import Foundation

public protocol MPSNNLossCallback: NSObjectProtocol, NSCopying, NSSecureCoding {
    func scalarWeight(forSourceImage sourceImage: MPSImage, destinationImage: MPSImage) -> Float
}

open class MPSCNNLossDescriptor: NSObject {
    public var lossType: MPSCNNLossType
    public var reductionType: MPSCNNReductionType
    public var weight: Float = 1
    public var labelSmoothing: Float = 0
    public var numberOfClasses: Int = 1
    public var epsilon: Float = 1e-7
    public var delta: Float = 1
    public var reduceAcrossBatch: Bool = false

    public init(type lossType: MPSCNNLossType, reductionType: MPSCNNReductionType) {
        self.lossType = lossType
        self.reductionType = reductionType
        super.init()
    }
}

open class MPSCNNLossDataDescriptor: NSObject {
    public private(set) var layout: MPSDataLayout
    public private(set) var size: MTLSize
    public var bytesPerRow: Int
    public var bytesPerImage: Int
    public let data: Data

    public init?(data: Data, layout: MPSDataLayout, size: MTLSize) {
        guard size.width > 0, size.height > 0 else { return nil }
        self.data = data
        self.layout = layout
        self.size = size
        self.bytesPerRow = max(size.width, 1)
        self.bytesPerImage = max(size.width * size.height, 1)
        super.init()
    }
}

open class MPSCNNLossLabels: MPSState {
    private let storedLabels: MPSImage
    private let storedWeights: MPSImage
    private let storedLoss: MPSImage

    public convenience init(device: any MTLDevice, labelsDescriptor: MPSCNNLossDataDescriptor) {
        self.init(device: device, lossImageSize: labelsDescriptor.size, labelsDescriptor: labelsDescriptor, weightsDescriptor: nil)
    }

    public init(
        device: any MTLDevice,
        lossImageSize: MTLSize,
        labelsDescriptor: MPSCNNLossDataDescriptor,
        weightsDescriptor: MPSCNNLossDataDescriptor?
    ) {
        let labels = MPSImage(
            device: device,
            imageDescriptor: MPSImageDescriptor(
                channelFormat: .float32,
                width: max(labelsDescriptor.size.width, 1),
                height: max(labelsDescriptor.size.height, 1),
                featureChannels: max(labelsDescriptor.size.depth, 1)
            )
        )
        let weights: MPSImage
        if let weightsDescriptor {
            weights = MPSImage(
                device: device,
                imageDescriptor: MPSImageDescriptor(
                    channelFormat: .float32,
                    width: max(weightsDescriptor.size.width, 1),
                    height: max(weightsDescriptor.size.height, 1),
                    featureChannels: max(weightsDescriptor.size.depth, 1)
                )
            )
        } else {
            weights = MPSImage(
                device: device,
                imageDescriptor: MPSImageDescriptor(
                    channelFormat: .float32,
                    width: 1,
                    height: 1,
                    featureChannels: 1
                )
            )
        }
        let loss = MPSImage(
            device: device,
            imageDescriptor: MPSImageDescriptor(
                channelFormat: .float32,
                width: max(lossImageSize.width, 1),
                height: max(lossImageSize.height, 1),
                featureChannels: max(lossImageSize.depth, 1)
            )
        )
        self.storedLabels = labels
        self.storedWeights = weights
        self.storedLoss = loss
        super.init(resources: [labels, weights, loss].compactMap { $0 as? any MTLResource })
    }

    public init(device: any MTLDevice, lossImageSize: MTLSize, labelsImage: MPSImage, weightsImage: MPSImage?) {
        self.storedLabels = labelsImage
        self.storedWeights = weightsImage ?? MPSImage(
            device: device,
            imageDescriptor: MPSImageDescriptor(channelFormat: .float32, width: 1, height: 1, featureChannels: 1)
        )
        self.storedLoss = MPSImage(
            device: device,
            imageDescriptor: MPSImageDescriptor(
                channelFormat: .float32,
                width: max(lossImageSize.width, 1),
                height: max(lossImageSize.height, 1),
                featureChannels: max(lossImageSize.depth, 1)
            )
        )
        super.init(resource: nil)
        _ = device
    }

    open func labelsImage() -> MPSImage { storedLabels }
    open func weightsImage() -> MPSImage { storedWeights }
    open func lossImage() -> MPSImage { storedLoss }
}

open class MPSCNNLoss: MPSCNNKernel {
    public private(set) var lossType: MPSCNNLossType
    public private(set) var reductionType: MPSCNNReductionType
    public private(set) var weight: Float
    public private(set) var labelSmoothing: Float
    public private(set) var numberOfClasses: Int
    public private(set) var epsilon: Float
    public private(set) var delta: Float
    public private(set) var reduceAcrossBatch: Bool

    public init(device: any MTLDevice, lossDescriptor: MPSCNNLossDescriptor) {
        self.lossType = lossDescriptor.lossType
        self.reductionType = lossDescriptor.reductionType
        self.weight = lossDescriptor.weight
        self.labelSmoothing = lossDescriptor.labelSmoothing
        self.numberOfClasses = lossDescriptor.numberOfClasses
        self.epsilon = lossDescriptor.epsilon
        self.delta = lossDescriptor.delta
        self.reduceAcrossBatch = lossDescriptor.reduceAcrossBatch
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.lossType = .meanAbsoluteError
        self.reductionType = .none
        self.weight = 1
        self.labelSmoothing = 0
        self.numberOfClasses = 1
        self.epsilon = 1e-7
        self.delta = 1
        self.reduceAcrossBatch = false
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        labels: MPSCNNLossLabels,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, sourceImage, labels, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNLoss.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        labels: MPSCNNLossLabels
    ) -> MPSImage {
        let dest = labels.lossImage()
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, labels: labels, destinationImage: dest)
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        labels: [MPSCNNLossLabels],
        destinationImages destinationImage: [MPSImage]
    ) {
        if let source = sourceImage.first, let label = labels.first, let dest = destinationImage.first {
            encode(commandBuffer: commandBuffer, sourceImage: source, labels: label, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNLoss.encodeBatch")
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        labels: [MPSCNNLossLabels]
    ) -> [MPSImage] {
        zip(sourceImage, labels).map {
            encode(commandBuffer: commandBuffer, sourceImage: $0, labels: $1)
        }
    }
}

open class MPSCNNYOLOLossDescriptor: NSObject {
    public var xyLossDescriptor: MPSCNNLossDescriptor
    public var whLossDescriptor: MPSCNNLossDescriptor
    public var confidenceLossDescriptor: MPSCNNLossDescriptor
    public var classesLossDescriptor: MPSCNNLossDescriptor
    public var reductionType: MPSCNNReductionType
    public var anchorBoxes: Data
    public var numberOfAnchorBoxes: Int
    public var rescore: Bool = true
    public var scaleXY: Float = 1
    public var scaleWH: Float = 1
    public var scaleNoObject: Float = 1
    public var scaleObject: Float = 1
    public var scaleClass: Float = 1
    public var minIOUForObjectPresence: Float = 0
    public var maxIOUForObjectAbsence: Float = 1
    public var reduceAcrossBatch: Bool = false

    public class func cnnLossDescriptor(
        withXYLossType XYLossType: MPSCNNLossType,
        whLossType WHLossType: MPSCNNLossType,
        confidenceLossType: MPSCNNLossType,
        classesLossType: MPSCNNLossType,
        reductionType: MPSCNNReductionType,
        anchorBoxes: Data,
        numberOfAnchorBoxes: Int
    ) -> MPSCNNYOLOLossDescriptor {
        MPSCNNYOLOLossDescriptor(
            xy: MPSCNNLossDescriptor(type: XYLossType, reductionType: reductionType),
            wh: MPSCNNLossDescriptor(type: WHLossType, reductionType: reductionType),
            confidence: MPSCNNLossDescriptor(type: confidenceLossType, reductionType: reductionType),
            classes: MPSCNNLossDescriptor(type: classesLossType, reductionType: reductionType),
            reductionType: reductionType,
            anchorBoxes: anchorBoxes,
            numberOfAnchorBoxes: numberOfAnchorBoxes
        )
    }

    public init(
        xy: MPSCNNLossDescriptor,
        wh: MPSCNNLossDescriptor,
        confidence: MPSCNNLossDescriptor,
        classes: MPSCNNLossDescriptor,
        reductionType: MPSCNNReductionType,
        anchorBoxes: Data,
        numberOfAnchorBoxes: Int
    ) {
        self.xyLossDescriptor = xy
        self.whLossDescriptor = wh
        self.confidenceLossDescriptor = confidence
        self.classesLossDescriptor = classes
        self.reductionType = reductionType
        self.anchorBoxes = anchorBoxes
        self.numberOfAnchorBoxes = numberOfAnchorBoxes
        super.init()
    }
}

open class MPSCNNYOLOLoss: MPSCNNKernel {
    public private(set) var lossXY: MPSCNNLoss
    public private(set) var lossWH: MPSCNNLoss
    public private(set) var lossConfidence: MPSCNNLoss
    public private(set) var lossClasses: MPSCNNLoss
    public private(set) var scaleXY: Float
    public private(set) var scaleWH: Float
    public private(set) var scaleNoObject: Float
    public private(set) var scaleObject: Float
    public private(set) var scaleClass: Float
    public private(set) var minIOUForObjectPresence: Float
    public private(set) var maxIOUForObjectAbsence: Float
    public private(set) var reductionType: MPSCNNReductionType
    public private(set) var numberOfAnchorBoxes: Int
    public private(set) var anchorBoxes: Data
    public private(set) var reduceAcrossBatch: Bool

    public init(device: any MTLDevice, lossDescriptor: MPSCNNYOLOLossDescriptor) {
        self.lossXY = MPSCNNLoss(device: device, lossDescriptor: lossDescriptor.xyLossDescriptor)
        self.lossWH = MPSCNNLoss(device: device, lossDescriptor: lossDescriptor.whLossDescriptor)
        self.lossConfidence = MPSCNNLoss(device: device, lossDescriptor: lossDescriptor.confidenceLossDescriptor)
        self.lossClasses = MPSCNNLoss(device: device, lossDescriptor: lossDescriptor.classesLossDescriptor)
        self.scaleXY = lossDescriptor.scaleXY
        self.scaleWH = lossDescriptor.scaleWH
        self.scaleNoObject = lossDescriptor.scaleNoObject
        self.scaleObject = lossDescriptor.scaleObject
        self.scaleClass = lossDescriptor.scaleClass
        self.minIOUForObjectPresence = lossDescriptor.minIOUForObjectPresence
        self.maxIOUForObjectAbsence = lossDescriptor.maxIOUForObjectAbsence
        self.reductionType = lossDescriptor.reductionType
        self.numberOfAnchorBoxes = lossDescriptor.numberOfAnchorBoxes
        self.anchorBoxes = lossDescriptor.anchorBoxes
        self.reduceAcrossBatch = lossDescriptor.reduceAcrossBatch
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        let empty = MPSCNNLossDescriptor(type: .meanAbsoluteError, reductionType: .none)
        self.lossXY = MPSCNNLoss(device: device, lossDescriptor: empty)
        self.lossWH = MPSCNNLoss(device: device, lossDescriptor: empty)
        self.lossConfidence = MPSCNNLoss(device: device, lossDescriptor: empty)
        self.lossClasses = MPSCNNLoss(device: device, lossDescriptor: empty)
        self.scaleXY = 1
        self.scaleWH = 1
        self.scaleNoObject = 1
        self.scaleObject = 1
        self.scaleClass = 1
        self.minIOUForObjectPresence = 0
        self.maxIOUForObjectAbsence = 1
        self.reductionType = .none
        self.numberOfAnchorBoxes = 0
        self.anchorBoxes = Data()
        self.reduceAcrossBatch = false
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        labels: MPSCNNLossLabels,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, sourceImage, labels, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNYOLOLoss.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        labels: MPSCNNLossLabels
    ) -> MPSImage {
        let dest = labels.lossImage()
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, labels: labels, destinationImage: dest)
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        labels: [MPSCNNLossLabels],
        destinationImages destinationImage: [MPSImage]
    ) {
        if let source = sourceImage.first, let label = labels.first, let dest = destinationImage.first {
            encode(commandBuffer: commandBuffer, sourceImage: source, labels: label, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNYOLOLoss.encodeBatch")
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        labels: [MPSCNNLossLabels]
    ) -> [MPSImage] {
        zip(sourceImage, labels).map {
            encode(commandBuffer: commandBuffer, sourceImage: $0, labels: $1)
        }
    }
}

open class MPSNNForwardLoss: MPSCNNKernel {
    public private(set) var lossType: MPSCNNLossType
    public private(set) var reductionType: MPSCNNReductionType
    public var weight: Float
    public var labelSmoothing: Float
    public private(set) var numberOfClasses: Int
    public var epsilon: Float
    public var delta: Float
    public private(set) var reduceAcrossBatch: Bool

    public init(device: any MTLDevice, lossDescriptor: MPSCNNLossDescriptor) {
        self.lossType = lossDescriptor.lossType
        self.reductionType = lossDescriptor.reductionType
        self.weight = lossDescriptor.weight
        self.labelSmoothing = lossDescriptor.labelSmoothing
        self.numberOfClasses = lossDescriptor.numberOfClasses
        self.epsilon = lossDescriptor.epsilon
        self.delta = lossDescriptor.delta
        self.reduceAcrossBatch = lossDescriptor.reduceAcrossBatch
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.lossType = .meanAbsoluteError
        self.reductionType = .none
        self.weight = 1
        self.labelSmoothing = 0
        self.numberOfClasses = 1
        self.epsilon = 1e-7
        self.delta = 1
        self.reduceAcrossBatch = false
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        labels: [MPSImage],
        weights: [MPSImage]?,
        destinationStates: [MPSState]?,
        destinationImages: [MPSImage]
    ) {
        _ = (commandBuffer, sourceImages, labels, weights, destinationStates, destinationImages)
        MPSHostBoundary.refuseGPUEncode("MPSNNForwardLoss.encodeBatch")
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        labels: [MPSImage],
        weights: [MPSImage]?,
        outStates: UnsafeMutablePointer<NSArray?>?,
        isTemporary: Bool
    ) -> [MPSImage] {
        _ = isTemporary
        outStates?.pointee = nil
        MPSHostBoundary.refuseGPUEncode("MPSNNForwardLoss.encodeBatch(outStates:)")
        return sourceImages.map { source in
            destinationImageAllocator.image(
                for: commandBuffer,
                imageDescriptor: destinationImageDescriptor(sourceImages: [source], sourceStates: nil),
                kernel: self
            )
        }
    }
}

open class MPSNNLossGradient: MPSCNNKernel {
    public private(set) var lossType: MPSCNNLossType
    public private(set) var reductionType: MPSCNNReductionType
    public var weight: Float
    public var labelSmoothing: Float
    public private(set) var numberOfClasses: Int
    public var epsilon: Float
    public var delta: Float
    public private(set) var reduceAcrossBatch: Bool
    public var computeLabelGradients: Bool = false

    public init(device: any MTLDevice, lossDescriptor: MPSCNNLossDescriptor) {
        self.lossType = lossDescriptor.lossType
        self.reductionType = lossDescriptor.reductionType
        self.weight = lossDescriptor.weight
        self.labelSmoothing = lossDescriptor.labelSmoothing
        self.numberOfClasses = lossDescriptor.numberOfClasses
        self.epsilon = lossDescriptor.epsilon
        self.delta = lossDescriptor.delta
        self.reduceAcrossBatch = lossDescriptor.reduceAcrossBatch
        super.init(device: device)
        isBackwards = true
    }

    public required init(device: any MTLDevice) {
        self.lossType = .meanAbsoluteError
        self.reductionType = .none
        self.weight = 1
        self.labelSmoothing = 0
        self.numberOfClasses = 1
        self.epsilon = 1e-7
        self.delta = 1
        self.reduceAcrossBatch = false
        super.init(device: device)
        isBackwards = true
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        labels: [MPSImage],
        weights: [MPSImage]?,
        sourceStates: [MPSState]?,
        destinationGradients: [MPSImage]
    ) {
        _ = (commandBuffer, sourceGradients, sourceImages, labels, weights, sourceStates, destinationGradients)
        MPSHostBoundary.refuseGPUEncode("MPSNNLossGradient.encodeBatch")
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        labels: [MPSImage],
        weights: [MPSImage]?,
        sourceStates: [MPSState]?
    ) -> [MPSImage] {
        let dest = sourceImages.map { source in
            destinationImageAllocator.image(
                for: commandBuffer,
                imageDescriptor: destinationImageDescriptor(sourceImages: [source], sourceStates: sourceStates),
                kernel: self
            )
        }
        encodeBatch(
            commandBuffer: commandBuffer,
            sourceGradients: sourceGradients,
            sourceImages: sourceImages,
            labels: labels,
            weights: weights,
            sourceStates: sourceStates,
            destinationGradients: dest
        )
        return dest
    }
}

open class MPSNNLossGradientNode: MPSNNGradientFilterNode {
    public private(set) var lossType: MPSCNNLossType
    public private(set) var reductionType: MPSCNNReductionType
    public private(set) var weight: Float
    public private(set) var labelSmoothing: Float
    public private(set) var numberOfClasses: Int
    public private(set) var epsilon: Float
    public private(set) var delta: Float
    public private(set) var reduceAcrossBatch: Bool
    public private(set) var isLabelsGradientFilter: Bool
    public var propertyCallBack: (any MPSNNLossCallback)?

    public convenience init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        labels: MPSNNImageNode,
        weights: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode?,
        lossDescriptor descriptor: MPSCNNLossDescriptor,
        isLabelsGradientFilter: Bool
    ) {
        self.init(
            sourceGradient: sourceGradient,
            sourceImage: sourceImage,
            labels: labels,
            weights: Optional(weights),
            gradientState: gradientState,
            lossDescriptor: descriptor,
            isLabelsGradientFilter: isLabelsGradientFilter
        )
    }

    public convenience init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        labels: MPSNNImageNode,
        gradientState: MPSNNGradientStateNode?,
        lossDescriptor descriptor: MPSCNNLossDescriptor,
        isLabelsGradientFilter: Bool
    ) {
        self.init(
            sourceGradient: sourceGradient,
            sourceImage: sourceImage,
            labels: labels,
            weights: nil,
            gradientState: gradientState,
            lossDescriptor: descriptor,
            isLabelsGradientFilter: isLabelsGradientFilter
        )
    }

    public init(
        sourceGradient: MPSNNImageNode,
        sourceImage: MPSNNImageNode,
        labels: MPSNNImageNode,
        weights: MPSNNImageNode?,
        gradientState: MPSNNGradientStateNode?,
        lossDescriptor descriptor: MPSCNNLossDescriptor,
        isLabelsGradientFilter: Bool
    ) {
        _ = (sourceGradient, sourceImage, labels, weights, gradientState)
        self.lossType = descriptor.lossType
        self.reductionType = descriptor.reductionType
        self.weight = descriptor.weight
        self.labelSmoothing = descriptor.labelSmoothing
        self.numberOfClasses = descriptor.numberOfClasses
        self.epsilon = descriptor.epsilon
        self.delta = descriptor.delta
        self.reduceAcrossBatch = descriptor.reduceAcrossBatch
        self.isLabelsGradientFilter = isLabelsGradientFilter
        super.init()
    }

    public init(
        sources sourceNodes: [MPSNNImageNode],
        gradientState: MPSNNGradientStateNode?,
        lossDescriptor descriptor: MPSCNNLossDescriptor,
        isLabelsGradientFilter: Bool
    ) {
        _ = (sourceNodes, gradientState)
        self.lossType = descriptor.lossType
        self.reductionType = descriptor.reductionType
        self.weight = descriptor.weight
        self.labelSmoothing = descriptor.labelSmoothing
        self.numberOfClasses = descriptor.numberOfClasses
        self.epsilon = descriptor.epsilon
        self.delta = descriptor.delta
        self.reduceAcrossBatch = descriptor.reduceAcrossBatch
        self.isLabelsGradientFilter = isLabelsGradientFilter
        super.init()
    }
}

open class MPSNNForwardLossNode: MPSNNFilterNode {
    public private(set) var lossType: MPSCNNLossType
    public private(set) var reductionType: MPSCNNReductionType
    public private(set) var weight: Float
    public private(set) var labelSmoothing: Float
    public private(set) var numberOfClasses: Int
    public private(set) var epsilon: Float
    public private(set) var delta: Float
    public private(set) var reduceAcrossBatch: Bool
    public var propertyCallBack: (any MPSNNLossCallback)?

    public convenience init(source: MPSNNImageNode, labels: MPSNNImageNode, lossDescriptor descriptor: MPSCNNLossDescriptor) {
        self.init(source: source, labels: labels, weights: nil, lossDescriptor: descriptor)
    }

    public convenience init(
        source: MPSNNImageNode,
        labels: MPSNNImageNode,
        weights: MPSNNImageNode,
        lossDescriptor descriptor: MPSCNNLossDescriptor
    ) {
        self.init(source: source, labels: labels, weights: Optional(weights), lossDescriptor: descriptor)
    }

    public init(
        source: MPSNNImageNode,
        labels: MPSNNImageNode,
        weights: MPSNNImageNode?,
        lossDescriptor descriptor: MPSCNNLossDescriptor
    ) {
        _ = (source, labels, weights)
        self.lossType = descriptor.lossType
        self.reductionType = descriptor.reductionType
        self.weight = descriptor.weight
        self.labelSmoothing = descriptor.labelSmoothing
        self.numberOfClasses = descriptor.numberOfClasses
        self.epsilon = descriptor.epsilon
        self.delta = descriptor.delta
        self.reduceAcrossBatch = descriptor.reduceAcrossBatch
        super.init()
    }

    public init(sources sourceNodes: [MPSNNImageNode], lossDescriptor descriptor: MPSCNNLossDescriptor) {
        _ = sourceNodes
        self.lossType = descriptor.lossType
        self.reductionType = descriptor.reductionType
        self.weight = descriptor.weight
        self.labelSmoothing = descriptor.labelSmoothing
        self.numberOfClasses = descriptor.numberOfClasses
        self.epsilon = descriptor.epsilon
        self.delta = descriptor.delta
        self.reduceAcrossBatch = descriptor.reduceAcrossBatch
        super.init()
    }

    open override func gradientFilter(withSource sourceGradient: MPSNNImageNode) -> MPSNNLossGradientNode {
        MPSNNLossGradientNode(
            sourceGradient: sourceGradient,
            sourceImage: resultImage,
            labels: MPSNNImageNode(handle: nil),
            gradientState: resultState as? MPSNNGradientStateNode,
            lossDescriptor: MPSCNNLossDescriptor(type: lossType, reductionType: reductionType),
            isLabelsGradientFilter: false
        )
    }

    open override func gradientFilter(withSources sourceGradient: [MPSNNImageNode]) -> MPSNNLossGradientNode {
        gradientFilter(withSource: sourceGradient.first ?? MPSNNImageNode(handle: nil))
    }

    open override func gradientFilters(withSource sourceGradient: MPSNNImageNode) -> [MPSNNGradientFilterNode] {
        [gradientFilter(withSource: sourceGradient)]
    }

    open override func gradientFilters(withSources sourceGradient: [MPSNNImageNode]) -> [MPSNNGradientFilterNode] {
        [gradientFilter(withSources: sourceGradient)]
    }
}

open class MPSNNBinaryArithmeticNode: MPSNNFilterNode {
    public var primaryScale: Float = 1
    public var secondaryScale: Float = 1
    public var bias: Float = 0
    public var minimumValue: Float = -.greatestFiniteMagnitude
    public var maximumValue: Float = .greatestFiniteMagnitude
    public var primaryStrideInPixelsX: Int = 1
    public var primaryStrideInPixelsY: Int = 1
    public var primaryStrideInFeatureChannels: Int = 1
    public var secondaryStrideInPixelsX: Int = 1
    public var secondaryStrideInPixelsY: Int = 1
    public var secondaryStrideInFeatureChannels: Int = 1

    public init(leftSource left: MPSNNImageNode, rightSource right: MPSNNImageNode) {
        _ = (left, right)
        super.init()
    }

    public init(sources sourceNodes: [MPSNNImageNode]) {
        _ = sourceNodes
        super.init()
    }

    open func gradientClass() -> AnyClass {
        MPSNNGradientFilterNode.self
    }

    open override func gradientFilters(withSources gradientImages: [MPSNNImageNode]) -> [MPSNNGradientFilterNode] {
        gradientImages.map { _ in MPSNNGradientFilterNode() }
    }
}

open class MPSLSTMDescriptor: MPSRNNDescriptor {
    public var memoryWeightsAreDiagonal: Bool = false
    public var inputGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var inputGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var inputGateMemoryWeights: (any MPSCNNConvolutionDataSource)?
    public var forgetGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var forgetGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var forgetGateMemoryWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateMemoryWeights: (any MPSCNNConvolutionDataSource)?
    public var cellGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var cellGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var cellGateMemoryWeights: (any MPSCNNConvolutionDataSource)?
    public var cellToOutputNeuronType: MPSCNNNeuronType = .tanH
    public var cellToOutputNeuronParamA: Float = 1
    public var cellToOutputNeuronParamB: Float = 1
    public var cellToOutputNeuronParamC: Float = 1

    open class func createLSTMDescriptor(
        withInputFeatureChannels inputFeatureChannels: Int,
        outputFeatureChannels: Int
    ) -> Self {
        let descriptor = MPSLSTMDescriptor()
        descriptor.inputFeatureChannels = inputFeatureChannels
        descriptor.outputFeatureChannels = outputFeatureChannels
        return descriptor as! Self
    }
}

open class MPSGRUDescriptor: MPSRNNDescriptor {
    public var inputGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var inputGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var recurrentGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var recurrentGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateInputWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateRecurrentWeights: (any MPSCNNConvolutionDataSource)?
    public var outputGateInputGateWeights: (any MPSCNNConvolutionDataSource)?
    public var gatePnormValue: Float = 1
    public var flipOutputGates: Bool = false

    open class func createGRUDescriptor(
        withInputFeatureChannels inputFeatureChannels: Int,
        outputFeatureChannels: Int
    ) -> Self {
        let descriptor = MPSGRUDescriptor()
        descriptor.inputFeatureChannels = inputFeatureChannels
        descriptor.outputFeatureChannels = outputFeatureChannels
        return descriptor as! Self
    }
}

open class MPSRNNRecurrentMatrixState: MPSState {
    private var recurrent: [MPSMatrix?]
    private var memory: [MPSMatrix?]

    public override init(resource: (any MTLResource)?) {
        self.recurrent = []
        self.memory = []
        super.init(resource: resource)
    }

    public init(recurrent: [MPSMatrix?], memory: [MPSMatrix?]) {
        self.recurrent = recurrent
        self.memory = memory
        super.init(resource: nil)
    }

    open func getRecurrentOutputMatrix(forLayerIndex layerIndex: Int) -> MPSMatrix? {
        recurrent.indices.contains(layerIndex) ? recurrent[layerIndex] : nil
    }

    open func getMemoryCellMatrix(forLayerIndex layerIndex: Int) -> MPSMatrix? {
        memory.indices.contains(layerIndex) ? memory[layerIndex] : nil
    }
}

open class MPSRNNMatrixTrainingState: MPSState {
    public override init(resource: (any MTLResource)?) {
        super.init(resource: resource)
    }
}

open class MPSRNNMatrixTrainingLayer: MPSKernel {
    public private(set) var inputFeatureChannels: Int
    public private(set) var outputFeatureChannels: Int
    public var storeAllIntermediateStates: Bool = false
    public var recurrentOutputIsTemporary: Bool = false
    public var trainingStateIsTemporary: Bool = false
    public var accumulateWeightGradients: Bool = false
    private let rnnDescriptor: MPSRNNDescriptor

    public init(device: any MTLDevice, rnnDescriptor: MPSRNNDescriptor, trainableWeights: NSMutableArray) {
        self.rnnDescriptor = rnnDescriptor
        self.inputFeatureChannels = rnnDescriptor.inputFeatureChannels
        self.outputFeatureChannels = rnnDescriptor.outputFeatureChannels
        super.init(device: device)
        createWeightMatrices(trainableWeights)
    }

    public required init(device: any MTLDevice) {
        self.rnnDescriptor = MPSRNNDescriptor()
        self.inputFeatureChannels = 1
        self.outputFeatureChannels = 1
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let weights = NSMutableArray()
        let copied = MPSRNNMatrixTrainingLayer(
            device: device ?? self.device,
            rnnDescriptor: rnnDescriptor,
            trainableWeights: weights
        )
        copied.options = options
        copied.label = label
        copied.storeAllIntermediateStates = storeAllIntermediateStates
        copied.recurrentOutputIsTemporary = recurrentOutputIsTemporary
        copied.trainingStateIsTemporary = trainingStateIsTemporary
        copied.accumulateWeightGradients = accumulateWeightGradients
        return copied as! Self
    }

    open func createWeightMatrices(_ matricesOut: NSMutableArray) {
        let descriptor = MPSMatrixDescriptor(
            rows: max(outputFeatureChannels, 1),
            columns: max(inputFeatureChannels, 1),
            rowBytes: MPSMatrixDescriptor.rowBytes(forColumns: max(inputFeatureChannels, 1), dataType: .float32),
            dataType: .float32
        )
        matricesOut.add(MPSMatrix(device: device, descriptor: descriptor))
    }

    open func createWeightGradientMatrices(_ matricesOut: NSMutableArray, dataType: MPSDataType) {
        let descriptor = MPSMatrixDescriptor(
            rows: max(outputFeatureChannels, 1),
            columns: max(inputFeatureChannels, 1),
            rowBytes: MPSMatrixDescriptor.rowBytes(forColumns: max(inputFeatureChannels, 1), dataType: dataType),
            dataType: dataType
        )
        matricesOut.add(MPSMatrix(device: device, descriptor: descriptor))
    }

    open func createTemporaryWeightGradientMatrices(
        _ matricesOut: NSMutableArray,
        dataType: MPSDataType,
        commandBuffer: any MTLCommandBuffer
    ) {
        let descriptor = MPSMatrixDescriptor(
            rows: max(outputFeatureChannels, 1),
            columns: max(inputFeatureChannels, 1),
            rowBytes: MPSMatrixDescriptor.rowBytes(forColumns: max(inputFeatureChannels, 1), dataType: dataType),
            dataType: dataType
        )
        matricesOut.add(MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor))
    }

    open func encodeForwardSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrices: [MPSMatrix],
        destinationMatrices: [MPSMatrix],
        trainingStates: NSMutableArray,
        weights: [MPSMatrix]
    ) {
        encodeForwardSequence(
            commandBuffer: commandBuffer,
            sourceMatrices: sourceMatrices,
            sourceOffsets: nil,
            destinationMatrices: destinationMatrices,
            destinationOffsets: nil,
            trainingStates: trainingStates,
            recurrentInputState: nil,
            recurrentOutputStates: nil,
            weights: weights
        )
    }

    open func encodeForwardSequence(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrices: [MPSMatrix],
        sourceOffsets: UnsafeMutablePointer<Int>?,
        destinationMatrices: [MPSMatrix],
        destinationOffsets: UnsafeMutablePointer<Int>?,
        trainingStates: NSMutableArray,
        recurrentInputState: MPSRNNRecurrentMatrixState?,
        recurrentOutputStates: NSMutableArray?,
        weights: [MPSMatrix]
    ) {
        _ = (commandBuffer, sourceMatrices, sourceOffsets, destinationMatrices, destinationOffsets, recurrentInputState, weights)
        trainingStates.add(MPSRNNMatrixTrainingState(resource: nil))
        recurrentOutputStates?.add(MPSRNNRecurrentMatrixState(resource: nil))
        MPSHostBoundary.refuseGPUEncode("MPSRNNMatrixTrainingLayer.encodeForwardSequence")
    }

    open func encodeGradientSequence(
        commandBuffer: any MTLCommandBuffer,
        forwardSources: [MPSMatrix],
        sourceGradients: [MPSMatrix],
        destinationGradients: [MPSMatrix]?,
        weightGradients: [MPSMatrix]?,
        trainingStates: [MPSRNNMatrixTrainingState],
        weights: [MPSMatrix]
    ) {
        encodeGradientSequence(
            commandBuffer: commandBuffer,
            forwardSources: forwardSources,
            forwardSourceOffsets: nil,
            sourceGradients: sourceGradients,
            sourceOffsets: nil,
            destinationGradients: destinationGradients,
            destinationOffsets: nil,
            weightGradients: weightGradients,
            trainingStates: trainingStates,
            recurrentInputState: nil,
            recurrentOutputStates: nil,
            weights: weights
        )
    }

    open func encodeGradientSequence(
        commandBuffer: any MTLCommandBuffer,
        forwardSources: [MPSMatrix],
        forwardSourceOffsets: UnsafeMutablePointer<Int>?,
        sourceGradients: [MPSMatrix],
        sourceOffsets sourceGradientOffsets: UnsafeMutablePointer<Int>?,
        destinationGradients: [MPSMatrix]?,
        destinationOffsets: UnsafeMutablePointer<Int>?,
        weightGradients: [MPSMatrix]?,
        trainingStates: [MPSRNNMatrixTrainingState],
        recurrentInputState: MPSRNNRecurrentMatrixState?,
        recurrentOutputStates: NSMutableArray?,
        weights: [MPSMatrix]
    ) {
        _ = (
            commandBuffer, forwardSources, forwardSourceOffsets, sourceGradients, sourceGradientOffsets,
            destinationGradients, destinationOffsets, weightGradients, trainingStates, recurrentInputState,
            recurrentOutputStates, weights
        )
        MPSHostBoundary.refuseGPUEncode("MPSRNNMatrixTrainingLayer.encodeGradientSequence")
    }

    open func encodeCopyWeights(
        commandBuffer: any MTLCommandBuffer,
        weights: [MPSMatrix],
        matrixId: MPSRNNMatrixId,
        matrix: MPSMatrix,
        copyFromWeightsToMatrix: Bool,
        matrixOffset: MTLOrigin
    ) {
        _ = (commandBuffer, weights, matrixId, matrix, copyFromWeightsToMatrix, matrixOffset)
        MPSHostBoundary.refuseGPUEncode("MPSRNNMatrixTrainingLayer.encodeCopyWeights")
    }
}

public protocol MPSCNNBatchNormalizationDataSource: NSObjectProtocol, NSCopying {
    func numberOfFeatureChannels() -> Int
    func gamma() -> UnsafeMutablePointer<Float>?
    func beta() -> UnsafeMutablePointer<Float>?
    func mean() -> UnsafeMutablePointer<Float>?
    func variance() -> UnsafeMutablePointer<Float>?
    func load() -> Bool
    func purge()
    func label() -> String?
    init?(coder aDecoder: NSCoder)
}

extension MPSCNNBatchNormalizationDataSource {
    public static var supportsSecureCoding: Bool { false }

    public func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        _ = (zone, device)
        return self
    }

    public func encode(with aCoder: NSCoder) {
        _ = aCoder
    }

    public func epsilon() -> Float { 1e-5 }

    public func updateGammaAndBeta(with batchNormalizationState: MPSCNNBatchNormalizationState) -> Bool {
        _ = batchNormalizationState
        return false
    }

    public func updateGammaAndBeta(
        with commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) -> MPSCNNNormalizationGammaAndBetaState? {
        _ = (commandBuffer, batchNormalizationState)
        return nil
    }

    public func updateMeanAndVariance(with batchNormalizationState: MPSCNNBatchNormalizationState) -> Bool {
        _ = batchNormalizationState
        return false
    }

    public func updateMeanAndVariance(
        with commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) -> MPSCNNNormalizationMeanAndVarianceState? {
        _ = (commandBuffer, batchNormalizationState)
        return nil
    }
}

open class MPSCNNNormalizationGammaAndBetaState: MPSState {
    public private(set) var gamma: any MTLBuffer
    public private(set) var beta: any MTLBuffer

    public init(gamma: any MTLBuffer, beta: any MTLBuffer) {
        self.gamma = gamma
        self.beta = beta
        super.init(resources: [gamma, beta])
    }

    open class func temporaryState(with commandBuffer: any MTLCommandBuffer, numberOfFeatureChannels: Int) -> Self {
        let bytes = max(numberOfFeatureChannels, 1) * 4
        let device = commandBuffer.device
        let gamma = (device as? MPSHostDevice)?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        let beta = (device as? MPSHostDevice)?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        let state = MPSCNNNormalizationGammaAndBetaState(gamma: gamma, beta: beta)
        return state as! Self
    }
}

open class MPSCNNNormalizationMeanAndVarianceState: MPSState {
    public private(set) var mean: any MTLBuffer
    public private(set) var variance: any MTLBuffer

    public init(mean: any MTLBuffer, variance: any MTLBuffer) {
        self.mean = mean
        self.variance = variance
        super.init(resources: [mean, variance])
    }

    open class func temporaryState(with commandBuffer: any MTLCommandBuffer, numberOfFeatureChannels: Int) -> Self {
        let bytes = max(numberOfFeatureChannels, 1) * 4
        let device = commandBuffer.device
        let mean = (device as? MPSHostDevice)?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        let variance = (device as? MPSHostDevice)?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        let state = MPSCNNNormalizationMeanAndVarianceState(mean: mean, variance: variance)
        return state as! Self
    }
}

open class MPSCNNBatchNormalizationState: MPSState {
    public private(set) var batchNormalization: MPSCNNBatchNormalization
    private let gammaBuffer: any MTLBuffer
    private let betaBuffer: any MTLBuffer
    private let meanBuffer: any MTLBuffer
    private let varianceBuffer: any MTLBuffer
    private let gammaGrad: any MTLBuffer
    private let betaGrad: any MTLBuffer

    public init(batchNormalization: MPSCNNBatchNormalization) {
        self.batchNormalization = batchNormalization
        let bytes = max(batchNormalization.numberOfFeatureChannels, 1) * 4
        let device = batchNormalization.device
        let host = device as? MPSHostDevice
        func buffer() -> any MTLBuffer {
            host?.makeBuffer(length: bytes) ?? MPSHostBuffer(device: device, length: bytes)
        }
        self.gammaBuffer = buffer()
        self.betaBuffer = buffer()
        self.meanBuffer = buffer()
        self.varianceBuffer = buffer()
        self.gammaGrad = buffer()
        self.betaGrad = buffer()
        super.init(resources: [gammaBuffer, betaBuffer, meanBuffer, varianceBuffer, gammaGrad, betaGrad])
    }

    open func gamma() -> (any MTLBuffer)? { gammaBuffer }
    open func beta() -> (any MTLBuffer)? { betaBuffer }
    open func mean() -> (any MTLBuffer)? { meanBuffer }
    open func variance() -> (any MTLBuffer)? { varianceBuffer }
    open func gradientForGamma() -> (any MTLBuffer)? { gammaGrad }
    open func gradientForBeta() -> (any MTLBuffer)? { betaGrad }

    open func reset() {
        let count = max(batchNormalization.numberOfFeatureChannels, 1)
        for buffer in [gammaBuffer, betaBuffer, meanBuffer, varianceBuffer, gammaGrad, betaGrad] {
            let pointer = buffer.contents.bindMemory(to: Float.self, capacity: count)
            for index in 0..<count {
                pointer[index] = 0
            }
        }
    }
}

open class MPSCNNBatchNormalization: MPSCNNKernel {
    public private(set) var dataSource: any MPSCNNBatchNormalizationDataSource
    public private(set) var numberOfFeatureChannels: Int
    public var epsilon: Float

    public convenience init(device: any MTLDevice, dataSource: any MPSCNNBatchNormalizationDataSource) {
        self.init(device: device, dataSource: dataSource, fusedNeuronDescriptor: nil)
    }

    public init(
        device: any MTLDevice,
        dataSource: any MPSCNNBatchNormalizationDataSource,
        fusedNeuronDescriptor: MPSNNNeuronDescriptor?
    ) {
        _ = dataSource.load()
        self.dataSource = dataSource
        self.numberOfFeatureChannels = dataSource.numberOfFeatureChannels()
        self.epsilon = dataSource.epsilon()
        super.init(device: device)
        _ = fusedNeuronDescriptor
        dataSource.purge()
    }

    public required init(device: any MTLDevice) {
        self.dataSource = MPSCNNHostBatchNormalizationDataSource.placeholder
        self.numberOfFeatureChannels = 1
        self.epsilon = 1e-5
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func reloadDataSource(_ dataSource: any MPSCNNBatchNormalizationDataSource) {
        self.dataSource = dataSource
        _ = dataSource.load()
        numberOfFeatureChannels = dataSource.numberOfFeatureChannels()
        epsilon = dataSource.epsilon()
        dataSource.purge()
    }

    open func reloadGammaAndBetaFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadMeanAndVarianceFromDataSource() {
        _ = dataSource.load()
        dataSource.purge()
    }

    open func reloadGammaAndBeta(
        with commandBuffer: any MTLCommandBuffer,
        gammaAndBetaState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, gammaAndBetaState)
    }

    open func reloadMeanAndVariance(
        with commandBuffer: any MTLCommandBuffer,
        meanAndVarianceState: MPSCNNNormalizationMeanAndVarianceState
    ) {
        _ = (commandBuffer, meanAndVarianceState)
    }

    open override func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNBatchNormalizationState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNBatchNormalizationState(batchNormalization: self)
    }

    open override func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSCNNBatchNormalizationState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, sourceImage, batchNormalizationState, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalization.encode")
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        batchNormalizationState: MPSCNNBatchNormalizationState,
        destinationImages: [MPSImage]
    ) {
        if let source = sourceImages.first, let dest = destinationImages.first {
            encode(to: commandBuffer, sourceImage: source, batchNormalizationState: batchNormalizationState, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalization.encodeBatch")
        }
    }
}

open class MPSCNNBatchNormalizationGradient: MPSCNNKernel {
    public init(device: any MTLDevice, fusedNeuronDescriptor: MPSNNNeuronDescriptor?) {
        super.init(device: device)
        isBackwards = true
        _ = fusedNeuronDescriptor
    }

    public required init(device: any MTLDevice) {
        super.init(device: device)
        isBackwards = true
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceGradient: MPSImage,
        sourceImage: MPSImage,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        destinationGradient: MPSImage
    ) {
        _ = (commandBuffer, sourceGradient, sourceImage, batchNormalizationState, destinationGradient)
        MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalizationGradient.encode")
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        sourceGradient: MPSImage,
        sourceImage: MPSImage,
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) -> MPSImage {
        let dest = destinationImageAllocator.image(
            for: commandBuffer,
            imageDescriptor: destinationImageDescriptor(sourceImages: [sourceImage], sourceStates: nil),
            kernel: self
        )
        encode(
            to: commandBuffer,
            sourceGradient: sourceGradient,
            sourceImage: sourceImage,
            batchNormalizationState: batchNormalizationState,
            destinationGradient: dest
        )
        return dest
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        batchNormalizationState: MPSCNNBatchNormalizationState,
        destinationGradients: [MPSImage]
    ) {
        if let gradient = sourceGradients.first, let source = sourceImages.first, let dest = destinationGradients.first {
            encode(
                to: commandBuffer,
                sourceGradient: gradient,
                sourceImage: source,
                batchNormalizationState: batchNormalizationState,
                destinationGradient: dest
            )
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNBatchNormalizationGradient.encodeBatch")
        }
    }

    open func encodeBatch(
        to commandBuffer: any MTLCommandBuffer,
        sourceGradients: [MPSImage],
        sourceImages: [MPSImage],
        batchNormalizationState: MPSCNNBatchNormalizationState
    ) -> [MPSImage] {
        zip(sourceGradients, sourceImages).map { gradient, source in
            encode(to: commandBuffer, sourceGradient: gradient, sourceImage: source, batchNormalizationState: batchNormalizationState)
        }
    }
}

open class MPSCNNBatchNormalizationNode: MPSNNFilterNode {
    public var flags: MPSCNNBatchNormalizationFlags = .Default
    public var trainingStyle: MPSNNTrainingStyle = .UpdateDeviceNone

    public init(source: MPSNNImageNode, dataSource: any MPSCNNBatchNormalizationDataSource) {
        _ = (source, dataSource)
        super.init()
    }
}

open class MPSCNNConvolutionTransposeGradientState: MPSState {
    public private(set) var convolutionTranspose: MPSCNNConvolutionTranspose

    public init(convolutionTranspose: MPSCNNConvolutionTranspose) {
        self.convolutionTranspose = convolutionTranspose
        super.init(resource: nil)
    }
}

open class MPSCNNConvolutionTransposeGradientStateNode: MPSNNGradientStateNode {}

open class MPSCNNConvolutionTranspose: MPSCNNConvolution {
    public var kernelOffsetX: Int = 0
    public var kernelOffsetY: Int = 0

    public override init(device: any MTLDevice, weights: any MPSCNNConvolutionDataSource) {
        super.init(device: device, weights: weights)
    }

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        convolutionGradientState: MPSCNNConvolutionGradientState?,
        destinationImage: MPSImage
    ) {
        _ = convolutionGradientState
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNConvolutionTranspose.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        convolutionGradientState: MPSCNNConvolutionGradientState?
    ) -> MPSImage {
        let dest = encode(commandBuffer: commandBuffer, sourceImage: sourceImage)
        _ = convolutionGradientState
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        convolutionGradientState: MPSCNNConvolutionGradientState?,
        destinationState outState: UnsafeMutablePointer<MPSCNNConvolutionTransposeGradientState?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> MPSImage {
        _ = isTemporary
        outState.pointee = MPSCNNConvolutionTransposeGradientState(convolutionTranspose: self)
        return encode(commandBuffer: commandBuffer, sourceImage: sourceImage, convolutionGradientState: convolutionGradientState)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        convolutionGradientStates convolutionGradientState: [MPSCNNConvolutionGradientState]?,
        destinationImages destinationImage: [MPSImage]
    ) {
        _ = convolutionGradientState
        encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImage, destinationImages: destinationImage)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        convolutionGradientStates convolutionGradientState: [MPSCNNConvolutionGradientState]?
    ) -> [MPSImage] {
        _ = convolutionGradientState
        return encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImage)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        convolutionGradientStates: [MPSCNNConvolutionGradientState]?,
        destinationStates outStates: UnsafeMutablePointer<NSArray?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> [MPSImage] {
        _ = (convolutionGradientStates, isTemporary)
        outStates.pointee = nil
        return encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImages)
    }

    open func resultState(
        sourceImage: MPSImage,
        sourceStates: [MPSCNNConvolutionGradientState]?,
        destinationImage: MPSImage
    ) -> MPSCNNConvolutionTransposeGradientState? {
        _ = (sourceImage, sourceStates, destinationImage)
        return MPSCNNConvolutionTransposeGradientState(convolutionTranspose: self)
    }

    open func resultStateBatch(
        sourceImage: [MPSImage],
        sourceStates: [[MPSCNNConvolutionGradientState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSCNNConvolutionTransposeGradientState]? {
        _ = (sourceImage, sourceStates, destinationImage)
        return [MPSCNNConvolutionTransposeGradientState(convolutionTranspose: self)]
    }

    open func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        sourceStates: [MPSCNNConvolutionGradientState]?,
        destinationImage: MPSImage
    ) -> MPSCNNConvolutionTransposeGradientState? {
        _ = commandBuffer
        return resultState(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }

    open func temporaryResultStateBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: [MPSImage],
        sourceStates: [[MPSCNNConvolutionGradientState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSCNNConvolutionTransposeGradientState]? {
        _ = commandBuffer
        return resultStateBatch(sourceImage: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }
}

final class MPSCNNHostBatchNormalizationDataSource: NSObject, MPSCNNBatchNormalizationDataSource {
    static let placeholder = MPSCNNHostBatchNormalizationDataSource(channels: 1)

    private let channels: Int
    private var gammaStorage: UnsafeMutablePointer<Float>
    private var betaStorage: UnsafeMutablePointer<Float>
    private var meanStorage: UnsafeMutablePointer<Float>
    private var varianceStorage: UnsafeMutablePointer<Float>

    init(channels: Int) {
        self.channels = max(channels, 1)
        self.gammaStorage = UnsafeMutablePointer<Float>.allocate(capacity: self.channels)
        self.betaStorage = UnsafeMutablePointer<Float>.allocate(capacity: self.channels)
        self.meanStorage = UnsafeMutablePointer<Float>.allocate(capacity: self.channels)
        self.varianceStorage = UnsafeMutablePointer<Float>.allocate(capacity: self.channels)
        for index in 0..<self.channels {
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
        return MPSCNNHostBatchNormalizationDataSource(channels: channels)
    }

    func numberOfFeatureChannels() -> Int { channels }
    func gamma() -> UnsafeMutablePointer<Float>? { gammaStorage }
    func beta() -> UnsafeMutablePointer<Float>? { betaStorage }
    func mean() -> UnsafeMutablePointer<Float>? { meanStorage }
    func variance() -> UnsafeMutablePointer<Float>? { varianceStorage }
    func load() -> Bool { true }
    func purge() {}
    func label() -> String? { "MPSHostBatchNormalizationDataSource" }
}
