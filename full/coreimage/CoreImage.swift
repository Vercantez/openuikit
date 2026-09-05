import Foundation

/// Linux starting implementation of Apple's public CoreImage module.
///
/// Real: software `CIColor` / `CIVector` / `CIImage` / `CIFilter` surface,
/// CPU `createCGImage` / `render(toBitmap:)` / PNG / JPEG, named filters
/// using Apple's published working-space formulas (color controls, sepia
/// matrix, exposure 2^EV, hue rotation, Gaussian 3σ pad), ISO 18004 QR
/// data codewords + Code 128, filter-name registry, barcode descriptors,
/// and typed option / format constants.
///
/// Fail-closed: Metal, EAGL, IOSurface, CVPixelBuffer, AVDepthData, HEIF /
/// TIFF / OpenEXR, RAW decode, Aztec/PDF417 generators, QR detection, and
/// CIKL/Metal kernel compilation. Those paths return nil, throw
/// `CIRenderError.unsupported`, or yield empty results rather than
/// fabricating GPU or Apple-service objects.

public var COREIMAGE_SUPPORTS_IOSURFACE: Int32 { 0 }
public var COREIMAGE_SUPPORTS_OPENGLES: Int32 { 0 }
public var UNIFIED_CORE_IMAGE: Int32 { 1 }
