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
        exerciseRemainingSurface()
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

private func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
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
    require(CFNetworkErrors.cfHostErrorUnknown.rawValue == 2, "host unknown")
    require(CFNetworkErrors.cfsocksErrorUnknownClientVersion.rawValue == 100, "socks client")
    require(CFNetworkErrors.cfsocksErrorUnsupportedServerVersion.rawValue == 101, "socks server")
    require(CFNetworkErrors.cfsocks4ErrorRequestFailed.rawValue == 110, "socks4 failed")
    require(CFNetworkErrors.cfsocks4ErrorIdentdFailed.rawValue == 111, "socks4 identd")
    require(CFNetworkErrors.cfsocks4ErrorIdConflict.rawValue == 112, "socks4 id")
    require(CFNetworkErrors.cfsocks4ErrorUnknownStatusCode.rawValue == 113, "socks4 status")
    require(CFNetworkErrors.cfsocks5ErrorBadState.rawValue == 120, "socks5 state")
    require(CFNetworkErrors.cfsocks5ErrorBadResponseAddr.rawValue == 121, "socks5 addr")
    require(CFNetworkErrors.cfsocks5ErrorBadCredentials.rawValue == 122, "socks5 creds")
    require(CFNetworkErrors.cfsocks5ErrorUnsupportedNegotiationMethod.rawValue == 123, "socks5 method")
    require(CFNetworkErrors.cfsocks5ErrorNoAcceptableMethod.rawValue == 124, "socks5 none")
    require(CFNetworkErrors.cfErrorPACFileError.rawValue == 308, "PAC error")
    require(CFNetworkErrors(rawValue: 0) == nil, "unknown error raw value")
    require(CFNetworkErrors(rawValue: -999) == .cfurlErrorCancelled, "failable cancelled")
    require(CFNetworkErrors.cfurlErrorCancelled != .cfurlErrorBadURL, "error inequality")
    var hasher = Hasher()
    CFNetworkErrors.cfurlErrorTimedOut.hash(into: &hasher)
    require(
        CFNetworkErrors.cfurlErrorTimedOut.hashValue == CFNetworkErrors.cfurlErrorTimedOut.hashValue,
        "error hash"
    )
    let codes = Set(CFNetworkErrors.allCases.map(\.rawValue))
    require(codes.count == CFNetworkErrors.allCases.count, "unique error codes")
    require(CFHostInfoType(rawValue: 0) == .addresses, "host addresses init")
    require(CFHostInfoType.addresses.rawValue == 0, "host addresses")
    require(CFHostInfoType.names != .reachability, "host info inequality")
    require(CFStreamErrorHTTP.parseFailure.rawValue == -1, "http parse failure")
    require(CFStreamErrorHTTP.redirectionLoop.rawValue == -2, "http redirect loop")
    require(CFStreamErrorHTTP.badURL.rawValue == -3, "http bad URL")
    require(CFStreamErrorHTTP(rawValue: -3) == .badURL, "http failable")
    require(CFStreamErrorHTTP.parseFailure != .badURL, "http error inequality")
    require(CFStreamErrorHTTPAuthentication.badPassword.rawValue == -1002, "auth password")
    require(CFStreamErrorHTTPAuthentication.badUserName.rawValue == -1001, "auth username")
    require(
        CFStreamErrorHTTPAuthentication(rawValue: -1001) == .badUserName,
        "auth username init"
    )
    require(
        CFStreamErrorHTTPAuthentication.typeUnsupported != .badPassword,
        "auth error inequality"
    )
    require(CFNetDiagnosticStatusValues.noErr.rawValue == 0, "diagnostic noErr")
    require(CFNetDiagnosticStatusValues.connectionDown.rawValue == -66557, "connection down")
    require(CFNetDiagnosticStatusValues.connectionUp.rawValue == -66555, "connection up")
    require(
        CFNetDiagnosticStatusValues(rawValue: -66557) == .connectionDown,
        "diagnostic failable"
    )
    require(
        CFNetDiagnosticStatusValues.connectionDown != .connectionUp,
        "diagnostic inequality"
    )
    require(
        CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue == -66559,
        "diagnostic indeterminate"
    )
    require(CFNetServicesError.badArgument.rawValue == -72004, "net service bad argument")
    require(CFNetServicesError.cancel.rawValue == -72005, "net service cancel")
    require(CFNetServicesError.collision.rawValue == -72001, "net service collision")
    require(CFNetServicesError.inProgress.rawValue == -72003, "net service in progress")
    require(
        CFNetServicesError.missingRequiredConfiguration.rawValue == -72008,
        "net service missing config"
    )
    require(CFNetServicesError.notFound.rawValue == -72002, "net service not found")
    require(CFNetServicesError.timeout.rawValue == -72007, "net service timeout")
    require(CFNetServicesError(rawValue: -72004) == .badArgument, "net service failable")
    require(CFNetServicesError.cancel != .timeout, "net service inequality")
    require(CFNetServiceMonitorType.TXT.rawValue == 1, "TXT monitor")
    require(CFNetServiceMonitorType(rawValue: 1) == .TXT, "TXT init")
    require(CFNetServiceMonitorType.TXT == CFNetServiceMonitorType.TXT, "TXT equality")

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
    _ = flags.update(with: .isDefault)
    require(flags.contains(.isDefault), "update isDefault")
    flags.insert(.remove)
    require(flags.contains(.remove), "contains remove")
    let unioned = flags.union(.moreComing)
    require(unioned.contains(.moreComing), "union moreComing")
    let symmetric = flags.symmetricDifference(.isDefault)
    require(!symmetric.contains(.isDefault), "symmetric difference")
    let subtracted = flags.subtracting(.remove)
    require(!subtracted.contains(.remove), "subtracting remove")
    flags.subtract(.remove)
    require(!flags.contains(.remove), "subtract remove")
    flags.formIntersection(.isDefault)
    require(flags.contains(.isDefault) && !flags.contains(.isDomain), "formIntersection")
    flags.formSymmetricDifference(.moreComing)
    require(flags.contains(.moreComing), "formSymmetricDifference")
    require(flags.isDisjoint(with: .remove), "isDisjoint")
    require(flags.isSubset(of: [.isDefault, .moreComing, .isDomain]), "isSubset")
    require(flags.isSuperset(of: [.moreComing]), "isSuperset")
    require(
        flags.isStrictSubset(of: [.isDefault, .moreComing, .isDomain, .remove]),
        "isStrictSubset"
    )
    require(!flags.isStrictSuperset(of: flags), "isStrictSuperset self")
    let fromSequence = CFNetServiceBrowserFlags([.moreComing, .isDomain])
    require(fromSequence.contains(.isDomain), "sequence init")
    _ = CFNetServiceBrowserFlags()
    require(CFNetServiceBrowserFlags(rawValue: 1) == .moreComing, "rawValue moreComing")

    var renamed: CFNetServiceRegisterFlags = []
    require(renamed.isEmpty, "register empty")
    _ = renamed.insert(.noAutoRename)
    require(renamed.contains(.noAutoRename), "noAutoRename")
    _ = renamed.remove(.noAutoRename)
    _ = renamed.update(with: .noAutoRename)
    require(renamed.union(.noAutoRename).contains(.noAutoRename), "register union")
    require(renamed.intersection(.noAutoRename).contains(.noAutoRename), "register intersection")
    require(renamed.symmetricDifference([]).contains(.noAutoRename), "register symmetric")
    require(renamed.subtracting(.noAutoRename).isEmpty, "register subtracting")
    renamed.subtract(.noAutoRename)
    renamed.formUnion(.noAutoRename)
    renamed.formIntersection(.noAutoRename)
    renamed.formSymmetricDifference([])
    require(renamed.isDisjoint(with: []), "register disjoint empty")
    require(renamed.isSubset(of: .noAutoRename), "register subset")
    require(renamed.isSuperset(of: []), "register superset")
    require(!renamed.isStrictSubset(of: .noAutoRename), "register strict subset equal")
    require(renamed.isStrictSuperset(of: []), "register strict superset")
    _ = CFNetServiceRegisterFlags([.noAutoRename])
    _ = CFNetServiceRegisterFlags()
    require(CFNetServiceRegisterFlags(arrayLiteral: .noAutoRename).contains(.noAutoRename), "arrayLiteral")
    require(CFNetServiceRegisterFlags(rawValue: 1) == .noAutoRename, "register rawValue")

    require(swiftString(kCFHTTPVersion1_0) == "HTTP/1.0", "HTTP/1.0")
    require(swiftString(kCFHTTPVersion1_1) == "HTTP/1.1", "HTTP/1.1")
    require(swiftString(kCFHTTPVersion2_0) == "HTTP/2.0", "HTTP/2.0")
    require(swiftString(kCFHTTPVersion3_0) == "HTTP/3.0", "HTTP/3.0")
    require(swiftString(kCFHTTPAuthenticationSchemeBasic) == "Basic", "Basic scheme")
    require(swiftString(kCFHTTPAuthenticationSchemeDigest) == "Digest", "Digest scheme")
    require(swiftString(kCFErrorDomainCFNetwork) == "kCFErrorDomainCFNetwork", "error domain")
    require(swiftString(kCFProxyTypeHTTP) == "kCFProxyTypeHTTP", "proxy type HTTP")
    require(swiftString(kCFURLErrorFailingURLErrorKey) == "NSErrorFailingURLKey", "failing URL key")
    require(kCFStreamErrorDomainHTTP == 4, "HTTP stream domain")
    require(kCFStreamErrorSOCKS4RequestFailed == 91, "SOCKS4 request failed")
    require(kCFStreamErrorSOCKS4IdentdFailed == 92, "SOCKS4 identd")
    require(kCFStreamErrorSOCKS4IdConflict == 93, "SOCKS4 id conflict")
    require(kCFStreamErrorSOCKS5BadResponseAddr == 1, "SOCKS5 bad addr")
    require(kCFStreamErrorSOCKS5BadState == 2, "SOCKS5 bad state")
    require(kCFStreamErrorSOCKSUnknownClientVersion == 3, "SOCKS unknown client")
    require(kCFStreamErrorSOCKS4SubDomainResponse == 2, "SOCKS4 subdomain")
    require(kCFStreamErrorSOCKS5SubDomainMethod == 4, "SOCKS5 method subdomain")
    require(kCFStreamErrorSOCKS5SubDomainResponse == 5, "SOCKS5 response subdomain")
    require(kCFStreamErrorSOCKS5SubDomainUserPass == 3, "SOCKS5 userpass subdomain")
    require(kCFStreamErrorSOCKSSubDomainVersionCode == 1, "SOCKS version subdomain")
    require(kSOCKS5NoAcceptableMethod == 255, "SOCKS5 no method")
    require(CFHTTPMessageGetTypeID() != CFHostGetTypeID(), "distinct type IDs")
    require(CFHTTPAuthenticationGetTypeID() != CFNetServiceGetTypeID(), "auth vs service type ID")
    require(
        CFNetServiceBrowserGetTypeID() != CFNetServiceMonitorGetTypeID(),
        "browser vs monitor type ID"
    )
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
    let serializedBytes = cfDataBytes(serialized)
    let serializedText = String(bytes: serializedBytes, encoding: .utf8)!
    require(serializedText.hasPrefix("POST /path?q=1 HTTP/1.1\r\n"), "serialized start line")
    require(serializedText.contains("Content-Type: text/plain"), "serialized header")
    require(serializedText.hasSuffix("hello"), "serialized body")

    let roundTrip = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
    let appendedRoundTrip = serializedBytes.withUnsafeBufferPointer { buffer in
        CFHTTPMessageAppendBytes(roundTrip, buffer.baseAddress!, CFIndex(buffer.count))
    }
    require(appendedRoundTrip, "round-trip append")
    let again = CFHTTPMessageCopySerializedMessage(roundTrip)!.takeRetainedValue()
    require(cfDataBytes(again) == serializedBytes, "serialize parse serialize is byte-exact")

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

    let negotiateRejected = CFHTTPMessageAddAuthentication(
        request,
        nil,
        cfString("user"),
        cfString("pass"),
        kCFHTTPAuthenticationSchemeNegotiate,
        false
    )
    require(!negotiateRejected, "Negotiate authentication fail-closed")

    let copy = CFHTTPMessageCreateCopy(nil, request).takeRetainedValue()
    require(copy != request, "copy is a distinct object")
    require(CFHTTPMessageIsRequest(copy), "copy remains a request")
    require(copy.hashValue == copy.hashValue, "message hashValue")
    var messageHasher = Hasher()
    copy.hash(into: &messageHasher)

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
    let wire = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nX-Fold: foo\r\n\tbar\r\n\r\nxyz"
    for byte in Array(wire.utf8) {
        var current = byte
        require(CFHTTPMessageAppendBytes(empty, &current, 1), "incremental RFC 7230 append")
    }
    require(CFHTTPMessageIsHeaderComplete(empty), "parsed headers complete")
    require(CFHTTPMessageGetResponseStatusCode(empty) == 200, "parsed status")
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(empty, cfString("Content-Type"))!.takeRetainedValue())
            == "text/plain",
        "parsed header"
    )
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(empty, cfString("X-Fold"))!.takeRetainedValue())
            == "foo bar",
        "obs-fold unfolded"
    )
    let parsedBody = CFHTTPMessageCopyBody(empty)!.takeRetainedValue()
    require(CFDataGetLength(parsedBody) == 3, "parsed body length")

    let lfOnly = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
    let lfWire = "GET /star HTTP/1.0\nHost: example.com\n\n"
    require(
        lfWire.withCString { pointer in
            CFHTTPMessageAppendBytes(
                lfOnly,
                UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
                CFIndex(lfWire.utf8.count)
            )
        },
        "LF terminator"
    )
    require(CFHTTPMessageIsHeaderComplete(lfOnly), "LF headers complete")
    require(
        swiftString(CFHTTPMessageCopyRequestMethod(lfOnly)!.takeRetainedValue()) == "GET",
        "LF method"
    )

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
    require(!CFHTTPAuthenticationRequiresOrderedRequests(auth), "basic unordered")
    require(swiftString(CFHTTPAuthenticationCopyMethod(auth).takeRetainedValue()) == "Basic", "method")
    require(swiftString(CFHTTPAuthenticationCopyRealm(auth).takeRetainedValue()) == "test", "realm")
    require(CFArrayGetCount(CFHTTPAuthenticationCopyDomains(auth).takeRetainedValue()) == 0, "no domains")
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
    require(auth.hashValue == auth.hashValue, "auth hashValue")
    var authHasher = Hasher()
    auth.hash(into: &authHasher)
    let otherAuth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(auth != otherAuth, "auth identity inequality")

    let usernameValue = cfString("user")
    let passwordValue = cfString("secret")
    var keyCallbacks = kCFTypeDictionaryKeyCallBacks
    var valueCallbacks = kCFTypeDictionaryValueCallBacks
    let dictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks, &valueCallbacks)!
    CFDictionarySetValue(
        dictionary,
        Unmanaged.passUnretained(kCFHTTPAuthenticationUsername).toOpaque(),
        Unmanaged.passUnretained(usernameValue).toOpaque()
    )
    CFDictionarySetValue(
        dictionary,
        Unmanaged.passUnretained(kCFHTTPAuthenticationPassword).toOpaque(),
        Unmanaged.passUnretained(passwordValue).toOpaque()
    )
    require(
        CFHTTPMessageApplyCredentialDictionary(request, auth, dictionary, &streamError),
        "apply credential dictionary"
    )

    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\", domain=\"example.com /digest\"")
    )
    let digest = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationIsValid(digest, &streamError), "digest is valid")
    require(CFHTTPAuthenticationRequiresOrderedRequests(digest), "digest is ordered")
    require(
        CFArrayGetCount(CFHTTPAuthenticationCopyDomains(digest).takeRetainedValue()) == 2,
        "digest domains"
    )
    let digestURL = CFURLCreateWithString(nil, cfString("http://example.com/digest"), nil)!
    let digestRequest = CFHTTPMessageCreateRequest(
        nil,
        cfString("GET"),
        digestURL,
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    require(
        CFHTTPMessageApplyCredentials(
            digestRequest,
            digest,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply digest credentials"
    )
    let digestHeader = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(digestRequest, cfString("Authorization"))!.takeRetainedValue()
    )
    require(digestHeader.hasPrefix("Digest "), "digest prefix")
    require(digestHeader.contains("response=\"ec6458ea81d81a4ae02cc6a0f78cc718\""), "RFC 7616 MD5 response")
    require(digestHeader.contains("uri=\"/digest\""), "digest uri")
    require(
        CFHTTPMessageAddAuthentication(
            digestRequest,
            response,
            cfString("user"),
            cfString("secret"),
            kCFHTTPAuthenticationSchemeDigest,
            false
        ),
        "AddAuthentication digest"
    )

    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\", algorithm=SHA-256")
    )
    let shaAuth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    let shaRequest = CFHTTPMessageCreateRequest(nil, cfString("GET"), digestURL, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(
        CFHTTPMessageApplyCredentials(
            shaRequest,
            shaAuth,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply SHA-256 digest"
    )
    let shaHeader = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(shaRequest, cfString("Authorization"))!.takeRetainedValue()
    )
    require(
        shaHeader.contains("response=\"b66cc11abd401777adfdaaf45b4cc8e65918912262b063c4ccc9eaa9f6a93358\""),
        "RFC 7616 SHA-256 response"
    )

    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Negotiate realm=\"test\"")
    )
    let negotiate = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(!CFHTTPAuthenticationIsValid(negotiate, &streamError), "Negotiate fail-closed")
    require(
        !CFHTTPMessageApplyCredentials(
            request,
            negotiate,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "Negotiate apply fail-closed"
    )
    require(
        streamError.domain == CFIndex(kCFStreamErrorDomainHTTP),
        "unsupported scheme error domain"
    )
    require(
        streamError.error == CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue,
        "unsupported scheme error code"
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

    var loopback = sockaddr_in()
    loopback.sin_family = sa_family_t(AF_INET)
    loopback.sin_addr = in_addr(
        s_addr: "127.0.0.1".withCString { inet_addr($0) }
    )
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

    let copy = CFHostCreateCopy(nil, host).takeRetainedValue()
    require(copy != host, "host copy identity")
    require(copy.hashValue == copy.hashValue, "host hashValue")
    var hostHasher = Hasher()
    copy.hash(into: &hostHasher)
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
    require(CFNetServiceGetTargetHost(service) == nil, "no target before resolve")
    require(CFNetServiceGetAddressing(service) == nil, "no addresses before resolve")
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

    let copy = CFNetServiceCreateCopy(nil, service).takeRetainedValue()
    require(copy != service, "service copy identity")
    require(copy.hashValue == copy.hashValue, "service hashValue")
    var serviceHasher = Hasher()
    copy.hash(into: &serviceHasher)
    require(swiftString(CFNetServiceGetName(copy).takeRetainedValue()) == "OpenUIKit", "copy name")

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
    require(CFNetServiceSetClient(service, { _, _, _ in }, &serviceContext), "set service client")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFNetServiceScheduleWithRunLoop(service, loop, mode)
        CFNetServiceUnscheduleFromRunLoop(service, loop, mode)
    }

    var browserContext = CFNetServiceClientContext()
    let browser = CFNetServiceBrowserCreate(
        nil,
        { _, _, _, _, _ in },
        &browserContext
    ).takeRetainedValue()
    require(browser.hashValue == browser.hashValue, "browser hashValue")
    var browserHasher = Hasher()
    browser.hash(into: &browserHasher)
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

    let monitor = CFNetServiceMonitorCreate(
        nil,
        service,
        { _, _, _, _, _, _ in },
        &browserContext
    ).takeRetainedValue()
    require(monitor.hashValue == monitor.hashValue, "monitor hashValue")
    var monitorHasher = Hasher()
    monitor.hash(into: &monitorHasher)
    require(!CFNetServiceMonitorStart(monitor, .TXT, &streamError), "monitor fail-closed")
    if let loop = CFRunLoopGetCurrent(), let mode = kCFRunLoopDefaultMode {
        CFNetServiceMonitorScheduleWithRunLoop(monitor, loop, mode)
        CFNetServiceMonitorStop(monitor, &streamError)
        CFNetServiceMonitorUnscheduleFromRunLoop(monitor, loop, mode)
    }
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
    let fromStreams = CFNetDiagnosticCreateWithStreams(nil, nil, nil).takeRetainedValue()
    require(fromStreams != diagnostic, "stream diagnostic identity")
    require(fromStreams.hashValue == fromStreams.hashValue, "diagnostic hashValue")
    var diagnosticHasher = Hasher()
    fromStreams.hash(into: &diagnosticHasher)
}

private func exerciseProxy() {
    setenv("http_proxy", "http://proxy.example.test:8080", 1)
    setenv("no_proxy", "localhost,example.com", 1)
    let settings = CFNetworkCopySystemProxySettings()!.takeRetainedValue()
    require(CFDictionaryGetCount(settings) == 0, "system proxy settings are empty")
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

    let urlCount = CallbackCounter()
    let pacURL = CFURLCreateWithString(nil, cfString("http://example.com/proxy.pac"), nil)!
    let urlSource = CFNetworkExecuteProxyAutoConfigurationURL(
        pacURL,
        target,
        { _, _, error in
            require(error != nil, "PAC URL callback error")
            urlCount.value += 1
        },
        &context
    )
    require(urlCount.value == 1, "PAC URL callback ran once")
    _ = urlSource
    unsetenv("http_proxy")
    unsetenv("no_proxy")
}

private func exerciseStreamsAndFTP() {
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let httpStream = CFReadStreamCreateForHTTPRequest(nil, request).takeRetainedValue()
    _ = httpStream
    var dummy: UInt8 = 0
    let emptyBody = CFReadStreamCreateWithBytesNoCopy(nil, &dummy, 0, kCFAllocatorNull)!
    _ = CFReadStreamCreateForStreamedHTTPRequest(nil, request, emptyBody).takeRetainedValue()
    let ftpURL = CFURLCreateWithString(nil, cfString("ftp://example.com/file"), nil)!
    _ = CFReadStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()
    _ = CFWriteStreamCreateWithFTPURL(nil, ftpURL).takeRetainedValue()

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
    let datePointer = CFDictionaryGetValue(
        dictionary,
        Unmanaged.passUnretained(kCFFTPResourceModDate).toOpaque()
    )!
    let date = Unmanaged<CFString>.fromOpaque(datePointer).takeUnretainedValue()
    require(swiftString(date) == "Jan 01 12:00", "FTP mod date")

    let linkListing = "lrwxrwxrwx 1 user group 4 Jan 01 12:00 link -> dest\r\n"
    var linkParsed: Unmanaged<CFDictionary>?
    _ = linkListing.withCString { pointer in
        CFFTPCreateParsedResourceListing(
            nil,
            UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            CFIndex(linkListing.utf8.count),
            &linkParsed
        )
    }
    let linkDictionary = linkParsed!.takeRetainedValue()
    let linkPointer = CFDictionaryGetValue(
        linkDictionary,
        Unmanaged.passUnretained(kCFFTPResourceLink).toOpaque()
    )!
    let link = Unmanaged<CFString>.fromOpaque(linkPointer).takeUnretainedValue()
    require(swiftString(link) == "dest", "FTP link")
}

private func exerciseRemainingSurface() {
    let constants: [(CFString, String)] = [
        (kCFDNSServiceFailureKey, "kCFDNSServiceFailureKey"),
        (kCFErrorDomainWinSock, "kCFErrorDomainWinSock"),
        (kCFFTPResourceLink, "kCFFTPResourceLink"),
        (kCFFTPResourceModDate, "kCFFTPResourceModDate"),
        (kCFFTPStatusCodeKey, "kCFFTPStatusCodeKey"),
        (kCFGetAddrInfoFailureKey, "kCFGetAddrInfoFailureKey"),
        (kCFHTTPAuthenticationAccountDomain, "kCFHTTPAuthenticationAccountDomain"),
        (kCFHTTPAuthenticationPassword, "kCFHTTPAuthenticationPassword"),
        (kCFHTTPAuthenticationSchemeKerberos, "Kerberos"),
        (kCFHTTPAuthenticationSchemeNTLM, "NTLM"),
        (kCFHTTPAuthenticationSchemeNegotiate, "Negotiate"),
        (kCFHTTPAuthenticationSchemeNegotiate2, "Negotiate2"),
        (kCFHTTPAuthenticationSchemeXMobileMeAuthToken, "X-MobileMe-AuthToken"),
        (kCFHTTPAuthenticationUsername, "kCFHTTPAuthenticationUsername"),
        (kCFNetworkProxiesProxyAutoConfigEnable, "kCFNetworkProxiesProxyAutoConfigEnable"),
        (kCFNetworkProxiesProxyAutoConfigJavaScript, "kCFNetworkProxiesProxyAutoConfigJavaScript"),
        (kCFNetworkProxiesProxyAutoConfigURLString, "kCFNetworkProxiesProxyAutoConfigURLString"),
        (kCFProxyAutoConfigurationHTTPResponseKey, "kCFProxyAutoConfigurationHTTPResponseKey"),
        (kCFProxyAutoConfigurationJavaScriptKey, "kCFProxyAutoConfigurationJavaScriptKey"),
        (kCFProxyAutoConfigurationURLKey, "kCFProxyAutoConfigurationURLKey"),
        (kCFProxyPasswordKey, "kCFProxyPasswordKey"),
        (kCFProxyTypeAutoConfigurationJavaScript, "kCFProxyTypeAutoConfigurationJavaScript"),
        (kCFProxyTypeAutoConfigurationURL, "kCFProxyTypeAutoConfigurationURL"),
        (kCFProxyTypeFTP, "kCFProxyTypeFTP"),
        (kCFProxyTypeSOCKS, "kCFProxyTypeSOCKS"),
        (kCFProxyUsernameKey, "kCFProxyUsernameKey"),
        (kCFSOCKSNegotiationMethodKey, "kCFSOCKSNegotiationMethodKey"),
        (kCFSOCKSStatusCodeKey, "kCFSOCKSStatusCodeKey"),
        (kCFSOCKSVersionKey, "kCFSOCKSVersionKey"),
        (kCFStreamNetworkServiceType, "kCFStreamNetworkServiceType"),
        (kCFStreamNetworkServiceTypeAVStreaming, "kCFStreamNetworkServiceTypeAVStreaming"),
        (kCFStreamNetworkServiceTypeBackground, "kCFStreamNetworkServiceTypeBackground"),
        (kCFStreamNetworkServiceTypeCallSignaling, "kCFStreamNetworkServiceTypeCallSignaling"),
        (kCFStreamNetworkServiceTypeResponsiveAV, "kCFStreamNetworkServiceTypeResponsiveAV"),
        (kCFStreamNetworkServiceTypeResponsiveData, "kCFStreamNetworkServiceTypeResponsiveData"),
        (kCFStreamNetworkServiceTypeVideo, "kCFStreamNetworkServiceTypeVideo"),
        (kCFStreamNetworkServiceTypeVoIP, "kCFStreamNetworkServiceTypeVoIP"),
        (kCFStreamNetworkServiceTypeVoice, "kCFStreamNetworkServiceTypeVoice"),
        (kCFStreamPropertyAllowConstrainedNetworkAccess, "kCFStreamPropertyAllowConstrainedNetworkAccess"),
        (kCFStreamPropertyAllowExpensiveNetworkAccess, "kCFStreamPropertyAllowExpensiveNetworkAccess"),
        (kCFStreamPropertyConnectionIsCellular, "kCFStreamPropertyConnectionIsCellular"),
        (kCFStreamPropertyConnectionIsExpensive, "kCFStreamPropertyConnectionIsExpensive"),
        (kCFStreamPropertyFTPAttemptPersistentConnection, "kCFStreamPropertyFTPAttemptPersistentConnection"),
        (kCFStreamPropertyFTPFetchResourceInfo, "kCFStreamPropertyFTPFetchResourceInfo"),
        (kCFStreamPropertyFTPFileTransferOffset, "kCFStreamPropertyFTPFileTransferOffset"),
        (kCFStreamPropertyFTPPassword, "kCFStreamPropertyFTPPassword"),
        (kCFStreamPropertyFTPProxy, "kCFStreamPropertyFTPProxy"),
        (kCFStreamPropertyFTPProxyHost, "kCFStreamPropertyFTPProxyHost"),
        (kCFStreamPropertyFTPProxyPassword, "kCFStreamPropertyFTPProxyPassword"),
        (kCFStreamPropertyFTPProxyPort, "kCFStreamPropertyFTPProxyPort"),
        (kCFStreamPropertyFTPProxyUser, "kCFStreamPropertyFTPProxyUser"),
        (kCFStreamPropertyFTPResourceSize, "kCFStreamPropertyFTPResourceSize"),
        (kCFStreamPropertyFTPUsePassiveMode, "kCFStreamPropertyFTPUsePassiveMode"),
        (kCFStreamPropertyFTPUserName, "kCFStreamPropertyFTPUserName"),
        (kCFStreamPropertyHTTPAttemptPersistentConnection, "kCFStreamPropertyHTTPAttemptPersistentConnection"),
        (kCFStreamPropertyHTTPFinalRequest, "kCFStreamPropertyHTTPFinalRequest"),
        (kCFStreamPropertyHTTPFinalURL, "kCFStreamPropertyHTTPFinalURL"),
        (kCFStreamPropertyHTTPProxy, "kCFStreamPropertyHTTPProxy"),
        (kCFStreamPropertyHTTPProxyHost, "kCFStreamPropertyHTTPProxyHost"),
        (kCFStreamPropertyHTTPProxyPort, "kCFStreamPropertyHTTPProxyPort"),
        (kCFStreamPropertyHTTPRequestBytesWrittenCount, "kCFStreamPropertyHTTPRequestBytesWrittenCount"),
        (kCFStreamPropertyHTTPResponseHeader, "kCFStreamPropertyHTTPResponseHeader"),
        (kCFStreamPropertyHTTPSProxyHost, "kCFStreamPropertyHTTPSProxyHost"),
        (kCFStreamPropertyHTTPSProxyPort, "kCFStreamPropertyHTTPSProxyPort"),
        (kCFStreamPropertyHTTPShouldAutoredirect, "kCFStreamPropertyHTTPShouldAutoredirect"),
        (kCFStreamPropertyNoCellular, "kCFStreamPropertyNoCellular"),
        (kCFStreamPropertyProxyLocalBypass, "kCFStreamPropertyProxyLocalBypass"),
        (kCFStreamPropertySSLContext, "kCFStreamPropertySSLContext"),
        (kCFStreamPropertySSLPeerTrust, "kCFStreamPropertySSLPeerTrust"),
        (kCFStreamPropertySSLSettings, "kCFStreamPropertySSLSettings"),
        (kCFStreamPropertySocketExtendedBackgroundIdleMode, "kCFStreamPropertySocketExtendedBackgroundIdleMode"),
        (kCFStreamPropertySocketRemoteHost, "kCFStreamPropertySocketRemoteHost"),
        (kCFStreamPropertySocketRemoteNetService, "kCFStreamPropertySocketRemoteNetService"),
        (kCFStreamSSLCertificates, "kCFStreamSSLCertificates"),
        (kCFStreamSSLIsServer, "kCFStreamSSLIsServer"),
        (kCFStreamSSLLevel, "kCFStreamSSLLevel"),
        (kCFStreamSSLPeerName, "kCFStreamSSLPeerName"),
        (kCFStreamSSLValidatesCertificateChain, "kCFStreamSSLValidatesCertificateChain"),
        (kCFURLErrorFailingURLStringErrorKey, "NSErrorFailingURLStringKey"),
    ]
    for (constant, expected) in constants {
        require(swiftString(constant) == expected, "constant \(expected)")
    }
    require(kCFStreamErrorDomainFTP == 11, "FTP stream domain")
    require(kCFStreamErrorDomainMach == 14, "Mach stream domain")
    require(kCFStreamErrorDomainNetDB == 12, "NetDB stream domain")
    require(kCFStreamErrorDomainSystemConfiguration == 13, "SC stream domain")
    require(kCFStreamErrorDomainWinSock == 15, "WinSock stream domain")
    _ = CFHostInfoType.addresses.hashValue
    _ = CFNetDiagnosticStatusValues.noErr.hashValue
    _ = CFNetServiceMonitorType.TXT.hashValue
    _ = CFNetServicesError.unknown.hashValue
    _ = CFStreamErrorHTTP.parseFailure.hashValue
    _ = CFStreamErrorHTTPAuthentication.typeUnsupported.hashValue
    var hasher = Hasher()
    CFHostInfoType.names.hash(into: &hasher)
    CFNetDiagnosticStatusValues.err.hash(into: &hasher)
    CFNetServiceMonitorType.TXT.hash(into: &hasher)
    CFNetServicesError.invalid.hash(into: &hasher)
    CFStreamErrorHTTP.redirectionLoop.hash(into: &hasher)
    CFStreamErrorHTTPAuthentication.badUserName.hash(into: &hasher)
}
