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

func testCFNetworkCopySystemProxySettings() {
    setenv("http_proxy", "http://proxy.example.test:8080", 1)
    setenv("no_proxy", "localhost,example.com", 1)
    let settings = CFNetworkCopySystemProxySettings()!.takeRetainedValue()
    require(CFDictionaryGetCount(settings) == 0, "system proxy settings are empty")
    unsetenv("http_proxy")
    unsetenv("no_proxy")
}

func testCFNetworkCopyProxiesForURL() {

    let settings = CFNetworkCopySystemProxySettings()!.takeRetainedValue()
    let target = CFURLCreateWithString(nil, cfString("http://other.test/"), nil)!
    let proxies = CFNetworkCopyProxiesForURL(target, settings).takeRetainedValue()
    require(CFArrayGetCount(proxies) == 1, "one proxy entry")
    guard let firstPointer = CFArrayGetValueAtIndex(proxies, 0) else {
        fatalError("CFNetworkRuntime: missing direct proxy entry")
    }
    let first = Unmanaged<CFDictionary>.fromOpaque(firstPointer).takeUnretainedValue()
    let typePointer = CFDictionaryGetValue(
        first,
        Unmanaged.passUnretained(kCFProxyTypeKey).toOpaque()
    )!
    let type = Unmanaged<CFString>.fromOpaque(typePointer).takeUnretainedValue()
    require(swiftString(type) == "kCFProxyTypeNone", "CopyProxiesForURL is DIRECT")
}

func testCFNetworkCopyProxiesForPACScript() {

    let target = CFURLCreateWithString(nil, cfString("http://other.test/"), nil)!
    var pacError: Unmanaged<CFError>?
    require(
        CFNetworkCopyProxiesForAutoConfigurationScript(
            cfString("function FindProxyForURL() { return 'DIRECT'; }"),
            target,
            &pacError
        ) == nil,
        "PAC script fail-closed"
    )
    require(pacError != nil, "PAC error set")
    _ = pacError?.takeRetainedValue()
}

func testCFNetworkExecutePAC() {

    let target = CFURLCreateWithString(nil, cfString("http://other.test/"), nil)!
    var context = CFStreamClientContext()
    let callbackCount = CallbackCounter()
    let callback: CFProxyAutoConfigurationResultCallback = { _, _, error in
        require(error != nil, "PAC callback error")
        callbackCount.value += 1
    }
    let source = CFNetworkExecuteProxyAutoConfigurationScript(
        cfString("function FindProxyForURL() { return 'DIRECT'; }"),
        target,
        callback,
        &context
    )
    require(callbackCount.value == 1, "PAC callback ran once")
    _ = source
    let urlCount = CallbackCounter()
    let pacURL = CFURLCreateWithString(nil, cfString("http://example.com/proxy.pac"), nil)!
    let urlCallback: CFProxyAutoConfigurationResultCallback = { _, _, error in
        require(error != nil, "PAC URL callback error")
        urlCount.value += 1
    }
    let urlSource = CFNetworkExecuteProxyAutoConfigurationURL(
        pacURL,
        target,
        urlCallback,
        &context
    )
    require(urlCount.value == 1, "PAC URL callback ran once")
    _ = urlSource
}
