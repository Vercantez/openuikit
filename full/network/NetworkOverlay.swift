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

    public struct ApplicationError: Hashable, Sendable, Error, ExpressibleByIntegerLiteral {
        public let code: UInt64
        public let reason: String?
        public typealias IntegerLiteralType = UInt64

        public init(code: UInt64, reason: String? = nil) {
            self.code = code
            self.reason = reason
        }

        public init(code: UInt64, message: String?) {
            self.init(code: code, reason: message)
        }

        public init(integerLiteral code: UInt64) {
            self.init(code: code, reason: nil)
        }

        public var message: String? { reason }
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
        public var maxDatagramFrameSize: UInt16 = 0
        public var initialMaxData: UInt64 = 0
        public var initialMaxStreamDataBidirectionalLocal: UInt64 = 0
        public var initialMaxStreamDataBidirectionalRemote: UInt64 = 0
        public var initialMaxStreamDataUnidirectional: UInt64 = 0
        public var initialMaxStreamsBidirectional: UInt64 = 0
        public var initialMaxStreamsUnidirectional: UInt64 = 0
        public var isDatagram = false
        public let securityProtocolOptions: sec_protocol_options_t

        public init(alpn: [String] = []) {
            self.alpn = alpn
            self.securityProtocolOptions = sec_protocol_options()
            super.init()
        }
    }

    public class Metadata: NWProtocolMetadata {
        public enum KeepAliveBehavior: Hashable, Sendable {
            case on
            case off
            case seconds(Int)

            public static var disabled: KeepAliveBehavior { .off }
            public static var application: KeepAliveBehavior { .on }
        }

        public var streamID: UInt64 { streamIdentifier }
        public var streamIdentifier: UInt64 = 0
        public var keepAliveBehavior: KeepAliveBehavior = .off
        public var keepAlive: KeepAliveBehavior {
            get { keepAliveBehavior }
            set { keepAliveBehavior = newValue }
        }
        public var applicationError: ApplicationError?
        public var negotiatedALPN: String?
        public var remoteIdleTimeout: UInt32 = 0
        public var usableDatagramFrameSize: UInt16 = 0
        public var streamApplicationErrorCode: UInt64?
        public var localMaxStreamsBidirectional: UInt64 = 0
        public var localMaxStreamsUnidirectional: UInt64 = 0
        public var remoteMaxStreamsBidirectional: UInt64 = 0
        public var remoteMaxStreamsUnidirectional: UInt64 = 0
        public let securityProtocolMetadata: sec_protocol_metadata_t = sec_protocol_metadata()
    }
}

public class NWProtocolWebSocket: NWProtocol {
    public static let definition = NWProtocolDefinition(identifier: "ws")

    public enum Opcode: UInt8, Hashable, Sendable {
        case cont = 0
        case text = 1
        case binary = 2
        case close = 8
        case ping = 9
        case pong = 10
    }

    public enum Version: Hashable, Sendable {
        case version13
        public static var v13: Version { .version13 }
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

        case protocolCode(Defined)
        case applicationCode(UInt16)
        case privateCode(UInt16)

        public static func defined(_ code: Defined) -> CloseCode { .protocolCode(code) }
        public static func privateStatus(_ code: UInt16) -> CloseCode { .privateCode(code) }

        public init(rawValue: UInt16) throws {
            if let defined = Defined(rawValue: rawValue) {
                self = .protocolCode(defined)
            } else if rawValue >= 3000 && rawValue <= 3999 {
                self = .applicationCode(rawValue)
            } else if rawValue >= 4000 && rawValue <= 4999 {
                self = .privateCode(rawValue)
            } else {
                throw NWError.posix(.EINVAL)
            }
        }

        public var rawValue: UInt16 {
            switch self {
            case .protocolCode(let code): return code.rawValue
            case .applicationCode(let code): return code
            case .privateCode(let code): return code
            }
        }
    }

    /// RFC 6455 §5 data frame. Encoding and decoding are local; they do not
    /// speak a TLS or HTTP handshake.
    public struct Frame: Hashable, Sendable {
        public var fin: Bool
        public var opcode: Opcode
        public var masked: Bool
        public var maskingKey: UInt32
        public var payload: Data

        public init(
            fin: Bool = true,
            opcode: Opcode,
            payload: Data,
            masked: Bool = false,
            maskingKey: UInt32 = 0
        ) {
            self.fin = fin
            self.opcode = opcode
            self.payload = payload
            self.masked = masked
            self.maskingKey = maskingKey
        }

        public func encode() -> Data {
            var bytes: [UInt8] = []
            let finBit: UInt8 = fin ? 0x80 : 0
            bytes.append(finBit | opcode.rawValue)
            let length = payload.count
            var second: UInt8 = masked ? 0x80 : 0
            if length <= 125 {
                second |= UInt8(length)
                bytes.append(second)
            } else if length <= 65535 {
                second |= 126
                bytes.append(second)
                bytes.append(UInt8((length >> 8) & 0xff))
                bytes.append(UInt8(length & 0xff))
            } else {
                second |= 127
                bytes.append(second)
                var remaining = UInt64(length)
                var ext = [UInt8](repeating: 0, count: 8)
                for index in stride(from: 7, through: 0, by: -1) {
                    ext[index] = UInt8(remaining & 0xff)
                    remaining >>= 8
                }
                bytes.append(contentsOf: ext)
            }
            var keyBytes = [UInt8](repeating: 0, count: 4)
            if masked {
                var key = maskingKey
                for index in stride(from: 3, through: 0, by: -1) {
                    keyBytes[index] = UInt8(key & 0xff)
                    key >>= 8
                }
                bytes.append(contentsOf: keyBytes)
            }
            if masked {
                bytes.append(contentsOf: NWProtocolWebSocket.mask(payload, key: keyBytes))
            } else {
                bytes.append(contentsOf: payload)
            }
            return Data(bytes)
        }

        public static func decode(_ data: Data) -> Frame? {
            let bytes = [UInt8](data)
            guard bytes.count >= 2 else { return nil }
            let fin = (bytes[0] & 0x80) != 0
            guard let opcode = Opcode(rawValue: bytes[0] & 0x0f) else { return nil }
            let masked = (bytes[1] & 0x80) != 0
            var payloadLength = Int(bytes[1] & 0x7f)
            var offset = 2
            if payloadLength == 126 {
                guard bytes.count >= offset + 2 else { return nil }
                payloadLength = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
                offset += 2
            } else if payloadLength == 127 {
                guard bytes.count >= offset + 8 else { return nil }
                var length: UInt64 = 0
                for index in 0..<8 {
                    length = (length << 8) | UInt64(bytes[offset + index])
                }
                if length > UInt64(Int.max) { return nil }
                payloadLength = Int(length)
                offset += 8
            }
            var key: UInt32 = 0
            var keyBytes = [UInt8](repeating: 0, count: 4)
            if masked {
                guard bytes.count >= offset + 4 else { return nil }
                keyBytes = Array(bytes[offset..<(offset + 4)])
                key = keyBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
                offset += 4
            }
            guard bytes.count >= offset + payloadLength else { return nil }
            var payload = Data(bytes[offset..<(offset + payloadLength)])
            if masked {
                payload = Data(NWProtocolWebSocket.mask(payload, key: keyBytes))
            }
            return Frame(
                fin: fin,
                opcode: opcode,
                payload: payload,
                masked: masked,
                maskingKey: key
            )
        }
    }

    static func mask(_ payload: Data, key: [UInt8]) -> [UInt8] {
        guard key.count == 4 else { return Array(payload) }
        return payload.enumerated().map { offset, byte in
            byte ^ key[offset % 4]
        }
    }

    public class Options: NWProtocolOptions {
        public var autoReplyPing = false
        public var maximumMessageSize = 0
        public var skipHandshake = false
        public private(set) var subprotocols: [String] = []
        public private(set) var additionalHeaders: [(name: String, value: String)] = []
        public let version: Version

        public override convenience init() {
            self.init(.version13)
        }

        public init(_ version: Version = .version13) {
            self.version = version
            super.init()
        }

        public func setSubprotocols(_ protocols: [String]) {
            subprotocols = protocols
        }

        public func addAdditionalHeader(_ name: String, value: String) {
            additionalHeaders.append((name: name, value: value))
        }

        public func setAdditionalHeaders(_ headers: [(name: String, value: String)]) {
            additionalHeaders = headers
        }
    }

    public class Metadata: NWProtocolMetadata {
        public var opcode: Opcode
        public var closeCode: CloseCode
        public var response: Response?
        public var selectedSubprotocol: String?
        public var additionalServerHeaders: [(String, String)]?

        public override convenience init() {
            self.init(opcode: .binary)
        }

        public init(opcode: Opcode) {
            self.opcode = opcode
            self.closeCode = .protocolCode(.normalClosure)
            super.init()
        }
    }

    public struct Response: Hashable, Sendable {
        public enum Status: Hashable, Sendable {
            case accept
            case reject
        }

        public var status: Status
        public var subprotocol: String?
        public var additionalHeaders: [(name: String, value: String)]?

        public init(status: Status) {
            self.init(status: status, subprotocol: nil, additionalHeaders: nil)
        }

        public init(
            status: Status,
            subprotocol: String?,
            additionalHeaders: [(name: String, value: String)]? = nil
        ) {
            self.status = status
            self.subprotocol = subprotocol
            self.additionalHeaders = additionalHeaders
        }

        public static func == (lhs: Response, rhs: Response) -> Bool {
            lhs.status == rhs.status
                && lhs.subprotocol == rhs.subprotocol
                && (lhs.additionalHeaders ?? []).map { "\($0.name)=\($0.value)" }
                    == (rhs.additionalHeaders ?? []).map { "\($0.name)=\($0.value)" }
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(status)
            hasher.combine(subprotocol)
        }
    }
}

public class NWProtocolFramer: NWProtocol {
    public class Definition: NWProtocolDefinition {
        public let implementation: any NWProtocolFramerImplementation.Type
        public init(implementation: any NWProtocolFramerImplementation.Type) {
            self.implementation = implementation
            super.init(identifier: String(describing: implementation))
        }
    }

    public enum StartResult: Hashable, Sendable {
        case ready
        case willMarkReady
    }

    public class Message: NWProtocolMetadata {
        public let definition: Definition
        private var storage: [String: Any] = [:]

        public init(definition: Definition) {
            self.definition = definition
            super.init()
        }

        public subscript(key: String) -> Any? {
            get { storage[key] }
            set { storage[key] = newValue }
        }
    }

    public class Options: NWProtocolOptions {
        public let definition: Definition
        public init(definition: Definition) {
            self.definition = definition
            super.init()
        }
    }

    public final class Instance: @unchecked Sendable, CustomDebugStringConvertible {
        public enum WakeupTime: Hashable, Sendable {
            case milliseconds(UInt64)
            case forever

            public static var now: WakeupTime { .milliseconds(0) }
            public static func interval(_ interval: TimeInterval) -> WakeupTime {
                .milliseconds(UInt64(max(0, interval) * 1000))
            }
        }

        public private(set) var parameters: NWParameters?
        public private(set) var local: NWEndpoint?
        public private(set) var remote: NWEndpoint?
        public let options: Options
        public private(set) var isReady = false
        public private(set) var failedError: NWError?
        public private(set) var lastWakeup: WakeupTime?
        public private(set) var deliveredMessages: [(data: Data, message: Message, isComplete: Bool)] = []

        private var inputBuffer = Data()
        private var inputComplete = false
        private var outputBuffer = Data()
        private var outputSource = Data()
        private var outputSourceOffset = 0
        private var passThroughInputEnabled = false
        private var passThroughOutputEnabled = false
        private var applicationProtocols: [NWProtocolOptions] = []

        public init() {
            self.options = Options(definition: Definition(implementation: NWHostPlaceholderFramer.self))
        }

        public init(
            options: Options,
            parameters: NWParameters? = nil,
            local: NWEndpoint? = nil,
            remote: NWEndpoint? = nil
        ) {
            self.options = options
            self.parameters = parameters
            self.local = local
            self.remote = remote
        }

        public var debugDescription: String {
            "NWProtocolFramer.Instance(ready: \(isReady), input: \(inputBuffer.count), output: \(outputBuffer.count))"
        }

        /// Host-driver: bytes that `parseInput` will observe.
        public func hostFeedInput(_ data: Data, isComplete: Bool = false) {
            inputBuffer.append(data)
            if isComplete { inputComplete = true }
        }

        public var hostCollectedOutput: Data { outputBuffer }

        public func hostSetOutputSource(_ data: Data) {
            outputSource = data
            outputSourceOffset = 0
        }

        public func parseInput(
            minimumIncompleteLength: Int,
            maximumLength: Int,
            parse: (UnsafeMutableRawBufferPointer?, Bool) -> Int
        ) -> Bool {
            if inputBuffer.count < minimumIncompleteLength && !inputComplete {
                return false
            }
            if inputBuffer.isEmpty {
                _ = parse(nil, inputComplete)
                return inputComplete
            }
            let count = min(max(maximumLength, 0), inputBuffer.count)
            var temp = [UInt8](inputBuffer.prefix(count))
            let complete = inputComplete && count == inputBuffer.count
            let consumed = temp.withUnsafeMutableBytes { buffer in
                parse(UnsafeMutableRawBufferPointer(start: buffer.baseAddress, count: buffer.count), complete)
            }
            let n = min(max(consumed, 0), inputBuffer.count)
            if n > 0 {
                inputBuffer.removeFirst(n)
            }
            return true
        }

        public func parseOutput(
            minimumIncompleteLength: Int,
            maximumLength: Int,
            parse: (UnsafeMutableRawBufferPointer?, Bool) -> Int
        ) -> Bool {
            let available = outputSource.count - outputSourceOffset
            if available < minimumIncompleteLength {
                return false
            }
            if available == 0 {
                _ = parse(nil, true)
                return true
            }
            let count = min(max(maximumLength, 0), available)
            var temp = [UInt8](outputSource[outputSourceOffset..<(outputSourceOffset + count)])
            let consumed = temp.withUnsafeMutableBytes { buffer in
                parse(UnsafeMutableRawBufferPointer(start: buffer.baseAddress, count: buffer.count), true)
            }
            let n = min(max(consumed, 0), available)
            outputSourceOffset += n
            return true
        }

        public func writeOutput(data: Data) {
            outputBuffer.append(data)
        }

        public func writeOutput<Output>(data: Output) where Output: DataProtocol {
            outputBuffer.append(contentsOf: data)
        }

        public func writeOutputNoCopy(length: Int) throws {
            let available = outputSource.count - outputSourceOffset
            guard length <= available else { throw NWError.posix(.ERANGE) }
            let slice = outputSource[outputSourceOffset..<(outputSourceOffset + length)]
            outputBuffer.append(slice)
            outputSourceOffset += length
        }

        public func passInput(to protocol: NWProtocolDefinition) { _ = `protocol` }
        public func passThroughInput() { passThroughInputEnabled = true }
        public func passThroughOutput() { passThroughOutputEnabled = true }

        public func markReady() { isReady = true }
        public func markFailed(error: NWError?) { failedError = error }

        public func deliverInput(data: Data, message: Message, isComplete: Bool) {
            deliveredMessages.append((data, message, isComplete))
        }

        public func deliverInputNoCopy(length: Int, message: Message, isComplete: Bool) -> Bool {
            guard length <= inputBuffer.count else { return false }
            let data = inputBuffer.prefix(length)
            inputBuffer.removeFirst(length)
            deliveredMessages.append((Data(data), message, isComplete))
            return true
        }

        public func scheduleWakeup(wakeupTime: WakeupTime) { lastWakeup = wakeupTime }

        public func prependApplicationProtocol(options: NWProtocolOptions) throws {
            applicationProtocols.insert(options, at: 0)
        }

        public func async(execute: @escaping () -> Void) {
            execute()
        }
    }
}

/// Linux host driver that owns a framer implementation and feeds
/// `parseInput` / `writeOutput` / `handleInput` without a live socket.
public final class NWProtocolFramerHostDriver {
    public let instance: NWProtocolFramer.Instance
    public let implementation: any NWProtocolFramerImplementation
    public let startResult: NWProtocolFramer.StartResult

    public init(
        implementation: any NWProtocolFramerImplementation.Type,
        parameters: NWParameters? = nil
    ) {
        let options = NWProtocolFramer.Options(
            definition: NWProtocolFramer.Definition(implementation: implementation)
        )
        let instance = NWProtocolFramer.Instance(options: options, parameters: parameters)
        self.instance = instance
        let impl = implementation.init(framer: instance)
        self.implementation = impl
        self.startResult = impl.start(framer: instance)
        if startResult == .ready {
            instance.markReady()
        }
    }

    @discardableResult
    public func handleIncoming(_ data: Data, complete: Bool = false) -> Int {
        instance.hostFeedInput(data, isComplete: complete)
        return implementation.handleInput(framer: instance)
    }

    public func handleOutgoing(message: NWProtocolFramer.Message, payload: Data, isComplete: Bool) {
        instance.hostSetOutputSource(payload)
        implementation.handleOutput(
            framer: instance,
            message: message,
            messageLength: payload.count,
            isComplete: isComplete
        )
    }

    public var output: Data { instance.hostCollectedOutput }
}

fileprivate final class NWHostPlaceholderFramer: NWProtocolFramerImplementation {
    required init(framer: NWProtocolFramer.Instance) { _ = framer }
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func handleInput(framer: NWProtocolFramer.Instance) -> Int { 0 }
    func handleOutput(
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
    func wakeup(framer: NWProtocolFramer.Instance) { _ = framer }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) { _ = framer }
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
