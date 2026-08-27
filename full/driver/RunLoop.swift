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

/// ONE FRAME, NO WAITING, NO THREAD OWNERSHIP -- the whole frame driver.
///
/// Split out from `UIKitRunLoop` because of a constraint from the CF side
/// (foundation-scope): CFRunLoop's Linux path waits on FILE DESCRIPTORS and
/// nothing else -- timers are timerfds, it blocks in ppoll, the dispatch main
/// queue arrives as an eventfd. A frame driver that owns the thread and sleeps
/// cannot compose with that, because both want the thread and CF would block in
/// ppoll straight past the frame deadline. It works standalone and then needs
/// rewriting.
///
/// So WHAT CALLS TICK IS PLUGGABLE. Two drivers sit over this one type:
///
///   PULL -- `UIKitRunLoop` owns the thread, and every blocking moment in it is
///           `HostFrameSource.wait(until:)`: ONE call, in ONE place. A
///           CFRunLoop-backed source implements that by blocking in
///           CFRunLoopRunInMode(deadline), so CF owns the block and services
///           its own descriptors while UIKit waits. Nothing else changes.
///   PUSH -- somebody else's loop owns the thread and calls `tick(at:)` when it
///           turns, which is what CADisplayLink does on iOS. No UIKit code is
///           involved in the waiting at all.
///
/// Both are exercised -- `runLoopSelfTest()` pulls, `externallyDrivenTest()`
/// pushes -- and neither reimplements the other.
///
/// A TIMERFD-BACKED SOURCE IS BUILDABLE. This design just does not need one.
///
/// A CORRECTED CLAIM, KEPT BECAUSE THE MISTAKE IS THE USEFUL PART. Measuring
/// machorun's libSystem finds 537 exported symbols and not one file-descriptor
/// wait primitive -- no timerfd, eventfd, epoll or ppoll, not even POSIX
/// poll/select or Darwin's kqueue -- with a control proving the grep
/// discriminates (it finds nanosleep, clock_gettime, read, write,
/// pthread_create). THAT MEASUREMENT IS CORRECT. The conclusion drawn from it,
/// "so nothing in this process can wait on a descriptor, CF included", was
/// WRONG. The primitives are simply not reached through libSystem:
/// swiftcore-macho/scripts/stage_linux_abi.sh declares them with GLIBCSYM asm
/// labels (`_glibc_<name>`), and machorun's loader binds that prefix straight to
/// glibc (src/resolve.c:31), deliberately bypassing libSystem. CF's epoll layer
/// already runs on exactly that mechanism -- libdispatch's real link has 20
/// undefined symbols and none of the eight is among them.
///
/// The lesson is this project's own, in the polarity that is easy to miss: an
/// EMPTY result was read as a capability gap. The control proved only that the
/// grep worked on libSystem; it never established that libSystem was the right
/// place to look. A control that validates the instrument does not validate the
/// choice of subject.
///
/// So `wait` could arm a timerfd through a C shim in that style. It stays a
/// sleep because the pull/push split above already composes: CF owns the block
/// inside `wait`, and no descriptor has to cross this API at all.
@MainActor
struct UIKitFrameDriver {
    let window: UIWindow
    /// Target frame interval. 60 Hz, the rate UIKit's display link runs at.
    var frameInterval: Double = 1.0 / 60.0

    /// Advance UIKit to `timestamp`. This is the entire frame driver: it does
    /// not wait, does not read a clock, and does not care who called it.
    func tick(at timestamp: Double) {
        // The clock UIKit's steppers read, and the timestamp the seam gets:
        // the same value, so a frame is never sampled at two different times.
        OpenUIKitRuntime.animationTime = timestamp
        window.tick(timestamp: timestamp)
    }

    /// When the driver wants its next turn. A push-mode host arms its own timer
    /// with this; a pull-mode host passes it to `wait(until:)`.
    func nextDeadline(after timestamp: Double) -> Double { timestamp + frameInterval }

    /// True when nothing is animating: UIKit's own redraw hint, not a guess.
    /// `animationWorkDeadline` is the latest end time of any recorded
    /// animation, and a host is expected to keep producing frames until the
    /// clock passes it.
    var isIdle: Bool { OpenUIKitRuntime.animationTime > OpenUIKitRuntime.animationWorkDeadline }
}

@MainActor
struct UIKitRunLoop {
    let window: UIWindow
    let source: HostFrameSource
    /// Target frame interval. 60 Hz, the rate UIKit's display link runs at.
    var frameInterval: Double = 1.0 / 60.0

    var driver: UIKitFrameDriver { UIKitFrameDriver(window: window, frameInterval: frameInterval) }

    /// Run until `predicate` returns true, or `timeout` monotonic seconds
    /// elapse. Returns the elapsed time ON THE SOURCE'S CLOCK and the number
    /// of turns taken.
    ///
    /// The ONLY blocking call is `source.wait(until:)` on the last line. That
    /// is the whole reason this composes: swap the source and somebody else
    /// owns every moment this thread is not advancing a frame.
    @discardableResult
    func run(timeout: Double, until predicate: () -> Bool) -> (elapsed: Double, turns: Int) {
        let d = driver
        let start = source.now()
        var turns = 0
        while true {
            let t = source.now() - start
            d.tick(at: t)
            turns += 1
            if predicate() { return (t, turns) }
            if t >= timeout { return (t, turns) }
            source.wait(until: start + d.nextDeadline(after: t))
        }
    }

    /// True when nothing is animating: UIKit's own redraw hint, not a guess.
    var isIdle: Bool { driver.isIdle }
}
