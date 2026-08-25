// UINavigationController. Owner: viewcontroller module (M7.5 navigation).
//
// Container layout: navigation bar (20pt status inset + 44pt content, see
// UINavigationBar) above a clipped content area; child VC views fill the
// content area (autoresized).
//
// Push transition per docs/APP_FEEL.md (0.35s, UIKit's transition curve ≈
// easeInOut, driven through UIView.animate so frames are deterministic and
// capture-able):
//   - incoming view slides +width -> 0,
//   - outgoing view slides 0 -> -0.3 * width underneath (parallax),
//   - a black scrim over the outgoing view fades 0 -> 8%,
//   - the incoming leading edge carries a soft ~9pt shadow (CALayer shadow:
//     sigma 4.5pt -> visible falloff ≈ 9pt, black at opacity 0.15).
// Pop is the exact reverse. The navigation bar crossfades/slides its titles
// with the same progress (UINavigationBar.setTransitionProgress).
//
// Completion model: the portable core has no run loop, and UIView.animate
// completions run synchronously (KNOWN_GAPS) — so transition CLEANUP (remove
// the outgoing view + scrim, fire viewDidDisappear/viewDidAppear) is driven
// by the host clock: UIWindow.tick(timestamp:) calls
// UINavigationController._stepTransitions(to:), the same pattern as
// UIScrollView's deceleration stepping. A host that renders without ticking
// keeps showing the transition's final frame (presentation clamps at the
// model); the stack/lifecycle finish on the first tick at/after the end time.
//
// Interactive back-swipe: a left-edge (< 20pt) pan scrubs the pop progress
// 1:1; release past 50% or with forward velocity completes, otherwise the
// transition snaps back with a critically-damped spring. The gesture scrubs
// MODEL values directly (no animation context), so it composes with the
// UIView.animate-driven completion/cancel tail.

extension UIRectEdge {
    public static let top = UIRectEdge(rawValue: 1 << 0)
    public static let left = UIRectEdge(rawValue: 1 << 1)
    public static let bottom = UIRectEdge(rawValue: 1 << 2)
    public static let right = UIRectEdge(rawValue: 1 << 3)
    public static let all: UIRectEdge = [.top, .left, .bottom, .right]
}

/// Left/right screen-edge pan (the subset UINavigationController needs):
/// recognition additionally requires the touch to start within
/// `edgeActivationWidth` of the configured edge and the drag to be
/// predominantly horizontal, away from that edge.
public final class UIScreenEdgePanGestureRecognizer: UIPanGestureRecognizer {
    public var edges: UIRectEdge = []
    /// iOS accepts edge pans starting within ~20pt of the edge.
    public var edgeActivationWidth: CGFloat = 20

    private var startedAtEdge = false

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard _state == .possible, let v = view else { return }
        let p = location(in: v)
        startedAtEdge =
            (edges.contains(.left) && p.x <= edgeActivationWidth)
            || (edges.contains(.right)
                && p.x >= v.bounds.width - edgeActivationWidth)
        if !startedAtEdge { state = .failed }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if _state == .possible, startedAtEdge {
            // Direction gate before the base class can recognize: the drag
            // must lead horizontally, away from the edge.
            let p = location(in: nil)
            let dx = p.x - startLocation.x, dy = p.y - startLocation.y
            if dx * dx + dy * dy > activationDistance * activationDistance {
                let leadsAway = edges.contains(.left) ? dx > 0 : dx < 0
                if !leadsAway || dx.magnitude < dy.magnitude {
                    state = .failed
                    return
                }
            }
        }
        super.touchesMoved(touches, with: event)
    }

    public override func reset() {
        super.reset()
        startedAtEdge = false
    }
}

open class UINavigationController: UIViewController {
    // MARK: Constants (docs/APP_FEEL.md "Navigation transitions")

    /// Push/pop duration; UIKit's nav transition ≈ 0.35s easeInOut.
    public static let transitionDuration: Double = 0.35
    /// The outgoing view slides to -30% width underneath the incoming one.
    static let parallaxFraction: CGFloat = 0.3
    /// Scrim over the outgoing view: black, 0 -> 8% alpha.
    static let scrimMaxAlpha: CGFloat = 0.08
    /// Leading-edge shadow on the moving (front) view: sigma 4.5pt (Canvas
    /// renders Gaussian sigma = shadowRadius) — a soft ≈9pt falloff.
    static let shadowRadius: CGFloat = 4.5
    static let shadowOpacity: Float = 0.15
    /// Release velocity (pt/s toward the trailing edge) that completes an
    /// interactive pop regardless of progress.
    static let completionVelocity: CGFloat = 300

    // MARK: Stack

    public private(set) var viewControllers: [UIViewController] = []
    public var topViewController: UIViewController? { viewControllers.last }

    public let navigationBar = UINavigationBar()
    /// Clipped area below the bar that hosts child VC views.
    let contentView = UIView()
    public private(set) var interactivePopGestureRecognizer: UIGestureRecognizer?

    public init(rootViewController: UIViewController) {
        super.init()
        addChild(rootViewController)
        viewControllers = [rootViewController]
        rootViewController.didMove(toParent: self)
    }

    public override init() {
        super.init()
    }

    // MARK: Container view

    open override func loadView() {
        let v = UILayoutContainerView(frame: CGRect(x: 0, y: 0,
                                                    width: 390, height: 844))
        v.backgroundColor = .systemBackground
        view = v

        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.clipsToBounds = true
        v.addSubview(contentView)

        navigationBar.autoresizingMask = [.flexibleWidth]
        navigationBar._controller = self
        navigationBar.onBackTapped = { [weak self] in
            self?.popViewController(animated: true)
        }
        v.addSubview(navigationBar)
        updateContainerLayout()

        let edge = UIScreenEdgePanGestureRecognizer { [weak self] r in
            self?.handleEdgePan(r as! UIScreenEdgePanGestureRecognizer)
        }
        edge.edges = .left
        v.addGestureRecognizer(edge)
        interactivePopGestureRecognizer = edge

        if let top = topViewController {
            // Initial install counts as an appearance (the portable core has
            // no window-attachment notion; UIKit fires these when the nav
            // view joins a window).
            top.beginAppearanceTransition(true, animated: false)
            installTopView(top)
            top.endAppearanceTransition()
            navigationBar.setState(title: top.title,
                                   backTitle: backTitle(forTopIndex: viewControllers.count - 1))
        }
    }

    func installTopView(_ vc: UIViewController) {
        let cv = vc.view!
        cv.frame = contentView.bounds
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(cv)
        bindContentScrollView(of: vc)
    }

    // MARK: Large-title container mode (M10)

    /// Frame the bar + content area for the current bar mode. Classic mode:
    /// opaque bar above a clipped content area. Large-title mode (iOS 26):
    /// content fills the WHOLE view and underlaps the transparent bar; the
    /// bar overlays the top `largeTitleExpandedInset` points.
    func updateContainerLayout() {
        guard isViewLoaded else { return }
        let v = view!
        if navigationBar.prefersLargeTitles {
            contentView.frame = v.bounds
            navigationBar.frame = CGRect(
                x: 0, y: 0, width: v.bounds.width,
                height: UINavigationBar.largeTitleExpandedInset)
        } else {
            let barH = UINavigationBar.barHeight
            contentView.frame = CGRect(x: 0, y: barH, width: v.bounds.width,
                                       height: v.bounds.height - barH)
            navigationBar.frame = CGRect(x: 0, y: 0, width: v.bounds.width,
                                         height: barH)
        }
    }

    /// navigationBar.prefersLargeTitles flipped: re-frame the container and
    /// re-bind the top controller's content scroll view.
    func _largeTitlesModeChanged() {
        updateContainerLayout()
        if let top = topViewController, top.isViewLoaded,
           top.view.superview === contentView {
            bindContentScrollView(of: top)
        }
    }

    /// A child's setContentScrollView(_:) changed while it is on screen.
    func _contentScrollViewDidChange(_ vc: UIViewController) {
        guard vc === topViewController, isViewLoaded,
              vc.viewIfLoaded?.superview === contentView else { return }
        bindContentScrollView(of: vc)
    }

    /// Bind the bar's large-title tracking to `vc`'s content scroll view:
    /// reserve the expanded inset, settle at the expanded rest offset when
    /// the scroll view was still at its default offset, and observe it.
    func bindContentScrollView(of vc: UIViewController) {
        guard navigationBar.prefersLargeTitles,
              let scroll = vc._contentScrollView else {
            navigationBar.trackedScrollView = nil
            return
        }
        let inset = UINavigationBar.largeTitleExpandedInset
        if scroll.contentInset.top != inset {
            let wasAtRest = scroll.contentOffset.y == -scroll.contentInset.top
            scroll.contentInset.top = inset
            if wasAtRest {
                scroll.contentOffset.y = -inset
            }
        }
        scroll.delegate = self
        navigationBar.trackedScrollView = scroll
        navigationBar.updateFromScroll()
    }

    /// Snap a release inside the large-title zone to the nearest rest state
    /// (fully expanded / fully collapsed), like UIKit.
    func snapLargeTitleIfNeeded(_ scroll: UIScrollView) {
        guard navigationBar.prefersLargeTitles,
              scroll === navigationBar.trackedScrollView else { return }
        let d = scroll.contentOffset.y + UINavigationBar.largeTitleExpandedInset
        guard d > 0.5, d < UINavigationBar.largeTitleZoneHeight - 0.5 else { return }
        let target: CGFloat =
            d < UINavigationBar.largeTitleZoneHeight / 2
                ? 0 : UINavigationBar.largeTitleZoneHeight
        scroll.setContentOffset(
            CGPoint(x: scroll.contentOffset.x,
                    y: target - UINavigationBar.largeTitleExpandedInset),
            animated: true)
    }

    /// Back-button label for the stack position `index` on top: the previous
    /// VC's title, "Back" when it has none, nil at the root (no button).
    func backTitle(forTopIndex index: Int) -> String? {
        guard index > 0 else { return nil }
        return viewControllers[index - 1].title ?? "Back"
    }

    func _titleDidChange(_ vc: UIViewController) {
        guard isViewLoaded, activeTransition == nil else { return }
        if vc === topViewController {
            navigationBar.setState(title: vc.title,
                                   backTitle: backTitle(forTopIndex: viewControllers.count - 1))
        }
    }

    // MARK: Transition state

    struct Transition {
        var push: Bool
        /// The view controller whose view moves over the full width (the
        /// incoming VC on push, the outgoing on pop).
        var frontVC: UIViewController
        /// The view underneath, moving by the parallax fraction.
        var backVC: UIViewController
        var scrim: UIView
        var width: CGFloat
        /// Host-clock time at which the transition completes; nil while an
        /// interactive pop is scrubbing.
        var endTime: Double?
        var interactive: Bool
        /// Interactive pop only: whether the release completes (true) or
        /// snaps back (false).
        var completing: Bool = true
    }
    var activeTransition: Transition?

    // MARK: Push

    public func pushViewController(_ vc: UIViewController, animated: Bool) {
        guard !viewControllers.contains(where: { $0 === vc }) else { return }
        finishActiveTransition()
        let from = topViewController
        addChild(vc)
        viewControllers.append(vc)

        guard isViewLoaded else {
            vc.didMove(toParent: self) // view installed by loadView later
            return
        }
        view.layoutIfNeeded()

        guard let from else {
            // First VC: no transition.
            vc.beginAppearanceTransition(true, animated: false)
            installTopView(vc)
            vc.endAppearanceTransition()
            navigationBar.setState(title: vc.title,
                                   backTitle: backTitle(forTopIndex: viewControllers.count - 1))
            vc.didMove(toParent: self)
            return
        }

        // Load the incoming view first (viewDidLoad precedes the appearance
        // callbacks, like UIKit), then the "will" pair in push order.
        vc.loadViewIfNeeded()
        from.beginAppearanceTransition(false, animated: animated)
        vc.beginAppearanceTransition(true, animated: animated)

        if !animated {
            installTopView(vc)
            from.view.removeFromSuperview()
            from.endAppearanceTransition()
            vc.endAppearanceTransition()
            navigationBar.setState(title: vc.title,
                                   backTitle: backTitle(forTopIndex: viewControllers.count - 1))
            vc.didMove(toParent: self)
            return
        }

        _runTransition(push: true, from: from, to: vc)
    }

    // MARK: Pop

    @discardableResult
    public func popViewController(animated: Bool) -> UIViewController? {
        finishActiveTransition()
        guard viewControllers.count > 1 else { return nil }
        let from = viewControllers.removeLast()
        from.willMove(toParent: nil)
        let to = viewControllers[viewControllers.count - 1]
        guard isViewLoaded else {
            detachFromParent(from)
            return from
        }
        view.layoutIfNeeded()
        to.loadViewIfNeeded()
        from.beginAppearanceTransition(false, animated: animated)
        to.beginAppearanceTransition(true, animated: animated)

        if !animated {
            installTopView(to)
            from.view.removeFromSuperview()
            from.endAppearanceTransition()
            to.endAppearanceTransition()
            navigationBar.setState(title: to.title,
                                   backTitle: backTitle(forTopIndex: viewControllers.count - 1))
            detachFromParent(from)
            return from
        }

        _runTransition(push: false, from: from, to: to)
        return from
    }

    // MARK: Animator dispatch (M12 — UIViewControllerTransitioning.swift)

    /// UIKit's push/pop direction, handed to the delegate.
    public enum Operation: Int, Sendable {
        case none = 0, push = 1, pop = 2
    }

    /// App hook for custom push/pop animations.
    public weak var delegate: UINavigationControllerDelegate?

    /// Run one ANIMATED push or pop through the transitioning API. The
    /// built-in `_UINavigationSlideAnimator` reproduces the M7.5 behaviour
    /// exactly (and stays scrubbable through `activeTransition`); a delegate
    /// animator gets the standard context and finishes it through
    /// `completeTransition(_:)`.
    func _runTransition(push: Bool, from: UIViewController, to: UIViewController) {
        let op: Operation = push ? .push : .pop
        let custom = delegate?.navigationController(self, animationControllerFor: op,
                                                    from: from, to: to)
        let ctx = _UINavigationTransitionContext(nav: self, push: push, from: from,
                                                 to: to, animated: true)
        delegate?.navigationController(self, willShow: to, animated: true)
        guard let custom else {
            _UINavigationSlideAnimator().animateTransition(using: ctx)
            return
        }
        // Custom animator: it owns the container, so only the incoming view
        // is installed for it; the bar switches without the built-in
        // cross-fade (docs/KNOWN_GAPS.md).
        if push {
            installTopView(to)
        } else {
            let toView = to.view!
            toView.frame = contentView.bounds
            toView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.insertSubview(toView, at: 0)
        }
        navigationBar.setState(title: to.title,
                               backTitle: backTitle(forTopIndex: viewControllers.count - 1))
        ctx.onComplete = { [weak self] _ in
            self?._finishCustomTransition(push: push, from: from, to: to)
        }
        custom.animateTransition(using: ctx)
    }

    /// Teardown for a delegate-supplied animator: the same bookkeeping
    /// `completeTransition(_:)` does for the built-in slide, minus the
    /// scrim/shadow/bar cross-fade the custom animator never created.
    func _finishCustomTransition(push: Bool, from: UIViewController, to: UIViewController) {
        // The outgoing controller's view leaves either way (a push covers it,
        // a pop discards it).
        from.viewIfLoaded?.removeFromSuperview()
        for vc in [from, to] {
            guard let v = vc.viewIfLoaded else { continue }
            v.removeAllAnimations()
            v.frame = contentView.bounds
        }
        if push {
            from.endAppearanceTransition()
            to.endAppearanceTransition()
            to.didMove(toParent: self)
        } else {
            from.endAppearanceTransition()
            to.endAppearanceTransition()
            detachFromParent(from)
        }
        delegate?.navigationController(self, didShow: to, animated: true)
    }

    @discardableResult
    public func popToRootViewController(animated: Bool) -> [UIViewController]? {
        guard viewControllers.count > 1 else { return nil }
        finishActiveTransition()
        // Collapse the middle of the stack, then pop the top normally.
        let removed = Array(viewControllers[1..<(viewControllers.count - 1)])
        for vc in removed {
            vc.willMove(toParent: nil)
            detachFromParent(vc)
        }
        viewControllers.removeSubrange(1..<(viewControllers.count - 1))
        guard let top = popViewController(animated: animated) else { return removed }
        return removed + [top]
    }

    // MARK: Shared transition mechanics

    func makeScrim() -> UIView {
        let s = UIView(frame: contentView.bounds)
        s.backgroundColor = .black
        s.alpha = 0
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.isUserInteractionEnabled = false
        return s
    }

    func setShadow(on v: UIView, enabled: Bool) {
        let l = v.layer
        if enabled {
            l.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            l.shadowOpacity = UINavigationController.shadowOpacity
            l.shadowRadius = UINavigationController.shadowRadius
            l.shadowOffset = .zero
        } else {
            l.shadowOpacity = 0
        }
    }

    /// Position the transition views for `coverage` q ∈ [0, 1]: the fraction
    /// of the width the FRONT view has entered (push animates q 0 -> 1, pop
    /// 1 -> 0). Pure property sets: inside a UIView.animate block they
    /// record animations; outside (interactive scrub) they move the model.
    func applyTransition(_ t: Transition, coverage q: CGFloat) {
        let mid = contentView.bounds.midX
        t.frontVC.view.center.x = mid + t.width * (1 - q)
        t.backVC.view.center.x = mid - UINavigationController.parallaxFraction * t.width * q
        t.scrim.alpha = UINavigationController.scrimMaxAlpha * q
    }

    /// Finish the active transition NOW (used when a new push/pop preempts
    /// one in flight): snap models to the destination and run the cleanup.
    func finishActiveTransition() {
        guard let t = activeTransition else { return }
        // Destination coverage: push -> 1, completing pop -> 0, cancelled
        // (or still-scrubbing) interactive pop -> 1.
        applyTransition(t, coverage: (t.push || !t.completing) ? 1 : 0)
        completeTransition(t)
    }

    /// Host-clock step: complete the transition when its end time passes.
    func stepTransition(to time: Double) {
        guard let t = activeTransition, let end = t.endTime,
              time >= end - 1e-9 else { return }
        completeTransition(t)
    }

    func completeTransition(_ t: Transition) {
        activeTransition = nil
        t.scrim.removeFromSuperview()

        let cancelled = t.interactive && !t.completing
        // The view leaving the hierarchy.
        let leavingVC = t.push ? t.backVC : (cancelled ? t.backVC : t.frontVC)
        let stayingVC = t.push ? t.frontVC : (cancelled ? t.frontVC : t.backVC)
        leavingVC.viewIfLoaded?.removeFromSuperview()

        // Reset geometry + recorded animations so the next appearance starts
        // clean (the leaving view keeps no parallax offset, the staying view
        // sheds its clamped-at-1 animations).
        for vc in [leavingVC, stayingVC] {
            guard let v = vc.viewIfLoaded else { continue }
            v.removeAllAnimations()
            v.center.x = contentView.bounds.midX
        }
        setShadow(on: t.frontVC.view, enabled: false)

        if cancelled {
            // Interactive pop snapped back: reverse the appearance calls on
            // both sides (UIKit's cancelled-transition sequence), keep the
            // stack unchanged.
            t.backVC.beginAppearanceTransition(false, animated: true)
            t.backVC.endAppearanceTransition()
            t.frontVC.beginAppearanceTransition(true, animated: true)
            t.frontVC.endAppearanceTransition()
            navigationBar.endTransition(cancelled: true)
            delegate?.navigationController(self, didShow: t.frontVC, animated: true)
            return
        }

        if t.push {
            // disappeared before appeared, matching real UIKit's push order.
            t.backVC.endAppearanceTransition()
            t.frontVC.endAppearanceTransition()
            navigationBar.endTransition()
            t.frontVC.didMove(toParent: self)
            delegate?.navigationController(self, didShow: t.frontVC, animated: true)
        } else {
            if t.interactive {
                // Interactive pop mutates the stack only on completion.
                viewControllers.removeAll { $0 === t.frontVC }
                t.frontVC.willMove(toParent: nil)
            }
            t.frontVC.endAppearanceTransition()
            t.backVC.endAppearanceTransition()
            navigationBar.endTransition()
            detachFromParent(t.frontVC)
            delegate?.navigationController(self, didShow: t.backVC, animated: true)
        }
    }

    func detachFromParent(_ vc: UIViewController) {
        // removeFromParent() itself issues didMove(toParent: nil) (UIKit).
        vc.removeFromParent()
    }

    // MARK: Interactive back-swipe

    func handleEdgePan(_ r: UIScreenEdgePanGestureRecognizer) {
        switch r.state {
        case .began:
            guard activeTransition == nil, viewControllers.count > 1,
                  isViewLoaded else { return }
            let from = viewControllers[viewControllers.count - 1]
            let to = viewControllers[viewControllers.count - 2]
            view.layoutIfNeeded()
            to.loadViewIfNeeded()
            from.beginAppearanceTransition(false, animated: true)
            to.beginAppearanceTransition(true, animated: true)
            let toView = to.view!
            toView.frame = contentView.bounds
            toView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.insertSubview(toView, at: 0)
            let scrim = makeScrim()
            contentView.insertSubview(scrim, at: 1)
            setShadow(on: from.view, enabled: true)
            var t = Transition(push: false, frontVC: from, backVC: to,
                               scrim: scrim, width: contentView.bounds.width,
                               endTime: nil, interactive: true)
            t.completing = false
            activeTransition = t
            navigationBar.beginTransition(
                title: to.title,
                backTitle: backTitle(forTopIndex: viewControllers.count - 2),
                push: false)
            scrub(progress: 0)
        case .changed:
            guard let t = activeTransition, t.interactive, t.endTime == nil
            else { return }
            let p = clamp01(r.translation(in: view).x / t.width)
            scrub(progress: p)
        case .ended, .cancelled, .failed:
            guard let t = activeTransition, t.interactive, t.endTime == nil
            else { return }
            let p = clamp01(r.translation(in: view).x / t.width)
            let vx = r.velocity(in: view).x
            let completes: Bool
            if r.state == .ended {
                // Release past 50%, or flung toward the trailing edge —
                // unless flung firmly back.
                if vx >= UINavigationController.completionVelocity {
                    completes = true
                } else if vx <= -UINavigationController.completionVelocity {
                    completes = false
                } else {
                    completes = p > 0.5
                }
            } else {
                completes = false
            }
            endInteractivePop(t, completes: completes)
        default:
            break
        }
    }

    /// Scrub the interactive pop to swipe progress `p` (0 = fully covered /
    /// top in place, 1 = pop complete). Direct model sets — no animations.
    func scrub(progress p: CGFloat) {
        guard let t = activeTransition else { return }
        applyTransition(t, coverage: 1 - p)
        navigationBar.setTransitionProgress(p)
    }

    /// Animate the remainder with a critically-damped spring and schedule
    /// the completion on the host clock.
    func endInteractivePop(_ t: Transition, completes: Bool) {
        var t = t
        t.completing = completes
        t.endTime = OpenUIKitRuntime.animationTime
            + UINavigationController.transitionDuration
        activeTransition = t
        UIView.animate(withDuration: UINavigationController.transitionDuration,
                       delay: 0, usingSpringWithDamping: 1,
                       initialSpringVelocity: 0, options: [], animations: {
            self.applyTransition(t, coverage: completes ? 0 : 1)
            self.navigationBar.setTransitionProgress(completes ? 1 : 0)
        })
        UINavigationController.registerTransitioning(self)
    }

    // MARK: Global transition registry (host clock stepping)

    private struct WeakNav { weak var nav: UINavigationController? }
    private static var transitioning: [WeakNav] = []

    static func registerTransitioning(_ nav: UINavigationController) {
        transitioning.removeAll { $0.nav == nil }
        if !transitioning.contains(where: { $0.nav === nav }) {
            transitioning.append(WeakNav(nav: nav))
        }
    }

    /// Complete every navigation transition whose end time has passed. The
    /// window calls this from tick(timestamp:) — the host's frame clock
    /// (same pattern as UIScrollView._stepScrollAnimations).
    public static func _stepTransitions(to time: Double) {
        guard !transitioning.isEmpty else { return }
        for entry in transitioning { entry.nav?.stepTransition(to: time) }
        transitioning.removeAll { $0.nav == nil || $0.nav!.activeTransition == nil }
    }

    /// Any navigation transition still in flight (host redraw hint).
    public static var _hasActiveTransition: Bool {
        transitioning.contains { $0.nav?.activeTransition != nil }
    }
}

// MARK: Large-title scroll observation (M10)

extension UINavigationController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === navigationBar.trackedScrollView else { return }
        navigationBar.updateFromScroll()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate: Bool) {
        if !willDecelerate { snapLargeTitleIfNeeded(scrollView) }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapLargeTitleIfNeeded(scrollView)
    }
}

func clamp01(_ v: CGFloat) -> CGFloat { Swift.min(Swift.max(v, 0), 1) }
