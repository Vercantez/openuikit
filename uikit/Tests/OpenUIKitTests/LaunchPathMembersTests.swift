import XCTest
@testable import OpenUIKit

/// NetNewsWire launch-path members (AppDelegate / SceneDelegate /
/// SceneCoordinator / RootSplitViewController / MainFeed). MEASURED iPhone 16 /
/// iOS 26.1: Tools/oracle2/scenelaunchprobe/transcript-ios26.1.txt and
/// transcript-poporder-ios26.1.txt.
@MainActor
final class LaunchPathMembersTests: XCTestCase {
    func testBackgroundTaskIdentifiersAndFetchResult() {
        XCTAssertEqual(UIBackgroundTaskIdentifier.invalid.rawValue, 0)
        XCTAssertEqual(UIBackgroundFetchResult.newData.rawValue, 0)
        XCTAssertEqual(UIBackgroundFetchResult.noData.rawValue, 1)
        XCTAssertEqual(UIBackgroundFetchResult.failed.rawValue, 2)
        let app = UIApplication.shared
        var expired = 0
        let t1 = app.beginBackgroundTask { expired += 1 }
        let t2 = app.beginBackgroundTask(withName: "probe") { expired += 1 }
        XCTAssertNotEqual(t1, .invalid)
        XCTAssertNotEqual(t2, .invalid)
        XCTAssertNotEqual(t1, t2)
        // measured in the foreground: no budget running down
        XCTAssertEqual(app.backgroundTimeRemaining, .greatestFiniteMagnitude)
        app.endBackgroundTask(t1)
        app.endBackgroundTask(t2)
        app.endBackgroundTask(t2)
        app.endBackgroundTask(.invalid)
        XCTAssertEqual(expired, 0)
    }

    private final class RemoteDelegate: UIResponder, UIApplicationDelegate {
        var events: [String] = []
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            events.append("token")
        }
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            let e = error as NSError
            events.append("fail \(e.domain) \(e.code) \(e.localizedDescription)")
        }
    }

    func testRegisterForRemoteNotificationsFailsAsynchronouslyLikeAnUnentitledApp() {
        let app = UIApplication.shared
        let saved = app.delegate
        let d = RemoteDelegate()
        app.delegate = d
        defer { app.delegate = saved }
        XCTAssertFalse(app.isRegisteredForRemoteNotifications)
        app.registerForRemoteNotifications()
        XCTAssertFalse(app.isRegisteredForRemoteNotifications)
        XCTAssertEqual(d.events, [], "measured: delivered after the call returns")
        let done = expectation(description: "delivered")
        DispatchQueue.main.async { done.fulfill() }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(d.events, ["fail NSCocoaErrorDomain 3000 no valid \u{201C}aps-environment\u{201D} entitlement string found for application"])
        XCTAssertFalse(app.isRegisteredForRemoteNotifications)
    }

    func testStatusBarDefaults() {
        XCTAssertEqual(UIStatusBarAnimation.none.rawValue, 0)
        XCTAssertEqual(UIStatusBarAnimation.fade.rawValue, 1)
        XCTAssertEqual(UIStatusBarAnimation.slide.rawValue, 2)
        let vc = UIViewController()
        XCTAssertFalse(vc.prefersStatusBarHidden)
        XCTAssertEqual(vc.preferredStatusBarUpdateAnimation, .fade)
        vc.setNeedsStatusBarAppearanceUpdate()
        let split = UISplitViewController(style: .doubleColumn)
        XCTAssertFalse(split.prefersStatusBarHidden)
        XCTAssertEqual(split.preferredStatusBarUpdateAnimation, .fade)
    }

#if !os(Linux) // swift-corelibs-foundation has no UndoManager
    func testUndoManagerComesFromTheWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        XCTAssertNotNil(window.undoManager)
        XCTAssertTrue(vc.undoManager === window.undoManager)
        XCTAssertTrue(vc.view.undoManager === window.undoManager)
        XCTAssertTrue(window.undoManager === window.undoManager, "one per window")
        XCTAssertNil(UIViewController().undoManager)
        XCTAssertNil(UIApplication.shared.undoManager)
    }
#endif

    func testNavigationItemSubtitleFlexibleSpaceAndMenu() {
        let item = UINavigationItem(title: "t")
        XCTAssertNil(item.subtitle)
        XCTAssertNil(item.subtitleView)
        item.subtitle = "Updated"
        XCTAssertEqual(item.subtitle, "Updated")
        let flex = UIBarButtonItem.flexibleSpace()
        XCTAssertNil(flex.title)
        XCTAssertNil(flex.image)
        XCTAssertEqual(flex.width, 0)
        XCTAssertTrue(flex.isEnabled)
        XCTAssertNil(flex.target)
        XCTAssertNil(flex.action)
        XCTAssertNil(flex.menu)
        XCTAssertEqual(UIBarButtonItem.fixedSpace(12).width, 12)
        let menu = UIMenu(title: "", children: [])
        flex.menu = menu
        XCTAssertTrue(flex.menu === menu)
    }

    func testContextualActionAccessibilityLabel() {
        let a = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in done(true) }
        XCTAssertNil(a.accessibilityLabel)
        a.accessibilityLabel = "x"
        XCTAssertEqual(a.accessibilityLabel, "x")
    }

    private final class Named: UIViewController {
        let n: String
        init(_ n: String) { self.n = n; super.init(nibName: nil, bundle: nil) }
        required init?(coder: NSCoder) { fatalError() }
    }

    private func names(_ vcs: [UIViewController]?) -> String {
        vcs.map { "[" + $0.map { ($0 as? Named)?.n ?? "?" }.joined(separator: " ") + "]" } ?? "nil"
    }

    func testPopToViewControllerMatchesMeasuredOrder() {
        let a = Named("a"), b = Named("b"), c = Named("c"), d = Named("d")
        let nav = UINavigationController(rootViewController: a)
        for v in [b, c, d] { nav.pushViewController(v, animated: false) }
        XCTAssertEqual(names(nav.popToViewController(b, animated: false)), "[c d]")
        XCTAssertEqual(names(nav.viewControllers), "[a b]")
        for v in [c, d] { nav.pushViewController(v, animated: false) }
        XCTAssertEqual(names(nav.popToRootViewController(animated: false)), "[b c d]")
        XCTAssertEqual(names(nav.popToRootViewController(animated: false)), "nil")
        nav.pushViewController(b, animated: false)
        XCTAssertEqual(names(nav.popToViewController(b, animated: false)), "nil", "already on top")
        XCTAssertEqual(names(nav.popToViewController(Named("x"), animated: false)), "nil", "not in the stack")
        XCTAssertEqual(names(nav.viewControllers), "[a b]")
    }

    private final class SafeAreaVC: UIViewController {
        var seen: [UIEdgeInsets] = []
        override func viewSafeAreaInsetsDidChange() {
            super.viewSafeAreaInsetsDidChange()
            seen.append(view.safeAreaInsets)
        }
    }

    func testViewSafeAreaInsetsDidChangeFollowsTheRootView() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let vc = SafeAreaVC()
        window.rootViewController = vc
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        XCTAssertEqual(vc.seen.last, UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        let count = vc.seen.count
        window.layoutIfNeeded()
        XCTAssertEqual(vc.seen.count, count, "no change, no callback")
    }

    func testStoryboardIdentifierGenericAndSceneOptions() {
        // iOS 13 spelling: `instantiateViewController(identifier:)` returns the
        // generic's default UIViewController when only `as!` follows.
        // (Compile-only: typechecks exactly like the iOS 26.1 SDK, see
        // scratch inst_probe in the report; not executed.)
        let sb = UIStoryboard(name: "Missing", bundle: nil)
        let later: () -> UINavigationController = {
            sb.instantiateViewController(identifier: "Nav") as! UINavigationController
        }
        let typed: () -> UIViewController = { sb.instantiateViewController(identifier: "Root") }
        _ = (later, typed)
        let options = UIScene.ConnectionOptions()
        XCTAssertTrue(options.urlContexts.isEmpty)
#if (canImport(AppKit) || os(iOS)) && canImport(UserNotifications)
        XCTAssertNil(options.notificationResponse)
#endif
        XCTAssertNil(UISceneSession().stateRestorationActivity)
    }
}
