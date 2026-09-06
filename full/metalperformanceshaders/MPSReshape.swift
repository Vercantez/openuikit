import Foundation

// Reject malformed/overflowing shapes before allocating or touching a destination.
// The tests use 2*3 == 3*2 and deliberately reject 2*4, zero, negative and
// Int.max*2 dimensions; no tolerance or score-fitted parameter is involved.
private func mpsReshapeElementCount(_ dimensions: [Int]) -> Int? {
    guard !dimensions.isEmpty, dimensions.count <= 16 else { return nil }
    var count = 1
    for dimension in dimensions {
        guard dimension > 0 else { return nil }
        let product = count.multipliedReportingOverflow(by: dimension)
        guard !product.overflow else { return nil }
        count = product.partialValue
    }
    return count
}

open class MPSNDArrayIdentity: MPSNDArrayUnaryKernel {
    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        precondition(count == 1, "An identity kernel has exactly one source")
        super.init(device: device, sourceCount: count)
    }

    public func reshape(
        with cmdBuf: (any MTLCommandBuffer)?, sourceArray: MPSNDArray,
        shape: [NSNumber], destinationArray: MPSNDArray?
    ) -> MPSNDArray? {
        guard shape.allSatisfy({ NSNumber(value: $0.intValue) == $0 }) else { return refuseReshape() }
        return reshapeHost(commandBuffer: cmdBuf, source: sourceArray,
                           sizes: shape.map { $0.intValue }, destination: destinationArray)
    }

    public func reshape(
        with cmdBuf: (any MTLCommandBuffer)?, sourceArray: MPSNDArray,
        dimensionCount numberOfDimensions: Int, dimensionSizes: UnsafeMutablePointer<Int>,
        destinationArray: MPSNDArray?
    ) -> MPSNDArray? {
        guard (1...16).contains(numberOfDimensions) else { return refuseReshape() }
        return reshapeHost(commandBuffer: cmdBuf, source: sourceArray,
                           sizes: Array(UnsafeBufferPointer(start: dimensionSizes, count: numberOfDimensions)),
                           destination: destinationArray)
    }

    public func reshape(
        with encoder: (any MTLComputeCommandEncoder)?, commandBuffer cmdBuf: (any MTLCommandBuffer)?,
        sourceArray: MPSNDArray, shape: [NSNumber], destinationArray: MPSNDArray?
    ) -> MPSNDArray? {
        guard encoder == nil else { return refuseReshape() }
        return reshape(with: cmdBuf, sourceArray: sourceArray, shape: shape, destinationArray: destinationArray)
    }

    public func reshape(
        with encoder: (any MTLComputeCommandEncoder)?, commandBuffer cmdBuf: (any MTLCommandBuffer)?,
        sourceArray: MPSNDArray, dimensionCount numberOfDimensions: Int,
        dimensionSizes: UnsafeMutablePointer<Int>, destinationArray: MPSNDArray?
    ) -> MPSNDArray? {
        guard encoder == nil else { return refuseReshape() }
        return reshape(with: cmdBuf, sourceArray: sourceArray, dimensionCount: numberOfDimensions,
                       dimensionSizes: dimensionSizes, destinationArray: destinationArray)
    }

    private func refuseReshape() -> MPSNDArray? {
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayIdentity.reshape")
        return nil
    }

    private func reshapeHost(
        commandBuffer: (any MTLCommandBuffer)?, source: MPSNDArray,
        sizes: [Int], destination: MPSNDArray?
    ) -> MPSNDArray? {
        let sourceSizes = (0..<source.numberOfDimensions).map { source.length(ofDimension: $0) }
        guard source.device === device,
              commandBuffer == nil || commandBuffer?.device === device,
              let count = mpsReshapeElementCount(sizes),
              mpsReshapeElementCount(sourceSizes) == count else { return refuseReshape() }
        let bytes = count.multipliedReportingOverflow(by: source.dataTypeSize)
        guard !bytes.overflow, bytes.partialValue == source.resourceSize() else { return refuseReshape() }
        guard let destination else { return source.hostReshapedView(sizes: sizes) }
        // Without a command buffer only a view may be produced. An explicit
        // destination requires a copy, even on this synchronous CPU backend.
        guard commandBuffer != nil, destination.device === device,
              destination.dataType == source.dataType,
              destination.numberOfDimensions == sizes.count,
              destination.resourceSize() == bytes.partialValue,
              sizes.enumerated().allSatisfy({ destination.length(ofDimension: $0.offset) == $0.element })
        else { return refuseReshape() }
        var snapshot = Data(count: bytes.partialValue)
        snapshot.withUnsafeMutableBytes { raw in
            source.readBytes(raw.baseAddress!, strideBytes: nil)
            destination.writeBytes(raw.baseAddress!, strideBytes: nil)
        }
        return destination
    }

    open override func encode(
        to cmdBuf: any MTLCommandBuffer, sourceArrays: [MPSNDArray], destinationArray destination: MPSNDArray
    ) {
        guard sourceArrays.count == 1 else {
            MPSHostBoundary.refuseGPUEncode("MPSNDArrayIdentity.encode")
            return
        }
        _ = reshape(with: cmdBuf, sourceArray: sourceArrays[0], shape: destination.descriptor().getShape(),
                    destinationArray: destination)
    }
}

open class MPSNNReshape: MPSCNNKernel {
    public required init(device: any MTLDevice) { super.init(device: device) }
    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) { return nil }

    private func accepts(_ source: MPSImage, width: Int, height: Int, channels: Int) -> Bool {
        guard source.device === device, source.numberOfImages == 1,
              source.parent == nil,
              let count = mpsReshapeElementCount([width, height, channels]),
              mpsReshapeElementCount([source.width, source.height, source.featureChannels]) == count,
              offset.x == 0, offset.y == 0, offset.z == 0,
              clipRect == MPSRectNoClip, sourceFeatureChannelOffset == 0,
              destinationFeatureChannelOffset == 0, sourceFeatureChannelMaxCount == Int.max
        else { return false }
        guard source.featureChannelFormat == .unorm8 || source.featureChannelFormat == .float16
            || source.featureChannelFormat == .float32 else { return false }
        let byteCount = count.multipliedReportingOverflow(by: mpsHostBytesPerChannel(source.featureChannelFormat))
        return !byteCount.overflow && byteCount.partialValue <= source.mpsHostStorageCount()
    }

    open override func encode(
        commandBuffer: any MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage
    ) {
        guard commandBuffer.device === device, destinationImage.device === device,
              destinationImage.numberOfImages == 1, destinationImage.parent == nil,
              sourceImage.featureChannelFormat == destinationImage.featureChannelFormat,
              accepts(sourceImage, width: destinationImage.width, height: destinationImage.height,
                      channels: destinationImage.featureChannels),
              accepts(destinationImage, width: sourceImage.width, height: sourceImage.height,
                      channels: sourceImage.featureChannels) else {
            MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encode")
            return
        }
        // The packed HWC stream [1,2,3,4,5,6] at 2x1x3 becomes
        // 3x2x1 without transposing channels. Padding lanes are never copied.
        let count = sourceImage.width * sourceImage.height * sourceImage.featureChannels
        var bytes = Data(count: count * mpsHostBytesPerChannel(sourceImage.featureChannelFormat))
        bytes.withUnsafeMutableBytes { raw in
            sourceImage.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
            destinationImage.writeBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
        }
    }

    public func encode(
        commandBuffer: any MTLCommandBuffer, sourceImage: MPSImage,
        reshapedWidth: Int, reshapedHeight: Int, reshapedFeatureChannels: Int
    ) -> MPSImage {
        guard commandBuffer.device === device,
              accepts(sourceImage, width: reshapedWidth, height: reshapedHeight, channels: reshapedFeatureChannels)
        else {
            MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encode")
            return sourceImage
        }
        let descriptor = MPSImageDescriptor(channelFormat: sourceImage.featureChannelFormat,
            width: reshapedWidth, height: reshapedHeight, featureChannels: reshapedFeatureChannels)
        let destination = destinationImageAllocator.image(for: commandBuffer, imageDescriptor: descriptor, kernel: self)
        encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: destination)
        return destination
    }

    public func encode(
        commandBuffer: any MTLCommandBuffer, sourceImage: MPSImage,
        destinationState outState: AutoreleasingUnsafeMutablePointer<MPSState?>,
        destinationStateIsTemporary isTemporary: Bool,
        reshapedWidth: Int, reshapedHeight: Int, reshapedFeatureChannels: Int
    ) -> MPSImage {
        _ = isTemporary
        outState.pointee = nil
        // Gradient-state production needs an oracle. Refuse the entire operation.
        _ = (commandBuffer, reshapedWidth, reshapedHeight, reshapedFeatureChannels)
        MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encode(destinationState:)")
        return sourceImage
    }

    open override func encodeBatch(
        commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage], destinationImages: [MPSImage]
    ) {
        guard commandBuffer.device === device, sourceImages.count == destinationImages.count,
              zip(sourceImages, destinationImages).allSatisfy({ source, destination in
                  source.featureChannelFormat == destination.featureChannelFormat
                      && accepts(source, width: destination.width, height: destination.height, channels: destination.featureChannels)
                      && accepts(destination, width: source.width, height: source.height, channels: source.featureChannels)
              }) else {
            MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encodeBatch")
            return
        }
        for (source, destination) in zip(sourceImages, destinationImages) {
            encode(commandBuffer: commandBuffer, sourceImage: source, destinationImage: destination)
        }
    }

    public func encodeBatch(
        commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage],
        reshapedWidth: Int, reshapedHeight: Int, reshapedFeatureChannels: Int
    ) -> [MPSImage] {
        guard commandBuffer.device === device, sourceImages.allSatisfy({
            accepts($0, width: reshapedWidth, height: reshapedHeight, channels: reshapedFeatureChannels)
        }) else {
            MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encodeBatch")
            return []
        }
        return sourceImages.map {
            encode(commandBuffer: commandBuffer, sourceImage: $0, reshapedWidth: reshapedWidth,
                   reshapedHeight: reshapedHeight, reshapedFeatureChannels: reshapedFeatureChannels)
        }
    }

    public func encodeBatch(
        commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage],
        destinationStates outStates: AutoreleasingUnsafeMutablePointer<NSArray?>,
        destinationStateIsTemporary isTemporary: Bool,
        reshapedWidth: Int, reshapedHeight: Int, reshapedFeatureChannels: Int
    ) -> [MPSImage] {
        _ = (commandBuffer, sourceImages, isTemporary, reshapedWidth, reshapedHeight, reshapedFeatureChannels)
        outStates.pointee = nil
        MPSHostBoundary.refuseGPUEncode("MPSNNReshape.encodeBatch(destinationStates:)")
        return []
    }
}
