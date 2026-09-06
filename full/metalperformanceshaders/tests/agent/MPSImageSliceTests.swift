import Foundation
import MetalPerformanceShaders

func testMPSImageFeatureSlicesAndBatch() {
    let device = MPSHostDevice.shared
    let descriptor = MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 1,
        featureChannels: 5, numberOfImages: 2, usage: [.shaderRead, .shaderWrite])
    let image = MPSImage(device: device, imageDescriptor: descriptor)
    precondition(image.numberOfImages == 2 && image.texture.arrayLength == 4)
    precondition(image.textureType == .type2DArray && image.resourceSize() == 32)
    let first: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let second: [UInt8] = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    first.withUnsafeBytes { image.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0) }
    second.withUnsafeBytes { image.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    // Slice 0 carries C0..3 of both pixels, slice 1 carries C4;
    // slices 2 and 3 repeat that layout for image 1. Padding is untouched.
    let expected: [UInt8] = [1, 2, 3, 4, 6, 7, 8, 9, 5, 0, 0, 0, 10, 0, 0, 0,
                            11, 12, 13, 14, 16, 17, 18, 19, 15, 0, 0, 0, 20, 0, 0, 0]
    let texture = image.texture as! MPSHostTexture
    precondition(Array(texture.bytes) == expected)
    let wrapper = MPSImage(texture: texture, featureChannels: 5)
    precondition(wrapper.numberOfImages == 2)
    var output = [UInt8](repeating: 0, count: 10)
    output.withUnsafeMutableBytes { wrapper.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    precondition(output == second)
    output.withUnsafeMutableBytes { image.readBytes($0.baseAddress!, dataLayout: .featureChannelsxHeightxWidth, imageIndex: 0) }
    precondition(output == [1, 6, 2, 7, 3, 8, 4, 9, 5, 10])
    // A write through either wrapper remains visible through the shared texture.
    first.withUnsafeBytes { wrapper.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    output.withUnsafeMutableBytes { image.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    precondition(output == first)
    let temporary = MPSTemporaryImage(commandBuffer: device.makeCommandBuffer(), imageDescriptor: descriptor)
    second.withUnsafeBytes { temporary.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    output.withUnsafeMutableBytes { temporary.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 1) }
    precondition(output == second && temporary.texture.arrayLength == 4 && temporary.readCount == 1)
}

func testMPSImageFeatureSliceStrides() {
    let image = MPSImage(device: MPSHostDevice.shared,
        imageDescriptor: MPSImageDescriptor(channelFormat: .unorm8, width: 2, height: 2, featureChannels: 5))
    // Write only C3,C4 across the slice boundary. Rows have one padding byte,
    // planes have two extra padding bytes. Sentinel bytes are never copied.
    let params = MPSImageReadWriteParams(featureChannelOffset: 3, numberOfFeatureChannelsToReadWrite: 2)
    let region = MTLRegion.make2D(0, 0, 2, 2)
    let source: [UInt8] = [1, 2, 99, 3, 4, 99, 99, 99, 5, 6, 99, 7, 8, 99, 99, 99]
    source.withUnsafeBytes {
        image.writeBytes($0.baseAddress!, dataLayout: .featureChannelsxHeightxWidth,
            bytesPerRow: 3, bytesPerImage: 8, region: region, featureChannelInfo: params, imageIndex: 0)
    }
    var packed = [UInt8](repeating: 99, count: 20)
    packed.withUnsafeMutableBytes {
        image.readBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
    }
    precondition(packed == [0, 0, 0, 1, 5, 0, 0, 0, 2, 6, 0, 0, 0, 3, 7, 0, 0, 0, 4, 8])
    var planar = [UInt8](repeating: 99, count: 16)
    planar.withUnsafeMutableBytes {
        image.readBytes($0.baseAddress!, dataLayout: .featureChannelsxHeightxWidth,
            bytesPerRow: 3, bytesPerImage: 8, region: region, featureChannelInfo: params, imageIndex: 0)
    }
    precondition(planar == source)
    // Invalid image indices and channel ranges leave caller/destination sentinels intact.
    planar.withUnsafeMutableBytes {
        image.readBytes($0.baseAddress!, dataLayout: .featureChannelsxHeightxWidth,
            bytesPerRow: 3, bytesPerImage: 8, region: region, featureChannelInfo: params, imageIndex: 1)
    }
    precondition(planar == source)
    let before = (image.texture as! MPSHostTexture).bytes
    source.withUnsafeBytes {
        image.writeBytes($0.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels,
            bytesPerRow: 4, region: region,
            featureChannelInfo: MPSImageReadWriteParams(featureChannelOffset: 4, numberOfFeatureChannelsToReadWrite: 2),
            imageIndex: 0)
    }
    precondition((image.texture as! MPSHostTexture).bytes == before)
}
