import XCTest
@testable import OpenUIKit

/// A column-style split view controller from a storyboard. MEASURED on real
/// NetNewsWire (Tools/oracle2/nnwgolden/SplitFacts.m, iPhone 16 / iOS 26.1):
/// archived `UISplitViewControllerStyle = 2` gives style 2 (tripleColumn);
/// the three archived children are primary / supplementary / secondary;
/// preferredDisplayMode 2, preferredSplitBehavior 1, primaryBackgroundStyle 1,
/// primaryEdge 0 as archived. The fixture (fixtures/splitstoryboard, ibtool of
/// Split.storyboard) archives exactly NetNewsWire's split keys. Before this,
/// init(coder:) left the style unspecified and the first column API trapped.
@MainActor
final class SplitStoryboardTests: XCTestCase {
    func testTripleColumnSplitDecodesStyleColumnsAndConfiguration() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("fixtures/splitstoryboard").path
        let saved = OpenUIKitRuntime.nibSearchPaths
        OpenUIKitRuntime.nibSearchPaths = [fixtures]
        defer { OpenUIKitRuntime.nibSearchPaths = saved }
        let split = try XCTUnwrap(UIStoryboard(name: "Split", bundle: nil)
            .instantiateInitialViewController() as? UISplitViewController)
        XCTAssertEqual(split.style, .tripleColumn)
        XCTAssertEqual(split.viewController(for: .primary)?.title, "Primary")
        XCTAssertEqual(split.viewController(for: .supplementary)?.title, "Supplementary")
        XCTAssertEqual(split.viewController(for: .secondary)?.title, "Secondary")
        XCTAssertEqual(split.preferredDisplayMode.rawValue, 2)
        XCTAssertEqual(split.preferredSplitBehavior.rawValue, 1)
        XCTAssertEqual(split.primaryBackgroundStyle.rawValue, 1)
        XCTAssertEqual(split.primaryEdge.rawValue, 0)
    }
}
