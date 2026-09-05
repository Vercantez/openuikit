// NSAttributedString storage / enumeration semantics, NSParagraphStyle,
// UIFontDescriptor, and the attributed measurement rules that the fixture
// goldens pin down (M12 — attributed text).
import Foundation
import XCTest
@testable import OpenUIKit

// OpenUIKit's attributed-text types SHADOW Foundation's (docs/KNOWN_GAPS.md):
// tests import both, so name them explicitly — this file is also the worked
// example of the disambiguation an app has to write.
private typealias NSAttributedString = OpenUIKit.NSAttributedString
private typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString
private typealias NSParagraphStyle = OpenUIKit.NSParagraphStyle
private typealias NSMutableParagraphStyle = OpenUIKit.NSMutableParagraphStyle
private typealias NSUnderlineStyle = OpenUIKit.NSUnderlineStyle

#if !os(Linux)
@MainActor
#endif
final class AttributedStringTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    let f17 = UIFont.systemFont(ofSize: 17)
    let f13 = UIFont.systemFont(ofSize: 13)
    let b17 = UIFont.systemFont(ofSize: 17, weight: .bold)

    // MARK: - Storage

    func testLengthIsUTF16() {
        XCTAssertEqual(NSAttributedString(string: "abc").length, 3)
        // A non-BMP scalar is two UTF-16 units, like Foundation.
        XCTAssertEqual(NSAttributedString(string: "a\u{1F600}b").length, 4)
    }

    func testInitialRunCoversWholeString() {
        let s = NSAttributedString(string: "hello", attributes: [.font: f17])
        var r = NSRange()
        let a = s.attributes(at: 0, effectiveRange: &r)
        XCTAssertEqual(r, NSRange(location: 0, length: 5))
        XCTAssertEqual(a[.font] as? UIFont, f17)
        XCTAssertEqual(s.runs.count, 1)
    }

    func testAddAttributeSplitsRunsInThree() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.foregroundColor, value: UIColor.systemRed,
                       range: NSRange(location: 2, length: 2))
        XCTAssertEqual(s.runs.map { $0.length }, [2, 2, 2])
        var r = NSRange()
        _ = s.attributes(at: 0, effectiveRange: &r)
        XCTAssertEqual(r, NSRange(location: 0, length: 2))
        _ = s.attributes(at: 2, effectiveRange: &r)
        XCTAssertEqual(r, NSRange(location: 2, length: 2))
        _ = s.attributes(at: 5, effectiveRange: &r)
        XCTAssertEqual(r, NSRange(location: 4, length: 2))
        XCTAssertEqual(s.attribute(.foregroundColor, at: 2, effectiveRange: nil) as? UIColor,
                       UIColor.systemRed)
        XCTAssertNil(s.attribute(.foregroundColor, at: 1, effectiveRange: nil))
    }

    func testAdjacentEqualRunsMergeBack() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.foregroundColor, value: UIColor.systemRed,
                       range: NSRange(location: 2, length: 2))
        XCTAssertEqual(s.runs.count, 3)
        // Painting the same value over everything collapses to ONE run.
        s.addAttribute(.foregroundColor, value: UIColor.systemRed, range: s.fullRange)
        XCTAssertEqual(s.runs.count, 1)
        // Removing it again also collapses.
        s.removeAttribute(.foregroundColor, range: s.fullRange)
        XCTAssertEqual(s.runs.count, 1)
    }

    func testSetAttributesReplacesRatherThanMerges() {
        let s = NSMutableAttributedString(string: "abcd",
                                          attributes: [.font: f17,
                                                       .foregroundColor: UIColor.systemRed])
        s.setAttributes([.font: b17], range: NSRange(location: 0, length: 2))
        XCTAssertNil(s.attribute(.foregroundColor, at: 0, effectiveRange: nil))
        XCTAssertEqual(s.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, b17)
        XCTAssertEqual(s.attribute(.foregroundColor, at: 2, effectiveRange: nil) as? UIColor,
                       UIColor.systemRed)
    }

    func testEnumerateAttributeCoalescesEqualValues() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        // Two DIFFERENT attributes split the runs, but .font is equal across
        // all six characters, so enumerateAttribute(.font) yields one span.
        s.addAttribute(.kern, value: CGFloat(2), range: NSRange(location: 1, length: 1))
        s.addAttribute(.baselineOffset, value: CGFloat(3), range: NSRange(location: 4, length: 1))
        XCTAssertEqual(s.runs.count, 5)
        var fontSpans: [NSRange] = []
        s.enumerateAttribute(.font, in: s.fullRange) { _, range, _ in fontSpans.append(range) }
        XCTAssertEqual(fontSpans, [NSRange(location: 0, length: 6)])

        var kernSpans: [(CGFloat?, NSRange)] = []
        s.enumerateAttribute(.kern, in: s.fullRange) { v, range, _ in
            kernSpans.append((v as? CGFloat, range))
        }
        XCTAssertEqual(kernSpans.map { $0.1 },
                       [NSRange(location: 0, length: 1), NSRange(location: 1, length: 1),
                        NSRange(location: 2, length: 4)])
        XCTAssertEqual(kernSpans[1].0, 2)
        XCTAssertNil(kernSpans[0].0)
    }

    func testEnumerateAttributeClipsToRangeAndStops() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.kern, value: CGFloat(2), range: NSRange(location: 2, length: 2))
        var spans: [NSRange] = []
        s.enumerateAttribute(.kern, in: NSRange(location: 1, length: 4)) { _, r, _ in
            spans.append(r)
        }
        XCTAssertEqual(spans, [NSRange(location: 1, length: 1),
                               NSRange(location: 2, length: 2),
                               NSRange(location: 4, length: 1)])
        var count = 0
        s.enumerateAttribute(.kern, in: s.fullRange) { _, _, stop in
            count += 1
            stop = true
        }
        XCTAssertEqual(count, 1)
    }

    func testEnumerateAttributesVisitsEveryRun() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.kern, value: CGFloat(2), range: NSRange(location: 2, length: 2))
        var spans: [NSRange] = []
        s.enumerateAttributes(in: s.fullRange) { _, r, _ in spans.append(r) }
        XCTAssertEqual(spans, [NSRange(location: 0, length: 2),
                               NSRange(location: 2, length: 2),
                               NSRange(location: 4, length: 2)])
    }

    func testLongestEffectiveRange() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.kern, value: CGFloat(2), range: NSRange(location: 1, length: 1))
        s.addAttribute(.baselineOffset, value: CGFloat(1), range: NSRange(location: 4, length: 1))
        var r = NSRange()
        _ = s.attribute(.font, at: 3, longestEffectiveRange: &r, in: s.fullRange)
        XCTAssertEqual(r, NSRange(location: 0, length: 6))
        _ = s.attribute(.font, at: 3, longestEffectiveRange: &r,
                        in: NSRange(location: 2, length: 3))
        XCTAssertEqual(r, NSRange(location: 2, length: 3))
    }

    func testAppendInsertAndReplace() {
        let s = NSMutableAttributedString(string: "ab", attributes: [.font: f17])
        s.append(NSAttributedString(string: "cd", attributes: [.font: b17]))
        XCTAssertEqual(s.string, "abcd")
        XCTAssertEqual(s.runs.map { $0.length }, [2, 2])
        s.insert(NSAttributedString(string: "XY", attributes: [.font: f13]), at: 2)
        XCTAssertEqual(s.string, "abXYcd")
        XCTAssertEqual(s.attribute(.font, at: 2, effectiveRange: nil) as? UIFont, f13)
        s.replaceCharacters(in: NSRange(location: 2, length: 2),
                            with: NSAttributedString(string: "Z", attributes: [.font: f17]))
        XCTAssertEqual(s.string, "abZcd")
        // "ab" + "Z" share the font, so they coalesce into one run.
        XCTAssertEqual(s.runs.map { $0.length }, [3, 2])
        s.deleteCharacters(in: NSRange(location: 0, length: 3))
        XCTAssertEqual(s.string, "cd")
        XCTAssertEqual(s.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, b17)
    }

    func testReplaceCharactersWithPlainStringInheritsAttributes() {
        let s = NSMutableAttributedString(string: "abcd", attributes: [.font: b17])
        s.replaceCharacters(in: NSRange(location: 1, length: 2), with: "ZZZ")
        XCTAssertEqual(s.string, "aZZZd")
        XCTAssertEqual(s.runs.count, 1)
        XCTAssertEqual(s.attribute(.font, at: 2, effectiveRange: nil) as? UIFont, b17)
    }

    func testAttributedSubstring() {
        let s = NSMutableAttributedString(string: "abcdef", attributes: [.font: f17])
        s.addAttribute(.font, value: b17, range: NSRange(location: 3, length: 3))
        let sub = s.attributedSubstring(from: NSRange(location: 2, length: 3))
        XCTAssertEqual(sub.string, "cde")
        XCTAssertEqual(sub.runs.map { $0.length }, [1, 2])
        XCTAssertEqual(sub.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, f17)
        XCTAssertEqual(sub.attribute(.font, at: 1, effectiveRange: nil) as? UIFont, b17)
        // Out-of-range slices clamp instead of trapping.
        XCTAssertEqual(s.attributedSubstring(from: NSRange(location: 4, length: 99)).string, "ef")
    }

    func testIsEqualTo() {
        let a = NSAttributedString(string: "ab", attributes: [.font: f17])
        let b = NSAttributedString(string: "ab", attributes: [.font: f17])
        let c = NSAttributedString(string: "ab", attributes: [.font: b17])
        XCTAssertTrue(a.isEqual(to: b))
        XCTAssertFalse(a.isEqual(to: c))
    }

    // MARK: - Paragraph style

    func testParagraphStyleMutableCopyAndEquality() {
        let m = NSMutableParagraphStyle()
        m.alignment = .center
        m.lineSpacing = 6
        m.tailIndent = -12
        XCTAssertEqual(m.alignment, .center)
        XCTAssertEqual(m.lineSpacing, 6)
        let copy = m.mutableCopy()
        XCTAssertEqual(copy, m)
        copy.lineSpacing = 7
        XCTAssertNotEqual(copy, m)
        XCTAssertTrue(NSParagraphStyle.default.isDefaultLayout)
        XCTAssertFalse(m.isDefaultLayout)
    }

    func testLabelAdoptsParagraphAlignmentAndBreakMode() {
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        ps.lineBreakMode = .byWordWrapping
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "hi",
                                              attributes: [.font: f17, .paragraphStyle: ps])
        XCTAssertEqual(l.textAlignment, .center)
        XCTAssertEqual(l.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(l.text, "hi")
    }

    func testSettingPlainTextClearsAttributedContent() {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "hi", attributes: [.font: b17])
        XCTAssertNotNil(l._attributed)
        l.text = "bye"
        XCTAssertNil(l._attributed)
        XCTAssertEqual(l.text, "bye")
        // The getter still synthesizes an attributed string from plain text.
        XCTAssertEqual(l.attributedText?.string, "bye")
    }

    // MARK: - UIFontDescriptor

    func testDescriptorTraitsRoundTrip() {
        let d = UIFont.systemFont(ofSize: 17).fontDescriptor
        XCTAssertEqual(d.pointSize, 17)
        XCTAssertFalse(d.symbolicTraits.contains(.traitBold))
        let bold = try! XCTUnwrap(d.withSymbolicTraits(.traitBold))
        XCTAssertEqual(UIFont(descriptor: bold, size: 0).weight, .bold)
        XCTAssertTrue(bold.symbolicTraits.contains(.traitBold))
        // size 0 keeps the descriptor's size; a real size overrides it.
        XCTAssertEqual(UIFont(descriptor: bold, size: 0).pointSize, 17)
        XCTAssertEqual(UIFont(descriptor: bold, size: 24).pointSize, 24)
    }

    func testDescriptorTraitsAreReplacedNotMerged() {
        let italicBold = UIFont.italicSystemFont(ofSize: 17).fontDescriptor
            .withSymbolicTraits(.traitBold)!
        // Real UIKit REPLACES the trait set: asking for bold alone drops italic.
        XCTAssertEqual(italicBold.design, .default)
        XCTAssertEqual(italicBold.weight, .bold)
        let both = UIFont.systemFont(ofSize: 17).fontDescriptor
            .withSymbolicTraits([.traitBold, .traitItalic])!
        XCTAssertEqual(both.weight, .bold)
        XCTAssertEqual(both.design, .italic)
    }

    func testDescriptorHeavyWeightIsNotDemotedToBold() {
        let d = UIFont.systemFont(ofSize: 17, weight: .heavy).fontDescriptor
        XCTAssertEqual(d.withSymbolicTraits(.traitBold)!.weight, .heavy)
        XCTAssertEqual(d.withSymbolicTraits([])!.weight, .regular)
    }

    func testDescriptorDesigns() {
        let d = UIFont.systemFont(ofSize: 17).fontDescriptor
        XCTAssertEqual(d.withDesign(.monospaced)?.design, .monospaced)
        XCTAssertNil(d.withDesign(.rounded))       // not portable
        XCTAssertEqual(d.withSize(11).pointSize, 11)
    }

    // MARK: - Measurement rules (probed against Catalyst UIKit)

    fileprivate func flatten(_ s: NSAttributedString) -> AttributedTextLayout.Text {
        AttributedTextLayout.flatten(s, defaultFont: f17, defaultColor: .label)
    }
    fileprivate func measure(_ s: NSAttributedString) -> CGFloat {
        let t = flatten(s)
        return AttributedTextLayout.width(t, from: 0, to: t.count)
    }

    func testKernIsAddedToEveryCharacterIncludingTheLast() {
        let plain = measure(NSAttributedString(string: "AVATAR", attributes: [.font: f17]))
        let kerned = measure(NSAttributedString(string: "AVATAR",
                                                attributes: [.font: f17, .kern: CGFloat(2)]))
        XCTAssertEqual(kerned - plain, 12, accuracy: 1e-6)   // 6 characters x 2
        let one = measure(NSAttributedString(string: "A", attributes: [.font: f17]))
        let oneKerned = measure(NSAttributedString(string: "A",
                                                   attributes: [.font: f17, .kern: CGFloat(2)]))
        XCTAssertEqual(oneKerned - one, 2, accuracy: 1e-6)
    }

    func testKernZeroDisablesPairKerning() {
        let plain = measure(NSAttributedString(string: "AVATAR", attributes: [.font: f17]))
        let zero = measure(NSAttributedString(string: "AVATAR",
                                              attributes: [.font: f17, .kern: CGFloat(0)]))
        // Catalyst: 61.9736 natural vs 66.9541 with kerning off.
        XCTAssertEqual(plain, 61.9736328125, accuracy: 1e-4)
        XCTAssertEqual(zero, 66.9541015625, accuracy: 1e-4)
    }

    func testPairKerningCrossesRunBoundariesButNotFonts() {
        let whole = measure(NSAttributedString(string: "AVAT", attributes: [.font: f17]))
        let split = NSMutableAttributedString()
        split.append(NSAttributedString(string: "AV", attributes: [.font: f17]))
        split.append(NSAttributedString(string: "AT", attributes: [.font: f17]))
        XCTAssertEqual(measure(split), whole, accuracy: 1e-6)

        // Different fonts on either side: no pair kerning, so the widths add.
        let f24 = UIFont.systemFont(ofSize: 24)
        let mixed = NSMutableAttributedString()
        mixed.append(NSAttributedString(string: "A", attributes: [.font: f17]))
        mixed.append(NSAttributedString(string: "V", attributes: [.font: f24]))
        let sum = measure(NSAttributedString(string: "A", attributes: [.font: f17]))
            + measure(NSAttributedString(string: "V", attributes: [.font: f24]))
        XCTAssertEqual(measure(mixed), sum, accuracy: 1e-6)
    }

    fileprivate func lineHeight(_ s: NSAttributedString) -> CGFloat {
        let l = UILabel()
        l.attributedText = s
        return l.sizeThatFits(CGSize(width: 10000, height: CGFloat.greatestFiniteMagnitude)).height
    }

    func testMixedFontLineBoxIsTheTallestRun() {
        let f24 = UIFont.systemFont(ofSize: 24)
        let s = NSMutableAttributedString()
        s.append(NSAttributedString(string: "Big ", attributes: [.font: f24]))
        s.append(NSAttributedString(string: "small", attributes: [.font: f17]))
        XCTAssertEqual(lineHeight(s), 28)             // labelLineHeight(24)
        XCTAssertEqual(lineHeight(NSAttributedString(string: "x", attributes: [.font: f17])), 20)
    }

    func testBaselineOffsetGrowsTheMatchingSideOfTheLineBox() {
        func h(_ offsets: [CGFloat]) -> CGFloat {
            let s = NSMutableAttributedString()
            for o in offsets {
                s.append(NSAttributedString(string: "a",
                                            attributes: [.font: f17, .baselineOffset: o]))
            }
            return lineHeight(s)
        }
        // Catalyst measurements: ascent grows by max(0, maxOffset), descent by
        // max(0, -minOffset).
        XCTAssertEqual(h([0]), 20)
        XCTAssertEqual(h([3]), 23)
        XCTAssertEqual(h([-3]), 23)
        XCTAssertEqual(h([3, -3]), 26)
        XCTAssertEqual(h([2, -5]), 27)
        XCTAssertEqual(h([0, 4]), 24)
    }

    func testUnderlineAndStrikethroughDoNotChangeMeasurement() {
        let plain = measure(NSAttributedString(string: "Under", attributes: [.font: f17]))
        let ul = measure(NSAttributedString(string: "Under", attributes: [
            .font: f17, .underlineStyle: NSUnderlineStyle.single.rawValue]))
        XCTAssertEqual(ul, plain, accuracy: 1e-9)
    }

    func testDecorationTableMatchesOracleMeasurements() {
        // Vendored from `oracle textdecor`; spot-check the sizes the fixtures
        // exercise (points relative to the run baseline).
        let d17 = FontEngine.decorations(for: f17)
        XCTAssertEqual(d17.underlineTop, 2)
        XCTAssertEqual(d17.underlineThickness, 1)
        XCTAssertEqual(d17.strikeTop, -5)
        XCTAssertEqual(d17.strikeThickness, 1)
        let s17 = FontEngine.decorations(for: .systemFont(ofSize: 17, weight: .semibold))
        XCTAssertEqual(s17.underlineTop, 2)
        XCTAssertEqual(s17.underlineThickness, 2)
        let d24 = FontEngine.decorations(for: .systemFont(ofSize: 24))
        XCTAssertEqual(d24.underlineTop, 3)
        XCTAssertEqual(d24.underlineThickness, 2)
    }

    // MARK: - Text input views

    func testTextFieldAttributedAdoptsLeadingFontAndColor() {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        let s = NSMutableAttributedString()
        s.append(NSAttributedString(string: "total ", attributes: [.font: f17]))
        s.append(NSAttributedString(string: "open",
                                    attributes: [.font: UIFont.systemFont(ofSize: 17,
                                                                          weight: .semibold)]))
        tf.attributedText = s
        XCTAssertEqual(tf.text, "total open")
        XCTAssertEqual(tf.font, f17)
        // Golden attrtext_fields: intrinsic width 108 for this string.
        XCTAssertEqual(tf.intrinsicContentSize.width, 108, accuracy: 0.001)
        // Editing drops the attributes (documented gap).
        tf.text = "x"
        XCTAssertNil(tf._attributed)
    }

    func testTextViewAttributedUsesFontLineHeights() {
        let tv = UITextView()
        tv.frame = CGRect(x: 0, y: 0, width: 288, height: 120)
        tv.font = f17
        tv.text = "hello"
        let plainHeight = tv.contentHeight
        tv.attributedText = NSAttributedString(string: "hello", attributes: [.font: f17])
        XCTAssertEqual(tv.contentHeight, plainHeight, accuracy: 0.001)
        XCTAssertEqual(tv.text, "hello")
        tv.text = "plain"
        XCTAssertNil(tv._attributed)
    }
}
