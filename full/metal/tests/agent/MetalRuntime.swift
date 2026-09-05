import Foundation
import Metal

func exerciseGeometry() {
    let origin = MTLOriginMake(1, 2, 3)
    precondition(origin.x == 1 && origin.y == 2 && origin.z == 3)
    let size = MTLSizeMake(4, 5, 6)
    precondition(size == MTLSize(width: 4, height: 5, depth: 6))
    let region2D = MTLRegionMake2D(1, 2, 3, 4)
    precondition(region2D.origin.x == 1 && region2D.size.height == 4)
    let region3D = MTLRegionMake3D(0, 0, 0, 8, 8, 1)
    precondition(region3D.size.depth == 1)
    let region1D = MTLRegionMake1D(2, 10)
    precondition(region1D.size.width == 10)
    let clear = MTLClearColorMake(0.1, 0.2, 0.3, 1)
    precondition(clear.alpha == 1)
    let sample = MTLSamplePositionMake(0.5, 0.5)
    precondition(sample.x == 0.5)
    let coord = MTLCoordinate2DMake(1, 2)
    precondition(coord.y == 2)
    let packed = MTLPackedFloat3Make(1, 2, 3)
    precondition(packed.x == 1 && packed.elements.2 == 3)
    let range = MTLIndirectCommandBufferExecutionRangeMake(4, 8)
    precondition(range.length == 8)
    let gpuRange = MTL4BufferRangeMake(16, 32)
    precondition(gpuRange.bufferAddress == 16)
    precondition(MTLSizeAndAlign(size: 64, align: 16).align == 16)
    let viewport = MTLViewport(originX: 0, originY: 0, width: 100, height: 50, znear: 0, zfar: 1)
    precondition(viewport.height == 50)
    let scissor = MTLScissorRect(x: 0, y: 0, width: 10, height: 10)
    precondition(scissor.width == 10)
    let mapping = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 1, renderTargetArrayIndexOffset: 2)
    precondition(mapping.viewportArrayIndexOffset == 1)
    _ = MTLVertexAmplificationViewMapping()
}

func exercisePixelFormatsAndOptions() {
    precondition(MTLPixelFormat.rgba8Unorm.rawValue == 70)
    precondition(MTLPixelFormat.bgra8Unorm.rawValue == 80)
    precondition(MTLPixelFormat.r8Unorm.rawValue == 10)
    precondition(MTLPixelFormat.rgba16Float.rawValue == 115)
    precondition(MTLPixelFormat.rgba32Float.rawValue == 125)
    precondition(MTLPixelFormat.depth32Float.rawValue == 252)
    precondition(MTLPixelFormat.invalid != .rgba8Unorm)
    precondition(MTLStorageMode.shared.rawValue == 0)
    precondition(MTLStorageMode.private.rawValue == 2)
    precondition(MTLResourceOptions.storageModePrivate.rawValue == 32)
    precondition(MTLResourceOptions.cpuCacheModeWriteCombined.contains(.optionCPUCacheModeWriteCombined))
    var usage: MTLTextureUsage = [.shaderRead, .renderTarget]
    precondition(usage.contains(.shaderRead))
    usage.formUnion(.shaderWrite)
    precondition(usage.contains(.shaderWrite))
    precondition(MTLColorWriteMask.all.contains(.red))
    precondition(MTLGPUFamily.apple1.rawValue == 1001)
    precondition(MTLGPUFamily.apple7 != .apple1)
    precondition(MTLLanguageVersion.version2_4.rawValue == 0x20004)
    precondition(MTLPrimitiveType.triangle.rawValue == 3)
    precondition(MTLLoadAction.clear.rawValue == 2)
    precondition(MTLTextureType.type2D.rawValue == 2)
    precondition(MTLCommandBufferStatus.completed.rawValue == 4)
    precondition(MTLLibraryErrorDomain == "MTLLibraryErrorDomain")
    precondition(MTLCommandBufferErrorDomain == "MTLCommandBufferErrorDomain")
    let libraryError = MTLLibraryError(.compileFailure)
    precondition(libraryError.code == .compileFailure)
    precondition(MTLLibraryError.compileFailure ~= libraryError)
    precondition(MTLCommandBufferError.accessRevoked == .blacklisted)
    precondition(MTLResourceCPUCacheModeShift == 0)
    precondition(MTLResourceStorageModeShift == 4)
    precondition(MTLCounterDontSample == -1)
    precondition(MTLDataType.float.rawValue == 3)
    precondition(MTLDataType.rgba8Unorm.rawValue == 70)
    precondition(MTLArgumentType.buffer.rawValue == 0)
    precondition(MTLBindingType.texture.rawValue == 2)
    precondition(MTLVisibilityResultMode.disabled.rawValue == 0)
    precondition(MTLShaderValidation.enabled.rawValue == 1)
    precondition(MTLFunctionOptions.compileToBinary.rawValue == 1)
    precondition(MTLIndirectCommandType.draw.contains(.draw))
    precondition(MTLVertexFormat.float4.rawValue == 31)
    precondition(MTLAttributeFormat.float4.rawValue == 31)
    precondition(MTLIOError.urlInvalid.rawValue == 1)
    _ = MTLPixelFormat.a8Unorm
    _ = MTLPixelFormat.rgba8Unorm_srgb
    _ = MTLPixelFormat.bgra8Unorm_srgb
    _ = MTLPixelFormat.stencil8
    _ = MTLPixelFormat.depth32Float_stencil8
    _ = MTLBlendFactor.sourceAlpha
    _ = MTLBlendOperation.add
    _ = MTLCompareFunction.less
    _ = MTLStencilOperation.keep
    _ = MTLCullMode.back
    _ = MTLWinding.counterClockwise
    _ = MTLSamplerAddressMode.repeat
    _ = MTLSamplerMinMagFilter.linear
    _ = MTLDispatchType.serial
    _ = MTLStages.blit
    _ = MTLRenderStages.fragment
    _ = MTLPipelineOption.argumentInfo
    _ = MTLBlitOption.depthFromDepthStencil
    _ = MTLResourceUsage.read
    _ = MTLStoreActionOptions.customSamplePositions
    _ = MTLCommandBufferErrorOption.encoderExecutionStatus
    _ = MTLBarrierScope.buffers
}

func exerciseSoftwareDevice() {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("CPU reference device must exist")
    }
    let devices = MTLCopyAllDevices()
    precondition(devices.count == 1)
    precondition(device.name == "OpenUIKit CPU Reference")
    precondition(device.hasUnifiedMemory)
    precondition(device.architecture.name == "cpu")
    precondition(!device.supportsFamily(.apple1))
    precondition(!device.supportsFamily(.metal3))
    precondition(!device.supportsFeatureSet(.iOS_GPUFamily1_v1))
    precondition(device.supportsTextureSampleCount(1))
    precondition(!device.supportsTextureSampleCount(4))
    precondition(!device.supportsRaytracing)
    precondition(device.minimumLinearTextureAlignment(for: .rgba8Unorm) == 16)
    precondition(device.minimumTextureBufferAlignment(for: .rgba8Unorm) == 16)
    let sized = device.heapBufferSizeAndAlign(length: 17, options: [])
    precondition(sized.size >= 17 && sized.align == 16)
    precondition(device.makeDefaultLibrary() == nil)
    let queue = device.makeCommandQueue()
    precondition(queue != nil)
    precondition(queue?.device.name == device.name)
    precondition(device.makeCommandQueue(maxCommandBufferCount: 8) != nil)
    precondition(device.makeCommandQueue(descriptor: MTLCommandQueueDescriptor()) != nil)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: false
    )
    precondition(descriptor.pixelFormat == .rgba8Unorm)
    precondition(descriptor.usage.contains(.shaderRead))
    let sampler = MTLSamplerDescriptor()
    sampler.minFilter = .linear
    sampler.sAddressMode = .clampToEdge
    precondition(device.makeSamplerState(descriptor: sampler) != nil)
    let depth = MTLDepthStencilDescriptor()
    depth.isDepthWriteEnabled = true
    depth.depthCompareFunction = .less
    depth.frontFaceStencil.stencilCompareFunction = .always
    precondition(device.makeDepthStencilState(descriptor: depth) != nil)
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
    precondition(pass.colorAttachments[0].loadAction == .clear)
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipeline.shaderValidation = .disabled
    pipeline.reset()
    precondition(pipeline.colorAttachments[0].pixelFormat == .invalid)
    let vertex = MTLVertexDescriptor()
    vertex.attributes[0].format = .float3
    vertex.attributes[0].offset = 0
    vertex.layouts[0].stride = 12
    vertex.reset()
    precondition(vertex.attributes[0].format == .invalid)
}

func exerciseBuffersAndBlit() {
    let device = MTLCreateSystemDefaultDevice()!
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let source = bytes.withUnsafeBytes { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: bytes.count, options: .storageModeShared)!
    }
    precondition(source.length == 5)
    precondition(source.contents().load(as: UInt8.self) == 1)
    source.didModifyRange(0..<5)
    let destination = device.makeBuffer(length: 8, options: [])!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    precondition(commandBuffer.status == .notEnqueued)
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
    let encoder = commandBuffer.makeBlitCommandEncoder()!
    encoder.copy(
        from: source,
        sourceOffset: 0,
        to: destination,
        destinationOffset: 1,
        size: 5
    )
    encoder.fill(buffer: destination, range: 6..<8, value: 0xAB)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(commandBuffer.status == .completed)
    precondition(completed)
    precondition(seen == [.scheduled, .completed])
    let destBytes = UnsafeRawBufferPointer(start: destination.contents(), count: 8)
    precondition(destBytes[0] == 0)
    precondition(destBytes[1] == 1)
    precondition(destBytes[5] == 5)
    precondition(destBytes[6] == 0xAB)
    precondition(destBytes[7] == 0xAB)
    destination.label = "scratch"
    precondition(destination.label == "scratch")
    _ = destination.setPurgeableState(.nonVolatile)
}

func roundTripTexture(_ format: MTLPixelFormat, bytesPerPixel: Int, pattern: [UInt8]) {
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
    pattern.withUnsafeBytes { raw in
        texture.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2 * bytesPerPixel
        )
    }
    var roundTrip = [UInt8](repeating: 0, count: pattern.count)
    roundTrip.withUnsafeMutableBytes { raw in
        texture.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2 * bytesPerPixel,
            from: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0
        )
    }
    precondition(roundTrip == pattern)
}

func exerciseTextures() {
    roundTripTexture(
        .rgba8Unorm,
        bytesPerPixel: 4,
        pattern: [10, 20, 30, 40, 50, 60, 70, 80]
    )
    roundTripTexture(
        .bgra8Unorm,
        bytesPerPixel: 4,
        pattern: [1, 2, 3, 4, 5, 6, 7, 8]
    )
    roundTripTexture(.r8Unorm, bytesPerPixel: 1, pattern: [9, 11])
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
    roundTripTexture(.rgba16Float, bytesPerPixel: 8, pattern: rgba16)
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
    roundTripTexture(.rgba32Float, bytesPerPixel: 16, pattern: rgba32)
    var depth = [UInt8](repeating: 0, count: 8)
    var d1: Float = 0.25
    var d2: Float = 0.75
    withUnsafeBytes(of: &d1) { src in depth.replaceSubrange(0..<4, with: src) }
    withUnsafeBytes(of: &d2) { src in depth.replaceSubrange(4..<8, with: src) }
    roundTripTexture(.depth32Float, bytesPerPixel: 4, pattern: depth)

    let device = MTLCreateSystemDefaultDevice()!
    let invalid = MTLTextureDescriptor()
    invalid.pixelFormat = .invalid
    precondition(device.makeTexture(descriptor: invalid) == nil)
    let zero = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 0, height: 4, mipmapped: false)
    precondition(device.makeTexture(descriptor: zero) == nil)
}

func exerciseMipmapsAndTextureCopy() {
    let device = MTLCreateSystemDefaultDevice()!
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    precondition(descriptor.mipmapLevelCount == 2)
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
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let blit = commandBuffer.makeBlitCommandEncoder()!
    blit.generateMipmaps(for: texture)
    blit.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
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
    precondition(mip[1] == 85)
    precondition(mip[2] == 85)
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
    copyEncoder.endEncoding()
    copyBuffer.commit()
    copyBuffer.waitUntilCompleted()
    var back = [UInt8](repeating: 0, count: 16)
    back.withUnsafeMutableBytes { raw in
        dest.getBytes(
            raw.baseAddress!,
            bytesPerRow: 8,
            from: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0
        )
    }
    precondition(back == pixels)
}

func exerciseComputeKernels() {
    let device = MTLCreateSystemDefaultDevice()!
    let library = MTLMakeCPUBuiltinLibrary(device)
    precondition(library.functionNames.contains(MTLCPUBuiltinKernel.fillUInt32.rawValue))
    let fill = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let pipeline = try! device.makeComputePipelineState(function: fill)
    let buffer = device.makeBuffer(length: 16, options: [])!
    var constant: UInt32 = 0xA1B2C3D4
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(pipeline)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    withUnsafeBytes(of: &constant) { raw in
        encoder.setBytes(raw.baseAddress!, length: 4, index: 1)
    }
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
    let addEncoder = addBuffer.makeComputeCommandEncoder()!
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
    let copyCB = queue.makeCommandBuffer()!
    let copyEnc = copyCB.makeComputeCommandEncoder()!
    copyEnc.setComputePipelineState(copyPipeline)
    copyEnc.setBuffer(src, offset: 0, index: 0)
    copyEnc.setBuffer(dst, offset: 0, index: 1)
    copyEnc.dispatchThreadgroups(MTLSizeMake(3, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    copyEnc.endEncoding()
    copyCB.commit()
    copyCB.waitUntilCompleted()
    precondition(dst.contents().load(as: UInt8.self) == 9)
    precondition(dst.contents().advanced(by: 1).load(as: UInt8.self) == 8)
    precondition(dst.contents().advanced(by: 2).load(as: UInt8.self) == 7)
    precondition(library.makeFunction(name: "kernel void k()") == nil)
}

func exerciseRenderPassClear() {
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
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
    encoder.setRenderPipelineState(state)
    encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: 2, height: 1, znear: 0, zfar: 1))
    encoder.setCullMode(.back)
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    var pixels = [UInt8](repeating: 0, count: 8)
    pixels.withUnsafeMutableBytes { raw in
        color.getBytes(raw.baseAddress!, bytesPerRow: 8, from: MTLRegionMake2D(0, 0, 2, 1), mipmapLevel: 0)
    }
    precondition(pixels == [255, 0, 0, 255, 255, 0, 0, 255])

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

func exerciseHeapsEventsAndFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let heapDesc = MTLHeapDescriptor()
    heapDesc.size = 4096
    heapDesc.storageMode = .shared
    let heap = device.makeHeap(descriptor: heapDesc)!
    precondition(heap.size == 4096)
    let heapBuffer = heap.makeBuffer(length: 32, options: .storageModeShared)!
    precondition(heapBuffer.heap != nil)
    precondition(heapBuffer.length == 32)
    let fence = device.makeFence()!
    let event = device.makeEvent()!
    fence.label = "cpu-fence"
    event.label = "cpu-event"
    precondition(fence.device.name == device.name)

    do {
        _ = try device.makeLibrary(source: "kernel void k() {}", options: nil)
        fatalError("shader compilation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeLibrary(URL: URL(fileURLWithPath: "/tmp/missing.metallib"))
        fatalError("metallib loading must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
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

    let capture = MTLCaptureManager.shared()
    precondition(!capture.supportsDestination(.developerTools))
    do {
        try capture.startCapture(with: MTLCaptureDescriptor())
        fatalError("GPU capture must fail closed")
    } catch let error as MTLCaptureError {
        precondition(error == .notSupported)
    } catch {
        fatalError("expected MTLCaptureError")
    }
    capture.stopCapture()
    precondition(!capture.isCapturing)

    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.dataType = .float
    argument.index = 0
    let encoder = device.makeArgumentEncoder(arguments: [argument])!
    precondition(encoder.encodedLength == 0)
    encoder.setBuffer(heapBuffer, offset: 0, index: 0)
    _ = encoder.constantData(at: 0)

    let icb = MTLIndirectCommandBufferDescriptor()
    icb.commandTypes = [.draw]
    precondition(device.makeIndirectCommandBuffer(descriptor: icb, maxCommandCount: 4, options: []) == nil)
}

func exerciseMetalKitLookalikeSurface() {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("CPU reference device must exist")
    }
    _ = device.name
    let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm,
        width: 48,
        height: 24,
        mipmapped: false
    )
    colorDescriptor.usage = [.shaderRead, .renderTarget]
    colorDescriptor.storageMode = .shared
    colorDescriptor.sampleCount = 1
    let color = device.makeTexture(descriptor: colorDescriptor)!
    precondition(color.pixelFormat == .bgra8Unorm)
    precondition(color.width == 48 && color.height == 24)
    precondition(color.usage.contains(.renderTarget))
    precondition(color.storageMode == .shared)

    let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .depth32Float,
        width: 48,
        height: 24,
        mipmapped: false
    )
    depthDescriptor.usage = .renderTarget
    depthDescriptor.storageMode = .private
    let depth = device.makeTexture(descriptor: depthDescriptor)!
    precondition(depth.pixelFormat == .depth32Float)
    precondition(depth.storageMode == .private)

    let buffer = device.makeBuffer(length: 16, options: .cpuCacheModeDefaultCache)!
    precondition(buffer.length == 16)
    _ = device.makeBuffer(length: 4, options: .storageModeShared)
    _ = device.makeBuffer(length: 4, options: .storageModePrivate)

    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = color
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    pass.renderTargetWidth = 48
    pass.renderTargetHeight = 24
    pass.depthAttachment.texture = depth
    pass.depthAttachment.loadAction = .clear
    pass.depthAttachment.storeAction = .store
    pass.depthAttachment.clearDepth = 1
    pass.stencilAttachment.clearStencil = 0
    precondition(pass.colorAttachments[0].clearColor.alpha == 1)

    let metal4: MTL4RenderPassDescriptor? = MTL4RenderPassDescriptor()
    precondition(metal4 != nil)
    _ = MTLPixelFormat.invalid
    _ = MTLPixelFormat.a8Unorm
    _ = MTLPixelFormat.r8Unorm
    _ = MTLPixelFormat.rgba8Unorm
    _ = MTLPixelFormat.bgra8Unorm_srgb
    _ = MTLPixelFormat.stencil8
    _ = MTLPixelFormat.depth32Float_stencil8
    _ = MTLTextureUsage.unknown
    _ = MTLTextureUsage.pixelFormatView
    _ = MTLLoadAction.dontCare
    _ = MTLStoreAction.multisampleResolve
    _ = MTLStorageMode.memoryless
}

exerciseGeometry()
exercisePixelFormatsAndOptions()
exerciseSoftwareDevice()
exerciseBuffersAndBlit()
exerciseTextures()
exerciseMipmapsAndTextureCopy()
exerciseComputeKernels()
exerciseRenderPassClear()
exerciseHeapsEventsAndFailClosed()
exerciseMetalKitLookalikeSurface()
print("METAL_AGENT_RUNTIME_OK")
