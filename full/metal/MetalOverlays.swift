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
