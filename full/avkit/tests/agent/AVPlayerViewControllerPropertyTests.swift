import Foundation
import AVKit

func testPlayerViewControllerClassConstructs() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        _ = controller.view
        precondition(controller.player == nil)
    }
}

func testPlayerViewControllerMediaCharacteristicsForSupportedCustomMediaSelectionSchemes() {
    avkitOnMain {
        let schemes = AVPlayerViewController.mediaCharacteristicsForSupportedCustomMediaSelectionSchemes
        precondition(schemes.isEmpty)
    }
}

func testPlayerViewControllerSelectSpeedIdentity() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer()
        let listed = AVPlaybackSpeed.systemDefaultSpeeds[0]
        controller.selectSpeed(listed)
        precondition(controller.selectedSpeed === listed)
        precondition(controller.player?.defaultRate == 2.0)
        let outsider = AVPlaybackSpeed(rate: 9.5, localizedName: "outsider")
        controller.selectSpeed(outsider)
        precondition(controller.selectedSpeed === listed)
    }
}

func testPlayerViewControllerAllowsPictureInPicturePlayback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.allowsPictureInPicturePlayback == true)
        controller.allowsPictureInPicturePlayback = false
        precondition(controller.allowsPictureInPicturePlayback == false)
    }
}

func testPlayerViewControllerAllowsVideoFrameAnalysis() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.allowsVideoFrameAnalysis == true)
        controller.allowsVideoFrameAnalysis = false
        precondition(controller.allowsVideoFrameAnalysis == false)
    }
}

func testPlayerViewControllerCanStartPictureInPictureAutomaticallyFromInline() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.canStartPictureInPictureAutomaticallyFromInline == false)
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        precondition(controller.canStartPictureInPictureAutomaticallyFromInline == true)
    }
}

func testPlayerViewControllerContentOverlayViewPlaceholder() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let overlay = controller.contentOverlayView
        precondition(overlay != nil)
        precondition(overlay?.frame == .zero)
        precondition(controller.contentOverlayView === overlay)
    }
}

func testPlayerViewControllerDelegateStorage() {
    avkitOnMain {
        final class Probe: NSObject, AVPlayerViewControllerDelegate {}
        let controller = AVPlayerViewController()
        let probe = Probe()
        controller.delegate = probe
        precondition(controller.delegate === probe)
        controller.delegate = nil
        precondition(controller.delegate == nil)
    }
}

func testPlayerViewControllerEntersFullScreenWhenPlaybackBegins() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.entersFullScreenWhenPlaybackBegins == false)
        controller.entersFullScreenWhenPlaybackBegins = true
        precondition(controller.entersFullScreenWhenPlaybackBegins == true)
    }
}

func testPlayerViewControllerExitsFullScreenWhenPlaybackEnds() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.exitsFullScreenWhenPlaybackEnds == false)
        controller.exitsFullScreenWhenPlaybackEnds = true
        precondition(controller.exitsFullScreenWhenPlaybackEnds == true)
    }
}

func testPlayerViewControllerPixelBufferAttributes() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.pixelBufferAttributes == nil)
        controller.pixelBufferAttributes = ["probe": 1]
        precondition((controller.pixelBufferAttributes?["probe"] as? Int) == 1)
    }
}

func testPlayerViewControllerPlayerAssignmentSelectsSpeed() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.player == nil)
        let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/clip.m4v"))
        player.defaultRate = 1.5
        controller.player = player
        precondition(controller.player === player)
        precondition(controller.selectedSpeed?.rate == 1.5)
        controller.player = nil
        precondition(controller.player == nil)
    }
}

func testPlayerViewControllerPreferredDisplayDynamicRange() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.preferredDisplayDynamicRange == .automatic)
        controller.preferredDisplayDynamicRange = .high
        precondition(controller.preferredDisplayDynamicRange == .high)
    }
}

func testPlayerViewControllerIsReadyForDisplayFromPlayerItem() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.isReadyForDisplay == false)
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openavkit-ready.m4v"))
        controller.player = AVPlayer(playerItem: item)
        precondition(controller.isReadyForDisplay == false)
        item.openUIKitHostSetPresentationSize(CGSize(width: 1920, height: 1080))
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == true)
        item.status = .failed
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == false)
    }
}

func testPlayerViewControllerRequiresLinearPlayback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.requiresLinearPlayback == false)
        controller.requiresLinearPlayback = true
        precondition(controller.requiresLinearPlayback == true)
    }
}

func testPlayerViewControllerSelectedSpeedDefault() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let normal = AVPlaybackSpeed.systemDefaultSpeeds.first(where: { $0.rate == 1.0 })
        precondition(controller.selectedSpeed === normal)
    }
}

func testPlayerViewControllerShowsPlaybackControls() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.showsPlaybackControls == true)
        controller.showsPlaybackControls = false
        precondition(controller.showsPlaybackControls == false)
    }
}

func testPlayerViewControllerShowsTimecodes() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.showsTimecodes == false)
        controller.showsTimecodes = true
        precondition(controller.showsTimecodes == true)
    }
}

func testPlayerViewControllerSpeedsAreSystemDefault() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.speeds.count == 5)
        precondition(controller.speeds[0] === AVPlaybackSpeed.systemDefaultSpeeds[0])
        let custom = [AVPlaybackSpeed(rate: 3, localizedName: "custom")]
        controller.speeds = custom
        precondition(controller.speeds[0] === custom[0])
    }
}

func testPlayerViewControllerToggleLookupAction() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let action = controller.toggleLookupAction
        _ = action
        precondition(controller.toggleLookupAction === action)
    }
}

func testPlayerViewControllerUpdatesNowPlayingInfoCenter() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.updatesNowPlayingInfoCenter == true)
        controller.updatesNowPlayingInfoCenter = false
        precondition(controller.updatesNowPlayingInfoCenter == false)
    }
}

func testPlayerViewControllerVideoBoundsFromPresentationSize() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.videoBounds == .zero)
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openavkit-bounds.m4v"))
        controller.player = AVPlayer(playerItem: item)
        item.openUIKitHostSetPresentationSize(CGSize(width: 1280, height: 720))
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.videoBounds == CGRect(x: 0, y: 0, width: 1280, height: 720))
        controller.player = nil
        precondition(controller.videoBounds == .zero)
    }
}

func testPlayerViewControllerVideoFrameAnalysisTypes() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.videoFrameAnalysisTypes == .default)
        controller.videoFrameAnalysisTypes = .text
        precondition(controller.videoFrameAnalysisTypes == .text)
    }
}

func testPlayerViewControllerVideoGravity() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.videoGravity == .resizeAspect)
        controller.videoGravity = .resizeAspectFill
        precondition(controller.videoGravity == .resizeAspectFill)
    }
}
