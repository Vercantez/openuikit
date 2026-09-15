import Accelerate
import Foundation

// Wave 9 remainder: Apple-designated BNNS overlay initializers and fail-closed
// layer apply paths. Value-type inits (optimizers, fused parameters, Yolo,
// sparse, nearest-neighbor, crop-resize, lookup table) store their inputs on
// Linux; layer inits without a BNNS runtime return nil; layer apply methods
// and graph context creation throw fail-closed errors. Every function below
// is top-level, synchronous, and takes no arguments.

private func _remDescriptor() -> BNNSNDArrayDescriptor {
    BNNSNDArrayDescriptor()
}

private func _expectLayerApplyFail(_ body: () throws -> Void) {
    do {
        try body()
        preconditionFailure("BNNS layer apply unexpectedly succeeded without a runtime")
    } catch let e as BNNS.Error {
        precondition(e == .layerApplyFail)
    } catch {
        preconditionFailure("unexpected BNNS layer apply error")
    }
}

func testBNNSRemOptimizerInits() {
    let adam = BNNS.AdamOptimizer(
        timeStep: 2, gradientScale: 1, regularizationScale: 0.5,
        gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1)
    precondition(adam.learningRate == 0.001)
    precondition(adam.beta1 == 0.9 && adam.beta2 == 0.999)
    precondition(adam.timeStep == 2 && adam.epsilon == 1e-8)
    precondition(adam.gradientBounds == nil && adam.usesAMSGrad == false)
    let adam2 = BNNS.AdamOptimizer(
        learningRate: 0.01, beta1: 0.85, beta2: 0.99, timeStep: 3,
        epsilon: 1e-7, gradientScale: 2, regularizationScale: 0.1,
        clipsGradientsTo: 0.0...1.0, regularizationFunction: BNNSOptimizerRegularizationL2)
    precondition(adam2.gradientBounds == 0.0...1.0)
    guard case .byValue = adam2.gradientClipping else { preconditionFailure("adam bounds clipping not stored") }
    let adamW = BNNS.AdamWOptimizer(
        gradientScale: 1, gradientClipping: .none, usesAMSGrad: true)
    precondition(adamW.learningRate == 0.001 && adamW.timeStep == 1)
    precondition(adamW.weightDecay == 1e-2 && adamW.usesAMSGrad == true)
    let rms = BNNS.RMSPropOptimizer(
        centered: true, gradientScale: 1, regularizationScale: 0.2,
        gradientClipping: .byNorm(threshold: 1), regularizationFunction: BNNSOptimizerRegularizationL1)
    precondition(rms.learningRate == 1e-2 && rms.alpha == 0.99 && rms.centered == true)
    precondition(rms.momentum == 0 && rms.gradientBounds == nil)
    let rms2 = BNNS.RMSPropOptimizer(
        learningRate: 0.02, alpha: 0.9, epsilon: 1e-6, centered: false,
        momentum: 0.5, gradientScale: 2, regularizationScale: 0.3,
        regularizationFunction: BNNSOptimizerRegularizationNone)
    precondition(rms2.momentum == 0.5 && rms2.centered == false)
    let sgd = BNNS.SGDMomentumOptimizer(
        learningRate: 0.05, gradientScale: 1, regularizationScale: 0.1,
        gradientClipping: .none, regularizationFunction: BNNSOptimizerRegularizationL1,
        sgdMomentumVariant: BNNSOptimizerSGDMomentumVariant(rawValue: 0))
    precondition(sgd.momentum == 0 && sgd.usesNesterovMomentum == false)
    let sgd2 = BNNS.SGDMomentumOptimizer(
        learningRate: 0.05, momentum: 0.9, gradientScale: 1, regularizationScale: 0.1,
        usesNestrovMomentum: true, regularizationFunction: BNNSOptimizerRegularizationL1,
        sgdMomentumVariant: BNNSOptimizerSGDMomentumVariant(rawValue: 0))
    precondition(sgd2.usesNestrovMomentum == true && sgd2.gradientBounds == nil)
    let sgd3 = BNNS.SGDMomentumOptimizer(
        learningRate: 0.05, momentum: 0.9, gradientScale: 1, regularizationScale: 0.1,
        clipsGradientsTo: 0.0...2.0, usesNesterovMomentum: true,
        regularizationFunction: BNNSOptimizerRegularizationL2,
        sgdMomentumVariant: BNNSOptimizerSGDMomentumVariant(rawValue: 0))
    precondition(sgd3.gradientBounds == 0.0...2.0 && sgd3.usesNesterovMomentum == true)
}

func testBNNSRemFusedParamInits() {
    let conv = BNNS.FusedConvolutionParameters(
        type: .standard, weights: _remDescriptor(), bias: nil,
        stride: (x: 1, y: 1), dilationStride: (x: 2, y: 2),
        groupSize: 2, padding: .zero)
    precondition(conv.groupSize == 2 && conv.type == .standard)
    precondition(conv.dilationStride == (x: 2, y: 2) && conv.bias == nil)
    let quant = BNNS.FusedQuantizationParameters(scale: nil, bias: nil)
    precondition(quant.scale == nil && quant.bias == nil)
    let norm = BNNS.FusedNormalizationParameters(
        type: .group(groupCount: 2), momentum: 0.9, epsilon: 1e-5, activation: .identity)
    precondition(norm.momentum == 0.9 && norm.epsilon == 1e-5)
    precondition(norm.beta == nil && norm.gamma == nil)
    let dequant = BNNS.FusedDequantizationParameters(scale: nil, bias: _remDescriptor())
    precondition(dequant.scale == nil && dequant.bias != nil)
    let fc = BNNS.FusedFullyConnectedParameters(weights: _remDescriptor(), bias: nil)
    precondition(fc.bias == nil)
    _ = fc.weights
    let unary = BNNS.FusedUnaryArithmeticParameters(
        inputDescriptorType: .sample, outputDescriptorType: .parameter, function: .abs)
    precondition(unary.function == .abs && unary.inputDescriptorType == .sample)
    let binary = BNNS.FusedBinaryArithmeticParameters(
        inputADescriptorType: .sample, inputBDescriptorType: .constant,
        outputDescriptorType: .parameter, function: .add)
    precondition(binary.function == .add && binary.inputBDescriptorType == .constant)
    let ternary = BNNS.FusedTernaryArithmeticParameters(
        inputADescriptorType: .sample, inputBDescriptorType: .sample,
        inputCDescriptorType: .parameter, outputDescriptorType: .sample,
        function: .multiplyAdd)
    precondition(ternary.function == .multiplyAdd)
    precondition(ternary.inputCDescriptorType == .parameter)
}

func testBNNSRemValueInits() {
    var anchors: [Float] = [0.5, 1.5]
    anchors.withUnsafeMutableBufferPointer { ptr in
        let yolo = BNNS.LossFunction.YoloParameters(
            huberDelta: 0.5, gridColumnCount: 13, gridRowsCount: 13,
            anchorBoxCount: 5, anchorBoxSize: 3, rescore: true,
            xyScale: 1, whScale: 1, objectScale: 1, noObjectScale: 0.5,
            classificationScale: 1, objectMinimumIoU: 0.5,
            noObjectMaximumIoU: 0.4,
            anchorsData: ptr.baseAddress!)
        precondition(yolo.huberDelta == 0.5 && yolo.gridColumnCount == 13)
        precondition(yolo.anchorBoxCount == 5 && yolo.rescore == true)
        precondition(yolo.anchorsData[0] == 0.5 && yolo.anchorsData[1] == 1.5)
    }
    let sparse = BNNS.SparseParameters(
        ratio: (numerator: 1, denominator: 2),
        targetSystem: BNNSTargetSystem(rawValue: 0))
    precondition(sparse.type == .unstructured)
    precondition(sparse.ratio == (numerator: 1, denominator: 2))
    let neighbors = BNNS.NearestNeighbors(
        capacity: 4, dimensionCount: 2, neighborCount: 1, dataType: BNNSDataTypeFloat32)
    precondition(neighbors.capacity == 4 && neighbors.dimensionCount == 2)
    precondition(neighbors.neighborCount == 1)
    precondition(neighbors.dataType == BNNSDataTypeFloat32)
    let crop = BNNS.CropResizeLayer(
        coordinatesAreNormalized: true, spatialScale: 2,
        boxCoordinateMode: .cornersWidthFirst)
    precondition(crop.coordinatesAreNormalized == true && crop.spatialScale == 2)
    precondition(crop.extrapolationValue == 0)
    let table = vImage.MultidimensionalLookupTable(
        entryCountPerSourceChannel: [2], destinationChannelCount: 1,
        data: [UInt16](repeating: 7, count: 2))
    precondition(table.sourceChannelCount == 1)
    precondition(table.destinationChannelCount == 1)
    precondition(table.entryCountPerSourceChannel == [2])
    precondition(table.tableData == [7, 7])
}

func testBNNSRemLayerInitsA() {
    let d = _remDescriptor()
    precondition(BNNS.ResizeLayer(
        interpolationMethod: .linear, input: d, output: d,
        alignsCorners: true) == nil)
    precondition(BNNS.DropoutLayer(
        input: d, output: d, rate: 0.5, seed: 7, control: 0) == nil)
    precondition(BNNS.PaddingLayer(
        input: d, output: d, mode: .symmetric, size: [(x: 1, y: 1)]) == nil)
    precondition(BNNS.PermuteLayer(
        input: d, output: d, permutation: [0]) == nil)
    precondition(BNNS.PoolingLayer(
        type: .l2Norm, input: d, output: d, bias: nil, activation: .identity,
        kernelSize: (width: 2, height: 2), stride: (x: 1, y: 1),
        padding: .zero) == nil)
    precondition(BNNS.EmbeddingLayer(
        input: d, output: d, dictionary: d, paddingIndex: 0,
        maximumNorm: 1, normType: .l2,
        scalesGradientByFrequency: false) == nil)
    precondition(BNNS.ReductionLayer(
        function: .sum, input: d, output: d, weights: nil) == nil)
    precondition(BNNS.ActivationLayer(
        function: .identity, input: d, output: d) == nil)
    precondition(BNNS.ActivationLayer(
        function: .rectifiedLinear, axes: [0], input: d, output: d) == nil)
    precondition(BNNS.ConvolutionLayer(
        type: .standard, input: d, weights: d, output: d, bias: nil,
        padding: .zero, activation: .identity, groupCount: 1,
        stride: (x: 1, y: 1), dilationStride: (x: 1, y: 1)) == nil)
    precondition(BNNS.NormalizationLayer(
        type: .group(groupCount: 1), input: d, output: d,
        beta: d, gamma: d, epsilon: 1e-5, activation: .identity) == nil)
}

func testBNNSRemLayerInitsB() {
    let d = _remDescriptor()
    precondition(BNNS.FullyConnectedLayer(
        input: d, output: d, weights: d, bias: nil,
        activation: .identity) == nil)
    precondition(BNNS.FusedParametersLayer(
        input: d, output: d, fusedLayerParameters: []) == nil)
    precondition(BNNS.FusedParametersLayer(
        inputA: d, inputB: d, inputC: d, output: d,
        fusedLayerParameters: []) == nil)
    precondition(BNNS.FusedParametersLayer(
        inputA: d, inputB: d, output: d,
        fusedLayerParameters: []) == nil)
    precondition(BNNS.TernaryArithmeticLayer(
        inputA: d, inputADescriptorType: .sample,
        inputB: d, inputBDescriptorType: .sample,
        inputC: d, inputCDescriptorType: .sample,
        output: d, outputDescriptorType: .sample,
        function: .multiplyAdd) == nil)
    precondition(BNNS.BroadcastMatrixMultiplyLayer(
        inputA: d, transposed: false, isWeights: false,
        inputB: d, transposed: false, isWeights: false,
        output: d, alpha: 1, accumulatesToOutput: false,
        isQuadratic: false) == nil)
    precondition(BNNS.FusedConvolutionNormalizationLayer(
        input: d, output: d, convolutionWeights: d, convolutionBias: nil,
        convolutionStride: (x: 1, y: 1),
        convolutionDilationStride: (x: 1, y: 1),
        convolutionPadding: .zero, normalization: .group(groupCount: 1),
        normalizationBeta: d, normalizationGamma: d,
        normalizationMomentum: 0, normalizationEpsilon: 1e-5,
        normalizationActivation: .identity) == nil)
    precondition(BNNS.FusedFullyConnectedNormalizationLayer(
        input: d, output: d, fullyConnectedWeights: d,
        fullyConnectedBias: nil, normalization: .group(groupCount: 1),
        normalizationBeta: d, normalizationGamma: d,
        normalizationMomentum: 0, normalizationEpsilon: 1e-5,
        normalizationActivation: .identity) == nil)
    precondition(BNNS.GramLayer(input: d, output: d, alpha: 1) == nil)
    precondition(BNNS.LossLayer(
        input: d, output: d, lossFunction: .meanSquareError,
        lossReduction: .sum) == nil)
    precondition(BNNS.RandomGenerator(method: .aesCtr) == nil)
}

func testBNNSRemLayerApplies() {
    let d = _remDescriptor()
    _expectLayerApplyFail { try BNNS.FusedLayer().apply(batchSize: 1, input: d, output: d, for: .inference) }
    _expectLayerApplyFail { try BNNS.UnaryLayer().apply(batchSize: 1, input: d, output: d) }
    _expectLayerApplyFail { try BNNS.BinaryLayer().apply(batchSize: 1, inputA: d, inputB: d, output: d) }
    _expectLayerApplyFail { try BNNS.PoolingLayer().apply(batchSize: 1, input: d, output: d) }
    _expectLayerApplyFail { try BNNS.EmbeddingLayer().apply(batchSize: 1, input: d, output: d) }
    _expectLayerApplyFail { try BNNS.CropResizeLayer().apply(input: d, regionOfInterest: d, output: d) }
    _expectLayerApplyFail { try BNNS.NormalizationLayer().apply(batchSize: 1, input: d, output: d, for: .training) }
    _expectLayerApplyFail {
        try BNNS.FusedParametersLayer().apply(
            batchSize: 1, inputA: d, inputB: d, inputC: d, output: d, for: .inference)
    }
    _expectLayerApplyFail {
        try BNNS.FusedParametersLayer().apply(
            batchSize: 1, inputA: d, inputB: d, output: d, for: .inference)
    }
    _expectLayerApplyFail {
        try BNNS.TernaryArithmeticLayer().apply(
            batchSize: 1, inputA: d, inputB: d, inputC: d, output: d)
    }
    _expectLayerApplyFail {
        try BNNS.BroadcastMatrixMultiplyLayer().apply(
            batchSize: 1, inputA: d, inputB: d, output: d)
    }
    _expectLayerApplyFail {
        try BNNS.LossLayer().apply(
            batchSize: 1, input: d, labels: d, output: d, generatingInputGradient: d)
    }
    _expectLayerApplyFail {
        try BNNS.LossLayer().apply(
            batchSize: 1, input: d, labels: d, output: d, weights: nil,
            broadcastsWeights: false, generatingInputGradient: d)
    }
}

func testBNNSRemGraphContext() {
    _ = BNNSGraph.Context.self
    do {
        _ = try BNNSGraph.Context(compileFromPath: "/nonexistent-graph")
        preconditionFailure("graph context creation unexpectedly succeeded without a runtime")
    } catch let e as BNNSGraph.Error {
        precondition(e == .unableToCreateContext)
    } catch {
        preconditionFailure("unexpected graph context error")
    }
}
