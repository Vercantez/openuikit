// CGImageSource / CGImageDestination for PNG and JPEG on top of ImageCodec
// (CQuartz QZImageDecodeRGBA / QZImageEncodePNG / QZImageEncodeJPEG).
//
// Byte-level oracle: same files decoded by Apple ImageIO and this module
// must produce identical RGBA8 pixels (ImageIOTests; measured 2026-09-05).
// Property dictionaries and thumbnail geometry were measured the same day
// against Apple ImageIO on macOS 26.1.

import Foundation
import OpenCoreGraphics
#if canImport(CoreGraphics)
import CoreGraphics
#endif

private let imageioTypeIDSource: CFTypeID = 0x4949_5301

public final class CGImageSource: @unchecked Sendable {
    var data: Data
    var uniformType: CFString?
    var images: [CGImage]
    var status: CGImageSourceStatus
    var parsed: ImageIOParsedFile
    var isFinal: Bool
    let isIncremental: Bool

    init(
        data: Data,
        type: CFString?,
        images: [CGImage],
        status: CGImageSourceStatus,
        parsed: ImageIOParsedFile,
        isFinal: Bool,
        incremental: Bool
    ) {
        self.data = data
        self.uniformType = type
        self.images = images
        self.status = status
        self.parsed = parsed
        self.isFinal = isFinal
        self.isIncremental = incremental
    }
}

public func CGImageSourceGetTypeID() -> CFTypeID { imageioTypeIDSource }

public func CGImageSourceCopyTypeIdentifiers() -> CFArray {
    [kUTTypePNG, kUTTypeJPEG, kUTTypeGIF] as CFArray
}

public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource? {
    _ = options
    // MEASURED 2026-09-05 Apple ImageIO: empty and garbage bytes still
    // return a source (statusInvalidData, count 0). PNG type appears at
    // 10 bytes; a truncated typed PNG blob that is final reports
    // statusComplete with no image.
    let bytes = Data(data as Data)
    return imageioRefresh(
        CGImageSource(
            data: bytes,
            type: nil,
            images: [],
            status: .statusInvalidData,
            parsed: ImageIOParsedFile(),
            isFinal: true,
            incremental: false
        )
    )
}

public func CGImageSourceCreateWithURL(
    _ url: CFURL,
    _ options: CFDictionary?
) -> CGImageSource? {
    let path = (url as URL).path
    guard let bytes = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
    return CGImageSourceCreateWithData(bytes as CFData, options)
}

public func CGImageSourceCreateWithDataProvider(
    _ provider: CGDataProvider,
    _ options: CFDictionary?
) -> CGImageSource? {
#if canImport(CoreGraphics)
    guard let data = provider.data else { return nil }
    return CGImageSourceCreateWithData(data, options)
#else
    CGImageSourceCreateWithData(provider.data as CFData, options)
#endif
}

public func CGImageSourceCreateIncremental(_ options: CFDictionary?) -> CGImageSource {
    _ = options
    return CGImageSource(
        data: Data(),
        type: nil,
        images: [],
        status: .statusInvalidData,
        parsed: ImageIOParsedFile(),
        isFinal: false,
        incremental: true
    )
}

public func CGImageSourceUpdateData(_ isrc: CGImageSource, _ data: CFData, _ final: Bool) {
    guard isrc.isIncremental else { return }
    isrc.data = Data(data as Data)
    isrc.isFinal = final
    _ = imageioRefresh(isrc)
}

public func CGImageSourceUpdateDataProvider(
    _ isrc: CGImageSource,
    _ provider: CGDataProvider,
    _ final: Bool
) {
#if canImport(CoreGraphics)
    guard let data = provider.data else { return }
    CGImageSourceUpdateData(isrc, data, final)
#else
    CGImageSourceUpdateData(isrc, provider.data as CFData, final)
#endif
}

public func CGImageSourceGetStatus(_ isrc: CGImageSource) -> CGImageSourceStatus {
    isrc.status
}

public func CGImageSourceGetStatusAtIndex(
    _ isrc: CGImageSource,
    _ index: Int
) -> CGImageSourceStatus {
    guard index >= 0, index < CGImageSourceGetCount(isrc) else { return .statusInvalidData }
    return index < isrc.images.count ? isrc.status : .statusIncomplete
}

public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int {
    if !isrc.images.isEmpty { return isrc.images.count }
    if isrc.parsed.frameCount > 0 { return isrc.parsed.frameCount }
    if let type = isrc.uniformType, typeEquals(type, kUTTypeGIF) { return 0 }
    return isrc.uniformType == nil ? 0 : 1
}

public func CGImageSourceGetType(_ isrc: CGImageSource) -> CFString? {
    isrc.uniformType
}

public func CGImageSourceCreateImageAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage? {
    _ = options
    guard index >= 0, index < isrc.images.count else { return nil }
    return isrc.images[index]
}

public func CGImageSourceCreateThumbnailAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CGImage? {
    guard let image = CGImageSourceCreateImageAtIndex(isrc, index, options) else {
        return nil
    }
    return imageioThumbnail(image, options: options, orientation: isrc.parsed.orientation)
}

public func CGImageSourceCopyPropertiesAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard index >= 0, index < CGImageSourceGetCount(isrc) else { return nil }
    let image = index < isrc.images.count ? isrc.images[index] : nil
    return imageioMakeProperties(isrc.parsed, image: image, index: index, fileSize: isrc.data.count, container: false)
}

public func CGImageSourceCopyProperties(
    _ isrc: CGImageSource,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard isrc.uniformType != nil else { return nil }
    return imageioMakeProperties(isrc.parsed, image: nil, index: 0, fileSize: isrc.data.count, container: true)
}

@discardableResult
private func imageioRefresh(_ source: CGImageSource) -> CGImageSource {
    source.parsed = imageioParseFile(source.data)
    source.uniformType = source.parsed.type
    let bytes = [UInt8](source.data)
    if let bitmap = imageioDecodeBitmap(bytes),
       let image = imageioMakeCGImage(width: bitmap.width, height: bitmap.height, rgba: bitmap.pixels) {
        source.images = [image]
        source.status = source.isFinal ? .statusComplete : .statusIncomplete
    } else {
        source.images = []
        if source.uniformType != nil {
            source.status = source.isFinal ? .statusComplete : .statusIncomplete
        } else {
            source.status = .statusInvalidData
        }
    }
    return source
}

func typeEquals(_ lhs: CFString, _ rhs: CFString) -> Bool {
    String(describing: lhs) == String(describing: rhs)
}
