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

func testJSContextEvaluate() throws {
    let context = JSContext()
    let sum = context.evaluateScript("40 + 2")!
    try expectEqual(sum.toInt32(), 42, "40+2")
    try expect(sum.isNumber, "sum is number")
    _ = context.evaluateScript("1+1", withSourceURL: URL(string: "https://example.test/app.js"))
    try expectEqual(context.evaluateScript("40+2")!.description, "42", "JSValue.description")
    let json = context.evaluateScript("JSON.stringify({k:1})")!
    try expectEqual(json.toString(), "{\"k\":1}", "json stringify")
    try expect(context.evaluateScript("JSON.parse('{\"k\":2}')").forProperty("k").toInt32() == 2, "json parse")
}

func testJSContextException() throws {
    let context = JSContext()
    var sawException = false
    context.exceptionHandler = { (_: JSContext?, _: JSValue?) in sawException = true }
    _ = context.evaluateScript("throw 'nope'")
    try expect(sawException, "exception handler")
    try expect(context.exception != nil, "exception stored")
    context.exception = nil
    _ = context.evaluateScript("40 + 2")
    try expect(context.exception == nil, "exception cleared after success")
}

func testJSContextGlobalObject() throws {
    let context = JSContext()
    try expect(context.globalObject.isObject, "global object")
    context.setObject("linux", forKeyedSubscript: "hostName" as NSString)
    try expectEqual(context.objectForKeyedSubscript("hostName").toString(), "linux", "global subscript")
    try expectEqual(context.evaluateScript("hostName").toString(), "linux", "global ident")
    try expectEqual(context.globalObject.forProperty("hostName").toString(), "linux", "globalObject property")
}

func testJSContextCurrentTLS() throws {
    _ = JSContext.current()
    _ = JSContext.currentThis()
    _ = JSContext.currentArguments()
    _ = JSContext.currentCallee()
    let context = JSContext()
    let ping: ([Any]) -> Any = { _ in
        _ = JSContext.current()
        _ = JSContext.currentThis()
        _ = JSContext.currentArguments()
        _ = JSContext.currentCallee()
        return "ok"
    }
    context.setObject(ping, forKeyedSubscript: "probeTLS" as NSString)
    try expectEqual(context.evaluateScript("probeTLS()").toString(), "ok", "tls during host call")
}

func testJSContextNameAndInspectable() throws {
    let vm = JSVirtualMachine()
    let context = JSContext(virtualMachine: vm)!
    try expect(context.virtualMachine === vm, "virtualMachine identity")
    context.name = "lane"
    try expectEqual(context.name, "lane", "name")
    context.isInspectable = false
    try expect(!context.isInspectable, "inspectable off; no inspector backend")
    context.isInspectable = true
    try expect(context.isInspectable, "inspectable stored true")
    try expect(context.jsGlobalContextRef != nil, "jsGlobalContextRef")
    let wrapped = JSContext(JSGlobalContextRef: context.jsGlobalContextRef)!
    try expect(wrapped.globalObject.isObject, "wrap global context")
    let plain = JSContext()
    try expect(plain.virtualMachine != nil, "default VM")
}
