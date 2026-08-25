// Lifecycle-module tests (M12): the responder chain, first-responder
// transitions on the new UIResponder base class, UIApplication's launch /
// activation / termination ordering, and the host-driven environment
// (UIScreen / UIDevice).
//
// Nothing here renders, so there are no new oracle scenes: the chain and
// the callback order are UIKit's documented contract (docs/APP_COMPAT.md),
// and the 81 golden scenes are the regression gate for "reparenting the
// class hierarchy changed nothing visible".
import XCTest
import Foundation
@testable import OpenUIKit

/// UIApplication is a process-wide singleton, so a chain assertion that
/// ends "at the application" only holds while no responder delegate is
/// installed. Run such assertions with the delegate detached.
private func withoutApplicationDelegate(_ body: () -> Void) {
    let previous = UIApplication.shared.delegate
    UIApplication.shared.delegate = nil
    defer { UIApplication.shared.delegate = previous }
    body()
}

// MARK: - Responder chain

final class ResponderChainTests: XCTestCase {
    /// A deep view walks superviews, hops through the view controller whose
    /// ROOT view it passes, and ends at the window then the application.
    func testDeepViewChainThroughViewControllerWindowApplication() {
        let vc = UIViewController()
        vc.loadViewIfNeeded()
        let content = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let leaf = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        content.addSubview(leaf)
        vc.view.addSubview(content)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = vc

        withoutApplicationDelegate {
            let chain = leaf._responderChain
            XCTAssertTrue(chain[0] === leaf)
            XCTAssertTrue(chain[1] === content)
            XCTAssertTrue(chain[2] === vc.view)
            XCTAssertTrue(chain[3] === vc, "the VC is inserted after its ROOT view")
            XCTAssertTrue(chain[4] === window)
            XCTAssertTrue(chain[5] === UIApplication.shared)
            XCTAssertEqual(chain.count, 6, "chain ends at the application")
        }
    }

    /// The controller hop happens ONLY for the controller's root view: a
    /// sibling subview's next responder is plainly its superview.
    func testOnlyRootViewGetsTheControllerHop() {
        let vc = UIViewController()
        vc.loadViewIfNeeded()
        let a = UIView()
        let b = UIView()
        vc.view.addSubview(a)
        a.addSubview(b)
        XCTAssertTrue(b.next === a)
        XCTAssertTrue(a.next === vc.view)
        XCTAssertTrue(vc.view.next === vc)
        XCTAssertNil(vc.next, "detached controller: no window above it")
    }

    /// A view a controller no longer owns loses the hop (the controller's
    /// view was replaced).
    func testReplacedRootViewLosesTheControllerHop() {
        let vc = UIViewController()
        let old = UIView()
        vc.view = old
        XCTAssertTrue(old.next === vc)
        let new = UIView()
        vc.view = new
        XCTAssertTrue(new.next === vc)
        XCTAssertNil(old.next, "no longer the controller's root view")
    }

    /// Container controllers stack: a child's chain passes through the
    /// child, the container's view, the container, then the window.
    func testChildControllerChainThroughContainer() {
        let child = UIViewController()
        let nav = UINavigationController(rootViewController: child)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = nav
        window.layoutIfNeeded()

        withoutApplicationDelegate {
            let chain = child.view._responderChain
            XCTAssertTrue(chain[0] === child.view)
            XCTAssertTrue(chain[1] === child)
            // ...through the navigation controller's own view hierarchy...
            XCTAssertTrue(chain.contains { $0 === nav })
            XCTAssertTrue(chain.contains { $0 === window })
            XCTAssertTrue(chain.last === UIApplication.shared)
            // The controller hop precedes the container, which precedes the
            // window.
            let iChild = chain.firstIndex { $0 === child }!
            let iNav = chain.firstIndex { $0 === nav }!
            let iWindow = chain.firstIndex { $0 === window }!
            XCTAssertLessThan(iChild, iNav)
            XCTAssertLessThan(iNav, iWindow)
        }
    }

    /// UIKit: a PRESENTED controller's next responder is the presenting
    /// controller, even though the presentation container lives in the
    /// window.
    func testPresentedControllerChainHopsToPresenter() {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = presenter
        window.layoutIfNeeded()

        let presented = UIViewController()
        presenter.present(presented, animated: false)

        let chain = presented.view._responderChain
        XCTAssertTrue(chain[0] === presented.view)
        XCTAssertTrue(chain[1] === presented)
        XCTAssertTrue(chain[2] === presenter, "hop to the presenter, not the window")
        XCTAssertTrue(chain[3] === window)
        XCTAssertTrue(chain[4] === UIApplication.shared)
    }

    /// With a window scene attached, the window's next responder is the
    /// scene, then the application (UIKit's scene-shaped chain).
    func testWindowSceneSitsBetweenWindowAndApplication() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertTrue(window.next === UIApplication.shared)
        let scene = UIWindowScene()
        window.windowScene = scene
        XCTAssertTrue(window.next === scene)
        XCTAssertTrue(scene.next === UIApplication.shared)
        XCTAssertTrue(UIApplication.shared.connectedScenes.contains(scene))
        XCTAssertTrue(scene.windows.contains { $0 === window })
        UIApplication.shared._disconnect(scene: scene)
        window.windowScene = nil
    }

    /// The application forwards to its delegate when the delegate is itself
    /// a responder — the `class AppDelegate: UIResponder,
    /// UIApplicationDelegate` shape.
    func testApplicationForwardsToResponderDelegate() {
        final class D: UIResponder, UIApplicationDelegate {}
        let d = D()
        let previous = UIApplication.shared.delegate
        UIApplication.shared.delegate = d
        XCTAssertTrue(UIApplication.shared.next === d)
        XCTAssertNil(d.next)
        UIApplication.shared.delegate = previous
    }

    func testResponderChainIsCycleGuarded() {
        // A malformed hierarchy must not hang a host.
        final class Loop: UIResponder {
            weak var target: UIResponder?
            override var next: UIResponder? { target }
        }
        let a = Loop(), b = Loop()
        a.target = b
        b.target = a
        XCTAssertEqual(a._responderChain.count, 2)
    }
}

// MARK: - Touch forwarding up the chain

/// Records the responder entry points it receives (and stops the chain).
private final class StopRecorder: UIView {
    var log: [String] = []
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("began")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("ended")
    }
}

private final class RecordingApplicationDelegate: UIResponder, UIApplicationDelegate {
    var log: [String] = []
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        log.append("app-delegate-began")
    }
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.append("willFinishLaunching")
        return true
    }
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.append("didFinishLaunching(state=\(application.applicationState))")
        return true
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        log.append("didBecomeActive(state=\(application.applicationState))")
    }
    func applicationWillResignActive(_ application: UIApplication) {
        log.append("willResignActive(state=\(application.applicationState))")
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        log.append("didEnterBackground(state=\(application.applicationState))")
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        log.append("willEnterForeground(state=\(application.applicationState))")
    }
    func applicationWillTerminate(_ application: UIApplication) {
        log.append("willTerminate")
    }
}

final class ResponderTouchForwardingTests: XCTestCase {
    /// UIKit's default: an unhandled touch travels up the chain.
    func testUnhandledTouchForwardsToAncestor() {
        let recorder = StopRecorder(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let plain = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        recorder.addSubview(plain)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(recorder)

        window.sendTouch(.began, at: CGPoint(x: 10, y: 10), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 10, y: 10), timestamp: 0.05)
        XCTAssertEqual(recorder.log, ["began", "ended"],
                       "the plain subview was hit; its ancestor handled the touch")
    }

    /// A responder that HANDLES a phase stops it: UIControl never calls
    /// super, so a tapped button does not leak touches to its ancestors.
    func testControlStopsForwarding() {
        let recorder = StopRecorder(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let button = UIControl(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        recorder.addSubview(button)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(recorder)

        window.sendTouch(.began, at: CGPoint(x: 10, y: 10), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 10, y: 10), timestamp: 0.05)
        XCTAssertEqual(recorder.log, [], "the control consumed the touches")
    }

    /// The chain really does reach the application and its delegate.
    func testTouchReachesApplicationDelegate() {
        let delegate = RecordingApplicationDelegate()
        let previous = UIApplication.shared.delegate
        UIApplication.shared.delegate = delegate
        defer { UIApplication.shared.delegate = previous }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let plain = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(plain)
        window.sendTouch(.began, at: CGPoint(x: 10, y: 10), timestamp: 0)
        XCTAssertEqual(delegate.log, ["app-delegate-began"])
    }

    /// pressesBegan has the same default: forward to `next`. A press sent
    /// to a leaf view climbs the whole chain — through the view controller
    /// and the window — to the app delegate.
    func testPressesForwardUpTheChain() {
        final class PressRecorder: UIViewController {
            var log: [String] = []
            override func pressesBegan(_ presses: Set<UIPress>,
                                       with event: UIPressesEvent?) {
                log.append("vc:\(presses.first?.key.map { "\($0)" } ?? "?")")
                super.pressesBegan(presses, with: event)
            }
        }
        final class DelegateRecorder: UIResponder, UIApplicationDelegate {
            var log: [String] = []
            override func pressesBegan(_ presses: Set<UIPress>,
                                       with event: UIPressesEvent?) {
                log.append("delegate")
            }
        }
        let vc = PressRecorder()
        let leaf = UIView()
        vc.view.addSubview(leaf)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.rootViewController = vc

        let delegate = DelegateRecorder()
        let previous = UIApplication.shared.delegate
        UIApplication.shared.delegate = delegate
        defer { UIApplication.shared.delegate = previous }

        let press = UIPress(phase: .began, key: .return)
        let event = UIPressesEvent(presses: [press])
        leaf.pressesBegan([press], with: event)

        XCTAssertEqual(vc.log, ["vc:return"], "climbed leaf -> root view -> VC")
        XCTAssertEqual(delegate.log, ["delegate"], "and on through the window + app")
        XCTAssertEqual(event.allPresses.count, 1)
    }
}

// MARK: - First responder

final class ResponderFirstResponderTests: XCTestCase {
    /// A responder that opts in takes focus, and the window records it.
    func testBecomeAndResignOnAView() {
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let v = Focusable()
        window.addSubview(v)

        XCTAssertFalse(v.isFirstResponder)
        XCTAssertTrue(v.becomeFirstResponder())
        XCTAssertTrue(v.isFirstResponder)
        XCTAssertTrue(window.firstResponder === v)
        XCTAssertTrue(v.resignFirstResponder())
        XCTAssertFalse(v.isFirstResponder)
        XCTAssertNil(window.firstResponder)
    }

    /// A view controller can hold focus too, through its view's window.
    func testViewControllerCanBecomeFirstResponder() {
        final class FocusableVC: UIViewController {
            override var canBecomeFirstResponder: Bool { true }
        }
        let vc = FocusableVC()
        XCTAssertFalse(vc.becomeFirstResponder(), "not in a window yet")

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = vc
        XCTAssertTrue(vc.becomeFirstResponder())
        XCTAssertTrue(window.firstResponder === vc)
        XCTAssertTrue(vc.isFirstResponder)
        vc.resignFirstResponder()
        XCTAssertNil(window.firstResponder)
    }

    /// Taking focus makes the previous first responder resign first.
    func testTakingFocusResignsThePrevious() {
        final class Focusable: UIView {
            var resigned = 0
            override var canBecomeFirstResponder: Bool { true }
            override func resignFirstResponder() -> Bool {
                resigned += 1
                return super.resignFirstResponder()
            }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let a = Focusable(), b = Focusable()
        window.addSubview(a)
        window.addSubview(b)
        XCTAssertTrue(a.becomeFirstResponder())
        XCTAssertTrue(b.becomeFirstResponder())
        XCTAssertEqual(a.resigned, 1)
        XCTAssertTrue(window.firstResponder === b)
        XCTAssertFalse(a.isFirstResponder)
    }

    /// canResignFirstResponder == false refuses the handover (UIKit).
    func testStickyFirstResponderBlocksHandover() {
        final class Sticky: UIView {
            override var canBecomeFirstResponder: Bool { true }
            override var canResignFirstResponder: Bool { false }
        }
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let sticky = Sticky(), other = Focusable()
        window.addSubview(sticky)
        window.addSubview(other)
        XCTAssertTrue(sticky.becomeFirstResponder())
        XCTAssertFalse(other.becomeFirstResponder())
        XCTAssertTrue(window.firstResponder === sticky)
    }

    /// Re-taking focus you already hold is a no-op that succeeds.
    func testBecomeFirstResponderIsIdempotent() {
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let v = Focusable()
        window.addSubview(v)
        XCTAssertTrue(v.becomeFirstResponder())
        XCTAssertTrue(v.becomeFirstResponder())
        XCTAssertTrue(window.firstResponder === v)
    }

    /// Focus is per WINDOW, which is where UIKit stores it.
    func testFirstResponderIsPerWindow() {
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        let w1 = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let w2 = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let a = Focusable(), b = Focusable()
        w1.addSubview(a)
        w2.addSubview(b)
        XCTAssertTrue(a.becomeFirstResponder())
        XCTAssertTrue(b.becomeFirstResponder())
        XCTAssertTrue(w1.firstResponder === a)
        XCTAssertTrue(w2.firstResponder === b)
    }

    /// A plain responder (no window) cannot take focus, even if it opts in.
    func testDetachedResponderCannotTakeFocus() {
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        XCTAssertFalse(Focusable().becomeFirstResponder())
    }
}

// MARK: - Application lifecycle

final class ApplicationLifecycleTests: XCTestCase {
    /// Launch -> active -> resign -> background -> foreground -> active ->
    /// terminate, in UIKit's order, with the state observable from inside
    /// every callback.
    func testLifecycleCallbackOrdering() {
        let app = UIApplication.shared
        let delegate = RecordingApplicationDelegate()
        let previous = app.delegate
        defer { app.delegate = previous }

        UIApplicationMain(delegate: delegate)
        XCTAssertEqual(app.applicationState, .inactive, "launches inactive")

        app._hostDidBecomeActive()
        app._hostWillResignActive()
        app._hostDidEnterBackground()
        app._hostWillEnterForeground()
        app._hostDidBecomeActive()
        app._hostWillTerminate()

        XCTAssertEqual(delegate.log, [
            "willFinishLaunching",
            "didFinishLaunching(state=inactive)",
            "didBecomeActive(state=active)",
            "willResignActive(state=active)",
            "didEnterBackground(state=background)",
            "willEnterForeground(state=inactive)",
            "didBecomeActive(state=active)",
            "willTerminate",
        ])
        XCTAssertTrue(app.isTerminating)
    }

    /// Redundant transitions are dropped (UIKit never sends one twice), and
    /// backgrounding from active resigns first even if the host forgot to.
    func testRedundantAndImpliedTransitions() {
        let app = UIApplication.shared
        let delegate = RecordingApplicationDelegate()
        let previous = app.delegate
        defer { app.delegate = previous }

        UIApplicationMain(delegate: delegate)
        app._hostDidBecomeActive()
        app._hostDidBecomeActive()          // dropped
        app._hostWillEnterForeground()      // dropped: not backgrounded
        app._hostDidEnterBackground()       // implies willResignActive
        app._hostDidEnterBackground()       // dropped
        app._hostWillTerminate()
        app._hostWillTerminate()            // dropped

        XCTAssertEqual(delegate.log, [
            "willFinishLaunching",
            "didFinishLaunching(state=inactive)",
            "didBecomeActive(state=active)",
            "willResignActive(state=active)",
            "didEnterBackground(state=background)",
            "willTerminate",
        ])
    }

    /// Scene activation follows the application's, and the scene delegate
    /// hears about it.
    func testSceneActivationFollowsApplication() {
        final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
            var window: UIWindow?
            var log: [String] = []
            func sceneDidBecomeActive(_ scene: UIScene) { log.append("active") }
            func sceneWillResignActive(_ scene: UIScene) { log.append("resign") }
            func sceneDidEnterBackground(_ scene: UIScene) { log.append("background") }
            func sceneWillEnterForeground(_ scene: UIScene) { log.append("foreground") }
        }
        let app = UIApplication.shared
        let appDelegate = RecordingApplicationDelegate()
        let previous = app.delegate
        defer { app.delegate = previous }
        UIApplicationMain(delegate: appDelegate)

        let scene = UIWindowScene()
        let sceneDelegate = SceneDelegate()
        scene.delegate = sceneDelegate
        app._connect(scene: scene)
        defer { app._disconnect(scene: scene) }
        XCTAssertEqual(scene.activationState, .foregroundInactive)

        app._hostDidBecomeActive()
        XCTAssertEqual(scene.activationState, .foregroundActive)
        app._hostDidEnterBackground()
        XCTAssertEqual(scene.activationState, .background)
        app._hostWillEnterForeground()
        XCTAssertEqual(scene.activationState, .foregroundInactive)

        XCTAssertEqual(sceneDelegate.log, ["active", "resign", "background", "foreground"])
        app._hostWillTerminate()
    }

    /// Windows register themselves and makeKey picks the key window.
    func testWindowRegistrationAndKeyWindow() {
        let app = UIApplication.shared
        let a = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let b = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertTrue(app.windows.contains { $0 === a })
        XCTAssertTrue(app.windows.contains { $0 === b })
        b.makeKeyAndVisible()
        XCTAssertTrue(app.keyWindow === b)
        XCTAssertTrue(b.isKeyWindow)
        XCTAssertFalse(a.isKeyWindow)
        a.makeKey()
        XCTAssertTrue(app.keyWindow === a)
    }

    /// A window with a root controller installs its view at the window's
    /// bounds; replacing the controller swaps the view out.
    func testRootViewControllerInstallsAndReplaces() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let first = UIViewController()
        window.rootViewController = first
        XCTAssertTrue(window.subviews.contains { $0 === first.view })
        XCTAssertEqual(first.view.frame.width, 320)
        XCTAssertEqual(first.view.frame.height, 480)

        let second = UIViewController()
        window.rootViewController = second
        XCTAssertFalse(window.subviews.contains { $0 === first.view })
        XCTAssertTrue(window.subviews.contains { $0 === second.view })
    }

    /// The nil-target action walks the chain from the first responder and
    /// stops at the first responder that handles it.
    func testSendActionWalksTheChain() {
        final class Focusable: UIView {
            override var canBecomeFirstResponder: Bool { true }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.makeKey()
        let mid = UIView()
        let leaf = Focusable()
        window.addSubview(mid)
        mid.addSubview(leaf)
        XCTAssertTrue(leaf.becomeFirstResponder())

        var visited: [ObjectIdentifier] = []
        let handled = UIApplication.shared.sendAction({ responder in
            visited.append(ObjectIdentifier(responder))
            return responder === mid   // only `mid` handles it
        }, to: nil, from: nil, for: nil)

        XCTAssertTrue(handled)
        XCTAssertEqual(visited, [ObjectIdentifier(leaf), ObjectIdentifier(mid)])
        leaf.resignFirstResponder()
    }

    /// open()/canOpenURL are inert without a host handler, and route to it
    /// when one is installed.
    func testOpenURLIsAHostHook() {
        let app = UIApplication.shared
        XCTAssertNil(UIApplication.urlOpenHandler)
        XCTAssertFalse(app.canOpenURL("https://example.com"))
        var reported: Bool?
        app.open("https://example.com") { reported = $0 }
        XCTAssertEqual(reported, false)

        var opened: [String] = []
        UIApplication.urlOpenHandler = { opened.append($0); return true }
        defer { UIApplication.urlOpenHandler = nil }
        XCTAssertTrue(app.canOpenURL("https://example.com"))
        app.open("https://example.com") { reported = $0 }
        XCTAssertEqual(opened, ["https://example.com"])
        XCTAssertEqual(reported, true)
    }
}

// MARK: - Environment

final class ScreenDeviceTests: XCTestCase {
    func testScreenIsHostDrivenAndPixelsFollowScale() {
        let screen = UIScreen.main
        let savedBounds = screen.bounds
        let savedScale = screen.scale
        defer { screen._hostConfigure(bounds: savedBounds, scale: savedScale) }

        screen._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                              scale: 3)
        XCTAssertEqual(screen.bounds.width, 390)
        XCTAssertEqual(screen.bounds.height, 844)
        XCTAssertEqual(screen.scale, 3)
        XCTAssertEqual(screen.nativeScale, 3)
        XCTAssertEqual(screen.nativeBounds.width, 1170)
        XCTAssertEqual(screen.nativeBounds.height, 2532)
        XCTAssertEqual(screen.traitCollection.displayScale, 3)
        XCTAssertEqual(UIScreen.screens.count, 1)

        // The origin is always zero, whatever the host passes.
        screen._hostConfigure(bounds: CGRect(x: 20, y: 40, width: 200, height: 100),
                              scale: 2)
        XCTAssertEqual(screen.bounds.minX, 0)
        XCTAssertEqual(screen.bounds.minY, 0)
        XCTAssertEqual(screen.nativeBounds.width, 400)
    }

    /// A window built from the screen's bounds is the surface the host set.
    func testWindowFromScreenBounds() {
        let screen = UIScreen.main
        let savedBounds = screen.bounds
        let savedScale = screen.scale
        defer { screen._hostConfigure(bounds: savedBounds, scale: savedScale) }
        screen._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                              scale: 2)
        let w = UIWindow(frame: UIScreen.main.bounds)
        XCTAssertEqual(w.bounds.width, 375)
        XCTAssertEqual(w.bounds.height, 667)
    }

    /// Documented fixed values (see UIDevice.swift's header).
    func testDeviceReportsDocumentedFixedValues() {
        let d = UIDevice.current
        XCTAssertEqual(d.userInterfaceIdiom, .phone)
        XCTAssertEqual(d.systemName, "iOS")
        XCTAssertEqual(d.systemVersion, "26.1")
        XCTAssertEqual(d.model, "iPhone")
        XCTAssertEqual(d.orientation, .portrait)
        XCTAssertTrue(d.orientation.isPortrait)
        XCTAssertEqual(d.batteryState, .unknown)
        XCTAssertEqual(d.batteryLevel, -1)
        XCTAssertTrue(UIDevice.current === d, "single shared instance")
    }
}
