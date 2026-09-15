import Foundation

/// Synchronous fail-closed completion-handler companions for the Swift
/// `async` GameKit overlays.
///
/// Each `async` declaration in the other product files is the Swift overlay
/// for an Objective-C `...:completionHandler:` selector (see
/// `reference/public-surface.tsv`). The isolated Linux host cannot `await`,
/// so these companions expose the same operation with an explicit
/// completion handler that is invoked synchronously with a fail-closed
/// `GKError`/`GKGameSessionError`. No Game Center daemon, account, or
/// entitlement is contacted.
public extension GKAchievement {
    class func report(
        _ achievements: [GKAchievement],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = achievements
        GameKitHost.fail(completionHandler)
    }

    class func report(
        _ achievements: [GKAchievement],
        withEligibleChallenges challenges: [GKChallenge],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = achievements
        _ = challenges
        GameKitHost.fail(completionHandler)
    }

    func selectChallengeablePlayers(
        _ players: [GKPlayer],
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        _ = players
        GameKitHost.fail(completionHandler)
    }
}

public extension GKCloudPlayer {
    class func currentSignedInPlayer(
        forContainer containerName: String?,
        completionHandler: ((GKCloudPlayer?, (any Error)?) -> Void)? = nil
    ) {
        _ = containerName
        GameKitHost.failSession(completionHandler)
    }
}

public extension GKGameActivityDefinition {
    class func loadGameActivityDefinitions(
        IDs activityDefinitionIDs: [String]?,
        completionHandler: (([GKGameActivityDefinition]?, (any Error)?) -> Void)? = nil
    ) {
        _ = activityDefinitionIDs
        GameKitHost.fail(completionHandler)
    }
}

public extension GKGameSession {
    class func createSession(
        inContainer containerName: String?,
        withTitle title: String,
        maxConnectedPlayers maxPlayers: Int,
        completionHandler: ((GKGameSession?, (any Error)?) -> Void)? = nil
    ) {
        _ = (containerName, title, maxPlayers)
        GameKitHost.failSession(completionHandler)
    }

    class func load(
        withIdentifier identifier: String,
        completionHandler: ((GKGameSession?, (any Error)?) -> Void)? = nil
    ) {
        _ = identifier
        GameKitHost.failSession(completionHandler)
    }

    class func loadSessions(
        inContainer containerName: String?,
        completionHandler: (([GKGameSession]?, (any Error)?) -> Void)? = nil
    ) {
        _ = containerName
        GameKitHost.failSession(completionHandler)
    }

    class func remove(
        withIdentifier identifier: String,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = identifier
        completionHandler?(GameKitHost.sessionError(.invalidSession))
    }

    func clearBadge(
        for players: [GKCloudPlayer],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = players
        completionHandler?(GameKitHost.sessionError())
    }

    func send(
        _ data: Data,
        with transport: GKTransportType,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (data, transport)
        completionHandler?(GameKitHost.sessionError(.sendDataNotConnected))
    }

    func sendMessage(
        withLocalizedFormatKey key: String,
        arguments: [String],
        data: Data?,
        to players: [GKCloudPlayer],
        badgePlayers: Bool,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (key, arguments, data, players, badgePlayers)
        completionHandler?(GameKitHost.sessionError(.sendDataNotConnected))
    }

    func setConnectionState(
        _ state: GKConnectionState,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = state
        completionHandler?(GameKitHost.sessionError())
    }
}

public extension GKLeaderboard {
    class func loadLeaderboards(
        IDs leaderboardIDs: [String]?,
        completionHandler: (([GKLeaderboard]?, (any Error)?) -> Void)? = nil
    ) {
        _ = leaderboardIDs
        GameKitHost.fail(completionHandler)
    }

    class func submitScore(
        _ score: Int,
        context: Int,
        player: GKPlayer,
        leaderboardIDs: [String],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (score, context, player, leaderboardIDs)
        GameKitHost.fail(completionHandler)
    }

    func loadEntries(
        for playerScope: PlayerScope,
        timeScope: TimeScope,
        range: NSRange,
        completionHandler: ((Entry?, [Entry], Int, (any Error)?) -> Void)? = nil
    ) {
        _ = (playerScope, timeScope, range)
        completionHandler?(nil, [], 0, GameKitHost.unsupportedError())
    }

    func loadEntries(
        for players: [GKPlayer],
        timeScope: TimeScope,
        completionHandler: ((Entry?, [Entry], (any Error)?) -> Void)? = nil
    ) {
        _ = (players, timeScope)
        completionHandler?(nil, [], GameKitHost.unsupportedError())
    }

    func submitScore(
        _ score: Int,
        context: Int,
        player: GKPlayer,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (score, context, player)
        GameKitHost.fail(completionHandler)
    }
}

public extension GKLocalPlayer {
    func deleteSavedGames(
        withName name: String,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = name
        completionHandler?(GameKitHost.unsupportedError(.iCloudUnavailable))
    }

    func loadFriends(
        identifiedBy identifiers: [String],
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        _ = identifiers
        GameKitHost.fail(completionHandler)
    }

    func resolveConflictingSavedGames(
        _ conflictingSavedGames: [GKSavedGame],
        with data: Data,
        completionHandler: (([GKSavedGame]?, (any Error)?) -> Void)? = nil
    ) {
        _ = conflictingSavedGames
        _ = data
        completionHandler?(nil, GameKitHost.unsupportedError(.iCloudUnavailable))
    }

    func saveGameData(
        _ data: Data,
        withName name: String,
        completionHandler: ((GKSavedGame?, (any Error)?) -> Void)? = nil
    ) {
        _ = data
        _ = name
        completionHandler?(nil, GameKitHost.unsupportedError(.iCloudUnavailable))
    }

    func setDefaultLeaderboardIdentifier(
        _ leaderboardIdentifier: String,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = leaderboardIdentifier
        GameKitHost.fail(completionHandler)
    }
}

public extension GKMatchmaker {
    func addPlayers(
        to match: GKMatch,
        matchRequest: GKMatchRequest,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (match, matchRequest)
        GameKitHost.fail(completionHandler)
    }

    func findMatch(
        for request: GKMatchRequest,
        completionHandler: ((GKMatch?, (any Error)?) -> Void)? = nil
    ) {
        _ = request
        GameKitHost.fail(completionHandler)
    }

    func findMatchedPlayers(
        _ request: GKMatchRequest,
        completionHandler: ((GKMatchedPlayers?, (any Error)?) -> Void)? = nil
    ) {
        _ = request
        GameKitHost.fail(completionHandler)
    }

    func findPlayers(
        forHostedRequest request: GKMatchRequest,
        completionHandler: (([GKPlayer]?, (any Error)?) -> Void)? = nil
    ) {
        _ = request
        GameKitHost.fail(completionHandler)
    }

    func match(
        for invite: GKInvite,
        completionHandler: ((GKMatch?, (any Error)?) -> Void)? = nil
    ) {
        _ = invite
        GameKitHost.fail(completionHandler)
    }

    func queryPlayerGroupActivity(
        _ playerGroup: Int,
        completionHandler: ((Int, (any Error)?) -> Void)? = nil
    ) {
        _ = playerGroup
        completionHandler?(0, GameKitHost.unsupportedError())
    }

    func queryQueueActivity(
        _ queueName: String,
        completionHandler: ((Int, (any Error)?) -> Void)? = nil
    ) {
        _ = queueName
        completionHandler?(0, GameKitHost.unsupportedError())
    }
}

public extension GKNotificationBanner {
    class func show(
        withTitle title: String?,
        message: String?,
        completionHandler: (() -> Void)? = nil
    ) {
        _ = (title, message)
        notePortableShow()
        completionHandler?()
    }

    class func show(
        withTitle title: String?,
        message: String?,
        duration: TimeInterval,
        completionHandler: (() -> Void)? = nil
    ) {
        _ = (title, message, duration)
        notePortableShow()
        completionHandler?()
    }
}

public extension GKScore {
    class func report(
        _ scores: [GKScore],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = scores
        GameKitHost.fail(completionHandler)
    }

    class func report(
        _ scores: [GKScore],
        withEligibleChallenges challenges: [GKChallenge],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = scores
        _ = challenges
        GameKitHost.fail(completionHandler)
    }

    class func report(
        _ scores: [GKLeaderboardScore],
        withEligibleChallenges challenges: [GKChallenge],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = scores
        _ = challenges
        GameKitHost.fail(completionHandler)
    }
}

public extension GKTurnBasedExchange {
    func cancel(
        withLocalizableMessageKey key: String,
        arguments: [String],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (key, arguments)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidState))
    }

    func reply(
        withLocalizableMessageKey key: String,
        arguments: [String],
        data: Data,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (key, arguments, data)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidState))
    }
}

public extension GKTurnBasedMatch {
    class func find(
        for request: GKMatchRequest,
        completionHandler: ((GKTurnBasedMatch?, (any Error)?) -> Void)? = nil
    ) {
        _ = request
        GameKitHost.fail(completionHandler)
    }

    class func load(
        withID matchID: String,
        completionHandler: ((GKTurnBasedMatch?, (any Error)?) -> Void)? = nil
    ) {
        _ = matchID
        GameKitHost.fail(completionHandler)
    }

    func endMatchInTurn(
        withMatch matchData: Data,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = matchData
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func endMatchInTurn(
        withMatch matchData: Data,
        leaderboardScores scores: [GKLeaderboardScore],
        achievements: [Any],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (matchData, scores, achievements)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func endMatchInTurn(
        withMatch matchData: Data,
        scores: [GKScore]?,
        achievements: [GKAchievement]?,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (matchData, scores, achievements)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func endTurn(
        withNextParticipants nextParticipants: [GKTurnBasedParticipant],
        turnTimeout timeout: TimeInterval,
        match matchData: Data,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (nextParticipants, timeout, matchData)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func participantQuitInTurn(
        with matchOutcome: Outcome,
        nextParticipants: [GKTurnBasedParticipant],
        turnTimeout timeout: TimeInterval,
        match matchData: Data,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (matchOutcome, nextParticipants, timeout, matchData)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func participantQuitOutOfTurn(
        with matchOutcome: Outcome,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = matchOutcome
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func saveCurrentTurn(
        withMatch matchData: Data,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = matchData
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidTurn))
    }

    func saveMergedMatch(
        _ matchData: Data,
        withResolvedExchanges exchanges: [GKTurnBasedExchange],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (matchData, exchanges)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidState))
    }

    func sendExchange(
        to participants: [GKTurnBasedParticipant],
        data: Data,
        localizableMessageKey key: String,
        arguments: [String],
        timeout: TimeInterval,
        completionHandler: ((GKTurnBasedExchange?, (any Error)?) -> Void)? = nil
    ) {
        _ = (participants, data, key, arguments, timeout)
        completionHandler?(nil, GameKitHost.unsupportedError(.turnBasedInvalidState))
    }

    func sendReminder(
        to participants: [GKTurnBasedParticipant],
        localizableMessageKey key: String,
        arguments: [String],
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (participants, key, arguments)
        completionHandler?(GameKitHost.unsupportedError(.turnBasedInvalidState))
    }
}

public extension GKAccessPoint {
    func trigger(
        challengeDefinitionID: String,
        handler: (() -> Void)? = nil
    ) {
        _ = challengeDefinitionID
        _ = handler
    }
}
