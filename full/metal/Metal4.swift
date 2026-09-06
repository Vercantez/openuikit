import Dispatch
import Foundation

/// Metal 4 descriptors, argument tables, and a CPU command stream that
/// records encoder state, runs byte-exact copies, and fail-closes GPU work.

public typealias MTL4CommitFeedbackHandler = (any MTL4CommitFeedback) -> Void

open class MTL4FunctionDescriptor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class MTL4LibraryFunctionDescriptor: MTL4FunctionDescriptor, @unchecked Sendable {
    public var name: String?
    public var library: (any MTLLibrary)?
}

open class MTL4SpecializedFunctionDescriptor: MTL4FunctionDescriptor, @unchecked Sendable {
    public var functionDescriptor: MTL4FunctionDescriptor?
    public var specializedName: String?
    public var constantValues: MTLFunctionConstantValues?
}

open class MTL4StaticLinkingDescriptor: NSObject, @unchecked Sendable {
    public var functionDescriptors: [MTL4FunctionDescriptor]?
    public var privateFunctionDescriptors: [MTL4FunctionDescriptor]?
    public var groups: [String: [MTL4FunctionDescriptor]]?
}

open class MTL4LibraryDescriptor: NSObject, @unchecked Sendable {
    public var source: String?
    public var name: String?
    public var options: MTLCompileOptions?
}

open class MTL4CompilerDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var pipelineDataSetSerializer: (any MTL4PipelineDataSetSerializer)?
}

open class MTL4CompilerTaskOptions: NSObject, @unchecked Sendable {
    public var lookupArchives: [any MTL4Archive]?
}

open class MTL4BinaryFunctionDescriptor: NSObject, @unchecked Sendable {
    public var functionDescriptor = MTL4FunctionDescriptor()
    public var name: String = ""
    public var options: MTL4BinaryFunctionOptions = []
}

open class MTL4CounterHeapDescriptor: NSObject, @unchecked Sendable {
    public var count: Int = 0
    public var type: MTL4CounterHeapType = .invalid
}

open class MTL4PipelineDataSetSerializerDescriptor: NSObject, @unchecked Sendable {
    public var configuration: MTL4PipelineDataSetSerializerConfiguration = []
}

open class MTL4AccelerationStructureDescriptor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class MTL4AccelerationStructureGeometryDescriptor: NSObject, @unchecked Sendable {
    public var intersectionFunctionTableOffset: Int = 0
    public var opaque: Bool = false
    public var allowDuplicateIntersectionFunctionInvocation: Bool = true
    public var label: String?
    public var primitiveDataBuffer = MTL4BufferRange()
    public var primitiveDataStride: Int = 0
    public var primitiveDataElementSize: Int = 0

    public override init() {
        super.init()
    }
}

open class MTL4AccelerationStructureCurveGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var controlPointBuffer = MTL4BufferRange()
    public var controlPointCount: Int = 0
    public var controlPointStride: Int = 0
    public var controlPointFormat: MTLAttributeFormat = .float3
    public var radiusBuffer = MTL4BufferRange()
    public var radiusFormat: MTLAttributeFormat = .float
    public var radiusStride: Int = 0
    public var indexBuffer = MTL4BufferRange()
    public var indexType: MTLIndexType = .uint16
    public var segmentCount: Int = 0
    public var segmentControlPointCount: Int = 0
    public var curveType: MTLCurveType = .round
    public var curveBasis: MTLCurveBasis = .bSpline
    public var curveEndCaps: MTLCurveEndCaps = .none
}

open class MTL4AccelerationStructureMotionCurveGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var controlPointBuffers = MTL4BufferRange()
    public var controlPointCount: Int = 0
    public var controlPointStride: Int = 0
    public var controlPointFormat: MTLAttributeFormat = .float3
    public var radiusBuffers = MTL4BufferRange()
    public var radiusFormat: MTLAttributeFormat = .float
    public var radiusStride: Int = 0
    public var indexBuffer = MTL4BufferRange()
    public var indexType: MTLIndexType = .uint16
    public var segmentCount: Int = 0
    public var segmentControlPointCount: Int = 0
    public var curveType: MTLCurveType = .round
    public var curveBasis: MTLCurveBasis = .bSpline
    public var curveEndCaps: MTLCurveEndCaps = .none
}

open class MTL4AccelerationStructureTriangleGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var vertexBuffer = MTL4BufferRange()
    public var vertexFormat: MTLAttributeFormat = .float3
    public var vertexStride: Int = 0
    public var indexBuffer = MTL4BufferRange()
    public var indexType: MTLIndexType = .uint16
    public var triangleCount: Int = 0
    public var transformationMatrixBuffer = MTL4BufferRange()
    public var transformationMatrixLayout: MTLMatrixLayout = .columnMajor
}

open class MTL4AccelerationStructureMotionTriangleGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var vertexBuffers = MTL4BufferRange()
    public var vertexFormat: MTLAttributeFormat = .float3
    public var vertexStride: Int = 0
    public var indexBuffer = MTL4BufferRange()
    public var indexType: MTLIndexType = .uint16
    public var triangleCount: Int = 0
    public var transformationMatrixBuffer = MTL4BufferRange()
    public var transformationMatrixLayout: MTLMatrixLayout = .columnMajor
}

open class MTL4AccelerationStructureBoundingBoxGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var boundingBoxBuffer = MTL4BufferRange()
    public var boundingBoxCount: Int = 0
    public var boundingBoxStride: Int = 0
}

open class MTL4AccelerationStructureMotionBoundingBoxGeometryDescriptor: MTL4AccelerationStructureGeometryDescriptor, @unchecked Sendable {
    public var boundingBoxBuffers = MTL4BufferRange()
    public var boundingBoxCount: Int = 0
    public var boundingBoxStride: Int = 0
}

open class MTL4PrimitiveAccelerationStructureDescriptor: MTL4AccelerationStructureDescriptor, @unchecked Sendable {
    public var geometryDescriptors: [MTL4AccelerationStructureGeometryDescriptor]?
    public var motionStartBorderMode: MTLMotionBorderMode = .clamp
    public var motionEndBorderMode: MTLMotionBorderMode = .clamp
    public var motionStartTime: Float = 0
    public var motionEndTime: Float = 1
    public var motionKeyframeCount: Int = 1
}

open class MTL4InstanceAccelerationStructureDescriptor: MTL4AccelerationStructureDescriptor, @unchecked Sendable {
    public var instanceDescriptorBuffer = MTL4BufferRange()
    public var instanceDescriptorStride: Int = 0
    public var instanceDescriptorType: MTLAccelerationStructureInstanceDescriptorType = .default
    public var instanceCount: Int = 0
    public var instanceTransformationMatrixLayout: MTLMatrixLayout = .columnMajor
    public var motionTransformBuffer = MTL4BufferRange()
    public var motionTransformStride: Int = 0
    public var motionTransformType: MTLTransformType = .packedFloat4x3
    public var motionTransformCount: Int = 0
}

open class MTL4IndirectInstanceAccelerationStructureDescriptor: MTL4AccelerationStructureDescriptor, @unchecked Sendable {
    public var instanceDescriptorBuffer = MTL4BufferRange()
    public var instanceDescriptorStride: Int = 0
    public var instanceDescriptorType: MTLAccelerationStructureInstanceDescriptorType = .indirect
    public var maxInstanceCount: Int = 0
    public var instanceCountBuffer = MTL4BufferRange()
    public var instanceTransformationMatrixLayout: MTLMatrixLayout = .columnMajor
    public var motionTransformBuffer = MTL4BufferRange()
    public var motionTransformStride: Int = 0
    public var motionTransformType: MTLTransformType = .packedFloat4x3
    public var maxMotionTransformCount: Int = 0
    public var motionTransformCountBuffer = MTL4BufferRange()
}

open class MTL4RenderPipelineColorAttachmentDescriptor: NSObject, @unchecked Sendable {
    public var pixelFormat: MTLPixelFormat = .invalid
    public var blendingState: MTL4BlendState = .disabled
    public var sourceRGBBlendFactor: MTLBlendFactor = .one
    public var destinationRGBBlendFactor: MTLBlendFactor = .zero
    public var rgbBlendOperation: MTLBlendOperation = .add
    public var sourceAlphaBlendFactor: MTLBlendFactor = .one
    public var destinationAlphaBlendFactor: MTLBlendFactor = .zero
    public var alphaBlendOperation: MTLBlendOperation = .add
    public var writeMask: MTLColorWriteMask = .all

    public override init() {
        super.init()
    }

    public func reset() {
        pixelFormat = .invalid
        blendingState = .disabled
        sourceRGBBlendFactor = .one
        destinationRGBBlendFactor = .zero
        rgbBlendOperation = .add
        sourceAlphaBlendFactor = .one
        destinationAlphaBlendFactor = .zero
        alphaBlendOperation = .add
        writeMask = .all
    }
}

open class MTL4RenderPipelineColorAttachmentDescriptorArray: NSObject, @unchecked Sendable {
    private var storage: [Int: MTL4RenderPipelineColorAttachmentDescriptor] = [:]

    public override init() {
        super.init()
    }

    public subscript(attachmentIndex: Int) -> MTL4RenderPipelineColorAttachmentDescriptor! {
        get {
            if let existing = storage[attachmentIndex] {
                return existing
            }
            let created = MTL4RenderPipelineColorAttachmentDescriptor()
            storage[attachmentIndex] = created
            return created
        }
        set {
            storage[attachmentIndex] = newValue
        }
    }

    public func reset() {
        storage.removeAll()
    }
}

open class MTL4RenderPipelineDescriptor: MTL4PipelineDescriptor, @unchecked Sendable {
    public var vertexFunctionDescriptor: MTL4FunctionDescriptor?
    public var fragmentFunctionDescriptor: MTL4FunctionDescriptor?
    public var vertexDescriptor: MTLVertexDescriptor?
    public let colorAttachments = MTL4RenderPipelineColorAttachmentDescriptorArray()
    public var rasterSampleCount: Int = 1
    public var alphaToCoverageState: MTL4AlphaToCoverageState = .disabled
    public var alphaToOneState: MTL4AlphaToOneState = .disabled
    public var isRasterizationEnabled: Bool = true
    public var maxVertexAmplificationCount: Int = 1
    public var inputPrimitiveTopology: MTLPrimitiveTopologyClass = .unspecified
    public var supportIndirectCommandBuffers: MTL4IndirectCommandBufferSupportState = .disabled
    public var supportVertexBinaryLinking: Bool = false
    public var supportFragmentBinaryLinking: Bool = false
    public var colorAttachmentMappingState: MTL4LogicalToPhysicalColorAttachmentMappingState = .identity
    public var vertexStaticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()
    public var fragmentStaticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()

    public func reset() {
        label = nil
        options = nil
        vertexFunctionDescriptor = nil
        fragmentFunctionDescriptor = nil
        vertexDescriptor = nil
        rasterSampleCount = 1
        alphaToCoverageState = .disabled
        alphaToOneState = .disabled
        isRasterizationEnabled = true
        maxVertexAmplificationCount = 1
        inputPrimitiveTopology = .unspecified
        supportIndirectCommandBuffers = .disabled
        supportVertexBinaryLinking = false
        supportFragmentBinaryLinking = false
        colorAttachmentMappingState = .identity
        vertexStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        fragmentStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        colorAttachments.reset()
    }
}

open class MTL4MeshRenderPipelineDescriptor: MTL4PipelineDescriptor, @unchecked Sendable {
    public var objectFunctionDescriptor: MTL4FunctionDescriptor?
    public var meshFunctionDescriptor: MTL4FunctionDescriptor?
    public var fragmentFunctionDescriptor: MTL4FunctionDescriptor?
    public let colorAttachments = MTL4RenderPipelineColorAttachmentDescriptorArray()
    public var rasterSampleCount: Int = 1
    public var alphaToCoverageState: MTL4AlphaToCoverageState = .disabled
    public var alphaToOneState: MTL4AlphaToOneState = .disabled
    public var isRasterizationEnabled: Bool = true
    public var maxVertexAmplificationCount: Int = 1
    public var maxTotalThreadsPerObjectThreadgroup: Int = 0
    public var maxTotalThreadsPerMeshThreadgroup: Int = 0
    public var maxTotalThreadgroupsPerMeshGrid: Int = 0
    public var payloadMemoryLength: Int = 0
    public var objectThreadgroupSizeIsMultipleOfThreadExecutionWidth: Bool = false
    public var meshThreadgroupSizeIsMultipleOfThreadExecutionWidth: Bool = false
    public var requiredThreadsPerObjectThreadgroup = MTLSize()
    public var requiredThreadsPerMeshThreadgroup = MTLSize()
    public var supportIndirectCommandBuffers: MTL4IndirectCommandBufferSupportState = .disabled
    public var supportObjectBinaryLinking: Bool = false
    public var supportMeshBinaryLinking: Bool = false
    public var supportFragmentBinaryLinking: Bool = false
    public var colorAttachmentMappingState: MTL4LogicalToPhysicalColorAttachmentMappingState = .identity
    public var objectStaticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()
    public var meshStaticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()
    public var fragmentStaticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()

    public func reset() {
        label = nil
        options = nil
        objectFunctionDescriptor = nil
        meshFunctionDescriptor = nil
        fragmentFunctionDescriptor = nil
        rasterSampleCount = 1
        alphaToCoverageState = .disabled
        alphaToOneState = .disabled
        isRasterizationEnabled = true
        maxVertexAmplificationCount = 1
        maxTotalThreadsPerObjectThreadgroup = 0
        maxTotalThreadsPerMeshThreadgroup = 0
        maxTotalThreadgroupsPerMeshGrid = 0
        payloadMemoryLength = 0
        objectThreadgroupSizeIsMultipleOfThreadExecutionWidth = false
        meshThreadgroupSizeIsMultipleOfThreadExecutionWidth = false
        requiredThreadsPerObjectThreadgroup = MTLSize()
        requiredThreadsPerMeshThreadgroup = MTLSize()
        supportIndirectCommandBuffers = .disabled
        supportObjectBinaryLinking = false
        supportMeshBinaryLinking = false
        supportFragmentBinaryLinking = false
        colorAttachmentMappingState = .identity
        objectStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        meshStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        fragmentStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        colorAttachments.reset()
    }
}

open class MTL4ComputePipelineDescriptor: MTL4PipelineDescriptor, @unchecked Sendable {
    public var computeFunctionDescriptor: MTL4FunctionDescriptor?
    public var maxTotalThreadsPerThreadgroup: Int = 0
    public var requiredThreadsPerThreadgroup = MTLSize()
    public var threadGroupSizeIsMultipleOfThreadExecutionWidth: Bool = false
    public var supportIndirectCommandBuffers: MTL4IndirectCommandBufferSupportState = .disabled
    public var supportBinaryLinking: Bool = false
    public var staticLinkingDescriptor: MTL4StaticLinkingDescriptor?

    public func reset() {
        label = nil
        options = nil
        computeFunctionDescriptor = nil
        maxTotalThreadsPerThreadgroup = 0
        requiredThreadsPerThreadgroup = MTLSize()
        threadGroupSizeIsMultipleOfThreadExecutionWidth = false
        supportIndirectCommandBuffers = .disabled
        supportBinaryLinking = false
        staticLinkingDescriptor = nil
    }
}

open class MTL4TileRenderPipelineDescriptor: MTL4PipelineDescriptor, @unchecked Sendable {
    public var tileFunctionDescriptor: MTL4FunctionDescriptor?
    public let colorAttachments = MTLTileRenderPipelineColorAttachmentDescriptorArray()
    public var rasterSampleCount: Int = 1
    public var threadgroupSizeMatchesTileSize: Bool = false
    public var maxTotalThreadsPerThreadgroup: Int = 0
    public var requiredThreadsPerThreadgroup = MTLSize()
    public var supportBinaryLinking: Bool = false
    public var staticLinkingDescriptor: MTL4StaticLinkingDescriptor! = MTL4StaticLinkingDescriptor()

    public func reset() {
        label = nil
        options = nil
        tileFunctionDescriptor = nil
        rasterSampleCount = 1
        threadgroupSizeMatchesTileSize = false
        maxTotalThreadsPerThreadgroup = 0
        requiredThreadsPerThreadgroup = MTLSize()
        supportBinaryLinking = false
        staticLinkingDescriptor = MTL4StaticLinkingDescriptor()
        for index in 0..<8 {
            colorAttachments[index].pixelFormat = .invalid
        }
    }
}

open class MTL4PipelineStageDynamicLinkingDescriptor: NSObject, @unchecked Sendable {
    public var binaryLinkedFunctions: [any MTL4BinaryFunction]?
    public var maxCallStackDepth: Int = 1
    public var preloadedLibraries: [any MTLDynamicLibrary] = []
}

open class MTL4RenderPipelineDynamicLinkingDescriptor: NSObject, @unchecked Sendable {
    public let vertexLinkingDescriptor = MTL4PipelineStageDynamicLinkingDescriptor()
    public let fragmentLinkingDescriptor = MTL4PipelineStageDynamicLinkingDescriptor()
    public let meshLinkingDescriptor = MTL4PipelineStageDynamicLinkingDescriptor()
    public let objectLinkingDescriptor = MTL4PipelineStageDynamicLinkingDescriptor()
    public let tileLinkingDescriptor = MTL4PipelineStageDynamicLinkingDescriptor()
}

open class MTL4CommandAllocatorDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
}

open class MTL4CommandBufferOptions: NSObject, @unchecked Sendable {
    public var logState: (any MTLLogState)?
}

open class MTL4CommandQueueDescriptor: NSObject, @unchecked Sendable {
    public var label: String?
    public var feedbackQueue: DispatchQueue?
}

open class MTL4CommitOptions: NSObject, @unchecked Sendable {
    var handlers: [MTL4CommitFeedbackHandler] = []

    public func addFeedbackHandler(_ block: @escaping MTL4CommitFeedbackHandler) {
        handlers.append(block)
    }
}

open class MTL4ArgumentTableDescriptor: NSObject, @unchecked Sendable {
    public var initializeBindings: Bool = false
    public var label: String?
    public var maxBufferBindCount: Int = 0
    public var maxSamplerStateBindCount: Int = 0
    public var maxTextureBindCount: Int = 0
    public var supportAttributeStrides: Bool = false
}

public struct MTL4CopySparseBufferMappingOperation: Equatable, Sendable {
    public var sourceRange: NSRange
    public var destinationOffset: Int

    public init() {
        self.sourceRange = NSRange(location: 0, length: 0)
        self.destinationOffset = 0
    }

    public init(sourceRange: NSRange, destinationOffset: Int) {
        self.sourceRange = sourceRange
        self.destinationOffset = destinationOffset
    }
}

public struct MTL4CopySparseTextureMappingOperation: Equatable, Sendable {
    public var sourceRegion: MTLRegion
    public var sourceLevel: Int
    public var sourceSlice: Int
    public var destinationOrigin: MTLOrigin
    public var destinationLevel: Int
    public var destinationSlice: Int

    public init() {
        self.sourceRegion = MTLRegion()
        self.sourceLevel = 0
        self.sourceSlice = 0
        self.destinationOrigin = MTLOrigin()
        self.destinationLevel = 0
        self.destinationSlice = 0
    }

    public init(
        sourceRegion: MTLRegion,
        sourceLevel: Int,
        sourceSlice: Int,
        destinationOrigin: MTLOrigin,
        destinationLevel: Int,
        destinationSlice: Int
    ) {
        self.sourceRegion = sourceRegion
        self.sourceLevel = sourceLevel
        self.sourceSlice = sourceSlice
        self.destinationOrigin = destinationOrigin
        self.destinationLevel = destinationLevel
        self.destinationSlice = destinationSlice
    }
}

public struct MTL4UpdateSparseBufferMappingOperation: Equatable, Sendable {
    public var mode: MTLSparseTextureMappingMode
    public var bufferRange: NSRange
    public var heapOffset: Int

    public init() {
        self.mode = .map
        self.bufferRange = NSRange(location: 0, length: 0)
        self.heapOffset = 0
    }

    public init(mode: MTLSparseTextureMappingMode, bufferRange: NSRange, heapOffset: Int) {
        self.mode = mode
        self.bufferRange = bufferRange
        self.heapOffset = heapOffset
    }
}

public struct MTL4UpdateSparseTextureMappingOperation: Equatable, Sendable {
    public var mode: MTLSparseTextureMappingMode
    public var textureRegion: MTLRegion
    public var textureLevel: Int
    public var textureSlice: Int
    public var heapOffset: Int

    public init() {
        self.mode = .map
        self.textureRegion = MTLRegion()
        self.textureLevel = 0
        self.textureSlice = 0
        self.heapOffset = 0
    }

    public init(
        mode: MTLSparseTextureMappingMode,
        textureRegion: MTLRegion,
        textureLevel: Int,
        textureSlice: Int,
        heapOffset: Int
    ) {
        self.mode = mode
        self.textureRegion = textureRegion
        self.textureLevel = textureLevel
        self.textureSlice = textureSlice
        self.heapOffset = heapOffset
    }
}

public protocol MTL4CommandAllocator: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get }
    func allocatedSize() -> UInt64
    func reset()
}

public protocol MTL4CommandEncoder: NSObjectProtocol {
    var commandBuffer: (any MTL4CommandBuffer)? { get }
    var label: String? { get set }
    func endEncoding()
    func insertDebugSignpost(_ string: String)
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func updateFence(_ fence: any MTLFence, afterEncoderStages: MTLStages)
    func waitForFence(_ fence: any MTLFence, beforeEncoderStages: MTLStages)
    func barrier(
        afterEncoderStages: MTLStages,
        beforeEncoderStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    )
    func barrier(
        afterStages: MTLStages,
        beforeQueueStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    )
    func barrier(
        afterQueueStages: MTLStages,
        beforeStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    )
}

public protocol MTL4ComputeCommandEncoder: MTL4CommandEncoder {
    func setComputePipelineState(_ state: any MTLComputePipelineState)
    func setArgumentTable(_ argumentTable: (any MTL4ArgumentTable)?)
    func setThreadgroupMemoryLength(_ length: Int, index: Int)
    func setImageblockSize(width: Int, height: Int)
    func stages() -> MTLStages
    func dispatchThreadgroups(threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func dispatchThreadgroups(indirectBuffer: MTLGPUAddress, threadsPerThreadgroup: MTLSize)
    func dispatchThreads(threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize)
    func dispatchThreads(indirectBuffer: MTLGPUAddress)
    func copy(
        sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    )
    func copy(
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
    func copy(
        sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        sliceCount: Int,
        levelCount: Int
    )
    func copy(sourceTexture: any MTLTexture, destinationTexture: any MTLTexture)
    func generateMipmaps(texture: any MTLTexture)
    func optimizeContents(forCPUAccess texture: any MTLTexture)
    func optimizeContents(forCPUAccess texture: any MTLTexture, slice: Int, level: Int)
    func optimizeContents(forGPUAccess texture: any MTLTexture)
    func optimizeContents(forGPUAccess texture: any MTLTexture, slice: Int, level: Int)
    func executeCommands(buffer indirectCommandbuffer: any MTLIndirectCommandBuffer, indirectBuffer indirectRangeBuffer: MTLGPUAddress)
    func copy(
        sourceTensor: any MTLTensor,
        sourceOrigin: MTLTensorExtents,
        sourceDimensions: MTLTensorExtents,
        destinationTensor: any MTLTensor,
        destinationOrigin: MTLTensorExtents,
        destinationDimensions: MTLTensorExtents
    )
    func build(
        destinationAccelerationStructure accelerationStructure: any MTLAccelerationStructure,
        descriptor: MTL4AccelerationStructureDescriptor,
        scratchBuffer: MTL4BufferRange
    )
    func copy(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    )
    func copyAndCompact(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    )
    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTL4AccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: MTL4BufferRange,
        options: MTLAccelerationStructureRefitOptions
    )
    func writeCompactedSize(
        sourceAccelerationStructure accelerationStructure: any MTLAccelerationStructure,
        destinationBuffer buffer: MTL4BufferRange
    )
    func writeTimestamp(granularity: MTL4TimestampGranularity, counterHeap: any MTL4CounterHeap, index: Int)
}

public protocol MTL4RenderCommandEncoder: MTL4CommandEncoder {
    var tileWidth: Int { get }
    var tileHeight: Int { get }
    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState)
    func setArgumentTable(_ argumentTable: any MTL4ArgumentTable, stages: MTLRenderStages)
    func setViewport(_ viewport: MTLViewport)
    func setScissorRect(_ rect: MTLScissorRect)
    func setCullMode(_ cullMode: MTLCullMode)
    func setFrontFacing(_ frontFacingWinding: MTLWinding)
    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode)
    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float)
    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode)
    func setBlendColor(red: Float, green: Float, blue: Float, alpha: Float)
    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?)
    func setStencilReferenceValue(_ referenceValue: UInt32)
    func setStencilReferenceValue(front frontReferenceValue: UInt32, back backReferenceValue: UInt32)
    func setVisibilityResultMode(_ mode: MTLVisibilityResultMode, offset: Int)
    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int)
    func setDepthStoreAction(_ storeAction: MTLStoreAction)
    func setStencilStoreAction(_ storeAction: MTLStoreAction)
    func setColorAttachmentMap(_ mapping: MTLLogicalToPhysicalColorAttachmentMap?)
    func setThreadgroupMemoryLength(_ length: Int, offset: Int, index: Int)
    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int)
    func dispatchThreadsPerTile(_ threadsPerTile: MTLSize)
    func drawPrimitives(primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int)
    func drawPrimitives(primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int, instanceCount: Int)
    func drawPrimitives(
        primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    )
    func drawPrimitives(primitiveType: MTLPrimitiveType, indirectBuffer: MTLGPUAddress)
    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int
    )
    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        instanceCount: Int
    )
    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    )
    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        indirectBuffer: MTLGPUAddress
    )
    func drawMeshThreadgroups(
        threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawMeshThreadgroups(
        indirectBuffer: MTLGPUAddress,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func drawMeshThreads(
        threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    )
    func executeCommands(
        buffer indirectCommandBuffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: MTLGPUAddress
    )
    func writeTimestamp(
        granularity: MTL4TimestampGranularity,
        after stage: MTLRenderStages,
        counterHeap: any MTL4CounterHeap,
        index: Int
    )
}

public protocol MTL4CommandBuffer: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get set }
    func beginCommandBuffer(allocator: any MTL4CommandAllocator)
    func beginCommandBuffer(allocator: any MTL4CommandAllocator, options: MTL4CommandBufferOptions)
    func endCommandBuffer()
    func makeComputeCommandEncoder() -> (any MTL4ComputeCommandEncoder)?
    func makeRenderCommandEncoder(
        descriptor: MTL4RenderPassDescriptor,
        options: MTL4RenderEncoderOptions
    ) -> (any MTL4RenderCommandEncoder)?
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func useResidencySet(_ residencySet: any MTLResidencySet)
    func writeTimestamp(counterHeap: any MTL4CounterHeap, index: Int)
    func resolveCounterHeap(
        _ counterHeap: any MTL4CounterHeap,
        range: Range<Int>,
        buffer: MTL4BufferRange,
        fenceToWait: (any MTLFence)?,
        fenceToUpdate: (any MTLFence)?
    )
}

public protocol MTL4CommandQueue: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    func addResidencySet(_ residencySet: any MTLResidencySet)
    func removeResidencySet(_ residencySet: any MTLResidencySet)
    func signalDrawable(_ drawable: any MTLDrawable)
    func waitForDrawable(_ drawable: any MTLDrawable)
    func signalEvent(_ event: any MTLEvent, value: UInt64)
    func waitForEvent(_ event: any MTLEvent, value: UInt64)
    func commit(_ commandBuffers: [any MTL4CommandBuffer], options: MTL4CommitOptions?)
    func copyMappings(
        sourceBuffer: any MTLBuffer,
        destinationBuffer: any MTLBuffer,
        operations: [MTL4CopySparseBufferMappingOperation]
    )
    func copyMappings(
        sourceTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        operations: [MTL4CopySparseTextureMappingOperation]
    )
    func updateMappings(
        buffer: any MTLBuffer,
        heap: (any MTLHeap)?,
        operations: [MTL4UpdateSparseBufferMappingOperation]
    )
    func updateMappings(
        texture: any MTLTexture,
        heap: (any MTLHeap)?,
        operations: [MTL4UpdateSparseTextureMappingOperation]
    )
}

public protocol MTL4ArgumentTable: NSObjectProtocol {
    var device: any MTLDevice { get }
    var label: String? { get }
    func setAddress(_ gpuAddress: MTLGPUAddress, index bindingIndex: Int)
    func setAddress(_ gpuAddress: MTLGPUAddress, attributeStride stride: Int, index bindingIndex: Int)
    func setResource(_ resourceID: MTLResourceID, bufferIndex bindingIndex: Int)
    func setSamplerState(_ resourceID: MTLResourceID, index bindingIndex: Int)
    func setTexture(_ resourceID: MTLResourceID, index bindingIndex: Int)
}

public protocol MTL4CommitFeedback: NSObjectProtocol {
    var gpuStartTime: CFTimeInterval { get }
    var gpuEndTime: CFTimeInterval { get }
    var error: (any Error)? { get }
}

public protocol MTL4CounterHeap: NSObjectProtocol {
    var count: Int { get }
    var label: String? { get set }
    var type: MTL4CounterHeapType { get }
    func invalidateCounterRange(_ range: Range<Int>)
    func resolveCounterRange(_ range: Range<Int>) throws -> Data?
}

public protocol MTL4Archive: NSObjectProtocol, Sendable {
    var label: String? { get set }
    func makeBinaryFunction(descriptor: MTL4BinaryFunctionDescriptor) throws -> any MTL4BinaryFunction
    func makeRenderPipelineState(
        descriptor: MTL4PipelineDescriptor,
        dynamicLinkingDescriptor: MTL4RenderPipelineDynamicLinkingDescriptor?
    ) throws -> any MTLRenderPipelineState
    func makeComputePipelineState(
        descriptor: MTL4ComputePipelineDescriptor,
        dynamicLinkingDescriptor: MTL4PipelineStageDynamicLinkingDescriptor?
    ) throws -> any MTLComputePipelineState
}

public protocol MTL4PipelineDataSetSerializer: NSObjectProtocol {
    func serializeAsArchiveAndFlush(url: URL) throws
    func serializeAsPipelinesScript() throws -> Data
}

public protocol MTL4Compiler: NSObjectProtocol, Sendable {
    var device: any MTLDevice { get }
    var label: String? { get }
    var pipelineDataSetSerializer: (any MTL4PipelineDataSetSerializer)? { get }
    func makeLibrary(descriptor: MTL4LibraryDescriptor) throws -> any MTLLibrary
    func makeDynamicLibrary(library: any MTLLibrary) throws -> any MTLDynamicLibrary
    func makeDynamicLibrary(url: URL) throws -> any MTLDynamicLibrary
    func makeBinaryFunction(
        descriptor: MTL4BinaryFunctionDescriptor,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTL4BinaryFunction
    func makeRenderPipelineState(
        descriptor: MTL4PipelineDescriptor,
        dynamicLinkingDescriptor: MTL4RenderPipelineDynamicLinkingDescriptor?,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTLRenderPipelineState
    func makeComputePipelineState(
        descriptor: MTL4ComputePipelineDescriptor,
        dynamicLinkingDescriptor: MTL4PipelineStageDynamicLinkingDescriptor?,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTLComputePipelineState
    func makeRenderPipelineStateBySpecialization(
        descriptor: MTL4PipelineDescriptor,
        pipeline: any MTLRenderPipelineState
    ) throws -> any MTLRenderPipelineState
}

extension MTL4CommandQueue {
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

extension MTL4CommandBuffer {
    public func useResidencySets(_ residencySets: [any MTLResidencySet]) {
        for set in residencySets {
            useResidencySet(set)
        }
    }
}

extension MTL4RenderCommandEncoder {
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
}

final class LinuxMTL4CommandAllocator: NSObject, MTL4CommandAllocator, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    private var bytes: UInt64 = 0

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, label: String?) {
        self.owningDevice = device
        self.label = label
        super.init()
    }

    func allocatedSize() -> UInt64 { bytes }

    func reset() {
        bytes = 0
    }
}

final class LinuxMTL4CommitFeedback: NSObject, MTL4CommitFeedback, @unchecked Sendable {
    let gpuStartTime: CFTimeInterval
    let gpuEndTime: CFTimeInterval
    let error: (any Error)?

    init(gpuStartTime: CFTimeInterval, gpuEndTime: CFTimeInterval, error: (any Error)?) {
        self.gpuStartTime = gpuStartTime
        self.gpuEndTime = gpuEndTime
        self.error = error
        super.init()
    }
}

final class LinuxMTL4CommandBuffer: NSObject, MTL4CommandBuffer, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private var recorded: [() -> Void] = []
    private var shaderWork = false
    private(set) var pendingError: MTL4CommandQueueError?
    private var began = false

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func beginCommandBuffer(allocator: any MTL4CommandAllocator) {
        began = true
        (allocator as? LinuxMTL4CommandAllocator)?.reset()
    }

    func beginCommandBuffer(allocator: any MTL4CommandAllocator, options: MTL4CommandBufferOptions) {
        _ = options
        beginCommandBuffer(allocator: allocator)
    }

    func endCommandBuffer() {
        began = false
    }

    func makeComputeCommandEncoder() -> (any MTL4ComputeCommandEncoder)? {
        LinuxMTL4ComputeCommandEncoder(commandBuffer: self)
    }

    func makeRenderCommandEncoder(
        descriptor: MTL4RenderPassDescriptor,
        options: MTL4RenderEncoderOptions
    ) -> (any MTL4RenderCommandEncoder)? {
        LinuxMTL4RenderCommandEncoder(commandBuffer: self, descriptor: descriptor, options: options)
    }

    func pushDebugGroup(_ string: String) { _ = string }
    func popDebugGroup() {}
    func useResidencySet(_ residencySet: any MTLResidencySet) { _ = residencySet }
    func writeTimestamp(counterHeap: any MTL4CounterHeap, index: Int) {
        record {
            (counterHeap as? LinuxMTL4CounterHeap)?.writeHostTimestamp(at: index)
        }
    }

    func resolveCounterHeap(
        _ counterHeap: any MTL4CounterHeap,
        range: Range<Int>,
        buffer: MTL4BufferRange,
        fenceToWait: (any MTLFence)?,
        fenceToUpdate: (any MTLFence)?
    ) {
        _ = (buffer, fenceToWait, fenceToUpdate)
        record {
            _ = try? counterHeap.resolveCounterRange(range)
            (fenceToUpdate as? LinuxMTLFence)?.signal()
        }
    }

    func record(_ work: @escaping () -> Void) {
        recorded.append(work)
    }

    func noteShaderWork() {
        shaderWork = true
    }

    func commitWork() -> (CFTimeInterval, CFTimeInterval, MTL4CommandQueueError?) {
        let start = ProcessInfo.processInfo.systemUptime
        for work in recorded {
            work()
        }
        recorded.removeAll()
        let end = ProcessInfo.processInfo.systemUptime
        if shaderWork {
            pendingError = MTL4CommandQueueError(
                .notPermitted,
                userInfo: [NSLocalizedDescriptionKey: "CPU Metal 4 device cannot dispatch GPU shaders"]
            )
        }
        shaderWork = false
        return (start, end, pendingError)
    }
}

final class LinuxMTL4CommandQueue: NSObject, MTL4CommandQueue, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, label: String?) {
        self.owningDevice = device
        self.label = label
        super.init()
    }

    func addResidencySet(_ residencySet: any MTLResidencySet) { _ = residencySet }
    func removeResidencySet(_ residencySet: any MTLResidencySet) { _ = residencySet }

    func signalDrawable(_ drawable: any MTLDrawable) {
        drawable.present()
    }

    func waitForDrawable(_ drawable: any MTLDrawable) { _ = drawable }

    func signalEvent(_ event: any MTLEvent, value: UInt64) {
        if let shared = event as? LinuxMTLSharedEvent {
            shared.signaledValue = value
        } else {
            (event as? LinuxMTLEvent)?.signal(value)
        }
    }

    func waitForEvent(_ event: any MTLEvent, value: UInt64) {
        if let shared = event as? LinuxMTLSharedEvent {
            _ = shared.wait(untilSignaledValue: value, timeoutMS: 0)
        }
    }

    func commit(_ commandBuffers: [any MTL4CommandBuffer], options: MTL4CommitOptions?) {
        for buffer in commandBuffers {
            guard let linux = buffer as? LinuxMTL4CommandBuffer else { continue }
            let (start, end, error) = linux.commitWork()
            let feedback = LinuxMTL4CommitFeedback(
                gpuStartTime: start,
                gpuEndTime: end,
                error: error
            )
            for handler in options?.handlers ?? [] {
                handler(feedback)
            }
        }
    }

    func copyMappings(
        sourceBuffer: any MTLBuffer,
        destinationBuffer: any MTLBuffer,
        operations: [MTL4CopySparseBufferMappingOperation]
    ) {
        _ = (sourceBuffer, destinationBuffer, operations)
    }

    func copyMappings(
        sourceTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        operations: [MTL4CopySparseTextureMappingOperation]
    ) {
        _ = (sourceTexture, destinationTexture, operations)
    }

    func updateMappings(
        buffer: any MTLBuffer,
        heap: (any MTLHeap)?,
        operations: [MTL4UpdateSparseBufferMappingOperation]
    ) {
        _ = (buffer, heap, operations)
    }

    func updateMappings(
        texture: any MTLTexture,
        heap: (any MTLHeap)?,
        operations: [MTL4UpdateSparseTextureMappingOperation]
    ) {
        _ = (texture, heap, operations)
    }
}

class LinuxMTL4EncoderBase: NSObject, @unchecked Sendable {
    unowned let owner: LinuxMTL4CommandBuffer
    var label: String?

    var commandBuffer: (any MTL4CommandBuffer)? { owner }

    init(commandBuffer: LinuxMTL4CommandBuffer) {
        self.owner = commandBuffer
        super.init()
    }

    func endEncoding() {}
    func insertDebugSignpost(_ string: String) { _ = string }
    func pushDebugGroup(_ string: String) { _ = string }
    func popDebugGroup() {}
    func updateFence(_ fence: any MTLFence, afterEncoderStages: MTLStages) {
        _ = (fence, afterEncoderStages)
        owner.record { (fence as? LinuxMTLFence)?.signal() }
    }
    func waitForFence(_ fence: any MTLFence, beforeEncoderStages: MTLStages) {
        _ = (fence, beforeEncoderStages)
        owner.record { (fence as? LinuxMTLFence)?.wait() }
    }
    func barrier(
        afterEncoderStages: MTLStages,
        beforeEncoderStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    ) {
        _ = (afterEncoderStages, beforeEncoderStages, visibilityOptions)
    }
    func barrier(
        afterStages: MTLStages,
        beforeQueueStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    ) {
        _ = (afterStages, beforeQueueStages, visibilityOptions)
    }
    func barrier(
        afterQueueStages: MTLStages,
        beforeStages: MTLStages,
        visibilityOptions: MTL4VisibilityOptions
    ) {
        _ = (afterQueueStages, beforeStages, visibilityOptions)
    }
}

final class LinuxMTL4ComputeCommandEncoder: LinuxMTL4EncoderBase, MTL4ComputeCommandEncoder, @unchecked Sendable {
    private var pipeline: (any MTLComputePipelineState)?
    private var argumentTable: (any MTL4ArgumentTable)?

    func setComputePipelineState(_ state: any MTLComputePipelineState) {
        pipeline = state
    }

    func setArgumentTable(_ argumentTable: (any MTL4ArgumentTable)?) {
        self.argumentTable = argumentTable
    }

    func setThreadgroupMemoryLength(_ length: Int, index: Int) { _ = (length, index) }
    func setImageblockSize(width: Int, height: Int) { _ = (width, height) }
    func stages() -> MTLStages { .dispatch }

    func dispatchThreadgroups(threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        _ = (threadgroupsPerGrid, threadsPerThreadgroup)
        owner.noteShaderWork()
    }

    func dispatchThreadgroups(indirectBuffer: MTLGPUAddress, threadsPerThreadgroup: MTLSize) {
        _ = (indirectBuffer, threadsPerThreadgroup)
        owner.noteShaderWork()
    }

    func dispatchThreads(threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        _ = (threadsPerGrid, threadsPerThreadgroup)
        owner.noteShaderWork()
    }

    func dispatchThreads(indirectBuffer: MTLGPUAddress) {
        _ = indirectBuffer
        owner.noteShaderWork()
    }

    func copy(
        sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    ) {
        owner.record {
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

    func copy(
        sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    ) {
        owner.record {
            metalCPUCopyTextureRegion(
                source: sourceTexture,
                sourceSlice: sourceSlice,
                sourceLevel: sourceLevel,
                sourceOrigin: sourceOrigin,
                sourceSize: sourceSize,
                destination: destinationTexture,
                destinationSlice: destinationSlice,
                destinationLevel: destinationLevel,
                destinationOrigin: destinationOrigin
            )
        }
    }

    func copy(
        sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        sliceCount: Int,
        levelCount: Int
    ) {
        for level in 0..<max(levelCount, 0) {
            let width = max(sourceTexture.width >> (sourceLevel + level), 1)
            let height = max(sourceTexture.height >> (sourceLevel + level), 1)
            let depth = max(sourceTexture.depth >> (sourceLevel + level), 1)
            for slice in 0..<max(sliceCount, 0) {
                copy(
                    sourceTexture: sourceTexture,
                    sourceSlice: sourceSlice + slice,
                    sourceLevel: sourceLevel + level,
                    sourceOrigin: MTLOrigin(),
                    sourceSize: MTLSize(width: width, height: height, depth: depth),
                    destinationTexture: destinationTexture,
                    destinationSlice: destinationSlice + slice,
                    destinationLevel: destinationLevel + level,
                    destinationOrigin: MTLOrigin()
                )
            }
        }
    }

    func copy(sourceTexture: any MTLTexture, destinationTexture: any MTLTexture) {
        copy(
            sourceTexture: sourceTexture,
            sourceSlice: 0,
            sourceLevel: 0,
            destinationTexture: destinationTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            sliceCount: min(sourceTexture.arrayLength, destinationTexture.arrayLength),
            levelCount: min(sourceTexture.mipmapLevelCount, destinationTexture.mipmapLevelCount)
        )
    }

    func generateMipmaps(texture: any MTLTexture) {
        owner.record {
            (texture as? LinuxMTLTexture)?.generateMipmapsBoxFilter()
        }
    }

    func optimizeContents(forCPUAccess texture: any MTLTexture) { _ = texture }
    func optimizeContents(forCPUAccess texture: any MTLTexture, slice: Int, level: Int) {
        _ = (texture, slice, level)
    }
    func optimizeContents(forGPUAccess texture: any MTLTexture) { _ = texture }
    func optimizeContents(forGPUAccess texture: any MTLTexture, slice: Int, level: Int) {
        _ = (texture, slice, level)
    }

    func executeCommands(
        buffer indirectCommandbuffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: MTLGPUAddress
    ) {
        _ = (indirectCommandbuffer, indirectRangeBuffer)
        owner.noteShaderWork()
    }

    func copy(
        sourceTensor: any MTLTensor,
        sourceOrigin: MTLTensorExtents,
        sourceDimensions: MTLTensorExtents,
        destinationTensor: any MTLTensor,
        destinationOrigin: MTLTensorExtents,
        destinationDimensions: MTLTensorExtents
    ) {
        let strides = sourceTensor.strides ?? MTLTensorExtents()
        let count = metalTensorElementCount(sourceDimensions.extents)
        let element = metalTensorElementSize(sourceTensor.dataType)
        let bytes = max(count * element, 1)
        let storage = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 16)
        defer { storage.deallocate() }
        sourceTensor.getBytes(
            storage,
            strides: strides,
            sliceOrigin: sourceOrigin,
            sliceDimensions: sourceDimensions
        )
        destinationTensor.replace(
            sliceOrigin: destinationOrigin,
            sliceDimensions: destinationDimensions,
            withBytes: storage,
            strides: destinationTensor.strides ?? MTLTensorExtents()
        )
    }

    func build(
        destinationAccelerationStructure accelerationStructure: any MTLAccelerationStructure,
        descriptor: MTL4AccelerationStructureDescriptor,
        scratchBuffer: MTL4BufferRange
    ) {
        _ = (accelerationStructure, descriptor, scratchBuffer)
        owner.noteShaderWork()
    }

    func copy(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    ) {
        _ = (sourceAccelerationStructure, destinationAccelerationStructure)
    }

    func copyAndCompact(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        destinationAccelerationStructure: any MTLAccelerationStructure
    ) {
        _ = (sourceAccelerationStructure, destinationAccelerationStructure)
        owner.noteShaderWork()
    }

    func refit(
        sourceAccelerationStructure: any MTLAccelerationStructure,
        descriptor: MTL4AccelerationStructureDescriptor,
        destinationAccelerationStructure: (any MTLAccelerationStructure)?,
        scratchBuffer: MTL4BufferRange,
        options: MTLAccelerationStructureRefitOptions
    ) {
        _ = (sourceAccelerationStructure, descriptor, destinationAccelerationStructure, scratchBuffer, options)
        owner.noteShaderWork()
    }

    func writeCompactedSize(
        sourceAccelerationStructure accelerationStructure: any MTLAccelerationStructure,
        destinationBuffer buffer: MTL4BufferRange
    ) {
        _ = (accelerationStructure, buffer)
    }

    func writeTimestamp(granularity: MTL4TimestampGranularity, counterHeap: any MTL4CounterHeap, index: Int) {
        _ = granularity
        owner.record {
            (counterHeap as? LinuxMTL4CounterHeap)?.writeHostTimestamp(at: index)
        }
    }
}

final class LinuxMTL4RenderCommandEncoder: LinuxMTL4EncoderBase, MTL4RenderCommandEncoder, @unchecked Sendable {
    let tileWidth: Int
    let tileHeight: Int
    private var pipeline: (any MTLRenderPipelineState)?
    private var viewport = MTLViewport()
    private var scissor = MTLScissorRect()
    private var cull: MTLCullMode = .none
    private var winding: MTLWinding = .clockwise

    init(
        commandBuffer: LinuxMTL4CommandBuffer,
        descriptor: MTL4RenderPassDescriptor,
        options: MTL4RenderEncoderOptions
    ) {
        self.tileWidth = descriptor.tileWidth
        self.tileHeight = descriptor.tileHeight
        super.init(commandBuffer: commandBuffer)
        _ = options
    }

    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState) {
        pipeline = pipelineState
    }

    func setArgumentTable(_ argumentTable: any MTL4ArgumentTable, stages: MTLRenderStages) {
        _ = (argumentTable, stages)
    }

    func setViewport(_ viewport: MTLViewport) { self.viewport = viewport }
    func setScissorRect(_ rect: MTLScissorRect) { scissor = rect }
    func setCullMode(_ cullMode: MTLCullMode) { cull = cullMode }
    func setFrontFacing(_ frontFacingWinding: MTLWinding) { winding = frontFacingWinding }
    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode) { _ = depthClipMode }
    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float) {
        _ = (depthBias, slopeScale, clamp)
    }
    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode) { _ = fillMode }
    func setBlendColor(red: Float, green: Float, blue: Float, alpha: Float) {
        _ = (red, green, blue, alpha)
    }
    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?) {
        _ = depthStencilState
    }
    func setStencilReferenceValue(_ referenceValue: UInt32) { _ = referenceValue }
    func setStencilReferenceValue(front frontReferenceValue: UInt32, back backReferenceValue: UInt32) {
        _ = (frontReferenceValue, backReferenceValue)
    }
    func setVisibilityResultMode(_ mode: MTLVisibilityResultMode, offset: Int) { _ = (mode, offset) }
    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int) {
        _ = (storeAction, colorAttachmentIndex)
    }
    func setDepthStoreAction(_ storeAction: MTLStoreAction) { _ = storeAction }
    func setStencilStoreAction(_ storeAction: MTLStoreAction) { _ = storeAction }
    func setColorAttachmentMap(_ mapping: MTLLogicalToPhysicalColorAttachmentMap?) { _ = mapping }
    func setThreadgroupMemoryLength(_ length: Int, offset: Int, index: Int) {
        _ = (length, offset, index)
    }
    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int) { _ = (length, index) }
    func dispatchThreadsPerTile(_ threadsPerTile: MTLSize) {
        _ = threadsPerTile
        owner.noteShaderWork()
    }

    func drawPrimitives(primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int) {
        drawPrimitives(
            primitiveType: primitiveType,
            vertexStart: vertexStart,
            vertexCount: vertexCount,
            instanceCount: 1,
            baseInstance: 0
        )
    }

    func drawPrimitives(
        primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int
    ) {
        drawPrimitives(
            primitiveType: primitiveType,
            vertexStart: vertexStart,
            vertexCount: vertexCount,
            instanceCount: instanceCount,
            baseInstance: 0
        )
    }

    func drawPrimitives(
        primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    ) {
        _ = (primitiveType, vertexStart, vertexCount, instanceCount, baseInstance, pipeline, viewport, scissor, cull, winding)
        owner.noteShaderWork()
    }

    func drawPrimitives(primitiveType: MTLPrimitiveType, indirectBuffer: MTLGPUAddress) {
        _ = (primitiveType, indirectBuffer)
        owner.noteShaderWork()
    }

    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int
    ) {
        drawIndexedPrimitives(
            primitiveType: primitiveType,
            indexCount: indexCount,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexBufferLength: indexBufferLength,
            instanceCount: 1,
            baseVertex: 0,
            baseInstance: 0
        )
    }

    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        instanceCount: Int
    ) {
        drawIndexedPrimitives(
            primitiveType: primitiveType,
            indexCount: indexCount,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexBufferLength: indexBufferLength,
            instanceCount: instanceCount,
            baseVertex: 0,
            baseInstance: 0
        )
    }

    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    ) {
        _ = (primitiveType, indexCount, indexType, indexBuffer, indexBufferLength, instanceCount, baseVertex, baseInstance)
        owner.noteShaderWork()
    }

    func drawIndexedPrimitives(
        primitiveType: MTLPrimitiveType,
        indexType: MTLIndexType,
        indexBuffer: MTLGPUAddress,
        indexBufferLength: Int,
        indirectBuffer: MTLGPUAddress
    ) {
        _ = (primitiveType, indexType, indexBuffer, indexBufferLength, indirectBuffer)
        owner.noteShaderWork()
    }

    func drawMeshThreadgroups(
        threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        _ = (threadgroupsPerGrid, threadsPerObjectThreadgroup, threadsPerMeshThreadgroup)
        owner.noteShaderWork()
    }

    func drawMeshThreadgroups(
        indirectBuffer: MTLGPUAddress,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        _ = (indirectBuffer, threadsPerObjectThreadgroup, threadsPerMeshThreadgroup)
        owner.noteShaderWork()
    }

    func drawMeshThreads(
        threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        _ = (threadsPerGrid, threadsPerObjectThreadgroup, threadsPerMeshThreadgroup)
        owner.noteShaderWork()
    }

    func executeCommands(
        buffer indirectCommandBuffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: MTLGPUAddress
    ) {
        _ = (indirectCommandBuffer, indirectRangeBuffer)
        owner.noteShaderWork()
    }

    func writeTimestamp(
        granularity: MTL4TimestampGranularity,
        after stage: MTLRenderStages,
        counterHeap: any MTL4CounterHeap,
        index: Int
    ) {
        _ = (granularity, stage)
        owner.record {
            (counterHeap as? LinuxMTL4CounterHeap)?.writeHostTimestamp(at: index)
        }
    }
}

final class LinuxMTL4ArgumentTable: NSObject, MTL4ArgumentTable, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    private var addresses: [Int: MTLGPUAddress] = [:]

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTL4ArgumentTableDescriptor) {
        self.owningDevice = device
        self.label = descriptor.label
        super.init()
    }

    func setAddress(_ gpuAddress: MTLGPUAddress, index bindingIndex: Int) {
        addresses[bindingIndex] = gpuAddress
    }

    func setAddress(_ gpuAddress: MTLGPUAddress, attributeStride stride: Int, index bindingIndex: Int) {
        _ = stride
        setAddress(gpuAddress, index: bindingIndex)
    }

    func setResource(_ resourceID: MTLResourceID, bufferIndex bindingIndex: Int) {
        addresses[bindingIndex] = resourceID._impl
    }

    func setSamplerState(_ resourceID: MTLResourceID, index bindingIndex: Int) {
        _ = (resourceID, bindingIndex)
    }

    func setTexture(_ resourceID: MTLResourceID, index bindingIndex: Int) {
        _ = (resourceID, bindingIndex)
    }
}

final class LinuxMTL4Compiler: NSObject, MTL4Compiler, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let label: String?
    let pipelineDataSetSerializer: (any MTL4PipelineDataSetSerializer)?

    var device: any MTLDevice { owningDevice }

    init(
        device: LinuxMTLDevice,
        label: String?,
        pipelineDataSetSerializer: (any MTL4PipelineDataSetSerializer)?
    ) {
        self.owningDevice = device
        self.label = label
        self.pipelineDataSetSerializer = pipelineDataSetSerializer
        super.init()
    }

    func makeLibrary(descriptor: MTL4LibraryDescriptor) throws -> any MTLLibrary {
        _ = descriptor
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeDynamicLibrary(library: any MTLLibrary) throws -> any MTLDynamicLibrary {
        _ = library
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeDynamicLibrary(url: URL) throws -> any MTLDynamicLibrary {
        _ = url
        throw metalUnsupportedLibraryError(
            .fileNotFound,
            reason: "no Metal dynamic library"
        )
    }

    func makeBinaryFunction(
        descriptor: MTL4BinaryFunctionDescriptor,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTL4BinaryFunction {
        _ = (descriptor, compilerTaskOptions)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeRenderPipelineState(
        descriptor: MTL4PipelineDescriptor,
        dynamicLinkingDescriptor: MTL4RenderPipelineDynamicLinkingDescriptor?,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTLRenderPipelineState {
        _ = (descriptor, dynamicLinkingDescriptor, compilerTaskOptions)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeComputePipelineState(
        descriptor: MTL4ComputePipelineDescriptor,
        dynamicLinkingDescriptor: MTL4PipelineStageDynamicLinkingDescriptor?,
        compilerTaskOptions: MTL4CompilerTaskOptions?
    ) throws -> any MTLComputePipelineState {
        _ = (descriptor, dynamicLinkingDescriptor, compilerTaskOptions)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeRenderPipelineStateBySpecialization(
        descriptor: MTL4PipelineDescriptor,
        pipeline: any MTLRenderPipelineState
    ) throws -> any MTLRenderPipelineState {
        _ = (descriptor, pipeline)
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }
}

final class LinuxMTL4CounterHeap: NSObject, MTL4CounterHeap, @unchecked Sendable {
    let count: Int
    var label: String?
    let type: MTL4CounterHeapType
    private var values: [UInt64]

    init(count: Int, type: MTL4CounterHeapType) {
        self.count = max(count, 0)
        self.type = type
        self.values = Array(repeating: 0, count: max(count, 0))
        super.init()
    }

    func writeHostTimestamp(at index: Int) {
        guard index >= 0, index < values.count else { return }
        values[index] = UInt64(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
    }

    func invalidateCounterRange(_ range: Range<Int>) {
        for index in range where index >= 0 && index < values.count {
            values[index] = 0
        }
    }

    func resolveCounterRange(_ range: Range<Int>) throws -> Data? {
        let clamped = range.clamped(to: 0..<values.count)
        guard !clamped.isEmpty else { return Data() }
        var data = Data(count: clamped.count * MemoryLayout<UInt64>.size)
        data.withUnsafeMutableBytes { raw in
            var offset = 0
            for index in clamped {
                raw.storeBytes(of: values[index], toByteOffset: offset, as: UInt64.self)
                offset += MemoryLayout<UInt64>.size
            }
        }
        return data
    }
}

final class LinuxMTL4Archive: NSObject, MTL4Archive, @unchecked Sendable {
    var label: String?

    func makeBinaryFunction(descriptor: MTL4BinaryFunctionDescriptor) throws -> any MTL4BinaryFunction {
        _ = descriptor
        throw metalUnsupportedLibraryError(.compileFailure, reason: "no shader compiler")
    }

    func makeRenderPipelineState(
        descriptor: MTL4PipelineDescriptor,
        dynamicLinkingDescriptor: MTL4RenderPipelineDynamicLinkingDescriptor?
    ) throws -> any MTLRenderPipelineState {
        _ = (descriptor, dynamicLinkingDescriptor)
        throw metalUnsupportedLibraryError(.compileFailure, reason: "no shader compiler")
    }

    func makeComputePipelineState(
        descriptor: MTL4ComputePipelineDescriptor,
        dynamicLinkingDescriptor: MTL4PipelineStageDynamicLinkingDescriptor?
    ) throws -> any MTLComputePipelineState {
        _ = (descriptor, dynamicLinkingDescriptor)
        throw metalUnsupportedLibraryError(.compileFailure, reason: "no shader compiler")
    }
}

final class LinuxMTL4PipelineDataSetSerializer: NSObject, MTL4PipelineDataSetSerializer, @unchecked Sendable {
    let configuration: MTL4PipelineDataSetSerializerConfiguration

    init(configuration: MTL4PipelineDataSetSerializerConfiguration) {
        self.configuration = configuration
        super.init()
    }

    func serializeAsArchiveAndFlush(url: URL) throws {
        _ = url
        throw metalUnsupportedLibraryError(.compileFailure, reason: "no GPU pipeline cache")
    }

    func serializeAsPipelinesScript() throws -> Data {
        throw metalUnsupportedLibraryError(.compileFailure, reason: "no GPU pipeline cache")
    }
}

final class LinuxMTLAccelerationStructure: LinuxMTLResource, MTLAccelerationStructure, @unchecked Sendable {
    let gpuResourceID: MTLResourceID
    let size: Int

    init(device: LinuxMTLDevice, size: Int) {
        self.gpuResourceID = device.nextID()
        self.size = max(size, 0)
        super.init(
            device: device,
            options: .storageModeShared,
            allocatedSize: max(size, 0),
            heap: nil,
            heapOffset: 0
        )
        device.noteAllocated(max(size, 0))
    }

    deinit {
        owningDevice.noteFreed(allocatedSize)
    }
}

func metalCPUCopyTextureRegion(
    source: any MTLTexture,
    sourceSlice: Int,
    sourceLevel: Int,
    sourceOrigin: MTLOrigin,
    sourceSize: MTLSize,
    destination: any MTLTexture,
    destinationSlice: Int,
    destinationLevel: Int,
    destinationOrigin: MTLOrigin
) {
    guard let bpp = metalBytesPerPixel(source.pixelFormat),
          metalBytesPerPixel(destination.pixelFormat) == bpp,
          sourceSize.width > 0,
          sourceSize.height > 0
    else { return }
    let depth = max(sourceSize.depth, 1)
    let bytesPerRow = sourceSize.width * bpp
    let bytesPerImage = bytesPerRow * sourceSize.height
    let count = bytesPerImage * depth
    let storage = UnsafeMutableRawPointer.allocate(byteCount: max(count, 1), alignment: 16)
    defer { storage.deallocate() }
    source.getBytes(
        storage,
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerImage,
        from: MTLRegion(
            origin: sourceOrigin,
            size: MTLSize(width: sourceSize.width, height: sourceSize.height, depth: depth)
        ),
        mipmapLevel: sourceLevel,
        slice: sourceSlice
    )
    destination.replace(
        region: MTLRegion(
            origin: destinationOrigin,
            size: MTLSize(width: sourceSize.width, height: sourceSize.height, depth: depth)
        ),
        mipmapLevel: destinationLevel,
        slice: destinationSlice,
        withBytes: storage,
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerImage
    )
}
