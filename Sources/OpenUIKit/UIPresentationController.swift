// UIPresentationController. Owner: viewcontroller module (M12 alerts cluster).
//
// The object that owns a modal presentation's CHROME and geometry: it builds
// whatever sits around the presented view (a dimming view, a sheet platter,
// an alert's dim), decides the presented view's frame in the container, and
// receives the four transition callbacks. `UIViewController.present` drives
// it; an app can substitute its own through
// `UIViewControllerTransitioningDelegate.presentationController(forPresented:…)`.
//
// Callback ORDER (UIKit's, reproduced by the presentation code and asserted
// in Tests/PresentationControllerTests):
//   present:  presentationTransitionWillBegin
//             -> [animation] -> presentationTransitionDidEnd(true)
//   dismiss:  dismissalTransitionWillBegin
//             -> [animation] -> dismissalTransitionDidEnd(true)
// A dismissal that is torn down without an animation (the interactive sheet
// drag reaching its end state) issues the same pair.
//
// LIFETIME NOTE (divergence from UIKit, deliberate): UIKit holds
// `presentedViewController` strongly. Here the presented controller owns its
// presentation controller (`vc.sheetPresentationController` is created before
// the presentation exists and configured by app code), so the back reference
// is `unowned` to avoid a cycle. The presentation controller never outlives
// the controller it presents.

@preconcurrency @MainActor
open class UIPresentationController {
    /// The controller being presented. See the LIFETIME NOTE above.
    public unowned let presentedViewController: UIViewController
    /// The presenter. nil until the presentation actually starts (a
    /// presentation controller may be created and configured beforehand).
    public internal(set) weak var presentingViewController: UIViewController?

    /// The view every presentation view lives in; installed by
    /// `UIViewController.present` before `presentationTransitionWillBegin`.
    public internal(set) var containerView: UIView?

    /// M13: the app's adaptivity / user-dismissal delegate. See
    /// UIAdaptivePresentation.swift for exactly which members are wired.
    public weak var delegate: UIAdaptivePresentationControllerDelegate?

    public init(presentedViewController: UIViewController,
                presenting presentingViewController: UIViewController?) {
        self.presentedViewController = presentedViewController
        self.presentingViewController = presentingViewController
    }

    /// The view the animator moves. Default: the presented controller's own
    /// view. Subclasses that wrap it in chrome (the page sheet's platter)
    /// return the wrapper.
    open var presentedView: UIView? { presentedViewController.viewIfLoaded }

    /// Where `presentedView` sits once presented. Default: the whole
    /// container.
    open var frameOfPresentedViewInContainerView: CGRect {
        containerView?.bounds ?? .zero
    }

    /// True when the presentation covers the presenter completely — the
    /// presenter then gets disappearance callbacks. A sheet or an alert
    /// leaves the presenter visible and returns false.
    open var shouldRemovePresentersView: Bool { false }

    // MARK: Transition callbacks

    /// Install the chrome. Called with `containerView` already set, BEFORE
    /// the animation starts.
    open func presentationTransitionWillBegin() {}
    open func presentationTransitionDidEnd(_ completed: Bool) {}
    open func dismissalTransitionWillBegin() {}
    /// Tear the chrome down. `completed` is false only if a dismissal was
    /// abandoned (no interactive dismissal is cancellable today).
    open func dismissalTransitionDidEnd(_ completed: Bool) {}

    open func containerViewWillLayoutSubviews() {}
    open func containerViewDidLayoutSubviews() {}
}
