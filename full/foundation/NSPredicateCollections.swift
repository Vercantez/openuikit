// Canonical predicate and reference-dictionary identities used by first-party
// frameworks in Linux-hosted Mach-O guests.
//
// This is deliberately a bounded Foundation slice. Predicates implement the
// constant and block forms without parsing an invented predicate language.
// Dictionaries implement real key copying, equality, mutation, and copying;
// persistence and fast enumeration remain later Foundation work.

#if FOUNDATION_CANONICAL_CONTRACTS_HOST
import Foundation
#else
import FoundationEssentials
import ObjectiveC
import Synchronization

// MARK: - Predicate

private enum _FoundationPredicateKind {
    case constant(Bool)
    case block((Any?, [String: Any]?) -> Bool)
}

private enum _FoundationPredicateArchiveTransport {
    private enum Snapshot: Sendable {
        case constant(Bool)
        case unsupported
    }

    private struct State: Sendable {
        var snapshots: [ObjectIdentifier: Snapshot] = [:]
        var order: [ObjectIdentifier] = []
    }

    private static let capacity = 64
    private static let state = Mutex(State())

    static func storeConstant(_ value: Bool, for coder: NSCoder) {
        store(.constant(value), for: coder)
    }

    static func storeUnsupported(for coder: NSCoder) {
        store(.unsupported, for: coder)
    }

    static func constant(for coder: NSCoder) -> Bool? {
        state.withLock { state in
            guard case .constant(let value) =
                    state.snapshots[ObjectIdentifier(coder)] else {
                return nil
            }
            return value
        }
    }

    private static func store(_ snapshot: Snapshot, for coder: NSCoder) {
        let identifier = ObjectIdentifier(coder)
        state.withLock { state in
            state.snapshots[identifier] = snapshot
            state.order.removeAll { $0 == identifier }
            state.order.append(identifier)
            while state.order.count > capacity {
                let evicted = state.order.removeFirst()
                state.snapshots.removeValue(forKey: evicted)
            }
        }
    }
}

/// A predicate with production constant and block evaluation semantics.
///
/// Format parsing is not guessed: consumers needing a parsed predicate receive
/// no silently incorrect implementation. Block predicates deliberately do not
/// round-trip through the opaque guest coder, while constant predicates do.
open class NSPredicate: NSObject, NSCopying, NSSecureCoding {
    private let kind: _FoundationPredicateKind

    open class var supportsSecureCoding: Bool { true }

    public init(value: Bool) {
        kind = .constant(value)
        super.init()
    }

    public init(
        block: @escaping (Any?, [String: Any]?) -> Bool
    ) {
        kind = .block(block)
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let value = _FoundationPredicateArchiveTransport.constant(
            for: coder
        ) else { return nil }
        kind = .constant(value)
        super.init()
    }

    open var predicateFormat: String {
        switch kind {
        case .constant(true):
            return "TRUEPREDICATE"
        case .constant(false):
            return "FALSEPREDICATE"
        case .block:
            return "BLOCKPREDICATE"
        }
    }

    open func evaluate(with object: Any?) -> Bool {
        evaluate(with: object, substitutionVariables: nil)
    }

    open func evaluate(
        with object: Any?,
        substitutionVariables bindings: [String: Any]?
    ) -> Bool {
        switch kind {
        case .constant(let value):
            return value
        case .block(let evaluator):
            return evaluator(object, bindings)
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }

    open func encode(with coder: NSCoder) {
        switch kind {
        case .constant(let value):
            _FoundationPredicateArchiveTransport.storeConstant(
                value,
                for: coder
            )
        case .block:
            _FoundationPredicateArchiveTransport.storeUnsupported(for: coder)
        }
    }
}

// MARK: - Reference dictionaries

private struct _FoundationDictionaryEntry: @unchecked Sendable {
    var key: Any
    var value: Any
}

private func _foundationDictionaryKeysEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let object = lhs as? NSObject, object.isEqual(rhs) {
        return true
    }
    if let object = rhs as? NSObject, object.isEqual(lhs) {
        return true
    }
    if let lhs = lhs as? AnyHashable,
       let rhs = rhs as? AnyHashable {
        return lhs == rhs
    }
    if Mirror(reflecting: lhs).displayStyle == .class,
       Mirror(reflecting: rhs).displayStyle == .class {
        return ObjectIdentifier(lhs as AnyObject)
            == ObjectIdentifier(rhs as AnyObject)
    }
    return false
}

// Decode the complete plist value graph, independent of any application's schema.
private enum _FoundationPlistValue: Decodable {
    case string(String), bool(Bool), integer(Int64), real(Double), data(Data), date(Date)
    case array([Self]), dictionary([String: Self])
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Int64.self) { self = .integer(value) }
        else if let value = try? container.decode(Double.self) { self = .real(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Data.self) { self = .data(value) }
        else if let value = try? container.decode(Date.self) { self = .date(value) }
        else if let value = try? container.decode([Self].self) { self = .array(value) }
        else { self = .dictionary(try container.decode([String: Self].self)) }
    }
    var object: Any {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value
        case .integer(let value): return value
        case .real(let value): return value
        case .data(let value): return value
        case .date(let value): return value
        case .array(let value): return value.map(\.object)
        case .dictionary(let value): return value.mapValues(\.object)
        }
    }
}

/// Immutable reference dictionary base for the Foundation class cluster.
open class NSDictionary: NSObject, NSCopying, @unchecked Sendable {
    fileprivate let entries: Mutex<[_FoundationDictionaryEntry]>

    public override init() {
        entries = Mutex([])
        super.init()
    }

    fileprivate init(entries: [_FoundationDictionaryEntry]) {
        self.entries = Mutex(entries)
        super.init()
    }

    public convenience init(dictionary: [AnyHashable: Any]) {
        self.init(entries: dictionary.map { _FoundationDictionaryEntry(key: $0.key, value: $0.value) })
    }
    public convenience init?(contentsOfFile path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let decoded = try? PropertyListDecoder().decode([String: _FoundationPlistValue].self, from: data)
        else { return nil }
        self.init(dictionary: decoded.reduce(into: [AnyHashable: Any]()) { $0[$1.key] = $1.value.object })
    }
    @objc
    open subscript(key: String) -> Any? { object(forKey: key) }

    open var count: Int { entries.withLock { $0.count } }

    open var allKeys: [Any] {
        entries.withLock { $0.map(\.key) }
    }

    open var allValues: [Any] {
        entries.withLock { $0.map(\.value) }
    }

    open func object(forKey aKey: Any) -> Any? {
        entries.withLock { entries in
            entries.first {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }?.value
        }
    }

    open subscript(key: any NSCopying) -> Any? {
        object(forKey: key)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }
}

/// Mutable Foundation reference dictionary with copied keys and retained
/// values. Individual operations are synchronized so concurrent framework
/// bookkeeping cannot corrupt its storage.
open class NSMutableDictionary: NSDictionary, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public init(capacity numItems: Int) {
        precondition(
            numItems >= 0,
            "NSMutableDictionary capacity must be nonnegative"
        )
        super.init()
    }

    open func setObject(_ anObject: Any, forKey aKey: any NSCopying) {
        entries.withLock { entries in
            if let index = entries.firstIndex(where: {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }) {
                entries[index].value = anObject
                return
            }
            entries.append(
                _FoundationDictionaryEntry(
                    key: aKey.copy(with: nil),
                    value: anObject
                )
            )
        }
    }

    open func removeObject(forKey aKey: Any) {
        entries.withLock { entries in
            entries.removeAll {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }
        }
    }

    open func removeAllObjects() {
        entries.withLock { $0.removeAll(keepingCapacity: false) }
    }

    open override subscript(key: any NSCopying) -> Any? {
        get { object(forKey: key) }
        set {
            if let newValue {
                setObject(newValue, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSDictionary(entries: entries.withLock { $0 })
    }
}
#endif
