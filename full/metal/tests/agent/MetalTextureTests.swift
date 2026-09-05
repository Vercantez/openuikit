import Foundation
import Metal

func testTextureBytesAndMips() {
    func roundTrip(_ format: MTLPixelFormat, bytesPerPixel: Int, pattern: [UInt8]) {
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
        precondition(texture.height == 1)
        precondition(texture.depth == 1)
        precondition(texture.textureType == .type2D)
        precondition(texture.mipmapLevelCount == 1)
        precondition(texture.sampleCount == 1)
        precondition(texture.arrayLength == 1)
        precondition(texture.usage.contains(.shaderRead))
        precondition(!texture.isFramebufferOnly)
        precondition(!texture.isShareable)
        precondition(!texture.isSparse)
        _ = texture.allowGPUOptimizedContents
        _ = texture.compressionType
        _ = texture.swizzle
        _ = texture.parent
        _ = texture.parentRelativeLevel
        _ = texture.parentRelativeSlice
        _ = texture.buffer
        _ = texture.bufferOffset
        _ = texture.bufferBytesPerRow
        _ = texture.rootResource
        _ = texture.gpuResourceID
        _ = texture.firstMipmapInTail
        _ = texture.tailSizeInBytes
        _ = texture.sparseTextureTier
        _ = texture.storageMode
        pattern.withUnsafeBytes { raw in
            texture.replace(
                region: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0,
                withBytes: raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel
            )
        }
        var roundTripBytes = [UInt8](repeating: 0, count: pattern.count)
        roundTripBytes.withUnsafeMutableBytes { raw in
            texture.getBytes(
                raw.baseAddress!,
                bytesPerRow: 2 * bytesPerPixel,
                from: MTLRegionMake2D(0, 0, 2, 1),
                mipmapLevel: 0
            )
        }
        precondition(roundTripBytes == pattern)
        _ = texture.makeTextureView(pixelFormat: format)
    }

    roundTrip(.rgba8Unorm, bytesPerPixel: 4, pattern: [10, 20, 30, 40, 50, 60, 70, 80])
    roundTrip(.bgra8Unorm, bytesPerPixel: 4, pattern: [1, 2, 3, 4, 5, 6, 7, 8])
    roundTrip(.r8Unorm, bytesPerPixel: 1, pattern: [9, 11])
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
    roundTrip(.rgba16Float, bytesPerPixel: 8, pattern: rgba16)
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
    roundTrip(.rgba32Float, bytesPerPixel: 16, pattern: rgba32)
    var depth = [UInt8](repeating: 0, count: 8)
    var d1: Float = 0.25
    var d2: Float = 0.75
    withUnsafeBytes(of: &d1) { src in depth.replaceSubrange(0..<4, with: src) }
    withUnsafeBytes(of: &d2) { src in depth.replaceSubrange(4..<8, with: src) }
    roundTrip(.depth32Float, bytesPerPixel: 4, pattern: depth)

    let device = MTLCreateSystemDefaultDevice()!
    let invalid = MTLTextureDescriptor()
    invalid.pixelFormat = .invalid
    precondition(device.makeTexture(descriptor: invalid) == nil)
    let zero = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 0,
        height: 4,
        mipmapped: false
    )
    precondition(device.makeTexture(descriptor: zero) == nil)

    let mipDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    precondition(mipDesc.mipmapLevelCount == 2)
    let mip = device.makeTexture(descriptor: mipDesc)!
    precondition(mip.mipmapLevelCount == 2)
    let pixels: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    pixels.withUnsafeBytes { raw in
        mip.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8,
            bytesPerImage: 16
        )
    }
    var sliceBytes = [UInt8](repeating: 0, count: 16)
    sliceBytes.withUnsafeMutableBytes { raw in
        mip.getBytes(
            raw.baseAddress!,
            bytesPerRow: 8,
            bytesPerImage: 16,
            from: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            slice: 0
        )
    }
    precondition(sliceBytes == pixels)
}
