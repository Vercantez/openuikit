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

func testCFNetworkErrorRawValues() {

    let pairs: [(CFNetworkErrors, Int32)] = [
        (.cfHostErrorHostNotFound, 1),
        (.cfHostErrorUnknown, 2),
        (.cfsocksErrorUnknownClientVersion, 100),
        (.cfsocksErrorUnsupportedServerVersion, 101),
        (.cfsocks4ErrorRequestFailed, 110),
        (.cfsocks4ErrorIdentdFailed, 111),
        (.cfsocks4ErrorIdConflict, 112),
        (.cfsocks4ErrorUnknownStatusCode, 113),
        (.cfsocks5ErrorBadState, 120),
        (.cfsocks5ErrorBadResponseAddr, 121),
        (.cfsocks5ErrorBadCredentials, 122),
        (.cfsocks5ErrorUnsupportedNegotiationMethod, 123),
        (.cfsocks5ErrorNoAcceptableMethod, 124),
        (.cfftpErrorUnexpectedStatusCode, 200),
        (.cfErrorHTTPAuthenticationTypeUnsupported, 300),
        (.cfErrorHTTPBadCredentials, 301),
        (.cfErrorHTTPConnectionLost, 302),
        (.cfErrorHTTPParseFailure, 303),
        (.cfErrorHTTPRedirectionLoopDetected, 304),
        (.cfErrorHTTPBadURL, 305),
        (.cfErrorHTTPProxyConnectionFailure, 306),
        (.cfErrorHTTPBadProxyCredentials, 307),
        (.cfErrorPACFileError, 308),
        (.cfErrorPACFileAuth, 309),
        (.cfErrorHTTPSProxyConnectionFailure, 310),
        (.cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod, 311),
        (.cfurlErrorBackgroundSessionInUseByAnotherProcess, -996),
        (.cfurlErrorBackgroundSessionWasDisconnected, -997),
        (.cfurlErrorUnknown, -998),
        (.cfurlErrorCancelled, -999),
        (.cfurlErrorBadURL, -1000),
        (.cfurlErrorTimedOut, -1001),
        (.cfurlErrorUnsupportedURL, -1002),
        (.cfurlErrorCannotFindHost, -1003),
        (.cfurlErrorCannotConnectToHost, -1004),
        (.cfurlErrorNetworkConnectionLost, -1005),
        (.cfurlErrorDNSLookupFailed, -1006),
        (.cfurlErrorHTTPTooManyRedirects, -1007),
        (.cfurlErrorResourceUnavailable, -1008),
        (.cfurlErrorNotConnectedToInternet, -1009),
        (.cfurlErrorRedirectToNonExistentLocation, -1010),
        (.cfurlErrorBadServerResponse, -1011),
        (.cfurlErrorUserCancelledAuthentication, -1012),
        (.cfurlErrorUserAuthenticationRequired, -1013),
        (.cfurlErrorZeroByteResource, -1014),
        (.cfurlErrorCannotDecodeRawData, -1015),
        (.cfurlErrorCannotDecodeContentData, -1016),
        (.cfurlErrorCannotParseResponse, -1017),
        (.cfurlErrorInternationalRoamingOff, -1018),
        (.cfurlErrorCallIsActive, -1019),
        (.cfurlErrorDataNotAllowed, -1020),
        (.cfurlErrorRequestBodyStreamExhausted, -1021),
        (.cfurlErrorAppTransportSecurityRequiresSecureConnection, -1022),
        (.cfurlErrorFileDoesNotExist, -1100),
        (.cfurlErrorFileIsDirectory, -1101),
        (.cfurlErrorNoPermissionsToReadFile, -1102),
        (.cfurlErrorDataLengthExceedsMaximum, -1103),
        (.cfurlErrorFileOutsideSafeArea, -1104),
        (.cfurlErrorSecureConnectionFailed, -1200),
        (.cfurlErrorServerCertificateHasBadDate, -1201),
        (.cfurlErrorServerCertificateUntrusted, -1202),
        (.cfurlErrorServerCertificateHasUnknownRoot, -1203),
        (.cfurlErrorServerCertificateNotYetValid, -1204),
        (.cfurlErrorClientCertificateRejected, -1205),
        (.cfurlErrorClientCertificateRequired, -1206),
        (.cfurlErrorCannotLoadFromNetwork, -2000),
        (.cfurlErrorCannotCreateFile, -3000),
        (.cfurlErrorCannotOpenFile, -3001),
        (.cfurlErrorCannotCloseFile, -3002),
        (.cfurlErrorCannotWriteToFile, -3003),
        (.cfurlErrorCannotRemoveFile, -3004),
        (.cfurlErrorCannotMoveFile, -3005),
        (.cfurlErrorDownloadDecodingFailedMidStream, -3006),
        (.cfurlErrorDownloadDecodingFailedToComplete, -3007),
        (.cfhttpCookieCannotParseCookieFile, -4000),
        (.cfNetServiceErrorUnknown, -72000),
        (.cfNetServiceErrorCollision, -72001),
        (.cfNetServiceErrorNotFound, -72002),
        (.cfNetServiceErrorInProgress, -72003),
        (.cfNetServiceErrorBadArgument, -72004),
        (.cfNetServiceErrorCancel, -72005),
        (.cfNetServiceErrorInvalid, -72006),
        (.cfNetServiceErrorTimeout, -72007),
        (.cfNetServiceErrorDNSServiceFailure, -73000),
    ]
    for (error, raw) in pairs {
        require(error.rawValue == raw, "CFNetworkErrors raw \(raw)")
        require(CFNetworkErrors(rawValue: raw) == error, "CFNetworkErrors init \(raw)")
    }
    require(CFNetworkErrors(rawValue: 0) == nil, "unknown error raw value")
    require(
        Set(CFNetworkErrors.allCases.map(\.rawValue)).count == CFNetworkErrors.allCases.count,
        "unique error codes"
    )
}

func testCFNetworkErrorHashable() {

    require(CFNetworkErrors.cfurlErrorCancelled != .cfurlErrorBadURL, "error inequality")
    require(CFNetworkErrors.cfurlErrorCancelled == .cfurlErrorCancelled, "error equality")
    var hasher = Hasher()
    CFNetworkErrors.cfurlErrorTimedOut.hash(into: &hasher)
    _ = hasher.finalize()
    require(
        CFNetworkErrors.cfurlErrorTimedOut.hashValue == CFNetworkErrors.cfurlErrorTimedOut.hashValue,
        "error hashValue"
    )
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

func testCFNetServiceMonitorTypeRawValues() {

    require(CFNetServiceMonitorType.TXT.rawValue == 1, "TXT monitor")
    require(CFNetServiceMonitorType(rawValue: 1) == .TXT, "TXT init")
    require(CFNetServiceMonitorType.TXT == CFNetServiceMonitorType.TXT, "TXT equality")
    require(CFNetServiceMonitorType.TXT.hashValue == CFNetServiceMonitorType.TXT.hashValue, "TXT hashValue")
    var hasher = Hasher()
    CFNetServiceMonitorType.TXT.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCFNetServiceBrowserFlagAlgebra() {

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
    require(CFNetServiceBrowserFlags.moreComing != .remove, "browser flag inequality")
}

func testCFNetServiceRegisterFlagAlgebra() {

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
    require(CFNetServiceRegisterFlags.noAutoRename != CFNetServiceRegisterFlags(), "register inequality")
}

func testCFHTTPVersionConstants() {

    require(swiftString(kCFHTTPVersion1_0) == "HTTP/1.0", "HTTP/1.0")
    require(swiftString(kCFHTTPVersion1_1) == "HTTP/1.1", "HTTP/1.1")
    require(swiftString(kCFHTTPVersion2_0) == "HTTP/2.0", "HTTP/2.0")
    require(swiftString(kCFHTTPVersion3_0) == "HTTP/3.0", "HTTP/3.0")
}

func testCFHTTPAuthenticationSchemeConstants() {

    require(swiftString(kCFHTTPAuthenticationSchemeBasic) == "Basic", "Basic scheme")
    require(swiftString(kCFHTTPAuthenticationSchemeDigest) == "Digest", "Digest scheme")
    require(swiftString(kCFHTTPAuthenticationSchemeKerberos) == "Kerberos", "Kerberos")
    require(swiftString(kCFHTTPAuthenticationSchemeNTLM) == "NTLM", "NTLM")
    require(swiftString(kCFHTTPAuthenticationSchemeNegotiate) == "Negotiate", "Negotiate")
    require(swiftString(kCFHTTPAuthenticationSchemeNegotiate2) == "Negotiate2", "Negotiate2")
    require(swiftString(kCFHTTPAuthenticationSchemeXMobileMeAuthToken) == "X-MobileMe-AuthToken", "XMM")
    require(swiftString(kCFHTTPAuthenticationUsername) == "kCFHTTPAuthenticationUsername", "username key")
    require(swiftString(kCFHTTPAuthenticationPassword) == "kCFHTTPAuthenticationPassword", "password key")
    require(swiftString(kCFHTTPAuthenticationAccountDomain) == "kCFHTTPAuthenticationAccountDomain", "domain key")
}

func testCFErrorDomainConstants() {

    require(swiftString(kCFErrorDomainCFNetwork) == "kCFErrorDomainCFNetwork", "error domain")
    require(swiftString(kCFErrorDomainWinSock) == "kCFErrorDomainWinSock", "winsock domain")
    require(swiftString(kCFDNSServiceFailureKey) == "kCFDNSServiceFailureKey", "dns failure key")
    require(swiftString(kCFGetAddrInfoFailureKey) == "kCFGetAddrInfoFailureKey", "getaddrinfo key")
    require(swiftString(kCFURLErrorFailingURLErrorKey) == "NSErrorFailingURLKey", "failing URL key")
    require(swiftString(kCFURLErrorFailingURLStringErrorKey) == "NSErrorFailingURLStringKey", "failing URL string")
    require(swiftString(kCFFTPStatusCodeKey) == "kCFFTPStatusCodeKey", "ftp status key")
}

func testCFProxyKeyConstants() {

    require(swiftString(kCFProxyTypeKey) == "kCFProxyTypeKey", "type key")
    require(swiftString(kCFProxyHostNameKey) == "kCFProxyHostNameKey", "host")
    require(swiftString(kCFProxyPortNumberKey) == "kCFProxyPortNumberKey", "port")
    require(swiftString(kCFProxyAutoConfigurationURLKey) == "kCFProxyAutoConfigurationURLKey", "pac url")
    require(swiftString(kCFProxyAutoConfigurationJavaScriptKey) == "kCFProxyAutoConfigurationJavaScriptKey", "pac js")
    require(swiftString(kCFProxyUsernameKey) == "kCFProxyUsernameKey", "user")
    require(swiftString(kCFProxyPasswordKey) == "kCFProxyPasswordKey", "pass")
    require(swiftString(kCFProxyTypeNone) == "kCFProxyTypeNone", "none")
    require(swiftString(kCFProxyTypeHTTP) == "kCFProxyTypeHTTP", "http")
    require(swiftString(kCFProxyTypeHTTPS) == "kCFProxyTypeHTTPS", "https")
    require(swiftString(kCFProxyTypeSOCKS) == "kCFProxyTypeSOCKS", "socks")
    require(swiftString(kCFProxyTypeFTP) == "kCFProxyTypeFTP", "ftp")
    require(swiftString(kCFProxyTypeAutoConfigurationURL) == "kCFProxyTypeAutoConfigurationURL", "auto url")
    require(swiftString(kCFProxyTypeAutoConfigurationJavaScript) == "kCFProxyTypeAutoConfigurationJavaScript", "auto js")
    require(swiftString(kCFProxyAutoConfigurationHTTPResponseKey) == "kCFProxyAutoConfigurationHTTPResponseKey", "pac http")
    require(swiftString(kCFNetworkProxiesHTTPEnable) == "kCFNetworkProxiesHTTPEnable", "http enable")
    require(swiftString(kCFNetworkProxiesHTTPPort) == "kCFNetworkProxiesHTTPPort", "http port")
    require(swiftString(kCFNetworkProxiesHTTPProxy) == "kCFNetworkProxiesHTTPProxy", "http proxy")
    require(swiftString(kCFNetworkProxiesProxyAutoConfigEnable) == "kCFNetworkProxiesProxyAutoConfigEnable", "pac enable")
    require(swiftString(kCFNetworkProxiesProxyAutoConfigJavaScript) == "kCFNetworkProxiesProxyAutoConfigJavaScript", "pac js setting")
    require(swiftString(kCFNetworkProxiesProxyAutoConfigURLString) == "kCFNetworkProxiesProxyAutoConfigURLString", "pac url setting")
}

func testCFFTPResourceConstants() {

    require(swiftString(kCFFTPResourceMode) == "kCFFTPResourceMode", "mode")
    require(swiftString(kCFFTPResourceName) == "kCFFTPResourceName", "name")
    require(swiftString(kCFFTPResourceOwner) == "kCFFTPResourceOwner", "owner")
    require(swiftString(kCFFTPResourceGroup) == "kCFFTPResourceGroup", "group")
    require(swiftString(kCFFTPResourceLink) == "kCFFTPResourceLink", "link")
    require(swiftString(kCFFTPResourceSize) == "kCFFTPResourceSize", "size")
    require(swiftString(kCFFTPResourceType) == "kCFFTPResourceType", "type")
    require(swiftString(kCFFTPResourceModDate) == "kCFFTPResourceModDate", "mod")
}

func testCFSOCKSErrorConstants() {

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
    require(kCFStreamErrorSOCKSSubDomainNone == 0, "SOCKS subdomain none")
    require(kCFStreamErrorSOCKSSubDomainVersionCode == 1, "SOCKS version subdomain")
    require(kSOCKS5NoAcceptableMethod == 255, "SOCKS5 no method")
    require(swiftString(kCFSOCKSNegotiationMethodKey) == "kCFSOCKSNegotiationMethodKey", "neg method")
    require(swiftString(kCFSOCKSStatusCodeKey) == "kCFSOCKSStatusCodeKey", "status")
    require(swiftString(kCFSOCKSVersionKey) == "kCFSOCKSVersionKey", "version")
}

func testCFStreamErrorDomainConstants() {

    require(kCFStreamErrorDomainHTTP == 4, "HTTP stream domain")
    require(kCFStreamErrorDomainFTP == 11, "FTP stream domain")
    require(kCFStreamErrorDomainNetServices == 10, "net services domain")
    require(kCFStreamErrorDomainNetDB == 12, "NetDB stream domain")
    require(kCFStreamErrorDomainSystemConfiguration == 13, "SC stream domain")
    require(kCFStreamErrorDomainMach == 14, "Mach stream domain")
    require(kCFStreamErrorDomainWinSock == 15, "WinSock stream domain")
}

func testCFStreamNetworkServiceTypeConstants() {

    require(swiftString(kCFStreamNetworkServiceType) == "kCFStreamNetworkServiceType", "type")
    require(swiftString(kCFStreamNetworkServiceTypeAVStreaming) == "kCFStreamNetworkServiceTypeAVStreaming", "av")
    require(swiftString(kCFStreamNetworkServiceTypeBackground) == "kCFStreamNetworkServiceTypeBackground", "bg")
    require(swiftString(kCFStreamNetworkServiceTypeCallSignaling) == "kCFStreamNetworkServiceTypeCallSignaling", "call")
    require(swiftString(kCFStreamNetworkServiceTypeResponsiveAV) == "kCFStreamNetworkServiceTypeResponsiveAV", "rav")
    require(swiftString(kCFStreamNetworkServiceTypeResponsiveData) == "kCFStreamNetworkServiceTypeResponsiveData", "rdata")
    require(swiftString(kCFStreamNetworkServiceTypeVideo) == "kCFStreamNetworkServiceTypeVideo", "video")
    require(swiftString(kCFStreamNetworkServiceTypeVoIP) == "kCFStreamNetworkServiceTypeVoIP", "voip")
    require(swiftString(kCFStreamNetworkServiceTypeVoice) == "kCFStreamNetworkServiceTypeVoice", "voice")
}

func testCFStreamPropertyFTPConstants() {

    require(swiftString(kCFStreamPropertyFTPAttemptPersistentConnection) == "kCFStreamPropertyFTPAttemptPersistentConnection", "persist")
    require(swiftString(kCFStreamPropertyFTPFetchResourceInfo) == "kCFStreamPropertyFTPFetchResourceInfo", "fetch")
    require(swiftString(kCFStreamPropertyFTPFileTransferOffset) == "kCFStreamPropertyFTPFileTransferOffset", "offset")
    require(swiftString(kCFStreamPropertyFTPPassword) == "kCFStreamPropertyFTPPassword", "pass")
    require(swiftString(kCFStreamPropertyFTPProxy) == "kCFStreamPropertyFTPProxy", "proxy")
    require(swiftString(kCFStreamPropertyFTPProxyHost) == "kCFStreamPropertyFTPProxyHost", "proxy host")
    require(swiftString(kCFStreamPropertyFTPProxyPassword) == "kCFStreamPropertyFTPProxyPassword", "proxy pass")
    require(swiftString(kCFStreamPropertyFTPProxyPort) == "kCFStreamPropertyFTPProxyPort", "proxy port")
    require(swiftString(kCFStreamPropertyFTPProxyUser) == "kCFStreamPropertyFTPProxyUser", "proxy user")
    require(swiftString(kCFStreamPropertyFTPResourceSize) == "kCFStreamPropertyFTPResourceSize", "size")
    require(swiftString(kCFStreamPropertyFTPUsePassiveMode) == "kCFStreamPropertyFTPUsePassiveMode", "pasv")
    require(swiftString(kCFStreamPropertyFTPUserName) == "kCFStreamPropertyFTPUserName", "user")
}

func testCFStreamPropertyHTTPConstants() {

    require(swiftString(kCFStreamPropertyHTTPAttemptPersistentConnection) == "kCFStreamPropertyHTTPAttemptPersistentConnection", "persist")
    require(swiftString(kCFStreamPropertyHTTPFinalRequest) == "kCFStreamPropertyHTTPFinalRequest", "final req")
    require(swiftString(kCFStreamPropertyHTTPFinalURL) == "kCFStreamPropertyHTTPFinalURL", "final url")
    require(swiftString(kCFStreamPropertyHTTPProxy) == "kCFStreamPropertyHTTPProxy", "proxy")
    require(swiftString(kCFStreamPropertyHTTPProxyHost) == "kCFStreamPropertyHTTPProxyHost", "proxy host")
    require(swiftString(kCFStreamPropertyHTTPProxyPort) == "kCFStreamPropertyHTTPProxyPort", "proxy port")
    require(swiftString(kCFStreamPropertyHTTPRequestBytesWrittenCount) == "kCFStreamPropertyHTTPRequestBytesWrittenCount", "bytes")
    require(swiftString(kCFStreamPropertyHTTPResponseHeader) == "kCFStreamPropertyHTTPResponseHeader", "resp")
    require(swiftString(kCFStreamPropertyHTTPSProxyHost) == "kCFStreamPropertyHTTPSProxyHost", "https host")
    require(swiftString(kCFStreamPropertyHTTPSProxyPort) == "kCFStreamPropertyHTTPSProxyPort", "https port")
    require(swiftString(kCFStreamPropertyHTTPShouldAutoredirect) == "kCFStreamPropertyHTTPShouldAutoredirect", "redir")
}

func testCFStreamPropertySSLAndAccessConstants() {

    require(swiftString(kCFStreamPropertyAllowConstrainedNetworkAccess) == "kCFStreamPropertyAllowConstrainedNetworkAccess", "constrained")
    require(swiftString(kCFStreamPropertyAllowExpensiveNetworkAccess) == "kCFStreamPropertyAllowExpensiveNetworkAccess", "expensive allow")
    require(swiftString(kCFStreamPropertyConnectionIsCellular) == "kCFStreamPropertyConnectionIsCellular", "cellular")
    require(swiftString(kCFStreamPropertyConnectionIsExpensive) == "kCFStreamPropertyConnectionIsExpensive", "expensive")
    require(swiftString(kCFStreamPropertyNoCellular) == "kCFStreamPropertyNoCellular", "no cellular")
    require(swiftString(kCFStreamPropertyProxyLocalBypass) == "kCFStreamPropertyProxyLocalBypass", "bypass")
    require(swiftString(kCFStreamPropertySSLContext) == "kCFStreamPropertySSLContext", "ssl ctx")
    require(swiftString(kCFStreamPropertySSLPeerTrust) == "kCFStreamPropertySSLPeerTrust", "peer trust")
    require(swiftString(kCFStreamPropertySSLSettings) == "kCFStreamPropertySSLSettings", "ssl settings")
    require(swiftString(kCFStreamPropertySocketExtendedBackgroundIdleMode) == "kCFStreamPropertySocketExtendedBackgroundIdleMode", "idle")
    require(swiftString(kCFStreamPropertySocketRemoteHost) == "kCFStreamPropertySocketRemoteHost", "remote host")
    require(swiftString(kCFStreamPropertySocketRemoteNetService) == "kCFStreamPropertySocketRemoteNetService", "remote ns")
    require(swiftString(kCFStreamSSLCertificates) == "kCFStreamSSLCertificates", "certs")
    require(swiftString(kCFStreamSSLIsServer) == "kCFStreamSSLIsServer", "is server")
    require(swiftString(kCFStreamSSLLevel) == "kCFStreamSSLLevel", "level")
    require(swiftString(kCFStreamSSLPeerName) == "kCFStreamSSLPeerName", "peer name")
    require(swiftString(kCFStreamSSLValidatesCertificateChain) == "kCFStreamSSLValidatesCertificateChain", "chain")
}

func testCFHTTPMessageCreateRequest() {

    require(CFHTTPMessageGetTypeID() != CFHostGetTypeID(), "distinct type IDs")
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
}

func testCFHTTPMessageHeadersAndBody() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("POST"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(request, cfString("Content-Type"), cfString("text/plain"))
    CFHTTPMessageSetHeaderFieldValue(request, cfString("X-Test"), cfString("one"))
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(request, cfString("content-type"))!.takeRetainedValue())
            == "text/plain",
        "header lookup is case-insensitive"
    )
    let body = cfDataFromUTF8("hello")
    CFHTTPMessageSetBody(request, body)
    let allHeaders = CFHTTPMessageCopyAllHeaderFields(request)!.takeRetainedValue()
    require(CFDictionaryGetCount(allHeaders) >= 2, "header dictionary")
    let serialized = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue()
    let serializedBytes = cfDataBytes(serialized)
    let serializedText = String(bytes: serializedBytes, encoding: .utf8)!
    require(serializedText.hasPrefix("POST /path?q=1 HTTP/1.1\r\n"), "serialized start line")
    require(serializedText.contains("Content-Type: text/plain"), "serialized header")
    require(serializedText.hasSuffix("hello"), "serialized body")
}

func testCFHTTPMessageAppendBytes() {

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
}

func testCFHTTPMessageSerializedRoundTrip() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("POST"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(request, cfString("Content-Type"), cfString("text/plain"))
    CFHTTPMessageSetBody(request, cfDataFromUTF8("hello"))
    let serialized = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue()
    let serializedBytes = cfDataBytes(serialized)
    let roundTrip = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
    let appendedRoundTrip = serializedBytes.withUnsafeBufferPointer { buffer in
        CFHTTPMessageAppendBytes(roundTrip, buffer.baseAddress!, CFIndex(buffer.count))
    }
    require(appendedRoundTrip, "round-trip append")
    let again = CFHTTPMessageCopySerializedMessage(roundTrip)!.takeRetainedValue()
    require(cfDataBytes(again) == serializedBytes, "serialize parse serialize is byte-exact")
}

func testCFHTTPMessageCreateResponse() {

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
}

func testCFHTTPMessageCreateCopy() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let copy = CFHTTPMessageCreateCopy(nil, request).takeRetainedValue()
    require(copy != request, "copy is a distinct object")
    require(CFHTTPMessageIsRequest(copy), "copy remains a request")
    require(copy.hashValue == copy.hashValue, "message hashValue")
    var messageHasher = Hasher()
    copy.hash(into: &messageHasher)
    _ = messageHasher.finalize()
    require(copy == copy, "message equality")
}

func testCFHTTPMessageAddAuthentication() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/secret"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
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
}

func testCFHTTPAuthenticationCreateFromResponse() {

    require(CFHTTPAuthenticationGetTypeID() != CFNetServiceGetTypeID(), "auth vs service type ID")
    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationIsValid(auth, nil), "basic auth valid")
    require(swiftString(CFHTTPAuthenticationCopyMethod(auth).takeRetainedValue()) == "Basic", "method")
    require(swiftString(CFHTTPAuthenticationCopyRealm(auth).takeRetainedValue()) == "test", "realm")
}

func testCFHTTPAuthenticationAppliesToRequest() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationRequiresUserNameAndPassword(auth), "requires user/password")
    require(!CFHTTPAuthenticationRequiresAccountDomain(auth), "basic does not need domain")
    require(!CFHTTPAuthenticationRequiresOrderedRequests(auth), "basic unordered")
    require(CFArrayGetCount(CFHTTPAuthenticationCopyDomains(auth).takeRetainedValue()) == 0, "no domains")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(CFHTTPAuthenticationAppliesToRequest(auth, request), "applies without domain list")
}

func testCFHTTPMessageApplyCredentials() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
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
}

func testCFHTTPAuthenticationDigest() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\", domain=\"example.com /digest\"")
    )
    let digest = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(CFHTTPAuthenticationIsValid(digest, &streamError), "digest is valid")
    require(CFHTTPAuthenticationRequiresOrderedRequests(digest), "digest is ordered")
    require(
        CFArrayGetCount(CFHTTPAuthenticationCopyDomains(digest).takeRetainedValue()) == 2,
        "digest domains"
    )
    let digestURL = CFURLCreateWithString(nil, cfString("http://example.com/digest"), nil)!
    let digestRequest = CFHTTPMessageCreateRequest(nil, cfString("GET"), digestURL, kCFHTTPVersion1_1)
        .takeRetainedValue()
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
}

func testCFHTTPAuthenticationUnsupportedScheme() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Negotiate realm=\"test\"")
    )
    let negotiate = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(!CFHTTPAuthenticationIsValid(negotiate, &streamError), "Negotiate fail-closed")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
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

func testCFHTTPAuthenticationHashable() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(auth.hashValue == auth.hashValue, "auth hashValue")
    var authHasher = Hasher()
    auth.hash(into: &authHasher)
    _ = authHasher.finalize()
    let otherAuth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(auth != otherAuth, "auth identity inequality")
    require(auth == auth, "auth equality")
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

func testCFHostClientContext() {

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
    _ = filled.info
    _ = filled.retain
    _ = filled.release
    _ = filled.copyDescription
}

func testCFNetServiceClientContext() {

    var serviceContext = CFNetServiceClientContext()
    require(serviceContext.version == 0, "service context version")
    require(serviceContext.info == nil, "service context info")
    require(serviceContext.retain == nil, "service context retain")
    require(serviceContext.release == nil, "service context release")
    require(serviceContext.copyDescription == nil, "service context copyDescription")
    serviceContext.version = 0
    serviceContext.info = nil
    serviceContext.retain = nil
    serviceContext.release = nil
    serviceContext.copyDescription = nil
    let filledServiceContext = CFNetServiceClientContext(
        version: 0,
        info: nil,
        retain: nil,
        release: nil,
        copyDescription: nil
    )
    require(filledServiceContext.version == 0, "filled service context")
    _ = filledServiceContext.info
    _ = filledServiceContext.retain
    _ = filledServiceContext.release
    _ = filledServiceContext.copyDescription
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

func testCFNetDiagnosticCreate() {

    let url = CFURLCreateWithString(nil, cfString("https://example.com/"), nil)!
    let diagnostic = CFNetDiagnosticCreateWithURL(kCFAllocatorSystemDefault!, url)
        .takeRetainedValue()
    CFNetDiagnosticSetName(diagnostic, cfString("probe"))
    let fromStreams = CFNetDiagnosticCreateWithStreams(nil, nil, nil).takeRetainedValue()
    require(fromStreams != diagnostic, "stream diagnostic identity")
    require(fromStreams.hashValue == fromStreams.hashValue, "diagnostic hashValue")
    var diagnosticHasher = Hasher()
    fromStreams.hash(into: &diagnosticHasher)
    _ = diagnosticHasher.finalize()
    require(fromStreams == fromStreams, "diagnostic equality")
}

func testCFNetDiagnosticStatus() {

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

func testCFFTPCreateParsedResourceListing() {

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

enum CFNetworkRuntime {
    static func main() {
        testCFNetworkErrorRawValues()
        testCFNetworkErrorHashable()
        testCFHostInfoTypeRawValues()
        testCFHostInfoTypeHashable()
        testCFNetServicesErrorRawValues()
        testCFNetServicesErrorHashable()
        testCFNetDiagnosticStatusRawValues()
        testCFNetDiagnosticStatusHashable()
        testCFStreamErrorHTTPRawValues()
        testCFStreamErrorHTTPHashable()
        testCFStreamErrorHTTPAuthenticationRawValues()
        testCFNetServiceMonitorTypeRawValues()
        testCFNetServiceBrowserFlagAlgebra()
        testCFNetServiceRegisterFlagAlgebra()
        testCFHTTPVersionConstants()
        testCFHTTPAuthenticationSchemeConstants()
        testCFErrorDomainConstants()
        testCFProxyKeyConstants()
        testCFFTPResourceConstants()
        testCFSOCKSErrorConstants()
        testCFStreamErrorDomainConstants()
        testCFStreamNetworkServiceTypeConstants()
        testCFStreamPropertyFTPConstants()
        testCFStreamPropertyHTTPConstants()
        testCFStreamPropertySSLAndAccessConstants()
        testCFHTTPMessageCreateRequest()
        testCFHTTPMessageHeadersAndBody()
        testCFHTTPMessageAppendBytes()
        testCFHTTPMessageSerializedRoundTrip()
        testCFHTTPMessageCreateResponse()
        testCFHTTPMessageCreateCopy()
        testCFHTTPMessageAddAuthentication()
        testCFHTTPAuthenticationCreateFromResponse()
        testCFHTTPAuthenticationAppliesToRequest()
        testCFHTTPMessageApplyCredentials()
        testCFHTTPAuthenticationDigest()
        testCFHTTPAuthenticationUnsupportedScheme()
        testCFHTTPAuthenticationHashable()
        testCFHostCreateWithName()
        testCFHostCreateWithAddress()
        testCFHostCreateCopy()
        testCFHostClientAndRunLoop()
        testCFHostClientContext()
        testCFNetServiceClientContext()
        testCFNetServiceCreate()
        testCFNetServiceTXT()
        testCFNetServiceRegisterAndResolve()
        testCFNetServiceClient()
        testCFNetServiceBrowser()
        testCFNetServiceMonitor()
        testCFNetDiagnosticCreate()
        testCFNetDiagnosticStatus()
        testCFNetworkCopySystemProxySettings()
        testCFNetworkCopyProxiesForURL()
        testCFNetworkCopyProxiesForPACScript()
        testCFNetworkExecutePAC()
        testCFReadStreamCreateForHTTPRequest()
        testCFStreamCreateFTP()
        testCFStreamCreatePair()
        testCFSocketStreamSOCKSGetError()
        testCFFTPCreateParsedResourceListing()
        print("CFNETWORK_AGENT_RUNTIME_OK")
    }
}

CFNetworkRuntime.main()
