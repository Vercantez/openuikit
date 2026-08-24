// Tests for scene-spec v2 effects: layer shadows + UIGradientView.
// Owner: view module (RenderPass/UIView/UIGradientView + Canvas additive ops).
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect
private typealias CGColor = OpenUIKit.CGColor

final class ShadowGradientTests: XCTestCase {

    private var savedBackend: RenderBackend = CanvasBackendSelection.current
    override func setUp() {
        super.setUp()
        savedBackend = CanvasBackendSelection.current
    }
    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        super.tearDown()
    }

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
        let o = (y * b.width + x) * 4
        return (Int(b.pixels[o]), Int(b.pixels[o + 1]), Int(b.pixels[o + 2]), Int(b.pixels[o + 3]))
    }

    // MARK: CALayer facade

    func testShadowDefaultsMatchCALayer() {
        let v = UIView()
        XCTAssertEqual(v.layer.shadowOpacity, 0)
        XCTAssertEqual(v.layer.shadowRadius, 3)
        XCTAssertEqual(v.layer.shadowOffset, CGSize(width: 0, height: -3))
        let c = try? XCTUnwrap(v.layer.shadowColor)
        XCTAssertEqual(c, CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    }

    // MARK: Shadow rendering

    /// White box on a white backdrop, hard shadow (radius 0) offset (4,4):
    /// darkening appears right+below the box only, beneath the box content.
    private func renderHardShadowScene() -> Bitmap {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let backdrop = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        backdrop.backgroundColor = .white
        root.addSubview(backdrop)
        let box = UIView(frame: CGRect(x: 20, y: 20, width: 20, height: 20))
        box.backgroundColor = .white
        box.layer.shadowOpacity = 1
        box.layer.shadowRadius = 0
        box.layer.shadowOffset = CGSize(width: 4, height: 4)
        root.addSubview(box)
        return UIRenderer.render(root, scale: 1)
    }

    func testHardShadowFallsRightAndBelow() {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bmp = renderHardShadowScene()
            // Box covers 20..40; shadow (offset +4) peeks out over 40..44.
            XCTAssertEqual(px(bmp, 42, 30).r, 0, "\(backend): shadow right of box")
            XCTAssertEqual(px(bmp, 30, 42).r, 0, "\(backend): shadow below box")
            // Box content covers its own shadow region.
            XCTAssertEqual(px(bmp, 30, 30).r, 255, "\(backend): box stays white")
            // No shadow up/left (offset moves it away).
            XCTAssertEqual(px(bmp, 18, 30).r, 255, "\(backend): no shadow left")
            XCTAssertEqual(px(bmp, 30, 18).r, 255, "\(backend): no shadow above")
        }
    }

    func testShadowHiddenByMasksToBounds() {
        CanvasBackendSelection.current = .swift
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let backdrop = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        backdrop.backgroundColor = .white
        root.addSubview(backdrop)
        let box = UIView(frame: CGRect(x: 20, y: 20, width: 20, height: 20))
        box.backgroundColor = .white
        box.layer.shadowOpacity = 1
        box.layer.shadowRadius = 0
        box.layer.shadowOffset = CGSize(width: 4, height: 4)
        box.clipsToBounds = true
        root.addSubview(box)
        let bmp = UIRenderer.render(root, scale: 1)
        XCTAssertEqual(px(bmp, 42, 30).r, 255, "masksToBounds suppresses the shadow")
    }

    /// Both backends draw shadows with the same silhouette/blur pipeline;
    /// a blurred shadow must agree closely between them.
    func testShadowBackendParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        let backdrop = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        backdrop.backgroundColor = .white
        root.addSubview(backdrop)
        // Pixel-aligned box (no cornerRadius): rounded-corner AA differs
        // between backends by design (documented divergence) — this test
        // isolates the shadow blur pipeline, which must match.
        let box = UIView(frame: CGRect(x: 25, y: 25, width: 30, height: 30))
        box.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        box.layer.shadowOpacity = 0.6
        box.layer.shadowRadius = 5
        box.layer.shadowOffset = CGSize(width: 0, height: 3)
        root.addSubview(box)

        CanvasBackendSelection.current = .swift
        let a = UIRenderer.render(root, scale: 2)
        CanvasBackendSelection.current = .quartz
        let b = UIRenderer.render(root, scale: 2)
        var maxDelta = 0
        for i in 0..<a.pixels.count {
            maxDelta = max(maxDelta, abs(Int(a.pixels[i]) - Int(b.pixels[i])))
        }
        XCTAssertLessThanOrEqual(maxDelta, 3, "backend shadow outputs diverge")
    }

    /// Canvas shadow state obeys save/restore (behavioral check: a fill
    /// after restore() must not cast a shadow).
    func testCanvasShadowStateSemantics() {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bmp = Bitmap(width: 40, height: 40)
            let canvas = Canvas(bitmap: bmp, scale: 1)
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 40, height: 40), color: .white)
            canvas.save()
            canvas.setShadow(color: .black, offset: CGSize(width: 4, height: 4), blur: 0)
            canvas.restore()
            canvas.fill(rect: CGRect(x: 10, y: 10, width: 10, height: 10), color: .white)
            XCTAssertEqual(px(bmp, 22, 15).r, 255,
                           "\(backend): restore() must pop the shadow")
            canvas.setShadow(color: .black, offset: CGSize(width: 4, height: 4), blur: 0)
            canvas.clearShadow()
            canvas.fill(rect: CGRect(x: 10, y: 25, width: 10, height: 10), color: .white)
            XCTAssertEqual(px(bmp, 22, 30).r, 255,
                           "\(backend): clearShadow() must remove the shadow")
        }
    }

    // MARK: Gradients

    func testGradientViewDefaults() {
        let g = UIGradientView()
        XCTAssertEqual(g.startPoint, CGPoint(x: 0.5, y: 0))
        XCTAssertEqual(g.endPoint, CGPoint(x: 0.5, y: 1))
        XCTAssertNil(g.locations)
    }

    /// Black→white vertical gradient: endpoints match the stop colors and
    /// the CA interpolation midpoint sits well ABOVE the plain sRGB lerp
    /// (gamma-1.8 interpolation space — calibrated against the oracle).
    func testGradientEndpointsAndMidpoint() {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 100))
            let g = UIGradientView(frame: CGRect(x: 0, y: 0, width: 20, height: 100))
            g.colors = [.black, .white]
            root.addSubview(g)
            let bmp = UIRenderer.render(root, scale: 1)
            XCTAssertLessThanOrEqual(px(bmp, 10, 0).r, 4, "\(backend): top ≈ black")
            XCTAssertGreaterThanOrEqual(px(bmp, 10, 99).r, 251, "\(backend): bottom ≈ white")
            let mid = px(bmp, 10, 50).r
            // Golden midpoint for black→white is ≈146 (plain sRGB lerp: 128).
            XCTAssertGreaterThanOrEqual(mid, 140, "\(backend): CA-space midpoint")
            XCTAssertLessThanOrEqual(mid, 152, "\(backend): CA-space midpoint")
        }
    }

    /// startPoint/endPoint act in the UNIT space of bounds: on a non-square
    /// view, a (0,0)→(1,1) gradient is constant along the unit-space
    /// anti-diagonal direction, not the point-space one.
    func testGradientDiagonalUsesUnitSpace() {
        CanvasBackendSelection.current = .swift
        let w = 40, h = 80
        let root = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
        let g = UIGradientView(frame: root.frame)
        g.colors = [.black, .white]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        root.addSubview(g)
        let bmp = UIRenderer.render(root, scale: 1)
        // Same unit-space t=(u+v)/2: (30,20) → u=.7625,v=.25625; (10,60) → u=.2625,v=.75625.
        let a = px(bmp, 30, 20).r
        let b = px(bmp, 10, 60).r
        XCTAssertLessThanOrEqual(abs(a - b), 3, "equal unit-space t must render equal")
        // Point-space projection would separate these two samples strongly.
        let c = px(bmp, 30, 60).r
        XCTAssertGreaterThan(c - a, 20, "gradient must still progress along the axis")
    }

    /// Locations pin the stops: [0, 0.2, 1] black→white→black puts white at
    /// 20% of the height.
    func testGradientLocations() {
        CanvasBackendSelection.current = .quartz
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 100))
        let g = UIGradientView(frame: root.frame)
        g.colors = [.black, .white, .black]
        g.locations = [0, 0.2, 1]
        root.addSubview(g)
        let bmp = UIRenderer.render(root, scale: 1)
        // Pixel centers sample at t = (y+0.5)/100, so row 0 is not exactly
        // the stop color (t=0.005 of a 0→0.2 ramp in gamma-1.8 space ≈ 7).
        XCTAssertGreaterThanOrEqual(px(bmp, 5, 20).r, 250, "white stop at 20%")
        XCTAssertLessThanOrEqual(px(bmp, 5, 0).r, 12)
        XCTAssertLessThanOrEqual(px(bmp, 5, 99).r, 12)
    }

    /// The calibrated CA interpolation space round-trips stop colors.
    func testCAGradientColorSpaceRoundTrip() {
        let colors: [CGColor] = [
            CGColor(red: 0.88, green: 0.19, blue: 0.19, alpha: 1),
            CGColor(red: 0.10, green: 0.44, blue: 0.76, alpha: 1),
            CGColor(red: 0, green: 0, blue: 0, alpha: 1),
            CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        ]
        for c in colors {
            let (r, g, b) = _CAGradientColorSpace.encode(c)
            let back = _CAGradientColorSpace.decode(r, g, b, alpha: c.alpha)
            XCTAssertEqual(back.red, c.red, accuracy: 0.004)
            XCTAssertEqual(back.green, c.green, accuracy: 0.004)
            XCTAssertEqual(back.blue, c.blue, accuracy: 0.004)
        }
    }

    /// Gradient backends agree (both consume the same densified stops).
    func testGradientBackendParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        let g = UIGradientView(frame: root.frame)
        g.colors = [UIColor(red: 0.95, green: 0.4, blue: 0.03, alpha: 1),
                    UIColor(red: 0.52, green: 0.37, blue: 0.97, alpha: 1)]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        root.addSubview(g)
        CanvasBackendSelection.current = .swift
        let a = UIRenderer.render(root, scale: 2)
        CanvasBackendSelection.current = .quartz
        let b = UIRenderer.render(root, scale: 2)
        var maxDelta = 0
        for i in 0..<a.pixels.count {
            maxDelta = max(maxDelta, abs(Int(a.pixels[i]) - Int(b.pixels[i])))
        }
        XCTAssertLessThanOrEqual(maxDelta, 2, "backend gradient outputs diverge")
    }
}
