import XCTest
@testable import OpenUIKit

@MainActor
final class ApplicationShellCompatibilityTests: XCTestCase {
    private final class ActivityRestorer: UIUserActivityRestoring {
        var restoredType: String?

        func restoreUserActivityState(_ userActivity: NSUserActivity) {
            restoredType = userActivity.activityType
        }
    }

    private final class OverridingActivity: NSUserActivity {
        override var activityType: String { super.activityType + ".override" }
    }

    func testSceneWindowUsesSceneScreenAndWindowLevelsSupportArithmetic() {
        let scene = UIWindowScene()
        let window = UIWindow(windowScene: scene)

        XCTAssertTrue(window.windowScene === scene)
        XCTAssertEqual(window.frame, scene.screen.bounds)
        XCTAssertEqual(window.windowLevel, .normal)

        window.windowLevel = .alert + 1
        XCTAssertEqual(window.windowLevel.rawValue, 2_001)
        XCTAssertGreaterThan(window.windowLevel, .statusBar)
    }

    func testNavigationAppearanceProxyIsInheritedByNewBars() {
        let proxy = UINavigationBar.appearance()
        let originalStandard = proxy.standardAppearance
        let originalEdge = proxy.scrollEdgeAppearance
        defer {
            proxy.standardAppearance = originalStandard
            proxy.scrollEdgeAppearance = originalEdge
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemPurple
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemOrange,
        ]
        let indicator = UIImage(bitmap: Bitmap(width: 1, height: 1))
        appearance.setBackIndicatorImage(indicator, transitionMaskImage: indicator)
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance

        let bar = UINavigationBar()
        XCTAssertTrue(bar.standardAppearance === appearance)
        XCTAssertTrue(bar.scrollEdgeAppearance === appearance)
        XCTAssertTrue(appearance.backIndicatorImage === indicator)
        XCTAssertTrue(appearance.backIndicatorTransitionMaskImage === indicator)

        bar.setState(title: "Details", backTitle: "Back")
        XCTAssertEqual(bar.backButton?.backLabel.textColor, .systemOrange)
        XCTAssertEqual(bar.backButton?.chevron.textColor, .systemOrange)
    }

    func testOverlayPresentationFillsWindowWithoutRemovingPresenter() {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = presenter

        let overlay = UIViewController()
        overlay.modalPresentationStyle = .overCurrentContext
        presenter.present(overlay, animated: false)

        XCTAssertEqual(overlay.view.frame, window.bounds)
        XCTAssertNotNil(presenter.view.superview)
        XCTAssertTrue(presenter.presentedViewController === overlay)
    }

    func testFoundationURLUsesThePortableHostHook() {
        let prior = UIApplication.urlOpenHandler
        defer { UIApplication.urlOpenHandler = prior }
        var opened: String?
        UIApplication.urlOpenHandler = {
            opened = $0
            return $0 == "https://example.com/path"
        }

        let url = URL(string: "https://example.com/path")!
        XCTAssertTrue(UIApplication.shared.canOpenURL(url))
        var result: Bool?
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) {
            result = $0
        }
        XCTAssertEqual(opened, url.absoluteString)
        XCTAssertEqual(result, true)
        XCTAssertEqual(UIApplication.openSettingsURLString, "app-settings:")
    }

    func testShortcutAndIncomingURLMetadataShapes() {
        let icon = UIApplicationShortcutIcon(systemImageName: "trash")
        let item = UIApplicationShortcutItem(
            type: "org.example.erase", localizedTitle: "Erase",
            localizedSubtitle: "Erase and open", icon: icon)
        XCTAssertEqual(item.type, "org.example.erase")
        XCTAssertEqual(item.localizedTitle, "Erase")
        XCTAssertEqual(item.localizedSubtitle, "Erase and open")
        XCTAssertTrue(item.icon === icon)

        let options: [UIApplication.OpenURLOptionsKey: Any] = [
            .sourceApplication: "org.example.sender",
            .openInPlace: true,
        ]
        XCTAssertEqual(options[.sourceApplication] as? String,
                       "org.example.sender")

        let restorer = ActivityRestorer()
        restorer.restoreUserActivityState(NSUserActivity(activityType: "org.example.activity"))
        XCTAssertEqual(restorer.restoredType, "org.example.activity")

        let overridden = OverridingActivity(activityType: "org.example.activity")
        let object: NSObject = overridden
        XCTAssertTrue(object === overridden)
        XCTAssertEqual(overridden.activityType, "org.example.activity.override")
    }
}
