import Foundation

open class MPSCNNGradientKernel: MPSCNNKernel {
    public var kernelOffsetX: Int = 0
    public var kernelOffsetY: Int = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
        isBackwards = true
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceGradient: MPSImage,
        sourceImage: MPSImage,
        gradientState: MPSState,
        destinationGradient: MPSImage
    ) {
        _ = (commandBuffer, sourceGradient, sourceImage, gradientState, destinationGradient)
        MPSHostBoundary.refuseGPUEncode("MPSCNNGradientKernel.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceGradient: MPSImage,
        sourceImage: MPSImage,
        gradientState: MPSState
    ) -> MPSImage {
        let dest = destinationImageAllocator.image(
            for: commandBuffer,
            imageDescriptor: destinationImageDescriptor(sourceImages: [sourceImage], sourceStates: [gradientState]),
            kernel: self
        )
        encode(
            commandBuffer: commandBuffer,
            sourceGradient: sourceGradient,
            sourceImage: sourceImage,
            gradientState: gradientState,
            destinationGradient: dest
        )
        return dest
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        gradientStates: [MPSState],
        destinationGradients: [MPSImage]
    ) {
        if let g = sourceGradients.first, let s = sourceImages.first, let st = gradientStates.first, let d = destinationGradients.first {
            encode(commandBuffer: commandBuffer, sourceGradient: g, sourceImage: s, gradientState: st, destinationGradient: d)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNGradientKernel.encodeBatch")
        }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        gradientStates: [MPSState]
    ) -> [MPSImage] {
        zip(zip(sourceGradients, sourceImages), gradientStates).map { pair, state in
            encode(commandBuffer: commandBuffer, sourceGradient: pair.0, sourceImage: pair.1, gradientState: state)
        }
    }
}

open class MPSCNNConvolutionGradient: MPSCNNGradientKernel {
    public private(set) var dataSource: any MPSCNNConvolutionDataSource
    public private(set) var groups: Int
    public private(set) var channelMultiplier: Int
    public private(set) var sourceGradientFeatureChannels: Int
    public private(set) var sourceImageFeatureChannels: Int
    public var gradientOption: MPSCNNConvolutionGradientOption = .all
    public var serializeWeightsAndBiases: Bool = false

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostConvolutionDataSource.placeholder
        self.groups = 1
        self.channelMultiplier = 1
        self.sourceGradientFeatureChannels = 1
        self.sourceImageFeatureChannels = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        _ = weights.load()
        let descriptor = weights.descriptor()
        self.dataSource = weights
        self.groups = descriptor.groups
        self.channelMultiplier = 1
        self.sourceGradientFeatureChannels = descriptor.outputFeatureChannels
        self.sourceImageFeatureChannels = descriptor.inputFeatureChannels
        super.init(device: device)
        weights.purge()
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func reloadWeightsAndBiasesFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadWeightsAndBiases(with commandBuffer: any MTLCommandBuffer, state: MPSCNNConvolutionWeightsAndBiasesState) {
        _ = (commandBuffer, state)
        MPSHostBoundary.refuseGPUEncode("MPSCNNConvolutionGradient.reloadWeightsAndBiases")
    }
}

open class MPSCNNConvolutionGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        convolutionGradientState gradientState: MPSCNNConvolutionGradientStateNode,
        weights: (any MPSCNNConvolutionDataSource)?
    ) {
        _ = (sourceGradient, sourceImage, gradientState, weights)
        super.init()
    }
}

open class MPSCNNConvolutionTransposeGradient: MPSCNNGradientKernel {
    public private(set) var dataSource: any MPSCNNConvolutionDataSource
    public private(set) var groups: Int
    public private(set) var sourceGradientFeatureChannels: Int
    public private(set) var sourceImageFeatureChannels: Int
    public var gradientOption: MPSCNNConvolutionGradientOption = .all

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostConvolutionDataSource.placeholder
        self.groups = 1
        self.sourceGradientFeatureChannels = 1
        self.sourceImageFeatureChannels = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        _ = weights.load()
        let descriptor = weights.descriptor()
        self.dataSource = weights
        self.groups = descriptor.groups
        self.sourceGradientFeatureChannels = descriptor.inputFeatureChannels
        self.sourceImageFeatureChannels = descriptor.outputFeatureChannels
        super.init(device: device)
        weights.purge()
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func reloadWeightsAndBiasesFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadWeightsAndBiases(with commandBuffer: any MTLCommandBuffer, state: MPSCNNConvolutionWeightsAndBiasesState) {
        _ = (commandBuffer, state)
        MPSHostBoundary.refuseGPUEncode("MPSCNNConvolutionTransposeGradient.reloadWeightsAndBiases")
    }
}

open class MPSCNNConvolutionTransposeGradientNode: MPSNNGradientFilterNode {
    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        convolutionTransposeGradientState: MPSCNNConvolutionTransposeGradientStateNode,
        weights: (any MPSCNNConvolutionDataSource)?
    ) {
        _ = (sourceGradient, sourceImage, convolutionTransposeGradientState, weights)
        super.init()
    }
}

open class MPSCNNArithmeticGradientState: MPSState {
    public init() {
        super.init(resource: nil)
    }
}

open class MPSCNNArithmetic: MPSCNNBinaryKernel {
    public var bias: Float = 0
    public var maximumValue: Float = .greatestFiniteMagnitude
    public var minimumValue: Float = -.greatestFiniteMagnitude
    public var primaryScale: Float = 1
    public var secondaryScale: Float = 1
    public var primaryStrideInFeatureChannels: Int = 1
    public var secondaryStrideInFeatureChannels: Int = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        destinationState: MPSCNNArithmeticGradientState,
        destinationImage: MPSImage
    ) {
        _ = destinationState
        encode(commandBuffer: commandBuffer, primaryImage: primaryImage, secondaryImage: secondaryImage, destinationImage: destinationImage)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        primaryImages: [MPSImage],
        secondaryImages: [MPSImage],
        destinationStates: [MPSCNNArithmeticGradientState],
        destinationImages: [MPSImage]
    ) {
        _ = destinationStates
        encodeBatch(commandBuffer: commandBuffer, primaryImages: primaryImages, secondaryImages: secondaryImages, destinationImages: destinationImages)
    }
}

open class MPSCNNArithmeticGradient: MPSCNNGradientKernel {
    public var bias: Float = 0
    public private(set) var isSecondarySourceFilter: Bool
    public var maximumValue: Float = .greatestFiniteMagnitude
    public var minimumValue: Float = -.greatestFiniteMagnitude
    public var primaryScale: Float = 1
    public var secondaryScale: Float = 1
    public var secondaryStrideInFeatureChannels: Int = 1

    public required init(device: any MTLDevice) {
        self.isSecondarySourceFilter = false
        super.init(device: device)
    }

    public init(device: any MTLDevice, isSecondarySourceFilter: Bool) {
        self.isSecondarySourceFilter = isSecondarySourceFilter
        super.init(device: device)
    }
}

open class MPSNNBinaryGradientStateNode: MPSNNGradientStateNode {}

open class MPSNNArithmeticGradientNode: MPSNNGradientFilterNode {
    public var bias: Float = 0
    public private(set) var isSecondarySourceFilter: Bool
    public var maximumValue: Float = .greatestFiniteMagnitude
    public var minimumValue: Float = -.greatestFiniteMagnitude
    public var primaryScale: Float = 1
    public var secondaryScale: Float = 1
    public var secondaryStrideInFeatureChannels: Int = 1
    public var secondaryStrideInPixelsX: Int = 1
    public var secondaryStrideInPixelsY: Int = 1

    public init(
        gradientImages: [MPSNNImageNode],
        forwardFilter filter: MPSNNFilterNode,
        isSecondarySourceFilter: Bool
    ) {
        _ = (gradientImages, filter)
        self.isSecondarySourceFilter = isSecondarySourceFilter
        super.init()
    }

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNBinaryGradientStateNode,
        isSecondarySourceFilter: Bool
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.isSecondarySourceFilter = isSecondarySourceFilter
        super.init()
    }
}

open class MPSCNNDropoutGradientState: MPSState {
    private let mask: Data

    public init(device: any MTLDevice, mask: Data) {
        self.mask = mask
        super.init(device: device, bufferSize: mask.count)
    }

    open func maskData() -> Data { mask }
}

open class MPSCNNDropout: MPSCNNKernel {
    public private(set) var keepProbability: Float
    public private(set) var seed: Int
    public private(set) var maskStrideInPixels: MTLSize

    public required init(device: any MTLDevice) {
        self.keepProbability = 0.5
        self.seed = 0
        self.maskStrideInPixels = MTLSize(width: 1, height: 1, depth: 1)
        super.init(device: device)
    }

    public init(device: any MTLDevice, keepProbability: Float, seed: Int, maskStrideInPixels: MTLSize) {
        self.keepProbability = min(max(keepProbability, 0), 1)
        self.seed = seed
        self.maskStrideInPixels = maskStrideInPixels
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNDropoutGradientState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNDropoutGradientState(device: device, mask: Data())
    }

    open override func resultStateBatch(
        sourceImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        sourceImage.enumerated().compactMap { index, image in
            let dest = destinationImage.indices.contains(index) ? destinationImage[index] : image
            return resultState(
                sourceImage: image,
                sourceStates: sourceStates?.indices.contains(index) == true ? sourceStates?[index] : nil,
                destinationImage: dest
            )
        }
    }

    open override func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNDropoutGradientState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }

    open override func temporaryResultStateBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = commandBuffer
        return resultStateBatch(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }
}

open class MPSCNNDropoutGradient: MPSCNNGradientKernel {
    public private(set) var keepProbability: Float
    public private(set) var seed: Int
    public private(set) var maskStrideInPixels: MTLSize

    public required init(device: any MTLDevice) {
        self.keepProbability = 0.5
        self.seed = 0
        self.maskStrideInPixels = MTLSize(width: 1, height: 1, depth: 1)
        super.init(device: device)
    }

    public init(device: any MTLDevice, keepProbability: Float, seed: Int, maskStrideInPixels: MTLSize) {
        self.keepProbability = min(max(keepProbability, 0), 1)
        self.seed = seed
        self.maskStrideInPixels = maskStrideInPixels
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNDropoutGradientNode: MPSNNGradientFilterNode {
    public private(set) var keepProbability: Float
    public private(set) var seed: Int
    public private(set) var maskStrideInPixels: MTLSize

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode,
        keepProbability: Float,
        seed: Int,
        maskStrideInPixels: MTLSize
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.keepProbability = keepProbability
        self.seed = seed
        self.maskStrideInPixels = maskStrideInPixels
        super.init()
    }
}

open class MPSCNNDropoutNode: MPSNNFilterNode {
    public private(set) var keepProbability: Float
    public private(set) var seed: Int
    public private(set) var maskStrideInPixels: MTLSize

    public convenience init(source: MPSNNImageNode) {
        self.init(source: source, keepProbability: 0.5, seed: 0, maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1))
    }

    public convenience init(source: MPSNNImageNode, keepProbability: Float) {
        self.init(source: source, keepProbability: keepProbability, seed: 0, maskStrideInPixels: MTLSize(width: 1, height: 1, depth: 1))
    }

    public init(source: MPSNNImageNode, keepProbability: Float, seed: Int, maskStrideInPixels: MTLSize) {
        _ = source
        self.keepProbability = keepProbability
        self.seed = seed
        self.maskStrideInPixels = maskStrideInPixels
        super.init()
    }
}

public protocol MPSCNNInstanceNormalizationDataSource: NSObjectProtocol, NSCopying {
    var numberOfFeatureChannels: Int { get }
    func gamma() -> UnsafeMutablePointer<Float>?
    func beta() -> UnsafeMutablePointer<Float>?
    func label() -> String?
    init?(coder aDecoder: NSCoder)
}

extension MPSCNNInstanceNormalizationDataSource {
    public static var supportsSecureCoding: Bool { false }

    public func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        _ = (zone, device)
        return self
    }

    public func encode(with aCoder: NSCoder) {
        _ = aCoder
    }

    public func epsilon() -> Float { 1e-5 }

    public func load() -> Bool { true }

    public func purge() {}

    public func updateGammaAndBeta(withInstanceNormalizationStateBatch instanceNormalizationStateBatch: [MPSCNNInstanceNormalizationGradientState]) -> Bool {
        _ = instanceNormalizationStateBatch
        return false
    }

    public func updateGammaAndBeta(
        with commandBuffer: any MTLCommandBuffer,
        instanceNormalizationStateBatch: [MPSCNNInstanceNormalizationGradientState]
    ) -> MPSCNNNormalizationGammaAndBetaState? {
        _ = (commandBuffer, instanceNormalizationStateBatch)
        return nil
    }
}

open class MPSCNNInstanceNormalizationGradientState: MPSState {
    public private(set) var instanceNormalization: MPSCNNInstanceNormalization
    public private(set) var gamma: (any MTLBuffer)?
    public private(set) var beta: (any MTLBuffer)?
    public private(set) var gradientForGamma: any MTLBuffer
    public private(set) var gradientForBeta: any MTLBuffer

    public init(instanceNormalization: MPSCNNInstanceNormalization) {
        self.instanceNormalization = instanceNormalization
        let bytes = max(instanceNormalization.dataSource.numberOfFeatureChannels, 1) * 4
        let device = instanceNormalization.device
        let host = device as? MPSHostDevice
        func buffer() -> any MTLBuffer {
            host?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        }
        self.gamma = instanceNormalization.dataSource.gamma().map { _ in buffer() }
        self.beta = instanceNormalization.dataSource.beta().map { _ in buffer() }
        self.gradientForGamma = buffer()
        self.gradientForBeta = buffer()
        super.init(resources: [gradientForGamma, gradientForBeta])
    }
}

open class MPSCNNInstanceNormalization: MPSCNNKernel {
    public private(set) var dataSource: any MPSCNNInstanceNormalizationDataSource
    public var epsilon: Float

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostInstanceNormalizationDataSource.placeholder
        self.epsilon = 1e-5
        super.init(device: device)
    }

    public init(device: any MTLDevice, dataSource: any MPSCNNInstanceNormalizationDataSource) {
        _ = dataSource.load()
        self.dataSource = dataSource
        self.epsilon = dataSource.epsilon()
        super.init(device: device)
        dataSource.purge()
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func reloadDataSource(_ dataSource: any MPSCNNInstanceNormalizationDataSource) {
        self.dataSource = dataSource
        _ = dataSource.load()
        epsilon = dataSource.epsilon()
        dataSource.purge()
    }

    open func reloadGammaAndBetaFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadGammaAndBeta(with commandBuffer: any MTLCommandBuffer, gammaAndBetaState: MPSCNNNormalizationGammaAndBetaState) {
        _ = (commandBuffer, gammaAndBetaState)
        MPSHostBoundary.refuseGPUEncode("MPSCNNInstanceNormalization.reloadGammaAndBeta")
    }

    open override func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNInstanceNormalizationGradientState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNInstanceNormalizationGradientState(instanceNormalization: self)
    }

    open override func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNInstanceNormalizationGradientState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }
}

final class MPSCNNHostInstanceNormalizationDataSource: NSObject, MPSCNNInstanceNormalizationDataSource {
    static let placeholder = MPSCNNHostInstanceNormalizationDataSource(channels: 1)
    let numberOfFeatureChannels: Int
    private var gammaStorage: UnsafeMutablePointer<Float>
    private var betaStorage: UnsafeMutablePointer<Float>

    init(channels: Int) {
        self.numberOfFeatureChannels = max(channels, 1)
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: numberOfFeatureChannels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: numberOfFeatureChannels)
        for index in 0..<numberOfFeatureChannels {
            gammaStorage[index] = 1
            betaStorage[index] = 0
        }
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSCNNHostInstanceNormalizationDataSource(channels: numberOfFeatureChannels)
    }

    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "instance-norm" }
}

public protocol MPSCNNGroupNormalizationDataSource: NSObjectProtocol, NSCopying {
    var numberOfFeatureChannels: Int { get }
    var numberOfGroups: Int { get set }
    func gamma() -> UnsafeMutablePointer<Float>?
    func beta() -> UnsafeMutablePointer<Float>?
    func label() -> String?
    init?(coder aDecoder: NSCoder)
}

extension MPSCNNGroupNormalizationDataSource {
    public static var supportsSecureCoding: Bool { false }

    public func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        _ = (zone, device)
        return self
    }

    public func encode(with aCoder: NSCoder) {
        _ = aCoder
    }

    public func epsilon() -> Float { 1e-5 }

    public func updateGammaAndBeta(withGroupNormalizationStateBatch groupNormalizationStateBatch: [MPSCNNGroupNormalizationGradientState]) -> Bool {
        _ = groupNormalizationStateBatch
        return false
    }

    public func updateGammaAndBeta(
        with commandBuffer: any MTLCommandBuffer,
        groupNormalizationStateBatch: [MPSCNNGroupNormalizationGradientState]
    ) -> MPSCNNNormalizationGammaAndBetaState? {
        _ = (commandBuffer, groupNormalizationStateBatch)
        return nil
    }
}

open class MPSCNNGroupNormalizationGradientState: MPSState {
    public private(set) var groupNormalization: MPSCNNGroupNormalization
    public private(set) var gamma: (any MTLBuffer)?
    public private(set) var beta: (any MTLBuffer)?
    public private(set) var gradientForGamma: any MTLBuffer
    public private(set) var gradientForBeta: any MTLBuffer

    public init(groupNormalization: MPSCNNGroupNormalization) {
        self.groupNormalization = groupNormalization
        let bytes = max(groupNormalization.dataSource.numberOfFeatureChannels, 1) * 4
        let device = groupNormalization.device
        let host = device as? MPSHostDevice
        func buffer() -> any MTLBuffer {
            host?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        }
        self.gamma = groupNormalization.dataSource.gamma().map { _ in buffer() }
        self.beta = groupNormalization.dataSource.beta().map { _ in buffer() }
        self.gradientForGamma = buffer()
        self.gradientForBeta = buffer()
        super.init(resources: [gradientForGamma, gradientForBeta])
    }
}

open class MPSCNNGroupNormalization: MPSCNNKernel {
    public private(set) var dataSource: any MPSCNNGroupNormalizationDataSource
    public var epsilon: Float

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostGroupNormalizationDataSource.placeholder
        self.epsilon = 1e-5
        super.init(device: device)
    }

    public init(device: any MTLDevice, dataSource: any MPSCNNGroupNormalizationDataSource) {
        self.dataSource = dataSource
        self.epsilon = dataSource.epsilon()
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func reloadGammaAndBetaFromDataSource() {}

    open func reloadGammaAndBeta(with commandBuffer: any MTLCommandBuffer, gammaAndBetaState: MPSCNNNormalizationGammaAndBetaState) {
        _ = (commandBuffer, gammaAndBetaState)
        MPSHostBoundary.refuseGPUEncode("MPSCNNGroupNormalization.reloadGammaAndBeta")
    }

    open override func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNGroupNormalizationGradientState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNGroupNormalizationGradientState(groupNormalization: self)
    }

    open override func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNGroupNormalizationGradientState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }
}

final class MPSCNNHostGroupNormalizationDataSource: NSObject, MPSCNNGroupNormalizationDataSource {
    static let placeholder = MPSCNNHostGroupNormalizationDataSource(channels: 1, groups: 1)
    let numberOfFeatureChannels: Int
    var numberOfGroups: Int
    private var gammaStorage: UnsafeMutablePointer<Float>
    private var betaStorage: UnsafeMutablePointer<Float>

    init(channels: Int, groups: Int) {
        self.numberOfFeatureChannels = max(channels, 1)
        self.numberOfGroups = max(groups, 1)
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: numberOfFeatureChannels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: numberOfFeatureChannels)
        for index in 0..<numberOfFeatureChannels {
            gammaStorage[index] = 1
            betaStorage[index] = 0
        }
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    deinit {
        gammaStorage.deallocate()
        betaStorage.deallocate()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPSCNNHostGroupNormalizationDataSource(channels: numberOfFeatureChannels, groups: numberOfGroups)
    }

    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func label() -> String? { "group-norm" }
}

open class MPSCNNLocalContrastNormalization: MPSCNNKernel {
    public var alpha: Float = 0
    public var beta: Float = 0.5
    public var delta: Float = 1
    public var p0: Float = 1
    public var pm: Float = 1
    public var ps: Float = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
        kernelWidth = 1
        kernelHeight = 1
    }

    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device)
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNLocalContrastNormalizationGradient: MPSCNNGradientKernel {
    public var alpha: Float = 0
    public var beta: Float = 0.5
    public var delta: Float = 1
    public var p0: Float = 1
    public var pm: Float = 1
    public var ps: Float = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
        kernelWidth = 1
        kernelHeight = 1
    }

    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device)
        self.kernelWidth = max(kernelWidth, 1)
        self.kernelHeight = max(kernelHeight, 1)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNLocalContrastNormalizationGradientNode: MPSNNGradientFilterNode {
    public var alpha: Float = 0
    public var beta: Float = 0.5
    public var delta: Float = 1
    public private(set) var kernelHeight: Int
    public private(set) var kernelWidth: Int
    public var p0: Float = 1
    public var pm: Float = 1
    public var ps: Float = 1

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode,
        kernelWidth: Int,
        kernelHeight: Int
    ) {
        _ = (sourceGradient, sourceImage, gradientState)
        self.kernelWidth = kernelWidth
        self.kernelHeight = kernelHeight
        super.init()
    }
}

open class MPSCNNLocalContrastNormalizationNode: MPSNNFilterNode {
    public var alpha: Float = 0
    public var beta: Float = 0.5
    public var delta: Float = 1
    public var p0: Float = 1
    public var pm: Float = 1
    public var ps: Float = 1
    public var kernelWidth: Int
    public var kernelHeight: Int

    public init(source sourceNode: MPSNNImageNode) {
        _ = sourceNode
        self.kernelWidth = 1
        self.kernelHeight = 1
        super.init()
    }

    public init(source sourceNode: MPSNNImageNode, kernelSize: Int) {
        _ = sourceNode
        self.kernelWidth = kernelSize
        self.kernelHeight = kernelSize
        super.init()
    }
}

open class MPSCNNCrossChannelNormalization: MPSCNNKernel {
    public var alpha: Float = 1
    public var beta: Float = 0.5
    public var delta: Float = 1
    public private(set) var kernelSize: Int

    public required init(device: any MTLDevice) {
        self.kernelSize = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelSize: Int) {
        self.kernelSize = max(kernelSize, 1)
        super.init(device: device)
        self.kernelWidth = self.kernelSize
        self.kernelHeight = 1
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNCrossChannelNormalizationGradient: MPSCNNGradientKernel {
    public var alpha: Float = 1
    public var beta: Float = 0.5
    public var delta: Float = 1
    public private(set) var kernelSize: Int

    public required init(device: any MTLDevice) {
        self.kernelSize = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelSize: Int) {
        self.kernelSize = max(kernelSize, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSRNNRecurrentImageState: MPSState {
    private var recurrent: [MPSImage?]
    private var memory: [MPSImage?]

    public init(recurrent: [MPSImage?], memory: [MPSImage?]) {
        self.recurrent = recurrent
        self.memory = memory
        super.init(resource: nil)
    }

    public override init(resource: (any MTLResource)?) {
        self.recurrent = []
        self.memory = []
        super.init(resource: resource)
    }

    open func getRecurrentOutputImage(forLayerIndex layerIndex: Int) -> MPSImage? {
        recurrent.indices.contains(layerIndex) ? recurrent[layerIndex] : nil
    }

    open func getMemoryCellImage(forLayerIndex layerIndex: Int) -> MPSImage? {
        memory.indices.contains(layerIndex) ? memory[layerIndex] : nil
    }
}

open class MPSRNNMatrixInferenceLayer: MPSKernel {
    public var bidirectionalCombineMode: MPSRNNBidirectionalCombineMode = .none
    public private(set) var inputFeatureChannels: Int
    public private(set) var numberOfLayers: Int
    public private(set) var outputFeatureChannels: Int
    public var recurrentOutputIsTemporary: Bool = false
    public var storeAllIntermediateStates: Bool = false
    private let descriptors: [MPSRNNDescriptor]

    public required init(device: any MTLDevice) {
        self.descriptors = [MPSRNNDescriptor()]
        self.inputFeatureChannels = 1
        self.outputFeatureChannels = 1
        self.numberOfLayers = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, rnnDescriptor: MPSRNNDescriptor) {
        self.descriptors = [rnnDescriptor]
        self.inputFeatureChannels = rnnDescriptor.inputFeatureChannels
        self.outputFeatureChannels = rnnDescriptor.outputFeatureChannels
        self.numberOfLayers = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, rnnDescriptors: [MPSRNNDescriptor]) {
        self.descriptors = rnnDescriptors
        self.inputFeatureChannels = rnnDescriptors.first?.inputFeatureChannels ?? 1
        self.outputFeatureChannels = rnnDescriptors.last?.outputFeatureChannels ?? 1
        self.numberOfLayers = max(rnnDescriptors.count, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSRNNMatrixInferenceLayer(device: device ?? self.device, rnnDescriptors: descriptors)
        copied.options = options
        copied.label = label
        copied.bidirectionalCombineMode = bidirectionalCombineMode
        copied.recurrentOutputIsTemporary = recurrentOutputIsTemporary
        copied.storeAllIntermediateStates = storeAllIntermediateStates
        return copied as! Self
    }

    open func encodeSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrices: [MPSMatrix],
        destinationMatrices: [MPSMatrix],
        recurrentInputState: MPSRNNRecurrentMatrixState?,
        recurrentOutputStates: NSMutableArray?
    ) {
        _ = (commandBuffer, sourceMatrices, destinationMatrices, recurrentInputState, recurrentOutputStates)
        MPSHostBoundary.refuseGPUEncode("MPSRNNMatrixInferenceLayer.encodeSequence")
    }

    open func encodeSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrices: [MPSMatrix],
        sourceOffsets: UnsafeMutablePointer<Int>?,
        destinationMatrices: [MPSMatrix],
        destinationOffsets: UnsafeMutablePointer<Int>?,
        recurrentInputState: MPSRNNRecurrentMatrixState?,
        recurrentOutputStates: NSMutableArray?
    ) {
        _ = (sourceOffsets, destinationOffsets)
        encodeSequence(
            commandBuffer: commandBuffer,
            sourceMatrices: sourceMatrices,
            destinationMatrices: destinationMatrices,
            recurrentInputState: recurrentInputState,
            recurrentOutputStates: recurrentOutputStates
        )
    }

    open func encodeBidirectionalSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceSequence: [MPSMatrix],
        destinationForwardMatrices: [MPSMatrix],
        destinationBackwardMatrices: [MPSMatrix]?
    ) {
        _ = (commandBuffer, sourceSequence, destinationForwardMatrices, destinationBackwardMatrices)
        MPSHostBoundary.refuseGPUEncode("MPSRNNMatrixInferenceLayer.encodeBidirectionalSequence")
    }
}

open class MPSRNNImageInferenceLayer: MPSKernel {
    public var bidirectionalCombineMode: MPSRNNBidirectionalCombineMode = .none
    public private(set) var inputFeatureChannels: Int
    public private(set) var numberOfLayers: Int
    public private(set) var outputFeatureChannels: Int
    public var recurrentOutputIsTemporary: Bool = false
    public var storeAllIntermediateStates: Bool = false
    private let descriptors: [MPSRNNDescriptor]

    public required init(device: any MTLDevice) {
        self.descriptors = [MPSRNNDescriptor()]
        self.inputFeatureChannels = 1
        self.outputFeatureChannels = 1
        self.numberOfLayers = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, rnnDescriptor: MPSRNNDescriptor) {
        self.descriptors = [rnnDescriptor]
        self.inputFeatureChannels = rnnDescriptor.inputFeatureChannels
        self.outputFeatureChannels = rnnDescriptor.outputFeatureChannels
        self.numberOfLayers = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, rnnDescriptors: [MPSRNNDescriptor]) {
        self.descriptors = rnnDescriptors
        self.inputFeatureChannels = rnnDescriptors.first?.inputFeatureChannels ?? 1
        self.outputFeatureChannels = rnnDescriptors.last?.outputFeatureChannels ?? 1
        self.numberOfLayers = max(rnnDescriptors.count, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSRNNImageInferenceLayer(device: device ?? self.device, rnnDescriptors: descriptors)
        copied.options = options
        copied.label = label
        copied.bidirectionalCombineMode = bidirectionalCombineMode
        copied.recurrentOutputIsTemporary = recurrentOutputIsTemporary
        copied.storeAllIntermediateStates = storeAllIntermediateStates
        return copied as! Self
    }

    open func encodeSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationImages: [MPSImage],
        recurrentInputState: MPSRNNRecurrentImageState?,
        recurrentOutputStates: NSMutableArray?
    ) {
        _ = (commandBuffer, sourceImages, destinationImages, recurrentInputState, recurrentOutputStates)
        MPSHostBoundary.refuseGPUEncode("MPSRNNImageInferenceLayer.encodeSequence")
    }

    open func encodeBidirectionalSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceSequence: [MPSImage],
        destinationForwardImages: [MPSImage],
        destinationBackwardImages: [MPSImage]?
    ) {
        _ = (commandBuffer, sourceSequence, destinationForwardImages, destinationBackwardImages)
        MPSHostBoundary.refuseGPUEncode("MPSRNNImageInferenceLayer.encodeBidirectionalSequence")
    }
}

open class MPSImageEDLines: MPSKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip
    public var detailRatio: UInt16
    public private(set) var gaussianSigma: Float
    public var gradientThreshold: Float
    public var lineErrorThreshold: Float
    public var maxLines: Int
    public var mergeLocalityThreshold: Float
    public var minLineLength: UInt16

    public required init(device: any MTLDevice) {
        self.detailRatio = 1
        self.gaussianSigma = 1
        self.gradientThreshold = 0.1
        self.lineErrorThreshold = 1
        self.maxLines = 0
        self.mergeLocalityThreshold = 0
        self.minLineLength = 1
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        gaussianSigma: Float,
        minLineLength: UInt16,
        maxLines: Int,
        detailRatio: UInt16,
        gradientThreshold: Float,
        lineErrorThreshold: Float,
        mergeLocalityThreshold: Float
    ) {
        self.gaussianSigma = gaussianSigma
        self.minLineLength = minLineLength
        self.maxLines = maxLines
        self.detailRatio = detailRatio
        self.gradientThreshold = gradientThreshold
        self.lineErrorThreshold = lineErrorThreshold
        self.mergeLocalityThreshold = mergeLocalityThreshold
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture source: any MTLTexture,
        destinationTexture dest: (any MTLTexture)?,
        endpointBuffer: any MTLBuffer,
        endpointOffset: Int
    ) {
        _ = (commandBuffer, source, dest, endpointBuffer, endpointOffset)
        MPSHostBoundary.refuseGPUEncode("MPSImageEDLines.encode")
    }
}

open class MPSImageGuidedFilter: MPSKernel {
    public var epsilon: Float = 1e-4
    public private(set) var kernelDiameter: Int
    public var reconstructOffset: Float = 0
    public var reconstructScale: Float = 1

    public required init(device: any MTLDevice) {
        self.kernelDiameter = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, kernelDiameter: Int) {
        self.kernelDiameter = max(kernelDiameter, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeReconstruction(
        to commandBuffer: any MTLCommandBuffer,
        guidanceTexture: any MTLTexture,
        coefficientsTexture: any MTLTexture,
        destinationTexture: any MTLTexture
    ) {
        _ = (commandBuffer, guidanceTexture, coefficientsTexture, destinationTexture)
        MPSHostBoundary.refuseGPUEncode("MPSImageGuidedFilter.encodeReconstruction")
    }

    open func encodeReconstruction(
        commandBuffer: any MTLCommandBuffer,
        guidance guidanceTexture: any MTLTexture,
        coefficientsTextureA: any MTLTexture,
        coefficientsTextureB: any MTLTexture,
        destination destinationTexture: any MTLTexture
    ) {
        _ = (coefficientsTextureA, coefficientsTextureB)
        encodeReconstruction(
            to: commandBuffer,
            guidanceTexture: guidanceTexture,
            coefficientsTexture: coefficientsTextureA,
            destinationTexture: destinationTexture
        )
    }

    open func encodeRegression(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        guidanceTexture: any MTLTexture,
        weightsTexture: (any MTLTexture)?,
        destinationCoefficientsTexture: any MTLTexture
    ) {
        _ = (commandBuffer, sourceTexture, guidanceTexture, weightsTexture, destinationCoefficientsTexture)
        MPSHostBoundary.refuseGPUEncode("MPSImageGuidedFilter.encodeRegression")
    }

    open func encodeRegression(
        commandBuffer: any MTLCommandBuffer,
        source sourceTexture: any MTLTexture,
        guidance guidanceTexture: any MTLTexture,
        weights weightsTexture: (any MTLTexture)?,
        destinationCoefficientsTextureA: any MTLTexture,
        destinationCoefficientsTextureB: any MTLTexture
    ) {
        _ = destinationCoefficientsTextureB
        encodeRegression(
            to: commandBuffer,
            sourceTexture: sourceTexture,
            guidanceTexture: guidanceTexture,
            weightsTexture: weightsTexture,
            destinationCoefficientsTexture: destinationCoefficientsTextureA
        )
    }
}

open class MPSImageNormalizedHistogram: MPSKernel {
    public var clipRectSource: MTLRegion = MPSRectNoClip
    public var zeroHistogram: Bool = true
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
        minmaxTexture: any MTLTexture,
        histogram: any MTLBuffer,
        histogramOffset: Int
    ) {
        _ = (commandBuffer, source, minmaxTexture, histogram, histogramOffset)
        MPSHostBoundary.refuseGPUEncode("MPSImageNormalizedHistogram.encode")
    }
}

public protocol MPSSVGFTextureAllocator: NSObjectProtocol {
    func texture(with pixelFormat: MTLPixelFormat, width: Int, height: Int) -> (any MTLTexture)?
    func `return`(_ texture: any MTLTexture)
}

open class MPSSVGFDefaultTextureAllocator: NSObject, MPSSVGFTextureAllocator {
    public private(set) var device: any MTLDevice
    public private(set) var allocatedTextureCount: Int = 0
    private var pool: [any MTLTexture] = []

    public init(device: any MTLDevice) {
        self.device = device
        super.init()
    }

    open func texture(with pixelFormat: MTLPixelFormat, width: Int, height: Int) -> (any MTLTexture)? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        let texture: any MTLTexture
        if let host = device as? MPSHostDevice {
            texture = host.makeTexture(descriptor: descriptor)
        } else {
            texture = MPSHostTexture(device: device, descriptor: descriptor)
        }
        allocatedTextureCount += 1
        pool.append(texture)
        return texture
    }

    open func `return`(_ texture: any MTLTexture) {
        _ = texture
        allocatedTextureCount = max(allocatedTextureCount - 1, 0)
    }

    open func reset() {
        pool.removeAll()
        allocatedTextureCount = 0
    }
}

open class MPSSVGFDenoiser: NSObject {
    public private(set) var svgf: MPSSVGF
    public private(set) var textureAllocator: any MPSSVGFTextureAllocator
    public var bilateralFilterIterations: Int = 3
    private var historyCleared = true

    public init(device: any MTLDevice) {
        self.svgf = MPSSVGF(device: device)
        self.textureAllocator = MPSSVGFDefaultTextureAllocator(device: device)
        super.init()
    }

    public init(SVGF svgf: MPSSVGF, textureAllocator: any MPSSVGFTextureAllocator) {
        self.svgf = svgf
        self.textureAllocator = textureAllocator
        super.init()
    }

    open func clearTemporalHistory() {
        historyCleared = true
    }

    open func releaseTemporaryTextures() {
        if let allocator = textureAllocator as? MPSSVGFDefaultTextureAllocator {
            allocator.reset()
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        motionVectorTexture: (any MTLTexture)?,
        depthNormalTexture: any MTLTexture,
        previousDepthNormalTexture: (any MTLTexture)?
    ) -> any MTLTexture {
        _ = (commandBuffer, motionVectorTexture, depthNormalTexture, previousDepthNormalTexture, historyCleared)
        MPSHostBoundary.refuseGPUEncode("MPSSVGFDenoiser.encode")
        return textureAllocator.texture(
            with: sourceTexture.pixelFormat,
            width: sourceTexture.width,
            height: sourceTexture.height
        ) ?? sourceTexture
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        destinationTexture: AutoreleasingUnsafeMutablePointer<any MTLTexture>,
        sourceTexture2: (any MTLTexture)?,
        destinationTexture2: AutoreleasingUnsafeMutablePointer<any MTLTexture>?,
        motionVectorTexture: (any MTLTexture)?,
        depthNormalTexture: any MTLTexture,
        previousDepthNormalTexture: (any MTLTexture)?
    ) {
        _ = (sourceTexture2, motionVectorTexture, previousDepthNormalTexture)
        let dest = encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceTexture,
            motionVectorTexture: motionVectorTexture,
            depthNormalTexture: depthNormalTexture,
            previousDepthNormalTexture: previousDepthNormalTexture
        )
        destinationTexture.pointee = dest
        if let destinationTexture2 {
            destinationTexture2.pointee = dest
        }
    }
}

open class MPSNNPad: MPSCNNKernel {
    public var fillValue: Float = 0
    public var paddingSizeAfter: MPSImageCoordinate
    public var paddingSizeBefore: MPSImageCoordinate

    public required convenience init(device: any MTLDevice) {
        self.init(
            device: device,
            paddingSizeBefore: MPSImageCoordinate(),
            paddingSizeAfter: MPSImageCoordinate(),
            fillValueArray: nil
        )
    }

    public convenience init(
        device: any MTLDevice,
        paddingSizeBefore: MPSImageCoordinate,
        paddingSizeAfter: MPSImageCoordinate
    ) {
        self.init(
            device: device,
            paddingSizeBefore: paddingSizeBefore,
            paddingSizeAfter: paddingSizeAfter,
            fillValueArray: nil
        )
    }

    public init(
        device: any MTLDevice,
        paddingSizeBefore: MPSImageCoordinate,
        paddingSizeAfter: MPSImageCoordinate,
        fillValueArray: Data?
    ) {
        self.paddingSizeBefore = paddingSizeBefore
        self.paddingSizeAfter = paddingSizeAfter
        if let fillValueArray, fillValueArray.count >= 4 {
            self.fillValue = fillValueArray.withUnsafeBytes { $0.load(as: Float.self) }
        }
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSNNLocalCorrelation: MPSCNNBinaryKernel {
    public var strideInX: Int
    public var strideInY: Int
    public var windowInX: Int
    public var windowInY: Int

    public required init(device: any MTLDevice) {
        self.strideInX = 1
        self.strideInY = 1
        self.windowInX = 1
        self.windowInY = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, windowInX: Int, windowInY: Int, strideInX: Int, strideInY: Int) {
        self.windowInX = max(windowInX, 0)
        self.windowInY = max(windowInY, 0)
        self.strideInX = max(strideInX, 1)
        self.strideInY = max(strideInY, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

open class MPSCNNNeuronGradient: MPSCNNGradientKernel {
    public private(set) var neuronType: MPSCNNNeuronType
    public private(set) var a: Float
    public private(set) var b: Float
    public private(set) var c: Float

    public var data: Data?

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

open class MPSCNNPoolingNode: MPSNNFilterNode {
    public private(set) var kernelWidth: Int
    public private(set) var kernelHeight: Int
    public private(set) var strideInPixelsX: Int
    public private(set) var strideInPixelsY: Int

    public init(
        source sourceNode: MPSNNImageNode,
        kernelWidth: Int,
        kernelHeight: Int,
        strideInPixelsX: Int,
        strideInPixelsY: Int
    ) {
        _ = sourceNode
        self.kernelWidth = kernelWidth
        self.kernelHeight = kernelHeight
        self.strideInPixelsX = strideInPixelsX
        self.strideInPixelsY = strideInPixelsY
        super.init()
    }

    public convenience init(source sourceNode: MPSNNImageNode, filterSize size: Int) {
        self.init(source: sourceNode, kernelWidth: size, kernelHeight: size, strideInPixelsX: size, strideInPixelsY: size)
    }

    public convenience init(source sourceNode: MPSNNImageNode, filterSize size: Int, stride: Int) {
        self.init(source: sourceNode, kernelWidth: size, kernelHeight: size, strideInPixelsX: stride, strideInPixelsY: stride)
    }
}
