import Foundation
import Metal

func testDescriptorValueSemantics() {
    let texture = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm,
        width: 48,
        height: 24,
        mipmapped: false
    )
    texture.textureType = .type2D
    texture.usage = [.shaderRead, .renderTarget]
    texture.storageMode = .shared
    texture.cpuCacheMode = .defaultCache
    texture.hazardTrackingMode = .default
    texture.sampleCount = 1
    texture.arrayLength = 1
    texture.depth = 1
    texture.resourceOptions = .storageModeShared
    texture.allowGPUOptimizedContents = false
    texture.compressionType = .lossless
    texture.swizzle = MTLTextureSwizzleChannels()
    texture.placementSparsePageSize = .size16
    precondition(texture.pixelFormat == .bgra8Unorm)
    precondition(texture.width == 48 && texture.height == 24)
    _ = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm, size: 4, mipmapped: false)
    _ = MTLTextureDescriptor.textureBufferDescriptor(
        with: .r8Unorm,
        width: 8,
        resourceOptions: [],
        usage: .shaderRead
    )

    let sampler = MTLSamplerDescriptor()
    sampler.minFilter = .linear
    sampler.magFilter = .nearest
    sampler.mipFilter = .notMipmapped
    sampler.maxAnisotropy = 1
    sampler.sAddressMode = .clampToEdge
    sampler.tAddressMode = .repeat
    sampler.rAddressMode = .mirrorRepeat
    sampler.borderColor = .transparentBlack
    sampler.normalizedCoordinates = true
    sampler.lodMinClamp = 0
    sampler.lodMaxClamp = 10
    sampler.lodBias = 0
    sampler.lodAverage = false
    sampler.compareFunction = .never
    sampler.supportArgumentBuffers = false
    sampler.reductionMode = .weightedAverage
    sampler.label = "s"
    precondition(sampler.minFilter == .linear)

    let stencil = MTLStencilDescriptor()
    stencil.stencilCompareFunction = .always
    stencil.stencilFailureOperation = .keep
    stencil.depthFailureOperation = .keep
    stencil.depthStencilPassOperation = .keep
    stencil.readMask = 0xFF
    stencil.writeMask = 0xFF
    let depth = MTLDepthStencilDescriptor()
    depth.depthCompareFunction = .less
    depth.isDepthWriteEnabled = true
    depth.frontFaceStencil = stencil
    depth.backFaceStencil = stencil
    depth.label = "ds"
    precondition(depth.isDepthWriteEnabled)

    let heap = MTLHeapDescriptor()
    heap.size = 1024
    heap.storageMode = .shared
    heap.cpuCacheMode = .defaultCache
    heap.sparsePageSize = .size16
    heap.hazardTrackingMode = .default
    heap.resourceOptions = .storageModeShared
    heap.type = .automatic
    heap.maxCompatiblePlacementSparsePageSize = .size16
    precondition(heap.size == 1024)

    let compile = MTLCompileOptions()
    compile.fastMathEnabled = true
    compile.languageVersion = .version2_4
    compile.libraryType = .executable
    compile.preserveInvariance = false
    compile.optimizationLevel = .default
    compile.compileSymbolVisibility = .default
    compile.allowReferencingUndefinedSymbols = false
    compile.mathMode = .safe
    compile.mathFloatingPointFunctions = .fast
    compile.enableLogging = false
    _ = compile.preprocessorMacros
    _ = compile.installName
    _ = compile.libraries
    _ = compile.maxTotalThreadsPerThreadgroup
    _ = compile.requiredThreadsPerThreadgroup

    let queueDesc = MTLCommandQueueDescriptor()
    queueDesc.maxCommandBufferCount = 2
    _ = queueDesc.logState
    let cbDesc = MTLCommandBufferDescriptor()
    cbDesc.retainedReferences = true
    cbDesc.errorOptions = []
    _ = cbDesc.logState
    let captureDesc = MTLCaptureDescriptor()
    captureDesc.destination = .developerTools
    _ = captureDesc.captureObject
    _ = captureDesc.outputURL

    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].storeActionOptions = []
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
    pass.colorAttachments[0].level = 0
    pass.colorAttachments[0].slice = 0
    pass.colorAttachments[0].depthPlane = 0
    pass.renderTargetWidth = 48
    pass.renderTargetHeight = 24
    pass.renderTargetArrayLength = 1
    pass.defaultRasterSampleCount = 1
    pass.depthAttachment.loadAction = .clear
    pass.depthAttachment.clearDepth = 1
    pass.depthAttachment.depthResolveFilter = .sample0
    pass.stencilAttachment.clearStencil = 0
    pass.stencilAttachment.stencilResolveFilter = .sample0
    pass.visibilityResultType = .reset
    pass.setSamplePositions([MTLSamplePosition(x: 0.5, y: 0.5)])
    precondition(pass.getSamplePositions().count == 1)
    _ = pass.imageblockSampleLength
    _ = pass.threadgroupMemoryLength
    _ = pass.tileWidth
    _ = pass.tileHeight
    _ = pass.supportColorAttachmentMapping

    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipeline.colorAttachments[0].isBlendingEnabled = false
    pipeline.colorAttachments[0].sourceRGBBlendFactor = .one
    pipeline.colorAttachments[0].destinationRGBBlendFactor = .zero
    pipeline.colorAttachments[0].rgbBlendOperation = .add
    pipeline.colorAttachments[0].sourceAlphaBlendFactor = .one
    pipeline.colorAttachments[0].destinationAlphaBlendFactor = .zero
    pipeline.colorAttachments[0].alphaBlendOperation = .add
    pipeline.colorAttachments[0].writeMask = .all
    pipeline.shaderValidation = .disabled
    pipeline.sampleCount = 1
    pipeline.rasterSampleCount = 1
    pipeline.isRasterizationEnabled = true
    pipeline.reset()
    precondition(pipeline.colorAttachments[0].pixelFormat == .invalid)

    let vertex = MTLVertexDescriptor()
    vertex.attributes[0].format = .float3
    vertex.attributes[0].offset = 0
    vertex.attributes[0].bufferIndex = 0
    vertex.layouts[0].stride = 12
    vertex.layouts[0].stepFunction = .perVertex
    vertex.layouts[0].stepRate = 1
    vertex.reset()
    precondition(vertex.attributes[0].format == .invalid)

    let compute = MTLComputePipelineDescriptor()
    compute.label = "c"
    _ = compute.computeFunction
    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.dataType = .float
    argument.index = 0
    argument.arrayLength = 1
    _ = argument.access
    _ = argument.textureType
    let blitPass = MTLBlitPassDescriptor()
    _ = blitPass.sampleBufferAttachments[0]
    let computePass = MTLComputePassDescriptor()
    computePass.dispatchType = .serial
    _ = computePass.sampleBufferAttachments[0]
    let constants = MTLFunctionConstantValues()
    var value: Int32 = 1
    withUnsafeBytes(of: &value) { raw in
        constants.setConstantValue(raw.baseAddress!, type: .int, index: 0)
        constants.setConstantValue(raw.baseAddress!, type: .int, withName: "k")
        constants.setConstantValues(raw.baseAddress!, type: .int, range: 1..<2)
    }
    constants.reset()
    let resourceStatePass = MTLResourceStatePassDescriptor()
    resourceStatePass.sampleBufferAttachments[0].startOfEncoderSampleIndex = 0
    resourceStatePass.sampleBufferAttachments[0].endOfEncoderSampleIndex = 1
    _ = resourceStatePass.sampleBufferAttachments[0].sampleBuffer
    let fnDesc = MTLFunctionDescriptor()
    fnDesc.name = "n"
    fnDesc.options = []
    let icb = MTLIndirectCommandBufferDescriptor()
    icb.commandTypes = [.draw]
    icb.inheritBuffers = false
    icb.maxVertexBufferBindCount = 4
    icb.maxFragmentBufferBindCount = 4
    icb.maxKernelBufferBindCount = 4
    _ = icb.inheritPipelineState
    _ = icb.inheritDepthStencilState
    _ = icb.inheritDepthBias
    _ = icb.inheritDepthClipMode
    _ = icb.inheritCullMode
    _ = icb.inheritFrontFacingWinding
    _ = icb.inheritTriangleFillMode
    _ = icb.maxMeshBufferBindCount
    _ = icb.maxObjectBufferBindCount
    _ = icb.maxKernelThreadgroupMemoryBindCount
    _ = icb.maxObjectThreadgroupMemoryBindCount
    _ = icb.supportColorAttachmentMapping
    _ = icb.supportDynamicAttributeStride
    _ = icb.supportRayTracing
    _ = MTLIntersectionFunctionDescriptor()
    _ = MTLIntersectionFunctionTableDescriptor()
    _ = MTLVisibleFunctionTableDescriptor()
    _ = MTLLinkedFunctions()
    _ = MTLStageInputOutputDescriptor()
    _ = MTLFunctionConstant()
    _ = MTLAttribute()
    _ = MTLVertexAttribute()
    let metal4 = MTL4RenderPassDescriptor()
    metal4.renderTargetWidth = 8
    metal4.renderTargetHeight = 8
    precondition(metal4.renderTargetWidth == 8)
}

func testMeshAndTilePipelineDescriptors() {
    let mesh = MTLMeshRenderPipelineDescriptor()
    mesh.label = "mesh"
    mesh.rasterSampleCount = 1
    mesh.isAlphaToCoverageEnabled = true
    mesh.isAlphaToOneEnabled = false
    mesh.isRasterizationEnabled = true
    mesh.maxVertexAmplificationCount = 1
    mesh.maxTotalThreadsPerObjectThreadgroup = 32
    mesh.maxTotalThreadsPerMeshThreadgroup = 64
    mesh.maxTotalThreadgroupsPerMeshGrid = 8
    mesh.payloadMemoryLength = 128
    mesh.objectThreadgroupSizeIsMultipleOfThreadExecutionWidth = true
    mesh.meshThreadgroupSizeIsMultipleOfThreadExecutionWidth = true
    mesh.requiredThreadsPerObjectThreadgroup = MTLSizeMake(8, 1, 1)
    mesh.requiredThreadsPerMeshThreadgroup = MTLSizeMake(16, 1, 1)
    mesh.supportIndirectCommandBuffers = false
    mesh.shaderValidation = .disabled
    mesh.depthAttachmentPixelFormat = .depth32Float
    mesh.stencilAttachmentPixelFormat = .stencil8
    mesh.colorAttachments[0].pixelFormat = .rgba8Unorm
    mesh.objectBuffers[0].mutability = .immutable
    mesh.meshBuffers[1].mutability = .mutable
    mesh.fragmentBuffers[2].mutability = .default
    mesh.objectLinkedFunctions = MTLLinkedFunctions()
    mesh.meshLinkedFunctions = MTLLinkedFunctions()
    mesh.fragmentLinkedFunctions = MTLLinkedFunctions()
    mesh.objectLinkedFunctions.functions = []
    mesh.objectLinkedFunctions.binaryFunctions = []
    mesh.objectLinkedFunctions.privateFunctions = []
    mesh.objectLinkedFunctions.groups = [:]
    mesh.binaryArchives = nil
    precondition(mesh.label == "mesh")
    precondition(mesh.colorAttachments[0].pixelFormat == .rgba8Unorm)
    precondition(mesh.objectBuffers[0].mutability == .immutable)
    precondition(mesh.meshBuffers[1].mutability == .mutable)
    mesh.reset()
    precondition(mesh.label == nil)
    precondition(mesh.rasterSampleCount == 1)
    precondition(mesh.objectBuffers[0].mutability == .default)

    let tile = MTLTileRenderPipelineDescriptor()
    tile.label = "tile"
    tile.rasterSampleCount = 1
    tile.threadgroupSizeMatchesTileSize = true
    tile.maxTotalThreadsPerThreadgroup = 32
    tile.maxCallStackDepth = 1
    tile.supportAddingBinaryFunctions = false
    tile.requiredThreadsPerThreadgroup = MTLSizeMake(8, 8, 1)
    tile.shaderValidation = .enabled
    tile.colorAttachments[0].pixelFormat = .bgra8Unorm
    tile.tileBuffers[0].mutability = .mutable
    tile.linkedFunctions = MTLLinkedFunctions()
    tile.linkedFunctions.functions = []
    tile.preloadedLibraries = []
    tile.binaryArchives = nil
    precondition(tile.colorAttachments[0].pixelFormat == .bgra8Unorm)
    tile.reset()
    precondition(tile.label == nil)
    precondition(tile.tileBuffers[0].mutability == .default)

    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.vertexBuffers[0].mutability = .immutable
    pipeline.fragmentBuffers[1].mutability = .mutable
    pipeline.vertexLinkedFunctions = MTLLinkedFunctions()
    pipeline.fragmentLinkedFunctions = MTLLinkedFunctions()
    pipeline.binaryArchives = nil
    precondition(pipeline.vertexBuffers[0].mutability == .immutable)
    let compute = MTLComputePipelineDescriptor()
    compute.buffers[0].mutability = .immutable
    precondition(compute.buffers[0].mutability == .immutable)
}
