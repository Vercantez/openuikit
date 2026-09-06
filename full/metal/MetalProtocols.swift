import Foundation

public protocol MTLAllocation: NSObjectProtocol {
    var allocatedSize: Int { get }
}

public protocol MTLResource: MTLAllocation {
    var device: any MTLDevice { get }
    var cpuCacheMode: MTLCPUCacheMode { get }
    var storageMode: MTLStorageMode { get }
    var hazardTrackingMode: MTLHazardTrackingMode { get }
    var resourceOptions: MTLResourceOptions { get }
    var heap: (any MTLHeap)? { get }
    var heapOffset: Int { get }
    var label: String? { get set }
    func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState
    func makeAliasable()
    func isAliasable() -> Bool
}

public protocol MTLBuffer: MTLResource {
    var length: Int { get }
    var gpuAddress: MTLGPUAddress { get }
    var sparseBufferTier: MTLBufferSparseTier { get }
    func contents() -> UnsafeMutableRawPointer
    func didModifyRange(_ range: Range<Int>)
    func addDebugMarker(_ marker: String, range: Range<Int>)
    func removeAllDebugMarkers()
    func makeTexture(descriptor: MTLTextureDescriptor, offset: Int, bytesPerRow: Int) -> (any MTLTexture)?
}

public protocol MTLTexture: MTLResource {
    var textureType: MTLTextureType { get }
    var pixelFormat: MTLPixelFormat { get }
    var width: Int { get }
    var height: Int { get }
    var depth: Int { get }
    var mipmapLevelCount: Int { get }
    var sampleCount: Int { get }
    var arrayLength: Int { get }
    var usage: MTLTextureUsage { get }
    var isFramebufferOnly: Bool { get }
    var isShareable: Bool { get }
    var isSparse: Bool { get }
    var allowGPUOptimizedContents: Bool { get }
    var compressionType: MTLTextureCompressionType { get }
    var swizzle: MTLTextureSwizzleChannels { get }
    var parent: (any MTLTexture)? { get }
    var parentRelativeLevel: Int { get }
    var parentRelativeSlice: Int { get }
    var buffer: (any MTLBuffer)? { get }
    var bufferOffset: Int { get }
    var bufferBytesPerRow: Int { get }
    var rootResource: (any MTLResource)? { get }
    var gpuResourceID: MTLResourceID { get }
    var firstMipmapInTail: Int { get }
    var tailSizeInBytes: Int { get }
    var sparseTextureTier: MTLTextureSparseTier { get }
    func replace(region: MTLRegion, mipmapLevel level: Int, withBytes pixelBytes: UnsafeRawPointer, bytesPerRow: Int)
    func replace(
        region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int,
        withBytes pixelBytes: UnsafeRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int
    )
    func getBytes(_ pixelBytes: UnsafeMutableRawPointer, bytesPerRow: Int, from region: MTLRegion, mipmapLevel level: Int)
    func getBytes(
        _ pixelBytes: UnsafeMutableRawPointer,
        bytesPerRow: Int,
        bytesPerImage: Int,
        from region: MTLRegion,
        mipmapLevel level: Int,
        slice: Int
    )
    func makeTextureView(pixelFormat: MTLPixelFormat) -> (any MTLTexture)?
    func makeTextureView(
        pixelFormat: MTLPixelFormat,
        textureType: MTLTextureType,
        levels levelRange: Range<Int>,
        slices sliceRange: Range<Int>
    ) -> (any MTLTexture)?
    func makeTextureView(
        pixelFormat: MTLPixelFormat,
        textureType: MTLTextureType,
        levels levelRange: Range<Int>,
        slices sliceRange: Range<Int>,
        swizzle: MTLTextureSwizzleChannels
    ) -> (any MTLTexture)?
    func newTextureView(with descriptor: MTLTextureViewDescriptor) -> (any MTLTexture)?
}

public protocol MTLHeap: MTLAllocation {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var size: Int { get }
    var usedSize: Int { get }
    var currentAllocatedSize: Int { get }
    var storageMode: MTLStorageMode { get }
    var cpuCacheMode: MTLCPUCacheMode { get }
    var hazardTrackingMode: MTLHazardTrackingMode { get }
    var resourceOptions: MTLResourceOptions { get }
    var type: MTLHeapType { get }
    func maxAvailableSize(alignment: Int) -> Int
    func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState
    func makeBuffer(length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeBuffer(length: Int, options: MTLResourceOptions, offset: Int) -> (any MTLBuffer)?
    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)?
    func makeTexture(descriptor: MTLTextureDescriptor, offset: Int) -> (any MTLTexture)?
}

public protocol MTLCommandEncoder: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func endEncoding()
    func insertDebugSignpost(_ string: String)
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages)
}

public protocol MTLBlitCommandEncoder: MTLCommandEncoder {
    func fill(buffer: any MTLBuffer, range: Range<Int>, value: UInt8)
    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    )
    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    )
    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin,
        options: MTLBlitOption
    )
    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        destinationBytesPerRow: Int,
        destinationBytesPerImage: Int
    )
    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        destinationBytesPerRow: Int,
        destinationBytesPerImage: Int,
        options: MTLBlitOption
    )
    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    )
    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        sliceCount: Int,
        levelCount: Int
    )
    func copy(from sourceTexture: any MTLTexture, to destinationTexture: any MTLTexture)
    func generateMipmaps(for texture: any MTLTexture)
    func optimizeContentsForCPUAccess(texture: any MTLTexture)
    func optimizeContentsForCPUAccess(texture: any MTLTexture, slice: Int, level: Int)
    func optimizeContentsForGPUAccess(texture: any MTLTexture)
    func optimizeContentsForGPUAccess(texture: any MTLTexture, slice: Int, level: Int)
    func updateFence(_ fence: any MTLFence)
    func waitForFence(_ fence: any MTLFence)
    func resetCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>)
    func copyIndirectCommandBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        sourceRange: Range<Int>,
        destination: any MTLIndirectCommandBuffer,
        destinationIndex: Int
    )
    func optimizeIndirectCommandBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>)
}

public protocol MTLComputeCommandEncoder: MTLCommandEncoder {
    var dispatchType: MTLDispatchType { get }
    func setComputePipelineState(_ state: any MTLComputePipelineState)
    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, index: Int)
    func setBufferOffset(_ offset: Int, index: Int)
    func setBufferOffset(offset: Int, attributeStride stride: Int, index: Int)
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, attributeStride stride: Int, index: Int)
    func setTexture(_ texture: (any MTLTexture)?, index: Int)
    func setSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setThreadgroupMemoryLength(_ length: Int, index: Int)
    func setImageblockWidth(_ width: Int, height: Int)
    func setStageInRegion(_ region: MTLRegion)
    func setStageInRegionWithIndirectBuffer(_ indirectBuffer: any MTLBuffer, indirectBufferOffset: Int)
    func dispatchThreadgroups(_ threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func dispatchThreadgroups(indirectBuffer: any MTLBuffer, indirectBufferOffset: Int, threadsPerThreadgroup: MTLSize)
    func dispatchThreads(_ threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func memoryBarrier(scope: MTLBarrierScope)
    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage)
    func useHeap(_ heap: any MTLHeap)
    func updateFence(_ fence: any MTLFence)
    func waitForFence(_ fence: any MTLFence)
    func executeCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>)
    func executeCommandsInBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        offset: Int
    )
    func executeCommands(in indirectCommandBuffer: any MTLIndirectCommandBuffer, with executionRange: NSRange)
    func executeCommands(
        in indirectCommandbuffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    )
}

public protocol MTLRenderCommandEncoder: MTLCommandEncoder {
    var tileWidth: Int { get }
    var tileHeight: Int { get }
    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState)
    func setVertexBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setVertexBuffer(_ buffer: (any MTLBuffer)?, offset: Int, attributeStride stride: Int, index: Int)
    func setVertexBufferOffset(_ offset: Int, index: Int)
    func setVertexBufferOffset(offset: Int, attributeStride stride: Int, index: Int)
    func setVertexBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setVertexBytes(_ bytes: UnsafeRawPointer, length: Int, attributeStride stride: Int, index: Int)
    func setVertexTexture(_ texture: (any MTLTexture)?, index: Int)
    func setVertexSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setVertexSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setFragmentBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setFragmentBufferOffset(_ offset: Int, index: Int)
    func setFragmentBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setFragmentTexture(_ texture: (any MTLTexture)?, index: Int)
    func setFragmentSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setFragmentSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setViewport(_ viewport: MTLViewport)
    func setScissorRect(_ rect: MTLScissorRect)
    func setCullMode(_ cullMode: MTLCullMode)
    func setFrontFacing(_ frontFacingWinding: MTLWinding)
    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode)
    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float)
    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?)
    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode)
    func setBlendColor(red: Float, green: Float, blue: Float, alpha: Float)
    func setStencilReferenceValue(_ referenceValue: UInt32)
    func setStencilReferenceValues(front frontReferenceValue: UInt32, back backReferenceValue: UInt32)
    func setVisibilityResultMode(_ mode: MTLVisibilityResultMode, offset: Int)
    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int)
    func setColorStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions, index colorAttachmentIndex: Int)
    func setDepthStoreAction(_ storeAction: MTLStoreAction)
    func setDepthStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions)
    func setStencilStoreAction(_ storeAction: MTLStoreAction)
    func setStencilStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions)
    func drawPrimitives(type primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int)
    func drawPrimitives(type primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int, instanceCount: Int)
    func drawPrimitives(
        type primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    )
    func drawPrimitives(type primitiveType: MTLPrimitiveType, indirectBuffer: any MTLBuffer, indirectBufferOffset: Int)
    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int
    )
    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int
    )
    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    )
    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    )
    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage)
    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage, stages: MTLRenderStages)
    func useHeap(_ heap: any MTLHeap)
    func useHeap(_ heap: any MTLHeap, stages: MTLRenderStages)
    func updateFence(_ fence: any MTLFence, after stages: MTLRenderStages)
    func waitForFence(_ fence: any MTLFence, before stages: MTLRenderStages)
    func memoryBarrier(scope: MTLBarrierScope, after: MTLRenderStages, before: MTLRenderStages)
    func executeCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>)
    func executeCommandsInBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        offset: Int
    )
    func setMeshBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setMeshBufferOffset(_ offset: Int, index: Int)
    func setMeshBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setMeshTexture(_ texture: (any MTLTexture)?, index: Int)
    func setMeshSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setMeshSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setObjectBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setObjectBufferOffset(_ offset: Int, index: Int)
    func setObjectBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setObjectTexture(_ texture: (any MTLTexture)?, index: Int)
    func setObjectSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setObjectSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int)
    func setTileBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setTileBufferOffset(_ offset: Int, index: Int)
    func setTileBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int)
    func setTileTexture(_ texture: (any MTLTexture)?, index: Int)
    func setTileSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setTileSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int)
    func setThreadgroupMemoryLength(_ length: Int, offset: Int, index: Int)
    func setTessellationFactorBuffer(_ buffer: (any MTLBuffer)?, offset: Int, instanceStride: Int)
    func setTessellationFactorScale(_ scale: Float)
    func setDepthTestBounds(_ bounds: ClosedRange<Float>)
    func dispatchThreadsPerTile(_ threadsPerTile: MTLSize)
    func drawMeshThreadgroups(
        _ threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawMeshThreadgroups(
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawMeshThreads(
        _ threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawPatches(
        numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int
    )
    func drawPatches(
        numberOfPatchControlPoints: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    )
    func drawIndexedPatches(
        numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int
    )
    func drawIndexedPatches(
        numberOfPatchControlPoints: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    )
    func memoryBarrier(resources: [any MTLResource], after: MTLRenderStages, before: MTLRenderStages)
}

public protocol MTLCommandQueue: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func makeCommandBuffer() -> (any MTLCommandBuffer)?
    func makeCommandBuffer(descriptor: MTLCommandBufferDescriptor) -> (any MTLCommandBuffer)?
    func makeCommandBufferWithUnretainedReferences() -> (any MTLCommandBuffer)?
    func insertDebugCaptureBoundary()
}

public protocol MTLCommandBuffer: NSObjectProtocol {
    var device: any MTLDevice { get }
    var commandQueue: any MTLCommandQueue { get }
    var retainedReferences: Bool { get }
    var errorOptions: MTLCommandBufferErrorOption { get }
    var label: String? { get set }
    var status: MTLCommandBufferStatus { get }
    var error: (any Error)? { get }
    var kernelStartTime: TimeInterval { get }
    var kernelEndTime: TimeInterval { get }
    var gpuStartTime: TimeInterval { get }
    var gpuEndTime: TimeInterval { get }
    var logs: MTLLogContainer { get }
    func enqueue()
    func commit()
    func addScheduledHandler(_ block: @escaping MTLCommandBufferHandler)
    func addCompletedHandler(_ block: @escaping MTLCommandBufferHandler)
    func waitUntilScheduled()
    func waitUntilCompleted()
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func present(_ drawable: any MTLDrawable)
    func present(_ drawable: any MTLDrawable, atTime presentationTime: CFTimeInterval)
    func present(_ drawable: any MTLDrawable, afterMinimumDuration duration: CFTimeInterval)
    func encodeSignalEvent(_ event: any MTLEvent, value: UInt64)
    func encodeWaitForEvent(_ event: any MTLEvent, value: UInt64)
    func makeBlitCommandEncoder() -> (any MTLBlitCommandEncoder)?
    func makeBlitCommandEncoder(descriptor blitPassDescriptor: MTLBlitPassDescriptor) -> (any MTLBlitCommandEncoder)?
    func makeComputeCommandEncoder() -> (any MTLComputeCommandEncoder)?
    func makeComputeCommandEncoder(dispatchType: MTLDispatchType) -> (any MTLComputeCommandEncoder)?
    func makeComputeCommandEncoder(descriptor computePassDescriptor: MTLComputePassDescriptor) -> (any MTLComputeCommandEncoder)?
    func makeRenderCommandEncoder(descriptor renderPassDescriptor: MTLRenderPassDescriptor) -> (any MTLRenderCommandEncoder)?
    func makeParallelRenderCommandEncoder(descriptor renderPassDescriptor: MTLRenderPassDescriptor) -> (any MTLParallelRenderCommandEncoder)?
    func makeResourceStateCommandEncoder() -> (any MTLResourceStateCommandEncoder)?
    func resourceStateCommandEncoder(with resourceStatePassDescriptor: MTLResourceStatePassDescriptor) -> (any MTLResourceStateCommandEncoder)?
}

public protocol MTLDevice: NSObjectProtocol, Sendable {
    var name: String { get }
    var registryID: UInt64 { get }
    var architecture: MTLArchitecture { get }
    var maxThreadsPerThreadgroup: MTLSize { get }
    var hasUnifiedMemory: Bool { get }
    var recommendedMaxWorkingSetSize: UInt64 { get }
    var currentAllocatedSize: Int { get }
    var maxBufferLength: Int { get }
    var maxThreadgroupMemoryLength: Int { get }
    var maxArgumentBufferSamplerCount: Int { get }
    var argumentBuffersSupport: MTLArgumentBuffersTier { get }
    var readWriteTextureSupport: MTLReadWriteTextureTier { get }
    var areBarycentricCoordsSupported: Bool { get }
    var areRasterOrderGroupsSupported: Bool { get }
    var areProgrammableSamplePositionsSupported: Bool { get }
    var sparseTileSizeInBytes: Int { get }
    var supports32BitFloatFiltering: Bool { get }
    var supports32BitMSAA: Bool { get }
    var supportsBCTextureCompression: Bool { get }
    var supportsPullModelInterpolation: Bool { get }
    var supportsShaderBarycentricCoordinates: Bool { get }
    var supportsQueryTextureLOD: Bool { get }
    var supportsFunctionPointers: Bool { get }
    var supportsFunctionPointersFromRender: Bool { get }
    var supportsRaytracing: Bool { get }
    var supportsRaytracingFromRender: Bool { get }
    var supportsPrimitiveMotionBlur: Bool { get }
    var supportsDynamicLibraries: Bool { get }
    var supportsRenderDynamicLibraries: Bool { get }
    var maximumConcurrentCompilationTaskCount: Int { get }
    func supportsFamily(_ gpuFamily: MTLGPUFamily) -> Bool
    func supportsFeatureSet(_ featureSet: MTLFeatureSet) -> Bool
    func supportsTextureSampleCount(_ sampleCount: Int) -> Bool
    func supportsVertexAmplificationCount(_ count: Int) -> Bool
    func supportsRasterizationRateMap(layerCount: Int) -> Bool
    func supportsCounterSampling(_ samplingPoint: MTLCounterSamplingPoint) -> Bool
    func minimumLinearTextureAlignment(for format: MTLPixelFormat) -> Int
    func minimumTextureBufferAlignment(for format: MTLPixelFormat) -> Int
    func heapBufferSizeAndAlign(length: Int, options: MTLResourceOptions) -> MTLSizeAndAlign
    func heapTextureSizeAndAlign(descriptor desc: MTLTextureDescriptor) -> MTLSizeAndAlign
    func makeCommandQueue() -> (any MTLCommandQueue)?
    func makeCommandQueue(maxCommandBufferCount: Int) -> (any MTLCommandQueue)?
    func makeCommandQueue(descriptor: MTLCommandQueueDescriptor) -> (any MTLCommandQueue)?
    func makeBuffer(length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeBuffer(bytes pointer: UnsafeRawPointer, length: Int, options: MTLResourceOptions) -> (any MTLBuffer)?
    func makeBuffer(
        bytesNoCopy pointer: UnsafeMutableRawPointer,
        length: Int,
        options: MTLResourceOptions,
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?
    ) -> (any MTLBuffer)?
    func makeTexture(descriptor: MTLTextureDescriptor) -> (any MTLTexture)?
    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> (any MTLSamplerState)?
    func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> (any MTLDepthStencilState)?
    func makeHeap(descriptor: MTLHeapDescriptor) -> (any MTLHeap)?
    func makeDefaultLibrary() -> (any MTLLibrary)?
    func makeDefaultLibrary(bundle: Bundle) throws -> any MTLLibrary
    func makeLibrary(source: String, options: MTLCompileOptions?) throws -> any MTLLibrary
    func makeLibrary(URL url: URL) throws -> any MTLLibrary
    func makeLibrary(filepath: String) throws -> any MTLLibrary
    func makeComputePipelineState(function computeFunction: any MTLFunction) throws -> any MTLComputePipelineState
    func makeComputePipelineState(descriptor: MTLComputePipelineDescriptor) throws -> any MTLComputePipelineState
    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> any MTLRenderPipelineState
    func makeEvent() -> (any MTLEvent)?
    func makeFence() -> (any MTLFence)?
    func makeSharedEvent() -> (any MTLSharedEvent)?
    func makeSharedEvent(handle sharedEventHandle: MTLSharedEventHandle) -> (any MTLSharedEvent)?
    func makeArgumentEncoder(arguments: [MTLArgumentDescriptor]) -> (any MTLArgumentEncoder)?
    func makeIndirectCommandBuffer(
        descriptor: MTLIndirectCommandBufferDescriptor,
        maxCommandCount maxCount: Int,
        options: MTLResourceOptions
    ) -> (any MTLIndirectCommandBuffer)?
    func getDefaultSamplePositions(sampleCount: Int) -> [MTLSamplePosition]
}

public protocol MTLLibrary: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var functionNames: [String] { get }
    var type: MTLLibraryType { get }
    var installName: String? { get }
    func makeFunction(name functionName: String) -> (any MTLFunction)?
    func makeFunction(descriptor: MTLFunctionDescriptor) throws -> any MTLFunction
    func makeFunction(name: String, constantValues: MTLFunctionConstantValues) throws -> any MTLFunction
    func reflection(functionName: String) -> MTLFunctionReflection?
}

public protocol MTLFunction: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var functionType: MTLFunctionType { get }
    var name: String { get }
    var label: String? { get set }
    var options: MTLFunctionOptions { get }
    var patchType: MTLPatchType { get }
    var patchControlPointCount: Int { get }
    var vertexAttributes: [MTLVertexAttribute]? { get }
    var stageInputAttributes: [MTLAttribute]? { get }
    var functionConstantsDictionary: [String: MTLFunctionConstant] { get }
    func makeArgumentEncoder(bufferIndex: Int) -> any MTLArgumentEncoder
}

public protocol MTLSamplerState: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLDepthStencilState: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLRenderPipelineState: MTLAllocation, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
    var maxTotalThreadsPerThreadgroup: Int { get }
    var threadExecutionWidth: Int { get }
    var imageblockSampleLength: Int { get }
    var supportIndirectCommandBuffers: Bool { get }
    var shaderValidation: MTLShaderValidation { get }
    var maxTotalThreadgroupsPerMeshGrid: Int { get }
    var maxTotalThreadsPerMeshThreadgroup: Int { get }
    var maxTotalThreadsPerObjectThreadgroup: Int { get }
    var meshThreadExecutionWidth: Int { get }
    var objectThreadExecutionWidth: Int { get }
    var requiredThreadsPerMeshThreadgroup: MTLSize { get }
    var requiredThreadsPerObjectThreadgroup: MTLSize { get }
    var requiredThreadsPerTileThreadgroup: MTLSize { get }
    var threadgroupSizeMatchesTileSize: Bool { get }
    func imageblockMemoryLength(forDimensions imageblockDimensions: MTLSize) -> Int
    func makeRenderPipelineState(
        additionalBinaryFunctions binaryFunctionsDescriptor: MTL4RenderPipelineBinaryFunctionsDescriptor
    ) throws -> any MTLRenderPipelineState
    func makeRenderPipelineState(
        additionalBinaryFunctions: MTLRenderPipelineFunctionsDescriptor
    ) throws -> any MTLRenderPipelineState
    func makeRenderPipelineDescriptorForSpecialization() -> MTL4PipelineDescriptor
}

public protocol MTLComputePipelineState: MTLAllocation, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var gpuResourceID: MTLResourceID { get }
    var maxTotalThreadsPerThreadgroup: Int { get }
    var threadExecutionWidth: Int { get }
    var staticThreadgroupMemoryLength: Int { get }
    var supportIndirectCommandBuffers: Bool { get }
    var shaderValidation: MTLShaderValidation { get }
    var requiredThreadsPerThreadgroup: MTLSize { get }
    func imageblockMemoryLength(forDimensions imageblockDimensions: MTLSize) -> Int
}

public protocol MTLDrawable: NSObjectProtocol {
    var drawableID: Int { get }
    var presentedTime: CFTimeInterval { get }
    func present()
    func present(at presentationTime: CFTimeInterval)
    func present(afterMinimumDuration duration: CFTimeInterval)
    func addPresentedHandler(_ block: @escaping MTLDrawablePresentedHandler)
}

public protocol MTLFence: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTLEvent: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
}

public protocol MTLSharedEvent: MTLEvent {
    var signaledValue: UInt64 { get set }
    func makeSharedEventHandle() -> MTLSharedEventHandle
    func notify(_ listener: MTLSharedEventListener, atValue value: UInt64, block: @escaping MTLSharedEventNotificationBlock)
    func wait(untilSignaledValue value: UInt64, timeoutMS milliseconds: UInt64) -> Bool
}

public protocol MTLCaptureScope: NSObjectProtocol {
    var device: (any MTLDevice)? { get }
    var commandQueue: (any MTLCommandQueue)? { get }
    var label: String? { get set }
    func begin()
    func end()
}

public protocol MTLDynamicLibrary: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var installName: String { get }
}

public protocol MTLLogState: NSObjectProtocol, Sendable {}

public protocol MTLFunctionLog: NSObjectProtocol {}

public protocol MTLCounterSet: NSObjectProtocol {
    var name: String { get }
}

public protocol MTLArgumentEncoder: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var encodedLength: Int { get }
    var alignment: Int { get }
    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, offset: Int)
    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, startOffset: Int, arrayElement: Int)
    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int)
    func setTexture(_ texture: (any MTLTexture)?, index: Int)
    func setSamplerState(_ sampler: (any MTLSamplerState)?, index: Int)
    func setRenderPipelineState(_ pipeline: (any MTLRenderPipelineState)?, index: Int)
    func setComputePipelineState(_ pipeline: (any MTLComputePipelineState)?, index: Int)
    func setIndirectCommandBuffer(_ indirectCommandBuffer: (any MTLIndirectCommandBuffer)?, index: Int)
    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?, index: Int)
    func constantData(at index: Int) -> UnsafeMutableRawPointer
    func makeArgumentEncoderForBuffer(atIndex index: Int) -> (any MTLArgumentEncoder)?
}

public protocol MTLIndirectCommandBuffer: MTLResource {
    var size: Int { get }
    var gpuResourceID: MTLResourceID { get }
    func indirectComputeCommandAt(_ commandIndex: Int) -> any MTLIndirectComputeCommand
    func indirectRenderCommandAt(_ commandIndex: Int) -> any MTLIndirectRenderCommand
}

public enum MTLCounterSamplingPoint: UInt, Equatable, Hashable, Sendable {
    case atStageBoundary = 0
    case atDrawBoundary = 1
    case atDispatchBoundary = 2
    case atTileDispatchBoundary = 3
    case atBlitBoundary = 4
}

public struct MTLLogContainer: Sendable {
    public struct Iterator: IteratorProtocol {
        public typealias Element = any MTLFunctionLog

        public mutating func next() -> (any MTLFunctionLog)? {
            nil
        }
    }

    public func makeIterator() -> Iterator {
        Iterator()
    }
}

open class MTLCaptureManager: NSObject, @unchecked Sendable {
    private static let instance = MTLCaptureManager()
    private var capturing = false
    public var defaultCaptureScope: (any MTLCaptureScope)?

    public var isCapturing: Bool { capturing }

    public class func shared() -> MTLCaptureManager {
        instance
    }

    public func supportsDestination(_ destination: MTLCaptureDestination) -> Bool {
        _ = destination
        return false
    }

    public func startCapture(with descriptor: MTLCaptureDescriptor) throws {
        _ = descriptor
        throw MTLCaptureError.notSupported
    }

    public func startCapture(device: any MTLDevice) {
        _ = device
    }

    public func startCapture(commandQueue: any MTLCommandQueue) {
        _ = commandQueue
    }

    public func startCapture(scope captureScope: any MTLCaptureScope) {
        _ = captureScope
    }

    public func stopCapture() {
        capturing = false
    }

    public func makeCaptureScope(device: any MTLDevice) -> any MTLCaptureScope {
        LinuxMTLCaptureScope(device: device, commandQueue: nil)
    }

    public func makeCaptureScope(commandQueue: any MTLCommandQueue) -> any MTLCaptureScope {
        LinuxMTLCaptureScope(device: commandQueue.device, commandQueue: commandQueue)
    }

    public func makeCaptureScope(commandQueue: any MTL4CommandQueue) -> any MTLCaptureScope {
        LinuxMTLCaptureScope(device: commandQueue.device, commandQueue: nil)
    }
}
