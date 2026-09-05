import Foundation

open class GKGameActivityDefinition: NSObject {
    public var identifier: String = ""
    public var title: String = ""
    public var details: String?
    public var groupIdentifier: String?
    public var defaultProperties: [String: String] = [:]
    public var fallbackURL: URL?
    public var supportsPartyCode: Bool = false
    public var supportsUnlimitedPlayers: Bool = false
    public var playStyle: GKGameActivityPlayStyle = .unspecified
    public var releaseState: GKReleaseState = []
    public var minimumPlayers: Int?
    public var maximumPlayers: Int?

    public var playerRange: (any RangeExpression)? {
        guard let minimumPlayers, let maximumPlayers else { return nil }
        return minimumPlayers...maximumPlayers
    }

    public class func loadGameActivityDefinitions(
        completionHandler: @escaping ([GKGameActivityDefinition]?, (any Error)?) -> Void
    ) {
        GameKitHost.fail(completionHandler)
    }

    public class func loadGameActivityDefinitions(IDs activityDefinitionIDs: [String]?) async throws -> [GKGameActivityDefinition] {
        _ = activityDefinitionIDs
        throw GameKitHost.unsupportedError()
    }

    public func loadAchievementDescriptions(
        completionHandler: @escaping ([GKAchievementDescription]?, (any Error)?) -> Void
    ) {
        GameKitHost.fail(completionHandler)
    }

    public func loadLeaderboards(completionHandler: @escaping ([GKLeaderboard]?, (any Error)?) -> Void) {
        GameKitHost.fail(completionHandler)
    }
}

open class GKGameActivity: NSObject {
    public enum State: UInt, Hashable, Sendable {
        case initialized = 0
        case active = 1
        case paused = 2
        case ended = 4
    }

    public private(set) var identifier: String
    public private(set) var activityDefinition: GKGameActivityDefinition
    public var properties: [String: String] = [:]
    public private(set) var state: State = .initialized
    public private(set) var partyCode: String?
    public private(set) var partyURL: URL?
    public private(set) var creationDate: Date
    public private(set) var startDate: Date?
    public private(set) var lastResumeDate: Date?
    public private(set) var endDate: Date?
    public private(set) var achievements: Set<GKAchievement> = []
    public private(set) var leaderboardScores: Set<GKLeaderboardScore> = []

    private var accumulatedActive: TimeInterval = 0
    private var lastActiveMark: Date?

    public var duration: TimeInterval {
        var total = accumulatedActive
        if state == .active, let lastActiveMark {
            total += Date().timeIntervalSince(lastActiveMark)
        }
        return total
    }

    public init(definition activityDefinition: GKGameActivityDefinition) {
        self.activityDefinition = activityDefinition
        self.identifier = UUID().uuidString
        self.creationDate = Date()
        self.properties = activityDefinition.defaultProperties
        super.init()
    }

    public class var validPartyCodeAlphabet: [String] { [] }

    public class func isValidPartyCode(_ partyCode: String) -> Bool {
        _ = partyCode
        return false
    }

    public class func start(definition activityDefinition: GKGameActivityDefinition) throws -> GKGameActivity {
        let activity = GKGameActivity(definition: activityDefinition)
        activity.start()
        return activity
    }

    public class func start(
        definition activityDefinition: GKGameActivityDefinition,
        partyCode: String
    ) throws -> GKGameActivity {
        _ = partyCode
        throw GameKitHost.unsupportedError(.invalidParameter)
    }

    public class func checkPendingGameActivityExistence(
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(false)
    }

    public func start() {
        guard state == .initialized || state == .paused else { return }
        let now = Date()
        if startDate == nil {
            startDate = now
        }
        lastResumeDate = now
        lastActiveMark = now
        state = .active
    }

    public func pause() {
        guard state == .active else { return }
        if let lastActiveMark {
            accumulatedActive += Date().timeIntervalSince(lastActiveMark)
        }
        lastActiveMark = nil
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        start()
    }

    public func end() {
        guard state != .ended else { return }
        if state == .active, let lastActiveMark {
            accumulatedActive += Date().timeIntervalSince(lastActiveMark)
        }
        lastActiveMark = nil
        endDate = Date()
        state = .ended
    }

    public func setProgress(on achievement: GKAchievement, to percentComplete: Double) {
        achievement.percentComplete = percentComplete
        achievements.insert(achievement)
    }

    public func setAchievementCompleted(_ achievement: GKAchievement) {
        achievement.percentComplete = 100
        achievements.insert(achievement)
    }

    public func progress(on achievement: GKAchievement) -> Double {
        achievements.first(where: { $0.identifier == achievement.identifier })?.percentComplete
            ?? achievement.percentComplete
    }

    public func removeAchievements(_ achievements: [GKAchievement]) {
        let ids = Set(achievements.map(\.identifier))
        self.achievements = self.achievements.filter { !ids.contains($0.identifier) }
    }

    public func setScore(on leaderboard: GKLeaderboard, to score: Int) {
        setScore(on: leaderboard, to: score, context: 0)
    }

    public func setScore(on leaderboard: GKLeaderboard, to score: Int, context: Int) {
        let entry = GKLeaderboardScore()
        entry.leaderboardID = leaderboard.identifier ?? leaderboard.baseLeaderboardID
        entry.value = score
        entry.context = context
        entry.player = GKLocalPlayer.local
        leaderboardScores = leaderboardScores.filter { $0.leaderboardID != entry.leaderboardID }
        leaderboardScores.insert(entry)
    }

    public func score(on leaderboard: GKLeaderboard) -> GKLeaderboardScore? {
        let key = leaderboard.identifier ?? leaderboard.baseLeaderboardID
        return leaderboardScores.first { $0.leaderboardID == key }
    }

    public func removeScores(from leaderboards: [GKLeaderboard]) {
        let ids = Set(leaderboards.map { $0.identifier ?? $0.baseLeaderboardID })
        leaderboardScores = leaderboardScores.filter { !ids.contains($0.leaderboardID) }
    }

    public func makeMatchRequest() -> GKMatchRequest? {
        guard let min = activityDefinition.minimumPlayers,
              let max = activityDefinition.maximumPlayers,
              min > 0, max >= min
        else { return nil }
        let request = GKMatchRequest()
        request.minPlayers = min
        request.maxPlayers = max
        request.defaultNumberOfPlayers = min
        return request
    }

    public func findMatch(completionHandler: @escaping (GKMatch?, (any Error)?) -> Void) {
        GameKitHost.fail(completionHandler)
    }

    public func findPlayersForHostedMatch(completionHandler: @escaping ([GKPlayer]?, (any Error)?) -> Void) {
        GameKitHost.fail(completionHandler)
    }
}

open class GKAccessPoint: NSObject {
    public enum Location: Int, Hashable, Sendable {
        case topLeading = 0
        case topTrailing = 1
        case bottomLeading = 2
        case bottomTrailing = 3
    }

    public static let shared = GKAccessPoint()

    public var isActive: Bool = false
    public var location: Location = .topLeading
    public var showHighlights: Bool = false
    public private(set) var isPresentingGameCenter: Bool = false
    public var isVisible: Bool { false }
    public var frameInScreenCoordinates: CGRect { .zero }

    public func trigger(handler: @escaping () -> Void) {
        _ = handler
        isPresentingGameCenter = false
    }

    public func trigger(state: GKGameCenterViewControllerState, handler: @escaping () -> Void) {
        _ = state
        _ = handler
        isPresentingGameCenter = false
    }

    public func trigger(gameActivity: GKGameActivity, handler: (() -> Void)? = nil) {
        _ = gameActivity
        _ = handler
    }

    public func trigger(gameActivityDefinitionID: String, handler: (() -> Void)? = nil) {
        _ = gameActivityDefinitionID
        _ = handler
    }

    public func triggerForChallenges(handler: (() -> Void)? = nil) { _ = handler }
    public func triggerForFriending(handler: (() -> Void)? = nil) { _ = handler }
    public func triggerForPlayTogether(handler: (() -> Void)? = nil) { _ = handler }
    public func trigger(achievementID: String, handler: (() -> Void)? = nil) {
        _ = achievementID
        _ = handler
    }
    public func trigger(leaderboardSetID: String, handler: (() -> Void)? = nil) {
        _ = leaderboardSetID
        _ = handler
    }
    public func trigger(player: GKPlayer, handler: (() -> Void)? = nil) {
        _ = player
        _ = handler
    }
    public func trigger(
        leaderboardID: String,
        playerScope: GKLeaderboard.PlayerScope,
        timeScope: GKLeaderboard.TimeScope,
        handler: (() -> Void)? = nil
    ) {
        _ = (leaderboardID, playerScope, timeScope, handler)
    }

    public func trigger(challengeDefinitionID: String) async {
        _ = challengeDefinitionID
    }

    public func trigger(gameActivity: GKGameActivity) async {
        _ = gameActivity
    }

    public func trigger(gameActivityDefinitionID: String) async {
        _ = gameActivityDefinitionID
    }
}
