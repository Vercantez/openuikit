import Dispatch
import Foundation

extension MTLRenderCommandEncoder {
    public func setViewports(_ viewports: [MTLViewport]) {
        for viewport in viewports {
            setViewport(viewport)
        }
    }

    public func setScissorRects(_ scissorRects: [MTLScissorRect]) {
        for rect in scissorRects {
            setScissorRect(rect)
        }
    }

    public func setVertexBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        metalBindBuffers(buffers, offsets: offsets, range: range, binder: setVertexBuffer)
    }

    public func setVertexBuffers(
        _ buffers: [(any MTLBuffer)?],
        offsets: [Int],
        attributeStrides: [Int],
        range: Range<Int>
    ) {
        for (i, index) in range.enumerated() {
            let buffer = i < buffers.count ? buffers[i] : nil
            let offset = i < offsets.count ? offsets[i] : 0
            let stride = i < attributeStrides.count ? attributeStrides[i] : 0
            setVertexBuffer(buffer, offset: offset, attributeStride: stride, index: index)
        }
    }

    public func setFragmentBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        metalBindBuffers(buffers, offsets: offsets, range: range, binder: setFragmentBuffer)
    }

    public func setMeshBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        metalBindBuffers(buffers, offsets: offsets, range: range, binder: setMeshBuffer)
    }

    public func setTileBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        metalBindBuffers(buffers, offsets: offsets, range: range, binder: setTileBuffer)
    }

    public func setObjectBuffers(_ buffers: [(any MTLBuffer)?], offsets: [Int], range: Range<Int>) {
        metalBindBuffers(buffers, offsets: offsets, range: range, binder: setObjectBuffer)
    }

    public func setVertexTextures(_ textures: [(any MTLTexture)?], range: Range<Int>) {
        metalBindTextures(textures, range: range, binder: setVertexTexture)
    }

    public func setFragmentTextures(_ textures: [(any MTLTexture)?], range: Range<Int>) {
        metalBindTextures(textures, range: range, binder: setFragmentTexture)
    }

    public func setMeshTextures(_ textures: [(any MTLTexture)?], range: Range<Int>) {
        metalBindTextures(textures, range: range, binder: setMeshTexture)
    }

    public func setTileTextures(_ textures: [(any MTLTexture)?], range: Range<Int>) {
        metalBindTextures(textures, range: range, binder: setTileTexture)
    }

    public func setObjectTextures(_ textures: [(any MTLTexture)?], range: Range<Int>) {
        metalBindTextures(textures, range: range, binder: setObjectTexture)
    }

    public func setVertexSamplerStates(_ samplers: [(any MTLSamplerState)?], range: Range<Int>) {
        metalBindSamplers(samplers, range: range, binder: setVertexSamplerState)
    }

    public func setFragmentSamplerStates(_ samplers: [(any MTLSamplerState)?], range: Range<Int>) {
        metalBindSamplers(samplers, range: range, binder: setFragmentSamplerState)
    }

    public func setMeshSamplerStates(_ samplers: [(any MTLSamplerState)?], range: Range<Int>) {
        metalBindSamplers(samplers, range: range, binder: setMeshSamplerState)
    }

    public func setTileSamplerStates(_ samplers: [(any MTLSamplerState)?], range: Range<Int>) {
        metalBindSamplers(samplers, range: range, binder: setTileSamplerState)
    }

    public func setObjectSamplerStates(_ samplers: [(any MTLSamplerState)?], range: Range<Int>) {
        metalBindSamplers(samplers, range: range, binder: setObjectSamplerState)
    }

    public func setVertexSamplerStates(
        _ samplers: [(any MTLSamplerState)?],
        lodMinClamps: [Float],
        lodMaxClamps: [Float],
        range: Range<Int>
    ) {
        metalBindClampedSamplers(
            samplers,
            lodMinClamps: lodMinClamps,
            lodMaxClamps: lodMaxClamps,
            range: range,
            binder: setVertexSamplerState
        )
    }

    public func setFragmentSamplerStates(
        _ samplers: [(any MTLSamplerState)?],
        lodMinClamps: [Float],
        lodMaxClamps: [Float],
        range: Range<Int>
    ) {
        metalBindClampedSamplers(
            samplers,
            lodMinClamps: lodMinClamps,
            lodMaxClamps: lodMaxClamps,
            range: range,
            binder: setFragmentSamplerState
        )
    }

    public func setMeshSamplerStates(
        _ samplers: [(any MTLSamplerState)?],
        lodMinClamps: [Float],
        lodMaxClamps: [Float],
        range: Range<Int>
    ) {
        metalBindClampedSamplers(
            samplers,
            lodMinClamps: lodMinClamps,
            lodMaxClamps: lodMaxClamps,
            range: range,
            binder: setMeshSamplerState
        )
    }

    public func setTileSamplerStates(
        _ samplers: [(any MTLSamplerState)?],
        lodMinClamps: [Float],
        lodMaxClamps: [Float],
        range: Range<Int>
    ) {
        metalBindClampedSamplers(
            samplers,
            lodMinClamps: lodMinClamps,
            lodMaxClamps: lodMaxClamps,
            range: range,
            binder: setTileSamplerState
        )
    }

    public func setObjectSamplerStates(
        _ samplers: [(any MTLSamplerState)?],
        lodMinClamps: [Float],
        lodMaxClamps: [Float],
        range: Range<Int>
    ) {
        metalBindClampedSamplers(
            samplers,
            lodMinClamps: lodMinClamps,
            lodMaxClamps: lodMaxClamps,
            range: range,
            binder: setObjectSamplerState
        )
    }

    public func useResources(_ resources: [any MTLResource], usage: MTLResourceUsage) {
        for resource in resources {
            useResource(resource, usage: usage)
        }
    }

    public func useResources(_ resources: [any MTLResource], usage: MTLResourceUsage, stages: MTLRenderStages) {
        for resource in resources {
            useResource(resource, usage: usage, stages: stages)
        }
    }

    public func useHeaps(_ heaps: [any MTLHeap]) {
        for heap in heaps {
            useHeap(heap)
        }
    }

    public func useHeaps(_ heaps: [any MTLHeap], stages: MTLRenderStages) {
        for heap in heaps {
            useHeap(heap, stages: stages)
        }
    }

    public func use(_ resource: any MTLResource, usage: MTLResourceUsage, stages: MTLRenderStages) {
        useResource(resource, usage: usage, stages: stages)
    }

    public func use(_ heap: any MTLHeap, stages: MTLRenderStages) {
        useHeap(heap, stages: stages)
    }
}

extension MTLDevice {
    public func makeLibrary(data: DispatchData) throws -> any MTLLibrary {
        _ = data
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "Linux Metal cannot load Apple metallib binaries"
        )
    }

    public func makeRenderPipelineState(
        descriptor: MTLRenderPipelineDescriptor,
        options: MTLPipelineOption
    ) throws -> (any MTLRenderPipelineState, MTLRenderPipelineReflection?) {
        _ = options
        return (try makeRenderPipelineState(descriptor: descriptor), nil)
    }

    public func makeRenderPipelineState(
        descriptor: MTLMeshRenderPipelineDescriptor,
        options: MTLPipelineOption
    ) throws -> (any MTLRenderPipelineState, MTLRenderPipelineReflection?) {
        _ = (descriptor, options)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    public func makeRenderPipelineState(
        tileDescriptor: MTLTileRenderPipelineDescriptor,
        options: MTLPipelineOption
    ) throws -> (any MTLRenderPipelineState, MTLRenderPipelineReflection?) {
        _ = (tileDescriptor, options)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    public func makeComputePipelineState(
        descriptor: MTLComputePipelineDescriptor,
        options: MTLPipelineOption
    ) throws -> (any MTLComputePipelineState, MTLComputePipelineReflection?) {
        _ = options
        return (try makeComputePipelineState(descriptor: descriptor), nil)
    }

    public func sampleTimestamps() -> (cpu: UInt64, gpu: UInt64) {
        let nanoseconds = UInt64((ProcessInfo.processInfo.systemUptime * 1_000_000_000).rounded())
        return (cpu: nanoseconds, gpu: nanoseconds)
    }

    public func sparseTileSize(
        with textureType: MTLTextureType,
        pixelFormat: MTLPixelFormat,
        sampleCount: Int
    ) -> MTLSize {
        _ = (textureType, pixelFormat, sampleCount)
        return MTLSize()
    }

    public func sparseTileSize(
        with textureType: MTLTextureType,
        pixelFormat: MTLPixelFormat,
        sampleCount: Int,
        sparsePageSize: MTLSparsePageSize
    ) -> MTLSize {
        _ = (textureType, pixelFormat, sampleCount, sparsePageSize)
        return MTLSize()
    }

    public func accelerationStructureSizes(descriptor: MTLAccelerationStructureDescriptor) -> MTLAccelerationStructureSizes {
        _ = descriptor
        return MTLAccelerationStructureSizes()
    }

    public var counterSets: [any MTLCounterSet]? { [] }

    public func queryTimestampFrequency() -> UInt64 {
        1_000_000_000
    }

    public func makeCommandAllocator() -> (any MTL4CommandAllocator)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTL4CommandAllocator(device: linux, label: nil)
    }

    public func makeCommandAllocator(descriptor: MTL4CommandAllocatorDescriptor) throws -> any MTL4CommandAllocator {
        guard let linux = self as? LinuxMTLDevice else {
            throw metalUnsupportedLibraryError(.unsupported, reason: "no Metal 4 command allocator")
        }
        return LinuxMTL4CommandAllocator(device: linux, label: descriptor.label)
    }

    public func makeCommandBuffer() -> (any MTL4CommandBuffer)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTL4CommandBuffer(device: linux)
    }

    public func makeMTL4CommandQueue() -> (any MTL4CommandQueue)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTL4CommandQueue(device: linux, label: nil)
    }

    public func makeMTL4CommandQueue(descriptor: MTL4CommandQueueDescriptor) throws -> any MTL4CommandQueue {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTL4CommandQueueError(.notPermitted, userInfo: [NSLocalizedDescriptionKey: "no Metal 4 queue"])
        }
        return LinuxMTL4CommandQueue(device: linux, label: descriptor.label)
    }

    public func makeArgumentTable(descriptor: MTL4ArgumentTableDescriptor) throws -> any MTL4ArgumentTable {
        guard let linux = self as? LinuxMTLDevice else {
            throw metalUnsupportedLibraryError(.unsupported, reason: "no argument table")
        }
        return LinuxMTL4ArgumentTable(device: linux, descriptor: descriptor)
    }

    public func makeCompiler(descriptor: MTL4CompilerDescriptor) throws -> any MTL4Compiler {
        guard let linux = self as? LinuxMTLDevice else {
            throw metalUnsupportedLibraryError(.unsupported, reason: "no Metal 4 compiler")
        }
        return LinuxMTL4Compiler(
            device: linux,
            label: descriptor.label,
            pipelineDataSetSerializer: descriptor.pipelineDataSetSerializer
        )
    }

    public func makeCounterHeap(descriptor: MTL4CounterHeapDescriptor) throws -> any MTL4CounterHeap {
        guard descriptor.type == .timestamp, descriptor.count >= 0 else {
            throw MTLCPUValidationError("CPU reference counter heap requires timestamp type")
        }
        return LinuxMTL4CounterHeap(count: descriptor.count, type: descriptor.type)
    }

    public func size(ofCounterHeapEntry type: MTL4CounterHeapType) -> Int {
        type == .timestamp ? MemoryLayout<UInt64>.size : 0
    }

    public func makeArchive(url: URL) throws -> any MTL4Archive {
        _ = url
        throw metalUnsupportedLibraryError(.fileNotFound, reason: "no Metal 4 pipeline archive")
    }

    public func makePipelineDataSetSerializer(
        descriptor: MTL4PipelineDataSetSerializerDescriptor
    ) -> any MTL4PipelineDataSetSerializer {
        LinuxMTL4PipelineDataSetSerializer(configuration: descriptor.configuration)
    }

    public func makeAccelerationStructure(size: Int) -> (any MTLAccelerationStructure)? {
        guard let linux = self as? LinuxMTLDevice else { return nil }
        return LinuxMTLAccelerationStructure(device: linux, size: size)
    }

    public func makeAccelerationStructure(descriptor: MTLAccelerationStructureDescriptor) -> (any MTLAccelerationStructure)? {
        _ = descriptor
        return makeAccelerationStructure(size: 0)
    }

    public func heapAccelerationStructureSizeAndAlign(size: Int) -> MTLSizeAndAlign {
        MTLSizeAndAlign(size: max(size, 0), align: 16)
    }

    public func heapAccelerationStructureSizeAndAlign(descriptor: MTLAccelerationStructureDescriptor) -> MTLSizeAndAlign {
        _ = descriptor
        return MTLSizeAndAlign(size: 0, align: 16)
    }

    public func makeIOCommandQueue(descriptor: MTLIOCommandQueueDescriptor) throws -> any MTLIOCommandQueue {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLIOError(.internal, userInfo: [NSLocalizedDescriptionKey: "Linux has no Metal IO command processor"])
        }
        return LinuxMTLIOCommandQueue(device: linux, descriptor: descriptor)
    }

    public func makeIOFileHandle(url: URL) throws -> any MTLIOFileHandle {
        _ = url
        throw MTLIOError(
            .internal,
            userInfo: [NSLocalizedDescriptionKey: "Linux has no Metal IO command processor"]
        )
    }

    public func makeIOFileHandle(url: URL, compressionMethod: MTLIOCompressionMethod) throws -> any MTLIOFileHandle {
        _ = compressionMethod
        return try makeIOFileHandle(url: url)
    }

    public func makeIOHandle(url: URL) throws -> any MTLIOFileHandle {
        try makeIOFileHandle(url: url)
    }

    public func makeIOHandle(url: URL, compressionMethod: MTLIOCompressionMethod) throws -> any MTLIOFileHandle {
        try makeIOFileHandle(url: url, compressionMethod: compressionMethod)
    }

    public func makeCounterSampleBuffer(descriptor: MTLCounterSampleBufferDescriptor) throws -> any MTLCounterSampleBuffer {
        guard let linux = self as? LinuxMTLDevice else {
            throw MTLCounterSampleBufferError(
                .internal,
                userInfo: [NSLocalizedDescriptionKey: "CPU reference has no GPU counter sample buffers"]
            )
        }
        guard descriptor.sampleCount >= 0 else {
            throw MTLCounterSampleBufferError(
                .invalid,
                userInfo: [NSLocalizedDescriptionKey: "sampleCount must be >= 0"]
            )
        }
        return LinuxMTLCounterSampleBuffer(device: linux, descriptor: descriptor)
    }

    public func makeLibrary(
        source: String,
        options: MTLCompileOptions?,
        completionHandler: @escaping MTLNewLibraryCompletionHandler
    ) {
        do {
            let library = try makeLibrary(source: source, options: options)
            completionHandler(library, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    public func makeLibrary(stitchedDescriptor: MTLStitchedLibraryDescriptor) throws -> any MTLLibrary {
        _ = stitchedDescriptor
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    public func makeLibrary(
        stitchedDescriptor: MTLStitchedLibraryDescriptor,
        completionHandler: @escaping MTLNewLibraryCompletionHandler
    ) {
        do {
            let library = try makeLibrary(stitchedDescriptor: stitchedDescriptor)
            completionHandler(library, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    public func makeRenderPipelineState(
        descriptor: MTLRenderPipelineDescriptor,
        completionHandler: @escaping MTLNewRenderPipelineStateCompletionHandler
    ) {
        do {
            let state = try makeRenderPipelineState(descriptor: descriptor)
            completionHandler(state, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    public func makeComputePipelineState(
        function: any MTLFunction,
        completionHandler: @escaping MTLNewComputePipelineStateCompletionHandler
    ) {
        do {
            let state = try makeComputePipelineState(function: function)
            completionHandler(state, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    public func convertSparsePixelRegions(
        _ pixelRegions: UnsafePointer<MTLRegion>,
        toTileRegions tileRegions: UnsafeMutablePointer<MTLRegion>,
        withTileSize tileSize: MTLSize,
        alignmentMode mode: MTLSparseTextureRegionAlignmentMode,
        numRegions: Int
    ) {
        _ = mode
        for index in 0..<numRegions {
            let pixel = pixelRegions[index]
            if tileSize.width <= 0 || tileSize.height <= 0 {
                tileRegions[index] = MTLRegion()
                continue
            }
            let x = pixel.origin.x / tileSize.width
            let y = pixel.origin.y / tileSize.height
            let w = (pixel.size.width + tileSize.width - 1) / tileSize.width
            let h = (pixel.size.height + tileSize.height - 1) / tileSize.height
            tileRegions[index] = MTLRegionMake2D(x, y, w, h)
        }
    }

    public func convertSparseTileRegions(
        _ tileRegions: UnsafePointer<MTLRegion>,
        toPixelRegions pixelRegions: UnsafeMutablePointer<MTLRegion>,
        withTileSize tileSize: MTLSize,
        numRegions: Int
    ) {
        for index in 0..<numRegions {
            let tile = tileRegions[index]
            pixelRegions[index] = MTLRegionMake2D(
                tile.origin.x * max(tileSize.width, 0),
                tile.origin.y * max(tileSize.height, 0),
                tile.size.width * max(tileSize.width, 0),
                tile.size.height * max(tileSize.height, 0)
            )
        }
    }
}

open class MTLAccelerationStructureDescriptor: NSObject, @unchecked Sendable {
    public var usage: MTLAccelerationStructureUsage = []

    public override init() {
        super.init()
    }
}

private func metalBindBuffers(
    _ buffers: [(any MTLBuffer)?],
    offsets: [Int],
    range: Range<Int>,
    binder: ((any MTLBuffer)?, Int, Int) -> Void
) {
    for (i, index) in range.enumerated() {
        let buffer = i < buffers.count ? buffers[i] : nil
        let offset = i < offsets.count ? offsets[i] : 0
        binder(buffer, offset, index)
    }
}

private func metalBindTextures(
    _ textures: [(any MTLTexture)?],
    range: Range<Int>,
    binder: ((any MTLTexture)?, Int) -> Void
) {
    for (i, index) in range.enumerated() {
        let texture = i < textures.count ? textures[i] : nil
        binder(texture, index)
    }
}

private func metalBindSamplers(
    _ samplers: [(any MTLSamplerState)?],
    range: Range<Int>,
    binder: ((any MTLSamplerState)?, Int) -> Void
) {
    for (i, index) in range.enumerated() {
        let sampler = i < samplers.count ? samplers[i] : nil
        binder(sampler, index)
    }
}

private func metalBindClampedSamplers(
    _ samplers: [(any MTLSamplerState)?],
    lodMinClamps: [Float],
    lodMaxClamps: [Float],
    range: Range<Int>,
    binder: ((any MTLSamplerState)?, Float, Float, Int) -> Void
) {
    for (i, index) in range.enumerated() {
        let sampler = i < samplers.count ? samplers[i] : nil
        let lodMin = i < lodMinClamps.count ? lodMinClamps[i] : 0
        let lodMax = i < lodMaxClamps.count ? lodMaxClamps[i] : 0
        binder(sampler, lodMin, lodMax, index)
    }
}
