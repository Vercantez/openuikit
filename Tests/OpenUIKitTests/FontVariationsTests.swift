// Text-module tests: variable-font instancing (FontVariations).
// Ground truth cross-checked against fontTools on the same system font.
import XCTest
@testable import OpenUIKit

@MainActor
final class FontVariationsTests: XCTestCase {

    private func systemFontIfAvailable() -> GlyphFont? {
        GlyphFont(path: "/System/Library/Fonts/SFNS.ttf")
    }

    /// SFNS 'H' at opsz=17/wght=400 must match fontTools' instanced bounds
    /// (184, 0, 1336, 1443) — regression guard for gvar delta application.
    func testInstancedHBoundsAtOpsz17() throws {
        guard let gf = systemFontIfAvailable(), let vars = gf.variations else {
            throw XCTSkip("system font unavailable")
        }
        let inst = GlyphRasterizer.font(for: .systemFont(ofSize: 17))
        XCTAssertNotNil(inst)
        let user: [UInt32: Double] = [
            GlyphRasterizer.tag("wght"): 400,
            GlyphRasterizer.tag("opsz"): 17,
        ]
        let coords = vars.normalizedCoords(user)
        let g = gf.glyphIndex(of: "H")
        XCTAssertNotEqual(g, 0)
        guard let verts = vars.instancedVertices(glyph: Int(g), coords: coords),
              !verts.isEmpty else {
            return XCTFail("no outline")
        }
        var minX = Int16.max, minY = Int16.max, maxX = Int16.min, maxY = Int16.min
        for v in verts {
            minX = min(minX, v.x); maxX = max(maxX, v.x)
            minY = min(minY, v.y); maxY = max(maxY, v.y)
        }
        print("H bounds instanced: (\(minX), \(minY), \(maxX), \(maxY))")
        XCTAssertEqual(Int(minX), 184, accuracy: 3)
        XCTAssertEqual(Int(minY), 0, accuracy: 3)
        XCTAssertEqual(Int(maxX), 1336, accuracy: 3)
        XCTAssertEqual(Int(maxY), 1443, accuracy: 3)
    }

    /// Default instance (all coords 0 → but SFNS default opsz=28) H bounds
    /// from the raw glyf table: (140, 0, 1292, 1443).
    func testDefaultInstanceHBounds() throws {
        guard let gf = systemFontIfAvailable(), let vars = gf.variations else {
            throw XCTSkip("system font unavailable")
        }
        let coords = vars.normalizedCoords([:])
        let g = gf.glyphIndex(of: "H")
        guard let verts = vars.instancedVertices(glyph: Int(g), coords: coords),
              !verts.isEmpty else {
            return XCTFail("no outline")
        }
        var minX = Int16.max, minY = Int16.max, maxX = Int16.min, maxY = Int16.min
        for v in verts {
            minX = min(minX, v.x); maxX = max(maxX, v.x)
            minY = min(minY, v.y); maxY = max(maxY, v.y)
        }
        print("H bounds default: (\(minX), \(minY), \(maxX), \(maxY))")
        XCTAssertEqual(Int(minX), 140, accuracy: 3)
        XCTAssertEqual(Int(maxX), 1292, accuracy: 3)
        XCTAssertEqual(Int(maxY), 1443, accuracy: 3)
    }
}

private func XCTAssertEqual(_ a: Int, _ b: Int, accuracy: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(abs(a - b) <= accuracy, "\(a) != \(b) ± \(accuracy)",
                  file: file, line: line)
}
