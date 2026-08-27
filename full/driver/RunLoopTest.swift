// RunLoopTest.swift -- does the loop advance over WALL TIME, or does it merely
// exist?
//
// The distinction matters because a loop that spins and calls tick() passes
// every ordering assertion you could write: animations complete, completion
// handlers fire, viewDidAppear fires. It is wrong about the only thing a run
// loop is FOR -- that a 0.5 s animation takes 0.5 s.
//
// So the measurement is elapsed REAL seconds, taken from a clock the loop does
// not control, and the check has teeth demonstrated on both sides:
//
//   MonotonicFrameSource  -- the real loop. Wall time must match the declared
//                            animation duration.
//   SyntheticFrameSource  -- the negative control, and NOT a strawman: it is
//                            precisely what openrender does today (advance the
//                            clock by hand, never wait). The animation still
//                            completes, so a test that only checked "did the
//                            completion fire" would PASS here. Wall time must
//                            be ~0, and the test must SAY SO.
//
// A run where both sources report the same wall time would mean the
// measurement is not measuring wall time at all.

import CHostClock
import OpenUIKit

/// Three decimals, without Foundation. `String(format:)` is a Foundation API
/// and this binary deliberately has no Foundation on the library path -- the
/// same constraint that shaped the whole render stack.
private func fixed3(_ v: Double) -> String {
    if v.isInfinite { return v < 0 ? "-inf" : "inf" }
    let neg = v < 0
    let scaled = ((neg ? -v : v) * 1000).rounded()
    let whole = Int(scaled) / 1000, frac = Int(scaled) % 1000
    var f = "\(frac)"
    while f.count < 3 { f = "0" + f }
    return (neg ? "-" : "") + "\(whole)." + f
}

@MainActor
func runLoopSelfTest() -> Bool {
    let duration = 0.5
    let tolerance = 0.15          // generous: a loaded container is not a metronome
    var allPassed = true

    func trial(_ label: String, _ source: HostFrameSource) -> (wall: Double, clock: Double, fired: Bool, turns: Int) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 140))
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(box)
        window.makeKeyAndVisible()
        OpenUIKitRuntime.animationTime = 0

        final class Flag { var fired = false }
        let flag = Flag()
        UIView.animate(withDuration: duration, animations: {
            box.frame = CGRect(x: 200, y: 0, width: 50, height: 50)
        }, completion: { _ in flag.fired = true })

        // The wall clock is read directly, NOT through the frame source, so a
        // source that lies about time cannot also fake the measurement.
        let wall0 = mr_monotonic_seconds()
        let loop = UIKitRunLoop(window: window, source: source)
        let (clock, turns) = loop.run(timeout: 5.0, until: { flag.fired })
        let wall = mr_monotonic_seconds() - wall0
        return (wall, clock, flag.fired, turns)
    }

    // ---- the real loop -----------------------------------------------------
    let real = trial("monotonic", MonotonicFrameSource())
    let realOK = real.fired && abs(real.wall - duration) <= tolerance
    print("  monotonic : fired=\(real.fired ? "yes" : "NO") turns=\(real.turns)"
        + "  animation-clock=\(fixed3(real.clock))s  WALL=\(fixed3(real.wall))s  "
        + (realOK ? "PASS" : "FAIL"))
    if !realOK { allPassed = false }

    // ---- the negative control ---------------------------------------------
    // Same animation, same assertions about completion -- and no waiting.
    let fake = trial("synthetic", SyntheticFrameSource(step: 1.0 / 60.0))
    let controlHasTeeth = fake.fired && fake.wall < duration / 2
    print("  synthetic : fired=\(fake.fired ? "yes" : "NO") turns=\(fake.turns)"
        + "  animation-clock=\(fixed3(fake.clock))s  WALL=\(fixed3(fake.wall))s  "
        + (controlHasTeeth ? "correctly detected as NOT wall-clock" : "CONTROL FAILED"))
    if !controlHasTeeth { allPassed = false }

    // ---- the discrimination itself ----------------------------------------
    // Both completed the animation. Only wall time separates them; if it did
    // not, this whole test would be measuring the animation clock twice.
    let separated = real.wall > fake.wall * 4
    let ratio = fake.wall > 0 ? real.wall / fake.wall : Double.infinity
    print("  both completed the animation; wall times differ by \(fixed3(ratio))x  "
        + (separated ? "PASS" : "FAIL -- the test is not measuring wall time"))
    if !separated { allPassed = false }

    // ---- the lifecycle actually REACHES viewDidAppear -----------------------
    // The point of a run loop, stated plainly. RealApp.swift works around its
    // absence in a comment -- "openrender has no run loop, so viewDidAppear
    // never fires on its own" -- and calls presentPickerNow() by hand. Under a
    // loop the callback should arrive because UINavigationController's
    // transition finishes on the clock, with nobody nudging it.
    allPassed = lifecycleReachesViewDidAppear() && allPassed
    allPassed = externallyDrivenTest() && allPassed
    return allPassed
}

@MainActor
private final class AppearRecorder: UIViewController {
    var appeared = false
    var appearedAnimated: Bool?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
        appearedAnimated = animated
    }
}

@MainActor
func lifecycleReachesViewDidAppear() -> Bool {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let root = UIViewController()
    let nav = UINavigationController(rootViewController: root)
    window.rootViewController = nav
    window.makeKeyAndVisible()
    OpenUIKitRuntime.animationTime = 0

    let pushed = AppearRecorder()
    nav.pushViewController(pushed, animated: true)

    // NOTHING is nudged here: no presentNow, no manual clock advance. The loop
    // is the only thing running.
    let before = pushed.appeared
    let loop = UIKitRunLoop(window: window, source: MonotonicFrameSource())
    let wall0 = mr_monotonic_seconds()
    let (_, turns) = loop.run(timeout: 3.0, until: { pushed.appeared })
    let wall = mr_monotonic_seconds() - wall0

    // Fired DURING the loop, not before it -- otherwise the loop proved nothing.
    let ok = !before && pushed.appeared && wall > 0.05
    print("  viewDidAppear: before-loop=\(before ? "already fired -- INVALID" : "not fired")"
        + "  after=\(pushed.appeared ? "FIRED" : "never")"
        + "  animated=\(pushed.appearedAnimated.map { $0 ? "true" : "false" } ?? "n/a")"
        + "  turns=\(turns)  WALL=\(fixed3(wall))s  " + (ok ? "PASS" : "FAIL"))
    return ok
}

// MARK: - PUSH mode: somebody else's loop owns the thread

/// The composition CFRunLoop needs, tested without CFRunLoop.
///
/// `UIKitRunLoop` appears NOWHERE below. The loop here owns the thread, does
/// its own waiting, and calls `UIKitFrameDriver.tick(at:)` when it turns --
/// exactly the position CFRunLoop will be in once it links, and exactly what
/// CADisplayLink does on iOS. If UIKit could only be advanced by a loop that
/// owns the thread, this test could not be written at all.
///
/// It has to demonstrate the same two things the pull-mode test does, or it
/// proves only that a function can be called: the lifecycle must REACH
/// viewDidAppear with nothing nudged, and it must take REAL time, measured by
/// a clock the driver does not control.
@MainActor
func externallyDrivenTest() -> Bool {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let root = UIViewController()
    let nav = UINavigationController(rootViewController: root)
    window.rootViewController = nav
    window.makeKeyAndVisible()
    OpenUIKitRuntime.animationTime = 0

    let pushed = AppearRecorder()
    nav.pushViewController(pushed, animated: true)
    let before = pushed.appeared

    // ---- a host loop that is not ours ------------------------------------
    let driver = UIKitFrameDriver(window: window)
    let start = mr_monotonic_seconds()
    var turns = 0
    var t = 0.0
    while !pushed.appeared && t < 3.0 {
        t = mr_monotonic_seconds() - start
        driver.tick(at: t)
        turns += 1
        // The host's own waiting. A real host blocks in its run loop here;
        // this one sleeps, because the guest has no descriptor to wait on.
        mr_sleep_seconds(start + driver.nextDeadline(after: t) - mr_monotonic_seconds())
    }
    let wall = mr_monotonic_seconds() - start

    let ok = !before && pushed.appeared && wall > 0.05
    print("  push mode  : externally driven, UIKitRunLoop not involved")
    print("  push mode  : viewDidAppear=\(pushed.appeared ? "FIRED" : "never")"
        + "  turns=\(turns)  WALL=\(fixed3(wall))s  " + (ok ? "PASS" : "FAIL"))

    // ---- the same negative control the pull-mode test uses ----------------
    // An external loop that never waits. The animation still completes and
    // viewDidAppear still fires, so "did it fire" cannot tell the two apart --
    // only wall time can, which is the point of measuring it here too.
    let w2 = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let nav2 = UINavigationController(rootViewController: UIViewController())
    w2.rootViewController = nav2
    w2.makeKeyAndVisible()
    OpenUIKitRuntime.animationTime = 0
    let pushed2 = AppearRecorder()
    nav2.pushViewController(pushed2, animated: true)
    let d2 = UIKitFrameDriver(window: w2)
    let s2 = mr_monotonic_seconds()
    var t2 = 0.0
    while !pushed2.appeared && t2 < 3.0 { t2 += 1.0 / 60.0; d2.tick(at: t2) }
    let wall2 = mr_monotonic_seconds() - s2
    let controlOK = pushed2.appeared && wall2 < 0.05
    print("  push mode  : control (never waits) viewDidAppear="
        + "\(pushed2.appeared ? "FIRED" : "never") WALL=\(fixed3(wall2))s  "
        + (controlOK ? "correctly detected as NOT wall-clock" : "CONTROL FAILED"))

    return ok && controlOK
}
