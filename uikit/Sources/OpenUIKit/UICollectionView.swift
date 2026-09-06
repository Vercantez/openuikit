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
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

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
}

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
        layout.collectionView = self
        backgroundColor = .systemBackground
        alwaysBounceVertical = false
    }

    // MARK: Counts (cached; the layout asks for them once per prepare)

    private var sectionItemCounts: [Int] = []
    private var countsDirty = true

    private func ensureCounts() {
        guard countsDirty else { return }
        countsDirty = false
        sectionItemCounts.removeAll()
        guard let ds = dataSource else { return }
        let n = ds.numberOfSections(in: self)
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

    private func recycle(_ view: UICollectionReusableView) {
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
        visibleViews[ElementKey(kind: elementKind,
                                indexPath: IndexPath(item: 0, section: indexPath.section))]
    }

    // MARK: Geometry queries (forwarded to the layout)

    public func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        ensureCounts()
        return collectionViewLayout.layoutAttributesForItem(at: indexPath)
    }

    public func indexPathForItem(at point: CGPoint) -> IndexPath? {
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
        collectionViewLayout.invalidateLayout()
        setNeedsLayout()
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

    /// The layout told us its cache is stale.
    func _layoutInvalidated() {
        setNeedsLayout()
    }

    // MARK: Tiling

    private var inTile = false

    open override var bounds: CGRect {
        didSet {
            if bounds.size != oldValue.size,
               collectionViewLayout.shouldInvalidateLayout(forBoundsChange: bounds) {
                collectionViewLayout.invalidateLayout()
            }
            // Scrolling IS a bounds-origin change: re-tile immediately so
            // drags and deceleration steps bring elements in without waiting
            // for a layout pass (same rule as UITableView).
            if bounds.origin != oldValue.origin, !inTile {
                retile()
            }
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

        ensureCounts()
        collectionViewLayout.prepareIfNeeded()
        let size = collectionViewLayout.collectionViewContentSize
        if size != contentSize { contentSize = size }
        backgroundView?.frame = CGRect(origin: contentOffset, size: bounds.size)

        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        let attributes = collectionViewLayout.layoutAttributesForElements(in: visibleRect) ?? []

        var needed = Set<ElementKey>()
        needed.reserveCapacity(attributes.count)
        for a in attributes where a.representedElementCategory != .decorationView {
            needed.insert(a.elementKey)
        }

        visibleViews.retire(keeping: needed) { key, view in
            view.removeFromSuperview()
            if key.kind == nil, let cell = view as? UICollectionViewCell {
                collectionDelegate?.collectionView(self, didEndDisplaying: cell,
                                                   forItemAt: key.indexPath)
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
                let supp = ds.collectionView(self, viewForSupplementaryElementOfKind: kind,
                                             at: a.indexPath)
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
            if let cell = view as? UICollectionViewCell {
                collectionDelegate?.collectionView(self, willDisplay: cell,
                                                   forItemAt: a.indexPath)
            }
        }

        // Z-order: supplementary views above cells (UIKit's default zIndex
        // ordering puts headers/footers on top), background behind, scroll
        // indicators above everything.
        for a in attributes where a.representedElementKind != nil {
            if let v = visibleViews[a.elementKey] { bringSubviewToFront(v) }
        }
        if let bg = backgroundView { sendSubviewToBack(bg) }
        if let bar = verticalIndicator { bringSubviewToFront(bar) }
        if let bar = horizontalIndicator { bringSubviewToFront(bar) }
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
        guard collectionDelegate?.collectionView(self, shouldSelectItemAt: path) ?? true else {
            return
        }
        if allowsMultipleSelection, selectedPaths.contains(path) {
            deselectItem(at: path, animated: false)
            collectionDelegate?.collectionView(self, didDeselectItemAt: path)
            return
        }
        if !allowsMultipleSelection {
            for old in selectedPaths where old != path {
                cellForItem(at: old)?.isSelected = false
                selectedPaths.remove(old)
                collectionDelegate?.collectionView(self, didDeselectItemAt: old)
            }
        }
        selectedPaths.insert(path)
        cell.isSelected = true
        collectionDelegate?.collectionView(self, didSelectItemAt: path)
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
