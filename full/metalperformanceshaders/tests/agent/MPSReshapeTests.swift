import Foundation
import MetalPerformanceShaders

private func reshapeArray(_ values: [UInt32], sizes: [Int] = [2, 3], type: MPSDataType = .float32) -> MPSNDArray {
    let array = MPSNDArray(device: MPSHostDevice.shared, descriptor: MPSNDArrayDescriptor(dataType: type, sizes: sizes))
    precondition(array.resourceSize() == values.count * MemoryLayout<UInt32>.size)
    var words = values
    words.withUnsafeMutableBytes { array.writeBytes($0.baseAddress!, strideBytes: nil) }
    return array
}

private func reshapeWords(_ array: MPSNDArray) -> [UInt32] {
    var words = [UInt32](repeating: 0, count: array.resourceSize() / 4)
    words.withUnsafeMutableBytes { array.readBytes($0.baseAddress!, strideBytes: nil) }
    return words
}

func testMPSNDArrayIdentityShapeAliasing() {
    let kernel = MPSNDArrayIdentity(device: MPSHostDevice.shared)
    // Signed zero, infinities and a NaN payload must survive bit for bit.
    let bits: [UInt32] = [0x80000000, 0x3f800000, 0x7f800000, 0xff800000, 0x7fc01234, 0x40000000]
    let source = reshapeArray(bits)
    MPSHostBoundary.reset()
    let view = kernel.reshape(with: nil, sourceArray: source, shape: [3, 2], destinationArray: nil)!
    precondition(MPSHostBoundary.lastRefusedAPI == nil)
    precondition(view.parent === source && view.device === source.device)
    precondition(view.numberOfDimensions == 2 && view.length(ofDimension: 0) == 3 && view.length(ofDimension: 1) == 2)
    precondition(view.dataType == .float32 && reshapeWords(view) == bits)
    let chain = kernel.reshape(with: nil, sourceArray: view, shape: [6], destinationArray: nil)!
    var replacement: [UInt32] = [10, 20, 30, 40, 50, 60]
    replacement.withUnsafeMutableBytes { chain.writeBytes($0.baseAddress!, strideBytes: nil) }
    precondition(reshapeWords(source) == replacement && reshapeWords(view) == replacement)
    replacement.reverse()
    replacement.withUnsafeMutableBytes { source.writeBytes($0.baseAddress!, strideBytes: nil) }
    precondition(reshapeWords(chain) == replacement)

    for shape: [NSNumber] in [[2, 4], [0, 6], [-1, 6], [1.5, 4], [], [NSNumber(value: Int.max), 2]] {
        MPSHostBoundary.reset()
        precondition(kernel.reshape(with: nil, sourceArray: source, shape: shape, destinationArray: nil) == nil)
        precondition(MPSHostBoundary.lastRefusedAPI == "MPSNDArrayIdentity.reshape")
        precondition(reshapeWords(source) == replacement)
    }
}

func testMPSNDArrayIdentityDimensionCopy() {
    let device = MPSHostDevice.shared
    let kernel = MPSNDArrayIdentity(device: device)
    let command = device.makeCommandBuffer()
    let bits: [UInt32] = [1, 2, 3, 4, 5, 6]
    let source = reshapeArray(bits)
    let destination = reshapeArray([99, 99, 99, 99, 99, 99], sizes: [3, 2])
    var sizes = [3, 2]
    MPSHostBoundary.reset()
    sizes.withUnsafeMutableBufferPointer {
        let result = kernel.reshape(with: command, sourceArray: source, dimensionCount: 2,
                                    dimensionSizes: $0.baseAddress!, destinationArray: destination)
        precondition(result === destination)
    }
    precondition(MPSHostBoundary.lastRefusedAPI == nil && reshapeWords(destination) == bits)
    var replacement: [UInt32] = [9, 8, 7, 6, 5, 4]
    replacement.withUnsafeMutableBytes { source.writeBytes($0.baseAddress!, strideBytes: nil) }
    precondition(reshapeWords(destination) == bits) // Explicit destinations do not alias.
    sizes.withUnsafeMutableBufferPointer {
        precondition(kernel.reshape(with: nil, sourceArray: source, dimensionCount: 2,
                                    dimensionSizes: $0.baseAddress!, destinationArray: destination) == nil)
        for count in [0, -1, 17] {
            precondition(kernel.reshape(with: command, sourceArray: source, dimensionCount: count,
                                        dimensionSizes: $0.baseAddress!, destinationArray: destination) == nil)
        }
    }
    precondition(reshapeWords(destination) == bits)
    // An equal byte count does not permit a dtype conversion or a wrong shape.
    let wrongType = reshapeArray(bits, sizes: [3, 2], type: .uInt32)
    precondition(kernel.reshape(with: command, sourceArray: source, shape: [3, 2], destinationArray: wrongType) == nil)
    precondition(kernel.reshape(with: command, sourceArray: source, shape: [2, 3], destinationArray: destination) == nil)
    precondition(reshapeWords(destination) == bits && reshapeWords(wrongType) == bits)
}

private final class ReshapeEncoder: MTLComputeCommandEncoder {
    let device: any MTLDevice = MPSHostDevice.shared
    var label: String?
}

func testMPSNDArrayIdentityEncoderShape() {
    let device = MPSHostDevice.shared
    let kernel = MPSNDArrayIdentity(device: device)
    let source = reshapeArray([1, 2, 3, 4, 5, 6])
    let destination = reshapeArray([9, 9, 9, 9, 9, 9], sizes: [6])
    MPSHostBoundary.reset()
    let copied = kernel.reshape(with: nil, commandBuffer: device.makeCommandBuffer(), sourceArray: source,
                                shape: [6], destinationArray: destination)
    precondition(copied === destination && reshapeWords(destination) == [1, 2, 3, 4, 5, 6])
    precondition(MPSHostBoundary.lastRefusedAPI == nil)
    let view = kernel.reshape(with: nil, commandBuffer: nil, sourceArray: source, shape: [6], destinationArray: nil)!
    precondition(view.parent === source && reshapeWords(view) == reshapeWords(source))
    precondition(kernel.reshape(with: ReshapeEncoder(), commandBuffer: device.makeCommandBuffer(), sourceArray: source,
                                shape: [6], destinationArray: destination) == nil)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNDArrayIdentity.reshape")
    precondition(reshapeWords(destination) == [1, 2, 3, 4, 5, 6])
}

func testMPSNDArrayIdentityEncoderDimensions() {
    let device = MPSHostDevice.shared
    let kernel = MPSNDArrayIdentity(device: device)
    let source = reshapeArray([1, 2, 3, 4, 5, 6])
    let destination = reshapeArray([9, 9, 9, 9, 9, 9], sizes: [1, 6])
    var sizes = [1, 6]
    sizes.withUnsafeMutableBufferPointer {
        MPSHostBoundary.reset()
        let copied = kernel.reshape(with: nil, commandBuffer: device.makeCommandBuffer(), sourceArray: source,
                                    dimensionCount: 2, dimensionSizes: $0.baseAddress!, destinationArray: destination)
        precondition(copied === destination && reshapeWords(destination) == [1, 2, 3, 4, 5, 6])
        precondition(MPSHostBoundary.lastRefusedAPI == nil)
        let view = kernel.reshape(with: nil, commandBuffer: nil, sourceArray: source,
                                  dimensionCount: 2, dimensionSizes: $0.baseAddress!, destinationArray: nil)!
        precondition(view.parent === source && view.length(ofDimension: 1) == 6)
        precondition(kernel.reshape(with: ReshapeEncoder(), commandBuffer: nil, sourceArray: source,
                                    dimensionCount: 2, dimensionSizes: $0.baseAddress!, destinationArray: destination) == nil)
        precondition(MPSHostBoundary.lastRefusedAPI == "MPSNDArrayIdentity.reshape")
    }
    // Inherited unary/multiary entry points also dispatch to the CPU identity.
    let result = kernel.encode(to: device.makeCommandBuffer(), sourceArray: source)
    precondition(reshapeWords(result) == reshapeWords(source))
}

private func reshapeImage(_ bytes: [UInt8], width: Int, height: Int, channels: Int,
                          format: MPSImageFeatureChannelFormat = .unorm8) -> MPSImage {
    let image = MPSImage(device: MPSHostDevice.shared,
        imageDescriptor: MPSImageDescriptor(channelFormat: format, width: width, height: height, featureChannels: channels))
    bytes.withUnsafeBytes { image.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0) }
    return image
}

private func reshapeImageBytes(_ image: MPSImage, count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    bytes.withUnsafeMutableBytes { image.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0) }
    return bytes
}

func testMPSNNReshapePackedChannels() {
    let device = MPSHostDevice.shared
    let kernel = MPSNNReshape(device: device)
    let command = device.makeCommandBuffer()
    // Exercise every supported scalar width and cross the 4-channel padding boundary.
    for (format, bytesPerChannel) in [(MPSImageFeatureChannelFormat.unorm8, 1), (.float16, 2), (.float32, 4)] {
        let bytes = (1...(10 * bytesPerChannel)).map { UInt8($0) }
        let source = reshapeImage(bytes, width: 2, height: 1, channels: 5, format: format)
        MPSHostBoundary.reset()
        let result = kernel.encode(commandBuffer: command, sourceImage: source,
            reshapedWidth: 1, reshapedHeight: 5, reshapedFeatureChannels: 2)
        precondition(MPSHostBoundary.lastRefusedAPI == nil)
        precondition(result.width == 1 && result.height == 5 && result.featureChannels == 2)
        precondition(result.featureChannelFormat == format && result !== source)
        precondition(reshapeImageBytes(result, count: bytes.count) == bytes)
        precondition(reshapeImageBytes(source, count: bytes.count) == bytes)
    }
    precondition(MPSNNReshape(coder: NSCoder(), device: device) == nil)
    let source = reshapeImage([1, 2, 3, 4, 5, 6], width: 2, height: 1, channels: 3)
    let sentinel = reshapeImage([99, 99, 99, 99], width: 2, height: 2, channels: 1)
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: command, sourceImage: source, destinationImage: sentinel)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNNReshape.encode")
    precondition(reshapeImageBytes(sentinel, count: 4) == [99, 99, 99, 99])
    for width in [0, -1, Int.max] {
        precondition(kernel.encode(commandBuffer: command, sourceImage: source,
            reshapedWidth: width, reshapedHeight: 2, reshapedFeatureChannels: 3) === source)
    }
    kernel.offset = MPSOffset(x: 1, y: 0, z: 0)
    precondition(kernel.encode(commandBuffer: command, sourceImage: source,
        reshapedWidth: 3, reshapedHeight: 2, reshapedFeatureChannels: 1) === source)
}

func testMPSNNReshapeBatch() {
    let device = MPSHostDevice.shared
    let kernel = MPSNNReshape(device: device)
    let first = reshapeImage([1, 2, 3, 4, 5, 6], width: 2, height: 1, channels: 3)
    let second = reshapeImage([6, 5, 4, 3, 2, 1], width: 2, height: 1, channels: 3)
    MPSHostBoundary.reset()
    let results = kernel.encodeBatch(commandBuffer: device.makeCommandBuffer(), sourceImages: [first, second],
        reshapedWidth: 3, reshapedHeight: 2, reshapedFeatureChannels: 1)
    precondition(MPSHostBoundary.lastRefusedAPI == nil && results.count == 2)
    precondition(reshapeImageBytes(results[0], count: 6) == [1, 2, 3, 4, 5, 6])
    precondition(reshapeImageBytes(results[1], count: 6) == [6, 5, 4, 3, 2, 1])
    let destination1 = reshapeImage([99, 99, 99, 99, 99, 99], width: 3, height: 2, channels: 1)
    let destination2 = reshapeImage([99, 99, 99, 99, 99, 99], width: 3, height: 2, channels: 1)
    kernel.encodeBatch(commandBuffer: device.makeCommandBuffer(), sourceImages: [first, second],
                       destinationImages: [destination1, destination2])
    precondition(reshapeImageBytes(destination1, count: 6) == [1, 2, 3, 4, 5, 6])
    precondition(reshapeImageBytes(destination2, count: 6) == [6, 5, 4, 3, 2, 1])
    let incompatible = reshapeImage([9, 9], width: 2, height: 1, channels: 1)
    kernel.encodeBatch(commandBuffer: device.makeCommandBuffer(), sourceImages: [second, incompatible],
                       destinationImages: [destination1, destination2])
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNNReshape.encodeBatch")
    precondition(reshapeImageBytes(destination1, count: 6) == [1, 2, 3, 4, 5, 6])
    precondition(kernel.encodeBatch(commandBuffer: device.makeCommandBuffer(), sourceImages: [first, incompatible],
        reshapedWidth: 3, reshapedHeight: 2, reshapedFeatureChannels: 1).isEmpty)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNNReshape.encodeBatch")
    precondition(reshapeImageBytes(first, count: 6) == [1, 2, 3, 4, 5, 6])
}

func testMPSNNReshapeGradientStateRefusal() {
    let device = MPSHostDevice.shared
    let kernel = MPSNNReshape(device: device)
    let source = reshapeImage([1, 2, 3, 4, 5, 6], width: 2, height: 1, channels: 3)
    var state: MPSState? = MPSState(device: device, bufferSize: 4)
    MPSHostBoundary.reset()
    let result = kernel.encode(commandBuffer: device.makeCommandBuffer(), sourceImage: source,
        destinationState: &state, destinationStateIsTemporary: true,
        reshapedWidth: 3, reshapedHeight: 2, reshapedFeatureChannels: 1)
    precondition(state == nil && result === source)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNNReshape.encode(destinationState:)")
    var states: NSArray? = NSArray(object: MPSState(device: device, bufferSize: 4))
    MPSHostBoundary.reset()
    let batch = kernel.encodeBatch(commandBuffer: device.makeCommandBuffer(), sourceImages: [source],
        destinationStates: &states, destinationStateIsTemporary: false,
        reshapedWidth: 3, reshapedHeight: 2, reshapedFeatureChannels: 1)
    precondition(states == nil && batch.isEmpty)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSNNReshape.encodeBatch(destinationStates:)")
    precondition(reshapeImageBytes(source, count: 6) == [1, 2, 3, 4, 5, 6])
}
