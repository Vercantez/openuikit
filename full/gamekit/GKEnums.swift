import Foundation

public enum GKChallengeState: Int, Hashable, Sendable {
    case invalid = 0
    case pending = 1
    case completed = 2
    case declined = 3
}

public enum GKConnectionState: Int, Hashable, Sendable {
    case notConnected = 0
    case connected = 1
}

public enum GKFriendsAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
}

public enum GKGameActivityPlayStyle: Int, Hashable, Sendable {
    case unspecified = 0
    case synchronous = 1
    case asynchronous = 2
}

public enum GKGameCenterViewControllerState: Int, Hashable, Sendable {
    case `default` = -1
    case leaderboards = 0
    case achievements = 1
    case challenges = 2
    case localPlayerProfile = 3
    case dashboard = 4
    case localPlayerFriendsList = 5
}

public enum GKInviteRecipientResponse: Int, Hashable, Sendable {
    case accepted = 0
    case declined = 1
    case failed = 2
    case incompatible = 3
    case unableToConnect = 4
    case noAnswer = 5

    public static var inviteeResponseAccepted: GKInviteRecipientResponse { .accepted }
    public static var inviteeResponseDeclined: GKInviteRecipientResponse { .declined }
    public static var inviteeResponseFailed: GKInviteRecipientResponse { .failed }
    public static var inviteeResponseIncompatible: GKInviteRecipientResponse { .incompatible }
    public static var inviteeResponseUnableToConnect: GKInviteRecipientResponse { .unableToConnect }
    public static var inviteeResponseNoAnswer: GKInviteRecipientResponse { .noAnswer }
}

public typealias GKInviteeResponse = GKInviteRecipientResponse

public enum GKMatchType: UInt, Hashable, Sendable {
    case peerToPeer = 0
    case hosted = 1
    case turnBased = 2
}

public enum GKMatchmakingMode: Int, Hashable, Sendable {
    case `default` = 0
    case nearbyOnly = 1
    case automatchOnly = 2
    case inviteOnly = 3
}

public enum GKPlayerConnectionState: Int, Hashable, Sendable {
    case unknown = 0
    case connected = 1
    case disconnected = 2
}

public enum GKTransportType: Int, Hashable, Sendable {
    case unreliable = 0
    case reliable = 1
}

public enum GKTurnBasedExchangeStatus: Int8, Hashable, Sendable {
    case unknown = 0
    case active = 1
    case complete = 2
    case resolved = 3
    case canceled = 4
}

/// Imported as an option set in the Swift overlay. Named cases match the
/// public `GKReleaseState` cases (`released` = 1, `prereleased` = 2).
public struct GKReleaseState: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let released = GKReleaseState(rawValue: 1)
    public static let prereleased = GKReleaseState(rawValue: 2)
}
