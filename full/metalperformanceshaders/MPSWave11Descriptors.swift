import Foundation

// MARK: - Wave 11 validated descriptors and host kernels
//
// Every class below is constructable, validated host data. GPU `encode`
// paths are inherited fail-closed refusals (via MPSHostBoundary) unless a
// host CPU implementation is provided and noted. Linux default values that
// Apple does not publish in the pinned overlay are documented per member.

private func mpsWave11Positive(_ value: Int) -> Int { max(value, 1) }

// MARK: - Convolution descriptors

/// Depth-wise convolution descriptor. The pinned overlay exposes no
/// dedicated initializer, so construction uses the inherited
/// convolution-descriptor initializers and `channelMultiplier` keeps its
/// Linux default until Apple initialization is observed.
open class MPSCNNDepthWiseConvolutionDescriptor: MPSCNNConvolutionDescriptor {
    public private(set) var channelMultiplier: Int = 1
}

/// Sub-pixel convolution descriptor with a validated scale factor.
open class MPSCNNSubPixelConvolutionDescriptor: MPSCNNConvolutionDescriptor {
    public var subPixelScaleFactor: Int {
        get { storedSubPixelScaleFactor }
        set { storedSubPixelScaleFactor = mpsWave11Positive(newValue) }
    }
    private var storedSubPixelScaleFactor: Int = 1
}

// MARK: - Acceleration structures

/// Quadrilateral polygon acceleration structure. Mirrors
/// `MPSTriangleAccelerationStructure`: `quadrilateralCount` aliases the
/// inherited `polygonCount`. Rebuild/refit stay unbuilt and refuse GPU work.
open class MPSQuadrilateralAccelerationStructure: MPSPolygonAccelerationStructure {
    public var quadrilateralCount: Int {
        get { polygonCount }
        set { polygonCount = newValue }
    }

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

// MARK: - Image kernels

/// Euclidean distance transform descriptor. The distance field itself is a
/// GPU kernel, so encode stays fail-closed; the radius is validated host
/// configuration. The Apple default for `searchLimitRadius` is not in the
/// pinned overlay; Linux starts at 0.
open class MPSImageEuclideanDistanceTransform: MPSUnaryImageKernel {
    public var searchLimitRadius: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

// MARK: - Comparison kernel and node

/// Per-pixel comparison kernel descriptor. The comparison itself is a GPU
/// kernel, so encode stays fail-closed through `MPSCNNArithmetic`.
/// The Apple defaults for `comparisonType`/`threshold` are not in the
/// pinned overlay; Linux starts at `.equal`/`0`.
open class MPSNNCompare: MPSCNNArithmetic {
    public var comparisonType: MPSNNComparisonType = .equal
    public var threshold: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }
}

/// Graph node carrying the comparison configuration.
open class MPSNNComparisonNode: MPSNNBinaryArithmeticNode {
    public var comparisonType: MPSNNComparisonType = .equal
}

// MARK: - Gram-matrix calculation

/// Gram-matrix calculation descriptor. Encode stays fail-closed; `alpha`
/// is validated host configuration (Linux default 1).
open class MPSNNGramMatrixCalculation: MPSCNNKernel {
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

/// Callback supplying a per-image alpha for Gram-matrix graph nodes.
public protocol MPSNNGramMatrixCallback: NSObjectProtocol, NSCopying, NSSecureCoding {
    func alpha(forSourceImage sourceImage: MPSImage, destinationImage: MPSImage) -> Float
}

/// Graph node carrying the Gram-matrix configuration and callback.
open class MPSNNGramMatrixCalculationNode: MPSNNFilterNode {
    public var alpha: Float = 1
    public var propertyCallBack: (any MPSNNGramMatrixCallback)?

    public init(source sourceNode: MPSNNImageNode, alpha: Float) {
        _ = sourceNode
        self.alpha = alpha
        super.init()
    }

    public convenience init(source sourceNode: MPSNNImageNode) {
        self.init(source: sourceNode, alpha: 1)
    }
}

// MARK: - Grid sample / slice kernels

/// Grid-sample descriptor. Sampling is a GPU kernel, so encode stays
/// fail-closed. The Apple default for `useGridValueAsInputCoordinate` is
/// not in the pinned overlay; Linux starts at `false`.
open class MPSNNGridSample: MPSCNNBinaryKernel {
    public var useGridValueAsInputCoordinate: Bool = false

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

/// Slice kernel descriptor. Slicing is a GPU kernel, so encode stays
/// fail-closed.
open class MPSNNSlice: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

// MARK: - Graph nodes and providers

/// Provider mapping a source image to a scale transform for `MPSNNScaleNode`.
public protocol MPSImageTransformProvider: NSObjectProtocol, NSSecureCoding {
    func transform(forSourceImage image: MPSImage, handle: (any MPSHandle)?) -> MPSScaleTransform
}

/// Scale graph node carrying the destination size and optional provider.
open class MPSNNScaleNode: MPSNNFilterNode {
    public private(set) var outputSize: MTLSize
    public private(set) var transformProvider: (any MPSImageTransformProvider)?

    public init(source sourceNode: MPSNNImageNode, outputSize size: MTLSize) {
        _ = sourceNode
        self.outputSize = size
        super.init()
    }

    public init(
        source sourceNode: MPSNNImageNode,
        transformProvider: (any MPSImageTransformProvider)?,
        outputSize size: MTLSize
    ) {
        _ = sourceNode
        self.transformProvider = transformProvider
        self.outputSize = size
        super.init()
    }
}

/// Pad graph node carrying padding geometry, edge mode, and fill value.
open class MPSNNPadNode: MPSNNFilterNode {
    public private(set) var paddingSizeBefore: MPSImageCoordinate
    public private(set) var paddingSizeAfter: MPSImageCoordinate
    public private(set) var edgeMode: MPSImageEdgeMode
    public var fillValue: Float = 0

    public init(
        source: MPSNNImageNode,
        paddingSizeBefore: MPSImageCoordinate,
        paddingSizeAfter: MPSImageCoordinate,
        edgeMode: MPSImageEdgeMode
    ) {
        _ = source
        self.paddingSizeBefore = paddingSizeBefore
        self.paddingSizeAfter = paddingSizeAfter
        self.edgeMode = edgeMode
        super.init()
    }
}

/// Reshape graph node carrying the validated result geometry.
open class MPSNNReshapeNode: MPSNNFilterNode {
    public private(set) var resultWidth: Int
    public private(set) var resultHeight: Int
    public private(set) var resultFeatureChannels: Int

    public init(source: MPSNNImageNode, resultWidth: Int, resultHeight: Int, resultFeatureChannels: Int) {
        _ = source
        self.resultWidth = mpsWave11Positive(resultWidth)
        self.resultHeight = mpsWave11Positive(resultHeight)
        self.resultFeatureChannels = mpsWave11Positive(resultFeatureChannels)
        super.init()
    }
}

/// Base reduction graph node. The reduction itself is a GPU kernel, so
/// graph execution stays fail-closed; the source clip region is validated
/// host configuration defaulting to no clipping.
open class MPSNNUnaryReductionNode: MPSNNFilterNode {
    public var clipRectSource: MTLRegion = MPSRectNoClip

    public init(source sourceNode: MPSNNImageNode) {
        _ = sourceNode
        super.init()
    }
}

/// Concatenation graph node carrying its source images.
open class MPSNNConcatenationNode: MPSNNFilterNode {
    public private(set) var sources: [MPSNNImageNode]

    public init(sources sourceNodes: [MPSNNImageNode]) {
        self.sources = sourceNodes
        super.init()
    }
}

/// Size-encoding state reporting the source image extent.
public protocol MPSImageSizeEncodingState: NSObjectProtocol {
    var sourceWidth: Int { get }
    var sourceHeight: Int { get }
}

/// Marker protocol for graph nodes that carry a training style.
public protocol MPSNNTrainableNode: NSObjectProtocol {
    var trainingStyle: MPSNNTrainingStyle { get set }
}

extension MPSCNNConvolutionNode: MPSNNTrainableNode {}

// MARK: - Matrix unary kernels and log-softmax

/// Host base for unary matrix kernels, mirroring the batch/origin
/// configuration of `MPSMatrixBinaryKernel` for single-source kernels.
open class MPSMatrixUnaryKernel: MPSKernel {
    public var sourceMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var resultMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var batchStart: Int = 0
    public var batchSize: Int = 1

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copied.sourceMatrixOrigin = sourceMatrixOrigin
        copied.resultMatrixOrigin = resultMatrixOrigin
        copied.batchStart = batchStart
        copied.batchSize = batchSize
        return copied
    }
}

/// Host float32 log-softmax: `y = x - max - log(sum(exp(x - max)))` per row.
/// Rows whose exponentials all underflow to zero yield `-infinity`, matching
/// `log(softmax)` of the same input.
open class MPSMatrixLogSoftMax: MPSMatrixSoftMax {
    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixLogSoftMax(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.sourceRows = sourceRows
        copied.sourceColumns = sourceColumns
        return copied as! Self
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32, resultMatrix.dataType == .float32 else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixLogSoftMax.encode")
            return
        }
        let rows = sourceRows > 0 ? sourceRows : inputMatrix.rows
        let columns = sourceColumns > 0 ? sourceColumns : inputMatrix.columns
        let a = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let c = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let lda = max(inputMatrix.rowBytes / 4, 1)
        let ldc = max(resultMatrix.rowBytes / 4, 1)
        for row in 0..<rows {
            var maxValue = a[row * lda]
            for col in 1..<columns {
                maxValue = max(maxValue, a[row * lda + col])
            }
            var sum: Float = 0
            for col in 0..<columns {
                sum += exp(a[row * lda + col] - maxValue)
            }
            let shift = sum > 0 ? maxValue + log(sum) : Float.infinity
            for col in 0..<columns {
                c[row * ldc + col] = a[row * lda + col] - shift
            }
        }
    }
}

/// Host float32 log-softmax gradient: `dx = g - exp(y) * sum(exp(y) * g)`
/// per row, where `y` holds the forward log-probabilities. Batch selection
/// and refusal rules mirror `MPSMatrixSoftMaxGradient`.
open class MPSMatrixLogSoftMaxGradient: MPSMatrixSoftMaxGradient {
    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixLogSoftMaxGradient(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copyBinaryConfiguration(to: copied)
        copied.sourceRows = sourceRows
        copied.sourceColumns = sourceColumns
        return copied as! Self
    }

    open override func encode(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        forwardOutputMatrix: MPSMatrix,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              forwardOutputMatrix.dataType == .float32,
              resultMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixLogSoftMaxGradient.encode")
            return
        }
        let rows = sourceRows > 0 ? sourceRows : forwardOutputMatrix.rows
        let columns = sourceColumns > 0 ? sourceColumns : forwardOutputMatrix.columns
        let zero = MTLOrigin(x: 0, y: 0, z: 0)
        guard hasHostOrigins, sourceRows >= 0, sourceColumns >= 0,
              [gradientMatrix, forwardOutputMatrix, resultMatrix].allSatisfy({
                  mpsHostMatrixRegionFits($0, rows: rows, columns: columns, origin: zero,
                      batchStart: batchStart, batchSize: batchSize)
              }), resultMatrix.data !== gradientMatrix.data,
              resultMatrix.data !== forwardOutputMatrix.data
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixLogSoftMaxGradient.encode")
            return
        }
        for batch in batchStart..<(batchStart + batchSize) {
            let g = mpsFloatBuffer(gradientMatrix.data,
                offset: gradientMatrix.offset + batch * gradientMatrix.matrixBytes)
            let y = mpsFloatBuffer(forwardOutputMatrix.data,
                offset: forwardOutputMatrix.offset + batch * forwardOutputMatrix.matrixBytes)
            let dx = mpsFloatBuffer(resultMatrix.data,
                offset: resultMatrix.offset + batch * resultMatrix.matrixBytes)
            let ldg = max(gradientMatrix.rowBytes / 4, 1)
            let ldy = max(forwardOutputMatrix.rowBytes / 4, 1)
            let ldd = max(resultMatrix.rowBytes / 4, 1)
            for row in 0..<rows {
                var dot: Float = 0
                for col in 0..<columns {
                    dot += exp(y[row * ldy + col]) * g[row * ldg + col]
                }
                for col in 0..<columns {
                    dx[row * ldd + col] = exp(y[row * ldy + col]) * (g[row * ldg + col] - dot)
                }
            }
        }
    }
}

// MARK: - NDArray quantization descriptors

/// Base quantization descriptor. The concrete scheme and data type are
/// supplied by the affine/LUT subclasses.
open class MPSNDArrayQuantizationDescriptor: NSObject {
    public private(set) var quantizationDataType: MPSDataType
    public private(set) var quantizationScheme: MPSNDArrayQuantizationScheme

    init(quantizationDataType: MPSDataType, quantizationScheme: MPSNDArrayQuantizationScheme) {
        self.quantizationDataType = quantizationDataType
        self.quantizationScheme = quantizationScheme
        super.init()
    }
}

/// Affine quantization descriptor. Linux defaults (data type, zero-point and
/// minimum presence) are host choices; the pinned overlay publishes no
/// Apple defaults.
open class MPSNDArrayAffineQuantizationDescriptor: MPSNDArrayQuantizationDescriptor {
    public var hasZeroPoint: Bool
    public var hasMinValue: Bool
    public var implicitZeroPoint: Bool

    public init() {
        self.hasZeroPoint = false
        self.hasMinValue = false
        self.implicitZeroPoint = false
        super.init(quantizationDataType: .float32, quantizationScheme: .typeAffine)
    }

    public init(dataType quantizationDataType: MPSDataType, hasZeroPoint: Bool, hasMinValue: Bool) {
        self.hasZeroPoint = hasZeroPoint
        self.hasMinValue = hasMinValue
        self.implicitZeroPoint = false
        super.init(quantizationDataType: quantizationDataType, quantizationScheme: .typeAffine)
    }
}

/// Lookup-table quantization descriptor.
open class MPSNDArrayLUTQuantizationDescriptor: MPSNDArrayQuantizationDescriptor {
    private var storedVectorAxis: Int = 0

    public init(dataType quantizationDataType: MPSDataType) {
        super.init(quantizationDataType: quantizationDataType, quantizationScheme: .typeLUT)
    }

    public init(dataType quantizationDataType: MPSDataType, vectorAxis: Int) {
        self.storedVectorAxis = vectorAxis
        super.init(quantizationDataType: quantizationDataType, quantizationScheme: .typeLUT)
    }
}

// MARK: - NDArray data kernels (validated configuration, fail-closed encode)

/// Gather descriptor carrying the gather axis (Linux default 0).
open class MPSNDArrayGather: MPSNDArrayBinaryKernel {
    public var axis: Int = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }
}

/// Strided-slice descriptor. The slice keeps its own stride storage while
/// the unary base defaults stay untouched.
open class MPSNDArrayStridedSlice: MPSNDArrayUnaryKernel {
    private var storedSliceStrides = MPSNDArrayOffsets()

    open override var strides: MPSNDArrayOffsets {
        get { storedSliceStrides }
        set { storedSliceStrides = newValue }
    }

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copied.storedSliceStrides = storedSliceStrides
        return copied
    }
}

/// NDArray matrix-multiplication descriptor. Linux defaults follow the BLAS
/// convention (`alpha` 1, `beta` 0); Apple defaults are not in the overlay.
open class MPSNDArrayMatrixMultiplication: MPSNDArrayMultiaryKernel {
    public var alpha: Double = 1
    public var beta: Double = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }
}

/// Quantized matrix-multiplication descriptor carrying both quantization
/// descriptors. Multiplication itself stays fail-closed.
open class MPSNDArrayQuantizedMatrixMultiplication: MPSNDArrayMatrixMultiplication {
    public private(set) var leftQuantizationDescriptor: MPSNDArrayQuantizationDescriptor
    public private(set) var rightQuantizationDescriptor: MPSNDArrayQuantizationDescriptor

    public init(
        device: any MTLDevice,
        leftQuantizationDescriptor: MPSNDArrayQuantizationDescriptor,
        rightQuantizationDescriptor: MPSNDArrayQuantizationDescriptor
    ) {
        self.leftQuantizationDescriptor = leftQuantizationDescriptor
        self.rightQuantizationDescriptor = rightQuantizationDescriptor
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.leftQuantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        self.rightQuantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        self.leftQuantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        self.rightQuantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        super.init(device: device, sourceCount: count)
    }
}

/// Lookup-table dequantize kernel descriptor.
open class MPSNDArrayLUTDequantize: MPSNDArrayMultiaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }
}

/// Affine int4 dequantize kernel descriptor carrying its quantization
/// descriptor.
open class MPSNDArrayAffineInt4Dequantize: MPSNDArrayMultiaryKernel {
    public private(set) var quantizationDescriptor: MPSNDArrayAffineQuantizationDescriptor

    public init(device: any MTLDevice, quantizationDescriptor: MPSNDArrayAffineQuantizationDescriptor) {
        self.quantizationDescriptor = quantizationDescriptor
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.quantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        self.quantizationDescriptor = MPSNDArrayAffineQuantizationDescriptor()
        super.init(device: device, sourceCount: count)
    }
}

/// Vector lookup-table dequantize kernel descriptor.
open class MPSNDArrayVectorLUTDequantize: MPSNDArrayMultiaryKernel {
    public var vectorAxis: Int

    public init(device: any MTLDevice, axis: Int) {
        self.vectorAxis = axis
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.vectorAxis = 0
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        self.vectorAxis = 0
        super.init(device: device, sourceCount: count)
    }
}
