// Canonical coding protocols and bounded keyed operations for the standalone
// Foundation guest.
//
// UIKit was compiled before the Foundation facade, so OpenUIKit already owns
// the NSCoder nominal identity. Foundation extends that exact class rather
// than introducing an incompatible second coder. Until NSKeyedArchiver owns a
// byte archive format, keyed values are an in-process, bounded transport:
// missing values and disallowed classes fail closed.

#if FOUNDATION_GUEST_CODER_HOST
import Foundation
#else
import FoundationEssentials
import ObjectiveC
import Synchronization

public protocol NSCoding: AnyObject {
    init?(coder: NSCoder)
    func encode(with coder: NSCoder)
}

public protocol NSSecureCoding: NSCoding {
    static var supportsSecureCoding: Bool { get }
}

private enum _FoundationGuestCoderValue: @unchecked Sendable {
    case null
    case object(Any)
    case bool(Bool)
    case double(Double)
    case float(Float)
    case int(Int)
    case int32(Int32)
    case int64(Int64)
}

private enum _FoundationGuestCoderTransport {
    private struct State: @unchecked Sendable {
        var values: [ObjectIdentifier: [String: _FoundationGuestCoderValue]] =
            [:]
        var order: [ObjectIdentifier] = []
    }

    private static let capacity = 64
    private static let state = Mutex(State())

    static func set(
        _ value: _FoundationGuestCoderValue,
        forKey key: String,
        coder: NSCoder
    ) {
        let identifier = ObjectIdentifier(coder)
        state.withLock { state in
            state.values[identifier, default: [:]][key] = value
            state.order.removeAll { $0 == identifier }
            state.order.append(identifier)
            while state.order.count > capacity {
                let evicted = state.order.removeFirst()
                state.values.removeValue(forKey: evicted)
            }
        }
    }

    static func value(
        forKey key: String,
        coder: NSCoder
    ) -> _FoundationGuestCoderValue? {
        state.withLock { $0.values[ObjectIdentifier(coder)]?[key] }
    }

    static func containsValue(forKey key: String, coder: NSCoder) -> Bool {
        state.withLock {
            $0.values[ObjectIdentifier(coder)]?[key] != nil
        }
    }
}

private func _foundationGuestCoderObject(
    _ value: _FoundationGuestCoderValue?
) -> Any? {
    guard let value else { return nil }
    switch value {
    case .null:
        return nil
    case .object(let object):
        return object
    case .bool(let value):
        return value
    case .double(let value):
        return value
    case .float(let value):
        return value
    case .int(let value):
        return value
    case .int32(let value):
        return value
    case .int64(let value):
        return value
    }
}

private func _foundationGuestCoderClassIsAllowed(
    _ object: Any,
    classes: [AnyClass]
) -> Bool {
    var currentClass: AnyClass? = object_getClass(object as AnyObject)
    while let candidate = currentClass {
        if classes.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(candidate) }) {
            return true
        }
        currentClass = class_getSuperclass(candidate)
    }
    return false
}

public extension NSCoder {
    var allowsKeyedCoding: Bool { true }

    func containsValue(forKey key: String) -> Bool {
        _FoundationGuestCoderTransport.containsValue(forKey: key, coder: self)
    }

    func encode(_ object: Any?, forKey key: String) {
        _FoundationGuestCoderTransport.set(
            object.map(_FoundationGuestCoderValue.object) ?? .null,
            forKey: key,
            coder: self
        )
    }

    func encode(_ value: Bool, forKey key: String) {
        _FoundationGuestCoderTransport.set(.bool(value), forKey: key, coder: self)
    }

    func encode(_ value: Double, forKey key: String) {
        _FoundationGuestCoderTransport.set(
            .double(value),
            forKey: key,
            coder: self
        )
    }

    func encode(_ value: Float, forKey key: String) {
        _FoundationGuestCoderTransport.set(.float(value), forKey: key, coder: self)
    }

    func encode(_ value: Int, forKey key: String) {
        _FoundationGuestCoderTransport.set(.int(value), forKey: key, coder: self)
    }

    func encode(_ value: Int32, forKey key: String) {
        _FoundationGuestCoderTransport.set(.int32(value), forKey: key, coder: self)
    }

    func encode(_ value: Int64, forKey key: String) {
        _FoundationGuestCoderTransport.set(.int64(value), forKey: key, coder: self)
    }

    func decodeObject(forKey key: String) -> Any? {
        _foundationGuestCoderObject(
            _FoundationGuestCoderTransport.value(forKey: key, coder: self)
        )
    }

    func decodeObject<DecodedObjectType>(
        of cls: DecodedObjectType.Type,
        forKey key: String
    ) -> DecodedObjectType?
    where DecodedObjectType: NSObject, DecodedObjectType: NSCoding {
        guard let object = decodeObject(forKey: key),
              _foundationGuestCoderClassIsAllowed(object, classes: [cls])
        else { return nil }
        return object as? DecodedObjectType
    }

    func decodeObject(
        of classes: [AnyClass]?,
        forKey key: String
    ) -> Any? {
        guard let object = decodeObject(forKey: key) else { return nil }
        guard let classes else { return object }
        guard _foundationGuestCoderClassIsAllowed(object, classes: classes)
        else { return nil }
        return object
    }

    func decodeBool(forKey key: String) -> Bool {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .bool(let value): return value
        case .int(let value): return value != 0
        case .int32(let value): return value != 0
        case .int64(let value): return value != 0
        default: return false
        }
    }

    func decodeDouble(forKey key: String) -> Double {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .double(let value): return value
        case .float(let value): return Double(value)
        case .int(let value): return Double(value)
        case .int32(let value): return Double(value)
        case .int64(let value): return Double(value)
        default: return 0
        }
    }

    func decodeFloat(forKey key: String) -> Float {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .float(let value): return value
        case .double(let value): return Float(value)
        case .int(let value): return Float(value)
        case .int32(let value): return Float(value)
        case .int64(let value): return Float(value)
        default: return 0
        }
    }

    func decodeInteger(forKey key: String) -> Int {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .int(let value): return value
        case .int32(let value): return Int(value)
        case .int64(let value): return Int(clamping: value)
        case .bool(let value): return value ? 1 : 0
        default: return 0
        }
    }

    func decodeInt32(forKey key: String) -> Int32 {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .int32(let value): return value
        case .int(let value): return Int32(clamping: value)
        case .int64(let value): return Int32(clamping: value)
        case .bool(let value): return value ? 1 : 0
        default: return 0
        }
    }

    func decodeInt64(forKey key: String) -> Int64 {
        switch _FoundationGuestCoderTransport.value(forKey: key, coder: self) {
        case .int64(let value): return value
        case .int(let value): return Int64(value)
        case .int32(let value): return Int64(value)
        case .bool(let value): return value ? 1 : 0
        default: return 0
        }
    }
}
#endif
