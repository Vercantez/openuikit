// Measured iPhone 16 / iOS 26.1: Tools/oracle2/collectionblockingprobe,
// collection.json vc.*. Programmatic controllers only; nib decoding and
// interactive layout-to-layout transitions remain outside this implementation.

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
    private let initialLayout: UICollectionViewLayout

    // vc.init: false isViewLoaded; clear/install true, transitions false.
    public init(collectionViewLayout layout: UICollectionViewLayout) {
        initialLayout = layout
        super.init()
    }

    open var clearsSelectionOnViewWillAppear = true
    open var useLayoutToLayoutNavigationTransitions = false
    /// Stored preference. The portable host does not synthesize the system
    /// reordering gesture; callers can drive the existing drag/drop API.
    open var installsStandardGestureForInteractiveMovement = true

    // vc.replacement/setLayout: this remains the INITIAL layout even after
    // assigning a different collection view or changing its layout.
    open var collectionViewLayout: UICollectionViewLayout { initialLayout }

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

    open override func loadView() {
        // vc.loaded/window: wrapper and collection both [0,0,393,852] on
        // the measured phone; use the host screen bounds, not a phone constant.
        let wrapper = UICollectionViewControllerWrapperView(frame: UIScreen.main.bounds)
        wrapper.collectionController = self
        view = wrapper
        let collection = UICollectionView(frame: wrapper.bounds, collectionViewLayout: initialLayout)
        _collectionView = collection
        install(collection)
    }

    private func install(_ collection: UICollectionView) {
        collection.frame = view.bounds
        // vc.loaded/replacement: autoresizing raw 18 = flexible width+height.
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
    open func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
        fatalError("UICollectionViewController subclasses must implement collectionView(_:numberOfItemsInSection:)")
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
}
