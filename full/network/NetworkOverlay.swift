import Foundation

public struct ProxyConfiguration: Hashable, Sendable {
    public struct RelayHop: Hashable, Sendable {
        public let http3RelayEndpoint: NWEndpoint?
        public let http2RelayEndpoint: NWEndpoint?
        public var additionalHTTPHeaderFields: [String: String]

        public init(
            http3RelayEndpoint: NWEndpoint? = nil,
            http2RelayEndpoint: NWEndpoint? = nil,
            additionalHTTPHeaderFields: [String: String] = [:]
        ) {
            self.http3RelayEndpoint = http3RelayEndpoint
            self.http2RelayEndpoint = http2RelayEndpoint
            self.additionalHTTPHeaderFields = additionalHTTPHeaderFields
        }
    }

    public var relays: [RelayHop]

    public init(relays: [RelayHop] = []) {
        self.relays = relays
    }
}

public class NWProtocolQUIC: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "quic")

    public struct ApplicationError: Hashable, Sendable, Error {
        public var code: UInt64
        public var message: String?
        public init(code: UInt64, message: String? = nil) {
            self.code = code
            self.message = message
        }
    }

    public class Options: NWProtocolOptions {
        public enum Direction: Hashable, Sendable {
            case bidirectional
            case unidirectional
        }

        public var alpn: [String]
        public var direction: Direction = .bidirectional
        public var idleTimeout: UInt32 = 0
        public var maxUDPPayloadSize: UInt16 = 0
        public var initialMaxData: UInt64 = 0
        public var initialMaxStreamDataBidirectionalLocal: UInt64 = 0
        public var initialMaxStreamDataBidirectionalRemote: UInt64 = 0
        public var initialMaxStreamDataUnidirectional: UInt64 = 0
        public var initialMaxStreamsBidirectional: UInt64 = 0
        public var initialMaxStreamsUnidirectional: UInt64 = 0

        public init(alpn: [String] = []) {
            self.alpn = alpn
            super.init()
        }
    }

    public class Metadata: NWProtocolMetadata {
        public enum KeepAliveBehavior: Hashable, Sendable {
            case disabled
            case application
        }

        public var streamID: UInt64 { 0 }
        public var keepAliveBehavior: KeepAliveBehavior = .disabled
        public var applicationError: ApplicationError?
    }
}

public class NWProtocolWebSocket: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "ws")

    public enum Opcode: Hashable, Sendable {
        case cont
        case text
        case binary
        case close
        case ping
        case pong
    }

    public enum Version: Hashable, Sendable {
        case v13
    }

    public enum CloseCode: Hashable, Sendable {
        public enum Defined: UInt16, Hashable, Sendable {
            case normalClosure = 1000
            case goingAway = 1001
            case protocolError = 1002
            case unsupportedData = 1003
            case noStatusReceived = 1005
            case abnormalClosure = 1006
            case invalidFramePayloadData = 1007
            case policyViolation = 1008
            case messageTooBig = 1009
            case mandatoryExtension = 1010
            case internalServerError = 1011
            case tlsHandshake = 1015
        }

        case defined(Defined)
        case privateStatus(UInt16)
    }

    public class Options: NWProtocolOptions {
        public var autoReplyPing = false
        public var maximumMessageSize = 0
        public var skipHandshake = false
        public override init() { super.init() }
        public func setSubprotocols(_ protocols: [String]) { _ = protocols }
        public func addAdditionalHeader(_ name: String, value: String) {
            _ = name
            _ = value
        }
    }

    public class Metadata: NWProtocolMetadata {
        public var opcode: Opcode = .binary
        public var closeCode: CloseCode = .defined(.normalClosure)
        public var response: Response?
    }

    public struct Response: Hashable, Sendable {
        public enum Status: Hashable, Sendable {
            case accept
            case reject
        }

        public var status: Status
        public init(status: Status) { self.status = status }
    }
}

public class NWProtocolFramer: NWProtocol {
    public class Definition: NWProtocolDefinition {
        public init(implementation: any NWProtocolFramerImplementation.Type) {
            super.init(identifier: String(describing: implementation))
        }
    }

    public enum StartResult: Hashable, Sendable {
        case ready
        case willMarkReady
    }

    public class Message: NWProtocolMetadata {
        public init(definition: Definition) {
            super.init()
            _ = definition
        }

        public subscript(key: String) -> Any? {
            get { _ = key; return nil }
            set { _ = key; _ = newValue }
        }
    }

    public class Options: NWProtocolOptions {
        public init(definition: Definition) {
            super.init()
            _ = definition
        }
    }

    public final class Instance: @unchecked Sendable {
        public enum WakeupTime: Hashable, Sendable {
            case now
            case forever
            case interval(TimeInterval)
        }

        public func writeOutput(data: Data) { _ = data }
        public func passInput(to protocol: NWProtocolDefinition) { _ = `protocol` }
        public func markReady() {}
        public func markFailed(error: NWError?) { _ = error }
        public func deliverInput(data: Data, message: Message, isComplete: Bool) {
            _ = data
            _ = message
            _ = isComplete
        }
        public func scheduleWakeup(wakeupTime: WakeupTime) { _ = wakeupTime }
    }
}

public protocol NWProtocolFramerImplementation: AnyObject {
    init(framer: NWProtocolFramer.Instance)
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult
    func handleInput(framer: NWProtocolFramer.Instance) -> Int
    func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    )
    func wakeup(framer: NWProtocolFramer.Instance)
    func stop(framer: NWProtocolFramer.Instance) -> Bool
    func cleanup(framer: NWProtocolFramer.Instance)
}

extension NWConnection.ContentContext {
    public static let defaultStream = NWConnection.ContentContext(identifier: "defaultStream")
    public static let finalMessage = NWConnection.ContentContext(identifier: "final")

    public var antecedent: NWConnection.ContentContext? { nil }
    public var relativePriority: Double { 0.5 }
    public var expirationMilliseconds: UInt64 { 0 }
    public var isFinal: Bool { identifier == "final" }
    public var protocolMetadata: [NWProtocolMetadata] { [] }

    public convenience init(
        identifier: String,
        expiration: UInt64 = 0,
        priority: Double = 0.5,
        isFinal: Bool = false,
        antecedent: NWConnection.ContentContext? = nil,
        metadata: [NWProtocolMetadata] = []
    ) {
        self.init(identifier: identifier)
        _ = expiration
        _ = priority
        _ = isFinal
        _ = antecedent
        _ = metadata
    }

    public func protocolMetadata(definition: NWProtocolDefinition) -> NWProtocolMetadata? {
        _ = definition
        return nil
    }
}

extension NWConnection {
    public func restart() {}
    public func batch(_ block: () -> Void) { block() }
    public var maximumDatagramSize: Int { 0 }

    public func metadata(definition: NWProtocolDefinition) -> NWProtocolMetadata? {
        _ = definition
        return nil
    }

    public func receiveDiscontiguous(
        minimumIncompleteLength: Int,
        maximumLength: Int,
        completion: @escaping (DispatchData?, ContentContext?, Bool, NWError?) -> Void
    ) {
        _ = minimumIncompleteLength
        _ = maximumLength
        completion(nil, nil, false, .unsupported)
    }

    public func receiveMessageDiscontiguous(
        completion: @escaping (DispatchData?, ContentContext?, Bool, NWError?) -> Void
    ) {
        completion(nil, nil, false, .unsupported)
    }

    public func send<Content>(
        content: Content?,
        contentContext: ContentContext = .defaultMessage,
        isComplete: Bool = true,
        completion: SendCompletion
    ) {
        _ = content
        _ = contentContext
        _ = isComplete
        if case .contentProcessed(let handler) = completion {
            handler(.unsupported)
        }
    }

    public convenience init?(from: NWConnectionGroup, to: NWEndpoint? = nil, using: NWProtocolOptions? = nil) {
        return nil
    }

    public convenience init?(message: NWConnectionGroup.Message) {
        return nil
    }

    public struct DataTransferReport: Sendable, CustomDebugStringConvertible {
        public struct PathReport: Sendable {
            public let sentIPPacketCount: UInt64
            public let receivedIPPacketCount: UInt64
            public let sentTransportByteCount: UInt64
            public let receivedTransportByteCount: UInt64
            public let sentApplicationByteCount: UInt64
            public let receivedApplicationByteCount: UInt64
            public let retransmittedTransportByteCount: UInt64
            public let receivedTransportDuplicateByteCount: UInt64
            public let receivedTransportOutOfOrderByteCount: UInt64
            public let transportMinimumRTT: TimeInterval
            public let transportRTTVariance: TimeInterval
            public let transportSmoothedRTT: TimeInterval
            public let interface: NWInterface
            public var radioType: NWInterface.RadioType? { nil }
        }

        public let pathReports: [PathReport]
        public let duration: TimeInterval
        public var aggregatePathReport: PathReport {
            pathReports[0]
        }
        public var debugDescription: String { "DataTransferReport" }
    }

    public class PendingDataTransferReport {
        public func collect(
            queue: DispatchQueue,
            completion: @escaping (DataTransferReport) -> Void
        ) {
            _ = queue
            let dummyInterface = NWInterface(name: "lo", type: .loopback)
            let report = DataTransferReport.PathReport(
                sentIPPacketCount: 0,
                receivedIPPacketCount: 0,
                sentTransportByteCount: 0,
                receivedTransportByteCount: 0,
                sentApplicationByteCount: 0,
                receivedApplicationByteCount: 0,
                retransmittedTransportByteCount: 0,
                receivedTransportDuplicateByteCount: 0,
                receivedTransportOutOfOrderByteCount: 0,
                transportMinimumRTT: 0,
                transportRTTVariance: 0,
                transportSmoothedRTT: 0,
                interface: dummyInterface
            )
            completion(DataTransferReport(pathReports: [report], duration: 0))
        }
    }

    public func startDataTransferReport() -> PendingDataTransferReport {
        PendingDataTransferReport()
    }

    public struct EstablishmentReport: CustomDebugStringConvertible {
        public struct Resolution: Sendable {
            public enum DNSProtocol: Hashable, Sendable { case unknown, udp, tcp, tls, https }
            public enum Source: Hashable, Sendable { case query, cache, expiredCache }
            public let duration: TimeInterval
            public let source: Source
            public var dnsProtocol: DNSProtocol { .unknown }
            public let endpointCount: Int
            public let preferredEndpoint: NWEndpoint
            public let successfulEndpoint: NWEndpoint
        }

        public struct Handshake {
            public let definition: NWProtocolDefinition
            public let handshakeRTT: TimeInterval
            public let handshakeDuration: TimeInterval
        }

        public let duration: TimeInterval
        public let attemptStartedAfterInterval: TimeInterval
        public let previousAttemptCount: Int
        public let usedProxy: Bool
        public let proxyConfigured: Bool
        public let proxyEndpoint: NWEndpoint?
        public let resolutions: [Resolution]
        public let handshakes: [Handshake]
        public var debugDescription: String { "EstablishmentReport" }
    }

    public func requestEstablishmentReport(
        queue: DispatchQueue,
        completion: @escaping (EstablishmentReport?) -> Void
    ) {
        _ = queue
        completion(nil)
    }
}
