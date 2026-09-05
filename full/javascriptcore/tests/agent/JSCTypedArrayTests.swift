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

func testJSTypedArrayAPI() throws {
    let ctx = JSGlobalContextCreate(nil)!
    defer { JSGlobalContextRelease(ctx) }
    var exception: JSValueRef?
    let typed = JSObjectMakeTypedArray(ctx, kJSTypedArrayTypeUint8Array, 4, &exception)!
    try expect(JSValueGetTypedArrayType(ctx, typed, &exception) == kJSTypedArrayTypeUint8Array, "typed type")
    try expectEqual(JSObjectGetTypedArrayLength(ctx, typed, &exception), 4, "typed length")
    try expectEqual(JSObjectGetTypedArrayByteLength(ctx, typed, &exception), 4, "typed bytes")
    try expectEqual(JSObjectGetTypedArrayByteOffset(ctx, typed, &exception), 0, "offset")
    let interned = JSObjectGetTypedArrayBuffer(ctx, typed, &exception)!
    let internedAgain = JSObjectGetTypedArrayBuffer(ctx, typed, &exception)!
    try expect(interned == internedAgain, "typed array buffer is interned")
    try expect(JSObjectGetTypedArrayBytesPtr(ctx, typed, &exception) != nil, "bytes ptr")
    try expectEqual(JSObjectGetArrayBufferByteLength(ctx, interned, &exception), 4, "buffer length")
    try expect(JSObjectGetArrayBufferBytesPtr(ctx, interned, &exception) != nil, "buffer ptr")
    let fromBuffer = JSObjectMakeTypedArrayWithArrayBuffer(ctx, kJSTypedArrayTypeUint8Array, interned, &exception)!
    try expect(JSObjectGetTypedArrayLength(ctx, fromBuffer, &exception) == 4, "from buffer")
    let offsetView = JSObjectMakeTypedArrayWithArrayBufferAndOffset(ctx, kJSTypedArrayTypeUint8Array, interned, 2, 2, &exception)!
    try expectEqual(JSObjectGetTypedArrayByteOffset(ctx, offsetView, &exception), 2, "view offset")

    let types: [JSTypedArrayType] = [
        kJSTypedArrayTypeInt8Array, kJSTypedArrayTypeInt16Array, kJSTypedArrayTypeInt32Array,
        kJSTypedArrayTypeUint16Array, kJSTypedArrayTypeUint32Array,
        kJSTypedArrayTypeUint8ClampedArray, kJSTypedArrayTypeFloat32Array,
        kJSTypedArrayTypeFloat64Array, kJSTypedArrayTypeBigInt64Array,
        kJSTypedArrayTypeBigUint64Array, kJSTypedArrayTypeArrayBuffer
    ]
    for type in types {
        let view = JSObjectMakeTypedArray(ctx, type, 2, &exception)!
        try expect(JSValueGetTypedArrayType(ctx, view, &exception) == type, "typed \(type.rawValue)")
    }

    let dealloc: JSTypedArrayBytesDeallocator = { _, _ in }
    let raw = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: 8)
    let noCopy = JSObjectMakeArrayBufferWithBytesNoCopy(ctx, raw, 8, dealloc, nil, &exception)!
    try expectEqual(JSObjectGetArrayBufferByteLength(ctx, noCopy, &exception), 8, "nocopy buffer")
    let typedNoCopy = JSObjectMakeTypedArrayWithBytesNoCopy(ctx, kJSTypedArrayTypeUint8Array, raw, 8, dealloc, nil, &exception)!
    try expectEqual(JSObjectGetTypedArrayLength(ctx, typedNoCopy, &exception), 8, "typed nocopy")
}
