import Foundation
import XCTest
@testable import OpenUIKit

/// The exact initializer shape used by focus-ios's `AsyncImageView`.
///
/// Its `NSCoder` initializer is deliberately not marked unavailable: calling
/// it proves that OpenUIKit supplies the exact required designated superclass
/// path and that a code-based view can still perform its ordinary common setup
/// afterwards. Calling it with no arguments proves UIView's distinct
/// convenience initializer is inherited after both designated paths are
/// implemented, which is the compiler corner Focus exercises.
@MainActor
private final class CoderCompatibleView: UIView {
    private(set) var commonInitCount = 0
    private(set) var installedSubview: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        commonInitCount += 1
        let child = UIView()
        addSubview(child)
        installedSubview = child
    }
}

final class UIViewCoderCompatibilityTests: XCTestCase {
    @MainActor
    func testCoderPathStartsWithZeroFrameDefaults() throws {
        let view = try XCTUnwrap(UIView(coder: NSCoder()))

        XCTAssertEqual(view.frame, .zero)
        XCTAssertEqual(view.bounds, .zero)
        XCTAssertEqual(view.center, .zero)
        XCTAssertEqual(view.alpha, 1)
        XCTAssertTrue(view.isOpaque)
        XCTAssertTrue(view.subviews.isEmpty)
    }

    func testOpenUIKitNSCoderIsFoundationsExactType() {
        let decoder: OpenUIKit.NSCoder = Foundation.NSCoder()
        XCTAssertTrue(type(of: decoder) === Foundation.NSCoder.self)
    }

    @MainActor
    func testUIKitNonfailableCoderSignaturesStayNonfailable() {
        let indicator: UIActivityIndicatorView = UIActivityIndicatorView(coder: NSCoder())
        let stack: UIStackView = UIStackView(coder: NSCoder())

        XCTAssertEqual(indicator.frame, .zero)
        XCTAssertEqual(indicator.style, .medium)
        XCTAssertFalse(indicator.isUserInteractionEnabled)
        XCTAssertEqual(stack.frame, .zero)
        XCTAssertTrue(stack.arrangedSubviews.isEmpty)
    }

    @MainActor
    func testFoundationNSCoderSubclassCanRunCommonSetup() throws {
        let view = try XCTUnwrap(CoderCompatibleView(coder: NSCoder()))

        XCTAssertEqual(view.frame, .zero)
        XCTAssertEqual(view.commonInitCount, 1)
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertTrue(view.subviews.first === view.installedSubview)
    }

    @MainActor
    func testFrameInitializerStillPreservesItsFrameAndRunsSetupOnce() {
        let frame = CGRect(x: 2, y: 3, width: 40, height: 50)
        let view = CoderCompatibleView(frame: frame)

        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(view.commonInitCount, 1)
        XCTAssertEqual(view.subviews.count, 1)
    }

    @MainActor
    func testFocusShapedSubclassInheritsZeroArgumentConvenienceInitializer() {
        let view = CoderCompatibleView()

        XCTAssertEqual(view.frame, .zero)
        XCTAssertEqual(view.commonInitCount, 1)
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertTrue(view.subviews.first === view.installedSubview)
    }

    @MainActor
    func testZeroArgumentInitializerRoutesAndCompatibilityDefaults() throws {
        let button = UIButton()
        let indicator = UIActivityIndicatorView()
        let slider = UISlider()
        let toggle = UISwitch()
        let table = UITableView()
        let collection = UICollectionView()
        let cell = UITableViewCell()
        let headerFooter = UITableViewHeaderFooterView()
        let reusable = UICollectionReusableView()
        let collectionCell = UICollectionViewCell()
        let refresh = UIRefreshControl()
        let progress = UIProgressView()
        let decodedProgress = try XCTUnwrap(UIProgressView(coder: NSCoder()))

        XCTAssertEqual(button.frame, .zero)
        XCTAssertEqual(button.buttonType, .custom)
        XCTAssertEqual(indicator.frame, .zero)
        XCTAssertEqual(indicator.style, .medium)
        XCTAssertEqual(slider.frame, CGRect(x: 0, y: 0, width: 100, height: 34))
        XCTAssertEqual(toggle.frame, CGRect(x: 0, y: 0, width: 63, height: 28))
        XCTAssertEqual(table.frame, .zero)
        XCTAssertEqual(table.style, .plain)
        XCTAssertEqual(collection.frame, .zero)
        // Intentional OpenUIKit compatibility extension: UIKit raises when a
        // programmatic collection view is initialized without a layout.
        XCTAssertTrue(collection.collectionViewLayout is UICollectionViewFlowLayout)
        XCTAssertEqual(cell.frame,
                       CGRect(x: 0, y: 0, width: 320,
                              height: UITableViewCell.defaultRowHeight))
        XCTAssertEqual(cell.style, .default)
        XCTAssertNil(cell.reuseIdentifier)
        XCTAssertEqual(headerFooter.frame, .zero)
        XCTAssertNil(headerFooter.reuseIdentifier)
        XCTAssertEqual(reusable.frame, .zero)
        XCTAssertEqual(collectionCell.frame, .zero)
        XCTAssertTrue(collectionCell.subviews.contains { $0 === collectionCell.contentView })
        XCTAssertEqual(refresh.frame, CGRect(x: 0, y: 0, width: 320, height: 60))
        XCTAssertEqual(progress.frame, CGRect(x: 0, y: 0, width: 0, height: 4))
        XCTAssertEqual(decodedProgress.frame,
                       CGRect(x: 0, y: 0, width: 0, height: 4))
    }

    @MainActor
    func testSpecializedInitializerAPIsRemainDistinct() {
        let button = UIButton(type: .system)
        let indicator = UIActivityIndicatorView(style: .large)
        let zeroSlider = UISlider(frame: .zero)
        let progress = UIProgressView(frame: CGRect(x: 1, y: 2,
                                                    width: 30, height: 40))
        let tableFrame = CGRect(x: 1, y: 2, width: 30, height: 40)
        let table = UITableView(frame: tableFrame, style: .insetGrouped)
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: tableFrame,
                                          collectionViewLayout: layout)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "row")
        let frameCell = UITableViewCell(frame: tableFrame)
        let headerFooter = UITableViewHeaderFooterView(reuseIdentifier: "header")
        let frameHeaderFooter = UITableViewHeaderFooterView(frame: tableFrame)

        XCTAssertEqual(button.buttonType, .system)
        XCTAssertEqual(indicator.style, .large)
        XCTAssertNotEqual(indicator.frame.size, .zero)
        XCTAssertEqual(zeroSlider.frame, .zero)
        XCTAssertEqual(progress.frame, CGRect(x: 1, y: 2, width: 30, height: 4))
        XCTAssertEqual(table.frame, tableFrame)
        XCTAssertEqual(table.style, .insetGrouped)
        XCTAssertEqual(collection.frame, tableFrame)
        XCTAssertTrue(collection.collectionViewLayout === layout)
        XCTAssertEqual(cell.style, .subtitle)
        XCTAssertEqual(cell.reuseIdentifier, "row")
        XCTAssertEqual(frameCell.frame,
                       CGRect(x: 0, y: 0, width: 320,
                              height: UITableViewCell.defaultRowHeight))
        XCTAssertEqual(frameCell.style, .default)
        XCTAssertNil(frameCell.reuseIdentifier)
        XCTAssertEqual(headerFooter.reuseIdentifier, "header")
        XCTAssertEqual(frameHeaderFooter.frame, tableFrame)
        XCTAssertNil(frameHeaderFooter.reuseIdentifier)
    }
}
