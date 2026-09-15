import Accelerate
import Foundation

// Swift overlay remainder B: BNNS optimizers, layer classes, fused parameter
// structs, relational operators, and function enums. Trap-on-read state is
// referenced by keypath only; Apple-side layer/optimizer designated inits and
// graph apply methods keep their deferred rows.

func testOvRemBOptimizers() {
    _ = BNNS.AdamWOptimizer.self
    var adamW = BNNS.AdamWOptimizer()
    adamW.weightDecay = 0.01
    adamW.learningRate = 0.001
    adamW.gradientScale = 1.0
    adamW.gradientClipping = .none
    adamW.beta1 = 0.9
    adamW.beta2 = 0.999
    adamW.epsilon = 1e-8
    adamW.timeStep = 1.0
    _ = \BNNS.AdamWOptimizer.weightDecay
    _ = \BNNS.AdamWOptimizer.learningRate
    _ = \BNNS.AdamWOptimizer.gradientScale
    _ = \BNNS.AdamWOptimizer.gradientClipping
    _ = \BNNS.AdamWOptimizer.bnnsOptimizerFunction
    _ = \BNNS.AdamWOptimizer.accumulatorCountMultiplier
    _ = \BNNS.AdamWOptimizer.timeStep
    _ = BNNS.RMSPropOptimizer.self
    var rms = BNNS.RMSPropOptimizer()
    rms.learningRate = 0.01
    rms.alpha = 0.99
    rms.epsilon = 1e-8
    rms.centered = true
    rms.momentum = 0.5
    rms.gradientScale = 1.0
    rms.gradientBounds = 0.0...1.0
    rms.gradientClipping = .byNorm(threshold: 1.0)
    rms.regularizationScale = 0.001
    rms.regularizationFunction = BNNSOptimizerRegularizationL1
    _ = \BNNS.RMSPropOptimizer.bnnsOptimizerFunction
    _ = \BNNS.RMSPropOptimizer.learningRate
    _ = \BNNS.RMSPropOptimizer.gradientScale
    _ = \BNNS.RMSPropOptimizer.gradientBounds
    _ = \BNNS.RMSPropOptimizer.gradientClipping
    _ = \BNNS.RMSPropOptimizer.regularizationScale
    _ = \BNNS.RMSPropOptimizer.regularizationFunction
    _ = \BNNS.RMSPropOptimizer.accumulatorCountMultiplier
    _ = BNNS.SGDMomentumOptimizer.self
    var sgd = BNNS.SGDMomentumOptimizer()
    sgd.learningRate = 0.01
    sgd.momentum = 0.9
    sgd.gradientScale = 1.0
    sgd.gradientBounds = nil
    sgd.gradientClipping = .none
    sgd.sgdMomentumVariant = BNNSOptimizerSGDMomentumVariant(rawValue: 0)
    sgd.regularizationScale = 0.0
    sgd.usesNestrovMomentum = false
    sgd.usesNesterovMomentum = true
    sgd.regularizationFunction = BNNSOptimizerRegularizationL1
    _ = \BNNS.SGDMomentumOptimizer.bnnsOptimizerFunction
    _ = \BNNS.SGDMomentumOptimizer.learningRate
    _ = \BNNS.SGDMomentumOptimizer.gradientScale
    _ = \BNNS.SGDMomentumOptimizer.gradientBounds
    _ = \BNNS.SGDMomentumOptimizer.gradientClipping
    _ = \BNNS.SGDMomentumOptimizer.sgdMomentumVariant
    _ = \BNNS.SGDMomentumOptimizer.regularizationScale
    _ = \BNNS.SGDMomentumOptimizer.usesNestrovMomentum
    _ = \BNNS.SGDMomentumOptimizer.usesNesterovMomentum
    _ = \BNNS.SGDMomentumOptimizer.regularizationFunction
    _ = \BNNS.SGDMomentumOptimizer.accumulatorCountMultiplier
    _ = adamW
    _ = rms
    _ = sgd
}

func testOvRemBLayers() {
    _ = BNNS.Layer.self
    _ = BNNS.Layer()
    _ = \BNNS.Layer.bnnsFilter
    _ = BNNS.EmbeddingLayer.self
    _ = BNNS.EmbeddingLayer()
    _ = BNNS.ReductionLayer.self
    _ = BNNS.ReductionLayer()
    _ = BNNS.ActivationLayer.self
    _ = BNNS.ActivationLayer()
    _ = BNNS.ConvolutionLayer.self
    _ = BNNS.ConvolutionLayer()
    _ = BNNS.NormalizationLayer.self
    _ = BNNS.NormalizationLayer()
    _ = BNNS.FullyConnectedLayer.self
    _ = BNNS.FullyConnectedLayer()
    _ = BNNS.GramLayer.self
    _ = BNNS.GramLayer()
    _ = BNNS.LossLayer.self
    _ = BNNS.LossLayer()
    _ = BNNS.TernaryArithmeticLayer.self
    _ = BNNS.TernaryArithmeticLayer()
    _ = BNNS.BroadcastMatrixMultiplyLayer.self
    _ = BNNS.BroadcastMatrixMultiplyLayer()
    _ = BNNS.FusedParametersLayer.self
    _ = BNNS.FusedParametersLayer()
    _ = BNNS.FusedConvolutionNormalizationLayer.self
    _ = BNNS.FusedConvolutionNormalizationLayer()
    _ = BNNS.FusedFullyConnectedNormalizationLayer.self
    _ = BNNS.FusedFullyConnectedNormalizationLayer()
    _ = BNNS.CropResizeLayer.self
    _ = BNNS.RandomGenerator.self
    _ = \BNNS.RandomGenerator.state
    _ = BNNS.RandomGeneratorState.self
    _ = BNNS.RandomGeneratorState()
    _ = BNNS.NearestNeighbors.self
    _ = BNNS.NearestNeighbors()
}

func testOvRemBFusedParams() {
    _ = BNNS.FusedConvolutionParameters.self
    _ = \BNNS.FusedConvolutionParameters.type
    _ = \BNNS.FusedConvolutionParameters.weights
    _ = \BNNS.FusedConvolutionParameters.padding
    _ = \BNNS.FusedConvolutionParameters.dilationStride
    _ = \BNNS.FusedConvolutionParameters.groupSize
    _ = BNNS.FusedQuantizationParameters.self
    _ = \BNNS.FusedQuantizationParameters.scale
    _ = \BNNS.FusedQuantizationParameters.bias
    _ = BNNS.FusedNormalizationParameters.self
    _ = \BNNS.FusedNormalizationParameters.type
    _ = BNNS.FusedDequantizationParameters.self
    _ = \BNNS.FusedDequantizationParameters.scale
    _ = \BNNS.FusedDequantizationParameters.bias
    _ = BNNS.FusedFullyConnectedParameters.self
    _ = \BNNS.FusedFullyConnectedParameters.weights
    _ = \BNNS.FusedFullyConnectedParameters.bias
    _ = BNNS.FusedUnaryArithmeticParameters.self
    _ = \BNNS.FusedUnaryArithmeticParameters.function
    _ = BNNS.FusedBinaryArithmeticParameters.self
    _ = \BNNS.FusedBinaryArithmeticParameters.function
    _ = BNNS.FusedTernaryArithmeticParameters.self
    _ = \BNNS.FusedTernaryArithmeticParameters.function
    _ = \BNNS.FusedTernaryArithmeticParameters.inputCDescriptorType
    _ = BNNS.SparseParameters.self
    _ = \BNNS.SparseParameters.type
    _ = \BNNS.SparseParameters.ratio
    _ = \BNNS.SparseParameters.targetSystem
    _ = BNNS.Shape.ArrayLiteralElement.self
    precondition(BNNS.Shape.ArrayLiteralElement.self == Int.self)
}

func testOvRemBRelational() {
    _ = BNNS.RelationalOperator.self
}

func testOvRemBFunctions() {
    _ = \BNNS.ReductionFunction.bnnsReduceFunction
    _ = BNNS.ReductionFunction.sum
    _ = \BNNS.ActivationFunction.bnnsActivation
    _ = BNNS.ActivationFunction.abs
    _ = \BNNS.ArithmeticUnaryFunction.bnnsArithmeticFunction
    _ = BNNS.ArithmeticUnaryFunction.AllCases.self
    _ = BNNS.ArithmeticUnaryFunction.allCases
    precondition(BNNS.ArithmeticUnaryFunction.allCases.count == 27)
    _ = BNNS.ArithmeticBinaryFunction.AllCases.self
    _ = BNNS.ArithmeticBinaryFunction.allCases
    precondition(BNNS.ArithmeticBinaryFunction.allCases.count == 12)
    _ = \BNNS.ArithmeticTernaryFunction.bnnsArithmeticFunction
    _ = vDSP.self
    _ = vDSP.RoundingMode.self
    _ = vDSP.RoundingMode.towardZero
    _ = vDSP.RoundingMode.towardNearestInteger
}
