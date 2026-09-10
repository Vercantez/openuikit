import XCTest
import Foundation
@testable import OpenUIKit

// UIScrollEdgeElementContainerInteraction, measured by
// Tools/oracle2/signalrowsprobe (iPhone 16 / iOS 26.1, `edge.*` in
// ios-26.1-iphone16.json and edge-ios-26.1-iphone16.json). Same geometry as
// the probe: 393×852 host, full-size scroll view with 40 pt black/red
// bands, a 160 pt top container and a 120 pt bottom container, insets
// 160/120 so content rests below the top container.

#if !os(Linux)
@MainActor
#endif
final class UIScrollEdgeElementContainerInteractionTests: XCTestCase {
    private struct Scene {
        let host: UIView
        let scroll: UIScrollView
        let header: UIView
        let footer: UIView
    }

    private func scene() -> Scene {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.backgroundColor = .white
        let scroll = UIScrollView(frame: host.bounds)
        scroll.contentSize = CGSize(width: 393, height: 3000)
        for i in 0..<75 {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 40, width: 393, height: 40))
            band.backgroundColor = i % 2 == 0 ? .black : .red
            scroll.addSubview(band)
        }
        host.addSubview(scroll)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 160))
        host.addSubview(header)
        let footer = UIView(frame: CGRect(x: 0, y: 732, width: 393, height: 120))
        host.addSubview(footer)
        scroll.contentInset = UIEdgeInsets(top: 160, left: 0, bottom: 120, right: 0)
        scroll.contentOffset = CGPoint(x: 0, y: -160)
        host.layoutIfNeeded()
        return Scene(host: host, scroll: scroll, header: header, footer: footer)
    }

    private func pockets(in scroll: UIScrollView) -> [_UITouchPassthroughView] {
        scroll.subviews.compactMap { $0 as? _UITouchPassthroughView }
    }

    func testDefaultsAreEmptyEdgeNilWeakScrollViewAndNoView() {
        let interaction = UIScrollEdgeElementContainerInteraction()
        XCTAssertNotNil(interaction as NSObject)
        XCTAssertEqual(interaction.edge, [])
        XCTAssertEqual(interaction.edge.rawValue, 0)
        XCTAssertNil(interaction.scrollView)
        XCTAssertNil(interaction.view)
        interaction.edge = .bottom
        XCTAssertEqual(interaction.edge.rawValue, 4)
        interaction.edge = [.top, .bottom]
        XCTAssertEqual(interaction.edge.rawValue, 5)
        interaction.edge = .left
        XCTAssertEqual(interaction.edge.rawValue, 2)
        var temporary: UIScrollView? = UIScrollView()
        interaction.scrollView = temporary
        XCTAssertTrue(interaction.scrollView === temporary)
        temporary = nil
        XCTAssertNil(interaction.scrollView)
    }

    func testAttachingToAnEmptyContainerChangesNoTreeAndMakesNoPocket() {
        let s = scene()
        let interaction = UIScrollEdgeElementContainerInteraction()
        interaction.edge = .top
        interaction.scrollView = s.scroll
        let scrollSubviewsBefore = s.scroll.subviews.count
        s.header.addInteraction(interaction)
        s.scroll.contentOffset = CGPoint(x: 0, y: 100)
        s.host.layoutIfNeeded()
        XCTAssertTrue(interaction.view === s.header)
        XCTAssertEqual(s.header.frame, CGRect(x: 0, y: 0, width: 393, height: 160))
        XCTAssertEqual(s.header.subviews.count, 0)
        XCTAssertEqual(s.header.layer.sublayers?.count ?? 0, 0)
        XCTAssertNil(s.header.backgroundColor)
        XCTAssertEqual(s.host.subviews.count, 3)
        XCTAssertEqual(s.scroll.subviews.count, scrollSubviewsBefore)
        XCTAssertEqual(pockets(in: s.scroll).count, 0)
        XCTAssertEqual(s.header.interactions.count, 1)
        s.header.removeInteraction(interaction)
        XCTAssertNil(interaction.view)
        XCTAssertEqual(s.header.interactions.count, 0)
    }

    func testPlainSubviewIsNotAnElement() {
        let s = scene()
        let strip = UIView(frame: CGRect(x: 0, y: 150, width: 393, height: 4))
        strip.backgroundColor = .green
        s.header.addSubview(strip)
        let interaction = UIScrollEdgeElementContainerInteraction()
        interaction.edge = .top
        interaction.scrollView = s.scroll
        s.header.addInteraction(interaction)
        s.scroll.contentOffset = CGPoint(x: 0, y: 100)
        s.host.layoutIfNeeded()
        XCTAssertEqual(pockets(in: s.scroll).count, 0)
        XCTAssertFalse(UIScrollEdgeElementContainerInteraction.holdsElement(s.header))
        XCTAssertTrue(UIScrollEdgeElementContainerInteraction.holdsElement({
            let v = UIView(); v.addSubview(UILabel()); return v
        }()))
    }

    func testElementHoldingContainerGetsAPocketThatEngagesPastRest() {
        let s = scene()
        let label = UILabel(frame: CGRect(x: 20, y: 90, width: 200, height: 40))
        label.text = "Header"
        s.header.addSubview(label)
        let footLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 200, height: 40))
        footLabel.text = "Footer"
        s.footer.addSubview(footLabel)
        let top = UIScrollEdgeElementContainerInteraction()
        top.edge = .top
        top.scrollView = s.scroll
        s.header.addInteraction(top)
        let bottom = UIScrollEdgeElementContainerInteraction()
        bottom.edge = .bottom
        bottom.scrollView = s.scroll
        s.footer.addInteraction(bottom)
        s.host.layoutIfNeeded()

        // Tree: the container and its siblings are untouched; the scroll
        // view holds one pocket per attached edge, below the indicators.
        XCTAssertEqual(s.header.subviews.count, 1)
        XCTAssertEqual(s.host.subviews.count, 3)
        let found = pockets(in: s.scroll)
        XCTAssertEqual(found.count, 2)
        let topPocket = try! XCTUnwrap(top.pocket)
        let bottomPocket = try! XCTUnwrap(bottom.pocket)
        XCTAssertTrue(topPocket.superview === s.scroll)
        XCTAssertNil(topPocket.hitTest(CGPoint(x: 10, y: 10), with: nil))

        // Rest: offset == -inset, content not under the top container.
        XCTAssertEqual(s.scroll.contentOffset, CGPoint(x: 0, y: -160))
        XCTAssertTrue(topPocket.isHidden)
        XCTAssertFalse(bottomPocket.isHidden)

        // 100 pt under: engaged. Pocket band = container band in scroll
        // coordinates plus the 20 pt fade past the inner edge.
        s.scroll.contentOffset = CGPoint(x: 0, y: -60)
        XCTAssertFalse(topPocket.isHidden)
        XCTAssertEqual(topPocket.frame, CGRect(x: 0, y: -60, width: 393, height: 180))
        XCTAssertEqual(bottomPocket.frame, CGRect(x: 0, y: 732 - 60 - 20, width: 393, height: 140))

        // Bottom rest: the bottom pocket disengages, the top stays.
        let bottomRest = 3000 - 852 + 120
        s.scroll.contentOffset = CGPoint(x: 0, y: CGFloat(bottomRest))
        XCTAssertTrue(bottomPocket.isHidden)
        XCTAssertFalse(topPocket.isHidden)
        s.scroll.contentOffset = CGPoint(x: 0, y: CGFloat(bottomRest - 60))
        XCTAssertFalse(bottomPocket.isHidden)

        // Detaching removes the pocket.
        s.header.removeInteraction(top)
        XCTAssertNil(top.pocket)
        XCTAssertEqual(pockets(in: s.scroll).count, 1)
    }

    func testScrimProfileMatchesTheMeasuredColumn() {
        // under100, x 380: red (255,0,0) reads 192 in the flat zone and 232
        // at 139 pt; footer bottomUnder: 229 at 16 pt inside the edge, 246
        // at the edge, 254 sixteen points past it.
        let alpha = UIScrollEdgeElementContainerInteraction.scrimAlpha
        XCTAssertEqual(alpha(100), 0.247, accuracy: 1e-9)
        XCTAssertEqual(alpha(60), 0.247, accuracy: 1e-9)
        XCTAssertEqual((1 - alpha(60)) * 255, 192, accuracy: 0.5)
        XCTAssertEqual((1 - alpha(16)) * 255, 229.5, accuracy: 0.5)
        XCTAssertEqual((1 - alpha(0)) * 255, 246, accuracy: 0.5)
        XCTAssertEqual((1 - alpha(-16)) * 255, 254, accuracy: 0.5)
        XCTAssertEqual(alpha(-20), 0)
        XCTAssertEqual(alpha(-40), 0)
        XCTAssertEqual(alpha(36), 0.1675, accuracy: 1e-9)
    }
}
