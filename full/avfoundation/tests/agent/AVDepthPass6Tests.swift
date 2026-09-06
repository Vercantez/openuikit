import Foundation
import AVFoundation

final class AVDepthPass6FileDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var finishedURL: URL?
    var finishedError: (any Error)?
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        _ = (output, connections)
        finishedURL = outputFileURL
        finishedError = error
    }
}

final class AVDepthPass6KeyDelegate: NSObject, AVContentKeySessionDelegate, @unchecked Sendable {
    var failedRequest: AVContentKeyRequest?
    var failedError: (any Error)?
    func contentKeySession(
        _ session: AVContentKeySession,
        contentKeyRequest keyRequest: AVContentKeyRequest,
        didFailWithError err: any Error
    ) {
        _ = session
        failedRequest = keyRequest
        failedError = err
    }
}

final class AVDepthPass6PullDelegate: NSObject, AVPlayerItemOutputPullDelegate {}
final class AVDepthPass6LegibleDelegate: NSObject, AVPlayerItemLegibleOutputPushDelegate {}
final class AVDepthPass6WriterDelegate: NSObject, AVAssetWriterDelegate {}

func testAVAssetWriterStoredConfigurationAndCancel() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-writer-config-\(UUID().uuidString).mp4")
    let writer = try! AVAssetWriter(URL: url, fileType: .mp4)
    precondition(writer.outputURL == url)
    precondition(writer.outputFileType == .mp4)
    precondition(writer.status == .unknown)

    let title = AVMutableMetadataItem()
    title.identifier = .commonIdentifierTitle
    writer.metadata = [title]
    writer.shouldOptimizeForNetworkUse = true
    let temp = FileManager.default.temporaryDirectory
    writer.directoryForTemporaryFiles = temp
    writer.movieFragmentInterval = CMTime(seconds: 2, preferredTimescale: 600)
    writer.initialMovieFragmentInterval = CMTime(seconds: 1, preferredTimescale: 600)
    writer.initialMovieFragmentSequenceNumber = 7
    writer.producesCombinableFragments = true
    writer.overallDurationHint = CMTime(seconds: 10, preferredTimescale: 600)
    writer.movieTimeScale = 600
    writer.preferredOutputSegmentInterval = CMTime(seconds: 4, preferredTimescale: 600)
    writer.initialSegmentStartTime = CMTime(seconds: 0.5, preferredTimescale: 600)
    writer.outputFileTypeProfile = .mpeg4AppleHLS
    let writerDelegate = AVDepthPass6WriterDelegate()
    writer.delegate = writerDelegate
    precondition(writer.metadata.count == 1)
    precondition(writer.shouldOptimizeForNetworkUse)
    precondition(writer.directoryForTemporaryFiles == temp)
    precondition(writer.movieFragmentInterval.seconds == 2)
    precondition(writer.initialMovieFragmentInterval.seconds == 1)
    precondition(writer.initialMovieFragmentSequenceNumber == 7)
    precondition(writer.producesCombinableFragments)
    precondition(writer.overallDurationHint.seconds == 10)
    precondition(writer.movieTimeScale == 600)
    precondition(writer.preferredOutputSegmentInterval.seconds == 4)
    precondition(writer.initialSegmentStartTime.seconds == 0.5)
    precondition(writer.outputFileTypeProfile == .mpeg4AppleHLS)
    precondition(writer.delegate === writerDelegate)
    precondition(!writer.canApply(outputSettings: ["AVVideoCodecKey": "avc1"], forMediaType: .video))

    let video = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
    precondition(writer.canAdd(video))
    writer.add(video)
    writer.add(audio)
    let group = AVAssetWriterInputGroup(inputs: [video, audio], defaultInput: video)
    precondition(group.inputs.count == 2)
    precondition(group.defaultInput === video)
    precondition(writer.canAdd(group))
    writer.add(group)
    precondition(writer.inputGroups.count == 1)
    precondition(writer.inputs.count == 2)

    writer.startSession(atSourceTime: .zero)
    writer.endSession(atSourceTime: CMTime(seconds: 1, preferredTimescale: 600))
    writer.flushSegment()
    writer.cancelWriting()
    precondition(writer.status == .cancelled)
    precondition(AVAssetWriter.Status.unknown.rawValue == 0)
    precondition(AVAssetWriter.Status.writing.rawValue == 1)
    precondition(AVAssetWriter.Status.completed.rawValue == 2)
    precondition(AVAssetWriter.Status.failed.rawValue == 3)
    precondition(AVAssetWriter.Status.cancelled.rawValue == 4)

    let tagged = AVAssetWriterInputTaggedPixelBufferGroupAdaptor(
        assetWriterInput: video,
        sourcePixelBufferAttributes: ["Width": 16]
    )
    precondition(tagged.assetWriterInput === video)
    precondition(tagged.sourcePixelBufferAttributes?["Width"] as? Int == 16)
    precondition(tagged.pixelBufferPool == nil)
    let pixel = AVAssetWriterInput.PixelBufferReceiver()
    precondition(pixel.sourcePixelBufferAttributes == nil)
    precondition((try? pixel.appendImmediately(CVReadOnlyPixelBuffer(), with: .zero)) == false)
    pixel.finish()
    let taggedReceiver = AVAssetWriterInput.TaggedPixelBufferGroupReceiver()
    precondition(taggedReceiver.sourcePixelBufferAttributes == nil)
    precondition((try? taggedReceiver.appendImmediately([], with: .zero)) == false)
    taggedReceiver.finish()
}

func testAVAssetReaderOutputsStoredConfiguration() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-reader-pass6.mp4"))
    let reader = try! AVAssetReader(asset: asset)
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600))
    reader.timeRange = range
    precondition(reader.timeRange.duration.seconds == 1)

    let track = AVAssetTrack()
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: ["AVFormatIDKey": 0])
    trackOutput.alwaysCopiesSampleData = true
    trackOutput.supportsRandomAccess = true
    trackOutput.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm(rawValue: "spectral")
    trackOutput.reset(forReadingTimeRanges: [NSNumber(value: 0)])
    trackOutput.markConfigurationAsFinal()
    precondition(trackOutput.track === track)
    precondition(trackOutput.outputSettings?["AVFormatIDKey"] as? Int == 0)
    precondition(trackOutput.alwaysCopiesSampleData)
    precondition(trackOutput.supportsRandomAccess)
    precondition(trackOutput.audioTimePitchAlgorithm.rawValue == "spectral")
    precondition(trackOutput.copyNextSampleBuffer() == nil)
    precondition(reader.canAdd(trackOutput))
    reader.add(trackOutput)

    let mix = AVAssetReaderAudioMixOutput(audioTracks: [track], audioSettings: ["AVSampleRateKey": 8000])
    mix.audioMix = AVAudioMix()
    mix.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm(rawValue: "timeDomain")
    precondition(mix.audioTracks.count == 1)
    precondition(mix.audioSettings?["AVSampleRateKey"] as? Int == 8000)
    precondition(mix.audioMix != nil)
    reader.add(mix)

    let video = AVAssetReaderVideoCompositionOutput(videoTracks: [track], videoSettings: ["Width": 320])
    video.videoComposition = AVVideoComposition()
    precondition(video.videoTracks.count == 1)
    precondition(video.videoSettings?["Width"] as? Int == 320)
    precondition(video.videoComposition != nil)
    precondition(video.customVideoCompositor == nil)
    reader.add(video)

    let sampleRef = AVAssetReaderSampleReferenceOutput(track: track)
    precondition(sampleRef.track === track)
    reader.add(sampleRef)

    let captions = AVAssetReaderOutputCaptionAdaptor(assetReaderTrackOutput: trackOutput)
    precondition(captions.assetReaderTrackOutput === trackOutput)
    precondition(captions.nextCaptionGroup() == nil)
    precondition(captions.captionsNotPresentInPreviousGroups(in: AVCaptionGroup()).isEmpty)
    captions.validationDelegate = nil

    let metadata = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: trackOutput)
    precondition(metadata.assetReaderTrackOutput === trackOutput)
    precondition(metadata.nextTimedMetadataGroup() == nil)

    let controller = AVAssetReaderOutput.RandomAccessController()
    controller.resetForReading(timeRanges: [range])
    controller.markConfigurationAsFinal()

    precondition(reader.outputs.count == 4)
    reader.cancelReading()
    precondition(reader.status == .cancelled)
    precondition(AVAssetReader.Status.unknown.rawValue == 0)
    precondition(AVAssetReader.Status.reading.rawValue == 1)
    precondition(AVAssetReader.Status.completed.rawValue == 2)
    precondition(AVAssetReader.Status.failed.rawValue == 3)
    precondition(AVAssetReader.Status.cancelled.rawValue == 4)
}

func testAVContentKeySessionFailClosedWithoutFairPlay() {
    let storage = FileManager.default.temporaryDirectory.appendingPathComponent("openav-keys")
    try? FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
    let session = AVContentKeySession(keySystem: .fairPlayStreaming, storageDirectoryAt: storage)
    precondition(session.keySystem == .fairPlayStreaming)
    precondition(session.keySystem.rawValue == "AVContentKeySystemFairPlayStreaming")
    precondition(AVContentKeySystem.clearKey.rawValue == "AVContentKeySystemClearKey")
    precondition(AVContentKeySystem.authorizationToken.rawValue == "AVContentKeySystemAuthorizationToken")
    precondition(session.storageURL == storage)
    let delegate = AVDepthPass6KeyDelegate()
    let queue = DispatchQueue(label: "openav.keys")
    session.setDelegate(delegate, queue: queue)
    precondition(session.delegate === delegate)
    precondition(session.delegateQueue === queue)
    precondition(session.contentProtectionSessionIdentifier == nil)

    let recipient = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-fairplay.mp4"))
    session.addContentKeyRecipient(recipient)
    precondition(session.contentKeyRecipients.count == 1)
    session.processContentKeyRequest(
        withIdentifier: "probe",
        initializationData: Data([0x01]),
        options: [AVContentKeyRequestProtocolVersionsKey: [1]]
    )
    precondition(delegate.failedRequest != nil)
    precondition((delegate.failedError as? AVError)?.code == .contentKeyRequestCancelled)
    precondition(delegate.failedRequest?.status == .failed)
    precondition(delegate.failedRequest?.canProvidePersistableContentKey == false)
    precondition(delegate.failedRequest?.contentKey == nil)
    precondition(delegate.failedRequest?.renewsExpiringResponseData == false)
    session.renewExpiringResponseData(for: delegate.failedRequest!)
    precondition(delegate.failedRequest?.status == .failed)

    do {
        try delegate.failedRequest?.respondByRequestingPersistableContentKeyRequestAndReturnError()
        preconditionFailure("persistable request must fail closed")
    } catch let error as AVError {
        precondition(error.code == .contentKeyRequestCancelled)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
    delegate.failedRequest?.respondByRequestingPersistableContentKeyRequest()
    delegate.failedRequest?.processContentKeyResponse(
        AVContentKeyResponse(fairPlayStreamingKeyResponseData: Data([0x02]))
    )
    precondition(delegate.failedRequest?.status == .failed)
    delegate.failedRequest?.processContentKeyResponseError(AVError(.contentKeyRequestCancelled))

    precondition(AVContentKeyRequest.RetryReason.timedOut.rawValue == "AVContentKeyRequestRetryReasonTimedOut")
    precondition(
        AVContentKeyRequest.RetryReason.receivedResponseWithExpiredLease.rawValue
            == "AVContentKeyRequestRetryReasonReceivedResponseWithExpiredLease"
    )
    precondition(
        AVContentKeyRequest.RetryReason.receivedObsoleteContentKey.rawValue
            == "AVContentKeyRequestRetryReasonReceivedObsoleteContentKey"
    )
    precondition(AVContentKeyRequest.Status.requestingResponse.rawValue == 0)
    precondition(AVContentKeyRequest.Status.receivedResponse.rawValue == 1)
    precondition(AVContentKeyRequest.Status.renewed.rawValue == 2)
    precondition(AVContentKeyRequest.Status.retried.rawValue == 3)
    precondition(AVContentKeyRequest.Status.cancelled.rawValue == 4)
    precondition(AVContentKeyRequest.Status.failed.rawValue == 5)

    let specifier = AVContentKeySpecifier(
        forKeySystem: .clearKey,
        identifier: "id",
        options: ["k": "v"]
    )
    precondition(specifier.keySystem == .clearKey)
    let key = AVContentKey()
    key.revoke()
    precondition(key.portableIsRevoked)
    precondition(key.externalContentProtectionStatus == .pending)

    session.expire()
    precondition(session.portableIsExpired)
    session.removeContentKeyRecipient(recipient)
    precondition(session.contentKeyRecipients.isEmpty)
    precondition(
        AVContentKeySession.pendingExpiredSessionReports(
            withAppIdentifier: Data(),
            storageDirectoryAt: storage
        ).isEmpty
    )
    AVContentKeySession.removePendingExpiredSessionReports(
        [],
        withAppIdentifier: Data(),
        storageDirectoryAt: storage
    )
    do {
        _ = try AVPersistableContentKeyRequest().persistableContentKey(
            fromKeyVendorResponse: Data(),
            options: nil
        )
        preconditionFailure("persistable content key must fail closed")
    } catch let error as AVError {
        precondition(error.code == .contentKeyRequestCancelled)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testAVCaptureMovieAndStillOutputsFailClosed() {
    let movie = AVCaptureMovieFileOutput()
    movie.movieFragmentInterval = CMTime(seconds: 2, preferredTimescale: 600)
    let item = AVMutableMetadataItem()
    item.identifier = .commonIdentifierTitle
    movie.metadata = [item]
    movie.isPrimaryConstituentDeviceSwitchingBehaviorForRecordingEnabled = true
    movie.setPrimaryConstituentDeviceSwitchingBehaviorForRecording(
        .restricted,
        restrictedSwitchingBehaviorConditions: [.videoZoomChanged]
    )
    movie.isSpatialVideoCaptureEnabled = true
    precondition(movie.movieFragmentInterval.seconds == 2)
    precondition(movie.metadata?.count == 1)
    precondition(movie.availableVideoCodecTypes.isEmpty)
    precondition(movie.isPrimaryConstituentDeviceSwitchingBehaviorForRecordingEnabled)
    precondition(movie.primaryConstituentDeviceSwitchingBehaviorForRecording == .restricted)
    precondition(movie.primaryConstituentDeviceRestrictedSwitchingBehaviorConditionsForRecording.contains(.videoZoomChanged))
    precondition(!movie.isSpatialVideoCaptureSupported)
    precondition(movie.isSpatialVideoCaptureEnabled)
    let connection = AVCaptureConnection()
    movie.setOutputSettings(["AVVideoCodecKey": "avc1"], for: connection)
    precondition(movie.outputSettings(for: connection)["AVVideoCodecKey"] as? String == "avc1")
    precondition(movie.supportedOutputSettingsKeys(for: connection).isEmpty)
    movie.setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(true, for: connection)
    precondition(movie.recordsVideoOrientationAndMirroringChangesAsMetadataTrack(for: connection))

    movie.maxRecordedDuration = CMTime(seconds: 5, preferredTimescale: 600)
    movie.maxRecordedFileSize = 1024
    movie.minFreeDiskSpaceLimit = 2048
    precondition(movie.maxRecordedDuration.seconds == 5)
    precondition(movie.maxRecordedFileSize == 1024)
    precondition(movie.minFreeDiskSpaceLimit == 2048)
    precondition(!movie.isRecording)
    precondition(!movie.isRecordingPaused)
    precondition(movie.recordedDuration == .zero)
    precondition(movie.recordedFileSize == 0)
    movie.pauseRecording()
    movie.resumeRecording()
    movie.stopRecording()

    let dest = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-movie-\(UUID().uuidString).mov")
    let fileDelegate = AVDepthPass6FileDelegate()
    movie.startRecording(to: dest, recordingDelegate: fileDelegate)
    precondition(fileDelegate.finishedURL == dest)
    precondition((fileDelegate.finishedError as? AVError)?.code == .applicationIsNotAuthorizedToUseDevice)
    precondition(!movie.isRecording)
    precondition(movie.outputFileURL == dest)

    let still = AVCaptureStillImageOutput()
    still.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
    still.automaticallyEnablesStillImageStabilizationWhenAvailable = true
    still.isHighResolutionStillImageOutputEnabled = true
    still.isCameraSensorOrientationCompensationEnabled = true
    still.isLensStabilizationDuringBracketedCaptureEnabled = true
    precondition(still.outputSettings[AVVideoCodecKey] as? AVVideoCodecType == .jpeg)
    precondition(still.availableImageDataCVPixelFormatTypes.isEmpty)
    precondition(still.availableImageDataCodecTypes.isEmpty)
    precondition(!still.isStillImageStabilizationSupported)
    precondition(still.automaticallyEnablesStillImageStabilizationWhenAvailable)
    precondition(!still.isStillImageStabilizationActive)
    precondition(still.isHighResolutionStillImageOutputEnabled)
    precondition(!still.isCameraSensorOrientationCompensationSupported)
    precondition(still.isCameraSensorOrientationCompensationEnabled)
    precondition(!still.isCapturingStillImage)
    precondition(still.maxBracketedCaptureStillImageCount == 0)
    precondition(!still.isLensStabilizationDuringBracketedCaptureSupported)
    precondition(still.isLensStabilizationDuringBracketedCaptureEnabled)
    precondition(AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer()) == nil)

    var stillSeen = 0
    still.captureStillImageAsynchronously(from: connection) { buffer, error in
        stillSeen += 1
        precondition(buffer == nil)
        precondition((error as? AVError)?.code == .applicationIsNotAuthorizedToUseDevice)
    }
    precondition(stillSeen == 1)
    var bracketSeen = 0
    still.captureStillImageBracketAsynchronously(
        from: connection,
        withSettingsArray: []
    ) { buffer, settings, error in
        bracketSeen += 1
        precondition(buffer == nil)
        precondition(settings == nil)
        precondition((error as? AVError)?.code == .applicationIsNotAuthorizedToUseDevice)
    }
    precondition(bracketSeen == 1)
    var prepared = 0
    still.prepareToCaptureStillImageBracket(
        from: connection,
        withSettingsArray: []
    ) { ok, error in
        prepared += 1
        precondition(!ok)
        precondition((error as? AVError)?.code == .applicationIsNotAuthorizedToUseDevice)
    }
    precondition(prepared == 1)
}

func testAVCaptureResolvedPhotoSettingsFailClosedDimensions() {
    let settings = AVCapturePhotoSettings()
    let output = AVCapturePhotoOutput()
    final class PhotoProbe: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
        var resolved: AVCaptureResolvedPhotoSettings?
        func photoOutput(
            _ output: AVCapturePhotoOutput,
            didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
            error: (any Error)?
        ) {
            _ = (output, error)
            resolved = resolvedSettings
        }
    }
    let probe = PhotoProbe()
    output.capturePhoto(with: settings, delegate: probe)
    let resolved = probe.resolved ?? AVCaptureResolvedPhotoSettings()
    precondition(resolved.uniqueID == settings.uniqueID || resolved.uniqueID == 0)
    precondition(resolved.photoDimensions.width == 0)
    precondition(resolved.photoDimensions.height == 0)
    precondition(resolved.rawPhotoDimensions.width == 0)
    precondition(resolved.previewDimensions.width == 0)
    precondition(resolved.embeddedThumbnailDimensions.width == 0)
    precondition(resolved.rawEmbeddedThumbnailDimensions.width == 0)
    precondition(resolved.portraitEffectsMatteDimensions.width == 0)
    precondition(resolved.livePhotoMovieDimensions.width == 0)
    precondition(resolved.deferredPhotoProxyDimensions.width == 0)
    precondition(
        resolved.dimensionsForSemanticSegmentationMatte(ofType: .skin).width == 0
    )
    precondition(!resolved.isFlashEnabled)
    precondition(!resolved.isRedEyeReductionEnabled)
    precondition(!resolved.isStillImageStabilizationEnabled)
    precondition(!resolved.isVirtualDeviceFusionEnabled)
    precondition(!resolved.isDualCameraFusionEnabled)
    precondition(resolved.expectedPhotoCount == 0)
    precondition(resolved.photoProcessingTimeRange.duration == .zero)
    precondition(!resolved.isContentAwareDistortionCorrectionEnabled)
    precondition(!resolved.isFastCapturePrioritizationEnabled)
}

func testAVOutputSettingsPresetRawValuesAndAssistant() {
    let rows: [(AVOutputSettingsPreset, String)] = [
        (.preset640x480, "AVOutputSettingsPreset640x480"),
        (.preset960x540, "AVOutputSettingsPreset960x540"),
        (.preset1280x720, "AVOutputSettingsPreset1280x720"),
        (.preset1920x1080, "AVOutputSettingsPreset1920x1080"),
        (.preset3840x2160, "AVOutputSettingsPreset3840x2160"),
        (.hevc1920x1080, "AVOutputSettingsPresetHEVC1920x1080"),
        (.hevc1920x1080WithAlpha, "AVOutputSettingsPresetHEVC1920x1080WithAlpha"),
        (.hevc3840x2160, "AVOutputSettingsPresetHEVC3840x2160"),
        (.hevc3840x2160WithAlpha, "AVOutputSettingsPresetHEVC3840x2160WithAlpha"),
        (.hevc4320x2160, "AVOutputSettingsPresetHEVC4320x2160"),
        (.hevc7680x4320, "AVOutputSettingsPresetHEVC7680x4320"),
        (.mvhevc960x960, "AVOutputSettingsPresetMVHEVC960x960"),
        (.mvhevc1440x1440, "AVOutputSettingsPresetMVHEVC1440x1440"),
        (.mvhevc4320x4320, "AVOutputSettingsPresetMVHEVC4320x4320"),
        (.mvhevc7680x7680, "AVOutputSettingsPresetMVHEVC7680x7680"),
    ]
    for (preset, payload) in rows {
        precondition(preset.rawValue == payload)
        precondition(AVOutputSettingsPreset(rawValue: payload) == preset)
    }
    precondition(AVOutputSettingsAssistant.availableOutputSettingsPresets().isEmpty)
    precondition(AVOutputSettingsAssistant(preset: .preset1280x720) == nil)
    let assistant = AVOutputSettingsAssistant()
    assistant.sourceVideoAverageFrameDuration = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)
    assistant.sourceVideoMinFrameDuration = CMTime(seconds: 1.0 / 60.0, preferredTimescale: 600)
    assistant.sourceAudioFormat = nil
    assistant.sourceVideoFormat = nil
    precondition(assistant.audioSettings == nil)
    precondition(assistant.videoSettings == nil)
    precondition(assistant.outputFileType == .mp4)
    precondition(abs(assistant.sourceVideoAverageFrameDuration.seconds - 1.0 / 30.0) < 0.001)
    precondition(abs(assistant.sourceVideoMinFrameDuration.seconds - 1.0 / 60.0) < 0.001)
    precondition(assistant.sourceAudioFormat == nil)
    precondition(assistant.sourceVideoFormat == nil)
}

func testAVPlayerItemOutputsStoredDelegates() {
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-item-outputs.mp4"))
    let pull = AVDepthPass6PullDelegate()
    let queue = DispatchQueue(label: "openav.item.output")

    let video = AVPlayerItemVideoOutput(outputSettings: ["Width": 64])
    video.setDelegate(pull, queue: queue)
    video.requestNotificationOfMediaDataChange(withAdvanceInterval: 0.25)
    video.suppressesPlayerRendering = true
    precondition(video.delegate === pull)
    precondition(video.delegateQueue === queue)
    precondition(video.suppressesPlayerRendering)
    precondition(!video.hasNewPixelBuffer(forItemTime: .zero))
    precondition(video.copyPixelBuffer(forItemTime: .zero, itemTimeForDisplay: nil) == nil)
    let hostTime = video.itemTime(forHostTime: 1.5)
    precondition(abs(hostTime.seconds - 1.5) < 0.01)
    let machTime = video.itemTime(forMachAbsoluteTime: 2_000_000_000)
    precondition(machTime.seconds == 2)

    let attributes = AVPlayerItemVideoOutput(pixelBufferAttributes: ["Height": 32])
    item.add(attributes)
    item.add(video)
    precondition(item.outputs.count == 2)
    item.remove(attributes)
    precondition(item.outputs.count == 1)

    let legible = AVPlayerItemLegibleOutput(mediaSubtypesForNativeRepresentation: [NSNumber(value: 1)])
    let legibleDelegate = AVDepthPass6LegibleDelegate()
    legible.setDelegate(legibleDelegate, queue: queue)
    legible.advanceIntervalForDelegateInvocation = 0.1
    legible.textStylingResolution = .sourceAndRulesOnly
    precondition(legible.delegate === legibleDelegate)
    precondition(legible.delegateQueue === queue)
    precondition(legible.advanceIntervalForDelegateInvocation == 0.1)
    precondition(legible.textStylingResolution == .sourceAndRulesOnly)
    precondition(AVPlayerItemLegibleOutput.TextStylingResolution.default.rawValue == "default")
    item.add(legible)

    let metadataOut = AVPlayerItemMetadataOutput(identifiers: ["mdta"])
    metadataOut.setDelegate(nil, queue: nil)
    metadataOut.advanceIntervalForDelegateInvocation = 0.2
    precondition(metadataOut.advanceIntervalForDelegateInvocation == 0.2)
    item.add(metadataOut)

    let collector = AVPlayerItemMetadataCollector(identifiers: ["id"], classifyingLabels: ["lab"])
    collector.setDelegate(nil, queue: queue)
    precondition(collector.delegateQueue === queue)
    item.add(collector)
    precondition(item.mediaDataCollectors.count == 1)
    item.remove(collector)
    precondition(item.mediaDataCollectors.isEmpty)

    let rendered = AVPlayerItemRenderedLegibleOutput(videoDisplaySize: CGSize(width: 320, height: 180))
    rendered.videoDisplaySize = CGSize(width: 640, height: 360)
    rendered.advanceIntervalForDelegateInvocation = 0.05
    rendered.setDelegate(nil, queue: nil)
    precondition(rendered.videoDisplaySize.width == 640)
    precondition(rendered.advanceIntervalForDelegateInvocation == 0.05)

    if let track = item.tracks.first {
        track.isEnabled = false
        precondition(!track.isEnabled)
        precondition(track.currentVideoFrameRate >= 0)
    }
}

func testAVSampleBufferDisplayLayerFailClosed() {
    let layer = AVSampleBufferDisplayLayer()
    precondition(layer.videoGravity == .resizeAspect)
    layer.videoGravity = .resize
    precondition(layer.videoGravity == .resize)
    precondition(!layer.isReadyForDisplay)
    precondition(!layer.isReadyForMoreMediaData)
    precondition(!layer.hasSufficientMediaDataForReliablePlaybackStart)
    precondition(!layer.isOutputObscuredDueToInsufficientExternalProtection)
    precondition(layer.status == .unknown)
    precondition(layer.error == nil)
    layer.preventsCapture = true
    layer.preventsDisplaySleepDuringVideoPlayback = false
    precondition(layer.preventsCapture)
    precondition(!layer.preventsDisplaySleepDuringVideoPlayback)
    let clock = CMTimebase()
    layer.controlTimebase = clock
    precondition(layer.controlTimebase != nil)
    _ = layer.timebase
    _ = layer.sampleBufferRenderer
    layer.enqueue(CMSampleBuffer())
    precondition(layer.status == .failed)
    precondition((layer.error as? AVError)?.code == .decoderNotFound)
    precondition(layer.requiresFlushToResumeDecoding)
    layer.flush()
    precondition(!layer.requiresFlushToResumeDecoding)
    layer.flushAndRemoveImage()
    var requested = false
    layer.requestMediaDataWhenReady(on: DispatchQueue(label: "openav.sbuf")) {
        requested = true
    }
    precondition(!requested)
    layer.stopRequestingMediaData()
    precondition(
        Notification.Name.AVSampleBufferDisplayLayerFailedToDecode.rawValue
            == "AVSampleBufferDisplayLayerFailedToDecode"
    )
    precondition(
        AVSampleBufferDisplayLayerFailedToDecodeNotificationErrorKey
            == "AVSampleBufferDisplayLayerFailedToDecodeNotificationErrorKey"
    )
    precondition(
        Notification.Name.AVSampleBufferDisplayLayerRequiresFlushToResumeDecodingDidChange.rawValue
            == "AVSampleBufferDisplayLayerRequiresFlushToResumeDecodingDidChange"
    )
    precondition(
        Notification.Name.AVSampleBufferDisplayLayerOutputObscuredDueToInsufficientExternalProtectionDidChange.rawValue
            == "AVSampleBufferDisplayLayerOutputObscuredDueToInsufficientExternalProtectionDidChange"
    )
    precondition(
        Notification.Name.AVSampleBufferDisplayLayerReadyForDisplayDidChange.rawValue
            == "AVSampleBufferDisplayLayerReadyForDisplayDidChange"
    )
}

func testAVAssetExportSessionStoredExportConfiguration() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-export-pass6.mp4"))
    let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)!
    session.outputURL = URL(fileURLWithPath: "/tmp/openav-export-out.mp4")
    session.outputFileType = .mp4
    session.shouldOptimizeForNetworkUse = true
    session.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600))
    session.fileLengthLimit = 4096
    let meta = AVMutableMetadataItem()
    meta.identifier = .commonIdentifierTitle
    session.metadata = [meta]
    session.metadataItemFilter = AVMetadataItemFilter.forSharing()
    session.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm(rawValue: "spectral")
    session.audioMix = AVAudioMix()
    session.videoComposition = AVVideoComposition()
    session.audioTrackGroupHandling = AVAssetTrackGroupOutputHandling(rawValue: 1)
    session.canPerformMultiplePassesOverSourceMediaData = true
    let temp = FileManager.default.temporaryDirectory
    session.directoryForTemporaryFiles = temp
    precondition(session.outputURL?.path.hasSuffix("openav-export-out.mp4") == true)
    precondition(session.outputFileType == .mp4)
    precondition(session.shouldOptimizeForNetworkUse)
    precondition(session.timeRange.duration.seconds == 3)
    precondition(session.fileLengthLimit == 4096)
    precondition(session.metadata?.count == 1)
    precondition(session.metadataItemFilter != nil)
    precondition(session.audioTimePitchAlgorithm.rawValue == "spectral")
    precondition(session.audioMix != nil)
    precondition(session.videoComposition != nil)
    precondition(session.customVideoCompositor == nil)
    precondition(session.audioTrackGroupHandling.rawValue == 1)
    precondition(session.canPerformMultiplePassesOverSourceMediaData)
    precondition(session.directoryForTemporaryFiles == temp)
    switch AVAssetExportSession.State.pending {
    case .pending:
        break
    default:
        preconditionFailure("pending")
    }
    switch AVAssetExportSession.State.waiting {
    case .waiting:
        break
    default:
        preconditionFailure("waiting")
    }
    switch AVAssetExportSession.State.exporting(progress: Progress(totalUnitCount: 1)) {
    case .exporting(let progress):
        precondition(progress.totalUnitCount == 1)
    default:
        preconditionFailure("exporting")
    }
}

func testAVAssetVariantQualifierStoresPredicateAndVariant() {
    let variant = AVAssetVariant()
    precondition(variant.url.isFileURL)
    precondition(variant.peakBitRate == nil)
    precondition(variant.averageBitRate == nil)
    precondition(variant.videoAttributes == nil)
    precondition(variant.audioAttributes == nil)
    let audio = AVAssetVariant.AudioAttributes()
    precondition(audio.formatIDs.isEmpty)
    precondition(audio.renditionSpecificAttributes(for: AVMediaSelectionOption()) == nil)
    let rendition = AVAssetVariant.AudioAttributes.RenditionSpecificAttributes()
    precondition(!rendition.isBinaural)
    precondition(!rendition.isDownmix)
    precondition(!rendition.isImmersive)
    precondition(rendition.channelCount == nil)
    let video = AVAssetVariant.VideoAttributes()
    precondition(video.presentationSize == .zero)
    precondition(video.videoLayoutAttributes.isEmpty)
    precondition(video.codecTypes.isEmpty)
    precondition(video.nominalFrameRate == nil)
    let layout = AVAssetVariant.VideoAttributes.LayoutAttributes()
    _ = layout.projectionType
    _ = layout.stereoViewComponents
    let predicate = NSPredicate(value: true)
    let byPredicate = AVAssetVariantQualifier(predicate: predicate)
    precondition(byPredicate.portablePredicate === predicate)
    let byVariant = AVAssetVariantQualifier(variant: variant)
    precondition(byVariant.portableVariant === variant)
}

func testAVCaptureDeviceWhiteBalanceAndRotationCoordinator() {
    precondition(AVCaptureDevice(uniqueID: "missing") == nil)
    let device = AVCaptureDevice()
    let gains = AVCaptureDevice.WhiteBalanceGains(redGain: 1.5, greenGain: 1, blueGain: 2)
    precondition(gains.redGain == 1.5)
    precondition(gains.greenGain == 1)
    precondition(gains.blueGain == 2)
    let chroma = AVCaptureDevice.WhiteBalanceChromaticityValues(x: 0.3, y: 0.4)
    precondition(chroma.x == 0.3)
    precondition(chroma.y == 0.4)
    let temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 6500, tint: 10)
    precondition(temp.temperature == 6500)
    precondition(temp.tint == 10)
    precondition(AVCaptureDevice.WhiteBalanceTemperatureAndTintValues.daylight.temperature == 6500)
    let convertedChroma = device.chromaticityValues(for: gains)
    precondition(convertedChroma.x == 0)
    precondition(convertedChroma.y == 0)
    let fromChroma = device.deviceWhiteBalanceGains(for: chroma)
    precondition(fromChroma.redGain == 0)
    let convertedTemp = device.temperatureAndTintValues(for: gains)
    precondition(convertedTemp.temperature == 0)
    let fromTemp = device.deviceWhiteBalanceGains(for: temp)
    precondition(fromTemp.blueGain == 0)
    precondition(device.deviceWhiteBalanceGains.redGain == 0)
    precondition(device.grayWorldDeviceWhiteBalanceGains.greenGain == 0)
    device.performEffect(for: .heart)
    precondition(
        device.primaryConstituentDeviceSwitchingBehavior == .unsupported
            || device.primaryConstituentDeviceSwitchingBehavior.rawValue == 0
    )
    _ = device.primaryConstituentDeviceRestrictedSwitchingBehaviorConditions
    _ = device.activePrimaryConstituentDeviceSwitchingBehavior
    _ = device.activePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions

    let preview = CALayer()
    let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: preview)
    precondition(coordinator.device === device)
    precondition(coordinator.previewLayer === preview)
    precondition(coordinator.videoRotationAngleForHorizonLevelCapture == 0)
    precondition(coordinator.videoRotationAngleForHorizonLevelPreview == 0)

    precondition(Notification.Name.AVCaptureDeviceWasConnected.rawValue == "AVCaptureDeviceWasConnected")
    precondition(Notification.Name.AVCaptureDeviceWasDisconnected.rawValue == "AVCaptureDeviceWasDisconnected")
    precondition(
        Notification.Name.AVCaptureDeviceSubjectAreaDidChange.rawValue
            == "AVCaptureDeviceSubjectAreaDidChange"
    )
    precondition(AVCaptureDevice.DeviceType(rawValue: "builtInWideAngleCamera") == .builtInWideAngleCamera)
    precondition(AVCaptureDevice.Position.back.rawValue == 1)
    precondition(AVCaptureDevice.Position.front.rawValue == 2)
    precondition(AVCaptureDevice.Position.unspecified.rawValue == 0)
}
