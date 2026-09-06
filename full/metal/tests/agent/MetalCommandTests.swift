import Foundation
import Metal

func testCommandBufferLifecycle() {
    let device = MTLCreateSystemDefaultDevice()!
    let queue = device.makeCommandQueue()!
    queue.label = "cpu-queue"
    precondition(queue.label == "cpu-queue")
    precondition(queue.device.name == device.name)
    let commandBuffer = queue.makeCommandBuffer()!
    precondition(commandBuffer.status == .notEnqueued)
    precondition(commandBuffer.device.name == device.name)
    precondition(commandBuffer.commandQueue.device.name == device.name)
    precondition(commandBuffer.retainedReferences)
    _ = commandBuffer.errorOptions
    commandBuffer.label = "cb"
    precondition(commandBuffer.label == "cb")
    commandBuffer.enqueue()
    precondition(commandBuffer.status == .enqueued)
    var seen: [MTLCommandBufferStatus] = []
    commandBuffer.addScheduledHandler { buffer in
        seen.append(buffer.status)
        precondition(buffer.status == .scheduled)
        precondition(buffer.error == nil)
    }
    var completed = false
    commandBuffer.addCompletedHandler { buffer in
        seen.append(buffer.status)
        precondition(buffer.status == .completed)
        precondition(buffer.error == nil)
        precondition(buffer.gpuEndTime >= buffer.gpuStartTime)
        precondition(buffer.kernelEndTime >= buffer.kernelStartTime)
        completed = true
    }
    commandBuffer.pushDebugGroup("g")
    commandBuffer.popDebugGroup()
    commandBuffer.commit()
    commandBuffer.waitUntilScheduled()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.status == .completed)
    precondition(completed)
    precondition(seen == [.scheduled, .completed])
    _ = commandBuffer.logs

    let described = queue.makeCommandBuffer(descriptor: MTLCommandBufferDescriptor())!
    described.commit()
    described.waitUntilCompleted()
    let unretained = queue.makeCommandBufferWithUnretainedReferences()!
    unretained.commit()
    unretained.waitUntilCompleted()
    queue.insertDebugCaptureBoundary()
}

func testBlitCopyFillMipmaps() {
    let device = MTLCreateSystemDefaultDevice()!
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let source = bytes.withUnsafeBytes { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: bytes.count, options: [])!
    }
    let destination = device.makeBuffer(length: 8, options: [])!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeBlitCommandEncoder()!
    encoder.label = "blit"
    precondition(encoder.label == "blit")
    precondition(encoder.device.name == device.name)
    encoder.insertDebugSignpost("copy")
    encoder.pushDebugGroup("blit-group")
    encoder.popDebugGroup()
    encoder.barrier(afterQueueStages: .blit, beforeStages: .blit)
    encoder.copy(from: source, sourceOffset: 0, to: destination, destinationOffset: 1, size: 5)
    encoder.fill(buffer: destination, range: 6..<8, value: 0xAB)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    let destBytes = UnsafeRawBufferPointer(start: destination.contents(), count: 8)
    precondition(destBytes[0] == 0)
    precondition(destBytes[1] == 1)
    precondition(destBytes[5] == 5)
    precondition(destBytes[6] == 0xAB)
    precondition(destBytes[7] == 0xAB)

    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    let texture = device.makeTexture(descriptor: descriptor)!
    let pixels: [UInt8] = [
        0, 0, 0, 255,
        100, 100, 100, 255,
        200, 200, 200, 255,
        40, 40, 40, 255
    ]
    pixels.withUnsafeBytes { raw in
        texture.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8
        )
    }
    let mipBuffer = queue.makeCommandBuffer()!
    let blit = mipBuffer.makeBlitCommandEncoder(descriptor: MTLBlitPassDescriptor())!
    blit.generateMipmaps(for: texture)
    blit.optimizeContentsForCPUAccess(texture: texture)
    blit.optimizeContentsForCPUAccess(texture: texture, slice: 0, level: 0)
    blit.optimizeContentsForGPUAccess(texture: texture)
    blit.optimizeContentsForGPUAccess(texture: texture, slice: 0, level: 0)
    let fence = device.makeFence()!
    blit.updateFence(fence)
    blit.waitForFence(fence)
    blit.endEncoding()
    mipBuffer.commit()
    mipBuffer.waitUntilCompleted()
    var mip = [UInt8](repeating: 0, count: 4)
    mip.withUnsafeMutableBytes { raw in
        texture.getBytes(
            raw.baseAddress!,
            bytesPerRow: 4,
            from: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 1
        )
    }
    precondition(mip[0] == 85)
    precondition(mip[3] == 255)

    let dest = device.makeTexture(descriptor: descriptor)!
    let copyBuffer = queue.makeCommandBuffer()!
    let copyEncoder = copyBuffer.makeBlitCommandEncoder()!
    copyEncoder.copy(from: texture, to: dest)
    let staging = device.makeBuffer(length: 16, options: [])!
    copyEncoder.copy(
        from: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: MTLOrigin(),
        sourceSize: MTLSize(width: 2, height: 2, depth: 1),
        to: staging,
        destinationOffset: 0,
        destinationBytesPerRow: 8,
        destinationBytesPerImage: 16
    )
    copyEncoder.copy(
        from: staging,
        sourceOffset: 0,
        sourceBytesPerRow: 8,
        sourceBytesPerImage: 16,
        sourceSize: MTLSize(width: 2, height: 2, depth: 1),
        to: dest,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: MTLOrigin()
    )
    copyEncoder.copy(
        from: staging,
        sourceOffset: 0,
        sourceBytesPerRow: 8,
        sourceBytesPerImage: 16,
        sourceSize: MTLSize(width: 2, height: 2, depth: 1),
        to: dest,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: MTLOrigin(),
        options: []
    )
    copyEncoder.copy(
        from: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: MTLOrigin(),
        sourceSize: MTLSize(width: 2, height: 2, depth: 1),
        to: staging,
        destinationOffset: 0,
        destinationBytesPerRow: 8,
        destinationBytesPerImage: 16,
        options: []
    )
    copyEncoder.copy(
        from: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        to: dest,
        destinationSlice: 0,
        destinationLevel: 0,
        sliceCount: 1,
        levelCount: 1
    )
    copyEncoder.endEncoding()
    copyBuffer.commit()
    copyBuffer.waitUntilCompleted()
}

func testIndirectCommandBufferAsData() {
    let device = MTLCreateSystemDefaultDevice()!
    let descriptor = MTLIndirectCommandBufferDescriptor()
    descriptor.commandTypes = [.concurrentDispatch, .draw]
    descriptor.maxKernelBufferBindCount = 8
    descriptor.maxVertexBufferBindCount = 4
    let icb = device.makeIndirectCommandBuffer(descriptor: descriptor, maxCommandCount: 2, options: .storageModeShared)!
    precondition(icb.size == 2)
    _ = icb.gpuResourceID
    _ = icb.allocatedSize
    icb.label = "icb"
    precondition(icb.label == "icb")
    let compute = icb.indirectComputeCommandAt(0)
    let library = MTLMakeCPUBuiltinLibrary(device)
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let pipeline = try! device.makeComputePipelineState(function: fill)
    let output = device.makeBuffer(length: 16, options: [])!
    let value = device.makeBuffer(length: 4, options: [])!
    value.contents().storeBytes(of: UInt32(0x11), as: UInt32.self)
    compute.reset()
    compute.setComputePipelineState(pipeline)
    compute.setKernelBuffer(output, offset: 0, at: 0)
    compute.setKernelBuffer(value, offset: 0, at: 1)
    compute.setKernelBuffer(value, offset: 0, index: 1)
    compute.setKernelBuffer(value, offset: 0, attributeStride: 4, at: 1)
    compute.setBarrier()
    compute.clearBarrier()
    compute.setImageblockWidth(1, height: 1)
    compute.setStageInRegion(MTLRegionMake2D(0, 0, 1, 1))
    compute.setThreadgroupMemoryLength(0, index: 0)
    compute.concurrentDispatchThreadgroups(MTLSizeMake(4, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.executeCommandsInBuffer(icb, range: 0..<1)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.error == nil)
    for index in 0..<4 {
        precondition(output.contents().advanced(by: index * 4).load(as: UInt32.self) == 0x11)
    }
    let blit = queue.makeCommandBuffer()!
    let blitEncoder = blit.makeBlitCommandEncoder()!
    blitEncoder.resetCommandsInBuffer(icb, range: 0..<1)
    let clone = device.makeIndirectCommandBuffer(descriptor: descriptor, maxCommandCount: 2, options: [])!
    blitEncoder.copyIndirectCommandBuffer(icb, sourceRange: 0..<1, destination: clone, destinationIndex: 0)
    blitEncoder.optimizeIndirectCommandBuffer(icb, range: 0..<1)
    blitEncoder.endEncoding()
    blit.commit()
    blit.waitUntilCompleted()
    let render = icb.indirectRenderCommandAt(0)
    let pipelineDesc = MTLRenderPipelineDescriptor()
    pipelineDesc.colorAttachments[0].pixelFormat = .rgba8Unorm
    let renderState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    let vertex = device.makeBuffer(length: 16, options: [])!
    render.reset()
    render.setRenderPipelineState(renderState)
    render.setVertexBuffer(vertex, offset: 0, at: 0)
    render.setVertexBuffer(vertex, offset: 0, attributeStride: 16, at: 0)
    render.setFragmentBuffer(vertex, offset: 0, at: 0)
    render.setMeshBuffer(vertex, offset: 0, at: 0)
    render.setObjectBuffer(vertex, offset: 0, at: 0)
    render.setObjectThreadgroupMemoryLength(0, index: 0)
    render.setCullMode(.back)
    render.setDepthBias(0, slopeScale: 0, clamp: 0)
    render.setDepthClipMode(.clip)
    render.setDepthStencilState(nil)
    render.setFrontFacing(.clockwise)
    render.setTriangleFillMode(.fill)
    render.setBarrier()
    render.clearBarrier()
    render.drawPrimitives(.triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1, baseInstance: 0)
    render.drawIndexedPrimitives(
        .triangle,
        indexCount: 3,
        indexType: .uint16,
        indexBuffer: vertex,
        indexBufferOffset: 0,
        instanceCount: 1,
        baseVertex: 0,
        baseInstance: 0
    )
    render.drawPatches(
        3,
        patchStart: 0,
        patchCount: 1,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        instanceCount: 1,
        baseInstance: 0,
        tessellationFactorBuffer: vertex,
        tessellationFactorBufferOffset: 0,
        tessellationFactorBufferInstanceStride: 0
    )
    render.drawIndexedPatches(
        3,
        patchStart: 0,
        patchCount: 1,
        patchIndexBuffer: nil,
        patchIndexBufferOffset: 0,
        controlPointIndexBuffer: vertex,
        controlPointIndexBufferOffset: 0,
        instanceCount: 1,
        baseInstance: 0,
        tessellationFactorBuffer: vertex,
        tessellationFactorBufferOffset: 0,
        tessellationFactorBufferInstanceStride: 0
    )
    render.drawMeshThreadgroups(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
    render.drawMeshThreads(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
    compute.concurrentDispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    let rangeBuffer = device.makeBuffer(length: 8, options: [])!
    rangeBuffer.contents().storeBytes(of: UInt32(0), as: UInt32.self)
    rangeBuffer.contents().advanced(by: 4).storeBytes(of: UInt32(0), as: UInt32.self)
    let extra = queue.makeCommandBuffer()!
    let extraEnc = extra.makeComputeCommandEncoder()!
    extraEnc.executeCommandsInBuffer(icb, indirectBuffer: rangeBuffer, offset: 0)
    extraEnc.executeCommands(in: icb, with: NSRange(location: 0, length: 0))
    extraEnc.executeCommands(in: icb, indirectBuffer: rangeBuffer, indirectBufferOffset: 0)
    extraEnc.endEncoding()
    extra.commit()
    extra.waitUntilCompleted()
}

func testResourceStateEncoder() {
    let device = MTLCreateSystemDefaultDevice()!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let pass = MTLResourceStatePassDescriptor()
    pass.sampleBufferAttachments[0].startOfEncoderSampleIndex = 0
    pass.sampleBufferAttachments[0].endOfEncoderSampleIndex = 0
    let encoder = commandBuffer.resourceStateCommandEncoder(with: pass)!
    encoder.label = "resource-state"
    precondition(encoder.label == "resource-state")
    precondition(encoder.device.name == device.name)
    encoder.insertDebugSignpost("rs")
    encoder.pushDebugGroup("rs")
    encoder.popDebugGroup()
    encoder.barrier(afterQueueStages: .resourceState, beforeStages: .blit)
    let fence = device.makeFence()!
    encoder.update(fence)
    encoder.wait(for: fence)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.error == nil)

    let texture = device.makeTexture(
        descriptor: MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: 1,
            height: 1,
            mipmapped: false
        )
    )!
    let failBuffer = queue.makeCommandBuffer()!
    let failEncoder = failBuffer.makeResourceStateCommandEncoder()!
    failEncoder.updateTextureMapping(
        texture,
        mode: .map,
        region: MTLRegionMake2D(0, 0, 1, 1),
        mipLevel: 0,
        slice: 0
    )
    failEncoder.updateTextureMapping(texture, mode: .unmap, indirectBuffer: device.makeBuffer(length: 8, options: [])!, indirectBufferOffset: 0)
    var region = MTLRegionMake2D(0, 0, 1, 1)
    var mip = 0
    var slice = 0
    failEncoder.updateTextureMappings(texture, mode: .map, regions: &region, mipLevels: &mip, slices: &slice, numRegions: 1)
    failEncoder.moveTextureMappings(
        sourceTexture: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: MTLOrigin(),
        sourceSize: MTLSizeMake(1, 1, 1),
        destinationTexture: texture,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: MTLOrigin()
    )
    failEncoder.endEncoding()
    failBuffer.commit()
    failBuffer.waitUntilCompleted()
    precondition(failBuffer.status == .error)
    precondition((failBuffer.error as? MTLCommandBufferError)?.code == .notPermitted)
}

func testMetal4CommandEncoders() {
    let device = MTLCreateSystemDefaultDevice()!
    let allocatorDesc = MTL4CommandAllocatorDescriptor()
    allocatorDesc.label = "alloc"
    let allocator = try! device.makeCommandAllocator(descriptor: allocatorDesc)
    allocator.reset()
    precondition(allocator.allocatedSize() == 0)
    precondition(allocator.device.name == device.name)
    _ = allocator.label
    precondition(device.makeCommandAllocator() != nil)

    let queueDesc = MTL4CommandQueueDescriptor()
    queueDesc.label = "m4q"
    queueDesc.feedbackQueue = nil
    let queue = try! device.makeMTL4CommandQueue(descriptor: queueDesc)
    precondition(queue.label == "m4q")
    precondition(queue.device.name == device.name)
    precondition(device.makeMTL4CommandQueue() != nil)
    let event = device.makeSharedEvent()!
    queue.signalEvent(event, value: 1)
    queue.waitForEvent(event, value: 1)
    let drawable = LinuxMTLDrawable()
    queue.signalDrawable(drawable)
    queue.waitForDrawable(drawable)
    queue.addResidencySets([])
    queue.removeResidencySets([])
    var sparseCopy = MTL4CopySparseBufferMappingOperation(sourceRange: NSRange(location: 0, length: 0), destinationOffset: 0)
    sparseCopy.destinationOffset = 0
    _ = MTL4CopySparseBufferMappingOperation()
    _ = MTL4CopySparseTextureMappingOperation()
    _ = MTL4CopySparseTextureMappingOperation(
        sourceRegion: MTLRegion(),
        sourceLevel: 0,
        sourceSlice: 0,
        destinationOrigin: MTLOrigin(),
        destinationLevel: 0,
        destinationSlice: 0
    )
    _ = MTL4UpdateSparseBufferMappingOperation()
    _ = MTL4UpdateSparseBufferMappingOperation(mode: .map, bufferRange: NSRange(location: 0, length: 0), heapOffset: 0)
    _ = MTL4UpdateSparseTextureMappingOperation()
    _ = MTL4UpdateSparseTextureMappingOperation(
        mode: .unmap,
        textureRegion: MTLRegion(),
        textureLevel: 0,
        textureSlice: 0,
        heapOffset: 0
    )
    let dummyBuf = device.makeBuffer(length: 4, options: [])!
    queue.copyMappings(sourceBuffer: dummyBuf, destinationBuffer: dummyBuf, operations: [sparseCopy])
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: 2, height: 2, mipmapped: true)
    texDesc.usage = [.shaderRead, .shaderWrite]
    let texture = device.makeTexture(descriptor: texDesc)!
    queue.copyMappings(sourceTexture: texture, destinationTexture: texture, operations: [])
    queue.updateMappings(buffer: dummyBuf, heap: nil, operations: [])
    queue.updateMappings(texture: texture, heap: nil, operations: [])

    let commandBuffer = device.makeCommandBuffer()!
    commandBuffer.label = "m4cb"
    precondition(commandBuffer.label == "m4cb")
    precondition(commandBuffer.device.name == device.name)
    let options = MTL4CommandBufferOptions()
    options.logState = nil
    commandBuffer.beginCommandBuffer(allocator: allocator, options: options)
    commandBuffer.beginCommandBuffer(allocator: allocator)
    commandBuffer.pushDebugGroup("g")
    commandBuffer.popDebugGroup()
    commandBuffer.useResidencySets([])

    let tableDesc = MTL4ArgumentTableDescriptor()
    tableDesc.label = "args"
    tableDesc.maxBufferBindCount = 4
    tableDesc.maxTextureBindCount = 4
    tableDesc.maxSamplerStateBindCount = 2
    tableDesc.initializeBindings = true
    tableDesc.supportAttributeStrides = false
    let table = try! device.makeArgumentTable(descriptor: tableDesc)
    table.setAddress(0, index: 0)
    table.setAddress(8, attributeStride: 16, index: 1)
    table.setResource(MTLResourceID(), bufferIndex: 2)
    table.setSamplerState(MTLResourceID(), index: 0)
    table.setTexture(MTLResourceID(), index: 0)
    precondition(table.device.name == device.name)
    _ = table.label

    let source = device.makeBuffer(length: 4, options: [])!
    source.contents().storeBytes(of: UInt32(0xAABBCCDD), as: UInt32.self)
    let dest = device.makeBuffer(length: 4, options: [])!
    let compute = commandBuffer.makeComputeCommandEncoder()!
    compute.label = "c4"
    compute.insertDebugSignpost("s")
    compute.pushDebugGroup("cg")
    compute.popDebugGroup()
    compute.barrier(afterEncoderStages: .dispatch, beforeEncoderStages: .blit, visibilityOptions: [.device])
    compute.barrier(afterStages: .dispatch, beforeQueueStages: .blit, visibilityOptions: [.device])
    compute.barrier(afterQueueStages: .blit, beforeStages: .dispatch, visibilityOptions: [.device])
    let fence = device.makeFence()!
    compute.updateFence(fence, afterEncoderStages: .dispatch)
    compute.waitForFence(fence, beforeEncoderStages: .dispatch)
    compute.setArgumentTable(table)
    compute.setThreadgroupMemoryLength(16, index: 0)
    compute.setImageblockSize(width: 8, height: 8)
    precondition(compute.stages().contains(.dispatch))
    compute.copy(sourceBuffer: source, sourceOffset: 0, destinationBuffer: dest, destinationOffset: 0, size: 4)
    let pixels: [UInt8] = [1, 2, 3, 4]
    pixels.withUnsafeBytes { raw in
        texture.replace(region: MTLRegionMake2D(0, 0, 2, 2), mipmapLevel: 0, withBytes: raw.baseAddress!, bytesPerRow: 2)
    }
    let destTex = device.makeTexture(descriptor: texDesc)!
    compute.copy(
        sourceTexture: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: MTLOrigin(),
        sourceSize: MTLSizeMake(2, 2, 1),
        destinationTexture: destTex,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: MTLOrigin()
    )
    compute.copy(
        sourceTexture: texture,
        sourceSlice: 0,
        sourceLevel: 0,
        destinationTexture: destTex,
        destinationSlice: 0,
        destinationLevel: 0,
        sliceCount: 1,
        levelCount: 1
    )
    compute.copy(sourceTexture: texture, destinationTexture: destTex)
    compute.generateMipmaps(texture: texture)
    compute.optimizeContents(forCPUAccess: texture)
    compute.optimizeContents(forCPUAccess: texture, slice: 0, level: 0)
    compute.optimizeContents(forGPUAccess: texture)
    compute.optimizeContents(forGPUAccess: texture, slice: 0, level: 0)
    compute.endEncoding()
    commandBuffer.endCommandBuffer()
    let commitOptions = MTL4CommitOptions()
    var feedbackSeen = false
    commitOptions.addFeedbackHandler { feedback in
        feedbackSeen = true
        precondition(feedback.error == nil)
        _ = feedback.gpuStartTime
        _ = feedback.gpuEndTime
    }
    queue.commit([commandBuffer], options: commitOptions)
    precondition(feedbackSeen)
    precondition(dest.contents().load(as: UInt32.self) == 0xAABBCCDD)
    var copied = [UInt8](repeating: 0, count: 4)
    copied.withUnsafeMutableBytes { raw in
        destTex.getBytes(raw.baseAddress!, bytesPerRow: 2, from: MTLRegionMake2D(0, 0, 2, 2), mipmapLevel: 0)
    }
    precondition(copied == pixels)

    let drawPipeline = try! device.makeRenderPipelineState(descriptor: {
        let d = MTLRenderPipelineDescriptor()
        d.colorAttachments[0].pixelFormat = .rgba8Unorm
        return d
    }())
    let drawBuffer = device.makeCommandBuffer()!
    let drawAlloc = device.makeCommandAllocator()!
    drawBuffer.beginCommandBuffer(allocator: drawAlloc)
    let pass = MTL4RenderPassDescriptor()
    pass.tileWidth = 8
    pass.tileHeight = 8
    let render = drawBuffer.makeRenderCommandEncoder(descriptor: pass, options: [.suspending])!
    precondition(render.tileWidth == 8)
    precondition(render.tileHeight == 8)
    render.setViewport(MTLViewport(originX: 0, originY: 0, width: 8, height: 8, znear: 0, zfar: 1))
    render.setViewports([MTLViewport(originX: 0, originY: 0, width: 8, height: 8, znear: 0, zfar: 1)])
    render.setScissorRect(MTLScissorRect(x: 0, y: 0, width: 8, height: 8))
    render.setScissorRects([MTLScissorRect(x: 0, y: 0, width: 8, height: 8)])
    render.setCullMode(.back)
    render.setFrontFacing(.counterClockwise)
    render.setDepthClipMode(.clip)
    render.setDepthBias(0, slopeScale: 0, clamp: 0)
    render.setTriangleFillMode(.fill)
    render.setBlendColor(red: 0, green: 0, blue: 0, alpha: 1)
    render.setStencilReferenceValue(0)
    render.setStencilReferenceValue(front: 0, back: 0)
    render.setVisibilityResultMode(.disabled, offset: 0)
    render.setColorStoreAction(.store, index: 0)
    render.setDepthStoreAction(.dontCare)
    render.setStencilStoreAction(.dontCare)
    render.setColorAttachmentMap(nil)
    render.setThreadgroupMemoryLength(0, offset: 0, index: 0)
    render.setObjectThreadgroupMemoryLength(0, index: 0)
    render.setArgumentTable(table, stages: .vertex)
    render.setRenderPipelineState(drawPipeline)
    render.setDepthStencilState(device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor()))
    render.writeTimestamp(granularity: .precise, after: .fragment, counterHeap: try! device.makeCounterHeap(descriptor: {
        let d = MTL4CounterHeapDescriptor()
        d.count = 1
        d.type = .timestamp
        return d
    }()), index: 0)
    render.executeCommands(buffer: device.makeIndirectCommandBuffer(
        descriptor: MTLIndirectCommandBufferDescriptor(),
        maxCommandCount: 1,
        options: []
    )!, indirectBuffer: 0)
    render.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: 3)
    render.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
    render.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1, baseInstance: 0)
    render.drawPrimitives(primitiveType: .triangle, indirectBuffer: 0)
    render.drawIndexedPrimitives(primitiveType: .triangle, indexCount: 3, indexType: .uint16, indexBuffer: 0, indexBufferLength: 6)
    render.drawIndexedPrimitives(primitiveType: .triangle, indexCount: 3, indexType: .uint16, indexBuffer: 0, indexBufferLength: 6, instanceCount: 1)
    render.drawIndexedPrimitives(
        primitiveType: .triangle,
        indexCount: 3,
        indexType: .uint16,
        indexBuffer: 0,
        indexBufferLength: 6,
        instanceCount: 1,
        baseVertex: 0,
        baseInstance: 0
    )
    render.drawIndexedPrimitives(primitiveType: .triangle, indexType: .uint16, indexBuffer: 0, indexBufferLength: 6, indirectBuffer: 0)
    render.drawMeshThreadgroups(
        threadgroupsPerGrid: MTLSizeMake(1, 1, 1),
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    render.drawMeshThreadgroups(
        indirectBuffer: 0,
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    render.drawMeshThreads(
        threadsPerGrid: MTLSizeMake(1, 1, 1),
        threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
        threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
    )
    render.dispatchThreadsPerTile(MTLSizeMake(8, 8, 1))
    render.endEncoding()
    drawBuffer.endCommandBuffer()
    var sawError = false
    let errorOptions = MTL4CommitOptions()
    errorOptions.addFeedbackHandler { feedback in
        sawError = true
        let error = feedback.error as? MTL4CommandQueueError
        precondition(error?.code == .notPermitted)
        precondition(MTL4CommandQueueError.notPermitted ~= feedback.error!)
    }
    queue.commit([drawBuffer], options: errorOptions)
    precondition(sawError)

    let compilerDesc = MTL4CompilerDescriptor()
    compilerDesc.label = "compiler"
    compilerDesc.pipelineDataSetSerializer = nil
    let compiler = try! device.makeCompiler(descriptor: compilerDesc)
    precondition(compiler.device.name == device.name)
    _ = compiler.label
    _ = compiler.pipelineDataSetSerializer
    do {
        _ = try compiler.makeLibrary(descriptor: libraryDescriptorFixture())
        fatalError("Metal 4 compile must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try compiler.makeRenderPipelineState(
            descriptor: MTL4RenderPipelineDescriptor(),
            dynamicLinkingDescriptor: nil,
            compilerTaskOptions: nil
        )
        fatalError("Metal 4 render pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try compiler.makeComputePipelineState(
            descriptor: MTL4ComputePipelineDescriptor(),
            dynamicLinkingDescriptor: nil,
            compilerTaskOptions: nil
        )
        fatalError("Metal 4 compute pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let taskOptions = MTL4CompilerTaskOptions()
    taskOptions.lookupArchives = []
    let binaryDesc = MTL4BinaryFunctionDescriptor()
    binaryDesc.name = "bin"
    binaryDesc.options = .pipelineIndependent
    binaryDesc.functionDescriptor = MTL4LibraryFunctionDescriptor()
    do {
        _ = try compiler.makeBinaryFunction(descriptor: binaryDesc, compilerTaskOptions: taskOptions)
        fatalError("binary function compile must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try compiler.makeDynamicLibrary(library: MTLMakeCPUBuiltinLibrary(device))
        fatalError("dynamic library from Metal 4 compiler must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try compiler.makeDynamicLibrary(url: URL(fileURLWithPath: "/tmp/missing.metallib"))
        fatalError("dynamic library URL must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let cpuPipeline = try! device.makeRenderPipelineState(descriptor: {
        let d = MTLRenderPipelineDescriptor()
        d.colorAttachments[0].pixelFormat = .rgba8Unorm
        return d
    }())
    do {
        _ = try compiler.makeRenderPipelineStateBySpecialization(
            descriptor: MTL4PipelineDescriptor(),
            pipeline: cpuPipeline
        )
        fatalError("specialization must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }

    let dispatchBuffer = device.makeCommandBuffer()!
    dispatchBuffer.beginCommandBuffer(allocator: allocator)
    let accel = device.makeAccelerationStructure(size: 0)!
    precondition(accel.size == 0)
    _ = accel.gpuResourceID
    let computeDispatch = dispatchBuffer.makeComputeCommandEncoder()!
    let builtin = MTLMakeCPUBuiltinLibrary(device).makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let computeState = try! device.makeComputePipelineState(function: builtin)
    computeDispatch.setComputePipelineState(computeState)
    computeDispatch.dispatchThreadgroups(threadgroupsPerGrid: MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    computeDispatch.dispatchThreadgroups(indirectBuffer: 0, threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    computeDispatch.dispatchThreads(threadsPerGrid: MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    computeDispatch.dispatchThreads(indirectBuffer: 0)
    let icb = device.makeIndirectCommandBuffer(
        descriptor: MTLIndirectCommandBufferDescriptor(),
        maxCommandCount: 1,
        options: []
    )!
    computeDispatch.executeCommands(buffer: icb, indirectBuffer: 0)
    computeDispatch.build(
        destinationAccelerationStructure: accel,
        descriptor: MTL4AccelerationStructureDescriptor(),
        scratchBuffer: MTL4BufferRangeMake(0, 0)
    )
    computeDispatch.copy(sourceAccelerationStructure: accel, destinationAccelerationStructure: accel)
    computeDispatch.copyAndCompact(sourceAccelerationStructure: accel, destinationAccelerationStructure: accel)
    computeDispatch.refit(
        sourceAccelerationStructure: accel,
        descriptor: MTL4AccelerationStructureDescriptor(),
        destinationAccelerationStructure: accel,
        scratchBuffer: MTL4BufferRangeMake(0, 0),
        options: []
    )
    computeDispatch.writeCompactedSize(sourceAccelerationStructure: accel, destinationBuffer: MTL4BufferRangeMake(0, 0))
    computeDispatch.endEncoding()
    dispatchBuffer.endCommandBuffer()
    var sawDispatchError = false
    let dispatchOptions = MTL4CommitOptions()
    dispatchOptions.addFeedbackHandler { feedback in
        sawDispatchError = true
        precondition((feedback.error as? MTL4CommandQueueError)?.code == .notPermitted)
    }
    queue.commit([dispatchBuffer], options: dispatchOptions)
    precondition(sawDispatchError)

    let heapDesc = MTL4CounterHeapDescriptor()
    heapDesc.count = 2
    heapDesc.type = .timestamp
    let counterHeap = try! device.makeCounterHeap(descriptor: heapDesc)
    precondition(counterHeap.count == 2)
    precondition(counterHeap.type == .timestamp)
    precondition(device.size(ofCounterHeapEntry: .timestamp) == 8)
    precondition(device.size(ofCounterHeapEntry: .invalid) == 0)
    counterHeap.label = "ts"
    let stampBuffer = device.makeCommandBuffer()!
    stampBuffer.beginCommandBuffer(allocator: allocator)
    stampBuffer.writeTimestamp(counterHeap: counterHeap, index: 0)
    let stampCompute = stampBuffer.makeComputeCommandEncoder()!
    stampCompute.writeTimestamp(granularity: .relaxed, counterHeap: counterHeap, index: 1)
    stampCompute.endEncoding()
    stampBuffer.resolveCounterHeap(
        counterHeap,
        range: 0..<2,
        buffer: MTL4BufferRangeMake(0, 16),
        fenceToWait: nil,
        fenceToUpdate: fence
    )
    stampBuffer.endCommandBuffer()
    var stampOK = false
    let stampOptions = MTL4CommitOptions()
    stampOptions.addFeedbackHandler { feedback in
        stampOK = feedback.error == nil
    }
    queue.commit([stampBuffer], options: stampOptions)
    precondition(stampOK)
    let resolved = try! counterHeap.resolveCounterRange(0..<2)
    precondition(resolved != nil)
    precondition(resolved!.count == 16)
    counterHeap.invalidateCounterRange(0..<2)
    let cleared = try! counterHeap.resolveCounterRange(0..<2)!
    precondition(cleared.withUnsafeBytes { $0.load(as: UInt64.self) } == 0)

    let scope = MTLCaptureManager.shared().makeCaptureScope(commandQueue: queue)
    _ = scope.device
    scope.begin()
    scope.end()

    do {
        _ = try device.makeArchive(url: URL(fileURLWithPath: "/tmp/missing.mtl4archive"))
        fatalError("archive load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let serializerDesc = MTL4PipelineDataSetSerializerDescriptor()
    serializerDesc.configuration = [.captureDescriptors]
    let serializer = device.makePipelineDataSetSerializer(descriptor: serializerDesc)
    do {
        _ = try serializer.serializeAsPipelinesScript()
        fatalError("pipeline script serialize must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        try serializer.serializeAsArchiveAndFlush(url: URL(fileURLWithPath: "/tmp/out.archive"))
        fatalError("archive flush must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
}

func testAccelerationStructureCommandEncoder() {
    let device = MTLCreateSystemDefaultDevice()!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let accel = device.makeAccelerationStructure(size: 0)!
    let dest = device.makeAccelerationStructure(size: 0)!
    let scratch = device.makeBuffer(length: 16, options: .storageModeShared)!
    let compacted = device.makeBuffer(length: 8, options: .storageModeShared)!
    compacted.contents().storeBytes(of: UInt32(99), as: UInt32.self)
    let heap = device.makeHeap(descriptor: {
        let desc = MTLHeapDescriptor()
        desc.size = 64
        return desc
    }())!
    let fence = device.makeFence()!
    let pass = MTLAccelerationStructurePassDescriptor.accelerationStructurePassDescriptor()
    pass.sampleBufferAttachments[0].sampleBuffer = try! device.makeCounterSampleBuffer(
        descriptor: MTLCounterSampleBufferDescriptor()
    )
    pass.sampleBufferAttachments[0].startOfEncoderSampleIndex = 0
    pass.sampleBufferAttachments[0].endOfEncoderSampleIndex = 0
    let encoder = commandBuffer.makeAccelerationStructureCommandEncoder(descriptor: pass)
    encoder.label = "as"
    encoder.insertDebugSignpost("build")
    encoder.pushDebugGroup("g")
    encoder.popDebugGroup()
    encoder.build(
        accelerationStructure: accel,
        descriptor: MTLAccelerationStructureDescriptor(),
        scratchBuffer: scratch,
        scratchBufferOffset: 0
    )
    encoder.copy(sourceAccelerationStructure: accel, destinationAccelerationStructure: dest)
    encoder.copyAndCompact(sourceAccelerationStructure: accel, destinationAccelerationStructure: dest)
    encoder.refit(
        sourceAccelerationStructure: accel,
        descriptor: MTLAccelerationStructureDescriptor(),
        destinationAccelerationStructure: dest,
        scratchBuffer: scratch,
        scratchBufferOffset: 0
    )
    encoder.refit(
        sourceAccelerationStructure: accel,
        descriptor: MTLAccelerationStructureDescriptor(),
        destinationAccelerationStructure: nil,
        scratchBuffer: nil,
        scratchBufferOffset: 0,
        options: .vertexData
    )
    encoder.writeCompactedSize(accelerationStructure: accel, buffer: compacted, offset: 0)
    encoder.writeCompactedSize(
        accelerationStructure: accel,
        buffer: compacted,
        offset: 4,
        sizeDataType: .uint
    )
    encoder.useResource(scratch, usage: .read)
    encoder.useResources([scratch], usage: .write)
    encoder.useHeap(heap)
    encoder.useHeaps([heap])
    encoder.updateFence(fence)
    encoder.waitForFence(fence)
    let counters = try! device.makeCounterSampleBuffer(descriptor: {
        let desc = MTLCounterSampleBufferDescriptor()
        desc.sampleCount = 1
        return desc
    }())
    encoder.sampleCounters(sampleBuffer: counters, sampleIndex: 0, barrier: false)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.status == .completed)
    precondition(compacted.contents().load(as: UInt32.self) == 0)
    let other = queue.makeCommandBuffer()!
    precondition(other.makeAccelerationStructureCommandEncoder() != nil)
    other.makeAccelerationStructureCommandEncoder()?.endEncoding()
    other.commit()
    other.waitUntilCompleted()
}

private func libraryDescriptorFixture() -> MTL4LibraryDescriptor {
    let descriptor = MTL4LibraryDescriptor()
    descriptor.source = "not msl"
    return descriptor
}
