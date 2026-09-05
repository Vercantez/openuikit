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
