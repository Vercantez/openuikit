// Objective-C selectors of the facade's NSArray / NSDictionary, and the
// set and enumerator classes the facade does not have.

import Foundation
import ObjectiveC

private func _ofIndexOf(_ values: [Any], _ object: AnyObject) -> Int {
    values.firstIndex { _ofIsEqual($0, object) } ?? Int.max
}

public typealias _OFComparator = @convention(block) (AnyObject, AnyObject) -> Int

// Typed objc_msgSend wrappers live in ../src/OFFoundation.m.
@_silgen_name("OFSendCompare")
private func _ofSendCompare(_ receiver: AnyObject, _ selector: Selector, _ other: AnyObject) -> Int

@_silgen_name("OFSendVoid")
private func _ofSendVoid(_ receiver: AnyObject, _ selector: Selector)

@_silgen_name("OFSendVoidWith")
private func _ofSendVoidWith(_ receiver: AnyObject, _ selector: Selector, _ argument: AnyObject?)

/// Stable merge sort by an Objective-C comparison selector (-compare:).
func _ofSorted(_ objects: [AnyObject], by selector: Selector) -> [AnyObject] {
    _ofSorted(objects) { _ofSendCompare($0, selector, $1) }
}

func _ofSorted(_ objects: [AnyObject], by compare: (AnyObject, AnyObject) -> Int) -> [AnyObject] {
    var items = objects
    // insertion into a stable order; collections here are small
    if items.count < 2 { return items }
    var sorted: [AnyObject] = []
    sorted.reserveCapacity(items.count)
    for item in items {
        var index = sorted.count
        while index > 0 && compare(sorted[index - 1], item) > 0 { index -= 1 }
        sorted.insert(item, at: index)
    }
    items = sorted
    return items
}

// MARK: - NSArray

extension NSArray {
    var _of_objects: [AnyObject] { allObjects.map(_ofBox) }

    @objc(count) public var _of_count: Int { count }
    @objc(objectAtIndex:) public func _of_objectAtIndex(_ index: Int) -> AnyObject {
        precondition(index >= 0 && index < count,
                     "*** -[NSArray objectAtIndex:]: index \(index) beyond bounds [0 .. \(count - 1)]")
        return _ofBox(object(at: index))
    }
    @objc(objectAtIndexedSubscript:) public func _of_objectAtIndexedSubscript(_ index: Int) -> AnyObject {
        _of_objectAtIndex(index)
    }
    @objc(firstObject) public var _of_firstObject: AnyObject? { count == 0 ? nil : _ofBox(object(at: 0)) }
    @objc(lastObject) public var _of_lastObject: AnyObject? { count == 0 ? nil : _ofBox(object(at: count - 1)) }
    @objc(containsObject:) public func _of_containsObject(_ object: AnyObject) -> Bool {
        _ofIndexOf(allObjects, object) != Int.max
    }
    @objc(indexOfObject:) public func _of_indexOfObject(_ object: AnyObject) -> Int { _ofIndexOf(allObjects, object) }
    @objc(indexOfObjectIdenticalTo:) public func _of_indexOfObjectIdenticalTo(_ object: AnyObject) -> Int {
        _of_objects.firstIndex { $0 === object } ?? Int.max
    }
    @objc(isEqualToArray:) public func _of_isEqualToArray(_ other: NSArray) -> Bool {
        let mine = allObjects, theirs = other.allObjects
        return mine.count == theirs.count && zip(mine, theirs).allSatisfy { _ofIsEqual($0, $1) }
    }
    @objc(arrayByAddingObject:) public func _of_arrayByAdding(_ object: AnyObject) -> NSArray {
        NSArray(array: allObjects + [object])
    }
    @objc(arrayByAddingObjectsFromArray:) public func _of_arrayByAddingArray(_ other: NSArray) -> NSArray {
        NSArray(array: allObjects + other.allObjects)
    }
    @objc(componentsJoinedByString:) public func _of_componentsJoined(_ separator: NSString) -> NSString {
        NSString(string: _of_objects.map { _ofDescription($0) }.joined(separator: separator._of_string))
    }
    @objc(description) public var _of_description: NSString { NSString(string: _ofCollectionDescription(self, level: 0)) }
    @objc(objectEnumerator) public func _of_objectEnumerator() -> NSEnumerator { NSEnumerator(_of_objects) }
    @objc(reverseObjectEnumerator) public func _of_reverseObjectEnumerator() -> NSEnumerator {
        NSEnumerator(_of_objects.reversed())
    }
    @objc(sortedArrayUsingSelector:) public func _of_sorted(using selector: Selector) -> NSArray {
        NSArray(array: _ofSorted(_of_objects, by: selector))
    }
    @objc(sortedArrayUsingComparator:) public func _of_sorted(comparator: _OFComparator) -> NSArray {
        NSArray(array: _ofSorted(_of_objects) { comparator($0, $1) })
    }
    @objc(_of_subarrayWithLocation:length:) public func _of_subarray(location: Int, length: Int) -> NSArray {
        let values = allObjects
        precondition(location >= 0 && length >= 0 && location + length <= values.count, "NSArray subarrayWithRange: out of bounds")
        return NSArray(array: Array(values[location..<(location + length)]))
    }
    @objc(makeObjectsPerformSelector:) public func _of_makeObjectsPerform(_ selector: Selector) {
        for object in _of_objects { _ofSendVoid(object, selector) }
    }
    @objc(makeObjectsPerformSelector:withObject:) public func _of_makeObjectsPerform(_ selector: Selector, with argument: AnyObject?) {
        for object in _of_objects { _ofSendVoidWith(object, selector, argument) }
    }
    @objc(enumerateObjectsUsingBlock:)
    public func _of_enumerateObjects(_ block: @convention(block) (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop: ObjCBool = false
        for (index, object) in _of_objects.enumerated() {
            block(object, index, &stop)
            if stop.boolValue { break }
        }
    }
    @objc(countByEnumeratingWithState:objects:count:)
    public func _of_countByEnumerating(_ state: UnsafeMutableRawPointer, objects: UnsafeMutableRawPointer?, count: Int) -> Int {
        _ofFastEnumerate(self, state) { _of_objects }
    }
    @objc(initWithArray:) public convenience init(_of_array other: NSArray) {
        self.init(array: other.allObjects)
    }
    @objc(initWithObjects:count:) public convenience init(_of_objects objects: UnsafePointer<AnyObject>?, count: Int) {
        self.init(objects: objects, count: count)
    }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { copy() as AnyObject }
    @objc(mutableCopyWithZone:) public func _of_mutableCopyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        mutableCopy() as AnyObject
    }
}

extension NSMutableArray {
    @objc(initWithCapacity:) public convenience init(_of_capacity capacity: Int) {
        self.init(capacity: capacity)
    }
    @objc(addObject:) public func _of_add(_ object: AnyObject) { add(object) }
    @objc(insertObject:atIndex:) public func _of_insert(_ object: AnyObject, at index: Int) {
        precondition(index >= 0 && index <= count, "*** -[NSMutableArray insertObject:atIndex:]: index \(index) beyond bounds")
        insert(object, at: index)
    }
    @objc(removeLastObject) public func _of_removeLastObject() {
        if count > 0 { removeObject(at: count - 1) }
    }
    @objc(removeObjectAtIndex:) public func _of_removeObjectAtIndex(_ index: Int) {
        precondition(index >= 0 && index < count, "*** -[NSMutableArray removeObjectAtIndex:]: index \(index) beyond bounds")
        removeObject(at: index)
    }
    @objc(replaceObjectAtIndex:withObject:) public func _of_replace(at index: Int, with object: AnyObject) {
        precondition(index >= 0 && index < count, "*** -[NSMutableArray replaceObjectAtIndex:withObject:]: index \(index) beyond bounds")
        replaceObject(at: index, with: object)
    }
    @objc(setObject:atIndexedSubscript:) public func _of_setObject(_ object: AnyObject, atIndexedSubscript index: Int) {
        if index == count { add(object) } else { _of_replace(at: index, with: object) }
    }
    @objc(addObjectsFromArray:) public func _of_addObjects(from other: NSArray) { addObjects(from: other.allObjects) }
    @objc(removeAllObjects) public func _of_removeAllObjects() { removeAllObjects() }
    @objc(removeObject:) public func _of_removeObject(_ object: AnyObject) {
        var index = count - 1
        while index >= 0 {
            if _ofIsEqual(self.object(at: index), object) { removeObject(at: index) }
            index -= 1
        }
    }
    @objc(removeObjectIdenticalTo:) public func _of_removeObjectIdenticalTo(_ object: AnyObject) {
        var index = count - 1
        while index >= 0 {
            if _ofBox(self.object(at: index)) === object { removeObject(at: index) }
            index -= 1
        }
    }
    private func _of_replaceAll(with objects: [AnyObject]) {
        removeAllObjects()
        addObjects(from: objects)
    }
    @objc(sortUsingSelector:) public func _of_sort(using selector: Selector) {
        _of_replaceAll(with: _ofSorted(_of_objects, by: selector))
    }
    @objc(sortUsingComparator:) public func _of_sort(comparator: _OFComparator) {
        _of_replaceAll(with: _ofSorted(_of_objects) { comparator($0, $1) })
    }
}

// MARK: - NSDictionary

/// Keys as Objective-C objects; the facade keeps whatever Swift stored.
extension NSDictionary {
    var _of_keys: [AnyObject] { allKeys.map(_ofBox) }

    @objc(count) public var _of_count: Int { count }
    @objc(objectForKey:) public func _of_objectForKey(_ key: AnyObject) -> AnyObject? {
        object(forKey: key).map(_ofBox)
    }
    /// Replaces, for Objective-C callers, the facade's own
    /// `@objc subscript(key: String)`: its thunk bridges every key as an
    /// NSString, so NetNewsWire's `cache[@(n)]` (an NSNumber key) read an
    /// NSNumber as a string and crashed (measured). Category methods win over
    /// the class's at run time; Swift callers keep the facade's subscript.
    @objc(objectForKeyedSubscript:) public func _of_objectForKeyedSubscript(_ key: AnyObject) -> AnyObject? {
        object(forKey: key).map(_ofBox)
    }
    @objc(valueForKey:) public func _of_valueForKey(_ key: NSString) -> AnyObject? {
        object(forKey: key).map(_ofBox)
    }
    @objc(allKeys) public var _of_allKeys: NSArray { NSArray(array: _of_keys) }
    @objc(allValues) public var _of_allValues: NSArray { NSArray(array: allValues.map(_ofBox)) }
    @objc(keyEnumerator) public func _of_keyEnumerator() -> NSEnumerator { NSEnumerator(_of_keys) }
    @objc(objectEnumerator) public func _of_objectEnumerator() -> NSEnumerator { NSEnumerator(allValues.map(_ofBox)) }
    @objc(description) public var _of_description: NSString { NSString(string: _ofCollectionDescription(self, level: 0)) }
    @objc(isEqualToDictionary:) public func _of_isEqualToDictionary(_ other: NSDictionary) -> Bool {
        guard count == other.count else { return false }
        for key in allKeys {
            guard let mine = object(forKey: key), let theirs = other.object(forKey: key), _ofIsEqual(mine, theirs) else {
                return false
            }
        }
        return true
    }
    @objc(objectsForKeys:notFoundMarker:) public func _of_objects(forKeys keys: NSArray, notFoundMarker marker: AnyObject) -> NSArray {
        NSArray(array: keys.allObjects.map { object(forKey: $0).map(_ofBox) ?? marker })
    }
    @objc(enumerateKeysAndObjectsUsingBlock:)
    public func _of_enumerateKeysAndObjects(_ block: @convention(block) (AnyObject, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop: ObjCBool = false
        for key in allKeys {
            guard let value = object(forKey: key) else { continue }
            block(_ofBox(key), _ofBox(value), &stop)
            if stop.boolValue { break }
        }
    }
    @objc(countByEnumeratingWithState:objects:count:)
    public func _of_countByEnumerating(_ state: UnsafeMutableRawPointer, objects: UnsafeMutableRawPointer?, count: Int) -> Int {
        _ofFastEnumerate(self, state) { _of_keys }
    }
    @objc(initWithObjects:forKeys:count:)
    public convenience init(_of_objects objects: UnsafePointer<AnyObject>?, keys: UnsafePointer<AnyObject>?, count: Int) {
        var dictionary: [AnyHashable: Any] = [:]
        var order: [AnyHashable] = []
        for index in 0..<count {
            let key = _ofHashableKey(keys![index])
            if dictionary[key] == nil { order.append(key) }
            dictionary[key] = objects![index]
        }
        self.init(dictionary: dictionary)
    }
    @objc(initWithDictionary:) public convenience init(_of_dictionary other: NSDictionary) {
        var dictionary: [AnyHashable: Any] = [:]
        for key in other.allKeys { dictionary[_ofHashableKey(_ofBox(key))] = other.object(forKey: key) }
        self.init(dictionary: dictionary)
    }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { copy() as AnyObject }
    @objc(mutableCopyWithZone:) public func _of_mutableCopyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        let copy = NSMutableDictionary()
        for key in allKeys { if let value = object(forKey: key) { copy._of_setObject(_ofBox(value), forKey: _ofBox(key)) } }
        return copy
    }
}

/// A Swift key for an Objective-C key object: strings and numbers become the
/// values Swift code will look them up by, everything else hashes by
/// -hash / -isEqual:.
func _ofHashableKey(_ key: AnyObject) -> AnyHashable {
    if let string = key as? NSString { return AnyHashable(String(string)) }
    if let object = key as? NSObject { return AnyHashable(object) }
    return AnyHashable(ObjectIdentifier(key))
}

extension NSMutableDictionary {
    @objc(initWithCapacity:) public convenience init(_of_capacity capacity: Int) {
        self.init(capacity: capacity)
    }
    @objc(setObject:forKey:) public func _of_setObject(_ object: AnyObject, forKey key: AnyObject) {
        if let copying = key as? NSString {
            setObject(object, forKey: NSString(string: String(copying)))
        } else if let copying = key as? any NSCopying {
            setObject(object, forKey: copying)
        } else {
            setObject(object, forKey: _OFKeyCopy(key))
        }
    }
    @objc(setObject:forKeyedSubscript:) public func _of_setObject(_ object: AnyObject?, forKeyedSubscript key: AnyObject) {
        if let object { _of_setObject(object, forKey: key) } else { removeObject(forKey: key) }
    }
    @objc(setValue:forKey:) public func _of_setValue(_ value: AnyObject?, forKey key: NSString) {
        _of_setObject(value, forKeyedSubscript: key)
    }
    @objc(removeObjectForKey:) public func _of_removeObject(forKey key: AnyObject) { removeObject(forKey: key) }
    @objc(removeAllObjects) public func _of_removeAllObjects() { removeAllObjects() }
    @objc(removeObjectsForKeys:) public func _of_removeObjects(forKeys keys: NSArray) {
        for key in keys.allObjects { removeObject(forKey: key) }
    }
    @objc(addEntriesFromDictionary:) public func _of_addEntries(from other: NSDictionary) {
        for key in other.allKeys {
            if let value = other.object(forKey: key) { _of_setObject(_ofBox(value), forKey: _ofBox(key)) }
        }
    }
}

/// A key that is not NSCopying (an NSNumber, say) is stored as itself: the
/// facade's -setObject:forKey: wants its Swift NSCopying protocol, whose copy
/// of an immutable key is the key.
final class _OFKeyCopy: NSObject, NSCopying {
    let key: AnyObject
    init(_ key: AnyObject) { self.key = key; super.init() }
    func copy(with zone: NSZone? = nil) -> Any { key }
}

// MARK: - NSEnumerator

open class NSEnumerator: NSObject {
    private var remaining: [AnyObject]
    init(_ objects: [AnyObject]) {
        remaining = objects
        super.init()
    }
    @objc(nextObject) open func nextObject() -> AnyObject? {
        remaining.isEmpty ? nil : remaining.removeFirst()
    }
    @objc(allObjects) open var allObjects: NSArray {
        defer { remaining.removeAll() }
        return NSArray(array: remaining)
    }
    @objc(countByEnumeratingWithState:objects:count:)
    public func _of_countByEnumerating(_ state: UnsafeMutableRawPointer, objects: UnsafeMutableRawPointer?, count: Int) -> Int {
        _ofFastEnumerate(self, state) {
            defer { remaining.removeAll() }
            return remaining
        }
    }
}

// MARK: - NSSet / NSMutableSet

/// An unordered collection with -hash/-isEqual: membership, kept in insertion
/// order (Apple's order is its hash table's; nothing here promises one).
open class NSSet: NSObject, @unchecked Sendable {
    var _of_objects: [AnyObject]

    public override init() {
        _of_objects = []
        super.init()
    }

    public init(objects: [AnyObject]) {
        var unique: [AnyObject] = []
        for object in objects where !unique.contains(where: { _ofIsEqual($0, object) }) {
            unique.append(object)
        }
        _of_objects = unique
        super.init()
    }

    @objc(initWithArray:) public convenience init(_of_array array: NSArray) {
        self.init(objects: array._of_objects)
    }

    @objc(count) open var count: Int { _of_objects.count }
    @objc(member:) open func member(_ object: AnyObject) -> AnyObject? {
        _of_objects.first { _ofIsEqual($0, object) }
    }
    @objc(containsObject:) open func contains(_ object: AnyObject) -> Bool { member(object) != nil }
    @objc(anyObject) open func anyObject() -> AnyObject? { _of_objects.first }
    @objc(allObjects) open var allObjects: NSArray { NSArray(array: _of_objects) }
    @objc(objectEnumerator) open func objectEnumerator() -> NSEnumerator { NSEnumerator(_of_objects) }
    @objc(description) open var _of_description: NSString { NSString(string: _ofCollectionDescription(self, level: 0)) }
    @objc(isEqualToSet:) open func isEqual(to other: NSSet) -> Bool {
        count == other.count && _of_objects.allSatisfy { other.contains($0) }
    }
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSSet else { return false }
        return isEqual(to: other)
    }
    open override var hash: Int { count }
    @objc(setByAddingObject:) open func adding(_ object: AnyObject) -> NSSet {
        NSSet(objects: _of_objects + [object])
    }
    @objc(objectsPassingTest:)
    open func objects(passingTest predicate: @convention(block) (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSSet {
        var stop: ObjCBool = false
        var passing: [AnyObject] = []
        for object in _of_objects {
            if predicate(object, &stop) { passing.append(object) }
            if stop.boolValue { break }
        }
        return NSSet(objects: passing)
    }
    @objc(enumerateObjectsUsingBlock:)
    open func enumerateObjects(_ block: @convention(block) (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop: ObjCBool = false
        for object in _of_objects {
            block(object, &stop)
            if stop.boolValue { break }
        }
    }
    @objc(makeObjectsPerformSelector:) open func makeObjectsPerform(_ selector: Selector) {
        for object in _of_objects { _ofSendVoid(object, selector) }
    }
    @objc(countByEnumeratingWithState:objects:count:)
    public func _of_countByEnumerating(_ state: UnsafeMutableRawPointer, objects: UnsafeMutableRawPointer?, count: Int) -> Int {
        _ofFastEnumerate(self, state) { _of_objects }
    }
    @objc(copyWithZone:) open func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        type(of: self) == NSSet.self ? self : NSSet(objects: _of_objects)
    }
    @objc(mutableCopyWithZone:) open func _of_mutableCopyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        NSMutableSet(objects: _of_objects)
    }
}

open class NSMutableSet: NSSet, @unchecked Sendable {
    @objc(initWithCapacity:) public convenience init(capacity: Int) {
        _ = capacity
        self.init(objects: [])
    }
    @objc(addObject:) open func add(_ object: AnyObject) {
        if member(object) == nil { _of_objects.append(object) }
    }
    @objc(removeObject:) open func remove(_ object: AnyObject) {
        _of_objects.removeAll { _ofIsEqual($0, object) }
    }
    @objc(addObjectsFromArray:) open func addObjects(from array: NSArray) {
        for object in array._of_objects { add(object) }
    }
    @objc(unionSet:) open func union(_ other: NSSet) {
        for object in other._of_objects { add(object) }
    }
    @objc(removeAllObjects) open func removeAllObjects() { _of_objects.removeAll() }
}

extension Set: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSSet

    public func _bridgeToObjectiveC() -> NSSet {
        NSSet(objects: map { _ofBox($0) })
    }

    public static func _forceBridgeFromObjectiveC(_ source: NSSet, result: inout Set?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }

    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSSet, result: inout Set?) -> Bool {
        var values = Set()
        for object in source._of_objects {
            guard let element = (object as Any) as? Element else { return false }
            values.insert(element)
        }
        result = values
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSSet?) -> Set {
        guard let source else { return [] }
        var result: Set?
        precondition(_conditionallyBridgeFromObjectiveC(source, result: &result), "NSSet contains an element of the wrong type")
        return result!
    }
}

// MARK: - AnyHashable <-> NSObject

/// An untyped NSDictionary / NSSet (`NSDictionary *`) imports as
/// [AnyHashable: Any] / Set<AnyHashable>; Swift's IRGen needs AnyHashable's
/// Objective-C counterpart to lower such a call (without it swift-frontend
/// 6.2.4 crashes in clang::CodeGen::classifyReturnType, measured on FMDB's
/// -rs_insertRowWithDictionary:insertType:tableName:). NSObject, as in the SDK.
extension AnyHashable: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSObject

    public func _bridgeToObjectiveC() -> NSObject {
        guard let object = _ofBox(base) as? NSObject else {
            fatalError("FoundationObjCBridge: AnyHashable(\(type(of: base))) has no Objective-C object form")
        }
        return object
    }

    public static func _forceBridgeFromObjectiveC(_ source: NSObject, result: inout AnyHashable?) {
        result = _ofHashable(source)
    }

    public static func _conditionallyBridgeFromObjectiveC(_ source: NSObject, result: inout AnyHashable?) -> Bool {
        result = _ofHashable(source)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSObject?) -> AnyHashable {
        _ofHashable(source!)
    }
}

/// Objective-C strings hash and compare as the Swift Strings they bridge to,
/// so a key stored by Objective-C is found by a Swift String (the SDK's
/// _HasCustomAnyHashableRepresentation for NSString).
func _ofHashable(_ object: NSObject) -> AnyHashable {
    if let string = object as? NSString { return AnyHashable(String(string)) }
    return AnyHashable(object)
}

extension NSString: @retroactive _HasCustomAnyHashableRepresentation {
    public func _toCustomAnyHashable() -> AnyHashable? { AnyHashable(String(self)) }
}
