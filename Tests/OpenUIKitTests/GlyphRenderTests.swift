// Glyph rasterization + label drawing smoke tests.
// These depend on system font files being present (this Mac has them);
// they skip gracefully if not.
import Foundation
import XCTest
@testable import OpenUIKit

final class GlyphRenderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    func testGlyphRasterization() throws {
        let font = UIFont.systemFont(ofSize: 17)
        guard let gf = GlyphRasterizer.font(for: font) else {
            throw XCTSkip("no system font file available")
        }
        let g = gf.glyphIndex(of: "H")
        XCTAssertNotEqual(g, 0)
        // 17pt at 2x -> 34px em mapping; 'H' should be about capHeight tall
        // (23.96px for the UIKit-optical face; the stb default instance may
        // differ slightly, so allow a generous band).
        let bmp = try XCTUnwrap(gf.rasterize(glyph: g, pixelSize: 34, shiftX: 0))
        XCTAssertGreaterThan(bmp.height, 18)
        XCTAssertLessThan(bmp.height, 30)
        XCTAssertGreaterThan(bmp.width, 8)
        XCTAssertLessThan(bmp.width, 30)
        XCTAssertTrue(bmp.mask.contains { $0 > 200 }, "solid coverage expected")
        // Glyph top (baseline + offsetY) must sit above the baseline.
        XCTAssertLessThan(bmp.offsetY, 0)
    }

    func testLabelDrawsGlyphsRoughlyInPlace() throws {
        let font = UIFont.systemFont(ofSize: 17)
        guard GlyphRasterizer.font(for: font) != nil else {
            throw XCTSkip("no system font file available")
        }
        let label = UILabel()
        label.text = "Hello UIKit"
        label.textColor = .black
        label.sizeToFit()
        let w = Int((label.bounds.width * 2).rounded()), h = Int((label.bounds.height * 2).rounded())
        let bitmap = Bitmap(width: w, height: h)
        let canvas = Canvas(bitmap: bitmap, scale: 2)
        label.drawContent(in: canvas, bounds: label.bounds)

        // Find ink rows/cols (alpha channel).
        var minX = w, maxX = -1, minY = h, maxY = -1
        for y in 0..<h {
            for x in 0..<w where bitmap.pixels[(y * w + x) * 4 + 3] > 64 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        XCTAssertGreaterThanOrEqual(maxX, 0, "label drew no glyphs")
        // Ink must roughly fill the width (83.5pt -> 167px) and sit within
        // the 40px line box: cap top around row 6-11, baseline near row 31-35.
        XCTAssertLessThan(minX, 8)
        XCTAssertGreaterThan(maxX, w - 20)
        XCTAssertGreaterThan(minY, 2)
        XCTAssertLessThan(minY, 14)
        XCTAssertGreaterThan(maxY, 24)
        XCTAssertLessThan(maxY, h)
    }

    func testMissingFontFileIsGraceful() {
        let saved = OpenUIKitRuntime.fontPaths
        defer { OpenUIKitRuntime.fontPaths = saved }
        // Force all candidate paths to garbage via overrides is not possible
        // for the hard-coded fallbacks, so just exercise the loader's failure
        // path directly.
        XCTAssertNil(GlyphFont(path: "/nonexistent/definitely-not-a-font.ttf"))
        XCTAssertNil(GlyphRasterizer.load(["/nonexistent/a.ttf", "/nonexistent/b.ttf"]))
    }
}
