import CoreFoundation
import Foundation

func cfString(_ value: String) -> CFString {
    value.withCString { cString in
        CFStringCreateWithCString(
            nil,
            cString,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    if CFStringGetCString(
        value,
        &buffer,
        CFIndex(buffer.count),
        CFStringBuiltInEncodings.UTF8.rawValue
    ) {
        return String(cString: buffer)
    }
    return ""
}

func cfStringsEqual(_ left: CFString, _ right: CFString) -> Bool {
    CFStringCompare(left, right, CFStringCompareFlags(rawValue: 0)) == .compareEqualTo
}

func cfStringsEqualInsensitive(_ left: CFString, _ right: CFString) -> Bool {
    CFStringCompare(left, right, .compareCaseInsensitive) == .compareEqualTo
}

func cfNumber(_ value: Int) -> CFNumber {
    var stored = value
    return withUnsafePointer(to: &stored) { pointer in
        CFNumberCreate(nil, .nsIntegerType, pointer)!
    }
}

func cfNumberInt32(_ value: Int32) -> CFNumber {
    var stored = value
    return withUnsafePointer(to: &stored) { pointer in
        CFNumberCreate(nil, .sInt32Type, pointer)!
    }
}

func cfBoolean(_ value: Bool) -> CFBoolean {
    (value ? kCFBooleanTrue : kCFBooleanFalse)!
}

func cfRetain<T: AnyObject>(_ value: T) -> Unmanaged<T> {
    Unmanaged.passRetained(value)
}

func cfDataCopy(_ data: CFData) -> CFData {
    CFDataCreateCopy(nil, data)!
}

func cfDataFromBytes(_ bytes: [UInt8]) -> CFData {
    bytes.withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func cfMutableDictionary() -> CFMutableDictionary {
    var keyCallbacks = kCFTypeDictionaryKeyCallBacks
    var valueCallbacks = kCFTypeDictionaryValueCallBacks
    return CFDictionaryCreateMutable(nil, 0, &keyCallbacks, &valueCallbacks)!
}

func cfDictionarySet(_ dictionary: CFMutableDictionary, key: CFString, value: AnyObject) {
    CFDictionarySetValue(
        dictionary,
        Unmanaged.passUnretained(key).toOpaque(),
        Unmanaged.passUnretained(value).toOpaque()
    )
}

func cfDictionarySetOptional(
    _ dictionary: CFMutableDictionary,
    key: CFString,
    value: AnyObject?
) {
    guard let value else { return }
    cfDictionarySet(dictionary, key: key, value: value)
}

func cfEmptyArray() -> CFArray {
    var callbacks = kCFTypeArrayCallBacks
    return CFArrayCreate(nil, nil, 0, &callbacks)!
}

func cfMutableArray() -> CFMutableArray {
    var callbacks = kCFTypeArrayCallBacks
    return CFArrayCreateMutable(nil, 0, &callbacks)!
}

func cfArrayAppend(_ array: CFMutableArray, _ value: AnyObject) {
    CFArrayAppendValue(array, Unmanaged.passUnretained(value).toOpaque())
}

func cfStringArray(_ values: [String]) -> CFArray {
    let array = cfMutableArray()
    for value in values {
        cfArrayAppend(array, cfString(value))
    }
    return array
}

func cfDataArray(_ values: [CFData]) -> CFArray {
    let array = cfMutableArray()
    for value in values {
        cfArrayAppend(array, value)
    }
    return array
}

func cfURLString(_ url: CFURL) -> String {
    guard let string = CFURLGetString(url) else { return "" }
    return swiftString(string)
}

func cfURLFromString(_ value: String) -> CFURL? {
    CFURLCreateWithString(nil, cfString(value), nil)
}

func cfRequestURI(from url: CFURL) -> String {
    if let path = CFURLCopyPath(url) {
        var uri = swiftString(path)
        if uri.isEmpty { uri = "/" }
        if let query = CFURLCopyQueryString(url, nil) {
            uri += "?" + swiftString(query)
        }
        return uri
    }
    let absolute = cfURLString(url)
    if let parsed = URL(string: absolute) {
        var uri = parsed.path.isEmpty ? "/" : parsed.path
        if let query = parsed.query { uri += "?" + query }
        return uri
    }
    return "/"
}

func cfNetworkError(_ code: CFNetworkErrors, userInfo: CFDictionary? = nil) -> CFError {
    CFErrorCreate(
        nil,
        kCFErrorDomainCFNetwork,
        CFIndex(code.rawValue),
        userInfo
    )!
}

func cfStreamError(
    domain: Int32,
    code: Int32
) -> CFStreamError {
    CFStreamError(domain: CFIndex(domain), error: code)
}

func cfWriteStreamError(
    _ pointer: UnsafeMutablePointer<CFStreamError>?,
    domain: Int32,
    code: Int32
) {
    pointer?.pointee = cfStreamError(domain: domain, code: code)
}

func cfInertReadStream() -> CFReadStream {
    var dummy: UInt8 = 0
    return CFReadStreamCreateWithBytesNoCopy(nil, &dummy, 0, kCFAllocatorNull)!
}

func cfInertWriteStream() -> CFWriteStream {
    CFWriteStreamCreateWithAllocatedBuffers(nil, nil)!
}

func cfInertRunLoopSource() -> CFRunLoopSource {
    var context = CFRunLoopSourceContext()
    context.version = 0
    return CFRunLoopSourceCreate(nil, 0, &context)!
}

private var pacDummyInfo: UInt8 = 0

func cfClientInfoPointer(_ info: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer {
    info ?? UnsafeMutableRawPointer(&pacDummyInfo)
}

func cfRetainContextInfo(
    _ retain: CFAllocatorRetainCallBack?,
    info: UnsafeMutableRawPointer?
) {
    if let retain, let info {
        _ = retain(info)
    }
}

func cfReleaseContextInfo(
    _ release: CFAllocatorReleaseCallBack?,
    info: UnsafeMutableRawPointer?
) {
    if let release, let info {
        release(info)
    }
}
