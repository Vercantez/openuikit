import Foundation

open class AVMetricContentKeyRequestEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var contentKeySpecifier: AVContentKeySpecifier { AVContentKeySpecifier() }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var isClientInitiated: Bool { false }
  public var mediaResourceRequestEvent: AVMetricMediaResourceRequestEvent? { nil }
}

open class AVMetricDownloadSummaryEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var errorEvent: AVMetricErrorEvent? { nil }
  public var recoverableErrorCount: Int { 0 }
  public var mediaResourceRequestCount: Int { 0 }
  public var bytesDownloadedCount: Int { 0 }
  public var downloadDuration: TimeInterval { 0 }
  public var variants: [AVAssetVariant] { [] }
}

open class AVMetricErrorEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var didRecover: Bool { false }
  public var error: any Error { AVFoundationPortableError.mediaServiceUnavailable }
}

open class AVMetricEvent: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var date: Date { Date.distantPast }
  public var mediaTime: CMTime { .zero }
  public var sessionID: String? { nil }
}

public protocol AVMetricEventStreamPublisher {
  func metrics<MetricEvent>(forType metricType: MetricEvent.Type) -> AVMetrics<MetricEvent> where MetricEvent : AVMetricEvent
  func allMetrics() -> AVMetrics<AVMetricEvent>
}

open class AVMetricHLSMediaSegmentRequestEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var url: URL? { nil }
  public var isMapSegment: Bool { false }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var indexFileURL: URL { URL(fileURLWithPath: "/dev/null") }
  public var segmentDuration: TimeInterval { 0 }
  public var mediaResourceRequestEvent: AVMetricMediaResourceRequestEvent? { nil }
}

open class AVMetricHLSPlaylistRequestEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var url: URL? { nil }
  public var isMultivariantPlaylist: Bool { false }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var mediaResourceRequestEvent: AVMetricMediaResourceRequestEvent? { nil }
}

open class AVMetricMediaRendition: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var stableID: String? { nil }
  public var url: URL? { nil }
}

open class AVMetricMediaResourceRequestEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var url: URL? { nil }
  public var serverAddress: String? { nil }
  public var requestStartTime: Date { Date.distantPast }
  public var requestEndTime: Date { Date.distantPast }
  public var responseStartTime: Date { Date.distantPast }
  public var responseEndTime: Date { Date.distantPast }
  public var wasReadFromCache: Bool { false }
  public var errorEvent: AVMetricErrorEvent? { nil }
}

open class AVMetricPlayerItemInitialLikelyToKeepUpEvent: AVMetricPlayerItemLikelyToKeepUpEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var playlistRequestEvents: [AVMetricHLSPlaylistRequestEvent] { [] }
  public var mediaSegmentRequestEvents: [AVMetricHLSMediaSegmentRequestEvent] { [] }
  public var contentKeyRequestEvents: [AVMetricContentKeyRequestEvent] { [] }
}

open class AVMetricPlayerItemLikelyToKeepUpEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var loadedTimeRanges: [CMTimeRange] { [] }
  public var variant: AVAssetVariant? { nil }
  public var timeTaken: TimeInterval { 0 }
}

open class AVMetricPlayerItemPlaybackSummaryEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var errorEvent: AVMetricErrorEvent? { nil }
  public var recoverableErrorCount: Int { 0 }
  public var stallCount: Int { 0 }
  public var variantSwitchCount: Int { 0 }
  public var playbackDuration: Int { 0 }
  public var mediaResourceRequestCount: Int { 0 }
  public var timeSpentRecoveringFromStall: TimeInterval { 0 }
  public var timeSpentInInitialStartup: TimeInterval { 0 }
  public var timeWeightedAverageBitrate: Int { 0 }
  public var timeWeightedPeakBitrate: Int { 0 }
}

open class AVMetricPlayerItemRateChangeEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var rate: Double { 0 }
  public var previousRate: Double { 0 }
  public var variant: AVAssetVariant? { nil }
}

open class AVMetricPlayerItemSeekDidCompleteEvent: AVMetricPlayerItemRateChangeEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var didSeekInBuffer: Bool { false }
}

open class AVMetricPlayerItemSeekEvent: AVMetricPlayerItemRateChangeEvent, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMetricPlayerItemStallEvent: AVMetricPlayerItemRateChangeEvent, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVMetricPlayerItemVariantSwitchEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var loadedTimeRanges: [CMTimeRange] { [] }
  public var fromVariant: AVAssetVariant? { nil }
  public var toVariant: AVAssetVariant { AVAssetVariant() }
  public var videoRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
  public var audioRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
  public var subtitleRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
  public var didSucceed: Bool { false }
}

open class AVMetricPlayerItemVariantSwitchStartEvent: AVMetricEvent, @unchecked Sendable {
  public override init() { super.init() }
  public var loadedTimeRanges: [CMTimeRange] { [] }
  public var fromVariant: AVAssetVariant? { nil }
  public var toVariant: AVAssetVariant { AVAssetVariant() }
  public var videoRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
  public var audioRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
  public var subtitleRendition: AVMetricMediaRendition { AVMetricMediaRendition() }
}

public struct AVMetrics<MetricEvent: AVMetricEvent>: Sendable {
  public init() {}
  public typealias Element = MetricEvent
  public struct AsyncIterator: Sendable {
    public init() {}
    public mutating func next() async throws -> MetricEvent? { return nil }
    public typealias Element = MetricEvent
  }
}
