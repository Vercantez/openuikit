import Foundation
import MetalPerformanceShaders

final class MPSTestHandle: NSObject, MPSHandle {
    static var supportsSecureCoding: Bool { true }
    let label: String
    init(label: String) { self.label = label }
    required init?(coder: NSCoder) { self.label = ""; super.init() }
    func encode(with coder: NSCoder) { _ = coder }
}

final class MPSTestConvolutionDataSource: NSObject, MPSCNNConvolutionDataSource {
    let storedDescriptor: MPSCNNConvolutionDescriptor
    var weightStorage: UnsafeMutablePointer<Float>
    var biasStorage: UnsafeMutablePointer<Float>

    override init() {
        storedDescriptor = MPSCNNConvolutionDescriptor(
            kernelWidth: 1,
            kernelHeight: 1,
            inputFeatureChannels: 1,
            outputFeatureChannels: 1
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
        return MPSTestConvolutionDataSource()
    }

    func biasTerms() -> UnsafeMutablePointer<Float>? { biasStorage }
    func dataType() -> MPSDataType { .float32 }
    func descriptor() -> MPSCNNConvolutionDescriptor { storedDescriptor }
    func label() -> String? { "test-weights" }
    func load() -> Bool { true }
    func purge() {}
    func weights() -> UnsafeMutableRawPointer { UnsafeMutableRawPointer(weightStorage) }
}

func testMPSNNNeuronDescriptor() {
    let none = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .none)
    precondition(none.neuronType == .none)
    let relu = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .reLU, a: 0.1)
    precondition(relu.a == 0.1)
    let sig = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .sigmoid, a: 1, b: 2)
    precondition(sig.b == 2)
    let elu = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .ELU, a: 1, b: 0, c: 0)
    precondition(elu.c == 0)
    let prelu = MPSNNNeuronDescriptor.cnnNeuronPReLUDescriptor(with: Data([1, 2, 3]), noCopy: false)
    precondition(prelu.neuronType == .pReLU)
    precondition(prelu.data?.count == 3)
    let copied = relu.copy() as! MPSNNNeuronDescriptor
    precondition(copied.a == 0.1)
    _ = MPSNNNeuronDescriptor()
}

func testMPSCNNConvolutionDescriptor() {
    let descriptor = MPSCNNConvolutionDescriptor(
        kernelWidth: 3,
        kernelHeight: 5,
        inputFeatureChannels: 4,
        outputFeatureChannels: 8
    )
    precondition(descriptor.kernelWidth == 3 && descriptor.kernelHeight == 5)
    precondition(descriptor.inputFeatureChannels == 4 && descriptor.outputFeatureChannels == 8)
    descriptor.strideInPixelsX = 2
    descriptor.strideInPixelsY = 3
    descriptor.groups = 1
    descriptor.dilationRateX = 1
    descriptor.dilationRateY = 2
    precondition(descriptor.strideInPixelsX == 2 && descriptor.dilationRateY == 2)
    descriptor.setNeuronType(.reLU, parameterA: 0.2, parameterB: 0)
    precondition(descriptor.neuronType() == .reLU)
    precondition(descriptor.neuronParameterA() == 0.2)
    precondition(descriptor.neuronParameterB() == 0)
    precondition(descriptor.fusedNeuronDescriptor.neuronType == .reLU)
    descriptor.setNeuronToPReLUWithParametersA(Data([4, 5]))
    precondition(descriptor.neuronType() == .pReLU)
    descriptor.setBatchNormalizationParametersForInferenceWithMean(nil, variance: nil, gamma: nil, beta: nil, epsilon: 1e-4)
    precondition(MPSCNNConvolutionDescriptor.supportsSecureCoding)
    descriptor.encode(with: NSCoder())
    precondition(MPSCNNConvolutionDescriptor(coder: NSCoder()) == nil)
    let relu = MPSCNNNeuronReLU(device: MPSHostDevice.shared, a: 0)
    let withNeuron = MPSCNNConvolutionDescriptor(
        kernelWidth: 1,
        kernelHeight: 1,
        inputFeatureChannels: 1,
        outputFeatureChannels: 1,
        neuronFilter: relu
    )
    precondition(withNeuron.neuron === relu)
    _ = withNeuron.copy()
}

func testMPSCNNKernelFailClosed() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let kernel = MPSCNNKernel(device: device)
    kernel.clipRect = MPSRectNoClip
    kernel.offset = MPSOffset(x: 0, y: 0, z: 0)
    kernel.edgeMode = .clamp
    kernel.destinationFeatureChannelOffset = 0
    kernel.sourceFeatureChannelOffset = 0
    kernel.sourceFeatureChannelMaxCount = 4
    kernel.destinationImageAllocator = MPSImage.defaultAllocator()
    kernel.padding = MPSNNDefaultPadding(method: .sizeSame)
    precondition(kernel.kernelWidth == 1 && kernel.kernelHeight == 1)
    precondition(kernel.strideInPixelsX == 1 && kernel.strideInPixelsY == 1)
    precondition(kernel.dilationRateX == 1 && kernel.dilationRateY == 1)
    precondition(!kernel.isBackwards && !kernel.isStateModified)
    precondition(!kernel.appendBatchBarrier())
    precondition(!kernel.isResultStateReusedAcrossBatch())
    precondition(kernel.encodingStorageSize(sourceImage: image, sourceStates: nil, destinationImage: nil) == 0)
    precondition(kernel.batchEncodingStorageSize(sourceImage: [image], sourceStates: nil, destinationImage: nil) == 0)
    let destDesc = kernel.destinationImageDescriptor(sourceImages: [image], sourceStates: nil)
    precondition(destDesc.width == 2)
    precondition(kernel.resultState(sourceImage: image, sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.resultStateBatch(sourceImage: [image], sourceStates: nil, destinationImage: [image]) == nil)
    precondition(kernel.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image) == nil)
    precondition(kernel.temporaryResultStateBatch(commandBuffer: cmd, sourceImage: [image], sourceStates: nil, destinationImage: [image]) == nil)
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    _ = kernel.encode(commandBuffer: cmd, sourceImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    kernel.encode(commandBuffer: cmd, sourceImage: image, destinationState: MPSState(resource: nil), destinationImage: image)
    var state: MPSState? = MPSState(resource: nil)
    _ = kernel.encode(commandBuffer: cmd, sourceImage: image, destinationState: &state, destinationStateIsTemporary: false)
    kernel.encodeBatch(commandBuffer: cmd, sourceImages: [image], destinationImages: [image])
    _ = kernel.encodeBatch(commandBuffer: cmd, sourceImages: [image])
    kernel.encodeBatch(commandBuffer: cmd, sourceImages: [image], destinationStates: nil, destinationImages: [image])
    var states: NSArray?
    _ = kernel.encodeBatch(commandBuffer: cmd, sourceImages: [image], destinationStates: &states, destinationStateIsTemporary: true)
    precondition(MPSCNNKernel(coder: NSCoder(), device: device) == nil)
}

func testMPSCNNConvolutionConstruct() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    var weights: [Float] = [1]
    var bias: [Float] = [0]
    let descriptor = MPSCNNConvolutionDescriptor(
        kernelWidth: 1,
        kernelHeight: 1,
        inputFeatureChannels: 1,
        outputFeatureChannels: 1
    )
    let conv = MPSCNNConvolution(
        device: device,
        convolutionDescriptor: descriptor,
        kernelWeights: &weights,
        biasTerms: &bias,
        flags: .none
    )
    precondition(conv.inputFeatureChannels == 1 && conv.outputFeatureChannels == 1)
    precondition(conv.groups == 1)
    precondition(conv.channelMultiplier == 1)
    precondition(conv.subPixelScaleFactor == 1)
    precondition(conv.neuronType == .none)
    _ = conv.neuron
    _ = conv.neuronParameterA
    _ = conv.neuronParameterB
    _ = conv.neuronParameterC
    _ = conv.fusedNeuronDescriptor
    _ = conv.dataSource
    conv.accumulatorPrecisionOption = .float
    precondition(conv.accumulatorPrecisionOption.contains(.float))
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    MPSHostBoundary.reset()
    conv.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let exported = conv.exportWeightsAndBiases(with: cmd, resultStateCanBeTemporary: false)
    _ = exported.weights
    _ = exported.biases
    conv.reloadWeightsAndBiasesFromDataSource()
    conv.reloadWeightsAndBiases(with: MPSTestConvolutionDataSource())
    conv.reloadWeightsAndBiases(with: cmd, state: exported)
    _ = conv.resultState(sourceImage: image, sourceStates: nil, destinationImage: image)
    _ = conv.resultStateBatch(sourceImage: [image], sourceStates: nil, destinationImage: [image])
    _ = conv.temporaryResultState(commandBuffer: cmd, sourceImage: image, sourceStates: nil, destinationImage: image)
    _ = conv.temporaryResultStateBatch(commandBuffer: cmd, sourceImage: [image], sourceStates: nil, destinationImage: [image])
    let fromSource = MPSCNNConvolution(device: device, weights: MPSTestConvolutionDataSource())
    _ = fromSource.dataSource.label()
    precondition(MPSCNNConvolution(coder: NSCoder(), device: device) == nil)
    _ = MPSCNNConvolution(device: device)
}

func testMPSCNNNeuron() {
    let device = MPSHostDevice.shared
    let descriptor = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: .reLU, a: 0.01)
    let neuron = MPSCNNNeuron(device: device, neuronDescriptor: descriptor)
    precondition(neuron.neuronType == .reLU)
    precondition(neuron.a == 0.01)
    _ = neuron.b
    _ = neuron.c
    _ = neuron.data
    _ = MPSCNNNeuron(device: device)
    precondition(MPSCNNNeuron(coder: NSCoder(), device: device) == nil)
    let relu = MPSCNNNeuronReLU(device: device, a: 0.2)
    precondition(relu.neuronType == .reLU)
    precondition(relu.a == 0.2)
}

func testMPSNNGraphFailClosed() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let handle = MPSTestHandle(label: "in")
    let node = MPSNNImageNode(handle: handle)
    node.format = .float16
    node.imageAllocator = MPSImage.defaultAllocator()
    node.exportFromGraph = true
    node.stopGradient = false
    node.synchronizeResource = false
    precondition(node.handle?.label == "in")
    let exported = MPSNNImageNode.exportedNode(with: handle)
    precondition(exported.exportFromGraph)
    let graph = MPSNNGraph(device: device, resultImage: node)
    precondition(graph != nil)
    graph!.format = .float16
    graph!.destinationImageAllocator = MPSImage.defaultAllocator()
    graph!.outputStateIsTemporary = false
    precondition(graph!.resultImageIsNeeded)
    _ = graph!.resultHandle
    _ = graph!.sourceImageHandles
    _ = graph!.sourceStateHandles
    _ = graph!.intermediateImageHandles
    _ = graph!.resultStateHandles
    _ = graph!.readCountForSourceImage(at: 0)
    _ = graph!.readCountForSourceState(at: 0)
    graph!.reloadFromDataSources()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 1, height: 1, featureChannels: 1)
    )
    MPSHostBoundary.reset()
    let encoded = graph!.encode(to: cmd, sourceImages: [image])
    precondition(encoded == nil)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    _ = graph!.encode(to: cmd, sourceImages: [image], sourceStates: nil, intermediateImages: nil, destinationStates: nil)
    MPSHostBoundary.reset()
    precondition(graph!.encodeBatch(to: cmd, sourceImages: [[image]], sourceStates: nil) == nil)
    _ = graph!.encodeBatch(
        to: cmd,
        sourceImages: [[image]],
        sourceStates: nil,
        intermediateImages: nil,
        destinationStates: nil
    )
    var handlerRan = false
    MPSHostBoundary.reset()
    _ = graph!.executeAsync(withSourceImages: [image]) { result, error in
        handlerRan = true
        precondition(result == nil)
        precondition(error != nil)
    }
    precondition(handlerRan)
    precondition(MPSNNGraph(device: device, resultImage: node, resultImageIsNeeded: false) != nil)
    var needed = ObjCBool(true)
    precondition(MPSNNGraph(device: device, resultImages: [node], resultsAreNeeded: &needed) != nil)
    precondition(MPSNNGraph(coder: NSCoder(), device: device) == nil)
    _ = MPSNNGraph(device: device)
}

func testMPSRNNDescriptor() {
    let descriptor = MPSRNNDescriptor()
    descriptor.inputFeatureChannels = 8
    descriptor.outputFeatureChannels = 16
    descriptor.useLayerInputUnitTransformMode = true
    descriptor.useFloat32Weights = true
    descriptor.layerSequenceDirection = .backward
    precondition(descriptor.inputFeatureChannels == 8)
    precondition(descriptor.outputFeatureChannels == 16)
    precondition(descriptor.useLayerInputUnitTransformMode)
    precondition(descriptor.useFloat32Weights)
    precondition(descriptor.layerSequenceDirection == .backward)
    let gate = MPSRNNSingleGateDescriptor.createRNNSingleGateDescriptor(
        withInputFeatureChannels: 4,
        outputFeatureChannels: 4
    )
    precondition(gate.inputFeatureChannels == 4)
    gate.inputWeights = MPSTestConvolutionDataSource()
    gate.recurrentWeights = MPSTestConvolutionDataSource()
    precondition(gate.inputWeights != nil && gate.recurrentWeights != nil)
}

func testMPSRayIntersectorFailClosed() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let rays = MPSRayIntersector(device: device)
    rays.cullMode = .back
    rays.frontFacingWinding = .counterClockwise
    rays.intersectionDataType = .distance
    rays.intersectionStride = 16
    rays.rayDataType = .originDirection
    rays.rayIndexDataType = .uInt32
    rays.rayMask = 1
    rays.rayMaskOperator = .and
    rays.rayMaskOptions = .primitive
    rays.rayStride = 32
    rays.boundingBoxIntersectionTestType = .fast
    rays.triangleIntersectionTestType = .watertight
    precondition(rays.recommendedMinimumRayBatchSize(rayCount: 8) == 8)
    let copied = rays.copy(with: nil, device: device)
    precondition(copied.cullMode == .back)
    rays.encode(with: NSCoder())
    precondition(MPSRayIntersector(coder: NSCoder(), device: device) == nil)
    precondition(MPSRayIntersector(coder: NSCoder()) == nil)
    let accel = MPSAccelerationStructure(device: device)
    let rayBuffer = device.makeBuffer(length: 64)
    let hitBuffer = device.makeBuffer(length: 64)
    MPSHostBoundary.reset()
    rays.encodeIntersection(
        commandBuffer: cmd,
        intersectionType: .nearest,
        rayBuffer: rayBuffer,
        rayBufferOffset: 0,
        intersectionBuffer: hitBuffer,
        intersectionBufferOffset: 0,
        rayCount: 1,
        accelerationStructure: accel
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    rays.encodeIntersection(
        commandBuffer: cmd,
        intersectionType: .any,
        rayBuffer: rayBuffer,
        rayBufferOffset: 0,
        intersectionBuffer: hitBuffer,
        intersectionBufferOffset: 0,
        rayCountBuffer: device.makeBuffer(length: 4),
        rayCountBufferOffset: 0,
        accelerationStructure: accel
    )
    rays.encodeIntersection(
        commandBuffer: cmd,
        intersectionType: .nearest,
        rayBuffer: rayBuffer,
        rayBufferOffset: 0,
        rayIndexBuffer: device.makeBuffer(length: 4),
        rayIndexBufferOffset: 0,
        intersectionBuffer: hitBuffer,
        intersectionBufferOffset: 0,
        rayIndexCount: 1,
        accelerationStructure: accel
    )
    rays.encodeIntersection(
        commandBuffer: cmd,
        intersectionType: .nearest,
        rayBuffer: rayBuffer,
        rayBufferOffset: 0,
        rayIndexBuffer: device.makeBuffer(length: 4),
        rayIndexBufferOffset: 0,
        intersectionBuffer: hitBuffer,
        intersectionBufferOffset: 0,
        rayIndexCountBuffer: device.makeBuffer(length: 4),
        rayIndexCountBufferOffset: 0,
        accelerationStructure: accel
    )
    let texture = device.makeTexture(
        descriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: 2, height: 2, mipmapped: false)
    )
    MPSHostBoundary.reset()
    rays.encodeIntersection(
        commandBuffer: cmd,
        intersectionType: .nearest,
        rayTexture: texture,
        intersectionTexture: texture,
        accelerationStructure: accel
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
}

func testMPSNNDefaultPadding() {
    let padding = MPSNNDefaultPadding(method: .sizeSame)
    precondition(padding.paddingMethod() == .sizeSame)
    precondition(padding.label() == "MPSNNDefaultPadding")
    precondition(padding.inverse() == nil)
    let device = MPSHostDevice.shared
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 1)
    )
    let suggested = MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 1)
    let dest = padding.destinationImageDescriptor(
        forSourceImages: [image],
        sourceStates: nil,
        for: MPSKernel(device: device),
        suggestedDescriptor: suggested
    )
    precondition(dest.width == 4)
    precondition(MPSNNDefaultPadding.supportsSecureCoding)
    padding.encode(with: NSCoder())
    precondition(MPSNNDefaultPadding(coder: NSCoder()) == nil)
    let tf = MPSNNDefaultPadding.forTensorflowAveragePooling()
    precondition(tf.paddingMethod() == .sizeSame)
    let valid = MPSNNDefaultPadding.forTensorflowAveragePoolingValidOnly()
    precondition(valid.paddingMethod().rawValue == MPSNNPaddingMethod.validOnly.rawValue)
}

func testMPSNNImageNodeAndFilterNode() {
    let handle = MPSTestHandle(label: "node")
    let imageNode = MPSNNImageNode(handle: handle)
    precondition(imageNode.handle?.label == "node")
    let filter = MPSNNFilterNode()
    filter.label = "conv"
    filter.paddingPolicy = MPSNNDefaultPadding(method: .validOnly)
    precondition(filter.label == "conv")
    _ = filter.resultImage
    _ = filter.resultState
    _ = filter.resultStates
    _ = filter.gradientFilter(withSource: imageNode)
    _ = filter.gradientFilter(withSources: [imageNode])
    _ = filter.gradientFilters(withSource: imageNode)
    _ = filter.gradientFilters(withSources: [imageNode])
    precondition(filter.trainingGraph(withSourceGradient: nil, nodeHandler: nil) == nil)
    let convNode = MPSCNNConvolutionNode(source: imageNode, weights: MPSTestConvolutionDataSource())
    convNode.accumulatorPrecision = .float
    convNode.trainingStyle = .updateDeviceCPU
    _ = convNode.convolutionGradientState
}

func testMPSCNNPoolingDescriptor() {
    let device = MPSHostDevice.shared
    let pool = MPSCNNPooling(device: device, kernelWidth: 2, kernelHeight: 3)
    precondition(pool.kernelWidth == 2 && pool.kernelHeight == 3)
    let strided = MPSCNNPooling(device: device, kernelWidth: 3, kernelHeight: 3, strideInPixelsX: 2, strideInPixelsY: 2)
    precondition(strided.strideInPixelsX == 2 && strided.strideInPixelsY == 2)
    precondition(MPSCNNPooling(coder: NSCoder(), device: device) == nil)
    let avg = MPSCNNPoolingAverage(device: device, kernelWidth: 2, kernelHeight: 2, strideInPixelsX: 2, strideInPixelsY: 2)
    avg.zeroPadSizeX = 1
    avg.zeroPadSizeY = 1
    precondition(avg.zeroPadSizeX == 1 && avg.zeroPadSizeY == 1)
    precondition(MPSCNNPoolingAverage(coder: NSCoder(), device: device) == nil)
    let maxPool = MPSCNNPoolingMax(device: device, kernelWidth: 2, kernelHeight: 2, strideInPixelsX: 1, strideInPixelsY: 1)
    precondition(maxPool.kernelWidth == 2)
    precondition(MPSCNNPoolingMax(coder: NSCoder(), device: device) == nil)
    MPSHostBoundary.reset()
    let image = MPSImage(
        device: device,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 1)
    )
    maxPool.encode(commandBuffer: device.makeCommandBuffer(), sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
}

func testMPSCNNConvolutionDataSource() {
    let source = MPSTestConvolutionDataSource()
    precondition(source.load())
    precondition(source.dataType() == .float32)
    precondition(source.descriptor().kernelWidth == 1)
    precondition(source.label() == "test-weights")
    precondition(source.weights().load(as: Float.self) == 1)
    precondition(source.biasTerms()?[0] == 0)
    source.purge()
    _ = source.copy()
    _ = source.copy(with: nil, device: MPSHostDevice.shared)
    _ = source.kernelWeightsDataType()
    _ = source.weightsLayout()
    _ = source.weightsQuantizationType()
    let lut = source.lookupTableForUInt8Kernel()
    lut.deallocate()
    let ranges = source.rangesForUInt8Kernel()
    ranges.deallocate()
    let conv = MPSCNNConvolution(device: MPSHostDevice.shared, weights: source)
    let gradient = MPSCNNConvolutionGradientState(convolution: conv)
    let weightsState = MPSCNNConvolutionWeightsAndBiasesState(
        device: MPSHostDevice.shared,
        cnnConvolutionDescriptor: source.descriptor()
    )
    precondition(source.update(with: gradient, sourceState: weightsState) == false)
    precondition(
        source.update(
            with: MPSHostDevice.shared.makeCommandBuffer(),
            gradientState: gradient,
            sourceState: weightsState
        ) == nil
    )
}

func testMPSCNNWeightsState() {
    let device = MPSHostDevice.shared
    let descriptor = MPSCNNConvolutionDescriptor(
        kernelWidth: 1,
        kernelHeight: 1,
        inputFeatureChannels: 2,
        outputFeatureChannels: 3
    )
    let state = MPSCNNConvolutionWeightsAndBiasesState(device: device, cnnConvolutionDescriptor: descriptor)
    precondition(state.weights.length > 0)
    precondition(state.biases != nil)
    precondition(state.weightsOffset == 0 && state.biasesOffset == 0)
    let weights = device.makeBuffer(length: 16)
    let biases = device.makeBuffer(length: 12)
    let fromBuffers = MPSCNNConvolutionWeightsAndBiasesState(weights: weights, biases: biases)
    precondition(fromBuffers.weights.length == 16)
    let offset = MPSCNNConvolutionWeightsAndBiasesState(
        weights: weights,
        weightsOffset: 4,
        biases: biases,
        biasesOffset: 8,
        cnnConvolutionDescriptor: descriptor
    )
    precondition(offset.weightsOffset == 4 && offset.biasesOffset == 8)
    let cmd = device.makeCommandBuffer()
    let temporary = MPSCNNConvolutionWeightsAndBiasesState.temporaryCNNConvolutionWeightsAndBiasesState(
        with: cmd,
        cnnConvolutionDescriptor: descriptor
    )
    _ = temporary.weights
}
