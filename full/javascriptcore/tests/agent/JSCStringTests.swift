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

func testJSStringAPI() throws {
    let hello = JSStringCreateWithUTF8CString("hello")!
    defer {
        JSStringRelease(hello)
    }
    try expectEqual(JSStringGetLength(hello), 5, "utf16 length")
    let copy = JSStringRetain(hello)!
    JSStringRelease(copy)
    try expect(JSStringIsEqual(hello, JSStringCreateWithUTF8CString("hello")), "equal strings")
    try expect(JSStringIsEqualToUTF8CString(hello, "hello"), "equal utf8")
    var buffer = [CChar](repeating: 0, count: 16)
    let copied = JSStringGetUTF8CString(hello, &buffer, buffer.count)
    try expect(copied > 0, "utf8 copy")
    let cf = JSStringCopyCFString(nil, hello)!
    let roundTrip = JSStringCreateWithCFString(cf)!
    try expect(JSStringIsEqual(hello, roundTrip), "cfstring round trip")
    JSStringRelease(roundTrip)
    let chars: [JSChar] = [0x41, 0x42]
    let fromChars = JSStringCreateWithCharacters(chars, 2)!
    try expect(JSStringIsEqualToUTF8CString(fromChars, "AB"), "create with characters")
    JSStringRelease(fromChars)
    try expectEqual(JSStringGetMaximumUTF8CStringSize(hello), 16, "max utf8")
    try expect(JSStringGetCharactersPtr(hello) != nil, "chars ptr")
    let _: JSStringRef = hello
}
