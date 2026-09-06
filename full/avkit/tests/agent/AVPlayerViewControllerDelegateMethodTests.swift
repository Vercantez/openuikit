import Foundation
import AVKit

private final class PlayerViewControllerMethodProbe: NSObject, AVPlayerViewControllerDelegate {
    var events: [String] = []
    var fullScreenRestored: Bool?
    var pipRestored: Bool?
    var shouldDismiss = true

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
        events.append("didPresent")
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        _ = (playerViewController, error)
        events.append("failedPiP")
    }

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

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        _ = (playerViewController, coordinator)
        events.append("willBeginFullScreen")
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        _ = (playerViewController, coordinator)
        events.append("willEndFullScreen")
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
        events.append("willPresent")
    }

    func playerViewControllerDidStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
        events.append("didStartPiP")
    }

    func playerViewControllerDidStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
        events.append("didStopPiP")
    }

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
        _ playerViewController: AVPlayerViewController
    ) -> Bool {
        _ = playerViewController
        return shouldDismiss
    }

    func playerViewControllerWillStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
        events.append("willStartPiP")
    }

    func playerViewControllerWillStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
        events.append("willStopPiP")
    }
}

private func makeRange() -> AVInterstitialTimeRange {
    AVInterstitialTimeRange(
        timeRange: CMTimeRange(
            start: CMTime(value: 1, timescale: 1),
            duration: CMTime(value: 2, timescale: 1)
        )
    )
}

func testPlayerViewControllerDelegateProtocolConformance() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        let typed: (any AVPlayerViewControllerDelegate)? = controller.delegate
        precondition(typed === probe)
    }
}

func testPlayerViewControllerDidPresentInterstitial() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverInterstitialDelegatePair(makeRange())
        precondition(probe.events.contains("didPresent"))
    }
}

func testPlayerViewControllerFailedToStartPictureInPictureWithError() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: true)
        precondition(probe.events == ["failedPiP"])
    }
}

func testPlayerViewControllerRestoreUserInterfaceForFullScreenExit() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverRestoreCompletions()
        precondition(probe.fullScreenRestored == false)
    }
}

func testPlayerViewControllerRestoreUserInterfaceForPictureInPictureStop() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverRestoreCompletions()
        precondition(probe.pipRestored == false)
    }
}

func testPlayerViewControllerWillBeginFullScreenPresentation() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverFullScreenDelegatePair()
        precondition(probe.events.first == "willBeginFullScreen")
    }
}

func testPlayerViewControllerWillEndFullScreenPresentation() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverFullScreenDelegatePair()
        precondition(probe.events.last == "willEndFullScreen")
    }
}

func testPlayerViewControllerWillPresentInterstitial() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverInterstitialDelegatePair(makeRange())
        precondition(probe.events.first == "willPresent")
    }
}

func testPlayerViewControllerDidStartPictureInPictureCallback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
        precondition(probe.events.contains("didStartPiP"))
    }
}

func testPlayerViewControllerDidStopPictureInPictureCallback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
        precondition(probe.events.last == "didStopPiP")
    }
}

func testPlayerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        precondition(controller.openUIKitHostQueryShouldAutomaticallyDismissAtPictureInPictureStart() == true)
        probe.shouldDismiss = false
        precondition(controller.openUIKitHostQueryShouldAutomaticallyDismissAtPictureInPictureStart() == false)
    }
}

func testPlayerViewControllerWillStartPictureInPictureCallback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
        precondition(probe.events.first == "willStartPiP")
    }
}

func testPlayerViewControllerWillStopPictureInPictureCallback() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerMethodProbe()
        controller.delegate = probe
        controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
        precondition(probe.events.contains("willStopPiP"))
    }
}
