// Tests for the rasterizer module (Sources/OpenCoreGraphics/Rasterizer.swift).
import XCTest
@testable import OpenCoreGraphics

// XCTest re-exports Foundation/CoreGraphics on Apple platforms; pin the
// geometry types to the OpenCoreGraphics implementations under test.
private typealias CGFloat = OpenCoreGraphics.CGFloat
private typealias CGPoint = OpenCoreGraphics.CGPoint
private typealias CGRect = OpenCoreGraphics.CGRect
private typealias CGColor = OpenCoreGraphics.CGColor
private typealias CGAffineTransform = OpenCoreGraphics.CGAffineTransform

@MainActor
final class RasterizerTests: XCTestCase {

    // These tests assert the pure-Swift rasterizer's exact analytic-coverage
    // and bilinear-sampling semantics — pin the swift backend regardless of
    // the process-wide default (which may be .quartz).
    private var savedBackend: RenderBackend = CanvasBackendSelection.current
    override func setUp() {
        super.setUp()
        savedBackend = CanvasBackendSelection.current
        CanvasBackendSelection.current = .swift
    }
    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        super.tearDown()
    }

    // MARK: helpers

    private func makeCanvas(width: Int, height: Int, scale: CGFloat = 1) -> Canvas {
        Canvas(bitmap: Bitmap(width: width, height: height), scale: scale)
    }

    private func alpha(_ c: Canvas, _ x: Int, _ y: Int) -> Int {
        Int(c.bitmap.pixels[(y * c.bitmap.width + x) * 4 + 3])
    }

    private func rgba(_ c: Canvas, _ x: Int, _ y: Int) -> [Int] {
        let o = (y * c.bitmap.width + x) * 4
        return (0..<4).map { Int(c.bitmap.pixels[o + $0]) }
    }

    /// Sum of coverage (alpha/255) over the whole bitmap.
    private func coverageSum(_ c: Canvas) -> Double {
        var s = 0.0
        let n = c.bitmap.width * c.bitmap.height
        for i in 0..<n { s += Double(c.bitmap.pixels[i * 4 + 3]) / 255 }
        return s
    }

    // MARK: exact axis-aligned subpixel coverage

    func testAxisAlignedSubpixelCoverageExact() {
        let c = makeCanvas(width: 40, height: 30)
        // Rect starting at x = 10.25 -> left edge pixel coverage 0.75.
        c.fill(rect: CGRect(x: 10.25, y: 5, width: 9.75, height: 10), color: CGColor.white)
        XCTAssertEqual(alpha(c, 9, 8), 0, "pixel left of rect must be empty")
        XCTAssertEqual(alpha(c, 10, 8), Int((0.75 * 255).rounded()), "edge pixel must be exactly 0.75 covered")
        XCTAssertEqual(alpha(c, 11, 8), 255, "interior pixel must be fully covered")
        XCTAssertEqual(alpha(c, 19, 8), 255, "right edge at x=20 is pixel-aligned -> full")
        XCTAssertEqual(alpha(c, 20, 8), 0)
        // Vertical edges too.
        XCTAssertEqual(alpha(c, 12, 4), 0)
        XCTAssertEqual(alpha(c, 12, 5), 255)
    }

    func testAxisAlignedFractionalBothEdges() {
        let c = makeCanvas(width: 20, height: 20)
        // x from 3.25 to 3.75 entirely inside pixel 3 -> coverage 0.5.
        c.fill(rect: CGRect(x: 3.25, y: 2, width: 0.5, height: 5), color: CGColor.white)
        XCTAssertEqual(alpha(c, 3, 4), Int((0.5 * 255).rounded()))
        XCTAssertEqual(alpha(c, 2, 4), 0)
        XCTAssertEqual(alpha(c, 4, 4), 0)
        // Fractional vertically as well: y from 10.1 to 10.9 -> 0.8.
        let c2 = makeCanvas(width: 20, height: 20)
        c2.fill(rect: CGRect(x: 2, y: 10.1, width: 5, height: 0.8), color: CGColor.white)
        XCTAssertEqual(alpha(c2, 4, 10), Int((0.8 * 255).rounded()))
    }

    func testSubpixelCoverageTotalAreaExact() {
        // Total painted coverage must equal the rect area exactly.
        let c = makeCanvas(width: 30, height: 30)
        let r = CGRect(x: 3.3, y: 4.7, width: 11.4, height: 7.9)
        c.fill(rect: r, color: CGColor.white)
        let area = 11.4 * 7.9
        XCTAssertEqual(coverageSum(c), area, accuracy: area * 0.002 + 0.5)
    }

    // MARK: circle accuracy

    func testCircleFillAreaWithinHalfPercent() {
        let r: CGFloat = 30
        let c = makeCanvas(width: 100, height: 100)
        let square = CGRect(x: 50 - r, y: 50 - r, width: 2 * r, height: 2 * r)
        c.fill(Path.roundedRect(square, cornerRadius: r), color: CGColor.white)
        let expected = Double.pi * Double(r * r)
        let got = coverageSum(c)
        XCTAssertEqual(got, expected, accuracy: expected * 0.005,
                       "circle area \(got) should be within 0.5% of \(expected)")
        // Center must be fully opaque, far corner empty.
        XCTAssertEqual(alpha(c, 50, 50), 255)
        XCTAssertEqual(alpha(c, 2, 2), 0)
    }

    func testCircleEdgePixelsAntialiased() {
        // Horizontal cut through the circle center: the boundary pixel at
        // x = 50 +/- 30 must have partial coverage, neighbors saturated/empty.
        let c = makeCanvas(width: 100, height: 100)
        c.fill(Path.roundedRect(CGRect(x: 20, y: 20, width: 60, height: 60), cornerRadius: 30),
               color: CGColor.white)
        // Circle spans x in [20, 80]; y row 50 (pixel covering y 50..51 near center).
        XCTAssertEqual(alpha(c, 19, 50), 0)
        XCTAssertGreaterThan(alpha(c, 21, 50), 250)
        XCTAssertEqual(alpha(c, 80, 50), 0)
        XCTAssertGreaterThan(alpha(c, 78, 50), 250)
    }

    // MARK: winding rules

    func testNonZeroWindingOverlapStaysOpaque() {
        let c = makeCanvas(width: 30, height: 30)
        var p = Path.rect(CGRect(x: 2, y: 2, width: 20, height: 20))
        p.elements.append(contentsOf: Path.rect(CGRect(x: 10, y: 10, width: 15, height: 15)).elements)
        c.fill(p, color: CGColor.white)  // non-zero: overlap winding 2 -> still 1
        XCTAssertEqual(alpha(c, 15, 15), 255, "overlap region must not exceed or lose coverage")
        XCTAssertEqual(alpha(c, 5, 5), 255)
        XCTAssertEqual(alpha(c, 23, 23), 255)
    }

    func testEvenOddRing() {
        // Border-ring pattern: outer rect + inner rect, even-odd -> hole.
        let c = makeCanvas(width: 40, height: 40)
        var p = Path.rect(CGRect(x: 5, y: 5, width: 30, height: 30))
        p.elements.append(contentsOf: Path.rect(CGRect(x: 10, y: 10, width: 20, height: 20)).elements)
        c.fill(p, color: CGColor.white, evenOdd: true)
        XCTAssertEqual(alpha(c, 7, 20), 255, "ring must be filled")
        XCTAssertEqual(alpha(c, 20, 20), 0, "hole must be empty")
        XCTAssertEqual(alpha(c, 2, 20), 0, "outside must be empty")
        // Ring area = 30*30 - 20*20 = 500 exactly (integer-aligned edges).
        XCTAssertEqual(coverageSum(c), 500, accuracy: 0.5)
    }

    func testEvenOddRingSubpixelInnerEdge() {
        // Inner edge at fractional position: hole edge coverage must be the
        // exact complement of a fill of the inner rect.
        let c = makeCanvas(width: 40, height: 40)
        var p = Path.rect(CGRect(x: 0, y: 0, width: 40, height: 40))
        p.elements.append(contentsOf: Path.rect(CGRect(x: 10.25, y: 10, width: 20, height: 20)).elements)
        c.fill(p, color: CGColor.white, evenOdd: true)
        XCTAssertEqual(alpha(c, 10, 15), Int((0.25 * 255).rounded()),
                       "ring pixel straddling inner edge at x=10.25 covers the left 0.25")
        XCTAssertEqual(alpha(c, 11, 15), 0)
        XCTAssertEqual(alpha(c, 9, 15), 255)
    }

    // MARK: clip

    func testClipIntersection() {
        let c = makeCanvas(width: 40, height: 40)
        c.clip(to: CGRect(x: 0, y: 0, width: 20, height: 40))
        c.clip(to: CGRect(x: 0, y: 0, width: 40, height: 15))
        c.fill(rect: CGRect(x: 0, y: 0, width: 40, height: 40), color: CGColor.white)
        XCTAssertEqual(alpha(c, 10, 10), 255, "inside both clips")
        XCTAssertEqual(alpha(c, 25, 10), 0, "outside first clip")
        XCTAssertEqual(alpha(c, 10, 20), 0, "outside second clip")
        XCTAssertEqual(alpha(c, 25, 20), 0, "outside both")
    }

    func testClipRestoreDiscardsClip() {
        let c = makeCanvas(width: 20, height: 20)
        c.save()
        c.clip(to: CGRect(x: 0, y: 0, width: 5, height: 5))
        c.restore()
        c.fill(rect: CGRect(x: 0, y: 0, width: 20, height: 20), color: CGColor.white)
        XCTAssertEqual(alpha(c, 15, 15), 255)
    }

    func testClipCoverageMatchesFillCoverage() {
        // Rounded-corner clipping of subviews depends on clip coverage being
        // as accurate as fill coverage: clip-to-shape + fill-everything must
        // equal a direct fill of the shape within 1/255 (mask quantization).
        let shape = Path.roundedRect(CGRect(x: 5.3, y: 4.6, width: 28.4, height: 22.9),
                                     cornerRadius: 9)
        let a = makeCanvas(width: 50, height: 40)
        a.fill(shape, color: CGColor.white)
        let b = makeCanvas(width: 50, height: 40)
        b.clip(to: shape)
        b.fill(rect: CGRect(x: -10, y: -10, width: 100, height: 100), color: CGColor.white)
        var maxDiff = 0
        for y in 0..<40 {
            for x in 0..<50 {
                maxDiff = max(maxDiff, abs(alpha(a, x, y) - alpha(b, x, y)))
            }
        }
        XCTAssertLessThanOrEqual(maxDiff, 1, "clip coverage must match fill coverage")
    }

    func testClipSubpixelExactness() {
        let c = makeCanvas(width: 20, height: 20)
        c.clip(to: CGRect(x: 10.25, y: 0, width: 9.75, height: 20))
        c.fill(rect: CGRect(x: 0, y: 0, width: 20, height: 20), color: CGColor.white)
        XCTAssertEqual(alpha(c, 10, 10), Int((0.75 * 255).rounded()))
        XCTAssertEqual(alpha(c, 9, 10), 0)
        XCTAssertEqual(alpha(c, 11, 10), 255)
    }

    func testClipAppliesToImagesAndMasks() {
        let img = Bitmap(width: 2, height: 2)
        for i in 0..<4 {
            img.pixels[i * 4] = 255; img.pixels[i * 4 + 3] = 255  // solid red
        }
        let c = makeCanvas(width: 20, height: 20)
        c.clip(to: CGRect(x: 0, y: 0, width: 10, height: 20))
        c.draw(img, in: CGRect(x: 0, y: 0, width: 20, height: 20))
        XCTAssertEqual(alpha(c, 5, 5), 255)
        XCTAssertEqual(alpha(c, 15, 5), 0, "image must be clipped")

        let d = makeCanvas(width: 20, height: 20)
        d.clip(to: CGRect(x: 0, y: 0, width: 10, height: 20))
        let mask = [UInt8](repeating: 255, count: 16 * 4)
        d.drawMask(mask, width: 16, height: 4, atPixelX: 0, pixelY: 0, color: CGColor.black)
        XCTAssertEqual(alpha(d, 5, 2), 255)
        XCTAssertEqual(alpha(d, 15, 2), 0, "mask must be clipped")
    }

    // MARK: transparency layers

    func testTransparencyLayerNesting() {
        let c = makeCanvas(width: 10, height: 10)
        c.beginTransparencyLayer(alpha: 0.5)
        c.beginTransparencyLayer(alpha: 0.5)
        c.fill(rect: CGRect(x: 0, y: 0, width: 10, height: 10),
               color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        c.endTransparencyLayer()
        c.endTransparencyLayer()
        // Effective alpha 0.25; color stays pure red (straight alpha).
        let px = rgba(c, 5, 5)
        XCTAssertEqual(px[0], 255)
        XCTAssertEqual(px[3], Int((0.25 * 255).rounded()))
    }

    func testTransparencyLayerGroupsBeforeFading() {
        // Overlapping opaque fills inside a 0.5-alpha layer must composite
        // first (as a group), then fade: result is 0.5 blue over white, NOT
        // 0.5 red + 0.5 blue stacked.
        let c = makeCanvas(width: 10, height: 10)
        c.fill(rect: CGRect(x: 0, y: 0, width: 10, height: 10), color: CGColor.white)
        c.beginTransparencyLayer(alpha: 0.5)
        c.fill(rect: CGRect(x: 0, y: 0, width: 10, height: 10),
               color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        c.fill(rect: CGRect(x: 0, y: 0, width: 10, height: 10),
               color: CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        c.endTransparencyLayer()
        let px = rgba(c, 5, 5)
        XCTAssertEqual(px[0], 128, accuracy: 1)  // 0.5*0 + 0.5*255
        XCTAssertEqual(px[1], 128, accuracy: 1)
        XCTAssertEqual(px[2], 255)               // 0.5*255 + 0.5*255
        XCTAssertEqual(px[3], 255)
    }

    func testTransparencyLayerRespectsClipAndBalancesState() {
        let c = makeCanvas(width: 20, height: 20)
        c.clip(to: CGRect(x: 0, y: 0, width: 10, height: 20))
        c.beginTransparencyLayer(alpha: 1)
        c.save()  // deliberately unbalanced inside the layer
        c.fill(rect: CGRect(x: 0, y: 0, width: 20, height: 20), color: CGColor.white)
        c.endTransparencyLayer()
        XCTAssertEqual(alpha(c, 5, 5), 255)
        XCTAssertEqual(alpha(c, 15, 5), 0, "clip active inside layer")
    }

    // MARK: image drawing

    func testBilinearSamplingKnown2x2() {
        // 2x2 image: left column value 0, right column 200 (opaque).
        let img = Bitmap(width: 2, height: 2)
        for (i, v) in [0, 200, 0, 200].enumerated() {
            img.pixels[i * 4] = UInt8(v)
            img.pixels[i * 4 + 3] = 255
        }
        let c = makeCanvas(width: 4, height: 4)
        c.draw(img, in: CGRect(x: 0, y: 0, width: 4, height: 4), interpolate: true)
        // Dest pixel centers x+0.5 map to source fx = (x+0.5)/4*2 - 0.5:
        // x=0 -> fx=-0.25 (clamped left)   -> 0
        // x=1 -> fx= 0.25 -> 0.75*0 + 0.25*200 = 50
        // x=2 -> fx= 0.75 -> 0.25*0 + 0.75*200 = 150
        // x=3 -> fx= 1.25 (clamped right)  -> 200
        XCTAssertEqual(rgba(c, 0, 1)[0], 0)
        XCTAssertEqual(rgba(c, 1, 1)[0], 50)
        XCTAssertEqual(rgba(c, 2, 1)[0], 150)
        XCTAssertEqual(rgba(c, 3, 1)[0], 200)
        for x in 0..<4 { XCTAssertEqual(alpha(c, x, 1), 255) }
    }

    func testNearestSampling() {
        let img = Bitmap(width: 2, height: 2)
        for (i, v) in [10, 240, 10, 240].enumerated() {
            img.pixels[i * 4] = UInt8(v)
            img.pixels[i * 4 + 3] = 255
        }
        let c = makeCanvas(width: 4, height: 4)
        c.draw(img, in: CGRect(x: 0, y: 0, width: 4, height: 4), interpolate: false)
        XCTAssertEqual(rgba(c, 0, 0)[0], 10)
        XCTAssertEqual(rgba(c, 1, 0)[0], 10)
        XCTAssertEqual(rgba(c, 2, 0)[0], 240)
        XCTAssertEqual(rgba(c, 3, 0)[0], 240)
    }

    func testImageEdgeCoverageFractionalRect() {
        // Image drawn into a fractional rect gets analytic edge coverage.
        let img = Bitmap(width: 1, height: 1)
        img.pixels = [255, 255, 255, 255]
        let c = makeCanvas(width: 10, height: 10)
        c.draw(img, in: CGRect(x: 2.5, y: 2, width: 3, height: 3))
        XCTAssertEqual(alpha(c, 2, 3), 128, accuracy: 1, "half-covered edge pixel")
        XCTAssertEqual(alpha(c, 3, 3), 255)
        XCTAssertEqual(alpha(c, 5, 3), 128, accuracy: 1)
        XCTAssertEqual(alpha(c, 1, 3), 0)
    }

    func testImageRespectsCTMScale() {
        // Canvas at 2x device scale: a 2x2 image drawn in a 2x2 point rect
        // covers 4x4 device pixels, scaled up with interpolation.
        let img = Bitmap(width: 2, height: 2)
        for (i, v) in [0, 100, 0, 100].enumerated() {
            img.pixels[i * 4] = UInt8(v)
            img.pixels[i * 4 + 3] = 255
        }
        let c = makeCanvas(width: 4, height: 4, scale: 2)
        c.draw(img, in: CGRect(x: 0, y: 0, width: 2, height: 2), interpolate: true)
        for y in 0..<4 {
            for x in 0..<4 { XCTAssertEqual(alpha(c, x, y), 255) }
        }
        // Same mapping as the 4x4 test: 0, 25, 75, 100.
        XCTAssertEqual(rgba(c, 0, 2)[0], 0)
        XCTAssertEqual(rgba(c, 1, 2)[0], 25)
        XCTAssertEqual(rgba(c, 2, 2)[0], 75)
        XCTAssertEqual(rgba(c, 3, 2)[0], 100)
    }

    // MARK: mask drawing

    func testDrawMaskTint() {
        let c = makeCanvas(width: 10, height: 10)
        let mask: [UInt8] = [0, 128, 255, 64]
        c.drawMask(mask, width: 2, height: 2, atPixelX: 3, pixelY: 4,
                   color: CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        XCTAssertEqual(alpha(c, 3, 4), 0)
        XCTAssertEqual(alpha(c, 4, 4), 128)
        XCTAssertEqual(alpha(c, 3, 5), 255)
        XCTAssertEqual(alpha(c, 4, 5), 64)
        XCTAssertEqual(rgba(c, 3, 5)[2], 255, "tint color applied")
    }

    // MARK: stroke

    func testStrokeBasicLine() {
        let c = makeCanvas(width: 40, height: 20)
        var p = Path()
        p.move(to: CGPoint(x: 5, y: 10))
        p.addLine(to: CGPoint(x: 35, y: 10))
        c.stroke(p, color: CGColor.white, lineWidth: 4)
        // 4-wide horizontal band centered at y=10: rows 8..11 full.
        XCTAssertEqual(alpha(c, 20, 9), 255)
        XCTAssertEqual(alpha(c, 20, 10), 255)
        XCTAssertEqual(alpha(c, 20, 7), 0)
        XCTAssertEqual(alpha(c, 20, 12), 0)
        // Butt caps: nothing before x=5 or after x=35.
        XCTAssertEqual(alpha(c, 3, 10), 0)
        XCTAssertEqual(alpha(c, 37, 10), 0)
    }

    func testStrokeJointHasNoSeamOrDoubleBlend() {
        // An L-shaped semi-transparent stroke: the joint region must blend
        // exactly once (no darker overlap seam).
        let c = makeCanvas(width: 40, height: 40)
        var p = Path()
        p.move(to: CGPoint(x: 5, y: 30))
        p.addLine(to: CGPoint(x: 30, y: 30))
        p.addLine(to: CGPoint(x: 30, y: 5))
        c.stroke(p, color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.5), lineWidth: 6)
        let mid = alpha(c, 15, 30)      // straight run
        let joint = alpha(c, 30, 30)    // corner overlap
        XCTAssertEqual(mid, 128, accuracy: 1)
        XCTAssertEqual(joint, 128, accuracy: 1, "joint must not double-blend")
    }

    // MARK: rounded-rect quality vs analytic expectations

    func testRoundedRectEdgePixelCoverageMatchesAnalytic() {
        // A rounded rect's straight edges are exact; check a straight-edge
        // pixel and the interior against analytic values.
        let c = makeCanvas(width: 60, height: 60, scale: 2)
        // 20x20 points at (5.125, 5), radius 4 -> device (10.25, 10, 40, 40).
        c.fill(Path.roundedRect(CGRect(x: 5.125, y: 5, width: 20, height: 20), cornerRadius: 4),
               color: CGColor.white)
        XCTAssertEqual(alpha(c, 10, 30), Int((0.75 * 255).rounded()),
                       "straight edge keeps exact subpixel coverage")
        XCTAssertEqual(alpha(c, 30, 30), 255)
        XCTAssertEqual(alpha(c, 9, 30), 0)
    }

    // MARK: performance

    func testFillPerformanceBudget() {
        // ~400 rounded-rect fills + circles on a 700x500 (device px at 2x ->
        // 1400x1000) canvas must finish well within the suite budget even in
        // debug builds. This is a smoke test, not a benchmark.
        let c = makeCanvas(width: 1400, height: 1000, scale: 2)
        let start = Date()
        for i in 0..<300 {
            let x = CGFloat((i * 37) % 600), y = CGFloat((i * 53) % 400)
            c.fill(Path.roundedRect(CGRect(x: x, y: y, width: 90, height: 70), cornerRadius: 12),
                   color: CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.8))
        }
        for i in 0..<100 {
            let x = CGFloat((i * 61) % 600), y = CGFloat((i * 41) % 400)
            c.fill(Path.roundedRect(CGRect(x: x, y: y, width: 60, height: 60), cornerRadius: 30),
                   color: CGColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 0.6))
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 10.0, "400 large AA fills took \(elapsed)s")
    }

    // MARK: transforms

    func testFillUnderTranslationAndScale() {
        let c = makeCanvas(width: 40, height: 40, scale: 2)
        c.save()
        c.translate(x: 5, y: 5)
        c.concatenate(CGAffineTransform(scaleX: 2, y: 2))
        // Rect (0,0,5,5) under translate(5,5), scale(2) at device scale 2:
        // device rect = (10, 10, 20, 20).
        c.fill(rect: CGRect(x: 0, y: 0, width: 5, height: 5), color: CGColor.white)
        c.restore()
        XCTAssertEqual(alpha(c, 9, 15), 0)
        XCTAssertEqual(alpha(c, 10, 15), 255)
        XCTAssertEqual(alpha(c, 29, 15), 255)
        XCTAssertEqual(alpha(c, 30, 15), 0)
    }

    func testRotatedFillCoverageSum() {
        // A rotated square keeps its area (AA coverage sums to area).
        let c = makeCanvas(width: 100, height: 100)
        c.translate(x: 50, y: 50)
        c.concatenate(CGAffineTransform(rotationAngle: 0.5))
        c.fill(rect: CGRect(x: -15, y: -15, width: 30, height: 30), color: CGColor.white)
        XCTAssertEqual(coverageSum(c), 900, accuracy: 900 * 0.005)
    }
}
