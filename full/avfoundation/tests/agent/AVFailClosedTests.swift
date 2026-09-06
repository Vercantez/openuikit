import Foundation
import AVFoundation

func testAVErrorHashable() {
    precondition(AVError.unknown == AVError.unknown)
    precondition(AVError(.unknown) == AVError(.unknown))
    precondition(AVError(.unknown) != AVError(.mediaServicesWereReset))
    var hasher = Hasher()
    AVError(.encoderNotFound).hash(into: &hasher)
    _ = hasher.finalize()
}

func testAVErrorUserInfoKeys() {
    precondition(AVErrorDeviceKey == "AVErrorDeviceKey")
    precondition(AVErrorTimeKey == "AVErrorTimeKey")
    precondition(AVErrorFileSizeKey == "AVErrorFileSizeKey")
    precondition(AVErrorPIDKey == "AVErrorPIDKey")
    precondition(AVErrorRecordingSuccessfullyFinishedKey == "AVErrorRecordingSuccessfullyFinishedKey")
    precondition(AVErrorMediaTypeKey == "AVErrorMediaTypeKey")
    precondition(AVErrorMediaSubTypeKey == "AVErrorMediaSubTypeKey")
    precondition(AVErrorPresentationTimeStampKey == "AVErrorPresentationTimeStampKey")
    precondition(AVErrorPersistentTrackIDKey == "AVErrorPersistentTrackIDKey")
    precondition(AVErrorFileTypeKey == "AVErrorFileTypeKey")
    let stamped = AVError(.noImageAtTime, userInfo: [AVErrorTimeKey: CMTime.zero])
    precondition(stamped.time == .zero)
    precondition(stamped.errorCode == AVError.Code.noImageAtTime.rawValue)
    precondition(AVError.errorDomain == AVFoundationErrorDomain)
}

func testAVAssetWriterStartWritingFailsClosedWithEncoderNotFound() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-writer-fail-\(UUID().uuidString).mp4")
    try? FileManager.default.removeItem(at: url)
    do {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        precondition(writer.outputURL == url)
        precondition(writer.outputFileType == .mp4)
        precondition(writer.status == .unknown)
        precondition(writer.error == nil)
        precondition(writer.availableMediaTypes.contains(.video))
        precondition(!writer.startWriting())
        precondition(writer.status == .failed)
        precondition((writer.error as? AVError)?.code == .encoderNotFound)
        do {
            try writer.start()
            preconditionFailure("AVAssetWriter.start() must fail closed")
        } catch let error as AVError {
            precondition(error.code == .encoderNotFound)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
    } catch {
        preconditionFailure("AVAssetWriter designated initializer should succeed: \(error)")
    }
}

func testAVAssetReaderStartReadingFailsClosedWithDecoderNotFound() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-reader.mp4"))
    do {
        let reader = try AVAssetReader(asset: asset)
        precondition(reader.asset === asset)
        precondition(reader.status == .unknown)
        precondition(!reader.startReading())
        precondition(reader.status == .failed)
        precondition((reader.error as? AVError)?.code == .decoderNotFound)
        precondition(AVAssetReader.Status.cancelled.rawValue == 4)
        precondition(AVAssetReader.Status.failed.rawValue == 3)
        precondition(AVAssetReader.Status.unknown.rawValue == 0)
        precondition(AVAssetReader.Status.reading.rawValue == 1)
        precondition(AVAssetReader.Status.completed.rawValue == 2)
        precondition(AVAssetWriter.Status.cancelled.rawValue == 4)
        precondition(AVAssetWriter.Status.unknown.rawValue == 0)
        precondition(AVAssetWriter.Status.writing.rawValue == 1)
        precondition(AVAssetWriter.Status.completed.rawValue == 2)
        precondition(AVAssetWriter.Status.failed.rawValue == 3)
        do {
            try reader.start()
            preconditionFailure("AVAssetReader.start() must fail closed")
        } catch let error as AVError {
            precondition(error.code == .decoderNotFound)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
    } catch {
        preconditionFailure("AVAssetReader designated initializer should succeed: \(error)")
    }
}

func testAVAssetImageGeneratorCopyCGImageFailsClosedWithNoImageAtTime() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-generator.mp4"))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    var actualTime = CMTime.invalid
    do {
        _ = try generator.copyCGImage(
            at: CMTime(seconds: 0, preferredTimescale: 600),
            actualTime: &actualTime
        )
        preconditionFailure("copyCGImage should fail closed")
    } catch let error as AVError {
        precondition(error.code == .noImageAtTime)
        precondition(actualTime == .invalid)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAVAssetImageGeneratorGenerateTimesFailsClosedWithNoImageAtTime() {
    let generator = AVAssetImageGenerator(
        asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-generator.mp4"))
    )
    var seen = 0
    generator.generateCGImagesAsynchronously(forTimes: [NSNumber(value: 0)]) { _, image, _, result, error in
        seen += 1
        precondition(image == nil)
        precondition(result == .failed)
        precondition((error as? AVError)?.code == .noImageAtTime)
    }
    precondition(seen == 1)
}

func testAVCaptureDeviceInputFailsClosedUnauthorized() {
    let device = AVCaptureDevice.default(
        .builtInWideAngleCamera,
        for: .video,
        position: .back
    ) ?? AVCaptureDevice()
    do {
        _ = try AVCaptureDeviceInput(device: device)
        preconditionFailure("device input should fail closed")
    } catch let error as AVError {
        precondition(error.code == .applicationIsNotAuthorizedToUseDevice)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAVCaptureDeviceDiscoverySessionEmptyOnLinux() {
    let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInMicrophone],
        mediaType: .video,
        position: .unspecified
    )
    precondition(session.devices.isEmpty)
    precondition(session.supportedMultiCamDeviceSets.isEmpty)
    precondition(AVCaptureDevice.default(for: .video) == nil)
    precondition(AVCaptureDevice.devices(for: .audio).isEmpty)
}

func testAVPlayerLooperReadyThenCancelled() {
    let player = AVQueuePlayer()
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-looper.mp4"))
    let looper = AVPlayerLooper(player: player, templateItem: item)
    precondition(looper.status == .ready)
    precondition(looper.loopCount == 0)
    precondition(player.items().count == 1)
    precondition(looper.loopingPlayerItems.count == 1)
    precondition(looper.error == nil)
    looper.disableLooping()
    precondition(looper.status == .cancelled)
    precondition(AVPlayerLooper.Status.ready.rawValue == 1)
    precondition(AVPlayerLooper.Status.cancelled.rawValue == 3)
    precondition(AVPlayerLooper.Status.failed.rawValue == 2)
    precondition(AVPlayerLooper.Status.unknown.rawValue == 0)
    precondition(AVPlayerLooper.ItemOrdering.loopingItemsPrecedeExistingItems.rawValue == 0)
    precondition(AVPlayerLooper.ItemOrdering.loopingItemsFollowExistingItems.rawValue == 1)
}

func testAVAudioMixAndVideoCompositionInstructionModels() {
    let mix = AVMutableAudioMix()
    let parameters = AVMutableAudioMixInputParameters()
    parameters.trackID = 1
    parameters.setVolume(0.5, at: .zero)
    parameters.setVolumeRamp(
        fromStartVolume: 0,
        toEndVolume: 1,
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    mix.inputParameters = [parameters]
    precondition(mix.inputParameters.count == 1)
    precondition(parameters.trackID == 1)
    var start: Float = 0
    var end: Float = 0
    var range = CMTimeRange.invalid
    precondition(parameters.getVolumeRamp(for: .zero, startVolume: &start, endVolume: &end, timeRange: &range))
    precondition(start == 0)
    precondition(end == 1)

    let composition = AVMutableVideoComposition()
    composition.frameDuration = CMTime(value: 1, timescale: 30)
    composition.renderSize = CGSize(width: 1920, height: 1080)
    composition.renderScale = 1
    composition.sourceTrackIDForFrameTiming = 1
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(
        start: .zero,
        duration: CMTime(seconds: 2, preferredTimescale: 1)
    )
    instruction.backgroundColor = nil
    instruction.enablePostProcessing = true
    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: AVAssetTrack())
    layer.setOpacity(1, at: .zero)
    layer.setTransform(CGAffineTransform.identity, at: .zero)
    instruction.layerInstructions = [layer]
    composition.instructions = [instruction]
    precondition(composition.instructions.count == 1)
    precondition(composition.renderSize.width == 1920)
    precondition(composition.renderSize.height == 1080)
    precondition(composition.frameDuration.timescale == 30)
    precondition(composition.sourceTrackIDForFrameTiming == 1)
    precondition(instruction.enablePostProcessing)
    precondition(instruction.timeRange.duration.seconds == 2)
    precondition(layer.trackID == 0)
}

func testAVCMTimeRangeValueBridgesCMTimeRange() {
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: 4, preferredTimescale: 1))
    let boxed = AVCMTimeRangeValue.nsValue(for: range)
    let roundTrip = AVCMTimeRangeValue.range(from: boxed)
    precondition(abs(roundTrip.duration.seconds - 4) < 0.001)
    precondition(roundTrip.start == .zero)
}

func testAVPlayerItemLoadedTimeRangesEmptyWhenAssetMissing() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-player-item.mp4"))
    let item = AVPlayerItem(asset: asset)
    precondition(item.tracks.isEmpty)
    precondition(item.loadedTimeRanges.isEmpty)
    precondition(item.presentationSize == .zero)
    precondition(item.error == nil)
    precondition(!item.duration.isValid)
}

func testAVPlayerPeriodicObserverRegistration() {
    let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/openav-missing-periodic.mp4"))
    let token = player.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
        queue: nil
    ) { _ in }
    player.removeTimeObserver(token)
    precondition(player.timeControlStatus == .paused)
    precondition(player.status == .readyToPlay)
}

func testAVMediaTypeAndCharacteristicRawValues() {
    precondition(AVMediaType.video.rawValue == "video")
    precondition(AVMediaType.audio.rawValue == "audio")
    precondition(AVMediaType.text.rawValue == "text")
    precondition(AVMediaType.closedCaption.rawValue == "closedCaption")
    precondition(AVMediaType.subtitle.rawValue == "subtitle")
    precondition(AVMediaType.timecode.rawValue == "timecode")
    precondition(AVMediaType.metadata.rawValue == "metadata")
    precondition(AVMediaType.muxed.rawValue == "muxed")
    precondition(AVMediaType.haptic.rawValue == "haptic")
    precondition(AVMediaType.metadataObject.rawValue == "metadataObject")
    precondition(AVMediaType.depthData.rawValue == "depthData")
    precondition(AVMediaType.auxiliaryPicture.rawValue == "auxiliaryPicture")
    precondition(AVMediaCharacteristic.visual.rawValue == "visual")
    precondition(AVMediaCharacteristic.audible.rawValue == "audible")
    precondition(AVMediaCharacteristic.legible.rawValue == "legible")
    precondition(AVMediaCharacteristic.frameBased.rawValue == "frameBased")
    precondition(AVMediaCharacteristic.easyToRead.rawValue == "easyToRead")
    precondition(AVMediaCharacteristic.describesVideoForAccessibility.rawValue == "describesVideoForAccessibility")
    precondition(AVMediaCharacteristic.describesMusicAndSoundForAccessibility.rawValue == "describesMusicAndSoundForAccessibility")
    precondition(AVMediaCharacteristic.transcribesSpokenDialogForAccessibility.rawValue == "transcribesSpokenDialogForAccessibility")
    precondition(AVMediaCharacteristic.containsHDRVideo.rawValue == "containsHDRVideo")
    precondition(AVMediaCharacteristic.containsStereoMultiviewVideo.rawValue == "containsStereoMultiviewVideo")
    precondition(AVMediaCharacteristic.containsAlphaChannel.rawValue == "containsAlphaChannel")
    precondition(AVMediaCharacteristic.enhancesSpeechIntelligibility.rawValue == "enhancesSpeechIntelligibility")
    precondition(AVMediaCharacteristic.usesWideGamutColorSpace.rawValue == "usesWideGamutColorSpace")
    precondition(AVMediaCharacteristic.isMainProgramContent.rawValue == "isMainProgramContent")
    precondition(AVMediaCharacteristic.isAuxiliaryContent.rawValue == "isAuxiliaryContent")
    precondition(AVMediaCharacteristic.languageTranslation.rawValue == "languageTranslation")
}

func testAVVideoCodecAndApertureRawValues() {
    precondition(AVVideoCodecType.h264.rawValue == "h264")
    precondition(AVVideoCodecType.hevc.rawValue == "hevc")
    precondition(AVVideoCodecType.jpeg.rawValue == "jpeg")
    precondition(AVVideoCodecType.JPEGXL.rawValue == "JPEGXL")
    precondition(AVVideoCodecType.proRes422.rawValue == "proRes422")
    precondition(AVVideoCodecType.proRes422HQ.rawValue == "proRes422HQ")
    precondition(AVVideoCodecType.proRes422LT.rawValue == "proRes422LT")
    precondition(AVVideoCodecType.proRes422Proxy.rawValue == "proRes422Proxy")
    precondition(AVVideoCodecType.proRes4444.rawValue == "proRes4444")
    precondition(AVVideoCodecType.appleProRes4444XQ.rawValue == "appleProRes4444XQ")
    precondition(AVVideoCodecType.proResRAW.rawValue == "proResRAW")
    precondition(AVVideoCodecType.proResRAWHQ.rawValue == "proResRAWHQ")
    precondition(AVVideoCodecType.hevcWithAlpha.rawValue == "hevcWithAlpha")
    precondition(AVVideoApertureMode.cleanAperture.rawValue == "cleanAperture")
    precondition(AVVideoApertureMode.productionAperture.rawValue == "productionAperture")
    precondition(AVVideoApertureMode.encodedPixels.rawValue == "encodedPixels")
    precondition(AVAssetImageGenerator.Result.succeeded.rawValue == 0)
    precondition(AVAssetImageGenerator.Result.failed.rawValue == 1)
    precondition(AVAssetImageGenerator.Result.cancelled.rawValue == 2)
    precondition(AVAssetImageGenerator.ApertureMode.cleanAperture.rawValue == "cleanAperture")
    precondition(AVAssetImageGenerator.DynamicRangePolicy.forceSDR.rawValue == "forceSDR")
    precondition(AVAssetImageGenerator.DynamicRangePolicy.matchSource.rawValue == "matchSource")
}

func testAVAssetWriterInputModelThenEncoderNotFound() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-writer-input-\(UUID().uuidString).mp4")
    try? FileManager.default.removeItem(at: url)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let video = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
    precondition(video.mediaType == .video)
    precondition(audio.mediaType == .audio)
    precondition(writer.canAdd(video))
    writer.add(video)
    writer.add(audio)
    precondition(writer.inputs.count == 2)
    precondition(!writer.startWriting())
    precondition(writer.status == .failed)
    precondition((writer.error as? AVError)?.code == .encoderNotFound)
    precondition(!video.isReadyForMoreMediaData)
    precondition(!video.append(CMSampleBuffer()))
    let finished = AVFLocked(false)
    writer.finishWriting {
        finished.store(true)
    }
    precondition(finished.load())
    precondition(writer.status == .failed)
}

func testAVAssetReaderCanAddOutputThenDecoderNotFound() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-reader-add.mp4"))
    let reader = try! AVAssetReader(asset: asset)
    let output = AVAssetReaderOutput()
    precondition(reader.canAdd(output))
    reader.add(output)
    precondition(reader.outputs.count == 1)
    precondition(!reader.startReading())
    precondition((reader.error as? AVError)?.code == .decoderNotFound)
    reader.cancelReading()
    precondition(reader.status == .cancelled)
}

func testAVAssetExportSessionCatalogFailClosed() {
    precondition(AVAssetExportSession.allExportPresets().isEmpty)
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-export-catalog.mp4"))
    precondition(AVAssetExportSession.exportPresets(compatibleWith: asset).isEmpty)
    let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
    precondition(session.supportedFileTypes.isEmpty)
    let types = AVFLocked([AVFileType]())
    session.determineCompatibleFileTypes { result in
        types.store(result)
    }
    precondition(types.load().isEmpty)
    let seen = AVFLocked(false)
    session.exportAsynchronously {
        seen.store(true)
    }
    precondition(seen.load())
    precondition(session.status == .failed)
    precondition((session.error as? AVError)?.code == .exportFailed)
    session.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1))
    precondition(session.timeRange.duration.seconds == 1)
    session.fileLengthLimit = 100
    precondition(session.fileLengthLimit == 100)
    precondition(session.estimatedOutputFileLength == 0)
    precondition(session.maxDuration == .zero)
    precondition(session.progress == 0)
}

func testAVCaptureSessionConfigurationModel() {
    let session = AVCaptureSession()
    precondition(session.sessionPreset == .high)
    session.sessionPreset = .photo
    precondition(session.sessionPreset == .photo)
    precondition(!session.canSetSessionPreset(.high))
    precondition(session.usesApplicationAudioSession)
    session.usesApplicationAudioSession = false
    precondition(!session.usesApplicationAudioSession)
    precondition(session.automaticallyConfiguresApplicationAudioSession)
    session.automaticallyConfiguresApplicationAudioSession = false
    precondition(!session.automaticallyConfiguresApplicationAudioSession)
    session.configuresApplicationAudioSessionToMixWithOthers = true
    precondition(session.configuresApplicationAudioSessionToMixWithOthers)
    session.isMultitaskingCameraAccessEnabled = true
    precondition(session.isMultitaskingCameraAccessEnabled)
    precondition(!session.isMultitaskingCameraAccessSupported)
    precondition(!session.isInterrupted)
    precondition(session.connections.isEmpty)
    precondition(session.hardwareCost == 0)
    session.addInput(AVCaptureInput())
    session.addOutput(AVCaptureOutput())
    precondition(session.inputs.isEmpty)
    precondition(session.outputs.isEmpty)
    precondition(
        AVCaptureSession.didStartRunningNotification.rawValue
            == "AVCaptureSessionDidStartRunningNotification"
    )
    precondition(
        AVCaptureSession.didStopRunningNotification.rawValue
            == "AVCaptureSessionDidStopRunningNotification"
    )
    precondition(
        AVCaptureSession.runtimeErrorNotification.rawValue
            == "AVCaptureSessionRuntimeErrorNotification"
    )
    precondition(
        AVCaptureSession.wasInterruptedNotification.rawValue
            == "AVCaptureSessionWasInterruptedNotification"
    )
    precondition(
        AVCaptureSession.interruptionEndedNotification.rawValue
            == "AVCaptureSessionInterruptionEndedNotification"
    )
    precondition(AVCaptureSessionErrorKey == "AVCaptureSessionErrorKey")
    precondition(AVCaptureSessionInterruptionReasonKey == "AVCaptureSessionInterruptionReasonKey")
    precondition(AVCaptureSession.InterruptionReason.videoDeviceNotAvailableInBackground.rawValue == 0)
    precondition(AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient.rawValue == 1)
    precondition(AVCaptureSession.InterruptionReason.videoDeviceInUseByAnotherClient.rawValue == 2)
    precondition(AVCaptureSession.InterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps.rawValue == 3)
    precondition(AVCaptureSession.InterruptionReason.videoDeviceNotAvailableDueToSystemPressure.rawValue == 4)
    precondition(AVCaptureSession.InterruptionReason.sensitiveContentMitigationActivated.rawValue == 5)
}

func testAVCMTimeValueBridgesCMTime() {
    let time = CMTime(seconds: 2.5, preferredTimescale: 600)
    let boxed = AVCMTimeValue.nsValue(for: time)
    let roundTrip = AVCMTimeValue.time(from: boxed)
    precondition(abs(roundTrip.seconds - 2.5) < 0.001)
}

func testAVErrorOverlayStaticCodes() {
    let rows: [(AVError.Code, Int)] = [
        (AVError.unknown, -11800),
        (AVError.outOfMemory, -11801),
        (AVError.sessionNotRunning, -11803),
        (AVError.deviceAlreadyUsedByAnotherSession, -11804),
        (AVError.noDataCaptured, -11805),
        (AVError.sessionConfigurationChanged, -11806),
        (AVError.diskFull, -11807),
        (AVError.deviceWasDisconnected, -11808),
        (AVError.mediaChanged, -11809),
        (AVError.maximumDurationReached, -11810),
        (AVError.maximumFileSizeReached, -11811),
        (AVError.mediaDiscontinuity, -11812),
        (AVError.maximumNumberOfSamplesForFileFormatReached, -11813),
        (AVError.deviceNotConnected, -11814),
        (AVError.deviceInUseByAnotherApplication, -11815),
        (AVError.deviceLockedForConfigurationByAnotherProcess, -11817),
        (AVError.sessionWasInterrupted, -11818),
        (AVError.mediaServicesWereReset, -11819),
        (AVError.exportFailed, -11820),
        (AVError.decodeFailed, -11821),
        (AVError.invalidSourceMedia, -11822),
        (AVError.fileAlreadyExists, -11823),
        (AVError.compositionTrackSegmentsNotContiguous, -11824),
        (AVError.invalidCompositionTrackSegmentDuration, -11825),
        (AVError.invalidCompositionTrackSegmentSourceStartTime, -11826),
        (AVError.invalidCompositionTrackSegmentSourceDuration, -11827),
        (AVError.fileFormatNotRecognized, -11828),
        (AVError.fileFailedToParse, -11829),
        (AVError.maximumStillImageCaptureRequestsExceeded, -11830),
        (AVError.contentIsProtected, -11831),
        (AVError.noImageAtTime, -11832),
        (AVError.decoderNotFound, -11833),
        (AVError.encoderNotFound, -11834),
        (AVError.contentIsNotAuthorized, -11835),
        (AVError.applicationIsNotAuthorized, -11836),
        (AVError.deviceIsNotAvailableInBackground, -11837),
        (AVError.operationNotSupportedForAsset, -11838),
        (AVError.decoderTemporarilyUnavailable, -11839),
        (AVError.encoderTemporarilyUnavailable, -11840),
        (AVError.invalidVideoComposition, -11841),
        (AVError.referenceForbiddenByReferencePolicy, -11842),
        (AVError.invalidOutputURLPathExtension, -11843),
        (AVError.screenCaptureFailed, -11844),
        (AVError.displayWasDisabled, -11845),
        (AVError.torchLevelUnavailable, -11846),
        (AVError.operationInterrupted, -11847),
        (AVError.incompatibleAsset, -11848),
        (AVError.failedToLoadMediaData, -11849),
        (AVError.serverIncorrectlyConfigured, -11850),
        (AVError.applicationIsNotAuthorizedToUseDevice, -11852),
        (AVError.failedToParse, -11853),
        (AVError.fileTypeDoesNotSupportSampleReferences, -11854),
        (AVError.undecodableMediaData, -11855),
        (AVError.airPlayControllerRequiresInternet, -11856),
        (AVError.airPlayReceiverRequiresInternet, -11857),
        (AVError.videoCompositorFailed, -11858),
        (AVError.recordingAlreadyInProgress, -11859),
        (AVError.unsupportedOutputSettings, -11861),
        (AVError.operationNotAllowed, -11862),
        (AVError.contentIsUnavailable, -11863),
        (AVError.formatUnsupported, -11864),
        (AVError.malformedDepth, -11865),
        (AVError.contentNotUpdated, -11866),
        (AVError.noLongerPlayable, -11867),
        (AVError.noCompatibleAlternatesForExternalDisplay, -11868),
        (AVError.noSourceTrack, -11869),
        (AVError.externalPlaybackNotSupportedForAsset, -11870),
        (AVError.operationNotSupportedForPreset, -11871),
        (AVError.sessionHardwareCostOverage, -11872),
        (AVError.unsupportedDeviceActiveFormat, -11873),
        (AVError.incorrectlyConfigured, -11875),
        (AVError.segmentStartedWithNonSyncSample, -11876),
        (AVError.rosettaNotInstalled, -11877),
        (AVError.operationCancelled, -11878),
        (AVError.contentKeyRequestCancelled, -11879),
        (AVError.invalidSampleCursor, -11880),
        (AVError.failedToLoadSampleData, -11881),
        (AVError.airPlayReceiverTemporarilyUnavailable, -11882),
        (AVError.encodeFailed, -11883),
        (AVError.sandboxExtensionDenied, -11884),
        (AVError.toneMappingFailed, -11885),
        (AVError.noSmartFramingsEnabled, -11890),
        (AVError.autoWhiteBalanceNotLocked, -11891),
        (AVError.followExternalSyncDeviceTimedOut, -11892),
    ]
    for (code, raw) in rows {
        precondition(code.rawValue == raw)
        precondition(AVError.Code(rawValue: raw) == code)
    }
}

func testAVVideoCompressionKeyPayloads() {
    precondition(AVVideoCodecKey == "AVVideoCodecKey")
    precondition(AVVideoWidthKey == "AVVideoWidthKey")
    precondition(AVVideoHeightKey == "AVVideoHeightKey")
    precondition(AVVideoCompressionPropertiesKey == "AVVideoCompressionPropertiesKey")
    precondition(AVVideoAverageBitRateKey == "AVVideoAverageBitRateKey")
    precondition(AVVideoMaxKeyFrameIntervalKey == "AVVideoMaxKeyFrameIntervalKey")
    precondition(AVVideoMaxKeyFrameIntervalDurationKey == "AVVideoMaxKeyFrameIntervalDurationKey")
    precondition(AVVideoQualityKey == "AVVideoQualityKey")
    precondition(AVVideoProfileLevelKey == "AVVideoProfileLevelKey")
    precondition(AVVideoH264EntropyModeKey == "AVVideoH264EntropyModeKey")
    precondition(AVVideoH264EntropyModeCABAC == "AVVideoH264EntropyModeCABAC")
    precondition(AVVideoH264EntropyModeCAVLC == "AVVideoH264EntropyModeCAVLC")
    precondition(AVVideoExpectedSourceFrameRateKey == "AVVideoExpectedSourceFrameRateKey")
    precondition(AVVideoAllowFrameReorderingKey == "AVVideoAllowFrameReorderingKey")
    precondition(AVVideoAllowWideColorKey == "AVVideoAllowWideColorKey")
    precondition(AVVideoScalingModeKey == "AVVideoScalingModeKey")
    precondition(AVVideoScalingModeFit == "AVVideoScalingModeFit")
    precondition(AVVideoScalingModeResize == "AVVideoScalingModeResize")
    precondition(AVVideoScalingModeResizeAspect == "AVVideoScalingModeResizeAspect")
    precondition(AVVideoScalingModeResizeAspectFill == "AVVideoScalingModeResizeAspectFill")
    precondition(AVVideoCodecH264 == "AVVideoCodecH264")
    precondition(AVVideoCodecHEVC == "AVVideoCodecHEVC")
    precondition(AVVideoCodecJPEG == "AVVideoCodecJPEG")
    precondition(AVVideoColorPropertiesKey == "AVVideoColorPropertiesKey")
    precondition(AVVideoColorPrimariesKey == "AVVideoColorPrimariesKey")
    precondition(AVVideoTransferFunctionKey == "AVVideoTransferFunctionKey")
    precondition(AVVideoYCbCrMatrixKey == "AVVideoYCbCrMatrixKey")
    precondition(AVVideoPixelAspectRatioKey == "AVVideoPixelAspectRatioKey")
    precondition(AVVideoCleanApertureKey == "AVVideoCleanApertureKey")
    precondition(AVVideoCleanApertureWidthKey == "AVVideoCleanApertureWidthKey")
    precondition(AVVideoCleanApertureHeightKey == "AVVideoCleanApertureHeightKey")
    precondition(AVVideoCleanApertureHorizontalOffsetKey == "AVVideoCleanApertureHorizontalOffsetKey")
    precondition(AVVideoCleanApertureVerticalOffsetKey == "AVVideoCleanApertureVerticalOffsetKey")
    precondition(AVURLAssetPreferPreciseDurationAndTimingKey == "AVURLAssetPreferPreciseDurationAndTimingKey")
    precondition(AVURLAssetAllowsCellularAccessKey == "AVURLAssetAllowsCellularAccessKey")
    precondition(AVURLAssetHTTPUserAgentKey == "AVURLAssetHTTPUserAgentKey")
    precondition(AVURLAssetOverrideMIMETypeKey == "AVURLAssetOverrideMIMETypeKey")
    precondition(AVURLAssetAllowsConstrainedNetworkAccessKey == "AVURLAssetAllowsConstrainedNetworkAccessKey")
    precondition(AVURLAssetAllowsExpensiveNetworkAccessKey == "AVURLAssetAllowsExpensiveNetworkAccessKey")
    precondition(AVURLAssetHTTPCookiesKey == "AVURLAssetHTTPCookiesKey")
    precondition(AVURLAssetPrimarySessionIdentifierKey == "AVURLAssetPrimarySessionIdentifierKey")
    precondition(AVURLAssetReferenceRestrictionsKey == "AVURLAssetReferenceRestrictionsKey")
    precondition(AVURLAssetShouldParseExternalSphericalTagsKey == "AVURLAssetShouldParseExternalSphericalTagsKey")
    precondition(AVURLAssetURLRequestAttributionKey == "AVURLAssetURLRequestAttributionKey")
    precondition(AVVideoAppleProRAWBitDepthKey == "AVVideoAppleProRAWBitDepthKey")
    precondition(AVVideoAverageNonDroppableFrameRateKey == "AVVideoAverageNonDroppableFrameRateKey")
    precondition(AVVideoDecompressionPropertiesKey == "AVVideoDecompressionPropertiesKey")
    precondition(AVVideoPixelAspectRatioHorizontalSpacingKey == "AVVideoPixelAspectRatioHorizontalSpacingKey")
    precondition(AVVideoPixelAspectRatioVerticalSpacingKey == "AVVideoPixelAspectRatioVerticalSpacingKey")
    precondition(AVVideoColorPrimaries_ITU_R_709_2 == "AVVideoColorPrimaries_ITU_R_709_2")
    precondition(AVVideoColorPrimaries_P3_D65 == "AVVideoColorPrimaries_P3_D65")
    precondition(AVVideoColorPrimaries_ITU_R_2020 == "AVVideoColorPrimaries_ITU_R_2020")
    precondition(AVVideoColorPrimaries_SMPTE_C == "AVVideoColorPrimaries_SMPTE_C")
    precondition(AVVideoTransferFunction_ITU_R_709_2 == "AVVideoTransferFunction_ITU_R_709_2")
    precondition(AVVideoTransferFunction_SMPTE_ST_2084_PQ == "AVVideoTransferFunction_SMPTE_ST_2084_PQ")
    precondition(AVVideoTransferFunction_ITU_R_2100_HLG == "AVVideoTransferFunction_ITU_R_2100_HLG")
    precondition(AVVideoTransferFunction_Linear == "AVVideoTransferFunction_Linear")
    precondition(AVVideoYCbCrMatrix_ITU_R_709_2 == "AVVideoYCbCrMatrix_ITU_R_709_2")
    precondition(AVVideoYCbCrMatrix_ITU_R_601_4 == "AVVideoYCbCrMatrix_ITU_R_601_4")
    precondition(AVVideoYCbCrMatrix_ITU_R_2020 == "AVVideoYCbCrMatrix_ITU_R_2020")
    precondition(AVVideoProfileLevelH264BaselineAutoLevel == "AVVideoProfileLevelH264BaselineAutoLevel")
    precondition(AVVideoProfileLevelH264MainAutoLevel == "AVVideoProfileLevelH264MainAutoLevel")
    precondition(AVVideoProfileLevelH264HighAutoLevel == "AVVideoProfileLevelH264HighAutoLevel")
    precondition(AVVideoProfileLevelH264Baseline30 == "AVVideoProfileLevelH264Baseline30")
    precondition(AVVideoProfileLevelH264Baseline31 == "AVVideoProfileLevelH264Baseline31")
    precondition(AVVideoProfileLevelH264Baseline41 == "AVVideoProfileLevelH264Baseline41")
    precondition(AVVideoProfileLevelH264Main30 == "AVVideoProfileLevelH264Main30")
    precondition(AVVideoProfileLevelH264Main31 == "AVVideoProfileLevelH264Main31")
    precondition(AVVideoProfileLevelH264Main32 == "AVVideoProfileLevelH264Main32")
    precondition(AVVideoProfileLevelH264Main41 == "AVVideoProfileLevelH264Main41")
    precondition(AVVideoProfileLevelH264High40 == "AVVideoProfileLevelH264High40")
    precondition(AVVideoProfileLevelH264High41 == "AVVideoProfileLevelH264High41")
    precondition(AVVideoTransferFunction_IEC_sRGB == "AVVideoTransferFunction_IEC_sRGB")
}

func testAVCaptureDeviceFailClosedDiscoveryModel() {
    let device = AVCaptureDevice()
    precondition(device.uniqueID.isEmpty)
    precondition(device.modelID.isEmpty)
    precondition(device.localizedName.isEmpty)
    precondition(device.manufacturer.isEmpty)
    precondition(!device.hasMediaType(.video))
    precondition(!device.isConnected)
    precondition(!device.isSuspended)
    precondition(device.formats.isEmpty)
    precondition(!device.isVideoFrameDurationLocked)
    precondition(device.minSupportedLockedVideoFrameDuration == .zero)
    precondition(!device.isFollowingExternalSyncDevice)
    precondition(device.minSupportedExternalSyncFrameDuration == .zero)
    precondition(!device.isAutoVideoFrameRateEnabled)
    precondition(device.position == .unspecified)
    precondition(device.deviceType.rawValue.isEmpty)
    precondition(AVCaptureDevice.userPreferredCamera == nil)
    precondition(AVCaptureDevice.systemPreferredCamera == nil)
    precondition(!device.isVirtualDevice)
    precondition(device.constituentDevices.isEmpty)
    precondition(device.virtualDeviceSwitchOverVideoZoomFactors.isEmpty)
    precondition(device.activePrimaryConstituent == nil)
    precondition(device.supportedFallbackPrimaryConstituentDevices.isEmpty)
    precondition(device.fallbackPrimaryConstituentDevices.isEmpty)
    precondition(!device.hasFlash)
    precondition(!device.isFlashAvailable)
    precondition(!device.isFlashActive)
    precondition(!device.isFlashModeSupported(.on))
    precondition(device.flashMode == .off)
    precondition(!device.hasTorch)
    precondition(!device.isTorchAvailable)
    precondition(!device.isTorchActive)
    precondition(device.torchLevel == 0)
    precondition(!device.isTorchModeSupported(.on))
    precondition(device.torchMode == .off)
    do {
        try device.setTorchModeOn(level: 1)
        preconditionFailure("torch must fail closed")
    } catch let error as AVError {
        precondition(error.code == .torchLevelUnavailable)
    } catch {
        preconditionFailure("unexpected torch error \(error)")
    }
    precondition(!device.isFocusModeSupported(.autoFocus))
    precondition(!device.isLockingFocusWithCustomLensPositionSupported)
    precondition(device.focusMode == .locked)
    precondition(!device.isFocusPointOfInterestSupported)
    precondition(device.focusPointOfInterest == .zero)
    precondition(!device.isFocusRectOfInterestSupported)
    precondition(device.minFocusRectOfInterestSize == .zero)
    precondition(device.focusRectOfInterest == .zero)
    precondition(device.defaultRectForFocusPoint(ofInterest: .zero) == .zero)
    precondition(!device.isAdjustingFocus)
    precondition(!device.isAutoFocusRangeRestrictionSupported)
    precondition(device.autoFocusRangeRestriction == .none)
    precondition(!device.isSmoothAutoFocusSupported)
    precondition(!device.isSmoothAutoFocusEnabled)
    precondition(!device.automaticallyAdjustsFaceDrivenAutoFocusEnabled)
    precondition(!device.isFaceDrivenAutoFocusEnabled)
    precondition(device.lensPosition == 0)
    precondition(device.minimumFocusDistance == 0)
    precondition(!device.isExposureModeSupported(.autoExpose))
    precondition(device.exposureMode == .locked)
    precondition(!device.isExposurePointOfInterestSupported)
    precondition(device.exposurePointOfInterest == .zero)
    precondition(!device.isExposureRectOfInterestSupported)
    precondition(device.minExposureRectOfInterestSize == .zero)
    precondition(device.exposureRectOfInterest == .zero)
    precondition(device.defaultRectForExposurePoint(ofInterest: .zero) == .zero)
    precondition(!device.automaticallyAdjustsFaceDrivenAutoExposureEnabled)
    precondition(!device.isFaceDrivenAutoExposureEnabled)
    precondition(device.activeMaxExposureDuration == .zero)
    precondition(!device.isAdjustingExposure)
    precondition(device.lensAperture == 0)
    precondition(device.exposureDuration == .zero)
    precondition(device.iso == 0)
    precondition(device.exposureTargetOffset == 0)
    precondition(device.exposureTargetBias == 0)
    precondition(device.minExposureTargetBias == 0)
    precondition(device.maxExposureTargetBias == 0)
    precondition(!device.isGlobalToneMappingEnabled)
    precondition(!device.isWhiteBalanceModeSupported(.autoWhiteBalance))
    precondition(!device.isLockingWhiteBalanceWithCustomDeviceGainsSupported)
    precondition(device.whiteBalanceMode == .locked)
    precondition(!device.isAdjustingWhiteBalance)
    precondition(device.maxWhiteBalanceGain == 0)
    precondition(!device.isSubjectAreaChangeMonitoringEnabled)
    precondition(!device.isLowLightBoostSupported)
    precondition(!device.isLowLightBoostEnabled)
    precondition(!device.automaticallyEnablesLowLightBoostWhenAvailable)
    device.videoZoomFactor = 2
    precondition(device.videoZoomFactor == 2)
    device.videoZoomFactor = 1
    precondition(device.videoZoomFactor == 1)
    precondition(!device.isRampingVideoZoom)
    device.ramp(toVideoZoomFactor: 2, withRate: 1)
    device.cancelVideoZoomRamp()
    precondition(device.dualCameraSwitchOverVideoZoomFactor == 0)
    precondition(device.displayVideoZoomFactorMultiplier == 0)
    precondition(!device.automaticallyAdjustsVideoHDREnabled)
    precondition(!device.isVideoHDREnabled)
    precondition(device.activeColorSpace == .sRGB)
    precondition(device.activeDepthDataFormat == nil)
    precondition(device.activeDepthDataMinFrameDuration == .zero)
    precondition(device.minAvailableVideoZoomFactor == 1)
    precondition(device.maxAvailableVideoZoomFactor == 1)
    precondition(!device.isGeometricDistortionCorrectionSupported)
    precondition(!device.isGeometricDistortionCorrectionEnabled)
    precondition(AVCaptureDevice.extrinsicMatrix(from: device, to: device) == nil)
    precondition(AVCaptureDevice.centerStageControlMode == .user)
    precondition(!AVCaptureDevice.isCenterStageEnabled)
    precondition(!device.isCenterStageActive)
    precondition(device.centerStageRectOfInterest == .zero)
    precondition(!AVCaptureDevice.isPortraitEffectEnabled)
    precondition(!device.isPortraitEffectActive)
    precondition(!AVCaptureDevice.reactionEffectsEnabled)
    precondition(!AVCaptureDevice.reactionEffectGesturesEnabled)
    precondition(!device.canPerformReactionEffects)
    precondition(device.availableReactionTypes.isEmpty)
    precondition(device.reactionEffectsInProgress.isEmpty)
    precondition(!AVCaptureDevice.isBackgroundReplacementEnabled)
    precondition(!device.isBackgroundReplacementActive)
    precondition(!AVCaptureDevice.isStudioLightEnabled)
    precondition(!device.isStudioLightActive)
    precondition(AVCaptureDevice.activeMicrophoneMode == .standard)
    precondition(AVCaptureDevice.preferredMicrophoneMode == .standard)
    precondition(
        AVCaptureDevice.wasConnectedNotification.rawValue
            == "AVCaptureDeviceWasConnectedNotification"
    )
    precondition(
        AVCaptureDevice.wasDisconnectedNotification.rawValue
            == "AVCaptureDeviceWasDisconnectedNotification"
    )
    precondition(
        AVCaptureDevice.subjectAreaDidChangeNotification.rawValue
            == "AVCaptureDeviceSubjectAreaDidChangeNotification"
    )
    precondition(AVCaptureDevice.maxAvailableTorchLevel == 0)
    precondition(AVCaptureDevice.currentLensPosition == 0)
    precondition(AVCaptureDevice.currentExposureDuration == .zero)
    precondition(AVCaptureDevice.currentISO == 0)
    precondition(AVCaptureDevice.currentExposureTargetBias == 0)
    _ = AVCaptureDevice.currentWhiteBalanceGains
    precondition(!device.isContinuityCamera)
    precondition(device.companionDeskViewCamera == nil)
    precondition(device.spatialCaptureDiscomfortReasons.isEmpty)
    precondition(device.cinematicVideoCaptureSceneMonitoringStatuses.isEmpty)
    precondition(device.dynamicAspectRatio == nil)
    precondition(device.dynamicDimensions.width == 0)
    precondition(device.smartFramingMonitor == nil)
    precondition(device.nominalFocalLengthIn35mmFilm == 0)
    precondition(!device.isCameraLensSmudgeDetectionEnabled)
    precondition(device.cameraLensSmudgeDetectionInterval == .zero)
    precondition(device.cameraLensSmudgeDetectionStatus == .disabled)
    device.setCameraLensSmudgeDetectionEnabled(true, detectionInterval: .zero)
    device.setPrimaryConstituentDeviceSwitchingBehavior(.auto, restrictedSwitchingBehaviorConditions: [])
    precondition(device.primaryConstituentDeviceSwitchingBehavior == .unsupported)
    _ = device.systemPressureState
    _ = device.activeFormat
    device.activeVideoMinFrameDuration = .zero
    device.activeVideoMaxFrameDuration = .zero
    AVCaptureDevice.showSystemUserInterface(.videoEffects)
}

func testAVCaptureDeviceFormatFailClosedModel() {
    let format = AVCaptureDevice.Format()
    precondition(format.supportedColorSpaces.isEmpty)
    precondition(format.supportedMaxPhotoDimensions.isEmpty)
    precondition(!format.isPortraitEffectsMatteStillImageDeliverySupported)
    precondition(!format.isMultiCamSupported)
    precondition(!format.isSpatialVideoCaptureSupported)
    precondition(format.geometricDistortionCorrectedVideoFieldOfView == 0)
    precondition(!format.isCenterStageSupported)
    precondition(format.videoMinZoomFactorForCenterStage == 0)
    precondition(format.videoMaxZoomFactorForCenterStage == 0)
    precondition(format.videoFrameRateRangeForCenterStage == nil)
    precondition(!format.isPortraitEffectSupported)
    precondition(format.videoFrameRateRangeForPortraitEffect == nil)
    precondition(!format.isStudioLightSupported)
    precondition(format.videoFrameRateRangeForStudioLight == nil)
    precondition(!format.reactionEffectsSupported)
    precondition(format.videoFrameRateRangeForReactionEffectsInProgress == nil)
    precondition(!format.isBackgroundReplacementSupported)
    precondition(format.videoFrameRateRangeForBackgroundReplacement == nil)
    precondition(!format.isCinematicVideoCaptureSupported)
    precondition(format.defaultSimulatedAperture == 0)
    precondition(format.minSimulatedAperture == 0)
    precondition(format.maxSimulatedAperture == 0)
    precondition(format.videoMinZoomFactorForCinematicVideo == 0)
    precondition(format.videoMaxZoomFactorForCinematicVideo == 0)
    precondition(format.videoFrameRateRangeForCinematicVideo == nil)
    precondition(format.supportedDynamicAspectRatios.isEmpty)
    precondition(format.videoFieldOfView(for: AVCaptureDevice.AspectRatio.ratio16x9, geometricDistortionCorrected: false) == 0)
    precondition(!format.isSmartFramingSupported)
    precondition(!format.isCameraLensSmudgeDetectionSupported)
    precondition(format.mediaType.rawValue.isEmpty)
    precondition(format.videoSupportedFrameRateRanges.isEmpty)
    precondition(format.videoFieldOfView == 0)
    precondition(!format.isVideoBinned)
    precondition(!format.isVideoStabilizationModeSupported(.auto))
    precondition(!format.isVideoStabilizationSupported)
    precondition(format.videoMaxZoomFactor == 0)
    precondition(format.videoZoomFactorUpscaleThreshold == 0)
    precondition(format.minExposureDuration == .zero)
    precondition(format.maxExposureDuration == .zero)
    precondition(format.minISO == 0)
    precondition(format.maxISO == 0)
    precondition(!format.isGlobalToneMappingSupported)
    precondition(!format.isVideoHDRSupported)
    precondition(format.highResolutionStillImageDimensions.width == 0)
    precondition(!format.isHighPhotoQualitySupported)
    precondition(!format.isHighestPhotoQualitySupported)
    precondition(format.autoFocusSystem == .none)
    precondition(format.videoMinZoomFactorForDepthDataDelivery == 0)
    precondition(format.videoMaxZoomFactorForDepthDataDelivery == 0)
    precondition(!format.zoomFactorsOutsideOfVideoZoomRangesForDepthDeliverySupported)
    precondition(format.supportedDepthDataFormats.isEmpty)
    precondition(format.unsupportedCaptureOutputClasses.isEmpty)
    precondition(!format.isAutoVideoFrameRateSupported)
}

func testAVCaptureConnectionAndDeviceInputModel() {
    let output = AVCaptureOutput()
    let port = AVCaptureInput.Port()
    let connection = AVCaptureConnection(inputPorts: [port], output: output)
    precondition(connection.inputPorts.count == 1)
    precondition(connection.output === output)
    precondition(connection.isEnabled)
    connection.isEnabled = false
    precondition(!connection.isEnabled)
    precondition(!connection.isActive)
    precondition(connection.audioChannels.isEmpty)
    precondition(!connection.isVideoMirroringSupported)
    precondition(!connection.isVideoMirrored)
    precondition(!connection.automaticallyAdjustsVideoMirroring)
    precondition(!connection.isVideoRotationAngleSupported(90))
    precondition(connection.videoRotationAngle == 0)
    precondition(!connection.isVideoOrientationSupported)
    precondition(connection.videoOrientation == .portrait)
    precondition(connection.videoMaxScaleAndCropFactor == 0)
    precondition(connection.videoScaleAndCropFactor == 0)
    precondition(!connection.isVideoStabilizationSupported)
    precondition(!connection.isVideoStabilizationEnabled)
    precondition(!connection.isCameraIntrinsicMatrixDeliverySupported)
    precondition(!connection.isCameraIntrinsicMatrixDeliveryEnabled)

    let input = AVCaptureDeviceInput()
    precondition(input.ports.isEmpty)
    _ = input.device
    precondition(!input.unifiedAutoExposureDefaultsEnabled)
    precondition(input.ports(for: .video, sourceDeviceType: .builtInWideAngleCamera, sourceDevicePosition: .back).isEmpty)
    precondition(input.videoMinFrameDurationOverride == .zero)
    precondition(!input.isLockedVideoFrameDurationSupported)
    precondition(input.activeLockedVideoFrameDuration == .zero)
    precondition(!input.isExternalSyncSupported)
    precondition(input.externalSyncDevice == nil)
    input.unfollowExternalSyncDevice()
    precondition(!input.isMultichannelAudioModeSupported(.stereo))
    precondition(!input.isWindNoiseRemovalSupported)
    precondition(!input.isWindNoiseRemovalEnabled)
    precondition(!input.isCinematicVideoCaptureSupported)
    precondition(!input.isCinematicVideoCaptureEnabled)
    precondition(input.simulatedAperture == 0)
}

func testAVAssetWriterInputPixelBufferAdaptorFailClosed() {
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input)
    precondition(adaptor.assetWriterInput === input)
    precondition(adaptor.sourcePixelBufferAttributes == nil)
    precondition(adaptor.pixelBufferPool == nil)
}

func testAVAssetCompatibilityFlagsAndUnusedTrackID() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-compat.mp4"))
    precondition(!asset.isCompatibleWithAirPlayVideo)
    precondition(!asset.isCompatibleWithSavedPhotosAlbum)
    precondition(!asset.providesPreciseDurationAndTiming)
    precondition(asset.creationDate == nil)
    precondition(asset.trackGroups.isEmpty)
    precondition(asset.availableChapterLocales.isEmpty)
    precondition(asset.allMediaSelections.isEmpty)
    precondition(asset.availableMediaCharacteristicsWithMediaSelectionOptions.isEmpty)
    precondition(asset.mediaSelectionGroup(forMediaCharacteristic: .audible) == nil)
    precondition(asset.overallDurationHint == .invalid)
    precondition(asset.minimumTimeOffsetFromLive == .invalid)
    asset.cancelLoading()
    let seen = AVFLocked(false)
    asset.findUnusedTrackID { trackID, error in
        seen.store(true)
        precondition(error == nil)
        precondition(trackID == 1)
    }
    precondition(seen.load())
}

func testAVAudioTimePitchAndImageGeneratorApertureConstants() {
    precondition(AVAudioTimePitchAlgorithm.timeDomain.rawValue == "timeDomain")
    precondition(AVAudioTimePitchAlgorithm.spectral.rawValue == "spectral")
    precondition(AVAudioTimePitchAlgorithm.lowQualityZeroLatency.rawValue == "lowQualityZeroLatency")
    precondition(AVAudioTimePitchAlgorithm.varispeed.rawValue == "varispeed")
    precondition(AVAssetImageGenerator.ApertureMode.encodedPixels.rawValue == "encodedPixels")
    precondition(AVAssetImageGenerator.ApertureMode.productionAperture.rawValue == "productionAperture")
    precondition(AVAssetImageGenerator.ApertureMode.cleanAperture.rawValue == "cleanAperture")
    precondition(AVAssetWriterInput.MediaDataLocation.interleavedWithMainMediaData.rawValue == "interleavedWithMainMediaData")
    precondition(AVAssetWriterInput.MediaDataLocation.beforeMainMediaDataNotInterleaved.rawValue == "beforeMainMediaDataNotInterleaved")
    precondition(AVAssetWriterInput.MediaDataLocation.sparselyInterleavedWithMainMediaData.rawValue == "sparselyInterleavedWithMainMediaData")
}
