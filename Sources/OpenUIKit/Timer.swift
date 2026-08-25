// A portable Timer on the HOST CLOCK. Owner: app-compat cluster (controls2).
//
// WHY THIS TYPE IS HERE, AND WHY IT CANNOT READ A WALL CLOCK
// ----------------------------------------------------------
// `Timer` is a Foundation type built on `RunLoop`, and `Sources/OpenUIKit`
// imports no Foundation and has no run loop (docs/ARCHITECTURE.md "Hard
// rules"). It also must not read a wall clock: `openrender` renders scenes
// and scroll traces frame by frame from SCRIPTED timestamps, and a golden
// that depended on `gettimeofday` would stop being reproducible.
//
// So this `Timer` runs on exactly the clock everything else in the library
// runs on — the timestamp the host passes to `UIWindow.tick(timestamp:)`,
// the same one that drives scroll deceleration, navigation transitions,
// sheet settling, `UIView.animate` completions and the caret blink. A timer
// fires when that clock passes its fire date, and never otherwise:
//
//   * `openhost` ticks every frame, so timers behave like real ones.
//   * `openrender` ticks only the scripted capture times of an animation or
//     scroll-trace scene, so a scene's timers fire at exactly the same
//     scripted moments on every machine and on every platform. A STATIC
//     scene never ticks, so its timers never fire — which is why no golden
//     can be perturbed by adding one.
//
// This SHADOWS Foundation's `Timer` and `RunLoop` exactly the way
// `NSAttributedString` and `NotificationCenter` shadow theirs: an app that
// imports both needs a file-scope `private typealias Timer =
// OpenUIKit.Timer`. See Sources/OpenUIKit/NotificationCenter.swift for the
// full statement of that tradeoff.
//
// DIVERGENCES from Foundation, all of them consequences of the above:
//   * `fireDate` is a `TimeInterval` on the host clock, not a `Date`
//     (`Date` is Foundation, and there is no wall clock to anchor it to).
//   * A timer created with `init(timeInterval:…)` and never added to a run
//     loop still needs `RunLoop.main.add(_:forMode:)` to start, but the
//     `mode` is IGNORED — there is one clock and one mode.
//   * The selector form RETAINS its target, exactly like Foundation's (the
//     classic `Timer`-retain-cycle behaviour), so `invalidate()` is still
//     required to break it. The block form retains its block.
//   * A LATE repeating timer does not play catch-up: it fires once and its
//     next fire date jumps to the first multiple of the interval that is
//     still in the future. Foundation documents the same behaviour.
//   * `tolerance` is stored and ignored — a scripted clock has no jitter to
//     absorb.
//   * There is no threading, so there is no `Timer` on a background queue.

/// The run-loop mode argument of `RunLoop.add(_:forMode:)`. Accepted and
/// ignored — see the file header.
public struct RunLoopMode: Hashable, RawRepresentable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let `default` = RunLoopMode(rawValue: "kCFRunLoopDefaultMode")
    public static let common = RunLoopMode(rawValue: "kCFRunLoopCommonModes")
    public static let tracking = RunLoopMode(rawValue: "UITrackingRunLoopMode")
}

/// Present so `RunLoop.main.add(timer, forMode: .common)` compiles. It runs
/// nothing: the host's loop is the run loop, and `UIWindow.tick(timestamp:)`
/// is its turn. See the file header.
public final class RunLoop {
    public typealias Mode = RunLoopMode

    public static let main = RunLoop()
    public static var current: RunLoop { main }

    private init() {}

    /// Schedules `timer` on the host clock. The mode is ignored.
    public func add(_ timer: Timer, forMode mode: Mode) {
        _ = mode
        Timer._schedule(timer)
    }
}

public final class Timer {
    // MARK: The clock

    /// The host clock the timer machinery runs on: the most recent timestamp
    /// passed to `UIWindow.tick(timestamp:)`. Starts at 0 and only moves
    /// forward. A host that never ticks never fires a timer.
    public private(set) static var currentTime: TimeInterval = 0

    /// Every scheduled, still-valid timer, in no particular order.
    private static var scheduled: [Timer] = []

    /// Host redraw hint, mirroring `UIScrollView._hasActiveScrollAnimations`:
    /// true while any scheduled timer is waiting to fire, so a dirty-flag
    /// host keeps ticking instead of idling.
    public static var _hasScheduledTimers: Bool { !scheduled.isEmpty }

    /// The earliest pending fire time, or nil. `openhost` uses it the way it
    /// uses `OpenUIKitRuntime.animationWorkDeadline`.
    public static var _nextFireTime: TimeInterval? {
        scheduled.map(\.fireDate).min()
    }

    /// Advance the timer clock and fire everything due. Called by
    /// `UIWindow.tick(timestamp:)` alongside the other steppers; a host with
    /// no window can call it directly.
    public static func _step(to timestamp: TimeInterval) {
        if timestamp > currentTime { currentTime = timestamp }
        guard !scheduled.isEmpty else { return }
        // Snapshot in fire order, so a timer that schedules another timer
        // does not perturb this pass, and two timers due in the same tick
        // fire earliest-first (Foundation's ordering).
        let due = scheduled.filter { $0.isValid && $0.fireDate <= timestamp }
            .sorted { $0.fireDate < $1.fireDate }
        for timer in due where timer.isValid {
            if timer.repeats {
                var next = timer.fireDate + timer.timeInterval
                if next <= timestamp, timer.timeInterval > 0 {
                    // Late: skip the missed fires rather than bursting. The
                    // trailing loop absorbs floating-point slop — the
                    // division can land exactly ON the timestamp.
                    let missed = ((timestamp - next) / timer.timeInterval).rounded(.down) + 1
                    next += missed * timer.timeInterval
                    while next <= timestamp { next += timer.timeInterval }
                }
                timer.fireDate = next
            }
            timer._fire()
            if !timer.repeats { timer.invalidate() }
        }
        scheduled.removeAll { !$0.isValid }
    }

    /// Drops every scheduled timer and rewinds the clock. Test/host hook —
    /// `openrender` calls it between scenes so one scene's timers can never
    /// leak into the next one's capture.
    public static func _reset() {
        for t in scheduled { t.isValid = false }
        scheduled.removeAll()
        currentTime = 0
    }

    static func _schedule(_ timer: Timer) {
        guard timer.isValid, !scheduled.contains(where: { $0 === timer }) else { return }
        scheduled.append(timer)
    }

    // MARK: Instance state

    /// The host-clock time at which the timer next fires. Assignable, like
    /// Foundation's `fireDate` (a `TimeInterval` here — see the header).
    public var fireDate: TimeInterval
    public let timeInterval: TimeInterval
    public let repeats: Bool
    public var userInfo: Any?
    /// Stored and ignored (there is no jitter on a scripted clock).
    public var tolerance: TimeInterval = 0
    public private(set) var isValid: Bool = true

    private var block: ((Timer) -> Void)?
    /// Retained, like Foundation's (see the header).
    private var target: AnyObject?
    private var selectorName: String?

    // MARK: Creating

    /// Foundation's block initializer. NOT scheduled — hand it to
    /// `RunLoop.main.add(_:forMode:)`, or use ``scheduledTimer(withTimeInterval:repeats:block:)``.
    public init(timeInterval interval: TimeInterval, repeats: Bool,
                block: @escaping (Timer) -> Void) {
        self.timeInterval = max(interval, 0)
        self.repeats = repeats
        self.fireDate = Timer.currentTime + max(interval, 0)
        self.block = block
    }

    /// Foundation's selector initializer. `target` must conform to
    /// ``SelectorDispatching`` (docs/OBJC_RUNTIME.md); the selector takes the
    /// timer as its one argument, so its name ends in a colon
    /// (`Selector.named("tick:")`). NOT scheduled — see above.
    public init(timeInterval interval: TimeInterval, target: AnyObject,
                selector: Selector, userInfo: Any?, repeats: Bool) {
        self.timeInterval = max(interval, 0)
        self.repeats = repeats
        self.fireDate = Timer.currentTime + max(interval, 0)
        self.userInfo = userInfo
        self.target = target
        self.selectorName = selector.actionName
    }

    /// Creates the timer AND schedules it on the host clock.
    @discardableResult
    public static func scheduledTimer(withTimeInterval interval: TimeInterval,
                                      repeats: Bool,
                                      block: @escaping (Timer) -> Void) -> Timer {
        let t = Timer(timeInterval: interval, repeats: repeats, block: block)
        _schedule(t)
        return t
    }

    /// Creates the timer AND schedules it on the host clock (selector form).
    @discardableResult
    public static func scheduledTimer(timeInterval interval: TimeInterval,
                                      target: AnyObject,
                                      selector: Selector,
                                      userInfo: Any?,
                                      repeats: Bool) -> Timer {
        let t = Timer(timeInterval: interval, target: target, selector: selector,
                      userInfo: userInfo, repeats: repeats)
        _schedule(t)
        return t
    }

    // MARK: Firing / invalidating

    /// Fires the timer NOW, out of schedule, exactly like Foundation's:
    /// a non-repeating timer is invalidated afterwards; a repeating one
    /// keeps its schedule (its next fire date is not moved).
    public func fire() {
        guard isValid else { return }
        _fire()
        if !repeats { invalidate() }
    }

    private func _fire() {
        if let block { block(self); return }
        guard let target, let selectorName else { return }
        // `Timer` itself stays nonisolated, exactly like Foundation's — a
        // timer is a schedule, not a view. Its TARGET, though, is app code
        // that is now `@MainActor` (`SelectorDispatching` is main-actor
        // isolated because every UIKit-shaped conformer is a view or a view
        // controller). OpenUIKit has no threads and no run loop of its own:
        // timers only ever fire from `RunLoop.main` / `UIWindow.tick`, both
        // main-thread entry points. `assumeIsolated` states that precondition
        // and CHECKS it (it traps off-main) rather than silencing it the way
        // `nonisolated(unsafe)` would.
        MainActor.assumeIsolated {
            guard let dispatcher = target as? SelectorDispatching else {
                SelectorDispatch.onUnresolved?(target, selectorName)
                return
            }
            if !dispatcher.perform(selectorName, with: self) {
                SelectorDispatch.onUnresolved?(target, selectorName)
            }
        }
    }

    /// Stops the timer permanently and releases its block/target. A timer
    /// cannot be revived, as in Foundation.
    public func invalidate() {
        guard isValid else { return }
        isValid = false
        block = nil
        target = nil
        selectorName = nil
        Timer.scheduled.removeAll { $0 === self }
    }
}
