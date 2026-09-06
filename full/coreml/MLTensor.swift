import Foundation

// MARK: - Range expressions

public protocol MLTensorRangeExpression: Sendable {}

public struct CoreMLTensorRange: MLTensorRangeExpression, Sendable {
    enum Kind: Sendable {
        case index(Int)
        case range(Range<Int>, stride: Int)
        case closed(ClosedRange<Int>, stride: Int)
        case from(PartialRangeFrom<Int>, stride: Int)
        case upTo(PartialRangeUpTo<Int>, stride: Int)
        case through(PartialRangeThrough<Int>, stride: Int)
        case fillAll
        case newAxis
        case squeeze
    }

    let kind: Kind
}

extension MLTensorRangeExpression where Self == CoreMLTensorRange {
    public static func closedRange(_ range: ClosedRange<Int>, stride: Int = 1) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .closed(range, stride: stride))
    }

    public static func partialRangeFrom(_ range: PartialRangeFrom<Int>, stride: Int = 1) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .from(range, stride: stride))
    }

    public static func partialRangeUpTo(_ range: PartialRangeThrough<Int>, stride: Int = 1) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .through(range, stride: stride))
    }

    public static func partialRangeUpTo(_ range: PartialRangeUpTo<Int>, stride: Int = 1) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .upTo(range, stride: stride))
    }

    public static var squeezeAxis: any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .squeeze)
    }

    public static func index(_ index: Int) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .index(index))
    }

    public static func range(_ range: Range<Int>, stride: Int = 1) -> any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .range(range, stride: stride))
    }

    public static var fillAll: any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .fillAll)
    }

    public static var newAxis: any MLTensorRangeExpression {
        CoreMLTensorRange(kind: .newAxis)
    }
}

// MARK: - Tensor

/// Linux CPU tensor. Arithmetic is IEEE-754 on a host buffer; it does not
/// claim Apple GPU / ANE scheduling or `withMLTensorComputePolicy` hops.
public struct MLTensor: Sendable, CustomStringConvertible, ExpressibleByArrayLiteral, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    public typealias FloatLiteralType = Float
    public typealias IntegerLiteralType = Int32
    public typealias BooleanLiteralType = Bool
    public typealias ArrayLiteralElement = MLTensor

    public let shape: [Int]
    public var scalarType: any MLTensorScalar.Type
    let values: [Float]

    public var rank: Int { shape.count }
    public var scalarCount: Int { coreMLElementCount(shape: shape) }
    public var isScalar: Bool { shape.isEmpty }
    public var description: String { "MLTensor(shape: \(shape), scalarCount: \(scalarCount))" }
    public var customMirror: Mirror {
        Mirror(self, children: ["shape": shape, "scalarCount": scalarCount])
    }

    init(shape: [Int], values: [Float], scalarType: any MLTensorScalar.Type) {
        let count = coreMLElementCount(shape: shape)
        var storage = values
        if storage.count < count {
            storage.append(contentsOf: repeatElement(0, count: count - storage.count))
        } else if storage.count > count {
            storage = Array(storage.prefix(count))
        }
        self.shape = shape
        self.values = storage
        self.scalarType = scalarType
    }

    public init(shape: [Int], data: Data, scalarType: any MLTensorScalar.Type) {
        let floats = MLTensor.decodeFloats(from: data, scalarType: scalarType)
        self.init(shape: shape, values: floats, scalarType: scalarType)
    }

    public init(
        bytesNoCopy bytes: UnsafeRawBufferPointer,
        shape: [Int],
        scalarType: any MLTensorScalar.Type,
        deallocator: Data.Deallocator
    ) {
        let data = Data(bytes)
        switch deallocator {
        case .none, .free, .unmap, .custom(_):
            break
        @unknown default:
            break
        }
        self.init(shape: shape, data: data, scalarType: scalarType)
    }

    public init(
        unsafeUninitializedShape shape: [Int],
        scalarType: any MLTensorScalar.Type,
        initializingWith initializer: (UnsafeMutableRawBufferPointer) throws -> Void
    ) rethrows {
        var data = Data(count: coreMLElementCount(shape: shape) * MemoryLayout<Float>.stride)
        try data.withUnsafeMutableBytes { buffer in
            try initializer(buffer)
        }
        self.init(shape: shape, data: data, scalarType: scalarType)
    }

    public init(repeating repeatedValue: Float, shape: [Int]) {
        self.init(shape: shape, values: Array(repeating: repeatedValue, count: coreMLElementCount(shape: shape)), scalarType: Float.self)
    }

    public init<Scalar: MLTensorScalar>(repeating repeatedValue: Scalar, shape: [Int], scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: shape, values: Array(repeating: MLTensor.float(from: repeatedValue), count: coreMLElementCount(shape: shape)), scalarType: scalarType)
    }

    public init(_ scalars: some Collection<Float>) {
        self.init(shape: [scalars.count], values: Array(scalars), scalarType: Float.self)
    }

    public init(_ scalars: some Collection<Int32>) {
        self.init(shape: [scalars.count], values: scalars.map { Float($0) }, scalarType: Int32.self)
    }

    public init(shape: [Int], scalars: some Collection<Float>) {
        self.init(shape: shape, values: Array(scalars), scalarType: Float.self)
    }

    public init<Scalar: MLTensorScalar>(shape: [Int], scalars: some Collection, scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: shape, values: scalars.map { MLTensor.float(from: $0) }, scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar>(_ scalars: some Collection, scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: [scalars.count], values: scalars.map { MLTensor.float(from: $0) }, scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar>(_ value: Scalar, scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: [], values: [MLTensor.float(from: value)], scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar>(zeros shape: [Int], scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: shape, values: Array(repeating: 0, count: coreMLElementCount(shape: shape)), scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar>(ones shape: [Int], scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: shape, values: Array(repeating: 1, count: coreMLElementCount(shape: shape)), scalarType: scalarType)
    }

    public init(_ elements: some Collection<MLTensor>, alongAxis axis: Int = 0) {
        self.init(concatenating: elements, alongAxis: axis)
    }

    public init<ShapedArray>(_ shapedArray: ShapedArray) where ShapedArray: MLShapedArrayProtocol, ShapedArray.Scalar: MLTensorScalar {
        var floats: [Float] = []
        shapedArray.withUnsafeShapedBufferPointer { buffer, _, _ in
            floats = buffer.map { MLTensor.float(from: $0) }
        }
        self.init(shape: shapedArray.shape, values: floats, scalarType: ShapedArray.Scalar.self)
    }

    public init(arrayLiteral elements: MLTensor...) {
        self.init(stacking: elements, alongAxis: 0)
    }

    public init(floatLiteral value: Float) {
        self.init(shape: [], values: [value], scalarType: Float.self)
    }

    public init(integerLiteral value: Int32) {
        self.init(shape: [], values: [Float(value)], scalarType: Int32.self)
    }

    public init(booleanLiteral value: Bool) {
        self.init(shape: [], values: [value ? 1 : 0], scalarType: Bool.self)
    }

    public init(linearSpaceFrom start: Float, through end: Float, count: Int) {
        self.init(linearSpaceFrom: start, through: end, count: count, scalarType: Float.self)
    }

    public init<Scalar: MLTensorScalar & BinaryFloatingPoint>(
        linearSpaceFrom start: Scalar,
        through end: Scalar,
        count: Int,
        scalarType: Scalar.Type = Scalar.self
    ) {
        precondition(count > 0)
        if count == 1 {
            self.init(shape: [1], values: [Float(start)], scalarType: scalarType)
            return
        }
        let startF = Float(start)
        let endF = Float(end)
        let step = (endF - startF) / Float(count - 1)
        let values = (0..<count).map { startF + Float($0) * step }
        self.init(shape: [count], values: values, scalarType: scalarType)
    }

    public init(rangeFrom start: Float, to end: Float, by stride: Float.Stride) {
        self.init(rangeFrom: start, to: end, by: stride, scalarType: Float.self)
    }

    public init<Scalar: MLTensorScalar & Strideable>(
        rangeFrom start: Scalar,
        to end: Scalar,
        by stride: Scalar.Stride,
        scalarType: Scalar.Type = Scalar.self
    ) {
        var values: [Float] = []
        var current = start
        while current < end {
            values.append(MLTensor.float(from: current))
            current = current.advanced(by: stride)
        }
        self.init(shape: [values.count], values: values, scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar & BinaryFloatingPoint>(
        randomNormal shape: [Int],
        mean: Scalar = Scalar(0.0),
        standardDeviation: Scalar = Scalar(1.0),
        seed: UInt64? = nil,
        scalarType: Scalar.Type = Scalar.self
    ) where Scalar.RawSignificand: FixedWidthInteger {
        var rng = CoreMLPCG(seed: seed ?? 1)
        let count = coreMLElementCount(shape: shape)
        let meanF = Float(mean)
        let stdF = Float(standardDeviation)
        var values: [Float] = []
        values.reserveCapacity(count)
        for _ in 0..<count {
            let u1 = Swift.max(rng.nextUnit(), Float(1e-6))
            let u2 = rng.nextUnit()
            let z = Foundation.sqrt(-2 * Foundation.log(u1)) * Foundation.cos(2 * Float.pi * u2)
            values.append(meanF + stdF * z)
        }
        self.init(shape: shape, values: values, scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar & BinaryInteger>(
        randomUniform shape: [Int],
        in bounds: ClosedRange<Scalar> = 0...1,
        seed: UInt64? = nil,
        scalarType: Scalar.Type = Scalar.self
    ) {
        var rng = CoreMLPCG(seed: seed ?? 1)
        let count = coreMLElementCount(shape: shape)
        let lower = Float(bounds.lowerBound)
        let upper = Float(bounds.upperBound)
        let span = upper - lower
        let values = (0..<count).map { _ in lower + rng.nextUnit() * span }
        self.init(shape: shape, values: values, scalarType: scalarType)
    }

    public init<Scalar: MLTensorScalar & BinaryFloatingPoint>(
        randomUniform shape: [Int],
        in bounds: Range<Scalar> = 0..<1,
        seed: UInt64? = nil,
        scalarType: Scalar.Type = Scalar.self
    ) {
        var rng = CoreMLPCG(seed: seed ?? 1)
        let count = coreMLElementCount(shape: shape)
        let lower = Float(bounds.lowerBound)
        let upper = Float(bounds.upperBound)
        let span = Swift.max(upper - lower, 0)
        let values = (0..<count).map { _ in lower + rng.nextUnit() * span }
        self.init(shape: shape, values: values, scalarType: scalarType)
    }

    public init(concatenating tensors: some Collection<MLTensor>, alongAxis axis: Int = 0) {
        let items = Array(tensors)
        precondition(!items.isEmpty)
        var newShape = items[0].shape
        precondition(!newShape.isEmpty)
        let normalized = axis < 0 ? axis + newShape.count : axis
        newShape[normalized] = items.reduce(0) { $0 + $1.shape[normalized] }
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: newShape))
        var axisOffset = 0
        for tensor in items {
            precondition(tensor.shape.count == items[0].shape.count)
            for linear in 0..<tensor.scalarCount {
                var coords = coreMLUnravel(linear: linear, shape: tensor.shape)
                coords[normalized] += axisOffset
                output[coreMLRavel(coords, shape: newShape)] = tensor.values[linear]
            }
            axisOffset += tensor.shape[normalized]
        }
        self.init(shape: newShape, values: output, scalarType: items[0].scalarType)
    }

    public init(stacking tensors: some Collection<MLTensor>, alongAxis axis: Int = 0) {
        let items = Array(tensors)
        precondition(!items.isEmpty)
        let expanded = items.map { $0.expandingShape(at: axis < 0 ? axis + $0.rank + 1 : axis) }
        self.init(concatenating: expanded, alongAxis: axis)
    }

    public func reshaped(to newShape: [Int]) -> MLTensor {
        precondition(coreMLElementCount(shape: newShape) == scalarCount)
        return MLTensor(shape: newShape, values: values, scalarType: scalarType)
    }

    public func flattened() -> MLTensor {
        reshaped(to: [scalarCount])
    }

    public func transposed() -> MLTensor {
        guard rank >= 2 else { return self }
        return transposed(permutation: Array((0..<rank).reversed()))
    }

    public func transposed(permutation axes: Int...) -> MLTensor {
        transposed(permutation: axes)
    }

    public func transposed(permutation axes: [Int]) -> MLTensor {
        precondition(axes.count == rank)
        var newShape = Array(repeating: 0, count: rank)
        for (destination, axis) in axes.enumerated() {
            newShape[destination] = shape[axis]
        }
        var output = Array(repeating: Float(0), count: scalarCount)
        for linear in 0..<scalarCount {
            let source = coreMLUnravel(linear: linear, shape: shape)
            var dest = Array(repeating: 0, count: rank)
            for (destination, axis) in axes.enumerated() {
                dest[destination] = source[axis]
            }
            output[coreMLRavel(dest, shape: newShape)] = values[linear]
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    public func expandingShape(at axes: Int...) -> MLTensor {
        expandingShape(at: axes)
    }

    public func expandingShape(at axes: [Int]) -> MLTensor {
        var newShape = shape
        let sorted = axes.sorted()
        for axis in sorted {
            let normalized = axis < 0 ? axis + newShape.count + 1 : axis
            newShape.insert(1, at: Swift.max(0, Swift.min(normalized, newShape.count)))
        }
        return reshaped(to: newShape)
    }

    public func squeezingShape() -> MLTensor {
        squeezingShape(at: shape.enumerated().compactMap { $0.element == 1 ? $0.offset : nil })
    }

    public func squeezingShape(at axes: Int...) -> MLTensor {
        squeezingShape(at: axes)
    }

    public func squeezingShape(at axes: [Int]) -> MLTensor {
        var remove = Set<Int>()
        for axis in axes {
            let normalized = axis < 0 ? axis + rank : axis
            if shape[normalized] == 1 {
                remove.insert(normalized)
            }
        }
        let newShape = shape.enumerated().compactMap { remove.contains($0.offset) ? nil : $0.element }
        return reshaped(to: newShape.isEmpty ? [] : newShape)
    }

    public func concatenated(with other: MLTensor, alongAxis axis: Int = 0) -> MLTensor {
        MLTensor(concatenating: [self, other], alongAxis: axis)
    }

    public func unstacked(alongAxis axis: Int = 0) -> [MLTensor] {
        let normalized = axis < 0 ? axis + rank : axis
        let count = shape[normalized]
        return (0..<count).map { index in
            sliced(axis: normalized, index: index)
        }
    }

    public func split(count: Int, alongAxis axis: Int = 0) -> [MLTensor] {
        let normalized = axis < 0 ? axis + rank : axis
        let size = shape[normalized] / count
        return split(sizes: Array(repeating: size, count: count), alongAxis: normalized)
    }

    public func split(sizes: [Int], alongAxis axis: Int = 0) -> [MLTensor] {
        let normalized = axis < 0 ? axis + rank : axis
        var origin = 0
        var result: [MLTensor] = []
        for size in sizes {
            result.append(sliced(axis: normalized, start: origin, end: origin + size))
            origin += size
        }
        return result
    }

    public func tiled(multiples: [Int]) -> MLTensor {
        precondition(multiples.count == rank)
        var newShape = shape
        for index in 0..<rank {
            newShape[index] *= multiples[index]
        }
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: newShape))
        for linear in 0..<output.count {
            let dest = coreMLUnravel(linear: linear, shape: newShape)
            var source = dest
            for axis in 0..<rank {
                source[axis] = dest[axis] % shape[axis]
            }
            output[linear] = values[coreMLRavel(source, shape: shape)]
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    public func reversed(alongAxes axes: Int...) -> MLTensor {
        reversed(alongAxes: axes)
    }

    public func reversed(alongAxes axes: [Int]) -> MLTensor {
        var output = values
        for linear in 0..<scalarCount {
            var indices = coreMLUnravel(linear: linear, shape: shape)
            for axis in axes {
                let normalized = axis < 0 ? axis + rank : axis
                indices[normalized] = shape[normalized] - 1 - indices[normalized]
            }
            output[coreMLRavel(indices, shape: shape)] = values[linear]
        }
        return MLTensor(shape: shape, values: output, scalarType: scalarType)
    }

    public func padded(forSizes sizes: [(before: Int, after: Int)], with value: Float) -> MLTensor {
        padded(forSizes: sizes, mode: .constant(value))
    }

    public func padded(forSizes sizes: [(before: Int, after: Int)], mode: MLTensor.PaddingMode) -> MLTensor {
        precondition(sizes.count == rank)
        var newShape = shape
        for (axis, pad) in sizes.enumerated() {
            newShape[axis] += pad.before + pad.after
        }
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: newShape))
        for linear in 0..<output.count {
            let dest = coreMLUnravel(linear: linear, shape: newShape)
            var source: [Int] = []
            var outside = false
            for axis in 0..<rank {
                let shifted = dest[axis] - sizes[axis].before
                if shifted < 0 || shifted >= shape[axis] {
                    switch mode {
                    case .constant(let fill):
                        output[linear] = fill
                        outside = true
                    case .reflection:
                        source.append(coreMLPadIndex(shifted, length: shape[axis]))
                    case .symmetric:
                        source.append(coreMLPadIndex(shifted, length: shape[axis], symmetric: true))
                    }
                } else {
                    source.append(shifted)
                }
            }
            if !outside {
                output[linear] = values[coreMLRavel(source, shape: shape)]
            }
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    public func resized(
        to size: (newHeight: Int, newWidth: Int),
        method: MLTensor.ResizeMethod = .nearestNeighbor
    ) -> MLTensor {
        precondition(rank >= 2)
        let heightAxis = rank - 2
        let widthAxis = rank - 1
        var newShape = shape
        newShape[heightAxis] = size.newHeight
        newShape[widthAxis] = size.newWidth
        let oldH = Float(shape[heightAxis])
        let oldW = Float(shape[widthAxis])
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: newShape))
        for linear in 0..<output.count {
            var indices = coreMLUnravel(linear: linear, shape: newShape)
            switch method {
            case .nearestNeighbor:
                let y = Swift.min(Int(Float(indices[heightAxis]) * oldH / Float(size.newHeight)), shape[heightAxis] - 1)
                let x = Swift.min(Int(Float(indices[widthAxis]) * oldW / Float(size.newWidth)), shape[widthAxis] - 1)
                indices[heightAxis] = y
                indices[widthAxis] = x
                output[linear] = values[coreMLRavel(indices, shape: shape)]
            case .bilinear(let alignCorners):
                _ = alignCorners
                let y = Float(indices[heightAxis]) * (oldH - 1) / Swift.max(Float(size.newHeight - 1), 1)
                let x = Float(indices[widthAxis]) * (oldW - 1) / Swift.max(Float(size.newWidth - 1), 1)
                output[linear] = sampleBilinear(y: y, x: x, heightAxis: heightAxis, widthAxis: widthAxis, other: indices)
            }
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    public func gathering(atIndices indices: MLTensor) -> MLTensor {
        gathering(atIndices: indices, alongAxis: 0)
    }

    public func gathering(atIndices indices: MLTensor, alongAxis axis: Int) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        var newShape = shape
        newShape[normalized] = indices.scalarCount
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: newShape))
        for linear in 0..<output.count {
            var dest = coreMLUnravel(linear: linear, shape: newShape)
            let gatherIndex = Int(indices.values[dest[normalized]])
            dest[normalized] = Swift.max(0, Swift.min(gatherIndex, shape[normalized] - 1))
            output[linear] = values[coreMLRavel(dest, shape: shape)]
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    public func replacing(with replacement: MLTensor, where mask: MLTensor) -> MLTensor {
        let out = zip3(values, replacement.broadcast(to: shape).values, mask.broadcast(to: shape).values).map { current, next, flag in
            flag != 0 ? next : current
        }
        return MLTensor(shape: shape, values: out, scalarType: scalarType)
    }

    public func replacing(with replacement: some MLTensorScalar, where mask: MLTensor) -> MLTensor {
        replacing(with: MLTensor(repeating: MLTensor.float(from: replacement), shape: shape), where: mask)
    }

    public func replacing(with replacement: MLTensor, atIndices indices: MLTensor, alongAxis axis: Int) -> MLTensor {
        var copy = values
        let normalized = axis < 0 ? axis + rank : axis
        for (offset, raw) in indices.values.enumerated() {
            let index = Int(raw)
            guard index >= 0, index < shape[normalized] else { continue }
            for linear in 0..<scalarCount {
                let coords = coreMLUnravel(linear: linear, shape: shape)
                if coords[normalized] == index {
                    let repl = replacement.values[Swift.min(offset, replacement.values.count - 1)]
                    copy[linear] = repl
                }
            }
        }
        return MLTensor(shape: shape, values: copy, scalarType: scalarType)
    }

    public func replacing(
        atIndices indices: MLTensor,
        with replacement: some MLTensorScalar,
        alongAxis axis: Int
    ) -> MLTensor {
        replacing(with: MLTensor(repeating: MLTensor.float(from: replacement), shape: shape), atIndices: indices, alongAxis: axis)
    }

    public func bandPart(lowerBandCount: Int, upperBandCount: Int) -> MLTensor {
        precondition(rank >= 2)
        var output = values
        let rows = shape[rank - 2]
        let cols = shape[rank - 1]
        for linear in 0..<scalarCount {
            let coords = coreMLUnravel(linear: linear, shape: shape)
            let i = coords[rank - 2]
            let j = coords[rank - 1]
            let diff = j - i
            let keepLower = lowerBandCount < 0 || diff >= -lowerBandCount
            let keepUpper = upperBandCount < 0 || diff <= upperBandCount
            if !(keepLower && keepUpper) {
                output[linear] = 0
            }
            _ = (rows, cols)
        }
        return MLTensor(shape: shape, values: output, scalarType: scalarType)
    }

    public func matmul(_ other: MLTensor) -> MLTensor {
        let lhs = rank == 1 ? expandingShape(at: 0) : self
        let rhs = other.rank == 1 ? other.expandingShape(at: 1) : other
        precondition(lhs.rank >= 2 && rhs.rank >= 2)
        let m = lhs.shape[lhs.rank - 2]
        let k = lhs.shape[lhs.rank - 1]
        let n = rhs.shape[rhs.rank - 1]
        precondition(k == rhs.shape[rhs.rank - 2])
        var outShape = lhs.shape
        outShape[lhs.rank - 2] = m
        outShape[lhs.rank - 1] = n
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: outShape))
        for i in 0..<m {
            for j in 0..<n {
                var sum: Float = 0
                for t in 0..<k {
                    let a = lhs.values[i * k + t]
                    let b = rhs.values[t * n + j]
                    sum += a * b
                }
                output[i * n + j] = sum
            }
        }
        var result = MLTensor(shape: outShape, values: output, scalarType: scalarType)
        if rank == 1 { result = result.squeezingShape(at: 0) }
        if other.rank == 1 { result = result.squeezingShape(at: result.rank - 1) }
        return result
    }

    public func cumulativeSum(alongAxis axis: Int = 0) -> MLTensor {
        scan(alongAxis: axis, initial: 0, combine: +)
    }

    public func cumulativeProduct(alongAxis axis: Int = 0) -> MLTensor {
        scan(alongAxis: axis, initial: 1, combine: *)
    }

    public func sum(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: 0, combine: +)
    }

    public func sum(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        sum(alongAxes: axes, keepRank: keepRank)
    }

    public func sum(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: 0, combine: +)
    }

    public func product(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: 1, combine: *)
    }

    public func product(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        product(alongAxes: axes, keepRank: keepRank)
    }

    public func product(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: 1, combine: *)
    }

    public func mean(keepRank: Bool = false) -> MLTensor {
        let total = sum(keepRank: keepRank)
        let denom = Float(Swift.max(scalarCount, 1))
        return MLTensor(shape: total.shape, values: total.values.map { $0 / denom }, scalarType: scalarType)
    }

    public func mean(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        mean(alongAxes: axes, keepRank: keepRank)
    }

    public func mean(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        let reduced = sum(alongAxes: axes, keepRank: keepRank)
        let denom = Float(axes.reduce(1) { partial, axis in
            let normalized = axis < 0 ? axis + rank : axis
            return partial * shape[normalized]
        })
        return MLTensor(shape: reduced.shape, values: reduced.values.map { $0 / Swift.max(denom, 1) }, scalarType: scalarType)
    }

    public func max(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: -Float.greatestFiniteMagnitude, combine: Swift.max)
    }

    public func max(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        max(alongAxes: axes, keepRank: keepRank)
    }

    public func max(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: -Float.greatestFiniteMagnitude, combine: Swift.max)
    }

    public func min(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: Float.greatestFiniteMagnitude, combine: Swift.min)
    }

    public func min(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        min(alongAxes: axes, keepRank: keepRank)
    }

    public func min(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: Float.greatestFiniteMagnitude, combine: Swift.min)
    }

    public func argmax() -> MLTensor {
        let index = values.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return MLTensor(shape: [], values: [Float(index)], scalarType: Int32.self)
    }

    public func argmax(alongAxis axis: Int, keepRank: Bool = false) -> MLTensor {
        argReduce(alongAxis: axis, keepRank: keepRank, choose: >)
    }

    public func argmin() -> MLTensor {
        let index = values.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        return MLTensor(shape: [], values: [Float(index)], scalarType: Int32.self)
    }

    public func argmin(alongAxis axis: Int, keepRank: Bool = false) -> MLTensor {
        argReduce(alongAxis: axis, keepRank: keepRank, choose: <)
    }

    public func argsort(alongAxis axis: Int = -1, descendingOrder: Bool = false) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        let length = shape[normalized]
        var newValues = Array(repeating: Float(0), count: scalarCount)
        let groups = scalarCount / Swift.max(length, 1)
        for group in 0..<groups {
            var pairs: [(Int, Float)] = []
            pairs.reserveCapacity(length)
            for index in 0..<length {
                let value = values[indexAlong(axis: normalized, group: group, index: index)]
                pairs.append((index, value))
            }
            pairs.sort { descendingOrder ? $0.1 > $1.1 : $0.1 < $1.1 }
            for (slot, pair) in pairs.enumerated() {
                newValues[indexAlong(axis: normalized, group: group, index: slot)] = Float(pair.0)
            }
        }
        return MLTensor(shape: shape, values: newValues, scalarType: Int32.self)
    }

    public func topK(_ k: Int) -> (values: MLTensor, indices: MLTensor) {
        let pairs = values.enumerated().sorted { $0.element > $1.element }.prefix(k)
        return (
            MLTensor(shape: [k], values: pairs.map(\.element), scalarType: scalarType),
            MLTensor(shape: [k], values: pairs.map { Float($0.offset) }, scalarType: Int32.self)
        )
    }

    public func all(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: 1) { $0 != 0 && $1 != 0 ? 1 : 0 }
    }

    public func all(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        all(alongAxes: axes, keepRank: keepRank)
    }

    public func all(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: 1) { $0 != 0 && $1 != 0 ? 1 : 0 }
    }

    public func any(keepRank: Bool = false) -> MLTensor {
        reduceAll(keepRank: keepRank, initial: 0) { $0 != 0 || $1 != 0 ? 1 : 0 }
    }

    public func any(alongAxes axes: Int..., keepRank: Bool = false) -> MLTensor {
        any(alongAxes: axes, keepRank: keepRank)
    }

    public func any(alongAxes axes: [Int], keepRank: Bool = false) -> MLTensor {
        reduce(alongAxes: axes, keepRank: keepRank, initial: 0) { $0 != 0 || $1 != 0 ? 1 : 0 }
    }

    public func abs() -> MLTensor { mapValues { Swift.abs($0) } }
    public func sign() -> MLTensor { mapValues { $0 > 0 ? 1 : ($0 < 0 ? -1 : 0) } }
    public func squareRoot() -> MLTensor { mapValues { Foundation.sqrt($0) } }
    public func rsqrt() -> MLTensor { mapValues { 1 / Foundation.sqrt($0) } }
    public func reciprocal() -> MLTensor { mapValues { 1 / $0 } }
    public func squared() -> MLTensor { mapValues { $0 * $0 } }
    public func exp() -> MLTensor { mapValues { Foundation.exp($0) } }
    public func exp2() -> MLTensor { mapValues { Foundation.exp2($0) } }
    public func log() -> MLTensor { mapValues { Foundation.log($0) } }
    public func sin() -> MLTensor { mapValues { Foundation.sin($0) } }
    public func cos() -> MLTensor { mapValues { Foundation.cos($0) } }
    public func tan() -> MLTensor { mapValues { Foundation.tan($0) } }
    public func asin() -> MLTensor { mapValues { Foundation.asin($0) } }
    public func acos() -> MLTensor { mapValues { Foundation.acos($0) } }
    public func atan() -> MLTensor { mapValues { Foundation.atan($0) } }
    public func sinh() -> MLTensor { mapValues { Foundation.sinh($0) } }
    public func cosh() -> MLTensor { mapValues { Foundation.cosh($0) } }
    public func tanh() -> MLTensor { mapValues { Foundation.tanh($0) } }
    public func asinh() -> MLTensor { mapValues { Foundation.asinh($0) } }
    public func acosh() -> MLTensor { mapValues { Foundation.acosh($0) } }
    public func atanh() -> MLTensor { mapValues { Foundation.atanh($0) } }
    public func ceil() -> MLTensor { mapValues { Foundation.ceil($0) } }
    public func floor() -> MLTensor { mapValues { Foundation.floor($0) } }
    public func round() -> MLTensor { mapValues { Foundation.round($0) } }
    public func softmax(alongAxis axis: Int = -1) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        let length = shape[normalized]
        let groups = scalarCount / Swift.max(length, 1)
        var output = values
        for group in 0..<groups {
            var maxValue = -Float.greatestFiniteMagnitude
            for index in 0..<length {
                maxValue = Swift.max(maxValue, values[indexAlong(axis: normalized, group: group, index: index)])
            }
            var sum: Float = 0
            var exps = Array(repeating: Float(0), count: length)
            for index in 0..<length {
                let e = Foundation.exp(values[indexAlong(axis: normalized, group: group, index: index)] - maxValue)
                exps[index] = e
                sum += e
            }
            for index in 0..<length {
                output[indexAlong(axis: normalized, group: group, index: index)] = exps[index] / sum
            }
        }
        return MLTensor(shape: shape, values: output, scalarType: scalarType)
    }

    public func pow(_ exponent: MLTensor) -> MLTensor {
        binary(exponent) { Foundation.pow($0, $1) }
    }

    public func pow(_ exponent: some MLTensorScalar & Numeric) -> MLTensor {
        let value = MLTensor.float(from: exponent)
        return mapValues { Foundation.pow($0, value) }
    }

    public func clamped(to bounds: ClosedRange<Float>) -> MLTensor {
        mapValues { Swift.min(Swift.max($0, bounds.lowerBound), bounds.upperBound) }
    }

    public func clamped(to bounds: PartialRangeFrom<Float>) -> MLTensor {
        mapValues { Swift.max($0, bounds.lowerBound) }
    }

    public func clamped(to bounds: PartialRangeThrough<Float>) -> MLTensor {
        mapValues { Swift.min($0, bounds.upperBound) }
    }

    public func cast<Scalar>(to scalarType: Scalar.Type) -> MLTensor where Scalar: MLTensorScalar {
        MLTensor(shape: shape, values: values, scalarType: scalarType)
    }

    public func cast(like other: MLTensor) -> MLTensor {
        MLTensor(shape: shape, values: values, scalarType: other.scalarType)
    }

    public func shapedArray<Scalar>(
        of scalarType: Scalar.Type
    ) async -> MLShapedArray<Scalar> where Scalar: MLShapedArrayScalar, Scalar: MLTensorScalar {
        cpuShapedArray(of: scalarType)
    }

    public func cpuShapedArray<Scalar>(
        of scalarType: Scalar.Type
    ) -> MLShapedArray<Scalar> where Scalar: MLShapedArrayScalar, Scalar: MLTensorScalar {
        switch Scalar.multiArrayDataType {
        case .float32:
            return MLShapedArray(data: values.withUnsafeBufferPointer { Data(buffer: $0) }, shape: shape)
        case .double:
            let doubles = values.map { Double($0) }
            return MLShapedArray(data: doubles.withUnsafeBufferPointer { Data(buffer: $0) }, shape: shape)
        case .float16:
            let halves = values.map { Float16($0) }
            return MLShapedArray(data: halves.withUnsafeBufferPointer { Data(buffer: $0) }, shape: shape)
        case .int32:
            let ints = values.map { Int32($0) }
            return MLShapedArray(data: ints.withUnsafeBufferPointer { Data(buffer: $0) }, shape: shape)
        case .int8:
            let bytes = values.map { Int8($0) }
            return MLShapedArray(data: bytes.withUnsafeBufferPointer { Data(buffer: $0) }, shape: shape)
        }
    }

    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Float>) throws -> R) rethrows -> R {
        try values.withUnsafeBufferPointer(body)
    }

    public subscript(ranges: (any MLTensorRangeExpression)?...) -> MLTensor {
        sliced(ranges: ranges)
    }

    public subscript(
        firstRange: (UnboundedRange_) -> (),
        trailingRanges: (any MLTensorRangeExpression)?...
    ) -> MLTensor {
        _ = firstRange
        return sliced(ranges: [CoreMLTensorRange(kind: .fillAll)] + trailingRanges)
    }

    public subscript(
        firstRange: (any MLTensorRangeExpression)?,
        secondRange: (UnboundedRange_) -> (),
        trailingRanges: (any MLTensorRangeExpression)?...
    ) -> MLTensor {
        _ = secondRange
        return sliced(ranges: [firstRange, CoreMLTensorRange(kind: .fillAll)] + trailingRanges)
    }

    public subscript(
        firstRange: (any MLTensorRangeExpression)?,
        secondRange: (any MLTensorRangeExpression)?,
        thirdRange: (UnboundedRange_) -> (),
        trailingRanges: (any MLTensorRangeExpression)?...
    ) -> MLTensor {
        _ = thirdRange
        return sliced(ranges: [firstRange, secondRange, CoreMLTensorRange(kind: .fillAll)] + trailingRanges)
    }

    public subscript(
        firstRange: (any MLTensorRangeExpression)?,
        secondRange: (any MLTensorRangeExpression)?,
        thirdRange: (any MLTensorRangeExpression)?,
        fourthRange: (UnboundedRange_) -> (),
        trailingRanges: (any MLTensorRangeExpression)?...
    ) -> MLTensor {
        _ = fourthRange
        return sliced(ranges: [firstRange, secondRange, thirdRange, CoreMLTensorRange(kind: .fillAll)] + trailingRanges)
    }

    public static func + (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.binary(rhs, +) }
    public static func + (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 + MLTensor.float(from: rhs) }
    }
    public static func + (lhs: some MLTensorScalar & Numeric, rhs: MLTensor) -> MLTensor {
        rhs.mapValues { MLTensor.float(from: lhs) + $0 }
    }
    public static func - (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.binary(rhs, -) }
    public static func - (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 - MLTensor.float(from: rhs) }
    }
    public static func - (lhs: some MLTensorScalar & Numeric, rhs: MLTensor) -> MLTensor {
        rhs.mapValues { MLTensor.float(from: lhs) - $0 }
    }
    public static prefix func - (rhs: MLTensor) -> MLTensor { rhs.mapValues { -$0 } }
    public static func * (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.binary(rhs, *) }
    public static func * (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 * MLTensor.float(from: rhs) }
    }
    public static func * (lhs: some MLTensorScalar & Numeric, rhs: MLTensor) -> MLTensor {
        rhs.mapValues { MLTensor.float(from: lhs) * $0 }
    }
    public static func / (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.binary(rhs, /) }
    public static func / (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 / MLTensor.float(from: rhs) }
    }
    public static func / (lhs: some MLTensorScalar & Numeric, rhs: MLTensor) -> MLTensor {
        rhs.mapValues { MLTensor.float(from: lhs) / $0 }
    }
    public static func % (lhs: MLTensor, rhs: MLTensor) -> MLTensor {
        lhs.binary(rhs) { $0.truncatingRemainder(dividingBy: $1) }
    }
    public static func % (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        let value = MLTensor.float(from: rhs)
        return lhs.mapValues { $0.truncatingRemainder(dividingBy: value) }
    }
    public static func % (lhs: some MLTensorScalar & Numeric, rhs: MLTensor) -> MLTensor {
        let value = MLTensor.float(from: lhs)
        return rhs.mapValues { value.truncatingRemainder(dividingBy: $0) }
    }
    public static func += (lhs: inout MLTensor, rhs: MLTensor) { lhs = lhs + rhs }
    public static func -= (lhs: inout MLTensor, rhs: MLTensor) { lhs = lhs - rhs }
    public static func *= (lhs: inout MLTensor, rhs: MLTensor) { lhs = lhs * rhs }
    public static func /= (lhs: inout MLTensor, rhs: MLTensor) { lhs = lhs / rhs }
    public static func %= (lhs: inout MLTensor, rhs: MLTensor) { lhs = lhs % rhs }

    public static func .& (lhs: MLTensor, rhs: MLTensor) -> MLTensor {
        lhs.binary(rhs) { Float(Int32($0) & Int32($1)) }
    }
    public static func .| (lhs: MLTensor, rhs: MLTensor) -> MLTensor {
        lhs.binary(rhs) { Float(Int32($0) | Int32($1)) }
    }
    public static func .^ (lhs: MLTensor, rhs: MLTensor) -> MLTensor {
        lhs.binary(rhs) { Float(Int32($0) ^ Int32($1)) }
    }
    public static prefix func .! (rhs: MLTensor) -> MLTensor {
        rhs.mapValues { $0 == 0 ? 1 : 0 }
    }
    public static func .== (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, ==) }
    public static func .== (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 == MLTensor.float(from: rhs) ? 1 : 0 }
    }
    public static func .!= (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, !=) }
    public static func .!= (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 != MLTensor.float(from: rhs) ? 1 : 0 }
    }
    public static func .< (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, <) }
    public static func .< (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 < MLTensor.float(from: rhs) ? 1 : 0 }
    }
    public static func .> (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, >) }
    public static func .> (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 > MLTensor.float(from: rhs) ? 1 : 0 }
    }
    public static func .<= (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, <=) }
    public static func .<= (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 <= MLTensor.float(from: rhs) ? 1 : 0 }
    }
    public static func .>= (lhs: MLTensor, rhs: MLTensor) -> MLTensor { lhs.compare(rhs, >=) }
    public static func .>= (lhs: MLTensor, rhs: some MLTensorScalar & Numeric) -> MLTensor {
        lhs.mapValues { $0 >= MLTensor.float(from: rhs) ? 1 : 0 }
    }

    public enum PaddingMode: Hashable, CustomStringConvertible, Sendable {
        case constant(Float)
        case reflection
        case symmetric

        public var description: String {
            switch self {
            case .constant(let value): return "constant(\(value))"
            case .reflection: return "reflection"
            case .symmetric: return "symmetric"
            }
        }
    }

    public enum ResizeMethod: Hashable, CustomStringConvertible, Sendable {
        case nearestNeighbor
        case bilinear(alignCorners: Bool = false)

        public var description: String {
            switch self {
            case .nearestNeighbor: return "nearestNeighbor"
            case .bilinear(let align): return "bilinear(alignCorners: \(align))"
            }
        }
    }
}

public func pointwiseMax(_ lhs: MLTensor, _ rhs: MLTensor) -> MLTensor {
    lhs.binary(rhs, Swift.max)
}

public func pointwiseMax(_ lhs: MLTensor, _ rhs: some MLTensorScalar & Numeric) -> MLTensor {
    lhs.mapValues { Swift.max($0, MLTensor.float(from: rhs)) }
}

public func pointwiseMax(_ lhs: some MLTensorScalar & Numeric, _ rhs: MLTensor) -> MLTensor {
    rhs.mapValues { Swift.max(MLTensor.float(from: lhs), $0) }
}

public func pointwiseMin(_ lhs: MLTensor, _ rhs: MLTensor) -> MLTensor {
    lhs.binary(rhs, Swift.min)
}

public func pointwiseMin(_ lhs: MLTensor, _ rhs: some MLTensorScalar & Numeric) -> MLTensor {
    lhs.mapValues { Swift.min($0, MLTensor.float(from: rhs)) }
}

public func pointwiseMin(_ lhs: some MLTensorScalar & Numeric, _ rhs: MLTensor) -> MLTensor {
    rhs.mapValues { Swift.min(MLTensor.float(from: lhs), $0) }
}

// MARK: - Internals

extension MLTensor {
    func mapValues(_ body: (Float) -> Float) -> MLTensor {
        MLTensor(shape: shape, values: values.map(body), scalarType: scalarType)
    }

    func binary(_ other: MLTensor, _ body: (Float, Float) -> Float) -> MLTensor {
        let outShape = Self.broadcastShape(shape, other.shape)
        let left = broadcast(to: outShape).values
        let right = other.broadcast(to: outShape).values
        return MLTensor(shape: outShape, values: zip(left, right).map(body), scalarType: scalarType)
    }

    func compare(_ other: MLTensor, _ body: (Float, Float) -> Bool) -> MLTensor {
        binary(other) { body($0, $1) ? 1 : 0 }
    }

    func broadcast(to target: [Int]) -> MLTensor {
        if shape == target { return self }
        if shape.isEmpty {
            return MLTensor(shape: target, values: Array(repeating: values.first ?? 0, count: coreMLElementCount(shape: target)), scalarType: scalarType)
        }
        var output = Array(repeating: Float(0), count: coreMLElementCount(shape: target))
        let padded = Array(repeating: 1, count: Swift.max(target.count - shape.count, 0)) + shape
        for linear in 0..<output.count {
            let dest = coreMLUnravel(linear: linear, shape: target)
            var source: [Int] = []
            for (axis, dim) in padded.enumerated() {
                let index = dest[axis]
                source.append(dim == 1 ? 0 : index)
            }
            let trimmed = Array(source.suffix(shape.count))
            output[linear] = values[coreMLRavel(trimmed, shape: shape)]
        }
        return MLTensor(shape: target, values: output, scalarType: scalarType)
    }

    static func broadcastShape(_ lhs: [Int], _ rhs: [Int]) -> [Int] {
        let rank = Swift.max(lhs.count, rhs.count)
        let left = Array(repeating: 1, count: rank - lhs.count) + lhs
        let right = Array(repeating: 1, count: rank - rhs.count) + rhs
        return zip(left, right).map { Swift.max($0, $1) }
    }

    func reduceAll(keepRank: Bool, initial: Float, combine: (Float, Float) -> Float) -> MLTensor {
        let value = values.reduce(initial, combine)
        if keepRank {
            return MLTensor(shape: Array(repeating: 1, count: rank), values: [value], scalarType: scalarType)
        }
        return MLTensor(shape: [], values: [value], scalarType: scalarType)
    }

    func reduce(alongAxes axes: [Int], keepRank: Bool, initial: Float, combine: (Float, Float) -> Float) -> MLTensor {
        var current = self
        for axis in axes.sorted(by: >) {
            current = current.reduce(alongAxis: axis, keepRank: keepRank, initial: initial, combine: combine)
        }
        return current
    }

    func reduce(alongAxis axis: Int, keepRank: Bool, initial: Float, combine: (Float, Float) -> Float) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        var newShape = shape
        newShape[normalized] = keepRank ? 1 : 0
        if !keepRank {
            newShape.remove(at: normalized)
        }
        let length = shape[normalized]
        let groups = scalarCount / Swift.max(length, 1)
        var output = Array(repeating: initial, count: coreMLElementCount(shape: newShape.isEmpty ? [] : newShape))
        for group in 0..<groups {
            var acc = initial
            for index in 0..<length {
                acc = combine(acc, values[indexAlong(axis: normalized, group: group, index: index)])
            }
            output[group] = acc
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    func scan(alongAxis axis: Int, initial: Float, combine: (Float, Float) -> Float) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        let length = shape[normalized]
        let groups = scalarCount / Swift.max(length, 1)
        var output = values
        for group in 0..<groups {
            var acc = initial
            for index in 0..<length {
                let offset = indexAlong(axis: normalized, group: group, index: index)
                acc = combine(acc, values[offset])
                output[offset] = acc
            }
        }
        return MLTensor(shape: shape, values: output, scalarType: scalarType)
    }

    func argReduce(alongAxis axis: Int, keepRank: Bool, choose: (Float, Float) -> Bool) -> MLTensor {
        let normalized = axis < 0 ? axis + rank : axis
        let length = shape[normalized]
        let groups = scalarCount / Swift.max(length, 1)
        var newShape = shape
        newShape[normalized] = keepRank ? 1 : 0
        if !keepRank { newShape.remove(at: normalized) }
        var output = Array(repeating: Float(0), count: groups)
        for group in 0..<groups {
            var best = values[indexAlong(axis: normalized, group: group, index: 0)]
            var bestIndex = 0
            for index in 1..<length {
                let value = values[indexAlong(axis: normalized, group: group, index: index)]
                if choose(value, best) {
                    best = value
                    bestIndex = index
                }
            }
            output[group] = Float(bestIndex)
        }
        return MLTensor(shape: newShape, values: output, scalarType: Int32.self)
    }

    func indexAlong(axis: Int, group: Int, index: Int) -> Int {
        var reducedShape = shape
        reducedShape.remove(at: axis)
        if reducedShape.isEmpty {
            return Swift.max(0, Swift.min(index, Swift.max(scalarCount - 1, 0)))
        }
        var coords = coreMLUnravel(linear: group, shape: reducedShape)
        coords.insert(index, at: axis)
        return coreMLRavel(coords, shape: shape)
    }

    func sliced(axis: Int, index: Int) -> MLTensor {
        sliced(axis: axis, start: index, end: index + 1).squeezingShape(at: axis)
    }

    func sliced(axis: Int, start: Int, end: Int) -> MLTensor {
        var newShape = shape
        newShape[axis] = end - start
        var output: [Float] = []
        output.reserveCapacity(coreMLElementCount(shape: newShape))
        for linear in 0..<scalarCount {
            let coords = coreMLUnravel(linear: linear, shape: shape)
            if coords[axis] >= start && coords[axis] < end {
                output.append(values[linear])
            }
        }
        return MLTensor(shape: newShape, values: output, scalarType: scalarType)
    }

    func sliced(ranges: [(any MLTensorRangeExpression)?]) -> MLTensor {
        var current = self
        for (axis, expression) in ranges.enumerated() {
            guard axis < current.rank else { break }
            guard let expression, let range = expression as? CoreMLTensorRange else { continue }
            switch range.kind {
            case .index(let index):
                current = current.sliced(axis: axis, index: index)
            case .range(let slice, _):
                current = current.sliced(axis: axis, start: slice.lowerBound, end: slice.upperBound)
            case .closed(let slice, _):
                current = current.sliced(axis: axis, start: slice.lowerBound, end: slice.upperBound + 1)
            case .from(let slice, _):
                current = current.sliced(axis: axis, start: slice.lowerBound, end: current.shape[axis])
            case .upTo(let slice, _):
                current = current.sliced(axis: axis, start: 0, end: slice.upperBound)
            case .through(let slice, _):
                current = current.sliced(axis: axis, start: 0, end: slice.upperBound + 1)
            case .fillAll:
                continue
            case .newAxis:
                current = current.expandingShape(at: axis)
            case .squeeze:
                current = current.squeezingShape(at: axis)
            }
        }
        return current
    }

    func sampleBilinear(y: Float, x: Float, heightAxis: Int, widthAxis: Int, other: [Int]) -> Float {
        let y0 = Int(Foundation.floor(y))
        let x0 = Int(Foundation.floor(x))
        let y1 = Swift.min(y0 + 1, shape[heightAxis] - 1)
        let x1 = Swift.min(x0 + 1, shape[widthAxis] - 1)
        let wy = y - Float(y0)
        let wx = x - Float(x0)
        func at(_ yy: Int, _ xx: Int) -> Float {
            var coords = other
            coords[heightAxis] = Swift.max(0, yy)
            coords[widthAxis] = Swift.max(0, xx)
            return values[coreMLRavel(coords, shape: shape)]
        }
        let v00 = at(y0, x0)
        let v01 = at(y0, x1)
        let v10 = at(y1, x0)
        let v11 = at(y1, x1)
        return v00 * (1 - wy) * (1 - wx) + v01 * (1 - wy) * wx + v10 * wy * (1 - wx) + v11 * wy * wx
    }

    static func float(from value: Any) -> Float {
        switch value {
        case let float as Float: return float
        case let double as Double: return Float(double)
        case let float16 as Float16: return Float(float16)
        case let int as Int32: return Float(int)
        case let int8 as Int8: return Float(int8)
        case let bool as Bool: return bool ? 1 : 0
        case let int as Int: return Float(int)
        default: return 0
        }
    }

    static func decodeFloats(from data: Data, scalarType: any MLTensorScalar.Type) -> [Float] {
        if scalarType == Float.self {
            return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        }
        if scalarType == Double.self {
            return data.withUnsafeBytes { $0.bindMemory(to: Double.self).map { Float($0) } }
        }
        if scalarType == Int32.self {
            return data.withUnsafeBytes { $0.bindMemory(to: Int32.self).map { Float($0) } }
        }
        if scalarType == Int8.self {
            return data.withUnsafeBytes { $0.bindMemory(to: Int8.self).map { Float($0) } }
        }
        if scalarType == Float16.self {
            return data.withUnsafeBytes { $0.bindMemory(to: Float16.self).map { Float($0) } }
        }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }
}

func coreMLRavel(_ indices: [Int], shape: [Int]) -> Int {
    let strides = coreMLCContiguousStrides(shape: shape)
    return zip(indices, strides).reduce(0) { $0 + $1.0 * $1.1 }
}

func coreMLPadIndex(_ index: Int, length: Int, symmetric: Bool = false) -> Int {
    if length <= 0 { return 0 }
    var current = index
    let period = symmetric ? (2 * length) : (2 * Swift.max(length - 1, 1))
    if period == 0 { return 0 }
    current %= period
    if current < 0 { current += period }
    if current >= length {
        current = period - current
    }
    return Swift.min(Swift.max(current, 0), length - 1)
}

func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
    zip(zip(a, b), c).map { ($0.0, $0.1, $1) }
}

struct CoreMLPCG {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt32 {
        state = state &* 6364136223846793005 &+ 1
        return UInt32(truncatingIfNeeded: state >> 32)
    }

    mutating func nextUnit() -> Float {
        Float(next()) / Float(UInt32.max)
    }
}
