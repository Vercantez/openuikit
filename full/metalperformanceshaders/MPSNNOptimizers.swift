import Foundation

open class MPSNNOptimizerDescriptor: NSObject {
    public var learningRate: Float
    public var gradientRescale: Float
    public var applyGradientClipping: Bool
    public var gradientClipMax: Float
    public var gradientClipMin: Float
    public var regularizationType: MPSNNRegularizationType
    public var regularizationScale: Float

    public init(
        learningRate: Float,
        gradientRescale: Float,
        regularizationType: MPSNNRegularizationType,
        regularizationScale: Float
    ) {
        self.learningRate = learningRate
        self.gradientRescale = gradientRescale
        self.applyGradientClipping = false
        self.gradientClipMax = 1
        self.gradientClipMin = -1
        self.regularizationType = regularizationType
        self.regularizationScale = regularizationScale
        super.init()
    }

    public init(
        learningRate: Float,
        gradientRescale: Float,
        applyGradientClipping: Bool,
        gradientClipMax: Float,
        gradientClipMin: Float,
        regularizationType: MPSNNRegularizationType,
        regularizationScale: Float
    ) {
        self.learningRate = learningRate
        self.gradientRescale = gradientRescale
        self.applyGradientClipping = applyGradientClipping
        self.gradientClipMax = gradientClipMax
        self.gradientClipMin = gradientClipMin
        self.regularizationType = regularizationType
        self.regularizationScale = regularizationScale
        super.init()
    }
}

open class MPSNNOptimizer: MPSKernel {
    public private(set) var learningRate: Float
    public private(set) var gradientRescale: Float
    public var applyGradientClipping: Bool
    public private(set) var gradientClipMax: Float
    public private(set) var gradientClipMin: Float
    public private(set) var regularizationType: MPSNNRegularizationType
    public private(set) var regularizationScale: Float

    public required init(device: any MTLDevice) {
        self.learningRate = 0.001
        self.gradientRescale = 1
        self.applyGradientClipping = false
        self.gradientClipMax = 1
        self.gradientClipMin = -1
        self.regularizationType = .None
        self.regularizationScale = 0
        super.init(device: device)
    }

    public init(device: any MTLDevice, optimizerDescriptor: MPSNNOptimizerDescriptor) {
        self.learningRate = optimizerDescriptor.learningRate
        self.gradientRescale = optimizerDescriptor.gradientRescale
        self.applyGradientClipping = optimizerDescriptor.applyGradientClipping
        self.gradientClipMax = optimizerDescriptor.gradientClipMax
        self.gradientClipMin = optimizerDescriptor.gradientClipMin
        self.regularizationType = optimizerDescriptor.regularizationType
        self.regularizationScale = optimizerDescriptor.regularizationScale
        super.init(device: device)
    }

    open func setLearningRate(_ newLearningRate: Float) {
        learningRate = newLearningRate
    }
}

func mpsHostApplyClipAndRegularization(
    gradient: Float,
    value: Float,
    rescale: Float,
    clip: Bool,
    clipMax: Float,
    clipMin: Float,
    regularizationType: MPSNNRegularizationType,
    regularizationScale: Float
) -> Float {
    var g = gradient * rescale
    if clip {
        g = min(max(g, clipMin), clipMax)
    }
    switch regularizationType {
    case .L1:
        g += regularizationScale * (value >= 0 ? 1 : -1)
    case .L2:
        g += regularizationScale * value
    default:
        break
    }
    return g
}

func mpsHostVectorPointer(_ vector: MPSVector) -> UnsafeMutablePointer<Float> {
    vector.data.contents.advanced(by: vector.offset).bindMemory(to: Float.self, capacity: max(vector.length, 1))
}

func mpsHostMatrixPointer(_ matrix: MPSMatrix) -> UnsafeMutablePointer<Float> {
    let floats = max(matrix.rowBytes / 4 * matrix.rows, matrix.rows * matrix.columns)
    return matrix.data.contents.advanced(by: matrix.offset).bindMemory(to: Float.self, capacity: max(floats, 1))
}

open class MPSNNOptimizerAdam: MPSNNOptimizer {
    public private(set) var beta1: Double
    public private(set) var beta2: Double
    public private(set) var epsilon: Float
    public var timeStep: Int

    public init(device: any MTLDevice, learningRate: Float) {
        self.beta1 = 0.9
        self.beta2 = 0.999
        self.epsilon = 1e-8
        self.timeStep = 0
        super.init(
            device: device,
            optimizerDescriptor: MPSNNOptimizerDescriptor(
                learningRate: learningRate,
                gradientRescale: 1,
                regularizationType: .None,
                regularizationScale: 0
            )
        )
    }

    public init(
        device: any MTLDevice,
        beta1: Double,
        beta2: Double,
        epsilon: Float,
        timeStep: Int,
        optimizerDescriptor: MPSNNOptimizerDescriptor
    ) {
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
        self.timeStep = timeStep
        super.init(device: device, optimizerDescriptor: optimizerDescriptor)
    }

    public required init(device: any MTLDevice) {
        self.beta1 = 0.9
        self.beta2 = 0.999
        self.epsilon = 1e-8
        self.timeStep = 0
        super.init(device: device)
    }

    private func applyAdam(
        count: Int,
        gradient: UnsafePointer<Float>,
        values: UnsafePointer<Float>,
        momentum: UnsafeMutablePointer<Float>,
        velocity: UnsafeMutablePointer<Float>,
        maximumVelocity: UnsafeMutablePointer<Float>?,
        result: UnsafeMutablePointer<Float>
    ) {
        timeStep += 1
        let t = max(timeStep, 1)
        let b1 = Float(beta1)
        let b2 = Float(beta2)
        let corr1 = 1 - Float(pow(beta1, Double(t)))
        let corr2 = 1 - Float(pow(beta2, Double(t)))
        for index in 0..<count {
            let g = mpsHostApplyClipAndRegularization(
                gradient: gradient[index],
                value: values[index],
                rescale: gradientRescale,
                clip: applyGradientClipping,
                clipMax: gradientClipMax,
                clipMin: gradientClipMin,
                regularizationType: regularizationType,
                regularizationScale: regularizationScale
            )
            momentum[index] = b1 * momentum[index] + (1 - b1) * g
            velocity[index] = b2 * velocity[index] + (1 - b2) * g * g
            let mHat = momentum[index] / max(corr1, 1e-12)
            let vHat = velocity[index] / max(corr2, 1e-12)
            var step = learningRate * mHat / (sqrt(vHat) + epsilon)
            if let maximumVelocity {
                let cap = abs(maximumVelocity[index])
                if cap > 0 {
                    step = min(max(step, -cap), cap)
                }
            }
            result[index] = values[index] - step
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientVector: MPSVector,
        inputValuesVector: MPSVector,
        inputMomentumVector: MPSVector,
        inputVelocityVector: MPSVector,
        resultValuesVector: MPSVector
    ) {
        encode(
            commandBuffer: commandBuffer,
            inputGradientVector: inputGradientVector,
            inputValuesVector: inputValuesVector,
            inputMomentumVector: inputMomentumVector,
            inputVelocityVector: inputVelocityVector,
            maximumVelocityVector: nil,
            resultValuesVector: resultValuesVector
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientVector: MPSVector,
        inputValuesVector: MPSVector,
        inputMomentumVector: MPSVector,
        inputVelocityVector: MPSVector,
        maximumVelocityVector: MPSVector?,
        resultValuesVector: MPSVector
    ) {
        _ = commandBuffer
        precondition(inputGradientVector.dataType == .float32)
        let count = min(inputGradientVector.length, inputValuesVector.length, resultValuesVector.length)
        applyAdam(
            count: count,
            gradient: mpsHostVectorPointer(inputGradientVector),
            values: mpsHostVectorPointer(inputValuesVector),
            momentum: mpsHostVectorPointer(inputMomentumVector),
            velocity: mpsHostVectorPointer(inputVelocityVector),
            maximumVelocity: maximumVelocityVector.map { mpsHostVectorPointer($0) },
            result: mpsHostVectorPointer(resultValuesVector)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientMatrix: MPSMatrix,
        inputValuesMatrix: MPSMatrix,
        inputMomentumMatrix: MPSMatrix,
        inputVelocityMatrix: MPSMatrix,
        resultValuesMatrix: MPSMatrix
    ) {
        encode(
            commandBuffer: commandBuffer,
            inputGradientMatrix: inputGradientMatrix,
            inputValuesMatrix: inputValuesMatrix,
            inputMomentumMatrix: inputMomentumMatrix,
            inputVelocityMatrix: inputVelocityMatrix,
            maximumVelocityMatrix: nil,
            resultValuesMatrix: resultValuesMatrix
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientMatrix: MPSMatrix,
        inputValuesMatrix: MPSMatrix,
        inputMomentumMatrix: MPSMatrix,
        inputVelocityMatrix: MPSMatrix,
        maximumVelocityMatrix: MPSMatrix?,
        resultValuesMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        precondition(inputGradientMatrix.dataType == .float32)
        let count = min(
            inputGradientMatrix.rows * inputGradientMatrix.columns,
            inputValuesMatrix.rows * inputValuesMatrix.columns,
            resultValuesMatrix.rows * resultValuesMatrix.columns
        )
        applyAdam(
            count: count,
            gradient: mpsHostMatrixPointer(inputGradientMatrix),
            values: mpsHostMatrixPointer(inputValuesMatrix),
            momentum: mpsHostMatrixPointer(inputMomentumMatrix),
            velocity: mpsHostMatrixPointer(inputVelocityMatrix),
            maximumVelocity: maximumVelocityMatrix.map { mpsHostMatrixPointer($0) },
            result: mpsHostMatrixPointer(resultValuesMatrix)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        convolutionGradientState: MPSCNNConvolutionGradientState,
        convolutionSourceState: MPSCNNConvolutionWeightsAndBiasesState,
        inputMomentumVectors: [MPSVector]?,
        inputVelocityVectors: [MPSVector]?,
        resultState: MPSCNNConvolutionWeightsAndBiasesState
    ) {
        _ = (commandBuffer, convolutionGradientState, convolutionSourceState, inputMomentumVectors, inputVelocityVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerAdam.encode(convolution:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        convolutionGradientState: MPSCNNConvolutionGradientState,
        convolutionSourceState: MPSCNNConvolutionWeightsAndBiasesState,
        inputMomentumVectors: [MPSVector],
        inputVelocityVectors: [MPSVector],
        maximumVelocityVectors: [MPSVector]?,
        resultState: MPSCNNConvolutionWeightsAndBiasesState
    ) {
        _ = maximumVelocityVectors
        encode(
            commandBuffer: commandBuffer,
            convolutionGradientState: convolutionGradientState,
            convolutionSourceState: convolutionSourceState,
            inputMomentumVectors: inputMomentumVectors,
            inputVelocityVectors: inputVelocityVectors,
            resultState: resultState
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector]?,
        inputVelocityVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationState, inputMomentumVectors, inputVelocityVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerAdam.encode(batchNorm:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector],
        inputVelocityVectors: [MPSVector],
        maximumVelocityVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = maximumVelocityVectors
        encode(
            commandBuffer: commandBuffer,
            batchNormalizationState: batchNormalizationState,
            inputMomentumVectors: inputMomentumVectors,
            inputVelocityVectors: inputVelocityVectors,
            resultState: resultState
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationGradientState: MPSCNNBatchNormalizationState,
        batchNormalizationSourceState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector]?,
        inputVelocityVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationGradientState, batchNormalizationSourceState, inputMomentumVectors, inputVelocityVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerAdam.encode(batchNormGradient:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationGradientState: MPSCNNBatchNormalizationState,
        batchNormalizationSourceState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector],
        inputVelocityVectors: [MPSVector],
        maximumVelocityVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = maximumVelocityVectors
        encode(
            commandBuffer: commandBuffer,
            batchNormalizationGradientState: batchNormalizationGradientState,
            batchNormalizationSourceState: batchNormalizationSourceState,
            inputMomentumVectors: inputMomentumVectors,
            inputVelocityVectors: inputVelocityVectors,
            resultState: resultState
        )
    }
}

open class MPSNNOptimizerStochasticGradientDescent: MPSNNOptimizer {
    public private(set) var momentumScale: Float
    public private(set) var useNesterovMomentum: Bool
    public var useNestrovMomentum: Bool {
        useNesterovMomentum
    }

    public init(device: any MTLDevice, learningRate: Float) {
        self.momentumScale = 0
        self.useNesterovMomentum = false
        super.init(
            device: device,
            optimizerDescriptor: MPSNNOptimizerDescriptor(
                learningRate: learningRate,
                gradientRescale: 1,
                regularizationType: .None,
                regularizationScale: 0
            )
        )
    }

    public init(
        device: any MTLDevice,
        momentumScale: Float,
        useNesterovMomentum: Bool,
        optimizerDescriptor: MPSNNOptimizerDescriptor
    ) {
        self.momentumScale = momentumScale
        self.useNesterovMomentum = useNesterovMomentum
        super.init(device: device, optimizerDescriptor: optimizerDescriptor)
    }

    public init(
        device: any MTLDevice,
        momentumScale: Float,
        useNestrovMomentum: Bool,
        optimizerDescriptor: MPSNNOptimizerDescriptor
    ) {
        self.momentumScale = momentumScale
        self.useNesterovMomentum = useNestrovMomentum
        super.init(device: device, optimizerDescriptor: optimizerDescriptor)
    }

    public required init(device: any MTLDevice) {
        self.momentumScale = 0
        self.useNesterovMomentum = false
        super.init(device: device)
    }

    private func applySGD(
        count: Int,
        gradient: UnsafePointer<Float>,
        values: UnsafePointer<Float>,
        momentum: UnsafeMutablePointer<Float>?,
        result: UnsafeMutablePointer<Float>
    ) {
        for index in 0..<count {
            let g = mpsHostApplyClipAndRegularization(
                gradient: gradient[index],
                value: values[index],
                rescale: gradientRescale,
                clip: applyGradientClipping,
                clipMax: gradientClipMax,
                clipMin: gradientClipMin,
                regularizationType: regularizationType,
                regularizationScale: regularizationScale
            )
            if let momentum, momentumScale != 0 {
                momentum[index] = momentumScale * momentum[index] + g
                if useNesterovMomentum {
                    result[index] = values[index] - learningRate * (g + momentumScale * momentum[index])
                } else {
                    result[index] = values[index] - learningRate * momentum[index]
                }
            } else {
                result[index] = values[index] - learningRate * g
            }
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientVector: MPSVector,
        inputValuesVector: MPSVector,
        inputMomentumVector: MPSVector?,
        resultValuesVector: MPSVector
    ) {
        _ = commandBuffer
        precondition(inputGradientVector.dataType == .float32)
        let count = min(inputGradientVector.length, inputValuesVector.length, resultValuesVector.length)
        applySGD(
            count: count,
            gradient: mpsHostVectorPointer(inputGradientVector),
            values: mpsHostVectorPointer(inputValuesVector),
            momentum: inputMomentumVector.map { mpsHostVectorPointer($0) },
            result: mpsHostVectorPointer(resultValuesVector)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientMatrix: MPSMatrix,
        inputValuesMatrix: MPSMatrix,
        inputMomentumMatrix: MPSMatrix?,
        resultValuesMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        precondition(inputGradientMatrix.dataType == .float32)
        let count = min(
            inputGradientMatrix.rows * inputGradientMatrix.columns,
            inputValuesMatrix.rows * inputValuesMatrix.columns,
            resultValuesMatrix.rows * resultValuesMatrix.columns
        )
        applySGD(
            count: count,
            gradient: mpsHostMatrixPointer(inputGradientMatrix),
            values: mpsHostMatrixPointer(inputValuesMatrix),
            momentum: inputMomentumMatrix.map { mpsHostMatrixPointer($0) },
            result: mpsHostMatrixPointer(resultValuesMatrix)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        convolutionGradientState: MPSCNNConvolutionGradientState,
        convolutionSourceState: MPSCNNConvolutionWeightsAndBiasesState,
        inputMomentumVectors: [MPSVector]?,
        resultState: MPSCNNConvolutionWeightsAndBiasesState
    ) {
        _ = (commandBuffer, convolutionGradientState, convolutionSourceState, inputMomentumVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerSGD.encode(convolution:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationState, inputMomentumVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerSGD.encode(batchNorm:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationGradientState: MPSCNNBatchNormalizationState,
        batchNormalizationSourceState: MPSCNNBatchNormalizationState,
        inputMomentumVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationGradientState, batchNormalizationSourceState, inputMomentumVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerSGD.encode(batchNormGradient:)")
    }
}

open class MPSNNOptimizerRMSProp: MPSNNOptimizer {
    public private(set) var decay: Double
    public private(set) var epsilon: Float

    public init(device: any MTLDevice, learningRate: Float) {
        self.decay = 0.9
        self.epsilon = 1e-8
        super.init(
            device: device,
            optimizerDescriptor: MPSNNOptimizerDescriptor(
                learningRate: learningRate,
                gradientRescale: 1,
                regularizationType: .None,
                regularizationScale: 0
            )
        )
    }

    public init(
        device: any MTLDevice,
        decay: Double,
        epsilon: Float,
        optimizerDescriptor: MPSNNOptimizerDescriptor
    ) {
        self.decay = decay
        self.epsilon = epsilon
        super.init(device: device, optimizerDescriptor: optimizerDescriptor)
    }

    public required init(device: any MTLDevice) {
        self.decay = 0.9
        self.epsilon = 1e-8
        super.init(device: device)
    }

    private func applyRMSProp(
        count: Int,
        gradient: UnsafePointer<Float>,
        values: UnsafePointer<Float>,
        sumOfSquares: UnsafeMutablePointer<Float>,
        result: UnsafeMutablePointer<Float>
    ) {
        let decayF = Float(decay)
        for index in 0..<count {
            let g = mpsHostApplyClipAndRegularization(
                gradient: gradient[index],
                value: values[index],
                rescale: gradientRescale,
                clip: applyGradientClipping,
                clipMax: gradientClipMax,
                clipMin: gradientClipMin,
                regularizationType: regularizationType,
                regularizationScale: regularizationScale
            )
            sumOfSquares[index] = decayF * sumOfSquares[index] + (1 - decayF) * g * g
            result[index] = values[index] - learningRate * g / (sqrt(sumOfSquares[index]) + epsilon)
        }
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientVector: MPSVector,
        inputValuesVector: MPSVector,
        inputSumOfSquaresVector: MPSVector,
        resultValuesVector: MPSVector
    ) {
        _ = commandBuffer
        precondition(inputGradientVector.dataType == .float32)
        let count = min(inputGradientVector.length, inputValuesVector.length, resultValuesVector.length)
        applyRMSProp(
            count: count,
            gradient: mpsHostVectorPointer(inputGradientVector),
            values: mpsHostVectorPointer(inputValuesVector),
            sumOfSquares: mpsHostVectorPointer(inputSumOfSquaresVector),
            result: mpsHostVectorPointer(resultValuesVector)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputGradientMatrix: MPSMatrix,
        inputValuesMatrix: MPSMatrix,
        inputSumOfSquaresMatrix: MPSMatrix,
        resultValuesMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        precondition(inputGradientMatrix.dataType == .float32)
        let count = min(
            inputGradientMatrix.rows * inputGradientMatrix.columns,
            inputValuesMatrix.rows * inputValuesMatrix.columns,
            resultValuesMatrix.rows * resultValuesMatrix.columns
        )
        applyRMSProp(
            count: count,
            gradient: mpsHostMatrixPointer(inputGradientMatrix),
            values: mpsHostMatrixPointer(inputValuesMatrix),
            sumOfSquares: mpsHostMatrixPointer(inputSumOfSquaresMatrix),
            result: mpsHostMatrixPointer(resultValuesMatrix)
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        convolutionGradientState: MPSCNNConvolutionGradientState,
        convolutionSourceState: MPSCNNConvolutionWeightsAndBiasesState,
        inputSumOfSquaresVectors: [MPSVector]?,
        resultState: MPSCNNConvolutionWeightsAndBiasesState
    ) {
        _ = (commandBuffer, convolutionGradientState, convolutionSourceState, inputSumOfSquaresVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerRMSProp.encode(convolution:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationState: MPSCNNBatchNormalizationState,
        inputSumOfSquaresVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationState, inputSumOfSquaresVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerRMSProp.encode(batchNorm:)")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        batchNormalizationGradientState: MPSCNNBatchNormalizationState,
        batchNormalizationSourceState: MPSCNNBatchNormalizationState,
        inputSumOfSquaresVectors: [MPSVector]?,
        resultState: MPSCNNNormalizationGammaAndBetaState
    ) {
        _ = (commandBuffer, batchNormalizationGradientState, batchNormalizationSourceState, inputSumOfSquaresVectors, resultState)
        MPSHostBoundary.refuseGPUEncode("MPSNNOptimizerRMSProp.encode(batchNormGradient:)")
    }
}
