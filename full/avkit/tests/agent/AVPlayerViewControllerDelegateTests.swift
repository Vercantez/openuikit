import Foundation
import AVKit

private final class RestoreProbeDelegate: NSObject, AVPlayerViewControllerDelegate {
    var fullScreenRestored: Bool?
    var pipRestored: Bool?
    var shouldDismiss = true
    var events: [String] = []

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForFullScreenExitWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = playerViewController
        fullScreenRestored = false
        completionHandler(false)
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = playerViewController
        pipRestored = false
        completionHandler(false)
    }

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
        _ playerViewController: AVPlayerViewController
    ) -> Bool {
        _ = playerViewController
        return shouldDismiss
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
        events.append("willPresent")
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
        events.append("didPresent")
    }
}

func testPlayerViewControllerInterstitialDelegateOrder() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = RestoreProbeDelegate()
        controller.delegate = probe
        let range = AVInterstitialTimeRange(
            timeRange: CMTimeRange(
                start: CMTime(value: 1, timescale: 1),
                duration: CMTime(value: 2, timescale: 1)
            )
        )
        controller.openUIKitHostDeliverInterstitialDelegatePair(range)
        precondition(probe.events == ["willPresent", "didPresent"])
    }
}

func testPlayerViewControllerRestoreCompletionsFailClosed() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = RestoreProbeDelegate()
        controller.delegate = probe
        controller.openUIKitHostDeliverRestoreCompletions()
        precondition(probe.fullScreenRestored == false)
        precondition(probe.pipRestored == false)
    }
}

func testPlayerViewControllerShouldAutomaticallyDismissQuery() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = RestoreProbeDelegate()
        controller.delegate = probe
        precondition(controller.openUIKitHostQueryShouldAutomaticallyDismissAtPictureInPictureStart() == true)
        probe.shouldDismiss = false
        precondition(controller.openUIKitHostQueryShouldAutomaticallyDismissAtPictureInPictureStart() == false)
    }
}
