// Tests for M8 layer-contents caching (LayerBridge content-image +
// subtree-composite caches). Owner: quartz-backend module.
//
// The core invariant: repeated renders of a live tree (which engage the
// caches from the third frame) must stay pixel-identical to an uncached
// render of the same model state, including after every kind of mutation
// the fingerprints track.
import XCTest
@testable import OpenUIKit

fileprivate typealias CGFloat = OpenUIKit.CGFloat
fileprivate typealias CGPoint = OpenUIKit.CGPoint
fileprivate typealias CGSize = OpenUIKit.CGSize
fileprivate typealias CGRect = OpenUIKit.CGRect

final class LayerCacheTests: XCTestCase {

    private var savedCaching = true

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCaching = OpenUIKitRuntime.layerCaching
        OpenUIKitRuntime.layerCaching = true
    }
    override func tearDown() {
        OpenUIKitRuntime.layerCaching = savedCaching
        super.tearDown()
    }

    /// A Settings-card-like tree: scroll view with two rounded, clipped
    /// cards holding labels and switches, over a colored root.
    private func makeTree() -> (root: UIView, scroll: UIScrollView,
                                label: UILabel, sw: UISwitch, card: UIView) {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        root.backgroundColor = .systemGroupedBackground
        let scroll = UIScrollView(frame: root.bounds)
        scroll.contentSize = CGSize(width: 200, height: 600)
        root.addSubview(scroll)

        var firstLabel: UILabel!
        var firstSwitch: UISwitch!
        var firstCard: UIView!
        for i in 0..<2 {
            let card = UIView(frame: CGRect(x: 16, y: 20 + CGFloat(i) * 140,
                                            width: 168, height: 120))
            card.backgroundColor = .secondarySystemGroupedBackground
            card.layer.cornerRadius = 10
            card.clipsToBounds = true
            let label = UILabel(frame: CGRect(x: 12, y: 10, width: 120, height: 20))
            label.text = "Row \(i)"
            label.font = .systemFont(ofSize: 15)
            card.addSubview(label)
            let sw = UISwitch()
            sw.frame.origin = CGPoint(x: 100, y: 60)
            sw.isOn = i == 0
            card.addSubview(sw)
            let hairline = UIView(frame: CGRect(x: 12, y: 40, width: 144, height: 0.5))
            hairline.backgroundColor = .separator
            card.addSubview(hairline)
            scroll.addSubview(card)
            if i == 0 { firstLabel = label; firstSwitch = sw; firstCard = card }
        }
        return (root, scroll, firstLabel, firstSwitch, firstCard)
    }

    /// Render with the caches disabled (ground truth for the same model).
    private func uncached(_ root: UIView, scale: CGFloat) -> [UInt8] {
        let was = OpenUIKitRuntime.layerCaching
        OpenUIKitRuntime.layerCaching = false
        defer { OpenUIKitRuntime.layerCaching = was }
        return UIRenderer.render(root, scale: scale).pixels
    }

    /// Renders `n` times (letting composites build) and returns the last.
    private func warmRender(_ root: UIView, scale: CGFloat, times n: Int = 4) -> [UInt8] {
        var last: [UInt8] = []
        for _ in 0..<n { last = UIRenderer.render(root, scale: scale).pixels }
        return last
    }

    func testWarmCacheMatchesUncachedExactly() {
        guard OpenUIKitRuntime.compositor == .layers else { return }
        let t = makeTree()
        let truth = uncached(t.root, scale: 2)
        let warm = warmRender(t.root, scale: 2)
        XCTAssertEqual(warm, truth, "cached composite render diverges from direct render")
    }

    func testScrollOffsetRepositionsCachedCards() {
        guard OpenUIKitRuntime.compositor == .layers else { return }
        let t = makeTree()
        _ = warmRender(t.root, scale: 2)                    // build caches
        t.scroll.contentOffset = CGPoint(x: 0, y: 50)       // integral offset
        let cached = UIRenderer.render(t.root, scale: 2).pixels
        let truth = uncached(t.root, scale: 2)
        XCTAssertEqual(cached, truth, "scrolled cached blit diverges from direct render")
    }

    func testMutationsInvalidate() {
        guard OpenUIKitRuntime.compositor == .layers else { return }
        let t = makeTree()
        _ = warmRender(t.root, scale: 2)

        // Label text change must invalidate the content + composite caches.
        t.label.text = "Changed"
        _ = UIRenderer.render(t.root, scale: 2)             // re-stabilize
        var cached = UIRenderer.render(t.root, scale: 2).pixels
        var truth = uncached(t.root, scale: 2)
        XCTAssertEqual(cached, truth, "label text change not picked up")

        // Background color change.
        t.card.backgroundColor = .systemRed
        _ = UIRenderer.render(t.root, scale: 2)
        cached = UIRenderer.render(t.root, scale: 2).pixels
        truth = uncached(t.root, scale: 2)
        XCTAssertEqual(cached, truth, "background change not picked up")

        // Switch state change (no animation).
        t.sw.setOn(false, animated: false)
        _ = UIRenderer.render(t.root, scale: 2)
        cached = UIRenderer.render(t.root, scale: 2).pixels
        truth = uncached(t.root, scale: 2)
        XCTAssertEqual(cached, truth, "switch state change not picked up")

        // Hiding a subview.
        t.label.isHidden = true
        _ = UIRenderer.render(t.root, scale: 2)
        cached = UIRenderer.render(t.root, scale: 2).pixels
        truth = uncached(t.root, scale: 2)
        XCTAssertEqual(cached, truth, "isHidden change not picked up")
    }

    /// Custom views must be able to invalidate via setNeedsDisplay (the
    /// UIKit contract for custom drawContent).
    final class InkView: UIView {
        var level: OpenUIKit.CGFloat = 0.25
        override func drawContent(in canvas: Canvas, bounds: OpenUIKit.CGRect) {
            canvas.fill(rect: CGRect(x: 0, y: 0, width: bounds.width * level,
                                     height: bounds.height),
                        color: CGColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 1))
        }
    }

    func testSetNeedsDisplayInvalidatesCustomContent() {
        guard OpenUIKitRuntime.compositor == .layers else { return }
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        root.backgroundColor = .white
        let card = UIView(frame: CGRect(x: 5, y: 5, width: 50, height: 20))
        card.backgroundColor = .systemGray6
        let ink = InkView(frame: card.bounds.insetBy(dx: 2, dy: 2))
        card.addSubview(ink)
        root.addSubview(card)
        _ = warmRender(root, scale: 2)

        ink.level = 0.9
        ink.setNeedsDisplay()
        _ = UIRenderer.render(root, scale: 2)
        let cached = UIRenderer.render(root, scale: 2).pixels
        let truth = uncached(root, scale: 2)
        XCTAssertEqual(cached, truth, "setNeedsDisplay did not invalidate custom content")
    }
}
