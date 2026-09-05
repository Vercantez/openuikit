import Foundation
import AVKit

private final class SampleBufferPlaybackProbe: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
    var renderSize: CMVideoDimensions?
    var playing: Bool?
    var pausedQuery = 0
    var prohibitQuery = 0
    var timeRangeQuery = 0

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        _ = pictureInPictureController
        renderSize = newRenderSize
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        _ = pictureInPictureController
        self.playing = playing
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
        pausedQuery += 1
        return true
    }

    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        _ = pictureInPictureController
        prohibitQuery += 1
        return true
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        _ = pictureInPictureController
        timeRangeQuery += 1
        return .zero
    }
}

func testPictureInPictureSampleBufferPlaybackDelegateDispatch() {
    let playback = SampleBufferPlaybackProbe()
    let sample = AVSampleBufferDisplayLayer()
    let source = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: sample,
        playbackDelegate: playback
    )
    precondition(source.sampleBufferDisplayLayer === sample)
    precondition(source.sampleBufferPlaybackDelegate === playback)
    let controller = AVPictureInPictureController(contentSource: source)
    controller.openUIKitHostInvokeSampleBufferPlaybackDelegate()
    precondition(playback.renderSize?.width == 0)
    precondition(playback.renderSize?.height == 0)
    precondition(playback.playing == false)
    precondition(playback.pausedQuery == 1)
    precondition(playback.prohibitQuery == 1)
    precondition(playback.timeRangeQuery == 1)
}
