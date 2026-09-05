// Portable ImageIO source surface. When CQuartz is present, PNG, JPEG, and
// composited GIF frames use that decoder. On the isolated Linux host the same
// state model is backed by the Foundation-only BMP/PNG codecs. Invalid input
// fails closed.

import Foundation
#if canImport(CQuartz)
import CQuartz
#endif
#if canImport(CoreGraphics)
@_exported import CoreGraphics
#endif
/// ImageIO's public incremental decoding state, including Apple's raw values.
public enum CGImageSourceStatus: Int32, Sendable {
    case statusUnexpectedEOF = -5
    case statusInvalidData = -4
    case statusUnknownType = -3
    case statusReadingHeader = -2
    case statusIncomplete = -1
    case statusComplete = 0
}

@frozen
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

struct DecodedImageSet {
    let images: [CGImage]
    let frameDelays: [Double]
}

struct ImageHeaderMetadata {
    let width: Int?
    let height: Int?
    let orientation: UInt32
    let isProgressiveJPEG: Bool

    static let empty = ImageHeaderMetadata(
        width: nil, height: nil, orientation: 1, isProgressiveJPEG: false
    )
}

public final class CGImageSource: @unchecked Sendable {
    var data = Data()
    var images: [CGImage] = []
    var frameDelays: [Double] = []
    var uniformType: CFString?
    var status: CGImageSourceStatus
    var metadata = ImageHeaderMetadata.empty
    var parsed = ImageIOParsedFile()
    var isFinal = false
    let isIncremental: Bool

    init(incremental: Bool) {
        isIncremental = incremental
        status = .statusInvalidData
    }

    convenience init(
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
        self.parsed = imageioParseFile(data)
        self.isFinal = true
        self.status = .statusComplete
    }

    public static func == (left: CGImageSource, right: CGImageSource) -> Bool {
        left === right
    }

    public static func != (left: CGImageSource, right: CGImageSource) -> Bool {
        left !== right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public var hashValue: Int {
        ObjectIdentifier(self).hashValue
    }
}

func decodedImages(_ data: Data, type: CFString) -> DecodedImageSet? {
#if canImport(CQuartz)
    if let quartz = decodedImagesUsingCQuartz(data, type: type) {
        return quartz
    }
#endif
    return imageioDecodePortable(data, type: type)
}

#if canImport(CQuartz)
private func decodedImagesUsingCQuartz(_ data: Data, type: CFString) -> DecodedImageSet? {
    let bytes = Array(data)
    guard !bytes.isEmpty else { return nil }

    if type == imageioTypeGIF {
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
            guard let image = imageioMakeImage(
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
    guard let image = imageioMakeImage(
        width: Int(width), height: Int(height), pixels: UnsafePointer(decoded)
    ) else { return nil }
    return DecodedImageSet(images: [image], frameDelays: [0])
}
#endif

@inline(__always)
func imageType(_ data: Data) -> CFString? {
    imageioDetectType(data)
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

func imageHeaderMetadata(_ data: Data, type: CFString?) -> ImageHeaderMetadata {
    guard let type else { return .empty }
    let bytes = Array(data)
    if type == imageioTypePNG {
        let width = bigEndianUInt32(bytes, 16)
        let height = bigEndianUInt32(bytes, 20)
        return ImageHeaderMetadata(
            width: width, height: height, orientation: 1,
            isProgressiveJPEG: false
        )
    }
    if type == imageioTypeGIF {
        return ImageHeaderMetadata(
            width: littleEndianUInt16(bytes, 6),
            height: littleEndianUInt16(bytes, 8),
            orientation: 1,
            isProgressiveJPEG: false
        )
    }
    if type == imageioTypeBMP, bytes.count >= 26 {
        let width = Int(Int32(bitPattern: UInt32(littleEndianUInt32(bytes, 18) ?? 0)))
        let height32 = Int32(bitPattern: UInt32(littleEndianUInt32(bytes, 22) ?? 0))
        return ImageHeaderMetadata(
            width: width == 0 ? nil : abs(width),
            height: height32 == 0 ? nil : abs(Int(height32)),
            orientation: 1,
            isProgressiveJPEG: false
        )
    }
    if type == imageioTypeJPEG {
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

private func refreshSource(_ source: CGImageSource) {
    source.parsed = imageioParseFile(source.data)
    source.uniformType = source.parsed.type
    source.metadata = imageHeaderMetadata(source.data, type: source.uniformType)
    guard let type = source.uniformType else {
        source.images.removeAll(keepingCapacity: false)
        source.frameDelays.removeAll(keepingCapacity: false)
        source.status = .statusInvalidData
        return
    }
    if !imageioTypeAllowed(type) {
        source.images.removeAll(keepingCapacity: false)
        source.frameDelays.removeAll(keepingCapacity: false)
        source.uniformType = nil
        source.status = .statusUnknownType
        return
    }

    if let decoded = decodedImages(source.data, type: type) {
        source.images = decoded.images
        source.frameDelays = decoded.frameDelays
        if source.parsed.frameDelays.isEmpty {
            source.parsed.frameDelays = decoded.frameDelays
        }
        source.status = source.isFinal ? .statusComplete : .statusIncomplete
    } else {
        source.images.removeAll(keepingCapacity: false)
        source.frameDelays.removeAll(keepingCapacity: false)
        // MEASURED 2026-09-05: CreateWithData of a 10-byte PNG prefix (typed,
        // no pixels) reports statusComplete because the blob is final.
        // Incremental of the same prefix reports statusIncomplete until
        // UpdateData(..., true).
        source.status = source.isFinal ? .statusComplete : .statusIncomplete
    }
}

public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource? {
    _ = options
    // MEASURED 2026-09-05 Apple ImageIO: empty and garbage bytes still
    // return a source (statusInvalidData, count 0). Truncated PNG of 10+
    // bytes returns a typed source with statusComplete and no image.
    let detected = imageioDetectType(data)
    if let detected, !imageioTypeAllowed(detected) {
        return nil
    }
    let source = CGImageSource(incremental: false)
    source.data = data
    source.isFinal = true
    refreshSource(source)
    return source
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
    refreshSource(source)
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
    if source.parsed.frameCount > 0 { return source.parsed.frameCount }
    if source.uniformType == imageioTypeGIF { return 0 }
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
    guard let image = CGImageSourceCreateImageAtIndex(source, index, options) else {
        return nil
    }
    return imageioThumbnail(image, options: options, orientation: source.parsed.orientation)
}

public func CGImageSourceCopyProperties(
    _ source: CGImageSource,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard source.uniformType != nil else { return nil }
    return imageioProperties(
        source.parsed, image: nil, index: 0,
        fileSize: source.data.count, container: true
    )
}

public func CGImageSourceCopyPropertiesAtIndex(
    _ source: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard index >= 0, index < CGImageSourceGetCount(source) else { return nil }
    let image = index < source.images.count ? source.images[index] : nil
    return imageioProperties(
        source.parsed, image: image, index: index,
        fileSize: source.data.count, container: false
    )
}
