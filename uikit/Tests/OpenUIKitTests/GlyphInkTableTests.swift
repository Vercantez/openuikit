// Text-module tests: GlyphInkTable phase model + mask resource integrity
// and the gamma-space text blend.
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
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

    // MARK: Window-server ink variants (glyph_ink_window.json)

    func testWindowMaskSelectionAndFallback() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        let i = Unicode.Scalar(UInt8(105))  // 'i', harvested in both tables
        let off = try XCTUnwrap(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                   dark: false, tag: "0", scalar: i))
        GlyphInkTable.windowCompositing = true
        defer { GlyphInkTable.windowCompositing = false }
        let win = try XCTUnwrap(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                   dark: false, tag: "0", scalar: i))
        // The render server rasterizes darker/crisper — masks must differ.
        let winPixels: [UInt8] = win.mask
        let offPixels: [UInt8] = off.mask
        let samePixels: Bool = winPixels.elementsEqual(offPixels)
        var sameGeom = true
        if win.width != off.width { sameGeom = false }
        if win.ox != off.ox { sameGeom = false }
        if win.oy != off.oy { sameGeom = false }
        XCTAssertFalse(samePixels && sameGeom,
                       "window-variant mask should differ from the offscreen mask")
        // Window text is stem-darkened: peak coverage at least as high.
        XCTAssertGreaterThanOrEqual(win.mask.max() ?? 0, off.mask.max() ?? 0)
        // A glyph absent from the window table falls back to the offscreen
        // table (mono-regular has no window harvest).
        let monoOff = GlyphInkTable.windowCompositing
            ? GlyphInkTable.mask(familyKey: "mono-regular", sizeKey: 17,
                                 dark: false, tag: "0", scalar: Unicode.Scalar(UInt8(101)))
            : nil
        GlyphInkTable.windowCompositing = false
        let monoPlain = GlyphInkTable.mask(familyKey: "mono-regular", sizeKey: 17,
                                           dark: false, tag: "0", scalar: Unicode.Scalar(UInt8(101)))
        GlyphInkTable.windowCompositing = true
        XCTAssertEqual(monoOff?.mask, monoPlain?.mask,
                       "missing window entry must fall back to the offscreen mask")
    }

    func testWindowTablePhaseCoverageForDeepMixed() throws {
        // Every (size, phase, char) combo deep_mixed's labels hit must be in
        // the window table: 17pt tags {0,P1} for the row labels, 12pt tags
        // {0,T,H,P2} for the footer.
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        GlyphInkTable.windowCompositing = true
        defer { GlyphInkTable.windowCompositing = false }
        for ch in "Wi-FiBluetoothStorageBattery".unicodeScalars {
            for tag in ["0", "P1"] {
                XCTAssertNotNil(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 17,
                                                   dark: false, tag: tag, scalar: ch),
                                "missing 17pt window mask \(ch) tag \(tag)")
            }
        }
        for ch in "Settingsfooterexplanationtext".unicodeScalars {
            for tag in ["0", "T", "H", "P2"] {
                XCTAssertNotNil(GlyphInkTable.mask(familyKey: "system-regular", sizeKey: 12,
                                                   dark: false, tag: tag, scalar: ch),
                                "missing 12pt window mask \(ch) tag \(tag)")
            }
        }
    }

    private func tags(forSize size: Int) -> [String] {
        if size < 12 { return ["0", "P1", "P2", "P3"] }
        if size < 16 { return ["0", "T", "H", "P2"] }
        if size < 29 { return ["0", "P1"] }
        return ["0"]
    }

    private func assertCoverage(_ family: String, _ size: Int, _ text: String,
                                dark: Bool = false, file: StaticString = #filePath,
                                line: UInt = #line) {
        for ch in text.unicodeScalars where ch != " " {
            for tag in tags(forSize: size) {
                XCTAssertNotNil(GlyphInkTable.mask(familyKey: family, sizeKey: size,
                                                   dark: dark, tag: tag, scalar: ch),
                                "missing \(family)-\(size)\(dark ? " dark" : "") mask '\(ch)' tag \(tag)",
                                file: file, line: line)
            }
        }
    }

    /// Offscreen harvest coverage for every button_states title (all phase
    /// tags per char, so advance tweaks that shift pen phases stay covered).
    func testOffscreenCoverageForButtonStates() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        assertCoverage("system-regular", 11, "Tiny 11")
        assertCoverage("system-regular", 13, "Small 13")
        assertCoverage("system-regular", 17, "Regular 17Green")
        assertCoverage("system-regular", 24, "Large 24")
        assertCoverage("system-regular", 20, "Disabled 20")
        assertCoverage("system-regular", 14, "Very long button title that fills the frame width")
        assertCoverage("system-light", 17, "Light")
        assertCoverage("system-medium", 17, "Medium")
        assertCoverage("system-heavy", 17, "Heavy")
        assertCoverage("system-bold", 17, "Disabled Bold")
    }

    /// Window-table coverage for every demo_settings string (34pt title,
    /// 17pt rows, 17pt semibold chevrons/name, 13pt captions incl. the em
    /// dash, and the default 15pt button titles).
    func testWindowCoverageForDemoSettings() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        GlyphInkTable.windowCompositing = true
        defer { GlyphInkTable.windowCompositing = false }
        assertCoverage("system-bold", 34, "Settings")
        assertCoverage("system-regular", 17,
                       "SearchHomeNetOnAirplane ModeWi-FiBluetoothGeneraliPhone Storage" +
                       "Critical AlertsMessagesPromotions")
        assertCoverage("system-semibold", 17, "Miguel Salinas\u{203A}")
        assertCoverage("system-regular", 13,
                       "Account, iCloud, and more72%NOTIFY ME ABOUT" +
                       "OpenUIKit demo \u{2014} rendered without UIKit")
        assertCoverage("system-regular", 15, "Sign OutHelp")
    }

    /// Dark-mode offscreen coverage for button_dark's titles.
    func testOffscreenDarkCoverageForButtonDark() throws {
        try XCTSkipUnless(GlyphInkTable.isAvailable, "glyph_ink.json not present")
        assertCoverage("system-regular", 15, "Plain DarkDisabled DarkOrange Title", dark: true)
        assertCoverage("system-semibold", 17, "Semibold Dark", dark: true)
    }

    /// Linux trial 2026-09-05: iOS-cut masks are keyed so a VM without
    /// SFNS.ttf can draw harvested glyphs and fail with this exact string
    /// when a cell is missing.
    func testIOSMaskKeyFormatAndHarvestedHit() throws {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        try XCTSkipUnless(GlyphInkTable.hasIOSTable(scale: 2),
                          "glyph_ink_ios.json not present")
        let a = Unicode.Scalar(UInt32(65))!
        let key = GlyphInkTable.iosMaskKey(familyKey: "system-regular", sizeKey: 17,
                                           dark: false, tag: "F0.0", scalar: a,
                                           scale: 2)
        XCTAssertTrue(key.hasPrefix("I|system-regular|17|light|F0.0|"))
        XCTAssertNotNil(GlyphInkTable.maskIOS(familyKey: "system-regular", sizeKey: 17,
                                              dark: false, tag: "F0.0", scalar: a,
                                              scale: 2))
        XCTAssertNil(GlyphInkTable.maskIOS(familyKey: "system-regular", sizeKey: 17,
                                           dark: false, tag: "F0.0",
                                           scalar: Unicode.Scalar(UInt32(81))!,
                                           scale: 2),
                     "unharvested Q (U+0051) must miss so OPENUIKIT_IOS_INK_MISS can name it")
        // MEASURED guest-trial2: picker "Select Episodes" 18 pt semibold S;
        // "ROW ACTION" 13 pt bold R (a43f92cf then I|system-bold|13|…|82).
        XCTAssertNotNil(GlyphInkTable.maskIOS(familyKey: "system-semibold", sizeKey: 18,
                                              dark: false, tag: "F0.0",
                                              scalar: Unicode.Scalar(UInt32(83))!,
                                              scale: 2))
        XCTAssertNotNil(GlyphInkTable.maskIOS(familyKey: "system-bold", sizeKey: 13,
                                              dark: false, tag: "F0.0",
                                              scalar: Unicode.Scalar(UInt32(82))!,
                                              scale: 2))
        XCTAssertNotNil(GlyphInkTable.maskIOS(familyKey: "system-regular", sizeKey: 13,
                                              dark: false, tag: "F0.75",
                                              scalar: Unicode.Scalar(UInt32(36))!,
                                              scale: 2))
        // MEASURED arm64 f75875cc: Focus home 12 pt regular k at F0.25
        // ("0 trackers blocked so far", ShareTrackersViewController).
        XCTAssertNotNil(GlyphInkTable.maskIOS(familyKey: "system-regular", sizeKey: 12,
                                              dark: false, tag: "F0.25",
                                              scalar: Unicode.Scalar(UInt32(107))!,
                                              scale: 2))
    }
}
