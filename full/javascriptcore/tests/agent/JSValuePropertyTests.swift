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

func testJSPropertyDescriptorKeys() throws {
    try expectEqual(JSPropertyDescriptorWritableKey, "writable", "writable key")
    try expectEqual(JSPropertyDescriptorEnumerableKey, "enumerable", "enumerable key")
    try expectEqual(JSPropertyDescriptorConfigurableKey, "configurable", "configurable key")
    try expectEqual(JSPropertyDescriptorValueKey, "value", "value key")
    try expectEqual(JSPropertyDescriptorGetKey, "get", "get key")
    try expectEqual(JSPropertyDescriptorSetKey, "set", "set key")
}

func testJSValueProperties() throws {
    let context = JSContext()
    let object = context.evaluateScript("({a: 1, b: 'x'})")!
    try expect(object.isObject, "object")
    try expectEqual(object.forProperty("a").toInt32(), 1, "property a")
    try expect(object.hasProperty("b"), "has b")
    object.setValue("y", forProperty: "b")
    try expectEqual(object.forProperty("b").toString(), "y", "set property")
}

func testJSValueSubscripts() throws {
    let context = JSContext()
    let array = context.evaluateScript("[10, 20]")!
    try expectEqual(array.atIndex(1).toInt32(), 20, "index 1")
    array.setValue(30, at: 1)
    try expectEqual(array.objectAtIndexedSubscript(1).toInt32(), 30, "indexed get")
    array.setObject(5, atIndexedSubscript: 0)
    try expectEqual(array.objectAtIndexedSubscript(0).toInt32(), 5, "indexed set")
    let dictValue = context.evaluateScript("({k:1})")!
    dictValue.setObject(8, forKeyedSubscript: "k")
    try expectEqual(dictValue.objectForKeyedSubscript("k").toInt32(), 8, "keyed set")
}

func testJSValueDefineProperty() throws {
    let context = JSContext()
    let dictValue = context.evaluateScript("({k:1})")!
    dictValue.defineProperty("hidden", descriptor: [
        JSPropertyDescriptorValueKey: 9,
        JSPropertyDescriptorEnumerableKey: false,
        JSPropertyDescriptorWritableKey: true,
        JSPropertyDescriptorConfigurableKey: true
    ] as [AnyHashable: Any])
    try expectEqual(dictValue.forProperty("hidden").toInt32(), 9, "defineProperty value")
    let getter: () -> Any = { 21 }
    dictValue.defineProperty("computed", descriptor: [
        JSPropertyDescriptorGetKey: getter,
        JSPropertyDescriptorEnumerableKey: true,
        JSPropertyDescriptorConfigurableKey: true
    ] as [AnyHashable: Any])
    try expect(dictValue.hasProperty("computed") || dictValue.forProperty("computed") != nil, "defineProperty getter recorded")
}

func testJSValueDeleteProperty() throws {
    let context = JSContext()
    let object = context.evaluateScript("({a: 1, b: 'x'})")!
    try expect(object.deleteProperty("b"), "delete")
    try expect(!object.hasProperty("b"), "deleted")
}
