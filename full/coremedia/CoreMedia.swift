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

public typealias CMAttachmentMode = UInt32
public typealias CMBlockBufferFlags = UInt32
public typealias CMPersistentTrackID = Int32
public typealias CMAudioFormatDescriptionMask = UInt32
public typealias CMBufferQueueTriggerCondition = Int32
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

public var kCMTimeMaxTimescale: Int { Int(Int32.max) }

public var kCMPersistentTrackID_Invalid: CMPersistentTrackID { 0 }

public var kCMAttachmentMode_ShouldNotPropagate: CMAttachmentMode { 0 }
public var kCMAttachmentMode_ShouldPropagate: CMAttachmentMode { 1 }

public var kCMBlockBufferAssureMemoryNowFlag: CMBlockBufferFlags { 1 << 0 }
public var kCMBlockBufferAlwaysCopyDataFlag: CMBlockBufferFlags { 1 << 1 }
public var kCMBlockBufferDontOptimizeDepthFlag: CMBlockBufferFlags { 1 << 2 }
public var kCMBlockBufferPermitEmptyReferenceFlag: CMBlockBufferFlags { 1 << 3 }
public var kCMBlockBufferCustomBlockSourceVersion: UInt32 { 1 }

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
    private let lock = NSLock()

    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
