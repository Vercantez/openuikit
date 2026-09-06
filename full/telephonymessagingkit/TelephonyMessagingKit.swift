@_exported import Foundation

/// Portable Linux starting point for Apple's public `TelephonyMessagingKit` module.
///
/// Value types, identifiers, and fail-closed service boundaries are real.
/// Carrier SMS/MMS/RCS daemons, entitlements, and baseband hardware do not
/// exist on this host; mutating Apple-service APIs throw documented errors
/// and never report success.
public final class TelephonyMessagingSession: Identifiable {
public enum Error: Hashable, Codable, Swift.Error, LocalizedError, Sendable {
    case invalidSession
    case internalError
    case invalidArgument
    case serviceUnavailable
    public var errorDescription: String? {
        "Linux has no telephony messaging daemon (\(String(describing: self)))."
    }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? {
        "Use a Darwin device with carrier messaging entitlements."
    }
    public var helpAnchor: String? { nil }
}

    public var isConfiguredForCarrierMessaging: Bool { false }
    public let mmsService = MMSService()
    public let rcsService = RCSService()
    public let smsService = SMSService()
    public var cellularServices: [CellularServiceState] {
        get throws { [] }
    }
    public var cellularServiceStateUpdates: TelephonyMessagingEmptyAsyncSequence<CellularServiceState> {
        TelephonyMessagingEmptyAsyncSequence()
    }
    public let id: UUID
    public static let shared = TelephonyMessagingSession()
    init() { self.id = UUID() }
}

public struct CellularServiceID: Hashable, Codable, CustomStringConvertible, Sendable {
    public let uuid: UUID
    public init(uuid: UUID = UUID()) { self.uuid = uuid }
    public var description: String { uuid.uuidString }
}

public struct CellularServiceState: Hashable, Codable, Identifiable, Sendable {
    public typealias ID = CellularServiceID
    public let id: CellularServiceID
    public let label: String
    public init(id: CellularServiceID, label: String) {
        self.id = id
        self.label = label
    }
}
