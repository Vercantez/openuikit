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

func testJSInterpreterSubset() throws {
    let context = JSContext()
    try expectEqual(context.evaluateScript("typeof 1").toString(), "number", "typeof number")
    try expectEqual(context.evaluateScript("1 + '2'").toString(), "12", "ToPrimitive string concat ECMA-262 13.8")
    try expectEqual(context.evaluateScript("'2' * '3'").toInt32(), 6, "ToNumber multiply ECMA-262 7.1.3")
    try expect(context.evaluateScript("null == undefined").toBool(), "abstract eq null/undefined ECMA-262 7.2.14")
    try expect(context.evaluateScript("'12' == 12").toBool(), "abstract eq string/number")
    try expect(!context.evaluateScript("'12' === 12").toBool(), "strict eq")
    try expectEqual(context.evaluateScript("false || 'x'").toString(), "x", "logical or")
    try expectEqual(context.evaluateScript("1 && 2").toInt32(), 2, "logical and")
    try expectEqual(context.evaluateScript("if (1) { 8 } else { 9 }").toInt32(), 8, "if")
    try expectEqual(context.evaluateScript("var s=0; for (var i=0; i<3; i=i+1) { s=s+i } s").toInt32(), 3, "for")
    try expectEqual(context.evaluateScript("var n=0; var i=3; while (i) { n=n+i; i=i-1 } n").toInt32(), 6, "while")
    try expectEqual(context.evaluateScript("var x=1; x+=2; x").toInt32(), 3, "+=")
    try expectEqual(context.evaluateScript("var y=1; ++y").toInt32(), 2, "prefix ++")
    try expectEqual(context.evaluateScript("Math.floor(1.9)").toInt32(), 1, "Math.floor")
    try expectEqual(context.evaluateScript("Math.max(1,4,2)").toInt32(), 4, "Math.max")
    try expectEqual(context.evaluateScript("Math.pow(2,3)").toInt32(), 8, "Math.pow")
    try expectEqual(context.evaluateScript("'hello'.charAt(1)").toString(), "e", "String.charAt")
    try expectEqual(context.evaluateScript("'hello'.length").toInt32(), 5, "String.length utf16")
    try expectEqual(context.evaluateScript("'ab'.concat('c')").toString(), "abc", "String.concat")
    try expectEqual(context.evaluateScript("'HELLO'.toLowerCase()").toString(), "hello", "toLowerCase")
    try expectEqual(context.evaluateScript("[1,2].push(3)").toInt32(), 3, "Array.push length")
    try expectEqual(context.evaluateScript("var a=[1,2]; a.push(3); a.join('-')").toString(), "1-2-3", "Array.join")
    try expectEqual(context.evaluateScript("[10,20,30].slice(1,2)[0]").toInt32(), 20, "Array.slice")
    try expectEqual(context.evaluateScript("[1,2].concat([3]).length").toInt32(), 3, "Array.concat")
    try expect(context.evaluateScript("({a:1}) instanceof Object").toBool(), "instanceof")
}

func testJSUnsupportedECMAScriptGaps() throws {
    let context = JSContext()
    func expectGap(_ script: String, contains fragment: String, _ message: String) throws {
        context.exception = nil
        _ = context.evaluateScript(script)
        let text = context.exception?.toString() ?? ""
        try expect(context.exception != nil, "\(message) should throw")
        try expect(jscIndexOfProbe(text, fragment) != nil, "\(message): \(text)")
        try expect(context.exception.forProperty("line").isNumber, "\(message) line")
        try expect(context.exception.forProperty("column").isNumber, "\(message) column")
        try expectEqual(context.exception.forProperty("name").toString(), "SyntaxError", "\(message) SyntaxError")
    }
    try expectGap("class Foo {}", contains: "class", "class gap")
    try expectGap("async function f(){}", contains: "async", "async gap")
    try expectGap("yield 1", contains: "generator", "generator gap")
    try expectGap("/a+/", contains: "regular expression", "regex gap")
    try expectGap("x => x", contains: "arrow", "arrow gap")
    try expectGap("`hi`", contains: "template", "template gap")
    try expectGap("import x from 'm'", contains: "module", "import gap")
    try expectGap("export const x = 1", contains: "module", "export gap")
    _ = context.evaluateScript("\nclass Foo {}")
    try expectEqual(context.exception.forProperty("line").toInt32(), 2, "syntax line is 2")
}
