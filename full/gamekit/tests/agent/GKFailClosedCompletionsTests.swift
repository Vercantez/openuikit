import Foundation
import GameKit

func testGKReportFailClosed() {
    var reportError: (any Error)?
    GKAchievement.report([GKAchievement(identifier: "a")], completionHandler: { err in
        reportError = err
    })
    precondition((reportError as? GKError)?.code == .notAuthenticated)

    GKAchievement.report(
        [GKAchievement(identifier: "a")],
        withEligibleChallenges: [GKChallenge()],
        completionHandler: { err in reportError = err }
    )
    precondition((reportError as? GKError)?.code == .notAuthenticated)

    var players: [GKPlayer]? = [GKPlayer()]
    var selectError: (any Error)?
    GKAchievement(identifier: "a").selectChallengeablePlayers([GKPlayer()]) { values, err in
        players = values
        selectError = err
    }
    precondition(players == nil)
    precondition((selectError as? GKError)?.code == .notAuthenticated)

    GKScore.report([GKScore(leaderboardIdentifier: "b")], completionHandler: { err in
        reportError = err
    })
    precondition((reportError as? GKError)?.code == .notAuthenticated)

    GKScore.report(
        [GKScore(leaderboardIdentifier: "b")],
        withEligibleChallenges: [GKChallenge()],
        completionHandler: { err in reportError = err }
    )
    precondition((reportError as? GKError)?.code == .notAuthenticated)

    let lbScore = GKLeaderboardScore()
    lbScore.leaderboardID = "b"
    GKScore.report(
        [lbScore],
        withEligibleChallenges: [GKChallenge()],
        completionHandler: { err in reportError = err }
    )
    precondition((reportError as? GKError)?.code == .notAuthenticated)
}

func testGKLeaderboardCompletionsFailClosed() {
    var boards: [GKLeaderboard]? = [GKLeaderboard()]
    var error: (any Error)?
    GKLeaderboard.loadLeaderboards(IDs: ["b"]) { values, err in
        boards = values
        error = err
    }
    precondition(boards == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    var submitError: (any Error)?
    GKLeaderboard.submitScore(10, context: 0, player: GKPlayer(), leaderboardIDs: ["b"]) { err in
        submitError = err
    }
    precondition((submitError as? GKError)?.code == .notAuthenticated)

    let board = GKLeaderboard()
    var entry: GKLeaderboard.Entry? = GKLeaderboard.Entry()
    var entries: [GKLeaderboard.Entry] = [GKLeaderboard.Entry()]
    var count = 99
    board.loadEntries(for: GKLeaderboard.PlayerScope.global, timeScope: .allTime, range: NSRange(location: 1, length: 10)) { value, values, total, err in
        entry = value
        entries = values
        count = total
        error = err
    }
    precondition(entry == nil)
    precondition(entries.isEmpty)
    precondition(count == 0)
    precondition((error as? GKError)?.code == .notAuthenticated)

    var single: GKLeaderboard.Entry? = GKLeaderboard.Entry()
    var many: [GKLeaderboard.Entry] = [GKLeaderboard.Entry()]
    board.loadEntries(for: [GKPlayer()], timeScope: .week) { value, values, err in
        single = value
        many = values
        error = err
    }
    precondition(single == nil)
    precondition(many.isEmpty)
    precondition((error as? GKError)?.code == .notAuthenticated)

    board.submitScore(5, context: 1, player: GKPlayer()) { err in
        submitError = err
    }
    precondition((submitError as? GKError)?.code == .notAuthenticated)
}

func testGKLocalPlayerCompletionsFailClosed() {
    let local = GKLocalPlayer.local
    var error: (any Error)?
    local.deleteSavedGames(withName: "slot1") { err in error = err }
    precondition((error as? GKError)?.code == .iCloudUnavailable)

    var friends: [GKPlayer]? = [GKPlayer()]
    local.loadFriends(identifiedBy: ["id1"]) { values, err in
        friends = values
        error = err
    }
    precondition(friends == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    var resolved: [GKSavedGame]? = [GKSavedGame()]
    local.resolveConflictingSavedGames([GKSavedGame()], with: Data([1])) { values, err in
        resolved = values
        error = err
    }
    precondition(resolved == nil)
    precondition((error as? GKError)?.code == .iCloudUnavailable)

    var saved: GKSavedGame? = GKSavedGame()
    local.saveGameData(Data([2]), withName: "slot1") { value, err in
        saved = value
        error = err
    }
    precondition(saved == nil)
    precondition((error as? GKError)?.code == .iCloudUnavailable)

    local.setDefaultLeaderboardIdentifier("board") { err in error = err }
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKMatchmakerCompletionsFailClosed() {
    let maker = GKMatchmaker.shared()
    let request = GKMatchRequest()
    var error: (any Error)?

    maker.addPlayers(to: GKMatch(), matchRequest: request) { err in error = err }
    precondition((error as? GKError)?.code == .notAuthenticated)

    var match: GKMatch? = GKMatch()
    maker.findMatch(for: request) { value, err in
        match = value
        error = err
    }
    precondition(match == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    var matched: GKMatchedPlayers? = GKMatchedPlayers()
    maker.findMatchedPlayers(request) { value, err in
        matched = value
        error = err
    }
    precondition(matched == nil)

    var hosted: [GKPlayer]? = [GKPlayer()]
    maker.findPlayers(forHostedRequest: request) { values, err in
        hosted = values
        error = err
    }
    precondition(hosted == nil)

    maker.match(for: GKInvite()) { value, err in
        match = value
        error = err
    }
    precondition(match == nil)

    var activity = 99
    maker.queryPlayerGroupActivity(3) { value, err in
        activity = value
        error = err
    }
    precondition(activity == 0)
    precondition((error as? GKError)?.code == .notAuthenticated)

    maker.queryQueueActivity("q") { value, err in
        activity = value
        error = err
    }
    precondition(activity == 0)
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKGameSessionCompletionsFailClosed() {
    var session: GKGameSession? = GKGameSession()
    var sessions: [GKGameSession]? = [GKGameSession()]
    var error: (any Error)?

    GKGameSession.createSession(inContainer: nil, withTitle: "t", maxConnectedPlayers: 4) { value, err in
        session = value
        error = err
    }
    precondition(session == nil)
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)

    GKGameSession.load(withIdentifier: "id") { value, err in
        session = value
        error = err
    }
    precondition(session == nil)
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)

    GKGameSession.loadSessions(inContainer: nil) { values, err in
        sessions = values
        error = err
    }
    precondition(sessions == nil)

    GKGameSession.remove(withIdentifier: "id") { err in error = err }
    precondition((error as? GKGameSessionError)?.code == .invalidSession)

    let live = GKGameSession()
    live.clearBadge(for: [GKCloudPlayer()]) { err in error = err }
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)

    live.send(Data([1]), with: .reliable) { err in error = err }
    precondition((error as? GKGameSessionError)?.code == .sendDataNotConnected)

    live.sendMessage(
        withLocalizedFormatKey: "k",
        arguments: ["a"],
        data: nil,
        to: [GKCloudPlayer()],
        badgePlayers: false
    ) { err in error = err }
    precondition((error as? GKGameSessionError)?.code == .sendDataNotConnected)

    live.setConnectionState(.connected) { err in error = err }
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)
}

func testGKTurnBasedExchangeCompletionsFailClosed() {
    let exchange = GKTurnBasedExchange()
    var error: (any Error)?
    exchange.cancel(withLocalizableMessageKey: "k", arguments: ["a"]) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidState)
    exchange.reply(withLocalizableMessageKey: "k", arguments: ["a"], data: Data([1])) { err in
        error = err
    }
    precondition((error as? GKError)?.code == .turnBasedInvalidState)
}

func testGKTurnBasedMatchCompletionsFailClosed() {
    let request = GKMatchRequest()
    var match: GKTurnBasedMatch? = GKTurnBasedMatch()
    var error: (any Error)?

    GKTurnBasedMatch.find(for: request) { value, err in
        match = value
        error = err
    }
    precondition(match == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    GKTurnBasedMatch.load(withID: "id") { value, err in
        match = value
        error = err
    }
    precondition(match == nil)

    let live = GKTurnBasedMatch()
    live.endMatchInTurn(withMatch: Data([1])) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.endMatchInTurn(
        withMatch: Data([1]),
        leaderboardScores: [GKLeaderboardScore()],
        achievements: [GKAchievement(identifier: "a")]
    ) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.endMatchInTurn(
        withMatch: Data([1]),
        scores: [GKScore(leaderboardIdentifier: "b")],
        achievements: [GKAchievement(identifier: "a")]
    ) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.endTurn(withNextParticipants: [], turnTimeout: 0, match: Data([1])) { err in
        error = err
    }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.participantQuitInTurn(
        with: .quit,
        nextParticipants: [],
        turnTimeout: 0,
        match: Data([1])
    ) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.participantQuitOutOfTurn(with: .quit) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    live.saveCurrentTurn(withMatch: Data([1])) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidTurn)

    var exchange: GKTurnBasedExchange? = GKTurnBasedExchange()
    live.saveMergedMatch(Data([1]), withResolvedExchanges: []) { err in error = err }
    precondition((error as? GKError)?.code == .turnBasedInvalidState)

    live.sendExchange(
        to: [],
        data: Data([1]),
        localizableMessageKey: "k",
        arguments: [],
        timeout: 0
    ) { value, err in
        exchange = value
        error = err
    }
    precondition(exchange == nil)
    precondition((error as? GKError)?.code == .turnBasedInvalidState)

    live.sendReminder(to: [], localizableMessageKey: "k", arguments: []) { err in
        error = err
    }
    precondition((error as? GKError)?.code == .turnBasedInvalidState)
}

func testGKCloudActivityBannerFailClosed() {
    var cloud: GKCloudPlayer? = GKCloudPlayer()
    var error: (any Error)?
    GKCloudPlayer.currentSignedInPlayer(forContainer: nil) { value, err in
        cloud = value
        error = err
    }
    precondition(cloud == nil)
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)

    var definitions: [GKGameActivityDefinition]? = [GKGameActivityDefinition()]
    GKGameActivityDefinition.loadGameActivityDefinitions(IDs: ["a"]) { values, err in
        definitions = values
        error = err
    }
    precondition(definitions == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    let banner = GKNotificationBanner()
    _ = banner
    let before = GKNotificationBanner.portableShowCount
    var shown = false
    GKNotificationBanner.show(withTitle: "t", message: "m") { shown = true }
    precondition(shown)
    GKNotificationBanner.show(withTitle: "t", message: "m", duration: 2) { shown = true }
    precondition(shown)
    precondition(GKNotificationBanner.portableShowCount == before + 2)

    let point = GKAccessPoint.shared
    point.trigger(challengeDefinitionID: "c") { _ = false }
    precondition(!point.isPresentingGameCenter)
}
