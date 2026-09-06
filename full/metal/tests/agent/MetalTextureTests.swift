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

func testTextureViewsAndDimensionalLayouts() {
    let device = MTLCreateSystemDefaultDevice()!

    func roundTrip(_ format: MTLPixelFormat, bytesPerPixel: Int, pattern: [UInt8]) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format,
            width: 2,
            height: 1,
            mipmapped: false
        )
        let texture = device.makeTexture(descriptor: descriptor)!
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
    }

    roundTrip(.a8Unorm, bytesPerPixel: 1, pattern: [3, 7])
    roundTrip(.r8Uint, bytesPerPixel: 1, pattern: [4, 9])
    roundTrip(.rg8Unorm, bytesPerPixel: 2, pattern: [1, 2, 3, 4])
    roundTrip(.r16Float, bytesPerPixel: 2, pattern: [0x00, 0x3C, 0x00, 0x40])
    roundTrip(.rgba8Uint, bytesPerPixel: 4, pattern: [9, 8, 7, 6, 5, 4, 3, 2])
    roundTrip(.bgra8Unorm_srgb, bytesPerPixel: 4, pattern: [11, 12, 13, 14, 15, 16, 17, 18])
    roundTrip(.r32Float, bytesPerPixel: 4, pattern: {
        var bytes = [UInt8](repeating: 0, count: 8)
        var a: Float = 0.5
        var b: Float = 1.5
        withUnsafeBytes(of: &a) { src in bytes.replaceSubrange(0..<4, with: src) }
        withUnsafeBytes(of: &b) { src in bytes.replaceSubrange(4..<8, with: src) }
        return bytes
    }())

    let sourceDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 2,
        height: 2,
        mipmapped: true
    )
    let source = device.makeTexture(descriptor: sourceDesc)!
    let pixels: [UInt8] = [
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16
    ]
    pixels.withUnsafeBytes { raw in
        source.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 8
        )
    }
    let same = source.makeTextureView(pixelFormat: .rgba8Unorm)!
    precondition(same.parent != nil)
    precondition(same.pixelFormat == .rgba8Unorm)
    let bgra = source.makeTextureView(pixelFormat: .bgra8Unorm)!
    precondition(bgra.pixelFormat == .bgra8Unorm)
    var viewed = [UInt8](repeating: 0, count: 16)
    viewed.withUnsafeMutableBytes { raw in
        bgra.getBytes(raw.baseAddress!, bytesPerRow: 8, from: MTLRegionMake2D(0, 0, 2, 2), mipmapLevel: 0)
    }
    precondition(viewed == pixels)
    precondition(source.makeTextureView(pixelFormat: .r8Unorm) == nil)

    let ranged = source.makeTextureView(
        pixelFormat: .rgba8Unorm,
        textureType: .type2D,
        levels: 0..<1,
        slices: 0..<1
    )!
    precondition(ranged.mipmapLevelCount == 1)
    precondition(ranged.parentRelativeLevel == 0)
    let swizzled = source.makeTextureView(
        pixelFormat: .rgba8Unorm,
        textureType: .type2D,
        levels: 0..<1,
        slices: 0..<1,
        swizzle: MTLTextureSwizzleChannels(red: .blue, green: .green, blue: .red, alpha: .alpha)
    )!
    precondition(swizzled.swizzle.red == .blue)
    let viewDesc = MTLTextureViewDescriptor()
    viewDesc.pixelFormat = .rgba8Uint
    viewDesc.textureType = .type2D
    viewDesc.levelRange = 0..<1
    viewDesc.sliceRange = 0..<1
    viewDesc.swizzle = MTLTextureSwizzleChannels()
    let fromDesc = source.newTextureView(with: viewDesc)!
    precondition(fromDesc.pixelFormat == .rgba8Uint)

    let arrayDesc = MTLTextureDescriptor()
    arrayDesc.textureType = .type2DArray
    arrayDesc.pixelFormat = .r8Unorm
    arrayDesc.width = 2
    arrayDesc.height = 1
    arrayDesc.arrayLength = 2
    let array = device.makeTexture(descriptor: arrayDesc)!
    precondition(array.arrayLength == 2)
    let slice0: [UInt8] = [1, 2]
    let slice1: [UInt8] = [9, 8]
    slice0.withUnsafeBytes { raw in
        array.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    slice1.withUnsafeBytes { raw in
        array.replace(
            region: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 1,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    var read1 = [UInt8](repeating: 0, count: 2)
    read1.withUnsafeMutableBytes { raw in
        array.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2,
            from: MTLRegionMake2D(0, 0, 2, 1),
            mipmapLevel: 0,
            slice: 1
        )
    }
    precondition(read1 == slice1)

    let cube = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .r8Unorm, size: 1, mipmapped: false)
    let cubeTex = device.makeTexture(descriptor: cube)!
    precondition(cube.textureType == .typeCube)
    for face in 0..<6 {
        var byte = UInt8(face + 1)
        withUnsafeBytes(of: &byte) { raw in
            cubeTex.replace(
                region: MTLRegionMake2D(0, 0, 1, 1),
                mipmapLevel: 0,
                slice: face,
                withBytes: raw.baseAddress!,
                bytesPerRow: 1,
                bytesPerImage: 1
            )
        }
    }
    var face5: UInt8 = 0
    withUnsafeMutableBytes(of: &face5) { raw in
        cubeTex.getBytes(
            raw.baseAddress!,
            bytesPerRow: 1,
            bytesPerImage: 1,
            from: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0,
            slice: 5
        )
    }
    precondition(face5 == 6)

    let volume = MTLTextureDescriptor()
    volume.textureType = .type3D
    volume.pixelFormat = .r8Unorm
    volume.width = 2
    volume.height = 1
    volume.depth = 2
    let tex3D = device.makeTexture(descriptor: volume)!
    precondition(tex3D.depth == 2)
    let voxels: [UInt8] = [1, 2, 3, 4]
    voxels.withUnsafeBytes { raw in
        tex3D.replace(
            region: MTLRegionMake3D(0, 0, 0, 2, 1, 2),
            mipmapLevel: 0,
            slice: 0,
            withBytes: raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2
        )
    }
    var readVoxels = [UInt8](repeating: 0, count: 4)
    readVoxels.withUnsafeMutableBytes { raw in
        tex3D.getBytes(
            raw.baseAddress!,
            bytesPerRow: 2,
            bytesPerImage: 2,
            from: MTLRegionMake3D(0, 0, 0, 2, 1, 2),
            mipmapLevel: 0,
            slice: 0
        )
    }
    precondition(readVoxels == voxels)
}
