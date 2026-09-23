import XCTest
@testable import OpenUIKit

/// A storyboard scene's "Toolbar Items" (archived `UIToolbarItems` on the view
/// controller; NetNewsWire's Feeds scene: Settings "gear", a flexible space,
/// Add "plus") become the controller's `toolbarItems`, which the navigation
/// controller's toolbar then shows. The fixture (fixtures/toolbarstoryboard,
/// ibtool of Toolbar.storyboard) archives the same three items. Before this the
/// key was ignored, the controller had no items, and the iOS toolbar slot was
/// empty (NetNewsWire's glass toolbar sat off screen at y 852).
@MainActor
final class ToolbarStoryboardTests: XCTestCase {
    func testSceneToolbarItemsBecomeTheControllersToolbarItems() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("fixtures/toolbarstoryboard").path
        let saved = (OpenUIKitRuntime.nibSearchPaths, OpenUIKitRuntime.systemFontCut,
                     OpenUIKitRuntime.imageScreenScale, OpenUIKitRuntime.resourceRoot)
        OpenUIKitRuntime.nibSearchPaths = [fixtures]
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.imageScreenScale = 3
        OpenUIKitRuntime.resourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
        defer {
            OpenUIKitRuntime.nibSearchPaths = saved.0
            OpenUIKitRuntime.systemFontCut = saved.1
            OpenUIKitRuntime.imageScreenScale = saved.2
            OpenUIKitRuntime.resourceRoot = saved.3
        }
        let nav = try XCTUnwrap(UIStoryboard(name: "Toolbar", bundle: nil)
            .instantiateInitialViewController() as? UINavigationController)
        let root = try XCTUnwrap(nav.topViewController)
        let items = try XCTUnwrap(root.toolbarItems)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].title, "Settings")
        XCTAssertNotNil(items[0].image)
        XCTAssertTrue(items[1]._isFlexibleSpace)
        XCTAssertEqual(items[2].title, "Add")
        XCTAssertNotNil(items[2].image)

        // The identifier-instantiated scene carries them too.
        let byID = UIStoryboard(name: "Toolbar", bundle: nil).instantiateViewController(withIdentifier: "Root")
        XCTAssertEqual(byID.toolbarItems?.count, 3)
    }
}
