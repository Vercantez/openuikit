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
  public var preferredRate: Float { portableProbe() == nil ? 0 : 1 }
  public var preferredVolume: Float { portableProbe() == nil ? 0 : 1 }
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
  public func tracks(withMediaType mediaType: AVMediaType) -> [AVAssetTrack] {
    tracks.filter { $0.mediaType == mediaType }
  }
  public func loadTracks(withMediaType mediaType: AVMediaType) async throws -> [AVAssetTrack] {
    return tracks(withMediaType: mediaType)
  }
  public func tracks(withMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) -> [AVAssetTrack] {
    tracks.filter { $0.hasMediaCharacteristic(mediaCharacteristic) }
  }
  public func loadTracks(withMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic) async throws -> [AVAssetTrack] {
    return tracks(withMediaCharacteristic: mediaCharacteristic)
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
  public class func exportPresets(compatibleWith asset: AVAsset) -> [String] { [] }
  public class func compatibility(ofExportPreset presetName: String, with asset: AVAsset, outputFileType: AVFileType?) async -> Bool { false }
  public var supportedFileTypes: [AVFileType] { [] }
  public var compatibleFileTypes: [AVFileType] { get async { [] } }
  public var timeRange: CMTimeRange {
      get { .zero }
      set { _ = newValue }
    }
  public var maxDuration: CMTime { .zero }
  public var estimatedOutputFileLength: Int64 { 0 }
  public var fileLengthLimit: Int64 {
      get { 0 }
      set { _ = newValue }
    }
  public var estimatedMaximumDuration: CMTime { get async throws { .zero } }
  public var estimatedOutputFileLengthInBytes: Int64 { get async throws { 0 } }
  public var metadata: [AVMetadataItem]? {
      get { nil }
      set { _ = newValue }
    }
  public var metadataItemFilter: AVMetadataItemFilter? {
      get { nil }
      set { _ = newValue }
    }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { AVAudioTimePitchAlgorithm(rawValue: "") }
      set { _ = newValue }
    }
  public var audioMix: AVAudioMix? {
      get { nil }
      set { _ = newValue }
    }
  public var videoComposition: AVVideoComposition? {
      get { nil }
      set { _ = newValue }
    }
  public var customVideoCompositor: (any AVVideoCompositing)? { nil }
  public var audioTrackGroupHandling: AVAssetTrackGroupOutputHandling {
      get { AVAssetTrackGroupOutputHandling(rawValue: 0) }
      set { _ = newValue }
    }
  public var canPerformMultiplePassesOverSourceMediaData: Bool {
      get { false }
      set { _ = newValue }
    }
  public var directoryForTemporaryFiles: URL? {
      get { nil }
      set { _ = newValue }
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
      get { .zero }
      set { _ = newValue }
    }
  public var outputs: [AVAssetReaderOutput] { stateLock.withLock { storedOutputs } }
  public func canAdd(_ output: AVAssetReaderOutput) -> Bool { false }
  public func add(_ output: AVAssetReaderOutput) { _ = output }
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
  public override init() { super.init() }
  convenience init(audioTracks: [AVAssetTrack], audioSettings: [String : Any]?) { self.init() }
  public var audioTracks: [AVAssetTrack] { [] }
  public var audioSettings: [String : Any]? { nil }
  public var audioMix: AVAudioMix? {
      get { nil }
      set { _ = newValue }
    }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { AVAudioTimePitchAlgorithm(rawValue: "") }
      set { _ = newValue }
    }
}

public protocol AVAssetReaderCaptionValidationHandling : AnyObject {
  func captionAdaptor(_ adaptor: AVAssetReaderOutputCaptionAdaptor, didVendCaption caption: AVCaption, skippingUnsupportedSourceSyntaxElements syntaxElements: [String])
}

open class AVAssetReaderOutput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class Provider<Payload: AVAssetReaderOutput.SupportedPayload>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func next() async throws -> Payload? { return nil }
    public func captionsNotPresentInPreviousGroups(in captionGroup: AVCaptionGroup) -> [AVCaption] { [] }
  }
  open class RandomAccessController: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public func resetForReading(timeRanges: [CMTimeRange]) {}
    public func markConfigurationAsFinal() {}
  }
  public protocol SupportedPayload {
  }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var alwaysCopiesSampleData: Bool {
      get { false }
      set { _ = newValue }
    }
  public func copyNextSampleBuffer() -> CMSampleBuffer? { nil }
  public var supportsRandomAccess: Bool {
      get { false }
      set { _ = newValue }
    }
  public func reset(forReadingTimeRanges timeRanges: [NSValue]) {}
  public func markConfigurationAsFinal() {}
}

open class AVAssetReaderOutputCaptionAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetReaderTrackOutput trackOutput: AVAssetReaderTrackOutput) { self.init() }
  public var assetReaderTrackOutput: AVAssetReaderTrackOutput { AVAssetReaderTrackOutput() }
  public func nextCaptionGroup() -> AVCaptionGroup? { nil }
  public func captionsNotPresentInPreviousGroups(in captionGroup: AVCaptionGroup) -> [AVCaption] { [] }
  public var validationDelegate: (any AVAssetReaderCaptionValidationHandling)? {
      get { nil }
      set { _ = newValue }
    }
}

open class AVAssetReaderOutputMetadataAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetReaderTrackOutput trackOutput: AVAssetReaderTrackOutput) { self.init() }
  public var assetReaderTrackOutput: AVAssetReaderTrackOutput { AVAssetReaderTrackOutput() }
  public func nextTimedMetadataGroup() -> AVTimedMetadataGroup? { nil }
}

open class AVAssetReaderSampleReferenceOutput: AVAssetReaderOutput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(track: AVAssetTrack) { self.init() }
  public var track: AVAssetTrack { AVAssetTrack() }
}

open class AVAssetReaderTrackOutput: AVAssetReaderOutput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(track: AVAssetTrack, outputSettings: [String : Any]?) { self.init() }
  public var track: AVAssetTrack { AVAssetTrack() }
  public var outputSettings: [String : Any]? { nil }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { AVAudioTimePitchAlgorithm(rawValue: "") }
      set { _ = newValue }
    }
}

open class AVAssetReaderVideoCompositionOutput: AVAssetReaderOutput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(videoTracks: [AVAssetTrack], videoSettings: [String : Any]?) { self.init() }
  public var videoTracks: [AVAssetTrack] { [] }
  public var videoSettings: [String : Any]? { nil }
  public var videoComposition: AVVideoComposition? {
      get { nil }
      set { _ = newValue }
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
  public var estimatedDataRate: Float { 0 }
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
  public func samplePresentationTime(forTrackTime trackTime: CMTime) -> CMTime { .zero }
  public func loadSamplePresentationTime(forTrackTime trackTime: CMTime) async throws -> CMTime { return .zero }
  public var commonMetadata: [AVMetadataItem] { [] }
  public var metadata: [AVMetadataItem] { [] }
  public var availableMetadataFormats: [AVMetadataFormat] { [] }
  public func metadata(forFormat format: AVMetadataFormat) -> [AVMetadataItem] { [] }
  public func loadMetadata(for format: AVMetadataFormat) async throws -> [AVMetadataItem] { return [] }
  public var availableTrackAssociationTypes: [AVAssetTrack.AssociationType] { [] }
  public func associatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) -> [AVAssetTrack] { [] }
  public func loadAssociatedTracks(ofType trackAssociationType: AVAssetTrack.AssociationType) async throws -> [AVAssetTrack] { return [] }
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
  public override init() { super.init() }
  convenience init(predicate: NSPredicate) { self.init() }
  convenience init(variant: AVAssetVariant) { self.init() }
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
  public var outputURL: URL { storedURL }
  public var outputFileType: AVFileType { storedFileType }
  public var availableMediaTypes: [AVMediaType] { [.video, .audio] }
  public var status: AVAssetWriter.Status { stateLock.withLock { storedStatus } }
  public var error: (any Error)? { stateLock.withLock { storedError } }
  public var metadata: [AVMetadataItem] {
      get { [] }
      set { _ = newValue }
    }
  public var shouldOptimizeForNetworkUse: Bool {
      get { false }
      set { _ = newValue }
    }
  public var directoryForTemporaryFiles: URL? {
      get { nil }
      set { _ = newValue }
    }
  public var inputs: [AVAssetWriterInput] { stateLock.withLock { storedInputs } }
  public func canApply(outputSettings: [String : Any]?, forMediaType mediaType: AVMediaType) -> Bool { false }
  public func canAdd(_ input: AVAssetWriterInput) -> Bool { false }
  public func add(_ input: AVAssetWriterInput) { _ = input }
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
  public var movieFragmentInterval: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var initialMovieFragmentInterval: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var initialMovieFragmentSequenceNumber: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var producesCombinableFragments: Bool {
      get { false }
      set { _ = newValue }
    }
  public var overallDurationHint: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var movieTimeScale: CMTimeScale {
      get { 0 }
      set { _ = newValue }
    }
  public func canAdd(_ inputGroup: AVAssetWriterInputGroup) -> Bool { false }
  public func add(_ inputGroup: AVAssetWriterInputGroup) {}
  public var inputGroups: [AVAssetWriterInputGroup] { [] }
  public var preferredOutputSegmentInterval: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var initialSegmentStartTime: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var outputFileTypeProfile: AVFileTypeProfile? {
      get { nil }
      set { _ = newValue }
    }
  public var delegate: (any AVAssetWriterDelegate)? {
      get { nil }
      set { _ = newValue }
    }
  public func flushSegment() {}
}

public protocol AVAssetWriterDelegate : AnyObject, Sendable {
  func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?)
  func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType)
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
  convenience init(mediaType: AVMediaType, outputSettings: [String : Any]?) { self.init() }
  convenience init(mediaType: AVMediaType, outputSettings: [String : Any]?, sourceFormatHint: CMFormatDescription?) { self.init() }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var outputSettings: [String : Any]? { nil }
  public var sourceFormatHint: CMFormatDescription? { nil }
  public var metadata: [AVMetadataItem] {
      get { [] }
      set { _ = newValue }
    }
  public var isReadyForMoreMediaData: Bool { false }
  public var expectsMediaDataInRealTime: Bool {
      get { false }
      set { _ = newValue }
    }
  public func append(_ sampleBuffer: CMSampleBuffer) -> Bool { false }
  public func markAsFinished() {}
  public var languageCode: String? {
      get { nil }
      set { _ = newValue }
    }
  public var extendedLanguageTag: String? {
      get { nil }
      set { _ = newValue }
    }
  public var naturalSize: CGSize {
      get { .zero }
      set { _ = newValue }
    }
  public var transform: CGAffineTransform {
      get { .identity }
      set { _ = newValue }
    }
  public var preferredVolume: Float {
      get { 0 }
      set { _ = newValue }
    }
  public var marksOutputTrackAsEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var mediaTimeScale: CMTimeScale {
      get { 0 }
      set { _ = newValue }
    }
  public var preferredMediaChunkDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var preferredMediaChunkAlignment: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var sampleReferenceBaseURL: URL? {
      get { nil }
      set { _ = newValue }
    }
  public var mediaDataLocation: AVAssetWriterInput.MediaDataLocation {
      get { AVAssetWriterInput.MediaDataLocation(rawValue: "") }
      set { _ = newValue }
    }
  public func canAddTrackAssociation(withTrackOf input: AVAssetWriterInput, type trackAssociationType: String) -> Bool { false }
  public func addTrackAssociation(withTrackOf input: AVAssetWriterInput, type trackAssociationType: String) {}
  public var performsMultiPassEncodingIfSupported: Bool {
      get { false }
      set { _ = newValue }
    }
  public var canPerformMultiplePasses: Bool { false }
  public var currentPassDescription: AVAssetWriterInputPassDescription? { nil }
  public func markCurrentPassAsFinished() {}
}

open class AVAssetWriterInputCaptionAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetWriterInput input: AVAssetWriterInput) { self.init() }
  public var assetWriterInput: AVAssetWriterInput { AVAssetWriterInput() }
  public func append(_ caption: AVCaption) -> Bool { false }
  public func append(_ captionGroup: AVCaptionGroup) -> Bool { false }
}

open class AVAssetWriterInputGroup: AVMediaSelectionGroup, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(inputs: [AVAssetWriterInput], defaultInput: AVAssetWriterInput?) { self.init() }
  public var inputs: [AVAssetWriterInput] { [] }
  public var defaultInput: AVAssetWriterInput? { nil }
}

open class AVAssetWriterInputMetadataAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetWriterInput input: AVAssetWriterInput) { self.init() }
  public var assetWriterInput: AVAssetWriterInput { AVAssetWriterInput() }
  public func append(_ timedMetadataGroup: AVTimedMetadataGroup) -> Bool { false }
}

open class AVAssetWriterInputPassDescription: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var sourceTimeRanges: [NSValue] { [] }
}

open class AVAssetWriterInputPixelBufferAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetWriterInput input: AVAssetWriterInput, sourcePixelBufferAttributes: [String : Any]? = nil) { self.init() }
  public var assetWriterInput: AVAssetWriterInput { AVAssetWriterInput() }
  public var sourcePixelBufferAttributes: [String : any Sendable]? { nil }
  public var pixelBufferPool: CVPixelBufferPool? { nil }
  public func append(_ pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool { false }
}

open class AVAssetWriterInputTaggedPixelBufferGroupAdaptor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(assetWriterInput input: AVAssetWriterInput, sourcePixelBufferAttributes: [String : Any]? = nil) { self.init() }
  public var assetWriterInput: AVAssetWriterInput { AVAssetWriterInput() }
  public var sourcePixelBufferAttributes: [String : any Sendable]? { nil }
  public var pixelBufferPool: CVPixelBufferPool? { nil }
}

open class AVComposition: AVAsset, @unchecked Sendable {
  public override init() { super.init() }
  public var urlAssetInitializationOptions: [String : Any] { [:] }
}

open class AVCompositionTrack: AVAssetTrack, @unchecked Sendable {
  public override init() { super.init() }
  public var formatDescriptionReplacements: [AVCompositionTrackFormatDescriptionReplacement] { [] }
}

open class AVCompositionTrackFormatDescriptionReplacement: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var originalFormatDescription: CMFormatDescription { CMFormatDescription() }
  public var replacementFormatDescription: CMFormatDescription { CMFormatDescription() }
}

open class AVCompositionTrackSegment: AVAssetTrackSegment, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(url URL: URL, trackID: CMPersistentTrackID, sourceTimeRange: CMTimeRange, targetTimeRange: CMTimeRange) {
    self.init()
    portableSourceURL = URL
    portableSourceTrackID = trackID
    portableTimeMapping = CMTimeMapping(source: sourceTimeRange, target: targetTimeRange)
  }
  convenience init(timeRange: CMTimeRange) {
    self.init()
    portableTimeMapping = CMTimeMapping(source: .zero, target: timeRange)
  }
  var portableSourceURL: URL?
  var portableSourceTrackID: CMPersistentTrackID = 0
  var portableTimeMapping = CMTimeMapping()
  public var sourceURL: URL? { portableSourceURL }
  public var sourceTrackID: CMPersistentTrackID { portableSourceTrackID }
  public override var timeMapping: CMTimeMapping { portableTimeMapping }
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
  convenience init(urlAssetInitializationOptions URLAssetInitializationOptions: [String : Any]? = nil) { self.init() }
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
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) { _ = timeRange }
  public func removeTimeRange(_ timeRange: CMTimeRange) { _ = timeRange }
  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {
    _ = (timeRange, duration)
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
  var portableSegments: [AVCompositionTrackSegment] = []
  public override var segments: [AVAssetTrackSegment] { portableSegments }
  public func insertTimeRange(_ timeRange: CMTimeRange, of track: AVAssetTrack, at startTime: CMTime) throws {
    let segment = AVCompositionTrackSegment(
      url: (track.asset as? AVURLAsset)?.url ?? URL(fileURLWithPath: "/dev/null"),
      trackID: track.trackID,
      sourceTimeRange: timeRange,
      targetTimeRange: CMTimeRange(start: startTime, duration: timeRange.duration)
    )
    portableSegments.append(segment)
    portableRecord.duration = timeRange.duration
    portableRecord.mediaType = track.mediaType
    portableRecord.naturalSize = track.naturalSize
    portableRecord.preferredTransform = track.preferredTransform
    portableRecord.nominalFrameRate = track.nominalFrameRate
    portableRecord.mediaTimescale = track.naturalTimeScale
    portableRecord.languageCode = track.languageCode
  }
  public func insertTimeRanges(_ timeRanges: [NSValue], of tracks: [AVAssetTrack], at startTime: CMTime) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {}
  public func removeTimeRange(_ timeRange: CMTimeRange) {}
  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {}
  public func validateSegments(_ trackSegments: [AVCompositionTrackSegment]) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func addTrackAssociation(to compositionTrack: AVCompositionTrack, type trackAssociationType: AVAssetTrack.AssociationType) {}
  public func removeTrackAssociation(to compositionTrack: AVCompositionTrack, type trackAssociationType: AVAssetTrack.AssociationType) {}
  public func replaceFormatDescription(_ originalFormatDescription: CMFormatDescription, with replacementFormatDescription: CMFormatDescription?) {}
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
}

open class AVMutableMovie: AVMovie, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(url URL: URL, options: [String : Any]? = nil, error: ()) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  convenience init(data: Data, options: [String : Any]? = nil, error: ()) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  convenience init(settingsFrom movie: AVMovie?, options: [String : Any]? = nil) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var timescale: CMTimeScale {
      get { 0 }
      set { _ = newValue }
    }
  public var isModified: Bool {
      get { false }
      set { _ = newValue }
    }
  public var interleavingPeriod: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public func insertTimeRange(_ timeRange: CMTimeRange, of asset: AVAsset, at startTime: CMTime, copySampleData: Bool) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {}
  public func removeTimeRange(_ timeRange: CMTimeRange) {}
  public func scale(_ timeRange: CMTimeRange, toDuration duration: CMTime) {}
  public func mutableTrack(compatibleWith track: AVAssetTrack) -> AVMutableMovieTrack? { nil }
  public func addMutableTrack(withMediaType mediaType: AVMediaType, copySettingsFrom track: AVAssetTrack?, options: [String : Any]? = nil) -> AVMutableMovieTrack? { nil }
  public func addMutableTracksCopyingSettings(from existingTracks: [AVAssetTrack], options: [String : Any]? = nil) -> [AVMutableMovieTrack] { [] }
  public func removeTrack(_ track: AVMovieTrack) {}
}

open class AVMutableMovieTrack: AVMovieTrack, @unchecked Sendable {
  public override init() { super.init() }
  public func append(_ sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>) throws -> (decodeTime: CMTime, presentationTime: CMTime) { return (decodeTime: .zero, presentationTime: .zero) }
  public var sampleReferenceBaseURL: URL? {
      get { nil }
      set { _ = newValue }
    }
  public var isModified: Bool {
      get { false }
      set { _ = newValue }
    }
  public var hasProtectedContent: Bool { false }
  public var timescale: CMTimeScale {
      get { 0 }
      set { _ = newValue }
    }
  public var layer: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var cleanApertureDimensions: CGSize {
      get { .zero }
      set { _ = newValue }
    }
  public var productionApertureDimensions: CGSize {
      get { .zero }
      set { _ = newValue }
    }
  public var encodedPixelsDimensions: CGSize {
      get { .zero }
      set { _ = newValue }
    }
  public var preferredMediaChunkSize: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var preferredMediaChunkDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var preferredMediaChunkAlignment: Int {
      get { 0 }
      set { _ = newValue }
    }
  public func insertTimeRange(_ timeRange: CMTimeRange, of track: AVAssetTrack, at startTime: CMTime, copySampleData: Bool) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func insertEmptyTimeRange(_ timeRange: CMTimeRange) {}
  public func removeTimeRange(_ timeRange: CMTimeRange) {}
  public func scaleTimeRange(_ timeRange: CMTimeRange, toDuration duration: CMTime) {}
  public func addTrackAssociation(to movieTrack: AVMovieTrack, type trackAssociationType: AVAssetTrack.AssociationType) {}
  public func removeTrackAssociation(to movieTrack: AVMovieTrack, type trackAssociationType: AVAssetTrack.AssociationType) {}
  public func replaceFormatDescription(_ formatDescription: CMFormatDescription, with newFormatDescription: CMFormatDescription) {}
  public func append(_ sampleBuffer: CMSampleBuffer, decodeTime outDecodeTime: UnsafeMutablePointer<CMTime>?, presentationTime outPresentationTime: UnsafeMutablePointer<CMTime>?) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func insertMediaTimeRange(_ mediaTimeRange: CMTimeRange, into trackTimeRange: CMTimeRange) -> Bool { false }
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
  public class func audiovisualTypes() -> [AVFileType] { [] }
  public class func audiovisualMIMETypes() -> [String] { [] }
  public class func isPlayableExtendedMIMEType(_ extendedMIMEType: String) -> Bool { false }
  public var httpSessionIdentifier: UUID { UUID() }
  public var resourceLoader: AVAssetResourceLoader { AVAssetResourceLoader() }
  public var assetCache: AVAssetCache? { nil }
  public func compatibleTrack(for compositionTrack: AVCompositionTrack) -> AVAssetTrack? { nil }
  public func findCompatibleTrack(for compositionTrack: AVCompositionTrack) async throws -> AVAssetTrack? { return nil }
  public var variants: [AVAssetVariant] { [] }
  public var mayRequireContentKeysForMediaDataProcessing: Bool { false }
}
