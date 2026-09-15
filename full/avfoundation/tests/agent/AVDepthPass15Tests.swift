import Foundation
import AVFoundation

// Depth pass 15 (wave 6): leftover declared capture data models that already
// compile (plus small access-level fixes and Apple-mirrored shims in
// AVDepthPass15.swift). Every test is top-level, synchronous, and takes no
// arguments. No camera, microphone, encoder, or Apple service success is
// claimed: device lists stay empty, capture calls fail closed or return
// zeros, and completion handlers run synchronously on the caller.

// AVCaptureDeviceInput's throwing device init cannot produce an instance on
// Linux; this subclass taps the inherited non-throwing init so the real
// follow/multichannel members can be exercised.
final class Depth15DeviceInput: AVCaptureDeviceInput, @unchecked Sendable {}

// SortComparator over synchronized data so the FoundationEssentials
// sorted(using:)/compare witnesses resolve on Linux (empty collection
// stays fail-closed with no ordering claims).
struct Depth15DataComparator: SortComparator, Sendable {
    typealias Compared = AVCaptureSynchronizedData
    var order: SortOrder = .forward
    func compare(_ lhs: AVCaptureSynchronizedData, _ rhs: AVCaptureSynchronizedData) -> ComparisonResult {
        _ = (lhs, rhs)
        return .orderedSame
    }
}

func testDepth15AudioChannelAndBrackets() {
    let channel = AVCaptureAudioChannel()
    precondition(channel.averagePowerLevel == 0)
    precondition(channel.peakHoldLevel == 0)
    _ = AVCaptureBracketedStillImageSettings()
    let auto = AVCaptureAutoExposureBracketedStillImageSettings()
    precondition(auto.exposureTargetBias == 0)
    let manual = AVCaptureManualExposureBracketedStillImageSettings()
    precondition(manual.exposureDuration == .zero)
    precondition(manual.iso == 0)
    _ = AVCaptureDeferredPhotoProxy()
}

func testDepth15CaptureConnectionControls() {
    let connection = AVCaptureConnection()
    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode(rawValue: 0)!
    _ = connection.preferredVideoStabilizationMode
    _ = connection.activeVideoStabilizationMode
    connection.enablesVideoStabilizationWhenAvailable = true
    precondition(connection.enablesVideoStabilizationWhenAvailable == false)
    let control = AVCaptureControl()
    control.isEnabled = true
    precondition(control.isEnabled == false)
}

func testDepth15DeviceCompletionHandlers() {
    let device = AVCaptureDevice()
    var focusSeen = false
    device.setFocusModeLocked(lensPosition: 0.5) { syncTime in
        focusSeen = syncTime == .zero
    }
    precondition(focusSeen)
    device.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
    var exposureSeen = false
    device.setExposureModeCustom(duration: .zero, iso: 100) { syncTime in
        exposureSeen = syncTime == .zero
    }
    precondition(exposureSeen)
    device.setExposureModeCustom(duration: .zero, iso: 100, completionHandler: nil)
    var biasSeen = false
    device.setExposureTargetBias(0.5) { syncTime in
        biasSeen = syncTime == .zero
    }
    precondition(biasSeen)
    device.setExposureTargetBias(0.5, completionHandler: nil)
    var gainsSeen = false
    device.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(AVCaptureDevice.WhiteBalanceGains()) { syncTime in
        gainsSeen = syncTime == .zero
    }
    precondition(gainsSeen)
    device.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(AVCaptureDevice.WhiteBalanceGains(), completionHandler: nil)
    var tintSeen = false
    device.setWhiteBalanceModeLocked(whiteBalanceTemperatureAndTintValues: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 6500, tint: 0)) { syncTime in
        tintSeen = syncTime == .zero
    }
    precondition(tintSeen)
    device.setWhiteBalanceModeLocked(whiteBalanceTemperatureAndTintValues: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 6500, tint: 0), handler: nil)
    var aspectSeen = false
    device.setDynamicAspectRatio(AVCaptureDevice.AspectRatio(rawValue: "ratio16x9")) { syncTime, error in
        aspectSeen = syncTime == .zero && error == nil
    }
    precondition(aspectSeen)
    device.setDynamicAspectRatio(AVCaptureDevice.AspectRatio(rawValue: "ratio16x9"), completionHandler: nil)
}

func testDepth15DeviceInputFollow() {
    let input = Depth15DeviceInput()
    input.follow(AVExternalSyncDevice(), videoFrameDuration: .zero, delegate: nil)
    precondition(input.activeExternalSyncVideoFrameDuration == .zero)
    input.multichannelAudioMode = .stereo
    _ = input.multichannelAudioMode
}

func testDepth15ExternalDisplay() {
    let config = AVCaptureExternalDisplayConfiguration()
    config.shouldMatchFrameRate = true
    config.bypassColorSpaceConversion = true
    config.preferredResolution = CMVideoDimensions(width: 1920, height: 1080)
    _ = config.shouldMatchFrameRate
    _ = config.bypassColorSpaceConversion
    _ = config.preferredResolution
    let configurator = AVCaptureExternalDisplayConfigurator()
    _ = configurator.device
    _ = configurator.isActive
    _ = configurator.activeExternalDisplayFrameRate
    configurator.stop()
}

func testDepth15FramingAndPickers() {
    let framing = AVCaptureFraming()
    _ = framing.aspectRatio
    precondition(framing.zoomFactor == 0)
    let byCount = AVCaptureIndexPicker("Title", symbolName: "star", numberOfIndexes: 3)
    let byTransform = AVCaptureIndexPicker("Title", symbolName: "star", numberOfIndexes: 3) { "Index \($0)" }
    let byTitles = AVCaptureIndexPicker("Title", symbolName: "star", localizedIndexTitles: ["a", "b"])
    for picker in [byCount, byTransform, byTitles] {
        picker.selectedIndex = 1
        precondition(picker.selectedIndex == 0)
        _ = picker.localizedTitle
        _ = picker.symbolName
        _ = picker.numberOfIndexes
        _ = picker.localizedIndexTitles
        picker.accessibilityIdentifier = "picker"
        _ = picker.accessibilityIdentifier
    }
}

func testDepth15MetadataInputAndMovieFile() {
    _ = AVCaptureMetadataInput()
    let timed = AVCaptureMetadataInput(formatDescription: CMMetadataFormatDescription(), clock: CMClock())
    let group = AVTimedMetadataGroup(items: [], timeRange: .zero)
    do {
        try timed.append(group)
        preconditionFailure("append must fail closed without a media service")
    } catch {
        _ = error
    }
    let movie = AVCaptureMovieFileOutput()
    let connection = AVCaptureConnection()
    movie.setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(true, for: connection)
    precondition(movie.recordsVideoOrientationAndMirroringChangesAsMetadataTrack(for: connection))
}

func testDepth15MulticamPhotoReaction() {
    let session = AVCaptureMultiCamSession()
    precondition(session.hardwareCost == 0)
    precondition(session.systemPressureCost == 0)
    let photo = AVCapturePhoto()
    _ = photo.bracketSettings
    _ = photo.resolvedSettings
    let bracket = AVCapturePhotoBracketSettings(rawPixelFormatType: 0, processedFormat: nil, bracketedSettings: [])
    let bracketFull = AVCapturePhotoBracketSettings(rawPixelFormatType: 0, rawFileType: nil, processedFormat: nil, processedFileType: nil, bracketedSettings: [])
    precondition(bracket.bracketedSettings.isEmpty)
    precondition(bracketFull.bracketedSettings.isEmpty)
    bracket.isLensStabilizationEnabled = true
    precondition(bracket.isLensStabilizationEnabled == false)
    let effect = AVCaptureReactionEffectState()
    _ = effect.reactionType
    precondition(effect.startTime == .zero)
    precondition(effect.endTime == .zero)
    precondition(AVCaptureReactionType(rawValue: "thumbsUp") == .thumbsUp)
    precondition(AVCaptureReactionType.thumbsUp.systemImageName == "hand.thumbsup.fill")
    precondition(AVCaptureReactionType.heart.systemImageName == "heart.fill")
    precondition(AVCaptureReactionType(rawValue: "future").systemImageName == "")
}

func testDepth15Sliders() {
    let range = AVCaptureSlider("Title", symbolName: "star", in: 0...1)
    let stepped = AVCaptureSlider("Title", symbolName: "star", in: 0...1, step: 0.1)
    let valued = AVCaptureSlider("Title", symbolName: "star", values: [0, 0.5, 1])
    for slider in [range, stepped, valued] {
        slider.value = 0.5
        precondition(slider.value == 0)
        slider.prominentValues = [0.25]
        precondition(slider.prominentValues.isEmpty)
        slider.localizedValueFormat = "%.1f"
        _ = slider.localizedValueFormat
        _ = slider.localizedTitle
        _ = slider.symbolName
        slider.accessibilityIdentifier = "slider"
        _ = slider.accessibilityIdentifier
    }
    _ = AVCaptureSystemExposureBiasSlider(device: AVCaptureDevice())
    _ = AVCaptureSystemExposureBiasSlider(device: AVCaptureDevice()) { _ in }
    _ = AVCaptureSystemZoomSlider(device: AVCaptureDevice())
    _ = AVCaptureSystemZoomSlider(device: AVCaptureDevice()) { _ in }
}

func testDepth15SmartFramingAndSpatial() {
    let monitor = AVCaptureSmartFramingMonitor()
    precondition(monitor.supportedFramings.isEmpty)
    monitor.enabledFramings = [AVCaptureFraming()]
    precondition(monitor.enabledFramings.isEmpty)
    _ = monitor.recommendedFraming
    precondition(monitor.isMonitoring == false)
    monitor.stopMonitoring()
    do {
        try monitor.startMonitoring()
        preconditionFailure("startMonitoring must fail closed without a device")
    } catch {
        _ = error
    }
    let generator = AVCaptureSpatialAudioMetadataSampleGenerator()
    generator.resetAnalyzer()
    _ = generator.newTimedMetadataSampleBufferAndResetAnalyzer()
    _ = generator.timedMetadataSampleBufferFormatDescription
}

func testDepth15SynchronizedData() {
    let data = AVCaptureSynchronizedData()
    precondition(data.timestamp == .zero)
    let collection = AVCaptureSynchronizedDataCollection()
    var iterator = collection.makeIterator()
    precondition(iterator.next() == nil)
    _ = AVCaptureSynchronizedDataCollection.Iterator()
    _ = AVCaptureSynchronizedDataCollection.Element.self
    let output = AVCaptureOutput()
    precondition(collection.synchronizedData(for: output) == nil)
    precondition(collection[output] == nil)
    precondition(collection.count == 0)
    let depth = AVCaptureSynchronizedDepthData()
    _ = depth.depthData
    precondition(depth.depthDataWasDropped == false)
    _ = depth.droppedReason
    let meta = AVCaptureSynchronizedMetadataObjectData()
    precondition(meta.metadataObjects.isEmpty)
    let sample = AVCaptureSynchronizedSampleBufferData()
    _ = sample.sampleBuffer
    precondition(sample.sampleBufferWasDropped == false)
    _ = sample.droppedReason
}

func testDepth15Timecode() {
    var timecode = AVCaptureTimecode()
    timecode = AVCaptureTimecode(hours: 1, minutes: 2, seconds: 3, frames: 4, userBits: 0, frameDuration: .zero, sourceType: .frameCount)
    _ = AVCaptureTimecode.advanced(timecode, by: 10)
    _ = AVCaptureTimecode.createMetadataSampleBuffer(from: timecode, associatedWithPresentationTimeStamp: .zero)
    _ = AVCaptureTimecode.createMetadataSampleBuffer(from: timecode, forDuration: .zero)
    let source = AVCaptureTimecode.Source()
    _ = source.displayName
    _ = source.type
    _ = source.uuid
    let generator = AVCaptureTimecodeGenerator()
    precondition(generator.availableSources.isEmpty)
    _ = generator.currentSource
    _ = generator.delegate
    generator.setDelegate(nil, queue: nil)
    generator.synchronizationTimeout = 1
    precondition(generator.synchronizationTimeout == 0)
    generator.timecodeAlignmentOffset = 1
    precondition(generator.timecodeAlignmentOffset == 0)
    generator.timecodeFrameDuration = CMTime(value: 1, timescale: 30)
    precondition(generator.timecodeFrameDuration == .zero)
    generator.startSynchronization(source: AVCaptureTimecode.Source())
    _ = generator.generateInitialTimecode()
}

func testDepth15SynchronizedSequenceA() {
    let collection = AVCaptureSynchronizedDataCollection()
    precondition(collection.allSatisfy { _ in true })
    precondition(collection.compactMap { $0 as AVCaptureSynchronizedData? }.isEmpty)
    precondition(collection.enumerated().map { $0.offset }.isEmpty)
    precondition(collection.underestimatedCount == 0)
    _ = collection.withContiguousStorageIfAvailable { _ in 0 }
    precondition(collection.map { _ in 1 }.isEmpty)
    precondition(collection.max { _, _ in false } == nil)
    precondition(collection.min { _, _ in false } == nil)
    precondition(collection.drop { _ in false }.first(where: { _ in true }) == nil)
    precondition(collection.lazy.first(where: { _ in true }) == nil)
    precondition(collection.count { _ in true } == 0)
    precondition(collection.first { _ in true } == nil)
    precondition(collection.filter { _ in true }.isEmpty)
    precondition(collection.prefix { _ in true }.isEmpty)
    precondition(Array(collection.prefix(2)).isEmpty)
    precondition(collection.reduce(into: 0) { acc, _ in acc += 1 } == 0)
    precondition(collection.reduce(0) { acc, _ in acc + 1 } == 0)
}

func testDepth15SynchronizedSequenceB() {
    let collection = AVCaptureSynchronizedDataCollection()
    precondition(collection.sorted { _, _ in false }.isEmpty)
    precondition(Array(collection.suffix(2)).isEmpty)
    precondition(collection.flatMap { [$0] }.isEmpty)
    precondition(collection.flatMap { _ in [AVCaptureSynchronizedData]() }.isEmpty)
    collection.forEach { _ in }
    precondition(collection.contains { _ in true } == false)
    precondition(Array(collection.dropLast()).isEmpty)
    precondition(Array(collection.dropFirst()).isEmpty)
    precondition(Array(collection.reversed()).isEmpty)
    var generator = SystemRandomNumberGenerator()
    _ = collection.shuffled(using: &generator)
    _ = collection.shuffled()
    precondition(collection.split(maxSplits: 1, omittingEmptySubsequences: true) { _ in false }.isEmpty)
    precondition(collection.starts(with: [], by: { _, _ in true }))
    precondition(collection.elementsEqual([], by: { _, _ in true }))
    precondition(collection.lexicographicallyPrecedes([], by: { _, _ in true }) == false)
    precondition(collection.sorted(using: Depth15DataComparator()).isEmpty)
    precondition(collection.sorted(using: [Depth15DataComparator()]).isEmpty)
}

func testDepth15AsyncPropertyStatus() {
    typealias Status = AVAsyncProperty<AVAsset, Bool>.Status
    precondition(Status.loading == Status.loading)
    precondition(Status.loading != Status.notYetLoaded)
    precondition(Status.loading.description == "loading")
    precondition(Status.failed(NSError(domain: "x", code: 1)).description == "failed")
    precondition(Status.loaded(true) == Status.loaded(true))
    precondition(!(Status.loaded(true) == Status.loaded(false)))
    _ = AVAnyAsyncProperty()
    precondition(AVAnyAsyncProperty().description.isEmpty == false)
    _ = AVPartialAsyncProperty<AVAsset>()
    precondition(AVPartialAsyncProperty<AVAsset>().description.isEmpty == false)
    _ = AVMergedMetrics<AVMetricEvent, AVMetricEvent, AVMetrics<AVMetricEvent>>()
    _ = AVMergedMetrics<AVMetricEvent, AVMetricEvent, AVMetrics<AVMetricEvent>>.Element.self
    _ = AVMergedMetrics<AVMetricEvent, AVMetricEvent, AVMetrics<AVMetricEvent>>.AsyncIterator.self
}
