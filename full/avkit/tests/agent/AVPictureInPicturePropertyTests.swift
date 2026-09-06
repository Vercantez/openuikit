import Foundation
import AVKit

func testPictureInPictureControllerClassUnsupported() {
    precondition(AVPictureInPictureController.isPictureInPictureSupported() == false)
}

func testPictureInPictureIsPictureInPictureSupported() {
    precondition(AVPictureInPictureController.isPictureInPictureSupported() == false)
}

func testPictureInPictureButtonStartImageCompatibleWithTraitCollection() {
    let traits = UITraitCollection()
    let image = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: traits)
    _ = image
    let nilTraits = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
    _ = nilTraits
}

func testPictureInPictureButtonStopImageCompatibleWithTraitCollection() {
    let traits = UITraitCollection()
    let image = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: traits)
    _ = image
    let nilTraits = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil)
    _ = nilTraits
}

func testPictureInPictureButtonStartImage() {
    let image = AVPictureInPictureController.pictureInPictureButtonStartImage
    _ = image
}

func testPictureInPictureButtonStopImage() {
    let image = AVPictureInPictureController.pictureInPictureButtonStopImage
    _ = image
}

func testPictureInPictureInitContentSource() {
    let layer = AVPlayerLayer()
    let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.contentSource === source)
}

func testPictureInPictureInitPlayerLayerReturnsNil() {
    let controller = AVPictureInPictureController(playerLayer: AVPlayerLayer())
    precondition(controller == nil)
}

func testPictureInPictureInvalidatePlaybackState() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    controller.invalidatePlaybackState()
    precondition(controller.isPictureInPictureActive == false)
}

func testPictureInPictureStartPictureInPictureFailsClosed() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    controller.startPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
}

func testPictureInPictureStopPictureInPictureInactiveIsSilent() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    controller.stopPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
}

func testPictureInPictureCanStartAutomaticallyFromInline() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.canStartPictureInPictureAutomaticallyFromInline == false)
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    precondition(controller.canStartPictureInPictureAutomaticallyFromInline == true)
}

func testPictureInPictureContentSourceProperty() {
    let first = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: first)
    precondition(controller.contentSource === first)
    let second = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    controller.contentSource = second
    precondition(controller.contentSource === second)
}

func testPictureInPictureDelegateProperty() {
    final class Probe: NSObject, AVPictureInPictureControllerDelegate {}
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    let probe = Probe()
    controller.delegate = probe
    precondition(controller.delegate === probe)
}

func testPictureInPictureIsPictureInPictureActive() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.isPictureInPictureActive == false)
    controller.startPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
}

func testPictureInPictureIsPictureInPicturePossible() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.isPictureInPicturePossible == false)
    controller.startPictureInPicture()
    precondition(controller.isPictureInPicturePossible == false)
}

func testPictureInPictureIsPictureInPictureSuspended() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.isPictureInPictureSuspended == false)
    controller.startPictureInPicture()
    controller.stopPictureInPicture()
    precondition(controller.isPictureInPictureSuspended == false)
}

func testPictureInPicturePlayerLayerProperty() {
    let layer = AVPlayerLayer()
    let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.playerLayer === layer)
}

func testPictureInPictureRequiresLinearPlayback() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.requiresLinearPlayback == false)
    controller.requiresLinearPlayback = true
    precondition(controller.requiresLinearPlayback == true)
}

func testPictureInPictureContentSourceClass() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    _ = source
}

func testPictureInPictureContentSourceInitActiveVideoCall() {
    let host = UIView(frame: .zero)
    let call = AVPictureInPictureVideoCallViewController()
    let source = AVPictureInPictureController.ContentSource(
        activeVideoCallSourceView: host,
        contentViewController: call
    )
    precondition(source.activeVideoCallSourceView === host)
    precondition(source.activeVideoCallContentViewController === call)
}

func testPictureInPictureContentSourceInitPlayerLayer() {
    let layer = AVPlayerLayer()
    let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
    precondition(source.playerLayer === layer)
}

func testPictureInPictureContentSourceInitSampleBuffer() {
    final class Playback: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            didTransitionToRenderSize newRenderSize: CMVideoDimensions
        ) {
            _ = (pictureInPictureController, newRenderSize)
        }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            setPlaying playing: Bool
        ) {
            _ = (pictureInPictureController, playing)
        }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            skipByInterval skipInterval: CMTime
        ) async {
            _ = (pictureInPictureController, skipInterval)
        }
        func pictureInPictureControllerIsPlaybackPaused(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> Bool {
            _ = pictureInPictureController
            return true
        }
        func pictureInPictureControllerTimeRangeForPlayback(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> CMTimeRange {
            _ = pictureInPictureController
            return .zero
        }
    }
    let playback = Playback()
    let sample = AVSampleBufferDisplayLayer()
    let source = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: sample,
        playbackDelegate: playback
    )
    precondition(source.sampleBufferDisplayLayer === sample)
    precondition(source.sampleBufferPlaybackDelegate === playback)
}

func testPictureInPictureContentSourceActiveVideoCallContentViewController() {
    let call = AVPictureInPictureVideoCallViewController()
    let source = AVPictureInPictureController.ContentSource(
        activeVideoCallSourceView: UIView(frame: .zero),
        contentViewController: call
    )
    precondition(source.activeVideoCallContentViewController === call)
}

func testPictureInPictureContentSourceActiveVideoCallSourceView() {
    let host = UIView(frame: .zero)
    let source = AVPictureInPictureController.ContentSource(
        activeVideoCallSourceView: host,
        contentViewController: AVPictureInPictureVideoCallViewController()
    )
    precondition(source.activeVideoCallSourceView === host)
}

func testPictureInPictureContentSourcePlayerLayer() {
    let layer = AVPlayerLayer()
    let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
    precondition(source.playerLayer === layer)
}

func testPictureInPictureContentSourceSampleBufferDisplayLayer() {
    final class Playback: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            didTransitionToRenderSize newRenderSize: CMVideoDimensions
        ) { _ = (pictureInPictureController, newRenderSize) }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            setPlaying playing: Bool
        ) { _ = (pictureInPictureController, playing) }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            skipByInterval skipInterval: CMTime
        ) async { _ = (pictureInPictureController, skipInterval) }
        func pictureInPictureControllerIsPlaybackPaused(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> Bool { _ = pictureInPictureController; return true }
        func pictureInPictureControllerTimeRangeForPlayback(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> CMTimeRange { _ = pictureInPictureController; return .zero }
    }
    let sample = AVSampleBufferDisplayLayer()
    let source = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: sample,
        playbackDelegate: Playback()
    )
    precondition(source.sampleBufferDisplayLayer === sample)
}

func testPictureInPictureContentSourceSampleBufferPlaybackDelegate() {
    final class Playback: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            didTransitionToRenderSize newRenderSize: CMVideoDimensions
        ) { _ = (pictureInPictureController, newRenderSize) }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            setPlaying playing: Bool
        ) { _ = (pictureInPictureController, playing) }
        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            skipByInterval skipInterval: CMTime
        ) async { _ = (pictureInPictureController, skipInterval) }
        func pictureInPictureControllerIsPlaybackPaused(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> Bool { _ = pictureInPictureController; return true }
        func pictureInPictureControllerTimeRangeForPlayback(
            _ pictureInPictureController: AVPictureInPictureController
        ) -> CMTimeRange { _ = pictureInPictureController; return .zero }
    }
    let playback = Playback()
    let source = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: AVSampleBufferDisplayLayer(),
        playbackDelegate: playback
    )
    precondition(source.sampleBufferPlaybackDelegate === playback)
}

func testPictureInPictureVideoCallViewControllerConstructs() {
    let controller = AVPictureInPictureVideoCallViewController()
    _ = controller
}
