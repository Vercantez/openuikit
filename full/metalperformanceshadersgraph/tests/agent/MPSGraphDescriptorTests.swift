import Foundation
import MetalPerformanceShadersGraph

func testCompilationDescriptor() {
    let descriptor = MPSGraphCompilationDescriptor()
    precondition(descriptor.optimizationLevel == .level0)
    precondition(descriptor.optimizationProfile == .performance)
    precondition(descriptor.reducedPrecisionFastMath == .none)
    precondition(descriptor.waitForCompilationCompletion == false)
    descriptor.optimizationLevel = .level1
    descriptor.optimizationProfile = .powerEfficiency
    descriptor.reducedPrecisionFastMath = .allowFP16Intermediates
    descriptor.waitForCompilationCompletion = true
    descriptor.callables = [:]
    descriptor.dispatchQueue = DispatchQueue(label: "mpsg-test")
    var completed = false
    descriptor.compilationCompletionHandler = { _, _ in completed = true }
    descriptor.disableTypeInference()
    let graph = MPSGraph()
    let shaped = MPSGraphShapedType(shape: mpsgShape(1), dataType: .float32)
    let x = graph.placeholder(shape: mpsgShape(1), dataType: .float32, name: "x")
    _ = graph.compile(
        with: MPSGraphDevice.hostDevice(),
        feeds: [x: shaped],
        targetTensors: [x],
        targetOperations: nil,
        compilationDescriptor: descriptor
    )
    precondition(completed)
}

func testExecutionDescriptor() {
    let descriptor = MPSGraphExecutionDescriptor()
    precondition(descriptor.waitUntilCompleted == false)
    descriptor.waitUntilCompleted = true
    descriptor.compilationDescriptor = MPSGraphCompilationDescriptor()
    var scheduled = false
    var completed = false
    descriptor.scheduledHandler = { _, _ in scheduled = true }
    descriptor.completionHandler = { _, _ in completed = true }
    let graph = MPSGraph()
    let x = graph.placeholder(shape: mpsgShape(1), dataType: .float32, name: "x")
    _ = graph.runAsync(
        feeds: [x: mpsgFloatData([1], shape: [1])],
        targetTensors: [x],
        targetOperations: nil,
        executionDescriptor: descriptor
    )
    precondition(scheduled && completed)
}

func testExecutableExecutionDescriptor() {
    let descriptor = MPSGraphExecutableExecutionDescriptor()
    precondition(descriptor.waitUntilCompleted == false)
    descriptor.waitUntilCompleted = true
    descriptor.completionHandler = { _, _ in }
    descriptor.scheduledHandler = { _, _ in }
}

func testSerializationDescriptor() {
    let descriptor = MPSGraphExecutableSerializationDescriptor()
    precondition(descriptor.append == false)
    precondition(descriptor.deploymentPlatform == .macOS)
    precondition(descriptor.minimumDeploymentTarget == "14.0")
    descriptor.append = true
    descriptor.deploymentPlatform = .iOS
    descriptor.minimumDeploymentTarget = "18.0"
    precondition(descriptor.deploymentPlatform == .iOS)
}

func testConvolution2DDescriptor() {
    let full = MPSGraphConvolution2DOpDescriptor(
        strideInX: 2,
        strideInY: 2,
        dilationRateInX: 1,
        dilationRateInY: 1,
        groups: 1,
        paddingLeft: 1,
        paddingRight: 1,
        paddingTop: 1,
        paddingBottom: 1,
        paddingStyle: .explicit,
        dataLayout: .NCHW,
        weightsLayout: .OIHW
    )
    precondition(full != nil)
    precondition(full?.strideInX == 2)
    precondition(full?.groups == 1)
    let compact = MPSGraphConvolution2DOpDescriptor(
        strideInX: 1,
        strideInY: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        groups: 1,
        paddingStyle: .TF_SAME,
        dataLayout: .NHWC,
        weightsLayout: .HWIO
    )
    compact?.setExplicitPaddingWithPaddingLeft(3, paddingRight: 4, paddingTop: 5, paddingBottom: 6)
    precondition(compact?.paddingLeft == 3)
    precondition(compact?.paddingStyle == .explicit)
    precondition(MPSGraphConvolution2DOpDescriptor(
        strideInX: 0,
        strideInY: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        groups: 1,
        paddingStyle: .explicit,
        dataLayout: .NCHW,
        weightsLayout: .OIHW
    ) == nil)
}

func testConvolution3DDescriptor() {
    let full = MPSGraphConvolution3DOpDescriptor(
        strideInX: 1,
        strideInY: 1,
        strideInZ: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        dilationRateInZ: 1,
        groups: 1,
        paddingLeft: 1,
        paddingRight: 1,
        paddingTop: 1,
        paddingBottom: 1,
        paddingFront: 1,
        paddingBack: 1,
        paddingStyle: .explicit,
        dataLayout: .NCDHW,
        weightsLayout: .OIDHW
    )
    precondition(full?.strideInZ == 1)
    precondition(full?.paddingFront == 1)
    let compact = MPSGraphConvolution3DOpDescriptor(
        strideInX: 1,
        strideInY: 1,
        strideInZ: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        dilationRateInZ: 1,
        groups: 1,
        paddingStyle: .TF_VALID,
        dataLayout: .NDHWC,
        weightsLayout: .DHWIO
    )
    compact?.setExplicitPaddingWithPaddingLeft(1, paddingRight: 2, paddingTop: 3, paddingBottom: 4, paddingFront: 5, paddingBack: 6)
    precondition(compact?.paddingBack == 6)
    precondition(MPSGraphConvolution3DOpDescriptor(
        strideInX: 1,
        strideInY: 1,
        strideInZ: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        dilationRateInZ: 1,
        groups: 0,
        paddingStyle: .explicit,
        dataLayout: .NCDHW,
        weightsLayout: .OIDHW
    ) == nil)
}

func testDepthwiseConvolution2DDescriptor() {
    let layout = MPSGraphDepthwiseConvolution2DOpDescriptor(dataLayout: .NCHW, weightsLayout: .OIHW)
    precondition(layout?.dataLayout == .NCHW)
    let full = MPSGraphDepthwiseConvolution2DOpDescriptor(
        strideInX: 2,
        strideInY: 2,
        dilationRateInX: 1,
        dilationRateInY: 1,
        paddingLeft: 1,
        paddingRight: 1,
        paddingTop: 1,
        paddingBottom: 1,
        paddingStyle: .explicit,
        dataLayout: .NHWC,
        weightsLayout: .HWIO
    )
    full?.setExplicitPaddingWithPaddingLeft(9, paddingRight: 8, paddingTop: 7, paddingBottom: 6)
    precondition(full?.paddingTop == 7)
    precondition(full?.strideInX == 2)
}

func testDepthwiseConvolution3DDescriptor() {
    let style = MPSGraphDepthwiseConvolution3DOpDescriptor(paddingStyle: .TF_SAME)
    precondition(style?.paddingStyle == .TF_SAME)
    precondition(style?.channelDimensionIndex == -4)
    let full = MPSGraphDepthwiseConvolution3DOpDescriptor(
        strides: mpsgShape(1, 1, 1),
        dilationRates: mpsgShape(1, 1, 1),
        paddingValues: mpsgShape(0, 0, 0, 0, 0, 0),
        paddingStyle: .explicit
    )
    precondition(full?.strides.count == 3)
}

func testPooling2DDescriptor() {
    let full = MPSGraphPooling2DOpDescriptor(
        kernelWidth: 2,
        kernelHeight: 2,
        strideInX: 2,
        strideInY: 2,
        dilationRateInX: 1,
        dilationRateInY: 1,
        paddingLeft: 0,
        paddingRight: 0,
        paddingTop: 0,
        paddingBottom: 0,
        paddingStyle: .explicit,
        dataLayout: .NCHW
    )
    precondition(full?.kernelWidth == 2)
    precondition(full?.returnIndicesMode == MPSGraphPoolingReturnIndicesMode.none)
    precondition(full?.ceilMode == false)
    let compact = MPSGraphPooling2DOpDescriptor(
        kernelWidth: 3,
        kernelHeight: 3,
        strideInX: 1,
        strideInY: 1,
        paddingStyle: .TF_SAME,
        dataLayout: .NHWC
    )
    compact?.setExplicitPaddingWithPaddingLeft(1, paddingRight: 1, paddingTop: 1, paddingBottom: 1)
    compact?.includeZeroPadToAverage = true
    compact?.returnIndicesDataType = .int32
    compact?.returnIndicesMode = .globalFlatten2D
    precondition(compact?.paddingStyle == .explicit)
    precondition(MPSGraphPooling2DOpDescriptor(
        kernelWidth: 0,
        kernelHeight: 1,
        strideInX: 1,
        strideInY: 1,
        paddingStyle: .explicit,
        dataLayout: .NCHW
    ) == nil)
}

func testPooling4DDescriptor() {
    let compact = MPSGraphPooling4DOpDescriptor(kernelSizes: mpsgShape(1, 2, 2, 2), paddingStyle: .explicit)
    precondition(compact?.kernelSizes.count == 4)
    precondition(compact?.strides.count == 4)
    let full = MPSGraphPooling4DOpDescriptor(
        kernelSizes: mpsgShape(1, 2, 2, 2),
        strides: mpsgShape(1, 1, 1, 1),
        dilationRates: mpsgShape(1, 1, 1, 1),
        paddingValues: mpsgShape(0, 0, 0, 0, 0, 0, 0, 0),
        paddingStyle: .TF_VALID
    )
    full?.ceilMode = true
    full?.includeZeroPadToAverage = true
    full?.returnIndicesMode = .globalFlatten4D
    full?.returnIndicesDataType = .int32
    precondition(full?.paddingStyle == .TF_VALID)
    precondition(MPSGraphPooling4DOpDescriptor(kernelSizes: [], paddingStyle: .explicit) == nil)
}

func testRandomOpDescriptor() {
    let descriptor = MPSGraphRandomOpDescriptor(distribution: .normal, dataType: .float32)
    precondition(descriptor?.distribution == .normal)
    precondition(descriptor?.mean == 0)
    precondition(descriptor?.standardDeviation == 1)
    descriptor?.min = -1
    descriptor?.max = 1
    descriptor?.minInteger = 0
    descriptor?.maxInteger = 10
    descriptor?.samplingMethod = .boxMuller
    precondition(descriptor?.samplingMethod == .boxMuller)
}

func testFFTDescriptor() {
    let descriptor = MPSGraphFFTDescriptor()
    precondition(descriptor.inverse == false)
    precondition(descriptor.roundToOddHermitean == false)
    precondition(descriptor.scalingMode == MPSGraphFFTScalingMode.none)
    descriptor.inverse = true
    descriptor.roundToOddHermitean = true
    descriptor.scalingMode = .unitary
    precondition(descriptor.scalingMode == .unitary)
}

func testImToColDescriptor() {
    let compact = MPSGraphImToColOpDescriptor(
        kernelWidth: 3,
        kernelHeight: 3,
        strideInX: 1,
        strideInY: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        dataLayout: .NCHW
    )
    precondition(compact?.kernelWidth == 3)
    let full = MPSGraphImToColOpDescriptor(
        kernelWidth: 2,
        kernelHeight: 2,
        strideInX: 2,
        strideInY: 2,
        dilationRateInX: 1,
        dilationRateInY: 1,
        paddingLeft: 1,
        paddingRight: 1,
        paddingTop: 1,
        paddingBottom: 1,
        dataLayout: .NHWC
    )
    full?.setExplicitPaddingWithPaddingLeft(4, paddingRight: 3, paddingTop: 2, paddingBottom: 1)
    precondition(full?.paddingLeft == 4)
    precondition(MPSGraphImToColOpDescriptor(
        kernelWidth: 0,
        kernelHeight: 1,
        strideInX: 1,
        strideInY: 1,
        dilationRateInX: 1,
        dilationRateInY: 1,
        dataLayout: .NCHW
    ) == nil)
}

func testStencilDescriptor() {
    let pad = MPSGraphStencilOpDescriptor(explicitPadding: mpsgShape(0, 0))
    precondition(pad?.reductionMode == .sum)
    let offsets = MPSGraphStencilOpDescriptor(offsets: mpsgShape(0), explicitPadding: mpsgShape(0, 0))
    precondition(offsets?.offsets.count == 1)
    let style = MPSGraphStencilOpDescriptor(paddingStyle: .explicit)
    precondition(style?.paddingStyle == .explicit)
    let full = MPSGraphStencilOpDescriptor(
        reductionMode: .max,
        offsets: mpsgShape(0),
        strides: mpsgShape(1),
        dilationRates: mpsgShape(1),
        explicitPadding: mpsgShape(0, 0),
        boundaryMode: .clampToEdge,
        paddingStyle: .explicit,
        paddingConstant: 0.5
    )
    precondition(full?.paddingConstant == 0.5)
    precondition(full?.boundaryMode == .clampToEdge)
}

func testLSTMDescriptor() {
    let descriptor = MPSGraphLSTMDescriptor()
    precondition(descriptor.activation == .tanh)
    precondition(descriptor.inputGateActivation == .sigmoid)
    precondition(descriptor.forgetGateActivation == .sigmoid)
    precondition(descriptor.cellGateActivation == .tanh)
    precondition(descriptor.outputGateActivation == .sigmoid)
    precondition(descriptor.produceCell == false)
    precondition(descriptor.bidirectional == false)
    descriptor.produceCell = true
    descriptor.training = true
    descriptor.reverse = true
    descriptor.forgetGateLast = true
    precondition(descriptor.training)
}

func testGRUDescriptor() {
    let descriptor = MPSGraphGRUDescriptor()
    precondition(descriptor.resetAfter == true)
    precondition(descriptor.resetGateActivation == .sigmoid)
    precondition(descriptor.updateGateActivation == .sigmoid)
    precondition(descriptor.outputGateActivation == .tanh)
    precondition(descriptor.flipZ == false)
    descriptor.bidirectional = true
    descriptor.resetGateFirst = true
    descriptor.training = true
    descriptor.reverse = true
    precondition(descriptor.bidirectional)
}

func testSingleGateRNNDescriptor() {
    let descriptor = MPSGraphSingleGateRNNDescriptor()
    precondition(descriptor.activation == .relu)
    precondition(descriptor.bidirectional == false)
    descriptor.reverse = true
    descriptor.training = true
    precondition(descriptor.reverse)
}

func testSparseDescriptor() {
    let descriptor = MPSGraphCreateSparseOpDescriptor.sparseDescriptor(
        descriptorWithStorageType: .COO,
        dataType: .float32
    )
    precondition(descriptor?.sparseStorageType == .COO)
    precondition(descriptor?.dataType == .float32)
    descriptor?.sparseStorageType = .CSR
    descriptor?.dataType = .float16
    precondition(descriptor?.sparseStorageType == .CSR)
}
