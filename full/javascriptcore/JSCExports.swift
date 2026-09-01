import CoreFoundation
import Foundation

/// C ABI thunks for symbols whose Swift overlay types cannot appear in `@_cdecl`.
/// C clients link the unmangled `JS*` names; Swift clients keep the typed overlay.

@_cdecl("JSValueGetType")
public func JSValueGetTypeCABI(_ ctx: JSContextRef?, _ value: JSValueRef?) -> UInt32 {
    JSValueGetType(ctx, value).rawValue
}

@_cdecl("JSValueCompare")
public func JSValueCompareCABI(
    _ ctx: JSContextRef?,
    _ left: JSValueRef?,
    _ right: JSValueRef?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    guard let ctx, let left, let right else { return JSRelationCondition.undefined.rawValue }
    return JSValueCompare(ctx, left, right, exception).rawValue
}

@_cdecl("JSValueCompareDouble")
public func JSValueCompareDoubleCABI(
    _ ctx: JSContextRef?,
    _ left: JSValueRef?,
    _ right: Double,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    guard let ctx, let left else { return JSRelationCondition.undefined.rawValue }
    return JSValueCompareDouble(ctx, left, right, exception).rawValue
}

@_cdecl("JSValueCompareInt64")
public func JSValueCompareInt64CABI(
    _ ctx: JSContextRef?,
    _ left: JSValueRef?,
    _ right: Int64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    guard let ctx, let left else { return JSRelationCondition.undefined.rawValue }
    return JSValueCompareInt64(ctx, left, right, exception).rawValue
}

@_cdecl("JSValueCompareUInt64")
public func JSValueCompareUInt64CABI(
    _ ctx: JSContextRef?,
    _ left: JSValueRef?,
    _ right: UInt64,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    guard let ctx, let left else { return JSRelationCondition.undefined.rawValue }
    return JSValueCompareUInt64(ctx, left, right, exception).rawValue
}

@_cdecl("JSClassCreate")
public func JSClassCreateCABI(_ definition: UnsafeRawPointer?) -> JSClassRef? {
    guard let definition else { return nil }
    return JSClassCreate(UnsafePointer(definition.assumingMemoryBound(to: JSClassDefinition.self)))
}

@_cdecl("JSValueGetTypedArrayType")
public func JSValueGetTypedArrayTypeCABI(
    _ ctx: JSContextRef?,
    _ value: JSValueRef?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> UInt32 {
    JSValueGetTypedArrayType(ctx, value, exception).rawValue
}

@_cdecl("JSObjectMakeTypedArray")
public func JSObjectMakeTypedArrayCABI(
    _ ctx: JSContextRef?,
    _ arrayType: UInt32,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef? {
    JSObjectMakeTypedArray(ctx, JSTypedArrayType(rawValue: arrayType), length, exception)
}

@_cdecl("JSObjectMakeTypedArrayWithArrayBuffer")
public func JSObjectMakeTypedArrayWithArrayBufferCABI(
    _ ctx: JSContextRef?,
    _ arrayType: UInt32,
    _ buffer: JSObjectRef?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef? {
    JSObjectMakeTypedArrayWithArrayBuffer(ctx, JSTypedArrayType(rawValue: arrayType), buffer, exception)
}

@_cdecl("JSObjectMakeTypedArrayWithArrayBufferAndOffset")
public func JSObjectMakeTypedArrayWithArrayBufferAndOffsetCABI(
    _ ctx: JSContextRef?,
    _ arrayType: UInt32,
    _ buffer: JSObjectRef?,
    _ byteOffset: Int,
    _ length: Int,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef? {
    JSObjectMakeTypedArrayWithArrayBufferAndOffset(
        ctx,
        JSTypedArrayType(rawValue: arrayType),
        buffer,
        byteOffset,
        length,
        exception
    )
}

@_cdecl("JSObjectMakeTypedArrayWithBytesNoCopy")
public func JSObjectMakeTypedArrayWithBytesNoCopyCABI(
    _ ctx: JSContextRef?,
    _ arrayType: UInt32,
    _ bytes: UnsafeMutableRawPointer?,
    _ byteLength: Int,
    _ bytesDeallocator: JSTypedArrayBytesDeallocator?,
    _ deallocatorContext: UnsafeMutableRawPointer?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef? {
    JSObjectMakeTypedArrayWithBytesNoCopy(
        ctx,
        JSTypedArrayType(rawValue: arrayType),
        bytes,
        byteLength,
        bytesDeallocator,
        deallocatorContext,
        exception
    )
}

@_cdecl("JSStringCreateWithCFString")
public func JSStringCreateWithCFStringCABI(_ string: OpaquePointer?) -> JSStringRef? {
    guard let string else { return JSStringCreateWithCFString(nil) }
    let cf = Unmanaged<CFString>.fromOpaque(UnsafeRawPointer(string)).takeUnretainedValue()
    return JSStringCreateWithCFString(cf)
}

@_cdecl("JSStringCopyCFString")
public func JSStringCopyCFStringCABI(_ alloc: OpaquePointer?, _ string: JSStringRef?) -> OpaquePointer? {
    _ = alloc
    let cf = JSStringCopyCFString(kCFAllocatorDefault, string)
    guard let cf else { return nil }
    return OpaquePointer(Unmanaged.passUnretained(cf).toOpaque())
}
