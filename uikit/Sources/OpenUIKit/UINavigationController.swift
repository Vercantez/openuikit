// UINavigationController. Owner: viewcontroller module (M7.5 navigation).
//
// Container layout: Catalyst's inline bar sits above a clipped content
// area (opaque 64 pt). iOS 26 inline bars are a transparent overlay —
// content fills the container and underlaps, the same geometry large-title
// mode already used (MEASURED Forms t200, iPhone SE 2x: table frame fills
// the window, safeAreaInsets.top 64, adjustedContentInset [64,0,0,0],
// contentOffset (0, -64), bar zone reads the table's grouped background).
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
@preconcurrency @MainActor
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

@preconcurrency @MainActor
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

    /// The controller whose view is currently in front of the navigation
    /// interface. This is normally the stack's top controller, but a modal
    /// presented over the navigation controller (or, on the portable path,
    /// directly by its top child) is the visible controller until dismissal.
    public var visibleViewController: UIViewController? {
        if let presentedViewController { return presentedViewController }
        guard let topViewController else { return nil }
        return topViewController.presentedViewController ?? topViewController
    }

    public let navigationBar = UINavigationBar()
    /// The controller's toolbar (M13). Hidden by default, exactly like
    /// UIKit; shown by `setToolbarHidden(false, animated:)` and filled from
    /// the top controller's `toolbarItems`.
    public let toolbar = UIToolbar()
    /// Whether the navigation bar is removed from the container's layout.
    /// Hidden bars give the top controller the full height above any toolbar.
    open var isNavigationBarHidden: Bool = false {
        didSet {
            guard isNavigationBarHidden != oldValue,
                  !_isAnimatingNavigationBarVisibility else { return }
            navigationBar.isHidden = isNavigationBarHidden
            navigationBar.alpha = 1
            updateContainerLayout()
        }
    }
    private var _isAnimatingNavigationBarVisibility = false

    open func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != isNavigationBarHidden else { return }
        guard animated, isViewLoaded else {
            isNavigationBarHidden = hidden
            return
        }

        let oldContentFrame = contentView.frame
        let oldBarFrame = navigationBar.frame
        _isAnimatingNavigationBarVisibility = true
        isNavigationBarHidden = hidden
        _isAnimatingNavigationBarVisibility = false
        navigationBar.isHidden = false
        updateContainerLayout()
        let targetContentFrame = contentView.frame
        let targetBarFrame = navigationBar.frame
        contentView.frame = oldContentFrame
        navigationBar.frame = oldBarFrame
        navigationBar.alpha = hidden ? 1 : 0
        UIView.animate(withDuration: UINavigationController.transitionDuration,
                       delay: 0, options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: {
            self.contentView.frame = targetContentFrame
            self.navigationBar.frame = targetBarFrame
            self.navigationBar.alpha = hidden ? 0 : 1
        }, completion: { [weak self] _ in
            guard let self else { return }
            self.navigationBar.isHidden = self.isNavigationBarHidden
            self.navigationBar.alpha = 1
        })
    }
    public var isToolbarHidden: Bool = true {
        didSet {
            guard isToolbarHidden != oldValue else { return }
            toolbar.isHidden = isToolbarHidden
            updateContainerLayout()
            updateToolbar()
        }
    }
    public func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        isToolbarHidden = hidden
    }
    /// Clipped area below the bar that hosts child VC views.
    let contentView = UIView()
    public private(set) var interactivePopGestureRecognizer: UIGestureRecognizer?
    /// iOS 26's content-pop recognizer. OpenUIKit's measured edge recognizer
    /// drives the same interactive transition, so both public routes expose
    /// the identical retained recognizer rather than competing for touches.
    public var interactiveContentPopGestureRecognizer: UIGestureRecognizer? {
        interactivePopGestureRecognizer
    }

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

        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        toolbar.isHidden = isToolbarHidden
        v.addSubview(toolbar)
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
            updateBarState()
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

    /// Frame the bar + content area for the current bar mode. Classic
    /// Catalyst inline: opaque bar above a clipped content area. Large-title
    /// mode and iOS 26 inline: content fills the WHOLE view and underlaps
    /// the transparent bar; the bar overlays the top of the container.
    /// MEASURED Forms t200, iPhone SE 2x, iOS 26.1: the table's window
    /// frame is [0, 0, 375, 667], `safeAreaInsets.top` 64,
    /// `adjustedContentInset` [64, 0, 0, 0], `contentOffset` (0, -64);
    /// the 64 pt bar zone is the table's grouped fill showing through.
    func updateContainerLayout() {
        guard isViewLoaded else { return }
        let v = view!
        if isNavigationBarHidden {
            contentView.frame = CGRect(x: 0, y: 0, width: v.bounds.width,
                                       height: v.bounds.height - toolbarHeight)
            navigationBar.frame = CGRect(x: 0, y: 0, width: v.bounds.width,
                                         height: UINavigationBar.barHeight)
        } else if navigationBar.prefersLargeTitles || UINavigationBar.isIOS {
            contentView.frame = v.bounds
            let overlay = navigationBar.prefersLargeTitles
                ? navigationBar.largeTitleOverlayHeight
                : UINavigationBar.barHeight
            navigationBar.frame = CGRect(
                x: 0, y: 0, width: v.bounds.width, height: overlay)
        } else {
            let barH = UINavigationBar.barHeight
            contentView.frame = CGRect(x: 0, y: barH, width: v.bounds.width,
                                       height: v.bounds.height - barH - toolbarHeight)
            navigationBar.frame = CGRect(x: 0, y: 0, width: v.bounds.width,
                                         height: barH)
        }
        toolbar.frame = CGRect(x: 0, y: v.bounds.height - toolbarHeight,
                               width: v.bounds.width, height: UIToolbar.defaultHeight)
        updateContentSafeArea()
    }

    /// The bars a child underlaps are SAFE AREA, not a scroll-view inset.
    ///
    /// MEASURED 2026-09-04, NavFlow conformance app t3000, iPhone SE 2x,
    /// iOS 26.1: the pushed controller's view fills the window and reports
    /// `safeAreaInsets` [116, 0, 0, 0] — the large-title bar's bottom edge —
    /// while its table's `contentInset` is [0, 0, 0, 0]. The port used to put
    /// the 116 pt into the scroll view's `contentInset` and leave the safe
    /// area at zero, so a controller whose Auto Layout hangs off
    /// `view.safeAreaLayoutGuide.topAnchor` (the normal spelling) drew its
    /// content 116 pt too high, under the bar.
    func updateContentSafeArea() {
        guard isViewLoaded else { return }
        let v = view!
        let inherited = v.safeAreaInsets
        let barBottom = isNavigationBarHidden
            ? 0 : navigationBar.frame.maxY - contentView.frame.minY
        let barTop = v.bounds.maxY - toolbarHeight
        let toolbarOverlap = contentView.frame.maxY - barTop
        contentView._setSafeAreaInsets(UIEdgeInsets(
            top: max(inherited.top, max(0, barBottom)),
            left: inherited.left,
            bottom: max(inherited.bottom, max(0, toolbarOverlap)),
            right: inherited.right))
    }

    /// Height the toolbar takes out of the content area (0 when hidden).
    var toolbarHeight: CGFloat { isToolbarHidden ? 0 : UIToolbar.defaultHeight }

    /// Fill the toolbar from the top controller's `toolbarItems` (M13).
    func updateToolbar() {
        guard isViewLoaded else { return }
        toolbar.items = topViewController?.toolbarItems
    }

    /// A child's `toolbarItems` changed while it is on screen.
    func _toolbarItemsDidChange(_ vc: UIViewController) {
        guard vc === topViewController else { return }
        updateToolbar()
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
        let previous = navigationBar.trackedScrollView
        guard navigationBar.prefersLargeTitles,
              let scroll = vc._contentScrollView else {
            previous?._scrollObserver = nil
            navigationBar.trackedScrollView = nil
            return
        }
        if previous !== scroll { previous?._scrollObserver = nil }
        // The expanded overlay reaches the scroll view as SAFE AREA
        // (updateContentSafeArea), exactly as it does on the device, so only
        // the rest offset is settled here.
        let inset = UINavigationBar.largeTitleExpandedInset
        let wasAtRest = scroll.contentOffset.y == -scroll.adjustedContentInset.top
        updateContentSafeArea()
        if wasAtRest, scroll.contentOffset.y != -inset {
            scroll.contentOffset.y = -inset
        }
        // Observe, do not become the delegate: the app owns `scroll.delegate`
        // (a UITableViewController is its own). See UIScrollView._scrollObserver.
        scroll._scrollObserver = self
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
        // MEASURED 2026-09-04, navprobe scroll holds, iPhone 16 / iOS 26.1:
        // zero-velocity release at d=36 retargets to the expanded rest;
        // d=37 retargets collapsed. Catalyst keeps the half-zone (26).
        let threshold: CGFloat = UINavigationBar.isIOS
            ? UINavigationBar.iOSSnapCollapseDistance
            : UINavigationBar.largeTitleZoneHeight / 2
        let target: CGFloat = d <= threshold ? 0 : UINavigationBar.largeTitleZoneHeight
        scroll.setContentOffset(
            CGPoint(x: scroll.contentOffset.x,
                    y: target - UINavigationBar.largeTitleExpandedInset),
            animated: true)
    }

    /// Back-button label for the stack position `index` on top: the previous
    /// VC's `backBarButtonItem` / `backButtonTitle` if it set one, otherwise
    /// its title, "Back" when it has none, nil at the root (no button).
    func backTitle(forTopIndex index: Int) -> String? {
        guard index > 0 else { return nil }
        let previous = viewControllers[index - 1]
        if viewControllers[index]._navigationItem?.hidesBackButton == true { return nil }
        if let item = previous._navigationItem {
            if let custom = item.backBarButtonItem?.title { return custom }
            if let t = item.backButtonTitle { return t }
        }
        return previous.title ?? "Back"
    }

    /// Push the whole navigation-item stack + the title/back state onto the
    /// bar (M13). `setState` still owns the title label and back button
    /// (they take part in the push/pop cross-fade); the item stack drives
    /// the bar-button platters, title view, prompt and per-item appearance.
    func updateBarState() {
        navigationBar.setState(title: topViewController?.title,
                               backTitle: backTitle(forTopIndex: viewControllers.count - 1))
        navigationBar.setItems(viewControllers.map { $0.navigationItem })
        updateToolbar()
    }

    func _titleDidChange(_ vc: UIViewController) {
        guard isViewLoaded, activeTransition == nil else { return }
        if vc === topViewController {
            updateBarState()
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
            updateBarState()
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
            updateBarState()
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
            updateBarState()
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
        updateBarState()
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
            settleBarAfterTransition(on: t.frontVC)
            delegate?.navigationController(self, didShow: t.frontVC, animated: true)
            return
        }

        if t.push {
            // disappeared before appeared, matching real UIKit's push order.
            t.backVC.endAppearanceTransition()
            t.frontVC.endAppearanceTransition()
            navigationBar.endTransition()
            settleBarAfterTransition(on: t.frontVC)
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
            settleBarAfterTransition(on: t.backVC)
            detachFromParent(t.frontVC)
            delegate?.navigationController(self, didShow: t.backVC, animated: true)
        }
    }

    /// A finished transition hands the bar over to the controller that is now
    /// on top: the item stack, and — in large-title mode — the tracked scroll
    /// view the large title follows. Without this the bar keeps the state it
    /// had when the transition started, which is why a pushed controller's
    /// large title still read the previous title (MEASURED: real iOS 26.1
    /// shows the pushed "About" as the LARGE title, `navprobe.large`
    /// rest_pushed — `_UINavigationBarLargeTitleView`'s label reads "About"
    /// at [16, 3.67, 97, 40.67] while the inline title stays at alpha 0).
    func settleBarAfterTransition(on vc: UIViewController) {
        guard vc === topViewController else { return }
        updateBarState()
        if vc.viewIfLoaded?.superview === contentView { bindContentScrollView(of: vc) }
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
