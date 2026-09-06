import Foundation
#if canImport(Glibc)
import Glibc
#endif

open class MLCDevice: NSObject {
    public let type: MLCDeviceType
    public let actualDeviceType: MLCDeviceType

    public required init(linuxType: MLCDeviceType, actualDeviceType: MLCDeviceType) {
        self.type = linuxType
        self.actualDeviceType = actualDeviceType
        super.init()
    }

    public class func cpu() -> Self {
        Self(linuxType: .cpu, actualDeviceType: .cpu)
    }

    public class func gpu() -> Self? {
        nil
    }

    public class func ane() -> Self? {
        nil
    }

    public convenience init?(type: MLCDeviceType) {
        self.init(type: type, selectsMultipleComputeDevices: false)
    }

    public convenience init?(type: MLCDeviceType, selectsMultipleComputeDevices: Bool) {
        _ = selectsMultipleComputeDevices
        switch type {
        case .cpu:
            self.init(linuxType: .cpu, actualDeviceType: .cpu)
        case .any:
            self.init(linuxType: .any, actualDeviceType: .cpu)
        case .gpu, .ane:
            return nil
        }
    }
}

open class MLCPlatform: NSObject {
    private static let lock = NSLock()
    private static var seed: NSNumber?
    private static var rngState: UInt64 = 0x9E3779B97F4A7C15

    public class func getRNGseed() -> NSNumber? {
        lock.lock()
        defer { lock.unlock() }
        return seed
    }

    public class func setRNGSeedTo(_ seed: NSNumber) {
        lock.lock()
        defer { lock.unlock() }
        self.seed = seed
        rngState = seed.uint64Value == 0 ? 0x9E3779B97F4A7C15 : seed.uint64Value
    }

    static func nextUniform() -> Float {
        lock.lock()
        defer { lock.unlock() }
        rngState = rngState &* 6364136223846793005 &+ 1
        let bits = UInt32(truncatingIfNeeded: rngState >> 33)
        return Float(bits) / Float(UInt32.max)
    }
}

open class MLCTensorData: NSObject {
    public let bytes: UnsafeMutableRawPointer
    public let length: Int
    private let owned: Bool
    private let deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?

    public convenience init(bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int) {
        self.init(pointer: bytes, length: length, owned: false, deallocator: nil)
    }

    public convenience init(
        bytesNoCopy bytes: UnsafeMutableRawPointer,
        length: Int,
        deallocator: @escaping (UnsafeMutableRawPointer, Int) -> Void
    ) {
        self.init(pointer: bytes, length: length, owned: false, deallocator: deallocator)
    }

    public convenience init(immutableBytesNoCopy bytes: UnsafeRawPointer, length: Int) {
        self.init(pointer: UnsafeMutableRawPointer(mutating: bytes), length: length, owned: false, deallocator: nil)
    }

    public convenience init(linuxCopying data: Data) {
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: max(data.count, 1), alignment: 16)
        data.copyBytes(to: pointer.assumingMemoryBound(to: UInt8.self), count: data.count)
        self.init(pointer: pointer, length: data.count, owned: true, deallocator: nil)
    }

    init(
        pointer: UnsafeMutableRawPointer,
        length: Int,
        owned: Bool,
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?
    ) {
        self.bytes = pointer
        self.length = length
        self.owned = owned
        self.deallocator = deallocator
        super.init()
    }

    deinit {
        if let deallocator {
            deallocator(bytes, length)
        } else if owned {
            bytes.deallocate()
        }
    }

    public func linuxData() -> Data {
        Data(bytes: bytes, count: length)
    }
}

open class MLCTensorDescriptor: NSObject, NSCopying {
    public static var maxTensorDimensions: Int { 5 }

    public let shape: [Int]
    public let stride: [Int]
    public let dataType: MLCDataType
    public let sequenceLengths: [Int]?
    public let sortedSequences: Bool
    public let batchSizePerSequenceStep: [Int]?

    public var dimensionCount: Int { shape.count }

    public var tensorAllocationSizeInBytes: Int {
        let volume = max(mlcShapeVolume(shape), 0)
        return volume * mlcElementSize(dataType)
    }

    public convenience init?(shape: [Int], dataType: MLCDataType) {
        self.init(
            shape: shape,
            dataType: dataType,
            sequenceLengths: nil,
            sortedSequences: false,
            batchSizePerSequenceStep: nil
        )
    }

    public convenience init?(
        shape: [Int],
        sequenceLengths: [Int],
        sortedSequences: Bool,
        dataType: MLCDataType
    ) {
        guard !sequenceLengths.isEmpty, sequenceLengths.count <= shape.first ?? 0 || true else { return nil }
        self.init(
            shape: shape,
            dataType: dataType,
            sequenceLengths: sequenceLengths,
            sortedSequences: sortedSequences,
            batchSizePerSequenceStep: nil
        )
    }

    public convenience init?(
        width: Int,
        height: Int,
        featureChannelCount featureChannels: Int,
        batchSize: Int
    ) {
        self.init(
            width: width,
            height: height,
            featureChannelCount: featureChannels,
            batchSize: batchSize,
            dataType: .float32
        )
    }

    public convenience init?(
        width: Int,
        height: Int,
        featureChannelCount: Int,
        batchSize: Int,
        dataType: MLCDataType
    ) {
        self.init(shape: [batchSize, featureChannelCount, height, width], dataType: dataType)
    }

    public convenience init?(
        convolutionWeightsWithWidth width: Int,
        height: Int,
        inputFeatureChannelCount: Int,
        outputFeatureChannelCount: Int,
        dataType: MLCDataType
    ) {
        self.init(
            shape: [outputFeatureChannelCount, inputFeatureChannelCount, height, width],
            dataType: dataType
        )
    }

    public convenience init?(
        convolutionWeightsWithInputFeatureChannelCount inputFeatureChannelCount: Int,
        outputFeatureChannelCount: Int,
        dataType: MLCDataType
    ) {
        self.init(
            shape: [outputFeatureChannelCount, inputFeatureChannelCount],
            dataType: dataType
        )
    }

    public convenience init?(
        convolutionBiasesWithFeatureChannelCount featureChannelCount: Int,
        dataType: MLCDataType
    ) {
        self.init(shape: [featureChannelCount], dataType: dataType)
    }

    init?(
        shape: [Int],
        dataType: MLCDataType,
        sequenceLengths: [Int]?,
        sortedSequences: Bool,
        batchSizePerSequenceStep: [Int]?
    ) {
        guard !shape.isEmpty,
              shape.count <= MLCTensorDescriptor.maxTensorDimensions,
              shape.allSatisfy({ $0 >= 0 })
        else { return nil }
        self.shape = shape
        self.stride = mlcContiguousStride(shape: shape)
        self.dataType = dataType
        self.sequenceLengths = sequenceLengths
        self.sortedSequences = sortedSequences
        self.batchSizePerSequenceStep = batchSizePerSequenceStep
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MLCTensorDescriptor(
            shape: shape,
            dataType: dataType,
            sequenceLengths: sequenceLengths,
            sortedSequences: sortedSequences,
            batchSizePerSequenceStep: batchSizePerSequenceStep
        )!
    }
}

open class MLCTensorOptimizerDeviceData: NSObject {}

open class MLCTensorParameter: NSObject {
    public let tensor: MLCTensor
    public var isUpdatable: Bool

    public convenience init(tensor: MLCTensor) {
        self.init(tensor: tensor, optimizerData: nil)
    }

    public init(tensor: MLCTensor, optimizerData: [MLCTensorData]?) {
        self.tensor = tensor
        self.isUpdatable = true
        super.init()
        if let optimizerData {
            _ = tensor.bindOptimizerData(optimizerData, deviceData: nil)
        }
    }
}

open class MLCTensor: NSObject {
    public let tensorID: Int
    public let descriptor: MLCTensorDescriptor
    public var label: String
    public private(set) var device: MLCDevice?
    public private(set) var optimizerData: [MLCTensorData]
    public private(set) var optimizerDeviceData: [MLCTensorOptimizerDeviceData]
    private var storage: Data

    public var data: Data? { storage }

    public var hasValidNumerics: Bool {
        guard descriptor.dataType == .float32 else { return true }
        return linuxHostFloats()?.allSatisfy { $0.isFinite } ?? true
    }

    public convenience init(descriptor tensorDescriptor: MLCTensorDescriptor) {
        self.init(descriptor: tensorDescriptor, storage: Data(count: tensorDescriptor.tensorAllocationSizeInBytes))
    }

    public convenience init(descriptor tensorDescriptor: MLCTensorDescriptor, data: MLCTensorData) {
        var storage = Data(count: tensorDescriptor.tensorAllocationSizeInBytes)
        let copyCount = min(storage.count, data.length)
        storage.withUnsafeMutableBytes { dest in
            if let base = dest.baseAddress {
                memcpy(base, data.bytes, copyCount)
            }
        }
        self.init(descriptor: tensorDescriptor, storage: storage)
    }

    public convenience init(descriptor tensorDescriptor: MLCTensorDescriptor, fillWithData fillData: NSNumber) {
        self.init(descriptor: tensorDescriptor)
        linuxFill(fillData.floatValue)
    }

    public convenience init(
        descriptor tensorDescriptor: MLCTensorDescriptor,
        randomInitializerType: MLCRandomInitializerType
    ) {
        self.init(descriptor: tensorDescriptor)
        linuxRandomFill(randomInitializerType)
    }

    public convenience init(shape: [Int]) {
        self.init(shape: shape, dataType: .float32)
    }

    public convenience init(shape: [Int], dataType: MLCDataType) {
        let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType)!
        self.init(descriptor: descriptor)
    }

    public convenience init(shape: [Int], data: MLCTensorData, dataType: MLCDataType) {
        let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType)!
        self.init(descriptor: descriptor, data: data)
    }

    public convenience init(shape: [Int], fillWithData fillData: NSNumber, dataType: MLCDataType) {
        let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType)!
        self.init(descriptor: descriptor, fillWithData: fillData)
    }

    public convenience init(shape: [Int], randomInitializerType: MLCRandomInitializerType) {
        let descriptor = MLCTensorDescriptor(shape: shape, dataType: .float32)!
        self.init(descriptor: descriptor, randomInitializerType: randomInitializerType)
    }

    public convenience init(width: Int, height: Int, featureChannelCount: Int, batchSize: Int) {
        let descriptor = MLCTensorDescriptor(
            width: width,
            height: height,
            featureChannelCount: featureChannelCount,
            batchSize: batchSize
        )!
        self.init(descriptor: descriptor)
    }

    public convenience init(
        width: Int,
        height: Int,
        featureChannelCount: Int,
        batchSize: Int,
        data: MLCTensorData
    ) {
        let descriptor = MLCTensorDescriptor(
            width: width,
            height: height,
            featureChannelCount: featureChannelCount,
            batchSize: batchSize
        )!
        self.init(descriptor: descriptor, data: data)
    }

    public convenience init(
        width: Int,
        height: Int,
        featureChannelCount: Int,
        batchSize: Int,
        data: MLCTensorData,
        dataType: MLCDataType
    ) {
        let descriptor = MLCTensorDescriptor(
            width: width,
            height: height,
            featureChannelCount: featureChannelCount,
            batchSize: batchSize,
            dataType: dataType
        )!
        self.init(descriptor: descriptor, data: data)
    }

    public convenience init(
        width: Int,
        height: Int,
        featureChannelCount: Int,
        batchSize: Int,
        fillWithData fillData: Float,
        dataType: MLCDataType
    ) {
        let descriptor = MLCTensorDescriptor(
            width: width,
            height: height,
            featureChannelCount: featureChannelCount,
            batchSize: batchSize,
            dataType: dataType
        )!
        self.init(descriptor: descriptor, fillWithData: NSNumber(value: fillData))
    }

    public convenience init(
        width: Int,
        height: Int,
        featureChannelCount: Int,
        batchSize: Int,
        randomInitializerType: MLCRandomInitializerType
    ) {
        let descriptor = MLCTensorDescriptor(
            width: width,
            height: height,
            featureChannelCount: featureChannelCount,
            batchSize: batchSize
        )!
        self.init(descriptor: descriptor, randomInitializerType: randomInitializerType)
    }

    public convenience init(sequenceLength: Int, featureChannelCount: Int, batchSize: Int) {
        let descriptor = MLCTensorDescriptor(
            shape: [sequenceLength, batchSize, featureChannelCount],
            dataType: .float32
        )!
        self.init(descriptor: descriptor)
    }

    public convenience init(
        sequenceLength: Int,
        featureChannelCount: Int,
        batchSize: Int,
        data: MLCTensorData?
    ) {
        let descriptor = MLCTensorDescriptor(
            shape: [sequenceLength, batchSize, featureChannelCount],
            dataType: .float32
        )!
        if let data {
            self.init(descriptor: descriptor, data: data)
        } else {
            self.init(descriptor: descriptor)
        }
    }

    public convenience init(
        sequenceLength: Int,
        featureChannelCount: Int,
        batchSize: Int,
        randomInitializerType: MLCRandomInitializerType
    ) {
        let descriptor = MLCTensorDescriptor(
            shape: [sequenceLength, batchSize, featureChannelCount],
            dataType: .float32
        )!
        self.init(descriptor: descriptor, randomInitializerType: randomInitializerType)
    }

    public convenience init?(
        sequenceLengths: [Int],
        sortedSequences: Bool,
        featureChannelCount: Int,
        batchSize: Int,
        data: MLCTensorData? = nil
    ) {
        guard let maxLength = sequenceLengths.max(), maxLength > 0 else { return nil }
        guard let descriptor = MLCTensorDescriptor(
            shape: [maxLength, batchSize, featureChannelCount],
            sequenceLengths: sequenceLengths,
            sortedSequences: sortedSequences,
            dataType: .float32
        ) else { return nil }
        if let data {
            self.init(descriptor: descriptor, data: data)
        } else {
            self.init(descriptor: descriptor)
        }
    }

    public convenience init?(
        sequenceLengths: [Int],
        sortedSequences: Bool,
        featureChannelCount: Int,
        batchSize: Int,
        randomInitializerType: MLCRandomInitializerType
    ) {
        guard let maxLength = sequenceLengths.max(), maxLength > 0 else { return nil }
        guard let descriptor = MLCTensorDescriptor(
            shape: [maxLength, batchSize, featureChannelCount],
            sequenceLengths: sequenceLengths,
            sortedSequences: sortedSequences,
            dataType: .float32
        ) else { return nil }
        self.init(descriptor: descriptor, randomInitializerType: randomInitializerType)
    }

    init(descriptor: MLCTensorDescriptor, storage: Data) {
        self.tensorID = MLCHostCounters.nextTensorID()
        self.descriptor = descriptor
        self.label = ""
        self.device = nil
        self.optimizerData = []
        self.optimizerDeviceData = []
        self.storage = storage
        super.init()
    }

    public func bindAndWriteData(_ data: MLCTensorData, to device: MLCDevice) -> Bool {
        guard device.actualDeviceType == .cpu else { return false }
        let copyCount = min(storage.count, data.length)
        storage.withUnsafeMutableBytes { dest in
            if let base = dest.baseAddress {
                memcpy(base, data.bytes, copyCount)
            }
        }
        self.device = device
        return true
    }

    public func bindOptimizerData(_ data: [MLCTensorData], deviceData: [MLCTensorOptimizerDeviceData]?) -> Bool {
        optimizerData = data
        optimizerDeviceData = deviceData ?? []
        return true
    }

    public func copyDataFromDeviceMemory(
        toBytes bytes: UnsafeMutableRawPointer,
        length: Int,
        synchronizeWithDevice: Bool
    ) -> Bool {
        _ = synchronizeWithDevice
        let copyCount = min(storage.count, length)
        storage.withUnsafeBytes { src in
            if let base = src.baseAddress {
                memcpy(bytes, base, copyCount)
            }
        }
        return copyCount > 0 || length == 0
    }

    public func synchronizeData() -> Bool {
        true
    }

    public func synchronizeOptimizerData() -> Bool {
        true
    }

    public func quantized(to type: MLCDataType, scale: Float, bias: Int) -> MLCTensor? {
        guard descriptor.dataType == .float32, type == .int8 || type == .uint8 else { return nil }
        guard let values = linuxHostFloats() else { return nil }
        guard let outDescriptor = MLCTensorDescriptor(shape: descriptor.shape, dataType: type) else { return nil }
        var output = Data(count: outDescriptor.tensorAllocationSizeInBytes)
        output.withUnsafeMutableBytes { dest in
            guard let base = dest.baseAddress else { return }
            for (index, value) in values.enumerated() {
                let q = Int((value / scale).rounded()) + bias
                if type == .int8 {
                    let clamped = Int8(clamping: q)
                    base.storeBytes(of: clamped, toByteOffset: index, as: Int8.self)
                } else {
                    let clamped = UInt8(clamping: q)
                    base.storeBytes(of: clamped, toByteOffset: index, as: UInt8.self)
                }
            }
        }
        return MLCTensor(descriptor: outDescriptor, storage: output)
    }

    public func quantized(to type: MLCDataType, scale: MLCTensor, bias: MLCTensor, axis: Int) -> MLCTensor? {
        _ = axis
        guard let scaleValue = scale.linuxHostFloats()?.first, let biasValue = bias.linuxHostFloats()?.first else {
            return nil
        }
        return quantized(to: type, scale: scaleValue, bias: Int(biasValue.rounded()))
    }

    public func dequantized(to type: MLCDataType, scale: MLCTensor, zeroPoint bias: MLCTensor) -> MLCTensor? {
        dequantized(to: type, scale: scale, bias: bias, axis: 0)
    }

    public func dequantized(to type: MLCDataType, scale: MLCTensor, bias: MLCTensor, axis: Int) -> MLCTensor? {
        _ = axis
        guard type == .float32 else { return nil }
        guard let scaleValue = scale.linuxHostFloats()?.first else { return nil }
        guard let zero = bias.linuxHostFloats()?.first else { return nil }
        guard let outDescriptor = MLCTensorDescriptor(shape: descriptor.shape, dataType: .float32) else { return nil }
        let count = mlcShapeVolume(descriptor.shape)
        var floats = [Float](repeating: 0, count: count)
        storage.withUnsafeBytes { src in
            guard let base = src.baseAddress else { return }
            for index in 0..<count {
                let q: Float
                switch descriptor.dataType {
                case .int8:
                    q = Float(base.load(fromByteOffset: index, as: Int8.self))
                case .uint8:
                    q = Float(base.load(fromByteOffset: index, as: UInt8.self))
                case .int32:
                    q = Float(base.load(fromByteOffset: index * 4, as: Int32.self))
                default:
                    q = 0
                }
                floats[index] = (q - zero) * scaleValue
            }
        }
        var output = Data(count: outDescriptor.tensorAllocationSizeInBytes)
        output.withUnsafeMutableBytes { dest in
            floats.withUnsafeBytes { src in
                if let base = dest.baseAddress, let srcBase = src.baseAddress {
                    memcpy(base, srcBase, min(dest.count, src.count))
                }
            }
        }
        return MLCTensor(descriptor: outDescriptor, storage: output)
    }

    func linuxFill(_ value: Float) {
        let count = mlcShapeVolume(descriptor.shape)
        switch descriptor.dataType {
        case .float32:
            var floats = [Float](repeating: value, count: count)
            storage = floats.withUnsafeMutableBytes { Data($0) }
        case .int32:
            let stored = Int32(value.rounded())
            var values = [Int32](repeating: stored, count: count)
            storage = values.withUnsafeMutableBytes { Data($0) }
        case .int64:
            let stored = Int64(value.rounded())
            var values = [Int64](repeating: stored, count: count)
            storage = values.withUnsafeMutableBytes { Data($0) }
        case .int8:
            var values = [Int8](repeating: Int8(clamping: Int(value.rounded())), count: count)
            storage = values.withUnsafeMutableBytes { Data($0) }
        case .uint8:
            var values = [UInt8](repeating: UInt8(clamping: Int(value.rounded())), count: count)
            storage = values.withUnsafeMutableBytes { Data($0) }
        case .boolean:
            var values = [UInt8](repeating: value == 0 ? 0 : 1, count: count)
            storage = values.withUnsafeMutableBytes { Data($0) }
        case .float16:
            storage = Data(count: count * 2)
        }
    }

    func linuxRandomFill(_ type: MLCRandomInitializerType) {
        let count = mlcShapeVolume(descriptor.shape)
        var floats = [Float](repeating: 0, count: count)
        let shape = descriptor.shape
        let fanIn = shape.count >= 2 ? max(shape[1] * (shape.count > 2 ? shape.dropFirst(2).reduce(1, *) : 1), 1) : 1
        let fanOut = shape.isEmpty ? 1 : max(shape[0] * (shape.count > 2 ? shape.dropFirst(2).reduce(1, *) : 1), 1)
        let limit: Float
        switch type {
        case .uniform:
            limit = 1
        case .glorotUniform:
            limit = Foundation.sqrt(6 / Float(fanIn + fanOut))
        case .xavier:
            limit = 1 / Foundation.sqrt(Float(fanIn))
        }
        for index in 0..<count {
            floats[index] = (MLCPlatform.nextUniform() * 2 - 1) * limit
        }
        storage = floats.withUnsafeMutableBytes { Data($0) }
    }

    public func linuxHostFloats() -> [Float]? {
        guard descriptor.dataType == .float32 else { return nil }
        let count = mlcShapeVolume(descriptor.shape)
        return storage.withUnsafeBytes { src in
            let buffer = src.bindMemory(to: Float.self)
            return Array(buffer.prefix(count))
        }
    }

    func linuxReplaceStorage(_ data: Data) {
        storage = data
    }
}
