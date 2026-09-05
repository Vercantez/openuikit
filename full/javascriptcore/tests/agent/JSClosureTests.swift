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

func testJSClosureBridging() throws {
    let context = JSContext()
    let add: ([Any]) -> Any = { args in
        let values = args.compactMap { ($0 as? JSValue)?.toDouble() }
        return values.reduce(0, +)
    }
    context.setObject(add, forKeyedSubscript: "hostAdd" as NSString)
    try expectEqual(context.evaluateScript("hostAdd(2, 3)").toInt32(), 5, "closure [Any]->Any")
    let ping: () -> Any = { "pong" }
    context.setObject(ping, forKeyedSubscript: "hostPing" as NSString)
    try expectEqual(context.evaluateScript("hostPing()").toString(), "pong", "closure ()->Any")
    let twice: (Any) -> Any = { arg in
        ((arg as? JSValue)?.toDouble() ?? 0) * 2
    }
    context.setObject(twice, forKeyedSubscript: "hostTwice" as NSString)
    try expectEqual(context.evaluateScript("hostTwice(4)").toInt32(), 8, "closure (Any)->Any")
    let sum2: (Any, Any) -> Any = { a, b in
        ((a as? JSValue)?.toDouble() ?? 0) + ((b as? JSValue)?.toDouble() ?? 0)
    }
    context.setObject(sum2, forKeyedSubscript: "hostSum2" as NSString)
    try expectEqual(context.evaluateScript("hostSum2(1, 2)").toInt32(), 3, "closure (Any,Any)->Any")
    let sum3: (Any, Any, Any) -> Any = { a, b, c in
        ((a as? JSValue)?.toDouble() ?? 0)
            + ((b as? JSValue)?.toDouble() ?? 0)
            + ((c as? JSValue)?.toDouble() ?? 0)
    }
    context.setObject(sum3, forKeyedSubscript: "hostSum3" as NSString)
    try expectEqual(context.evaluateScript("hostSum3(1, 2, 3)").toInt32(), 6, "closure (Any,Any,Any)->Any")
}
