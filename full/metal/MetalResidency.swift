import Foundation

/// Software residency tracking, identity rasterization-rate maps, CPU tensors,
/// in-memory binary archives, and related fail-closed factories. None of this
/// talks to an Apple GPU, IOSurface compositor, or AIR compiler.

func metalTensorElementSize(_ type: MTLTensorDataType) -> Int {
    switch type {
    case .none:
        return 0
    case .int8, .uint8:
        return 1
    case .float16, .bfloat16, .int16, .uint16:
        return 2
    case .float32, .int32, .uint32:
        return 4
    }
}

func metalTensorElementCount(_ extents: [Int]) -> Int {
    guard !extents.isEmpty else { return 0 }
    return extents.reduce(1) { $0 * max($1, 0) }
}

open class MTLResidencySetDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var initialCapacity: Int = 0

    public override init() {
        super.init()
    }
}

open class MTLTensorDescriptor: NSObject, NSCopying, @unchecked Sendable {
    public var cpuCacheMode: MTLCPUCacheMode = .defaultCache
    public var storageMode: MTLStorageMode = .shared
    public var hazardTrackingMode: MTLHazardTrackingMode = .default
    public var resourceOptions: MTLResourceOptions = .storageModeShared
    public var usage: MTLTensorUsage = .compute
    public var dataType: MTLTensorDataType = .none
    public var dimensions: MTLTensorExtents = MTLTensorExtents()
    public var strides: MTLTensorExtents?

    public override init() {
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLTensorDescriptor()
        copy.cpuCacheMode = cpuCacheMode
        copy.storageMode = storageMode
        copy.hazardTrackingMode = hazardTrackingMode
        copy.resourceOptions = resourceOptions
        copy.usage = usage
        copy.dataType = dataType
        copy.dimensions = dimensions.copy() as! MTLTensorExtents
        copy.strides = strides.flatMap { $0.copy() as? MTLTensorExtents }
        return copy
    }
}

open class MTLBinaryArchiveDescriptor: NSObject, @unchecked Sendable {
    public var url: URL?

    public override init() {
        super.init()
    }
}

open class MTLLogStateDescriptor: NSObject, @unchecked Sendable {
    public var bufferSize: Int = 0
    public var level: MTLLogLevel = .undefined

    public override init() {
        super.init()
    }
}

open class MTLSharedTextureHandle: NSObject, NSSecureCoding, @unchecked Sendable {
    public var device: any MTLDevice { LinuxMTLDevice.shared }
    public var label: String?

    public override init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        super.init()
        self.label = coder.decodeObject(of: NSString.self, forKey: "label") as String?
    }

    public func encode(with coder: NSCoder) {
        coder.encode(label as NSString?, forKey: "label")
    }
}

open class MTLResourceViewPoolDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var resourceViewCount: Int = 0

    public override init() {
        super.init()
    }
}

open class MTLAccelerationStructurePassSampleBufferAttachmentDescriptor: NSObject, @unchecked Sendable {
    public var sampleBuffer: (any MTLCounterSampleBuffer)?
    public var startOfEncoderSampleIndex: Int = 0
    public var endOfEncoderSampleIndex: Int = 0

    public override init() {
        super.init()
    }
}

open class MTLAccelerationStructurePassSampleBufferAttachmentDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLAccelerationStructurePassSampleBufferAttachmentDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(attachmentIndex: Int) -> MTLAccelerationStructurePassSampleBufferAttachmentDescriptor! {
        get {
            if let existing = storage[attachmentIndex] {
                return existing
            }
            let created = MTLAccelerationStructurePassSampleBufferAttachmentDescriptor()
            storage[attachmentIndex] = created
            return created
        }
        set {
            storage[attachmentIndex] = newValue
        }
    }
}

open class MTLAccelerationStructurePassDescriptor: NSObject, @unchecked Sendable {
    public let sampleBufferAttachments = MTLAccelerationStructurePassSampleBufferAttachmentDescriptorArray()

    public override init() {
        super.init()
    }

    public class func accelerationStructurePassDescriptor() -> MTLAccelerationStructurePassDescriptor {
        MTLAccelerationStructurePassDescriptor()
    }
}

open class MTLRasterizationRateSampleArray: NSObject, @unchecked Sendable {
    private var storage: [Int: Float] = [:]

    public override init() {
        super.init()
    }

    public subscript(index: Int) -> Float {
        get { storage[index] ?? 1 }
        set { storage[index] = newValue }
    }
}

open class MTLRasterizationRateLayerDescriptor: NSObject, NSCopying, @unchecked Sendable {
    public var sampleCount: MTLSize
    public let maxSampleCount: MTLSize
    public let horizontal = MTLRasterizationRateSampleArray()
    public let vertical = MTLRasterizationRateSampleArray()

    public init(sampleCount: MTLSize) {
        self.sampleCount = sampleCount
        self.maxSampleCount = sampleCount
        super.init()
        for x in 0..<max(sampleCount.width, 0) {
            horizontal[x] = 1
        }
        for y in 0..<max(sampleCount.height, 0) {
            vertical[y] = 1
        }
    }

    public convenience init(horizontal: [Float], vertical: [Float]) {
        self.init(sampleCount: MTLSize(width: horizontal.count, height: vertical.count, depth: 1))
        for (index, value) in horizontal.enumerated() {
            self.horizontal[index] = value
        }
        for (index, value) in vertical.enumerated() {
            self.vertical[index] = value
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MTLRasterizationRateLayerDescriptor(sampleCount: maxSampleCount)
        copy.sampleCount = sampleCount
        for x in 0..<max(maxSampleCount.width, 0) {
            copy.horizontal[x] = horizontal[x]
        }
        for y in 0..<max(maxSampleCount.height, 0) {
            copy.vertical[y] = vertical[y]
        }
        return copy
    }
}

open class MTLRasterizationRateLayerArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTLRasterizationRateLayerDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(layerIndex: Int) -> MTLRasterizationRateLayerDescriptor? {
        get { storage[layerIndex] }
        set { storage[layerIndex] = newValue }
    }

    var populated: [MTLRasterizationRateLayerDescriptor] {
        storage.keys.sorted().compactMap { storage[$0] }
    }
}

open class MTLRasterizationRateMapDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var screenSize = MTLSize()
    public let layers = MTLRasterizationRateLayerArray()

    public override init() {
        super.init()
    }

    public convenience init(screenSize: MTLSize, label: String? = nil) {
        self.init()
        self.screenSize = screenSize
        self.label = label
    }

    public convenience init(
        screenSize: MTLSize,
        layer: MTLRasterizationRateLayerDescriptor,
        label: String? = nil
    ) {
        self.init(screenSize: screenSize, label: label)
        layers[0] = layer
    }

    public convenience init(
        screenSize: MTLSize,
        layers layerList: [MTLRasterizationRateLayerDescriptor],
        label: String? = nil
    ) {
        self.init(screenSize: screenSize, label: label)
        for (index, layer) in layerList.enumerated() {
            layers[index] = layer
        }
    }

    public var layerCount: Int { layers.populated.count }

    public func layer(at layerIndex: Int) -> MTLRasterizationRateLayerDescriptor? {
        layers[layerIndex]
    }

    public func setLayer(_ layer: MTLRasterizationRateLayerDescriptor?, at layerIndex: Int) {
        layers[layerIndex] = layer
    }
}

final class LinuxMTLResidencySet: NSObject, MTLResidencySet, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private let lock = NSLock()
    private var storage: [ObjectIdentifier: any MTLAllocation] = [:]
    private var committed = false
    private var resident = false

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLResidencySetDescriptor) {
        self.owningDevice = device
        self.label = descriptor.label
        super.init()
        _ = descriptor.initialCapacity
    }

    var allocationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage.count
    }

    var allAllocations: [any MTLAllocation] {
        lock.lock()
        defer { lock.unlock() }
        return Array(storage.values)
    }

    var allocatedSize: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return storage.values.reduce(0) { $0 + UInt64(($1 as? MTLResource)?.allocatedSize ?? 0) }
    }

    func addAllocation(_ allocation: any MTLAllocation) {
        lock.lock()
        storage[ObjectIdentifier(allocation as AnyObject)] = allocation
        lock.unlock()
    }

    func removeAllocation(_ allocation: any MTLAllocation) {
        lock.lock()
        storage.removeValue(forKey: ObjectIdentifier(allocation as AnyObject))
        lock.unlock()
    }

    func addAllocations(_ allocations: [any MTLAllocation]) {
        for allocation in allocations {
            addAllocation(allocation)
        }
    }

    func removeAllocations(_ allocations: [any MTLAllocation]) {
        for allocation in allocations {
            removeAllocation(allocation)
        }
    }

    func containsAllocation(_ anAllocation: any MTLAllocation) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage[ObjectIdentifier(anAllocation as AnyObject)] != nil
    }

    func removeAllAllocations() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }

    func commit() {
        committed = true
    }

    func requestResidency() {
        resident = true
    }

    func endResidency() {
        resident = false
    }

    var isCommitted: Bool { committed }
    var isResident: Bool { resident }
}

final class LinuxMTLRasterizationRateMap: NSObject, MTLRasterizationRateMap, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let screenSize: MTLSize
    let physicalGranularity = MTLSize(width: 1, height: 1, depth: 1)
    let layerCount: Int
    let parameterBufferSizeAndAlign: MTLSizeAndAlign

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLRasterizationRateMapDescriptor) {
        self.owningDevice = device
        self.label = descriptor.label
        self.screenSize = descriptor.screenSize
        self.layerCount = max(descriptor.layerCount, 1)
        self.parameterBufferSizeAndAlign = MTLSizeAndAlign(
            size: 16 + self.layerCount * 16,
            align: 16
        )
        super.init()
    }

    func physicalSize(layer layerIndex: Int) -> MTLSize {
        _ = layerIndex
        return screenSize
    }

    func screenCoordinates(physicalCoordinates: MTLCoordinate2D, layer layerIndex: Int) -> MTLCoordinate2D {
        _ = layerIndex
        return physicalCoordinates
    }

    func physicalCoordinates(screenCoordinates: MTLCoordinate2D, layer layerIndex: Int) -> MTLCoordinate2D {
        _ = layerIndex
        return screenCoordinates
    }

    func copyParameterData(buffer: any MTLBuffer, offset: Int) {
        guard offset >= 0, offset + 16 <= buffer.length else { return }
        let header: [UInt32] = [
            UInt32(screenSize.width),
            UInt32(screenSize.height),
            UInt32(layerCount),
            1
        ]
        header.withUnsafeBytes { raw in
            buffer.contents().advanced(by: offset).copyMemory(from: raw.baseAddress!, byteCount: 16)
        }
    }
}

final class LinuxMTLTensor: LinuxMTLResource, MTLTensor, @unchecked Sendable {
    let gpuResourceID: MTLResourceID
    let dataType: MTLTensorDataType
    let dimensions: MTLTensorExtents
    let strides: MTLTensorExtents?
    let usage: MTLTensorUsage
    private let storage: UnsafeMutableRawPointer
    private let byteCount: Int
    private let ownsStorage: Bool
    let buffer: (any MTLBuffer)?
    let bufferOffset: Int

    init(
        device: LinuxMTLDevice,
        descriptor: MTLTensorDescriptor,
        byteCount: Int
    ) {
        self.gpuResourceID = device.nextID()
        self.dataType = descriptor.dataType
        self.dimensions = descriptor.dimensions.copy() as! MTLTensorExtents
        self.strides = descriptor.strides.flatMap { $0.copy() as? MTLTensorExtents }
        self.usage = descriptor.usage
        self.byteCount = max(byteCount, 1)
        self.storage = UnsafeMutableRawPointer.allocate(byteCount: self.byteCount, alignment: 16)
        self.storage.initializeMemory(as: UInt8.self, repeating: 0, count: self.byteCount)
        self.ownsStorage = true
        self.buffer = nil
        self.bufferOffset = 0
        var options = descriptor.resourceOptions
        if descriptor.storageMode == .private {
            options.insert(.storageModePrivate)
        }
        super.init(
            device: device,
            options: options,
            allocatedSize: self.byteCount,
            heap: nil,
            heapOffset: 0
        )
        device.noteAllocated(self.byteCount)
    }

    deinit {
        if ownsStorage {
            storage.deallocate()
            owningDevice.noteFreed(allocatedSize)
        }
    }

    func getBytes(
        _ bytes: UnsafeMutableRawPointer,
        strides: MTLTensorExtents,
        sliceOrigin: MTLTensorExtents,
        sliceDimensions: MTLTensorExtents
    ) {
        _ = strides
        let count = metalTensorElementCount(sliceDimensions.extents)
        let element = metalTensorElementSize(dataType)
        let originCount = metalTensorElementCount(sliceOrigin.extents)
        let byteOffset = originCount * element
        let byteLength = count * element
        guard byteOffset >= 0, byteOffset + byteLength <= byteCount else { return }
        bytes.copyMemory(from: storage.advanced(by: byteOffset), byteCount: byteLength)
    }

    func replace(
        sliceOrigin: MTLTensorExtents,
        sliceDimensions: MTLTensorExtents,
        withBytes bytes: UnsafeRawPointer,
        strides: MTLTensorExtents
    ) {
        _ = strides
        let count = metalTensorElementCount(sliceDimensions.extents)
        let element = metalTensorElementSize(dataType)
        let originCount = metalTensorElementCount(sliceOrigin.extents)
        let byteOffset = originCount * element
        let byteLength = count * element
        guard byteOffset >= 0, byteOffset + byteLength <= byteCount else { return }
        storage.advanced(by: byteOffset).copyMemory(from: bytes, byteCount: byteLength)
    }
}

final class LinuxMTLBinaryArchive: NSObject, MTLBinaryArchive, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private var computeCount = 0
    private var renderCount = 0

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLBinaryArchiveDescriptor) {
        self.owningDevice = device
        super.init()
        _ = descriptor.url
    }

    func addComputePipelineFunctions(descriptor: MTLComputePipelineDescriptor) throws {
        _ = descriptor
        computeCount += 1
    }

    func addRenderPipelineFunctions(descriptor: MTLRenderPipelineDescriptor) throws {
        _ = descriptor
        renderCount += 1
    }

    func serialize(to url: URL) throws {
        _ = url
        throw MTLBinaryArchiveError(
            .internalError,
            userInfo: [NSLocalizedDescriptionKey: "no GPU pipeline cache"]
        )
    }

    var storedComputeCount: Int { computeCount }
    var storedRenderCount: Int { renderCount }
}

final class LinuxMTLLogState: NSObject, MTLLogState, @unchecked Sendable {
    let bufferSize: Int
    let level: MTLLogLevel
    private var handlers: [(String?, String?, MTLLogLevel, String) -> Void] = []

    init(descriptor: MTLLogStateDescriptor) {
        self.bufferSize = descriptor.bufferSize
        self.level = descriptor.level
        super.init()
    }

    func addLogHandler(_ block: @escaping (String?, String?, MTLLogLevel, String) -> Void) {
        handlers.append(block)
    }
}

final class LinuxMTLCounterSampleBuffer: NSObject, MTLCounterSampleBuffer, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let sampleCount: Int

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLCounterSampleBufferDescriptor) {
        self.owningDevice = device
        self.label = descriptor.label
        self.sampleCount = max(descriptor.sampleCount, 0)
        super.init()
    }

    func resolveCounterRange(_ range: Range<Int>) throws -> Data? {
        _ = range
        return nil
    }
}

final class LinuxMTLFunctionHandle: NSObject, MTLFunctionHandle, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let name: String
    let functionType: MTLFunctionType
    let gpuResourceID: MTLResourceID

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, function: any MTLFunction) {
        self.owningDevice = device
        self.name = function.name
        self.functionType = function.functionType
        self.gpuResourceID = device.nextID()
        super.init()
    }

    init(device: LinuxMTLDevice, name: String, functionType: MTLFunctionType) {
        self.owningDevice = device
        self.name = name
        self.functionType = functionType
        self.gpuResourceID = device.nextID()
        super.init()
    }
}

final class LinuxMTLTextureViewPool: NSObject, MTLTextureViewPool, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let resourceViewCount: Int
    let baseResourceID: MTLResourceID
    private var views: [Int: MTLResourceID] = [:]

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLResourceViewPoolDescriptor) {
        self.owningDevice = device
        self.label = descriptor.label
        self.resourceViewCount = max(descriptor.resourceViewCount, 0)
        self.baseResourceID = device.nextID()
        super.init()
    }

    func copyResourceViews(
        from sourcePool: any MTLResourceViewPool,
        sourceRange: Range<Int>,
        destinationIndex: Int
    ) -> MTLResourceID {
        _ = (sourcePool, sourceRange, destinationIndex)
        return baseResourceID
    }

    func setTextureView(texture: any MTLTexture, index: Int) -> MTLResourceID {
        _ = texture
        let id = owningDevice.nextID()
        views[index] = id
        return id
    }

    func setTextureView(texture: any MTLTexture, descriptor: MTLTextureViewDescriptor, index: Int) -> MTLResourceID {
        _ = descriptor
        return setTextureView(texture: texture, index: index)
    }

    func setTextureView(
        buffer: any MTLBuffer,
        descriptor: MTLTextureDescriptor,
        offset: Int,
        bytesPerRow: Int,
        index: Int
    ) -> MTLResourceID {
        _ = (buffer, descriptor, offset, bytesPerRow)
        let id = owningDevice.nextID()
        views[index] = id
        return id
    }
}

final class LinuxMTLCommandBufferEncoderInfo: NSObject, MTLCommandBufferEncoderInfo, @unchecked Sendable {
    let label: String
    let debugSignposts: [String]
    let errorState: MTLCommandEncoderErrorState

    init(label: String, debugSignposts: [String] = [], errorState: MTLCommandEncoderErrorState) {
        self.label = label
        self.debugSignposts = debugSignposts
        self.errorState = errorState
        super.init()
    }
}

final class LinuxMTLAccelerationStructureCommandEncoder: NSObject, MTLAccelerationStructureCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    var label: String?
    private var ended = false
    private(set) var recorded: [String] = []

    var device: any MTLDevice { commandBuffer.device }

    init(commandBuffer: LinuxMTLCommandBuffer) {
        self.commandBuffer = commandBuffer
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        commandBuffer.finishEncoder()
    }

    func insertDebugSignpost(_ string: String) {
        recorded.append("signpost:\(string)")
    }

    func pushDebugGroup(_ string: String) {
        recorded.append("push:\(string)")
    }

    func popDebugGroup() {
        recorded.append("pop")
    }

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func build(
        accelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        scratchBuffer: any MTLBuffer,
        scratchBufferOffset: Int
    ) {
        recorded.append("build:\(accelerationStructure.size):\(scratchBuffer.length):\(scratchBufferOffset)")
        _ = descriptor
    }

    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: (any MTLBuffer)?,
        scratchBufferOffset: Int
    ) {
        refit(
            sourceAccelerationStructure: sourceAccelerationStructure,
            descriptor: descriptor,
            destinationAccelerationStructure: destinationAccelerationStructure,
            scratchBuffer: scratchBuffer,
            scratchBufferOffset: scratchBufferOffset,
            options: []
        )
    }

    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: (any MTLBuffer)?,
        scratchBufferOffset: Int,
        options: MTLAccelerationStructureRefitOptions
    ) {
        recorded.append(
            "refit:\(sourceAccelerationStructure.size):\(destinationAccelerationStructure?.size ?? -1):\(scratchBufferOffset):\(options.rawValue)"
        )
        _ = descriptor
    }

    func copy(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    ) {
        recorded.append("copy:\(sourceAccelerationStructure.size):\(destinationAccelerationStructure.size)")
    }

    func copyAndCompact(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    ) {
        recorded.append("compact:\(sourceAccelerationStructure.size):\(destinationAccelerationStructure.size)")
    }

    func writeCompactedSize(
        accelerationStructure: any MTLAccelerationStructure,
        buffer: any MTLBuffer,
        offset: Int
    ) {
        writeCompactedSize(
            accelerationStructure: accelerationStructure,
            buffer: buffer,
            offset: offset,
            sizeDataType: .uint
        )
    }

    func writeCompactedSize(
        accelerationStructure: any MTLAccelerationStructure,
        buffer: any MTLBuffer,
        offset: Int,
        sizeDataType: MTLDataType
    ) {
        _ = sizeDataType
        recorded.append("compacted:\(accelerationStructure.size):\(offset)")
        commandBuffer.record {
            guard offset >= 0, offset + 4 <= buffer.length else { return }
            buffer.contents().advanced(by: offset).storeBytes(of: UInt32(0), as: UInt32.self)
        }
    }

    func updateFence(_ fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.signal()
        }
    }

    func waitForFence(_ fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.wait()
        }
    }

    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage) {
        recorded.append("use:\(resource.allocatedSize):\(usage.rawValue)")
    }

    func useHeap(_ heap: any MTLHeap) {
        recorded.append("heap:\(heap.size)")
    }

    func sampleCounters(sampleBuffer: any MTLCounterSampleBuffer, sampleIndex: Int, barrier: Bool) {
        recorded.append("counters:\(sampleBuffer.sampleCount):\(sampleIndex):\(barrier)")
    }
}

extension MTLAccelerationStructureCommandEncoder {
    public func useResources(_ resources: [any MTLResource], usage: MTLResourceUsage) {
        for resource in resources {
            useResource(resource, usage: usage)
        }
    }

    public func useHeaps(_ heaps: [any MTLHeap]) {
        for heap in heaps {
            useHeap(heap)
        }
    }
}

extension MTLCommandQueue {
    public func addResidencySets(_ residencySets: [any MTLResidencySet]) {
        for set in residencySets {
            addResidencySet(set)
        }
    }

    public func removeResidencySets(_ residencySets: [any MTLResidencySet]) {
        for set in residencySets {
            removeResidencySet(set)
        }
    }
}

extension MTLCommandBuffer {
    public func useResidencySets(_ residencySets: [any MTLResidencySet]) {
        for set in residencySets {
            useResidencySet(set)
        }
    }
}

extension MTLDevice {
    public func makeResidencySet(descriptor desc: MTLResidencySetDescriptor) throws -> any MTLResidencySet {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLCPUValidationError("residency sets require the CPU reference device")
        }
        return LinuxMTLResidencySet(device: linux, descriptor: desc)
    }

    public func makeRasterizationRateMap(descriptor: MTLRasterizationRateMapDescriptor) -> (any MTLRasterizationRateMap)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        guard descriptor.screenSize.width > 0, descriptor.screenSize.height > 0 else { return nil }
        return LinuxMTLRasterizationRateMap(device: linux, descriptor: descriptor)
    }

    public func tensorSizeAndAlign(descriptor: MTLTensorDescriptor) -> MTLSizeAndAlign {
        let count = metalTensorElementCount(descriptor.dimensions.extents)
        let bytes = count * metalTensorElementSize(descriptor.dataType)
        let align = 16
        let size = bytes == 0 ? 0 : (bytes + align - 1) / align * align
        return MTLSizeAndAlign(size: size, align: align)
    }

    public func makeTensor(descriptor: MTLTensorDescriptor) throws -> any MTLTensor {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLTensorError(.internalError, userInfo: [NSLocalizedDescriptionKey: "no CPU tensor device"])
        }
        guard descriptor.dataType != .none, !descriptor.dimensions.extents.isEmpty else {
            throw MTLTensorError(
                .invalidDescriptor,
                userInfo: [NSLocalizedDescriptionKey: "tensor descriptor requires a data type and extents"]
            )
        }
        let sized = tensorSizeAndAlign(descriptor: descriptor)
        guard sized.size > 0 else {
            throw MTLTensorError(.invalidDescriptor, userInfo: [NSLocalizedDescriptionKey: "tensor size is zero"])
        }
        return LinuxMTLTensor(device: linux, descriptor: descriptor, byteCount: sized.size)
    }

    public func makeBinaryArchive(descriptor: MTLBinaryArchiveDescriptor) throws -> any MTLBinaryArchive {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLBinaryArchiveError(.internalError, userInfo: [NSLocalizedDescriptionKey: "no binary archive device"])
        }
        return LinuxMTLBinaryArchive(device: linux, descriptor: descriptor)
    }

    public func makeDynamicLibrary(library: any MTLLibrary) throws -> any MTLDynamicLibrary {
        _ = library
        throw MTLDynamicLibraryError(
            .unsupported,
            userInfo: [NSLocalizedDescriptionKey: "no AIR dynamic library loader"]
        )
    }

    public func makeDynamicLibrary(url: URL) throws -> any MTLDynamicLibrary {
        _ = url
        throw MTLDynamicLibraryError(
            .unsupported,
            userInfo: [NSLocalizedDescriptionKey: "no AIR dynamic library loader"]
        )
    }

    public func makeLogState(descriptor: MTLLogStateDescriptor) throws -> any MTLLogState {
        guard descriptor.bufferSize >= 0 else {
            throw MTLLogStateError.invalidSize
        }
        return LinuxMTLLogState(descriptor: descriptor)
    }

    public func makeSharedTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)? {
        _ = descriptor
        return nil
    }

    public func makeSharedTexture(handle sharedHandle: MTLSharedTextureHandle) -> (any MTLTexture)? {
        _ = sharedHandle
        return nil
    }

    public func makeTextureViewPool(descriptor: MTLResourceViewPoolDescriptor) throws -> any MTLTextureViewPool {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLCPUValidationError("texture view pools require the CPU reference device")
        }
        guard descriptor.resourceViewCount >= 0 else {
            throw MTLCPUValidationError("resourceViewCount must be >= 0")
        }
        return LinuxMTLTextureViewPool(device: linux, descriptor: descriptor)
    }

    public func functionHandle(function: any MTLFunction) -> (any MTLFunctionHandle)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTLFunctionHandle(device: linux, function: function)
    }

    public func functionHandle(function: any MTL4BinaryFunction) -> (any MTLFunctionHandle)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTLFunctionHandle(device: linux, name: "binary", functionType: .kernel)
    }
}
