import Foundation

final class MPSColorTransformStorage {
    let pointer: UnsafeMutablePointer<Float>

    init(_ transform: UnsafePointer<Float>?) {
        pointer = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        if let transform {
            pointer[0] = transform[0]
            pointer[1] = transform[1]
            pointer[2] = transform[2]
        } else {
            pointer[0] = 0.299
            pointer[1] = 0.587
            pointer[2] = 0.114
        }
    }

    deinit {
        pointer.deallocate()
    }
}

open class MPSImageGaussianBlur: MPSUnaryImageKernel {
    public private(set) var sigma: Float

    public required init(device: any MTLDevice) {
        self.sigma = 0
        super.init(device: device)
    }

    public init(device: any MTLDevice, sigma: Float) {
        self.sigma = sigma
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSImageGaussianBlur(device: device ?? self.device, sigma: sigma)
        copied.options = options
        copied.label = label
        copied.clipRect = clipRect
        copied.offset = offset
        copied.edgeMode = edgeMode
        return copied as! Self
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUSeparableGaussian(
            source: sourceImage,
            destination: destinationImage,
            sigma: sigma,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageBox: MPSUnaryImageKernel {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int

    public required init(device: any MTLDevice) {
        self.kernelWidth = 1
        self.kernelHeight = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSImageBox(device: device ?? self.device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
        copied.options = options
        copied.label = label
        copied.clipRect = clipRect
        copied.offset = offset
        copied.edgeMode = edgeMode
        return copied as! Self
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUBox(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageTent: MPSImageBox {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUTent(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageSobel: MPSUnaryImageKernel {
    private let transformPointer: UnsafeMutablePointer<Float>

    public var colorTransform: UnsafePointer<Float> {
        UnsafePointer(transformPointer)
    }

    public required init(device: any MTLDevice) {
        self.transformPointer = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        self.transformPointer[0] = 0.299
        self.transformPointer[1] = 0.587
        self.transformPointer[2] = 0.114
        super.init(device: device)
    }

    public init(device: any MTLDevice, linearGrayColorTransform transform: UnsafePointer<Float>) {
        self.transformPointer = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        self.transformPointer[0] = transform[0]
        self.transformPointer[1] = transform[1]
        self.transformPointer[2] = transform[2]
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    deinit {
        transformPointer.deallocate()
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUSobel(
            source: sourceImage,
            destination: destinationImage,
            transform: transformPointer,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageHistogram: MPSKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip
    public var zeroHistogram: Bool = true
    public var minPixelThresholdValue: vector_float4 = .zero
    public private(set) var histogramInfo: MPSImageHistogramInfo

    public required init(device: any MTLDevice) {
        self.histogramInfo = MPSImageHistogramInfo()
        super.init(device: device)
    }

    public init(device: any MTLDevice, histogramInfo: UnsafePointer<MPSImageHistogramInfo>) {
        self.histogramInfo = histogramInfo.pointee
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func histogramSize(forSourceFormat sourceFormat: MTLPixelFormat) -> Int {
        _ = sourceFormat
        return histogramInfo.numberOfHistogramEntries * 4 * MemoryLayout<UInt32>.stride
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture source: any MTLTexture,
        histogram: any MTLBuffer,
        histogramOffset: Int
    ) {
        _ = commandBuffer
        mpsCPUHistogram(
            source: source,
            histogram: histogram,
            histogramOffset: histogramOffset,
            info: histogramInfo,
            zeroHistogram: zeroHistogram
        )
    }
}

open class MPSImageHistogramEqualization: MPSUnaryImageKernel {
    public private(set) var histogramInfo: MPSImageHistogramInfo
    var equalizationLUT: [UInt8] = []

    public required init(device: any MTLDevice) {
        self.histogramInfo = MPSImageHistogramInfo()
        super.init(device: device)
    }

    public init(device: any MTLDevice, histogramInfo: UnsafePointer<MPSImageHistogramInfo>) {
        self.histogramInfo = histogramInfo.pointee
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeTransform(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture source: any MTLTexture,
        histogram: any MTLBuffer,
        histogramOffset: Int
    ) {
        _ = (commandBuffer, source)
        let entries = max(histogramInfo.numberOfHistogramEntries, 1)
        let available = max(histogram.length - histogramOffset, 0) / MemoryLayout<UInt32>.stride
        guard available >= entries else { return }
        let counts = histogram.contents.advanced(by: histogramOffset).bindMemory(to: UInt32.self, capacity: available)
        equalizationLUT = mpsHistogramEqualizationLUT(counts: counts, entries: entries, channelCount: min(4, available / entries))
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUApplyLUT(
            source: sourceImage,
            destination: destinationImage,
            lut: equalizationLUT,
            offset: offset,
            clipRect: clipRect,
            edgeMode: edgeMode
        )
    }
}

open class MPSImageHistogramSpecification: MPSUnaryImageKernel {
    public private(set) var histogramInfo: MPSImageHistogramInfo

    public required init(device: any MTLDevice) {
        self.histogramInfo = MPSImageHistogramInfo()
        super.init(device: device)
    }

    public init(device: any MTLDevice, histogramInfo: UnsafePointer<MPSImageHistogramInfo>) {
        self.histogramInfo = histogramInfo.pointee
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeTransform(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture source: any MTLTexture,
        sourceHistogram: any MTLBuffer,
        sourceHistogramOffset: Int,
        desiredHistogram: any MTLBuffer,
        desiredHistogramOffset: Int
    ) {
        _ = (
            commandBuffer, source, sourceHistogram, sourceHistogramOffset,
            desiredHistogram, desiredHistogramOffset
        )
        MPSHostBoundary.refuseGPUEncode("MPSImageHistogramSpecification.encodeTransform")
    }
}

open class MPSImageScale: MPSUnaryImageKernel {
    private var transformPointer: UnsafeMutablePointer<MPSScaleTransform>?

    public var scaleTransform: UnsafePointer<MPSScaleTransform>? {
        get { transformPointer.map { UnsafePointer($0) } }
        set {
            transformPointer?.deinitialize(count: 1)
            transformPointer?.deallocate()
            transformPointer = nil
            if let incoming = newValue {
                let pointer = UnsafeMutablePointer<MPSScaleTransform>.allocate(capacity: 1)
                pointer.initialize(to: incoming.pointee)
                transformPointer = pointer
            }
        }
    }

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    deinit {
        transformPointer?.deinitialize(count: 1)
        transformPointer?.deallocate()
    }
}

open class MPSImageLanczosScale: MPSImageScale {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUScale(
            source: sourceImage,
            destination: destinationImage,
            transform: scaleTransform?.pointee,
            mode: .lanczos,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageBilinearScale: MPSImageScale {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUScale(
            source: sourceImage,
            destination: destinationImage,
            transform: scaleTransform?.pointee,
            mode: .bilinear,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageThresholdBinary: MPSUnaryImageKernel {
    public private(set) var thresholdValue: Float
    public private(set) var maximumValue: Float
    private let transformStorage: MPSColorTransformStorage

    public var transform: UnsafePointer<Float> {
        UnsafePointer(transformStorage.pointer)
    }

    public required init(device: any MTLDevice) {
        self.thresholdValue = 0
        self.maximumValue = 1
        self.transformStorage = MPSColorTransformStorage(nil)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        thresholdValue: Float,
        maximumValue: Float,
        linearGrayColorTransform transform: UnsafePointer<Float>?
    ) {
        self.thresholdValue = thresholdValue
        self.maximumValue = maximumValue
        self.transformStorage = MPSColorTransformStorage(transform)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUThreshold(
            source: sourceImage,
            destination: destinationImage,
            thresholdValue: thresholdValue,
            maximumValue: maximumValue,
            transform: transformStorage.pointer,
            mode: .binary,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageThresholdBinaryInverse: MPSUnaryImageKernel {
    public private(set) var thresholdValue: Float
    public private(set) var maximumValue: Float
    private let transformStorage: MPSColorTransformStorage

    public var transform: UnsafePointer<Float> {
        UnsafePointer(transformStorage.pointer)
    }

    public required init(device: any MTLDevice) {
        self.thresholdValue = 0
        self.maximumValue = 1
        self.transformStorage = MPSColorTransformStorage(nil)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        thresholdValue: Float,
        maximumValue: Float,
        linearGrayColorTransform transform: UnsafePointer<Float>?
    ) {
        self.thresholdValue = thresholdValue
        self.maximumValue = maximumValue
        self.transformStorage = MPSColorTransformStorage(transform)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageThresholdToZero: MPSUnaryImageKernel {
    public private(set) var thresholdValue: Float
    private let transformStorage: MPSColorTransformStorage

    public var transform: UnsafePointer<Float> {
        UnsafePointer(transformStorage.pointer)
    }

    public required init(device: any MTLDevice) {
        self.thresholdValue = 0
        self.transformStorage = MPSColorTransformStorage(nil)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        thresholdValue: Float,
        linearGrayColorTransform transform: UnsafePointer<Float>?
    ) {
        self.thresholdValue = thresholdValue
        self.transformStorage = MPSColorTransformStorage(transform)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUThreshold(
            source: sourceImage,
            destination: destinationImage,
            thresholdValue: thresholdValue,
            maximumValue: 1,
            transform: transformStorage.pointer,
            mode: .toZero,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageThresholdTruncate: MPSUnaryImageKernel {
    public private(set) var thresholdValue: Float
    private let transformStorage: MPSColorTransformStorage

    public var transform: UnsafePointer<Float> {
        UnsafePointer(transformStorage.pointer)
    }

    public required init(device: any MTLDevice) {
        self.thresholdValue = 0
        self.transformStorage = MPSColorTransformStorage(nil)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        thresholdValue: Float,
        linearGrayColorTransform transform: UnsafePointer<Float>?
    ) {
        self.thresholdValue = thresholdValue
        self.transformStorage = MPSColorTransformStorage(transform)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUThreshold(
            source: sourceImage,
            destination: destinationImage,
            thresholdValue: thresholdValue,
            maximumValue: 1,
            transform: transformStorage.pointer,
            mode: .truncate,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageAreaMax: MPSUnaryImageKernel {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int

    public required init(device: any MTLDevice) {
        self.kernelWidth = 1
        self.kernelHeight = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUAreaExtrema(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            findMax: true,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageAreaMin: MPSImageAreaMax {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUAreaExtrema(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            findMax: false,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageConvolution: MPSUnaryImageKernel {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int
    public var bias: Float = 0
    private let weights: [Float]

    public required init(device: any MTLDevice) {
        self.kernelWidth = 1
        self.kernelHeight = 1
        self.weights = [1]
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        weights kernelWeights: UnsafePointer<Float>
    ) {
        let width = max(kernelWidth, 1)
        let height = max(kernelHeight, 1)
        self.kernelWidth = width
        self.kernelHeight = height
        self.weights = (0..<(width * height)).map { kernelWeights[$0] }
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUConvolve(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            weights: weights,
            bias: bias,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageMedian: MPSUnaryImageKernel {
    public private(set) var kernelDiameter: Int

    public class func maxKernelDiameter() -> Int { 9 }
    public class func minKernelDiameter() -> Int { 3 }

    public required init(device: any MTLDevice) {
        self.kernelDiameter = 3
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelDiameter: Int) {
        let clamped = max(Self.minKernelDiameter(), min(kernelDiameter, Self.maxKernelDiameter()))
        self.kernelDiameter = clamped % 2 == 0 ? clamped + 1 : clamped
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUMedian(
            source: sourceImage,
            destination: destinationImage,
            kernelDiameter: kernelDiameter,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageTranspose: MPSUnaryImageKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUTranspose(source: sourceImage, destination: destinationImage)
    }
}

open class MPSImageArithmetic: MPSBinaryImageKernel {
    public var primaryScale: Float = 1
    public var secondaryScale: Float = 1
    public var bias: Float = 0
    public var minimumValue: Float = -.greatestFiniteMagnitude
    public var maximumValue: Float = .greatestFiniteMagnitude
    public var primaryStrideInPixels: MTLSize = MTLSize(width: 1, height: 1, depth: 1)
    public var secondaryStrideInPixels: MTLSize = MTLSize(width: 1, height: 1, depth: 1)

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    func applyArithmetic(_ a: Float, _ b: Float) -> Float {
        a * primaryScale + b * secondaryScale + bias
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUArithmetic(
            primary: primaryImage,
            secondary: secondaryImage,
            destination: destinationImage,
            combine: { applyArithmetic($0, $1) },
            minimumValue: minimumValue,
            maximumValue: maximumValue
        )
    }
}

open class MPSImageAdd: MPSImageArithmetic {
    public required init(device: any MTLDevice) {
        super.init(device: device)
        primaryScale = 1
        secondaryScale = 1
    }

    override func applyArithmetic(_ a: Float, _ b: Float) -> Float {
        a * primaryScale + b * secondaryScale + bias
    }
}

open class MPSImageSubtract: MPSImageArithmetic {
    public required init(device: any MTLDevice) {
        super.init(device: device)
        primaryScale = 1
        secondaryScale = -1
    }
}

open class MPSImageMultiply: MPSImageArithmetic {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    override func applyArithmetic(_ a: Float, _ b: Float) -> Float {
        a * primaryScale * b * secondaryScale + bias
    }
}

open class MPSImageDivide: MPSImageArithmetic {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    override func applyArithmetic(_ a: Float, _ b: Float) -> Float {
        let denom = b * secondaryScale
        if denom == 0 { return maximumValue }
        return (a * primaryScale) / denom + bias
    }
}

open class MPSImageDilate: MPSUnaryImageKernel {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int
    let values: [Float]

    public required init(device: any MTLDevice) {
        self.kernelWidth = 1
        self.kernelHeight = 1
        self.values = [0]
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        values: UnsafePointer<Float>
    ) {
        let width = max(kernelWidth, 1)
        let height = max(kernelHeight, 1)
        self.kernelWidth = width
        self.kernelHeight = height
        self.values = (0..<(width * height)).map { values[$0] }
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUMorphology(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            values: values,
            dilate: true,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageErode: MPSImageDilate {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        values: UnsafePointer<Float>
    ) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight, values: values)
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCPUMorphology(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            values: values,
            dilate: false,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImageIntegral: MPSUnaryImageKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageIntegralOfSquares: MPSUnaryImageKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageLaplacian: MPSUnaryImageKernel {
    public var bias: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        let kernel: [Float] = [
            0, -1, 0,
            -1, 4, -1,
            0, -1, 0
        ]
        mpsCPUConvolve(
            source: sourceImage,
            destination: destinationImage,
            kernelWidth: 3,
            kernelHeight: 3,
            weights: kernel,
            bias: bias,
            edgeMode: edgeMode,
            offset: offset,
            clipRect: clipRect
        )
    }
}

open class MPSImagePyramid: MPSUnaryImageKernel {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int
    private let weights: [Float]

    public required init(device: any MTLDevice) {
        self.kernelWidth = 5
        self.kernelHeight = 5
        self.weights = Array(repeating: 0.04, count: 25)
        super.init(device: device)
    }

    public convenience init(device: any MTLDevice, centerWeight: Float) {
        var kernel = Array(repeating: Float(0), count: 25)
        kernel[12] = centerWeight
        self.init(device: device, kernelWidth: 5, kernelHeight: 5, weights: &kernel)
    }

    public init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        weights kernelWeights: UnsafePointer<Float>
    ) {
        let width = max(kernelWidth, 1)
        let height = max(kernelHeight, 1)
        self.kernelWidth = width
        self.kernelHeight = height
        self.weights = (0..<(width * height)).map { kernelWeights[$0] }
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageGaussianPyramid: MPSImagePyramid {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageLaplacianPyramid: MPSImagePyramid {
    public var laplacianBias: Float = 0
    public var laplacianScale: Float = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageLaplacianPyramidAdd: MPSImageLaplacianPyramid {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageLaplacianPyramidSubtract: MPSImageLaplacianPyramid {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceUnary: MPSUnaryImageKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceRowMin: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceRowMax: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceRowMean: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceRowSum: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceColumnMin: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceColumnMax: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceColumnMean: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageReduceColumnSum: MPSImageReduceUnary {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

open class MPSImageStatisticsMean: MPSUnaryImageKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageStatisticsMeanAndVariance: MPSUnaryImageKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageStatisticsMinAndMax: MPSUnaryImageKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageThresholdToZeroInverse: MPSUnaryImageKernel {
    public private(set) var thresholdValue: Float
    private let transformStorage: MPSColorTransformStorage

    public var transform: UnsafePointer<Float> {
        UnsafePointer(transformStorage.pointer)
    }

    public required init(device: any MTLDevice) {
        self.thresholdValue = 0
        self.transformStorage = MPSColorTransformStorage(nil)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        thresholdValue: Float,
        linearGrayColorTransform transform: UnsafePointer<Float>?
    ) {
        self.thresholdValue = thresholdValue
        self.transformStorage = MPSColorTransformStorage(transform)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSImageCanny: MPSUnaryImageKernel {
    public private(set) var sigma: Float
    public var highThreshold: Float = 0.8
    public var lowThreshold: Float = 0.4
    public var useFastMode: Bool = false
    private let transformPointer: UnsafeMutablePointer<Float>

    public var colorTransform: UnsafePointer<Float> {
        UnsafePointer(transformPointer)
    }

    public required init(device: any MTLDevice) {
        self.sigma = 1
        self.transformPointer = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        self.transformPointer[0] = 0.299
        self.transformPointer[1] = 0.587
        self.transformPointer[2] = 0.114
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        linearToGrayScaleTransform transform: UnsafePointer<Float>,
        sigma: Float
    ) {
        self.sigma = sigma
        self.transformPointer = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        self.transformPointer[0] = transform[0]
        self.transformPointer[1] = transform[1]
        self.transformPointer[2] = transform[2]
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    deinit {
        transformPointer.deallocate()
    }
}

open class MPSImageFindKeypoints: MPSKernel {
    public private(set) var keypointRangeInfo: MPSImageKeypointRangeInfo

    public required init(device: any MTLDevice) {
        self.keypointRangeInfo = MPSImageKeypointRangeInfo()
        super.init(device: device)
    }

    public init(device: any MTLDevice, info: UnsafePointer<MPSImageKeypointRangeInfo>) {
        self.keypointRangeInfo = info.pointee
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture source: any MTLTexture,
        regions: UnsafePointer<MTLRegion>,
        numberOfRegions: Int,
        keypointCountBuffer: any MTLBuffer,
        keypointCountBufferOffset: Int,
        keypointDataBuffer: any MTLBuffer,
        keypointDataBufferOffset: Int
    ) {
        _ = (
            commandBuffer, source, regions, numberOfRegions, keypointCountBuffer,
            keypointCountBufferOffset, keypointDataBuffer, keypointDataBufferOffset
        )
        MPSHostBoundary.refuseGPUEncode("MPSImageFindKeypoints.encode")
    }
}

func mpsReadUnorm8(_ image: MPSImage) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: max(image.width * image.height * image.featureChannels, 0))
    pixels.withUnsafeMutableBytes { raw in
        image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    return pixels
}

func mpsWriteUnorm8(_ image: MPSImage, _ pixels: [UInt8]) {
    pixels.withUnsafeBytes { raw in
        image.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
}

func mpsSampleUnorm8(
    _ pixels: [UInt8],
    width: Int,
    height: Int,
    channels: Int,
    x: Int,
    y: Int,
    channel: Int,
    edgeMode: MPSImageEdgeMode
) -> Float {
    var sx = x
    var sy = y
    switch edgeMode {
    case .zero:
        if x < 0 || y < 0 || x >= width || y >= height { return 0 }
    case .clamp, .constant:
        sx = min(max(x, 0), width - 1)
        sy = min(max(y, 0), height - 1)
    case .mirror, .mirrorWithEdge:
        sx = mpsMirrorIndex(x, width)
        sy = mpsMirrorIndex(y, height)
    }
    let index = (sy * width + sx) * channels + channel
    guard pixels.indices.contains(index) else { return 0 }
    return Float(pixels[index]) / 255
}

func mpsMirrorIndex(_ value: Int, _ length: Int) -> Int {
    if length <= 1 { return 0 }
    let period = 2 * (length - 1)
    var wrapped = value % period
    if wrapped < 0 { wrapped += period }
    if wrapped >= length { wrapped = period - wrapped }
    return wrapped
}

enum MPSCPUThresholdMode {
    case binary
    case toZero
    case truncate
}

enum MPSCPUScaleMode {
    case bilinear
    case lanczos
}

func mpsQuantizeUnorm8(_ value: Float) -> UInt8 {
    UInt8((min(max(value, 0), 1) * 255).rounded())
}

func mpsClipBounds(clipRect: MTLRegion, width: Int, height: Int) -> (Int, Int, Int, Int) {
    if clipRect.size.width >= Int.max / 4 || clipRect.size.height >= Int.max / 4 {
        return (0, 0, width, height)
    }
    let x0 = max(clipRect.origin.x, 0)
    let y0 = max(clipRect.origin.y, 0)
    let x1 = min(clipRect.origin.x + clipRect.size.width, width)
    let y1 = min(clipRect.origin.y + clipRect.size.height, height)
    return (x0, y0, max(x0, x1), max(y0, y1))
}

func mpsSourceCoord(destX: Int, destY: Int, offset: MPSOffset, clipRect: MTLRegion) -> (Int, Int) {
    let clipX = clipRect.size.width >= Int.max / 4 ? 0 : clipRect.origin.x
    let clipY = clipRect.size.height >= Int.max / 4 ? 0 : clipRect.origin.y
    return (destX - clipX + offset.x, destY - clipY + offset.y)
}

func mpsCPUSeparableGaussian(
    source: MPSImage,
    destination: MPSImage,
    sigma: Float,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset = MPSOffset(),
    clipRect: MTLRegion = MPSRectNoClip
) {
    let radius = max(Int(ceil(Double(abs(sigma)) * 3)), 1)
    var weights = [Float](repeating: 0, count: radius * 2 + 1)
    var sum: Float = 0
    let twoSigmaSq = max(2 * sigma * sigma, 0.0001)
    for i in -radius...radius {
        let w = exp(-Float(i * i) / twoSigmaSq)
        weights[i + radius] = w
        sum += w
    }
    for i in weights.indices { weights[i] /= sum }
    let intermediate = MPSImage(
        device: source.device,
        imageDescriptor: MPSImageDescriptor(
            channelFormat: source.featureChannelFormat,
            width: source.width,
            height: source.height,
            featureChannels: source.featureChannels
        )
    )
    mpsCPUConvolve(
        source: source,
        destination: intermediate,
        kernelWidth: weights.count,
        kernelHeight: 1,
        weights: weights,
        bias: 0,
        edgeMode: edgeMode,
        offset: offset,
        clipRect: clipRect
    )
    mpsCPUConvolve(
        source: intermediate,
        destination: destination,
        kernelWidth: 1,
        kernelHeight: weights.count,
        weights: weights,
        bias: 0,
        edgeMode: edgeMode
    )
}

func mpsCPUBox(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset = MPSOffset(),
    clipRect: MTLRegion = MPSRectNoClip
) {
    let count = max(kernelWidth * kernelHeight, 1)
    let weights = [Float](repeating: 1 / Float(count), count: count)
    mpsCPUConvolve(
        source: source,
        destination: destination,
        kernelWidth: kernelWidth,
        kernelHeight: kernelHeight,
        weights: weights,
        bias: 0,
        edgeMode: edgeMode,
        offset: offset,
        clipRect: clipRect
    )
}

func mpsTent1D(_ length: Int) -> [Float] {
    let n = max(length, 1)
    let radius = n / 2
    var weights = [Float](repeating: 0, count: n)
    var sum: Float = 0
    for i in 0..<n {
        let w = Float(radius + 1 - abs(i - radius))
        weights[i] = max(w, 0)
        sum += weights[i]
    }
    if sum > 0 {
        for i in weights.indices { weights[i] /= sum }
    }
    return weights
}

func mpsCPUTent(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let wx = mpsTent1D(kernelWidth)
    let wy = mpsTent1D(kernelHeight)
    var kernel = [Float](repeating: 0, count: kernelWidth * kernelHeight)
    for y in 0..<kernelHeight {
        for x in 0..<kernelWidth {
            kernel[y * kernelWidth + x] = wy[y] * wx[x]
        }
    }
    mpsCPUConvolve(
        source: source,
        destination: destination,
        kernelWidth: kernelWidth,
        kernelHeight: kernelHeight,
        weights: kernel,
        bias: 0,
        edgeMode: edgeMode,
        offset: offset,
        clipRect: clipRect
    )
}

func mpsCPUConvolve(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    weights: [Float],
    bias: Float,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset = MPSOffset(),
    clipRect: MTLRegion = MPSRectNoClip
) {
    let width = destination.width
    let height = destination.height
    let channels = min(source.featureChannels, destination.featureChannels)
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    if dst.count < width * height * destination.featureChannels {
        dst = [UInt8](repeating: 0, count: width * height * destination.featureChannels)
    }
    let ox = kernelWidth / 2
    let oy = kernelHeight / 2
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx0, sy0) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            for c in 0..<channels {
                var acc = bias
                for ky in 0..<kernelHeight {
                    for kx in 0..<kernelWidth {
                        let weight = weights[ky * kernelWidth + kx]
                        let sample = mpsSampleUnorm8(
                            src,
                            width: source.width,
                            height: source.height,
                            channels: source.featureChannels,
                            x: sx0 + kx - ox,
                            y: sy0 + ky - oy,
                            channel: c,
                            edgeMode: edgeMode
                        )
                        acc += weight * sample
                    }
                }
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(acc)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsGray(
    _ pixels: [UInt8],
    width: Int,
    height: Int,
    channels: Int,
    x: Int,
    y: Int,
    transform: UnsafePointer<Float>,
    edgeMode: MPSImageEdgeMode
) -> Float {
    if channels <= 1 {
        return mpsSampleUnorm8(pixels, width: width, height: height, channels: channels, x: x, y: y, channel: 0, edgeMode: edgeMode)
    }
    let r = mpsSampleUnorm8(pixels, width: width, height: height, channels: channels, x: x, y: y, channel: 0, edgeMode: edgeMode)
    let g = mpsSampleUnorm8(pixels, width: width, height: height, channels: channels, x: x, y: y, channel: 1, edgeMode: edgeMode)
    let b = mpsSampleUnorm8(pixels, width: width, height: height, channels: channels, x: x, y: y, channel: min(2, channels - 1), edgeMode: edgeMode)
    return r * transform[0] + g * transform[1] + b * transform[2]
}

func mpsCPUSobel(
    source: MPSImage,
    destination: MPSImage,
    transform: UnsafePointer<Float>,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    let gxk: [Float] = [-1, 0, 1, -2, 0, 2, -1, 0, 1]
    let gyk: [Float] = [-1, -2, -1, 0, 0, 0, 1, 2, 1]
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx0, sy0) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            var gx: Float = 0
            var gy: Float = 0
            for ky in 0..<3 {
                for kx in 0..<3 {
                    let sample = mpsGray(
                        src,
                        width: source.width,
                        height: source.height,
                        channels: source.featureChannels,
                        x: sx0 + kx - 1,
                        y: sy0 + ky - 1,
                        transform: transform,
                        edgeMode: edgeMode
                    )
                    gx += gxk[ky * 3 + kx] * sample
                    gy += gyk[ky * 3 + kx] * sample
                }
            }
            let mag = min(sqrt(gx * gx + gy * gy), 1)
            for c in 0..<destination.featureChannels {
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(mag)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUThreshold(
    source: MPSImage,
    destination: MPSImage,
    thresholdValue: Float,
    maximumValue: Float,
    transform: UnsafePointer<Float>,
    mode: MPSCPUThresholdMode,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx, sy) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            let gray = mpsGray(
                src,
                width: source.width,
                height: source.height,
                channels: source.featureChannels,
                x: sx,
                y: sy,
                transform: transform,
                edgeMode: edgeMode
            )
            var out: Float = 0
            switch mode {
            case .binary:
                out = gray >= thresholdValue ? maximumValue : 0
            case .toZero:
                out = gray >= thresholdValue ? gray : 0
            case .truncate:
                out = min(gray, thresholdValue)
            }
            for c in 0..<destination.featureChannels {
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(out)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUMedian(
    source: MPSImage,
    destination: MPSImage,
    kernelDiameter: Int,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let radius = kernelDiameter / 2
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    var window = [Float]()
    window.reserveCapacity(kernelDiameter * kernelDiameter)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx0, sy0) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            for c in 0..<min(source.featureChannels, destination.featureChannels) {
                window.removeAll(keepingCapacity: true)
                for ky in -radius...radius {
                    for kx in -radius...radius {
                        window.append(
                            mpsSampleUnorm8(
                                src,
                                width: source.width,
                                height: source.height,
                                channels: source.featureChannels,
                                x: sx0 + kx,
                                y: sy0 + ky,
                                channel: c,
                                edgeMode: edgeMode
                            )
                        )
                    }
                }
                window.sort()
                let mid = window[window.count / 2]
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(mid)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUAreaExtrema(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    findMax: Bool,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let ox = kernelWidth / 2
    let oy = kernelHeight / 2
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx0, sy0) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            for c in 0..<min(source.featureChannels, destination.featureChannels) {
                var acc: Float = findMax ? -1 : 2
                for ky in 0..<kernelHeight {
                    for kx in 0..<kernelWidth {
                        let sample = mpsSampleUnorm8(
                            src,
                            width: source.width,
                            height: source.height,
                            channels: source.featureChannels,
                            x: sx0 + kx - ox,
                            y: sy0 + ky - oy,
                            channel: c,
                            edgeMode: edgeMode
                        )
                        acc = findMax ? max(acc, sample) : min(acc, sample)
                    }
                }
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(acc)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUMorphology(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    values: [Float],
    dilate: Bool,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let ox = kernelWidth / 2
    let oy = kernelHeight / 2
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx0, sy0) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            for c in 0..<min(source.featureChannels, destination.featureChannels) {
                var acc: Float = dilate ? -Float.greatestFiniteMagnitude : Float.greatestFiniteMagnitude
                for ky in 0..<kernelHeight {
                    for kx in 0..<kernelWidth {
                        let probe = values[ky * kernelWidth + kx]
                        let sample = mpsSampleUnorm8(
                            src,
                            width: source.width,
                            height: source.height,
                            channels: source.featureChannels,
                            x: sx0 + kx - ox,
                            y: sy0 + ky - oy,
                            channel: c,
                            edgeMode: edgeMode
                        )
                        if dilate {
                            acc = max(acc, sample - probe)
                        } else {
                            acc = min(acc, sample + probe)
                        }
                    }
                }
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(acc)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsLanczos2(_ x: Float) -> Float {
    let ax = abs(x)
    if ax < 0.0001 { return 1 }
    if ax >= 2 { return 0 }
    let pi = Float.pi
    return (sin(pi * ax) / (pi * ax)) * (sin(pi * ax / 2) / (pi * ax / 2))
}

func mpsCPUScale(
    source: MPSImage,
    destination: MPSImage,
    transform: MPSScaleTransform?,
    mode: MPSCPUScaleMode,
    edgeMode: MPSImageEdgeMode,
    offset: MPSOffset,
    clipRect: MTLRegion
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let scaleX = Float(transform?.scaleX ?? Double(source.width) / Double(max(width, 1)))
    let scaleY = Float(transform?.scaleY ?? Double(source.height) / Double(max(height, 1)))
    let translateX = Float(transform?.translateX ?? 0)
    let translateY = Float(transform?.translateY ?? 0)
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (dx, dy) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            let srcXf = (Float(dx) + 0.5) * scaleX + Float(translateX) - 0.5
            let srcYf = (Float(dy) + 0.5) * scaleY + Float(translateY) - 0.5
            for c in 0..<min(source.featureChannels, destination.featureChannels) {
                var acc: Float = 0
                if mode == .bilinear {
                    let x0s = Int(floor(srcXf))
                    let y0s = Int(floor(srcYf))
                    let fx = srcXf - Float(x0s)
                    let fy = srcYf - Float(y0s)
                    let s00 = mpsSampleUnorm8(src, width: source.width, height: source.height, channels: source.featureChannels, x: x0s, y: y0s, channel: c, edgeMode: edgeMode)
                    let s10 = mpsSampleUnorm8(src, width: source.width, height: source.height, channels: source.featureChannels, x: x0s + 1, y: y0s, channel: c, edgeMode: edgeMode)
                    let s01 = mpsSampleUnorm8(src, width: source.width, height: source.height, channels: source.featureChannels, x: x0s, y: y0s + 1, channel: c, edgeMode: edgeMode)
                    let s11 = mpsSampleUnorm8(src, width: source.width, height: source.height, channels: source.featureChannels, x: x0s + 1, y: y0s + 1, channel: c, edgeMode: edgeMode)
                    let top = s00 * (1 - fx) + s10 * fx
                    let bottom = s01 * (1 - fx) + s11 * fx
                    acc = top * (1 - fy) + bottom * fy
                } else {
                    var weightSum: Float = 0
                    let ix = Int(floor(srcXf))
                    let iy = Int(floor(srcYf))
                    for ky in (iy - 1)...(iy + 2) {
                        for kx in (ix - 1)...(ix + 2) {
                            let w = mpsLanczos2(srcXf - Float(kx)) * mpsLanczos2(srcYf - Float(ky))
                            acc += w * mpsSampleUnorm8(
                                src,
                                width: source.width,
                                height: source.height,
                                channels: source.featureChannels,
                                x: kx,
                                y: ky,
                                channel: c,
                                edgeMode: edgeMode
                            )
                            weightSum += w
                        }
                    }
                    if weightSum != 0 { acc /= weightSum }
                }
                dst[(y * width + x) * destination.featureChannels + c] = mpsQuantizeUnorm8(acc)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsHistogramEqualizationLUT(counts: UnsafePointer<UInt32>, entries: Int, channelCount: Int = 4) -> [UInt8] {
    let channels = min(max(channelCount, 1), 4)
    var lut = [UInt8](repeating: 0, count: max(entries, 1) * 4)
    for channel in 0..<channels {
        var total: UInt64 = 0
        for i in 0..<entries {
            total += UInt64(counts[channel * entries + i])
        }
        if total == 0 { continue }
        var cdf: UInt64 = 0
        for i in 0..<entries {
            cdf += UInt64(counts[channel * entries + i])
            let mapped = (Double(cdf) / Double(total)) * 255
            lut[channel * entries + i] = UInt8(min(max(mapped.rounded(), 0), 255))
        }
    }
    return lut
}

func mpsCPUApplyLUT(
    source: MPSImage,
    destination: MPSImage,
    lut: [UInt8],
    offset: MPSOffset,
    clipRect: MTLRegion,
    edgeMode: MPSImageEdgeMode
) {
    let src = mpsReadUnorm8(source)
    var dst = mpsReadUnorm8(destination)
    let width = destination.width
    let height = destination.height
    let entries = max(lut.count / 4, 1)
    let (x0, y0, x1, y1) = mpsClipBounds(clipRect: clipRect, width: width, height: height)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let (sx, sy) = mpsSourceCoord(destX: x, destY: y, offset: offset, clipRect: clipRect)
            for c in 0..<min(source.featureChannels, destination.featureChannels) {
                let sample = mpsSampleUnorm8(
                    src,
                    width: source.width,
                    height: source.height,
                    channels: source.featureChannels,
                    x: sx,
                    y: sy,
                    channel: c,
                    edgeMode: edgeMode
                )
                let value = mpsQuantizeUnorm8(sample)
                let bin = min(Int(value) * entries / 256, entries - 1)
                let mapped = lut.isEmpty ? value : lut[min(c, 3) * entries + bin]
                dst[(y * width + x) * destination.featureChannels + c] = mapped
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUTranspose(source: MPSImage, destination: MPSImage) {
    let src = mpsReadUnorm8(source)
    var dst = [UInt8](repeating: 0, count: destination.width * destination.height * destination.featureChannels)
    let channels = min(source.featureChannels, destination.featureChannels)
    for y in 0..<source.height {
        for x in 0..<source.width {
            for c in 0..<channels {
                if x < destination.height && y < destination.width {
                    dst[(x * destination.width + y) * destination.featureChannels + c] =
                        src[(y * source.width + x) * source.featureChannels + c]
                }
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUArithmetic(
    primary: MPSImage,
    secondary: MPSImage,
    destination: MPSImage,
    combine: (Float, Float) -> Float,
    minimumValue: Float,
    maximumValue: Float
) {
    let a = mpsReadUnorm8(primary)
    let b = mpsReadUnorm8(secondary)
    let width = min(primary.width, min(secondary.width, destination.width))
    let height = min(primary.height, min(secondary.height, destination.height))
    let channels = min(primary.featureChannels, min(secondary.featureChannels, destination.featureChannels))
    var dst = [UInt8](repeating: 0, count: destination.width * destination.height * destination.featureChannels)
    for y in 0..<height {
        for x in 0..<width {
            for c in 0..<channels {
                let av = Float(a[(y * primary.width + x) * primary.featureChannels + c]) / 255
                let bv = Float(b[(y * secondary.width + x) * secondary.featureChannels + c]) / 255
                let value = min(max(combine(av, bv), minimumValue), maximumValue)
                let clamped = min(max(value, 0), 1)
                dst[(y * destination.width + x) * destination.featureChannels + c] = UInt8(clamped * 255)
            }
        }
    }
    mpsWriteUnorm8(destination, dst)
}

func mpsCPUHistogram(
    source: any MTLTexture,
    histogram: any MTLBuffer,
    histogramOffset: Int,
    info: MPSImageHistogramInfo,
    zeroHistogram: Bool
) {
    let entries = max(info.numberOfHistogramEntries, 1)
    let bins = entries * 4
    let dest = histogram.contents.advanced(by: histogramOffset).bindMemory(to: UInt32.self, capacity: bins)
    if zeroHistogram {
        for i in 0..<bins { dest[i] = 0 }
    }
    guard let host = source as? MPSHostTexture else { return }
    let bytes = host.bytes
    let width = host.width
    let height = host.height
    let channels = min(mpsHostBytesPerPixel(host.pixelFormat), 4)
    bytes.withUnsafeBytes { raw in
        guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return }
        for y in 0..<height {
            for x in 0..<width {
                for c in 0..<channels {
                    if c == 3 && !info.histogramForAlpha.boolValue { continue }
                    let value = base[(y * width + x) * channels + c]
                    let bin = min(Int(value) * entries / 256, entries - 1)
                    dest[c * entries + bin] += 1
                }
            }
        }
    }
}
