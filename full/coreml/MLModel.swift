import Foundation

open class MLPredictionOptions: NSObject {
    open var usesCPUOnly: Bool
    open var outputBackings: [String: Any]

    public override init() {
        self.usesCPUOnly = false
        self.outputBackings = [:]
        super.init()
    }
}

open class MLModelConfiguration: NSObject, NSSecureCoding, Foundation.NSCopying {
    public static var supportsSecureCoding: Bool { true }

    open var computeUnits: MLComputeUnits
    open var allowLowPrecisionAccumulationOnGPU: Bool
    /// Metal is not linked by this isolated compile. The Apple overlay types this
    /// as `(any MTLDevice)?`; Linux stores a nil object so clients observe no device.
    open var preferredMetalDevice: AnyObject?
    open var functionName: String?
    open var modelDisplayName: String?
    open var parameters: [MLParameterKey: Any]?
    open var optimizationHints: MLOptimizationHints

    public override init() {
        self.computeUnits = .all
        self.allowLowPrecisionAccumulationOnGPU = false
        self.preferredMetalDevice = nil
        self.functionName = nil
        self.modelDisplayName = nil
        self.parameters = nil
        self.optimizationHints = MLOptimizationHints()
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}

    /// Exact `NSCopying` witness. `NSObject.copy()` dispatches `copyWithZone:`
    /// through this method on Apple Foundation and swift-corelibs Foundation.
    open func copy(with zone: NSZone?) -> Any {
        _ = zone
        let copied = MLModelConfiguration()
        copied.computeUnits = computeUnits
        copied.allowLowPrecisionAccumulationOnGPU = allowLowPrecisionAccumulationOnGPU
        copied.preferredMetalDevice = preferredMetalDevice
        copied.functionName = functionName
        copied.modelDisplayName = modelDisplayName
        copied.parameters = parameters
        copied.optimizationHints = optimizationHints
        return copied
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
    let sourceURL: URL?
    private let specificationData: Data?

    public convenience init(url compiledModelURL: URL) throws {
        try self.init(URL: compiledModelURL)
    }

    public init(URL compiledModelURL: URL) throws {
        self.sourceURL = compiledModelURL
        self.specificationData = nil
        super.init()
    }

    public init(specification specificationData: Data) throws {
        self.sourceURL = nil
        self.specificationData = specificationData
        super.init()
    }

    public init(specification specificationData: Data, blobMapping: [URL: Data]) throws {
        _ = blobMapping
        self.sourceURL = nil
        self.specificationData = specificationData
        super.init()
    }

    public func functionNames(completionHandler handler: @escaping ([String]?, (any Error)?) -> Void) {
        _ = (sourceURL, specificationData)
        let error = coreMLNoBackend("MLModelAsset.functionNames")
        coreMLDeliverCompletion {
            handler(nil, error)
        }
    }

    public func modelDescription(
        of functionName: String,
        completionHandler handler: @escaping (MLModelDescription?, (any Error)?) -> Void
    ) {
        _ = functionName
        let error = coreMLNoBackend("MLModelAsset.modelDescription(of:)")
        coreMLDeliverCompletion {
            handler(nil, error)
        }
    }

    public func modelDescription(of functionName: String) async throws -> MLModelDescription {
        try await withCheckedThrowingContinuation { continuation in
            modelDescription(of: functionName) { description, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let description {
                    continuation.resume(returning: description)
                } else {
                    continuation.resume(throwing: coreMLNoBackend("MLModelAsset.modelDescription(of:)"))
                }
            }
        }
    }

    public func modelDescription(completionHandler handler: @escaping (MLModelDescription?, (any Error)?) -> Void) {
        let error = coreMLNoBackend("MLModelAsset.modelDescription")
        coreMLDeliverCompletion {
            handler(nil, error)
        }
    }
}

open class MLModel: NSObject {
    public let configuration: MLModelConfiguration
    public let modelDescription: MLModelDescription
    let compiled: CoreMLCompiledModel?

    public static var availableComputeDevices: [MLComputeDevice] {
        MLComputeDevice.allComputeDevices
    }

    init(configuration: MLModelConfiguration, modelDescription: MLModelDescription, compiled: CoreMLCompiledModel? = nil) {
        self.configuration = configuration
        self.modelDescription = modelDescription
        self.compiled = compiled
        super.init()
    }

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOf: url, configuration: MLModelConfiguration())
    }

    public convenience init(contentsOfURL url: URL) throws {
        try self.init(contentsOf: url)
    }

    public init(contentsOf url: URL, configuration: MLModelConfiguration) throws {
        let spec = try CoreMLModelCodec.load(contentsOf: url)
        self.configuration = configuration
        self.modelDescription = spec.description
        self.compiled = spec
        super.init()
    }

    public convenience init(contentsOfURL url: URL, configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: url, configuration: configuration)
    }

    open class func load(
        _ asset: MLModelAsset,
        configuration: MLModelConfiguration,
        completionHandler handler: @escaping (MLModel?, (any Error)?) -> Void
    ) {
        load(contentsOf: asset.sourceURL ?? URL(fileURLWithPath: "/tmp/missing.mlmodelc"), configuration: configuration) { result in
            switch result {
            case .success(let model):
                handler(model, nil)
            case .failure(let error):
                handler(nil, error)
            }
        }
    }

    open class func load(
        contentsOf url: URL,
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Result<MLModel, any Error>) -> Void
    ) {
        coreMLDeliverCompletion {
            do {
                let model = try MLModel(contentsOf: url, configuration: configuration)
                handler(.success(model))
            } catch {
                handler(.failure(coreMLMissingModelLoad("MLModel.load(contentsOf:configuration:)")))
            }
        }
    }

    open class func load(
        contentsOf url: URL,
        configuration: MLModelConfiguration = MLModelConfiguration()
    ) async throws -> MLModel {
        try await coreMLAwaitCompletion { completion in
            load(contentsOf: url, configuration: configuration, completionHandler: completion)
        }
    }

    open class func compileModel(at modelURL: URL) throws -> URL {
        try CoreMLModelCodec.compile(contentsOf: modelURL)
    }

    open class func compileModel(at modelURL: URL) async throws -> URL {
        try await coreMLAwaitCompletion { completion in
            compileModel(at: modelURL, completionHandler: completion)
        }
    }

    open class func compileModel(
        at url: URL,
        completionHandler handler: @escaping (Result<URL, any Error>) -> Void
    ) {
        coreMLDeliverCompletion {
            do {
                handler(.success(try compileModel(at: url)))
            } catch {
                handler(.failure(error))
            }
        }
    }

    open func parameterValue(for key: MLParameterKey) throws -> Any {
        if let value = configuration.parameters?[key] {
            return value
        }
        throw coreMLError(.parameters, "MLModel has no value for parameter \(key.name).")
    }

    open func prediction(from input: any MLFeatureProvider) throws -> any MLFeatureProvider {
        try prediction(from: input, options: MLPredictionOptions())
    }

    open func prediction(
        from input: any MLFeatureProvider,
        options: MLPredictionOptions
    ) throws -> any MLFeatureProvider {
        guard let compiled else {
            throw coreMLNoBackend("MLModel.prediction(from:options:)")
        }
        return try coreMLPredict(compiled, from: input, options: options)
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
        _ = state
        return try prediction(from: inputFeatures, options: options)
    }

    open func prediction(
        from input: any MLFeatureProvider,
        using state: MLState,
        options: MLPredictionOptions = MLPredictionOptions()
    ) async throws -> any MLFeatureProvider {
        _ = state
        guard let compiled else {
            throw coreMLNoBackend("MLModel.prediction(from:using:options:)")
        }
        return try coreMLPredict(compiled, from: input, options: options)
    }

    open func prediction(
        from input: any MLFeatureProvider,
        options: MLPredictionOptions = MLPredictionOptions()
    ) async throws -> any MLFeatureProvider {
        guard let compiled else {
            throw coreMLNoBackend("MLModel.prediction(from:options:)")
        }
        return try coreMLPredict(compiled, from: input, options: options)
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
        var rows: [any MLFeatureProvider] = []
        rows.reserveCapacity(inputBatch.count)
        for index in 0..<inputBatch.count {
            rows.append(try prediction(from: inputBatch.features(at: index), options: options))
        }
        return MLArrayBatchProvider(array: rows)
    }

    open func makeState() -> MLState {
        var buffers: [String: MLMultiArray] = [:]
        for (name, description) in modelDescription.stateDescriptionsByName {
            let shape = description.stateConstraint?.bufferShape ?? [1]
            let dataType = description.stateConstraint?.dataType ?? .float32
            if let array = try? MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: dataType) {
                buffers[name] = array
            }
        }
        return MLState(buffers: buffers)
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
