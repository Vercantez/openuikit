import Foundation

open class GKAchievement: NSObject, NSSecureCoding {
    public var identifier: String
    public var percentComplete: Double = 0 {
        didSet { if percentComplete < 0 { percentComplete = 0 } }
    }
    public var showsCompletionBanner: Bool = true
    public private(set) var lastReportedDate: Date = Date.distantPast
    public private(set) var player: GKPlayer
    public var playerID: String? { player.playerID }

    public var isCompleted: Bool { percentComplete >= 100 }

    public init(identifier: String) {
        self.identifier = identifier
        self.player = GKLocalPlayer.local
        super.init()
    }

    public init(identifier: String, player: GKPlayer) {
        self.identifier = identifier
        self.player = player
        super.init()
    }

    public init?(identifier: String?, forPlayer playerID: String) {
        guard let identifier, !identifier.isEmpty, !playerID.isEmpty else { return nil }
        self.identifier = identifier
        let player = GKPlayer()
        player.playerID = playerID
        self.player = player
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? else {
            return nil
        }
        self.identifier = identifier
        self.percentComplete = coder.decodeDouble(forKey: "percentComplete")
        self.showsCompletionBanner = coder.decodeBool(forKey: "showsCompletionBanner")
        self.player = GKLocalPlayer.local
        super.init()
        if let reported = coder.decodeObject(of: NSDate.self, forKey: "lastReportedDate") as Date? {
            lastReportedDate = reported
        }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(percentComplete, forKey: "percentComplete")
        coder.encode(showsCompletionBanner, forKey: "showsCompletionBanner")
        coder.encode(lastReportedDate as NSDate, forKey: "lastReportedDate")
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? GKAchievement else { return false }
        return identifier == other.identifier && player.playerID == other.player.playerID
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        hasher.combine(player.playerID)
        return hasher.finalize()
    }

    public class func loadAchievements(
        completionHandler: (([GKAchievement]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public class func resetAchievements(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public class func report(_ achievements: [GKAchievement]) async throws {
        _ = achievements
        throw GameKitHost.unsupportedError()
    }

    public class func report(
        _ achievements: [GKAchievement],
        withEligibleChallenges challenges: [GKChallenge]
    ) async throws {
        _ = achievements
        _ = challenges
        throw GameKitHost.unsupportedError()
    }

    public func selectChallengeablePlayerIDs(
        _ playerIDs: [String]?,
        withCompletionHandler completionHandler: (([String]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func selectChallengeablePlayers(_ players: [GKPlayer]) async throws -> [GKPlayer] {
        _ = players
        throw GameKitHost.unsupportedError()
    }
}

open class GKAchievementDescription: NSObject, NSSecureCoding {
    public internal(set) var identifier: String = ""
    public internal(set) var title: String = ""
    public internal(set) var achievedDescription: String = ""
    public internal(set) var unachievedDescription: String = ""
    public internal(set) var groupIdentifier: String?
    public internal(set) var maximumPoints: Int = 0
    public internal(set) var isHidden: Bool = false
    public internal(set) var isReplayable: Bool = false
    public internal(set) var activityIdentifier: String = ""
    public internal(set) var activityProperties: [String: String] = [:]
    public internal(set) var releaseState: GKReleaseState = []
    public internal(set) var rarityPercent: Double?

    public override init() { super.init() }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        identifier = (coder.decodeObject(of: NSString.self, forKey: "identifier") as String?) ?? ""
        title = (coder.decodeObject(of: NSString.self, forKey: "title") as String?) ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(title as NSString, forKey: "title")
    }

    public class func loadAchievementDescriptions(
        completionHandler: (([GKAchievementDescription]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }
}

open class GKChallenge: NSObject, NSSecureCoding {
    public internal(set) var state: GKChallengeState = .invalid
    public internal(set) var issueDate: Date = Date()
    public internal(set) var completionDate: Date?
    public internal(set) var issuingPlayer: GKPlayer?
    public internal(set) var receivingPlayer: GKPlayer?
    public var issuingPlayerID: String? { issuingPlayer?.playerID }
    public var receivingPlayerID: String? { receivingPlayer?.playerID }
    public internal(set) var message: String?

    public override init() { super.init() }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        super.init()
        if let raw = coder.decodeObject(of: NSNumber.self, forKey: "state") {
            state = GKChallengeState(rawValue: raw.intValue) ?? .invalid
        }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: state.rawValue), forKey: "state")
    }

    public class func loadReceivedChallenges(
        completionHandler: (([GKChallenge]?, (any Error)?) -> Void)? = nil
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func decline() {
        state = .declined
    }
}

open class GKAchievementChallenge: GKChallenge {
    public internal(set) var achievement: GKAchievement?
}

open class GKScoreChallenge: GKChallenge {
    public internal(set) var score: GKScore?
    public internal(set) var leaderboardEntry: GKLeaderboard.Entry?
}

open class GKChallengeDefinition: NSObject {
    public internal(set) var identifier: String = ""
    public internal(set) var title: String = ""
    public internal(set) var details: String?
    public internal(set) var groupIdentifier: String?
    public internal(set) var durationOptions: [DateComponents] = []
    public internal(set) var isRepeatable: Bool = false
    public internal(set) var leaderboard: GKLeaderboard?
    public internal(set) var releaseState: GKReleaseState = []

    public class func loadChallengeDefinitions(
        completionHandler: @escaping ([GKChallengeDefinition]?, (any Error)?) -> Void
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func hasActiveChallenges(completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        completionHandler(false, GameKitHost.unsupportedError())
    }
}
