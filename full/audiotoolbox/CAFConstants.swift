import Foundation

public struct CAFFormatFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let linearPCMFormatFlagIsFloat = CAFFormatFlags(rawValue: 1 << 0)
    public static let linearPCMFormatFlagIsLittleEndian = CAFFormatFlags(rawValue: 1 << 1)
}

public struct CAFRegionFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let loopEnable = CAFRegionFlags(rawValue: 1)
    public static let playForward = CAFRegionFlags(rawValue: 2)
    public static let playBackward = CAFRegionFlags(rawValue: 4)
}

public let kCAF_FileType: UInt32 = atFourCC("caff")
public let kCAF_FileVersion_Initial: UInt16 = 1

public let kCAF_StreamDescriptionChunkID: UInt32 = atFourCC("desc")
public let kCAF_AudioDataChunkID: UInt32 = atFourCC("data")
public let kCAF_ChannelLayoutChunkID: UInt32 = atFourCC("chan")
public let kCAF_FillerChunkID: UInt32 = atFourCC("free")
public let kCAF_MarkerChunkID: UInt32 = atFourCC("mark")
public let kCAF_RegionChunkID: UInt32 = atFourCC("regn")
public let kCAF_InstrumentChunkID: UInt32 = atFourCC("inst")
public let kCAF_MagicCookieID: UInt32 = atFourCC("kuki")
public let kCAF_InfoStringsChunkID: UInt32 = atFourCC("info")
public let kCAF_EditCommentsChunkID: UInt32 = atFourCC("edct")
public let kCAF_PacketTableChunkID: UInt32 = atFourCC("pakt")
public let kCAF_StringsChunkID: UInt32 = atFourCC("strg")
public let kCAF_UUIDChunkID: UInt32 = atFourCC("uuid")
public let kCAF_PeakChunkID: UInt32 = atFourCC("peak")
public let kCAF_OverviewChunkID: UInt32 = atFourCC("ovvw")
public let kCAF_MIDIChunkID: UInt32 = atFourCC("midi")
public let kCAF_UMIDChunkID: UInt32 = atFourCC("umid")
public let kCAF_FormatListID: UInt32 = atFourCC("ldsc")
public let kCAF_iXMLChunkID: UInt32 = atFourCC("iXML")

public let kCAFMarkerType_Generic: UInt32 = 0
public let kCAFMarkerType_ProgramStart: UInt32 = atFourCC("pbeg")
public let kCAFMarkerType_ProgramEnd: UInt32 = atFourCC("pend")
public let kCAFMarkerType_TrackStart: UInt32 = atFourCC("tbeg")
public let kCAFMarkerType_TrackEnd: UInt32 = atFourCC("tend")
public let kCAFMarkerType_Index: UInt32 = atFourCC("indx")
public let kCAFMarkerType_RegionStart: UInt32 = atFourCC("rbeg")
public let kCAFMarkerType_RegionEnd: UInt32 = atFourCC("rend")
public let kCAFMarkerType_RegionSyncPoint: UInt32 = atFourCC("rsyc")
public let kCAFMarkerType_SelectionStart: UInt32 = atFourCC("sbeg")
public let kCAFMarkerType_SelectionEnd: UInt32 = atFourCC("send")
public let kCAFMarkerType_EditSourceBegin: UInt32 = atFourCC("cbeg")
public let kCAFMarkerType_EditSourceEnd: UInt32 = atFourCC("cend")
public let kCAFMarkerType_EditDestinationBegin: UInt32 = atFourCC("dbeg")
public let kCAFMarkerType_EditDestinationEnd: UInt32 = atFourCC("dend")
public let kCAFMarkerType_SustainLoopStart: UInt32 = atFourCC("slbg")
public let kCAFMarkerType_SustainLoopEnd: UInt32 = atFourCC("slen")
public let kCAFMarkerType_ReleaseLoopStart: UInt32 = atFourCC("rlbg")
public let kCAFMarkerType_ReleaseLoopEnd: UInt32 = atFourCC("rlen")
public let kCAFMarkerType_SavedPlayPosition: UInt32 = atFourCC("spps")
public let kCAFMarkerType_Tempo: UInt32 = atFourCC("tmpo")
public let kCAFMarkerType_TimeSignature: UInt32 = atFourCC("tsig")
public let kCAFMarkerType_KeySignature: UInt32 = atFourCC("ksig")

public let kCAF_SMPTE_TimeTypeNone: UInt32 = 0
public let kCAF_SMPTE_TimeType24: UInt32 = 1
public let kCAF_SMPTE_TimeType25: UInt32 = 2
public let kCAF_SMPTE_TimeType30Drop: UInt32 = 3
public let kCAF_SMPTE_TimeType30: UInt32 = 4
public let kCAF_SMPTE_TimeType2997: UInt32 = 5
public let kCAF_SMPTE_TimeType2997Drop: UInt32 = 6
public let kCAF_SMPTE_TimeType60: UInt32 = 7
public let kCAF_SMPTE_TimeType5994: UInt32 = 8
public let kCAF_SMPTE_TimeType60Drop: UInt32 = 9
public let kCAF_SMPTE_TimeType5994Drop: UInt32 = 10
public let kCAF_SMPTE_TimeType50: UInt32 = 11
public let kCAF_SMPTE_TimeType2398: UInt32 = 12

@frozen
public struct CAFFileHeader: Equatable, Hashable, Sendable {
    public var mFileType: UInt32
    public var mFileVersion: UInt16
    public var mFileFlags: UInt16

    public init() {
        mFileType = kCAF_FileType
        mFileVersion = kCAF_FileVersion_Initial
        mFileFlags = 0
    }

    public init(mFileType: UInt32, mFileVersion: UInt16, mFileFlags: UInt16) {
        self.mFileType = mFileType
        self.mFileVersion = mFileVersion
        self.mFileFlags = mFileFlags
    }
}

@frozen
public struct CAFChunkHeader: Equatable, Hashable, Sendable {
    public var mChunkType: UInt32
    public var mChunkSize: Int64

    public init() {
        mChunkType = 0
        mChunkSize = 0
    }

    public init(mChunkType: UInt32, mChunkSize: Int64) {
        self.mChunkType = mChunkType
        self.mChunkSize = mChunkSize
    }
}

@frozen
public struct CAFAudioDescription: Equatable, Hashable, Sendable {
    public var mSampleRate: Float64
    public var mFormatID: UInt32
    public var mFormatFlags: CAFFormatFlags
    public var mBytesPerPacket: UInt32
    public var mFramesPerPacket: UInt32
    public var mChannelsPerFrame: UInt32
    public var mBitsPerChannel: UInt32

    public init() {
        mSampleRate = 0
        mFormatID = 0
        mFormatFlags = []
        mBytesPerPacket = 0
        mFramesPerPacket = 0
        mChannelsPerFrame = 0
        mBitsPerChannel = 0
    }

    public init(
        mSampleRate: Float64,
        mFormatID: UInt32,
        mFormatFlags: CAFFormatFlags,
        mBytesPerPacket: UInt32,
        mFramesPerPacket: UInt32,
        mChannelsPerFrame: UInt32,
        mBitsPerChannel: UInt32
    ) {
        self.mSampleRate = mSampleRate
        self.mFormatID = mFormatID
        self.mFormatFlags = mFormatFlags
        self.mBytesPerPacket = mBytesPerPacket
        self.mFramesPerPacket = mFramesPerPacket
        self.mChannelsPerFrame = mChannelsPerFrame
        self.mBitsPerChannel = mBitsPerChannel
    }
}

@frozen
public struct CAFDataChunk: Equatable, Hashable, Sendable {
    public var mEditCount: UInt32
    public var mData: UInt8

    public init() {
        mEditCount = 0
        mData = 0
    }

    public init(mEditCount: UInt32, mData: UInt8) {
        self.mEditCount = mEditCount
        self.mData = mData
    }
}

@frozen
public struct CAFAudioFormatListItem: Equatable, Hashable, Sendable {
    public var mFormat: CAFAudioDescription
    public var mChannelLayoutTag: UInt32

    public init() {
        mFormat = CAFAudioDescription()
        mChannelLayoutTag = 0
    }

    public init(mFormat: CAFAudioDescription, mChannelLayoutTag: UInt32) {
        self.mFormat = mFormat
        self.mChannelLayoutTag = mChannelLayoutTag
    }
}

@frozen
public struct CAF_UUID_ChunkHeader: Sendable {
    public var mHeader: CAFChunkHeader
    public var mUUID: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    public init() {
        mHeader = CAFChunkHeader()
        mUUID = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(
        mHeader: CAFChunkHeader,
        mUUID: (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )
    ) {
        self.mHeader = mHeader
        self.mUUID = mUUID
    }
}

@frozen
public struct CAF_SMPTE_Time: Equatable, Hashable, Sendable {
    public var mHours: Int8
    public var mMinutes: UInt8
    public var mSeconds: UInt8
    public var mFrames: UInt8
    public var mSubFrameSampleOffset: UInt32

    public init() {
        mHours = 0
        mMinutes = 0
        mSeconds = 0
        mFrames = 0
        mSubFrameSampleOffset = 0
    }
}

@frozen
public struct CAFMarker: Equatable, Hashable, Sendable {
    public var mType: UInt32
    public var mFramePosition: Float64
    public var mMarkerID: UInt32
    public var mSMPTETime: CAF_SMPTE_Time
    public var mChannel: UInt32

    public init() {
        mType = kCAFMarkerType_Generic
        mFramePosition = 0
        mMarkerID = 0
        mSMPTETime = CAF_SMPTE_Time()
        mChannel = 0
    }
}

@frozen
public struct CAFMarkerChunk: Equatable, Hashable, Sendable {
    public var mSMPTE_TimeType: UInt32
    public var mNumberMarkers: UInt32
    public var mMarkers: CAFMarker

    public init() {
        mSMPTE_TimeType = kCAF_SMPTE_TimeTypeNone
        mNumberMarkers = 0
        mMarkers = CAFMarker()
    }
}

@frozen
public struct CAFRegion: Equatable, Hashable, Sendable {
    public var mRegionID: UInt32
    public var mFlags: CAFRegionFlags
    public var mNumberMarkers: UInt32
    public var mMarkers: CAFMarker

    public init() {
        mRegionID = 0
        mFlags = []
        mNumberMarkers = 0
        mMarkers = CAFMarker()
    }

    public init(mRegionID: UInt32, mFlags: CAFRegionFlags, mNumberMarkers: UInt32, mMarkers: CAFMarker) {
        self.mRegionID = mRegionID
        self.mFlags = mFlags
        self.mNumberMarkers = mNumberMarkers
        self.mMarkers = mMarkers
    }
}

@frozen
public struct CAFRegionChunk: Equatable, Hashable, Sendable {
    public var mSMPTE_TimeType: UInt32
    public var mNumberRegions: UInt32
    public var mRegions: CAFRegion

    public init() {
        mSMPTE_TimeType = kCAF_SMPTE_TimeTypeNone
        mNumberRegions = 0
        mRegions = CAFRegion()
    }
}

@frozen
public struct CAFInstrumentChunk: Equatable, Hashable, Sendable {
    public var mBaseNote: Float32
    public var mMIDILowNote: UInt8
    public var mMIDIHighNote: UInt8
    public var mMIDILowVelocity: UInt8
    public var mMIDIHighVelocity: UInt8
    public var mdBGain: Float32
    public var mStartRegionID: UInt32
    public var mSustainRegionID: UInt32
    public var mReleaseRegionID: UInt32
    public var mInstrumentID: UInt32

    public init() {
        mBaseNote = 60
        mMIDILowNote = 0
        mMIDIHighNote = 127
        mMIDILowVelocity = 0
        mMIDIHighVelocity = 127
        mdBGain = 0
        mStartRegionID = 0
        mSustainRegionID = 0
        mReleaseRegionID = 0
        mInstrumentID = 0
    }
}

@frozen
public struct CAFPacketTableHeader: Equatable, Hashable, Sendable {
    public var mNumberPackets: Int64
    public var mNumberValidFrames: Int64
    public var mPrimingFrames: Int32
    public var mRemainderFrames: Int32

    public init() {
        mNumberPackets = 0
        mNumberValidFrames = 0
        mPrimingFrames = 0
        mRemainderFrames = 0
    }
}

@frozen
public struct CAFPositionPeak: Equatable, Hashable, Sendable {
    public var mValue: Float32
    public var mFrameNumber: UInt64

    public init() {
        mValue = 0
        mFrameNumber = 0
    }
}

@frozen
public struct CAFPeakChunk: Equatable, Hashable, Sendable {
    public var mEditCount: UInt32
    public var mPeaks: CAFPositionPeak

    public init() {
        mEditCount = 0
        mPeaks = CAFPositionPeak()
    }
}

@frozen
public struct CAFOverviewSample: Equatable, Hashable, Sendable {
    public var mMinValue: Int16
    public var mMaxValue: Int16

    public init() {
        mMinValue = 0
        mMaxValue = 0
    }
}

@frozen
public struct CAFOverviewChunk: Equatable, Hashable, Sendable {
    public var mEditCount: UInt32
    public var mNumFramesPerOVWSample: UInt32
    public var mData: CAFOverviewSample

    public init() {
        mEditCount = 0
        mNumFramesPerOVWSample = 0
        mData = CAFOverviewSample()
    }
}

@frozen
public struct CAFStringID: Equatable, Hashable, Sendable {
    public var mStringID: UInt32
    public var mStringStartByteOffset: Int64

    public init() {
        mStringID = 0
        mStringStartByteOffset = 0
    }
}

@frozen
public struct CAFStrings: Equatable, Hashable, Sendable {
    public var mNumEntries: UInt32
    public var mStringsIDs: CAFStringID

    public init() {
        mNumEntries = 0
        mStringsIDs = CAFStringID()
    }
}

@frozen
public struct CAFInfoStrings: Equatable, Hashable, Sendable {
    public var mNumEntries: UInt32

    public init() {
        mNumEntries = 0
    }
}

@frozen
public struct CAFUMIDChunk: Sendable {
    public var mBytes: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    public init() {
        mBytes = (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        )
    }
}
