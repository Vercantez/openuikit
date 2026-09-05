import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public let kUTTypePNG: CFString = "public.png" as CFString
public let kUTTypeJPEG: CFString = "public.jpeg" as CFString
public let kUTTypeGIF: CFString = "com.compuserve.gif" as CFString
public let kUTTypeTIFF: CFString = "public.tiff" as CFString
public let kUTTypeBMP: CFString = "com.microsoft.bmp" as CFString
public let kUTTypeImage: CFString = "public.image" as CFString
public let kUTTypeJPEG2000: CFString = "public.jpeg-2000" as CFString
public let kUTTypeHEIC: CFString = "public.heic" as CFString
public let kUTTypeHEIF: CFString = "public.heif" as CFString

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth" as CFString
public let kCGImagePropertyPixelHeight: CFString = "PixelHeight" as CFString
public let kCGImagePropertyOrientation: CFString = "Orientation" as CFString
public let kCGImagePropertyHasAlpha: CFString = "HasAlpha" as CFString
public let kCGImagePropertyColorModel: CFString = "ColorModel" as CFString
public let kCGImagePropertyColorModelRGB: CFString = "RGB" as CFString
public let kCGImagePropertyDPIWidth: CFString = "DPIWidth" as CFString
public let kCGImagePropertyDPIHeight: CFString = "DPIHeight" as CFString
public let kCGImagePropertyDepth: CFString = "Depth" as CFString
public let kCGImagePropertyFileSize: CFString = "FileSize" as CFString
public let kCGImagePropertyProfileName: CFString = "ProfileName" as CFString
public let kCGImagePropertyColorModelGray: CFString = "Gray" as CFString

public let kCGImagePropertyPNGDictionary: CFString = "{PNG}" as CFString
public let kCGImagePropertyPNGGamma: CFString = "Gamma" as CFString
public let kCGImagePropertyPNGTitle: CFString = "Title" as CFString
public let kCGImagePropertyPNGAuthor: CFString = "Author" as CFString
public let kCGImagePropertyPNGDescription: CFString = "Description" as CFString
public let kCGImagePropertyPNGCopyright: CFString = "Copyright" as CFString
public let kCGImagePropertyPNGSoftware: CFString = "Software" as CFString
public let kCGImagePropertyPNGComment: CFString = "Comment" as CFString
public let kCGImagePropertyPNGInterlaceType: CFString = "InterlaceType" as CFString
public let kCGImagePropertyPNGXPixelsPerMeter: CFString = "XPixelsPerMeter" as CFString
public let kCGImagePropertyPNGYPixelsPerMeter: CFString = "YPixelsPerMeter" as CFString

public let kCGImagePropertyJFIFDictionary: CFString = "{JFIF}" as CFString
public let kCGImagePropertyJFIFIsProgressive: CFString = "IsProgressive" as CFString
public let kCGImagePropertyJFIFVersion: CFString = "JFIFVersion" as CFString
public let kCGImagePropertyJFIFDensityUnit: CFString = "DensityUnit" as CFString
public let kCGImagePropertyJFIFXDensity: CFString = "XDensity" as CFString
public let kCGImagePropertyJFIFYDensity: CFString = "YDensity" as CFString

public let kCGImagePropertyTIFFDictionary: CFString = "{TIFF}" as CFString
public let kCGImagePropertyTIFFOrientation: CFString = "Orientation" as CFString
public let kCGImagePropertyTIFFMake: CFString = "Make" as CFString
public let kCGImagePropertyTIFFModel: CFString = "Model" as CFString
public let kCGImagePropertyTIFFXResolution: CFString = "XResolution" as CFString
public let kCGImagePropertyTIFFYResolution: CFString = "YResolution" as CFString
public let kCGImagePropertyTIFFResolutionUnit: CFString = "ResolutionUnit" as CFString

public let kCGImagePropertyExifDictionary: CFString = "{Exif}" as CFString
public let kCGImagePropertyExifDateTimeOriginal: CFString = "DateTimeOriginal" as CFString
public let kCGImagePropertyExifUserComment: CFString = "UserComment" as CFString
public let kCGImagePropertyExifPixelXDimension: CFString = "PixelXDimension" as CFString
public let kCGImagePropertyExifPixelYDimension: CFString = "PixelYDimension" as CFString
public let kCGImagePropertyExifColorSpace: CFString = "ColorSpace" as CFString

public let kCGImagePropertyGPSDictionary: CFString = "{GPS}" as CFString
public let kCGImagePropertyGPSLatitude: CFString = "Latitude" as CFString
public let kCGImagePropertyGPSLatitudeRef: CFString = "LatitudeRef" as CFString
public let kCGImagePropertyGPSLongitude: CFString = "Longitude" as CFString
public let kCGImagePropertyGPSLongitudeRef: CFString = "LongitudeRef" as CFString
public let kCGImagePropertyGPSAltitude: CFString = "Altitude" as CFString
public let kCGImagePropertyGPSAltitudeRef: CFString = "AltitudeRef" as CFString

public let kCGImagePropertyGIFDictionary: CFString = "{GIF}" as CFString
public let kCGImagePropertyGIFLoopCount: CFString = "LoopCount" as CFString
public let kCGImagePropertyGIFDelayTime: CFString = "DelayTime" as CFString
public let kCGImagePropertyGIFUnclampedDelayTime: CFString = "UnclampedDelayTime" as CFString
public let kCGImagePropertyGIFCanvasPixelWidth: CFString = "CanvasPixelWidth" as CFString
public let kCGImagePropertyGIFCanvasPixelHeight: CFString = "CanvasPixelHeight" as CFString
public let kCGImagePropertyGIFHasGlobalColorMap: CFString = "HasGlobalColorMap" as CFString

public let kCGImagePropertyIPTCDictionary: CFString = "{IPTC}" as CFString
public let kCGImagePropertyIPTCObjectName: CFString = "ObjectName" as CFString
public let kCGImagePropertyIPTCByline: CFString = "Byline" as CFString
public let kCGImagePropertyIPTCCaptionAbstract: CFString = "Caption/Abstract" as CFString
public let kCGImagePropertyIPTCCopyrightNotice: CFString = "CopyrightNotice" as CFString

public let kCGImageSourceShouldAllowFloat: CFString = "kCGImageSourceShouldAllowFloat" as CFString

public let kCGImageDestinationOrientation: CFString = "kCGImageDestinationOrientation" as CFString

public let kCGImageMetadataNamespaceExif: CFString = "http://ns.adobe.com/exif/1.0/" as CFString
public let kCGImageMetadataPrefixExif: CFString = "exif" as CFString
public let kCGImageMetadataNamespaceTIFF: CFString = "http://ns.adobe.com/tiff/1.0/" as CFString
public let kCGImageMetadataPrefixTIFF: CFString = "tiff" as CFString

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
    let bytes = Array(data.prefix(14))
    // MEASURED 2026-09-05 Apple ImageIO: PNG type appears at 10 bytes.
    if bytes.count >= 10,
       bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47,
       bytes[4] == 0x0D, bytes[5] == 0x0A, bytes[6] == 0x1A, bytes[7] == 0x0A {
        return kUTTypePNG
    }
    if bytes.count >= 2, bytes[0] == 0xFF, bytes[1] == 0xD8 {
        return kUTTypeJPEG
    }
    if bytes.count >= 6,
       bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46,
       bytes[3] == 0x38, (bytes[4] == 0x37 || bytes[4] == 0x39),
       bytes[5] == 0x61 {
        return kUTTypeGIF
    }
    return nil
}

func imageioOptionInt(_ options: CFDictionary?, _ key: CFString) -> Int? {
    guard let options else { return nil }
    let ns = options as NSDictionary
    if let number = ns[key] as? NSNumber { return number.intValue }
    return nil
}

func imageioOptionBool(_ options: CFDictionary?, _ key: CFString) -> Bool {
    guard let options else { return false }
    let ns = options as NSDictionary
    if let flag = ns[key] as? Bool { return flag }
    if let number = ns[key] as? NSNumber { return number.boolValue }
    return false
}
