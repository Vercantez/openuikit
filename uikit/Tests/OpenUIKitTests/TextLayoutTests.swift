// TextLayout tests — wrapping and truncation behavior.
// Expected values beyond the golden scenes were captured from the real-UIKit
// oracle (Tools/oracle) with probe scenes.
import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class TextLayoutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    let fox = "The quick brown fox jumps over the lazy dog near the river bank"

    func testWordWrapAt200Size17() {
        let font = UIFont.systemFont(ofSize: 17)
        let lines = TextLayout.wrap(fox, font: font, maxWidth: 200, maxLines: 0)
        XCTAssertEqual(lines.map { String($0.text) },
                       ["The quick brown fox", "jumps over the lazy dog", "near the river bank"])
        // Widths of non-final lines include the trailing break space
        // (matches real UIKit usedRect; golden label_multiline width = 193).
        let maxW = lines.map(\.measuredWidth).max() ?? 0
        XCTAssertEqual(FontEngine.ceilToPixel(maxW, scale: 2), 193.0, accuracy: 1e-9)
    }

    func testWordWrapOracleCrossChecks() {
        // Oracle: 15pt -> 3 lines, width 195; 20pt -> 4 lines, width 181.5.
        let f15 = UIFont.systemFont(ofSize: 15)
        let l15 = TextLayout.wrap(fox, font: f15, maxWidth: 200, maxLines: 0)
        XCTAssertEqual(l15.count, 3)
        XCTAssertEqual(FontEngine.ceilToPixel(l15.map(\.measuredWidth).max() ?? 0, scale: 2),
                       195.0, accuracy: 1e-9)
        let f20 = UIFont.systemFont(ofSize: 20)
        let l20 = TextLayout.wrap(fox, font: f20, maxWidth: 200, maxLines: 0)
        XCTAssertEqual(l20.count, 4)
        XCTAssertEqual(FontEngine.ceilToPixel(l20.map(\.measuredWidth).max() ?? 0, scale: 2),
                       181.5, accuracy: 1e-9)
    }

    func testNumberOfLinesCap() {
        let font = UIFont.systemFont(ofSize: 17)
        let text = "Two line maximum label that should truncate the rest of this text"
        let lines = TextLayout.wrap(text, font: font, maxWidth: 200, maxLines: 2)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(lines[0].text), "Two line maximum label")
        XCTAssertEqual(String(lines[1].text), "that should truncate the")
        // Golden label_multiline sizeThatFits200 = [192, 40].
        let maxW = lines.map(\.measuredWidth).max() ?? 0
        XCTAssertEqual(FontEngine.ceilToPixel(maxW, scale: 2), 192.0, accuracy: 1e-9)
    }

    func testLongWordCharacterWrap() {
        let font = UIFont.systemFont(ofSize: 17)
        let lines = TextLayout.wrap("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", font: font,
                                    maxWidth: 60, maxLines: 0)
        XCTAssertGreaterThan(lines.count, 1)
        for l in lines {
            XCTAssertLessThanOrEqual(l.drawWidth, 60 + 1e-6)
            XCTAssertFalse(l.text.isEmpty)
        }
        // No characters lost.
        XCTAssertEqual(lines.map { String($0.text) }.joined().count, 30)
    }

    /// Truncation break points match real Catalyst UIKit at 17pt/150pt
    /// (measured pixel-by-pixel from UILabel renders; see golden
    /// label_truncate). UIKit condenses truncated lines with the font's
    /// tight tracking, which is why more characters fit than a naive
    /// natural-width computation allows.
    func testTruncationModes() {
        let font = UIFont.systemFont(ofSize: 17)
        let text = "This text is definitely too long to fit"
        let ell = "\u{2026}"
        let tail = TextLayout.truncate(text, font: font, maxWidth: 150, mode: .byTruncatingTail)
        XCTAssertEqual(tail.text, "This text is definit" + ell)
        XCTAssertLessThan(tail.delta, 0)
        let head = TextLayout.truncate(text, font: font, maxWidth: 150, mode: .byTruncatingHead)
        XCTAssertEqual(head.text, ell + "itely too long to fit")
        let mid = TextLayout.truncate(text, font: font, maxWidth: 150, mode: .byTruncatingMiddle)
        XCTAssertEqual(mid.text, "This text" + ell + "long to fit")
        // Clipping leaves the text unchanged (drawing clips instead).
        XCTAssertEqual(TextLayout.truncate(text, font: font, maxWidth: 150,
                                           mode: .byClipping).text, text)
        // Text that fits is never touched.
        let fit = TextLayout.truncate("Hi", font: font, maxWidth: 150, mode: .byTruncatingTail)
        XCTAssertEqual(fit.text, "Hi")
        XCTAssertEqual(fit.delta, 0)
    }
}
