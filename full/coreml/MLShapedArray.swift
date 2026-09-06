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

    public var scalars: [Scalar] {
        var result: [Scalar] = []
        withUnsafeShapedBufferPointer { buffer, _, _ in
            result = Array(buffer)
        }
        return result
    }

    public var scalar: Scalar? {
        guard isScalar else { return nil }
        return scalars.first
    }

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
    public var count: Int { shape.first ?? 1 }

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
        let pointer = UnsafeMutablePointer<Scalar>.allocate(capacity: Swift.max(count, 1))
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
        let clamped = axis < 0 ? 0 : Swift.min(axis, newShape.count)
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

    public init<S>(concatenating shapedArrays: S, alongAxis: Int) where Scalar == S.Element.Scalar, S: Sequence, S.Element: MLShapedArrayProtocol {
        let arrays = Array(shapedArrays)
        precondition(!arrays.isEmpty, "concatenating empty MLShapedArray list")
        let rank = arrays[0].shape.count
        var axis = alongAxis
        if axis < 0 { axis += rank }
        precondition(axis >= 0 && axis < rank)
        var dims = arrays[0].shape
        var axisCount = 0
        var values: [Scalar] = []
        for array in arrays {
            precondition(array.shape.count == rank)
            for (index, dim) in array.shape.enumerated() where index != axis {
                precondition(dim == dims[index])
            }
            axisCount += array.shape[axis]
            array.withUnsafeShapedBufferPointer { buffer, _, _ in
                if Scalar.self == S.Element.Scalar.self {
                    values.append(contentsOf: Array(buffer))
                }
            }
        }
        dims[axis] = axisCount
        if axis == 0 {
            self.init(scalars: values, shape: dims)
        } else {
            let concat = MLMultiArray(
                byConcatenatingMultiArrays: arrays.map { MLMultiArray($0) },
                alongAxis: axis,
                dataType: Scalar.multiArrayDataType
            )
            self.init(converting: concat)
        }
    }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public subscript(bounds: Range<Int>) -> MLShapedArraySlice<Scalar> {
        get {
            precondition(bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex)
            var newShape = shape
            if newShape.isEmpty {
                return MLShapedArraySlice(scalars: bounds.isEmpty ? [] : storage, shape: [])
            }
            newShape[0] = bounds.count
            let remainder = Array(shape.dropFirst())
            let childCount = coreMLElementCount(shape: remainder)
            let start = bounds.lowerBound * childCount
            let length = bounds.count * childCount
            let values = (length == 0 || storage.isEmpty)
                ? [Scalar]()
                : Array(storage[start..<(start + length)])
            return MLShapedArraySlice(scalars: values, shape: newShape)
        }
        set {
            var rows: [MLShapedArraySlice<Scalar>] = []
            if bounds.lowerBound > 0 {
                rows.append(contentsOf: (0..<bounds.lowerBound).map { self[$0] })
            }
            rows.append(contentsOf: Array(newValue))
            if bounds.upperBound < count {
                rows.append(contentsOf: (bounds.upperBound..<count).map { self[$0] })
            }
            if rows.isEmpty {
                var emptyShape = shape
                if !emptyShape.isEmpty {
                    emptyShape[0] = 0
                }
                self.shape = emptyShape
                self.strides = coreMLCContiguousStrides(shape: emptyShape)
                self.storage = []
                return
            }
            let rebuilt = MLShapedArray<Scalar>(concatenating: rows, alongAxis: 0)
            self.shape = rebuilt.shape
            self.strides = rebuilt.strides
            self.storage = rebuilt.scalars
        }
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

extension MLShapedArray: RandomAccessCollection, MutableCollection {}

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
    public var count: Int { shape.first ?? 1 }
    public var description: String {
        "MLShapedArraySlice<\(Scalar.self)>(shape: \(shape), scalarCount: \(scalarCount))"
    }
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
        let pointer = UnsafeMutablePointer<Scalar>.allocate(capacity: Swift.max(count, 1))
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

    public subscript(index: Int) -> MLShapedArraySlice<Scalar> {
        get { slice(at: index) }
        set {
            let existing = slice(at: index)
            precondition(existing.shape == newValue.shape)
            let childCount = existing.scalarCount
            let start = index * childCount
            for offset in 0..<childCount {
                storage[start + offset] = newValue.scalars[offset]
            }
        }
    }

    public init<S>(concatenating shapedArrays: S, alongAxis: Int) where Scalar == S.Element.Scalar, S: Sequence, S.Element: MLShapedArrayProtocol {
        let array = MLShapedArray<Scalar>(concatenating: shapedArrays, alongAxis: alongAxis)
        self.shape = array.shape
        self.strides = array.strides
        self.storage = array.scalars
    }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public subscript(bounds: Range<Int>) -> MLShapedArraySlice<Scalar> {
        get {
            precondition(bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex)
            var newShape = shape
            if newShape.isEmpty {
                return MLShapedArraySlice(scalars: bounds.isEmpty ? [] : storage, shape: [])
            }
            newShape[0] = bounds.count
            let remainder = Array(shape.dropFirst())
            let childCount = coreMLElementCount(shape: remainder)
            let start = bounds.lowerBound * childCount
            let length = bounds.count * childCount
            let values = (length == 0 || storage.isEmpty)
                ? [Scalar]()
                : Array(storage[start..<(start + length)])
            return MLShapedArraySlice(scalars: values, shape: newShape)
        }
        set {
            replaceSubrange(bounds, with: Array(newValue))
        }
    }

    public init() {
        self.init(scalars: [Scalar](), shape: [0])
    }

    public mutating func replaceSubrange<C>(
        _ subrange: Range<Int>,
        with newElements: C
    ) where C: Collection, C.Element == MLShapedArraySlice<Scalar> {
        var rows = (0..<count).map { self[$0] }
        rows.replaceSubrange(subrange, with: Array(newElements))
        var newShape = shape
        if newShape.isEmpty {
            self = MLShapedArraySlice(scalars: rows.first?.scalars ?? [], shape: [])
            return
        }
        newShape[0] = rows.count
        var values: [Scalar] = []
        for row in rows {
            values.append(contentsOf: row.scalars)
        }
        self = MLShapedArraySlice(scalars: values, shape: newShape)
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
}

extension MLShapedArraySlice: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {}

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


public enum MLModelStructure: Sendable {
    public struct NeuralNetwork: Sendable {
        public struct Layer: Sendable {
            public let name: String
            public let type: String
            public let inputNames: [String]
            public let outputNames: [String]

            public init(name: String, type: String, inputNames: [String], outputNames: [String]) {
                self.name = name
                self.type = type
                self.inputNames = inputNames
                self.outputNames = outputNames
            }
        }

        public let layers: [Layer]

        public init(layers: [Layer]) {
            self.layers = layers
        }
    }

    public struct Program: Sendable {
        public struct ValueType: Sendable {
            public init() {}
        }
        public struct Value: Sendable {
            public init() {}
        }
        public enum Binding: Sendable {
            case name(String)
            case value(Value)
        }
        public struct NamedValueType: Sendable {
            public let name: String
            public let type: ValueType

            public init(name: String, type: ValueType) {
                self.name = name
                self.type = type
            }
        }
        public struct Argument: Sendable {
            public let bindings: [Binding]

            public init(bindings: [Binding]) {
                self.bindings = bindings
            }
        }
        public struct Operation: Sendable {
            public let operatorName: String
            public let inputs: [String: Argument]
            public let outputs: [NamedValueType]
            public let blocks: [Block]

            public init(
                operatorName: String,
                inputs: [String: Argument],
                outputs: [NamedValueType],
                blocks: [Block]
            ) {
                self.operatorName = operatorName
                self.inputs = inputs
                self.outputs = outputs
                self.blocks = blocks
            }
        }
        public struct Block: Sendable {
            public let inputs: [NamedValueType]
            public let outputNames: [String]
            public let operations: [Operation]

            public init(inputs: [NamedValueType], outputs: [String], operations: [Operation]) {
                self.inputs = inputs
                self.outputNames = outputs
                self.operations = operations
            }
        }
        public struct Function: Sendable {
            public let inputs: [NamedValueType]
            public let block: Block

            public init(inputs: [NamedValueType], block: Block) {
                self.inputs = inputs
                self.block = block
            }
        }

        public let functions: [String: Function]

        public init(functions: [String: Function]) {
            self.functions = functions
        }
    }

    public struct Pipeline: Sendable {
        public let subModelNames: [String]
        public let subModels: [MLModelStructure]

        public init(subModelNames: [String], subModels: [MLModelStructure]) {
            self.subModelNames = subModelNames
            self.subModels = subModels
        }
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

        public init(preferred: MLComputeDevice, supported: [MLComputeDevice]) {
            self.preferred = preferred
            self.supported = supported
        }
    }

    public struct Cost: Sendable {
        public let weight: Double

        public init(weight: Double) {
            self.weight = weight
        }
    }

    public let modelStructure: MLModelStructure

    public init(modelStructure: MLModelStructure) {
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
