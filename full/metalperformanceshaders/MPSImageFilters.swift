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
        _ = (commandBuffer, source, histogram, histogramOffset)
        MPSHostBoundary.refuseGPUEncode("MPSImageHistogram.encode")
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
