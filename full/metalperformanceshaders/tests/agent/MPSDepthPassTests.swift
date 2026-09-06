import Foundation
import MetalPerformanceShaders

final class MPSTestBatchNormDataSource: NSObject, MPSCNNBatchNormalizationDataSource {
    let channels: Int
    var gammaStorage: UnsafeMutablePointer<Float>
    var betaStorage: UnsafeMutablePointer<Float>
    var meanStorage: UnsafeMutablePointer<Float>
    var varianceStorage: UnsafeMutablePointer<Float>

    init(channels: Int) {
        self.channels = channels
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        self.meanStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        self.varianceStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        for index in 0..<channels {
            gammaStorage[index] = 1
            betaStorage[index] = 0
            meanStorage[index] = 0
            varianceStorage[index] = 1
        }
        super.init()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
        meanStorage.deallocate()
        varianceStorage.deallocate()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSTestBatchNormDataSource(channels: channels)
    }

    func numberOfFeatureChannels() -> Int { channels }
    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func mean() -> UnsafeMutablePointer<Float>? { meanStorage }
    func variance() -> UnsafeMutablePointer<Float>? { varianceStorage }
    func load() -> Bool { true }
    func purge() {}
    func label() -> String? { "bn-test" }
}

final class MPSTestLossCallback: NSObject, MPSNNLossCallback {
    static var supportsSecureCoding: Bool { true }
    required init?(coder: NSCoder) { super.init(); _ = coder }
    override init() { super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSTestLossCallback()
    }
    func scalarWeight(forSourceImage sourceImage: MPSImage, destinationImage: MPSImage) -> Float {
        _ = (sourceImage, destinationImage)
        return 1
    }
}

func mpsDepthUnorm(_ device: MPSHostDevice, width: Int, height: Int) -> MPSImage {
    MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: width, height: height, featureChannels: 1)
    )
}

func mpsDepthFloatVector(_ device: MPSHostDevice, values: [Float]) -> MPSVector {
    let vector = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: values.count, dataType: .float32))
    let pointer = vector.data.contents.bindMemory(to: Float.self, capacity: values.count)
    for index in 0..<values.count { pointer[index] = values[index] }
    return vector
}

func mpsDepthFloatMatrix(_ device: MPSHostDevice, rows: Int, columns: Int, values: [Float]) -> MPSMatrix {
    let desc = MPSMatrixDescriptor(
        rows: rows,
        columns: columns,
        rowBytes: columns * 4,
        dataType: .float32
    )
    let matrix = MPSMatrix(device: device, descriptor: desc)
    let pointer = matrix.data.contents.bindMemory(to: Float.self, capacity: values.count)
    for index in 0..<values.count { pointer[index] = values[index] }
    return matrix
}

func testMPSCNNBinaryKernel() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let kernel = MPSCNNBinaryKernel(device: device)
    kernel.clipRect = MPSRectNoClip
    kernel.destinationFeatureChannelOffset = 1
    kernel.destinationImageAllocator = MPSImage.defaultAllocator()
    kernel.padding = MPSNNDefaultPadding(method: .sizeSame)
    kernel.primaryEdgeMode = .zero
    kernel.secondaryEdgeMode = .clamp
    kernel.primaryOffset = MPSOffset(x: 1, y: 2, z: 0)
    kernel.secondaryOffset = MPSOffset(x: 0, y: 1, z: 0)
    kernel.primarySourceFeatureChannelOffset = 0
    kernel.secondarySourceFeatureChannelOffset = 0
    kernel.primarySourceFeatureChannelMaxCount = 4
    kernel.secondarySourceFeatureChannelMaxCount = 4
    kernel.primaryStrideInPixelsX = 1
    kernel.primaryStrideInPixelsY = 1
    kernel.secondaryStrideInPixelsX = 1
    kernel.secondaryStrideInPixelsY = 1
    precondition(!kernel.isBackwards && !kernel.isStateModified)
    precondition(kernel.primaryKernelWidth == 1 && kernel.primaryKernelHeight == 1)
    precondition(kernel.secondaryKernelWidth == 1 && kernel.secondaryKernelHeight == 1)
    precondition(kernel.primaryDilationRateX == 1 && kernel.primaryDilationRateY == 1)
    precondition(kernel.secondaryDilationRateX == 1 && kernel.secondaryDilationRateY == 1)
    precondition(!kernel.appendBatchBarrier())
    precondition(!kernel.isResultStateReusedAcrossBatch())
    let image = mpsDepthUnorm(device, width: 2, height: 2)
    precondition(kernel.encodingStorageSize(primaryImage: image, secondaryImage: image, sourceStates: nil, destinationImage: nil) == 0)
    precondition(kernel.batchEncodingStorageSize(primaryImage: [image], secondaryImage: [image], sourceStates: nil, destinationImage: nil) == 0)
    let destDesc = kernel.destinationImageDescriptor(forSourceImages: [image], sourceStates: nil)
    precondition(destDesc.width == 2)
    precondition(kernel.resultState(primaryImage: image, secondaryImage: image, sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.resultStateBatch(primaryImage: [image], secondaryImage: [image], sourceStates: nil, destinationImage: [image]) == nil)
    precondition(kernel.temporaryResultState(commandBuffer: cmd, primaryImage: image, secondaryImage: image, sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.temporaryResultStateBatch(commandBuffer: cmd, primaryImage: [image], secondaryImage: [image], sourceStates: nil, destinationImage: [image]) == nil)
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    _ = kernel.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var state: MPSState?
    _ = kernel.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationState: &state, destinationStateIsTemporary: false)
    kernel.encodeBatch(commandBuffer: cmd, primaryImages: [image], secondaryImages: [image], destinationImages: [image])
    _ = kernel.encodeBatch(commandBuffer: cmd, primaryImages: [image], secondaryImages: [image])
    var states: NSArray?
    _ = kernel.encodeBatch(commandBuffer: cmd, primaryImages: [image], secondaryImages: [image], destinationStates: &states, destinationStateIsTemporary: true)
    precondition(MPSCNNBinaryKernel(coder: NSCoder(), device: device) == nil)
}

func testMPSCNNMultiaryKernel() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let kernel = MPSCNNMultiaryKernel(device: device, sourceCount: 3)
    precondition(kernel.sourceCount == 3)
    kernel.clipRect = MPSRectNoClip
    kernel.destinationFeatureChannelOffset = 0
    kernel.destinationImageAllocator = MPSImage.defaultAllocator()
    kernel.padding = MPSNNDefaultPadding(method: .validOnly)
    kernel.setKernelWidth(3, at: 0)
    kernel.setKernelHeight(5, at: 1)
    kernel.setOffset(MPSOffset(x: 2, y: 3, z: 0), at: 0)
    kernel.setEdgeMode(.zero, at: 2)
    kernel.setDilationRateX(2, at: 0)
    kernel.setDilationRateY(3, at: 1)
    kernel.setStrideInPixelsX(2, at: 0)
    kernel.setStrideInPixelsY(2, at: 1)
    kernel.setSourceFeatureChannelOffset(1, at: 0)
    kernel.setSourceFeatureChannelMaxCount(8, at: 1)
    precondition(kernel.kernelWidth(at: 0) == 3)
    precondition(kernel.kernelHeight(at: 1) == 5)
    precondition(kernel.offset(at: 0).x == 2)
    precondition(kernel.edgeMode(at: 2) == .zero)
    precondition(kernel.dilationRateXatIndex(0) == 2)
    precondition(kernel.dilationRateYatIndex(1) == 3)
    precondition(kernel.stride(inPixelsXatIndex: 0) == 2)
    precondition(kernel.stride(inPixelsYatIndex: 1) == 2)
    precondition(kernel.sourceFeatureChannelOffset(at: 0) == 1)
    precondition(kernel.sourceFeatureChannelMaxCount(at: 1) == 8)
    precondition(!kernel.isBackwards && !kernel.isStateModified)
    precondition(!kernel.appendBatchBarrier())
    precondition(!kernel.isResultStateReusedAcrossBatch())
    let image = mpsDepthUnorm(device, width: 4, height: 4)
    let destDesc = kernel.destinationImageDescriptor(sourceImages: [image], sourceStates: nil)
    precondition(destDesc.width == 4)
    precondition(kernel.resultState(sourceImages: [image], sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.resultStateBatch(sourceImages: [[image]], sourceStates: nil, destinationImage: [image]) == nil)
    precondition(kernel.temporaryResultState(commandBuffer: cmd, sourceImages: [image], sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.temporaryResultStateBatch(commandBuffer: cmd, sourceImages: [[image]], sourceStates: nil, destinationImage: [image]) == nil)
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: cmd, sourceImages: [image], destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = kernel.encode(commandBuffer: cmd, sourceImages: [image])
    var state: MPSState?
    _ = kernel.encode(commandBuffer: cmd, sourceImages: [image], destinationState: &state, destinationStateIsTemporary: false)
    kernel.encodeBatch(commandBuffer: cmd, sourceImages: [[image]], destinationImages: [image])
    _ = kernel.encodeBatch(commandBuffer: cmd, sourceImages: [[image]])
    var states: NSArray?
    _ = kernel.encodeBatch(commandBuffer: cmd, sourceImages: [[image]], destinationStates: &states, destinationStateIsTemporary: false)
    precondition(MPSCNNMultiaryKernel(coder: NSCoder(), device: device) == nil)
}

func testMPSSVGF() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let svgf = MPSSVGF(device: device)
    svgf.bilateralFilterRadius = 3
    svgf.bilateralFilterSigma = 1.5
    svgf.channelCount = 3
    svgf.channelCount2 = 1
    svgf.depthWeight = 0.5
    svgf.luminanceWeight = 0.25
    svgf.minimumFramesForVarianceEstimation = 4
    svgf.normalWeight = 0.8
    svgf.reprojectionThreshold = 0.05
    svgf.temporalReprojectionBlendFactor = 0.1
    svgf.temporalWeighting = .exponentialMovingAverage
    svgf.varianceEstimationRadius = 2
    svgf.varianceEstimationSigma = 0.75
    svgf.variancePrefilterRadius = 1
    svgf.variancePrefilterSigma = 0.5
    precondition(svgf.bilateralFilterRadius == 3)
    precondition(svgf.temporalWeighting == .exponentialMovingAverage)
    let copied = svgf.copy(with: nil, device: device)
    precondition(copied.channelCount == 3)
    precondition(copied.variancePrefilterSigma == 0.5)
    svgf.encode(with: NSCoder())
    precondition(MPSSVGF(coder: NSCoder(), device: device) == nil)
    let texture = device.makeTexture(
        descriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: 4, height: 4, mipmapped: false)
    )
    MPSHostBoundary.reset()
    svgf.encodeReprojection(
        to: cmd,
        sourceTexture: texture,
        previousTexture: texture,
        destinationTexture: texture,
        previousLuminanceMomentsTexture: texture,
        destinationLuminanceMomentsTexture: texture,
        previousFrameCount: texture,
        destinationFrameCount: texture,
        motionVectorTexture: nil,
        depthNormalTexture: nil,
        previousDepthNormalTexture: nil
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    svgf.encodeReprojection(
        to: cmd,
        sourceTexture: texture,
        previousTexture: texture,
        destinationTexture: texture,
        previousLuminanceMomentsTexture: texture,
        destinationLuminanceMomentsTexture: texture,
        sourceTexture2: texture,
        previousTexture2: texture,
        destinationTexture2: texture,
        previousLuminanceMomentsTexture2: texture,
        destinationLuminanceMomentsTexture2: texture,
        previousFrameCount: texture,
        destinationFrameCount: texture,
        motionVectorTexture: texture,
        depthNormalTexture: texture,
        previousDepthNormalTexture: texture
    )
    MPSHostBoundary.reset()
    svgf.encodeVarianceEstimation(
        to: cmd,
        sourceTexture: texture,
        luminanceMomentsTexture: texture,
        destinationTexture: texture,
        frameCount: texture,
        depthNormalTexture: nil
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    svgf.encodeVarianceEstimation(
        to: cmd,
        sourceTexture: texture,
        luminanceMomentsTexture: texture,
        destinationTexture: texture,
        sourceTexture2: texture,
        luminanceMomentsTexture2: texture,
        destinationTexture2: texture,
        frameCount: texture,
        depthNormalTexture: texture
    )
    MPSHostBoundary.reset()
    svgf.encodeBilateralFilter(to: cmd, stepDistance: 1, sourceTexture: texture, destinationTexture: texture, depthNormalTexture: texture)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    svgf.encodeBilateralFilter(
        to: cmd,
        stepDistance: 2,
        sourceTexture: texture,
        destinationTexture: texture,
        sourceTexture2: texture,
        destinationTexture2: texture,
        depthNormalTexture: texture
    )
}

func testMPSCNNConvolutionTranspose() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = MPSTestConvolutionDataSource()
    let transpose = MPSCNNConvolutionTranspose(device: device, weights: source)
    precondition(transpose.inputFeatureChannels == 1)
    precondition(transpose.outputFeatureChannels == 1)
    precondition(transpose.groups == 1)
    _ = transpose.dataSource
    transpose.accumulatorPrecisionOption = .float
    transpose.kernelOffsetX = 1
    transpose.kernelOffsetY = -1
    precondition(transpose.kernelOffsetX == 1 && transpose.kernelOffsetY == -1)
    let image = mpsDepthUnorm(device, width: 2, height: 2)
    let conv = MPSCNNConvolution(device: device, weights: source)
    let gradient = MPSCNNConvolutionGradientState(convolution: conv)
    MPSHostBoundary.reset()
    transpose.encode(commandBuffer: cmd, sourceImage: image, convolutionGradientState: gradient, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = transpose.encode(commandBuffer: cmd, sourceImage: image, convolutionGradientState: gradient)
    var outState: MPSCNNConvolutionTransposeGradientState?
    _ = transpose.encode(
        commandBuffer: cmd,
        sourceImage: image,
        convolutionGradientState: gradient,
        destinationState: &outState,
        destinationStateIsTemporary: false
    )
    transpose.encodeBatch(commandBuffer: cmd, sourceImages: [image], convolutionGradientStates: [gradient], destinationImages: [image])
    _ = transpose.encodeBatch(commandBuffer: cmd, sourceImages: [image], convolutionGradientStates: [gradient])
    var batchStates: NSArray?
    _ = transpose.encodeBatch(
        commandBuffer: cmd,
        sourceImages: [image],
        convolutionGradientStates: [gradient],
        destinationStates: &batchStates,
        destinationStateIsTemporary: true
    )
    _ = transpose.exportWeightsAndBiases(with: cmd, resultStateCanBeTemporary: false)
    transpose.reloadWeightsAndBiasesFromDataSource()
    transpose.reloadWeightsAndBiases(with: cmd, state: MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: source.descriptor()))
    let tState = transpose.resultState(sourceImage: image, sourceStates: [gradient], destinationImage: image)
    precondition(tState?.convolutionTranspose === transpose)
    _ = transpose.resultStateBatch(sourceImage: [image], sourceStates: [[gradient]], destinationImage: [image])
    _ = transpose.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: [gradient], destinationImage: image)
    _ = transpose.temporaryResultStateBatch(commandBuffer: cmd, sourceImage: [image], sourceStates: [[gradient]], destinationImage: [image])
    _ = MPSCNNConvolutionTransposeGradientStateNode()
    precondition(MPSCNNConvolutionTranspose(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNConvolutionTranspose(device: device)
}

func testMPSCNNYOLOLoss() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let anchors = Data([0, 1, 2, 3])
    let descriptor = MPSCNNYOLOLossDescriptor.cnnLossDescriptor(
        withXYLossType: .meanSquaredError,
        whLossType: .meanAbsoluteError,
        confidenceLossType: .sigmoidCrossEntropy,
        classesLossType: .softMaxCrossEntropy,
        reductionType: .sum,
        anchorBoxes: anchors,
        numberOfAnchorBoxes: 2
    )
    descriptor.rescore = false
    descriptor.scaleXY = 0.5
    descriptor.scaleWH = 0.25
    descriptor.scaleNoObject = 0.1
    descriptor.scaleObject = 1.2
    descriptor.scaleClass = 0.8
    descriptor.minIOUForObjectPresence = 0.3
    descriptor.maxIOUForObjectAbsence = 0.7
    descriptor.reduceAcrossBatch = true
    descriptor.numberOfAnchorBoxes = 2
    descriptor.anchorBoxes = anchors
    descriptor.xyLossDescriptor.weight = 2
    descriptor.whLossDescriptor.weight = 3
    descriptor.confidenceLossDescriptor.weight = 4
    descriptor.classesLossDescriptor.weight = 5
    precondition(descriptor.xyLossDescriptor.lossType == .meanSquaredError)
    precondition(descriptor.whLossDescriptor.lossType == .meanAbsoluteError)
    precondition(descriptor.rescore == false)
    let yolo = MPSCNNYOLOLoss(device: device, lossDescriptor: descriptor)
    precondition(yolo.lossXY.lossType == .meanSquaredError)
    precondition(yolo.lossWH.lossType == .meanAbsoluteError)
    precondition(yolo.lossConfidence.lossType == .sigmoidCrossEntropy)
    precondition(yolo.lossClasses.lossType == .softMaxCrossEntropy)
    precondition(yolo.scaleXY == 0.5 && yolo.scaleWH == 0.25)
    precondition(yolo.scaleNoObject == 0.1 && yolo.scaleObject == 1.2 && yolo.scaleClass == 0.8)
    precondition(yolo.minIOUForObjectPresence == 0.3)
    precondition(yolo.maxIOUForObjectAbsence == 0.7)
    precondition(yolo.reductionType == .sum)
    precondition(yolo.numberOfAnchorBoxes == 2)
    precondition(yolo.anchorBoxes.count == 4)
    precondition(yolo.reduceAcrossBatch)
    let image = mpsDepthUnorm(device, width: 2, height: 2)
    let labelsDesc = MPSCNNLossDataDescriptor(
        data: Data(repeating: 0, count: 4),
        layout: .HeightxWidthxFeatureChannels,
        size: MTLSize(width: 2, height: 2, depth: 1)
    )!
    let labels = MPSCNNLossLabels(device: device, labelsDescriptor: labelsDesc)
    MPSHostBoundary.reset()
    yolo.encode(commandBuffer: cmd, sourceImage: image, labels: labels, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = yolo.encode(commandBuffer: cmd, sourceImage: image, labels: labels)
    yolo.encode(commandBuffer: cmd, sourceImages: [image], labels: [labels], destinationImages: [image])
    _ = yolo.encode(commandBuffer: cmd, sourceImages: [image], labels: [labels])
    precondition(MPSCNNYOLOLoss(coder: NSCoder(), device: device) == nil)
}

func testMPSLSTMAndGRUDescriptors() {
    let lstm = MPSLSTMDescriptor.createLSTMDescriptor(withInputFeatureChannels: 8, outputFeatureChannels: 16)
    precondition(lstm.inputFeatureChannels == 8)
    precondition(lstm.outputFeatureChannels == 16)
    lstm.memoryWeightsAreDiagonal = true
    lstm.inputGateInputWeights = MPSTestConvolutionDataSource()
    lstm.inputGateRecurrentWeights = MPSTestConvolutionDataSource()
    lstm.inputGateMemoryWeights = MPSTestConvolutionDataSource()
    lstm.forgetGateInputWeights = MPSTestConvolutionDataSource()
    lstm.forgetGateRecurrentWeights = MPSTestConvolutionDataSource()
    lstm.forgetGateMemoryWeights = MPSTestConvolutionDataSource()
    lstm.outputGateInputWeights = MPSTestConvolutionDataSource()
    lstm.outputGateRecurrentWeights = MPSTestConvolutionDataSource()
    lstm.outputGateMemoryWeights = MPSTestConvolutionDataSource()
    lstm.cellGateInputWeights = MPSTestConvolutionDataSource()
    lstm.cellGateRecurrentWeights = MPSTestConvolutionDataSource()
    lstm.cellGateMemoryWeights = MPSTestConvolutionDataSource()
    lstm.cellToOutputNeuronType = .tanH
    lstm.cellToOutputNeuronParamA = 0.5
    lstm.cellToOutputNeuronParamB = 0.25
    lstm.cellToOutputNeuronParamC = 0.1
    precondition(lstm.memoryWeightsAreDiagonal)
    precondition(lstm.inputGateInputWeights != nil)
    precondition(lstm.cellToOutputNeuronParamA == 0.5)
    let gru = MPSGRUDescriptor.createGRUDescriptor(withInputFeatureChannels: 4, outputFeatureChannels: 4)
    gru.inputGateInputWeights = MPSTestConvolutionDataSource()
    gru.inputGateRecurrentWeights = MPSTestConvolutionDataSource()
    gru.recurrentGateInputWeights = MPSTestConvolutionDataSource()
    gru.recurrentGateRecurrentWeights = MPSTestConvolutionDataSource()
    gru.outputGateInputWeights = MPSTestConvolutionDataSource()
    gru.outputGateRecurrentWeights = MPSTestConvolutionDataSource()
    gru.outputGateInputGateWeights = MPSTestConvolutionDataSource()
    gru.gatePnormValue = 2
    gru.flipOutputGates = true
    precondition(gru.flipOutputGates && gru.gatePnormValue == 2)
    precondition(gru.outputGateInputGateWeights != nil)
}

func testMPSNNForwardLossNode() {
    let source = MPSNNImageNode(handle: nil)
    let labels = MPSNNImageNode(handle: nil)
    let weights = MPSNNImageNode(handle: nil)
    let descriptor = MPSCNNLossDescriptor(type: .meanSquaredError, reductionType: .mean)
    descriptor.weight = 2
    descriptor.labelSmoothing = 0.1
    descriptor.numberOfClasses = 10
    descriptor.epsilon = 1e-4
    descriptor.delta = 0.5
    descriptor.reduceAcrossBatch = true
    let node = MPSNNForwardLossNode(source: source, labels: labels, lossDescriptor: descriptor)
    precondition(node.lossType == .meanSquaredError)
    precondition(node.reductionType == .mean)
    precondition(node.weight == 2)
    precondition(node.labelSmoothing == 0.1)
    precondition(node.numberOfClasses == 10)
    precondition(node.epsilon == 1e-4)
    precondition(node.delta == 0.5)
    precondition(node.reduceAcrossBatch)
    node.propertyCallBack = MPSTestLossCallback()
    precondition(node.propertyCallBack != nil)
    let withWeights = MPSNNForwardLossNode(source: source, labels: labels, weights: weights, lossDescriptor: descriptor)
    _ = withWeights.lossType
    let fromSources = MPSNNForwardLossNode(sources: [source, labels], lossDescriptor: descriptor)
    _ = fromSources.numberOfClasses
    let gradient = node.gradientFilter(withSource: source)
    precondition(gradient.lossType == .meanSquaredError)
    _ = node.gradientFilter(withSources: [source])
    _ = node.gradientFilters(withSource: source)
    _ = node.gradientFilters(withSources: [source])
}

func testMPSNNLossGradientNode() {
    let source = MPSNNImageNode(handle: nil)
    let descriptor = MPSCNNLossDescriptor(type: .huber, reductionType: .sum)
    descriptor.delta = 1.5
    descriptor.weight = 3
    descriptor.labelSmoothing = 0.2
    descriptor.numberOfClasses = 4
    descriptor.epsilon = 1e-6
    descriptor.reduceAcrossBatch = false
    let node = MPSNNLossGradientNode(
        sourceGradient: source,
        sourceImage: source,
        labels: source,
        gradientState: nil,
        lossDescriptor: descriptor,
        isLabelsGradientFilter: true
    )
    precondition(node.isLabelsGradientFilter)
    precondition(node.lossType == .huber)
    precondition(node.reductionType == .sum)
    precondition(node.weight == 3)
    precondition(node.labelSmoothing == 0.2)
    precondition(node.numberOfClasses == 4)
    precondition(node.epsilon == 1e-6)
    precondition(node.delta == 1.5)
    precondition(!node.reduceAcrossBatch)
    node.propertyCallBack = MPSTestLossCallback()
    _ = node.propertyCallBack?.scalarWeight(
        forSourceImage: mpsDepthUnorm(MPSHostDevice.shared, width: 1, height: 1),
        destinationImage: mpsDepthUnorm(MPSHostDevice.shared, width: 1, height: 1)
    )
    let withWeights = MPSNNLossGradientNode(
        sourceGradient: source,
        sourceImage: source,
        labels: source,
        weights: source,
        gradientState: nil,
        lossDescriptor: descriptor,
        isLabelsGradientFilter: false
    )
    precondition(!withWeights.isLabelsGradientFilter)
    let fromSources = MPSNNLossGradientNode(
        sources: [source, source, source],
        gradientState: nil,
        lossDescriptor: descriptor,
        isLabelsGradientFilter: false
    )
    _ = fromSources.delta
}

func testMPSRNNMatrixTrainingLayer() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let rnn = MPSLSTMDescriptor.createLSTMDescriptor(withInputFeatureChannels: 2, outputFeatureChannels: 3)
    let weightsOut = NSMutableArray()
    let layer = MPSRNNMatrixTrainingLayer(device: device, rnnDescriptor: rnn, trainableWeights: weightsOut)
    precondition(layer.inputFeatureChannels == 2)
    precondition(layer.outputFeatureChannels == 3)
    precondition(weightsOut.count >= 1)
    layer.storeAllIntermediateStates = true
    layer.recurrentOutputIsTemporary = true
    layer.trainingStateIsTemporary = true
    layer.accumulateWeightGradients = true
    precondition(layer.storeAllIntermediateStates && layer.recurrentOutputIsTemporary)
    precondition(layer.trainingStateIsTemporary && layer.accumulateWeightGradients)
    let copied = layer.copy(with: nil, device: device)
    precondition(copied.inputFeatureChannels == 2)
    let grads = NSMutableArray()
    layer.createWeightGradientMatrices(grads, dataType: .float32)
    precondition(grads.count >= 1)
    let temp = NSMutableArray()
    layer.createTemporaryWeightGradientMatrices(temp, dataType: .float32, commandBuffer: cmd)
    precondition(temp.count >= 1)
    let source = mpsDepthFloatMatrix(device, rows: 1, columns: 2, values: [1, 2])
    let dest = mpsDepthFloatMatrix(device, rows: 1, columns: 3, values: [0, 0, 0])
    let weights: [MPSMatrix] = (weightsOut as? [MPSMatrix]) ?? []
    let training = NSMutableArray()
    MPSHostBoundary.reset()
    layer.encodeForwardSequence(
        commandBuffer: cmd,
        sourceMatrices: [source],
        destinationMatrices: [dest],
        trainingStates: training,
        weights: weights
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var sourceOff = 0
    var destOff = 0
    var gradOff = 0
    var destGradOff = 0
    let recurrentOut = NSMutableArray()
    layer.encodeForwardSequence(
        commandBuffer: cmd,
        sourceMatrices: [source],
        sourceOffsets: &sourceOff,
        destinationMatrices: [dest],
        destinationOffsets: &destOff,
        trainingStates: training,
        recurrentInputState: MPSRNNRecurrentMatrixState(resource: nil),
        recurrentOutputStates: recurrentOut,
        weights: weights
    )
    let states = (training as? [MPSRNNMatrixTrainingState]) ?? []
    MPSHostBoundary.reset()
    layer.encodeGradientSequence(
        commandBuffer: cmd,
        forwardSources: [source],
        sourceGradients: [dest],
        destinationGradients: [source],
        weightGradients: weights,
        trainingStates: states,
        weights: weights
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    layer.encodeGradientSequence(
        commandBuffer: cmd,
        forwardSources: [source],
        forwardSourceOffsets: &sourceOff,
        sourceGradients: [dest],
        sourceOffsets: &gradOff,
        destinationGradients: [source],
        destinationOffsets: &destGradOff,
        weightGradients: weights,
        trainingStates: states,
        recurrentInputState: MPSRNNRecurrentMatrixState(recurrent: [source], memory: [dest]),
        recurrentOutputStates: recurrentOut,
        weights: weights
    )
    MPSHostBoundary.reset()
    if let weight = weights.first {
        layer.encodeCopyWeights(
            commandBuffer: cmd,
            weights: weights,
            matrixId: .lstmInputGateInputWeights,
            matrix: weight,
            copyFromWeightsToMatrix: true,
            matrixOffset: MTLOrigin(x: 0, y: 0, z: 0)
        )
        precondition(MPSHostBoundary.lastRefusedAPI != nil)
    }
    let recurrent = MPSRNNRecurrentMatrixState(recurrent: [source], memory: [dest])
    precondition(recurrent.getRecurrentOutputMatrix(forLayerIndex: 0) != nil)
    precondition(recurrent.getMemoryCellMatrix(forLayerIndex: 0) != nil)
    _ = MPSRNNMatrixTrainingState(resource: nil)
    precondition(MPSRNNMatrixTrainingLayer(coder: NSCoder(), device: device) == nil)
}

func testMPSCNNBatchNormalization() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let data = MPSTestBatchNormDataSource(channels: 2)
    precondition(data.load())
    precondition(data.numberOfFeatureChannels() == 2)
    precondition(data.gamma()?[0] == 1)
    precondition(data.beta()?[0] == 0)
    precondition(data.mean()?[0] == 0)
    precondition(data.variance()?[0] == 1)
    precondition(data.label() == "bn-test")
    data.purge()
    _ = data.copy()
    _ = data.copy(with: nil, device: device)
    _ = data.epsilon()
    precondition(MPSTestBatchNormDataSource.supportsSecureCoding == false)
    data.encode(with: NSCoder())
    precondition(MPSTestBatchNormDataSource(coder: NSCoder()) == nil)
    let fused = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .reLU)
    let bn = MPSCNNBatchNormalization(device: device, dataSource: data, fusedNeuronDescriptor: fused)
    precondition(bn.numberOfFeatureChannels == 2)
    bn.epsilon = 1e-4
    precondition(bn.epsilon == 1e-4)
    _ = bn.dataSource
    let convenience = MPSCNNBatchNormalization(device: device, dataSource: data)
    _ = convenience.numberOfFeatureChannels
    bn.reloadDataSource(data)
    bn.reloadGammaAndBetaFromDataSource()
    bn.reloadMeanAndVarianceFromDataSource()
    let gammaBeta = MPSCNNNormalizationGammaAndBetaState(
        gamma: device.makeBuffer(length: 8),
        beta: device.makeBuffer(length: 8)
    )
    precondition(gammaBeta.gamma.length == 8)
    precondition(gammaBeta.beta.length == 8)
    let tempGB = MPSCNNNormalizationGammaAndBetaState.temporaryState(with: cmd, numberOfFeatureChannels: 2)
    _ = tempGB.gamma
    bn.reloadGammaAndBeta(with: cmd, gammaAndBetaState: gammaBeta)
    let meanVar = MPSCNNNormalizationMeanAndVarianceState(
        mean: device.makeBuffer(length: 8),
        variance: device.makeBuffer(length: 8)
    )
    precondition(meanVar.mean.length == 8)
    precondition(meanVar.variance.length == 8)
    let tempMV = MPSCNNNormalizationMeanAndVarianceState.temporaryState(with: cmd, numberOfFeatureChannels: 2)
    _ = tempMV.variance
    bn.reloadMeanAndVariance(with: cmd, meanAndVarianceState: meanVar)
    let image = mpsDepthUnorm(device, width: 2, height: 2)
    let state = bn.resultState(sourceImage: image, sourceStates: nil, destinationImage: image)!
    precondition(state.batchNormalization === bn)
    precondition(state.gamma() != nil && state.beta() != nil)
    precondition(state.mean() != nil && state.variance() != nil)
    precondition(state.gradientForGamma() != nil && state.gradientForBeta() != nil)
    state.reset()
    _ = data.updateGammaAndBeta(with: state)
    precondition(data.updateGammaAndBeta(with: cmd, batchNormalizationState: state) == nil)
    _ = data.updateMeanAndVariance(with: state)
    precondition(data.updateMeanAndVariance(with: cmd, batchNormalizationState: state) == nil)
    _ = bn.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image)
    MPSHostBoundary.reset()
    bn.encode(to: cmd, sourceImage: image, batchNormalizationState: state, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    bn.encodeBatch(to: cmd, sourceImages: [image], batchNormalizationState: state, destinationImages: [image])
    let grad = MPSCNNBatchNormalizationGradient(device: device, fusedNeuronDescriptor: fused)
    MPSHostBoundary.reset()
    grad.encode(to: cmd, sourceGradient: image, sourceImage: image, batchNormalizationState: state, destinationGradient: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = grad.encode(to: cmd, sourceGradient: image, sourceImage: image, batchNormalizationState: state)
    grad.encodeBatch(to: cmd, sourceGradients: [image], sourceImages: [image], batchNormalizationState: state, destinationGradients: [image])
    _ = grad.encodeBatch(to: cmd, sourceGradients: [image], sourceImages: [image], batchNormalizationState: state)
    precondition(MPSCNNBatchNormalizationGradient(coder: NSCoder(), device: device) == nil)
    let node = MPSCNNBatchNormalizationNode(source: MPSNNImageNode(handle: nil), dataSource: data)
    node.flags = .calculateStatisticsAlways
    node.trainingStyle = .updateDeviceCPU
    precondition(node.flags.contains(.calculateStatisticsAlways))
    precondition(MPSCNNBatchNormalization(coder: NSCoder(), device: device) == nil)
}

func testMPSNDArrayKernels() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let desc = MPSNDArrayDescriptor(dataType: .float32, shape: [2, 2])
    let array = MPSNDArray(device: device, descriptor: desc)
    let base = MPSNDArrayMultiaryBase(device: device, sourceCount: 2)
    precondition(base.destinationArrayAllocator is MPSNDArrayDefaultAllocator)
    base.destinationArrayAllocator = MPSNDArray.defaultAllocator()
    let destDesc = base.destinationArrayDescriptor(forSourceArrays: [array], sourceState: nil)
    precondition(destDesc.length(ofDimension: 0) == 2)
    _ = base.dilationRates(forSourceIndex: 0)
    _ = base.edgeMode(atSourceIndex: 0)
    _ = base.kernelSizes(forSourceIndex: 0)
    _ = base.offsets(atSourceIndex: 0)
    _ = base.strides(forSourceIndex: 1)
    precondition(base.resultState(forSourceArrays: [array], sourceStates: nil, destinationArray: array) == nil)
    base.encode(with: NSCoder())
    _ = base.copy(with: nil, device: device)
    _ = MPSNDArrayMultiaryBase(coder: NSCoder(), device: device)

    let multi = MPSNDArrayMultiaryKernel(device: device, sourceCount: 2)
    MPSHostBoundary.reset()
    multi.encode(to: cmd, sourceArrays: [array, array], destinationArray: array)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = multi.encode(to: cmd, sourceArrays: [array, array])
    multi.encode(to: cmd, sourceArrays: [array, array], resultState: nil, destinationArray: array)
    var state: MPSState?
    _ = multi.encode(to: cmd, sourceArrays: [array, array], resultState: &state, outputStateIsTemporary: false)
    multi.encode(to: nil, commandBuffer: cmd, sourceArrays: [array, array], destinationArray: array)
    _ = MPSNDArrayMultiaryKernel(coder: NSCoder(), device: device)

    let binary = MPSNDArrayBinaryKernel(device: device)
    _ = binary.primaryOffsets
    _ = binary.secondaryOffsets
    _ = binary.primaryKernelSizes
    _ = binary.secondaryKernelSizes
    _ = binary.primaryDilationRates
    _ = binary.secondaryDilationRates
    _ = binary.primaryStrides
    _ = binary.secondaryStrides
    _ = binary.primaryEdgeMode
    _ = binary.secondaryEdgeMode
    MPSHostBoundary.reset()
    binary.encode(to: cmd, primarySourceArray: array, secondarySourceArray: array, destinationArray: array)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = binary.encode(to: cmd, primarySourceArray: array, secondarySourceArray: array)
    binary.encode(to: cmd, primarySourceArray: array, secondarySourceArray: array, resultState: nil, destinationArray: array)
    _ = binary.encode(to: cmd, primarySourceArray: array, secondarySourceArray: array, resultState: &state, outputStateIsTemporary: true)
    _ = MPSNDArrayBinaryKernel(coder: NSCoder(), device: device)

    let unary = MPSNDArrayUnaryKernel(device: device)
    _ = unary.offsets
    _ = unary.kernelSizes
    _ = unary.dilationRates
    _ = unary.strides
    _ = unary.edgeMode
    MPSHostBoundary.reset()
    unary.encode(to: cmd, sourceArray: array, destinationArray: array)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = unary.encode(to: cmd, sourceArray: array)
    unary.encode(to: cmd, sourceArray: array, resultState: nil, destinationArray: array)
    _ = unary.encode(to: cmd, sourceArray: array, resultState: &state, outputStateIsTemporary: false)
    _ = MPSNDArrayUnaryKernel(coder: NSCoder(), device: device)
}

func testMPSNNBinaryArithmeticNode() {
    let left = MPSNNImageNode(handle: nil)
    let right = MPSNNImageNode(handle: nil)
    let node = MPSNNBinaryArithmeticNode(leftSource: left, rightSource: right)
    node.primaryScale = 2
    node.secondaryScale = 3
    node.bias = 0.5
    node.minimumValue = -1
    node.maximumValue = 1
    node.primaryStrideInPixelsX = 2
    node.primaryStrideInPixelsY = 2
    node.primaryStrideInFeatureChannels = 1
    node.secondaryStrideInPixelsX = 1
    node.secondaryStrideInPixelsY = 1
    node.secondaryStrideInFeatureChannels = 1
    precondition(node.primaryScale == 2 && node.secondaryScale == 3)
    precondition(node.bias == 0.5)
    precondition(node.minimumValue == -1 && node.maximumValue == 1)
    precondition(node.primaryStrideInPixelsX == 2)
    _ = node.gradientClass()
    _ = node.gradientFilters(withSources: [left, right])
    let fromSources = MPSNNBinaryArithmeticNode(sources: [left, right])
    _ = fromSources.primaryScale
}

func testMPSCNNLossAndForwardLoss() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let descriptor = MPSCNNLossDescriptor(type: .meanAbsoluteError, reductionType: .mean)
    descriptor.weight = 1.5
    descriptor.labelSmoothing = 0.05
    descriptor.numberOfClasses = 3
    descriptor.epsilon = 1e-5
    descriptor.delta = 0.25
    descriptor.reduceAcrossBatch = false
    precondition(descriptor.lossType == .meanAbsoluteError)
    precondition(descriptor.reductionType == .mean)
    let loss = MPSCNNLoss(device: device, lossDescriptor: descriptor)
    precondition(loss.lossType == .meanAbsoluteError)
    precondition(loss.reductionType == .mean)
    precondition(loss.weight == 1.5)
    precondition(loss.labelSmoothing == 0.05)
    precondition(loss.numberOfClasses == 3)
    precondition(loss.epsilon == 1e-5)
    precondition(loss.delta == 0.25)
    precondition(!loss.reduceAcrossBatch)
    let image = mpsDepthUnorm(device, width: 2, height: 2)
    let labelsDesc = MPSCNNLossDataDescriptor(
        data: Data(repeating: 1, count: 8),
        layout: .HeightxWidthxFeatureChannels,
        size: MTLSize(width: 2, height: 2, depth: 1)
    )!
    labelsDesc.bytesPerRow = 8
    labelsDesc.bytesPerImage = 16
    precondition(labelsDesc.layout == .HeightxWidthxFeatureChannels)
    precondition(labelsDesc.size.width == 2)
    let labels = MPSCNNLossLabels(device: device, labelsDescriptor: labelsDesc)
    _ = labels.labelsImage()
    _ = labels.lossImage()
    _ = labels.weightsImage()
    let sized = MPSCNNLossLabels(
        device: device,
        lossImageSize: MTLSize(width: 1, height: 1, depth: 1),
        labelsDescriptor: labelsDesc,
        weightsDescriptor: labelsDesc
    )
    _ = sized.lossImage()
    let fromImages = MPSCNNLossLabels(device: device, lossImageSize: MTLSize(width: 1, height: 1, depth: 1), labelsImage: image, weightsImage: image)
    _ = fromImages.labelsImage()
    MPSHostBoundary.reset()
    loss.encode(commandBuffer: cmd, sourceImage: image, labels: labels, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = loss.encode(commandBuffer: cmd, sourceImage: image, labels: labels)
    loss.encode(commandBuffer: cmd, sourceImages: [image], labels: [labels], destinationImages: [image])
    _ = loss.encode(commandBuffer: cmd, sourceImages: [image], labels: [labels])
    precondition(MPSCNNLoss(coder: NSCoder(), device: device) == nil)

    let forward = MPSNNForwardLoss(device: device, lossDescriptor: descriptor)
    forward.weight = 2
    forward.labelSmoothing = 0.2
    forward.epsilon = 1e-3
    forward.delta = 0.4
    precondition(forward.lossType == .meanAbsoluteError)
    precondition(forward.numberOfClasses == 3)
    precondition(forward.reductionType == .mean)
    precondition(!forward.reduceAcrossBatch)
    MPSHostBoundary.reset()
    forward.encodeBatch(
        commandBuffer: cmd,
        sourceImages: [image],
        labels: [image],
        weights: [image],
        destinationStates: nil,
        destinationImages: [image]
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var outStates: NSArray?
    _ = forward.encodeBatch(
        commandBuffer: cmd,
        sourceImages: [image],
        labels: [image],
        weights: nil,
        outStates: &outStates,
        isTemporary: false
    )
    precondition(MPSNNForwardLoss(coder: NSCoder(), device: device) == nil)

    let grad = MPSNNLossGradient(device: device, lossDescriptor: descriptor)
    grad.computeLabelGradients = true
    grad.weight = 1
    grad.labelSmoothing = 0
    grad.epsilon = 1e-6
    grad.delta = 1
    precondition(grad.computeLabelGradients)
    precondition(grad.lossType == .meanAbsoluteError)
    precondition(grad.numberOfClasses == 3)
    precondition(grad.reductionType == .mean)
    precondition(!grad.reduceAcrossBatch)
    MPSHostBoundary.reset()
    grad.encodeBatch(
        commandBuffer: cmd,
        sourceGradients: [image],
        sourceImages: [image],
        labels: [image],
        weights: nil,
        sourceStates: nil,
        destinationGradients: [image]
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = grad.encodeBatch(
        commandBuffer: cmd,
        sourceGradients: [image],
        sourceImages: [image],
        labels: [image],
        weights: nil,
        sourceStates: nil
    )
    precondition(MPSNNLossGradient(coder: NSCoder(), device: device) == nil)
}

func testMPSNNOptimizerAdamCPU() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let descriptor = MPSNNOptimizerDescriptor(
        learningRate: 0.001,
        gradientRescale: 1,
        applyGradientClipping: false,
        gradientClipMax: 1,
        gradientClipMin: -1,
        regularizationType: .None,
        regularizationScale: 0
    )
    precondition(descriptor.learningRate == 0.001)
    descriptor.learningRate = 0.001
    descriptor.gradientRescale = 1
    descriptor.applyGradientClipping = false
    descriptor.gradientClipMax = 1
    descriptor.gradientClipMin = -1
    descriptor.regularizationType = .None
    descriptor.regularizationScale = 0
    let short = MPSNNOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .L2,
        regularizationScale: 0.001
    )
    precondition(short.regularizationType == .L2)
    let adam = MPSNNOptimizerAdam(
        device: device,
        beta1: 0.9,
        beta2: 0.999,
        epsilon: 1e-8,
        timeStep: 0,
        optimizerDescriptor: descriptor
    )
    precondition(adam.beta1 == 0.9 && adam.beta2 == 0.999)
    precondition(adam.epsilon == 1e-8)
    adam.timeStep = 0
    precondition(adam.learningRate == 0.001)
    adam.setLearningRate(0.001)
    precondition(!adam.applyGradientClipping)
    _ = adam.gradientClipMax
    _ = adam.gradientClipMin
    _ = adam.gradientRescale
    _ = adam.regularizationScale
    _ = adam.regularizationType
    let g = mpsDepthFloatVector(device, values: [1])
    let v = mpsDepthFloatVector(device, values: [1])
    let m = mpsDepthFloatVector(device, values: [0])
    let vel = mpsDepthFloatVector(device, values: [0])
    let out = mpsDepthFloatVector(device, values: [0])
    adam.encode(
        commandBuffer: cmd,
        inputGradientVector: g,
        inputValuesVector: v,
        inputMomentumVector: m,
        inputVelocityVector: vel,
        resultValuesVector: out
    )
    let result = out.data.contents.bindMemory(to: Float.self, capacity: 1)[0]
    // t=1, m=0.1, v=0.001, mHat=1, vHat=1, step=0.001, theta=0.999
    precondition(abs(result - 0.999) < 1e-5, "adam vector got \(result)")
    precondition(adam.timeStep == 1)
    let g2 = mpsDepthFloatVector(device, values: [1])
    let v2 = mpsDepthFloatVector(device, values: [1])
    let m2 = mpsDepthFloatVector(device, values: [0])
    let vel2 = mpsDepthFloatVector(device, values: [0])
    let maxv = mpsDepthFloatVector(device, values: [1])
    let out2 = mpsDepthFloatVector(device, values: [0])
    let adam2 = MPSNNOptimizerAdam(device: device, learningRate: 0.001)
    adam2.encode(
        commandBuffer: cmd,
        inputGradientVector: g2,
        inputValuesVector: v2,
        inputMomentumVector: m2,
        inputVelocityVector: vel2,
        maximumVelocityVector: maxv,
        resultValuesVector: out2
    )
    let gm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [1])
    let vm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [1])
    let mm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    let velm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    let outm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    let adam3 = MPSNNOptimizerAdam(device: device, learningRate: 0.001)
    adam3.encode(
        commandBuffer: cmd,
        inputGradientMatrix: gm,
        inputValuesMatrix: vm,
        inputMomentumMatrix: mm,
        inputVelocityMatrix: velm,
        resultValuesMatrix: outm
    )
    let matrixResult = outm.data.contents.bindMemory(to: Float.self, capacity: 1)[0]
    precondition(abs(matrixResult - 0.999) < 1e-5, "adam matrix got \(matrixResult)")
    adam3.encode(
        commandBuffer: cmd,
        inputGradientMatrix: gm,
        inputValuesMatrix: vm,
        inputMomentumMatrix: mm,
        inputVelocityMatrix: velm,
        maximumVelocityMatrix: vm,
        resultValuesMatrix: outm
    )
    let conv = MPSCNNConvolution(device: device, weights: MPSTestConvolutionDataSource())
    let convGrad = MPSCNNConvolutionGradientState(convolution: conv)
    let weightsState = MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: MPSTestConvolutionDataSource().descriptor())
    MPSHostBoundary.reset()
    adam.encode(
        commandBuffer: cmd,
        convolutionGradientState: convGrad,
        convolutionSourceState: weightsState,
        inputMomentumVectors: nil,
        inputVelocityVectors: nil,
        resultState: weightsState
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    adam.encode(
        commandBuffer: cmd,
        convolutionGradientState: convGrad,
        convolutionSourceState: weightsState,
        inputMomentumVectors: [m],
        inputVelocityVectors: [vel],
        maximumVelocityVectors: [maxv],
        resultState: weightsState
    )
    let bn = MPSCNNBatchNormalization(device: device, dataSource: MPSTestBatchNormDataSource(channels: 1))
    let bnState = MPSCNNBatchNormalizationState(batchNormalization: bn)
    let gb = MPSCNNNormalizationGammaAndBetaState(gamma: device.makeBuffer(length: 4), beta: device.makeBuffer(length: 4))
    MPSHostBoundary.reset()
    adam.encode(
        commandBuffer: cmd,
        batchNormalizationState: bnState,
        inputMomentumVectors: nil,
        inputVelocityVectors: nil,
        resultState: gb
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    adam.encode(
        commandBuffer: cmd,
        batchNormalizationState: bnState,
        inputMomentumVectors: [m],
        inputVelocityVectors: [vel],
        maximumVelocityVectors: nil,
        resultState: gb
    )
    adam.encode(
        commandBuffer: cmd,
        batchNormalizationGradientState: bnState,
        batchNormalizationSourceState: bnState,
        inputMomentumVectors: nil,
        inputVelocityVectors: nil,
        resultState: gb
    )
    adam.encode(
        commandBuffer: cmd,
        batchNormalizationGradientState: bnState,
        batchNormalizationSourceState: bnState,
        inputMomentumVectors: [m],
        inputVelocityVectors: [vel],
        maximumVelocityVectors: nil,
        resultState: gb
    )
}

func testMPSNNOptimizerSGDAndRMSProp() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let descriptor = MPSNNOptimizerDescriptor(
        learningRate: 0.1,
        gradientRescale: 1,
        regularizationType: .None,
        regularizationScale: 0
    )
    let sgd = MPSNNOptimizerStochasticGradientDescent(
        device: device,
        momentumScale: 0,
        useNesterovMomentum: false,
        optimizerDescriptor: descriptor
    )
    precondition(sgd.momentumScale == 0)
    precondition(!sgd.useNesterovMomentum)
    precondition(!sgd.useNestrovMomentum)
    let g = mpsDepthFloatVector(device, values: [2])
    let v = mpsDepthFloatVector(device, values: [10])
    let out = mpsDepthFloatVector(device, values: [0])
    sgd.encode(
        commandBuffer: cmd,
        inputGradientVector: g,
        inputValuesVector: v,
        inputMomentumVector: nil,
        resultValuesVector: out
    )
    let result = out.data.contents.bindMemory(to: Float.self, capacity: 1)[0]
    precondition(abs(result - 9.8) < 1e-5, "sgd vector got \(result)")
    let gm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [2])
    let vm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [10])
    let outm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    sgd.encode(
        commandBuffer: cmd,
        inputGradientMatrix: gm,
        inputValuesMatrix: vm,
        inputMomentumMatrix: nil,
        resultValuesMatrix: outm
    )
    let matrixResult = outm.data.contents.bindMemory(to: Float.self, capacity: 1)[0]
    precondition(abs(matrixResult - 9.8) < 1e-5)
    let nesterov = MPSNNOptimizerStochasticGradientDescent(
        device: device,
        momentumScale: 0.9,
        useNestrovMomentum: true,
        optimizerDescriptor: descriptor
    )
    precondition(nesterov.useNesterovMomentum)
    let sgdSimple = MPSNNOptimizerStochasticGradientDescent(device: device, learningRate: 0.1)
    _ = sgdSimple.learningRate
    let conv = MPSCNNConvolution(device: device, weights: MPSTestConvolutionDataSource())
    let convGrad = MPSCNNConvolutionGradientState(convolution: conv)
    let weightsState = MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: MPSTestConvolutionDataSource().descriptor())
    MPSHostBoundary.reset()
    sgd.encode(
        commandBuffer: cmd,
        convolutionGradientState: convGrad,
        convolutionSourceState: weightsState,
        inputMomentumVectors: nil,
        resultState: weightsState
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let bn = MPSCNNBatchNormalization(device: device, dataSource: MPSTestBatchNormDataSource(channels: 1))
    let bnState = MPSCNNBatchNormalizationState(batchNormalization: bn)
    let gb = MPSCNNNormalizationGammaAndBetaState(gamma: device.makeBuffer(length: 4), beta: device.makeBuffer(length: 4))
    sgd.encode(commandBuffer: cmd, batchNormalizationState: bnState, inputMomentumVectors: nil, resultState: gb)
    sgd.encode(
        commandBuffer: cmd,
        batchNormalizationGradientState: bnState,
        batchNormalizationSourceState: bnState,
        inputMomentumVectors: nil,
        resultState: gb
    )

    let rms = MPSNNOptimizerRMSProp(device: device, decay: 0.9, epsilon: 1e-8, optimizerDescriptor: descriptor)
    precondition(rms.decay == 0.9)
    precondition(rms.epsilon == 1e-8)
    let rg = mpsDepthFloatVector(device, values: [1])
    let rv = mpsDepthFloatVector(device, values: [1])
    let rs = mpsDepthFloatVector(device, values: [0])
    let rout = mpsDepthFloatVector(device, values: [0])
    rms.encode(
        commandBuffer: cmd,
        inputGradientVector: rg,
        inputValuesVector: rv,
        inputSumOfSquaresVector: rs,
        resultValuesVector: rout
    )
    // s = 0.1, step = 0.1 * 1 / (sqrt(0.1)+1e-8) ≈ 0.316227, result ≈ 0.68377
    let rmsResult = rout.data.contents.bindMemory(to: Float.self, capacity: 1)[0]
    precondition(abs(rmsResult - (1 - 0.1 / (sqrt(0.1) + 1e-8))) < 1e-5, "rmsprop got \(rmsResult)")
    let rgm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [1])
    let rvm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [1])
    let rsm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    let routm = mpsDepthFloatMatrix(device, rows: 1, columns: 1, values: [0])
    let rms2 = MPSNNOptimizerRMSProp(device: device, learningRate: 0.1)
    rms2.encode(
        commandBuffer: cmd,
        inputGradientMatrix: rgm,
        inputValuesMatrix: rvm,
        inputSumOfSquaresMatrix: rsm,
        resultValuesMatrix: routm
    )
    MPSHostBoundary.reset()
    rms.encode(
        commandBuffer: cmd,
        convolutionGradientState: convGrad,
        convolutionSourceState: weightsState,
        inputSumOfSquaresVectors: nil,
        resultState: weightsState
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    rms.encode(commandBuffer: cmd, batchNormalizationState: bnState, inputSumOfSquaresVectors: nil, resultState: gb)
    rms.encode(
        commandBuffer: cmd,
        batchNormalizationGradientState: bnState,
        batchNormalizationSourceState: bnState,
        inputSumOfSquaresVectors: nil,
        resultState: gb
    )
}
