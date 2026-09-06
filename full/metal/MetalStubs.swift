import Foundation

/// Fail-closed / compile-only types referenced by the CPU-reference encoder
/// and pipeline surface. None of these execute GPU, ray-tracing, tensor, or
/// Metal 4 work.

public protocol MTLAccelerationStructure: MTLResource {
    var gpuResourceID: MTLResourceID { get }
    var size: Int { get }
}

public protocol MTLVisibleFunctionTable: MTLResource {
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLIntersectionFunctionTable: MTLResource {
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLCounterSampleBuffer: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var sampleCount: Int { get }
    func resolveCounterRange(_ range: Range<Int>) throws -> Data?
}

public protocol MTLResidencySet: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    var allocatedSize: UInt64 { get }
    var allocationCount: Int { get }
    var allAllocations: [any MTLAllocation] { get }
    func addAllocation(_ allocation: any MTLAllocation)
    func removeAllocation(_ allocation: any MTLAllocation)
    func addAllocations(_ allocations: [any MTLAllocation])
    func removeAllocations(_ allocations: [any MTLAllocation])
    func containsAllocation(_ anAllocation: any MTLAllocation) -> Bool
    func removeAllAllocations()
    func commit()
    func requestResidency()
    func endResidency()
}

public protocol MTLResourceStateCommandEncoder: MTLCommandEncoder {
    func update(_ fence: any MTLFence)
    func wait(for fence: any MTLFence)
    func updateTextureMapping(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        region: MTLRegion,
        mipLevel: Int,
        slice: Int
    )
    func updateTextureMapping(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    )
    func updateTextureMappings(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        regions: UnsafePointer<MTLRegion>,
        mipLevels: UnsafePointer<Int>,
        slices: UnsafePointer<Int>,
        numRegions: Int
    )
    func moveTextureMappings(
        sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    )
}

public protocol MTLParallelRenderCommandEncoder: MTLCommandEncoder {
    func makeRenderCommandEncoder() -> (any MTLRenderCommandEncoder)?
    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int)
    func setColorStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions, index colorAttachmentIndex: Int)
    func setDepthStoreAction(_ storeAction: MTLStoreAction)
    func setDepthStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions)
    func setStencilStoreAction(_ storeAction: MTLStoreAction)
    func setStencilStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions)
}

public protocol MTLFunctionHandle: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var name: String { get }
    var functionType: MTLFunctionType { get }
    var gpuResourceID: MTLResourceID { get }
}

public protocol MTLTensor: MTLResource {
    var gpuResourceID: MTLResourceID { get }
    var buffer: (any MTLBuffer)? { get }
    var bufferOffset: Int { get }
    var dataType: MTLTensorDataType { get }
    var dimensions: MTLTensorExtents { get }
    var strides: MTLTensorExtents? { get }
    var usage: MTLTensorUsage { get }
    func getBytes(
        _ bytes: UnsafeMutableRawPointer,
        strides: MTLTensorExtents,
        sliceOrigin: MTLTensorExtents,
        sliceDimensions: MTLTensorExtents
    )
    func replace(
        sliceOrigin: MTLTensorExtents,
        sliceDimensions: MTLTensorExtents,
        withBytes bytes: UnsafeRawPointer,
        strides: MTLTensorExtents
    )
}

public protocol MTLBinaryArchive: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func addComputePipelineFunctions(descriptor: MTLComputePipelineDescriptor) throws
    func addRenderPipelineFunctions(descriptor: MTLRenderPipelineDescriptor) throws
    func serialize(to url: URL) throws
}

public protocol MTLBinding: NSObjectProtocol, Sendable {
    var name: String { get }
    var index: Int { get }
    var type: MTLBindingType { get }
    var access: MTLBindingAccess { get }
    var isUsed: Bool { get }
    var isArgument: Bool { get }
}

public protocol MTLBufferBinding: MTLBinding {
    var bufferAlignment: Int { get }
    var bufferDataSize: Int { get }
    var bufferDataType: MTLDataType { get }
}

public protocol MTL4BinaryFunction: NSObjectProtocol, Sendable {}

open class MTL4PipelineDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var options: MTL4PipelineOptions?

    public override init() {
        super.init()
    }
}

open class MTL4PipelineOptions: NSObject, @unchecked Sendable {
    public var shaderReflection: MTL4ShaderReflection = []
    public var shaderValidation: MTLShaderValidation = .default

    public override init() {
        super.init()
    }
}

open class MTL4RenderPipelineBinaryFunctionsDescriptor: NSObject, @unchecked Sendable {
    public var fragmentAdditionalBinaryFunctions: [any MTL4BinaryFunction]?
    public var meshAdditionalBinaryFunctions: [any MTL4BinaryFunction]?
    public var objectAdditionalBinaryFunctions: [any MTL4BinaryFunction]?
    public var tileAdditionalBinaryFunctions: [any MTL4BinaryFunction]?
    public var vertexAdditionalBinaryFunctions: [any MTL4BinaryFunction]?

    public override init() {
        super.init()
    }

    public func reset() {
        fragmentAdditionalBinaryFunctions = nil
        meshAdditionalBinaryFunctions = nil
        objectAdditionalBinaryFunctions = nil
        tileAdditionalBinaryFunctions = nil
        vertexAdditionalBinaryFunctions = nil
    }
}

public protocol MTLIndirectComputeCommand: NSObjectProtocol {
    func reset()
    func setComputePipelineState(_ pipelineState: any MTLComputePipelineState)
    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int)
    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, at index: Int)
    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, index: Int)
    func concurrentDispatchThreadgroups(_ threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func concurrentDispatchThreads(_ threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func setBarrier()
    func clearBarrier()
    func setImageblockWidth(_ width: Int, height: Int)
    func setStageInRegion(_ region: MTLRegion)
    func setThreadgroupMemoryLength(_ length: Int, index: Int)
}

public protocol MTLIndirectRenderCommand: NSObjectProtocol {
    func reset()
    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState)
    func setVertexBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int)
    func setVertexBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, at index: Int)
    func setFragmentBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int)
    func setMeshBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int)
    func setObjectBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int)
    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int)
    func setCullMode(_ cullMode: MTLCullMode)
    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float)
    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode)
    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?)
    func setFrontFacing(_ frontFacingWindning: MTLWinding)
    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode)
    func setBarrier()
    func clearBarrier()
    func drawPrimitives(
        _ primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    )
    func drawIndexedPrimitives(
        _ primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    )
    func drawPatches(
        _ numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int,
        tessellationFactorBuffer buffer: any MTLBuffer,
        tessellationFactorBufferOffset offset: Int,
        tessellationFactorBufferInstanceStride instanceStride: Int
    )
    func drawIndexedPatches(
        _ numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int,
        tessellationFactorBuffer buffer: any MTLBuffer,
        tessellationFactorBufferOffset offset: Int,
        tessellationFactorBufferInstanceStride instanceStride: Int
    )
    func drawMeshThreadgroups(
        _ threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawMeshThreads(
        _ threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
}

public final class LinuxMTLDrawable: NSObject, MTLDrawable, @unchecked Sendable {
    public var drawableID: Int = 0
    public var presentedTime: CFTimeInterval = 0
    private var handlers: [MTLDrawablePresentedHandler] = []

    public func present() {
        presentedTime = ProcessInfo.processInfo.systemUptime
        for handler in handlers {
            handler(self)
        }
    }

    public func present(at presentationTime: CFTimeInterval) {
        presentedTime = presentationTime
        for handler in handlers {
            handler(self)
        }
    }

    public func present(afterMinimumDuration duration: CFTimeInterval) {
        _ = duration
        present()
    }

    public func addPresentedHandler(_ block: @escaping MTLDrawablePresentedHandler) {
        handlers.append(block)
    }
}

public protocol MTLAccelerationStructureCommandEncoder: MTLCommandEncoder {
    func build(
        accelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        scratchBuffer: any MTLBuffer,
        scratchBufferOffset: Int
    )
    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: (any MTLBuffer)?,
        scratchBufferOffset: Int
    )
    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTLAccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: (any MTLBuffer)?,
        scratchBufferOffset: Int,
        options: MTLAccelerationStructureRefitOptions
    )
    func copy(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    )
    func copyAndCompact(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    )
    func writeCompactedSize(
        accelerationStructure: any MTLAccelerationStructure,
        buffer: any MTLBuffer,
        offset: Int
    )
    func writeCompactedSize(
        accelerationStructure: any MTLAccelerationStructure,
        buffer: any MTLBuffer,
        offset: Int,
        sizeDataType: MTLDataType
    )
    func updateFence(_ fence: any MTLFence)
    func waitForFence(_ fence: any MTLFence)
    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage)
    func useHeap(_ heap: any MTLHeap)
    func sampleCounters(sampleBuffer: any MTLCounterSampleBuffer, sampleIndex: Int, barrier: Bool)
}

public protocol MTLRasterizationRateMap: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var screenSize: MTLSize { get }
    var physicalGranularity: MTLSize { get }
    var layerCount: Int { get }
    var parameterBufferSizeAndAlign: MTLSizeAndAlign { get }
    func physicalSize(layer layerIndex: Int) -> MTLSize
    func screenCoordinates(physicalCoordinates: MTLCoordinate2D, layer layerIndex: Int) -> MTLCoordinate2D
    func physicalCoordinates(screenCoordinates: MTLCoordinate2D, layer layerIndex: Int) -> MTLCoordinate2D
    func copyParameterData(buffer: any MTLBuffer, offset: Int)
}

public protocol MTLResourceViewPool: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var resourceViewCount: Int { get }
    var baseResourceID: MTLResourceID { get }
    func copyResourceViews(
        from sourcePool: any MTLResourceViewPool,
        sourceRange: Range<Int>,
        destinationIndex: Int
    ) -> MTLResourceID
}

public protocol MTLTextureViewPool: MTLResourceViewPool {
    func setTextureView(texture: any MTLTexture, index: Int) -> MTLResourceID
    func setTextureView(texture: any MTLTexture, descriptor: MTLTextureViewDescriptor, index: Int) -> MTLResourceID
    func setTextureView(
        buffer: any MTLBuffer,
        descriptor: MTLTextureDescriptor,
        offset: Int,
        bytesPerRow: Int,
        index: Int
    ) -> MTLResourceID
}
