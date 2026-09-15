import Dispatch
import Foundation

// Wave 12: synchronous twins of completion-handler / fail-closed surface whose
// Swift spellings are pinned by the iPhoneOS 26.1 graph and, where behavior
// was in doubt, by an Xcode 26.1 `import AVFoundation` oracle probe on this
// Mac (see README). Every completion handler below is invoked synchronously
// on the caller's thread: the sealed gate forbids `await`, and Linux has no
// media service, capture hardware, decoder, encoder, or FairPlay daemon, so
// service-backed results stay fail-closed. No Apple success is fabricated.

// MARK: - AVAssetTrack completion-handler loads (stored-state projections)

extension AVAssetTrack {
  public func loadAssociatedTracks(
    ofType trackAssociationType: AVAssetTrack.AssociationType,
    completionHandler: @escaping ([AVAssetTrack]?, (any Error)?) -> Void
  ) {
    completionHandler(associatedTracks(ofType: trackAssociationType), nil)
  }
  public func loadMetadata(
    for format: AVMetadataFormat,
    completionHandler: @escaping ([AVMetadataItem]?, (any Error)?) -> Void
  ) {
    completionHandler(metadata(forFormat: format), nil)
  }
  public func loadSamplePresentationTime(
    forTrackTime trackTime: CMTime,
    completionHandler: @escaping (CMTime, (any Error)?) -> Void
  ) {
    completionHandler(samplePresentationTime(forTrackTime: trackTime), nil)
  }
  public func loadSegment(
    forTrackTime trackTime: CMTime,
    completionHandler: @escaping (AVAssetTrackSegment?, (any Error)?) -> Void
  ) {
    completionHandler(segment(forTrackTime: trackTime), nil)
  }
}

// MARK: - AVPlayerItemIntegratedTimeline seeks (fail-closed false)

extension AVPlayerItemIntegratedTimeline {
  public func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
    _ = date
    completionHandler(false)
  }
  public func seek(
    to time: CMTime,
    toleranceBefore: CMTime,
    toleranceAfter: CMTime,
    completionHandler: @escaping (Bool) -> Void
  ) {
    _ = (time, toleranceBefore, toleranceAfter)
    completionHandler(false)
  }
}

// MARK: - Sample-buffer renderer / synchronizer / generator handlers

extension AVSampleBufferAudioRenderer {
  // Oracle (macOS 26.1, fresh renderer): flush reports true (empty queue
  // trivially flushed). Mirrors Apple, not the async twin's false.
  public func flush(fromSourceTime time: CMTime, completionHandler: @escaping (Bool) -> Void) {
    _ = time
    completionHandler(true)
  }
}

extension AVSampleBufferVideoRenderer {
  public func flush(removingDisplayedImage removeDisplayedImage: Bool, completionHandler: @escaping () -> Void) {
    _ = removeDisplayedImage
    completionHandler()
  }
  // Oracle: fresh renderer vends nil metrics with no error.
  public func loadVideoPerformanceMetrics(completionHandler: @escaping (AVVideoPerformanceMetrics?) -> Void) {
    completionHandler(nil)
  }
}

extension AVSampleBufferRenderSynchronizer {
  public func removeRenderer(
    _ renderer: any AVQueuedSampleBufferRendering,
    at time: CMTime,
    completionHandler: @escaping (Bool) -> Void
  ) {
    _ = (renderer, time)
    completionHandler(false)
  }
}

extension AVSampleBufferGenerator {
  public class func notifyOfDataReady(
    for sbuf: CMSampleBuffer,
    completionHandler: @escaping (Bool, (any Error)?) -> Void
  ) {
    _ = sbuf
    completionHandler(false, AVFoundationPortableError.mediaServiceUnavailable)
  }
}

extension AVSampleBufferGeneratorBatch {
  public func makeDataReady(completionHandler: @escaping ((any Error)?) -> Void) {
    completionHandler(AVFoundationPortableError.mediaServiceUnavailable)
  }
}

// MARK: - Capture / external-storage fail-closed handlers

extension AVCapturePhotoOutput {
  public func setPreparedPhotoSettingsArray(
    _ preparedPhotoSettingsArray: [AVCapturePhotoSettings],
    completionHandler: @escaping (Bool, (any Error)?) -> Void
  ) {
    _ = preparedPhotoSettingsArray
    completionHandler(false, AVFoundationPortableError.mediaServiceUnavailable)
  }
}

extension AVExternalStorageDevice {
  public class func requestAccess(completionHandler: @escaping (Bool) -> Void) {
    completionHandler(false)
  }
}

extension AVCaptureSlider {
  // No control events exist on this host; the action is accepted and never fired.
  public func setActionQueue(_ actionQueue: DispatchQueue, action: @escaping (Float) -> Void) {
    _ = (actionQueue, action)
  }
}

extension AVCaptureIndexPicker {
  // No control events exist on this host; the action is accepted and never fired.
  public func setActionQueue(_ actionQueue: DispatchQueue, action: @escaping (Int) -> Void) {
    _ = (actionQueue, action)
  }
}

// MARK: - Export session compatibility / estimates (oracle-pinned shapes)

extension AVAssetExportSession {
  // Oracle (bogus asset): compatibility is false.
  public class func determineCompatibility(
    ofExportPreset presetName: String,
    with asset: AVAsset,
    outputFileType: AVFileType?,
    completionHandler: @escaping (Bool) -> Void
  ) {
    _ = (presetName, asset, outputFileType)
    completionHandler(false)
  }
  // Oracle (bogus asset): zero duration, nil error.
  public func estimateMaximumDuration(completionHandler: @escaping (CMTime, (any Error)?) -> Void) {
    completionHandler(.zero, nil)
  }
  // Oracle (bogus asset): zero length, nil error.
  public func estimateOutputFileLength(completionHandler: @escaping (Int64, (any Error)?) -> Void) {
    completionHandler(0, nil)
  }
}

// MARK: - Playback assistant (empty options, no error)

extension AVAssetPlaybackAssistant {
  public func loadPlaybackConfigurationOptions(completionHandler: @escaping ([AVAssetPlaybackConfigurationOption]) -> Void) {
    completionHandler([])
  }
}

// MARK: - Writer input queue registration (inert: never ready, never fired)

extension AVAssetWriterInput {
  public func requestMediaDataWhenReady(on queue: DispatchQueue, using block: @escaping () -> Void) {
    _ = (queue, block)
  }
  public func respondToEachPassDescription(on queue: DispatchQueue, using block: @escaping () -> Void) {
    _ = (queue, block)
  }
}

// MARK: - Caption conversion validation (terminal nil, zero warnings)

extension AVCaptionConversionValidator {
  // Oracle (empty validator): status moves to validating, the handler is
  // delivered once with nil, and validation completes with no warnings.
  // Mirrored synchronously; no conversion service exists on this host.
  public func validateCaptionConversion(warningHandler handler: @escaping (AVCaptionConversionWarning?) -> Void) {
    storedStatus = .validating
    handler(nil)
    storedStatus = .completed
  }
}

extension AVCaptionConversionWarning {
  public var rangeOfCaptions: NSRange { storedRangeOfCaptions }
}

// MARK: - Caption per-index attribute getters (oracle-pinned defaults)

extension AVCaption {
  // Oracle (macOS 26.1, fresh caption): every attribute is the zero default,
  // colors/ruby are nil, and the effective range is the full text range.
  // No attribute storage exists on this host, so defaults always apply.
  public func decoration(at index: String.Index) -> (AVCaption.Decoration, Range<String.Index>) {
    _ = index
    return ([], storedText.startIndex..<storedText.endIndex)
  }
  public func fontWeight(at index: String.Index) -> (AVCaption.FontWeight, Range<String.Index>) {
    _ = index
    return (.unknown, storedText.startIndex..<storedText.endIndex)
  }
  public func textCombine(at index: String.Index) -> (AVCaption.TextCombine, Range<String.Index>) {
    _ = index
    return (.all, storedText.startIndex..<storedText.endIndex)
  }
  public func backgroundColor(at index: String.Index) -> (CGColor?, Range<String.Index>) {
    _ = index
    return (nil, storedText.startIndex..<storedText.endIndex)
  }
  public func ruby(at index: String.Index) -> (AVCaption.Ruby?, Range<String.Index>) {
    _ = index
    return (nil, storedText.startIndex..<storedText.endIndex)
  }
  public func fontStyle(at index: String.Index) -> (AVCaption.FontStyle, Range<String.Index>) {
    _ = index
    return (.unknown, storedText.startIndex..<storedText.endIndex)
  }
  public func textColor(at index: String.Index) -> (CGColor?, Range<String.Index>) {
    _ = index
    return (nil, storedText.startIndex..<storedText.endIndex)
  }
}

// MARK: - Variant qualifier predicates (empty-universe fail-closed)

extension AVAssetVariantQualifier {
  // The Linux variant catalog is empty, so every qualifier matches nothing.
  // NSPredicate(value: false) records that without inventing query semantics.
  // Operator-taking overloads stay deferred: NSComparisonPredicate is
  // unavailable in swift-corelibs-foundation, so their Apple operator type
  // cannot be named on the isolated host.
  public class func predicate(forBinauralAudio isBinauralAudio: Bool) -> NSPredicate {
    _ = isBinauralAudio
    return NSPredicate(value: false)
  }
  public class func predicate(forBinauralAudio isBinauralAudio: Bool, mediaSelectionOption: AVMediaSelectionOption?) -> NSPredicate {
    _ = (isBinauralAudio, mediaSelectionOption)
    return NSPredicate(value: false)
  }
  public class func predicate(forDownmixAudio isDownmixAudio: Bool) -> NSPredicate {
    _ = isDownmixAudio
    return NSPredicate(value: false)
  }
  public class func predicate(forDownmixAudio isDownmixAudio: Bool, mediaSelectionOption: AVMediaSelectionOption?) -> NSPredicate {
    _ = (isDownmixAudio, mediaSelectionOption)
    return NSPredicate(value: false)
  }
  public class func predicate(forImmersiveAudio isImmersiveAudio: Bool) -> NSPredicate {
    _ = isImmersiveAudio
    return NSPredicate(value: false)
  }
  public class func predicate(forImmersiveAudio isImmersiveAudio: Bool, mediaSelectionOption: AVMediaSelectionOption?) -> NSPredicate {
    _ = (isImmersiveAudio, mediaSelectionOption)
    return NSPredicate(value: false)
  }
}

// MARK: - Bracketed still-image settings factories (stored values)

extension AVCaptureAutoExposureBracketedStillImageSettings {
  public class func autoExposureSettings(exposureTargetBias bias: Float) -> Self {
    let settings = Self()
    settings.storedExposureTargetBias = bias
    return settings
  }
}

extension AVCaptureManualExposureBracketedStillImageSettings {
  public class func manualExposureSettings(exposureDuration duration: CMTime, iso ISO: Float) -> Self {
    let settings = Self()
    settings.storedExposureDuration = duration
    settings.storedISO = ISO
    return settings
  }
}

// MARK: - Composition completion-handler twins

extension AVMutableComposition {
  public func insertTimeRange(
    _ timeRange: CMTimeRange,
    of asset: AVAsset,
    at startTime: CMTime,
    completionHandler: @escaping ((any Error)?) -> Void
  ) {
    do {
      try insertTimeRange(timeRange, of: asset, at: startTime)
      completionHandler(nil)
    } catch {
      completionHandler(error)
    }
  }
}

extension AVMutableVideoComposition {
  // Oracle (empty composition input): Apple fails this call. No composition
  // service exists on this host, so it always fails closed here.
  public class func videoComposition(
    withPropertiesOf asset: AVAsset,
    prototypeInstruction: AVVideoCompositionInstruction,
    completionHandler: @escaping (AVMutableVideoComposition?, (any Error)?) -> Void
  ) {
    _ = (asset, prototypeInstruction)
    completionHandler(nil, AVFoundationPortableError.mediaServiceUnavailable)
  }
}

// MARK: - Image generator lazy sequence constructor

extension AVAssetImageGenerator {
  public func images(for times: [CMTime]) -> sending AVAssetImageGenerator.Images {
    _ = times
    return AVAssetImageGenerator.Images()
  }
}

// MARK: - Sample cursor ordering (all cursors pinned: equal)

extension AVSampleCursor {
  public func comparePositionInDecodeOrder(withPositionOf cursor: AVSampleCursor) -> ComparisonResult {
    _ = cursor
    return .orderedSame
  }
}

// MARK: - Zero-state value properties

extension AVFrameRateRange {
  public var maxFrameRate: Double { 0 }
  public var minFrameRate: Double { 0 }
}

extension AVDepthData {
  public var depthDataType: OSType { 0 }
}

extension AVPortraitEffectsMatte {
  public var pixelFormatType: OSType { 0 }
}

extension AVSemanticSegmentationMatte {
  public var pixelFormatType: OSType { 0 }
}

extension AVMetricHLSMediaSegmentRequestEvent {
  // Darwin vends these events (no public init); Linux zero-state has no bytes.
  public var byteRange: NSRange { NSRange(location: 0, length: 0) }
}

extension AVMetricMediaResourceRequestEvent {
  // Darwin vends these events (no public init); Linux zero-state has no bytes.
  public var byteRange: NSRange { NSRange(location: 0, length: 0) }
}

// MARK: - Reader output providers (fail-closed providers, no samples)

extension CMReadySampleBuffer: AVAssetReaderOutput.SupportedPayload where Content == CMSampleBuffer.DynamicContent {}

extension AVTimedMetadataGroup: AVAssetReaderOutput.SupportedPayload {}

extension AVAssetReader {
  public func outputProvider(
    for output: AVAssetReaderOutput
  ) -> sending AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>> {
    _ = output
    return AVAssetReaderOutput.Provider()
  }
  public func outputCaptionProvider(
    for output: AVAssetReaderTrackOutput,
    validationDelegate: (any AVAssetReaderCaptionValidationHandling)? = nil
  ) -> sending AVAssetReaderOutput.Provider<AVCaptionGroup> {
    _ = (output, validationDelegate)
    return AVAssetReaderOutput.Provider()
  }
  public func outputMetadataProvider(
    for output: AVAssetReaderTrackOutput
  ) -> sending AVAssetReaderOutput.Provider<AVTimedMetadataGroup> {
    _ = output
    return AVAssetReaderOutput.Provider()
  }
  public func outputProviderWithRandomAccess(
    for output: AVAssetReaderOutput
  ) -> sending (AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>, AVAssetReaderOutput.RandomAccessController) {
    _ = output
    return (AVAssetReaderOutput.Provider(), AVAssetReaderOutput.RandomAccessController())
  }
  public func outputCaptionProviderWithRandomAccess(
    for output: AVAssetReaderTrackOutput,
    validationDelegate: (any AVAssetReaderCaptionValidationHandling)? = nil
  ) -> sending (AVAssetReaderOutput.Provider<AVCaptionGroup>, AVAssetReaderOutput.RandomAccessController) {
    _ = (output, validationDelegate)
    return (AVAssetReaderOutput.Provider(), AVAssetReaderOutput.RandomAccessController())
  }
  public func outputMetadataProviderWithRandomAccess(
    for output: AVAssetReaderTrackOutput
  ) -> sending (AVAssetReaderOutput.Provider<AVTimedMetadataGroup>, AVAssetReaderOutput.RandomAccessController) {
    _ = output
    return (AVAssetReaderOutput.Provider(), AVAssetReaderOutput.RandomAccessController())
  }
}

// MARK: - Writer input receivers (fail-closed receivers, no encoder)

extension AVAssetWriter {
  public func inputReceiver(
    for input: AVAssetWriterInput
  ) -> sending AVAssetWriterInput.SampleBufferReceiver {
    _ = input
    return AVAssetWriterInput.SampleBufferReceiver()
  }
  public func inputCaptionReceiver(
    for input: AVAssetWriterInput
  ) -> sending AVAssetWriterInput.CaptionReceiver {
    _ = input
    return AVAssetWriterInput.CaptionReceiver()
  }
  public func inputMetadataReceiver(
    for input: AVAssetWriterInput
  ) -> sending AVAssetWriterInput.MetadataReceiver {
    _ = input
    return AVAssetWriterInput.MetadataReceiver()
  }
  public func inputPixelBufferReceiver(
    for input: AVAssetWriterInput,
    pixelBufferAttributes attributes: CVPixelBufferCreationAttributes?
  ) -> sending AVAssetWriterInput.PixelBufferReceiver {
    _ = (input, attributes)
    return AVAssetWriterInput.PixelBufferReceiver()
  }
  public func inputTaggedPixelBufferGroupReceiver(
    for input: AVAssetWriterInput,
    pixelBufferAttributes attributes: CVPixelBufferCreationAttributes?
  ) -> sending AVAssetWriterInput.TaggedPixelBufferGroupReceiver {
    _ = (input, attributes)
    return AVAssetWriterInput.TaggedPixelBufferGroupReceiver()
  }
  public func inputReceiverRequestingMultiPass(
    for input: AVAssetWriterInput
  ) -> sending (AVAssetWriterInput.SampleBufferReceiver, AVAssetWriterInput.MultiPassController) {
    _ = input
    return (AVAssetWriterInput.SampleBufferReceiver(), AVAssetWriterInput.MultiPassController())
  }
  public func inputCaptionReceiverRequestingMultiPass(
    for input: AVAssetWriterInput
  ) -> sending (AVAssetWriterInput.CaptionReceiver, AVAssetWriterInput.MultiPassController) {
    _ = input
    return (AVAssetWriterInput.CaptionReceiver(), AVAssetWriterInput.MultiPassController())
  }
  public func inputMetadataReceiverRequestingMultiPass(
    for input: AVAssetWriterInput
  ) -> sending (AVAssetWriterInput.MetadataReceiver, AVAssetWriterInput.MultiPassController) {
    _ = input
    return (AVAssetWriterInput.MetadataReceiver(), AVAssetWriterInput.MultiPassController())
  }
  public func inputPixelBufferReceiverRequestingMultiPass(
    for input: AVAssetWriterInput,
    pixelBufferAttributes attributes: CVPixelBufferCreationAttributes?
  ) -> sending (AVAssetWriterInput.PixelBufferReceiver, AVAssetWriterInput.MultiPassController) {
    _ = (input, attributes)
    return (AVAssetWriterInput.PixelBufferReceiver(), AVAssetWriterInput.MultiPassController())
  }
  public func inputTaggedPixelBufferGroupReceiverRequestingMultiPass(
    for input: AVAssetWriterInput,
    pixelBufferAttributes attributes: CVPixelBufferCreationAttributes?
  ) -> sending (AVAssetWriterInput.TaggedPixelBufferGroupReceiver, AVAssetWriterInput.MultiPassController) {
    _ = (input, attributes)
    return (AVAssetWriterInput.TaggedPixelBufferGroupReceiver(), AVAssetWriterInput.MultiPassController())
  }
}
