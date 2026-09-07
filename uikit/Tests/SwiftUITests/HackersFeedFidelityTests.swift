import XCTest
#if os(Linux)
@preconcurrency @testable import SwiftUI
@preconcurrency @testable import OpenUIKit
#else
@testable import SwiftUI
@testable import OpenUIKit
#endif

private struct MeasuredFeedRows: View {
    var body: some View {
        List {
            Color.red.frame(height: 97 + 1.0 / 3)
            Color.blue.frame(height: 77)
        }.listStyle(.plain)
    }
}

private struct MeasuredFeedToolbar: View {
    var body: some View {
        Text("Feed").toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly).font(.headline).foregroundStyle(.primary)
                }
            }
        }.searchable(text: .constant(""), placement: .toolbar)
    }
}

#if !os(Linux)
@MainActor
#endif
final class HackersFeedFidelityTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedImageScale: CGFloat = 1
    private var savedScale: CGFloat = 1
    private var savedBounds = CGRect.zero
    private var savedRoot = ""

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedImageScale = OpenUIKitRuntime.imageScreenScale
        OpenUIKitRuntime.imageScreenScale = 3
        savedScale = UIScreen.main.scale
        savedBounds = UIScreen.main.bounds
        savedRoot = OpenUIKitRuntime.resourceRoot
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        OpenUIKitRuntime.resourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
    }

    override func tearDown() {
        OpenUIKitRuntime.imageScreenScale = savedImageScale
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        OpenUIKitRuntime.resourceRoot = savedRoot
        super.tearDown()
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }

    // HackersRowMetrics, iPhone 16 / iOS 26.1 @3x: content heights
    // 97.333 / 77, row heights 127.333 / 107; top and bottom inset 15.
    func testPlainListInsetsAreFifteenPointsOutsideMeasuredContent() throws {
        let host = UIHostingController(rootView: MeasuredFeedRows())
        host.view.frame = UIScreen.main.bounds
        host.view.layoutIfNeeded()
        let first = try XCTUnwrap(descendants(host.view).first { $0.accessibilityIdentifier == "SwiftUI.List.row.0" })
        let second = try XCTUnwrap(descendants(host.view).first { $0.accessibilityIdentifier == "SwiftUI.List.row.1" })
        XCTAssertEqual(first.frame.height, 127 + 1.0 / 3, accuracy: 0.001)
        XCTAssertEqual(second.frame.height, 107, accuracy: 0.001)
        XCTAssertEqual(second.frame.minY, first.frame.maxY, accuracy: 0.001)
        XCTAssertEqual(first.subviews.first?.frame.minY ?? -1, 15, accuracy: 0.001)
    }

    func testCatalystListKeepsItsExistingInsets() throws {
        OpenUIKitRuntime.systemFontCut = .macOS
        let host = UIHostingController(rootView: MeasuredFeedRows())
        host.view.frame = UIScreen.main.bounds
        host.view.layoutIfNeeded()
        XCTAssertFalse(descendants(host.view).contains { $0.accessibilityIdentifier == "SwiftUI.List.row.0" })
    }

    // The native toolbar's UIImageView reports body / medium / large;
    // its alignment box is 27.333 x 27 at window (285.333, 68), inside
    // the gear's [277, 59, 44, 44] platter. The 23 x 23 missing region
    // is the ink inside this alignment box, not an absent toolbar entry.
    func testToolbarGearUsesHarvestedNativeSymbolAndMeasuredAlignment() throws {
        let host = UIHostingController(rootView: MeasuredFeedToolbar())
        let nav = UINavigationController(rootViewController: host)
        nav.view.frame = UIScreen.main.bounds
        nav.view.layoutIfNeeded()
        nav.navigationBar.layoutIfNeeded()
        let items = try XCTUnwrap(host.navigationItem.rightBarButtonItems)
        XCTAssertEqual(items.count, 2)
        let gear = try XCTUnwrap(items.last)
        let image = try XCTUnwrap(gear.image, "the toolbar must use UIKit symbol ink instead of a blank SwiftUI symbol view")
        XCTAssertTrue(image.isSymbolImage)
        XCTAssertEqual(image.size.width, 27 + 1.0 / 3, accuracy: 0.001)
        XCTAssertEqual(image.size.height, 27, accuracy: 0.001)
        let itemView = try XCTUnwrap(nav.navigationBar.rightItemViews.last)
        itemView.layoutIfNeeded()
        XCTAssertFalse(itemView.imageView.isHidden)
        XCTAssertNotNil(itemView.imageView.image)
        XCTAssertEqual(itemView.frame.minX, 277, accuracy: 0.001)
        XCTAssertEqual(itemView.imageView.frame.minX, 8 + 1.0 / 3, accuracy: 0.001)
        XCTAssertEqual(itemView.imageView.frame.minY, 9, accuracy: 0.001)
    }
}
