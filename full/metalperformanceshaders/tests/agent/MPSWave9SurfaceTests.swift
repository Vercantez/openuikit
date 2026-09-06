import Foundation
import MetalPerformanceShaders

final class MPSWave9InstanceNormSource: NSObject, MPSCNNInstanceNormalizationDataSource {
    let numberOfFeatureChannels: Int
    var gammaStorage: UnsafeMutablePointer<Float>
    var betaStorage: UnsafeMutablePointer<Float>

    init(channels: Int) {
        self.numberOfFeatureChannels = channels
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        for index in 0..<channels {
            gammaStorage[index] = 1
            betaStorage[index] = 0
        }
        super.init()
    }

    required init?(coder: NSCoder) { return nil }
    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave9InstanceNormSource(channels: numberOfFeatureChannels)
    }
    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "wave9-in" }
}

final class MPSWave9GroupNormSource: NSObject, MPSCNNGroupNormalizationDataSource {
    let numberOfFeatureChannels: Int
    var numberOfGroups: Int
    var gammaStorage: UnsafeMutablePointer<Float>
    var betaStorage: UnsafeMutablePointer<Float>

    init(channels: Int, groups: Int) {
        self.numberOfFeatureChannels = channels
        self.numberOfGroups = groups
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: channels)
        for index in 0..<channels {
            gammaStorage[index] = 1
            betaStorage[index] = 0
        }
        super.init()
    }

    required init?(coder: NSCoder) { return nil }
    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSWave9GroupNormSource(channels: numberOfFeatureChannels, groups: numberOfGroups)
    }
    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "wave9-gn" }
}

final class MPSWave9ConvWeights: NSObject, MPSCNNConvolutionDataSource {
    private var weightStorage = UnsafeMutablePointer<Float>.allocate(capacity: 1)
    override init() {
        weightStorage.initialize(to: 1)
        super.init()
    }
    deinit { weightStorage.deallocate() }
    func copy(with zone: NSZone? = nil) -> Any { _ = zone; return MPSWave9ConvWeights() }
    func biasTerms() -> UnsafeMutablePointer<Float>? { nil }
    func dataType() -> MPSDataType { .float32 }
    func descriptor() -> MPSCNNConvolutionDescriptor {
        MPSCNNConvolutionDescriptor(kernelWidth: 1, kernelHeight: 1, inputFeatureChannels: 1, outputFeatureChannels: 1)
    }
    func label() -> String? { "wave9-conv" }
    func load() -> Bool { true }
    func purge() {}
    func weights() -> UnsafeMutableRawPointer { UnsafeMutableRawPointer(weightStorage) }
}

func testMPSAccelerationStructureHost() {
    let device = MPSHostDevice.shared
    let group = MPSAccelerationStructureGroup(device: device)
    precondition(group.device.name == device.name)
    let accel = MPSAccelerationStructure(device: device)
    precondition(accel.status == .unbuilt)
    accel.usage = [.refit, .frequentRebuild]
    precondition(accel.usage.contains(.refit))
    _ = accel.boundingBox
    _ = accel.group
    MPSHostBoundary.reset()
    accel.rebuild()
    precondition(accel.status == .unbuilt)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var called = false
    accel.rebuild { structure in
        called = true
        precondition(structure?.status == .unbuilt)
    }
    precondition(called)
    MPSHostBoundary.reset()
    accel.encodeRefit(commandBuffer: device.makeCommandBuffer())
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let copied = accel.copy(with: nil, device: device)
    precondition(copied.status == .unbuilt)
    let grouped = accel.copy(with: nil, group: group)
    precondition(grouped.usage.contains(.refit))
    accel.encode(with: NSCoder())
    precondition(MPSAccelerationStructure(coder: NSCoder(), device: device) == nil)
    precondition(MPSAccelerationStructure(coder: NSCoder(), group: group) == nil)
    precondition(MPSAccelerationStructure(coder: NSCoder()) == nil)
    _ = MPSAccelerationStructure(group: group)

    let polyBuf = MPSPolygonBuffer()
    polyBuf.polygonCount = 2
    polyBuf.vertexBufferOffset = 12
    polyBuf.indexBufferOffset = 4
    polyBuf.maskBufferOffset = 8
    let vb = device.makeBuffer(length: 48)
    polyBuf.vertexBuffer = vb
    polyBuf.indexBuffer = device.makeBuffer(length: 16)
    polyBuf.maskBuffer = device.makeBuffer(length: 8)
    let polyCopy = polyBuf.copy() as! MPSPolygonBuffer
    precondition(polyCopy.polygonCount == 2)
    precondition(polyCopy.vertexBufferOffset == 12)
    precondition(MPSPolygonBuffer(coder: NSCoder()) == nil)

    let poly = MPSPolygonAccelerationStructure(device: device)
    poly.polygonCount = 3
    poly.polygonType = .triangle
    poly.vertexStride = 12
    poly.indexType = .uInt32
    poly.vertexBuffer = vb
    poly.vertexBufferOffset = 0
    poly.indexBuffer = polyBuf.indexBuffer
    poly.indexBufferOffset = 0
    poly.maskBuffer = polyBuf.maskBuffer
    poly.maskBufferOffset = 0
    poly.polygonBuffers = [polyBuf]
    precondition(poly.polygonCount == 3)
    precondition(poly.polygonType == .triangle)

    let tri = MPSTriangleAccelerationStructure(device: device)
    tri.triangleCount = 4
    precondition(tri.polygonCount == 4)

    let inst = MPSInstanceAccelerationStructure(device: device)
    inst.instanceCount = 2
    inst.instanceBufferOffset = 16
    inst.maskBufferOffset = 4
    inst.transformBufferOffset = 8
    inst.transformType = .float4x4
    inst.accelerationStructures = [poly]
    inst.instanceBuffer = device.makeBuffer(length: 64)
    inst.maskBuffer = device.makeBuffer(length: 8)
    inst.transformBuffer = device.makeBuffer(length: 128)
    precondition(inst.instanceCount == 2)
    precondition(inst.transformType == .float4x4)
}

func testMPSCommandBufferAndKeyedUnarchiver() {
    let device = MPSHostDevice.shared
    let queue = device.makeCommandQueue()
    let wrapped = MPSCommandBuffer(from: queue)
    precondition(wrapped.commandBuffer.device.name == device.name)
    precondition(wrapped.rootCommandBuffer.device.name == device.name)
    wrapped.predicate = MPSPredicate(device: device)
    wrapped.heapProvider = nil
    wrapped.commitAndContinue()
    wrapped.prefetchHeap(forWorkloadSize: 1024)
    let also = MPSCommandBuffer(fromCommandQueue: queue)
    _ = also.commandBuffer
    let inner = MPSCommandBuffer(commandBuffer: device.makeCommandBuffer())
    _ = inner.heapProvider

    let unarchiver = MPSKeyedUnarchiver(device: device)
    precondition(unarchiver?.mpsMTLDevice().name == device.name)
    var error: NSError?
    _ = MPSKeyedUnarchiver(forReadingFrom: Data(), device: device, error: &error)
    precondition(error != nil)
    _ = MPSKeyedUnarchiver(forReadingFromData: Data(), device: device, error: nil)
    _ = MPSKeyedUnarchiver(forReadingWith: Data(), device: device)
    _ = MPSKeyedUnarchiver(forReadingWithData: Data(), device: device)
    MPSHostBoundary.reset()
    precondition(MPSKeyedUnarchiver.unarchiveObject(with: Data(), device: device) == nil)
    precondition(MPSKeyedUnarchiver.unarchiveObject(withFile: "/tmp/none", device: device) == nil)
    var threw = false
    do {
        _ = try MPSKeyedUnarchiver.unarchiveTopLevelObject(with: Data(), device: device)
    } catch {
        threw = true
    }
    precondition(threw)
    threw = false
    do {
        _ = try MPSKeyedUnarchiver.unarchivedObject(of: MPSKernel.self, from: Data(), device: device)
    } catch {
        threw = true
    }
    precondition(threw)
    threw = false
    do {
        _ = try MPSKeyedUnarchiver.unarchivedObject(ofClasses: Set<AnyHashable>(), from: Data(), device: device)
    } catch {
        threw = true
    }
    precondition(threw)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
}

func testMPSCNNWave9Kernels() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let weights = MPSWave9ConvWeights()
    let convGrad = MPSCNNConvolutionGradient(device: device, weights: weights)
    convGrad.gradientOption = .all
    convGrad.serializeWeightsAndBiases = false
    convGrad.kernelOffsetX = 1
    convGrad.kernelOffsetY = -1
    precondition(convGrad.groups == 1)
    precondition(convGrad.channelMultiplier == 1)
    precondition(convGrad.sourceGradientFeatureChannels == 1)
    precondition(convGrad.sourceImageFeatureChannels == 1)
    _ = convGrad.dataSource
    convGrad.reloadWeightsAndBiasesFromDataSource()
    MPSHostBoundary.reset()
    convGrad.reloadWeightsAndBiases(
        with: cmd,
        state: MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: weights.descriptor())
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let conv = MPSCNNConvolution(device: device, weights: weights)
    let state = MPSCNNConvolutionGradientState(convolution: conv)
    precondition(state.gradientForWeightsLayout == .OHWI)
    _ = state.gradientForWeights
    _ = state.gradientForBiases
    _ = state.convolution
    MPSHostBoundary.reset()
    convGrad.encode(commandBuffer: cmd, sourceGradient: image, sourceImage: image, gradientState: state, destinationGradient: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = convGrad.encode(commandBuffer: cmd, sourceGradient: image, sourceImage: image, gradientState: state)
    convGrad.encodeBatch(
        commandBuffer: cmd,
        sourceGradients: [image],
        sourceImages: [image],
        gradientStates: [state],
        destinationGradients: [image]
    )
    _ = convGrad.encodeBatch(commandBuffer: cmd, sourceGradients: [image], sourceImages: [image], gradientStates: [state])
    precondition(MPSCNNConvolutionGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNConvolutionGradient(device: device)
    let node = MPSCNNConvolutionGradientNode(
        sourceGradient: MPSNNImageNode(handle: nil),
        sourceImage: MPSNNImageNode(handle: nil),
        convolutionGradientState: MPSCNNConvolutionGradientStateNode(),
        weights: weights
    )
    _ = node
    _ = MPSCNNConvolutionGradientStateNode()

    let tgrad = MPSCNNConvolutionTransposeGradient(device: device, weights: weights)
    precondition(tgrad.groups == 1)
    tgrad.gradientOption = .gradientWithData
    tgrad.reloadWeightsAndBiasesFromDataSource()
    MPSHostBoundary.reset()
    tgrad.reloadWeightsAndBiases(
        with: cmd,
        state: MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: weights.descriptor())
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = tgrad.dataSource
    _ = tgrad.sourceGradientFeatureChannels
    _ = tgrad.sourceImageFeatureChannels
    precondition(MPSCNNConvolutionTransposeGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNConvolutionTransposeGradient(device: device)
    _ = MPSCNNConvolutionTransposeGradientNode(
        sourceGradient: MPSNNImageNode(handle: nil),
        sourceImage: MPSNNImageNode(handle: nil),
        convolutionTransposeGradientState: MPSCNNConvolutionTransposeGradientStateNode(),
        weights: nil
    )

    let arith = MPSCNNArithmetic(device: device)
    arith.bias = 1
    arith.primaryScale = 2
    arith.secondaryScale = 3
    arith.minimumValue = -10
    arith.maximumValue = 10
    arith.primaryStrideInFeatureChannels = 1
    arith.secondaryStrideInFeatureChannels = 1
    let ast = MPSCNNArithmeticGradientState()
    MPSHostBoundary.reset()
    arith.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationState: ast, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    arith.encodeBatch(
        commandBuffer: cmd,
        primaryImages: [image],
        secondaryImages: [image],
        destinationStates: [ast],
        destinationImages: [image]
    )
    let agr = MPSCNNArithmeticGradient(device: device, isSecondarySourceFilter: true)
    precondition(agr.isSecondarySourceFilter)
    agr.bias = 0
    agr.primaryScale = 1
    agr.secondaryScale = 1
    agr.minimumValue = 0
    agr.maximumValue = 1
    agr.secondaryStrideInFeatureChannels = 1
    _ = MPSCNNArithmeticGradient(device: device)

    let anode = MPSNNArithmeticGradientNode(
        sourceGradient: MPSNNImageNode(handle: nil),
        sourceImage: MPSNNImageNode(handle: nil),
        gradientState: MPSNNBinaryGradientStateNode(),
        isSecondarySourceFilter: false
    )
    precondition(!anode.isSecondarySourceFilter)
    anode.bias = 0.5
    anode.primaryScale = 2
    anode.secondaryScale = 3
    anode.minimumValue = -1
    anode.maximumValue = 1
    anode.secondaryStrideInFeatureChannels = 1
    anode.secondaryStrideInPixelsX = 1
    anode.secondaryStrideInPixelsY = 1
    _ = MPSNNArithmeticGradientNode(
        gradientImages: [MPSNNImageNode(handle: nil)],
        forwardFilter: MPSNNFilterNode(),
        isSecondarySourceFilter: true
    )

    let drop = MPSCNNDropout(device: device, keepProbability: 0.8, seed: 3, maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1))
    precondition(drop.keepProbability == 0.8 && drop.seed == 3)
    precondition(drop.maskStrideInPixels.width == 1)
    let dstate = drop.resultState(sourceImage: image, sourceStates: nil, destinationImage: image)
    precondition(dstate?.maskData().count == 0)
    _ = drop.resultStateBatch(sourceImage: [image], sourceStates: nil, destinationImage: [image])
    _ = drop.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image)
    _ = drop.temporaryResultStateBatch(commandBuffer: cmd, sourceImage: [image], sourceStates: nil, destinationImage: [image])
    precondition(MPSCNNDropout(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNDropout(device: device)
    let dgrad = MPSCNNDropoutGradient(device: device, keepProbability: 0.5, seed: 1, maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1))
    precondition(dgrad.keepProbability == 0.5 && dgrad.seed == 1)
    _ = dgrad.maskStrideInPixels
    precondition(MPSCNNDropoutGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNDropoutGradient(device: device)
    let dnode = MPSCNNDropoutGradientNode(
        sourceGradient: MPSNNImageNode(handle: nil),
        sourceImage: MPSNNImageNode(handle: nil),
        gradientState: MPSNNGradientStateNode(),
        keepProbability: 0.4,
        seed: 9,
        maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1)
    )
    precondition(dnode.keepProbability == 0.4 && dnode.seed == 9)
    _ = dnode.maskStrideInPixels
    let dropNode = MPSCNNDropoutNode(source: MPSNNImageNode(handle: nil), keepProbability: 0.7, seed: 2, maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1))
    precondition(dropNode.keepProbability == 0.7)
    _ = MPSCNNDropoutNode(source: MPSNNImageNode(handle: nil))
    _ = MPSCNNDropoutNode(source: MPSNNImageNode(handle: nil), keepProbability: 0.9)
    _ = dropNode.seed
    _ = dropNode.maskStrideInPixels

    let inSource = MPSWave9InstanceNormSource(channels: 2)
    precondition(inSource.numberOfFeatureChannels == 2)
    precondition(inSource.gamma()?[0] == 1)
    precondition(inSource.beta()?[0] == 0)
    precondition(inSource.label() == "wave9-in")
    _ = inSource.copy()
    _ = inSource.copy(with: nil, device: device)
    _ = inSource.epsilon()
    _ = inSource.load()
    inSource.purge()
    inSource.encode(with: NSCoder())
    precondition(MPSWave9InstanceNormSource.supportsSecureCoding == false)
    precondition(inSource.updateGammaAndBeta(withInstanceNormalizationStateBatch: []) == false)
    precondition(inSource.updateGammaAndBeta(with: cmd, instanceNormalizationStateBatch: []) == nil)
    precondition(MPSWave9InstanceNormSource(coder: NSCoder()) == nil)
    let inn = MPSCNNInstanceNormalization(device: device, dataSource: inSource)
    inn.epsilon = 1e-4
    inn.reloadDataSource(inSource)
    inn.reloadGammaAndBetaFromDataSource()
    MPSHostBoundary.reset()
    inn.reloadGammaAndBeta(
        with: cmd,
        gammaAndBetaState: MPSCNNNormalizationGammaAndBetaState.temporaryState(with: cmd, numberOfFeatureChannels: 2)
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let inState = inn.resultState(sourceImage: image, sourceStates: nil, destinationImage: image)
    precondition(inState?.instanceNormalization === inn)
    _ = inState?.gamma
    _ = inState?.beta
    _ = inState?.gradientForGamma
    _ = inState?.gradientForBeta
    _ = inn.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image)
    _ = inn.dataSource
    precondition(MPSCNNInstanceNormalization(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNInstanceNormalization(device: device)

    let gnSource = MPSWave9GroupNormSource(channels: 4, groups: 2)
    gnSource.numberOfGroups = 2
    precondition(gnSource.numberOfFeatureChannels == 4)
    precondition(gnSource.gamma()?[0] == 1)
    precondition(gnSource.beta()?[0] == 0)
    precondition(gnSource.label() == "wave9-gn")
    _ = gnSource.copy()
    _ = gnSource.copy(with: nil, device: device)
    gnSource.encode(with: NSCoder())
    _ = gnSource.epsilon()
    precondition(gnSource.updateGammaAndBeta(withGroupNormalizationStateBatch: []) == false)
    precondition(gnSource.updateGammaAndBeta(with: cmd, groupNormalizationStateBatch: []) == nil)
    precondition(MPSWave9GroupNormSource.supportsSecureCoding == false)
    precondition(MPSWave9GroupNormSource(coder: NSCoder()) == nil)
    let gn = MPSCNNGroupNormalization(device: device, dataSource: gnSource)
    gn.epsilon = 1e-3
    gn.reloadGammaAndBetaFromDataSource()
    MPSHostBoundary.reset()
    gn.reloadGammaAndBeta(
        with: cmd,
        gammaAndBetaState: MPSCNNNormalizationGammaAndBetaState.temporaryState(with: cmd, numberOfFeatureChannels: 4)
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let gnState = gn.resultState(sourceImage: image, sourceStates: nil, destinationImage: image)
    precondition(gnState?.groupNormalization === gn)
    _ = gnState?.gamma
    _ = gnState?.beta
    _ = gnState?.gradientForGamma
    _ = gnState?.gradientForBeta
    _ = gn.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image)
    _ = gn.dataSource
    precondition(MPSCNNGroupNormalization(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNGroupNormalization(device: device)

    let lcn = MPSCNNLocalContrastNormalization(device: device, kernelWidth: 3, kernelHeight: 5)
    lcn.alpha = 0.1
    lcn.beta = 0.2
    lcn.delta = 1
    lcn.p0 = 1
    lcn.pm = 1
    lcn.ps = 1
    precondition(lcn.kernelWidth == 3 && lcn.kernelHeight == 5)
    precondition(MPSCNNLocalContrastNormalization(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNLocalContrastNormalization(device: device)
    let lcng = MPSCNNLocalContrastNormalizationGradient(device: device, kernelWidth: 3, kernelHeight: 5)
    lcng.alpha = 0.1
    lcng.beta = 0.2
    lcng.delta = 1
    lcng.p0 = 1
    lcng.pm = 1
    lcng.ps = 1
    precondition(lcng.kernelWidth == 3)
    precondition(MPSCNNLocalContrastNormalizationGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNLocalContrastNormalizationGradient(device: device)
    let lcngn = MPSCNNLocalContrastNormalizationGradientNode(
        sourceGradient: MPSNNImageNode(handle: nil),
        sourceImage: MPSNNImageNode(handle: nil),
        gradientState: MPSNNGradientStateNode(),
        kernelWidth: 3,
        kernelHeight: 5
    )
    lcngn.alpha = 0.1
    lcngn.beta = 0.2
    lcngn.delta = 1
    lcngn.p0 = 1
    lcngn.pm = 1
    lcngn.ps = 1
    precondition(lcngn.kernelWidth == 3 && lcngn.kernelHeight == 5)
    let lcnn = MPSCNNLocalContrastNormalizationNode(source: MPSNNImageNode(handle: nil), kernelSize: 3)
    lcnn.kernelWidth = 3
    lcnn.kernelHeight = 3
    lcnn.p0 = 1
    lcnn.pm = 1
    lcnn.ps = 1
    _ = MPSCNNLocalContrastNormalizationNode(source: MPSNNImageNode(handle: nil))

    let ccn = MPSCNNCrossChannelNormalization(device: device, kernelSize: 5)
    ccn.alpha = 1
    ccn.beta = 0.75
    ccn.delta = 1
    precondition(ccn.kernelSize == 5)
    precondition(MPSCNNCrossChannelNormalization(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNCrossChannelNormalization(device: device)
    let ccng = MPSCNNCrossChannelNormalizationGradient(device: device, kernelSize: 5)
    ccng.alpha = 1
    ccng.beta = 0.75
    ccng.delta = 1
    precondition(ccng.kernelSize == 5)
    precondition(MPSCNNCrossChannelNormalizationGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNCrossChannelNormalizationGradient(device: device)

    let ngrad = MPSCNNNeuronGradient(device: device, neuronDescriptor: MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .reLU, a: 0.1))
    precondition(ngrad.neuronType == .reLU && ngrad.a == 0.1)
    _ = ngrad.b
    _ = ngrad.c
    _ = ngrad.data
    precondition(MPSCNNNeuronGradient(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNNeuronGradient(device: device)

    let poolNode = MPSCNNPoolingNode(
        source: MPSNNImageNode(handle: nil),
        kernelWidth: 2,
        kernelHeight: 2,
        strideInPixelsX: 2,
        strideInPixelsY: 2
    )
    precondition(poolNode.kernelWidth == 2 && poolNode.strideInPixelsX == 2)
    _ = MPSCNNPoolingNode(source: MPSNNImageNode(handle: nil), filterSize: 3)
    _ = MPSCNNPoolingNode(source: MPSNNImageNode(handle: nil), filterSize: 3, stride: 1)
    _ = poolNode.kernelHeight
    _ = poolNode.strideInPixelsY

    let pad = MPSNNPad(
        device: device,
        paddingSizeBefore: MPSImageCoordinate(x: 1, y: 1, channel: 0),
        paddingSizeAfter: MPSImageCoordinate(x: 2, y: 2, channel: 0),
        fillValueArray: nil
    )
    pad.fillValue = 0
    precondition(pad.paddingSizeBefore.x == 1)
    precondition(pad.paddingSizeAfter.x == 2)
    _ = MPSNNPad(device: device)
    _ = MPSNNPad(device: device, paddingSizeBefore: MPSImageCoordinate(), paddingSizeAfter: MPSImageCoordinate())
    precondition(MPSNNPad(coder: NSCoder(), device: device) == nil)

    let corr = MPSNNLocalCorrelation(device: device, windowInX: 3, windowInY: 3, strideInX: 1, strideInY: 1)
    precondition(corr.windowInX == 3 && corr.windowInY == 3)
    precondition(corr.strideInX == 1 && corr.strideInY == 1)
    _ = MPSNNLocalCorrelation(device: device)
    precondition(MPSNNLocalCorrelation(coder: NSCoder(), device: device) == nil)

    let gk = MPSCNNGradientKernel(device: device)
    gk.kernelOffsetX = 2
    gk.kernelOffsetY = 3
    precondition(gk.kernelOffsetX == 2 && gk.kernelOffsetY == 3)
    precondition(MPSCNNGradientKernel(coder: NSCoder(), device: device) == nil)
}

func testMPSRNNInferenceAndImageFilters() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let desc = MPSRNNSingleGateDescriptor.createRNNSingleGateDescriptor(withInputFeatureChannels: 2, outputFeatureChannels: 3)
    let matrixLayer = MPSRNNMatrixInferenceLayer(device: device, rnnDescriptor: desc)
    precondition(matrixLayer.inputFeatureChannels == 2)
    precondition(matrixLayer.outputFeatureChannels == 3)
    precondition(matrixLayer.numberOfLayers == 1)
    matrixLayer.bidirectionalCombineMode = .add
    matrixLayer.recurrentOutputIsTemporary = true
    matrixLayer.storeAllIntermediateStates = true
    let stacked = MPSRNNMatrixInferenceLayer(device: device, rnnDescriptors: [desc, desc])
    precondition(stacked.numberOfLayers == 2)
    _ = stacked.copy(with: nil, device: device)
    let src = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .float32))
    let dst = MPSMatrix(device: device, descriptor: MPSMatrixDescriptor(rows: 1, columns: 3, rowBytes: 12, dataType: .float32))
    MPSHostBoundary.reset()
    matrixLayer.encodeSequence(
        commandBuffer: cmd,
        sourceMatrices: [src],
        destinationMatrices: [dst],
        recurrentInputState: nil,
        recurrentOutputStates: nil
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var srcOff = 0
    var dstOff = 0
    matrixLayer.encodeSequence(
        commandBuffer: cmd,
        sourceMatrices: [src],
        sourceOffsets: &srcOff,
        destinationMatrices: [dst],
        destinationOffsets: &dstOff,
        recurrentInputState: nil,
        recurrentOutputStates: nil
    )
    matrixLayer.encodeBidirectionalSequence(
        commandBuffer: cmd,
        sourceSequence: [src],
        destinationForwardMatrices: [dst],
        destinationBackwardMatrices: nil
    )
    precondition(MPSRNNMatrixInferenceLayer(coder: NSCoder(), device: device) == nil)
    _ = MPSRNNMatrixInferenceLayer(device: device)
    let rec = MPSRNNRecurrentMatrixState(recurrent: [src], memory: [nil])
    _ = rec.getRecurrentOutputMatrix(forLayerIndex: 0)
    _ = rec.getMemoryCellMatrix(forLayerIndex: 1)

    let imageLayer = MPSRNNImageInferenceLayer(device: device, rnnDescriptor: desc)
    precondition(imageLayer.inputFeatureChannels == 2 && imageLayer.outputFeatureChannels == 3)
    imageLayer.bidirectionalCombineMode = .concatenate
    imageLayer.recurrentOutputIsTemporary = false
    imageLayer.storeAllIntermediateStates = false
    _ = MPSRNNImageInferenceLayer(device: device, rnnDescriptors: [desc])
    _ = imageLayer.copy(with: nil, device: device)
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .float16, width: 2, height: 2, featureChannels: 2)
    )
    MPSHostBoundary.reset()
    imageLayer.encodeSequence(
        commandBuffer: cmd,
        sourceImages: [image],
        destinationImages: [image],
        recurrentInputState: nil,
        recurrentOutputStates: nil
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    imageLayer.encodeBidirectionalSequence(
        commandBuffer: cmd,
        sourceSequence: [image],
        destinationForwardImages: [image],
        destinationBackwardImages: nil
    )
    precondition(MPSRNNImageInferenceLayer(coder: NSCoder(), device: device) == nil)
    _ = MPSRNNImageInferenceLayer(device: device)
    let recImage = MPSRNNRecurrentImageState(recurrent: [image], memory: [nil])
    _ = recImage.getRecurrentOutputImage(forLayerIndex: 0)
    _ = recImage.getMemoryCellImage(forLayerIndex: 1)
    _ = MPSRNNRecurrentImageState(resource: nil)

    let ed = MPSImageEDLines(
        device: device,
        gaussianSigma: 1.5,
        minLineLength: 8,
        maxLines: 16,
        detailRatio: 2,
        gradientThreshold: 0.2,
        lineErrorThreshold: 1.1,
        mergeLocalityThreshold: 0.5
    )
    precondition(ed.gaussianSigma == 1.5)
    precondition(ed.minLineLength == 8)
    ed.maxLines = 10
    ed.detailRatio = 3
    ed.gradientThreshold = 0.3
    ed.lineErrorThreshold = 0.9
    ed.mergeLocalityThreshold = 0.4
    ed.clipRectSource = MTLRegion.make2D(0, 0, 4, 4)
    let texture = device.makeTexture(
        descriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 4, height: 4, mipmapped: false)
    )
    MPSHostBoundary.reset()
    ed.encode(
        to: cmd,
        sourceTexture: texture,
        destinationTexture: texture,
        endpointBuffer: device.makeBuffer(length: 64),
        endpointOffset: 0
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(MPSImageEDLines(coder: NSCoder(), device: device) == nil)
    _ = MPSImageEDLines(device: device)

    let guided = MPSImageGuidedFilter(device: device, kernelDiameter: 5)
    precondition(guided.kernelDiameter == 5)
    guided.epsilon = 0.01
    guided.reconstructOffset = 0
    guided.reconstructScale = 1
    MPSHostBoundary.reset()
    guided.encodeRegression(
        to: cmd,
        sourceTexture: texture,
        guidanceTexture: texture,
        weightsTexture: nil,
        destinationCoefficientsTexture: texture
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    guided.encodeRegression(
        commandBuffer: cmd,
        source: texture,
        guidance: texture,
        weights: nil,
        destinationCoefficientsTextureA: texture,
        destinationCoefficientsTextureB: texture
    )
    guided.encodeReconstruction(to: cmd, guidanceTexture: texture, coefficientsTexture: texture, destinationTexture: texture)
    guided.encodeReconstruction(
        commandBuffer: cmd,
        guidance: texture,
        coefficientsTextureA: texture,
        coefficientsTextureB: texture,
        destination: texture
    )
    precondition(MPSImageGuidedFilter(coder: NSCoder(), device: device) == nil)
    _ = MPSImageGuidedFilter(device: device)

    var info = MPSImageHistogramInfo()
    info.numberOfHistogramEntries = 64
    let hist = MPSImageNormalizedHistogram(device: device, histogramInfo: &info)
    precondition(hist.histogramInfo.numberOfHistogramEntries == 64)
    hist.zeroHistogram = true
    hist.clipRectSource = MTLRegion.make2D(0, 0, 4, 4)
    precondition(hist.histogramSize(forSourceFormat: .rgba8Unorm) == 64 * 16)
    MPSHostBoundary.reset()
    hist.encode(
        to: cmd,
        sourceTexture: texture,
        minmaxTexture: texture,
        histogram: device.makeBuffer(length: 1024),
        histogramOffset: 0
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    precondition(MPSImageNormalizedHistogram(coder: NSCoder(), device: device) == nil)
    _ = MPSImageNormalizedHistogram(device: device)

    let allocator = MPSSVGFDefaultTextureAllocator(device: device)
    precondition(allocator.device.name == device.name)
    let allocated = allocator.texture(with: .rgba8Unorm, width: 2, height: 2)
    precondition(allocator.allocatedTextureCount == 1)
    if let allocated {
        allocator.return(allocated)
    }
    allocator.reset()
    precondition(allocator.allocatedTextureCount == 0)
    let svgf = MPSSVGF(device: device)
    let denoiser = MPSSVGFDenoiser(SVGF: svgf, textureAllocator: allocator)
    denoiser.bilateralFilterIterations = 2
    precondition(denoiser.svgf === svgf)
    _ = denoiser.textureAllocator
    denoiser.clearTemporalHistory()
    MPSHostBoundary.reset()
    _ = denoiser.encode(
        commandBuffer: cmd,
        sourceTexture: texture,
        motionVectorTexture: nil,
        depthNormalTexture: texture,
        previousDepthNormalTexture: nil
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var dest: any MTLTexture = texture
    var dest2: any MTLTexture = texture
    denoiser.encode(
        commandBuffer: cmd,
        sourceTexture: texture,
        destinationTexture: &dest,
        sourceTexture2: texture,
        destinationTexture2: &dest2,
        motionVectorTexture: nil,
        depthNormalTexture: texture,
        previousDepthNormalTexture: nil
    )
    denoiser.releaseTemporaryTextures()
    _ = MPSSVGFDenoiser(device: device)
}
