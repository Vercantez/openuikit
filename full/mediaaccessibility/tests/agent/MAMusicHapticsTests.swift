import Foundation
import MediaAccessibility

func testMusicHapticsManagerSharedIsInactive() {
    let manager = MAMusicHapticsManager.shared
    precondition(manager === MAMusicHapticsManager.shared)
    precondition(manager.isActive == false)
}

func testMusicHapticsManagerActiveStatusNotification() {
    precondition(
        MAMusicHapticsManager.activeStatusDidChangeNotification.rawValue
            == "MAMusicHapticsManagerActiveStatusDidChangeNotification"
    )
}

func testMusicHapticsEnabledStatusDidChangeNotification() {
    let value = MAMusicHaptics()
    _ = value
    precondition(
        MAMusicHaptics.enabledStatusDidChangeNotification.rawValue
            == "MAMusicHapticsEnabledStatusDidChangeNotification"
    )
    precondition(MAMusicHaptics() == MAMusicHaptics())
}

func testMusicHapticsManagerCheckAvailabilityFailClosed() {
    final class Box: @unchecked Sendable {
        var invoked = false
        var available = true
    }
    let state = Box()
    MAMusicHapticsManager.shared.checkHapticTrackAvailabilityForMedia(
        matchingCode: "USRC17607839"
    ) { value in
        state.invoked = true
        state.available = value
    }
    precondition(state.invoked)
    precondition(state.available == false)

    MAMusicHapticsManager.shared.checkHapticTrackAvailabilityForMedia(
        matchingCode: "USRC17607839",
        completionHandler: nil
    )
}

func testMusicHapticsManagerStatusObserverRoundTrip() {
    final class Box: @unchecked Sendable {
        var fired = false
    }
    let state = Box()
    let token = MAMusicHapticsManager.shared.addStatusObserver { _, _ in
        state.fired = true
    }
    precondition(token != nil)
    if let token {
        MAMusicHapticsManager.shared.removeStatusObserver(token)
    }
    precondition(state.fired == false)
}
