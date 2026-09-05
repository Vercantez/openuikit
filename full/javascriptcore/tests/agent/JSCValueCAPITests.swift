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

func testJSValueCAPI() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    let number = JSValueMakeNumber(ctx, 12)!
    try expect(JSValueIsNumber(ctx, number), "is number")
    try expectEqual(JSValueToNumber(ctx, number, nil), 12, "to number")
    try expectEqual(JSValueToInt32(ctx, number, nil), 12, "to int32")
    try expectEqual(JSValueToUInt32(ctx, number, nil), 12, "to uint32")
    try expectEqual(JSValueToInt64(ctx, number, nil), 12, "to int64")
    try expectEqual(JSValueToUInt64(ctx, number, nil), 12, "to uint64")
    try expect(JSValueIsBoolean(ctx, JSValueMakeBoolean(ctx, true)), "bool")
    try expect(JSValueIsString(ctx, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("s"))), "string")
    try expect(JSValueIsUndefined(ctx, JSValueMakeUndefined(ctx)), "undefined")
    try expect(JSValueIsNull(ctx, JSValueMakeNull(ctx)), "null")
    try expect(JSValueIsSymbol(ctx, JSValueMakeSymbol(ctx, JSStringCreateWithUTF8CString("sym"))), "symbol")
    try expect(JSValueGetType(ctx, number) == kJSTypeNumber, "get type")
    try expect(JSValueIsStrictEqual(ctx, number, JSValueMakeNumber(ctx, 12)), "strict eq")
    try expect(JSValueIsEqual(ctx, number, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("12")), nil), "abstract eq")
    let json = JSValueCreateJSONString(ctx, JSValueMakeFromJSONString(ctx, JSStringCreateWithUTF8CString("true")), 0, nil)!
    try expect(JSStringIsEqualToUTF8CString(json, "true"), "json string")
    let big = JSBigIntCreateWithInt64(ctx, 5, nil)
    try expect(JSValueIsBigInt(ctx, big), "bigint c")
    _ = JSBigIntCreateWithUInt64(ctx, 6, nil)
    _ = JSBigIntCreateWithDouble(ctx, 7, nil)
    _ = JSBigIntCreateWithString(ctx, JSStringCreateWithUTF8CString("8")!, nil)
    JSValueProtect(ctx, number)
    JSValueUnprotect(ctx, number)
    try expect(JSValueToBoolean(ctx, JSValueMakeBoolean(ctx, true)), "to bool")
    var exception: JSValueRef?
    try expect(JSValueToObject(ctx, JSValueMakeNumber(ctx, 1), &exception) != nil, "to object")
    try expect(JSValueCompare(ctx, JSValueMakeNumber(ctx, 1), JSValueMakeNumber(ctx, 2), nil) == .lessThan, "JSValueCompare")
    try expect(JSValueCompareDouble(ctx, JSValueMakeNumber(ctx, 3), 3, nil) == .equal, "compare double c")
    try expect(JSValueCompareInt64(ctx, JSValueMakeNumber(ctx, 3), 4, nil) == .lessThan, "compare int64 c")
    try expect(JSValueCompareUInt64(ctx, JSValueMakeNumber(ctx, 5), 4, nil) == .greaterThan, "compare uint64 c")
    let _: JSValueRef = number
    let _: JSValueProperty? = nil
}
