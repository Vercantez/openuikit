// Text-module diagnostic: my stbtt_Rasterize glue vs stb's own bitmap path
// must produce identical masks for the same (default-instance) outline.
import XCTest
import CSTBTrueType
@testable import OpenUIKit

final class RasterizeABTests: XCTestCase {

    func testWrapperMatchesStbDefaultPath() throws {
        guard let gf = GlyphFont(path: "/System/Library/Fonts/SFNS.ttf") else {
            throw XCTSkip("system font unavailable")
        }
        let g = gf.glyphIndex(of: "H")
        let s = Float(gf.emScale(forPixels: 34))
        let shiftX: Float = 0.25, shiftY: Float = 0.25

        // Path A: stb built-in
        var x0: Int32 = 0, y0: Int32 = 0, x1: Int32 = 0, y1: Int32 = 0
        stbtt_GetGlyphBitmapBoxSubpixel(&gf.info, g, s, s, shiftX, shiftY, &x0, &y0, &x1, &y1)
        let w = Int(x1 - x0), h = Int(y1 - y0)
        var maskA = [UInt8](repeating: 0, count: w * h)
        maskA.withUnsafeMutableBufferPointer { buf in
            stbtt_MakeGlyphBitmapSubpixel(&gf.info, buf.baseAddress, Int32(w), Int32(h),
                                          Int32(w), s, s, shiftX, shiftY, g)
        }

        // Path B: my wrapper on stb's own vertices
        var verts: UnsafeMutablePointer<stbtt_vertex>? = nil
        let n = stbtt_GetGlyphShape(&gf.info, g, &verts)
        defer { stbtt_FreeShape(&gf.info, verts) }
        var maskB = [UInt8](repeating: 0, count: w * h)
        maskB.withUnsafeMutableBufferPointer { buf in
            var bm = stbtt__bitmap(w: Int32(w), h: Int32(h), stride: Int32(w),
                                   pixels: buf.baseAddress)
            stbtt_Rasterize(&bm, 0.35, verts, n, s, s, shiftX, shiftY, x0, y0, 1, nil)
        }

        var diffs = 0
        var maxd = 0
        for i in 0..<(w * h) {
            let d = abs(Int(maskA[i]) - Int(maskB[i]))
            if d > 0 { diffs += 1 }
            maxd = max(maxd, d)
        }
        print("mask \(w)x\(h) differing bytes: \(diffs), max delta: \(maxd)")
        // row sums to localize any shift
        func rowSum(_ m: [UInt8], _ r: Int) -> Int {
            var t = 0
            for x in 0..<w { t += Int(m[r * w + x]) }
            return t
        }
        for r in [0, 1, h - 2, h - 1] {
            print("row \(r): A=\(rowSum(maskA, r)) B=\(rowSum(maskB, r))")
        }
        XCTAssertEqual(diffs, 0)
    }
}
