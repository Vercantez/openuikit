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

func testCFHostCreateWithName() {

    require(CFHostGetTypeID() != 0, "host type ID")
    let host = CFHostCreateWithName(nil, cfString("localhost")).takeRetainedValue()
    var resolved = DarwinBoolean(false)
    require(CFHostGetNames(host, &resolved) != nil, "name present")
    require(resolved.boolValue, "name resolved at creation")
    require(CFHostStartInfoResolution(host, .addresses, nil), "localhost addresses")
    var addressesResolved = DarwinBoolean(false)
    let addresses = CFHostGetAddressing(host, &addressesResolved)!.takeRetainedValue()
    require(addressesResolved.boolValue, "addresses resolved")
    require(CFArrayGetCount(addresses) > 0, "at least one localhost address")
    require(!CFHostStartInfoResolution(host, .reachability, nil), "reachability fail-closed")
    var reachabilityResolved = DarwinBoolean(true)
    require(CFHostGetReachability(host, &reachabilityResolved) == nil, "no fabricated reachability")
    require(!reachabilityResolved.boolValue, "reachability remains unresolved")
    CFHostCancelInfoResolution(host, .addresses)
}

func testCFHostCreateWithAddress() {

    var loopback = sockaddr_in()
    loopback.sin_family = sa_family_t(AF_INET)
    loopback.sin_addr = in_addr(s_addr: "127.0.0.1".withCString { inet_addr($0) })
    let addressData = withUnsafeBytes(of: &loopback) { buffer in
        CFDataCreate(
            nil,
            buffer.bindMemory(to: UInt8.self).baseAddress,
            CFIndex(MemoryLayout<sockaddr_in>.size)
        )!
    }
    let byAddress = CFHostCreateWithAddress(nil, addressData).takeRetainedValue()
    _ = CFHostStartInfoResolution(byAddress, .names, nil)
    var namesResolved = DarwinBoolean(false)
    _ = CFHostGetNames(byAddress, &namesResolved)
}

func testCFHostCreateCopy() {

    let host = CFHostCreateWithName(nil, cfString("localhost")).takeRetainedValue()
    let copy = CFHostCreateCopy(nil, host).takeRetainedValue()
    require(copy != host, "host copy identity")
    require(copy.hashValue == copy.hashValue, "host hashValue")
    var hostHasher = Hasher()
    copy.hash(into: &hostHasher)
    _ = hostHasher.finalize()
    require(copy == copy, "host equality")
}

func testCFHostClientAndRunLoop() {

    let host = CFHostCreateWithName(nil, cfString("localhost")).takeRetainedValue()
    let callback: CFHostClientCallBack = { _, _, _, _ in }
    var context = CFHostClientContext()
    require(CFHostSetClient(host, callback, &context), "set client")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFHostScheduleWithRunLoop(host, loop, mode)
        CFHostUnscheduleFromRunLoop(host, loop, mode)
    }
    require(CFHostSetClient(host, nil, nil), "clear client")
}
