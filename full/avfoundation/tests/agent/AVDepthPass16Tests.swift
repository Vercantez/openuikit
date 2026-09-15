import Foundation
import AVFoundation

// Depth pass 16 (wave 6): leftover declared delegate protocols (recording
// witnesses), player timeline / video-output / sample-rendering models, and
// Swift value-type witnesses that already compile. Every test is top-level,
// synchronous, and takes no arguments. No hardware, daemon, FairPlay,
// codec, or Apple service success is claimed.

// MARK: - Recording doubles

final class Depth16AudioDelegate: AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    var calls = 0
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        calls += 1
    }
}

final class Depth16SynchronizerDelegate: AVCaptureDataOutputSynchronizerDelegate, @unchecked Sendable {
    var calls = 0
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        calls += 1
    }
}

final class Depth16DepthDelegate: AVCaptureDepthDataOutputDelegate, @unchecked Sendable {
    var calls = 0
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        calls += 1
    }
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
        calls += 1
    }
}

final class Depth16FileDelegate: AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {
    var calls = 0
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) { calls += 1 }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, startPTS: CMTime, from connections: [AVCaptureConnection]) { calls += 1 }
    func fileOutput(_ output: AVCaptureFileOutput, didPauseRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) { calls += 1 }
    func fileOutput(_ output: AVCaptureFileOutput, didResumeRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) { calls += 1 }
}

final class Depth16MetadataDelegate: AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    var calls = 0
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        calls += 1
    }
}

final class Depth16PhotoDelegate: AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    var calls = 0
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: (any Error)?) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) { calls += 1 }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) { calls += 1 }
}

final class Depth16TimecodeDelegate: AVCaptureTimecodeGeneratorDelegate, @unchecked Sendable {
    var calls = 0
    func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, didReceiveUpdate timecode: AVCaptureTimecode, from source: AVCaptureTimecode.Source) { calls += 1 }
    func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, transitionedTo synchronizationStatus: AVCaptureTimecodeGenerator.SynchronizationStatus, for source: AVCaptureTimecode.Source) { calls += 1 }
    func timecodeGenerator(_ generator: AVCaptureTimecodeGenerator, didUpdateAvailableSources availableSources: [AVCaptureTimecode.Source]) { calls += 1 }
}

final class Depth16ContentKeyDelegate: AVContentKeySessionDelegate, @unchecked Sendable {
    var calls = 0
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, didUpdatePersistableContentKey persistableContentKey: Data, forContentKeyIdentifier keyIdentifier: Any) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest, reason retryReason: AVContentKeyRequest.RetryReason) -> Bool { calls += 1; return false }
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest) { calls += 1 }
    func contentKeySessionContentProtectionSessionIdentifierDidChange(_ session: AVContentKeySession) { calls += 1 }
    func contentKeySessionDidGenerateExpiredSessionReport(_ session: AVContentKeySession) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, externalProtectionStatusDidChangeFor contentKey: AVContentKey) { calls += 1 }
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequests: [AVContentKeyRequest], forInitializationData initializationData: Data?) { calls += 1 }
}

final class Depth16CoordinatorDelegate: AVPlayerPlaybackCoordinatorDelegate, @unchecked Sendable {
    func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, identifierFor playerItem: AVPlayerItem) -> String { "id" }
    func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, interstitialTimeRangesFor playerItem: AVPlayerItem) -> [NSValue] { [] }
}

final class Depth16Compositor: AVVideoCompositing, @unchecked Sendable {
    var sourcePixelBufferAttributes: [String: any Sendable]? { nil }
    var requiredPixelBufferAttributesForRenderContext: [String: any Sendable] { [:] }
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {}
    func cancelAllPendingVideoCompositionRequests() {}
    var supportsWideColorSourceFrames: Bool { false }
    var supportsHDRSourceFrames: Bool { false }
    var supportsSourceTaggedBuffers: Bool { false }
    var canConformColorOfSourceFrames: Bool { false }
    func anticipateRendering(using renderHint: AVVideoCompositionRenderHint) {}
    func prerollForRendering(using renderHint: AVVideoCompositionRenderHint) {}
}

final class Depth16ValidationHandler: AVVideoCompositionValidationHandling, @unchecked Sendable {
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidValueForKey key: String) -> Bool { true }
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingEmptyTimeRange timeRange: CMTimeRange) -> Bool { true }
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTimeRangeIn videoCompositionInstruction: any AVVideoCompositionInstructionProtocol) -> Bool { true }
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTrackIDIn videoCompositionInstruction: any AVVideoCompositionInstructionProtocol, layerInstruction: AVVideoCompositionLayerInstruction, asset: AVAsset) -> Bool { true }
}

final class Depth16LegibleDelegate: AVPlayerItemLegibleOutputPushDelegate, @unchecked Sendable {
    var calls = 0
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) { calls += 1 }
    func legibleOutput(_ output: AVPlayerItemLegibleOutput, didOutputAttributedStrings strings: [NSAttributedString], nativeSampleBuffers nativeSamples: [Any], forItemTime itemTime: CMTime) { calls += 1 }
}

final class Depth16CollectorDelegate: AVPlayerItemMetadataCollectorPushDelegate, @unchecked Sendable {
    var calls = 0
    func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector, didCollect metadataGroups: sending [AVDateRangeMetadataGroup], indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet) { calls += 1 }
}

final class Depth16MetadataOutputDelegate: AVPlayerItemMetadataOutputPushDelegate, @unchecked Sendable {
    var calls = 0
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) { calls += 1 }
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: sending [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) { calls += 1 }
}

final class Depth16PullDelegate: AVPlayerItemOutputPullDelegate, @unchecked Sendable {
    var calls = 0
    func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) { calls += 1 }
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) { calls += 1 }
}

final class Depth16PushDelegate: AVPlayerItemOutputPushDelegate, @unchecked Sendable {
    var calls = 0
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) { calls += 1 }
}

final class Depth16RenderedLegibleDelegate: AVPlayerItemRenderedLegibleOutputPushDelegate, @unchecked Sendable {
    var calls = 0
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) { calls += 1 }
    func renderedLegibleOutput(_ output: AVPlayerItemRenderedLegibleOutput, didOutputRenderedCaptionImages captionImages: [AVRenderedCaptionImage], forItemTime itemTime: CMTime) { calls += 1 }
}

final class Depth16TimelineObserver: AVPlayerItemIntegratedTimelineObserver {}

// MARK: - Tests

func testDepth16CaptureDelegates() {
    let audio = Depth16AudioDelegate()
    audio.captureOutput(AVCaptureOutput(), didOutput: CMSampleBuffer(), from: AVCaptureConnection())
    precondition(audio.calls == 1)
    let sync = Depth16SynchronizerDelegate()
    sync.dataOutputSynchronizer(AVCaptureDataOutputSynchronizer(), didOutput: AVCaptureSynchronizedDataCollection())
    precondition(sync.calls == 1)
    let depth = Depth16DepthDelegate()
    depth.depthDataOutput(AVCaptureDepthDataOutput(), didOutput: AVDepthData(), timestamp: .zero, connection: AVCaptureConnection())
    depth.depthDataOutput(AVCaptureDepthDataOutput(), didDrop: AVDepthData(), timestamp: .zero, connection: AVCaptureConnection(), reason: .none)
    precondition(depth.calls == 2)
    let file = Depth16FileDelegate()
    let url = URL(fileURLWithPath: "/dev/null")
    file.fileOutput(AVCaptureFileOutput(), didStartRecordingTo: url, from: [])
    file.fileOutput(AVCaptureFileOutput(), didStartRecordingTo: url, startPTS: .zero, from: [])
    file.fileOutput(AVCaptureFileOutput(), didPauseRecordingTo: url, from: [])
    file.fileOutput(AVCaptureFileOutput(), didResumeRecordingTo: url, from: [])
    precondition(file.calls == 4)
    let meta = Depth16MetadataDelegate()
    meta.metadataOutput(AVCaptureMetadataOutput(), didOutput: [], from: AVCaptureConnection())
    precondition(meta.calls == 1)
    let photo = Depth16PhotoDelegate()
    let photoOutput = AVCapturePhotoOutput()
    let resolved = AVCaptureResolvedPhotoSettings()
    photo.photoOutput(photoOutput, willBeginCaptureFor: resolved)
    photo.photoOutput(photoOutput, willCapturePhotoFor: resolved)
    photo.photoOutput(photoOutput, didCapturePhotoFor: resolved)
    photo.photoOutput(photoOutput, didFinishProcessingPhoto: AVCapturePhoto(), error: nil)
    photo.photoOutput(photoOutput, didFinishCapturingDeferredPhotoProxy: nil, error: nil)
    photo.photoOutput(photoOutput, didFinishProcessingPhoto: nil, previewPhoto: nil, resolvedSettings: resolved, bracketSettings: nil, error: nil)
    photo.photoOutput(photoOutput, didFinishProcessingRawPhoto: nil, previewPhoto: nil, resolvedSettings: resolved, bracketSettings: nil, error: nil)
    photo.photoOutput(photoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt: url, resolvedSettings: resolved)
    photo.photoOutput(photoOutput, didFinishProcessingLivePhotoToMovieFileAt: url, duration: .zero, photoDisplayTime: .zero, resolvedSettings: resolved, error: nil)
    photo.photoOutput(photoOutput, didFinishCaptureFor: resolved, error: nil)
    precondition(photo.calls == 10)
    let timecode = Depth16TimecodeDelegate()
    let generator = AVCaptureTimecodeGenerator()
    timecode.timecodeGenerator(generator, didReceiveUpdate: AVCaptureTimecode(), from: AVCaptureTimecode.Source())
    timecode.timecodeGenerator(generator, transitionedTo: .synchronized, for: AVCaptureTimecode.Source())
    timecode.timecodeGenerator(generator, didUpdateAvailableSources: [])
    precondition(timecode.calls == 3)
}

func testDepth16ContentKey() {
    _ = AVContentKeyResponse(authorizationTokenData: Data([1, 2, 3]))
    _ = AVContentKeyResponse(clearKeyData: Data([4]), initializationVector: Data([5]))
    let asset = AVAsset()
    asset.contentKeySession(AVContentKeySession(), didProvide: AVContentKey())
    precondition(asset.mayRequireContentKeysForMediaDataProcessing == false)
    let delegate = Depth16ContentKeyDelegate()
    let session = AVContentKeySession()
    delegate.contentKeySession(session, didProvide: AVContentKeyRequest())
    delegate.contentKeySession(session, didProvideRenewingContentKeyRequest: AVContentKeyRequest())
    delegate.contentKeySession(session, didProvide: AVPersistableContentKeyRequest())
    delegate.contentKeySession(session, didUpdatePersistableContentKey: Data(), forContentKeyIdentifier: "id")
    delegate.contentKeySession(session, contentKeyRequest: AVContentKeyRequest(), didFailWithError: AVError(.contentKeyRequestCancelled))
    precondition(delegate.contentKeySession(session, shouldRetry: AVContentKeyRequest(), reason: .timedOut) == false)
    delegate.contentKeySession(session, contentKeyRequestDidSucceed: AVContentKeyRequest())
    delegate.contentKeySessionContentProtectionSessionIdentifierDidChange(session)
    delegate.contentKeySessionDidGenerateExpiredSessionReport(session)
    delegate.contentKeySession(session, externalProtectionStatusDidChangeFor: AVContentKey())
    delegate.contentKeySession(session, didProvide: [AVContentKeyRequest()], forInitializationData: nil)
    precondition(delegate.calls == 11)
}

func testDepth16PlayerTimeline() {
    let timeline = AVPlayerItemIntegratedTimeline()
    _ = timeline.currentDate
    _ = timeline.currentSnapshot
    precondition(timeline.currentTime == .zero)
    let snapshot = AVPlayerItemIntegratedTimelineSnapshot()
    _ = snapshot.currentDate
    _ = snapshot.currentSegment
    precondition(snapshot.currentTime == .zero)
    precondition(snapshot.duration == .zero)
    precondition(snapshot.segments.isEmpty)
    let (segment, offset) = snapshot.segmentAndOffsetIntoSegment(forTimelineTime: .zero)
    _ = segment
    precondition(offset == .zero)
    _ = AVPlayerItemIntegratedTimeline.BoundaryTimes()
    _ = AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator()
    _ = AVPlayerItemIntegratedTimeline.BoundaryTimes.Element.self
    _ = AVPlayerItemIntegratedTimeline.BoundaryTimes.AsyncIterator.self
    _ = AVPlayerItemIntegratedTimeline.PeriodicTimes()
    _ = AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator()
    _ = AVPlayerItemIntegratedTimeline.PeriodicTimes.Element.self
    _ = AVPlayerItemIntegratedTimeline.PeriodicTimes.AsyncIterator.self
    _ = timeline.boundaryTimes(for: AVPlayerItemSegment(), offsetsIntoSegment: [])
    _ = timeline.periodicTimes(forInterval: CMTime(value: 1, timescale: 1))
    _ = Depth16TimelineObserver()
}

func testDepth16PlayerLayerAndCoordinator() {
    let layer = AVPlayerLayer(player: nil)
    layer.pixelBufferAttributes = ["k": 1]
    _ = layer.pixelBufferAttributes
    _ = layer.videoRect
    let coordinator = AVPlayerPlaybackCoordinator()
    _ = coordinator.player
    let delegate = Depth16CoordinatorDelegate()
    coordinator.delegate = delegate
    _ = coordinator.delegate
    _ = coordinator.playbackCoordinationMedium
    do {
        try coordinator.coordinate(using: nil)
        preconditionFailure("coordinate must fail closed without a medium")
    } catch {
        _ = error
    }
    precondition(delegate.playbackCoordinator(coordinator, identifierFor: AVPlayerItem()) == "id")
    precondition(delegate.playbackCoordinator(coordinator, interstitialTimeRangesFor: AVPlayerItem()).isEmpty)
}

func testDepth16PlayerVideoOutput() {
    let output = AVPlayerVideoOutput()
    _ = AVPlayerVideoOutput(specification: AVVideoOutputSpecification())
    let configuration = AVPlayerVideoOutput.Configuration()
    precondition(configuration.dataChannelDescription.isEmpty)
    _ = configuration.sourcePlayerItem
    _ = configuration.preferredTransform
    precondition(configuration.activationTime == .zero)
    _ = AVPlayerVideoOutput.Sample()
    let sample = AVPlayerVideoOutput.Sample()
    precondition(sample.taggedBuffers.isEmpty)
    precondition(sample.presentationTime == .zero)
    _ = sample.activeConfiguration
    precondition(output.sample(forHostTime: .zero) == nil)
    let itemOutput = AVPlayerItemVideoOutput()
    let (buffer, displayTime) = itemOutput.pixelBufferAndDisplayTime(forItemTime: .zero)
    precondition(buffer == nil)
    precondition(displayTime == .invalid)
    let renderer = AVSampleBufferVideoRenderer()
    _ = renderer.recommendedPixelBufferAttributes
    renderer.presentationTimeExpectation = .monotonicallyIncreasing
    _ = renderer.presentationTimeExpectation
    _ = AVSampleBufferVideoRenderer.PresentationTimeExpectation.none
    _ = AVSampleBufferVideoRenderer.PresentationTimeExpectation.minimumUpcoming(.zero)
}

func testDepth16QueuedAndCompositing() {
    let layer = AVSampleBufferDisplayLayer()
    let rendering: any AVQueuedSampleBufferRendering = layer
    rendering.enqueue(CMSampleBuffer())
    rendering.flush()
    rendering.requestMediaDataWhenReady(on: DispatchQueue(label: "depth16")) {}
    rendering.stopRequestingMediaData()
    _ = rendering.hasSufficientMediaDataForReliablePlaybackStart
    _ = rendering.isReadyForMoreMediaData
    _ = rendering.timebase
    _ = AVQueuedSampleBufferRendering.self
    let compositor = Depth16Compositor()
    let compositing: any AVVideoCompositing = compositor
    _ = compositing.sourcePixelBufferAttributes
    _ = compositing.requiredPixelBufferAttributesForRenderContext
    compositing.renderContextChanged(AVVideoCompositionRenderContext())
    compositing.startRequest(AVAsynchronousVideoCompositionRequest())
    compositing.cancelAllPendingVideoCompositionRequests()
    precondition(compositing.supportsWideColorSourceFrames == false)
    precondition(compositing.supportsHDRSourceFrames == false)
    precondition(compositing.supportsSourceTaggedBuffers == false)
    precondition(compositing.canConformColorOfSourceFrames == false)
    compositing.anticipateRendering(using: AVVideoCompositionRenderHint())
    compositing.prerollForRendering(using: AVVideoCompositionRenderHint())
    _ = AVVideoCompositing.self
    let validator = Depth16ValidationHandler()
    let composition = AVVideoComposition()
    precondition(validator.videoComposition(composition, shouldContinueValidatingAfterFindingInvalidValueForKey: "k"))
    precondition(validator.videoComposition(composition, shouldContinueValidatingAfterFindingEmptyTimeRange: .zero))
    precondition(validator.videoComposition(composition, shouldContinueValidatingAfterFindingInvalidTimeRangeIn: AVVideoCompositionInstruction()))
    precondition(validator.videoComposition(composition, shouldContinueValidatingAfterFindingInvalidTrackIDIn: AVVideoCompositionInstruction(), layerInstruction: AVVideoCompositionLayerInstruction(), asset: AVAsset()))
    _ = AVVideoCompositionValidationHandling.self
    let instruction = AVVideoCompositionInstruction()
    _ = instruction.timeRange
    precondition(instruction.enablePostProcessing == false)
    precondition(instruction.containsTweening == false)
    _ = instruction.requiredSourceTrackIDs
    precondition(instruction.passthroughTrackID == 0)
    _ = instruction.requiredSourceSampleDataTrackIDs
    _ = AVVideoCompositionInstruction.self
}

func testDepth16AsyncValueModels() {
    _ = AVMetrics<AVMetricEvent>()
    _ = AVMetrics<AVMetricEvent>.Element.self
    _ = AVMetrics<AVMetricEvent>.AsyncIterator.self
    let item = AVPlayerItem()
    _ = item.allMetrics()
    _ = item.metrics(forType: AVMetricPlayerItemStallEvent.self)
    _ = AVMetricEventStreamPublisher.self
    let params = AVCIImageFilteringParameters()
    _ = params.sourceImage
    precondition(params.compositionTime == .zero)
    _ = params.renderSize
    _ = AVCIImageFilteringResult()
    let result = AVCIImageFilteringResult(resultImage: CIImage(), ciContext: CIContext())
    _ = result.resultImage
    _ = result.ciContext
    _ = AVSpatialVideoConfiguration()
    _ = AVSpatialVideoConfiguration.nonSpatial
    _ = AVSpatialVideoConfiguration(formatDescription: CMFormatDescription())
    var spatial = AVSpatialVideoConfiguration()
    spatial.disparityAdjustment = 1
    spatial.cameraSystemBaseline = 2
    spatial.horizontalFieldOfView = 3
    precondition(spatial.disparityAdjustment == 1)
    precondition(spatial.cameraSystemBaseline == 2)
    precondition(spatial.horizontalFieldOfView == 3)
    _ = spatial.cameraCalibrationDataLensCollection
    let images = AVAssetImageGenerator.Images()
    _ = images.makeAsyncIterator()
    _ = AVAssetImageGenerator.Images.Element.self
    let success = AVAssetImageGenerator.Images.Element.success(requestedTime: .zero, image: CGImage(), actualTime: .zero)
    let failure = AVAssetImageGenerator.Images.Element.failure(requestedTime: .zero, error: AVError(.noImageAtTime))
    switch (success, failure) {
    case (.success(let requested, let image, let actual), .failure(let requested2, _)):
        precondition(requested == .zero)
        _ = image
        precondition(actual == .zero)
        precondition(requested2 == .zero)
    default:
        preconditionFailure("unreachable element combination")
    }
}

func testDepth16CompositionConfigs() {
    var configuration = AVVideoComposition.Configuration()
    configuration.instructions = [AVVideoCompositionInstruction()]
    precondition(configuration.instructions.count == 1)
    let full = AVVideoComposition.Configuration(animationTool: nil, colorPrimaries: nil, colorTransferFunction: nil, colorYCbCrMatrix: nil, customVideoCompositorClass: nil, frameDuration: .zero, instructions: [], outputBufferDescription: nil, perFrameHDRDisplayMetadataPolicy: .propagate, renderScale: 1.0, renderSize: .zero, sourceSampleDataTrackIDs: [], sourceTrackIDForFrameTiming: 0, spatialVideoConfigurations: [])
    _ = AVVideoComposition(configuration: full)
    _ = configuration
    var instruction = AVVideoCompositionInstruction.Configuration()
    instruction.enablePostProcessing = true
    instruction.timeRange = CMTimeRange(start: .zero, duration: CMTime(value: 1, timescale: 600))
    instruction.layerInstructions = [AVVideoCompositionLayerInstruction()]
    instruction.requiredSourceSampleDataTrackIDs = [1]
    precondition(instruction.enablePostProcessing)
    precondition(instruction.layerInstructions.count == 1)
    precondition(instruction.requiredSourceSampleDataTrackIDs == [1])
    _ = instruction.backgroundColor
    let built = AVVideoCompositionInstruction.Configuration(backgroundColor: nil, enablePostProcessing: false, layerInstructions: [], requiredSourceSampleDataTrackIDs: [], timeRange: .zero)
    _ = AVVideoCompositionInstruction(configuration: built)
    _ = AVVideoCompositionCoreAnimationTool.Configuration()
    _ = AVVideoCompositionCoreAnimationTool(configuration: AVVideoCompositionCoreAnimationTool.Configuration())
    _ = AVVideoCompositionCoreAnimationTool()
    let context = AVVideoCompositionRenderContext()
    do {
        _ = try context.makeMutablePixelBuffer()
    } catch {
        _ = error
    }
}

func testDepth16CompositionRequest() {
    let request = AVAsynchronousVideoCompositionRequest()
    precondition(request.sourceSampleDataTrackIDs.isEmpty)
    precondition(request.sourceTaggedDynamicBuffers(byTrackID: 1) == nil)
    precondition(request.sourceReadOnlyPixelBuffer(byTrackID: 1) == nil)
    precondition(request.sourceReadySampleBuffer(byTrackID: 1) == nil)
    request.finish(withComposedPixelBuffer: CVReadOnlyPixelBuffer())
    request.finish(withComposedTaggedBuffers: [])
    var mutable = CVMutablePixelBuffer()
    do {
        try request.attach(AVSpatialVideoConfiguration(), to: &mutable)
        preconditionFailure("attach must fail closed without a media service")
    } catch {
        _ = error
    }
}

func testDepth16RawValueInits() {
    precondition(AVCapturePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions(rawValue: 1).rawValue == 1)
    precondition(AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason(rawValue: "segmentsChanged").rawValue == "segmentsChanged")
    precondition(AVContentKeySessionServerPlaybackContextOption(rawValue: "serverChallenge").rawValue == "serverChallenge")
    precondition(AVCaptureSystemPressureFactors(rawValue: 0).rawValue == 0)
    precondition(AVCaptureSceneMonitoringStatus(rawValue: "notEnoughLight").rawValue == "notEnoughLight")
    precondition(AVCaptureSystemPressureLevel(rawValue: "nominal") == .nominal)
    precondition(AVPlayerRateDidChangeReason(rawValue: "setRateCalled").rawValue == "setRateCalled")
    precondition(AVCaptureReactionType(rawValue: "lasers").rawValue == "lasers")
    precondition(AVPlayerWaitingReason(rawValue: "noItemToPlay") == .noItemToPlay)
    precondition(AVCaptureDevice.AspectRatio(rawValue: "ratio16x9").rawValue == "ratio16x9")
    precondition(AVPlayerHDRMode(rawValue: 1) == .hlg)
}

func testDepth16PlayerItemDelegates() {
    let legible = Depth16LegibleDelegate()
    legible.legibleOutput(AVPlayerItemLegibleOutput(), didOutputAttributedStrings: [], nativeSampleBuffers: [], forItemTime: .zero)
    legible.outputSequenceWasFlushed(AVPlayerItemOutput())
    precondition(legible.calls == 2)
    let collector = Depth16CollectorDelegate()
    collector.metadataCollector(AVPlayerItemMetadataCollector(), didCollect: [], indexesOfNewGroups: IndexSet(), indexesOfModifiedGroups: IndexSet())
    precondition(collector.calls == 1)
    let metadata = Depth16MetadataOutputDelegate()
    metadata.metadataOutput(AVPlayerItemMetadataOutput(), didOutputTimedMetadataGroups: [], from: nil)
    metadata.outputSequenceWasFlushed(AVPlayerItemOutput())
    precondition(metadata.calls == 2)
    let pull = Depth16PullDelegate()
    pull.outputMediaDataWillChange(AVPlayerItemOutput())
    pull.outputSequenceWasFlushed(AVPlayerItemOutput())
    precondition(pull.calls == 2)
    let push = Depth16PushDelegate()
    push.outputSequenceWasFlushed(AVPlayerItemOutput())
    precondition(push.calls == 1)
    let rendered = Depth16RenderedLegibleDelegate()
    rendered.renderedLegibleOutput(AVPlayerItemRenderedLegibleOutput(), didOutputRenderedCaptionImages: [], forItemTime: .zero)
    rendered.outputSequenceWasFlushed(AVPlayerItemOutput())
    precondition(rendered.calls == 2)
}
