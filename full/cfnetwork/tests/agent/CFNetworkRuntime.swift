import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

enum CFNetworkRuntime {
    static func main() {
        exerciseErrorsAndFlags()
        exerciseHTTPMessage()
        exerciseAuthentication()
        exerciseHost()
        exerciseNetService()
        exerciseDiagnostics()
        exerciseProxy()
        exerciseStreamsAndFTP()
        print("CFNETWORK_AGENT_RUNTIME_OK")
    }
}

CFNetworkRuntime.main()

private final class CallbackCounter {
    var value = 0
}

private func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

private func swiftString(_ value: CFString) -> String {
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

private func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

private func exerciseErrorsAndFlags() {
    require(CFNetworkErrors.cfurlErrorCancelled.rawValue == -999, "cancelled code")
    require(CFNetworkErrors.cfurlErrorBadURL.rawValue == -1000, "bad URL code")
    require(CFNetworkErrors.cfHostErrorHostNotFound.rawValue == 1, "host not found")
    require(CFNetworkErrors.cfErrorPACFileError.rawValue == 308, "PAC error")
    require(CFNetworkErrors(rawValue: 0) == nil, "unknown error raw value")
    require(CFNetworkErrors.cfurlErrorCancelled != .cfurlErrorBadURL, "error inequality")
    var hasher = Hasher()
    CFNetworkErrors.cfurlErrorTimedOut.hash(into: &hasher)
    require(CFNetworkErrors.cfurlErrorTimedOut.hashValue == CFNetworkErrors.cfurlErrorTimedOut.hashValue, "error hash")
    let codes = Set(CFNetworkErrors.allCases.map(\.rawValue))
    require(codes.count == CFNetworkErrors.allCases.count, "unique error codes")
    require(CFHostInfoType.addresses.rawValue == 0, "host addresses")
    require(CFHostInfoType.names != .reachability, "host info inequality")
    require(CFStreamErrorHTTP.parseFailure.rawValue == -1, "http parse failure")
    require(CFStreamErrorHTTPAuthentication.badPassword.rawValue == -1002, "auth password")
    require(CFNetDiagnosticStatusValues.noErr.rawValue == 0, "diagnostic noErr")
    require(
        CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue == -66559,
        "diagnostic indeterminate"
    )
    require(CFNetServicesError.badArgument.rawValue == -72004, "net service bad argument")
    require(CFNetServiceMonitorType.TXT.rawValue == 1, "TXT monitor")

    var flags: CFNetServiceBrowserFlags = []
    require(flags.isEmpty, "empty browser flags")
    let inserted = flags.insert(.moreComing)
    require(inserted.inserted, "insert moreComing")
    require(flags.contains(.moreComing), "contains moreComing")
    require(!flags.contains(.isDomain), "does not contain isDomain")
    flags.formUnion(.isDomain)
    require(flags.contains(.isDomain), "union isDomain")
    let intersection = flags.intersection([.moreComing])
    require(intersection.contains(.moreComing) && !intersection.contains(.isDomain), "intersection")
    flags.remove(.moreComing)
    require(!flags.contains(.moreComing), "remove moreComing")
    let renamed = CFNetServiceRegisterFlags.noAutoRename
    require(renamed.contains(.noAutoRename), "noAutoRename")
    require(CFNetServiceBrowserFlags(rawValue: 1) == .moreComing, "rawValue moreComing")
    require(CFNetServiceRegisterFlags(arrayLiteral: .noAutoRename).contains(.noAutoRename), "arrayLiteral")

    require(swiftString(kCFHTTPVersion1_0) == "HTTP/1.0", "HTTP/1.0")
    require(swiftString(kCFHTTPVersion1_1) == "HTTP/1.1", "HTTP/1.1")
    require(swiftString(kCFHTTPVersion2_0) == "HTTP/2.0", "HTTP/2.0")
    require(swiftString(kCFHTTPVersion3_0) == "HTTP/3.0", "HTTP/3.0")
    require(swiftString(kCFHTTPAuthenticationSchemeBasic) == "Basic", "Basic scheme")
    require(swiftString(kCFErrorDomainCFNetwork) == "kCFErrorDomainCFNetwork", "error domain")
    require(swiftString(kCFProxyTypeHTTP) == "kCFProxyTypeHTTP", "proxy type HTTP")
    require(swiftString(kCFURLErrorFailingURLErrorKey) == "NSErrorFailingURLKey", "failing URL key")
    require(kCFStreamErrorDomainHTTP == 4, "HTTP stream domain")
    require(kCFStreamErrorSOCKS4RequestFailed == 91, "SOCKS4 request failed")
    require(kSOCKS5NoAcceptableMethod == 255, "SOCKS5 no method")
    require(CFHTTPMessageGetTypeID() != CFHostGetTypeID(), "distinct type IDs")
    require(CFHTTPAuthenticationGetTypeID() != CFNetServiceGetTypeID(), "auth vs service type ID")
}

private func exerciseHTTPMessage() {
    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(
        nil,
        cfString("POST"),
        url,
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    require(CFHTTPMessageIsRequest(request), "request flag")
    require(CFHTTPMessageIsHeaderComplete(request), "request headers complete")
    require(swiftString(CFHTTPMessageCopyVersion(request).takeRetainedValue()) == "HTTP/1.1", "version")
    require(
        swiftString(CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue()) == "POST",
        "method"
    )
    require(CFHTTPMessageCopyRequestURL(request) != nil, "request URL")
    CFHTTPMessageSetHeaderFieldValue(request, cfString("Content-Type"), cfString("text/plain"))
    CFHTTPMessageSetHeaderFieldValue(request, cfString("X-Test"), cfString("one"))
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(request, cfString("content-type"))!.takeRetainedValue())
            == "text/plain",
        "header lookup is case-insensitive"
    )
    let body = cfDataFromUTF8("hello")
    CFHTTPMessageSetBody(request, body)
    let serialized = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue()
    let serializedBytes = UnsafeBufferPointer(
        start: CFDataGetBytePtr(serialized),
        count: Int(CFDataGetLength(serialized))
    )
    let serializedText = String(bytes: serializedBytes, encoding: .utf8)!
    require(serializedText.hasPrefix("POST /path?q=1 HTTP/1.1\r\n"), "serialized start line")
    require(serializedText.contains("Content-Type: text/plain"), "serialized header")
    require(serializedText.hasSuffix("hello"), "serialized body")

    let added = CFHTTPMessageAddAuthentication(
        request,
        nil,
        cfString("user"),
        cfString("pass"),
        kCFHTTPAuthenticationSchemeBasic,
        false
    )
    require(added, "basic authentication added")
    let authorization = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(request, cfString("Authorization"))!.takeRetainedValue()
    )
    require(authorization.hasPrefix("Basic "), "authorization prefix")

    let digestRejected = CFHTTPMessageAddAuthentication(
        request,
        nil,
        cfString("user"),
        cfString("pass"),
        kCFHTTPAuthenticationSchemeDigest,
        false
    )
    require(!digestRejected, "digest authentication fail-closed")

    let copy = CFHTTPMessageCreateCopy(nil, request).takeRetainedValue()
    require(copy != request, "copy is a distinct object")
    require(CFHTTPMessageIsRequest(copy), "copy remains a request")

    let response = CFHTTPMessageCreateResponse(
        nil,
        401,
        cfString("Unauthorized"),
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    require(!CFHTTPMessageIsRequest(response), "response flag")
    require(CFHTTPMessageGetResponseStatusCode(response) == 401, "status code")
    require(
        swiftString(CFHTTPMessageCopyResponseStatusLine(response)!.takeRetainedValue())
            == "HTTP/1.1 401 Unauthorized",
        "status line"
    )

    let empty = CFHTTPMessageCreateEmpty(nil, false).takeRetainedValue()
    require(!CFHTTPMessageIsHeaderComplete(empty), "empty is incomplete")
    let wire = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nxyz"
    let appended = wire.withCString { pointer in
        CFHTTPMessageAppendBytes(
            empty,
            UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            CFIndex(wire.utf8.count)
        )
    }
    require(appended, "append parsed")
    require(CFHTTPMessageIsHeaderComplete(empty), "parsed headers complete")
    require(CFHTTPMessageGetResponseStatusCode(empty) == 200, "parsed status")
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(empty, cfString("Content-Type"))!.takeRetainedValue())
            == "text/plain",
        "parsed header"
    )
    let parsedBody = CFHTTPMessageCopyBody(empty)!.takeRetainedValue()
    require(CFDataGetLength(parsedBody) == 3, "parsed body length")

    let allHeaders = CFHTTPMessageCopyAllHeaderFields(request)!.takeRetainedValue()
    require(CFDictionaryGetCount(allHeaders) >= 2, "header dictionary")
}

private func exerciseAuthentication() {
    let response = CFHTTPMessageCreateResponse(
        nil,
        401,
        nil,
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationIsValid(auth, nil), "basic auth valid")
    require(CFHTTPAuthenticationRequiresUserNameAndPassword(auth), "requires user/password")
    require(!CFHTTPAuthenticationRequiresAccountDomain(auth), "basic does not need domain")
    require(swiftString(CFHTTPAuthenticationCopyMethod(auth).takeRetainedValue()) == "Basic", "method")
    require(swiftString(CFHTTPAuthenticationCopyRealm(auth).takeRetainedValue()) == "test", "realm")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(CFHTTPAuthenticationAppliesToRequest(auth, request), "applies without domain list")
    var streamError = CFStreamError(domain: 0, error: 0)
    require(
        CFHTTPMessageApplyCredentials(
            request,
            auth,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply basic credentials"
    )

    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\"")
    )
    let digest = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(!CFHTTPAuthenticationIsValid(digest, &streamError), "digest fail-closed")
    require(
        !CFHTTPMessageApplyCredentials(request, digest, cfString("user"), cfString("secret"), &streamError),
        "digest apply fail-closed"
    )
    require(
        streamError.domain == CFIndex(kCFStreamErrorDomainHTTP),
        "digest error domain"
    )
}

private func exerciseHost() {
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

    let copy = CFHostCreateCopy(nil, host).takeRetainedValue()
    require(copy != host, "host copy identity")
    var context = CFHostClientContext()
    require(CFHostSetClient(host, nil, &context), "set client")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFHostScheduleWithRunLoop(host, loop, mode)
        CFHostUnscheduleFromRunLoop(host, loop, mode)
    }
    CFHostCancelInfoResolution(host, .addresses)
}

private func exerciseNetService() {
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

    var browserContext = CFNetServiceClientContext()
    let browser = CFNetServiceBrowserCreate(
        nil,
        { _, _, _, _, _ in },
        &browserContext
    ).takeRetainedValue()
    require(
        !CFNetServiceBrowserSearchForServices(
            browser,
            cfString("local."),
            cfString("_http._tcp"),
            &streamError
        ),
        "browse fail-closed"
    )
    CFNetServiceBrowserInvalidate(browser)

    let monitor = CFNetServiceMonitorCreate(
        nil,
        service,
        { _, _, _, _, _, _ in },
        &browserContext
    ).takeRetainedValue()
    require(!CFNetServiceMonitorStart(monitor, .TXT, &streamError), "monitor fail-closed")
    CFNetServiceMonitorInvalidate(monitor)
    CFNetServiceCancel(service)
}

private func exerciseDiagnostics() {
    let url = CFURLCreateWithString(nil, cfString("https://example.com/"), nil)!
    let diagnostic = CFNetDiagnosticCreateWithURL(kCFAllocatorSystemDefault!, url)
        .takeRetainedValue()
    CFNetDiagnosticSetName(diagnostic, cfString("probe"))
    var description: Unmanaged<CFString>?
    let status = CFNetDiagnosticCopyNetworkStatusPassively(diagnostic, &description)
    require(
        status == CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue),
        "passive status is indeterminate"
    )
    require(swiftString(description!.takeRetainedValue()) == "probe", "diagnostic name")
    require(
        CFNetDiagnosticDiagnoseProblemInteractively(diagnostic)
            == CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.err.rawValue),
        "interactive diagnose unavailable"
    )
}

private func exerciseProxy() {
    setenv("http_proxy", "http://proxy.example.test:8080", 1)
    setenv("no_proxy", "localhost,example.com", 1)
    let settings = CFNetworkCopySystemProxySettings()!.takeRetainedValue()
    let enable = CFDictionaryGetValue(
        settings,
        Unmanaged.passUnretained(kCFNetworkProxiesHTTPEnable).toOpaque()
    )
    require(enable != nil, "proxy enable present")
    let target = CFURLCreateWithString(nil, cfString("http://other.test/"), nil)!
    let proxies = CFNetworkCopyProxiesForURL(target, settings).takeRetainedValue()
    require(CFArrayGetCount(proxies) == 1, "one proxy entry")
    let bypassURL = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let bypass = CFNetworkCopyProxiesForURL(bypassURL, settings).takeRetainedValue()
    guard let firstPointer = CFArrayGetValueAtIndex(bypass, 0) else {
        fatalError("CFNetworkRuntime: missing bypass proxy entry")
    }
    let first = Unmanaged<CFDictionary>.fromOpaque(firstPointer).takeUnretainedValue()
    let typePointer = CFDictionaryGetValue(
        first,
        Unmanaged.passUnretained(kCFProxyTypeKey).toOpaque()
    )!
    let type = Unmanaged<CFString>.fromOpaque(typePointer).takeUnretainedValue()
    require(swiftString(type) == "kCFProxyTypeNone", "no_proxy bypass")

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

    var context = CFStreamClientContext()
    let callbackCount = CallbackCounter()
    let source = CFNetworkExecuteProxyAutoConfigurationScript(
        cfString("function FindProxyForURL() { return 'DIRECT'; }"),
        target,
        { _, _, error in
            require(error != nil, "PAC callback error")
            callbackCount.value += 1
        },
        &context
    )
    require(callbackCount.value == 1, "PAC callback ran once")
    _ = source
    unsetenv("http_proxy")
    unsetenv("no_proxy")
}

private func exerciseStreamsAndFTP() {
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let httpStream = CFReadStreamCreateForHTTPRequest(nil, request).takeRetainedValue()
    _ = httpStream
    let ftpURL = CFURLCreateWithString(nil, cfString("ftp://example.com/file"), nil)!
    _ = CFReadStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()
    _ = CFWriteStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()

    var error = CFStreamError(
        domain: CFIndex(kCFStreamErrorDomainHTTP),
        error: Int32(kCFStreamErrorSOCKS4RequestFailed)
    )
    require(CFSocketStreamSOCKSGetError(&error) == 91, "SOCKS error")
    require(
        CFSocketStreamSOCKSGetErrorSubdomain(&error) == Int32(kCFStreamErrorSOCKSSubDomainNone),
        "SOCKS subdomain"
    )

    let listing = "-rw-r--r-- 1 user group 1234 Jan 01 12:00 README.txt\r\n"
    var parsed: Unmanaged<CFDictionary>?
    let consumed = listing.withCString { pointer in
        CFFTPCreateParsedResourceListing(
            nil,
            UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            CFIndex(listing.utf8.count),
            &parsed
        )
    }
    require(consumed == CFIndex(listing.utf8.count), "FTP listing consumed")
    let dictionary = parsed!.takeRetainedValue()
    let namePointer = CFDictionaryGetValue(
        dictionary,
        Unmanaged.passUnretained(kCFFTPResourceName).toOpaque()
    )!
    let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue()
    require(swiftString(name) == "README.txt", "FTP name")
}
