import XCTest
@testable import OpenUIKit

final class SmoothProbeTests: XCTestCase {
    func testSmoothedHRow() throws {
        guard let inst = GlyphRasterizer.font(for: .systemFont(ofSize: 17)) else {
            throw XCTSkip("no font")
        }
        let g = inst.glyphIndex(of: "H")
        guard let bmp = inst.rasterizeSmoothed(glyph: g, devicePixelSize: 34, phaseX: 0) else {
            return XCTFail("no mask")
        }
        print("smoothed w=\(bmp.width) h=\(bmp.height) offx=\(bmp.offsetX) offy=\(bmp.offsetY)")
        // row through stem middle: absolute device y = -12 (halfway up cap 24px)
        let row = -12 - bmp.offsetY
        var vals: [Int] = []
        for x in 0..<min(bmp.width, 14) { vals.append(Int(bmp.mask[row * bmp.width + x])) }
        print("row(y=-12):", vals)
    }
}
