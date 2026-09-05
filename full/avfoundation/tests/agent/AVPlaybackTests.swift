import Dispatch
import Foundation
@_spi(OpenUIKitHost) import AVFoundation

func testAVPlayerStatusAndTimeControl() {
    let empty = AVPlayer()
    precondition(empty.status == .unknown)
    precondition(empty.timeControlStatus == .paused)
    precondition(empty.error == nil)
    precondition(AVPlayer.Status.unknown.rawValue == 0)
    precondition(AVPlayer.Status.readyToPlay.rawValue == 1)
    precondition(AVPlayer.Status.failed.rawValue == 2)
    precondition(AVPlayer.TimeControlStatus.paused.rawValue == 0)
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
    precondition(AVPlayerItem.Status.unknown.rawValue == 0)
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
    asset.loadValuesAsynchronously(forKeys: ["tracks"]) {}
    precondition(asset.statusOfValue(forKey: "tracks", error: nil) == .loaded)
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
    precondition(AVLayerVideoGravity.resizeAspect.rawValue == "AVLayerVideoGravityResizeAspect")
    precondition(AVLayerVideoGravity.resizeAspectFill.rawValue == "AVLayerVideoGravityResizeAspectFill")
    precondition(AVLayerVideoGravity.resize.rawValue == "AVLayerVideoGravityResize")
}

func testAVCaptureAuthorizationDenied() {
    precondition(AVAuthorizationStatus.notDetermined.rawValue == 0)
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
    precondition(AVCaptureSession.InterruptionReason.videoDeviceNotAvailableInBackground.rawValue == 0)
}

func testAVAudioSessionNoHardwareRoute() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
        try session.setActive(true)
        try session.setMode(.moviePlayback)
    } catch {
        preconditionFailure("portable session must not throw: \(error)")
    }
    precondition(session.category == .playAndRecord)
    precondition(session.mode == .moviePlayback)
    precondition(session.currentRoute.inputs.isEmpty)
    precondition(session.currentRoute.outputs.isEmpty)
    precondition(session.outputVolume == 0)
    precondition(AVAudioSession.interruptionNotification.rawValue == "AVAudioSessionInterruptionNotification")
    precondition(AVAudioSession.routeChangeNotification.rawValue == "AVAudioSessionRouteChangeNotification")
    precondition(AVAudioSessionInterruptionTypeKey == "AVAudioSessionInterruptionTypeKey")
    precondition(AVAudioSessionInterruptionOptionKey == "AVAudioSessionInterruptionOptionKey")
    precondition(AVAudioSessionRouteChangeReasonKey == "AVAudioSessionRouteChangeReasonKey")
    precondition(AVAudioSession.InterruptionType.began.rawValue == 1)
    precondition(AVAudioSession.InterruptionType.ended.rawValue == 0)
    precondition(AVAudioSession.InterruptionOptions.shouldResume.rawValue == 1)
    precondition(AVAudioSession.RouteChangeReason.categoryChange.rawValue == 3)
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

func testAVPlayerDeclaredSurface() {
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-surface.mp4"))
    _ = player.reasonForWaitingToPlay
    player.cancelPendingPrerolls()
    let preroll = avfAwait { await player.preroll(atRate: 1) }
    switch preroll {
    case .success(let ok):
        precondition(!ok)
    default:
        preconditionFailure("preroll is fail-closed")
    }
    player.sourceClock = nil
    player.masterClock = nil
    player.allowsExternalPlayback = true
    precondition(player.allowsExternalPlayback)
    precondition(!player.isExternalPlaybackActive)
    player.usesExternalPlaybackWhileExternalScreenIsActive = true
    player.externalPlaybackVideoGravity = .resizeAspect
    precondition(!player.isOutputObscuredDueToInsufficientExternalProtection)
    precondition(AVPlayer.availableHDRModes.isEmpty)
    precondition(!AVPlayer.eligibleForHDRPlayback)
    _ = player.playbackCoordinator
    player.videoOutput = nil
    player.networkResourcePriority = .high
    precondition(player.networkResourcePriority == .high)
    precondition(!player.audioOutputSuppressedDueToNonMixableAudioRoute)
    AVPlayer.isObservationEnabled = true
    player.isClosedCaptionDisplayEnabled = true
    precondition(player.isClosedCaptionDisplayEnabled)
    let criteria = AVPlayerMediaSelectionCriteria()
    player.setMediaSelectionCriteria(criteria, forMediaCharacteristic: .audible)
    precondition(player.mediaSelectionCriteria(forMediaCharacteristic: .audible) === criteria)
    player.appliesMediaSelectionCriteriaAutomatically = false
    player.setRate(0, time: .zero, atHostTime: .zero)
    player.seek(to: Date())
    _ = AVPlayer.rateDidChangeNotification
    _ = AVPlayer.rateDidChangeReasonKey
    _ = AVPlayer.HDRMode.hlg
    _ = AVPlayer.WaitingReason.toMinimizeStalls
    _ = AVPlayer.RateDidChangeReason.setRateCalled
}

func testAVPlayerItemDeclaredSurface() {
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-item-surface.mp4"))
    _ = item.presentationSize
    _ = item.timedMetadata
    _ = item.automaticallyLoadedAssetKeys
    _ = item.canPlaySlowForward
    _ = item.canPlayReverse
    _ = item.canPlaySlowReverse
    _ = item.canPlayFastReverse
    _ = item.canStepForward
    _ = item.canStepBackward
    item.configuredTimeOffsetFromLive = .zero
    _ = item.recommendedTimeOffsetFromLive
    item.automaticallyPreservesTimeOffsetFromLive = true
    item.forwardPlaybackEndTime = .zero
    item.reversePlaybackEndTime = .zero
    _ = item.seekableTimeRanges
    _ = item.currentDate()
    _ = item.seek(to: Date())
    item.step(byCount: 1)
    _ = item.timebase
    item.videoComposition = nil
    _ = item.customVideoCompositor
    item.seekingWaitsForVideoCompositionRendering = true
    item.textStyleRules = nil
    _ = item.loadedTimeRanges
    _ = item.isPlaybackLikelyToKeepUp
    _ = item.isPlaybackBufferFull
    _ = item.isPlaybackBufferEmpty
    _ = item.preferredForwardBufferDuration
    _ = AVPlayerItem.timeJumpedNotification
    _ = AVPlayerItem.newAccessLogEntryNotification
    _ = item.copy(with: nil)
    let withKeys = AVPlayerItem(asset: item.asset, automaticallyLoadedAssetKeys: [] as [String]?)
    precondition(withKeys.asset === item.asset)
}

func testAVAssetDeclaredSurface() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-asset-surface.mp4"))
    _ = asset.preferredRate
    _ = asset.preferredVolume
    _ = asset.preferredTransform
    _ = asset.providesPreciseDurationAndTiming
    asset.cancelLoading()
    _ = asset.unusedTrackID()
    _ = asset.track(withTrackID: 0)
    _ = asset.tracks(withMediaType: .audio)
    _ = asset.tracks(withMediaCharacteristic: .audible)
    _ = asset.trackGroups
    _ = asset.creationDate
    _ = asset.lyrics
    _ = asset.commonMetadata
    _ = asset.availableMetadataFormats
    _ = asset.metadata(forFormat: AVMetadataFormat(rawValue: "id3"))
    _ = asset.availableChapterLocales
    _ = asset.chapterMetadataGroups(bestMatchingPreferredLanguages: ["en"])
    _ = asset.hasProtectedContent
    _ = asset.canContainFragments
    _ = asset.containsFragments
    _ = asset.isExportable
    _ = asset.isReadable
    _ = asset.isComposable
    _ = asset.isCompatibleWithSavedPhotosAlbum
    _ = asset.isCompatibleWithAirPlayVideo
    _ = AVURLAsset.audiovisualTypes()
    _ = AVURLAsset.audiovisualMIMETypes()
    precondition(!AVURLAsset.isPlayableExtendedMIMEType("video/mp4"))
    _ = asset.resourceLoader
    _ = asset.variants
    let unused = avfAwait { try await asset.findUnusedTrackID() }
    switch unused {
    case .success(let id):
        precondition(id == 0)
    default:
        preconditionFailure("findUnusedTrackID is fail-closed")
    }
}

func testAVCaptureDeviceDeclaredSurface() {
    let device = AVCaptureDevice()
    _ = AVCaptureDevice.DeviceType.builtInWideAngleCamera
    _ = AVCaptureDevice.DeviceType.builtInTelephotoCamera
    _ = AVCaptureDevice.DeviceType.builtInUltraWideCamera
    _ = AVCaptureDevice.DeviceType.builtInDualCamera
    _ = AVCaptureDevice.DeviceType.microphone
    _ = AVCaptureDevice.Position.front
    _ = AVCaptureDevice.Position.back
    _ = AVCaptureDevice.Position.unspecified
    _ = AVCaptureDevice.FlashMode.off
    _ = AVCaptureDevice.FocusMode.continuousAutoFocus
    _ = AVCaptureDevice.ExposureMode.continuousAutoExposure
    _ = AVCaptureDevice.TorchMode.off
    _ = AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance
    _ = device.uniqueID
    _ = device.modelID
    _ = device.localizedName
    _ = device.manufacturer
    _ = device.deviceType
    _ = device.position
    _ = device.formats
    _ = device.activeFormat
    _ = device.activeVideoMinFrameDuration
    _ = device.activeVideoMaxFrameDuration
    _ = device.hasFlash
    _ = device.hasTorch
    _ = device.isFlashAvailable
    _ = device.isTorchAvailable
    _ = device.isConnected
    _ = device.isVirtualDevice
    _ = device.constituentDevices
    device.unlockForConfiguration()
    do {
        try device.lockForConfiguration()
        preconditionFailure("lockForConfiguration must fail closed")
    } catch {
        _ = error
    }
    let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera],
        mediaType: .video,
        position: .back
    )
    precondition(session.devices.isEmpty)
    precondition(session.supportedMultiCamDeviceSets.isEmpty)
    precondition(AVCaptureDevice.default(for: .video) == nil)
}

func testAVKeyValueStatusRawValues() {
    precondition(AVKeyValueStatus.unknown.rawValue == 0)
    precondition(AVKeyValueStatus.loading.rawValue == 1)
    precondition(AVKeyValueStatus.loaded.rawValue == 2)
    precondition(AVKeyValueStatus.failed.rawValue == 3)
    precondition(AVKeyValueStatus.cancelled.rawValue == 4)
}
