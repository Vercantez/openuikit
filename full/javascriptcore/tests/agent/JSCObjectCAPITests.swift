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

func testJSObjectCAPI() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    var exception: JSValueRef?
    let object = JSObjectMake(ctx, nil, nil)!
    JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), JSValueMakeNumber(ctx, 3), 0, &exception)
    try expect(JSObjectHasProperty(ctx, object, JSStringCreateWithUTF8CString("k")), "has k")
    try expectEqual(JSValueToNumber(ctx, JSObjectGetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), &exception), nil), 3, "get k")
    JSObjectSetPropertyAtIndex(ctx, object, 0, JSValueMakeNumber(ctx, 9), &exception)
    try expectEqual(JSValueToNumber(ctx, JSObjectGetPropertyAtIndex(ctx, object, 0, &exception), nil), 9, "index")
    try expect(JSObjectDeleteProperty(ctx, object, JSStringCreateWithUTF8CString("k"), &exception), "delete k")
    let names = JSObjectCopyPropertyNames(ctx, object)!
    try expect(JSPropertyNameArrayGetCount(names) >= 1, "names")
    _ = JSPropertyNameArrayGetNameAtIndex(names, 0)
    JSPropertyNameAccumulatorAddName(names, JSStringCreateWithUTF8CString("extra"))
    _ = JSPropertyNameArrayRetain(names)
    JSPropertyNameArrayRelease(names)
    JSPropertyNameArrayRelease(names)
    try expect(JSObjectSetPrivate(object, UnsafeMutableRawPointer(bitPattern: 0x5)!), "set private")
    try expect(JSObjectGetPrivate(object) != nil, "get private")

    JSObjectSetProperty(ctx, object, JSStringCreateWithUTF8CString("k"), JSValueMakeNumber(ctx, 3), 0, &exception)
    let key = JSValueMakeString(ctx, JSStringCreateWithUTF8CString("k"))
    try expect(JSObjectHasPropertyForKey(ctx, object, key, &exception), "has for key")
    try expectEqual(JSValueToNumber(ctx, JSObjectGetPropertyForKey(ctx, object, key, &exception), nil), 3, "get for key")
    JSObjectSetPropertyForKey(ctx, object, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("n")), JSValueMakeNumber(ctx, 4), 0, &exception)
    try expect(JSObjectDeletePropertyForKey(ctx, object, JSValueMakeString(ctx, JSStringCreateWithUTF8CString("n")), &exception), "delete for key")
    let proto = JSObjectMake(ctx, nil, nil)!
    JSObjectSetPrototype(ctx, object, proto)
    try expect(JSObjectGetPrototype(ctx, object) != nil, "prototype")

    let array = JSObjectMakeArray(ctx, 0, nil, &exception)!
    try expect(JSValueIsArray(ctx, array), "make array")
    let date = JSObjectMakeDate(ctx, 0, nil, &exception)!
    try expect(JSValueIsDate(ctx, date), "make date")
    let err = JSObjectMakeError(ctx, 0, nil, &exception)!
    try expect(JSValueIsObject(ctx, err), "make error")
    let re = JSObjectMakeRegExp(ctx, 0, nil, &exception)!
    try expect(JSValueIsObject(ctx, re), "make regexp data object; literals remain a listed gap")
    var resolve: JSObjectRef?
    var reject: JSObjectRef?
    let promise = JSObjectMakeDeferredPromise(ctx, &resolve, &reject, &exception)!
    try expect(JSValueIsObject(ctx, promise), "promise object without a job queue")
    try expect(resolve != nil && reject != nil, "resolve/reject")
    let _: JSObjectRef = object
    let _: JSPropertyNameArrayRef = names
    let _: JSPropertyNameAccumulatorRef = names
}

func testJSFunctionAndConstructorCAPI() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    var exception: JSValueRef?
    let ctor = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("function Box(v){ this.v = v } Box"), nil, nil, 1, &exception)!
    try expect(JSObjectIsFunction(ctx, ctor), "is function")
    try expect(JSObjectIsConstructor(ctx, ctor), "is constructor")
    let ctorArgs: [JSValueRef?] = [JSValueMakeNumber(ctx, 9)]
    let constructed = ctorArgs.withUnsafeBufferPointer {
        JSObjectCallAsConstructor(ctx, ctor, 1, $0.baseAddress, &exception)
    }!
    try expect(JSValueIsInstanceOfConstructor(ctx, constructed, ctor, &exception), "instance of")
    let fn = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("function id(x){ return x } id"), nil, nil, 1, &exception)!
    let fnArgs: [JSValueRef?] = [JSValueMakeNumber(ctx, 6)]
    let called = fnArgs.withUnsafeBufferPointer {
        JSObjectCallAsFunction(ctx, fn, nil, 1, $0.baseAddress, &exception)
    }!
    try expectEqual(JSValueToNumber(ctx, called, nil), 6, "call as function")
    let made = JSObjectMakeFunction(ctx, JSStringCreateWithUTF8CString("id"), 1, nil, JSStringCreateWithUTF8CString("return 7"), nil, 1, &exception)
    try expect(made != nil, "make function")
    try expectEqual(JSValueToNumber(ctx, JSObjectCallAsFunction(ctx, made, nil, 0, nil, &exception), nil), 7, "made function body")
}
