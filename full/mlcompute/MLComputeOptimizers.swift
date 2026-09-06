import Foundation

open class MLCOptimizer: NSObject, NSCopying {
    public var learningRate: Float
    public let gradientRescale: Float
    public var appliesGradientClipping: Bool
    public let gradientClipMax: Float
    public let gradientClipMin: Float
    public let regularizationScale: Float
    public let regularizationType: MLCRegularizationType
    public let gradientClippingType: MLCGradientClippingType
    public let maximumClippingNorm: Float
    public let customGlobalNorm: Float

    public init(descriptor: MLCOptimizerDescriptor) {
        self.learningRate = descriptor.learningRate
        self.gradientRescale = descriptor.gradientRescale
        self.appliesGradientClipping = descriptor.appliesGradientClipping
        self.gradientClipMax = descriptor.gradientClipMax
        self.gradientClipMin = descriptor.gradientClipMin
        self.regularizationScale = descriptor.regularizationScale
        self.regularizationType = descriptor.regularizationType
        self.gradientClippingType = descriptor.gradientClippingType
        self.maximumClippingNorm = descriptor.maximumClippingNorm
        self.customGlobalNorm = descriptor.customGlobalNorm
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let descriptor = MLCOptimizerDescriptor(
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
        return MLCOptimizer(descriptor: descriptor)
    }
}

open class MLCAdamOptimizer: MLCOptimizer {
    public let beta1: Float
    public let beta2: Float
    public let epsilon: Float
    public let timeStep: Int
    public let usesAMSGrad: Bool

    public override convenience init(descriptor: MLCOptimizerDescriptor) {
        self.init(
            descriptor: descriptor,
            beta1: 0.9,
            beta2: 0.999,
            epsilon: 1e-8,
            usesAMSGrad: false,
            timeStep: 1
        )
    }

    public convenience init(
        descriptor optimizerDescriptor: MLCOptimizerDescriptor,
        beta1: Float,
        beta2: Float,
        epsilon: Float,
        timeStep: Int
    ) {
        self.init(
            descriptor: optimizerDescriptor,
            beta1: beta1,
            beta2: beta2,
            epsilon: epsilon,
            usesAMSGrad: false,
            timeStep: timeStep
        )
    }

    public init(
        descriptor optimizerDescriptor: MLCOptimizerDescriptor,
        beta1: Float,
        beta2: Float,
        epsilon: Float,
        usesAMSGrad: Bool,
        timeStep: Int
    ) {
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
        self.usesAMSGrad = usesAMSGrad
        self.timeStep = timeStep
        super.init(descriptor: optimizerDescriptor)
    }
}

open class MLCAdamWOptimizer: MLCOptimizer {
    public let beta1: Float
    public let beta2: Float
    public let epsilon: Float
    public let timeStep: Int
    public let usesAMSGrad: Bool

    public override convenience init(descriptor: MLCOptimizerDescriptor) {
        self.init(
            descriptor: descriptor,
            beta1: 0.9,
            beta2: 0.999,
            epsilon: 1e-8,
            usesAMSGrad: false,
            timeStep: 1
        )
    }

    public init(
        descriptor optimizerDescriptor: MLCOptimizerDescriptor,
        beta1: Float,
        beta2: Float,
        epsilon: Float,
        usesAMSGrad: Bool,
        timeStep: Int
    ) {
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
        self.usesAMSGrad = usesAMSGrad
        self.timeStep = timeStep
        super.init(descriptor: optimizerDescriptor)
    }
}

open class MLCSGDOptimizer: MLCOptimizer {
    public let momentumScale: Float
    public let usesNesterovMomentum: Bool

    public override convenience init(descriptor: MLCOptimizerDescriptor) {
        self.init(descriptor: descriptor, momentumScale: 0, usesNesterovMomentum: false)
    }

    public init(
        descriptor optimizerDescriptor: MLCOptimizerDescriptor,
        momentumScale: Float,
        usesNesterovMomentum: Bool
    ) {
        self.momentumScale = momentumScale
        self.usesNesterovMomentum = usesNesterovMomentum
        super.init(descriptor: optimizerDescriptor)
    }
}

open class MLCRMSPropOptimizer: MLCOptimizer {
    public let momentumScale: Float
    public let alpha: Float
    public let epsilon: Float
    public let isCentered: Bool

    public override convenience init(descriptor: MLCOptimizerDescriptor) {
        self.init(
            descriptor: descriptor,
            momentumScale: 0,
            alpha: 0.99,
            epsilon: 1e-8,
            isCentered: false
        )
    }

    public init(
        descriptor optimizerDescriptor: MLCOptimizerDescriptor,
        momentumScale: Float,
        alpha: Float,
        epsilon: Float,
        isCentered: Bool
    ) {
        self.momentumScale = momentumScale
        self.alpha = alpha
        self.epsilon = epsilon
        self.isCentered = isCentered
        super.init(descriptor: optimizerDescriptor)
    }
}
