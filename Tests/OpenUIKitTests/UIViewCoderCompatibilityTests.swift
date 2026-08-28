import Foundation
import XCTest
@testable import OpenUIKit

/// The exact initializer shape used by focus-ios's `AsyncImageView`.
///
/// Its `NSCoder` initializer is deliberately not marked unavailable: calling
/// it proves that OpenUIKit supplies a designated superclass path and that a
/// code-based view can still perform its ordinary common setup afterwards.
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
    /// A non-Foundation token exercises the portable opaque surface directly.
    /// This would stop compiling if the superclass API acquired an NSCoder
    /// dependency in the Foundation-free branch.
    private final class PortableDecoderToken {}

    @MainActor
    func testPortableCoderPathStartsWithZeroFrameDefaults() throws {
        let view = try XCTUnwrap(UIView(coder: PortableDecoderToken()))

        XCTAssertEqual(view.frame, .zero)
        XCTAssertEqual(view.bounds, .zero)
        XCTAssertEqual(view.center, .zero)
        XCTAssertEqual(view.alpha, 1)
        XCTAssertTrue(view.isOpaque)
        XCTAssertTrue(view.subviews.isEmpty)
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
}
