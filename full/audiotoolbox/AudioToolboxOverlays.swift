import Foundation

/// Packed overlays whose field order follows Apple AudioUnit / AudioFile headers
/// as corroborated by the pinned macios bindings. Flexible-array tails keep a
/// single leading `data` byte so tests can assert prefix layout without inventing
/// Apple's trailing alignment.

@frozen
public struct AUChannelInfo: Equatable, Hashable, Sendable {
    public var inChannels: Int16
    public var outChannels: Int16

    public init() {
        inChannels = 0
        outChannels = 0
    }

    public init(inChannels: Int16, outChannels: Int16) {
        self.inChannels = inChannels
        self.outChannels = outChannels
    }
}

@frozen
public struct AUDependentParameter: Equatable, Hashable, Sendable {
    public var mScope: AudioUnitScope
    public var mParameterID: AudioUnitParameterID

    public init() {
        mScope = 0
        mParameterID = 0
    }

    public init(mScope: AudioUnitScope, mParameterID: AudioUnitParameterID) {
        self.mScope = mScope
        self.mParameterID = mParameterID
    }
}

@frozen
public struct AudioUnitParameter: Equatable, Hashable, @unchecked Sendable {
    public var mAudioUnit: AudioUnit?
    public var mParameterID: AudioUnitParameterID
    public var mScope: AudioUnitScope
    public var mElement: AudioUnitElement

    public init() {
        mAudioUnit = nil
        mParameterID = 0
        mScope = 0
        mElement = 0
    }

    public init(
        mAudioUnit: AudioUnit?,
        mParameterID: AudioUnitParameterID,
        mScope: AudioUnitScope,
        mElement: AudioUnitElement
    ) {
        self.mAudioUnit = mAudioUnit
        self.mParameterID = mParameterID
        self.mScope = mScope
        self.mElement = mElement
    }
}

@frozen
public struct AUPreset: Equatable, Hashable, @unchecked Sendable {
    public var presetNumber: Int32
    public var presetName: OpaquePointer?

    public init() {
        presetNumber = 0
        presetName = nil
    }

    public init(presetNumber: Int32, presetName: OpaquePointer?) {
        self.presetNumber = presetNumber
        self.presetName = presetName
    }
}

@frozen
public struct ParameterEvent: Equatable, Hashable, Sendable {
    public var parameterID: AudioUnitParameterID
    public var scope: AudioUnitScope
    public var element: AudioUnitElement
    public var value: AudioUnitParameterValue

    public init() {
        parameterID = 0
        scope = 0
        element = 0
        value = 0
    }

    public init(
        parameterID: AudioUnitParameterID,
        scope: AudioUnitScope,
        element: AudioUnitElement,
        value: AudioUnitParameterValue
    ) {
        self.parameterID = parameterID
        self.scope = scope
        self.element = element
        self.value = value
    }
}

@frozen
public struct MIDIRawData: Equatable, Hashable, Sendable {
    public var length: UInt32
    public var data: UInt8

    public init() {
        length = 0
        data = 0
    }

    public init(length: UInt32, data: UInt8) {
        self.length = length
        self.data = data
    }
}

@frozen
public struct MIDIMetaEvent: Equatable, Hashable, Sendable {
    public var metaEventType: UInt8
    public var unused1: UInt8
    public var unused2: UInt8
    public var unused3: UInt8
    public var dataLength: UInt32
    public var data: UInt8

    public init() {
        metaEventType = 0
        unused1 = 0
        unused2 = 0
        unused3 = 0
        dataLength = 0
        data = 0
    }

    public init(
        metaEventType: UInt8,
        unused1: UInt8,
        unused2: UInt8,
        unused3: UInt8,
        dataLength: UInt32,
        data: UInt8
    ) {
        self.metaEventType = metaEventType
        self.unused1 = unused1
        self.unused2 = unused2
        self.unused3 = unused3
        self.dataLength = dataLength
        self.data = data
    }
}

@frozen
public struct AUParameterAutomationEvent: Equatable, Hashable, Sendable {
    public var hostTime: UInt64
    public var address: AUParameterAddress
    public var value: AUValue
    public var eventType: AUParameterAutomationEventType
    public var reserved: UInt32

    public init() {
        hostTime = 0
        address = 0
        value = 0
        eventType = .value
        reserved = 0
    }

    public init(
        hostTime: UInt64,
        address: AUParameterAddress,
        value: AUValue,
        eventType: AUParameterAutomationEventType,
        reserved: UInt32 = 0
    ) {
        self.hostTime = hostTime
        self.address = address
        self.value = value
        self.eventType = eventType
        self.reserved = reserved
    }
}

@frozen
public struct AURecordedParameterEvent: Equatable, Hashable, Sendable {
    public var hostTime: UInt64
    public var address: AUParameterAddress
    public var value: AUValue

    public init() {
        hostTime = 0
        address = 0
        value = 0
    }

    public init(hostTime: UInt64, address: AUParameterAddress, value: AUValue) {
        self.hostTime = hostTime
        self.address = address
        self.value = value
    }
}

@frozen
public struct AudioFile_SMPTE_Time: Equatable, Hashable, Sendable {
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

    public init(
        mHours: Int8,
        mMinutes: UInt8,
        mSeconds: UInt8,
        mFrames: UInt8,
        mSubFrameSampleOffset: UInt32
    ) {
        self.mHours = mHours
        self.mMinutes = mMinutes
        self.mSeconds = mSeconds
        self.mFrames = mFrames
        self.mSubFrameSampleOffset = mSubFrameSampleOffset
    }
}

@frozen
public struct AudioFileMarker: Equatable, Hashable, @unchecked Sendable {
    public var mFramePosition: Float64
    public var mName: OpaquePointer?
    public var mMarkerID: Int32
    public var mSMPTETime: AudioFile_SMPTE_Time
    public var mType: UInt32
    public var mReserved: UInt16
    public var mChannel: UInt16

    public init() {
        mFramePosition = 0
        mName = nil
        mMarkerID = 0
        mSMPTETime = AudioFile_SMPTE_Time()
        mType = 0
        mReserved = 0
        mChannel = 0
    }

    public init(
        mFramePosition: Float64,
        mName: OpaquePointer?,
        mMarkerID: Int32,
        mSMPTETime: AudioFile_SMPTE_Time,
        mType: UInt32,
        mReserved: UInt16,
        mChannel: UInt16
    ) {
        self.mFramePosition = mFramePosition
        self.mName = mName
        self.mMarkerID = mMarkerID
        self.mSMPTETime = mSMPTETime
        self.mType = mType
        self.mReserved = mReserved
        self.mChannel = mChannel
    }
}

@frozen
public struct AudioFileMarkerList: Equatable, Hashable, Sendable {
    public var mSMPTE_TimeType: UInt32
    public var mNumberMarkers: UInt32
    public var mMarkers: AudioFileMarker

    public init() {
        mSMPTE_TimeType = 0
        mNumberMarkers = 0
        mMarkers = AudioFileMarker()
    }

    public init(mSMPTE_TimeType: UInt32, mNumberMarkers: UInt32, mMarkers: AudioFileMarker) {
        self.mSMPTE_TimeType = mSMPTE_TimeType
        self.mNumberMarkers = mNumberMarkers
        self.mMarkers = mMarkers
    }
}

@frozen
public struct AUSamplerInstrumentData: Equatable, Hashable, @unchecked Sendable {
    public var fileURL: OpaquePointer?
    public var instrumentType: UInt8
    public var bankMSB: UInt8
    public var bankLSB: UInt8
    public var presetID: UInt8

    public init() {
        fileURL = nil
        instrumentType = kInstrumentType_Audiofile
        bankMSB = kAUSampler_DefaultMelodicBankMSB
        bankLSB = kAUSampler_DefaultBankLSB
        presetID = 0
    }

    public init(
        fileURL: OpaquePointer?,
        instrumentType: UInt8,
        bankMSB: UInt8,
        bankLSB: UInt8,
        presetID: UInt8
    ) {
        self.fileURL = fileURL
        self.instrumentType = instrumentType
        self.bankMSB = bankMSB
        self.bankLSB = bankLSB
        self.presetID = presetID
    }
}

@frozen
public struct AUSamplerBankPresetData: Equatable, Hashable, @unchecked Sendable {
    public var bankURL: OpaquePointer?
    public var bankMSB: UInt8
    public var bankLSB: UInt8
    public var presetID: UInt8
    public var reserved: UInt8

    public init() {
        bankURL = nil
        bankMSB = kAUSampler_DefaultMelodicBankMSB
        bankLSB = kAUSampler_DefaultBankLSB
        presetID = 0
        reserved = 0
    }

    public init(
        bankURL: OpaquePointer?,
        bankMSB: UInt8,
        bankLSB: UInt8,
        presetID: UInt8,
        reserved: UInt8
    ) {
        self.bankURL = bankURL
        self.bankMSB = bankMSB
        self.bankLSB = bankLSB
        self.presetID = presetID
        self.reserved = reserved
    }
}

public let kAUPresetVersionKey = "version"
public let kAUPresetTypeKey = "type"
public let kAUPresetSubtypeKey = "subtype"
public let kAUPresetManufacturerKey = "manufacturer"
public let kAUPresetDataKey = "data"
public let kAUPresetNameKey = "name"
public let kAUPresetRenderQualityKey = "render-quality"
public let kAUPresetCPULoadKey = "cpu-load"
public let kAUPresetElementNameKey = "element-name"
public let kAUPresetExternalFileRefs = "file-references"
public let kAUPresetPartKey = "part"

public let kAudioUnitConfigurationInfo_HasCustomView = "HasCustomView"
public let kAudioUnitConfigurationInfo_ChannelConfigurations = "ChannelConfigurations"
public let kAudioUnitConfigurationInfo_InitialInputs = "InitialInputs"
public let kAudioUnitConfigurationInfo_InitialOutputs = "InitialOutputs"
public let kAudioUnitConfigurationInfo_IconURL = "IconURL"
public let kAudioUnitConfigurationInfo_BusCountWritable = "BusCountWritable"
public let kAudioUnitConfigurationInfo_SupportedChannelLayoutTags = "SupportedChannelLayoutTags"
public let kAudioUnitConfigurationInfo_MIDIProtocol = "MIDIProtocol"
public let kAudioUnitConfigurationInfo_MigrateFromPlugin = "MigrateFromPlugin"

public let kAudioSettings_TopLevelKey = "name"
public let kAudioSettings_Version = "version"
public let kAudioSettings_Parameters = "parameters"
public let kAudioSettings_SettingKey = "key"
public let kAudioSettings_SettingName = "name"
public let kAudioSettings_ValueType = "value type"
public let kAudioSettings_AvailableValues = "available values"
public let kAudioSettings_LimitedValues = "limited values"
public let kAudioSettings_CurrentValue = "current value"
public let kAudioSettings_Hint = "hint"
public let kAudioSettings_Unit = "unit"
public let kAudioSettings_Summary = "summary"

public let kAudioSession_AudioRouteChangeKey_OldRoute = "OldRoute"
public let kAudioSession_AudioRouteChangeKey_Reason = "Reason"

public func NumAudioFileMarkersToNumBytes(_ inNumMarkers: Int) -> Int {
    MemoryLayout<AudioFileMarkerList>.size
        - MemoryLayout<AudioFileMarker>.size
        + inNumMarkers * MemoryLayout<AudioFileMarker>.size
}

public func NumBytesToNumAudioFileMarkers(_ inNumBytes: Int) -> Int {
    let header = MemoryLayout<AudioFileMarkerList>.size - MemoryLayout<AudioFileMarker>.size
    if inNumBytes < header { return 0 }
    return (inNumBytes - header) / MemoryLayout<AudioFileMarker>.size
}
