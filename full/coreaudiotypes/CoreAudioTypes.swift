/// Canonical Linux starting point for the `CoreAudioTypes` module.
///
/// This framework is a clean-room reconstruction of the Xcode 26.1 iPhoneOS
/// public Swift surface. It provides one nominal identity (`CoreAudioTypes` /
/// `libCoreAudioTypes.dylib`) for downstream CoreAudio, AudioToolbox, AVFAudio,
/// AudioUnit, CoreMedia, and unchanged apps.
///
/// Layouts follow the sealed symbol-graph field types and declaration order.
/// Numeric constants absent from the graph are pinned to Xcode 26.1 iPhoneOS
/// compile-time oracle observations and locked down by a downstream runtime.
///
/// No CoreFoundation-owned type appears on a seeded public signature, so this
/// product module does not `import CoreFoundation`. Darwin `OSType`/`OSStatus`
/// names are required by `AudioClassDescription` and the `kAudio_*` error
/// constants; they are MacTypes identities, not CoreAudioTypes graph IDs and
/// not CoreFoundation lookalikes.

/// Four-character code used by `AudioClassDescription` (Darwin MacTypes).
public typealias OSType = UInt32

/// Status code used by the `kAudio_*` error constants (Darwin MacTypes).
public typealias OSStatus = Int32

public typealias AudioChannelLabel = UInt32
public typealias AudioChannelLayoutTag = UInt32
public typealias AudioFormatFlags = UInt32
public typealias AudioFormatID = UInt32
public typealias AudioSampleType = Int16
public typealias AudioUnitSampleType = Int32
public typealias AVAudioInteger = Int
public typealias AVAudioUInteger = UInt
public typealias AudioSessionID = UInt32

/// Channel count packed in the low 16 bits of an `AudioChannelLayoutTag`.
///
/// The graph records this function but not the mask. The public tag packing
/// convention uses the low 16 bits for the channel count; the Xcode 26.1
/// Apple oracle confirms that mask for ordinary and zero-count tags.
public func AudioChannelLayoutTag_GetNumberOfChannels(
    _ inLayoutTag: AudioChannelLayoutTag
) -> UInt32 {
    inLayoutTag & 0x0000_FFFF
}

/// Fail-closed arithmetic for flexible-array trailing-element byte counts.
///
/// Graph-absent helper; internal so it is not extra public surface.
enum CoreAudioTypesFlexibleArray {
    enum Problem: Error, Equatable {
        case negativeCount
        case overflow
    }

    /// Byte count for `count` trailing elements starting at `leadingOffset`.
    /// `count == 0` is the header up to the first element; `count == 1` matches
    /// the embedded single-element struct size when there is no extra tail padding.
    static func byteCount(
        leadingOffset: Int,
        elementStride: Int,
        count: Int
    ) throws -> Int {
        if count < 0 {
            throw Problem.negativeCount
        }
        if leadingOffset < 0 || elementStride < 0 {
            throw Problem.overflow
        }
        let (product, productOverflow) = elementStride.multipliedReportingOverflow(by: count)
        if productOverflow {
            throw Problem.overflow
        }
        let (total, totalOverflow) = leadingOffset.addingReportingOverflow(product)
        if totalOverflow {
            throw Problem.overflow
        }
        return total
    }

    static func audioBufferListByteCount(bufferCount: Int) throws -> Int {
        let leading = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)
            ?? MemoryLayout<UInt32>.stride
        return try byteCount(
            leadingOffset: leading,
            elementStride: MemoryLayout<AudioBuffer>.stride,
            count: bufferCount
        )
    }

    static func audioChannelLayoutByteCount(descriptionCount: Int) throws -> Int {
        let leading = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)
            ?? (MemoryLayout<UInt32>.stride * 3)
        return try byteCount(
            leadingOffset: leading,
            elementStride: MemoryLayout<AudioChannelDescription>.stride,
            count: descriptionCount
        )
    }
}
