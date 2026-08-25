// Shared view-recycling machinery. Owner: collection module (M13).
//
// UITableView shipped with reuse (per-identifier pools + registered classes +
// prepareForReuse on dequeue) welded into the class. UICollectionView needs
// the SAME machinery for two families of views (cells and supplementary
// views), so it lives here and both containers drive one implementation:
//
//   ReuseRegistry<V>  — registered factories + per-identifier recycle pools.
//   VisibleViewMap<K, V> — which views are currently instantiated for which
//                        keys, and the retire step of a tiling pass.
//
// Nothing here is measured against UIKit: reuse is invisible in a rendered
// frame. What IS held to account is the invariant the tests assert — a 10k
// row/item scroll instantiates only ~one screenful of views (see
// TableViewTests / CollectionViewTests).

/// A view a container can recycle: it knows the identifier it was created
/// for and can reset itself before being handed back out.
///
/// Internal on purpose — real UIKit has no such protocol (it uses
/// `-prepareForReuse` by convention on unrelated classes), so exporting one
/// would add API an app cannot have written against.
protocol ReusableView: AnyObject {
    var reuseIdentifier: String? { get }
    func prepareForReuse()
}

/// Recycled views kept per identifier. Must hold at least a screenful: a far
/// `setContentOffset` jump retires EVERY visible view and re-tiles the same
/// count from the pool (a smaller cap would allocate on every jump; steady
/// scrolling only ever pools one or two).
let reusePoolCapacityPerIdentifier = 64

/// Registered factories + per-identifier recycle pools for one family of
/// reusable views (a table's cells, a collection's cells, a collection's
/// supplementary views of one kind).
final class ReuseRegistry<V: ReusableView> {
    private var pools: [String: [V]] = [:]
    private var factories: [String: (String) -> V] = [:]

    /// `register(_:forCellReuseIdentifier:)` and friends: the factory is
    /// handed the identifier so it can stamp it onto the new view.
    func register(identifier: String, factory: @escaping (String) -> V) {
        factories[identifier] = factory
    }

    /// A pooled view (reset via `prepareForReuse`) if one is waiting, else a
    /// freshly built one if the identifier is registered, else nil (UIKit's
    /// `dequeueReusableCell(withIdentifier:)` returns nil the same way).
    func dequeue(_ identifier: String) -> V? {
        if var pool = pools[identifier], !pool.isEmpty {
            let view = pool.removeLast()
            pools[identifier] = pool
            view.prepareForReuse()
            return view
        }
        return factories[identifier]?(identifier)
    }

    /// Hand a retired view back to its pool (dropped once the pool is full,
    /// and dropped entirely for a view created without an identifier).
    func recycle(_ view: V) {
        guard let id = view.reuseIdentifier else { return }
        var pool = pools[id] ?? []
        guard pool.count < reusePoolCapacityPerIdentifier else { return }
        pool.append(view)
        pools[id] = pool
    }

}

/// The views a tiling container currently has instantiated, keyed by whatever
/// identifies a slot (an IndexPath for cells, a section index for a table's
/// header, a kind+IndexPath for a supplementary view).
///
/// The container owns creation (it needs its data source); this type owns the
/// bookkeeping and the retire half of a tiling pass, which both containers
/// would otherwise spell out per view family.
struct VisibleViewMap<Key: Hashable, V: AnyObject> {
    private(set) var views: [Key: V] = [:]

    subscript(key: Key) -> V? {
        get { views[key] }
        set { views[key] = newValue }
    }

    var isEmpty: Bool { views.isEmpty }
    var keys: Dictionary<Key, V>.Keys { views.keys }

    /// Drop every view whose key is no longer needed, calling `retire` on
    /// each (remove from the superview, recycle, …).
    mutating func retire(keeping needed: Set<Key>, _ retire: (Key, V) -> Void) {
        for (key, view) in views where !needed.contains(key) {
            views[key] = nil
            retire(key, view)
        }
    }

    /// Drop everything, calling `retire` on each view.
    mutating func removeAll(_ retire: (Key, V) -> Void) {
        for (key, view) in views { retire(key, view) }
        views.removeAll()
    }

    mutating func replaceAll(with newViews: [Key: V]) {
        views = newViews
    }

    func first(where predicate: (Key, V) -> Bool) -> (key: Key, value: V)? {
        for (k, v) in views where predicate(k, v) { return (k, v) }
        return nil
    }
}
