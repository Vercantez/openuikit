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

func testCFNetServiceCreate() {

    require(CFNetServiceGetTypeID() != 0, "service type ID")
    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("OpenUIKit"),
        8080
    ).takeRetainedValue()
    require(swiftString(CFNetServiceGetDomain(service).takeRetainedValue()) == "local.", "domain")
    require(swiftString(CFNetServiceGetType(service).takeRetainedValue()) == "_http._tcp", "type")
    require(swiftString(CFNetServiceGetName(service).takeRetainedValue()) == "OpenUIKit", "name")
    require(CFNetServiceGetPortNumber(service) == 8080, "port")
    require(CFNetServiceGetTargetHost(service) == nil, "no target before resolve")
    require(CFNetServiceGetAddressing(service) == nil, "no addresses before resolve")
    let copy = CFNetServiceCreateCopy(nil, service).takeRetainedValue()
    require(copy != service, "service copy identity")
    require(copy.hashValue == copy.hashValue, "service hashValue")
    var serviceHasher = Hasher()
    copy.hash(into: &serviceHasher)
    _ = serviceHasher.finalize()
    require(copy == copy, "service equality")
    require(swiftString(CFNetServiceGetName(copy).takeRetainedValue()) == "OpenUIKit", "copy name")
}

func testCFNetServiceTXT() {

    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("OpenUIKit"),
        8080
    ).takeRetainedValue()
    let txt = "path=/docs".utf8
    let txtData = Array(txt)
    let record = txtData.withUnsafeBufferPointer { buffer in
        var framed: [UInt8] = [UInt8(buffer.count)]
        framed.append(contentsOf: buffer)
        return framed.withUnsafeBufferPointer {
            CFDataCreate(nil, $0.baseAddress, CFIndex($0.count))!
        }
    }
    require(CFNetServiceSetTXTData(service, record), "set TXT")
    let copiedTXT = CFNetServiceGetTXTData(service)!.takeRetainedValue()
    let parsed = CFNetServiceCreateDictionaryWithTXTData(nil, copiedTXT)!.takeRetainedValue()
    require(CFDictionaryGetCount(parsed) == 1, "TXT dictionary count")
    let rebuilt = CFNetServiceCreateTXTDataWithDictionary(nil, parsed)!.takeRetainedValue()
    require(CFDataGetLength(rebuilt) == CFDataGetLength(record), "TXT round-trip length")
}

func testCFNetServiceRegisterAndResolve() {

    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("OpenUIKit"),
        8080
    ).takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(
        !CFNetServiceRegisterWithOptions(service, 0, &streamError),
        "Bonjour register fail-closed"
    )
    require(
        !CFNetServiceResolveWithTimeout(service, 0.1, &streamError),
        "Bonjour resolve fail-closed"
    )
    require(streamError.domain == CFIndex(kCFStreamErrorDomainNetServices), "net services domain")
    CFNetServiceCancel(service)
}

func testCFNetServiceClient() {

    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("OpenUIKit"),
        8080
    ).takeRetainedValue()
    let callback: CFNetServiceClientCallBack = { _, _, _ in }
    var serviceContext = CFNetServiceClientContext()
    require(CFNetServiceSetClient(service, callback, &serviceContext), "set service client")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFNetServiceScheduleWithRunLoop(service, loop, mode)
        CFNetServiceUnscheduleFromRunLoop(service, loop, mode)
    }
}

func testCFNetServiceBrowser() {

    require(
        CFNetServiceBrowserGetTypeID() != CFNetServiceMonitorGetTypeID(),
        "browser vs monitor type ID"
    )
    var browserContext = CFNetServiceClientContext()
    let callback: CFNetServiceBrowserClientCallBack = { _, _, _, _, _ in }
    let browser = CFNetServiceBrowserCreate(nil, callback, &browserContext).takeRetainedValue()
    require(browser.hashValue == browser.hashValue, "browser hashValue")
    var browserHasher = Hasher()
    browser.hash(into: &browserHasher)
    _ = browserHasher.finalize()
    require(browser == browser, "browser equality")
    require(!(browser != browser), "browser inequality")
    var streamError = CFStreamError(domain: 0, error: 0)
    require(
        !CFNetServiceBrowserSearchForServices(
            browser,
            cfString("local."),
            cfString("_http._tcp"),
            &streamError
        ),
        "browse fail-closed"
    )
    require(
        !CFNetServiceBrowserSearchForDomains(browser, true, &streamError),
        "domain browse fail-closed"
    )
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFNetServiceBrowserScheduleWithRunLoop(browser, loop, mode)
        CFNetServiceBrowserStopSearch(browser, &streamError)
        CFNetServiceBrowserUnscheduleFromRunLoop(browser, loop, mode)
    }
    CFNetServiceBrowserInvalidate(browser)
}

func testCFNetServiceMonitor() {

    let service = CFNetServiceCreate(
        nil,
        cfString("local."),
        cfString("_http._tcp"),
        cfString("OpenUIKit"),
        8080
    ).takeRetainedValue()
    var browserContext = CFNetServiceClientContext()
    let callback: CFNetServiceMonitorClientCallBack = { _, _, _, _, _, _ in }
    let monitor = CFNetServiceMonitorCreate(nil, service, callback, &browserContext)
        .takeRetainedValue()
    require(monitor.hashValue == monitor.hashValue, "monitor hashValue")
    var monitorHasher = Hasher()
    monitor.hash(into: &monitorHasher)
    _ = monitorHasher.finalize()
    require(monitor == monitor, "monitor equality")
    require(!(monitor != monitor), "monitor inequality")
    var streamError = CFStreamError(domain: 0, error: 0)
    require(!CFNetServiceMonitorStart(monitor, .TXT, &streamError), "monitor fail-closed")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFNetServiceMonitorScheduleWithRunLoop(monitor, loop, mode)
        CFNetServiceMonitorStop(monitor, &streamError)
        CFNetServiceMonitorUnscheduleFromRunLoop(monitor, loop, mode)
    }
    CFNetServiceMonitorInvalidate(monitor)
}
