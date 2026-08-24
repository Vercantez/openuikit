// FontEngine tests — metrics + measurement vs golden/font_metrics.json.
import Foundation
import XCTest
@testable import OpenUIKit

final class FontEngineTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    func goldenFonts() throws -> [[String: Any]] {
        let json = try TextTestSupport.loadJSON("golden/font_metrics.json")
        return try XCTUnwrap(json["fonts"] as? [[String: Any]])
    }

    /// Every metric of every table entry must be reproduced exactly.
    func testMetricsExactForAllTableEntries() throws {
        for entry in try goldenFonts() {
            let id = try XCTUnwrap(entry["id"] as? String)
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            let m = FontEngine.metrics(for: font)
            XCTAssertEqual(m.ascender, try XCTUnwrap(entry["ascender"] as? Double),
                           accuracy: 1e-9, "\(id) ascender")
            XCTAssertEqual(m.descender, try XCTUnwrap(entry["descender"] as? Double),
                           accuracy: 1e-9, "\(id) descender")
            XCTAssertEqual(m.lineHeight, try XCTUnwrap(entry["lineHeight"] as? Double),
                           accuracy: 1e-9, "\(id) lineHeight")
            XCTAssertEqual(m.capHeight, try XCTUnwrap(entry["capHeight"] as? Double),
                           accuracy: 1e-9, "\(id) capHeight")
            XCTAssertEqual(m.xHeight, try XCTUnwrap(entry["xHeight"] as? Double),
                           accuracy: 1e-9, "\(id) xHeight")
            XCTAssertEqual(m.leading, try XCTUnwrap(entry["leading"] as? Double),
                           accuracy: 1e-9, "\(id) leading")
        }
    }

    /// Single-character advances must match the table exactly.
    func testAdvancesExactForSampleEntries() throws {
        for entry in try goldenFonts() {
            let id = try XCTUnwrap(entry["id"] as? String)
            guard id == "system-regular-17.0" || id == "mono-bold-13.0"
                || id == "italic-regular-20.0" || id == "system-black-34.0" else { continue }
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            let advances = try XCTUnwrap(entry["advances"] as? [String: Double])
            for (ch, gold) in advances {
                let scalar = try XCTUnwrap(ch.unicodeScalars.first)
                XCTAssertEqual(FontEngine.advance(of: scalar, font: font), gold,
                               accuracy: 1e-9, "\(id) advance '\(ch)'")
            }
        }
    }

    /// Fractional sizes interpolate linearly between adjacent integer sizes
    /// (the optical-family switch is preserved because only neighbors blend).
    func testFractionalSizeInterpolation() {
        let m16 = FontEngine.metrics(for: .systemFont(ofSize: 16))
        let m17 = FontEngine.metrics(for: .systemFont(ofSize: 17))
        let mMid = FontEngine.metrics(for: .systemFont(ofSize: 16.25))
        XCTAssertEqual(mMid.ascender, m16.ascender + 0.25 * (m17.ascender - m16.ascender),
                       accuracy: 1e-9)
        XCTAssertEqual(mMid.lineHeight, m16.lineHeight + 0.25 * (m17.lineHeight - m16.lineHeight),
                       accuracy: 1e-9)
        // Sizes present in the table (e.g. 17.5) are exact lookups, not blends.
        let m175 = FontEngine.metrics(for: .systemFont(ofSize: 17.5))
        XCTAssertEqual(m175.lineHeight, 21.0, accuracy: 1e-9)
    }

    /// String measurement (advances + pair kerning) must reproduce the real
    /// measured widths within 0.3 pt for EVERY reference string of EVERY font.
    func testStringWidthsAcrossAllFonts() throws {
        var checked = 0
        for entry in try goldenFonts() {
            let id = try XCTUnwrap(entry["id"] as? String)
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            let widths = try XCTUnwrap(entry["stringWidths"] as? [String: Double])
            for (s, gold) in widths {
                let w = FontEngine.measure(s, font: font)
                XCTAssertEqual(w, gold, accuracy: 0.3, "\(id) '\(s)'")
                // The kerning table actually reproduces them much tighter.
                XCTAssertEqual(w, gold, accuracy: 0.01, "\(id) '\(s)' (tight)")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 2000, "expected all 432 fonts x ~6 strings")
    }

    /// The task's canonical spot check.
    func testHelloUIKitAt17() {
        let w = FontEngine.measure("Hello UIKit", font: .systemFont(ofSize: 17))
        XCTAssertEqual(w, 83.041015625, accuracy: 0.25)
    }

    /// Kerned strings would be badly wrong from bare advance sums; make sure
    /// kerning is engaged (regression guard).
    func testKerningIsApplied() {
        let font = UIFont.systemFont(ofSize: 17)
        let unkerned = "AVAST Wavy To. LT".unicodeScalars
            .reduce(0.0) { $0 + FontEngine.advance(of: $1, font: font) }
        let kerned = FontEngine.measure("AVAST Wavy To. LT", font: font)
        XCTAssertEqual(kerned, 152.04541015625, accuracy: 0.01)
        XCTAssertGreaterThan(unkerned - kerned, 5, "kerning should shave >5pt here")
        // Mono fonts have no kerning.
        let mono = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let monoSum = "AVAST Wavy To. LT".unicodeScalars
            .reduce(0.0) { $0 + FontEngine.advance(of: $1, font: mono) }
        XCTAssertEqual(FontEngine.measure("AVAST Wavy To. LT", font: mono), monoSum,
                       accuracy: 1e-9)
    }

    /// Label line height rule: lineHeight plus one point in the three bands
    /// where real UIKit lays out taller lines (verified against the oracle
    /// for every size 8...40).
    func testLabelLineHeightBands() {
        let expected: [Double: Double] = [
            8: 10, 9: 11, 10: 13, 11: 14, 12: 15, 13: 16, 14: 17, 15: 19,
            16: 19, 17: 20, 18: 21, 19: 23, 20: 24, 21: 25, 22: 26, 23: 27,
            24: 28, 28: 33, 34: 40, 40: 47, 11.5: 14, 13.5: 16, 17.5: 21,
        ]
        for (size, h) in expected {
            XCTAssertEqual(FontEngine.labelLineHeight(for: .systemFont(ofSize: size)), h,
                           accuracy: 1e-9, "size \(size)")
        }
    }

    /// Non-ASCII advances vendored in font_metrics.json (harvested from the
    /// oracle with the same NSString measurement as the ASCII ones). The
    /// U+203A chevron drove demo_settings' 14 layout failures: the fallback
    /// estimate gave 7pt-wide labels where real UIKit gives 8pt.
    func testVendoredNonASCIIAdvances() throws {
        let chevron = Unicode.Scalar(0x203A)!
        let emDash = Unicode.Scalar(0x2014)!
        // Oracle values (advprobe, NSString.size(withAttributes:)).
        XCTAssertEqual(FontEngine.advance(of: chevron,
                                          font: .systemFont(ofSize: 17, weight: .semibold)),
                       7.569337725639343, accuracy: 1e-9)
        XCTAssertEqual(FontEngine.advance(of: emDash, font: .systemFont(ofSize: 13)),
                       11.54638671875, accuracy: 1e-9)
        // demo_settings chevron labels: intrinsic width must ceil to 8pt.
        XCTAssertEqual(FontEngine.ceilToPixel(
            FontEngine.measure("\u{203A}", font: .systemFont(ofSize: 17, weight: .semibold)),
            scale: 2), 8.0, accuracy: 1e-9)
        // Fractional sizes interpolate the ext advances like ASCII ones.
        let lo = FontEngine.advance(of: chevron, font: .systemFont(ofSize: 16))
        let hi = FontEngine.advance(of: chevron, font: .systemFont(ofSize: 17))
        XCTAssertEqual(FontEngine.advance(of: chevron, font: .systemFont(ofSize: 16.5)),
                       lo + 0.5 * (hi - lo), accuracy: 1e-9)
        // U+2026 keeps the exact label-context (tight-table) advance, which
        // the ext table must not override.
        XCTAssertEqual(FontEngine.advance(of: Unicode.Scalar(0x2026)!,
                                          font: .systemFont(ofSize: 17)),
                       FontEngine.ellipsisAdvance(for: .systemFont(ofSize: 17)),
                       accuracy: 1e-9)
    }
}
