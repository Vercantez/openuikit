import Foundation
import GameKit

func testGKGameActivityStateMachine() {
    let definition = GKGameActivityDefinition()
    definition.identifier = "raid"
    definition.title = "Raid"
    definition.details = "night"
    definition.groupIdentifier = "group"
    definition.defaultProperties = ["difficulty": "hard"]
    definition.fallbackURL = URL(string: "https://example.invalid")
    definition.supportsPartyCode = true
    definition.supportsUnlimitedPlayers = false
    definition.playStyle = .synchronous
    definition.releaseState = .released
    definition.minimumPlayers = 2
    definition.maximumPlayers = 4
    precondition(definition.identifier == "raid")
    precondition(definition.title == "Raid")
    precondition(definition.details == "night")
    precondition(definition.playStyle == .synchronous)
    precondition(definition.releaseState == .released)
    precondition(definition.supportsPartyCode)
    _ = definition.playerRange

    let activity = GKGameActivity(definition: definition)
    precondition(activity.state == .initialized)
    precondition(activity.activityDefinition === definition)
    precondition(!activity.identifier.isEmpty)
    precondition(activity.properties["difficulty"] == "hard")
    precondition(activity.partyCode == nil)
    precondition(activity.partyURL == nil)
    precondition(activity.startDate == nil)
    precondition(activity.endDate == nil)
    precondition(activity.duration == 0)
    activity.properties["seed"] = "1"
    precondition(activity.properties["seed"] == "1")
    _ = activity.creationDate
    _ = activity.lastResumeDate

    activity.pause()
    precondition(activity.state == .initialized)
    activity.start()
    precondition(activity.state == .active)
    precondition(activity.startDate != nil)
    activity.pause()
    precondition(activity.state == .paused)
    activity.resume()
    precondition(activity.state == .active)
    activity.end()
    precondition(activity.state == .ended)
    precondition(activity.endDate != nil)
    activity.start()
    precondition(activity.state == .ended)

    var pending = true
    GKGameActivity.checkPendingGameActivityExistence { pending = $0 }
    precondition(!pending)
}

func testGKGameActivityScoresAndAchievements() {
    let definition = GKGameActivityDefinition()
    definition.minimumPlayers = 2
    definition.maximumPlayers = 4
    let activity = GKGameActivity(definition: definition)
    let achievement = GKAchievement(identifier: "stars")
    activity.setProgress(on: achievement, to: 40)
    precondition(activity.progress(on: achievement) == 40)
    precondition(activity.achievements.contains(achievement))
    activity.setAchievementCompleted(achievement)
    precondition(achievement.isCompleted)
    activity.removeAchievements([achievement])
    precondition(activity.achievements.isEmpty)

    let board = GKLeaderboard()
    board.identifier = "kills"
    activity.setScore(on: board, to: 15)
    precondition(activity.score(on: board)?.value == 15)
    activity.setScore(on: board, to: 20, context: 3)
    precondition(activity.score(on: board)?.context == 3)
    activity.removeScores(from: [board])
    precondition(activity.score(on: board) == nil)

    let request = activity.makeMatchRequest()
    precondition(request?.minPlayers == 2)
    precondition(request?.maxPlayers == 4)

    var match: GKMatch? = GKMatch()
    var error: (any Error)?
    activity.findMatch { value, err in
        match = value
        error = err
    }
    precondition(match == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)
    var players: [GKPlayer]? = [GKPlayer()]
    activity.findPlayersForHostedMatch { values, err in
        players = values
        error = err
    }
    precondition(players == nil)
}

func testGKGameActivityPartyCode() {
    precondition(GKGameActivity.validPartyCodeAlphabet.isEmpty)
    precondition(!GKGameActivity.isValidPartyCode("ABCD"))
    precondition(!GKGameActivity.isValidPartyCode(""))
    let definition = GKGameActivityDefinition()
    do {
        _ = try GKGameActivity.start(definition: definition, partyCode: "ABCD")
        precondition(false)
    } catch let error as GKError {
        precondition(error.code == .invalidParameter)
    } catch {
        precondition(false)
    }
    let started = try? GKGameActivity.start(definition: definition)
    precondition(started?.state == .active)
}

func testGKGameActivityDefinitionFailClosed() {
    var loaded: [GKGameActivityDefinition]? = [GKGameActivityDefinition()]
    var error: (any Error)?
    GKGameActivityDefinition.loadGameActivityDefinitions { values, err in
        loaded = values
        error = err
    }
    precondition(loaded == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)
    let definition = GKGameActivityDefinition()
    var descriptions: [GKAchievementDescription]? = [GKAchievementDescription()]
    definition.loadAchievementDescriptions { values, err in
        descriptions = values
        error = err
    }
    precondition(descriptions == nil)
    var boards: [GKLeaderboard]? = [GKLeaderboard()]
    definition.loadLeaderboards { values, err in
        boards = values
        error = err
    }
    precondition(boards == nil)
}
