import Foundation

open class GKLeaderboard: NSObject {
    public enum PlayerScope: Int, Hashable, Sendable {
        case global = 0
        case friendsOnly = 1
    }

    public enum TimeScope: Int, Hashable, Sendable {
        case today = 0
        case week = 1
        case allTime = 2
    }

    public enum LeaderboardType: Int, Hashable, Sendable {
        case classic = 0
        case recurring = 1
    }

    open class Entry: NSObject {
        public internal(set) var context: Int = 0
        public internal(set) var date: Date = Date()
        public internal(set) var formattedScore: String = "0"
        public internal(set) var player: GKPlayer = GKPlayer()
        public internal(set) var rank: Int = 0
        public internal(set) var score: Int = 0
    }

    public var identifier: String?
    public var playerScope: PlayerScope = .global
    public var timeScope: TimeScope = .allTime
    public var range: NSRange = NSRange(location: 1, length: 25)
    public internal(set) var title: String?
    public internal(set) var groupIdentifier: String?
    public internal(set) var isHidden: Bool = false
    public internal(set) var isLoading: Bool = false
    public internal(set) var maxRange: Int = 0
    public internal(set) var scores: [GKScore]?
    public internal(set) var localPlayerScore: GKScore?
    public internal(set) var leaderboardDescription: String = ""
    public internal(set) var baseLeaderboardID: String = ""
    public internal(set) var type: LeaderboardType = .classic
    public internal(set) var startDate: Date?
    public internal(set) var nextStartDate: Date?
    public internal(set) var duration: TimeInterval = 0
    public internal(set) var activityIdentifier: String = ""
    public internal(set) var activityProperties: [String: String] = [:]
    public internal(set) var releaseState: GKReleaseState = []

    public override init() { super.init() }

    public init(players: [GKPlayer]) {
        _ = players
        super.init()
    }

    public init?(playerIDs: [String]?) {
        guard let playerIDs, !playerIDs.isEmpty else { return nil }
        super.init()
    }

    public class func loadLeaderboards(
        completionHandler: (([GKLeaderboard]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public class func loadLeaderboards(IDs leaderboardIDs: [String]?) async throws -> [GKLeaderboard] {
        _ = leaderboardIDs
        throw GameKitHost.unsupportedError()
    }

    public class func submitScore(
        _ score: Int,
        context: Int,
        player: GKPlayer,
        leaderboardIDs: [String]
    ) async throws {
        _ = (score, context, player, leaderboardIDs)
        throw GameKitHost.unsupportedError()
    }

    public func loadPreviousOccurrence(completionHandler: @escaping (GKLeaderboard?, (any Error)?) -> Void) {
        GameKitHost.fail(completionHandler)
    }

    public func loadScores(completionHandler: (([GKScore]?, (any Error)?) -> Void)? = nil) {
        isLoading = false
        GameKitHost.fail(completionHandler)
    }

    public func loadEntries(
        for playerScope: PlayerScope,
        timeScope: TimeScope,
        range: NSRange
    ) async throws -> (GKLeaderboard.Entry?, [GKLeaderboard.Entry], Int) {
        _ = (playerScope, timeScope, range)
        throw GameKitHost.unsupportedError()
    }

    public func loadEntries(
        for players: [GKPlayer],
        timeScope: TimeScope
    ) async throws -> (GKLeaderboard.Entry?, [GKLeaderboard.Entry]) {
        _ = (players, timeScope)
        throw GameKitHost.unsupportedError()
    }

    public func submitScore(_ score: Int, context: Int, player: GKPlayer) async throws {
        _ = (score, context, player)
        throw GameKitHost.unsupportedError()
    }
}

open class GKLeaderboardScore: NSObject {
    public var context: Int = 0
    public var leaderboardID: String = ""
    public var player: GKPlayer = GKPlayer()
    public var value: Int = 0
}

open class GKLeaderboardSet: NSObject, NSSecureCoding {
    public var identifier: String?
    public internal(set) var title: String = ""
    public internal(set) var groupIdentifier: String?

    public override init() { super.init() }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?
        title = (coder.decodeObject(of: NSString.self, forKey: "title") as String?) ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(title as NSString, forKey: "title")
    }

    public class func loadLeaderboardSets(
        completionHandler: (([GKLeaderboardSet]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadLeaderboards(completionHandler: (([GKLeaderboard]?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func loadLeaderboards(handler: @escaping ([GKLeaderboard]?, (any Error)?) -> Void) {
        GameKitHost.fail(handler)
    }
}

open class GKScore: NSObject, NSSecureCoding {
    public var leaderboardIdentifier: String
    public var value: Int64 = 0 {
        didSet { formattedValue = String(value) }
    }
    public var context: UInt64 = 0
    public var shouldSetDefaultLeaderboard: Bool = false
    public private(set) var date: Date = Date()
    public private(set) var formattedValue: String? = "0"
    public private(set) var rank: Int = 0
    public private(set) var player: GKPlayer
    public var playerID: String? { player.playerID }

    public init(leaderboardIdentifier identifier: String) {
        self.leaderboardIdentifier = identifier
        self.player = GKLocalPlayer.local
        super.init()
    }

    public init(leaderboardIdentifier identifier: String, player: GKPlayer) {
        self.leaderboardIdentifier = identifier
        self.player = player
        super.init()
    }

    public init?(leaderboardIdentifier identifier: String, forPlayer playerID: String) {
        guard !identifier.isEmpty, !playerID.isEmpty else { return nil }
        self.leaderboardIdentifier = identifier
        let player = GKPlayer()
        player.playerID = playerID
        self.player = player
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "leaderboardIdentifier") as String? else {
            return nil
        }
        leaderboardIdentifier = identifier
        value = coder.decodeInt64(forKey: "value")
        context = UInt64(bitPattern: coder.decodeInt64(forKey: "context"))
        player = GKLocalPlayer.local
        super.init()
        formattedValue = String(value)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(leaderboardIdentifier as NSString, forKey: "leaderboardIdentifier")
        coder.encode(value, forKey: "value")
        coder.encode(Int64(bitPattern: context), forKey: "context")
    }

    public class func report(_ scores: [GKScore]) async throws {
        _ = scores
        throw GameKitHost.unsupportedError()
    }

    public class func report(_ scores: [GKLeaderboardScore], withEligibleChallenges challenges: [GKChallenge]) async throws {
        _ = scores
        _ = challenges
        throw GameKitHost.unsupportedError()
    }

    public class func report(_ scores: [GKScore], withEligibleChallenges challenges: [GKChallenge]) async throws {
        _ = scores
        _ = challenges
        throw GameKitHost.unsupportedError()
    }
}
