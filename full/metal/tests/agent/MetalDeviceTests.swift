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
