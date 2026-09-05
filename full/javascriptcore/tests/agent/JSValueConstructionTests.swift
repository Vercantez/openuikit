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

func testJSValueConstruction() throws {
    let context = JSContext()
    try expect(JSValue(bool: true, in: context).isBoolean, "bool value")
    try expect(JSValue(bool: false, inContext: context).isBoolean, "bool inContext")
    try expect(JSValue(double: 1.5, in: context).isNumber, "double value")
    try expect(JSValue(double: 1.5, inContext: context).isNumber, "double inContext")
    try expect(JSValue(int32: 3, in: context).toInt32() == 3, "int32")
    try expect(JSValue(int32: 3, inContext: context).toInt32() == 3, "int32 inContext")
    try expect(JSValue(uInt32: 4, in: context).toUInt32() == 4, "uint32")
    try expect(JSValue(UInt32: 4, inContext: context).toUInt32() == 4, "UInt32 inContext")
    try expect(JSValue(undefinedIn: context).isUndefined, "undefined")
    try expect(JSValue(undefinedInContext: context).isUndefined, "undefined inContext")
    try expect(JSValue(nullIn: context).isNull, "null")
    try expect(JSValue(nullInContext: context).isNull, "null inContext")
    try expect(JSValue(newObjectIn: context).isObject, "new object")
    try expect(JSValue(newObjectInContext: context).isObject, "new object inContext")
    try expect(JSValue(newArrayIn: context).isArray, "new array")
    try expect(JSValue(newArrayInContext: context).isArray, "new array inContext")
    try expect(JSValue(object: "hi", in: context).isString, "object string")
    try expect(JSValue(object: "hi", inContext: context).isString, "object inContext")
    try expect(JSValue(newErrorFromMessage: "boom", in: context).isObject, "error")
    try expect(JSValue(newErrorFromMessage: "boom", inContext: context).isObject, "error inContext")
    try expect(jscIndexOfProbe(JSValue(newRegularExpressionFromPattern: "a+", flags: "g", in: context).toString(), "a+") != nil, "regexp")
    try expect(jscIndexOfProbe(JSValue(newRegularExpressionFromPattern: "a+", flags: "g", inContext: context).toString(), "a+") != nil, "regexp inContext")
    try expect(JSValue(newSymbolFromDescription: "s", in: context).isSymbol, "symbol")
    try expect(JSValue(newSymbolFromDescription: "s", inContext: context).isSymbol, "symbol inContext")
    try expect(JSValue(newBigIntFrom: Int64(99), in: context)?.isBigInt == true, "bigint int64")
    try expect(JSValue(newBigIntFromInt64: 99, inContext: context)?.isBigInt == true, "bigint int64 inContext")
    try expect(JSValue(newBigIntFrom: 8.0, in: context)?.isBigInt == true, "bigint double")
    try expect(JSValue(newBigIntFromDouble: 8.0, inContext: context)?.isBigInt == true, "bigint double inContext")
    try expect(JSValue(newBigIntFrom: "77", in: context)?.isBigInt == true, "bigint string")
    try expect(JSValue(newBigIntFromString: "77", inContext: context)?.isBigInt == true, "bigint string inContext")
    try expect(JSValue(newBigIntFrom: UInt64(5), in: context)?.isBigInt == true, "bigint uint64")
    try expect(JSValue(newBigIntFromUInt64: 5, inContext: context)?.isBigInt == true, "bigint uint64 inContext")
    try expect(JSValue(point: CGPoint(x: 1, y: 2), inContext: context).toPoint().x == 1, "point")
    try expect(JSValue(size: CGSize(width: 3, height: 4), inContext: context).toSize().width == 3, "size")
    try expect(JSValue(rect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 5, height: 6)), inContext: context).toRect().size.width == 5, "rect")
    try expect(JSValue(range: NSRange(location: 1, length: 2), inContext: context).toRange().location == 1, "range")
    let value = JSValue(bool: true, in: context)!
    let fromRef = JSValue(JSValueRef: value.jsValueRef, inContext: context)!
    try expect(fromRef.isBoolean, "from ref")
    let promise = JSValue(newPromiseIn: context, fromExecutor: { resolve, _ in
        _ = resolve?.call(withArguments: [1])
    })!
    try expect(promise.isObject, "promise executor sync; no microtask queue")
    try expect(JSValue(newPromiseInContext: context, fromExecutor: { _, _ in }).isObject, "promise inContext")
    try expect(JSValue(newPromiseResolvedWithResult: 1, in: context).isObject, "resolved")
    try expect(JSValue(newPromiseResolvedWithResult: 1, inContext: context).isObject, "resolved inContext")
    try expect(JSValue(newPromiseRejectedWithReason: "x", in: context).isObject, "rejected")
    try expect(JSValue(newPromiseRejectedWithReason: "x", inContext: context).isObject, "rejected inContext")
}

func testJSValueToCoercions() throws {
    let context = JSContext()
    let number = JSValue(double: 42, in: context)!
    try expectEqual(number.toBool(), true, "toBool")
    try expectEqual(number.toDouble(), 42, "toDouble")
    try expectEqual(number.toInt32(), 42, "toInt32")
    try expectEqual(number.toUInt32(), 42, "toUInt32")
    try expectEqual(number.toInt64(), 42, "toInt64")
    try expectEqual(number.toUInt64(), 42, "toUInt64")
    try expectEqual(number.toNumber().intValue, 42, "toNumber")
    try expectEqual(number.toString(), "42", "toString")
    try expect(JSValue(bool: false, in: context).toBool() == false, "false toBool")
    try expectEqual(JSValue(undefinedIn: context).toBool(), false, "undefined toBool")
    try expect(JSValue(undefinedIn: context).toObject() == nil, "undefined toObject nil")
    try expect(JSValue(nullIn: context).toObject() == nil, "null toObject nil")
    try expect(JSValue(object: "hi", in: context).toObjectOf(NSString.self) != nil, "toObjectOf NSString")
    try expect(JSValue(object: "hi", in: context).toObjectOf(NSNumber.self) == nil, "toObjectOf mismatch")
    let dateValue = JSValue(object: Date(timeIntervalSince1970: 1), in: context)!
    try expect(dateValue.toDate() != nil, "toDate")
    try expectEqual(dateValue.toInt64(), 1000, "date ToNumber ms")
    try expectEqual(JSValue(point: CGPoint(x: 1, y: 2), inContext: context).toPoint().x, 1, "toPoint")
    try expectEqual(JSValue(size: CGSize(width: 3, height: 4), inContext: context).toSize().width, 3, "toSize")
    try expectEqual(JSValue(rect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 5, height: 6)), inContext: context).toRect().size.width, 5, "toRect")
    try expectEqual(JSValue(range: NSRange(location: 1, length: 2), inContext: context).toRange().location, 1, "toRange")
    let array = context.evaluateScript("[10, 20]")!
    try expectEqual(array.toArray()?.count, 2, "toArray")
    let dictValue = context.evaluateScript("({k:1, z:2})")!
    try expectEqual(dictValue.toDictionary()?.count, 2, "toDictionary")
    try expect(number.toObject() is NSNumber, "number toObject")
}

func testJSValueTypeQueries() throws {
    let context = JSContext()
    try expect(JSValue(undefinedIn: context).isUndefined, "isUndefined")
    try expect(JSValue(nullIn: context).isNull, "isNull")
    try expect(JSValue(bool: true, in: context).isBoolean, "isBoolean")
    try expect(JSValue(double: 1, in: context).isNumber, "isNumber")
    try expect(JSValue(object: "s", in: context).isString, "isString")
    try expect(JSValue(newObjectIn: context).isObject, "isObject")
    try expect(JSValue(newArrayIn: context).isArray, "isArray")
    try expect(JSValue(object: Date(), in: context).isDate, "isDate")
    try expect(JSValue(newSymbolFromDescription: "s", in: context).isSymbol, "isSymbol")
    try expect(JSValue(newBigIntFrom: Int64(1), in: context)?.isBigInt == true, "isBigInt")
    let value = JSValue(bool: true, in: context)!
    try expect(value.context === context, "JSValue.context")
    try expect(value.jsValueRef != nil, "jsValueRef")
    try expect(value.isDate == false, "bool is not date")
}

func testJSValueCompare() throws {
    let context = JSContext()
    let sum = JSValue(double: 42, in: context)!
    try expect(sum.compare(40.0) == .greaterThan, "compare double")
    try expect(sum.compare(Int64(42)) == .equal, "compare int64")
    try expect(sum.compare(UInt64(42)) == .equal, "compare uint64")
    let left = JSValue(double: 3, in: context)!
    let right = JSValue(double: 9, in: context)!
    try expect(left.compare(right) == .lessThan, "compare JSValue lessThan")
    try expect(!left.isEqual(to: right), "isEqual to")
    try expect(JSValue(object: "12", in: context).isEqualWithTypeCoercion(to: 12), "coercion equal")
    let ctor = context.evaluateScript("function Box(v){ this.v = v } Box")!
    let instance = ctor.construct(withArguments: [1])!
    try expect(instance.isInstance(of: ctor), "isInstanceOf")
}
