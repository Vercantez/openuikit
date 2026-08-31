// Portable ImageIO decode surface backed by the same vendored stb_image path
// used by OpenUIKit. PNG and JPEG bytes become the real OpenCoreGraphics
// bitmap type consumed by SwiftUI and UIKit; invalid data fails closed.

import CQuartz
import Foundation
@_exported import CoreGraphics

public typealias CFData = Data
public typealias CFDictionary = [AnyHashable: Any]
public typealias CFString = String

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth"
public let kCGImagePropertyPixelHeight: CFString = "PixelHeight"
public let kCGImagePropertyOrientation: CFString = "Orientation"
public let kCGImageSourceShouldCache: CFString = "ShouldCache"
public let kCGImageSourceCreateThumbnailFromImageAlways: CFString =
    "CreateThumbnailFromImageAlways"
public let kCGImageSourceThumbnailMaxPixelSize: CFString = "ThumbnailMaxPixelSize"
public let kCGImageSourceCreateThumbnailWithTransform: CFString =
    "CreateThumbnailWithTransform"

public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}

public final class CGImageSource: @unchecked Sendable {
    fileprivate let image: CGImage
    fileprivate let uniformType: CFString

    fileprivate init(image: CGImage, uniformType: CFString) {
        self.image = image
        self.uniformType = uniformType
    }
}

@inline(__always)
private func decodedImage(_ data: Data) -> CGImage? {
    let bytes = Array(data)
    guard !bytes.isEmpty else { return nil }

    var width: Int32 = 0
    var height: Int32 = 0
    guard let decoded = bytes.withUnsafeBufferPointer({ buffer in
        QZImageDecodeRGBA(buffer.baseAddress, buffer.count, &width, &height)
    }) else {
        return nil
    }
    defer { QZImageFreeRGBA(decoded) }

    guard width > 0, height > 0 else { return nil }
    let w = Int(width)
    let h = Int(height)
    guard w <= Int.max / 4, h <= Int.max / (w * 4) else { return nil }
    let byteCount = w * h * 4
    let image = CGImage(width: w, height: h)
    image.pixels.withUnsafeMutableBufferPointer { destination in
        destination.baseAddress?.update(from: decoded, count: byteCount)
    }
    return image
}

@inline(__always)
private func imageType(_ data: Data) -> CFString? {
    let bytes = Array(data.prefix(12))
    if bytes.count >= 8,
       bytes[0...7].elementsEqual([137, 80, 78, 71, 13, 10, 26, 10]) {
        return "public.png"
    }
    if bytes.count >= 3, bytes[0] == 0xff, bytes[1] == 0xd8, bytes[2] == 0xff {
        return "public.jpeg"
    }
    return nil
}

public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource? {
    _ = options
    guard let type = imageType(data), let image = decodedImage(data) else {
        return nil
    }
    return CGImageSource(image: image, uniformType: type)
}

public func CGImageSourceGetCount(_ source: CGImageSource) -> Int {
    _ = source
    return 1
}

public func CGImageSourceGetType(_ source: CGImageSource) -> CFString? {
    source.uniformType
}

public func CGImageSourceCreateImageAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage? {
    _ = options
    return index == 0 ? source.image : nil
}

public func CGImageSourceCreateThumbnailAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage? {
    // The current renderer has no resampling API. Returning the decoded image
    // is truthful and useful; callers that require a bounded thumbnail can
    // inspect its dimensions and resample through CGContext.
    CGImageSourceCreateImageAtIndex(source, index, options)
}

public func CGImageSourceCopyPropertiesAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard index == 0 else { return nil }
    return [
        kCGImagePropertyPixelWidth: source.image.width,
        kCGImagePropertyPixelHeight: source.image.height,
        kCGImagePropertyOrientation: CGImagePropertyOrientation.up.rawValue,
    ]
}
