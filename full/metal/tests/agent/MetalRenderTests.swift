import Foundation
import Metal

func testRenderPassClearAndLoad() {
    let device = MTLCreateSystemDefaultDevice()!
    let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 1,
        mipmapped: false
    )
    colorDesc.usage = [.renderTarget, .shaderRead]
    let color = device.makeTexture(descriptor: colorDesc)!
    let seed: [UInt8] = [9, 9, 9, 9, 9, 9, 9, 9]
    seed.withUnsafeBytes { raw in
        color.replace(region: MTLRegionMake2D(0, 0, 2, 1), mipmapLevel: 0, withBytes: raw.baseAddress!, bytesPerRow: 8)
    }
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = color
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    let state = try! device.makeRenderPipelineState(descriptor: pipeline)
    _ = state.device
    _ = state.label
    _ = state.gpuResourceID
    _ = state.maxTotalThreadsPerThreadgroup
    _ = state.threadExecutionWidth
    _ = state.imageblockSampleLength
    _ = state.supportIndirectCommandBuffers
    _ = state.shaderValidation
    _ = state.imageblockMemoryLength(forDimensions: MTLSizeMake(1, 1, 1))
    _ = state.allocatedSize
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
    encoder.label = "render"
    encoder.setRenderPipelineState(state)
    encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: 2, height: 1, znear: 0, zfar: 1))
    encoder.setScissorRect(MTLScissorRect(x: 0, y: 0, width: 2, height: 1))
    encoder.setCullMode(.back)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setDepthClipMode(.clip)
    encoder.setDepthBias(0, slopeScale: 0, clamp: 0)
    encoder.setTriangleFillMode(.fill)
    encoder.setBlendColor(red: 0, green: 0, blue: 0, alpha: 1)
    encoder.setStencilReferenceValue(0)
    encoder.setStencilReferenceValues(front: 0, back: 0)
    encoder.setVisibilityResultMode(.disabled, offset: 0)
    encoder.setColorStoreAction(.store, index: 0)
    encoder.setColorStoreActionOptions([], index: 0)
    encoder.setDepthStoreAction(.store)
    encoder.setDepthStoreActionOptions([])
    encoder.setStencilStoreAction(.dontCare)
    encoder.setStencilStoreActionOptions([])
    let vertex = device.makeBuffer(length: 12, options: [])!
    encoder.setVertexBuffer(vertex, offset: 0, index: 0)
    encoder.setVertexBuffer(vertex, offset: 0, attributeStride: 12, index: 0)
    encoder.setVertexBufferOffset(0, index: 0)
    encoder.setVertexBufferOffset(offset: 0, attributeStride: 12, index: 0)
    var dummy: Float = 0
    withUnsafeBytes(of: &dummy) { raw in
        encoder.setVertexBytes(raw.baseAddress!, length: 4, index: 1)
        encoder.setVertexBytes(raw.baseAddress!, length: 4, attributeStride: 4, index: 1)
        encoder.setFragmentBytes(raw.baseAddress!, length: 4, index: 1)
    }
    encoder.setVertexTexture(color, index: 0)
    encoder.setFragmentTexture(color, index: 0)
    encoder.setFragmentBuffer(vertex, offset: 0, index: 0)
    encoder.setFragmentBufferOffset(0, index: 0)
    encoder.setVertexSamplerState(nil, index: 0)
    encoder.setVertexSamplerState(nil, lodMinClamp: 0, lodMaxClamp: 1, index: 0)
    encoder.setFragmentSamplerState(nil, index: 0)
    encoder.setFragmentSamplerState(nil, lodMinClamp: 0, lodMaxClamp: 1, index: 0)
    encoder.setDepthStencilState(nil)
    encoder.useResource(color, usage: .write)
    encoder.useResource(color, usage: .write, stages: .fragment)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1, baseInstance: 0)
    encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: 3,
        indexType: .uint16,
        indexBuffer: vertex,
        indexBufferOffset: 0
    )
    encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: 3,
        indexType: .uint16,
        indexBuffer: vertex,
        indexBufferOffset: 0,
        instanceCount: 1
    )
    encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: 3,
        indexType: .uint16,
        indexBuffer: vertex,
        indexBufferOffset: 0,
        instanceCount: 1,
        baseVertex: 0,
        baseInstance: 0
    )
    encoder.insertDebugSignpost("draw")
    encoder.pushDebugGroup("pass")
    encoder.popDebugGroup()
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    var pixels = [UInt8](repeating: 0, count: 8)
    pixels.withUnsafeMutableBytes { raw in
        color.getBytes(raw.baseAddress!, bytesPerRow: 8, from: MTLRegionMake2D(0, 0, 2, 1), mipmapLevel: 0)
    }
    precondition(pixels == [255, 0, 0, 255, 255, 0, 0, 255])
    _ = encoder.tileWidth
    _ = encoder.tileHeight

    let keep = device.makeTexture(descriptor: colorDesc)!
    let keepSeed: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
    keepSeed.withUnsafeBytes { raw in
        keep.replace(region: MTLRegionMake2D(0, 0, 2, 1), mipmapLevel: 0, withBytes: raw.baseAddress!, bytesPerRow: 8)
    }
    let loadPass = MTLRenderPassDescriptor()
    loadPass.colorAttachments[0].texture = keep
    loadPass.colorAttachments[0].loadAction = .load
    loadPass.colorAttachments[0].storeAction = .store
    let loadBuffer = queue.makeCommandBuffer()!
    let loadEncoder = loadBuffer.makeRenderCommandEncoder(descriptor: loadPass)!
    loadEncoder.endEncoding()
    loadBuffer.commit()
    loadBuffer.waitUntilCompleted()
    var loaded = [UInt8](repeating: 0, count: 8)
    loaded.withUnsafeMutableBytes { raw in
        keep.getBytes(raw.baseAddress!, bytesPerRow: 8, from: MTLRegionMake2D(0, 0, 2, 1), mipmapLevel: 0)
    }
    precondition(loaded == keepSeed)
}

func testParallelRenderEncoderAndSamplerState() {
    let device = MTLCreateSystemDefaultDevice()!
    let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    )
    colorDesc.usage = [.renderTarget, .shaderRead]
    let color = device.makeTexture(descriptor: colorDesc)!
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = color
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    let state = try! device.makeRenderPipelineState(descriptor: pipeline)
    let samplerDesc = MTLSamplerDescriptor()
    samplerDesc.minFilter = .linear
    samplerDesc.label = "cpu-sampler"
    let sampler = device.makeSamplerState(descriptor: samplerDesc)!
    precondition(sampler.device.name == device.name)
    precondition(sampler.label == "cpu-sampler")
    _ = sampler.gpuResourceID
    let depthDesc = MTLDepthStencilDescriptor()
    depthDesc.isDepthWriteEnabled = true
    depthDesc.depthCompareFunction = .less
    depthDesc.label = "cpu-depth"
    let depthState = device.makeDepthStencilState(descriptor: depthDesc)!
    precondition(depthState.device.name == device.name)
    precondition(depthState.label == "cpu-depth")
    _ = depthState.gpuResourceID
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let parallel = commandBuffer.makeParallelRenderCommandEncoder(descriptor: pass)!
    parallel.label = "parallel"
    precondition(parallel.label == "parallel")
    precondition(parallel.device.name == device.name)
    parallel.insertDebugSignpost("child")
    parallel.pushDebugGroup("p")
    parallel.popDebugGroup()
    let child = parallel.makeRenderCommandEncoder()!
    child.setRenderPipelineState(state)
    child.setFragmentSamplerState(sampler, index: 0)
    child.setVertexSamplerState(sampler, index: 0)
    child.setDepthStencilState(depthState)
    child.endEncoding()
    parallel.setColorStoreAction(.store, index: 0)
    parallel.setColorStoreActionOptions([], index: 0)
    parallel.setDepthStoreAction(.dontCare)
    parallel.setDepthStoreActionOptions([])
    parallel.setStencilStoreAction(.dontCare)
    parallel.setStencilStoreActionOptions([])
    parallel.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.error == nil)
    var pixel = [UInt8](repeating: 0, count: 4)
    pixel.withUnsafeMutableBytes { raw in
        color.getBytes(raw.baseAddress!, bytesPerRow: 4, from: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0)
    }
    precondition(pixel == [0, 255, 0, 255])
}

func testRenderEncoderStageBindings() {
    let device = MTLCreateSystemDefaultDevice()!
    let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    )
    colorDesc.usage = [.renderTarget, .shaderRead]
    let color = device.makeTexture(descriptor: colorDesc)!
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = color
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1)
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    let state = try! device.makeRenderPipelineState(descriptor: pipeline)
    let sampler = device.makeSamplerState(descriptor: MTLSamplerDescriptor())!
    let heap = device.makeHeap(descriptor: {
        let desc = MTLHeapDescriptor()
        desc.size = 256
        return desc
    }())!
    let vertex = device.makeBuffer(length: 16, options: .storageModeShared)!
    let fragment = device.makeBuffer(length: 32, options: .storageModeShared)!
    let mesh = device.makeBuffer(length: 8, options: .storageModeShared)!
    let object = device.makeBuffer(length: 4, options: .storageModeShared)!
    let tile = device.makeBuffer(length: 12, options: .storageModeShared)!
    let index = device.makeBuffer(length: 8, options: .storageModeShared)!
    let indirect = device.makeBuffer(length: 16, options: .storageModeShared)!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
    encoder.setRenderPipelineState(state)
    encoder.setViewports([
        MTLViewport(originX: 0, originY: 0, width: 1, height: 1, znear: 0, zfar: 1)
    ])
    encoder.setScissorRects([MTLScissorRect(x: 0, y: 0, width: 1, height: 1)])
    encoder.setVertexBuffers([vertex], offsets: [0], range: 0..<1)
    encoder.setVertexBuffers([vertex], offsets: [0], attributeStrides: [16], range: 0..<1)
    encoder.setFragmentBuffers([fragment], offsets: [0], range: 0..<1)
    encoder.setMeshBuffers([mesh], offsets: [0], range: 0..<1)
    encoder.setObjectBuffers([object], offsets: [0], range: 0..<1)
    encoder.setTileBuffers([tile], offsets: [0], range: 0..<1)
    encoder.setVertexTextures([color], range: 0..<1)
    encoder.setFragmentTextures([color], range: 0..<1)
    encoder.setMeshTextures([color], range: 0..<1)
    encoder.setObjectTextures([color], range: 0..<1)
    encoder.setTileTextures([color], range: 0..<1)
    encoder.setVertexSamplerStates([sampler], range: 0..<1)
    encoder.setFragmentSamplerStates([sampler], range: 0..<1)
    encoder.setMeshSamplerStates([sampler], range: 0..<1)
    encoder.setObjectSamplerStates([sampler], range: 0..<1)
    encoder.setTileSamplerStates([sampler], range: 0..<1)
    encoder.setVertexSamplerStates([sampler], lodMinClamps: [0], lodMaxClamps: [1], range: 0..<1)
    encoder.setFragmentSamplerStates([sampler], lodMinClamps: [0], lodMaxClamps: [1], range: 0..<1)
    encoder.setMeshSamplerStates([sampler], lodMinClamps: [0], lodMaxClamps: [1], range: 0..<1)
    encoder.setObjectSamplerStates([sampler], lodMinClamps: [0], lodMaxClamps: [1], range: 0..<1)
    encoder.setTileSamplerStates([sampler], lodMinClamps: [0], lodMaxClamps: [1], range: 0..<1)
    encoder.setMeshBuffer(mesh, offset: 0, index: 2)
    encoder.setMeshBufferOffset(4, index: 2)
    var meshBytes: UInt32 = 1
    withUnsafeBytes(of: &meshBytes) { raw in
        encoder.setMeshBytes(raw.baseAddress!, length: 4, index: 3)
    }
    encoder.setObjectBuffer(object, offset: 0, index: 1)
    encoder.setObjectBufferOffset(0, index: 1)
    withUnsafeBytes(of: &meshBytes) { raw in
        encoder.setObjectBytes(raw.baseAddress!, length: 4, index: 2)
    }
    encoder.setTileBuffer(tile, offset: 0, index: 1)
    encoder.setTileBufferOffset(4, index: 1)
    withUnsafeBytes(of: &meshBytes) { raw in
        encoder.setTileBytes(raw.baseAddress!, length: 4, index: 2)
    }
    encoder.setObjectThreadgroupMemoryLength(16, index: 0)
    encoder.setThreadgroupMemoryLength(32, offset: 0, index: 0)
    encoder.setTessellationFactorBuffer(vertex, offset: 0, instanceStride: 0)
    encoder.setTessellationFactorScale(1)
    encoder.setDepthTestBounds(0...1)
    encoder.useResources([vertex], usage: .read)
    encoder.useResources([fragment], usage: .write, stages: [.fragment])
    encoder.useHeaps([heap])
    encoder.useHeaps([heap], stages: [.vertex])
    encoder.use(color, usage: .read, stages: [.fragment])
    encoder.use(heap, stages: [.mesh])
    encoder.memoryBarrier(resources: [vertex], after: [.vertex], before: [.fragment])
    encoder.memoryBarrier(scope: [.buffers], after: [.vertex], before: [.fragment])
    encoder.updateFence(device.makeFence()!, after: [.fragment])
    encoder.waitForFence(device.makeFence()!, before: [.vertex])
    encoder.drawMeshThreadgroups(
        MTLSizeMake(1, 1, 1),
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    encoder.drawMeshThreadgroups(
        indirectBuffer: indirect,
        indirectBufferOffset: 0,
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    encoder.drawMeshThreads(
        MTLSizeMake(1, 1, 1),
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    encoder.drawPatches(
        numberOfPatchControlPoints: 3,
        patchStart: 0,
        patchCount: 1,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        instanceCount: 1,
        baseInstance: 0
    )
    encoder.drawPatches(
        numberOfPatchControlPoints: 3,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        indirectBuffer: indirect,
        indirectBufferOffset: 0
    )
    encoder.drawIndexedPatches(
        numberOfPatchControlPoints: 3,
        patchStart: 0,
        patchCount: 1,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        controlPointIndexBuffer: index,
        controlPointIndexBufferOffset: 0,
        instanceCount: 1,
        baseInstance: 0
    )
    encoder.drawIndexedPatches(
        numberOfPatchControlPoints: 3,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        controlPointIndexBuffer: index,
        controlPointIndexBufferOffset: 0,
        indirectBuffer: indirect,
        indirectBufferOffset: 0
    )
    encoder.dispatchThreadsPerTile(MTLSizeMake(8, 8, 1))
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.error == nil)
    var pixel = [UInt8](repeating: 0, count: 4)
    pixel.withUnsafeMutableBytes { raw in
        color.getBytes(raw.baseAddress!, bytesPerRow: 4, from: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0)
    }
    precondition(pixel == [0, 0, 255, 255])
}

func testRenderPipelineStateMeshProperties() {
    let device = MTLCreateSystemDefaultDevice()!
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
    descriptor.supportIndirectCommandBuffers = true
    let state = try! device.makeRenderPipelineState(descriptor: descriptor)
    _ = state.device
    _ = state.label
    _ = state.gpuResourceID
    _ = state.maxTotalThreadsPerThreadgroup
    _ = state.threadExecutionWidth
    _ = state.imageblockSampleLength
    _ = state.supportIndirectCommandBuffers
    _ = state.shaderValidation
    precondition(state.maxTotalThreadgroupsPerMeshGrid == 0)
    precondition(state.maxTotalThreadsPerMeshThreadgroup == 0)
    precondition(state.maxTotalThreadsPerObjectThreadgroup == 0)
    _ = state.meshThreadExecutionWidth
    _ = state.objectThreadExecutionWidth
    _ = state.requiredThreadsPerMeshThreadgroup
    _ = state.requiredThreadsPerObjectThreadgroup
    _ = state.requiredThreadsPerTileThreadgroup
    _ = state.threadgroupSizeMatchesTileSize
    precondition(state.imageblockMemoryLength(forDimensions: MTLSizeMake(8, 8, 1)) == 0)
    let specialized = state.makeRenderPipelineDescriptorForSpecialization()
    _ = specialized.label
    do {
        _ = try state.makeRenderPipelineState(
            additionalBinaryFunctions: MTL4RenderPipelineBinaryFunctionsDescriptor()
        )
        fatalError("extra Metal 4 binary functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try state.makeRenderPipelineState(
            additionalBinaryFunctions: MTLRenderPipelineFunctionsDescriptor()
        )
        fatalError("extra binary functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
}
