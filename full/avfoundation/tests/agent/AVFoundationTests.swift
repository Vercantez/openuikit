import Dispatch
import Foundation
import AVFoundation

private final class AVFLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}

private func avfAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = AVFLocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let result = box.load() else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

func testPlayerPlayPauseAndSeek() {
    let url = URL(fileURLWithPath: "/tmp/openav-input.mp4")
    let player = AVPlayer(url: url)
    precondition(player.currentItem != nil)
    precondition(player.rate == 0)
    player.play()
    precondition(player.rate == 1)
    let time = CMTime(value: 1, timescale: 2)
    player.seek(to: time)
    precondition(player.currentTime() == time)
    player.seek(to: .invalid)
    precondition(player.currentTime() == time)
    player.pause()
    precondition(player.rate == 0)
}

func testPlayerVolumeMuteAndPolicy() {
    let player = AVPlayer()
    precondition(player.volume == 1)
    player.volume = 0.25
    precondition(player.volume == 0.25)
    precondition(player.defaultRate == 1)
    player.defaultRate = 1.5
    precondition(player.defaultRate == 1.5)
    precondition(!player.isMuted)
    player.isMuted = true
    precondition(player.isMuted)
    precondition(
        player.audiovisualBackgroundPlaybackPolicy == .automatic
    )
    player.audiovisualBackgroundPlaybackPolicy = .pauses
    precondition(player.audiovisualBackgroundPlaybackPolicy == .pauses)
    precondition(player.preventsDisplaySleepDuringVideoPlayback)
    player.preventsDisplaySleepDuringVideoPlayback = false
    precondition(!player.preventsDisplaySleepDuringVideoPlayback)
}

func testPlayerReplaceCurrentItem() {
    let first = URL(fileURLWithPath: "/tmp/openav-a.mp4")
    let second = URL(fileURLWithPath: "/tmp/openav-b.mp4")
    let player = AVPlayer(url: first)
    precondition(player.currentItem?.url == first)
    player.rate = 1
    player.seek(to: CMTime(value: 3, timescale: 1))
    player.replaceCurrentItem(with: AVPlayerItem(url: second))
    precondition(player.currentItem?.url == second)
    precondition(player.rate == 0, "replaceCurrentItem must clear rate, got \(player.rate)")
    precondition(player.currentTime() == .zero)
    player.replaceCurrentItem(with: nil)
    precondition(player.currentItem == nil)
}

func testFileTypeUTIValues() {
    precondition(AVFileType.mp4.rawValue == "public.mpeg-4")
    precondition(AVFileType.mov.rawValue == "com.apple.quicktime-movie")
    precondition(AVFileType.m4a.rawValue == "com.apple.m4a-audio")
    precondition(AVFileType(rawValue: "public.mpeg-4") == .mp4)
    precondition(AVFileType("com.apple.quicktime-movie") == .mov)
}

func testExportPresetConstants() {
    precondition(AVAssetExportPresetLowQuality == "AVAssetExportPresetLowQuality")
    precondition(AVAssetExportPresetMediumQuality == "AVAssetExportPresetMediumQuality")
    precondition(AVAssetExportPresetHighestQuality == "AVAssetExportPresetHighestQuality")
    precondition(AVAssetExportPreset1280x720 == "AVAssetExportPreset1280x720")
    precondition(AVAssetExportPreset1920x1080 == "AVAssetExportPreset1920x1080")
    precondition(AVAssetExportPresetPassthrough == "AVAssetExportPresetPassthrough")
}

func testExportSessionFailClosedAndCancel() {
    precondition(AVAssetExportSession(asset: AVAsset(), presetName: "") == nil)
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-input.mp4"))
    let session = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPreset1280x720
    )
    precondition(session != nil)
    guard let session else { return }
    precondition(session.status == .unknown)
    precondition(session.presetName == AVAssetExportPreset1280x720)
    precondition(session.asset === asset)
    let output = URL(fileURLWithPath: "/tmp/openav-output.mp4")
    let result = avfAwait {
        try await session.export(to: output, as: .mp4)
    }
    switch result {
    case .failure(let error as AVFoundationPortableError):
        precondition(error == .exportUnavailable(preset: AVAssetExportPreset1280x720))
    default:
        preconditionFailure("export without a host handler must fail closed")
    }
    precondition(session.status == .failed)
    precondition(session.error != nil)
    session.cancelExport()
    precondition(session.status == .cancelled)
}

func testExportSessionStatusRawValues() {
    precondition(AVAssetExportSession.Status.unknown.rawValue == 0)
    precondition(AVAssetExportSession.Status.waiting.rawValue == 1)
    precondition(AVAssetExportSession.Status.exporting.rawValue == 2)
    precondition(AVAssetExportSession.Status.completed.rawValue == 3)
    precondition(AVAssetExportSession.Status.failed.rawValue == 4)
    precondition(AVAssetExportSession.Status.cancelled.rawValue == 5)
}

func testMakeRectAspectFit() {
    let square = AVMakeRect(
        aspectRatio: CGSize(width: 2, height: 1),
        insideRect: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    precondition(square.origin.x == 0)
    precondition(square.origin.y == 2.5)
    precondition(square.size.width == 10)
    precondition(square.size.height == 5)
    let empty = AVMakeRect(
        aspectRatio: .zero,
        insideRect: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    precondition(empty == .zero)
}

func testAVErrorCodeMaciosRawValues() {
    let expected: [(AVError.Code, Int)] = [
        (.unknown, -11800),
        (.outOfMemory, -11801),
        (.sessionNotRunning, -11803),
        (.deviceAlreadyUsedByAnotherSession, -11804),
        (.noDataCaptured, -11805),
        (.sessionConfigurationChanged, -11806),
        (.diskFull, -11807),
        (.deviceWasDisconnected, -11808),
        (.mediaChanged, -11809),
        (.maximumDurationReached, -11810),
        (.maximumFileSizeReached, -11811),
        (.mediaDiscontinuity, -11812),
        (.maximumNumberOfSamplesForFileFormatReached, -11813),
        (.deviceNotConnected, -11814),
        (.deviceInUseByAnotherApplication, -11815),
        (.deviceLockedForConfigurationByAnotherProcess, -11817),
        (.sessionWasInterrupted, -11818),
        (.mediaServicesWereReset, -11819),
        (.exportFailed, -11820),
        (.decodeFailed, -11821),
        (.invalidSourceMedia, -11822),
        (.fileAlreadyExists, -11823),
        (.compositionTrackSegmentsNotContiguous, -11824),
        (.invalidCompositionTrackSegmentDuration, -11825),
        (.invalidCompositionTrackSegmentSourceStartTime, -11826),
        (.invalidCompositionTrackSegmentSourceDuration, -11827),
        (.fileFormatNotRecognized, -11828),
        (.fileFailedToParse, -11829),
        (.maximumStillImageCaptureRequestsExceeded, -11830),
        (.contentIsProtected, -11831),
        (.noImageAtTime, -11832),
        (.decoderNotFound, -11833),
        (.encoderNotFound, -11834),
        (.contentIsNotAuthorized, -11835),
        (.applicationIsNotAuthorized, -11836),
        (.deviceIsNotAvailableInBackground, -11837),
        (.operationNotSupportedForAsset, -11838),
        (.decoderTemporarilyUnavailable, -11839),
        (.encoderTemporarilyUnavailable, -11840),
        (.invalidVideoComposition, -11841),
        (.referenceForbiddenByReferencePolicy, -11842),
        (.invalidOutputURLPathExtension, -11843),
        (.screenCaptureFailed, -11844),
        (.displayWasDisabled, -11845),
        (.torchLevelUnavailable, -11846),
        (.operationInterrupted, -11847),
        (.incompatibleAsset, -11848),
        (.failedToLoadMediaData, -11849),
        (.serverIncorrectlyConfigured, -11850),
        (.applicationIsNotAuthorizedToUseDevice, -11852),
        (.failedToParse, -11853),
        (.fileTypeDoesNotSupportSampleReferences, -11854),
        (.undecodableMediaData, -11855),
        (.airPlayControllerRequiresInternet, -11856),
        (.airPlayReceiverRequiresInternet, -11857),
        (.videoCompositorFailed, -11858),
        (.recordingAlreadyInProgress, -11859),
        (.unsupportedOutputSettings, -11861),
        (.operationNotAllowed, -11862),
        (.contentIsUnavailable, -11863),
        (.formatUnsupported, -11864),
        (.malformedDepth, -11865),
        (.contentNotUpdated, -11866),
        (.noLongerPlayable, -11867),
        (.noCompatibleAlternatesForExternalDisplay, -11868),
        (.noSourceTrack, -11869),
        (.externalPlaybackNotSupportedForAsset, -11870),
        (.operationNotSupportedForPreset, -11871),
        (.sessionHardwareCostOverage, -11872),
        (.unsupportedDeviceActiveFormat, -11873),
        (.incorrectlyConfigured, -11875),
        (.segmentStartedWithNonSyncSample, -11876),
        (.rosettaNotInstalled, -11877),
        (.operationCancelled, -11878),
        (.contentKeyRequestCancelled, -11879),
        (.invalidSampleCursor, -11880),
        (.failedToLoadSampleData, -11881),
        (.airPlayReceiverTemporarilyUnavailable, -11882),
        (.encodeFailed, -11883),
        (.sandboxExtensionDenied, -11884),
        (.toneMappingFailed, -11885),
        (.noSmartFramingsEnabled, -11890),
        (.autoWhiteBalanceNotLocked, -11891),
        (.followExternalSyncDeviceTimedOut, -11892),
    ]
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
    }
    let error = AVError(.exportFailed)
    precondition(error.errorCode == -11820)
    precondition(AVError.errorDomain == AVFoundationErrorDomain)
    precondition(AVFoundationErrorDomain == "AVFoundationErrorDomain")
    precondition(AVError.exportFailed == .exportFailed)
}

func testCaptureDevicesEmptyAndLockFails() {
    precondition(AVCaptureDevice.devices().isEmpty)
    let device = AVCaptureDevice()
    do {
        try device.lockForConfiguration()
        preconditionFailure("lockForConfiguration must fail closed without capture hardware")
    } catch let error as AVFoundationPortableError {
        precondition(error == .mediaServiceUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    device.unlockForConfiguration()
}

func testPlayerItemNotificationNames() {
    precondition(
        Notification.Name.AVPlayerItemDidPlayToEndTime.rawValue
            == "AVPlayerItemDidPlayToEndTimeNotification"
    )
    precondition(
        Notification.Name.AVPlayerItemFailedToPlayToEndTime.rawValue
            == "AVPlayerItemFailedToPlayToEndTimeNotification"
    )
    precondition(
        Notification.Name.AVPlayerItemPlaybackStalled.rawValue
            == "AVPlayerItemPlaybackStalledNotification"
    )
}

func testURLAssetAndPlayerItemInit() {
    let url = URL(fileURLWithPath: "/tmp/openav-asset.mp4")
    let asset = AVURLAsset(url: url, options: nil)
    precondition(asset.url == url)
    let item = AVPlayerItem(asset: asset)
    precondition(item.asset === asset)
    precondition(item.url == url)
    let fromURL = AVPlayerItem(url: url)
    precondition(fromURL.url == url)
}

func testImageGeneratorFailClosed() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-frame.mp4"))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    precondition(generator.appliesPreferredTrackTransform)
    precondition(generator.asset === asset)
    let seen = AVFLocked(false)
    generator.generateCGImageAsynchronously(for: .zero) { image, _, error in
        seen.store(true)
        precondition(image == nil)
        guard let portable = error as? AVFoundationPortableError else {
            preconditionFailure("frame generation must fail closed")
        }
        precondition(portable == .frameGenerationUnavailable(asset.url))
    }
    precondition(seen.load())
}

func testBackgroundPlaybackPolicyRawValues() {
    precondition(AVPlayerAudiovisualBackgroundPlaybackPolicy.automatic.rawValue == 1)
    precondition(AVPlayerAudiovisualBackgroundPlaybackPolicy.pauses.rawValue == 2)
    precondition(AVPlayerAudiovisualBackgroundPlaybackPolicy.continuesIfPossible.rawValue == 3)
}

func testAudioSessionCategoryState() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playback, options: [.duckOthers, .mixWithOthers])
        try session.setActive(true)
    } catch {
        preconditionFailure("portable audio session state must not throw: \(error)")
    }
    precondition(session.category == .playback)
    precondition(session.categoryOptions.contains(.duckOthers))
}
