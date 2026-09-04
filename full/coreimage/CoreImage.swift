import Foundation

/// Linux starting implementation of Apple's public CoreImage module.
///
/// Real: software `CIColor` / `CIVector` / `CIImage` / `CIFilter` surface,
/// a deterministic CPU `CILinearGradient` rasterizer (the original lane
/// slice), filter-name registry, barcode descriptors, fail-closed detectors,
/// and typed option / format constants.
///
/// Fail-closed: Metal, EAGL, IOSurface, CVPixelBuffer, AVDepthData, JPEG/HEIF
/// /TIFF/PNG/EXR codecs, RAW decode, and CIKL/Metal kernel compilation. Those
/// paths return nil, throw `CIRenderError.unsupported`, or yield empty
/// results rather than fabricating GPU or Apple-service objects.

public var COREIMAGE_SUPPORTS_IOSURFACE: Int32 { 0 }
public var COREIMAGE_SUPPORTS_OPENGLES: Int32 { 0 }
public var UNIFIED_CORE_IMAGE: Int32 { 1 }
