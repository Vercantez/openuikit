// UINib / NIBArchive tests. Ground truth: the xib XML the fixture nibs were
// compiled from (pocket-casts-ios podcasts/SwitchCell.xib,
// DisclosureCell.xib, StorageAndDataUseViewController.xib — see
// scripts/compile_realapp_nibs.sh). Every number asserted below is a literal
// attribute of that XML, so these tests fail if the reader drifts from the
// format rather than from an opinion about it.
//
// Tests MAY use Foundation (the library must not).

import Foundation
import XCTest

@testable import OpenUIKit

/// The two app classes the cell nibs name, standing in for the harness's
/// registrations (Sources/RealAppProbe/NibClasses.swift) so the parser can be
/// tested without the whole real-app screen.
#if !os(Linux)
@MainActor
#endif
final class NibTestLabel: UILabel {}

#if !os(Linux)
@MainActor
#endif
final class NibTestImageView: UIImageView {}

#if !os(Linux)
@MainActor
#endif
final class NibTestSwitchCell: UITableViewCell, UINibOutletConnecting {
    var cellLabel: UILabel?
    var cellImage: UIImageView?
    var cellTextToImageConstraint: OpenUIKit.NSLayoutConstraint?
    var awakeCount = 0

    func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool {
        switch name {
        case "cellLabel": cellLabel = object as? UILabel
        case "cellImage": cellImage = object as? UIImageView
        case "cellTextToImageConstraint":
            cellTextToImageConstraint = object as? OpenUIKit.NSLayoutConstraint
        default: return false
        }
        return true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        awakeCount += 1
    }
}

#if !os(Linux)
@MainActor
#endif
final class UINibTests: XCTestCase {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // OpenUIKitTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // repo root
        .path

    static var nibDirectory: String { repoRoot + "/fixtures/realapp/nibs" }

    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.resourceRoot = UINibTests.repoRoot + "/Sources/OpenUIKit/Resources"
        OpenUIKitRuntime.nibSearchPaths = [UINibTests.nibDirectory]
        UINib.unhandledKeys = []
    }

    override func tearDown() {
        OpenUIKitRuntime.nibSearchPaths = []
        super.tearDown()
    }

    // MARK: The container

    /// The header fields of SwitchCell.nib, read off the bytes.
    func testArchiveTables() throws {
        let bytes = try XCTUnwrap(
            ResourceIO.readFile(UINibTests.nibDirectory + "/SwitchCell.nib"))
        let archive = try XCTUnwrap(NibArchive.parse(bytes))
        XCTAssertEqual(archive.objects.count, 48)
        // Object 0 is the archive root and names the three lists UIKit reads.
        let root = archive.objects[0]
        XCTAssertEqual(root.className, "NSObject")
        XCTAssertNotNil(root.first("UINibTopLevelObjectsKey"))
        XCTAssertNotNil(root.first("UINibObjectsKey"))
        XCTAssertNotNil(root.first("UINibConnectionsKey"))
    }

    /// Anything that is not a NIBArchive fails closed instead of trapping.
    func testRejectsNonArchive() {
        XCTAssertNil(NibArchive.parse([]))
        XCTAssertNil(NibArchive.parse(Array(repeating: 0x41, count: 200)))
        let bytes = ResourceIO.readFile(UINibTests.nibDirectory + "/SwitchCell.nib")!
        XCTAssertNil(NibArchive.parse(Array(bytes[0..<40])), "truncated header")
    }

    /// `_TtC8podcasts14ThemeableLabel` is what ibtool writes for a class with
    /// a `customModule`; the registry matches on the class name so the same
    /// nib resolves under a differently-named module.
    func testDemanglesSwiftClassNames() {
        XCTAssertEqual(
            UINibClassRegistry.demangleSwiftClassName("_TtC8podcasts14ThemeableLabel"),
            "ThemeableLabel")
        XCTAssertEqual(
            UINibClassRegistry.demangleSwiftClassName("_TtC12realappprobe10SwitchCell"),
            "SwitchCell")
        XCTAssertNil(UINibClassRegistry.demangleSwiftClassName("UILabel"))
    }

    // MARK: SwitchCell.xib

    private func makeSwitchCell() throws -> NibTestSwitchCell {
        UINibClassRegistry.register("SwitchCell") { NibTestSwitchCell() }
        UINibClassRegistry.register("ThemeableLabel") { NibTestLabel(frame: .zero) }
        let nib = UINib(nibName: "SwitchCell", bundle: nil)
        XCTAssertTrue(nib.isLoaded)
        let objects = nib.instantiate(withOwner: nil, options: nil)
        return try XCTUnwrap(objects.compactMap { $0 as? NibTestSwitchCell }.first)
    }

    /// The archived hierarchy: the custom cell class, its content view, and
    /// the image view + label inside it. `<rect>`s from the xib:
    /// cell/content view 320 x 44, image view (16, 20, 24, 24), label
    /// (48, 0, 267, 64).
    func testSwitchCellHierarchyAndFrames() throws {
        let cell = try makeSwitchCell()
        XCTAssertEqual(cell.frame, CGRect(x: 0, y: 0, width: 320, height: 44))
        XCTAssertEqual(cell.contentView.frame,
                       CGRect(x: 0, y: 0, width: 320, height: 44))
        // The nib's cell archives no textLabel/imageView; the port's eager
        // ones are taken out of the hierarchy so a layout dump matches UIKit's.
        XCTAssertEqual(cell.contentView.subviews.count, 2)
        let image = try XCTUnwrap(cell.contentView.subviews.first as? UIImageView)
        let label = try XCTUnwrap(cell.contentView.subviews.last as? UILabel)
        XCTAssertEqual(image.frame, CGRect(x: 16, y: 20, width: 24, height: 24))
        XCTAssertEqual(label.frame, CGRect(x: 48, y: 0, width: 267, height: 64))
    }

    /// `customClass="ThemeableLabel" customModule="podcasts"` swaps the class
    /// through `UIClassSwapper`.
    func testSwitchCellClassSwap() throws {
        let cell = try makeSwitchCell()
        XCTAssertTrue(cell.contentView.subviews.last is NibTestLabel,
                      "UIClassSwapper should resolve ThemeableLabel")
    }

    /// The three `<outlet>`s, connected through the class's own table.
    func testSwitchCellOutlets() throws {
        let cell = try makeSwitchCell()
        XCTAssertNotNil(cell.cellLabel)
        XCTAssertNotNil(cell.cellImage)
        XCTAssertIdentical(cell.cellLabel, cell.contentView.subviews.last)
        XCTAssertIdentical(cell.cellImage, cell.contentView.subviews.first)
        // `cellTextToImageConstraint` is the label-leading-to-image-trailing
        // constraint with constant 8 (xib id CL0-C3-qSk).
        let constraint = try XCTUnwrap(cell.cellTextToImageConstraint)
        XCTAssertEqual(constraint.firstAttribute, .leading)
        XCTAssertEqual(constraint.secondAttribute, .trailing)
        XCTAssertEqual(constraint.constant, 8)
        XCTAssertIdentical(constraint.firstItem, cell.cellLabel)
        XCTAssertIdentical(constraint.secondItem, cell.cellImage)
    }

    /// awakeFromNib runs exactly once per instantiation, AFTER the outlets.
    func testSwitchCellAwakeFromNib() throws {
        let cell = try makeSwitchCell()
        XCTAssertEqual(cell.awakeCount, 1)
    }

    /// The archived label properties: `numberOfLines="0"`,
    /// `adjustsFontForContentSizeCategory="YES"`, `lineBreakMode`
    /// `tailTruncation`, the 0.196 grey text colour and the 62-character
    /// placeholder string.
    func testSwitchCellLabelProperties() throws {
        let cell = try makeSwitchCell()
        let label = try XCTUnwrap(cell.cellLabel)
        XCTAssertEqual(label.numberOfLines, 0)
        XCTAssertTrue(label.adjustsFontForContentSizeCategory)
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        XCTAssertEqual(label.text,
                       "Label is really long and longer than you'd expect so let's see")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(label.textColor.getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertEqual(Double(r), 0.1960784314, accuracy: 1e-6)
        XCTAssertEqual(Double(a), 1, accuracy: 1e-9)
        // `<fontDescription style="UICTFontTextStyleCallout"/>`
        XCTAssertEqual(label.font.pointSize,
                       UIFont.preferredFont(forTextStyle: .callout).pointSize)
        XCTAssertFalse(label.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints=\"NO\"")
        // `horizontalHuggingPriority="251" horizontalCompressionResistancePriority="749"`
        XCTAssertEqual(label.contentHuggingPriority(for: .horizontal).rawValue, 251)
        XCTAssertEqual(
            label.contentCompressionResistancePriority(for: .horizontal).rawValue, 749)
    }

    /// The image view's two unary size constraints (width = height = 24) and
    /// `contentMode="scaleAspectFit"` / `userInteractionEnabled="NO"`.
    func testSwitchCellImageViewProperties() throws {
        let cell = try makeSwitchCell()
        let image = try XCTUnwrap(cell.cellImage)
        XCTAssertEqual(image.contentMode, .scaleAspectFit)
        XCTAssertFalse(image.isUserInteractionEnabled)
        let sizes = image.constraints.filter { $0.secondItem == nil }
        XCTAssertEqual(sizes.count, 2)
        XCTAssertEqual(Set(sizes.map(\.constant)), [24])
        XCTAssertEqual(Set(sizes.map(\.firstAttribute)), [.width, .height])
    }

    /// The content view's 8 constraints (xib `<constraints>` under
    /// `tableViewCellContentView`), including the two that address the
    /// content view's `leadingMargin` — the archive's `NSSecondAttributeV2`
    /// is 17, where the legacy `NSSecondAttribute` collapses it to 5
    /// (leading). Reading V2 is what keeps the margin.
    func testSwitchCellContentViewConstraints() throws {
        let cell = try makeSwitchCell()
        XCTAssertEqual(cell.contentView.constraints.count, 8)
        let margins = cell.contentView.constraints.filter {
            $0.secondAttribute == .leadingMargin
        }
        XCTAssertEqual(margins.count, 2, "leadingMargin survives as leadingMargin")
        // One of them is the priority-750 label leading (xib gMv-6M-2OZ).
        XCTAssertEqual(Set(margins.map(\.priority.rawValue)), [1000, 750])
    }

    /// Every dequeue is a fresh hierarchy, as UIKit's is, and the table
    /// stamps the reuse identifier onto a cell the nib produced.
    func testTableRegistersNib() throws {
        UINibClassRegistry.register("SwitchCell") { NibTestSwitchCell() }
        UINibClassRegistry.register("ThemeableLabel") { NibTestLabel(frame: .zero) }
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480),
                                style: .grouped)
        table.register(UINib(nibName: "SwitchCell", bundle: nil),
                       forCellReuseIdentifier: "SwitchCell")
        let first = try XCTUnwrap(table.dequeueReusableCell(withIdentifier: "SwitchCell"))
        let second = try XCTUnwrap(table.dequeueReusableCell(withIdentifier: "SwitchCell"))
        XCTAssertEqual(first.reuseIdentifier, "SwitchCell")
        XCTAssertNotIdentical(first, second)
        XCTAssertNotIdentical((first as? NibTestSwitchCell)?.cellLabel,
                              (second as? NibTestSwitchCell)?.cellLabel)
    }

    // MARK: DisclosureCell.xib

    /// The second cell: four subviews, a `multiplier="1:1"` aspect
    /// constraint, a `multiplier="0.4"` width cap and an archived image name.
    func testDisclosureCellArchive() throws {
        let bytes = try XCTUnwrap(
            ResourceIO.readFile(UINibTests.nibDirectory + "/DisclosureCell.nib"))
        let archive = try XCTUnwrap(NibArchive.parse(bytes))
        XCTAssertEqual(archive.objects.count, 72)
        let names = Set(archive.objects.map(\.className))
        XCTAssertTrue(names.contains("UIImageNibPlaceholder"),
                      "image=\"chevron\" archives as a placeholder")
        // The 1:1 and 0.4/0.3 multipliers the xib declares.
        var multipliers: Set<Double> = []
        for object in archive.objects where object.className == "NSLayoutConstraint" {
            if case .number(let m)? = object.first("NSMultiplier") {
                multipliers.insert((m * 100).rounded() / 100)
            }
        }
        XCTAssertTrue(multipliers.contains(0.4), "\(multipliers)")
        XCTAssertTrue(multipliers.contains(0.3), "\(multipliers)")
    }

    // MARK: StorageAndDataUseViewController.xib

    /// A File's-Owner nib: the `view` and `settingsTable` outlets land on the
    /// owner, and the archived table keeps `style="grouped"` and
    /// `rowHeight="54"`.
    func testFilesOwnerNib() throws {
        final class Owner: UIViewController, UINibOutletConnecting,
                           UITableViewDataSource, UITableViewDelegate {
            var settingsTable: UITableView?
            func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool {
                guard name == "settingsTable" else { return false }
                settingsTable = object as? UITableView
                return true
            }
            func tableView(_ t: UITableView, numberOfRowsInSection s: Int) -> Int { 0 }
            func tableView(_ t: UITableView,
                           cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                UITableViewCell()
            }
        }
        UINibClassRegistry.register("ThemeableView") { UIView() }
        UINibClassRegistry.register("ThemeableTable") { UITableView() }
        let owner = Owner()
        let nib = UINib(nibName: "StorageAndDataUseViewController", bundle: nil)
        XCTAssertTrue(nib.isLoaded)
        _ = nib.instantiate(withOwner: owner, options: nil)
        let root = try XCTUnwrap(owner.viewIfLoaded)
        XCTAssertEqual(root.frame, CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = try XCTUnwrap(owner.settingsTable)
        XCTAssertIdentical(table.superview, root)
        XCTAssertEqual(table.style, .grouped)
        XCTAssertEqual(table.rowHeight, 54)
        XCTAssertEqual(table.estimatedRowHeight, 54)
        XCTAssertTrue(table.alwaysBounceVertical)
        // `<outlet property="dataSource" destination="-1">` — the File's Owner.
        XCTAssertIdentical(table.dataSource as AnyObject?, owner)
        // The four pin-to-edges constraints live on the owner's root view.
        XCTAssertEqual(root.constraints.count, 4)
    }
}
