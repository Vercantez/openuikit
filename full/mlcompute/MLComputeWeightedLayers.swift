import Foundation

open class MLCConvolutionLayer: MLCLayer {
    public let weights: MLCTensor
    public let biases: MLCTensor?
    public let descriptor: MLCConvolutionDescriptor
    public let weightsParameter: MLCTensorParameter
    public let biasesParameter: MLCTensorParameter?

    public init?(weights: MLCTensor, biases: MLCTensor?, descriptor: MLCConvolutionDescriptor) {
        self.weights = weights
        self.biases = biases
        self.descriptor = descriptor
        self.weightsParameter = MLCTensorParameter(tensor: weights)
        self.biasesParameter = biases.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "convolution"
    }
}

open class MLCFullyConnectedLayer: MLCLayer {
    public let weights: MLCTensor
    public let biases: MLCTensor?
    public let descriptor: MLCConvolutionDescriptor
    public let weightsParameter: MLCTensorParameter
    public let biasesParameter: MLCTensorParameter?

    public init?(weights: MLCTensor, biases: MLCTensor?, descriptor: MLCConvolutionDescriptor) {
        self.weights = weights
        self.biases = biases
        self.descriptor = descriptor
        self.weightsParameter = MLCTensorParameter(tensor: weights)
        self.biasesParameter = biases.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "fullyConnected"
    }
}

open class MLCEmbeddingLayer: MLCLayer {
    public let descriptor: MLCEmbeddingDescriptor
    public let weights: MLCTensor
    public let weightsParameter: MLCTensorParameter

    public init(descriptor: MLCEmbeddingDescriptor, weights: MLCTensor) {
        self.descriptor = descriptor
        self.weights = weights
        self.weightsParameter = MLCTensorParameter(tensor: weights)
        super.init()
        label = "embedding"
    }
}

open class MLCBatchNormalizationLayer: MLCLayer {
    public let featureChannelCount: Int
    public let mean: MLCTensor
    public let variance: MLCTensor
    public let beta: MLCTensor?
    public let gamma: MLCTensor?
    public let varianceEpsilon: Float
    public let momentum: Float
    public let betaParameter: MLCTensorParameter?
    public let gammaParameter: MLCTensorParameter?

    public convenience init?(
        featureChannelCount: Int,
        mean: MLCTensor,
        variance: MLCTensor,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float
    ) {
        self.init(
            featureChannelCount: featureChannelCount,
            mean: mean,
            variance: variance,
            beta: beta,
            gamma: gamma,
            varianceEpsilon: varianceEpsilon,
            momentum: 0.99
        )
    }

    public init?(
        featureChannelCount: Int,
        mean: MLCTensor,
        variance: MLCTensor,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float,
        momentum: Float
    ) {
        guard featureChannelCount > 0 else { return nil }
        self.featureChannelCount = featureChannelCount
        self.mean = mean
        self.variance = variance
        self.beta = beta
        self.gamma = gamma
        self.varianceEpsilon = varianceEpsilon
        self.momentum = momentum
        self.betaParameter = beta.map { MLCTensorParameter(tensor: $0) }
        self.gammaParameter = gamma.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "batchNorm"
    }
}

open class MLCInstanceNormalizationLayer: MLCLayer {
    public let featureChannelCount: Int
    public let mean: MLCTensor?
    public let variance: MLCTensor?
    public let beta: MLCTensor?
    public let gamma: MLCTensor?
    public let varianceEpsilon: Float
    public let momentum: Float
    public let betaParameter: MLCTensorParameter?
    public let gammaParameter: MLCTensorParameter?

    public convenience init?(
        featureChannelCount: Int,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float
    ) {
        self.init(
            featureChannelCount: featureChannelCount,
            mean: nil,
            variance: nil,
            beta: beta,
            gamma: gamma,
            varianceEpsilon: varianceEpsilon,
            momentum: 0.99
        )
    }

    public convenience init?(
        featureChannelCount: Int,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float,
        momentum: Float
    ) {
        self.init(
            featureChannelCount: featureChannelCount,
            mean: nil,
            variance: nil,
            beta: beta,
            gamma: gamma,
            varianceEpsilon: varianceEpsilon,
            momentum: momentum
        )
    }

    public init?(
        featureChannelCount: Int,
        mean: MLCTensor?,
        variance: MLCTensor?,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float,
        momentum: Float
    ) {
        guard featureChannelCount > 0 else { return nil }
        self.featureChannelCount = featureChannelCount
        self.mean = mean
        self.variance = variance
        self.beta = beta
        self.gamma = gamma
        self.varianceEpsilon = varianceEpsilon
        self.momentum = momentum
        self.betaParameter = beta.map { MLCTensorParameter(tensor: $0) }
        self.gammaParameter = gamma.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "instanceNorm"
    }
}

open class MLCGroupNormalizationLayer: MLCLayer {
    public let featureChannelCount: Int
    public let groupCount: Int
    public let beta: MLCTensor?
    public let gamma: MLCTensor?
    public let varianceEpsilon: Float
    public let betaParameter: MLCTensorParameter?
    public let gammaParameter: MLCTensorParameter?

    public init?(
        featureChannelCount: Int,
        groupCount: Int,
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float
    ) {
        guard featureChannelCount > 0, groupCount > 0, featureChannelCount % groupCount == 0 else { return nil }
        self.featureChannelCount = featureChannelCount
        self.groupCount = groupCount
        self.beta = beta
        self.gamma = gamma
        self.varianceEpsilon = varianceEpsilon
        self.betaParameter = beta.map { MLCTensorParameter(tensor: $0) }
        self.gammaParameter = gamma.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "groupNorm"
    }
}

open class MLCLayerNormalizationLayer: MLCLayer {
    public let normalizedShape: [Int]
    public let beta: MLCTensor?
    public let gamma: MLCTensor?
    public let varianceEpsilon: Float
    public let betaParameter: MLCTensorParameter?
    public let gammaParameter: MLCTensorParameter?

    public convenience init?(
        normalizedShape: [Int],
        beta: MLCTensor,
        gamma: MLCTensor,
        varianceEpsilon: Float
    ) {
        self.init(
            normalizedShape: normalizedShape,
            beta: Optional(beta),
            gamma: Optional(gamma),
            varianceEpsilon: varianceEpsilon
        )
    }

    public init?(
        normalizedShape: [Int],
        beta: MLCTensor?,
        gamma: MLCTensor?,
        varianceEpsilon: Float
    ) {
        guard !normalizedShape.isEmpty else { return nil }
        self.normalizedShape = normalizedShape
        self.beta = beta
        self.gamma = gamma
        self.varianceEpsilon = varianceEpsilon
        self.betaParameter = beta.map { MLCTensorParameter(tensor: $0) }
        self.gammaParameter = gamma.map { MLCTensorParameter(tensor: $0) }
        super.init()
        label = "layerNorm"
    }
}

open class MLCLSTMLayer: MLCLayer {
    public let descriptor: MLCLSTMDescriptor
    public let inputWeights: [MLCTensor]
    public let hiddenWeights: [MLCTensor]
    public let peepholeWeights: [MLCTensor]?
    public let biases: [MLCTensor]?
    public let gateActivations: [MLCActivationDescriptor]
    public let outputResultActivation: MLCActivationDescriptor
    public let inputWeightsParameters: [MLCTensorParameter]
    public let hiddenWeightsParameters: [MLCTensorParameter]
    public let peepholeWeightsParameters: [MLCTensorParameter]?
    public let biasesParameters: [MLCTensorParameter]?

    public convenience init?(
        descriptor: MLCLSTMDescriptor,
        inputWeights: [MLCTensor],
        hiddenWeights: [MLCTensor],
        biases: [MLCTensor]?
    ) {
        self.init(
            descriptor: descriptor,
            inputWeights: inputWeights,
            hiddenWeights: hiddenWeights,
            peepholeWeights: nil,
            biases: biases
        )
    }

    public convenience init?(
        descriptor: MLCLSTMDescriptor,
        inputWeights: [MLCTensor],
        hiddenWeights: [MLCTensor],
        peepholeWeights: [MLCTensor]?,
        biases: [MLCTensor]?
    ) {
        let gates = [
            MLCActivationDescriptor(type: .sigmoid)!,
            MLCActivationDescriptor(type: .sigmoid)!,
            MLCActivationDescriptor(type: .tanh)!,
            MLCActivationDescriptor(type: .sigmoid)!,
        ]
        self.init(
            descriptor: descriptor,
            inputWeights: inputWeights,
            hiddenWeights: hiddenWeights,
            peepholeWeights: peepholeWeights,
            biases: biases,
            gateActivations: gates,
            outputResultActivation: MLCActivationDescriptor(type: .tanh)!
        )
    }

    public init?(
        descriptor: MLCLSTMDescriptor,
        inputWeights: [MLCTensor],
        hiddenWeights: [MLCTensor],
        peepholeWeights: [MLCTensor]?,
        biases: [MLCTensor]?,
        gateActivations: [MLCActivationDescriptor],
        outputResultActivation: MLCActivationDescriptor
    ) {
        let directionFactor = descriptor.isBidirectional ? 2 : 1
        let expected = 4 * descriptor.layerCount * directionFactor
        guard inputWeights.count == expected, hiddenWeights.count == expected else { return nil }
        if descriptor.usesBiases {
            guard biases?.count == expected else { return nil }
        }
        self.descriptor = descriptor
        self.inputWeights = inputWeights
        self.hiddenWeights = hiddenWeights
        self.peepholeWeights = peepholeWeights
        self.biases = biases
        self.gateActivations = gateActivations
        self.outputResultActivation = outputResultActivation
        self.inputWeightsParameters = inputWeights.map { MLCTensorParameter(tensor: $0) }
        self.hiddenWeightsParameters = hiddenWeights.map { MLCTensorParameter(tensor: $0) }
        self.peepholeWeightsParameters = peepholeWeights.map { $0.map { MLCTensorParameter(tensor: $0) } }
        self.biasesParameters = biases.map { $0.map { MLCTensorParameter(tensor: $0) } }
        super.init()
        label = "lstm"
    }
}

open class MLCMultiheadAttentionLayer: MLCLayer {
    public let descriptor: MLCMultiheadAttentionDescriptor
    public let weights: [MLCTensor]
    public let biases: [MLCTensor]?
    public let attentionBiases: [MLCTensor]?
    public let weightsParameters: [MLCTensorParameter]
    public let biasesParameters: [MLCTensorParameter]?

    public init?(
        descriptor: MLCMultiheadAttentionDescriptor,
        weights: [MLCTensor],
        biases: [MLCTensor]?,
        attentionBiases: [MLCTensor]?
    ) {
        guard weights.count == 4 else { return nil }
        if descriptor.hasBiases {
            guard biases?.count == 4 else { return nil }
        }
        self.descriptor = descriptor
        self.weights = weights
        self.biases = biases
        self.attentionBiases = attentionBiases
        self.weightsParameters = weights.map { MLCTensorParameter(tensor: $0) }
        self.biasesParameters = biases.map { $0.map { MLCTensorParameter(tensor: $0) } }
        super.init()
        label = "multiheadAttention"
    }
}

open class MLCLossLayer: MLCLayer {
    public let descriptor: MLCLossDescriptor
    public let weights: MLCTensor?

    public required init(linuxDescriptor: MLCLossDescriptor, linuxWeights: MLCTensor?) {
        self.descriptor = linuxDescriptor
        self.weights = linuxWeights
        super.init()
        label = "loss"
    }

    public convenience init(descriptor lossDescriptor: MLCLossDescriptor) {
        self.init(linuxDescriptor: lossDescriptor, linuxWeights: nil)
    }

    public convenience init(descriptor lossDescriptor: MLCLossDescriptor, weights: MLCTensor) {
        self.init(linuxDescriptor: lossDescriptor, linuxWeights: weights)
    }

    public class func meanAbsoluteError(reductionType: MLCReductionType, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .meanAbsoluteError, reductionType: reductionType, weight: weight),
            linuxWeights: nil
        )
    }

    public class func meanAbsoluteError(reductionType: MLCReductionType, weights: MLCTensor?) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .meanAbsoluteError, reductionType: reductionType),
            linuxWeights: weights
        )
    }

    public class func meanSquaredError(reductionType: MLCReductionType, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .meanSquaredError, reductionType: reductionType, weight: weight),
            linuxWeights: nil
        )
    }

    public class func meanSquaredError(reductionType: MLCReductionType, weights: MLCTensor?) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .meanSquaredError, reductionType: reductionType),
            linuxWeights: weights
        )
    }

    public class func softmaxCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        classCount: Int,
        weight: Float
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .softmaxCrossEntropy,
                reductionType: reductionType,
                weight: weight,
                labelSmoothing: labelSmoothing,
                classCount: classCount
            ),
            linuxWeights: nil
        )
    }

    public class func softmaxCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        classCount: Int,
        weights: MLCTensor?
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .softmaxCrossEntropy,
                reductionType: reductionType,
                weight: 1,
                labelSmoothing: labelSmoothing,
                classCount: classCount
            ),
            linuxWeights: weights
        )
    }

    public class func sigmoidCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        weight: Float
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .sigmoidCrossEntropy,
                reductionType: reductionType,
                weight: weight,
                labelSmoothing: labelSmoothing,
                classCount: 1
            ),
            linuxWeights: nil
        )
    }

    public class func sigmoidCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        weights: MLCTensor?
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .sigmoidCrossEntropy,
                reductionType: reductionType,
                weight: 1,
                labelSmoothing: labelSmoothing,
                classCount: 1
            ),
            linuxWeights: weights
        )
    }

    public class func categoricalCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        classCount: Int,
        weight: Float
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .categoricalCrossEntropy,
                reductionType: reductionType,
                weight: weight,
                labelSmoothing: labelSmoothing,
                classCount: classCount
            ),
            linuxWeights: nil
        )
    }

    public class func categoricalCrossEntropy(
        reductionType: MLCReductionType,
        labelSmoothing: Float,
        classCount: Int,
        weights: MLCTensor?
    ) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .categoricalCrossEntropy,
                reductionType: reductionType,
                weight: 1,
                labelSmoothing: labelSmoothing,
                classCount: classCount
            ),
            linuxWeights: weights
        )
    }

    public class func hingeLoss(reductionType: MLCReductionType, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .hinge, reductionType: reductionType, weight: weight),
            linuxWeights: nil
        )
    }

    public class func hingeLoss(reductionType: MLCReductionType, weights: MLCTensor?) -> Self {
        Self(linuxDescriptor: MLCLossDescriptor(type: .hinge, reductionType: reductionType), linuxWeights: weights)
    }

    public class func huberLoss(reductionType: MLCReductionType, delta: Float, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .huber,
                reductionType: reductionType,
                weight: weight,
                labelSmoothing: 0,
                classCount: 1,
                epsilon: 1e-7,
                delta: delta
            ),
            linuxWeights: nil
        )
    }

    public class func huberLoss(reductionType: MLCReductionType, delta: Float, weights: MLCTensor?) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .huber,
                reductionType: reductionType,
                weight: 1,
                labelSmoothing: 0,
                classCount: 1,
                epsilon: 1e-7,
                delta: delta
            ),
            linuxWeights: weights
        )
    }

    public class func cosineDistance(reductionType: MLCReductionType, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .cosineDistance, reductionType: reductionType, weight: weight),
            linuxWeights: nil
        )
    }

    public class func cosineDistance(reductionType: MLCReductionType, weights: MLCTensor?) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(type: .cosineDistance, reductionType: reductionType),
            linuxWeights: weights
        )
    }

    public class func log(reductionType: MLCReductionType, epsilon: Float, weight: Float) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .log,
                reductionType: reductionType,
                weight: weight,
                labelSmoothing: 0,
                classCount: 1,
                epsilon: epsilon,
                delta: 1
            ),
            linuxWeights: nil
        )
    }

    public class func log(reductionType: MLCReductionType, epsilon: Float, weights: MLCTensor?) -> Self {
        Self(
            linuxDescriptor: MLCLossDescriptor(
                type: .log,
                reductionType: reductionType,
                weight: 1,
                labelSmoothing: 0,
                classCount: 1,
                epsilon: epsilon,
                delta: 1
            ),
            linuxWeights: weights
        )
    }
}

open class MLCYOLOLossLayer: MLCLossLayer {
    public let yoloLossDescriptor: MLCYOLOLossDescriptor

    public init(descriptor lossDescriptor: MLCYOLOLossDescriptor) {
        self.yoloLossDescriptor = lossDescriptor
        super.init(
            linuxDescriptor: MLCLossDescriptor(type: .meanSquaredError, reductionType: .mean),
            linuxWeights: nil
        )
        label = "yoloLoss"
    }

    public required init(linuxDescriptor: MLCLossDescriptor, linuxWeights: MLCTensor?) {
        self.yoloLossDescriptor = MLCYOLOLossDescriptor(anchorBoxes: Data(), anchorBoxCount: 0)
        super.init(linuxDescriptor: linuxDescriptor, linuxWeights: linuxWeights)
    }
}
