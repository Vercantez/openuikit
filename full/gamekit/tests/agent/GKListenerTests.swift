import Foundation
import GameKit

final class GKListenerProbe: GKGameActivityListener, GKMatchmakerViewControllerDelegate {
    var didFailError: (any Error)?
    var wasCancelled = false
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error) {
        _ = viewController
        didFailError = error
    }
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        _ = viewController
        wasCancelled = true
    }
}

func testGKListenerSyncCompletions() {
    let listener = GKListenerProbe()
    let player = GKPlayer()
    let activity = GKGameActivity(definition: GKGameActivityDefinition())
    var wantsToPlay = true
    listener.player(player, wantsToPlay: activity) { value in wantsToPlay = value }
    precondition(wantsToPlay == false)

    guard let controller = GKMatchmakerViewController(matchRequest: GKMatchRequest()) else {
        preconditionFailure("matchmaker controller should construct for the default request")
    }
    var properties: [String: Any]? = ["seed": true]
    listener.matchmakerViewController(controller, getMatchPropertiesForRecipient: player) { value in
        properties = value
    }
    precondition(properties?.isEmpty == true)
}
