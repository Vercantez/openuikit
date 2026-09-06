import Foundation

public let MTRErrorDomain = "MTRErrorDomain"
public let MTRInteractionErrorDomain = "MTRInteractionErrorDomain"

public struct MTRError: Error, CustomNSError, Hashable, @unchecked Sendable {
    public enum Code: Int, Sendable, Hashable {
        case generalError = 1
        case invalidStringLength = 2
        case invalidIntegerValue = 3
        case invalidArgument = 4
        case invalidMessageLength = 5
        case invalidState = 6
        case wrongAddressType = 7
        case integrityCheckFailed = 8
        case timeout = 9
        case bufferTooSmall = 10
        case fabricExists = 11
        case unknownSchema = 12
        case schemaMismatch = 13
        case tlvDecodeFailed = 14
        case dnssdUnauthorized = 15
        case cancelled = 16
        case accessDenied = 17
        case busy = 18
        case notFound = 19
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MTRErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var generalError: Code { .generalError }
    public static var invalidStringLength: Code { .invalidStringLength }
    public static var invalidIntegerValue: Code { .invalidIntegerValue }
    public static var invalidArgument: Code { .invalidArgument }
    public static var invalidMessageLength: Code { .invalidMessageLength }
    public static var invalidState: Code { .invalidState }
    public static var wrongAddressType: Code { .wrongAddressType }
    public static var integrityCheckFailed: Code { .integrityCheckFailed }
    public static var timeout: Code { .timeout }
    public static var bufferTooSmall: Code { .bufferTooSmall }
    public static var fabricExists: Code { .fabricExists }
    public static var unknownSchema: Code { .unknownSchema }
    public static var schemaMismatch: Code { .schemaMismatch }
    public static var tlvDecodeFailed: Code { .tlvDecodeFailed }
    public static var dnssdUnauthorized: Code { .dnssdUnauthorized }
    public static var cancelled: Code { .cancelled }
    public static var accessDenied: Code { .accessDenied }
    public static var busy: Code { .busy }
    public static var notFound: Code { .notFound }

    public static func == (lhs: MTRError, rhs: MTRError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MTRError.Code {
    public static func ~= (match: MTRError.Code, error: any Error) -> Bool {
        if let typed = error as? MTRError { return typed.code == match }
        let ns = error as NSError
        return ns.domain == MTRErrorDomain && ns.code == match.rawValue
    }
}

public struct MTRInteractionError: Error, CustomNSError, Hashable, @unchecked Sendable {
    public enum Code: Int, Sendable, Hashable {
        case failure = 0x01
        case invalidSubscription = 0x7D
        case unsupportedAccess = 0x7E
        case unsupportedEndpoint = 0x7F
        case invalidAction = 0x80
        case unsupportedCommand = 0x81
        case invalidCommand = 0x85
        case unsupportedAttribute = 0x86
        case constraintError = 0x87
        case unsupportedWrite = 0x88
        case resourceExhausted = 0x89
        case notFound = 0x8B
        case unreportableAttribute = 0x8C
        case invalidDataType = 0x8D
        case unsupportedRead = 0x8F
        case dataVersionMismatch = 0x92
        case timeout = 0x94
        case busy = 0x9C
        case accessRestricted = 0x9D
        case unsupportedCluster = 0xC3
        case noUpstreamSubscription = 0xC5
        case needsTimedInteraction = 0xC6
        case unsupportedEvent = 0xC7
        case pathsExhausted = 0xC8
        case timedRequestMismatch = 0xC9
        case failsafeRequired = 0xCA
        case invalidInState = 0xCB
        case noCommandResponse = 0xCC
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MTRInteractionErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var failure: Code { .failure }
    public static var invalidSubscription: Code { .invalidSubscription }
    public static var unsupportedAccess: Code { .unsupportedAccess }
    public static var unsupportedEndpoint: Code { .unsupportedEndpoint }
    public static var invalidAction: Code { .invalidAction }
    public static var unsupportedCommand: Code { .unsupportedCommand }
    public static var invalidCommand: Code { .invalidCommand }
    public static var unsupportedAttribute: Code { .unsupportedAttribute }
    public static var constraintError: Code { .constraintError }
    public static var unsupportedWrite: Code { .unsupportedWrite }
    public static var resourceExhausted: Code { .resourceExhausted }
    public static var notFound: Code { .notFound }
    public static var unreportableAttribute: Code { .unreportableAttribute }
    public static var invalidDataType: Code { .invalidDataType }
    public static var unsupportedRead: Code { .unsupportedRead }
    public static var dataVersionMismatch: Code { .dataVersionMismatch }
    public static var timeout: Code { .timeout }
    public static var busy: Code { .busy }
    public static var accessRestricted: Code { .accessRestricted }
    public static var unsupportedCluster: Code { .unsupportedCluster }
    public static var noUpstreamSubscription: Code { .noUpstreamSubscription }
    public static var needsTimedInteraction: Code { .needsTimedInteraction }
    public static var unsupportedEvent: Code { .unsupportedEvent }
    public static var pathsExhausted: Code { .pathsExhausted }
    public static var timedRequestMismatch: Code { .timedRequestMismatch }
    public static var failsafeRequired: Code { .failsafeRequired }
    public static var invalidInState: Code { .invalidInState }
    public static var noCommandResponse: Code { .noCommandResponse }

    public static func == (lhs: MTRInteractionError, rhs: MTRInteractionError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MTRInteractionError.Code {
    public static func ~= (match: MTRInteractionError.Code, error: any Error) -> Bool {
        if let typed = error as? MTRInteractionError { return typed.code == match }
        let ns = error as NSError
        return ns.domain == MTRInteractionErrorDomain && ns.code == match.rawValue
    }
}

func MTRMakeError(_ code: MTRError.Code, reason: String? = nil) -> MTRError {
    var info: [String: Any] = [:]
    if let reason { info[NSLocalizedDescriptionKey] = reason }
    return MTRError(code, userInfo: info)
}

func MTRFailClosed(_ code: MTRError.Code = .invalidState) -> MTRError {
    MTRMakeError(
        code,
        reason: "Matter controller / fabric / radio APIs are unavailable on this Linux host"
    )
}

public typealias MTRStatusCompletion = ((any Error)?) -> Void
public typealias StatusCompletion = ((any Error)?) -> Void
public typealias MTRDeviceResponseHandler = ([[String: Any]]?, (any Error)?) -> Void
public typealias MTRDeviceReportHandler = ([Any]) -> Void
public typealias MTRDeviceErrorHandler = (any Error) -> Void
public typealias MTRDeviceResubscriptionScheduledHandler = (any Error, NSNumber) -> Void
public typealias MTRSubscriptionEstablishedHandler = () -> Void
public typealias SubscriptionEstablishedHandler = () -> Void
public typealias MTRValuesHandler = (Any?, (any Error)?) -> Void
public typealias ResponseHandler = (Any?, (any Error)?) -> Void
public typealias MTRDeviceConnectionCallback = (MTRBaseDevice?, (any Error)?) -> Void
public typealias MTRDeviceControllerGetterHandler = (Any?, (any Error)?) -> Void
public typealias MTRDeviceOpenCommissioningWindowHandler = (MTRSetupPayload?, (any Error)?) -> Void
public typealias MTRLogCallback = (MTRLogType, String, String) -> Void
public typealias MTRAsyncCallbackReadyHandler = (Any, Int) -> Void
public typealias MTRCSRDERBytes = Data
public typealias MTRCertificateDERBytes = Data
public typealias MTRCertificateTLVBytes = Data
public typealias MTRTLVBytes = Data
public typealias MTRNOCChainGenerationCompleteHandler = (Data?, Data?, Data?, NSNumber?, (any Error)?) -> Void

private var mtrLogCallback: MTRLogCallback?
private var mtrLogThreshold: MTRLogType = .error

public func MTRSetLogCallback(_ logTypeThreshold: MTRLogType, _ callback: MTRLogCallback?) {
    mtrLogThreshold = logTypeThreshold
    mtrLogCallback = callback
}

func MTRCurrentLogThreshold() -> MTRLogType { mtrLogThreshold }
func MTRCurrentLogCallback() -> MTRLogCallback? { mtrLogCallback }

func MTREmitLog(_ type: MTRLogType, _ message: String) {
    guard let callback = mtrLogCallback else { return }
    if type.rawValue <= mtrLogThreshold.rawValue {
        callback(type, "Matter", message)
    }
}

public func MTRSetMessageReliabilityParameters(
    _ idleRetransmitMs: NSNumber?,
    _ activeRetransmitMs: NSNumber?,
    _ activeThresholdMs: NSNumber?,
    _ additionalRetransmitDelayMs: NSNumber?
) {
    _ = (idleRetransmitMs, activeRetransmitMs, activeThresholdMs, additionalRetransmitDelayMs)
}

public func MTRDeviceControllerStorageClasses() -> Set<AnyHashable> {
    [
        ObjectIdentifier(MTRSetupPayload.self),
        ObjectIdentifier(MTRClusterPath.self),
        ObjectIdentifier(MTRAttributePath.self),
        ObjectIdentifier(MTREventPath.self),
        ObjectIdentifier(MTRCommandPath.self),
    ]
}
