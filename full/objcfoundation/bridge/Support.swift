// FoundationObjCBridge: the Objective-C face of the guest's one Foundation.
//
// The Swift facade (module Foundation, full/foundation) owns NSString,
// NSArray, NSDictionary, NSNumber, NSData, NSError, NSNull, NSValue and NSLock.
// This module gives those classes the Objective-C selectors the iOS SDK
// declares (full/objcfoundation/include/Foundation), and adds, as Swift
// classes, the ones the facade does not have (NSMutableString, NSSet,
// NSMutableSet, NSEnumerator, NSDate, NSLocale, NSTimeZone, NSDateFormatter,
// NSAssertionHandler). Its C/Objective-C companion (../src) supplies what
// Swift cannot: variadic methods, the %@ formatter, NSLog, exported constants
// and the constant-string fix-up.
//
// It is linked only into executables that contain Objective-C; render_full and
// the Focus guest never load it.

import Foundation
import ObjectiveC

// MARK: - Boxing between facade storage (Any) and Objective-C objects

/// The Objective-C object for a value held in a facade collection. Swift
/// values bridge through the facade's _ObjectiveCBridgeable conformances
/// (String -> NSString, Int -> NSNumber, ...); objects pass through.
@inline(__always)
func _ofBox(_ value: Any) -> AnyObject {
    value as AnyObject
}

/// Objective-C equality (-isEqual:), which every facade class overrides.
func _ofIsEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    let left = _ofBox(lhs)
    let right = _ofBox(rhs)
    if left === right { return true }
    guard let object = left as? NSObject else { return false }
    return object.isEqual(right)
}

// MARK: - Objective-C text of an object (-description, %@)

// -description through a typed objc_msgSend wrapper in ../src/OFFoundation.m.
@_silgen_name("OFSendObject")
private func _ofSendDescription(_ receiver: AnyObject, _ selector: Selector) -> Unmanaged<AnyObject>?

/// The text %@ prints for an object: its -description, as NSLog and
/// +stringWithFormat: use it.
func _ofDescription(_ object: AnyObject?) -> String {
    guard let object else { return "(null)" }
    if let string = object as? NSString { return String(string) }
    guard let text = _ofSendDescription(object, _ofDescriptionSelector)?.takeUnretainedValue() else {
        return "(null)"
    }
    if let string = text as? NSString { return String(string) }
    return "(null)"
}

private let _ofDescriptionSelector = Selector("description")

/// Apple's quoting of strings inside collection descriptions: bare when the
/// text is a plain identifier-like token, otherwise quoted.
func _ofQuotedIfNeeded(_ text: String) -> String {
    let plain = !text.isEmpty && text.unicodeScalars.allSatisfy {
        ($0 >= "a" && $0 <= "z") || ($0 >= "A" && $0 <= "Z") || ($0 >= "0" && $0 <= "9")
            || $0 == "_" || $0 == "$" || $0 == "." || $0 == "/" || $0 == ":"
    }
    if plain { return text }
    var result = "\""
    for scalar in text.unicodeScalars {
        switch scalar {
        case "\"": result += "\\\""
        case "\\": result += "\\\\"
        case "\n": result += "\\n"
        case "\t": result += "\\t"
        default:
            if scalar.value < 0x80 {
                result.unicodeScalars.append(scalar)
            } else {
                for unit in String(scalar).utf16 {
                    result += "\\U" + String(unit, radix: 16).leftPadded(to: 4)
                }
            }
        }
    }
    return result + "\""
}

extension String {
    func leftPadded(to width: Int, with pad: Character = "0") -> String {
        count >= width ? self : String(repeating: pad, count: width - count) + self
    }
}

/// -descriptionWithLocale:indent: for the collection classes, as Apple lays it
/// out: four spaces per level, nested collections opening at their own level.
func _ofCollectionDescription(_ object: AnyObject, level: Int) -> String {
    let pad = String(repeating: "    ", count: level)
    let inner = String(repeating: "    ", count: level + 1)
    func element(_ value: AnyObject) -> String {
        if value is NSArray || value is NSDictionary || value is NSSet {
            return _ofCollectionDescription(value, level: level + 1)
        }
        if let string = value as? NSString { return _ofQuotedIfNeeded(String(string)) }
        return _ofDescription(value)
    }
    if let array = object as? NSArray {
        let items = array.allObjects.map { inner + element(_ofBox($0)) }
        if items.isEmpty { return pad + "(\n" + pad + ")" }
        return (level == 0 ? "" : pad) + "(\n" + items.joined(separator: ",\n") + "\n" + pad + ")"
    }
    if let set = object as? NSSet {
        let items = set._of_objects.map { inner + element($0) }
        if items.isEmpty { return pad + "{(\n" + pad + ")}" }
        return (level == 0 ? "" : pad) + "{(\n" + items.joined(separator: ",\n") + "\n" + pad + ")}"
    }
    if let dictionary = object as? NSDictionary {
        let pairs = dictionary.allKeys.map { key -> (String, String) in
            let keyText = element(_ofBox(key))
            let value = dictionary.object(forKey: key).map { element(_ofBox($0)) } ?? "(null)"
            return (keyText, value)
        }.sorted { $0.0 < $1.0 }
        let lines = pairs.map { inner + $0.0 + " = " + $0.1 + ";" }
        if lines.isEmpty { return pad + "{\n" + pad + "}" }
        return (level == 0 ? "" : pad) + "{\n" + lines.joined(separator: "\n") + "\n" + pad + "}"
    }
    return _ofDescription(object)
}

// MARK: - Associated storage

/// A retained reference cell for objc_setAssociatedObject.
final class _OFBox<Value>: NSObject {
    var value: Value
    init(_ value: Value) { self.value = value; super.init() }
}

func _ofAssociated<Value>(_ object: AnyObject, _ key: UnsafeRawPointer) -> Value? {
    (objc_getAssociatedObject(object, key) as? _OFBox<Value>)?.value
}

func _ofAssociate<Value>(_ object: AnyObject, _ key: UnsafeRawPointer, _ value: Value) {
    objc_setAssociatedObject(object, key, _OFBox(value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

/// Stable addresses for association keys.
enum _OFKeys {
    static let numberType = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    static let dataBytes = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    static let enumeration = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    static let cString = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
}

// MARK: - Fast enumeration

/// Backing store for one countByEnumeratingWithState:objects:count: pass: the
/// boxed elements stay retained by the enumerated object until the next pass.
final class _OFEnumerationItems: NSObject {
    let items: UnsafeMutablePointer<Unmanaged<AnyObject>?>
    let count: Int
    init(_ objects: [AnyObject]) {
        count = objects.count
        items = .allocate(capacity: max(count, 1))
        for (index, object) in objects.enumerated() {
            items[index] = Unmanaged.passRetained(object)
        }
        super.init()
    }
    deinit {
        for index in 0..<count { items[index]?.release() }
        items.deallocate()
    }
}

private let _ofMutationsWord: UnsafeMutablePointer<UInt> = {
    let word = UnsafeMutablePointer<UInt>.allocate(capacity: 1)
    word.initialize(to: 0)
    return word
}()

/// One whole-collection pass: state 0 hands out every element, then 0.
func _ofFastEnumerate(
    _ owner: AnyObject,
    _ state: UnsafeMutableRawPointer,
    _ objects: () -> [AnyObject]
) -> Int {
    // NSFastEnumerationState { unsigned long state; id *itemsPtr;
    //                          unsigned long *mutationsPtr; unsigned long extra[5]; }
    if state.load(as: UInt.self) != 0 { return 0 }
    let items = _OFEnumerationItems(objects())
    objc_setAssociatedObject(owner, _OFKeys.enumeration, items, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    state.storeBytes(of: 1, as: UInt.self)
    state.storeBytes(of: UnsafeMutableRawPointer(items.items), toByteOffset: 8, as: UnsafeMutableRawPointer.self)
    state.storeBytes(of: UnsafeMutableRawPointer(_ofMutationsWord), toByteOffset: 16, as: UnsafeMutableRawPointer.self)
    return items.count
}

// MARK: - Swift entry points the C/Objective-C half calls

/// An autoreleased-by-caller NSString from UTF-8 bytes (the formatter's output).
@_cdecl("OFStringFromUTF8")
public func OFStringFromUTF8(_ bytes: UnsafePointer<CChar>, _ length: Int) -> Unmanaged<NSString> {
    let buffer = UnsafeBufferPointer(start: UnsafeRawPointer(bytes).assumingMemoryBound(to: UInt8.self), count: length)
    return Unmanaged.passRetained(NSString(string: String(decoding: buffer, as: UTF8.self)))
}

/// The %@ text of an object, as UTF-8 the caller frees.
@_cdecl("OFCopyDescriptionUTF8")
public func OFCopyDescriptionUTF8(_ object: AnyObject?) -> UnsafeMutablePointer<CChar> {
    strdup(_ofDescription(object))!
}
