import Foundation

// MARK: - Wave 12 leftover host surface
//
// Every class below is constructable, validated host data. GPU `encode`
// paths refuse through `MPSHostBoundary` unless a host CPU implementation
// is provided and noted. Linux default values that Apple does not publish
// in the pinned overlay are documented per member.

private func mpsWave12Positive(_ value: Int) -> Int { max(value, 1) }

// MARK: - CoreGraphics stand-ins for MPSImageConversion
//
// The pinned `MPSImageConversion` initializer names `CGColorConversionInfo`,
// which does not exist in Swift Foundation on Linux, so this lane provides
// a minimal host spelling. (`CGFloat` already comes from Foundation on both
// platforms.) Neither carries color-conversion behavior; conversion encode
// stays fail-closed.

public final class CGColorConversionInfo: NSObject {
    public override init() { super.init() }
}

// MARK: - Batch-normalization statistics kernels

/// Batch-normalization statistics descriptor. Statistics gathering is a GPU
/// kernel, so batch encode stays fail-closed.
open class MPSCNNBatchNormalizationStatistics: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) {
        _ = (commandBuffer, sourceImages, batchNormalizationState)
        MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalizationStatistics.encodeBatch")
    }
}

/// Batch-normalization statistics-gradient descriptor. The gradient itself
/// is a GPU kernel, so batch encode stays fail-closed; the fused neuron
/// descriptor is validated host configuration.
open class MPSCNNBatchNormalizationStatisticsGradient: MPSCNNKernel {
    public private(set) var fusedNeuronDescriptor: MPSNNNeuronDescriptor?

    public required init(device: any MTLDevice) {
        self.fusedNeuronDescriptor = nil
        super.init(device: device)
    }

    public init(device: any MTLDevice, fusedNeuronDescriptor: MPSNNNeuronDescriptor?) {
        self.fusedNeuronDescriptor = fusedNeuronDescriptor
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) {
        _ = (commandBuffer, sourceGradients, sourceImages, batchNormalizationState)
        MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalizationStatisticsGradient.encodeBatch")
    }
}

/// Graph node carrying batch-normalization gradient wiring.
open class MPSCNNBatchNormalizationGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        super.init()
    }
}

// MARK: - Binary convolution and fully-connected kernels

/// Binary convolution descriptor. The binary GEMM itself is a GPU kernel,
/// so encode stays fail-closed through `MPSCNNKernel`; the data source,
/// binarization type, flags, and scale/bias configuration are validated
/// host data. Channel counts read through the data source descriptor.
open class MPSCNNBinaryConvolution: MPSCNNKernel {
    public private(set) var dataSource: any MPSCNNConvolutionDataSource
    public private(set) var binaryType: MPSCNNBinaryConvolutionType
    public private(set) var binaryFlags: MPSCNNBinaryConvolutionFlags
    public private(set) var scaleValue: Float

    public var inputFeatureChannels: Int {
        dataSource.descriptor().inputFeatureChannels
    }

    public var outputFeatureChannels: Int {
        dataSource.descriptor().outputFeatureChannels
    }

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostConvolutionDataSource.placeholder
        self.binaryType = .binaryWeights
        self.binaryFlags = .none
        self.scaleValue = 1
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        convolutionData: any MPSCNNConvolutionDataSource,
        outputBiasTerms: UnsafePointer<Float>?,
        outputScaleTerms: UnsafePointer<Float>?,
        inputBiasTerms: UnsafePointer<Float>?,
        inputScaleTerms: UnsafePointer<Float>?,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        _ = (outputBiasTerms, outputScaleTerms, inputBiasTerms, inputScaleTerms)
        _ = convolutionData.load()
        self.dataSource = convolutionData
        self.binaryType = type
        self.binaryFlags = flags
        self.scaleValue = 1
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        convolutionData: any MPSCNNConvolutionDataSource,
        scaleValue: Float,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        _ = convolutionData.load()
        self.dataSource = convolutionData
        self.binaryType = type
        self.binaryFlags = flags
        self.scaleValue = scaleValue
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Binary convolution graph node carrying binarization configuration.
open class MPSCNNBinaryConvolutionNode: MPSNNFilterNode {
    public private(set) var weights: any MPSCNNConvolutionDataSource
    public private(set) var binaryType: MPSCNNBinaryConvolutionType
    public private(set) var binaryFlags: MPSCNNBinaryConvolutionFlags
    public private(set) var scaleValue: Float

    public init(
        source sourceNode: MPSNNImageNode,
        weights: any MPSCNNConvolutionDataSource,
        outputBiasTerms: UnsafePointer<Float>?,
        outputScaleTerms: UnsafePointer<Float>?,
        inputBiasTerms: UnsafePointer<Float>?,
        inputScaleTerms: UnsafePointer<Float>?,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        _ = (sourceNode, outputBiasTerms, outputScaleTerms, inputBiasTerms, inputScaleTerms)
        self.weights = weights
        self.binaryType = type
        self.binaryFlags = flags
        self.scaleValue = 1
        super.init()
    }

    public init(
        source sourceNode: MPSNNImageNode,
        weights: any MPSCNNConvolutionDataSource,
        scaleValue: Float,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        _ = sourceNode
        self.weights = weights
        self.binaryType = type
        self.binaryFlags = flags
        self.scaleValue = scaleValue
        super.init()
    }
}

/// Binary fully-connected descriptor. Inherits the binary-convolution host
/// data and fail-closed encode; fully-connected geometry comes from the
/// data source descriptor.
open class MPSCNNBinaryFullyConnected: MPSCNNBinaryConvolution {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    public override init(
        device: any MTLDevice,
        convolutionData: any MPSCNNConvolutionDataSource,
        outputBiasTerms: UnsafePointer<Float>?,
        outputScaleTerms: UnsafePointer<Float>?,
        inputBiasTerms: UnsafePointer<Float>?,
        inputScaleTerms: UnsafePointer<Float>?,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        super.init(
            device: device,
            convolutionData: convolutionData,
            outputBiasTerms: outputBiasTerms,
            outputScaleTerms: outputScaleTerms,
            inputBiasTerms: inputBiasTerms,
            inputScaleTerms: inputScaleTerms,
            type: type,
            flags: flags
        )
    }

    public override init(
        device: any MTLDevice,
        convolutionData: any MPSCNNConvolutionDataSource,
        scaleValue: Float,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        super.init(
            device: device,
            convolutionData: convolutionData,
            scaleValue: scaleValue,
            type: type,
            flags: flags
        )
    }
}

/// Binary fully-connected graph node.
open class MPSCNNBinaryFullyConnectedNode: MPSCNNBinaryConvolutionNode {
    public override init(
        source sourceNode: MPSNNImageNode,
        weights: any MPSCNNConvolutionDataSource,
        outputBiasTerms: UnsafePointer<Float>?,
        outputScaleTerms: UnsafePointer<Float>?,
        inputBiasTerms: UnsafePointer<Float>?,
        inputScaleTerms: UnsafePointer<Float>?,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        super.init(
            source: sourceNode,
            weights: weights,
            outputBiasTerms: outputBiasTerms,
            outputScaleTerms: outputScaleTerms,
            inputBiasTerms: inputBiasTerms,
            inputScaleTerms: inputScaleTerms,
            type: type,
            flags: flags
        )
    }

    public override init(
        source sourceNode: MPSNNImageNode,
        weights: any MPSCNNConvolutionDataSource,
        scaleValue: Float,
        type: MPSCNNBinaryConvolutionType,
        flags: MPSCNNBinaryConvolutionFlags
    ) {
        super.init(
            source: sourceNode,
            weights: weights,
            scaleValue: scaleValue,
            type: type,
            flags: flags
        )
    }
}

// MARK: - Fully-connected kernels and nodes

/// Fully-connected descriptor. Convolution execute is a GPU kernel, so
/// encode stays fail-closed; weights and channel geometry are validated
/// host data inherited from `MPSCNNConvolution`.
open class MPSCNNFullyConnected: MPSCNNConvolution {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    public override init(
        device: any MTLDevice,
        convolutionDescriptor: MPSCNNConvolutionDescriptor,
        kernelWeights: UnsafePointer<Float>,
        biasTerms: UnsafePointer<Float>?,
        flags: MPSCNNConvolutionFlags
    ) {
        super.init(
            device: device,
            convolutionDescriptor: convolutionDescriptor,
            kernelWeights: kernelWeights,
            biasTerms: biasTerms,
            flags: flags
        )
    }

    public override init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        super.init(device: device, weights: weights)
    }
}

/// Fully-connected gradient descriptor. Gradient encode stays fail-closed;
/// the weight data source is validated host data.
open class MPSCNNFullyConnectedGradient: MPSCNNGradientKernel {
    public private(set) var weights: any MPSCNNConvolutionDataSource

    public required init(device: any MTLDevice) {
        self.weights = MPSCNNHostConvolutionDataSource.placeholder
        super.init(device: device)
    }

    public init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        _ = weights.load()
        self.weights = weights
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Fully-connected gradient graph node.
open class MPSCNNFullyConnectedGradientNode: MPSNNGradientFilterNode {
    public private(set) var weights: (any MPSCNNConvolutionDataSource)?

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        convolutionGradientState gradientState: MPSCNNConvolutionGradientStateNode,
        weights: (any MPSCNNConvolutionDataSource)?
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.weights = weights
        super.init()
    }
}

/// Fully-connected graph node.
open class MPSCNNFullyConnectedNode: MPSNNFilterNode {
    public private(set) var weights: any MPSCNNConvolutionDataSource

    public init(source sourceNode: MPSNNImageNode, weights: any MPSCNNConvolutionDataSource) {
        _ = sourceNode
        self.weights = weights
        super.init()
    }
}

/// Transpose-convolution graph node carrying its weights and optional
/// gradient state.
open class MPSCNNConvolutionTransposeNode: MPSNNFilterNode {
    public private(set) var weights: any MPSCNNConvolutionDataSource
    public private(set) var convolutionGradientState: MPSCNNConvolutionGradientStateNode?

    public init(
        source sourceNode: MPSNNImageNode,
        convolutionGradientState: MPSCNNConvolutionGradientStateNode?,
        weights: any MPSCNNConvolutionDataSource
    ) {
        _ = sourceNode
        self.convolutionGradientState = convolutionGradientState
        self.weights = weights
        super.init()
    }
}

// MARK: - Normalization nodes

/// Cross-channel normalization graph node. Normalization execute is a GPU
/// kernel; the kernel size is validated host configuration. The Apple
/// default kernel size is not in the pinned overlay; Linux starts at 5,
/// matching the spatial-normalization node default.
open class MPSCNNCrossChannelNormalizationNode: MPSNNFilterNode {
    public var kernelSizeInFeatureChannels: Int {
        get { storedKernelSize }
        set { storedKernelSize = mpsWave12Positive(newValue) }
    }
    private var storedKernelSize: Int

    public init(source sourceNode: MPSNNImageNode) {
        _ = sourceNode
        self.storedKernelSize = 5
        super.init()
    }

    public init(source sourceNode: MPSNNImageNode, kernelSize: Int) {
        _ = sourceNode
        self.storedKernelSize = mpsWave12Positive(kernelSize)
        super.init()
    }
}

/// Cross-channel normalization gradient graph node.
open class MPSCNNCrossChannelNormalizationGradientNode: MPSNNGradientFilterNode {
    public private(set) var kernelSize: Int

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode,
        kernelSize: Int
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.kernelSize = mpsWave12Positive(kernelSize)
        super.init()
    }
}

/// Local-contrast normalization graph node. Execute is a GPU kernel; the
/// alpha/beta/delta parameters are validated host configuration.
open class MPSCNNNormalizationNode: MPSNNFilterNode {
    public var alpha: Float = 1
    public var beta: Float = 0.5
    public var delta: Float = 1

    public init(source sourceNode: MPSNNImageNode) {
        _ = sourceNode
        super.init()
    }
}

/// Group-normalization graph node carrying its data source and training style.
open class MPSCNNGroupNormalizationNode: MPSNNFilterNode {
    public private(set) var dataSource: any MPSCNNGroupNormalizationDataSource
    public var trainingStyle: MPSNNTrainingStyle = .UpdateDeviceNone

    public init(source: MPSNNImageNode, dataSource: any MPSCNNGroupNormalizationDataSource) {
        _ = source
        self.dataSource = dataSource
        super.init()
    }
}

/// Group-normalization gradient descriptor. Encode stays fail-closed.
open class MPSCNNGroupNormalizationGradient: MPSCNNGradientKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Group-normalization gradient graph node.
open class MPSCNNGroupNormalizationGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        super.init()
    }
}

/// Instance-normalization graph node carrying its data source and training style.
open class MPSCNNInstanceNormalizationNode: MPSNNFilterNode {
    public private(set) var dataSource: any MPSCNNInstanceNormalizationDataSource
    public var trainingStyle: MPSNNTrainingStyle = .UpdateDeviceNone

    public init(source: MPSNNImageNode, dataSource: any MPSCNNInstanceNormalizationDataSource) {
        _ = source
        self.dataSource = dataSource
        super.init()
    }
}

/// Instance-normalization gradient descriptor. Encode stays fail-closed.
open class MPSCNNInstanceNormalizationGradient: MPSCNNGradientKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Instance-normalization gradient graph node.
open class MPSCNNInstanceNormalizationGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        super.init()
    }
}

// MARK: - Loss nodes

/// Loss graph node carrying its loss descriptor and label wiring.
open class MPSCNNLossNode: MPSNNFilterNode {
    public private(set) var lossDescriptor: MPSCNNLossDescriptor
    public private(set) var inputLabels: MPSNNLabelsNode

    public init(source: MPSNNImageNode, lossDescriptor descriptor: MPSCNNLossDescriptor) {
        _ = source
        self.lossDescriptor = descriptor
        self.inputLabels = MPSNNLabelsNode()
        super.init()
    }
}

/// YOLO loss graph node carrying its YOLO loss descriptor and label wiring.
open class MPSCNNYOLOLossNode: MPSNNFilterNode {
    public private(set) var lossDescriptor: MPSCNNYOLOLossDescriptor
    public private(set) var inputLabels: MPSNNLabelsNode

    public init(source: MPSNNImageNode, lossDescriptor descriptor: MPSCNNYOLOLossDescriptor) {
        _ = source
        self.lossDescriptor = descriptor
        self.inputLabels = MPSNNLabelsNode()
        super.init()
    }
}

// MARK: - Image conversion

/// Image conversion descriptor. Pixel conversion is a GPU kernel, so encode
/// stays fail-closed through `MPSUnaryImageKernel`; the alpha configuration
/// is validated host data.
open class MPSImageConversion: MPSUnaryImageKernel {
    public private(set) var sourceAlpha: MPSAlphaType
    public private(set) var destinationAlpha: MPSAlphaType

    public required init(device: any MTLDevice) {
        self.sourceAlpha = .alphaIsOne
        self.destinationAlpha = .alphaIsOne
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        srcAlpha: MPSAlphaType,
        destAlpha: MPSAlphaType,
        backgroundColor: UnsafeMutablePointer<CGFloat>?,
        conversionInfo: CGColorConversionInfo?
    ) {
        _ = (backgroundColor, conversionInfo)
        self.sourceAlpha = srcAlpha
        self.destinationAlpha = destAlpha
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

// MARK: - Matrix decomposition and solve kernels
//
// Factorizations and triangular solves are GPU kernels; every encode below
// refuses through `MPSHostBoundary`. The ordering/transpose/unit flags and
// dimensions are validated host configuration mirrored from the pinned
// overlay signatures.

/// Cholesky decomposition descriptor.
open class MPSMatrixDecompositionCholesky: MPSMatrixUnaryKernel {
    public private(set) var lower: Bool
    public private(set) var order: Int

    public required init(device: any MTLDevice) {
        self.lower = true
        self.order = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, lower: Bool, order: Int) {
        self.lower = lower
        self.order = mpsWave12Positive(order)
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        resultMatrix: MPSMatrix,
        status: (any MTLBuffer)?
    ) {
        _ = (commandBuffer, sourceMatrix, resultMatrix, status)
        MPSHostBoundary.refuseGPUEncode("MPSMatrixDecompositionCholesky.encode")
    }
}

/// LU decomposition descriptor.
open class MPSMatrixDecompositionLU: MPSMatrixUnaryKernel {
    public private(set) var rows: Int
    public private(set) var columns: Int

    public required init(device: any MTLDevice) {
        self.rows = 1
        self.columns = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, rows: Int, columns: Int) {
        self.rows = mpsWave12Positive(rows)
        self.columns = mpsWave12Positive(columns)
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        resultMatrix: MPSMatrix,
        pivotIndices: MPSMatrix,
        info status: (any MTLBuffer)?
    ) {
        _ = (commandBuffer, sourceMatrix, resultMatrix, pivotIndices, status)
        MPSHostBoundary.refuseGPUEncode("MPSMatrixDecompositionLU.encode")
    }
}

/// Cholesky solve descriptor.
open class MPSMatrixSolveCholesky: MPSMatrixUnaryKernel {
    public private(set) var upper: Bool
    public private(set) var order: Int
    public private(set) var numberOfRightHandSides: Int

    public required init(device: any MTLDevice) {
        self.upper = true
        self.order = 1
        self.numberOfRightHandSides = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, upper: Bool, order: Int, numberOfRightHandSides: Int) {
        self.upper = upper
        self.order = mpsWave12Positive(order)
        self.numberOfRightHandSides = mpsWave12Positive(numberOfRightHandSides)
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        rightHandSideMatrix: MPSMatrix,
        solutionMatrix: MPSMatrix
    ) {
        _ = (commandBuffer, sourceMatrix, rightHandSideMatrix, solutionMatrix)
        MPSHostBoundary.refuseGPUEncode("MPSMatrixSolveCholesky.encode")
    }
}

/// LU solve descriptor.
open class MPSMatrixSolveLU: MPSMatrixUnaryKernel {
    public private(set) var transpose: Bool
    public private(set) var order: Int
    public private(set) var numberOfRightHandSides: Int

    public required init(device: any MTLDevice) {
        self.transpose = false
        self.order = 1
        self.numberOfRightHandSides = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, transpose: Bool, order: Int, numberOfRightHandSides: Int) {
        self.transpose = transpose
        self.order = mpsWave12Positive(order)
        self.numberOfRightHandSides = mpsWave12Positive(numberOfRightHandSides)
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        rightHandSideMatrix: MPSMatrix,
        pivotIndices: MPSMatrix,
        solutionMatrix: MPSMatrix
    ) {
        _ = (commandBuffer, sourceMatrix, rightHandSideMatrix, pivotIndices, solutionMatrix)
        MPSHostBoundary.refuseGPUEncode("MPSMatrixSolveLU.encode")
    }
}

/// Triangular solve descriptor.
open class MPSMatrixSolveTriangular: MPSMatrixUnaryKernel {
    public private(set) var right: Bool
    public private(set) var upper: Bool
    public private(set) var transpose: Bool
    public private(set) var unit: Bool
    public private(set) var order: Int
    public private(set) var numberOfRightHandSides: Int
    public private(set) var alpha: Double

    public required init(device: any MTLDevice) {
        self.right = false
        self.upper = true
        self.transpose = false
        self.unit = false
        self.order = 1
        self.numberOfRightHandSides = 1
        self.alpha = 1
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        right: Bool,
        upper: Bool,
        transpose: Bool,
        unit: Bool,
        order: Int,
        numberOfRightHandSides: Int,
        alpha: Double
    ) {
        self.right = right
        self.upper = upper
        self.transpose = transpose
        self.unit = unit
        self.order = mpsWave12Positive(order)
        self.numberOfRightHandSides = mpsWave12Positive(numberOfRightHandSides)
        self.alpha = alpha
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        rightHandSideMatrix: MPSMatrix,
        solutionMatrix: MPSMatrix
    ) {
        _ = (commandBuffer, sourceMatrix, rightHandSideMatrix, solutionMatrix)
        MPSHostBoundary.refuseGPUEncode("MPSMatrixSolveTriangular.encode")
    }
}

// MARK: - NDArray gradient kernels and states
//
// Gradient kernels are GPU kernels; every encode below refuses through
// `MPSHostBoundary`. Allocating overloads return the incoming gradient
// unchanged with the refusal marker (matching the reshape precedent) and
// never fabricate gradient content. Destination overloads leave the
// destination untouched.

/// Base gradient-state object for NDArray gradient kernels.
open class MPSNDArrayGradientState: MPSState {
    public init(device: any MTLDevice) {
        super.init(device: device, bufferSize: 0)
    }

    public convenience init() {
        self.init(device: MPSHostDevice.shared)
    }
}

/// Unary gradient kernel descriptor.
open class MPSNDArrayUnaryGradientKernel: MPSNDArrayUnaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        _ = coder
        super.init(device: device)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState
    ) -> MPSNDArray {
        _ = (cmdBuf, sourceArray, state)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayUnaryGradientKernel.encode")
        return gradient
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState,
        destinationArray destination: MPSNDArray
    ) {
        _ = (cmdBuf, sourceArray, gradient, state, destination)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayUnaryGradientKernel.encode")
    }
}

/// Primary-source binary gradient kernel descriptor.
open class MPSNDArrayBinaryPrimaryGradientKernel: MPSNDArrayBinaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        _ = coder
        super.init(device: device)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState
    ) -> MPSNDArray {
        _ = (cmdBuf, primarySourceArray, secondarySourceArray, state)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayBinaryPrimaryGradientKernel.encode")
        return gradient
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState,
        destinationArray destination: MPSNDArray
    ) {
        _ = (cmdBuf, primarySourceArray, secondarySourceArray, gradient, state, destination)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayBinaryPrimaryGradientKernel.encode")
    }
}

/// Secondary-source binary gradient kernel descriptor.
open class MPSNDArrayBinarySecondaryGradientKernel: MPSNDArrayBinaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        _ = coder
        super.init(device: device)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState
    ) -> MPSNDArray {
        _ = (cmdBuf, primarySourceArray, secondarySourceArray, state)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayBinarySecondaryGradientKernel.encode")
        return gradient
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState,
        destinationArray destination: MPSNDArray
    ) {
        _ = (cmdBuf, primarySourceArray, secondarySourceArray, gradient, state, destination)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayBinarySecondaryGradientKernel.encode")
    }
}

/// Multiary gradient kernel descriptor carrying the gradient source index.
open class MPSNDArrayMultiaryGradientKernel: MPSNDArrayMultiaryKernel {
    public private(set) var sourceGradientIndex: Int

    public required init(device: any MTLDevice) {
        self.sourceGradientIndex = 0
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        self.sourceGradientIndex = 0
        super.init(device: device, sourceCount: count)
    }

    public init(device: any MTLDevice, sourceCount count: Int, sourceGradientIndex: Int) {
        self.sourceGradientIndex = max(sourceGradientIndex, 0)
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        _ = coder
        self.sourceGradientIndex = 0
        super.init(device: device)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArrays sources: [MPSNDArray],
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState
    ) -> MPSNDArray {
        _ = (cmdBuf, sources, state)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayMultiaryGradientKernel.encode")
        return gradient
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArrays sources: [MPSNDArray],
        sourceGradient gradient: MPSNDArray,
        gradientState state: MPSState,
        destinationArray destination: MPSNDArray
    ) {
        _ = (cmdBuf, sources, gradient, state, destination)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayMultiaryGradientKernel.encode")
    }
}

/// Gather gradient kernel descriptor. Encode stays fail-closed.
open class MPSNDArrayGatherGradient: MPSNDArrayBinaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        super.init(coder: coder, device: device)
    }
}

/// Gather gradient-state object.
open class MPSNDArrayGatherGradientState: MPSNDArrayGradientState {
    public override init(device: any MTLDevice) {
        super.init(device: device)
    }
}

/// Strided-slice gradient kernel descriptor. Encode stays fail-closed.
open class MPSNDArrayStridedSliceGradient: MPSNDArrayUnaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        super.init(coder: coder, device: device)
    }
}

// MARK: - Neural-network gradient states

/// Base gradient-state object for graph gradient nodes.
open class MPSNNGradientState: MPSState {
    public init(device: any MTLDevice) {
        super.init(device: device, bufferSize: 0)
    }

    public convenience init() {
        self.init(device: MPSHostDevice.shared)
    }
}

/// Binary gradient-state object.
open class MPSNNBinaryGradientState: MPSNNGradientState {
    public override init(device: any MTLDevice) {
        super.init(device: device)
    }
}

/// Multiary gradient-state object.
open class MPSNNMultiaryGradientState: MPSNNGradientState {
    public override init(device: any MTLDevice) {
        super.init(device: device)
    }
}

/// Multiary gradient-state graph node.
open class MPSNNMultiaryGradientStateNode: MPSNNGradientStateNode {}

/// Arithmetic gradient-state graph node.
open class MPSNNArithmeticGradientStateNode: MPSNNGradientStateNode {}

/// Label state graph node wiring ground-truth labels into loss nodes.
open class MPSNNLabelsNode: MPSNNStateNode {}

// MARK: - Neural-network arithmetic and scale nodes

/// Addition graph node. Execute is a GPU kernel; scales and bias are
/// validated host configuration inherited from `MPSNNBinaryArithmeticNode`.
open class MPSNNAdditionNode: MPSNNBinaryArithmeticNode {}

/// Addition gradient graph node.
open class MPSNNAdditionGradientNode: MPSNNGradientFilterNode {}

/// Multiplication graph node.
open class MPSNNMultiplicationNode: MPSNNBinaryArithmeticNode {}

/// Multiplication gradient graph node.
open class MPSNNMultiplicationGradientNode: MPSNNGradientFilterNode {}

/// Subtraction graph node.
open class MPSNNSubtractionNode: MPSNNBinaryArithmeticNode {}

/// Subtraction gradient graph node.
open class MPSNNSubtractionGradientNode: MPSNNGradientFilterNode {}

/// Division graph node.
open class MPSNNDivisionNode: MPSNNBinaryArithmeticNode {}

/// Bilinear-scale graph node.
open class MPSNNBilinearScaleNode: MPSNNFilterNode {}

/// Lanczos-scale graph node.
open class MPSNNLanczosScaleNode: MPSNNFilterNode {}

/// Concatenation gradient graph node.
open class MPSNNConcatenationGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient gradientSourceNode: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (gradientSourceNode, sourceImage, gradientState)
        super.init()
    }
}

// MARK: - Pad, reshape, and initial-gradient kernels

/// Pad gradient descriptor. Encode stays fail-closed.
open class MPSNNPadGradient: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Pad gradient graph node.
open class MPSNNPadGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        super.init()
    }
}

/// Reshape gradient descriptor. Encode stays fail-closed.
open class MPSNNReshapeGradient: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Reshape gradient graph node.
open class MPSNNReshapeGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        super.init()
    }
}

/// Initial-gradient descriptor. Encode stays fail-closed.
open class MPSNNInitialGradient: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Initial-gradient graph node.
open class MPSNNInitialGradientNode: MPSNNFilterNode {
    public init(source: MPSNNImageNode) {
        _ = source
        super.init()
    }
}

// MARK: - Gram-matrix gradient kernel and node

/// Gram-matrix gradient descriptor. Encode stays fail-closed; `alpha` is
/// validated host configuration (Linux default 1).
open class MPSNNGramMatrixCalculationGradient: MPSCNNKernel {
    public var alpha: Float = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public init(device: any MTLDevice, alpha: Float) {
        self.alpha = alpha
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Gram-matrix gradient graph node.
open class MPSNNGramMatrixCalculationGradientNode: MPSNNGradientFilterNode {
    public private(set) var alpha: Float

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.alpha = 1
        super.init()
    }

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode,
        alpha: Float
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.alpha = alpha
        super.init()
    }
}
