import Foundation

/// Marker protocol for values that may be stored in a `CKRecord` field.
public protocol CKRecordValueProtocol {}

/// ObjC-bridged record value existential used by the public Swift overlay.
public typealias __CKRecordObjCValue = CKRecordValueProtocol
public typealias CKRecordValue = __CKRecordObjCValue

public protocol CKRecordKeyValueSetting: NSObjectProtocol {
    func allKeys() -> [String]
    func changedKeys() -> [String]
    func object(forKey key: String) -> (any CKRecordValue)?
    func setObject(_ object: (any CKRecordValue)?, forKey key: String)
    subscript(key: CKRecord.FieldKey) -> (any CKRecordValueProtocol)? { get set }
    subscript<T>(key: CKRecord.FieldKey) -> T? where T: CKRecordValueProtocol { get set }
}

public struct CKRecordKeyValueIterator: IteratorProtocol {
    public typealias Element = (CKRecord.FieldKey, any CKRecordValueProtocol)

    private var remaining: [Element]

    init(_ pairs: [Element]) {
        remaining = pairs
    }

    public mutating func next() -> Element? {
        guard !remaining.isEmpty else { return nil }
        return remaining.removeFirst()
    }
}

extension String: CKRecordValueProtocol {}
extension NSString: CKRecordValueProtocol {}
extension Bool: CKRecordValueProtocol {}
extension Int: CKRecordValueProtocol {}
extension Int8: CKRecordValueProtocol {}
extension Int16: CKRecordValueProtocol {}
extension Int32: CKRecordValueProtocol {}
extension Int64: CKRecordValueProtocol {}
extension UInt: CKRecordValueProtocol {}
extension UInt8: CKRecordValueProtocol {}
extension UInt16: CKRecordValueProtocol {}
extension UInt32: CKRecordValueProtocol {}
extension UInt64: CKRecordValueProtocol {}
extension Float: CKRecordValueProtocol {}
extension Double: CKRecordValueProtocol {}
extension NSNumber: CKRecordValueProtocol {}
extension Date: CKRecordValueProtocol {}
extension Data: CKRecordValueProtocol {}
extension Array: CKRecordValueProtocol where Element: CKRecordValueProtocol {}

final class CKRecordValueStore: NSObject, CKRecordKeyValueSetting, @unchecked Sendable {
    private var values: [String: any CKRecordValueProtocol] = [:]
    private var changed: Set<String> = []

    func allKeys() -> [String] {
        Array(values.keys)
    }

    func changedKeys() -> [String] {
        Array(changed)
    }

    func object(forKey key: String) -> (any CKRecordValue)? {
        values[key]
    }

    func setObject(_ object: (any CKRecordValue)?, forKey key: String) {
        if let object {
            values[key] = object
        } else {
            values.removeValue(forKey: key)
        }
        changed.insert(key)
    }

    subscript(key: CKRecord.FieldKey) -> (any CKRecordValueProtocol)? {
        get { object(forKey: key) }
        set { setObject(newValue, forKey: key) }
    }

    subscript<T>(key: CKRecord.FieldKey) -> T? where T: CKRecordValueProtocol {
        get { object(forKey: key) as? T }
        set { setObject(newValue, forKey: key) }
    }

    func clearChangedKeys() {
        changed.removeAll()
    }

    func pairs() -> [(CKRecord.FieldKey, any CKRecordValueProtocol)] {
        values.keys.sorted().compactMap { key in
            guard let value = values[key] else { return nil }
            return (key, value)
        }
    }

    func copyStore() -> CKRecordValueStore {
        let copy = CKRecordValueStore()
        copy.values = values
        copy.changed = changed
        return copy
    }

    func replaceAll(from other: CKRecordValueStore, keys: [String]?) {
        values.removeAll()
        changed.removeAll()
        for key in other.allKeys() {
            if let keys {
                var allowed = false
                for candidate in keys where candidate == key {
                    allowed = true
                    break
                }
                if !allowed { continue }
            }
            if let object = other.object(forKey: key) {
                values[key] = object
            }
        }
    }

    func mergeChanged(from other: CKRecordValueStore) {
        for key in other.changedKeys() {
            setObject(other.object(forKey: key), forKey: key)
        }
    }

    func archiveValues() -> [String: any CKRecordValueProtocol] {
        values
    }

    func restoreValues(_ restored: [String: any CKRecordValueProtocol]) {
        values = restored
        changed.removeAll()
    }
}
