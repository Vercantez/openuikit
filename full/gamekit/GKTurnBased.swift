import Foundation

open class GKTurnBasedParticipant: NSObject {
    public enum Status: Int, Hashable, Sendable {
        case unknown = 0
        case invited = 1
        case declined = 2
        case matching = 3
        case active = 4
        case done = 5
    }

    public internal(set) var lastTurnDate: Date?
    public var matchOutcome: GKTurnBasedMatch.Outcome = .none
    public internal(set) var player: GKPlayer?
    public var playerID: String? { player?.playerID }
    public internal(set) var status: Status = .unknown
    public internal(set) var timeoutDate: Date?
}

open class GKTurnBasedExchangeReply: NSObject {
    public internal(set) var data: Data?
    public internal(set) var message: String?
    public internal(set) var recipient: GKTurnBasedParticipant = GKTurnBasedParticipant()
    public internal(set) var replyDate: Date = Date()
}

open class GKTurnBasedExchange: NSObject {
    public internal(set) var completionDate: Date?
    public internal(set) var data: Data?
    public internal(set) var exchangeID: String = ""
    public internal(set) var message: String?
    public internal(set) var recipients: [GKTurnBasedParticipant] = []
    public internal(set) var replies: [GKTurnBasedExchangeReply]?
    public internal(set) var sendDate: Date = Date()
    public internal(set) var sender: GKTurnBasedParticipant = GKTurnBasedParticipant()
    public var status: GKTurnBasedExchangeStatus = .unknown
    public internal(set) var timeoutDate: Date?

    public func cancel(withLocalizableMessageKey key: String, arguments: [String]) async throws {
        _ = (key, arguments)
        throw GameKitHost.unsupportedError(.turnBasedInvalidState)
    }

    public func reply(withLocalizableMessageKey key: String, arguments: [String], data: Data) async throws {
        _ = (key, arguments, data)
        throw GameKitHost.unsupportedError(.turnBasedInvalidState)
    }
}

open class GKTurnBasedMatch: NSObject {
    public enum Outcome: Int, Hashable, Sendable {
        case none = 0
        case quit = 1
        case won = 2
        case lost = 3
        case tied = 4
        case timeExpired = 5
        case first = 6
        case second = 7
        case third = 8
        case fourth = 9
        case customRange = 0xFF0000
    }

    public enum Status: Int, Hashable, Sendable {
        case unknown = 0
        case open = 1
        case ended = 2
        case matching = 3
    }

    public internal(set) var matchID: String = ""
    public var message: String?
    public internal(set) var status: Status = .unknown
    public internal(set) var creationDate: Date = Date()
    public internal(set) var participants: [GKTurnBasedParticipant] = []
    public internal(set) var currentParticipant: GKTurnBasedParticipant?
    public internal(set) var matchData: Data?
    public internal(set) var matchDataMaximumSize: Int = 65536
    public var exchanges: [GKTurnBasedExchange]?
    public internal(set) var exchangeDataMaximumSize: Int = 4096
    public internal(set) var exchangeMaxInitiatedExchangesPerPlayer: Int = 1

    public var activeExchanges: [GKTurnBasedExchange]? {
        exchanges?.filter { $0.status == .active }
    }

    public var completedExchanges: [GKTurnBasedExchange]? {
        exchanges?.filter { $0.status == .complete || $0.status == .resolved || $0.status == .canceled }
    }

    public func setLocalizableMessageWithKey(_ key: String, arguments: [String]?) {
        if let arguments, !arguments.isEmpty {
            message = key + ":" + arguments.joined(separator: ",")
        } else {
            message = key
        }
    }

    public class func loadMatches(completionHandler: (([GKTurnBasedMatch]?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func acceptInvite(completionHandler: ((GKTurnBasedMatch?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func declineInvite(completionHandler: (((any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func loadMatchData(completionHandler: ((Data?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func rematch(completionHandler: ((GKTurnBasedMatch?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public func remove(completionHandler: (((any Error)?) -> Void)? = nil) {
        GameKitHost.fail(completionHandler)
    }

    public class func find(for request: GKMatchRequest) async throws -> GKTurnBasedMatch {
        _ = request
        throw GameKitHost.unsupportedError()
    }

    public class func load(withID matchID: String) async throws -> GKTurnBasedMatch {
        _ = matchID
        throw GameKitHost.unsupportedError()
    }

    public func endMatchInTurn(withMatch matchData: Data) async throws {
        _ = matchData
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func endMatchInTurn(
        withMatch matchData: Data,
        leaderboardScores scores: [GKLeaderboardScore],
        achievements: [Any]
    ) async throws {
        _ = (matchData, scores, achievements)
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func endMatchInTurn(
        withMatch matchData: Data,
        scores: [GKScore]?,
        achievements: [GKAchievement]?
    ) async throws {
        _ = (matchData, scores, achievements)
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func endTurn(
        withNextParticipants nextParticipants: [GKTurnBasedParticipant],
        turnTimeout timeout: TimeInterval,
        match matchData: Data
    ) async throws {
        _ = (nextParticipants, timeout, matchData)
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func participantQuitInTurn(
        with matchOutcome: Outcome,
        nextParticipants: [GKTurnBasedParticipant],
        turnTimeout timeout: TimeInterval,
        match matchData: Data
    ) async throws {
        _ = (matchOutcome, nextParticipants, timeout, matchData)
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func participantQuitOutOfTurn(with matchOutcome: Outcome) async throws {
        _ = matchOutcome
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func saveCurrentTurn(withMatch matchData: Data) async throws {
        _ = matchData
        throw GameKitHost.unsupportedError(.turnBasedInvalidTurn)
    }

    public func saveMergedMatch(_ matchData: Data, withResolvedExchanges exchanges: [GKTurnBasedExchange]) async throws {
        _ = (matchData, exchanges)
        throw GameKitHost.unsupportedError(.turnBasedInvalidState)
    }

    public func sendExchange(
        to participants: [GKTurnBasedParticipant],
        data: Data,
        localizableMessageKey key: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> GKTurnBasedExchange {
        _ = (participants, data, key, arguments, timeout)
        throw GameKitHost.unsupportedError(.turnBasedInvalidState)
    }

    public func sendReminder(
        to participants: [GKTurnBasedParticipant],
        localizableMessageKey key: String,
        arguments: [String]
    ) async throws {
        _ = (participants, key, arguments)
        throw GameKitHost.unsupportedError(.turnBasedInvalidState)
    }
}
