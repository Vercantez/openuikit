import Foundation

public class CIFilterShape: @unchecked Sendable {
    public let extent: CGRect

    public init(rect r: CGRect) {
        self.extent = r
    }

    public func insetBy(x dx: Int32, y dy: Int32) -> CIFilterShape {
        CIFilterShape(rect: extent.insetBy(dx: CGFloat(dx), dy: CGFloat(dy)))
    }

    public func intersect(with s2: CIFilterShape) -> CIFilterShape {
        CIFilterShape(rect: extent.intersection(s2.extent))
    }

    public func intersect(with r: CGRect) -> CIFilterShape {
        CIFilterShape(rect: extent.intersection(r))
    }

    public func union(with s2: CIFilterShape) -> CIFilterShape {
        CIFilterShape(rect: extent.union(s2.extent))
    }

    public func union(with r: CGRect) -> CIFilterShape {
        CIFilterShape(rect: extent.union(r))
    }

    public func transform(by m: CGAffineTransform, interior flag: Bool) -> CIFilterShape {
        _ = flag
        return CIFilterShape(rect: m.applying(to: extent))
    }
}

public class CISampler: @unchecked Sendable {
    public let extent: CGRect
    public let definition: CIFilterShape
    let image: CIImage

    public convenience init(image im: CIImage) {
        self.init(image: im, options: nil)
    }

    public init(image im: CIImage, options dict: [AnyHashable: Any]? = nil) {
        _ = dict
        self.image = im
        self.extent = im.extent
        self.definition = CIFilterShape(rect: im.extent)
    }
}

public class CIImageAccumulator: @unchecked Sendable {
    public let extent: CGRect
    public let format: CIFormat
    private var current: CIImage

    public init?(extent: CGRect, format: CIFormat) {
        guard extent.width > 0, extent.height > 0 else { return nil }
        self.extent = extent
        self.format = format
        self.current = CIImage(color: .clear).cropped(to: extent)
    }

    public convenience init?(extent: CGRect, format: CIFormat, colorSpace: CGColorSpace) {
        self.init(extent: extent, format: format)
        _ = colorSpace
    }

    public func image() -> CIImage { current }

    public func setImage(_ image: CIImage) {
        current = image.cropped(to: extent)
    }

    public func setImage(_ image: CIImage, dirtyRect: CGRect) {
        _ = dirtyRect
        setImage(image)
    }

    public func clear() {
        current = CIImage(color: .clear).cropped(to: extent)
    }
}

public class CIRenderDestination: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public var alphaMode: CIRenderDestinationAlphaMode = .unpremultiplied
    public var blendKernel: CIBlendKernel?
    public var blendsInDestinationColorSpace = false
    public var captureTraceURL: URL?
    public var isClamped = false
    public var colorSpace: CGColorSpace?
    public var isDithered = false
    public var isFlipped = false

    public init(
        bitmapData data: UnsafeMutableRawPointer,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        format: CIFormat
    ) {
        _ = (data, bytesPerRow, format)
        self.width = width
        self.height = height
    }

    public init(glTexture texture: UInt32, target: UInt32, width: Int, height: Int) {
        _ = (texture, target)
        self.width = width
        self.height = height
    }

    public convenience init(GLTexture texture: UInt32, target: UInt32, width: Int, height: Int) {
        self.init(glTexture: texture, target: target, width: width, height: height)
    }
}

public class CIRenderInfo: @unchecked Sendable {
    public let kernelCompileTime: TimeInterval
    public let kernelExecutionTime: TimeInterval
    public let passCount: Int
    public let pixelsProcessed: Int

    public init(
        kernelCompileTime: TimeInterval = 0,
        kernelExecutionTime: TimeInterval = 0,
        passCount: Int = 0,
        pixelsProcessed: Int = 0
    ) {
        self.kernelCompileTime = kernelCompileTime
        self.kernelExecutionTime = kernelExecutionTime
        self.passCount = passCount
        self.pixelsProcessed = pixelsProcessed
    }
}

public class CIRenderTask: @unchecked Sendable {
    public init() {}

    public func waitUntilCompleted() throws -> CIRenderInfo {
        CIRenderInfo()
    }
}

public class CIRAWFilter: CIFilter, @unchecked Sendable {
    public class var supportedCameraModels: [String] { [] }

    public var baselineExposure: Float = 0
    public var boostAmount: Float = 0 {
        didSet { if boostAmount != ciClampAmount(boostAmount) { boostAmount = ciClampAmount(boostAmount) } }
    }
    public var boostShadowAmount: Float = 0 {
        didSet { if boostShadowAmount != ciClampAmount(boostShadowAmount) { boostShadowAmount = ciClampAmount(boostShadowAmount) } }
    }
    public var colorNoiseReductionAmount: Float = 0 {
        didSet { if colorNoiseReductionAmount != ciClampAmount(colorNoiseReductionAmount) { colorNoiseReductionAmount = ciClampAmount(colorNoiseReductionAmount) } }
    }
    public var isColorNoiseReductionSupported = false
    public var contrastAmount: Float = 0 {
        didSet { if contrastAmount != ciClampAmount(contrastAmount) { contrastAmount = ciClampAmount(contrastAmount) } }
    }
    public var isContrastSupported = false
    public var decoderVersion: CIRAWDecoderVersion = .none
    public var detailAmount: Float = 0 {
        didSet { if detailAmount != ciClampAmount(detailAmount) { detailAmount = ciClampAmount(detailAmount) } }
    }
    public var isDetailSupported = false
    public var isDraftModeEnabled = false
    public var exposure: Float = 0
    public var extendedDynamicRangeAmount: Float = 0 {
        didSet { if extendedDynamicRangeAmount != ciClampAmount(extendedDynamicRangeAmount) { extendedDynamicRangeAmount = ciClampAmount(extendedDynamicRangeAmount) } }
    }
    public var isGamutMappingEnabled = false
    public var isHighlightRecoveryEnabled = false
    public var isHighlightRecoverySupported = false
    public var isLensCorrectionEnabled = false
    public var isLensCorrectionSupported = false
    public var linearSpaceFilter: CIFilter?
    public var localToneMapAmount: Float = 0 {
        didSet { if localToneMapAmount != ciClampAmount(localToneMapAmount) { localToneMapAmount = ciClampAmount(localToneMapAmount) } }
    }
    public var isLocalToneMapSupported = false
    public var luminanceNoiseReductionAmount: Float = 0 {
        didSet { if luminanceNoiseReductionAmount != ciClampAmount(luminanceNoiseReductionAmount) { luminanceNoiseReductionAmount = ciClampAmount(luminanceNoiseReductionAmount) } }
    }
    public var isLuminanceNoiseReductionSupported = false
    public var moireReductionAmount: Float = 0 {
        didSet { if moireReductionAmount != ciClampAmount(moireReductionAmount) { moireReductionAmount = ciClampAmount(moireReductionAmount) } }
    }
    public var isMoireReductionSupported = false
    public var nativeSize: CGSize = .zero
    public var neutralChromaticity: CGPoint = .zero
    public var neutralLocation: CGPoint = .zero
    public var neutralTemperature: Float = 0
    public var neutralTint: Float = 0
    public var orientation: CGImagePropertyOrientation = .up
    public var portraitEffectsMatte: CIImage?
    public var previewImage: CIImage?
    public var properties: [AnyHashable: Any] = [:]
    public var scaleFactor: Float = 1 {
        didSet { if scaleFactor < 0 { scaleFactor = 0 } }
    }
    public var semanticSegmentationGlassesMatte: CIImage?
    public var semanticSegmentationHairMatte: CIImage?
    public var semanticSegmentationSkinMatte: CIImage?
    public var semanticSegmentationSkyMatte: CIImage?
    public var semanticSegmentationTeethMatte: CIImage?
    public var shadowBias: Float = 0
    public var sharpnessAmount: Float = 0 {
        didSet { if sharpnessAmount != ciClampAmount(sharpnessAmount) { sharpnessAmount = ciClampAmount(sharpnessAmount) } }
    }
    public var isSharpnessSupported = false
    public var supportedDecoderVersions: [CIRAWDecoderVersion] { [] }

    public override var outputImage: CIImage? { nil }

    public override init() {
        super.init()
        name = "CIRAWFilter"
    }

    public convenience init?(imageURL url: URL) {
        _ = url
        return nil
    }

    public convenience init?(imageData data: Data, identifierHint: String?) {
        _ = (data, identifierHint)
        return nil
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

func ciClampAmount(_ value: Float) -> Float {
    min(1, max(0, value))
}

extension NSObject {
    public func provideImageData(
        _ data: UnsafeMutableRawPointer,
        bytesPerRow rowbytes: Int,
        origin originx: Int,
        _ originy: Int,
        size width: Int,
        _ height: Int,
        userInfo info: Any?
    ) {
        _ = (data, rowbytes, originx, originy, width, height, info)
    }
}
