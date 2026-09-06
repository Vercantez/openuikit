import Dispatch
import Foundation
@_spi(OpenUIKitHost) import AVFoundation

func testAVPlayerStatusAndTimeControl() {
    // Apple: empty player status is unknown until an item is ready; timeControlStatus
    // is paused / playing / waitingToPlayAtSpecifiedRate
    // (https://developer.apple.com/documentation/avfoundation/avplayer/timecontrolstatus-swift.property).
    let empty = AVPlayer()
    precondition(empty.status == .unknown)
    precondition(empty.timeControlStatus == .paused)
    precondition(empty.error == nil)
    precondition(AVPlayer.Status(rawValue: 0) == .unknown)
    precondition(AVPlayer.Status.readyToPlay.rawValue == 1)
    precondition(AVPlayer.Status.failed.rawValue == 2)
    precondition(AVPlayer.TimeControlStatus(rawValue: 0) == .paused)
    precondition(AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate.rawValue == 1)
    precondition(AVPlayer.TimeControlStatus.playing.rawValue == 2)
    precondition(AVPlayer.ActionAtItemEnd.advance.rawValue == 0)
    precondition(AVPlayer.ActionAtItemEnd.pause.rawValue == 1)
    precondition(AVPlayer.ActionAtItemEnd.none.rawValue == 2)

    let url = URL(fileURLWithPath: "/tmp/openav-status.mp4")
    let player = AVPlayer(url: url)
    precondition(player.status == .readyToPlay)
    precondition(player.timeControlStatus == .paused)
    precondition(player.automaticallyWaitsToMinimizeStalling)
    precondition(player.actionAtItemEnd == .advance)
    player.play()
    precondition(player.rate == 1)
    precondition(player.timeControlStatus == .playing)
    player.pause()
    precondition(player.timeControlStatus == .paused)
    player.playImmediately(atRate: 1.5)
    precondition(player.rate == 1.5)
    precondition(player.timeControlStatus == .playing)
    player.actionAtItemEnd = .pause
    precondition(player.actionAtItemEnd == .pause)
    player.automaticallyWaitsToMinimizeStalling = false
    precondition(!player.automaticallyWaitsToMinimizeStalling)
}

func testAVPlayerSeekCompletionAndTolerances() {
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-seek.mp4"))
    let time = CMTime(seconds: 1.25, preferredTimescale: 600)
    let finished = avfAwait { await player.seek(to: time) }
    switch finished {
    case .success(let ok):
        precondition(ok)
    default:
        preconditionFailure("state-only seek must complete")
    }
    precondition(abs(player.currentTime().seconds - 1.25) < 0.01)

    let seen = AVFLocked(false)
    player.seek(to: CMTime(seconds: 0.5, preferredTimescale: 600)) { ok in
        seen.store(ok)
    }
    precondition(seen.load())
    let tolerated = avfAwait {
        await player.seek(
            to: CMTime(seconds: 2, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
    switch tolerated {
    case .success(let ok):
        precondition(ok)
    default:
        preconditionFailure("tolerant seek must complete")
    }
    player.seek(to: CMTime(seconds: 3, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    let dateFinished = avfAwait { await player.seek(to: Date()) }
    switch dateFinished {
    case .success(let ok):
        precondition(!ok)
    default:
        preconditionFailure("date seek is fail-closed without a decoder")
    }
}

func testAVPlayerPeriodicAndBoundaryObservers() {
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-obs.mp4"))
    let asset = player.currentItem!.asset
    asset._portableInjectDuration(0.4)

    let periodicHits = AVFLocked(0)
    let periodic = DispatchSemaphore(value: 0)
    let periodicToken = player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
        queue: DispatchQueue.global()
    ) { _ in
        let n = periodicHits.load() + 1
        periodicHits.store(n)
        if n >= 2 { periodic.signal() }
    }
    player.play()
    precondition(periodic.wait(timeout: .now() + 2) == .success)
    player.removeTimeObserver(periodicToken)

    let boundaryHits = AVFLocked(0)
    let boundary = DispatchSemaphore(value: 0)
    player.seek(to: .zero)
    let boundaryToken = player.addBoundaryTimeObserver(
        forTimes: [AVCMTimeValue.nsValue(for: CMTime(seconds: 0.05, preferredTimescale: 600))],
        queue: DispatchQueue.global()
    ) {
        boundaryHits.store(boundaryHits.load() + 1)
        boundary.signal()
    }
    player.play()
    precondition(boundary.wait(timeout: .now() + 2) == .success)
    precondition(boundaryHits.load() >= 1)
    player.removeTimeObserver(boundaryToken)
    player.pause()
}

func testAVPlayerItemDidPlayToEndTime() {
    precondition(
        AVPlayerItem.didPlayToEndTimeNotification.rawValue
            == "AVPlayerItemDidPlayToEndTimeNotification"
    )
    precondition(
        Notification.Name.AVPlayerItemDidPlayToEndTime
            == AVPlayerItem.didPlayToEndTimeNotification
    )
    let url = URL(fileURLWithPath: "/tmp/openav-end.mp4")
    let item = AVPlayerItem(url: url)
    item.asset._portableInjectDuration(0.08)
    let player = AVPlayer(playerItem: item)
    let seen = AVFLocked(false)
    let sem = DispatchSemaphore(value: 0)
    let observer = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: item,
        queue: nil
    ) { _ in
        seen.store(true)
        sem.signal()
    }
    player.play()
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(seen.load())
    NotificationCenter.default.removeObserver(observer)
    precondition(player.timeControlStatus == .paused)
}

func testAVPlayerItemStateMachine() {
    let url = URL(fileURLWithPath: "/tmp/openav-item.mp4")
    let asset = AVURLAsset(url: url)
    let item = AVPlayerItem(asset: asset)
    precondition(item.status == .readyToPlay)
    precondition(item.error == nil)
    precondition(item.asset === asset)
    precondition(item.tracks.isEmpty)
    precondition(!item.duration.isValid)
    precondition(item.canPlayFastForward == false)
    item.seek(to: CMTime(seconds: 1, preferredTimescale: 600))
    precondition(abs(item.currentTime().seconds - 1) < 0.01)
    let seeked = avfAwait { await item.seek(to: CMTime(seconds: 2, preferredTimescale: 600)) }
    switch seeked {
    case .success(let ok):
        precondition(ok)
    default:
        preconditionFailure("item seek must complete")
    }
    item.cancelPendingSeeks()
    _ = item.accessLog()
    _ = item.errorLog()
    precondition(item.outputs.isEmpty)
    precondition(AVPlayerItem.Status(rawValue: 0) == .unknown)
    precondition(AVPlayerItem.Status.readyToPlay.rawValue == 1)
    precondition(AVPlayerItem.Status.failed.rawValue == 2)
}

func testAVAssetLoadFailClosed() {
    let url = URL(fileURLWithPath: "/tmp/openav-load.mp4")
    let asset = AVURLAsset(url: url)
    precondition(!asset.duration.isValid)
    precondition(!asset.isPlayable)
    precondition(asset.tracks.isEmpty)
    precondition(asset.metadata.isEmpty)
    let loaded = avfAwait { () async throws -> (CMTime, [AVAssetTrack], Bool) in
        try await asset.load(.duration, .tracks, .isPlayable)
    }
    switch loaded {
    case .success(let triple):
        precondition(!triple.0.isValid)
        precondition(triple.1.isEmpty)
        precondition(triple.2 == false)
    default:
        preconditionFailure("load must complete fail-closed, not throw")
    }
    let durationOnly = avfAwait { try await asset.load(.duration) }
    switch durationOnly {
    case .success(let time):
        precondition(!time.isValid)
    default:
        preconditionFailure("duration load must complete")
    }
    let metadata = avfAwait { try await asset.load(.metadata) }
    switch metadata {
    case .success(let items):
        precondition(items.isEmpty)
    default:
        preconditionFailure("metadata load must complete")
    }
    switch asset.status(of: .isPlayable) {
    case .loaded(let playable):
        precondition(playable == false)
    default:
        preconditionFailure("isPlayable should be loaded after load()")
    }
    switch asset.status(of: .lyrics) {
    case .notYetLoaded:
        break
    default:
        preconditionFailure("unloaded key must report notYetLoaded")
    }
    asset.loadValuesAsynchronously(forKeys: ["tracks"]) {}
    precondition(asset.statusOfValue(forKey: "tracks", error: nil) == .loaded)
    _ = avfAwait { await asset.loadValues(forKeys: ["duration"]) }
    let factory = AVAsset.asset(with: url)
    precondition((factory as? AVURLAsset)?.url == url)
}

func testAVQueuePlayerOrdering() {
    let a = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-a.mp4"))
    let b = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-b.mp4"))
    let queue = AVQueuePlayer(items: [a, b])
    precondition(queue.items().count == 2)
    precondition(queue.currentItem === a)
    precondition(queue.canInsert(b, after: a))
    queue.advanceToNextItem()
    precondition(queue.currentItem === b)
    precondition(queue.items().count == 1)
    queue.removeAllItems()
    precondition(queue.items().isEmpty)
    precondition(queue.currentItem == nil)
    let c = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-c.mp4"))
    precondition(queue.canInsert(c, after: nil))
    queue.insert(c, after: nil)
    precondition(queue.currentItem === c)
    queue.remove(c)
    precondition(queue.items().isEmpty)
}

func testAVPlayerLayerVideoGravity() {
    // Apple AVPlayerLayer.videoGravity default is ResizeAspect
    // (AVLayerVideoGravityResizeAspect). Linux has no decoded frame:
    // isReadyForDisplay is false and copyDisplayedPixelBuffer() is nil.
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-layer.mp4"))
    let layer = AVPlayerLayer.playerLayer(with: player)
    precondition(layer.player === player)
    precondition(layer.videoGravity == .resizeAspect)
    precondition(layer.videoGravity.rawValue == "AVLayerVideoGravityResizeAspect")
    layer.videoGravity = .resizeAspectFill
    precondition(layer.videoGravity == .resizeAspectFill)
    layer.videoGravity = .resize
    precondition(layer.videoGravity.rawValue == "AVLayerVideoGravityResize")
    precondition(!layer.isReadyForDisplay)
    precondition(layer.copyDisplayedPixelBuffer() == nil)
    precondition(layer.displayedReadOnlyPixelBuffer() == nil)
    layer.player = nil
    precondition(layer.player == nil)
}

func testAVLayerVideoGravityValues() {
    // Apple AVAnimation.h C-string constants AVLayerVideoGravityResizeAspect*.
    precondition(AVLayerVideoGravity.resizeAspect.rawValue == "AVLayerVideoGravityResizeAspect")
    precondition(AVLayerVideoGravity.resizeAspectFill.rawValue == "AVLayerVideoGravityResizeAspectFill")
    precondition(AVLayerVideoGravity.resize.rawValue == "AVLayerVideoGravityResize")
    precondition(AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspect") == .resizeAspect)
    precondition(AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResize") != .resizeAspectFill)
}

func testAVCaptureAuthorizationDenied() {
    // Apple AVAuthorizationStatus NS_ENUM: notDetermined=0, restricted=1,
    // denied=2, authorized=3. Linux has no capture hardware and no prompt,
    // so authorizationStatus is denied and requestAccess is false
    // (https://developer.apple.com/documentation/avfoundation/avcapturedevice/authorizationstatus(for:)).
    precondition(AVAuthorizationStatus(rawValue: 0) == .notDetermined)
    precondition(AVAuthorizationStatus.restricted.rawValue == 1)
    precondition(AVAuthorizationStatus.denied.rawValue == 2)
    precondition(AVAuthorizationStatus.authorized.rawValue == 3)
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    precondition(status == .denied)
    let granted = avfAwait { await AVCaptureDevice.requestAccess(for: .audio) }
    switch granted {
    case .success(let ok):
        precondition(!ok)
    default:
        preconditionFailure("requestAccess must deny on Linux")
    }
    precondition(AVCaptureDevice.devices().isEmpty)
    precondition(AVCaptureDevice.devices(for: .video).isEmpty)
    precondition(AVCaptureDevice.default(for: .video) == nil)
    let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera],
        mediaType: .video,
        position: .back
    )
    precondition(session.devices.isEmpty)
    precondition(session.supportedMultiCamDeviceSets.isEmpty)
}

func testAVCaptureSessionFailClosed() {
    let session = AVCaptureSession()
    precondition(!session.isRunning)
    session.startRunning()
    precondition(!session.isRunning, "no capture hardware: startRunning stays fail-closed")
    session.stopRunning()
    precondition(!session.canAddInput(AVCaptureInput()))
    precondition(!session.canAddOutput(AVCaptureOutput()))
    session.beginConfiguration()
    session.commitConfiguration()
    precondition(session.inputs.isEmpty)
    precondition(session.outputs.isEmpty)
    precondition(AVCaptureSession.Preset.high.rawValue == "high")
}

func testAVAudioSessionNoHardwareRoute() {
    // Extra portable surface (iOS 26.1 places AVAudioSession in AVFAudio).
    // Apple routeChangeNotification userInfo: AVAudioSessionRouteChangeReasonKey
    // and AVAudioSessionRouteChangePreviousRouteKey. categoryChange == 3.
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/routechangenotification
    // Interruption userInfo: AVAudioSessionInterruptionTypeKey, and on ended
    // AVAudioSessionInterruptionOptionKey.
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionnotification
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.ambient)
    let routeHits = AVFLocked(0)
    let routeReason = AVFLocked(UInt(0))
    let route = NotificationCenter.default.addObserver(
        forName: AVAudioSession.routeChangeNotification,
        object: session,
        queue: nil
    ) { note in
        routeHits.store(routeHits.load() + 1)
        let value = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber
        routeReason.store(value?.uintValue ?? 0)
        precondition(note.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] != nil)
    }
    do {
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
        try session.setActive(true)
        try session.setMode(.moviePlayback)
    } catch {
        preconditionFailure("portable session must not throw: \(error)")
    }
    NotificationCenter.default.removeObserver(route)
    precondition(session.category == .playAndRecord)
    precondition(session.mode == .moviePlayback)
    precondition(session.currentRoute.inputs.isEmpty)
    precondition(session.currentRoute.outputs.isEmpty)
    precondition(session.outputVolume == 0)
    precondition(routeHits.load() >= 1)
    precondition(routeReason.load() == AVAudioSession.RouteChangeReason.categoryChange.rawValue)
    precondition(AVAudioSession.interruptionNotification.rawValue == "AVAudioSessionInterruptionNotification")
    precondition(AVAudioSession.routeChangeNotification.rawValue == "AVAudioSessionRouteChangeNotification")
    precondition(AVAudioSessionInterruptionTypeKey == "AVAudioSessionInterruptionTypeKey")
    precondition(AVAudioSessionInterruptionOptionKey == "AVAudioSessionInterruptionOptionKey")
    precondition(AVAudioSessionRouteChangeReasonKey == "AVAudioSessionRouteChangeReasonKey")
    precondition(AVAudioSession.InterruptionType.began.rawValue == 1)
    precondition(AVAudioSession.InterruptionType.ended.rawValue == 0)
    precondition(AVAudioSession.InterruptionOptions.shouldResume.rawValue == 1)
    precondition(AVAudioSession.RouteChangeReason.categoryChange.rawValue == 3)

    let interruptHits = AVFLocked(0)
    let interruptType = AVFLocked(UInt(99))
    let interruptOptions = AVFLocked(UInt(0))
    let interrupt = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: session,
        queue: nil
    ) { note in
        interruptHits.store(interruptHits.load() + 1)
        let typeValue = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber
        interruptType.store(typeValue?.uintValue ?? 99)
        let optionValue = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber
        interruptOptions.store(optionValue?.uintValue ?? 0)
    }
    session._portablePostInterruption(type: .began)
    precondition(interruptHits.load() == 1)
    precondition(interruptType.load() == AVAudioSession.InterruptionType.began.rawValue)
    precondition(!session._portableState.isActive)
    session._portablePostInterruption(type: .ended, options: .shouldResume)
    NotificationCenter.default.removeObserver(interrupt)
    precondition(interruptHits.load() == 2)
    precondition(interruptType.load() == AVAudioSession.InterruptionType.ended.rawValue)
    precondition(interruptOptions.load() == AVAudioSession.InterruptionOptions.shouldResume.rawValue)
}

func testAVAudioPlayerSilentClock() {
    let url = URL(fileURLWithPath: "/tmp/openav-tone.m4a")
    guard let player = try? AVAudioPlayer(contentsOf: url) else {
        preconditionFailure("init(contentsOf:) must succeed without decoding")
    }
    precondition(player.duration == 0)
    precondition(player.prepareToPlay())
    player.volume = 0.5
    player.numberOfLoops = 0
    precondition(player.play())
    precondition(player.isPlaying)
    player.pause()
    precondition(!player.isPlaying)
    player.stop()
    precondition(player.currentTime == 0)

    player._portableSetDuration(0.15)
    precondition(player.duration == 0.15)
    let finished = AVFLocked(false)
    let sem = DispatchSemaphore(value: 0)
    final class FinishProbe: NSObject, AVAudioPlayerDelegate {
        let flag: AVFLocked<Bool>
        let sem: DispatchSemaphore
        init(flag: AVFLocked<Bool>, sem: DispatchSemaphore) {
            self.flag = flag
            self.sem = sem
        }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            self.flag.store(flag)
            sem.signal()
        }
        func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {}
    }
    let probe = FinishProbe(flag: finished, sem: sem)
    player.delegate = probe
    precondition(player.play())
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(finished.load())
    _ = probe
}

func testAVAudioRecorderAndSpeechFailClosed() {
    let url = URL(fileURLWithPath: "/tmp/openav-rec.m4a")
    guard let recorder = try? AVAudioRecorder(url: url, settings: [:]) else {
        preconditionFailure("recorder init must succeed without hardware")
    }
    precondition(recorder.prepareToRecord())
    precondition(recorder.record())
    precondition(recorder.isRecording)
    recorder.pause()
    precondition(!recorder.isRecording)
    recorder.stop()
    precondition(!recorder.deleteRecording())

    let synth = AVSpeechSynthesizer()
    let utterance = AVSpeechUtterance(string: "hello")
    precondition(!synth.speak(utterance))
    precondition(!synth.isSpeaking)
    precondition(!synth.stopSpeaking(at: .immediate))
    precondition(AVSpeechSynthesisVoice.speechVoices().isEmpty)
    precondition(AVSpeechBoundary.immediate.rawValue == 0)
    precondition(AVSpeechBoundary.word.rawValue == 1)
}

func testAVKeyValueStatusRawValues() {
    precondition(AVKeyValueStatus(rawValue: 0) == .unknown)
    precondition(AVKeyValueStatus.loading.rawValue == 1)
    precondition(AVKeyValueStatus.loaded.rawValue == 2)
    precondition(AVKeyValueStatus.failed.rawValue == 3)
    precondition(AVKeyValueStatus.cancelled.rawValue == 4)
}

func testAVPlayerExternalPlaybackAndHDR() {
    let player = AVPlayer()
    precondition(!player.allowsExternalPlayback)
    player.allowsExternalPlayback = true
    precondition(player.allowsExternalPlayback)
    precondition(!player.isExternalPlaybackActive)
    precondition(!player.usesExternalPlaybackWhileExternalScreenIsActive)
    player.usesExternalPlaybackWhileExternalScreenIsActive = true
    precondition(player.usesExternalPlaybackWhileExternalScreenIsActive)
    precondition(player.externalPlaybackVideoGravity == .resizeAspect)
    player.externalPlaybackVideoGravity = .resize
    precondition(player.externalPlaybackVideoGravity == .resize)
    precondition(player.appliesMediaSelectionCriteriaAutomatically)
    player.appliesMediaSelectionCriteriaAutomatically = false
    precondition(!player.appliesMediaSelectionCriteriaAutomatically)
    precondition(!player.isClosedCaptionDisplayEnabled)
    player.isClosedCaptionDisplayEnabled = true
    precondition(player.isClosedCaptionDisplayEnabled)
    precondition(player.networkResourcePriority == .default)
    player.networkResourcePriority = .low
    precondition(player.networkResourcePriority == .low)
    precondition(player.reasonForWaitingToPlay == nil)
    precondition(!player.isOutputObscuredDueToInsufficientExternalProtection)
    precondition(!player.audioOutputSuppressedDueToNonMixableAudioRoute)
    precondition(AVPlayer.availableHDRModes.isEmpty)
    precondition(!AVPlayer.eligibleForHDRPlayback)
    precondition(AVPlayer.HDRMode.hlg.rawValue == 1)
    precondition(AVPlayer.HDRMode.hdr10.rawValue == 2)
    precondition(AVPlayer.HDRMode.dolbyVision.rawValue == 4)
    precondition(AVPlayer.NetworkResourcePriority.default.rawValue == 0)
    precondition(AVPlayer.NetworkResourcePriority.low.rawValue == 1)
    precondition(AVPlayer.NetworkResourcePriority.high.rawValue == 2)
    precondition(AVPlayer.WaitingReason.toMinimizeStalls.rawValue == "toMinimizeStalls")
    precondition(AVPlayer.WaitingReason.noItemToPlay.rawValue == "noItemToPlay")
    precondition(AVPlayer.WaitingReason.evaluatingBufferingRate.rawValue == "evaluatingBufferingRate")
    precondition(AVPlayer.WaitingReason.interstitialEvent.rawValue == "interstitialEvent")
    precondition(AVPlayer.WaitingReason.waitingForCoordinatedPlayback.rawValue == "waitingForCoordinatedPlayback")
    player.setRate(1.25, time: CMTime(seconds: 0.5, preferredTimescale: 600), atHostTime: .zero)
    precondition(abs(player.currentTime().seconds - 0.5) < 0.01)
    precondition(abs(Double(player.rate) - 1.25) < 0.01)
    player.pause()
    let preroll = avfAwait { await player.preroll(atRate: 1) }
    switch preroll {
    case .success(let ok):
        precondition(!ok)
    default:
        preconditionFailure("preroll must fail closed")
    }
    player.cancelPendingPrerolls()
    let prerollDone = AVFLocked(true)
    player.preroll(atRate: 1) { ok in
        prerollDone.store(ok)
    }
    precondition(!prerollDone.load())
}

func testAVPlayerItemOutputsAndMix() {
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-item-out.mp4"))
    precondition(item.outputs.isEmpty)
    let output = AVPlayerItemOutput()
    item.add(output)
    precondition(item.outputs.count == 1)
    item.remove(output)
    precondition(item.outputs.isEmpty)
    let mix = AVMutableAudioMix()
    item.audioMix = mix
    precondition(item.audioMix === mix)
    let composition = AVMutableVideoComposition()
    item.videoComposition = composition
    precondition(item.videoComposition === composition)
    item.seekingWaitsForVideoCompositionRendering = true
    precondition(item.seekingWaitsForVideoCompositionRendering)
    item.preferredForwardBufferDuration = 2
    precondition(item.preferredForwardBufferDuration == 2)
    item.videoApertureMode = .encodedPixels
    precondition(item.videoApertureMode == .encodedPixels)
    precondition(!item.canPlayFastForward)
    precondition(!item.canPlayReverse)
    precondition(!item.canStepForward)
    item.seek(to: CMTime(seconds: 1, preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
    precondition(abs(item.currentTime().seconds - 1) < 0.01)
    let seeked = AVFLocked(false)
    item.seek(
        to: CMTime(seconds: 2, preferredTimescale: 1),
        toleranceBefore: .zero,
        toleranceAfter: .zero
    ) { ok in
        seeked.store(ok)
    }
    precondition(seeked.load())
    precondition(abs(item.currentTime().seconds - 2) < 0.01)
    let collector = AVPlayerItemMediaDataCollector()
    item.add(collector)
    precondition(item.mediaDataCollectors.count == 1)
    item.remove(collector)
    precondition(item.mediaDataCollectors.isEmpty)
}

func testAVPlayerItemCapabilitiesAndBitRate() {
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-item-caps.mp4"))
    precondition(!item.canPlayFastForward)
    precondition(!item.canPlaySlowForward)
    precondition(!item.canPlayReverse)
    precondition(!item.canPlaySlowReverse)
    precondition(!item.canPlayFastReverse)
    precondition(!item.canStepForward)
    precondition(!item.canStepBackward)
    precondition(item.timedMetadata == nil)
    precondition(item.timebase == nil)
    precondition(item.currentDate() == nil)
    item.step(byCount: 1)
    item.automaticallyPreservesTimeOffsetFromLive = true
    precondition(item.automaticallyPreservesTimeOffsetFromLive)
    item.forwardPlaybackEndTime = CMTime(seconds: 5, preferredTimescale: 1)
    precondition(item.forwardPlaybackEndTime.seconds == 5)
    item.reversePlaybackEndTime = CMTime(seconds: 1, preferredTimescale: 1)
    precondition(item.reversePlaybackEndTime.seconds == 1)
    item.preferredPeakBitRate = 1_000_000
    precondition(item.preferredPeakBitRate == 1_000_000)
    item.preferredPeakBitRateForExpensiveNetworks = 500_000
    precondition(item.preferredPeakBitRateForExpensiveNetworks == 500_000)
    item.preferredMaximumResolution = CGSize(width: 1920, height: 1080)
    precondition(item.preferredMaximumResolution.width == 1920)
    item.preferredMaximumResolutionForExpensiveNetworks = CGSize(width: 1280, height: 720)
    precondition(item.preferredMaximumResolutionForExpensiveNetworks.width == 1280)
    item.startsOnFirstEligibleVariant = true
    precondition(item.startsOnFirstEligibleVariant)
    precondition(!item.canUseNetworkResourcesForLiveStreamingWhilePaused)
    precondition(!item.appliesPerFrameHDRDisplayMetadata)
    precondition(!item.isAudioSpatializationAllowed)
    let videoOutput = AVPlayerItemVideoOutput()
    precondition(!videoOutput.hasNewPixelBuffer(forItemTime: .zero))
    precondition(videoOutput.copyPixelBuffer(forItemTime: .zero, itemTimeForDisplay: nil) == nil)
    item.add(videoOutput)
    precondition(item.outputs.count == 1)
    item.remove(videoOutput)
    precondition(item.outputs.isEmpty)
}
