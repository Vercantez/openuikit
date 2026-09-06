import Foundation
#if canImport(CoreImage)
import CoreImage
#endif

open class AVAnyAsyncProperty: NSObject, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVAsyncProperty<Root, Value>: AVPartialAsyncProperty<Root>, @unchecked Sendable {
  public let portableKey: String

  public override init() {
    self.portableKey = ""
    super.init()
  }

  public init(portableKey: String) {
    self.portableKey = portableKey
    super.init()
  }

  public enum Status: CustomStringConvertible {
    case notYetLoaded
    case loading
    case loaded(Value)
    case failed(NSError)

    public var description: String {
      switch self {
      case .notYetLoaded: return "notYetLoaded"
      case .loading: return "loading"
      case .loaded: return "loaded"
      case .failed: return "failed"
      }
    }
  }
}

extension AVAsyncProperty.Status: Equatable where Value: Equatable {
  public static func == (lhs: AVAsyncProperty<Root, Value>.Status, rhs: AVAsyncProperty<Root, Value>.Status) -> Bool {
    switch (lhs, rhs) {
    case (.notYetLoaded, .notYetLoaded), (.loading, .loading):
      return true
    case (.loaded(let a), .loaded(let b)):
      return a == b
    case (.failed(let a), .failed(let b)):
      return a == b
    default:
      return false
    }
  }
}

open class AVAsynchronousCIImageFilteringRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var renderSize: CGSize { .zero }
  public var compositionTime: CMTime { .zero }
  public var sourceImage: CIImage { CIImage() }
  public func finish(with filteredImage: CIImage, context: CIContext?) {}
  public func finish(with error: any Error) {}
}

public protocol AVAsynchronousKeyValueLoading {
  func status<T>(of property: AVAsyncProperty<Self, T>) -> AVAsyncProperty<Self, T>.Status
  func statusOfValue(forKey key: String, error outError: UnsafeMutablePointer<NSError?>?) -> AVKeyValueStatus
  func loadValuesAsynchronously(forKeys keys: [String], completionHandler handler: (() -> Void)?)
  func loadValues(forKeys keys: [String]) async
}

open class AVAsynchronousVideoCompositionRequest: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var sourceSampleDataTrackIDs: [CMPersistentTrackID] { [] }
  public func sourceTaggedDynamicBuffers(byTrackID trackID: CMPersistentTrackID) -> [CMTaggedDynamicBuffer]? { nil }
  public func sourceReadOnlyPixelBuffer(byTrackID trackID: CMPersistentTrackID) -> CVReadOnlyPixelBuffer? { nil }
  public func sourceReadySampleBuffer(byTrackID trackID: CMPersistentTrackID) -> CMReadySampleBuffer<CMSampleBuffer.DynamicContent>? { nil }
  public func finish(withComposedPixelBuffer readOnlyPixelBuffer: CVReadOnlyPixelBuffer) {}
  public func finish(withComposedTaggedBuffers taggedBuffers: [CMTaggedDynamicBuffer]) {}
  public func attach(_ spatialVideoConfiguration: AVSpatialVideoConfiguration, to pixelBuffer: inout CVMutablePixelBuffer) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var renderContext: AVVideoCompositionRenderContext { AVVideoCompositionRenderContext() }
  public var compositionTime: CMTime { .zero }
  public var sourceTrackIDs: [NSNumber] { [] }
  public var videoCompositionInstruction: any AVVideoCompositionInstructionProtocol { AVVideoCompositionInstruction() }
  public func sourceFrame(byTrackID trackID: CMPersistentTrackID) -> CVPixelBuffer? { nil }
  public func sourceSampleBuffer(byTrackID trackID: CMPersistentTrackID) -> CMSampleBuffer? { nil }
  public func sourceTimedMetadata(byTrackID trackID: CMPersistentTrackID) -> AVTimedMetadataGroup? { nil }
  public func finish(withComposedVideoFrame composedVideoFrame: CVPixelBuffer) {}
  public func finish(with error: any Error) {}
  public func finishCancelledRequest() {}
}

public enum AVAuthorizationStatus: Int, Hashable, Sendable {
  case notDetermined = 0
  case restricted = 1
  case denied = 2
  case authorized = 3
}

public struct AVCIImageFilteringParameters: Sendable {
  public init() {}
  public var sourceImage: CIImage = CIImage()
  public var compositionTime: CMTime = .zero
  public var renderSize: CGSize = .zero
}

public struct AVCIImageFilteringResult: Sendable {
  public init() {}
  public var resultImage: CIImage = CIImage()
  public var ciContext: CIContext? = nil
  public init(resultImage: CIImage, ciContext: CIContext? = nil) {}
}

open class AVCameraCalibrationData: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var intrinsicMatrixReferenceDimensions: CGSize { .zero }
  public var pixelSize: Float { 0 }
  public var lensDistortionLookupTable: Data? { nil }
  public var inverseLensDistortionLookupTable: Data? { nil }
  public var lensDistortionCenter: CGPoint { .zero }
}

open class AVCustomMediaSelectionScheme: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var shouldOfferLanguageSelection: Bool { false }
  public var availableLanguages: [String] { [] }
}

open class AVDateRangeMetadataGroup: AVMetadataGroup, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(items: [AVMetadataItem], start startDate: Date, end endDate: Date?) { self.init() }
  public var startDate: Date { Date.distantPast }
  public var endDate: Date? { nil }
}

public struct AVEdgeWidths: Sendable {
  public init() {}
  public init(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {}
  public var left: CGFloat = 0
  public var top: CGFloat = 0
  public var right: CGFloat = 0
  public var bottom: CGFloat = 0
}

open class AVFrameRateRange: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var maxFrameDuration: CMTime { .zero }
  public var minFrameDuration: CMTime { .zero }
}

public enum AVKeyValueStatus: Int, Hashable, Sendable {
  case unknown = 0
  case loading = 1
  case loaded = 2
  case failed = 3
  case cancelled = 4
}

public struct AVLayerVideoGravity: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  // Apple AVLayerVideoGravity*. Measured from the public C-string constants
  // (`AVLayerVideoGravityResizeAspect` and siblings) in AVFoundation/AVAnimation.h.
  public static let resizeAspect = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspect")
  public static let resizeAspectFill = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspectFill")
  public static let resize = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResize")
}

public struct AVMergedMetrics<MetricEvent1: AVMetricEvent, MetricEvent2: AVMetricEvent, MetricEventPack>: Sendable {
  public init() {}
  public typealias Element = (AVMetricEvent, any AVMetricEventStreamPublisher)
  public struct AsyncIterator: Sendable {
    public init() {}
    public mutating func next() async throws -> (AVMetricEvent, any AVMetricEventStreamPublisher)? { return nil }
    public typealias Element = (AVMetricEvent, any AVMetricEventStreamPublisher)
  }
}

open class AVPartialAsyncProperty<Root>: AVAnyAsyncProperty, @unchecked Sendable {
  public override init() { super.init() }
}

extension AVPartialAsyncProperty where Root: AVAsset {
  public static var duration: AVAsyncProperty<Root, CMTime> {
    AVAsyncProperty(portableKey: "duration")
  }
  public static var tracks: AVAsyncProperty<Root, [AVAssetTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
  public static var isPlayable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isPlayable")
  }
  public static var metadata: AVAsyncProperty<Root, [AVMetadataItem]> {
    AVAsyncProperty(portableKey: "metadata")
  }
  public static var commonMetadata: AVAsyncProperty<Root, [AVMetadataItem]> {
    AVAsyncProperty(portableKey: "commonMetadata")
  }
  public static var lyrics: AVAsyncProperty<Root, String?> {
    AVAsyncProperty(portableKey: "lyrics")
  }
  public static var isExportable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isExportable")
  }
  public static var isReadable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isReadable")
  }
  public static var isComposable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isComposable")
  }
}

open class AVPersistableContentKeyRequest: AVContentKeyRequest, @unchecked Sendable {
  public override init() { super.init() }
  public func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]? = nil) throws -> Data {
    _ = (keyVendorResponse, options)
    throw AVError(.contentKeyRequestCancelled)
  }
}

public struct AVPixelAspectRatio: Sendable {
  public init() {}
  public init(horizontalSpacing: Int, verticalSpacing: Int) {}
  public var horizontalSpacing: Int = 0
  public var verticalSpacing: Int = 0
}

open class AVPortraitEffectsMatte: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(fromDictionaryRepresentation imageSourceAuxDataInfoDictionary: [AnyHashable : Any]) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func replacingPortraitEffectsMatte(with pixelBuffer: CVPixelBuffer) throws -> Self { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var mattingImage: CVPixelBuffer { CVPixelBuffer() }
}

open class AVQueuePlayer: AVPlayer, @unchecked Sendable {
  private let queueLock = NSLock()
  private var queuedItems: [AVPlayerItem] = []

  public override init() {
    super.init()
  }

  public init(items: [AVPlayerItem]) {
    queuedItems = items
    super.init(playerItem: items.first)
  }

  public func items() -> [AVPlayerItem] {
    queueLock.withLock { queuedItems }
  }

  public func canInsert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) -> Bool {
    _ = item
    if let afterItem {
      return queueLock.withLock { queuedItems.contains { $0 === afterItem } }
    }
    return true
  }

  public func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
    queueLock.lock()
    if let afterItem, let index = queuedItems.firstIndex(where: { $0 === afterItem }) {
      queuedItems.insert(item, at: queuedItems.index(after: index))
    } else {
      queuedItems.insert(item, at: queuedItems.startIndex)
    }
    let head = queuedItems.first
    queueLock.unlock()
    if currentItem == nil {
      replaceCurrentItem(with: head)
    }
  }

  public func remove(_ item: AVPlayerItem) {
    queueLock.lock()
    queuedItems.removeAll { $0 === item }
    let head = queuedItems.first
    let removingCurrent = currentItem === item
    queueLock.unlock()
    if removingCurrent {
      replaceCurrentItem(with: head)
    }
  }

  public func removeAllItems() {
    queueLock.withLock { queuedItems.removeAll() }
    replaceCurrentItem(with: nil)
  }

  public func advanceToNextItem() {
    queueLock.lock()
    if !queuedItems.isEmpty {
      queuedItems.removeFirst()
    }
    let head = queuedItems.first
    queueLock.unlock()
    replaceCurrentItem(with: head)
  }
}

open class AVRenderedCaptionImage: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var readOnlyPixelBuffer: CVReadOnlyPixelBuffer { CVReadOnlyPixelBuffer() }
  public var pixelBuffer: CVPixelBuffer { CVPixelBuffer() }
  public var position: CGPoint { .zero }
}

open class AVRouteDetector: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var isRouteDetectionEnabled: Bool {
      get { false }
      set { _ = newValue }
    }
  public var multipleRoutesDetected: Bool { false }
  public var detectsCustomRoutes: Bool {
      get { false }
      set { _ = newValue }
    }
}

public struct AVSpatialCaptureDiscomfortReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let notEnoughLight = AVSpatialCaptureDiscomfortReason(rawValue: "notEnoughLight")
  public static let subjectTooClose = AVSpatialCaptureDiscomfortReason(rawValue: "subjectTooClose")
}

public struct AVSpatialVideoConfiguration: Sendable {
  public init() {}
  public var cameraCalibrationDataLensCollection: CMFormatDescription.Extensions.Value.CameraCalibrationDataLensCollection? = nil
  public var horizontalFieldOfView: UInt32? = nil
  public var cameraSystemBaseline: UInt32? = nil
  public var disparityAdjustment: Int32? = nil
  public init(formatDescription: CMFormatDescription) {}
  public static var nonSpatial: AVSpatialVideoConfiguration { AVSpatialVideoConfiguration() }
}

open class AVTextStyleRule: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public class func propertyList(for textStyleRules: [AVTextStyleRule]) -> Any { 0 }
  public class func textStyleRules(fromPropertyList plist: Any) -> [AVTextStyleRule]? { nil }
  convenience init?(textMarkupAttributes: [String : Any] = [:]) { return nil }
  public var textMarkupAttributes: [String : Any] { [:] }
}

open class AVTimedMetadataGroup: AVMetadataGroup, @unchecked Sendable {
  public override init() { super.init() }
  convenience init?(sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>) { return nil }
  convenience init(items: [AVMetadataItem], timeRange: CMTimeRange) { self.init() }
  convenience init?(sampleBuffer: CMSampleBuffer) { return nil }
  public var timeRange: CMTimeRange { .zero }
  public func copyFormatDescription() -> CMMetadataFormatDescription? { nil }
}

public struct AVVariantPreferences: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let scalabilityToLosslessAudio = AVVariantPreferences(rawValue: 1 << 0)
}
