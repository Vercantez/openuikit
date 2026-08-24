// Text-module tests: GlyphInkTable phase model + mask resource integrity
// and the gamma-space text blend.
import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat

final class GlyphInkTableTests: XCTestCase {

    // MARK: Phase quantization model (measured against oracle probes)

    func testPhaseTagsHalfPointSizes() {
        // 16..<29pt: halves {0, 1/2}.
        for size: CGFloat in [17, 19, 20, 24, 28] {
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.0).tag, "0")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.49).tag, "0")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.5).tag, "P1")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.99).tag, "P1")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.49).anchor, 0)
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.5).anchor, 1)
        }
    }

    func testPhaseTagsThirdSizes() {
        // 12..<16pt: {0, 1/3, 1/2, 2/3}.
        for size: CGFloat in [12, 13, 14, 15] {
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.2).tag, "0")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.4).tag, "T")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.55).tag, "H")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.8).tag, "P2")
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.4).anchor, 0)
            XCTAssertEqual(GlyphInkTable.phase(size: size, frac: 0.55).anchor, 1)
        }
    }

    func testPhaseTagsQuarterAndWholeSizes() {
        XCTAssertEqual(GlyphInkTable.phase(size: 10, frac: 0.3).tag, "P1")
        XCTAssertEqual(GlyphInkTable.phase(size: 10, frac: 0.6).tag, "P2")
        XCTAssertEqual(GlyphInkTable.phase(size: 10, frac: 0.8).tag, "P3")
        // >= 29pt: whole-point positions only; anchor always 0.
        XCTAssertEqual(GlyphInkTable.phase(size: 34, frac: 0.9).tag, "0")
        XCTAssertEqual(GlyphInkTable.phase(size: 34, frac: 0.9).anchor, 0)
    }

    // MARK: Resource integrity

    func testMaskLookupAndDimensions() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        // 'l' at 17pt regular, phase 0 — harvested from the oracle.
        let m = try XCTUnwrap(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                 dark: false, tag: "0",
                                                 scalar: Unicode.Scalar(108)))
        XCTAssertEqual(m.mask.count, m.width * m.height)
        XCTAssertGreaterThan(m.width, 0)
        // A 17pt 'l' is ~26 device px tall plus smoothing spread.
        XCTAssertTrue((20...40).contains(m.height), "height \(m.height)")
        // Both phases exist at half-point sizes.
        XCTAssertNotNil(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                           dark: false, tag: "P1",
                                           scalar: Unicode.Scalar(108)))
        // Miss returns nil (unknown char).
        XCTAssertNil(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                        dark: false, tag: "0",
                                        scalar: Unicode.Scalar(0x2603)!))
    }

    func testHexDecode() {
        XCTAssertEqual(GlyphInkTable.hexDecode("00ff7f"), [0, 255, 127])
        XCTAssertNil(GlyphInkTable.hexDecode("0"))
        XCTAssertNil(GlyphInkTable.hexDecode("zz"))
    }

    // MARK: Gamma helpers

    func testPowNormMatchesReference() {
        // Reference values from Foundation pow (double precision).
        let cases: [(CGFloat, CGFloat, CGFloat)] = [
            (0.5765, 0.79, 0.6471894903418466),
            (0.15294, 0.79, 0.2268671722178754),
            (0.3, 1.2658227848101267, 0.21783525606482596),
        ]
        for (x, p, want) in cases {
            XCTAssertEqual(GlyphInkTable.powNorm(x, p), want, accuracy: 1e-9)
        }
    }

    func testMaskLinearRoundTripsCalibrationColor() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        // Drawing the linear mask with the calibration color through the
        // gamma blend must reproduce the stored sRGB-effective coverage.
        let stored = try XCTUnwrap(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                      dark: false, tag: "0",
                                                      scalar: Unicode.Scalar(108)))
        let linear = try XCTUnwrap(GlyphInkTable.maskLinear(familyKey: "system-regular", sizeKey: 17,
                                                            dark: false, tag: "0",
                                                            scalar: Unicode.Scalar(108)))
        let g = GlyphInkTable.blendGamma
        let full: CGFloat = 216.0 / 255.0
        let fullG = GlyphInkTable.powNorm(1 - full, g)
        for i in 0..<stored.mask.count where stored.mask[i] > 0 {
            let cT = CGFloat(linear.mask[i]) / 255
            // gamma blend of black@0.847 over white at true coverage cT:
            let p = GlyphInkTable.powNorm(
                (1 + (fullG - 1) * cT), 1 / g)
            let effective = (1 - p) / full
            XCTAssertEqual(effective, CGFloat(stored.mask[i]) / 255, accuracy: 2.5 / 255,
                           "at \(i)")
        }
    }

    // MARK: End-to-end: label render must use harvested ink

    func testLabelRenderMatchesHarvestedMask() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 22))
        label.text = "l"
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 22))
        root.backgroundColor = .white
        root.addSubview(label)
        let bmp = UIRenderer.render(root, scale: 2)
        let m = try XCTUnwrap(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                 dark: false, tag: "0",
                                                 scalar: Unicode.Scalar(108)))
        // Baseline: y0 = floor((22-20)/2+0.5)=1; +floor(16.435+0.5)=16 → 17pt → 34px.
        let baseY = 34
        var maxDelta = 0
        for my in 0..<m.height {
            for mx in 0..<m.width {
                let x = m.ox + mx, y = baseY + m.oy + my
                guard x >= 0, y >= 0, x < bmp.width, y < bmp.height else { continue }
                let o = (y * bmp.width + x) * 4
                let px = Int(bmp.pixels[o])  // red channel over white bg
                let want = 255 - Int((CGFloat(m.mask[my * m.width + mx]) * 216 / 255).rounded())
                maxDelta = max(maxDelta, abs(px - want))
            }
        }
        XCTAssertLessThanOrEqual(maxDelta, 2, "rendered glyph should equal harvested ink")
    }
}
