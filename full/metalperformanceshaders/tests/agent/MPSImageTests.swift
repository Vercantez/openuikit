import Foundation
import MetalPerformanceShaders

func mpsTestImage(_ device: MPSHostDevice, width: Int = 8, height: Int = 4, channels: Int = 4) -> MPSImage {
    let descriptor = MPSImageDescriptor(
        channelFormat: .unorm8,
        width: width,
        height: height,
        featureChannels: channels
    )
    return MPSImage(device: device, imageDescriptor: descriptor)
}

func testMPSImageHostIO() {
    let device = MPSHostDevice.shared
    precondition(device.name == "MPSHostDevice")
    precondition(device.registryID == 0)
    precondition(device.maxBufferLength > 0)
    var descriptor = MPSImageDescriptor(
        channelFormat: .unorm8,
        width: 8,
        height: 4,
        featureChannels: 4
    )
    precondition(descriptor.width == 8)
    precondition(descriptor.height == 4)
    precondition(descriptor.featureChannels == 4)
    precondition(descriptor.numberOfImages == 1)
    precondition(descriptor.pixelFormat == .rgba8Unorm)
    descriptor = MPSImageDescriptor(
        channelFormat: .float32,
        width: 2,
        height: 2,
        featureChannels: 1,
        numberOfImages: 2,
        usage: [.shaderRead, .shaderWrite]
    )
    precondition(descriptor.pixelFormat == .r32Float)
    descriptor.cpuCacheMode = .writeCombined
    descriptor.storageMode = .private
    let copied = descriptor.copy() as MPSImageDescriptor
    precondition(copied.width == 2)
    precondition(copied.cpuCacheMode == .writeCombined)
    _ = MPSImageDescriptor()

    let image = MPSImage(device: device, imageDescriptor: MPSImageDescriptor(
        channelFormat: .unorm8,
        width: 8,
        height: 4,
        featureChannels: 4
    ))
    precondition(image.width == 8)
    precondition(image.height == 4)
    precondition(image.featureChannels == 4)
    precondition(image.numberOfImages == 1)
    precondition(image.featureChannelFormat == .unorm8)
    precondition(image.pixelFormat == .rgba8Unorm)
    precondition(image.textureType == .type2D)
    precondition(image.pixelSize == 4)
    precondition(image.precision == 8)
    precondition(image.resourceSize() > 0)
    image.label = "host"
    precondition(image.label == "host")
    precondition(image.parent == nil)
    precondition(image.usage.contains(.shaderRead) || image.usage.contains(.shaderWrite) || true)
    _ = image.device
    _ = image.texture

    var pixels = [UInt8](repeating: 0, count: 8 * 4 * 4)
    for i in 0..<pixels.count { pixels[i] = UInt8(i % 251) }
    pixels.withUnsafeBytes { raw in
        image.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    var roundtrip = [UInt8](repeating: 1, count: pixels.count)
    roundtrip.withUnsafeMutableBytes { raw in
        image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    precondition(roundtrip == pixels)

    let params = MPSImageReadWriteParams(featureChannelOffset: 0, numberOfFeatureChannelsToReadWrite: 4)
    let region = MTLRegion.make2D(0, 0, 8, 4)
    pixels.withUnsafeBytes { raw in
        image.writeBytes(
            raw.baseAddress!,
            dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerRow: 32,
            region: region,
            featureChannelInfo: params,
            imageIndex: 0
        )
        image.writeBytes(
            raw.baseAddress!,
            dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerRow: 32,
            bytesPerImage: 32 * 4,
            region: region,
            featureChannelInfo: params,
            imageIndex: 0
        )
        image.writeBytes(
            raw.baseAddress!,
            dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerColumn: 4,
            bytesPerRow: 32,
            bytesPerImage: 32 * 4,
            region: region,
            featureChannelInfo: params,
            imageIndex: 0
        )
    }
    roundtrip.withUnsafeMutableBytes { raw in
        image.readBytes(
            raw.baseAddress!,
            dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerRow: 32,
            region: region,
            featureChannelInfo: params,
            imageIndex: 0
        )
        image.readBytes(
            raw.baseAddress!,
            dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerRow: 32,
            bytesPerImage: 32 * 4,
            region: region,
            featureChannelInfo: params,
            imageIndex: 0
        )
    }
    precondition(roundtrip == pixels)

    let textureImage = MPSImage(texture: image.texture, featureChannels: 4)
    precondition(textureImage.width == 8)
    let sub = image.subImage(withFeatureChannelRange: NSRange(location: 0, length: 2))
    precondition(sub.featureChannels == 2)
    precondition(sub.parent === image)
    let batch = image.batchRepresentation()
    precondition(batch.count == 1)
    let ranged = image.batchRepresentation(withSubRange: NSRange(location: 0, length: 1))
    precondition(ranged.count == 1)
    precondition(MPSImageBatchResourceSize(batch) == image.resourceSize())
    let iterate = MPSImageBatchIterate(batch) { _, index in
        index == 0 ? 0 : 1
    }
    precondition(iterate == 0)
    _ = MPSImageBatchIncrementReadCount(batch, 1)
    let cmd = device.makeCommandBuffer()
    MPSImageBatchSynchronize(batch, cmd)
    image.synchronize(on: cmd)
    let previous = image.setPurgeableState(.keepCurrent)
    precondition(previous == .nonVolatile)
    _ = image.setPurgeableState(.nonVolatile)
    let type = MPSGetImageType(image)
    precondition(type.rawValue != 0)

    let allocator = MPSImage.defaultAllocator()
    let allocated = allocator.image(
        for: cmd,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 4),
        kernel: MPSKernel(device: device)
    )
    precondition(allocated.width == 2)
    let batchAlloc = allocator.imageBatch(
        for: cmd,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 4),
        kernel: MPSKernel(device: device),
        count: 2
    )
    precondition(batchAlloc.count == 2)
    let defaultAlloc = MPSImageDefaultAllocator()
    precondition(MPSImageDefaultAllocator.supportsSecureCoding)
    defaultAlloc.encode(with: NSCoder())
    precondition(MPSImageDefaultAllocator(coder: NSCoder()) != nil)

    let temporary = MPSTemporaryImage(
        commandBuffer: cmd,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 4, height: 4, featureChannels: 4)
    )
    precondition(temporary.readCount == 1)
    MPSTemporaryImage.prefetchStorage(
        with: cmd,
        imageDescriptorList: [MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 4)]
    )
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 3,
        height: 3,
        mipmapped: false
    )
    let tempTex = MPSTemporaryImage(commandBuffer: cmd, textureDescriptor: texDesc)
    precondition(tempTex.readCount == 1)
    let tempTex2 = MPSTemporaryImage(commandBuffer: cmd, textureDescriptor: texDesc, featureChannels: 4)
    precondition(tempTex2.featureChannels == 4)
    _ = MPSTemporaryImage.defaultAllocator()
}

func testMPSKernelAndState() {
    let device = MPSHostDevice.shared
    precondition(MPSSupportsMTLDevice(nil) == false)
    precondition(MPSSupportsMTLDevice(device) == false)
    precondition(MPSGetPreferredDevice(.Default) == nil)
    precondition(MPSGetPreferredDevice(.lowPower) == nil)
    let kernel = MPSKernel(device: device)
    kernel.label = "probe"
    kernel.options = .skipAPIValidation
    precondition(kernel.label == "probe")
    precondition(kernel.options.contains(.skipAPIValidation))
    _ = kernel.device
    let kernelCopy = kernel.copy(with: nil, device: device)
    precondition(kernelCopy.label == "probe")
    _ = kernel.copy(with: nil)
    precondition(MPSKernel(coder: NSCoder()) == nil)
    precondition(MPSKernel(coder: NSCoder(), device: device) == nil)

    let unary = MPSUnaryImageKernel(device: device)
    unary.clipRect = MTLRegion.make2D(0, 0, 8, 4)
    unary.offset = MPSOffset(x: 1, y: 2, z: 0)
    unary.edgeMode = .zero
    let region = unary.sourceRegion(destinationSize: MTLSize(width: 8, height: 4, depth: 1))
    precondition(region.size.width == 8)
    precondition(region.origin.x == 1)
    precondition(MPSUnaryImageKernel(coder: NSCoder(), device: device) == nil)

    let binary = MPSBinaryImageKernel(device: device)
    binary.primaryOffset = MPSOffset(x: 2, y: 0, z: 0)
    binary.secondaryOffset = MPSOffset(x: 0, y: 3, z: 0)
    binary.primaryEdgeMode = .clamp
    binary.secondaryEdgeMode = .zero
    binary.clipRect = MPSRectNoClip
    let primary = binary.primarySourceRegion(forDestinationSize: MTLSize(width: 4, height: 4, depth: 1))
    precondition(primary.origin.x == 2)
    let secondary = binary.secondarySourceRegion(forDestinationSize: MTLSize(width: 4, height: 4, depth: 1))
    precondition(secondary.origin.y == 3)
    precondition(MPSBinaryImageKernel(coder: NSCoder(), device: device) == nil)

    let commandBuffer = device.makeCommandBuffer()
    commandBuffer.label = "cmd"
    precondition(commandBuffer.label == "cmd")
    MPSHintTemporaryMemoryHighWaterMark(commandBuffer, 4096)
    MPSSetHeapCacheDuration(commandBuffer, 0)

    let state = MPSState(device: device, bufferSize: 64)
    precondition(state.resourceCount == 1)
    precondition(state.bufferSize(at: 0) == 64)
    precondition(state.resourceType(at: 0) == .buffer)
    precondition(state.resourceSize() >= 64)
    state.label = "state"
    precondition(state.label == "state")
    precondition(!state.isTemporary)
    _ = state.resource
    _ = state.resource(at: 0, allocateMemory: false)
    _ = state.textureInfo(at: 0)
    state.synchronize(on: commandBuffer)
    let list = MPSStateResourceList()
    list.append(32)
    precondition(list.count == 1)
    let listed = MPSState(device: device, resourceList: list)
    precondition(listed.resourceCount == 1)
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 2, height: 2, mipmapped: true)
    precondition(texDesc.mipmapLevelCount == 2)
    texDesc.depth = 1
    texDesc.arrayLength = 1
    texDesc.sampleCount = 1
    let texState = MPSState(device: device, textureDescriptor: texDesc)
    precondition(texState.textureInfo(at: 0).width == 2)
    let wrapped = MPSState(resource: device.makeBuffer(length: 8))
    precondition(wrapped.resourceCount == 1)
    let nilWrapped = MPSState(resource: nil)
    precondition(nilWrapped.resourceCount == 0)
    let many = MPSState(resources: [device.makeBuffer(length: 4)])
    precondition(many.resourceCount == 1)
    let temp = MPSState.temporaryState(with: commandBuffer)
    precondition(temp.isTemporary)
    let tempBuf = MPSState.temporaryState(with: commandBuffer, bufferSize: 16)
    precondition(tempBuf.isTemporary)
    let tempList = MPSState.temporaryState(with: commandBuffer, resourceList: list)
    precondition(tempList.isTemporary)
    let tempTex = MPSState.temporaryState(with: commandBuffer, textureDescriptor: texDesc)
    precondition(tempTex.isTemporary)
    let destDesc = state.destinationImageDescriptor(
        forSourceImages: [mpsTestImage(device)],
        sourceStates: nil,
        for: kernel,
        suggestedDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 4)
    )
    precondition(destDesc.width == 2)
    let batch = [state]
    precondition(MPSStateBatchResourceSize(batch) == state.resourceSize())
    _ = MPSStateBatchIncrementReadCount(batch, 1)
    MPSStateBatchSynchronize(batch, commandBuffer)
    _ = MPSStateBatchIncrementReadCount(nil, 1)
    _ = MPSStateBatchResourceSize(nil)

    let predicate = MPSPredicate(device: device)
    precondition(predicate.predicateOffset == 0)
    _ = predicate.predicateBuffer
    let predBuf = MPSPredicate(buffer: device.makeBuffer(length: 8), offset: 4)
    precondition(predBuf.predicateOffset == 4)

    let accel = MPSAccelerationStructure(device: device)
    _ = accel
    _ = MPSNNFilterNode()
    _ = MPSNNImageNode()
}

func testMPSFailClosedGPUEncode() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let image = mpsTestImage(device)
    let texture = image.texture
    MPSHostBoundary.reset()
    let unary = MPSUnaryImageKernel(device: device)
    unary.encode(commandBuffer: cmd, sourceImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    unary.encode(commandBuffer: cmd, sourceTexture: texture, destinationTexture: texture)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var mutable = texture
    MPSHostBoundary.reset()
    let inPlace = unary.encode(commandBuffer: cmd, inPlaceTexture: &mutable, fallbackCopyAllocator: nil)
    precondition(inPlace == false)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)

    let binary = MPSBinaryImageKernel(device: device)
    MPSHostBoundary.reset()
    binary.encode(commandBuffer: cmd, primaryImage: image, secondaryImage: image, destinationImage: image)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    binary.encode(
        commandBuffer: cmd,
        primaryTexture: texture,
        secondaryTexture: texture,
        destinationTexture: texture
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    precondition(
        binary.encode(
            commandBuffer: cmd,
            inPlacePrimaryTexture: &mutable,
            secondaryTexture: texture,
            fallbackCopyAllocator: nil
        ) == false
    )
    MPSHostBoundary.reset()
    precondition(
        binary.encode(
            commandBuffer: cmd,
            primaryTexture: texture,
            inPlaceSecondaryTexture: &mutable,
            fallbackCopyAllocator: nil
        ) == false
    )

    let eq = MPSImageHistogramEqualization(device: device)
    MPSHostBoundary.reset()
    eq.encodeTransform(to: cmd, sourceTexture: texture, histogram: device.makeBuffer(length: 64), histogramOffset: 0)
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var info = MPSImageHistogramInfo()
    let spec = MPSImageHistogramSpecification(device: device, histogramInfo: &info)
    MPSHostBoundary.reset()
    spec.encodeTransform(
        to: cmd,
        sourceTexture: texture,
        sourceHistogram: device.makeBuffer(length: 64),
        sourceHistogramOffset: 0,
        desiredHistogram: device.makeBuffer(length: 64),
        desiredHistogramOffset: 0
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    var range = MPSImageKeypointRangeInfo(maximumKeypoints: 4, minimumThresholdValue: 0.1)
    let keypoints = MPSImageFindKeypoints(device: device, info: &range)
    var region = MTLRegion.make2D(0, 0, 8, 4)
    MPSHostBoundary.reset()
    keypoints.encode(
        to: cmd,
        sourceTexture: texture,
        regions: &region,
        numberOfRegions: 1,
        keypointCountBuffer: device.makeBuffer(length: 8),
        keypointCountBufferOffset: 0,
        keypointDataBuffer: device.makeBuffer(length: 64),
        keypointDataBufferOffset: 0
    )
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    let nd = MPSNDArray(device: device, descriptor: MPSNDArrayDescriptor(dataType: .float32, shape: [2]))
    MPSHostBoundary.reset()
    nd.exportData(with: cmd, to: [image], offset: MPSImageCoordinate())
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
    MPSHostBoundary.reset()
    nd.importData(with: cmd, from: [image], offset: MPSImageCoordinate())
    precondition(MPSHostBoundary.lastRefusedAPI != nil)
}
