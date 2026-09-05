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

func testCFNetServicesErrorRawValues() {

    require(CFNetServicesError.unknown.rawValue == -72000, "unknown")
    require(CFNetServicesError.collision.rawValue == -72001, "collision")
    require(CFNetServicesError.notFound.rawValue == -72002, "notFound")
    require(CFNetServicesError.inProgress.rawValue == -72003, "inProgress")
    require(CFNetServicesError.badArgument.rawValue == -72004, "badArgument")
    require(CFNetServicesError.cancel.rawValue == -72005, "cancel")
    require(CFNetServicesError.invalid.rawValue == -72006, "invalid")
    require(CFNetServicesError.timeout.rawValue == -72007, "timeout")
    require(CFNetServicesError.missingRequiredConfiguration.rawValue == -72008, "missing config")
    require(CFNetServicesError(rawValue: -72004) == .badArgument, "net service failable")
}

func testCFNetServicesErrorHashable() {

    require(CFNetServicesError.cancel != .timeout, "net service inequality")
    require(CFNetServicesError.unknown == .unknown, "net service equality")
    require(CFNetServicesError.unknown.hashValue == CFNetServicesError.unknown.hashValue, "hashValue")
    var hasher = Hasher()
    CFNetServicesError.invalid.hash(into: &hasher)
    _ = hasher.finalize()
}
