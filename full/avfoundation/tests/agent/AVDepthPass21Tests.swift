import Dispatch
import Foundation
import AVFoundation

// Wave 12: synchronous twins of completion-handler surface plus the remaining
// AVPartialAsyncProperty tokens. Every handler below runs synchronously on the
// caller; no await, semaphore, or DispatchQueue.main is used. Fail-closed
// shapes (empty arrays, nil errors, false/true flags) were pinned by an Xcode
// 26.1 `import AVFoundation` oracle probe on this Mac; see README.

func testWave12PartialAsyncTrackProperties() {
    let associationTypes: AVAsyncProperty<AVAssetTrack, [AVAssetTrack.AssociationType]> = .availableTrackAssociationTypes
    precondition(associationTypes.portableKey == "availableTrackAssociationTypes")
    let isPlayable: AVAsyncProperty<AVAssetTrack, Bool> = .isPlayable
    precondition(isPlayable.portableKey == "isPlayable")
    let isDecodable: AVAsyncProperty<AVAssetTrack, Bool> = .isDecodable
    precondition(isDecodable.portableKey == "isDecodable")
    let naturalSize: AVAsyncProperty<AVAssetTrack, CGSize> = .naturalSize
    precondition(naturalSize.portableKey == "naturalSize")
    let languageCode: AVAsyncProperty<AVAssetTrack, String?> = .languageCode
    precondition(languageCode.portableKey == "languageCode")
    let commonMetadata: AVAsyncProperty<AVAssetTrack, [AVMetadataItem]> = .commonMetadata
    precondition(commonMetadata.portableKey == "commonMetadata")
    let isSelfContained: AVAsyncProperty<AVAssetTrack, Bool> = .isSelfContained
    precondition(isSelfContained.portableKey == "isSelfContained")
    let preferredVolume: AVAsyncProperty<AVAssetTrack, Float> = .preferredVolume
    precondition(preferredVolume.portableKey == "preferredVolume")
    let minFrameDuration: AVAsyncProperty<AVAssetTrack, CMTime> = .minFrameDuration
    precondition(minFrameDuration.portableKey == "minFrameDuration")
    let naturalTimeScale: AVAsyncProperty<AVAssetTrack, CMTimeScale> = .naturalTimeScale
    precondition(naturalTimeScale.portableKey == "naturalTimeScale")
    let nominalFrameRate: AVAsyncProperty<AVAssetTrack, Float> = .nominalFrameRate
    precondition(nominalFrameRate.portableKey == "nominalFrameRate")
    let estimatedDataRate: AVAsyncProperty<AVAssetTrack, Float> = .estimatedDataRate
    precondition(estimatedDataRate.portableKey == "estimatedDataRate")
    let formatDescriptions: AVAsyncProperty<AVAssetTrack, [CMFormatDescription]> = .formatDescriptions
    precondition(formatDescriptions.portableKey == "formatDescriptions")
    let preferredTransform: AVAsyncProperty<AVAssetTrack, CGAffineTransform> = .preferredTransform
    precondition(preferredTransform.portableKey == "preferredTransform")
    let extendedLanguageTag: AVAsyncProperty<AVAssetTrack, String?> = .extendedLanguageTag
    precondition(extendedLanguageTag.portableKey == "extendedLanguageTag")
    let mediaCharacteristics: AVAsyncProperty<AVAssetTrack, [AVMediaCharacteristic]> = .mediaCharacteristics
    precondition(mediaCharacteristics.portableKey == "mediaCharacteristics")
    let totalSampleDataLength: AVAsyncProperty<AVAssetTrack, Int64> = .totalSampleDataLength
    precondition(totalSampleDataLength.portableKey == "totalSampleDataLength")
    let canProvideSampleCursors: AVAsyncProperty<AVAssetTrack, Bool> = .canProvideSampleCursors
    precondition(canProvideSampleCursors.portableKey == "canProvideSampleCursors")
    let requiresFrameReordering: AVAsyncProperty<AVAssetTrack, Bool> = .requiresFrameReordering
    precondition(requiresFrameReordering.portableKey == "requiresFrameReordering")
    let availableMetadataFormats: AVAsyncProperty<AVAssetTrack, [AVMetadataFormat]> = .availableMetadataFormats
    precondition(availableMetadataFormats.portableKey == "availableMetadataFormats")
    let hasAudioSampleDependencies: AVAsyncProperty<AVAssetTrack, Bool> = .hasAudioSampleDependencies
    precondition(hasAudioSampleDependencies.portableKey == "hasAudioSampleDependencies")
    let metadata: AVAsyncProperty<AVAssetTrack, [AVMetadataItem]> = .metadata
    precondition(metadata.portableKey == "metadata")
    let segments: AVAsyncProperty<AVAssetTrack, [AVAssetTrackSegment]> = .segments
    precondition(segments.portableKey == "segments")
    let isEnabled: AVAsyncProperty<AVAssetTrack, Bool> = .isEnabled
    precondition(isEnabled.portableKey == "isEnabled")
    let timeRange: AVAsyncProperty<AVAssetTrack, CMTimeRange> = .timeRange
    precondition(timeRange.portableKey == "timeRange")
}

func testWave12PartialAsyncAssetProperties() {
    let characteristics: AVAsyncProperty<AVAsset, [AVMediaCharacteristic]> = .availableMediaCharacteristicsWithMediaSelectionOptions
    precondition(characteristics.portableKey == "availableMediaCharacteristicsWithMediaSelectionOptions")
    let isReadable: AVAsyncProperty<AVAsset, Bool> = .isReadable
    precondition(isReadable.portableKey == "isReadable")
    let trackGroups: AVAsyncProperty<AVAsset, [AVAssetTrackGroup]> = .trackGroups
    precondition(trackGroups.portableKey == "trackGroups")
    let creationDate: AVAsyncProperty<AVAsset, AVMetadataItem?> = .creationDate
    precondition(creationDate.portableKey == "creationDate")
    let isComposable: AVAsyncProperty<AVAsset, Bool> = .isComposable
    precondition(isComposable.portableKey == "isComposable")
    let isExportable: AVAsyncProperty<AVAsset, Bool> = .isExportable
    precondition(isExportable.portableKey == "isExportable")
    let preferredRate: AVAsyncProperty<AVAsset, Float> = .preferredRate
    precondition(preferredRate.portableKey == "preferredRate")
    let commonMetadata: AVAsyncProperty<AVAsset, [AVMetadataItem]> = .commonMetadata
    precondition(commonMetadata.portableKey == "commonMetadata")
    let preferredVolume: AVAsyncProperty<AVAsset, Float> = .preferredVolume
    precondition(preferredVolume.portableKey == "preferredVolume")
    let containsFragments: AVAsyncProperty<AVAsset, Bool> = .containsFragments
    precondition(containsFragments.portableKey == "containsFragments")
    let allMediaSelections: AVAsyncProperty<AVAsset, [AVMediaSelection]> = .allMediaSelections
    precondition(allMediaSelections.portableKey == "allMediaSelections")
    let preferredTransform: AVAsyncProperty<AVAsset, CGAffineTransform> = .preferredTransform
    precondition(preferredTransform.portableKey == "preferredTransform")
    let canContainFragments: AVAsyncProperty<AVAsset, Bool> = .canContainFragments
    precondition(canContainFragments.portableKey == "canContainFragments")
    let hasProtectedContent: AVAsyncProperty<AVAsset, Bool> = .hasProtectedContent
    precondition(hasProtectedContent.portableKey == "hasProtectedContent")
    let overallDurationHint: AVAsyncProperty<AVAsset, CMTime> = .overallDurationHint
    precondition(overallDurationHint.portableKey == "overallDurationHint")
    let availableChapterLocales: AVAsyncProperty<AVAsset, [Locale]> = .availableChapterLocales
    precondition(availableChapterLocales.portableKey == "availableChapterLocales")
    let preferredMediaSelection: AVAsyncProperty<AVAsset, AVMediaSelection> = .preferredMediaSelection
    precondition(preferredMediaSelection.portableKey == "preferredMediaSelection")
    let availableMetadataFormats: AVAsyncProperty<AVAsset, [AVMetadataFormat]> = .availableMetadataFormats
    precondition(availableMetadataFormats.portableKey == "availableMetadataFormats")
    let minimumTimeOffsetFromLive: AVAsyncProperty<AVAsset, CMTime> = .minimumTimeOffsetFromLive
    precondition(minimumTimeOffsetFromLive.portableKey == "minimumTimeOffsetFromLive")
    let airPlay: AVAsyncProperty<AVAsset, Bool> = .isCompatibleWithAirPlayVideo
    precondition(airPlay.portableKey == "isCompatibleWithAirPlayVideo")
    let photosAlbum: AVAsyncProperty<AVAsset, Bool> = .isCompatibleWithSavedPhotosAlbum
    precondition(photosAlbum.portableKey == "isCompatibleWithSavedPhotosAlbum")
    let preciseTiming: AVAsyncProperty<AVAsset, Bool> = .providesPreciseDurationAndTiming
    precondition(preciseTiming.portableKey == "providesPreciseDurationAndTiming")
    let lyrics: AVAsyncProperty<AVAsset, String?> = .lyrics
    precondition(lyrics.portableKey == "lyrics")
}

func testWave12PartialAsyncMetadataItemProperties() {
    let numberValue: AVAsyncProperty<AVMetadataItem, NSNumber?> = .numberValue
    precondition(numberValue.portableKey == "numberValue")
    let stringValue: AVAsyncProperty<AVMetadataItem, String?> = .stringValue
    precondition(stringValue.portableKey == "stringValue")
    let extraAttributes: AVAsyncProperty<AVMetadataItem, [AVMetadataExtraAttributeKey : Any]?> = .extraAttributes
    precondition(extraAttributes.portableKey == "extraAttributes")
    let value: AVAsyncProperty<AVMetadataItem, (any NSCopying & NSObjectProtocol)?> = .value
    precondition(value.portableKey == "value")
    let dataValue: AVAsyncProperty<AVMetadataItem, Data?> = .dataValue
    precondition(dataValue.portableKey == "dataValue")
    let dateValue: AVAsyncProperty<AVMetadataItem, Date?> = .dateValue
    precondition(dateValue.portableKey == "dateValue")
}

func testWave12PartialAsyncTracksProperties() {
    let composition: AVAsyncProperty<AVComposition, [AVCompositionTrack]> = .tracks
    precondition(composition.portableKey == "tracks")
    let movie: AVAsyncProperty<AVMovie, [AVMovieTrack]> = .tracks
    precondition(movie.portableKey == "tracks")
    let mutableMovie: AVAsyncProperty<AVMutableMovie, [AVMutableMovieTrack]> = .tracks
    precondition(mutableMovie.portableKey == "tracks")
    let fragmentedAsset: AVAsyncProperty<AVFragmentedAsset, [AVFragmentedAssetTrack]> = .tracks
    precondition(fragmentedAsset.portableKey == "tracks")
    let fragmentedMovie: AVAsyncProperty<AVFragmentedMovie, [AVFragmentedMovieTrack]> = .tracks
    precondition(fragmentedMovie.portableKey == "tracks")
    let mutableComposition: AVAsyncProperty<AVMutableComposition, [AVMutableCompositionTrack]> = .tracks
    precondition(mutableComposition.portableKey == "tracks")
}

func testWave12CaptionAttributeGetters() {
    let caption = AVCaption(
        "Hello",
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600))
    )
    let index = caption.text.startIndex
    let fullRange = caption.text.startIndex..<caption.text.endIndex
    let (decoration, decorationRange) = caption.decoration(at: index)
    precondition(decoration.isEmpty && decorationRange == fullRange)
    let (fontWeight, fontWeightRange) = caption.fontWeight(at: index)
    precondition(fontWeight == .unknown && fontWeightRange == fullRange)
    let (textCombine, textCombineRange) = caption.textCombine(at: index)
    precondition(textCombine == .all && textCombineRange == fullRange)
    let (background, backgroundRange) = caption.backgroundColor(at: index)
    precondition(background == nil && backgroundRange == fullRange)
    let (ruby, rubyRange) = caption.ruby(at: index)
    precondition(ruby == nil && rubyRange == fullRange)
    let (fontStyle, fontStyleRange) = caption.fontStyle(at: index)
    precondition(fontStyle == .unknown && fontStyleRange == fullRange)
    let (textColor, textColorRange) = caption.textColor(at: index)
    precondition(textColor == nil && textColorRange == fullRange)
}

func testWave12VariantQualifierPredicates() {
    precondition(!AVAssetVariantQualifier.predicate(forBinauralAudio: true).evaluate(with: nil))
    precondition(!AVAssetVariantQualifier.predicate(forBinauralAudio: false, mediaSelectionOption: nil).evaluate(with: nil))
    precondition(!AVAssetVariantQualifier.predicate(forDownmixAudio: true).evaluate(with: nil))
    precondition(!AVAssetVariantQualifier.predicate(forDownmixAudio: false, mediaSelectionOption: nil).evaluate(with: nil))
    precondition(!AVAssetVariantQualifier.predicate(forImmersiveAudio: true).evaluate(with: nil))
    precondition(!AVAssetVariantQualifier.predicate(forImmersiveAudio: false, mediaSelectionOption: nil).evaluate(with: nil))
}

func testWave12ExposureBracketFactories() {
    let auto = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 1.5)
    precondition(auto.exposureTargetBias == 1.5)
    let duration = CMTime(seconds: 0.5, preferredTimescale: 600)
    let manual = AVCaptureManualExposureBracketedStillImageSettings.manualExposureSettings(exposureDuration: duration, iso: 200)
    precondition(abs(manual.exposureDuration.seconds - 0.5) < 0.001 && manual.iso == 200)
}

func testWave12TrackCompletionHandlerLoads() {
    let track = AVAssetTrack()
    var associatedCount = -1
    track.loadAssociatedTracks(ofType: .audioFallback) { tracks, error in
        associatedCount = tracks?.count ?? -1
        precondition(error == nil)
    }
    precondition(associatedCount == 0)
    var metadataCount = -1
    track.loadMetadata(for: .id3Metadata) { items, error in
        metadataCount = items?.count ?? -1
        precondition(error == nil)
    }
    precondition(metadataCount == 0)
    let expectedPresentation = track.samplePresentationTime(forTrackTime: .zero)
    var presentationSeconds = -1.0
    track.loadSamplePresentationTime(forTrackTime: .zero) { time, error in
        presentationSeconds = time.seconds
        precondition(error == nil)
    }
    precondition(presentationSeconds == expectedPresentation.seconds)
    let expectedSegment = track.segment(forTrackTime: .zero)
    var segmentMissing = false
    track.loadSegment(forTrackTime: .zero) { segment, error in
        segmentMissing = (segment == nil)
        precondition(error == nil)
    }
    precondition(segmentMissing && expectedSegment == nil)
}

func testWave12IntegratedTimelineSeekHandlers() {
    let timeline = AVPlayerItemIntegratedTimeline()
    var dateFinished = true
    timeline.seek(to: Date()) { finished in dateFinished = finished }
    precondition(!dateFinished)
    var timeFinished = true
    timeline.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
        timeFinished = finished
    }
    precondition(!timeFinished)
}

func testWave12SampleBufferRendererHandlers() {
    let audioRenderer = AVSampleBufferAudioRenderer()
    var audioFlushed = false
    audioRenderer.flush(fromSourceTime: .zero) { flushed in audioFlushed = flushed }
    precondition(audioFlushed)
    let videoRenderer = AVSampleBufferVideoRenderer()
    var videoFlushed = false
    videoRenderer.flush(removingDisplayedImage: true) { videoFlushed = true }
    precondition(videoFlushed)
    var metricsMissing = false
    videoRenderer.loadVideoPerformanceMetrics { metrics in metricsMissing = (metrics == nil) }
    precondition(metricsMissing)
    let synchronizer = AVSampleBufferRenderSynchronizer()
    var removed = true
    synchronizer.removeRenderer(Wave12QueueStub(), at: .zero) { didRemove in removed = didRemove }
    precondition(!removed)
}

final class Wave12QueueStub: NSObject, AVQueuedSampleBufferRendering, @unchecked Sendable {
    var timebase: CMTimebase { CMTimebase() }
    func enqueue(_ sampleBuffer: CMSampleBuffer) {}
    func flush() {}
    var isReadyForMoreMediaData: Bool { false }
    func requestMediaDataWhenReady(on queue: DispatchQueue, using block: @escaping () -> Void) {}
    func stopRequestingMediaData() {}
    var hasSufficientMediaDataForReliablePlaybackStart: Bool { false }
}

func testWave12SampleBufferGeneratorHandlers() {
    var notifiedReady = true
    var notifyErrorMissing = true
    AVSampleBufferGenerator.notifyOfDataReady(for: CMSampleBuffer()) { ready, error in
        notifiedReady = ready
        notifyErrorMissing = (error == nil)
    }
    precondition(!notifiedReady && !notifyErrorMissing)
    let generator = AVSampleBufferGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave12-nothing.mp4")), timebase: nil)
    let batch = generator.makeBatch()
    var batchErrorMissing = true
    batch.makeDataReady { error in batchErrorMissing = (error == nil) }
    precondition(!batchErrorMissing)
}

func testWave12PhotoPreparedSettingsHandler() {
    let output = AVCapturePhotoOutput()
    var prepared = true
    var prepareErrorMissing = true
    output.setPreparedPhotoSettingsArray([]) { isPrepared, error in
        prepared = isPrepared
        prepareErrorMissing = (error == nil)
    }
    precondition(!prepared && !prepareErrorMissing)
}

func testWave12ExternalStorageRequestAccess() {
    var granted = true
    AVExternalStorageDevice.requestAccess { isGranted in granted = isGranted }
    precondition(!granted)
}

func testWave12ExportSessionEstimates() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave12-nothing.mp4"))
    var compatible = true
    AVAssetExportSession.determineCompatibility(ofExportPreset: "wave12", with: asset, outputFileType: nil) { isCompatible in
        compatible = isCompatible
    }
    precondition(!compatible)
    let session = AVAssetExportSession(asset: asset, presetName: "wave12")!
    var maximumSeconds = -1.0
    var maximumError: (any Error)? = AVFoundationPortableError.mediaServiceUnavailable
    session.estimateMaximumDuration { duration, error in
        maximumSeconds = duration.seconds
        maximumError = error
    }
    precondition(maximumSeconds == 0 && maximumError == nil)
    var estimatedLength: Int64 = -1
    var lengthError: (any Error)? = AVFoundationPortableError.mediaServiceUnavailable
    session.estimateOutputFileLength { length, error in
        estimatedLength = length
        lengthError = error
    }
    precondition(estimatedLength == 0 && lengthError == nil)
}

func testWave12PlaybackAssistantOptions() {
    let assistant = AVAssetPlaybackAssistant(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave12-nothing.mp4")))
    var optionCount = -1
    assistant.loadPlaybackConfigurationOptions { options in optionCount = options.count }
    precondition(optionCount == 0)
}

func testWave12WriterInputQueueHandlers() {
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let queue = DispatchQueue(label: "wave12-writer")
    var mediaBlockFired = false
    input.requestMediaDataWhenReady(on: queue) { mediaBlockFired = true }
    precondition(!mediaBlockFired && !input.isReadyForMoreMediaData)
    var passBlockFired = false
    input.respondToEachPassDescription(on: queue) { passBlockFired = true }
    precondition(!passBlockFired)
}

func testWave12CaptureControlActions() {
    let queue = DispatchQueue(label: "wave12-controls")
    let slider = AVCaptureSlider("wave12", symbolName: "wave12", in: 0...1)
    var sliderFired = false
    slider.setActionQueue(queue) { _ in sliderFired = true }
    precondition(!sliderFired)
    let picker = AVCaptureIndexPicker("wave12", symbolName: "wave12", numberOfIndexes: 3)
    var pickerFired = false
    picker.setActionQueue(queue) { _ in pickerFired = true }
    precondition(!pickerFired)
}

func testWave12CaptionValidationHandler() {
    let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600))
    let validator = AVCaptionConversionValidator(captions: [], timeRange: timeRange, conversionSettings: [:])
    var calls = 0
    var terminalNil = false
    validator.validateCaptionConversion { warning in
        calls += 1
        terminalNil = (warning == nil)
    }
    precondition(calls == 1 && terminalNil)
    precondition(validator.status == .completed && validator.warnings.isEmpty)
    let warning = AVCaptionConversionWarning()
    precondition(warning.rangeOfCaptions.location == 0 && warning.rangeOfCaptions.length == 0)
}

func testWave12CompositionCompletionHandlers() {
    let composition = AVMutableComposition()
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave12-nothing.mp4"))
    let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600))
    var insertError: (any Error)? = AVFoundationPortableError.mediaServiceUnavailable
    composition.insertTimeRange(timeRange, of: asset, at: .zero) { error in insertError = error }
    precondition(insertError == nil && composition.tracks.isEmpty)
    var compositionMissing = false
    var factoryErrorMissing = true
    AVMutableVideoComposition.videoComposition(
        withPropertiesOf: composition,
        prototypeInstruction: AVMutableVideoCompositionInstruction()
    ) { videoComposition, error in
        compositionMissing = (videoComposition == nil)
        factoryErrorMissing = (error == nil)
    }
    precondition(compositionMissing && !factoryErrorMissing)
}

func testWave12ImageGeneratorImages() {
    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave12-nothing.mp4")))
    let sequence: AVAssetImageGenerator.Images = generator.images(for: [.zero])
    _ = sequence.makeAsyncIterator()
}

func testWave12MediaValueDefaults() {
    precondition(AVCapturePhotoSettings().rawPhotoPixelFormatType == 0)
    precondition(AVCapturePhotoSettings(rawPixelFormatType: 42).rawPhotoPixelFormatType == 42)
    let frameRange = AVFrameRateRange()
    precondition(frameRange.maxFrameRate == 0 && frameRange.minFrameRate == 0)
    precondition(AVDepthData().depthDataType == 0)
    precondition(AVPortraitEffectsMatte().pixelFormatType == 0)
    precondition(AVSemanticSegmentationMatte().pixelFormatType == 0)
    let segmentBytes = AVMetricHLSMediaSegmentRequestEvent().byteRange
    precondition(segmentBytes.location == 0 && segmentBytes.length == 0)
    let resourceBytes = AVMetricMediaResourceRequestEvent().byteRange
    precondition(resourceBytes.location == 0 && resourceBytes.length == 0)
}

func testWave12SampleCursorCompare() {
    let cursor = AVSampleCursor()
    precondition(cursor.comparePositionInDecodeOrder(withPositionOf: AVSampleCursor()) == .orderedSame)
}

func testWave12ReaderOutputProviders() {
    let reader = AVAssetReader()
    let output = AVAssetReaderOutput()
    let trackOutput = AVAssetReaderTrackOutput()
    let provider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>> = reader.outputProvider(for: output)
    _ = provider
    let captionProvider: AVAssetReaderOutput.Provider<AVCaptionGroup> = reader.outputCaptionProvider(
        for: trackOutput,
        validationDelegate: nil
    )
    precondition(captionProvider.captionsNotPresentInPreviousGroups(in: AVCaptionGroup()).isEmpty)
    let metadataProvider: AVAssetReaderOutput.Provider<AVTimedMetadataGroup> = reader.outputMetadataProvider(for: trackOutput)
    _ = metadataProvider
    let (randomProvider, randomController) = reader.outputProviderWithRandomAccess(for: output)
    _ = randomProvider
    randomController.resetForReading(timeRanges: [])
    let (randomCaptionProvider, _) = reader.outputCaptionProviderWithRandomAccess(for: trackOutput, validationDelegate: nil)
    _ = randomCaptionProvider
    let (randomMetadataProvider, _) = reader.outputMetadataProviderWithRandomAccess(for: trackOutput)
    _ = randomMetadataProvider
}

func testWave12WriterInputReceivers() {
    let writer = AVAssetWriter()
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let sampleReceiver: AVAssetWriterInput.SampleBufferReceiver = writer.inputReceiver(for: input)
    sampleReceiver.finish()
    let captionReceiver: AVAssetWriterInput.CaptionReceiver = writer.inputCaptionReceiver(for: input)
    captionReceiver.finish()
    let metadataReceiver: AVAssetWriterInput.MetadataReceiver = writer.inputMetadataReceiver(for: input)
    metadataReceiver.finish()
    let pixelReceiver: AVAssetWriterInput.PixelBufferReceiver = writer.inputPixelBufferReceiver(for: input, pixelBufferAttributes: nil)
    pixelReceiver.finish()
    let taggedReceiver: AVAssetWriterInput.TaggedPixelBufferGroupReceiver = writer.inputTaggedPixelBufferGroupReceiver(for: input, pixelBufferAttributes: nil)
    taggedReceiver.finish()
    let (multiSample, multiSampleController) = writer.inputReceiverRequestingMultiPass(for: input)
    _ = multiSampleController
    multiSample.finish()
    let (multiCaption, _) = writer.inputCaptionReceiverRequestingMultiPass(for: input)
    multiCaption.finish()
    let (multiMetadata, _) = writer.inputMetadataReceiverRequestingMultiPass(for: input)
    multiMetadata.finish()
    let (multiPixel, _) = writer.inputPixelBufferReceiverRequestingMultiPass(for: input, pixelBufferAttributes: nil)
    multiPixel.finish()
    let (multiTagged, _) = writer.inputTaggedPixelBufferGroupReceiverRequestingMultiPass(for: input, pixelBufferAttributes: nil)
    multiTagged.finish()
}
