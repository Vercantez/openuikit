// Bounded Objective-C reference collection and data identities for the
// standalone Foundation guest.
//
// These types restore the canonical Swift bridging boundary needed by
// first-party frameworks: Swift arrays and Data can be passed through APIs
// spelled NSArray and NSData without changing consumer sources. The
// implementations own real in-process storage, copying, mutation, and keyed
// coding; plist parsing and Foundation's private class-cluster subclasses are
// intentionally outside this slice.

import FoundationEssentials
import ObjectiveC
import Synchronization

public protocol NSMutableCopying: AnyObject {
    func mutableCopy(with zone: NSZone?) -> Any
}

public extension NSMutableCopying {
    func mutableCopy() -> Any { mutableCopy(with: nil) }
}

private func _foundationReferenceObjectsEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let object = lhs as? NSObject, object.isEqual(rhs) { return true }
    if let object = rhs as? NSObject, object.isEqual(lhs) { return true }
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

open class NSArray: NSObject, NSCopying, NSMutableCopying, NSSecureCoding,
    ExpressibleByArrayLiteral, Sequence, @unchecked Sendable {
    fileprivate let storage: Mutex<[Any]>

    open class var supportsSecureCoding: Bool { true }

    public override init() {
        storage = Mutex([])
        super.init()
    }

    public required init(objects: UnsafePointer<AnyObject>?, count: Int) {
        precondition(count >= 0, "NSArray count must be nonnegative")
        precondition(count == 0 || objects != nil, "NSArray objects are missing")
        var values: [Any] = []
        values.reserveCapacity(count)
        if let objects {
            for index in 0..<count { values.append(objects[index]) }
        }
        storage = Mutex(values)
        super.init()
    }

    public convenience init(array: [Any]) {
        self.init()
        storage.withLock { $0 = Array(array) }
    }

    public required convenience init(arrayLiteral elements: Any...) {
        self.init(array: elements)
    }

    public required convenience init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding,
              coder.containsValue(forKey: "NS.objects"),
              let values = coder.decodeObject(forKey: "NS.objects") as? [Any]
        else { return nil }
        self.init(array: values)
    }

    open var count: Int { storage.withLock { $0.count } }

    open func object(at index: Int) -> Any {
        storage.withLock { $0[index] }
    }

    open subscript(index: Int) -> Any { object(at: index) }

    open var allObjects: [Any] { storage.withLock { Array($0) } }

    public func makeIterator() -> IndexingIterator<[Any]> {
        allObjects.makeIterator()
    }

    open func contains(_ object: Any) -> Bool {
        storage.withLock { values in
            values.contains {
                _foundationReferenceObjectsEqual($0, object)
            }
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        if type(of: self) == NSArray.self { return self }
        return NSArray(array: allObjects)
    }

    open override func copy() -> Any { copy(with: nil) }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSMutableArray(array: allObjects)
    }

    open override func mutableCopy() -> Any { mutableCopy(with: nil) }

    open func encode(with coder: NSCoder) {
        guard coder.allowsKeyedCoding else { return }
        coder.encode(allObjects, forKey: "NS.objects")
    }

    open override func isEqual(_ object: Any?) -> Bool {
        let other: [Any]
        if let object = object as? NSArray {
            other = object.allObjects
        } else if let object = object as? [Any] {
            other = object
        } else {
            return false
        }
        let own = allObjects
        guard own.count == other.count else { return false }
        return zip(own, other).allSatisfy {
            _foundationReferenceObjectsEqual($0.0, $0.1)
        }
    }

    open override var hash: Int { count }
}

open class NSMutableArray: NSArray, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public init(capacity numItems: Int) {
        precondition(numItems >= 0, "NSMutableArray capacity must be nonnegative")
        super.init()
        storage.withLock { $0.reserveCapacity(numItems) }
    }

    public required init(objects: UnsafePointer<AnyObject>?, count: Int) {
        super.init(objects: objects, count: count)
    }

    public required convenience init(arrayLiteral elements: Any...) {
        self.init(array: elements)
    }

    public required convenience init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding,
              coder.containsValue(forKey: "NS.objects"),
              let values = coder.decodeObject(forKey: "NS.objects") as? [Any]
        else { return nil }
        self.init(array: values)
    }

    public convenience init(array: [Any]) {
        self.init()
        storage.withLock { $0 = Array(array) }
    }

    open func add(_ object: Any) {
        storage.withLock { $0.append(object) }
    }

    open func addObjects(from otherArray: [Any]) {
        storage.withLock { $0.append(contentsOf: otherArray) }
    }

    open func insert(_ object: Any, at index: Int) {
        storage.withLock { $0.insert(object, at: index) }
    }

    open func removeObject(at index: Int) {
        _ = storage.withLock { $0.remove(at: index) }
    }

    open func removeAllObjects() {
        storage.withLock { $0.removeAll(keepingCapacity: false) }
    }

    open func replaceObject(at index: Int, with object: Any) {
        storage.withLock { $0[index] = object }
    }

    open override subscript(index: Int) -> Any {
        get { object(at: index) }
        set { replaceObject(at: index, with: newValue) }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSArray(array: allObjects)
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSMutableArray(array: allObjects)
    }
}

extension Array: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectType = NSArray

    public func _bridgeToObjectiveC() -> NSArray {
        NSArray(array: map { $0 as Any })
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSArray,
        result: inout Array?
    ) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }

    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSArray,
        result: inout Array?
    ) -> Bool {
        var values: [Element] = []
        values.reserveCapacity(source.count)
        for object in source.allObjects {
            guard let element = object as? Element else { return false }
            values.append(element)
        }
        result = values
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSArray?
    ) -> Array {
        guard let source else { return [] }
        var result: Array?
        precondition(
            _conditionallyBridgeFromObjectiveC(source, result: &result),
            "NSArray contains an element of the wrong type"
        )
        return result!
    }
}

open class NSData: NSObject, NSCopying, NSMutableCopying, NSSecureCoding,
    RandomAccessCollection, @unchecked Sendable {
    public typealias Element = UInt8
    public typealias Index = Int

    fileprivate let storage: Mutex<Data>

    open class var supportsSecureCoding: Bool { true }

    public override init() {
        storage = Mutex(Data())
        super.init()
    }

    public init(bytes: UnsafeRawPointer?, length: Int) {
        precondition(length >= 0, "NSData length must be nonnegative")
        precondition(length == 0 || bytes != nil, "NSData bytes are missing")
        if let bytes {
            storage = Mutex(Data(bytes: bytes, count: length))
        } else {
            storage = Mutex(Data())
        }
        super.init()
    }

    public init(data: Data) {
        storage = Mutex(data)
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding,
              coder.containsValue(forKey: "NS.data")
        else { return nil }
        if let data = coder.decodeObject(forKey: "NS.data") as? Data {
            storage = Mutex(data)
        } else if let data = coder.decodeObject(forKey: "NS.data") as? NSData {
            storage = Mutex(Data(data))
        } else {
            return nil
        }
        super.init()
    }

    open var length: Int { storage.withLock { $0.count } }
    open var count: Int { length }
    public var startIndex: Int { 0 }
    public var endIndex: Int { length }

    open subscript(index: Int) -> UInt8 {
        storage.withLock { $0[index] }
    }

    public func index(after index: Int) -> Int { index + 1 }
    public func index(before index: Int) -> Int { index - 1 }

    open func getBytes(_ buffer: UnsafeMutableRawPointer, length: Int) {
        precondition(length >= 0 && length <= self.length, "NSData byte range")
        storage.withLock { data in
            data.copyBytes(
                to: buffer.assumingMemoryBound(to: UInt8.self),
                count: length
            )
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        if type(of: self) == NSData.self { return self }
        return NSData(data: Data(self))
    }

    open override func copy() -> Any { copy(with: nil) }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSMutableData(data: Data(self))
    }

    open override func mutableCopy() -> Any { mutableCopy(with: nil) }

    open func encode(with coder: NSCoder) {
        guard coder.allowsKeyedCoding else { return }
        coder.encode(Data(self), forKey: "NS.data")
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let data = object as? NSData { return Data(self) == Data(data) }
        if let data = object as? Data { return Data(self) == data }
        return false
    }

    open override var hash: Int { Data(self).hashValue }
}

open class NSMutableData: NSData, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public override init(data: Data) {
        super.init(data: data)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override var length: Int {
        get { super.length }
        set {
            precondition(newValue >= 0, "NSMutableData length must be nonnegative")
            storage.withLock { data in
                if newValue < data.count {
                    data.removeSubrange(newValue..<data.count)
                } else if newValue > data.count {
                    data.append(
                        contentsOf: repeatElement(
                            UInt8(0),
                            count: newValue - data.count
                        )
                    )
                }
            }
        }
    }

    open func append(_ bytes: UnsafeRawPointer, length: Int) {
        precondition(length >= 0, "NSMutableData append length")
        storage.withLock {
            $0.append(bytes.assumingMemoryBound(to: UInt8.self), count: length)
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSData(data: Data(self))
    }
}

extension Data: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectType = NSData

    public func _bridgeToObjectiveC() -> NSData { NSData(data: self) }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSData,
        result: inout Data?
    ) {
        result = Data(source)
    }

    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSData,
        result: inout Data?
    ) -> Bool {
        result = Data(source)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSData?
    ) -> Data {
        source.map { Data($0) } ?? Data()
    }
}


extension Dictionary: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectType = NSDictionary
    public func _bridgeToObjectiveC() -> NSDictionary {
        NSDictionary(dictionary: reduce(into: [AnyHashable: Any]()) { $0[$1.key] = $1.value })
    }
    public static func _forceBridgeFromObjectiveC(_ source: NSDictionary, result: inout Dictionary?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSDictionary, result: inout Dictionary?) -> Bool {
        var values: Dictionary = [:]
        for rawKey in source.allKeys {
            guard let key = rawKey as? Key, let value = source.object(forKey: rawKey) as? Value else { return false }
            values[key] = value
        }
        result = values
        return true
    }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDictionary?) -> Dictionary {
        guard let source else { return [:] }
        var result: Dictionary?
        precondition(_conditionallyBridgeFromObjectiveC(source, result: &result), "NSDictionary key/value type mismatch")
        return result!
    }
}
