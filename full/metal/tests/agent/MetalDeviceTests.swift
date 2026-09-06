import Dispatch
import Foundation
import Metal

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
    do {
        _ = try device.makeCounterSampleBuffer(descriptor: counterDesc)
        fatalError("counter sample buffer must fail closed")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("counter"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
}
