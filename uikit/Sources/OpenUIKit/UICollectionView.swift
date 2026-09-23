// `@objc` members (OPENUIKIT_OBJC_SUBCLASSING) need Foundation in scope.
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
#endif
// UICollectionView. Owner: collection module (M13, docs/APP_COMPAT.md
// cluster #1 — 498 uses across 23 types, all four corpus apps).
//
// A UIScrollView subclass that tiles whatever its LAYOUT describes: on every
// contentOffset change it asks `layoutAttributesForElements(in:)` for the
// visible rect and instantiates only those elements, recycling the ones that
// left through the shared ReuseRegistry (UIReuse.swift — the same component
// UITableView drives). A 10k-item grid therefore holds ~one screenful of
// cells, which CollectionViewTests asserts.
//
// Nothing in this file is invented geometry: all of it comes from the layout
// object. The measured part of the cluster is UICollectionViewFlowLayout,
// whose rules were probed against real UIKit (scripts/flow_probe.sh) and are
// exercised by the collection_* fixture scenes.

// The `item`/`section` spelling of an index path moved to
// FoundationTypes.swift with M15, alongside `row`/`section` — both are now
// extensions on Foundation's IndexPath rather than on a type of our own.

// MARK: - Data source / delegate protocols

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
// MARK: sugar-unify scoped imports (docs/agent_reports/sugar-unify.md):
// Foundation / ObjectiveC names OpenUIKit re-exports rather than re-declares.
// Each is @_exported here too: a plain scoped import that precedes the
// re-export in file order hides the name from clients (swiftc).
#if canImport(Foundation)
@_exported import class Foundation.NSCoder
@_exported import struct Foundation.IndexPath
#endif
#if canImport(ObjectiveC)
@_exported import struct ObjectiveC.Selector
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
// `@objc` protocols (OPENUIKIT_OBJC_SUBCLASSING) need Foundation's IndexPath
// bridging in scope; scoped imports keep its other names out of this file.
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
import protocol ObjectiveC.NSObjectProtocol
#endif

// Apple toolchain (OPENUIKIT_OBJC_SUBCLASSING): UIKit's own shape, an `@objc`
// protocol with UIKit's runtime name, NSObjectProtocol refinement, SDK
// selectors and SDK required/optional split, so Swift code writes
// `delegate?.method?(…)` and an Objective-C class adopts the same protocol
// (docs/agent_reports/objc-protocols.md). OpenUIKit's own call sites go
// through UIKitProtocolDispatch.swift. Linux ELF and the Foundation-hidden
// guest have no `@objc`: the Swift protocol below with default
// implementations, unchanged.
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UICollectionViewDataSource) @preconcurrency @MainActor
public protocol UICollectionViewDataSource: NSObjectProtocol {
    @objc(collectionView:numberOfItemsInSection:)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    @objc(collectionView:cellForItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    @objc(numberOfSectionsInCollectionView:)
    optional func numberOfSections(in collectionView: UICollectionView) -> Int
    @objc(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView
    @objc(collectionView:canMoveItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
}

@objc(UICollectionViewDelegate) @preconcurrency @MainActor
public protocol UICollectionViewDelegate: UIScrollViewDelegate {
    @objc(collectionView:shouldSelectItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    @objc(collectionView:didSelectItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    @objc(collectionView:didDeselectItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    @objc(collectionView:willDisplayCell:forItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath)
    @objc(collectionView:didEndDisplayingCell:forItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath)
    // NetNewsWire's MainFeedCollectionViewController / MainTimelineDataSource
    // implement these (netnewswire-first-screen); SDK selectors.
    @objc(collectionView:canPerformPrimaryActionForItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 canPerformPrimaryActionForItemAt indexPath: IndexPath) -> Bool
    @objc(collectionView:performPrimaryActionForItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 performPrimaryActionForItemAt indexPath: IndexPath)
    @objc(collectionView:shouldShowMenuForItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 shouldShowMenuForItemAt indexPath: IndexPath) -> Bool
    @objc(collectionView:canPerformAction:forItemAtIndexPath:withSender:)
    optional func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector,
                                 forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    @objc(collectionView:performAction:forItemAtIndexPath:withSender:)
    optional func collectionView(_ collectionView: UICollectionView, performAction action: Selector,
                                 forItemAt indexPath: IndexPath, withSender sender: Any?)
    @objc(collectionView:contextMenuConfigurationForItemAtIndexPath:point:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration?
    // SDK members declared for source compatibility (RxCocoa 4's
    // UITableView+Rx / UICollectionView+Rx name them); OpenUIKit does not
    // send them yet (unmeasured: accessory buttons, end-of-display and
    // supplementary-view display tracking, collection highlight).
    @objc(collectionView:didHighlightItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    @objc(collectionView:didUnhighlightItemAtIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    @objc(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 willDisplaySupplementaryView view: UICollectionReusableView,
                                 forElementKind elementKind: String, at indexPath: IndexPath)
    @objc(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)
    optional func collectionView(_ collectionView: UICollectionView,
                                 didEndDisplayingSupplementaryView view: UICollectionReusableView,
                                 forElementOfKind elementKind: String, at indexPath: IndexPath)
}
#else
@preconcurrency @MainActor
public protocol UICollectionViewDataSource: AnyObject {
    func numberOfSections(in collectionView: UICollectionView) -> Int
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool
}

public extension UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    /// UIKit raises if a layout asks for a supplementary view the data
    /// source will not build; the portable answer is an empty view, so a
    /// scene that sets a header size without a data source still renders.
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool { false }
}

@preconcurrency @MainActor
public protocol UICollectionViewDelegate: UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView,
                        didDeselectItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView,
                        canPerformPrimaryActionForItemAt indexPath: IndexPath) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                        performPrimaryActionForItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView,
                        shouldShowMenuForItemAt indexPath: IndexPath) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                        forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    func collectionView(_ collectionView: UICollectionView,
                        performAction action: Selector,
                        forItemAt indexPath: IndexPath, withSender sender: Any?)
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration?
}

public extension UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool { true }
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView,
                        didDeselectItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {}
    // NetNewsWire's MainFeedCollectionViewController / MainTimelineDataSource
    // override these. They are declared with UIKit's not-implemented answers
    // (no primary action, no legacy edit menu, no context menu, not movable).
    // OPEN: the portable collection view does not yet route taps to the
    // primary action, long presses to the context menu, or drags to moves;
    // UIKit's input-driven semantics for those were not measured here.
    func collectionView(_ collectionView: UICollectionView,
                        canPerformPrimaryActionForItemAt indexPath: IndexPath) -> Bool { false }
    func collectionView(_ collectionView: UICollectionView,
                        performPrimaryActionForItemAt indexPath: IndexPath) {}
    func collectionView(_ collectionView: UICollectionView,
                        shouldShowMenuForItemAt indexPath: IndexPath) -> Bool { false }
    func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                        forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool { false }
    func collectionView(_ collectionView: UICollectionView,
                        performAction action: Selector,
                        forItemAt indexPath: IndexPath, withSender sender: Any?) {}
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? { nil }
}
#endif

/// Per-section overrides for the flow layout.
///
/// Real UIKit probes each method with `respondsToSelector` and falls back to
/// the layout's own property. There is no ObjC runtime here, so the DEFAULT
/// implementations do the falling back themselves — they return the layout's
/// property, which is exactly the value UIKit would have used. A conforming
/// type therefore only implements what it wants to change.
@preconcurrency @MainActor
public protocol UICollectionViewDelegateFlowLayout: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize
}

public extension UICollectionViewDelegateFlowLayout {
    private func flow(_ l: UICollectionViewLayout) -> UICollectionViewFlowLayout? {
        l as? UICollectionViewFlowLayout
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        flow(collectionViewLayout)?.itemSize ?? .zero
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        flow(collectionViewLayout)?.sectionInset ?? .zero
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        flow(collectionViewLayout)?.minimumLineSpacing ?? 0
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        flow(collectionViewLayout)?.minimumInteritemSpacing ?? 0
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        flow(collectionViewLayout)?.headerReferenceSize ?? .zero
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        flow(collectionViewLayout)?.footerReferenceSize ?? .zero
    }
}

// MARK: - UICollectionView

@preconcurrency @MainActor
open class UICollectionView: UIScrollView {
    public static let elementKindSectionHeader = "UICollectionElementKindSectionHeader"
    public static let elementKindSectionFooter = "UICollectionElementKindSectionFooter"

    /// Tiling key: a cell (kind nil) or a supplementary view of some kind.
    struct ElementKey: Hashable {
        let kind: String?
        let indexPath: IndexPath
    }

    /// Where `scrollToItem(at:at:animated:)` should put the item.
    public struct ScrollPosition: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let none = ScrollPosition([])
        public static let top = ScrollPosition(rawValue: 1 << 0)
        public static let centeredVertically = ScrollPosition(rawValue: 1 << 1)
        public static let bottom = ScrollPosition(rawValue: 1 << 2)
        public static let left = ScrollPosition(rawValue: 1 << 3)
        public static let centeredHorizontally = ScrollPosition(rawValue: 1 << 4)
        public static let right = ScrollPosition(rawValue: 1 << 5)
    }

    // MARK: Configuration

    /// NetNewsWire MainFeedCollectionViewController.swift:312 replaces the
    /// layout without animation: the same as assigning `collectionViewLayout`.
    /// The animated transition (and the completion variant) is OPEN.
    public func setCollectionViewLayout(_ layout: UICollectionViewLayout, animated: Bool) {
        _ = animated
        collectionViewLayout = layout
    }

    public var collectionViewLayout: UICollectionViewLayout {
        didSet {
            guard collectionViewLayout !== oldValue else { return }
            oldValue.collectionView = nil
            collectionViewLayout.collectionView = self
            collectionViewLayout.invalidateLayout()
            reloadData()
        }
    }

    public weak var dataSource: UICollectionViewDataSource? {
        didSet { if dataSource !== oldValue { reloadData() } }
    }

    public weak var dragDelegate: UICollectionViewDragDelegate? {
        didSet { _installDragLift() }
    }
    public weak var dropDelegate: UICollectionViewDropDelegate?
    public var dragInteractionEnabled = true
    public internal(set) var hasActiveDrag = false
    public internal(set) var hasActiveDrop = false
    var _activeDrag = false {
        didSet { hasActiveDrag = _activeDrag }
    }
    var _activeDrop = false {
        didSet { hasActiveDrop = _activeDrop }
    }
    var _dragLift: UILongPressGestureRecognizer?

    // Like UIKit, the collection view's delegate IS the inherited scroll-view
    // `delegate` (UICollectionViewDelegate refines UIScrollViewDelegate); the
    // collection conformance is discovered dynamically.
    var collectionDelegate: UICollectionViewDelegate? { delegate as? UICollectionViewDelegate }

    public var allowsSelection = true
    public var allowsMultipleSelection = false

    /// Drawn behind every cell (UIKit's `backgroundView`).
    public var backgroundView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let v = backgroundView {
                v.isUserInteractionEnabled = false
                insertSubview(v, at: 0)
                setNeedsLayout()
            }
        }
    }

    // MARK: Init

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(initWithFrame:collectionViewLayout:)
#endif
    public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        collectionViewLayout = layout
        super.init(frame: frame)
        configureCollectionView(with: layout)
    }

    /// Compatibility extension: UIKit classifies this as convenience too,
    /// but raises at runtime without an explicit layout. OpenUIKit supplies a
    /// flow layout for its long-standing zero/frame-only source surface.
    public override convenience init(frame: CGRect) {
        self.init(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
    }

    public convenience init() {
        self.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    public required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        collectionViewLayout = layout
        super.init(coder: coder)
        configureCollectionView(with: layout)
    }

    private func configureCollectionView(with layout: UICollectionViewLayout) {
        _configured = true
        layout.collectionView = self
        backgroundColor = .systemBackground
        alwaysBounceVertical = false
    }

    // MARK: Counts (cached; the layout asks for them once per prepare)

    private var sectionItemCounts: [Int] = []
    var countsDirty = true

    private func ensureCounts() {
        guard countsDirty else { return }
        countsDirty = false
        sectionItemCounts.removeAll()
        guard let ds = dataSource else { return }
        let n = ds._numberOfSections(self)
        sectionItemCounts.reserveCapacity(n)
        for s in 0..<n {
            sectionItemCounts.append(ds.collectionView(self, numberOfItemsInSection: s))
        }
    }

    public var numberOfSections: Int {
        ensureCounts()
        return sectionItemCounts.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        ensureCounts()
        guard section >= 0, section < sectionItemCounts.count else { return 0 }
        return sectionItemCounts[section]
    }

    // MARK: Reuse (shared machinery — UIReuse.swift)

    private let cellRegistry = ReuseRegistry<UICollectionReusableView>()
    /// One registry per supplementary KIND: a header and a footer may share
    /// a reuse identifier, and their pools must not cross.
    private var supplementaryRegistries: [String: ReuseRegistry<UICollectionReusableView>] = [:]

    private func supplementaryRegistry(_ kind: String) -> ReuseRegistry<UICollectionReusableView> {
        if let r = supplementaryRegistries[kind] { return r }
        let r = ReuseRegistry<UICollectionReusableView>()
        supplementaryRegistries[kind] = r
        return r
    }

    public func register(_ cellClass: UICollectionViewCell.Type,
                         forCellWithReuseIdentifier identifier: String) {
        cellRegistry.register(identifier: identifier) { id in
            let constructor = unsafeBitCast(
                cellClass,
                to: _UICollectionViewCellDynamicConstructor.Type.self)
            let cell = constructor.init(frame: .zero)
            cell.reuseIdentifier = id
            return cell
        }
    }

    public func register(_ viewClass: UICollectionReusableView.Type,
                         forSupplementaryViewOfKind elementKind: String,
                         withReuseIdentifier identifier: String) {
        supplementaryRegistry(elementKind).register(identifier: identifier) { id in
            let constructor = unsafeBitCast(
                viewClass,
                to: _UICollectionReusableViewDynamicConstructor.Type.self)
            let view = constructor.init(frame: .zero)
            view.reuseIdentifier = id
            view.elementKind = elementKind
            return view
        }
    }

    public func dequeueReusableCell(withReuseIdentifier identifier: String,
                                    for indexPath: IndexPath) -> UICollectionViewCell {
        guard let view = cellRegistry.dequeue(identifier) as? UICollectionViewCell else {
            fatalError("dequeueReusableCell(withReuseIdentifier:for:) requires a class registered for '\(identifier)'")
        }
        return view
    }

    public func dequeueReusableSupplementaryView(ofKind elementKind: String,
                                                 withReuseIdentifier identifier: String,
                                                 for indexPath: IndexPath)
        -> UICollectionReusableView {
        guard let view = supplementaryRegistry(elementKind).dequeue(identifier) else {
            fatalError("dequeueReusableSupplementaryView(ofKind:withReuseIdentifier:for:) requires a class registered for '\(identifier)' of kind '\(elementKind)'")
        }
        return view
    }

    func recycle(_ view: UICollectionReusableView) {
        if let cell = view as? UICollectionViewCell {
            cell.collectionView = nil
            cellRegistry.recycle(view)
        } else if let kind = view.elementKind {
            supplementaryRegistry(kind).recycle(view)
        }
    }

    // MARK: Visible views

    var visibleViews = VisibleViewMap<ElementKey, UICollectionReusableView>()

    public var visibleCells: [UICollectionViewCell] {
        visibleViews.views
            .filter { $0.key.kind == nil }
            .sorted { $0.key.indexPath < $1.key.indexPath }
            .compactMap { $0.value as? UICollectionViewCell }
    }

    public var indexPathsForVisibleItems: [IndexPath] {
        visibleViews.views.keys.filter { $0.kind == nil }.map(\.indexPath).sorted()
    }

    public func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        visibleViews[ElementKey(kind: nil, indexPath: indexPath)] as? UICollectionViewCell
    }

    public func indexPath(for cell: UICollectionViewCell) -> IndexPath? {
        visibleViews.first { $0.kind == nil && $1 === cell }?.key.indexPath
    }

    public func supplementaryView(forElementKind elementKind: String,
                                  at indexPath: IndexPath) -> UICollectionReusableView? {
        // A per-item supplementary (compositional badge) lives at its own
        // index path; a section header at item 0 of the section.
        visibleViews[ElementKey(kind: elementKind, indexPath: indexPath)]
            ?? visibleViews[ElementKey(kind: elementKind,
                                       indexPath: IndexPath(item: 0, section: indexPath.section))]
    }

    public func visibleSupplementaryViews(ofKind elementKind: String) -> [UICollectionReusableView] {
        visibleViews.views
            .filter { $0.key.kind == elementKind }
            .sorted { $0.key.indexPath < $1.key.indexPath }
            .map(\.value)
    }

    // MARK: Geometry queries (forwarded to the layout)

    public func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        flushReloadInvalidation()
        ensureCounts()
        if collectionViewLayout.isPrepared,
           let cached = _queriedAttributes[ElementKey(kind: nil, indexPath: indexPath)] {
            return cached
        }
        return collectionViewLayout.layoutAttributesForItem(at: indexPath)
    }

    public func layoutAttributesForSupplementaryElement(ofKind elementKind: String,
                                                        at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        flushReloadInvalidation()
        ensureCounts()
        return collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: elementKind,
                                                                         at: indexPath)
    }

    public func indexPathForItem(at point: CGPoint) -> IndexPath? {
        flushReloadInvalidation()
        ensureCounts()
        collectionViewLayout.prepareIfNeeded()
        let probe = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        let hits = collectionViewLayout.layoutAttributesForElements(in: probe) ?? []
        for a in hits where a.representedElementCategory == .cell && a.frame.contains(point) {
            return a.indexPath
        }
        return nil
    }

    // MARK: Reload / updates

    public func reloadData() {
        visibleViews.removeAll { _, view in
            view.removeFromSuperview()
            recycle(view)
        }
        selectedPaths.removeAll()
        countsDirty = true
        // MEASURED flowlayoutprobe section 5 (iPhone 16 / iOS 26.1): setting
        // the data source (a reload) sends the layout nothing; its
        // -invalidateLayout arrives at the start of the next layout pass,
        // immediately before -prepareLayout.
        reloadInvalidationPending = true
        setNeedsLayout()
    }

    /// A `reloadData()` whose layout invalidation the next layout pass (or
    /// geometry query) still owes.
    private var reloadInvalidationPending = false

    private func flushReloadInvalidation() {
        guard reloadInvalidationPending else { return }
        reloadInvalidationPending = false
        collectionViewLayout.invalidateLayout()
    }

    /// PORTABLE FALLBACK, documented divergence: UIKit animates inserts,
    /// deletes and moves inside the block. Here the block runs, the data is
    /// reloaded in one step and `completion(true)` fires immediately — the
    /// end state is correct, the transition is not animated. (UITableView's
    /// `performUpdates(withDuration:identity:updates:)` is the animated
    /// portable spelling; the collection equivalent is future work, see
    /// docs/KNOWN_GAPS.md.)
    public func performBatchUpdates(_ updates: (() -> Void)?,
                                    completion: ((Bool) -> Void)? = nil) {
        updates?()
        reloadData()
        layoutIfNeeded()
        completion?(true)
    }

    public func reloadSections(_ sections: [Int]) { reloadData() }
    public func reloadItems(at indexPaths: [IndexPath]) { reloadData() }
    public func insertItems(at indexPaths: [IndexPath]) { reloadData() }
    public func deleteItems(at indexPaths: [IndexPath]) { reloadData() }
    public func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) { reloadData() }

    // collectionblockingprobe base.populated*, iPhone 16 / iOS 26.1:
    // offset (20,30)+(3,4) becomes (23,34); size (500,1200)+(10,20)
    // becomes (510,1220) immediately, then returns to the layout's size on
    // the next pass. With content height 600 < viewport 852, y clamps to 0.
    func _applyInvalidationAdjustments(_ context: UICollectionViewLayoutInvalidationContext) {
        let previousTiling = inTile
        inTile = true
        defer { inTile = previousTiling }
        if context.contentSizeAdjustment != .zero {
            contentSize = CGSize(width: contentSize.width + context.contentSizeAdjustment.width,
                                 height: contentSize.height + context.contentSizeAdjustment.height)
        }
        if context.contentOffsetAdjustment != .zero {
            let x = contentOffset.x + context.contentOffsetAdjustment.x
            let y = contentOffset.y + context.contentOffsetAdjustment.y
            contentOffset = CGPoint(x: max(minContentOffset.x, min(maxContentOffset.x, x)),
                                    y: max(minContentOffset.y, min(maxContentOffset.y, y)))
        }
    }

    /// The layout told us its cache is stale.
    func _layoutInvalidated() {
        _queriedAttributes.removeAll()
        setNeedsLayout()
    }

    // MARK: Tiling

    private var inTile = false

    /// One element query: the grid-aligned rect, then the content size
    /// UIKit reads right after it.
    private func _queryElements(_ visibleRect: CGRect) -> [UICollectionViewLayoutAttributes] {
        let queried = collectionViewLayout.layoutAttributesForElements(in: _tilingQueryRect(visibleRect)) ?? []
        let size = collectionViewLayout.collectionViewContentSize
        if size != contentSize { contentSize = size }
        _queriedAttributes.removeAll(keepingCapacity: true)
        for a in queried { _queriedAttributes[a.elementKey] = a }
        return queried
    }

    /// Asks the layout about the bounds clamped into the scrollable range
    /// when the offset lies outside it; true when that invalidated.
    @discardableResult
    private func _revalidateOffsetBounds() -> Bool {
        let lo = minContentOffset, hi = maxContentOffset
        // `+ 0` turns the -0 of a negated zero inset into 0.
        let clamped = CGPoint(x: max(lo.x, min(hi.x, contentOffset.x)) + 0,
                              y: max(lo.y, min(hi.y, contentOffset.y)) + 0)
        guard clamped != contentOffset else { return false }
        guard case .invalidate(let context) = boundsQuestion(for: CGRect(origin: clamped, size: bounds.size)) else {
            return false
        }
        invalidateForBoundsChange(context)
        return true
    }

    /// MEASURED flowlayoutprobe section 10: leaving the window with the
    /// offset outside the scrollable range asks the layout about the clamped
    /// bounds (and invalidates on YES), inside `-removeFromSuperview`.
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil, _configured, !inTile, dataSource != nil {
            _revalidateOffsetBounds()
        }
    }

    /// `prepare()` if the layout is stale and, when it ran, the content size
    /// it produced.
    private func _prepareLayoutAndContentSize() {
        guard collectionViewLayout.prepareIfNeeded() else { return }
        let size = collectionViewLayout.collectionViewContentSize
        if size != contentSize { contentSize = size }
    }

    /// The rect UIKit hands `layoutAttributesForElements(in:)`: the visible
    /// bounds widened to whole multiples of the bounds size on the grid
    /// anchored at the origin. MEASURED flowlayoutprobe (bounds height H,
    /// offset y): H 480 y 0 -> {0, 480}; y 100 -> {0, 960}; y -59 ->
    /// {-480, 960}; H 200 y 0 -> {0, 200} (x likewise with the width).
    final func _tilingQueryRect(_ visible: CGRect) -> CGRect {
        guard visible.width > 0, visible.height > 0 else { return visible }
        let x0 = (visible.minX / visible.width).rounded(.down) * visible.width
        let x1 = (visible.maxX / visible.width).rounded(.up) * visible.width
        let y0 = (visible.minY / visible.height).rounded(.down) * visible.height
        let y1 = (visible.maxY / visible.height).rounded(.up) * visible.height
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// Context produced by `invalidationContext(forBoundsChange:)` while the
    /// bounds were still the old value; consumed when the bounds have moved.
    private var pendingBoundsContext: UICollectionViewLayoutInvalidationContext?
    /// `_willSetContentOffset` already asked for the bounds set that
    /// follows (`true`: and invalidated; `false`: the layout declined). That
    /// set asks nothing and invalidates nothing more, but an invalidated one
    /// still counts as bounds-invalidated (tiling waits for the pass).
    private var preMoveChainResult: Bool?
    /// A bounds-driven invalidation the layout has not yet consumed with
    /// `prepare()`. MEASURED offset.swift base/flow.drag touch2/touch3: a
    /// further bounds change while one is pending asks nothing at all — only
    /// scrollViewDidScroll fires — and the question returns once the layout
    /// pass prepared.
    private var boundsInvalidationPending = false
    /// Whether the bounds set in flight invalidated the layout.
    private var invalidatedForCurrentBoundsChange = false
    /// False while `super.init(frame:)` sets the first frame: MEASURED
    /// flowlayoutprobe section 5, `-initWithFrame:collectionViewLayout:`
    /// sends the layout nothing.
    private var _configured = false
    /// The last element query's attributes, by element: what
    /// `layoutAttributesForItem(at:)` answers from (MEASURED flowlayoutprobe
    /// section 5: `-[UICollectionView layoutAttributesForItemAtIndexPath:]`
    /// for a laid-out item does not reach the layout's override). Dropped
    /// on every invalidation.
    private var _queriedAttributes: [ElementKey: UICollectionViewLayoutAttributes] = [:]

    // MEASURED signalrowsprobe invalidate.* (2026-09-09) and
    // signalrowsprobe/offset.swift (2026-09-10), iPhone 16 / iOS 26.1: EVERY
    // bounds change (frame resize, bounds origin, contentOffset, a drag
    // step, a deceleration frame) asks shouldInvalidateLayout(forBoundsChange:
    // new) while `bounds` is still OLD; a true answer fetches
    // invalidationContext(forBoundsChange:) (still old bounds); then, with
    // the new bounds in place, invalidateLayout() runs and
    // invalidateLayout(with:) receives that SAME context object (flags
    // false, adjustments zero; flow: attributes true only for a size or
    // cross-axis change, metrics false); scrollViewDidScroll comes AFTER
    // invalidateLayout(with:). setContentOffset / scrollRectToVisible /
    // scrollToItem (animated or not) run the whole chain BEFORE the move —
    // see `_willSetContentOffset`. A false answer stops after the question.
    // prepare() follows synchronously for a size change and on the next
    // layout pass for an origin change (with layoutAttributesForElements
    // and the cell dequeues). A frame set to the same rect asks nothing.
    open override var bounds: CGRect {
        willSet {
            invalidatedForCurrentBoundsChange = false
            pendingBoundsContext = nil
            guard newValue != bounds, !inTile, _configured else { preMoveChainResult = nil; return }
            if let invalidated = preMoveChainResult {
                preMoveChainResult = nil
                invalidatedForCurrentBoundsChange = invalidated
                return
            }
            switch boundsQuestion(for: newValue) {
            case .stillPending: invalidatedForCurrentBoundsChange = true
            case .declined: break
            case .invalidate(let context): pendingBoundsContext = context
            }
        }
        didSet {
            // An origin change already ran `_boundsOriginDidChange` inside
            // the superclass setter; a size-only change is consumed here.
            consumePendingBoundsContext()
            if invalidatedForCurrentBoundsChange, bounds.size != oldValue.size,
               dataSource != nil, bounds.width > 0, bounds.height > 0 {
                // MEASURED flowlayoutprobe section 6: inside -setFrame:,
                // -prepareLayout then -collectionViewContentSize; the
                // element query waits for the layout pass.
                _prepareLayoutAndContentSize()
            }
        }
    }

    private enum BoundsQuestion {
        /// An earlier bounds-driven invalidation is still unconsumed: no
        /// question, and tiling keeps waiting for the layout pass.
        case stillPending
        /// The layout declined.
        case declined
        case invalidate(UICollectionViewLayoutInvalidationContext)
    }

    /// The question half of the chain, asked on the OLD bounds.
    private func boundsQuestion(for newBounds: CGRect) -> BoundsQuestion {
        if boundsInvalidationPending {
            // Only a layout pass that will actually prepare (data source
            // set, non-empty bounds — `retile`'s guard) can consume the
            // pending invalidation; otherwise keep asking as before.
            if collectionViewLayout.isPrepared || dataSource == nil
                || bounds.width <= 0 || bounds.height <= 0 {
                boundsInvalidationPending = false
            } else {
                return .stillPending
            }
        }
        guard collectionViewLayout.shouldInvalidateLayout(forBoundsChange: newBounds) else { return .declined }
        return .invalidate(collectionViewLayout.invalidationContext(forBoundsChange: newBounds))
    }

    /// The invalidation half: `invalidateLayout()` → `invalidateLayout(with:)`
    /// with the context the question produced.
    private func invalidateForBoundsChange(_ context: UICollectionViewLayoutInvalidationContext) {
        let layout = collectionViewLayout
        layout._pendingBoundsContext = context
        layout.invalidateLayout()
        layout._pendingBoundsContext = nil
        boundsInvalidationPending = true
    }

    private func consumePendingBoundsContext() {
        guard let context = pendingBoundsContext else { return }
        pendingBoundsContext = nil
        invalidatedForCurrentBoundsChange = true
        invalidateForBoundsChange(context)
    }

    override func _willSetContentOffset(_ offset: CGPoint, animated: Bool) {
        super._willSetContentOffset(offset, animated: animated)
        let newBounds = CGRect(origin: offset, size: bounds.size)
        preMoveChainResult = nil
        guard newBounds != bounds, !inTile else { return }
        switch boundsQuestion(for: newBounds) {
        case .stillPending:
            preMoveChainResult = true
        case .declined:
            preMoveChainResult = false
        case .invalidate(let context):
            invalidateForBoundsChange(context)
            preMoveChainResult = true
        }
    }

    override func _boundsOriginDidChange(from oldValue: CGRect) {
        consumePendingBoundsContext()
        super._boundsOriginDidChange(from: oldValue)
        // Scrolling IS a bounds-origin change: re-tile immediately so drags
        // and deceleration steps bring elements in without waiting for a
        // layout pass (same rule as UITableView; UIKit tiles on the pass,
        // the same cells a turn later). After a bounds-driven invalidation
        // the measured prepare() waits for the layout pass the invalidation
        // already queued, so tiling waits with it.
        if !inTile, !invalidatedForCurrentBoundsChange {
            retile()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        retile()
    }

    func retile() {
        guard !inTile else { return }
        inTile = true
        defer { inTile = false }
        guard dataSource != nil, bounds.width > 0, bounds.height > 0 else { return }

        // MEASURED flowlayoutprobe sections 5-9 (iPhone 16 / iOS 26.1), the
        // order UIKit sends a layout (an Objective-C subclass included):
        // [-invalidateLayout owed by a reload], -prepareLayout (the data
        // source's counts are fetched lazily, inside it, when the layout
        // first asks), -collectionViewContentSize, then
        // -layoutAttributesForElementsInRect: and -collectionViewContentSize
        // again; without a pending invalidation only the last two.
        flushReloadInvalidation()
        let sizeBeforePass = contentSize
        _prepareLayoutAndContentSize()
        backgroundView?.frame = CGRect(origin: contentOffset, size: bounds.size)

        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        var queried = _queryElements(visibleRect)
        // MEASURED flowlayoutprobe section 8: when the pass changed the
        // content size and the offset now lies outside the scrollable range,
        // UIKit asks -shouldInvalidateLayoutForBoundsChange: with the CLAMPED
        // bounds; a YES invalidates, and the same pass prepares and queries
        // again. The offset itself does not move.
        if contentSize != sizeBeforePass,_revalidateOffsetBounds() {
            _prepareLayoutAndContentSize()
            queried = _queryElements(visibleRect)
        }
        // Views exist only for what intersects the visible bounds (section 7:
        // the query returned 6 elements, 3 cells were visible) and for items
        // the collection view knows of: an invalidation does not refetch the
        // counts, so an item the data source added since is not shown
        // (section 8: 7 attributes, count still 5, 3 cells).
        let attributes = queried.filter { a in
            guard a.frame.intersects(visibleRect) else { return false }
            guard a.representedElementCategory == .cell else { return true }
            return a.indexPath.item < numberOfItems(inSection: a.indexPath.section)
        }

        var needed = Set<ElementKey>()
        needed.reserveCapacity(attributes.count)
        for a in attributes where a.representedElementCategory != .decorationView {
            needed.insert(a.elementKey)
        }

        visibleViews.retire(keeping: needed) { key, view in
            view.removeFromSuperview()
            if key.kind == nil, let cell = view as? UICollectionViewCell {
                collectionDelegate?._didEndDisplaying(self, cell, key.indexPath)
            }
            recycle(view)
        }

        guard let ds = dataSource else { return }
        for a in attributes where a.representedElementCategory != .decorationView {
            let key = a.elementKey
            if let existing = visibleViews[key] {
                existing.frame = a.frame
                existing.apply(a)
                existing.setNeedsLayout()
                continue
            }
            let view: UICollectionReusableView
            if let kind = a.representedElementKind {
                let supp = ds._supplementary(self, kind, a.indexPath)
                supp.elementKind = kind
                view = supp
            } else {
                let cell = ds.collectionView(self, cellForItemAt: a.indexPath)
                cell.collectionView = self
                cell.isSelected = selectedPaths.contains(a.indexPath)
                view = cell
            }
            view.frame = a.frame
            visibleViews[key] = view
            addSubview(view)
            view.apply(a)
            view.setNeedsLayout()
            // MEASURED Tools/oracle2/cellconfigprobe (iOS 26.1): each cell is
            // configured as it is prepared -- cellForItemAt 0, update 0,
            // cellForItemAt 1, update 1 -- in the window, before sizing.
            if window != nil, let cell = view as? UICollectionViewCell {
                cell._updateConfigurationIfNeeded()
            }
            if let cell = view as? UICollectionViewCell {
                collectionDelegate?._willDisplay(self, cell, a.indexPath)
            }
        }

        // Z-order: supplementary views above cells (UIKit's default zIndex
        // ordering puts headers/footers on top), background behind, scroll
        // indicators above everything.
        for a in attributes where a.representedElementKind != nil {
            if let v = visibleViews[a.elementKey] { bringSubviewToFront(v) }
        }
        if let bg = backgroundView { sendSubviewToBack(bg) }
        _frontScrollEdgePockets()
        if let bar = verticalIndicator { bringSubviewToFront(bar) }
        if let bar = horizontalIndicator { bringSubviewToFront(bar) }

        // List self-sizing: MEASURED collection_list_plain Bravo 68.5 after
        // configure (estimated 52). preferredLayoutAttributesFitting is not
        // wired through UICollectionView yet, so we sample the configured
        // cell here and invalidate once the fitted height disagrees.
        if let layout = collectionViewLayout as? UICollectionViewCompositionalLayout,
           let listCfg = layout._storedListConfiguration {
            var changed = false
            for a in attributes where a.representedElementKind == nil {
                guard let cell = visibleViews[a.elementKey] as? UICollectionViewListCell else {
                    continue
                }
                var h = cell.preferredHeight(forWidth: a.frame.width)
                if a.indexPath.item == 0 {
                    h += UICollectionViewListCell.headerTopPadding(for: listCfg.appearance)
                }
                if layout._noteFittedListHeight(h, at: a.indexPath) {
                    changed = true
                }
            }
            if changed {
                collectionViewLayout.invalidateLayout()
                setNeedsLayout()
            }
        }
    }

    // MARK: Selection

    private var selectedPaths: Set<IndexPath> = []

    public var indexPathsForSelectedItems: [IndexPath]? {
        selectedPaths.isEmpty ? nil : selectedPaths.sorted()
    }

    /// Programmatic selection (UIKit semantics: no delegate callbacks).
    public func selectItem(at indexPath: IndexPath?, animated: Bool,
                           scrollPosition: ScrollPosition = .none) {
        guard let indexPath else {
            for p in selectedPaths { cellForItem(at: p)?.isSelected = false }
            selectedPaths.removeAll()
            return
        }
        if !allowsMultipleSelection {
            for p in selectedPaths where p != indexPath {
                cellForItem(at: p)?.isSelected = false
            }
            selectedPaths.removeAll()
        }
        selectedPaths.insert(indexPath)
        cellForItem(at: indexPath)?.isSelected = true
        if !scrollPosition.isEmpty {
            scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
        }
    }

    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
        guard selectedPaths.remove(indexPath) != nil else { return }
        cellForItem(at: indexPath)?.isSelected = false
    }

    /// A bound cell finished a tap.
    func commitItemTap(on cell: UICollectionViewCell) {
        guard allowsSelection, let path = indexPath(for: cell) else { return }
        guard collectionDelegate?._shouldSelect(self, path) ?? true else {
            return
        }
        if allowsMultipleSelection, selectedPaths.contains(path) {
            deselectItem(at: path, animated: false)
            collectionDelegate?._didDeselect(self, path)
            return
        }
        if !allowsMultipleSelection {
            for old in selectedPaths where old != path {
                cellForItem(at: old)?.isSelected = false
                selectedPaths.remove(old)
                collectionDelegate?._didDeselect(self, old)
            }
        }
        selectedPaths.insert(path)
        cell.isSelected = true
        collectionDelegate?._didSelect(self, path)
    }

    // MARK: Scrolling to an item

    public func scrollToItem(at indexPath: IndexPath, at position: ScrollPosition,
                             animated: Bool) {
        collectionViewLayout.prepareIfNeeded()
        if collectionViewLayout.handleScrollToItem(at: indexPath, at: position) {
            setNeedsLayout()
            layoutIfNeeded()
            return
        }
        guard let a = layoutAttributesForItem(at: indexPath) else { return }
        let rect = a.frame
        var target = contentOffset
        if position.contains(.top) {
            target.y = rect.minY
        } else if position.contains(.centeredVertically) {
            target.y = rect.midY - bounds.height / 2
        } else if position.contains(.bottom) {
            target.y = rect.maxY - bounds.height
        } else if rect.minY < contentOffset.y {
            target.y = rect.minY
        } else if rect.maxY > contentOffset.y + bounds.height {
            target.y = rect.maxY - bounds.height
        }
        if position.contains(.left) {
            target.x = rect.minX
        } else if position.contains(.centeredHorizontally) {
            target.x = rect.midX - bounds.width / 2
        } else if position.contains(.right) {
            target.x = rect.maxX - bounds.width
        } else if rect.minX < contentOffset.x {
            target.x = rect.minX
        } else if rect.maxX > contentOffset.x + bounds.width {
            target.x = rect.maxX - bounds.width
        }
        let lo = minContentOffset, hi = maxContentOffset
        target.x = Swift.min(Swift.max(target.x, lo.x), Swift.max(lo.x, hi.x))
        target.y = Swift.min(Swift.max(target.y, lo.y), Swift.max(lo.y, hi.y))
        setContentOffset(target, animated: animated)
    }
}
