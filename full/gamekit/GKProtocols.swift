import Foundation

public protocol GKChallengeListener: AnyObject {
    func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer)
    func player(_ player: GKPlayer, didReceive challenge: GKChallenge)
    func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer)
    func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge)
}

public extension GKChallengeListener {
    func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) {}
    func player(_ player: GKPlayer, didReceive challenge: GKChallenge) {}
    func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) {}
    func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge) {}
}

public protocol GKGameActivityListener: AnyObject {
    func player(_ player: GKPlayer, wantsToPlay activity: GKGameActivity) async -> Bool
}

public extension GKGameActivityListener {
    func player(_ player: GKPlayer, wantsToPlay activity: GKGameActivity) async -> Bool {
        false
    }
}

public protocol GKInviteEventListener: AnyObject {
    func player(_ player: GKPlayer, didAccept invite: GKInvite)
    func player(_ player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String])
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer])
}

public extension GKInviteEventListener {
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {}
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {}
}

public protocol GKSavedGameListener: AnyObject {
    func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame)
    func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame])
}

public extension GKSavedGameListener {
    func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) {}
    func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) {}
}

public protocol GKTurnBasedEventListener: AnyObject {
    func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer])
    func player(_ player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String])
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch)
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch)
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch)
    func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch)
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool)
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch)
}

public extension GKTurnBasedEventListener {
    func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {}
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {}
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {}
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {}
    func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {}
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {}
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {}
}

public protocol GKLocalPlayerListener: GKChallengeListener, GKGameActivityListener, GKInviteEventListener, GKSavedGameListener, GKTurnBasedEventListener {}

public extension GKLocalPlayerListener {
    func player(_ player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String]) {}
}

public protocol GKMatchDelegate: AnyObject {
    func match(_ match: GKMatch, didFailWithError error: (any Error)?)
    func match(_ match: GKMatch, didReceive data: Data, forRecipient recipient: GKPlayer, fromRemotePlayer player: GKPlayer)
    func match(_ match: GKMatch, didReceive data: Data, fromPlayer playerID: String)
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer)
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState)
    func match(_ match: GKMatch, player playerID: String, didChange state: GKPlayerConnectionState)
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool
    func match(_ match: GKMatch, shouldReinvitePlayer playerID: String) -> Bool
}

public extension GKMatchDelegate {
    func match(_ match: GKMatch, didFailWithError error: (any Error)?) {}
    func match(_ match: GKMatch, didReceive data: Data, forRecipient recipient: GKPlayer, fromRemotePlayer player: GKPlayer) {}
    func match(_ match: GKMatch, didReceive data: Data, fromPlayer playerID: String) {}
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {}
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {}
    func match(_ match: GKMatch, player playerID: String, didChange state: GKPlayerConnectionState) {}
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool { false }
    func match(_ match: GKMatch, shouldReinvitePlayer playerID: String) -> Bool { false }
}

public protocol GKGameSessionEventListener: AnyObject {
    func session(_ session: GKGameSession, didAdd player: GKCloudPlayer)
    func session(_ session: GKGameSession, didReceive data: Data, from player: GKCloudPlayer)
    func session(_ session: GKGameSession, didReceiveMessage message: String, with data: Data, from player: GKCloudPlayer)
    func session(_ session: GKGameSession, didRemove player: GKCloudPlayer)
    func session(_ session: GKGameSession, player: GKCloudPlayer, didChange newState: GKConnectionState)
    func session(_ session: GKGameSession, player: GKCloudPlayer, didSave data: Data)
}

public extension GKGameSessionEventListener {
    func session(_ session: GKGameSession, didAdd player: GKCloudPlayer) {}
    func session(_ session: GKGameSession, didReceive data: Data, from player: GKCloudPlayer) {}
    func session(_ session: GKGameSession, didReceiveMessage message: String, with data: Data, from player: GKCloudPlayer) {}
    func session(_ session: GKGameSession, didRemove player: GKCloudPlayer) {}
    func session(_ session: GKGameSession, player: GKCloudPlayer, didChange newState: GKConnectionState) {}
    func session(_ session: GKGameSession, player: GKCloudPlayer, didSave data: Data) {}
}

public protocol GKGameCenterControllerDelegate: AnyObject {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController)
}

public protocol GKFriendRequestComposeViewControllerDelegate: AnyObject {
    func friendRequestComposeViewControllerDidFinish(_ viewController: GKFriendRequestComposeViewController)
}

public protocol GKMatchmakerViewControllerDelegate: AnyObject {
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error)
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController)
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFindHostedPlayers players: [GKPlayer])
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch)
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFindPlayers playerIDs: [String])
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didReceiveAcceptFromHostedPlayer playerID: String)
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, getMatchPropertiesForRecipient recipient: GKPlayer) async -> [String: Any]
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, hostedPlayerDidAccept player: GKPlayer)
}

public extension GKMatchmakerViewControllerDelegate {
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFindHostedPlayers players: [GKPlayer]) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFindPlayers playerIDs: [String]) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didReceiveAcceptFromHostedPlayer playerID: String) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, getMatchPropertiesForRecipient recipient: GKPlayer) async -> [String: Any] {
        [:]
    }
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, hostedPlayerDidAccept player: GKPlayer) {}
}

public protocol GKTurnBasedMatchmakerViewControllerDelegate: AnyObject {
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController)
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: any Error)
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch)
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, playerQuitFor match: GKTurnBasedMatch)
}

public extension GKTurnBasedMatchmakerViewControllerDelegate {
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch) {}
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, playerQuitFor match: GKTurnBasedMatch) {}
}
