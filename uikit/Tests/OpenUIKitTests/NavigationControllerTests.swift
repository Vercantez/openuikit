// View-controller + navigation tests (M7.5): lazy view loading, appearance
// callback ORDER around push/pop (real UIKit's sequence), host-clock
// transition completion, recorded transition animations (slide + parallax +
// scrim), a rendered mid-transition frame probe, back-button pop and the
// interactive edge-swipe (complete + cancel).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

/// Shared appearance-event log.
#if !os(Linux)
@MainActor
#endif
private final class Log {
    var entries: [String] = []
    func add(_ s: String) { entries.append(s) }
}

#if !os(Linux)
@MainActor
#endif
private class LifecycleVC: UIViewController {
    required init?(coder: NSCoder) { fatalError() }
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

#if !os(Linux)
@MainActor
#endif
private func makeNav(_ root: UIViewController,
                     size: CGSize = CGSize(width: 390, height: 700))
    -> UINavigationController {
    let nav = UINavigationController(rootViewController: root)
    nav.view.frame = CGRect(origin: .zero, size: size)
    nav.view.layoutIfNeeded()
    return nav
}

#if !os(Linux)
@MainActor
#endif
final class ViewControllerLifecycleTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
    }
    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    func testViewLoadsLazilyOnce() {
        let log = Log()
        let vc = LifecycleVC(name: "A", log: log)
        XCTAssertFalse(vc.isViewLoaded)
        XCTAssertNil(vc.viewIfLoaded)
        XCTAssertTrue(log.entries.isEmpty)
        _ = vc.view
        XCTAssertTrue(vc.isViewLoaded)
        XCTAssertEqual(log.entries, ["A.didLoad"])
        _ = vc.view // second access must not reload
        XCTAssertEqual(log.entries, ["A.didLoad"])
        // Default loadView: plain transparent view (programmatic UIKit).
        XCTAssertNil(vc.view.backgroundColor)
    }

    func testRootInstallFiresAppearance() {
        let log = Log()
        let nav = makeNav(LifecycleVC(name: "A", log: log))
        XCTAssertEqual(log.entries, ["A.didLoad", "A.willAppear", "A.didAppear"])
        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertNotNil(nav.viewControllers[0].parent)
        XCTAssertTrue(nav.viewControllers[0].navigationController === nav)
    }

    func testVisibleViewControllerTracksThePublishedStack() {
        let empty = UINavigationController()
        XCTAssertNil(empty.topViewController)
        XCTAssertNil(empty.visibleViewController)

        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        XCTAssertTrue(nav.visibleViewController === root)

        let pushed = UIViewController()
        nav.pushViewController(pushed, animated: false)
        XCTAssertTrue(nav.topViewController === pushed)
        XCTAssertTrue(nav.visibleViewController === pushed)

        XCTAssertTrue(nav.popViewController(animated: false) === pushed)
        XCTAssertTrue(nav.visibleViewController === root)
    }

    func testVisibleViewControllerTracksContainerAndTopChildPresentations() {
        let root = UIViewController()
        let nav = makeNav(root)

        let containerModal = UIViewController()
        nav.present(containerModal, animated: false)
        XCTAssertTrue(nav.presentedViewController === containerModal)
        XCTAssertTrue(nav.visibleViewController === containerModal)
        nav.dismiss(animated: false)
        XCTAssertTrue(nav.visibleViewController === root)

        // UIKit makes the navigation controller the presentation context.
        // OpenUIKit also accepts a direct present call on the top child, so
        // the visibility API must not lose that equivalent ownership shape.
        let childModal = UIViewController()
        root.present(childModal, animated: false)
        XCTAssertTrue(root.presentedViewController === childModal)
        XCTAssertTrue(nav.visibleViewController === childModal)
        root.dismiss(animated: false)
        XCTAssertTrue(nav.visibleViewController === root)
    }

    func testPushLifecycleOrderNonAnimated() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        log.entries.removeAll()
        let b = LifecycleVC(name: "B", log: log)
        nav.pushViewController(b, animated: false)
        // Real UIKit push order: B loads, A.willDisappear, B.willAppear,
        // A.didDisappear, B.didAppear.
        XCTAssertEqual(log.entries, ["B.didLoad", "A.willDisappear",
                                     "B.willAppear", "A.didDisappear",
                                     "B.didAppear"])
        XCTAssertTrue(nav.topViewController === b)
        XCTAssertNil(a.view.superview)         // outgoing view detached
        XCTAssertNotNil(b.view.superview)
    }

    func testPopLifecycleOrderNonAnimated() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        let b = LifecycleVC(name: "B", log: log)
        nav.pushViewController(b, animated: false)
        log.entries.removeAll()
        let popped = nav.popViewController(animated: false)
        XCTAssertTrue(popped === b)
        XCTAssertEqual(log.entries, ["B.willDisappear", "A.willAppear",
                                     "B.didDisappear", "A.didAppear"])
        XCTAssertNil(b.parent)
        XCTAssertTrue(nav.topViewController === a)
    }

    func testAnimatedPushCompletesOnHostClock() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        log.entries.removeAll()
        let b = LifecycleVC(name: "B", log: log)
        OpenUIKitRuntime.animationTime = 1.0
        nav.pushViewController(b, animated: true)
        // "will" callbacks fire at push time; "did" wait for the clock.
        XCTAssertEqual(log.entries, ["B.didLoad", "A.willDisappear", "B.willAppear"])
        XCTAssertNotNil(a.view.superview) // outgoing still visible mid-flight
        XCTAssertTrue(UINavigationController._hasActiveTransition)

        UINavigationController._stepTransitions(to: 1.2) // mid-transition
        XCTAssertEqual(log.entries, ["B.didLoad", "A.willDisappear", "B.willAppear"])

        UINavigationController._stepTransitions(to: 1.0 + 0.35)
        XCTAssertEqual(log.entries, ["B.didLoad", "A.willDisappear",
                                     "B.willAppear", "A.didDisappear",
                                     "B.didAppear"])
        XCTAssertNil(a.view.superview)
        XCTAssertFalse(UINavigationController._hasActiveTransition)
        // Bar settled on the new title with the previous title as back label.
        XCTAssertEqual(nav.navigationBar.titleLabel.text, "B")
        XCTAssertEqual(nav.navigationBar.backButton?.backLabel.text, "A")
    }

    func testAnimatedPushRecordsSpecTransitionAnimations() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        let b = LifecycleVC(name: "B", log: log)
        OpenUIKitRuntime.animationTime = 0
        nav.pushViewController(b, animated: true)

        let w = nav.contentView.bounds.width
        let mid = nav.contentView.bounds.midX

        // Incoming: slides +width -> 0.
        guard let bAnim = b.view.animations.first(where: { $0.property == .position }),
              case .point(let bFrom) = bAnim.from,
              case .point(let bTo) = bAnim.to else {
            return XCTFail("incoming position animation missing")
        }
        XCTAssertEqual(bFrom.x, mid + w, accuracy: 1e-9)
        XCTAssertEqual(bTo.x, mid, accuracy: 1e-9)
        XCTAssertEqual(bAnim.duration, 0.35, accuracy: 1e-12)
        guard case .curve(let c1x, let c1y, let c2x, let c2y) = bAnim.timing else {
            return XCTFail("expected bezier timing")
        }
        // UIKit's transition curve ≈ easeInOut (0.42, 0, 0.58, 1).
        XCTAssertEqual([c1x, c1y, c2x, c2y], [0.42, 0, 0.58, 1])

        // Outgoing: parallax 0 -> -0.3 * width.
        guard let aAnim = a.view.animations.first(where: { $0.property == .position }),
              case .point(let aFrom) = aAnim.from,
              case .point(let aTo) = aAnim.to else {
            return XCTFail("outgoing position animation missing")
        }
        XCTAssertEqual(aFrom.x, mid, accuracy: 1e-9)
        XCTAssertEqual(aTo.x, mid - 0.3 * w, accuracy: 1e-9)

        // Scrim: black overlay above the outgoing view, alpha 0 -> 0.08.
        guard let t = nav.activeTransition else { return XCTFail("no transition") }
        guard let sAnim = t.scrim.animations.first(where: { $0.property == .alpha }),
              case .scalar(let s0) = sAnim.from,
              case .scalar(let s1) = sAnim.to else {
            return XCTFail("scrim alpha animation missing")
        }
        XCTAssertEqual(s0, 0, accuracy: 1e-9)
        XCTAssertEqual(s1, 0.08, accuracy: 1e-9)
        let subs = nav.contentView.subviews
        XCTAssertEqual(subs.count, 3)
        XCTAssertTrue(subs[0] === a.view && subs[1] === t.scrim && subs[2] === b.view)

        // Incoming leading-edge shadow present mid-flight, cleared at end.
        XCTAssertGreaterThan(b.view.layer.shadowOpacity, 0)
        UINavigationController._stepTransitions(to: 0.35)
        XCTAssertEqual(b.view.layer.shadowOpacity, 0)
        XCTAssertTrue(b.view.animations.isEmpty) // cleaned up
    }

    func testMidTransitionRenderedFrame() {
        // Red root, green pushed VC. At t = 0.15 the rendered frame must
        // show: green from the incoming edge rightward, scrim-darkened red
        // on the left (black at 8% x eased progress).
        let root = UIViewController()
        root.loadViewIfNeeded()
        root.view.backgroundColor = .red
        let nav = makeNav(root, size: CGSize(width: 200, height: 260))
        let vc = UIViewController()
        vc.loadViewIfNeeded()
        vc.view.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        OpenUIKitRuntime.animationTime = 0
        nav.pushViewController(vc, animated: true)

        guard let anim = vc.view.animations.first(where: { $0.property == .position })
        else { return XCTFail("no incoming animation") }
        OpenUIKitRuntime.animationTime = 0.15
        defer { OpenUIKitRuntime.animationTime = 0 }
        let u = LayerBridge.animationProgress(anim, at: 0.15)
        XCTAssertGreaterThan(u, 0.2)   // sanity: eased progress at 3/7 of the way
        XCTAssertLessThan(u, 0.6)

        let bmp = UIRenderer.render(nav.view, scale: 1)
        XCTAssertEqual(bmp.width, 200)
        func px(_ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int) {
            let i = (y * bmp.width + x) * 4
            return (Int(bmp.pixels[i]), Int(bmp.pixels[i + 1]), Int(bmp.pixels[i + 2]))
        }
        let edge = Double(200 * (1 - u))
        let y = 150 // inside the content area (bar is 64pt tall)

        // Right of the edge: the incoming green view.
        let g = px(Swift.min(199, Int(edge.rounded()) + 6), y)
        XCTAssertEqual(g.g, 255)
        XCTAssertEqual(g.r, 0)

        // Left: red under the scrim (black at 0.08 * u).
        let r = px(4, y)
        let expectedRed = (255.0 * (1 - 0.08 * Double(u))).rounded()
        XCTAssertEqual(Double(r.r), expectedRed, accuracy: 3)
        XCTAssertEqual(r.g, 0)
        XCTAssertEqual(r.b, 0)
    }

    func testBackButtonTapPops() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let nav = makeNav(a)
        window.addSubview(nav.view)
        window.layoutIfNeeded()
        nav.pushViewController(LifecycleVC(name: "B", log: log), animated: false)
        XCTAssertEqual(nav.viewControllers.count, 2)
        XCTAssertEqual(nav.navigationBar.backButton?.backLabel.text, "A")

        OpenUIKitRuntime.animationTime = 5.0
        window.sendTouch(.began, at: CGPoint(x: 40, y: 42), timestamp: 5.0)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 42), timestamp: 5.08)
        XCTAssertTrue(UINavigationController._hasActiveTransition)
        window.tick(timestamp: 5.5) // host clock passes the pop end
        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertTrue(nav.topViewController === a)
        XCTAssertEqual(log.entries.suffix(2), ["B.didDisappear", "A.didAppear"])
        OpenUIKitRuntime.animationTime = 0
    }

    func testInteractiveBackSwipeCompletes() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let nav = makeNav(a)
        window.addSubview(nav.view)
        window.layoutIfNeeded()
        let b = LifecycleVC(name: "B", log: log)
        nav.pushViewController(b, animated: false)
        log.entries.removeAll()

        // Left-edge drag, released with a strong forward fling.
        window.sendTouch(.began, at: CGPoint(x: 10, y: 300), timestamp: 1.00)
        window.sendTouch(.moved, at: CGPoint(x: 25, y: 300), timestamp: 1.02)
        XCTAssertNotNil(nav.activeTransition)
        XCTAssertEqual(log.entries, ["B.willDisappear", "A.willAppear"])
        window.sendTouch(.moved, at: CGPoint(x: 130, y: 300), timestamp: 1.05)
        // Scrubbing writes MODEL positions directly.
        let w = nav.contentView.bounds.width
        let p = (130.0 - 10.0) / w
        XCTAssertEqual(b.view.center.x, nav.contentView.bounds.midX + w * p,
                       accuracy: 0.5)
        window.sendTouch(.moved, at: CGPoint(x: 330, y: 300), timestamp: 1.10)
        OpenUIKitRuntime.animationTime = 1.11
        window.sendTouch(.ended, at: CGPoint(x: 330, y: 300), timestamp: 1.11)
        // Released: spring tail scheduled, stack not yet mutated.
        XCTAssertEqual(nav.viewControllers.count, 2)
        XCTAssertTrue(UINavigationController._hasActiveTransition)
        window.tick(timestamp: 1.11 + 0.4)
        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertTrue(nav.topViewController === a)
        XCTAssertNil(b.parent)
        XCTAssertEqual(log.entries, ["B.willDisappear", "A.willAppear",
                                     "B.didDisappear", "A.didAppear"])
        OpenUIKitRuntime.animationTime = 0
    }

    func testInteractiveBackSwipeCancels() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let nav = makeNav(a)
        window.addSubview(nav.view)
        window.layoutIfNeeded()
        let b = LifecycleVC(name: "B", log: log)
        nav.pushViewController(b, animated: false)
        log.entries.removeAll()

        // Short, slow drag (progress < 50%, velocity below threshold).
        window.sendTouch(.began, at: CGPoint(x: 8, y: 300), timestamp: 2.00)
        window.sendTouch(.moved, at: CGPoint(x: 24, y: 300), timestamp: 2.05)
        window.sendTouch(.moved, at: CGPoint(x: 40, y: 300), timestamp: 2.30)
        OpenUIKitRuntime.animationTime = 2.31
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 300), timestamp: 2.31)
        window.tick(timestamp: 2.31 + 0.4)
        // Snapped back: stack unchanged, reversed appearance calls, view
        // restored to center, revealed view removed again.
        XCTAssertEqual(nav.viewControllers.count, 2)
        XCTAssertTrue(nav.topViewController === b)
        XCTAssertEqual(log.entries, ["B.willDisappear", "A.willAppear",
                                     "A.willDisappear", "A.didDisappear",
                                     "B.willAppear", "B.didAppear"])
        XCTAssertEqual(b.view.center.x, nav.contentView.bounds.midX, accuracy: 1e-9)
        XCTAssertNil(a.view.superview)
        XCTAssertEqual(nav.navigationBar.titleLabel.text, "B")
        OpenUIKitRuntime.animationTime = 0
    }

    func testEdgePanIgnoredAwayFromEdge() {
        let log = Log()
        let nav = makeNav(LifecycleVC(name: "A", log: log))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.addSubview(nav.view)
        window.layoutIfNeeded()
        nav.pushViewController(LifecycleVC(name: "B", log: log), animated: false)
        window.sendTouch(.began, at: CGPoint(x: 120, y: 300), timestamp: 3.0)
        window.sendTouch(.moved, at: CGPoint(x: 220, y: 300), timestamp: 3.05)
        window.sendTouch(.ended, at: CGPoint(x: 220, y: 300), timestamp: 3.10)
        XCTAssertNil(nav.activeTransition)
        XCTAssertEqual(nav.viewControllers.count, 2)
    }

    func testTitleChangeUpdatesBar() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        XCTAssertEqual(nav.navigationBar.titleLabel.text, "A")
        a.title = "Renamed"
        XCTAssertEqual(nav.navigationBar.titleLabel.text, "Renamed")
    }

    func testPreemptedTransitionFinishesBeforeNext() {
        let log = Log()
        let a = LifecycleVC(name: "A", log: log)
        let nav = makeNav(a)
        let b = LifecycleVC(name: "B", log: log)
        let c = LifecycleVC(name: "C", log: log)
        OpenUIKitRuntime.animationTime = 0
        nav.pushViewController(b, animated: true)
        // Second push lands mid-flight: the first must complete instantly.
        nav.pushViewController(c, animated: true)
        XCTAssertEqual(nav.viewControllers.count, 3)
        XCTAssertNil(a.view.superview)
        XCTAssertNotNil(b.view.superview) // now the outgoing view of push #2
        UINavigationController._stepTransitions(to: 0.35)
        XCTAssertTrue(nav.topViewController === c)
        XCTAssertNil(b.view.superview)
        XCTAssertEqual(log.entries.suffix(2), ["B.didDisappear", "C.didAppear"])
    }
}
