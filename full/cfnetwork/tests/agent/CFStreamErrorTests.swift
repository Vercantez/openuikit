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

func testCFStreamErrorHTTPRawValues() {

    require(CFStreamErrorHTTP.parseFailure.rawValue == -1, "http parse failure")
    require(CFStreamErrorHTTP.redirectionLoop.rawValue == -2, "http redirect loop")
    require(CFStreamErrorHTTP.badURL.rawValue == -3, "http bad URL")
    require(CFStreamErrorHTTP(rawValue: -3) == .badURL, "http failable")
}

func testCFStreamErrorHTTPHashable() {

    require(CFStreamErrorHTTP.parseFailure != .badURL, "http error inequality")
    require(CFStreamErrorHTTP.parseFailure == .parseFailure, "http error equality")
    require(CFStreamErrorHTTP.parseFailure.hashValue == CFStreamErrorHTTP.parseFailure.hashValue, "hashValue")
    var hasher = Hasher()
    CFStreamErrorHTTP.redirectionLoop.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCFStreamErrorHTTPAuthenticationRawValues() {

    require(CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue == -1000, "auth type")
    require(CFStreamErrorHTTPAuthentication.badUserName.rawValue == -1001, "auth username")
    require(CFStreamErrorHTTPAuthentication.badPassword.rawValue == -1002, "auth password")
    require(CFStreamErrorHTTPAuthentication(rawValue: -1001) == .badUserName, "auth username init")
    require(CFStreamErrorHTTPAuthentication.typeUnsupported != .badPassword, "auth error inequality")
    require(
        CFStreamErrorHTTPAuthentication.typeUnsupported.hashValue
            == CFStreamErrorHTTPAuthentication.typeUnsupported.hashValue,
        "auth hashValue"
    )
    var hasher = Hasher()
    CFStreamErrorHTTPAuthentication.badUserName.hash(into: &hasher)
    _ = hasher.finalize()
}
