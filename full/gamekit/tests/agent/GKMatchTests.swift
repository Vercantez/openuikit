import Foundation
import GameKit

func testGKMatchRequestProperties() {
    let request = GKMatchRequest()
    precondition(request.minPlayers == 2)
    precondition(request.maxPlayers == 4)
    precondition(request.defaultNumberOfPlayers == 2)
    request.minPlayers = 3
    request.maxPlayers = 8
    request.defaultNumberOfPlayers = 4
    request.playerGroup = 12
    request.playerAttributes = 0xFF
    request.inviteMessage = "join"
    request.playersToInvite = ["a"]
    request.recipients = [GKPlayer()]
    request.properties = ["map": "forest"]
    request.queueName = "ranked"
    request.restrictToAutomatch = true
    precondition(request.minPlayers == 3)
    precondition(request.maxPlayers == 8)
    precondition(request.defaultNumberOfPlayers == 4)
    precondition(request.playerGroup == 12)
    precondition(request.playerAttributes == 0xFF)
    precondition(request.inviteMessage == "join")
    precondition(request.playersToInvite == ["a"])
    precondition(request.recipients?.count == 1)
    precondition(request.properties?["map"] as? String == "forest")
    precondition(request.queueName == "ranked")
    precondition(request.restrictToAutomatch)
    request.inviteeResponseHandler = { _, _ in }
    request.recipientResponseHandler = { _, _ in }
    _ = request.inviteeResponseHandler
    _ = request.recipientResponseHandler
    _ = request.recipientProperties
    precondition(GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer) == 4)
    precondition(GKMatchRequest.maxPlayersAllowedForMatch(of: .hosted) == 16)
    precondition(GKMatchRequest.maxPlayersAllowedForMatch(of: .turnBased) == 16)
}

func testGKMatchFailClosed() {
    let match = GKMatch()
    precondition(match.expectedPlayerCount == 0)
    precondition(match.players.isEmpty)
    precondition(match.playerIDs?.isEmpty ?? true)
    match.delegate = nil
    _ = match.properties
    _ = match.playerProperties
    var host: String? = "keep"
    match.chooseBestHostPlayer { value in host = value }
    precondition(host == nil)
    var hostPlayer: GKPlayer? = GKPlayer()
    match.chooseBestHostingPlayer { value in hostPlayer = value }
    precondition(hostPlayer == nil)
    var rematch: GKMatch? = match
    var rematchError: (any Error)?
    match.rematch { value, error in
        rematch = value
        rematchError = error
    }
    precondition(rematch == nil)
    precondition((rematchError as? GKError)?.code == .notAuthenticated)
    do {
        try match.send(Data([1]), to: [GKPlayer()], dataMode: .reliable)
        precondition(false)
    } catch let error as GKError {
        precondition(error.code == .matchNotConnected)
    } catch {
        precondition(false)
    }
    do {
        try match.send(Data([1]), toPlayers: ["x"], with: .unreliable)
        precondition(false)
    } catch let error as GKError {
        precondition(error.code == .matchNotConnected)
    } catch {
        precondition(false)
    }
    do {
        try match.sendData(toAllPlayers: Data([1]), with: .reliable)
        precondition(false)
    } catch let error as GKError {
        precondition(error.code == .matchNotConnected)
    } catch {
        precondition(false)
    }
    let chat = match.voiceChat(withName: "party")
    precondition(chat?.name == "party")
    match.disconnect()
    precondition(match.players.isEmpty)
}

func testGKMatchmakerFailClosed() {
    let maker = GKMatchmaker.shared()
    precondition(ObjectIdentifier(maker) == ObjectIdentifier(GKMatchmaker.shared()))
    maker.startBrowsingForNearbyPlayers(handler: { _, _ in })
    maker.startBrowsingForNearbyPlayers(reachableHandler: { _, _ in })
    maker.startGroupActivity { _ in }
    maker.stopBrowsingForNearbyPlayers()
    maker.stopGroupActivity()
    maker.cancel()
    maker.cancelInvite(toPlayer: "x")
    maker.cancelPendingInvite(to: GKPlayer())
    maker.finishMatchmaking(for: GKMatch())
    var activity = 99
    var error: (any Error)?
    maker.queryActivity { value, err in
        activity = value
        error = err
    }
    precondition(activity == 0)
    precondition((error as? GKError)?.code == .notAuthenticated)
    var hosted: [String]? = ["x"]
    maker.findPlayers(forHostedMatchRequest: GKMatchRequest()) { ids, err in
        hosted = ids
        error = err
    }
    precondition(hosted == nil)
}

func testGKInviteAndMatchedPlayers() {
    let invite = GKInvite()
    precondition(!invite.isHosted)
    precondition(invite.inviter.isEmpty)
    precondition(invite.playerAttributes == 0)
    precondition(invite.playerGroup == 0)
    _ = invite.sender
    let matched = GKMatchedPlayers()
    precondition(matched.players.isEmpty)
    precondition(matched.properties == nil)
    precondition(matched.playerProperties == nil)
}
