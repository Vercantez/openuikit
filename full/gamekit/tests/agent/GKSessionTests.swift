import Foundation
import GameKit

func testGKGameSessionFailClosed() {
    let session = GKGameSession()
    precondition(session.identifier.isEmpty)
    precondition(session.title.isEmpty)
    precondition(session.maxNumberOfConnectedPlayers == 0)
    precondition(session.players.isEmpty)
    precondition(session.badgedPlayers.isEmpty)
    _ = session.lastModifiedDate
    _ = session.lastModifiedPlayer
    _ = session.owner
    precondition(session.players(with: .connected).isEmpty)

    final class Probe: NSObject, GKGameSessionEventListener {}
    let probe = Probe()
    GKGameSession.add(listener: probe)
    precondition(GKGameSession.registeredListenerCount == 1)
    GKGameSession.remove(listener: probe)
    precondition(GKGameSession.registeredListenerCount == 0)

    var url: URL? = URL(string: "https://example.invalid")
    var error: (any Error)?
    session.getShareURL { value, err in
        url = value
        error = err
    }
    precondition(url == nil)
    precondition((error as? GKGameSessionError)?.code == .notAuthenticated)

    var data: Data? = Data([1])
    session.loadData { value, err in
        data = value
        error = err
    }
    precondition(data == nil)
    session.save(Data([1])) { value, err in
        data = value
        error = err
    }
    precondition(data == nil)
}

func testGKSavedGameFailClosed() {
    let saved = GKSavedGame()
    precondition(saved.deviceName == nil)
    precondition(saved.modificationDate == nil)
    precondition(saved.name == nil)
    var data: Data? = Data([1])
    var error: (any Error)?
    saved.loadData { value, err in
        data = value
        error = err
    }
    precondition(data == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKVoiceChatFailClosed() {
    precondition(!GKVoiceChat.isVoIPAllowed())
    let chat = GKVoiceChat(name: "lobby")
    precondition(chat.name == "lobby")
    precondition(!chat.isActive)
    precondition(chat.volume == 1)
    precondition(chat.players.isEmpty)
    precondition(chat.playerIDs?.isEmpty ?? true)
    chat.volume = 0.5
    precondition(chat.volume == 0.5)
    chat.start()
    precondition(!chat.isActive)
    chat.isActive = true
    chat.stop()
    precondition(!chat.isActive)
    chat.setMute(true, forPlayer: "p1")
    precondition(chat.isPlayerMuted("p1"))
    let player = GKPlayer.anonymousGuestPlayer(withIdentifier: "p2")
    chat.setPlayer(player, muted: true)
    precondition(chat.isPlayerMuted("p2"))
    chat.playerStateUpdateHandler("p1", .speaking)
    chat.playerVoiceChatStateDidChangeHandler(player, .silent)
}

func testGKViewControllerLocalState() {
    let defaultCenter = GKGameCenterViewController()
    precondition(defaultCenter.viewState == .default)
    let achievements = GKGameCenterViewController(achievementID: "a")
    precondition(achievements.viewState == .achievements)
    let board = GKLeaderboard()
    board.identifier = "b"
    let fromBoard = GKGameCenterViewController(leaderboard: board, playerScope: .global)
    precondition(fromBoard.viewState == .leaderboards)
    precondition(fromBoard.leaderboardIdentifier == "b")
    let fromIDs = GKGameCenterViewController(
        leaderboardID: "c",
        playerScope: .friendsOnly,
        timeScope: .week
    )
    precondition(fromIDs.leaderboardIdentifier == "c")
    precondition(fromIDs.leaderboardTimeScope == .week)
    let set = GKGameCenterViewController(leaderboardSetID: "set")
    precondition(set.viewState == .leaderboards)
    let profile = GKGameCenterViewController(player: GKPlayer())
    precondition(profile.viewState == .localPlayerProfile)
    let dashboard = GKGameCenterViewController(state: .dashboard)
    precondition(dashboard.viewState == .dashboard)
    dashboard.gameCenterDelegate = nil
    dashboard.leaderboardTimeScope = .today
    precondition(dashboard.leaderboardTimeScope == .today)

    let request = GKMatchRequest()
    let mm = GKMatchmakerViewController(matchRequest: request)
    precondition(mm != nil)
    precondition(mm?.matchRequest.minPlayers == 2)
    mm?.isHosted = true
    mm?.canStartWithMinimumPlayers = true
    mm?.matchmakingMode = .inviteOnly
    precondition(mm?.isHosted == true)
    precondition(mm?.canStartWithMinimumPlayers == true)
    precondition(mm?.matchmakingMode == .inviteOnly)
    mm?.addPlayers(to: GKMatch())
    mm?.setHostedPlayer("p1", connected: true)
    precondition(mm?.isHostedPlayerConnected("p1") == true)
    let guest = GKPlayer.anonymousGuestPlayer(withIdentifier: "p2")
    mm?.setHostedPlayer(guest, didConnect: true)
    precondition(mm?.isHostedPlayerConnected("p2") == true)
    mm?.matchmakerDelegate = nil
    precondition(GKMatchmakerViewController(invite: GKInvite()) != nil)
    let invalid = GKMatchRequest()
    invalid.minPlayers = 0
    precondition(GKMatchmakerViewController(matchRequest: invalid) == nil)

    let turn = GKTurnBasedMatchmakerViewController(matchRequest: request)
    turn.matchmakingMode = .automatchOnly
    turn.showExistingMatches = false
    turn.turnBasedMatchmakerDelegate = nil
    precondition(turn.matchmakingMode == .automatchOnly)
    precondition(!turn.showExistingMatches)
    _ = turn.matchRequest

    precondition(GKFriendRequestComposeViewController.maxNumberOfRecipients() == 8)
    let compose = GKFriendRequestComposeViewController()
    compose.setMessage("hi")
    precondition(compose.message == "hi")
    compose.addRecipientPlayers([GKPlayer(), GKPlayer()])
    compose.addRecipients(withEmailAddresses: ["a@example.invalid"])
    compose.addRecipients(withPlayerIDs: ["id"])
    precondition(compose.recipientCount == 4)
    compose.composeViewDelegate = nil
    compose.addRecipientPlayers((0..<20).map { _ in GKPlayer() })
    precondition(compose.recipientCount <= 8)
}

func testGKProtocolWitnesses() {
    final class ChallengeProbe: NSObject, GKChallengeListener {}
    final class InviteProbe: NSObject, GKInviteEventListener {
        func player(_ player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String]) {}
    }
    final class SavedProbe: NSObject, GKSavedGameListener {}
    final class TurnProbe: NSObject, GKTurnBasedEventListener {
        func player(_ player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String]) {}
    }
    final class LocalProbe: NSObject, GKLocalPlayerListener {}
    final class MatchProbe: NSObject, GKMatchDelegate {}
    final class SessionProbe: NSObject, GKGameSessionEventListener {}
    final class CenterProbe: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            _ = gameCenterViewController
        }
    }
    final class FriendProbe: NSObject, GKFriendRequestComposeViewControllerDelegate {
        func friendRequestComposeViewControllerDidFinish(_ viewController: GKFriendRequestComposeViewController) {
            _ = viewController
        }
    }
    final class MatchmakerProbe: NSObject, GKMatchmakerViewControllerDelegate {
        func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error) {
            _ = (viewController, error)
        }
        func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
            _ = viewController
        }
    }
    final class TurnMakerProbe: NSObject, GKTurnBasedMatchmakerViewControllerDelegate {
        func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
            _ = viewController
        }
        func turnBasedMatchmakerViewController(
            _ viewController: GKTurnBasedMatchmakerViewController,
            didFailWithError error: any Error
        ) {
            _ = (viewController, error)
        }
    }
    _ = ChallengeProbe()
    _ = InviteProbe()
    _ = SavedProbe()
    _ = TurnProbe()
    _ = LocalProbe()
    _ = MatchProbe()
    _ = SessionProbe()
    _ = CenterProbe()
    _ = FriendProbe()
    _ = MatchmakerProbe()
    _ = TurnMakerProbe()
    let matchDelegate: any GKMatchDelegate = MatchProbe()
    precondition(!matchDelegate.match(GKMatch(), shouldReinvitePlayer: "x"))
    precondition(!matchDelegate.match(GKMatch(), shouldReinviteDisconnectedPlayer: GKPlayer()))
}
