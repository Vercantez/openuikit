import CoreFoundation
import Foundation

/// Linux starting implementation of Apple's public `CoreMedia` module.
///
/// Foundational C-layout value types (`CMTime`, `CMTimeRange`, `CMTimeMapping`,
/// `CMSampleTimingInfo`, `CMVideoDimensions`) and the media-type / format /
/// sample-buffer identity surfaces needed by AVFAudio, AVFoundation, Speech,
/// ReplayKit, and app code live here. Isolated Linux Swift cannot emit
/// `@_cdecl` entry points that pass these Swift structs by value; those
/// functions are Swift overlay with matching field layout. Central ARM64
/// integration must Clang-import the C structs before claiming TBD C ABI.
/// Swift overlay members without a C calling convention are Swift-only.
///
/// Darwin `FourCharCode` and `OSStatus` are not available on this isolated
/// Linux gate. Four-character codes use `UInt32` with the same width as the
/// C typedef; `OSStatus`-typed C APIs stay conditionally compiled out until
/// the central build supplies Darwin. CoreAudioTypes and CoreVideo APIs are
/// likewise gated on `canImport` of those real modules.

public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeEpoch = Int64

/// C `FourCharCode` is Darwin-owned. Isolated Linux uses the identical
/// 32-bit layout without declaring a local `FourCharCode` typedef.
public typealias CMMediaType = UInt32
public typealias CMVideoCodecType = UInt32
public typealias CMPixelFormatType = UInt32
public typealias CMAudioCodecType = UInt32
public typealias CMClosedCaptionFormatType = UInt32
public typealias CMMuxedStreamType = UInt32
public typealias CMSubtitleFormatType = UInt32
public typealias CMMetadataFormatType = UInt32
public typealias CMTimeCodeFormatType = UInt32
public typealias CMTextFormatType = UInt32
public typealias CMTaggedBufferGroupFormatType = UInt32

public typealias CMImageDescriptionFlavor = CFString
public typealias CMSoundDescriptionFlavor = CFString
public typealias CMTextDescriptionFlavor = CFString
public typealias CMMetadataDescriptionFlavor = CFString
public typealias CMClosedCaptionDescriptionFlavor = CFString
public typealias CMTimeCodeDescriptionFlavor = CFString

public typealias CMAttachmentMode = UInt32
public typealias CMBlockBufferFlags = UInt32
public typealias CMPersistentTrackID = Int32
public typealias CMAudioFormatDescriptionMask = UInt32
/// Linux stand-in for Darwin's `DarwinBoolean` used by CoreMedia C callbacks.
public struct DarwinBoolean: ExpressibleByBooleanLiteral, Equatable, Sendable {
    public var boolValue: Bool
    public init(_ value: Bool) { self.boolValue = value }
    public init(booleanLiteral value: Bool) { self.boolValue = value }
}

public typealias CMBufferQueueTriggerCondition = Int32
public typealias CMBufferQueueTriggerToken = OpaquePointer
public typealias CMBufferGetTimeCallback = (CMBuffer, UnsafeMutableRawPointer?) -> CMTime
public typealias CMBufferGetTimeHandler = (CMBuffer) -> CMTime
public typealias CMBufferGetBooleanCallback = (CMBuffer, UnsafeMutableRawPointer?) -> DarwinBoolean
public typealias CMBufferGetBooleanHandler = (CMBuffer) -> Bool
public typealias CMBufferGetSizeCallback = (CMBuffer, UnsafeMutableRawPointer?) -> Int
public typealias CMBufferGetSizeHandler = (CMBuffer) -> Int
public typealias CMBufferCompareCallback = (CMBuffer, CMBuffer, UnsafeMutableRawPointer?) -> CFComparisonResult
public typealias CMBufferCompareHandler = (CMBuffer, CMBuffer) -> CFComparisonResult
public typealias CMBufferQueueTriggerCallback = (UnsafeMutableRawPointer?, CMBufferQueueTriggerToken) -> Void
public typealias CMBufferQueueTriggerHandler = (CMBufferQueueTriggerToken) -> Void
public typealias CMBufferValidationCallback = (CMBufferQueue, CMBuffer, UnsafeMutableRawPointer?) -> OSStatus
public typealias CMBufferValidationHandler = (CMBufferQueue, CMBuffer) -> OSStatus
public typealias CMTextDisplayFlags = UInt32
public typealias CMTextJustificationValue = Int8
public typealias CMBaseClassVersion = UInt
public typealias CMStructVersion = UInt

public typealias CMItemCount = CFIndex
public typealias CMItemIndex = CFIndex
public typealias CMAttachmentBearer = CFTypeRef
public typealias CMBuffer = CFTypeRef
public typealias CMClockOrTimebase = CFTypeRef

public typealias CMAudioFormatDescription = CMFormatDescription
public typealias CMVideoFormatDescription = CMFormatDescription
public typealias CMMuxedFormatDescription = CMFormatDescription
public typealias CMClosedCaptionFormatDescription = CMFormatDescription
public typealias CMTextFormatDescription = CMFormatDescription
public typealias CMTimeCodeFormatDescription = CMFormatDescription
public typealias CMMetadataFormatDescription = CMFormatDescription
public typealias CMTaggedBufferGroupFormatDescription = CMFormatDescription

public typealias CMSampleBufferInvalidateCallback = (CMSampleBuffer, UInt64) -> Void
public typealias CMSampleBufferInvalidateHandler = (CMSampleBuffer) -> Void
public typealias CMSampleBufferMakeDataReadyCallback = (CMSampleBuffer, UnsafeMutableRawPointer?) -> OSStatus
public typealias CMSampleBufferMakeDataReadyHandler = (CMSampleBuffer) -> OSStatus

public var kCMTimeZero: CMTime { .zero }
public var kCMTimeInvalid: CMTime { .invalid }
public var kCMTimeIndefinite: CMTime { .indefinite }
public var kCMTimePositiveInfinity: CMTime { .positiveInfinity }
public var kCMTimeNegativeInfinity: CMTime { .negativeInfinity }
public var kCMTimeRangeZero: CMTimeRange { .zero }
public var kCMTimeRangeInvalid: CMTimeRange { .invalid }
public var kCMTimeMappingInvalid: CMTimeMapping { .invalid }

public var kCMTimeMaxTimescale: Int { Int(Int32.max) }

/// C `CMITEMCOUNT_MAX` is a preprocessor macro. The Swift overlay exposes it
/// as `Int.max`, matching 64-bit `CMItemCount` / `CFIndex`.
public var CMITEMCOUNT_MAX: Int { Int.max }

/// Linux overlay of CoreMedia header feature flags. Annotation macros are
/// true because this module uses Swift nullability and derived enums;
/// Darwin C visibility / timebase source terminology stay off.
public var COREMEDIA_TRUE: Bool { true }
public var COREMEDIA_FALSE: Bool { false }
public var COREMEDIA_DECLARE_BRIDGED_TYPES: Bool { true }
public var COREMEDIA_DECLARE_NULLABILITY: Bool { true }
public var COREMEDIA_DECLARE_NULLABILITY_BEGIN_END: Bool { true }
public var COREMEDIA_DECLARE_RELEASES_ARGUMENT: Bool { true }
public var COREMEDIA_DECLARE_RETURNS_NOT_RETAINED_ON_PARAMETERS: Bool { true }
public var COREMEDIA_DECLARE_RETURNS_RETAINED: Bool { true }
public var COREMEDIA_DECLARE_RETURNS_RETAINED_BLOCK: Bool { true }
public var COREMEDIA_DECLARE_RETURNS_RETAINED_ON_PARAMETERS: Bool { true }
public var COREMEDIA_USE_DERIVED_ENUMS_FOR_CONSTANTS: Bool { true }
public var COREMEDIA_CMBASECLASS_VERSION_IS_POINTER_ALIGNED: Bool { true }
public var COREMEDIA_USE_ALIGNED_CMBASECLASS_VERSION: Bool { true }
public var COREMEDIA_EXPORTS_USE_EXPLICIT_VISIBILITY: Int32 { 0 }
public var CMTIMEBASE_USE_SOURCE_TERMINOLOGY: Int32 { 0 }

public var kCMPersistentTrackID_Invalid: CMPersistentTrackID { 0 }

public var kCMAttachmentMode_ShouldNotPropagate: CMAttachmentMode { 0 }
public var kCMAttachmentMode_ShouldPropagate: CMAttachmentMode { 1 }

public var kCMBlockBufferAssureMemoryNowFlag: CMBlockBufferFlags { 1 << 0 }
public var kCMBlockBufferAlwaysCopyDataFlag: CMBlockBufferFlags { 1 << 1 }
public var kCMBlockBufferDontOptimizeDepthFlag: CMBlockBufferFlags { 1 << 2 }
public var kCMBlockBufferPermitEmptyReferenceFlag: CMBlockBufferFlags { 1 << 3 }
public var kCMBlockBufferCustomBlockSourceVersion: UInt32 { 1 }

// CMTextFormatDescription.h display flags and justification.
public var kCMTextDisplayFlag_scrollIn: CMTextDisplayFlags { 0x0000_0020 }
public var kCMTextDisplayFlag_scrollOut: CMTextDisplayFlags { 0x0000_0040 }
public var kCMTextDisplayFlag_scrollDirectionMask: CMTextDisplayFlags { 0x0000_0180 }
public var kCMTextDisplayFlag_scrollDirection_bottomToTop: CMTextDisplayFlags { 0x0000_0000 }
public var kCMTextDisplayFlag_scrollDirection_rightToLeft: CMTextDisplayFlags { 0x0000_0080 }
public var kCMTextDisplayFlag_scrollDirection_topToBottom: CMTextDisplayFlags { 0x0000_0100 }
public var kCMTextDisplayFlag_scrollDirection_leftToRight: CMTextDisplayFlags { 0x0000_0180 }
public var kCMTextDisplayFlag_continuousKaraoke: CMTextDisplayFlags { 0x0000_0800 }
public var kCMTextDisplayFlag_writeTextVertically: CMTextDisplayFlags { 0x0002_0000 }
public var kCMTextDisplayFlag_fillTextRegion: CMTextDisplayFlags { 0x0004_0000 }
public var kCMTextDisplayFlag_obeySubtitleFormatting: CMTextDisplayFlags { 0x2000_0000 }
public var kCMTextDisplayFlag_forcedSubtitlesPresent: CMTextDisplayFlags { 0x4000_0000 }
public var kCMTextDisplayFlag_allSubtitlesForced: CMTextDisplayFlags { 0x8000_0000 }
public var kCMTextJustification_left_top: CMTextJustificationValue { 0 }
public var kCMTextJustification_centered: CMTextJustificationValue { 1 }
public var kCMTextJustification_bottom_right: CMTextJustificationValue { -1 }
public var kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment: UInt32 { 1 << 0 }

@inline(__always)
internal func cmFourCC(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> UInt32 {
    (UInt32(a) << 24) | (UInt32(b) << 16) | (UInt32(c) << 8) | UInt32(d)
}

@inline(__always)
internal func cmFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    precondition(bytes.count == 4, "FourCC literal must be four UTF-8 bytes")
    return cmFourCC(bytes[0], bytes[1], bytes[2], bytes[3])
}

internal func cmMakeCFString(_ string: String) -> CFString {
    string.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

internal func cmCFDictionary(_ pairs: [(CFString, CFTypeRef)]) -> CFDictionary {
    var keyCB = kCFTypeDictionaryKeyCallBacks
    var valCB = kCFTypeDictionaryValueCallBacks
    let dict = CFDictionaryCreateMutable(
        kCFAllocatorDefault,
        CFIndex(pairs.count),
        &keyCB,
        &valCB
    )!
    for (key, value) in pairs {
        CFDictionarySetValue(
            dict,
            unsafeBitCast(key, to: UnsafeRawPointer.self),
            unsafeBitCast(value, to: UnsafeRawPointer.self)
        )
    }
    return dict
}

internal func cmCFDictionaryValue(_ dictionary: CFDictionary, key: CFString) -> UnsafeRawPointer? {
    CFDictionaryGetValue(
        dictionary,
        unsafeBitCast(key, to: UnsafeRawPointer.self)
    )
}

internal func cmNSError(code: Int) -> NSError {
    NSError(domain: NSOSStatusErrorDomain, code: code, userInfo: nil)
}

internal final class CMUnfairLock: @unchecked Sendable {
    private let lock = NSRecursiveLock()

    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
