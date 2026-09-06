import Foundation

public let kAppleSoftwareAudioCodecManufacturer: UInt32 = atFourCC("appl")
public let kAppleHardwareAudioCodecManufacturer: UInt32 = atFourCC("aphw")

public let kAudioCodecPropertyInputBufferSize: AudioCodecPropertyID = atFourCC("tbuf")
public let kAudioCodecPropertyPacketFrameSize: AudioCodecPropertyID = atFourCC("pakf")
public let kAudioCodecPropertyHasVariablePacketByteSizes: AudioCodecPropertyID = atFourCC("vpk?")
public let kAudioCodecPropertyEmploysDependentPackets: AudioCodecPropertyID = atFourCC("dpk?")
public let kAudioCodecPropertyMaximumPacketByteSize: AudioCodecPropertyID = atFourCC("pakb")
public let kAudioCodecPropertyPacketSizeLimitForVBR: AudioCodecPropertyID = atFourCC("pakl")
public let kAudioCodecPropertyCurrentInputFormat: AudioCodecPropertyID = atFourCC("ifmt")
public let kAudioCodecPropertyCurrentOutputFormat: AudioCodecPropertyID = atFourCC("ofmt")
public let kAudioCodecPropertyMagicCookie: AudioCodecPropertyID = atFourCC("kuki")
public let kAudioCodecPropertyUsedInputBufferSize: AudioCodecPropertyID = atFourCC("ubuf")
public let kAudioCodecPropertyIsInitialized: AudioCodecPropertyID = atFourCC("init")
public let kAudioCodecPropertyCurrentTargetBitRate: AudioCodecPropertyID = atFourCC("brat")
public let kAudioCodecPropertyCurrentInputSampleRate: AudioCodecPropertyID = atFourCC("cisr")
public let kAudioCodecPropertyCurrentOutputSampleRate: AudioCodecPropertyID = atFourCC("cosr")
public let kAudioCodecPropertyQualitySetting: AudioCodecPropertyID = atFourCC("srcq")
public let kAudioCodecPropertyApplicableBitRateRange: AudioCodecPropertyID = atFourCC("brta")
public let kAudioCodecPropertyRecommendedBitRateRange: AudioCodecPropertyID = atFourCC("brtr")
public let kAudioCodecPropertyApplicableInputSampleRates: AudioCodecPropertyID = atFourCC("isra")
public let kAudioCodecPropertyApplicableOutputSampleRates: AudioCodecPropertyID = atFourCC("osra")
public let kAudioCodecPropertyPaddedZeros: AudioCodecPropertyID = atFourCC("pad0")
public let kAudioCodecPropertyPrimeMethod: AudioCodecPropertyID = atFourCC("prmm")
public let kAudioCodecPropertyPrimeInfo: AudioCodecPropertyID = atFourCC("prim")
public let kAudioCodecPropertyCurrentInputChannelLayout: AudioCodecPropertyID = atFourCC("icl ")
public let kAudioCodecPropertyCurrentOutputChannelLayout: AudioCodecPropertyID = atFourCC("ocl ")
public let kAudioCodecPropertySettings: AudioCodecPropertyID = atFourCC("acs ")
public let kAudioCodecPropertyFormatList: AudioCodecPropertyID = atFourCC("acfl")
public let kAudioCodecPropertyBitRateControlMode: AudioCodecPropertyID = atFourCC("acbf")
public let kAudioCodecPropertySoundQualityForVBR: AudioCodecPropertyID = atFourCC("vbrq")
public let kAudioCodecPropertyBitRateForVBR: AudioCodecPropertyID = atFourCC("vbrb")
public let kAudioCodecPropertyDelayMode: AudioCodecPropertyID = atFourCC("dmod")
public let kAudioCodecPropertyAdjustLocalQuality: AudioCodecPropertyID = atFourCC("^qal")
public let kAudioCodecPropertyDynamicRangeControlMode: AudioCodecPropertyID = atFourCC("mdrc")
public let kAudioCodecPropertyAdjustCompressionProfile: AudioCodecPropertyID = atFourCC("^pro")
public let kAudioCodecPropertyProgramTargetLevelConstant: AudioCodecPropertyID = atFourCC("ptlc")
public let kAudioCodecPropertyAdjustTargetLevelConstant: AudioCodecPropertyID = atFourCC("^tlc")
public let kAudioCodecPropertyProgramTargetLevel: AudioCodecPropertyID = atFourCC("pptl")
public let kAudioCodecPropertyAdjustTargetLevel: AudioCodecPropertyID = atFourCC("^ptl")
public let kAudioCodecPropertyDynamicRangeControlConfiguration: AudioCodecPropertyID = atFourCC("cdrc")
public let kAudioCodecPropertyContentSource: AudioCodecPropertyID = atFourCC("csrc")
public let kAudioCodecPropertyASPFrequency: AudioCodecPropertyID = atFourCC("aspf")

public let kAudioCodecQuality_Max: UInt32 = 0x7F
public let kAudioCodecQuality_High: UInt32 = 0x60
public let kAudioCodecQuality_Medium: UInt32 = 0x40
public let kAudioCodecQuality_Low: UInt32 = 0x20
public let kAudioCodecQuality_Min: UInt32 = 0

public let kAudioCodecPropertyNameCFString: AudioCodecPropertyID = atFourCC("lnam")
public let kAudioCodecPropertyManufacturerCFString: AudioCodecPropertyID = atFourCC("lmak")
public let kAudioCodecPropertyFormatCFString: AudioCodecPropertyID = atFourCC("lfor")

public let kAudioCodecNoError: Int32 = 0
public let kAudioCodecUnspecifiedError: Int32 = atSignedFourCC("what")
public let kAudioCodecUnknownPropertyError: Int32 = atSignedFourCC("who?")
public let kAudioCodecBadPropertySizeError: Int32 = atSignedFourCC("!siz")
public let kAudioCodecIllegalOperationError: Int32 = atSignedFourCC("nope")
public let kAudioCodecUnsupportedFormatError: Int32 = atSignedFourCC("fmt?")
public let kAudioCodecStateError: Int32 = atSignedFourCC("!stt")
public let kAudioCodecNotEnoughBufferSpaceError: Int32 = atSignedFourCC("!buf")
public let kAudioCodecBadDataError: Int32 = atSignedFourCC("!dat")

public let kAudioCodecBitRateControlMode_Constant: UInt32 = 0
public let kAudioCodecBitRateControlMode_LongTermAverage: UInt32 = 1
public let kAudioCodecBitRateControlMode_VariableConstrained: UInt32 = 2
public let kAudioCodecBitRateControlMode_Variable: UInt32 = 3

public let kAudioCodecBitRateFormat_CBR: UInt32 = 0
public let kAudioCodecBitRateFormat_ABR: UInt32 = 1
public let kAudioCodecBitRateFormat_VBR: UInt32 = 2

public let kAudioCodecDelayMode_Compatibility: UInt32 = 0
public let kAudioCodecDelayMode_Minimum: UInt32 = 1
public let kAudioCodecDelayMode_Optimal: UInt32 = 2

public let kAudioCodecPrimeMethod_Pre: UInt32 = 0
public let kAudioCodecPrimeMethod_Normal: UInt32 = 1
public let kAudioCodecPrimeMethod_None: UInt32 = 2

public let kAudioCodecOutputPrecedenceNone: UInt32 = 0
public let kAudioCodecOutputPrecedenceBitRate: UInt32 = 1
public let kAudioCodecOutputPrecedenceSampleRate: UInt32 = 2

public let kAudioCodecProduceOutputPacketFailure: UInt32 = 1
public let kAudioCodecProduceOutputPacketSuccess: UInt32 = 2
public let kAudioCodecProduceOutputPacketSuccessHasMore: UInt32 = 3
public let kAudioCodecProduceOutputPacketNeedsMoreInputData: UInt32 = 4
public let kAudioCodecProduceOutputPacketAtEOF: UInt32 = 5
public let kAudioCodecProduceOutputPacketSuccessConcealed: UInt32 = 6

public let kAudioCodecGetPropertyInfoSelect: UInt32 = 0x0001
public let kAudioCodecGetPropertySelect: UInt32 = 0x0002
public let kAudioCodecSetPropertySelect: UInt32 = 0x0003
public let kAudioCodecInitializeSelect: UInt32 = 0x0004
public let kAudioCodecUninitializeSelect: UInt32 = 0x0005
public let kAudioCodecAppendInputDataSelect: UInt32 = 0x0006
public let kAudioCodecProduceOutputDataSelect: UInt32 = 0x0007
public let kAudioCodecResetSelect: UInt32 = 0x0008
public let kAudioCodecAppendInputBufferListSelect: UInt32 = 0x0009
public let kAudioCodecProduceOutputBufferListSelect: UInt32 = 0x000A

public let kAudioCodecDynamicRangeControlConfiguration_None: UInt32 = 0
public let kAudioCodecDynamicRangeControlConfiguration_Music: UInt32 = 1
public let kAudioCodecDynamicRangeControlConfiguration_Speech: UInt32 = 2
public let kAudioCodecDynamicRangeControlConfiguration_Movie: UInt32 = 3
public let kAudioCodecDynamicRangeControlConfiguration_Capture: UInt32 = 4

public let kAudioCodecContentSource_Unspecified: Int32 = -1
public let kAudioCodecContentSource_Reserved: Int32 = 0
public let kAudioCodecContentSource_AppleCapture_Traditional: Int32 = 1
public let kAudioCodecContentSource_AppleCapture_Spatial: Int32 = 2
public let kAudioCodecContentSource_AppleCapture_Spatial_Enhanced: Int32 = 3
public let kAudioCodecContentSource_AppleMusic_Traditional: Int32 = 4
public let kAudioCodecContentSource_AppleMusic_Spatial: Int32 = 5
public let kAudioCodecContentSource_AppleAV_Traditional_Offline: Int32 = 6
public let kAudioCodecContentSource_AppleAV_Spatial_Offline: Int32 = 7
public let kAudioCodecContentSource_AppleAV_Traditional_Live: Int32 = 8
public let kAudioCodecContentSource_AppleAV_Spatial_Live: Int32 = 9
public let kAudioCodecContentSource_ApplePassthrough: Int32 = 10
public let kAudioCodecContentSource_Capture_Traditional: Int32 = 33
public let kAudioCodecContentSource_Capture_Spatial: Int32 = 34
public let kAudioCodecContentSource_Capture_Spatial_Enhanced: Int32 = 35
public let kAudioCodecContentSource_Music_Traditional: Int32 = 36
public let kAudioCodecContentSource_Music_Spatial: Int32 = 37
public let kAudioCodecContentSource_AV_Traditional_Offline: Int32 = 38
public let kAudioCodecContentSource_AV_Spatial_Offline: Int32 = 39
public let kAudioCodecContentSource_AV_Traditional_Live: Int32 = 40
public let kAudioCodecContentSource_AV_Spatial_Live: Int32 = 41
public let kAudioCodecContentSource_Passthrough: Int32 = 42

@frozen
public struct AudioCodecPrimeInfo: Equatable, Hashable, Sendable {
    public var leadingFrames: UInt32
    public var trailingFrames: UInt32

    public init() {
        leadingFrames = 0
        trailingFrames = 0
    }

    public init(leadingFrames: UInt32, trailingFrames: UInt32) {
        self.leadingFrames = leadingFrames
        self.trailingFrames = trailingFrames
    }
}

@frozen
public struct AudioCodecMagicCookieInfo: Equatable, Hashable, Sendable {
    public var mMagicCookieSize: UInt32
    public var mMagicCookie: UnsafeRawPointer?

    public init() {
        mMagicCookieSize = 0
        mMagicCookie = nil
    }

    public init(mMagicCookieSize: UInt32, mMagicCookie: UnsafeRawPointer?) {
        self.mMagicCookieSize = mMagicCookieSize
        self.mMagicCookie = mMagicCookie
    }
}

@_cdecl("AudioCodecInitialize")
public func AudioCodecInitialize(
    _ inCodec: AudioCodec?,
    _ inInputFormat: UnsafeRawPointer?,
    _ inOutputFormat: UnsafeRawPointer?,
    _ inMagicCookie: UnsafeRawPointer?,
    _ inMagicCookieByteSize: UInt32
) -> Int32 {
    _ = inCodec
    _ = inInputFormat
    _ = inOutputFormat
    _ = inMagicCookie
    _ = inMagicCookieByteSize
    return kAudioCodecUnsupportedFormatError
}

@_cdecl("AudioCodecUninitialize")
public func AudioCodecUninitialize(_ inCodec: AudioCodec?) -> Int32 {
    _ = inCodec
    return kAudioCodecStateError
}

@_cdecl("AudioCodecReset")
public func AudioCodecReset(_ inCodec: AudioCodec?) -> Int32 {
    _ = inCodec
    return kAudioCodecStateError
}

public func AudioCodecGetPropertyInfo(
    _ inCodec: AudioCodec?,
    _ inPropertyID: AudioCodecPropertyID,
    _ outSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    _ = inCodec
    _ = inPropertyID
    outSize?.pointee = 0
    outWritable?.pointee = 0
    return kAudioCodecUnknownPropertyError
}

public func AudioCodecGetProperty(
    _ inCodec: AudioCodec?,
    _ inPropertyID: AudioCodecPropertyID,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inCodec
    _ = inPropertyID
    _ = ioPropertyDataSize
    _ = outPropertyData
    return kAudioCodecUnknownPropertyError
}

public func AudioCodecSetProperty(
    _ inCodec: AudioCodec?,
    _ inPropertyID: AudioCodecPropertyID,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    _ = inCodec
    _ = inPropertyID
    _ = inPropertyDataSize
    _ = inPropertyData
    return kAudioCodecIllegalOperationError
}

public func AudioCodecAppendInputData(
    _ inCodec: AudioCodec?,
    _ inInputData: UnsafeRawPointer?,
    _ ioInputDataByteSize: UnsafeMutablePointer<UInt32>?,
    _ ioNumberPackets: UnsafeMutablePointer<UInt32>?,
    _ inPacketDescription: UnsafeRawPointer?
) -> Int32 {
    _ = inCodec
    _ = inInputData
    _ = ioInputDataByteSize
    _ = ioNumberPackets
    _ = inPacketDescription
    return kAudioCodecStateError
}

public func AudioCodecProduceOutputPackets(
    _ inCodec: AudioCodec?,
    _ outOutputData: UnsafeMutableRawPointer?,
    _ ioOutputDataByteSize: UnsafeMutablePointer<UInt32>?,
    _ ioNumberPackets: UnsafeMutablePointer<UInt32>?,
    _ outPacketDescription: UnsafeMutableRawPointer?,
    _ outStatus: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inCodec
    _ = outOutputData
    ioOutputDataByteSize?.pointee = 0
    ioNumberPackets?.pointee = 0
    _ = outPacketDescription
    outStatus?.pointee = kAudioCodecProduceOutputPacketFailure
    return kAudioCodecStateError
}

public func AudioCodecAppendInputBufferList(
    _ inCodec: AudioCodec?,
    _ inBufferList: UnsafeRawPointer?,
    _ ioNumberPackets: UnsafeMutablePointer<UInt32>?,
    _ inPacketDescription: UnsafeRawPointer?,
    _ outBytesConsumed: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inCodec
    _ = inBufferList
    _ = ioNumberPackets
    _ = inPacketDescription
    outBytesConsumed?.pointee = 0
    return kAudioCodecStateError
}

public func AudioCodecProduceOutputBufferList(
    _ inCodec: AudioCodec?,
    _ ioBufferList: UnsafeMutableRawPointer?,
    _ ioNumberPackets: UnsafeMutablePointer<UInt32>?,
    _ outPacketDescription: UnsafeMutableRawPointer?,
    _ outStatus: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inCodec
    _ = ioBufferList
    ioNumberPackets?.pointee = 0
    _ = outPacketDescription
    outStatus?.pointee = kAudioCodecProduceOutputPacketFailure
    return kAudioCodecStateError
}

@frozen
public struct MusicDeviceStdNoteParams: Equatable, Hashable, Sendable {
    public var argCount: UInt32
    public var mPitch: Float32
    public var mVelocity: Float32

    public init() {
        argCount = 2
        mPitch = 60
        mVelocity = 0
    }

    public init(argCount: UInt32, mPitch: Float32, mVelocity: Float32) {
        self.argCount = argCount
        self.mPitch = mPitch
        self.mVelocity = mVelocity
    }
}

@frozen
public struct MusicDeviceNoteParams: Equatable, Hashable, Sendable {
    public var argCount: UInt32
    public var mPitch: Float32
    public var mVelocity: Float32
    public var mControls: Float32

    public init() {
        argCount = 2
        mPitch = 60
        mVelocity = 0
        mControls = 0
    }

    public init(argCount: UInt32, mPitch: Float32, mVelocity: Float32, mControls: Float32) {
        self.argCount = argCount
        self.mPitch = mPitch
        self.mVelocity = mVelocity
        self.mControls = mControls
    }
}

@_cdecl("MusicDeviceMIDIEvent")
public func MusicDeviceMIDIEvent(
    _ inUnit: MusicDeviceComponent?,
    _ inStatus: UInt32,
    _ inData1: UInt32,
    _ inData2: UInt32,
    _ inOffsetSampleFrame: UInt32
) -> Int32 {
    _ = inStatus
    _ = inData1
    _ = inData2
    _ = inOffsetSampleFrame
    guard ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_CannotDoInCurrentContext
}

@_cdecl("MusicDeviceSysEx")
public func MusicDeviceSysEx(
    _ inUnit: MusicDeviceComponent?,
    _ inData: UnsafePointer<UInt8>?,
    _ inLength: UInt32
) -> Int32 {
    _ = inData
    _ = inLength
    guard ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_CannotDoInCurrentContext
}

public func MusicDeviceStartNote(
    _ inUnit: MusicDeviceComponent?,
    _ inInstrument: MusicDeviceInstrumentID,
    _ inGroupID: MusicDeviceGroupID,
    _ outNoteInstanceID: UnsafeMutablePointer<NoteInstanceID>?,
    _ inOffsetSampleFrame: UInt32,
    _ inParams: UnsafePointer<MusicDeviceNoteParams>?
) -> Int32 {
    _ = inInstrument
    _ = inGroupID
    _ = inOffsetSampleFrame
    _ = inParams
    outNoteInstanceID?.pointee = 0
    guard ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_CannotDoInCurrentContext
}

@_cdecl("MusicDeviceStopNote")
public func MusicDeviceStopNote(
    _ inUnit: MusicDeviceComponent?,
    _ inGroupID: MusicDeviceGroupID,
    _ inNoteInstanceID: NoteInstanceID,
    _ inOffsetSampleFrame: UInt32
) -> Int32 {
    _ = inGroupID
    _ = inNoteInstanceID
    _ = inOffsetSampleFrame
    guard ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_CannotDoInCurrentContext
}
