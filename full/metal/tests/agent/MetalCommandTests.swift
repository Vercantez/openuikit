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
