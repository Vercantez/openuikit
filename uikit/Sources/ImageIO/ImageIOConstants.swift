import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public let kUTTypePNG: CFString = "public.png" as CFString
public let kUTTypeJPEG: CFString = "public.jpeg" as CFString
public let kUTTypeImage: CFString = "public.image" as CFString

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth" as CFString
public let kCGImagePropertyPixelHeight: CFString = "PixelHeight" as CFString
public let kCGImagePropertyOrientation: CFString = "Orientation" as CFString
public let kCGImagePropertyHasAlpha: CFString = "HasAlpha" as CFString
public let kCGImagePropertyColorModel: CFString = "ColorModel" as CFString
public let kCGImagePropertyColorModelRGB: CFString = "RGB" as CFString
public let kCGImagePropertyDPIWidth: CFString = "DPIWidth" as CFString
public let kCGImagePropertyDPIHeight: CFString = "DPIHeight" as CFString
public let kCGImagePropertyDepth: CFString = "Depth" as CFString

public let kCGImageSourceShouldCache: CFString = "kCGImageSourceShouldCache" as CFString
public let kCGImageSourceShouldCacheImmediately: CFString =
    "kCGImageSourceShouldCacheImmediately" as CFString
public let kCGImageSourceCreateThumbnailFromImageAlways: CFString =
    "kCGImageSourceCreateThumbnailFromImageAlways" as CFString
public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString =
    "kCGImageSourceCreateThumbnailFromImageIfAbsent" as CFString
public let kCGImageSourceCreateThumbnailWithTransform: CFString =
    "kCGImageSourceCreateThumbnailWithTransform" as CFString
public let kCGImageSourceThumbnailMaxPixelSize: CFString =
    "kCGImageSourceThumbnailMaxPixelSize" as CFString
public let kCGImageSourceTypeIdentifierHint: CFString =
    "kCGImageSourceTypeIdentifierHint" as CFString

public let kCGImageDestinationLossyCompressionQuality: CFString =
    "kCGImageDestinationLossyCompressionQuality" as CFString

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

func imageioDetectType(_ data: Data) -> CFString? {
    let bytes = Array(data.prefix(8))
    if bytes.count >= 8,
       bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47,
       bytes[4] == 0x0D, bytes[5] == 0x0A, bytes[6] == 0x1A, bytes[7] == 0x0A {
        return kUTTypePNG
    }
    if bytes.count >= 2, bytes[0] == 0xFF, bytes[1] == 0xD8 {
        return kUTTypeJPEG
    }
    return nil
}
