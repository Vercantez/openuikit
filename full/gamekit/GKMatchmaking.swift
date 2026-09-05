import Foundation

open class GKMatchRequest: NSObject {
    public var minPlayers: Int = 2
    public var maxPlayers: Int = 4
    public var defaultNumberOfPlayers: Int = 2
    public var playerGroup: Int = 0
    public var playerAttributes: UInt32 = 0
    public var inviteMessage: String?
    public var playersToInvite: [String]?
    public var recipients: [GKPlayer]?
    public var properties: [String: Any]?
    public var recipientProperties: [GKPlayer: [String: Any]]?
    public var queueName: String?
    public var restrictToAutomatch: Bool = false
    public var inviteeResponseHandler: ((String, GKInviteeResponse) -> Void)?
    public var recipientResponseHandler: ((GKPlayer, GKInviteRecipientResponse) -> Void)?

    public class func maxPlayersAllowedForMatch(of matchType: GKMatchType) -> Int {
        switch matchType {
        case .peerToPeer: return 4
        case .hosted, .turnBased: return 16
        }
    }
}

open class GKInvite: NSObject {
    public internal(set) var isHosted: Bool = false
    public internal(set) var inviter: String = ""
    public internal(set) var playerAttributes: UInt32 = 0
    public internal(set) var playerGroup: Int = 0
    public internal(set) var sender: GKPlayer = GKPlayer()
}

open class GKMatchedPlayers: NSObject {
    public internal(set) var players: [GKPlayer] = []
    public internal(set) var properties: [String: Any]?
    public internal(set) var playerProperties: [GKPlayer: [String: Any]]?
}

open class GKMatch: NSObject {
    public enum SendDataMode: Int, Hashable, Sendable {
        case reliable = 0
        case unreliable = 1
    }

    public weak var delegate: (any GKMatchDelegate)?
    public internal(set) var expectedPlayerCount: Int = 0
    public internal(set) var players: [GKPlayer] = []
    public var playerIDs: [String]? { players.compactMap(\.playerID) }
    public internal(set) var properties: [String: Any]?
    public internal(set) var playerProperties: [GKPlayer: [String: Any]]?
    private var disconnected = false

    public func disconnect() {
        disconnected = true
        expectedPlayerCount = 0
        players.removeAll()
    }

    public func chooseBestHostPlayer(completionHandler: @escaping (String?) -> Void) {
        completionHandler(nil)
    }

    public func chooseBestHostingPlayer(completionHandler: @escaping (GKPlayer?) -> Void) {
        completionHandler(nil)
    }

    public func rematch(completionHandler: ((GKMatch?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func send(_ data: Data, to players: [GKPlayer], dataMode mode: SendDataMode) throws {
        _ = (data, players, mode)
        throw GameKitHost.unsupportedError(.matchNotConnected)
    }

    public func send(_ data: Data, toPlayers playerIDs: [String], with mode: SendDataMode) throws {
        _ = (data, playerIDs, mode)
        throw GameKitHost.unsupportedError(.matchNotConnected)
    }

    public func sendData(toAllPlayers data: Data, with mode: SendDataMode) throws {
        _ = (data, mode)
        throw GameKitHost.unsupportedError(.matchNotConnected)
    }

    public func voiceChat(withName name: String) -> GKVoiceChat? {
        disconnected ? nil : GKVoiceChat(name: name)
    }
}

open class GKMatchmaker: NSObject {
    public static let sharedInstance = GKMatchmaker()
    public class func shared() -> GKMatchmaker { sharedInstance }

    private var browsing = false
    private var groupActivity = false

    public func cancel() {
        browsing = false
        groupActivity = false
    }

    public func cancelInvite(toPlayer playerID: String) {
        _ = playerID
    }

    public func cancelPendingInvite(to player: GKPlayer) {
        _ = player
    }

    public func finishMatchmaking(for match: GKMatch) {
        _ = match
    }

    public func startBrowsingForNearbyPlayers(handler reachableHandler: ((GKPlayer, Bool) -> Void)? = nil) {
        browsing = true
        _ = reachableHandler
    }

    public func startBrowsingForNearbyPlayers(reachableHandler: ((String, Bool) -> Void)? = nil) {
        browsing = true
        _ = reachableHandler
    }

    public func stopBrowsingForNearbyPlayers() {
        browsing = false
    }

    public func startGroupActivity(playerHandler handler: @escaping (GKPlayer) -> Void) {
        groupActivity = true
        _ = handler
    }

    public func stopGroupActivity() {
        groupActivity = false
    }

    public var isBrowsingForNearbyPlayers: Bool { browsing }
    public var isGroupActivityActive: Bool { groupActivity }

    public func queryActivity(completionHandler: ((Int, (any Error)?) -> Void)? = nil) {
        completionHandler?(0, GameKitHost.unsupportedError())
    }

    public func findPlayers(
        forHostedMatchRequest request: GKMatchRequest,
        withCompletionHandler completionHandler: (([String]?, (any Error)?) -> Void)? = nil
    ) {
        _ = request
        GameKitHost.fail(completionHandler)
    }

    public func addPlayers(to match: GKMatch, matchRequest: GKMatchRequest) async throws {
        _ = (match, matchRequest)
        throw GameKitHost.unsupportedError()
    }

    public func findMatch(for request: GKMatchRequest) async throws -> GKMatch {
        _ = request
        throw GameKitHost.unsupportedError()
    }

    public func findMatchedPlayers(_ request: GKMatchRequest) async throws -> GKMatchedPlayers {
        _ = request
        throw GameKitHost.unsupportedError()
    }

    public func findPlayers(forHostedRequest request: GKMatchRequest) async throws -> [GKPlayer] {
        _ = request
        throw GameKitHost.unsupportedError()
    }

    public func match(for invite: GKInvite) async throws -> GKMatch {
        _ = invite
        throw GameKitHost.unsupportedError()
    }

    public func queryPlayerGroupActivity(_ playerGroup: Int) async throws -> Int {
        _ = playerGroup
        throw GameKitHost.unsupportedError()
    }

    public func queryQueueActivity(_ queueName: String) async throws -> Int {
        _ = queueName
        throw GameKitHost.unsupportedError()
    }
}

open class GKVoiceChat: NSObject {
    public enum PlayerState: Int, Hashable, Sendable {
        case connected = 0
        case disconnected = 1
        case speaking = 2
        case silent = 3
        case connecting = 4
    }

    public var isActive: Bool = false
    public var volume: Float = 1
    public internal(set) var name: String
    public internal(set) var players: [GKPlayer] = []
    public var playerIDs: [String]? { players.compactMap(\.playerID) }
    public var playerStateUpdateHandler: (String, PlayerState) -> Void = { _, _ in }
    public var playerVoiceChatStateDidChangeHandler: (GKPlayer, PlayerState) -> Void = { _, _ in }
    private var muted: [String: Bool] = [:]

    public init(name: String) {
        self.name = name
        super.init()
    }

    public class func isVoIPAllowed() -> Bool { false }

    public func start() {
        isActive = false
    }

    public func stop() {
        isActive = false
    }

    public func setMute(_ isMuted: Bool, forPlayer playerID: String) {
        muted[playerID] = isMuted
    }

    public func setPlayer(_ player: GKPlayer, muted isMuted: Bool) {
        if let id = player.playerID {
            muted[id] = isMuted
        }
    }

    public func isPlayerMuted(_ playerID: String) -> Bool {
        muted[playerID] ?? false
    }
}
