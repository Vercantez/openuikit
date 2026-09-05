import Dispatch
import Foundation
import AVKit

/// The sealed host runner calls `test*` from a nonisolated context. UIKit-shaped
/// AVKit types are `@MainActor`; hop via assumeIsolated on the process main thread.
private func avkitOnMain<T>(_ body: @MainActor () -> T) -> T {
    MainActor.assumeIsolated(body)
}

private final class PictureInPictureProbeDelegate: NSObject, AVPictureInPictureControllerDelegate {
    var events: [String] = []
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
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        _ = (pictureInPictureController, error)
        events.append("failedToStart")
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
}

private final class PictureInPictureSampleBufferProbe: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
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

private final class ProbeTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {}

private final class PlayerViewControllerProbeDelegate: NSObject, AVPlayerViewControllerDelegate {
    var events: [String] = []
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
        completionHandler(false)
    }
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = playerViewController
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

private final class RoutePickerProbeDelegate: NSObject, AVRoutePickerViewDelegate {
    var events: [String] = []
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
        events.append("willBegin")
    }
    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
        events.append("didEnd")
    }
}

private final class InputPickerProbeDelegate: NSObject, AVInputPickerInteraction.Delegate {
    var events: [String] = []
    func inputPickerInteractionWillBeginPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("willPresent")
    }
    func inputPickerInteractionDidEndPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("didPresent")
    }
    func inputPickerInteractionWillBeginDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("willDismiss")
    }
    func inputPickerInteractionDidEndDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("didDismiss")
    }
}

func testAVKitErrorDomain() {
    precondition(AVKitErrorDomain == "AVKitErrorDomain")
    precondition(AVKitError.errorDomain == AVKitErrorDomain)
    precondition(AVKitError._nsErrorDomain == AVKitErrorDomain)
}

func testAVKitErrorCodes() {
    precondition(AVKitError.Code.unknown.rawValue == -1000)
    precondition(AVKitError.Code.pictureInPictureStartFailed.rawValue == -1001)
    precondition(AVKitError.Code(rawValue: -1000) == .unknown)
    precondition(AVKitError.Code(rawValue: -1001) == .pictureInPictureStartFailed)
    precondition(AVKitError.Code(rawValue: 0) == nil)
    precondition(AVKitError.unknown == .unknown)
    precondition(AVKitError.pictureInPictureStartFailed == .pictureInPictureStartFailed)
}

func testAVKitErrorBridging() {
    let typed = AVKitError(.pictureInPictureStartFailed, userInfo: ["probe": "avkit"])
    let nsError = typed as NSError
    precondition(nsError.domain == AVKitErrorDomain)
    precondition(nsError.code == -1001)
    precondition(nsError.userInfo["probe"] as? String == "avkit")
    precondition(typed.code == .pictureInPictureStartFailed)
    precondition(typed.errorCode == -1001)
    precondition(AVKitError.Code.pictureInPictureStartFailed ~= (typed as any Error))
    precondition(!(AVKitError.Code.unknown ~= (typed as any Error)))
    precondition(typed.hashValue == AVKitError(.pictureInPictureStartFailed, userInfo: ["other": 1]).hashValue)
    precondition(typed != AVKitError(.unknown))
}

func testPlatformSupportsAVKitCore() {
    precondition(PLATFORM_SUPPORTS_AVKITCORE == false)
}

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

func testDisplayDynamicRangeRawValues() {
    precondition(AVDisplayDynamicRange.automatic.rawValue == 0)
    precondition(AVDisplayDynamicRange.standard.rawValue == 1)
    precondition(AVDisplayDynamicRange.constrainedHigh.rawValue == 2)
    precondition(AVDisplayDynamicRange.high.rawValue == 3)
    precondition(AVDisplayDynamicRange.automatic != .high)
}

func testCaptureEventPhaseRawValues() {
    precondition(AVCaptureEventPhase.began.rawValue == 0)
    precondition(AVCaptureEventPhase.ended.rawValue == 1)
    precondition(AVCaptureEventPhase.cancelled.rawValue == 2)
}

func testRouteSelectionRawValues() {
    precondition(AVAudioSession.RouteSelection.none.rawValue == 0)
    precondition(AVAudioSession.RouteSelection.local.rawValue == 1)
    precondition(AVAudioSession.RouteSelection.external.rawValue == 2)
}

func testVideoPlayerNilCaption() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        precondition(video.player == nil)
        precondition(video.openUIKitHostCaption == "No Video")
    }
}

func testVideoPlayerPlayingCaption() {
    avkitOnMain {
        let url = URL(fileURLWithPath: "/tmp/clip.m4v")
        let player = AVPlayer(url: url)
        player.rate = 1
        let video = VideoPlayer(player: player)
        precondition(video.player === player)
        precondition(video.openUIKitHostCaption == "clip.m4v\nPlaying")
        player.rate = 0
        precondition(VideoPlayer(player: player).openUIKitHostCaption == "clip.m4v\nPaused")
    }
}

func testVideoPlayerOverlayInit() {
    avkitOnMain {
        let player = AVPlayer()
        let video = VideoPlayer(player: player) {
            EmptyView()
        }
        precondition(video.player === player)
        _ = video.body
    }
}

func testVideoPlayerViewModifiers() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        _ = video.opacity(0.5)
        _ = video.padding(8)
        _ = video.disabled(true)
    }
}

func testPictureInPictureUnsupported() {
    precondition(AVPictureInPictureController.isPictureInPictureSupported() == false)
    let layer = AVPlayerLayer()
    // MEASURED OpenUIKit-Chrome-fw-avkit iPhone 16 / iOS 26.1: nil when unsupported.
    let controller = AVPictureInPictureController(playerLayer: layer)
    precondition(controller == nil)
}

func testPictureInPictureStartStaysInactive() {
    let source = AVPictureInPictureController.ContentSource(playerLayer: AVPlayerLayer())
    let controller = AVPictureInPictureController(contentSource: source)
    let probe = PictureInPictureProbeDelegate()
    controller.delegate = probe
    controller.startPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
    precondition(controller.isPictureInPicturePossible == false)
    precondition(probe.events.isEmpty)
    controller.stopPictureInPicture()
    precondition(controller.isPictureInPictureActive == false)
    precondition(probe.events.isEmpty)
}

func testPictureInPictureContentSourceStoresLayer() {
    let layer = AVPlayerLayer()
    let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
    precondition(source.playerLayer === layer)
    let controller = AVPictureInPictureController(contentSource: source)
    precondition(controller.contentSource === source)
    precondition(controller.canStartPictureInPictureAutomaticallyFromInline == false)
    precondition(controller.requiresLinearPlayback == false)
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.requiresLinearPlayback = true
    precondition(controller.canStartPictureInPictureAutomaticallyFromInline == true)
    precondition(controller.requiresLinearPlayback == true)
    controller.invalidatePlaybackState()
    _ = AVPictureInPictureController.pictureInPictureButtonStartImage
    _ = AVPictureInPictureController.pictureInPictureButtonStopImage
    _ = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
    _ = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil)
}

func testPictureInPictureSampleBufferAndVideoCallSources() {
    let playback = PictureInPictureSampleBufferProbe()
    let sample = AVSampleBufferDisplayLayer()
    let sampleSource = AVPictureInPictureController.ContentSource(
        sampleBufferDisplayLayer: sample,
        playbackDelegate: playback
    )
    precondition(sampleSource.sampleBufferDisplayLayer === sample)
    let host = UIView(frame: .zero)
    let call = AVPictureInPictureVideoCallViewController()
    let callSource = AVPictureInPictureController.ContentSource(
        activeVideoCallSourceView: host,
        contentViewController: call
    )
    precondition(callSource.activeVideoCallSourceView === host)
    precondition(callSource.activeVideoCallContentViewController === call)
}

func testPlaybackSpeedStoresRate() {
    let speed = AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×")
    precondition(speed.rate == 1.5)
    precondition(speed.localizedName == "1.5×")
    precondition(speed.localizedNumericName == "1.5\u{00D7}")
}

func testPlaybackSpeedSystemDefaultSpeeds() {
    // MEASURED OpenUIKit-Chrome-fw-avkit iPhone 16 / iOS 26.1 locale=en_US.
    let speeds = AVPlaybackSpeed.systemDefaultSpeeds
    precondition(speeds.count == 5)
    precondition(speeds[0].rate == 2.0)
    precondition(speeds[0].localizedName == "Double")
    precondition(speeds[0].localizedNumericName == "2\u{00D7}")
    precondition(speeds[1].rate == 1.5)
    precondition(speeds[1].localizedName == "Faster")
    precondition(speeds[1].localizedNumericName == "1.5\u{00D7}")
    precondition(speeds[2].rate == 1.25)
    precondition(speeds[2].localizedName == "Fast")
    precondition(speeds[2].localizedNumericName == "1.25\u{00D7}")
    precondition(speeds[3].rate == 1.0)
    precondition(speeds[3].localizedName == "Normal")
    precondition(speeds[3].localizedNumericName == "1\u{00D7}")
    precondition(speeds[4].rate == 0.5)
    precondition(speeds[4].localizedName == "Half")
    precondition(speeds[4].localizedNumericName == "0.5\u{00D7}")
    precondition(AVPlaybackSpeed.systemDefaultSpeeds[3] === speeds[3])
    let custom = AVPlaybackSpeed(rate: 3, localizedName: "custom")
    precondition(custom.localizedNumericName == "3\u{00D7}")
    let threeHalves = AVPlaybackSpeed(rate: 2.5, localizedName: "custom")
    precondition(threeHalves.localizedNumericName == "2.5\u{00D7}")
}

func testCaptureEventPlayFailsClosed() {
    let event = AVCaptureEvent()
    precondition(event.play(.cameraShutter) == false)
    precondition(event.shouldPlaySound == false)
}

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

func testCaptureEventInteractionStoresEnabled() {
    avkitOnMain {
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
}

func testPlayerViewControllerSelectSpeed() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let speed = AVPlaybackSpeed.systemDefaultSpeeds[0]
        controller.player = AVPlayer()
        controller.selectSpeed(speed)
        precondition(controller.selectedSpeed === speed)
        precondition(controller.player?.defaultRate == 2.0)
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.showsPlaybackControls == true)
        precondition(controller.preferredDisplayDynamicRange == .automatic)
    }
}

func testPlayerViewControllerMeasuredDefaults() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        // MEASURED OpenUIKit-Chrome-fw-avkit iPhone 16 / iOS 26.1.
        precondition(controller.showsPlaybackControls == true)
        precondition(controller.showsTimecodes == false)
        precondition(controller.videoGravity == .resizeAspect)
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == .zero)
        precondition(controller.contentOverlayView != nil)
        precondition(controller.allowsPictureInPicturePlayback == true)
        precondition(controller.allowsVideoFrameAnalysis == true)
        precondition(controller.videoFrameAnalysisTypes == .default)
        precondition(controller.canStartPictureInPictureAutomaticallyFromInline == false)
        precondition(controller.updatesNowPlayingInfoCenter == true)
        precondition(controller.entersFullScreenWhenPlaybackBegins == false)
        precondition(controller.exitsFullScreenWhenPlaybackEnds == false)
        precondition(controller.requiresLinearPlayback == false)
        precondition(controller.preferredDisplayDynamicRange == .automatic)
        precondition(controller.selectedSpeed === AVPlaybackSpeed.systemDefaultSpeeds[3])
        precondition(controller.speeds.count == 5)
        precondition(controller.speeds[0] === AVPlaybackSpeed.systemDefaultSpeeds[0])
        precondition(controller.player == nil)
        controller.allowsPictureInPicturePlayback = false
        controller.allowsVideoFrameAnalysis = false
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.requiresLinearPlayback = true
        controller.showsPlaybackControls = false
        controller.showsTimecodes = true
        controller.updatesNowPlayingInfoCenter = false
        controller.videoGravity = .resizeAspectFill
        controller.videoFrameAnalysisTypes = .text
        controller.pixelBufferAttributes = ["probe": 1]
        controller.preferredDisplayDynamicRange = .high
        precondition(controller.allowsPictureInPicturePlayback == false)
        precondition(controller.allowsVideoFrameAnalysis == false)
        precondition(controller.canStartPictureInPictureAutomaticallyFromInline == true)
        precondition(controller.entersFullScreenWhenPlaybackBegins == true)
        precondition(controller.exitsFullScreenWhenPlaybackEnds == true)
        precondition(controller.requiresLinearPlayback == true)
        precondition(controller.showsPlaybackControls == false)
        precondition(controller.showsTimecodes == true)
        precondition(controller.updatesNowPlayingInfoCenter == false)
        precondition(controller.videoGravity == .resizeAspectFill)
        precondition(controller.videoFrameAnalysisTypes == .text)
        precondition((controller.pixelBufferAttributes?["probe"] as? Int) == 1)
        precondition(controller.preferredDisplayDynamicRange == .high)
        _ = AVPlayerViewController.mediaCharacteristicsForSupportedCustomMediaSelectionSchemes
        _ = controller.toggleLookupAction
    }
}

func testPlayerViewControllerSelectSpeedIdentity() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let listed = AVPlaybackSpeed.systemDefaultSpeeds[3]
        precondition(controller.selectedSpeed === listed)
        let outsider = AVPlaybackSpeed(rate: 9.5, localizedName: "probe-outsider")
        controller.selectSpeed(outsider)
        precondition(controller.selectedSpeed === listed)
        let twin = AVPlaybackSpeed(rate: 1.0, localizedName: "Normal")
        controller.selectSpeed(twin)
        precondition(controller.selectedSpeed === listed)
        let faster = AVPlaybackSpeed.systemDefaultSpeeds[1]
        controller.selectSpeed(faster)
        precondition(controller.selectedSpeed === faster)
        let player = AVPlayer()
        player.defaultRate = 1.5
        let synced = AVPlayerViewController()
        synced.player = player
        precondition(synced.selectedSpeed?.rate == 1.5)
    }
}

func testPlayerViewControllerDelegateHooksExist() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = PlayerViewControllerProbeDelegate()
        controller.delegate = probe
        precondition(controller.delegate === probe)
        let range = AVInterstitialTimeRange(
            timeRange: CMTimeRange(start: .zero, duration: .zero)
        )
        probe.playerViewController(controller, willPresent: range)
        probe.playerViewController(controller, didPresent: range)
        probe.playerViewController(controller, failedToStartPictureInPictureWithError: AVKitError(.pictureInPictureStartFailed))
        probe.playerViewControllerWillStartPictureInPicture(controller)
        probe.playerViewControllerDidStartPictureInPicture(controller)
        probe.playerViewControllerWillStopPictureInPicture(controller)
        probe.playerViewControllerDidStopPictureInPicture(controller)
        precondition(probe.playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(controller) == false)
        var restored = true
        probe.playerViewController(
            controller,
            restoreUserInterfaceForFullScreenExitWithCompletionHandler: { restored = $0 }
        )
        precondition(restored == false)
        restored = true
        probe.playerViewController(
            controller,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: { restored = $0 }
        )
        precondition(restored == false)
        let coordinator = ProbeTransitionCoordinator()
        probe.playerViewController(
            controller,
            willBeginFullScreenPresentationWithAnimationCoordinator: coordinator
        )
        probe.playerViewController(
            controller,
            willEndFullScreenPresentationWithAnimationCoordinator: coordinator
        )
        precondition(probe.events.count == 8)
    }
}

func testInputPickerPresentStaysClosed() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        precondition(picker.isPresented == false)
        picker.present()
        precondition(picker.isPresented == false)
        picker.dismiss()
        precondition(picker.isPresented == false)
    }
}

func testInterstitialTimeRangeIdentity() {
    let range = CMTimeRange(
        start: CMTime(value: 10, timescale: 1),
        duration: CMTime(value: 5, timescale: 1)
    )
    let interstitial = AVInterstitialTimeRange(timeRange: range)
    precondition(interstitial.timeRange.start.value == 10)
    precondition(interstitial.timeRange.duration.value == 5)
    let same = AVInterstitialTimeRange(timeRange: range)
    precondition(interstitial.isEqual(same))
    precondition(interstitial.hash == same.hash)
    let copy = interstitial.copy() as! AVInterstitialTimeRange
    precondition(copy.isEqual(interstitial))
    precondition(copy !== interstitial)
    precondition(AVInterstitialTimeRange.supportsSecureCoding == true)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: interstitial,
        requiringSecureCoding: true
    )
    let restored = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: AVInterstitialTimeRange.self,
        from: data
    )
    precondition(restored?.isEqual(interstitial) == true)
}

func testRoutePickerStoresPriorities() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        precondition(picker.prioritizesVideoDevices == false)
        picker.prioritizesVideoDevices = true
        precondition(picker.prioritizesVideoDevices == true)
        picker.activeTintColor = .white
        precondition(picker.activeTintColor != nil)
        let probe = RoutePickerProbeDelegate()
        picker.delegate = probe
        precondition(picker.delegate === probe)
        picker.customRoutingController = AVCustomRoutingController()
        precondition(picker.customRoutingController != nil)
        // Fail closed: no route sheet, so the delegate is not invoked.
        precondition(probe.events.isEmpty)
    }
}

func testInputPickerDelegateFailClosed() {
    avkitOnMain {
        let session = AVAudioSession()
        let picker = AVInputPickerInteraction(audioSession: session)
        precondition(picker.audioSession === session)
        let probe = InputPickerProbeDelegate()
        picker.delegate = probe
        picker.present()
        precondition(picker.isPresented == false)
        picker.dismiss()
        precondition(picker.isPresented == false)
        // Linux presents no UI; the stored delegate is still invoked with the
        // documented will/did pair so callers can observe the fail-closed path.
        precondition(probe.events.count == 4)
    }
}

func testCaptureEventPhaseAndSounds() {
    let event = AVCaptureEvent()
    precondition(event.phase == .ended)
    precondition(event.shouldPlaySound == false)
    _ = AVCaptureEventSound.beginVideoRecording
    _ = AVCaptureEventSound.endVideoRecording
    avkitOnMain {
        var primary = 0
        var secondary = 0
        let interaction = AVCaptureEventInteraction(
            primary: { _ in primary += 1 },
            secondary: { _ in secondary += 1 }
        )
        precondition(interaction.isEnabled == true)
        precondition(primary == 0)
        precondition(secondary == 0)
        let viaEventHandler = AVCaptureEventInteraction(eventHandler: { _ in })
        precondition(viaEventHandler.isEnabled == true)
        let viaPair = AVCaptureEventInteraction(
            primaryEventHandler: { _ in },
            secondaryEventHandler: { _ in }
        )
        precondition(viaPair.isEnabled == true)
    }
}

func testPlayerItemAVKitAdditions() {
    avkitOnMain {
        let item = AVPlayerItem()
        precondition(item.externalMetadata.isEmpty)
        item.externalMetadata = [AVMetadataItem()]
        precondition(item.externalMetadata.count == 1)
        precondition(item.interstitialTimeRanges.isEmpty)
        let range = AVInterstitialTimeRange(
            timeRange: CMTimeRange(start: .zero, duration: .zero)
        )
        item.interstitialTimeRanges = [range]
        precondition(item.interstitialTimeRanges.count == 1)
    }
}

func testVideoPlayerOnCameraCaptureEvent() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        _ = video.onCameraCaptureEvent { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: false) { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: true, primaryAction: { _ in }, secondaryAction: { _ in })
        _ = video.onCameraCaptureEvent(isEnabled: true, defaultSoundDisabled: true) { _ in }
    }
}

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
