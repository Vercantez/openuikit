import Foundation
import AVKit

private final class PictureInPictureOrderProbe: NSObject, AVPictureInPictureControllerDelegate {
    var events: [String] = []
    var startError: (any Error)?

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
        events.append("willStart")
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
        events.append("didStart")
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
        events.append("willStop")
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
        events.append("didStop")
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        _ = pictureInPictureController
        startError = error
        events.append("failedToStart")
    }
}

func testPictureInPictureDelegateOrder() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    let probe = PictureInPictureOrderProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
    precondition(probe.events == ["willStart", "didStart", "willStop", "didStop"])
    precondition(controller.isPictureInPictureActive == false)
    precondition(controller.isPictureInPictureSuspended == false)
    probe.events.removeAll()
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: true)
    precondition(probe.events == ["failedToStart"])
    let nsError = probe.startError as NSError?
    precondition(nsError?.domain == AVKitErrorDomain)
    precondition(nsError?.code == AVKitError.Code.pictureInPictureStartFailed.rawValue)
}

func testPictureInPictureButtonImages() {
    let start = AVPictureInPictureController.pictureInPictureButtonStartImage
    let stop = AVPictureInPictureController.pictureInPictureButtonStopImage
    _ = start
    _ = stop
    let traits = UITraitCollection()
    let startTrait = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: traits)
    let stopTrait = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: traits)
    _ = startTrait
    _ = stopTrait
    let nilTraitStart = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
    let nilTraitStop = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil)
    _ = nilTraitStart
    _ = nilTraitStop
}

func testPictureInPictureSuspendedStaysFalse() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.isPictureInPictureSuspended == false)
    controller.startPictureInPicture()
    precondition(controller.isPictureInPictureSuspended == false)
    controller.stopPictureInPicture()
    precondition(controller.isPictureInPictureSuspended == false)
}
