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
