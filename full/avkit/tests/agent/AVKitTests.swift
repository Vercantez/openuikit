import Dispatch
import Foundation
import AVKit

@MainActor
func testAVKitErrorDomain() {
    precondition(AVKitErrorDomain == "AVKitErrorDomain")
    precondition(AVKitError.errorDomain == AVKitErrorDomain)
    precondition(AVKitError._nsErrorDomain == AVKitErrorDomain)
}

@MainActor
func testAVKitErrorCodes() {
    precondition(AVKitError.Code.unknown.rawValue == -1000)
    precondition(AVKitError.Code.pictureInPictureStartFailed.rawValue == -1001)
    precondition(AVKitError.Code(rawValue: -1000) == .unknown)
    precondition(AVKitError.Code(rawValue: -1001) == .pictureInPictureStartFailed)
    precondition(AVKitError.Code(rawValue: 0) == nil)
    precondition(AVKitError.unknown == .unknown)
    precondition(AVKitError.pictureInPictureStartFailed == .pictureInPictureStartFailed)
}

@MainActor
func testAVKitErrorBridging() {
    let typed = AVKitError(.pictureInPictureStartFailed, userInfo: ["probe": "avkit"])
    let nsError = typed as NSError
    precondition(nsError.domain == AVKitErrorDomain)
    precondition(nsError.code == -1001)
    precondition(nsError.userInfo["probe"] as? String == "avkit")
    precondition(typed.code == .pictureInPictureStartFailed)
    precondition(typed.errorCode == -1001)
    precondition(AVKitError.pictureInPictureStartFailed ~= nsError)
    precondition(typed.hashValue == AVKitError(.pictureInPictureStartFailed, userInfo: ["other": 1]).hashValue)
    precondition(typed != AVKitError(.unknown))
}

@MainActor
func testPlatformSupportsAVKitCore() {
    precondition(PLATFORM_SUPPORTS_AVKITCORE == false)
}

@MainActor
func testVideoFrameAnalysisOptionSet() {
    precondition(AVVideoFrameAnalysisType.default.rawValue == 1 << 0)
    precondition(AVVideoFrameAnalysisType.text.rawValue == 1 << 1)
    precondition(AVVideoFrameAnalysisType.subject.rawValue == 1 << 2)
    precondition(AVVideoFrameAnalysisType.visualSearch.rawValue == 1 << 3)
    precondition(AVVideoFrameAnalysisType.machineReadableCode.rawValue == 1 << 4)
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(combined.contains(.text))
    precondition(combined.contains(.subject))
    precondition(!combined.contains(.visualSearch))
    precondition(combined.union(.visualSearch).contains(.visualSearch))
    precondition(AVVideoFrameAnalysisType().isEmpty)
}

@MainActor
func testDisplayDynamicRangeRawValues() {
    precondition(AVDisplayDynamicRange.automatic.rawValue == 0)
    precondition(AVDisplayDynamicRange.standard.rawValue == 1)
    precondition(AVDisplayDynamicRange.constrainedHigh.rawValue == 2)
    precondition(AVDisplayDynamicRange.high.rawValue == 3)
    precondition(AVDisplayDynamicRange.automatic != .high)
}

@MainActor
func testCaptureEventPhaseRawValues() {
    precondition(AVCaptureEventPhase.began.rawValue == 0)
    precondition(AVCaptureEventPhase.ended.rawValue == 1)
    precondition(AVCaptureEventPhase.cancelled.rawValue == 2)
}

@MainActor
func testRouteSelectionRawValues() {
    precondition(AVAudioSession.RouteSelection.none.rawValue == 0)
    precondition(AVAudioSession.RouteSelection.local.rawValue == 1)
    precondition(AVAudioSession.RouteSelection.external.rawValue == 2)
}

@MainActor
func testVideoPlayerNilCaption() {
    let video = VideoPlayer(player: nil)
    precondition(video.player == nil)
    precondition(video.openUIKitHostCaption == "No Video")
}

@MainActor
func testVideoPlayerPlayingCaption() {
    let url = URL(fileURLWithPath: "/tmp/clip.m4v")
    let player = AVPlayer(url: url)
    player.rate = 1
    let video = VideoPlayer(player: player)
    precondition(video.player === player)
    precondition(video.openUIKitHostCaption == "clip.m4v\nPlaying")
    player.rate = 0
    precondition(VideoPlayer(player: player).openUIKitHostCaption == "clip.m4v\nPaused")
}

@MainActor
func testVideoPlayerOverlayInit() {
    let player = AVPlayer()
    let video = VideoPlayer(player: player) {
        EmptyView()
    }
    precondition(video.player === player)
    _ = video.body
}

@MainActor
func testVideoPlayerViewModifiers() {
    let video = VideoPlayer(player: nil)
    _ = video.opacity(0.5)
    _ = video.padding(8)
    _ = video.disabled(true)
}

@MainActor
func testPictureInPictureUnsupported() {
    precondition(AVPictureInPictureController.isPictureInPictureSupported() == false)
    let layer = AVPlayerLayer()
    let controller = AVPictureInPictureController(playerLayer: layer)
    precondition(controller != nil)
    precondition(controller?.isPictureInPicturePossible == false)
    precondition(controller?.isPictureInPictureActive == false)
    precondition(controller?.isPictureInPictureSuspended == false)
}

@MainActor
func testPictureInPictureStartStaysInactive() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    controller.startPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
    precondition(controller.isPictureInPicturePossible == false)
    controller.stopPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
}

@MainActor
func testPlaybackSpeedStoresRate() {
    let speed = AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×")
    precondition(speed.rate == 1.5)
    precondition(speed.localizedName == "1.5×")
    precondition(speed.localizedNumericName.contains("1.5"))
    precondition(!AVPlaybackSpeed.systemDefaultSpeeds.isEmpty)
}

@MainActor
func testCaptureEventPlayFailsClosed() {
    let event = AVCaptureEvent()
    precondition(event.play(.cameraShutter) == false)
    precondition(event.shouldPlaySound == false)
}

@MainActor
func testCaptureEventSoundURLThrows() {
    do {
        _ = try AVCaptureEventSound(url: URL(fileURLWithPath: "/tmp/shutter.caf"))
        preconditionFailure("custom capture sound must fail closed")
    } catch let error as AVKitError {
        precondition(error.code == .unknown)
    } catch {
        let nsError = error as NSError
        precondition(nsError.domain == AVKitErrorDomain)
        precondition(nsError.code == AVKitError.Code.unknown.rawValue)
    }
}

@MainActor
func testCaptureEventInteractionStoresEnabled() {
    var sawEvent = false
    let interaction = AVCaptureEventInteraction { _ in sawEvent = true }
    precondition(interaction.isEnabled == true)
    interaction.isEnabled = false
    precondition(interaction.isEnabled == false)
    precondition(sawEvent == false)
    AVCaptureEventInteraction.defaultCaptureSoundDisabled = true
    precondition(AVCaptureEventInteraction.defaultCaptureSoundDisabled == true)
    AVCaptureEventInteraction.defaultCaptureSoundDisabled = false
}

@MainActor
func testPlayerViewControllerSelectSpeed() {
    let controller = AVPlayerViewController()
    let speed = AVPlaybackSpeed(rate: 2, localizedName: "2×")
    controller.player = AVPlayer()
    controller.selectSpeed(speed)
    precondition(controller.selectedSpeed === speed)
    precondition(controller.isReadyForDisplay == false)
    precondition(controller.showsPlaybackControls == true)
    precondition(controller.preferredDisplayDynamicRange == .automatic)
}

@MainActor
func testInputPickerPresentStaysClosed() {
    let picker = AVInputPickerInteraction()
    precondition(picker.isPresented == false)
    picker.present()
    precondition(picker.isPresented == false)
    picker.dismiss()
    precondition(picker.isPresented == false)
}

@MainActor
func testInterstitialTimeRangeIdentity() {
    let range = CMTimeRange(
        start: CMTime(value: 10, timescale: 1),
        duration: CMTime(value: 5, timescale: 1)
    )
    let interstitial = AVInterstitialTimeRange(timeRange: range)
    precondition(interstitial.timeRange.start.value == 10)
    precondition(interstitial.timeRange.duration.value == 5)
}

@MainActor
func testRoutePickerStoresPriorities() {
    let picker = AVRoutePickerView(frame: .zero)
    picker.prioritizesVideoDevices = true
    precondition(picker.prioritizesVideoDevices == true)
}

@MainActor
func testPrepareRouteSelectionCallback() {
    let session = AVAudioSession()
    let lock = NSLock()
    var called = 0
    var allowed = true
    var selection = AVAudioSession.RouteSelection.local
    let semaphore = DispatchSemaphore(value: 0)
    session.prepareRouteSelectionForPlayback { nextAllowed, nextSelection in
        lock.lock()
        called += 1
        allowed = nextAllowed
        selection = nextSelection
        lock.unlock()
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 2) == .success)
    lock.lock()
    precondition(called == 1)
    precondition(allowed == false)
    precondition(selection == .none)
    lock.unlock()
}
