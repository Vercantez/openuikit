// UICollectionViewDiffableDataSource + NSDiffableDataSourceSectionSnapshot.
// Owner: table/collection extras (APP_LADDER §4 row 9: collection half,
// 7 apps / 36 uses). Apply uses the same identity-preserving batch path
// UITableViewDiffableDataSource already measured: insert/delete/move keep
// the live cell when the identifier is unchanged.

#if canImport(Foundation)
import struct Foundation.IndexPath
#endif
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#endif

public struct NSDiffableDataSourceSectionSnapshot<ItemIdentifierType: Hashable> {
    private var order: [ItemIdentifierType] = []
    private var parentOf: [ItemIdentifierType: ItemIdentifierType] = [:]
    private var childrenOf: [ItemIdentifierType: [ItemIdentifierType]] = [:]
    private var expandedItems: Set<ItemIdentifierType> = []

    public init() {}

    public func items() -> [ItemIdentifierType] { order }
    public func rootItems() -> [ItemIdentifierType] {
        order.filter { parentOf[$0] == nil }
    }

    public func visibleItems() -> [ItemIdentifierType] {
        var out: [ItemIdentifierType] = []
        func walk(_ item: ItemIdentifierType) {
            out.append(item)
            if expandedItems.contains(item) {
                for child in childrenOf[item] ?? [] { walk(child) }
            }
        }
        for root in rootItems() { walk(root) }
        return out
    }

    public func parent(of item: ItemIdentifierType) -> ItemIdentifierType? {
        parentOf[item]
    }

    public func level(of item: ItemIdentifierType) -> Int {
        var n = 0
        var cur = parentOf[item]
        while let p = cur {
            n += 1
            cur = parentOf[p]
        }
        return n
    }

    public func isExpanded(_ item: ItemIdentifierType) -> Bool {
        expandedItems.contains(item)
    }

    public func contains(_ item: ItemIdentifierType) -> Bool {
        parentOf[item] != nil || order.contains(item)
    }

    public func snapshot(of parent: ItemIdentifierType,
                         includingParent: Bool = false)
        -> NSDiffableDataSourceSectionSnapshot<ItemIdentifierType> {
        var snap = NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>()
        if includingParent { snap.append([parent]) }
        func copy(_ item: ItemIdentifierType) {
            let kids = childrenOf[item] ?? []
            if !kids.isEmpty {
                snap.append(kids, to: item)
                if expandedItems.contains(item) { snap.expand([item]) }
                for k in kids { copy(k) }
            }
        }
        copy(parent)
        return snap
    }

    public mutating func append(_ items: [ItemIdentifierType],
                                to parent: ItemIdentifierType? = nil) {
        for item in items {
            precondition(!order.contains(item),
                         "Item identifiers must be unique in a section snapshot")
            order.append(item)
            if let parent {
                precondition(order.contains(parent),
                             "Parent identifier missing from section snapshot")
                parentOf[item] = parent
                childrenOf[parent, default: []].append(item)
            }
        }
        if let parent { expandedItems.insert(parent) }
    }

    public mutating func insert(_ items: [ItemIdentifierType],
                                before item: ItemIdentifierType) {
        insert(items, relativeTo: item, after: false)
    }

    public mutating func insert(_ items: [ItemIdentifierType],
                                after item: ItemIdentifierType) {
        insert(items, relativeTo: item, after: true)
    }

    public mutating func delete(_ items: [ItemIdentifierType]) {
        var removing = Set(items)
        func collect(_ item: ItemIdentifierType) {
            for child in childrenOf[item] ?? [] {
                removing.insert(child)
                collect(child)
            }
        }
        for item in items { collect(item) }
        order.removeAll { removing.contains($0) }
        for item in removing {
            if let parent = parentOf[item] {
                childrenOf[parent]?.removeAll { $0 == item }
            }
            parentOf.removeValue(forKey: item)
            childrenOf.removeValue(forKey: item)
            expandedItems.remove(item)
        }
    }

    public mutating func expand(_ items: [ItemIdentifierType]) {
        for item in items where order.contains(item) {
            expandedItems.insert(item)
        }
    }

    public mutating func collapse(_ items: [ItemIdentifierType]) {
        expandedItems.subtract(items)
    }

    public mutating func replace(childrenOf parent: ItemIdentifierType,
                                 using snapshot: NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>) {
        let existing = childrenOf[parent] ?? []
        delete(existing)
        append(snapshot.rootItems(), to: parent)
        for item in snapshot.order where snapshot.parentOf[item] != nil {
            if !order.contains(item) {
                append([item], to: snapshot.parentOf[item])
            }
        }
        for item in snapshot.expandedItems { expand([item]) }
    }

    public func visualSnapshot() -> NSDiffableDataSourceSectionSnapshot<ItemIdentifierType> {
        var snap = NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>()
        snap.append(visibleItems())
        return snap
    }

    private mutating func insert(_ items: [ItemIdentifierType],
                                 relativeTo target: ItemIdentifierType,
                                 after: Bool) {
        for item in items {
            precondition(!order.contains(item),
                         "Item identifiers must be unique in a section snapshot")
        }
        guard let index = order.firstIndex(of: target) else {
            preconditionFailure("Invalid item identifier in section snapshot")
        }
        let parent = parentOf[target]
        order.insert(contentsOf: items, at: index + (after ? 1 : 0))
        for item in items {
            if let parent {
                parentOf[item] = parent
                let kids = childrenOf[parent] ?? []
                if let t = kids.firstIndex(of: target) {
                    childrenOf[parent]?.insert(contentsOf: items, at: t + (after ? 1 : 0))
                } else {
                    childrenOf[parent, default: []].append(contentsOf: items)
                }
            }
        }
    }
}

@preconcurrency @MainActor
open class UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>:
    UICollectionViewDataSource
where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    public typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                            ItemIdentifierType>
    public typealias CellProvider = (UICollectionView, IndexPath, ItemIdentifierType)
        -> UICollectionViewCell?
    public typealias SupplementaryViewProvider =
        (UICollectionView, String, IndexPath) -> UICollectionReusableView?

    public struct ReorderingHandlers {
        public var canReorderItem: ((ItemIdentifierType) -> Bool)?
        public var willReorder: ((NSDiffableDataSourceTransaction<SectionIdentifierType,
                                                                   ItemIdentifierType>) -> Void)?
        public var didReorder: ((NSDiffableDataSourceTransaction<SectionIdentifierType,
                                                                  ItemIdentifierType>) -> Void)?
        public init() {}
    }

    public struct SectionSnapshotHandlers {
        public var shouldExpandItem: ((ItemIdentifierType) -> Bool)?
        public var willExpandItem: ((ItemIdentifierType) -> Void)?
        public var didExpandItem: ((ItemIdentifierType) -> Void)?
        public var shouldCollapseItem: ((ItemIdentifierType) -> Bool)?
        public var willCollapseItem: ((ItemIdentifierType) -> Void)?
        public var didCollapseItem: ((ItemIdentifierType) -> Void)?
        public var snapshotForExpandingParent: ((ItemIdentifierType,
                                                 NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>)
            -> NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>)?
        public init() {}
    }

    public var supplementaryViewProvider: SupplementaryViewProvider?
    public var reorderingHandlers = ReorderingHandlers()
    public var sectionSnapshotHandlers = SectionSnapshotHandlers()

    private weak var collectionView: UICollectionView?
    private let cellProvider: CellProvider
    private var currentSnapshot = Snapshot()
    private var sectionSnapshots: [SectionIdentifierType:
        NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>] = [:]

    public init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        self.collectionView = collectionView
        self.cellProvider = cellProvider
        collectionView.dataSource = self
    }

    open func snapshot() -> Snapshot { currentSnapshot }

    open func snapshot(for section: SectionIdentifierType)
        -> NSDiffableDataSourceSectionSnapshot<ItemIdentifierType> {
        sectionSnapshots[section] ?? NSDiffableDataSourceSectionSnapshot()
    }

    open func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        currentSnapshot.itemIdentifier(at: indexPath)
    }

    open func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        guard let sectionID = currentSnapshot.sectionIdentifier(containingItem: itemIdentifier),
              let section = currentSnapshot.indexOfSection(sectionID),
              let row = currentSnapshot.itemIdentifiers(inSection: sectionID)
                .firstIndex(of: itemIdentifier) else { return nil }
        return IndexPath(item: row, section: section)
    }

    open func sectionIdentifier(for index: Int) -> SectionIdentifierType? {
        guard currentSnapshot.sectionIdentifiers.indices.contains(index) else { return nil }
        return currentSnapshot.sectionIdentifiers[index]
    }

    open func apply(_ snapshot: Snapshot,
                    animatingDifferences: Bool = true,
                    completion: (() -> Void)? = nil) {
        guard let collectionView else {
            currentSnapshot = snapshot.clearingReloadMarkers()
            completion?()
            return
        }
        let next = snapshot.clearingReloadMarkers()
        if !animatingDifferences || snapshot.hasReloadedIdentifiers {
            currentSnapshot = next
            collectionView.reloadData()
            completion?()
            return
        }
        collectionView.performUpdates(
            withDuration: 0.25,
            identity: { [unowned self] indexPath in
                AnyHashable(self.currentSnapshot.itemIdentifier(at: indexPath)!)
            },
            updates: { self.currentSnapshot = next },
            completion: completion)
    }

    open func applySnapshotUsingReloadData(_ snapshot: Snapshot,
                                           completion: (() -> Void)? = nil) {
        currentSnapshot = snapshot.clearingReloadMarkers()
        collectionView?.reloadData()
        completion?()
    }

    open func apply(_ snapshot: NSDiffableDataSourceSectionSnapshot<ItemIdentifierType>,
                    to section: SectionIdentifierType,
                    animatingDifferences: Bool = true,
                    completion: (() -> Void)? = nil) {
        sectionSnapshots[section] = snapshot
        var full = currentSnapshot
        if full.indexOfSection(section) == nil {
            full.appendSections([section])
        }
        let existing = full.itemIdentifiers(inSection: section)
        if !existing.isEmpty { full.deleteItems(existing) }
        full.appendItems(snapshot.visibleItems(), toSection: section)
        apply(full, animatingDifferences: animatingDifferences, completion: completion)
    }

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        currentSnapshot.numberOfSections
    }

    open func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
        guard currentSnapshot.sectionIdentifiers.indices.contains(section) else { return 0 }
        return currentSnapshot.numberOfItems(
            inSection: currentSnapshot.sectionIdentifiers[section])
    }

    open func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let identifier = currentSnapshot.itemIdentifier(at: indexPath),
              let cell = cellProvider(collectionView, indexPath, identifier) else {
            preconditionFailure("UICollectionViewDiffableDataSource cell provider returned nil")
        }
        if let list = cell as? UICollectionViewListCell,
           let sectionID = currentSnapshot.sectionIdentifiers.indices.contains(indexPath.section)
            ? currentSnapshot.sectionIdentifiers[indexPath.section] : nil {
            let snap = sectionSnapshots[sectionID]
            list.indentationLevel = snap?.level(of: identifier) ?? 0
            list.isListExpanded = snap?.isExpanded(identifier) ?? false
        }
        return cell
    }

    open func collectionView(_ collectionView: UICollectionView,
                             viewForSupplementaryElementOfKind kind: String,
                             at indexPath: IndexPath) -> UICollectionReusableView {
        if let supplementaryViewProvider,
           let view = supplementaryViewProvider(collectionView, kind, indexPath) {
            return view
        }
        return UICollectionReusableView()
    }
}

public struct NSDiffableDataSourceTransaction<SectionIdentifierType: Hashable,
                                              ItemIdentifierType: Hashable> {
    public let initialSnapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                            ItemIdentifierType>
    public let finalSnapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                          ItemIdentifierType>
    public let difference: CollectionDifference<ItemIdentifierType>

    public init(initialSnapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                             ItemIdentifierType>,
                finalSnapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                           ItemIdentifierType>) {
        self.initialSnapshot = initialSnapshot
        self.finalSnapshot = finalSnapshot
        self.difference = initialSnapshot.itemIdentifiers.difference(from: finalSnapshot.itemIdentifiers)
    }
}

extension UICollectionView {
    /// Identity-preserving batch update, the collection twin of
    /// `UITableView.performUpdates`. Insert/delete/move keep the live cell
    /// when `identity` matches across the update — the same rule the table
    /// diffable data source already uses.
    public func performUpdates(withDuration duration: Double,
                               identity: (IndexPath) -> AnyHashable,
                               updates: () -> Void,
                               completion: (() -> Void)? = nil) {
        guard dataSource != nil, bounds.width > 0 else {
            updates()
            reloadData()
            completion?()
            return
        }
        var oldCells: [AnyHashable: UICollectionViewCell] = [:]
        var oldFrames: [AnyHashable: CGRect] = [:]
        for (key, view) in visibleViews.views where key.kind == nil {
            if let cell = view as? UICollectionViewCell {
                let id = identity(key.indexPath)
                oldCells[id] = cell
                oldFrames[id] = cell.frame
            }
        }
        updates()
        countsDirty = true
        collectionViewLayout.invalidateLayout()
        collectionViewLayout.prepareIfNeeded()

        var rekeyed: [ElementKey: UICollectionReusableView] = [:]
        var kept = Set<ObjectIdentifier>()
        let n = numberOfSections
        for s in 0..<n {
            let count = numberOfItems(inSection: s)
            for i in 0..<count {
                let path = IndexPath(item: i, section: s)
                let id = identity(path)
                if let cell = oldCells[id] {
                    let key = ElementKey(kind: nil, indexPath: path)
                    rekeyed[key] = cell
                    kept.insert(ObjectIdentifier(cell))
                }
            }
        }
        for (key, view) in visibleViews.views where key.kind == nil {
            if !kept.contains(ObjectIdentifier(view)) {
                view.removeFromSuperview()
                recycle(view)
            }
        }
        for (key, view) in rekeyed {
            visibleViews[key] = view
        }
        retile()

        var moves: [(view: UIView, target: CGRect)] = []
        var fadeIns: [UIView] = []
        for (key, view) in visibleViews.views where key.kind == nil {
            let id = identity(key.indexPath)
            let target = view.frame
            if let old = oldFrames[id], old != target {
                view.frame = old
                moves.append((view, target))
            } else if oldFrames[id] == nil {
                view.alpha = 0
                fadeIns.append(view)
            }
        }
        guard !moves.isEmpty || !fadeIns.isEmpty else {
            completion?()
            return
        }
        let animated = moves.map(\.view) + fadeIns
        UIView.animate(withDuration: duration, animations: {
            for m in moves { m.view.frame = m.target }
            for v in fadeIns { v.alpha = 1 }
        }, completion: { _ in
            let now = OpenUIKitRuntime.animationTime
            for v in animated { v._removeFinishedAnimations(at: now) }
            completion?()
        })
    }
}
