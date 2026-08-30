// Ordered diffable table data. The snapshot is a value; the data source owns
// the last applied value and drives UITableView's existing identity-preserving
// update engine.

#if canImport(Foundation)
import struct Foundation.IndexPath
#endif

public struct NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    private var sections: [SectionIdentifierType] = []
    private var itemsBySection: [SectionIdentifierType: [ItemIdentifierType]] = [:]
    private var reloadedSectionSet: Set<SectionIdentifierType> = []
    private var reloadedItemSet: Set<ItemIdentifierType> = []

    public init() {}

    public var numberOfItems: Int { itemIdentifiers.count }
    public var numberOfSections: Int { sections.count }
    public var sectionIdentifiers: [SectionIdentifierType] { sections }
    public var itemIdentifiers: [ItemIdentifierType] {
        sections.flatMap { itemsBySection[$0] ?? [] }
    }

    public func numberOfItems(inSection identifier: SectionIdentifierType) -> Int {
        itemsBySection[identifier]?.count ?? 0
    }

    public func itemIdentifiers(inSection identifier: SectionIdentifierType)
        -> [ItemIdentifierType] {
        requireSection(identifier)
        return itemsBySection[identifier] ?? []
    }

    public func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        sections.firstIndex(of: identifier)
    }

    public func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        itemIdentifiers.firstIndex(of: identifier)
    }

    public func sectionIdentifier(containingItem identifier: ItemIdentifierType)
        -> SectionIdentifierType? {
        sections.first { itemsBySection[$0]?.contains(identifier) == true }
    }

    public mutating func appendSections(_ identifiers: [SectionIdentifierType]) {
        requireNewSections(identifiers)
        sections.append(contentsOf: identifiers)
        for identifier in identifiers { itemsBySection[identifier] = [] }
    }

    public mutating func insertSections(_ identifiers: [SectionIdentifierType],
                                        beforeSection beforeIdentifier: SectionIdentifierType) {
        requireNewSections(identifiers)
        requireSection(beforeIdentifier)
        let index = sections.firstIndex(of: beforeIdentifier)!
        sections.insert(contentsOf: identifiers, at: index)
        for identifier in identifiers { itemsBySection[identifier] = [] }
    }

    public mutating func insertSections(_ identifiers: [SectionIdentifierType],
                                        afterSection afterIdentifier: SectionIdentifierType) {
        requireNewSections(identifiers)
        requireSection(afterIdentifier)
        let index = sections.firstIndex(of: afterIdentifier)! + 1
        sections.insert(contentsOf: identifiers, at: index)
        for identifier in identifiers { itemsBySection[identifier] = [] }
    }

    public mutating func deleteSections(_ identifiers: [SectionIdentifierType]) {
        requireDistinct(identifiers, kind: "section")
        for identifier in identifiers { requireSection(identifier) }
        let deleting = Set(identifiers)
        let deletedItems = Set(identifiers.flatMap { itemsBySection[$0] ?? [] })
        sections.removeAll { deleting.contains($0) }
        for identifier in identifiers { itemsBySection.removeValue(forKey: identifier) }
        reloadedSectionSet.subtract(deleting)
        reloadedItemSet.subtract(deletedItems)
    }

    public mutating func moveSection(_ identifier: SectionIdentifierType,
                                     beforeSection toIdentifier: SectionIdentifierType) {
        moveSection(identifier, relativeTo: toIdentifier, after: false)
    }

    public mutating func moveSection(_ identifier: SectionIdentifierType,
                                     afterSection toIdentifier: SectionIdentifierType) {
        moveSection(identifier, relativeTo: toIdentifier, after: true)
    }

    public mutating func reloadSections(_ identifiers: [SectionIdentifierType]) {
        requireDistinct(identifiers, kind: "section")
        for identifier in identifiers { requireSection(identifier) }
        reloadedSectionSet.formUnion(identifiers)
    }

    public mutating func appendItems(_ identifiers: [ItemIdentifierType],
                                     toSection sectionIdentifier: SectionIdentifierType? = nil) {
        requireNewItems(identifiers)
        let section = resolvedSection(sectionIdentifier)
        itemsBySection[section, default: []].append(contentsOf: identifiers)
    }

    public mutating func insertItems(_ identifiers: [ItemIdentifierType],
                                     beforeItem beforeIdentifier: ItemIdentifierType) {
        insertItems(identifiers, relativeTo: beforeIdentifier, after: false)
    }

    public mutating func insertItems(_ identifiers: [ItemIdentifierType],
                                     afterItem afterIdentifier: ItemIdentifierType) {
        insertItems(identifiers, relativeTo: afterIdentifier, after: true)
    }

    public mutating func deleteItems(_ identifiers: [ItemIdentifierType]) {
        requireDistinct(identifiers, kind: "item")
        for identifier in identifiers { requireItem(identifier) }
        let deleting = Set(identifiers)
        for section in sections {
            itemsBySection[section]?.removeAll { deleting.contains($0) }
        }
        reloadedItemSet.subtract(deleting)
    }

    public mutating func moveItem(_ identifier: ItemIdentifierType,
                                  beforeItem toIdentifier: ItemIdentifierType) {
        moveItem(identifier, relativeTo: toIdentifier, after: false)
    }

    public mutating func moveItem(_ identifier: ItemIdentifierType,
                                  afterItem toIdentifier: ItemIdentifierType) {
        moveItem(identifier, relativeTo: toIdentifier, after: true)
    }

    public mutating func reloadItems(_ identifiers: [ItemIdentifierType]) {
        requireDistinct(identifiers, kind: "item")
        for identifier in identifiers { requireItem(identifier) }
        reloadedItemSet.formUnion(identifiers)
    }

    public mutating func deleteAllItems() {
        sections.removeAll()
        itemsBySection.removeAll()
        reloadedSectionSet.removeAll()
        reloadedItemSet.removeAll()
    }

    fileprivate var hasReloadedIdentifiers: Bool {
        !reloadedSectionSet.isEmpty || !reloadedItemSet.isEmpty
    }

    fileprivate func itemIdentifier(at indexPath: IndexPath) -> ItemIdentifierType? {
        guard sections.indices.contains(indexPath.section) else { return nil }
        let items = itemsBySection[sections[indexPath.section]] ?? []
        guard items.indices.contains(indexPath.row) else { return nil }
        return items[indexPath.row]
    }

    fileprivate func clearingReloadMarkers()
        -> NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        var copy = self
        copy.reloadedSectionSet.removeAll()
        copy.reloadedItemSet.removeAll()
        return copy
    }

    private func requireSection(_ identifier: SectionIdentifierType) {
        precondition(sections.contains(identifier),
                     "Invalid section identifier in diffable snapshot")
    }

    private func requireItem(_ identifier: ItemIdentifierType) {
        precondition(sectionIdentifier(containingItem: identifier) != nil,
                     "Invalid item identifier in diffable snapshot")
    }

    private func requireDistinct<T: Hashable>(_ identifiers: [T], kind: String) {
        precondition(Set(identifiers).count == identifiers.count,
                     "Duplicate \(kind) identifiers in diffable snapshot operation")
    }

    private func requireNewSections(_ identifiers: [SectionIdentifierType]) {
        requireDistinct(identifiers, kind: "section")
        precondition(identifiers.allSatisfy { !sections.contains($0) },
                     "Section identifiers must be unique in a diffable snapshot")
    }

    private func requireNewItems(_ identifiers: [ItemIdentifierType]) {
        requireDistinct(identifiers, kind: "item")
        let existing = Set(itemIdentifiers)
        precondition(identifiers.allSatisfy { !existing.contains($0) },
                     "Item identifiers must be unique in a diffable snapshot")
    }

    private func resolvedSection(_ identifier: SectionIdentifierType?)
        -> SectionIdentifierType {
        if let identifier {
            requireSection(identifier)
            return identifier
        }
        precondition(!sections.isEmpty,
                     "A section must exist before appending diffable items")
        return sections.last!
    }

    private mutating func moveSection(_ identifier: SectionIdentifierType,
                                      relativeTo target: SectionIdentifierType,
                                      after: Bool) {
        requireSection(identifier)
        requireSection(target)
        guard identifier != target else { return }
        sections.remove(at: sections.firstIndex(of: identifier)!)
        let targetIndex = sections.firstIndex(of: target)!
        sections.insert(identifier, at: targetIndex + (after ? 1 : 0))
    }

    private mutating func insertItems(_ identifiers: [ItemIdentifierType],
                                      relativeTo target: ItemIdentifierType,
                                      after: Bool) {
        requireNewItems(identifiers)
        guard let section = sectionIdentifier(containingItem: target),
              let index = itemsBySection[section]?.firstIndex(of: target) else {
            preconditionFailure("Invalid item identifier in diffable snapshot")
        }
        itemsBySection[section]!.insert(contentsOf: identifiers,
                                       at: index + (after ? 1 : 0))
    }

    private mutating func moveItem(_ identifier: ItemIdentifierType,
                                   relativeTo target: ItemIdentifierType,
                                   after: Bool) {
        requireItem(identifier)
        requireItem(target)
        guard identifier != target else { return }
        let sourceSection = sectionIdentifier(containingItem: identifier)!
        itemsBySection[sourceSection]!.removeAll { $0 == identifier }
        let targetSection = sectionIdentifier(containingItem: target)!
        let targetIndex = itemsBySection[targetSection]!.firstIndex(of: target)!
        itemsBySection[targetSection]!.insert(identifier,
                                             at: targetIndex + (after ? 1 : 0))
    }
}

@preconcurrency @MainActor
open class UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>:
    UITableViewDataSource
where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    public typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType,
                                                            ItemIdentifierType>
    public typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType)
        -> UITableViewCell?

    public var defaultRowAnimation: UITableView.RowAnimation = .automatic

    private weak var tableView: UITableView?
    private let cellProvider: CellProvider
    private var currentSnapshot = Snapshot()

    public init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.tableView = tableView
        self.cellProvider = cellProvider
        tableView.dataSource = self
    }

    open func snapshot() -> Snapshot { currentSnapshot }

    open func apply(_ snapshot: Snapshot,
                    animatingDifferences: Bool = true,
                    completion: (() -> Void)? = nil) {
        guard let tableView else {
            currentSnapshot = snapshot.clearingReloadMarkers()
            completion?()
            return
        }

        let next = snapshot.clearingReloadMarkers()
        if !animatingDifferences || snapshot.hasReloadedIdentifiers
            || defaultRowAnimation == .none {
            currentSnapshot = next
            tableView.reloadData()
            completion?()
            return
        }

        tableView.performUpdates(
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
        tableView?.reloadData()
        completion?()
    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        currentSnapshot.numberOfSections
    }

    open func tableView(_ tableView: UITableView,
                        numberOfRowsInSection section: Int) -> Int {
        guard currentSnapshot.sectionIdentifiers.indices.contains(section) else { return 0 }
        return currentSnapshot.numberOfItems(
            inSection: currentSnapshot.sectionIdentifiers[section])
    }

    open func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let identifier = currentSnapshot.itemIdentifier(at: indexPath),
              let cell = cellProvider(tableView, indexPath, identifier) else {
            preconditionFailure("UITableViewDiffableDataSource cell provider returned nil")
        }
        return cell
    }

    open func tableView(_ tableView: UITableView,
                        titleForHeaderInSection section: Int) -> String? { nil }

    open func tableView(_ tableView: UITableView,
                        titleForFooterInSection section: Int) -> String? { nil }

    open func tableView(_ tableView: UITableView,
                        canEditRowAt indexPath: IndexPath) -> Bool { true }

    open func tableView(_ tableView: UITableView,
                        editingStyleForRowAt indexPath: IndexPath)
        -> UITableViewCell.EditingStyle { .delete }

    open func tableView(_ tableView: UITableView,
                        commit editingStyle: UITableViewCell.EditingStyle,
                        forRowAt indexPath: IndexPath) {}
}
