@_exported import Foundation
import Dispatch

/// Exact iPhoneOS 26.1 runtime string. The public header name is MLModelErrorDomain;
/// Apple's NSError domain is `com.apple.CoreML`, not `com.apple.CoreML.ErrorDomain`.
public let MLModelErrorDomain = "com.apple.CoreML"

func coreMLError(
    _ code: MLModelError.Code,
    _ message: String
) -> MLModelError {
    MLModelError(code, userInfo: [NSLocalizedDescriptionKey: message])
}

func coreMLNoBackend(_ operation: String) -> MLModelError {
    coreMLError(
        .generic,
        "CoreML has no compiled-model runtime on Linux: \(operation) is unavailable."
    )
}

func coreMLNoModelIO(_ operation: String) -> MLModelError {
    coreMLError(
        .io,
        "CoreML cannot compile or deserialize Apple .mlmodel/.mlmodelc artifacts on Linux: \(operation)."
    )
}

/// Apple's missing-model `MLModel.load` completion uses domain `com.apple.CoreML` code 0.
func coreMLMissingModelLoad(_ operation: String) -> MLModelError {
    coreMLError(
        .generic,
        "CoreML cannot load a compiled model on Linux: \(operation)."
    )
}

private struct CoreMLUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

final class CoreMLOnceToken: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func run(_ body: () -> Void) {
        lock.lock()
        let shouldRun = !delivered
        if shouldRun {
            delivered = true
        }
        lock.unlock()
        if shouldRun {
            body()
        }
    }
}

/// Fail-closed completion delivery: non-inline, exactly once, race-safe.
/// The hop is only required to be off the caller; no particular queue is claimed.
/// A short deadline also establishes an observable return-before-callback
/// boundary, rather than racing the caller against an immediately scheduled
/// global-queue job.
func coreMLDeliverCompletion(_ body: @escaping () -> Void) {
    let token = CoreMLOnceToken()
    let work = CoreMLUncheckedWork(body: {
        token.run(body)
    })
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(1)) {
        work.body()
    }
}

func coreMLAwaitCompletion<T>(
    _ start: (@escaping (Result<T, any Error>) -> Void) -> Void
) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        start { result in
            continuation.resume(with: result)
        }
    }
}

func coreMLCheckedMultiply(_ lhs: Int, _ rhs: Int) -> Int? {
    let (value, overflow) = lhs.multipliedReportingOverflow(by: rhs)
    return overflow ? nil : value
}

func coreMLCheckedAdd(_ lhs: Int, _ rhs: Int) -> Int? {
    let (value, overflow) = lhs.addingReportingOverflow(rhs)
    return overflow ? nil : value
}

func coreMLCContiguousStrides(shape: [Int]) -> [Int] {
    guard !shape.isEmpty else { return [] }
    var strides = Array(repeating: 1, count: shape.count)
    if shape.count >= 2 {
        for index in stride(from: shape.count - 2, through: 0, by: -1) {
            guard let next = coreMLCheckedMultiply(strides[index + 1], shape[index + 1]) else {
                return strides
            }
            strides[index] = next
        }
    }
    return strides
}

func coreMLElementCount(shape: [Int]) -> Int {
    var count = 1
    for dimension in shape {
        guard let next = coreMLCheckedMultiply(count, dimension) else {
            return 0
        }
        count = next
    }
    return count
}

func coreMLByteCount(count: Int, dataType: MLMultiArrayDataType) -> Int {
    coreMLCheckedMultiply(count, dataType.byteSize) ?? 0
}

func coreMLUnravel(linear: Int, shape: [Int]) -> [Int] {
    guard !shape.isEmpty else { return [] }
    var remaining = linear
    var indices = Array(repeating: 0, count: shape.count)
    for axis in stride(from: shape.count - 1, through: 0, by: -1) {
        let dimension = shape[axis]
        if dimension <= 0 {
            indices[axis] = 0
            continue
        }
        indices[axis] = remaining % dimension
        remaining /= dimension
    }
    return indices
}

func coreMLHighestReachableOffset(shape: [Int], strides: [Int]) -> Int? {
    if shape.contains(where: { $0 == 0 }) {
        return 0
    }
    var offset = 0
    for (dimension, stride) in zip(shape, strides) {
        guard dimension >= 0, stride >= 0 else { return nil }
        guard dimension > 0 else { continue }
        guard let spanned = coreMLCheckedMultiply(dimension - 1, stride) else { return nil }
        guard let next = coreMLCheckedAdd(offset, spanned) else { return nil }
        offset = next
    }
    return offset
}

func coreMLValidateMultiArrayLayout(
    shape: [Int],
    strides: [Int]?,
    dataType: MLMultiArrayDataType
) throws -> (shape: [Int], strides: [Int], byteCount: Int) {
    if let strides, strides.count != shape.count {
        throw coreMLError(.featureType, "MLMultiArray rank of shape and strides must match.")
    }
    guard shape.allSatisfy({ $0 >= 0 }) else {
        throw coreMLError(.io, "MLMultiArray shape must be non-negative.")
    }
    let resolvedStrides = strides ?? coreMLCContiguousStrides(shape: shape)
    guard resolvedStrides.allSatisfy({ $0 >= 0 }) else {
        throw coreMLError(.io, "MLMultiArray strides must be non-negative.")
    }
    var elementCount = 1
    for dimension in shape {
        guard let next = coreMLCheckedMultiply(elementCount, dimension) else {
            throw coreMLError(.io, "MLMultiArray shape overflows Int.")
        }
        elementCount = next
    }
    guard let highest = coreMLHighestReachableOffset(shape: shape, strides: resolvedStrides) else {
        throw coreMLError(.io, "MLMultiArray layout overflows Int.")
    }
    let spannedElements: Int
    if shape.contains(where: { $0 == 0 }) {
        spannedElements = 0
    } else {
        guard let count = coreMLCheckedAdd(highest, 1) else {
            throw coreMLError(.io, "MLMultiArray layout overflows Int.")
        }
        spannedElements = count
    }
    let allocationCount = max(spannedElements, 1)
    guard let byteCount = coreMLCheckedMultiply(allocationCount, dataType.byteSize) else {
        throw coreMLError(.io, "MLMultiArray byte count overflows Int.")
    }
    return (shape, resolvedStrides, spannedElements == 0 ? 0 : byteCount)
}

/// Portable counterpart of CoreML's bridged `NS_ERROR_ENUM`.
public struct MLModelError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case generic = 0
        case featureType = 1
        case io = 3
        case customLayer = 4
        case customModel = 5
        case update = 6
        case parameters = 7
        case modelDecryptionKeyFetch = 8
        case modelDecryption = 9
        case modelCollection = 10
        case predictionCancelled = 11
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MLModelErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let generic = Code.generic
    public static let featureType = Code.featureType
    public static let io = Code.io
    public static let customLayer = Code.customLayer
    public static let customModel = Code.customModel
    public static let update = Code.update
    public static let parameters = Code.parameters
    public static let modelDecryptionKeyFetch = Code.modelDecryptionKeyFetch
    public static let modelDecryption = Code.modelDecryption
    public static let modelCollection = Code.modelCollection
    public static let predictionCancelled = Code.predictionCancelled

    public static func == (lhs: MLModelError, rhs: MLModelError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MLModelError.Code {
    public static func ~= (match: MLModelError.Code, error: any Error) -> Bool {
        (error as? MLModelError)?.code == match
    }
}

public enum MLComputeUnits: Int, Hashable, Sendable {
    case cpuOnly = 0
    case cpuAndGPU = 1
    case all = 2
    case cpuAndNeuralEngine = 3
}

public enum MLFeatureType: Int, Hashable, Sendable {
    case invalid = 0
    case int64 = 1
    case double = 2
    case string = 3
    case image = 4
    case multiArray = 5
    case dictionary = 6
    case sequence = 7
    case state = 8
}

public enum MLImageSizeConstraintType: Int, Hashable, Sendable {
    case unspecified = 0
    case enumerated = 2
    case range = 3
}

public enum MLMultiArrayDataType: Int, Hashable, Sendable {
    case double = 0x10040
    case float32 = 0x10020
    case float16 = 0x10010
    case int32 = 0x20020
    case int8 = 0x20008

    public static var float: MLMultiArrayDataType { .float32 }
    public static var float64: MLMultiArrayDataType { .double }

    public var byteSize: Int {
        switch self {
        case .double: return 8
        case .float32, .int32: return 4
        case .float16: return 2
        case .int8: return 1
        }
    }
}

public enum MLMultiArrayShapeConstraintType: Int, Hashable, Sendable {
    case unspecified = 1
    case enumerated = 2
    case range = 3
}

public enum MLTaskState: Int, Hashable, Sendable {
    case suspended = 1
    case running = 2
    case cancelling = 3
    case completed = 4
    case failed = 5
}

public struct MLUpdateProgressEvent: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let trainingBegin = MLUpdateProgressEvent(rawValue: 1 << 0)
    public static let miniBatchEnd = MLUpdateProgressEvent(rawValue: 1 << 1)
    public static let epochEnd = MLUpdateProgressEvent(rawValue: 1 << 2)
}

public struct MLModelMetadataKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let author = MLModelMetadataKey(rawValue: "com.apple.coreml.model.author")
    public static let description = MLModelMetadataKey(rawValue: "com.apple.coreml.model.description")
    public static let versionString = MLModelMetadataKey(rawValue: "com.apple.coreml.model.versionstring")
    public static let license = MLModelMetadataKey(rawValue: "com.apple.coreml.model.license")
    public static let creatorDefinedKey = MLModelMetadataKey(rawValue: "com.apple.coreml.model.creatordefined")
}

public struct MLOptimizationHints: Hashable, Sendable {
    public enum ReshapeFrequency: Int, Hashable, Sendable {
        case frequent = 0
        case infrequent = 1
    }

    public enum SpecializationStrategy: Int, Hashable, Sendable {
        case `default` = 0
        case fastPrediction = 1
    }

    public var reshapeFrequency: ReshapeFrequency
    public var specializationStrategy: SpecializationStrategy

    public init() {
        self.reshapeFrequency = .frequent
        self.specializationStrategy = .default
    }
}

open class MLKey: NSObject, NSSecureCoding {
    public let name: String
    public let scope: String?

    public static var supportsSecureCoding: Bool { true }

    init(name: String, scope: String? = nil) {
        self.name = name
        self.scope = scope
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MLKey else { return false }
        return name == other.name && scope == other.scope
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(scope)
        return hasher.finalize()
    }
}

open class MLParameterKey: MLKey {
    public static let beta1 = MLParameterKey(name: "beta1")
    public static let beta2 = MLParameterKey(name: "beta2")
    public static let biases = MLParameterKey(name: "biases")
    public static let epochs = MLParameterKey(name: "epochs")
    public static let eps = MLParameterKey(name: "eps")
    public static let learningRate = MLParameterKey(name: "learningRate")
    public static let linkedModelFileName = MLParameterKey(name: "linkedModelFileName")
    public static let linkedModelSearchPath = MLParameterKey(name: "linkedModelSearchPath")
    public static let miniBatchSize = MLParameterKey(name: "miniBatchSize")
    public static let momentum = MLParameterKey(name: "momentum")
    public static let numberOfNeighbors = MLParameterKey(name: "numberOfNeighbors")
    public static let seed = MLParameterKey(name: "seed")
    public static let shuffle = MLParameterKey(name: "shuffle")
    public static let weights = MLParameterKey(name: "weights")

    public func scoped(to scope: String) -> MLParameterKey {
        MLParameterKey(name: name, scope: scope)
    }
}

open class MLMetricKey: MLKey {
    public static let epochIndex = MLMetricKey(name: "epochIndex")
    public static let lossValue = MLMetricKey(name: "lossValue")
    public static let miniBatchIndex = MLMetricKey(name: "miniBatchIndex")
}

public protocol MLComputeDeviceProtocol: NSObjectProtocol {}

public protocol MLFeatureProvider {
    var featureNames: Set<String> { get }
    func featureValue(for featureName: String) -> MLFeatureValue?
}

public protocol MLBatchProvider {
    var count: Int { get }
    func features(at index: Int) -> any MLFeatureProvider
}

public protocol MLWritable: NSObjectProtocol {
    func write(to url: URL) throws
}

public protocol MLCustomLayer {
    init(parameters: [String: Any]) throws
    init(parameterDictionary parameters: [String: Any]) throws
    func setWeightData(_ weights: [Data]) throws
    func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws -> [[NSNumber]]
    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws
}

public protocol MLCustomModel {
    init(modelDescription: MLModelDescription, parameters: [String: Any]) throws
    init(modelDescription: MLModelDescription, parameterDictionary parameters: [String: Any]) throws
    func prediction(from input: any MLFeatureProvider, options: MLPredictionOptions) throws -> any MLFeatureProvider
    func predictions(from inputBatch: any MLBatchProvider, options: MLPredictionOptions) throws -> any MLBatchProvider
}

extension MLCustomLayer {
    public init(parameterDictionary parameters: [String: Any]) throws {
        try self.init(parameters: parameters)
    }
}

/// Linux stand-in that keeps `MLCustomLayer` fail-closed. Clients cannot
/// register a working custom layer without a compiled-model runtime.
open class MLFailClosedCustomLayer: NSObject, MLCustomLayer {
    public required init(parameters: [String: Any]) throws {
        _ = parameters
        super.init()
        throw coreMLError(.customLayer, "MLCustomLayer is fail-closed on Linux.")
    }

    public func setWeightData(_ weights: [Data]) throws {
        _ = weights
        throw coreMLError(.customLayer, "MLCustomLayer is fail-closed on Linux.")
    }

    public func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws -> [[NSNumber]] {
        _ = inputShapes
        throw coreMLError(.customLayer, "MLCustomLayer is fail-closed on Linux.")
    }

    public func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
        _ = (inputs, outputs)
        throw coreMLError(.customLayer, "MLCustomLayer is fail-closed on Linux.")
    }
}

extension MLCustomModel {
    public func predictions(
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
}

public protocol MLTensorScalar: Sendable {}

extension Float: MLTensorScalar {}
extension Double: MLTensorScalar {}
extension Float16: MLTensorScalar {}
extension Int8: MLTensorScalar {}
extension Int32: MLTensorScalar {}
extension Bool: MLTensorScalar {}
