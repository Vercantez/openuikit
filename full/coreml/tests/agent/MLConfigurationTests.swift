import CoreML
import Foundation

func testModelConfigurationDefaultsAndCopy() {
    let configuration = MLModelConfiguration()
    precondition(configuration.computeUnits == .all)
    precondition(configuration.computeUnits.rawValue == 2)
    precondition(configuration.allowLowPrecisionAccumulationOnGPU == false)
    configuration.computeUnits = .cpuOnly
    configuration.allowLowPrecisionAccumulationOnGPU = true
    configuration.functionName = "main"
    configuration.modelDisplayName = "AgeNet"
    configuration.parameters = [MLParameterKey.learningRate: 0.01]
    configuration.optimizationHints.reshapeFrequency = .infrequent
    configuration.optimizationHints.specializationStrategy = .fastPrediction
    precondition(configuration.preferredMetalDevice == nil)
    configuration.preferredMetalDevice = nil
    let copyingWitness: any Foundation.NSCopying = configuration
    _ = copyingWitness
    let copy = configuration.copy() as! MLModelConfiguration
    precondition(copy !== configuration)
    precondition(copy.computeUnits == .cpuOnly)
    precondition(copy.allowLowPrecisionAccumulationOnGPU == true)
    precondition(copy.functionName == "main")
    precondition(copy.modelDisplayName == "AgeNet")
    precondition((copy.parameters?[MLParameterKey.learningRate] as? Double) == 0.01)
    precondition(copy.optimizationHints.reshapeFrequency == .infrequent)
    precondition(copy.optimizationHints.specializationStrategy == .fastPrediction)
    copy.encode(with: NSCoder())
    precondition(MLModelConfiguration(coder: NSCoder()) == nil)
    _ = MLModelConfiguration.supportsSecureCoding
    _ = configuration.optimizationHints
}

func testPredictionOptionsAndOptimizationHints() {
    let options = MLPredictionOptions()
    precondition(options.usesCPUOnly == false)
    options.usesCPUOnly = true
    options.outputBackings = ["out": 1]
    precondition(options.outputBackings["out"] as? Int == 1)
    let hints = MLOptimizationHints()
    precondition(hints.reshapeFrequency == .frequent)
    precondition(hints.specializationStrategy == .default)
    let other = MLOptimizationHints()
    precondition(hints == other)
    var mutated = MLOptimizationHints()
    mutated.reshapeFrequency = .infrequent
    precondition(hints != mutated)
    precondition(MLOptimizationHints.ReshapeFrequency.frequent != .infrequent)
    precondition(MLOptimizationHints.SpecializationStrategy.default != .fastPrediction)
}

func testParameterMetricAndMetadataKeys() {
    precondition(MLParameterKey.learningRate.name == "learningRate")
    let scoped = MLParameterKey.weights.scoped(to: "conv1")
    precondition(scoped.scope == "conv1")
    precondition(MLParameterKey.beta1.name == "beta1")
    precondition(MLParameterKey.beta2.name == "beta2")
    precondition(MLParameterKey.biases.name == "biases")
    precondition(MLParameterKey.epochs.name == "epochs")
    precondition(MLParameterKey.eps.name == "eps")
    precondition(MLParameterKey.linkedModelFileName.name == "linkedModelFileName")
    precondition(MLParameterKey.linkedModelSearchPath.name == "linkedModelSearchPath")
    precondition(MLParameterKey.miniBatchSize.name == "miniBatchSize")
    precondition(MLParameterKey.momentum.name == "momentum")
    precondition(MLParameterKey.numberOfNeighbors.name == "numberOfNeighbors")
    precondition(MLParameterKey.seed.name == "seed")
    precondition(MLParameterKey.shuffle.name == "shuffle")
    precondition(MLMetricKey.lossValue.name == "lossValue")
    precondition(MLMetricKey.epochIndex.name == "epochIndex")
    precondition(MLMetricKey.miniBatchIndex.name == "miniBatchIndex")
    precondition(MLModelMetadataKey.author.rawValue.contains("author"))
    precondition(MLModelMetadataKey.description.rawValue.contains("description"))
    precondition(MLModelMetadataKey.versionString.rawValue.contains("versionstring"))
    precondition(MLModelMetadataKey.license.rawValue.contains("license"))
    precondition(MLModelMetadataKey.creatorDefinedKey.rawValue.contains("creatordefined"))
    precondition(MLModelMetadataKey(rawValue: "x") != .author)
    _ = MLModelMetadataKey.author.hashValue
    var hasher = Hasher()
    MLModelMetadataKey.author.hash(into: &hasher)
    precondition(MLKey(coder: NSCoder()) == nil)
    _ = MLKey.supportsSecureCoding
}

func testComputeDevicesAreCPUOnly() {
    let devices = MLModel.availableComputeDevices
    precondition(devices.count == 1)
    guard case .cpu = devices[0] else {
        fatalError("Linux CoreML must advertise only CPU")
    }
    precondition(MLComputeDevice.allComputeDevices.count == 1)
    precondition(MLComputeDevice.allComputeDevices[0] == devices[0])
    let ane = MLNeuralEngineComputeDevice()
    precondition(ane.totalCoreCount == 0)
    let policy = MLComputePolicy(.cpuOnly)
    precondition(policy == .cpuOnly)
    precondition(policy.description.contains("cpuOnly"))
    _ = policy.hashValue
    var hasher = Hasher()
    policy.hash(into: &hasher)
    _ = policy.customMirror
    precondition(MLComputePolicy.cpuAndGPU != .cpuOnly)
    _ = MLCPUComputeDevice()
    _ = MLGPUComputeDevice()
    let protocolWitness: any MLComputeDeviceProtocol = MLCPUComputeDevice()
    _ = protocolWitness
}
