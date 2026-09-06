import Foundation
import AVKit

private final class PictureInPictureMethodProbe: NSObject, AVPictureInPictureControllerDelegate {
    var events: [String] = []
    var startError: (any Error)?
    var restored: Bool?

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

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = pictureInPictureController
        restored = false
        completionHandler(false)
    }
}

private func makeController() -> AVPictureInPictureController {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    return AVPictureInPictureController(contentSource: source)
}

func testPictureInPictureControllerDelegateProtocolConformance() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    let typed: (any AVPictureInPictureControllerDelegate)? = controller.delegate
    precondition(typed === probe)
}

func testPictureInPictureControllerFailedToStartWithError() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.startPictureInPicture()
    precondition(probe.events == ["failedToStart"])
    let nsError = probe.startError as NSError?
    precondition(nsError?.domain == AVKitErrorDomain)
    precondition(nsError?.code == AVKitError.Code.pictureInPictureStartFailed.rawValue)
}

func testPictureInPictureControllerDidStartPictureInPicture() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
    precondition(probe.events.contains("didStart"))
}

func testPictureInPictureControllerDidStopPictureInPicture() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
    precondition(probe.events.last == "didStop")
}

func testPictureInPictureControllerWillStartPictureInPicture() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
    precondition(probe.events.first == "willStart")
}

func testPictureInPictureControllerWillStopPictureInPicture() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverPictureInPictureDelegateSequence(failedToStart: false)
    precondition(probe.events.contains("willStop"))
}

func testPictureInPictureRestoreUserInterfaceCompletionHandler() {
    let controller = makeController()
    let probe = PictureInPictureMethodProbe()
    controller.delegate = probe
    controller.openUIKitHostDeliverRestoreUserInterfaceForPictureInPictureStop()
    precondition(probe.restored == false)
}
