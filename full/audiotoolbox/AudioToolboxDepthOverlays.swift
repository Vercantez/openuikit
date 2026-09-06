#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

/// Depth-pass C overlays. CoreAudioTypes-owned names (`AudioTimeStamp`,
/// `AudioBufferList`, `AudioChannelLayout`, `AudioStreamBasicDescription`)
/// stay as 64-byte / pointer slots rather than local redeclarations.
/// `MIDIEventList` stays unhosted (CoreMIDI).

public typealias ATTimeStampOverlay = (
    UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64
)

internal func atEmptyTimeStampOverlay() -> ATTimeStampOverlay {
    (0, 0, 0, 0, 0, 0, 0, 0)
}

internal func atEmptyParameterName() -> (
    CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
    CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
    CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
    CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
    CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
    CChar, CChar
) {
    (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0
    )
}

@frozen
public struct AURenderEventHeader {
    public var next: UnsafeMutableRawPointer?
    public var eventSampleTime: AUEventSampleTime
    public var eventType: AURenderEventType
    public var reserved: UInt8

    public init() {
        next = nil
        eventSampleTime = 0
        eventType = .parameter
        reserved = 0
    }

    public init(
        next: UnsafeMutableRawPointer?,
        eventSampleTime: AUEventSampleTime,
        eventType: AURenderEventType,
        reserved: UInt8
    ) {
        self.next = next
        self.eventSampleTime = eventSampleTime
        self.eventType = eventType
        self.reserved = reserved
    }
}

@frozen
public struct AUMIDIEvent {
    public var next: UnsafeMutableRawPointer?
    public var eventSampleTime: AUEventSampleTime
    public var eventType: AURenderEventType
    public var reserved: UInt8
    public var length: UInt16
    public var cable: UInt8
    public var data: (UInt8, UInt8, UInt8)

    public init() {
        next = nil
        eventSampleTime = 0
        eventType = .MIDI
        reserved = 0
        length = 0
        cable = 0
        data = (0, 0, 0)
    }

    public init(
        next: UnsafeMutableRawPointer?,
        eventSampleTime: AUEventSampleTime,
        eventType: AURenderEventType,
        reserved: UInt8,
        length: UInt16,
        cable: UInt8,
        data: (UInt8, UInt8, UInt8)
    ) {
        self.next = next
        self.eventSampleTime = eventSampleTime
        self.eventType = eventType
        self.reserved = reserved
        self.length = length
        self.cable = cable
        self.data = data
    }
}

@frozen
public struct AUParameterEvent {
    public var next: UnsafeMutableRawPointer?
    public var eventSampleTime: AUEventSampleTime
    public var eventType: AURenderEventType
    public var reserved: (UInt8, UInt8, UInt8)
    public var rampDurationSampleFrames: AUAudioFrameCount
    public var parameterAddress: AUParameterAddress
    public var value: AUValue

    public init() {
        next = nil
        eventSampleTime = 0
        eventType = .parameter
        reserved = (0, 0, 0)
        rampDurationSampleFrames = 0
        parameterAddress = 0
        value = 0
    }

    public init(
        next: UnsafeMutableRawPointer?,
        eventSampleTime: AUEventSampleTime,
        eventType: AURenderEventType,
        reserved: (UInt8, UInt8, UInt8),
        rampDurationSampleFrames: AUAudioFrameCount,
        parameterAddress: AUParameterAddress,
        value: AUValue
    ) {
        self.next = next
        self.eventSampleTime = eventSampleTime
        self.eventType = eventType
        self.reserved = reserved
        self.rampDurationSampleFrames = rampDurationSampleFrames
        self.parameterAddress = parameterAddress
        self.value = value
    }
}

@frozen
public struct AURenderEvent {
    public var head: AURenderEventHeader
    public var parameter: AUParameterEvent
    public var MIDI: AUMIDIEvent

    public init() {
        head = AURenderEventHeader()
        parameter = AUParameterEvent()
        MIDI = AUMIDIEvent()
    }

    public init(parameter: AUParameterEvent) {
        self.init()
        self.parameter = parameter
        self.head.eventType = parameter.eventType
        self.head.eventSampleTime = parameter.eventSampleTime
    }

    public init(MIDI: AUMIDIEvent) {
        self.init()
        self.MIDI = MIDI
        self.head.eventType = MIDI.eventType
        self.head.eventSampleTime = MIDI.eventSampleTime
    }
}

@frozen
public struct AudioUnitParameterInfo {
    public var name: (
        CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
        CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
        CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
        CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
        CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
        CChar, CChar
    )
    public var unitName: Unmanaged<CFString>?
    public var clumpID: UInt32
    public var cfNameString: Unmanaged<CFString>?
    public var unit: AudioUnitParameterUnit
    public var minValue: AudioUnitParameterValue
    public var maxValue: AudioUnitParameterValue
    public var defaultValue: AudioUnitParameterValue
    public var flags: AudioUnitParameterOptions

    public init() {
        name = atEmptyParameterName()
        unitName = nil
        clumpID = 0
        cfNameString = nil
        unit = .generic
        minValue = 0
        maxValue = 1
        defaultValue = 0
        flags = []
    }

    public init(
        name: (
            CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
            CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
            CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
            CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
            CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
            CChar, CChar
        ),
        unitName: Unmanaged<CFString>?,
        clumpID: UInt32,
        cfNameString: Unmanaged<CFString>?,
        unit: AudioUnitParameterUnit,
        minValue: AudioUnitParameterValue,
        maxValue: AudioUnitParameterValue,
        defaultValue: AudioUnitParameterValue,
        flags: AudioUnitParameterOptions
    ) {
        self.name = name
        self.unitName = unitName
        self.clumpID = clumpID
        self.cfNameString = cfNameString
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
        self.defaultValue = defaultValue
        self.flags = flags
    }
}

@frozen
public struct ScheduledAudioSlice {
    public var mTimeStamp: ATTimeStampOverlay
    public var mCompletionProc: ScheduledAudioSliceCompletionProc?
    public var mCompletionProcUserData: UnsafeMutableRawPointer?
    public var mFlags: AUScheduledAudioSliceFlags
    public var mReserved: UInt32
    public var mReserved2: UnsafeMutableRawPointer?
    public var mNumberFrames: UInt32
    public var mBufferList: UnsafeMutableRawPointer?

    public init() {
        mTimeStamp = atEmptyTimeStampOverlay()
        mCompletionProc = nil
        mCompletionProcUserData = nil
        mFlags = []
        mReserved = 0
        mReserved2 = nil
        mNumberFrames = 0
        mBufferList = nil
    }

    public init(
        mTimeStamp: ATTimeStampOverlay,
        mCompletionProc: ScheduledAudioSliceCompletionProc?,
        mCompletionProcUserData: UnsafeMutableRawPointer?,
        mFlags: AUScheduledAudioSliceFlags,
        mReserved: UInt32,
        mReserved2: UnsafeMutableRawPointer?,
        mNumberFrames: UInt32,
        mBufferList: UnsafeMutableRawPointer?
    ) {
        self.mTimeStamp = mTimeStamp
        self.mCompletionProc = mCompletionProc
        self.mCompletionProcUserData = mCompletionProcUserData
        self.mFlags = mFlags
        self.mReserved = mReserved
        self.mReserved2 = mReserved2
        self.mNumberFrames = mNumberFrames
        self.mBufferList = mBufferList
    }
}

@frozen
public struct ScheduledAudioFileRegion {
    public var mTimeStamp: ATTimeStampOverlay
    public var mCompletionProc: ScheduledAudioFileRegionCompletionProc?
    public var mCompletionProcUserData: UnsafeMutableRawPointer?
    public var mAudioFile: OpaquePointer?
    public var mLoopCount: UInt32
    public var mStartFrame: Int64
    public var mFramesToPlay: UInt32

    public init() {
        mTimeStamp = atEmptyTimeStampOverlay()
        mCompletionProc = nil
        mCompletionProcUserData = nil
        mAudioFile = nil
        mLoopCount = 0
        mStartFrame = 0
        mFramesToPlay = 0
    }

    public init(
        mTimeStamp: ATTimeStampOverlay,
        mCompletionProc: ScheduledAudioFileRegionCompletionProc?,
        mCompletionProcUserData: UnsafeMutableRawPointer?,
        mAudioFile: OpaquePointer?,
        mLoopCount: UInt32,
        mStartFrame: Int64,
        mFramesToPlay: UInt32
    ) {
        self.mTimeStamp = mTimeStamp
        self.mCompletionProc = mCompletionProc
        self.mCompletionProcUserData = mCompletionProcUserData
        self.mAudioFile = mAudioFile
        self.mLoopCount = mLoopCount
        self.mStartFrame = mStartFrame
        self.mFramesToPlay = mFramesToPlay
    }
}

@frozen
public struct AudioFileRegion {
    public var mRegionID: UInt32
    public var mName: Unmanaged<CFString>?
    public var mFlags: AudioFileRegionFlags
    public var mNumberMarkers: UInt32
    public var mMarkers: AudioFileMarker

    public init() {
        mRegionID = 0
        mName = nil
        mFlags = []
        mNumberMarkers = 0
        mMarkers = AudioFileMarker()
    }

    public init(
        mRegionID: UInt32,
        mName: Unmanaged<CFString>?,
        mFlags: AudioFileRegionFlags,
        mNumberMarkers: UInt32,
        mMarkers: AudioFileMarker
    ) {
        self.mRegionID = mRegionID
        self.mName = mName
        self.mFlags = mFlags
        self.mNumberMarkers = mNumberMarkers
        self.mMarkers = mMarkers
    }
}

@frozen
public struct AudioFileRegionList {
    public var mSMPTE_TimeType: UInt32
    public var mNumberRegions: UInt32
    public var mRegions: AudioFileRegion

    public init() {
        mSMPTE_TimeType = 0
        mNumberRegions = 0
        mRegions = AudioFileRegion()
    }

    public init(mSMPTE_TimeType: UInt32, mNumberRegions: UInt32, mRegions: AudioFileRegion) {
        self.mSMPTE_TimeType = mSMPTE_TimeType
        self.mNumberRegions = mNumberRegions
        self.mRegions = mRegions
    }
}

public func NextAudioFileRegion(
    _ inAFRegionPtr: UnsafePointer<AudioFileRegion>
) -> UnsafeMutablePointer<AudioFileRegion> {
    let header = MemoryLayout<AudioFileRegion>.size - MemoryLayout<AudioFileMarker>.size
    let offset = header + Int(inAFRegionPtr.pointee.mNumberMarkers) * MemoryLayout<AudioFileMarker>.stride
    return UnsafeMutableRawPointer(mutating: inAFRegionPtr)
        .advanced(by: offset)
        .assumingMemoryBound(to: AudioFileRegion.self)
}

@frozen
public struct AudioPanningInfo {
    public var mPanningMode: AudioPanningMode
    public var mCoordinateFlags: UInt32
    public var mCoordinates: (Float32, Float32, Float32)
    public var mGainScale: Float32
    public var mOutputChannelMap: UnsafeRawPointer?

    public init() {
        mPanningMode = .panningMode_SoundField
        mCoordinateFlags = 0
        mCoordinates = (0, 0, 0)
        mGainScale = 1
        mOutputChannelMap = nil
    }

    public init(
        mPanningMode: AudioPanningMode,
        mCoordinateFlags: UInt32,
        mCoordinates: (Float32, Float32, Float32),
        mGainScale: Float32,
        mOutputChannelMap: UnsafeRawPointer?
    ) {
        self.mPanningMode = mPanningMode
        self.mCoordinateFlags = mCoordinateFlags
        self.mCoordinates = mCoordinates
        self.mGainScale = mGainScale
        self.mOutputChannelMap = mOutputChannelMap
    }
}

@frozen
public struct AudioUnitParameterEventValues: Equatable, Hashable, Sendable {
    public var value: AudioUnitParameterValue
    public var startBufferOffset: UInt32
    public var durationInFrames: UInt32
    public var startValue: AudioUnitParameterValue
    public var endValue: AudioUnitParameterValue

    public init() {
        value = 0
        startBufferOffset = 0
        durationInFrames = 0
        startValue = 0
        endValue = 0
    }

    public init(
        value: AudioUnitParameterValue,
        startBufferOffset: UInt32 = 0,
        durationInFrames: UInt32 = 0,
        startValue: AudioUnitParameterValue = 0,
        endValue: AudioUnitParameterValue = 0
    ) {
        self.value = value
        self.startBufferOffset = startBufferOffset
        self.durationInFrames = durationInFrames
        self.startValue = startValue
        self.endValue = endValue
    }
}

@frozen
public struct AudioUnitParameterEvent: Equatable, Hashable, Sendable {
    public var scope: AudioUnitScope
    public var element: AudioUnitElement
    public var parameter: AudioUnitParameterID
    public var eventType: AUParameterEventType
    public var eventValues: AudioUnitParameterEventValues

    public init() {
        scope = 0
        element = 0
        parameter = 0
        eventType = .parameterEvent_Immediate
        eventValues = AudioUnitParameterEventValues()
    }

    public init(
        scope: AudioUnitScope,
        element: AudioUnitElement,
        parameter: AudioUnitParameterID,
        eventType: AUParameterEventType,
        eventValues: AudioUnitParameterEventValues
    ) {
        self.scope = scope
        self.element = element
        self.parameter = parameter
        self.eventType = eventType
        self.eventValues = eventValues
    }
}

public func AudioUnitScheduleParameters(
    _ inUnit: AudioUnit?,
    _ inParameterEvent: UnsafePointer<AudioUnitParameterEvent>?,
    _ inNumParamEvents: UInt32
) -> Int32 {
    guard ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    guard let inParameterEvent else {
        return inNumParamEvents == 0 ? 0 : kAudioUnitErr_InvalidParameter
    }
    var index = 0
    while index < Int(inNumParamEvents) {
        let event = inParameterEvent.advanced(by: index).pointee
        let value: AudioUnitParameterValue
        if event.eventType == .parameterEvent_Ramped {
            value = event.eventValues.endValue
        } else {
            value = event.eventValues.value
        }
        let status = AudioUnitSetParameter(
            inUnit,
            event.parameter,
            event.scope,
            event.element,
            value,
            event.eventValues.startBufferOffset
        )
        if status != 0 {
            return status
        }
        index += 1
    }
    return 0
}

@frozen
public struct HostCallbackInfo {
    public var hostUserData: UnsafeMutableRawPointer?
    public var beatAndTempoProc: HostCallback_GetBeatAndTempo?
    public var musicalTimeLocationProc: HostCallback_GetMusicalTimeLocation?
    public var transportStateProc: HostCallback_GetTransportState?
    public var transportStateProc2: HostCallback_GetTransportState2?

    public init() {
        hostUserData = nil
        beatAndTempoProc = nil
        musicalTimeLocationProc = nil
        transportStateProc = nil
        transportStateProc2 = nil
    }

    public init(
        hostUserData: UnsafeMutableRawPointer?,
        beatAndTempoProc: HostCallback_GetBeatAndTempo?,
        musicalTimeLocationProc: HostCallback_GetMusicalTimeLocation?,
        transportStateProc: HostCallback_GetTransportState?,
        transportStateProc2: HostCallback_GetTransportState2?
    ) {
        self.hostUserData = hostUserData
        self.beatAndTempoProc = beatAndTempoProc
        self.musicalTimeLocationProc = musicalTimeLocationProc
        self.transportStateProc = transportStateProc
        self.transportStateProc2 = transportStateProc2
    }
}

@frozen
public struct AudioBytePacketTranslation: Equatable, Hashable, Sendable {
    public var mByte: Int64
    public var mPacket: Int64
    public var mByteOffsetInPacket: UInt32
    public var mFlags: AudioBytePacketTranslationFlags

    public init() {
        mByte = 0
        mPacket = 0
        mByteOffsetInPacket = 0
        mFlags = []
    }

    public init(
        mByte: Int64,
        mPacket: Int64,
        mByteOffsetInPacket: UInt32,
        mFlags: AudioBytePacketTranslationFlags
    ) {
        self.mByte = mByte
        self.mPacket = mPacket
        self.mByteOffsetInPacket = mByteOffsetInPacket
        self.mFlags = mFlags
    }
}

@frozen
public struct AudioFramePacketTranslation: Equatable, Hashable, Sendable {
    public var mFrame: Int64
    public var mPacket: Int64
    public var mFrameOffsetInPacket: UInt32

    public init() {
        mFrame = 0
        mPacket = 0
        mFrameOffsetInPacket = 0
    }

    public init(mFrame: Int64, mPacket: Int64, mFrameOffsetInPacket: UInt32) {
        self.mFrame = mFrame
        self.mPacket = mPacket
        self.mFrameOffsetInPacket = mFrameOffsetInPacket
    }
}

@frozen
public struct AudioIndependentPacketTranslation: Equatable, Hashable, Sendable {
    public var mPacket: Int64
    public var mIndependentlyDecodablePacket: Int64

    public init() {
        mPacket = 0
        mIndependentlyDecodablePacket = 0
    }

    public init(mPacket: Int64, mIndependentlyDecodablePacket: Int64) {
        self.mPacket = mPacket
        self.mIndependentlyDecodablePacket = mIndependentlyDecodablePacket
    }
}

@frozen
public struct AudioPacketRangeByteCountTranslation: Equatable, Hashable, Sendable {
    public var mPacket: Int64
    public var mPacketCount: Int64
    public var mByteCountUpperBound: Int64

    public init() {
        mPacket = 0
        mPacketCount = 0
        mByteCountUpperBound = 0
    }

    public init(mPacket: Int64, mPacketCount: Int64, mByteCountUpperBound: Int64) {
        self.mPacket = mPacket
        self.mPacketCount = mPacketCount
        self.mByteCountUpperBound = mByteCountUpperBound
    }
}

@frozen
public struct AudioPacketRollDistanceTranslation: Equatable, Hashable, Sendable {
    public var mPacket: Int64
    public var mRollDistance: Int64

    public init() {
        mPacket = 0
        mRollDistance = 0
    }

    public init(mPacket: Int64, mRollDistance: Int64) {
        self.mPacket = mPacket
        self.mRollDistance = mRollDistance
    }
}

@frozen
public struct AudioPacketDependencyInfoTranslation: Equatable, Hashable, Sendable {
    public var mPacket: Int64
    public var mIsIndependentlyDecodable: UInt32
    public var mNumberPrerollPackets: UInt32

    public init() {
        mPacket = 0
        mIsIndependentlyDecodable = 0
        mNumberPrerollPackets = 0
    }

    public init(mPacket: Int64, mIsIndependentlyDecodable: UInt32, mNumberPrerollPackets: UInt32) {
        self.mPacket = mPacket
        self.mIsIndependentlyDecodable = mIsIndependentlyDecodable
        self.mNumberPrerollPackets = mNumberPrerollPackets
    }
}

@frozen
public struct AudioQueueLevelMeterState: Equatable, Hashable, Sendable {
    public var mAveragePower: Float32
    public var mPeakPower: Float32

    public init() {
        mAveragePower = 0
        mPeakPower = 0
    }

    public init(mAveragePower: Float32, mPeakPower: Float32) {
        self.mAveragePower = mAveragePower
        self.mPeakPower = mPeakPower
    }
}

@frozen
public struct AudioQueueChannelAssignment {
    public var mDeviceUID: Unmanaged<CFString>?
    public var mChannelNumber: UInt32

    public init() {
        mDeviceUID = nil
        mChannelNumber = 0
    }

    public init(mDeviceUID: Unmanaged<CFString>?, mChannelNumber: UInt32) {
        self.mDeviceUID = mDeviceUID
        self.mChannelNumber = mChannelNumber
    }
}

@frozen
public struct AudioQueueParameterEvent: Equatable, Hashable, Sendable {
    public var mID: AudioQueueParameterID
    public var mValue: AudioQueueParameterValue

    public init() {
        mID = 0
        mValue = 0
    }

    public init(mID: AudioQueueParameterID, mValue: AudioQueueParameterValue) {
        self.mID = mID
        self.mValue = mValue
    }
}

@frozen
public struct AudioUnitFrequencyResponseBin: Equatable, Hashable, Sendable {
    public var mFrequency: Float64
    public var mMagnitude: Float64

    public init() {
        mFrequency = 0
        mMagnitude = 0
    }

    public init(mFrequency: Float64, mMagnitude: Float64) {
        self.mFrequency = mFrequency
        self.mMagnitude = mMagnitude
    }
}

@frozen
public struct AudioUnitParameterHistoryInfo: Equatable, Hashable, Sendable {
    public var updatesPerSecond: Float32
    public var historyDurationInSeconds: Float32

    public init() {
        updatesPerSecond = 0
        historyDurationInSeconds = 0
    }

    public init(updatesPerSecond: Float32, historyDurationInSeconds: Float32) {
        self.updatesPerSecond = updatesPerSecond
        self.historyDurationInSeconds = historyDurationInSeconds
    }
}

@frozen
public struct AudioUnitParameterNameInfo {
    public var inID: AudioUnitParameterID
    public var inDesiredLength: Int32
    public var outName: Unmanaged<CFString>?

    public init() {
        inID = 0
        inDesiredLength = 0
        outName = nil
    }

    public init(inID: AudioUnitParameterID, inDesiredLength: Int32, outName: Unmanaged<CFString>?) {
        self.inID = inID
        self.inDesiredLength = inDesiredLength
        self.outName = outName
    }
}

@frozen
public struct AudioUnitParameterStringFromValue {
    public var inParamID: AudioUnitParameterID
    public var inValue: UnsafePointer<AudioUnitParameterValue>?
    public var outString: Unmanaged<CFString>?

    public init() {
        inParamID = 0
        inValue = nil
        outString = nil
    }

    public init(
        inParamID: AudioUnitParameterID,
        inValue: UnsafePointer<AudioUnitParameterValue>?,
        outString: Unmanaged<CFString>?
    ) {
        self.inParamID = inParamID
        self.inValue = inValue
        self.outString = outString
    }
}

@frozen
public struct AudioUnitParameterValueFromString {
    public var inParamID: AudioUnitParameterID
    public var inString: Unmanaged<CFString>?
    public var outValue: AudioUnitParameterValue

    public init() {
        inParamID = 0
        inString = nil
        outValue = 0
    }

    public init(
        inParamID: AudioUnitParameterID,
        inString: Unmanaged<CFString>?,
        outValue: AudioUnitParameterValue
    ) {
        self.inParamID = inParamID
        self.inString = inString
        self.outValue = outValue
    }
}

@frozen
public struct AudioUnitNodeConnection: Equatable, Hashable, Sendable {
    public var sourceNode: AUNode
    public var sourceOutputNumber: UInt32
    public var destNode: AUNode
    public var destInputNumber: UInt32

    public init() {
        sourceNode = 0
        sourceOutputNumber = 0
        destNode = 0
        destInputNumber = 0
    }

    public init(
        sourceNode: AUNode,
        sourceOutputNumber: UInt32,
        destNode: AUNode,
        destInputNumber: UInt32
    ) {
        self.sourceNode = sourceNode
        self.sourceOutputNumber = sourceOutputNumber
        self.destNode = destNode
        self.destInputNumber = destInputNumber
    }
}

@frozen
public struct AUInputSamplesInOutputCallbackStruct {
    public var inputToOutputCallback: AUInputSamplesInOutputCallback?
    public var userData: UnsafeMutableRawPointer?

    public init() {
        inputToOutputCallback = nil
        userData = nil
    }

    public init(
        inputToOutputCallback: AUInputSamplesInOutputCallback?,
        userData: UnsafeMutableRawPointer?
    ) {
        self.inputToOutputCallback = inputToOutputCallback
        self.userData = userData
    }
}

@frozen
public struct AUVoiceIOOtherAudioDuckingConfiguration: Equatable, Hashable, Sendable {
    public var mEnableAdvancedDucking: UInt8
    public var mDuckingLevel: AUVoiceIOOtherAudioDuckingLevel

    public init() {
        mEnableAdvancedDucking = 0
        mDuckingLevel = .default
    }

    public init(
        mEnableAdvancedDucking: UInt8,
        mDuckingLevel: AUVoiceIOOtherAudioDuckingLevel
    ) {
        self.mEnableAdvancedDucking = mEnableAdvancedDucking
        self.mDuckingLevel = mDuckingLevel
    }
}

@frozen
public struct AudioOutputUnitStartAtTimeParams {
    public var mTimestamp: ATTimeStampOverlay
    public var mFlags: UInt32

    public init() {
        mTimestamp = atEmptyTimeStampOverlay()
        mFlags = 0
    }

    public init(mTimestamp: ATTimeStampOverlay, mFlags: UInt32) {
        self.mTimestamp = mTimestamp
        self.mFlags = mFlags
    }
}

@frozen
public struct AudioOutputUnitMIDICallbacks {
    public var userData: UnsafeMutableRawPointer?
    public var MIDIEventProc: ((UnsafeMutableRawPointer?, UInt32, UInt32, UInt32, UInt32) -> Void)?
    public var MIDISysExProc: ((UnsafeMutableRawPointer?, UnsafePointer<UInt8>, UInt32) -> Void)?

    public init() {
        userData = nil
        MIDIEventProc = nil
        MIDISysExProc = nil
    }

    public init(
        userData: UnsafeMutableRawPointer?,
        MIDIEventProc: @escaping (UnsafeMutableRawPointer?, UInt32, UInt32, UInt32, UInt32) -> Void,
        MIDISysExProc: @escaping (UnsafeMutableRawPointer?, UnsafePointer<UInt8>, UInt32) -> Void
    ) {
        self.userData = userData
        self.MIDIEventProc = MIDIEventProc
        self.MIDISysExProc = MIDISysExProc
    }
}

@frozen
public struct ExtendedNoteOnEvent: Equatable, Hashable, Sendable {
    public var instrumentID: MusicDeviceInstrumentID
    public var groupID: MusicDeviceGroupID
    public var duration: Float32
    public var extendedParams: MusicDeviceNoteParams

    public init() {
        instrumentID = 0
        groupID = 0
        duration = 0
        extendedParams = MusicDeviceNoteParams()
    }

    public init(
        instrumentID: MusicDeviceInstrumentID,
        groupID: MusicDeviceGroupID,
        duration: Float32,
        extendedParams: MusicDeviceNoteParams
    ) {
        self.instrumentID = instrumentID
        self.groupID = groupID
        self.duration = duration
        self.extendedParams = extendedParams
    }
}
