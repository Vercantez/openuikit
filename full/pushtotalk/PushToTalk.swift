import Foundation

// Linux starting point for Apple's PushToTalk. There is no Push To Talk
// daemon, CallKit/PTT entitlement, PushKit token, or AVAudioSession on this
// host. Value types, error codes, descriptors, and the fail-closed manager
// state machine are implemented and tested here. Instantiation of a live
// Apple-backed manager always fails with `invalidPlatform`.

// MARK: - Undeclared foreign types
//
// UIKit and AVFoundation are not declared dependencies of this seed. Channel
// and participant images, and audio-session callbacks, type-check as NSObject
// so the public selectors exist. They are never decoded as bitmaps or mixed
// with a real AVAudioSession. See oracle-questions.tsv.

/// UIKit is not a declared dependency. Images are stored as `NSObject`.
public typealias UIImage = NSObject

/// AVFoundation is not a declared dependency. Audio-session callbacks are
/// never delivered by `PTChannelManager` on Linux.
public typealias AVAudioSession = NSObject

// MARK: - Error domains
//
// String identities match the pinned dotnet-macios `[ErrorDomain (...)]`
// attributes and the TBD export names. Apple's runtime NSError domain
// payload is unobserved (oracle question).

public let PTChannelErrorDomain = "PTChannelErrorDomain"
public let PTInstantiationErrorDomain = "PTInstantiationErrorDomain"

// MARK: - Join / leave / transmit enums
//
// Raw values are the `[Native]` integers recorded by the pinned
// dotnet-macios PushToTalk bindings, which match sequential NS_ENUM
// assignment from the API-digester child order.

public enum PTChannelJoinReason: Int, Equatable, Hashable, Sendable {
    case developerRequest = 0
    case channelRestoration = 1
}

public enum PTChannelLeaveReason: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case userRequest = 1
    case developerRequest = 2
    case systemPolicy = 3
}

public enum PTChannelTransmitRequestSource: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case userRequest = 1
    case developerRequest = 2
    case handsfreeButton = 3
}

public enum PTServiceStatus: Int, Equatable, Hashable, Sendable {
    case ready = 0
    case connecting = 1
    case unavailable = 2
}

public enum PTTransmissionMode: Int, Equatable, Hashable, Sendable {
    case fullDuplex = 0
    case halfDuplex = 1
    case listenOnly = 2
}

// MARK: - PTChannelError

/// Bridged Push To Talk channel error.
///
/// Raw values are the NS_ERROR_ENUM integers recorded by the pinned
/// dotnet-macios bindings (`Unknown = 0` through `TransmissionNotAllowed = 9`).
@frozen
public struct PTChannelError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = PTChannelError

        case unknown = 0
        case channelNotFound = 1
        case channelLimitReached = 2
        case callActive = 3
        case transmissionInProgress = 4
        case transmissionNotFound = 5
        case appNotForeground = 6
        case deviceManagementRestriction = 7
        case screenTimeRestriction = 8
        case transmissionNotAllowed = 9
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { PTChannelErrorDomain }

    public static var errorDomain: String { PTChannelErrorDomain }

    public static var unknown: Code { .unknown }
    public static var channelNotFound: Code { .channelNotFound }
    public static var channelLimitReached: Code { .channelLimitReached }
    public static var callActive: Code { .callActive }
    public static var transmissionInProgress: Code { .transmissionInProgress }
    public static var transmissionNotFound: Code { .transmissionNotFound }
    public static var appNotForeground: Code { .appNotForeground }
    public static var deviceManagementRestriction: Code { .deviceManagementRestriction }
    public static var screenTimeRestriction: Code { .screenTimeRestriction }
    public static var transmissionNotAllowed: Code { .transmissionNotAllowed }

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

extension PTChannelError.Code {
    public static func ~= (match: PTChannelError.Code, error: any Error) -> Bool {
        if let typed = error as? PTChannelError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == PTChannelErrorDomain && nsError.code == match.rawValue
    }
}

// MARK: - PTInstantiationError

/// Bridged Push To Talk manager-instantiation error.
///
/// Raw values are the NS_ERROR_ENUM integers recorded by the pinned
/// dotnet-macios bindings (`Unknown = 0` through
/// `InstantiationAlreadyInProgress = 5`). Linux factory construction
/// always surfaces `invalidPlatform`.
@frozen
public struct PTInstantiationError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = PTInstantiationError

        case unknown = 0
        case invalidPlatform = 1
        case missingBackgroundMode = 2
        case missingPushServerEnvironment = 3
        case missingEntitlement = 4
        case instantiationAlreadyInProgress = 5
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { PTInstantiationErrorDomain }

    public static var errorDomain: String { PTInstantiationErrorDomain }

    public static var unknown: Code { .unknown }
    public static var invalidPlatform: Code { .invalidPlatform }
    public static var missingBackgroundMode: Code { .missingBackgroundMode }
    public static var missingPushServerEnvironment: Code { .missingPushServerEnvironment }
    public static var missingEntitlement: Code { .missingEntitlement }
    public static var instantiationAlreadyInProgress: Code { .instantiationAlreadyInProgress }

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

extension PTInstantiationError.Code {
    public static func ~= (match: PTInstantiationError.Code, error: any Error) -> Bool {
        if let typed = error as? PTInstantiationError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == PTInstantiationErrorDomain && nsError.code == match.rawValue
    }
}
