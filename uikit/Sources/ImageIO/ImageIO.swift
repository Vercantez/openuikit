// CGImageSource / CGImageDestination for PNG and JPEG on top of ImageCodec
// (CQuartz QZImageDecodeRGBA / QZImageEncodePNG / QZImageEncodeJPEG).
//
// Byte-level oracle: same files decoded by Apple ImageIO and this module
// must produce identical RGBA8 pixels (ImageIOTests; measured 2026-09-05).

import Foundation
import OpenCoreGraphics
#if canImport(CoreGraphics)
import CoreGraphics
#endif

private let imageioTypeIDSource: CFTypeID = 0x4949_5301

public final class CGImageSource: @unchecked Sendable {
    let data: Data
    let uniformType: CFString?
    var images: [CGImage]
    var status: CGImageSourceStatus

    init(data: Data, type: CFString?, images: [CGImage], status: CGImageSourceStatus) {
        self.data = data
        self.uniformType = type
        self.images = images
        self.status = status
    }
}

public func CGImageSourceGetTypeID() -> CFTypeID { imageioTypeIDSource }

public func CGImageSourceCopyTypeIdentifiers() -> CFArray {
    [kUTTypePNG, kUTTypeJPEG] as CFArray
}

public func CGImageSourceCreateWithData(
    _ data: CFData,
    _ options: CFDictionary?
) -> CGImageSource? {
    _ = options
    let bytes = Data(data as Data)
    return imageioSource(from: bytes)
}

public func CGImageSourceCreateWithURL(
    _ url: CFURL,
    _ options: CFDictionary?
) -> CGImageSource? {
    let path = (url as URL).path
    guard let bytes = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
    return CGImageSourceCreateWithData(bytes as CFData, options)
}

public func CGImageSourceCreateIncremental(_ options: CFDictionary?) -> CGImageSource {
    _ = options
    return CGImageSource(
        data: Data(),
        type: Optional<CFString>.none,
        images: [],
        status: CGImageSourceStatus.statusInvalidData
    )
}

public func CGImageSourceUpdateData(_ isrc: CGImageSource, _ data: CFData, _ final: Bool) {
    _ = final
    let bytes = Data(data as Data)
    if let decoded = imageioSource(from: bytes) {
        isrc.images = decoded.images
        isrc.status = decoded.status
    }
}

public func CGImageSourceGetStatus(_ isrc: CGImageSource) -> CGImageSourceStatus {
    isrc.status
}

public func CGImageSourceGetStatusAtIndex(
    _ isrc: CGImageSource,
    _ index: Int
) -> CGImageSourceStatus {
    guard index >= 0, index < isrc.images.count else { return .statusInvalidData }
    return isrc.status
}

public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int {
    isrc.images.count
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
    // Thumbnail resampling is not invented: return the decoded frame.
    // MEASURED 2026-09-05: corpus callers (Hackers ThumbnailView, element-ios
    // MXKTools) pass kCGImageSourceThumbnailMaxPixelSize; those sizes are
    // recorded as an open question in docs/agent_reports/silent-frameworks.md.
    _ = options
    return CGImageSourceCreateImageAtIndex(isrc, index, Optional<CFDictionary>.none)
}

public func CGImageSourceCopyPropertiesAtIndex(
    _ isrc: CGImageSource,
    _ index: Int,
    _ options: CFDictionary?
) -> CFDictionary? {
    _ = options
    guard index >= 0, index < isrc.images.count else { return nil }
    let image = isrc.images[index]
    let width: Int
    let height: Int
#if canImport(CoreGraphics)
    width = image.width
    height = image.height
#else
    width = image.width
    height = image.height
#endif
    return [
        kCGImagePropertyPixelWidth: width,
        kCGImagePropertyPixelHeight: height,
        kCGImagePropertyOrientation: CGImagePropertyOrientation.up.rawValue,
        kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
        kCGImagePropertyDepth: 8,
        kCGImagePropertyHasAlpha: true,
    ] as CFDictionary
}

public func CGImageSourceCopyProperties(
    _ isrc: CGImageSource,
    _ options: CFDictionary?
) -> CFDictionary? {
    CGImageSourceCopyPropertiesAtIndex(isrc, 0, options)
}

private func imageioSource(from data: Data) -> CGImageSource? {
    guard !data.isEmpty else { return nil }
    let type = imageioDetectType(data)
    let bytes = [UInt8](data)
    guard let bitmap = imageioDecodeBitmap(bytes) else {
        if type != nil {
            return CGImageSource(
                data: data,
                type: type,
                images: [],
                status: CGImageSourceStatus.statusInvalidData
            )
        }
        return nil
    }
    guard let image = imageioMakeCGImage(
        width: bitmap.width,
        height: bitmap.height,
        rgba: bitmap.pixels
    ) else { return nil }
    return CGImageSource(
        data: data,
        type: type ?? kUTTypePNG,
        images: [image],
        status: CGImageSourceStatus.statusComplete
    )
}
