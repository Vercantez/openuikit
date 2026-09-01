import Foundation

open class MLPredictionOptions: NSObject {
    open var usesCPUOnly: Bool
    open var outputBackings: [String: Any]

    public override init() {
        self.usesCPUOnly = true
        self.outputBackings = [:]
        super.init()
    }
}

open class MLModelConfiguration: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var computeUnits: MLComputeUnits
    open var allowLowPrecisionAccumulationOnGPU: Bool
    open var functionName: String?
    open var modelDisplayName: String?
    open var parameters: [MLParameterKey: Any]?
    open var optimizationHints: MLOptimizationHints

    public override init() {
        self.computeUnits = .cpuOnly
        self.allowLowPrecisionAccumulationOnGPU = false
        self.functionName = nil
        self.modelDisplayName = nil
        self.parameters = nil
        self.optimizationHints = MLOptimizationHints()
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = MLModelConfiguration()
        copy.computeUnits = computeUnits
        copy.allowLowPrecisionAccumulationOnGPU = allowLowPrecisionAccumulationOnGPU
        copy.functionName = functionName
        copy.modelDisplayName = modelDisplayName
        copy.parameters = parameters
        copy.optimizationHints = optimizationHints
        return copy
    }
}

open class MLState: NSObject {
    private let buffers: [String: MLMultiArray]

    public override init() {
        self.buffers = [:]
        super.init()
    }

    init(buffers: [String: MLMultiArray]) {
        self.buffers = buffers
        super.init()
    }

    public func withMultiArray<R>(for stateName: String, _ body: (MLMultiArray) throws -> R) rethrows -> R {
        guard let array = buffers[stateName] else {
            fatalError("MLState has no buffer named \(stateName)")
        }
        return try body(array)
    }

    public func withMultiArray<R>(_ body: (MLMultiArray) -> R) throws -> R {
        guard let array = buffers.values.first else {
            throw coreMLError(.generic, "MLState has no backing multi-arrays on Linux.")
        }
        return body(array)
    }
}

open class MLModelAsset: NSObject {
    private let sourceURL: URL?
    private let specificationData: Data?

    public convenience init(url compiledModelURL: URL) throws {
        try self.init(URL: compiledModelURL)
    }

    public init(URL compiledModelURL: URL) throws {
        self.sourceURL = compiledModelURL
        self.specificationData = nil
        super.init()
        throw coreMLNoModelIO("MLModelAsset.init(URL:)")
    }

    public init(specification specificationData: Data) throws {
        self.sourceURL = nil
        self.specificationData = specificationData
        super.init()
        throw coreMLNoModelIO("MLModelAsset.init(specification:)")
    }

    public init(specification specificationData: Data, blobMapping: [URL: Data]) throws {
        _ = blobMapping
        self.sourceURL = nil
        self.specificationData = specificationData
        super.init()
        throw coreMLNoModelIO("MLModelAsset.init(specification:blobMapping:)")
    }

    public func functionNames(completionHandler handler: @escaping ([String]?, (any Error)?) -> Void) {
        handler(nil, coreMLNoBackend("MLModelAsset.functionNames"))
    }

    public func modelDescription(of functionName: String) async throws -> MLModelDescription {
        _ = functionName
        throw coreMLNoBackend("MLModelAsset.modelDescription(of:)")
    }

    public func modelDescription(completionHandler handler: @escaping (MLModelDescription?, (any Error)?) -> Void) {
        handler(nil, coreMLNoBackend("MLModelAsset.modelDescription"))
    }
}

open class MLModel: NSObject {
    public let configuration: MLModelConfiguration
    public let modelDescription: MLModelDescription

    public static var availableComputeDevices: [MLComputeDevice] {
        MLComputeDevice.allComputeDevices
    }

    init(configuration: MLModelConfiguration, modelDescription: MLModelDescription) {
        self.configuration = configuration
        self.modelDescription = modelDescription
        super.init()
    }

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOf: url, configuration: MLModelConfiguration())
    }

    public convenience init(contentsOfURL url: URL) throws {
        try self.init(contentsOf: url)
    }

    public init(contentsOf url: URL, configuration: MLModelConfiguration) throws {
        _ = url
        self.configuration = configuration
        self.modelDescription = MLModelDescription()
        super.init()
        throw coreMLNoModelIO("MLModel.init(contentsOf:configuration:)")
    }

    public convenience init(contentsOfURL url: URL, configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: url, configuration: configuration)
    }

    open class func load(
        _ asset: MLModelAsset,
        configuration: MLModelConfiguration,
        completionHandler handler: @escaping (MLModel?, (any Error)?) -> Void
    ) {
        _ = (asset, configuration)
        handler(nil, coreMLNoBackend("MLModel.load(_:configuration:)"))
    }

    open class func load(
        contentsOf url: URL,
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Result<MLModel, any Error>) -> Void
    ) {
        handler(.failure(coreMLNoModelIO("MLModel.load(contentsOf:configuration:)")))
    }

    open class func load(
        contentsOf url: URL,
        configuration: MLModelConfiguration = MLModelConfiguration()
    ) async throws -> MLModel {
        throw coreMLNoModelIO("MLModel.load(contentsOf:configuration:)")
    }

    open class func compileModel(at modelURL: URL) throws -> URL {
        _ = modelURL
        throw coreMLNoModelIO("MLModel.compileModel(at:)")
    }

    open class func compileModel(at modelURL: URL) async throws -> URL {
        _ = modelURL
        throw coreMLNoModelIO("MLModel.compileModel(at:)")
    }

    open class func compileModel(
        at url: URL,
        completionHandler handler: @escaping (Result<URL, any Error>) -> Void
    ) {
        handler(.failure(coreMLNoModelIO("MLModel.compileModel(at:completionHandler:)")))
    }

    open func parameterValue(for key: MLParameterKey) throws -> Any {
        _ = key
        throw coreMLError(.parameters, "MLModel parameter lookup has no compiled model on Linux.")
    }

    open func prediction(from input: any MLFeatureProvider) throws -> any MLFeatureProvider {
        try prediction(from: input, options: MLPredictionOptions())
    }

    open func prediction(
        from input: any MLFeatureProvider,
        options: MLPredictionOptions
    ) throws -> any MLFeatureProvider {
        _ = (input, options)
        throw coreMLNoBackend("MLModel.prediction(from:options:)")
    }

    open func prediction(
        from inputFeatures: any MLFeatureProvider,
        using state: MLState
    ) throws -> any MLFeatureProvider {
        try prediction(from: inputFeatures, using: state, options: MLPredictionOptions())
    }

    open func prediction(
        from inputFeatures: any MLFeatureProvider,
        using state: MLState,
        options: MLPredictionOptions
    ) throws -> any MLFeatureProvider {
        _ = (inputFeatures, state, options)
        throw coreMLNoBackend("MLModel.prediction(from:using:options:)")
    }

    open func prediction(
        from input: any MLFeatureProvider,
        using state: MLState,
        options: MLPredictionOptions = MLPredictionOptions()
    ) async throws -> any MLFeatureProvider {
        _ = (input, state, options)
        throw coreMLNoBackend("MLModel.prediction(from:using:options:)")
    }

    open func prediction(
        from input: any MLFeatureProvider,
        options: MLPredictionOptions = MLPredictionOptions()
    ) async throws -> any MLFeatureProvider {
        _ = (input, options)
        throw coreMLNoBackend("MLModel.prediction(from:options:)")
    }

    open func prediction(from inputs: [String: MLTensor]) async throws -> [String: MLTensor] {
        _ = inputs
        throw coreMLNoBackend("MLModel.prediction(from: tensors)")
    }

    open func prediction(
        from inputs: [String: MLTensor],
        using state: MLState
    ) async throws -> [String: MLTensor] {
        _ = (inputs, state)
        throw coreMLNoBackend("MLModel.prediction(from:using: tensors)")
    }

    open func predictions(fromBatch inputBatch: any MLBatchProvider) throws -> any MLBatchProvider {
        try predictions(from: inputBatch, options: MLPredictionOptions())
    }

    open func predictions(
        from inputBatch: any MLBatchProvider,
        options: MLPredictionOptions
    ) throws -> any MLBatchProvider {
        _ = (inputBatch, options)
        throw coreMLNoBackend("MLModel.predictions(from:options:)")
    }

    open func makeState() -> MLState {
        MLState()
    }
}

open class MLCPUComputeDevice: NSObject, MLComputeDeviceProtocol {
    public override init() {
        super.init()
    }
}

open class MLGPUComputeDevice: NSObject, MLComputeDeviceProtocol {
    public override init() {
        super.init()
    }
}

open class MLNeuralEngineComputeDevice: NSObject, MLComputeDeviceProtocol {
    public var totalCoreCount: Int { 0 }

    public override init() {
        super.init()
    }
}

public enum MLComputeDevice: Hashable, CustomStringConvertible {
    case cpu(MLCPUComputeDevice)
    case gpu(MLGPUComputeDevice)
    case neuralEngine(MLNeuralEngineComputeDevice)

    public static var allComputeDevices: [MLComputeDevice] {
        [.cpu(MLCPUComputeDevice())]
    }

    public var description: String {
        switch self {
        case .cpu: return "cpu"
        case .gpu: return "gpu"
        case .neuralEngine: return "neuralEngine"
        }
    }

    public static func == (a: MLComputeDevice, b: MLComputeDevice) -> Bool {
        switch (a, b) {
        case (.cpu, .cpu): return true
        case (.gpu, .gpu): return true
        case (.neuralEngine, .neuralEngine): return true
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .cpu: hasher.combine(0)
        case .gpu: hasher.combine(1)
        case .neuralEngine: hasher.combine(2)
        }
    }
}

public struct MLComputePolicy: Hashable, CustomStringConvertible, Sendable {
    public let computeUnits: MLComputeUnits

    public static var cpuOnly: MLComputePolicy { MLComputePolicy(.cpuOnly) }
    public static var cpuAndGPU: MLComputePolicy { MLComputePolicy(.cpuAndGPU) }

    public init(_ computeUnits: MLComputeUnits) {
        self.computeUnits = computeUnits
    }

    public var description: String { String(describing: computeUnits) }

    public var customMirror: Mirror {
        Mirror(self, children: ["computeUnits": computeUnits])
    }
}

public func withMLTensorComputePolicy<Result>(
    _ computePolicy: MLComputePolicy,
    _ body: () throws -> Result
) rethrows -> Result {
    _ = computePolicy
    return try body()
}

public func withMLTensorComputePolicy<R>(
    _ computePolicy: MLComputePolicy,
    _ body: () async throws -> R
) async rethrows -> R {
    _ = computePolicy
    return try await body()
}
