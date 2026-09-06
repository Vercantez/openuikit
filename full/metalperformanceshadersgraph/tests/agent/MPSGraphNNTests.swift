import Foundation
import MetalPerformanceShadersGraph

func testConvolutionConstruction() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, 1, 4, 4, name: "x")
    let w = mpsgPlaceholder(graph, 1, 1, 3, 3, name: "w")
    let conv2d = MPSGraphConvolution2DOpDescriptor(
        strideInX: 1, strideInY: 1, dilationRateInX: 1, dilationRateInY: 1, groups: 1,
        paddingStyle: .explicit, dataLayout: .NCHW, weightsLayout: .OIHW
    )!
    let y = graph.convolution2D(x, weights: w, descriptor: conv2d, name: "c2d")
    precondition(y.operation.inputTensors.count >= 2)
    _ = graph.convolution2DDataGradient(y, weights: w, outputShape: mpsgShape(1, 1, 4, 4), forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolution2DDataGradient(y, weights: w, outputShapeTensor: x, forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolution2DWeightsGradient(y, source: x, outputShape: mpsgShape(1, 1, 3, 3), forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolution2DWeightsGradient(y, source: x, outputShapeTensor: w, forwardConvolutionDescriptor: conv2d, name: nil)
    let conv3d = MPSGraphConvolution3DOpDescriptor(
        strideInX: 1, strideInY: 1, strideInZ: 1,
        dilationRateInX: 1, dilationRateInY: 1, dilationRateInZ: 1, groups: 1,
        paddingStyle: .explicit, dataLayout: .NCDHW, weightsLayout: .OIDHW
    )!
    let x3 = mpsgPlaceholder(graph, 1, 1, 4, 4, 4, name: "x3")
    let w3 = mpsgPlaceholder(graph, 1, 1, 3, 3, 3, name: "w3")
    _ = graph.convolution3D(x3, weights: w3, descriptor: conv3d, name: nil)
    _ = graph.convolution3DDataGradient(x3, weights: w3, outputShape: mpsgShape(1, 1, 4, 4, 4), forwardConvolutionDescriptor: conv3d, name: nil)
    _ = graph.convolution3DDataGradient(x3, weights: w3, outputShapeTensor: x3, forwardConvolutionDescriptor: conv3d, name: nil)
    _ = graph.convolution3DWeightsGradient(x3, source: x3, outputShape: mpsgShape(1, 1, 3, 3, 3), forwardConvolutionDescriptor: conv3d, name: nil)
    _ = graph.convolution3DWeightsGradient(x3, source: x3, outputShapeTensor: w3, forwardConvolutionDescriptor: conv3d, name: nil)
    _ = graph.convolutionTranspose2D(x, weights: w, outputShape: mpsgShape(1, 1, 4, 4), descriptor: conv2d, name: nil)
    _ = graph.convolutionTranspose2D(x, weights: w, outputShapeTensor: x, descriptor: conv2d, name: nil)
    _ = graph.convolutionTranspose2DDataGradient(x, weights: w, outputShape: mpsgShape(1, 1, 4, 4), forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolutionTranspose2DDataGradient(x, weights: w, outputShapeTensor: x, forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolutionTranspose2DWeightsGradient(x, weights: w, outputShape: mpsgShape(1, 1, 3, 3), forwardConvolutionDescriptor: conv2d, name: nil)
    _ = graph.convolutionTranspose2DWeightsGradient(x, weights: w, outputShapeTensor: w, forwardConvolutionDescriptor: conv2d, name: nil)
    let dw2 = MPSGraphDepthwiseConvolution2DOpDescriptor(dataLayout: .NCHW, weightsLayout: .OIHW)!
    _ = graph.depthwiseConvolution2D(x, weights: w, descriptor: dw2, name: nil)
    _ = graph.depthwiseConvolution2DDataGradient(x, weights: w, outputShape: mpsgShape(1, 1, 4, 4), descriptor: dw2, name: nil)
    _ = graph.depthwiseConvolution2DWeightsGradient(x, source: x, outputShape: mpsgShape(1, 1, 3, 3), descriptor: dw2, name: nil)
    let dw3 = MPSGraphDepthwiseConvolution3DOpDescriptor(paddingStyle: .explicit)!
    _ = graph.depthwiseConvolution3D(x3, weights: w3, descriptor: dw3, name: nil)
    _ = graph.depthwiseConvolution3DDataGradient(x3, weights: w3, outputShape: mpsgShape(1, 1, 4, 4, 4), descriptor: dw3, name: nil)
    _ = graph.depthwiseConvolution3DWeightsGradient(x3, source: x3, outputShape: mpsgShape(1, 1, 3, 3, 3), descriptor: dw3, name: nil)
    let im2col = MPSGraphImToColOpDescriptor(
        kernelWidth: 3, kernelHeight: 3, strideInX: 1, strideInY: 1,
        dilationRateInX: 1, dilationRateInY: 1, dataLayout: .NCHW
    )!
    _ = graph.imToCol(x, descriptor: im2col, name: nil)
    _ = graph.colToIm(x, outputShape: mpsgShape(1, 1, 4, 4), descriptor: im2col, name: nil)
}

func testPoolingConstruction() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, 1, 4, 4, name: "x")
    let pool2 = MPSGraphPooling2DOpDescriptor(
        kernelWidth: 2, kernelHeight: 2, strideInX: 2, strideInY: 2,
        paddingStyle: .explicit, dataLayout: .NCHW
    )!
    _ = graph.avgPooling2D(withSourceTensor: x, descriptor: pool2, name: nil)
    _ = graph.avgPooling2DGradient(withGradientTensor: x, sourceTensor: x, descriptor: pool2, name: nil)
    _ = graph.maxPooling2D(withSourceTensor: x, descriptor: pool2, name: nil)
    _ = graph.maxPooling2DGradient(withGradientTensor: x, sourceTensor: x, descriptor: pool2, name: nil)
    _ = graph.maxPooling2DGradient(withGradientTensor: x, indicesTensor: x, outputShape: mpsgShape(1, 1, 2, 2), descriptor: pool2, name: nil)
    _ = graph.maxPooling2DGradient(withGradientTensor: x, indicesTensor: x, outputShapeTensor: x, descriptor: pool2, name: nil)
    precondition(graph.maxPooling2DReturnIndices(x, descriptor: pool2, name: nil).count == 2)
    let pool4 = MPSGraphPooling4DOpDescriptor(kernelSizes: mpsgShape(1, 1, 2, 2), paddingStyle: .explicit)!
    let x4 = mpsgPlaceholder(graph, 1, 1, 4, 4, name: "x4")
    _ = graph.avgPooling4D(x4, descriptor: pool4, name: nil)
    _ = graph.avgPooling4DGradient(x4, source: x4, descriptor: pool4, name: nil)
    _ = graph.maxPooling4D(x4, descriptor: pool4, name: nil)
    _ = graph.maxPooling4DGradient(x4, source: x4, descriptor: pool4, name: nil)
    _ = graph.maxPooling4DGradient(withGradientTensor: x4, indicesTensor: x4, outputShape: mpsgShape(1, 1, 2, 2), descriptor: pool4, name: nil)
    _ = graph.maxPooling4DGradient(withGradientTensor: x4, indicesTensor: x4, outputShapeTensor: x4, descriptor: pool4, name: nil)
    _ = graph.maxPooling4DReturnIndices(x4, descriptor: pool4, name: nil)
    _ = graph.L2NormPooling4D(x4, descriptor: pool4, name: nil)
    _ = graph.L2NormPooling4DGradient(x4, source: x4, descriptor: pool4, name: nil)
}

func testRNNConstruction() {
    let graph = MPSGraph()
    let src = mpsgPlaceholder(graph, 2, 3, 4, name: "s")
    let rw = mpsgPlaceholder(graph, 4, 4, name: "rw")
    let lstm = MPSGraphLSTMDescriptor()
    precondition(graph.LSTM(src, recurrentWeight: rw, initState: nil, initCell: nil, descriptor: lstm, name: nil).count >= 2)
    _ = graph.LSTM(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, initCell: nil, descriptor: lstm, name: nil)
    _ = graph.LSTM(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, initCell: nil, mask: nil, peephole: nil, descriptor: lstm, name: nil)
    _ = graph.LSTMGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, cellOutputFwd: src, descriptor: lstm, name: nil)
    _ = graph.LSTMGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, cellOutputFwd: src, inputWeight: nil, bias: nil, initState: nil, initCell: nil, descriptor: lstm, name: nil)
    _ = graph.LSTMGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, cellOutputFwd: src, inputWeight: nil, bias: nil, initState: nil, initCell: nil, mask: nil, descriptor: lstm, name: nil)
    _ = graph.LSTMGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, cellOutputFwd: src, stateGradient: nil, cellGradient: nil, inputWeight: nil, bias: nil, initState: nil, initCell: nil, mask: nil, peephole: nil, descriptor: lstm, name: nil)
    let gru = MPSGraphGRUDescriptor()
    _ = graph.GRU(src, recurrentWeight: rw, inputWeight: nil, bias: nil, descriptor: gru, name: nil)
    _ = graph.GRU(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, descriptor: gru, name: nil)
    _ = graph.GRU(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, mask: nil, secondaryBias: nil, descriptor: gru, name: nil)
    _ = graph.GRUGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, outputFwd: src, inputWeight: nil, bias: nil, descriptor: gru, name: nil)
    _ = graph.GRUGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, outputFwd: src, inputWeight: nil, bias: nil, initState: nil, descriptor: gru, name: nil)
    _ = graph.GRUGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, outputFwd: src, stateGradient: nil, inputWeight: nil, bias: nil, initState: nil, mask: nil, secondaryBias: nil, descriptor: gru, name: nil)
    let rnn = MPSGraphSingleGateRNNDescriptor()
    _ = graph.singleGateRNN(src, recurrentWeight: rw, initState: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNN(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNN(src, recurrentWeight: rw, inputWeight: nil, bias: nil, initState: nil, mask: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNNGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, initState: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNNGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, inputWeight: nil, bias: nil, initState: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNNGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, inputWeight: nil, bias: nil, initState: nil, mask: nil, descriptor: rnn, name: nil)
    _ = graph.singleGateRNNGradients(src, recurrentWeight: rw, sourceGradient: src, zState: src, stateGradient: nil, inputWeight: nil, bias: nil, initState: nil, mask: nil, descriptor: rnn, name: nil)
}

func testRandomAndFFTConstruction() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 4, name: "x")
    let random = MPSGraphRandomOpDescriptor(distribution: .uniform, dataType: .float32)!
    _ = graph.randomTensor(withShape: mpsgShape(4), descriptor: random, name: nil)
    _ = graph.randomTensor(withShape: mpsgShape(4), descriptor: random, seed: 1, name: nil)
    _ = graph.randomTensor(withShape: mpsgShape(4), descriptor: random, stateTensor: x, name: nil)
    _ = graph.randomTensor(withShapeTensor: x, descriptor: random, name: nil)
    _ = graph.randomTensor(withShapeTensor: x, descriptor: random, seed: 1, name: nil)
    _ = graph.randomTensor(withShapeTensor: x, descriptor: random, stateTensor: x, name: nil)
    _ = graph.randomUniformTensor(withShape: mpsgShape(4), name: nil)
    _ = graph.randomUniformTensor(withShape: mpsgShape(4), seed: 1, name: nil)
    _ = graph.randomUniformTensor(withShape: mpsgShape(4), stateTensor: x, name: nil)
    _ = graph.randomUniformTensor(withShapeTensor: x, name: nil)
    _ = graph.randomUniformTensor(withShapeTensor: x, seed: 1, name: nil)
    _ = graph.randomUniformTensor(withShapeTensor: x, stateTensor: x, name: nil)
    _ = graph.randomPhiloxStateTensor(withSeed: 1, name: nil)
    _ = graph.randomPhiloxStateTensor(withCounterLow: 0, counterHigh: 0, key: 1, name: nil)
    let fft = MPSGraphFFTDescriptor()
    _ = graph.fastFourierTransform(x, axes: mpsgShape(0), descriptor: fft, name: nil)
    _ = graph.fastFourierTransform(x, axesTensor: x, descriptor: fft, name: nil)
    _ = graph.HermiteanToRealFFT(x, axes: mpsgShape(0), descriptor: fft, name: nil)
    _ = graph.HermiteanToRealFFT(x, axesTensor: x, descriptor: fft, name: nil)
    _ = graph.realToHermiteanFFT(x, axes: mpsgShape(0), descriptor: fft, name: nil)
    _ = graph.realToHermiteanFFT(x, axesTensor: x, descriptor: fft, name: nil)
}

func testSortGatherScatter() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 4, name: "x")
    _ = graph.sort(x, axis: 0, name: nil)
    _ = graph.sort(x, axis: 0, descending: true, name: nil)
    _ = graph.sort(x, axisTensor: x, name: nil)
    _ = graph.sort(x, axisTensor: x, descending: false, name: nil)
    _ = graph.argSort(x, axis: 0, name: nil)
    _ = graph.argSort(x, axis: 0, descending: true, name: nil)
    _ = graph.argSort(x, axisTensor: x, name: nil)
    _ = graph.argSort(x, axisTensor: x, descending: false, name: nil)
    _ = graph.topK(x, k: 1, name: nil)
    _ = graph.topK(x, axis: 0, k: 1, name: nil)
    _ = graph.topK(x, kTensor: x, name: nil)
    _ = graph.topK(x, axisTensor: x, kTensor: x, name: nil)
    _ = graph.topKGradient(x, input: x, k: 1, name: nil)
    _ = graph.topKGradient(x, source: x, axis: 0, k: 1, name: nil)
    _ = graph.topKGradient(x, input: x, kTensor: x, name: nil)
    _ = graph.topKGradient(x, source: x, axisTensor: x, kTensor: x, name: nil)
    _ = graph.bottomK(x, axis: 0, k: 1, name: nil)
    _ = graph.bottomK(x, axisTensor: x, kTensor: x, name: nil)
    _ = graph.bottomKGradient(x, source: x, axis: 0, k: 1, name: nil)
    _ = graph.bottomKGradient(x, source: x, axisTensor: x, kTensor: x, name: nil)
    _ = graph.gather(withUpdatesTensor: x, indicesTensor: x, axis: 0, batchDimensions: 0, name: nil)
    _ = graph.gatherAlongAxis(0, updates: x, indices: x, name: nil)
    _ = graph.gatherAlongAxisTensor(x, updates: x, indices: x, name: nil)
    _ = graph.gatherND(withUpdatesTensor: x, indicesTensor: x, batchDimensions: 0, name: nil)
    _ = graph.scatter(x, indices: x, shape: mpsgShape(4), axis: 0, mode: .set, name: nil)
    _ = graph.scatterAlongAxis(0, updates: x, indices: x, shape: mpsgShape(4), mode: .add, name: nil)
    _ = graph.scatterAlongAxis(0, data: x, updates: x, indices: x, mode: .add, name: nil)
    _ = graph.scatterAlongAxisTensor(x, updates: x, indices: x, shape: mpsgShape(4), mode: .set, name: nil)
    _ = graph.scatterAlongAxisTensor(x, data: x, updates: x, indices: x, mode: .set, name: nil)
    _ = graph.scatterND(withUpdatesTensor: x, indicesTensor: x, shape: mpsgShape(4), batchDimensions: 0, name: nil)
    _ = graph.scatterND(withUpdatesTensor: x, indicesTensor: x, shape: mpsgShape(4), batchDimensions: 0, mode: .set, name: nil)
    _ = graph.scatterNDWithData(x, updates: x, indices: x, batchDimensions: 0, mode: .set, name: nil)
    _ = graph.scatterWithData(x, updates: x, indices: x, axis: 0, mode: .set, name: nil)
}

func testResizeQuantizeNormalize() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, 1, 4, 4, name: "x")
    let size = graph.constant(2, shape: mpsgShape(2), dataType: .int32)
    _ = graph.resize(x, size: mpsgShape(2, 2), mode: .nearest, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resize(x, sizeTensor: size, mode: .bilinear, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resize(x, sizeTensor: size, mode: .nearest, centerResult: true, alignCorners: false, name: nil)
    _ = graph.resize(x, sizeTensor: size, scaleOffsetTensor: x, mode: .nearest, layout: .NCHW, name: nil)
    _ = graph.resize(x, sizeTensor: size, scaleTensor: x, offsetTenor: x, mode: .nearest, name: nil)
    _ = graph.resize(withGradientTensor: x, input: x, mode: .nearest, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resize(withGradientTensor: x, input: x, scaleOffsetTensor: x, mode: .nearest, layout: .NCHW, name: nil)
    _ = graph.resize(withGradientTensor: x, input: x, scale: x, offsetTensor: x, mode: .nearest, name: nil)
    _ = graph.resizeBilinear(x, sizeTensor: size, centerResult: true, alignCorners: false, name: nil)
    _ = graph.resizeBilinear(x, sizeTensor: size, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resizeBilinear(x, sizeTensor: size, scaleOffsetTensor: x, layout: .NCHW, name: nil)
    _ = graph.resizeBilinear(x, sizeTensor: size, scaleTensor: x, offsetTensor: x, name: nil)
    _ = graph.resizeBilinear(withGradientTensor: x, input: x, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resizeBilinear(withGradientTensor: x, input: x, scaleOffsetTensor: x, layout: .NCHW, name: nil)
    _ = graph.resizeBilinear(withGradientTensor: x, input: x, scale: x, offsetTensor: x, name: nil)
    _ = graph.resizeNearest(x, sizeTensor: size, nearestRoundingMode: .floor, centerResult: true, alignCorners: false, name: nil)
    _ = graph.resizeNearest(x, sizeTensor: size, nearestRoundingMode: .floor, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resizeNearest(x, sizeTensor: size, scaleOffsetTensor: x, nearestRoundingMode: .floor, layout: .NCHW, name: nil)
    _ = graph.resizeNearest(x, sizeTensor: size, scaleTensor: x, offsetTensor: x, nearestRoundingMode: .floor, name: nil)
    _ = graph.resizeNearest(withGradientTensor: x, input: x, nearestRoundingMode: .floor, centerResult: true, alignCorners: false, layout: .NCHW, name: nil)
    _ = graph.resizeNearest(withGradientTensor: x, input: x, scaleOffsetTensor: x, nearestRoundingMode: .floor, layout: .NCHW, name: nil)
    _ = graph.resizeNearest(withGradientTensor: x, input: x, scale: x, offsetTensor: x, nearestRoundingMode: .floor, name: nil)
    _ = graph.quantize(x, scale: 1, zeroPoint: 0, dataType: .int8, name: nil)
    _ = graph.quantize(x, scaleTensor: x, zeroPoint: 0, dataType: .int8, axis: 1, name: nil)
    _ = graph.quantize(x, scaleTensor: x, zeroPointTensor: x, dataType: .int8, axis: 1, name: nil)
    _ = graph.dequantize(x, scale: 1, zeroPoint: 0, dataType: .float32, name: nil)
    _ = graph.dequantize(x, scaleTensor: x, dataType: .float32, name: nil)
    _ = graph.dequantize(x, LUTTensor: x, name: nil)
    _ = graph.dequantize(x, LUTTensor: x, axis: 0, name: nil)
    _ = graph.dequantize(x, scaleTensor: x, zeroPoint: 0, dataType: .float32, axis: 1, name: nil)
    _ = graph.dequantize(x, scaleTensor: x, zeroPointTensor: x, dataType: .float32, name: nil)
    _ = graph.dequantize(x, scaleTensor: x, zeroPointTensor: x, dataType: .float32, axis: 1, name: nil)
    _ = graph.normalize(x, mean: x, variance: x, gamma: nil, beta: nil, epsilon: 1e-5, name: nil)
    _ = graph.normalizationGradient(withIncomingGradientTensor: x, sourceTensor: x, mean: x, varianceTensor: x, gammaTensor: nil, gammaGradientTensor: nil, betaGradientTensor: nil, reductionAxes: mpsgShape(0), epsilon: 1e-5, name: nil)
    _ = graph.normalizationBetaGradient(withIncomingGradientTensor: x, sourceTensor: x, reductionAxes: mpsgShape(0), name: nil)
    _ = graph.normalizationGammaGradient(withIncomingGradientTensor: x, sourceTensor: x, mean: x, varianceTensor: x, reductionAxes: mpsgShape(0), epsilon: 1e-5, name: nil)
    _ = graph.variance(of: x, axes: mpsgShape(0), name: nil)
    _ = graph.variance(of: x, mean: x, axes: mpsgShape(0), name: nil)
}

func testLayoutAndAttention() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, 4, 4, 4, name: "x")
    let sparse = MPSGraphCreateSparseOpDescriptor.sparseDescriptor(descriptorWithStorageType: .COO, dataType: .float32)!
    _ = graph.sparseTensor(sparseTensorWithDescriptor: sparse, tensors: [x], shape: mpsgShape(4), name: nil)
    _ = graph.sparseTensor(sparseTensorWithType: .COO, tensors: [x], shape: mpsgShape(4), dataType: .float32, name: nil)
    _ = graph.depth(toSpace2DTensor: x, widthAxis: 3, heightAxis: 2, depthAxis: 1, blockSize: 2, usePixelShuffleOrder: false, name: nil)
    _ = graph.depth(toSpace2DTensor: x, widthAxisTensor: x, heightAxisTensor: x, depthAxisTensor: x, blockSize: 2, usePixelShuffleOrder: false, name: nil)
    _ = graph.space(toDepth2DTensor: x, widthAxis: 3, heightAxis: 2, depthAxis: 1, blockSize: 2, usePixelShuffleOrder: false, name: nil)
    _ = graph.space(toDepth2DTensor: x, widthAxisTensor: x, heightAxisTensor: x, depthAxisTensor: x, blockSize: 2, usePixelShuffleOrder: false, name: nil)
    _ = graph.spaceToBatch(x, spatialAxes: mpsgShape(2, 3), batchAxis: 0, blockDimensions: mpsgShape(2, 2), usePixelShuffleOrder: false, name: nil)
    _ = graph.spaceToBatch(x, spatialAxesTensor: x, batchAxisTensor: x, blockDimensionsTensor: x, usePixelShuffleOrder: false, name: nil)
    _ = graph.batchToSpace(x, spatialAxes: mpsgShape(2, 3), batchAxis: 0, blockDimensions: mpsgShape(2, 2), usePixelShuffleOrder: false, name: nil)
    _ = graph.batchToSpace(x, spatialAxesTensor: x, batchAxisTensor: x, blockDimensionsTensor: x, usePixelShuffleOrder: false, name: nil)
    _ = graph.bandPart(x, numLower: 0, numUpper: 0, name: nil)
    _ = graph.bandPart(x, numLowerTensor: x, numUpperTensor: x, name: nil)
    _ = graph.nonMaximumSuppression(withBoxesTensor: x, scoresTensor: x, iouThreshold: 0.5, scoreThreshold: 0.1, perClassSuppression: false, coordinateMode: .explicit, name: nil)
    _ = graph.nonMaximumSuppression(withBoxesTensor: x, scoresTensor: x, classIndicesTensor: x, iouThreshold: 0.5, scoreThreshold: 0.1, perClassSuppression: false, coordinateMode: .explicit, name: nil)
    _ = graph.sampleGrid(withSourceTensor: x, coordinateTensor: x, layout: .NCHW, normalizeCoordinates: true, relativeCoordinates: false, alignCorners: false, paddingMode: .zero, nearestRoundingMode: .floor, constantValue: 0, name: nil)
    _ = graph.sampleGrid(withSourceTensor: x, coordinateTensor: x, layout: .NCHW, normalizeCoordinates: true, relativeCoordinates: false, alignCorners: false, paddingMode: .zero, samplingMode: .bilinear, constantValue: 0, name: nil)
    _ = graph.scaledDotProductAttention(query: x, key: x, value: x, scale: 1, name: nil)
    _ = graph.scaledDotProductAttention(query: x, key: x, value: x, mask: nil, scale: 1, name: nil)
    let stencil = MPSGraphStencilOpDescriptor(paddingStyle: .explicit)!
    _ = graph.stencil(withSourceTensor: x, weightsTensor: x, descriptor: stencil, name: nil)
}

func testOptimizersAndCall() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 4, name: "x")
    _ = graph.dropout(x, rate: 0.5, name: nil)
    _ = graph.dropout(x, rate: x, name: nil)
    _ = graph.adam(
        currentLearningRate: x, beta1: x, beta2: x, epsilon: x, values: x,
        momentum: x, velocity: x, maximumVelocity: nil, gradient: x, name: nil
    )
    _ = graph.adam(
        learningRate: x, beta1: x, beta2: x, epsilon: x, beta1Power: x, beta2Power: x,
        values: x, momentum: x, velocity: x, maximumVelocity: nil, gradient: x, name: nil
    )
    _ = graph.stochasticGradientDescent(learningRate: x, values: x, gradient: x, name: nil)
    let variable = graph.variable(with: Data(count: 16), shape: mpsgShape(4), dataType: .float32, name: "v")
    let variableOp = variable.operation as! MPSGraphVariableOp
    _ = graph.applyStochasticGradientDescent(learningRate: x, variable: variableOp, gradient: x, name: nil)
    let shaped = MPSGraphShapedType(shape: mpsgShape(4), dataType: .float32)
    _ = graph.call(symbolName: "missing", inputTensors: [x], outputTypes: [shaped], name: nil)
    _ = graph.nonZeroIndices(x, name: nil)
}
