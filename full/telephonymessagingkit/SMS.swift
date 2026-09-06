@_exported import Foundation
public struct SMSContent: Equatable, Codable, Sendable {
    public let body: String
    public init(body: String) {
        self.body = body
    }
}

public struct SMSMessage: Equatable, Codable, Sendable {
    public let cellularServiceID: CellularServiceID
    public let handle: SMSHandle
    public let content: SMSContent
    public let messageID: SMSMessageID
    public init(cellularServiceID: CellularServiceID, handle: SMSHandle, messageID: SMSMessageID, content: SMSContent) {
        self.cellularServiceID = cellularServiceID
        self.handle = handle
        self.messageID = messageID
        self.content = content
    }
}

public final class SMSService {
public struct ViabilityNotification: Equatable, Hashable, Sendable {
    public let cellularServiceID: CellularServiceID
    public let isViable: Bool
    public init(cellularServiceID: CellularServiceID, isViable: Bool) {
        self.cellularServiceID = cellularServiceID
        self.isViable = isViable
    }
}

public struct IncomingMessageNotification: Sendable {
    public let message: SMSMessage
    public init(message: SMSMessage) {
        self.message = message
    }
}

public struct CriticalMessageStateNotification: Equatable, Hashable, Sendable {
public enum State: Hashable, Sendable {
    case sent
}

    public let cellularServiceID: CellularServiceID
    public let state: SMSService.CriticalMessageStateNotification.State
    public let messageID: SMSMessageID
    public init(cellularServiceID: CellularServiceID, state: SMSService.CriticalMessageStateNotification.State, messageID: SMSMessageID) {
        self.cellularServiceID = cellularServiceID
        self.state = state
        self.messageID = messageID
    }
}

public enum Error: Hashable, Codable, Swift.Error, LocalizedError, Sendable {
    case notSupported
    case permanentFailure
    case temporaryFailure
    case unknown
    public var errorDescription: String? {
        "Linux has no telephony messaging daemon (\(String(describing: self)))."
    }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? {
        "Use a Darwin device with carrier messaging entitlements."
    }
    public var helpAnchor: String? { nil }
}

    public func reportSpam(_ message: SMSMessage) async throws {
        throw Error.notSupported
    }
    public func sendMessage(_ message: SMSMessage) async throws {
        throw Error.notSupported
    }
    public var viabilityNotifications: TelephonyMessagingEmptyAsyncSequence<SMSService.ViabilityNotification> {
        get throws {
            throw Error.notSupported
        }
    }
    public var incomingMessageNotifications: TelephonyMessagingEmptyAsyncSequence<SMSService.IncomingMessageNotification> {
        get throws {
            throw Error.notSupported
        }
    }
    public var criticalMessageStateNotifications: TelephonyMessagingEmptyAsyncSequence<SMSService.CriticalMessageStateNotification> {
        get throws {
            throw Error.notSupported
        }
    }
    public func isViable(for cellularServiceID: CellularServiceID) -> Bool {
        false
    }
    init() {}
}

public struct SMSMessageID: RawRepresentable, Hashable, Codable, CustomStringConvertible, Sendable {
    public typealias RawValue = UInt32
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    public var description: String { String(rawValue) }
}

public struct SMSHandle: Equatable, Codable, Sendable {
    public let phoneNumber: String
    public init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
}
