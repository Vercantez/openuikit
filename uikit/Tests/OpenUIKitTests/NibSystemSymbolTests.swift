import XCTest
@testable import OpenUIKit

/// SF Symbols chosen in Interface Builder (NetNewsWire's section-header
/// chevron, its filter button) archive `UISystemSymbolResourceName`.
/// fixtures/nibsymbol/SymbolView.nib is compiled by ibtool from
/// SymbolView.xib. MEASURED Tools/oracle2/listheaderprobe (it loads the same
/// nib; transcript-ios26.1.txt `FACT nibsymbol`): the image view's image and
/// the button's normal image are symbol images, the same size as
/// `UIImage(systemName:)` of "chevron.down" (18.67 x 10.33) and
/// "line.3.horizontal.decrease" (21 x 12).
@MainActor
final class NibSystemSymbolTests: XCTestCase {
    func testInterfaceBuilderSymbolsLoadAsSystemImages() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let savedRoot = OpenUIKitRuntime.resourceRoot
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedScale = OpenUIKitRuntime.imageScreenScale
        OpenUIKitRuntime.resourceRoot = root.path + "/Sources/OpenUIKit/Resources"
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.imageScreenScale = 3
        defer {
            OpenUIKitRuntime.resourceRoot = savedRoot
            OpenUIKitRuntime.systemFontCut = savedCut
            OpenUIKitRuntime.imageScreenScale = savedScale
        }
        let expectedChevron = try XCTUnwrap(UIImage(systemName: "chevron.down"))
        let expectedFilter = try XCTUnwrap(UIImage(systemName: "line.3.horizontal.decrease"))
        let data = try Data(contentsOf: root.appendingPathComponent("fixtures/nibsymbol/SymbolView.nib"))
        let view = try XCTUnwrap(UINib(data: data, bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView)
        let imageView = try XCTUnwrap(view.subviews.compactMap { $0 as? UIImageView }.first)
        let button = try XCTUnwrap(view.subviews.compactMap { $0 as? UIButton }.first)

        let chevron = try XCTUnwrap(imageView.image, "chevron.down")
        XCTAssertTrue(chevron.isSymbolImage)
        XCTAssertEqual(chevron.size, expectedChevron.size)
        XCTAssertEqual(chevron.size.width, 18.667, accuracy: 0.01)
        XCTAssertEqual(chevron.size.height, 10.333, accuracy: 0.01)
        let filter = try XCTUnwrap(button.image(for: .normal), "line.3.horizontal.decrease")
        XCTAssertTrue(filter.isSymbolImage)
        XCTAssertEqual(filter.size, expectedFilter.size)
        XCTAssertEqual(filter.size.width, 21, accuracy: 0.01)
        XCTAssertEqual(filter.size.height, 12, accuracy: 0.01)
    }
}
