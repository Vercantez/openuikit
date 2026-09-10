import XCTest
import Foundation
@testable import OpenUIKit

// UIScrollEdgeEffect, measured by Tools/oracle2/scrolledgeeffectprobe
// (iPhone 16 / iOS 26.1, ios-26.1-iphone16.json + profiles-ios-26.1-
// iphone16.json; report docs/agent_reports/scroll-edge-effect.md). Same
// content as the probe: 40 pt black/red bands, 3000 pt tall, sampled at
// x = 380 pt.

#if !os(Linux)
@MainActor
#endif
final class UIScrollEdgeEffectTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 1)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    private func fillBands(_ scroll: UIScrollView, width: CGFloat) {
        scroll.contentSize = CGSize(width: width, height: 3000)
        for i in 0..<75 {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 40, width: width, height: 40))
            band.autoresizingMask = [.flexibleWidth]
            band.backgroundColor = i % 2 == 0 ? .black : .red
            scroll.addSubview(band)
        }
    }

    private func pixel(_ bitmap: Bitmap, _ x: Int, _ y: Int) -> [Int] {
        let i = (y * bitmap.width + x) * 4
        return [Int(bitmap.pixels[i]), Int(bitmap.pixels[i + 1]), Int(bitmap.pixels[i + 2])]
    }

    private func assertPixel(_ bitmap: Bitmap, _ x: Int, _ y: Int, _ expected: [Int],
                             tolerance: Int = 1, file: StaticString = #filePath, line: UInt = #line) {
        let p = pixel(bitmap, x, y)
        XCTAssertTrue(zip(p, expected).allSatisfy { abs($0 - $1) <= tolerance },
                      "pixel (\(x), \(y)) = \(p), expected \(expected)", file: file, line: line)
    }

    // MARK: Read-back (transcript `fresh`, `freshAfterSet`, `effectSharedAcrossViews`)

    func testEveryScrollViewKindHasFourDistinctAutomaticShownEffects() {
        let views: [UIScrollView] = [
            UIScrollView(),
            UITableView(frame: .zero, style: .plain),
            UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()),
        ]
        for s in views {
            let effects = [s.topEdgeEffect, s.leftEdgeEffect, s.bottomEdgeEffect, s.rightEdgeEffect]
            XCTAssertEqual(Set(effects.map { ObjectIdentifier($0) }).count, 4)
            XCTAssertTrue(s.topEdgeEffect === s.topEdgeEffect)
            XCTAssertTrue(s.bottomEdgeEffect === s.bottomEdgeEffect)
            for (e, edge) in zip(effects, [UIRectEdge.top, .left, .bottom, .right]) {
                XCTAssertTrue(e.style === UIScrollEdgeEffect.Style.automatic)
                XCTAssertFalse(e.isHidden)
                XCTAssertEqual(e.edge, edge)
                XCTAssertTrue((e as AnyObject) is NSObject)
            }
        }
        XCTAssertFalse(views[0].topEdgeEffect === views[1].topEdgeEffect)

        // Styles are singletons; identity is equality.
        XCTAssertTrue(UIScrollEdgeEffect.Style.automatic === UIScrollEdgeEffect.Style.automatic)
        XCTAssertTrue(UIScrollEdgeEffect.Style.hard.isEqual(UIScrollEdgeEffect.Style.hard))
        XCTAssertFalse(UIScrollEdgeEffect.Style.hard.isEqual(UIScrollEdgeEffect.Style.soft))
        XCTAssertEqual(Set([UIScrollEdgeEffect.Style.automatic, .soft, .hard].map { ObjectIdentifier($0) }).count, 3)

        // Set / read back on one edge leaves the others alone.
        let s = views[0]
        s.topEdgeEffect.style = .hard
        s.topEdgeEffect.isHidden = true
        XCTAssertTrue(s.topEdgeEffect.style === UIScrollEdgeEffect.Style.hard)
        XCTAssertTrue(s.topEdgeEffect.isHidden)
        XCTAssertTrue(s.bottomEdgeEffect.style === UIScrollEdgeEffect.Style.automatic)
        XCTAssertFalse(s.bottomEdgeEffect.isHidden)
        s.leftEdgeEffect.style = .soft
        s.rightEdgeEffect.isHidden = true
        XCTAssertTrue(s.leftEdgeEffect.style === UIScrollEdgeEffect.Style.soft)
        XCTAssertTrue(s.rightEdgeEffect.isHidden)

        // An untouched scroll view carries no effect objects (and no plate).
        let untouched = UIScrollView()
        XCTAssertNil(untouched._edgeEffectIfPresent(.top))
        XCTAssertNil(untouched._edgeEffectIfPresent(.bottom))
    }

    // MARK: Container interaction (transcript `interaction.*`, profiles)

    private struct Scene {
        let host: UIView
        let scroll: UIScrollView
        let header: UIView
        let interaction: UIScrollEdgeElementContainerInteraction
    }

    /// The signalrowsprobe scene: 393×852 host, full-size scroll view, a
    /// 160 pt element-holding top container with the interaction attached.
    private func containerScene() -> Scene {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.backgroundColor = .white
        let scroll = UIScrollView(frame: host.bounds)
        fillBands(scroll, width: 393)
        host.addSubview(scroll)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 160))
        let label = UILabel(frame: CGRect(x: 20, y: 90, width: 200, height: 40))
        label.text = "Header"
        header.addSubview(label)
        host.addSubview(header)
        let top = UIScrollEdgeElementContainerInteraction()
        top.edge = .top
        top.scrollView = scroll
        header.addInteraction(top)
        scroll.contentInset = UIEdgeInsets(top: 160, left: 0, bottom: 0, right: 0)
        scroll.contentOffset = CGPoint(x: 0, y: -60)
        host.layoutIfNeeded()
        return Scene(host: host, scroll: scroll, header: header, interaction: top)
    }

    func testHidingTheTopEffectRemovesTheContainerScrim() {
        let s = containerScene()
        let pocket = try! XCTUnwrap(s.interaction.pocket)
        XCTAssertFalse(pocket.isHidden)
        // Scrim on: 100 pt under the container, the red band at host y 100
        // (content y 40) reads 192 (α 0.247).
        var bitmap = UIRenderer.render(s.host, scale: 1)
        assertPixel(bitmap, 380, 100, [192, 0, 0])

        s.scroll.topEdgeEffect.isHidden = true
        XCTAssertTrue(pocket.isHidden)
        bitmap = UIRenderer.render(s.host, scale: 1)
        assertPixel(bitmap, 380, 100, [255, 0, 0])
        assertPixel(bitmap, 380, 20, [255, 255, 255])   // above the content: host white
        assertPixel(bitmap, 380, 80, [0, 0, 0])          // content y 20: black band 0

        // Scrolling while hidden keeps it hidden; showing it again restores
        // the band (interaction.topHidden → raw; shownEdge → band).
        s.scroll.contentOffset = CGPoint(x: 0, y: 100)
        XCTAssertTrue(pocket.isHidden)
        s.scroll.topEdgeEffect.isHidden = false
        XCTAssertFalse(pocket.isHidden)
        bitmap = UIRenderer.render(s.host, scale: 1)
        assertPixel(bitmap, 380, 100, [192, 0, 0])   // content y 200: red band 5, 60 pt inside the container
    }

    func testHardStyleDrawsTheMeasuredPlateOverTheContainer() {
        let s = containerScene()
        let pocket = try! XCTUnwrap(s.interaction.pocket)
        s.scroll.topEdgeEffect.style = .hard
        // MEASURED interaction.topHard: effect view from the visible edge to
        // the container's inner edge − 30 (213 → 183); here 160 − 30 = 130.
        XCTAssertEqual(pocket.frame, CGRect(x: 0, y: -60, width: 393, height: 130))
        XCTAssertFalse(pocket.isHidden)
        let bitmap = UIRenderer.render(s.host, scale: 1)
        // Flat white α 0.902: red reads (255, 230, 230), black (230, 230, 230).
        assertPixel(bitmap, 380, 100, [255, 230, 230])
        assertPixel(bitmap, 380, 80, [230, 230, 230])   // content y 20: black band 0 under the plate
        assertPixel(bitmap, 380, 129, [255, 230, 230])
        // Hard cut at 130: raw content below (content y 70: red band 1; y 80: black band 2).
        assertPixel(bitmap, 380, 130, [255, 0, 0])
        assertPixel(bitmap, 380, 140, [0, 0, 0])

        // Back to automatic: the scrim geometry and profile return.
        s.scroll.topEdgeEffect.style = .automatic
        XCTAssertEqual(pocket.frame, CGRect(x: 0, y: -60, width: 393, height: 180))
        assertPixel(UIRenderer.render(s.host, scale: 1), 380, 100, [192, 0, 0])
    }

    // MARK: Bars (transcript `scroll.*`, `toolbar.*`, `large.*`)

    private struct BarScene {
        let window: UIWindow
        let tabs: UITabBarController
        let nav: UINavigationController
        let scroll: UIScrollView
    }

    /// The probe's app: tab bar controller → navigation controller → a
    /// controller whose view holds a full-size scroll view, on an iPhone 16
    /// window (safe area 59 / 34), iOS cut.
    private func barScene() -> BarScene {
        OpenUIKitRuntime.systemFontCut = .iOS
        let vc = UIViewController()
        vc.title = "Scroll"
        vc.view.backgroundColor = .white
        let scroll = UIScrollView(frame: vc.view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(scroll)
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem = UITabBarItem(title: "Scroll", image: UIImage(systemName: "list.bullet"), tag: 0)
        let tabs = UITabBarController()
        tabs.viewControllers = [nav]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        fillBands(scroll, width: 393)
        scroll.contentOffset = CGPoint(x: 0, y: -scroll.adjustedContentInset.top)
        window.layoutIfNeeded()
        return BarScene(window: window, tabs: tabs, nav: nav, scroll: scroll)
    }

    func testHardPlateUnderNavigationAndTabBarsMatchesTheMeasuredGeometry() {
        let s = barScene()
        XCTAssertEqual(s.nav.navigationBar.frame, CGRect(x: 0, y: 59, width: 393, height: 54))
        XCTAssertEqual(s.scroll.adjustedContentInset.top, 113)
        XCTAssertEqual(s.scroll.adjustedContentInset.bottom, 83)
        XCTAssertEqual(s.scroll.contentOffset.y, -113)
        XCTAssertNil(s.scroll._topEdgePocket)
        XCTAssertNil(s.scroll._bottomEdgePocket)

        // Bottom `.hard` at the top rest: content already runs under the
        // tab bar, so the plate is the bar frame [0, 769, 393, 83].
        s.scroll.bottomEdgeEffect.style = .hard
        let bottom = try! XCTUnwrap(s.scroll._bottomEdgePocket)
        XCTAssertFalse(bottom.isHidden)
        XCTAssertEqual(bottom.frame, CGRect(x: 0, y: -113 + 769, width: 393, height: 83))
        XCTAssertNil(s.scroll._topEdgePocket)

        // Top `.hard`: off through 8 pt under the safe edge, on at 12 —
        // the trigger is the glass edge at 103 (= 113 − 10), and the plate
        // is [0, 0, 393, 103] on screen.
        s.scroll.topEdgeEffect.style = .hard
        XCTAssertTrue(s.scroll._topEdgePocket?.isHidden ?? true)
        s.scroll.contentOffset = CGPoint(x: 0, y: -113 + 8)
        XCTAssertTrue(s.scroll._topEdgePocket?.isHidden ?? true)
        s.scroll.contentOffset = CGPoint(x: 0, y: -113 + 12)
        let top = try! XCTUnwrap(s.scroll._topEdgePocket)
        XCTAssertFalse(top.isHidden)
        XCTAssertEqual(top.frame, CGRect(x: 0, y: -101, width: 393, height: 103))

        // 100 pt under (scroll.topHard / scroll.bottomHard, offset −13):
        // both plates, white α 0.902 with a hard cut at 103 / 769.
        s.scroll.contentOffset = CGPoint(x: 0, y: -13)
        XCTAssertEqual(top.frame, CGRect(x: 0, y: -13, width: 393, height: 103))
        XCTAssertEqual(bottom.frame, CGRect(x: 0, y: -13 + 769, width: 393, height: 83))
        let bitmap = UIRenderer.render(s.window, scale: 1)
        assertPixel(bitmap, 380, 30, [230, 230, 230])       // black band 13–52 under the plate
        assertPixel(bitmap, 380, 80, [255, 230, 230])                   // red band 53–92
        assertPixel(bitmap, 380, 102, [230, 230, 230])                  // last plate row (black band 93–132)
        assertPixel(bitmap, 380, 103, [0, 0, 0])                        // hard cut: raw
        assertPixel(bitmap, 380, 150, [255, 0, 0])                      // raw red band 133–172
        assertPixel(bitmap, 380, 768, [0, 0, 0])                        // raw black band 733–772
        assertPixel(bitmap, 380, 790, [255, 230, 230])                  // red band 773–812 under the plate
        assertPixel(bitmap, 380, 830, [230, 230, 230])                  // black band 813–851

        // Bottom rest: the bottom plate disengages (bottomRest raw), the
        // top stays; 1 pt short of the rest it is back (bottom-1).
        let bottomRest = 3000 - 852 + 83
        s.scroll.contentOffset = CGPoint(x: 0, y: CGFloat(bottomRest))
        XCTAssertTrue(bottom.isHidden)
        XCTAssertFalse(top.isHidden)
        s.scroll.contentOffset = CGPoint(x: 0, y: CGFloat(bottomRest - 1))
        XCTAssertFalse(bottom.isHidden)

        // Hidden beats hard; showing again restores the plate.
        s.scroll.topEdgeEffect.isHidden = true
        XCTAssertTrue(top.isHidden)
        s.scroll.topEdgeEffect.isHidden = false
        XCTAssertFalse(top.isHidden)
        s.scroll.topEdgeEffect.style = .automatic
        XCTAssertTrue(top.isHidden)
    }

    func testHardPlateUnderAToolbarStartsAtTheSlotPadding() {
        OpenUIKitRuntime.systemFontCut = .iOS
        let vc = UIViewController()
        vc.title = "Toolbar"
        vc.view.backgroundColor = .white
        let scroll = UIScrollView(frame: vc.view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(scroll)
        vc.toolbarItems = [UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)]
        let nav = UINavigationController(rootViewController: vc)
        nav.isToolbarHidden = false
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        fillBands(scroll, width: 393)
        scroll.contentOffset = CGPoint(x: 0, y: -13)
        window.layoutIfNeeded()
        // toolbar.rest: adjustedContentInset.bottom 86; toolbar.bottomHard:
        // effect view [0, 776, 393, 76] = slot top 766 + 10.
        XCTAssertEqual(scroll.adjustedContentInset.bottom, 86)
        scroll.bottomEdgeEffect.style = .hard
        let bottom = try! XCTUnwrap(scroll._bottomEdgePocket)
        XCTAssertFalse(bottom.isHidden)
        XCTAssertEqual(bottom.frame, CGRect(x: 0, y: -13 + 776, width: 393, height: 76))
        scroll.bottomEdgeEffect.isHidden = true
        XCTAssertTrue(bottom.isHidden)
    }

    func testLargeTitlePocketAndTabBarGradientFollowTheEffect() {
        OpenUIKitRuntime.systemFontCut = .iOS
        // Large-title bar: collapsed pocket engaged, then hidden / hard.
        let vc = UIViewController()
        vc.title = "Large"
        vc.view.backgroundColor = .systemBackground
        let scroll = UIScrollView(frame: vc.view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: 375, height: 1200)
        vc.view.addSubview(scroll)
        vc.setContentScrollView(scroll)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        nav.view.frame = CGRect(x: 0, y: 0, width: 375, height: 480)
        nav.view.layoutIfNeeded()
        scroll.contentOffset = CGPoint(x: 0, y: 160)
        let bar = nav.navigationBar
        XCTAssertFalse(bar.pocketView.isHidden)
        scroll.topEdgeEffect.isHidden = true
        XCTAssertTrue(bar.pocketView.isHidden)
        scroll.topEdgeEffect.isHidden = false
        XCTAssertFalse(bar.pocketView.isHidden)
        scroll.topEdgeEffect.style = .hard
        XCTAssertTrue(bar.pocketView.isHidden)
        scroll.topEdgeEffect.style = .automatic
        XCTAssertFalse(bar.pocketView.isHidden)

        // Tab bar: the dark gradient follows the selected controller's
        // content scroll view (resolved without setContentScrollView).
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark, displayScale: 1)
        defer { UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 1) }
        let s = barScene()
        s.window.overrideUserInterfaceStyle = .dark
        s.tabs.tabBar.setNeedsLayout()
        s.tabs.tabBar.layoutIfNeeded()
        XCTAssertTrue(s.tabs._resolvedContentScrollView(for: .bottom) === s.scroll)
        let edge = try! XCTUnwrap(s.tabs.tabBar.bottomEdgeEffect)
        XCTAssertFalse(edge.isHidden)
        s.scroll.bottomEdgeEffect.isHidden = true
        XCTAssertTrue(edge.isHidden)
        s.scroll.bottomEdgeEffect.isHidden = false
        XCTAssertFalse(edge.isHidden)
        s.scroll.bottomEdgeEffect.style = .hard
        XCTAssertTrue(edge.isHidden)
        XCTAssertNotNil(s.scroll._bottomEdgePocket)
    }
}
