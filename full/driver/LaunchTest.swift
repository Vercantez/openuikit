// LaunchTest.swift -- can an app be launched from the NAME of its delegate,
// with the object never crossing the boundary?
//
// The failure this test is built to catch is a fake: a "launch by name" that
// quietly closes over the delegate type it was given, so the string is
// decoration. Guards against that:
//   * the delegate class is named ONLY as a string literal in `runLaunchByName`
//     -- the type is never written there;
//   * a bogus name must fail, and say which name;
//   * a real class that is NOT a delegate must fail at the conformance step,
//     not be accepted;
//   * the instance is checked for a sentinel set in `init()`, because the
//     interesting wrong answer (`alloc` without `init`) produces an object of
//     the right class with an uninitialised body.

import CHostClock
import OpenUIKit

// MARK: - The app under test: ordinary app source, no launch machinery in it

/// What an app delegate looks like. The only thing here that is not what a
/// real iOS delegate would write is the `InstantiableAppDelegate` conformance
/// in place of plain `UIApplicationDelegate` -- see that protocol's comment
/// for the two words in ~/uikit that would remove even that.
final class ProbeAppDelegate: UIResponder, InstantiableAppDelegate {
    /// Set by `init()` and by nothing else. If a launch path allocated the
    /// object without running the initialiser, this is not 0xA11CE.
    let initSentinel: Int
    var window: UIWindow?
    var didFinishLaunching = false
    var rootAppeared: AppearProbeController?

    override init() {
        initSentinel = 0xA11CE
        super.init()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let root = AppearProbeController()
        w.rootViewController = UINavigationController(rootViewController: root)
        w.makeKeyAndVisible()
        window = w
        rootAppeared = root
        didFinishLaunching = true
        return true
    }
}

@MainActor
final class AppearProbeController: UIViewController {
    var appeared = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
    }
}

/// A real class that is NOT an app delegate. Used as a negative control: the
/// name resolves, the conformance must not.
final class NotADelegateAtAll {
    init() {}
}

// MARK: - The test

/// Typed nils. A bare `nil` here would be ambiguous against OpenUIKit's own
/// `UIApplicationMain(delegate:launchOptions:)`, and the compiler says so.
private let noPrincipal: String? = nil
private let noDelegate: String? = nil

@MainActor
func launchByNameSelfTest() -> Bool {
    var ok = true

    // ---- which runtime can answer "what class is named X" -----------------
    _ = objcRuntimeSurvey()

    // ---- the string an app would pass -------------------------------------
    // `_mangledTypeName` is `NSStringFromClass`'s counterpart: this is the
    // exact value a synthesised `@main` would hand to UIApplicationMain.
    guard let produced = mangledName(of: ProbeAppDelegate.self) else {
        print("  swift      : _mangledTypeName(ProbeAppDelegate.self) = nil  FAIL")
        return false
    }
    print("  swift      : _mangledTypeName(ProbeAppDelegate.self) = \"\(produced)\"")

    // ---- which spellings the runtime accepts ------------------------------
    // Worth knowing precisely, because a real app supplies the ObjC form and
    // we resolve with the Swift one.
    let forms = [("mangled (as produced)", produced),
                 ("qualified source name", "render_full.ProbeAppDelegate"),
                 ("ObjC mangled (NSStringFromClass form)",
                  objcMangledName(module: "render_full", cls: "ProbeAppDelegate")),
                 ("bare class name", "ProbeAppDelegate")]
    // Two columns on purpose. `raw` is what the Swift runtime answers on its
    // own; `resolved` is what UIApplicationMain answers. Printing only the
    // second would hide that the NSStringFromClass spelling needs re-spelling
    // first, which is the one finding here a reader must not miss.
    for (label, s) in forms {
        let raw = typeByName(s) != nil
        let resolved = resolveClass(named: s) != nil
        print("  name form  : raw=\(raw ? "yes" : "no ")  resolved=\(resolved ? "yes" : "no ")"
            + "  \(label)  \"\(s)\"")
    }
    // The spelling a real @main passes must work through the resolver.
    let objcForm = objcMangledName(module: "render_full", cls: "ProbeAppDelegate")
    let objcFormWorks = resolveClass(named: objcForm) != nil
    if !objcFormWorks {
        print("  name form  : NSStringFromClass spelling does not resolve  FAIL")
        ok = false
    }

    // ---- round trip: name -> type -> same type ----------------------------
    let roundTripped = typeByName(produced)
    let identical = roundTripped.map { $0 == ProbeAppDelegate.self } ?? false
    print("  round trip : name -> type is ProbeAppDelegate: \(identical ? "yes  PASS" : "NO  FAIL")")
    if !identical { ok = false }

    // ---- LAUNCH, from a string literal and nothing else --------------------
    // The type `ProbeAppDelegate` is deliberately not written on this path.
    // The spelling used here is the ObjC mangled one, because that is what
    // NSStringFromClass returns and therefore what a real app supplies. It is
    // built from string literals; the type is not named on this path.
    let result = UIApplicationMain(principalClassName: noPrincipal,
                                   delegateClassName: objcForm)
    switch result {
    case .failure(let why):
        print("  launch     : FAILED -- \(why)")
        return false
    case .success(let app):
        guard let delegate = app.delegate as? ProbeAppDelegate else {
            print("  launch     : delegate is not a ProbeAppDelegate  FAIL")
            return false
        }
        let sentinelOK = delegate.initSentinel == 0xA11CE
        print("  launch     : delegate=\(produced.isEmpty ? "?" : "ProbeAppDelegate")"
            + "  didFinishLaunching=\(delegate.didFinishLaunching ? "yes" : "NO")"
            + "  init-ran=\(sentinelOK ? "yes" : "NO -- allocated without init")"
            + "  " + ((sentinelOK && delegate.didFinishLaunching) ? "PASS" : "FAIL"))
        if !(sentinelOK && delegate.didFinishLaunching) { ok = false }

        // ---- and it is a live app the loop can drive ---------------------
        // NOT asserted on the ROOT controller: a window's root appears at
        // makeKeyAndVisible with no animation, so it has already appeared
        // before any loop runs. (It did, and reading that as a pass was this
        // test's own first bug.) The assertion needs something that can only
        // complete on the clock -- an animated push, driven by nothing but the
        // loop, taking real time.
        guard let window = delegate.window,
              let nav = window.rootViewController as? UINavigationController else {
            print("  run        : delegate built no window  FAIL")
            return false
        }
        let rootAppearedAtLaunch = delegate.rootAppeared?.appeared ?? false
        OpenUIKitRuntime.animationTime = 0
        let pushed = AppearProbeController()
        nav.pushViewController(pushed, animated: true)
        let before = pushed.appeared
        let loop = UIKitRunLoop(window: window, source: MonotonicFrameSource())
        let wall0 = mr_monotonic_seconds()
        let (_, turns) = loop.run(timeout: 3.0, until: { pushed.appeared })
        let wall = mr_monotonic_seconds() - wall0
        app._hostDidBecomeActive()
        let isActive: Bool = app.applicationState == UIApplication.State.active
        let ran = !before && pushed.appeared && wall > 0.05 && isActive
        let stateText: String = isActive ? "active" : "NOT active"
        let verdict: String = ran ? "PASS" : "FAIL"
        print("  run        : root appeared at launch=\(rootAppearedAtLaunch ? "yes" : "no")"
            + "  pushed-before-loop=\(before ? "already fired -- INVALID" : "not fired")"
            + "  after=\(pushed.appeared ? "FIRED" : "never")")
        print("  run        : turns=\(turns)  wall=\(fixed3ms(wall))s"
            + "  applicationState=\(stateText)  \(verdict)")
        if !ran { ok = false }
        app._hostWillTerminate()
    }

    // ---- teeth: the failures must fail ------------------------------------
    let bogus = UIApplicationMain(principalClassName: noPrincipal,
                                  delegateClassName: "render_full.NoSuchDelegate")
    let bogusRejected: Bool
    if case .failure(.unknownClass) = bogus { bogusRejected = true } else { bogusRejected = false }
    print("  control    : unknown class name -> "
        + (bogusRejected ? "rejected  PASS" : "ACCEPTED -- FAIL"))
    if !bogusRejected { ok = false }

    // A class that really exists and really is not a delegate. This separates
    // "the name did not resolve" from "the conformance was not checked".
    let realButWrong = "render_full.NotADelegateAtAll"
    let resolves = typeByName(realButWrong) != nil
    let wrong = UIApplicationMain(principalClassName: noPrincipal,
                                  delegateClassName: realButWrong)
    let wrongRejected: Bool
    if case .failure(.notADelegate) = wrong { wrongRejected = true } else { wrongRejected = false }
    print("  control    : non-delegate class (name resolves=\(resolves ? "yes" : "NO")) -> "
        + (wrongRejected ? "rejected at conformance  PASS" : "NOT rejected at conformance  FAIL"))
    if !(resolves && wrongRejected) { ok = false }

    let noName = UIApplicationMain(principalClassName: noPrincipal, delegateClassName: noDelegate)
    let noNameRejected: Bool
    if case .failure(.noDelegateName) = noName { noNameRejected = true } else { noNameRejected = false }
    print("  control    : nil delegate name (UIKit reads Info.plist here) -> "
        + (noNameRejected ? "rejected  PASS" : "ACCEPTED -- FAIL"))
    if !noNameRejected { ok = false }

    return ok
}

/// Three decimals without Foundation; see RunLoopTest.swift's `fixed3`.
private func fixed3ms(_ v: Double) -> String {
    let scaled = (v * 1000).rounded()
    let whole = Int(scaled) / 1000, frac = Int(scaled) % 1000
    var f = "\(frac)"
    while f.count < 3 { f = "0" + f }
    return "\(whole)." + f
}
