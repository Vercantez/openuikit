// Custom transitions: UIViewControllerAnimatedTransitioning + context +
// transitioning delegate + the public transition coordinator and
// percent-driven interactive controller (M12 + corpus tail #1).
//
// WHY: the census (docs/APP_COMPAT.md) counts 64 uses of this cluster in the
// corpus — apps supply their own present/dismiss and push/pop animations
// through it. Until M12 OpenUIKit's own sheet and navigation transitions
// animated DIRECTLY inside `present(_:animated:)` and
// `pushViewController(_:animated:)`, so there was no seam an app could hook.
//
// The refactor: every modal presentation and every animated push/pop now
// builds a transition CONTEXT, asks for an ANIMATOR (the app's
// `transitioningDelegate` / `UINavigationController.delegate` first, the
// built-in one otherwise) and lets the animator drive. The built-in
// animators (`_UIPageSheetAnimator`, `_UINavigationSlideAnimator`) contain
// exactly the code that used to be inline, so every existing scene, capture
// and app keeps its measured behaviour.
//
// Deliberate limits, all documented in docs/KNOWN_GAPS.md:
//   - Built-in interactive back-swipe and sheet drag stay on their measured
//     host-clock scrub paths; a custom animator can still return a
//     `UIPercentDrivenInteractiveTransition` from the transitioning /
//     navigation delegate.
//   - `animateTransition(using:)` must finish through
//     `context.completeTransition(_:)` — usually from a UIView.animate
//     completion, which the host clock fires exactly like the built-ins.

/// Keys for `UIViewControllerContextTransitioning.viewController(forKey:)`.
public struct UITransitionContextViewControllerKey: Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let from = UITransitionContextViewControllerKey(rawValue: "UITransitionContextFromViewController")
    public static let to = UITransitionContextViewControllerKey(rawValue: "UITransitionContextToViewController")
}

/// Keys for `UIViewControllerContextTransitioning.view(forKey:)`.
public struct UITransitionContextViewKey: Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let from = UITransitionContextViewKey(rawValue: "UITransitionContextFromView")
    public static let to = UITransitionContextViewKey(rawValue: "UITransitionContextToView")
}

/// What UIKit hands an animator: the container to animate inside, the two
/// controllers/views, their start and end frames, and the completion hook.
@preconcurrency @MainActor
public protocol UIViewControllerContextTransitioning: AnyObject {
    var containerView: UIView { get }
    var isAnimated: Bool { get }
    var isInteractive: Bool { get }
    var transitionWasCancelled: Bool { get }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController?
    func view(forKey key: UITransitionContextViewKey) -> UIView?
    func initialFrame(for vc: UIViewController) -> CGRect
    func finalFrame(for vc: UIViewController) -> CGRect
    /// The animator MUST call this when its animation ends.
    func completeTransition(_ didComplete: Bool)
    func updateInteractiveTransition(_ percentComplete: CGFloat)
    func finishInteractiveTransition()
    func cancelInteractiveTransition()
}

/// An object that performs one transition's animation.
@preconcurrency @MainActor
public protocol UIViewControllerAnimatedTransitioning: AnyObject {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    func animationEnded(_ transitionCompleted: Bool)
    func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating?
}

extension UIViewControllerAnimatedTransitioning {
    public func animationEnded(_ transitionCompleted: Bool) {}
    public func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating? { nil }
}

/// An app's hook for a modal presentation: custom animators and/or a custom
/// `UIPresentationController`.
@preconcurrency @MainActor
public protocol UIViewControllerTransitioningDelegate: AnyObject {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController?
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning?
}

extension UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    public func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? { nil }
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? { nil }
    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? { nil }
    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? { nil }
}

// MARK: - Concrete context for modal presentations

/// The context OpenUIKit hands modal animators. `containerView` is the
/// presentation container the presentation controller installed; the "to"
/// view on a presentation is the presentation controller's `presentedView`
/// (the sheet platter), which is what the built-in animator moves.
@preconcurrency @MainActor
final class _UIModalTransitionContext: UIViewControllerContextTransitioning {
    let containerView: UIView
    let isAnimated: Bool
    let presenting: Bool
    private weak var fromVC: UIViewController?
    private weak var toVC: UIViewController?
    private weak var fromView: UIView?
    private weak var toView: UIView?
    private let startFrame: CGRect
    private let endFrame: CGRect
    /// Called exactly once, from `completeTransition`.
    var onComplete: ((Bool) -> Void)?
    var coordinator: _UITransitionCoordinator?
    var isInteractive = false
    var transitionWasCancelled = false
    private var completed = false

    init(containerView: UIView, animated: Bool, presenting: Bool,
         from: UIViewController?, to: UIViewController?,
         fromView: UIView?, toView: UIView?,
         startFrame: CGRect, endFrame: CGRect) {
        self.containerView = containerView
        self.isAnimated = animated
        self.presenting = presenting
        self.fromVC = from
        self.toVC = to
        self.fromView = fromView
        self.toView = toView
        self.startFrame = startFrame
        self.endFrame = endFrame
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? fromVC : toVC
    }
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        key == .from ? fromView : toView
    }
    /// Presentation: the presented view starts offscreen and ends at its
    /// final frame; dismissal is the reverse.
    func initialFrame(for vc: UIViewController) -> CGRect {
        vc === (presenting ? toVC : fromVC) ? startFrame : containerView.bounds
    }
    func finalFrame(for vc: UIViewController) -> CGRect {
        vc === (presenting ? toVC : fromVC) ? endFrame : containerView.bounds
    }
    func completeTransition(_ didComplete: Bool) {
        guard !completed else { return }
        completed = true
        onComplete?(didComplete)
    }
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        coordinator?.percentComplete = percentComplete
    }
    func finishInteractiveTransition() {
        isInteractive = false
        coordinator?.setInteractive(false)
    }
    func cancelInteractiveTransition() {
        transitionWasCancelled = true
        isInteractive = false
        coordinator?.isCancelled = true
        coordinator?.setInteractive(false)
    }
}

// MARK: - Navigation transitions

/// An app's hook for push/pop animations, including an optional
/// percent-driven interactive controller.
@preconcurrency @MainActor
public protocol UINavigationControllerDelegate: AnyObject {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool)
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController, animated: Bool)
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
}

extension UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController, animated: Bool) {}
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController, animated: Bool) {}
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? { nil }
}

/// The context for one push or pop. `containerView` is the navigation
/// controller's clipped content area — the same view the built-in slide moves
/// its two child views inside.
@preconcurrency @MainActor
final class _UINavigationTransitionContext: UIViewControllerContextTransitioning {
    unowned let nav: UINavigationController
    let push: Bool
    let fromVC: UIViewController
    let toVC: UIViewController
    let isAnimated: Bool
    var onComplete: ((Bool) -> Void)?
    var coordinator: _UITransitionCoordinator?
    var isInteractive = false
    var transitionWasCancelled = false
    private var completed = false

    init(nav: UINavigationController, push: Bool,
         from: UIViewController, to: UIViewController, animated: Bool) {
        self.nav = nav
        self.push = push
        self.fromVC = from
        self.toVC = to
        self.isAnimated = animated
    }

    var containerView: UIView { nav.contentView }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? fromVC : toVC
    }
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        (key == .from ? fromVC : toVC).viewIfLoaded
    }
    /// The incoming view starts one container width off the trailing edge on
    /// a push and at rest on a pop; the outgoing one is the mirror image.
    func initialFrame(for vc: UIViewController) -> CGRect {
        let b = containerView.bounds
        if vc === toVC && push { return b.offsetBy(dx: b.width, dy: 0) }
        return b
    }
    func finalFrame(for vc: UIViewController) -> CGRect {
        let b = containerView.bounds
        if vc === fromVC && !push { return b.offsetBy(dx: b.width, dy: 0) }
        return b
    }
    func completeTransition(_ didComplete: Bool) {
        guard !completed else { return }
        completed = true
        onComplete?(didComplete)
    }
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        coordinator?.percentComplete = percentComplete
    }
    func finishInteractiveTransition() {
        isInteractive = false
        coordinator?.setInteractive(false)
    }
    func cancelInteractiveTransition() {
        transitionWasCancelled = true
        isInteractive = false
        coordinator?.isCancelled = true
        coordinator?.setInteractive(false)
    }
}

/// The built-in push/pop: the incoming view slides over the outgoing one,
/// which parallaxes back under a scrim. Every constant is the M7.5 one
/// (docs/APP_FEEL.md "Navigation transitions"); the code moved here verbatim
/// so that push/pop runs through the same animator seam a custom animator
/// plugs into.
///
/// It does NOT drive the transition to completion through the context: the
/// built-in slide is SCRUBBABLE (the interactive back swipe seeks the same
/// `applyTransition(_:coverage:)` function against the host clock), so its
/// completion is owned by `UINavigationController.stepTransition(to:)`. A
/// custom animator, which has no scrub hook, finishes through
/// `context.completeTransition(_:)` like UIKit's.
@preconcurrency @MainActor
final class _UINavigationSlideAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        UINavigationController.transitionDuration
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let c = ctx as? _UINavigationTransitionContext else {
            ctx.completeTransition(true)
            return
        }
        let nav = c.nav
        let duration = transitionDuration(using: ctx)
        let scrim = nav.makeScrim()
        let t: UINavigationController.Transition
        if c.push {
            nav.contentView.addSubview(scrim)     // above outgoing
            nav.installTopView(c.toVC)            // above scrim
            nav.setShadow(on: c.toVC.view, enabled: true)
            t = UINavigationController.Transition(
                push: true, frontVC: c.toVC, backVC: c.fromVC, scrim: scrim,
                width: nav.contentView.bounds.width,
                endTime: OpenUIKitRuntime.animationTime + duration,
                interactive: false)
        } else {
            // Incoming (previous) view goes UNDER the outgoing top view,
            // offset by the parallax; scrim starts at full strength.
            let toView = c.toVC.view!
            toView.frame = nav.contentView.bounds
            toView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            nav.contentView.insertSubview(toView, at: 0)
            nav.contentView.insertSubview(scrim, at: 1) // above incoming, below front
            nav.setShadow(on: c.fromVC.view, enabled: true)
            t = UINavigationController.Transition(
                push: false, frontVC: c.fromVC, backVC: c.toVC, scrim: scrim,
                width: nav.contentView.bounds.width,
                endTime: OpenUIKitRuntime.animationTime + duration,
                interactive: false)
        }
        nav.activeTransition = t
        nav.navigationBar.beginTransition(
            title: c.toVC.title,
            backTitle: nav.backTitle(forTopIndex: nav.viewControllers.count - 1),
            push: c.push)
        nav.applyTransition(t, coverage: c.push ? 0 : 1)
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut,
                       animations: {
            nav.applyTransition(t, coverage: c.push ? 1 : 0)
            nav.navigationBar.setTransitionProgress(1)
            c.coordinator?.performAlongsideAnimations()
        })
        nav.navigationBar.accelerateOutgoingBackFade(duration: duration)
        UINavigationController.registerTransitioning(nav)
    }
}

// MARK: - Transition coordinator
//
// MEASURED animprobe, iPhone SE 2x / iOS 26.1: push/pop/present/dismiss vend
// a coordinator on from, to, and the container controller for the animated
// case. Rotation still has no size-transition vendor (the host owns the
// surface); `viewWillTransition(to:with:)` keeps the protocol so app
// overrides compile.
@preconcurrency @MainActor
public protocol UIViewControllerTransitionCoordinatorContext: AnyObject {
    var isAnimated: Bool { get }
    var presentationStyle: UIModalPresentationStyle { get }
    var initiallyInteractive: Bool { get }
    var isInterruptible: Bool { get }
    var isInteractive: Bool { get }
    var isCancelled: Bool { get }
    var transitionDuration: TimeInterval { get }
    var percentComplete: CGFloat { get }
    var completionVelocity: CGFloat { get }
    var completionCurve: UIView.AnimationCurve { get }
    var containerView: UIView { get }
    var targetTransform: CGAffineTransform { get }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController?
    func view(forKey key: UITransitionContextViewKey) -> UIView?
}

@preconcurrency @MainActor
public protocol UIViewControllerTransitionCoordinator: UIViewControllerTransitionCoordinatorContext {
    @discardableResult
    func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool
    @discardableResult
    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool
    func notifyWhenInteractionChanges(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void)
    func notifyWhenInteractionEnds(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void)
}

extension UIViewControllerTransitionCoordinator {
    /// UIKit's `completion:` is defaulted because it imports from a nullable
    /// Objective-C block parameter; a Swift PROTOCOL requirement may not carry
    /// a default argument, so the one-argument spelling app code writes lives
    /// here instead.
    @discardableResult
    public func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        animate(alongsideTransition: animation, completion: nil)
    }

    @discardableResult
    public func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        animateAlongsideTransition(in: view, animation: animation, completion: nil)
    }
}

// MARK: - Concrete coordinator
//
// MEASURED animprobe, iPhone SE 2x / iOS 26.1:
//   * Non-nil on from, to, and the navigation controller during animated
//     push; still non-nil in viewDidAppear; nil after the transition ends.
//   * Push: duration 0.35, presentationStyle .none, completionCurve raw 7,
//     completionVelocity 1, isAnimated true, initiallyInteractive false,
//     isInteractive false, isInterruptible false, targetTransform identity,
//     percentComplete 0 at viewWillAppear.
//   * PageSheet present: presentationStyle .pageSheet, completionCurve
//     easeInOut (0), transitionDuration 0 at viewWillAppear, presenting
//     controller also vends the coordinator.
//   * animate(alongsideTransition:) returns true; the animation block is
//     NOT invoked synchronously in viewWillAppear (alongsideRanSync false);
//     completion runs after the transition, not in willAppear.

@preconcurrency @MainActor
final class _UITransitionCoordinator: UIViewControllerTransitionCoordinator {
    let isAnimated: Bool
    let presentationStyle: UIModalPresentationStyle
    let initiallyInteractive: Bool
    var isInterruptible: Bool
    var isInteractive: Bool
    var isCancelled = false
    var transitionDuration: TimeInterval
    var percentComplete: CGFloat = 0
    var completionVelocity: CGFloat = 1
    var completionCurve: UIView.AnimationCurve
    let containerView: UIView
    var targetTransform: CGAffineTransform = .identity
    private weak var fromVC: UIViewController?
    private weak var toVC: UIViewController?
    private weak var fromView: UIView?
    private weak var toView: UIView?
    private var attached: [UIViewController] = []
    private var items: [(animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
                         completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?)] = []
    private var interactionHandlers: [(any UIViewControllerTransitionCoordinatorContext) -> Void] = []
    private var alongsideFlushed = false
    private var finished = false

    init(animated: Bool,
         presentationStyle: UIModalPresentationStyle,
         duration: TimeInterval,
         completionCurve: UIView.AnimationCurve,
         containerView: UIView,
         from: UIViewController?,
         to: UIViewController?,
         fromView: UIView?,
         toView: UIView?,
         interactive: Bool,
         interruptible: Bool) {
        self.isAnimated = animated
        self.presentationStyle = presentationStyle
        self.initiallyInteractive = interactive
        self.isInteractive = interactive
        self.isInterruptible = interruptible
        self.transitionDuration = duration
        self.completionCurve = completionCurve
        self.containerView = containerView
        self.fromVC = from
        self.toVC = to
        self.fromView = fromView
        self.toView = toView
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? fromVC : toVC
    }
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        key == .from ? fromView : toView
    }

    func attach(_ controllers: UIViewController?...) {
        for vc in controllers {
            guard let vc else { continue }
            vc._transitionCoordinator = self
            if !attached.contains(where: { $0 === vc }) { attached.append(vc) }
        }
    }

    func detach() {
        for vc in attached {
            if vc._transitionCoordinator === self {
                vc._transitionCoordinator = nil
            }
        }
        attached.removeAll()
    }

    @discardableResult
    func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        guard isAnimated, !finished else { return false }
        items.append((animation, completion))
        if alongsideFlushed {
            animation?(self)
        }
        return true
    }

    @discardableResult
    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        _ = view
        return animate(alongsideTransition: animation, completion: completion)
    }

    func notifyWhenInteractionChanges(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void
    ) {
        interactionHandlers.append(handler)
    }

    func notifyWhenInteractionEnds(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void
    ) {
        notifyWhenInteractionChanges(handler)
    }

    func performAlongsideAnimations() {
        guard !alongsideFlushed else { return }
        alongsideFlushed = true
        for item in items { item.animation?(self) }
    }

    func setInteractive(_ value: Bool) {
        guard isInteractive != value else { return }
        isInteractive = value
        for handler in interactionHandlers { handler(self) }
    }

    func flushAlongsideIfNeeded(duration: TimeInterval) {
        guard !alongsideFlushed else { return }
        if duration <= 1e-12 {
            performAlongsideAnimations()
            return
        }
        UIView.animate(withDuration: duration, animations: {
            self.performAlongsideAnimations()
        })
    }

    func complete(cancelled: Bool) {
        guard !finished else { return }
        finished = true
        isCancelled = cancelled
        if isInteractive { setInteractive(false) }
        if !alongsideFlushed { performAlongsideAnimations() }
        for item in items { item.completion?(self) }
        detach()
    }
}

// MARK: - Interactive transitioning

@preconcurrency @MainActor
public protocol UIViewControllerInteractiveTransitioning: AnyObject {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    var completionSpeed: CGFloat { get }
    var completionCurve: UIView.AnimationCurve { get }
    var wantsInteractiveStart: Bool { get }
}

extension UIViewControllerInteractiveTransitioning {
    public var completionSpeed: CGFloat { 1 }
    public var completionCurve: UIView.AnimationCurve { .easeInOut }
    public var wantsInteractiveStart: Bool { true }
}

@preconcurrency @MainActor
open class UIPercentDrivenInteractiveTransition: UIViewControllerInteractiveTransitioning {
    public private(set) var duration: CGFloat = 0
    public private(set) var percentComplete: CGFloat = 0
    public var completionSpeed: CGFloat = 1
    public var completionCurve: UIView.AnimationCurve = .easeInOut
    public var timingCurve: UITimingCurveProvider?
    public var wantsInteractiveStart = true

    private weak var context: UIViewControllerContextTransitioning?
    private weak var propertyAnimator: UIViewPropertyAnimator?
    var _animator: UIViewControllerAnimatedTransitioning?

    public init() {}

    open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        context = transitionContext
        if let animator = _animator {
            duration = CGFloat(animator.transitionDuration(using: transitionContext))
            if let interruptible = animator.interruptibleAnimator(using: transitionContext)
                as? UIViewPropertyAnimator {
                propertyAnimator = interruptible
                if interruptible.state == .inactive {
                    interruptible.startAnimation()
                }
                interruptible.pauseAnimation()
            } else {
                animator.animateTransition(using: transitionContext)
            }
        }
    }

    open func update(_ percentComplete: CGFloat) {
        let p = min(max(percentComplete, 0), 1)
        self.percentComplete = p
        propertyAnimator?.fractionComplete = p
        context?.updateInteractiveTransition(p)
    }

    open func pause() {
        propertyAnimator?.pauseAnimation()
        context?.updateInteractiveTransition(percentComplete)
    }

    open func finish() {
        context?.finishInteractiveTransition()
        if let animator = propertyAnimator, animator.state == .active {
            animator.isReversed = false
            animator.continueAnimation(withTimingParameters: timingCurve,
                                       durationFactor: completionSpeed)
            animator.addCompletion { [weak self] _ in
                self?.context?.completeTransition(true)
            }
        } else {
            context?.completeTransition(true)
        }
    }

    open func cancel() {
        context?.cancelInteractiveTransition()
        if let animator = propertyAnimator, animator.state == .active {
            animator.isReversed = true
            animator.continueAnimation(withTimingParameters: timingCurve,
                                       durationFactor: completionSpeed)
            animator.addCompletion { [weak self] _ in
                self?.context?.completeTransition(false)
            }
        } else {
            context?.completeTransition(false)
        }
    }
}
