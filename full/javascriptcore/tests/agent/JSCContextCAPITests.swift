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

func testJSContextCAPI() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    JSGlobalContextSetName(ctx, JSStringCreateWithUTF8CString("probe"))
    let name = JSGlobalContextCopyName(ctx)!
    try expect(JSStringIsEqualToUTF8CString(name, "probe"), "context name")
    JSStringRelease(name)
    JSGlobalContextSetInspectable(ctx, true)
    try expect(JSGlobalContextIsInspectable(ctx), "inspectable stored flag only")
    let group = JSContextGetGroup(ctx)!
    _ = JSContextGroupRetain(group)
    JSContextGroupRelease(group)
    try expect(JSContextGetGlobalContext(ctx) == ctx, "global context identity")
    try expect(JSContextGetGlobalObject(ctx) != nil, "global object")

    let createdGroup = JSContextGroupCreate()!
    _ = JSContextGroupRetain(createdGroup)
    let grouped = JSGlobalContextCreateInGroup(createdGroup, nil)!
    _ = JSGlobalContextRetain(grouped)
    JSGlobalContextRelease(grouped)
    JSContextGroupRelease(createdGroup)
    JSContextGroupRelease(createdGroup)

    var exception: JSValueRef?
    let script = JSStringCreateWithUTF8CString("1+1")!
    try expect(JSCheckScriptSyntax(ctx, script, nil, 1, &exception), "syntax ok")
    try expect(!JSCheckScriptSyntax(ctx, JSStringCreateWithUTF8CString("function ("), nil, 1, &exception), "syntax bad")
    let eval = JSEvaluateScript(ctx, JSStringCreateWithUTF8CString("'ab'+'c'"), nil, nil, 1, &exception)!
    let copied = JSValueToStringCopy(ctx, eval, &exception)!
    try expect(JSStringIsEqualToUTF8CString(copied, "abc"), "eval string")
    JSGarbageCollect(ctx)
    let _: JSContextRef = ctx
    let _: JSGlobalContextRef = ctx
    let _: JSContextGroupRef = group
}
