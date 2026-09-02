import XCTest
@testable import OpenUIKit

@MainActor
final class UILabelShrinkTests: XCTestCase {
    private func makeLabel(text: String, font: UIFont, width: CGFloat,
                           adjusts: Bool, minimum: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 40))
        label.text = text
        label.font = font
        label.adjustsFontSizeToFitWidth = adjusts
        label.minimumScaleFactor = minimum
        return label
    }

    private func render(_ label: UILabel) -> [UInt8] {
        let scale: CGFloat = 2
        let bitmap = Bitmap(width: Int(label.bounds.width * scale),
                            height: Int(label.bounds.height * scale))
        let canvas = Canvas(bitmap: bitmap, scale: scale)
        label.drawContent(in: canvas, bounds: label.bounds)
        return bitmap.pixels
    }

    func testDefaultsAndStoredValuesMatchUIKit() {
        let label = UILabel()
        XCTAssertFalse(label.adjustsFontSizeToFitWidth)
        XCTAssertEqual(label.minimumScaleFactor, 0)
        XCTAssertFalse(label.allowsDefaultTighteningForTruncation)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        XCTAssertTrue(label.adjustsFontSizeToFitWidth)
        XCTAssertEqual(label.minimumScaleFactor, 0.6)
    }

    func testDefaultTighteningUsesBoundedTrackingBeforeTruncation() {
        let text = "Tight label"
        let requested = UIFont.systemFont(ofSize: 20)
        let natural = FontEngine.measure(text, font: requested)
        let width = natural * 0.98
        let tightened = makeLabel(
            text: text,
            font: requested,
            width: width,
            adjusts: false,
            minimum: 0
        )
        tightened.numberOfLines = 1
        tightened.allowsDefaultTighteningForTruncation = true
        let ordinary = makeLabel(
            text: text,
            font: requested,
            width: width,
            adjusts: false,
            minimum: 0
        )
        ordinary.numberOfLines = 1

        XCTAssertNotEqual(render(tightened), render(ordinary))
        XCTAssertEqual(tightened.intrinsicContentSize, ordinary.intrinsicContentSize)

        // More than five percent of the font size per inter-glyph advance
        // fails back to normal truncation rather than crushing the label.
        tightened.frame.size.width = natural * 0.5
        ordinary.frame.size.width = natural * 0.5
        XCTAssertEqual(render(tightened), render(ordinary))
    }

    func testDisabledAdjustmentKeepsRequestedFontAndPixels() {
        let text = "Shrink me please"
        let requested = UIFont.systemFont(ofSize: 20)
        let natural = FontEngine.measure(text, font: requested)
        let label = makeLabel(text: text, font: requested,
                              width: natural * 0.7,
                              adjusts: false, minimum: 0.5)
        let reference = makeLabel(text: text, font: requested,
                                  width: natural * 0.7,
                                  adjusts: false, minimum: 0)
        XCTAssertEqual(label.effectiveDrawingFont(for: text,
                                                  width: label.bounds.width),
                       requested)
        XCTAssertEqual(render(label), render(reference))
    }

    func testShrinksWholeStringWhenRequiredScaleIsAboveMinimum() {
        let text = "Shrink me please"
        let requested = UIFont.systemFont(ofSize: 20)
        let natural = FontEngine.measure(text, font: requested)
        let width = natural * 0.75
        let label = makeLabel(text: text, font: requested, width: width,
                              adjusts: true, minimum: 0.6)
        let intrinsicBefore = label.intrinsicContentSize
        let effective = label.effectiveDrawingFont(for: text, width: width)

        XCTAssertGreaterThan(effective.pointSize, requested.pointSize * 0.6)
        XCTAssertLessThan(effective.pointSize, requested.pointSize)
        XCTAssertLessThanOrEqual(FontEngine.measure(text, font: effective),
                                 width + 1e-5)

        // A reference label using the solved font fits naturally and draws
        // the full string. Byte identity proves the adjusted path did not
        // feed the text through ellipsis/truncation.
        let reference = makeLabel(text: text, font: effective, width: width,
                                  adjusts: false, minimum: 0)
        XCTAssertEqual(render(label), render(reference))
        XCTAssertEqual(label.font, requested)
        XCTAssertEqual(label.intrinsicContentSize, intrinsicBefore)
    }

    func testClampsAtMinimumThenUsesExistingTruncation() {
        let text = "Shrink me please"
        let requested = UIFont.systemFont(ofSize: 20)
        let natural = FontEngine.measure(text, font: requested)
        let width = natural * 0.4
        let label = makeLabel(text: text, font: requested, width: width,
                              adjusts: true, minimum: 0.6)
        let effective = label.effectiveDrawingFont(for: text, width: width)
        XCTAssertEqual(effective.pointSize, 12, accuracy: 1e-8)
        XCTAssertGreaterThan(FontEngine.measure(text, font: effective), width)

        // At the floor, UIKit resumes the label's normal truncation/clip
        // behavior. This comparison also covers vertical centering and the
        // effective font's line-box metrics.
        let reference = makeLabel(text: text, font: effective, width: width,
                                  adjusts: false, minimum: 0)
        XCTAssertEqual(render(label), render(reference))
        XCTAssertEqual(label.font, requested)
    }

    func testMeasuredMinimumScaleTruncatesAtTheEffectiveFloor() {
        // Exact real-iOS oracle case (20pt, 80pt label): both minimum fonts
        // remain too wide and UIKit takes the ordinary tail-truncation path.
        // The lower 0.6 floor retains visibly more text than the 0.9 floor.
        let text = "Shrink me please"
        let requested = UIFont.systemFont(ofSize: 20)

        let shrink = makeLabel(text: text, font: requested, width: 80,
                               adjusts: true, minimum: 0.6)
        let shrinkFont = shrink.effectiveDrawingFont(for: text, width: 80)
        XCTAssertEqual(shrinkFont.pointSize, 12, accuracy: 1e-8)
        let shrinkLine = TextLayout.truncate(text, font: shrinkFont,
                                             maxWidth: 80,
                                             mode: .byTruncatingTail)
        XCTAssertEqual(shrinkLine.text, "Shrink me pl…")

        let floor = makeLabel(text: text, font: requested, width: 80,
                              adjusts: true, minimum: 0.9)
        let floorFont = floor.effectiveDrawingFont(for: text, width: 80)
        XCTAssertEqual(floorFont.pointSize, 18, accuracy: 1e-8)
        let floorLine = TextLayout.truncate(text, font: floorFont,
                                            maxWidth: 80,
                                            mode: .byTruncatingTail)
        XCTAssertEqual(floorLine.text, "Shrink…")
        XCTAssertGreaterThan(shrinkLine.text.count, floorLine.text.count)
    }

    func testMultilineAndAttributedTextRemainAtRequestedFont() {
        let requested = UIFont.systemFont(ofSize: 20)
        let multiline = makeLabel(text: "one two three", font: requested,
                                  width: 20, adjusts: true, minimum: 0.5)
        multiline.numberOfLines = 2
        XCTAssertEqual(multiline.effectiveDrawingFont(for: multiline.text!, width: 20),
                       requested)

        let attributed = makeLabel(text: "attributed", font: requested,
                                   width: 20, adjusts: true, minimum: 0.5)
        attributed.attributedText = NSAttributedString(string: "attributed")
        XCTAssertEqual(attributed.effectiveDrawingFont(for: attributed.text!, width: 20),
                       requested)
    }
}
