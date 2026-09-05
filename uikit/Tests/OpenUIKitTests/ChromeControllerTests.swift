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
        // Binding settles at the expanded rest offset. The 116 pt is SAFE
        // AREA (NavFlow t3000, iPhone SE 2x, iOS 26.1: contentInset [0,0,0,0],
        // safeAreaInsets.top 116), not a contentInset.
        XCTAssertEqual(scroll.contentInset.top, 0)
        XCTAssertEqual(scroll.adjustedContentInset.top, 116)
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

// MARK: - iOS 26 bar transition (Tools/oracle2/navprobe)

/// The push/pop bar behaviour MEASURED with Tools/oracle2/navprobe on the
/// iPhone 16 / iOS 26.1: the bar's title content translates with its own view
/// controller instead of cross-fading in place, and the controller that
/// arrives owns the large title.
@MainActor
final class IOSNavigationBarTransitionTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut = .macOS

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    private func makeNav(largeTitles: Bool) -> UINavigationController {
        let root = UIViewController()
        root.title = "Settings"
        root.view.backgroundColor = .systemBackground
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = largeTitles
        nav.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        nav.view.layoutIfNeeded()
        return nav
    }

    /// navprobe.large / navprobe.inline, push: the incoming side sits at
    /// w(1 - q) full width, the outgoing side at -0.3 w q clipped to the
    /// incoming leading edge, both at alpha 1. Sample from the recording
    /// (q = 0.4587): outgoing x -53.67 w 264.76, incoming x 211.09 — and
    /// -53.67 + 264.76 = 211.09.
    func testPushTranslatesBarContentWithItsController() {
        for largeTitles in [true, false] {
            let nav = makeNav(largeTitles: largeTitles)
            let bar = nav.navigationBar
            let detail = UIViewController()
            detail.title = "About"
            bar.beginTransition(title: "About", backTitle: "Settings", push: true)
            let t = bar.transition!
            let old = t.oldGroup!, new = t.newGroup!
            let w: CGFloat = 390

            bar.setTransitionProgress(0)
            XCTAssertEqual(new.frame.origin.x, w)
            XCTAssertEqual(old.frame, CGRect(x: 0, y: 0, width: w, height: bar.bounds.height))

            for q: CGFloat in [0.25, 0.4587, 0.8] {
                bar.setTransitionProgress(q)
                XCTAssertEqual(new.frame.origin.x, w * (1 - q), accuracy: 1e-6)
                XCTAssertEqual(new.frame.width, w, accuracy: 1e-6)
                XCTAssertEqual(old.frame.origin.x, -0.3 * w * q, accuracy: 1e-6)
                XCTAssertEqual(old.frame.maxX, new.frame.origin.x, accuracy: 1e-6)
                XCTAssertEqual(old.alpha, 1)
                XCTAssertEqual(new.alpha, 1)
                XCTAssertTrue(old.clipsToBounds)
            }
            _ = detail
        }
    }

    /// The pop is the same relation with the roles swapped: the outgoing
    /// (popped) controller is the one on top. Recording sample, q = 0.6994:
    /// outgoing x 117.25 w 390, incoming x -81.83 w 199.08 -> right edge
    /// 117.25.
    func testPopTranslatesBarContentWithItsController() {
        let nav = makeNav(largeTitles: true)
        let bar = nav.navigationBar
        bar.beginTransition(title: "Settings", backTitle: nil, push: false)
        let t = bar.transition!
        let old = t.oldGroup!, new = t.newGroup!
        let w: CGFloat = 390
        for p: CGFloat in [0, 0.3006, 0.7] {
            bar.setTransitionProgress(p)
            let q = 1 - p
            XCTAssertEqual(old.frame.origin.x, w * (1 - q), accuracy: 1e-6)
            XCTAssertEqual(old.frame.width, w, accuracy: 1e-6)
            XCTAssertEqual(new.frame.origin.x, -0.3 * w * q, accuracy: 1e-6)
            XCTAssertEqual(new.frame.maxX, old.frame.origin.x, accuracy: 1e-6)
        }
    }

    /// The large title travels inside the group with its controller's title,
    /// at the same vertical rest position on both sides (recording: abs y
    /// 123.00 at every frame of the push).
    func testBothLargeTitlesRideTheirGroups() {
        let nav = makeNav(largeTitles: true)
        let bar = nav.navigationBar
        bar.beginTransition(title: "About", backTitle: "Settings", push: true)
        let t = bar.transition!
        XCTAssertEqual(t.oldLarge?.text, "Settings")
        XCTAssertEqual(t.newLarge?.text, "About")
        XCTAssertTrue(t.oldLarge?.superview === t.oldGroup)
        XCTAssertTrue(t.newLarge?.superview === t.newGroup)
        XCTAssertEqual(t.oldLarge?.frame.origin.y, UINavigationBar.largeTitleLabelY)
        XCTAssertEqual(t.newLarge?.frame.origin.y, UINavigationBar.largeTitleLabelY)
        XCTAssertEqual(t.oldLarge?.frame.origin.x, UINavigationBar.largeTitleX)
        XCTAssertEqual(t.newLarge?.frame.origin.x, UINavigationBar.largeTitleX)
    }

    /// MEASURED (navprobe.large rest_pushed): a controller pushed with the
    /// default `largeTitleDisplayMode` (.automatic) shows the LARGE title —
    /// the bar's label reads "About" at [16, 3.67, 97, 40.67] while the
    /// inline title stays at alpha 0. Before this the port's large title kept
    /// the root's text for the rest of the run.
    func testPushedControllerOwnsTheLargeTitle() {
        let nav = makeNav(largeTitles: true)
        let bar = nav.navigationBar
        XCTAssertEqual(bar.largeTitleLabel?.text, "Settings")
        let detail = UIViewController()
        detail.title = "About"
        XCTAssertEqual(detail.navigationItem.largeTitleDisplayMode, .automatic)
        nav.pushViewController(detail, animated: true)
        nav.finishActiveTransition()
        XCTAssertEqual(bar.largeTitleLabel?.text, "About")
        XCTAssertTrue(bar.largeTitleLabel?.superview === bar)
        XCTAssertEqual(bar.largeTitleLabel?.alpha, 1)
        XCTAssertNil(bar.transition)

        nav.popViewController(animated: true)
        nav.finishActiveTransition()
        XCTAssertEqual(bar.largeTitleLabel?.text, "Settings")
    }

    /// The back button does not travel: the recording has the platter at
    /// x 16.0 on every frame of both transitions, in both variants.
    func testBackButtonDoesNotTranslate() {
        let nav = makeNav(largeTitles: true)
        let bar = nav.navigationBar
        bar.beginTransition(title: "About", backTitle: "Settings", push: true)
        let back = bar.transition!.newBack!
        var seen: Set<CGFloat> = []
        for p: CGFloat in [0, 0.25, 0.5, 0.75, 1] {
            bar.setTransitionProgress(p)
            seen.insert(back.frame.origin.x)
        }
        XCTAssertEqual(seen, [0])
    }

    private func makeLargeScrollNav(offset: CGFloat? = nil) -> (UINavigationController, UIScrollView) {
        let vc = UIViewController()
        vc.title = "Library"
        vc.view.backgroundColor = .systemGroupedBackground
        let scroll = UIScrollView(frame: vc.view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentSize = CGSize(width: 390, height: 1200)
        vc.view.addSubview(scroll)
        vc.setContentScrollView(scroll)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        nav.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        nav.view.layoutIfNeeded()
        if let offset { scroll.contentOffset = CGPoint(x: 0, y: offset) }
        return (nav, scroll)
    }

    /// MEASURED 2026-09-04, navprobe.scroll rest samples, iPhone 16 / iOS 26.1:
    /// the 34 pt title translates 1:1 and stays alpha 1 through d = 51; the
    /// inline title stays at effective 0. No font scale (identity transform,
    /// pointSize 34 at every offset).
    func testIOSCollapseKeepsTitlesOpaqueUntilTheZone() {
        let (nav, scroll) = makeLargeScrollNav()
        let bar = nav.navigationBar
        XCTAssertEqual(scroll.contentOffset.y, -116)
        XCTAssertEqual(bar.largeTitleLabel!.alpha, 1)
        XCTAssertEqual(bar.titleLabel.alpha, 0)
        XCTAssertEqual(bar.frame.origin.y, 10)
        XCTAssertEqual(bar.frame.height, 106)
        XCTAssertEqual(bar.largeTitleLabel!.font.pointSize, 34)

        scroll.contentOffset = CGPoint(x: 0, y: -116 + 36)
        XCTAssertEqual(bar.largeTitleLabel!.frame.origin.y, 57.5 - 36, accuracy: 1e-9)
        XCTAssertEqual(bar.largeTitleLabel!.alpha, 1)
        XCTAssertEqual(bar.titleLabel.alpha, 0)
        XCTAssertEqual(bar.largeTitleLabel!.font.pointSize, 34)
        XCTAssertEqual(bar.frame.height, 106)
    }

    /// At d = 52 the bar snaps to the 64 pt overlay, the large title is
    /// gone and the inline title is in (navprobe.scroll d052).
    func testIOSCollapseSnapsTitlesAndBarHeightAtTheZone() {
        let (nav, _) = makeLargeScrollNav(offset: -116 + 52)
        let bar = nav.navigationBar
        XCTAssertEqual(bar.largeTitleLabel!.alpha, 0)
        XCTAssertEqual(bar.titleLabel.alpha, 1)
        XCTAssertEqual(bar.frame.height, UINavigationBar.iOSCollapsedBarHeight)
    }

    /// MEASURED 2026-09-04, suite golden `navbar_inline` (SE 2x / iOS 26.1):
    /// `ScrollEdgeEffectView` starts at the container origin. The 72 pt
    /// pocket is a bar subview, so it sits at y = −bar.y (= −10 when SA is 0).
    func testIOSCollapsedPocketStartsAtContainerOrigin() {
        let (nav, _) = makeLargeScrollNav(offset: 160)
        let bar = nav.navigationBar
        XCTAssertFalse(bar.pocketView.isHidden)
        XCTAssertEqual(bar.frame.origin.y, 10)
        XCTAssertEqual(bar.pocketView.frame,
                       CGRect(x: 0, y: -10, width: 390,
                              height: UINavigationBar.pocketHeight))
    }

    /// MEASURED 2026-09-04, probe_scroll_edge_white, iPhone SE 2x / iOS 26.1:
    /// red|green edge under the collapsed bar, y = 8…20: 10–90 % mix is 5 pt,
    /// erf fit σ = 1.85. Catalyst keeps the 8 pt navbar_inline kernel.
    func testIOSPocketBlurSigmaIsTheMeasuredEdge() {
        XCTAssertEqual(UINavigationBar.pocketBlurSigma, 1.85)
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .macOS
        XCTAssertEqual(UINavigationBar.pocketBlurSigma, 8)
        OpenUIKitRuntime.systemFontCut = saved
    }

    /// Zero-velocity release: d = 36 expands, d = 37 collapses
    /// (navprobe.scroll hold_d36 / hold_d37).
    func testIOSSnapThresholdIs36() {
        let (nav, scroll) = makeLargeScrollNav()
        scroll.contentOffset = CGPoint(x: 0, y: -116 + 36)
        nav.scrollViewDidEndDragging(scroll, willDecelerate: false)
        XCTAssertEqual(scroll.contentOffset.y, -116)

        scroll.removeAllAnimations()
        scroll.contentOffset = CGPoint(x: 0, y: -116 + 37)
        nav.scrollViewDidEndDragging(scroll, willDecelerate: false)
        nav.view.layoutIfNeeded()
        // Snap writes y = 52 − 116 = −64; the collapse shrinks
        // safeArea.top 116 → 64 and rebases +52 → −12
        // (probe_collapse_rebase sv.set.-64).
        XCTAssertEqual(scroll.contentOffset.y, -12, accuracy: 0.5)
    }

    /// MEASURED 2026-09-04, probe_collapse_rebase + Feed t2800,
    /// iPhone SE 2x / iOS 26.1: a programmatic setContentOffset past
    /// collapse distance 52 rebases y by +52 when the large-title overlay
    /// shrinks (adj 116 → 64). Same numbers on UIScrollView and
    /// UICollectionView, and on a plain scroll view whose
    /// additionalSafeAreaInsets.top shrinks 116 → 64 with no nav bar.
    func testIOSSafeAreaTopShrinkRebasesOffset() {
        let (nav, scroll) = makeLargeScrollNav()
        XCTAssertEqual(scroll.contentOffset.y, -116, accuracy: 0.5)
        XCTAssertEqual(scroll.adjustedContentInset.top, 116, accuracy: 0.5)

        scroll.setContentOffset(CGPoint(x: 0, y: -65), animated: false)
        nav.view.layoutIfNeeded()
        XCTAssertEqual(scroll.contentOffset.y, -65, accuracy: 0.5)
        XCTAssertEqual(scroll.adjustedContentInset.top, 116, accuracy: 0.5)
        XCTAssertEqual(nav.navigationBar.frame.height, 106, accuracy: 0.5)

        scroll.setContentOffset(CGPoint(x: 0, y: -116), animated: false)
        nav.view.layoutIfNeeded()
        scroll.setContentOffset(CGPoint(x: 0, y: 300), animated: false)
        nav.view.layoutIfNeeded()
        XCTAssertEqual(scroll.contentOffset.y, 352, accuracy: 0.5)
        XCTAssertEqual(scroll.adjustedContentInset.top, 64, accuracy: 0.5)
        XCTAssertEqual(nav.navigationBar.frame.height, 54, accuracy: 0.5)

        scroll.setContentOffset(CGPoint(x: 0, y: 160), animated: false)
        nav.view.layoutIfNeeded()
        XCTAssertEqual(scroll.contentOffset.y, 160, accuracy: 0.5)
        XCTAssertEqual(scroll.adjustedContentInset.top, 64, accuracy: 0.5)

        let vc = UIViewController()
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        sv.contentSize = CGSize(width: 375, height: 2400)
        vc.view.addSubview(sv)
        vc.additionalSafeAreaInsets.top = 116
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        vc.view.layoutIfNeeded()
        sv.setContentOffset(CGPoint(x: 0, y: 300), animated: false)
        vc.view.layoutIfNeeded()
        XCTAssertEqual(sv.contentOffset.y, 300, accuracy: 0.5)
        XCTAssertEqual(sv.adjustedContentInset.top, 116, accuracy: 0.5)
        vc.additionalSafeAreaInsets.top = 64
        vc.view.layoutIfNeeded()
        XCTAssertEqual(sv.contentOffset.y, 352, accuracy: 0.5)
        XCTAssertEqual(sv.adjustedContentInset.top, 64, accuracy: 0.5)
    }

    /// MEASURED 2026-09-04, navprobe.barorigin hide_sa0, iPhone SE 2x /
    /// iOS 26.1, window safeAreaInsets.top 0: the bar sits at y 10 with
    /// height 54 (inline) / 106 (large), the child fills the container, and
    /// the child's safeAreaInsets.top is the overlay (64 / 116). The inline
    /// title's HostedViewWrapper is y 11.5 (center 22) when the large title
    /// is off, and y 26.5 (center 37, alpha 0) while it shows.
    func testIOSBarOriginIsTenWhenSafeAreaTopIsZero() {
        let inline = makeNav(largeTitles: false)
        XCTAssertEqual(inline.navigationBar.frame,
                       CGRect(x: 0, y: 10, width: 390, height: 54))
        XCTAssertEqual(inline.contentView.frame.origin, .zero)
        XCTAssertEqual(inline.contentView.frame.size, CGSize(width: 390, height: 700))
        XCTAssertEqual(inline.topViewController!.view.safeAreaInsets.top, 64)
        XCTAssertEqual(inline.navigationBar.titleLabel.center.y, 22, accuracy: 0.01)
        XCTAssertEqual(inline.navigationBar.titleLabel.alpha, 1)

        let large = makeNav(largeTitles: true)
        XCTAssertEqual(large.navigationBar.frame,
                       CGRect(x: 0, y: 10, width: 390, height: 106))
        XCTAssertEqual(large.topViewController!.view.safeAreaInsets.top, 116)
        XCTAssertEqual(large.navigationBar.largeTitleLabel!.frame.origin.y, 57.5,
                       accuracy: 1e-9)
        XCTAssertEqual(large.navigationBar.titleLabel.center.y, 37, accuracy: 0.01)
        XCTAssertEqual(large.navigationBar.titleLabel.alpha, 0)
    }

    /// MEASURED NavFlow t200.landscape / t3000.landscape, iPhone SE 2x /
    /// iOS 26.1: compact height collapses large titles to the 54 pt inline
    /// bar at y **24** (table SA top 78 = 24+54). `prefersLargeTitles`
    /// stays true. Portrait y=10 / height 106 is unchanged.
    func testCompactHeightCollapsesLargeTitlesAndRaisesBarTop() {
        let savedTraits = UITraitCollection.current
        let savedBounds = UIScreen.main.bounds
        let savedScale = UIScreen.main.scale
        defer {
            UITraitCollection.current = savedTraits
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact)
        UIScreen.main._hostConfigure(
            bounds: CGRect(x: 0, y: 0, width: 667, height: 375), scale: 2)
        let root = UIViewController()
        root.title = "Library"
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.view.frame = CGRect(x: 0, y: 0, width: 667, height: 375)
        nav.view.layoutIfNeeded()
        XCTAssertTrue(nav.navigationBar.prefersLargeTitles)
        XCTAssertFalse(nav.navigationBar.displaysLargeTitles)
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 24, width: 667, height: 54))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 78)
        XCTAssertNil(nav.navigationBar.largeTitleLabel)
        XCTAssertEqual(nav.navigationBar.titleLabel.center.y, 22, accuracy: 0.01)
        XCTAssertEqual(nav.navigationBar.titleLabel.alpha, 1)
    }

    /// Same probe, hide_add59 / iPhone 16 window SA 59: y follows the inset
    /// (not 10 + inset). Overlay = y + height = 113 inline, 165 large.
    func testIOSBarOriginFollowsSafeAreaTopAboveTheFloor() {
        let nav = makeNav(largeTitles: false)
        nav.view._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 59, width: 390, height: 54))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 113)
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.bottom, 34)

        nav.navigationBar.prefersLargeTitles = true
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 59, width: 390, height: 106))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 165)
    }

    /// A 20 pt status bar (SE, status bar shown; also additionalSafeAreaInsets
    /// 20 on a zero-SA window) is the same rule: y = 20, overlay 74 / 126.
    func testIOSBarOriginMatchesAStatusBarSafeArea() {
        let nav = makeNav(largeTitles: true)
        nav.view._setSafeAreaInsets(UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0))
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 20, width: 390, height: 106))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 126)
        XCTAssertEqual(nav.navigationBar.titleLabel.center.y, 37, accuracy: 0.01)
    }

    /// Forms t200, iPhone SE 2x, iOS 26.1: an inline bar with no explicit
    /// appearance is transparent at rest, and the child fills the container
    /// (underlaps), reporting safeAreaInsets.top = 64. Catalyst keeps the
    /// opaque bar above a clipped content area (`testClassicModeUsesMeasuredBarZone`).
    func testIOSInlineBarIsTransparentAndContentUnderlaps() {
        let nav = makeNav(largeTitles: false)
        XCTAssertNil(nav.navigationBar.backgroundColor)
        XCTAssertEqual(nav.navigationBar.standardAppearance._configuration, .default)
        XCTAssertEqual(nav.contentView.frame,
                       CGRect(x: 0, y: 0, width: 390, height: 700))
        XCTAssertEqual(nav.topViewController!.view.frame,
                       CGRect(x: 0, y: 0, width: 390, height: 700))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 64)
        XCTAssertEqual(nav.navigationBar.frame.height, 54)   // bar-origin probe: 54 at y 10
        XCTAssertEqual(nav.navigationBar.titleLabel.center.y, 22, accuracy: 1e-9)   // bar-local 11.5 + 10.5
    }

    /// MEASURED realapp_focus_settings_light, iPhone 16 / iOS 26.1:
    /// `navigationBar.isTranslucent = false` insets the child below the bar
    /// at y 59 h 54 (content `[0, 113, 393, 739]`) with child
    /// `safeAreaInsets` `[0,0,34,0]` — bottom home-indicator only.
    func testIOSOpaqueBarInsetsContentBelowTheBar() {
        let nav = makeNav(largeTitles: false)
        nav.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        nav.view._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        nav.navigationBar.isTranslucent = false
        nav.view.layoutIfNeeded()
        XCTAssertNil(nav.view.backgroundColor)
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 59, width: 393, height: 54))
        XCTAssertEqual(nav.contentView.frame,
                       CGRect(x: 0, y: 113, width: 393, height: 739))
        XCTAssertEqual(nav.topViewController!.view.frame,
                       CGRect(x: 0, y: 0, width: 393, height: 739))
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.top, 0)
        XCTAssertEqual(nav.topViewController!.view.safeAreaInsets.bottom, 34)
    }

    /// Catalyst keeps the M7.5 cross-fade: no groups, and the old title
    /// morphs toward the back-button position.
    func testCatalystKeepsTheCrossFade() {
        OpenUIKitRuntime.systemFontCut = .macOS
        let nav = makeNav(largeTitles: false)
        let bar = nav.navigationBar
        bar.beginTransition(title: "About", backTitle: "Settings", push: true)
        XCTAssertNil(bar.transition?.oldGroup)
        XCTAssertNil(bar.transition?.newGroup)
        bar.setTransitionProgress(0.5)
        XCTAssertEqual(bar.transition!.oldTitle.alpha, 0.5, accuracy: 1e-9)
        XCTAssertEqual(bar.transition!.newTitle.alpha, 0.5, accuracy: 1e-9)
    }
}
