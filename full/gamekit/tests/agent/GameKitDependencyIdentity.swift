import Foundation
import UIKit
import GameKit

/// Future clean-EC2 identity probe. Not compiled by the isolated host gate.
///
/// That run must build guest Foundation and UIKit first, compile GameKit
/// against their -I/-L paths, link this client, and execute it with
/// LD_LIBRARY_PATH so libGameKit.dylib loads.

_ = GKErrorDomain
_ = GKLocalPlayer.local.isAuthenticated
_ = GKAccessPoint.shared.isActive
_ = GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer)

let achievement = GKAchievement(identifier: "probe")
achievement.percentComplete = 100
precondition(achievement.isCompleted)

print("GAMEKIT_DEPENDENCY_IDENTITY_OK")
