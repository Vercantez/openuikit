import XCTest
@testable import OpenUIKit

/// UIViewController.overrideUserInterfaceStyle. MEASURED iPhone 16 / iOS 26.1:
/// Tools/oracle2/vcstyleprobe/transcript-ios26.1.txt.
@MainActor
final class ControllerStyleOverrideTests: XCTestCase {
    func testControllerOverrideResolvesThroughItsViewSubtreeAndChildren() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        XCTAssertEqual(root.traitCollection.userInterfaceStyle, .light)

        let vc = UIViewController()
        XCTAssertEqual(vc.overrideUserInterfaceStyle, .unspecified)
        vc.overrideUserInterfaceStyle = .dark
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertEqual(vc.traitCollection.userInterfaceStyle, .dark, "before the view loads")

        let sub = UIView()
        vc.view.addSubview(sub)
        XCTAssertEqual(vc.view.overrideUserInterfaceStyle, .unspecified, "the view's own override is untouched")
        XCTAssertEqual(vc.view.traitCollection.userInterfaceStyle, .dark)

        let child = UIViewController()
        vc.addChild(child); vc.view.addSubview(child.view); child.didMove(toParent: vc)
        XCTAssertEqual(child.overrideUserInterfaceStyle, .unspecified)
        XCTAssertEqual(child.traitCollection.userInterfaceStyle, .dark)

        root.addChild(vc); root.view.addSubview(vc.view); vc.didMove(toParent: root)
        XCTAssertEqual(root.traitCollection.userInterfaceStyle, .light)
        XCTAssertEqual(vc.traitCollection.userInterfaceStyle, .dark)
        XCTAssertEqual(vc.view.traitCollection.userInterfaceStyle, .dark)
        XCTAssertEqual(sub.traitCollection.userInterfaceStyle, .dark)

        vc.overrideUserInterfaceStyle = .unspecified
        XCTAssertEqual(vc.traitCollection.userInterfaceStyle, .light)
    }
}
