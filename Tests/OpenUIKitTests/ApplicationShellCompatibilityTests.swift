import XCTest
@testable import OpenUIKit

@MainActor
final class ApplicationShellCompatibilityTests: XCTestCase {
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
}
