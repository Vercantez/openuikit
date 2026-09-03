import Foundation

public protocol AVQueuedSampleBufferRendering : AnyObject {
  var timebase: CMTimebase { get }
  func enqueue(_ sampleBuffer: CMSampleBuffer)
  func flush()
  var isReadyForMoreMediaData: Bool { get }
  func requestMediaDataWhenReady(on queue: DispatchQueue, using block: @escaping () -> Void)
  func stopRequestingMediaData()
  var hasSufficientMediaDataForReliablePlaybackStart: Bool { get }
}

public enum AVQueuedSampleBufferRenderingStatus: Int, Hashable, Sendable {
  case unknown = 0
  case rendering = 1
  case failed = 2
}

open class AVSampleBufferAudioRenderer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var status: AVQueuedSampleBufferRenderingStatus { AVQueuedSampleBufferRenderingStatus(rawValue: 0)! }
  public var error: (any Error)? { nil }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { AVAudioTimePitchAlgorithm(rawValue: "") }
      set { _ = newValue }
    }
  public var allowedAudioSpatializationFormats: AVAudioSpatializationFormats {
      get { AVAudioSpatializationFormats(rawValue: 0) }
      set { _ = newValue }
    }
  public var volume: Float {
      get { 0 }
      set { _ = newValue }
    }
  public var isMuted: Bool {
      get { false }
      set { _ = newValue }
    }
  public func flush(fromSourceTime time: CMTime) async -> Bool { false }
}

open class AVSampleBufferGenerator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public init(asset: AVAsset, timebase: CMTimebase?) {}
  public func makeSampleBuffer(for request: AVSampleBufferRequest) throws -> sending CMSampleBuffer { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func makeBatch() -> AVSampleBufferGeneratorBatch { AVSampleBufferGeneratorBatch() }
  public func makeSampleBuffer(for request: AVSampleBufferRequest, addTo batch: AVSampleBufferGeneratorBatch) throws -> CMSampleBuffer { return CMSampleBuffer() }
  public class func notifyOfDataReady(for sbuf: CMSampleBuffer) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
}

open class AVSampleBufferGeneratorBatch: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func makeDataReady() async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func cancel() {}
}

open class AVSampleBufferRenderSynchronizer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var timebase: CMTimebase { CMTimebase() }
  public var rate: Float {
      get { 0 }
      set { _ = newValue }
    }
  public func currentTime() -> CMTime { .zero }
  public func setRate(_ rate: Float, time: CMTime) {}
  public func setRate(_ rate: Float, time: CMTime, atHostTime hostTime: CMTime) {}
  public var delaysRateChangeUntilHasSufficientMediaData: Bool {
      get { false }
      set { _ = newValue }
    }
  public var renderers: [any AVQueuedSampleBufferRendering] { [] }
  public func addRenderer(_ renderer: any AVQueuedSampleBufferRendering) {}
  public func removeRenderer(_ renderer: any AVQueuedSampleBufferRendering, at time: CMTime) async -> Bool { false }
  public func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any { 0 }
  public func addBoundaryTimeObserver(forTimes times: [NSValue], queue: DispatchQueue?, using block: @escaping () -> Void) -> Any { 0 }
  public func removeTimeObserver(_ observer: Any) {}
  public static let rateDidChangeNotification: Notification.Name = Notification.Name("rateDidChangeNotification")
}

open class AVSampleBufferRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Direction: Int, Hashable, Sendable {
    case forward = 0
    case none = 1
    case reverse = 2
  }
  public enum Mode: Int, Hashable, Sendable {
    case immediate = 0
    case scheduled = 1
    case opportunistic = 2
  }
  public init(start startCursor: AVSampleCursor) {}
  public var startCursor: AVSampleCursor { AVSampleCursor() }
  public var direction: AVSampleBufferRequest.Direction {
      get { AVSampleBufferRequest.Direction(rawValue: 0)! }
      set { _ = newValue }
    }
  public var limitCursor: AVSampleCursor? {
      get { nil }
      set { _ = newValue }
    }
  public var preferredMinSampleCount: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var maxSampleCount: Int {
      get { 0 }
      set { _ = newValue }
    }
  public var mode: AVSampleBufferRequest.Mode {
      get { AVSampleBufferRequest.Mode(rawValue: 0)! }
      set { _ = newValue }
    }
  public var overrideTime: CMTime {
      get { .zero }
      set { _ = newValue }
    }
}

open class AVSampleBufferVideoRenderer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum PresentationTimeExpectation: Sendable {
    case none
    case monotonicallyIncreasing
    case minimumUpcoming(CMTime)
  }
  public var presentationTimeExpectation: AVSampleBufferVideoRenderer.PresentationTimeExpectation {
      get { AVSampleBufferVideoRenderer.PresentationTimeExpectation(rawValue: 0)! }
      set { _ = newValue }
    }
  public var recommendedPixelBufferAttributes: CVPixelBufferAttributes { CVPixelBufferAttributes() }
  public var status: AVQueuedSampleBufferRenderingStatus { AVQueuedSampleBufferRenderingStatus(rawValue: 0)! }
  public var error: (any Error)? { nil }
  public var requiresFlushToResumeDecoding: Bool { false }
  public func flush(removingDisplayedImage removeDisplayedImage: Bool) async {}
  public func displayedPixelBuffer() -> CVPixelBuffer? { nil }
  public var videoPerformanceMetrics: AVVideoPerformanceMetrics? { get async { nil } }
  public static let didFailToDecodeNotification: Notification.Name = Notification.Name("didFailToDecodeNotification")
  public static let didFailToDecodeNotificationErrorKey: String = "didFailToDecodeNotificationErrorKey"
  public static let requiresFlushToResumeDecodingDidChangeNotification: Notification.Name = Notification.Name("requiresFlushToResumeDecodingDidChangeNotification")
}

open class AVSampleCursor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func stepInDecodeOrder(byCount stepCount: Int64) -> Int64 { 0 }
  public func stepInPresentationOrder(byCount stepCount: Int64) -> Int64 { 0 }
  public func step(byDecodeTime deltaDecodeTime: CMTime, wasPinned outWasPinned: UnsafeMutablePointer<Bool>?) -> CMTime { .zero }
  public func step(byPresentationTime deltaPresentationTime: CMTime, wasPinned outWasPinned: UnsafeMutablePointer<Bool>?) -> CMTime { .zero }
  public var presentationTimeStamp: CMTime { .zero }
  public var decodeTimeStamp: CMTime { .zero }
  public func maySamplesWithEarlierDecodeTimeStampsHavePresentationTimeStamps(laterThan cursor: AVSampleCursor) -> Bool { false }
  public func maySamplesWithLaterDecodeTimeStampsHavePresentationTimeStamps(earlierThan cursor: AVSampleCursor) -> Bool { false }
  public var currentSampleDuration: CMTime { .zero }
  public func copyCurrentSampleFormatDescription() -> CMFormatDescription { CMFormatDescription() }
  public var currentSampleSyncInfo: AVSampleCursorSyncInfo { AVSampleCursorSyncInfo() }
  public var currentSampleDependencyInfo: AVSampleCursorDependencyInfo { AVSampleCursorDependencyInfo() }
  public var currentSampleDependencyAttachments: [AnyHashable : Any]? { nil }
  public var currentSampleAudioDependencyInfo: AVSampleCursorAudioDependencyInfo { AVSampleCursorAudioDependencyInfo() }
  public var samplesRequiredForDecoderRefresh: Int { 0 }
  public var currentChunkStorageURL: URL? { nil }
  public var currentChunkStorageRange: AVSampleCursorStorageRange { AVSampleCursorStorageRange() }
  public var currentChunkInfo: AVSampleCursorChunkInfo { AVSampleCursorChunkInfo() }
  public var currentSampleIndexInChunk: Int64 { 0 }
  public var currentSampleStorageRange: AVSampleCursorStorageRange { AVSampleCursorStorageRange() }
}

public struct AVSampleCursorAudioDependencyInfo: Sendable {
  public init(audioSampleIsIndependentlyDecodable: Bool, audioSamplePacketRefreshCount: Int) {}
  public var audioSampleIsIndependentlyDecodable: Bool = false
  public var audioSamplePacketRefreshCount: Int = 0
  public init() {}
}

public struct AVSampleCursorChunkInfo: Sendable {
  public init(chunkSampleCount: Int64, chunkHasUniformSampleSizes: Bool, chunkHasUniformSampleDurations: Bool, chunkHasUniformFormatDescriptions: Bool) {}
  public var chunkSampleCount: Int64 = 0
  public var chunkHasUniformSampleSizes: Bool = false
  public var chunkHasUniformSampleDurations: Bool = false
  public var chunkHasUniformFormatDescriptions: Bool = false
  public init() {}
}

public struct AVSampleCursorDependencyInfo: Sendable {
  public init(sampleIndicatesWhetherItHasDependentSamples: Bool, sampleHasDependentSamples: Bool, sampleIndicatesWhetherItDependsOnOthers: Bool, sampleDependsOnOthers: Bool, sampleIndicatesWhetherItHasRedundantCoding: Bool, sampleHasRedundantCoding: Bool) {}
  public var sampleIndicatesWhetherItHasDependentSamples: Bool = false
  public var sampleHasDependentSamples: Bool = false
  public var sampleIndicatesWhetherItDependsOnOthers: Bool = false
  public var sampleDependsOnOthers: Bool = false
  public var sampleIndicatesWhetherItHasRedundantCoding: Bool = false
  public var sampleHasRedundantCoding: Bool = false
  public init() {}
}

public struct AVSampleCursorStorageRange: Sendable {
  public init(offset: Int64, length: Int64) {}
  public var offset: Int64 = 0
  public var length: Int64 = 0
  public init() {}
}

public struct AVSampleCursorSyncInfo: Sendable {
  public init(sampleIsFullSync: Bool, sampleIsPartialSync: Bool, sampleIsDroppable: Bool) {}
  public var sampleIsFullSync: Bool = false
  public var sampleIsPartialSync: Bool = false
  public var sampleIsDroppable: Bool = false
  public init() {}
}
