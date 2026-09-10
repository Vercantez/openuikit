// M12: the presentation/transitioning API itself — UIPresentationController
// callback ORDER, a custom UIViewControllerTransitioningDelegate replacing
// both the presentation controller and the animators, a custom animator round
// trip driven by a FAKE context, and the UINavigationController animator seam.
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class Trace {
    var entries: [String] = []
    func add(_ s: String) { entries.append(s) }
}

#if !os(Linux)
@MainActor
#endif
private final class RecordingPresentationController: UIPresentationController {
    let trace: Trace
    init(presented: UIViewController, presenting: UIViewController?, trace: Trace) {
        self.trace = trace
        super.init(presentedViewController: presented, presenting: presenting)
    }
    override func presentationTransitionWillBegin() {
        trace.add("presentWill(container=\(containerView != nil))")
        guard let c = containerView else { return }
        presentedViewController.loadViewIfNeeded()
        let v = presentedViewController.view!
        v.frame = frameOfPresentedViewInContainerView
        c.addSubview(v)
    }
    override func presentationTransitionDidEnd(_ completed: Bool) {
        trace.add("presentDid(\(completed))")
    }
    override func dismissalTransitionWillBegin() { trace.add("dismissWill") }
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        trace.add("dismissDid(\(completed))")
        presentedViewController.viewIfLoaded?.removeFromSuperview()
        containerView?.removeFromSuperview()
    }
    override var frameOfPresentedViewInContainerView: CGRect {
        (containerView?.bounds ?? .zero).insetBy(dx: 20, dy: 100)
    }
}

/// A custom animator that just cross-fades and reports what it saw.
#if !os(Linux)
@MainActor
#endif
private final class FadeAnimator: UIViewControllerAnimatedTransitioning {
    let presenting: Bool
    let trace: Trace
    let duration: TimeInterval
    var seenContainer: UIView?
    var seenFinalFrame: CGRect = .zero
    init(presenting: Bool, trace: Trace, duration: TimeInterval = 0.2) {
        self.presenting = presenting
        self.trace = trace
        self.duration = duration
    }
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        seenContainer = ctx.containerView
        let key: UITransitionContextViewKey = presenting ? .to : .from
        let vcKey: UITransitionContextViewControllerKey = presenting ? .to : .from
        guard let v = ctx.view(forKey: key), let vc = ctx.viewController(forKey: vcKey) else {
            trace.add("animate(missing)")
            ctx.completeTransition(false)
            return
        }
        seenFinalFrame = ctx.finalFrame(for: vc)
        trace.add("animate(\(presenting ? "in" : "out"))")
        v.alpha = presenting ? 0 : 1
        UIView.animate(withDuration: duration, animations: {
            v.alpha = self.presenting ? 1 : 0
        }, completion: { _ in
            self.trace.add("animatorDone")
            ctx.completeTransition(true)
        })
    }
    func animationEnded(_ transitionCompleted: Bool) {
        trace.add("animationEnded(\(transitionCompleted))")
    }
}

#if !os(Linux)
@MainActor
#endif
private final class CustomTransitioningDelegate: UIViewControllerTransitioningDelegate {
    let trace: Trace
    var presentation: RecordingPresentationController?
    let presentAnimator: FadeAnimator
    let dismissAnimator: FadeAnimator
    init(trace: Trace) {
        self.trace = trace
        presentAnimator = FadeAnimator(presenting: true, trace: trace)
        dismissAnimator = FadeAnimator(presenting: false, trace: trace)
    }
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let pc = RecordingPresentationController(presented: presented,
                                                 presenting: presenting, trace: trace)
        presentation = pc
        return pc
    }
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentAnimator
    }
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? { dismissAnimator }
}

#if !os(Linux)
@MainActor
#endif
private final class TraceVC: UIViewController {
    required init?(coder: NSCoder) { fatalError() }
    let name: String
    let trace: Trace
    init(name: String, trace: Trace) {
        self.name = name
        self.trace = trace
        super.init()
        title = name
    }
    override func viewWillAppear(_ animated: Bool) { trace.add("\(name).willAppear") }
    override func viewDidAppear(_ animated: Bool) { trace.add("\(name).didAppear") }
    override func viewWillDisappear(_ animated: Bool) { trace.add("\(name).willDisappear") }
    override func viewDidDisappear(_ animated: Bool) { trace.add("\(name).didDisappear") }
}

#if !os(Linux)
@MainActor
#endif
final class PresentationControllerTests: XCTestCase {
    override func setUp() { super.setUp(); OpenUIKitRuntime.animationTime = 0 }
    override func tearDown() { OpenUIKitRuntime.animationTime = 0; super.tearDown() }

    private func step(to t: Double) {
        OpenUIKitRuntime.animationTime = t
        UIView._stepAnimationCompletions(to: t)
    }

    private func makeWindow() -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = UIViewController()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        return (window, base)
    }

    /// The four callbacks, in UIKit's order, around an ANIMATED present and
    /// dismiss, interleaved with the appearance callbacks.
    func testCallbackOrderAcrossAnimatedPresentAndDismiss() {
        let trace = Trace()
        let (_, base) = makeWindow()
        let presented = TraceVC(name: "Sheet", trace: trace)
        let delegate = CustomTransitioningDelegate(trace: trace)
        presented.transitioningDelegate = delegate

        base.present(presented, animated: true)
        XCTAssertEqual(trace.entries,
                       ["presentWill(container=true)", "Sheet.willAppear", "animate(in)"])
        // Nothing else fires until the host clock passes the animation end.
        step(to: 0.1)
        XCTAssertEqual(trace.entries.count, 3)
        step(to: 0.25)
        XCTAssertEqual(trace.entries,
                       ["presentWill(container=true)", "Sheet.willAppear", "animate(in)",
                        "animatorDone", "presentDid(true)", "Sheet.didAppear"])

        trace.entries.removeAll()
        base.dismiss(animated: true)
        XCTAssertEqual(trace.entries, ["Sheet.willDisappear", "dismissWill", "animate(out)"])
        step(to: 0.6)
        XCTAssertEqual(trace.entries,
                       ["Sheet.willDisappear", "dismissWill", "animate(out)",
                        "animatorDone", "dismissDid(true)", "Sheet.didDisappear"])
        XCTAssertNil(base.presentedViewController)
        XCTAssertNil(presented.presentingViewController)
        XCTAssertNil(presented.presentationController)
    }

    /// A NON-animated present must land in the same end state without the
    /// animator ever running (the presentation controller installs the final
    /// chrome state in `presentationTransitionWillBegin`).
    func testNonAnimatedPresentSkipsTheAnimator() {
        let trace = Trace()
        let (_, base) = makeWindow()
        let presented = TraceVC(name: "Sheet", trace: trace)
        let delegate = CustomTransitioningDelegate(trace: trace)
        presented.transitioningDelegate = delegate

        base.present(presented, animated: false)
        XCTAssertEqual(trace.entries,
                       ["presentWill(container=true)", "Sheet.willAppear",
                        "presentDid(true)", "Sheet.didAppear"])
        XCTAssertNil(delegate.presentAnimator.seenContainer)
        trace.entries.removeAll()
        base.dismiss(animated: false)
        XCTAssertEqual(trace.entries,
                       ["Sheet.willDisappear", "dismissWill", "dismissDid(true)",
                        "Sheet.didDisappear"])
        XCTAssertNil(delegate.dismissAnimator.seenContainer)
    }

    /// The custom presentation controller owns the geometry: its
    /// `frameOfPresentedViewInContainerView` is what the presented view gets,
    /// and the animator sees the same rect through the context.
    func testCustomPresentationControllerOwnsGeometry() {
        let trace = Trace()
        let (_, base) = makeWindow()
        let presented = TraceVC(name: "Sheet", trace: trace)
        let delegate = CustomTransitioningDelegate(trace: trace)
        presented.transitioningDelegate = delegate
        base.present(presented, animated: true)
        let expected = CGRect(x: 20, y: 100, width: 353, height: 652)
        XCTAssertEqual(presented.view.frame, expected)
        XCTAssertEqual(delegate.presentAnimator.seenFinalFrame, expected)
        XCTAssertTrue(delegate.presentAnimator.seenContainer === presented.presentationController?.containerView)
        XCTAssertTrue(presented.presentationController === delegate.presentation)
        XCTAssertTrue(delegate.presentation?.presentingViewController === base)
    }

    /// The built-in sheet presentation is still a UIPresentationController and
    /// still produces the M11 geometry (regression guard for the refactor).
    func testBuiltInSheetPresentationControllerGeometry() {
        let (_, base) = makeWindow()
        let sheet = UIViewController()
        sheet.view.backgroundColor = .systemBackground
        base.present(sheet, animated: false)
        let pc = sheet.presentationController as? UISheetPresentationController
        XCTAssertNotNil(pc)
        XCTAssertTrue(pc === sheet.sheetPresentationController)
        XCTAssertEqual(pc?.presentedView === sheet._presentationSheet, true)
        XCTAssertEqual(sheet._presentationSheet?.frame,
                       CGRect(x: 0, y: 59, width: 393, height: 793))
        XCTAssertEqual(sheet._presentationDim?.alpha ?? 0, 0.2, accuracy: 1e-9)
        XCTAssertFalse(pc!.shouldRemovePresentersView)
    }

    /// `prefersGrabberVisible` is normally set BEFORE the presentation
    /// exists, so the grabber has to be installed when the platter joins the
    /// hierarchy — not when the flag is set (regression: the M12 refactor
    /// briefly installed it while the platter was still detached, which
    /// silently dropped it and cost modal_sheet_grabber 0.05 % of pixels,
    /// far too little for the scene threshold to notice).
    func testGrabberInstalledWhenConfiguredBeforePresenting() {
        let (_, base) = makeWindow()
        let sheet = UIViewController()
        sheet.view.backgroundColor = .systemBackground
        sheet.sheetPresentationController?.prefersGrabberVisible = true
        base.present(sheet, animated: false)
        let grabber = sheet._presentationSheet?.subviews
            .compactMap { $0 as? _UISheetGrabber }.first
        XCTAssertNotNil(grabber)
        // MEASURED geometry (real iOS 26.1, 393 pt sheet): 36 x 5 at
        // x 178.5, 5 pt below the sheet's top edge, corner radius 2.5.
        XCTAssertEqual(grabber?.frame, CGRect(x: 178.5, y: 5, width: 36, height: 5))
        XCTAssertEqual(grabber?.layer.cornerRadius ?? 0, 2.5, accuracy: 1e-9)

        // Turning it off while presented removes it again.
        sheet.sheetPresentationController?.prefersGrabberVisible = false
        XCTAssertTrue(sheet._presentationSheet?.subviews
            .compactMap { $0 as? _UISheetGrabber }.isEmpty ?? false)
    }
}

// MARK: - Custom animator against a FAKE context

/// A hand-built context: no presentation at all, just the protocol. This is
/// the contract a third-party animator is written against, so it is tested
/// without any of OpenUIKit's own presentation machinery in the way.
#if !os(Linux)
@MainActor
#endif
private final class FakeContext: UIViewControllerContextTransitioning {
    let containerView: UIView
    let fromVC: UIViewController
    let toVC: UIViewController
    var isAnimated = true
    var isInteractive = false
    var transitionWasCancelled = false
    var completions: [Bool] = []

    init(container: UIView, from: UIViewController, to: UIViewController) {
        containerView = container
        fromVC = from
        toVC = to
    }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? fromVC : toVC
    }
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        (key == .from ? fromVC : toVC).view
    }
    func initialFrame(for vc: UIViewController) -> CGRect {
        vc === toVC ? containerView.bounds.offsetBy(dx: containerView.bounds.width, dy: 0)
                    : containerView.bounds
    }
    func finalFrame(for vc: UIViewController) -> CGRect {
        vc === fromVC ? containerView.bounds.offsetBy(dx: -containerView.bounds.width, dy: 0)
                      : containerView.bounds
    }
    func completeTransition(_ didComplete: Bool) { completions.append(didComplete) }
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
}

/// A slide animator written the way an app would write one.
#if !os(Linux)
@MainActor
#endif
private final class SlideInAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval { 0.3 }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toVC = ctx.viewController(forKey: .to),
              let toView = ctx.view(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }
        toView.frame = ctx.initialFrame(for: toVC)
        ctx.containerView.addSubview(toView)
        UIView.animate(withDuration: transitionDuration(using: ctx), animations: {
            toView.frame = ctx.finalFrame(for: toVC)
        }, completion: { finished in
            ctx.completeTransition(finished)
        })
    }
}

#if !os(Linux)
@MainActor
#endif
final class CustomAnimatorContractTests: XCTestCase {
    override func setUp() { super.setUp(); OpenUIKitRuntime.animationTime = 0 }
    override func tearDown() { OpenUIKitRuntime.animationTime = 0; super.tearDown() }

    func testAnimatorRoundTripThroughAFakeContext() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
        let from = UIViewController()
        let to = UIViewController()
        from.view.frame = container.bounds
        container.addSubview(from.view)
        let ctx = FakeContext(container: container, from: from, to: to)
        let animator = SlideInAnimator()

        XCTAssertEqual(animator.transitionDuration(using: ctx), 0.3, accuracy: 1e-9)
        animator.animateTransition(using: ctx)
        // The animator installed the incoming view in the CONTEXT's container
        // and left the MODEL at the destination; the trailing-edge start is
        // carried by the recorded animation (UIView.animate semantics), which
        // is what the renderer samples for the presentation tree.
        XCTAssertTrue(to.view.superview === container)
        XCTAssertEqual(to.view.frame, container.bounds)
        XCTAssertTrue(ctx.completions.isEmpty)
        let recorded = to.view.animations.first { $0.property == .position }
        XCTAssertNotNil(recorded, "the animator's UIView.animate must record a position animation")
        XCTAssertEqual(recorded?.duration ?? 0, 0.3, accuracy: 1e-9)
        if case .point(let p0)? = recorded?.from {
            XCTAssertEqual(p0.x, 450, accuracy: 1e-9) // centre of the offscreen start
        } else {
            XCTFail("expected a point-valued position animation")
        }

        OpenUIKitRuntime.animationTime = 0.31
        UIView._stepAnimationCompletions(to: 0.31)
        XCTAssertEqual(ctx.completions, [true])
        XCTAssertEqual(to.view.frame, container.bounds)
    }

    /// The navigation controller asks its delegate for an animator and drives
    /// it through the context; the built-in slide is used when it returns nil.
    func testNavigationDelegateAnimatorReplacesTheBuiltInSlide() {
        #if !os(Linux)
        @MainActor
        #endif
        final class NavDelegate: UINavigationControllerDelegate {
            let trace = Trace()
            var animator: FadeAnimator?
            var supply = true
            func navigationController(_ nav: UINavigationController,
                                      animationControllerFor operation: UINavigationController.Operation,
                                      from fromVC: UIViewController,
                                      to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
                trace.add("askFor(\(operation.rawValue))")
                guard supply else { return nil }
                let a = FadeAnimator(presenting: true, trace: trace)
                animator = a
                return a
            }
            func navigationController(_ nav: UINavigationController,
                                      willShow vc: UIViewController, animated: Bool) {
                trace.add("willShow(\(vc.title ?? "?"))")
            }
            func navigationController(_ nav: UINavigationController,
                                      didShow vc: UIViewController, animated: Bool) {
                trace.add("didShow(\(vc.title ?? "?"))")
            }
        }

        let root = UIViewController()
        root.title = "Root"
        let nav = UINavigationController(rootViewController: root)
        nav.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        nav.view.layoutIfNeeded()
        let del = NavDelegate()
        nav.delegate = del

        let pushed = UIViewController()
        pushed.title = "Detail"
        nav.pushViewController(pushed, animated: true)
        XCTAssertEqual(del.trace.entries,
                       ["askFor(1)", "willShow(Detail)", "animate(in)"])
        XCTAssertTrue(del.animator?.seenContainer === nav.contentView)
        XCTAssertTrue(pushed.view.superview === nav.contentView)
        // The built-in slide never ran: no scrim, no active transition record.
        XCTAssertNil(nav.activeTransition)

        OpenUIKitRuntime.animationTime = 0.25
        UIView._stepAnimationCompletions(to: 0.25)
        XCTAssertEqual(del.trace.entries.suffix(3),
                       ["animate(in)", "animatorDone", "didShow(Detail)"])
        XCTAssertNil(root.view.superview)
        XCTAssertEqual(nav.viewControllers.count, 2)

        // With no animator supplied, the built-in slide runs (and records a
        // scrubbable transition).
        del.supply = false
        del.trace.entries.removeAll()
        OpenUIKitRuntime.animationTime = 0
        let third = UIViewController()
        third.title = "Third"
        nav.pushViewController(third, animated: true)
        XCTAssertEqual(del.trace.entries, ["askFor(1)", "willShow(Third)"])
        XCTAssertNotNil(nav.activeTransition)
        XCTAssertEqual(nav.activeTransition?.push, true)
    }
}
