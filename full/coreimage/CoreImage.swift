import Foundation

/// Linux starting implementation of Apple's public CoreImage module.
///
/// Real: software `CIColor` / `CIVector` / `CIImage` / `CIFilter` surface,
/// CPU `createCGImage` / `render(toBitmap:)`, named filters measured on
/// iPhone SE 2x / iOS 26.1 (color controls, sepia, matrix, exposure, photo
/// cubes, Gaussian blur pad 3×radius), ISO 18004 QR + Code 128, PNG
/// round-trip and JPEG representation, filter-name registry, barcode
/// descriptors, and typed option / format constants.
///
/// Fail-closed: Metal, EAGL, IOSurface, CVPixelBuffer, AVDepthData, HEIF /
/// TIFF / OpenEXR, RAW decode, Aztec/PDF417 generators, QR detection, and
/// CIKL/Metal kernel compilation. Those paths return nil, throw
/// `CIRenderError.unsupported`, or yield empty results rather than
/// fabricating GPU or Apple-service objects.

public var COREIMAGE_SUPPORTS_IOSURFACE: Int32 { 0 }
public var COREIMAGE_SUPPORTS_OPENGLES: Int32 { 0 }
public var UNIFIED_CORE_IMAGE: Int32 { 1 }
