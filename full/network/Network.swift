import Foundation

public enum NWError: Error, Equatable, Sendable, CustomStringConvertible {
    case posix(Int32)
    case dns(Int32)
    case tls(Int32)
    case unsupported

    public var description: String {
        switch self {
        case .posix(let code): return "POSIX network error \(code)"
        case .dns(let code): return "DNS network error \(code)"
        case .tls(let code): return "TLS network error \(code)"
        case .unsupported: return "Network transport is unavailable on this host"
        }
    }
}

/// A parsed IPv4 address. Parsing is local and deterministic; constructing an
/// address does not imply that a network interface or route exists.
public struct IPv4Address: Hashable, Sendable, RawRepresentable,
    CustomDebugStringConvertible
{
    public let rawValue: Data

    public init?(rawValue: Data) {
        guard rawValue.count == 4 else { return nil }
        self.rawValue = rawValue
    }

    public init?(_ data: Data) { self.init(rawValue: data) }

    public init?(_ string: String) {
        guard let bytes = Self.parseBytes(string) else { return nil }
        rawValue = Data(bytes)
    }

    public static let any = IPv4Address(rawValue: Data(repeating: 0, count: 4))!
    public static let broadcast = IPv4Address(
        rawValue: Data(repeating: 255, count: 4)
    )!
    public static let loopback = IPv4Address("127.0.0.1")!

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
public struct IPv6Address: Hashable, Sendable, RawRepresentable,
    CustomDebugStringConvertible
{
    public let rawValue: Data

    public init?(rawValue: Data) {
        guard rawValue.count == 16 else { return nil }
        self.rawValue = rawValue
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
        rawValue = Data(bytes)
    }

    public static let any = IPv6Address(rawValue: Data(repeating: 0, count: 16))!
    public static let loopback = IPv6Address("::1")!

    public var debugDescription: String {
        stride(from: 0, to: 16, by: 2).map { index in
            let word = UInt16(rawValue[index]) << 8 | UInt16(rawValue[index + 1])
            return String(word, radix: 16)
        }.joined(separator: ":")
    }

    private static func parseWords(_ string: String) -> [UInt16]? {
        guard !string.isEmpty, !string.contains("%") else { return nil }
        let compressionRanges = string.ranges(of: "::")
        guard compressionRanges.count <= 1 else { return nil }

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

        if let compression = compressionRanges.first {
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

        public init(_ string: String) { self = .name(string, nil) }
        public init(stringLiteral value: String) { self.init(value) }

        public var debugDescription: String {
            switch self { case .name(let value, _): return value }
        }
    }

    public struct Port: Hashable, Sendable, RawRepresentable,
        ExpressibleByIntegerLiteral, CustomDebugStringConvertible
    {
        public let rawValue: UInt16
        public init?(rawValue: UInt16) { self.rawValue = rawValue }
        public init(integerLiteral value: UInt16) { rawValue = value }

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

    public var debugDescription: String {
        switch self {
        case .hostPort(let host, let port):
            return "\(host.debugDescription):\(port.rawValue)"
        case .service(let name, let type, let domain, _):
            return "\(name).\(type).\(domain)"
        case .unix(let path): return path
        }
    }
}

public struct NWPath: Equatable, Sendable, CustomDebugStringConvertible {
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

    public init(
        status: Status = .unsatisfied,
        availableInterfaces: [NWInterface] = [],
        isExpensive: Bool = false,
        isConstrained: Bool = false,
        supportsIPv4: Bool = false,
        supportsIPv6: Bool = false,
        supportsDNS: Bool = false,
        unsatisfiedReason: UnsatisfiedReason = .notAvailable
    ) {
        self.status = status
        self.availableInterfaces = availableInterfaces
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
        self.supportsDNS = supportsDNS
        self.unsatisfiedReason = unsatisfiedReason
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

    public func start<Queue>(queue: Queue) {
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

public enum NWProtocolTCP {
    public final class Options {
        public var noDelay = false
        public var connectionTimeout: Int = 0
        public init() {}
    }
}

public enum NWProtocolTLS {
    public final class Options { public init() {} }
}

public enum NWProtocolIP {
    public final class Options {
        public enum Version: Int, Sendable { case any = 0, v4 = 4, v6 = 6 }
        public var version: Version = .any
        public init() {}
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
        public var internetProtocol: Any? = NWProtocolIP.Options()
        public init() {}
    }

    public var requiredInterfaceType: NWInterface.InterfaceType?
    public var prohibitedInterfaceTypes: [NWInterface.InterfaceType] = []
    public var includePeerToPeer = false
    public var allowLocalEndpointReuse = false
    public var serviceClass: ServiceClass = .bestEffort
    public let defaultProtocolStack = ProtocolStack()
    public let tcpOptions: NWProtocolTCP.Options?
    public let tlsOptions: NWProtocolTLS.Options?

    public init(
        tls: NWProtocolTLS.Options?,
        tcp: NWProtocolTCP.Options
    ) {
        tlsOptions = tls
        tcpOptions = tcp
    }

    private init(tcp: NWProtocolTCP.Options?) {
        tcpOptions = tcp
        tlsOptions = nil
    }

    public static var tcp: NWParameters { NWParameters(tcp: .init()) }
    public static var udp: NWParameters { NWParameters(tcp: nil) }
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

    public final class ContentContext {
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

    public func start<Queue>(queue: Queue) {
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

    public func start<Queue>(queue: Queue) {
        guard state == .setup else { return }
        state = .failed(.unsupported)
        stateUpdateHandler?(.failed(.unsupported))
    }

    public func cancel() {
        state = .cancelled
        stateUpdateHandler?(.cancelled)
    }
}
