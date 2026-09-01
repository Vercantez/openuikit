import Foundation

final class LinuxMTLDevice: NSObject, MTLDevice, @unchecked Sendable {
    static let shared = LinuxMTLDevice()

    let architecture = MTLArchitecture(name: "cpu")
    private let lock = NSLock()
    private var allocated: Int = 0
    private var nextResourceID: UInt64 = 1

    var name: String { "OpenUIKit Software Metal" }
    var registryID: UInt64 { 0x4F55494B4D544C01 }
    var maxThreadsPerThreadgroup: MTLSize { MTLSize(width: 1, height: 1, depth: 1) }
    var hasUnifiedMemory: Bool { true }
    var recommendedMaxWorkingSetSize: UInt64 { 256 * 1024 * 1024 }
    var maxBufferLength: Int { 256 * 1024 * 1024 }
    var maxThreadgroupMemoryLength: Int { 0 }
    var maxArgumentBufferSamplerCount: Int { 16 }
    var argumentBuffersSupport: MTLArgumentBuffersTier { .tier1 }
    var readWriteTextureSupport: MTLReadWriteTextureTier { .tierNone }
    var areBarycentricCoordsSupported: Bool { false }
    var areRasterOrderGroupsSupported: Bool { false }
    var areProgrammableSamplePositionsSupported: Bool { false }
    var sparseTileSizeInBytes: Int { 0 }
    var supports32BitFloatFiltering: Bool { false }
    var supports32BitMSAA: Bool { false }
    var supportsBCTextureCompression: Bool { false }
    var supportsPullModelInterpolation: Bool { false }
    var supportsShaderBarycentricCoordinates: Bool { false }
    var supportsQueryTextureLOD: Bool { false }
    var supportsFunctionPointers: Bool { false }
    var supportsFunctionPointersFromRender: Bool { false }
    var supportsRaytracing: Bool { false }
    var supportsRaytracingFromRender: Bool { false }
    var supportsPrimitiveMotionBlur: Bool { false }
    var supportsDynamicLibraries: Bool { false }
    var supportsRenderDynamicLibraries: Bool { false }
    var maximumConcurrentCompilationTaskCount: Int { 1 }

    var currentAllocatedSize: Int {
        lock.lock()
        defer { lock.unlock() }
        return allocated
    }

    func supportsFamily(_ gpuFamily: MTLGPUFamily) -> Bool {
        _ = gpuFamily
        return false
    }

    func supportsFeatureSet(_ featureSet: MTLFeatureSet) -> Bool {
        _ = featureSet
        return false
    }

    func supportsTextureSampleCount(_ sampleCount: Int) -> Bool {
        sampleCount == 1
    }

    func supportsVertexAmplificationCount(_ count: Int) -> Bool {
        count <= 1
    }

    func supportsRasterizationRateMap(layerCount: Int) -> Bool {
        _ = layerCount
        return false
    }

    func supportsCounterSampling(_ samplingPoint: MTLCounterSamplingPoint) -> Bool {
        _ = samplingPoint
        return false
    }

    func minimumLinearTextureAlignment(for format: MTLPixelFormat) -> Int {
        _ = format
        return 16
    }

    func minimumTextureBufferAlignment(for format: MTLPixelFormat) -> Int {
        _ = format
        return 16
    }

    func heapBufferSizeAndAlign(length: Int, options: MTLResourceOptions = []) -> MTLSizeAndAlign {
        _ = options
        let align = 16
        let size = (max(length, 0) + align - 1) / align * align
        return MTLSizeAndAlign(size: size, align: align)
    }

    func heapTextureSizeAndAlign(descriptor desc: MTLTextureDescriptor) -> MTLSizeAndAlign {
        let bytes = LinuxMTLTexture.storageByteCount(descriptor: desc)
        return MTLSizeAndAlign(size: bytes, align: 16)
    }

    func makeCommandQueue() -> (any MTLCommandQueue)? {
        LinuxMTLCommandQueue(device: self)
    }

    func makeCommandQueue(maxCommandBufferCount: Int) -> (any MTLCommandQueue)? {
        _ = maxCommandBufferCount
        return LinuxMTLCommandQueue(device: self)
    }

    func makeCommandQueue(descriptor: MTLCommandQueueDescriptor) -> (any MTLCommandQueue)? {
        _ = descriptor
        return LinuxMTLCommandQueue(device: self)
    }

    func makeBuffer(length: Int, options: MTLResourceOptions = []) -> (any MTLBuffer)? {
        guard length >= 0 else { return nil }
        let storage = UnsafeMutableRawPointer.allocate(byteCount: max(length, 1), alignment: 16)
        storage.initializeMemory(as: UInt8.self, repeating: 0, count: max(length, 1))
        noteAllocated(length)
        return LinuxMTLBuffer(
            device: self,
            length: length,
            options: options,
            storage: storage,
            ownsStorage: true,
            deallocator: nil
        )
    }

    func makeBuffer(
        bytes pointer: UnsafeRawPointer,
        length: Int,
        options: MTLResourceOptions = []
    ) -> (any MTLBuffer)? {
        guard let buffer = makeBuffer(length: length, options: options) else { return nil }
        if length > 0 {
            buffer.contents().copyMemory(from: pointer, byteCount: length)
        }
        return buffer
    }

    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)? {
        guard descriptor.width > 0, descriptor.height > 0 else { return nil }
        let bytes = LinuxMTLTexture.storageByteCount(descriptor: descriptor)
        let storage = UnsafeMutableRawPointer.allocate(byteCount: max(bytes, 1), alignment: 16)
        storage.initializeMemory(as: UInt8.self, repeating: 0, count: max(bytes, 1))
        noteAllocated(bytes)
        return LinuxMTLTexture(
            device: self,
            descriptor: descriptor,
            storage: storage,
            ownsStorage: true,
            parentBuffer: nil,
            bufferOffset: 0,
            bufferBytesPerRow: 0
        )
    }

    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> (any MTLSamplerState)? {
        LinuxMTLSamplerState(device: self, descriptor: descriptor, resourceID: nextID())
    }

    func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> (any MTLDepthStencilState)? {
        LinuxMTLDepthStencilState(device: self, descriptor: descriptor, resourceID: nextID())
    }

    func makeDefaultLibrary() -> (any MTLLibrary)? {
        nil
    }

    func makeLibrary(source: String, options: MTLCompileOptions?) throws -> any MTLLibrary {
        _ = (source, options)
        throw metalUnsupportedLibraryError(
            .unsupported,
            reason: "Linux Metal has no AIR/Metal shader compiler"
        )
    }

    func makeLibrary(URL url: URL) throws -> any MTLLibrary {
        _ = url
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "Linux Metal cannot load Apple metallib binaries"
        )
    }

    func makeEvent() -> (any MTLEvent)? {
        LinuxMTLEvent(device: self)
    }

    func makeFence() -> (any MTLFence)? {
        LinuxMTLFence(device: self)
    }

    func getDefaultSamplePositions(sampleCount: Int) -> [MTLSamplePosition] {
        if sampleCount == 1 {
            return [MTLSamplePosition(x: 0.5, y: 0.5)]
        }
        return []
    }

    fileprivate func noteAllocated(_ bytes: Int) {
        lock.lock()
        allocated += max(bytes, 0)
        lock.unlock()
    }

    fileprivate func noteFreed(_ bytes: Int) {
        lock.lock()
        allocated = max(0, allocated - max(bytes, 0))
        lock.unlock()
    }

    fileprivate func nextID() -> MTLResourceID {
        lock.lock()
        defer { lock.unlock() }
        let value = nextResourceID
        nextResourceID += 1
        return MTLResourceID(impl: value)
    }
}

class LinuxMTLResource: NSObject, MTLResource, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let cpuCacheMode: MTLCPUCacheMode
    let storageMode: MTLStorageMode
    let hazardTrackingMode: MTLHazardTrackingMode
    let resourceOptions: MTLResourceOptions
    let allocatedSize: Int
    var label: String?
    private var aliasable = false
    private var purgeableState: MTLPurgeableState = .nonVolatile

    var device: any MTLDevice { owningDevice }
    var heap: (any MTLHeap)? { nil }
    var heapOffset: Int { 0 }

    init(device: LinuxMTLDevice, options: MTLResourceOptions, allocatedSize: Int) {
        self.owningDevice = device
        self.resourceOptions = options
        self.allocatedSize = allocatedSize
        if options.contains(.storageModePrivate) {
            self.storageMode = .private
        } else if options.contains(.storageModeMemoryless) {
            self.storageMode = .memoryless
        } else {
            self.storageMode = .shared
        }
        self.cpuCacheMode = options.contains(.cpuCacheModeWriteCombined) ? .writeCombined : .defaultCache
        if options.contains(.hazardTrackingModeTracked) {
            self.hazardTrackingMode = .tracked
        } else if options.contains(.hazardTrackingModeUntracked) {
            self.hazardTrackingMode = .untracked
        } else {
            self.hazardTrackingMode = .default
        }
        super.init()
    }

    func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState {
        let previous = purgeableState
        if state != .keepCurrent {
            purgeableState = state
        }
        return previous
    }

    func makeAliasable() {
        aliasable = true
    }

    func isAliasable() -> Bool {
        aliasable
    }
}

final class LinuxMTLBuffer: LinuxMTLResource, MTLBuffer, @unchecked Sendable {
    let length: Int
    let gpuAddress: MTLGPUAddress
    let sparseBufferTier: MTLBufferSparseTier = .tierNone
    private let storage: UnsafeMutableRawPointer
    private let ownsStorage: Bool
    private let deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?

    init(
        device: LinuxMTLDevice,
        length: Int,
        options: MTLResourceOptions,
        storage: UnsafeMutableRawPointer,
        ownsStorage: Bool,
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?
    ) {
        self.length = length
        self.gpuAddress = UInt64(UInt(bitPattern: storage))
        self.storage = storage
        self.ownsStorage = ownsStorage
        self.deallocator = deallocator
        super.init(device: device, options: options, allocatedSize: length)
    }

    deinit {
        owningDevice.noteFreed(length)
        if let deallocator {
            deallocator(storage, length)
        } else if ownsStorage {
            storage.deallocate()
        }
    }

    func contents() -> UnsafeMutableRawPointer {
        storage
    }

    func addDebugMarker(_ marker: String, range: Range<Int>) {
        _ = (marker, range)
    }

    func removeAllDebugMarkers() {}

    func makeTexture(
        descriptor: MTLTextureDescriptor,
        offset: Int,
        bytesPerRow: Int
    ) -> (any MTLTexture)? {
        guard offset >= 0, bytesPerRow > 0, offset < length else { return nil }
        return LinuxMTLTexture(
            device: owningDevice,
            descriptor: descriptor,
            storage: storage.advanced(by: offset),
            ownsStorage: false,
            parentBuffer: self,
            bufferOffset: offset,
            bufferBytesPerRow: bytesPerRow
        )
    }
}

final class LinuxMTLTexture: LinuxMTLResource, MTLTexture, @unchecked Sendable {
    let textureType: MTLTextureType
    let pixelFormat: MTLPixelFormat
    let width: Int
    let height: Int
    let depth: Int
    let mipmapLevelCount: Int
    let sampleCount: Int
    let arrayLength: Int
    let usage: MTLTextureUsage
    let isFramebufferOnly: Bool = false
    let isShareable: Bool = false
    let isSparse: Bool = false
    let allowGPUOptimizedContents: Bool
    let compressionType: MTLTextureCompressionType
    let swizzle: MTLTextureSwizzleChannels
    let parent: (any MTLTexture)? = nil
    let parentRelativeLevel: Int = 0
    let parentRelativeSlice: Int = 0
    let buffer: (any MTLBuffer)?
    let bufferOffset: Int
    let bufferBytesPerRow: Int
    let gpuResourceID: MTLResourceID
    let firstMipmapInTail: Int = 0
    let tailSizeInBytes: Int = 0
    let sparseTextureTier: MTLTextureSparseTier = .tierNone
    private let storage: UnsafeMutableRawPointer
    private let ownsStorage: Bool
    private let bytesPerPixel: Int?

    var rootResource: (any MTLResource)? { buffer }

    init(
        device: LinuxMTLDevice,
        descriptor: MTLTextureDescriptor,
        storage: UnsafeMutableRawPointer,
        ownsStorage: Bool,
        parentBuffer: (any MTLBuffer)?,
        bufferOffset: Int,
        bufferBytesPerRow: Int
    ) {
        self.textureType = descriptor.textureType
        self.pixelFormat = descriptor.pixelFormat
        self.width = descriptor.width
        self.height = descriptor.height
        self.depth = max(descriptor.depth, 1)
        self.mipmapLevelCount = max(descriptor.mipmapLevelCount, 1)
        self.sampleCount = max(descriptor.sampleCount, 1)
        self.arrayLength = max(descriptor.arrayLength, 1)
        self.usage = descriptor.usage
        self.allowGPUOptimizedContents = descriptor.allowGPUOptimizedContents
        self.compressionType = descriptor.compressionType
        self.swizzle = descriptor.swizzle
        self.buffer = parentBuffer
        self.bufferOffset = bufferOffset
        self.bufferBytesPerRow = bufferBytesPerRow
        self.gpuResourceID = device.nextID()
        self.storage = storage
        self.ownsStorage = ownsStorage
        self.bytesPerPixel = metalBytesPerPixel(descriptor.pixelFormat)
        super.init(
            device: device,
            options: descriptor.resourceOptions,
            allocatedSize: LinuxMTLTexture.storageByteCount(descriptor: descriptor)
        )
    }

    deinit {
        if ownsStorage {
            owningDevice.noteFreed(allocatedSize)
            storage.deallocate()
        }
    }

    static func mipmapCount(width: Int, height: Int) -> Int {
        var count = 1
        var w = max(width, 1)
        var h = max(height, 1)
        while w > 1 || h > 1 {
            w = max(w / 2, 1)
            h = max(h / 2, 1)
            count += 1
        }
        return count
    }

    static func storageByteCount(descriptor: MTLTextureDescriptor) -> Int {
        let pixelBytes = metalBytesPerPixel(descriptor.pixelFormat) ?? 4
        let width = max(descriptor.width, 1)
        let height = max(descriptor.height, 1)
        let depth = max(descriptor.depth, 1)
        let array = max(descriptor.arrayLength, 1)
        let samples = max(descriptor.sampleCount, 1)
        return width * height * depth * array * samples * pixelBytes
    }

    func replace(
        region: MTLRegion,
        mipmapLevel level: Int,
        withBytes pixelBytes: UnsafeRawPointer,
        bytesPerRow: Int
    ) {
        replace(
            region: region,
            mipmapLevel: level,
            slice: 0,
            withBytes: pixelBytes,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerRow * max(region.size.height, 1)
        )
    }

    func replace(
        region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int,
        withBytes pixelBytes: UnsafeRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int
    ) {
        _ = (level, slice, bytesPerImage)
        copyRegion(region, bytesPerRow: bytesPerRow, from: pixelBytes, to: storage)
    }

    func getBytes(
        _ pixelBytes: UnsafeMutableRawPointer,
        bytesPerRow: Int,
        from region: MTLRegion,
        mipmapLevel level: Int
    ) {
        getBytes(
            pixelBytes,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerRow * max(region.size.height, 1),
            from: region,
            mipmapLevel: level,
            slice: 0
        )
    }

    func getBytes(
        _ pixelBytes: UnsafeMutableRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int,
        from region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int
    ) {
        _ = (level, slice, bytesPerImage)
        copyRegion(region, bytesPerRow: bytesPerRow, from: storage, to: pixelBytes)
    }

    func makeTextureView(pixelFormat: MTLPixelFormat) -> (any MTLTexture)? {
        guard pixelFormat == self.pixelFormat else { return nil }
        return self
    }

    private func copyRegion(
        _ region: MTLRegion,
        bytesPerRow: Int,
        from source: UnsafeRawPointer,
        to destination: UnsafeMutableRawPointer
    ) {
        guard let bytesPerPixel, levelZeroContains(region) else { return }
        let origin = region.origin
        let size = region.size
        let destBytesPerRow = max(width * bytesPerPixel, bytesPerPixel)
        for row in 0..<max(size.height, 0) {
            let src = source.advanced(by: row * bytesPerRow)
            let dst = destination.advanced(
                by: (origin.y + row) * destBytesPerRow + origin.x * bytesPerPixel
            )
            dst.copyMemory(from: src, byteCount: max(size.width, 0) * bytesPerPixel)
        }
    }

    private func copyRegion(
        _ region: MTLRegion,
        bytesPerRow: Int,
        from source: UnsafeMutableRawPointer,
        to destination: UnsafeMutableRawPointer
    ) {
        guard let bytesPerPixel, levelZeroContains(region) else { return }
        let origin = region.origin
        let size = region.size
        for row in 0..<max(size.height, 0) {
            let src = source.advanced(
                by: ((origin.y + row) * width + origin.x) * bytesPerPixel
            )
            let dst = destination.advanced(by: row * bytesPerRow)
            dst.copyMemory(from: src, byteCount: max(size.width, 0) * bytesPerPixel)
        }
    }

    private func levelZeroContains(_ region: MTLRegion) -> Bool {
        region.origin.x >= 0
            && region.origin.y >= 0
            && region.origin.x + region.size.width <= width
            && region.origin.y + region.size.height <= height
    }
}

final class LinuxMTLCommandQueue: NSObject, MTLCommandQueue, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func makeCommandBuffer() -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: true)
    }

    func makeCommandBuffer(descriptor: MTLCommandBufferDescriptor) -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: descriptor.retainedReferences)
    }

    func makeCommandBufferWithUnretainedReferences() -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: false)
    }

    func insertDebugCaptureBoundary() {}
}

final class LinuxMTLCommandBuffer: NSObject, MTLCommandBuffer, @unchecked Sendable {
    unowned let queue: LinuxMTLCommandQueue
    let retainedReferences: Bool
    let errorOptions: MTLCommandBufferErrorOption = []
    var label: String?
    private(set) var status: MTLCommandBufferStatus = .notEnqueued
    private(set) var error: (any Error)?
    var kernelStartTime: TimeInterval = 0
    var kernelEndTime: TimeInterval = 0
    var gpuStartTime: TimeInterval = 0
    var gpuEndTime: TimeInterval = 0
    let logs = MTLLogContainer()
    private var completedHandlers: [MTLCommandBufferHandler] = []
    private var scheduledHandlers: [MTLCommandBufferHandler] = []
    private var recorded: [() -> Void] = []
    private var encoding = false

    var device: any MTLDevice { queue.device }
    var commandQueue: any MTLCommandQueue { queue }

    init(queue: LinuxMTLCommandQueue, retainedReferences: Bool) {
        self.queue = queue
        self.retainedReferences = retainedReferences
        super.init()
    }

    func enqueue() {
        if status == .notEnqueued {
            status = .enqueued
        }
    }

    func commit() {
        enqueue()
        status = .committed
        status = .scheduled
        for handler in scheduledHandlers {
            handler(self)
        }
        for work in recorded {
            work()
        }
        recorded.removeAll()
        status = .completed
        for handler in completedHandlers {
            handler(self)
        }
    }

    func addScheduledHandler(_ block: @escaping MTLCommandBufferHandler) {
        scheduledHandlers.append(block)
    }

    func addCompletedHandler(_ block: @escaping MTLCommandBufferHandler) {
        completedHandlers.append(block)
    }

    func waitUntilScheduled() {}

    func waitUntilCompleted() {
        if status == .committed || status == .scheduled {
            status = .completed
        }
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func present(_ drawable: any MTLDrawable) {
        drawable.present()
    }

    func makeBlitCommandEncoder() -> (any MTLBlitCommandEncoder)? {
        guard !encoding else { return nil }
        encoding = true
        return LinuxMTLBlitCommandEncoder(commandBuffer: self)
    }

    fileprivate func finishEncoder() {
        encoding = false
    }

    fileprivate func record(_ work: @escaping () -> Void) {
        recorded.append(work)
    }
}

final class LinuxMTLBlitCommandEncoder: NSObject, MTLBlitCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    var label: String?
    private var ended = false

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
        _ = string
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func fill(buffer: any MTLBuffer, range: Range<Int>, value: UInt8) {
        let lower = range.lowerBound
        let count = range.count
        commandBuffer.record {
            guard lower >= 0, lower + count <= buffer.length else { return }
            buffer.contents().advanced(by: lower).initializeMemory(
                as: UInt8.self,
                repeating: value,
                count: count
            )
        }
    }

    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    ) {
        commandBuffer.record {
            guard size > 0,
                  sourceOffset >= 0,
                  destinationOffset >= 0,
                  sourceOffset + size <= sourceBuffer.length,
                  destinationOffset + size <= destinationBuffer.length
            else { return }
            destinationBuffer.contents().advanced(by: destinationOffset).copyMemory(
                from: sourceBuffer.contents().advanced(by: sourceOffset),
                byteCount: size
            )
        }
    }

    func generateMipmaps(for texture: any MTLTexture) {
        _ = texture
    }

    func optimizeContentsForCPUAccess(texture: any MTLTexture) {
        _ = texture
    }

    func optimizeContentsForGPUAccess(texture: any MTLTexture) {
        _ = texture
    }
}

final class LinuxMTLSamplerState: NSObject, MTLSamplerState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let gpuResourceID: MTLResourceID

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLSamplerDescriptor, resourceID: MTLResourceID) {
        self.owningDevice = device
        self.label = descriptor.label
        self.gpuResourceID = resourceID
        super.init()
    }
}

final class LinuxMTLDepthStencilState: NSObject, MTLDepthStencilState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let gpuResourceID: MTLResourceID

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLDepthStencilDescriptor, resourceID: MTLResourceID) {
        self.owningDevice = device
        self.label = descriptor.label
        self.gpuResourceID = resourceID
        super.init()
    }
}

final class LinuxMTLFence: NSObject, MTLFence, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }
}

final class LinuxMTLEvent: NSObject, MTLEvent, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }
}

final class LinuxMTLCaptureScope: NSObject, MTLCaptureScope, @unchecked Sendable {
    let device: (any MTLDevice)?
    let commandQueue: (any MTLCommandQueue)?
    var label: String?

    init(device: (any MTLDevice)?, commandQueue: (any MTLCommandQueue)?) {
        self.device = device
        self.commandQueue = commandQueue
        super.init()
    }

    func begin() {}

    func end() {}
}
