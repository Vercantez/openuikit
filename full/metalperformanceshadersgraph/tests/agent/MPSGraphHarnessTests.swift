import Foundation
import MetalPerformanceShadersGraph

func mpsgShape(_ dims: Int...) -> [NSNumber] {
    dims.map { $0 as NSNumber }
}

func mpsgFloatData(_ values: [Float], shape: [Int]) -> MPSGraphTensorData {
    let data = values.withUnsafeBytes { Data($0) }
    return MPSGraphTensorData(
        device: MPSGraphDevice.hostDevice(),
        data: data,
        shape: shape.map { $0 as NSNumber },
        dataType: .float32
    )
}

func mpsgFloats(_ data: MPSGraphTensorData) -> [Float] {
    data.storage.withUnsafeBytes { raw in
        Array(raw.bindMemory(to: Float.self).prefix(data.elementCount))
    }
}

func mpsgClose(_ actual: [Float], _ expected: [Float], eps: Float = 1e-5) {
    precondition(actual.count == expected.count, "count \(actual.count) vs \(expected.count)")
    for (lhs, rhs) in zip(actual, expected) {
        let ok = abs(lhs - rhs) <= eps || (lhs.isNaN && rhs.isNaN)
        precondition(ok, "\(lhs) vs \(rhs)")
    }
}

func mpsgPlaceholder(_ graph: MPSGraph, _ dims: Int..., name: String) -> MPSGraphTensor {
    graph.placeholder(shape: dims.map { $0 as NSNumber }, dataType: .float32, name: name)
}

func mpsgRun(_ graph: MPSGraph, feeds: [MPSGraphTensor: MPSGraphTensorData], _ target: MPSGraphTensor) -> [Float] {
    let results = graph.run(feeds: feeds, targetTensors: [target], targetOperations: nil)
    guard let data = results[target] else {
        preconditionFailure("missing result for \(target.operation.name)")
    }
    return mpsgFloats(data)
}
