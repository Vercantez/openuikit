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
}

func exercisePixelFormatsAndOptions() {
    precondition(MTLPixelFormat.rgba8Unorm.rawValue == 70)
    precondition(MTLPixelFormat.bgra8Unorm.rawValue == 80)
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
    let libraryError = MTLLibraryError(.unsupported)
    precondition(libraryError.code == .unsupported)
    precondition(MTLLibraryError.unsupported ~= libraryError)
    precondition(MTLCommandBufferError.accessRevoked == .blacklisted)
    precondition(MTLResourceCPUCacheModeShift == 0)
    precondition(MTLResourceStorageModeShift == 4)
    precondition(MTLCounterDontSample == -1)
}

func exerciseSoftwareDevice() {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("software device must exist")
    }
    let devices = MTLCopyAllDevices()
    precondition(devices.count == 1)
    precondition(device.name == "OpenUIKit Software Metal")
    precondition(device.hasUnifiedMemory)
    precondition(device.architecture.name == "cpu")
    precondition(!device.supportsFamily(.apple1))
    precondition(!device.supportsFamily(.metal3))
    precondition(!device.supportsFeatureSet(.iOS_GPUFamily1_v1))
    precondition(device.supportsTextureSampleCount(1))
    precondition(!device.supportsTextureSampleCount(4))
    precondition(!device.supportsRaytracing)
    precondition(device.minimumLinearTextureAlignment(for: .rgba8Unorm) == 16)
    let sized = device.heapBufferSizeAndAlign(length: 17, options: [])
    precondition(sized.size >= 17 && sized.align == 16)
    precondition(device.makeDefaultLibrary() == nil)
    let queue = device.makeCommandQueue()
    precondition(queue != nil)
    precondition(queue?.device.name == device.name)
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
    precondition(device.makeSamplerState(descriptor: sampler) != nil)
    let depth = MTLDepthStencilDescriptor()
    depth.isDepthWriteEnabled = true
    precondition(device.makeDepthStencilState(descriptor: depth) != nil)
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
    precondition(pass.colorAttachments[0].loadAction == .clear)
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipeline.reset()
    precondition(pipeline.colorAttachments[0].pixelFormat == .invalid)
}

func exerciseBuffersAndBlit() {
    let device = MTLCreateSystemDefaultDevice()!
    let bytes: [UInt8] = [1, 2, 3, 4, 5]
    let source = bytes.withUnsafeBytes { raw in
        device.makeBuffer(bytes: raw.baseAddress!, length: bytes.count, options: .storageModeShared)!
    }
    precondition(source.length == 5)
    precondition(source.contents().load(as: UInt8.self) == 1)
    let destination = device.makeBuffer(length: 8, options: [])!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    precondition(commandBuffer.status == .notEnqueued)
    var completed = false
    commandBuffer.addCompletedHandler { buffer in
        precondition(buffer.status == .completed)
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

func exerciseTextures() {
    let device = MTLCreateSystemDefaultDevice()!
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 1,
        mipmapped: false
    )
    let texture = device.makeTexture(descriptor: descriptor)!
    precondition(texture.width == 2)
    precondition(texture.pixelFormat == .rgba8Unorm)
    let pixels: [UInt8] = [10, 20, 30, 40, 50, 60, 70, 80]
    pixels.withUnsafeBytes { raw in
        texture.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8
        )
    }
    var roundTrip = [UInt8](repeating: 0, count: 8)
    roundTrip.withUnsafeMutableBytes { raw in
        texture.getBytes(
            raw.baseAddress!,
            bytesPerRow: 8,
            from: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0
        )
    }
    precondition(roundTrip == pixels)
    precondition(texture.makeTextureView(pixelFormat: .rgba8Unorm) != nil)
}

func exerciseFailClosedGPU() {
    let device = MTLCreateSystemDefaultDevice()!
    do {
        _ = try device.makeLibrary(source: "kernel void k() {}", options: nil)
        fatalError("shader compilation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .unsupported)
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
}

/// Call the Metal APIs MetalKit product sources use through lookalikes
/// (`MTKView`, `MTKTextureLoader`) so a later integration compile cannot
/// silently drop those signatures.
func exerciseMetalKitLookalikeSurface() {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("software device must exist")
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
exerciseFailClosedGPU()
exerciseMetalKitLookalikeSurface()
print("METAL_AGENT_RUNTIME_OK")
