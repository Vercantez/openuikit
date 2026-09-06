import Foundation

private final class MLMultiArrayStorage {
    let pointer: UnsafeMutableRawPointer
    let byteCount: Int
    private let lock = NSLock()
    private var deallocated = false
    private let deallocator: (UnsafeMutableRawPointer) -> Void

    init(byteCount: Int) {
        let allocation = max(byteCount, 1)
        self.byteCount = byteCount
        self.pointer = UnsafeMutableRawPointer.allocate(
            byteCount: allocation,
            alignment: MemoryLayout<Double>.alignment
        )
        self.pointer.initializeMemory(as: UInt8.self, repeating: 0, count: allocation)
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
        invokeDeallocator()
    }

    func invokeDeallocator() {
        lock.lock()
        let shouldRun = !deallocated
        if shouldRun {
            deallocated = true
        }
        lock.unlock()
        if shouldRun {
            deallocator(pointer)
        }
    }
}

open class MLMultiArray: NSObject, NSSecureCoding, Foundation.NSCopying {
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
        let layout = try coreMLValidateMultiArrayLayout(shape: dims, strides: nil, dataType: dataType)
        self.storage = MLMultiArrayStorage(byteCount: layout.byteCount)
        self.shape = shape
        self.dataType = dataType
        self.strides = layout.strides.map { NSNumber(value: $0) }
        super.init()
    }

    public convenience init(shape: [Int], dataType: MLMultiArrayDataType, strides: [Int]) {
        let layout = try! coreMLValidateMultiArrayLayout(
            shape: shape,
            strides: strides,
            dataType: dataType
        )
        let allocation = max(layout.byteCount, 1)
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: allocation,
            alignment: MemoryLayout<Double>.alignment
        )
        pointer.initializeMemory(as: UInt8.self, repeating: 0, count: allocation)
        try! self.init(
            dataPointer: pointer,
            shape: shape.map { NSNumber(value: $0) },
            dataType: dataType,
            strides: strides.map { NSNumber(value: $0) },
            deallocator: { $0.deallocate() }
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
        let strideValues = strides.map(\.intValue)
        let layout = try coreMLValidateMultiArrayLayout(
            shape: dims,
            strides: strideValues,
            dataType: dataType
        )
        self.storage = MLMultiArrayStorage(
            pointer: dataPointer,
            byteCount: layout.byteCount,
            deallocator: deallocator
        )
        self.shape = shape
        self.dataType = dataType
        self.strides = strides
        super.init()
    }

    public convenience init(
        byConcatenatingMultiArrays multiArrays: [MLMultiArray],
        alongAxis axis: Int,
        dataType: MLMultiArrayDataType
    ) {
        precondition(!multiArrays.isEmpty, "concatenating empty MLMultiArray list")
        let first = multiArrays[0]
        let rank = first.shape.count
        precondition(rank > 0, "concatenating rank-0 MLMultiArray")
        var normalizedAxis = axis
        if normalizedAxis < 0 {
            normalizedAxis += rank
        }
        precondition(normalizedAxis >= 0 && normalizedAxis < rank, "MLMultiArray concat axis out of range")
        var dims = first.shape.map(\.intValue)
        var axisCount = 0
        for array in multiArrays {
            precondition(array.shape.count == rank, "MLMultiArray concat rank mismatch")
            let sourceDims = array.shape.map(\.intValue)
            for (index, dim) in sourceDims.enumerated() where index != normalizedAxis {
                precondition(dim == dims[index], "MLMultiArray concat shape mismatch")
            }
            guard let next = coreMLCheckedAdd(axisCount, sourceDims[normalizedAxis]) else {
                preconditionFailure("MLMultiArray concat axis overflows Int")
            }
            axisCount = next
        }
        dims[normalizedAxis] = axisCount
        try! self.init(shape: dims.map { NSNumber(value: $0) }, dataType: dataType)
        var axisOrigin = 0
        for array in multiArrays {
            let sourceAxis = array.shape[normalizedAxis].intValue
            let sourceCount = array.count
            for linear in 0..<sourceCount {
                var indices = coreMLUnravel(linear: linear, shape: array.shape.map(\.intValue))
                indices[normalizedAxis] += axisOrigin
                self.setNumber(array.number(atLinear: linear), atIndices: indices)
            }
            axisOrigin += sourceAxis
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
        shapedArray.withUnsafeShapedBufferPointer { buffer, shape, _ in
            guard let base = buffer.baseAddress else { return }
            for linear in 0..<buffer.count {
                let indices = coreMLUnravel(linear: linear, shape: shape)
                let value = base[linear]
                self.setNumber(Self.number(fromScalar: value), atIndices: indices)
            }
        }
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func encode(with coder: NSCoder) {}

    open func copy(with zone: NSZone?) -> Any {
        _ = zone
        let copied = try! MLMultiArray(shape: shape, dataType: dataType)
        transfer(to: copied)
        return copied
    }

    public convenience init(data: Data, shape: [NSNumber], dataType: MLMultiArrayDataType) throws {
        try self.init(shape: shape, dataType: dataType)
        let layout = try coreMLValidateMultiArrayLayout(
            shape: shape.map(\.intValue),
            strides: nil,
            dataType: dataType
        )
        let byteCount = min(data.count, layout.byteCount)
        data.withUnsafeBytes { buffer in
            if let base = buffer.baseAddress {
                storage.pointer.copyMemory(from: base, byteCount: byteCount)
            }
        }
    }

    public var data: Data {
        withUnsafeBytes { Data($0.prefix(max(storage.byteCount, 0))) }
    }

    public func transposed() throws -> MLMultiArray {
        guard shape.count >= 2 else { return copy() as! MLMultiArray }
        let dims = shape.map(\.intValue)
        let newShape = Array(dims.reversed())
        let result = try MLMultiArray(shape: newShape.map { NSNumber(value: $0) }, dataType: dataType)
        for linear in 0..<count {
            let indices = coreMLUnravel(linear: linear, shape: dims)
            result.setNumber(number(atLinear: linear), atIndices: Array(indices.reversed()))
        }
        return result
    }

    public subscript(idx: Int) -> NSNumber {
        get {
            precondition(idx >= 0 && idx < count, "MLMultiArray linear index out of range")
            return number(atLinear: idx)
        }
        set {
            precondition(idx >= 0 && idx < count, "MLMultiArray linear index out of range")
            setNumber(newValue, atLinear: idx)
        }
    }

    public subscript(key: [NSNumber]) -> NSNumber {
        get {
            let indices = key.map(\.intValue)
            precondition(isValidIndices(indices), "MLMultiArray indices out of range")
            return number(atIndices: indices)
        }
        set {
            let indices = key.map(\.intValue)
            precondition(isValidIndices(indices), "MLMultiArray indices out of range")
            setNumber(newValue, atIndices: indices)
        }
    }

    public func transfer(to destinationMultiArray: MLMultiArray) {
        let sourceShape = shape.map(\.intValue)
        let destinationShape = destinationMultiArray.shape.map(\.intValue)
        precondition(sourceShape == destinationShape, "MLMultiArray transfer requires identical shapes")
        for linear in 0..<count {
            let indices = coreMLUnravel(linear: linear, shape: sourceShape)
            destinationMultiArray.setNumber(number(atIndices: indices), atIndices: indices)
        }
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try body(UnsafeRawBufferPointer(start: storage.pointer, count: max(storage.byteCount, 0)))
    }

    public func withUnsafeMutableBytes<R>(
        _ body: (UnsafeMutableRawBufferPointer, [Int]) throws -> R
    ) rethrows -> R {
        try body(
            UnsafeMutableRawBufferPointer(start: storage.pointer, count: max(storage.byteCount, 0)),
            strides.map(\.intValue)
        )
    }

    public func withUnsafeBufferPointer<S, R>(
        ofType type: S.Type,
        _ body: (UnsafeBufferPointer<S>) throws -> R
    ) rethrows -> R where S: MLShapedArrayScalar {
        precondition(S.multiArrayDataType == dataType)
        let typed = UnsafePointer<S>(OpaquePointer(storage.pointer))
        let capacity = storage.byteCount / max(MemoryLayout<S>.stride, 1)
        return try body(UnsafeBufferPointer(start: typed, count: capacity))
    }

    public func withUnsafeMutableBufferPointer<S, R>(
        ofType type: S.Type,
        _ body: (UnsafeMutableBufferPointer<S>, [Int]) throws -> R
    ) rethrows -> R where S: MLShapedArrayScalar {
        precondition(S.multiArrayDataType == dataType)
        let typed = UnsafeMutablePointer<S>(OpaquePointer(storage.pointer))
        let capacity = storage.byteCount / max(MemoryLayout<S>.stride, 1)
        return try body(
            UnsafeMutableBufferPointer(start: typed, count: capacity),
            strides.map(\.intValue)
        )
    }

    private func isValidIndices(_ indices: [Int]) -> Bool {
        let dims = shape.map(\.intValue)
        guard indices.count == dims.count else { return false }
        for (index, dimension) in zip(indices, dims) {
            if dimension == 0 { return false }
            if index < 0 || index >= dimension { return false }
        }
        return true
    }

    private func linearOffset(_ indices: [Int]) -> Int {
        zip(indices, strides.map(\.intValue)).reduce(0) { $0 + $1.0 * $1.1 }
    }

    fileprivate func number(atLinear linear: Int) -> NSNumber {
        number(atIndices: coreMLUnravel(linear: linear, shape: shape.map(\.intValue)))
    }

    fileprivate func setNumber(_ number: NSNumber, atLinear linear: Int) {
        setNumber(number, atIndices: coreMLUnravel(linear: linear, shape: shape.map(\.intValue)))
    }

    fileprivate func number(atIndices indices: [Int]) -> NSNumber {
        number(atOffset: linearOffset(indices))
    }

    fileprivate func setNumber(_ number: NSNumber, atIndices indices: [Int]) {
        storeNumber(number, atOffset: linearOffset(indices))
    }

    private func number(atOffset offset: Int) -> NSNumber {
        let pointer = storage.pointer
        switch dataType {
        case .double:
            return NSNumber(value: pointer.advanced(by: offset * 8).load(as: Double.self))
        case .float32:
            return NSNumber(value: pointer.advanced(by: offset * 4).load(as: Float.self))
        case .float16:
            let value = pointer.advanced(by: offset * 2).load(as: Float16.self)
            return NSNumber(value: Float(value))
        case .int32:
            return NSNumber(value: pointer.advanced(by: offset * 4).load(as: Int32.self))
        case .int8:
            return NSNumber(value: pointer.advanced(by: offset).load(as: Int8.self))
        }
    }

    private func storeNumber(_ number: NSNumber, atOffset offset: Int) {
        let pointer = storage.pointer
        switch dataType {
        case .double:
            pointer.advanced(by: offset * 8).storeBytes(of: number.doubleValue, as: Double.self)
        case .float32:
            pointer.advanced(by: offset * 4).storeBytes(of: number.floatValue, as: Float.self)
        case .float16:
            pointer.advanced(by: offset * 2).storeBytes(of: Float16(number.floatValue), as: Float16.self)
        case .int32:
            pointer.advanced(by: offset * 4).storeBytes(of: number.int32Value, as: Int32.self)
        case .int8:
            pointer.advanced(by: offset).storeBytes(
                of: Int8(truncatingIfNeeded: number.intValue),
                as: Int8.self
            )
        }
    }

    private static func number<Scalar>(fromScalar value: Scalar) -> NSNumber {
        switch value {
        case let double as Double:
            return NSNumber(value: double)
        case let float as Float:
            return NSNumber(value: float)
        case let float16 as Float16:
            return NSNumber(value: Float(float16))
        case let int32 as Int32:
            return NSNumber(value: int32)
        case let int8 as Int8:
            return NSNumber(value: int8)
        default:
            return NSNumber(value: 0)
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
