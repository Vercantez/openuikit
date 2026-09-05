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

func testCFReadStreamCreateForHTTPRequest() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let httpStream = CFReadStreamCreateForHTTPRequest(nil, request).takeRetainedValue()
    _ = httpStream
    var dummy: UInt8 = 0
    let emptyBody = CFReadStreamCreateWithBytesNoCopy(nil, &dummy, 0, kCFAllocatorNull)!
    _ = CFReadStreamCreateForStreamedHTTPRequest(nil, request, emptyBody).takeRetainedValue()
}

func testCFStreamCreateFTP() {

    let ftpURL = CFURLCreateWithString(nil, cfString("ftp://example.com/file"), nil)!
    _ = CFReadStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()
    _ = CFWriteStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()
}

func testCFStreamCreatePair() {

    let host = CFHostCreateWithName(nil, cfString("localhost")).takeRetainedValue()
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    CFStreamCreatePairWithSocketToCFHost(nil, host, 80, &readStream, &writeStream)
    require(readStream != nil && writeStream != nil, "host socket pair")
    _ = readStream?.takeRetainedValue()
    _ = writeStream?.takeRetainedValue()
    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("pair"),
        9
    ).takeRetainedValue()
    var serviceRead: Unmanaged<CFReadStream>?
    var serviceWrite: Unmanaged<CFWriteStream>?
    CFStreamCreatePairWithSocketToNetService(nil, service, &serviceRead, &serviceWrite)
    require(serviceRead != nil && serviceWrite != nil, "net service socket pair")
    _ = serviceRead?.takeRetainedValue()
    _ = serviceWrite?.takeRetainedValue()
}

func testCFSocketStreamSOCKSGetError() {

    var error = CFStreamError(
        domain: CFIndex(kCFStreamErrorDomainHTTP),
        error: Int32(kCFStreamErrorSOCKS4RequestFailed)
    )
    require(CFSocketStreamSOCKSGetError(&error) == 91, "SOCKS error")
    require(
        CFSocketStreamSOCKSGetErrorSubdomain(&error) == Int32(kCFStreamErrorSOCKSSubDomainNone),
        "SOCKS subdomain"
    )
}
