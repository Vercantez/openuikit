// Measured iPhone 16 / iOS 26.1: Tools/oracle2/collectionblockingprobe,
// collection.json vc.*, and Tools/oracle2/collectioncontrollerprobe,
// collectioncontroller.json (bare background, view-first access, custom
// loadView, coder initialization, the standard reordering gesture).
// Programmatic and empty-archive controllers; nib decoding, interactive
// reordering and layout-to-layout transitions remain outside this
// implementation (docs/agent_reports/uicollectionviewcontroller.md).

@preconcurrency @MainActor
private final class UICollectionViewControllerWrapperView: UIView {
    weak var collectionController: UICollectionViewController?
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionController?._collectionView?.frame = bounds
    }
}

@preconcurrency @MainActor
open class UICollectionViewController: UIViewController,
                                      UICollectionViewDataSource, UICollectionViewDelegate {
    fileprivate var _collectionView: UICollectionView?
    /// The layout handed to `init(collectionViewLayout:)`. nil after
    /// `init?(coder:)` (coder.empty.layoutNil is true on the oracle; a nib's
    /// collection view would normally carry the layout).
    private let initialLayout: UICollectionViewLayout?
    /// Substitute for a coder-initialised controller whose archive supplied
    /// no layout. UIKit's getter reports nil there and its `collectionView`
    /// cannot load; the portable core has no archive loader, so it follows
    /// `UICollectionView.init?(coder:)` and supplies a flow layout instead of
    /// trapping. Created once so identity is stable across reads.
    private lazy var fallbackLayout = UICollectionViewFlowLayout()

    // vc.init: false isViewLoaded; clear/install true, transitions false.
    public init(collectionViewLayout layout: UICollectionViewLayout) {
        initialLayout = layout
        super.init()
    }

    /// coder.empty: a keyed archive with no entries yields a non-nil,
    /// unloaded controller with nil layout and the default preferences
    /// (true / true / false). Archive keys are not decoded: the measured
    /// round trip carries `clearsSelectionOnViewWillAppear` and
    /// `installsStandardGestureForInteractiveMovement` but neither the layout
    /// nor `useLayoutToLayoutNavigationTransitions`, and OpenUIKit has no
    /// archive reader to consult for the two it does carry.
    ///
    /// From a storyboard (`UINibCoder`) the controller state is decoded like
    /// any controller's (`nibName` is the scene's view nib), so `loadView`
    /// finds the archived collection view. Before, the coder was dropped and
    /// a storyboard collection controller (NetNewsWire's feed list) built a
    /// blank programmatic collection with none of its prototype cells.
    public required init?(coder: NSCoder) {
        initialLayout = nil
        super.init(coder: coder)
    }

    open var clearsSelectionOnViewWillAppear = true
    /// Stored preference. UIKit installs a private
    /// `_UICollectionViewLegacyReorderingGestureRecognizer` on the collection
    /// only once it is in a window AND the data source implements
    /// `collectionView(_:moveItemAt:to:)` AND this is true (gesture.window.*
    /// rows); detached controllers never carry it. The portable host has no
    /// interactive movement, so the value is stored and never installs a
    /// recognizer.
    open var installsStandardGestureForInteractiveMovement = true
    /// Stored preference; the portable navigation controller does not run
    /// layout-to-layout transitions. It still gates selection clearing, as
    /// on the oracle.
    open var useLayoutToLayoutNavigationTransitions = false

    // vc.replacement/setLayout: this remains the INITIAL layout even after
    // assigning a different collection view or changing its layout.
    // lazy.afterLayoutGetter: reading it does not load the view.
    open var collectionViewLayout: UICollectionViewLayout { initialLayout ?? fallbackLayout }

    open var collectionView: UICollectionView! {
        get {
            loadViewIfNeeded()
            return _collectionView
        }
        set {
            // collection-lifecycle.json nil.fresh.afterSet: assigning nil
            // while unloaded leaves it unloaded; loaded nil removes the view
            // and stays nil on subsequent reads (nil.loaded.afterGet).
            if newValue == nil && !isViewLoaded { return }
            // vc.setBeforeLoad: assigning a collection loads the wrapper.
            loadViewIfNeeded()
            guard _collectionView !== newValue else { return }
            _collectionView?.dataSource = nil
            _collectionView?.delegate = nil
            _collectionView?.removeFromSuperview()
            _collectionView = newValue
            if let newValue { install(newValue) }
        }
    }

    /// viewFirst / viewDidLoad rows: the wrapper and the collection are
    /// created together, so `viewDidLoad` already sees a non-nil
    /// `collectionView` whose superview is `view`. loadView.plain /
    /// .collection / .subview: a subclass that overrides `loadView` gets NO
    /// collection view from the controller, even when the view it installs
    /// is itself a `UICollectionView` (that view keeps autoresizing 0 and is
    /// neither wired as data source nor adopted as `collectionView`).
    open override func loadView() {
        // A storyboard collection view controller's view is its view nib.
        // Its root view is the archived UICollectionView itself (UIKit's
        // collectionViewController scene; NetNewsWire's feed list), which
        // becomes `collectionView`. Data source and delegate come from the
        // storyboard's outlet connections, as archived.
        if _loadStoryboardView() {
            if let collection = view as? UICollectionView { _collectionView = collection }
            return
        }
        // vc.loaded/window: wrapper and collection both [0,0,393,852] on
        // the measured phone; use the host screen bounds, not a phone constant.
        let wrapper = UICollectionViewControllerWrapperView(frame: UIScreen.main.bounds)
        // viewFirst.viewAutoresize 18, wrapperBackground nil, translates true.
        wrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.collectionController = self
        view = wrapper
        let collection = UICollectionView(frame: wrapper.bounds, collectionViewLayout: collectionViewLayout)
        _collectionView = collection
        install(collection)
    }

    private func install(_ collection: UICollectionView) {
        collection.frame = view.bounds
        // vc.loaded/replacement: autoresizing raw 18 = flexible width+height.
        // bare.background: the collection's systemBackground comes from
        // UICollectionView itself, so nothing is set here.
        collection.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collection.dataSource = self
        collection.delegate = self
        view.addSubview(collection)
    }

    // Called by the existing begin/endAppearanceTransition driver, outside
    // the overridable callbacks. Lifecycle oracle, iPhone16/iOS26.1: selected
    // [0,0] survives super.viewWillAppear; nonanimated entry to viewIsAppearing
    // is empty, animated entry to viewDidAppear is empty. This also occurs on
    // first window/navigation appearance. Direct viewWillAppear is unchanged.
    func _clearSelectionForAppearance() {
        guard OpenUIKitRuntime.systemFontCut == .iOS,
              clearsSelectionOnViewWillAppear,
              !useLayoutToLayoutNavigationTransitions else { return }
        for path in _collectionView?.indexPathsForSelectedItems ?? [] {
            _collectionView?.deselectItem(at: path, animated: false)
        }
    }

    // UIKit has no optional numberOfSections implementation (the oracle's
    // respondsSections is false). Swift protocol defaults supply the same
    // collection-view fallback of one section while remaining overridable.
    open func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    /// MEASURED Tools/oracle2/cvcdatasourceprobe, iPhone 16 / iOS 26.1:
    /// UIKit's controller answers this itself with 0 (responds true, direct
    /// call 0; one section, no cells). A storyboard collection controller is
    /// its collection's data source until the app installs its own, and the
    /// view's -setFrame: already prepares the layout (NetNewsWire replaces it
    /// with a diffable data source in viewDidLoad).
    open func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
        0
    }
    open func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("UICollectionViewController subclasses must implement collectionView(_:cellForItemAt:)")
    }
    open func collectionView(_ collectionView: UICollectionView,
                             viewForSupplementaryElementOfKind kind: String,
                             at indexPath: IndexPath) -> UICollectionReusableView {
        fatalError("UICollectionViewController subclasses must provide supplementary views requested by their layout")
    }

    // MARK: UICollectionViewDelegate / UIScrollViewDelegate (override in subclasses)
    //
    // Same pattern as UITableViewController: against Apple's ObjC class a
    // subclass writes `override func collectionView(_:didSelectItemAt:)`
    // (Xcode's template does; the ladder corpus has 11 didSelectItemAt and
    // 31 scrollViewDidScroll overrides in UICollectionViewController
    // subclasses), and `override` only resolves here if the class declares
    // the member. Bodies equal the protocol-extension defaults, so nothing
    // changes for the collection view's dispatch. Only members the portable
    // UICollectionView / UIScrollView actually call are declared; flow-layout
    // delegate members stay in the protocol because apps adopt
    // UICollectionViewDelegateFlowLayout in an extension without `override`.

    open func collectionView(_ collectionView: UICollectionView,
                             shouldSelectItemAt indexPath: IndexPath) -> Bool { true }
    open func collectionView(_ collectionView: UICollectionView,
                             didSelectItemAt indexPath: IndexPath) {}
    open func collectionView(_ collectionView: UICollectionView,
                             didDeselectItemAt indexPath: IndexPath) {}
    open func collectionView(_ collectionView: UICollectionView,
                             willDisplay cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {}
    open func collectionView(_ collectionView: UICollectionView,
                             didEndDisplaying cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {}

    // NetNewsWire's MainFeedCollectionViewController / MainTimelineDataSource
    // override these. They are declared with UIKit's not-implemented answers
    // (no primary action, no legacy edit menu, no context menu, not movable).
    // OPEN: the portable collection view does not yet route taps to the
    // primary action, long presses to the context menu, or drags to moves;
    // UIKit's input-driven semantics for those were not measured here.
    open func collectionView(_ collectionView: UICollectionView,
                             canPerformPrimaryActionForItemAt indexPath: IndexPath) -> Bool { false }
    open func collectionView(_ collectionView: UICollectionView,
                             performPrimaryActionForItemAt indexPath: IndexPath) {}
    open func collectionView(_ collectionView: UICollectionView,
                             shouldShowMenuForItemAt indexPath: IndexPath) -> Bool { false }
    open func collectionView(_ collectionView: UICollectionView,
                             canPerformAction action: Selector,
                             forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool { false }
    open func collectionView(_ collectionView: UICollectionView,
                             performAction action: Selector,
                             forItemAt indexPath: IndexPath, withSender sender: Any?) {}
    open func collectionView(_ collectionView: UICollectionView,
                             contextMenuConfigurationForItemAt indexPath: IndexPath,
                             point: CGPoint) -> UIContextMenuConfiguration? { nil }
    open func collectionView(_ collectionView: UICollectionView,
                             canMoveItemAt indexPath: IndexPath) -> Bool { false }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                        withVelocity velocity: CGPoint,
                                        targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {}
    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
    open func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {}
    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { true }
    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {}
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? { nil }
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {}
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {}
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?,
                                      atScale scale: CGFloat) {}
}
