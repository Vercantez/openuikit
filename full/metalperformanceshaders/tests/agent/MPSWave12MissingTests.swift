import Foundation
import MetalPerformanceShaders

// MARK: - Wave 12 leftover probes
//
// Each test below is top-level, synchronous, and argument-free. Every test
// names each identifier it evidences in coverage.tsv. GPU paths are
// asserted fail-closed through `MPSHostBoundary`, never as Apple results.

final class MPSWave12TestHandle: NSObject, MPSHandle {
    static var supportsSecureCoding: Bool { true }
    let storedLabel: String
    init(label: String) { self.storedLabel = label; super.init() }
    required init?(coder: NSCoder) { self.storedLabel = ""; super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    var label: String { storedLabel }
}

final class MPSWave12TestDataSource: NSObject, MPSCNNConvolutionDataSource {
    let storedDescriptor: MPSCNNConvolutionDescriptor
    var weightStorage: UnsafeMutablePointer<Float>
    var biasStorage: UnsafeMutablePointer<Float>

    init(inputChannels: Int, outputChannels: Int) {
        storedDescriptor = MPSCNNConvolutionDescriptor(
            kernelWidth: 1,
            kernelHeight: 1,
            inputFeatureChannels: inputChannels,
            outputFeatureChannels: outputChannels
        )
        weightStorage = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        weightStorage[0] = 1
        biasStorage = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        biasStorage[0] = 0
        super.init()
    }

    deinit {
        weightStorage.deallocate()
        biasStorage.deallocate()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave12TestDataSource(inputChannels: 1, outputChannels: 1)
    }

    func biasTerms() -> UnsafeMutablePointer<Float>? { biasStorage }
    func dataType() -> MPSDataType { .float32 }
    func descriptor() -> MPSCNNConvolutionDescriptor { storedDescriptor }
    func label() -> String? { "wave12-weights" }
    func load() -> Bool { true }
    func purge() {}
    func weights() -> UnsafeMutableRawPointer { UnsafeMutableRawPointer(weightStorage) }
}

final class MPSWave12TestGroupDataSource: NSObject, MPSCNNGroupNormalizationDataSource {
    var numberOfFeatureChannels: Int = 4
    var numberOfGroups: Int = 2
    var gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: 4)
    var betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: 4)

    override init() {
        gammaStorage.initialize(repeating: 1, count: 4)
        betaStorage.initialize(repeating: 0, count: 4)
        super.init()
    }

    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }

    required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave12TestGroupDataSource()
    }

    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "wave12-group" }
}

final class MPSWave12TestInstanceDataSource: NSObject, MPSCNNInstanceNormalizationDataSource {
    var numberOfFeatureChannels: Int = 4
    var gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: 4)
    var betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: 4)

    override init() {
        gammaStorage.initialize(repeating: 1, count: 4)
        betaStorage.initialize(repeating: 0, count: 4)
        super.init()
    }

    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }

    required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave12TestInstanceDataSource()
    }

    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "wave12-instance" }
}

final class MPSWave12TestGramCallback: NSObject, MPSNNGramMatrixCallback {
    static var supportsSecureCoding: Bool { true }
    required init?(coder: NSCoder) { super.init() }
    override init() { super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave12TestGramCallback()
    }
    func alpha(forSourceImage sourceImage: MPSImage, destinationImage: MPSImage) -> Float {
        _ = (sourceImage, destinationImage)
        return 0.75
    }
}

final class MPSWave12TestSizeState: NSObject, MPSImageSizeEncodingState {
    let sourceWidth: Int
    let sourceHeight: Int
    init(width: Int, height: Int) {
        self.sourceWidth = width
        self.sourceHeight = height
        super.init()
    }
}

final class MPSWave12TestTransformProvider: NSObject, MPSImageTransformProvider {
    static var supportsSecureCoding: Bool { true }
    required init?(coder: NSCoder) { super.init() }
    override init() { super.init() }
    func encode(with coder: NSCoder) { _ = coder }
    func transform(forSourceImage image: MPSImage, handle: (any MPSHandle)?) -> MPSScaleTransform {
        _ = (image, handle)
        return MPSScaleTransform(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)
    }
}

private func mpsWave12Image(device: any MTLDevice) -> MPSImage {
    MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
}

private func mpsWave12Array(device: any MTLDevice) -> MPSNDArray {
    MPSNDArray(device: device, descriptor: MPSNDArrayDescriptor(dataType: .float32, sizes: [2]))
}

private func mpsWave12Matrix(device: any MTLDevice) -> MPSMatrix {
    MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32))
}

func testMPSWave12BatchNormStatistics() {
    let device = MPSHostDevice.shared
    let image = mpsWave12Image(device: device)
    let batchNorm = MPSCNNBatchNormalization(device: device)
    let state = MPSCNNBatchNormalizationState(batchNormalization: batchNorm)
    let stats = MPSCNNBatchNormalizationStatistics(device: device)
    precondition(MPSCNNBatchNormalizationStatistics(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    stats.encodeBatch(to: device.makeCommandBuffer(), sourceImages: [image], batchNormalizationState: state)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let gradient = MPSCNNBatchNormalizationStatisticsGradient(device: device)
    precondition(gradient.fusedNeuronDescriptor == nil)
    let neuron = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .reLU, a: 0)
    let fused = MPSCNNBatchNormalizationStatisticsGradient(device: device, fusedNeuronDescriptor: neuron)
    precondition(fused.fusedNeuronDescriptor?.neuronType == .reLU)
    precondition(MPSCNNBatchNormalizationStatisticsGradient(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    fused.encodeBatch(
        to: device.makeCommandBuffer(),
        sourceGradients: [image],
        sourceImages: [image],
        batchNormalizationState: state
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let node = MPSCNNBatchNormalizationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = node
}

func testMPSWave12BinaryConvolution() {
    let device = MPSHostDevice.shared
    let weights = MPSWave12TestDataSource(inputChannels: 4, outputChannels: 8)
    let full = MPSCNNBinaryConvolution(
        device: device,
        convolutionData: weights,
        outputBiasTerms: nil,
        outputScaleTerms: nil,
        inputBiasTerms: nil,
        inputScaleTerms: nil,
        type: .XNOR,
        flags: .useBetaScaling
    )
    precondition(full.inputFeatureChannels == 4)
    precondition(full.outputFeatureChannels == 8)
    let scaled = MPSCNNBinaryConvolution(
        device: device,
        convolutionData: weights,
        scaleValue: 0.5,
        type: .binaryWeights,
        flags: .none
    )
    precondition(scaled.inputFeatureChannels == 4 && scaled.outputFeatureChannels == 8)
    precondition(MPSCNNBinaryConvolution(coder: NSCoder(), device: device) == nil)
    let node = MPSCNNBinaryConvolutionNode(
        source: MPSNNImageNode(),
        weights: weights,
        outputBiasTerms: nil,
        outputScaleTerms: nil,
        inputBiasTerms: nil,
        inputScaleTerms: nil,
        type: .AND,
        flags: .none
    )
    _ = node
    let scaledNode = MPSCNNBinaryConvolutionNode(
        source: MPSNNImageNode(),
        weights: weights,
        scaleValue: 2,
        type: .XNOR,
        flags: .useBetaScaling
    )
    _ = scaledNode
    let fc = MPSCNNBinaryFullyConnected(
        device: device,
        convolutionData: weights,
        outputBiasTerms: nil,
        outputScaleTerms: nil,
        inputBiasTerms: nil,
        inputScaleTerms: nil,
        type: .binaryWeights,
        flags: .none
    )
    precondition(fc.inputFeatureChannels == 4 && fc.outputFeatureChannels == 8)
    let fcScaled = MPSCNNBinaryFullyConnected(
        device: device,
        convolutionData: weights,
        scaleValue: 1.5,
        type: .XNOR,
        flags: .none
    )
    _ = fcScaled
    precondition(MPSCNNBinaryFullyConnected(coder: NSCoder(), device: device) == nil)
    let fcNode = MPSCNNBinaryFullyConnectedNode(
        source: MPSNNImageNode(),
        weights: weights,
        outputBiasTerms: nil,
        outputScaleTerms: nil,
        inputBiasTerms: nil,
        inputScaleTerms: nil,
        type: .binaryWeights,
        flags: .none
    )
    _ = fcNode
    let fcScaledNode = MPSCNNBinaryFullyConnectedNode(
        source: MPSNNImageNode(),
        weights: weights,
        scaleValue: 0.25,
        type: .AND,
        flags: .none
    )
    _ = fcScaledNode
}

func testMPSWave12FullyConnected() {
    let device = MPSHostDevice.shared
    let weights = MPSWave12TestDataSource(inputChannels: 3, outputChannels: 5)
    let descriptor = MPSCNNConvolutionDescriptor(
        kernelWidth: 1, kernelHeight: 1, inputFeatureChannels: 3, outputFeatureChannels: 5
    )
    let kernelWeights: [Float] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    kernelWeights.withUnsafeBufferPointer { buffer in
        let fc = MPSCNNFullyConnected(
            device: device,
            convolutionDescriptor: descriptor,
            kernelWeights: buffer.baseAddress!,
            biasTerms: nil,
            flags: .none
        )
        precondition(fc.inputFeatureChannels == 3 && fc.outputFeatureChannels == 5)
    }
    let fromWeights = MPSCNNFullyConnected(device: device, weights: weights)
    precondition(fromWeights.inputFeatureChannels == 3 && fromWeights.outputFeatureChannels == 5)
    precondition(MPSCNNFullyConnected(coder: NSCoder(), device: device) == nil)
    let gradient = MPSCNNFullyConnectedGradient(device: device, weights: weights)
    _ = gradient
    precondition(MPSCNNFullyConnectedGradient(coder: NSCoder(), device: device) == nil)
    let gradientNode = MPSCNNFullyConnectedGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        convolutionGradientState: MPSCNNConvolutionGradientStateNode(),
        weights: weights
    )
    _ = gradientNode
    let node = MPSCNNFullyConnectedNode(source: MPSNNImageNode(), weights: weights)
    _ = node
    let transpose = MPSCNNConvolutionTransposeNode(
        source: MPSNNImageNode(),
        convolutionGradientState: MPSCNNConvolutionGradientStateNode(),
        weights: weights
    )
    _ = transpose
    let transposeNil = MPSCNNConvolutionTransposeNode(
        source: MPSNNImageNode(),
        convolutionGradientState: nil,
        weights: weights
    )
    precondition(transposeNil.convolutionGradientState == nil)
}

func testMPSWave12NormalizationNodes() {
    let crossGrad = MPSCNNCrossChannelNormalizationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode(),
        kernelSize: 7
    )
    precondition(crossGrad.kernelSize == 7)
    let crossDefault = MPSCNNCrossChannelNormalizationNode(source: MPSNNImageNode())
    precondition(crossDefault.kernelSizeInFeatureChannels == 5)
    let cross = MPSCNNCrossChannelNormalizationNode(source: MPSNNImageNode(), kernelSize: 3)
    precondition(cross.kernelSizeInFeatureChannels == 3)
    cross.kernelSizeInFeatureChannels = 9
    precondition(cross.kernelSizeInFeatureChannels == 9)
    let norm = MPSCNNNormalizationNode(source: MPSNNImageNode())
    precondition(norm.alpha == 1 && norm.beta == 0.5 && norm.delta == 1)
    norm.alpha = 2
    norm.beta = 0.25
    norm.delta = 4
    precondition(norm.alpha == 2 && norm.beta == 0.25 && norm.delta == 4)
    let groupGradient = MPSCNNGroupNormalizationGradient(device: MPSHostDevice.shared)
    _ = groupGradient
    let groupGradNode = MPSCNNGroupNormalizationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = groupGradNode
    let groupNode = MPSCNNGroupNormalizationNode(
        source: MPSNNImageNode(),
        dataSource: MPSWave12TestGroupDataSource()
    )
    precondition(groupNode.trainingStyle == .UpdateDeviceNone)
    groupNode.trainingStyle = .updateDeviceCPU
    precondition(groupNode.trainingStyle == .updateDeviceCPU)
    precondition(groupNode.dataSource.numberOfFeatureChannels == 4)
    let instanceGradient = MPSCNNInstanceNormalizationGradient(device: MPSHostDevice.shared)
    _ = instanceGradient
    let instanceGradNode = MPSCNNInstanceNormalizationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = instanceGradNode
    let instanceNode = MPSCNNInstanceNormalizationNode(
        source: MPSNNImageNode(),
        dataSource: MPSWave12TestInstanceDataSource()
    )
    precondition(instanceNode.trainingStyle == .UpdateDeviceNone)
    instanceNode.trainingStyle = .updateDeviceGPU
    precondition(instanceNode.trainingStyle == .updateDeviceGPU)
    precondition(instanceNode.dataSource.numberOfFeatureChannels == 4)
}

func testMPSWave12LossNodes() {
    let lossDescriptor = MPSCNNLossDescriptor(type: .meanSquaredError, reductionType: .mean)
    let lossNode = MPSCNNLossNode(source: MPSNNImageNode(), lossDescriptor: lossDescriptor)
    precondition(lossNode.lossDescriptor.lossType == .meanSquaredError)
    let labels: MPSNNLabelsNode = lossNode.inputLabels
    _ = labels
    let anchors = Data([0, 1, 2, 3])
    let yoloDescriptor = MPSCNNYOLOLossDescriptor.cnnLossDescriptor(
        withXYLossType: .meanSquaredError,
        whLossType: .meanAbsoluteError,
        confidenceLossType: .sigmoidCrossEntropy,
        classesLossType: .softMaxCrossEntropy,
        reductionType: .sum,
        anchorBoxes: anchors,
        numberOfAnchorBoxes: 2
    )
    let yoloNode = MPSCNNYOLOLossNode(source: MPSNNImageNode(), lossDescriptor: yoloDescriptor)
    let yoloLabels: MPSNNLabelsNode = yoloNode.inputLabels
    _ = yoloLabels
}

func testMPSWave12ImageConversion() {
    let device = MPSHostDevice.shared
    let conversion = MPSImageConversion(
        device: device,
        srcAlpha: .premultiplied,
        destAlpha: .nonPremultiplied,
        backgroundColor: nil,
        conversionInfo: nil
    )
    precondition(conversion.sourceAlpha == .premultiplied)
    precondition(conversion.destinationAlpha == .nonPremultiplied)
    var background: CGFloat = 0.5
    let withBackground = MPSImageConversion(
        device: device,
        srcAlpha: .alphaIsOne,
        destAlpha: .alphaIsOne,
        backgroundColor: &background,
        conversionInfo: CGColorConversionInfo()
    )
    precondition(withBackground.sourceAlpha == .alphaIsOne)
    precondition(withBackground.destinationAlpha == .alphaIsOne)
    let image = mpsWave12Image(device: device)
    MPSHostBoundary.reset()
    conversion.encode(commandBuffer: device.makeCommandBuffer(), sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave12MatrixDecomposition() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsWave12Matrix(device: device)
    let result = mpsWave12Matrix(device: device)
    let pivots = mpsWave12Matrix(device: device)
    let status = MPSHostBuffer(device: device, length: 8)
    let cholesky = MPSMatrixDecompositionCholesky(device: device, lower: true, order: 2)
    MPSHostBoundary.reset()
    cholesky.encode(commandBuffer: cmd, sourceMatrix: source, resultMatrix: result, status: status)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    cholesky.encode(commandBuffer: cmd, sourceMatrix: source, resultMatrix: result, status: nil)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let lu = MPSMatrixDecompositionLU(device: device, rows: 2, columns: 3)
    lu.encode(commandBuffer: cmd, sourceMatrix: source, resultMatrix: result, pivotIndices: pivots, info: status)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    lu.encode(commandBuffer: cmd, sourceMatrix: source, resultMatrix: result, pivotIndices: pivots, info: nil)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave12MatrixSolve() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsWave12Matrix(device: device)
    let rhs = mpsWave12Matrix(device: device)
    let solution = mpsWave12Matrix(device: device)
    let pivots = mpsWave12Matrix(device: device)
    let cholesky = MPSMatrixSolveCholesky(device: device, upper: false, order: 2, numberOfRightHandSides: 1)
    MPSHostBoundary.reset()
    cholesky.encode(commandBuffer: cmd, sourceMatrix: source, rightHandSideMatrix: rhs, solutionMatrix: solution)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let lu = MPSMatrixSolveLU(device: device, transpose: true, order: 2, numberOfRightHandSides: 2)
    lu.encode(
        commandBuffer: cmd,
        sourceMatrix: source,
        rightHandSideMatrix: rhs,
        pivotIndices: pivots,
        solutionMatrix: solution
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let triangular = MPSMatrixSolveTriangular(
        device: device,
        right: true,
        upper: false,
        transpose: true,
        unit: true,
        order: 2,
        numberOfRightHandSides: 1,
        alpha: 2
    )
    triangular.encode(
        commandBuffer: cmd,
        sourceMatrix: source,
        rightHandSideMatrix: rhs,
        solutionMatrix: solution
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave12MatrixUnaryAndLogSoftMax() {
    let device = MPSHostDevice.shared
    let unary = MPSMatrixUnaryKernel(device: device)
    precondition(unary.batchStart == 0 && unary.batchSize == 1)
    precondition(unary.sourceMatrixOrigin == MTLOrigin(x: 0, y: 0, z: 0))
    precondition(unary.resultMatrixOrigin == MTLOrigin(x: 0, y: 0, z: 0))
    unary.batchStart = 2
    unary.batchSize = 3
    unary.sourceMatrixOrigin = MTLOrigin(x: 1, y: 2, z: 0)
    unary.resultMatrixOrigin = MTLOrigin(x: 3, y: 4, z: 0)
    precondition(unary.batchStart == 2 && unary.batchSize == 3)
    precondition(unary.sourceMatrixOrigin == MTLOrigin(x: 1, y: 2, z: 0))
    precondition(unary.resultMatrixOrigin == MTLOrigin(x: 3, y: 4, z: 0))
    let logSoftMax = MPSMatrixLogSoftMax(device: device)
    _ = logSoftMax
    let logSoftMaxGradient = MPSMatrixLogSoftMaxGradient(device: device)
    _ = logSoftMaxGradient
}

func testMPSWave12NDArrayGradientKernels() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let source = mpsWave12Array(device: device)
    let secondary = mpsWave12Array(device: device)
    let gradient = mpsWave12Array(device: device)
    let destination = mpsWave12Array(device: device)
    let state = MPSNDArrayGradientState(device: device)
    let unary = MPSNDArrayUnaryGradientKernel(device: device)
    precondition(unary.sourceCount == 1)
    let unaryCoded = MPSNDArrayUnaryGradientKernel(coder: NSCoder(), device: device)
    precondition(unaryCoded.sourceCount == 1)
    MPSHostBoundary.reset()
    let unaryOut = unary.encode(to: cmd, sourceArray: source, sourceGradient: gradient, gradientState: state)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(unaryOut.dataType == gradient.dataType)
    MPSHostBoundary.reset()
    unary.encode(
        to: cmd,
        sourceArray: source,
        sourceGradient: gradient,
        gradientState: state,
        destinationArray: destination
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let primary = MPSNDArrayBinaryPrimaryGradientKernel(device: device)
    precondition(primary.sourceCount == 2)
    let primaryCoded = MPSNDArrayBinaryPrimaryGradientKernel(coder: NSCoder(), device: device)
    precondition(primaryCoded.sourceCount == 2)
    let primaryOut = primary.encode(
        to: cmd,
        primarySourceArray: source,
        secondarySourceArray: secondary,
        sourceGradient: gradient,
        gradientState: state
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(primaryOut.dataType == gradient.dataType)
    MPSHostBoundary.reset()
    primary.encode(
        to: cmd,
        primarySourceArray: source,
        secondarySourceArray: secondary,
        sourceGradient: gradient,
        gradientState: state,
        destinationArray: destination
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let sequel = MPSNDArrayBinarySecondaryGradientKernel(device: device)
    precondition(sequel.sourceCount == 2)
    let sequelCoded = MPSNDArrayBinarySecondaryGradientKernel(coder: NSCoder(), device: device)
    precondition(sequelCoded.sourceCount == 2)
    let sequelOut = sequel.encode(
        to: cmd,
        primarySourceArray: source,
        secondarySourceArray: secondary,
        sourceGradient: gradient,
        gradientState: state
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(sequelOut.dataType == gradient.dataType)
    MPSHostBoundary.reset()
    sequel.encode(
        to: cmd,
        primarySourceArray: source,
        secondarySourceArray: secondary,
        sourceGradient: gradient,
        gradientState: state,
        destinationArray: destination
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let multiary = MPSNDArrayMultiaryGradientKernel(device: device, sourceCount: 3, sourceGradientIndex: 1)
    precondition(multiary.sourceCount == 3)
    let multiaryCoded = MPSNDArrayMultiaryGradientKernel(coder: NSCoder(), device: device)
    precondition(multiaryCoded.sourceCount == 1)
    let multiaryOut = multiary.encode(
        to: cmd,
        sourceArrays: [source, secondary],
        sourceGradient: gradient,
        gradientState: state
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(multiaryOut.dataType == gradient.dataType)
    MPSHostBoundary.reset()
    multiary.encode(
        to: cmd,
        sourceArrays: [source, secondary],
        sourceGradient: gradient,
        gradientState: state,
        destinationArray: destination
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave12NDArrayStatesAndKernels() {
    let device = MPSHostDevice.shared
    let gradientState = MPSNDArrayGradientState(device: device)
    _ = gradientState
    let gatherGradient = MPSNDArrayGatherGradient(device: device)
    _ = gatherGradient
    let gatherGradientState = MPSNDArrayGatherGradientState(device: device)
    _ = gatherGradientState
    let sliceGradient = MPSNDArrayStridedSliceGradient(device: device)
    _ = sliceGradient
    let gather = MPSNDArrayGather(device: device)
    precondition(gather.sourceCount == 2)
    gather.axis = 1
    precondition(gather.axis == 1)
    let slice = MPSNDArrayStridedSlice(device: device)
    let strides = MPSNDArrayOffsets(dimensions: (3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
    slice.strides = strides
    precondition(slice.strides.dimensions.0 == 3)
    let matmul = MPSNDArrayMatrixMultiplication(device: device)
    precondition(matmul.alpha == 1 && matmul.beta == 0)
    matmul.alpha = 3
    matmul.beta = 2
    precondition(matmul.alpha == 3 && matmul.beta == 2)
    let left = MPSNDArrayAffineQuantizationDescriptor(dataType: .uInt8, hasZeroPoint: true, hasMinValue: false)
    let right = MPSNDArrayLUTQuantizationDescriptor(dataType: .float16, vectorAxis: 1)
    let quantized = MPSNDArrayQuantizedMatrixMultiplication(
        device: device,
        leftQuantizationDescriptor: left,
        rightQuantizationDescriptor: right
    )
    _ = quantized
    let quantBase: MPSNDArrayQuantizationDescriptor = left
    precondition(quantBase.quantizationDataType == .uInt8)
    precondition(quantBase.quantizationScheme == .typeAffine)
    precondition(right.quantizationScheme == .typeLUT)
    let affineDequant = MPSNDArrayAffineInt4Dequantize(device: device, quantizationDescriptor: left)
    precondition(affineDequant.quantizationDescriptor.hasZeroPoint)
    let affineDefault = MPSNDArrayAffineQuantizationDescriptor()
    precondition(!affineDefault.hasZeroPoint && !affineDefault.hasMinValue && !affineDefault.implicitZeroPoint)
    let affine = MPSNDArrayAffineQuantizationDescriptor(
        dataType: .float16, hasZeroPoint: false, hasMinValue: true
    )
    precondition(affine.hasMinValue && !affine.hasZeroPoint)
    affine.hasZeroPoint = true
    affine.implicitZeroPoint = true
    precondition(affine.hasZeroPoint && affine.implicitZeroPoint)
    let lutDequant = MPSNDArrayLUTDequantize(device: device)
    _ = lutDequant
    let lut = MPSNDArrayLUTQuantizationDescriptor(dataType: .uInt8)
    precondition(lut.quantizationDataType == .uInt8)
    let lutAxis = MPSNDArrayLUTQuantizationDescriptor(dataType: .float32, vectorAxis: 2)
    _ = lutAxis
    let vectorDequant = MPSNDArrayVectorLUTDequantize(device: device, axis: 2)
    precondition(vectorDequant.vectorAxis == 2)
    vectorDequant.vectorAxis = 5
    precondition(vectorDequant.vectorAxis == 5)
}

func testMPSWave12NNGradientStates() {
    let device = MPSHostDevice.shared
    let gradient = MPSNNGradientState(device: device)
    _ = gradient
    let binary = MPSNNBinaryGradientState(device: device)
    _ = binary
    let multiary = MPSNNMultiaryGradientState(device: device)
    _ = multiary
    let multiaryNode = MPSNNMultiaryGradientStateNode()
    multiaryNode.exportFromGraph = true
    precondition(multiaryNode.exportFromGraph)
    let arithmeticNode = MPSNNArithmeticGradientStateNode()
    _ = arithmeticNode
    let labels = MPSNNLabelsNode()
    labels.exportFromGraph = true
    precondition(labels.exportFromGraph)
    let state = MPSNNStateNode()
    precondition(!state.exportFromGraph && !state.synchronizeResource && state.handle == nil)
    state.exportFromGraph = true
    state.synchronizeResource = true
    state.handle = MPSWave12TestHandle(label: "wave12")
    precondition(state.exportFromGraph && state.synchronizeResource && state.handle?.label == "wave12")
    let gradientNode = MPSNNGradientStateNode()
    _ = gradientNode
    let filter = MPSNNGradientFilterNode()
    _ = filter
    let weights = MPSWave12TestDataSource(inputChannels: 2, outputChannels: 2)
    let convNode = MPSCNNConvolutionNode(source: MPSNNImageNode(), weights: weights)
    let trainable: any MPSNNTrainableNode = convNode
    precondition(trainable.trainingStyle == .UpdateDeviceNone)
    trainable.trainingStyle = .updateDeviceCPU
    precondition(trainable.trainingStyle == .updateDeviceCPU)
}

func testMPSWave12NNArithmeticNodes() {
    let left = MPSNNImageNode()
    let right = MPSNNImageNode()
    let add = MPSNNAdditionNode(leftSource: left, rightSource: right)
    _ = add
    let addGrad = MPSNNAdditionGradientNode()
    _ = addGrad
    let mul = MPSNNMultiplicationNode(leftSource: left, rightSource: right)
    _ = mul
    let mulGrad = MPSNNMultiplicationGradientNode()
    _ = mulGrad
    let sub = MPSNNSubtractionNode(leftSource: left, rightSource: right)
    _ = sub
    let subGrad = MPSNNSubtractionGradientNode()
    _ = subGrad
    let div = MPSNNDivisionNode(leftSource: left, rightSource: right)
    _ = div
    let bilinear = MPSNNBilinearScaleNode()
    _ = bilinear
    let lanczos = MPSNNLanczosScaleNode()
    _ = lanczos
    let concat = MPSNNConcatenationNode(sources: [left, right])
    precondition(concat.sources.count == 2)
    let concatGrad = MPSNNConcatenationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = concatGrad
}

func testMPSWave12PadReshapeScaleNodes() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = mpsWave12Image(device: device)
    let padGrad = MPSNNPadGradient(device: device)
    precondition(MPSNNPadGradient(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    padGrad.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let padGradNode = MPSNNPadGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = padGradNode
    let reshapeGrad = MPSNNReshapeGradient(device: device)
    precondition(MPSNNReshapeGradient(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    reshapeGrad.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let reshapeGradNode = MPSNNReshapeGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    _ = reshapeGradNode
    let initial = MPSNNInitialGradient(device: device)
    precondition(MPSNNInitialGradient(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    initial.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let initialNode = MPSNNInitialGradientNode(source: MPSNNImageNode())
    _ = initialNode
    let source = MPSNNImageNode()
    let pad = MPSNNPadNode(
        source: source,
        paddingSizeBefore: MPSImageCoordinate(x: 1, y: 1, channel: 0),
        paddingSizeAfter: MPSImageCoordinate(x: 2, y: 2, channel: 0),
        edgeMode: .zero
    )
    precondition(pad.fillValue == 0)
    pad.fillValue = 2.5
    precondition(pad.fillValue == 2.5)
    let reshape = MPSNNReshapeNode(
        source: source,
        resultWidth: 3,
        resultHeight: 4,
        resultFeatureChannels: 5
    )
    precondition(reshape.resultWidth == 3 && reshape.resultHeight == 4 && reshape.resultFeatureChannels == 5)
    let size = MTLSize(width: 6, height: 7, depth: 1)
    let scale = MPSNNScaleNode(source: source, outputSize: size)
    precondition(scale.outputSize == size)
    let provider: any MPSImageTransformProvider = MPSWave12TestTransformProvider()
    let scaledWithProvider = MPSNNScaleNode(source: source, transformProvider: provider, outputSize: size)
    precondition(scaledWithProvider.outputSize == size)
    precondition(scaledWithProvider.transformProvider != nil)
    let reduction = MPSNNUnaryReductionNode(source: source)
    precondition(reduction.clipRectSource == MPSRectNoClip)
    reduction.clipRectSource = MTLRegion.make2D(1, 2, 3, 4)
    precondition(reduction.clipRectSource == MTLRegion.make2D(1, 2, 3, 4))
}

func testMPSWave12CompareGramGridSlice() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = mpsWave12Image(device: device)
    let compare = MPSNNCompare(device: device)
    precondition(compare.comparisonType == .equal && compare.threshold == 0)
    compare.comparisonType = .greaterOrEqual
    compare.threshold = 1.5
    precondition(compare.comparisonType == .greaterOrEqual && compare.threshold == 1.5)
    let comparisonNode = MPSNNComparisonNode(sources: [MPSNNImageNode(), MPSNNImageNode()])
    precondition(comparisonNode.comparisonType == .equal)
    comparisonNode.comparisonType = .less
    precondition(comparisonNode.comparisonType == .less)
    let gram = MPSNNGramMatrixCalculation(device: device)
    precondition(gram.alpha == 1)
    let gramAlpha = MPSNNGramMatrixCalculation(device: device, alpha: 0.5)
    precondition(gramAlpha.alpha == 0.5)
    precondition(MPSNNGramMatrixCalculation(coder: NSCoder(), device: device) == nil)
    let callback: any MPSNNGramMatrixCallback = MPSWave12TestGramCallback()
    precondition(callback.alpha(forSourceImage: image, destinationImage: image) == 0.75)
    let gramNode = MPSNNGramMatrixCalculationNode(source: MPSNNImageNode())
    precondition(gramNode.alpha == 1 && gramNode.propertyCallBack == nil)
    let gramNodeAlpha = MPSNNGramMatrixCalculationNode(source: MPSNNImageNode(), alpha: 2)
    precondition(gramNodeAlpha.alpha == 2)
    gramNode.propertyCallBack = callback
    precondition(gramNode.propertyCallBack?.alpha(forSourceImage: image, destinationImage: image) == 0.75)
    let gramGrad = MPSNNGramMatrixCalculationGradient(device: device)
    precondition(gramGrad.alpha == 1)
    let gramGradAlpha = MPSNNGramMatrixCalculationGradient(device: device, alpha: 3)
    precondition(gramGradAlpha.alpha == 3)
    precondition(MPSNNGramMatrixCalculationGradient(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    gramGrad.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    let gramGradNode = MPSNNGramMatrixCalculationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode()
    )
    precondition(gramGradNode.alpha == 1)
    let gramGradNodeAlpha = MPSNNGramMatrixCalculationGradientNode(
        sourceGradient: MPSNNImageNode(),
        sourceImage: MPSNNImageNode(),
        gradientState: MPSNNGradientStateNode(),
        alpha: 0.25
    )
    precondition(gramGradNodeAlpha.alpha == 0.25)
    let grid = MPSNNGridSample(device: device)
    precondition(!grid.useGridValueAsInputCoordinate)
    grid.useGridValueAsInputCoordinate = true
    precondition(grid.useGridValueAsInputCoordinate)
    precondition(MPSNNGridSample(coder: NSCoder(), device: device) == nil)
    let slice = MPSNNSlice(device: device)
    precondition(MPSNNSlice(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    slice.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
}

func testMPSWave12DescriptorsAndProtocols() {
    let device = MPSHostDevice.shared
    let depthwise = MPSCNNDepthWiseConvolutionDescriptor(
        kernelWidth: 3, kernelHeight: 3, inputFeatureChannels: 4, outputFeatureChannels: 8
    )
    precondition(depthwise.channelMultiplier == 1)
    let subpixel = MPSCNNSubPixelConvolutionDescriptor(
        kernelWidth: 2, kernelHeight: 2, inputFeatureChannels: 4, outputFeatureChannels: 16
    )
    precondition(subpixel.subPixelScaleFactor == 1)
    subpixel.subPixelScaleFactor = 4
    precondition(subpixel.subPixelScaleFactor == 4)
    let edt = MPSImageEuclideanDistanceTransform(device: device)
    precondition(edt.searchLimitRadius == 0)
    edt.searchLimitRadius = 8
    precondition(edt.searchLimitRadius == 8)
    precondition(MPSImageEuclideanDistanceTransform(coder: NSCoder(), device: device) == nil)
    let quad = MPSQuadrilateralAccelerationStructure(device: device)
    precondition(quad.quadrilateralCount == 0)
    quad.quadrilateralCount = 5
    precondition(quad.quadrilateralCount == 5)
    let sizeState: any MPSImageSizeEncodingState = MPSWave12TestSizeState(width: 10, height: 12)
    precondition(sizeState.sourceWidth == 10 && sizeState.sourceHeight == 12)
    let provider: any MPSImageTransformProvider = MPSWave12TestTransformProvider()
    let image = mpsWave12Image(device: device)
    let transform = provider.transform(forSourceImage: image, handle: nil)
    precondition(transform.scaleX == 1 && transform.translateX == 0)
}
