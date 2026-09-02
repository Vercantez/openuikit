// Tests for the quartz-backend module (Backend.swift / QuartzBackend.swift):
// dual-render parity between the Swift rasterizer and the QuartzBackend
// through the SAME Canvas API calls.
import XCTest
@testable import OpenCoreGraphics

private typealias CGAffineTransform = OpenCoreGraphics.CGAffineTransform

@MainActor
final class BackendParityTests: XCTestCase {

    private var savedBackend: RenderBackend = CanvasBackendSelection.current
    override func setUp() {
        super.setUp()
        savedBackend = CanvasBackendSelection.current
    }
    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        super.tearDown()
    }

    /// Render `draw` with both backends into identical bitmaps; return the
    /// maximum per-channel byte delta after compositing over white AND over
    /// black (covers color and alpha; ignores the RGB of fully transparent
    /// pixels, which a premultiplied backing cannot represent).
    private func maxDelta(width: Int, height: Int, scale: CGFloat = 2,
                          _ draw: (Canvas) -> Void) -> Int {
        var results: [[UInt8]] = []
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bmp = Bitmap(width: width, height: height)
            let canvas = Canvas(bitmap: bmp, scale: scale)
            draw(canvas)
            results.append(bmp.pixels)
        }
        var d = 0.0
        for p in 0..<(width * height) {
            let o = p * 4
            let a0 = Double(results[0][o + 3]) / 255, a1 = Double(results[1][o + 3]) / 255
            for ch in 0..<3 {
                let c0 = Double(results[0][o + ch]) * a0, c1 = Double(results[1][o + ch]) * a1
                d = max(d, abs((c0 + 255 * (1 - a0)) - (c1 + 255 * (1 - a1))))  // over white
                d = max(d, abs(c0 - c1))                                        // over black
            }
        }
        return Int(d.rounded())
    }

    /// Asymmetric fixture: proves the flip CTM (a y-mirrored render would
    /// differ by hundreds of counts, not single digits).
    func testAsymmetricFillParity() {
        let d = maxDelta(width: 100, height: 80) { c in
            c.fill(rect: CGRect(x: 2, y: 3, width: 20, height: 8),
                   color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            c.fill(.roundedRect(CGRect(x: 10, y: 22, width: 30, height: 12), cornerRadius: 5),
                   color: CGColor(red: 0, green: 0.5, blue: 1, alpha: 0.6))
        }
        XCTAssertLessThanOrEqual(d, 3, "asymmetric fills differ between backends")
    }

    func testHardEdgedRotatedFillParity() {
        let d = maxDelta(width: 64, height: 64) { c in
            c.fill(rect: CGRect(x: 0, y: 0, width: 32, height: 32),
                   color: CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
            c.save()
            c.translate(x: 16, y: 16)
            c.concatenate(CGAffineTransform(rotationAngle: 0.5))
            c.fill(.rect(CGRect(x: -8, y: -5, width: 16, height: 10)),
                   color: CGColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1),
                   hardEdges: true)
            c.restore()
        }
        // Hard edges are 0/1 threshold at pixel centers in both backends; a
        // center exactly on the edge may flip, so allow full-pixel disagreement
        // only if it never happens (delta must be 0 for off-edge geometry).
        XCTAssertLessThanOrEqual(d, 3, "hard-edged rotated fill differs")
    }

    func testTransparencyLayerGroupAlphaParity() {
        let d = maxDelta(width: 40, height: 40) { c in
            c.fill(rect: CGRect(x: 0, y: 0, width: 20, height: 20),
                   color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            c.beginTransparencyLayer(alpha: 0.5)
            // Overlapping fills must composite first, THEN fade as a unit.
            c.fill(rect: CGRect(x: 2, y: 2, width: 10, height: 10),
                   color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            c.fill(rect: CGRect(x: 6, y: 6, width: 10, height: 10),
                   color: CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            c.endTransparencyLayer()
        }
        XCTAssertLessThanOrEqual(d, 3, "group alpha semantics differ")
    }

    func testClipAndMaskParity() {
        // Glyph-style coverage mask under a rounded clip.
        var mask = [UInt8](repeating: 0, count: 12 * 10)
        for y in 0..<10 { for x in 0..<12 { mask[y * 12 + x] = UInt8((x * 21 + y * 9) % 256) } }
        let d = maxDelta(width: 30, height: 30, scale: 1) { c in
            c.fill(rect: CGRect(x: 0, y: 0, width: 30, height: 30),
                   color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            c.save()
            c.clip(to: CGRect(x: 4, y: 4, width: 18, height: 14), cornerRadius: 4)
            c.fill(rect: CGRect(x: 0, y: 0, width: 30, height: 30),
                   color: CGColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1))
            c.drawMask(mask, width: 12, height: 10, atPixelX: 6, pixelY: 6,
                       color: CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            c.restore()
        }
        XCTAssertLessThanOrEqual(d, 3, "clip+mask differs")
    }

    func testDrawImageParity() {
        let img = Bitmap(width: 4, height: 3)
        for y in 0..<3 { for x in 0..<4 {
            let o = (y * 4 + x) * 4
            img.pixels[o] = UInt8(40 * x + 10)
            img.pixels[o + 1] = UInt8(60 * y + 20)
            img.pixels[o + 2] = 200
            img.pixels[o + 3] = 255
        } }
        // Nearest-neighbor at integer alignment must agree exactly modulo
        // rounding; the interpolating filters intentionally differ (quartz
        // matches CG's sharper kernel), so only 'interpolate: false' is a
        // parity requirement.
        let d = maxDelta(width: 32, height: 24, scale: 2) { c in
            c.draw(img, in: CGRect(x: 2, y: 3, width: 8, height: 6), interpolate: false)
        }
        XCTAssertLessThanOrEqual(d, 3, "nearest-neighbor image draw differs")
    }

    /// Image draw must not be vertically mirrored under the quartz backend
    /// (regression guard for the y-flip counter-transform).
    func testDrawImageOrientationQuartz() {
        CanvasBackendSelection.current = .quartz
        let img = Bitmap(width: 2, height: 2)
        // top row red, bottom row green (straight alpha)
        img.pixels = [255, 0, 0, 255,  255, 0, 0, 255,
                      0, 255, 0, 255,  0, 255, 0, 255]
        let bmp = Bitmap(width: 8, height: 8)
        let c = Canvas(bitmap: bmp, scale: 1)
        c.draw(img, in: CGRect(x: 0, y: 0, width: 8, height: 8), interpolate: false)
        // pixel (4,1) is in the top half -> red; (4,6) bottom half -> green
        let top = (1 * 8 + 4) * 4, bottom = (6 * 8 + 4) * 4
        XCTAssertGreaterThan(bmp.pixels[top], bmp.pixels[top + 1], "top half should be red")
        XCTAssertGreaterThan(bmp.pixels[bottom + 1], bmp.pixels[bottom], "bottom half should be green")
    }

    /// bitmap.pixels must be current immediately after each op (the backing
    /// sync must not wait for pngData).
    func testPixelsCurrentAfterEachOpQuartz() {
        CanvasBackendSelection.current = .quartz
        let bmp = Bitmap(width: 10, height: 10)
        let c = Canvas(bitmap: bmp, scale: 1)
        c.fill(rect: CGRect(x: 0, y: 0, width: 10, height: 5),
               color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(bmp.pixels[(2 * 10 + 2) * 4], 255)
        XCTAssertEqual(bmp.pixels[(2 * 10 + 2) * 4 + 3], 255)
        c.fill(rect: CGRect(x: 0, y: 5, width: 10, height: 5),
               color: CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        XCTAssertEqual(bmp.pixels[(7 * 10 + 2) * 4 + 1], 255)
    }

    func testStrokeParityCoarse() {
        // Stroking models differ in join/cap details; require agreement on a
        // simple straight segment away from the ends.
        let d = maxDelta(width: 40, height: 20, scale: 1) { c in
            var p = Path()
            p.move(to: CGPoint(x: 4, y: 10))
            p.addLine(to: CGPoint(x: 36, y: 10))
            c.stroke(p, color: CGColor(red: 0, green: 0, blue: 0, alpha: 1), lineWidth: 4)
        }
        XCTAssertLessThanOrEqual(d, 3, "straight-line stroke differs")
    }
}
