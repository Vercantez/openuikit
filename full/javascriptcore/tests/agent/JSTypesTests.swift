import Foundation
import JavaScriptCore

enum JavaScriptCoreRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw JavaScriptCoreRuntimeFailure.message(message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw JavaScriptCoreRuntimeFailure.message("\(message): \(actual) != \(expected)")
    }
}

func jscIndexOfProbe(_ haystack: String, _ needle: String) -> Int? {
    let hay = Array(haystack)
    let need = Array(needle)
    if need.isEmpty { return 0 }
    if need.count > hay.count { return nil }
    for index in 0...(hay.count - need.count) {
        var matched = true
        for offset in 0..<need.count {
            if hay[index + offset] != need[offset] {
                matched = false
                break
            }
        }
        if matched { return index }
    }
    return nil
}

var jsClassInitCount: Int32 = 0
var jsClassFinalizeCount: Int32 = 0
var jsClassConverted = false

func testJSTypeConstants() throws {
    try expectEqual(kJSTypeUndefined.rawValue, 0, "kJSTypeUndefined")
    try expectEqual(kJSTypeNull.rawValue, 1, "kJSTypeNull")
    try expectEqual(kJSTypeBoolean.rawValue, 2, "kJSTypeBoolean")
    try expectEqual(kJSTypeNumber.rawValue, 3, "kJSTypeNumber")
    try expectEqual(kJSTypeString.rawValue, 4, "kJSTypeString")
    try expectEqual(kJSTypeObject.rawValue, 5, "kJSTypeObject")
    try expectEqual(kJSTypeSymbol.rawValue, 6, "kJSTypeSymbol")
    try expectEqual(kJSTypeBigInt.rawValue, 7, "kJSTypeBigInt")
    try expect(kJSTypeUndefined != kJSTypeNull, "JSType !=")
    try expect(JSType(rawValue: 3) == kJSTypeNumber, "JSType rawValue init")
    try expect(JSType(3) == kJSTypeNumber, "JSType unlabeled init")
    try expectEqual(kJSTypeNumber.rawValue, 3, "JSType.rawValue")
    var hasher = Hasher()
    kJSTypeNumber.hash(into: &hasher)
    _ = hasher.finalize()
    _ = kJSTypeNumber.hashValue
    try expectEqual(JSC_OBJC_API_ENABLED, Int32(1), "objc overlay enabled")
    let _: JSType = kJSTypeUndefined
}

func testJSTypedArrayTypeConstants() throws {
    try expectEqual(kJSTypedArrayTypeNone.rawValue, 0, "typed none")
    try expectEqual(kJSTypedArrayTypeInt8Array.rawValue, 1, "int8")
    try expectEqual(kJSTypedArrayTypeInt16Array.rawValue, 2, "int16")
    try expectEqual(kJSTypedArrayTypeInt32Array.rawValue, 3, "int32")
    try expectEqual(kJSTypedArrayTypeUint8Array.rawValue, 4, "uint8")
    try expectEqual(kJSTypedArrayTypeUint8ClampedArray.rawValue, 5, "uint8clamped")
    try expectEqual(kJSTypedArrayTypeUint16Array.rawValue, 6, "uint16")
    try expectEqual(kJSTypedArrayTypeUint32Array.rawValue, 7, "uint32")
    try expectEqual(kJSTypedArrayTypeFloat32Array.rawValue, 8, "float32")
    try expectEqual(kJSTypedArrayTypeFloat64Array.rawValue, 9, "float64")
    try expectEqual(kJSTypedArrayTypeArrayBuffer.rawValue, 10, "arraybuffer")
    try expectEqual(kJSTypedArrayTypeBigInt64Array.rawValue, 11, "bigint64")
    try expectEqual(kJSTypedArrayTypeBigUint64Array.rawValue, 12, "biguint64")
    try expect(kJSTypedArrayTypeFloat32Array != kJSTypedArrayTypeNone, "typed !=")
    try expect(JSTypedArrayType(rawValue: 8) == kJSTypedArrayTypeFloat32Array, "typed rawValue init")
    try expect(JSTypedArrayType(4) == kJSTypedArrayTypeUint8Array, "typed unlabeled init")
    try expectEqual(kJSTypedArrayTypeUint8Array.rawValue, 4, "typed.rawValue")
    var hasher = Hasher()
    kJSTypedArrayTypeInt8Array.hash(into: &hasher)
    _ = hasher.finalize()
    _ = kJSTypedArrayTypeInt8Array.hashValue
    let _: JSTypedArrayType = kJSTypedArrayTypeNone
}

func testJSRelationCondition() throws {
    try expectEqual(JSRelationCondition.undefined.rawValue, 0, "rel undefined")
    try expectEqual(JSRelationCondition.equal.rawValue, 1, "rel equal")
    try expectEqual(JSRelationCondition.greaterThan.rawValue, 2, "rel greater")
    try expectEqual(JSRelationCondition.lessThan.rawValue, 3, "rel less")
    try expect(JSRelationCondition(rawValue: 3) == .lessThan, "rel rawValue init")
    try expect(JSRelationCondition.lessThan != JSRelationCondition.equal, "rel !=")
    var hasher = Hasher()
    JSRelationCondition.equal.hash(into: &hasher)
    _ = hasher.finalize()
    _ = JSRelationCondition.equal.hashValue
    let _: JSRelationCondition = .undefined
}

func testJSPropertyAttributes() throws {
    try expectEqual(kJSPropertyAttributeNone, 0, "attr none")
    try expectEqual(kJSPropertyAttributeReadOnly, 2, "readonly")
    try expectEqual(kJSPropertyAttributeDontEnum, 4, "dontenum")
    try expectEqual(kJSPropertyAttributeDontDelete, 8, "dontdelete")
    let propAttrs: JSPropertyAttributes = JSPropertyAttributes(kJSPropertyAttributeReadOnly)
    try expect(propAttrs != 0, "JSPropertyAttributes")
}

func testJSClassAttributes() throws {
    try expectEqual(kJSClassAttributeNone, 0, "class none")
    try expectEqual(kJSClassAttributeNoAutomaticPrototype, 2, "no auto proto")
    let classAttrs: JSClassAttributes = JSClassAttributes(kJSClassAttributeNone)
    try expect(classAttrs == 0, "JSClassAttributes")
}
