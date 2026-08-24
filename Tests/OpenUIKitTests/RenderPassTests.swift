// View-module tests: render-pass smoke tests over the naive rasterizer.
// Interior pixels are sampled away from anti-aliased edges.
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect
private typealias CGAffineTransform = OpenUIKit.CGAffineTransform
private typealias CGColor = OpenUIKit.CGColor

final class RenderPassTests: XCTestCase {

    // MARK: helpers

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
        let o = (y * b.width + x) * 4
        return (Int(b.pixels[o]), Int(b.pixels[o + 1]), Int(b.pixels[o + 2]), Int(b.pixels[o + 3]))
    }

    private func assertPixel(_ bmp: Bitmap, _ x: Int, _ y: Int,
                             _ expected: (Int, Int, Int, Int), tolerance: Int = 2,
                             file: StaticString = #filePath, line: UInt = #line) {
        let p = px(bmp, x, y)
        for (got, want) in [(p.r, expected.0), (p.g, expected.1), (p.b, expected.2), (p.a, expected.3)] {
            XCTAssertLessThanOrEqual(abs(got - want), tolerance,
                                     "pixel (\(x),\(y)) = \(p), expected \(expected)",
                                     file: file, line: line)
        }
    }

    private let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    private let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

    private func makeRoot(_ w: CGFloat, _ h: CGFloat, bg: UIColor?) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        v.backgroundColor = bg
        return v
    }

    // MARK: basics

    func testBackgroundFillCoversBounds() {
        let root = makeRoot(20, 20, bg: red)
        let bmp = UIRenderer.render(root, scale: 1)
        XCTAssertEqual(bmp.width, 20)
        XCTAssertEqual(bmp.height, 20)
        assertPixel(bmp, 10, 10, (255, 0, 0, 255))
        assertPixel(bmp, 0, 0, (255, 0, 0, 255))
        assertPixel(bmp, 19, 19, (255, 0, 0, 255))
    }

    func testScaleMapsPointsToPixels() {
        let root = makeRoot(10, 10, bg: red)
        let child = UIView(frame: CGRect(x: 5, y: 0, width: 5, height: 10))
        child.backgroundColor = blue
        root.addSubview(child)
        let bmp = UIRenderer.render(root, scale: 2)
        XCTAssertEqual(bmp.width, 20)
        assertPixel(bmp, 4, 10, (255, 0, 0, 255))   // left half red
        assertPixel(bmp, 15, 10, (0, 0, 255, 255))  // right half blue
    }

    func testNilBackgroundIsTransparent() {
        let root = makeRoot(10, 10, bg: nil)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 5, 5, (0, 0, 0, 0))
    }

    func testSubviewsRenderInArrayOrder() {
        let root = makeRoot(40, 40, bg: white)
        let a = UIView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        a.backgroundColor = blue
        let b = UIView(frame: CGRect(x: 15, y: 15, width: 10, height: 10))
        b.backgroundColor = green
        root.addSubview(a)
        root.addSubview(b)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 20, 20, (0, 255, 0, 255))  // later sibling on top
        assertPixel(bmp, 8, 8, (0, 0, 255, 255))
        assertPixel(bmp, 2, 2, (255, 255, 255, 255))

        root.sendSubviewToBack(b)
        let bmp2 = UIRenderer.render(root, scale: 1)
        assertPixel(bmp2, 20, 20, (0, 0, 255, 255))  // now covered by a
    }

    func testHiddenSkipsEntireSubtree() {
        let root = makeRoot(20, 20, bg: white)
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        parent.isHidden = true
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        child.backgroundColor = red
        parent.addSubview(child)
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 10, 10, (255, 255, 255, 255))
    }

    func testZeroAlphaSkipsSubtree() {
        let root = makeRoot(20, 20, bg: white)
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        parent.alpha = 0
        parent.backgroundColor = red
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 10, 10, (255, 255, 255, 255))
    }

    // MARK: clipping

    func testClipsToBoundsClipsSubviews() {
        let root = makeRoot(40, 40, bg: white)
        let parent = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        parent.backgroundColor = blue
        parent.clipsToBounds = true
        let child = UIView(frame: CGRect(x: -10, y: -10, width: 40, height: 40))
        child.backgroundColor = red
        parent.addSubview(child)
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 20, 20, (255, 0, 0, 255))      // inside parent: child visible
        assertPixel(bmp, 5, 5, (255, 255, 255, 255))    // outside parent: clipped
        assertPixel(bmp, 35, 35, (255, 255, 255, 255))
    }

    func testNoClipLetsSubviewsEscapeBounds() {
        let root = makeRoot(40, 40, bg: white)
        let parent = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        parent.backgroundColor = blue
        let child = UIView(frame: CGRect(x: -10, y: -10, width: 40, height: 40))
        child.backgroundColor = red
        parent.addSubview(child)
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 5, 5, (255, 0, 0, 255))  // escapes: not clipped
    }

    func testCornerRadiusClipsBackgroundContentAndSubviews() {
        let root = makeRoot(24, 24, bg: white)
        let parent = UIView(frame: CGRect(x: 2, y: 2, width: 20, height: 20))
        parent.backgroundColor = blue
        parent.layer.cornerRadius = 8
        parent.clipsToBounds = true
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        child.backgroundColor = red
        parent.addSubview(child)
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        // Corner pixel of the parent (root (3,3)) is outside the rounded
        // corner (distance from corner-circle center > radius) → white.
        assertPixel(bmp, 3, 3, (255, 255, 255, 255))
        // Interior is the child, clipped in.
        assertPixel(bmp, 12, 12, (255, 0, 0, 255))
        // Edge midpoints are inside the rounded rect.
        assertPixel(bmp, 12, 4, (255, 0, 0, 255))
    }

    func testRoundedBackgroundWithoutClipStillRounded() {
        let root = makeRoot(24, 24, bg: white)
        let v = UIView(frame: CGRect(x: 2, y: 2, width: 20, height: 20))
        v.backgroundColor = blue
        v.layer.cornerRadius = 10
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 3, 3, (255, 255, 255, 255))   // outside round corner
        assertPixel(bmp, 12, 12, (0, 0, 255, 255))     // center
    }

    // MARK: border

    func testBorderDrawsAboveSubviews() {
        let root = makeRoot(20, 20, bg: white)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        v.backgroundColor = white
        v.layer.borderWidth = 3
        v.layer.borderColor = CGColor.black
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        child.backgroundColor = red
        v.addSubview(child)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 1, 10, (0, 0, 0, 255))     // ring, above the child
        assertPixel(bmp, 10, 1, (0, 0, 0, 255))
        assertPixel(bmp, 10, 10, (255, 0, 0, 255))  // interior: child, not border
    }

    func testBorderRingDoesNotFillInterior() {
        let root = makeRoot(20, 20, bg: nil)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        v.backgroundColor = white
        v.layer.borderWidth = 2
        v.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 10, 10, (255, 255, 255, 255))  // interior untouched
        assertPixel(bmp, 0, 10, (0, 0, 0, 255))         // ring
        assertPixel(bmp, 19, 10, (0, 0, 0, 255))
    }

    func testWideBorderConsumesWholeBounds() {
        let root = makeRoot(10, 10, bg: nil)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.backgroundColor = white
        v.layer.borderWidth = 6  // 2*6 > 10 → no interior left
        v.layer.borderColor = CGColor.black
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 5, 5, (0, 0, 0, 255))
    }

    func testDefaultZeroBorderWidthDrawsNoBorder() {
        let root = makeRoot(10, 10, bg: red)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 0, 5, (255, 0, 0, 255))
    }

    // MARK: alpha grouping

    func testAlphaGroupsWholeSubtree() {
        // parent alpha 0.5 with two stacked opaque children: the subtree
        // composites first (blue wins), THEN fades as a unit over white.
        let root = makeRoot(20, 20, bg: white)
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        parent.alpha = 0.5
        let c1 = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        c1.backgroundColor = red
        let c2 = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        c2.backgroundColor = blue
        parent.addSubview(c1)
        parent.addSubview(c2)
        root.addSubview(parent)
        let bmp = UIRenderer.render(root, scale: 1)
        // 0.5*blue + 0.5*white = (128, 128, 255). If alpha were applied
        // per-child instead, the result would be (128, 64, 191).
        assertPixel(bmp, 10, 10, (128, 128, 255, 255))
    }

    func testAlphaGroupsBorderToo() {
        let root = makeRoot(20, 20, bg: white)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        v.alpha = 0.5
        v.backgroundColor = black
        v.layer.borderWidth = 4
        v.layer.borderColor = CGColor.black
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        // Border over background inside one layer: still 50% black over white,
        // NOT 0.5-black over 0.5-black.
        assertPixel(bmp, 1, 10, (128, 128, 128, 255))
        assertPixel(bmp, 10, 10, (128, 128, 128, 255))
    }

    // MARK: drawContent ordering

    private final class ContentView: UIView {
        override func drawContent(in canvas: Canvas, bounds: CGRect) {
            // Deliberately larger than bounds to verify masksToBounds clips
            // the layer's own content too.
            canvas.fill(rect: CGRect(x: -10, y: -10,
                                     width: bounds.width + 20, height: bounds.height + 20),
                        color: CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        }
    }

    func testContentDrawsAboveBackgroundBelowSubviews() {
        let root = makeRoot(30, 30, bg: white)
        let v = ContentView(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
        v.backgroundColor = red
        v.clipsToBounds = true
        let child = UIView(frame: CGRect(x: 5, y: 5, width: 10, height: 10))
        child.backgroundColor = blue
        v.addSubview(child)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 7, 7, (0, 255, 0, 255))    // content over background
        assertPixel(bmp, 15, 15, (0, 0, 255, 255))  // subview over content
        assertPixel(bmp, 2, 2, (255, 255, 255, 255)) // content clipped to bounds
    }

    // MARK: transforms

    func testTranslationTransformMovesSubview() {
        let root = makeRoot(40, 40, bg: white)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.backgroundColor = green
        v.transform = CGAffineTransform(translationX: 20, y: 10)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 25, 15, (0, 255, 0, 255))
        assertPixel(bmp, 5, 5, (255, 255, 255, 255))
    }

    func testScaleTransformAboutCenter() {
        let root = makeRoot(40, 40, bg: white)
        let v = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
        v.backgroundColor = red
        v.transform = CGAffineTransform(scaleX: 2, y: 2)
        root.addSubview(v)
        // center (15,15), scaled size 20 → covers (5,5)-(25,25).
        let bmp = UIRenderer.render(root, scale: 1)
        assertPixel(bmp, 6, 6, (255, 0, 0, 255))
        assertPixel(bmp, 24, 24, (255, 0, 0, 255))
        assertPixel(bmp, 3, 3, (255, 255, 255, 255))
        assertPixel(bmp, 27, 27, (255, 255, 255, 255))
    }

    func testRotatedFillHasHardEdges() {
        // UIKit does not anti-alias edges of rotated layers: every pixel must
        // be either fully background or fully the fill color — no blends.
        let root = makeRoot(60, 60, bg: nil)
        let v = UIView(frame: CGRect(x: 15, y: 20, width: 30, height: 20))
        v.backgroundColor = red
        v.transform = CGAffineTransform(rotationAngle: .pi / 4)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        var alphas = Set<Int>()
        var reds = 0
        for y in 0..<bmp.height {
            for x in 0..<bmp.width {
                let p = px(bmp, x, y)
                alphas.insert(p.a)
                if p.a == 255 {
                    XCTAssertEqual(p.r, 255)
                    XCTAssertEqual(p.g, 0)
                    XCTAssertEqual(p.b, 0)
                    reds += 1
                }
            }
        }
        XCTAssertEqual(alphas, Set([0, 255]), "rotated edges must be hard (0/255 only)")
        // Area sanity: rotated 30x20 rect covers ~600 px.
        XCTAssertGreaterThan(reds, 500)
        XCTAssertLessThan(reds, 700)
        // Center of the view is filled.
        assertPixel(bmp, 30, 30, (255, 0, 0, 255))
    }

    func testScaledBorderHasHardEdges() {
        let root = makeRoot(60, 60, bg: nil)
        let v = UIView(frame: CGRect(x: 20, y: 20, width: 20, height: 20))
        v.layer.borderWidth = 4
        v.layer.borderColor = CGColor.black
        v.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        var alphas = Set<Int>()
        for y in 0..<bmp.height {
            for x in 0..<bmp.width {
                alphas.insert(px(bmp, x, y).a)
            }
        }
        XCTAssertEqual(alphas, Set([0, 255]), "scaled border edges must be hard")
        // Scaled bounds cover (15,15)-(45,45), border 4pt scaled to 6px.
        assertPixel(bmp, 17, 30, (0, 0, 0, 255))       // within ring
        assertPixel(bmp, 30, 30, (0, 0, 0, 0))         // interior empty
    }

    func testAxisAlignedFillKeepsAntialiasedFractionalEdge() {
        // Non-transformed fractional edge SHOULD get coverage AA (contrast
        // with the rotated case above).
        let root = makeRoot(10, 10, bg: nil)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 5.5, height: 10))
        v.backgroundColor = red
        root.addSubview(v)
        let bmp = UIRenderer.render(root, scale: 1)
        let edge = px(bmp, 5, 5)  // pixel column 5 is half covered
        XCTAssertGreaterThan(edge.a, 60)
        XCTAssertLessThan(edge.a, 200)
    }
}
