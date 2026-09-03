import Foundation

public struct AVVideoApertureMode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let cleanAperture = AVVideoApertureMode(rawValue: "cleanAperture")
  public static let productionAperture = AVVideoApertureMode(rawValue: "productionAperture")
  public static let encodedPixels = AVVideoApertureMode(rawValue: "encodedPixels")
}

public struct AVVideoCodecType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let hevc = AVVideoCodecType(rawValue: "hevc")
  public static let h264 = AVVideoCodecType(rawValue: "h264")
  public static let jpeg = AVVideoCodecType(rawValue: "jpeg")
  public static let JPEGXL = AVVideoCodecType(rawValue: "JPEGXL")
  public static let proRes4444 = AVVideoCodecType(rawValue: "proRes4444")
  public static let appleProRes4444XQ = AVVideoCodecType(rawValue: "appleProRes4444XQ")
  public static let proRes422 = AVVideoCodecType(rawValue: "proRes422")
  public static let proRes422HQ = AVVideoCodecType(rawValue: "proRes422HQ")
  public static let proRes422LT = AVVideoCodecType(rawValue: "proRes422LT")
  public static let proRes422Proxy = AVVideoCodecType(rawValue: "proRes422Proxy")
  public static let proResRAW = AVVideoCodecType(rawValue: "proResRAW")
  public static let proResRAWHQ = AVVideoCodecType(rawValue: "proResRAWHQ")
  public static let hevcWithAlpha = AVVideoCodecType(rawValue: "hevcWithAlpha")
}

public protocol AVVideoCompositing : AnyObject, Sendable {
  var sourcePixelBufferAttributes: [String : any Sendable]? { get }
  var requiredPixelBufferAttributesForRenderContext: [String : any Sendable] { get }
  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext)
  func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest)
  func cancelAllPendingVideoCompositionRequests()
  var supportsWideColorSourceFrames: Bool { get }
  var supportsHDRSourceFrames: Bool { get }
  var supportsSourceTaggedBuffers: Bool { get }
  var canConformColorOfSourceFrames: Bool { get }
  func anticipateRendering(using renderHint: AVVideoCompositionRenderHint)
  func prerollForRendering(using renderHint: AVVideoCompositionRenderHint)
}

open class AVVideoComposition: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Configuration: Sendable {
    public init() {}
    public var animationTool: AVVideoCompositionCoreAnimationTool? = nil
    public var colorPrimaries: String? = nil
    public var colorTransferFunction: String? = nil
    public var colorYCbCrMatrix: String? = nil
    public var customVideoCompositorClass: (any AVVideoCompositing.Type)? = nil
    public var frameDuration: CMTime = .zero
    public var instructions: [any AVVideoCompositionInstructionProtocol] = []
    public var outputBufferDescription: [[CMTag]]? = nil
    public var spatialVideoConfigurations: [AVSpatialVideoConfiguration] = []
    public var perFrameHDRDisplayMetadataPolicy: AVVideoComposition.PerFrameHDRDisplayMetadataPolicy = AVVideoComposition.PerFrameHDRDisplayMetadataPolicy(rawValue: "")
    public var renderScale: Float = 0
    public var renderSize: CGSize = .zero
    public var sourceSampleDataTrackIDs: [CMPersistentTrackID] = []
    public var sourceTrackIDForFrameTiming: CMPersistentTrackID = 0
    public init(for asset: AVAsset, prototypeInstruction: AVVideoCompositionInstruction? = nil) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
    public init(animationTool: AVVideoCompositionCoreAnimationTool? = nil, colorPrimaries: String? = nil, colorTransferFunction: String? = nil, colorYCbCrMatrix: String? = nil, customVideoCompositorClass: (any AVVideoCompositing.Type)? = nil, frameDuration: CMTime = CMTime.zero, instructions: [any AVVideoCompositionInstructionProtocol] = [any AVVideoCompositionInstructionProtocol](), outputBufferDescription: [[CMTag]]? = nil, perFrameHDRDisplayMetadataPolicy: AVVideoComposition.PerFrameHDRDisplayMetadataPolicy = .propagate, renderScale: Float = 1.0, renderSize: CGSize = .zero, sourceSampleDataTrackIDs: [CMPersistentTrackID] = [CMPersistentTrackID](), sourceTrackIDForFrameTiming: Int32 = CMPersistentTrackID.zero, spatialVideoConfigurations: [AVSpatialVideoConfiguration] = []) {}
  }
  public struct PerFrameHDRDisplayMetadataPolicy: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let propagate = PerFrameHDRDisplayMetadataPolicy(rawValue: "propagate")
    public static let generate = PerFrameHDRDisplayMetadataPolicy(rawValue: "generate")
  }
  public dynamic var sourceSampleDataTrackIDs: [CMPersistentTrackID] { [] }
  public var outputBufferDescription: [[CMTag]]? { nil }
  public var spatialVideoConfigurations: [AVSpatialVideoConfiguration] { [] }
  convenience init(applyingFiltersTo asset: AVAsset, applier: @escaping (AVCIImageFilteringParameters) async throws -> AVCIImageFilteringResult) async throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  convenience init(configuration: AVVideoComposition.Configuration) { self.init() }
  convenience init(propertiesOf asset: AVAsset) { self.init() }
  public class func videoComposition(withPropertiesOf asset: AVAsset) async throws -> AVVideoComposition { return AVVideoComposition() }
  public var customVideoCompositorClass: (any AVVideoCompositing.Type)? { nil }
  public var frameDuration: CMTime { .zero }
  public var sourceTrackIDForFrameTiming: CMPersistentTrackID { 0 }
  public var renderSize: CGSize { .zero }
  public var renderScale: Float { 0 }
  public var instructions: [any AVVideoCompositionInstructionProtocol] { [] }
  public var animationTool: AVVideoCompositionCoreAnimationTool? { nil }
  public var colorPrimaries: String? { nil }
  public var colorYCbCrMatrix: String? { nil }
  public var colorTransferFunction: String? { nil }
  public var perFrameHDRDisplayMetadataPolicy: AVVideoComposition.PerFrameHDRDisplayMetadataPolicy { AVVideoComposition.PerFrameHDRDisplayMetadataPolicy(rawValue: "") }
  convenience init(asset: AVAsset, applyingCIFiltersWithHandler applier: @escaping (AVAsynchronousCIImageFilteringRequest) -> Void) { self.init() }
  public class func videoComposition(with asset: AVAsset, applyingCIFiltersWithHandler applier: @escaping (AVAsynchronousCIImageFilteringRequest) -> Void) async throws -> AVVideoComposition { return AVVideoComposition() }
  public func isValid(for asset: AVAsset?, timeRange: CMTimeRange, validationDelegate: (any AVVideoCompositionValidationHandling)?) -> Bool { false }
  public func isValid(for asset: AVAsset?, timeRange: CMTimeRange, validationDelegate: (any AVVideoCompositionValidationHandling)?) async throws -> Bool { return false }
  public func isValid(for tracks: [AVAssetTrack], assetDuration duration: CMTime, timeRange: CMTimeRange, validationDelegate: (any AVVideoCompositionValidationHandling)?) -> Bool { false }
}

open class AVVideoCompositionCoreAnimationTool: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Configuration: Sendable {
    public init() {}
  }
  convenience init(configuration: sending AVVideoCompositionCoreAnimationTool.Configuration) { self.init() }
}

open class AVVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol, @unchecked Sendable {
  public override init() { super.init() }
  public struct Configuration: Sendable {
    public init() {}
    public var backgroundColor: CGColor? = nil
    public var enablePostProcessing: Bool = false
    public var layerInstructions: [AVVideoCompositionLayerInstruction] = []
    public var requiredSourceSampleDataTrackIDs: [CMPersistentTrackID] = []
    public var timeRange: CMTimeRange = .zero
    public init(backgroundColor: CGColor? = nil, enablePostProcessing: Bool = true, layerInstructions: [AVVideoCompositionLayerInstruction] = [], requiredSourceSampleDataTrackIDs: [CMPersistentTrackID] = [], timeRange: CMTimeRange = .zero) {}
  }
  convenience init(configuration: AVVideoCompositionInstruction.Configuration) { self.init() }
  public var timeRange: CMTimeRange { .zero }
  public var backgroundColor: CGColor? { nil }
  public var layerInstructions: [AVVideoCompositionLayerInstruction] { [] }
  public var enablePostProcessing: Bool { false }
  public var requiredSourceTrackIDs: [NSValue]? { nil }
  public var passthroughTrackID: CMPersistentTrackID { 0 }
  public var requiredSourceSampleDataTrackIDs: [NSNumber] { [] }
  public var containsTweening: Bool { false }
}

public protocol AVVideoCompositionInstructionProtocol : AnyObject, Sendable {
  var timeRange: CMTimeRange { get }
  var enablePostProcessing: Bool { get }
  var containsTweening: Bool { get }
  var requiredSourceTrackIDs: [NSValue]? { get }
  var passthroughTrackID: CMPersistentTrackID { get }
  var requiredSourceSampleDataTrackIDs: [NSNumber] { get }
}

open class AVVideoCompositionLayerInstruction: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Configuration: Sendable {
    public init() {}
    public var trackID: CMPersistentTrackID = 0
    public init(trackID: CMPersistentTrackID = .zero) {}
    public init(assetTrack: AVAssetTrack) {}
    public func cropRectangleRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.CropRectangleRamp? { nil }
    public func opacityRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.OpacityRamp? { nil }
    public func transformRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.TransformRamp? { nil }
    public mutating func setOpacity(_ opacity: Float, at time: CMTime) {}
    public mutating func addOpacityRamp(_ ramp: AVVideoCompositionLayerInstruction.OpacityRamp) {}
    public mutating func setTransform(_ transform: CGAffineTransform, at time: CMTime) {}
    public mutating func addTransformRamp(_ ramp: AVVideoCompositionLayerInstruction.TransformRamp) {}
    public mutating func setCropRectangle(_ rect: CGRect, at time: CMTime) {}
    public mutating func addCropRectangleRamp(_ ramp: AVVideoCompositionLayerInstruction.CropRectangleRamp) {}
  }
  public struct CropRectangleRamp: Sendable {
    public init() {}
    public var timeRange: CMTimeRange = .zero
    public var start: CGRect = .zero
    public var end: CGRect = .zero
    public init(timeRange: CMTimeRange, start: CGRect, end: CGRect) {}
  }
  public struct OpacityRamp: Sendable {
    public init() {}
    public var timeRange: CMTimeRange = .zero
    public var start: Float = 0
    public var end: Float = 0
    public init(timeRange: CMTimeRange, start: Float, end: Float) {}
  }
  public struct TransformRamp: Sendable {
    public init() {}
    public var timeRange: CMTimeRange = .zero
    public var start: CGAffineTransform = .identity
    public var end: CGAffineTransform = .identity
    public init(timeRange: CMTimeRange, start: CGAffineTransform, end: CGAffineTransform) {}
  }
  convenience init(configuration: AVVideoCompositionLayerInstruction.Configuration) { self.init() }
  public func cropRectangleRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.CropRectangleRamp? { nil }
  public func opacityRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.OpacityRamp? { nil }
  public func transformRamp(at time: CMTime) -> AVVideoCompositionLayerInstruction.TransformRamp? { nil }
  public var trackID: CMPersistentTrackID { 0 }
  public func getTransformRamp(for time: CMTime, start startTransform: UnsafeMutablePointer<CGAffineTransform>?, end endTransform: UnsafeMutablePointer<CGAffineTransform>?, timeRange: UnsafeMutablePointer<CMTimeRange>?) -> Bool { false }
  public func getOpacityRamp(for time: CMTime, startOpacity: UnsafeMutablePointer<Float>?, endOpacity: UnsafeMutablePointer<Float>?, timeRange: UnsafeMutablePointer<CMTimeRange>?) -> Bool { false }
  public func getCropRectangleRamp(for time: CMTime, startCropRectangle: UnsafeMutablePointer<CGRect>?, endCropRectangle: UnsafeMutablePointer<CGRect>?, timeRange: UnsafeMutablePointer<CMTimeRange>?) -> Bool { false }
}

open class AVVideoCompositionRenderContext: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func makeMutablePixelBuffer() throws -> CVMutablePixelBuffer { return CVMutablePixelBuffer() }
  public var size: CGSize { .zero }
  public var renderTransform: CGAffineTransform { .identity }
  public var renderScale: Float { 0 }
  public var pixelAspectRatio: AVPixelAspectRatio { AVPixelAspectRatio() }
  public var edgeWidths: AVEdgeWidths { AVEdgeWidths() }
  public var highQualityRendering: Bool { false }
  public var videoComposition: AVVideoComposition { AVVideoComposition() }
  public func newPixelBuffer() -> CVPixelBuffer? { nil }
}

open class AVVideoCompositionRenderHint: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var startCompositionTime: CMTime { .zero }
  public var endCompositionTime: CMTime { .zero }
}

public protocol AVVideoCompositionValidationHandling : AnyObject {
  func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidValueForKey key: String) -> Bool
  func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingEmptyTimeRange timeRange: CMTimeRange) -> Bool
  func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTimeRangeIn videoCompositionInstruction: any AVVideoCompositionInstructionProtocol) -> Bool
  func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTrackIDIn videoCompositionInstruction: any AVVideoCompositionInstructionProtocol, layerInstruction: AVVideoCompositionLayerInstruction, asset: AVAsset) -> Bool
}

open class AVVideoOutputSpecification: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(tagCollections: [[CMTag]]) { self.init() }
  public func setOutputPixelBufferAttributes(_ pixelBufferAttributes: [String : Any]?, for tagCollection: [CMTag]) {}
  public func setOutputSettings(_ outputSettings: [String : any Sendable]?, for tagCollection: [CMTag]) {}
  public var preferredTagCollections: [[CMTag]] { [] }
  public var defaultPixelBufferAttributes: [String : Any]? {
      get { nil }
      set { _ = newValue }
    }
  public var defaultOutputSettings: [String : any Sendable]? {
      get { nil }
      set { _ = newValue }
    }
}

open class AVVideoPerformanceMetrics: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var totalNumberOfFrames: Int { 0 }
  public var numberOfDroppedFrames: Int { 0 }
  public var numberOfCorruptedFrames: Int { 0 }
  public var numberOfFramesDisplayedUsingOptimizedCompositing: Int { 0 }
  public var totalAccumulatedFrameDelay: TimeInterval { 0 }
}

public struct AVVideoRange: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let sdr = AVVideoRange(rawValue: "sdr")
  public static let hlg = AVVideoRange(rawValue: "hlg")
  public static let pq = AVVideoRange(rawValue: "pq")
}
