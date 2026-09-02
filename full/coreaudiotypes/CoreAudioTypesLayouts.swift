/// Foundational `@frozen` value layouts reconstructed from sealed graph field
/// types and declaration order. Each struct embeds one trailing flexible
/// element when the graph records a single `mBuffers` /
/// `mChannelDescriptions` field.

@frozen
public struct AudioBuffer: BitwiseCopyable {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?

    public init() {
        mNumberChannels = 0
        mDataByteSize = 0
        mData = nil
    }

    public init(
        mNumberChannels: UInt32,
        mDataByteSize: UInt32,
        mData: UnsafeMutableRawPointer?
    ) {
        self.mNumberChannels = mNumberChannels
        self.mDataByteSize = mDataByteSize
        self.mData = mData
    }
}

@frozen
public struct AudioBufferList: BitwiseCopyable {
    public var mNumberBuffers: UInt32
    public var mBuffers: AudioBuffer

    public init() {
        mNumberBuffers = 0
        mBuffers = AudioBuffer()
    }

    public init(mNumberBuffers: UInt32, mBuffers: AudioBuffer) {
        self.mNumberBuffers = mNumberBuffers
        self.mBuffers = mBuffers
    }
}

@frozen
public struct AudioChannelDescription: Sendable, BitwiseCopyable {
    public var mChannelLabel: AudioChannelLabel
    public var mChannelFlags: AudioChannelFlags
    public var mCoordinates: (Float32, Float32, Float32)

    public init() {
        mChannelLabel = 0
        mChannelFlags = AudioChannelFlags(rawValue: 0)
        mCoordinates = (0, 0, 0)
    }

    public init(
        mChannelLabel: AudioChannelLabel,
        mChannelFlags: AudioChannelFlags,
        mCoordinates: (Float32, Float32, Float32)
    ) {
        self.mChannelLabel = mChannelLabel
        self.mChannelFlags = mChannelFlags
        self.mCoordinates = mCoordinates
    }
}

@frozen
public struct AudioChannelLayout: Sendable, BitwiseCopyable {
    public var mChannelLayoutTag: AudioChannelLayoutTag
    public var mChannelBitmap: AudioChannelBitmap
    public var mNumberChannelDescriptions: UInt32
    public var mChannelDescriptions: AudioChannelDescription

    public init() {
        mChannelLayoutTag = 0
        mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        mNumberChannelDescriptions = 0
        mChannelDescriptions = AudioChannelDescription()
    }

    public init(
        mChannelLayoutTag: AudioChannelLayoutTag,
        mChannelBitmap: AudioChannelBitmap,
        mNumberChannelDescriptions: UInt32,
        mChannelDescriptions: AudioChannelDescription
    ) {
        self.mChannelLayoutTag = mChannelLayoutTag
        self.mChannelBitmap = mChannelBitmap
        self.mNumberChannelDescriptions = mNumberChannelDescriptions
        self.mChannelDescriptions = mChannelDescriptions
    }
}

@frozen
public struct AudioClassDescription: Sendable, BitwiseCopyable {
    public var mType: OSType
    public var mSubType: OSType
    public var mManufacturer: OSType

    public init() {
        mType = 0
        mSubType = 0
        mManufacturer = 0
    }

    public init(mType: OSType, mSubType: OSType, mManufacturer: OSType) {
        self.mType = mType
        self.mSubType = mSubType
        self.mManufacturer = mManufacturer
    }
}

@frozen
public struct AudioFormatListItem: Sendable, BitwiseCopyable {
    public var mASBD: AudioStreamBasicDescription
    public var mChannelLayoutTag: AudioChannelLayoutTag

    public init() {
        mASBD = AudioStreamBasicDescription()
        mChannelLayoutTag = 0
    }

    public init(
        mASBD: AudioStreamBasicDescription,
        mChannelLayoutTag: AudioChannelLayoutTag
    ) {
        self.mASBD = mASBD
        self.mChannelLayoutTag = mChannelLayoutTag
    }
}

@frozen
public struct AudioStreamBasicDescription: Sendable, BitwiseCopyable {
    public var mSampleRate: Float64
    public var mFormatID: AudioFormatID
    public var mFormatFlags: AudioFormatFlags
    public var mBytesPerPacket: UInt32
    public var mFramesPerPacket: UInt32
    public var mBytesPerFrame: UInt32
    public var mChannelsPerFrame: UInt32
    public var mBitsPerChannel: UInt32
    public var mReserved: UInt32

    public init() {
        mSampleRate = 0
        mFormatID = 0
        mFormatFlags = 0
        mBytesPerPacket = 0
        mFramesPerPacket = 0
        mBytesPerFrame = 0
        mChannelsPerFrame = 0
        mBitsPerChannel = 0
        mReserved = 0
    }

    public init(
        mSampleRate: Float64,
        mFormatID: AudioFormatID,
        mFormatFlags: AudioFormatFlags,
        mBytesPerPacket: UInt32,
        mFramesPerPacket: UInt32,
        mBytesPerFrame: UInt32,
        mChannelsPerFrame: UInt32,
        mBitsPerChannel: UInt32,
        mReserved: UInt32
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

@frozen
public struct AudioStreamPacketDependencyDescription: Sendable, BitwiseCopyable {
    public var mIsIndependentlyDecodable: UInt32
    public var mPreRollCount: UInt32
    public var mFlags: UInt32
    public var mReserved: UInt32

    public init() {
        mIsIndependentlyDecodable = 0
        mPreRollCount = 0
        mFlags = 0
        mReserved = 0
    }

    public init(
        mIsIndependentlyDecodable: UInt32,
        mPreRollCount: UInt32,
        mFlags: UInt32,
        mReserved: UInt32
    ) {
        self.mIsIndependentlyDecodable = mIsIndependentlyDecodable
        self.mPreRollCount = mPreRollCount
        self.mFlags = mFlags
        self.mReserved = mReserved
    }
}

@frozen
public struct AudioStreamPacketDescription: Sendable, BitwiseCopyable {
    public var mStartOffset: Int64
    public var mVariableFramesInPacket: UInt32
    public var mDataByteSize: UInt32

    public init() {
        mStartOffset = 0
        mVariableFramesInPacket = 0
        mDataByteSize = 0
    }

    public init(
        mStartOffset: Int64,
        mVariableFramesInPacket: UInt32,
        mDataByteSize: UInt32
    ) {
        self.mStartOffset = mStartOffset
        self.mVariableFramesInPacket = mVariableFramesInPacket
        self.mDataByteSize = mDataByteSize
    }
}

@frozen
public struct AudioTimeStamp: Sendable, BitwiseCopyable {
    public var mSampleTime: Float64
    public var mHostTime: UInt64
    public var mRateScalar: Float64
    public var mWordClockTime: UInt64
    public var mSMPTETime: SMPTETime
    public var mFlags: AudioTimeStampFlags
    public var mReserved: UInt32

    public init() {
        mSampleTime = 0
        mHostTime = 0
        mRateScalar = 0
        mWordClockTime = 0
        mSMPTETime = SMPTETime()
        mFlags = AudioTimeStampFlags(rawValue: 0)
        mReserved = 0
    }

    public init(
        mSampleTime: Float64,
        mHostTime: UInt64,
        mRateScalar: Float64,
        mWordClockTime: UInt64,
        mSMPTETime: SMPTETime,
        mFlags: AudioTimeStampFlags,
        mReserved: UInt32
    ) {
        self.mSampleTime = mSampleTime
        self.mHostTime = mHostTime
        self.mRateScalar = mRateScalar
        self.mWordClockTime = mWordClockTime
        self.mSMPTETime = mSMPTETime
        self.mFlags = mFlags
        self.mReserved = mReserved
    }
}

@frozen
public struct AudioValueRange: Sendable, BitwiseCopyable {
    public var mMinimum: Float64
    public var mMaximum: Float64

    public init() {
        mMinimum = 0
        mMaximum = 0
    }

    public init(mMinimum: Float64, mMaximum: Float64) {
        self.mMinimum = mMinimum
        self.mMaximum = mMaximum
    }
}

@frozen
public struct AudioValueTranslation: BitwiseCopyable {
    public var mInputData: UnsafeMutableRawPointer
    public var mInputDataSize: UInt32
    public var mOutputData: UnsafeMutableRawPointer
    public var mOutputDataSize: UInt32

    public init(
        mInputData: UnsafeMutableRawPointer,
        mInputDataSize: UInt32,
        mOutputData: UnsafeMutableRawPointer,
        mOutputDataSize: UInt32
    ) {
        self.mInputData = mInputData
        self.mInputDataSize = mInputDataSize
        self.mOutputData = mOutputData
        self.mOutputDataSize = mOutputDataSize
    }
}

@frozen
public struct SMPTETime: Sendable, BitwiseCopyable {
    public var mSubframes: Int16
    public var mSubframeDivisor: Int16
    public var mCounter: UInt32
    public var mType: SMPTETimeType
    public var mFlags: SMPTETimeFlags
    public var mHours: Int16
    public var mMinutes: Int16
    public var mSeconds: Int16
    public var mFrames: Int16

    public init() {
        mSubframes = 0
        mSubframeDivisor = 0
        mCounter = 0
        mType = .type24
        mFlags = SMPTETimeFlags(rawValue: 0)
        mHours = 0
        mMinutes = 0
        mSeconds = 0
        mFrames = 0
    }

    public init(
        mSubframes: Int16,
        mSubframeDivisor: Int16,
        mCounter: UInt32,
        mType: SMPTETimeType,
        mFlags: SMPTETimeFlags,
        mHours: Int16,
        mMinutes: Int16,
        mSeconds: Int16,
        mFrames: Int16
    ) {
        self.mSubframes = mSubframes
        self.mSubframeDivisor = mSubframeDivisor
        self.mCounter = mCounter
        self.mType = mType
        self.mFlags = mFlags
        self.mHours = mHours
        self.mMinutes = mMinutes
        self.mSeconds = mSeconds
        self.mFrames = mFrames
    }
}
