// Custom transitions: UIViewControllerAnimatedTransitioning + context +
// transitioning delegate. Owner: viewcontroller module (M12 alerts cluster).
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
//   - No UIViewControllerInteractiveTransitioning. The interactive back
//     swipe and the interactive sheet drag are SCRUBBED against the host
//     clock by the controllers themselves (measured physics), and routing
//     them through a percent-driven interactive protocol would change the
//     feel. A custom animator therefore runs non-interactively.
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
public protocol UIViewControllerAnimatedTransitioning: AnyObject {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    func animationEnded(_ transitionCompleted: Bool)
}

extension UIViewControllerAnimatedTransitioning {
    public func animationEnded(_ transitionCompleted: Bool) {}
}

/// An app's hook for a modal presentation: custom animators and/or a custom
/// `UIPresentationController`.
public protocol UIViewControllerTransitioningDelegate: AnyObject {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController?
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
}

// MARK: - Concrete context for modal presentations

/// The context OpenUIKit hands modal animators. `containerView` is the
/// presentation container the presentation controller installed; the "to"
/// view on a presentation is the presentation controller's `presentedView`
/// (the sheet platter), which is what the built-in animator moves.
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

    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }

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
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
}

// MARK: - Navigation transitions

/// An app's hook for push/pop animations. UIKit's protocol, minus the
/// interactive-controller member — see the file header for why.
public protocol UINavigationControllerDelegate: AnyObject {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool)
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController, animated: Bool)
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
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
}

/// The context for one push or pop. `containerView` is the navigation
/// controller's clipped content area — the same view the built-in slide moves
/// its two child views inside.
final class _UINavigationTransitionContext: UIViewControllerContextTransitioning {
    unowned let nav: UINavigationController
    let push: Bool
    let fromVC: UIViewController
    let toVC: UIViewController
    let isAnimated: Bool
    var onComplete: ((Bool) -> Void)?
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
    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }

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
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
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
        })
        nav.navigationBar.accelerateOutgoingBackFade(duration: duration)
        UINavigationController.registerTransitioning(nav)
    }
}
