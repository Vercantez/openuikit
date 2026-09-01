// Portable ImageIO source surface backed by CQuartz' vendored stb_image.
// Static and incremental sources share one state model; PNG, JPEG, and every
// composited GIF frame become the real OpenCoreGraphics bitmap type consumed
// by SwiftUI and UIKit. Invalid input fails closed.

import CQuartz
import Foundation
@_exported import CoreGraphics

// Foundation owns the process-wide Core Foundation compatibility identities.
// In particular, do not redeclare CFString or CFDictionary here: clients
// commonly import Foundation and ImageIO together and Apple exposes one type.
public typealias CFData = Data

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth"
public let kCGImagePropertyPixelHeight: CFString = "PixelHeight"
public let kCGImagePropertyOrientation: CFString = "Orientation"
public let kCGImagePropertyGIFDictionary: CFString = "{GIF}"
public let kCGImagePropertyGIFDelayTime: CFString = "DelayTime"
public let kCGImagePropertyGIFUnclampedDelayTime: CFString = "UnclampedDelayTime"
public let kCGImagePropertyGIFLoopCount: CFString = "LoopCount"
public let kCGImagePropertyJFIFDictionary: CFString = "{JFIF}"
public let kCGImagePropertyJFIFIsProgressive: CFString = "IsProgressive"
public let kCGImagePropertyPNGDictionary: CFString = "{PNG}"
public let kCGImagePropertyAPNGDelayTime: CFString = "DelayTime"
public let kCGImagePropertyAPNGUnclampedDelayTime: CFString = "UnclampedDelayTime"
public let kCGImagePropertyAPNGLoopCount: CFString = "LoopCount"
public let kCGImagePropertyWebPDictionary: CFString = "{WebP}"
public let kCGImagePropertyWebPDelayTime: CFString = "DelayTime"
public let kCGImagePropertyWebPUnclampedDelayTime: CFString = "UnclampedDelayTime"
public let kCGImagePropertyWebPLoopCount: CFString = "LoopCount"

public let kCGImageSourceShouldCache: CFString = "ShouldCache"
public let kCGImageSourceShouldCacheImmediately: CFString = "ShouldCacheImmediately"
public let kCGImageSourceCreateThumbnailFromImageAlways: CFString =
    "CreateThumbnailFromImageAlways"
public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString =
    "CreateThumbnailFromImageIfAbsent"
public let kCGImageSourceThumbnailMaxPixelSize: CFString = "ThumbnailMaxPixelSize"
public let kCGImageSourceCreateThumbnailWithTransform: CFString =
    "CreateThumbnailWithTransform"

/// ImageIO's public incremental decoding state, including Apple's raw values.
public enum CGImageSourceStatus: Int32, Sendable {
    case statusUnexpectedEOF = -5
    case statusInvalidData = -4
    case statusUnknownType = -3
    case statusReadingHeader = -2
    case statusIncomplete = -1
    case statusComplete = 0
}

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

fileprivate struct DecodedImageSet {
    let images: [CGImage]
    let frameDelays: [Double]
}

fileprivate struct ImageHeaderMetadata {
    let width: Int?
    let height: Int?
    let orientation: UInt32
    let isProgressiveJPEG: Bool

    static let empty = ImageHeaderMetadata(
        width: nil, height: nil, orientation: 1, isProgressiveJPEG: false
    )
}

public final class CGImageSource: @unchecked Sendable {
    fileprivate var data = Data()
    fileprivate var images: [CGImage] = []
    fileprivate var frameDelays: [Double] = []
    fileprivate var uniformType: CFString?
    fileprivate var status: CGImageSourceStatus
    fileprivate var metadata = ImageHeaderMetadata.empty
    fileprivate var isFinal = false
    fileprivate let isIncremental: Bool

    fileprivate init(incremental: Bool) {
        isIncremental = incremental
        status = .statusInvalidData
    }

    fileprivate convenience init(
        data: Data,
        type: CFString,
        decoded: DecodedImageSet,
        metadata: ImageHeaderMetadata
    ) {
        self.init(incremental: false)
        self.data = data
        self.uniformType = type
        self.images = decoded.images
        self.frameDelays = decoded.frameDelays
        self.metadata = metadata
        self.isFinal = true
        self.status = .statusComplete
    }
}

@inline(__always)
private func makeImage(
    width: Int,
    height: Int,
    pixels: UnsafePointer<UInt8>
) -> CGImage? {
    guard width > 0, height > 0,
          width <= Int.max / 4,
          height <= Int.max / (width * 4) else { return nil }
    let byteCount = width * height * 4
    let image = CGImage(width: width, height: height)
    image.pixels.withUnsafeMutableBufferPointer { destination in
        destination.baseAddress?.update(from: pixels, count: byteCount)
    }
    return image
}

private func decodedImages(_ data: Data, type: CFString) -> DecodedImageSet? {
    let bytes = Array(data)
    guard !bytes.isEmpty else { return nil }

    if type == "com.compuserve.gif" {
        var width: Int32 = 0
        var height: Int32 = 0
        var frameCount: Int32 = 0
        var delays: UnsafeMutablePointer<Int32>?
        guard let decoded = bytes.withUnsafeBufferPointer({ buffer in
            QZImageDecodeGIFRGBA(
                buffer.baseAddress, buffer.count, &width, &height,
                &frameCount, &delays
            )
        }) else { return nil }
        defer {
            QZImageFreeRGBA(decoded)
            QZImageFreeGIFDelays(delays)
        }

        let w = Int(width)
        let h = Int(height)
        let count = Int(frameCount)
        guard w > 0, h > 0, count > 0,
              w <= Int.max / 4,
              h <= Int.max / (w * 4),
              count <= Int.max / (w * h * 4) else { return nil }
        let bytesPerFrame = w * h * 4
        var images: [CGImage] = []
        var frameDelays: [Double] = []
        images.reserveCapacity(count)
        frameDelays.reserveCapacity(count)
        for index in 0..<count {
            guard let image = makeImage(
                width: w,
                height: h,
                pixels: UnsafePointer(decoded.advanced(by: index * bytesPerFrame))
            ) else { return nil }
            images.append(image)
            frameDelays.append(Double(delays?[index] ?? 0) / 1_000)
        }
        return DecodedImageSet(images: images, frameDelays: frameDelays)
    }

    var width: Int32 = 0
    var height: Int32 = 0
    guard let decoded = bytes.withUnsafeBufferPointer({ buffer in
        QZImageDecodeRGBA(buffer.baseAddress, buffer.count, &width, &height)
    }) else { return nil }
    defer { QZImageFreeRGBA(decoded) }
    guard let image = makeImage(
        width: Int(width), height: Int(height), pixels: UnsafePointer(decoded)
    ) else { return nil }
    return DecodedImageSet(images: [image], frameDelays: [0])
}

@inline(__always)
private func imageType(_ data: Data) -> CFString? {
    let bytes = Array(data.prefix(12))
    if bytes.count >= 8,
       bytes[0...7].elementsEqual([137, 80, 78, 71, 13, 10, 26, 10]) {
        return "public.png"
    }
    if bytes.count >= 2, bytes[0] == 0xff, bytes[1] == 0xd8 {
        return "public.jpeg"
    }
    if bytes.count >= 6,
       bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46,
       bytes[3] == 0x38, (bytes[4] == 0x37 || bytes[4] == 0x39),
       bytes[5] == 0x61 {
        return "com.compuserve.gif"
    }
    return nil
}

@inline(__always)
private func bigEndianUInt16(_ bytes: [UInt8], _ offset: Int) -> Int? {
    guard offset >= 0, offset + 1 < bytes.count else { return nil }
    return (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
}

@inline(__always)
private func littleEndianUInt16(_ bytes: [UInt8], _ offset: Int) -> Int? {
    guard offset >= 0, offset + 1 < bytes.count else { return nil }
    return Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
}

@inline(__always)
private func bigEndianUInt32(_ bytes: [UInt8], _ offset: Int) -> Int? {
    guard offset >= 0, offset + 3 < bytes.count else { return nil }
    return (Int(bytes[offset]) << 24) | (Int(bytes[offset + 1]) << 16)
        | (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
}

@inline(__always)
private func littleEndianUInt32(_ bytes: [UInt8], _ offset: Int) -> Int? {
    guard offset >= 0, offset + 3 < bytes.count else { return nil }
    return Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
        | (Int(bytes[offset + 2]) << 16) | (Int(bytes[offset + 3]) << 24)
}

private func jpegOrientation(_ bytes: [UInt8]) -> UInt32 {
    var offset = 2
    while offset + 4 <= bytes.count {
        guard bytes[offset] == 0xff else { offset += 1; continue }
        let marker = bytes[offset + 1]
        if marker == 0xd9 || marker == 0xda { break }
        guard let length = bigEndianUInt16(bytes, offset + 2), length >= 2,
              offset + 2 + length <= bytes.count else { break }
        let payload = offset + 4
        let payloadEnd = offset + 2 + length
        if marker == 0xe1, payload + 14 <= payloadEnd,
           Array(bytes[payload..<(payload + 6)]) == [69, 120, 105, 102, 0, 0] {
            let tiff = payload + 6
            let little = bytes[tiff] == 0x49 && bytes[tiff + 1] == 0x49
            let big = bytes[tiff] == 0x4d && bytes[tiff + 1] == 0x4d
            guard little || big else { return 1 }
            let u16: (Int) -> Int? = { index in
                little ? littleEndianUInt16(bytes, index)
                    : bigEndianUInt16(bytes, index)
            }
            let u32: (Int) -> Int? = { index in
                little ? littleEndianUInt32(bytes, index)
                    : bigEndianUInt32(bytes, index)
            }
            guard u16(tiff + 2) == 42, let relativeIFD = u32(tiff + 4) else {
                return 1
            }
            let ifd = tiff + relativeIFD
            guard let entryCount = u16(ifd) else { return 1 }
            for entry in 0..<entryCount {
                let item = ifd + 2 + entry * 12
                guard item + 11 < payloadEnd else { break }
                if u16(item) == 0x0112, u16(item + 2) == 3,
                   u32(item + 4) == 1, let value = u16(item + 8),
                   (1...8).contains(value) {
                    return UInt32(value)
                }
            }
        }
        offset += 2 + length
    }
    return 1
}

private func imageHeaderMetadata(_ data: Data, type: CFString?) -> ImageHeaderMetadata {
    guard let type else { return .empty }
    let bytes = Array(data)
    if type == "public.png" {
        let width = bigEndianUInt32(bytes, 16)
        let height = bigEndianUInt32(bytes, 20)
        return ImageHeaderMetadata(
            width: width, height: height, orientation: 1,
            isProgressiveJPEG: false
        )
    }
    if type == "com.compuserve.gif" {
        return ImageHeaderMetadata(
            width: littleEndianUInt16(bytes, 6),
            height: littleEndianUInt16(bytes, 8),
            orientation: 1,
            isProgressiveJPEG: false
        )
    }
    if type == "public.jpeg" {
        var offset = 2
        while offset + 4 <= bytes.count {
            guard bytes[offset] == 0xff else { offset += 1; continue }
            let marker = bytes[offset + 1]
            if marker == 0xd9 || marker == 0xda { break }
            guard let length = bigEndianUInt16(bytes, offset + 2), length >= 2,
                  offset + 2 + length <= bytes.count else { break }
            let isStartOfFrame = (0xc0...0xc3).contains(marker)
                || (0xc5...0xc7).contains(marker)
                || (0xc9...0xcb).contains(marker)
                || (0xcd...0xcf).contains(marker)
            if isStartOfFrame, length >= 7 {
                return ImageHeaderMetadata(
                    width: bigEndianUInt16(bytes, offset + 7),
                    height: bigEndianUInt16(bytes, offset + 5),
                    orientation: jpegOrientation(bytes),
                    isProgressiveJPEG: marker == 0xc2
                )
            }
            offset += 2 + length
        }
        return ImageHeaderMetadata(
            width: nil, height: nil, orientation: jpegOrientation(bytes),
            isProgressiveJPEG: false
        )
    }
    return .empty
}

private func gifLoopCount(_ data: Data) -> Int? {
    let bytes = Array(data)
    let application = Array("NETSCAPE2.0".utf8)
    guard bytes.count >= application.count + 5 else { return nil }
    for start in 0...(bytes.count - application.count - 5) {
        guard Array(bytes[start..<(start + application.count)]) == application else {
            continue
        }
        let subBlock = start + application.count
        guard bytes[subBlock] == 3, bytes[subBlock + 1] == 1 else { continue }
        return littleEndianUInt16(bytes, subBlock + 2)
    }
    return nil
}

private func refreshIncrementalSource(_ source: CGImageSource) {
    source.uniformType = imageType(source.data)
    source.metadata = imageHeaderMetadata(source.data, type: source.uniformType)
    guard let type = source.uniformType else {
        source.images.removeAll(keepingCapacity: false)
        source.frameDelays.removeAll(keepingCapacity: false)
        source.status = source.isFinal ? .statusUnknownType : .statusInvalidData
        return
    }

    if let decoded = decodedImages(source.data, type: type) {
        source.images = decoded.images
        source.frameDelays = decoded.frameDelays
        source.status = source.isFinal ? .statusComplete : .statusIncomplete
    } else {
        source.images.removeAll(keepingCapacity: false)
        source.frameDelays.removeAll(keepingCapacity: false)
        source.status = source.isFinal ? .statusUnexpectedEOF : .statusIncomplete
    }
}

public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource? {
    _ = options
    guard let type = imageType(data), let decoded = decodedImages(data, type: type) else {
        return nil
    }
    return CGImageSource(
        data: data,
        type: type,
        decoded: decoded,
        metadata: imageHeaderMetadata(data, type: type)
    )
}

public func CGImageSourceCreateIncremental(
    _ options: CFDictionary?
) -> CGImageSource {
    _ = options
    return CGImageSource(incremental: true)
}

public func CGImageSourceUpdateData(
    _ source: CGImageSource,
    _ data: CFData,
    _ final: Bool
) {
    guard source.isIncremental else { return }
    source.data = data
    source.isFinal = final
    refreshIncrementalSource(source)
}

public func CGImageSourceGetStatus(_ source: CGImageSource) -> CGImageSourceStatus {
    source.status
}

public func CGImageSourceGetStatusAtIndex(
    _ source: CGImageSource,
    _ index: Int
) -> CGImageSourceStatus {
    guard index >= 0, index < CGImageSourceGetCount(source) else {
        return .statusUnknownType
    }
    return index < source.images.count ? source.status : .statusIncomplete
}

public func CGImageSourceGetCount(_ source: CGImageSource) -> Int {
    if !source.images.isEmpty { return source.images.count }
    return source.uniformType == nil ? 0 : 1
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
    guard index >= 0, index < source.images.count else { return nil }
    return source.images[index]
}

public func CGImageSourceCreateThumbnailAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage? {
    // The renderer currently has no ImageIO resampling primitive. Returning
    // the actual decoded image is lossless and lets callers resample through
    // CGContext; it never fabricates a thumbnail or changes orientation.
    CGImageSourceCreateImageAtIndex(source, index, options)
}

public func CGImageSourceCopyProperties(
    _ source: CGImageSource,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard source.uniformType != nil else { return nil }
    var properties: CFDictionary = [:]
    if source.uniformType == "com.compuserve.gif" {
        var gif: [CFString: Any] = [:]
        if let loopCount = gifLoopCount(source.data) {
            gif[kCGImagePropertyGIFLoopCount] = loopCount
        }
        properties[kCGImagePropertyGIFDictionary] = gif
    }
    return properties
}

public func CGImageSourceCopyPropertiesAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard index >= 0, index < CGImageSourceGetCount(source) else { return nil }
    let image = index < source.images.count ? source.images[index] : nil
    let width = image?.width ?? source.metadata.width
    let height = image?.height ?? source.metadata.height
    var properties: CFDictionary = [
        kCGImagePropertyOrientation: source.metadata.orientation,
    ]
    if let width { properties[kCGImagePropertyPixelWidth] = width }
    if let height { properties[kCGImagePropertyPixelHeight] = height }

    if source.uniformType == "com.compuserve.gif" {
        let delay = index < source.frameDelays.count
            ? source.frameDelays[index] : 0
        properties[kCGImagePropertyGIFDictionary] = [
            kCGImagePropertyGIFDelayTime: delay,
            kCGImagePropertyGIFUnclampedDelayTime: delay,
        ] as [CFString: Any]
    } else if source.uniformType == "public.jpeg" {
        properties[kCGImagePropertyJFIFDictionary] = [
            kCGImagePropertyJFIFIsProgressive: source.metadata.isProgressiveJPEG,
        ] as [CFString: Any]
    }
    return properties
}
