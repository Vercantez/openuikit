import Foundation
import GameKit

func testGKAchievementLocalState() {
    let achievement = GKAchievement(identifier: "level.1")
    precondition(achievement.identifier == "level.1")
    precondition(achievement.percentComplete == 0)
    precondition(!achievement.isCompleted)
    precondition(achievement.showsCompletionBanner)
    achievement.percentComplete = 50
    precondition(!achievement.isCompleted)
    achievement.percentComplete = 100
    precondition(achievement.isCompleted)
    achievement.showsCompletionBanner = false
    precondition(!achievement.showsCompletionBanner)
    _ = achievement.lastReportedDate
    _ = achievement.player
    _ = achievement.playerID

    let guest = GKPlayer.anonymousGuestPlayer(withIdentifier: "guest-1")
    let forPlayer = GKAchievement(identifier: "coop", player: guest)
    precondition(forPlayer.player.guestIdentifier == "guest-1")

    let obsolete = GKAchievement(identifier: "legacy", forPlayer: "player-id")
    precondition(obsolete?.playerID == "player-id")
    precondition(GKAchievement(identifier: nil, forPlayer: "x") == nil)
    precondition(GKAchievement(identifier: "x", forPlayer: "") == nil)

    if let data = try? NSKeyedArchiver.archivedData(
        withRootObject: achievement,
        requiringSecureCoding: true
    ) {
        let restored = try? NSKeyedUnarchiver.unarchivedObject(ofClass: GKAchievement.self, from: data)
        if let restored {
            precondition(restored.identifier == "level.1")
            precondition(restored.percentComplete == 100)
        }
    }
}

func testGKAchievementFailClosed() {
    var loaded: [GKAchievement]? = [GKAchievement(identifier: "x")]
    var loadError: (any Error)?
    GKAchievement.loadAchievements { values, error in
        loaded = values
        loadError = error
    }
    precondition(loaded == nil)
    precondition((loadError as? GKError)?.code == .notAuthenticated)

    var resetError: (any Error)?
    GKAchievement.resetAchievements { error in
        resetError = error
    }
    precondition((resetError as? GKError)?.code == .notAuthenticated)

    var challengeIDs: [String]? = ["keep"]
    var challengeError: (any Error)?
    GKAchievement(identifier: "x").selectChallengeablePlayerIDs(["a"]) { ids, error in
        challengeIDs = ids
        challengeError = error
    }
    precondition(challengeIDs == nil)
    precondition((challengeError as? GKError)?.code == .notAuthenticated)
}

func testGKAchievementDescriptionFailClosed() {
    let description = GKAchievementDescription()
    precondition(description.identifier.isEmpty)
    precondition(description.title.isEmpty)
    precondition(description.achievedDescription.isEmpty)
    precondition(description.unachievedDescription.isEmpty)
    precondition(description.groupIdentifier == nil)
    precondition(description.maximumPoints == 0)
    precondition(!description.isHidden)
    precondition(!description.isReplayable)
    precondition(description.activityIdentifier.isEmpty)
    precondition(description.activityProperties.isEmpty)
    precondition(description.releaseState.isEmpty)
    precondition(description.rarityPercent == nil)

    var loaded: [GKAchievementDescription]? = [GKAchievementDescription()]
    var error: (any Error)?
    GKAchievementDescription.loadAchievementDescriptions { values, err in
        loaded = values
        error = err
    }
    precondition(loaded == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKScoreLocalState() {
    let score = GKScore(leaderboardIdentifier: "board")
    precondition(score.leaderboardIdentifier == "board")
    precondition(score.value == 0)
    score.value = 42
    precondition(score.value == 42)
    precondition(score.formattedValue == "42")
    score.context = 9
    precondition(score.context == 9)
    score.shouldSetDefaultLeaderboard = true
    precondition(score.shouldSetDefaultLeaderboard)
    precondition(score.rank == 0)
    _ = score.date
    _ = score.player
    _ = score.playerID

    let guest = GKPlayer.anonymousGuestPlayer(withIdentifier: "g")
    let tagged = GKScore(leaderboardIdentifier: "board", player: guest)
    precondition(tagged.player.guestIdentifier == "g")
    precondition(GKScore(leaderboardIdentifier: "board", forPlayer: "pid")?.playerID == "pid")
    precondition(GKScore(leaderboardIdentifier: "", forPlayer: "pid") == nil)
}

func testGKLeaderboardLocalState() {
    let board = GKLeaderboard()
    board.identifier = "best"
    board.playerScope = .friendsOnly
    board.timeScope = .week
    board.range = NSRange(location: 1, length: 10)
    precondition(board.identifier == "best")
    precondition(board.playerScope == .friendsOnly)
    precondition(board.timeScope == .week)
    precondition(board.range.location == 1)
    precondition(board.range.length == 10)
    precondition(!board.isLoading)
    precondition(board.type == .classic)
    precondition(board.duration == 0)
    _ = board.title
    _ = board.groupIdentifier
    _ = board.isHidden
    _ = board.maxRange
    _ = board.scores
    _ = board.localPlayerScore
    _ = board.leaderboardDescription
    _ = board.baseLeaderboardID
    _ = board.startDate
    _ = board.nextStartDate
    _ = board.activityIdentifier
    _ = board.activityProperties
    _ = board.releaseState

    var previous: GKLeaderboard? = board
    var previousError: (any Error)?
    board.loadPreviousOccurrence { value, error in
        previous = value
        previousError = error
    }
    precondition(previous == nil)
    precondition((previousError as? GKError)?.code == .notAuthenticated)

    var scores: [GKScore]? = [GKScore(leaderboardIdentifier: "best")]
    var scoreError: (any Error)?
    board.loadScores { values, error in
        scores = values
        scoreError = error
    }
    precondition(scores == nil)
    precondition((scoreError as? GKError)?.code == .notAuthenticated)

    var loaded: [GKLeaderboard]? = [board]
    var loadError: (any Error)?
    GKLeaderboard.loadLeaderboards { values, error in
        loaded = values
        loadError = error
    }
    precondition(loaded == nil)
    precondition((loadError as? GKError)?.code == .notAuthenticated)

    let withPlayers = GKLeaderboard(players: [GKPlayer()])
    _ = withPlayers
    precondition(GKLeaderboard(playerIDs: nil) == nil)
    precondition(GKLeaderboard(playerIDs: ["a"]) != nil)

    let entry = GKLeaderboard.Entry()
    precondition(entry.score == 0)
    precondition(entry.rank == 0)
    precondition(entry.context == 0)
    _ = entry.date
    _ = entry.formattedScore
    _ = entry.player

    let set = GKLeaderboardSet()
    set.identifier = "set"
    precondition(set.identifier == "set")
    precondition(set.title.isEmpty)
    var setBoards: [GKLeaderboard]? = [board]
    var setError: (any Error)?
    set.loadLeaderboards { values, error in
        setBoards = values
        setError = error
    }
    precondition(setBoards == nil)
    precondition((setError as? GKError)?.code == .notAuthenticated)
    set.loadLeaderboards { values, error in
        setBoards = values
        setError = error
    }
    var sets: [GKLeaderboardSet]? = [set]
    GKLeaderboardSet.loadLeaderboardSets { values, error in
        sets = values
        setError = error
    }
    precondition(sets == nil)

    let lbScore = GKLeaderboardScore()
    lbScore.context = 3
    lbScore.leaderboardID = "best"
    lbScore.value = 10
    lbScore.player = GKPlayer()
    precondition(lbScore.context == 3)
    precondition(lbScore.leaderboardID == "best")
    precondition(lbScore.value == 10)
    _ = lbScore.player
}
