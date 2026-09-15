import Foundation
import AVFoundation

// Depth pass 12: remaining declared non-capture data models that already
// compile (or needed only stored-value behavior). Every test is top-level,
// synchronous, and takes no arguments. No capture hardware, player chrome,
// async load, FairPlay, PiP, AirPlay, or CIImage filtering success is claimed.

func testMutableAudioMixInputParametersTrackFactory() {
    // Swift spelling of +audioMixInputParametersWithTrack:.
    let track = AVAssetTrack()
    let params = AVMutableAudioMixInputParameters(track: track)
    precondition(params.trackID == track.trackID)
    let untracked = AVMutableAudioMixInputParameters(track: nil)
    precondition(untracked.trackID == 0)
    // Inherited stored audioTimePitchAlgorithm on the mutable subclass.
    precondition(params.audioTimePitchAlgorithm == nil)
    params.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm(rawValue: "varispeed")
    precondition(params.audioTimePitchAlgorithm == AVAudioTimePitchAlgorithm(rawValue: "varispeed"))
}

func testMutableVideoCompositionLayerInstructionRampSetters() {
    let instruction = AVMutableVideoCompositionLayerInstruction()
    let range = CMTimeRange(start: .zero, duration: CMTime(value: 60, timescale: 600))
    let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
    instruction.setCropRectangle(rect, at: .zero)
    var startRect = CGRect.zero
    var endRect = CGRect.zero
    var cropRange = CMTimeRange.zero
    precondition(instruction.getCropRectangleRamp(for: .zero, startCropRectangle: &startRect, endCropRectangle: &endRect, timeRange: &cropRange))
    precondition(startRect == rect && endRect == rect)
    let cropEnd = CGRect(x: 5, y: 6, width: 7, height: 8)
    instruction.setCropRectangleRamp(fromStartCropRectangle: rect, toEndCropRectangle: cropEnd, timeRange: range)
    precondition(instruction.getCropRectangleRamp(for: .zero, startCropRectangle: &startRect, endCropRectangle: &endRect, timeRange: &cropRange))
    precondition(startRect == rect && endRect == cropEnd && cropRange == range)
    instruction.setOpacityRamp(fromStartOpacity: 0.25, toEndOpacity: 0.75, timeRange: range)
    var startOpacity: Float = 0
    var endOpacity: Float = 0
    var opacityRange = CMTimeRange.zero
    precondition(instruction.getOpacityRamp(for: .zero, startOpacity: &startOpacity, endOpacity: &endOpacity, timeRange: &opacityRange))
    precondition(startOpacity == 0.25 && endOpacity == 0.75 && opacityRange == range)
    let startTransform = CGAffineTransform(a: 2, b: 0, c: 0, d: 2, tx: 1, ty: 1)
    instruction.setTransformRamp(fromStartTransform: .identity, toEndTransform: startTransform, timeRange: range)
    var outStart = CGAffineTransform.identity
    var outEnd = CGAffineTransform.identity
    var transformRange = CMTimeRange.zero
    precondition(instruction.getTransformRamp(for: .zero, start: &outStart, end: &outEnd, timeRange: &transformRange))
    precondition(outStart == .identity && outEnd == startTransform && transformRange == range)
}

func testTextStyleRuleStoredAttributes() {
    let rule = AVTextStyleRule(textMarkupAttributes: ["font": "Helvetica", "size": 14])!
    precondition((rule.textMarkupAttributes["font"] as? String) == "Helvetica")
    precondition((rule.textMarkupAttributes["size"] as? Int) == 14)
    let second = AVTextStyleRule()
    precondition(second.textMarkupAttributes.isEmpty)
    let plist = AVTextStyleRule.propertyList(for: [rule, second])
    let roundTripped = AVTextStyleRule.textStyleRules(fromPropertyList: plist)!
    precondition(roundTripped.count == 2)
    precondition((roundTripped[0].textMarkupAttributes["font"] as? String) == "Helvetica")
    precondition(roundTripped[1].textMarkupAttributes.isEmpty)
    precondition(AVTextStyleRule.textStyleRules(fromPropertyList: "not-a-plist") == nil)
}

func testSampleBufferGeneratorFailClosedBatch() {
    let asset = AVAsset()
    let generator = AVSampleBufferGenerator(asset: asset, timebase: nil)
    let batch = generator.makeBatch()
    batch.cancel()
    let request = AVSampleBufferRequest()
    var threwSingle = false
    do {
        _ = try generator.makeSampleBuffer(for: request)
    } catch {
        threwSingle = true
    }
    precondition(threwSingle)
    var threwBatched = false
    do {
        _ = try generator.makeSampleBuffer(for: request, addTo: batch)
    } catch {
        threwBatched = true
    }
    precondition(threwBatched)
}

func testVideoPerformanceMetricsZeroCounters() {
    let metrics = AVVideoPerformanceMetrics()
    precondition(metrics.totalNumberOfFrames == 0)
    precondition(metrics.numberOfDroppedFrames == 0)
    precondition(metrics.numberOfCorruptedFrames == 0)
    precondition(metrics.numberOfFramesDisplayedUsingOptimizedCompositing == 0)
    precondition(metrics.totalAccumulatedFrameDelay == 0)
}

final class DepthPass12CaptionValidationWitness: NSObject, AVAssetReaderCaptionValidationHandling {
    var vended: [(AVCaption, [String])] = []
    func captionAdaptor(_ adaptor: AVAssetReaderOutputCaptionAdaptor, didVendCaption caption: AVCaption, skippingUnsupportedSourceSyntaxElements syntaxElements: [String]) {
        vended.append((caption, syntaxElements))
    }
}

func testAssetReaderCaptionValidationHandlingWitness() {
    let witness = DepthPass12CaptionValidationWitness()
    let handler: any AVAssetReaderCaptionValidationHandling = witness
    let adaptor = AVAssetReaderOutputCaptionAdaptor()
    let caption = AVCaption()
    handler.captionAdaptor(adaptor, didVendCaption: caption, skippingUnsupportedSourceSyntaxElements: ["ruby"])
    precondition(witness.vended.count == 1)
    precondition(witness.vended[0].1 == ["ruby"])
}

final class DepthPass12ResourceLoaderWitness: NSObject, AVAssetResourceLoaderDelegate {
    var cancelled: [AVAssetResourceLoadingRequest] = []
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        _ = (resourceLoader, loadingRequest)
        return false
    }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        _ = (resourceLoader, renewalRequest)
        return false
    }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        _ = resourceLoader
        cancelled.append(loadingRequest)
    }
}

func testAssetResourceLoaderDelegateFailClosed() {
    let witness = DepthPass12ResourceLoaderWitness()
    let delegate: any AVAssetResourceLoaderDelegate = witness
    let loader = AVAssetResourceLoader()
    let loadingRequest = AVAssetResourceLoadingRequest()
    let renewalRequest = AVAssetResourceRenewalRequest()
    precondition(delegate.resourceLoader(loader, shouldWaitForLoadingOfRequestedResource: loadingRequest) == false)
    precondition(delegate.resourceLoader(loader, shouldWaitForRenewalOfRequestedResource: renewalRequest) == false)
    delegate.resourceLoader(loader, didCancel: loadingRequest)
    precondition(witness.cancelled.count == 1)
}

final class DepthPass12WriterWitness: NSObject, AVAssetWriterDelegate, @unchecked Sendable {
    var segments: [(Data, AVAssetSegmentType)] = []
    var reports = 0
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        _ = (writer, segmentReport)
        segments.append((segmentData, segmentType))
        reports += 1
    }
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType) {
        _ = writer
        segments.append((segmentData, segmentType))
    }
}

func testAssetWriterDelegateSegmentCallbacks() {
    let witness = DepthPass12WriterWitness()
    let delegate: any AVAssetWriterDelegate = witness
    let writer = AVAssetWriter()
    delegate.assetWriter(writer, didOutputSegmentData: Data([1, 2, 3]), segmentType: .initialization, segmentReport: nil)
    delegate.assetWriter(writer, didOutputSegmentData: Data([4]), segmentType: .separable)
    precondition(witness.segments.count == 2)
    precondition(witness.segments[0].0 == Data([1, 2, 3]) && witness.segments[0].1 == .initialization)
    precondition(witness.reports == 1)
}

func testFragmentMindingAssociation() {
    // ObjC property associatedWithFragmentMinder is projected in Swift as
    // isAssociatedWithFragmentMinder.
    let minder: any AVFragmentMinding = AVFragmentedAsset(url: URL(string: "file:///tmp/nonexistent-fragmented.mp4")!)
    precondition(minder.isAssociatedWithFragmentMinder == false)
    let asset = AVFragmentedAsset(url: URL(string: "file:///tmp/nonexistent-other.mp4")!)
    precondition(asset.isAssociatedWithFragmentMinder == false)
}

struct DepthPass12TestPayload: AVAssetReaderOutput.SupportedPayload {}

func testAssetReaderOutputProviderCaptionQuery() {
    let provider = AVAssetReaderOutput.Provider<DepthPass12TestPayload>()
    let group = AVCaptionGroup()
    precondition(provider.captionsNotPresentInPreviousGroups(in: group).isEmpty)
}

func testRemainingRawValueInitializers() {
    // Table-driven init(rawValue:) witnesses for string/option-set types whose
    // member values were pinned by earlier passes.
    precondition(AVVideoApertureMode(rawValue: "cleanAperture") == .cleanAperture)
    precondition(AVVideoApertureMode(rawValue: "encodedPixels") == .encodedPixels)
    precondition(AVAssetTrack.AssociationType(rawValue: "timecode") == .timecode)
    precondition(AVAssetTrack.AssociationType(rawValue: "chapterList") == .chapterList)
    precondition(AVAudioTimePitchAlgorithm(rawValue: "varispeed") == .varispeed)
    precondition(AVAudioTimePitchAlgorithm(rawValue: "spectral") == .spectral)
    precondition(AVAudioSpatializationFormats(rawValue: 1) == .monoAndStereo)
    precondition(AVAudioSpatializationFormats(rawValue: 1 << 1) == .multichannel)
    precondition(AVSpatialCaptureDiscomfortReason(rawValue: "notEnoughLight") == .notEnoughLight)
    precondition(AVSpatialCaptureDiscomfortReason(rawValue: "subjectTooClose") == .subjectTooClose)
    precondition(AVAssetImageGenerator.ApertureMode(rawValue: "cleanAperture") == .cleanAperture)
    precondition(AVAssetImageGenerator.ApertureMode(rawValue: "encodedPixels") == .encodedPixels)
    precondition(AVAssetPlaybackConfigurationOption(rawValue: "spatialVideo") == .spatialVideo)
    precondition(AVAssetPlaybackConfigurationOption(rawValue: "stereoVideo") == .stereoVideo)
    precondition(AVAssetImageGenerator.DynamicRangePolicy(rawValue: "forceSDR") == .forceSDR)
    precondition(AVAssetImageGenerator.DynamicRangePolicy(rawValue: "matchSource") == .matchSource)
}
