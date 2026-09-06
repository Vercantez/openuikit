import Foundation

/// Linux starting point for Apple's public `MLCompute` module.
/// Isolated host compilation produces `libMLCompute.dylib` with Foundation only.
/// GPU, ANE, Metal, and BNNS execution fail closed; CPU tensors, descriptors,
/// and graph topology are real.

public let MLComputeErrorDomain = "org.openuikit.MLCompute.linux"

public typealias MLCGraphCompletionHandler = (MLCTensor?, (any Error)?, TimeInterval) -> Void

public enum MLComputeErrorCode: Int, Sendable {
    case gpuUnavailable = 1
    case aneUnavailable = 2
    case compileFailed = 3
    case executeFailed = 4
    case invalidGeometry = 5
    case unsupportedDataType = 6
}

public enum MLComputeError: Error, Equatable {
    case gpuUnavailable
    case aneUnavailable
    case compileFailed(String)
    case executeFailed(String)
    case invalidGeometry(String)
    case unsupportedDataType(MLCDataType)

    public var nsError: NSError {
        let code: MLComputeErrorCode
        let message: String
        switch self {
        case .gpuUnavailable:
            code = .gpuUnavailable
            message = "MLCompute GPU devices require Metal, which is not available on this Linux host"
        case .aneUnavailable:
            code = .aneUnavailable
            message = "MLCompute Apple Neural Engine is not available on this Linux host"
        case .compileFailed(let detail):
            code = .compileFailed
            message = detail
        case .executeFailed(let detail):
            code = .executeFailed
            message = detail
        case .invalidGeometry(let detail):
            code = .invalidGeometry
            message = detail
        case .unsupportedDataType(let dataType):
            code = .unsupportedDataType
            message = "Unsupported MLCompute data type \(dataType.rawValue)"
        }
        return NSError(
            domain: MLComputeErrorDomain,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

func mlcFailClosedError(_ error: MLComputeError) -> NSError {
    error.nsError
}

enum MLCHostCounters {
    static var tensorID: Int = 1
    static var layerID: Int = 1
    static let lock = NSLock()

    static func nextTensorID() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let value = tensorID
        tensorID += 1
        return value
    }

    static func nextLayerID() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let value = layerID
        layerID += 1
        return value
    }
}

func mlcElementSize(_ dataType: MLCDataType) -> Int {
    switch dataType {
    case .float32, .int32: return 4
    case .float16: return 2
    case .boolean, .int8, .uint8: return 1
    case .int64: return 8
    }
}

func mlcContiguousStride(shape: [Int]) -> [Int] {
    guard !shape.isEmpty else { return [] }
    var stride = Array(repeating: 1, count: shape.count)
    var running = 1
    for index in stride.indices.reversed() {
        stride[index] = running
        running *= max(shape[index], 0)
    }
    return stride
}

func mlcShapeVolume(_ shape: [Int]) -> Int {
    shape.reduce(1, *)
}

func mlcRowMajorOffset(indices: [Int], stride: [Int]) -> Int {
    zip(indices, stride).reduce(0) { $0 + $1.0 * $1.1 }
}
