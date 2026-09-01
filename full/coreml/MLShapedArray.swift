import Foundation

public protocol MLShapedArrayScalar {
    static var multiArrayDataType: MLMultiArrayDataType { get }
}

extension Double: MLShapedArrayScalar {
    public static var multiArrayDataType: MLMultiArrayDataType { .double }
}

extension Float: MLShapedArrayScalar {
    public static var multiArrayDataType: MLMultiArrayDataType { .float32 }
}

extension Float16: MLShapedArrayScalar {
    public static var multiArrayDataType: MLMultiArrayDataType { .float16 }
}

extension Int32: MLShapedArrayScalar {
    public static var multiArrayDataType: MLMultiArrayDataType { .int32 }
}

extension Int8: MLShapedArrayScalar {
    public static var multiArrayDataType: MLMultiArrayDataType { .int8 }
}

public enum MLShapedArrayBufferLayout: Sendable {
    case lastMajorContiguous
    case firstMajorContiguous
    case strides([Int])
}

public protocol MLShapedArrayRangeExpression {
    func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int>
}

extension Range: MLShapedArrayRangeExpression where Bound == Int {
    public func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int> {
        let lower = Swift.max(lowerBound, range.lowerBound)
        let upper = Swift.min(upperBound, range.upperBound)
        return lower..<Swift.max(lower, upper)
    }
}

extension ClosedRange: MLShapedArrayRangeExpression where Bound == Int {
    public func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int> {
        (lowerBound..<(upperBound + 1)).relative(toShapedArrayAxis: range)
    }
}

extension PartialRangeFrom: MLShapedArrayRangeExpression where Bound == Int {
    public func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int> {
        (lowerBound..<range.upperBound).relative(toShapedArrayAxis: range)
    }
}

extension PartialRangeUpTo: MLShapedArrayRangeExpression where Bound == Int {
    public func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int> {
        (range.lowerBound..<upperBound).relative(toShapedArrayAxis: range)
    }
}

extension PartialRangeThrough: MLShapedArrayRangeExpression where Bound == Int {
    public func relative(toShapedArrayAxis range: Range<Int>) -> Range<Int> {
        (range.lowerBound..<(upperBound + 1)).relative(toShapedArrayAxis: range)
    }
}

public protocol MLShapedArrayProtocol<Scalar>: ExpressibleByArrayLiteral {
    associatedtype Scalar: MLShapedArrayScalar
    var shape: [Int] { get }
    var strides: [Int] { get }
    init(bytesNoCopy bytes: UnsafeRawPointer, shape: [Int], strides: [Int], deallocator: Data.Deallocator)
    init(
        unsafeUninitializedShape shape: [Int],
        initializingWith initializer: (inout UnsafeMutableBufferPointer<Scalar>, [Int]) throws -> Void
    ) rethrows
    func withUnsafeShapedBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R
    mutating func withUnsafeMutableShapedBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R
    subscript<C>(scalarAt indices: C) -> Scalar where C: Collection, C.Element == Int { get set }
}

extension MLShapedArrayProtocol {
    public var scalarCount: Int { coreMLElementCount(shape: shape) }
    public var isScalar: Bool { shape.isEmpty }
    public var count: Int { shape.first ?? 1 }

    public init(bytesNoCopy bytes: UnsafeRawPointer, shape: [Int], deallocator: Data.Deallocator) {
        self.init(
            bytesNoCopy: bytes,
            shape: shape,
            strides: coreMLCContiguousStrides(shape: shape),
            deallocator: deallocator
        )
    }

    public init(repeating value: Scalar, shape: [Int]) {
        let array = Self(
            unsafeUninitializedShape: shape,
            initializingWith: { buffer, _ in
                for index in 0..<buffer.count {
                    buffer[index] = value
                }
            }
        )
        _ = array
        self = array
    }
}

public struct MLShapedArray<Scalar: MLShapedArrayScalar>: MLShapedArrayProtocol {
    public typealias ArrayLiteralElement = Scalar
    public typealias Index = Int
    public typealias Element = MLShapedArraySlice<Scalar>
    public typealias SubSequence = MLShapedArraySlice<Scalar>
    public typealias Indices = Range<Int>

    public private(set) var shape: [Int]
    public private(set) var strides: [Int]
    private var storage: [Scalar]

    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    public var indices: Range<Int> { startIndex..<endIndex }

    public var scalars: [Scalar] {
        get { storage }
        set {
            precondition(newValue.count == storage.count)
            storage = newValue
        }
    }

    public var scalar: Scalar? {
        get { isScalar || storage.count == 1 ? storage.first : nil }
        set {
            if let newValue, !storage.isEmpty {
                storage[0] = newValue
            }
        }
    }

    public var description: String {
        "MLShapedArray<\(Scalar.self)>(shape: \(shape), scalarCount: \(scalarCount))"
    }

    public init(arrayLiteral elements: Scalar...) {
        self.init(scalars: elements, shape: [elements.count])
    }

    public init(scalar: Scalar) {
        self.shape = []
        self.strides = []
        self.storage = [scalar]
    }

    public init<S>(scalars: S, shape: [Int]) where Scalar == S.Element, S: Sequence {
        let values = Array(scalars)
        precondition(values.count == coreMLElementCount(shape: shape))
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        self.storage = values
    }

    public init(repeating value: Scalar, shape: [Int]) {
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        self.storage = Array(repeating: value, count: coreMLElementCount(shape: shape))
    }

    public init(data: Data, shape: [Int]) {
        self.init(data: data, shape: shape, strides: coreMLCContiguousStrides(shape: shape))
    }

    public init(data: Data, shape: [Int], strides: [Int]) {
        precondition(data.count >= coreMLElementCount(shape: shape) * MemoryLayout<Scalar>.stride)
        self.shape = shape
        self.strides = strides
        self.storage = data.withUnsafeBytes { buffer in
            let typed = buffer.bindMemory(to: Scalar.self)
            return Array(typed.prefix(coreMLElementCount(shape: shape)))
        }
    }

    public init(
        bytesNoCopy bytes: UnsafeRawPointer,
        shape: [Int],
        strides: [Int],
        deallocator: Data.Deallocator
    ) {
        let count = coreMLElementCount(shape: shape)
        let typed = bytes.bindMemory(to: Scalar.self, capacity: count)
        self.shape = shape
        self.strides = strides
        self.storage = Array(UnsafeBufferPointer(start: typed, count: count))
        switch deallocator {
        case .free:
            free(UnsafeMutableRawPointer(mutating: bytes))
        case .none:
            break
        default:
            break
        }
    }

    public init(
        unsafeUninitializedShape shape: [Int],
        initializingWith initializer: (inout UnsafeMutableBufferPointer<Scalar>, [Int]) throws -> Void
    ) rethrows {
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        let count = coreMLElementCount(shape: shape)
        let pointer = UnsafeMutablePointer<Scalar>.allocate(capacity: max(count, 1))
        defer { pointer.deallocate() }
        var buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        try initializer(&buffer, self.strides)
        self.storage = count == 0 ? [] : Array(UnsafeBufferPointer(start: pointer, count: count))
    }

    public init(_ multiArray: MLMultiArray) {
        self.init(converting: multiArray)
    }

    public init(converting multiArray: MLMultiArray) {
        precondition(Scalar.multiArrayDataType == multiArray.dataType)
        self.shape = multiArray.shape.map(\.intValue)
        self.strides = multiArray.strides.map(\.intValue)
        self.storage = multiArray.withUnsafeBufferPointer(ofType: Scalar.self) { Array($0) }
    }

    public init<T>(converting source: T) where T: MLShapedArrayProtocol {
        self.shape = source.shape
        self.strides = source.strides
        var copied: [Scalar] = []
        copied.reserveCapacity(coreMLElementCount(shape: source.shape))
        source.withUnsafeShapedBufferPointer { buffer, _, _ in
            if Scalar.self == T.Scalar.self {
                copied = buffer.map { unsafeBitCast($0, to: Scalar.self) }
            }
        }
        self.storage = copied
    }

    public init(randomScalarsIn range: Range<Scalar>, shape: [Int]) where Scalar: FixedWidthInteger {
        self.init(scalars: (0..<coreMLElementCount(shape: shape)).map { _ in Scalar.random(in: range) }, shape: shape)
    }

    public init(identityMatrixOfSize size: Int) where Scalar: FixedWidthInteger {
        var values = Array(repeating: Scalar.zero, count: size * size)
        for index in 0..<size {
            values[index * size + index] = 1
        }
        self.init(scalars: values, shape: [size, size])
    }

    public subscript<C>(scalarAt indices: C) -> Scalar where C: Collection, C.Element == Int {
        get { storage[linearIndex(Array(indices))] }
        set { storage[linearIndex(Array(indices))] = newValue }
    }

    public subscript(scalarAt indices: Int...) -> Scalar {
        get { self[scalarAt: indices] }
        set { self[scalarAt: indices] = newValue }
    }

    public subscript(index: Int) -> MLShapedArraySlice<Scalar> {
        get { slice(at: index) }
        set {
            let existing = slice(at: index)
            precondition(existing.shape == newValue.shape)
            for offset in 0..<existing.scalarCount {
                storage[linearIndex([index]) + offset] = newValue.scalars[offset]
            }
        }
    }

    public func withUnsafeShapedBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        try storage.withUnsafeBufferPointer { buffer in
            try body(buffer, shape, strides)
        }
    }

    public mutating func withUnsafeMutableShapedBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        try storage.withUnsafeMutableBufferPointer { buffer in
            var mutable = buffer
            return try body(&mutable, shape, strides)
        }
    }

    public mutating func withUnsafeMutableShapedBufferPointer<R>(
        using bufferLayout: MLShapedArrayBufferLayout,
        _ body: (inout UnsafeMutableBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        _ = bufferLayout
        return try withUnsafeMutableShapedBufferPointer(body)
    }

    public mutating func fill(with value: Scalar) {
        for index in storage.indices {
            storage[index] = value
        }
    }

    public mutating func fill<C>(with collection: C) where C: Collection, Scalar == C.Element {
        precondition(collection.count == storage.count)
        storage = Array(collection)
    }

    public func reshaped(to newShape: [Int]) -> MLShapedArray<Scalar> {
        precondition(coreMLElementCount(shape: newShape) == scalarCount)
        return MLShapedArray(scalars: storage, shape: newShape)
    }

    public func transposed() -> MLShapedArray<Scalar> {
        transposed(permutation: Array(stride(from: shape.count - 1, through: 0, by: -1)))
    }

    public func transposed(permutation axes: [Int]) -> MLShapedArray<Scalar> {
        precondition(axes.count == shape.count)
        let newShape = axes.map { shape[$0] }
        var result = MLShapedArray(repeating: storage[0], shape: newShape)
        // Copy only the identity permutation or reverse for rank <= 2, otherwise keep values in storage order.
        if axes == Array(0..<shape.count) {
            result.storage = storage
        } else if shape.count == 2 && axes == [1, 0] {
            let rows = shape[0]
            let cols = shape[1]
            var transposed: [Scalar] = []
            transposed.reserveCapacity(storage.count)
            for column in 0..<cols {
                for row in 0..<rows {
                    transposed.append(storage[row * cols + column])
                }
            }
            result.storage = transposed
        } else {
            result.storage = storage
        }
        return result
    }

    public func expandingShape(at axis: Int) -> MLShapedArray<Scalar> {
        var newShape = shape
        let clamped = axis < 0 ? 0 : min(axis, newShape.count)
        newShape.insert(1, at: clamped)
        return reshaped(to: newShape)
    }

    public func squeezingShape() -> MLShapedArray<Scalar> {
        reshaped(to: shape.filter { $0 != 1 })
    }

    public func changingLayout(to bufferLayout: MLShapedArrayBufferLayout) -> MLShapedArray<Scalar> {
        _ = bufferLayout
        return self
    }

    private func slice(at index: Int) -> MLShapedArraySlice<Scalar> {
        if shape.isEmpty {
            return MLShapedArraySlice(scalars: storage, shape: [])
        }
        let remainder = Array(shape.dropFirst())
        let childCount = coreMLElementCount(shape: remainder)
        let start = index * childCount
        return MLShapedArraySlice(scalars: Array(storage[start..<(start + childCount)]), shape: remainder)
    }

    private func linearIndex(_ indices: [Int]) -> Int {
        zip(indices, strides).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

extension MLShapedArray: Equatable where Scalar: Equatable {
    public static func == (lhs: MLShapedArray<Scalar>, rhs: MLShapedArray<Scalar>) -> Bool {
        lhs.shape == rhs.shape && lhs.storage == rhs.storage
    }
}

extension MLShapedArray: Encodable where Scalar: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shape, forKey: .shape)
        try container.encode(storage, forKey: .scalars)
    }
}

extension MLShapedArray: Decodable where Scalar: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shape = try container.decode([Int].self, forKey: .shape)
        let scalars = try container.decode([Scalar].self, forKey: .scalars)
        self.init(scalars: scalars, shape: shape)
    }
}

private enum CodingKeys: String, CodingKey {
    case shape
    case scalars
}

public struct MLShapedArraySlice<Scalar: MLShapedArrayScalar>: MLShapedArrayProtocol {
    public typealias ArrayLiteralElement = Scalar
    public typealias Index = Int
    public typealias Element = MLShapedArraySlice<Scalar>
    public typealias SubSequence = MLShapedArraySlice<Scalar>
    public typealias Indices = Range<Int>

    public let shape: [Int]
    public var strides: [Int]
    private var storage: [Scalar]

    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    public var indices: Range<Int> { startIndex..<endIndex }
    public var scalars: [Scalar] {
        get { storage }
        set {
            precondition(newValue.count == storage.count)
            storage = newValue
        }
    }

    public var scalar: Scalar? {
        get { storage.count == 1 ? storage.first : nil }
        set {
            if let newValue, !storage.isEmpty { storage[0] = newValue }
        }
    }

    public init(arrayLiteral elements: Scalar...) {
        self.init(scalars: elements, shape: [elements.count])
    }

    public init(scalar: Scalar) {
        self.shape = []
        self.strides = []
        self.storage = [scalar]
    }

    public init<S>(scalars: S, shape: [Int]) where Scalar == S.Element, S: Sequence {
        let values = Array(scalars)
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        self.storage = values
    }

    public init(repeating value: Scalar, shape: [Int]) {
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        self.storage = Array(repeating: value, count: coreMLElementCount(shape: shape))
    }

    public init(data: Data, shape: [Int]) {
        self.init(data: data, shape: shape, strides: coreMLCContiguousStrides(shape: shape))
    }

    public init(data: Data, shape: [Int], strides: [Int]) {
        self.shape = shape
        self.strides = strides
        self.storage = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Scalar.self).prefix(coreMLElementCount(shape: shape)))
        }
    }

    public init(
        bytesNoCopy bytes: UnsafeRawPointer,
        shape: [Int],
        strides: [Int],
        deallocator: Data.Deallocator
    ) {
        let count = coreMLElementCount(shape: shape)
        let typed = bytes.bindMemory(to: Scalar.self, capacity: count)
        self.shape = shape
        self.strides = strides
        self.storage = Array(UnsafeBufferPointer(start: typed, count: count))
        if case .free = deallocator {
            free(UnsafeMutableRawPointer(mutating: bytes))
        }
    }

    public init(
        unsafeUninitializedShape shape: [Int],
        initializingWith initializer: (inout UnsafeMutableBufferPointer<Scalar>, [Int]) throws -> Void
    ) rethrows {
        self.shape = shape
        self.strides = coreMLCContiguousStrides(shape: shape)
        let count = coreMLElementCount(shape: shape)
        let pointer = UnsafeMutablePointer<Scalar>.allocate(capacity: max(count, 1))
        defer { pointer.deallocate() }
        var buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        try initializer(&buffer, self.strides)
        self.storage = count == 0 ? [] : Array(UnsafeBufferPointer(start: pointer, count: count))
    }

    public init(_ multiArray: MLMultiArray) {
        self.init(converting: multiArray)
    }

    public init(converting multiArray: MLMultiArray) {
        let array = MLShapedArray<Scalar>(converting: multiArray)
        self.shape = array.shape
        self.strides = array.strides
        self.storage = array.scalars
    }

    public init<T>(converting source: T) where T: MLShapedArrayProtocol {
        self.shape = source.shape
        self.strides = source.strides
        var copied: [Scalar] = []
        source.withUnsafeShapedBufferPointer { buffer, _, _ in
            if Scalar.self == T.Scalar.self {
                copied = buffer.map { unsafeBitCast($0, to: Scalar.self) }
            }
        }
        self.storage = copied
    }

    public init(randomScalarsIn range: Range<Scalar>, shape: [Int]) where Scalar: FixedWidthInteger {
        self.init(scalars: (0..<coreMLElementCount(shape: shape)).map { _ in Scalar.random(in: range) }, shape: shape)
    }

    public init(identityMatrixOfSize size: Int) where Scalar: FixedWidthInteger {
        self.init(converting: MLShapedArray<Scalar>(identityMatrixOfSize: size))
    }

    public subscript<C>(scalarAt indices: C) -> Scalar where C: Collection, C.Element == Int {
        get { storage[zip(Array(indices), strides).reduce(0) { $0 + $1.0 * $1.1 }] }
        set { storage[zip(Array(indices), strides).reduce(0) { $0 + $1.0 * $1.1 }] = newValue }
    }

    public subscript(scalarAt indices: Int...) -> Scalar {
        get { self[scalarAt: indices] }
        set { self[scalarAt: indices] = newValue }
    }

    public func withUnsafeShapedBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        try storage.withUnsafeBufferPointer { try body($0, shape, strides) }
    }

    public mutating func withUnsafeMutableShapedBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        try storage.withUnsafeMutableBufferPointer { buffer in
            var mutable = buffer
            return try body(&mutable, shape, strides)
        }
    }

    public mutating func withUnsafeMutableShapedBufferPointer<R>(
        using bufferLayout: MLShapedArrayBufferLayout,
        _ body: (inout UnsafeMutableBufferPointer<Scalar>, [Int], [Int]) throws -> R
    ) rethrows -> R {
        _ = bufferLayout
        return try withUnsafeMutableShapedBufferPointer(body)
    }

    public mutating func fill(with value: Scalar) {
        storage = Array(repeating: value, count: storage.count)
    }

    public mutating func fill<C>(with collection: C) where C: Collection, Scalar == C.Element {
        storage = Array(collection)
    }

    public func reshaped(to newShape: [Int]) -> MLShapedArraySlice<Scalar> {
        MLShapedArraySlice(scalars: storage, shape: newShape)
    }

    public func transposed() -> MLShapedArraySlice<Scalar> {
        MLShapedArraySlice(converting: MLShapedArray(scalars: storage, shape: shape).transposed())
    }

    public func transposed(permutation axes: [Int]) -> MLShapedArraySlice<Scalar> {
        MLShapedArraySlice(converting: MLShapedArray(scalars: storage, shape: shape).transposed(permutation: axes))
    }

    public func expandingShape(at axis: Int) -> MLShapedArraySlice<Scalar> {
        MLShapedArraySlice(converting: MLShapedArray(scalars: storage, shape: shape).expandingShape(at: axis))
    }

    public func squeezingShape() -> MLShapedArraySlice<Scalar> {
        MLShapedArraySlice(converting: MLShapedArray(scalars: storage, shape: shape).squeezingShape())
    }

    public func changingLayout(to bufferLayout: MLShapedArrayBufferLayout) -> MLShapedArraySlice<Scalar> {
        _ = bufferLayout
        return self
    }
}

extension MLShapedArraySlice: Equatable where Scalar: Equatable {
    public static func == (lhs: MLShapedArraySlice<Scalar>, rhs: MLShapedArraySlice<Scalar>) -> Bool {
        lhs.shape == rhs.shape && lhs.storage == rhs.storage
    }
}

extension MLShapedArraySlice: Encodable where Scalar: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shape, forKey: .shape)
        try container.encode(storage, forKey: .scalars)
    }
}

extension MLShapedArraySlice: Decodable where Scalar: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shape = try container.decode([Int].self, forKey: .shape)
        let scalars = try container.decode([Scalar].self, forKey: .scalars)
        self.init(scalars: scalars, shape: shape)
    }
}


public struct MLTensor: Sendable, CustomStringConvertible {
    public let shape: [Int]
    public var scalarType: any MLTensorScalar.Type
    private let storage: Data

    public var rank: Int { shape.count }
    public var scalarCount: Int { coreMLElementCount(shape: shape) }
    public var isScalar: Bool { shape.isEmpty }
    public var description: String { "MLTensor(shape: \(shape), scalarCount: \(scalarCount))" }
    public var customMirror: Mirror {
        Mirror(self, children: ["shape": shape, "scalarCount": scalarCount])
    }

    public init(shape: [Int], data: Data, scalarType: any MLTensorScalar.Type) {
        self.shape = shape
        self.storage = data
        self.scalarType = scalarType
    }

    public init(repeating repeatedValue: Float, shape: [Int]) {
        var data = Data(count: coreMLElementCount(shape: shape) * MemoryLayout<Float>.stride)
        data.withUnsafeMutableBytes { buffer in
            buffer.bindMemory(to: Float.self).initialize(repeating: repeatedValue)
        }
        self.init(shape: shape, data: data, scalarType: Float.self)
    }

    public init(_ scalars: some Collection<Float>) {
        self.init(shape: [scalars.count], scalars: Array(scalars))
    }

    public init(_ scalars: some Collection<Int32>) {
        var data = Data(count: scalars.count * MemoryLayout<Int32>.stride)
        data.withUnsafeMutableBytes { buffer in
            var iterator = scalars.makeIterator()
            for index in buffer.bindMemory(to: Int32.self).indices {
                buffer.bindMemory(to: Int32.self)[index] = iterator.next() ?? 0
            }
        }
        self.init(shape: [scalars.count], data: data, scalarType: Int32.self)
    }

    public init(shape: [Int], scalars: some Collection<Float>) {
        var data = Data(count: coreMLElementCount(shape: shape) * MemoryLayout<Float>.stride)
        data.withUnsafeMutableBytes { buffer in
            var iterator = scalars.makeIterator()
            for index in buffer.bindMemory(to: Float.self).indices {
                buffer.bindMemory(to: Float.self)[index] = iterator.next() ?? 0
            }
        }
        self.init(shape: shape, data: data, scalarType: Float.self)
    }

    public init<Scalar: MLTensorScalar>(zeros shape: [Int], scalarType: Scalar.Type = Scalar.self) {
        self.init(shape: shape, data: Data(count: coreMLElementCount(shape: shape) * 4), scalarType: scalarType)
    }

    public func reshaped(to newShape: [Int]) -> MLTensor {
        precondition(coreMLElementCount(shape: newShape) == scalarCount)
        return MLTensor(shape: newShape, data: storage, scalarType: scalarType)
    }

    public func flattened() -> MLTensor {
        reshaped(to: [scalarCount])
    }

    public func shapedArray<Scalar>(
        of scalarType: Scalar.Type
    ) async -> MLShapedArray<Scalar> where Scalar: MLShapedArrayScalar, Scalar: MLTensorScalar {
        MLShapedArray(data: storage, shape: shape)
    }
}

public enum MLModelStructure: Sendable {
    public struct NeuralNetwork: Sendable {
        public struct Layer: Sendable {
            public let name: String
            public let type: String
            public let inputNames: [String]
            public let outputNames: [String]
        }

        public let layers: [Layer]
    }

    public struct Program: Sendable {
        public struct ValueType: Sendable {}
        public struct Value: Sendable {}
        public enum Binding: Sendable {
            case name(String)
            case value(Value)
        }
        public struct NamedValueType: Sendable {
            public let name: String
            public let type: ValueType
        }
        public struct Argument: Sendable {
            public let bindings: [Binding]
        }
        public struct Operation: Sendable {
            public let operatorName: String
            public let inputs: [String: Argument]
            public let outputs: [NamedValueType]
            public let blocks: [Block]
        }
        public struct Block: Sendable {
            public let inputs: [NamedValueType]
            public let outputs: [String]
            public let operations: [Operation]
        }
        public struct Function: Sendable {
            public let inputs: [NamedValueType]
            public let block: Block
        }

        public let functions: [String: Function]
    }

    public struct Pipeline: Sendable {
        public let subModelNames: [String]
        public let subModels: [MLModelStructure]
    }

    case neuralNetwork(NeuralNetwork)
    case program(Program)
    case pipeline(Pipeline)
    case unsupported

    public static func load(contentsOf url: URL) async throws -> MLModelStructure {
        _ = url
        throw coreMLNoModelIO("MLModelStructure.load(contentsOf:)")
    }

    public static func load(asset: MLModelAsset) async throws -> MLModelStructure {
        _ = asset
        throw coreMLNoModelIO("MLModelStructure.load(asset:)")
    }
}

public final class MLComputePlan {
    public struct DeviceUsage {
        public let preferred: MLComputeDevice
        public let supported: [MLComputeDevice]
    }

    public struct Cost: Sendable {
        public let weight: Double
    }

    public let modelStructure: MLModelStructure

    init(modelStructure: MLModelStructure) {
        self.modelStructure = modelStructure
    }

    public static func load(
        contentsOf url: URL,
        configuration: MLModelConfiguration
    ) async throws -> MLComputePlan {
        _ = (url, configuration)
        throw coreMLNoModelIO("MLComputePlan.load(contentsOf:configuration:)")
    }

    public static func load(
        asset: MLModelAsset,
        configuration: MLModelConfiguration
    ) async throws -> MLComputePlan {
        _ = (asset, configuration)
        throw coreMLNoModelIO("MLComputePlan.load(asset:configuration:)")
    }

    public func deviceUsage(for layer: MLModelStructure.NeuralNetwork.Layer) -> DeviceUsage? {
        _ = layer
        return nil
    }

    public func deviceUsage(for operation: MLModelStructure.Program.Operation) -> DeviceUsage? {
        _ = operation
        return nil
    }

    public func estimatedCost(of operation: MLModelStructure.Program.Operation) -> Cost? {
        _ = operation
        return nil
    }
}
