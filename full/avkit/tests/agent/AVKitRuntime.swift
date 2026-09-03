import AVKit
import Foundation

/// Schema-v1-style runtime probe kept for the lane checklist. The sealed
/// schema-v2 gate compiles `*Tests.swift` and prints the load-smoke marker;
/// this file is not the host runner.
func avkitRuntimeProbe() {
    precondition(AVKitErrorDomain == "AVKitErrorDomain")
    precondition(PLATFORM_SUPPORTS_AVKITCORE == false)
    let player = AVPlayer()
    let video = VideoPlayer(player: player)
    precondition(video.openUIKitHostCaption == "No Video")
    _ = AVPictureInPictureController.isPictureInPictureSupported()
}

avkitRuntimeProbe()
print("AVKIT_AGENT_RUNTIME_OK")
