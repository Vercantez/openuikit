import Foundation

public enum NWError: Error, Hashable, Sendable, CustomStringConvertible,
    CustomDebugStringConvertible, LocalizedError
{
    case posix(POSIXErrorCode)
    case dns(DNSServiceErrorType)
    case tls(OSStatus)
    case wifiAware(Int32)

    /// Linux fail-closed token for missing transport. Not an Apple case.
    public static var unsupported: NWError { .posix(.EOPNOTSUPP) }

    public static var errorDomain: String { String(kNWErrorDomainPOSIX) }

    public var errorCode: Int {
        switch self {
        case .posix(let code): return Int(code.rawValue)
        case .dns(let code): return Int(code)
        case .tls(let code): return Int(code)
        case .wifiAware(let code): return Int(code)
        }
    }

    public var errorUserInfo: [String: Any] { [:] }

    public var description: String {
        switch self {
        case .posix(let code): return "POSIX network error \(code)"
        case .dns(let code): return "DNS network error \(code)"
        case .tls(let code): return "TLS network error \(code)"
        case .wifiAware(let code): return "Wi-Fi Aware network error \(code)"
        }
    }

    public var debugDescription: String { description }
    public var localizedDescription: String { description }
}

public protocol IPAddress: Sendable {
    var isLoopback: Bool { get }
    var isLinkLocal: Bool { get }
    var isMulticast: Bool { get }
    var rawValue: Data { get }
    var interface: NWInterface? { get }
    init?(_ rawValue: Data, _ interface: NWInterface?)
    init?(_ string: String)
}

/// A parsed IPv4 address. Parsing is local and deterministic; constructing an
/// address does not imply that a network interface or route exists.
public struct IPv4Address: Hashable, Sendable, RawRepresentable, IPAddress,
    CustomDebugStringConvertible
{
    public let rawValue: Data
    public let interface: NWInterface?

    public init?(rawValue: Data) {
        self.init(rawValue, nil)
    }

    public init?(_ rawValue: Data, _ interface: NWInterface? = nil) {
        guard rawValue.count == 4 else { return nil }
        self.rawValue = rawValue
        self.interface = interface
    }

    public init?(_ data: Data) { self.init(rawValue: data) }

    public init?(_ string: String) {
        guard let bytes = Self.parseBytes(string) else { return nil }
        rawValue = Data(bytes)
        interface = nil
    }

    public static let any = IPv4Address(rawValue: Data(repeating: 0, count: 4))!
    public static let broadcast = IPv4Address(
        rawValue: Data(repeating: 255, count: 4)
    )!
    public static let loopback = IPv4Address("127.0.0.1")!
    public static let allHostsGroup = IPv4Address("224.0.0.1")!
    public static let allRoutersGroup = IPv4Address("224.0.0.2")!
    public static let allReportsGroup = IPv4Address("224.0.0.22")!
    public static let mdnsGroup = IPv4Address("224.0.0.251")!

    public var isLoopback: Bool { rawValue == Data([127, 0, 0, 1]) }
    public var isLinkLocal: Bool { rawValue.first == 169 && rawValue.dropFirst().first == 254 }
    public var isMulticast: Bool { (rawValue.first ?? 0) >= 224 && (rawValue.first ?? 0) <= 239 }

    public var debugDescription: String {
        rawValue.map(String.init).joined(separator: ".")
    }

    fileprivate static func parseBytes(_ string: String) -> [UInt8]? {
        let components = string.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 4 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(4)
        for component in components {
            guard
                !component.isEmpty,
                component.allSatisfy({ $0.isNumber }),
                let value = UInt8(component)
            else { return nil }
            bytes.append(value)
        }
        return bytes
    }
}

/// A parsed IPv6 address with the same 16-byte raw-value boundary as Network.
/// The parser supports compressed and IPv4-tail spellings without consulting
/// DNS or host networking services.
public struct IPv6Address: Hashable, Sendable, RawRepresentable, IPAddress,
    CustomDebugStringConvertible
{
    public let rawValue: Data
    public let interface: NWInterface?

    public enum Scope: UInt8, Hashable, Sendable {
        case nodeLocal = 1
        case linkLocal = 2
        case siteLocal = 5
        case organizationLocal = 8
        case global = 14
    }

    public init?(rawValue: Data) {
        self.init(rawValue, nil)
    }

    public init?(_ rawValue: Data, _ interface: NWInterface? = nil) {
        guard rawValue.count == 16 else { return nil }
        self.rawValue = rawValue
        self.interface = interface
    }

    public init?(_ data: Data) { self.init(rawValue: data) }

    public init?(_ string: String) {
        guard let words = Self.parseWords(string) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(16)
        for word in words {
            bytes.append(UInt8(word >> 8))
            bytes.append(UInt8(word & 0xff))
        }
        self.rawValue = Data(bytes)
        self.interface = nil
    }

    public static let any = IPv6Address(rawValue: Data(repeating: 0, count: 16))!
    public static let loopback = IPv6Address("::1")!
    public static let broadcast = IPv6Address(rawValue: Data(repeating: 0xff, count: 16))!
    public static let nodeLocalNodes = IPv6Address("ff01::1")!
    public static let linkLocalNodes = IPv6Address("ff02::1")!
    public static let linkLocalRouters = IPv6Address("ff02::2")!

    public var isLoopback: Bool { self == .loopback }
    public var isAny: Bool { self == .any }
    public var isLinkLocal: Bool { rawValue.count == 16 && rawValue[0] == 0xfe && (rawValue[1] & 0xc0) == 0x80 }
    public var isMulticast: Bool { rawValue.first == 0xff }
    public var isUniqueLocal: Bool { rawValue.first == 0xfc || rawValue.first == 0xfd }
    public var isIPv4Mapped: Bool {
        rawValue.prefix(12) == Data([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff])
    }
    public var isIPv4Compatabile: Bool {
        rawValue.prefix(12) == Data(repeating: 0, count: 12) && !isLoopback && !isAny
    }
    public var is6to4: Bool { rawValue.count == 16 && rawValue[0] == 0x20 && rawValue[1] == 0x02 }
    public var asIPv4: IPv4Address? {
        guard isIPv4Mapped else { return nil }
        return IPv4Address(rawValue.suffix(4), interface)
    }
    public var multicastScope: Scope? {
        guard isMulticast else { return nil }
        return Scope(rawValue: rawValue[1] & 0x0f)
    }

    public var debugDescription: String {
        stride(from: 0, to: 16, by: 2).map { index in
            let word = UInt16(rawValue[index]) << 8 | UInt16(rawValue[index + 1])
            return String(word, radix: 16)
        }.joined(separator: ":")
    }

    private static func parseWords(_ string: String) -> [UInt16]? {
        guard !string.isEmpty, !string.contains("%") else { return nil }
        // Keep the Network shim independent of the compiler's
        // _StringProcessing overlay.  The standard substring-ranges API looks
        // harmless convenience here, but it leaves a direct runtime symbol in
        // libNetwork.  Walk Character indices instead so the framework keeps
        // the small Foundation/Concurrency closure promised by the package.
        var compressionRange: Range<String.Index>?
        var scan = string.startIndex
        while scan < string.endIndex {
            let next = string.index(after: scan)
            if string[scan] == ":", next < string.endIndex,
               string[next] == ":"
            {
                guard compressionRange == nil else { return nil }
                let upperBound = string.index(after: next)
                compressionRange = scan..<upperBound
                scan = upperBound
            } else {
                scan = next
            }
        }

        func parseSide(_ text: Substring) -> [UInt16]? {
            guard !text.isEmpty else { return [] }
            let components = text.split(separator: ":", omittingEmptySubsequences: false)
            guard !components.contains(where: { $0.isEmpty }) else { return nil }
            var words: [UInt16] = []
            for (index, component) in components.enumerated() {
                if component.contains(".") {
                    guard index == components.count - 1,
                          let bytes = IPv4Address.parseBytes(String(component))
                    else { return nil }
                    words.append(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
                    words.append(UInt16(bytes[2]) << 8 | UInt16(bytes[3]))
                } else {
                    guard component.count <= 4,
                          let word = UInt16(component, radix: 16)
                    else { return nil }
                    words.append(word)
                }
            }
            return words
        }

        if let compression = compressionRange {
            guard let left = parseSide(string[..<compression.lowerBound]),
                  let right = parseSide(string[compression.upperBound...])
            else { return nil }
            let zeroCount = 8 - left.count - right.count
            guard zeroCount >= 1 else { return nil }
            return left + Array(repeating: 0, count: zeroCount) + right
        }
        guard let words = parseSide(Substring(string)), words.count == 8 else {
            return nil
        }
        return words
    }
}

public struct NWInterface: Hashable, Sendable, CustomDebugStringConvertible {
    public enum InterfaceType: Int, Hashable, Sendable {
        case other = 0
        case wifi = 1
        case cellular = 2
        case wiredEthernet = 3
        case loopback = 4
    }

    public enum RadioType: Hashable, Sendable {
        public enum WiFi: Hashable, Sendable {
            case a, b, g, n, ac, ax
        }

        public enum Cellular: Hashable, Sendable {
            public enum NewRadio5GVariant: Hashable, Sendable {
                case mmWave
                case sub6GHz
            }

            case gsm
            case lte
            case cdma
            case evdo
            case wcdma
            case standalone5G(NewRadio5GVariant)
            case dualConnectivity5G(NewRadio5GVariant)
        }

        case wifi(WiFi)
        case cell(Cellular)
    }

    public let type: InterfaceType
    public let name: String
    public let index: Int

    public init(name: String, type: InterfaceType, index: Int = 0) {
        self.name = name
        self.type = type
        self.index = index
    }

    public var debugDescription: String { "\(name)(\(type))" }
}

public enum NWEndpoint: Hashable, Sendable, CustomDebugStringConvertible {
    public enum Host: Hashable, Sendable, ExpressibleByStringLiteral,
        CustomDebugStringConvertible
    {
        case name(String, NWInterface?)
        case ipv4(IPv4Address)
        case ipv6(IPv6Address)

        public init(_ string: String) { self = .name(string, nil) }
        public init(stringLiteral value: String) { self.init(value) }

        public typealias StringLiteralType = String
        public typealias UnicodeScalarLiteralType = StringLiteralType
        public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

        public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
            self.init(stringLiteral: value)
        }

        public init(unicodeScalarLiteral value: ExtendedGraphemeClusterLiteralType) {
            self.init(stringLiteral: value)
        }

        public var interface: NWInterface? {
            switch self {
            case .name(_, let interface): return interface
            case .ipv4(let address): return address.interface
            case .ipv6(let address): return address.interface
            }
        }

        public var debugDescription: String {
            switch self {
            case .name(let value, _): return value
            case .ipv4(let address): return address.debugDescription
            case .ipv6(let address): return address.debugDescription
            }
        }
    }

    public struct Port: Hashable, Sendable, RawRepresentable,
        ExpressibleByIntegerLiteral, CustomDebugStringConvertible
    {
        public let rawValue: UInt16
        public init?(rawValue: UInt16) { self.rawValue = rawValue }
        public init(integerLiteral value: UInt16) { rawValue = value }
        public init?(_ service: String) {
            guard let value = UInt16(service) else { return nil }
            rawValue = value
        }

        public typealias IntegerLiteralType = UInt16
        public typealias RawValue = UInt16

        public static let any: Port = 0
        public static let ssh: Port = 22
        public static let smtp: Port = 25
        public static let http: Port = 80
        public static let pop: Port = 110
        public static let imap: Port = 143
        public static let https: Port = 443
        public static let imaps: Port = 993
        public static let socks: Port = 1080

        public var debugDescription: String { String(rawValue) }
    }

    case hostPort(host: Host, port: Port)
    case service(name: String, type: String, domain: String, interface: NWInterface?)
    case unix(path: String)
    case url(URL)
    case opaque(nw_endpoint_t)

    public static func == (lhs: NWEndpoint, rhs: NWEndpoint) -> Bool {
        switch (lhs, rhs) {
        case (.hostPort(let h1, let p1), .hostPort(let h2, let p2)):
            return h1 == h2 && p1 == p2
        case (.service(let n1, let t1, let d1, let i1), .service(let n2, let t2, let d2, let i2)):
            return n1 == n2 && t1 == t2 && d1 == d2 && i1 == i2
        case (.unix(let a), .unix(let b)):
            return a == b
        case (.url(let a), .url(let b)):
            return a == b
        case (.opaque(let a), .opaque(let b)):
            return (a as AnyObject) === (b as AnyObject)
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .hostPort(let host, let port):
            hasher.combine(0)
            hasher.combine(host)
            hasher.combine(port)
        case .service(let name, let type, let domain, let interface):
            hasher.combine(1)
            hasher.combine(name)
            hasher.combine(type)
            hasher.combine(domain)
            hasher.combine(interface)
        case .unix(let path):
            hasher.combine(2)
            hasher.combine(path)
        case .url(let url):
            hasher.combine(3)
            hasher.combine(url)
        case .opaque(let endpoint):
            hasher.combine(4)
            hasher.combine(ObjectIdentifier(endpoint as AnyObject))
        }
    }

    public var interface: NWInterface? {
        switch self {
        case .hostPort(let host, _): return host.interface
        case .service(_, _, _, let interface): return interface
        case .unix, .url, .opaque: return nil
        }
    }

    public var txtRecord: NWTXTRecord? { nil }

    public var debugDescription: String {
        switch self {
        case .hostPort(let host, let port):
            return "\(host.debugDescription):\(port.rawValue)"
        case .service(let name, let type, let domain, _):
            return "\(name).\(type).\(domain)"
        case .unix(let path): return path
        case .url(let url): return url.absoluteString
        case .opaque: return "opaque"
        }
    }
}

public struct NWPath: Equatable, Sendable, CustomDebugStringConvertible {
    public enum LinkQuality: Hashable, Sendable {
        case unknown
        case minimal
        case moderate
        case good
    }

    public enum Status: Int, Sendable {
        case satisfied = 0
        case unsatisfied = 1
        case requiresConnection = 2
    }

    public enum UnsatisfiedReason: Int, Sendable {
        case notAvailable = 0
        case cellularDenied = 1
        case wifiDenied = 2
        case localNetworkDenied = 3
        case vpnInactive = 4
    }

    public let status: Status
    public let availableInterfaces: [NWInterface]
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let supportsIPv4: Bool
    public let supportsIPv6: Bool
    public let supportsDNS: Bool
    public let unsatisfiedReason: UnsatisfiedReason
    public let localEndpoint: NWEndpoint?
    public let remoteEndpoint: NWEndpoint?
    public var isUltraConstrained: Bool { false }
    public var linkQuality: LinkQuality { .unknown }
    public var gateways: [NWEndpoint] { [] }

    public init(
        status: Status = .unsatisfied,
        availableInterfaces: [NWInterface] = [],
        isExpensive: Bool = false,
        isConstrained: Bool = false,
        supportsIPv4: Bool = false,
        supportsIPv6: Bool = false,
        supportsDNS: Bool = false,
        unsatisfiedReason: UnsatisfiedReason = .notAvailable,
        localEndpoint: NWEndpoint? = nil,
        remoteEndpoint: NWEndpoint? = nil
    ) {
        self.status = status
        self.availableInterfaces = availableInterfaces
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
        self.supportsDNS = supportsDNS
        self.unsatisfiedReason = unsatisfiedReason
        self.localEndpoint = localEndpoint
        self.remoteEndpoint = remoteEndpoint
    }

    public func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        availableInterfaces.contains { $0.type == type }
    }

    public var debugDescription: String { "NWPath(\(status))" }
}

public final class NWPathMonitor: @unchecked Sendable,
    CustomDebugStringConvertible
{
    public var pathUpdateHandler: ((NWPath) -> Void)?
    public private(set) var currentPath = NWPath()
    public let requiredInterfaceType: NWInterface.InterfaceType?
    public let prohibitedInterfaceTypes: [NWInterface.InterfaceType]
    public private(set) var isStarted = false
    public private(set) var isCancelled = false

    public init() {
        requiredInterfaceType = nil
        prohibitedInterfaceTypes = []
    }

    public init(requiredInterfaceType: NWInterface.InterfaceType) {
        self.requiredInterfaceType = requiredInterfaceType
        prohibitedInterfaceTypes = []
    }

    public init(prohibitedInterfaceTypes: [NWInterface.InterfaceType]) {
        requiredInterfaceType = nil
        self.prohibitedInterfaceTypes = prohibitedInterfaceTypes
    }

    public private(set) var queue: DispatchQueue?

    public func start(queue: DispatchQueue) {
        self.queue = queue
        startGeneric()
    }

    public func start<Queue>(queue: Queue) {
        startGeneric()
    }

    private func startGeneric() {
        guard !isStarted && !isCancelled else { return }
        isStarted = true
        // No platform reachability service is queried. Delivering an explicit
        // unsatisfied snapshot cannot be mistaken for connectivity.
        pathUpdateHandler?(currentPath)
    }

    public func cancel() {
        isCancelled = true
        isStarted = false
    }

    public var debugDescription: String {
        "NWPathMonitor(started: \(isStarted), cancelled: \(isCancelled))"
    }
}

public class NWProtocol {}

public class NWProtocolDefinition {
    public let identifier: String
    public init(identifier: String) { self.identifier = identifier }
}

public class NWProtocolOptions {
    public init() {}
}

public class NWProtocolMetadata {
    public init() {}
}

public class NWProtocolTCP: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "tcp")

    public class Options: NWProtocolOptions {
        public var noDelay = false
        public var connectionTimeout: Int = 0
        public var noOptions = false
        public var disableECN = false
        public var keepaliveIdle = 0
        public var enableFastOpen = false
        public var keepaliveCount = 0
        public var persistTimeout = 0
        public var enableKeepalive = false
        public var keepaliveInterval = 0
        public var retransmitFinDrop = false
        public var connectionDropTime = 0
        public var maximumSegmentSize = 0
        public var disableAckStretching = false
        public var noPush = false
        public override init() { super.init() }
    }

    public class Metadata: NWProtocolMetadata {
        public var availableSendBuffer: UInt32 { 0 }
        public var availableReceiveBuffer: UInt32 { 0 }
    }
}

public class NWProtocolTLS: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "tls")

    public class Options: NWProtocolOptions {
        public var securityProtocolOptions: sec_protocol_options_t { sec_protocol_options() }
        public override init() { super.init() }
    }

    public class Metadata: NWProtocolMetadata {
        public var securityProtocolMetadata: sec_protocol_metadata_t { sec_protocol_metadata() }
    }
}

public class NWProtocolUDP: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "udp")

    public class Options: NWProtocolOptions {
        public var preferNoChecksum = false
        public override init() { super.init() }
    }

    public class Metadata: NWProtocolMetadata {
        public override init() { super.init() }
    }
}

public class NWProtocolIP: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "ip")

    public enum ECN: Hashable, Sendable {
        case nonECT
        case ect0
        case ect1
        case ce
    }

    public class Options: NWProtocolOptions {
        public enum Version: Hashable, Sendable { case any, v4, v6 }
        public enum AddressPreference: Hashable, Sendable {
            case `default`
            case temporary
            case stable
        }

        public var version: Version = .any
        public var hopLimit: UInt8 = 0
        public var useMinimumMTU = false
        public var disableFragmentation = false
        public var disableMulticastLoopback = false
        public var shouldCalculateReceiveTime = false
        public var localAddressPreference: AddressPreference = .default
        public override init() { super.init() }
    }

    public class Metadata: NWProtocolMetadata {
        public var receiveTime: UInt64 { 0 }
        public var serviceClass: NWParameters.ServiceClass = .bestEffort
        public var ecn: ECN = .nonECT
        public override init() { super.init() }
        @discardableResult public func serviceClass(_ serviceClass: NWParameters.ServiceClass) -> Self {
            self.serviceClass = serviceClass
            return self
        }
        @discardableResult public func ecn(_ ecn: ECN) -> Self {
            self.ecn = ecn
            return self
        }
    }
}

public final class NWParameters {
    public enum ServiceClass: Int, Sendable {
        case bestEffort = 0
        case background = 1
        case interactiveVideo = 2
        case interactiveVoice = 3
        case responsiveData = 4
        case signaling = 5
    }

    public final class ProtocolStack {
        public var internetProtocol: NWProtocolOptions? = NWProtocolIP.Options()
        public var transportProtocol: NWProtocolOptions?
        public var applicationProtocols: [NWProtocolOptions] = []
        public init() {}
    }

    public enum Attribution: Hashable, Sendable {
        case developer
        case user
    }

    public enum ExpiredDNSBehavior: Hashable, Sendable {
        case systemDefault
        case allow
        case prohibit
        case persistent
    }

    public enum MultipathServiceType: Hashable, Sendable {
        case disabled
        case handover
        case interactive
        case aggregate
    }

    public class PrivacyContext: @unchecked Sendable, CustomDebugStringConvertible {
        public static let `default` = PrivacyContext(description: "default")
        public var proxyConfigurations: [ProxyConfiguration] = []
        public let contextDescription: String
        public init(description: String) { contextDescription = description }
        public func flushCache() {}
        public func disableLogging() {}
        public func requireEncryptedNameResolution(
            _ requireEncryption: Bool,
            fallbackResolver: ResolverConfiguration?
        ) {
            _ = requireEncryption
            _ = fallbackResolver
        }
        public var debugDescription: String { contextDescription }

        public enum ResolverConfiguration: CustomDebugStringConvertible {
            case tls(NWEndpoint, serverAddresses: [NWEndpoint])
            case https(URL, serverAddresses: [NWEndpoint])
            public var debugDescription: String { "ResolverConfiguration" }
        }
    }

    public var requiredInterfaceType: NWInterface.InterfaceType = .other
    public var prohibitedInterfaceTypes: [NWInterface.InterfaceType]? = []
    public var includePeerToPeer = false
    public var allowLocalEndpointReuse = false
    public var serviceClass: ServiceClass = .bestEffort
    public let defaultProtocolStack = ProtocolStack()
    public let tcpOptions: NWProtocolTCP.Options?
    public let tlsOptions: NWProtocolTLS.Options?
    public var attribution: Attribution = .developer
    public var allowFastOpen = false
    public var acceptLocalOnly = false
    public var preferNoProxies = false
    public var requiredInterface: NWInterface?
    public var expiredDNSBehavior: ExpiredDNSBehavior = .systemDefault
    public var multipathServiceType: MultipathServiceType = .disabled
    public var prohibitedInterfaces: [NWInterface]?
    public var requiredLocalEndpoint: NWEndpoint?
    public var prohibitExpensivePaths = false
    public var prohibitConstrainedPaths = false
    public var requiresDNSSECValidation = false
    public var allowUltraConstrainedPaths = false
    public var parameters: NWParameters { self }

    public init(
        tls: NWProtocolTLS.Options?,
        tcp: NWProtocolTCP.Options = NWProtocolTCP.Options()
    ) {
        tlsOptions = tls
        tcpOptions = tcp
        defaultProtocolStack.transportProtocol = tcp
        if let tls {
            defaultProtocolStack.applicationProtocols = [tls]
        }
    }

    public convenience init(dtls: NWProtocolTLS.Options?, udp: NWProtocolUDP.Options = NWProtocolUDP.Options()) {
        self.init(tls: dtls, tcp: NWProtocolTCP.Options())
        defaultProtocolStack.transportProtocol = udp
    }

    public convenience init(quic: NWProtocolQUIC.Options) {
        self.init(tls: nil, tcp: NWProtocolTCP.Options())
        defaultProtocolStack.transportProtocol = quic
    }

    public init() {
        tcpOptions = nil
        tlsOptions = nil
    }

    private init(tcp: NWProtocolTCP.Options?) {
        tcpOptions = tcp
        tlsOptions = nil
        defaultProtocolStack.transportProtocol = tcp
    }

    public static var tcp: NWParameters { NWParameters(tcp: .init()) }
    public static var udp: NWParameters { NWParameters(tcp: nil) }
    public static var tls: NWParameters { NWParameters(tls: .init(), tcp: .init()) }
    public static var dtls: NWParameters { NWParameters(dtls: .init()) }
    public static var applicationService: NWParameters { NWParameters() }
    public class func quic(alpn: [String]) -> NWParameters {
        NWParameters(quic: NWProtocolQUIC.Options(alpn: alpn))
    }
    public class func quicDatagram(alpn: [String]) -> NWParameters {
        quic(alpn: alpn)
    }

    public func copy() -> NWParameters { self }
    public func setPrivacyContext(_ privacyContext: PrivacyContext) { _ = privacyContext }

    @discardableResult public func serviceClass(_ serviceClass: ServiceClass) -> Self {
        self.serviceClass = serviceClass
        return self
    }
    @discardableResult public func localEndpoint(_ endpoint: NWEndpoint?) -> Self {
        requiredLocalEndpoint = endpoint
        return self
    }
    @discardableResult public func fastOpenAllowed(_ allowed: Bool) -> Self {
        allowFastOpen = allowed
        return self
    }
    @discardableResult public func requiredInterface(_ interface: NWInterface) -> Self {
        requiredInterface = interface
        return self
    }
    @discardableResult public func expiredDNSBehavior(_ behavior: ExpiredDNSBehavior) -> Self {
        expiredDNSBehavior = behavior
        return self
    }
    @discardableResult public func noProxiesPreferred(_ noProxies: Bool) -> Self {
        preferNoProxies = noProxies
        return self
    }
    @discardableResult public func peerToPeerIncluded(_ included: Bool) -> Self {
        includePeerToPeer = included
        return self
    }
    @discardableResult public func multipathServiceType(_ type: MultipathServiceType) -> Self {
        multipathServiceType = type
        return self
    }
    @discardableResult public func prohibitedInterfaces(_ interfaces: [NWInterface]) -> Self {
        prohibitedInterfaces = interfaces
        return self
    }
    @discardableResult public func requiredInterfaceType(_ type: NWInterface.InterfaceType) -> Self {
        requiredInterfaceType = type
        return self
    }
    @discardableResult public func dnssecValidationRequired(_ required: Bool) -> Self {
        requiresDNSSECValidation = required
        return self
    }
    @discardableResult public func expensivePathsProhibited(_ prohibited: Bool) -> Self {
        prohibitExpensivePaths = prohibited
        return self
    }
    @discardableResult public func prohibitedInterfaceTypes(_ types: [NWInterface.InterfaceType]) -> Self {
        prohibitedInterfaceTypes = types
        return self
    }
    @discardableResult public func localEndpointReuseAllowed(_ allowed: Bool) -> Self {
        allowLocalEndpointReuse = allowed
        return self
    }
    @discardableResult public func constrainedPathsProhibited(_ prohibited: Bool) -> Self {
        prohibitConstrainedPaths = prohibited
        return self
    }
    @discardableResult public func ultraConstrainedPathsAllowed(_ val: Bool) -> Self {
        allowUltraConstrainedPaths = val
        return self
    }
    @discardableResult public func localOnly(_ local: Bool) -> Self {
        acceptLocalOnly = local
        return self
    }
    @discardableResult public func localPort(_ port: NWEndpoint.Port) -> Self {
        requiredLocalEndpoint = .hostPort(host: .name("0.0.0.0", nil), port: port)
        return self
    }

    public var debugDescription: String { "NWParameters(\(serviceClass))" }
}

public final class NWConnection: @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case preparing
        case ready
        case failed(NWError)
        case cancelled
    }

    public class ContentContext {
        public static let defaultMessage = ContentContext(identifier: "default")
        public let identifier: String
        public init(identifier: String) { self.identifier = identifier }
    }

    public enum SendCompletion {
        case idempotent
        case contentProcessed((NWError?) -> Void)
    }

    public let endpoint: NWEndpoint
    public let parameters: NWParameters
    public var stateUpdateHandler: ((State) -> Void)?
    public var viabilityUpdateHandler: ((Bool) -> Void)?
    public var betterPathUpdateHandler: ((Bool) -> Void)?
    public private(set) var state: State = .setup

    public init(to endpoint: NWEndpoint, using parameters: NWParameters) {
        self.endpoint = endpoint
        self.parameters = parameters
    }

    public convenience init(
        host: NWEndpoint.Host,
        port: NWEndpoint.Port,
        using parameters: NWParameters
    ) {
        self.init(to: .hostPort(host: host, port: port), using: parameters)
    }

    public private(set) var queue: DispatchQueue?
    public private(set) var currentPath: NWPath?
    public var pathUpdateHandler: ((NWPath) -> Void)?

    public func start(queue: DispatchQueue) {
        self.queue = queue
        failClosedStart()
    }

    public func start<Queue>(queue: Queue) {
        failClosedStart()
    }

    private func failClosedStart() {
        guard state == .setup else { return }
        state = .preparing
        stateUpdateHandler?(.preparing)
        state = .failed(.unsupported)
        viabilityUpdateHandler?(false)
        stateUpdateHandler?(.failed(.unsupported))
    }

    public func cancel() {
        state = .cancelled
        stateUpdateHandler?(.cancelled)
    }

    public func forceCancel() { cancel() }
    public func cancelCurrentEndpoint() { cancel() }

    public func send(
        content: Data?,
        contentContext: ContentContext = .defaultMessage,
        isComplete: Bool = true,
        completion: SendCompletion
    ) {
        if case .contentProcessed(let handler) = completion {
            handler(.unsupported)
        }
    }

    public func receive(
        minimumIncompleteLength: Int,
        maximumLength: Int,
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        completion(nil, nil, false, .unsupported)
    }

    public func receiveMessage(
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        completion(nil, nil, false, .unsupported)
    }
}

public final class NWListener {
    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case ready
        case failed(NWError)
        case cancelled
    }

    public let parameters: NWParameters
    public let port: NWEndpoint.Port?
    public var stateUpdateHandler: ((State) -> Void)?
    public var newConnectionHandler: ((NWConnection) -> Void)?
    public private(set) var state: State = .setup

    public init(
        using parameters: NWParameters,
        on port: NWEndpoint.Port = .any
    ) throws {
        self.parameters = parameters
        self.port = port
    }

    public private(set) var queue: DispatchQueue?
    public var newConnectionGroupHandler: ((NWConnectionGroup) -> Void)?
    public var serviceRegistrationUpdateHandler: ((ServiceRegistrationChange) -> Void)?
    public var newConnectionLimit: Int = NWListener.InfiniteConnectionLimit
    public static let InfiniteConnectionLimit = Int(NW_LISTENER_INFINITE_CONNECTION_LIMIT)
    public var service: Service?

    public enum ServiceRegistrationChange {
        case add(NWEndpoint)
        case remove(NWEndpoint)
    }

    public struct Service: Hashable, Sendable, CustomDebugStringConvertible {
        public let name: String?
        public let type: String
        public let domain: String?
        public let txtRecord: Data?
        public var noAutoRename = false
        public var txtRecordObject: NWTXTRecord?

        public init(applicationService: String) {
            name = applicationService
            type = "_app._tcp"
            domain = nil
            txtRecord = nil
        }

        public init(name: String? = nil, type: String, domain: String? = nil, txtRecord: Data? = nil) {
            self.name = name
            self.type = type
            self.domain = domain
            self.txtRecord = txtRecord
        }

        public init(name: String? = nil, type: String, domain: String? = nil, txtRecord: NWTXTRecord) {
            self.name = name
            self.type = type
            self.domain = domain
            self.txtRecord = nil
            self.txtRecordObject = txtRecord
        }

        public var debugDescription: String { "\(name ?? "").\(type).\(domain ?? "")" }
    }

    public convenience init(applicationService name: String, using parameters: NWParameters = .applicationService) throws {
        try self.init(using: parameters, on: .any)
        self.service = Service(applicationService: name)
    }

    public convenience init(service: Service, using parameters: NWParameters) throws {
        try self.init(using: parameters, on: .any)
        self.service = service
    }

    public func start(queue: DispatchQueue) {
        self.queue = queue
        failClosedStart()
    }

    public func start<Queue>(queue: Queue) {
        failClosedStart()
    }

    private func failClosedStart() {
        guard state == .setup else { return }
        state = .failed(.unsupported)
        stateUpdateHandler?(.failed(.unsupported))
    }

    public func cancel() {
        state = .cancelled
        stateUpdateHandler?(.cancelled)
    }
}
