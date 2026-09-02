// M10 chrome controller tests: modal presentation lifecycle (pageSheet /
// fullScreen appearance semantics, presentation stack links, dim/sheet
// chrome + measured metrics, host-clock completion), UITabBarController
// switching (appearance order, state preservation, tap selection) and
// large-title navigation bar collapse (tracked offset -> title layout /
// fades, snap-to-rest, pocket engagement).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

@MainActor
private final class Log {
    var entries: [String] = []
    func add(_ s: String) { entries.append(s) }
}

@MainActor
private class LifecycleVC: UIViewController {
    let name: String
    let log: Log
    init(name: String, log: Log) {
        self.name = name
        self.log = log
        super.init()
        title = name
    }
    override func viewDidLoad() { log.add("\(name).didLoad") }
    override func viewWillAppear(_ animated: Bool) { log.add("\(name).willAppear") }
    override func viewDidAppear(_ animated: Bool) { log.add("\(name).didAppear") }
    override func viewWillDisappear(_ animated: Bool) { log.add("\(name).willDisappear") }
    override func viewDidDisappear(_ animated: Bool) { log.add("\(name).didDisappear") }
}

// MARK: - Modal presentation

@MainActor
final class ModalPresentationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
    }
    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    private func makeBase(_ log: Log, in window: UIWindow? = nil) -> LifecycleVC {
        let base = LifecycleVC(name: "Base", log: log)
        base.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        if let window {
            window.addSubview(base.view)
        }
        base.beginAppearanceTransition(true, animated: false)
        base.endAppearanceTransition()
        log.entries.removeAll()
        return base
    }

    func testPresentLinksAndPageSheetLifecycle() {
        let log = Log()
        let base = makeBase(log)
        let sheet = LifecycleVC(name: "Sheet", log: log)

        base.present(sheet, animated: false)
        // pageSheet: the presenter stays visible — NO disappearance calls.
        XCTAssertEqual(log.entries,
                       ["Sheet.didLoad", "Sheet.willAppear", "Sheet.didAppear"])
        XCTAssertTrue(base.presentedViewController === sheet)
        XCTAssertTrue(sheet.presentingViewController === base)

        log.entries.removeAll()
        base.dismiss(animated: false)
        XCTAssertEqual(log.entries, ["Sheet.willDisappear", "Sheet.didDisappear"])
        XCTAssertNil(base.presentedViewController)
        XCTAssertNil(sheet.presentingViewController)
        XCTAssertNil(sheet.view.superview)
    }

    func testFullScreenSendsPresenterDisappearance() {
        let log = Log()
        let base = makeBase(log)
        let modal = LifecycleVC(name: "Modal", log: log)
        modal.modalPresentationStyle = .fullScreen

        base.present(modal, animated: false)
        XCTAssertEqual(log.entries, ["Modal.didLoad", "Base.willDisappear",
                                     "Modal.willAppear", "Modal.didAppear",
                                     "Base.didDisappear"])
        log.entries.removeAll()
        base.dismiss(animated: false)
        XCTAssertEqual(log.entries, ["Modal.willDisappear", "Base.willAppear",
                                     "Modal.didDisappear", "Base.didAppear"])
    }

    func testDismissFromPresentedForwardsToPresenter() {
        let log = Log()
        let base = makeBase(log)
        let sheet = LifecycleVC(name: "Sheet", log: log)
        base.present(sheet, animated: false)
        sheet.dismiss(animated: false)   // UIKit: dismisses itself
        XCTAssertNil(base.presentedViewController)
        XCTAssertNil(sheet.presentingViewController)
    }

    func testPresentForwardsToTopOfStack() {
        let log = Log()
        let base = makeBase(log)
        let first = LifecycleVC(name: "First", log: log)
        let second = LifecycleVC(name: "Second", log: log)
        base.present(first, animated: false)
        base.present(second, animated: false)   // forwarded to `first`
        XCTAssertTrue(first.presentedViewController === second)
        XCTAssertTrue(second.presentingViewController === first)
        base.dismiss(animated: false)           // collapses the whole chain
        XCTAssertNil(base.presentedViewController)
        XCTAssertNil(first.presentedViewController)
    }

    func testPageSheetChromeMetrics() {
        let log = Log()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = makeBase(log, in: window)
        let sheet = LifecycleVC(name: "Sheet", log: log)
        base.present(sheet, animated: false)

        // Chrome attaches to the window (topmost ancestor), above base.
        let container = sheet._presentationContainer
        XCTAssertTrue(container?.superview === window)
        // Dim at the measured 20%.
        XCTAssertEqual(sheet._presentationDim?.alpha ?? 0, 0.2, accuracy: 1e-9)
        // Sheet at the measured 59 pt top inset, full width to the bottom.
        // (M11: sheetprobe reads the live frame off real iOS as
        // (0, 59, 393, 793); the M10 value of 59.5 was a fit to the golden's
        // edge profile and scored 0.09 pt worse — see docs/APP_FEEL.md.)
        let sf = sheet._presentationSheet!.frame
        XCTAssertEqual(sf.minY, 59, accuracy: 1e-9)
        XCTAssertEqual(sf.width, 393)
        XCTAssertEqual(sf.maxY, 852)
        // The presented view fills the sheet and lost its own background
        // (the platter draws the rounded shape instead).
        XCTAssertEqual(sheet.view.bounds.size, sf.size)
        XCTAssertNil(sheet.view.backgroundColor)

        base.dismiss(animated: false)
        XCTAssertNil(container?.superview)
    }

    func testAnimatedPresentCompletesOnHostClock() {
        let log = Log()
        let base = makeBase(log)
        let sheet = LifecycleVC(name: "Sheet", log: log)
        base.present(sheet, animated: true)
        // "will" fires immediately; "did" waits for the transition end.
        XCTAssertEqual(log.entries, ["Sheet.didLoad", "Sheet.willAppear"])
        // The slide-up was recorded from offscreen (y = 852) to rest
        // (y = 59): the model holds the final frame, the recorded
        // animation the offscreen start (the presentation interpolates).
        let platter = sheet._presentationSheet!
        XCTAssertEqual(platter.frame.minY, 59, accuracy: 1e-9)
        XCTAssertTrue(platter.animations.contains { $0.property == .position })
        XCTAssertEqual(sheet._presentationDim?.alpha ?? 0, 0.2, accuracy: 1e-9)
        OpenUIKitRuntime.animationTime = UIViewController.presentTransitionDuration + 0.01
        UIView._stepAnimationCompletions(to: OpenUIKitRuntime.animationTime)
        XCTAssertEqual(log.entries,
                       ["Sheet.didLoad", "Sheet.willAppear", "Sheet.didAppear"])
    }

    func testSheetPathMatchesMeasuredCornerProfile() {
        // Golden left-edge inset per Δy from the top edge (points).
        let rect = CGRect(x: 0, y: 0, width: 393, height: 792.5)
        let path = _UIPageSheetView.sheetPath(
            in: rect, topRadius: _UIPageSheetView.topCornerRadius,
            bottomRadius: _UIPageSheetView.bottomCornerRadius)
        // Rasterize-free probe: walk the path's flattened segments and find
        // the leftmost x at a few scanline depths.
        func leftmostX(atY y: CGFloat) -> CGFloat {
            var minX = CGFloat.greatestFiniteMagnitude
            var last = CGPoint.zero
            var start = CGPoint.zero
            func consider(_ a: CGPoint, _ b: CGPoint) {
                let (y0, y1) = (Swift.min(a.y, b.y), Swift.max(a.y, b.y))
                guard y >= y0, y <= y1, y1 > y0 else { return }
                let t = (y - a.y) / (b.y - a.y)
                minX = Swift.min(minX, a.x + (b.x - a.x) * t)
            }
            for e in path.elements {
                switch e {
                case .move(let p): last = p; start = p
                case .line(let p): consider(last, p); last = p
                case .quad(_, let end), .cubic(_, _, let end):
                    // Flatten coarsely: sample the curve.
                    let steps = 32
                    var prev = last
                    for i in 1...steps {
                        let t = CGFloat(i) / CGFloat(steps)
                        let pt = _curvePoint(e, from: last, t: t)
                        consider(prev, pt)
                        prev = pt
                    }
                    last = end
                case .close: consider(last, start)
                }
            }
            return minX
        }
        // Measured circular fit: within ~1.5 pt of the golden profile.
        for (dy, expected) in [(5.0, 18.94), (10.0, 12.13), (20.0, 4.41)] {
            XCTAssertEqual(Double(leftmostX(atY: CGFloat(dy))), expected,
                           accuracy: 1.5)
        }
    }
}

/// Sample a path curve element at parameter t (helper for the corner probe).
private func _curvePoint(_ e: Path.Element, from p0: CGPoint,
                         t: CGFloat) -> CGPoint {
    switch e {
    case .cubic(let c1, let c2, let p3):
        let mt = 1 - t
        let a = mt * mt * mt, b = 3 * mt * mt * t, c = 3 * mt * t * t, d = t * t * t
        return CGPoint(x: a * p0.x + b * c1.x + c * c2.x + d * p3.x,
                       y: a * p0.y + b * c1.y + c * c2.y + d * p3.y)
    case .quad(let c, let p2):
        let mt = 1 - t
        let a = mt * mt, b = 2 * mt * t, d = t * t
        return CGPoint(x: a * p0.x + b * c.x + d * p2.x,
                       y: a * p0.y + b * c.y + d * p2.y)
    default:
        return p0
    }
}

// MARK: - Tab bar controller

@MainActor
final class TabBarControllerTests: XCTestCase {
    private func makeTab(_ log: Log, count: Int = 3)
        -> (UITabBarController, [LifecycleVC]) {
        let tab = UITabBarController()
        let vcs = (0..<count).map { LifecycleVC(name: "T\($0)", log: log) }
        tab.viewControllers = vcs
        tab.view.frame = CGRect(x: 0, y: 0, width: 375, height: 480)
        tab.view.layoutIfNeeded()
        return (tab, vcs)
    }

    func testInitialInstallAndBarState() {
        let log = Log()
        let (tab, vcs) = makeTab(log)
        XCTAssertEqual(log.entries, ["T0.didLoad", "T0.willAppear", "T0.didAppear"])
        XCTAssertTrue(tab.selectedViewController === vcs[0])
        XCTAssertEqual(tab.selectedIndex, 0)
        XCTAssertTrue(tab.tabBar.selectedItem === vcs[0].tabBarItem)
        XCTAssertTrue(vcs[0].tabBarController === tab)
        // Bar occupies the bottom 72 pt; content underlaps (full bounds).
        XCTAssertEqual(tab.tabBar.frame,
                       CGRect(x: 0, y: 408, width: 375, height: 72))
        XCTAssertEqual(vcs[0].view.bounds.size, CGSize(width: 375, height: 480))
    }

    func testSwitchOrderAndStatePreservation() {
        let log = Log()
        let (tab, vcs) = makeTab(log)
        // Scroll state to preserve on tab 0.
        let scroll = UIScrollView(frame: vcs[0].view.bounds)
        scroll.contentSize = CGSize(width: 375, height: 2000)
        scroll.contentOffset = CGPoint(x: 0, y: 321)
        vcs[0].view.addSubview(scroll)

        log.entries.removeAll()
        tab.selectedIndex = 1
        // Measured UIKit order: old will → new will → old did → new did.
        XCTAssertEqual(log.entries, ["T1.didLoad", "T0.willDisappear",
                                     "T1.willAppear", "T0.didDisappear",
                                     "T1.didAppear"])
        XCTAssertTrue(tab.selectedViewController === vcs[1])
        XCTAssertNil(vcs[0].view.superview?.superview) // wrapper detached

        log.entries.removeAll()
        tab.selectedIndex = 0
        XCTAssertEqual(log.entries, ["T1.willDisappear", "T0.willAppear",
                                     "T1.didDisappear", "T0.didAppear"])
        // Tab 0's view state survived the round trip.
        XCTAssertEqual(scroll.contentOffset.y, 321)
        XCTAssertTrue(vcs[0].view.subviews.contains { $0 === scroll })
        // No spurious reload.
        XCTAssertFalse(log.entries.contains("T0.didLoad"))
    }

    func testTapSelectsTab() {
        let log = Log()
        let (tab, vcs) = makeTab(log)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 480))
        window.addSubview(tab.view)
        window.layoutIfNeeded()
        // Item pitch 85.75, platter centered: item 1's center is at x=187.5,
        // inside the platter (y ≈ 439 in the 480 pt scene).
        window.sendTouch(.began, at: CGPoint(x: 187.5, y: 439), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 187.5, y: 439), timestamp: 0.05)
        XCTAssertEqual(tab.selectedIndex, 1)
        XCTAssertTrue(tab.selectedViewController === vcs[1])
        XCTAssertTrue(tab.tabBar.selectedItem === vcs[1].tabBarItem)
    }

    func testSelectedIndexBeforeViewLoad() {
        let log = Log()
        let tab = UITabBarController()
        let vcs = (0..<3).map { LifecycleVC(name: "T\($0)", log: log) }
        tab.viewControllers = vcs
        tab.selectedIndex = 2
        XCTAssertTrue(log.entries.isEmpty)      // nothing installed yet
        tab.view.frame = CGRect(x: 0, y: 0, width: 375, height: 480)
        tab.view.layoutIfNeeded()
        XCTAssertTrue(tab.selectedViewController === vcs[2])
        XCTAssertEqual(log.entries, ["T2.didLoad", "T2.willAppear", "T2.didAppear"])
    }
}

// MARK: - Large-title navigation bar

@MainActor
final class LargeTitleNavigationTests: XCTestCase {
    private func makeLargeNav(offset: CGFloat? = nil)
        -> (UINavigationController, UIScrollView) {
        let vc = UIViewController()
        vc.title = "Library"
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
        if let offset { scroll.contentOffset = CGPoint(x: 0, y: offset) }
        return (nav, scroll)
    }

    func testExpandedRestState() {
        let (nav, scroll) = makeLargeNav()
        let bar = nav.navigationBar
        // Binding reserved the expanded inset and settled at the rest offset.
        XCTAssertEqual(scroll.contentInset.top, 116)
        XCTAssertEqual(scroll.contentOffset.y, -116)
        // Content fills the whole container (underlaps the transparent bar).
        XCTAssertEqual(nav.topViewController!.view.frame,
                       CGRect(x: 0, y: 0, width: 375, height: 480))
        XCTAssertNil(bar.backgroundColor)
        // Large title at its measured rest frame; inline title hidden.
        let large = bar.largeTitleLabel!
        XCTAssertEqual(large.frame.origin.x, 20)
        XCTAssertEqual(large.frame.origin.y, 67)
        XCTAssertEqual(large.frame.height, 40.5)
        XCTAssertEqual(large.font.pointSize, 34)
        XCTAssertEqual(large.alpha, 1)
        XCTAssertEqual(bar.titleLabel.alpha, 0)
        XCTAssertTrue(bar.pocketView.isHidden)
    }

    func testCollapsedState() {
        let (nav, _) = makeLargeNav(offset: 160)
        let bar = nav.navigationBar
        // Large title scrolled away (1:1 with content) and faded out;
        // inline title fully in; pocket engaged.
        let d: CGFloat = 160 + 116
        XCTAssertEqual(bar.largeTitleLabel!.frame.origin.y, 67 - d)
        XCTAssertEqual(bar.largeTitleLabel!.alpha, 0)
        XCTAssertEqual(bar.titleLabel.alpha, 1)
        XCTAssertEqual(bar.titleLabel.center.y, 32, accuracy: 1e-9)
        XCTAssertFalse(bar.pocketView.isHidden)
        XCTAssertEqual(bar.pocketView.frame,
                       CGRect(x: 0, y: 0, width: 375,
                              height: UINavigationBar.pocketHeight))
    }

    func testMidCollapseInterpolates() {
        let (nav, scroll) = makeLargeNav()
        let bar = nav.navigationBar
        scroll.contentOffset = CGPoint(x: 0, y: -116 + 36)   // d = 36
        XCTAssertEqual(bar.largeTitleLabel!.frame.origin.y, 31)  // 67 - 36
        XCTAssertGreaterThan(bar.largeTitleLabel!.alpha, 0)
        XCTAssertLessThan(bar.largeTitleLabel!.alpha, 1)
        XCTAssertGreaterThan(bar.titleLabel.alpha, 0)
        XCTAssertLessThan(bar.titleLabel.alpha, 1)
    }

    func testSnapToNearestRestState() {
        let (nav, scroll) = makeLargeNav()
        // Released inside the large-title zone below halfway: snap back
        // (the animated setContentOffset sets the model immediately).
        scroll.contentOffset = CGPoint(x: 0, y: -116 + 20)
        nav.scrollViewDidEndDragging(scroll, willDecelerate: false)
        XCTAssertEqual(scroll.contentOffset.y, -116)

        // Past halfway: snap collapsed.
        scroll.removeAllAnimations()
        scroll.contentOffset = CGPoint(x: 0, y: -116 + 40)
        nav.scrollViewDidEndDragging(scroll, willDecelerate: false)
        XCTAssertEqual(scroll.contentOffset.y, -116 + 52)
    }

    func testBarPassesTouchesThroughExceptBackButton() {
        let (nav, scroll) = makeLargeNav()
        let bar = nav.navigationBar
        // Transparent chrome: a point in the bar region falls through to
        // the content beneath.
        XCTAssertNil(bar.hitTest(CGPoint(x: 187, y: 30), with: nil))
        let hit = nav.view.hitTest(CGPoint(x: 187, y: 30), with: nil)
        XCTAssertTrue(hit === scroll)
        // Push a child so a back button exists; it takes touches.
        let child = UIViewController()
        child.title = "Detail"
        nav.pushViewController(child, animated: false)
        let back = bar.backButton!
        let inBack = bar.convert(CGPoint(x: back.bounds.midX,
                                         y: back.bounds.midY), from: back)
        XCTAssertNotNil(bar.hitTest(inBack, with: nil))
    }

    /// M13: the inline (non-large-title) bar now uses the MEASURED iOS 26
    /// zone split — 10 pt top padding + a 54 pt content bar, title centre 32
    /// — instead of M7.5's guessed 20 + 44 (title centre 42). The total bar
    /// height is unchanged at 64, so the content area is where it was.
    func testClassicModeUsesMeasuredBarZone() {
        let vc = UIViewController()
        vc.title = "Plain"
        let nav = UINavigationController(rootViewController: vc)
        nav.view.frame = CGRect(x: 0, y: 0, width: 375, height: 480)
        nav.view.layoutIfNeeded()
        // Opaque 64 pt bar above a clipped content area, like before M10.
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 0, width: 375, height: 64))
        XCTAssertNotNil(nav.navigationBar.backgroundColor)
        XCTAssertEqual(vc.view.frame.height, 480 - 64)
        XCTAssertEqual(nav.navigationBar.titleLabel.center.y, 32, accuracy: 1e-9)
    }
}
