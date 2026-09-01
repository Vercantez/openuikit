import Foundation

private final class MLMultiArrayStorage {
    let pointer: UnsafeMutableRawPointer
    let byteCount: Int
    let deallocator: (UnsafeMutableRawPointer) -> Void

    init(byteCount: Int) {
        self.byteCount = byteCount
        self.pointer = UnsafeMutableRawPointer.allocate(
            byteCount: max(byteCount, 1),
            alignment: MemoryLayout<Double>.alignment
        )
        self.pointer.initializeMemory(as: UInt8.self, repeating: 0, count: max(byteCount, 1))
        self.deallocator = { $0.deallocate() }
    }

    init(
        pointer: UnsafeMutableRawPointer,
        byteCount: Int,
        deallocator: ((UnsafeMutableRawPointer) -> Void)?
    ) {
        self.pointer = pointer
        self.byteCount = byteCount
        self.deallocator = deallocator ?? { _ in }
    }

    deinit {
        deallocator(pointer)
    }
}

open class MLMultiArray: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private let storage: MLMultiArrayStorage
    public private(set) var shape: [NSNumber]
    public private(set) var dataType: MLMultiArrayDataType
    public private(set) var strides: [NSNumber]

    public var count: Int {
        coreMLElementCount(shape: shape.map(\.intValue))
    }

    public var dataPointer: UnsafeMutableRawPointer {
        storage.pointer
    }

    public init(shape: [NSNumber], dataType: MLMultiArrayDataType) throws {
        let dims = shape.map(\.intValue)
        guard dims.allSatisfy({ $0 >= 0 }) else {
            throw coreMLError(.io, "MLMultiArray shape must be non-negative.")
        }
        let elementCount = coreMLElementCount(shape: dims)
        let byteCount = coreMLByteCount(count: elementCount, dataType: dataType)
        self.storage = MLMultiArrayStorage(byteCount: byteCount)
        self.shape = shape
        self.dataType = dataType
        self.strides = coreMLCContiguousStrides(shape: dims).map { NSNumber(value: $0) }
        super.init()
    }

    public convenience init(shape: [Int], dataType: MLMultiArrayDataType, strides: [Int]) {
        let elementCount = coreMLElementCount(shape: shape)
        let owned = MLMultiArrayStorage(
            byteCount: coreMLByteCount(count: elementCount, dataType: dataType)
        )
        try! self.init(
            dataPointer: owned.pointer,
            shape: shape.map { NSNumber(value: $0) },
            dataType: dataType,
            strides: strides.map { NSNumber(value: $0) },
            deallocator: { _ in
                withExtendedLifetime(owned) {}
            }
        )
    }

    public init(
        dataPointer: UnsafeMutableRawPointer,
        shape: [NSNumber],
        dataType: MLMultiArrayDataType,
        strides: [NSNumber],
        deallocator: ((UnsafeMutableRawPointer) -> Void)? = nil
    ) throws {
        let dims = shape.map(\.intValue)
        let elementCount = coreMLElementCount(shape: dims)
        self.storage = MLMultiArrayStorage(
            pointer: dataPointer,
            byteCount: coreMLByteCount(count: elementCount, dataType: dataType),
            deallocator: deallocator
        )
        self.shape = shape
        self.dataType = dataType
        self.strides = strides
        super.init()
    }

    public convenience init(byConcatenatingMultiArrays multiArrays: [MLMultiArray], alongAxis axis: Int, dataType: MLMultiArrayDataType) {
        precondition(!multiArrays.isEmpty, "concatenating empty MLMultiArray list")
        let first = multiArrays[0]
        var dims = first.shape.map(\.intValue)
        let normalizedAxis = axis < 0 ? axis + dims.count : axis
        precondition(normalizedAxis >= 0 && normalizedAxis < dims.count)
        var axisCount = 0
        for array in multiArrays {
            precondition(array.dataType == dataType)
            precondition(array.shape.count == first.shape.count)
            for (index, dim) in array.shape.map(\.intValue).enumerated() where index != normalizedAxis {
                precondition(dim == dims[index])
            }
            axisCount += array.shape[normalizedAxis].intValue
        }
        dims[normalizedAxis] = axisCount
        try! self.init(shape: dims.map { NSNumber(value: $0) }, dataType: dataType)
        var destinationOffset = 0
        for array in multiArrays {
            let bytes = coreMLByteCount(count: array.count, dataType: dataType)
            self.dataPointer.advanced(by: destinationOffset).copyMemory(
                from: array.dataPointer,
                byteCount: bytes
            )
            destinationOffset += bytes
        }
    }

    public convenience init<C>(_ data: C) throws where C: Collection, C.Element == Double {
        try self.init(shape: [NSNumber(value: data.count)], dataType: .double)
        var index = 0
        for value in data {
            self[index] = NSNumber(value: value)
            index += 1
        }
    }

    public convenience init<C>(_ data: C) throws where C: Collection, C.Element == Float {
        try self.init(shape: [NSNumber(value: data.count)], dataType: .float32)
        var index = 0
        for value in data {
            self[index] = NSNumber(value: value)
            index += 1
        }
    }

    public convenience init<C>(_ data: C) throws where C: Collection, C.Element: FixedWidthInteger {
        try self.init(shape: [NSNumber(value: data.count)], dataType: .int32)
        var index = 0
        for value in data {
            self[index] = NSNumber(value: Int32(truncatingIfNeeded: value))
            index += 1
        }
    }

    public convenience init<ShapedArray>(_ shapedArray: ShapedArray) where ShapedArray: MLShapedArrayProtocol {
        try! self.init(
            shape: shapedArray.shape.map { NSNumber(value: $0) },
            dataType: ShapedArray.Scalar.multiArrayDataType
        )
        shapedArray.withUnsafeShapedBufferPointer { buffer, _, _ in
            let bytes = buffer.count * MemoryLayout<ShapedArray.Scalar>.stride
            if bytes > 0, let base = buffer.baseAddress {
                self.dataPointer.copyMemory(from: UnsafeRawPointer(base), byteCount: bytes)
            }
        }
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    public subscript(idx: Int) -> NSNumber {
        get { number(atLinear: idx) }
        set { setNumber(newValue, atLinear: idx) }
    }

    public subscript(key: [NSNumber]) -> NSNumber {
        get { number(atLinear: linearIndex(key.map(\.intValue))) }
        set { setNumber(newValue, atLinear: linearIndex(key.map(\.intValue))) }
    }

    public func transfer(to destinationMultiArray: MLMultiArray) {
        precondition(count == destinationMultiArray.count)
        precondition(dataType == destinationMultiArray.dataType)
        destinationMultiArray.dataPointer.copyMemory(from: dataPointer, byteCount: storage.byteCount)
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try body(UnsafeRawBufferPointer(start: storage.pointer, count: storage.byteCount))
    }

    public func withUnsafeMutableBytes<R>(
        _ body: (UnsafeMutableRawBufferPointer, [Int]) throws -> R
    ) rethrows -> R {
        try body(
            UnsafeMutableRawBufferPointer(start: storage.pointer, count: storage.byteCount),
            strides.map(\.intValue)
        )
    }

    public func withUnsafeBufferPointer<S, R>(
        ofType type: S.Type,
        _ body: (UnsafeBufferPointer<S>) throws -> R
    ) rethrows -> R where S: MLShapedArrayScalar {
        precondition(S.multiArrayDataType == dataType)
        let typed = UnsafePointer<S>(OpaquePointer(storage.pointer))
        return try body(UnsafeBufferPointer(start: typed, count: count))
    }

    public func withUnsafeMutableBufferPointer<S, R>(
        ofType type: S.Type,
        _ body: (UnsafeMutableBufferPointer<S>, [Int]) throws -> R
    ) rethrows -> R where S: MLShapedArrayScalar {
        precondition(S.multiArrayDataType == dataType)
        let typed = UnsafeMutablePointer<S>(OpaquePointer(storage.pointer))
        return try body(
            UnsafeMutableBufferPointer(start: typed, count: count),
            strides.map(\.intValue)
        )
    }

    private func linearIndex(_ indices: [Int]) -> Int {
        zip(indices, strides.map(\.intValue)).reduce(0) { $0 + $1.0 * $1.1 }
    }

    private func number(atLinear index: Int) -> NSNumber {
        let pointer = storage.pointer
        switch dataType {
        case .double:
            return NSNumber(value: pointer.advanced(by: index * 8).load(as: Double.self))
        case .float32:
            return NSNumber(value: pointer.advanced(by: index * 4).load(as: Float.self))
        case .float16:
            let value = pointer.advanced(by: index * 2).load(as: Float16.self)
            return NSNumber(value: Float(value))
        case .int32:
            return NSNumber(value: pointer.advanced(by: index * 4).load(as: Int32.self))
        case .int8:
            return NSNumber(value: pointer.advanced(by: index).load(as: Int8.self))
        }
    }

    private func setNumber(_ number: NSNumber, atLinear index: Int) {
        let pointer = storage.pointer
        switch dataType {
        case .double:
            pointer.advanced(by: index * 8).storeBytes(of: number.doubleValue, as: Double.self)
        case .float32:
            pointer.advanced(by: index * 4).storeBytes(of: number.floatValue, as: Float.self)
        case .float16:
            pointer.advanced(by: index * 2).storeBytes(of: Float16(number.floatValue), as: Float16.self)
        case .int32:
            pointer.advanced(by: index * 4).storeBytes(of: number.int32Value, as: Int32.self)
        case .int8:
            pointer.advanced(by: index).storeBytes(of: Int8(truncatingIfNeeded: number.intValue), as: Int8.self)
        }
    }
}

extension UnsafeBufferPointer {
    public init(_ multiArray: MLMultiArray) throws {
        guard MemoryLayout<Element>.stride == multiArray.dataType.byteSize else {
            throw coreMLError(.featureType, "UnsafeBufferPointer element size does not match MLMultiArray data type.")
        }
        self.init(
            start: UnsafePointer<Element>(OpaquePointer(multiArray.dataPointer)),
            count: multiArray.count
        )
    }
}

extension UnsafeMutableBufferPointer {
    public init(_ multiArray: MLMultiArray) throws {
        guard MemoryLayout<Element>.stride == multiArray.dataType.byteSize else {
            throw coreMLError(.featureType, "UnsafeMutableBufferPointer element size does not match MLMultiArray data type.")
        }
        self.init(
            start: UnsafeMutablePointer<Element>(OpaquePointer(multiArray.dataPointer)),
            count: multiArray.count
        )
    }
}
