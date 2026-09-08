// UIViewController. Owner: viewcontroller module (M7.5 navigation).
//
// UIKit semantics implemented here:
//   - `view` loads lazily: first access runs loadView() then viewDidLoad()
//     (loadView's default creates a plain UIView with nil background, like a
//     programmatic UIViewController without a nib).
//   - Appearance callbacks are driven through begin/endAppearanceTransition
//     (the same primitives UIKit exposes for container view controllers).
//     UINavigationController produces real UIKit's push/pop order with them:
//       push A -> B:  B.viewDidLoad, A.viewWillDisappear, B.viewWillAppear,
//                     ...transition..., A.viewDidDisappear, B.viewDidAppear
//       pop  B -> A:  B.viewWillDisappear, A.viewWillAppear,
//                     ...transition..., B.viewDidDisappear, A.viewDidAppear
//     A cancelled interactive pop replays the reversed pair on both sides
//     (willAppear/didAppear on the still-top VC), matching UIKit.
//   - Containment: addChild/removeFromParent with the documented automatic
//     willMove/didMove calls (addChild calls child.willMove(toParent:);
//     removeFromParent calls child.didMove(toParent: nil)).
//
// No run loop exists in the portable core: appearance "did" callbacks around
// animated transitions fire when the host's clock reaches the transition end
// (UIWindow.tick -> UINavigationController._stepTransitions).

/// Container-controller view class (same name real UIKit dumps for
/// UINavigationController / UITabBarController — compare.py treats it as
/// private and prunes the subtree on both sides).
@preconcurrency @MainActor
final class UILayoutContainerView: UIView {
    /// Last size `UINavigationController.updateContainerLayout` ran at.
    /// `loadView` builds a 390×844 view; the window then assigns its own
    /// bounds (Ledger SE 375×667 / 667×375). Without a size-change pass the
    /// bottom-docked search stays at y 758 of the loadView frame.
    var _lastNavigationLayoutSize: CGSize = .zero
    /// The navigation bar's y is `max(safeArea.top, 10)` (MEASURED
    /// navprobe.barorigin). Re-frame when the window's insets arrive, and
    /// when the container is first sized to the window (MEASURED Ledger
    /// t200: slot `[0, 581, 375, 86]` in a 375×667 window).
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        (_managingViewController as? UINavigationController)?.updateContainerLayout()
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != _lastNavigationLayoutSize,
              let nav = _managingViewController as? UINavigationController else { return }
        _lastNavigationLayoutSize = bounds.size
        nav.updateContainerLayout()
    }
}

/// The container contract UIViewController adopts on UIKit. The Objective-C
/// protocol inherits NSObjectProtocol. OpenUIKit's responder classes now do
/// inherit NSObject; this protocol retains its historical `AnyObject`
/// constraint so non-responder portable containers are not source-broken.
@preconcurrency @MainActor
public protocol UIContentContainer: AnyObject {
    var preferredContentSize: CGSize { get }
    func preferredContentSizeDidChange(
        forChildContentContainer container: UIContentContainer)
    func systemLayoutFittingSizeDidChange(
        forChildContentContainer container: UIContentContainer)
    func size(
        forChildContentContainer container: UIContentContainer,
        withParentContainerSize parentSize: CGSize
    ) -> CGSize
    func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator)
    func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator)
}

@preconcurrency @MainActor
open class UIViewController: UIResponder, UIContentContainer {
#if !canImport(Foundation)
    open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                           change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {}
#endif

    private let _nibName: String?
    private let _nibBundle: Bundle
    private let _hasExplicitNibRequest: Bool

    /// Handler-form trait registrations are owned by the observable, as in
    /// UIKit. Keeping them here (rather than on the root view) makes a token
    /// survive lazy view loading and root-view replacement without forcing a
    /// view load at registration time.
    var _traitRegistrations: [UITraitChangeRegistration] = []
    var _legacyTopLayoutGuide: _UILegacyLayoutSupportView?
    var _legacyBottomLayoutGuide: _UILegacyLayoutSupportView?

    /// Designated initializer for UIKit source compatibility. Defaulted
    /// arguments keep `UIViewController()` and `super.init()` working
    /// (MEASURED Focus AutocompleteSettingViewController.swift:19 —
    /// a separate parameterless `init()` made that file's `convenience
    /// init()` an override that the unmodified source does not mark).
    /// OpenUIKit has no Interface Builder archive loader: nil/nil is the
    /// ordinary programmatic path, while an explicit nib request remains
    /// lazy and is rejected only if this class's default `loadView()` is
    /// ultimately used.
    public init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        _nibName = nibNameOrNil
        _nibBundle = nibBundleOrNil ?? .main
        _hasExplicitNibRequest = nibNameOrNil != nil || nibBundleOrNil != nil
        super.init()
    }

    /// The requested nib name, retained even though the portable core cannot
    /// decode nib archives.
    open var nibName: String? { _nibName }

    /// UIKit normalizes a nil initializer argument to `Bundle.main`; a
    /// Catalyst 26.1 oracle reports that value for both `init()` and nil/nil.
    open var nibBundle: Bundle? { _nibBundle }

    // MARK: View loading (lazy loadView/viewDidLoad)

    var _view: UIView? {
        didSet {
            _legacyTopLayoutGuide = nil
            _legacyBottomLayoutGuide = nil
            _view?._managingViewController = self
            _view?._additionalSafeAreaInsets = additionalSafeAreaInsets
        }
    }

    /// The controller's view. First access loads it (loadView + viewDidLoad).
    public var view: UIView! {
        get {
            loadViewIfNeeded()
            return _view
        }
        set { _view = newValue }
    }

    public var isViewLoaded: Bool { _view != nil }
    public var viewIfLoaded: UIView? { _view }

    /// Deprecated iOS 7–10 layout guides. iOS 11 maps them onto the safe-area
    /// band (`UIViewController.h`: use `safeAreaLayoutGuide`). SnapKit 5.7.0
    /// Tests.swift:722 pins `make.top.equalTo(vc.topLayoutGuide.snp.bottom)`.
    /// Length is `safeAreaInsets.top` / `.bottom` (0 for an unattached VC).
    public var topLayoutGuide: UILayoutSupport {
        if let g = _legacyTopLayoutGuide { return g }
        let g = _UILegacyLayoutSupportView()
        g.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(g)
        NSLayoutConstraint.activate([
            g.topAnchor.constraint(equalTo: view.topAnchor),
            g.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            g.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            g.heightAnchor.constraint(equalToConstant: view.safeAreaInsets.top),
        ])
        _legacyTopLayoutGuide = g
        return g
    }

    public var bottomLayoutGuide: UILayoutSupport {
        if let g = _legacyBottomLayoutGuide { return g }
        let g = _UILegacyLayoutSupportView()
        g.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(g)
        NSLayoutConstraint.activate([
            g.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            g.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            g.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            g.heightAnchor.constraint(equalToConstant: view.safeAreaInsets.bottom),
        ])
        _legacyBottomLayoutGuide = g
        return g
    }

    public func loadViewIfNeeded() {
        guard _view == nil else { return }
        loadView()
        if _view == nil { _view = UIView() } // loadView() that set nothing
        viewDidLoad()
    }

    // MARK: Responder chain (lifecycle module, M12)

    /// UIKit: a presented view controller's next responder is the
    /// controller that PRESENTED it; otherwise it is the controller's view's
    /// superview — which is the window when this is a window's root
    /// controller, and the container's view for a child of a container.
    ///
    /// (The presented case needs the explicit hop because OpenUIKit installs
    /// the presentation container in the WINDOW, not inside the presenter's
    /// view — see UIPresentation.present. Without it a sheet's chain would
    /// skip the presenter, which UIKit documents that it does not.)
    open override var next: UIResponder? {
        if let presenting = presentingViewController, _presentationContainer != nil {
            return presenting
        }
        return viewIfLoaded?.superview
    }

    /// A controller takes focus in the window its view is installed in
    /// (UIKit: a controller whose view is not in a window cannot become
    /// first responder either).
    override var _firstResponderWindow: UIWindow? { viewIfLoaded?.window }

    /// Create `self.view`. Default: a plain UIView with a portrait-phone
    /// frame and nil (transparent) background — the same as a programmatic
    /// UIViewController without a nib. Containers re-frame the view anyway.
    open func loadView() {
        // UIKit's rule: a controller with a nib gets its view from the nib's
        // `view` outlet on the File's Owner (UINib.swift). The name defaults
        // to the class's own, which is how the pocket-casts settings screens
        // are written — `StorageAndDataUseViewController` names no nib and
        // gets `StorageAndDataUseViewController.xib`.
        let candidate = _nibName ?? String(describing: type(of: self))
        let nib = UINib(nibName: candidate, bundle: _nibBundle)
        if nib.isLoaded {
            _ = nib.instantiate(withOwner: self, options: nil)
            if _view != nil { return }
        }
        if _hasExplicitNibRequest {
            let requestedName = _nibName ?? "<class-named nib>"
            fatalError(
                "OpenUIKit could not load Interface Builder nib '\(requestedName)'; "
                + "point OpenUIKitRuntime.nibSearchPaths at it, or override "
                + "loadView() to construct the view programmatically")
        }
        view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    }

    /// Called exactly once, right after loadView().
    open func viewDidLoad() {}

    // MARK: Safe area (app-compat cluster — AutoLayout/UILayoutGuide.swift)

    /// Extra insets added to the view's inherited safe area. UIKit's only
    /// app-facing lever on the safe area, and how a container reserves room
    /// for chrome it draws over its child (a nav bar, a tab bar).
    ///
    /// Note the divergence documented in docs/KNOWN_GAPS.md: OpenUIKit's own
    /// nav/tab chrome does NOT set this yet — screens under a
    /// `UITabBarController` are still told their bottom inset explicitly.
    public var additionalSafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            guard additionalSafeAreaInsets != oldValue else { return }
            _view?._additionalSafeAreaInsets = additionalSafeAreaInsets
            _view?.setNeedsLayout()
        }
    }

    // MARK: Title

    /// Shown by UINavigationController in the navigation bar (and as the
    /// next VC's back-button label). Also writes `tabBarItem.title`.
    /// MEASURED /tmp/tabs-t2000-probe, iPhone SE 2x / iOS 26.1: a plain
    /// VC with `tabBarItem.title = "Search"` then `title = "Library"`
    /// reports `tabBarItem.title == "Library"`; `navigationItem.title`
    /// alone does not. Creating the item if it was nil matches the probe
    /// (`child.tabBarItem` is nil before the set, non-nil after).
    public var title: String? {
        didSet {
            _navigationItem?.title = title
            if let item = tabBarItem {
                item.title = title
            } else {
                tabBarItem = UITabBarItem(title: title, image: nil, tag: 0)
            }
            navigationController?._titleDidChange(self)
        }
    }

    // MARK: Navigation item (M13 — bars & appearance)

    var _navigationItem: UINavigationItem?
    /// The bar configuration a parent `UINavigationController` displays for
    /// this controller. Created on first access, like UIKit, and seeded from
    /// `title`.
    public var navigationItem: UINavigationItem {
        if let item = _navigationItem { return item }
        let item = UINavigationItem(title: title)
        _navigationItem = item
        return item
    }

    /// Items for the parent navigation controller's toolbar.
    public var toolbarItems: [UIBarButtonItem]? {
        didSet { navigationController?._toolbarItemsDidChange(self) }
    }

    // MARK: Modal presentation (M10 — see UIPresentation.swift)

    /// Style used the next time this controller is PRESENTED.
    /// `.automatic` resolves to `.pageSheet` (the iOS default).
    public var modalPresentationStyle: UIModalPresentationStyle = .automatic

    /// Transition requested for the next modal presentation. UIKit defaults
    /// this to `.coverVertical`; OpenUIKit retains the exact public state while
    /// its built-in presenter continues to use the measured transitions in
    /// UIPresentation.swift.
    @available(iOS 3.0, *)
    open var modalTransitionStyle: UIModalTransitionStyle = .coverVertical

    /// UIKit's accessor. Creating it is what an app's
    /// `vc.popoverPresentationController?.sourceView = v` line does; the
    /// controller is remembered so the presentation uses it.
    ///
    /// NOTE (measured, and the reason UIAlertController never touches this):
    /// on real iOS 26 merely configuring an action sheet's popover flips it
    /// into a popover presentation and silently drops its cancel action.
    @available(iOS 8.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    open var popoverPresentationController: UIPopoverPresentationController? {
        if let existing = _popoverController { return existing }
        let controller = UIPopoverPresentationController(
            presentedViewController: self,
            presenting: nil
        )
        _popoverController = controller
        return controller
    }

    /// The dimming view swallows touches either way — there is no
    /// tap-outside-to-dismiss. Setting it true DOES now suppress the
    /// interactive drag-to-dismiss (the sheet tracks the finger and always
    /// springs back), matching UIKit's intent; UIKit additionally stiffens
    /// the drag itself, which is not measured here.
    public var isModalInPresentation = false

    /// Orientations this controller allows. UIKit's base implementation is
    /// device-family dependent: phones exclude upside-down portrait while
    /// iPads permit all four interface orientations.
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }

    /// UIKit's legacy rotation gate defaults to enabled. Modern hosts should
    /// primarily consult `supportedInterfaceOrientations`, but open-source
    /// controllers still commonly override both surfaces.
    open var shouldAutorotate: Bool { true }

    /// Foreground treatment requested for host-owned status-bar content.
    /// OpenUIKit itself draws no system status bar; hosts may consume this
    /// policy when presenting a controller.
    open var preferredStatusBarStyle: UIStatusBarStyle { .default }

    /// The controller this one is currently presenting.
    public internal(set) var presentedViewController: UIViewController?
    /// The controller that presented this one.
    public internal(set) weak var presentingViewController: UIViewController?

    /// The object that owns this presentation's chrome and geometry while
    /// this controller is presented (M12 — UIPresentationController.swift).
    /// UIKit exposes it under the same name.
    public internal(set) var presentationController: UIPresentationController? {
        get { _presentationController }
        set { _presentationController = newValue }
    }
    var _presentationController: UIPresentationController?
    /// The in-flight modal transition's context (kept alive for the duration
    /// of the animation; a custom animator may hold onto it).
    var _activeTransitionContext: UIViewControllerContextTransitioning?
    /// Public `transitionCoordinator` while a push/pop/present/dismiss is in
    /// flight. MEASURED animprobe, iPhone SE 2x / iOS 26.1.
    var _transitionCoordinator: UIViewControllerTransitionCoordinator?

    /// UIKit returns a local coordinator while a presentation, navigation
    /// transition or size change is active, then asks the containing
    /// controller. MEASURED animprobe, iPhone SE 2x / iOS 26.1: non-nil on
    /// from, to and the navigation controller during an animated push
    /// through viewDidAppear, then nil.
    open var transitionCoordinator: UIViewControllerTransitionCoordinator? {
        _transitionCoordinator ?? parent?.transitionCoordinator
    }

    /// App hook for custom present/dismiss animations and a custom
    /// presentation controller (M12 — UIViewControllerTransitioning.swift).
    public weak var transitioningDelegate: UIViewControllerTransitioningDelegate?

    /// Lazily created by `sheetPresentationController` (UIPresentation.swift).
    var _sheetController: UISheetPresentationController?
    /// Lazily created by `popoverPresentationController`
    /// (UIAdaptivePresentation.swift).
    var _popoverController: UIPopoverPresentationController?

    /// The presentation controller `present(_:animated:)` uses when no
    /// transitioning delegate supplies one. Overridden by UIAlertController.
    func _makeDefaultPresentationController(presenting: UIViewController)
        -> UIPresentationController {
        // Pad regular-width `.popover` stays a popover (Modal-ipad t9200).
        // Compact width still goes through the sheet (adaptedStyle).
        if _resolvedPresentationStyle == .popover {
            let p = _popoverController
                ?? UIPopoverPresentationController(presentedViewController: self,
                                                   presenting: presenting)
            _popoverController = p
            return p
        }
        let c = _sheetController
            ?? UISheetPresentationController(presentedViewController: self, presenting: nil)
        _sheetController = c
        c.sheetStyle = _resolvedPresentationStyle
        // A `.popover` presentation adapts to this sheet on compact width
        // (see UIAdaptivePresentation.swift); forward the popover
        // controller's delegate so the adaptive/dismissal callbacks still
        // reach the app.
        if c.delegate == nil, let p = _popoverController { c.delegate = p.delegate }
        return c
    }

    /// The built-in modal animators. Overridden by UIAlertController.
    func _makeDefaultPresentAnimator() -> UIViewControllerAnimatedTransitioning {
        _UIPageSheetAnimator(presenting: true)
    }
    func _makeDefaultDismissAnimator() -> UIViewControllerAnimatedTransitioning {
        _UIPageSheetAnimator(presenting: false)
    }

    /// True while a disappearance transition is in flight (the interactive
    /// dismissal teardown uses it to keep will/did appearance calls paired).
    var _isDisappearing: Bool { _appearanceState == .disappearing }

    // MARK: Content scroll view (M10 large titles)

    /// The scroll view a parent UINavigationController's bar tracks for
    /// large-title expansion/collapse (analog of UIKit's
    /// `setContentScrollView(_:for:)`). Explicit binding only — there is no
    /// automatic detection.
    public internal(set) weak var _contentScrollView: UIScrollView?

    public func setContentScrollView(_ scrollView: UIScrollView?) {
        _contentScrollView = scrollView
        navigationController?._contentScrollViewDidChange(self)
    }

    // MARK: Tab bar item (M10)

    /// The item representing this controller in a parent UITabBarController.
    /// Lazily defaulted from `title` when the controller joins a tab
    /// controller without one.
    public var tabBarItem: UITabBarItem?

    /// Nearest ancestor tab bar controller (UIKit semantics).
    public var tabBarController: UITabBarController? {
        var p = parent
        while let cur = p {
            if let tab = cur as? UITabBarController { return tab }
            p = cur.parent
        }
        return nil
    }

    // MARK: Appearance callbacks

    open func viewWillAppear(_ animated: Bool) {}
    open func viewDidAppear(_ animated: Bool) {}
    open func viewWillDisappear(_ animated: Bool) {}
    open func viewDidDisappear(_ animated: Bool) {}

    // MARK: Layout callbacks (app-compat, 2026-08-28)
    //
    // Real UIKit brackets the root view's `layoutSubviews` with these two, and
    // app code puts real work in them (focus-ios positions its URL bar from
    // `viewDidLayoutSubviews`). They FIRE — `UIView._layoutSubtree` calls them
    // around the layout of the view whose `_managingViewController` is self —
    // rather than being declared and silent, which would be the failure this
    // whole surface exists to avoid.

    open func viewWillLayoutSubviews() {}
    open func viewDidLayoutSubviews() {}

    /// The controller's half of the update-constraints pass. Runs before
    /// layout, once per pass, when something has called
    /// `view.setNeedsUpdateConstraints()` — see `UIView.updateConstraints()`.
    /// An override must call `super`, as in UIKit.
    open func updateViewConstraints() {
        _view?.updateConstraints()
    }

    // MARK: Content size (app-compat, 2026-08-28)

    /// The size this controller would like when presented in a container that
    /// asks — a popover in UIKit. OpenUIKit presents nothing that consults it,
    /// so it is STORAGE plus the notification UIKit sends: setting it tells
    /// the parent through `preferredContentSizeDidChange(forChildContentContainer:)`,
    /// which is the part app code observes. `.zero` means "no preference",
    /// as in UIKit.
    open var preferredContentSize: CGSize = .zero {
        didSet {
            guard preferredContentSize != oldValue else { return }
            parent?.preferredContentSizeDidChange(forChildContentContainer: self)
        }
    }

    /// UIKit's `UIContentContainer` callback. Default does nothing.
    open func preferredContentSizeDidChange(
        forChildContentContainer container: UIContentContainer) {}

    /// Notification bridge for a child whose Auto Layout fitting size
    /// changed. UIKit's UIViewController base implementation is a no-op; a
    /// presentation/container subclass decides how that affects its chrome.
    open func systemLayoutFittingSizeDidChange(
        forChildContentContainer container: UIContentContainer) {}

    /// UIKit's default answer is the proposed parent size unchanged.
    open func size(
        forChildContentContainer container: UIContentContainer,
        withParentContainerSize parentSize: CGSize
    ) -> CGSize {
        parentSize
    }

    /// UIKit's `UIContentContainer` size-transition callback (a rotation, or a
    /// window resize). OpenUIKit never rotates a window on its own; a HOST
    /// that resizes its surface is what calls this, so the callback exists and
    /// is deliverable but nothing in the library triggers it.
    /// docs/KNOWN_GAPS.md.
    open func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        // UIKit's base implementation forwards top-down through containment.
        // A custom container can override `size(forChild…:)`; if the child is
        // already at that size UIKit suppresses the redundant callback.
        for child in children {
            let childSize = self.size(
                forChildContentContainer: child,
                withParentContainerSize: size)
            if child.viewIfLoaded?.bounds.size != childSize {
                child.viewWillTransition(to: childSize, with: coordinator)
            }
        }
    }

    /// Trait-transition counterpart of `viewWillTransition(to:with:)`.
    /// Calling super propagates the transition through contained children.
    open func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        for child in children {
            child.willTransition(to: newCollection, with: coordinator)
        }
    }

    /// Legacy iOS 8–16 trait-change override still used by focus-ios. Hosts
    /// deliver it through `UIView._traitsDidChange(previous:)`; the modern
    /// registration callbacks use that same delivery path.
    open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {}

    /// A controller inherits traits from its loaded root view, then its
    /// containing controller. Before either relationship exists, the main
    /// screen completes any process-wide unspecified size axes so view-load
    /// code observes the same portable environment as a detached UIView.
    public var traitCollection: UITraitCollection {
        viewIfLoaded?.traitCollection
            ?? parent?.traitCollection
            ?? UIScreen.main._currentTraitsResolvingSizeClasses
    }

    /// Which edges a full-screen child extends under. Stored; OpenUIKit's
    /// containers inset their children explicitly rather than consulting it
    /// (docs/KNOWN_GAPS.md, "App compatibility").
    open var edgesForExtendedLayout: UIRectEdge = .all
    open var extendedLayoutIncludesOpaqueBars = false

    enum AppearanceState { case disappeared, appearing, appeared, disappearing }
    var _appearanceState: AppearanceState = .disappeared
    var _appearanceAnimated = false

    /// Container-VC primitive (public in UIKit): start an appearance
    /// transition. Loads the view and calls viewWillAppear/viewWillDisappear.
    /// Idempotent while a transition in the same direction is in flight;
    /// reversing an in-flight transition (interactive-pop cancel) issues the
    /// opposite "will" callback, like UIKit.
    public func beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
        if isAppearing {
            guard _appearanceState != .appeared, _appearanceState != .appearing
            else { return }
            _appearanceState = .appearing
            _appearanceAnimated = animated
            loadViewIfNeeded()
            viewWillAppear(animated)
            // Collection lifecycle oracle (iPhone16/iOS26.1): nonanimated
            // selection clearing occurs after willAppear, before the next
            // appearance phase. Other controller families are unaffected.
            if !animated {
                (self as? UICollectionViewController)?._clearSelectionForAppearance()
            }
        } else {
            guard _appearanceState != .disappeared,
                  _appearanceState != .disappearing else { return }
            _appearanceState = .disappearing
            _appearanceAnimated = animated
            viewWillDisappear(animated)
        }
    }

    /// Finish the in-flight appearance transition: calls viewDidAppear /
    /// viewDidDisappear to match the pending "will" callback.
    public func endAppearanceTransition() {
        switch _appearanceState {
        case .appearing:
            // Animated collection returns retain selection during appearance,
            // then clear it before entering the subclass's didAppear callback.
            if _appearanceAnimated {
                (self as? UICollectionViewController)?._clearSelectionForAppearance()
            }
            _appearanceState = .appeared
            viewDidAppear(_appearanceAnimated)
        case .disappearing:
            _appearanceState = .disappeared
            viewDidDisappear(_appearanceAnimated)
        case .appeared, .disappeared:
            break
        }
    }

    // MARK: Containment

    public private(set) var children: [UIViewController] = []
    public internal(set) weak var parent: UIViewController?

    /// UIKit: automatically calls child.willMove(toParent: self). The caller
    /// (container) calls child.didMove(toParent:) once the child's view is
    /// installed.
    public func addChild(_ child: UIViewController) {
        guard child.parent !== self else { return }
        child.removeFromParent()
        child.willMove(toParent: self)
        children.append(child)
        child.parent = self
    }

    /// UIKit: the container calls willMove(toParent: nil) first; this method
    /// then automatically calls didMove(toParent: nil).
    public func removeFromParent() {
        guard let p = parent else { return }
        p.children.removeAll { $0 === self }
        parent = nil
        didMove(toParent: nil)
    }

    open func willMove(toParent parent: UIViewController?) {}
    open func didMove(toParent parent: UIViewController?) {}

    /// Nearest ancestor navigation controller (UIKit semantics).
    public var navigationController: UINavigationController? {
        var p = parent
        while let cur = p {
            if let nav = cur as? UINavigationController { return nav }
            p = cur.parent
        }
        return nil
    }

    /// Split-view detail routing; standalone controllers use presentation.
    /// The split-specific delegate and column behavior is measured in
    /// Tools/oracle2/splitviewprobe (iOS 26.1, iPad A16 and SE).
    open func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if let split = splitViewController {
            split.showDetailViewController(vc, sender: sender)
        } else {
            present(vc, animated: true)
        }
    }

    /// Display a controller using the receiver's containing navigation stack
    /// when one exists, otherwise use the ordinary modal presentation path.
    open func show(_ vc: UIViewController, sender: Any?) {
        _ = sender
        if let nav = self as? UINavigationController ?? navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
}
