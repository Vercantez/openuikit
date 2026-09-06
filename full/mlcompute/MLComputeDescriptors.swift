import Foundation

open class MLCActivationDescriptor: NSObject, NSCopying {
    public let activationType: MLCActivationType
    public let a: Float
    public let b: Float
    public let c: Float

    public convenience init?(type activationType: MLCActivationType) {
        let defaults = MLCActivationDefaults.parameters(for: activationType)
        self.init(type: activationType, a: defaults.0, b: defaults.1, c: defaults.2)
    }

    public convenience init?(type activationType: MLCActivationType, a: Float) {
        let defaults = MLCActivationDefaults.parameters(for: activationType)
        self.init(type: activationType, a: a, b: defaults.1, c: defaults.2)
    }

    public convenience init?(type activationType: MLCActivationType, a: Float, b: Float) {
        let defaults = MLCActivationDefaults.parameters(for: activationType)
        self.init(type: activationType, a: a, b: b, c: defaults.2)
    }

    public init?(type activationType: MLCActivationType, a: Float, b: Float, c: Float) {
        self.activationType = activationType
        self.a = a
        self.b = b
        self.c = c
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCActivationDescriptor(type: activationType, a: a, b: b, c: c)!
    }

    public func linuxHostApply(_ x: Float) -> Float {
        mlcApplyActivation(type: activationType, a: a, b: b, c: c, x: x)
    }
}

open class MLCConvolutionDescriptor: NSObject, NSCopying {
    public let convolutionType: MLCConvolutionType
    public let kernelSizes: (height: Int, width: Int)
    public let inputFeatureChannelCount: Int
    public let outputFeatureChannelCount: Int
    public let groupCount: Int
    public let strides: (y: Int, x: Int)
    public let dilationRates: (y: Int, x: Int)
    public let paddingPolicy: MLCPaddingPolicy

    public var isConvolutionTranspose: Bool { convolutionType == .transposed }
    public var usesDepthwiseConvolution: Bool { convolutionType == .depthwise }

    public convenience init(
        type: MLCConvolutionType = .standard,
        kernelSizes: (height: Int, width: Int),
        inputFeatureChannelCount: Int,
        outputFeatureChannelCount: Int,
        groupCount: Int = 1,
        strides: (y: Int, x: Int) = (1, 1),
        dilationRates: (y: Int, x: Int) = (1, 1),
        paddingPolicy: MLCPaddingPolicy = .same
    ) {
        self.init(
            convolutionType: type,
            kernelSizes: kernelSizes,
            inputFeatureChannelCount: inputFeatureChannelCount,
            outputFeatureChannelCount: outputFeatureChannelCount,
            groupCount: groupCount,
            strides: strides,
            dilationRates: dilationRates,
            paddingPolicy: paddingPolicy
        )
    }

    public convenience init(
        transposeWithKernelWidth kernelWidth: Int,
        kernelHeight: Int,
        inputFeatureChannelCount: Int,
        outputFeatureChannelCount: Int
    ) {
        self.init(
            type: .transposed,
            kernelSizes: (height: kernelHeight, width: kernelWidth),
            inputFeatureChannelCount: inputFeatureChannelCount,
            outputFeatureChannelCount: outputFeatureChannelCount
        )
    }

    public convenience init(
        depthwiseWithKernelWidth kernelWidth: Int,
        kernelHeight: Int,
        inputFeatureChannelCount: Int,
        channelMultiplier: Int
    ) {
        self.init(
            type: .depthwise,
            kernelSizes: (height: kernelHeight, width: kernelWidth),
            inputFeatureChannelCount: inputFeatureChannelCount,
            outputFeatureChannelCount: inputFeatureChannelCount * channelMultiplier,
            groupCount: inputFeatureChannelCount
        )
    }

    init(
        convolutionType: MLCConvolutionType,
        kernelSizes: (height: Int, width: Int),
        inputFeatureChannelCount: Int,
        outputFeatureChannelCount: Int,
        groupCount: Int,
        strides: (y: Int, x: Int),
        dilationRates: (y: Int, x: Int),
        paddingPolicy: MLCPaddingPolicy
    ) {
        self.convolutionType = convolutionType
        self.kernelSizes = kernelSizes
        self.inputFeatureChannelCount = inputFeatureChannelCount
        self.outputFeatureChannelCount = outputFeatureChannelCount
        self.groupCount = groupCount
        self.strides = strides
        self.dilationRates = dilationRates
        self.paddingPolicy = paddingPolicy
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCConvolutionDescriptor(
            convolutionType: convolutionType,
            kernelSizes: kernelSizes,
            inputFeatureChannelCount: inputFeatureChannelCount,
            outputFeatureChannelCount: outputFeatureChannelCount,
            groupCount: groupCount,
            strides: strides,
            dilationRates: dilationRates,
            paddingPolicy: paddingPolicy
        )
    }

    public func linuxOutputSpatial(inputHeight: Int, inputWidth: Int) -> (Int, Int) {
        mlcSpatialOutput(
            input: inputHeight,
            kernel: kernelSizes.height,
            stride: strides.y,
            dilation: dilationRates.y,
            padding: paddingPolicy,
            isHeight: true
        ).map { h in
            let w = mlcSpatialOutput(
                input: inputWidth,
                kernel: kernelSizes.width,
                stride: strides.x,
                dilation: dilationRates.x,
                padding: paddingPolicy,
                isHeight: false
            ) ?? 0
            return (h, w)
        } ?? (0, 0)
    }
}

func mlcSpatialOutput(
    input: Int,
    kernel: Int,
    stride: Int,
    dilation: Int,
    padding: MLCPaddingPolicy,
    isHeight: Bool
) -> Int? {
    let effective = dilation * (kernel - 1) + 1
    let pad: Int
    switch padding {
    case .valid:
        pad = 0
    case .same:
        let strideSafe = max(stride, 1)
        let out = (input + strideSafe - 1) / strideSafe
        return max(out, 0)
    case .sized(let y, let x):
        pad = isHeight ? y : x
    }
    let strideSafe = max(stride, 1)
    let out = (input + 2 * pad - effective) / strideSafe + 1
    return out > 0 ? out : nil
}

open class MLCPoolingDescriptor: NSObject, NSCopying {
    public let poolingType: MLCPoolingType
    public let kernelSizes: (height: Int, width: Int)
    public let strides: (y: Int, x: Int)
    public let dilationRates: (y: Int, x: Int)
    public let paddingPolicy: MLCPaddingPolicy

    public convenience init(
        type: MLCPoolingType,
        kernelSizes: (height: Int, width: Int),
        strides: (y: Int, x: Int) = (y: 1, x: 1),
        dilationRates: (y: Int, x: Int) = (y: 1, x: 1),
        paddingPolicy: MLCPaddingPolicy = .same
    ) {
        self.init(
            poolingType: type,
            kernelSizes: kernelSizes,
            strides: strides,
            dilationRates: dilationRates,
            paddingPolicy: paddingPolicy
        )
    }

    init(
        poolingType: MLCPoolingType,
        kernelSizes: (height: Int, width: Int),
        strides: (y: Int, x: Int),
        dilationRates: (y: Int, x: Int),
        paddingPolicy: MLCPaddingPolicy
    ) {
        self.poolingType = poolingType
        self.kernelSizes = kernelSizes
        self.strides = strides
        self.dilationRates = dilationRates
        self.paddingPolicy = paddingPolicy
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCPoolingDescriptor(
            poolingType: poolingType,
            kernelSizes: kernelSizes,
            strides: strides,
            dilationRates: dilationRates,
            paddingPolicy: paddingPolicy
        )
    }
}

open class MLCLossDescriptor: NSObject, NSCopying {
    public let lossType: MLCLossType
    public let reductionType: MLCReductionType
    public let weight: Float
    public let labelSmoothing: Float
    public let classCount: Int
    public let epsilon: Float
    public let delta: Float

    public convenience init(type lossType: MLCLossType, reductionType: MLCReductionType) {
        self.init(
            type: lossType,
            reductionType: reductionType,
            weight: 1,
            labelSmoothing: 0,
            classCount: 1,
            epsilon: 1e-7,
            delta: 1
        )
    }

    public convenience init(type lossType: MLCLossType, reductionType: MLCReductionType, weight: Float) {
        self.init(
            type: lossType,
            reductionType: reductionType,
            weight: weight,
            labelSmoothing: 0,
            classCount: 1,
            epsilon: 1e-7,
            delta: 1
        )
    }

    public convenience init(
        type lossType: MLCLossType,
        reductionType: MLCReductionType,
        weight: Float,
        labelSmoothing: Float,
        classCount: Int
    ) {
        self.init(
            type: lossType,
            reductionType: reductionType,
            weight: weight,
            labelSmoothing: labelSmoothing,
            classCount: classCount,
            epsilon: 1e-7,
            delta: 1
        )
    }

    public init(
        type lossType: MLCLossType,
        reductionType: MLCReductionType,
        weight: Float,
        labelSmoothing: Float,
        classCount: Int,
        epsilon: Float,
        delta: Float
    ) {
        self.lossType = lossType
        self.reductionType = reductionType
        self.weight = weight
        self.labelSmoothing = labelSmoothing
        self.classCount = classCount
        self.epsilon = epsilon
        self.delta = delta
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCLossDescriptor(
            type: lossType,
            reductionType: reductionType,
            weight: weight,
            labelSmoothing: labelSmoothing,
            classCount: classCount,
            epsilon: epsilon,
            delta: delta
        )
    }
}

open class MLCOptimizerDescriptor: NSObject, NSCopying {
    public let learningRate: Float
    public let gradientRescale: Float
    public let appliesGradientClipping: Bool
    public let gradientClipMax: Float
    public let gradientClipMin: Float
    public let regularizationType: MLCRegularizationType
    public let regularizationScale: Float
    public let gradientClippingType: MLCGradientClippingType
    public let maximumClippingNorm: Float
    public let customGlobalNorm: Float

    public convenience init(
        learningRate: Float,
        gradientRescale: Float,
        regularizationType: MLCRegularizationType,
        regularizationScale: Float
    ) {
        self.init(
            learningRate: learningRate,
            gradientRescale: gradientRescale,
            appliesGradientClipping: false,
            gradientClippingType: .byValue,
            gradientClipMax: 0.1,
            gradientClipMin: -0.1,
            maximumClippingNorm: 1,
            customGlobalNorm: 0,
            regularizationType: regularizationType,
            regularizationScale: regularizationScale
        )
    }

    public convenience init(
        learningRate: Float,
        gradientRescale: Float,
        appliesGradientClipping: Bool,
        gradientClipMax: Float,
        gradientClipMin: Float,
        regularizationType: MLCRegularizationType,
        regularizationScale: Float
    ) {
        self.init(
            learningRate: learningRate,
            gradientRescale: gradientRescale,
            appliesGradientClipping: appliesGradientClipping,
            gradientClippingType: .byValue,
            gradientClipMax: gradientClipMax,
            gradientClipMin: gradientClipMin,
            maximumClippingNorm: 1,
            customGlobalNorm: 0,
            regularizationType: regularizationType,
            regularizationScale: regularizationScale
        )
    }

    public init(
        learningRate: Float,
        gradientRescale: Float,
        appliesGradientClipping: Bool,
        gradientClippingType: MLCGradientClippingType,
        gradientClipMax: Float,
        gradientClipMin: Float,
        maximumClippingNorm: Float,
        customGlobalNorm: Float,
        regularizationType: MLCRegularizationType,
        regularizationScale: Float
    ) {
        self.learningRate = learningRate
        self.gradientRescale = gradientRescale
        self.appliesGradientClipping = appliesGradientClipping
        self.gradientClippingType = gradientClippingType
        self.gradientClipMax = gradientClipMax
        self.gradientClipMin = gradientClipMin
        self.maximumClippingNorm = maximumClippingNorm
        self.customGlobalNorm = customGlobalNorm
        self.regularizationType = regularizationType
        self.regularizationScale = regularizationScale
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCOptimizerDescriptor(
            learningRate: learningRate,
            gradientRescale: gradientRescale,
            appliesGradientClipping: appliesGradientClipping,
            gradientClippingType: gradientClippingType,
            gradientClipMax: gradientClipMax,
            gradientClipMin: gradientClipMin,
            maximumClippingNorm: maximumClippingNorm,
            customGlobalNorm: customGlobalNorm,
            regularizationType: regularizationType,
            regularizationScale: regularizationScale
        )
    }
}

open class MLCLSTMDescriptor: NSObject, NSCopying {
    public let inputSize: Int
    public let hiddenSize: Int
    public let layerCount: Int
    public let usesBiases: Bool
    public let batchFirst: Bool
    public let isBidirectional: Bool
    public let returnsSequences: Bool
    public let dropout: Float
    public let resultMode: MLCLSTMResultMode

    public convenience init(inputSize: Int, hiddenSize: Int, layerCount: Int) {
        self.init(
            inputSize: inputSize,
            hiddenSize: hiddenSize,
            layerCount: layerCount,
            usesBiases: true,
            batchFirst: false,
            isBidirectional: false,
            returnsSequences: true,
            dropout: 0,
            resultMode: .output
        )
    }

    public convenience init(
        inputSize: Int,
        hiddenSize: Int,
        layerCount: Int,
        usesBiases: Bool,
        isBidirectional: Bool,
        dropout: Float
    ) {
        self.init(
            inputSize: inputSize,
            hiddenSize: hiddenSize,
            layerCount: layerCount,
            usesBiases: usesBiases,
            batchFirst: false,
            isBidirectional: isBidirectional,
            returnsSequences: true,
            dropout: dropout,
            resultMode: .output
        )
    }

    public convenience init(
        inputSize: Int,
        hiddenSize: Int,
        layerCount: Int,
        usesBiases: Bool,
        batchFirst: Bool,
        isBidirectional: Bool,
        dropout: Float
    ) {
        self.init(
            inputSize: inputSize,
            hiddenSize: hiddenSize,
            layerCount: layerCount,
            usesBiases: usesBiases,
            batchFirst: batchFirst,
            isBidirectional: isBidirectional,
            returnsSequences: true,
            dropout: dropout,
            resultMode: .output
        )
    }

    public convenience init(
        inputSize: Int,
        hiddenSize: Int,
        layerCount: Int,
        usesBiases: Bool,
        batchFirst: Bool,
        isBidirectional: Bool,
        returnsSequences: Bool,
        dropout: Float
    ) {
        self.init(
            inputSize: inputSize,
            hiddenSize: hiddenSize,
            layerCount: layerCount,
            usesBiases: usesBiases,
            batchFirst: batchFirst,
            isBidirectional: isBidirectional,
            returnsSequences: returnsSequences,
            dropout: dropout,
            resultMode: .output
        )
    }

    public init(
        inputSize: Int,
        hiddenSize: Int,
        layerCount: Int,
        usesBiases: Bool,
        batchFirst: Bool,
        isBidirectional: Bool,
        returnsSequences: Bool,
        dropout: Float,
        resultMode: MLCLSTMResultMode
    ) {
        self.inputSize = inputSize
        self.hiddenSize = hiddenSize
        self.layerCount = layerCount
        self.usesBiases = usesBiases
        self.batchFirst = batchFirst
        self.isBidirectional = isBidirectional
        self.returnsSequences = returnsSequences
        self.dropout = dropout
        self.resultMode = resultMode
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCLSTMDescriptor(
            inputSize: inputSize,
            hiddenSize: hiddenSize,
            layerCount: layerCount,
            usesBiases: usesBiases,
            batchFirst: batchFirst,
            isBidirectional: isBidirectional,
            returnsSequences: returnsSequences,
            dropout: dropout,
            resultMode: resultMode
        )
    }
}

open class MLCEmbeddingDescriptor: NSObject, NSCopying {
    public let embeddingCount: Int
    public let embeddingDimension: Int
    public let paddingIndex: Int?
    public let maximumNorm: Float?
    public let pNorm: Float?
    public let scalesGradientByFrequency: Bool

    public convenience init?(embeddingCount: Int, embeddingDimension: Int) {
        self.init(
            embeddingCount: embeddingCount,
            embeddingDimension: embeddingDimension,
            paddingIndex: nil,
            maximumNorm: nil,
            pNorm: nil,
            scalesGradientByFrequency: false
        )
    }

    public init?(
        embeddingCount: Int,
        embeddingDimension: Int,
        paddingIndex: Int?,
        maximumNorm: Float?,
        pNorm: Float?,
        scalesGradientByFrequency: Bool
    ) {
        guard embeddingCount > 0, embeddingDimension > 0 else { return nil }
        self.embeddingCount = embeddingCount
        self.embeddingDimension = embeddingDimension
        self.paddingIndex = paddingIndex
        self.maximumNorm = maximumNorm
        self.pNorm = pNorm
        self.scalesGradientByFrequency = scalesGradientByFrequency
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCEmbeddingDescriptor(
            embeddingCount: embeddingCount,
            embeddingDimension: embeddingDimension,
            paddingIndex: paddingIndex,
            maximumNorm: maximumNorm,
            pNorm: pNorm,
            scalesGradientByFrequency: scalesGradientByFrequency
        )!
    }
}

open class MLCMatMulDescriptor: NSObject, NSCopying {
    public let alpha: Float
    public let transposesX: Bool
    public let transposesY: Bool

    public override convenience init() {
        self.init(alpha: 1, transposesX: false, transposesY: false)!
    }

    public init?(alpha: Float, transposesX: Bool, transposesY: Bool) {
        self.alpha = alpha
        self.transposesX = transposesX
        self.transposesY = transposesY
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCMatMulDescriptor(alpha: alpha, transposesX: transposesX, transposesY: transposesY)!
    }
}

open class MLCMultiheadAttentionDescriptor: NSObject, NSCopying {
    public let modelDimension: Int
    public let keyDimension: Int
    public let valueDimension: Int
    public let headCount: Int
    public let dropout: Float
    public let hasBiases: Bool
    public let hasAttentionBiases: Bool
    public let addsZeroAttention: Bool

    public convenience init(modelDimension: Int, headCount: Int) {
        self.init(
            modelDimension: modelDimension,
            keyDimension: modelDimension,
            valueDimension: modelDimension,
            headCount: headCount,
            dropout: 0,
            hasBiases: true,
            hasAttentionBiases: false,
            addsZeroAttention: false
        )!
    }

    public init?(
        modelDimension: Int,
        keyDimension: Int,
        valueDimension: Int,
        headCount: Int,
        dropout: Float,
        hasBiases: Bool,
        hasAttentionBiases: Bool,
        addsZeroAttention: Bool
    ) {
        guard modelDimension > 0, headCount > 0, modelDimension % headCount == 0 else { return nil }
        self.modelDimension = modelDimension
        self.keyDimension = keyDimension
        self.valueDimension = valueDimension
        self.headCount = headCount
        self.dropout = dropout
        self.hasBiases = hasBiases
        self.hasAttentionBiases = hasAttentionBiases
        self.addsZeroAttention = addsZeroAttention
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCMultiheadAttentionDescriptor(
            modelDimension: modelDimension,
            keyDimension: keyDimension,
            valueDimension: valueDimension,
            headCount: headCount,
            dropout: dropout,
            hasBiases: hasBiases,
            hasAttentionBiases: hasAttentionBiases,
            addsZeroAttention: addsZeroAttention
        )!
    }
}

open class MLCYOLOLossDescriptor: NSObject, NSCopying {
    public let anchorBoxes: Data
    public let anchorBoxCount: Int
    public var maximumIOUForObjectAbsence: Float
    public var minimumIOUForObjectPresence: Float
    public var scaleClassLoss: Float
    public var scaleNoObjectConfidenceLoss: Float
    public var scaleObjectConfidenceLoss: Float
    public var scaleSpatialPositionLoss: Float
    public var scaleSpatialSizeLoss: Float
    public var shouldRescore: Bool

    public init(anchorBoxes: Data, anchorBoxCount: Int) {
        self.anchorBoxes = anchorBoxes
        self.anchorBoxCount = anchorBoxCount
        self.maximumIOUForObjectAbsence = 0.3
        self.minimumIOUForObjectPresence = 0.3
        self.scaleClassLoss = 1
        self.scaleNoObjectConfidenceLoss = 0.5
        self.scaleObjectConfidenceLoss = 1
        self.scaleSpatialPositionLoss = 1
        self.scaleSpatialSizeLoss = 1
        self.shouldRescore = true
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MLCYOLOLossDescriptor(anchorBoxes: anchorBoxes, anchorBoxCount: anchorBoxCount)
        copy.maximumIOUForObjectAbsence = maximumIOUForObjectAbsence
        copy.minimumIOUForObjectPresence = minimumIOUForObjectPresence
        copy.scaleClassLoss = scaleClassLoss
        copy.scaleNoObjectConfidenceLoss = scaleNoObjectConfidenceLoss
        copy.scaleObjectConfidenceLoss = scaleObjectConfidenceLoss
        copy.scaleSpatialPositionLoss = scaleSpatialPositionLoss
        copy.scaleSpatialSizeLoss = scaleSpatialSizeLoss
        copy.shouldRescore = shouldRescore
        return copy
    }
}
