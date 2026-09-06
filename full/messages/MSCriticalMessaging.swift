import Foundation

/// Authorization status for the Critical Messaging API.
///
/// Case order matches the pinned API digester (`unknown`, `denied`,
/// `approved`). Sequential `Int` raw values are the Swift default for that
/// order; Darwin's explicit integers were not printed.
public enum MSCriticalMessagingAuthorizationStatus: Int, Hashable, Sendable {
    case unknown = 0
    case denied = 1
    case approved = 2
}

/// Errors returned by the Critical Messaging API.
///
/// Case order matches the pinned API digester (`unknown`,
/// `invalidAuthenticationRequest`, `notSupported`, `notAuthorized`,
/// `sendFailed`). Sequential `Int` raw values are the Swift default for
/// that order. The Darwin `errorDomain` string is unobserved; Linux uses
/// the type name.
public enum MSCriticalMessagingError: Int, Error, LocalizedError, CustomNSError, Hashable, Sendable {
    case unknown = 0
    case invalidAuthenticationRequest = 1
    case notSupported = 2
    case notAuthorized = 3
    case sendFailed = 4

    public static var errorDomain: String { "MSCriticalMessagingError" }

    public var errorCode: Int { rawValue }

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown critical messaging error."
        case .invalidAuthenticationRequest:
            return "The critical messaging authorization request was invalid."
        case .notSupported:
            return "Critical messaging is not supported on this Linux host."
        case .notAuthorized:
            return "The process is not authorized to send critical messages."
        case .sendFailed:
            return "The critical message could not be sent."
        }
    }
}

/// A phone-number identity for critical messaging.
public struct MSRecipient: Hashable, Sendable {
    public var phoneNumber: String

    public init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
}

/// A critical-alert SMS payload. Linux never delivers it.
public struct MSCriticalMessage: Sendable {
    public var messageText: String

    public init(messageText: String) {
        self.messageText = messageText
    }
}

/// Critical SMS entry point. Linux has no entitlement, daemon, or carrier
/// path: authorization and send fail with `.notSupported`, and the
/// recipient cap is zero.
open class MSCriticalSMSMessenger: NSObject {
    public override init() {
        super.init()
    }

    /// Darwin's cap is unobserved. Linux reports `0` so callers cannot
    /// schedule a send that this host would fabricate.
    open var maximumCriticalMessagingRecipients: Int { 0 }

    open func requestAuthorization(
        for recipients: [MSRecipient]
    ) async throws -> [MSRecipient: MSCriticalMessagingAuthorizationStatus] {
        _ = recipients
        throw MSCriticalMessagingError.notSupported
    }

    open func checkAuthorizationStatus(
        for recipients: [MSRecipient]
    ) async throws -> [MSRecipient: MSCriticalMessagingAuthorizationStatus] {
        _ = recipients
        throw MSCriticalMessagingError.notSupported
    }

    open func send(
        _ message: MSCriticalMessage,
        to recipient: MSRecipient
    ) async throws -> Bool {
        _ = message
        _ = recipient
        throw MSCriticalMessagingError.notSupported
    }
}
