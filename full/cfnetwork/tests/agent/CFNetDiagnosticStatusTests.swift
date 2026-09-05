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

func testCFNetDiagnosticStatusRawValues() {

    require(CFNetDiagnosticStatusValues.noErr.rawValue == 0, "diagnostic noErr")
    require(CFNetDiagnosticStatusValues.err.rawValue == -66560, "diagnostic err")
    require(CFNetDiagnosticStatusValues.connectionUp.rawValue == -66555, "connection up")
    require(CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue == -66559, "indeterminate")
    require(CFNetDiagnosticStatusValues.connectionDown.rawValue == -66557, "connection down")
    require(CFNetDiagnosticStatusValues(rawValue: -66557) == .connectionDown, "diagnostic failable")
}

func testCFNetDiagnosticStatusHashable() {

    require(CFNetDiagnosticStatusValues.connectionDown != .connectionUp, "diagnostic inequality")
    require(CFNetDiagnosticStatusValues.noErr == .noErr, "diagnostic equality")
    require(CFNetDiagnosticStatusValues.noErr.hashValue == CFNetDiagnosticStatusValues.noErr.hashValue, "hashValue")
    var hasher = Hasher()
    CFNetDiagnosticStatusValues.err.hash(into: &hasher)
    _ = hasher.finalize()
}
