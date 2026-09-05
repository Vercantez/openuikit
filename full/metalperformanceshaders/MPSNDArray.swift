import Foundation

public protocol MPSNDArrayAllocator: NSObjectProtocol, NSSecureCoding {
    func array(
        for cmdBuf: any MTLCommandBuffer,
        arrayDescriptor descriptor: MPSNDArrayDescriptor,
        kernel: MPSKernel
    ) -> MPSNDArray
}

public final class MPSNDArrayDefaultAllocator: NSObject, MPSNDArrayAllocator {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func array(
        for cmdBuf: any MTLCommandBuffer,
        arrayDescriptor descriptor: MPSNDArrayDescriptor,
        kernel: MPSKernel
    ) -> MPSNDArray {
        _ = cmdBuf
        return MPSNDArray(device: kernel.device, descriptor: descriptor)
    }
}

open class MPSNDArrayDescriptor: NSObject {
    public var dataType: MPSDataType
    public var preferPackedRows: Bool = false
    private var lengths: [Int]
    private var slices: [MPSDimensionSlice]
    private var order: [UInt8]

    public var numberOfDimensions: Int {
        get { lengths.count }
        set {
            let count = max(newValue, 0)
            if count > lengths.count {
                lengths.append(contentsOf: Array(repeating: 1, count: count - lengths.count))
                slices.append(contentsOf: (slices.count..<count).map { _ in MPSDimensionSlice(start: 0, length: 1) })
                order.append(contentsOf: (order.count..<count).map { UInt8($0) })
            } else if count < lengths.count {
                lengths = Array(lengths.prefix(count))
                slices = Array(slices.prefix(count))
                order = Array(order.prefix(count))
            }
        }
    }

    public convenience init(
        dataType: MPSDataType,
        dimensionCount numberOfDimensions: Int,
        dimensionSizes: UnsafeMutablePointer<Int>
    ) {
        let count = max(numberOfDimensions, 0)
        let sizes = (0..<count).map { max(dimensionSizes[$0], 0) }
        self.init(dataType: dataType, sizes: sizes)
    }

    public convenience init(dataType: MPSDataType, shape: [NSNumber]) {
        self.init(dataType: dataType, sizes: shape.map { max($0.intValue, 0) })
    }

    public init(dataType: MPSDataType, sizes: [Int]) {
        self.dataType = dataType
        self.lengths = sizes.isEmpty ? [1] : sizes.map { max($0, 0) }
        self.slices = self.lengths.map { MPSDimensionSlice(start: 0, length: $0) }
        self.order = (0..<self.lengths.count).map { UInt8($0) }
        super.init()
    }

    public func length(ofDimension dimensionIndex: Int) -> Int {
        guard lengths.indices.contains(dimensionIndex) else { return 0 }
        return lengths[dimensionIndex]
    }

    public func sliceRange(forDimension dimensionIndex: Int) -> MPSDimensionSlice {
        guard slices.indices.contains(dimensionIndex) else {
            return MPSDimensionSlice()
        }
        return slices[dimensionIndex]
    }

    public func sliceDimension(_ dimensionIndex: Int, withSubrange subRange: MPSDimensionSlice) {
        guard slices.indices.contains(dimensionIndex) else { return }
        let dimLength = lengths[dimensionIndex]
        let start = min(max(subRange.start, 0), dimLength)
        let length = min(max(subRange.length, 0), dimLength - start)
        slices[dimensionIndex] = MPSDimensionSlice(start: start, length: length)
    }

    public func transposeDimension(_ dimensionIndex: Int, withDimension dimensionIndex2: Int) {
        guard lengths.indices.contains(dimensionIndex), lengths.indices.contains(dimensionIndex2) else {
            return
        }
        lengths.swapAt(dimensionIndex, dimensionIndex2)
        slices.swapAt(dimensionIndex, dimensionIndex2)
        order.swapAt(dimensionIndex, dimensionIndex2)
    }

    public func reshape(withDimensionCount numberOfDimensions: Int, dimensionSizes: UnsafeMutablePointer<Int>) {
        let count = max(numberOfDimensions, 0)
        lengths = (0..<count).map { max(dimensionSizes[$0], 0) }
        slices = lengths.map { MPSDimensionSlice(start: 0, length: $0) }
        order = (0..<count).map { UInt8($0) }
    }

    public func reshape(withShape shape: [NSNumber]) {
        lengths = shape.map { max($0.intValue, 0) }
        if lengths.isEmpty { lengths = [1] }
        slices = lengths.map { MPSDimensionSlice(start: 0, length: $0) }
        order = (0..<lengths.count).map { UInt8($0) }
    }

    public func permute(withDimensionOrder dimensionOrder: UnsafeMutablePointer<Int>) {
        let count = lengths.count
        var nextLengths = Array(repeating: 0, count: count)
        var nextSlices = Array(repeating: MPSDimensionSlice(), count: count)
        var nextOrder = Array(repeating: UInt8(0), count: count)
        for index in 0..<count {
            let source = dimensionOrder[index]
            guard lengths.indices.contains(source) else { return }
            nextLengths[index] = lengths[source]
            nextSlices[index] = slices[source]
            nextOrder[index] = UInt8(source)
        }
        lengths = nextLengths
        slices = nextSlices
        order = nextOrder
    }

    public func dimensionOrder() -> vector_uchar16 {
        var vector = vector_uchar16.zero
        for index in 0..<min(order.count, 16) {
            vector[index] = order[index]
        }
        return vector
    }

    public func getShape() -> [NSNumber] {
        lengths.map { NSNumber(value: $0) }
    }

    public func elementCount() -> Int {
        slices.reduce(1) { $0 * max($1.length, 1) }
    }

    public func copyDescriptor() -> MPSNDArrayDescriptor {
        let copy = MPSNDArrayDescriptor(dataType: dataType, sizes: lengths)
        copy.preferPackedRows = preferPackedRows
        copy.slices = slices
        copy.order = order
        return copy
    }
}

open class MPSNDArray: NSObject {
    public private(set) var device: any MTLDevice
    public private(set) var dataType: MPSDataType
    public private(set) var numberOfDimensions: Int
    public var label: String?
    public private(set) var parent: MPSNDArray?
    public var dataTypeSize: Int { max(MPSSizeofMPSDataType(dataType), 1) }

    private var lengths: [Int]
    private var hostStorage: Data
    private var ownedBuffer: (any MTLBuffer)?

    public class func defaultAllocator() -> any MPSNDArrayAllocator {
        MPSNDArrayDefaultAllocator()
    }

    public init(device: any MTLDevice, descriptor: MPSNDArrayDescriptor) {
        self.device = device
        self.dataType = descriptor.dataType
        self.numberOfDimensions = descriptor.numberOfDimensions
        self.lengths = (0..<descriptor.numberOfDimensions).map { descriptor.length(ofDimension: $0) }
        self.parent = nil
        let bytes = descriptor.elementCount() * max(MPSSizeofMPSDataType(descriptor.dataType), 1)
        self.hostStorage = Data(count: max(bytes, 0))
        super.init()
    }

    public convenience init(device: any MTLDevice, scalar value: Double) {
        let sizes = [1]
        self.init(
            device: device,
            descriptor: MPSNDArrayDescriptor(dataType: .float32, sizes: sizes)
        )
        _ = sizes
        hostStorage.withUnsafeMutableBytes { buffer in
            buffer.storeBytes(of: Float(value), as: Float.self)
        }
    }

    public convenience init(buffer: any MTLBuffer, offset: Int, descriptor: MPSNDArrayDescriptor) {
        self.init(device: buffer.device, descriptor: descriptor)
        ownedBuffer = buffer
        let length = min(max(buffer.length - offset, 0), hostStorage.count)
        if length > 0 {
            hostStorage.replaceSubrange(
                0..<length,
                with: UnsafeRawBufferPointer(start: buffer.contents.advanced(by: offset), count: length)
            )
        }
    }

    public func length(ofDimension dimensionIndex: Int) -> Int {
        guard lengths.indices.contains(dimensionIndex) else { return 0 }
        return lengths[dimensionIndex]
    }

    public func descriptor() -> MPSNDArrayDescriptor {
        MPSNDArrayDescriptor(dataType: dataType, sizes: lengths)
    }

    public func resourceSize() -> Int {
        hostStorage.count
    }

    public func userBuffer() -> (any MTLBuffer)? {
        ownedBuffer
    }

    public func synchronize(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }

    public func arrayView(with descriptor: MPSNDArrayDescriptor) -> MPSNDArray? {
        let view = MPSNDArray(device: device, descriptor: descriptor)
        view.parent = self
        let count = min(view.hostStorage.count, hostStorage.count)
        if count > 0 {
            view.hostStorage.replaceSubrange(0..<count, with: hostStorage.prefix(count))
        }
        return view
    }

    public func arrayView(
        with cmdBuf: any MTLCommandBuffer,
        descriptor: MPSNDArrayDescriptor,
        aliasing: MPSAliasingStrategy
    ) -> MPSNDArray? {
        _ = (cmdBuf, aliasing)
        return arrayView(with: descriptor)
    }

    public func arrayView(withShape shape: [NSNumber]?, strides: [NSNumber]) -> MPSNDArray? {
        _ = strides
        let descriptor = MPSNDArrayDescriptor(
            dataType: dataType,
            shape: shape ?? lengths.map { NSNumber(value: $0) }
        )
        return arrayView(with: descriptor)
    }

    public func arrayView(
        withDimensionCount numberOfDimensions: Int,
        dimensionSizes: UnsafePointer<Int>,
        strides dimStrides: UnsafePointer<Int>
    ) -> MPSNDArray? {
        _ = dimStrides
        let sizes = (0..<max(numberOfDimensions, 0)).map { max(dimensionSizes[$0], 0) }
        let descriptor = MPSNDArrayDescriptor(dataType: dataType, sizes: sizes)
        _ = sizes
        return arrayView(with: descriptor)
    }

    public func readBytes(_ buffer: UnsafeMutableRawPointer, strideBytes strideBytesPerDimension: UnsafeMutablePointer<Int>?) {
        _ = strideBytesPerDimension
        hostStorage.withUnsafeBytes { storage in
            guard let base = storage.baseAddress else { return }
            buffer.copyMemory(from: base, byteCount: storage.count)
        }
    }

    public func writeBytes(_ buffer: UnsafeMutableRawPointer, strideBytes strideBytesPerDimension: UnsafeMutablePointer<Int>?) {
        _ = strideBytesPerDimension
        hostStorage.withUnsafeMutableBytes { storage in
            guard let base = storage.baseAddress else { return }
            base.copyMemory(from: UnsafeRawPointer(buffer), byteCount: storage.count)
        }
    }

    public func exportData(
        with cmdBuf: any MTLCommandBuffer,
        to buffer: any MTLBuffer,
        destinationDataType: MPSDataType,
        offset: Int,
        rowStrides: UnsafeMutablePointer<Int>?
    ) {
        _ = (cmdBuf, destinationDataType, rowStrides)
        let length = min(max(buffer.length - offset, 0), hostStorage.count)
        if length > 0 {
            hostStorage.withUnsafeBytes { storage in
                guard let base = storage.baseAddress else { return }
                buffer.contents.advanced(by: offset).copyMemory(from: base, byteCount: length)
            }
        }
    }

    public func importData(
        with cmdBuf: any MTLCommandBuffer,
        from buffer: any MTLBuffer,
        sourceDataType: MPSDataType,
        offset: Int,
        rowStrides: UnsafeMutablePointer<Int>?
    ) {
        _ = (cmdBuf, sourceDataType, rowStrides)
        let length = min(max(buffer.length - offset, 0), hostStorage.count)
        if length > 0 {
            hostStorage.replaceSubrange(
                0..<length,
                with: UnsafeRawBufferPointer(start: buffer.contents.advanced(by: offset), count: length)
            )
        }
    }

    public func exportData(
        with cmdBuf: any MTLCommandBuffer,
        to images: [MPSImage],
        offset: MPSImageCoordinate
    ) {
        _ = (cmdBuf, images, offset)
        MPSHostBoundary.refuseGPUEncode("MPSNDArray.exportData(to:images:)")
    }

    public func importData(
        with cmdBuf: any MTLCommandBuffer,
        from images: [MPSImage],
        offset: MPSImageCoordinate
    ) {
        _ = (cmdBuf, images, offset)
        MPSHostBoundary.refuseGPUEncode("MPSNDArray.importData(from:images:)")
    }
}

open class MPSTemporaryNDArray: MPSNDArray {
    public var readCount: Int = 1

    public convenience init(commandBuffer: any MTLCommandBuffer, descriptor: MPSNDArrayDescriptor) {
        self.init(device: commandBuffer.device, descriptor: descriptor)
        readCount = 1
    }

    public override class func defaultAllocator() -> any MPSNDArrayAllocator {
        MPSNDArrayDefaultAllocator()
    }
}
