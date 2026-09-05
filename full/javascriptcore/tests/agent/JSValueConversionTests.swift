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

func testJSValueDeepDictionaryConversion() throws {
    let context = JSContext()
    let nested = context.evaluateScript("({outer:{inner:1, flag:true}, label:'x'})")!
    let dict = nested.toDictionary()
    try expect(dict != nil, "toDictionary")
    let outer = dict?["outer"] as? [AnyHashable: Any]
    try expect((outer?["inner"] as? NSNumber)?.intValue == 1, "nested inner")
    try expect(dict?["label"] != nil, "nested label present")
    try expectEqual(nested.forProperty("label").toString(), "x", "nested label")
    let fromSwift = JSValue(object: ["a": ["b": 2]] as [AnyHashable: Any], in: context)!
    try expectEqual(fromSwift.forProperty("a").forProperty("b").toInt32(), 2, "swift nested dict into JS")
    try expect(fromSwift.toDictionary()?["a"] != nil, "nested dict round trip present")
}

func testJSValueDeepArrayConversion() throws {
    let context = JSContext()
    let nested = context.evaluateScript("[[1,2],{k:3}]")!
    let array = nested.toArray()
    try expectEqual(array?.count, 2, "outer array")
    try expectEqual(nested.atIndex(0).toArray()?.count, 2, "inner array")
    try expectEqual(nested.atIndex(1).forProperty("k").toInt32(), 3, "array nested object")
    let fromSwift = JSValue(object: [1, ["z": 9]] as [Any], in: context)!
    try expectEqual(fromSwift.atIndex(1).forProperty("z").toInt32(), 9, "swift nested array into JS")
    try expect(fromSwift.toObject() != nil, "toObject array")
    try expectEqual(fromSwift.toArray()?.count, 2, "toArray round trip")
}
