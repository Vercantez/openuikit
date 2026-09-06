import Dispatch
import Foundation
import Metal

// from MetalBufferTests.swift
func testBufferStorage() {
    let device = MTLCreateSystemDefaultDevice()!
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let source = bytes.withUnsafeBytes { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: bytes.count, options: .storageModeShared)!
    }
    precondition(source.length == 5)
    precondition(source.allocatedSize >= 5)
    precondition(source.contents().load(as: UInt8.self) == 1)
    source.didModifyRange(0..<5)
    source.addDebugMarker("src", range: 0..<5)
    source.removeAllDebugMarkers()
    source.label = "source"
    precondition(source.label == "source")
    precondition(source.storageMode == .shared)
    precondition(source.cpuCacheMode == .defaultCache)
    _ = source.hazardTrackingMode
    _ = source.resourceOptions
    _ = source.gpuAddress
    _ = source.sparseBufferTier
    _ = source.heap
    _ = source.heapOffset
    _ = source.setPurgeableState(.nonVolatile)
    source.makeAliasable()
    _ = source.isAliasable()
    let destination = device.makeBuffer(length: 8, options: [])!
    precondition(destination.length == 8)
    precondition(destination.contents().load(as: UInt8.self) == 0)
    var borrowed = [UInt8](repeating: 9, count: 4)
    let noCopy = borrowed.withUnsafeMutableBytes { raw in
        device.makeBuffer(
            bytesNoCopy: raw.baseAddress!,
            length: 4,
            options: .cpuCacheModeDefaultCache,
            deallocator: { _, _ in }
        )!
    }
    precondition(noCopy.length == 4)
    let privateBuf = device.makeBuffer(length: 4, options: .storageModePrivate)!
    precondition(privateBuf.storageMode == .private)
    privateBuf.contents().storeBytes(of: UInt32(0xAABBCCDD), as: UInt32.self)
    privateBuf.didModifyRange(0..<4)
    let privateDest = device.makeBuffer(length: 4, options: .storageModeShared)!
    let queue = device.makeCommandQueue()!
    let copy = queue.makeCommandBuffer()!
    let blit = copy.makeBlitCommandEncoder()!
    blit.copy(from: privateBuf, sourceOffset: 0, to: privateDest, destinationOffset: 0, size: 4)
    blit.endEncoding()
    copy.commit()
    copy.waitUntilCompleted()
    precondition(privateDest.contents().load(as: UInt32.self) == 0xAABBCCDD)
    let viewDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    viewDesc.usage = [.shaderRead]
    let layout: [UInt8] = [1, 2, 0xAA, 0xBB, 3, 4, 0xCC, 0xDD]
    layout.withUnsafeBytes { raw in
        destination.contents().copyMemory(from: raw.baseAddress!, byteCount: 8)
    }
    let view = destination.makeTexture(descriptor: viewDesc, offset: 0, bytesPerRow: 4)!
    precondition(view.buffer === destination)
    precondition(view.bufferOffset == 0)
    precondition(view.bufferBytesPerRow == 4)
    var fromView = [UInt8](repeating: 0, count: 4)
    fromView.withUnsafeMutableBytes { raw in
        view.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            from: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0
        )
    }
    precondition(fromView == [1, 2, 3, 4])
    _ = destination.device
}

// from MetalCommandTests.swift
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

// from MetalComputeTests.swift
func testCPUBuiltinCompute() {
    let device = MTLCreateSystemDefaultDevice()!
    let library = MTLMakeCPUBuiltinLibrary(device)
    library.label = "cpu-builtin"
    precondition(library.label == "cpu-builtin")
    precondition(library.device.name == device.name)
    precondition(library.functionNames.contains(MTLCPUBuiltinKernel.fillUInt32.rawValue))
    precondition(library.type == .executable)
    _ = library.installName
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    precondition(fill.name == MTLCPUBuiltinKernel.fillUInt32.rawValue)
    precondition(fill.functionType == .kernel)
    precondition(fill.device.name == device.name)
    _ = fill.options
    _ = fill.patchType
    _ = fill.patchControlPointCount
    _ = fill.vertexAttributes
    _ = fill.stageInputAttributes
    _ = fill.functionConstantsDictionary
    fill.label = "fill"
    precondition(fill.label == "fill")
    _ = fill.makeArgumentEncoder(bufferIndex: 0)
    let descriptor = MTLFunctionDescriptor()
    descriptor.name = MTLCPUBuiltinKernel.fillUInt32.rawValue
    _ = try! library.makeFunction(descriptor: descriptor)
    _ = try! library.makeFunction(name: fill.name, constantValues: MTLFunctionConstantValues())
    precondition(library.reflection(functionName: fill.name) == nil)
    let pipeline = try! device.makeComputePipelineState(function: fill)
    precondition(pipeline.maxTotalThreadsPerThreadgroup == 64)
    precondition(pipeline.threadExecutionWidth == 1)
    precondition(pipeline.staticThreadgroupMemoryLength == 0)
    precondition(!pipeline.supportIndirectCommandBuffers)
    precondition(pipeline.shaderValidation == .disabled)
    _ = pipeline.requiredThreadsPerThreadgroup
    _ = pipeline.allocatedSize
    _ = pipeline.gpuResourceID
    _ = pipeline.imageblockMemoryLength(forDimensions: MTLSizeMake(1, 1, 1))
    let computeDesc = MTLComputePipelineDescriptor()
    computeDesc.computeFunction = fill
    _ = try! device.makeComputePipelineState(descriptor: computeDesc)
    let buffer = device.makeBuffer(length: 16, options: [])!
    var constant: UInt32 = 0xA1B2C3D4
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.label = "compute"
    precondition(encoder.dispatchType == .serial)
    encoder.setComputePipelineState(pipeline)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    encoder.setBuffer(buffer, offset: 0, attributeStride: 4, index: 0)
    encoder.setBufferOffset(0, index: 0)
    encoder.setBufferOffset(offset: 0, attributeStride: 4, index: 0)
    withUnsafeBytes(of: &constant) { raw in
        encoder.setBytes(raw.baseAddress!, length: 4, index: 1)
        encoder.setBytes(raw.baseAddress!, length: 4, attributeStride: 4, index: 1)
    }
    encoder.setTexture(nil, index: 0)
    encoder.setSamplerState(nil, index: 0)
    encoder.setSamplerState(nil, lodMinClamp: 0, lodMaxClamp: 1, index: 0)
    encoder.setThreadgroupMemoryLength(0, index: 0)
    encoder.setImageblockWidth(1, height: 1)
    encoder.setStageInRegion(MTLRegionMake2D(0, 0, 1, 1))
    encoder.memoryBarrier(scope: .buffers)
    encoder.useResource(buffer, usage: .write)
    encoder.useHeap(device.makeHeap(descriptor: MTLHeapDescriptor())!)
    encoder.barrier(afterQueueStages: .dispatch, beforeStages: .dispatch)
    encoder.dispatchThreadgroups(MTLSizeMake(4, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    for index in 0..<4 {
        let value = buffer.contents().advanced(by: index * 4).load(as: UInt32.self)
        precondition(value == 0xA1B2C3D4)
    }

    let addFn = library.makeFunction(name: MTLCPUBuiltinKernel.addUInt32.rawValue)!
    let addPipeline = try! device.makeComputePipelineState(function: addFn)
    let a = device.makeBuffer(length: 8, options: [])!
    let b = device.makeBuffer(length: 8, options: [])!
    let out = device.makeBuffer(length: 8, options: [])!
    a.contents().storeBytes(of: UInt32(2), as: UInt32.self)
    a.contents().advanced(by: 4).storeBytes(of: UInt32(3), as: UInt32.self)
    b.contents().storeBytes(of: UInt32(5), as: UInt32.self)
    b.contents().advanced(by: 4).storeBytes(of: UInt32(7), as: UInt32.self)
    let addBuffer = queue.makeCommandBuffer()!
    let addEncoder = addBuffer.makeComputeCommandEncoder(dispatchType: .serial)!
    addEncoder.setComputePipelineState(addPipeline)
    addEncoder.setBuffer(a, offset: 0, index: 0)
    addEncoder.setBuffer(b, offset: 0, index: 1)
    addEncoder.setBuffer(out, offset: 0, index: 2)
    addEncoder.dispatchThreads(MTLSizeMake(2, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    addEncoder.endEncoding()
    addBuffer.commit()
    addBuffer.waitUntilCompleted()
    precondition(out.contents().load(as: UInt32.self) == 7)
    precondition(out.contents().advanced(by: 4).load(as: UInt32.self) == 10)

    let copyFn = library.makeFunction(name: MTLCPUBuiltinKernel.copyUInt8.rawValue)!
    let copyPipeline = try! device.makeComputePipelineState(function: copyFn)
    let src = device.makeBuffer(length: 3, options: [])!
    let dst = device.makeBuffer(length: 3, options: [])!
    src.contents().storeBytes(of: UInt8(9), as: UInt8.self)
    src.contents().advanced(by: 1).storeBytes(of: UInt8(8), as: UInt8.self)
    src.contents().advanced(by: 2).storeBytes(of: UInt8(7), as: UInt8.self)
    let copyPass = MTLComputePassDescriptor()
    let copyCB = queue.makeCommandBuffer()!
    let copyEnc = copyCB.makeComputeCommandEncoder(descriptor: copyPass)!
    copyEnc.setComputePipelineState(copyPipeline)
    copyEnc.setBuffer(src, offset: 0, index: 0)
    copyEnc.setBuffer(dst, offset: 0, index: 1)
    copyEnc.dispatchThreadgroups(MTLSizeMake(3, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    copyEnc.endEncoding()
    copyCB.commit()
    copyCB.waitUntilCompleted()
    precondition(dst.contents().load(as: UInt8.self) == 9)
    precondition(library.makeFunction(name: "kernel void k()") == nil)
}

// from MetalDescriptorTests.swift
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

func testMetal4PipelineDescriptors() {
    let options = MTL4PipelineOptions()
    options.shaderReflection = .bindingInfo
    options.shaderValidation = .disabled
    precondition(options.shaderReflection.contains(.bindingInfo))
    let binary = MTL4RenderPipelineBinaryFunctionsDescriptor()
    binary.vertexAdditionalBinaryFunctions = []
    binary.fragmentAdditionalBinaryFunctions = []
    binary.meshAdditionalBinaryFunctions = []
    binary.objectAdditionalBinaryFunctions = []
    binary.tileAdditionalBinaryFunctions = []
    binary.reset()
    precondition(binary.vertexAdditionalBinaryFunctions == nil)

    let function = MTL4LibraryFunctionDescriptor()
    function.name = "vertex_main"
    function.library = nil
    let specialized = MTL4SpecializedFunctionDescriptor()
    specialized.functionDescriptor = function
    specialized.specializedName = "spec"
    specialized.constantValues = MTLFunctionConstantValues()
    let linking = MTL4StaticLinkingDescriptor()
    linking.functionDescriptors = [function]
    linking.privateFunctionDescriptors = []
    linking.groups = ["g": [function]]
    precondition(linking.groups?["g"]?.count == 1)

    let libraryDesc = MTL4LibraryDescriptor()
    libraryDesc.source = "kernel void k() {}"
    libraryDesc.name = "k"
    libraryDesc.options = MTLCompileOptions()
    precondition(libraryDesc.name == "k")

    let color = MTL4RenderPipelineColorAttachmentDescriptor()
    color.pixelFormat = .rgba8Unorm
    color.blendingState = .enabled
    color.sourceRGBBlendFactor = .one
    color.destinationRGBBlendFactor = .zero
    color.rgbBlendOperation = .add
    color.sourceAlphaBlendFactor = .one
    color.destinationAlphaBlendFactor = .zero
    color.alphaBlendOperation = .add
    color.writeMask = .all
    precondition(color.pixelFormat == .rgba8Unorm)
    color.reset()
    precondition(color.pixelFormat == .invalid)
    let colors = MTL4RenderPipelineColorAttachmentDescriptorArray()
    colors[0].pixelFormat = .bgra8Unorm
    precondition(colors[0].pixelFormat == .bgra8Unorm)
    colors.reset()
    precondition(colors[0].pixelFormat == .invalid)

    let render = MTL4RenderPipelineDescriptor()
    render.label = "r4"
    render.options = options
    render.vertexFunctionDescriptor = function
    render.fragmentFunctionDescriptor = specialized
    render.vertexDescriptor = MTLVertexDescriptor()
    render.colorAttachments[0].pixelFormat = .rgba8Unorm
    render.rasterSampleCount = 1
    render.alphaToCoverageState = .enabled
    render.alphaToOneState = .disabled
    render.isRasterizationEnabled = true
    render.maxVertexAmplificationCount = 1
    render.inputPrimitiveTopology = .triangle
    render.supportIndirectCommandBuffers = .disabled
    render.supportVertexBinaryLinking = false
    render.supportFragmentBinaryLinking = false
    render.colorAttachmentMappingState = .identity
    render.vertexStaticLinkingDescriptor = linking
    render.fragmentStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
    precondition(render.label == "r4")
    precondition(render.colorAttachments[0].pixelFormat == .rgba8Unorm)
    render.reset()
    precondition(render.label == nil)
    precondition(render.rasterSampleCount == 1)

    let mesh = MTL4MeshRenderPipelineDescriptor()
    mesh.label = "mesh4"
    mesh.objectFunctionDescriptor = function
    mesh.meshFunctionDescriptor = function
    mesh.fragmentFunctionDescriptor = function
    mesh.colorAttachments[0].pixelFormat = .rgba8Unorm
    mesh.rasterSampleCount = 1
    mesh.alphaToCoverageState = .disabled
    mesh.alphaToOneState = .enabled
    mesh.isRasterizationEnabled = true
    mesh.maxVertexAmplificationCount = 1
    mesh.maxTotalThreadsPerObjectThreadgroup = 32
    mesh.maxTotalThreadsPerMeshThreadgroup = 64
    mesh.maxTotalThreadgroupsPerMeshGrid = 4
    mesh.payloadMemoryLength = 16
    mesh.objectThreadgroupSizeIsMultipleOfThreadExecutionWidth = true
    mesh.meshThreadgroupSizeIsMultipleOfThreadExecutionWidth = true
    mesh.requiredThreadsPerObjectThreadgroup = MTLSizeMake(8, 1, 1)
    mesh.requiredThreadsPerMeshThreadgroup = MTLSizeMake(16, 1, 1)
    mesh.supportIndirectCommandBuffers = .enabled
    mesh.supportObjectBinaryLinking = false
    mesh.supportMeshBinaryLinking = false
    mesh.supportFragmentBinaryLinking = false
    mesh.colorAttachmentMappingState = .inherited
    mesh.objectStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
    mesh.meshStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
    mesh.fragmentStaticLinkingDescriptor = MTL4StaticLinkingDescriptor()
    precondition(mesh.maxTotalThreadsPerMeshThreadgroup == 64)
    mesh.reset()
    precondition(mesh.label == nil)

    let compute = MTL4ComputePipelineDescriptor()
    compute.computeFunctionDescriptor = function
    compute.maxTotalThreadsPerThreadgroup = 64
    compute.requiredThreadsPerThreadgroup = MTLSizeMake(8, 1, 1)
    compute.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
    compute.supportIndirectCommandBuffers = .disabled
    compute.supportBinaryLinking = false
    compute.staticLinkingDescriptor = linking
    compute.reset()
    precondition(compute.computeFunctionDescriptor == nil)

    let tile = MTL4TileRenderPipelineDescriptor()
    tile.tileFunctionDescriptor = function
    tile.colorAttachments[0].pixelFormat = .rgba8Unorm
    tile.rasterSampleCount = 1
    tile.threadgroupSizeMatchesTileSize = true
    tile.maxTotalThreadsPerThreadgroup = 32
    tile.requiredThreadsPerThreadgroup = MTLSizeMake(8, 8, 1)
    tile.supportBinaryLinking = false
    tile.staticLinkingDescriptor = MTL4StaticLinkingDescriptor()
    tile.reset()
    precondition(tile.tileFunctionDescriptor == nil)

    let stage = MTL4PipelineStageDynamicLinkingDescriptor()
    stage.binaryLinkedFunctions = []
    stage.maxCallStackDepth = 2
    stage.preloadedLibraries = []
    let dynamic = MTL4RenderPipelineDynamicLinkingDescriptor()
    _ = dynamic.vertexLinkingDescriptor.maxCallStackDepth
    _ = dynamic.fragmentLinkingDescriptor
    _ = dynamic.meshLinkingDescriptor
    _ = dynamic.objectLinkingDescriptor
    _ = dynamic.tileLinkingDescriptor

    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.inputPrimitiveTopology = .triangle
    pipeline.maxTessellationFactor = 16
    pipeline.isTessellationFactorScaleEnabled = false
    pipeline.tessellationFactorFormat = .half
    pipeline.tessellationControlPointIndexType = .none
    pipeline.tessellationFactorStepFunction = .constant
    pipeline.tessellationOutputWindingOrder = .clockwise
    pipeline.tessellationPartitionMode = .pow2
    pipeline.vertexPreloadedLibraries = []
    pipeline.fragmentPreloadedLibraries = []
    precondition(pipeline.inputPrimitiveTopology == .triangle)
    pipeline.reset()
    precondition(pipeline.tessellationPartitionMode == .pow2)

    let argument = MTLArgument()
    argument.name = "buf"
    argument.type = .buffer
    argument.access = .readOnly
    argument.index = 1
    argument.isActive = true
    argument.arrayLength = 4
    argument.bufferAlignment = 16
    argument.bufferDataSize = 64
    argument.bufferDataType = .float4
    argument.bufferPointerType = MTLPointerType()
    argument.bufferStructType = MTLStructType()
    argument.isDepthTexture = false
    argument.textureDataType = .none
    argument.textureType = .type2D
    argument.threadgroupMemoryAlignment = 16
    argument.threadgroupMemoryDataSize = 32
    precondition(argument.bufferAlignment == 16)
    let members = MTLStructMember()
    members.name = "x"
    argument.bufferStructType?.members = [members]
    precondition(argument.bufferStructType?.memberByName("x")?.name == "x")
    _ = members.arrayType()
    _ = members.pointerType()
    _ = members.structType()
    _ = members.textureReferenceType()
    _ = members.tensorReferenceType()
    members.dataType = .float
    members.offset = 0
    members.argumentIndex = 1
    let array = MTLArrayType()
    array.arrayLength = 2
    array.stride = 16
    array.argumentIndexStride = 1
    array.elementType = .float
    _ = array.element()
    _ = array.elementPointerType()
    _ = array.elementStructType()
    _ = array.elementTensorReferenceType()
    _ = array.elementTextureReferenceType()
    let pointer = MTLPointerType()
    pointer.access = .readOnly
    pointer.alignment = 16
    pointer.dataSize = 8
    pointer.elementIsArgumentBuffer = false
    pointer.elementType = .float
    _ = pointer.elementArrayType()
    _ = pointer.elementStructType()
    let texRef = MTLTextureReferenceType()
    texRef.access = .readOnly
    texRef.isDepthTexture = false
    texRef.textureDataType = .float
    texRef.textureType = .type2D
    _ = MTLTensorReferenceType()
    _ = texRef.textureType

    let compilerDesc = MTL4CompilerDescriptor()
    compilerDesc.pipelineDataSetSerializer = nil
    _ = compilerDesc.label
    let task = MTL4CompilerTaskOptions()
    task.lookupArchives = nil
    _ = task.lookupArchives
    let binaryFn = MTL4BinaryFunctionDescriptor()
    binaryFn.name = "n"
    binaryFn.options = []
    binaryFn.functionDescriptor = MTL4FunctionDescriptor()
    precondition(binaryFn.name == "n")
    let heap = MTL4CounterHeapDescriptor()
    heap.count = 4
    heap.type = .timestamp
    precondition(heap.count == 4)
    let serializer = MTL4PipelineDataSetSerializerDescriptor()
    serializer.configuration = [.captureBinaries, .captureDescriptors]
    precondition(serializer.configuration.contains(.captureBinaries))
    let argumentAccess: MTLArgumentAccess = .readWrite
    _ = argumentAccess
    _ = MTLArgumentAccess.readOnly
}

// from MetalDeviceTests.swift
func testCPUDevice() {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("CPU reference device must exist")
    }
    let devices = MTLCopyAllDevices()
    precondition(devices.count == 1)
    precondition(device.name == "OpenUIKit CPU Reference")
    precondition(device.registryID != 0)
    precondition(device.architecture.name == "cpu")
    precondition(device.hasUnifiedMemory)
    precondition(device.maxThreadsPerThreadgroup.width == 64)
    precondition(device.recommendedMaxWorkingSetSize > 0)
    precondition(device.maxBufferLength > 0)
    precondition(device.maxThreadgroupMemoryLength > 0)
    precondition(device.maxArgumentBufferSamplerCount >= 1)
    precondition(device.argumentBuffersSupport == .tier1)
    precondition(device.readWriteTextureSupport == .tierNone)
    precondition(!device.areBarycentricCoordsSupported)
    precondition(!device.areRasterOrderGroupsSupported)
    precondition(!device.areProgrammableSamplePositionsSupported)
    precondition(device.sparseTileSizeInBytes == 0)
    precondition(!device.supports32BitFloatFiltering)
    precondition(!device.supports32BitMSAA)
    precondition(!device.supportsBCTextureCompression)
    precondition(!device.supportsPullModelInterpolation)
    precondition(!device.supportsShaderBarycentricCoordinates)
    precondition(!device.supportsQueryTextureLOD)
    precondition(!device.supportsFunctionPointers)
    precondition(!device.supportsFunctionPointersFromRender)
    precondition(!device.supportsRaytracing)
    precondition(!device.supportsRaytracingFromRender)
    precondition(!device.supportsPrimitiveMotionBlur)
    precondition(!device.supportsDynamicLibraries)
    precondition(!device.supportsRenderDynamicLibraries)
    precondition(device.maximumConcurrentCompilationTaskCount == 1)
    _ = device.currentAllocatedSize
    precondition(!device.supportsFamily(.apple1))
    precondition(!device.supportsFamily(.metal3))
    precondition(!device.supportsFeatureSet(.iOS_GPUFamily1_v1))
    precondition(device.supportsTextureSampleCount(1))
    precondition(!device.supportsTextureSampleCount(4))
    precondition(device.supportsVertexAmplificationCount(1))
    precondition(!device.supportsRasterizationRateMap(layerCount: 1))
    precondition(!device.supportsCounterSampling(.atStageBoundary))
    precondition(device.minimumLinearTextureAlignment(for: .rgba8Unorm) == 16)
    precondition(device.minimumTextureBufferAlignment(for: .rgba8Unorm) == 16)
    let sized = device.heapBufferSizeAndAlign(length: 17, options: [])
    precondition(sized.size >= 17 && sized.align == 16)
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    let textureAlign = device.heapTextureSizeAndAlign(descriptor: textureDesc)
    precondition(textureAlign.size > 0)
    precondition(device.makeCommandQueue() != nil)
    precondition(device.makeCommandQueue(maxCommandBufferCount: 8) != nil)
    precondition(device.makeCommandQueue(descriptor: MTLCommandQueueDescriptor()) != nil)
    let sampler = MTLSamplerDescriptor()
    sampler.minFilter = .linear
    sampler.sAddressMode = .clampToEdge
    let samplerState = device.makeSamplerState(descriptor: sampler)!
    precondition(samplerState.device.name == device.name)
    _ = samplerState.label
    _ = samplerState.gpuResourceID
    let depth = MTLDepthStencilDescriptor()
    depth.isDepthWriteEnabled = true
    depth.depthCompareFunction = .less
    let depthState = device.makeDepthStencilState(descriptor: depth)!
    precondition(depthState.device.name == device.name)
    _ = depthState.label
    _ = depthState.gpuResourceID
    precondition(device.makeDefaultLibrary() == nil)
    let samples = device.getDefaultSamplePositions(sampleCount: 1)
    precondition(samples.count == 1)
    precondition(device.getDefaultSamplePositions(sampleCount: 4).isEmpty)
}

func testDeviceFactoryAndFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let timestamps = device.sampleTimestamps()
    precondition(timestamps.cpu > 0)
    precondition(timestamps.gpu == timestamps.cpu)
    let shared = device.makeBuffer(length: 8, options: .storageModeShared)!
    precondition(shared.length == 8)
    var payload: UInt32 = 0x11223344
    let copied = withUnsafeBytes(of: &payload) { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: 4, options: .storageModeShared)!
    }
    precondition(copied.contents().load(as: UInt32.self) == 0x11223344)
    var borrowed = [UInt8](repeating: 7, count: 2)
    let noCopy = borrowed.withUnsafeMutableBytes { raw in
        device.makeBuffer(
            bytesNoCopy: raw.baseAddress!,
            length: 2,
            options: .storageModeShared,
            deallocator: { _, _ in }
        )!
    }
    precondition(noCopy.length == 2)
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    let texture = device.makeTexture(descriptor: textureDesc)!
    precondition(texture.width == 2)
    let heapDesc = MTLHeapDescriptor()
    heapDesc.size = 128
    precondition(device.makeHeap(descriptor: heapDesc) != nil)
    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.dataType = .float
    argument.index = 0
    precondition(device.makeArgumentEncoder(arguments: [argument]) != nil)
    precondition(device.makeDefaultLibrary() == nil)
    do {
        _ = try device.makeLibrary(data: DispatchData.empty)
        fatalError("DispatchData metallib load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let render = MTLRenderPipelineDescriptor()
    render.colorAttachments[0].pixelFormat = .rgba8Unorm
    let (state, reflection) = try! device.makeRenderPipelineState(descriptor: render, options: [])
    _ = state
    precondition(reflection == nil)
    do {
        _ = try device.makeRenderPipelineState(descriptor: MTLMeshRenderPipelineDescriptor(), options: [])
        fatalError("mesh pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeRenderPipelineState(tileDescriptor: MTLTileRenderPipelineDescriptor(), options: [])
        fatalError("tile pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let compute = MTLComputePipelineDescriptor()
    compute.computeFunction = MTLMakeCPUBuiltinLibrary(device).makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)
    do {
        let (computeState, computeReflection) = try device.makeComputePipelineState(descriptor: compute, options: [])
        _ = computeState.maxTotalThreadsPerThreadgroup
        precondition(computeReflection == nil)
    } catch {
        fatalError("CPU builtin compute pipeline must succeed")
    }
}

func testDeviceFailClosedFactories() {
    let device = MTLCreateSystemDefaultDevice()!
    precondition(device.counterSets?.isEmpty == true)
    precondition(device.queryTimestampFrequency() == 1_000_000_000)
    let asDesc = MTLAccelerationStructureDescriptor()
    let structure = device.makeAccelerationStructure(descriptor: asDesc)!
    precondition(structure.size == 0)
    let sized = device.makeAccelerationStructure(size: 32)!
    precondition(sized.size == 32)
    let heapAlign = device.heapAccelerationStructureSizeAndAlign(size: 48)
    precondition(heapAlign.size == 48)
    precondition(heapAlign.align == 16)
    let descAlign = device.heapAccelerationStructureSizeAndAlign(descriptor: asDesc)
    precondition(descAlign.size == 0)
    var pixels = [MTLRegionMake2D(0, 0, 16, 16)]
    var tiles = [MTLRegion()]
    device.convertSparsePixelRegions(
        &pixels,
        toTileRegions: &tiles,
        withTileSize: MTLSizeMake(0, 0, 1),
        alignmentMode: .outward,
        numRegions: 1
    )
    precondition(tiles[0].size.width == 0)
    pixels = [MTLRegionMake2D(0, 0, 16, 16)]
    device.convertSparsePixelRegions(
        &pixels,
        toTileRegions: &tiles,
        withTileSize: MTLSizeMake(8, 8, 1),
        alignmentMode: .inward,
        numRegions: 1
    )
    precondition(tiles[0].size.width == 2)
    var tileIn = [MTLRegionMake2D(1, 1, 2, 2)]
    var pixelOut = [MTLRegion()]
    device.convertSparseTileRegions(
        &tileIn,
        toPixelRegions: &pixelOut,
        withTileSize: MTLSizeMake(8, 8, 1),
        numRegions: 1
    )
    precondition(pixelOut[0].origin.x == 8)
    precondition(pixelOut[0].size.width == 16)

    var libraryDone = false
    device.makeLibrary(source: "not msl", options: nil) { library, error in
        libraryDone = true
        precondition(library == nil)
        precondition((error as? MTLLibraryError)?.code == .compileFailure)
    }
    precondition(libraryDone)

    var stitchDone = false
    let stitched = MTLStitchedLibraryDescriptor()
    stitched.functions = []
    stitched.functionGraphs = []
    stitched.binaryArchives = nil
    stitched.options = []
    device.makeLibrary(stitchedDescriptor: stitched) { library, error in
        stitchDone = true
        precondition(library == nil)
        precondition((error as? MTLLibraryError)?.code == .compileFailure)
    }
    precondition(stitchDone)
    do {
        _ = try device.makeLibrary(stitchedDescriptor: MTLStitchedLibraryDescriptor())
        fatalError("stitched library must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }

    var renderDone = false
    let renderDesc = MTLRenderPipelineDescriptor()
    renderDesc.colorAttachments[0].pixelFormat = .rgba8Unorm
    device.makeRenderPipelineState(descriptor: renderDesc) { state, error in
        renderDone = true
        precondition(state != nil)
        precondition(error == nil)
    }
    precondition(renderDone)

    var computeDone = false
    let builtin = MTLMakeCPUBuiltinLibrary(device).makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    device.makeComputePipelineState(function: builtin) { state, error in
        computeDone = true
        precondition(state != nil)
        precondition(error == nil)
    }
    precondition(computeDone)

    do {
        _ = try device.makeIOFileHandle(url: URL(fileURLWithPath: "/tmp/missing.bin"))
        fatalError("IO file handle must fail closed")
    } catch let error as MTLIOError {
        precondition(error.code == .internal)
        precondition(MTLIOError.internal ~= error)
        precondition(MTLIOError.errorDomain == MTLIOErrorDomain)
    } catch {
        fatalError("expected MTLIOError")
    }
    do {
        _ = try device.makeIOFileHandle(url: URL(fileURLWithPath: "/tmp/missing.bin"), compressionMethod: .lzfse)
        fatalError("compressed IO handle must fail closed")
    } catch let error as MTLIOError {
        precondition(error.code == .internal)
    } catch {
        fatalError("expected MTLIOError")
    }
    do {
        _ = try device.makeIOHandle(url: URL(fileURLWithPath: "/tmp/missing.bin"))
        fatalError("IO handle must fail closed")
    } catch let error as MTLIOError {
        precondition(error.code == .internal)
    } catch {
        fatalError("expected MTLIOError")
    }
    do {
        _ = try device.makeIOHandle(url: URL(fileURLWithPath: "/tmp/missing.bin"), compressionMethod: .lz4)
        fatalError("compressed IO handle alias must fail closed")
    } catch let error as MTLIOError {
        precondition(error.code == .internal)
    } catch {
        fatalError("expected MTLIOError")
    }

    let counterDesc = MTLCounterSampleBufferDescriptor()
    counterDesc.sampleCount = 1
    counterDesc.label = "counters"
    counterDesc.storageMode = .shared
    counterDesc.counterSet = nil
    let counters = try! device.makeCounterSampleBuffer(descriptor: counterDesc)
    precondition(counters.sampleCount == 1)
    precondition(try! counters.resolveCounterRange(0..<1) == nil)
}

// from MetalEnumTests.swift
func testMetalEnumOptionSetAndConstantValues() {
    _ = MTLArgumentBuffersTier.tier1
    precondition(MTLArgumentBuffersTier.tier1.rawValue == 0)
    precondition(MTLArgumentBuffersTier(rawValue: 0) == MTLArgumentBuffersTier.tier1)
    precondition(MTLArgumentBuffersTier.tier2.rawValue == 1)
    precondition(MTLArgumentBuffersTier(rawValue: 1) == MTLArgumentBuffersTier.tier2)
    precondition(MTLArgumentBuffersTier.tier1 != MTLArgumentBuffersTier.tier2)
    var MTLArgumentBuffersTierSet: Set<MTLArgumentBuffersTier> = [.tier1]
    MTLArgumentBuffersTierSet.insert(.tier2)
    precondition(MTLArgumentBuffersTierSet.count == 2)

    _ = MTLArgumentType.buffer
    precondition(MTLArgumentType.buffer.rawValue == 0)
    precondition(MTLArgumentType(rawValue: 0) == MTLArgumentType.buffer)
    precondition(MTLArgumentType.threadgroupMemory.rawValue == 1)
    precondition(MTLArgumentType(rawValue: 1) == MTLArgumentType.threadgroupMemory)
    precondition(MTLArgumentType.texture.rawValue == 2)
    precondition(MTLArgumentType(rawValue: 2) == MTLArgumentType.texture)
    precondition(MTLArgumentType.sampler.rawValue == 3)
    precondition(MTLArgumentType(rawValue: 3) == MTLArgumentType.sampler)
    precondition(MTLArgumentType.imageblockData.rawValue == 16)
    precondition(MTLArgumentType(rawValue: 16) == MTLArgumentType.imageblockData)
    precondition(MTLArgumentType.imageblock.rawValue == 17)
    precondition(MTLArgumentType(rawValue: 17) == MTLArgumentType.imageblock)
    precondition(MTLArgumentType.visibleFunctionTable.rawValue == 24)
    precondition(MTLArgumentType(rawValue: 24) == MTLArgumentType.visibleFunctionTable)
    precondition(MTLArgumentType.primitiveAccelerationStructure.rawValue == 25)
    precondition(MTLArgumentType(rawValue: 25) == MTLArgumentType.primitiveAccelerationStructure)
    precondition(MTLArgumentType.instanceAccelerationStructure.rawValue == 26)
    precondition(MTLArgumentType(rawValue: 26) == MTLArgumentType.instanceAccelerationStructure)
    precondition(MTLArgumentType.intersectionFunctionTable.rawValue == 27)
    precondition(MTLArgumentType(rawValue: 27) == MTLArgumentType.intersectionFunctionTable)
    precondition(MTLArgumentType.buffer != MTLArgumentType.threadgroupMemory)
    var MTLArgumentTypeSet: Set<MTLArgumentType> = [.buffer]
    MTLArgumentTypeSet.insert(.threadgroupMemory)
    precondition(MTLArgumentTypeSet.count == 2)

    _ = MTLAttributeFormat.invalid
    precondition(MTLAttributeFormat.invalid.rawValue == 0)
    precondition(MTLAttributeFormat(rawValue: 0) == MTLAttributeFormat.invalid)
    precondition(MTLAttributeFormat.uchar2.rawValue == 1)
    precondition(MTLAttributeFormat(rawValue: 1) == MTLAttributeFormat.uchar2)
    precondition(MTLAttributeFormat.uchar3.rawValue == 2)
    precondition(MTLAttributeFormat(rawValue: 2) == MTLAttributeFormat.uchar3)
    precondition(MTLAttributeFormat.uchar4.rawValue == 3)
    precondition(MTLAttributeFormat(rawValue: 3) == MTLAttributeFormat.uchar4)
    precondition(MTLAttributeFormat.char2.rawValue == 4)
    precondition(MTLAttributeFormat(rawValue: 4) == MTLAttributeFormat.char2)
    precondition(MTLAttributeFormat.char3.rawValue == 5)
    precondition(MTLAttributeFormat(rawValue: 5) == MTLAttributeFormat.char3)
    precondition(MTLAttributeFormat.char4.rawValue == 6)
    precondition(MTLAttributeFormat(rawValue: 6) == MTLAttributeFormat.char4)
    precondition(MTLAttributeFormat.uchar2Normalized.rawValue == 7)
    precondition(MTLAttributeFormat(rawValue: 7) == MTLAttributeFormat.uchar2Normalized)
    precondition(MTLAttributeFormat.uchar3Normalized.rawValue == 8)
    precondition(MTLAttributeFormat(rawValue: 8) == MTLAttributeFormat.uchar3Normalized)
    precondition(MTLAttributeFormat.uchar4Normalized.rawValue == 9)
    precondition(MTLAttributeFormat(rawValue: 9) == MTLAttributeFormat.uchar4Normalized)
    precondition(MTLAttributeFormat.char2Normalized.rawValue == 10)
    precondition(MTLAttributeFormat(rawValue: 10) == MTLAttributeFormat.char2Normalized)
    precondition(MTLAttributeFormat.char3Normalized.rawValue == 11)
    precondition(MTLAttributeFormat(rawValue: 11) == MTLAttributeFormat.char3Normalized)
    precondition(MTLAttributeFormat.char4Normalized.rawValue == 12)
    precondition(MTLAttributeFormat(rawValue: 12) == MTLAttributeFormat.char4Normalized)
    precondition(MTLAttributeFormat.ushort2.rawValue == 13)
    precondition(MTLAttributeFormat(rawValue: 13) == MTLAttributeFormat.ushort2)
    precondition(MTLAttributeFormat.ushort3.rawValue == 14)
    precondition(MTLAttributeFormat(rawValue: 14) == MTLAttributeFormat.ushort3)
    precondition(MTLAttributeFormat.ushort4.rawValue == 15)
    precondition(MTLAttributeFormat(rawValue: 15) == MTLAttributeFormat.ushort4)
    precondition(MTLAttributeFormat.short2.rawValue == 16)
    precondition(MTLAttributeFormat(rawValue: 16) == MTLAttributeFormat.short2)
    precondition(MTLAttributeFormat.short3.rawValue == 17)
    precondition(MTLAttributeFormat(rawValue: 17) == MTLAttributeFormat.short3)
    precondition(MTLAttributeFormat.short4.rawValue == 18)
    precondition(MTLAttributeFormat(rawValue: 18) == MTLAttributeFormat.short4)
    precondition(MTLAttributeFormat.ushort2Normalized.rawValue == 19)
    precondition(MTLAttributeFormat(rawValue: 19) == MTLAttributeFormat.ushort2Normalized)
    precondition(MTLAttributeFormat.ushort3Normalized.rawValue == 20)
    precondition(MTLAttributeFormat(rawValue: 20) == MTLAttributeFormat.ushort3Normalized)
    precondition(MTLAttributeFormat.ushort4Normalized.rawValue == 21)
    precondition(MTLAttributeFormat(rawValue: 21) == MTLAttributeFormat.ushort4Normalized)
    precondition(MTLAttributeFormat.short2Normalized.rawValue == 22)
    precondition(MTLAttributeFormat(rawValue: 22) == MTLAttributeFormat.short2Normalized)
    precondition(MTLAttributeFormat.short3Normalized.rawValue == 23)
    precondition(MTLAttributeFormat(rawValue: 23) == MTLAttributeFormat.short3Normalized)
    precondition(MTLAttributeFormat.short4Normalized.rawValue == 24)
    precondition(MTLAttributeFormat(rawValue: 24) == MTLAttributeFormat.short4Normalized)
    precondition(MTLAttributeFormat.half2.rawValue == 25)
    precondition(MTLAttributeFormat(rawValue: 25) == MTLAttributeFormat.half2)
    precondition(MTLAttributeFormat.half3.rawValue == 26)
    precondition(MTLAttributeFormat(rawValue: 26) == MTLAttributeFormat.half3)
    precondition(MTLAttributeFormat.half4.rawValue == 27)
    precondition(MTLAttributeFormat(rawValue: 27) == MTLAttributeFormat.half4)
    precondition(MTLAttributeFormat.float.rawValue == 28)
    precondition(MTLAttributeFormat(rawValue: 28) == MTLAttributeFormat.float)
    precondition(MTLAttributeFormat.float2.rawValue == 29)
    precondition(MTLAttributeFormat(rawValue: 29) == MTLAttributeFormat.float2)
    precondition(MTLAttributeFormat.float3.rawValue == 30)
    precondition(MTLAttributeFormat(rawValue: 30) == MTLAttributeFormat.float3)
    precondition(MTLAttributeFormat.float4.rawValue == 31)
    precondition(MTLAttributeFormat(rawValue: 31) == MTLAttributeFormat.float4)
    precondition(MTLAttributeFormat.int.rawValue == 32)
    precondition(MTLAttributeFormat(rawValue: 32) == MTLAttributeFormat.int)
    precondition(MTLAttributeFormat.int2.rawValue == 33)
    precondition(MTLAttributeFormat(rawValue: 33) == MTLAttributeFormat.int2)
    precondition(MTLAttributeFormat.int3.rawValue == 34)
    precondition(MTLAttributeFormat(rawValue: 34) == MTLAttributeFormat.int3)
    precondition(MTLAttributeFormat.int4.rawValue == 35)
    precondition(MTLAttributeFormat(rawValue: 35) == MTLAttributeFormat.int4)
    precondition(MTLAttributeFormat.uint.rawValue == 36)
    precondition(MTLAttributeFormat(rawValue: 36) == MTLAttributeFormat.uint)
    precondition(MTLAttributeFormat.uint2.rawValue == 37)
    precondition(MTLAttributeFormat(rawValue: 37) == MTLAttributeFormat.uint2)
    precondition(MTLAttributeFormat.uint3.rawValue == 38)
    precondition(MTLAttributeFormat(rawValue: 38) == MTLAttributeFormat.uint3)
    precondition(MTLAttributeFormat.uint4.rawValue == 39)
    precondition(MTLAttributeFormat(rawValue: 39) == MTLAttributeFormat.uint4)
    precondition(MTLAttributeFormat.int1010102Normalized.rawValue == 40)
    precondition(MTLAttributeFormat(rawValue: 40) == MTLAttributeFormat.int1010102Normalized)
    precondition(MTLAttributeFormat.uint1010102Normalized.rawValue == 41)
    precondition(MTLAttributeFormat(rawValue: 41) == MTLAttributeFormat.uint1010102Normalized)
    precondition(MTLAttributeFormat.uchar4Normalized_bgra.rawValue == 42)
    precondition(MTLAttributeFormat(rawValue: 42) == MTLAttributeFormat.uchar4Normalized_bgra)
    precondition(MTLAttributeFormat.uchar.rawValue == 45)
    precondition(MTLAttributeFormat(rawValue: 45) == MTLAttributeFormat.uchar)
    precondition(MTLAttributeFormat.char.rawValue == 46)
    precondition(MTLAttributeFormat(rawValue: 46) == MTLAttributeFormat.char)
    precondition(MTLAttributeFormat.ucharNormalized.rawValue == 47)
    precondition(MTLAttributeFormat(rawValue: 47) == MTLAttributeFormat.ucharNormalized)
    precondition(MTLAttributeFormat.charNormalized.rawValue == 48)
    precondition(MTLAttributeFormat(rawValue: 48) == MTLAttributeFormat.charNormalized)
    precondition(MTLAttributeFormat.ushort.rawValue == 49)
    precondition(MTLAttributeFormat(rawValue: 49) == MTLAttributeFormat.ushort)
    precondition(MTLAttributeFormat.short.rawValue == 50)
    precondition(MTLAttributeFormat(rawValue: 50) == MTLAttributeFormat.short)
    precondition(MTLAttributeFormat.ushortNormalized.rawValue == 51)
    precondition(MTLAttributeFormat(rawValue: 51) == MTLAttributeFormat.ushortNormalized)
    precondition(MTLAttributeFormat.shortNormalized.rawValue == 52)
    precondition(MTLAttributeFormat(rawValue: 52) == MTLAttributeFormat.shortNormalized)
    precondition(MTLAttributeFormat.half.rawValue == 53)
    precondition(MTLAttributeFormat(rawValue: 53) == MTLAttributeFormat.half)
    precondition(MTLAttributeFormat.floatRG11B10.rawValue == 54)
    precondition(MTLAttributeFormat(rawValue: 54) == MTLAttributeFormat.floatRG11B10)
    precondition(MTLAttributeFormat.floatRGB9E5.rawValue == 55)
    precondition(MTLAttributeFormat(rawValue: 55) == MTLAttributeFormat.floatRGB9E5)
    precondition(MTLAttributeFormat.invalid != MTLAttributeFormat.uchar2)
    var MTLAttributeFormatSet: Set<MTLAttributeFormat> = [.invalid]
    MTLAttributeFormatSet.insert(.uchar2)
    precondition(MTLAttributeFormatSet.count == 2)

    _ = MTLBindingAccess.readOnly
    precondition(MTLBindingAccess.readOnly.rawValue == 0)
    precondition(MTLBindingAccess(rawValue: 0) == MTLBindingAccess.readOnly)
    precondition(MTLBindingAccess.readWrite.rawValue == 1)
    precondition(MTLBindingAccess(rawValue: 1) == MTLBindingAccess.readWrite)
    precondition(MTLBindingAccess.writeOnly.rawValue == 2)
    precondition(MTLBindingAccess(rawValue: 2) == MTLBindingAccess.writeOnly)
    precondition(MTLBindingAccess.readOnly != MTLBindingAccess.readWrite)
    var MTLBindingAccessSet: Set<MTLBindingAccess> = [.readOnly]
    MTLBindingAccessSet.insert(.readWrite)
    precondition(MTLBindingAccessSet.count == 2)

    _ = MTLBindingType.buffer
    precondition(MTLBindingType.buffer.rawValue == 0)
    precondition(MTLBindingType(rawValue: 0) == MTLBindingType.buffer)
    precondition(MTLBindingType.threadgroupMemory.rawValue == 1)
    precondition(MTLBindingType(rawValue: 1) == MTLBindingType.threadgroupMemory)
    precondition(MTLBindingType.texture.rawValue == 2)
    precondition(MTLBindingType(rawValue: 2) == MTLBindingType.texture)
    precondition(MTLBindingType.sampler.rawValue == 3)
    precondition(MTLBindingType(rawValue: 3) == MTLBindingType.sampler)
    precondition(MTLBindingType.imageblockData.rawValue == 4)
    precondition(MTLBindingType(rawValue: 4) == MTLBindingType.imageblockData)
    precondition(MTLBindingType.imageblock.rawValue == 5)
    precondition(MTLBindingType(rawValue: 5) == MTLBindingType.imageblock)
    precondition(MTLBindingType.visibleFunctionTable.rawValue == 6)
    precondition(MTLBindingType(rawValue: 6) == MTLBindingType.visibleFunctionTable)
    precondition(MTLBindingType.primitiveAccelerationStructure.rawValue == 7)
    precondition(MTLBindingType(rawValue: 7) == MTLBindingType.primitiveAccelerationStructure)
    precondition(MTLBindingType.instanceAccelerationStructure.rawValue == 8)
    precondition(MTLBindingType(rawValue: 8) == MTLBindingType.instanceAccelerationStructure)
    precondition(MTLBindingType.intersectionFunctionTable.rawValue == 9)
    precondition(MTLBindingType(rawValue: 9) == MTLBindingType.intersectionFunctionTable)
    precondition(MTLBindingType.objectPayload.rawValue == 10)
    precondition(MTLBindingType(rawValue: 10) == MTLBindingType.objectPayload)
    precondition(MTLBindingType.tensor.rawValue == 11)
    precondition(MTLBindingType(rawValue: 11) == MTLBindingType.tensor)
    precondition(MTLBindingType.buffer != MTLBindingType.threadgroupMemory)
    var MTLBindingTypeSet: Set<MTLBindingType> = [.buffer]
    MTLBindingTypeSet.insert(.threadgroupMemory)
    precondition(MTLBindingTypeSet.count == 2)

    _ = MTLBlendFactor.zero
    precondition(MTLBlendFactor.zero.rawValue == 0)
    precondition(MTLBlendFactor(rawValue: 0) == MTLBlendFactor.zero)
    precondition(MTLBlendFactor.one.rawValue == 1)
    precondition(MTLBlendFactor(rawValue: 1) == MTLBlendFactor.one)
    precondition(MTLBlendFactor.sourceColor.rawValue == 2)
    precondition(MTLBlendFactor(rawValue: 2) == MTLBlendFactor.sourceColor)
    precondition(MTLBlendFactor.oneMinusSourceColor.rawValue == 3)
    precondition(MTLBlendFactor(rawValue: 3) == MTLBlendFactor.oneMinusSourceColor)
    precondition(MTLBlendFactor.sourceAlpha.rawValue == 4)
    precondition(MTLBlendFactor(rawValue: 4) == MTLBlendFactor.sourceAlpha)
    precondition(MTLBlendFactor.oneMinusSourceAlpha.rawValue == 5)
    precondition(MTLBlendFactor(rawValue: 5) == MTLBlendFactor.oneMinusSourceAlpha)
    precondition(MTLBlendFactor.destinationColor.rawValue == 6)
    precondition(MTLBlendFactor(rawValue: 6) == MTLBlendFactor.destinationColor)
    precondition(MTLBlendFactor.oneMinusDestinationColor.rawValue == 7)
    precondition(MTLBlendFactor(rawValue: 7) == MTLBlendFactor.oneMinusDestinationColor)
    precondition(MTLBlendFactor.destinationAlpha.rawValue == 8)
    precondition(MTLBlendFactor(rawValue: 8) == MTLBlendFactor.destinationAlpha)
    precondition(MTLBlendFactor.oneMinusDestinationAlpha.rawValue == 9)
    precondition(MTLBlendFactor(rawValue: 9) == MTLBlendFactor.oneMinusDestinationAlpha)
    precondition(MTLBlendFactor.sourceAlphaSaturated.rawValue == 10)
    precondition(MTLBlendFactor(rawValue: 10) == MTLBlendFactor.sourceAlphaSaturated)
    precondition(MTLBlendFactor.blendColor.rawValue == 11)
    precondition(MTLBlendFactor(rawValue: 11) == MTLBlendFactor.blendColor)
    precondition(MTLBlendFactor.oneMinusBlendColor.rawValue == 12)
    precondition(MTLBlendFactor(rawValue: 12) == MTLBlendFactor.oneMinusBlendColor)
    precondition(MTLBlendFactor.blendAlpha.rawValue == 13)
    precondition(MTLBlendFactor(rawValue: 13) == MTLBlendFactor.blendAlpha)
    precondition(MTLBlendFactor.oneMinusBlendAlpha.rawValue == 14)
    precondition(MTLBlendFactor(rawValue: 14) == MTLBlendFactor.oneMinusBlendAlpha)
    precondition(MTLBlendFactor.source1Color.rawValue == 15)
    precondition(MTLBlendFactor(rawValue: 15) == MTLBlendFactor.source1Color)
    precondition(MTLBlendFactor.oneMinusSource1Color.rawValue == 16)
    precondition(MTLBlendFactor(rawValue: 16) == MTLBlendFactor.oneMinusSource1Color)
    precondition(MTLBlendFactor.source1Alpha.rawValue == 17)
    precondition(MTLBlendFactor(rawValue: 17) == MTLBlendFactor.source1Alpha)
    precondition(MTLBlendFactor.oneMinusSource1Alpha.rawValue == 18)
    precondition(MTLBlendFactor(rawValue: 18) == MTLBlendFactor.oneMinusSource1Alpha)
    precondition(MTLBlendFactor.zero != MTLBlendFactor.one)
    var MTLBlendFactorSet: Set<MTLBlendFactor> = [.zero]
    MTLBlendFactorSet.insert(.one)
    precondition(MTLBlendFactorSet.count == 2)

    _ = MTLBlendOperation.add
    precondition(MTLBlendOperation.add.rawValue == 0)
    precondition(MTLBlendOperation(rawValue: 0) == MTLBlendOperation.add)
    precondition(MTLBlendOperation.subtract.rawValue == 1)
    precondition(MTLBlendOperation(rawValue: 1) == MTLBlendOperation.subtract)
    precondition(MTLBlendOperation.reverseSubtract.rawValue == 2)
    precondition(MTLBlendOperation(rawValue: 2) == MTLBlendOperation.reverseSubtract)
    precondition(MTLBlendOperation.min.rawValue == 3)
    precondition(MTLBlendOperation(rawValue: 3) == MTLBlendOperation.min)
    precondition(MTLBlendOperation.max.rawValue == 4)
    precondition(MTLBlendOperation(rawValue: 4) == MTLBlendOperation.max)
    precondition(MTLBlendOperation.add != MTLBlendOperation.subtract)
    var MTLBlendOperationSet: Set<MTLBlendOperation> = [.add]
    MTLBlendOperationSet.insert(.subtract)
    precondition(MTLBlendOperationSet.count == 2)

    _ = MTLBufferSparseTier.tierNone
    precondition(MTLBufferSparseTier.tierNone.rawValue == 0)
    precondition(MTLBufferSparseTier(rawValue: 0) == MTLBufferSparseTier.tierNone)
    precondition(MTLBufferSparseTier.tier1.rawValue == 1)
    precondition(MTLBufferSparseTier(rawValue: 1) == MTLBufferSparseTier.tier1)
    precondition(MTLBufferSparseTier.tierNone != MTLBufferSparseTier.tier1)
    var MTLBufferSparseTierSet: Set<MTLBufferSparseTier> = [.tierNone]
    MTLBufferSparseTierSet.insert(.tier1)
    precondition(MTLBufferSparseTierSet.count == 2)

    _ = MTLCPUBuiltinKernel.fillUInt32
    precondition(MTLCPUBuiltinKernel.fillUInt32.rawValue == "openuikit.cpu.fillUInt32")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.fillUInt32") == MTLCPUBuiltinKernel.fillUInt32)
    precondition(MTLCPUBuiltinKernel.addUInt32.rawValue == "openuikit.cpu.addUInt32")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.addUInt32") == MTLCPUBuiltinKernel.addUInt32)
    precondition(MTLCPUBuiltinKernel.copyUInt8.rawValue == "openuikit.cpu.copyUInt8")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.copyUInt8") == MTLCPUBuiltinKernel.copyUInt8)
    precondition(MTLCPUBuiltinKernel.fillUInt32 != MTLCPUBuiltinKernel.addUInt32)
    var MTLCPUBuiltinKernelSet: Set<MTLCPUBuiltinKernel> = [.fillUInt32]
    MTLCPUBuiltinKernelSet.insert(.addUInt32)
    precondition(MTLCPUBuiltinKernelSet.count == 2)

    _ = MTLCPUCacheMode.defaultCache
    precondition(MTLCPUCacheMode.defaultCache.rawValue == 0)
    precondition(MTLCPUCacheMode(rawValue: 0) == MTLCPUCacheMode.defaultCache)
    precondition(MTLCPUCacheMode.writeCombined.rawValue == 1)
    precondition(MTLCPUCacheMode(rawValue: 1) == MTLCPUCacheMode.writeCombined)
    precondition(MTLCPUCacheMode.defaultCache != MTLCPUCacheMode.writeCombined)
    var MTLCPUCacheModeSet: Set<MTLCPUCacheMode> = [.defaultCache]
    MTLCPUCacheModeSet.insert(.writeCombined)
    precondition(MTLCPUCacheModeSet.count == 2)

    _ = MTLCaptureDestination.developerTools
    precondition(MTLCaptureDestination.developerTools.rawValue == 1)
    precondition(MTLCaptureDestination(rawValue: 1) == MTLCaptureDestination.developerTools)
    precondition(MTLCaptureDestination.gpuTraceDocument.rawValue == 2)
    precondition(MTLCaptureDestination(rawValue: 2) == MTLCaptureDestination.gpuTraceDocument)
    precondition(MTLCaptureDestination.developerTools != MTLCaptureDestination.gpuTraceDocument)
    var MTLCaptureDestinationSet: Set<MTLCaptureDestination> = [.developerTools]
    MTLCaptureDestinationSet.insert(.gpuTraceDocument)
    precondition(MTLCaptureDestinationSet.count == 2)

    _ = MTLCaptureError.notSupported
    precondition(MTLCaptureError.notSupported.rawValue == 1)
    precondition(MTLCaptureError(rawValue: 1) == MTLCaptureError.notSupported)
    precondition(MTLCaptureError.alreadyCapturing.rawValue == 2)
    precondition(MTLCaptureError(rawValue: 2) == MTLCaptureError.alreadyCapturing)
    precondition(MTLCaptureError.invalidDescriptor.rawValue == 3)
    precondition(MTLCaptureError(rawValue: 3) == MTLCaptureError.invalidDescriptor)
    precondition(MTLCaptureError.notSupported != MTLCaptureError.alreadyCapturing)
    var MTLCaptureErrorSet: Set<MTLCaptureError> = [.notSupported]
    MTLCaptureErrorSet.insert(.alreadyCapturing)
    precondition(MTLCaptureErrorSet.count == 2)

    _ = MTLCommandBufferError.Code.`none`
    precondition(MTLCommandBufferError.Code.`none`.rawValue == 0)
    precondition(MTLCommandBufferError.Code(rawValue: 0) == MTLCommandBufferError.Code.`none`)
    precondition(MTLCommandBufferError.Code.`internal`.rawValue == 1)
    precondition(MTLCommandBufferError.Code(rawValue: 1) == MTLCommandBufferError.Code.`internal`)
    precondition(MTLCommandBufferError.Code.timeout.rawValue == 2)
    precondition(MTLCommandBufferError.Code(rawValue: 2) == MTLCommandBufferError.Code.timeout)
    precondition(MTLCommandBufferError.Code.pageFault.rawValue == 3)
    precondition(MTLCommandBufferError.Code(rawValue: 3) == MTLCommandBufferError.Code.pageFault)
    precondition(MTLCommandBufferError.Code.blacklisted.rawValue == 4)
    precondition(MTLCommandBufferError.Code(rawValue: 4) == MTLCommandBufferError.Code.blacklisted)
    precondition(MTLCommandBufferError.Code.notPermitted.rawValue == 7)
    precondition(MTLCommandBufferError.Code(rawValue: 7) == MTLCommandBufferError.Code.notPermitted)
    precondition(MTLCommandBufferError.Code.outOfMemory.rawValue == 8)
    precondition(MTLCommandBufferError.Code(rawValue: 8) == MTLCommandBufferError.Code.outOfMemory)
    precondition(MTLCommandBufferError.Code.invalidResource.rawValue == 9)
    precondition(MTLCommandBufferError.Code(rawValue: 9) == MTLCommandBufferError.Code.invalidResource)
    precondition(MTLCommandBufferError.Code.memoryless.rawValue == 10)
    precondition(MTLCommandBufferError.Code(rawValue: 10) == MTLCommandBufferError.Code.memoryless)
    precondition(MTLCommandBufferError.Code.stackOverflow.rawValue == 12)
    precondition(MTLCommandBufferError.Code(rawValue: 12) == MTLCommandBufferError.Code.stackOverflow)
    precondition(MTLCommandBufferError.Code.`none` != MTLCommandBufferError.Code.`internal`)
    var MTLCommandBufferError_CodeSet: Set<MTLCommandBufferError.Code> = [.`none`]
    MTLCommandBufferError_CodeSet.insert(.`internal`)
    precondition(MTLCommandBufferError_CodeSet.count == 2)

    _ = MTLCommandBufferStatus.notEnqueued
    precondition(MTLCommandBufferStatus.notEnqueued.rawValue == 0)
    precondition(MTLCommandBufferStatus(rawValue: 0) == MTLCommandBufferStatus.notEnqueued)
    precondition(MTLCommandBufferStatus.enqueued.rawValue == 1)
    precondition(MTLCommandBufferStatus(rawValue: 1) == MTLCommandBufferStatus.enqueued)
    precondition(MTLCommandBufferStatus.committed.rawValue == 2)
    precondition(MTLCommandBufferStatus(rawValue: 2) == MTLCommandBufferStatus.committed)
    precondition(MTLCommandBufferStatus.scheduled.rawValue == 3)
    precondition(MTLCommandBufferStatus(rawValue: 3) == MTLCommandBufferStatus.scheduled)
    precondition(MTLCommandBufferStatus.completed.rawValue == 4)
    precondition(MTLCommandBufferStatus(rawValue: 4) == MTLCommandBufferStatus.completed)
    precondition(MTLCommandBufferStatus.error.rawValue == 5)
    precondition(MTLCommandBufferStatus(rawValue: 5) == MTLCommandBufferStatus.error)
    precondition(MTLCommandBufferStatus.notEnqueued != MTLCommandBufferStatus.enqueued)
    var MTLCommandBufferStatusSet: Set<MTLCommandBufferStatus> = [.notEnqueued]
    MTLCommandBufferStatusSet.insert(.enqueued)
    precondition(MTLCommandBufferStatusSet.count == 2)

    _ = MTLCompareFunction.never
    precondition(MTLCompareFunction.never.rawValue == 0)
    precondition(MTLCompareFunction(rawValue: 0) == MTLCompareFunction.never)
    precondition(MTLCompareFunction.less.rawValue == 1)
    precondition(MTLCompareFunction(rawValue: 1) == MTLCompareFunction.less)
    precondition(MTLCompareFunction.equal.rawValue == 2)
    precondition(MTLCompareFunction(rawValue: 2) == MTLCompareFunction.equal)
    precondition(MTLCompareFunction.lessEqual.rawValue == 3)
    precondition(MTLCompareFunction(rawValue: 3) == MTLCompareFunction.lessEqual)
    precondition(MTLCompareFunction.greater.rawValue == 4)
    precondition(MTLCompareFunction(rawValue: 4) == MTLCompareFunction.greater)
    precondition(MTLCompareFunction.notEqual.rawValue == 5)
    precondition(MTLCompareFunction(rawValue: 5) == MTLCompareFunction.notEqual)
    precondition(MTLCompareFunction.greaterEqual.rawValue == 6)
    precondition(MTLCompareFunction(rawValue: 6) == MTLCompareFunction.greaterEqual)
    precondition(MTLCompareFunction.always.rawValue == 7)
    precondition(MTLCompareFunction(rawValue: 7) == MTLCompareFunction.always)
    precondition(MTLCompareFunction.never != MTLCompareFunction.less)
    var MTLCompareFunctionSet: Set<MTLCompareFunction> = [.never]
    MTLCompareFunctionSet.insert(.less)
    precondition(MTLCompareFunctionSet.count == 2)

    _ = MTLCompileSymbolVisibility.`default`
    precondition(MTLCompileSymbolVisibility.`default`.rawValue == 0)
    precondition(MTLCompileSymbolVisibility(rawValue: 0) == MTLCompileSymbolVisibility.`default`)
    precondition(MTLCompileSymbolVisibility.hidden.rawValue == 1)
    precondition(MTLCompileSymbolVisibility(rawValue: 1) == MTLCompileSymbolVisibility.hidden)
    precondition(MTLCompileSymbolVisibility.`default` != MTLCompileSymbolVisibility.hidden)
    var MTLCompileSymbolVisibilitySet: Set<MTLCompileSymbolVisibility> = [.`default`]
    MTLCompileSymbolVisibilitySet.insert(.hidden)
    precondition(MTLCompileSymbolVisibilitySet.count == 2)

    _ = MTLCounterSamplingPoint.atStageBoundary
    precondition(MTLCounterSamplingPoint.atStageBoundary.rawValue == 0)
    precondition(MTLCounterSamplingPoint(rawValue: 0) == MTLCounterSamplingPoint.atStageBoundary)
    precondition(MTLCounterSamplingPoint.atDrawBoundary.rawValue == 1)
    precondition(MTLCounterSamplingPoint(rawValue: 1) == MTLCounterSamplingPoint.atDrawBoundary)
    precondition(MTLCounterSamplingPoint.atDispatchBoundary.rawValue == 2)
    precondition(MTLCounterSamplingPoint(rawValue: 2) == MTLCounterSamplingPoint.atDispatchBoundary)
    precondition(MTLCounterSamplingPoint.atTileDispatchBoundary.rawValue == 3)
    precondition(MTLCounterSamplingPoint(rawValue: 3) == MTLCounterSamplingPoint.atTileDispatchBoundary)
    precondition(MTLCounterSamplingPoint.atBlitBoundary.rawValue == 4)
    precondition(MTLCounterSamplingPoint(rawValue: 4) == MTLCounterSamplingPoint.atBlitBoundary)
    precondition(MTLCounterSamplingPoint.atStageBoundary != MTLCounterSamplingPoint.atDrawBoundary)
    var MTLCounterSamplingPointSet: Set<MTLCounterSamplingPoint> = [.atStageBoundary]
    MTLCounterSamplingPointSet.insert(.atDrawBoundary)
    precondition(MTLCounterSamplingPointSet.count == 2)

    _ = MTLCullMode.`none`
    precondition(MTLCullMode.`none`.rawValue == 0)
    precondition(MTLCullMode(rawValue: 0) == MTLCullMode.`none`)
    precondition(MTLCullMode.front.rawValue == 1)
    precondition(MTLCullMode(rawValue: 1) == MTLCullMode.front)
    precondition(MTLCullMode.back.rawValue == 2)
    precondition(MTLCullMode(rawValue: 2) == MTLCullMode.back)
    precondition(MTLCullMode.`none` != MTLCullMode.front)
    var MTLCullModeSet: Set<MTLCullMode> = [.`none`]
    MTLCullModeSet.insert(.front)
    precondition(MTLCullModeSet.count == 2)

    _ = MTLDataType.`none`
    precondition(MTLDataType.`none`.rawValue == 0)
    precondition(MTLDataType(rawValue: 0) == MTLDataType.`none`)
    precondition(MTLDataType.`struct`.rawValue == 1)
    precondition(MTLDataType(rawValue: 1) == MTLDataType.`struct`)
    precondition(MTLDataType.array.rawValue == 2)
    precondition(MTLDataType(rawValue: 2) == MTLDataType.array)
    precondition(MTLDataType.float.rawValue == 3)
    precondition(MTLDataType(rawValue: 3) == MTLDataType.float)
    precondition(MTLDataType.float2.rawValue == 4)
    precondition(MTLDataType(rawValue: 4) == MTLDataType.float2)
    precondition(MTLDataType.float3.rawValue == 5)
    precondition(MTLDataType(rawValue: 5) == MTLDataType.float3)
    precondition(MTLDataType.float4.rawValue == 6)
    precondition(MTLDataType(rawValue: 6) == MTLDataType.float4)
    precondition(MTLDataType.float2x2.rawValue == 7)
    precondition(MTLDataType(rawValue: 7) == MTLDataType.float2x2)
    precondition(MTLDataType.float2x3.rawValue == 8)
    precondition(MTLDataType(rawValue: 8) == MTLDataType.float2x3)
    precondition(MTLDataType.float2x4.rawValue == 9)
    precondition(MTLDataType(rawValue: 9) == MTLDataType.float2x4)
    precondition(MTLDataType.float3x2.rawValue == 10)
    precondition(MTLDataType(rawValue: 10) == MTLDataType.float3x2)
    precondition(MTLDataType.float3x3.rawValue == 11)
    precondition(MTLDataType(rawValue: 11) == MTLDataType.float3x3)
    precondition(MTLDataType.float3x4.rawValue == 12)
    precondition(MTLDataType(rawValue: 12) == MTLDataType.float3x4)
    precondition(MTLDataType.float4x2.rawValue == 13)
    precondition(MTLDataType(rawValue: 13) == MTLDataType.float4x2)
    precondition(MTLDataType.float4x3.rawValue == 14)
    precondition(MTLDataType(rawValue: 14) == MTLDataType.float4x3)
    precondition(MTLDataType.float4x4.rawValue == 15)
    precondition(MTLDataType(rawValue: 15) == MTLDataType.float4x4)
    precondition(MTLDataType.half.rawValue == 16)
    precondition(MTLDataType(rawValue: 16) == MTLDataType.half)
    precondition(MTLDataType.half2.rawValue == 17)
    precondition(MTLDataType(rawValue: 17) == MTLDataType.half2)
    precondition(MTLDataType.half3.rawValue == 18)
    precondition(MTLDataType(rawValue: 18) == MTLDataType.half3)
    precondition(MTLDataType.half4.rawValue == 19)
    precondition(MTLDataType(rawValue: 19) == MTLDataType.half4)
    precondition(MTLDataType.half2x2.rawValue == 20)
    precondition(MTLDataType(rawValue: 20) == MTLDataType.half2x2)
    precondition(MTLDataType.half2x3.rawValue == 21)
    precondition(MTLDataType(rawValue: 21) == MTLDataType.half2x3)
    precondition(MTLDataType.half2x4.rawValue == 22)
    precondition(MTLDataType(rawValue: 22) == MTLDataType.half2x4)
    precondition(MTLDataType.half3x2.rawValue == 23)
    precondition(MTLDataType(rawValue: 23) == MTLDataType.half3x2)
    precondition(MTLDataType.half3x3.rawValue == 24)
    precondition(MTLDataType(rawValue: 24) == MTLDataType.half3x3)
    precondition(MTLDataType.half3x4.rawValue == 25)
    precondition(MTLDataType(rawValue: 25) == MTLDataType.half3x4)
    precondition(MTLDataType.half4x2.rawValue == 26)
    precondition(MTLDataType(rawValue: 26) == MTLDataType.half4x2)
    precondition(MTLDataType.half4x3.rawValue == 27)
    precondition(MTLDataType(rawValue: 27) == MTLDataType.half4x3)
    precondition(MTLDataType.half4x4.rawValue == 28)
    precondition(MTLDataType(rawValue: 28) == MTLDataType.half4x4)
    precondition(MTLDataType.int.rawValue == 29)
    precondition(MTLDataType(rawValue: 29) == MTLDataType.int)
    precondition(MTLDataType.int2.rawValue == 30)
    precondition(MTLDataType(rawValue: 30) == MTLDataType.int2)
    precondition(MTLDataType.int3.rawValue == 31)
    precondition(MTLDataType(rawValue: 31) == MTLDataType.int3)
    precondition(MTLDataType.int4.rawValue == 32)
    precondition(MTLDataType(rawValue: 32) == MTLDataType.int4)
    precondition(MTLDataType.uint.rawValue == 33)
    precondition(MTLDataType(rawValue: 33) == MTLDataType.uint)
    precondition(MTLDataType.uint2.rawValue == 34)
    precondition(MTLDataType(rawValue: 34) == MTLDataType.uint2)
    precondition(MTLDataType.uint3.rawValue == 35)
    precondition(MTLDataType(rawValue: 35) == MTLDataType.uint3)
    precondition(MTLDataType.uint4.rawValue == 36)
    precondition(MTLDataType(rawValue: 36) == MTLDataType.uint4)
    precondition(MTLDataType.short.rawValue == 37)
    precondition(MTLDataType(rawValue: 37) == MTLDataType.short)
    precondition(MTLDataType.short2.rawValue == 38)
    precondition(MTLDataType(rawValue: 38) == MTLDataType.short2)
    precondition(MTLDataType.short3.rawValue == 39)
    precondition(MTLDataType(rawValue: 39) == MTLDataType.short3)
    precondition(MTLDataType.short4.rawValue == 40)
    precondition(MTLDataType(rawValue: 40) == MTLDataType.short4)
    precondition(MTLDataType.ushort.rawValue == 41)
    precondition(MTLDataType(rawValue: 41) == MTLDataType.ushort)
    precondition(MTLDataType.ushort2.rawValue == 42)
    precondition(MTLDataType(rawValue: 42) == MTLDataType.ushort2)
    precondition(MTLDataType.ushort3.rawValue == 43)
    precondition(MTLDataType(rawValue: 43) == MTLDataType.ushort3)
    precondition(MTLDataType.ushort4.rawValue == 44)
    precondition(MTLDataType(rawValue: 44) == MTLDataType.ushort4)
    precondition(MTLDataType.char.rawValue == 45)
    precondition(MTLDataType(rawValue: 45) == MTLDataType.char)
    precondition(MTLDataType.char2.rawValue == 46)
    precondition(MTLDataType(rawValue: 46) == MTLDataType.char2)
    precondition(MTLDataType.char3.rawValue == 47)
    precondition(MTLDataType(rawValue: 47) == MTLDataType.char3)
    precondition(MTLDataType.char4.rawValue == 48)
    precondition(MTLDataType(rawValue: 48) == MTLDataType.char4)
    precondition(MTLDataType.uchar.rawValue == 49)
    precondition(MTLDataType(rawValue: 49) == MTLDataType.uchar)
    precondition(MTLDataType.uchar2.rawValue == 50)
    precondition(MTLDataType(rawValue: 50) == MTLDataType.uchar2)
    precondition(MTLDataType.uchar3.rawValue == 51)
    precondition(MTLDataType(rawValue: 51) == MTLDataType.uchar3)
    precondition(MTLDataType.uchar4.rawValue == 52)
    precondition(MTLDataType(rawValue: 52) == MTLDataType.uchar4)
    precondition(MTLDataType.bool.rawValue == 53)
    precondition(MTLDataType(rawValue: 53) == MTLDataType.bool)
    precondition(MTLDataType.bool2.rawValue == 54)
    precondition(MTLDataType(rawValue: 54) == MTLDataType.bool2)
    precondition(MTLDataType.bool3.rawValue == 55)
    precondition(MTLDataType(rawValue: 55) == MTLDataType.bool3)
    precondition(MTLDataType.bool4.rawValue == 56)
    precondition(MTLDataType(rawValue: 56) == MTLDataType.bool4)
    precondition(MTLDataType.texture.rawValue == 58)
    precondition(MTLDataType(rawValue: 58) == MTLDataType.texture)
    precondition(MTLDataType.sampler.rawValue == 59)
    precondition(MTLDataType(rawValue: 59) == MTLDataType.sampler)
    precondition(MTLDataType.pointer.rawValue == 60)
    precondition(MTLDataType(rawValue: 60) == MTLDataType.pointer)
    precondition(MTLDataType.r8Unorm.rawValue == 62)
    precondition(MTLDataType(rawValue: 62) == MTLDataType.r8Unorm)
    precondition(MTLDataType.r8Snorm.rawValue == 63)
    precondition(MTLDataType(rawValue: 63) == MTLDataType.r8Snorm)
    precondition(MTLDataType.r16Unorm.rawValue == 64)
    precondition(MTLDataType(rawValue: 64) == MTLDataType.r16Unorm)
    precondition(MTLDataType.r16Snorm.rawValue == 65)
    precondition(MTLDataType(rawValue: 65) == MTLDataType.r16Snorm)
    precondition(MTLDataType.rg8Unorm.rawValue == 66)
    precondition(MTLDataType(rawValue: 66) == MTLDataType.rg8Unorm)
    precondition(MTLDataType.rg8Snorm.rawValue == 67)
    precondition(MTLDataType(rawValue: 67) == MTLDataType.rg8Snorm)
    precondition(MTLDataType.rg16Unorm.rawValue == 68)
    precondition(MTLDataType(rawValue: 68) == MTLDataType.rg16Unorm)
    precondition(MTLDataType.rg16Snorm.rawValue == 69)
    precondition(MTLDataType(rawValue: 69) == MTLDataType.rg16Snorm)
    precondition(MTLDataType.rgba8Unorm.rawValue == 70)
    precondition(MTLDataType(rawValue: 70) == MTLDataType.rgba8Unorm)
    precondition(MTLDataType.rgba8Unorm_srgb.rawValue == 71)
    precondition(MTLDataType(rawValue: 71) == MTLDataType.rgba8Unorm_srgb)
    precondition(MTLDataType.rgba8Snorm.rawValue == 72)
    precondition(MTLDataType(rawValue: 72) == MTLDataType.rgba8Snorm)
    precondition(MTLDataType.rgba16Unorm.rawValue == 73)
    precondition(MTLDataType(rawValue: 73) == MTLDataType.rgba16Unorm)
    precondition(MTLDataType.rgba16Snorm.rawValue == 74)
    precondition(MTLDataType(rawValue: 74) == MTLDataType.rgba16Snorm)
    precondition(MTLDataType.rgb10a2Unorm.rawValue == 75)
    precondition(MTLDataType(rawValue: 75) == MTLDataType.rgb10a2Unorm)
    precondition(MTLDataType.rg11b10Float.rawValue == 76)
    precondition(MTLDataType(rawValue: 76) == MTLDataType.rg11b10Float)
    precondition(MTLDataType.rgb9e5Float.rawValue == 77)
    precondition(MTLDataType(rawValue: 77) == MTLDataType.rgb9e5Float)
    precondition(MTLDataType.renderPipeline.rawValue == 78)
    precondition(MTLDataType(rawValue: 78) == MTLDataType.renderPipeline)
    precondition(MTLDataType.computePipeline.rawValue == 79)
    precondition(MTLDataType(rawValue: 79) == MTLDataType.computePipeline)
    precondition(MTLDataType.indirectCommandBuffer.rawValue == 80)
    precondition(MTLDataType(rawValue: 80) == MTLDataType.indirectCommandBuffer)
    precondition(MTLDataType.long.rawValue == 81)
    precondition(MTLDataType(rawValue: 81) == MTLDataType.long)
    precondition(MTLDataType.long2.rawValue == 82)
    precondition(MTLDataType(rawValue: 82) == MTLDataType.long2)
    precondition(MTLDataType.long3.rawValue == 83)
    precondition(MTLDataType(rawValue: 83) == MTLDataType.long3)
    precondition(MTLDataType.long4.rawValue == 84)
    precondition(MTLDataType(rawValue: 84) == MTLDataType.long4)
    precondition(MTLDataType.ulong.rawValue == 85)
    precondition(MTLDataType(rawValue: 85) == MTLDataType.ulong)
    precondition(MTLDataType.ulong2.rawValue == 86)
    precondition(MTLDataType(rawValue: 86) == MTLDataType.ulong2)
    precondition(MTLDataType.ulong3.rawValue == 87)
    precondition(MTLDataType(rawValue: 87) == MTLDataType.ulong3)
    precondition(MTLDataType.ulong4.rawValue == 88)
    precondition(MTLDataType(rawValue: 88) == MTLDataType.ulong4)
    precondition(MTLDataType.visibleFunctionTable.rawValue == 115)
    precondition(MTLDataType(rawValue: 115) == MTLDataType.visibleFunctionTable)
    precondition(MTLDataType.intersectionFunctionTable.rawValue == 116)
    precondition(MTLDataType(rawValue: 116) == MTLDataType.intersectionFunctionTable)
    precondition(MTLDataType.primitiveAccelerationStructure.rawValue == 117)
    precondition(MTLDataType(rawValue: 117) == MTLDataType.primitiveAccelerationStructure)
    precondition(MTLDataType.instanceAccelerationStructure.rawValue == 118)
    precondition(MTLDataType(rawValue: 118) == MTLDataType.instanceAccelerationStructure)
    precondition(MTLDataType.depthStencilState.rawValue == 119)
    precondition(MTLDataType(rawValue: 119) == MTLDataType.depthStencilState)
    precondition(MTLDataType.bfloat.rawValue == 121)
    precondition(MTLDataType(rawValue: 121) == MTLDataType.bfloat)
    precondition(MTLDataType.bfloat2.rawValue == 122)
    precondition(MTLDataType(rawValue: 122) == MTLDataType.bfloat2)
    precondition(MTLDataType.bfloat3.rawValue == 123)
    precondition(MTLDataType(rawValue: 123) == MTLDataType.bfloat3)
    precondition(MTLDataType.bfloat4.rawValue == 124)
    precondition(MTLDataType(rawValue: 124) == MTLDataType.bfloat4)
    precondition(MTLDataType.tensor.rawValue == 125)
    precondition(MTLDataType(rawValue: 125) == MTLDataType.tensor)
    precondition(MTLDataType.`none` != MTLDataType.`struct`)
    var MTLDataTypeSet: Set<MTLDataType> = [.`none`]
    MTLDataTypeSet.insert(.`struct`)
    precondition(MTLDataTypeSet.count == 2)

    _ = MTLDepthClipMode.clip
    precondition(MTLDepthClipMode.clip.rawValue == 0)
    precondition(MTLDepthClipMode(rawValue: 0) == MTLDepthClipMode.clip)
    precondition(MTLDepthClipMode.clamp.rawValue == 1)
    precondition(MTLDepthClipMode(rawValue: 1) == MTLDepthClipMode.clamp)
    precondition(MTLDepthClipMode.clip != MTLDepthClipMode.clamp)
    var MTLDepthClipModeSet: Set<MTLDepthClipMode> = [.clip]
    MTLDepthClipModeSet.insert(.clamp)
    precondition(MTLDepthClipModeSet.count == 2)

    _ = MTLDispatchType.serial
    precondition(MTLDispatchType.serial.rawValue == 0)
    precondition(MTLDispatchType(rawValue: 0) == MTLDispatchType.serial)
    precondition(MTLDispatchType.concurrent.rawValue == 1)
    precondition(MTLDispatchType(rawValue: 1) == MTLDispatchType.concurrent)
    precondition(MTLDispatchType.serial != MTLDispatchType.concurrent)
    var MTLDispatchTypeSet: Set<MTLDispatchType> = [.serial]
    MTLDispatchTypeSet.insert(.concurrent)
    precondition(MTLDispatchTypeSet.count == 2)

    _ = MTLFeatureSet.iOS_GPUFamily1_v1
    precondition(MTLFeatureSet.iOS_GPUFamily1_v1.rawValue == 0)
    precondition(MTLFeatureSet(rawValue: 0) == MTLFeatureSet.iOS_GPUFamily1_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v1.rawValue == 1)
    precondition(MTLFeatureSet(rawValue: 1) == MTLFeatureSet.iOS_GPUFamily2_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v2.rawValue == 2)
    precondition(MTLFeatureSet(rawValue: 2) == MTLFeatureSet.iOS_GPUFamily1_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v2.rawValue == 3)
    precondition(MTLFeatureSet(rawValue: 3) == MTLFeatureSet.iOS_GPUFamily2_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v1.rawValue == 4)
    precondition(MTLFeatureSet(rawValue: 4) == MTLFeatureSet.iOS_GPUFamily3_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v3.rawValue == 5)
    precondition(MTLFeatureSet(rawValue: 5) == MTLFeatureSet.iOS_GPUFamily1_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v3.rawValue == 6)
    precondition(MTLFeatureSet(rawValue: 6) == MTLFeatureSet.iOS_GPUFamily2_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v2.rawValue == 7)
    precondition(MTLFeatureSet(rawValue: 7) == MTLFeatureSet.iOS_GPUFamily3_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v4.rawValue == 8)
    precondition(MTLFeatureSet(rawValue: 8) == MTLFeatureSet.iOS_GPUFamily1_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v4.rawValue == 9)
    precondition(MTLFeatureSet(rawValue: 9) == MTLFeatureSet.iOS_GPUFamily2_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v3.rawValue == 10)
    precondition(MTLFeatureSet(rawValue: 10) == MTLFeatureSet.iOS_GPUFamily3_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily4_v1.rawValue == 11)
    precondition(MTLFeatureSet(rawValue: 11) == MTLFeatureSet.iOS_GPUFamily4_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v5.rawValue == 12)
    precondition(MTLFeatureSet(rawValue: 12) == MTLFeatureSet.iOS_GPUFamily1_v5)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v5.rawValue == 13)
    precondition(MTLFeatureSet(rawValue: 13) == MTLFeatureSet.iOS_GPUFamily2_v5)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v4.rawValue == 14)
    precondition(MTLFeatureSet(rawValue: 14) == MTLFeatureSet.iOS_GPUFamily3_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily4_v2.rawValue == 15)
    precondition(MTLFeatureSet(rawValue: 15) == MTLFeatureSet.iOS_GPUFamily4_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily5_v1.rawValue == 16)
    precondition(MTLFeatureSet(rawValue: 16) == MTLFeatureSet.iOS_GPUFamily5_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v1 != MTLFeatureSet.iOS_GPUFamily2_v1)
    var MTLFeatureSetSet: Set<MTLFeatureSet> = [.iOS_GPUFamily1_v1]
    MTLFeatureSetSet.insert(.iOS_GPUFamily2_v1)
    precondition(MTLFeatureSetSet.count == 2)

    _ = MTLFunctionType.vertex
    precondition(MTLFunctionType.vertex.rawValue == 1)
    precondition(MTLFunctionType(rawValue: 1) == MTLFunctionType.vertex)
    precondition(MTLFunctionType.fragment.rawValue == 2)
    precondition(MTLFunctionType(rawValue: 2) == MTLFunctionType.fragment)
    precondition(MTLFunctionType.kernel.rawValue == 3)
    precondition(MTLFunctionType(rawValue: 3) == MTLFunctionType.kernel)
    precondition(MTLFunctionType.visible.rawValue == 5)
    precondition(MTLFunctionType(rawValue: 5) == MTLFunctionType.visible)
    precondition(MTLFunctionType.intersection.rawValue == 6)
    precondition(MTLFunctionType(rawValue: 6) == MTLFunctionType.intersection)
    precondition(MTLFunctionType.mesh.rawValue == 7)
    precondition(MTLFunctionType(rawValue: 7) == MTLFunctionType.mesh)
    precondition(MTLFunctionType.object.rawValue == 8)
    precondition(MTLFunctionType(rawValue: 8) == MTLFunctionType.object)
    precondition(MTLFunctionType.vertex != MTLFunctionType.fragment)
    var MTLFunctionTypeSet: Set<MTLFunctionType> = [.vertex]
    MTLFunctionTypeSet.insert(.fragment)
    precondition(MTLFunctionTypeSet.count == 2)

    _ = MTLGPUFamily.apple1
    precondition(MTLGPUFamily.apple1.rawValue == 1001)
    precondition(MTLGPUFamily(rawValue: 1001) == MTLGPUFamily.apple1)
    precondition(MTLGPUFamily.apple2.rawValue == 1002)
    precondition(MTLGPUFamily(rawValue: 1002) == MTLGPUFamily.apple2)
    precondition(MTLGPUFamily.apple3.rawValue == 1003)
    precondition(MTLGPUFamily(rawValue: 1003) == MTLGPUFamily.apple3)
    precondition(MTLGPUFamily.apple4.rawValue == 1004)
    precondition(MTLGPUFamily(rawValue: 1004) == MTLGPUFamily.apple4)
    precondition(MTLGPUFamily.apple5.rawValue == 1005)
    precondition(MTLGPUFamily(rawValue: 1005) == MTLGPUFamily.apple5)
    precondition(MTLGPUFamily.apple6.rawValue == 1006)
    precondition(MTLGPUFamily(rawValue: 1006) == MTLGPUFamily.apple6)
    precondition(MTLGPUFamily.apple7.rawValue == 1007)
    precondition(MTLGPUFamily(rawValue: 1007) == MTLGPUFamily.apple7)
    precondition(MTLGPUFamily.apple8.rawValue == 1008)
    precondition(MTLGPUFamily(rawValue: 1008) == MTLGPUFamily.apple8)
    precondition(MTLGPUFamily.apple9.rawValue == 1009)
    precondition(MTLGPUFamily(rawValue: 1009) == MTLGPUFamily.apple9)
    precondition(MTLGPUFamily.apple10.rawValue == 1010)
    precondition(MTLGPUFamily(rawValue: 1010) == MTLGPUFamily.apple10)
    precondition(MTLGPUFamily.mac1.rawValue == 2001)
    precondition(MTLGPUFamily(rawValue: 2001) == MTLGPUFamily.mac1)
    precondition(MTLGPUFamily.mac2.rawValue == 2002)
    precondition(MTLGPUFamily(rawValue: 2002) == MTLGPUFamily.mac2)
    precondition(MTLGPUFamily.common1.rawValue == 3001)
    precondition(MTLGPUFamily(rawValue: 3001) == MTLGPUFamily.common1)
    precondition(MTLGPUFamily.common2.rawValue == 3002)
    precondition(MTLGPUFamily(rawValue: 3002) == MTLGPUFamily.common2)
    precondition(MTLGPUFamily.common3.rawValue == 3003)
    precondition(MTLGPUFamily(rawValue: 3003) == MTLGPUFamily.common3)
    precondition(MTLGPUFamily.macCatalyst1.rawValue == 4001)
    precondition(MTLGPUFamily(rawValue: 4001) == MTLGPUFamily.macCatalyst1)
    precondition(MTLGPUFamily.macCatalyst2.rawValue == 4002)
    precondition(MTLGPUFamily(rawValue: 4002) == MTLGPUFamily.macCatalyst2)
    precondition(MTLGPUFamily.metal3.rawValue == 5001)
    precondition(MTLGPUFamily(rawValue: 5001) == MTLGPUFamily.metal3)
    precondition(MTLGPUFamily.metal4.rawValue == 5002)
    precondition(MTLGPUFamily(rawValue: 5002) == MTLGPUFamily.metal4)
    precondition(MTLGPUFamily.apple1 != MTLGPUFamily.apple2)
    var MTLGPUFamilySet: Set<MTLGPUFamily> = [.apple1]
    MTLGPUFamilySet.insert(.apple2)
    precondition(MTLGPUFamilySet.count == 2)

    _ = MTLHazardTrackingMode.`default`
    precondition(MTLHazardTrackingMode.`default`.rawValue == 0)
    precondition(MTLHazardTrackingMode(rawValue: 0) == MTLHazardTrackingMode.`default`)
    precondition(MTLHazardTrackingMode.untracked.rawValue == 1)
    precondition(MTLHazardTrackingMode(rawValue: 1) == MTLHazardTrackingMode.untracked)
    precondition(MTLHazardTrackingMode.tracked.rawValue == 2)
    precondition(MTLHazardTrackingMode(rawValue: 2) == MTLHazardTrackingMode.tracked)
    precondition(MTLHazardTrackingMode.`default` != MTLHazardTrackingMode.untracked)
    var MTLHazardTrackingModeSet: Set<MTLHazardTrackingMode> = [.`default`]
    MTLHazardTrackingModeSet.insert(.untracked)
    precondition(MTLHazardTrackingModeSet.count == 2)

    _ = MTLHeapType.automatic
    precondition(MTLHeapType.automatic.rawValue == 0)
    precondition(MTLHeapType(rawValue: 0) == MTLHeapType.automatic)
    precondition(MTLHeapType.placement.rawValue == 1)
    precondition(MTLHeapType(rawValue: 1) == MTLHeapType.placement)
    precondition(MTLHeapType.sparse.rawValue == 2)
    precondition(MTLHeapType(rawValue: 2) == MTLHeapType.sparse)
    precondition(MTLHeapType.automatic != MTLHeapType.placement)
    var MTLHeapTypeSet: Set<MTLHeapType> = [.automatic]
    MTLHeapTypeSet.insert(.placement)
    precondition(MTLHeapTypeSet.count == 2)

    _ = MTLIOError.Code.urlInvalid
    precondition(MTLIOError.Code.urlInvalid.rawValue == 1)
    precondition(MTLIOError.Code(rawValue: 1) == MTLIOError.Code.urlInvalid)
    precondition(MTLIOError.Code.`internal`.rawValue == 2)
    precondition(MTLIOError.Code(rawValue: 2) == MTLIOError.Code.`internal`)
    precondition(MTLIOError.Code.urlInvalid != MTLIOError.Code.`internal`)
    var MTLIOError_CodeSet: Set<MTLIOError.Code> = [.urlInvalid]
    MTLIOError_CodeSet.insert(.`internal`)
    precondition(MTLIOError_CodeSet.count == 2)

    _ = MTLIndexType.uint16
    precondition(MTLIndexType.uint16.rawValue == 0)
    precondition(MTLIndexType(rawValue: 0) == MTLIndexType.uint16)
    precondition(MTLIndexType.uint32.rawValue == 1)
    precondition(MTLIndexType(rawValue: 1) == MTLIndexType.uint32)
    precondition(MTLIndexType.uint16 != MTLIndexType.uint32)
    var MTLIndexTypeSet: Set<MTLIndexType> = [.uint16]
    MTLIndexTypeSet.insert(.uint32)
    precondition(MTLIndexTypeSet.count == 2)

    _ = MTLLanguageVersion.version1_0
    precondition(MTLLanguageVersion.version1_0.rawValue == 0x10000)
    precondition(MTLLanguageVersion(rawValue: 0x10000) == MTLLanguageVersion.version1_0)
    precondition(MTLLanguageVersion.version1_1.rawValue == 0x10001)
    precondition(MTLLanguageVersion(rawValue: 0x10001) == MTLLanguageVersion.version1_1)
    precondition(MTLLanguageVersion.version1_2.rawValue == 0x10002)
    precondition(MTLLanguageVersion(rawValue: 0x10002) == MTLLanguageVersion.version1_2)
    precondition(MTLLanguageVersion.version2_0.rawValue == 0x20000)
    precondition(MTLLanguageVersion(rawValue: 0x20000) == MTLLanguageVersion.version2_0)
    precondition(MTLLanguageVersion.version2_1.rawValue == 0x20001)
    precondition(MTLLanguageVersion(rawValue: 0x20001) == MTLLanguageVersion.version2_1)
    precondition(MTLLanguageVersion.version2_2.rawValue == 0x20002)
    precondition(MTLLanguageVersion(rawValue: 0x20002) == MTLLanguageVersion.version2_2)
    precondition(MTLLanguageVersion.version2_3.rawValue == 0x20003)
    precondition(MTLLanguageVersion(rawValue: 0x20003) == MTLLanguageVersion.version2_3)
    precondition(MTLLanguageVersion.version2_4.rawValue == 0x20004)
    precondition(MTLLanguageVersion(rawValue: 0x20004) == MTLLanguageVersion.version2_4)
    precondition(MTLLanguageVersion.version3_0.rawValue == 0x30000)
    precondition(MTLLanguageVersion(rawValue: 0x30000) == MTLLanguageVersion.version3_0)
    precondition(MTLLanguageVersion.version3_1.rawValue == 0x30001)
    precondition(MTLLanguageVersion(rawValue: 0x30001) == MTLLanguageVersion.version3_1)
    precondition(MTLLanguageVersion.version3_2.rawValue == 0x30002)
    precondition(MTLLanguageVersion(rawValue: 0x30002) == MTLLanguageVersion.version3_2)
    precondition(MTLLanguageVersion.version4_0.rawValue == 0x40000)
    precondition(MTLLanguageVersion(rawValue: 0x40000) == MTLLanguageVersion.version4_0)
    precondition(MTLLanguageVersion.version1_0 != MTLLanguageVersion.version1_1)
    var MTLLanguageVersionSet: Set<MTLLanguageVersion> = [.version1_0]
    MTLLanguageVersionSet.insert(.version1_1)
    precondition(MTLLanguageVersionSet.count == 2)

    _ = MTLLibraryError.Code.unsupported
    precondition(MTLLibraryError.Code.unsupported.rawValue == 1)
    precondition(MTLLibraryError.Code(rawValue: 1) == MTLLibraryError.Code.unsupported)
    precondition(MTLLibraryError.Code.`internal`.rawValue == 2)
    precondition(MTLLibraryError.Code(rawValue: 2) == MTLLibraryError.Code.`internal`)
    precondition(MTLLibraryError.Code.compileFailure.rawValue == 3)
    precondition(MTLLibraryError.Code(rawValue: 3) == MTLLibraryError.Code.compileFailure)
    precondition(MTLLibraryError.Code.compileWarning.rawValue == 4)
    precondition(MTLLibraryError.Code(rawValue: 4) == MTLLibraryError.Code.compileWarning)
    precondition(MTLLibraryError.Code.functionNotFound.rawValue == 5)
    precondition(MTLLibraryError.Code(rawValue: 5) == MTLLibraryError.Code.functionNotFound)
    precondition(MTLLibraryError.Code.fileNotFound.rawValue == 6)
    precondition(MTLLibraryError.Code(rawValue: 6) == MTLLibraryError.Code.fileNotFound)
    precondition(MTLLibraryError.Code.unsupported != MTLLibraryError.Code.`internal`)
    var MTLLibraryError_CodeSet: Set<MTLLibraryError.Code> = [.unsupported]
    MTLLibraryError_CodeSet.insert(.`internal`)
    precondition(MTLLibraryError_CodeSet.count == 2)

    _ = MTLLibraryOptimizationLevel.`default`
    precondition(MTLLibraryOptimizationLevel.`default`.rawValue == 0)
    precondition(MTLLibraryOptimizationLevel(rawValue: 0) == MTLLibraryOptimizationLevel.`default`)
    precondition(MTLLibraryOptimizationLevel.size.rawValue == 1)
    precondition(MTLLibraryOptimizationLevel(rawValue: 1) == MTLLibraryOptimizationLevel.size)
    precondition(MTLLibraryOptimizationLevel.`default` != MTLLibraryOptimizationLevel.size)
    var MTLLibraryOptimizationLevelSet: Set<MTLLibraryOptimizationLevel> = [.`default`]
    MTLLibraryOptimizationLevelSet.insert(.size)
    precondition(MTLLibraryOptimizationLevelSet.count == 2)

    _ = MTLLibraryType.executable
    precondition(MTLLibraryType.executable.rawValue == 0)
    precondition(MTLLibraryType(rawValue: 0) == MTLLibraryType.executable)
    precondition(MTLLibraryType.dynamic.rawValue == 1)
    precondition(MTLLibraryType(rawValue: 1) == MTLLibraryType.dynamic)
    precondition(MTLLibraryType.executable != MTLLibraryType.dynamic)
    var MTLLibraryTypeSet: Set<MTLLibraryType> = [.executable]
    MTLLibraryTypeSet.insert(.dynamic)
    precondition(MTLLibraryTypeSet.count == 2)

    _ = MTLLoadAction.dontCare
    precondition(MTLLoadAction.dontCare.rawValue == 0)
    precondition(MTLLoadAction(rawValue: 0) == MTLLoadAction.dontCare)
    precondition(MTLLoadAction.load.rawValue == 1)
    precondition(MTLLoadAction(rawValue: 1) == MTLLoadAction.load)
    precondition(MTLLoadAction.clear.rawValue == 2)
    precondition(MTLLoadAction(rawValue: 2) == MTLLoadAction.clear)
    precondition(MTLLoadAction.dontCare != MTLLoadAction.load)
    var MTLLoadActionSet: Set<MTLLoadAction> = [.dontCare]
    MTLLoadActionSet.insert(.load)
    precondition(MTLLoadActionSet.count == 2)

    _ = MTLMathFloatingPointFunctions.fast
    precondition(MTLMathFloatingPointFunctions.fast.rawValue == 0)
    precondition(MTLMathFloatingPointFunctions(rawValue: 0) == MTLMathFloatingPointFunctions.fast)
    precondition(MTLMathFloatingPointFunctions.precise.rawValue == 1)
    precondition(MTLMathFloatingPointFunctions(rawValue: 1) == MTLMathFloatingPointFunctions.precise)
    precondition(MTLMathFloatingPointFunctions.fast != MTLMathFloatingPointFunctions.precise)
    var MTLMathFloatingPointFunctionsSet: Set<MTLMathFloatingPointFunctions> = [.fast]
    MTLMathFloatingPointFunctionsSet.insert(.precise)
    precondition(MTLMathFloatingPointFunctionsSet.count == 2)

    _ = MTLMathMode.safe
    precondition(MTLMathMode.safe.rawValue == 0)
    precondition(MTLMathMode(rawValue: 0) == MTLMathMode.safe)
    precondition(MTLMathMode.relaxed.rawValue == 1)
    precondition(MTLMathMode(rawValue: 1) == MTLMathMode.relaxed)
    precondition(MTLMathMode.fast.rawValue == 2)
    precondition(MTLMathMode(rawValue: 2) == MTLMathMode.fast)
    precondition(MTLMathMode.safe != MTLMathMode.relaxed)
    var MTLMathModeSet: Set<MTLMathMode> = [.safe]
    MTLMathModeSet.insert(.relaxed)
    precondition(MTLMathModeSet.count == 2)

    _ = MTLMultisampleDepthResolveFilter.sample0
    precondition(MTLMultisampleDepthResolveFilter.sample0.rawValue == 0)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 0) == MTLMultisampleDepthResolveFilter.sample0)
    precondition(MTLMultisampleDepthResolveFilter.min.rawValue == 1)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 1) == MTLMultisampleDepthResolveFilter.min)
    precondition(MTLMultisampleDepthResolveFilter.max.rawValue == 2)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 2) == MTLMultisampleDepthResolveFilter.max)
    precondition(MTLMultisampleDepthResolveFilter.sample0 != MTLMultisampleDepthResolveFilter.min)
    var MTLMultisampleDepthResolveFilterSet: Set<MTLMultisampleDepthResolveFilter> = [.sample0]
    MTLMultisampleDepthResolveFilterSet.insert(.min)
    precondition(MTLMultisampleDepthResolveFilterSet.count == 2)

    _ = MTLMultisampleStencilResolveFilter.sample0
    precondition(MTLMultisampleStencilResolveFilter.sample0.rawValue == 0)
    precondition(MTLMultisampleStencilResolveFilter(rawValue: 0) == MTLMultisampleStencilResolveFilter.sample0)
    precondition(MTLMultisampleStencilResolveFilter.depthResolvedSample.rawValue == 1)
    precondition(MTLMultisampleStencilResolveFilter(rawValue: 1) == MTLMultisampleStencilResolveFilter.depthResolvedSample)
    precondition(MTLMultisampleStencilResolveFilter.sample0 != MTLMultisampleStencilResolveFilter.depthResolvedSample)
    var MTLMultisampleStencilResolveFilterSet: Set<MTLMultisampleStencilResolveFilter> = [.sample0]
    MTLMultisampleStencilResolveFilterSet.insert(.depthResolvedSample)
    precondition(MTLMultisampleStencilResolveFilterSet.count == 2)

    _ = MTLPatchType.`none`
    precondition(MTLPatchType.`none`.rawValue == 0)
    precondition(MTLPatchType(rawValue: 0) == MTLPatchType.`none`)
    precondition(MTLPatchType.triangle.rawValue == 1)
    precondition(MTLPatchType(rawValue: 1) == MTLPatchType.triangle)
    precondition(MTLPatchType.quad.rawValue == 2)
    precondition(MTLPatchType(rawValue: 2) == MTLPatchType.quad)
    precondition(MTLPatchType.`none` != MTLPatchType.triangle)
    var MTLPatchTypeSet: Set<MTLPatchType> = [.`none`]
    MTLPatchTypeSet.insert(.triangle)
    precondition(MTLPatchTypeSet.count == 2)

    _ = MTLPixelFormat.invalid
    precondition(MTLPixelFormat.invalid.rawValue == 0)
    precondition(MTLPixelFormat(rawValue: 0) == MTLPixelFormat.invalid)
    precondition(MTLPixelFormat.a8Unorm.rawValue == 1)
    precondition(MTLPixelFormat(rawValue: 1) == MTLPixelFormat.a8Unorm)
    precondition(MTLPixelFormat.r8Unorm.rawValue == 10)
    precondition(MTLPixelFormat(rawValue: 10) == MTLPixelFormat.r8Unorm)
    precondition(MTLPixelFormat.r8Unorm_srgb.rawValue == 11)
    precondition(MTLPixelFormat(rawValue: 11) == MTLPixelFormat.r8Unorm_srgb)
    precondition(MTLPixelFormat.r8Snorm.rawValue == 12)
    precondition(MTLPixelFormat(rawValue: 12) == MTLPixelFormat.r8Snorm)
    precondition(MTLPixelFormat.r8Uint.rawValue == 13)
    precondition(MTLPixelFormat(rawValue: 13) == MTLPixelFormat.r8Uint)
    precondition(MTLPixelFormat.r8Sint.rawValue == 14)
    precondition(MTLPixelFormat(rawValue: 14) == MTLPixelFormat.r8Sint)
    precondition(MTLPixelFormat.r16Unorm.rawValue == 20)
    precondition(MTLPixelFormat(rawValue: 20) == MTLPixelFormat.r16Unorm)
    precondition(MTLPixelFormat.r16Snorm.rawValue == 22)
    precondition(MTLPixelFormat(rawValue: 22) == MTLPixelFormat.r16Snorm)
    precondition(MTLPixelFormat.r16Uint.rawValue == 23)
    precondition(MTLPixelFormat(rawValue: 23) == MTLPixelFormat.r16Uint)
    precondition(MTLPixelFormat.r16Sint.rawValue == 24)
    precondition(MTLPixelFormat(rawValue: 24) == MTLPixelFormat.r16Sint)
    precondition(MTLPixelFormat.r16Float.rawValue == 25)
    precondition(MTLPixelFormat(rawValue: 25) == MTLPixelFormat.r16Float)
    precondition(MTLPixelFormat.rg8Unorm.rawValue == 30)
    precondition(MTLPixelFormat(rawValue: 30) == MTLPixelFormat.rg8Unorm)
    precondition(MTLPixelFormat.rg8Unorm_srgb.rawValue == 31)
    precondition(MTLPixelFormat(rawValue: 31) == MTLPixelFormat.rg8Unorm_srgb)
    precondition(MTLPixelFormat.rg8Snorm.rawValue == 32)
    precondition(MTLPixelFormat(rawValue: 32) == MTLPixelFormat.rg8Snorm)
    precondition(MTLPixelFormat.rg8Uint.rawValue == 33)
    precondition(MTLPixelFormat(rawValue: 33) == MTLPixelFormat.rg8Uint)
    precondition(MTLPixelFormat.rg8Sint.rawValue == 34)
    precondition(MTLPixelFormat(rawValue: 34) == MTLPixelFormat.rg8Sint)
    precondition(MTLPixelFormat.b5g6r5Unorm.rawValue == 40)
    precondition(MTLPixelFormat(rawValue: 40) == MTLPixelFormat.b5g6r5Unorm)
    precondition(MTLPixelFormat.a1bgr5Unorm.rawValue == 41)
    precondition(MTLPixelFormat(rawValue: 41) == MTLPixelFormat.a1bgr5Unorm)
    precondition(MTLPixelFormat.abgr4Unorm.rawValue == 42)
    precondition(MTLPixelFormat(rawValue: 42) == MTLPixelFormat.abgr4Unorm)
    precondition(MTLPixelFormat.bgr5A1Unorm.rawValue == 43)
    precondition(MTLPixelFormat(rawValue: 43) == MTLPixelFormat.bgr5A1Unorm)
    precondition(MTLPixelFormat.r32Uint.rawValue == 53)
    precondition(MTLPixelFormat(rawValue: 53) == MTLPixelFormat.r32Uint)
    precondition(MTLPixelFormat.r32Sint.rawValue == 54)
    precondition(MTLPixelFormat(rawValue: 54) == MTLPixelFormat.r32Sint)
    precondition(MTLPixelFormat.r32Float.rawValue == 55)
    precondition(MTLPixelFormat(rawValue: 55) == MTLPixelFormat.r32Float)
    precondition(MTLPixelFormat.rg16Unorm.rawValue == 60)
    precondition(MTLPixelFormat(rawValue: 60) == MTLPixelFormat.rg16Unorm)
    precondition(MTLPixelFormat.rg16Snorm.rawValue == 62)
    precondition(MTLPixelFormat(rawValue: 62) == MTLPixelFormat.rg16Snorm)
    precondition(MTLPixelFormat.rg16Uint.rawValue == 63)
    precondition(MTLPixelFormat(rawValue: 63) == MTLPixelFormat.rg16Uint)
    precondition(MTLPixelFormat.rg16Sint.rawValue == 64)
    precondition(MTLPixelFormat(rawValue: 64) == MTLPixelFormat.rg16Sint)
    precondition(MTLPixelFormat.rg16Float.rawValue == 65)
    precondition(MTLPixelFormat(rawValue: 65) == MTLPixelFormat.rg16Float)
    precondition(MTLPixelFormat.rgba8Unorm.rawValue == 70)
    precondition(MTLPixelFormat(rawValue: 70) == MTLPixelFormat.rgba8Unorm)
    precondition(MTLPixelFormat.rgba8Unorm_srgb.rawValue == 71)
    precondition(MTLPixelFormat(rawValue: 71) == MTLPixelFormat.rgba8Unorm_srgb)
    precondition(MTLPixelFormat.rgba8Snorm.rawValue == 72)
    precondition(MTLPixelFormat(rawValue: 72) == MTLPixelFormat.rgba8Snorm)
    precondition(MTLPixelFormat.rgba8Uint.rawValue == 73)
    precondition(MTLPixelFormat(rawValue: 73) == MTLPixelFormat.rgba8Uint)
    precondition(MTLPixelFormat.rgba8Sint.rawValue == 74)
    precondition(MTLPixelFormat(rawValue: 74) == MTLPixelFormat.rgba8Sint)
    precondition(MTLPixelFormat.bgra8Unorm.rawValue == 80)
    precondition(MTLPixelFormat(rawValue: 80) == MTLPixelFormat.bgra8Unorm)
    precondition(MTLPixelFormat.bgra8Unorm_srgb.rawValue == 81)
    precondition(MTLPixelFormat(rawValue: 81) == MTLPixelFormat.bgra8Unorm_srgb)
    precondition(MTLPixelFormat.rgb10a2Unorm.rawValue == 90)
    precondition(MTLPixelFormat(rawValue: 90) == MTLPixelFormat.rgb10a2Unorm)
    precondition(MTLPixelFormat.rgb10a2Uint.rawValue == 91)
    precondition(MTLPixelFormat(rawValue: 91) == MTLPixelFormat.rgb10a2Uint)
    precondition(MTLPixelFormat.rg11b10Float.rawValue == 92)
    precondition(MTLPixelFormat(rawValue: 92) == MTLPixelFormat.rg11b10Float)
    precondition(MTLPixelFormat.rgb9e5Float.rawValue == 93)
    precondition(MTLPixelFormat(rawValue: 93) == MTLPixelFormat.rgb9e5Float)
    precondition(MTLPixelFormat.bgr10a2Unorm.rawValue == 94)
    precondition(MTLPixelFormat(rawValue: 94) == MTLPixelFormat.bgr10a2Unorm)
    precondition(MTLPixelFormat.rg32Uint.rawValue == 103)
    precondition(MTLPixelFormat(rawValue: 103) == MTLPixelFormat.rg32Uint)
    precondition(MTLPixelFormat.rg32Sint.rawValue == 104)
    precondition(MTLPixelFormat(rawValue: 104) == MTLPixelFormat.rg32Sint)
    precondition(MTLPixelFormat.rg32Float.rawValue == 105)
    precondition(MTLPixelFormat(rawValue: 105) == MTLPixelFormat.rg32Float)
    precondition(MTLPixelFormat.rgba16Unorm.rawValue == 110)
    precondition(MTLPixelFormat(rawValue: 110) == MTLPixelFormat.rgba16Unorm)
    precondition(MTLPixelFormat.rgba16Snorm.rawValue == 112)
    precondition(MTLPixelFormat(rawValue: 112) == MTLPixelFormat.rgba16Snorm)
    precondition(MTLPixelFormat.rgba16Uint.rawValue == 113)
    precondition(MTLPixelFormat(rawValue: 113) == MTLPixelFormat.rgba16Uint)
    precondition(MTLPixelFormat.rgba16Sint.rawValue == 114)
    precondition(MTLPixelFormat(rawValue: 114) == MTLPixelFormat.rgba16Sint)
    precondition(MTLPixelFormat.rgba16Float.rawValue == 115)
    precondition(MTLPixelFormat(rawValue: 115) == MTLPixelFormat.rgba16Float)
    precondition(MTLPixelFormat.rgba32Uint.rawValue == 123)
    precondition(MTLPixelFormat(rawValue: 123) == MTLPixelFormat.rgba32Uint)
    precondition(MTLPixelFormat.rgba32Sint.rawValue == 124)
    precondition(MTLPixelFormat(rawValue: 124) == MTLPixelFormat.rgba32Sint)
    precondition(MTLPixelFormat.rgba32Float.rawValue == 125)
    precondition(MTLPixelFormat(rawValue: 125) == MTLPixelFormat.rgba32Float)
    precondition(MTLPixelFormat.bc1_rgba.rawValue == 130)
    precondition(MTLPixelFormat(rawValue: 130) == MTLPixelFormat.bc1_rgba)
    precondition(MTLPixelFormat.bc1_rgba_srgb.rawValue == 131)
    precondition(MTLPixelFormat(rawValue: 131) == MTLPixelFormat.bc1_rgba_srgb)
    precondition(MTLPixelFormat.bc2_rgba.rawValue == 132)
    precondition(MTLPixelFormat(rawValue: 132) == MTLPixelFormat.bc2_rgba)
    precondition(MTLPixelFormat.bc2_rgba_srgb.rawValue == 133)
    precondition(MTLPixelFormat(rawValue: 133) == MTLPixelFormat.bc2_rgba_srgb)
    precondition(MTLPixelFormat.bc3_rgba.rawValue == 134)
    precondition(MTLPixelFormat(rawValue: 134) == MTLPixelFormat.bc3_rgba)
    precondition(MTLPixelFormat.bc3_rgba_srgb.rawValue == 135)
    precondition(MTLPixelFormat(rawValue: 135) == MTLPixelFormat.bc3_rgba_srgb)
    precondition(MTLPixelFormat.bc4_rUnorm.rawValue == 140)
    precondition(MTLPixelFormat(rawValue: 140) == MTLPixelFormat.bc4_rUnorm)
    precondition(MTLPixelFormat.bc4_rSnorm.rawValue == 141)
    precondition(MTLPixelFormat(rawValue: 141) == MTLPixelFormat.bc4_rSnorm)
    precondition(MTLPixelFormat.bc5_rgUnorm.rawValue == 142)
    precondition(MTLPixelFormat(rawValue: 142) == MTLPixelFormat.bc5_rgUnorm)
    precondition(MTLPixelFormat.bc5_rgSnorm.rawValue == 143)
    precondition(MTLPixelFormat(rawValue: 143) == MTLPixelFormat.bc5_rgSnorm)
    precondition(MTLPixelFormat.bc6H_rgbFloat.rawValue == 150)
    precondition(MTLPixelFormat(rawValue: 150) == MTLPixelFormat.bc6H_rgbFloat)
    precondition(MTLPixelFormat.bc6H_rgbuFloat.rawValue == 151)
    precondition(MTLPixelFormat(rawValue: 151) == MTLPixelFormat.bc6H_rgbuFloat)
    precondition(MTLPixelFormat.bc7_rgbaUnorm.rawValue == 152)
    precondition(MTLPixelFormat(rawValue: 152) == MTLPixelFormat.bc7_rgbaUnorm)
    precondition(MTLPixelFormat.bc7_rgbaUnorm_srgb.rawValue == 153)
    precondition(MTLPixelFormat(rawValue: 153) == MTLPixelFormat.bc7_rgbaUnorm_srgb)
    precondition(MTLPixelFormat.pvrtc_rgb_2bpp.rawValue == 160)
    precondition(MTLPixelFormat(rawValue: 160) == MTLPixelFormat.pvrtc_rgb_2bpp)
    precondition(MTLPixelFormat.pvrtc_rgb_2bpp_srgb.rawValue == 161)
    precondition(MTLPixelFormat(rawValue: 161) == MTLPixelFormat.pvrtc_rgb_2bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgb_4bpp.rawValue == 162)
    precondition(MTLPixelFormat(rawValue: 162) == MTLPixelFormat.pvrtc_rgb_4bpp)
    precondition(MTLPixelFormat.pvrtc_rgb_4bpp_srgb.rawValue == 163)
    precondition(MTLPixelFormat(rawValue: 163) == MTLPixelFormat.pvrtc_rgb_4bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgba_2bpp.rawValue == 164)
    precondition(MTLPixelFormat(rawValue: 164) == MTLPixelFormat.pvrtc_rgba_2bpp)
    precondition(MTLPixelFormat.pvrtc_rgba_2bpp_srgb.rawValue == 165)
    precondition(MTLPixelFormat(rawValue: 165) == MTLPixelFormat.pvrtc_rgba_2bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgba_4bpp.rawValue == 166)
    precondition(MTLPixelFormat(rawValue: 166) == MTLPixelFormat.pvrtc_rgba_4bpp)
    precondition(MTLPixelFormat.pvrtc_rgba_4bpp_srgb.rawValue == 167)
    precondition(MTLPixelFormat(rawValue: 167) == MTLPixelFormat.pvrtc_rgba_4bpp_srgb)
    precondition(MTLPixelFormat.eac_r11Unorm.rawValue == 170)
    precondition(MTLPixelFormat(rawValue: 170) == MTLPixelFormat.eac_r11Unorm)
    precondition(MTLPixelFormat.eac_r11Snorm.rawValue == 172)
    precondition(MTLPixelFormat(rawValue: 172) == MTLPixelFormat.eac_r11Snorm)
    precondition(MTLPixelFormat.eac_rg11Unorm.rawValue == 174)
    precondition(MTLPixelFormat(rawValue: 174) == MTLPixelFormat.eac_rg11Unorm)
    precondition(MTLPixelFormat.eac_rg11Snorm.rawValue == 176)
    precondition(MTLPixelFormat(rawValue: 176) == MTLPixelFormat.eac_rg11Snorm)
    precondition(MTLPixelFormat.eac_rgba8.rawValue == 178)
    precondition(MTLPixelFormat(rawValue: 178) == MTLPixelFormat.eac_rgba8)
    precondition(MTLPixelFormat.eac_rgba8_srgb.rawValue == 179)
    precondition(MTLPixelFormat(rawValue: 179) == MTLPixelFormat.eac_rgba8_srgb)
    precondition(MTLPixelFormat.etc2_rgb8.rawValue == 180)
    precondition(MTLPixelFormat(rawValue: 180) == MTLPixelFormat.etc2_rgb8)
    precondition(MTLPixelFormat.etc2_rgb8_srgb.rawValue == 181)
    precondition(MTLPixelFormat(rawValue: 181) == MTLPixelFormat.etc2_rgb8_srgb)
    precondition(MTLPixelFormat.etc2_rgb8a1.rawValue == 182)
    precondition(MTLPixelFormat(rawValue: 182) == MTLPixelFormat.etc2_rgb8a1)
    precondition(MTLPixelFormat.etc2_rgb8a1_srgb.rawValue == 183)
    precondition(MTLPixelFormat(rawValue: 183) == MTLPixelFormat.etc2_rgb8a1_srgb)
    precondition(MTLPixelFormat.astc_4x4_srgb.rawValue == 186)
    precondition(MTLPixelFormat(rawValue: 186) == MTLPixelFormat.astc_4x4_srgb)
    precondition(MTLPixelFormat.astc_5x4_srgb.rawValue == 187)
    precondition(MTLPixelFormat(rawValue: 187) == MTLPixelFormat.astc_5x4_srgb)
    precondition(MTLPixelFormat.astc_5x5_srgb.rawValue == 188)
    precondition(MTLPixelFormat(rawValue: 188) == MTLPixelFormat.astc_5x5_srgb)
    precondition(MTLPixelFormat.astc_6x5_srgb.rawValue == 189)
    precondition(MTLPixelFormat(rawValue: 189) == MTLPixelFormat.astc_6x5_srgb)
    precondition(MTLPixelFormat.astc_6x6_srgb.rawValue == 190)
    precondition(MTLPixelFormat(rawValue: 190) == MTLPixelFormat.astc_6x6_srgb)
    precondition(MTLPixelFormat.astc_8x5_srgb.rawValue == 192)
    precondition(MTLPixelFormat(rawValue: 192) == MTLPixelFormat.astc_8x5_srgb)
    precondition(MTLPixelFormat.astc_8x6_srgb.rawValue == 193)
    precondition(MTLPixelFormat(rawValue: 193) == MTLPixelFormat.astc_8x6_srgb)
    precondition(MTLPixelFormat.astc_8x8_srgb.rawValue == 194)
    precondition(MTLPixelFormat(rawValue: 194) == MTLPixelFormat.astc_8x8_srgb)
    precondition(MTLPixelFormat.astc_10x5_srgb.rawValue == 195)
    precondition(MTLPixelFormat(rawValue: 195) == MTLPixelFormat.astc_10x5_srgb)
    precondition(MTLPixelFormat.astc_10x6_srgb.rawValue == 196)
    precondition(MTLPixelFormat(rawValue: 196) == MTLPixelFormat.astc_10x6_srgb)
    precondition(MTLPixelFormat.astc_10x8_srgb.rawValue == 197)
    precondition(MTLPixelFormat(rawValue: 197) == MTLPixelFormat.astc_10x8_srgb)
    precondition(MTLPixelFormat.astc_10x10_srgb.rawValue == 198)
    precondition(MTLPixelFormat(rawValue: 198) == MTLPixelFormat.astc_10x10_srgb)
    precondition(MTLPixelFormat.astc_12x10_srgb.rawValue == 199)
    precondition(MTLPixelFormat(rawValue: 199) == MTLPixelFormat.astc_12x10_srgb)
    precondition(MTLPixelFormat.astc_12x12_srgb.rawValue == 200)
    precondition(MTLPixelFormat(rawValue: 200) == MTLPixelFormat.astc_12x12_srgb)
    precondition(MTLPixelFormat.astc_4x4_ldr.rawValue == 204)
    precondition(MTLPixelFormat(rawValue: 204) == MTLPixelFormat.astc_4x4_ldr)
    precondition(MTLPixelFormat.astc_5x4_ldr.rawValue == 205)
    precondition(MTLPixelFormat(rawValue: 205) == MTLPixelFormat.astc_5x4_ldr)
    precondition(MTLPixelFormat.astc_5x5_ldr.rawValue == 206)
    precondition(MTLPixelFormat(rawValue: 206) == MTLPixelFormat.astc_5x5_ldr)
    precondition(MTLPixelFormat.astc_6x5_ldr.rawValue == 207)
    precondition(MTLPixelFormat(rawValue: 207) == MTLPixelFormat.astc_6x5_ldr)
    precondition(MTLPixelFormat.astc_6x6_ldr.rawValue == 208)
    precondition(MTLPixelFormat(rawValue: 208) == MTLPixelFormat.astc_6x6_ldr)
    precondition(MTLPixelFormat.astc_8x5_ldr.rawValue == 210)
    precondition(MTLPixelFormat(rawValue: 210) == MTLPixelFormat.astc_8x5_ldr)
    precondition(MTLPixelFormat.astc_8x6_ldr.rawValue == 211)
    precondition(MTLPixelFormat(rawValue: 211) == MTLPixelFormat.astc_8x6_ldr)
    precondition(MTLPixelFormat.astc_8x8_ldr.rawValue == 212)
    precondition(MTLPixelFormat(rawValue: 212) == MTLPixelFormat.astc_8x8_ldr)
    precondition(MTLPixelFormat.astc_10x5_ldr.rawValue == 213)
    precondition(MTLPixelFormat(rawValue: 213) == MTLPixelFormat.astc_10x5_ldr)
    precondition(MTLPixelFormat.astc_10x6_ldr.rawValue == 214)
    precondition(MTLPixelFormat(rawValue: 214) == MTLPixelFormat.astc_10x6_ldr)
    precondition(MTLPixelFormat.astc_10x8_ldr.rawValue == 215)
    precondition(MTLPixelFormat(rawValue: 215) == MTLPixelFormat.astc_10x8_ldr)
    precondition(MTLPixelFormat.astc_10x10_ldr.rawValue == 216)
    precondition(MTLPixelFormat(rawValue: 216) == MTLPixelFormat.astc_10x10_ldr)
    precondition(MTLPixelFormat.astc_12x10_ldr.rawValue == 217)
    precondition(MTLPixelFormat(rawValue: 217) == MTLPixelFormat.astc_12x10_ldr)
    precondition(MTLPixelFormat.astc_12x12_ldr.rawValue == 218)
    precondition(MTLPixelFormat(rawValue: 218) == MTLPixelFormat.astc_12x12_ldr)
    precondition(MTLPixelFormat.astc_4x4_hdr.rawValue == 222)
    precondition(MTLPixelFormat(rawValue: 222) == MTLPixelFormat.astc_4x4_hdr)
    precondition(MTLPixelFormat.astc_5x4_hdr.rawValue == 223)
    precondition(MTLPixelFormat(rawValue: 223) == MTLPixelFormat.astc_5x4_hdr)
    precondition(MTLPixelFormat.astc_5x5_hdr.rawValue == 224)
    precondition(MTLPixelFormat(rawValue: 224) == MTLPixelFormat.astc_5x5_hdr)
    precondition(MTLPixelFormat.astc_6x5_hdr.rawValue == 225)
    precondition(MTLPixelFormat(rawValue: 225) == MTLPixelFormat.astc_6x5_hdr)
    precondition(MTLPixelFormat.astc_6x6_hdr.rawValue == 226)
    precondition(MTLPixelFormat(rawValue: 226) == MTLPixelFormat.astc_6x6_hdr)
    precondition(MTLPixelFormat.astc_8x5_hdr.rawValue == 228)
    precondition(MTLPixelFormat(rawValue: 228) == MTLPixelFormat.astc_8x5_hdr)
    precondition(MTLPixelFormat.astc_8x6_hdr.rawValue == 229)
    precondition(MTLPixelFormat(rawValue: 229) == MTLPixelFormat.astc_8x6_hdr)
    precondition(MTLPixelFormat.astc_8x8_hdr.rawValue == 230)
    precondition(MTLPixelFormat(rawValue: 230) == MTLPixelFormat.astc_8x8_hdr)
    precondition(MTLPixelFormat.astc_10x5_hdr.rawValue == 231)
    precondition(MTLPixelFormat(rawValue: 231) == MTLPixelFormat.astc_10x5_hdr)
    precondition(MTLPixelFormat.astc_10x6_hdr.rawValue == 232)
    precondition(MTLPixelFormat(rawValue: 232) == MTLPixelFormat.astc_10x6_hdr)
    precondition(MTLPixelFormat.astc_10x8_hdr.rawValue == 233)
    precondition(MTLPixelFormat(rawValue: 233) == MTLPixelFormat.astc_10x8_hdr)
    precondition(MTLPixelFormat.astc_10x10_hdr.rawValue == 234)
    precondition(MTLPixelFormat(rawValue: 234) == MTLPixelFormat.astc_10x10_hdr)
    precondition(MTLPixelFormat.astc_12x10_hdr.rawValue == 235)
    precondition(MTLPixelFormat(rawValue: 235) == MTLPixelFormat.astc_12x10_hdr)
    precondition(MTLPixelFormat.astc_12x12_hdr.rawValue == 236)
    precondition(MTLPixelFormat(rawValue: 236) == MTLPixelFormat.astc_12x12_hdr)
    precondition(MTLPixelFormat.gbgr422.rawValue == 240)
    precondition(MTLPixelFormat(rawValue: 240) == MTLPixelFormat.gbgr422)
    precondition(MTLPixelFormat.bgrg422.rawValue == 241)
    precondition(MTLPixelFormat(rawValue: 241) == MTLPixelFormat.bgrg422)
    precondition(MTLPixelFormat.depth16Unorm.rawValue == 250)
    precondition(MTLPixelFormat(rawValue: 250) == MTLPixelFormat.depth16Unorm)
    precondition(MTLPixelFormat.depth32Float.rawValue == 252)
    precondition(MTLPixelFormat(rawValue: 252) == MTLPixelFormat.depth32Float)
    precondition(MTLPixelFormat.stencil8.rawValue == 253)
    precondition(MTLPixelFormat(rawValue: 253) == MTLPixelFormat.stencil8)
    precondition(MTLPixelFormat.depth32Float_stencil8.rawValue == 260)
    precondition(MTLPixelFormat(rawValue: 260) == MTLPixelFormat.depth32Float_stencil8)
    precondition(MTLPixelFormat.x32_stencil8.rawValue == 261)
    precondition(MTLPixelFormat(rawValue: 261) == MTLPixelFormat.x32_stencil8)
    precondition(MTLPixelFormat.bgra10_xr.rawValue == 552)
    precondition(MTLPixelFormat(rawValue: 552) == MTLPixelFormat.bgra10_xr)
    precondition(MTLPixelFormat.bgra10_xr_srgb.rawValue == 553)
    precondition(MTLPixelFormat(rawValue: 553) == MTLPixelFormat.bgra10_xr_srgb)
    precondition(MTLPixelFormat.bgr10_xr.rawValue == 554)
    precondition(MTLPixelFormat(rawValue: 554) == MTLPixelFormat.bgr10_xr)
    precondition(MTLPixelFormat.bgr10_xr_srgb.rawValue == 555)
    precondition(MTLPixelFormat(rawValue: 555) == MTLPixelFormat.bgr10_xr_srgb)
    precondition(MTLPixelFormat.invalid != MTLPixelFormat.a8Unorm)
    var MTLPixelFormatSet: Set<MTLPixelFormat> = [.invalid]
    MTLPixelFormatSet.insert(.a8Unorm)
    precondition(MTLPixelFormatSet.count == 2)

    _ = MTLPrimitiveType.point
    precondition(MTLPrimitiveType.point.rawValue == 0)
    precondition(MTLPrimitiveType(rawValue: 0) == MTLPrimitiveType.point)
    precondition(MTLPrimitiveType.line.rawValue == 1)
    precondition(MTLPrimitiveType(rawValue: 1) == MTLPrimitiveType.line)
    precondition(MTLPrimitiveType.lineStrip.rawValue == 2)
    precondition(MTLPrimitiveType(rawValue: 2) == MTLPrimitiveType.lineStrip)
    precondition(MTLPrimitiveType.triangle.rawValue == 3)
    precondition(MTLPrimitiveType(rawValue: 3) == MTLPrimitiveType.triangle)
    precondition(MTLPrimitiveType.triangleStrip.rawValue == 4)
    precondition(MTLPrimitiveType(rawValue: 4) == MTLPrimitiveType.triangleStrip)
    precondition(MTLPrimitiveType.point != MTLPrimitiveType.line)
    var MTLPrimitiveTypeSet: Set<MTLPrimitiveType> = [.point]
    MTLPrimitiveTypeSet.insert(.line)
    precondition(MTLPrimitiveTypeSet.count == 2)

    _ = MTLPurgeableState.keepCurrent
    precondition(MTLPurgeableState.keepCurrent.rawValue == 1)
    precondition(MTLPurgeableState(rawValue: 1) == MTLPurgeableState.keepCurrent)
    precondition(MTLPurgeableState.nonVolatile.rawValue == 2)
    precondition(MTLPurgeableState(rawValue: 2) == MTLPurgeableState.nonVolatile)
    precondition(MTLPurgeableState.volatile.rawValue == 3)
    precondition(MTLPurgeableState(rawValue: 3) == MTLPurgeableState.volatile)
    precondition(MTLPurgeableState.empty.rawValue == 4)
    precondition(MTLPurgeableState(rawValue: 4) == MTLPurgeableState.empty)
    precondition(MTLPurgeableState.keepCurrent != MTLPurgeableState.nonVolatile)
    var MTLPurgeableStateSet: Set<MTLPurgeableState> = [.keepCurrent]
    MTLPurgeableStateSet.insert(.nonVolatile)
    precondition(MTLPurgeableStateSet.count == 2)

    _ = MTLReadWriteTextureTier.tierNone
    precondition(MTLReadWriteTextureTier.tierNone.rawValue == 0)
    precondition(MTLReadWriteTextureTier(rawValue: 0) == MTLReadWriteTextureTier.tierNone)
    precondition(MTLReadWriteTextureTier.tier1.rawValue == 1)
    precondition(MTLReadWriteTextureTier(rawValue: 1) == MTLReadWriteTextureTier.tier1)
    precondition(MTLReadWriteTextureTier.tier2.rawValue == 2)
    precondition(MTLReadWriteTextureTier(rawValue: 2) == MTLReadWriteTextureTier.tier2)
    precondition(MTLReadWriteTextureTier.tierNone != MTLReadWriteTextureTier.tier1)
    var MTLReadWriteTextureTierSet: Set<MTLReadWriteTextureTier> = [.tierNone]
    MTLReadWriteTextureTierSet.insert(.tier1)
    precondition(MTLReadWriteTextureTierSet.count == 2)

    _ = MTLSamplerAddressMode.clampToEdge
    precondition(MTLSamplerAddressMode.clampToEdge.rawValue == 0)
    precondition(MTLSamplerAddressMode(rawValue: 0) == MTLSamplerAddressMode.clampToEdge)
    precondition(MTLSamplerAddressMode.mirrorClampToEdge.rawValue == 1)
    precondition(MTLSamplerAddressMode(rawValue: 1) == MTLSamplerAddressMode.mirrorClampToEdge)
    precondition(MTLSamplerAddressMode.`repeat`.rawValue == 2)
    precondition(MTLSamplerAddressMode(rawValue: 2) == MTLSamplerAddressMode.`repeat`)
    precondition(MTLSamplerAddressMode.mirrorRepeat.rawValue == 3)
    precondition(MTLSamplerAddressMode(rawValue: 3) == MTLSamplerAddressMode.mirrorRepeat)
    precondition(MTLSamplerAddressMode.clampToZero.rawValue == 4)
    precondition(MTLSamplerAddressMode(rawValue: 4) == MTLSamplerAddressMode.clampToZero)
    precondition(MTLSamplerAddressMode.clampToBorderColor.rawValue == 5)
    precondition(MTLSamplerAddressMode(rawValue: 5) == MTLSamplerAddressMode.clampToBorderColor)
    precondition(MTLSamplerAddressMode.clampToEdge != MTLSamplerAddressMode.mirrorClampToEdge)
    var MTLSamplerAddressModeSet: Set<MTLSamplerAddressMode> = [.clampToEdge]
    MTLSamplerAddressModeSet.insert(.mirrorClampToEdge)
    precondition(MTLSamplerAddressModeSet.count == 2)

    _ = MTLSamplerBorderColor.transparentBlack
    precondition(MTLSamplerBorderColor.transparentBlack.rawValue == 0)
    precondition(MTLSamplerBorderColor(rawValue: 0) == MTLSamplerBorderColor.transparentBlack)
    precondition(MTLSamplerBorderColor.opaqueBlack.rawValue == 1)
    precondition(MTLSamplerBorderColor(rawValue: 1) == MTLSamplerBorderColor.opaqueBlack)
    precondition(MTLSamplerBorderColor.opaqueWhite.rawValue == 2)
    precondition(MTLSamplerBorderColor(rawValue: 2) == MTLSamplerBorderColor.opaqueWhite)
    precondition(MTLSamplerBorderColor.transparentBlack != MTLSamplerBorderColor.opaqueBlack)
    var MTLSamplerBorderColorSet: Set<MTLSamplerBorderColor> = [.transparentBlack]
    MTLSamplerBorderColorSet.insert(.opaqueBlack)
    precondition(MTLSamplerBorderColorSet.count == 2)

    _ = MTLSamplerMinMagFilter.nearest
    precondition(MTLSamplerMinMagFilter.nearest.rawValue == 0)
    precondition(MTLSamplerMinMagFilter(rawValue: 0) == MTLSamplerMinMagFilter.nearest)
    precondition(MTLSamplerMinMagFilter.linear.rawValue == 1)
    precondition(MTLSamplerMinMagFilter(rawValue: 1) == MTLSamplerMinMagFilter.linear)
    precondition(MTLSamplerMinMagFilter.nearest != MTLSamplerMinMagFilter.linear)
    var MTLSamplerMinMagFilterSet: Set<MTLSamplerMinMagFilter> = [.nearest]
    MTLSamplerMinMagFilterSet.insert(.linear)
    precondition(MTLSamplerMinMagFilterSet.count == 2)

    _ = MTLSamplerMipFilter.notMipmapped
    precondition(MTLSamplerMipFilter.notMipmapped.rawValue == 0)
    precondition(MTLSamplerMipFilter(rawValue: 0) == MTLSamplerMipFilter.notMipmapped)
    precondition(MTLSamplerMipFilter.nearest.rawValue == 1)
    precondition(MTLSamplerMipFilter(rawValue: 1) == MTLSamplerMipFilter.nearest)
    precondition(MTLSamplerMipFilter.linear.rawValue == 2)
    precondition(MTLSamplerMipFilter(rawValue: 2) == MTLSamplerMipFilter.linear)
    precondition(MTLSamplerMipFilter.notMipmapped != MTLSamplerMipFilter.nearest)
    var MTLSamplerMipFilterSet: Set<MTLSamplerMipFilter> = [.notMipmapped]
    MTLSamplerMipFilterSet.insert(.nearest)
    precondition(MTLSamplerMipFilterSet.count == 2)

    _ = MTLSamplerReductionMode.weightedAverage
    precondition(MTLSamplerReductionMode.weightedAverage.rawValue == 0)
    precondition(MTLSamplerReductionMode(rawValue: 0) == MTLSamplerReductionMode.weightedAverage)
    precondition(MTLSamplerReductionMode.minimum.rawValue == 1)
    precondition(MTLSamplerReductionMode(rawValue: 1) == MTLSamplerReductionMode.minimum)
    precondition(MTLSamplerReductionMode.maximum.rawValue == 2)
    precondition(MTLSamplerReductionMode(rawValue: 2) == MTLSamplerReductionMode.maximum)
    precondition(MTLSamplerReductionMode.weightedAverage != MTLSamplerReductionMode.minimum)
    var MTLSamplerReductionModeSet: Set<MTLSamplerReductionMode> = [.weightedAverage]
    MTLSamplerReductionModeSet.insert(.minimum)
    precondition(MTLSamplerReductionModeSet.count == 2)

    _ = MTLShaderValidation.`default`
    precondition(MTLShaderValidation.`default`.rawValue == 0)
    precondition(MTLShaderValidation(rawValue: 0) == MTLShaderValidation.`default`)
    precondition(MTLShaderValidation.enabled.rawValue == 1)
    precondition(MTLShaderValidation(rawValue: 1) == MTLShaderValidation.enabled)
    precondition(MTLShaderValidation.disabled.rawValue == 2)
    precondition(MTLShaderValidation(rawValue: 2) == MTLShaderValidation.disabled)
    precondition(MTLShaderValidation.`default` != MTLShaderValidation.enabled)
    var MTLShaderValidationSet: Set<MTLShaderValidation> = [.`default`]
    MTLShaderValidationSet.insert(.enabled)
    precondition(MTLShaderValidationSet.count == 2)

    _ = MTLSparsePageSize.size16
    precondition(MTLSparsePageSize.size16.rawValue == 16)
    precondition(MTLSparsePageSize(rawValue: 16) == MTLSparsePageSize.size16)
    precondition(MTLSparsePageSize.size64.rawValue == 64)
    precondition(MTLSparsePageSize(rawValue: 64) == MTLSparsePageSize.size64)
    precondition(MTLSparsePageSize.size256.rawValue == 256)
    precondition(MTLSparsePageSize(rawValue: 256) == MTLSparsePageSize.size256)
    precondition(MTLSparsePageSize.size16 != MTLSparsePageSize.size64)
    var MTLSparsePageSizeSet: Set<MTLSparsePageSize> = [.size16]
    MTLSparsePageSizeSet.insert(.size64)
    precondition(MTLSparsePageSizeSet.count == 2)

    _ = MTLSparseTextureMappingMode.map
    precondition(MTLSparseTextureMappingMode.map.rawValue == 0)
    precondition(MTLSparseTextureMappingMode(rawValue: 0) == MTLSparseTextureMappingMode.map)
    precondition(MTLSparseTextureMappingMode.unmap.rawValue == 1)
    precondition(MTLSparseTextureMappingMode(rawValue: 1) == MTLSparseTextureMappingMode.unmap)
    precondition(MTLSparseTextureMappingMode.map != MTLSparseTextureMappingMode.unmap)
    var MTLSparseTextureMappingModeSet: Set<MTLSparseTextureMappingMode> = [.map]
    MTLSparseTextureMappingModeSet.insert(.unmap)
    precondition(MTLSparseTextureMappingModeSet.count == 2)

    _ = MTLStencilOperation.keep
    precondition(MTLStencilOperation.keep.rawValue == 0)
    precondition(MTLStencilOperation(rawValue: 0) == MTLStencilOperation.keep)
    precondition(MTLStencilOperation.zero.rawValue == 1)
    precondition(MTLStencilOperation(rawValue: 1) == MTLStencilOperation.zero)
    precondition(MTLStencilOperation.replace.rawValue == 2)
    precondition(MTLStencilOperation(rawValue: 2) == MTLStencilOperation.replace)
    precondition(MTLStencilOperation.incrementClamp.rawValue == 3)
    precondition(MTLStencilOperation(rawValue: 3) == MTLStencilOperation.incrementClamp)
    precondition(MTLStencilOperation.decrementClamp.rawValue == 4)
    precondition(MTLStencilOperation(rawValue: 4) == MTLStencilOperation.decrementClamp)
    precondition(MTLStencilOperation.invert.rawValue == 5)
    precondition(MTLStencilOperation(rawValue: 5) == MTLStencilOperation.invert)
    precondition(MTLStencilOperation.incrementWrap.rawValue == 6)
    precondition(MTLStencilOperation(rawValue: 6) == MTLStencilOperation.incrementWrap)
    precondition(MTLStencilOperation.decrementWrap.rawValue == 7)
    precondition(MTLStencilOperation(rawValue: 7) == MTLStencilOperation.decrementWrap)
    precondition(MTLStencilOperation.keep != MTLStencilOperation.zero)
    var MTLStencilOperationSet: Set<MTLStencilOperation> = [.keep]
    MTLStencilOperationSet.insert(.zero)
    precondition(MTLStencilOperationSet.count == 2)

    _ = MTLStorageMode.shared
    precondition(MTLStorageMode.shared.rawValue == 0)
    precondition(MTLStorageMode(rawValue: 0) == MTLStorageMode.shared)
    precondition(MTLStorageMode.`private`.rawValue == 2)
    precondition(MTLStorageMode(rawValue: 2) == MTLStorageMode.`private`)
    precondition(MTLStorageMode.memoryless.rawValue == 3)
    precondition(MTLStorageMode(rawValue: 3) == MTLStorageMode.memoryless)
    precondition(MTLStorageMode.shared != MTLStorageMode.`private`)
    var MTLStorageModeSet: Set<MTLStorageMode> = [.shared]
    MTLStorageModeSet.insert(.`private`)
    precondition(MTLStorageModeSet.count == 2)

    _ = MTLStoreAction.dontCare
    precondition(MTLStoreAction.dontCare.rawValue == 0)
    precondition(MTLStoreAction(rawValue: 0) == MTLStoreAction.dontCare)
    precondition(MTLStoreAction.store.rawValue == 1)
    precondition(MTLStoreAction(rawValue: 1) == MTLStoreAction.store)
    precondition(MTLStoreAction.multisampleResolve.rawValue == 2)
    precondition(MTLStoreAction(rawValue: 2) == MTLStoreAction.multisampleResolve)
    precondition(MTLStoreAction.storeAndMultisampleResolve.rawValue == 3)
    precondition(MTLStoreAction(rawValue: 3) == MTLStoreAction.storeAndMultisampleResolve)
    precondition(MTLStoreAction.unknown.rawValue == 4)
    precondition(MTLStoreAction(rawValue: 4) == MTLStoreAction.unknown)
    precondition(MTLStoreAction.customSampleDepthStore.rawValue == 5)
    precondition(MTLStoreAction(rawValue: 5) == MTLStoreAction.customSampleDepthStore)
    precondition(MTLStoreAction.dontCare != MTLStoreAction.store)
    var MTLStoreActionSet: Set<MTLStoreAction> = [.dontCare]
    MTLStoreActionSet.insert(.store)
    precondition(MTLStoreActionSet.count == 2)

    _ = MTLTextureCompressionType.lossless
    precondition(MTLTextureCompressionType.lossless.rawValue == 0)
    precondition(MTLTextureCompressionType(rawValue: 0) == MTLTextureCompressionType.lossless)
    precondition(MTLTextureCompressionType.lossy.rawValue == 1)
    precondition(MTLTextureCompressionType(rawValue: 1) == MTLTextureCompressionType.lossy)
    precondition(MTLTextureCompressionType.lossless != MTLTextureCompressionType.lossy)
    var MTLTextureCompressionTypeSet: Set<MTLTextureCompressionType> = [.lossless]
    MTLTextureCompressionTypeSet.insert(.lossy)
    precondition(MTLTextureCompressionTypeSet.count == 2)

    _ = MTLTextureSparseTier.tierNone
    precondition(MTLTextureSparseTier.tierNone.rawValue == 0)
    precondition(MTLTextureSparseTier(rawValue: 0) == MTLTextureSparseTier.tierNone)
    precondition(MTLTextureSparseTier.tier1.rawValue == 1)
    precondition(MTLTextureSparseTier(rawValue: 1) == MTLTextureSparseTier.tier1)
    precondition(MTLTextureSparseTier.tier2.rawValue == 2)
    precondition(MTLTextureSparseTier(rawValue: 2) == MTLTextureSparseTier.tier2)
    precondition(MTLTextureSparseTier.tierNone != MTLTextureSparseTier.tier1)
    var MTLTextureSparseTierSet: Set<MTLTextureSparseTier> = [.tierNone]
    MTLTextureSparseTierSet.insert(.tier1)
    precondition(MTLTextureSparseTierSet.count == 2)

    _ = MTLTextureSwizzle.zero
    precondition(MTLTextureSwizzle.zero.rawValue == 0)
    precondition(MTLTextureSwizzle(rawValue: 0) == MTLTextureSwizzle.zero)
    precondition(MTLTextureSwizzle.one.rawValue == 1)
    precondition(MTLTextureSwizzle(rawValue: 1) == MTLTextureSwizzle.one)
    precondition(MTLTextureSwizzle.red.rawValue == 2)
    precondition(MTLTextureSwizzle(rawValue: 2) == MTLTextureSwizzle.red)
    precondition(MTLTextureSwizzle.green.rawValue == 3)
    precondition(MTLTextureSwizzle(rawValue: 3) == MTLTextureSwizzle.green)
    precondition(MTLTextureSwizzle.blue.rawValue == 4)
    precondition(MTLTextureSwizzle(rawValue: 4) == MTLTextureSwizzle.blue)
    precondition(MTLTextureSwizzle.alpha.rawValue == 5)
    precondition(MTLTextureSwizzle(rawValue: 5) == MTLTextureSwizzle.alpha)
    precondition(MTLTextureSwizzle.zero != MTLTextureSwizzle.one)
    var MTLTextureSwizzleSet: Set<MTLTextureSwizzle> = [.zero]
    MTLTextureSwizzleSet.insert(.one)
    precondition(MTLTextureSwizzleSet.count == 2)

    _ = MTLTextureType.type1D
    precondition(MTLTextureType.type1D.rawValue == 0)
    precondition(MTLTextureType(rawValue: 0) == MTLTextureType.type1D)
    precondition(MTLTextureType.type1DArray.rawValue == 1)
    precondition(MTLTextureType(rawValue: 1) == MTLTextureType.type1DArray)
    precondition(MTLTextureType.type2D.rawValue == 2)
    precondition(MTLTextureType(rawValue: 2) == MTLTextureType.type2D)
    precondition(MTLTextureType.type2DArray.rawValue == 3)
    precondition(MTLTextureType(rawValue: 3) == MTLTextureType.type2DArray)
    precondition(MTLTextureType.type2DMultisample.rawValue == 4)
    precondition(MTLTextureType(rawValue: 4) == MTLTextureType.type2DMultisample)
    precondition(MTLTextureType.typeCube.rawValue == 5)
    precondition(MTLTextureType(rawValue: 5) == MTLTextureType.typeCube)
    precondition(MTLTextureType.typeCubeArray.rawValue == 6)
    precondition(MTLTextureType(rawValue: 6) == MTLTextureType.typeCubeArray)
    precondition(MTLTextureType.type3D.rawValue == 7)
    precondition(MTLTextureType(rawValue: 7) == MTLTextureType.type3D)
    precondition(MTLTextureType.type2DMultisampleArray.rawValue == 8)
    precondition(MTLTextureType(rawValue: 8) == MTLTextureType.type2DMultisampleArray)
    precondition(MTLTextureType.typeTextureBuffer.rawValue == 9)
    precondition(MTLTextureType(rawValue: 9) == MTLTextureType.typeTextureBuffer)
    precondition(MTLTextureType.type1D != MTLTextureType.type1DArray)
    var MTLTextureTypeSet: Set<MTLTextureType> = [.type1D]
    MTLTextureTypeSet.insert(.type1DArray)
    precondition(MTLTextureTypeSet.count == 2)

    _ = MTLTriangleFillMode.fill
    precondition(MTLTriangleFillMode.fill.rawValue == 0)
    precondition(MTLTriangleFillMode(rawValue: 0) == MTLTriangleFillMode.fill)
    precondition(MTLTriangleFillMode.lines.rawValue == 1)
    precondition(MTLTriangleFillMode(rawValue: 1) == MTLTriangleFillMode.lines)
    precondition(MTLTriangleFillMode.fill != MTLTriangleFillMode.lines)
    var MTLTriangleFillModeSet: Set<MTLTriangleFillMode> = [.fill]
    MTLTriangleFillModeSet.insert(.lines)
    precondition(MTLTriangleFillModeSet.count == 2)

    _ = MTLVertexFormat.invalid
    precondition(MTLVertexFormat.invalid.rawValue == 0)
    precondition(MTLVertexFormat(rawValue: 0) == MTLVertexFormat.invalid)
    precondition(MTLVertexFormat.uchar2.rawValue == 1)
    precondition(MTLVertexFormat(rawValue: 1) == MTLVertexFormat.uchar2)
    precondition(MTLVertexFormat.uchar3.rawValue == 2)
    precondition(MTLVertexFormat(rawValue: 2) == MTLVertexFormat.uchar3)
    precondition(MTLVertexFormat.uchar4.rawValue == 3)
    precondition(MTLVertexFormat(rawValue: 3) == MTLVertexFormat.uchar4)
    precondition(MTLVertexFormat.char2.rawValue == 4)
    precondition(MTLVertexFormat(rawValue: 4) == MTLVertexFormat.char2)
    precondition(MTLVertexFormat.char3.rawValue == 5)
    precondition(MTLVertexFormat(rawValue: 5) == MTLVertexFormat.char3)
    precondition(MTLVertexFormat.char4.rawValue == 6)
    precondition(MTLVertexFormat(rawValue: 6) == MTLVertexFormat.char4)
    precondition(MTLVertexFormat.uchar2Normalized.rawValue == 7)
    precondition(MTLVertexFormat(rawValue: 7) == MTLVertexFormat.uchar2Normalized)
    precondition(MTLVertexFormat.uchar3Normalized.rawValue == 8)
    precondition(MTLVertexFormat(rawValue: 8) == MTLVertexFormat.uchar3Normalized)
    precondition(MTLVertexFormat.uchar4Normalized.rawValue == 9)
    precondition(MTLVertexFormat(rawValue: 9) == MTLVertexFormat.uchar4Normalized)
    precondition(MTLVertexFormat.char2Normalized.rawValue == 10)
    precondition(MTLVertexFormat(rawValue: 10) == MTLVertexFormat.char2Normalized)
    precondition(MTLVertexFormat.char3Normalized.rawValue == 11)
    precondition(MTLVertexFormat(rawValue: 11) == MTLVertexFormat.char3Normalized)
    precondition(MTLVertexFormat.char4Normalized.rawValue == 12)
    precondition(MTLVertexFormat(rawValue: 12) == MTLVertexFormat.char4Normalized)
    precondition(MTLVertexFormat.ushort2.rawValue == 13)
    precondition(MTLVertexFormat(rawValue: 13) == MTLVertexFormat.ushort2)
    precondition(MTLVertexFormat.ushort3.rawValue == 14)
    precondition(MTLVertexFormat(rawValue: 14) == MTLVertexFormat.ushort3)
    precondition(MTLVertexFormat.ushort4.rawValue == 15)
    precondition(MTLVertexFormat(rawValue: 15) == MTLVertexFormat.ushort4)
    precondition(MTLVertexFormat.short2.rawValue == 16)
    precondition(MTLVertexFormat(rawValue: 16) == MTLVertexFormat.short2)
    precondition(MTLVertexFormat.short3.rawValue == 17)
    precondition(MTLVertexFormat(rawValue: 17) == MTLVertexFormat.short3)
    precondition(MTLVertexFormat.short4.rawValue == 18)
    precondition(MTLVertexFormat(rawValue: 18) == MTLVertexFormat.short4)
    precondition(MTLVertexFormat.ushort2Normalized.rawValue == 19)
    precondition(MTLVertexFormat(rawValue: 19) == MTLVertexFormat.ushort2Normalized)
    precondition(MTLVertexFormat.ushort3Normalized.rawValue == 20)
    precondition(MTLVertexFormat(rawValue: 20) == MTLVertexFormat.ushort3Normalized)
    precondition(MTLVertexFormat.ushort4Normalized.rawValue == 21)
    precondition(MTLVertexFormat(rawValue: 21) == MTLVertexFormat.ushort4Normalized)
    precondition(MTLVertexFormat.short2Normalized.rawValue == 22)
    precondition(MTLVertexFormat(rawValue: 22) == MTLVertexFormat.short2Normalized)
    precondition(MTLVertexFormat.short3Normalized.rawValue == 23)
    precondition(MTLVertexFormat(rawValue: 23) == MTLVertexFormat.short3Normalized)
    precondition(MTLVertexFormat.short4Normalized.rawValue == 24)
    precondition(MTLVertexFormat(rawValue: 24) == MTLVertexFormat.short4Normalized)
    precondition(MTLVertexFormat.half2.rawValue == 25)
    precondition(MTLVertexFormat(rawValue: 25) == MTLVertexFormat.half2)
    precondition(MTLVertexFormat.half3.rawValue == 26)
    precondition(MTLVertexFormat(rawValue: 26) == MTLVertexFormat.half3)
    precondition(MTLVertexFormat.half4.rawValue == 27)
    precondition(MTLVertexFormat(rawValue: 27) == MTLVertexFormat.half4)
    precondition(MTLVertexFormat.float.rawValue == 28)
    precondition(MTLVertexFormat(rawValue: 28) == MTLVertexFormat.float)
    precondition(MTLVertexFormat.float2.rawValue == 29)
    precondition(MTLVertexFormat(rawValue: 29) == MTLVertexFormat.float2)
    precondition(MTLVertexFormat.float3.rawValue == 30)
    precondition(MTLVertexFormat(rawValue: 30) == MTLVertexFormat.float3)
    precondition(MTLVertexFormat.float4.rawValue == 31)
    precondition(MTLVertexFormat(rawValue: 31) == MTLVertexFormat.float4)
    precondition(MTLVertexFormat.int.rawValue == 32)
    precondition(MTLVertexFormat(rawValue: 32) == MTLVertexFormat.int)
    precondition(MTLVertexFormat.int2.rawValue == 33)
    precondition(MTLVertexFormat(rawValue: 33) == MTLVertexFormat.int2)
    precondition(MTLVertexFormat.int3.rawValue == 34)
    precondition(MTLVertexFormat(rawValue: 34) == MTLVertexFormat.int3)
    precondition(MTLVertexFormat.int4.rawValue == 35)
    precondition(MTLVertexFormat(rawValue: 35) == MTLVertexFormat.int4)
    precondition(MTLVertexFormat.uint.rawValue == 36)
    precondition(MTLVertexFormat(rawValue: 36) == MTLVertexFormat.uint)
    precondition(MTLVertexFormat.uint2.rawValue == 37)
    precondition(MTLVertexFormat(rawValue: 37) == MTLVertexFormat.uint2)
    precondition(MTLVertexFormat.uint3.rawValue == 38)
    precondition(MTLVertexFormat(rawValue: 38) == MTLVertexFormat.uint3)
    precondition(MTLVertexFormat.uint4.rawValue == 39)
    precondition(MTLVertexFormat(rawValue: 39) == MTLVertexFormat.uint4)
    precondition(MTLVertexFormat.int1010102Normalized.rawValue == 40)
    precondition(MTLVertexFormat(rawValue: 40) == MTLVertexFormat.int1010102Normalized)
    precondition(MTLVertexFormat.uint1010102Normalized.rawValue == 41)
    precondition(MTLVertexFormat(rawValue: 41) == MTLVertexFormat.uint1010102Normalized)
    precondition(MTLVertexFormat.uchar4Normalized_bgra.rawValue == 42)
    precondition(MTLVertexFormat(rawValue: 42) == MTLVertexFormat.uchar4Normalized_bgra)
    precondition(MTLVertexFormat.uchar.rawValue == 45)
    precondition(MTLVertexFormat(rawValue: 45) == MTLVertexFormat.uchar)
    precondition(MTLVertexFormat.char.rawValue == 46)
    precondition(MTLVertexFormat(rawValue: 46) == MTLVertexFormat.char)
    precondition(MTLVertexFormat.ucharNormalized.rawValue == 47)
    precondition(MTLVertexFormat(rawValue: 47) == MTLVertexFormat.ucharNormalized)
    precondition(MTLVertexFormat.charNormalized.rawValue == 48)
    precondition(MTLVertexFormat(rawValue: 48) == MTLVertexFormat.charNormalized)
    precondition(MTLVertexFormat.ushort.rawValue == 49)
    precondition(MTLVertexFormat(rawValue: 49) == MTLVertexFormat.ushort)
    precondition(MTLVertexFormat.short.rawValue == 50)
    precondition(MTLVertexFormat(rawValue: 50) == MTLVertexFormat.short)
    precondition(MTLVertexFormat.ushortNormalized.rawValue == 51)
    precondition(MTLVertexFormat(rawValue: 51) == MTLVertexFormat.ushortNormalized)
    precondition(MTLVertexFormat.shortNormalized.rawValue == 52)
    precondition(MTLVertexFormat(rawValue: 52) == MTLVertexFormat.shortNormalized)
    precondition(MTLVertexFormat.half.rawValue == 53)
    precondition(MTLVertexFormat(rawValue: 53) == MTLVertexFormat.half)
    precondition(MTLVertexFormat.floatRG11B10.rawValue == 54)
    precondition(MTLVertexFormat(rawValue: 54) == MTLVertexFormat.floatRG11B10)
    precondition(MTLVertexFormat.floatRGB9E5.rawValue == 55)
    precondition(MTLVertexFormat(rawValue: 55) == MTLVertexFormat.floatRGB9E5)
    precondition(MTLVertexFormat.invalid != MTLVertexFormat.uchar2)
    var MTLVertexFormatSet: Set<MTLVertexFormat> = [.invalid]
    MTLVertexFormatSet.insert(.uchar2)
    precondition(MTLVertexFormatSet.count == 2)

    _ = MTLVertexStepFunction.constant
    precondition(MTLVertexStepFunction.constant.rawValue == 0)
    precondition(MTLVertexStepFunction(rawValue: 0) == MTLVertexStepFunction.constant)
    precondition(MTLVertexStepFunction.perVertex.rawValue == 1)
    precondition(MTLVertexStepFunction(rawValue: 1) == MTLVertexStepFunction.perVertex)
    precondition(MTLVertexStepFunction.perInstance.rawValue == 2)
    precondition(MTLVertexStepFunction(rawValue: 2) == MTLVertexStepFunction.perInstance)
    precondition(MTLVertexStepFunction.perPatch.rawValue == 3)
    precondition(MTLVertexStepFunction(rawValue: 3) == MTLVertexStepFunction.perPatch)
    precondition(MTLVertexStepFunction.perPatchControlPoint.rawValue == 4)
    precondition(MTLVertexStepFunction(rawValue: 4) == MTLVertexStepFunction.perPatchControlPoint)
    precondition(MTLVertexStepFunction.constant != MTLVertexStepFunction.perVertex)
    var MTLVertexStepFunctionSet: Set<MTLVertexStepFunction> = [.constant]
    MTLVertexStepFunctionSet.insert(.perVertex)
    precondition(MTLVertexStepFunctionSet.count == 2)

    _ = MTLVisibilityResultMode.disabled
    precondition(MTLVisibilityResultMode.disabled.rawValue == 0)
    precondition(MTLVisibilityResultMode(rawValue: 0) == MTLVisibilityResultMode.disabled)
    precondition(MTLVisibilityResultMode.boolean.rawValue == 1)
    precondition(MTLVisibilityResultMode(rawValue: 1) == MTLVisibilityResultMode.boolean)
    precondition(MTLVisibilityResultMode.counting.rawValue == 2)
    precondition(MTLVisibilityResultMode(rawValue: 2) == MTLVisibilityResultMode.counting)
    precondition(MTLVisibilityResultMode.disabled != MTLVisibilityResultMode.boolean)
    var MTLVisibilityResultModeSet: Set<MTLVisibilityResultMode> = [.disabled]
    MTLVisibilityResultModeSet.insert(.boolean)
    precondition(MTLVisibilityResultModeSet.count == 2)

    _ = MTLVisibilityResultType.reset
    precondition(MTLVisibilityResultType.reset.rawValue == 0)
    precondition(MTLVisibilityResultType(rawValue: 0) == MTLVisibilityResultType.reset)
    precondition(MTLVisibilityResultType.accumulate.rawValue == 1)
    precondition(MTLVisibilityResultType(rawValue: 1) == MTLVisibilityResultType.accumulate)
    precondition(MTLVisibilityResultType.reset != MTLVisibilityResultType.accumulate)
    var MTLVisibilityResultTypeSet: Set<MTLVisibilityResultType> = [.reset]
    MTLVisibilityResultTypeSet.insert(.accumulate)
    precondition(MTLVisibilityResultTypeSet.count == 2)

    _ = MTLWinding.clockwise
    precondition(MTLWinding.clockwise.rawValue == 0)
    precondition(MTLWinding(rawValue: 0) == MTLWinding.clockwise)
    precondition(MTLWinding.counterClockwise.rawValue == 1)
    precondition(MTLWinding(rawValue: 1) == MTLWinding.counterClockwise)
    precondition(MTLWinding.clockwise != MTLWinding.counterClockwise)
    var MTLWindingSet: Set<MTLWinding> = [.clockwise]
    MTLWindingSet.insert(.counterClockwise)
    precondition(MTLWindingSet.count == 2)

    var MTLBarrierScopeValue = MTLBarrierScope.buffers
    precondition(MTLBarrierScopeValue.contains(.buffers))
    MTLBarrierScopeValue.formUnion(.textures)
    precondition(MTLBarrierScopeValue.contains(.textures))
    _ = MTLBarrierScope.buffers
    _ = MTLBarrierScope.textures
    _ = MTLBarrierScope(rawValue: MTLBarrierScopeValue.rawValue)

    var MTLBlitOptionValue = MTLBlitOption.depthFromDepthStencil
    precondition(MTLBlitOptionValue.contains(.depthFromDepthStencil))
    MTLBlitOptionValue.formUnion(.stencilFromDepthStencil)
    precondition(MTLBlitOptionValue.contains(.stencilFromDepthStencil))
    _ = MTLBlitOption.depthFromDepthStencil
    _ = MTLBlitOption.stencilFromDepthStencil
    _ = MTLBlitOption.rowLinearPVRTC
    _ = MTLBlitOption(rawValue: MTLBlitOptionValue.rawValue)

    var MTLColorWriteMaskValue = MTLColorWriteMask.red
    precondition(MTLColorWriteMaskValue.contains(.red))
    MTLColorWriteMaskValue.formUnion(.green)
    precondition(MTLColorWriteMaskValue.contains(.green))
    _ = MTLColorWriteMask.red
    _ = MTLColorWriteMask.green
    _ = MTLColorWriteMask.blue
    _ = MTLColorWriteMask.alpha
    _ = MTLColorWriteMask.all
    _ = MTLColorWriteMask(rawValue: MTLColorWriteMaskValue.rawValue)

    let MTLCommandBufferErrorOptionValue = MTLCommandBufferErrorOption.encoderExecutionStatus
    precondition(MTLCommandBufferErrorOptionValue.contains(.encoderExecutionStatus))
    _ = MTLCommandBufferErrorOption.encoderExecutionStatus
    _ = MTLCommandBufferErrorOption(rawValue: MTLCommandBufferErrorOptionValue.rawValue)

    var MTLFunctionOptionsValue = MTLFunctionOptions.compileToBinary
    precondition(MTLFunctionOptionsValue.contains(.compileToBinary))
    MTLFunctionOptionsValue.formUnion(.storeFunctionInMetalPipelinesScript)
    precondition(MTLFunctionOptionsValue.contains(.storeFunctionInMetalPipelinesScript))
    _ = MTLFunctionOptions.compileToBinary
    _ = MTLFunctionOptions.storeFunctionInMetalPipelinesScript
    _ = MTLFunctionOptions.storeFunctionInMetalScript
    _ = MTLFunctionOptions.failOnBinaryArchiveMiss
    _ = MTLFunctionOptions.pipelineIndependent
    _ = MTLFunctionOptions(rawValue: MTLFunctionOptionsValue.rawValue)

    var MTLIndirectCommandTypeValue = MTLIndirectCommandType.draw
    precondition(MTLIndirectCommandTypeValue.contains(.draw))
    MTLIndirectCommandTypeValue.formUnion(.drawIndexed)
    precondition(MTLIndirectCommandTypeValue.contains(.drawIndexed))
    _ = MTLIndirectCommandType.draw
    _ = MTLIndirectCommandType.drawIndexed
    _ = MTLIndirectCommandType.drawPatches
    _ = MTLIndirectCommandType.drawIndexedPatches
    _ = MTLIndirectCommandType.concurrentDispatch
    _ = MTLIndirectCommandType.concurrentDispatchThreads
    _ = MTLIndirectCommandType.drawMeshThreadgroups
    _ = MTLIndirectCommandType.drawMeshThreads
    _ = MTLIndirectCommandType(rawValue: MTLIndirectCommandTypeValue.rawValue)

    var MTLPipelineOptionValue = MTLPipelineOption.argumentInfo
    precondition(MTLPipelineOptionValue.contains(.argumentInfo))
    MTLPipelineOptionValue.formUnion(.bindingInfo)
    precondition(MTLPipelineOptionValue.contains(.bindingInfo))
    _ = MTLPipelineOption.argumentInfo
    _ = MTLPipelineOption.bindingInfo
    _ = MTLPipelineOption.bufferTypeInfo
    _ = MTLPipelineOption.failOnBinaryArchiveMiss
    _ = MTLPipelineOption(rawValue: MTLPipelineOptionValue.rawValue)

    var MTLRenderStagesValue = MTLRenderStages.vertex
    precondition(MTLRenderStagesValue.contains(.vertex))
    MTLRenderStagesValue.formUnion(.fragment)
    precondition(MTLRenderStagesValue.contains(.fragment))
    _ = MTLRenderStages.vertex
    _ = MTLRenderStages.fragment
    _ = MTLRenderStages.tile
    _ = MTLRenderStages.object
    _ = MTLRenderStages.mesh
    _ = MTLRenderStages(rawValue: MTLRenderStagesValue.rawValue)

    var MTLResourceOptionsValue = MTLResourceOptions.cpuCacheModeWriteCombined
    precondition(MTLResourceOptionsValue.contains(.cpuCacheModeWriteCombined))
    MTLResourceOptionsValue.formUnion(.optionCPUCacheModeWriteCombined)
    precondition(MTLResourceOptionsValue.contains(.optionCPUCacheModeWriteCombined))
    _ = MTLResourceOptions.cpuCacheModeWriteCombined
    _ = MTLResourceOptions.optionCPUCacheModeWriteCombined
    _ = MTLResourceOptions.cpuCacheModeDefaultCache
    _ = MTLResourceOptions.storageModeShared
    _ = MTLResourceOptions.storageModePrivate
    _ = MTLResourceOptions.storageModeMemoryless
    _ = MTLResourceOptions.hazardTrackingModeUntracked
    _ = MTLResourceOptions.hazardTrackingModeTracked
    _ = MTLResourceOptions(rawValue: MTLResourceOptionsValue.rawValue)

    var MTLResourceUsageValue = MTLResourceUsage.read
    precondition(MTLResourceUsageValue.contains(.read))
    MTLResourceUsageValue.formUnion(.write)
    precondition(MTLResourceUsageValue.contains(.write))
    _ = MTLResourceUsage.read
    _ = MTLResourceUsage.write
    _ = MTLResourceUsage.sample
    _ = MTLResourceUsage(rawValue: MTLResourceUsageValue.rawValue)

    var MTLStagesValue = MTLStages.vertex
    precondition(MTLStagesValue.contains(.vertex))
    MTLStagesValue.formUnion(.fragment)
    precondition(MTLStagesValue.contains(.fragment))
    _ = MTLStages.vertex
    _ = MTLStages.fragment
    _ = MTLStages.tile
    _ = MTLStages.object
    _ = MTLStages.mesh
    _ = MTLStages.dispatch
    _ = MTLStages.blit
    _ = MTLStages.accelerationStructure
    _ = MTLStages.machineLearning
    _ = MTLStages.resourceState
    _ = MTLStages.all
    _ = MTLStages(rawValue: MTLStagesValue.rawValue)

    let MTLStoreActionOptionsValue = MTLStoreActionOptions.customSamplePositions
    precondition(MTLStoreActionOptionsValue.contains(.customSamplePositions))
    _ = MTLStoreActionOptions.customSamplePositions
    _ = MTLStoreActionOptions(rawValue: MTLStoreActionOptionsValue.rawValue)

    var MTLTextureUsageValue = MTLTextureUsage.unknown
    precondition(MTLTextureUsageValue.contains(.unknown))
    MTLTextureUsageValue.formUnion(.shaderRead)
    precondition(MTLTextureUsageValue.contains(.shaderRead))
    _ = MTLTextureUsage.unknown
    _ = MTLTextureUsage.shaderRead
    _ = MTLTextureUsage.shaderWrite
    _ = MTLTextureUsage.renderTarget
    _ = MTLTextureUsage.pixelFormatView
    _ = MTLTextureUsage.shaderAtomic
    _ = MTLTextureUsage(rawValue: MTLTextureUsageValue.rawValue)

    _ = MTLCommandBufferErrorDomain
    _ = MTLLibraryErrorDomain
    _ = MTLCaptureErrorDomain
    _ = MTLBinaryArchiveDomain
    _ = MTLCounterErrorDomain
    _ = MTLDynamicLibraryDomain
    _ = MTLIOErrorDomain
    _ = MTLLogStateErrorDomain
    _ = MTLTensorDomain
    _ = MTL4CommandQueueErrorDomain
    _ = MTLCommandBufferEncoderInfoErrorKey
    _ = MTLAttributeStrideStatic
    _ = MTLBufferLayoutStrideDynamic
    _ = MTLCounterDontSample
    _ = MTLCounterErrorValue
    _ = MTL_TENSOR_MAX_RANK
    _ = MTLResourceCPUCacheModeShift
    _ = MTLResourceCPUCacheModeMask
    _ = MTLResourceStorageModeShift
    _ = MTLResourceStorageModeMask
    _ = MTLResourceHazardTrackingModeShift
    _ = MTLResourceHazardTrackingModeMask
    precondition(MTLLibraryErrorDomain == "MTLLibraryErrorDomain")
    precondition(MTLCommandBufferErrorDomain == "MTLCommandBufferErrorDomain")
    precondition(MTLCaptureErrorDomain == "MTLCaptureErrorDomain")
    precondition(MTLCounterDontSample == -1)
    precondition(MTLResourceCPUCacheModeShift == 0)
    precondition(MTLResourceStorageModeShift == 4)
    precondition(MTLResourceHazardTrackingModeShift == 8)
    precondition(MTLIOError.urlInvalid.rawValue == 1)
    precondition(MTLCommandBufferError.accessRevoked == .blacklisted)
    metalExerciseOptionSet(MTLAccelerationStructureInstanceOptions.opaque, .nonOpaque)
    metalExerciseOptionSet(MTLAccelerationStructureUsage.refit, .preferFastBuild)
    metalExerciseOptionSet(MTLAccelerationStructureRefitOptions.vertexData, .perPrimitiveData)
    metalExerciseOptionSet(MTLIntersectionFunctionSignature.instancing, .triangleData)
    metalExerciseOptionSet(MTL4BinaryFunctionOptions.pipelineIndependent, .pipelineIndependent)
    metalExerciseOptionSet(MTL4RenderEncoderOptions.suspending, .resuming)
    metalExerciseOptionSet(MTL4ShaderReflection.bindingInfo, .bufferTypeInfo)
    metalExerciseOptionSet(MTL4VisibilityOptions.device, .resourceAlias)
    metalExerciseOptionSet(MTL4PipelineDataSetSerializerConfiguration.captureDescriptors, .captureBinaries)
    metalExerciseOptionSet(MTLStitchedLibraryOptions.failOnBinaryArchiveMiss, .storeLibraryInMetalPipelinesScript)
    metalExerciseOptionSet(MTLTensorUsage.compute, .render)
    let accelLiteral: MTLAccelerationStructureInstanceOptions = [.opaque, .disableTriangleCulling]
    precondition(accelLiteral.contains(.opaque))
    let usageLiteral: MTLAccelerationStructureUsage = [.refit, .preferFastBuild]
    precondition(usageLiteral.contains(.refit))
    let signatureLiteral: MTLIntersectionFunctionSignature = [.instancing, .triangleData]
    precondition(signatureLiteral.contains(.instancing))
    let metal4Literal: MTL4RenderEncoderOptions = [.suspending, .resuming]
    precondition(metal4Literal.contains(.suspending))
    precondition(MTLAccelerationStructureInstanceOptions.disableTriangleCulling.rawValue == 1)
    precondition(MTLAccelerationStructureInstanceOptions.triangleFrontFacingWindingCounterClockwise.rawValue == 2)
    precondition(MTLAccelerationStructureInstanceOptions.opaque.rawValue == 4)
    precondition(MTLAccelerationStructureInstanceOptions.nonOpaque.rawValue == 8)
    precondition(MTLAccelerationStructureUsage.extendedLimits.rawValue == 4)
    precondition(MTLAccelerationStructureUsage.preferFastIntersection.rawValue == 8)
    precondition(MTLAccelerationStructureUsage.minimizeMemory.rawValue == 16)
    precondition(MTLIntersectionFunctionSignature.worldSpaceData.rawValue == 4)
    precondition(MTLIntersectionFunctionSignature.instanceMotion.rawValue == 8)
    precondition(MTLIntersectionFunctionSignature.primitiveMotion.rawValue == 16)
    precondition(MTLIntersectionFunctionSignature.extendedLimits.rawValue == 32)
    precondition(MTLIntersectionFunctionSignature.maxLevels.rawValue == 64)
    precondition(MTLIntersectionFunctionSignature.curveData.rawValue == 128)
    precondition(MTLIntersectionFunctionSignature.intersectionFunctionBuffer.rawValue == 256)
    precondition(MTLIntersectionFunctionSignature.userData.rawValue == 256 << 1)
    precondition(MTLMutability.default.rawValue == 0)
    precondition(MTLMutability(rawValue: 0) == MTLMutability.default)
    precondition(MTLMutability.mutable.rawValue == 1)
    precondition(MTLMutability(rawValue: 1) == MTLMutability.mutable)
    precondition(MTLMutability.immutable.rawValue == 2)
    precondition(MTLMutability(rawValue: 2) == MTLMutability.immutable)
    precondition(MTLMutability.default != MTLMutability.mutable)
    var MTLMutabilitySet: Set<MTLMutability> = [.default]
    MTLMutabilitySet.insert(.mutable)
    precondition(MTLMutabilitySet.count == 2)
    precondition(MTLMotionBorderMode.clamp.rawValue == 0)
    precondition(MTLMotionBorderMode(rawValue: 0) == MTLMotionBorderMode.clamp)
    precondition(MTLMotionBorderMode.vanish.rawValue == 1)
    precondition(MTLMotionBorderMode(rawValue: 1) == MTLMotionBorderMode.vanish)
    precondition(MTLMotionBorderMode.clamp != MTLMotionBorderMode.vanish)
    var MTLMotionBorderModeSet: Set<MTLMotionBorderMode> = [.clamp]
    MTLMotionBorderModeSet.insert(.vanish)
    precondition(MTLMotionBorderModeSet.count == 2)

    metalExerciseRawEnum([
        MTL4AlphaToCoverageState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4AlphaToOneState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4BlendState.disabled, .enabled, .unspecialized
    ])
    metalExerciseRawEnum([
        MTL4IndirectCommandBufferSupportState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4LogicalToPhysicalColorAttachmentMappingState.identity, .inherited
    ])
    metalExerciseRawEnum([
        MTL4CompilerTaskStatus.none, .scheduled, .compiling, .finished
    ])
    metalExerciseRawEnum([
        MTL4TimestampGranularity.relaxed, .precise
    ])
    metalExerciseRawEnum([
        MTL4CounterHeapType.invalid, .timestamp
    ])
    metalExerciseRawEnum([
        MTLCurveType.round, .flat
    ])
    metalExerciseRawEnum([
        MTLCurveBasis.bSpline, .linear, .bezier, .catmullRom
    ])
    metalExerciseRawEnum([
        MTLCurveEndCaps.none, .disk, .sphere
    ])
    metalExerciseRawEnum([
        MTLIOPriority.high, .normal, .low
    ])
    metalExerciseRawEnum([
        MTLIOStatus.pending, .cancelled, .error, .complete
    ])
    metalExerciseRawEnum([
        MTLIOCompressionMethod.zlib, .lzfse, .lz4, .lzma, .lzBitmap
    ])
    metalExerciseRawEnum([
        MTLIOCommandQueueType.concurrent, .serial
    ])
    metalExerciseRawEnum([
        MTLMatrixLayout.columnMajor, .rowMajor
    ])
    metalExerciseRawEnum([
        MTLPrimitiveTopologyClass.unspecified, .point, .line, .triangle
    ])
    metalExerciseRawEnum([
        MTLTessellationControlPointIndexType.none, .uint16, .uint32
    ])
    metalExerciseRawEnum([
        MTLTessellationFactorFormat.half
    ])
    metalExerciseRawEnum([
        MTLTessellationFactorStepFunction.constant, .perPatch, .perInstance, .perPatchAndPerInstance
    ])
    metalExerciseRawEnum([
        MTLTessellationPartitionMode.pow2, .integer, .fractionalOdd, .fractionalEven
    ])
    metalExerciseRawEnum([
        MTLTransformType.packedFloat4x3, .component
    ])
    metalExerciseRawEnum([
        MTLAccelerationStructureInstanceDescriptorType.default, .userID, .motion, .indirect, .indirectMotion
    ])
    metalExerciseRawEnum([
        MTLSparseTextureRegionAlignmentMode.outward, .inward
    ])
    metalExerciseRawEnum([
        MTL4CommandQueueError.Code.none, .internal, .timeout, .notPermitted, .outOfMemory, .accessRevoked, .deviceRemoved
    ])
    precondition(MTL4CommandQueueError.none == .none)
    precondition(MTL4CommandQueueError.internal == .internal)
    precondition(MTL4CommandQueueError.timeout == .timeout)
    precondition(MTL4CommandQueueError.notPermitted == .notPermitted)
    precondition(MTL4CommandQueueError.outOfMemory == .outOfMemory)
    precondition(MTL4CommandQueueError.accessRevoked == .accessRevoked)
    precondition(MTL4CommandQueueError.deviceRemoved == .deviceRemoved)
    precondition(MTL4CommandQueueError.errorDomain == MTL4CommandQueueErrorDomain)
    let queueError = MTL4CommandQueueError(.notPermitted, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(queueError.code == .notPermitted)
    precondition(queueError.errorCode == MTL4CommandQueueError.Code.notPermitted.rawValue)
    _ = queueError.errorUserInfo
    _ = queueError.hashValue
    var hasher = Hasher()
    queueError.hash(into: &hasher)
    precondition(MTL4CommandQueueError.notPermitted ~= queueError)
    precondition(queueError != MTL4CommandQueueError(.none))

    let timestamp = MTLCommonCounter.timestamp
    precondition(timestamp.rawValue == "Timestamp")
    precondition(MTLCommonCounter(rawValue: "Timestamp") == timestamp)
    precondition(MTLCommonCounter.clipperInvocations != MTLCommonCounter.clipperPrimitivesOut)
    precondition(MTLCommonCounter.computeKernelInvocations.rawValue == "ComputeKernelInvocations")
    precondition(MTLCommonCounter.fragmentCycles.rawValue == "FragmentCycles")
    precondition(MTLCommonCounter.fragmentInvocations.rawValue == "FragmentInvocations")
    precondition(MTLCommonCounter.fragmentsPassed.rawValue == "FragmentsPassed")
    precondition(MTLCommonCounter.postTessellationVertexCycles.rawValue == "PostTessellationVertexCycles")
    precondition(MTLCommonCounter.postTessellationVertexInvocations.rawValue == "PostTessellationVertexInvocations")
    precondition(MTLCommonCounter.renderTargetWriteCycles.rawValue == "RenderTargetWriteCycles")
    precondition(MTLCommonCounter.tessellationCycles.rawValue == "TessellationCycles")
    precondition(MTLCommonCounter.tessellationInputPatches.rawValue == "TessellationInputPatches")
    precondition(MTLCommonCounter.totalCycles.rawValue == "TotalCycles")
    precondition(MTLCommonCounter.vertexCycles.rawValue == "VertexCycles")
    precondition(MTLCommonCounter.vertexInvocations.rawValue == "VertexInvocations")
    var counterSet: Set<MTLCommonCounter> = [.timestamp]
    counterSet.insert(.totalCycles)
    precondition(counterSet.count == 2)
    _ = timestamp.hashValue
    var counterHasher = Hasher()
    timestamp.hash(into: &counterHasher)

    precondition(MTLCommonCounterSet.timestamp.rawValue == "timestamp")
    precondition(MTLCommonCounterSet.stageUtilization.rawValue == "stageUtilization")
    precondition(MTLCommonCounterSet.statistic.rawValue == "statistic")
    precondition(MTLCommonCounterSet(rawValue: "timestamp") == .timestamp)
    precondition(MTLCommonCounterSet.timestamp != MTLCommonCounterSet.statistic)
    var namedSets: Set<MTLCommonCounterSet> = [.timestamp]
    namedSets.insert(.statistic)
    precondition(namedSets.count == 2)
    _ = MTLCommonCounterSet.stageUtilization.hashValue
    var setHasher = Hasher()
    MTLCommonCounterSet.stageUtilization.hash(into: &setHasher)

    var ts = MTLCounterResultTimestamp()
    ts.timestamp = 42
    precondition(ts.timestamp == 42)
    var stage = MTLCounterResultStageUtilization()
    stage.totalCycles = 1
    stage.vertexCycles = 2
    stage.tessellationCycles = 3
    stage.postTessellationVertexCycles = 4
    stage.fragmentCycles = 5
    stage.renderTargetCycles = 6
    precondition(stage.totalCycles == 1)
    precondition(stage.vertexCycles == 2)
    precondition(stage.tessellationCycles == 3)
    precondition(stage.postTessellationVertexCycles == 4)
    precondition(stage.fragmentCycles == 5)
    precondition(stage.renderTargetCycles == 6)
    var stat = MTLCounterResultStatistic()
    stat.clipperInvocations = 1
    stat.clipperPrimitivesOut = 2
    stat.computeKernelInvocations = 3
    stat.fragmentInvocations = 4
    stat.fragmentsPassed = 5
    stat.postTessellationVertexInvocations = 6
    stat.tessellationInputPatches = 7
    stat.vertexInvocations = 8
    precondition(stat.clipperInvocations == 1)
    precondition(stat.vertexInvocations == 8)

    metalExerciseRawEnum([
        MTLTensorDataType.none, .float32, .float16, .bfloat16, .int8, .uint8, .int16, .uint16, .int32, .uint32
    ])
    metalExerciseRawEnum([
        MTLStepFunction.constant, .perVertex, .perInstance, .perPatch, .perPatchControlPoint,
        .threadPositionInGridX, .threadPositionInGridY, .threadPositionInGridXIndexed, .threadPositionInGridYIndexed
    ])
    metalExerciseRawEnum([
        MTLLogLevel.undefined, .debug, .info, .notice, .error, .fault
    ])
    metalExerciseRawEnum([
        MTLCommandEncoderErrorState.unknown, .completed, .affected, .pending, .faulted
    ])
    metalExerciseRawEnum([
        MTLFunctionLogType.validation
    ])
    metalExerciseRawEnum([
        MTLIOCompressionStatus.complete, .error
    ])
    metalExerciseRawEnum([
        MTLLogStateError.invalid, .invalidSize
    ])
    metalExerciseRawEnum([
        MTLDynamicLibraryError.Code.none, .invalidFile, .compilationFailure, .unresolvedInstallName,
        .dependencyLoadFailure, .unsupported
    ])
    precondition(MTLDynamicLibraryError.none == .none)
    precondition(MTLDynamicLibraryError.invalidFile == .invalidFile)
    precondition(MTLDynamicLibraryError.compilationFailure == .compilationFailure)
    precondition(MTLDynamicLibraryError.unresolvedInstallName == .unresolvedInstallName)
    precondition(MTLDynamicLibraryError.dependencyLoadFailure == .dependencyLoadFailure)
    precondition(MTLDynamicLibraryError.unsupported == .unsupported)
    precondition(MTLDynamicLibraryError.errorDomain == MTLDynamicLibraryDomain)
    let dynError = MTLDynamicLibraryError(.unsupported, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(dynError.code == .unsupported)
    precondition(dynError.errorCode == Int(MTLDynamicLibraryError.Code.unsupported.rawValue))
    _ = dynError.errorUserInfo
    _ = dynError.hashValue
    _ = dynError.localizedDescription
    var dynHasher = Hasher()
    dynError.hash(into: &dynHasher)
    precondition(MTLDynamicLibraryError.unsupported ~= dynError)
    precondition(dynError != MTLDynamicLibraryError(.none))

    metalExerciseRawEnum([
        MTLBinaryArchiveError.Code.none, .invalidFile, .unexpectedElement, .compilationFailure, .internalError
    ])
    precondition(MTLBinaryArchiveError.none == .none)
    precondition(MTLBinaryArchiveError.invalidFile == .invalidFile)
    precondition(MTLBinaryArchiveError.unexpectedElement == .unexpectedElement)
    precondition(MTLBinaryArchiveError.compilationFailure == .compilationFailure)
    precondition(MTLBinaryArchiveError.internalError == .internalError)
    precondition(MTLBinaryArchiveError.errorDomain == MTLBinaryArchiveDomain)
    let binError = MTLBinaryArchiveError(.internalError, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(binError.code == .internalError)
    precondition(MTLBinaryArchiveError.internalError ~= binError)
    _ = binError.errorUserInfo
    _ = binError.hashValue
    _ = binError.localizedDescription

    metalExerciseRawEnum([
        MTLCounterSampleBufferError.Code.outOfMemory, .invalid, .internal
    ])
    precondition(MTLCounterSampleBufferError.outOfMemory == .outOfMemory)
    precondition(MTLCounterSampleBufferError.invalid == .invalid)
    precondition(MTLCounterSampleBufferError.internal == .internal)
    precondition(MTLCounterSampleBufferError.errorDomain == MTLCounterErrorDomain)
    let counterError = MTLCounterSampleBufferError(.invalid, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(counterError.code == .invalid)
    precondition(MTLCounterSampleBufferError.invalid ~= counterError)
    _ = counterError.hashValue
    _ = counterError.localizedDescription

    metalExerciseRawEnum([
        MTLTensorError.Code.none, .internalError, .invalidDescriptor
    ])
    precondition(MTLTensorError.none == .none)
    precondition(MTLTensorError.internalError == .internalError)
    precondition(MTLTensorError.invalidDescriptor == .invalidDescriptor)
    precondition(MTLTensorError.errorDomain == MTLTensorDomain)
    let tensorError = MTLTensorError(.invalidDescriptor, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(tensorError.code == .invalidDescriptor)
    precondition(MTLTensorError.invalidDescriptor ~= tensorError)
    _ = tensorError.hashValue
    _ = tensorError.localizedDescription

    precondition(MTLCommandBufferError.none == .none)
    precondition(MTLCommandBufferError.internal == .internal)
    precondition(MTLCommandBufferError.timeout == .timeout)
    precondition(MTLCommandBufferError.pageFault == .pageFault)
    precondition(MTLCommandBufferError.blacklisted == .blacklisted)
    precondition(MTLCommandBufferError.notPermitted == .notPermitted)
    precondition(MTLCommandBufferError.outOfMemory == .outOfMemory)
    precondition(MTLCommandBufferError.invalidResource == .invalidResource)
    precondition(MTLCommandBufferError.memoryless == .memoryless)
    precondition(MTLCommandBufferError.stackOverflow == .stackOverflow)
    _ = MTLCommandBufferError.errorDomain
    let ioThrown = MTLIOError(.internal, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(ioThrown == MTLIOError(.internal))
    precondition(ioThrown != MTLIOError(.urlInvalid))
    _ = ioThrown.hashValue
    _ = ioThrown.localizedDescription
    precondition(MTLIOError.internal ~= ioThrown)
}

private func metalExerciseOptionSet<T: OptionSet & Hashable>(_ first: T, _ second: T)
where T.RawValue: FixedWidthInteger, T.Element == T {
    let empty = T()
    precondition(empty.isEmpty)
    var value = first
    precondition(value.contains(first))
    let inserted = value.insert(second)
    _ = inserted
    value.formUnion(second)
    precondition(value.contains(first))
    let unioned = first.union(second)
    precondition(unioned.contains(first))
    let combined = first.union(second)
    let inter = combined.intersection(first)
    precondition(inter.contains(first))
    var form = combined
    form.formIntersection(first)
    var symmetric = first
    symmetric.formSymmetricDifference(second)
    _ = first.symmetricDifference(second)
    _ = first.subtracting(second)
    var subtract = combined
    subtract.subtract(second)
    precondition(first.isSubset(of: combined))
    precondition(combined.isSuperset(of: first))
    _ = first.isStrictSubset(of: combined)
    _ = combined.isStrictSuperset(of: first)
    _ = first.isDisjoint(with: second) || first == second
    _ = value.remove(second)
    _ = value.update(with: first)
    precondition(first != second || first == second)
    var set = Set<T>()
    set.insert(first)
    set.insert(second)
    _ = value.hashValue
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
    _ = T(rawValue: first.rawValue)
}

private func metalExerciseRawEnum<T: RawRepresentable & Hashable>(_ values: [T])
where T.RawValue: Equatable {
    precondition(!values.isEmpty)
    for value in values {
        precondition(T(rawValue: value.rawValue) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    if values.count >= 2 {
        precondition(values[0] != values[1])
        var set = Set<T>()
        set.insert(values[0])
        set.insert(values[1])
        precondition(set.count == 2)
    }
}

// from MetalFailClosedTests.swift
func testLibraryFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    do {
        _ = try device.makeLibrary(source: "kernel void k() {}", options: nil)
        fatalError("shader compilation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        precondition(error.errorCode == Int(MTLLibraryError.Code.compileFailure.rawValue))
        precondition(MTLLibraryError.errorDomain == MTLLibraryErrorDomain)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
        precondition(MTLLibraryError.compileFailure ~= error)
        _ = error.errorUserInfo
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        let copy = MTLLibraryError(.compileFailure, userInfo: error.userInfo)
        precondition(copy == error)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeLibrary(URL: URL(fileURLWithPath: "/tmp/missing.metallib"))
        fatalError("metallib loading must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
        precondition(MTLLibraryError.fileNotFound ~= error)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeLibrary(filepath: "/tmp/missing.metallib")
        fatalError("filepath library load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeDefaultLibrary(bundle: Bundle.main)
        fatalError("default library bundle load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    _ = MTLLibraryError.unsupported
    _ = MTLLibraryError.internal
    _ = MTLLibraryError.compileWarning
    _ = MTLLibraryError.functionNotFound
}

func testCaptureFailClosed() {
    let capture = MTLCaptureManager.shared()
    precondition(!capture.supportsDestination(.developerTools))
    precondition(!capture.supportsDestination(.gpuTraceDocument))
    precondition(!capture.isCapturing)
    _ = capture.defaultCaptureScope
    do {
        try capture.startCapture(with: MTLCaptureDescriptor())
        fatalError("GPU capture must fail closed")
    } catch let error as MTLCaptureError {
        precondition(error == .notSupported)
        _ = MTLCaptureError.alreadyCapturing
        _ = MTLCaptureError.invalidDescriptor
    } catch {
        fatalError("expected MTLCaptureError")
    }
    let device = MTLCreateSystemDefaultDevice()!
    capture.startCapture(device: device)
    capture.startCapture(commandQueue: device.makeCommandQueue()!)
    let scope = capture.makeCaptureScope(device: device)
    scope.label = "scope"
    _ = scope.device
    _ = scope.commandQueue
    scope.begin()
    capture.startCapture(scope: scope)
    scope.end()
    _ = capture.makeCaptureScope(commandQueue: device.makeCommandQueue()!)
    capture.stopCapture()
    precondition(!capture.isCapturing)
}

func testArgumentEncoderAndICB() {
    let device = MTLCreateSystemDefaultDevice()!
    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.dataType = .float
    argument.index = 0
    let encoder = device.makeArgumentEncoder(arguments: [argument])!
    encoder.label = "args"
    precondition(encoder.label == "args")
    precondition(encoder.encodedLength == 16)
    precondition(encoder.alignment == 16)
    precondition(encoder.device.name == device.name)
    let buffer = device.makeBuffer(length: 16, options: [])!
    encoder.setArgumentBuffer(buffer, offset: 0)
    encoder.setArgumentBuffer(buffer, startOffset: 0, arrayElement: 0)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    encoder.setTexture(nil, index: 0)
    encoder.setSamplerState(nil, index: 0)
    encoder.setRenderPipelineState(nil, index: 0)
    encoder.setComputePipelineState(nil, index: 0)
    encoder.setIndirectCommandBuffer(nil, index: 0)
    encoder.setDepthStencilState(nil, index: 0)
    _ = encoder.constantData(at: 0)
    precondition(encoder.makeArgumentEncoderForBuffer(atIndex: 0) == nil)
    let payload = device.makeBuffer(length: encoder.encodedLength, options: [])!
    encoder.setArgumentBuffer(payload, offset: 0)
    let constant: Float = 2.5
    encoder.constantData(at: 0).storeBytes(of: constant, as: Float.self)
    precondition(payload.contents().load(as: Float.self) == 2.5)
    let pointed = device.makeBuffer(length: 8, options: [])!
    encoder.setBuffer(pointed, offset: 0, index: 0)
    precondition(payload.contents().load(as: UInt64.self) == pointed.gpuAddress)
    encoder.setArgumentBuffer(payload, startOffset: 0, arrayElement: 0)
    let icbDesc = MTLIndirectCommandBufferDescriptor()
    icbDesc.commandTypes = [.concurrentDispatch]
    let icb = device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: 4, options: [])!
    precondition(icb.size == 4)
    _ = icb.gpuResourceID
    precondition(icb.device.name == device.name)
    encoder.setIndirectCommandBuffer(icb, index: 0)
}

func testPipelineDescriptorValidation() {
    let device = MTLCreateSystemDefaultDevice()!
    let samples = MTLRenderPipelineDescriptor()
    samples.sampleCount = 0
    do {
        _ = try device.makeRenderPipelineState(descriptor: samples)
        fatalError("invalid sampleCount must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("sampleCount"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let blending = MTLRenderPipelineDescriptor()
    blending.colorAttachments[0].isBlendingEnabled = true
    blending.colorAttachments[0].pixelFormat = .invalid
    do {
        _ = try device.makeRenderPipelineState(descriptor: blending)
        fatalError("blending without a color format must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("blending"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let library = MTLMakeCPUBuiltinLibrary(device)
    let kernel = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let shaded = MTLRenderPipelineDescriptor()
    shaded.vertexFunction = kernel
    do {
        _ = try device.makeRenderPipelineState(descriptor: shaded)
        fatalError("MSL vertex functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let fragmentShaded = MTLRenderPipelineDescriptor()
    fragmentShaded.fragmentFunction = kernel
    do {
        _ = try device.makeRenderPipelineState(descriptor: fragmentShaded)
        fatalError("MSL fragment functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let compute = MTLComputePipelineDescriptor()
    do {
        _ = try device.makeComputePipelineState(descriptor: compute)
        fatalError("compute pipeline without a function must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("compute function"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let vertex = MTLVertexDescriptor()
    vertex.layouts[0].stride = 16
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.vertexDescriptor = vertex
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    _ = try! device.makeRenderPipelineState(descriptor: pipeline)
}

func testComputeDispatchFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    encoder.endEncoding()
    var completed = false
    commandBuffer.addCompletedHandler { buffer in
        completed = true
        precondition(buffer.status == .error)
        let error = buffer.error as? MTLCommandBufferError
        precondition(error?.code == .notPermitted)
        precondition(MTLCommandBufferError.notPermitted ~= buffer.error!)
        precondition(MTLCommandBufferError.errorDomain == MTLCommandBufferErrorDomain)
        _ = error?.errorCode
        _ = error?.errorUserInfo
        _ = error?.hashValue
    }
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(completed)
    precondition(commandBuffer.status == .error)
    precondition((commandBuffer.error as? MTLCommandBufferError)?.code == .notPermitted)
}

func testIOCommandBufferFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let queueDesc = MTLIOCommandQueueDescriptor()
    queueDesc.maxCommandBufferCount = 2
    queueDesc.maxCommandsInFlight = 1
    queueDesc.priority = .normal
    queueDesc.type = .serial
    queueDesc.scratchBufferAllocator = nil
    let queue = try! device.makeIOCommandQueue(descriptor: queueDesc)
    queue.label = "io"
    precondition(queue.label == "io")
    queue.enqueueBarrier()
    let empty = queue.makeCommandBuffer()
    empty.label = "empty"
    precondition(empty.status == .pending)
    var emptyCompleted = false
    empty.addCompletedHandler { buffer in
        emptyCompleted = true
        precondition(buffer.status == .complete)
        precondition(buffer.error == nil)
    }
    empty.addBarrier()
    empty.pushDebugGroup("g")
    empty.popDebugGroup()
    let event = device.makeSharedEvent()!
    empty.signalEvent(event, value: 1)
    empty.waitForEvent(event, value: 1)
    empty.enqueue()
    empty.commit()
    empty.waitUntilCompleted()
    precondition(emptyCompleted)
    precondition(empty.status == .complete)
    let statusBuffer = device.makeBuffer(length: 8, options: [])!
    empty.copyStatus(buffer: statusBuffer, offset: 0)
    precondition(statusBuffer.contents().load(as: UInt64.self) == UInt64(MTLIOStatus.complete.rawValue))

    let loaded = queue.makeCommandBufferWithUnretainedReferences()
    let handle = MetalTestIOFileHandle()
    handle.label = "file"
    precondition(handle.label == "file")
    loaded.load(device.makeBuffer(length: 4, options: [])!, offset: 0, size: 4, sourceHandle: handle, sourceHandleOffset: 0)
    var bytes: UInt8 = 0
    withUnsafeMutableBytes(of: &bytes) { raw in
        loaded.loadBytes(raw.baseAddress!, size: 1, sourceHandle: handle, sourceHandleOffset: 0)
    }
    let tex = device.makeTexture(descriptor: MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    ))!
    loaded.load(
        tex,
        slice: 0,
        level: 0,
        size: MTLSizeMake(1, 1, 1),
        sourceBytesPerRow: 1,
        sourceBytesPerImage: 1,
        destinationOrigin: MTLOrigin(),
        sourceHandle: handle,
        sourceHandleOffset: 0
    )
    var loadCompleted = false
    loaded.addCompletedHandler { buffer in
        loadCompleted = true
        precondition(buffer.status == .error)
        let error = buffer.error as? MTLIOError
        precondition(error?.code == .internal)
        precondition(MTLIOError.internal ~= buffer.error!)
    }
    loaded.commit()
    loaded.waitUntilCompleted()
    precondition(loadCompleted)
    precondition(loaded.status == .error)

    let cancelled = queue.makeCommandBuffer()
    cancelled.tryCancel()
    precondition(cancelled.status == .cancelled)
}

func testCPUTensorBinaryArchiveAndHandles() {
    let device = MTLCreateSystemDefaultDevice()!
    let invalid = MTLTensorDescriptor()
    invalid.dataType = .none
    do {
        _ = try device.makeTensor(descriptor: invalid)
        fatalError("empty tensor must fail closed")
    } catch let error as MTLTensorError {
        precondition(error.code == .invalidDescriptor)
        precondition(MTLTensorError.invalidDescriptor ~= error)
        precondition(error.localizedDescription.contains("tensor"))
    } catch {
        fatalError("expected MTLTensorError")
    }
    let descriptor = MTLTensorDescriptor()
    descriptor.dataType = .float32
    descriptor.dimensions = MTLTensorExtents([4])!
    descriptor.usage = [.compute]
    descriptor.storageMode = .shared
    descriptor.cpuCacheMode = .defaultCache
    descriptor.hazardTrackingMode = .default
    descriptor.resourceOptions = .storageModeShared
    descriptor.strides = MTLTensorExtents([1])
    let copy = descriptor.copy() as! MTLTensorDescriptor
    precondition(copy.dimensions.extents == [4])
    let sized = device.tensorSizeAndAlign(descriptor: descriptor)
    precondition(sized.size >= 16)
    precondition(sized.align == 16)
    let tensor = try! device.makeTensor(descriptor: descriptor)
    precondition(tensor.dataType == .float32)
    precondition(tensor.dimensions.extents == [4])
    precondition(tensor.usage.contains(.compute))
    precondition(tensor.buffer == nil)
    precondition(tensor.bufferOffset == 0)
    _ = tensor.gpuResourceID
    _ = tensor.strides
    let values: [Float] = [1, 2, 3, 4]
    values.withUnsafeBytes { raw in
        tensor.replace(
            sliceOrigin: MTLTensorExtents([0])!,
            sliceDimensions: MTLTensorExtents([4])!,
            withBytes: raw.baseAddress!,
            strides: MTLTensorExtents([1])!
        )
    }
    var readback = [Float](repeating: 0, count: 4)
    readback.withUnsafeMutableBytes { raw in
        tensor.getBytes(
            raw.baseAddress!,
            strides: MTLTensorExtents([1])!,
            sliceOrigin: MTLTensorExtents([0])!,
            sliceDimensions: MTLTensorExtents([4])!
        )
    }
    precondition(readback == values)

    let archiveDesc = MTLBinaryArchiveDescriptor()
    archiveDesc.url = URL(fileURLWithPath: "/tmp/missing.metallib")
    let archive = try! device.makeBinaryArchive(descriptor: archiveDesc)
    archive.label = "cpu-archive"
    precondition(archive.device.name == device.name)
    try! archive.addComputePipelineFunctions(descriptor: MTLComputePipelineDescriptor())
    try! archive.addRenderPipelineFunctions(descriptor: MTLRenderPipelineDescriptor())
    do {
        try archive.serialize(to: URL(fileURLWithPath: "/tmp/out.metallib"))
        fatalError("serialize must fail closed")
    } catch let error as MTLBinaryArchiveError {
        precondition(error.code == .internalError)
        precondition(MTLBinaryArchiveError.internalError ~= error)
    } catch {
        fatalError("expected MTLBinaryArchiveError")
    }

    let builtin = MTLMakeCPUBuiltinLibrary(device).makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let handle = device.functionHandle(function: builtin)!
    precondition(handle.name == builtin.name)
    precondition(handle.functionType == .kernel)
    precondition(handle.device.name == device.name)
    _ = handle.gpuResourceID
    _ = device.functionHandle(function: LinuxMTL4BinaryFunctionStub())

    do {
        _ = try device.makeDynamicLibrary(library: MTLMakeCPUBuiltinLibrary(device))
        fatalError("dynamic library must fail closed")
    } catch let error as MTLDynamicLibraryError {
        precondition(error.code == .unsupported)
        precondition(MTLDynamicLibraryError.unsupported ~= error)
        precondition(error.localizedDescription.contains("dynamic library"))
    } catch {
        fatalError("expected MTLDynamicLibraryError")
    }
    do {
        _ = try device.makeDynamicLibrary(url: URL(fileURLWithPath: "/tmp/missing.dylib"))
        fatalError("dynamic library URL must fail closed")
    } catch let error as MTLDynamicLibraryError {
        precondition(error.code == .unsupported)
    } catch {
        fatalError("expected MTLDynamicLibraryError")
    }

    let logDesc = MTLLogStateDescriptor()
    logDesc.bufferSize = 256
    logDesc.level = .info
    let logState = try! device.makeLogState(descriptor: logDesc)
    var handlerCount = 0
    logState.addLogHandler { _, _, _, _ in handlerCount += 1 }
    precondition(handlerCount == 0)
    do {
        let bad = MTLLogStateDescriptor()
        bad.bufferSize = -1
        _ = try device.makeLogState(descriptor: bad)
        fatalError("negative log buffer must fail closed")
    } catch let error as MTLLogStateError {
        precondition(error == .invalidSize)
    } catch {
        fatalError("expected MTLLogStateError")
    }

    let sharedDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    )
    precondition(device.makeSharedTexture(descriptor: sharedDesc) == nil)
    let sharedHandle = MTLSharedTextureHandle()
    sharedHandle.label = "none"
    _ = sharedHandle.device
    _ = MTLSharedTextureHandle.supportsSecureCoding
    precondition(device.makeSharedTexture(handle: sharedHandle) == nil)

    let poolDesc = MTLResourceViewPoolDescriptor()
    poolDesc.label = "views"
    poolDesc.resourceViewCount = 4
    let pool = try! device.makeTextureViewPool(descriptor: poolDesc)
    precondition(pool.resourceViewCount == 4)
    precondition(pool.device.name == device.name)
    _ = pool.baseResourceID
    _ = pool.label
    let texture = device.makeTexture(descriptor: sharedDesc)!
    let first = pool.setTextureView(texture: texture, index: 0)
    _ = pool.setTextureView(texture: texture, descriptor: MTLTextureViewDescriptor(), index: 1)
    let buffer = device.makeBuffer(length: 16, options: .storageModeShared)!
    _ = pool.setTextureView(
        buffer: buffer,
        descriptor: sharedDesc,
        offset: 0,
        bytesPerRow: 4,
        index: 2
    )
    _ = pool.copyResourceViews(from: pool, sourceRange: 0..<1, destinationIndex: 3)
    _ = first

    let counterDesc = MTLCounterSampleBufferDescriptor()
    counterDesc.sampleCount = 2
    counterDesc.label = "cpu-counters"
    let counters = try! device.makeCounterSampleBuffer(descriptor: counterDesc)
    precondition(counters.sampleCount == 2)
    precondition(counters.device.name == device.name)
    precondition(try! counters.resolveCounterRange(0..<2) == nil)

    let encoderInfo = MetalTestCommandBufferEncoderInfo()
    precondition(encoderInfo.label == "encoder")
    precondition(encoderInfo.debugSignposts.isEmpty)
    precondition(encoderInfo.errorState == .completed)
}

private final class LinuxMTL4BinaryFunctionStub: NSObject, MTL4BinaryFunction {}

private final class MetalTestCommandBufferEncoderInfo: NSObject, MTLCommandBufferEncoderInfo {
    var label: String { "encoder" }
    var debugSignposts: [String] { [] }
    var errorState: MTLCommandEncoderErrorState { .completed }
}

private final class MetalTestIOFileHandle: NSObject, MTLIOFileHandle, @unchecked Sendable {
    var label: String?
}

// from MetalGeometryTests.swift
func testGeometryHelpers() {
    let origin = MTLOriginMake(1, 2, 3)
    precondition(origin.x == 1 && origin.y == 2 && origin.z == 3)
    precondition(MTLOrigin().x == 0)
    precondition(MTLOrigin(x: 4, y: 5, z: 6).z == 6)
    let size = MTLSizeMake(4, 5, 6)
    precondition(size == MTLSize(width: 4, height: 5, depth: 6))
    precondition(MTLSize().width == 0)
    let region2D = MTLRegionMake2D(1, 2, 3, 4)
    precondition(region2D.origin.x == 1 && region2D.size.height == 4)
    let region3D = MTLRegionMake3D(0, 0, 0, 8, 8, 1)
    precondition(region3D.size.depth == 1)
    let region1D = MTLRegionMake1D(2, 10)
    precondition(region1D.size.width == 10)
    precondition(MTLRegion().size.width == 0)
    let sized = MTLSizeAndAlign(size: 64, align: 16)
    precondition(sized.size == 64 && sized.align == 16)
    precondition(MTLSizeAndAlign().align == 0)
    let clear = MTLClearColorMake(0.1, 0.2, 0.3, 1)
    precondition(clear.red == 0.1 && clear.green == 0.2 && clear.blue == 0.3 && clear.alpha == 1)
    precondition(MTLClearColor().alpha == 1)
    precondition(MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1).red == 1)
    let viewport = MTLViewport(originX: 0, originY: 0, width: 100, height: 50, znear: 0, zfar: 1)
    precondition(viewport.width == 100 && viewport.height == 50 && viewport.znear == 0 && viewport.zfar == 1)
    precondition(MTLViewport().zfar == 1)
    let scissor = MTLScissorRect(x: 0, y: 1, width: 10, height: 12)
    precondition(scissor.x == 0 && scissor.y == 1 && scissor.width == 10 && scissor.height == 12)
    precondition(MTLScissorRect().width == 0)
    let sample = MTLSamplePositionMake(0.5, 0.25)
    precondition(sample.x == 0.5 && sample.y == 0.25)
    precondition(MTLSamplePosition().x == 0)
    let coord = MTLCoordinate2DMake(1, 2)
    precondition(coord.x == 1 && coord.y == 2)
    let packed = MTLPackedFloat3Make(1, 2, 3)
    precondition(packed.x == 1 && packed.y == 2 && packed.z == 3)
    precondition(packed.elements.0 == 1 && packed.elements.2 == 3)
    var packedMut = MTLPackedFloat3()
    packedMut.elements = (9, 8, 7)
    precondition(packedMut.x == 9)
    let range = MTLIndirectCommandBufferExecutionRangeMake(4, 8)
    precondition(range.location == 4 && range.length == 8)
    precondition(MTLIndirectCommandBufferExecutionRange().length == 0)
    let gpuRange = MTL4BufferRangeMake(16, 32)
    precondition(gpuRange.bufferAddress == 16 && gpuRange.length == 32)
    precondition(MTL4BufferRange().length == 0)
    let mapping = MTLVertexAmplificationViewMapping(
        viewportArrayIndexOffset: 1,
        renderTargetArrayIndexOffset: 2
    )
    precondition(mapping.viewportArrayIndexOffset == 1)
    precondition(mapping.renderTargetArrayIndexOffset == 2)
    _ = MTLVertexAmplificationViewMapping()
    let swizzle = MTLTextureSwizzleChannels(red: .red, green: .green, blue: .blue, alpha: .alpha)
    precondition(swizzle.red == .red && swizzle.alpha == .alpha)
    _ = MTLTextureSwizzleChannels()
    let resourceID = MTLResourceID()
    precondition(resourceID._impl == 0)

    let identity = MTLPackedFloat4x3()
    precondition(identity.columns.0.x == 0)
    let column0 = MTLPackedFloat3Make(1, 0, 0)
    let column1 = MTLPackedFloat3Make(0, 1, 0)
    let column2 = MTLPackedFloat3Make(0, 0, 1)
    let column3 = MTLPackedFloat3Make(4, 5, 6)
    let transform = MTLPackedFloat4x3(columns: (column0, column1, column2, column3))
    precondition(transform.columns.3.x == 4 && transform.columns.3.z == 6)
}

func testAccelerationStructureDescriptors() {
    let sizes = MTLAccelerationStructureSizes(
        accelerationStructureSize: 0,
        buildScratchBufferSize: 0,
        refitScratchBufferSize: 0
    )
    precondition(sizes.accelerationStructureSize == 0)
    precondition(MTLAccelerationStructureSizes() == sizes)
    let matrix = MTLPackedFloat4x3(columns: (
        MTLPackedFloat3Make(1, 0, 0),
        MTLPackedFloat3Make(0, 1, 0),
        MTLPackedFloat3Make(0, 0, 1),
        MTLPackedFloat3Make(10, 20, 30)
    ))
    var instance = MTLAccelerationStructureInstanceDescriptor(
        transformationMatrix: matrix,
        options: [.opaque, .disableTriangleCulling],
        mask: 0xFF,
        intersectionFunctionTableOffset: 2,
        accelerationStructureIndex: 3
    )
    precondition(instance.mask == 0xFF)
    precondition(instance.options.contains(.opaque))
    instance.accelerationStructureIndex = 7
    precondition(instance.accelerationStructureIndex == 7)
    precondition(instance.transformationMatrix.columns.3.y == 20)
    var user = MTLAccelerationStructureUserIDInstanceDescriptor(
        transformationMatrix: matrix,
        options: .nonOpaque,
        mask: 1,
        intersectionFunctionTableOffset: 0,
        accelerationStructureIndex: 1,
        userID: 42
    )
    precondition(user.userID == 42)
    user.userID = 99
    precondition(user.userID == 99)
    var motion = MTLAccelerationStructureMotionInstanceDescriptor()
    motion.motionStartTime = 0.25
    motion.motionEndTime = 0.75
    motion.motionStartBorderMode = .clamp
    motion.motionEndBorderMode = .vanish
    motion.motionTransformsCount = 4
    motion.motionTransformsStartIndex = 1
    motion.options = .triangleFrontFacingWindingCounterClockwise
    precondition(motion.motionEndBorderMode == .vanish)
    precondition(motion.motionTransformsCount == 4)
    var indirect = MTLIndirectAccelerationStructureInstanceDescriptor(
        transformationMatrix: matrix,
        options: .opaque,
        mask: 2,
        intersectionFunctionTableOffset: 0,
        userID: 8,
        accelerationStructureID: MTLResourceID()
    )
    precondition(indirect.accelerationStructureID._impl == 0)
    indirect.userID = 9
    precondition(indirect.userID == 9)
    var indirectMotion = MTLIndirectAccelerationStructureMotionInstanceDescriptor()
    indirectMotion.motionStartBorderMode = .vanish
    indirectMotion.accelerationStructureID = MTLResourceID()
    precondition(indirectMotion.motionStartBorderMode == .vanish)
    let descriptor = MTLAccelerationStructureDescriptor()
    descriptor.usage = [.refit, .preferFastBuild]
    precondition(descriptor.usage.contains(.refit))
    let device = MTLCreateSystemDefaultDevice()!
    let zero = device.accelerationStructureSizes(descriptor: descriptor)
    precondition(zero.accelerationStructureSize == 0)
    precondition(zero.buildScratchBufferSize == 0)
    precondition(zero.refitScratchBufferSize == 0)
    let sparse = device.sparseTileSize(with: .type2D, pixelFormat: .rgba8Unorm, sampleCount: 1)
    precondition(sparse.width == 0 && sparse.height == 0)
    let sparsePage = device.sparseTileSize(
        with: .type2D,
        pixelFormat: .rgba8Unorm,
        sampleCount: 1,
        sparsePageSize: .size16
    )
    precondition(sparsePage.width == 0)
}

func testAccelerationStructureGeometryDescriptors() {
    let keyframe = MTLMotionKeyframeData.data()
    keyframe.offset = 16
    precondition(keyframe.offset == 16)
    keyframe.buffer = nil
    let geometry = MTLAccelerationStructureGeometryDescriptor()
    geometry.intersectionFunctionTableOffset = 3
    geometry.opaque = true
    geometry.allowDuplicateIntersectionFunctionInvocation = false
    geometry.label = "geom"
    geometry.primitiveDataBuffer = nil
    geometry.primitiveDataBufferOffset = 8
    geometry.primitiveDataStride = 16
    geometry.primitiveDataElementSize = 4
    precondition(geometry.opaque)
    let curve = MTLAccelerationStructureCurveGeometryDescriptor.descriptor()
    curve.controlPointCount = 4
    curve.controlPointBufferOffset = 0
    curve.controlPointFormat = .float3
    curve.controlPointStride = 12
    curve.radiusBufferOffset = 0
    curve.radiusFormat = .float
    curve.radiusStride = 4
    curve.indexBufferOffset = 0
    curve.indexType = .uint16
    curve.segmentCount = 1
    curve.segmentControlPointCount = 4
    curve.curveType = .round
    curve.curveBasis = .bSpline
    curve.curveEndCaps = .none
    curve.controlPointBuffer = nil
    curve.radiusBuffer = nil
    curve.indexBuffer = nil
    precondition(curve.controlPointCount == 4)
    precondition(curve.curveBasis == .bSpline)
    let motion = MTLAccelerationStructureMotionCurveGeometryDescriptor.descriptor()
    motion.controlPointBuffers = [keyframe]
    motion.controlPointCount = 4
    motion.controlPointFormat = .float3
    motion.controlPointStride = 12
    motion.radiusBuffers = [keyframe]
    motion.radiusFormat = .float
    motion.radiusStride = 4
    motion.indexBuffer = nil
    motion.indexBufferOffset = 0
    motion.indexType = .uint32
    motion.segmentCount = 1
    motion.segmentControlPointCount = 4
    motion.curveType = .flat
    motion.curveBasis = .bezier
    motion.curveEndCaps = .sphere
    precondition(motion.controlPointBuffers.count == 1)
    precondition(motion.curveType == .flat)
    let indirect = MTLIndirectInstanceAccelerationStructureDescriptor.descriptor()
    indirect.instanceDescriptorBuffer = nil
    indirect.instanceDescriptorBufferOffset = 0
    indirect.instanceDescriptorStride = 64
    indirect.instanceDescriptorType = .indirect
    indirect.maxInstanceCount = 8
    indirect.instanceCountBuffer = nil
    indirect.instanceCountBufferOffset = 4
    indirect.instanceTransformationMatrixLayout = .columnMajor
    indirect.motionTransformBuffer = nil
    indirect.motionTransformBufferOffset = 0
    indirect.motionTransformStride = 48
    indirect.motionTransformType = .packedFloat4x3
    indirect.maxMotionTransformCount = 2
    indirect.motionTransformCountBuffer = nil
    indirect.motionTransformCountBufferOffset = 0
    precondition(indirect.maxInstanceCount == 8)
    precondition(indirect.instanceDescriptorType == .indirect)
}

func testTriangleAndInstanceAccelerationDescriptors() {
    let device = MTLCreateSystemDefaultDevice()!
    let vertices = device.makeBuffer(length: 36, options: .storageModeShared)!
    let indices = device.makeBuffer(length: 12, options: .storageModeShared)!
    let boxes = device.makeBuffer(length: 24, options: .storageModeShared)!
    let triangle = MTLAccelerationStructureTriangleGeometryDescriptor.descriptor()
    triangle.vertexBuffer = vertices
    triangle.vertexBufferOffset = 0
    triangle.vertexStride = 12
    triangle.vertexFormat = .float3
    triangle.indexBuffer = indices
    triangle.indexBufferOffset = 0
    triangle.indexType = .uint16
    triangle.triangleCount = 1
    triangle.transformationMatrixBuffer = nil
    triangle.transformationMatrixBufferOffset = 0
    triangle.transformationMatrixLayout = .columnMajor
    triangle.opaque = true
    triangle.label = "tri"
    precondition(triangle.triangleCount == 1)
    precondition(triangle.vertexStride == 12)
    let keyframe = MTLMotionKeyframeData.data()
    keyframe.buffer = vertices
    keyframe.offset = 0
    let motionTri = MTLAccelerationStructureMotionTriangleGeometryDescriptor.descriptor()
    motionTri.vertexBuffers = [keyframe]
    motionTri.vertexStride = 12
    motionTri.vertexFormat = .float3
    motionTri.indexBuffer = indices
    motionTri.indexBufferOffset = 0
    motionTri.indexType = .uint32
    motionTri.triangleCount = 2
    motionTri.transformationMatrixBuffer = nil
    motionTri.transformationMatrixBufferOffset = 0
    motionTri.transformationMatrixLayout = .rowMajor
    precondition(motionTri.vertexBuffers.count == 1)
    precondition(motionTri.triangleCount == 2)
    let box = MTLAccelerationStructureBoundingBoxGeometryDescriptor.descriptor()
    box.boundingBoxBuffer = boxes
    box.boundingBoxBufferOffset = 0
    box.boundingBoxCount = 1
    box.boundingBoxStride = 24
    precondition(box.boundingBoxCount == 1)
    let motionBox = MTLAccelerationStructureMotionBoundingBoxGeometryDescriptor.descriptor()
    motionBox.boundingBoxBuffers = [keyframe]
    motionBox.boundingBoxCount = 1
    motionBox.boundingBoxStride = 24
    precondition(motionBox.boundingBoxBuffers.count == 1)
    let primitive = MTLPrimitiveAccelerationStructureDescriptor.descriptor()
    primitive.geometryDescriptors = [triangle, box]
    primitive.motionStartBorderMode = .clamp
    primitive.motionEndBorderMode = .vanish
    primitive.motionStartTime = 0
    primitive.motionEndTime = 1
    primitive.motionKeyframeCount = 1
    primitive.usage = [.preferFastBuild]
    precondition(primitive.geometryDescriptors?.count == 2)
    let instance = MTLInstanceAccelerationStructureDescriptor.descriptor()
    instance.instanceDescriptorBuffer = vertices
    instance.instanceDescriptorBufferOffset = 0
    instance.instanceDescriptorStride = 64
    instance.instanceDescriptorType = .userID
    instance.instanceCount = 2
    instance.instancedAccelerationStructures = [device.makeAccelerationStructure(size: 0)!]
    instance.instanceTransformationMatrixLayout = .columnMajor
    instance.motionTransformBuffer = nil
    instance.motionTransformBufferOffset = 0
    instance.motionTransformStride = 48
    instance.motionTransformType = .packedFloat4x3
    instance.motionTransformCount = 0
    precondition(instance.instanceCount == 2)
    precondition(instance.instanceDescriptorType == .userID)
    let sizes = device.accelerationStructureSizes(descriptor: primitive)
    precondition(sizes.accelerationStructureSize == 0)

    var quaternion = MTLPackedFloatQuaternion(x: 0, y: 0, z: 0, w: 1)
    quaternion.x = 0.1
    precondition(quaternion.w == 1)
    precondition(MTLPackedFloatQuaternion() != quaternion)
    var transform = MTLComponentTransform()
    transform.scale = MTLPackedFloat3Make(1, 2, 3)
    transform.shear = MTLPackedFloat3()
    transform.pivot = MTLPackedFloat3()
    transform.rotation = quaternion
    transform.translation = MTLPackedFloat3Make(4, 5, 6)
    precondition(transform.scale.y == 2)
    precondition(transform == MTLComponentTransform(
        scale: transform.scale,
        shear: transform.shear,
        pivot: transform.pivot,
        rotation: transform.rotation,
        translation: transform.translation
    ))
    var mapArgs = MTLMapIndirectArguments(
        regionOriginX: 1, regionOriginY: 2, regionOriginZ: 0,
        regionSizeWidth: 4, regionSizeHeight: 4, regionSizeDepth: 1,
        mipMapLevel: 0, sliceId: 0
    )
    mapArgs.sliceId = 1
    precondition(mapArgs.regionSizeWidth == 4)
    precondition(MTLMapIndirectArguments().mipMapLevel == 0)
    var draw = MTLDrawPrimitivesIndirectArguments(vertexCount: 3, instanceCount: 1, vertexStart: 0, baseInstance: 0)
    draw.instanceCount = 2
    precondition(draw.vertexCount == 3)
    var indexed = MTLDrawIndexedPrimitivesIndirectArguments(
        indexCount: 3, instanceCount: 1, indexStart: 0, baseVertex: 0, baseInstance: 0
    )
    indexed.baseVertex = -1
    precondition(indexed.indexCount == 3)
    var patch = MTLDrawPatchIndirectArguments(patchCount: 1, instanceCount: 1, patchStart: 0, baseInstance: 0)
    patch.patchStart = 1
    precondition(patch.patchCount == 1)
}

func testMetal4AccelerationStructureDescriptors() {
    let geometry = MTL4AccelerationStructureGeometryDescriptor()
    geometry.intersectionFunctionTableOffset = 2
    geometry.opaque = true
    geometry.allowDuplicateIntersectionFunctionInvocation = false
    geometry.label = "g4"
    geometry.primitiveDataBuffer = MTL4BufferRangeMake(8, 16)
    geometry.primitiveDataStride = 16
    geometry.primitiveDataElementSize = 4
    precondition(geometry.opaque)
    let curve = MTL4AccelerationStructureCurveGeometryDescriptor()
    curve.controlPointBuffer = MTL4BufferRangeMake(0, 48)
    curve.controlPointCount = 4
    curve.controlPointStride = 12
    curve.controlPointFormat = .float3
    curve.radiusBuffer = MTL4BufferRangeMake(48, 16)
    curve.radiusFormat = .float
    curve.radiusStride = 4
    curve.indexBuffer = MTL4BufferRangeMake(64, 8)
    curve.indexType = .uint16
    curve.segmentCount = 1
    curve.segmentControlPointCount = 4
    curve.curveType = .round
    curve.curveBasis = .bSpline
    curve.curveEndCaps = .none
    precondition(curve.controlPointCount == 4)
    let motionCurve = MTL4AccelerationStructureMotionCurveGeometryDescriptor()
    motionCurve.controlPointBuffers = MTL4BufferRangeMake(0, 96)
    motionCurve.controlPointCount = 4
    motionCurve.controlPointStride = 12
    motionCurve.controlPointFormat = .float3
    motionCurve.radiusBuffers = MTL4BufferRangeMake(96, 32)
    motionCurve.radiusFormat = .float
    motionCurve.radiusStride = 4
    motionCurve.indexBuffer = MTL4BufferRangeMake(128, 8)
    motionCurve.indexType = .uint32
    motionCurve.segmentCount = 1
    motionCurve.segmentControlPointCount = 4
    motionCurve.curveType = .flat
    motionCurve.curveBasis = .bezier
    motionCurve.curveEndCaps = .sphere
    precondition(motionCurve.curveType == .flat)
    let tri = MTL4AccelerationStructureTriangleGeometryDescriptor()
    tri.vertexBuffer = MTL4BufferRangeMake(0, 36)
    tri.vertexFormat = .float3
    tri.vertexStride = 12
    tri.indexBuffer = MTL4BufferRangeMake(36, 12)
    tri.indexType = .uint16
    tri.triangleCount = 1
    tri.transformationMatrixBuffer = MTL4BufferRangeMake(48, 48)
    tri.transformationMatrixLayout = .columnMajor
    precondition(tri.triangleCount == 1)
    let motionTri = MTL4AccelerationStructureMotionTriangleGeometryDescriptor()
    motionTri.vertexBuffers = MTL4BufferRangeMake(0, 72)
    motionTri.vertexFormat = .float3
    motionTri.vertexStride = 12
    motionTri.indexBuffer = MTL4BufferRangeMake(72, 12)
    motionTri.indexType = .uint32
    motionTri.triangleCount = 2
    motionTri.transformationMatrixBuffer = MTL4BufferRange()
    motionTri.transformationMatrixLayout = .rowMajor
    precondition(motionTri.triangleCount == 2)
    let box = MTL4AccelerationStructureBoundingBoxGeometryDescriptor()
    box.boundingBoxBuffer = MTL4BufferRangeMake(0, 24)
    box.boundingBoxCount = 1
    box.boundingBoxStride = 24
    precondition(box.boundingBoxCount == 1)
    let motionBox = MTL4AccelerationStructureMotionBoundingBoxGeometryDescriptor()
    motionBox.boundingBoxBuffers = MTL4BufferRangeMake(0, 48)
    motionBox.boundingBoxCount = 2
    motionBox.boundingBoxStride = 24
    precondition(motionBox.boundingBoxCount == 2)
    let primitive = MTL4PrimitiveAccelerationStructureDescriptor()
    primitive.geometryDescriptors = [curve, tri, box]
    primitive.motionStartBorderMode = .clamp
    primitive.motionEndBorderMode = .vanish
    primitive.motionStartTime = 0
    primitive.motionEndTime = 1
    primitive.motionKeyframeCount = 2
    precondition(primitive.geometryDescriptors?.count == 3)
    let instance = MTL4InstanceAccelerationStructureDescriptor()
    instance.instanceDescriptorBuffer = MTL4BufferRangeMake(0, 128)
    instance.instanceDescriptorStride = 64
    instance.instanceDescriptorType = .default
    instance.instanceCount = 2
    instance.instanceTransformationMatrixLayout = .columnMajor
    instance.motionTransformBuffer = MTL4BufferRange()
    instance.motionTransformStride = 48
    instance.motionTransformType = .packedFloat4x3
    instance.motionTransformCount = 0
    precondition(instance.instanceCount == 2)
    let indirect = MTL4IndirectInstanceAccelerationStructureDescriptor()
    indirect.instanceDescriptorBuffer = MTL4BufferRangeMake(0, 256)
    indirect.instanceDescriptorStride = 64
    indirect.instanceDescriptorType = .indirect
    indirect.maxInstanceCount = 8
    indirect.instanceCountBuffer = MTL4BufferRangeMake(256, 4)
    indirect.instanceTransformationMatrixLayout = .columnMajor
    indirect.motionTransformBuffer = MTL4BufferRange()
    indirect.motionTransformStride = 48
    indirect.motionTransformType = .component
    indirect.maxMotionTransformCount = 2
    indirect.motionTransformCountBuffer = MTL4BufferRangeMake(260, 4)
    precondition(indirect.maxInstanceCount == 8)
    precondition(indirect.instanceDescriptorType == .indirect)
}

// from MetalHeapTests.swift
func testHeapFenceAndEvent() {
    let device = MTLCreateSystemDefaultDevice()!
    let heapDesc = MTLHeapDescriptor()
    heapDesc.size = 4096
    heapDesc.storageMode = .shared
    let heap = device.makeHeap(descriptor: heapDesc)!
    heap.label = "heap"
    precondition(heap.label == "heap")
    precondition(heap.size == 4096)
    precondition(heap.device.name == device.name)
    precondition(heap.storageMode == .shared)
    _ = heap.cpuCacheMode
    _ = heap.hazardTrackingMode
    _ = heap.resourceOptions
    _ = heap.type
    _ = heap.allocatedSize
    _ = heap.currentAllocatedSize
    _ = heap.usedSize
    _ = heap.maxAvailableSize(alignment: 16)
    _ = heap.setPurgeableState(.nonVolatile)
    let heapBuffer = heap.makeBuffer(length: 32, options: .storageModeShared)!
    precondition(heapBuffer.heap != nil)
    precondition(heapBuffer.length == 32)
    let placed = heap.makeBuffer(length: 16, options: [], offset: 64)
    precondition(placed != nil)
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 4,
        height: 1,
        mipmapped: false
    )
    precondition(heap.makeTexture(descriptor: texDesc) != nil)
    precondition(heap.makeTexture(descriptor: texDesc, offset: 256) != nil)
    let fence = device.makeFence()!
    fence.label = "cpu-fence"
    precondition(fence.label == "cpu-fence")
    precondition(fence.device.name == device.name)
    let event = device.makeEvent()!
    event.label = "cpu-event"
    precondition(event.label == "cpu-event")
    precondition(event.device.name == device.name)
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.encodeSignalEvent(event, value: 1)
    commandBuffer.encodeWaitForEvent(event, value: 1)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
}

func testSharedEventHostClock() {
    let device = MTLCreateSystemDefaultDevice()!
    let event = device.makeSharedEvent()!
    event.label = "host-clock"
    precondition(event.label == "host-clock")
    precondition(event.device.name == device.name)
    precondition(event.signaledValue == 0)
    event.signaledValue = 3
    precondition(event.signaledValue == 3)
    event.signaledValue = 1
    precondition(event.signaledValue == 3)
    precondition(event.wait(untilSignaledValue: 3, timeoutMS: 0))
    precondition(!event.wait(untilSignaledValue: 4, timeoutMS: 0))
    var notified = false
    let listener = MTLSharedEventListener()
    _ = listener.dispatchQueue
    event.notify(listener, atValue: 5) { shared, value in
        notified = true
        precondition(value >= 5)
        precondition(shared.signaledValue >= 5)
    }
    event.signaledValue = 5
    precondition(notified)
    let sharedListener = MTLSharedEventListener.shared()
    precondition(sharedListener === MTLSharedEventListener.shared())
    let queued = MTLSharedEventListener(dispatchQueue: DispatchQueue.global())
    _ = queued.dispatchQueue
    let handle = event.makeSharedEventHandle()
    handle.label = "cloned"
    let restored = device.makeSharedEvent(handle: handle)!
    precondition(restored.signaledValue == 5)
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.encodeSignalEvent(event, value: 7)
    commandBuffer.encodeWaitForEvent(event, value: 7)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(event.signaledValue >= 7)
    _ = MTLSharedEventHandle.supportsSecureCoding
}

func testResidencySetAndRasterizationRateMap() {
    let device = MTLCreateSystemDefaultDevice()!
    let residencyDesc = MTLResidencySetDescriptor()
    residencyDesc.label = "resident"
    residencyDesc.initialCapacity = 4
    let residency = try! device.makeResidencySet(descriptor: residencyDesc)
    residency.label = "cpu-set"
    precondition(residency.device.name == device.name)
    precondition(residency.label == "cpu-set")
    let buffer = device.makeBuffer(length: 32, options: .storageModeShared)!
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    let texture = device.makeTexture(descriptor: textureDesc)!
    residency.addAllocation(buffer)
    residency.addAllocations([texture])
    precondition(residency.containsAllocation(buffer))
    precondition(residency.allocationCount == 2)
    precondition(residency.allAllocations.count == 2)
    precondition(residency.allocatedSize >= 32)
    residency.commit()
    residency.requestResidency()
    residency.removeAllocation(texture)
    precondition(!residency.containsAllocation(texture))
    residency.removeAllocations([buffer])
    residency.removeAllAllocations()
    precondition(residency.allocationCount == 0)
    residency.endResidency()
    let queue = device.makeCommandQueue()!
    queue.addResidencySet(residency)
    queue.addResidencySets([residency])
    queue.removeResidencySet(residency)
    queue.removeResidencySets([residency])
    let commandBuffer = queue.makeCommandBuffer()!
    commandBuffer.useResidencySet(residency)
    commandBuffer.useResidencySets([residency])
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let layer = MTLRasterizationRateLayerDescriptor(sampleCount: MTLSizeMake(2, 2, 1))
    precondition(layer.maxSampleCount.width == 2)
    layer.sampleCount = MTLSizeMake(2, 2, 1)
    layer.horizontal[0] = 1
    layer.horizontal[1] = 1
    layer.vertical[0] = 1
    layer.vertical[1] = 1
    let fromArrays = MTLRasterizationRateLayerDescriptor(horizontal: [1, 1], vertical: [1, 1])
    precondition(fromArrays.horizontal[0] == 1)
    let copied = fromArrays.copy() as! MTLRasterizationRateLayerDescriptor
    precondition(copied.vertical[0] == 1)
    let rateDesc = MTLRasterizationRateMapDescriptor(screenSize: MTLSizeMake(8, 8, 1), layer: layer, label: "identity")
    rateDesc.setLayer(layer, at: 0)
    precondition(rateDesc.layerCount == 1)
    precondition(rateDesc.layer(at: 0) != nil)
    precondition(rateDesc.layers[0] != nil)
    rateDesc.screenSize = MTLSizeMake(8, 8, 1)
    let multi = MTLRasterizationRateMapDescriptor(
        screenSize: MTLSizeMake(4, 4, 1),
        layers: [layer],
        label: "multi"
    )
    precondition(multi.layerCount == 1)
    _ = MTLRasterizationRateMapDescriptor(screenSize: MTLSizeMake(2, 2, 1), label: "empty")
    let map = device.makeRasterizationRateMap(descriptor: rateDesc)!
    precondition(map.device.name == device.name)
    precondition(map.label == "identity")
    precondition(map.screenSize.width == 8)
    precondition(map.layerCount == 1)
    precondition(map.physicalGranularity.width == 1)
    precondition(map.physicalSize(layer: 0).width == 8)
    precondition(map.parameterBufferSizeAndAlign.size >= 16)
    let screen = MTLCoordinate2DMake(3, 4)
    let physical = map.physicalCoordinates(screenCoordinates: screen, layer: 0)
    precondition(physical.x == 3 && physical.y == 4)
    let back = map.screenCoordinates(physicalCoordinates: physical, layer: 0)
    precondition(back.x == 3)
    let param = device.makeBuffer(length: 64, options: .storageModeShared)!
    map.copyParameterData(buffer: param, offset: 0)
    precondition(param.contents().load(as: UInt32.self) == 8)
}

// from MetalRenderTests.swift
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

func testRenderEncoderAccelerationBindings() {
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
    pass.colorAttachments[0].loadAction = .load
    pass.colorAttachments[0].storeAction = .store
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    let state = try! device.makeRenderPipelineState(descriptor: pipeline)
    let accel = device.makeAccelerationStructure(size: 0)
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
    encoder.setRenderPipelineState(state)
    encoder.setColorAttachmentMap(MTLLogicalToPhysicalColorAttachmentMap())
    encoder.setVertexAccelerationStructure(accel, bufferIndex: 0)
    encoder.setFragmentAccelerationStructure(accel, bufferIndex: 1)
    encoder.setTileAccelerationStructure(accel, bufferIndex: 2)
    encoder.setVertexIntersectionFunctionTable(nil, bufferIndex: 0)
    encoder.setFragmentIntersectionFunctionTable(nil, bufferIndex: 0)
    encoder.setTileIntersectionFunctionTable(nil, bufferIndex: 0)
    encoder.setVertexVisibleFunctionTable(nil, bufferIndex: 0)
    encoder.setFragmentVisibleFunctionTable(nil, bufferIndex: 0)
    encoder.setTileVisibleFunctionTable(nil, bufferIndex: 0)
    var mapping = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 0)
    encoder.setVertexAmplificationCount(1, viewMappings: &mapping)
    encoder.setVertexAmplificationCount(1, viewMappings: nil)
    let counters = try! device.makeCounterSampleBuffer(descriptor: {
        let desc = MTLCounterSampleBufferDescriptor()
        desc.sampleCount = 1
        return desc
    }())
    encoder.sampleCounters(sampleBuffer: counters, sampleIndex: 0, barrier: true)
    encoder.useHeap(device.makeHeap(descriptor: {
        let desc = MTLHeapDescriptor()
        desc.size = 32
        return desc
    }())!)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.status == .completed)
}

// from MetalTextureTests.swift
func testTextureBytesAndMips() {
    func roundTrip(_ format: MTLPixelFormat, bytesPerPixel: Int, pattern: [UInt8]) {
        let device = MTLCreateSystemDefaultDevice()!
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format,
            width: 2,
            height: 1,
            mipmapped: false
        )
        let texture = device.makeTexture(descriptor: descriptor)!
        precondition(texture.pixelFormat == format)
        precondition(texture.width == 2)
        precondition(texture.height == 1)
        precondition(texture.depth == 1)
        precondition(texture.textureType == .type2D)
        precondition(texture.mipmapLevelCount == 1)
        precondition(texture.sampleCount == 1)
        precondition(texture.arrayLength == 1)
        precondition(texture.usage.contains(.shaderRead))
        precondition(!texture.isFramebufferOnly)
        precondition(!texture.isShareable)
        precondition(!texture.isSparse)
        _ = texture.allowGPUOptimizedContents
        _ = texture.compressionType
        _ = texture.swizzle
        _ = texture.parent
        _ = texture.parentRelativeLevel
        _ = texture.parentRelativeSlice
        _ = texture.buffer
        _ = texture.bufferOffset
        _ = texture.bufferBytesPerRow
        _ = texture.rootResource
        _ = texture.gpuResourceID
        _ = texture.firstMipmapInTail
        _ = texture.tailSizeInBytes
        _ = texture.sparseTextureTier
        _ = texture.storageMode
        pattern.withUnsafeBytes { raw in
            texture.replace(
                region: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0,
                withBytes: raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel
            )
        }
        var roundTripBytes = [UInt8](repeating: 0, count: pattern.count)
        roundTripBytes.withUnsafeMutableBytes { raw in
            texture.getBytes(
                raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel,
                from: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0
            )
        }
        precondition(roundTripBytes == pattern)
        _ = texture.makeTextureView(pixelFormat: format)
    }

    roundTrip(.rgba8Unorm, bytesPerPixel: 4, pattern: [10, 20, 30, 40, 50, 60, 70, 80])
    roundTrip(.bgra8Unorm, bytesPerPixel: 4, pattern: [1, 2, 3, 4, 5, 6, 7, 8])
    roundTrip(.r8Unorm, bytesPerPixel: 1, pattern: [9, 11])
    var rgba16 = [UInt8](repeating: 0, count: 16)
    var one = Float16(1.0)
    var half = Float16(0.5)
    withUnsafeBytes(of: &one) { src in
        rgba16.replaceSubrange(0..<2, with: src)
        rgba16.replaceSubrange(8..<10, with: src)
    }
    withUnsafeBytes(of: &half) { src in
        rgba16.replaceSubrange(2..<4, with: src)
        rgba16.replaceSubrange(10..<12, with: src)
    }
    roundTrip(.rgba16Float, bytesPerPixel: 8, pattern: rgba16)
    var rgba32 = [UInt8](repeating: 0, count: 32)
    var f1: Float = 1
    var f2: Float = 2
    withUnsafeBytes(of: &f1) { src in
        rgba32.replaceSubrange(0..<4, with: src)
        rgba32.replaceSubrange(16..<20, with: src)
    }
    withUnsafeBytes(of: &f2) { src in
        rgba32.replaceSubrange(4..<8, with: src)
        rgba32.replaceSubrange(20..<24, with: src)
    }
    roundTrip(.rgba32Float, bytesPerPixel: 16, pattern: rgba32)
    var depth = [UInt8](repeating: 0, count: 8)
    var d1: Float = 0.25
    var d2: Float = 0.75
    withUnsafeBytes(of: &d1) { src in depth.replaceSubrange(0..<4, with: src) }
    withUnsafeBytes(of: &d2) { src in depth.replaceSubrange(4..<8, with: src) }
    roundTrip(.depth32Float, bytesPerPixel: 4, pattern: depth)

    let device = MTLCreateSystemDefaultDevice()!
    let invalid = MTLTextureDescriptor()
    invalid.pixelFormat = .invalid
    precondition(device.makeTexture(descriptor: invalid) == nil)
    let zero = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 0,
        height: 4,
        mipmapped: false
    )
    precondition(device.makeTexture(descriptor: zero) == nil)

    let mipDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    precondition(mipDesc.mipmapLevelCount == 2)
    let mip = device.makeTexture(descriptor: mipDesc)!
    precondition(mip.mipmapLevelCount == 2)
    let pixels: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    pixels.withUnsafeBytes { raw in
        mip.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8,
            bytesPerImage: 16
        )
    }
    var sliceBytes = [UInt8](repeating: 0, count: 16)
    sliceBytes.withUnsafeMutableBytes { raw in
        mip.getBytes(
            raw.baseAddress!,
            bytesPerRow: 8,
            bytesPerImage: 16,
            from: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            slice: 0
        )
    }
    precondition(sliceBytes == pixels)
}

func testTextureViewsAndDimensionalLayouts() {
    let device = MTLCreateSystemDefaultDevice()!

    func roundTrip(_ format: MTLPixelFormat, bytesPerPixel: Int, pattern: [UInt8]) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format,
            width: 2,
            height: 1,
            mipmapped: false
        )
        let texture = device.makeTexture(descriptor: descriptor)!
        pattern.withUnsafeBytes { raw in
            texture.replace(
                region: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0,
                withBytes: raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel
            )
        }
        var roundTripBytes = [UInt8](repeating: 0, count: pattern.count)
        roundTripBytes.withUnsafeMutableBytes { raw in
            texture.getBytes(
                raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel,
                from: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0
            )
        }
        precondition(roundTripBytes == pattern)
    }

    roundTrip(.a8Unorm, bytesPerPixel: 1, pattern: [3, 7])
    roundTrip(.r8Uint, bytesPerPixel: 1, pattern: [4, 9])
    roundTrip(.rg8Unorm, bytesPerPixel: 2, pattern: [1, 2, 3, 4])
    roundTrip(.r16Float, bytesPerPixel: 2, pattern: [0x00, 0x3C, 0x00, 0x40])
    roundTrip(.rgba8Uint, bytesPerPixel: 4, pattern: [9, 8, 7, 6, 5, 4, 3, 2])
    roundTrip(.bgra8Unorm_srgb, bytesPerPixel: 4, pattern: [11, 12, 13, 14, 15, 16, 17, 18])
    roundTrip(.r32Float, bytesPerPixel: 4, pattern: {
        var bytes = [UInt8](repeating: 0, count: 8)
        var a: Float = 0.5
        var b: Float = 1.5
        withUnsafeBytes(of: &a) { src in bytes.replaceSubrange(0..<4, with: src) }
        withUnsafeBytes(of: &b) { src in bytes.replaceSubrange(4..<8, with: src) }
        return bytes
    }())

    let sourceDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    let source = device.makeTexture(descriptor: sourceDesc)!
    let pixels: [UInt8] = [
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16
    ]
    pixels.withUnsafeBytes { raw in
        source.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8
        )
    }
    let same = source.makeTextureView(pixelFormat: .rgba8Unorm)!
    precondition(same.parent != nil)
    precondition(same.pixelFormat == .rgba8Unorm)
    let bgra = source.makeTextureView(pixelFormat: .bgra8Unorm)!
    precondition(bgra.pixelFormat == .bgra8Unorm)
    var viewed = [UInt8](repeating: 0, count: 16)
    viewed.withUnsafeMutableBytes { raw in
        bgra.getBytes(raw.baseAddress!, bytesPerRow: 8, from: MTLRegionMake2D(0, 0, 2, 2), mipmapLevel: 0)
    }
    precondition(viewed == pixels)
    precondition(source.makeTextureView(pixelFormat: .r8Unorm) == nil)

    let ranged = source.makeTextureView(
        pixelFormat: .rgba8Unorm,
        textureType: .type2D,
        levels: 0..<1,
        slices: 0..<1
    )!
    precondition(ranged.mipmapLevelCount == 1)
    precondition(ranged.parentRelativeLevel == 0)
    let swizzled = source.makeTextureView(
        pixelFormat: .rgba8Unorm,
        textureType: .type2D,
        levels: 0..<1,
        slices: 0..<1,
        swizzle: MTLTextureSwizzleChannels(red: .blue, green: .green, blue: .red, alpha: .alpha)
    )!
    precondition(swizzled.swizzle.red == .blue)
    let viewDesc = MTLTextureViewDescriptor()
    viewDesc.pixelFormat = .rgba8Uint
    viewDesc.textureType = .type2D
    viewDesc.levelRange = 0..<1
    viewDesc.sliceRange = 0..<1
    viewDesc.swizzle = MTLTextureSwizzleChannels()
    let fromDesc = source.newTextureView(with: viewDesc)!
    precondition(fromDesc.pixelFormat == .rgba8Uint)

    let arrayDesc = MTLTextureDescriptor()
    arrayDesc.textureType = .type2DArray
    arrayDesc.pixelFormat = .r8Unorm
    arrayDesc.width = 2
    arrayDesc.height = 1
    arrayDesc.arrayLength = 2
    let array = device.makeTexture(descriptor: arrayDesc)!
    precondition(array.arrayLength == 2)
    let slice0: [UInt8] = [1, 2]
    let slice1: [UInt8] = [9, 8]
    slice0.withUnsafeBytes { raw in
        array.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    slice1.withUnsafeBytes { raw in
        array.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 1,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    var read1 = [UInt8](repeating: 0, count: 2)
    read1.withUnsafeMutableBytes { raw in
        array.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2,
            from: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 1
        )
    }
    precondition(read1 == slice1)

    let cube = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .r8Unorm, size: 1, mipmapped: false)
    let cubeTex = device.makeTexture(descriptor: cube)!
    precondition(cube.textureType == .typeCube)
    for face in 0..<6 {
        var byte = UInt8(face + 1)
        withUnsafeBytes(of: &byte) { raw in
            cubeTex.replace(
                region: MTLRegionMake2D(0, 0, 1, 1),
                mipmapLevel: 0,
                slice: face,
                withBytes: raw.baseAddress!,
                bytesPerRow: 1,
                bytesPerImage: 1
            )
        }
    }
    var face5: UInt8 = 0
    withUnsafeMutableBytes(of: &face5) { raw in
        cubeTex.getBytes(
            raw.baseAddress!,
            bytesPerRow: 1,
            bytesPerImage: 1,
            from: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0,
            slice: 5
        )
    }
    precondition(face5 == 6)

    let volume = MTLTextureDescriptor()
    volume.textureType = .type3D
    volume.pixelFormat = .r8Unorm
    volume.width = 2
    volume.height = 1
    volume.depth = 2
    let tex3D = device.makeTexture(descriptor: volume)!
    precondition(tex3D.depth == 2)
    let voxels: [UInt8] = [1, 2, 3, 4]
    voxels.withUnsafeBytes { raw in
        tex3D.replace(
            region: MTLRegionMake3D(0, 0, 0, 2, 1, 2),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    var readVoxels = [UInt8](repeating: 0, count: 4)
    readVoxels.withUnsafeMutableBytes { raw in
        tex3D.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2,
            from: MTLRegionMake3D(0, 0, 0, 2, 1, 2),
            mipmapLevel: 0,
            slice: 0
        )
    }
    precondition(readVoxels == voxels)
}

testBufferStorage()
testCommandBufferLifecycle()
testBlitCopyFillMipmaps()
testIndirectCommandBufferAsData()
testResourceStateEncoder()
testMetal4CommandEncoders()
testCPUBuiltinCompute()
testDescriptorValueSemantics()
testMeshAndTilePipelineDescriptors()
testMetal4PipelineDescriptors()
testCPUDevice()
testDeviceFactoryAndFailClosed()
testDeviceFailClosedFactories()
testMetalEnumOptionSetAndConstantValues()
testLibraryFailClosed()
testCaptureFailClosed()
testArgumentEncoderAndICB()
testPipelineDescriptorValidation()
testComputeDispatchFailClosed()
testIOCommandBufferFailClosed()
testGeometryHelpers()
testAccelerationStructureDescriptors()
testAccelerationStructureGeometryDescriptors()
testHeapFenceAndEvent()
testSharedEventHostClock()
testRenderPassClearAndLoad()
testParallelRenderEncoderAndSamplerState()
testRenderEncoderStageBindings()
testRenderPipelineStateMeshProperties()
testTextureBytesAndMips()
testTextureViewsAndDimensionalLayouts()
testAccelerationStructureCommandEncoder()
testCPUTensorBinaryArchiveAndHandles()
testTriangleAndInstanceAccelerationDescriptors()
testMetal4AccelerationStructureDescriptors()
testResidencySetAndRasterizationRateMap()
testRenderEncoderAccelerationBindings()

print("METAL_AGENT_RUNTIME_OK")
