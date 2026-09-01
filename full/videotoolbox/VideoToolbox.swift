/// Linux starting point for Apple's public VideoToolbox module.
///
/// Constants, flags, session types, and the C/ObjC overlay compile and link.
/// Hardware encode/decode, pixel transfer, ColorSync, motion estimation, HDR
/// metadata, and frame-processor models are fail-closed: queries report no
/// support and create/process APIs return documented VideoToolbox errors
/// instead of fabricating compressed or decoded frames.

public typealias OSStatus = Int32
public typealias CFString = String
public typealias CFDictionary = [AnyHashable: Any]
public typealias CFArray = [Any]
public typealias CFTypeRef = AnyObject
public typealias CFTypeID = UInt
public typealias CFURL = String
public typealias DarwinBoolean = Bool
public typealias OSType = UInt32
public typealias CMVideoCodecType = UInt32
public typealias CMItemCount = Int
public typealias VTSession = CFTypeRef

/// Only the default allocator (`nil`) is representable on this Linux seed.
public enum CFAllocator: Sendable {}

public let noErr: OSStatus = 0

// MARK: - Portable CoreMedia / CoreVideo stand-ins
// These exist so VideoToolbox can compile as an isolated module. They are not
// a substitute for the CoreMedia/CoreVideo ports.

public struct CMTime: Equatable, Hashable, Sendable {
    public var value: Int64
    public var timescale: Int32
    public var flags: UInt32
    public var epoch: Int64

    public init(value: Int64 = 0, timescale: Int32 = 0, flags: UInt32 = 0, epoch: Int64 = 0) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }

    public static let invalid = CMTime()
    public static let zero = CMTime(value: 0, timescale: 1, flags: 1, epoch: 0)
}

public struct CMTimeRange: Equatable, Hashable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime = .invalid, duration: CMTime = .invalid) {
        self.start = start
        self.duration = duration
    }
}

public struct CMVideoDimensions: Equatable, Hashable, Sendable {
    public var width: Int32
    public var height: Int32

    public init(width: Int32 = 0, height: Int32 = 0) {
        self.width = width
        self.height = height
    }
}

open class CVPixelBuffer: @unchecked Sendable {
    public init() {}
}

public typealias CVImageBuffer = CVPixelBuffer

open class CVPixelBufferPool: @unchecked Sendable {
    public init() {}
}

open class CMSampleBuffer: @unchecked Sendable {
    public init() {}
}

open class CMFormatDescription: @unchecked Sendable {
    public init() {}
}

public typealias CMVideoFormatDescription = CMFormatDescription

public struct CMTaggedBuffer: Equatable, Sendable {
    public init() {}
}

open class __CMTaggedBufferGroup: @unchecked Sendable {
    public init() {}
}

open class CGImage: @unchecked Sendable {
    public init() {}
}

public typealias __VTMotionEstimationInfoFlags = UInt32

/// Portable CoreVideo read-only pixel-buffer overlay used by motion estimation
/// and frame-processor Swift APIs.
public final class CVReadOnlyPixelBuffer: @unchecked Sendable {
    public let pixelBuffer: CVPixelBuffer

    public init(_ pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
}

/// Metal command-buffer stand-in so `VTFrameProcessor.process(with:parameters:)`
/// can compile without importing Metal.
public protocol MTLCommandBuffer: AnyObject {}

// MARK: - OSStatus constants (public VTErrors.h values)

public var kVTPropertyNotSupportedErr: OSStatus { -12900 }
public var kVTPropertyReadOnlyErr: OSStatus { -12901 }
public var kVTParameterErr: OSStatus { -12902 }
public var kVTInvalidSessionErr: OSStatus { -12903 }
public var kVTAllocationFailedErr: OSStatus { -12904 }
public var kVTPixelTransferNotSupportedErr: OSStatus { -12905 }
public var kVTCouldNotFindVideoDecoderErr: OSStatus { -12906 }
public var kVTCouldNotCreateInstanceErr: OSStatus { -12907 }
public var kVTCouldNotFindVideoEncoderErr: OSStatus { -12908 }
public var kVTVideoDecoderBadDataErr: OSStatus { -12909 }
public var kVTVideoDecoderUnsupportedDataFormatErr: OSStatus { -12910 }
public var kVTVideoDecoderMalfunctionErr: OSStatus { -12911 }
public var kVTVideoEncoderMalfunctionErr: OSStatus { -12912 }
public var kVTVideoDecoderNotAvailableNowErr: OSStatus { -12913 }
public var kVTImageRotationNotSupportedErr: OSStatus { -12914 }
public var kVTPixelRotationNotSupportedErr: OSStatus { -12914 }
public var kVTVideoEncoderNotAvailableNowErr: OSStatus { -12915 }
public var kVTFormatDescriptionChangeNotSupportedErr: OSStatus { -12916 }
public var kVTInsufficientSourceColorDataErr: OSStatus { -12917 }
public var kVTCouldNotCreateColorCorrectionDataErr: OSStatus { -12918 }
public var kVTColorSyncTransformConvertFailedErr: OSStatus { -12919 }
public var kVTVideoDecoderAuthorizationErr: OSStatus { -12210 }
public var kVTVideoEncoderAuthorizationErr: OSStatus { -12211 }
public var kVTColorCorrectionPixelTransferFailedErr: OSStatus { -12212 }
public var kVTMultiPassStorageIdentifierMismatchErr: OSStatus { -12213 }
public var kVTMultiPassStorageInvalidErr: OSStatus { -12214 }
public var kVTFrameSiloInvalidTimeStampErr: OSStatus { -12215 }
public var kVTFrameSiloInvalidTimeRangeErr: OSStatus { -12216 }
public var kVTCouldNotFindTemporalFilterErr: OSStatus { -12217 }
public var kVTPixelTransferNotPermittedErr: OSStatus { -12218 }
public var kVTColorCorrectionImageRotationFailedErr: OSStatus { -12219 }
public var kVTVideoDecoderRemovedErr: OSStatus { -17690 }
public var kVTSessionMalfunctionErr: OSStatus { -17691 }
public var kVTVideoDecoderNeedsRosettaErr: OSStatus { -17692 }
public var kVTVideoEncoderNeedsRosettaErr: OSStatus { -17693 }
public var kVTVideoDecoderReferenceMissingErr: OSStatus { -17694 }
public var kVTVideoDecoderCallbackMessagingErr: OSStatus { -17695 }
public var kVTVideoDecoderUnknownErr: OSStatus { -17696 }
public var kVTExtensionDisabledErr: OSStatus { -17697 }
public var kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr: OSStatus { -17698 }
public var kVTCouldNotOutputTaggedBufferGroupErr: OSStatus { -17699 }
public var kVTCouldNotFindExtensionErr: OSStatus { -19510 }
public var kVTExtensionConflictErr: OSStatus { -19511 }
public var kVTVideoEncoderAutoWhiteBalanceNotLockedErr: OSStatus { -19512 }

public var kVTUnlimitedFrameDelayCount: Int { -1 }
public var kVTQPModulationLevel_Default: Int { -1 }
public var kVTQPModulationLevel_Disable: Int { 0 }

/// ColorSync-backed pixel transfer is a macOS host service. Linux reports false.
public var VT_SUPPORT_COLORSYNC_PIXEL_TRANSFER: Bool { false }

public enum VideoToolboxLinux {
    public static let statusCodes: [(String, OSStatus)] = [
        ("kVTPropertyNotSupportedErr", kVTPropertyNotSupportedErr),
        ("kVTPropertyReadOnlyErr", kVTPropertyReadOnlyErr),
        ("kVTParameterErr", kVTParameterErr),
        ("kVTInvalidSessionErr", kVTInvalidSessionErr),
        ("kVTAllocationFailedErr", kVTAllocationFailedErr),
        ("kVTPixelTransferNotSupportedErr", kVTPixelTransferNotSupportedErr),
        ("kVTCouldNotFindVideoDecoderErr", kVTCouldNotFindVideoDecoderErr),
        ("kVTCouldNotCreateInstanceErr", kVTCouldNotCreateInstanceErr),
        ("kVTCouldNotFindVideoEncoderErr", kVTCouldNotFindVideoEncoderErr),
        ("kVTVideoDecoderBadDataErr", kVTVideoDecoderBadDataErr),
        ("kVTVideoDecoderUnsupportedDataFormatErr", kVTVideoDecoderUnsupportedDataFormatErr),
        ("kVTVideoDecoderMalfunctionErr", kVTVideoDecoderMalfunctionErr),
        ("kVTVideoEncoderMalfunctionErr", kVTVideoEncoderMalfunctionErr),
        ("kVTVideoDecoderNotAvailableNowErr", kVTVideoDecoderNotAvailableNowErr),
        ("kVTImageRotationNotSupportedErr", kVTImageRotationNotSupportedErr),
        ("kVTPixelRotationNotSupportedErr", kVTPixelRotationNotSupportedErr),
        ("kVTVideoEncoderNotAvailableNowErr", kVTVideoEncoderNotAvailableNowErr),
        ("kVTFormatDescriptionChangeNotSupportedErr", kVTFormatDescriptionChangeNotSupportedErr),
        ("kVTInsufficientSourceColorDataErr", kVTInsufficientSourceColorDataErr),
        ("kVTCouldNotCreateColorCorrectionDataErr", kVTCouldNotCreateColorCorrectionDataErr),
        ("kVTColorSyncTransformConvertFailedErr", kVTColorSyncTransformConvertFailedErr),
        ("kVTVideoDecoderAuthorizationErr", kVTVideoDecoderAuthorizationErr),
        ("kVTVideoEncoderAuthorizationErr", kVTVideoEncoderAuthorizationErr),
        ("kVTColorCorrectionPixelTransferFailedErr", kVTColorCorrectionPixelTransferFailedErr),
        ("kVTMultiPassStorageIdentifierMismatchErr", kVTMultiPassStorageIdentifierMismatchErr),
        ("kVTMultiPassStorageInvalidErr", kVTMultiPassStorageInvalidErr),
        ("kVTFrameSiloInvalidTimeStampErr", kVTFrameSiloInvalidTimeStampErr),
        ("kVTFrameSiloInvalidTimeRangeErr", kVTFrameSiloInvalidTimeRangeErr),
        ("kVTCouldNotFindTemporalFilterErr", kVTCouldNotFindTemporalFilterErr),
        ("kVTPixelTransferNotPermittedErr", kVTPixelTransferNotPermittedErr),
        ("kVTColorCorrectionImageRotationFailedErr", kVTColorCorrectionImageRotationFailedErr),
        ("kVTVideoDecoderRemovedErr", kVTVideoDecoderRemovedErr),
        ("kVTSessionMalfunctionErr", kVTSessionMalfunctionErr),
        ("kVTVideoDecoderNeedsRosettaErr", kVTVideoDecoderNeedsRosettaErr),
        ("kVTVideoEncoderNeedsRosettaErr", kVTVideoEncoderNeedsRosettaErr),
        ("kVTVideoDecoderReferenceMissingErr", kVTVideoDecoderReferenceMissingErr),
        ("kVTVideoDecoderCallbackMessagingErr", kVTVideoDecoderCallbackMessagingErr),
        ("kVTVideoDecoderUnknownErr", kVTVideoDecoderUnknownErr),
        ("kVTExtensionDisabledErr", kVTExtensionDisabledErr),
        ("kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr", kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr),
        ("kVTCouldNotOutputTaggedBufferGroupErr", kVTCouldNotOutputTaggedBufferGroupErr),
        ("kVTCouldNotFindExtensionErr", kVTCouldNotFindExtensionErr),
        ("kVTExtensionConflictErr", kVTExtensionConflictErr),
        ("kVTVideoEncoderAutoWhiteBalanceNotLockedErr", kVTVideoEncoderAutoWhiteBalanceNotLockedErr),
    ]
}
