// Portable ImageIO CGImage / CF spellings.
//
// On Darwin, CGImage is CoreGraphics' type so `CGImageSourceCreateImageAtIndex`
// returns the same identity Apple's ImageIO does. On Linux there is no
// CoreGraphics module; the lookalike stores straight-alpha RGBA8 (the same
// layout ImageCodec / CQuartz QZImageDecodeRGBA produce).

import Foundation
import OpenCoreGraphics
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if !canImport(CoreGraphics)
public typealias CFString = String
public typealias CFDictionary = [AnyHashable: Any]
public typealias CFArray = [Any]
public typealias CFData = Data
public typealias CFURL = URL
public typealias CFMutableData = NSMutableData
public typealias CFTypeID = UInt

/// Linux lookalike for CoreGraphics' RGBA8 image. Not CoreGraphics identity.
public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public let bitsPerComponent: Int
    public let bitsPerPixel: Int
    public let bytesPerRow: Int
    public let rgba: [UInt8]

    public init(width: Int, height: Int, rgba: [UInt8]) {
        self.width = max(0, width)
        self.height = max(0, height)
        self.bitsPerComponent = 8
        self.bitsPerPixel = 32
        self.bytesPerRow = self.width * 4
        let count = self.width * self.height * 4
        if rgba.count >= count {
            self.rgba = Array(rgba.prefix(count))
        } else {
            var padded = rgba
            padded.append(contentsOf: repeatElement(UInt8(0), count: count - rgba.count))
            self.rgba = padded
        }
    }
}

public final class CGDataProvider: @unchecked Sendable {
    public let data: Data
    public init(data: Data) { self.data = data }
}

public final class CGDataConsumer: @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var bytes = Data()
    public init() {}
    func receive(_ data: Data) {
        lock.lock()
        bytes.append(data)
        lock.unlock()
    }
}
#endif

func imageioMakeCGImage(width: Int, height: Int, rgba: [UInt8]) -> CGImage? {
    guard width > 0, height > 0, rgba.count >= width * height * 4 else { return nil }
#if canImport(CoreGraphics)
    let count = width * height * 4
    // Darwin CGImage / CGContext reject straight-alpha `.last` (measured:
    // GoldenDarkModeTests and GuestCompatibility/BitmapContextProbe use
    // `.premultipliedLast`). Premultiply our straight RGBA8 for the wrapper.
    var premul = Array(rgba.prefix(count))
    imageioPremultiply(&premul)
    let data = CFDataCreate(nil, premul, count)!
    guard let provider = CoreGraphics.CGDataProvider(data: data) else { return nil }
    guard let space = CoreGraphics.CGColorSpace(name: CoreGraphics.CGColorSpace.sRGB) else { return nil }
    return CoreGraphics.CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: space,
        bitmapInfo: CoreGraphics.CGBitmapInfo(
            rawValue: CoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
#else
    return CGImage(width: width, height: height, rgba: Array(rgba.prefix(width * height * 4)))
#endif
}

func imageioReadRGBA(_ image: CGImage) -> (width: Int, height: Int, rgba: [UInt8])? {
#if canImport(CoreGraphics)
    let width = image.width
    let height = image.height
    guard width > 0, height > 0 else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let space = CoreGraphics.CGColorSpace(name: CoreGraphics.CGColorSpace.sRGB) else { return nil }
    guard let ctx = CoreGraphics.CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: space,
        bitmapInfo: CoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    imageioUnpremultiply(&pixels)
    return (width, height, pixels)
#else
    return (image.width, image.height, image.rgba)
#endif
}

func imageioPremultiply(_ pixels: inout [UInt8]) {
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let a = Int(pixels[i + 3])
        if a == 255 || a == 0 { continue }
        for c in 0..<3 {
            pixels[i + c] = UInt8((Int(pixels[i + c]) * a + 127) / 255)
        }
    }
}

func imageioUnpremultiply(_ pixels: inout [UInt8]) {
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let a = Int(pixels[i + 3])
        if a > 0 && a < 255 {
            for c in 0..<3 {
                pixels[i + c] = UInt8(min(255, (Int(pixels[i + c]) * 255 + a / 2) / a))
            }
        }
    }
}

func imageioBitmap(from image: CGImage) -> Bitmap? {
    guard let read = imageioReadRGBA(image) else { return nil }
    let bitmap = Bitmap(width: read.width, height: read.height)
    bitmap.pixels = read.rgba
    return bitmap
}
