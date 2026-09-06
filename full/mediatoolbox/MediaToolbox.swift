import CoreFoundation
import Foundation

#if canImport(CoreMedia)
@_exported import CoreMedia
#endif
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif

/// Linux starting implementation of Apple's public `MediaToolbox` module.
///
/// The isolated host gate does not link CoreMedia or CoreAudioTypes. Layout-
/// compatible lookalikes below exist only when those modules are absent; they
/// are not Darwin ABI and must not be used as a substitute once the real
/// modules are on the search path.

#if !canImport(Darwin)
public typealias OSStatus = Int32
#endif

#if !canImport(CoreMedia)
public typealias FourCharCode = UInt32
public typealias CMMediaType = UInt32
public typealias CMItemCount = Int

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

    public static let invalid = CMTimeRange()
    public static let zero = CMTimeRange(start: .zero, duration: .zero)
}
#endif

#if !canImport(CoreAudioTypes)
public struct AudioBuffer: BitwiseCopyable {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?

    public init(
        mNumberChannels: UInt32 = 0,
        mDataByteSize: UInt32 = 0,
        mData: UnsafeMutableRawPointer? = nil
    ) {
        self.mNumberChannels = mNumberChannels
        self.mDataByteSize = mDataByteSize
        self.mData = mData
    }
}

public struct AudioBufferList: BitwiseCopyable {
    public var mNumberBuffers: UInt32
    public var mBuffers: AudioBuffer

    public init(mNumberBuffers: UInt32 = 0, mBuffers: AudioBuffer = AudioBuffer()) {
        self.mNumberBuffers = mNumberBuffers
        self.mBuffers = mBuffers
    }
}

public struct AudioStreamBasicDescription: Sendable, BitwiseCopyable {
    public var mSampleRate: Float64
    public var mFormatID: UInt32
    public var mFormatFlags: UInt32
    public var mBytesPerPacket: UInt32
    public var mFramesPerPacket: UInt32
    public var mBytesPerFrame: UInt32
    public var mChannelsPerFrame: UInt32
    public var mBitsPerChannel: UInt32
    public var mReserved: UInt32

    public init(
        mSampleRate: Float64 = 0,
        mFormatID: UInt32 = 0,
        mFormatFlags: UInt32 = 0,
        mBytesPerPacket: UInt32 = 0,
        mFramesPerPacket: UInt32 = 0,
        mBytesPerFrame: UInt32 = 0,
        mChannelsPerFrame: UInt32 = 0,
        mBitsPerChannel: UInt32 = 0,
        mReserved: UInt32 = 0
    ) {
        self.mSampleRate = mSampleRate
        self.mFormatID = mFormatID
        self.mFormatFlags = mFormatFlags
        self.mBytesPerPacket = mBytesPerPacket
        self.mFramesPerPacket = mFramesPerPacket
        self.mBytesPerFrame = mBytesPerFrame
        self.mChannelsPerFrame = mChannelsPerFrame
        self.mBitsPerChannel = mBitsPerChannel
        self.mReserved = mReserved
    }
}
#endif

/// Documented by pinned `dotnet/macios` `MTAudioProcessingTapError.InvalidArgument`.
public var kMTAudioProcessingTapInvalidArgumentErr: OSStatus { -12780 }

public var kMTAudioProcessingTapCallbacksVersion_0: Int32 { 0 }

public typealias MTAudioProcessingTapCreationFlags = UInt32
public typealias MTAudioProcessingTapFlags = UInt32

public var kMTAudioProcessingTapCreationFlag_PreEffects: MTAudioProcessingTapCreationFlags {
    1 << 0
}

public var kMTAudioProcessingTapCreationFlag_PostEffects: MTAudioProcessingTapCreationFlags {
    1 << 1
}

public var kMTAudioProcessingTapFlag_StartOfStream: MTAudioProcessingTapFlags {
    1 << 8
}

public var kMTAudioProcessingTapFlag_EndOfStream: MTAudioProcessingTapFlags {
    1 << 9
}

public typealias MTAudioProcessingTapInitCallback = (
    MTAudioProcessingTap,
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<UnsafeMutableRawPointer?>
) -> Void

public typealias MTAudioProcessingTapFinalizeCallback = (MTAudioProcessingTap) -> Void

public typealias MTAudioProcessingTapPrepareCallback = (
    MTAudioProcessingTap,
    CMItemCount,
    UnsafePointer<AudioStreamBasicDescription>
) -> Void

public typealias MTAudioProcessingTapUnprepareCallback = (MTAudioProcessingTap) -> Void

public typealias MTAudioProcessingTapProcessCallback = (
    MTAudioProcessingTap,
    CMItemCount,
    MTAudioProcessingTapFlags,
    UnsafeMutablePointer<AudioBufferList>,
    UnsafeMutablePointer<CMItemCount>,
    UnsafeMutablePointer<MTAudioProcessingTapFlags>
) -> Void

public struct MTAudioProcessingTapCallbacks {
    public var version: Int32
    public var clientInfo: UnsafeMutableRawPointer?
    public var `init`: MTAudioProcessingTapInitCallback?
    public var finalize: MTAudioProcessingTapFinalizeCallback?
    public var prepare: MTAudioProcessingTapPrepareCallback?
    public var unprepare: MTAudioProcessingTapUnprepareCallback?
    public var process: MTAudioProcessingTapProcessCallback

    public init(
        version: Int32,
        clientInfo: UnsafeMutableRawPointer?,
        init: MTAudioProcessingTapInitCallback?,
        finalize: MTAudioProcessingTapFinalizeCallback?,
        prepare: MTAudioProcessingTapPrepareCallback?,
        unprepare: MTAudioProcessingTapUnprepareCallback?,
        process: MTAudioProcessingTapProcessCallback
    ) {
        self.version = version
        self.clientInfo = clientInfo
        self.`init` = `init`
        self.finalize = finalize
        self.prepare = prepare
        self.unprepare = unprepare
        self.process = process
    }
}

func mtFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    precondition(bytes.count == 4, "FourCC literal must be four UTF-8 bytes")
    return (UInt32(bytes[0]) << 24)
        | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8)
        | UInt32(bytes[3])
}

func mtCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

func mtString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}
