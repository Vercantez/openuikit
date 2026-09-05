import Foundation

/// Portable counterpart of Game Kit's bridged `NS_ERROR_ENUM(GKErrorDomain, GKErrorCode)`.
/// Numeric codes follow the public GameKit header enumeration corroborated by
/// the pinned dotnet-macios binding (`src/GameKit/GameKit.cs`).
public struct GKError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case cancelled = 2
        case communicationsFailure = 3
        case userDenied = 4
        case invalidCredentials = 5
        case notAuthenticated = 6
        case authenticationInProgress = 7
        case invalidPlayer = 8
        case scoreNotSet = 9
        case parentalControlsBlocked = 10
        case playerStatusExceedsMaximumLength = 11
        case playerStatusInvalid = 12
        case matchRequestInvalid = 13
        case underage = 14
        case gameUnrecognized = 15
        case notSupported = 16
        case invalidParameter = 17
        case unexpectedConnection = 18
        case challengeInvalid = 19
        case turnBasedMatchDataTooLarge = 20
        case turnBasedTooManySessions = 21
        case turnBasedInvalidParticipant = 22
        case turnBasedInvalidTurn = 23
        case turnBasedInvalidState = 24
        case invitationsDisabled = 25
        case playerPhotoFailure = 26
        case ubiquityContainerUnavailable = 27
        case matchNotConnected = 28
        case gameSessionRequestInvalid = 29
        case restrictedToAutomatch = 30
        case apiNotAvailable = 31
        case notAuthorized = 32
        case connectionTimeout = 33
        case apiObsolete = 34
        case iCloudUnavailable = 35
        case lockdownMode = 36
        case appUnlisted = 37
        case debugMode = 38
        case friendListDescriptionMissing = 100
        case friendListRestricted = 101
        case friendListDenied = 102
        case friendRequestNotAvailable = 103
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { GKErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String {
        (userInfo[NSLocalizedDescriptionKey] as? String)
            ?? GameKitHost.unsupportedDescription
    }

    public static func == (lhs: GKError, rhs: GKError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public static let unknown = Code.unknown
    public static let cancelled = Code.cancelled
    public static let communicationsFailure = Code.communicationsFailure
    public static let userDenied = Code.userDenied
    public static let invalidCredentials = Code.invalidCredentials
    public static let notAuthenticated = Code.notAuthenticated
    public static let authenticationInProgress = Code.authenticationInProgress
    public static let invalidPlayer = Code.invalidPlayer
    public static let scoreNotSet = Code.scoreNotSet
    public static let parentalControlsBlocked = Code.parentalControlsBlocked
    public static let playerStatusExceedsMaximumLength = Code.playerStatusExceedsMaximumLength
    public static let playerStatusInvalid = Code.playerStatusInvalid
    public static let matchRequestInvalid = Code.matchRequestInvalid
    public static let underage = Code.underage
    public static let gameUnrecognized = Code.gameUnrecognized
    public static let notSupported = Code.notSupported
    public static let invalidParameter = Code.invalidParameter
    public static let unexpectedConnection = Code.unexpectedConnection
    public static let challengeInvalid = Code.challengeInvalid
    public static let turnBasedMatchDataTooLarge = Code.turnBasedMatchDataTooLarge
    public static let turnBasedTooManySessions = Code.turnBasedTooManySessions
    public static let turnBasedInvalidParticipant = Code.turnBasedInvalidParticipant
    public static let turnBasedInvalidTurn = Code.turnBasedInvalidTurn
    public static let turnBasedInvalidState = Code.turnBasedInvalidState
    public static let invitationsDisabled = Code.invitationsDisabled
    public static let playerPhotoFailure = Code.playerPhotoFailure
    public static let ubiquityContainerUnavailable = Code.ubiquityContainerUnavailable
    public static let matchNotConnected = Code.matchNotConnected
    public static let gameSessionRequestInvalid = Code.gameSessionRequestInvalid
    public static let restrictedToAutomatch = Code.restrictedToAutomatch
    public static let apiNotAvailable = Code.apiNotAvailable
    public static let notAuthorized = Code.notAuthorized
    public static let connectionTimeout = Code.connectionTimeout
    public static let apiObsolete = Code.apiObsolete
    public static let iCloudUnavailable = Code.iCloudUnavailable
    public static let lockdownMode = Code.lockdownMode
    public static let appUnlisted = Code.appUnlisted
    public static let debugMode = Code.debugMode
    public static let friendListDescriptionMissing = Code.friendListDescriptionMissing
    public static let friendListRestricted = Code.friendListRestricted
    public static let friendListDenied = Code.friendListDenied
    public static let friendRequestNotAvailable = Code.friendRequestNotAvailable
}

extension GKError.Code {
    public static func ~= (match: GKError.Code, error: any Error) -> Bool {
        (error as? GKError)?.code == match
    }
}

/// Portable counterpart of `NS_ERROR_ENUM(GKGameSessionErrorDomain, GKGameSessionErrorCode)`.
public struct GKGameSessionError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case notAuthenticated = 2
        case sessionConflict = 3
        case sessionNotShared = 4
        case connectionCancelledByUser = 5
        case connectionFailed = 6
        case sessionHasMaxConnectedPlayers = 7
        case sendDataNotConnected = 8
        case sendDataNoRecipients = 9
        case sendDataNotReachable = 10
        case sendRateLimitReached = 11
        case badContainer = 12
        case cloudQuotaExceeded = 13
        case networkFailure = 14
        case cloudDriveDisabled = 15
        case invalidSession = 16
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { GKGameSessionErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String {
        (userInfo[NSLocalizedDescriptionKey] as? String)
            ?? GameKitHost.unsupportedDescription
    }

    public static func == (lhs: GKGameSessionError, rhs: GKGameSessionError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static let unknown = Code.unknown
    public static let notAuthenticated = Code.notAuthenticated
    public static let sessionConflict = Code.sessionConflict
    public static let sessionNotShared = Code.sessionNotShared
    public static let connectionCancelledByUser = Code.connectionCancelledByUser
    public static let connectionFailed = Code.connectionFailed
    public static let sessionHasMaxConnectedPlayers = Code.sessionHasMaxConnectedPlayers
    public static let sendDataNotConnected = Code.sendDataNotConnected
    public static let sendDataNoRecipients = Code.sendDataNoRecipients
    public static let sendDataNotReachable = Code.sendDataNotReachable
    public static let sendRateLimitReached = Code.sendRateLimitReached
    public static let badContainer = Code.badContainer
    public static let cloudQuotaExceeded = Code.cloudQuotaExceeded
    public static let networkFailure = Code.networkFailure
    public static let cloudDriveDisabled = Code.cloudDriveDisabled
    public static let invalidSession = Code.invalidSession
}

extension GKGameSessionError.Code {
    public static func ~= (match: GKGameSessionError.Code, error: any Error) -> Bool {
        (error as? GKGameSessionError)?.code == match
    }
}
