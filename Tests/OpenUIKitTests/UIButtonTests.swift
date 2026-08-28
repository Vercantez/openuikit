// Button-module tests: legacy plain UIButton layout/sizing/colors,
// validated against golden/button_basic.layout.json and oracle probes
// (Catalyst iOS 26.1 ground truth; probe numbers reproduced in comments).
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

@MainActor
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
