import Foundation

/// Fail-closed / compile-only types referenced by the CPU-reference encoder
/// and pipeline surface. None of these execute GPU, ray-tracing, tensor, or
/// Metal 4 work.

public protocol MTLAccelerationStructure: MTLResource {}

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
}

public protocol MTLResidencySet: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get set }
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
    public override init() {
        super.init()
    }
}

open class MTL4RenderPipelineBinaryFunctionsDescriptor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
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

open class LinuxMTLDrawable: NSObject, MTLDrawable, @unchecked Sendable {
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
