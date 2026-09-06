import Foundation

/// MetalKit writes `MTLTextureDescriptor.storageMode` (and the sibling
/// mode fields) without updating `resourceOptions`. The created resource
/// must report those descriptor fields, not only the option bits.
func metalResourceOptions(from descriptor: MTLTextureDescriptor) -> MTLResourceOptions {
    var options = descriptor.resourceOptions
    options.remove(.storageModePrivate)
    options.remove(.storageModeMemoryless)
    switch descriptor.storageMode {
    case .private:
        options.insert(.storageModePrivate)
    case .memoryless:
        options.insert(.storageModeMemoryless)
    case .shared:
        break
    }
    if descriptor.cpuCacheMode == .writeCombined {
        options.insert(.cpuCacheModeWriteCombined)
    } else {
        options.remove(.cpuCacheModeWriteCombined)
    }
    options.remove(.hazardTrackingModeTracked)
    options.remove(.hazardTrackingModeUntracked)
    switch descriptor.hazardTrackingMode {
    case .tracked:
        options.insert(.hazardTrackingModeTracked)
    case .untracked:
        options.insert(.hazardTrackingModeUntracked)
    case .default:
        break
    }
    return options
}

final class LinuxMTLDevice: NSObject, MTLDevice, @unchecked Sendable {
    static let shared = LinuxMTLDevice()

    let architecture = MTLArchitecture(name: "cpu")
    private let lock = NSLock()
    private var allocated: Int = 0
    private var nextResourceID: UInt64 = 1

    var name: String { "OpenUIKit CPU Reference" }
    var registryID: UInt64 { 0x4F55494B4D544C01 }
    var maxThreadsPerThreadgroup: MTLSize { MTLSize(width: 64, height: 1, depth: 1) }
    var hasUnifiedMemory: Bool { true }
    var recommendedMaxWorkingSetSize: UInt64 { 256 * 1024 * 1024 }
    var maxBufferLength: Int { 256 * 1024 * 1024 }
    var maxThreadgroupMemoryLength: Int { 32 * 1024 }
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
            deallocator: nil,
            heap: nil,
            heapOffset: 0
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

    func makeBuffer(
        bytesNoCopy pointer: UnsafeMutableRawPointer,
        length: Int,
        options: MTLResourceOptions = [],
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)? = nil
    ) -> (any MTLBuffer)? {
        guard length >= 0 else { return nil }
        noteAllocated(length)
        return LinuxMTLBuffer(
            device: self,
            length: length,
            options: options,
            storage: pointer,
            ownsStorage: false,
            deallocator: deallocator,
            heap: nil,
            heapOffset: 0
        )
    }

    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)? {
        guard MetalCPULayout.isValidTextureDescriptor(descriptor) else { return nil }
        if descriptor.sampleCount != 1, !supportsTextureSampleCount(descriptor.sampleCount) {
            return nil
        }
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
            bufferBytesPerRow: 0,
            heap: nil,
            heapOffset: 0
        )
    }

    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> (any MTLSamplerState)? {
        LinuxMTLSamplerState(device: self, descriptor: descriptor, resourceID: nextID())
    }

    func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> (any MTLDepthStencilState)? {
        LinuxMTLDepthStencilState(device: self, descriptor: descriptor, resourceID: nextID())
    }

    func makeHeap(descriptor: MTLHeapDescriptor) -> (any MTLHeap)? {
        guard descriptor.size >= 0 else { return nil }
        return LinuxMTLHeap(device: self, descriptor: descriptor)
    }

    func makeDefaultLibrary() -> (any MTLLibrary)? {
        nil
    }

    func makeDefaultLibrary(bundle: Bundle) throws -> any MTLLibrary {
        _ = bundle
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "Linux Metal has no default metallib in the process bundle"
        )
    }

    func makeLibrary(source: String, options: MTLCompileOptions?) throws -> any MTLLibrary {
        _ = (source, options)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeLibrary(URL url: URL) throws -> any MTLLibrary {
        _ = url
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "Linux Metal cannot load Apple metallib binaries"
        )
    }

    func makeLibrary(filepath: String) throws -> any MTLLibrary {
        _ = filepath
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "Linux Metal cannot load Apple metallib binaries"
        )
    }

    func makeComputePipelineState(function computeFunction: any MTLFunction) throws -> any MTLComputePipelineState {
        guard let function = computeFunction as? LinuxMTLFunction, function.isCPUBuiltin else {
            throw metalUnsupportedLibraryError(
                .compileFailure,
                reason: "no shader compiler"
            )
        }
        return LinuxMTLComputePipelineState(device: self, function: function)
    }

    func makeComputePipelineState(descriptor: MTLComputePipelineDescriptor) throws -> any MTLComputePipelineState {
        guard let function = descriptor.computeFunction else {
            throw MTLCPUValidationError("compute pipeline descriptor has no compute function")
        }
        return try makeComputePipelineState(function: function)
    }

    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> any MTLRenderPipelineState {
        try validateRenderPipeline(descriptor)
        return LinuxMTLRenderPipelineState(device: self, descriptor: descriptor)
    }

    func makeEvent() -> (any MTLEvent)? {
        LinuxMTLEvent(device: self)
    }

    func makeSharedEvent() -> (any MTLSharedEvent)? {
        LinuxMTLSharedEvent(device: self)
    }

    func makeSharedEvent(handle sharedEventHandle: MTLSharedEventHandle) -> (any MTLSharedEvent)? {
        let event = LinuxMTLSharedEvent(device: self)
        event.label = sharedEventHandle.label
        event.signaledValue = sharedEventHandle.signaledValue
        return event
    }

    func makeFence() -> (any MTLFence)? {
        LinuxMTLFence(device: self)
    }

    func makeArgumentEncoder(arguments: [MTLArgumentDescriptor]) -> (any MTLArgumentEncoder)? {
        LinuxMTLArgumentEncoder(device: self, arguments: arguments)
    }

    func makeIndirectCommandBuffer(
        descriptor: MTLIndirectCommandBufferDescriptor,
        maxCommandCount maxCount: Int,
        options: MTLResourceOptions = []
    ) -> (any MTLIndirectCommandBuffer)? {
        guard maxCount > 0 else { return nil }
        return LinuxMTLIndirectCommandBuffer(
            device: self,
            descriptor: descriptor,
            maxCommandCount: maxCount,
            options: options
        )
    }

    func getDefaultSamplePositions(sampleCount: Int) -> [MTLSamplePosition] {
        if sampleCount == 1 {
            return [MTLSamplePosition(x: 0.5, y: 0.5)]
        }
        return []
    }

    private func validateRenderPipeline(_ descriptor: MTLRenderPipelineDescriptor) throws {
        if descriptor.vertexFunction != nil || descriptor.fragmentFunction != nil {
            throw metalUnsupportedLibraryError(
                .compileFailure,
                reason: "no shader compiler"
            )
        }
        if descriptor.sampleCount < 1 || descriptor.rasterSampleCount < 1 {
            throw MTLCPUValidationError("render pipeline sampleCount must be >= 1")
        }
        let attachment = descriptor.colorAttachments[0]!
        if attachment.isBlendingEnabled, attachment.pixelFormat == .invalid {
            throw MTLCPUValidationError("blending requires a valid color pixel format")
        }
        if let vertex = descriptor.vertexDescriptor {
            for index in 0..<31 {
                let layout = vertex.layouts[index]!
                if layout.stride < 0 {
                    throw MTLCPUValidationError("vertex descriptor stride must be >= 0")
                }
            }
        }
    }

    func noteAllocated(_ bytes: Int) {
        lock.lock()
        allocated += max(bytes, 0)
        lock.unlock()
    }

    func noteFreed(_ bytes: Int) {
        lock.lock()
        allocated = max(0, allocated - max(bytes, 0))
        lock.unlock()
    }

    func nextID() -> MTLResourceID {
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
    weak var owningHeap: LinuxMTLHeap?
    let heapOffsetValue: Int

    var device: any MTLDevice { owningDevice }
    var heap: (any MTLHeap)? { owningHeap }
    var heapOffset: Int { heapOffsetValue }

    init(
        device: LinuxMTLDevice,
        options: MTLResourceOptions,
        allocatedSize: Int,
        heap: LinuxMTLHeap?,
        heapOffset: Int
    ) {
        self.owningDevice = device
        self.resourceOptions = options
        self.allocatedSize = allocatedSize
        self.owningHeap = heap
        self.heapOffsetValue = heapOffset
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
    private(set) var lastModifiedRange: Range<Int> = 0..<0

    init(
        device: LinuxMTLDevice,
        length: Int,
        options: MTLResourceOptions,
        storage: UnsafeMutableRawPointer,
        ownsStorage: Bool,
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?,
        heap: LinuxMTLHeap?,
        heapOffset: Int
    ) {
        self.length = length
        self.gpuAddress = UInt64(UInt(bitPattern: storage))
        self.storage = storage
        self.ownsStorage = ownsStorage
        self.deallocator = deallocator
        super.init(device: device, options: options, allocatedSize: length, heap: heap, heapOffset: heapOffset)
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

    func didModifyRange(_ range: Range<Int>) {
        lastModifiedRange = range
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
        guard MetalCPULayout.isValidTextureDescriptor(descriptor) else { return nil }
        return LinuxMTLTexture(
            device: owningDevice,
            descriptor: descriptor,
            storage: storage.advanced(by: offset),
            ownsStorage: false,
            parentBuffer: self,
            bufferOffset: offset,
            bufferBytesPerRow: bytesPerRow,
            heap: owningHeap,
            heapOffset: heapOffsetValue + offset
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
    var parent: (any MTLTexture)?
    var parentRelativeLevel: Int
    var parentRelativeSlice: Int
    let buffer: (any MTLBuffer)?
    let bufferOffset: Int
    let bufferBytesPerRow: Int
    let gpuResourceID: MTLResourceID
    let firstMipmapInTail: Int = 0
    let tailSizeInBytes: Int = 0
    let sparseTextureTier: MTLTextureSparseTier = .tierNone
    let storage: UnsafeMutableRawPointer
    private let ownsStorage: Bool
    let bytesPerPixel: Int?
    var mipLevels: [MetalCPUMipLevel]
    var sliceCount: Int

    var rootResource: (any MTLResource)? { buffer ?? parent }

    init(
        device: LinuxMTLDevice,
        descriptor: MTLTextureDescriptor,
        storage: UnsafeMutableRawPointer,
        ownsStorage: Bool,
        parentBuffer: (any MTLBuffer)?,
        bufferOffset: Int,
        bufferBytesPerRow: Int,
        heap: LinuxMTLHeap?,
        heapOffset: Int
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
        self.parent = nil
        self.parentRelativeLevel = 0
        self.parentRelativeSlice = 0
        self.sliceCount = metalSliceCount(
            textureType: descriptor.textureType,
            arrayLength: descriptor.arrayLength
        )
        let pixelBytes = self.bytesPerPixel ?? 4
        self.mipLevels = MetalCPULayout.levels(
            width: descriptor.width,
            height: descriptor.height,
            depth: descriptor.depth,
            mipmapLevelCount: descriptor.mipmapLevelCount,
            arrayLength: descriptor.arrayLength,
            sampleCount: descriptor.sampleCount,
            bytesPerPixel: pixelBytes,
            textureType: descriptor.textureType
        ).levels
        super.init(
            device: device,
            options: metalResourceOptions(from: descriptor),
            allocatedSize: LinuxMTLTexture.storageByteCount(descriptor: descriptor),
            heap: heap,
            heapOffset: heapOffset
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
        return MetalCPULayout.levels(
            width: descriptor.width,
            height: descriptor.height,
            depth: descriptor.depth,
            mipmapLevelCount: descriptor.mipmapLevelCount,
            arrayLength: descriptor.arrayLength,
            sampleCount: descriptor.sampleCount,
            bytesPerPixel: pixelBytes,
            textureType: descriptor.textureType
        ).total
    }

    func mipLevel(_ level: Int) -> MetalCPUMipLevel? {
        guard level >= 0, level < mipLevels.count else { return nil }
        return mipLevels[level]
    }

    func sliceOffset(level: Int, slice: Int) -> Int? {
        guard let mip = mipLevel(level), slice >= 0, slice < sliceCount else { return nil }
        let sliceBytes = mip.bytesPerImage * max(mip.depth, 1) * max(sampleCount, 1)
        return mip.offset + slice * sliceBytes
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
        copyRegion(
            region,
            level: level,
            slice: slice,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerImage,
            from: pixelBytes,
            toStorage: true
        )
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
        copyRegion(
            region,
            level: level,
            slice: slice,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerImage,
            from: pixelBytes,
            toStorage: false
        )
    }

    func makeTextureView(pixelFormat: MTLPixelFormat) -> (any MTLTexture)? {
        makeTextureView(
            pixelFormat: pixelFormat,
            textureType: textureType,
            levels: 0..<mipmapLevelCount,
            slices: 0..<sliceCount,
            swizzle: swizzle
        )
    }

    func makeTextureView(
        pixelFormat: MTLPixelFormat,
        textureType: MTLTextureType,
        levels levelRange: Range<Int>,
        slices sliceRange: Range<Int>
    ) -> (any MTLTexture)? {
        makeTextureView(
            pixelFormat: pixelFormat,
            textureType: textureType,
            levels: levelRange,
            slices: sliceRange,
            swizzle: swizzle
        )
    }

    func makeTextureView(
        pixelFormat: MTLPixelFormat,
        textureType: MTLTextureType,
        levels levelRange: Range<Int>,
        slices sliceRange: Range<Int>,
        swizzle: MTLTextureSwizzleChannels
    ) -> (any MTLTexture)? {
        guard metalPixelFormatsAreViewCompatible(pixelFormat, self.pixelFormat) else { return nil }
        guard !levelRange.isEmpty, !sliceRange.isEmpty else { return nil }
        guard levelRange.lowerBound >= 0, levelRange.upperBound <= mipmapLevelCount else { return nil }
        guard sliceRange.lowerBound >= 0, sliceRange.upperBound <= sliceCount else { return nil }
        return LinuxMTLTexture(
            viewOf: self,
            pixelFormat: pixelFormat,
            textureType: textureType,
            levels: levelRange,
            slices: sliceRange,
            swizzle: swizzle
        )
    }

    func newTextureView(with descriptor: MTLTextureViewDescriptor) -> (any MTLTexture)? {
        let format = descriptor.pixelFormat == .invalid ? pixelFormat : descriptor.pixelFormat
        let type = descriptor.textureType
        return makeTextureView(
            pixelFormat: format,
            textureType: type,
            levels: descriptor.levelRange,
            slices: descriptor.sliceRange,
            swizzle: descriptor.swizzle
        )
    }

    convenience init(
        viewOf parentTexture: LinuxMTLTexture,
        pixelFormat: MTLPixelFormat,
        textureType: MTLTextureType,
        levels: Range<Int>,
        slices: Range<Int>,
        swizzle: MTLTextureSwizzleChannels
    ) {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = textureType
        descriptor.pixelFormat = pixelFormat
        let baseLevel = levels.lowerBound
        let levelCount = max(levels.count, 1)
        let parentMip = parentTexture.mipLevel(baseLevel)
        descriptor.width = parentMip?.width ?? max(parentTexture.width >> baseLevel, 1)
        descriptor.height = parentMip?.height ?? max(parentTexture.height >> baseLevel, 1)
        descriptor.depth = textureType == .type3D ? (parentMip?.depth ?? parentTexture.depth) : 1
        descriptor.mipmapLevelCount = levelCount
        descriptor.arrayLength = textureType == .typeCube ? 1 : max(slices.count, 1)
        descriptor.sampleCount = parentTexture.sampleCount
        descriptor.usage = parentTexture.usage.union(.pixelFormatView)
        descriptor.swizzle = swizzle
        descriptor.storageMode = parentTexture.storageMode
        descriptor.cpuCacheMode = parentTexture.cpuCacheMode
        descriptor.hazardTrackingMode = parentTexture.hazardTrackingMode
        descriptor.resourceOptions = parentTexture.resourceOptions
        self.init(
            device: parentTexture.owningDevice,
            descriptor: descriptor,
            storage: parentTexture.storage,
            ownsStorage: false,
            parentBuffer: parentTexture.buffer,
            bufferOffset: parentTexture.bufferOffset,
            bufferBytesPerRow: parentTexture.bufferBytesPerRow,
            heap: parentTexture.owningHeap,
            heapOffset: parentTexture.heapOffsetValue
        )
        self.parent = parentTexture
        self.parentRelativeLevel = levels.lowerBound
        self.parentRelativeSlice = slices.lowerBound
        if parentTexture.mipLevel(baseLevel) != nil {
            var shifted: [MetalCPUMipLevel] = []
            for index in 0..<levelCount {
                let parentLevel = baseLevel + index
                guard let mip = parentTexture.mipLevel(parentLevel) else { continue }
                let sliceBytes = mip.bytesPerImage * max(mip.depth, 1) * max(parentTexture.sampleCount, 1)
                shifted.append(
                    MetalCPUMipLevel(
                        width: mip.width,
                        height: mip.height,
                        depth: mip.depth,
                        offset: mip.offset + slices.lowerBound * sliceBytes,
                        bytesPerRow: mip.bytesPerRow,
                        bytesPerImage: mip.bytesPerImage
                    )
                )
            }
            if !shifted.isEmpty {
                self.mipLevels = shifted
            }
        }
        self.sliceCount = slices.count
    }

    func generateMipmapsBoxFilter() {
        guard bytesPerPixel != nil, mipmapLevelCount > 1 else { return }
        for level in 1..<mipmapLevelCount {
            guard let src = mipLevel(level - 1), let dst = mipLevel(level) else { continue }
            for slice in 0..<sliceCount {
                guard let srcOffset = sliceOffset(level: level - 1, slice: slice),
                      let dstOffset = sliceOffset(level: level, slice: slice)
                else { continue }
                MetalCPUPixels.boxFilter(
                    format: pixelFormat,
                    source: UnsafeRawPointer(storage.advanced(by: srcOffset)),
                    sourceWidth: src.width,
                    sourceHeight: src.height,
                    sourceBytesPerRow: src.bytesPerRow,
                    destination: storage.advanced(by: dstOffset),
                    destWidth: dst.width,
                    destHeight: dst.height,
                    destBytesPerRow: dst.bytesPerRow
                )
            }
        }
    }

    func clearLevelZero(color: MTLClearColor) {
        guard let mip = mipLevel(0) else { return }
        let pixels = mip.width * mip.height * max(mip.depth, 1) * sliceCount * max(sampleCount, 1)
        MetalCPUPixels.writeClear(color, format: pixelFormat, to: storage.advanced(by: mip.offset), pixelCount: pixels)
    }

    func clearLevelZero(depth: Double) {
        guard pixelFormat == .depth32Float, let mip = mipLevel(0) else { return }
        let count = mip.width * mip.height * mip.depth * sliceCount * max(sampleCount, 1)
        MetalCPUPixels.writeDepth(depth, to: storage.advanced(by: mip.offset), pixelCount: count)
    }

    private func copyRegion(
        _ region: MTLRegion,
        level: Int,
        slice: Int,
        bytesPerRow: Int,
        bytesPerImage: Int = 0,
        from pointer: UnsafeRawPointer,
        toStorage: Bool
    ) {
        guard let bytesPerPixel,
              let mip = mipLevel(level),
              let base = sliceOffset(level: level, slice: slice)
        else { return }
        let origin = region.origin
        let size = region.size
        guard origin.x >= 0, origin.y >= 0, origin.z >= 0,
              origin.x + size.width <= mip.width,
              origin.y + size.height <= mip.height,
              origin.z + size.depth <= mip.depth
        else { return }
        let storageRow = buffer != nil && bufferBytesPerRow > 0 ? bufferBytesPerRow : mip.bytesPerRow
        let storageImage = buffer != nil && bufferBytesPerRow > 0
            ? bufferBytesPerRow * max(mip.height, 1)
            : mip.bytesPerImage
        let imageStride = bytesPerImage > 0 ? bytesPerImage : bytesPerRow * max(size.height, 1)
        for z in 0..<max(size.depth, 1) {
            for row in 0..<max(size.height, 0) {
                let storageIndex = base
                    + (origin.z + z) * storageImage
                    + (origin.y + row) * storageRow
                    + origin.x * bytesPerPixel
                let external = pointer.advanced(by: z * imageStride + row * bytesPerRow)
                let count = max(size.width, 0) * bytesPerPixel
                if toStorage {
                    storage.advanced(by: storageIndex).copyMemory(from: external, byteCount: count)
                } else {
                    UnsafeMutableRawPointer(mutating: external).copyMemory(
                        from: storage.advanced(by: storageIndex),
                        byteCount: count
                    )
                }
            }
        }
    }
}

final class LinuxMTLHeap: NSObject, MTLHeap, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    let size: Int
    private(set) var usedSize: Int = 0
    let storageMode: MTLStorageMode
    let cpuCacheMode: MTLCPUCacheMode
    let hazardTrackingMode: MTLHazardTrackingMode
    let resourceOptions: MTLResourceOptions
    let type: MTLHeapType
    let allocatedSize: Int
    private let storage: UnsafeMutableRawPointer
    private var bump: Int = 0
    private var purgeableState: MTLPurgeableState = .nonVolatile

    var device: any MTLDevice { owningDevice }
    var currentAllocatedSize: Int { usedSize }

    init(device: LinuxMTLDevice, descriptor: MTLHeapDescriptor) {
        self.owningDevice = device
        self.size = max(descriptor.size, 0)
        self.storageMode = descriptor.storageMode
        self.cpuCacheMode = descriptor.cpuCacheMode
        self.hazardTrackingMode = descriptor.hazardTrackingMode
        self.resourceOptions = descriptor.resourceOptions
        self.type = descriptor.type
        self.allocatedSize = max(descriptor.size, 0)
        self.storage = UnsafeMutableRawPointer.allocate(byteCount: max(descriptor.size, 1), alignment: 16)
        self.storage.initializeMemory(as: UInt8.self, repeating: 0, count: max(descriptor.size, 1))
        super.init()
        device.noteAllocated(self.size)
    }

    deinit {
        owningDevice.noteFreed(size)
        storage.deallocate()
    }

    func maxAvailableSize(alignment: Int) -> Int {
        let align = max(alignment, 1)
        let aligned = (bump + align - 1) / align * align
        return max(0, size - aligned)
    }

    func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState {
        let previous = purgeableState
        if state != .keepCurrent {
            purgeableState = state
        }
        return previous
    }

    func makeBuffer(length: Int, options: MTLResourceOptions = []) -> (any MTLBuffer)? {
        makeBuffer(length: length, options: options, offset: -1)
    }

    func makeBuffer(length: Int, options: MTLResourceOptions = [], offset: Int) -> (any MTLBuffer)? {
        guard length >= 0 else { return nil }
        let placement: Int
        if offset >= 0 {
            placement = offset
            guard placement + length <= size else { return nil }
        } else {
            let aligned = (bump + 15) / 16 * 16
            guard aligned + length <= size else { return nil }
            bump = aligned + length
            usedSize = bump
            placement = aligned
        }
        return LinuxMTLBuffer(
            device: owningDevice,
            length: length,
            options: options.isEmpty ? resourceOptions : options,
            storage: storage.advanced(by: placement),
            ownsStorage: false,
            deallocator: nil,
            heap: self,
            heapOffset: placement
        )
    }

    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)? {
        makeTexture(descriptor: descriptor, offset: -1)
    }

    func makeTexture(descriptor: MTLTextureDescriptor, offset: Int) -> (any MTLTexture)? {
        guard MetalCPULayout.isValidTextureDescriptor(descriptor) else { return nil }
        let bytes = LinuxMTLTexture.storageByteCount(descriptor: descriptor)
        let placement: Int
        if offset >= 0 {
            placement = offset
            guard placement + bytes <= size else { return nil }
        } else {
            let aligned = (bump + 15) / 16 * 16
            guard aligned + bytes <= size else { return nil }
            bump = aligned + bytes
            usedSize = bump
            placement = aligned
        }
        return LinuxMTLTexture(
            device: owningDevice,
            descriptor: descriptor,
            storage: storage.advanced(by: placement),
            ownsStorage: false,
            parentBuffer: nil,
            bufferOffset: 0,
            bufferBytesPerRow: 0,
            heap: self,
            heapOffset: placement
        )
    }
}

final class LinuxMTLSamplerState: NSObject, MTLSamplerState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let gpuResourceID: MTLResourceID
    let descriptor: MTLSamplerDescriptor

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLSamplerDescriptor, resourceID: MTLResourceID) {
        self.owningDevice = device
        self.label = descriptor.label
        self.gpuResourceID = resourceID
        self.descriptor = descriptor
        super.init()
    }
}

final class LinuxMTLDepthStencilState: NSObject, MTLDepthStencilState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let gpuResourceID: MTLResourceID
    let descriptor: MTLDepthStencilDescriptor

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLDepthStencilDescriptor, resourceID: MTLResourceID) {
        self.owningDevice = device
        self.label = descriptor.label
        self.gpuResourceID = resourceID
        self.descriptor = descriptor
        super.init()
    }
}

final class LinuxMTLFence: NSObject, MTLFence, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private(set) var signaled = false

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func signal() {
        signaled = true
    }

    func wait() {
        signaled = false
    }
}

final class LinuxMTLEvent: NSObject, MTLEvent, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private(set) var value: UInt64 = 0

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func signal(_ newValue: UInt64) {
        if newValue > value {
            value = newValue
        }
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
