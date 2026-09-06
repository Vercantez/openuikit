import Foundation
import MLCompute

func testDeviceCPUAndFailClosedGPU() {
    let cpu = MLCDevice.cpu()
    precondition(cpu.type == .cpu)
    precondition(cpu.actualDeviceType == .cpu)
    precondition(MLCDevice.gpu() == nil)
    precondition(MLCDevice.ane() == nil)
    precondition(MLCDevice(type: .cpu)?.actualDeviceType == .cpu)
    precondition(MLCDevice(type: .any)?.actualDeviceType == .cpu)
    precondition(MLCDevice(type: .gpu) == nil)
    precondition(MLCDevice(type: .ane) == nil)
    precondition(MLCDevice(type: .cpu, selectsMultipleComputeDevices: true)?.type == .cpu)
    precondition(MLCDevice(type: .gpu, selectsMultipleComputeDevices: false) == nil)
}

func testPlatformRNG() {
    MLCPlatform.setRNGSeedTo(NSNumber(value: 42))
    precondition(MLCPlatform.getRNGseed()?.intValue == 42)
    let a = MLCTensor(shape: [8], randomInitializerType: .uniform)
    MLCPlatform.setRNGSeedTo(NSNumber(value: 99))
    let b = MLCTensor(shape: [8], randomInitializerType: .uniform)
    precondition(a.linuxHostFloats() != nil)
    precondition(b.linuxHostFloats() != nil)
}

func testOptimizerHyperparameters() {
    let descriptor = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    let base = MLCOptimizer(descriptor: descriptor)
    precondition(base.learningRate == 0.01)
    base.learningRate = 0.02
    precondition(base.learningRate == 0.02)
    base.appliesGradientClipping = true
    precondition(base.appliesGradientClipping)
    precondition(base.gradientRescale == 1)
    precondition(base.regularizationType == .none)
    let copied = base.copy() as! MLCOptimizer
    precondition(copied.learningRate == 0.02)
    let adam = MLCAdamOptimizer(descriptor: descriptor)
    precondition(adam.beta1 == 0.9)
    precondition(adam.beta2 == 0.999)
    precondition(adam.epsilon == 1e-8)
    precondition(adam.timeStep == 1)
    precondition(adam.usesAMSGrad == false)
    let adam2 = MLCAdamOptimizer(descriptor: descriptor, beta1: 0.8, beta2: 0.9, epsilon: 1e-7, timeStep: 3)
    precondition(adam2.beta1 == 0.8 && adam2.timeStep == 3)
    let adam3 = MLCAdamOptimizer(
        descriptor: descriptor,
        beta1: 0.7,
        beta2: 0.8,
        epsilon: 1e-6,
        usesAMSGrad: true,
        timeStep: 4
    )
    precondition(adam3.usesAMSGrad)
    let adamW = MLCAdamWOptimizer(descriptor: descriptor)
    precondition(adamW.beta1 == 0.9)
    let adamW2 = MLCAdamWOptimizer(
        descriptor: descriptor,
        beta1: 0.85,
        beta2: 0.95,
        epsilon: 1e-8,
        usesAMSGrad: true,
        timeStep: 2
    )
    precondition(adamW2.usesAMSGrad && adamW2.timeStep == 2)
    let sgd = MLCSGDOptimizer(descriptor: descriptor)
    precondition(sgd.momentumScale == 0)
    precondition(sgd.usesNesterovMomentum == false)
    let sgd2 = MLCSGDOptimizer(descriptor: descriptor, momentumScale: 0.9, usesNesterovMomentum: true)
    precondition(sgd2.usesNesterovMomentum)
    let rms = MLCRMSPropOptimizer(descriptor: descriptor)
    precondition(rms.alpha == 0.99)
    precondition(rms.epsilon == 1e-8)
    precondition(rms.isCentered == false)
    let rms2 = MLCRMSPropOptimizer(
        descriptor: descriptor,
        momentumScale: 0.5,
        alpha: 0.8,
        epsilon: 1e-7,
        isCentered: true
    )
    precondition(rms2.isCentered && rms2.momentumScale == 0.5)
    precondition(base.gradientClipMax == 0.1)
    precondition(base.gradientClipMin == -0.1)
    precondition(base.gradientClippingType == .byValue)
    precondition(base.maximumClippingNorm == 1)
    precondition(base.customGlobalNorm == 0)
    precondition(base.regularizationScale == 0)
}

func testGraphNodeTopology() {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 2, 4, 4], fillWithData: NSNumber(value: Float(1)), dataType: .float32)
    let relu = MLCActivationLayer.relu
    let activated = graph.node(with: relu, source: input)!
    precondition(activated.descriptor.shape == input.descriptor.shape)
    precondition(graph.layers.contains(where: { $0 === relu }))
    precondition(graph.sourceTensors(for: relu).first === input)
    precondition(graph.resultTensors(for: relu).first === activated)
    let add = MLCArithmeticLayer(operation: .add)
    let summed = graph.node(with: add, sources: [activated, activated])!
    precondition(summed.descriptor.shape == activated.descriptor.shape)
    let disabled = graph.node(with: MLCDropoutLayer(rate: 0.1, seed: 1), sources: [summed], disableUpdate: true)
    precondition(disabled != nil)
    let loss = MLCLossLayer.meanSquaredError(reductionType: .mean, weight: 1)
    let lossOut = graph.node(with: loss, sources: [summed], lossLabels: [input])
    precondition(lossOut != nil)
    let reshaped = graph.reshape(shape: [1, 32], source: summed)!
    precondition(reshaped.descriptor.shape == [1, 32])
    let transposed = graph.transpose(dimensions: [0, 1, 3, 2], source: input)!
    precondition(transposed.descriptor.shape == [1, 2, 4, 4])
    let concat = graph.concatenate(sources: [activated, activated], dimension: 1)!
    precondition(concat.descriptor.shape[1] == 4)
    let parts = graph.split(source: concat, splitCount: 2, dimension: 1)!
    precondition(parts.count == 2)
    let parts2 = graph.split(source: concat, splitSectionLengths: [1, 3], dimension: 1)!
    precondition(parts2[0].descriptor.shape[1] == 1)
    let gathered = graph.gather(withDimension: 1, source: concat, indices: MLCTensor(shape: [1], dataType: .int32))
    precondition(gathered != nil)
    let scattered = graph.scatter(
        withDimension: 1,
        source: concat,
        indices: MLCTensor(shape: [1], dataType: .int32),
        copyFrom: concat,
        reductionType: .sum
    )
    precondition(scattered != nil)
    precondition(graph.summarizedDOTDescription.contains("digraph"))
    let cpu = MLCDevice.cpu()
    var floats: [Float] = [1, 2, 3, 4]
    let ok = floats.withUnsafeMutableBufferPointer { buffer in
        graph.bindAndWriteData(
            ["x": MLCTensorData(bytesNoCopy: UnsafeMutableRawPointer(buffer.baseAddress!), length: 16)],
            forInputs: ["x": MLCTensor(shape: [4])],
            to: cpu,
            synchronous: true
        )
    }
    precondition(ok)
    var more: [Float] = [1, 2, 3, 4]
    more.withUnsafeMutableBufferPointer { buffer in
        precondition(
            graph.bindAndWriteData(
                ["y": MLCTensorData(bytesNoCopy: UnsafeMutableRawPointer(buffer.baseAddress!), length: 16)],
                forInputs: ["y": MLCTensor(shape: [4])],
                to: cpu,
                batchSize: 1,
                synchronous: true
            )
        )
    }
    precondition(graph.device?.actualDeviceType == .cpu)
}

func testInferenceCompileExecuteFailClosed() {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 1, 2, 2])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let inference = MLCInferenceGraph(graphObjects: [graph])
    precondition(inference.addInputs(["x": input]))
    precondition(inference.addInputs(["x": input], lossLabels: nil, lossLabelWeights: nil))
    precondition(inference.addOutputs(["y": input]))
    let cpu = MLCDevice.cpu()
    precondition(inference.compile(options: [], device: cpu) == false)
    precondition(inference.compile(options: [.debugLayers], device: cpu, inputTensors: ["x": input], inputTensorsData: nil) == false)
    precondition(inference.deviceMemorySize == 0)
    var called = false
    let data = ["x": MLCTensorData(linuxCopying: Data(count: 16))]
    precondition(inference.execute(inputsData: data, batchSize: 1, options: .synchronous) { result, error, time in
        called = true
        precondition(result == nil)
        precondition((error as NSError?)?.domain == MLComputeErrorDomain)
        precondition(time == 0)
    } == false)
    precondition(called)
    called = false
    precondition(inference.execute(inputsData: data, outputsData: nil, batchSize: 1, options: []) { _, _, _ in
        called = true
    } == false)
    precondition(called)
    called = false
    precondition(inference.execute(inputsData: data, lossLabelsData: nil, lossLabelWeightsData: nil, batchSize: 1, options: []) { _, _, _ in
        called = true
    } == false)
    precondition(called)
    called = false
    precondition(inference.execute(inputsData: data, lossLabelsData: nil, lossLabelWeightsData: nil, outputsData: nil, batchSize: 1, options: []) { _, _, _ in
        called = true
    } == false)
    precondition(called)
    let empty = MLCInferenceGraph()
    precondition(empty.link(with: [inference]))
    precondition(MLComputeErrorCode.compileFailed.rawValue == 3)
    precondition(MLComputeErrorCode.executeFailed.rawValue == 4)
    precondition(MLComputeError.gpuUnavailable.nsError.code == 1)
    precondition(MLComputeError.aneUnavailable.nsError.code == 2)
}

func testTrainingCompileExecuteFailClosed() {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 4])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let optDesc = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    let training = MLCTrainingGraph(
        graphObjects: [graph],
        lossLayer: MLCLossLayer.meanSquaredError(reductionType: .mean, weight: 1),
        optimizer: MLCAdamOptimizer(descriptor: optDesc)
    )
    precondition(training.optimizer is MLCAdamOptimizer)
    precondition(training.addInputs(["x": input], lossLabels: ["y": input]))
    precondition(training.addInputs(["x": input], lossLabels: nil, lossLabelWeights: nil))
    precondition(training.addOutputs(["y": input]))
    let cpu = MLCDevice.cpu()
    precondition(training.compile(options: [], device: cpu) == false)
    precondition(training.compile(options: [.computeAllGradients], device: cpu, inputTensors: nil, inputTensorsData: nil) == false)
    precondition(training.compileOptimizer(MLCSGDOptimizer(descriptor: optDesc)) == false)
    precondition(training.link(with: []) == false)
    precondition(training.allocateUserGradient(for: input) != nil)
    precondition(training.bindOptimizerData([MLCTensorData(linuxCopying: Data(count: 4))], deviceData: nil, with: input))
    _ = training.gradientData(forParameter: input, layer: MLCActivationLayer.relu)
    precondition(training.gradientTensor(forInput: input) != nil)
    _ = training.resultGradientTensors(for: MLCActivationLayer.relu)
    _ = training.sourceGradientTensors(for: MLCActivationLayer.relu)
    precondition(training.setTrainingTensorParameters([MLCTensorParameter(tensor: input)]))
    precondition(training.stopGradient(for: [input]))
    training.synchronizeUpdates()
    var called = false
    precondition(training.executeForward(batchSize: 1, options: []) { _, error, _ in
        called = true
        precondition((error as NSError?)?.domain == MLComputeErrorDomain)
    } == false)
    precondition(called)
    called = false
    precondition(training.executeForward(batchSize: 1, options: [], outputsData: nil) { _, _, _ in called = true } == false)
    precondition(called)
    called = false
    precondition(training.executeGradient(batchSize: 1, options: []) { _, _, _ in called = true } == false)
    precondition(called)
    called = false
    precondition(training.executeGradient(batchSize: 1, options: [], outputsData: nil) { _, _, _ in called = true } == false)
    precondition(called)
    called = false
    precondition(training.executeOptimizerUpdate(options: []) { _, _, _ in called = true } == false)
    precondition(called)
    called = false
    let data = ["x": MLCTensorData(linuxCopying: Data(count: 16))]
    precondition(training.execute(inputsData: data, lossLabelsData: nil, lossLabelWeightsData: nil, batchSize: 1, options: []) { _, _, _ in called = true } == false)
    precondition(called)
    called = false
    precondition(training.execute(inputsData: data, lossLabelsData: nil, lossLabelWeightsData: nil, outputsData: nil, batchSize: 1, options: []) { _, _, _ in called = true } == false)
    precondition(called)
    precondition(training.deviceMemorySize == 0)
    precondition(MLComputeError.unsupportedDataType(.float16).nsError.code == 6)
    precondition(MLComputeError.invalidGeometry("x").nsError.domain == MLComputeErrorDomain)
}

func testConvolutionShapeInference() {
    let graph = MLCGraph()
    let input = MLCTensor(width: 8, height: 8, featureChannelCount: 2, batchSize: 1)
    let weights = MLCTensor(
        descriptor: MLCTensorDescriptor(
            convolutionWeightsWithWidth: 3,
            height: 3,
            inputFeatureChannelCount: 2,
            outputFeatureChannelCount: 4,
            dataType: .float32
        )!
    )
    let conv = MLCConvolutionLayer(
        weights: weights,
        biases: nil,
        descriptor: MLCConvolutionDescriptor(
            type: .standard,
            kernelSizes: (3, 3),
            inputFeatureChannelCount: 2,
            outputFeatureChannelCount: 4,
            paddingPolicy: .same
        )
    )!
    let output = graph.node(with: conv, source: input)!
    precondition(output.descriptor.shape == [1, 4, 8, 8])
    let pool = MLCPoolingLayer(
        descriptor: MLCPoolingDescriptor(type: .max, kernelSizes: (2, 2), strides: (2, 2), paddingPolicy: .valid)
    )
    let pooled = graph.node(with: pool, source: output)!
    precondition(pooled.descriptor.shape[2] == 4)
}
