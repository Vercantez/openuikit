import XCTest
@testable import OpenUIKit

/// Members NetNewsWire's feed / timeline / settings code touches. MEASURED
/// iPhone 16 / iOS 26.1: Tools/oracle2/cellconfigprobe/transcript-ios26.1.txt.
@MainActor
final class ScatteredMembersTests: XCTestCase {
    func testFontSizes() {
        XCTAssertEqual(UIFont.systemFontSize, 14)
        XCTAssertEqual(UIFont.smallSystemFontSize, 12)
        XCTAssertEqual(UIFont.labelFontSize, 17)
        XCTAssertEqual(UIFont.buttonFontSize, 18)
    }

    func testLabelStateDefaults() {
        let l = UILabel()
        XCTAssertTrue(l.isEnabled)
        XCTAssertFalse(l.isHighlighted)
        XCTAssertNil(l.highlightedTextColor)
    }

    func testScrollViewInsetAdjustmentAndZoomDefaults() {
        XCTAssertEqual(UIScrollView.ContentInsetAdjustmentBehavior.automatic.rawValue, 0)
        XCTAssertEqual(UIScrollView.ContentInsetAdjustmentBehavior.scrollableAxes.rawValue, 1)
        XCTAssertEqual(UIScrollView.ContentInsetAdjustmentBehavior.never.rawValue, 2)
        XCTAssertEqual(UIScrollView.ContentInsetAdjustmentBehavior.always.rawValue, 3)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        let sv = UIScrollView(frame: window.bounds)
        window.addSubview(sv)
        window.layoutIfNeeded()
        XCTAssertEqual(sv.contentInsetAdjustmentBehavior, .automatic)
        XCTAssertTrue(sv.bouncesZoom)
        XCTAssertEqual(sv.adjustedContentInset.top, 59)
        sv.contentInsetAdjustmentBehavior = .never
        XCTAssertEqual(sv.adjustedContentInset, .zero, "never: the safe area is not folded in")
    }

    func testControllerMembers() {
        let vc = UIViewController()
        XCTAssertFalse(vc.definesPresentationContext)
        XCTAssertNil(vc.toolbarItems)
        vc.setToolbarItems([UIBarButtonItem.flexibleSpace()], animated: false)
        XCTAssertEqual(vc.toolbarItems?.count, 1)
    }

    func testGestureSearchBarLayoutAccessibilityPointerDefaults() {
        XCTAssertEqual(UIPanGestureRecognizer().allowedScrollTypesMask.rawValue, 0)
        XCTAssertEqual(UIScrollTypeMask.all.rawValue, 3)
        let sb = UISearchBar()
        XCTAssertNil(sb.barTintColor)
        XCTAssertNil(sb.scopeBarBackgroundImage)
        XCTAssertEqual(sb.autocapitalizationType.rawValue, 2)
        XCTAssertEqual(UICollectionViewCompositionalLayoutConfiguration().contentInsetsReference, .safeArea)
        XCTAssertEqual(UIContentInsetsReference.safeArea.rawValue, 2)
        XCTAssertEqual(UIContentInsetsReference.readableContent.rawValue, 4)
        XCTAssertEqual(UIAccessibility.Notification.announcement.rawValue, 1008)
        XCTAssertFalse(UIAccessibility.isVoiceOverRunning)
        UIAccessibility.post(notification: .announcement, argument: "x")
        let pi = UIPointerInteraction()
        XCTAssertNil(pi.delegate)
        XCTAssertTrue(pi.isEnabled)
    }

    /// iPhoneSimulator26.1 UIImage.h: `UIImagePNGRepresentation` /
    /// `UIImageJPEGRepresentation` bridge to `pngData() -> Data?` and
    /// `jpegData(compressionQuality:) -> Data?`; UIGraphicsImageRenderer's
    /// `pngData(actions:)` is `Data`. NetNewsWire RSImage.swift:105 returns
    /// `pngData()` from a `-> Data?` function.
    func testEncodersReturnFoundationData() {
        let image = UIImage(bitmap: Bitmap(width: 2, height: 2), scale: 1)
        let png: Data? = image.pngData()
        let jpeg: Data? = image.jpegData(compressionQuality: 0.5)
        XCTAssertNotNil(png)
        XCTAssertNotNil(jpeg)
        XCTAssertEqual(Array(png!.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        XCTAssertEqual(UIImage(data: png!, scale: 1)?.size, CGSize(width: 2, height: 2))
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let rendered: Data = renderer.pngData { _ in }
        XCTAssertFalse(rendered.isEmpty)
    }
}
