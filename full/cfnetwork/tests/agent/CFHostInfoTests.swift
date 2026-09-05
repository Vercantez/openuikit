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

func testCFHostInfoTypeRawValues() {

    require(CFHostInfoType.addresses.rawValue == 0, "host addresses")
    require(CFHostInfoType.names.rawValue == 1, "host names")
    require(CFHostInfoType.reachability.rawValue == 2, "host reachability")
    require(CFHostInfoType(rawValue: 0) == .addresses, "host addresses init")
    require(CFHostInfoType(rawValue: 1) == .names, "host names init")
    require(CFHostInfoType(rawValue: 2) == .reachability, "host reachability init")
}

func testCFHostInfoTypeHashable() {

    require(CFHostInfoType.addresses == .addresses, "host info equality")
    require(CFHostInfoType.names != .reachability, "host info inequality")
    require(CFHostInfoType.addresses.hashValue == CFHostInfoType.addresses.hashValue, "host info hashValue")
    var hasher = Hasher()
    CFHostInfoType.names.hash(into: &hasher)
    _ = hasher.finalize()
}
