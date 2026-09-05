import Foundation

/// Linux starting implementation of Apple's public `GameKit` module.
///
/// Local value types, enum raw values, match-request arithmetic, achievement
/// completion, and `GKGameActivity` state transitions are real in-memory
/// behavior. Game Center identity, leaderboards, matchmaking, iCloud saved
/// games, voice chat, and dashboard UI are fail-closed: this host has no
/// Apple Game Center daemon, entitlements, or presentation surface.

public let GKErrorDomain = "GKErrorDomain"
public let GKGameSessionErrorDomain = "GKGameSessionErrorDomain"
public let GKSessionErrorDomain = "GKSessionErrorDomain"
public let GKVoiceChatServiceErrorDomain = "GKVoiceChatServiceErrorDomain"

/// Documented Game Center sentinel for a player identifier that is no longer
/// available. Exact on-wire spelling is recorded as an oracle question.
public let GKPlayerIDNoLongerAvailable = "/unavailable"

/// One week, matching the public `GKTurnTimeoutDefault` duration comment.
public var GKTurnTimeoutDefault: TimeInterval = 60 * 60 * 24 * 7
/// No timeout. Public headers describe this as "never times out".
public var GKTurnTimeoutNone: TimeInterval = 0
/// One day, matching the public `GKExchangeTimeoutDefault` duration comment.
public var GKExchangeTimeoutDefault: TimeInterval = 60 * 60 * 24
public var GKExchangeTimeoutNone: TimeInterval = 0

extension NSNotification.Name {
    public static let GKPlayerAuthenticationDidChangeNotificationName =
        NSNotification.Name("GKPlayerAuthenticationDidChangeNotificationName")
    public static let GKPlayerDidChangeNotificationName =
        NSNotification.Name("GKPlayerDidChangeNotificationName")
}

enum GameKitHost {
    static let unsupportedDescription =
        "Game Center Apple identity, matchmaking, and dashboard services are unavailable on this Linux host."

    static func unsupportedError(
        _ code: GKError.Code = .notAuthenticated
    ) -> GKError {
        GKError(code, userInfo: [NSLocalizedDescriptionKey: unsupportedDescription])
    }

    static func sessionError(
        _ code: GKGameSessionError.Code = .notAuthenticated
    ) -> GKGameSessionError {
        GKGameSessionError(
            code,
            userInfo: [NSLocalizedDescriptionKey: unsupportedDescription]
        )
    }

    static func fail<T>(_ completion: ((T?, (any Error)?) -> Void)?) {
        completion?(nil, unsupportedError())
    }

    static func fail(_ completion: (((any Error)?) -> Void)?) {
        completion?(unsupportedError())
    }

    static func failSession<T>(_ completion: ((T?, (any Error)?) -> Void)?) {
        completion?(nil, sessionError())
    }
}
