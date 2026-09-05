import Foundation

open class GKBasePlayer: NSObject {
    public internal(set) var displayName: String?
    public internal(set) var playerID: String?

    public override init() {
        super.init()
    }
}

open class GKPlayer: GKBasePlayer {
    public enum PhotoSize: Int, Hashable, Sendable {
        case small = 0
        case normal = 1
    }

    public internal(set) var alias: String = ""
    public internal(set) var gamePlayerID: String = ""
    public internal(set) var teamPlayerID: String = ""
    public internal(set) var guestIdentifier: String?
    public internal(set) var isFriend: Bool = false
    public internal(set) var isInvitable: Bool = false

    public override init() {
        super.init()
        self.playerID = ""
        self.displayName = ""
    }

    public required init(guestIdentifier: String) {
        super.init()
        self.guestIdentifier = guestIdentifier
        self.playerID = guestIdentifier
        self.alias = guestIdentifier
        self.displayName = guestIdentifier
        self.gamePlayerID = guestIdentifier
        self.teamPlayerID = guestIdentifier
    }

    public class func anonymousGuestPlayer(withIdentifier guestIdentifier: String) -> Self {
        Self.init(guestIdentifier: guestIdentifier)
    }

    public class func loadPlayers(
        forIdentifiers identifiers: [String],
        withCompletionHandler completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func scopedIDsArePersistent() -> Bool {
        guestIdentifier == nil && !(playerID?.isEmpty ?? true)
    }
}

open class GKLocalPlayer: GKPlayer {
    public static let local = GKLocalPlayer()

    public private(set) var isAuthenticated: Bool = false
    public private(set) var isUnderage: Bool = false
    public private(set) var isMultiplayerGamingRestricted: Bool = true
    public private(set) var isPersonalizedCommunicationRestricted: Bool = true
    public private(set) var isPresentingFriendRequestViewController: Bool = false
    public private(set) var friends: [String]?

    private var listeners: [ObjectIdentifier: any GKLocalPlayerListener] = [:]

    public func register(_ listener: any GKLocalPlayerListener) {
        listeners[ObjectIdentifier(listener as AnyObject)] = listener
    }

    public func unregisterListener(_ listener: any GKLocalPlayerListener) {
        listeners.removeValue(forKey: ObjectIdentifier(listener as AnyObject))
    }

    public func unregisterAllListeners() {
        listeners.removeAll()
    }

    public func fetchItems(
        forIdentityVerificationSignature completionHandler: ((URL?, Data?, Data?, UInt64, (any Error)?) -> Void)? = nil
    ) {
        completionHandler?(nil, nil, nil, 0, GameKitHost.unsupportedError())
    }

    public func generateIdentityVerificationSignature(
        completionHandler: ((URL?, Data?, Data?, UInt64, (any Error)?) -> Void)? = nil
    ) {
        completionHandler?(nil, nil, nil, 0, GameKitHost.unsupportedError())
    }

    public func fetchSavedGames(
        completionHandler handler: (([GKSavedGame]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(handler)
    }

    public func loadChallengableFriends(
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadDefaultLeaderboardIdentifier(
        completionHandler: ((String?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadFriendPlayers(
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadFriends(_ completionHandler: @escaping ([GKPlayer]?, (any Error)?) -> Void) {
        GameKitHost.fail(completionHandler)
    }

    public func loadFriendsAuthorizationStatus(
        _ completionHandler: @escaping (GKFriendsAuthorizationStatus, (any Error)?) -> Void
    ) {
        completionHandler(.notDetermined, GameKitHost.unsupportedError())
    }

    public func loadFriendsObsoleted(
        completionHandler: (([String]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadRecentPlayers(
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func deleteSavedGames(withName name: String) async throws {
        _ = name
        throw GameKitHost.unsupportedError(.iCloudUnavailable)
    }

    public func loadFriends(identifiedBy identifiers: [String]) async throws -> [GKPlayer] {
        _ = identifiers
        throw GameKitHost.unsupportedError()
    }

    public func resolveConflictingSavedGames(
        _ conflictingSavedGames: [GKSavedGame],
        with data: Data
    ) async throws -> [GKSavedGame] {
        _ = conflictingSavedGames
        _ = data
        throw GameKitHost.unsupportedError(.iCloudUnavailable)
    }

    public func saveGameData(_ data: Data, withName name: String) async throws -> GKSavedGame {
        _ = data
        _ = name
        throw GameKitHost.unsupportedError(.iCloudUnavailable)
    }

    public func setDefaultLeaderboardIdentifier(_ leaderboardIdentifier: String) async throws {
        _ = leaderboardIdentifier
        throw GameKitHost.unsupportedError()
    }
}

open class GKCloudPlayer: GKBasePlayer {
    public class func currentSignedInPlayer(forContainer containerName: String?) async throws -> GKCloudPlayer {
        _ = containerName
        throw GameKitHost.sessionError()
    }
}
