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
// `@objc` members (OPENUIKIT_OBJC_SUBCLASSING) need Foundation in scope; a
// scoped declaration import keeps its geometry out of this file (UIView.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
#endif

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

// Objective-C runtime name = UIKit's, and header macro SWIFT_CLASS_NAMED:
// Objective-C app classes may subclass it (vtable-free, see
// ObjCSubclassing.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UIViewController)
#endif
@preconcurrency @MainActor
open class UIViewController: UIResponder, UIContentContainer {
#if !canImport(Foundation)
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func observeValue(forKeyPath keyPath: String?, of object: Any?,
                           change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {}
#endif
#if !(canImport(ObjectiveC) && canImport(Foundation))
    // The storyboard segue hooks (UIStoryboard.swift). Where Objective-C and
    // Foundation are both present they are `@objc` extension members; a
    // Foundation-hidden guest library cannot represent a `String` parameter
    // in Objective-C and a Linux build has no `@objc`, so there they are
    // declared here, where an app subclass can still override them.
    open func performSegue(withIdentifier identifier: String, sender: Any?) {
        _performSegue(withIdentifier: identifier, sender: sender)
    }
    open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool { true }
    open func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
#endif

    private final let _nibName: String?
    private final let _nibBundle: Bundle
    private final let _hasExplicitNibRequest: Bool

    /// Handler-form trait registrations are owned by the observable, as in
    /// UIKit. Keeping them here (rather than on the root view) makes a token
    /// survive lazy view loading and root-view replacement without forcing a
    /// view load at registration time.
    final var _traitRegistrations: [UITraitChangeRegistration] = []
    final var _legacyTopLayoutGuide: _UILegacyLayoutSupportView?
    final var _legacyBottomLayoutGuide: _UILegacyLayoutSupportView?

    /// Designated initializer for UIKit source compatibility. Defaulted
    /// arguments keep `UIViewController()` and `super.init()` working
    /// (MEASURED Focus AutocompleteSettingViewController.swift:19 —
    /// a separate parameterless `init()` made that file's `convenience
    /// init()` an override that the unmodified source does not mark).
    /// OpenUIKit has no Interface Builder archive loader: nil/nil is the
    /// ordinary programmatic path, while an explicit nib request remains
    /// lazy and is rejected only if this class's default `loadView()` is
    /// ultimately used.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public dynamic init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        _nibName = nibNameOrNil
        _nibBundle = nibBundleOrNil ?? .main
        _hasExplicitNibRequest = nibNameOrNil != nil || nibBundleOrNil != nil
        super.init()
    }

    /// UIKit's required keyed-archive initializer, the base every
    /// storyboard/nib-backed subclass's `required init?(coder:)` chains to.
    /// MEASURED (Tools/oracle2/viewcontrollercoderprobe, iPhone 16 / iOS
    /// 26.1, `base.coder`): on an empty keyed archive the result is non-nil,
    /// unloaded, `nibName` nil, `nibBundle` `Bundle.main`, `title` nil, and
    /// the first `view` access builds the same plain view as `init()` does
    /// (autoresizing 18, nil background). OpenUIKit has no archive reader:
    /// the coder is not consulted (a bare `NSCoder()` is abstract on Darwin
    /// Foundation and every decode call on it raises), so the archive keys
    /// Apple round-trips (`UITitle`, `UIRestorationIdentifier`,
    /// `base.roundTrip`) are not read and this path is exactly the nil/nil
    /// programmatic initializer with a different spelling.
    ///
    /// From a storyboard (`UINibCoder`), the archived controller state is
    /// decoded too: `nibName` is the scene's view nib (MEASURED
    /// `roo-00-001-view-rtv-00-001` for the probe's root), and `title`, the
    /// navigation item, segue templates and child controllers are set before
    /// this returns (UIStoryboard.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public required dynamic init?(coder: NSCoder) {
        _nibName = UINibCoder.archivedString(coder, "UINibName")
        _nibBundle = .main
        _hasExplicitNibRequest = false
        super.init()
        UINibCoder.decodeControllerState(self, from: coder)
    }

    /// The requested nib name, retained even though the portable core cannot
    /// decode nib archives.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var nibName: String? { _nibName }

    /// UIKit normalizes a nil initializer argument to `Bundle.main`; a
    /// Catalyst 26.1 oracle reports that value for both `init()` and nil/nil.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var nibBundle: Bundle? { _nibBundle }

    // MARK: View loading (lazy loadView/viewDidLoad)

    final var _view: UIView? {
        didSet {
            _legacyTopLayoutGuide = nil
            _legacyBottomLayoutGuide = nil
            _view?._managingViewController = self
            _view?._additionalSafeAreaInsets = additionalSafeAreaInsets
        }
    }

    /// The controller's view. First access loads it (loadView + viewDidLoad).
    public final var view: UIView! {
        get {
            loadViewIfNeeded()
            return _view
        }
        set { _view = newValue }
    }

    public final var isViewLoaded: Bool { _view != nil }
    public final var viewIfLoaded: UIView? { _view }

    /// Deprecated iOS 7–10 layout guides. iOS 11 maps them onto the safe-area
    /// band (`UIViewController.h`: use `safeAreaLayoutGuide`). SnapKit 5.7.0
    /// Tests.swift:722 pins `make.top.equalTo(vc.topLayoutGuide.snp.bottom)`.
    /// Length is `safeAreaInsets.top` / `.bottom` (0 for an unattached VC).
    public final var topLayoutGuide: UILayoutSupport {
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

    public final var bottomLayoutGuide: UILayoutSupport {
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

    public final func loadViewIfNeeded() {
        guard _view == nil else { return }
        loadView()
        if _view == nil { _view = UIView() } // loadView() that set nothing
        // Storyboard embed segues run here, after loadView and before
        // viewDidLoad (MEASURED order, UIStoryboard.swift).
        _performSeguesOnViewLoad()
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
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func loadView() {
        // A storyboard controller's view is its scene's view nib.
        if _loadStoryboardView() { return }
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
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewDidLoad() {}

    // MARK: Safe area (app-compat cluster — AutoLayout/UILayoutGuide.swift)

    /// Extra insets added to the view's inherited safe area. UIKit's only
    /// app-facing lever on the safe area, and how a container reserves room
    /// for chrome it draws over its child (a nav bar, a tab bar).
    ///
    /// Note the divergence documented in docs/KNOWN_GAPS.md: OpenUIKit's own
    /// nav/tab chrome does NOT set this yet — screens under a
    /// `UITabBarController` are still told their bottom inset explicitly.
    public final var additionalSafeAreaInsets: UIEdgeInsets = .zero {
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
    public final var title: String? {
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

    final var _navigationItem: UINavigationItem?
    /// The bar configuration a parent `UINavigationController` displays for
    /// this controller. Created on first access, like UIKit, and seeded from
    /// `title`.
    public final var navigationItem: UINavigationItem {
        if let item = _navigationItem { return item }
        let item = UINavigationItem(title: title)
        _navigationItem = item
        return item
    }

    /// Items for the parent navigation controller's toolbar.
    public final var toolbarItems: [UIBarButtonItem]? {
        didSet { navigationController?._toolbarItemsDidChange(self) }
    }

    // MARK: Modal presentation (M10 — see UIPresentation.swift)

    /// Style used the next time this controller is PRESENTED.
    /// `.automatic` resolves to `.pageSheet` (the iOS default).
    public final var modalPresentationStyle: UIModalPresentationStyle = .automatic

    /// Transition requested for the next modal presentation. UIKit defaults
    /// this to `.coverVertical`; OpenUIKit retains the exact public state while
    /// its built-in presenter continues to use the measured transitions in
    /// UIPresentation.swift.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    @available(iOS 3.0, *)
    open dynamic var modalTransitionStyle: UIModalTransitionStyle = .coverVertical

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
    ///
    /// Keeps a Swift vtable slot (UIPopoverPresentationController is not an
    /// Objective-C class here); apps override it, so it stays `open`.
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
    public final var isModalInPresentation = false

    /// Orientations this controller allows. UIKit's base implementation is
    /// device-family dependent: phones exclude upside-down portrait while
    /// iPads permit all four interface orientations.
    ///
    /// Keeps a Swift vtable slot (UIInterfaceOrientationMask is a Swift
    /// option set, not Objective-C); OpenUIKit reads it through
    /// `_supportedInterfaceOrientationsDispatch` (ObjCSubclassing.swift).
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _baseSupportedInterfaceOrientations
    }
    final var _baseSupportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }

    /// UIKit's legacy rotation gate defaults to enabled. Modern hosts should
    /// primarily consult `supportedInterfaceOrientations`, but open-source
    /// controllers still commonly override both surfaces.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var shouldAutorotate: Bool { true }

    /// Foreground treatment requested for host-owned status-bar content.
    /// OpenUIKit itself draws no system status bar; hosts may consume this
    /// policy when presenting a controller.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var preferredStatusBarStyle: UIStatusBarStyle { .default }

    /// MEASURED iOS 26.1: false for a plain and a split view controller.
    /// The host owns the status bar; the port reports the preference.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var prefersStatusBarHidden: Bool { false }

    /// MEASURED iOS 26.1: `.fade` by default.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }

    /// The port draws no status bar, so there is nothing to re-query; the
    /// call is accepted (NetNewsWire SceneCoordinator.swift:1465).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func setNeedsStatusBarAppearanceUpdate() {}

    /// Called when the root view's safe-area insets change (MEASURED iOS
    /// 26.1: once at launch with the window's [59, 0, 34, 0], between
    /// viewWillAppear and sceneWillEnterForeground). Dispatched from
    /// UIView's safe-area propagation (UILayoutGuide.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewSafeAreaInsetsDidChange() {}

    /// The controller this one is currently presenting.
    public internal(set) final var presentedViewController: UIViewController?
    /// The controller that presented this one.
    public internal(set) weak final var presentingViewController: UIViewController?

    /// The object that owns this presentation's chrome and geometry while
    /// this controller is presented (M12 — UIPresentationController.swift).
    /// UIKit exposes it under the same name.
    public internal(set) final var presentationController: UIPresentationController? {
        get { _presentationController }
        set { _presentationController = newValue }
    }
    final var _presentationController: UIPresentationController?
    /// The in-flight modal transition's context (kept alive for the duration
    /// of the animation; a custom animator may hold onto it).
    final var _activeTransitionContext: UIViewControllerContextTransitioning?
    /// Public `transitionCoordinator` while a push/pop/present/dismiss is in
    /// flight. MEASURED animprobe, iPhone SE 2x / iOS 26.1.
    final var _transitionCoordinator: UIViewControllerTransitionCoordinator?

    /// UIKit returns a local coordinator while a presentation, navigation
    /// transition or size change is active, then asks the containing
    /// controller. MEASURED animprobe, iPhone SE 2x / iOS 26.1: non-nil on
    /// from, to and the navigation controller during an animated push
    /// through viewDidAppear, then nil.
    ///
    /// Keeps a Swift vtable slot (a Swift protocol type); read through
    /// `_transitionCoordinatorDispatch` inside OpenUIKit.
    open var transitionCoordinator: UIViewControllerTransitionCoordinator? {
        _transitionCoordinator ?? parent?._transitionCoordinatorDispatch
    }

    /// App hook for custom present/dismiss animations and a custom
    /// presentation controller (M12 — UIViewControllerTransitioning.swift).
    public weak final var transitioningDelegate: UIViewControllerTransitioningDelegate?

    /// Lazily created by `sheetPresentationController` (UIPresentation.swift).
    final var _sheetController: UISheetPresentationController?
    /// Lazily created by `popoverPresentationController`
    /// (UIAdaptivePresentation.swift).
    final var _popoverController: UIPopoverPresentationController?

    /// The presentation controller `present(_:animated:)` uses when no
    /// transitioning delegate supplies one. Overridden by UIAlertController.
    ///
    /// Vtable-free (OPENUIKIT_OBJC_SUBCLASSING): UIPresentationController and
    /// the animator protocol are not Objective-C types, so the one override
    /// (UIAlertController) is reached by type checks, here and below.
    final func _makeDefaultPresentationController(presenting: UIViewController)
        -> UIPresentationController {
        if let alert = self as? UIAlertController {
            return alert._alertPresentationController(presenting: presenting)
        }
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
    final func _makeDefaultPresentAnimator() -> UIViewControllerAnimatedTransitioning {
        if self is UIAlertController { return _UIAlertAnimator(presenting: true) }
        return _UIPageSheetAnimator(presenting: true)
    }
    final func _makeDefaultDismissAnimator() -> UIViewControllerAnimatedTransitioning {
        if self is UIAlertController { return _UIAlertAnimator(presenting: false) }
        return _UIPageSheetAnimator(presenting: false)
    }

    /// True while a disappearance transition is in flight (the interactive
    /// dismissal teardown uses it to keep will/did appearance calls paired).
    final var _isDisappearing: Bool { _appearanceState == .disappearing }

    // MARK: Content scroll view (M10 large titles)

    /// The scroll view a parent UINavigationController's bar tracks for
    /// large-title expansion/collapse (analog of UIKit's
    /// `setContentScrollView(_:for:)`). Explicit binding only — there is no
    /// automatic detection.
    public internal(set) weak final var _contentScrollView: UIScrollView?

    public final func setContentScrollView(_ scrollView: UIScrollView?) {
        _contentScrollView = scrollView
        navigationController?._contentScrollViewDidChange(self)
    }

    // MARK: Tab bar item (M10)

    /// The item representing this controller in a parent UITabBarController.
    /// Lazily defaulted from `title` when the controller joins a tab
    /// controller without one.
    public final var tabBarItem: UITabBarItem?

    /// iOS 18: the `UITab` whose provider produced this controller. MEASURED
    /// (signallastrowsprobe) set as soon as the provider returns, before the
    /// tab joins a controller; nil for legacy `viewControllers` children.
    public final var tab: UITab? { _tab }
    weak final var _tab: UITab?

    /// Nearest ancestor tab bar controller (UIKit semantics).
    public final var tabBarController: UITabBarController? {
        var p = parent
        while let cur = p {
            if let tab = cur as? UITabBarController { return tab }
            p = cur.parent
        }
        return nil
    }

    // MARK: Appearance callbacks

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewWillAppear(_ animated: Bool) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewDidAppear(_ animated: Bool) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewWillDisappear(_ animated: Bool) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewDidDisappear(_ animated: Bool) {}

    // MARK: Layout callbacks (app-compat, 2026-08-28)
    //
    // Real UIKit brackets the root view's `layoutSubviews` with these two, and
    // app code puts real work in them (focus-ios positions its URL bar from
    // `viewDidLayoutSubviews`). They FIRE — `UIView._layoutSubtree` calls them
    // around the layout of the view whose `_managingViewController` is self —
    // rather than being declared and silent, which would be the failure this
    // whole surface exists to avoid.

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewWillLayoutSubviews() {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func viewDidLayoutSubviews() {}

    /// The controller's half of the update-constraints pass. Runs before
    /// layout, once per pass, when something has called
    /// `view.setNeedsUpdateConstraints()` — see `UIView.updateConstraints()`.
    /// An override must call `super`, as in UIKit.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func updateViewConstraints() {
        _view?.updateConstraints()
    }

    // MARK: Content size (app-compat, 2026-08-28)

    /// The size this controller would like when presented in a container that
    /// asks — a popover in UIKit. OpenUIKit presents nothing that consults it,
    /// so it is STORAGE plus the notification UIKit sends: setting it tells
    /// the parent through `preferredContentSizeDidChange(forChildContentContainer:)`,
    /// which is the part app code observes. `.zero` means "no preference",
    /// as in UIKit.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var preferredContentSize: CGSize = .zero {
        didSet {
            guard preferredContentSize != oldValue else { return }
            parent?._preferredContentSizeDidChangeDispatch(forChildContentContainer: self)
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
        _viewWillTransitionBase(to: size, with: coordinator)
    }

    /// UIViewController's own `viewWillTransition(to:with:)` body.
    final func _viewWillTransitionBase(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        // UIKit's base implementation forwards top-down through containment.
        // A custom container can override `size(forChild…:)`; if the child is
        // already at that size UIKit suppresses the redundant callback.
        for child in children {
            let childSize = _sizeDispatch(
                forChildContentContainer: child,
                withParentContainerSize: size)
            if child.viewIfLoaded?.bounds.size != childSize {
                child._viewWillTransitionDispatch(to: childSize, with: coordinator)
            }
        }
    }

    /// Trait-transition counterpart of `viewWillTransition(to:with:)`.
    /// Calling super propagates the transition through contained children.
    open func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        _willTransitionBase(to: newCollection, with: coordinator)
    }

    /// UIViewController's own `willTransition(to:with:)` body.
    final func _willTransitionBase(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        for child in children {
            child._willTransitionDispatch(to: newCollection, with: coordinator)
        }
    }

    /// Legacy iOS 8–16 trait-change override still used by focus-ios. Hosts
    /// deliver it through `UIView._traitsDidChange(previous:)`; the modern
    /// registration callbacks use that same delivery path.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {}

    /// A controller inherits traits from its loaded root view, then its
    /// containing controller. Before either relationship exists, the main
    /// screen completes any process-wide unspecified size axes so view-load
    /// code observes the same portable environment as a detached UIView.
    public final var traitCollection: UITraitCollection {
        viewIfLoaded?.traitCollection
            ?? parent?.traitCollection
            ?? UIScreen.main._currentTraitsResolvingSizeClasses
    }

    /// Which edges a full-screen child extends under. Stored; OpenUIKit's
    /// containers inset their children explicitly rather than consulting it
    /// (docs/KNOWN_GAPS.md, "App compatibility").
    public final var edgesForExtendedLayout: UIRectEdge = .all
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var extendedLayoutIncludesOpaqueBars = false

    /// UIKit's `shouldAutomaticallyForwardAppearanceMethods` (iOS 26.1
    /// default true — iososslibraryprobe). A custom container that returns
    /// false forwards with begin/endAppearanceTransition itself (ios-oss
    /// PagedContainerViewController). OpenUIKit's built-in containers drive
    /// their children explicitly and custom containers are not auto-forwarded
    /// either way, so the value is read by nothing yet (docs/KNOWN_GAPS.md).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var shouldAutomaticallyForwardAppearanceMethods: Bool { true }

    enum AppearanceState { case disappeared, appearing, appeared, disappearing }
    final var _appearanceState: AppearanceState = .disappeared
    final var _appearanceAnimated = false

    /// Container-VC primitive (public in UIKit): start an appearance
    /// transition. Loads the view and calls viewWillAppear/viewWillDisappear.
    /// Idempotent while a transition in the same direction is in flight;
    /// reversing an in-flight transition (interactive-pop cancel) issues the
    /// opposite "will" callback, like UIKit.
    public final func beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
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
    public final func endAppearanceTransition() {
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

    public private(set) final var children: [UIViewController] = []
    public internal(set) weak final var parent: UIViewController?

    /// UIKit: automatically calls child.willMove(toParent: self). The caller
    /// (container) calls child.didMove(toParent:) once the child's view is
    /// installed.
    public final func addChild(_ child: UIViewController) {
        guard child.parent !== self else { return }
        child.removeFromParent()
        child.willMove(toParent: self)
        children.append(child)
        child.parent = self
    }

    /// UIKit: the container calls willMove(toParent: nil) first; this method
    /// then automatically calls didMove(toParent: nil).
    public final func removeFromParent() {
        guard let p = parent else { return }
        p.children.removeAll { $0 === self }
        parent = nil
        didMove(toParent: nil)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(willMoveToParentViewController:)
#endif
    open dynamic func willMove(toParent parent: UIViewController?) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(didMoveToParentViewController:)
#endif
    open dynamic func didMove(toParent parent: UIViewController?) {}

    /// Nearest ancestor navigation controller (UIKit semantics).
    public final var navigationController: UINavigationController? {
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
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if let split = splitViewController {
            split.showDetailViewController(vc, sender: sender)
        } else {
            present(vc, animated: true)
        }
    }

    /// Display a controller using the receiver's containing navigation stack
    /// when one exists, otherwise use the ordinary modal presentation path.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(showViewController:sender:)
#endif
    open dynamic func show(_ vc: UIViewController, sender: Any?) {
        _ = sender
        if let nav = self as? UINavigationController ?? navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
}

extension UIViewController {
    /// A child a storyboard archived under this controller
    /// (`UIChildViewControllers` / a navigation root relationship): parented
    /// WITHOUT the containment callbacks. MEASURED (nibruntimeprobe): the
    /// probe's root reports `parent` = its navigation controller in
    /// `awakeFromNib` and logs no `willMove`/`didMove(toParent:)` at all.
    func _adoptArchivedChild(_ child: UIViewController) {
        guard child.parent !== self else { return }
        children.append(child)
        child.parent = self
    }
}
