import Foundation
import MetalPerformanceShaders

// MARK: - Wave 11 focused probes
//
// Each test below is top-level, synchronous, and argument-free. Every test
// names each identifier it evidences in coverage.tsv.

final class MPSWave11TestHandle: NSObject, MPSHandle {
    static var supportsSecureCoding: Bool { true }
    let storedLabel: String
    init(label: String) { self.storedLabel = label; super.init() }
    required init?(coder: NSCoder) { self.storedLabel = ""; super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    // NOTE: the pinned overlay declares `label()` as a method while this
    // host stub keeps the pre-existing property shape; the overlay member
    // stays deferred (see oracle-questions.tsv).
    var label: String { storedLabel }
}

final class MPSWave11TestHeapProvider: NSObject, MPSHeapProvider {
    var lastRequestedSize: Int?
    func newHeap(size: Int) -> AnyObject? {
        lastRequestedSize = size
        return nil
    }
}

final class MPSWave11TestSizeState: NSObject, MPSImageSizeEncodingState {
    let sourceWidth: Int
    let sourceHeight: Int
    init(width: Int, height: Int) {
        self.sourceWidth = width
        self.sourceHeight = height
        super.init()
    }
}

final class MPSWave11TestTransformProvider: NSObject, MPSImageTransformProvider {
    static var supportsSecureCoding: Bool { true }
    required init?(coder: NSCoder) { super.init() }
    override init() { super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    func transform(forSourceImage image: MPSImage, handle: (any MPSHandle)?) -> MPSScaleTransform {
        _ = (image, handle)
        return MPSScaleTransform(scaleX: 2, scaleY: 3, translateX: 4, translateY: 5)
    }
}

final class MPSWave11TestGramCallback: NSObject, MPSNNGramMatrixCallback {
    static var supportsSecureCoding: Bool { true }
    required init?(coder: NSCoder) { super.init() }
    override init() { super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave11TestGramCallback()
    }
    func alpha(forSourceImage sourceImage: MPSImage, destinationImage: MPSImage) -> Float {
        _ = (sourceImage, destinationImage)
        return 0.5
    }
}

func testMPSWave11HandleAndHeapProvider() {
    let device = MPSHostDevice.shared
    let handle: any MPSHandle = MPSWave11TestHandle(label: "wave11")
    precondition(handle.label == "wave11")
    let node = MPSNNImageNode(handle: handle)
    precondition(node.handle?.label == "wave11")
    let exported = MPSNNImageNode.exportedNode(with: handle)
    precondition(exported.exportFromGraph)
    let provider: any MPSHeapProvider = MPSWave11TestHeapProvider()
    precondition(provider.newHeap(size: 64) == nil)
    let cmd = MPSCommandBuffer(commandBuffer: device.makeCommandBuffer())
    cmd.heapProvider = provider
    precondition(cmd.heapProvider != nil)
    cmd.heapProvider = nil
    precondition(cmd.heapProvider == nil)
}

func testMPSWave11StateNodes() {
    let handle: any MPSHandle = MPSWave11TestHandle(label: "state")
    let state = MPSNNStateNode()
    precondition(!state.exportFromGraph && !state.synchronizeResource)
    precondition(state.handle == nil)
    state.exportFromGraph = true
    state.synchronizeResource = true
    state.handle = handle
    precondition(state.exportFromGraph && state.synchronizeResource)
    precondition(state.handle?.label == "state")
    let gradientState = MPSNNGradientStateNode()
    gradientState.handle = handle
    gradientState.exportFromGraph = true
    let asBase: MPSNNStateNode = gradientState
    precondition(asBase.exportFromGraph && asBase.handle?.label == "state")
    let gradientFilter = MPSNNGradientFilterNode()
    let filter = MPSNNFilterNode()
    let sourceNode = MPSNNImageNode()
    precondition(filter.gradientFilters(withSource: sourceNode).count == 1)
    _ = gradientFilter
}

func testMPSWave11ConvolutionDescriptors() {
    let depthwise = MPSCNNDepthWiseConvolutionDescriptor(
        kernelWidth: 3, kernelHeight: 3, inputFeatureChannels: 4, outputFeatureChannels: 8
    )
    precondition(depthwise.kernelWidth == 3 && depthwise.outputFeatureChannels == 8)
    precondition(depthwise.channelMultiplier == 1)
    let asBase: MPSCNNConvolutionDescriptor = depthwise
    precondition(asBase.inputFeatureChannels == 4)
    let subpixel = MPSCNNSubPixelConvolutionDescriptor(
        kernelWidth: 2, kernelHeight: 2, inputFeatureChannels: 4, outputFeatureChannels: 16
    )
    precondition(subpixel.subPixelScaleFactor == 1)
    subpixel.subPixelScaleFactor = 2
    precondition(subpixel.subPixelScaleFactor == 2)
    subpixel.subPixelScaleFactor = 0
    precondition(subpixel.subPixelScaleFactor == 1)
}

func testMPSWave11QuadrilateralAccelerationStructure() {
    let device = MPSHostDevice.shared
    let quad = MPSQuadrilateralAccelerationStructure(device: device)
    precondition(quad.status == .unbuilt)
    precondition(quad.quadrilateralCount == 0)
    quad.quadrilateralCount = 7
    precondition(quad.quadrilateralCount == 7 && quad.polygonCount == 7)
    quad.polygonCount = 3
    precondition(quad.quadrilateralCount == 3)
    MPSHostBoundary.reset()
    quad.rebuild()
    precondition(quad.status == .unbuilt)
    precondition(MPSQuadrilateralAccelerationStructure(coder: NSCoder()) == nil)
    MPSHostBoundary.reset()
}

func testMPSWave11EuclideanDistanceTransform() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let edt = MPSImageEuclideanDistanceTransform(device: device)
    precondition(edt.searchLimitRadius == 0)
    edt.searchLimitRadius = 5
    precondition(edt.searchLimitRadius == 5)
    MPSHostBoundary.reset()
    edt.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    precondition(MPSImageEuclideanDistanceTransform(coder: NSCoder(), device: device) == nil)
}

func testMPSWave11Compare() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let compare = MPSNNCompare(device: device)
    precondition(compare.comparisonType == .equal)
    precondition(compare.threshold == 0)
    compare.comparisonType = .greater
    compare.threshold = 0.5
    precondition(compare.comparisonType == .greater && compare.threshold == 0.5)
    MPSHostBoundary.reset()
    compare.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let node = MPSNNComparisonNode(sources: [MPSNNImageNode(), MPSNNImageNode()])
    precondition(node.comparisonType == .equal)
    node.comparisonType = .lessOrEqual
    precondition(node.comparisonType == .lessOrEqual)
}

func testMPSWave11GramMatrix() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let gram = MPSNNGramMatrixCalculation(device: device)
    precondition(gram.alpha == 1)
    let scaled = MPSNNGramMatrixCalculation(device: device, alpha: 0.25)
    precondition(scaled.alpha == 0.25)
    scaled.alpha = 2
    precondition(scaled.alpha == 2)
    precondition(MPSNNGramMatrixCalculation(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    gram.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let callback: any MPSNNGramMatrixCallback = MPSWave11TestGramCallback()
    precondition(callback.alpha(forSourceImage: image, destinationImage: image) == 0.5)
    let node = MPSNNGramMatrixCalculationNode(source: MPSNNImageNode())
    precondition(node.alpha == 1 && node.propertyCallBack == nil)
    node.propertyCallBack = callback
    let alphaNode = MPSNNGramMatrixCalculationNode(source: MPSNNImageNode(), alpha: 0.5)
    precondition(alphaNode.alpha == 0.5)
    precondition(alphaNode.propertyCallBack == nil)
    precondition(node.propertyCallBack?.alpha(forSourceImage: image, destinationImage: image) == 0.5)
}

func testMPSWave11GridSampleAndSlice() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let grid = MPSNNGridSample(device: device)
    precondition(!grid.useGridValueAsInputCoordinate)
    grid.useGridValueAsInputCoordinate = true
    precondition(grid.useGridValueAsInputCoordinate)
    precondition(MPSNNGridSample(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    grid.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let slice = MPSNNSlice(device: device)
    precondition(MPSNNSlice(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    slice.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave11GraphNodes() {
    let source = MPSNNImageNode()
    let size = MTLSize(width: 4, height: 5, depth: 1)
    let scale = MPSNNScaleNode(source: source, outputSize: size)
    precondition(scale.outputSize == size && scale.transformProvider == nil)
    let provider: any MPSImageTransformProvider = MPSWave11TestTransformProvider()
    let imageForProvider = MPSImage(
        device: MPSHostDevice.shared,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let transform = provider.transform(forSourceImage: imageForProvider, handle: nil)
    precondition(transform.scaleX == 2 && transform.translateY == 5)
    let scaledWithProvider = MPSNNScaleNode(source: source, transformProvider: provider, outputSize: size)
    precondition(scaledWithProvider.outputSize == size)
    precondition(scaledWithProvider.transformProvider != nil)
    let pad = MPSNNPadNode(
        source: source,
        paddingSizeBefore: MPSImageCoordinate(x: 1, y: 2, channel: 0),
        paddingSizeAfter: MPSImageCoordinate(x: 3, y: 4, channel: 0),
        edgeMode: .clamp
    )
    precondition(pad.fillValue == 0)
    pad.fillValue = 1.5
    precondition(pad.fillValue == 1.5 && pad.edgeMode == .clamp)
    let reshape = MPSNNReshapeNode(source: source, resultWidth: 4, resultHeight: 5, resultFeatureChannels: 6)
    precondition(reshape.resultWidth == 4 && reshape.resultHeight == 5 && reshape.resultFeatureChannels == 6)
    let reduction = MPSNNUnaryReductionNode(source: source)
    precondition(reduction.clipRectSource == MPSRectNoClip)
    reduction.clipRectSource = MTLRegion.make2D(0, 0, 4, 5)
    precondition(reduction.clipRectSource == MTLRegion.make2D(0, 0, 4, 5))
    let concat = MPSNNConcatenationNode(sources: [source, MPSNNImageNode()])
    precondition(concat.sources.count == 2)
    let sizeState: any MPSImageSizeEncodingState = MPSWave11TestSizeState(width: 8, height: 6)
    precondition(sizeState.sourceWidth == 8 && sizeState.sourceHeight == 6)
    let weights = MPSTestConvolutionDataSource()
    let convNode = MPSCNNConvolutionNode(source: source, weights: weights)
    let trainable: any MPSNNTrainableNode = convNode
    precondition(trainable.trainingStyle == .UpdateDeviceNone)
    trainable.trainingStyle = .updateDeviceCPU
    precondition(convNode.trainingStyle == .updateDeviceCPU)
}

func testMPSWave11MatrixUnaryAndLogSoftMax() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let unary = MPSMatrixUnaryKernel(device: device)
    precondition(unary.batchStart == 0 && unary.batchSize == 1)
    precondition(unary.sourceMatrixOrigin == MTLOrigin(x: 0, y: 0, z: 0))
    precondition(unary.resultMatrixOrigin == MTLOrigin(x: 0, y: 0, z: 0))
    unary.batchStart = 1
    unary.batchSize = 2
    unary.sourceMatrixOrigin = MTLOrigin(x: 1, y: 0, z: 0)
    unary.resultMatrixOrigin = MTLOrigin(x: 0, y: 1, z: 0)
    let copied = unary.copy() as! MPSMatrixUnaryKernel
    precondition(copied.batchStart == 1 && copied.batchSize == 2)
    precondition(copied.sourceMatrixOrigin == MTLOrigin(x: 1, y: 0, z: 0))
    precondition(copied.resultMatrixOrigin == MTLOrigin(x: 0, y: 1, z: 0))
    // Host log-softmax of [0, 1, 2]: max 2, sum e^-2+e^-1+1 = 1.5032147,
    // log(sum) = 0.40760596, so y = [-2.407606, -1.407606, -0.407606].
    let desc = MPSMatrixDescriptor(rows: 1, columns: 3, rowBytes: 12, dataType: .float32)
    let input = MPSMatrix(device: device, descriptor: desc)
    let result = MPSMatrix(device: device, descriptor: desc)
    let inPtr = input.data.contents.bindMemory(to: Float.self, capacity: 3)
    inPtr[0] = 0; inPtr[1] = 1; inPtr[2] = 2
    let logSoftMax = MPSMatrixLogSoftMax(device: device)
    logSoftMax.encode(commandBuffer: cmd, inputMatrix: input, resultMatrix: result)
    let outPtr = result.data.contents.bindMemory(to: Float.self, capacity: 3)
    let expected: [Float] = [-2.407606, -1.407606, -0.407606]
    for i in 0..<3 {
        precondition(abs(outPtr[i] - expected[i]) < 1e-5)
    }
    var probSum: Float = 0
    for i in 0..<3 { probSum += exp(outPtr[i]) }
    precondition(abs(probSum - 1) < 1e-6)
    let plain = MPSMatrixSoftMax(device: device)
    let plainResult = MPSMatrix(device: device, descriptor: desc)
    plain.encode(commandBuffer: cmd, inputMatrix: input, resultMatrix: plainResult)
    let plainPtr = plainResult.data.contents.bindMemory(to: Float.self, capacity: 3)
    for i in 0..<3 {
        precondition(abs(log(plainPtr[i]) - outPtr[i]) < 1e-6)
    }
    // Log-softmax gradient: y = [log 0.25, log 0.75, log ~0], g = [2, 6, 9].
    // The third channel carries ~0 probability, so dx matches the
    // two-channel oracle [-0.75, 0.75] and cross-checks the softmax
    // gradient reference on linear probabilities.
    let fwd = MPSMatrix(device: device, descriptor: desc)
    let grad = MPSMatrix(device: device, descriptor: desc)
    let dx = MPSMatrix(device: device, descriptor: desc)
    let fwdPtr = fwd.data.contents.bindMemory(to: Float.self, capacity: 3)
    fwdPtr[0] = -1.3862944; fwdPtr[1] = -0.28768207; fwdPtr[2] = -20
    let gradPtr = grad.data.contents.bindMemory(to: Float.self, capacity: 3)
    gradPtr[0] = 2; gradPtr[1] = 6; gradPtr[2] = 9
    let logGrad = MPSMatrixLogSoftMaxGradient(device: device)
    logGrad.encode(to: cmd, gradientMatrix: grad, forwardOutputMatrix: fwd, resultMatrix: dx)
    let dxPtr = dx.data.contents.bindMemory(to: Float.self, capacity: 3)
    precondition(abs(dxPtr[0] - (-0.75)) < 1e-5)
    precondition(abs(dxPtr[1] - 0.75) < 1e-5)
    let linFwd = MPSMatrix(device: device, descriptor: desc)
    let linPtr = linFwd.data.contents.bindMemory(to: Float.self, capacity: 3)
    linPtr[0] = 0.25; linPtr[1] = 0.75; linPtr[2] = 0
    let linDx = MPSMatrix(device: device, descriptor: desc)
    let refGrad = MPSMatrixSoftMaxGradient(device: device)
    refGrad.encode(to: cmd, gradientMatrix: grad, forwardOutputMatrix: linFwd, resultMatrix: linDx)
    let linDxPtr = linDx.data.contents.bindMemory(to: Float.self, capacity: 3)
    for i in 0..<3 {
        precondition(abs(linDxPtr[i] - dxPtr[i]) < 1e-4)
    }
    MPSHostBoundary.reset()
}

func testMPSWave11NDArrayQuantization() {
    let affineDefault = MPSNDArrayAffineQuantizationDescriptor()
    let asBase: MPSNDArrayQuantizationDescriptor = affineDefault
    precondition(asBase.quantizationScheme == .typeAffine)
    precondition(asBase.quantizationDataType == .float32)
    let affine = MPSNDArrayAffineQuantizationDescriptor(
        dataType: .uInt8, hasZeroPoint: true, hasMinValue: false
    )
    precondition(affine.quantizationDataType == .uInt8)
    precondition(affine.quantizationScheme == .typeAffine)
    precondition(affine.hasZeroPoint && !affine.hasMinValue && !affine.implicitZeroPoint)
    affine.hasMinValue = true
    affine.implicitZeroPoint = true
    precondition(affine.hasMinValue && affine.implicitZeroPoint)
    let lut = MPSNDArrayLUTQuantizationDescriptor(dataType: .float16)
    precondition(lut.quantizationDataType == .float16)
    precondition(lut.quantizationScheme == .typeLUT)
    let lutAxis = MPSNDArrayLUTQuantizationDescriptor(dataType: .float16, vectorAxis: 2)
    let lutAsBase: MPSNDArrayQuantizationDescriptor = lutAxis
    precondition(lutAsBase.quantizationScheme == .typeLUT)
}

func testMPSWave11NDArrayKernels() {
    let device = MPSHostDevice.shared
    let gather = MPSNDArrayGather(device: device)
    precondition(gather.axis == 0 && gather.sourceCount == 2)
    gather.axis = 2
    precondition(gather.axis == 2)
    let slice = MPSNDArrayStridedSlice(device: device)
    let strides = MPSNDArrayOffsets(dimensions: (2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
    slice.strides = strides
    precondition(slice.strides.dimensions.0 == 2)
    let matmul = MPSNDArrayMatrixMultiplication(device: device)
    precondition(matmul.alpha == 1 && matmul.beta == 0)
    matmul.alpha = 2
    matmul.beta = 0.5
    precondition(matmul.alpha == 2 && matmul.beta == 0.5)
    let left = MPSNDArrayAffineQuantizationDescriptor(dataType: .uInt8, hasZeroPoint: true, hasMinValue: true)
    let right = MPSNDArrayLUTQuantizationDescriptor(dataType: .float16, vectorAxis: 1)
    let quantized = MPSNDArrayQuantizedMatrixMultiplication(
        device: device, leftQuantizationDescriptor: left, rightQuantizationDescriptor: right
    )
    precondition(quantized.leftQuantizationDescriptor.quantizationDataType == .uInt8)
    precondition(quantized.rightQuantizationDescriptor.quantizationScheme == .typeLUT)
    precondition(quantized.alpha == 1 && quantized.beta == 0)
    let lutDequant = MPSNDArrayLUTDequantize(device: device)
    precondition(lutDequant.sourceCount == 1)
    let affineDequant = MPSNDArrayAffineInt4Dequantize(device: device, quantizationDescriptor: left)
    precondition(affineDequant.quantizationDescriptor.hasZeroPoint)
    let vectorDequant = MPSNDArrayVectorLUTDequantize(device: device, axis: 3)
    precondition(vectorDequant.vectorAxis == 3)
    let copied = quantized.copy() as! MPSNDArrayQuantizedMatrixMultiplication
    precondition(copied.sourceCount == quantized.sourceCount)
}
