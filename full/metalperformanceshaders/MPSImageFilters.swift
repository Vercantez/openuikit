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
        mpsCPUSeparableGaussian(source: sourceImage, destination: destinationImage, sigma: sigma, edgeMode: edgeMode)
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
        mpsCPUBox(source: sourceImage, destination: destinationImage, kernelWidth: kernelWidth, kernelHeight: kernelHeight, edgeMode: edgeMode)
    }
}

open class MPSImageTent: MPSImageBox {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
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
        _ = (commandBuffer, source, histogram, histogramOffset)
        MPSHostBoundary.refuseGPUEncode("MPSImageHistogramEqualization.encodeTransform")
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
}

open class MPSImageBilinearScale: MPSImageScale {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
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
}

open class MPSImageAreaMin: MPSImageAreaMax {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight)
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
            edgeMode: edgeMode
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
    private let values: [Float]

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

func mpsCPUSeparableGaussian(source: MPSImage, destination: MPSImage, sigma: Float, edgeMode: MPSImageEdgeMode) {
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
    mpsCPUConvolve(
        source: source,
        destination: destination,
        kernelWidth: weights.count,
        kernelHeight: 1,
        weights: weights,
        bias: 0,
        edgeMode: edgeMode
    )
}

func mpsCPUBox(source: MPSImage, destination: MPSImage, kernelWidth: Int, kernelHeight: Int, edgeMode: MPSImageEdgeMode) {
    let count = max(kernelWidth * kernelHeight, 1)
    let weights = [Float](repeating: 1 / Float(count), count: count)
    mpsCPUConvolve(
        source: source,
        destination: destination,
        kernelWidth: kernelWidth,
        kernelHeight: kernelHeight,
        weights: weights,
        bias: 0,
        edgeMode: edgeMode
    )
}

func mpsCPUConvolve(
    source: MPSImage,
    destination: MPSImage,
    kernelWidth: Int,
    kernelHeight: Int,
    weights: [Float],
    bias: Float,
    edgeMode: MPSImageEdgeMode
) {
    let width = source.width
    let height = source.height
    let channels = source.featureChannels
    let src = mpsReadUnorm8(source)
    var dst = [UInt8](repeating: 0, count: width * height * channels)
    let ox = kernelWidth / 2
    let oy = kernelHeight / 2
    for y in 0..<height {
        for x in 0..<width {
            for c in 0..<channels {
                var acc = bias
                for ky in 0..<kernelHeight {
                    for kx in 0..<kernelWidth {
                        let weight = weights[ky * kernelWidth + kx]
                        let sample = mpsSampleUnorm8(
                            src,
                            width: width,
                            height: height,
                            channels: channels,
                            x: x + kx - ox,
                            y: y + ky - oy,
                            channel: c,
                            edgeMode: edgeMode
                        )
                        acc += weight * sample
                    }
                }
                let value = min(max(acc, 0), 1)
                dst[(y * width + x) * channels + c] = UInt8(value * 255)
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
