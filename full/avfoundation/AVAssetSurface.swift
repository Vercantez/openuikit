import Foundation

extension AVAsset {
  public func loadChapterMetadataGroups(withTitleLocale locale: Locale, containingItemsWithCommonKeys commonKeys: [AVMetadataKey] = []) async throws -> [AVTimedMetadataGroup] { return [] }
  public func unusedTrackID() -> CMPersistentTrackID {
    let used = Set(tracks.map(\.trackID))
    var candidate: CMPersistentTrackID = 1
    while used.contains(candidate) { candidate += 1 }
    return candidate
  }
  public func findUnusedTrackID() async throws -> CMPersistentTrackID { unusedTrackID() }
  public func findUnusedTrackID(completionHandler: @escaping (CMPersistentTrackID, (any Error)?) -> Void) {
    completionHandler(unusedTrackID(), nil)
  }
  public var duration: CMTime {
    // Injected host SPI wins so first-pass clock tests stay deterministic.
    // Otherwise a local ISO-BMFF / WAV / AIFF probe supplies the movie header.
    // Missing files stay .invalid (measured testAVAssetLoadFailClosed).
    if let injected = loadState.injectedDuration {
      return AVTimeMath.time(seconds: injected)
    }
    if let probe = portableProbe(), probe.duration.isValid {
      return probe.duration
    }
    let trackSeconds = portableStoredTracks().compactMap { track -> Double? in
      let seconds = track.timeRange.duration.seconds
      return seconds > 0 ? seconds : nil
    }.max()
    if let trackSeconds {
      return AVTimeMath.time(seconds: trackSeconds)
    }
    return .invalid
  }
  public var preferredRate: Float { portableProbe()?.preferredRate ?? 0 }
  public var preferredVolume: Float {
    if let audio = tracks.first(where: { $0.mediaType == .audio }) {
      return audio.preferredVolume
    }
    return portableProbe()?.preferredVolume ?? 0
  }
  public var preferredTransform: CGAffineTransform {
    portableProbe()?.preferredTransform ?? .identity
  }
  public var minimumTimeOffsetFromLive: CMTime { .invalid }
  public var providesPreciseDurationAndTiming: Bool { false }
  public func cancelLoading() {}
  public var referenceRestrictions: AVAssetReferenceRestrictions { AVAssetReferenceRestrictions(rawValue: 0) }
  public var tracks: [AVAssetTrack] { portableStoredTracks() }
  public func track(withTrackID trackID: CMPersistentTrackID) -> AVAssetTrack? {
    tracks.first(where: { $0.trackID == trackID })
  }
  public func loadTrack(withTrackID trackID: CMPersistentTrackID) async throws -> AVAssetTrack? {
    return track(withTrackID: trackID)
  }
  public func loadTrack(withTrackID trackID: CMPersistentTrackID, completionHandler: @escaping (AVAssetTrack?, (any Error)?) -> Void) {
    completionHandler(track(withTrackID: trackID), nil)
  }
  public func tracks(withMediaType mediaType: AVMediaType) -> [AVAssetTrack] {
    tracks.filter { $0.mediaType == mediaType }
  }
  public func loadTracks(withMediaType mediaType: AVMediaType) async throws -> [AVAssetTrack] {
    return tracks(withMediaType: mediaType)
  }
  public func loadTracks(
    withMediaType mediaType: AVMediaType,
    completionHandler: @escaping ([AVAssetTrack]?, (any Error)?) -> Void
  ) {
    completionHandler(tracks(withMediaType: mediaType), nil)
  }
  public func tracks(withMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) -> [AVAssetTrack] {
    tracks.filter { $0.hasMediaCharacteristic(mediaCharacteristic) }
  }
  public func loadTracks(withMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) async throws -> [AVAssetTrack] {
    return tracks(withMediaCharacteristic: mediaCharacteristic)
  }
  public func loadTracks(
    withMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic,
    completionHandler: @escaping ([AVAssetTrack]?, (any Error)?) -> Void
  ) {
    completionHandler(tracks(withMediaCharacteristic: mediaCharacteristic), nil)
  }
  public var trackGroups: [AVAssetTrackGroup] { [] }
  public var creationDate: AVMetadataItem? { nil }
  public var lyrics: String? { nil }
  public var commonMetadata: [AVMetadataItem] { [] }
  public var metadata: [AVMetadataItem] { [] }
  public var availableMetadataFormats: [AVMetadataFormat] { [] }
  public func metadata(forFormat format: AVMetadataFormat) -> [AVMetadataItem] { [] }
  public func loadMetadata(for format: AVMetadataFormat) async throws -> [AVMetadataItem] { return [] }
  public var availableChapterLocales: [Locale] { [] }
  public func chapterMetadataGroups(withTitleLocale locale: Locale, containingItemsWithCommonKeys commonKeys: [AVMetadataKey]?) -> [AVTimedMetadataGroup] { [] }
  public func chapterMetadataGroups(bestMatchingPreferredLanguages preferredLanguages: [String]) -> [AVTimedMetadataGroup] { [] }
  public func loadChapterMetadataGroups(bestMatchingPreferredLanguages preferredLanguages: [String]) async throws -> [AVTimedMetadataGroup] { return [] }
  public var availableMediaCharacteristicsWithMediaSelectionOptions: [AVMediaCharacteristic] { [] }
  public func mediaSelectionGroup(forMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) -> AVMediaSelectionGroup? { nil }
  public func loadMediaSelectionGroup(for mediaCharacteristic: AVMediaCharacteristic) async throws -> AVMediaSelectionGroup? { return nil }
  public var preferredMediaSelection: AVMediaSelection { AVMediaSelection() }
  public var allMediaSelections: [AVMediaSelection] { [] }
  public var hasProtectedContent: Bool { false }
  public var canContainFragments: Bool { false }
  public var containsFragments: Bool { false }
  public var overallDurationHint: CMTime { .invalid }
  public var isPlayable: Bool { false }
  public var isExportable: Bool { false }
  public var isReadable: Bool { false }
  public var isComposable: Bool { false }
  public var isCompatibleWithSavedPhotosAlbum: Bool { false }
  public var isCompatibleWithAirPlayVideo: Bool { false }
}

open class AVAssetCache: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var isPlayableOffline: Bool { false }
  public func mediaSelectionOptions(in mediaSelectionGroup: AVMediaSelectionGroup) -> [AVMediaSelectionOption] { [] }
  public func mediaPresentationLanguages(for mediaSelectionGroup: AVMediaSelectionGroup) -> [String] { [] }
}

open class AVAssetDownloadConfiguration: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(asset: AVURLAsset, title: String) { self.init() }
  public var artworkData: Data? {
      get { nil }
      set { _ = newValue }
    }
  public var primaryContentConfiguration: AVAssetDownloadContentConfiguration { AVAssetDownloadContentConfiguration() }
  public var auxiliaryContentConfigurations: [AVAssetDownloadContentConfiguration] {
      get { [] }
      set { _ = newValue }
    }
  public var optimizesAuxiliaryContentConfigurations: Bool {
      get { false }
      set { _ = newValue }
    }
  public func setInterstitialMediaSelectionCriteria(_ criteria: [AVPlayerMediaSelectionCriteria], forMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) {}
}

open class AVAssetDownloadContentConfiguration: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var variantQualifiers: [AVAssetVariantQualifier] {
      get { [] }
      set { _ = newValue }
    }
  public var mediaSelections: [AVMediaSelection] {
      get { [] }
      set { _ = newValue }
    }
}

open class AVAssetDownloadStorageManagementPolicy: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var priority: AVAssetDownloadedAssetEvictionPriority { AVAssetDownloadedAssetEvictionPriority(rawValue: "") }
  public var expirationDate: Date { Date.distantPast }
}

open class AVAssetDownloadStorageManager: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public class func shared() -> AVAssetDownloadStorageManager { AVAssetDownloadStorageManager() }
  public func setStorageManagementPolicy(_ storageManagementPolicy: AVAssetDownloadStorageManagementPolicy, for downloadStorageURL: URL) {}
  public func storageManagementPolicy(for downloadStorageURL: URL) -> AVAssetDownloadStorageManagementPolicy? { nil }
}

public struct AVAssetDownloadedAssetEvictionPriority: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let important = AVAssetDownloadedAssetEvictionPriority(rawValue: "important")
  public static let `default` = AVAssetDownloadedAssetEvictionPriority(rawValue: "default")
}

extension AVAssetExportSession {
  public enum State {
    case pending
    case waiting
    case exporting(progress: Progress)
  }
  public class func allExportPresets() -> [String] { [] }
  public class func exportPresets(compatibleWith asset: AVAsset) -> [String] {
    _ = asset
    return []
  }
  public class func compatibility(ofExportPreset presetName: String, with asset: AVAsset, outputFileType: AVFileType?) async -> Bool {
    _ = (presetName, asset, outputFileType)
    return false
  }
  public var supportedFileTypes: [AVFileType] { [] }
  public var compatibleFileTypes: [AVFileType] { get async { [] } }
  public var timeRange: CMTimeRange {
      get { portableTimeRange }
      set { portableTimeRange = newValue }
    }
  public var maxDuration: CMTime { .zero }
  public var estimatedOutputFileLength: Int64 { 0 }
  public var fileLengthLimit: Int64 {
      get { portableFileLengthLimit }
      set { portableFileLengthLimit = newValue }
    }
  public var estimatedMaximumDuration: CMTime { get async throws { .zero } }
  public var estimatedOutputFileLengthInBytes: Int64 { get async throws { 0 } }
  public var metadata: [AVMetadataItem]? {
      get { portableMetadata }
      set { portableMetadata = newValue }
    }
  public var metadataItemFilter: AVMetadataItemFilter? {
      get { portableMetadataItemFilter }
      set { portableMetadataItemFilter = newValue }
    }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { portableAudioTimePitchAlgorithm }
      set { portableAudioTimePitchAlgorithm = newValue }
    }
  public var audioMix: AVAudioMix? {
      get { portableAudioMix }
      set { portableAudioMix = newValue }
    }
  public var videoComposition: AVVideoComposition? {
      get { portableVideoComposition }
      set { portableVideoComposition = newValue }
    }
  public var customVideoCompositor: (any AVVideoCompositing)? { nil }
  public var audioTrackGroupHandling: AVAssetTrackGroupOutputHandling {
      get { portableAudioTrackGroupHandling }
      set { portableAudioTrackGroupHandling = newValue }
    }
  public var canPerformMultiplePassesOverSourceMediaData: Bool {
      get { portableCanPerformMultiplePassesOverSourceMediaData }
      set { portableCanPerformMultiplePassesOverSourceMediaData = newValue }
    }
  public var directoryForTemporaryFiles: URL? {
      get { portableDirectoryForTemporaryFiles }
      set { portableDirectoryForTemporaryFiles = newValue }
    }
}

extension AVAssetImageGenerator {
  public struct ApertureMode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let cleanAperture = ApertureMode(rawValue: "cleanAperture")
    public static let productionAperture = ApertureMode(rawValue: "productionAperture")
    public static let encodedPixels = ApertureMode(rawValue: "encodedPixels")
  }
  public struct DynamicRangePolicy: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let forceSDR = DynamicRangePolicy(rawValue: "forceSDR")
    public static let matchSource = DynamicRangePolicy(rawValue: "matchSource")
  }
  public struct Images: Sendable {
    public init() {}
    public func makeAsyncIterator() -> AVAssetImageGenerator.Images { AVAssetImageGenerator.Images() }
    public mutating func next() async -> AVAssetImageGenerator.Images.Element? { nil }
    public typealias AsyncIterator = AVAssetImageGenerator.Images
    public enum Element {
      case success(requestedTime: CMTime, image: CGImage, actualTime: CMTime)
      case failure(requestedTime: CMTime, error: any Error)
    }
  }
  public enum Result: Int, Hashable, Sendable {
    case succeeded = 0
    case failed = 1
    case cancelled = 2
  }
  public func image(at time: CMTime) async throws -> (image: CGImage, actualTime: CMTime) {
    throw AVError(.noImageAtTime, userInfo: [AVErrorTimeKey: time])
  }
  public var maximumSize: CGSize {
      get { .zero }
      set { _ = newValue }
    }
  public var apertureMode: AVAssetImageGenerator.ApertureMode? {
      get { nil }
      set { _ = newValue }
    }
  public var dynamicRangePolicy: AVAssetImageGenerator.DynamicRangePolicy {
      get { AVAssetImageGenerator.DynamicRangePolicy(rawValue: "") }
      set { _ = newValue }
    }
  public var videoComposition: AVVideoComposition? {
      get { nil }
      set { _ = newValue }
    }
  public var customVideoCompositor: (any AVVideoCompositing)? { nil }
  public var requestedTimeToleranceBefore: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var requestedTimeToleranceAfter: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public func copyCGImage(at requestedTime: CMTime, actualTime: UnsafeMutablePointer<CMTime>?) throws -> CGImage {
    actualTime?.pointee = .invalid
    throw AVError(.noImageAtTime, userInfo: [AVErrorTimeKey: requestedTime])
  }
  public func generateCGImagesAsynchronously(forTimes requestedTimes: [NSValue], completionHandler handler: @escaping AVAssetImageGeneratorCompletionHandler) {
    for value in requestedTimes {
      let time = avTime(from: value)
      handler(time, nil, .invalid, .failed, AVError(.noImageAtTime, userInfo: [AVErrorTimeKey: time]))
    }
  }
  public func cancelAllCGImageGeneration() {}
}

open class AVAssetPlaybackAssistant: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(asset: AVAsset) { self.init() }
  public var playbackConfigurationOptions: [AVAssetPlaybackConfigurationOption] { get async { [] } }
}

public struct AVAssetPlaybackConfigurationOption: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let stereoVideo = AVAssetPlaybackConfigurationOption(rawValue: "stereoVideo")
  public static let stereoMultiviewVideo = AVAssetPlaybackConfigurationOption(rawValue: "stereoMultiviewVideo")
  public static let spatialVideo = AVAssetPlaybackConfigurationOption(rawValue: "spatialVideo")
  public static let nonRectilinearProjection = AVAssetPlaybackConfigurationOption(rawValue: "nonRectilinearProjection")
}

open class AVAssetReader: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case reading = 1
    case completed = 2
    case failed = 3
    case cancelled = 4
  }
  private let stateLock = NSLock()
  private var storedStatus = Status.unknown
  private var storedError: (any Error)?
  private var storedAsset = AVAsset()
  private var storedOutputs: [AVAssetReaderOutput] = []
  private var storedTimeRange = CMTimeRange.zero
  public func start() throws {
    stateLock.lock()
    storedStatus = .failed
    storedError = AVError(.decoderNotFound)
    stateLock.unlock()
    throw AVError(.decoderNotFound)
  }
  public convenience init(asset: AVAsset) throws {
    self.init()
    storedAsset = asset
  }
  public var asset: AVAsset { storedAsset }
  public var status: AVAssetReader.Status { stateLock.withLock { storedStatus } }
  public var error: (any Error)? { stateLock.withLock { storedError } }
  public var timeRange: CMTimeRange {
      get { storedTimeRange }
      set { storedTimeRange = newValue }
    }
  public var outputs: [AVAssetReaderOutput] { stateLock.withLock { storedOutputs } }
  public func canAdd(_ output: AVAssetReaderOutput) -> Bool {
    stateLock.withLock { storedStatus == .unknown }
  }
  public func add(_ output: AVAssetReaderOutput) {
    guard canAdd(output) else { return }
    stateLock.withLock { storedOutputs.append(output) }
  }
  public func startReading() -> Bool {
    stateLock.lock()
    storedStatus = .failed
    storedError = AVError(.decoderNotFound)
    stateLock.unlock()
    return false
  }
  public func cancelReading() {
    stateLock.withLock { storedStatus = .cancelled }
  }
}

open class AVAssetReaderAudioMixOutput: AVAssetReaderOutput, @unchecked Sendable {
  private var storedTracks: [AVAssetTrack] = []
  private var storedSettings: [String : Any]?
  private var storedMix: AVAudioMix?
  private var storedPitch = AVAudioTimePitchAlgorithm(rawValue: "")
  public override init() { super.init() }
  public convenience init(audioTracks: [AVAssetTrack], audioSettings: [String : Any]?) {
    self.init()
    storedTracks = audioTracks
    storedSettings = audioSettings
    storedMediaType = .audio
  }
  public var audioTracks: [AVAssetTrack] { storedTracks }
  public var audioSettings: [String : Any]? { storedSettings }
  public var audioMix: AVAudioMix? {
      get { storedMix }
      set { storedMix = newValue }
    }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { storedPitch }
      set { storedPitch = newValue }
    }
}

public protocol AVAssetReaderCaptionValidationHandling : AnyObject {
  func captionAdaptor(_ adaptor: AVAssetReaderOutputCaptionAdaptor, didVendCaption caption: AVCaption, skippingUnsupportedSourceSyntaxElements syntaxElements: [String])
}

open class AVAssetReaderOutput: NSObject, @unchecked Sendable {
  var storedMediaType = AVMediaType(rawValue: "")
  private var storedAlwaysCopiesSampleData = true
  private var storedSupportsRandomAccess = false
  private var storedConfigurationFinal = false
  private var storedReadingRanges: [NSValue] = []
  public override init() { super.init() }
  open class Provider<Payload: AVAssetReaderOutput.SupportedPayload>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func next() async throws -> Payload? { return nil }
    public func captionsNotPresentInPreviousGroups(in captionGroup: AVCaptionGroup) -> [AVCaption] { [] }
  }
  open class RandomAccessController: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func resetForReading(timeRanges: [CMTimeRange]) { _ = timeRanges }
    public func markConfigurationAsFinal() {}
  }
  public protocol SupportedPayload {
  }
  public var mediaType: AVMediaType { storedMediaType }
  public var alwaysCopiesSampleData: Bool {
      get { storedAlwaysCopiesSampleData }
      set { storedAlwaysCopiesSampleData = newValue }
    }
  public func copyNextSampleBuffer() -> CMSampleBuffer? { nil }
  public var supportsRandomAccess: Bool {
      get { storedSupportsRandomAccess }
      set { storedSupportsRandomAccess = newValue }
    }
  public func reset(forReadingTimeRanges timeRanges: [NSValue]) {
    storedReadingRanges = timeRanges
  }
  public func markConfigurationAsFinal() { storedConfigurationFinal = true }
}

open class AVAssetReaderOutputCaptionAdaptor: NSObject, @unchecked Sendable {
  private var storedTrackOutput = AVAssetReaderTrackOutput()
  weak var storedValidationDelegate: (any AVAssetReaderCaptionValidationHandling)?
  public override init() { super.init() }
  public convenience init(assetReaderTrackOutput trackOutput: AVAssetReaderTrackOutput) {
    self.init()
    storedTrackOutput = trackOutput
  }
  public var assetReaderTrackOutput: AVAssetReaderTrackOutput { storedTrackOutput }
  public func nextCaptionGroup() -> AVCaptionGroup? { nil }
  public func captionsNotPresentInPreviousGroups(in captionGroup: AVCaptionGroup) -> [AVCaption] {
    _ = captionGroup
    return []
  }
  public var validationDelegate: (any AVAssetReaderCaptionValidationHandling)? {
      get { storedValidationDelegate }
      set { storedValidationDelegate = newValue }
    }
}

open class AVAssetReaderOutputMetadataAdaptor: NSObject, @unchecked Sendable {
  private var storedTrackOutput = AVAssetReaderTrackOutput()
  public override init() { super.init() }
  public convenience init(assetReaderTrackOutput trackOutput: AVAssetReaderTrackOutput) {
    self.init()
    storedTrackOutput = trackOutput
  }
  public var assetReaderTrackOutput: AVAssetReaderTrackOutput { storedTrackOutput }
  public func nextTimedMetadataGroup() -> AVTimedMetadataGroup? { nil }
}

open class AVAssetReaderSampleReferenceOutput: AVAssetReaderOutput, @unchecked Sendable {
  private var storedTrack = AVAssetTrack()
  public override init() { super.init() }
  public convenience init(track: AVAssetTrack) {
    self.init()
    storedTrack = track
    storedMediaType = track.mediaType
  }
  public var track: AVAssetTrack { storedTrack }
}

open class AVAssetReaderTrackOutput: AVAssetReaderOutput, @unchecked Sendable {
  private var storedTrack = AVAssetTrack()
  private var storedSettings: [String : Any]?
  private var storedPitch = AVAudioTimePitchAlgorithm(rawValue: "")
  public override init() { super.init() }
  public convenience init(track: AVAssetTrack, outputSettings: [String : Any]?) {
    self.init()
    storedTrack = track
    storedSettings = outputSettings
    storedMediaType = track.mediaType
  }
  public var track: AVAssetTrack { storedTrack }
  public var outputSettings: [String : Any]? { storedSettings }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { storedPitch }
      set { storedPitch = newValue }
    }
}

open class AVAssetReaderVideoCompositionOutput: AVAssetReaderOutput, @unchecked Sendable {
  private var storedTracks: [AVAssetTrack] = []
  private var storedSettings: [String : Any]?
  private var storedComposition: AVVideoComposition?
  public override init() { super.init() }
  public convenience init(videoTracks: [AVAssetTrack], videoSettings: [String : Any]?) {
    self.init()
    storedTracks = videoTracks
    storedSettings = videoSettings
    storedMediaType = .video
  }
  public var videoTracks: [AVAssetTrack] { storedTracks }
  public var videoSettings: [String : Any]? { storedSettings }
  public var videoComposition: AVVideoComposition? {
      get { storedComposition }
      set { storedComposition = newValue }
    }
  public var customVideoCompositor: (any AVVideoCompositing)? { nil }
}

public struct AVAssetReferenceRestrictions: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let forbidRemoteReferenceToLocal = AVAssetReferenceRestrictions(rawValue: 1 << 0)
  public static let forbidLocalReferenceToRemote = AVAssetReferenceRestrictions(rawValue: 1 << 1)
  public static let forbidCrossSiteReference = AVAssetReferenceRestrictions(rawValue: 1 << 2)
  public static let forbidLocalReferenceToLocal = AVAssetReferenceRestrictions(rawValue: 1 << 3)
  public static let forbidAll = AVAssetReferenceRestrictions(rawValue: 1 << 4)
  public static let defaultPolicy = AVAssetReferenceRestrictions(rawValue: 1 << 5)
}

open class AVAssetResourceLoader: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func setDelegate(_ delegate: (any AVAssetResourceLoaderDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public var delegate: (any AVAssetResourceLoaderDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
  public var preloadsEligibleContentKeys: Bool {
      get { false }
      set { _ = newValue }
    }
  public var sendsCommonMediaClientDataAsHTTPHeaders: Bool {
      get { false }
      set { _ = newValue }
    }
}

public protocol AVAssetResourceLoaderDelegate : AnyObject {
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest)
}

open class AVAssetResourceLoadingContentInformationRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var contentType: String? {
      get { nil }
      set { _ = newValue }
    }
  public var allowedContentTypes: [String]? { nil }
  public var contentLength: Int64 {
      get { 0 }
      set { _ = newValue }
    }
  public var isByteRangeAccessSupported: Bool {
      get { false }
      set { _ = newValue }
    }
  public var renewalDate: Date? {
      get { nil }
      set { _ = newValue }
    }
  public var isEntireLengthAvailableOnDemand: Bool {
      get { false }
      set { _ = newValue }
    }
}

open class AVAssetResourceLoadingDataRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var requestedOffset: Int64 { 0 }
  public var requestedLength: Int { 0 }
  public var requestsAllDataToEndOfResource: Bool { false }
  public var currentOffset: Int64 { 0 }
  public func respond(with data: Data) {}
}

open class AVAssetResourceLoadingRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var isFinished: Bool { false }
  public var isCancelled: Bool { false }
  public var contentInformationRequest: AVAssetResourceLoadingContentInformationRequest? { nil }
  public var dataRequest: AVAssetResourceLoadingDataRequest? { nil }
  public var requestor: AVAssetResourceLoadingRequestor { AVAssetResourceLoadingRequestor() }
  public func finishLoading() {}
  public func finishLoading(with error: (any Error)?) {}
  public func streamingContentKeyRequestData(forApp appIdentifier: Data, contentIdentifier: Data, options: [String : Any]? = nil) throws -> Data { return .init() }
  public func persistentContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]? = nil) throws -> Data { return .init() }
}

open class AVAssetResourceLoadingRequestor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var providesExpiredSessionReports: Bool { false }
}

open class AVAssetResourceRenewalRequest: AVAssetResourceLoadingRequest, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVAssetSegmentReport: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var segmentType: AVAssetSegmentType { AVAssetSegmentType(rawValue: 0)! }
  public var trackReports: [AVAssetSegmentTrackReport] { [] }
}

open class AVAssetSegmentReportSampleInformation: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var presentationTimeStamp: CMTime { .zero }
  public var offset: Int { 0 }
  public var length: Int { 0 }
  public var isSyncSample: Bool { false }
}

open class AVAssetSegmentTrackReport: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var trackID: CMPersistentTrackID { 0 }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var earliestPresentationTimeStamp: CMTime { .zero }
  public var duration: CMTime { .zero }
  public var firstVideoSampleInformation: AVAssetSegmentReportSampleInformation? { nil }
}

public enum AVAssetSegmentType: Int, Hashable, Sendable {
  case initialization = 0
  case separable = 1
}

open class AVAssetTrack: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  weak var portableAsset: AVAsset?
  var portableRecord = AVLocalMediaTrack()

  convenience init(portable record: AVLocalMediaTrack, asset: AVAsset) {
    self.init()
    portableAsset = asset
    portableRecord = record
  }

  public struct AssociationType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let audioFallback = AssociationType(rawValue: "audioFallback")
    public static let chapterList = AssociationType(rawValue: "chapterList")
    public static let forcedSubtitlesOnly = AssociationType(rawValue: "forcedSubtitlesOnly")
    public static let selectionFollower = AssociationType(rawValue: "selectionFollower")
    public static let timecode = AssociationType(rawValue: "timecode")
    public static let metadataReferent = AssociationType(rawValue: "metadataReferent")
    public static let renderMetadataSource = AssociationType(rawValue: "renderMetadataSource")
  }
  public var asset: AVAsset? { portableAsset }
  public var trackID: CMPersistentTrackID { portableRecord.trackID }
  public var mediaType: AVMediaType { portableRecord.mediaType }
  public var formatDescriptions: [Any] { [] }
  public var isPlayable: Bool { false }
  public var isDecodable: Bool { false }
  public var isEnabled: Bool { portableRecord.isEnabled }
  public var isSelfContained: Bool { portableRecord.isSelfContained }
  public var totalSampleDataLength: Int64 { portableRecord.totalSampleDataLength }
  public func hasMediaCharacteristic(_ mediaCharacteristic: AVMediaCharacteristic) -> Bool {
    switch mediaCharacteristic {
    case .visual: return mediaType == .video
    case .audible: return mediaType == .audio
    case .legible:
      return mediaType == .text || mediaType == .subtitle || mediaType == .closedCaption
    case .frameBased: return mediaType == .video
    default: return false
    }
  }
  public var timeRange: CMTimeRange {
    let duration = portableRecord.duration.isValid ? portableRecord.duration : .zero
    return CMTimeRange(start: .zero, duration: duration)
  }
  public var naturalTimeScale: CMTimeScale { portableRecord.mediaTimescale }
  public var estimatedDataRate: Float {
    let seconds = portableRecord.duration.seconds
    guard seconds > 0, portableRecord.totalSampleDataLength > 0 else { return 0 }
    return Float(Double(portableRecord.totalSampleDataLength) * 8.0 / seconds)
  }
  public var languageCode: String? { portableRecord.languageCode }
  public var extendedLanguageTag: String? { portableRecord.languageCode }
  public var naturalSize: CGSize { portableRecord.naturalSize }
  public var preferredTransform: CGAffineTransform { portableRecord.preferredTransform }
  public var preferredVolume: Float { portableRecord.preferredVolume }
  public var hasAudioSampleDependencies: Bool { false }
  public var nominalFrameRate: Float { portableRecord.nominalFrameRate }
  public var minFrameDuration: CMTime {
    portableRecord.minFrameDuration.isValid ? portableRecord.minFrameDuration : .zero
  }
  public var requiresFrameReordering: Bool { false }
  public var segments: [AVAssetTrackSegment] { [] }
  public func segment(forTrackTime trackTime: CMTime) -> AVAssetTrackSegment? { nil }
  public func loadSegment(forTrackTime trackTime: CMTime) async throws -> AVAssetTrackSegment? { return nil }
  public func samplePresentationTime(forTrackTime trackTime: CMTime) -> CMTime {
    // Unedited local tracks have identity mapping; no elst is parsed yet.
    trackTime.isValid ? trackTime : .invalid
  }
  public func loadSamplePresentationTime(forTrackTime trackTime: CMTime) async throws -> CMTime { return .zero }
  public var commonMetadata: [AVMetadataItem] { [] }
  public var metadata: [AVMetadataItem] { [] }
  public var availableMetadataFormats: [AVMetadataFormat] { [] }
  public func metadata(forFormat format: AVMetadataFormat) -> [AVMetadataItem] { [] }
  public func loadMetadata(for format: AVMetadataFormat) async throws -> [AVMetadataItem] { return [] }
  public var availableTrackAssociationTypes: [AVAssetTrack.AssociationType] { [] }
  public func associatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) -> [AVAssetTrack] { [] }
  public func loadAssociatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) async throws -> [AVAssetTrack] { return [] }
  public var canProvideSampleCursors: Bool { false }
  public func makeSampleCursor(presentationTimeStamp: CMTime) -> AVSampleCursor? { nil }
  public func makeSampleCursorAtFirstSampleInDecodeOrder() -> AVSampleCursor? { nil }
  public func makeSampleCursorAtLastSampleInDecodeOrder() -> AVSampleCursor? { nil }
}

open class AVAssetTrackGroup: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var trackIDs: [NSNumber] { [] }
}

public struct AVAssetTrackGroupOutputHandling: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let preserveAlternateTracks = AVAssetTrackGroupOutputHandling(rawValue: 1 << 0)
}

open class AVAssetTrackSegment: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var timeMapping: CMTimeMapping { CMTimeMapping() }
  public var isEmpty: Bool { false }
}

open class AVAssetVariant: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class AudioAttributes: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    open class RenditionSpecificAttributes: NSObject, @unchecked Sendable {
      public override init() { super.init() }
      public var channelCount: Int? { nil }
      public var isBinaural: Bool { false }
      public var isImmersive: Bool { false }
      public var isDownmix: Bool { false }
    }
    public var formatIDs: [AudioFormatID] { [] }
    public func renditionSpecificAttributes(for mediaSelectionOption: AVMediaSelectionOption) -> AVAssetVariant.AudioAttributes.RenditionSpecificAttributes? { nil }
  }
  open class VideoAttributes: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    open class LayoutAttributes: NSObject, @unchecked Sendable {
      public override init() { super.init() }
      public var stereoViewComponents: CMStereoViewComponents { [] }
      public var projectionType: CMProjectionType { CMProjectionType(rawValue: 0) }
    }
    public var nominalFrameRate: Double? { nil }
    public var codecTypes: [CMVideoCodecType] { [] }
    public var videoRange: AVVideoRange { AVVideoRange(rawValue: "") }
    public var presentationSize: CGSize { .zero }
    public var videoLayoutAttributes: [AVAssetVariant.VideoAttributes.LayoutAttributes] { [] }
  }
  public var peakBitRate: Double? { nil }
  public var averageBitRate: Double? { nil }
  public var videoAttributes: AVAssetVariant.VideoAttributes? { nil }
  public var audioAttributes: AVAssetVariant.AudioAttributes? { nil }
  public var url: URL { URL(fileURLWithPath: "/dev/null") }
}

open class AVAssetVariantQualifier: NSObject, @unchecked Sendable {
  private var storedPredicate: NSPredicate?
  private var storedVariant: AVAssetVariant?
  public override init() { super.init() }
  public convenience init(predicate: NSPredicate) {
    self.init()
    storedPredicate = predicate
  }
  public convenience init(variant: AVAssetVariant) {
    self.init()
    storedVariant = variant
  }
  public var portablePredicate: NSPredicate? { storedPredicate }
  public var portableVariant: AVAssetVariant? { storedVariant }
}

open class AVAssetWriter: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case writing = 1
    case completed = 2
    case failed = 3
    case cancelled = 4
  }
  private let stateLock = NSLock()
  private var storedStatus = Status.unknown
  private var storedError: (any Error)?
  private var storedURL = URL(fileURLWithPath: "/dev/null")
  private var storedFileType = AVFileType(rawValue: "")
  private var storedInputs: [AVAssetWriterInput] = []
  private var storedMetadata: [AVMetadataItem] = []
  private var storedShouldOptimize = false
  private var storedTempDirectory: URL?
  private var storedMovieFragmentInterval = CMTime.zero
  private var storedInitialMovieFragmentInterval = CMTime.zero
  private var storedInitialMovieFragmentSequenceNumber = 0
  private var storedProducesCombinableFragments = false
  private var storedOverallDurationHint = CMTime.zero
  private var storedMovieTimeScale: CMTimeScale = 0
  private var storedInputGroups: [AVAssetWriterInputGroup] = []
  private var storedPreferredOutputSegmentInterval = CMTime.zero
  private var storedInitialSegmentStartTime = CMTime.zero
  private var storedOutputFileTypeProfile: AVFileTypeProfile?
  private weak var storedDelegate: (any AVAssetWriterDelegate)?
  private var storedDidFlushSegment = false
  public func start() throws {
    stateLock.lock()
    storedStatus = .failed
    storedError = AVError(.encoderNotFound)
    stateLock.unlock()
    throw AVError(.encoderNotFound)
  }
  public convenience init(url outputURL: URL, fileType outputFileType: AVFileType) throws {
    self.init()
    storedURL = outputURL
    storedFileType = outputFileType
  }
  public convenience init(outputURL: URL, fileType outputFileType: AVFileType) throws {
    try self.init(url: outputURL, fileType: outputFileType)
  }
  public convenience init(URL outputURL: URL, fileType outputFileType: AVFileType) throws {
    try self.init(url: outputURL, fileType: outputFileType)
  }
  public var outputURL: URL { storedURL }
  public var outputFileType: AVFileType { storedFileType }
  public var availableMediaTypes: [AVMediaType] { [.video, .audio] }
  public var status: AVAssetWriter.Status { stateLock.withLock { storedStatus } }
  public var error: (any Error)? { stateLock.withLock { storedError } }
  public var metadata: [AVMetadataItem] {
      get { storedMetadata }
      set { storedMetadata = newValue }
    }
  public var shouldOptimizeForNetworkUse: Bool {
      get { storedShouldOptimize }
      set { storedShouldOptimize = newValue }
    }
  public var directoryForTemporaryFiles: URL? {
      get { storedTempDirectory }
      set { storedTempDirectory = newValue }
    }
  public var inputs: [AVAssetWriterInput] { stateLock.withLock { storedInputs } }
  public func canApply(outputSettings: [String : Any]?, forMediaType mediaType: AVMediaType) -> Bool {
    _ = (outputSettings, mediaType)
    return false
  }
  public func canAdd(_ input: AVAssetWriterInput) -> Bool {
    stateLock.withLock {
      storedStatus == .unknown && (input.mediaType == .video || input.mediaType == .audio)
    }
  }
  public func add(_ input: AVAssetWriterInput) {
    guard canAdd(input) else { return }
    stateLock.withLock { storedInputs.append(input) }
  }
  public func startWriting() -> Bool {
    stateLock.lock()
    storedStatus = .failed
    storedError = AVError(.encoderNotFound)
    stateLock.unlock()
    return false
  }
  public func startSession(atSourceTime startTime: CMTime) { _ = startTime }
  public func endSession(atSourceTime endTime: CMTime) { _ = endTime }
  public func cancelWriting() {
    stateLock.withLock { storedStatus = .cancelled }
  }
  public func finishWriting() async {}
  public func finishWriting(completionHandler handler: @escaping () -> Void) {
    stateLock.lock()
    storedStatus = .failed
    storedError = AVError(.encoderNotFound)
    stateLock.unlock()
    handler()
  }
  public var movieFragmentInterval: CMTime {
      get { storedMovieFragmentInterval }
      set { storedMovieFragmentInterval = newValue }
    }
  public var initialMovieFragmentInterval: CMTime {
      get { storedInitialMovieFragmentInterval }
      set { storedInitialMovieFragmentInterval = newValue }
    }
  public var initialMovieFragmentSequenceNumber: Int {
      get { storedInitialMovieFragmentSequenceNumber }
      set { storedInitialMovieFragmentSequenceNumber = newValue }
    }
  public var producesCombinableFragments: Bool {
      get { storedProducesCombinableFragments }
      set { storedProducesCombinableFragments = newValue }
    }
  public var overallDurationHint: CMTime {
      get { storedOverallDurationHint }
      set { storedOverallDurationHint = newValue }
    }
  public var movieTimeScale: CMTimeScale {
      get { storedMovieTimeScale }
      set { storedMovieTimeScale = newValue }
    }
  public func canAdd(_ inputGroup: AVAssetWriterInputGroup) -> Bool {
    stateLock.withLock { storedStatus == .unknown }
  }
  public func add(_ inputGroup: AVAssetWriterInputGroup) {
    guard canAdd(inputGroup) else { return }
    stateLock.withLock { storedInputGroups.append(inputGroup) }
  }
  public var inputGroups: [AVAssetWriterInputGroup] { stateLock.withLock { storedInputGroups } }
  public var preferredOutputSegmentInterval: CMTime {
      get { storedPreferredOutputSegmentInterval }
      set { storedPreferredOutputSegmentInterval = newValue }
    }
  public var initialSegmentStartTime: CMTime {
      get { storedInitialSegmentStartTime }
      set { storedInitialSegmentStartTime = newValue }
    }
  public var outputFileTypeProfile: AVFileTypeProfile? {
      get { storedOutputFileTypeProfile }
      set { storedOutputFileTypeProfile = newValue }
    }
  public var delegate: (any AVAssetWriterDelegate)? {
      get { storedDelegate }
      set { storedDelegate = newValue }
    }
  public func flushSegment() { storedDidFlushSegment = true }
}

public protocol AVAssetWriterDelegate : AnyObject, Sendable {
  func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?)
  func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType)
}

extension AVAssetWriterDelegate {
  public func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
    _ = (writer, segmentData, segmentType, segmentReport)
  }
  public func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType) {
    _ = (writer, segmentData, segmentType)
  }
}

open class AVAssetWriterInput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class CaptionReceiver: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func append(_ caption: AVCaption) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func append(_ captionGroup: AVCaptionGroup) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func appendImmediately(_ caption: AVCaption) throws -> Bool { return false }
    public func appendImmediately(_ captionGroup: AVCaptionGroup) throws -> Bool { return false }
    public func finish() {}
  }
  public struct MediaDataLocation: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let interleavedWithMainMediaData = MediaDataLocation(rawValue: "interleavedWithMainMediaData")
    public static let beforeMainMediaDataNotInterleaved = MediaDataLocation(rawValue: "beforeMainMediaDataNotInterleaved")
    public static let sparselyInterleavedWithMainMediaData = MediaDataLocation(rawValue: "sparselyInterleavedWithMainMediaData")
  }
  open class MetadataReceiver: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func append(_ timedMetadataGroup: AVTimedMetadataGroup) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func appendImmediately(_ timedMetadataGroup: AVTimedMetadataGroup) throws -> Bool { return false }
    public func finish() {}
  }
  open class MultiPassController: NSObject, @unchecked Sendable {
    public override init() { super.init() }
  }
  open class PixelBufferReceiver: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var sourcePixelBufferAttributes: CVPixelBufferCreationAttributes? { nil }
    public func append(_ pixelBuffer: CVReadOnlyPixelBuffer, with presentationTime: CMTime) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func appendImmediately(_ pixelBuffer: CVReadOnlyPixelBuffer, with presentationTime: CMTime) throws -> Bool { return false }
    public func finish() {}
  }
  open class SampleBufferReceiver: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func append(_ sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func appendImmediately(_ sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>) throws -> Bool { return false }
    public func finish() {}
  }
  open class TaggedPixelBufferGroupReceiver: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var sourcePixelBufferAttributes: CVPixelBufferCreationAttributes? { nil }
    public func append(_ taggedPixelBufferGroup: [CMTaggedDynamicBuffer], with presentationTime: CMTime) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public func appendImmediately(_ taggedPixelBufferGroup: [CMTaggedDynamicBuffer], with presentationTime: CMTime) throws -> Bool { return false }
    public func finish() {}
  }
  private var storedMediaType = AVMediaType(rawValue: "")
  private var storedOutputSettings: [String : Any]?
  private var storedSourceFormatHint: CMFormatDescription?
  private var storedMetadata: [AVMetadataItem] = []
  private var storedExpectsMediaDataInRealTime = false
  private var storedLanguageCode: String?
  private var storedExtendedLanguageTag: String?
  private var storedNaturalSize = CGSize.zero
  private var storedTransform = CGAffineTransform.identity
  private var storedPreferredVolume: Float = 1
  private var storedMarksOutputTrackAsEnabled = true
  private var storedMediaTimeScale: CMTimeScale = 0
  private var storedPreferredMediaChunkDuration = CMTime.zero
  private var storedPreferredMediaChunkAlignment = 0
  private var storedSampleReferenceBaseURL: URL?
  private var storedMediaDataLocation = AVAssetWriterInput.MediaDataLocation.interleavedWithMainMediaData
  private var storedPerformsMultiPassEncodingIfSupported = false
  private var storedFinished = false
  private var storedAssociations: [(AVAssetWriterInput, String)] = []
  public convenience init(mediaType: AVMediaType, outputSettings: [String : Any]?) {
    self.init()
    storedMediaType = mediaType
    storedOutputSettings = outputSettings
  }
  public convenience init(mediaType: AVMediaType, outputSettings: [String : Any]?, sourceFormatHint: CMFormatDescription?) {
    self.init(mediaType: mediaType, outputSettings: outputSettings)
    storedSourceFormatHint = sourceFormatHint
  }
  public var mediaType: AVMediaType { storedMediaType }
  public var outputSettings: [String : Any]? { storedOutputSettings }
  public var sourceFormatHint: CMFormatDescription? { storedSourceFormatHint }
  public var metadata: [AVMetadataItem] {
      get { storedMetadata }
      set { storedMetadata = newValue }
    }
  public var isReadyForMoreMediaData: Bool { false }
  public var expectsMediaDataInRealTime: Bool {
      get { storedExpectsMediaDataInRealTime }
      set { storedExpectsMediaDataInRealTime = newValue }
    }
  public func append(_ sampleBuffer: CMSampleBuffer) -> Bool {
    _ = sampleBuffer
    return false
  }
  public func markAsFinished() { storedFinished = true }
  public var languageCode: String? {
      get { storedLanguageCode }
      set { storedLanguageCode = newValue }
    }
  public var extendedLanguageTag: String? {
      get { storedExtendedLanguageTag }
      set { storedExtendedLanguageTag = newValue }
    }
  public var naturalSize: CGSize {
      get { storedNaturalSize }
      set { storedNaturalSize = newValue }
    }
  public var transform: CGAffineTransform {
      get { storedTransform }
      set { storedTransform = newValue }
    }
  public var preferredVolume: Float {
      get { storedPreferredVolume }
      set { storedPreferredVolume = newValue }
    }
  public var marksOutputTrackAsEnabled: Bool {
      get { storedMarksOutputTrackAsEnabled }
      set { storedMarksOutputTrackAsEnabled = newValue }
    }
  public var mediaTimeScale: CMTimeScale {
      get { storedMediaTimeScale }
      set { storedMediaTimeScale = newValue }
    }
  public var preferredMediaChunkDuration: CMTime {
      get { storedPreferredMediaChunkDuration }
      set { storedPreferredMediaChunkDuration = newValue }
    }
  public var preferredMediaChunkAlignment: Int {
      get { storedPreferredMediaChunkAlignment }
      set { storedPreferredMediaChunkAlignment = newValue }
    }
  public var sampleReferenceBaseURL: URL? {
      get { storedSampleReferenceBaseURL }
      set { storedSampleReferenceBaseURL = newValue }
    }
  public var mediaDataLocation: AVAssetWriterInput.MediaDataLocation {
      get { storedMediaDataLocation }
      set { storedMediaDataLocation = newValue }
    }
  public func canAddTrackAssociation(withTrackOf input: AVAssetWriterInput, type trackAssociationType: String) -> Bool {
    _ = (input, trackAssociationType)
    return false
  }
  public func addTrackAssociation(withTrackOf input: AVAssetWriterInput, type trackAssociationType: String) {
    storedAssociations.append((input, trackAssociationType))
  }
  public var performsMultiPassEncodingIfSupported: Bool {
      get { storedPerformsMultiPassEncodingIfSupported }
      set { storedPerformsMultiPassEncodingIfSupported = newValue }
    }
  public var canPerformMultiplePasses: Bool { false }
  public var currentPassDescription: AVAssetWriterInputPassDescription? { nil }
  public func markCurrentPassAsFinished() { storedFinished = true }
}

open class AVAssetWriterInputCaptionAdaptor: NSObject, @unchecked Sendable {
  private var storedInput = AVAssetWriterInput()
  public override init() { super.init() }
  public convenience init(assetWriterInput input: AVAssetWriterInput) {
    self.init()
    storedInput = input
  }
  public var assetWriterInput: AVAssetWriterInput { storedInput }
  public func append(_ caption: AVCaption) -> Bool {
    _ = caption
    return false
  }
  public func append(_ captionGroup: AVCaptionGroup) -> Bool {
    _ = captionGroup
    return false
  }
}

open class AVAssetWriterInputGroup: AVMediaSelectionGroup, @unchecked Sendable {
  private var storedInputs: [AVAssetWriterInput] = []
  private var storedDefault: AVAssetWriterInput?
  public override init() { super.init() }
  public convenience init(inputs: [AVAssetWriterInput], defaultInput: AVAssetWriterInput?) {
    self.init()
    storedInputs = inputs
    storedDefault = defaultInput
  }
  public var inputs: [AVAssetWriterInput] { storedInputs }
  public var defaultInput: AVAssetWriterInput? { storedDefault }
}

open class AVAssetWriterInputMetadataAdaptor: NSObject, @unchecked Sendable {
  private var storedInput = AVAssetWriterInput()
  public override init() { super.init() }
  public convenience init(assetWriterInput input: AVAssetWriterInput) {
    self.init()
    storedInput = input
  }
  public var assetWriterInput: AVAssetWriterInput { storedInput }
  public func append(_ timedMetadataGroup: AVTimedMetadataGroup) -> Bool {
    _ = timedMetadataGroup
    return false
  }
}

open class AVAssetWriterInputPassDescription: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var sourceTimeRanges: [NSValue] { [] }
}

open class AVAssetWriterInputPixelBufferAdaptor: NSObject, @unchecked Sendable {
  private var storedInput = AVAssetWriterInput()
  private var storedAttributes: [String : any Sendable]?
  public override init() { super.init() }
  public convenience init(assetWriterInput input: AVAssetWriterInput, sourcePixelBufferAttributes: [String : Any]? = nil) {
    self.init()
    storedInput = input
    storedAttributes = sourcePixelBufferAttributes
  }
  public var assetWriterInput: AVAssetWriterInput { storedInput }
  public var sourcePixelBufferAttributes: [String : any Sendable]? { storedAttributes }
  public var pixelBufferPool: CVPixelBufferPool? { nil }
  public func append(_ pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool {
    _ = (pixelBuffer, presentationTime)
    return false
  }
}

open class AVAssetWriterInputTaggedPixelBufferGroupAdaptor: NSObject, @unchecked Sendable {
  private var storedInput = AVAssetWriterInput()
  private var storedAttributes: [String : any Sendable]?
  public override init() { super.init() }
  public convenience init(assetWriterInput input: AVAssetWriterInput, sourcePixelBufferAttributes: [String : Any]? = nil) {
    self.init()
    storedInput = input
    storedAttributes = sourcePixelBufferAttributes
  }
  public var assetWriterInput: AVAssetWriterInput { storedInput }
  public var sourcePixelBufferAttributes: [String : any Sendable]? { storedAttributes }
  public var pixelBufferPool: CVPixelBufferPool? { nil }
}

open class AVComposition: AVAsset, @unchecked Sendable {
  var portableURLAssetInitializationOptions: [String: Any] = [:]
  public override init() { super.init() }
  public var urlAssetInitializationOptions: [String : Any] { portableURLAssetInitializationOptions }
  public var naturalSize: CGSize {
    tracks.first(where: { $0.mediaType == .video })?.naturalSize ?? .zero
  }
}

open class AVCompositionTrack: AVAssetTrack, @unchecked Sendable {
  var portableCompositionSegments: [AVCompositionTrackSegment] = []
  var portableFormatDescriptionReplacements: [AVCompositionTrackFormatDescriptionReplacement] = []
  var portableAssociatedTracks: [AVAssetTrack.AssociationType: [AVAssetTrack]] = [:]
  var portableMetadataItems: [AVMetadataItem] = []

  public override init() { super.init() }

  public override var segments: [AVAssetTrackSegment] { portableCompositionSegments }

  public override func segment(forTrackTime trackTime: CMTime) -> AVAssetTrackSegment? {
    portableCompositionSegments.first { $0.timeMapping.target.containsTime(trackTime) }
  }

  public override func samplePresentationTime(forTrackTime trackTime: CMTime) -> CMTime {
    guard let segment = portableCompositionSegments.first(where: { $0.timeMapping.target.containsTime(trackTime) }) else {
      return super.samplePresentationTime(forTrackTime: trackTime)
    }
    if segment.isEmpty { return .invalid }
    let offset = trackTime.seconds - segment.timeMapping.target.start.seconds
    let sourceSeconds = segment.timeMapping.source.start.seconds + offset
    let scale = trackTime.timescale == 0 ? 600 : trackTime.timescale
    return CMTime(seconds: sourceSeconds, preferredTimescale: scale)
  }

  public var formatDescriptionReplacements: [AVCompositionTrackFormatDescriptionReplacement] {
    portableFormatDescriptionReplacements
  }

  public override var metadata: [AVMetadataItem] { portableMetadataItems }
  public override var commonMetadata: [AVMetadataItem] { portableMetadataItems }
  public override func metadata(forFormat format: AVMetadataFormat) -> [AVMetadataItem] {
    _ = format
    return portableMetadataItems
  }
  public override var availableMetadataFormats: [AVMetadataFormat] {
    portableMetadataItems.isEmpty ? [] : [.quickTimeMetadata]
  }
  public override var availableTrackAssociationTypes: [AVAssetTrack.AssociationType] {
    Array(portableAssociatedTracks.keys)
  }
  public override func associatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) -> [AVAssetTrack] {
    portableAssociatedTracks[trackAssociationType] ?? []
  }
}

open class AVCompositionTrackFormatDescriptionReplacement: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  var portableOriginal = CMFormatDescription()
  var portableReplacement = CMFormatDescription()
  public var originalFormatDescription: CMFormatDescription { portableOriginal }
  public var replacementFormatDescription: CMFormatDescription { portableReplacement }
}

open class AVCompositionTrackSegment: AVAssetTrackSegment, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(url URL: URL, trackID: CMPersistentTrackID, sourceTimeRange: CMTimeRange, targetTimeRange: CMTimeRange) {
    self.init()
    portableSourceURL = URL
    portableSourceTrackID = trackID
    portableTimeMapping = CMTimeMapping(source: sourceTimeRange, target: targetTimeRange)
  }
  public convenience init(URL: URL, trackID: CMPersistentTrackID, sourceTimeRange: CMTimeRange, targetTimeRange: CMTimeRange) {
    self.init(url: URL, trackID: trackID, sourceTimeRange: sourceTimeRange, targetTimeRange: targetTimeRange)
  }
  public convenience init(timeRange: CMTimeRange) {
    self.init()
    portableTimeMapping = CMTimeMapping(source: .zero, target: timeRange)
  }
  var portableSourceURL: URL?
  var portableSourceTrackID: CMPersistentTrackID = 0
  var portableTimeMapping = CMTimeMapping()
  public var sourceURL: URL? { portableSourceURL }
  public var sourceTrackID: CMPersistentTrackID { portableSourceTrackID }
  public override var timeMapping: CMTimeMapping { portableTimeMapping }
  public override var isEmpty: Bool { portableSourceURL == nil }
}

public protocol AVFragmentMinding {
  var isAssociatedWithFragmentMinder: Bool { get }
}

open class AVFragmentedAsset: AVURLAsset, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVFragmentedAssetMinder: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(asset: any AVAsset & AVFragmentMinding, mindingInterval: TimeInterval) { self.init() }
  public var mindingInterval: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
  public var assets: [any AVAsset & AVFragmentMinding] { [] }
  public func addFragmentedAsset(_ asset: any AVAsset & AVFragmentMinding) {}
  public func removeFragmentedAsset(_ asset: any AVAsset & AVFragmentMinding) {}
}

open class AVFragmentedAssetTrack: AVAssetTrack, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVFragmentedMovie: AVMovie, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVFragmentedMovieMinder: AVFragmentedAssetMinder, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(movie: AVFragmentedMovie, mindingInterval: TimeInterval) { self.init() }
  public var movies: [AVFragmentedMovie] { [] }
  public func add(_ movie: AVFragmentedMovie) {}
  public func remove(_ movie: AVFragmentedMovie) {}
}

open class AVFragmentedMovieTrack: AVMovieTrack, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableAssetDownloadStorageManagementPolicy: AVAssetDownloadStorageManagementPolicy, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableAudioMix: AVAudioMix, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableAudioMixInputParameters: AVAudioMixInputParameters, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(track: AVAssetTrack?) {
    self.init()
    if let track {
      self.trackID = track.trackID
    }
  }
  public func setVolumeRamp(fromStartVolume startVolume: Float, toEndVolume endVolume: Float, timeRange: CMTimeRange) {
    volumeStart = startVolume
    volumeEnd = endVolume
    volumeRange = timeRange
  }
  public func setVolume(_ volume: Float, at time: CMTime) {
    volumeStart = volume
    volumeEnd = volume
    volumeRange = CMTimeRange(start: time, duration: .zero)
  }
}

open class AVMutableCaption: AVCaption, @unchecked Sendable {
  public override init() { super.init() }
  public func setTextColor(_ textColor: CGColor, in range: NSRange) {}
  public func setBackgroundColor(_ backgroundColor: CGColor, in range: NSRange) {}
  public func setFontWeight(_ fontWeight: AVCaption.FontWeight, in range: NSRange) {}
  public func setFontStyle(_ fontStyle: AVCaption.FontStyle, in range: NSRange) {}
  public func setDecoration(_ decoration: AVCaption.Decoration, in range: NSRange) {}
  public func setTextCombine(_ textCombine: AVCaption.TextCombine, in range: NSRange) {}
  public func setRuby(_ rubyText: AVCaption.Ruby, in range: NSRange) {}
  public func removeTextColor(in range: NSRange) {}
  public func removeBackgroundColor(in range: NSRange) {}
  public func removeFontWeight(in range: NSRange) {}
  public func removeFontStyle(in range: NSRange) {}
  public func removeDecoration(in range: NSRange) {}
  public func removeTextCombine(in range: NSRange) {}
  public func removeRuby(in range: NSRange) {}
}

open class AVMutableCaptionRegion: AVCaptionRegion, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(identifier: String) { self.init() }
}

open class AVMutableComposition: AVComposition, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(urlAssetInitializationOptions URLAssetInitializationOptions: [String : Any]? = nil) {
    self.init()
    portableURLAssetInitializationOptions = URLAssetInitializationOptions ?? [:]
  }
  public func insertTimeRange(_ timeRange: CMTimeRange, of asset: AVAsset, at startTime: CMTime) throws {
    _ = startTime
    for source in asset.tracks {
      let preferred = source.trackID == 0 ? 0 : source.trackID
      guard let dest = addMutableTrack(withMediaType: source.mediaType, preferredTrackID: preferred) else {
        continue
      }
      try dest.insertTimeRange(timeRange, of: source, at: startTime)
    }
  }
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {
    let extra = timeRange.duration.seconds
    guard extra > 0 else { return }
    loadState.lock.lock()
    for track in loadState.storedTracks {
      let current = track.portableRecord.duration
      let base = current.isValid ? current.seconds : 0
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(seconds: base + extra, timescale: scale)
    }
    loadState.lock.unlock()
  }
  public func removeTimeRange(_ timeRange: CMTimeRange) {
    let cut = timeRange.duration.seconds
    guard cut > 0 else { return }
    loadState.lock.lock()
    for track in loadState.storedTracks {
      guard track.portableRecord.duration.isValid else { continue }
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(
        seconds: max(0, track.portableRecord.duration.seconds - cut),
        timescale: scale
      )
    }
    loadState.lock.unlock()
  }
  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {
    let source = timeRange.duration.seconds
    guard source > 0, duration.isValid else { return }
    let factor = duration.seconds / source
    loadState.lock.lock()
    for track in loadState.storedTracks {
      guard track.portableRecord.duration.isValid else { continue }
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(
        seconds: track.portableRecord.duration.seconds * factor,
        timescale: scale
      )
    }
    loadState.lock.unlock()
  }
  public func addMutableTrack(withMediaType mediaType: AVMediaType, preferredTrackID: CMPersistentTrackID) -> AVMutableCompositionTrack? {
    let track = AVMutableCompositionTrack()
    var record = AVLocalMediaTrack()
    record.mediaType = mediaType
    record.trackID = preferredTrackID == 0 ? unusedTrackID() : preferredTrackID
    record.isEnabled = true
    record.isSelfContained = false
    track.portableAsset = self
    track.portableRecord = record
    loadState.lock.lock()
    loadState.storedTracks.append(track)
    loadState.lock.unlock()
    return track
  }
  public func removeTrack(_ track: AVCompositionTrack) {
    loadState.lock.lock()
    loadState.storedTracks.removeAll { $0 === track }
    loadState.lock.unlock()
  }
  public func mutableTrack(compatibleWith track: AVAssetTrack) -> AVMutableCompositionTrack? {
    tracks.compactMap { $0 as? AVMutableCompositionTrack }.first { $0.mediaType == track.mediaType }
  }
}

open class AVMutableCompositionTrack: AVCompositionTrack, @unchecked Sendable {
  public override init() { super.init() }
  var portableSegments: [AVCompositionTrackSegment] {
    get { portableCompositionSegments }
    set { portableCompositionSegments = newValue }
  }
  public override var segments: [AVAssetTrackSegment] { portableCompositionSegments }
  public override var languageCode: String? {
    get { portableRecord.languageCode }
    set { portableRecord.languageCode = newValue }
  }
  public override var extendedLanguageTag: String? {
    get { portableRecord.languageCode }
    set { portableRecord.languageCode = newValue }
  }
  public override var naturalTimeScale: CMTimeScale {
    get { portableRecord.mediaTimescale }
    set { portableRecord.mediaTimescale = newValue }
  }
  public override var isEnabled: Bool {
    get { portableRecord.isEnabled }
    set { portableRecord.isEnabled = newValue }
  }
  public override var preferredTransform: CGAffineTransform {
    get { portableRecord.preferredTransform }
    set { portableRecord.preferredTransform = newValue }
  }
  public override var preferredVolume: Float {
    get { portableRecord.preferredVolume }
    set { portableRecord.preferredVolume = newValue }
  }
  public func insertTimeRange(_ timeRange: CMTimeRange, of track: AVAssetTrack, at startTime: CMTime) throws {
    let segment = AVCompositionTrackSegment(
      url: (track.asset as? AVURLAsset)?.url ?? URL(fileURLWithPath: "/dev/null"),
      trackID: track.trackID,
      sourceTimeRange: timeRange,
      targetTimeRange: CMTimeRange(start: startTime, duration: timeRange.duration)
    )
    portableCompositionSegments.append(segment)
    portableRecord.duration = timeRange.duration
    portableRecord.mediaType = track.mediaType
    portableRecord.naturalSize = track.naturalSize
    portableRecord.preferredTransform = track.preferredTransform
    portableRecord.nominalFrameRate = track.nominalFrameRate
    portableRecord.mediaTimescale = track.naturalTimeScale
    portableRecord.languageCode = track.languageCode
  }
  public func insertTimeRanges(_ timeRanges: [NSValue], of tracks: [AVAssetTrack], at startTime: CMTime) throws {
    guard timeRanges.count == tracks.count else {
      throw AVError(.invalidSourceMedia)
    }
    var cursor = startTime
    for (index, track) in tracks.enumerated() {
      let range = AVCMTimeRangeValue.range(from: timeRanges[index])
      try insertTimeRange(range, of: track, at: cursor)
      cursor = CMTime(
        seconds: cursor.seconds + range.duration.seconds,
        preferredTimescale: cursor.timescale == 0 ? 600 : cursor.timescale
      )
    }
  }
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {
    let extra = timeRange.duration.seconds
    guard extra > 0 else { return }
    let current = portableRecord.duration
    let base = current.isValid ? current.seconds : 0
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    let start = CMTime(seconds: base, preferredTimescale: scale)
    portableCompositionSegments.append(AVCompositionTrackSegment(timeRange: CMTimeRange(start: start, duration: timeRange.duration)))
    portableRecord.duration = AVTimeMath.time(seconds: base + extra, timescale: scale)
  }
  public func removeTimeRange(_ timeRange: CMTimeRange) {
    let cut = timeRange.duration.seconds
    guard cut > 0, portableRecord.duration.isValid else { return }
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    portableRecord.duration = AVTimeMath.time(
      seconds: max(0, portableRecord.duration.seconds - cut),
      timescale: scale
    )
    portableCompositionSegments.removeAll { $0.timeMapping.target.containsTime(timeRange.start) }
  }
  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {
    let source = timeRange.duration.seconds
    guard source > 0, duration.isValid, portableRecord.duration.isValid else { return }
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    portableRecord.duration = AVTimeMath.time(
      seconds: portableRecord.duration.seconds * (duration.seconds / source),
      timescale: scale
    )
  }
  public func validateSegments(_ trackSegments: [AVCompositionTrackSegment]) throws {
    for segment in trackSegments {
      if !segment.timeMapping.target.duration.isValid || segment.timeMapping.target.duration.seconds < 0 {
        throw AVError(.invalidCompositionTrackSegmentDuration)
      }
      if !segment.isEmpty {
        if !segment.timeMapping.source.start.isValid {
          throw AVError(.invalidCompositionTrackSegmentSourceStartTime)
        }
        if !segment.timeMapping.source.duration.isValid || segment.timeMapping.source.duration.seconds < 0 {
          throw AVError(.invalidCompositionTrackSegmentSourceDuration)
        }
      }
    }
    let sorted = trackSegments.sorted {
      $0.timeMapping.target.start.seconds < $1.timeMapping.target.start.seconds
    }
    var end = 0.0
    var seen = false
    for segment in sorted {
      let start = segment.timeMapping.target.start.seconds
      if seen, abs(start - end) > 0.0001 {
        throw AVError(.compositionTrackSegmentsNotContiguous)
      }
      seen = true
      end = start + segment.timeMapping.target.duration.seconds
    }
  }
  public func addTrackAssociation(to compositionTrack: AVCompositionTrack, type trackAssociationType: AVAssetTrack.AssociationType) {
    var current = portableAssociatedTracks[trackAssociationType] ?? []
    current.append(compositionTrack)
    portableAssociatedTracks[trackAssociationType] = current
  }
  public func removeTrackAssociation(to compositionTrack: AVCompositionTrack, type trackAssociationType: AVAssetTrack.AssociationType) {
    portableAssociatedTracks[trackAssociationType]?.removeAll { $0 === compositionTrack }
  }
  public func replaceFormatDescription(_ originalFormatDescription: CMFormatDescription, with replacementFormatDescription: CMFormatDescription?) {
    let replacement = AVCompositionTrackFormatDescriptionReplacement()
    replacement.portableOriginal = originalFormatDescription
    replacement.portableReplacement = replacementFormatDescription ?? originalFormatDescription
    portableFormatDescriptionReplacements.append(replacement)
  }
}

open class AVMutableDateRangeMetadataGroup: AVDateRangeMetadataGroup, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableMediaSelection: AVMediaSelection, @unchecked Sendable {
  public override init() { super.init() }
  public func select(_ mediaSelectionOption: AVMediaSelectionOption?, in mediaSelectionGroup: AVMediaSelectionGroup) {}
}

open class AVMutableMetadataItem: AVMetadataItem, @unchecked Sendable {
  public override init() { super.init() }

  public override var identifier: AVMetadataIdentifier? {
    get { storedIdentifier }
    set {
      storedIdentifier = newValue
      if let newValue {
        storedKeySpace = AVMetadataItem.keySpace(forIdentifier: newValue)
        if let mapped = AVMetadataItem.key(forIdentifier: newValue) as? AVMetadataKey {
          storedCommonKey = mapped
          storedKey = mapped.rawValue as NSString
        } else if let string = AVMetadataItem.key(forIdentifier: newValue) as? String {
          storedKey = string as NSString
        }
      }
    }
  }
  public override var extendedLanguageTag: String? {
    get { storedExtendedLanguageTag }
    set { storedExtendedLanguageTag = newValue }
  }
  public override var locale: Locale? {
    get { storedLocale }
    set { storedLocale = newValue }
  }
  public override var time: CMTime {
    get { storedTime }
    set { storedTime = newValue }
  }
  public override var duration: CMTime {
    get { storedDuration }
    set { storedDuration = newValue }
  }
  public override var dataType: String? {
    get { storedDataType }
    set { storedDataType = newValue }
  }
  public override var value: (any NSCopying & NSObjectProtocol)? {
    get { storedValue }
    set { storedValue = newValue }
  }
  public override var extraAttributes: [AVMetadataExtraAttributeKey : Any]? {
    get { storedExtraAttributes }
    set { storedExtraAttributes = newValue }
  }
  public override var startDate: Date? {
    get { storedStartDate }
    set { storedStartDate = newValue }
  }
  public override var key: (any NSCopying & NSObjectProtocol)? {
    get { storedKey }
    set { storedKey = newValue }
  }
  public override var keySpace: AVMetadataKeySpace? {
    get { storedKeySpace }
    set { storedKeySpace = newValue }
  }
}

open class AVMutableMovie: AVMovie, @unchecked Sendable {
  public override init() { super.init() }

  public convenience init(url URL: URL, options: [String : Any]? = nil, error: ()) throws {
    guard URL.isFileURL, FileManager.default.fileExists(atPath: URL.path) else {
      throw AVError(.failedToLoadMediaData)
    }
    self.init()
    portableURL = URL
    _ = options
    attachMovieProbeIfNeeded(mutable: true)
    if portableProbe() == nil {
      throw AVError(.fileFormatNotRecognized)
    }
  }

  public convenience init(data: Data, options: [String : Any]? = nil, error: ()) throws {
    self.init()
    portableData = data
    _ = options
    attachMovieProbeIfNeeded(mutable: true)
    if portableProbe() == nil {
      throw AVError(.fileFormatNotRecognized)
    }
  }

  public convenience init(settingsFrom movie: AVMovie?, options: [String : Any]? = nil) throws {
    self.init()
    portableTimescale = movie?.portableTimescale ?? 600
    portableURL = movie?.url
    portableDefaultStorage = movie?.defaultMediaDataStorage
    _ = options
  }

  public var timescale: CMTimeScale {
    get { portableTimescale }
    set { portableTimescale = newValue }
  }
  public var isModified: Bool {
    get { portableModified }
    set { portableModified = newValue }
  }
  public var interleavingPeriod: CMTime {
    get { portableInterleavingPeriod }
    set { portableInterleavingPeriod = newValue }
  }

  public func insertTimeRange(
    _ timeRange: CMTimeRange,
    of asset: AVAsset,
    at startTime: CMTime,
    copySampleData: Bool
  ) throws {
    if copySampleData {
      throw AVError(.decoderNotFound)
    }
    _ = startTime
    for source in asset.tracks {
      guard let dest = addMutableTrack(
        withMediaType: source.mediaType,
        copySettingsFrom: source,
        options: nil
      ) else { continue }
      try dest.insertTimeRange(timeRange, of: source, at: startTime, copySampleData: false)
    }
    portableModified = true
  }

  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {
    let extra = timeRange.duration.seconds
    guard extra > 0 else { return }
    loadState.lock.lock()
    for track in loadState.storedTracks {
      let current = track.portableRecord.duration
      let base = current.isValid ? current.seconds : 0
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(seconds: base + extra, timescale: scale)
    }
    loadState.lock.unlock()
    portableModified = true
  }

  public func removeTimeRange(_ timeRange: CMTimeRange) {
    let cut = timeRange.duration.seconds
    guard cut > 0 else { return }
    loadState.lock.lock()
    for track in loadState.storedTracks {
      guard track.portableRecord.duration.isValid else { continue }
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(
        seconds: max(0, track.portableRecord.duration.seconds - cut),
        timescale: scale
      )
    }
    loadState.lock.unlock()
    portableModified = true
  }

  public func scale(_ timeRange: CMTimeRange, toDuration duration: CMTime) {
    let source = timeRange.duration.seconds
    guard source > 0, duration.isValid else { return }
    let factor = duration.seconds / source
    loadState.lock.lock()
    for track in loadState.storedTracks {
      guard track.portableRecord.duration.isValid else { continue }
      let scale = track.portableRecord.mediaTimescale == 0 ? 600 : track.portableRecord.mediaTimescale
      track.portableRecord.duration = AVTimeMath.time(
        seconds: track.portableRecord.duration.seconds * factor,
        timescale: scale
      )
    }
    loadState.lock.unlock()
    portableModified = true
  }

  public func mutableTrack(compatibleWith track: AVAssetTrack) -> AVMutableMovieTrack? {
    tracks.compactMap { $0 as? AVMutableMovieTrack }.first { $0.mediaType == track.mediaType }
  }

  public func addMutableTrack(
    withMediaType mediaType: AVMediaType,
    copySettingsFrom track: AVAssetTrack?,
    options: [String : Any]? = nil
  ) -> AVMutableMovieTrack? {
    _ = options
    let added = AVMutableMovieTrack()
    var record = AVLocalMediaTrack()
    record.mediaType = mediaType
    record.trackID = unusedTrackID()
    record.isEnabled = true
    record.isSelfContained = false
    if let track {
      record.naturalSize = track.naturalSize
      record.preferredTransform = track.preferredTransform
      record.preferredVolume = track.preferredVolume
      record.nominalFrameRate = track.nominalFrameRate
      record.mediaTimescale = track.naturalTimeScale
      record.languageCode = track.languageCode
    }
    added.portableAsset = self
    added.portableRecord = record
    loadState.lock.lock()
    loadState.storedTracks.append(added)
    loadState.lock.unlock()
    portableModified = true
    return added
  }

  public func addMutableTracksCopyingSettings(
    from existingTracks: [AVAssetTrack],
    options: [String : Any]? = nil
  ) -> [AVMutableMovieTrack] {
    existingTracks.compactMap {
      addMutableTrack(withMediaType: $0.mediaType, copySettingsFrom: $0, options: options)
    }
  }

  public func removeTrack(_ track: AVMovieTrack) {
    loadState.lock.lock()
    loadState.storedTracks.removeAll { $0 === track }
    loadState.lock.unlock()
    portableModified = true
  }
}

open class AVMutableMovieTrack: AVMovieTrack, @unchecked Sendable {
  var portableSampleReferenceBaseURL: URL?
  var portableTrackModified = false
  var portableLayer = 0
  var portableCleanApertureDimensions = CGSize.zero
  var portableProductionApertureDimensions = CGSize.zero
  var portableEncodedPixelsDimensions = CGSize.zero
  var portablePreferredMediaChunkSize = 0
  var portablePreferredMediaChunkDuration = CMTime.zero
  var portablePreferredMediaChunkAlignment = 0
  var portableAssociatedTracks: [AVAssetTrack.AssociationType: [AVAssetTrack]] = [:]

  public override init() { super.init() }

  public func append(
    _ sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>
  ) throws -> (decodeTime: CMTime, presentationTime: CMTime) {
    _ = sampleBuffer
    throw AVError(.decoderNotFound)
  }

  public var sampleReferenceBaseURL: URL? {
    get { portableSampleReferenceBaseURL }
    set { portableSampleReferenceBaseURL = newValue }
  }
  public var isModified: Bool {
    get { portableTrackModified }
    set { portableTrackModified = newValue }
  }
  public var hasProtectedContent: Bool { false }
  public var timescale: CMTimeScale {
    get { portableRecord.mediaTimescale }
    set { portableRecord.mediaTimescale = newValue }
  }
  public var layer: Int {
    get { portableLayer }
    set { portableLayer = newValue }
  }
  public var cleanApertureDimensions: CGSize {
    get { portableCleanApertureDimensions }
    set { portableCleanApertureDimensions = newValue }
  }
  public var productionApertureDimensions: CGSize {
    get { portableProductionApertureDimensions }
    set { portableProductionApertureDimensions = newValue }
  }
  public var encodedPixelsDimensions: CGSize {
    get { portableEncodedPixelsDimensions }
    set { portableEncodedPixelsDimensions = newValue }
  }
  public var preferredMediaChunkSize: Int {
    get { portablePreferredMediaChunkSize }
    set { portablePreferredMediaChunkSize = newValue }
  }
  public var preferredMediaChunkDuration: CMTime {
    get { portablePreferredMediaChunkDuration }
    set { portablePreferredMediaChunkDuration = newValue }
  }
  public var preferredMediaChunkAlignment: Int {
    get { portablePreferredMediaChunkAlignment }
    set { portablePreferredMediaChunkAlignment = newValue }
  }
  public override var isEnabled: Bool {
    get { portableRecord.isEnabled }
    set { portableRecord.isEnabled = newValue }
  }
  public override var naturalSize: CGSize {
    get { portableRecord.naturalSize }
    set { portableRecord.naturalSize = newValue }
  }
  public override var preferredTransform: CGAffineTransform {
    get { portableRecord.preferredTransform }
    set { portableRecord.preferredTransform = newValue }
  }
  public override var preferredVolume: Float {
    get { portableRecord.preferredVolume }
    set { portableRecord.preferredVolume = newValue }
  }

  public func insertTimeRange(
    _ timeRange: CMTimeRange,
    of track: AVAssetTrack,
    at startTime: CMTime,
    copySampleData: Bool
  ) throws {
    if copySampleData {
      throw AVError(.decoderNotFound)
    }
    _ = startTime
    portableRecord.duration = timeRange.duration
    portableRecord.mediaType = track.mediaType
    portableRecord.naturalSize = track.naturalSize
    portableRecord.preferredTransform = track.preferredTransform
    portableRecord.nominalFrameRate = track.nominalFrameRate
    portableRecord.mediaTimescale = track.naturalTimeScale
    portableRecord.languageCode = track.languageCode
    portableRecord.isSelfContained = false
    portableTrackModified = true
  }

  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {
    let extra = timeRange.duration.seconds
    guard extra > 0 else { return }
    let current = portableRecord.duration
    let base = current.isValid ? current.seconds : 0
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    portableRecord.duration = AVTimeMath.time(seconds: base + extra, timescale: scale)
    portableTrackModified = true
  }

  public func removeTimeRange(_ timeRange: CMTimeRange) {
    let cut = timeRange.duration.seconds
    guard cut > 0, portableRecord.duration.isValid else { return }
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    portableRecord.duration = AVTimeMath.time(
      seconds: max(0, portableRecord.duration.seconds - cut),
      timescale: scale
    )
    portableTrackModified = true
  }

  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {
    let source = timeRange.duration.seconds
    guard source > 0, duration.isValid, portableRecord.duration.isValid else { return }
    let scale = portableRecord.mediaTimescale == 0 ? 600 : portableRecord.mediaTimescale
    portableRecord.duration = AVTimeMath.time(
      seconds: portableRecord.duration.seconds * (duration.seconds / source),
      timescale: scale
    )
    portableTrackModified = true
  }

  public func addTrackAssociation(to movieTrack: AVMovieTrack, type trackAssociationType: AVAssetTrack.AssociationType) {
    var current = portableAssociatedTracks[trackAssociationType] ?? []
    current.append(movieTrack)
    portableAssociatedTracks[trackAssociationType] = current
  }

  public func removeTrackAssociation(to movieTrack: AVMovieTrack, type trackAssociationType: AVAssetTrack.AssociationType) {
    portableAssociatedTracks[trackAssociationType]?.removeAll { $0 === movieTrack }
  }

  public override func associatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) -> [AVAssetTrack] {
    portableAssociatedTracks[trackAssociationType] ?? []
  }

  public func replaceFormatDescription(
    _ formatDescription: CMFormatDescription,
    with newFormatDescription: CMFormatDescription
  ) {
    _ = (formatDescription, newFormatDescription)
  }

  public func append(
    _ sampleBuffer: CMSampleBuffer,
    decodeTime outDecodeTime: UnsafeMutablePointer<CMTime>?,
    presentationTime outPresentationTime: UnsafeMutablePointer<CMTime>?
  ) throws {
    _ = sampleBuffer
    outDecodeTime?.pointee = .invalid
    outPresentationTime?.pointee = .invalid
    throw AVError(.decoderNotFound)
  }

  public func insertMediaTimeRange(_ mediaTimeRange: CMTimeRange, into trackTimeRange: CMTimeRange) -> Bool {
    _ = (mediaTimeRange, trackTimeRange)
    return false
  }
}

open class AVMutableTimedMetadataGroup: AVTimedMetadataGroup, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableVideoComposition: AVVideoComposition, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(propertiesOf asset: AVAsset, prototypeInstruction: AVVideoCompositionInstruction) { self.init() }
  public class func videoComposition(withPropertiesOf asset: AVAsset, prototypeInstruction: AVVideoCompositionInstruction) async throws -> AVMutableVideoComposition { return AVMutableVideoComposition() }
}

open class AVMutableVideoCompositionInstruction: AVVideoCompositionInstruction, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMutableVideoCompositionLayerInstruction: AVVideoCompositionLayerInstruction, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(assetTrack track: AVAssetTrack) {
    self.init()
    portableTrackID = track.trackID
  }
  public func setTransformRamp(fromStart startTransform: CGAffineTransform, toEnd endTransform: CGAffineTransform, timeRange: CMTimeRange) {
    storedTransform = TransformRamp(timeRange: timeRange, start: startTransform, end: endTransform)
  }
  public func setTransform(_ transform: CGAffineTransform, at time: CMTime) {
    storedTransform = TransformRamp(
      timeRange: CMTimeRange(start: time, duration: .zero),
      start: transform,
      end: transform
    )
  }
  public func setOpacityRamp(fromStartOpacity startOpacity: Float, toEndOpacity endOpacity: Float, timeRange: CMTimeRange) {
    storedOpacity = OpacityRamp(timeRange: timeRange, start: startOpacity, end: endOpacity)
  }
  public func setOpacity(_ opacity: Float, at time: CMTime) {
    storedOpacity = OpacityRamp(
      timeRange: CMTimeRange(start: time, duration: .zero),
      start: opacity,
      end: opacity
    )
  }
  public func setCropRectangleRamp(fromStartCropRectangle startCropRectangle: CGRect, toEndCropRectangle endCropRectangle: CGRect, timeRange: CMTimeRange) {
    storedCrop = CropRectangleRamp(timeRange: timeRange, start: startCropRectangle, end: endCropRectangle)
  }
  public func setCropRectangle(_ cropRectangle: CGRect, at time: CMTime) {
    storedCrop = CropRectangleRamp(
      timeRange: CMTimeRange(start: time, duration: .zero),
      start: cropRectangle,
      end: cropRectangle
    )
  }
}

extension AVURLAsset {
  public class func audiovisualTypes() -> [AVFileType] { [.mp4, .m4a, .mov] }
  public class func audiovisualMIMETypes() -> [String] {
    ["video/mp4", "audio/mp4", "audio/wav", "audio/aiff"]
  }
  public class func isPlayableExtendedMIMEType(_ extendedMIMEType: String) -> Bool { false }
  public var resourceLoader: AVAssetResourceLoader { AVAssetResourceLoader() }
  public var assetCache: AVAssetCache? { nil }
  public func compatibleTrack(for compositionTrack: AVCompositionTrack) -> AVAssetTrack? {
    tracks.first(where: { $0.mediaType == compositionTrack.mediaType })
  }
  public func findCompatibleTrack(for compositionTrack: AVCompositionTrack) async throws -> AVAssetTrack? {
    return compatibleTrack(for: compositionTrack)
  }
  public var variants: [AVAssetVariant] { [] }
  public var mayRequireContentKeysForMediaDataProcessing: Bool { false }
}
