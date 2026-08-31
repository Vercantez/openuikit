// Thread-safe Foundation NSCache for Linux-hosted Mach-O guests.
//
// The storage is a real strongly retaining, equality-keyed LRU cache.  Limits,
// delegate notifications, replacement, and recency behavior are pinned by a
// native Apple oracle. Delegate calls happen after releasing the storage lock;
// Apple itself rejects mutation reentry from an eviction callback, so callers
// must treat the callback as a notification rather than a mutation hook.

import ObjectiveC

private final class _FoundationGuestCacheKey: Hashable {
    let value: AnyObject

    init(_ value: AnyObject) {
        self.value = value
    }

    static func == (
        lhs: _FoundationGuestCacheKey,
        rhs: _FoundationGuestCacheKey
    ) -> Bool {
        if lhs.value === rhs.value { return true }

        if let lhsObject = lhs.value as? ObjectiveC.NSObject,
           let rhsObject = rhs.value as? ObjectiveC.NSObject {
            return lhsObject.isEqual(rhsObject)
        }

        if let lhsHashable = lhs.value as? AnyHashable,
           let rhsHashable = rhs.value as? AnyHashable {
            return lhsHashable == rhsHashable
        }

        return false
    }

    func hash(into hasher: inout Hasher) {
        if let object = value as? ObjectiveC.NSObject {
            hasher.combine(object.hash)
        } else if let hashable = value as? AnyHashable {
            hasher.combine(hashable)
        } else {
            hasher.combine(ObjectIdentifier(value))
        }
    }
}

private final class _FoundationGuestCacheEntry<
    KeyType: AnyObject,
    ObjectType: AnyObject
> {
    let key: KeyType
    let value: ObjectType
    let cost: Int
    var previous: _FoundationGuestCacheEntry?
    var next: _FoundationGuestCacheEntry?

    init(key: KeyType, value: ObjectType, cost: Int) {
        self.key = key
        self.value = value
        self.cost = cost
    }
}

public protocol NSCacheDelegate: NSObjectProtocol {
    func cache(
        _ cache: NSCache<AnyObject, AnyObject>,
        willEvictObject obj: Any
    )
}

public extension NSCacheDelegate {
    func cache(
        _ cache: NSCache<AnyObject, AnyObject>,
        willEvictObject obj: Any
    ) {
        _ = cache
        _ = obj
    }
}

@available(*, unavailable)
extension NSCache: @unchecked Sendable {}

open class NSCache<KeyType: AnyObject, ObjectType: AnyObject>:
    ObjectiveC.NSObject {
    private typealias Entry = _FoundationGuestCacheEntry<KeyType, ObjectType>

    private let _lock = NSLock()
    private var _entries: [_FoundationGuestCacheKey: Entry] = [:]
    private var _leastRecent: Entry?
    private var _mostRecent: Entry?
    private var _totalCost = 0
    private var _totalCostLimit = 0
    private var _countLimit = 0

    open var name: String = ""
    open var evictsObjectsWithDiscardedContent: Bool = true
    open weak var delegate: (any NSCacheDelegate)?

    open var totalCostLimit: Int {
        get {
            _lock.withLock { _totalCostLimit }
        }
        set {
            let evicted = _lock.withLock { () -> [ObjectType] in
                _totalCostLimit = newValue
                return _trimLocked()
            }
            _notify(evicted)
        }
    }

    open var countLimit: Int {
        get {
            _lock.withLock { _countLimit }
        }
        set {
            let evicted = _lock.withLock { () -> [ObjectType] in
                _countLimit = newValue
                return _trimLocked()
            }
            _notify(evicted)
        }
    }

    public override init() {
        super.init()
    }

    open func object(forKey key: KeyType) -> ObjectType? {
        _lock.withLock {
            guard let entry = _entries[_FoundationGuestCacheKey(key)] else {
                return nil
            }
            _moveToMostRecentLocked(entry)
            return entry.value
        }
    }

    open func setObject(_ obj: ObjectType, forKey key: KeyType) {
        setObject(obj, forKey: key, cost: 0)
    }

    open func setObject(
        _ obj: ObjectType,
        forKey key: KeyType,
        cost: Int
    ) {
        // Darwin stores the supplied signed cost in an unsigned accounting
        // domain. A negative cost therefore exceeds every positive public
        // limit and is evicted immediately; the native oracle pins this edge
        // rather than inheriting swift-corelibs-foundation's `max(cost, 0)`.
        let normalizedCost = cost < 0 ? Int.max : cost
        let evicted = _lock.withLock { () -> [ObjectType] in
            var evicted: [ObjectType] = []
            let wrappedKey = _FoundationGuestCacheKey(key)

            if let replaced = _entries.removeValue(forKey: wrappedKey) {
                _unlinkLocked(replaced)
                _subtractCostLocked(replaced.cost)
                evicted.append(replaced.value)
            }

            let entry = Entry(key: key, value: obj, cost: normalizedCost)
            _entries[wrappedKey] = entry
            _appendMostRecentLocked(entry)
            _addCostLocked(normalizedCost)
            evicted.append(contentsOf: _trimLocked())
            return evicted
        }
        _notify(evicted)
    }

    open func removeObject(forKey key: KeyType) {
        let evicted = _lock.withLock { () -> [ObjectType] in
            guard let entry = _entries.removeValue(
                forKey: _FoundationGuestCacheKey(key)
            ) else {
                return []
            }
            _unlinkLocked(entry)
            _subtractCostLocked(entry.cost)
            return [entry.value]
        }
        _notify(evicted)
    }

    open func removeAllObjects() {
        let evicted = _lock.withLock { () -> [ObjectType] in
            var values: [ObjectType] = []
            var entry = _leastRecent
            while let current = entry {
                values.append(current.value)
                entry = current.next
                current.previous = nil
                current.next = nil
            }
            _entries.removeAll(keepingCapacity: false)
            _leastRecent = nil
            _mostRecent = nil
            _totalCost = 0
            return values
        }
        _notify(evicted)
    }

    private func _trimLocked() -> [ObjectType] {
        var evicted: [ObjectType] = []
        while (_countLimit > 0 && _entries.count > _countLimit) ||
            (_totalCostLimit > 0 && _totalCost > _totalCostLimit) {
            guard let entry = _leastRecent else { break }
            _entries.removeValue(forKey: _FoundationGuestCacheKey(entry.key))
            _unlinkLocked(entry)
            _subtractCostLocked(entry.cost)
            evicted.append(entry.value)
        }
        return evicted
    }

    private func _appendMostRecentLocked(_ entry: Entry) {
        entry.previous = _mostRecent
        entry.next = nil
        _mostRecent?.next = entry
        _mostRecent = entry
        if _leastRecent == nil {
            _leastRecent = entry
        }
    }

    private func _moveToMostRecentLocked(_ entry: Entry) {
        guard entry !== _mostRecent else { return }
        _unlinkLocked(entry)
        _appendMostRecentLocked(entry)
    }

    private func _unlinkLocked(_ entry: Entry) {
        if entry === _leastRecent {
            _leastRecent = entry.next
        }
        if entry === _mostRecent {
            _mostRecent = entry.previous
        }
        entry.previous?.next = entry.next
        entry.next?.previous = entry.previous
        entry.previous = nil
        entry.next = nil
    }

    private func _addCostLocked(_ cost: Int) {
        let addition = _totalCost.addingReportingOverflow(cost)
        _totalCost = addition.overflow ? Int.max : addition.partialValue
    }

    private func _subtractCostLocked(_ cost: Int) {
        if _totalCost != Int.max {
            _totalCost -= cost
            return
        }

        var recomputed = 0
        var entry = _leastRecent
        while let current = entry {
            let addition = recomputed.addingReportingOverflow(current.cost)
            recomputed = addition.overflow ? Int.max : addition.partialValue
            if recomputed == Int.max { break }
            entry = current.next
        }
        _totalCost = recomputed
    }

    private func _notify(_ values: [ObjectType]) {
        guard !values.isEmpty, let delegate else { return }
        // NSCache's delegate API erases the generic arguments. Generic class
        // specializations are invariant, so `unsafeDowncast` rejects this
        // Foundation-required reabstraction. Rebind the same retained object
        // pointer through Unmanaged; key and value are both class references,
        // so their erased ABI representation is identical and delegate
        // original cache identity is preserved for the delegate.
        let opaque = Unmanaged.passUnretained(self).toOpaque()
        let erased = Unmanaged<NSCache<AnyObject, AnyObject>>
            .fromOpaque(opaque)
            .takeUnretainedValue()
        for value in values {
            delegate.cache(erased, willEvictObject: value)
        }
    }
}
