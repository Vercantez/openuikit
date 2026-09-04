// iOS-cut measurements for attrtext_paragraph (SE 2x, iOS 26.1).
import XCTest
@testable import OpenUIKit

private typealias NSAttributedString = OpenUIKit.NSAttributedString
private typealias NSMutableParagraphStyle = OpenUIKit.NSMutableParagraphStyle
private typealias NSTextAlignment = OpenUIKit.NSTextAlignment

@MainActor
final class AttrtextParagraphProbeTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    private func attributed(_ text: String, size: CGFloat, align: NSTextAlignment,
                            lines: Int) -> UILabel {
        let ps = NSMutableParagraphStyle()
        ps.alignment = align
        ps.lineBreakMode = OpenUIKit.NSLineBreakMode.byWordWrapping
        let s = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size), .paragraphStyle: ps
        ])
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 80))
        label.attributedText = s
        label.numberOfLines = lines
        return label
    }

    func testRightAlignWrapCountsLeadingSpaceOnContinuation() {
        // iOS 26.1 SE 2x: the wrap-break space is a LEADING space on the
        // continuation line when alignment is .right (197.5) and stays off
        // that line when alignment is .left or .center (193.5).
        let text = "right aligned text that wraps over two lines here"
        let right = attributed(text, size: 17, align: NSTextAlignment.right, lines: 2)
        let left = attributed(text, size: 17, align: NSTextAlignment.left, lines: 2)
        let center = attributed(text, size: 17, align: NSTextAlignment.center, lines: 2)
        let fit = CGSize(width: 200, height: 1e6)
        XCTAssertEqual(right.sizeThatFits(fit).width, 197.5, accuracy: 1e-9)
        XCTAssertEqual(left.sizeThatFits(fit).width, 193.5, accuracy: 1e-9)
        XCTAssertEqual(center.sizeThatFits(fit).width, 193.5, accuracy: 1e-9)
        XCTAssertEqual(right.sizeThatFits(fit).height, 41, accuracy: 1e-9)
    }

    func testHardNewlineLeadingSpaceMatchesSoftRightWrap() {
        let with = attributed("right aligned text that\n wraps over two lines here",
                              size: 17, align: NSTextAlignment.right, lines: 2)
        let without = attributed("right aligned text that\nwraps over two lines here",
                                 size: 17, align: NSTextAlignment.right, lines: 2)
        let fit = CGSize(width: 200, height: 1e6)
        XCTAssertEqual(with.sizeThatFits(fit).width, 197.5, accuracy: 1e-9)
        XCTAssertEqual(without.sizeThatFits(fit).width, 193.5, accuracy: 1e-9)
    }

    func testPlainRightAlignWrapMatchesAttributed() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 80))
        label.text = "right aligned text that wraps over two lines here"
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 2
        label.textAlignment = NSTextAlignment.right
        label.lineBreakMode = OpenUIKit.NSLineBreakMode.byWordWrapping
        XCTAssertEqual(label.sizeThatFits(CGSize(width: 200, height: 1e6)).width,
                       197.5, accuracy: 1e-9)
    }

    func testCenteredFifteenPointPenLandsOnQuarterPhases() {
        // Scene line widths at 15 pt / 240: pens 11.298 and 11.873, which
        // the 2x quarter-point model maps to F0.25 and F0.75. First/last
        // ink of both lines match iOS; the leftover is 1-level AA inside
        // PIXEL_TOL (not the 96.1 score).
        let f15 = UIFont.systemFont(ofSize: 15)
        let c1 = FontEngine.measure("The quick brown fox jumps over", font: f15)
        let c2 = FontEngine.measure("the lazy dog near the river bank", font: f15)
        let p1 = (240 - c1) / 2
        let p2 = (240 - c2) / 2
        let f1 = p1 - CGFloat(Int(p1))
        let f2 = p2 - CGFloat(Int(p2))
        XCTAssertEqual(GlyphInkTable.phaseIOS(size: 15, frac: f1, scale: 2).tag, "F0.25")
        XCTAssertEqual(GlyphInkTable.phaseIOS(size: 15, frac: f2, scale: 2).tag, "F0.75")
    }
}
