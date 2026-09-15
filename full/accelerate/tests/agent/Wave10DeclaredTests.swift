import Accelerate
import Foundation

// Wave 10 declared-remainder conversion: oracle-pinned BNNS overlay mappings
// (macOS 26.1 / Xcode 26.1 `xcrun swiftc` probes, September 2026) plus
// fail-closed no-op applies for NearestNeighbors and the vImage
// MultidimensionalLookupTable. Every precondition below executes real Linux
// behavior; no test uses DispatchQueue.main, RunLoop, semaphores, or await.

func testWave10ActivationMapping() {
    let relu = BNNS.ActivationFunction.rectifiedLinear.bnnsActivation
    precondition(relu.function.rawValue == 1)
    precondition(relu.function == BNNSActivationFunctionRectifiedLinear)
    let ident = BNNS.ActivationFunction.identity.bnnsActivation
    precondition(ident.function.rawValue == 0)
    let tanh = BNNS.ActivationFunction.tanh.bnnsActivation
    precondition(tanh.function.rawValue == 4)
    let scaled = BNNS.ActivationFunction.scaledTanh(alpha: 1, beta: 2).bnnsActivation
    precondition(scaled.function.rawValue == 5 && scaled.alpha == 1 && scaled.beta == 2)
    let abs = BNNS.ActivationFunction.abs.bnnsActivation
    precondition(abs.function.rawValue == 6)
    let clamped = BNNS.ActivationFunction.clamp(bounds: 0...1).bnnsActivation
    precondition(clamped.function.rawValue == 8 && clamped.alpha == 0 && clamped.beta == 1)
    let sm = BNNS.ActivationFunction.softmax.bnnsActivation
    precondition(sm.function.rawValue == 11)
    let gelu = BNNS.ActivationFunction.geluApproximation(alpha: 1, beta: 2).bnnsActivation
    precondition(gelu.function.rawValue == 12 && gelu.alpha == 1 && gelu.beta == 2)
    let hs = BNNS.ActivationFunction.hardSigmoid(alpha: 1, beta: 2).bnnsActivation
    precondition(hs.function.rawValue == 15)
    let elu = BNNS.ActivationFunction.elu(alpha: 1).bnnsActivation
    precondition(elu.function.rawValue == 18 && elu.alpha == 1)
    let leaky = BNNS.ActivationFunction.leakyRectifiedLinear(alpha: 0.1).bnnsActivation
    precondition(leaky.function.rawValue == 2 && leaky.alpha == 0.1)
    let silu = BNNS.ActivationFunction.silu.bnnsActivation
    precondition(silu.function.rawValue == 31)
}

func testWave10ArithmeticMapping() {
    let abs = BNNS.ArithmeticUnaryFunction.abs.bnnsArithmeticFunction
    precondition(abs == BNNSArithmeticAbs && abs.rawValue == 32)
    precondition(BNNS.ArithmeticUnaryFunction.reciprocal.bnnsArithmeticFunction.rawValue == 35)
    precondition(BNNS.ArithmeticUnaryFunction.squareRoot.bnnsArithmeticFunction.rawValue == 4)
    precondition(BNNS.ArithmeticUnaryFunction.exp.bnnsArithmeticFunction.rawValue == 22)
    precondition(BNNS.ArithmeticUnaryFunction.negate.bnnsArithmeticFunction.rawValue == 34)
    precondition(BNNS.ArithmeticUnaryFunction.square.bnnsArithmeticFunction.rawValue == 36)
    precondition(BNNS.ArithmeticUnaryFunction.floor.bnnsArithmeticFunction.rawValue == 7)
    precondition(BNNS.ArithmeticUnaryFunction.sign.bnnsArithmeticFunction.rawValue == 33)
    let ma = BNNS.ArithmeticTernaryFunction.multiplyAdd.bnnsArithmeticFunction
    precondition(ma == BNNSArithmeticMultiplyAdd && ma.rawValue == 28)
}

func testWave10PaddingMapping() {
    let scalar = BNNS.PaddingMode.constantScalar(1.0)
    precondition(scalar.bnnsPaddingMode == BNNSPaddingModeConstant)
    precondition(scalar.bnnsPaddingMode.rawValue == 0)
    precondition(scalar.paddingBitPattern == Float(1.0).bitPattern)
    let bits = BNNS.PaddingMode.constantBitPattern(123)
    precondition(bits.bnnsPaddingMode.rawValue == 0)
    precondition(bits.paddingBitPattern == 123)
    precondition(BNNS.PaddingMode.reflect.bnnsPaddingMode == BNNSPaddingModeReflect)
    precondition(BNNS.PaddingMode.reflect.paddingBitPattern == 0)
    precondition(BNNS.PaddingMode.symmetric.bnnsPaddingMode.rawValue == 2)
    precondition(BNNS.PaddingMode.symmetric.paddingBitPattern == 0)
}

func testWave10PoolingMapping() {
    precondition(BNNS.PoolingType.max().bnnsPoolingFunction == BNNSPoolingFunctionMax)
    precondition(BNNS.PoolingType.maxEx().bnnsPoolingFunction.rawValue == 0)
    precondition(BNNS.PoolingType.unMax().bnnsPoolingFunction == BNNSPoolingFunctionUnMax)
    precondition(BNNS.PoolingType.l2Norm.bnnsPoolingFunction == BNNSPoolingFunctionL2Norm)
    precondition(BNNS.PoolingType.average(countIncludesPadding: true).bnnsPoolingFunction == BNNSPoolingFunctionAverageCountIncludePadding)
    precondition(BNNS.PoolingType.average(countIncludesPadding: false).bnnsPoolingFunction == BNNSPoolingFunctionAverageCountExcludePadding)
}

func testWave10LossMapping() {
    precondition(BNNS.LossFunction.cosineDistance.bnnsLossFunction == BNNSLossFunctionCosineDistance)
    precondition(BNNS.LossFunction.meanSquareError.bnnsLossFunction.rawValue == 3)
    precondition(BNNS.LossFunction.meanAbsoluteError.bnnsLossFunction.rawValue == 9)
    precondition(BNNS.LossFunction.sigmoidCrossEntropy(labelSmoothing: 0).bnnsLossFunction.rawValue == 2)
    precondition(BNNS.LossFunction.softmaxCrossEntropy(labelSmoothing: 0).bnnsLossFunction.rawValue == 1)
    precondition(BNNS.LossFunction.categoricalCrossEntropy.bnnsLossFunction.rawValue == 10)
    precondition(BNNS.LossFunction.hinge.bnnsLossFunction.rawValue == 8)
    precondition(BNNS.LossFunction.huber(huberDelta: 1).bnnsLossFunction.rawValue == 4)
    precondition(BNNS.LossFunction.log.bnnsLossFunction.rawValue == 6)
    precondition(BNNS.LossReduction.weightedMean.bnnsLossReductionFunction == BNNSLossReductionWeightedMean)
    precondition(BNNS.LossReduction.reductionMean.bnnsLossReductionFunction.rawValue == 3)
    precondition(BNNS.LossReduction.zeroWeightMean.bnnsLossReductionFunction.rawValue == 4)
    precondition(BNNS.LossReduction.sum.bnnsLossReductionFunction == BNNSLossReductionSum)
    precondition(BNNS.LossReduction.none.bnnsLossReductionFunction == BNNSLossReductionNone)
}

func testWave10ReductionMapping() {
    precondition(BNNS.ReductionFunction.max.bnnsReduceFunction == BNNSReduceFunctionMax)
    precondition(BNNS.ReductionFunction.min.bnnsReduceFunction.rawValue == 1)
    precondition(BNNS.ReductionFunction.sum.bnnsReduceFunction == BNNSReduceFunctionSum)
    precondition(BNNS.ReductionFunction.mean.bnnsReduceFunction.rawValue == 4)
    precondition(BNNS.ReductionFunction.sumOfSquares.bnnsReduceFunction == BNNSReduceFunctionSumSquare)
    precondition(BNNS.ReductionFunction.sumOfAbsolutes.bnnsReduceFunction == BNNSReduceFunctionL1Norm)
    precondition(BNNS.ReductionFunction.product.bnnsReduceFunction.rawValue == 14)
    precondition(BNNS.ReductionFunction.l2Norm.bnnsReduceFunction.rawValue == 12)
    precondition(BNNS.ReductionFunction.logSumExp.bnnsReduceFunction.rawValue == 13)
    precondition(BNNS.ReductionFunction.sumOfLogs(epsilon: 0.1).bnnsReduceFunction == BNNSReduceFunctionSumLog)
    precondition(BNNS.ReductionFunction.all.bnnsReduceFunction.rawValue == 11)
    precondition(BNNS.ReductionFunction.any.bnnsReduceFunction.rawValue == 10)
}

func testWave10OptimizerMappingA() {
    let adam = BNNS.AdamOptimizer(timeStep: 1, gradientScale: 1, regularizationScale: 0, gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1)
    precondition(adam.bnnsOptimizerFunction == BNNSOptimizerFunctionAdamWithClipping)
    precondition(adam.bnnsOptimizerFunction.rawValue == 8)
    precondition(adam.accumulatorCountMultiplier == 2)
    let adamW = BNNS.AdamWOptimizer(gradientScale: 1, gradientClipping: .none)
    precondition(adamW.bnnsOptimizerFunction == BNNSOptimizerFunctionAdamWWithClipping)
    precondition(adamW.bnnsOptimizerFunction.rawValue == 10)
    precondition(adamW.accumulatorCountMultiplier == 2)
}

func testWave10OptimizerMappingB() {
    let rms = BNNS.RMSPropOptimizer(centered: false, gradientScale: 1, regularizationScale: 0, gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1)
    precondition(rms.bnnsOptimizerFunction == BNNSOptimizerFunctionRMSPropWithClipping)
    precondition(rms.bnnsOptimizerFunction.rawValue == 9)
    precondition(rms.accumulatorCountMultiplier == 1)
    let rmsC = BNNS.RMSPropOptimizer(centered: true, gradientScale: 1, regularizationScale: 0, gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1)
    precondition(rmsC.accumulatorCountMultiplier == 2)
    let sgd = BNNS.SGDMomentumOptimizer(learningRate: 0.01, gradientScale: 1, regularizationScale: 0, gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1, sgdMomentumVariant: BNNSOptimizerSGDMomentumVariant(rawValue: 0))
    precondition(sgd.bnnsOptimizerFunction == BNNSOptimizerFunctionSGDMomentumWithClipping)
    precondition(sgd.bnnsOptimizerFunction.rawValue == 7)
    precondition(sgd.accumulatorCountMultiplier == 0)
}

func testWave10NeighborLUTApply() {
    let nn = BNNS.NearestNeighbors(capacity: 4, dimensionCount: 2, neighborCount: 1, dataType: BNNSDataTypeFloat32)
    let idx = BNNSNDArrayDescriptor()
    let dist = BNNSNDArrayDescriptor()
    nn.apply(index: nil, outputIndices: idx, outputDistances: dist)
    nn.apply(index: 0, outputIndices: idx, outputDistances: dist)
    let lut = vImage.MultidimensionalLookupTable(entryCountPerSourceChannel: [2, 2], destinationChannelCount: 1, data: [UInt16]([0, 1, 2, 3]))
    let src = vImage.PixelBuffer<vImage.PlanarF>(pixelValues: [Float]([0.5]), size: vImage.Size(width: 1, height: 1))
    let dst = vImage.PixelBuffer<vImage.PlanarF>(pixelValues: [Float]([0]), size: vImage.Size(width: 1, height: 1))
    lut.apply(sources: [src], destinations: [dst], interpolation: .full)
    let src2 = vImage.PixelBuffer<vImage.PlanarFx2>(pixelValues: [Float]([0.5, 0.5]), size: vImage.Size(width: 1, height: 1))
    let dst2 = vImage.PixelBuffer<vImage.PlanarFx2>(pixelValues: [Float]([0, 0]), size: vImage.Size(width: 1, height: 1))
    lut.apply(source: src2, destination: dst2, interpolation: .half)
    _ = idx; _ = dist
}
