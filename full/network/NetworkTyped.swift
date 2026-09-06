import Foundation

// MARK: - iOS 26 protocol-stack types (Linux starting point)
//
// These overlay types wrap the existing POSIX NWConnection / NWListener
// transport. TLS/QUIC/Bonjour remain fail-closed. Async Apple run loops are
// not driven here; start() is synchronous and reports the first state before
// returning, matching the classic NWConnection Linux path.

public protocol ConnectionStorage {
    init()
}

public struct DefaultProtocolStorage: ConnectionStorage {
    public init() {}
}

public protocol NetworkMetadataProtocol {}

public protocol NetworkProtocolOptions {
    associatedtype BelowProtocol
    associatedtype ProtocolStorage: ConnectionStorage = DefaultProtocolStorage
    associatedtype Metadata: NetworkMetadataProtocol
    typealias Message<T> = (content: T, metadata: Metadata)
    var parameters: NWParameters { get }
}

public protocol OneToOneProtocol: NetworkProtocolOptions {}
public protocol StreamProtocol: OneToOneProtocol {}
public protocol MessageProtocol: OneToOneProtocol {
    associatedtype LegacyMessage
    associatedtype ContentType
}
public protocol DatagramProtocol: MessageProtocol {}
public protocol MultiplexProtocol: NetworkProtocolOptions {}

public protocol NetworkFixedWidthInteger: FixedWidthInteger {}
extension UInt8: NetworkFixedWidthInteger {}

public protocol NetworkEncoder {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

public protocol NetworkDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

public protocol NetworkCoder: Sendable {
    associatedtype Decoder: NetworkDecoder
    associatedtype Encoder: NetworkEncoder
    init()
    func makeDecoder() -> Decoder
    func makeEncoder() -> Encoder
}

extension JSONEncoder: NetworkEncoder {}
extension JSONDecoder: NetworkDecoder {}
extension PropertyListEncoder: NetworkEncoder {}
extension PropertyListDecoder: NetworkDecoder {}

public struct NetworkJSONCoder: NetworkCoder {
    public typealias Decoder = JSONDecoder
    public typealias Encoder = JSONEncoder
    public init() {}
    public func makeDecoder() -> JSONDecoder { JSONDecoder() }
    public func makeEncoder() -> JSONEncoder { JSONEncoder() }
    public static var json: NetworkJSONCoder { NetworkJSONCoder() }
}

public struct NetworkPropertyListCoder: NetworkCoder {
    public typealias Decoder = PropertyListDecoder
    public typealias Encoder = PropertyListEncoder
    public init() {}
    public func makeDecoder() -> PropertyListDecoder { PropertyListDecoder() }
    public func makeEncoder() -> PropertyListEncoder { PropertyListEncoder() }
    public static var propertyList: NetworkPropertyListCoder { NetworkPropertyListCoder() }
}

extension NetworkCoder where Self == NetworkJSONCoder {
    public static var json: NetworkJSONCoder { NetworkJSONCoder() }
}

extension NetworkCoder where Self == NetworkPropertyListCoder {
    public static var propertyList: NetworkPropertyListCoder { NetworkPropertyListCoder() }
}

public protocol FramerProtocol {
    static var definition: NWProtocolFramer.Definition { get }
}

public protocol Connectable {}

extension NWEndpoint: Connectable {}

public protocol ListenerProvider {
    var service: NWListener.Service { get }
}

public protocol BrowserProvider: Sendable {
    associatedtype Endpoint: Connectable
}

public protocol NWParametersProvider {
    var parameters: NWParameters { get }
    func serviceClass(_ serviceClass: NWParameters.ServiceClass) -> Self
    func localEndpoint(_ endpoint: NWEndpoint?) -> Self
    func fastOpenAllowed(_ allowed: Bool) -> Self
    func requiredInterface(_ interface: NWInterface) -> Self
    func expiredDNSBehavior(_ behavior: NWParameters.ExpiredDNSBehavior) -> Self
    func noProxiesPreferred(_ preferred: Bool) -> Self
    func peerToPeerIncluded(_ included: Bool) -> Self
    func multipathServiceType(_ type: NWParameters.MultipathServiceType) -> Self
    func prohibitedInterfaces(_ interfaces: [NWInterface]) -> Self
    func requiredInterfaceType(_ type: NWInterface.InterfaceType) -> Self
    func dnssecValidationRequired(_ required: Bool) -> Self
    func expensivePathsProhibited(_ prohibited: Bool) -> Self
    func prohibitedInterfaceTypes(_ types: [NWInterface.InterfaceType]) -> Self
    func localEndpointReuseAllowed(_ allowed: Bool) -> Self
    func constrainedPathsProhibited(_ prohibited: Bool) -> Self
    func ultraConstrainedPathsAllowed(_ allowed: Bool) -> Self
    func localOnly(_ local: Bool) -> Self
    func localPort(_ port: NWEndpoint.Port) -> Self
}

extension NWParametersProvider {
    public func serviceClass(_ serviceClass: NWParameters.ServiceClass) -> Self {
        _ = parameters.serviceClass(serviceClass)
        return self
    }
    public func localEndpoint(_ endpoint: NWEndpoint?) -> Self {
        _ = parameters.localEndpoint(endpoint)
        return self
    }
    public func fastOpenAllowed(_ allowed: Bool) -> Self {
        _ = parameters.fastOpenAllowed(allowed)
        return self
    }
    public func requiredInterface(_ interface: NWInterface) -> Self {
        _ = parameters.requiredInterface(interface)
        return self
    }
    public func expiredDNSBehavior(_ behavior: NWParameters.ExpiredDNSBehavior) -> Self {
        _ = parameters.expiredDNSBehavior(behavior)
        return self
    }
    public func noProxiesPreferred(_ preferred: Bool) -> Self {
        _ = parameters.noProxiesPreferred(preferred)
        return self
    }
    public func peerToPeerIncluded(_ included: Bool) -> Self {
        _ = parameters.peerToPeerIncluded(included)
        return self
    }
    public func multipathServiceType(_ type: NWParameters.MultipathServiceType) -> Self {
        _ = parameters.multipathServiceType(type)
        return self
    }
    public func prohibitedInterfaces(_ interfaces: [NWInterface]) -> Self {
        _ = parameters.prohibitedInterfaces(interfaces)
        return self
    }
    public func requiredInterfaceType(_ type: NWInterface.InterfaceType) -> Self {
        _ = parameters.requiredInterfaceType(type)
        return self
    }
    public func dnssecValidationRequired(_ required: Bool) -> Self {
        _ = parameters.dnssecValidationRequired(required)
        return self
    }
    public func expensivePathsProhibited(_ prohibited: Bool) -> Self {
        _ = parameters.expensivePathsProhibited(prohibited)
        return self
    }
    public func prohibitedInterfaceTypes(_ types: [NWInterface.InterfaceType]) -> Self {
        _ = parameters.prohibitedInterfaceTypes(types)
        return self
    }
    public func localEndpointReuseAllowed(_ allowed: Bool) -> Self {
        _ = parameters.localEndpointReuseAllowed(allowed)
        return self
    }
    public func constrainedPathsProhibited(_ prohibited: Bool) -> Self {
        _ = parameters.constrainedPathsProhibited(prohibited)
        return self
    }
    public func ultraConstrainedPathsAllowed(_ allowed: Bool) -> Self {
        _ = parameters.ultraConstrainedPathsAllowed(allowed)
        return self
    }
    public func localOnly(_ local: Bool) -> Self {
        _ = parameters.localOnly(local)
        return self
    }
    public func localPort(_ port: NWEndpoint.Port) -> Self {
        _ = parameters.localPort(port)
        return self
    }
}

extension NWParameters: NWParametersProvider {}

@resultBuilder
public struct ProtocolStackBuilder<ApplicationProtocol: NetworkProtocolOptions, each P: NetworkProtocolOptions> {
    public static func buildBlock(_ applicationProtocol: ApplicationProtocol) -> ApplicationProtocol {
        applicationProtocol
    }

    public static func buildBlock(
        _ applicationProtocol: ApplicationProtocol,
        _ belowProtocols: repeat each P
    ) -> (ApplicationProtocol, repeat each P) {
        (applicationProtocol, repeat each belowProtocols)
    }
}

@resultBuilder
public struct ProtocolMetadataBuilder {
    public static func buildBlock(_ metadata: NWProtocolMetadata...) -> [NWProtocolMetadata] {
        Array(metadata)
    }

    public static func buildBlock() -> [NWProtocolMetadata] {
        []
    }
}

public struct NWParametersBuilder<Top: NetworkProtocolOptions, each P: NetworkProtocolOptions>: NWParametersProvider {
    public var parameters: NWParameters

    public init(@ProtocolStackBuilder<Top, repeat each P> _ builder: () -> Top) {
        parameters = builder().parameters
    }

    public init(auto: () -> Top) {
        parameters = auto().parameters
    }

    public static func parameters(
        @ProtocolStackBuilder<Top, repeat each P> _ builder: () -> Top
    ) -> NWParametersBuilder<Top, repeat each P> {
        NWParametersBuilder(builder)
    }

    public static func parameters(
        initialParameters: NWParameters,
        @ProtocolStackBuilder<Top, repeat each P> _ builder: () -> Top
    ) -> NWParametersBuilder<Top, repeat each P> {
        _ = initialParameters
        return NWParametersBuilder(builder)
    }
}

public struct UnexpectedEndpointType: Error, CustomDebugStringConvertible {
    public let endpoint: NWEndpoint
    public init(endpoint: NWEndpoint) { self.endpoint = endpoint }
    public var debugDescription: String { "UnexpectedEndpointType(\(endpoint))" }
    public var localizedDescription: String { debugDescription }
}

public struct TXTRecordDecoder {
    public init() {}
    public func decode<T>(_ type: T.Type, from txtRecord: NWTXTRecord) throws -> T where T: Decodable {
        let data = try JSONSerialization.data(withJSONObject: txtRecord.dictionary)
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Protocol option structs

public struct IP: NetworkProtocolOptions, NWParametersProvider {
    public typealias BelowProtocol = Void
    public typealias ProtocolStorage = DefaultProtocolStorage
    public struct Metadata: NetworkMetadataProtocol {
        public let other: [NWProtocolMetadata]
        public init(other: [NWProtocolMetadata] = []) { self.other = other }
    }

    public var parameters: NWParameters

    public init() {
        parameters = NWParameters()
        parameters.defaultProtocolStack.internetProtocol = NWProtocolIP.Options()
    }

    public func version(_ version: NWProtocolIP.Options.Version) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.version = version
        return self
    }

    public func hopLimit(_ limit: UInt8) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.hopLimit = limit
        return self
    }

    public func localAddressPreference(_ preference: NWProtocolIP.Options.AddressPreference) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.localAddressPreference = preference
        return self
    }

    public func minimumMTU(_ useMinimumMTU: Bool) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.useMinimumMTU = useMinimumMTU
        return self
    }

    public func fragmentationDisabled(_ dontFragment: Bool) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.disableFragmentation = dontFragment
        return self
    }

    public func receiveTimeCalculated(_ calculateReceiveTime: Bool) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.shouldCalculateReceiveTime = calculateReceiveTime
        return self
    }

    public func multicastLoopbackDisabled(_ disableMulticastLoopback: Bool) -> IP {
        (parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.disableMulticastLoopback = disableMulticastLoopback
        return self
    }
}

public struct TCP: StreamProtocol, NWParametersProvider {
    public typealias BelowProtocol = IP
    public typealias ProtocolStorage = DefaultProtocolStorage
    public struct Metadata: NetworkMetadataProtocol {
        public let endOfStream: Bool
        public let other: [NWProtocolMetadata]
        public init(endOfStream: Bool = false, other: [NWProtocolMetadata] = []) {
            self.endOfStream = endOfStream
            self.other = other
        }
    }

    public var parameters: NWParameters

    public init() {
        parameters = .tcp
    }

    public init(@ProtocolStackBuilder<IP> _ builder: () -> IP) {
        parameters = .tcp
        parameters.defaultProtocolStack.internetProtocol = builder().parameters.defaultProtocolStack.internetProtocol
    }

    public func noDelay(_ noDelay: Bool) -> TCP {
        parameters.tcpOptions?.noDelay = noDelay
        return self
    }

    public func noOptions(_ noOptions: Bool) -> TCP {
        parameters.tcpOptions?.noOptions = noOptions
        return self
    }

    public func noPush(_ noPush: Bool) -> TCP {
        parameters.tcpOptions?.noPush = noPush
        return self
    }

    public func persistTimeout(_ timeout: UInt32) -> TCP {
        parameters.tcpOptions?.persistTimeout = Int(timeout)
        return self
    }

    public func fastOpenAllowed(_ allowed: Bool) -> TCP {
        parameters.tcpOptions?.enableFastOpen = allowed
        return self
    }

    public func connectionTimeout(_ timeout: UInt32) -> TCP {
        parameters.tcpOptions?.connectionTimeout = Int(timeout)
        return self
    }

    public func retransmitFinDrop(_ drop: Bool) -> TCP {
        parameters.tcpOptions?.retransmitFinDrop = drop
        return self
    }

    public func maximumSegmentSize(_ bytes: UInt32) -> TCP {
        parameters.tcpOptions?.maximumSegmentSize = Int(bytes)
        return self
    }

    public func ecnDisabled(_ disableECN: Bool) -> TCP {
        parameters.tcpOptions?.disableECN = disableECN
        return self
    }

    public func ackStretchingDisabled(_ disableAckStretching: Bool) -> TCP {
        parameters.tcpOptions?.disableAckStretching = disableAckStretching
        return self
    }

    public func retransmitConnectionDropTime(_ timeout: UInt32) -> TCP {
        parameters.tcpOptions?.connectionDropTime = Int(timeout)
        return self
    }

    public func keepalive(idleTimeInSeconds: UInt32, count: UInt32, intervalInSeconds: UInt32) -> TCP {
        parameters.tcpOptions?.enableKeepalive = true
        parameters.tcpOptions?.keepaliveIdle = Int(idleTimeInSeconds)
        parameters.tcpOptions?.keepaliveCount = Int(count)
        parameters.tcpOptions?.keepaliveInterval = Int(intervalInSeconds)
        return self
    }
}

public struct UDP: DatagramProtocol, NWParametersProvider {
    public typealias BelowProtocol = IP
    public typealias ProtocolStorage = DefaultProtocolStorage
    public typealias ContentType = Data
    public typealias LegacyMessage = (content: Data, metadata: [NWProtocolMetadata]?)
    public struct Metadata: NetworkMetadataProtocol {
        public let other: [NWProtocolMetadata]
        public init(other: [NWProtocolMetadata] = []) { self.other = other }
    }

    public var parameters: NWParameters

    public init() {
        parameters = .udp
    }

    public init(@ProtocolStackBuilder<IP> _ builder: () -> IP) {
        parameters = .udp
        parameters.defaultProtocolStack.internetProtocol = builder().parameters.defaultProtocolStack.internetProtocol
    }

    public func noChecksumPreferred(_ noChecksum: Bool) -> UDP {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolUDP.Options)?.preferNoChecksum = noChecksum
        return self
    }
}

public struct TLS: StreamProtocol, NWParametersProvider {
    public typealias BelowProtocol = TCP
    public typealias ProtocolStorage = DefaultProtocolStorage
    public enum PeerAuthentication: Hashable, Sendable {
        case none
        case optional
        case required
    }

    public struct Metadata: NetworkMetadataProtocol {
        public let endOfStream: Bool
        public let other: [NWProtocolMetadata]
        public init(endOfStream: Bool = false, other: [NWProtocolMetadata] = []) {
            self.endOfStream = endOfStream
            self.other = other
        }
    }

    public var parameters: NWParameters
    public private(set) var applicationProtocolsValue: [String] = []
    public private(set) var peerAuthenticationValue: PeerAuthentication = .required
    public private(set) var minVersion: tls_protocol_version_t?
    public private(set) var maxVersion: tls_protocol_version_t?
    public private(set) var cipherSuiteValues: [tls_ciphersuite_t] = []
    public private(set) var cipherSuiteGroupValues: [tls_ciphersuite_group_t] = []
    public private(set) var ticketsEnabledValue = true
    public private(set) var earlyDataEnabledValue = false
    public private(set) var localIdentityValue: sec_identity_t?

    public init() {
        parameters = .tls
    }

    public init(@ProtocolStackBuilder<TCP> _ builder: () -> TCP) {
        let tcp = builder()
        parameters = NWParameters(tls: NWProtocolTLS.Options(), tcp: tcp.parameters.tcpOptions ?? NWProtocolTCP.Options())
    }

    public func applicationProtocols(_ protocols: [String]) -> TLS {
        var copy = self
        copy.applicationProtocolsValue = protocols
        return copy
    }

    public func peerAuthentication(_ preference: PeerAuthentication) -> TLS {
        var copy = self
        copy.peerAuthenticationValue = preference
        return copy
    }

    public func version(min: tls_protocol_version_t? = nil, max: tls_protocol_version_t? = nil) -> TLS {
        var copy = self
        copy.minVersion = min
        copy.maxVersion = max
        return copy
    }

    public func cipherSuites(_ suites: [tls_ciphersuite_t]) -> TLS {
        var copy = self
        copy.cipherSuiteValues = suites
        return copy
    }

    public func cipherSuiteGroups(_ groups: [tls_ciphersuite_group_t]) -> TLS {
        var copy = self
        copy.cipherSuiteGroupValues = groups
        return copy
    }

    public func ticketsEnabled(_ enabled: Bool) -> TLS {
        var copy = self
        copy.ticketsEnabledValue = enabled
        return copy
    }

    public func earlyDataEnabled(_ enabled: Bool) -> TLS {
        var copy = self
        copy.earlyDataEnabledValue = enabled
        return copy
    }

    public func localIdentity(_ identity: sec_identity_t) -> TLS {
        var copy = self
        copy.localIdentityValue = identity
        return copy
    }

    public func certificateValidator(
        _ handler: @escaping (sec_protocol_metadata_t, sec_trust_t) async -> Bool
    ) -> TLS {
        _ = handler
        return self
    }
}

public struct QUIC: MultiplexProtocol, NWParametersProvider {
    public typealias BelowProtocol = UDP
    public struct ProtocolStorage: ConnectionStorage {
        public init() {}
    }

    public struct Metadata: NetworkMetadataProtocol {
        public init() {}
    }

    public struct TLS {
        fileprivate var parent: QUIC
        public func cipherSuites(_ suites: [tls_ciphersuite_t]) -> QUIC {
            _ = suites
            return parent
        }
        public func localIdentity(_ identity: sec_identity_t) -> QUIC {
            _ = identity
            return parent
        }
        public func ciphersuiteGroups(_ groups: [tls_ciphersuite_group_t]) -> QUIC {
            _ = groups
            return parent
        }
        public func peerAuthentication(_ preference: Network.TLS.PeerAuthentication) -> QUIC {
            _ = preference
            return parent
        }
        public func certificateValidator(
            _ handler: @escaping (sec_protocol_metadata_t, sec_trust_t) async -> Bool
        ) -> QUIC {
            _ = handler
            return parent
        }
    }

    public final class Stream<ApplicationProtocol: NetworkProtocolOptions> {
        public let parent: NetworkConnection<QUIC>
        public let streamID: UInt64
        public let directionality: QUICStream.Directionality
        public let initiator: QUICStream.Initiator
        public var streamApplicationErrorCode: UInt64
        public init(
            parent: NetworkConnection<QUIC>,
            streamID: UInt64 = 0,
            directionality: QUICStream.Directionality = .bidirectional,
            initiator: QUICStream.Initiator = .client
        ) {
            self.parent = parent
            self.streamID = streamID
            self.directionality = directionality
            self.initiator = initiator
            self.streamApplicationErrorCode = 0
        }
    }

    public final class Datagrams<ApplicationProtocol: NetworkProtocolOptions> {
        public let parent: NetworkConnection<QUIC>
        public init(parent: NetworkConnection<QUIC>) {
            self.parent = parent
        }
    }

    public var parameters: NWParameters
    public var tls: TLS { TLS(parent: self) }

    public init(alpn: [String]) {
        parameters = .quic(alpn: alpn)
    }

    public init(alpn: [String], @ProtocolStackBuilder<UDP> _ builder: () -> UDP) {
        parameters = .quic(alpn: alpn)
        parameters.defaultProtocolStack.internetProtocol = builder().parameters.defaultProtocolStack.internetProtocol
    }

    public func idleTimeout(_ timeout: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.idleTimeout = UInt32(timeout)
        return self
    }

    public func initialMaxData(_ initialMaxData: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxData = UInt64(initialMaxData)
        return self
    }

    public func maxUDPPayloadSize(_ size: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.maxUDPPayloadSize = UInt16(clamping: size)
        return self
    }

    public func maxDatagramFrameSize(_ size: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.maxDatagramFrameSize = UInt16(clamping: size)
        return self
    }

    public func initialMaxBidirectionalStreams(_ initialMaxStreamsBidi: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxStreamsBidirectional = UInt64(initialMaxStreamsBidi)
        return self
    }

    public func initialMaxUnidirectionalStreams(_ initialMaxStreamDataUni: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxStreamsUnidirectional = UInt64(initialMaxStreamDataUni)
        return self
    }

    public func initialMaxStreamDataUnidirectional(_ initialMaxStreamDataUni: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxStreamDataUnidirectional = UInt64(initialMaxStreamDataUni)
        return self
    }

    public func initialMaxStreamDataBidirectionalLocal(_ initialMaxStreamDataBidiLocal: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxStreamDataBidirectionalLocal = UInt64(initialMaxStreamDataBidiLocal)
        return self
    }

    public func initialMaxStreamDataBidirectionalRemote(_ initialMaxStreamDataBidiRemote: Int) -> QUIC {
        (parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options)?.initialMaxStreamDataBidirectionalRemote = UInt64(initialMaxStreamDataBidiRemote)
        return self
    }
}

public struct QUICStream: StreamProtocol {
    public typealias BelowProtocol = Void
    public typealias ProtocolStorage = DefaultProtocolStorage
    public enum Directionality: Hashable, Sendable {
        case bidirectional
        case unidirectional
    }
    public enum Initiator: Hashable, Sendable {
        case client
        case server
    }
    public struct Metadata: NetworkMetadataProtocol {
        public let endOfStream: Bool
        public let other: [NWProtocolMetadata]
        public init(endOfStream: Bool = false, other: [NWProtocolMetadata] = []) {
            self.endOfStream = endOfStream
            self.other = other
        }
    }
    public var parameters: NWParameters { .quic(alpn: []) }
    public init() {}
}

public struct QUICDatagram: DatagramProtocol {
    public typealias BelowProtocol = Void
    public typealias ProtocolStorage = DefaultProtocolStorage
    public typealias ContentType = Data
    public typealias LegacyMessage = (content: Data, metadata: [NWProtocolMetadata]?)
    public struct Metadata: NetworkMetadataProtocol {
        public let other: [NWProtocolMetadata]
        public init(other: [NWProtocolMetadata] = []) { self.other = other }
    }
    public var parameters: NWParameters { .quicDatagram(alpn: []) }
    public init() {}
}

public struct WebSocket: MessageProtocol, NWParametersProvider {
    public typealias BelowProtocol = any NetworkProtocolOptions
    public typealias ProtocolStorage = DefaultProtocolStorage
    public typealias ContentType = Data
    public typealias LegacyMessage = (
        type: NWProtocolWebSocket.Opcode,
        content: Data,
        metadata: [NWProtocolMetadata]?,
        isFinal: Bool
    )
    public struct Metadata: NetworkMetadataProtocol {
        public let isComplete: Bool
        public let lastMessage: Bool
        public let other: [NWProtocolMetadata]
        public let opcode: NWProtocolWebSocket.Opcode
        public let closeCode: NWProtocolWebSocket.CloseCode?
        public init(
            opcode: NWProtocolWebSocket.Opcode = .binary,
            closeCode: NWProtocolWebSocket.CloseCode? = nil,
            isComplete: Bool = true,
            lastMessage: Bool = false,
            other: [NWProtocolMetadata] = []
        ) {
            self.opcode = opcode
            self.closeCode = closeCode
            self.isComplete = isComplete
            self.lastMessage = lastMessage
            self.other = other
        }
    }

    public var parameters: NWParameters
    private var options: NWProtocolWebSocket.Options

    public init<BelowProtocol>(@ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: StreamProtocol {
        let below = builder()
        options = NWProtocolWebSocket.Options()
        parameters = below.parameters
        parameters.defaultProtocolStack.applicationProtocols.append(options)
    }

    public init<BelowProtocol>(@ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: MessageProtocol {
        let below = builder()
        options = NWProtocolWebSocket.Options()
        parameters = below.parameters
        parameters.defaultProtocolStack.applicationProtocols.append(options)
    }

    public func autoReplyPing(_ reply: Bool) -> WebSocket {
        options.autoReplyPing = reply
        return self
    }

    public func skipHandshake(_ skip: Bool) -> WebSocket {
        options.skipHandshake = skip
        return self
    }

    public func maximumMessageSize(_ size: Int) -> WebSocket {
        options.maximumMessageSize = size
        return self
    }

    public func subprotocols(_ subprotocols: [String]) -> WebSocket {
        options.setSubprotocols(subprotocols)
        return self
    }

    public func additionalHeaders(_ headers: [(name: String, value: String)]) -> WebSocket {
        options.setAdditionalHeaders(headers)
        return self
    }
}

public struct Framer<T: FramerProtocol>: MessageProtocol, NWParametersProvider {
    public typealias BelowProtocol = any NetworkProtocolOptions
    public typealias ProtocolStorage = DefaultProtocolStorage
    public typealias ContentType = Data
    public typealias LegacyMessage = (Data, Framer<T>.Metadata)
    public struct Metadata: NetworkMetadataProtocol {
        public let isComplete: Bool
        public let lastMessage: Bool
        public let other: [NWProtocolMetadata]
        public let framer: NWProtocolFramer.Message
        public init(
            framer: NWProtocolFramer.Message,
            isComplete: Bool,
            lastMessage: Bool,
            other: [NWProtocolMetadata]?
        ) {
            self.framer = framer
            self.isComplete = isComplete
            self.lastMessage = lastMessage
            self.other = other ?? []
        }
    }

    public var parameters: NWParameters
    public var options: NWProtocolFramer.Options

    public init<BelowProtocol>(using framer: T.Type, @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: StreamProtocol {
        let below = builder()
        options = NWProtocolFramer.Options(definition: T.definition)
        parameters = below.parameters
        parameters.defaultProtocolStack.applicationProtocols.append(options)
        _ = framer
    }

    public init<BelowProtocol>(using framer: T.Type, @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: MessageProtocol {
        let below = builder()
        options = NWProtocolFramer.Options(definition: T.definition)
        parameters = below.parameters
        parameters.defaultProtocolStack.applicationProtocols.append(options)
        _ = framer
    }

    public init<BelowProtocol>(@ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: StreamProtocol {
        self.init(using: T.self, builder)
    }

    public init<BelowProtocol>(@ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol) where BelowProtocol: MessageProtocol {
        self.init(using: T.self, builder)
    }
}

public struct Coder<Sending: Encodable, Receiving: Decodable, CoderType: NetworkCoder>: MessageProtocol, NWParametersProvider {
    public typealias BelowProtocol = any NetworkProtocolOptions
    public typealias ProtocolStorage = DefaultProtocolStorage
    public typealias ContentType = Receiving
    public typealias LegacyMessage = (
        content: ContentType,
        metadata: [NWProtocolMetadata]?,
        isFinal: Bool
    )
    public struct Metadata: NetworkMetadataProtocol {
        public let isComplete: Bool
        public let lastMessage: Bool
        public let other: [NWProtocolMetadata]
        public init(isComplete: Bool = true, lastMessage: Bool = false, other: [NWProtocolMetadata] = []) {
            self.isComplete = isComplete
            self.lastMessage = lastMessage
            self.other = other
        }
    }

    public var parameters: NWParameters
    public let coder: CoderType

    public init<BelowProtocol>(
        sending: Sending.Type,
        receiving: Receiving.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: StreamProtocol {
        _ = sending
        _ = receiving
        coder = using
        parameters = builder().parameters
    }

    public init<BelowProtocol>(
        sending: Sending.Type,
        receiving: Receiving.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: DatagramProtocol {
        _ = sending
        _ = receiving
        coder = using
        parameters = builder().parameters
    }

    public init<BelowProtocol>(
        receiving: Receiving.Type,
        sending: Sending.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: StreamProtocol {
        self.init(sending: sending, receiving: receiving, using: using, builder)
    }

    public init<BelowProtocol>(
        receiving: Receiving.Type,
        sending: Sending.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: DatagramProtocol {
        self.init(sending: sending, receiving: receiving, using: using, builder)
    }
}

extension Coder where Sending: Decodable, Sending == Receiving {
    public init<BelowProtocol>(
        _ type: Sending.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: StreamProtocol {
        self.init(sending: type, receiving: type, using: using, builder)
    }

    public init<BelowProtocol>(
        _ type: Sending.Type,
        using: CoderType,
        @ProtocolStackBuilder<BelowProtocol> _ builder: () -> BelowProtocol
    ) where BelowProtocol: DatagramProtocol {
        self.init(sending: type, receiving: type, using: using, builder)
    }
}

public final class LengthPrefixedHostFramerImplementation: NWProtocolFramerImplementation {
    public required init(framer: NWProtocolFramer.Instance) { _ = framer }
    public func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        _ = framer
        return .ready
    }
    public func handleInput(framer: NWProtocolFramer.Instance) -> Int { _ = framer; return 0 }
    public func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    ) {
        _ = framer
        _ = message
        _ = messageLength
        _ = isComplete
    }
    public func wakeup(framer: NWProtocolFramer.Instance) { _ = framer }
    public func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    public func cleanup(framer: NWProtocolFramer.Instance) { _ = framer }
}

public struct LengthPrefixedHostFramer: FramerProtocol {
    public static var definition: NWProtocolFramer.Definition {
        NWProtocolFramer.Definition(implementation: LengthPrefixedHostFramerImplementation.self)
    }
}

// MARK: - Bonjour / browser / listener providers

public struct Bonjour: BrowserProvider, Sendable {
    public struct Endpoint: Connectable, Hashable, CustomStringConvertible {
        public typealias ID = String
        public let name: String
        public let type: String
        public let domain: String
        public let result: NWBrowser.Result
        public let txtRecord: NWTXTRecord
        public var id: String { "\(name).\(type).\(domain)" }
        public var description: String { id }
        public var nwEndpoint: NWEndpoint { result.endpoint }
        public init(
            name: String,
            type: String,
            domain: String,
            result: NWBrowser.Result,
            txtRecord: NWTXTRecord = NWTXTRecord()
        ) {
            self.name = name
            self.type = type
            self.domain = domain
            self.result = result
            self.txtRecord = txtRecord
        }
    }

    public let type: String
    public let domain: String?
    public let includeTxtRecord: Bool

    public static func bonjour(_ type: String, domain: String? = nil, includeTxtRecord: Bool = false) -> Bonjour {
        Bonjour(type: type, domain: domain, includeTxtRecord: includeTxtRecord)
    }

    public init(type: String, domain: String? = nil, includeTxtRecord: Bool = false) {
        self.type = type
        self.domain = domain
        self.includeTxtRecord = includeTxtRecord
    }
}

public struct BonjourListenerProvider: ListenerProvider {
    public let name: String?
    public let type: String
    public let domain: String?
    public let txtRecord: NWTXTRecord?
    public var service: NWListener.Service {
        if let txtRecord {
            return NWListener.Service(name: name, type: type, domain: domain, txtRecord: txtRecord)
        }
        return NWListener.Service(name: name, type: type, domain: domain)
    }

    public init(name: String? = nil, type: String, domain: String? = nil, txtRecord: NWTXTRecord? = nil) {
        self.name = name
        self.type = type
        self.domain = domain
        self.txtRecord = txtRecord
    }

    public static func bonjour(
        name: String? = nil,
        type: String,
        domain: String? = nil,
        txtRecord: NWTXTRecord? = nil
    ) -> BonjourListenerProvider {
        BonjourListenerProvider(name: name, type: type, domain: domain, txtRecord: txtRecord)
    }
}

extension BrowserProvider where Self == Bonjour {
    public static func bonjour(_ type: String, domain: String? = nil, includeTxtRecord: Bool = false) -> Bonjour {
        Bonjour.bonjour(type, domain: domain, includeTxtRecord: includeTxtRecord)
    }
}

extension ListenerProvider where Self == BonjourListenerProvider {
    public static func bonjour(
        name: String? = nil,
        type: String,
        domain: String? = nil,
        txtRecord: NWTXTRecord? = nil
    ) -> BonjourListenerProvider {
        BonjourListenerProvider.bonjour(name: name, type: type, domain: domain, txtRecord: txtRecord)
    }
}

// MARK: - Typed connection / channel / listener / browser

public class NetworkChannel<ApplicationProtocol: NetworkProtocolOptions>: Hashable, CustomDebugStringConvertible {
    public typealias ID = String
    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case preparing
        case ready
        case failed(NWError)
        case cancelled
    }

    let inner: NWConnection
    public let id: String
    public var parameters: NWParameters { inner.parameters }
    public var maximumDatagramSize: Int { 65507 }
    public var state: State { NetworkChannel.map(inner.state) }
    public var debugDescription: String { "NetworkChannel(\(state))" }

    public init(inner: NWConnection) {
        self.inner = inner
        self.id = UUID().uuidString
    }

    public func metadata(definition: NWProtocolDefinition) -> NWProtocolMetadata? {
        _ = definition
        return nil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public static func == (
        lhs: NetworkChannel<ApplicationProtocol>,
        rhs: NetworkChannel<ApplicationProtocol>
    ) -> Bool {
        lhs === rhs
    }

    public func sendIdempotent<Content>(
        _ content: Content,
        endOfStream: Bool = false,
        @ProtocolMetadataBuilder metadata builder: () -> [NWProtocolMetadata] = { [] }
    ) where Content: DataProtocol {
        _ = endOfStream
        _ = builder()
        inner.send(content: Data(content), completion: .idempotent)
    }

    public func sendIdempotent<Value>(
        _ value: Value,
        endOfStream: Bool = false,
        @ProtocolMetadataBuilder metadata builder: () -> [NWProtocolMetadata] = { [] }
    ) where Value: NetworkFixedWidthInteger {
        var big = value.bigEndian
        let data = withUnsafeBytes(of: &big) { Data($0) }
        sendIdempotent(data, endOfStream: endOfStream, metadata: builder)
    }

    public func sendIdempotent(
        _ content: String,
        @ProtocolMetadataBuilder metadata builder: () -> [NWProtocolMetadata] = { [] }
    ) {
        sendIdempotent(Data(content.utf8), metadata: builder)
    }

    public func sendIdempotent<Content>(
        _ content: Content,
        type: Int,
        lastMessage: Bool = false,
        @ProtocolMetadataBuilder metadata builder: () -> [NWProtocolMetadata] = { [] }
    ) where Content: DataProtocol {
        _ = type
        _ = lastMessage
        sendIdempotent(content, metadata: builder)
    }

    static func map(_ state: NWConnection.State) -> State {
        switch state {
        case .setup: return .setup
        case .waiting(let error): return .waiting(error)
        case .preparing: return .preparing
        case .ready: return .ready
        case .failed(let error): return .failed(error)
        case .cancelled: return .cancelled
        }
    }
}

public final class NetworkConnection<ApplicationProtocol: NetworkProtocolOptions>: CustomDebugStringConvertible {
    let inner: NWConnection
    public private(set) var channel: NetworkChannel<ApplicationProtocol>
    var storedQUICApplicationError = NWProtocolQUIC.ApplicationError(code: 0)
    var storedQUICKeepalive: NWProtocolQUIC.Metadata.KeepAliveBehavior = .off
    private var stateHandler: ((NetworkConnection<ApplicationProtocol>, NetworkChannel<ApplicationProtocol>.State) -> Void)?
    private var pathHandler: ((NetworkConnection<ApplicationProtocol>, NWPath) -> Void)?
    private var viabilityHandler: ((NetworkConnection<ApplicationProtocol>, Bool) -> Void)?
    private var betterPathHandler: ((NetworkConnection<ApplicationProtocol>, Bool) -> Void)?

    public var currentPath: NWPath? { inner.currentPath }
    public var localEndpoint: NWEndpoint? { inner.localEndpoint }
    public var remoteEndpoint: NWEndpoint? { inner.remoteEndpoint }
    public var parameters: NWParameters { inner.parameters }
    public var state: NetworkChannel<ApplicationProtocol>.State { channel.state }
    public var debugDescription: String { "NetworkConnection(\(state))" }

    public init(inner: NWConnection) {
        self.inner = inner
        self.channel = NetworkChannel(inner: inner)
        wireHandlers()
    }

    public convenience init(
        to endpoint: NWEndpoint,
        using builder: NWParametersBuilder<ApplicationProtocol>
    ) {
        self.init(inner: NWConnection(to: endpoint, using: builder.parameters))
    }

    public convenience init(
        to endpoint: NWEndpoint,
        @ProtocolStackBuilder<ApplicationProtocol> using builder: () -> ApplicationProtocol
    ) {
        self.init(inner: NWConnection(to: endpoint, using: builder().parameters))
    }

    public convenience init(
        to provider: any Connectable,
        using builder: NWParametersBuilder<ApplicationProtocol>
    ) {
        let endpoint = (provider as? NWEndpoint) ?? .hostPort(host: .name("invalid", nil), port: .any)
        self.init(to: endpoint, using: builder)
    }

    public convenience init(
        to provider: any Connectable,
        @ProtocolStackBuilder<ApplicationProtocol> using builder: () -> ApplicationProtocol
    ) {
        let endpoint = (provider as? NWEndpoint) ?? .hostPort(host: .name("invalid", nil), port: .any)
        self.init(to: endpoint, using: builder)
    }

    @discardableResult
    public func start() -> Self {
        inner.start(queue: DispatchQueue(label: "network.typed.connection"))
        stateHandler?(self, state)
        if let path = currentPath {
            pathHandler?(self, path)
        }
        return self
    }

    public func cancel() {
        inner.cancel()
    }

    public func tryNextEndpoint() {
        inner.cancelCurrentEndpoint()
    }

    @discardableResult
    public func onStateUpdate(
        _ handler: @escaping (
            NetworkConnection<ApplicationProtocol>,
            NetworkChannel<ApplicationProtocol>.State
        ) -> Void
    ) -> Self {
        stateHandler = handler
        return self
    }

    @discardableResult
    public func onPathUpdate(
        _ handler: @escaping (NetworkConnection<ApplicationProtocol>, NWPath) -> Void
    ) -> Self {
        pathHandler = handler
        return self
    }

    @discardableResult
    public func onViabilityUpdate(
        _ handler: @escaping (NetworkConnection<ApplicationProtocol>, Bool) -> Void
    ) -> Self {
        viabilityHandler = handler
        return self
    }

    @discardableResult
    public func onBetterPathUpdate(
        _ handler: @escaping (NetworkConnection<ApplicationProtocol>, Bool) -> Void
    ) -> Self {
        betterPathHandler = handler
        return self
    }

    private func wireHandlers() {
        inner.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            self.stateHandler?(self, NetworkChannel.map(state))
        }
        inner.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.pathHandler?(self, path)
        }
        inner.viabilityUpdateHandler = { [weak self] viable in
            guard let self else { return }
            self.viabilityHandler?(self, viable)
        }
        inner.betterPathUpdateHandler = { [weak self] better in
            guard let self else { return }
            self.betterPathHandler?(self, better)
        }
    }
}

extension NetworkConnection where ApplicationProtocol == QUIC {
    public var applicationError: NWProtocolQUIC.ApplicationError {
        get { storedQUICApplicationError }
        set { storedQUICApplicationError = newValue }
    }
    public var securityProtocolMetadata: sec_protocol_metadata_t { sec_protocol_metadata() }
    public var negotiatedALPN: String? { nil }
    public var remoteIdleTimeout: Int { 0 }
    public var usableDatagramFrameSize: Int { 0 }
    public var remoteMaxStreamsBidirectional: Int { 0 }
    public var remoteMaxStreamsUnidirectional: Int { 0 }
    public var keepalive: NWProtocolQUIC.Metadata.KeepAliveBehavior {
        get { storedQUICKeepalive }
        set { storedQUICKeepalive = newValue }
    }
    public var datagrams: QUIC.Datagrams<QUICDatagram> { QUIC.Datagrams(parent: self) }

    public func openStream(
        directionality: QUICStream.Directionality = .bidirectional
    ) throws -> QUIC.Stream<QUICStream> {
        _ = directionality
        throw NWError.posix(.EOPNOTSUPP)
    }
}

public final class NetworkListener<ApplicationProtocol: NetworkProtocolOptions>: CustomDebugStringConvertible {
    public typealias StateUpdateHandler = (
        NetworkListener<ApplicationProtocol>,
        NetworkListener<ApplicationProtocol>.State
    ) -> Void
    public typealias ServiceRegistrationUpdateHandler = (
        NetworkListener<ApplicationProtocol>,
        NetworkListener<ApplicationProtocol>.ServiceRegistrationChange
    ) -> Void

    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case ready
        case failed(NWError)
        case cancelled
    }

    public enum ServiceRegistrationChange {
        case add(NWEndpoint)
        case remove(NWEndpoint)
    }

    let inner: NWListener
    private var stateHandler: StateUpdateHandler?
    private var registrationHandler: ServiceRegistrationUpdateHandler?

    public var port: NWEndpoint.Port? { inner.port }
    public var service: NWListener.Service? {
        get { inner.service }
        set { inner.service = newValue }
    }
    public var newConnectionLimit: Int {
        get { inner.newConnectionLimit }
        set { inner.newConnectionLimit = newValue }
    }
    public var newConnectionHandler: ((NetworkConnection<ApplicationProtocol>) -> Void)? {
        didSet {
            inner.newConnectionHandler = { [weak self] connection in
                self?.newConnectionHandler?(NetworkConnection(inner: connection))
            }
        }
    }
    public var state: State { Self.map(inner.state) }
    public var debugDescription: String { "NetworkListener(\(state))" }

    public init(inner: NWListener) {
        self.inner = inner
    }

    public convenience init(
        for provider: (any ListenerProvider)? = nil,
        using builder: NWParametersBuilder<ApplicationProtocol>
    ) throws {
        if provider != nil {
            throw NWError.posix(.EOPNOTSUPP)
        }
        try self.init(inner: NWListener(using: builder.parameters, on: .any))
    }

    public convenience init(
        for provider: (any ListenerProvider)? = nil,
        @ProtocolStackBuilder<ApplicationProtocol> using builder: () -> ApplicationProtocol
    ) throws {
        if provider != nil {
            throw NWError.posix(.EOPNOTSUPP)
        }
        try self.init(inner: NWListener(using: builder().parameters, on: .any))
    }

    @discardableResult
    public func newConnectionLimit(_ limit: Int) -> Self {
        newConnectionLimit = limit
        return self
    }

    @discardableResult
    public func onStateUpdate(_ handler: @escaping StateUpdateHandler) -> Self {
        stateHandler = handler
        inner.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            handler(self, Self.map(state))
        }
        return self
    }

    @discardableResult
    public func onServiceRegistrationUpdate(_ handler: @escaping ServiceRegistrationUpdateHandler) -> Self {
        registrationHandler = handler
        return self
    }

    @discardableResult
    public func start() -> Self {
        inner.start(queue: DispatchQueue(label: "network.typed.listener"))
        stateHandler?(self, state)
        return self
    }

    public func cancel() {
        inner.cancel()
    }

    static func map(_ state: NWListener.State) -> State {
        switch state {
        case .setup: return .setup
        case .waiting(let error): return .waiting(error)
        case .ready: return .ready
        case .failed(let error): return .failed(error)
        case .cancelled: return .cancelled
        }
    }
}

public final class NetworkBrowser<Provider: BrowserProvider>: CustomDebugStringConvertible {
    public typealias StateUpdateHandler = (
        NetworkBrowser<Provider>,
        NetworkBrowser<Provider>.State
    ) -> Void

    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case ready
        case failed(NWError)
        case cancelled
    }

    public enum RunResult<T> {
        case finish(T)
        case `continue`
    }

    public let provider: Provider
    public let parameters: NWParameters?
    public private(set) var state: State = .setup
    private var stateHandler: StateUpdateHandler?

    public var debugDescription: String { "NetworkBrowser(\(state))" }

    public init(for provider: Provider, using parameters: NWParameters? = nil) {
        self.provider = provider
        self.parameters = parameters
    }

    @discardableResult
    public func onStateUpdate(_ handler: @escaping StateUpdateHandler) -> Self {
        stateHandler = handler
        return self
    }

    /// Linux has no mDNS responder. Start fails closed with EOPNOTSUPP.
    @discardableResult
    public func start() -> Self {
        state = .failed(.posix(.EOPNOTSUPP))
        stateHandler?(self, state)
        return self
    }
}
