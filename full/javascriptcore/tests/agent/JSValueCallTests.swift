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

func testJSValueCall() throws {
    let context = JSContext()
    let scripted = context.evaluateScript("function add(x,y){ return x+y } add")!
    let result = scripted.call(withArguments: [3, 4])!
    try expectEqual(result.toInt32(), 7, "call add")
    let noArgs = context.evaluateScript("function ping(){ return 1 } ping")!
    try expectEqual(noArgs.call(withArguments: []).toInt32(), 1, "call no args")
}

func testJSValueConstruct() throws {
    let context = JSContext()
    let ctor = context.evaluateScript("function Box(v){ this.v = v } Box")!
    let instance = ctor.construct(withArguments: [9])!
    try expectEqual(instance.forProperty("v").toInt32(), 9, "construct this.v")
    try expect(instance.isObject, "constructed object")
}

func testJSValueInvokeMethod() throws {
    let context = JSContext()
    let ctor = context.evaluateScript("function Box(v){ this.v = v } Box")!
    let instance = ctor.construct(withArguments: [9])!
    try expect(instance.invokeMethod("toString", withArguments: []).toString() != nil, "invoke toString")
    context.evaluateScript("var o = { n: 3, add: function(x){ return this.n + x } }")
    let object = context.evaluateScript("o")!
    try expectEqual(object.invokeMethod("add", withArguments: [4]).toInt32(), 7, "invokeMethod this")
}
