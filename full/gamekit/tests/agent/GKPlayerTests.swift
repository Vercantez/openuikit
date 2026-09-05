import Foundation
import GameKit

func testGKPlayerIdentity() {
    let base = GKBasePlayer()
    precondition(base.displayName == nil)
    precondition(base.playerID == nil)

    let player = GKPlayer()
    precondition(player.alias.isEmpty)
    precondition(player.gamePlayerID.isEmpty)
    precondition(player.teamPlayerID.isEmpty)
    precondition(player.guestIdentifier == nil)
    precondition(!player.isFriend)
    precondition(!player.isInvitable)
    precondition(!(player.playerID?.isEmpty ?? true) || player.playerID == "")
    precondition(!player.scopedIDsArePersistent())

    let guest = GKPlayer.anonymousGuestPlayer(withIdentifier: "guest-42")
    precondition(guest.guestIdentifier == "guest-42")
    precondition(guest.playerID == "guest-42")
    precondition(guest.alias == "guest-42")

    var loaded: [GKPlayer]? = [player]
    var error: (any Error)?
    GKPlayer.loadPlayers(forIdentifiers: ["a"]) { values, err in
        loaded = values
        error = err
    }
    precondition(loaded == nil)
    precondition((error as? GKError)?.code == .notAuthenticated)
}

func testGKLocalPlayerUnauthenticated() {
    let local = GKLocalPlayer.local
    precondition(!local.isAuthenticated)
    precondition(!local.isUnderage)
    precondition(local.isMultiplayerGamingRestricted)
    precondition(local.isPersonalizedCommunicationRestricted)
    precondition(!local.isPresentingFriendRequestViewController)
    precondition(local.friends == nil)
    final class Probe: NSObject, GKLocalPlayerListener {}
    let probe = Probe()
    local.register(probe)
    local.unregisterListener(probe)
    local.unregisterAllListeners()

    var itemsError: (any Error)?
    local.fetchItems(forIdentityVerificationSignature: { url, d1, d2, n, err in
        precondition(url == nil)
        precondition(d1 == nil)
        precondition(d2 == nil)
        precondition(n == 0)
        itemsError = err
    })
    precondition((itemsError as? GKError)?.code == .notAuthenticated)

    local.generateIdentityVerificationSignature { _, _, _, _, err in
        itemsError = err
    }
    precondition((itemsError as? GKError)?.code == .notAuthenticated)

    var games: [GKSavedGame]? = [GKSavedGame()]
    local.fetchSavedGames { values, err in
        games = values
        itemsError = err
    }
    precondition(games == nil)

    var friends: [GKPlayer]? = [GKPlayer()]
    local.loadChallengableFriends { values, err in
        friends = values
        itemsError = err
    }
    precondition(friends == nil)
    local.loadFriendPlayers { values, err in
        friends = values
        itemsError = err
    }
    precondition(friends == nil)
    local.loadFriends { values, err in
        friends = values
        itemsError = err
    }
    precondition(friends == nil)
    local.loadRecentPlayers { values, err in
        friends = values
        itemsError = err
    }
    precondition(friends == nil)

    var leaderboard: String? = "x"
    local.loadDefaultLeaderboardIdentifier { value, err in
        leaderboard = value
        itemsError = err
    }
    precondition(leaderboard == nil)

    var status: GKFriendsAuthorizationStatus = .authorized
    local.loadFriendsAuthorizationStatus { value, err in
        status = value
        itemsError = err
    }
    precondition(status == .notDetermined)

    var obsolete: [String]? = ["x"]
    local.loadFriendsObsoleted { values, err in
        obsolete = values
        itemsError = err
    }
    precondition(obsolete == nil)
}

func testGKAccessPointLocalState() {
    let point = GKAccessPoint.shared
    precondition(ObjectIdentifier(point) == ObjectIdentifier(GKAccessPoint.shared))
    point.isActive = true
    precondition(point.isActive)
    precondition(!point.isVisible)
    precondition(!point.isPresentingGameCenter)
    point.location = .bottomTrailing
    precondition(point.location == .bottomTrailing)
    point.showHighlights = true
    precondition(point.showHighlights)
    precondition(point.frameInScreenCoordinates == .zero)
    point.trigger { precondition(false) }
    point.trigger(state: .dashboard) { precondition(false) }
    point.triggerForChallenges { precondition(false) }
    point.triggerForFriending { _ = false }
    point.triggerForPlayTogether { _ = false }
    point.trigger(achievementID: "a") { _ = false }
    point.trigger(leaderboardSetID: "s") { _ = false }
    point.trigger(player: GKPlayer()) { _ = false }
    point.trigger(leaderboardID: "b", playerScope: .global, timeScope: .allTime) { _ = false }
    let definition = GKGameActivityDefinition()
    let activity = GKGameActivity(definition: definition)
    point.trigger(gameActivity: activity, handler: { _ = false })
    point.trigger(gameActivityDefinitionID: "id", handler: { _ = false })
    precondition(!point.isPresentingGameCenter)
}

func testGKConstantsAndNotifications() {
    precondition(GKTurnTimeoutDefault == 60 * 60 * 24 * 7)
    precondition(GKTurnTimeoutNone == 0)
    precondition(GKExchangeTimeoutDefault == 60 * 60 * 24)
    precondition(GKExchangeTimeoutNone == 0)
    precondition(GKPlayerIDNoLongerAvailable == "/unavailable")
    precondition(GKSessionErrorDomain == "GKSessionErrorDomain")
    precondition(GKVoiceChatServiceErrorDomain == "GKVoiceChatServiceErrorDomain")
    precondition(
        NSNotification.Name.GKPlayerAuthenticationDidChangeNotificationName.rawValue
            == "GKPlayerAuthenticationDidChangeNotificationName"
    )
    precondition(
        NSNotification.Name.GKPlayerDidChangeNotificationName.rawValue
            == "GKPlayerDidChangeNotificationName"
    )
}
