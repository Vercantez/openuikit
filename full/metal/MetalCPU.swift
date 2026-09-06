import Foundation

/// Documented CPU-reference kernel names. These are not MSL/AIR functions.
public enum MTLCPUBuiltinKernel: String, Equatable, Hashable, Sendable, CaseIterable {
    /// Thread `i` writes `UInt32` from buffer 1 (or bytes at index 1) into buffer 0 at `i * 4`.
    case fillUInt32 = "openuikit.cpu.fillUInt32"
    /// Thread `i` writes `buf0[i] &+ buf1[i]` into buffer 2 as `UInt32`.
    case addUInt32 = "openuikit.cpu.addUInt32"
    /// Thread `i` copies one byte from buffer 0 to buffer 1.
    case copyUInt8 = "openuikit.cpu.copyUInt8"
}

public func MTLMakeCPUBuiltinLibrary(_ device: any MTLDevice) -> any MTLLibrary {
    LinuxMTLLibrary.cpuBuiltin(device: device)
}

struct MetalCPUMipLevel: Equatable {
    var width: Int
    var height: Int
    var depth: Int
    var offset: Int
    var bytesPerRow: Int
    var bytesPerImage: Int
}

enum MetalCPULayout {
    static func mipSize(base: Int, level: Int) -> Int {
        max(base >> level, 1)
    }

    static func sliceCount(textureType: MTLTextureType, arrayLength: Int) -> Int {
        metalSliceCount(textureType: textureType, arrayLength: arrayLength)
    }

    static func levels(
        width: Int,
        height: Int,
        depth: Int,
        mipmapLevelCount: Int,
        arrayLength: Int,
        sampleCount: Int,
        bytesPerPixel: Int,
        textureType: MTLTextureType = .type2D
    ) -> (total: Int, levels: [MetalCPUMipLevel]) {
        var levels: [MetalCPUMipLevel] = []
        var offset = 0
        let mips = max(mipmapLevelCount, 1)
        let slices = sliceCount(textureType: textureType, arrayLength: arrayLength)
        let samples = max(sampleCount, 1)
        for mip in 0..<mips {
            let w = mipSize(base: max(width, 1), level: mip)
            let h = mipSize(base: max(height, 1), level: mip)
            let d = textureType == .type3D ? mipSize(base: max(depth, 1), level: mip) : max(depth, 1)
            let row = w * bytesPerPixel
            let image = row * h
            let sliceBytes = image * d * samples
            levels.append(
                MetalCPUMipLevel(
                    width: w,
                    height: h,
                    depth: d,
                    offset: offset,
                    bytesPerRow: row,
                    bytesPerImage: image
                )
            )
            offset += sliceBytes * slices
        }
        return (max(offset, 1), levels)
    }

    static func isValidTextureDescriptor(_ descriptor: MTLTextureDescriptor) -> Bool {
        guard descriptor.pixelFormat != .invalid else { return false }
        guard descriptor.width > 0, descriptor.height > 0, descriptor.depth > 0 else { return false }
        guard descriptor.mipmapLevelCount >= 1 else { return false }
        guard descriptor.arrayLength >= 1 else { return false }
        guard descriptor.sampleCount >= 1 else { return false }
        switch descriptor.textureType {
        case .type1D, .type1DArray, .typeTextureBuffer:
            return descriptor.height == 1 && descriptor.depth == 1
        case .typeCube, .typeCubeArray:
            return descriptor.width == descriptor.height && descriptor.depth == 1
        case .type3D:
            return descriptor.arrayLength == 1
        default:
            return true
        }
    }
}

enum MetalCPUPixels {
    static func packUnorm8(_ value: Double) -> UInt8 {
        let scaled = value * 255.0
        if scaled <= 0 { return 0 }
        if scaled >= 255 { return 255 }
        return UInt8(scaled.rounded())
    }

    static func writeClear(
        _ color: MTLClearColor,
        format: MTLPixelFormat,
        to dest: UnsafeMutableRawPointer,
        pixelCount: Int
    ) {
        guard pixelCount > 0 else { return }
        switch format {
        case .rgba8Unorm, .rgba8Unorm_srgb:
            let pixel: [UInt8] = [
                packUnorm8(color.red),
                packUnorm8(color.green),
                packUnorm8(color.blue),
                packUnorm8(color.alpha)
            ]
            fillRepeating(pixel, count: pixelCount, dest: dest)
        case .bgra8Unorm, .bgra8Unorm_srgb:
            let pixel: [UInt8] = [
                packUnorm8(color.blue),
                packUnorm8(color.green),
                packUnorm8(color.red),
                packUnorm8(color.alpha)
            ]
            fillRepeating(pixel, count: pixelCount, dest: dest)
        case .r8Unorm, .r8Unorm_srgb, .a8Unorm:
            let pixel = packUnorm8(color.red)
            dest.initializeMemory(as: UInt8.self, repeating: pixel, count: pixelCount)
        case .rgba16Float:
            let pixel: [Float16] = [
                Float16(color.red),
                Float16(color.green),
                Float16(color.blue),
                Float16(color.alpha)
            ]
            for index in 0..<pixelCount {
                pixel.withUnsafeBytes { raw in
                    dest.advanced(by: index * 8).copyMemory(from: raw.baseAddress!, byteCount: 8)
                }
            }
        case .rgba32Float:
            let pixel: [Float] = [
                Float(color.red),
                Float(color.green),
                Float(color.blue),
                Float(color.alpha)
            ]
            for index in 0..<pixelCount {
                pixel.withUnsafeBytes { raw in
                    dest.advanced(by: index * 16).copyMemory(from: raw.baseAddress!, byteCount: 16)
                }
            }
        case .depth32Float, .r32Float:
            let value = Float(color.red)
            for index in 0..<pixelCount {
                dest.advanced(by: index * 4).storeBytes(of: value, as: Float.self)
            }
        default:
            break
        }
    }

    static func writeDepth(_ depth: Double, to dest: UnsafeMutableRawPointer, pixelCount: Int) {
        let value = Float(depth)
        for index in 0..<pixelCount {
            dest.advanced(by: index * 4).storeBytes(of: value, as: Float.self)
        }
    }

    private static func fillRepeating(_ pixel: [UInt8], count: Int, dest: UnsafeMutableRawPointer) {
        pixel.withUnsafeBytes { raw in
            let src = raw.baseAddress!
            for index in 0..<count {
                dest.advanced(by: index * pixel.count).copyMemory(from: src, byteCount: pixel.count)
            }
        }
    }

    static func boxFilter(
        format: MTLPixelFormat,
        source: UnsafeRawPointer,
        sourceWidth: Int,
        sourceHeight: Int,
        sourceBytesPerRow: Int,
        destination: UnsafeMutableRawPointer,
        destWidth: Int,
        destHeight: Int,
        destBytesPerRow: Int
    ) {
        guard let bpp = metalBytesPerPixel(format) else { return }
        for y in 0..<destHeight {
            for x in 0..<destWidth {
                let x0 = min(x * 2, sourceWidth - 1)
                let y0 = min(y * 2, sourceHeight - 1)
                let x1 = min(x0 + 1, sourceWidth - 1)
                let y1 = min(y0 + 1, sourceHeight - 1)
                let samples = [
                    source.advanced(by: y0 * sourceBytesPerRow + x0 * bpp),
                    source.advanced(by: y0 * sourceBytesPerRow + x1 * bpp),
                    source.advanced(by: y1 * sourceBytesPerRow + x0 * bpp),
                    source.advanced(by: y1 * sourceBytesPerRow + x1 * bpp)
                ]
                let destPixel = destination.advanced(by: y * destBytesPerRow + x * bpp)
                average(format: format, samples: samples, to: destPixel)
            }
        }
    }

    private static func average(
        format: MTLPixelFormat,
        samples: [UnsafeRawPointer],
        to dest: UnsafeMutableRawPointer
    ) {
        switch format {
        case .rgba8Unorm, .rgba8Unorm_srgb, .bgra8Unorm, .bgra8Unorm_srgb:
            var acc = [0, 0, 0, 0]
            for sample in samples {
                let bytes = sample.assumingMemoryBound(to: UInt8.self)
                for channel in 0..<4 {
                    acc[channel] += Int(bytes[channel])
                }
            }
            let out = dest.assumingMemoryBound(to: UInt8.self)
            for channel in 0..<4 {
                out[channel] = UInt8(acc[channel] / samples.count)
            }
        case .r8Unorm, .r8Unorm_srgb, .a8Unorm:
            var acc = 0
            for sample in samples {
                acc += Int(sample.load(as: UInt8.self))
            }
            dest.storeBytes(of: UInt8(acc / samples.count), as: UInt8.self)
        case .rgba16Float:
            var acc = [Float](repeating: 0, count: 4)
            for sample in samples {
                for channel in 0..<4 {
                    let half = sample.advanced(by: channel * 2).load(as: Float16.self)
                    acc[channel] += Float(half)
                }
            }
            for channel in 0..<4 {
                dest.advanced(by: channel * 2).storeBytes(
                    of: Float16(acc[channel] / Float(samples.count)),
                    as: Float16.self
                )
            }
        case .rgba32Float:
            var acc = [Float](repeating: 0, count: 4)
            for sample in samples {
                for channel in 0..<4 {
                    acc[channel] += sample.advanced(by: channel * 4).load(as: Float.self)
                }
            }
            for channel in 0..<4 {
                dest.advanced(by: channel * 4).storeBytes(
                    of: acc[channel] / Float(samples.count),
                    as: Float.self
                )
            }
        case .depth32Float, .r32Float:
            var acc: Float = 0
            for sample in samples {
                acc += sample.load(as: Float.self)
            }
            dest.storeBytes(of: acc / Float(samples.count), as: Float.self)
        default:
            dest.copyMemory(from: samples[0], byteCount: metalBytesPerPixel(format) ?? 0)
        }
    }
}
