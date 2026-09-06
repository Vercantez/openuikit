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

func testTensorArithmeticAndMatmul() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    let b = MLTensor(shape: [2, 2], scalars: [Float(5), 6, 7, 8])
    a.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 2, 3, 4])
    }
    let sum = a + b
    sum.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [6, 8, 10, 12])
    }
    let scaled = a * Float(2)
    scaled.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 4, 6, 8])
    }
    let shifted = Float(1) + a
    shifted.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 3, 4, 5])
    }
    let sub = b - a
    sub.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [4, 4, 4, 4])
    }
    let negated = -a
    negated.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [-1, -2, -3, -4])
    }
    let divided = b / a
    divided.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 5)
    }
    let remainder = MLTensor([Float(5), 6]) % MLTensor([Float(2), 4])
    remainder.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    var acc = a
    acc += b
    acc.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [6, 8, 10, 12])
    }
    acc -= b
    acc *= b
    acc /= b
    acc %= b
    let product = a.matmul(b)
    // [1 2; 3 4] x [5 6; 7 8] = [19 22; 43 50]
    product.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [19, 22, 43, 50])
    }
    let pointMax = pointwiseMax(a, b)
    pointMax.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [5, 6, 7, 8])
    }
    let pointMin = pointwiseMin(a, Float(2))
    pointMin.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 2, 2, 2])
    }
    let scalarMax = pointwiseMax(Float(3), a)
    scalarMax.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 3, 3, 4])
    }
    _ = pointwiseMin(a, b)
    _ = pointwiseMin(Float(1), a)
}

func testTensorReductionsAndElementwise() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    a.sum().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 10)
    }
    a.product().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 24)
    }
    a.mean().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 2.5)
    }
    a.max().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
    a.min().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    a.sum(alongAxes: 1).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 7])
    }
    a.mean(alongAxes: [0]).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 3])
    }
    a.max(alongAxes: 0).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 4])
    }
    a.min(alongAxes: 1).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 3])
    }
    a.argmax().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 3)
    }
    a.argmin().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 0)
    }
    let softmax = MLTensor([Float(1), 1]).softmax()
    softmax.withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - 0.5) < 0.0001)
    }
    a.abs().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    a.squared().withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 4, 9, 16])
    }
    a.reciprocal().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    MLTensor([Float(4)]).squareRoot().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 2)
    }
    MLTensor([Float(4)]).rsqrt().withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - 0.5) < 0.0001)
    }
    MLTensor([Float(-2), 0, 3]).sign().withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [-1, 0, 1])
    }
    MLTensor([Float(1)]).exp().withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - Foundation.exp(Float(1))) < 0.0001)
    }
    _ = a.exp2()
    _ = a.log()
    _ = a.sin()
    _ = a.cos()
    _ = a.tan()
    _ = a.asin()
    _ = a.acos()
    _ = a.atan()
    _ = a.sinh()
    _ = a.cosh()
    _ = a.tanh()
    _ = a.asinh()
    _ = a.acosh()
    _ = a.atanh()
    _ = a.ceil()
    _ = a.floor()
    _ = a.round()
    _ = a.pow(2 as Float)
    _ = a.pow(MLTensor(repeating: 2, shape: [2, 2]))
    _ = a.clamped(to: 0...3)
    _ = a.clamped(to: 2...)
    _ = a.clamped(to: ...2)
    _ = a.cast(to: Int32.self)
    _ = a.cast(like: MLTensor([Int32(1)]))
    _ = a.cumulativeSum(alongAxis: 1)
    _ = a.cumulativeProduct(alongAxis: 0)
    _ = a.all()
    _ = a.any()
    _ = a.all(alongAxes: 0)
    _ = a.any(alongAxes: 1)
    _ = a.product(alongAxes: 0)
    _ = a.product(alongAxes: [0])
    _ = a.all(alongAxes: [0])
    _ = a.any(alongAxes: [1])
    _ = a.sum(alongAxes: [1])
    _ = a.max(alongAxes: [0])
    _ = a.min(alongAxes: [1])
    _ = a.argmax(alongAxis: 1)
    _ = a.argmin(alongAxis: 0)
    _ = a.argsort()
    let top = a.flattened().topK(2)
    top.values.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
}

func testTensorShapeOpsAndEnums() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    let transposed = a.transposed()
    transposed.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 3, 2, 4])
    }
    _ = a.transposed(permutation: 1, 0)
    _ = a.transposed(permutation: [1, 0])
    let expanded = a.expandingShape(at: 0)
    precondition(expanded.shape == [1, 2, 2])
    _ = a.expandingShape(at: [0])
    precondition(expanded.squeezingShape().shape == [2, 2])
    _ = expanded.squeezingShape(at: 0)
    _ = expanded.squeezingShape(at: [0])
    let stacked = MLTensor(stacking: [a, a], alongAxis: 0)
    precondition(stacked.shape == [2, 2, 2])
    let concat = a.concatenated(with: a, alongAxis: 0)
    precondition(concat.shape == [4, 2])
    precondition(a.unstacked().count == 2)
    precondition(a.split(count: 2, alongAxis: 0).count == 2)
    precondition(a.split(sizes: [1, 1], alongAxis: 0).count == 2)
    let tiled = a.tiled(multiples: [2, 1])
    precondition(tiled.shape == [4, 2])
    _ = a.reversed(alongAxes: 0)
    _ = a.reversed(alongAxes: [1])
    let padded = a.padded(forSizes: [(1, 1), (0, 0)], with: 0)
    precondition(padded.shape == [4, 2])
    _ = a.padded(forSizes: [(0, 0), (1, 1)], mode: .constant(0))
    _ = a.padded(forSizes: [(1, 0), (0, 0)], mode: .reflection)
    _ = a.padded(forSizes: [(1, 0), (0, 0)], mode: .symmetric)
    let nearest = a.resized(to: (newHeight: 4, newWidth: 2), method: .nearestNeighbor)
    precondition(nearest.shape == [4, 2])
    _ = a.resized(to: (newHeight: 2, newWidth: 2), method: .bilinear(alignCorners: false))
    let gathered = a.gathering(atIndices: MLTensor([Int32(1)]), alongAxis: 0)
    precondition(gathered.shape[0] == 1)
    _ = a.gathering(atIndices: MLTensor([Int32(0)]))
    let mask = MLTensor(shape: [2, 2], scalars: [Float(1), 0, 1, 0])
    _ = a.replacing(with: bZero(), where: mask)
    _ = a.replacing(with: Float(9), where: mask)
    _ = a.replacing(with: MLTensor([Float(9), 9]), atIndices: MLTensor([Int32(0)]), alongAxis: 0)
    _ = a.replacing(atIndices: MLTensor([Int32(1)]), with: Float(0), alongAxis: 0)
    _ = a.bandPart(lowerBandCount: 0, upperBandCount: 0)
    let ones = MLTensor(ones: [2], scalarType: Float.self)
    ones.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 1])
    }
    _ = MLTensor(ones: [2], scalarType: Int32.self)
    _ = MLTensor(repeating: Int32(3), shape: [2], scalarType: Int32.self)
    _ = MLTensor(Float(2), scalarType: Float.self)
    _ = MLTensor([Float(1), 2], scalarType: Float.self)
    _ = MLTensor(shape: [2], scalars: [Int32(1), 2], scalarType: Int32.self)
    _ = MLTensor(MLShapedArray<Float>(scalars: [1, 2], shape: [2]))
    _ = MLTensor([a.flattened(), a.flattened()], alongAxis: 0)
    let linspace = MLTensor(linearSpaceFrom: Float(0), through: 2, count: 3)
    linspace.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 2])
    }
    _ = MLTensor(linearSpaceFrom: Float(0), through: 1, count: 2, scalarType: Float.self)
    let ranged = MLTensor(rangeFrom: Float(0), to: 3, by: 1)
    ranged.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 2])
    }
    _ = MLTensor(rangeFrom: Float(0), to: 2, by: 1, scalarType: Float.self)
    _ = MLTensor(randomNormal: [2], seed: 1, scalarType: Float.self)
    _ = MLTensor(randomUniform: [2], in: Float(0)..<1, seed: 1, scalarType: Float.self)
    _ = MLTensor(randomUniform: [2], in: Int32(0)...3, seed: 1, scalarType: Int32.self)
    let scalar: MLTensor = 1.5
    precondition(scalar.isScalar)
    let intLiteral: MLTensor = 3
    _ = intLiteral
    let boolLiteral: MLTensor = true
    _ = boolLiteral
    let arrayLiteral: MLTensor = [MLTensor([Float(1)]), MLTensor([Float(2)])]
    precondition(arrayLiteral.rank >= 1)
    let bytes = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    bytes.initialize(repeating: 3, count: 2)
    let copied = MLTensor(
        bytesNoCopy: UnsafeRawBufferPointer(start: UnsafeRawPointer(bytes), count: 8),
        shape: [2],
        scalarType: Float.self,
        deallocator: .none
    )
    copied.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 3)
    }
    bytes.deinitialize(count: 2)
    bytes.deallocate()
    let uninit = MLTensor(
        unsafeUninitializedShape: [2],
        scalarType: Float.self,
        initializingWith: { buffer in
            buffer.bindMemory(to: Float.self).initialize(repeating: 4)
        }
    )
    uninit.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
    precondition(MLTensor.PaddingMode.reflection == .reflection)
    precondition(MLTensor.PaddingMode.symmetric != .constant(0))
    _ = MLTensor.PaddingMode.constant(1).hashValue
    var hasher = Hasher()
    MLTensor.PaddingMode.reflection.hash(into: &hasher)
    _ = MLTensor.PaddingMode.reflection.description
    _ = MLTensor.PaddingMode.symmetric.description
    _ = MLTensor.PaddingMode.constant(1).description
    precondition(MLTensor.ResizeMethod.nearestNeighbor == .nearestNeighbor)
    precondition(MLTensor.ResizeMethod.bilinear(alignCorners: true) != .nearestNeighbor)
    _ = MLTensor.ResizeMethod.nearestNeighbor.hashValue
    MLTensor.ResizeMethod.nearestNeighbor.hash(into: &hasher)
    _ = MLTensor.ResizeMethod.nearestNeighbor.description
    _ = MLTensor.ResizeMethod.bilinear(alignCorners: false).description
    _ = CoreMLTensorRange.range(0..<1)
    _ = CoreMLTensorRange.closedRange(0...0)
    _ = CoreMLTensorRange.partialRangeFrom(0...)
    _ = CoreMLTensorRange.partialRangeUpTo(..<1)
    _ = CoreMLTensorRange.partialRangeUpTo(...0)
    _ = CoreMLTensorRange.index(0)
    _ = CoreMLTensorRange.fillAll
    _ = CoreMLTensorRange.newAxis
    _ = CoreMLTensorRange.squeezeAxis
    let sliced = a[CoreMLTensorRange.index(0)]
    precondition(sliced.rank == 1)
    _ = a[...]
    _ = a.cpuShapedArray(of: Float.self)
}

private func bZero() -> MLTensor {
    MLTensor(zeros: [2, 2], scalarType: Float.self)
}

func testTensorComparisonsAndBitwise() {
    let a = MLTensor([Float(1), 2, 3])
    let b = MLTensor([Float(1), 0, 4])
    (a .== b).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 0, 0])
    }
    (a .!= Float(2)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 0, 1])
    }
    (a .< b).withUnsafeBufferPointer { buffer in
        precondition(buffer[2] == 1)
    }
    (a .> Float(1)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 1])
    }
    (a .<= b).withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    (a .>= Float(3)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 0, 1])
    }
    _ = a .== Float(1)
    _ = a .!= b
    _ = a .< Float(2)
    _ = a .> b
    _ = a .<= Float(2)
    _ = a .>= b
    let bits = MLTensor([Int32(1), 3])
    (bits .& bits).withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    _ = bits .| bits
    _ = bits .^ bits
    _ = (.!)(a)
}
