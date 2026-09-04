@_exported import CoreFoundation
@_exported import Foundation

/// Linux substitute for Darwin's `DarwinBoolean`. CFNetwork APIs that report
/// resolution state take a pointer to this type on the Apple overlay.
public struct DarwinBoolean: ExpressibleByBooleanLiteral, Equatable, Hashable,
    CustomStringConvertible
{
    public var _value: UInt8

    public init(_ value: Bool) {
        _value = value ? 1 : 0
    }

    public init(booleanLiteral value: Bool) {
        self.init(value)
    }

    public var boolValue: Bool { _value != 0 }

    public var description: String { String(boolValue) }
}

enum CFNetworkTypeID {
    static let httpMessage: CFTypeID = 0x4346_4E01
    static let httpAuthentication: CFTypeID = 0x4346_4E02
    static let host: CFTypeID = 0x4346_4E03
    static let netDiagnostic: CFTypeID = 0x4346_4E04
    static let netService: CFTypeID = 0x4346_4E05
    static let netServiceBrowser: CFTypeID = 0x4346_4E06
    static let netServiceMonitor: CFTypeID = 0x4346_4E07
}

public enum CFHostInfoType: Int32, Hashable, CaseIterable {
    case addresses = 0
    case names = 1
    case reachability = 2
}

public enum CFNetDiagnosticStatusValues: Int32, Hashable, CaseIterable {
    case noErr = 0
    case err = -66560
    case connectionUp = -66555
    case connectionIndeterminate = -66559
    case connectionDown = -66557
}

public typealias CFNetDiagnosticStatus = CFIndex

public struct CFNetServiceBrowserFlags: OptionSet, Hashable {
    public let rawValue: CFOptionFlags

    public init(rawValue: CFOptionFlags) {
        self.rawValue = rawValue
    }

    public static let moreComing = CFNetServiceBrowserFlags(rawValue: 1)
    public static let isDomain = CFNetServiceBrowserFlags(rawValue: 2)
    public static let isDefault = CFNetServiceBrowserFlags(rawValue: 4)
    public static let `remove` = CFNetServiceBrowserFlags(rawValue: 8)
}

public enum CFNetServiceMonitorType: Int32, Hashable, CaseIterable {
    case TXT = 1
}

public struct CFNetServiceRegisterFlags: OptionSet, Hashable {
    public let rawValue: CFOptionFlags

    public init(rawValue: CFOptionFlags) {
        self.rawValue = rawValue
    }

    public static let noAutoRename = CFNetServiceRegisterFlags(rawValue: 1)
}

public enum CFNetServicesError: Int32, Hashable, CaseIterable {
    case unknown = -72000
    case collision = -72001
    case notFound = -72002
    case inProgress = -72003
    case badArgument = -72004
    case cancel = -72005
    case invalid = -72006
    case timeout = -72007
    case missingRequiredConfiguration = -72008
}

public enum CFNetworkErrors: Int32, Hashable, CaseIterable {
    case cfHostErrorHostNotFound = 1
    case cfHostErrorUnknown = 2
    case cfsocksErrorUnknownClientVersion = 100
    case cfsocksErrorUnsupportedServerVersion = 101
    case cfsocks4ErrorRequestFailed = 110
    case cfsocks4ErrorIdentdFailed = 111
    case cfsocks4ErrorIdConflict = 112
    case cfsocks4ErrorUnknownStatusCode = 113
    case cfsocks5ErrorBadState = 120
    case cfsocks5ErrorBadResponseAddr = 121
    case cfsocks5ErrorBadCredentials = 122
    case cfsocks5ErrorUnsupportedNegotiationMethod = 123
    case cfsocks5ErrorNoAcceptableMethod = 124
    case cfftpErrorUnexpectedStatusCode = 200
    case cfErrorHTTPAuthenticationTypeUnsupported = 300
    case cfErrorHTTPBadCredentials = 301
    case cfErrorHTTPConnectionLost = 302
    case cfErrorHTTPParseFailure = 303
    case cfErrorHTTPRedirectionLoopDetected = 304
    case cfErrorHTTPBadURL = 305
    case cfErrorHTTPProxyConnectionFailure = 306
    case cfErrorHTTPBadProxyCredentials = 307
    case cfErrorPACFileError = 308
    case cfErrorPACFileAuth = 309
    case cfErrorHTTPSProxyConnectionFailure = 310
    case cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod = 311
    case cfurlErrorBackgroundSessionInUseByAnotherProcess = -996
    case cfurlErrorBackgroundSessionWasDisconnected = -997
    case cfurlErrorUnknown = -998
    case cfurlErrorCancelled = -999
    case cfurlErrorBadURL = -1000
    case cfurlErrorTimedOut = -1001
    case cfurlErrorUnsupportedURL = -1002
    case cfurlErrorCannotFindHost = -1003
    case cfurlErrorCannotConnectToHost = -1004
    case cfurlErrorNetworkConnectionLost = -1005
    case cfurlErrorDNSLookupFailed = -1006
    case cfurlErrorHTTPTooManyRedirects = -1007
    case cfurlErrorResourceUnavailable = -1008
    case cfurlErrorNotConnectedToInternet = -1009
    case cfurlErrorRedirectToNonExistentLocation = -1010
    case cfurlErrorBadServerResponse = -1011
    case cfurlErrorUserCancelledAuthentication = -1012
    case cfurlErrorUserAuthenticationRequired = -1013
    case cfurlErrorZeroByteResource = -1014
    case cfurlErrorCannotDecodeRawData = -1015
    case cfurlErrorCannotDecodeContentData = -1016
    case cfurlErrorCannotParseResponse = -1017
    case cfurlErrorInternationalRoamingOff = -1018
    case cfurlErrorCallIsActive = -1019
    case cfurlErrorDataNotAllowed = -1020
    case cfurlErrorRequestBodyStreamExhausted = -1021
    case cfurlErrorAppTransportSecurityRequiresSecureConnection = -1022
    case cfurlErrorFileDoesNotExist = -1100
    case cfurlErrorFileIsDirectory = -1101
    case cfurlErrorNoPermissionsToReadFile = -1102
    case cfurlErrorDataLengthExceedsMaximum = -1103
    case cfurlErrorFileOutsideSafeArea = -1104
    case cfurlErrorSecureConnectionFailed = -1200
    case cfurlErrorServerCertificateHasBadDate = -1201
    case cfurlErrorServerCertificateUntrusted = -1202
    case cfurlErrorServerCertificateHasUnknownRoot = -1203
    case cfurlErrorServerCertificateNotYetValid = -1204
    case cfurlErrorClientCertificateRejected = -1205
    case cfurlErrorClientCertificateRequired = -1206
    case cfurlErrorCannotLoadFromNetwork = -2000
    case cfurlErrorCannotCreateFile = -3000
    case cfurlErrorCannotOpenFile = -3001
    case cfurlErrorCannotCloseFile = -3002
    case cfurlErrorCannotWriteToFile = -3003
    case cfurlErrorCannotRemoveFile = -3004
    case cfurlErrorCannotMoveFile = -3005
    case cfurlErrorDownloadDecodingFailedMidStream = -3006
    case cfurlErrorDownloadDecodingFailedToComplete = -3007
    case cfhttpCookieCannotParseCookieFile = -4000
    case cfNetServiceErrorUnknown = -72000
    case cfNetServiceErrorCollision = -72001
    case cfNetServiceErrorNotFound = -72002
    case cfNetServiceErrorInProgress = -72003
    case cfNetServiceErrorBadArgument = -72004
    case cfNetServiceErrorCancel = -72005
    case cfNetServiceErrorInvalid = -72006
    case cfNetServiceErrorTimeout = -72007
    case cfNetServiceErrorDNSServiceFailure = -73000
}

public enum CFStreamErrorHTTP: Int32, Hashable, CaseIterable {
    case parseFailure = -1
    case redirectionLoop = -2
    case badURL = -3
}

public enum CFStreamErrorHTTPAuthentication: Int32, Hashable, CaseIterable {
    case typeUnsupported = -1000
    case badUserName = -1001
    case badPassword = -1002
}

public struct CFHostClientContext {
    public var version: CFIndex
    public var info: UnsafeMutableRawPointer?
    public var retain: CFAllocatorRetainCallBack?
    public var release: CFAllocatorReleaseCallBack?
    public var copyDescription: CFAllocatorCopyDescriptionCallBack?

    public init() {
        version = 0
        info = nil
        retain = nil
        release = nil
        copyDescription = nil
    }

    public init(
        version: CFIndex,
        info: UnsafeMutableRawPointer?,
        retain: CFAllocatorRetainCallBack?,
        release: CFAllocatorReleaseCallBack?,
        copyDescription: CFAllocatorCopyDescriptionCallBack?
    ) {
        self.version = version
        self.info = info
        self.retain = retain
        self.release = release
        self.copyDescription = copyDescription
    }
}

public struct CFNetServiceClientContext {
    public var version: CFIndex
    public var info: UnsafeMutableRawPointer?
    public var retain: CFAllocatorRetainCallBack?
    public var release: CFAllocatorReleaseCallBack?
    public var copyDescription: CFAllocatorCopyDescriptionCallBack?

    public init() {
        version = 0
        info = nil
        retain = nil
        release = nil
        copyDescription = nil
    }

    public init(
        version: CFIndex,
        info: UnsafeMutableRawPointer?,
        retain: CFAllocatorRetainCallBack?,
        release: CFAllocatorReleaseCallBack?,
        copyDescription: CFAllocatorCopyDescriptionCallBack?
    ) {
        self.version = version
        self.info = info
        self.retain = retain
        self.release = release
        self.copyDescription = copyDescription
    }
}

public typealias CFHostClientCallBack = (
    CFHost, CFHostInfoType, UnsafePointer<CFStreamError>?, UnsafeMutableRawPointer?
) -> Void

public typealias CFNetServiceBrowserClientCallBack = (
    CFNetServiceBrowser, CFOptionFlags, CFTypeRef?, UnsafeMutablePointer<CFStreamError>?,
    UnsafeMutableRawPointer?
) -> Void

public typealias CFNetServiceClientCallBack = (
    CFNetService, UnsafeMutablePointer<CFStreamError>?, UnsafeMutableRawPointer?
) -> Void

public typealias CFNetServiceMonitorClientCallBack = (
    CFNetServiceMonitor, CFNetService?, CFNetServiceMonitorType, CFData?,
    UnsafeMutablePointer<CFStreamError>?, UnsafeMutableRawPointer?
) -> Void

public typealias CFProxyAutoConfigurationResultCallback = (
    UnsafeMutableRawPointer, CFArray, CFError?
) -> Void

public final class CFHTTPMessage: Hashable {
    let lock = NSLock()
    var isRequestMessage: Bool
    var headerComplete: Bool
    var httpVersion: String
    var method: String?
    var url: CFURL?
    var statusCode: CFIndex
    var statusReason: String?
    var headers: [(name: String, value: String)]
    var body: CFData?
    var parseBuffer: [UInt8]

    init(
        isRequestMessage: Bool,
        headerComplete: Bool,
        httpVersion: String,
        method: String? = nil,
        url: CFURL? = nil,
        statusCode: CFIndex = 0,
        statusReason: String? = nil
    ) {
        self.isRequestMessage = isRequestMessage
        self.headerComplete = headerComplete
        self.httpVersion = httpVersion
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.statusReason = statusReason
        self.headers = []
        self.body = nil
        self.parseBuffer = []
    }

    public static func == (left: CFHTTPMessage, right: CFHTTPMessage) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFHTTPAuthentication: Hashable {
    let lock = NSLock()
    var scheme: String
    var realm: String?
    var domains: [String]
    var isValidAuthentication: Bool
    var requiresUserPassword: Bool
    var requiresAccountDomain: Bool
    var requiresOrderedRequests: Bool

    init(
        scheme: String,
        realm: String?,
        domains: [String] = [],
        isValidAuthentication: Bool,
        requiresUserPassword: Bool,
        requiresAccountDomain: Bool = false,
        requiresOrderedRequests: Bool = false
    ) {
        self.scheme = scheme
        self.realm = realm
        self.domains = domains
        self.isValidAuthentication = isValidAuthentication
        self.requiresUserPassword = requiresUserPassword
        self.requiresAccountDomain = requiresAccountDomain
        self.requiresOrderedRequests = requiresOrderedRequests
    }

    public static func == (left: CFHTTPAuthentication, right: CFHTTPAuthentication) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFHost: Hashable {
    let lock = NSLock()
    var names: [String]
    var addresses: [CFData]
    var namesResolved: Bool
    var addressesResolved: Bool
    var reachabilityResolved: Bool
    var cancelled: Set<CFHostInfoType>
    var client: CFHostClientCallBack?
    var clientInfo: UnsafeMutableRawPointer?
    var clientRelease: CFAllocatorReleaseCallBack?
    var scheduled: Bool

    init(
        names: [String],
        addresses: [CFData],
        namesResolved: Bool,
        addressesResolved: Bool
    ) {
        self.names = names
        self.addresses = addresses
        self.namesResolved = namesResolved
        self.addressesResolved = addressesResolved
        self.reachabilityResolved = false
        self.cancelled = []
        self.client = nil
        self.clientInfo = nil
        self.clientRelease = nil
        self.scheduled = false
    }

    deinit {
        cfReleaseContextInfo(clientRelease, info: clientInfo)
    }

    public static func == (left: CFHost, right: CFHost) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFNetDiagnostic: Hashable {
    let lock = NSLock()
    var url: CFURL?
    var name: String?

    init(url: CFURL?) {
        self.url = url
        self.name = nil
    }

    public static func == (left: CFNetDiagnostic, right: CFNetDiagnostic) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFNetService: Hashable {
    let lock = NSLock()
    var domain: String
    var serviceType: String
    var name: String
    var port: Int32
    var txtRecord: CFData?
    var targetHost: String?
    var addresses: [CFData]
    var client: CFNetServiceClientCallBack?
    var clientInfo: UnsafeMutableRawPointer?
    var clientRelease: CFAllocatorReleaseCallBack?
    var scheduled: Bool
    var invalidated: Bool

    init(domain: String, serviceType: String, name: String, port: Int32) {
        self.domain = domain
        self.serviceType = serviceType
        self.name = name
        self.port = port
        self.txtRecord = nil
        self.targetHost = nil
        self.addresses = []
        self.client = nil
        self.clientInfo = nil
        self.clientRelease = nil
        self.scheduled = false
        self.invalidated = false
    }

    deinit {
        cfReleaseContextInfo(clientRelease, info: clientInfo)
    }

    public static func == (left: CFNetService, right: CFNetService) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFNetServiceBrowser: Hashable {
    let lock = NSLock()
    var client: CFNetServiceBrowserClientCallBack
    var clientInfo: UnsafeMutableRawPointer?
    var clientRelease: CFAllocatorReleaseCallBack?
    var scheduled: Bool
    var searching: Bool
    var invalidated: Bool

    init(
        client: @escaping CFNetServiceBrowserClientCallBack,
        info: UnsafeMutableRawPointer?,
        release: CFAllocatorReleaseCallBack?
    ) {
        self.client = client
        self.clientInfo = info
        self.clientRelease = release
        self.scheduled = false
        self.searching = false
        self.invalidated = false
    }

    deinit {
        cfReleaseContextInfo(clientRelease, info: clientInfo)
    }

    public static func == (left: CFNetServiceBrowser, right: CFNetServiceBrowser) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public final class CFNetServiceMonitor: Hashable {
    let lock = NSLock()
    var service: CFNetService
    var client: CFNetServiceMonitorClientCallBack
    var clientInfo: UnsafeMutableRawPointer?
    var clientRelease: CFAllocatorReleaseCallBack?
    var scheduled: Bool
    var running: Bool
    var invalidated: Bool

    init(
        service: CFNetService,
        client: @escaping CFNetServiceMonitorClientCallBack,
        info: UnsafeMutableRawPointer?,
        release: CFAllocatorReleaseCallBack?
    ) {
        self.service = service
        self.client = client
        self.clientInfo = info
        self.clientRelease = release
        self.scheduled = false
        self.running = false
        self.invalidated = false
    }

    deinit {
        cfReleaseContextInfo(clientRelease, info: clientInfo)
    }

    public static func == (left: CFNetServiceMonitor, right: CFNetServiceMonitor) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public let kCFStreamErrorSOCKS4IdConflict: Int = 93
public let kCFStreamErrorSOCKS4IdentdFailed: Int = 92
public let kCFStreamErrorSOCKS4RequestFailed: Int = 91
public let kCFStreamErrorSOCKS5BadResponseAddr: Int = 1
public let kCFStreamErrorSOCKS5BadState: Int = 2
public let kCFStreamErrorSOCKSUnknownClientVersion: Int = 3
public let kCFStreamErrorSOCKS4SubDomainResponse: Int = 2
public let kCFStreamErrorSOCKS5SubDomainMethod: Int = 4
public let kCFStreamErrorSOCKS5SubDomainResponse: Int = 5
public let kCFStreamErrorSOCKS5SubDomainUserPass: Int = 3
public let kCFStreamErrorSOCKSSubDomainNone: Int = 0
public let kCFStreamErrorSOCKSSubDomainVersionCode: Int = 1
public let kSOCKS5NoAcceptableMethod: Int = 255

public let kCFStreamErrorDomainHTTP: Int32 = 4
public let kCFStreamErrorDomainFTP: Int32 = 11
public let kCFStreamErrorDomainNetServices: Int32 = 10
public let kCFStreamErrorDomainNetDB: Int32 = 12
public let kCFStreamErrorDomainSystemConfiguration: Int32 = 13
public let kCFStreamErrorDomainMach: Int32 = 14
public let kCFStreamErrorDomainWinSock: CFIndex = 15

public let kCFDNSServiceFailureKey: CFString = cfString("kCFDNSServiceFailureKey")
public let kCFErrorDomainCFNetwork: CFString = cfString("kCFErrorDomainCFNetwork")
public let kCFErrorDomainWinSock: CFString = cfString("kCFErrorDomainWinSock")
public let kCFFTPResourceGroup: CFString = cfString("kCFFTPResourceGroup")
public let kCFFTPResourceLink: CFString = cfString("kCFFTPResourceLink")
public let kCFFTPResourceModDate: CFString = cfString("kCFFTPResourceModDate")
public let kCFFTPResourceMode: CFString = cfString("kCFFTPResourceMode")
public let kCFFTPResourceName: CFString = cfString("kCFFTPResourceName")
public let kCFFTPResourceOwner: CFString = cfString("kCFFTPResourceOwner")
public let kCFFTPResourceSize: CFString = cfString("kCFFTPResourceSize")
public let kCFFTPResourceType: CFString = cfString("kCFFTPResourceType")
public let kCFFTPStatusCodeKey: CFString = cfString("kCFFTPStatusCodeKey")
public let kCFGetAddrInfoFailureKey: CFString = cfString("kCFGetAddrInfoFailureKey")
public let kCFHTTPAuthenticationAccountDomain: CFString = cfString(
    "kCFHTTPAuthenticationAccountDomain"
)
public let kCFHTTPAuthenticationPassword: CFString = cfString("kCFHTTPAuthenticationPassword")
public let kCFHTTPAuthenticationSchemeBasic: CFString = cfString("Basic")
public let kCFHTTPAuthenticationSchemeDigest: CFString = cfString("Digest")
public let kCFHTTPAuthenticationSchemeKerberos: CFString = cfString("Kerberos")
public let kCFHTTPAuthenticationSchemeNTLM: CFString = cfString("NTLM")
public let kCFHTTPAuthenticationSchemeNegotiate: CFString = cfString("Negotiate")
public let kCFHTTPAuthenticationSchemeNegotiate2: CFString = cfString("Negotiate2")
public let kCFHTTPAuthenticationSchemeXMobileMeAuthToken: CFString = cfString(
    "X-MobileMe-AuthToken"
)
public let kCFHTTPAuthenticationUsername: CFString = cfString("kCFHTTPAuthenticationUsername")
public let kCFHTTPVersion1_0: CFString = cfString("HTTP/1.0")
public let kCFHTTPVersion1_1: CFString = cfString("HTTP/1.1")
public let kCFHTTPVersion2_0: CFString = cfString("HTTP/2.0")
public let kCFHTTPVersion3_0: CFString = cfString("HTTP/3.0")
public let kCFNetworkProxiesHTTPEnable: CFString = cfString("kCFNetworkProxiesHTTPEnable")
public let kCFNetworkProxiesHTTPPort: CFString = cfString("kCFNetworkProxiesHTTPPort")
public let kCFNetworkProxiesHTTPProxy: CFString = cfString("kCFNetworkProxiesHTTPProxy")
public let kCFNetworkProxiesProxyAutoConfigEnable: CFString = cfString(
    "kCFNetworkProxiesProxyAutoConfigEnable"
)
public let kCFNetworkProxiesProxyAutoConfigJavaScript: CFString = cfString(
    "kCFNetworkProxiesProxyAutoConfigJavaScript"
)
public let kCFNetworkProxiesProxyAutoConfigURLString: CFString = cfString(
    "kCFNetworkProxiesProxyAutoConfigURLString"
)
public let kCFProxyAutoConfigurationHTTPResponseKey: CFString = cfString(
    "kCFProxyAutoConfigurationHTTPResponseKey"
)
public let kCFProxyAutoConfigurationJavaScriptKey: CFString = cfString(
    "kCFProxyAutoConfigurationJavaScriptKey"
)
public let kCFProxyAutoConfigurationURLKey: CFString = cfString("kCFProxyAutoConfigurationURLKey")
public let kCFProxyHostNameKey: CFString = cfString("kCFProxyHostNameKey")
public let kCFProxyPasswordKey: CFString = cfString("kCFProxyPasswordKey")
public let kCFProxyPortNumberKey: CFString = cfString("kCFProxyPortNumberKey")
public let kCFProxyTypeAutoConfigurationJavaScript: CFString = cfString(
    "kCFProxyTypeAutoConfigurationJavaScript"
)
public let kCFProxyTypeAutoConfigurationURL: CFString = cfString("kCFProxyTypeAutoConfigurationURL")
public let kCFProxyTypeFTP: CFString = cfString("kCFProxyTypeFTP")
public let kCFProxyTypeHTTP: CFString = cfString("kCFProxyTypeHTTP")
public let kCFProxyTypeHTTPS: CFString = cfString("kCFProxyTypeHTTPS")
public let kCFProxyTypeKey: CFString = cfString("kCFProxyTypeKey")
public let kCFProxyTypeNone: CFString = cfString("kCFProxyTypeNone")
public let kCFProxyTypeSOCKS: CFString = cfString("kCFProxyTypeSOCKS")
public let kCFProxyUsernameKey: CFString = cfString("kCFProxyUsernameKey")
public let kCFSOCKSNegotiationMethodKey: CFString = cfString("kCFSOCKSNegotiationMethodKey")
public let kCFSOCKSStatusCodeKey: CFString = cfString("kCFSOCKSStatusCodeKey")
public let kCFSOCKSVersionKey: CFString = cfString("kCFSOCKSVersionKey")
public let kCFStreamNetworkServiceType: CFString = cfString("kCFStreamNetworkServiceType")
public let kCFStreamNetworkServiceTypeAVStreaming: CFString = cfString(
    "kCFStreamNetworkServiceTypeAVStreaming"
)
public let kCFStreamNetworkServiceTypeBackground: CFString = cfString(
    "kCFStreamNetworkServiceTypeBackground"
)
public let kCFStreamNetworkServiceTypeCallSignaling: CFString = cfString(
    "kCFStreamNetworkServiceTypeCallSignaling"
)
public let kCFStreamNetworkServiceTypeResponsiveAV: CFString = cfString(
    "kCFStreamNetworkServiceTypeResponsiveAV"
)
public let kCFStreamNetworkServiceTypeResponsiveData: CFString = cfString(
    "kCFStreamNetworkServiceTypeResponsiveData"
)
public let kCFStreamNetworkServiceTypeVideo: CFString = cfString("kCFStreamNetworkServiceTypeVideo")
public let kCFStreamNetworkServiceTypeVoIP: CFString = cfString("kCFStreamNetworkServiceTypeVoIP")
public let kCFStreamNetworkServiceTypeVoice: CFString = cfString("kCFStreamNetworkServiceTypeVoice")
public let kCFStreamPropertyAllowConstrainedNetworkAccess: CFString = cfString(
    "kCFStreamPropertyAllowConstrainedNetworkAccess"
)
public let kCFStreamPropertyAllowExpensiveNetworkAccess: CFString = cfString(
    "kCFStreamPropertyAllowExpensiveNetworkAccess"
)
public let kCFStreamPropertyConnectionIsCellular: CFString = cfString(
    "kCFStreamPropertyConnectionIsCellular"
)
public let kCFStreamPropertyConnectionIsExpensive: CFString = cfString(
    "kCFStreamPropertyConnectionIsExpensive"
)
public let kCFStreamPropertyFTPAttemptPersistentConnection: CFString = cfString(
    "kCFStreamPropertyFTPAttemptPersistentConnection"
)
public let kCFStreamPropertyFTPFetchResourceInfo: CFString = cfString(
    "kCFStreamPropertyFTPFetchResourceInfo"
)
public let kCFStreamPropertyFTPFileTransferOffset: CFString = cfString(
    "kCFStreamPropertyFTPFileTransferOffset"
)
public let kCFStreamPropertyFTPPassword: CFString = cfString("kCFStreamPropertyFTPPassword")
public let kCFStreamPropertyFTPProxy: CFString = cfString("kCFStreamPropertyFTPProxy")
public let kCFStreamPropertyFTPProxyHost: CFString = cfString("kCFStreamPropertyFTPProxyHost")
public let kCFStreamPropertyFTPProxyPassword: CFString = cfString(
    "kCFStreamPropertyFTPProxyPassword"
)
public let kCFStreamPropertyFTPProxyPort: CFString = cfString("kCFStreamPropertyFTPProxyPort")
public let kCFStreamPropertyFTPProxyUser: CFString = cfString("kCFStreamPropertyFTPProxyUser")
public let kCFStreamPropertyFTPResourceSize: CFString = cfString(
    "kCFStreamPropertyFTPResourceSize"
)
public let kCFStreamPropertyFTPUsePassiveMode: CFString = cfString(
    "kCFStreamPropertyFTPUsePassiveMode"
)
public let kCFStreamPropertyFTPUserName: CFString = cfString("kCFStreamPropertyFTPUserName")
public let kCFStreamPropertyHTTPAttemptPersistentConnection: CFString = cfString(
    "kCFStreamPropertyHTTPAttemptPersistentConnection"
)
public let kCFStreamPropertyHTTPFinalRequest: CFString = cfString(
    "kCFStreamPropertyHTTPFinalRequest"
)
public let kCFStreamPropertyHTTPFinalURL: CFString = cfString("kCFStreamPropertyHTTPFinalURL")
public let kCFStreamPropertyHTTPProxy: CFString = cfString("kCFStreamPropertyHTTPProxy")
public let kCFStreamPropertyHTTPProxyHost: CFString = cfString("kCFStreamPropertyHTTPProxyHost")
public let kCFStreamPropertyHTTPProxyPort: CFString = cfString("kCFStreamPropertyHTTPProxyPort")
public let kCFStreamPropertyHTTPRequestBytesWrittenCount: CFString = cfString(
    "kCFStreamPropertyHTTPRequestBytesWrittenCount"
)
public let kCFStreamPropertyHTTPResponseHeader: CFString = cfString(
    "kCFStreamPropertyHTTPResponseHeader"
)
public let kCFStreamPropertyHTTPSProxyHost: CFString = cfString("kCFStreamPropertyHTTPSProxyHost")
public let kCFStreamPropertyHTTPSProxyPort: CFString = cfString("kCFStreamPropertyHTTPSProxyPort")
public let kCFStreamPropertyHTTPShouldAutoredirect: CFString = cfString(
    "kCFStreamPropertyHTTPShouldAutoredirect"
)
public let kCFStreamPropertyNoCellular: CFString = cfString("kCFStreamPropertyNoCellular")
public let kCFStreamPropertyProxyLocalBypass: CFString = cfString(
    "kCFStreamPropertyProxyLocalBypass"
)
public let kCFStreamPropertySSLContext: CFString = cfString("kCFStreamPropertySSLContext")
public let kCFStreamPropertySSLPeerTrust: CFString = cfString("kCFStreamPropertySSLPeerTrust")
public let kCFStreamPropertySSLSettings: CFString = cfString("kCFStreamPropertySSLSettings")
public let kCFStreamPropertySocketExtendedBackgroundIdleMode: CFString = cfString(
    "kCFStreamPropertySocketExtendedBackgroundIdleMode"
)
public let kCFStreamPropertySocketRemoteHost: CFString = cfString(
    "kCFStreamPropertySocketRemoteHost"
)
public let kCFStreamPropertySocketRemoteNetService: CFString = cfString(
    "kCFStreamPropertySocketRemoteNetService"
)
public let kCFStreamSSLCertificates: CFString = cfString("kCFStreamSSLCertificates")
public let kCFStreamSSLIsServer: CFString = cfString("kCFStreamSSLIsServer")
public let kCFStreamSSLLevel: CFString = cfString("kCFStreamSSLLevel")
public let kCFStreamSSLPeerName: CFString = cfString("kCFStreamSSLPeerName")
public let kCFStreamSSLValidatesCertificateChain: CFString = cfString(
    "kCFStreamSSLValidatesCertificateChain"
)
public let kCFURLErrorFailingURLErrorKey: CFString = cfString("NSErrorFailingURLKey")
public let kCFURLErrorFailingURLStringErrorKey: CFString = cfString("NSErrorFailingURLStringKey")
