import Foundation
import GameKit

func testGKTurnBasedLocalState() {
    let participant = GKTurnBasedParticipant()
    precondition(participant.status == .unknown)
    precondition(participant.matchOutcome == .none)
    precondition(participant.player == nil)
    precondition(participant.playerID == nil)
    precondition(participant.lastTurnDate == nil)
    precondition(participant.timeoutDate == nil)
    participant.matchOutcome = .won
    precondition(participant.matchOutcome == .won)

    let reply = GKTurnBasedExchangeReply()
    precondition(reply.data == nil)
    precondition(reply.message == nil)
    _ = reply.recipient
    _ = reply.replyDate

    let exchange = GKTurnBasedExchange()
    precondition(exchange.status == .unknown)
    precondition(exchange.exchangeID.isEmpty)
    precondition(exchange.recipients.isEmpty)
    _ = exchange.sendDate
    _ = exchange.sender
    _ = exchange.completionDate
    _ = exchange.data
    _ = exchange.message
    _ = exchange.replies
    _ = exchange.timeoutDate

    let match = GKTurnBasedMatch()
    precondition(match.status == .unknown)
    precondition(match.matchID.isEmpty)
    precondition(match.participants.isEmpty)
    precondition(match.matchDataMaximumSize == 65536)
    precondition(match.exchangeDataMaximumSize == 4096)
    precondition(match.exchangeMaxInitiatedExchangesPerPlayer == 1)
    match.message = "hello"
    precondition(match.message == "hello")
    match.setLocalizableMessageWithKey("key", arguments: ["a"])
    precondition(match.message == "key:a")
    match.setLocalizableMessageWithKey("plain", arguments: nil)
    precondition(match.message == "key" || match.message == "plain")
    let active = GKTurnBasedExchange()
    active.status = .active
    let done = GKTurnBasedExchange()
    done.status = .complete
    match.exchanges = [active, done]
    precondition(match.activeExchanges?.count == 1)
    precondition(match.completedExchanges?.count == 1)
    _ = match.creationDate
    _ = match.currentParticipant
    _ = match.matchData
}

func testGKTurnBasedFailClosed() {
    var matches: [GKTurnBasedMatch]? = [GKTurnBasedMatch()]
    var error: (any Error)?
    GKTurnBasedMatch.loadMatches { values, err in
        matches = values
        error = err
    }
    precondition(matches == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    let match = GKTurnBasedMatch()
    var accepted: GKTurnBasedMatch? = match
    match.acceptInvite { value, err in
        accepted = value
        error = err
    }
    precondition(accepted == nil)
    match.declineInvite { err in error = err }
    precondition((error as? GKError)?.code == .notAuthenticated)
    var data: Data? = Data([1])
    match.loadMatchData { value, err in
        data = value
        error = err
    }
    precondition(data == nil)
    var rematch: GKTurnBasedMatch? = match
    match.rematch { value, err in
        rematch = value
        error = err
    }
    precondition(rematch == nil)
    match.remove { err in error = err }
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKChallengeLocalState() {
    let challenge = GKChallenge()
    precondition(challenge.state == .invalid)
    challenge.decline()
    precondition(challenge.state == .declined)
    _ = challenge.issueDate
    _ = challenge.completionDate
    _ = challenge.issuingPlayer
    _ = challenge.receivingPlayer
    _ = challenge.issuingPlayerID
    _ = challenge.receivingPlayerID
    _ = challenge.message

    let achievementChallenge = GKAchievementChallenge()
    precondition(achievementChallenge.achievement == nil)
    let scoreChallenge = GKScoreChallenge()
    precondition(scoreChallenge.score == nil)
    precondition(scoreChallenge.leaderboardEntry == nil)

    var received: [GKChallenge]? = [challenge]
    var error: (any Error)?
    GKChallenge.loadReceivedChallenges { values, err in
        received = values
        error = err
    }
    precondition(received == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)

    let definition = GKChallengeDefinition()
    precondition(definition.identifier.isEmpty)
    precondition(definition.title.isEmpty)
    precondition(definition.details == nil)
    precondition(definition.groupIdentifier == nil)
    precondition(definition.durationOptions.isEmpty)
    precondition(!definition.isRepeatable)
    precondition(definition.leaderboard == nil)
    precondition(definition.releaseState.isEmpty)
    var definitions: [GKChallengeDefinition]? = [definition]
    GKChallengeDefinition.loadChallengeDefinitions { values, err in
        definitions = values
        error = err
    }
    precondition(definitions == nil)
    var hasActive = true
    definition.hasActiveChallenges { value, err in
        hasActive = value
        error = err
    }
    precondition(!hasActive)
}
