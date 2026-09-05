import CoreML
import Foundation

func testTensorShapeRankAndFlatten() {
    let tensor = MLTensor(repeating: 1.0, shape: [2, 2])
    precondition(tensor.shape == [2, 2])
    precondition(tensor.scalarCount == 4)
    precondition(tensor.rank == 2)
    precondition(!tensor.isScalar)
    _ = tensor.scalarType
    _ = tensor.description
    _ = tensor.customMirror
    let flat = tensor.flattened()
    precondition(flat.shape == [4])
    let reshaped = tensor.reshaped(to: [4, 1])
    precondition(reshaped.shape == [4, 1])
}

func testTensorConcatenatingAndInitializers() {
    let tensor = MLTensor(concatenating: [MLTensor(repeating: 1, shape: [2]), MLTensor(repeating: 2, shape: [2])])
    precondition(tensor.shape == [4])
    let zeros = MLTensor(zeros: [3], scalarType: Float.self)
    precondition(zeros.shape == [3])
    let fromFloats = MLTensor([Float(1), Float(2)])
    precondition(fromFloats.shape == [2])
    let fromInts = MLTensor([Int32(3), Int32(4)])
    precondition(fromInts.shape == [2])
    let shaped = MLTensor(shape: [2], scalars: [Float(1), Float(2)])
    precondition(shaped.scalarCount == 2)
    let fromData = MLTensor(shape: [1], data: Data(count: 4), scalarType: Float.self)
    precondition(fromData.rank == 1)
    coremlWaitAsync {
        let converted = await tensor.shapedArray(of: Float.self)
        precondition(converted.scalarCount == 4)
    }
}
