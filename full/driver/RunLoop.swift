// RunLoop.swift -- the piece that turns "renders a frame" into "runs".
//
// OpenUIKit already has the seam. `UIWindow.tick(timestamp:)` says so in its
// own comment -- "there is no run loop, so this tick IS the run-loop turn" --
// and one call advances scroll deceleration, navigation transitions (which is
// what fires viewDidAppear/viewDidDisappear), sheet settling, UIView.animate
// completions, caret blink, scheduled Timers and time-based gesture
// recognisers. Nothing here reimplements any of that. All this file adds is a
// host that feeds that seam REAL time instead of a value set by hand.
//
// DESIGNED SO CFRunLoop CAN LATER DRIVE IT RATHER THAN COMPETE WITH IT.
// On real iOS, UIKit's main loop sits ON CFRunLoop; it does not replace it.
// foundation-scope is building CFRunLoop's epoll path now, and if that and this
// end up as rival loops we will have built the wrong thing twice. So the only
// two things a host must supply -- "what time is it" and "wait until" -- are
// behind `HostFrameSource`. Today `MonotonicFrameSource` answers them with
// clock_gettime and nanosleep. A CFRunLoop-backed source would answer `wait`
// by blocking in CFRunLoopRunInMode with a timeout, and nothing else in this
// file would change. The loop body would stay exactly one line: tick.

import CHostClock
import OpenUIKit

/// The two primitives a run loop needs from its host. Everything else about
/// driving UIKit is already in `UIWindow.tick(timestamp:)`.
protocol HostFrameSource {
    /// Monotonic seconds. Must not jump; UIKit timings are durations.
    func now() -> Double
    /// Block until `deadline` (monotonic seconds). A CFRunLoop-backed source
    /// would block in the run loop here instead of sleeping, which is the
    /// whole point of the protocol.
    func wait(until deadline: Double)
}

/// The real one: a monotonic clock and a sleep.
struct MonotonicFrameSource: HostFrameSource {
    func now() -> Double { mr_monotonic_seconds() }
    func wait(until deadline: Double) { mr_sleep_seconds(deadline - mr_monotonic_seconds()) }
}

/// NOT a run loop -- the NEGATIVE CONTROL. Returns a clock that advances by a
/// fixed step per turn and never waits, which is exactly what "drive the frames
/// by hand" does today. UIKit cannot tell the difference: animations still
/// complete, viewDidAppear still fires, every assertion about ORDERING still
/// passes. Only wall time reveals it, which is why the frame-pacing check
/// measures elapsed real seconds and not the animation clock.
struct SyntheticFrameSource: HostFrameSource {
    let step: Double
    private final class Box { var t = 0.0 }
    private let box = Box()
    init(step: Double) { self.step = step }
    func now() -> Double { box.t += step; return box.t }
    func wait(until deadline: Double) { /* deliberately nothing */ }
}

@MainActor
struct UIKitRunLoop {
    let window: UIWindow
    let source: HostFrameSource
    /// Target frame interval. 60 Hz, the rate UIKit's display link runs at.
    var frameInterval: Double = 1.0 / 60.0

    /// Run until `predicate` returns true, or `timeout` monotonic seconds
    /// elapse. Returns the elapsed time ON THE SOURCE'S CLOCK and the number
    /// of turns taken.
    @discardableResult
    func run(timeout: Double, until predicate: () -> Bool) -> (elapsed: Double, turns: Int) {
        let start = source.now()
        var turns = 0
        while true {
            let t = source.now() - start
            // The clock UIKit's steppers read, and the timestamp the seam gets:
            // the same value, so a frame is never sampled at two different times.
            OpenUIKitRuntime.animationTime = t
            window.tick(timestamp: t)
            turns += 1
            if predicate() { return (t, turns) }
            if t >= timeout { return (t, turns) }
            source.wait(until: start + t + frameInterval)
        }
    }

    /// True when nothing is animating: UIKit's own redraw hint, not a guess.
    /// `animationWorkDeadline` is the latest end time of any recorded
    /// animation, and a host is expected to keep producing frames until the
    /// clock passes it.
    var isIdle: Bool { OpenUIKitRuntime.animationTime > OpenUIKitRuntime.animationWorkDeadline }
}
