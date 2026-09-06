import Foundation

public protocol MPSCNNConvolutionDataSource: NSObjectProtocol, NSCopying {
    func biasTerms() -> UnsafeMutablePointer<Float>?
    func dataType() -> MPSDataType
    func descriptor() -> MPSCNNConvolutionDescriptor
    func label() -> String?
    func load() -> Bool
    func purge()
    func weights() -> UnsafeMutableRawPointer
}

extension MPSCNNConvolutionDataSource {
    public func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        _ = (zone, device)
        return self
    }

    public func kernelWeightsDataType() -> MPSDataType { dataType() }

    public func lookupTableForUInt8Kernel() -> UnsafeMutablePointer<Float> {
        UnsafeMutablePointer<Float>.allocate(capacity: 1)
    }

    public func rangesForUInt8Kernel() -> UnsafeMutablePointer<vector_float2> {
        UnsafeMutablePointer<vector_float2>.allocate(capacity: 1)
    }

    public func update(
        with commandBuffer: any MTLCommandBuffer,
        gradientState: MPSCNNConvolutionGradientState,
        sourceState: MPSCNNConvolutionWeightsAndBiasesState
    ) -> MPSCNNConvolutionWeightsAndBiasesState? {
        _ = (commandBuffer, gradientState, sourceState)
        return nil
    }

    public func update(
        with gradientState: MPSCNNConvolutionGradientState,
        sourceState: MPSCNNConvolutionWeightsAndBiasesState
    ) -> Bool {
        _ = (gradientState, sourceState)
        return false
    }

    public func weightsLayout() -> MPSCNNConvolutionWeightsLayout { .OHWI }

    public func weightsQuantizationType() -> MPSCNNWeightsQuantizationType { .none }
}

open class MPSNNDefaultPadding: NSObject, MPSNNPadding {
    public static var supportsSecureCoding: Bool { true }
    private let method: MPSNNPaddingMethod
    private let paddingLabel: String

    public convenience init(method: MPSNNPaddingMethod) {
        self.init(method: method, label: "MPSNNDefaultPadding")
    }

    public init(method: MPSNNPaddingMethod, label: String) {
        self.method = method
        self.paddingLabel = label
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    open func paddingMethod() -> MPSNNPaddingMethod { method }

    open func label() -> String { paddingLabel }

    open class func forTensorflowAveragePooling() -> Self {
        MPSNNDefaultPadding(method: .sizeSame, label: "tfAveragePooling") as! Self
    }

    open class func forTensorflowAveragePoolingValidOnly() -> Self {
        MPSNNDefaultPadding(method: .validOnly, label: "tfAveragePoolingValidOnly") as! Self
    }
}

open class MPSNNNeuronDescriptor: NSObject, NSCopying {
    public var neuronType: MPSCNNNeuronType
    public var a: Float
    public var b: Float
    public var c: Float
    public var data: Data?

    public override init() {
        self.neuronType = .none
        self.a = 0
        self.b = 0
        self.c = 0
        super.init()
    }

    public class func cnnNeuronDescriptor(with neuronType: MPSCNNNeuronType) -> MPSNNNeuronDescriptor {
        cnnNeuronDescriptor(with: neuronType, a: 0, b: 0, c: 0)
    }

    public class func cnnNeuronDescriptor(with neuronType: MPSCNNNeuronType, a: Float) -> MPSNNNeuronDescriptor {
        cnnNeuronDescriptor(with: neuronType, a: a, b: 0, c: 0)
    }

    public class func cnnNeuronDescriptor(with neuronType: MPSCNNNeuronType, a: Float, b: Float) -> MPSNNNeuronDescriptor {
        cnnNeuronDescriptor(with: neuronType, a: a, b: b, c: 0)
    }

    public class func cnnNeuronDescriptor(
        with neuronType: MPSCNNNeuronType,
        a: Float,
        b: Float,
        c: Float
    ) -> MPSNNNeuronDescriptor {
        let descriptor = MPSNNNeuronDescriptor()
        descriptor.neuronType = neuronType
        descriptor.a = a
        descriptor.b = b
        descriptor.c = c
        return descriptor
    }

    public class func cnnNeuronPReLUDescriptor(with data: Data, noCopy: Bool) -> MPSNNNeuronDescriptor {
        let descriptor = cnnNeuronDescriptor(with: .pReLU)
        descriptor.data = noCopy ? data : Data(data)
        return descriptor
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = MPSNNNeuronDescriptor.cnnNeuronDescriptor(with: neuronType, a: a, b: b, c: c)
        copied.data = data
        return copied
    }
}

open class MPSNNImageNode: NSObject {
    public var handle: (any MPSHandle)?
    public var format: MPSImageFeatureChannelFormat = .float16
    public var imageAllocator: any MPSImageAllocator = MPSImageDefaultAllocator()
    public var exportFromGraph: Bool = false
    public var stopGradient: Bool = false
    public var synchronizeResource: Bool = false

    public override init() {
        self.handle = nil
        super.init()
    }

    public init(handle: (any MPSHandle)?) {
        self.handle = handle
        super.init()
    }

    open class func exportedNode(with handle: (any MPSHandle)?) -> Self {
        let node = MPSNNImageNode(handle: handle)
        node.exportFromGraph = true
        return node as! Self
    }
}

open class MPSNNStateNode: NSObject {
    public var handle: (any MPSHandle)?
    public var exportFromGraph: Bool = false
    public var synchronizeResource: Bool = false
}

open class MPSNNGradientStateNode: MPSNNStateNode {}

open class MPSNNGradientFilterNode: NSObject {}

open class MPSNNFilterNode: NSObject {
    public var label: String?
    public var paddingPolicy: any MPSNNPadding = MPSNNDefaultPadding(method: .validOnly)
    public private(set) var resultImage: MPSNNImageNode
    public private(set) var resultState: MPSNNStateNode?
    public private(set) var resultStates: [MPSNNStateNode]?

    public override init() {
        self.resultImage = MPSNNImageNode(handle: nil)
        super.init()
    }

    open func gradientFilter(withSource gradientImage: MPSNNImageNode) -> MPSNNGradientFilterNode {
        _ = gradientImage
        return MPSNNGradientFilterNode()
    }

    open func gradientFilter(withSources gradientImages: [MPSNNImageNode]) -> MPSNNGradientFilterNode {
        _ = gradientImages
        return MPSNNGradientFilterNode()
    }

    open func gradientFilters(withSource gradientImage: MPSNNImageNode) -> [MPSNNGradientFilterNode] {
        [gradientFilter(withSource: gradientImage)]
    }

    open func gradientFilters(withSources gradientImages: [MPSNNImageNode]) -> [MPSNNGradientFilterNode] {
        [gradientFilter(withSources: gradientImages)]
    }

    open func trainingGraph(
        withSourceGradient gradientImage: MPSNNImageNode?,
        nodeHandler: MPSGradientNodeBlock? = nil
    ) -> [MPSNNFilterNode]? {
        _ = (gradientImage, nodeHandler)
        return nil
    }
}

open class MPSCNNKernel: MPSKernel {
    public var clipRect: MTLRegion = MPSRectNoClip
    public var offset: MPSOffset = MPSOffset()
    public var edgeMode: MPSImageEdgeMode = .clamp
    public var destinationFeatureChannelOffset: Int = 0
    public var sourceFeatureChannelOffset: Int = 0
    public var sourceFeatureChannelMaxCount: Int = Int.max
    public var destinationImageAllocator: any MPSImageAllocator = MPSImageDefaultAllocator()
    public var padding: any MPSNNPadding = MPSNNDefaultPadding(method: .validOnly)
    public var kernelWidth: Int = 1
    public var kernelHeight: Int = 1
    public var strideInPixelsX: Int = 1
    public var strideInPixelsY: Int = 1
    public var dilationRateX: Int = 1
    public var dilationRateY: Int = 1
    public var isBackwards: Bool = false
    public var isStateModified: Bool = false

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func appendBatchBarrier() -> Bool { false }

    open func isResultStateReusedAcrossBatch() -> Bool { false }

    open func encodingStorageSize(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage?
    ) -> Int {
        _ = (sourceImage, sourceStates, destinationImage)
        return 0
    }

    open func batchEncodingStorageSize(
        sourceImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]?
    ) -> Int {
        _ = (sourceImage, sourceStates, destinationImage)
        return 0
    }

    open func destinationImageDescriptor(
        sourceImages: [MPSImage],
        sourceStates: [MPSState]?
    ) -> MPSImageDescriptor {
        _ = sourceStates
        guard let first = sourceImages.first else {
            return MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 1)
        }
        return MPSImageDescriptor(
            channelFormat: first.featureChannelFormat,
            width: first.width,
            height: first.height,
            featureChannels: first.featureChannels
        )
    }

    open func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return nil
    }

    open func resultStateBatch(
        sourceImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = (sourceImage, sourceStates, destinationImage)
        return nil
    }

    open func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = (commandBuffer, sourceImage, sourceStates, destinationImage)
        return nil
    }

    open func temporaryResultStateBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = (commandBuffer, sourceImage, sourceStates, destinationImage)
        return nil
    }

    open func encode(commandBuffer: any MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        _ = (commandBuffer, sourceImage, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNKernel.encode")
    }

    open func encode(commandBuffer: any MTLCommandBuffer, sourceImage: MPSImage) -> MPSImage {
        let dest = destinationImageAllocator.image(
            for: commandBuffer,
            imageDescriptor: destinationImageDescriptor(sourceImages: [sourceImage], sourceStates: nil),
            kernel: self
        )
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: dest)
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationState: MPSState,
        destinationImage: MPSImage
    ) {
        _ = destinationState
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: destinationImage)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationState outState: UnsafeMutablePointer<MPSState?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> MPSImage {
        _ = isTemporary
        outState.pointee = nil
        return encode(commandBuffer: commandBuffer, sourceImage: sourceImage)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationImages: [MPSImage]
    ) {
        if let source = sourceImages.first, let dest = destinationImages.first {
            encode(commandBuffer: commandBuffer, sourceImage: source, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNKernel.encodeBatch")
        }
    }

    open func encodeBatch(commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage]) -> [MPSImage] {
        sourceImages.map { encode(commandBuffer: commandBuffer, sourceImage: $0) }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationStates: [MPSState]?,
        destinationImages: [MPSImage]
    ) {
        _ = destinationStates
        encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImages, destinationImages: destinationImages)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationStates outStates: UnsafeMutablePointer<NSArray?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> [MPSImage] {
        _ = isTemporary
        outStates.pointee = nil
        return encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImages)
    }
}

open class MPSCNNNeuron: MPSCNNKernel {
    public private(set) var neuronType: MPSCNNNeuronType
    public private(set) var a: Float
    public private(set) var b: Float
    public private(set) var c: Float
    public private(set) var data: Data?

    public required init(device: any MTLDevice) {
        self.neuronType = .none
        self.a = 0
        self.b = 0
        self.c = 0
        super.init(device: device)
    }

    public init(device: any MTLDevice, neuronDescriptor: MPSNNNeuronDescriptor) {
        self.neuronType = neuronDescriptor.neuronType
        self.a = neuronDescriptor.a
        self.b = neuronDescriptor.b
        self.c = neuronDescriptor.c
        self.data = neuronDescriptor.data
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNNeuronReLU: MPSCNNNeuron {
    public init(device: any MTLDevice, a: Float) {
        super.init(device: device, neuronDescriptor: .cnnNeuronDescriptor(with: .reLU, a: a))
    }

    public required init(device: any MTLDevice) {
        super.init(device: device, neuronDescriptor: .cnnNeuronDescriptor(with: .reLU))
    }
}

open class MPSCNNConvolutionDescriptor: NSObject, NSSecureCoding, NSCopying {
    public static var supportsSecureCoding: Bool { true }
    public var kernelWidth: Int
    public var kernelHeight: Int
    public var inputFeatureChannels: Int
    public var outputFeatureChannels: Int
    public var strideInPixelsX: Int = 1
    public var strideInPixelsY: Int = 1
    public var groups: Int = 1
    public var dilationRateX: Int = 1
    public var dilationRateY: Int = 1
    public var neuron: MPSCNNNeuron?
    public var fusedNeuronDescriptor: MPSNNNeuronDescriptor = .cnnNeuronDescriptor(with: .none)
    private var storedNeuronA: Float = 0
    private var storedNeuronB: Float = 0
    private var storedNeuronType: MPSCNNNeuronType = .none

    public override init() {
        self.kernelWidth = 1
        self.kernelHeight = 1
        self.inputFeatureChannels = 1
        self.outputFeatureChannels = 1
        super.init()
    }

    public convenience init(
        kernelWidth: Int,
        kernelHeight: Int,
        inputFeatureChannels: Int,
        outputFeatureChannels: Int
    ) {
        self.init(
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            inputFeatureChannels: inputFeatureChannels,
            outputFeatureChannels: outputFeatureChannels,
            neuronFilter: nil
        )
    }

    public convenience init(
        kernelWidth: Int,
        kernelHeight: Int,
        inputFeatureChannels: Int,
        outputFeatureChannels: Int,
        neuronFilter: MPSCNNNeuron?
    ) {
        self.init()
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
        self.inputFeatureChannels = max(inputFeatureChannels, 1)
        self.outputFeatureChannels = max(outputFeatureChannels, 1)
        self.neuron = neuronFilter
        if let neuronFilter {
            fusedNeuronDescriptor = .cnnNeuronDescriptor(
                with: neuronFilter.neuronType,
                a: neuronFilter.a,
                b: neuronFilter.b,
                c: neuronFilter.c
            )
            storedNeuronType = neuronFilter.neuronType
            storedNeuronA = neuronFilter.a
            storedNeuronB = neuronFilter.b
        }
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with aCoder: NSCoder) {
        _ = aCoder
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = MPSCNNConvolutionDescriptor(
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            inputFeatureChannels: inputFeatureChannels,
            outputFeatureChannels: outputFeatureChannels,
            neuronFilter: neuron
        )
        copied.strideInPixelsX = strideInPixelsX
        copied.strideInPixelsY = strideInPixelsY
        copied.groups = groups
        copied.dilationRateX = dilationRateX
        copied.dilationRateY = dilationRateY
        copied.fusedNeuronDescriptor = fusedNeuronDescriptor.copy() as! MPSNNNeuronDescriptor
        return copied
    }

    open func neuronType() -> MPSCNNNeuronType { storedNeuronType }
    open func neuronParameterA() -> Float { storedNeuronA }
    open func neuronParameterB() -> Float { storedNeuronB }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float) {
        storedNeuronType = neuronType
        storedNeuronA = parameterA
        storedNeuronB = parameterB
        fusedNeuronDescriptor = .cnnNeuronDescriptor(with: neuronType, a: parameterA, b: parameterB)
    }

    open func setNeuronToPReLUWithParametersA(_ A: Data) {
        storedNeuronType = .pReLU
        fusedNeuronDescriptor = .cnnNeuronPReLUDescriptor(with: A, noCopy: false)
    }

    open func setBatchNormalizationParametersForInferenceWithMean(
        _ mean: UnsafePointer<Float>?,
        variance: UnsafePointer<Float>?,
        gamma: UnsafePointer<Float>?,
        beta: UnsafePointer<Float>?,
        epsilon: Float
    ) {
        _ = (mean, variance, gamma, beta, epsilon)
    }
}

open class MPSCNNConvolutionWeightsAndBiasesState: MPSState {
    public private(set) var weights: any MTLBuffer
    public private(set) var biases: (any MTLBuffer)?
    public private(set) var weightsOffset: Int
    public private(set) var biasesOffset: Int

    public init(weights: any MTLBuffer, biases: (any MTLBuffer)?) {
        self.weights = weights
        self.biases = biases
        self.weightsOffset = 0
        self.biasesOffset = 0
        super.init(resources: biases.map { [weights, $0] } ?? [weights])
    }

    public init(device: any MTLDevice, cnnConvolutionDescriptor descriptor: MPSCNNConvolutionDescriptor) {
        let weightCount = descriptor.kernelWidth * descriptor.kernelHeight
            * descriptor.inputFeatureChannels * descriptor.outputFeatureChannels
        let host = device as? MPSHostDevice
        let weightBuffer = host?.makeBuffer(length: max(weightCount, 1) * 4)
            ?? MPSHostBuffer(device: device, length: max(weightCount, 1) * 4)
        let biasBuffer = host?.makeBuffer(length: max(descriptor.outputFeatureChannels, 1) * 4)
            ?? MPSHostBuffer(device: device, length: max(descriptor.outputFeatureChannels, 1) * 4)
        self.weights = weightBuffer
        self.biases = biasBuffer
        self.weightsOffset = 0
        self.biasesOffset = 0
        super.init(resources: [weightBuffer, biasBuffer])
    }

    public init(
        weights: any MTLBuffer,
        weightsOffset: Int,
        biases: (any MTLBuffer)?,
        biasesOffset: Int,
        cnnConvolutionDescriptor descriptor: MPSCNNConvolutionDescriptor
    ) {
        _ = descriptor
        self.weights = weights
        self.biases = biases
        self.weightsOffset = weightsOffset
        self.biasesOffset = biasesOffset
        super.init(resources: biases.map { [weights, $0] } ?? [weights])
    }

    open class func temporaryCNNConvolutionWeightsAndBiasesState(
        with commandBuffer: any MTLCommandBuffer,
        cnnConvolutionDescriptor descriptor: MPSCNNConvolutionDescriptor
    ) -> Self {
        let state = MPSCNNConvolutionWeightsAndBiasesState(
            device: commandBuffer.device,
            cnnConvolutionDescriptor: descriptor
        )
        return state as! Self
    }
}

open class MPSCNNConvolutionGradientState: MPSState {
    public private(set) var convolution: MPSCNNConvolution
    public private(set) var gradientForWeights: any MTLBuffer
    public private(set) var gradientForBiases: any MTLBuffer

    public init(convolution: MPSCNNConvolution) {
        self.convolution = convolution
        let device = convolution.device
        self.gradientForWeights = (device as? MPSHostDevice)?.makeBuffer(length: 16)
            ?? MPSHostBuffer(device: device, length: 16)
        self.gradientForBiases = (device as? MPSHostDevice)?.makeBuffer(length: 16)
            ?? MPSHostBuffer(device: device, length: 16)
        super.init(resources: [gradientForWeights, gradientForBiases])
    }
}

open class MPSCNNConvolutionGradientStateNode: MPSNNGradientStateNode {}

open class MPSCNNConvolution: MPSCNNKernel {
    public private(set) var inputFeatureChannels: Int
    public private(set) var outputFeatureChannels: Int
    public private(set) var groups: Int
    public private(set) var channelMultiplier: Int
    public private(set) var subPixelScaleFactor: Int
    public private(set) var neuron: MPSCNNNeuron?
    public private(set) var neuronType: MPSCNNNeuronType
    public private(set) var neuronParameterA: Float
    public private(set) var neuronParameterB: Float
    public private(set) var neuronParameterC: Float
    public private(set) var fusedNeuronDescriptor: MPSNNNeuronDescriptor?
    public private(set) var dataSource: any MPSCNNConvolutionDataSource
    public var accumulatorPrecisionOption: MPSNNConvolutionAccumulatorPrecisionOption = .half
    private var storedWeights: [Float]
    private var storedBiases: [Float]

    public required init(device: any MTLDevice) {
        self.inputFeatureChannels = 1
        self.outputFeatureChannels = 1
        self.groups = 1
        self.channelMultiplier = 1
        self.subPixelScaleFactor = 1
        self.neuronType = .none
        self.neuronParameterA = 0
        self.neuronParameterB = 0
        self.neuronParameterC = 0
        self.storedWeights = [0]
        self.storedBiases = [0]
        self.dataSource = MPSCNNHostConvolutionDataSource.placeholder
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        convolutionDescriptor: MPSCNNConvolutionDescriptor,
        kernelWeights: UnsafePointer<Float>,
        biasTerms: UnsafePointer<Float>?,
        flags: MPSCNNConvolutionFlags
    ) {
        _ = flags
        self.inputFeatureChannels = convolutionDescriptor.inputFeatureChannels
        self.outputFeatureChannels = convolutionDescriptor.outputFeatureChannels
        self.groups = convolutionDescriptor.groups
        self.channelMultiplier = 1
        self.subPixelScaleFactor = 1
        self.neuron = convolutionDescriptor.neuron
        self.neuronType = convolutionDescriptor.neuronType()
        self.neuronParameterA = convolutionDescriptor.neuronParameterA()
        self.neuronParameterB = convolutionDescriptor.neuronParameterB()
        self.neuronParameterC = 0
        self.fusedNeuronDescriptor = convolutionDescriptor.fusedNeuronDescriptor
        let weightCount = convolutionDescriptor.kernelWidth * convolutionDescriptor.kernelHeight
            * convolutionDescriptor.inputFeatureChannels * convolutionDescriptor.outputFeatureChannels
        self.storedWeights = (0..<max(weightCount, 1)).map { kernelWeights[$0] }
        if let biasTerms {
            self.storedBiases = (0..<convolutionDescriptor.outputFeatureChannels).map { biasTerms[$0] }
        } else {
            self.storedBiases = Array(repeating: 0, count: convolutionDescriptor.outputFeatureChannels)
        }
        self.dataSource = MPSCNNHostConvolutionDataSource(
            descriptor: convolutionDescriptor,
            weights: storedWeights,
            biases: storedBiases
        )
        super.init(device: device)
        kernelWidth = convolutionDescriptor.kernelWidth
        kernelHeight = convolutionDescriptor.kernelHeight
        strideInPixelsX = convolutionDescriptor.strideInPixelsX
        strideInPixelsY = convolutionDescriptor.strideInPixelsY
        dilationRateX = convolutionDescriptor.dilationRateX
        dilationRateY = convolutionDescriptor.dilationRateY
    }

    public init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        _ = weights.load()
        let descriptor = weights.descriptor()
        self.inputFeatureChannels = descriptor.inputFeatureChannels
        self.outputFeatureChannels = descriptor.outputFeatureChannels
        self.groups = descriptor.groups
        self.channelMultiplier = 1
        self.subPixelScaleFactor = 1
        self.neuron = descriptor.neuron
        self.neuronType = descriptor.neuronType()
        self.neuronParameterA = descriptor.neuronParameterA()
        self.neuronParameterB = descriptor.neuronParameterB()
        self.neuronParameterC = 0
        self.fusedNeuronDescriptor = descriptor.fusedNeuronDescriptor
        self.dataSource = weights
        let count = descriptor.kernelWidth * descriptor.kernelHeight
            * descriptor.inputFeatureChannels * descriptor.outputFeatureChannels
        let pointer = weights.weights().bindMemory(to: Float.self, capacity: max(count, 1))
        self.storedWeights = (0..<max(count, 1)).map { pointer[$0] }
        if let bias = weights.biasTerms() {
            self.storedBiases = (0..<descriptor.outputFeatureChannels).map { bias[$0] }
        } else {
            self.storedBiases = Array(repeating: 0, count: descriptor.outputFeatureChannels)
        }
        weights.purge()
        super.init(device: device)
        kernelWidth = descriptor.kernelWidth
        kernelHeight = descriptor.kernelHeight
        strideInPixelsX = descriptor.strideInPixelsX
        strideInPixelsY = descriptor.strideInPixelsY
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func exportWeightsAndBiases(
        with commandBuffer: any MTLCommandBuffer,
        resultStateCanBeTemporary: Bool
    ) -> MPSCNNConvolutionWeightsAndBiasesState {
        _ = (commandBuffer, resultStateCanBeTemporary)
        return MPSCNNConvolutionWeightsAndBiasesState(
            device: device,
            cnnConvolutionDescriptor: dataSource.descriptor()
        )
    }

    open func reloadWeightsAndBiasesFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadWeightsAndBiases(with dataSource: any MPSCNNConvolutionDataSource) {
        self.dataSource = dataSource
        reloadWeightsAndBiasesFromDataSource()
    }

    open func reloadWeightsAndBiases(
        with commandBuffer: any MTLCommandBuffer,
        state: MPSCNNConvolutionWeightsAndBiasesState
    ) {
        _ = (commandBuffer, state)
    }

    open override func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNConvolutionGradientState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNConvolutionGradientState(convolution: self)
    }

    open override func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNConvolutionGradientState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }
}

open class MPSCNNConvolutionNode: MPSNNFilterNode {
    public var accumulatorPrecision: MPSNNConvolutionAccumulatorPrecisionOption = .half
    public var trainingStyle: MPSNNTrainingStyle = .UpdateDeviceNone
    public private(set) var convolutionGradientState: MPSCNNConvolutionGradientStateNode?

    public init(source sourceNode: MPSNNImageNode, weights: any MPSCNNConvolutionDataSource) {
        _ = (sourceNode, weights)
        super.init()
        convolutionGradientState = MPSCNNConvolutionGradientStateNode()
    }
}

open class MPSCNNPooling: MPSCNNKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public convenience init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        self.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight, strideInPixelsX: 1, strideInPixelsY: 1)
    }

    public init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        strideInPixelsX: Int,
        strideInPixelsY: Int
    ) {
        super.init(device: device)
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
        self.strideInPixelsX = max(strideInPixelsX, 1)
        self.strideInPixelsY = max(strideInPixelsY, 1)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNPoolingAverage: MPSCNNPooling {
    public var zeroPadSizeX: Int = 0
    public var zeroPadSizeY: Int = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        strideInPixelsX: Int,
        strideInPixelsY: Int
    ) {
        super.init(
            device: device,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            strideInPixelsX: strideInPixelsX,
            strideInPixelsY: strideInPixelsY
        )
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNPoolingMax: MPSCNNPooling {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init(
        device: any MTLDevice,
        kernelWidth: Int,
        kernelHeight: Int,
        strideInPixelsX: Int,
        strideInPixelsY: Int
    ) {
        super.init(
            device: device,
            kernelWidth: kernelWidth,
            kernelHeight: kernelHeight,
            strideInPixelsX: strideInPixelsX,
            strideInPixelsY: strideInPixelsY
        )
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSNNGraph: MPSKernel {
    public var format: MPSImageFeatureChannelFormat = .float16
    public var destinationImageAllocator: any MPSImageAllocator = MPSImageDefaultAllocator()
    public var outputStateIsTemporary: Bool = false
    public private(set) var resultImageIsNeeded: Bool
    public private(set) var resultHandle: (any MPSHandle)?
    public private(set) var sourceImageHandles: [any MPSHandle] = []
    public private(set) var sourceStateHandles: [any MPSHandle]?
    public private(set) var intermediateImageHandles: [any MPSHandle]?
    public private(set) var resultStateHandles: [any MPSHandle]?
    private var sourceReadCounts: [Int] = []

    public required init(device: any MTLDevice) {
        self.resultImageIsNeeded = true
        super.init(device: device)
    }

    public convenience init?(device: any MTLDevice, resultImage: MPSNNImageNode) {
        self.init(device: device, resultImage: resultImage, resultImageIsNeeded: true)
    }

    public init?(device: any MTLDevice, resultImage: MPSNNImageNode, resultImageIsNeeded resultIsNeeded: Bool) {
        self.resultImageIsNeeded = resultIsNeeded
        self.resultHandle = resultImage.handle
        super.init(device: device)
    }

    public init?(
        device: any MTLDevice,
        resultImages: [MPSNNImageNode],
        resultsAreNeeded areResultsNeeded: UnsafeMutablePointer<ObjCBool>?
    ) {
        self.resultImageIsNeeded = areResultsNeeded?.pointee.boolValue ?? true
        self.resultHandle = resultImages.first?.handle
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func readCountForSourceImage(at index: Int) -> Int {
        guard sourceReadCounts.indices.contains(index) else { return 1 }
        return sourceReadCounts[index]
    }

    open func readCountForSourceState(at index: Int) -> Int {
        _ = index
        return 1
    }

    open func reloadFromDataSources() {}

    open func encode(to commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage]) -> MPSImage? {
        _ = (commandBuffer, sourceImages)
        MPSHostBoundary.refuseGPUEncode("MPSNNGraph.encode")
        return nil
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        sourceStates: [MPSState]?,
        intermediateImages: NSMutableArray?,
        destinationStates: NSMutableArray?
    ) -> MPSImage? {
        _ = (sourceStates, intermediateImages, destinationStates)
        return encode(to: commandBuffer, sourceImages: sourceImages)
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceImages: [[MPSImage]],
        sourceStates: [[MPSState]]?
    ) -> [MPSImage]? {
        _ = (commandBuffer, sourceImages, sourceStates)
        MPSHostBoundary.refuseGPUEncode("MPSNNGraph.encodeBatch")
        return nil
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceImages: [[MPSImage]],
        sourceStates: [[MPSState]]?,
        intermediateImages: NSMutableArray?,
        destinationStates: NSMutableArray?
    ) -> [MPSImage]? {
        _ = (intermediateImages, destinationStates)
        return encodeBatch(to: commandBuffer, sourceImages: sourceImages, sourceStates: sourceStates)
    }

    open func executeAsync(
        withSourceImages sourceImages: [MPSImage],
        completionHandler handler: @escaping MPSNNGraphCompletionHandler
    ) -> MPSImage {
        _ = sourceImages
        MPSHostBoundary.refuseGPUEncode("MPSNNGraph.executeAsync")
        let image = MPSImage(
            device: device,
            imageDescriptor: MPSImageDescriptor(channelFormat: format, width: 1, height: 1, featureChannels: 1)
        )
        handler(
            nil,
            NSError(
                domain: "MetalPerformanceShaders",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "MPSNNGraph encode is fail-closed on Linux"]
            )
        )
        return image
    }
}

open class MPSRNNDescriptor: NSObject {
    public var inputFeatureChannels: Int = 1
    public var outputFeatureChannels: Int = 1
    public var useLayerInputUnitTransformMode: Bool = false
    public var useFloat32Weights: Bool = false
    public var layerSequenceDirection: MPSRNNSequenceDirection = .forward
}

open class MPSRNNSingleGateDescriptor: MPSRNNDescriptor {
    public var inputWeights: (any MPSCNNConvolutionDataSource)?
    public var recurrentWeights: (any MPSCNNConvolutionDataSource)?

    open class func createRNNSingleGateDescriptor(
        withInputFeatureChannels inputFeatureChannels: Int,
        outputFeatureChannels: Int
    ) -> Self {
        let descriptor = MPSRNNSingleGateDescriptor()
        descriptor.inputFeatureChannels = inputFeatureChannels
        descriptor.outputFeatureChannels = outputFeatureChannels
        return descriptor as! Self
    }
}

final class MPSCNNHostConvolutionDataSource: NSObject, MPSCNNConvolutionDataSource {
    static let placeholder = MPSCNNHostConvolutionDataSource(
        descriptor: MPSCNNConvolutionDescriptor(
            kernelWidth: 1,
            kernelHeight: 1,
            inputFeatureChannels: 1,
            outputFeatureChannels: 1
        ),
        weights: [0],
        biases: [0]
    )

    private let storedDescriptor: MPSCNNConvolutionDescriptor
    private var weightStorage: UnsafeMutablePointer<Float>
    private var biasStorage: UnsafeMutablePointer<Float>
    private let weightCount: Int
    private let biasCount: Int

    init(descriptor: MPSCNNConvolutionDescriptor, weights: [Float], biases: [Float]) {
        self.storedDescriptor = descriptor
        self.weightCount = max(weights.count, 1)
        self.biasCount = max(biases.count, 1)
        self.weightStorage = UnsafeMutablePointer<Float>.allocate(capacity: weightCount)
        self.biasStorage = UnsafeMutablePointer<Float>.allocate(capacity: biasCount)
        for i in 0..<weightCount {
            weightStorage[i] = i < weights.count ? weights[i] : 0
        }
        for i in 0..<biasCount {
            biasStorage[i] = i < biases.count ? biases[i] : 0
        }
        super.init()
    }

    deinit {
        weightStorage.deallocate()
        biasStorage.deallocate()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let weights = (0..<weightCount).map { weightStorage[$0] }
        let biases = (0..<biasCount).map { biasStorage[$0] }
        return MPSCNNHostConvolutionDataSource(descriptor: storedDescriptor, weights: weights, biases: biases)
    }

    func biasTerms() -> UnsafeMutablePointer<Float>? { biasStorage }

    func dataType() -> MPSDataType { .float32 }

    func descriptor() -> MPSCNNConvolutionDescriptor { storedDescriptor }

    func label() -> String? { "MPSHostCNNConvolutionDataSource" }

    func load() -> Bool { true }

    func purge() {}

    func weights() -> UnsafeMutableRawPointer { UnsafeMutableRawPointer(weightStorage) }
}
