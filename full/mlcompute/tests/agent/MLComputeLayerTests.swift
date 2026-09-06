import Foundation
import MLCompute

func testActivationLayerFactories() {
    let fromDesc = MLCActivationLayer(descriptor: MLCActivationDescriptor(type: .relu)!)
    precondition(fromDesc.descriptor.activationType == .relu)
    precondition(MLCActivationLayer.relu.descriptor.activationType == .relu)
    precondition(MLCActivationLayer.relu6.descriptor.a == 6)
    precondition(MLCActivationLayer.leakyReLU.descriptor.a == 0.01)
    precondition(MLCActivationLayer.leakyReLU(negativeSlope: 0.2).descriptor.a == 0.2)
    precondition(MLCActivationLayer.linear(scale: 2, bias: 1).descriptor.b == 1)
    precondition(MLCActivationLayer.sigmoid.descriptor.activationType == .sigmoid)
    precondition(MLCActivationLayer.hardSigmoid.descriptor.activationType == .hardSigmoid)
    precondition(MLCActivationLayer.tanh.descriptor.activationType == .tanh)
    precondition(MLCActivationLayer.absolute.descriptor.activationType == .absolute)
    precondition(MLCActivationLayer.softPlus.descriptor.activationType == .softPlus)
    precondition(MLCActivationLayer.softPlus(beta: 2).descriptor.a == 2)
    precondition(MLCActivationLayer.softSign.descriptor.activationType == .softSign)
    precondition(MLCActivationLayer.elu.descriptor.activationType == .elu)
    precondition(MLCActivationLayer.elu(a: 0.3).descriptor.a == 0.3)
    precondition(MLCActivationLayer.relun(a: 4, b: 1).descriptor.b == 1)
    precondition(MLCActivationLayer.logSigmoid.descriptor.activationType == .logSigmoid)
    precondition(MLCActivationLayer.selu.descriptor.activationType == .selu)
    precondition(MLCActivationLayer.celu.descriptor.activationType == .celu)
    precondition(MLCActivationLayer.celu(a: 1.5).descriptor.a == 1.5)
    precondition(MLCActivationLayer.hardShrink.descriptor.activationType == .hardShrink)
    precondition(MLCActivationLayer.hardShrink(a: 0.2).descriptor.a == 0.2)
    precondition(MLCActivationLayer.softShrink.descriptor.activationType == .softShrink)
    precondition(MLCActivationLayer.softShrink(a: 0.3).descriptor.a == 0.3)
    precondition(MLCActivationLayer.tanhShrink.descriptor.activationType == .tanhShrink)
    precondition(MLCActivationLayer.threshold(0.5, replacement: -1).descriptor.b == -1)
    precondition(MLCActivationLayer.gelu.descriptor.activationType == .gelu)
    precondition(MLCActivationLayer.hardSwish.descriptor.activationType == .hardSwish)
    precondition(MLCActivationLayer.clamp(min: -1, max: 1).descriptor.a == -1)
}

func testSimpleLayerConstruction() {
    let arithmetic = MLCArithmeticLayer(operation: .add)
    precondition(arithmetic.operation == .add)
    let comparison = MLCComparisonLayer(operation: .greater)
    precondition(comparison.operation == .greater)
    let concat = MLCConcatenationLayer()
    precondition(concat.dimension == 0)
    let concatDim = MLCConcatenationLayer(dimension: 1)
    precondition(concatDim.dimension == 1)
    let dropout = MLCDropoutLayer(rate: 0.5, seed: 7)
    precondition(dropout.rate == 0.5 && dropout.seed == 7)
    let gather = MLCGatherLayer(dimension: 1)
    precondition(gather.dimension == 1)
    let gram = MLCGramMatrixLayer(scale: 0.25)
    precondition(gram.scale == 0.25)
    let reshape = MLCReshapeLayer(shape: [2, 3])!
    precondition(reshape.shape == [2, 3])
    let transpose = MLCTransposeLayer(dimensions: [0, 2, 1])!
    precondition(transpose.dimensions == [0, 2, 1])
    let softmax = MLCSoftmaxLayer(operation: .softmax)
    precondition(softmax.dimension == 0)
    let softmaxDim = MLCSoftmaxLayer(operation: .logSoftmax, dimension: 1)
    precondition(softmaxDim.operation == .logSoftmax)
    let selection = MLCSelectionLayer()
    precondition(selection.label.contains("selection") || selection.layerID > 0)
    let slice = MLCSliceLayer(start: [0], end: [2], stride: [1])!
    precondition(slice.start == [0] && slice.end == [2] && slice.stride == [1])
    let split = MLCSplitLayer(splitCount: 2, dimension: 0)
    precondition(split.splitCount == 2 && split.dimension == 0)
    let splitLens = MLCSplitLayer(splitSectionLengths: [1, 3], dimension: 1)
    precondition(splitLens.splitSectionLengths == [1, 3])
    let scatter = MLCScatterLayer(dimension: 0, reductionType: .sum)!
    precondition(scatter.reductionType == .sum)
    let reduction = MLCReductionLayer(reductionType: .mean, dimension: 1)!
    precondition(reduction.dimension == 1)
    let reductionDims = MLCReductionLayer(reductionType: .sum, dimensions: [1, 2])!
    precondition(reductionDims.dimensions == [1, 2])
    let padZero = MLCPaddingLayer(zeroPadding: [1])
    precondition(padZero.paddingType == .zero)
    let padReflect = MLCPaddingLayer(reflectionPadding: [1, 2])
    precondition(padReflect.paddingType == .reflect)
    let padSym = MLCPaddingLayer(symmetricPadding: [1, 1, 1, 1])
    precondition(padSym.paddingType == .symmetric)
    let padConst = MLCPaddingLayer(constantPadding: [2], constantValue: 0.5)
    precondition(padConst.constantValue == 0.5)
    precondition(padConst.paddingLeft == 2)
    let upsample = MLCUpsampleLayer(shape: [8, 8])!
    precondition(upsample.sampleMode == .nearest)
    let upsampleMode = MLCUpsampleLayer(shape: [4, 4], sampleMode: .linear, alignsCorners: true)!
    precondition(upsampleMode.alignsCorners)
    let pool = MLCPoolingLayer(descriptor: MLCPoolingDescriptor(type: .max, kernelSizes: (2, 2)))
    precondition(pool.descriptor.poolingType == .max)
    let matmul = MLCMatMulLayer(descriptor: MLCMatMulDescriptor())!
    precondition(matmul.descriptor.alpha == 1)
}

func testLayerBaseProperties() {
    let layer = MLCArithmeticLayer(operation: .multiply)
    precondition(layer.layerID > 0)
    layer.label = "mul"
    precondition(layer.label == "mul")
    layer.isDebuggingEnabled = true
    precondition(layer.isDebuggingEnabled)
    precondition(layer.deviceType == .cpu)
    let cpu = MLCDevice.cpu()
    precondition(MLCLayer.supportsDataType(.float32, on: cpu))
    precondition(MLCLayer.supportsDataType(.int8, on: cpu))
}

func testWeightedLayerConstruction() {
    let weights = MLCTensor(shape: [4, 2], fillWithData: NSNumber(value: Float(0.1)), dataType: .float32)
    let biases = MLCTensor(shape: [4], fillWithData: NSNumber(value: Float(0)), dataType: .float32)
    let convDesc = MLCConvolutionDescriptor(
        kernelSizes: (1, 1),
        inputFeatureChannelCount: 2,
        outputFeatureChannelCount: 4
    )
    let conv = MLCConvolutionLayer(weights: weights, biases: biases, descriptor: convDesc)!
    precondition(conv.weights === weights)
    precondition(conv.biases === biases)
    precondition(conv.descriptor.outputFeatureChannelCount == 4)
    precondition(conv.weightsParameter.tensor === weights)
    precondition(conv.biasesParameter?.tensor === biases)
    let fc = MLCFullyConnectedLayer(weights: weights, biases: biases, descriptor: convDesc)!
    precondition(fc.weightsParameter.tensor === weights)
    let embedDesc = MLCEmbeddingDescriptor(embeddingCount: 5, embeddingDimension: 2)!
    let embedWeights = MLCTensor(shape: [5, 2])
    let embed = MLCEmbeddingLayer(descriptor: embedDesc, weights: embedWeights)
    precondition(embed.weightsParameter.tensor === embedWeights)
    let mean = MLCTensor(shape: [4], fillWithData: NSNumber(value: Float(0)), dataType: .float32)
    let variance = MLCTensor(shape: [4], fillWithData: NSNumber(value: Float(1)), dataType: .float32)
    let bn = MLCBatchNormalizationLayer(
        featureChannelCount: 4,
        mean: mean,
        variance: variance,
        beta: biases,
        gamma: biases,
        varianceEpsilon: 1e-5
    )!
    precondition(bn.momentum == 0.99)
    let bn2 = MLCBatchNormalizationLayer(
        featureChannelCount: 4,
        mean: mean,
        variance: variance,
        beta: nil,
        gamma: nil,
        varianceEpsilon: 1e-5,
        momentum: 0.9
    )!
    precondition(bn2.momentum == 0.9)
    precondition(bn.featureChannelCount == 4)
    precondition(bn.betaParameter != nil)
    let inst = MLCInstanceNormalizationLayer(
        featureChannelCount: 4,
        beta: biases,
        gamma: biases,
        varianceEpsilon: 1e-5
    )!
    precondition(inst.gammaParameter != nil)
    let inst2 = MLCInstanceNormalizationLayer(
        featureChannelCount: 4,
        beta: nil,
        gamma: nil,
        varianceEpsilon: 1e-5,
        momentum: 0.8
    )!
    precondition(inst2.momentum == 0.8)
    let inst3 = MLCInstanceNormalizationLayer(
        featureChannelCount: 4,
        mean: mean,
        variance: variance,
        beta: nil,
        gamma: nil,
        varianceEpsilon: 1e-5,
        momentum: 0.7
    )!
    precondition(inst3.mean === mean)
    let group = MLCGroupNormalizationLayer(
        featureChannelCount: 4,
        groupCount: 2,
        beta: biases,
        gamma: biases,
        varianceEpsilon: 1e-5
    )!
    precondition(group.groupCount == 2)
    let ln = MLCLayerNormalizationLayer(
        normalizedShape: [4],
        beta: biases,
        gamma: biases,
        varianceEpsilon: 1e-5
    )!
    precondition(ln.normalizedShape == [4])
    let lnOpt = MLCLayerNormalizationLayer(
        normalizedShape: [4],
        beta: Optional(biases),
        gamma: Optional(biases),
        varianceEpsilon: 1e-5
    )!
    precondition(lnOpt.varianceEpsilon == 1e-5)
}

func testLSTMAndAttentionLayers() {
    let descriptor = MLCLSTMDescriptor(inputSize: 2, hiddenSize: 2, layerCount: 1)
    let tensors = (0..<4).map { _ in MLCTensor(shape: [2, 2]) }
    let lstm = MLCLSTMLayer(descriptor: descriptor, inputWeights: tensors, hiddenWeights: tensors, biases: tensors)!
    precondition(lstm.inputWeights.count == 4)
    precondition(lstm.gateActivations.count == 4)
    precondition(lstm.outputResultActivation.activationType == .tanh)
    precondition(lstm.inputWeightsParameters.count == 4)
    precondition(lstm.hiddenWeightsParameters.count == 4)
    let lstm2 = MLCLSTMLayer(
        descriptor: descriptor,
        inputWeights: tensors,
        hiddenWeights: tensors,
        peepholeWeights: tensors,
        biases: tensors
    )!
    precondition(lstm2.peepholeWeights?.count == 4)
    let lstm3 = MLCLSTMLayer(
        descriptor: descriptor,
        inputWeights: tensors,
        hiddenWeights: tensors,
        peepholeWeights: nil,
        biases: tensors,
        gateActivations: lstm.gateActivations,
        outputResultActivation: lstm.outputResultActivation
    )!
    precondition(lstm3.biasesParameters?.count == 4)
    let attnDesc = MLCMultiheadAttentionDescriptor(modelDimension: 4, headCount: 2)
    let weights = (0..<4).map { _ in MLCTensor(shape: [4, 4]) }
    let attn = MLCMultiheadAttentionLayer(
        descriptor: attnDesc,
        weights: weights,
        biases: weights,
        attentionBiases: nil
    )!
    precondition(attn.weightsParameters.count == 4)
    precondition(attn.biasesParameters?.count == 4)
}

func testLossLayerFactories() {
    let descriptor = MLCLossDescriptor(type: .meanSquaredError, reductionType: .mean)
    let layer = MLCLossLayer(descriptor: descriptor)
    precondition(layer.descriptor.lossType == .meanSquaredError)
    let weights = MLCTensor(shape: [1], fillWithData: NSNumber(value: Float(1)), dataType: .float32)
    let weighted = MLCLossLayer(descriptor: descriptor, weights: weights)
    precondition(weighted.weights === weights)
    precondition(MLCLossLayer.meanAbsoluteError(reductionType: .mean, weight: 1).descriptor.lossType == .meanAbsoluteError)
    precondition(MLCLossLayer.meanAbsoluteError(reductionType: .sum, weights: weights).weights === weights)
    precondition(MLCLossLayer.meanSquaredError(reductionType: .mean, weight: 1).descriptor.lossType == .meanSquaredError)
    precondition(MLCLossLayer.meanSquaredError(reductionType: .none, weights: nil).weights == nil)
    precondition(MLCLossLayer.softmaxCrossEntropy(reductionType: .mean, labelSmoothing: 0, classCount: 3, weight: 1).descriptor.classCount == 3)
    precondition(MLCLossLayer.softmaxCrossEntropy(reductionType: .mean, labelSmoothing: 0, classCount: 3, weights: weights).weights === weights)
    precondition(MLCLossLayer.sigmoidCrossEntropy(reductionType: .mean, labelSmoothing: 0, weight: 1).descriptor.lossType == .sigmoidCrossEntropy)
    precondition(MLCLossLayer.sigmoidCrossEntropy(reductionType: .mean, labelSmoothing: 0, weights: nil).weights == nil)
    precondition(MLCLossLayer.categoricalCrossEntropy(reductionType: .mean, labelSmoothing: 0, classCount: 2, weight: 1).descriptor.classCount == 2)
    precondition(MLCLossLayer.categoricalCrossEntropy(reductionType: .mean, labelSmoothing: 0, classCount: 2, weights: weights).weights === weights)
    precondition(MLCLossLayer.hingeLoss(reductionType: .sum, weight: 0.5).descriptor.weight == 0.5)
    precondition(MLCLossLayer.hingeLoss(reductionType: .sum, weights: weights).weights === weights)
    precondition(MLCLossLayer.huberLoss(reductionType: .mean, delta: 0.2, weight: 1).descriptor.delta == 0.2)
    precondition(MLCLossLayer.huberLoss(reductionType: .mean, delta: 0.2, weights: nil).descriptor.delta == 0.2)
    precondition(MLCLossLayer.cosineDistance(reductionType: .mean, weight: 1).descriptor.lossType == .cosineDistance)
    precondition(MLCLossLayer.cosineDistance(reductionType: .mean, weights: weights).weights === weights)
    precondition(MLCLossLayer.log(reductionType: .mean, epsilon: 1e-6, weight: 1).descriptor.epsilon == 1e-6)
    precondition(MLCLossLayer.log(reductionType: .mean, epsilon: 1e-6, weights: nil).descriptor.lossType == .log)
    let yolo = MLCYOLOLossLayer(descriptor: MLCYOLOLossDescriptor(anchorBoxes: Data(count: 8), anchorBoxCount: 1))
    precondition(yolo.yoloLossDescriptor.anchorBoxCount == 1)
}
