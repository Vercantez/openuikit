// View-module tests: LayerBridge (M5 QZLayer compositor) — geometry
// mapping, content extents, and cross-compositor parity against the
// hand-written render pass.
import XCTest
@testable import OpenUIKit

private typealias CGAffineTransform = OpenUIKit.CGAffineTransform

final class LayerBridgeTests: XCTestCase {

    private var savedCompositor: RenderCompositor!
    private var savedBackend: RenderBackend!

    override func setUp() {
        super.setUp()
        savedCompositor = OpenUIKitRuntime.compositor
        savedBackend = OpenUIKitRuntime.renderBackend
        OpenUIKitRuntime.renderBackend = .quartz
    }

    override func tearDown() {
        OpenUIKitRuntime.compositor = savedCompositor
        OpenUIKitRuntime.renderBackend = savedBackend
        super.tearDown()
    }

    private let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

    private func maxChannelDiff(_ a: Bitmap, _ b: Bitmap) -> Int {
        precondition(a.width == b.width && a.height == b.height)
        var worst = 0
        for i in 0..<a.pixels.count {
            worst = max(worst, abs(Int(a.pixels[i]) - Int(b.pixels[i])))
        }
        return worst
    }

    private func meanAbsDiff(_ a: Bitmap, _ b: Bitmap) -> Double {
        var total = 0
        for i in 0..<a.pixels.count {
            total += abs(Int(a.pixels[i]) - Int(b.pixels[i]))
        }
        return Double(total) / Double(a.pixels.count)
    }

    /// Renders `root` through both compositors on the quartz backend.
    private func bothCompositors(_ root: UIView, scale: CGFloat) -> (layers: Bitmap, pass: Bitmap) {
        root.layoutIfNeeded()
        let layers = LayerBridge.render(root, scale: scale)
        let pass = UIRenderer.renderPassRender(root, scale: scale)
        return (layers, pass)
    }

    // MARK: geometry mapping

    func testSnapOutSnapsToDeviceGrid() {
        let r = LayerBridge.snapOut(CGRect(x: 1.3, y: -0.2, width: 4.1, height: 2.0),
                                    scale: 2)
        XCTAssertEqual(r.minX, 1.0)
        XCTAssertEqual(r.minY, -0.5)
        XCTAssertEqual(r.maxX, 5.5)
        XCTAssertEqual(r.maxY, 2.0)
    }

    func testContentExtentPlainContainersHaveNone() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        XCTAssertNil(LayerBridge.contentExtent(of: v, scale: 2))
        let s = UIStackView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        XCTAssertNil(LayerBridge.contentExtent(of: s, scale: 2))
    }

    func testContentExtentLabelPadsBounds() {
        let l = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        l.text = "Hi"
        let e = LayerBridge.contentExtent(of: l, scale: 2)
        XCTAssertNotNil(e)
        XCTAssertEqual(e!, CGRect(x: -2, y: -2, width: 44, height: 24))
    }

    func testContentExtentImageOverflowsBoundsForCenterMode() {
        let bmp = Bitmap(width: 40, height: 40) // 20x20 points at scale 2
        let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        iv.image = UIImage(bitmap: bmp, scale: 2)
        iv.contentMode = .center
        let e = LayerBridge.contentExtent(of: iv, scale: 2)
        XCTAssertNotNil(e)
        // 20x20 image centered in 10x10 bounds -> extends 5pt past each edge.
        XCTAssertEqual(e!, CGRect(x: -5, y: -5, width: 20, height: 20))
    }

    // MARK: compositor parity (layers vs render pass, quartz backend)

    func testFlatGeometryParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        root.backgroundColor = white
        let a = UIView(frame: CGRect(x: 4, y: 4, width: 30, height: 30))
        a.backgroundColor = red
        let hidden = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        hidden.backgroundColor = blue
        hidden.isHidden = true
        let group = UIView(frame: CGRect(x: 20, y: 8, width: 30, height: 24))
        group.backgroundColor = blue
        group.alpha = 0.5
        let inner = UIView(frame: CGRect(x: 5, y: 5, width: 10, height: 10))
        inner.backgroundColor = white
        group.addSubview(inner)
        root.addSubview(a)
        root.addSubview(hidden)
        root.addSubview(group)
        let (layers, pass) = bothCompositors(root, scale: 2)
        XCTAssertLessThanOrEqual(maxChannelDiff(layers, pass), 1,
                                 "flat geometry should be near byte-identical")
    }

    func testCornerBorderClipShadowParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 60))
        root.backgroundColor = white
        let card = UIView(frame: CGRect(x: 10, y: 8, width: 40, height: 30))
        card.backgroundColor = blue
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 3
        card.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        card.layer.shadowOpacity = 0.6
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        // Subview overflowing a clipped parent; border must draw above it.
        let sub = UIView(frame: CGRect(x: 20, y: 15, width: 40, height: 40))
        sub.backgroundColor = red
        card.clipsToBounds = false
        card.addSubview(sub)
        let clipped = UIView(frame: CGRect(x: 55, y: 8, width: 20, height: 20))
        clipped.backgroundColor = red
        clipped.layer.cornerRadius = 6
        clipped.clipsToBounds = true
        let esc = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        esc.backgroundColor = blue
        clipped.addSubview(esc)
        root.addSubview(card)
        root.addSubview(clipped)
        let (layers, pass) = bothCompositors(root, scale: 2)
        XCTAssertLessThan(meanAbsDiff(layers, pass), 0.6,
                          "corner/border/clip/shadow parity")
    }

    func testUnclampedCornerRadiusSpikesOutsideBounds() {
        // 20x20 view with cornerRadius 60: CA's unclamped kappa path spikes
        // far outside the frame (golden/corner_radius behavior).
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        root.backgroundColor = white
        let v = UIView(frame: CGRect(x: 30, y: 30, width: 20, height: 20))
        v.backgroundColor = red
        v.layer.cornerRadius = 60
        root.addSubview(v)
        let (layers, pass) = bothCompositors(root, scale: 2)
        // Spike ink must exist beyond the 20x20 frame on both compositors.
        func inkOutsideFrame(_ b: Bitmap) -> Bool {
            // frame in device px: x 60..100, y 60..100; sample above it.
            for y in 80..<120 where y < 120 {
                let o = (y * b.width + 110) * 4
                if b.pixels[o] > 200 && b.pixels[o + 1] < 200 { return true }
            }
            return false
        }
        XCTAssertTrue(inkOutsideFrame(layers), "layers path must not clamp cornerRadius")
        XCTAssertLessThan(meanAbsDiff(layers, pass), 0.6)
    }

    func testTransformedLayerHardEdgesParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        root.backgroundColor = white
        let v = UIView(frame: CGRect(x: 15, y: 15, width: 30, height: 20))
        v.backgroundColor = blue
        v.transform = CGAffineTransform(a: 0.7071, b: 0.7071,
                                        c: -0.7071, d: 0.7071, tx: 0, ty: 0)
        root.addSubview(v)
        let (layers, pass) = bothCompositors(root, scale: 2)
        // Hard-edged rasterization at pixel centers: identical coverage.
        XCTAssertLessThanOrEqual(maxChannelDiff(layers, pass), 1,
                                 "transformed layers must composite hard-edged")
    }

    func testLabelContentParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        root.backgroundColor = white
        let label = UILabel(frame: CGRect(x: 8, y: 8, width: 100, height: 24))
        label.text = "Hello UIKit"
        root.addSubview(label)
        let (layers, pass) = bothCompositors(root, scale: 2)
        XCTAssertLessThan(meanAbsDiff(layers, pass), 0.6, "label glyph parity")
    }

    func testGradientViewMapsToGradientLayer() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        root.backgroundColor = white
        let g = UIGradientView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        g.colors = [red, blue]
        root.addSubview(g)
        root.layoutIfNeeded()
        let bmp = LayerBridge.render(root, scale: 2)
        // Top row ~red, bottom row ~blue (default top->bottom axis).
        let top = (Int(bmp.pixels[(2 * 80 + 40) * 4]), Int(bmp.pixels[(2 * 80 + 40) * 4 + 2]))
        let bot = (Int(bmp.pixels[(77 * 80 + 40) * 4]), Int(bmp.pixels[(77 * 80 + 40) * 4 + 2]))
        XCTAssertGreaterThan(top.0, 220); XCTAssertLessThan(top.1, 60)
        XCTAssertGreaterThan(bot.1, 220); XCTAssertLessThan(bot.0, 60)
    }

    func testSwiftBackendFallsBackToRenderPass() {
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .layers
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        root.backgroundColor = red
        root.layer.cornerRadius = 4
        let viaRender = UIRenderer.render(root, scale: 2)
        let viaPass = UIRenderer.renderPassRender(root, scale: 2)
        XCTAssertEqual(viaRender.pixels, viaPass.pixels,
                       "layers compositor requires quartz; swift backend uses the render pass")
    }
}
