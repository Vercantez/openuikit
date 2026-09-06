import Foundation
import AVKit

private final class SampleBufferMethodProbe: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
    var renderSize: CMVideoDimensions?
    var playing: Bool?
    var pausedQuery = 0
    var prohibitQuery = 0
    var timeRangeQuery = 0
    var skipInterval: CMTime?
    var skipCompletions = 0

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

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completionHandler: @escaping () -> Void
    ) {
        _ = pictureInPictureController
        self.skipInterval = skipInterval
        skipCompletions += 1
        completionHandler()
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

private func makeSampleController(
    _ playback: SampleBufferMethodProbe
) -> AVPictureInPictureController {
    let source = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: AVSampleBufferDisplayLayer(),
        playbackDelegate: playback
    )
    return AVPictureInPictureController(contentSource: source)
}

func testPictureInPictureSampleBufferPlaybackDelegateProtocol() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    let typed: (any AVPictureInPictureSampleBufferPlaybackDelegate)? =
        controller.contentSource?.sampleBufferPlaybackDelegate
    precondition(typed === playback)
}

func testPictureInPictureDidTransitionToRenderSize() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    controller.openUIKitHostInvokeSampleBufferDidTransitionToRenderSize(width: 640, height: 360)
    precondition(playback.renderSize?.width == 640)
    precondition(playback.renderSize?.height == 360)
}

func testPictureInPictureSetPlaying() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    controller.openUIKitHostInvokeSampleBufferSetPlaying(true)
    precondition(playback.playing == true)
    controller.openUIKitHostInvokeSampleBufferSetPlaying(false)
    precondition(playback.playing == false)
}

func testPictureInPictureIsPlaybackPaused() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    let paused = controller.openUIKitHostQuerySampleBufferIsPlaybackPaused()
    precondition(paused == true)
    precondition(playback.pausedQuery == 1)
}

func testPictureInPictureShouldProhibitBackgroundAudioPlayback() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    let prohibit = controller.openUIKitHostQuerySampleBufferShouldProhibitBackgroundAudioPlayback()
    precondition(prohibit == true)
    precondition(playback.prohibitQuery == 1)
}

func testPictureInPictureTimeRangeForPlayback() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    let range = controller.openUIKitHostQuerySampleBufferTimeRangeForPlayback()
    precondition(range == .zero)
    precondition(playback.timeRangeQuery == 1)
}

func testPictureInPictureSkipByIntervalCompletionHandler() {
    let playback = SampleBufferMethodProbe()
    let controller = makeSampleController(playback)
    let interval = CMTime(value: 15, timescale: 1)
    controller.openUIKitHostInvokeSkipByInterval(interval)
    precondition(playback.skipCompletions == 1)
    precondition(playback.skipInterval?.value == 15)
    precondition(playback.skipInterval?.timescale == 1)
}
