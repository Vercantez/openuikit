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

    /// RFC 1122 §3.2.1.3: 127.0.0.0/8 is loopback (not only 127.0.0.1).
    public var isLoopback: Bool { rawValue.first == 127 }
    /// RFC 3927: 169.254.0.0/16.
    public var isLinkLocal: Bool { rawValue.count == 4 && rawValue[0] == 169 && rawValue[1] == 254 }
    /// RFC 1112: 224.0.0.0/4.
    public var isMulticast: Bool {
        guard let first = rawValue.first else { return false }
        return first >= 224 && first <= 239
    }

    public var debugDescription: String {
        rawValue.map(String.init).joined(separator: ".")
    }

    public var description: String { debugDescription }

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
        let (literal, zone) = nwSplitZone(string)
        guard let words = Self.parseWords(literal) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(16)
        for word in words {
            bytes.append(UInt8(word >> 8))
            bytes.append(UInt8(word & 0xff))
        }
        self.rawValue = Data(bytes)
        if let zone {
            self.interface = NWPOSIX.interfaceForZone(zone)
        } else {
            self.interface = nil
        }
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
        let body = stride(from: 0, to: 16, by: 2).map { index in
            let word = UInt16(rawValue[index]) << 8 | UInt16(rawValue[index + 1])
            return String(word, radix: 16)
        }.joined(separator: ":")
        if let interface {
            return body + "%" + interface.name
        }
        return body
    }

    public var description: String { debugDescription }

    private static func parseWords(_ string: String) -> [UInt16]? {
        guard !string.isEmpty else { return nil }
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
                if nwContainsDot(component) {
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

        public init(_ string: String) {
            let literal = nwStripBrackets(string)
            if let v4 = IPv4Address(literal) {
                self = .ipv4(v4)
            } else if let v6 = IPv6Address(literal) {
                self = .ipv6(v6)
            } else {
                self = .name(string, nil)
            }
        }
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
            if let value = UInt16(service) {
                rawValue = value
                return
            }
            switch service {
            case "ssh": rawValue = 22
            case "smtp": rawValue = 25
            case "http": rawValue = 80
            case "pop": rawValue = 110
            case "imap": rawValue = 143
            case "https": rawValue = 443
            case "imaps": rawValue = 993
            case "socks": rawValue = 1080
            default: return nil
            }
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
            switch host {
            case .ipv6:
                return "[\(host.debugDescription)]:\(port.rawValue)"
            default:
                return "\(host.debugDescription):\(port.rawValue)"
            }
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
    public let gateways: [NWEndpoint]

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
        remoteEndpoint: NWEndpoint? = nil,
        gateways: [NWEndpoint] = []
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
        self.gateways = gateways
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
        NWPOSIX.tag(queue)
        startGeneric()
    }

    public func start<Queue>(queue: Queue) {
        if let dispatchQueue = queue as? DispatchQueue {
            self.queue = dispatchQueue
            NWPOSIX.tag(dispatchQueue)
        }
        startGeneric()
    }

    private func startGeneric() {
        guard !isStarted && !isCancelled else { return }
        isStarted = true
        // Measured: getifaddrs; .satisfied iff a non-loopback interface has an
        // address. Handlers run on the supplied queue via sync so a host test
        // can observe the first snapshot before start returns.
        currentPath = NWPOSIX.makePath(
            required: requiredInterfaceType,
            prohibited: prohibitedInterfaceTypes
        )
        let path = currentPath
        let handler = pathUpdateHandler
        NWPOSIX.run(queue) { handler?(path) }
    }

    public func cancel() {
        isCancelled = true
        isStarted = false
    }

    public var debugDescription: String {
        "NWPathMonitor(started: \(isStarted), cancelled: \(isCancelled))"
    }

    public struct Iterator: AsyncIteratorProtocol {
        public typealias Element = NWPath
        let path: NWPath
        var consumed = false
        public mutating func next() async -> NWPath? {
            if consumed { return nil }
            consumed = true
            return path
        }
    }

    public typealias AsyncIterator = Iterator

    public func makeAsyncIterator() -> Iterator {
        Iterator(path: currentPath)
    }
}

extension NWPathMonitor: AsyncSequence {
    public typealias Element = NWPath
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
        public let securityProtocolOptions: sec_protocol_options_t
        public override init() {
            self.securityProtocolOptions = sec_protocol_options()
            super.init()
        }
    }

    public class Metadata: NWProtocolMetadata {
        public let securityProtocolMetadata: sec_protocol_metadata_t
        public override init() {
            self.securityProtocolMetadata = sec_protocol_metadata()
            super.init()
        }
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
    public static var udp: NWParameters { NWParameters(dtls: nil, udp: .init()) }
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

    /// Incoming socket from `NWListener`. Already connected; `start` marks ready.
    fileprivate init(
        connectedFD: Int32,
        endpoint: NWEndpoint,
        parameters: NWParameters,
        firstDatagram: Data?
    ) {
        self.endpoint = endpoint
        self.parameters = parameters
        self.fd = connectedFD
        self.pendingDatagram = firstDatagram
        self.preconnected = true
        self.isUDP = NWPOSIX.isUDP(parameters)
    }

    public private(set) var queue: DispatchQueue?
    public private(set) var currentPath: NWPath?
    public var pathUpdateHandler: ((NWPath) -> Void)?

    private let lock = NSLock()
    private var fd: Int32 = -1
    private var isUDP = false
    private var preconnected = false
    private var pendingDatagram: Data?
    private var lastContentContext: ContentContext = .defaultMessage
    private var lastSendComplete = true

    deinit { closeSocket() }

    public func start(queue: DispatchQueue) {
        self.queue = queue
        NWPOSIX.tag(queue)
        startTransport()
    }

    public func start<Queue>(queue: Queue) {
        if let dispatchQueue = queue as? DispatchQueue {
            self.queue = dispatchQueue
            NWPOSIX.tag(dispatchQueue)
        }
        startTransport()
    }

    private func startTransport() {
        lock.lock()
        guard state == .setup else {
            lock.unlock()
            return
        }
        lock.unlock()
        emit(.preparing)
        if NWPOSIX.wantsTLS(parameters) {
            // No TLS stack on Linux. Fail closed with SecureTransport errSSLProtocol.
            emit(.failed(.tls(NWPOSIX.tlsUnsupportedStatus)))
            viabilityUpdateHandler?(false)
            betterPathUpdateHandler?(false)
            return
        }
        if NWPOSIX.wantsQUIC(parameters) {
            // No QUIC stack on Linux. Fail closed; Options remain a data model.
            emit(.failed(.posix(.EOPNOTSUPP)))
            viabilityUpdateHandler?(false)
            betterPathUpdateHandler?(false)
            return
        }
        if preconnected {
            becomeReady()
            return
        }
        switch endpoint {
        case .hostPort(let host, let port):
            connectHost(host, port: port)
        case .unix(let path):
            connectUnixPath(path)
        case .url(let url):
            connectURL(url)
        case .service:
            // No Bonjour / mDNS on Linux. waiting then failed exercises the
            // documented state machine without fabricating a browse result.
            emit(.waiting(.posix(.EOPNOTSUPP)))
            emit(.failed(.posix(.EOPNOTSUPP)))
            viabilityUpdateHandler?(false)
        case .opaque:
            emit(.failed(.posix(.EOPNOTSUPP)))
            viabilityUpdateHandler?(false)
        }
    }

    private func connectHost(_ host: NWEndpoint.Host, port: NWEndpoint.Port) {
        isUDP = NWPOSIX.isUDP(parameters)
        let resolved = NWPOSIX.resolveHost(host)
        if let error = resolved.2 {
            emit(.failed(error))
            viabilityUpdateHandler?(false)
            return
        }
        if let v4 = resolved.0 {
            guard let socket = NWPOSIX.makeSocket(udp: isUDP) else {
                failPOSIX()
                return
            }
            fd = socket
            if parameters.allowLocalEndpointReuse {
                NWPOSIX.setReuseAddr(fd)
            }
            if let tcp = parameters.tcpOptions {
                NWPOSIX.applyTCPOptions(fd, tcp)
            }
            if let error = NWPOSIX.connectIPv4(fd: fd, address: v4, port: port.rawValue) {
                NWPOSIX.closeFD(fd)
                fd = -1
                emit(.failed(error))
                viabilityUpdateHandler?(false)
                return
            }
            becomeReady()
            return
        }
        if let v6 = resolved.1 {
            var socketFD: Int32 = -1
            if let error = NWPOSIX.connectIPv6Replacing(fd: &socketFD, address: v6, port: port.rawValue, udp: isUDP) {
                emit(.failed(error))
                viabilityUpdateHandler?(false)
                return
            }
            fd = socketFD
            becomeReady()
            return
        }
        emit(.failed(.dns(Int32(-2))))
        viabilityUpdateHandler?(false)
    }

    private func connectUnixPath(_ path: String) {
        isUDP = NWPOSIX.isUDP(parameters)
        guard let socket = NWPOSIX.makeUnixSocket(udp: isUDP) else {
            failPOSIX()
            return
        }
        fd = socket
        if let error = NWPOSIX.connectUnix(fd: fd, path: path) {
            NWPOSIX.closeFD(fd)
            fd = -1
            emit(.failed(error))
            viabilityUpdateHandler?(false)
            return
        }
        becomeReady()
    }

    private func connectURL(_ url: URL) {
        guard let hostString = url.host else {
            emit(.failed(.posix(.EINVAL)))
            viabilityUpdateHandler?(false)
            return
        }
        let portValue: UInt16
        if let port = url.port {
            portValue = UInt16(port)
        } else if url.scheme == "https" || url.scheme == "wss" {
            portValue = 443
        } else {
            portValue = 80
        }
        connectHost(NWEndpoint.Host(hostString), port: NWEndpoint.Port(integerLiteral: portValue))
    }

    private func becomeReady() {
        currentPath = NWPOSIX.makePath(required: nil, prohibited: [])
        if let path = currentPath {
            pathUpdateHandler?(path)
        }
        emit(.ready)
        viabilityUpdateHandler?(true)
        betterPathUpdateHandler?(false)
    }

    private func failPOSIX() {
        let error = NWPOSIX.lastPOSIXError()
        emit(.failed(error))
        viabilityUpdateHandler?(false)
    }

    private func emit(_ newState: State) {
        lock.lock()
        state = newState
        lock.unlock()
        let handler = stateUpdateHandler
        NWPOSIX.run(queue) { handler?(newState) }
    }

    public func cancel() {
        closeSocket()
        emit(.cancelled)
    }

    public func forceCancel() { cancel() }
    public func cancelCurrentEndpoint() { cancel() }

    private func closeSocket() {
        lock.lock()
        let socket = fd
        fd = -1
        lock.unlock()
        NWPOSIX.closeFD(socket)
    }

    public func send(
        content: Data?,
        contentContext: ContentContext = .defaultMessage,
        isComplete: Bool = true,
        completion: SendCompletion
    ) {
        lock.lock()
        lastContentContext = contentContext
        lastSendComplete = isComplete
        let socket = fd
        let current = state
        lock.unlock()
        let error: NWError?
        switch current {
        case .ready:
            error = NWPOSIX.sendBytes(fd: socket, data: content ?? Data())
        case .failed(let existing):
            error = existing
        case .cancelled:
            error = NWPOSIX.cancelledError
        default:
            error = NWPOSIX.notConnectedError
        }
        if case .contentProcessed(let handler) = completion {
            NWPOSIX.run(queue) { handler(error) }
        }
    }

    public func receive(
        minimumIncompleteLength: Int,
        maximumLength: Int,
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        receiveBody(
            minimumIncompleteLength: minimumIncompleteLength,
            maximumLength: maximumLength,
            message: false,
            completion: completion
        )
    }

    public func receiveMessage(
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        receiveBody(
            minimumIncompleteLength: 1,
            maximumLength: 65535,
            message: true,
            completion: completion
        )
    }

    private func receiveBody(
        minimumIncompleteLength: Int,
        maximumLength: Int,
        message: Bool,
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        lock.lock()
        if let pending = pendingDatagram {
            pendingDatagram = nil
            let socket = fd
            let current = state
            lock.unlock()
            _ = socket
            deliverReceive(pending, complete: true, error: currentError(current), completion: completion)
            return
        }
        let socket = fd
        let current = state
        lock.unlock()
        switch current {
        case .ready:
            break
        case .failed(let error):
            deliverReceive(nil, complete: false, error: error, completion: completion)
            return
        case .cancelled:
            deliverReceive(nil, complete: false, error: NWPOSIX.cancelledError, completion: completion)
            return
        default:
            deliverReceive(nil, complete: false, error: NWPOSIX.notConnectedError, completion: completion)
            return
        }
        let work = {
            var collected = Data()
            var complete = false
            var error: NWError?
            let cap = max(maximumLength, 1)
            while collected.count < (message ? 1 : max(minimumIncompleteLength, 1)) {
                let remaining = cap - collected.count
                if remaining <= 0 { break }
                let chunk = NWPOSIX.recvBytes(fd: socket, maximumLength: remaining)
                if let recvError = chunk.2 {
                    error = recvError
                    break
                }
                if chunk.1 {
                    complete = true
                    break
                }
                if let data = chunk.0 {
                    collected.append(data)
                }
                if message { break }
            }
            self.deliverReceive(
                collected.isEmpty && error != nil ? nil : collected,
                complete: complete,
                error: error,
                completion: completion
            )
        }
        Thread { work() }.start()
    }

    private func currentError(_ state: State) -> NWError? {
        switch state {
        case .failed(let error): return error
        case .cancelled: return NWPOSIX.cancelledError
        default: return nil
        }
    }

    private func deliverReceive(
        _ data: Data?,
        complete: Bool,
        error: NWError?,
        completion: @escaping (Data?, ContentContext?, Bool, NWError?) -> Void
    ) {
        lock.lock()
        let context = lastContentContext
        lock.unlock()
        let finish = {
            completion(data, context, complete, error)
        }
        if let queue {
            NWPOSIX.run(queue, finish)
        } else {
            finish()
        }
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
    public private(set) var port: NWEndpoint.Port?
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

    private let lock = NSLock()
    private var listenFD: Int32 = -1
    private var isUDP = false

    deinit { cancel() }

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
        NWPOSIX.tag(queue)
        startListen()
    }

    public func start<Queue>(queue: Queue) {
        if let dispatchQueue = queue as? DispatchQueue {
            self.queue = dispatchQueue
            NWPOSIX.tag(dispatchQueue)
        }
        startListen()
    }

    private func startListen() {
        lock.lock()
        guard state == .setup else {
            lock.unlock()
            return
        }
        lock.unlock()
        if NWPOSIX.wantsTLS(parameters) {
            emit(.failed(.tls(NWPOSIX.tlsUnsupportedStatus)))
            return
        }
        if service != nil {
            // No mDNS responder: service advertisement is fail-closed.
            emit(.failed(.posix(.EOPNOTSUPP)))
            return
        }
        isUDP = NWPOSIX.isUDP(parameters)
        guard let socket = NWPOSIX.makeSocket(udp: isUDP) else {
            emit(.failed(NWPOSIX.lastPOSIXError()))
            return
        }
        if parameters.allowLocalEndpointReuse {
            NWPOSIX.setReuseAddr(socket)
        } else {
            // Loopback tests reuse ports immediately; SO_REUSEADDR is the POSIX
            // mapping of allowLocalEndpointReuse, also applied on .any so a
            // second start in the same process can bind.
            NWPOSIX.setReuseAddr(socket)
        }
        let requested = port?.rawValue ?? 0
        guard let assigned = NWPOSIX.bindLoopback(fd: socket, port: requested) else {
            let error = NWPOSIX.lastPOSIXError()
            NWPOSIX.closeFD(socket)
            emit(.failed(error))
            return
        }
        if !isUDP {
            guard NWPOSIX.listenTCP(socket) else {
                let error = NWPOSIX.lastPOSIXError()
                NWPOSIX.closeFD(socket)
                emit(.failed(error))
                return
            }
        }
        lock.lock()
        listenFD = socket
        port = NWEndpoint.Port(integerLiteral: assigned)
        lock.unlock()
        emit(.ready)
        Thread { [weak self] in
            self?.acceptLoop()
        }.start()
    }

    private func acceptLoop() {
        while true {
            lock.lock()
            let socket = listenFD
            let cancelled: Bool
            switch state {
            case .cancelled, .failed: cancelled = true
            default: cancelled = false
            }
            let udp = isUDP
            lock.unlock()
            if cancelled || socket < 0 { return }
            let accepted: NWPOSIX.Accepted?
            if udp {
                accepted = NWPOSIX.recvFromUDP(listenFD: socket)
            } else {
                accepted = NWPOSIX.acceptTCP(listenFD: socket)
            }
            guard let accepted else {
                let code = errno
                if code == EBADF || code == EINVAL || code == ECONNABORTED {
                    return
                }
                continue
            }
            let connection = NWConnection(
                connectedFD: accepted.fd,
                endpoint: accepted.endpoint,
                parameters: parameters,
                firstDatagram: accepted.firstDatagram
            )
            let handler = newConnectionHandler
            NWPOSIX.run(queue) { handler?(connection) }
        }
    }

    private func emit(_ newState: State) {
        lock.lock()
        state = newState
        lock.unlock()
        let handler = stateUpdateHandler
        NWPOSIX.run(queue) { handler?(newState) }
    }

    public func cancel() {
        lock.lock()
        let socket = listenFD
        listenFD = -1
        lock.unlock()
        NWPOSIX.closeFD(socket)
        emit(.cancelled)
    }

    public var debugDescription: String { "NWListener(\(state))" }
}
