import Foundation

open class GKGameCenterViewController: NSObject {
    public weak var gameCenterDelegate: (any GKGameCenterControllerDelegate)?
    public var leaderboardIdentifier: String?
    public var leaderboardTimeScope: GKLeaderboard.TimeScope = .allTime
    public var viewState: GKGameCenterViewControllerState = .default

    public override init() { super.init() }

    public init(achievementID: String) {
        self.viewState = .achievements
        super.init()
        _ = achievementID
    }

    public init(leaderboard: GKLeaderboard, playerScope: GKLeaderboard.PlayerScope) {
        self.viewState = .leaderboards
        self.leaderboardIdentifier = leaderboard.identifier
        super.init()
        _ = playerScope
    }

    public init(
        leaderboardID: String,
        playerScope: GKLeaderboard.PlayerScope,
        timeScope: GKLeaderboard.TimeScope
    ) {
        self.viewState = .leaderboards
        self.leaderboardIdentifier = leaderboardID
        self.leaderboardTimeScope = timeScope
        super.init()
        _ = playerScope
    }

    public init(leaderboardSetID: String) {
        self.viewState = .leaderboards
        super.init()
        _ = leaderboardSetID
    }

    public init(player: GKPlayer) {
        self.viewState = .localPlayerProfile
        super.init()
        _ = player
    }

    public init(state: GKGameCenterViewControllerState) {
        self.viewState = state
        super.init()
    }
}

open class GKMatchmakerViewController: NSObject {
    public weak var matchmakerDelegate: (any GKMatchmakerViewControllerDelegate)?
    public var canStartWithMinimumPlayers: Bool = false
    public var isHosted: Bool = false
    public private(set) var matchRequest: GKMatchRequest
    public var matchmakingMode: GKMatchmakingMode = .default
    private var hostedConnections: [String: Bool] = [:]

    public init?(invite: GKInvite) {
        self.matchRequest = GKMatchRequest()
        super.init()
        _ = invite
    }

    public init?(matchRequest request: GKMatchRequest) {
        guard request.minPlayers >= 2, request.maxPlayers >= request.minPlayers else { return nil }
        self.matchRequest = request
        super.init()
    }

    public func addPlayers(to match: GKMatch) {
        _ = match
    }

    public func setHostedPlayer(_ playerID: String, connected: Bool) {
        hostedConnections[playerID] = connected
    }

    public func setHostedPlayer(_ player: GKPlayer, didConnect connected: Bool) {
        if let id = player.playerID {
            hostedConnections[id] = connected
        }
    }

    public func isHostedPlayerConnected(_ playerID: String) -> Bool {
        hostedConnections[playerID] ?? false
    }
}

open class GKTurnBasedMatchmakerViewController: NSObject {
    public var matchmakingMode: GKMatchmakingMode = .default
    public var showExistingMatches: Bool = true
    public weak var turnBasedMatchmakerDelegate: (any GKTurnBasedMatchmakerViewControllerDelegate)?
    public private(set) var matchRequest: GKMatchRequest

    public init(matchRequest request: GKMatchRequest) {
        self.matchRequest = request
        super.init()
    }
}

open class GKFriendRequestComposeViewController: NSObject {
    public weak var composeViewDelegate: (any GKFriendRequestComposeViewControllerDelegate)?
    public private(set) var recipientPlayers: [GKPlayer] = []
    public private(set) var recipientEmails: [String] = []
    public private(set) var recipientPlayerIDs: [String] = []
    public private(set) var message: String?

    public class func maxNumberOfRecipients() -> Int { 8 }

    public func addRecipientPlayers(_ players: [GKPlayer]) {
        let remaining = Self.maxNumberOfRecipients() - recipientCount
        recipientPlayers.append(contentsOf: players.prefix(max(0, remaining)))
    }

    public func addRecipients(withEmailAddresses emailAddresses: [String]) {
        let remaining = Self.maxNumberOfRecipients() - recipientCount
        recipientEmails.append(contentsOf: emailAddresses.prefix(max(0, remaining)))
    }

    public func addRecipients(withPlayerIDs playerIDs: [String]) {
        let remaining = Self.maxNumberOfRecipients() - recipientCount
        recipientPlayerIDs.append(contentsOf: playerIDs.prefix(max(0, remaining)))
    }

    public func setMessage(_ message: String?) {
        self.message = message
    }

    public var recipientCount: Int {
        recipientPlayers.count + recipientEmails.count + recipientPlayerIDs.count
    }
}

open class GKNotificationBanner: NSObject {
    public private(set) static var portableShowCount = 0

    public class func show(withTitle title: String?, message: String?) async {
        _ = (title, message)
        portableShowCount += 1
    }

    public class func show(withTitle title: String?, message: String?, duration: TimeInterval) async {
        _ = (title, message, duration)
        portableShowCount += 1
    }
}
