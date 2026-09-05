// Button-module tests: legacy plain UIButton layout/sizing/colors,
// validated against golden/button_basic.layout.json and oracle probes
// (Catalyst iOS 26.1 ground truth; probe numbers reproduced in comments).
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

#if !os(Linux)
@MainActor
#endif
final class UIButtonTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 2)
    }

    private func makeButton(_ title: String, size: CGFloat? = nil,
                            weight: UIFont.Weight = .regular) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        if let size { b.titleLabel?.font = .systemFont(ofSize: size, weight: weight) }
        return b
    }

    private func makeImage(width: Int, height: Int) -> UIImage {
        UIImage(bitmap: Bitmap(width: width, height: height))
    }

    // MARK: defaults

    func testDefaultTitleFontIs15Regular() {
        let b = UIButton(type: .system)
        XCTAssertEqual(b.titleLabel?.font, UIFont.systemFont(ofSize: 15))
    }

    func testTitleLabelDumpClassName() {
        // The layout dump prints the dynamic type name; the oracle emits
        // "UIButtonLabel" for the title subview.
        let b = UIButton(type: .system)
        XCTAssertEqual(String(describing: type(of: b.subviews[0])), "UIButtonLabel")
    }

    func testImageViewExistsAndTracksExactControlState() {
        let button = UIButton(type: .system)
        XCTAssertNotNil(button.imageView)
        XCTAssertNil(button.currentImage)

        let normal = makeImage(width: 10, height: 6)
        let highlighted = makeImage(width: 14, height: 8)
        let selected = makeImage(width: 12, height: 7)
        button.setImage(normal, for: .normal)
        button.setImage(highlighted, for: .highlighted)
        button.setImage(selected, for: .selected)
        XCTAssertTrue(button.image(for: .normal) === normal)
        XCTAssertTrue(button.currentImage === normal)
        XCTAssertTrue(button.imageView?.image === normal)

        button.isHighlighted = true
        XCTAssertTrue(button.currentImage === highlighted)
        XCTAssertTrue(button.imageView?.image === highlighted)

        // Measured on iOS 26: combined highlighted+selected with no exact
        // assignment falls directly back to normal, not either partial state.
        button.isSelected = true
        XCTAssertTrue(button.currentImage === normal)
        let combined: UIControl.State = [.highlighted, .selected]
        button.setImage(selected, for: combined)
        XCTAssertTrue(button.currentImage === selected)
        button.setImage(nil, for: combined)
        XCTAssertTrue(button.currentImage === normal)
    }

    func testImageOnlyAndImageTitleLayout() {
        let image = makeImage(width: 10, height: 6)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.sizeToFit()
        button.layoutIfNeeded()
        XCTAssertEqual(button.frame.size, CGSize(width: 10, height: 18))
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 0, y: 6, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame, .zero)

        button.setTitle("Go", for: .normal)
        let titleSize = button.titleLabel!.intrinsicContentSize
        button.sizeToFit()
        button.layoutIfNeeded()
        XCTAssertEqual(button.frame.width, titleSize.width.rounded(.down) + 10)
        XCTAssertEqual(button.frame.height, Swift.max(titleSize.height, 6) + 12)
        XCTAssertEqual(button.imageView?.frame.minX, 0)
        XCTAssertEqual(button.titleLabel?.frame.minX, 10)

        // Real-iOS fixed-frame oracle: image [25,19,10,6], title
        // [35,13,20,18] in an 80x44 button. OpenUIKit's established Catalyst
        // label line box is one point taller (19), hence y=12.5/height=19;
        // horizontal image/title geometry is exact.
        button.frame = CGRect(x: 10, y: 20, width: 80, height: 44)
        button.layoutIfNeeded()
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 25, y: 19, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame,
                       CGRect(x: 35, y: 12.5, width: 20, height: 19))
    }

    func testLegacyInsetsAndPhysicalAlignmentsMatchOracleGeometry() {
        let button = makeButton("Go")
        button.setImage(makeImage(width: 10, height: 6), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5,
                                               bottom: 7, right: 11)
        button.titleEdgeInsets = UIEdgeInsets(top: 2, left: 13,
                                             bottom: 4, right: 17)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 19,
                                             bottom: 5, right: 23)

        XCTAssertEqual(button.intrinsicContentSize,
                       CGSize(width: 46, height: 29))
        XCTAssertEqual(button.contentRect(forBounds: button.bounds),
                       CGRect(x: 5, y: 3, width: 184, height: 70))

        let expected: [(UIControl.ContentHorizontalAlignment, CGRect, CGRect)] = [
            (.center, CGRect(x: 80, y: 33, width: 10, height: 6),
             CGRect(x: 90, y: 27.5, width: 20, height: 19)),
            (.left, CGRect(x: 24, y: 33, width: 10, height: 6),
             CGRect(x: 28, y: 27.5, width: 20, height: 19)),
            (.right, CGRect(x: 136, y: 33, width: 10, height: 6),
             CGRect(x: 152, y: 27.5, width: 20, height: 19)),
        ]
        for (alignment, image, title) in expected {
            button.contentHorizontalAlignment = alignment
            button.layoutIfNeeded()
            XCTAssertEqual(button.imageView?.frame, image, "\(alignment)")
            XCTAssertEqual(button.titleLabel?.frame, title, "\(alignment)")
            XCTAssertEqual(button.imageRect(forContentRect:
                button.contentRect(forBounds: button.bounds)), image)
            XCTAssertEqual(button.titleRect(forContentRect:
                button.contentRect(forBounds: button.bounds)), title)
        }
    }

    func testExplicitContentInsetsReplacePaddingAndPreserveNegativeSizes() {
        let title = makeButton("Go")
        title.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5,
                                              bottom: 7, right: 11)
        // iOS 26.1: 20x18 title + insets -> 36x28. OpenUIKit's established
        // line box is one point taller, so the oracle-adapted height is 29.
        XCTAssertEqual(title.intrinsicContentSize,
                       CGSize(width: title.titleLabel!.intrinsicContentSize.width
                            .rounded(.up) + 16,
                              height: title.titleLabel!.intrinsicContentSize.height
                                  + 10))

        let image = UIButton(type: .system)
        image.setImage(makeImage(width: 10, height: 6), for: .normal)
        image.contentEdgeInsets = title.contentEdgeInsets
        XCTAssertEqual(image.intrinsicContentSize, CGSize(width: 26, height: 29))

        let empty = UIButton(type: .system)
        empty.contentEdgeInsets = UIEdgeInsets(top: -3, left: -5,
                                              bottom: -7, right: -11)
        // UIKit does not clamp negative legacy size totals.
        XCTAssertEqual(empty.sizeThatFits(.zero), CGSize(width: -16, height: 9))
    }

    func testExplicitSizingRoundsEachInsetAndUsesZeroAxisIntrinsicSentinel() {
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                       displayScale: 3)
        let empty = UIButton(type: .system)
        empty.contentEdgeInsets = UIEdgeInsets(top: 1.2, left: 2.2,
                                              bottom: 3.7, right: 4.7)
        var fit = empty.sizeThatFits(.zero)
        // iOS @3x rounds the components to 4/3 + 11/3 vertically
        // and 7/3 + 14/3 horizontally. Keep OpenUIKit's established local
        // 19pt label line box while asserting the measured inset rule.
        XCTAssertEqual(fit.width, 7, accuracy: 1e-9)
        XCTAssertEqual(fit.height,
                       empty.titleLabel!.font.labelLineHeight + 5,
                       accuracy: 1e-9)
        XCTAssertEqual(empty.intrinsicContentSize, fit)

        empty.contentEdgeInsets = UIEdgeInsets(top: -1.2, left: -2.2,
                                              bottom: -3.7, right: -4.7)
        fit = empty.sizeThatFits(.zero)
        XCTAssertEqual(fit.width, -7, accuracy: 1e-9)
        XCTAssertEqual(fit.height,
                       empty.titleLabel!.font.labelLineHeight - 5,
                       accuracy: 1e-9)

        // Negative half-pixel ties round toward +infinity: -0.5pt @3x is
        // -1/3pt, while +0.5pt is +2/3pt.
        empty.contentEdgeInsets = UIEdgeInsets(top: 1, left: -0.5,
                                              bottom: 0, right: 0.5)
        XCTAssertEqual(empty.sizeThatFits(.zero).width, 1.0 / 3,
                       accuracy: 1e-9)

        empty.contentEdgeInsets = UIEdgeInsets(top: 3, left: 0,
                                              bottom: 7, right: 0)
        fit = empty.sizeThatFits(.zero)
        XCTAssertEqual(fit.width, 0)
        XCTAssertEqual(empty.intrinsicContentSize.width,
                       UIView.noIntrinsicMetric)

        // The sentinel is axis/result based rather than an empty-button
        // special case. Exercise both axes with real image content.
        let image = UIButton(type: .system)
        image.setImage(makeImage(width: 10, height: 6), for: .normal)
        image.contentEdgeInsets = UIEdgeInsets(top: 1, left: -10,
                                              bottom: 0, right: 0)
        XCTAssertEqual(image.sizeThatFits(.zero).width, 0)
        XCTAssertEqual(image.intrinsicContentSize.width,
                       UIView.noIntrinsicMetric)
        image.contentEdgeInsets = UIEdgeInsets(
            top: -image.titleLabel!.font.labelLineHeight,
            left: 1, bottom: 0, right: 0)
        XCTAssertEqual(image.sizeThatFits(.zero).height, 0)
        XCTAssertEqual(image.intrinsicContentSize.height,
                       UIView.noIntrinsicMetric)
    }

    func testContentRectCollapsesAndIntegralizesOnTheDisplayPixelGrid() {
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                       displayScale: 3)
        let button = makeButton("Go")
        let bounds = CGRect(x: 0, y: 0, width: 20, height: 10)

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15,
                                               bottom: 9, right: 16)
        XCTAssertEqual(button.contentRect(forBounds: bounds),
                       CGRect(x: 28.0 / 3, y: 13.0 / 3,
                              width: 29.0 / 3 - 28.0 / 3,
                              height: 14.0 / 3 - 13.0 / 3))

        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8,
                                               bottom: 6, right: 12)
        XCTAssertEqual(button.contentRect(forBounds: bounds),
                       CGRect(x: 8, y: 4, width: 0, height: 0))

        button.contentEdgeInsets = UIEdgeInsets(top: 1.2, left: 2.2,
                                               bottom: 3.7, right: 4.7)
        XCTAssertEqual(button.contentRect(forBounds: bounds),
                       CGRect(x: 2, y: 1, width: 46.0 / 3 - 2,
                              height: 19.0 / 3 - 1))

        button.contentEdgeInsets = UIEdgeInsets(top: -3, left: -5,
                                               bottom: -7, right: -11)
        XCTAssertEqual(button.contentRect(forBounds: bounds),
                       CGRect(x: -5, y: -3, width: 36, height: 20))
    }

    func testLegacyVerticalAndFillAlignmentsMatchOracleRules() {
        let button = makeButton("Go")
        button.setImage(makeImage(width: 10, height: 6), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5,
                                               bottom: 7, right: 11)
        button.titleEdgeInsets = UIEdgeInsets(top: 2, left: 13,
                                             bottom: 4, right: 17)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 19,
                                             bottom: 5, right: 23)

        button.contentVerticalAlignment = .top
        button.layoutIfNeeded()
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 80, y: 4, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame,
                       CGRect(x: 90, y: 5, width: 20, height: 19))

        button.contentVerticalAlignment = .bottom
        button.layoutIfNeeded()
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 80, y: 62, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame,
                       CGRect(x: 90, y: 50, width: 20, height: 19))

        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.layoutIfNeeded()
        let image = try! XCTUnwrap(button.imageView?.frame)
        XCTAssertEqual(image.minX, 24, accuracy: 1e-9)
        XCTAssertEqual(image.minY, 4, accuracy: 1e-9)
        XCTAssertEqual(image.width, CGFloat(142) / 3, accuracy: 1e-9)
        XCTAssertEqual(image.height, 64, accuracy: 1e-9)
        let title = try! XCTUnwrap(button.titleLabel?.frame)
        XCTAssertEqual(title.minX, 69.5, accuracy: 1e-9)
        XCTAssertEqual(title.minY, 5, accuracy: 1e-9)
        XCTAssertEqual(title.width, CGFloat(308) / 3, accuracy: 1e-9)
        XCTAssertEqual(title.height, 64, accuracy: 1e-9)

        button.semanticContentAttribute = .forceRightToLeft
        button.layoutIfNeeded()
        let rtlImage = try! XCTUnwrap(button.imageView?.frame)
        XCTAssertEqual(rtlImage.minX, image.minX, accuracy: 1e-9)
        XCTAssertEqual(rtlImage.width, image.width, accuracy: 1e-9)
        let rtlTitle = try! XCTUnwrap(button.titleLabel?.frame)
        XCTAssertEqual(rtlTitle.minX, title.minX, accuracy: 1e-9)
        XCTAssertEqual(rtlTitle.width, title.width, accuracy: 1e-9)
    }

    func testFillPreservesSignedPerItemAreasAndStandardizesSubviewFrames() {
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                       displayScale: 3)
        let button = makeButton("Go")
        button.setImage(makeImage(width: 10, height: 6), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill

        func rawRects() -> (image: CGRect, title: CGRect) {
            let content = button.contentRect(forBounds: button.bounds)
            return (button.imageRect(forContentRect: content),
                    button.titleRect(forContentRect: content))
        }
        func assertRect(_ actual: CGRect, _ expected: CGRect) {
            XCTAssertEqual(actual.origin.x, expected.origin.x, accuracy: 1e-9)
            XCTAssertEqual(actual.origin.y, expected.origin.y, accuracy: 1e-9)
            XCTAssertEqual(actual.size.width, expected.size.width, accuracy: 1e-9)
            XCTAssertEqual(actual.size.height, expected.size.height, accuracy: 1e-9)
        }

        // iOS 26.1 @3x: each requested endpoint is rounded independently.
        // The two signed available widths then share the 10:20 basis.
        button.imageEdgeInsets = UIEdgeInsets(top: 1.2, left: 2.1,
                                             bottom: 2.4, right: 3.2)
        button.titleEdgeInsets = UIEdgeInsets(top: 2.2, left: 3.1,
                                             bottom: 3.4, right: 4.2)
        var raw = rawRects()
        XCTAssertEqual(raw.image.origin.x, 2, accuracy: 1e-9)
        XCTAssertEqual(raw.image.origin.y, 4.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.width, 584.0 / 9, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.height, 229.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.x, 202.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.y, 7.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.width, 1156.0 / 9, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.height, 223.0 / 3, accuracy: 1e-9)
        button.layoutIfNeeded()
        assertRect(button.imageView!.frame, raw.image)
        assertRect(button.titleLabel!.frame, raw.title)

        // Cross only the image's inset edges. The hook rectangles remain
        // signed; frame assignment standardizes both negative widths and the
        // image's negative height.
        button.imageEdgeInsets = UIEdgeInsets(top: 40, left: 150,
                                             bottom: 50, right: 160)
        button.titleEdgeInsets = .zero
        raw = rawRects()
        XCTAssertEqual(raw.image.origin.x, 150, accuracy: 1e-9)
        XCTAssertEqual(raw.image.origin.y, 40, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.width, -1210.0 / 9, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.height, -10, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.x, 733.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.width, -400.0 / 9, accuracy: 1e-9)
        button.layoutIfNeeded()
        assertRect(button.imageView!.frame, raw.image.standardized)
        assertRect(button.titleLabel!.frame, raw.title.standardized)

        // With both horizontal areas crossed, the title basis floors at
        // zero while the image keeps its signed basis.
        button.titleEdgeInsets = UIEdgeInsets(top: 45, left: 150,
                                             bottom: 55, right: 160)
        raw = rawRects()
        XCTAssertEqual(raw.image.origin.x, 150, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.width, -110, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.x, 40, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.width, -0.0, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.y, 45, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.height, -20, accuracy: 1e-9)
        button.layoutIfNeeded()
        assertRect(button.imageView!.frame, raw.image.standardized)
        assertRect(button.titleLabel!.frame, raw.title.standardized)

        // Exact basis cancellation uses UIKit's finite denominator fallback:
        // image available/basis = -20/-20, title = 200/20.
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 110,
                                             bottom: 0, right: 110)
        button.titleEdgeInsets = .zero
        raw = rawRects()
        XCTAssertEqual(raw.image.origin.x, 110, accuracy: 1e-9)
        XCTAssertEqual(raw.image.size.width, 400, accuracy: 1e-9)
        XCTAssertEqual(raw.title.origin.x, -3800, accuracy: 1e-9)
        XCTAssertEqual(raw.title.size.width, 4000, accuracy: 1e-9)
    }

    func testSemanticDirectionResolvesLeadingTrailingAndReversesContentOrder() {
        XCTAssertEqual(UIControl.ContentVerticalAlignment.center.rawValue, 0)
        XCTAssertEqual(UIControl.ContentVerticalAlignment.top.rawValue, 1)
        XCTAssertEqual(UIControl.ContentVerticalAlignment.bottom.rawValue, 2)
        XCTAssertEqual(UIControl.ContentVerticalAlignment.fill.rawValue, 3)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.center.rawValue, 0)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.left.rawValue, 1)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.right.rawValue, 2)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.fill.rawValue, 3)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.leading.rawValue, 4)
        XCTAssertEqual(UIControl.ContentHorizontalAlignment.trailing.rawValue, 5)
        XCTAssertEqual(UISemanticContentAttribute.unspecified.rawValue, 0)
        XCTAssertEqual(UISemanticContentAttribute.playback.rawValue, 1)
        XCTAssertEqual(UISemanticContentAttribute.spatial.rawValue, 2)
        XCTAssertEqual(UISemanticContentAttribute.forceLeftToRight.rawValue, 3)
        XCTAssertEqual(UISemanticContentAttribute.forceRightToLeft.rawValue, 4)

        XCTAssertEqual(UIView.userInterfaceLayoutDirection(for: .unspecified),
                       .leftToRight)
        XCTAssertEqual(UIView.userInterfaceLayoutDirection(
            for: .unspecified, relativeTo: .rightToLeft), .rightToLeft)
        XCTAssertEqual(UIView.userInterfaceLayoutDirection(
            for: .playback, relativeTo: .rightToLeft), .leftToRight)
        XCTAssertEqual(UIView.userInterfaceLayoutDirection(
            for: .spatial, relativeTo: .rightToLeft), .leftToRight)
        XCTAssertEqual(UIView.userInterfaceLayoutDirection(
            for: .forceRightToLeft), .rightToLeft)

        let parent = UIView()
        parent.semanticContentAttribute = .forceRightToLeft
        let child = UIView()
        parent.addSubview(child)
        XCTAssertEqual(child.effectiveUserInterfaceLayoutDirection,
                       .leftToRight)
        child.semanticContentAttribute = .forceRightToLeft
        XCTAssertEqual(child.effectiveUserInterfaceLayoutDirection,
                       .rightToLeft)

        let button = makeButton("Go")
        button.setImage(makeImage(width: 10, height: 6), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5,
                                               bottom: 7, right: 11)
        button.titleEdgeInsets = UIEdgeInsets(top: 2, left: 13,
                                             bottom: 4, right: 17)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 19,
                                             bottom: 5, right: 23)
        button.semanticContentAttribute = .forceRightToLeft
        button.contentHorizontalAlignment = .leading
        XCTAssertEqual(button.effectiveContentHorizontalAlignment, .right)
        button.layoutIfNeeded()
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 156, y: 33, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame,
                       CGRect(x: 142, y: 27.5, width: 20, height: 19))

        button.contentHorizontalAlignment = .trailing
        XCTAssertEqual(button.effectiveContentHorizontalAlignment, .left)
        button.layoutIfNeeded()
        XCTAssertEqual(button.imageView?.frame,
                       CGRect(x: 44, y: 33, width: 10, height: 6))
        XCTAssertEqual(button.titleLabel?.frame,
                       CGRect(x: 18, y: 27.5, width: 20, height: 19))

        let immediate = makeButton("Go")
        immediate.setImage(makeImage(width: 10, height: 6), for: .normal)
        immediate.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        immediate.contentHorizontalAlignment = .leading
        let directionRoot = UIView()
        directionRoot.semanticContentAttribute = .forceRightToLeft
        directionRoot.addSubview(immediate)
        directionRoot.layoutIfNeeded()
        XCTAssertEqual(immediate.effectiveUserInterfaceLayoutDirection,
                       .leftToRight)
        XCTAssertLessThan(immediate.imageView!.frame.minX,
                          immediate.titleLabel!.frame.minX)
    }

    func testAttributedTitlesUseExactStateThenNormalAndDriveMetrics() {
        let button = UIButton(type: .system)
        button.setTitle("Plain", for: .normal)
        let normalAttributes: [OpenUIKit.NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor.systemRed,
        ]
        let normal = OpenUIKit.NSAttributedString(
            string: "Rich", attributes: normalAttributes)
        let selectedAttributes: [OpenUIKit.NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
        ]
        let selected = OpenUIKit.NSAttributedString(
            string: "Chosen", attributes: selectedAttributes)
        button.setAttributedTitle(normal, for: .normal)

        XCTAssertEqual(button.currentTitle, "Plain")
        XCTAssertTrue(button.currentAttributedTitle === normal)
        XCTAssertEqual(button.titleLabel?.text, "Rich")
        XCTAssertTrue(button.titleLabel?._attributed === normal)
        XCTAssertEqual(button.intrinsicContentSize.width,
                       button.titleLabel!.intrinsicContentSize.width.rounded(.up))
        XCTAssertEqual(button.intrinsicContentSize.height,
                       button.titleLabel!.intrinsicContentSize.height + 12)

        button.isSelected = true
        XCTAssertTrue(button.currentAttributedTitle === normal)
        button.setAttributedTitle(selected, for: .selected)
        XCTAssertTrue(button.currentAttributedTitle === selected)
        XCTAssertEqual(button.titleLabel?.text, "Chosen")
        button.setAttributedTitle(nil, for: .selected)
        XCTAssertTrue(button.currentAttributedTitle === normal)
        XCTAssertEqual(button.titleLabel?.text, "Rich")
    }

    // MARK: sizing (golden/button_basic.layout.json)

    func testSizeToFitPlain() {
        // golden: "Plain Button" default font -> button 86x31, label 86x19.
        let b = makeButton("Plain Button")
        b.frame = CGRect(x: 20, y: 20, width: 0, height: 0)
        b.sizeToFit()
        XCTAssertEqual(b.frame, CGRect(x: 20, y: 20, width: 86, height: 31))
        XCTAssertEqual(b.intrinsicContentSize, CGSize(width: 86, height: 31))
        b.layoutIfNeeded()
        XCTAssertEqual(b.subviews[0].frame, CGRect(x: 0, y: 6, width: 86, height: 19))
    }

    func testSizeToFitSemibold17() {
        // golden: "Bold Button" 17pt semibold -> 97x32, label 97x20.
        let b = makeButton("Bold Button", size: 17, weight: .semibold)
        b.sizeToFit()
        XCTAssertEqual(b.frame.size, CGSize(width: 97, height: 32))
        b.layoutIfNeeded()
        XCTAssertEqual(b.subviews[0].frame, CGRect(x: 0, y: 6, width: 97, height: 20))
    }

    func testSizeThatFitsIgnoresConstraint() {
        // Oracle probe: a 211pt title reports 211 for sizeThatFits(200).
        let b = makeButton("Fixed Frame Button")
        let s = b.sizeThatFits(CGSize(width: 10, height: 10))
        XCTAssertEqual(s, b.intrinsicContentSize)
        // golden: intrinsic 139x31 (label intrinsic width 138.5 ceils to 139).
        XCTAssertEqual(s, CGSize(width: 139, height: 31))
    }

    func testFixedFrameCentersCeiledTitleRect() {
        // golden: 200x44 button, label frame (30.5, 12.5, 139, 19).
        let b = makeButton("Fixed Frame Button")
        b.frame = CGRect(x: 20, y: 120, width: 200, height: 44)
        b.layoutIfNeeded()
        XCTAssertEqual(b.subviews[0].frame,
                       CGRect(x: 30.5, y: 12.5, width: 139, height: 19))
    }

    func testButtonTitleTruncatesInTheMiddle() {
        // Real UIButton titles truncate MIDDLE, not tail (oracle width
        // sweep at 14pt renders "Very…width" for an 80pt button).
        let b = makeButton("A Very Long Button Title Here")
        XCTAssertEqual(b.titleLabel?.lineBreakMode, .byTruncatingMiddle)
    }

    func testOverflowSqueezeGetsFullBoundsWidth() {
        // golden/button_states: 300x30 button, 14pt title of natural width
        // 309.16pt fits at tight tracking -> label (0, 6.5, 300, 17); the
        // text draws squeezed to exactly floor(width) (ink 598px @2x).
        // Oracle sweep: every width 287..309 gives the full-width label.
        let b = makeButton("Very long button title that fills the frame width",
                           size: 14)
        b.frame = CGRect(x: 20, y: 250, width: 300, height: 30)
        b.layoutIfNeeded()
        XCTAssertEqual(b.subviews[0].frame,
                       CGRect(x: 0, y: 6.5, width: 300, height: 17))
    }

    func testOverflowTruncationHugsMiddleTruncatedLine() {
        // Oracle width sweep (same 14pt title): when even tight tracking
        // does not fit, the label hugs the middle-truncated line, ceiled
        // to whole points and centered. Oracle: W=80 -> (2.5, 75),
        // W=150 -> (2, 146), W=200 -> (0.5, 199).
        let title = "Very long button title that fills the frame width"
        for (w, expX, expW): (CGFloat, CGFloat, CGFloat) in
            [(80, 2.5, 75), (150, 2, 146), (200, 0.5, 199)] {
            let b = makeButton(title, size: 14)
            b.frame = CGRect(x: 10, y: 0, width: w, height: 30)
            b.layoutIfNeeded()
            XCTAssertEqual(b.subviews[0].frame,
                           CGRect(x: expX, y: 6.5, width: expW, height: 17),
                           "width \(w)")
        }
        // 15pt legacy probe: 80pt button, "A Very Long Button Title Here"
        // (natural 210.9pt) -> our hug model gives 75pt ("A Ve…Here"
        // drawn 74.63); the oracle reported 76 (its tight advances run
        // ~1pt wider on long lines — known 1pt model drift, text is
        // centered so the pixel error is <= 0.5pt).
        let b = makeButton("A Very Long Button Title Here")
        b.frame = CGRect(x: 0, y: 0, width: 80, height: 44)
        b.layoutIfNeeded()
        XCTAssertEqual(b.subviews[0].frame,
                       CGRect(x: 2.5, y: 12.5, width: 75, height: 19))
    }

    // MARK: title colors

    func testDefaultTitleColorIsTint() {
        let b = makeButton("T")
        b.layoutIfNeeded()
        let c = (b.subviews[0] as! UILabel).textColor
            .resolvedCGColor(with: UITraitCollection.current)
        // light tintColor = (0, 0.5333, 1, 1) -> golden text (0,136,255).
        XCTAssertEqual(c, UIColor.tintColor.resolvedCGColor(with: .current))
    }

    func testDisabledTitleColorIsSystemGray() {
        // golden "Disabled": peak text pixels (133,133,133) alpha 115 ->
        // white 0.52 alpha 0.45 in light mode.
        let b = makeButton("Disabled")
        b.isEnabled = false
        b.layoutIfNeeded()
        let c = (b.subviews[0] as! UILabel).textColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual((c.red * 255).rounded(), 133)
        XCTAssertEqual((c.alpha * 255).rounded(), 115)
        let dark = (b.subviews[0] as! UILabel).textColor
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark,
                                                     displayScale: 2))
        XCTAssertEqual((dark.red * 255).rounded(), 140)  // oracle dark probe
    }

    func testExplicitTitleColorWinsWhenDisabled() {
        // Oracle probe: disabled button with explicit titleColor renders it.
        let b = makeButton("Off")
        b.setTitleColor(.systemRed, for: .normal)
        b.isEnabled = false
        b.layoutIfNeeded()
        let c = (b.subviews[0] as! UILabel).textColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(c, UIColor.systemRed.resolvedCGColor(with: .current))
    }

    func testDisabledSizingUnchanged() {
        // golden: "Disabled" -> 62x31 (state does not affect metrics).
        let b = makeButton("Disabled")
        b.isEnabled = false
        b.sizeToFit()
        XCTAssertEqual(b.frame.size, CGSize(width: 62, height: 31))
    }

    // MARK: ink coverage for the button scene (regression for the harvested
    // glyph masks; missing masks silently degrade to the approximate path)

    func testButtonSceneGlyphMasksPresent() {
        guard GlyphInkTable.isAvailable else { return }
        for ch in "PlainButoFxedrmDsb".unicodeScalars {
            for tag in ["0", "T", "H", "P2"] {
                XCTAssertNotNil(GlyphInkTable.mask(familyKey: "system-regular",
                                                   sizeKey: 15, dark: false,
                                                   tag: tag, scalar: ch),
                                "missing system-regular|15|light|\(tag)|\(ch)")
            }
        }
        for ch in "Boldutn".unicodeScalars {
            for tag in ["0", "P1"] {
                XCTAssertNotNil(GlyphInkTable.mask(familyKey: "system-semibold",
                                                   sizeKey: 17, dark: false,
                                                   tag: tag, scalar: ch),
                                "missing system-semibold|17|light|\(tag)|\(ch)")
            }
        }
    }
}
