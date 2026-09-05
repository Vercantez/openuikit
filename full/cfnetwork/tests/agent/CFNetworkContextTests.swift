import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

final class CallbackCounter {
    var value = 0
}

func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    require(
        CFStringGetCString(
            value,
            &buffer,
            CFIndex(buffer.count),
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFString conversion"
    )
    return String(cString: buffer)
}

func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

func testCFHostClientContext() {

    var context = CFHostClientContext()
    require(context.version == 0, "default version")
    require(context.info == nil, "default info")
    require(context.retain == nil, "default retain")
    require(context.release == nil, "default release")
    require(context.copyDescription == nil, "default copyDescription")
    context.version = 0
    context.info = nil
    context.retain = nil
    context.release = nil
    context.copyDescription = nil
    let filled = CFHostClientContext(
        version: 0,
        info: nil,
        retain: nil,
        release: nil,
        copyDescription: nil
    )
    require(filled.version == 0, "filled version")
    _ = filled.info
    _ = filled.retain
    _ = filled.release
    _ = filled.copyDescription
}

func testCFNetServiceClientContext() {

    var serviceContext = CFNetServiceClientContext()
    require(serviceContext.version == 0, "service context version")
    require(serviceContext.info == nil, "service context info")
    require(serviceContext.retain == nil, "service context retain")
    require(serviceContext.release == nil, "service context release")
    require(serviceContext.copyDescription == nil, "service context copyDescription")
    let filledServiceContext = CFNetServiceClientContext(
        version: 0,
        info: nil,
        retain: nil,
        release: nil,
        copyDescription: nil
    )
    require(filledServiceContext.version == 0, "filled service context")
    _ = filledServiceContext.info
    _ = filledServiceContext.retain
    _ = filledServiceContext.release
    _ = filledServiceContext.copyDescription
}
