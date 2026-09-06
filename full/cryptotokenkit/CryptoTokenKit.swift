@_exported import Foundation

// Linux starting point for Apple's CryptoTokenKit. Smart-card readers, NFC
// slots, ctkd, Secure Enclave tokens, and entitlement-gated pairing are
// fail-closed. Value types, TLV/ATR parsing, in-process token configuration,
// and exact error codes are implemented from the pinned Xcode 26.1 graph,
// API digester, and dotnet/macios bindings.

// MARK: - Error domain

/// Process-local identity of Apple's `TKErrorDomain`.
///
/// Pinned `dotnet/macios` `src/cryptotokenkit.cs` annotates
/// `TKErrorCode` with `[ErrorDomain ("TKErrorDomain")]`.
public let TKErrorDomain = "TKErrorDomain"

/// Bridged CryptoTokenKit error.
///
/// Raw values from the pinned macios `TKErrorCode` enum (corroborated by
/// the API-digester child order for `TKError.Code`):
/// `notImplemented = -1` … `authenticationNeeded = -9`.
@frozen
public struct TKError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = TKError

        case notImplemented = -1
        case communicationError = -2
        case corruptedData = -3
        case canceledByUser = -4
        case authenticationFailed = -5
        case objectNotFound = -6
        case tokenNotFound = -7
        case badParameter = -8
        case authenticationNeeded = -9

        public static var TKErrorTokenNotFound: Code { .tokenNotFound }
        public static var TKErrorObjectNotFound: Code { .objectNotFound }
        public static var TKErrorAuthenticationFailed: Code { .authenticationFailed }
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { TKErrorDomain }

    public static var errorDomain: String { TKErrorDomain }

    public static var notImplemented: Code { .notImplemented }
    public static var communicationError: Code { .communicationError }
    public static var corruptedData: Code { .corruptedData }
    public static var canceledByUser: Code { .canceledByUser }
    public static var authenticationFailed: Code { .authenticationFailed }
    public static var objectNotFound: Code { .objectNotFound }
    public static var tokenNotFound: Code { .tokenNotFound }
    public static var badParameter: Code { .badParameter }
    public static var authenticationNeeded: Code { .authenticationNeeded }

    public static var TKErrorTokenNotFound: Code { .tokenNotFound }
    public static var TKErrorObjectNotFound: Code { .objectNotFound }
    public static var TKErrorAuthenticationFailed: Code { .authenticationFailed }

    public init(_ code: Code, reason: String? = nil) {
        var info: [String: Any] = [:]
        if let reason {
            info[NSLocalizedDescriptionKey] = reason
        }
        self.init(code, userInfo: info)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

func tkMakeError(_ code: TKError.Code, reason: String? = nil) -> TKError {
    TKError(code, reason: reason)
}

func tkObjectIDsEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let left = lhs as? NSObject, let right = rhs as? NSObject {
        return left.isEqual(right)
    }
    return false
}

// MARK: - Typealiases

/// BER/simple/compact TLV tag. Apple overlays this as `UInt64`.
public typealias TKTLVTag = UInt64

/// Constraint object supplied to `TKTokenSessionDelegate` auth callbacks.
public typealias TKTokenOperationConstraint = AnyObject

// MARK: - Token operations

/// Key operations a token session may advertise.
///
/// Raw values from pinned macios `TKTokenOperation`: `none = 0` …
/// `performKeyExchange = 4`.
public enum TKTokenOperation: Int, Equatable, Hashable, Sendable {
    case none = 0
    case readData = 1
    case signData = 2
    case decryptData = 3
    case performKeyExchange = 4
}

// MARK: - Smart card protocols (OptionSet)

/// ISO 7816 transmission protocols.
///
/// Bit positions from pinned macios `TKSmartCardProtocol`:
/// `T0 = 1 << 0`, `T1 = 1 << 1`, `T15 = 1 << 15`,
/// `Any = (1 << 16) - 1`.
public struct TKSmartCardProtocol: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let t0 = TKSmartCardProtocol(rawValue: 1 << 0)
    public static let t1 = TKSmartCardProtocol(rawValue: 1 << 1)
    public static let t15 = TKSmartCardProtocol(rawValue: 1 << 15)
    public static let any = TKSmartCardProtocol(rawValue: (1 << 16) - 1)
}

// MARK: - PIN format enumerations

extension TKSmartCardPINFormat {
    /// PIN character set. Raw values from macios `TKSmartCardPinCharset`.
    public enum Charset: Int, Equatable, Hashable, Sendable {
        case numeric = 0
        case alphanumeric = 1
        case upperAlphanumeric = 2
    }

    /// PIN encoding. Raw values from macios `TKSmartCardPinEncoding`.
    public enum Encoding: Int, Equatable, Hashable, Sendable {
        case binary = 0
        case ascii = 1
        case bcd = 2
    }

    /// PIN justification inside the PIN block.
    public enum Justification: Int, Equatable, Hashable, Sendable {
        case left = 0
        case right = 1
    }
}

extension TKSmartCardUserInteractionForPINOperation {
    /// Conditions that complete a PIN entry. Flags from macios
    /// `TKSmartCardPinCompletion`: `maxLength = 1 << 0`, `key = 1 << 1`,
    /// `timeout = 1 << 2`.
    public struct Completion: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let maxLength = Completion(rawValue: 1 << 0)
        public static let key = Completion(rawValue: 1 << 1)
        public static let timeout = Completion(rawValue: 1 << 2)
    }
}

extension TKSmartCardUserInteractionForSecurePINChange {
    /// Which PIN values a secure PIN change confirms. Flags from macios
    /// `TKSmartCardPinConfirmation`: `new = 1 << 0`, `current = 1 << 1`.
    public struct Confirmation: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let new = Confirmation(rawValue: 1 << 0)
        public static let current = Confirmation(rawValue: 1 << 1)
    }
}

extension TKSmartCardSlot {
    /// Reader slot occupancy. Sequential values from macios
    /// `TKSmartCardSlotState`: `missing = 0` … `validCard = 4`.
    public enum State: Int, Equatable, Hashable, Sendable {
        case missing = 0
        case empty = 1
        case probing = 2
        case muteCard = 3
        case validCard = 4
    }
}

// MARK: - Nested typealiases on token types

extension TKToken {
    public typealias InstanceID = String
    public typealias ObjectID = Any
}

extension TKTokenDriver {
    public typealias ClassID = String
}
