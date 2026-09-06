import Foundation
import MLCompute

func testActivationDescriptorDefaults() {
    let relu = MLCActivationDescriptor(type: .relu)!
    precondition(relu.activationType == .relu)
    precondition(relu.a == 0)
    let linear = MLCActivationDescriptor(type: .linear, a: 2)!
    precondition(linear.a == 2)
    precondition(linear.b == 0)
    let pair = MLCActivationDescriptor(type: .elu, a: 0.5, b: 1)!
    precondition(pair.a == 0.5)
    let full = MLCActivationDescriptor(type: .clamp, a: -1, b: 2, c: 0)!
    precondition(full.b == 2)
    let copy = relu.copy() as! MLCActivationDescriptor
    precondition(copy.activationType == .relu)
    precondition(relu.linuxHostApply(-2) == 0)
    precondition(abs(MLCActivationDescriptor(type: .sigmoid)!.linuxHostApply(0) - 0.5) < 0.0001)
    let selu = MLCActivationDescriptor(type: .selu)!
    precondition(abs(selu.a - 1.6732632) < 0.0001)
}

func testConvolutionDescriptorGeometry() {
    let standard = MLCConvolutionDescriptor(
        kernelSizes: (height: 3, width: 3),
        inputFeatureChannelCount: 4,
        outputFeatureChannelCount: 8
    )
    precondition(standard.convolutionType == .standard)
    precondition(standard.kernelSizes.height == 3)
    precondition(standard.inputFeatureChannelCount == 4)
    precondition(standard.outputFeatureChannelCount == 8)
    precondition(standard.groupCount == 1)
    precondition(standard.strides.x == 1)
    precondition(standard.dilationRates.y == 1)
    precondition(standard.paddingPolicy == .same)
    precondition(standard.isConvolutionTranspose == false)
    precondition(standard.usesDepthwiseConvolution == false)
    let spatial = standard.linuxOutputSpatial(inputHeight: 8, inputWidth: 8)
    precondition(spatial.0 == 8 && spatial.1 == 8)
    let transpose = MLCConvolutionDescriptor(
        transposeWithKernelWidth: 2,
        kernelHeight: 2,
        inputFeatureChannelCount: 3,
        outputFeatureChannelCount: 6
    )
    precondition(transpose.isConvolutionTranspose)
    let depthwise = MLCConvolutionDescriptor(
        depthwiseWithKernelWidth: 3,
        kernelHeight: 3,
        inputFeatureChannelCount: 8,
        channelMultiplier: 2
    )
    precondition(depthwise.usesDepthwiseConvolution)
    precondition(depthwise.outputFeatureChannelCount == 16)
    precondition(depthwise.groupCount == 8)
    let copy = standard.copy() as! MLCConvolutionDescriptor
    precondition(copy.outputFeatureChannelCount == 8)
}

func testPoolingDescriptorValues() {
    let descriptor = MLCPoolingDescriptor(
        type: .max,
        kernelSizes: (height: 2, width: 2),
        strides: (y: 2, x: 2)
    )
    precondition(descriptor.poolingType == .max)
    precondition(descriptor.kernelSizes.width == 2)
    precondition(descriptor.strides.y == 2)
    precondition(descriptor.dilationRates.x == 1)
    precondition(descriptor.paddingPolicy == .same)
    let copy = descriptor.copy() as! MLCPoolingDescriptor
    precondition(copy.kernelSizes.height == 2)
}

func testLossDescriptorValues() {
    let basic = MLCLossDescriptor(type: .meanSquaredError, reductionType: .mean)
    precondition(basic.lossType == .meanSquaredError)
    precondition(basic.reductionType == .mean)
    precondition(basic.weight == 1)
    let weighted = MLCLossDescriptor(type: .hinge, reductionType: .sum, weight: 0.5)
    precondition(weighted.weight == 0.5)
    let smooth = MLCLossDescriptor(
        type: .softmaxCrossEntropy,
        reductionType: .mean,
        weight: 1,
        labelSmoothing: 0.1,
        classCount: 10
    )
    precondition(smooth.classCount == 10)
    precondition(smooth.labelSmoothing == 0.1)
    let full = MLCLossDescriptor(
        type: .huber,
        reductionType: .none,
        weight: 1,
        labelSmoothing: 0,
        classCount: 1,
        epsilon: 1e-5,
        delta: 0.25
    )
    precondition(full.delta == 0.25)
    precondition(full.epsilon == 1e-5)
    let copy = basic.copy() as! MLCLossDescriptor
    precondition(copy.lossType == .meanSquaredError)
}

func testOptimizerDescriptorValues() {
    let basic = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    precondition(basic.learningRate == 0.01)
    precondition(basic.gradientRescale == 1)
    precondition(basic.regularizationType == .none)
    precondition(basic.regularizationScale == 0)
    precondition(basic.appliesGradientClipping == false)
    let clipped = MLCOptimizerDescriptor(
        learningRate: 0.001,
        gradientRescale: 0.5,
        appliesGradientClipping: true,
        gradientClipMax: 1,
        gradientClipMin: -1,
        regularizationType: .l2,
        regularizationScale: 0.01
    )
    precondition(clipped.gradientClipMax == 1)
    precondition(clipped.gradientClipMin == -1)
    let typed = MLCOptimizerDescriptor(
        learningRate: 0.002,
        gradientRescale: 1,
        appliesGradientClipping: true,
        gradientClippingType: .byNorm,
        gradientClipMax: 0.5,
        gradientClipMin: -0.5,
        maximumClippingNorm: 2,
        customGlobalNorm: 3,
        regularizationType: .l1,
        regularizationScale: 0.1
    )
    precondition(typed.gradientClippingType == .byNorm)
    precondition(typed.maximumClippingNorm == 2)
    precondition(typed.customGlobalNorm == 3)
    let copy = basic.copy() as! MLCOptimizerDescriptor
    precondition(copy.learningRate == 0.01)
}

func testLSTMDescriptorDefaults() {
    let basic = MLCLSTMDescriptor(inputSize: 8, hiddenSize: 16, layerCount: 1)
    precondition(basic.inputSize == 8)
    precondition(basic.hiddenSize == 16)
    precondition(basic.layerCount == 1)
    precondition(basic.usesBiases)
    precondition(basic.returnsSequences)
    precondition(basic.resultMode == .output)
    precondition(basic.batchFirst == false)
    precondition(basic.isBidirectional == false)
    precondition(basic.dropout == 0)
    let short = MLCLSTMDescriptor(
        inputSize: 4,
        hiddenSize: 8,
        layerCount: 2,
        usesBiases: false,
        isBidirectional: true,
        dropout: 0.1
    )
    precondition(short.isBidirectional)
    let mid = MLCLSTMDescriptor(
        inputSize: 4,
        hiddenSize: 8,
        layerCount: 1,
        usesBiases: true,
        batchFirst: true,
        isBidirectional: false,
        dropout: 0
    )
    precondition(mid.batchFirst)
    let seq = MLCLSTMDescriptor(
        inputSize: 4,
        hiddenSize: 8,
        layerCount: 1,
        usesBiases: true,
        batchFirst: true,
        isBidirectional: false,
        returnsSequences: false,
        dropout: 0
    )
    precondition(seq.returnsSequences == false)
    let full = MLCLSTMDescriptor(
        inputSize: 4,
        hiddenSize: 8,
        layerCount: 1,
        usesBiases: true,
        batchFirst: false,
        isBidirectional: false,
        returnsSequences: true,
        dropout: 0,
        resultMode: .outputAndStates
    )
    precondition(full.resultMode == .outputAndStates)
    let copy = basic.copy() as! MLCLSTMDescriptor
    precondition(copy.hiddenSize == 16)
}

func testEmbeddingDescriptorValues() {
    let basic = MLCEmbeddingDescriptor(embeddingCount: 10, embeddingDimension: 4)!
    precondition(basic.embeddingCount == 10)
    precondition(basic.embeddingDimension == 4)
    precondition(basic.paddingIndex == nil)
    precondition(basic.maximumNorm == nil)
    precondition(basic.pNorm == nil)
    precondition(basic.scalesGradientByFrequency == false)
    let full = MLCEmbeddingDescriptor(
        embeddingCount: 5,
        embeddingDimension: 2,
        paddingIndex: 0,
        maximumNorm: 1,
        pNorm: 2,
        scalesGradientByFrequency: true
    )!
    precondition(full.paddingIndex == 0)
    precondition(full.scalesGradientByFrequency)
    precondition(MLCEmbeddingDescriptor(embeddingCount: 0, embeddingDimension: 1) == nil)
    let copy = basic.copy() as! MLCEmbeddingDescriptor
    precondition(copy.embeddingDimension == 4)
}

func testMatMulDescriptorValues() {
    let basic = MLCMatMulDescriptor()
    precondition(basic.alpha == 1)
    precondition(basic.transposesX == false)
    precondition(basic.transposesY == false)
    let custom = MLCMatMulDescriptor(alpha: 0.5, transposesX: true, transposesY: false)!
    precondition(custom.transposesX)
    let copy = basic.copy() as! MLCMatMulDescriptor
    precondition(copy.alpha == 1)
}

func testMultiheadAttentionDescriptorValues() {
    let basic = MLCMultiheadAttentionDescriptor(modelDimension: 8, headCount: 2)
    precondition(basic.modelDimension == 8)
    precondition(basic.headCount == 2)
    precondition(basic.keyDimension == 8)
    precondition(basic.valueDimension == 8)
    precondition(basic.hasBiases)
    let full = MLCMultiheadAttentionDescriptor(
        modelDimension: 8,
        keyDimension: 8,
        valueDimension: 8,
        headCount: 2,
        dropout: 0.1,
        hasBiases: false,
        hasAttentionBiases: true,
        addsZeroAttention: true
    )!
    precondition(full.dropout == 0.1)
    precondition(full.hasAttentionBiases)
    precondition(full.addsZeroAttention)
    precondition(MLCMultiheadAttentionDescriptor(
        modelDimension: 7,
        keyDimension: 7,
        valueDimension: 7,
        headCount: 2,
        dropout: 0,
        hasBiases: true,
        hasAttentionBiases: false,
        addsZeroAttention: false
    ) == nil)
    let copy = basic.copy() as! MLCMultiheadAttentionDescriptor
    precondition(copy.headCount == 2)
}

func testYOLOLossDescriptorValues() {
    let boxes = Data(repeating: 0, count: 16)
    let descriptor = MLCYOLOLossDescriptor(anchorBoxes: boxes, anchorBoxCount: 2)
    precondition(descriptor.anchorBoxCount == 2)
    precondition(descriptor.anchorBoxes.count == 16)
    precondition(descriptor.shouldRescore)
    precondition(descriptor.scaleClassLoss == 1)
    descriptor.scaleNoObjectConfidenceLoss = 0.25
    precondition(descriptor.scaleNoObjectConfidenceLoss == 0.25)
    descriptor.scaleObjectConfidenceLoss = 2
    descriptor.scaleSpatialPositionLoss = 0.5
    descriptor.scaleSpatialSizeLoss = 0.5
    descriptor.minimumIOUForObjectPresence = 0.4
    descriptor.maximumIOUForObjectAbsence = 0.2
    let copy = descriptor.copy() as! MLCYOLOLossDescriptor
    precondition(copy.minimumIOUForObjectPresence == 0.4)
}
