import Foundation

public let kAudioUnitScope_Global: AudioUnitScope = 0
public let kAudioUnitScope_Input: AudioUnitScope = 1
public let kAudioUnitScope_Output: AudioUnitScope = 2
public let kAudioUnitScope_Group: AudioUnitScope = 3
public let kAudioUnitScope_Part: AudioUnitScope = 4
public let kAudioUnitScope_Note: AudioUnitScope = 5
public let kAudioUnitScope_Layer: AudioUnitScope = 6
public let kAudioUnitScope_LayerItem: AudioUnitScope = 7

public let kAudioUnitProperty_ClassInfo: AudioUnitPropertyID = 0
public let kAudioUnitProperty_MakeConnection: AudioUnitPropertyID = 1
public let kAudioUnitProperty_SampleRate: AudioUnitPropertyID = 2
public let kAudioUnitProperty_ParameterList: AudioUnitPropertyID = 3
public let kAudioUnitProperty_ParameterInfo: AudioUnitPropertyID = 4
public let kAudioUnitProperty_CPULoad: AudioUnitPropertyID = 6
public let kAudioUnitProperty_StreamFormat: AudioUnitPropertyID = 8
public let kAudioUnitProperty_ElementCount: AudioUnitPropertyID = 11
public let kAudioUnitProperty_Latency: AudioUnitPropertyID = 12
public let kAudioUnitProperty_SupportedNumChannels: AudioUnitPropertyID = 13
public let kAudioUnitProperty_MaximumFramesPerSlice: AudioUnitPropertyID = 14
public let kAudioUnitProperty_ParameterValueStrings: AudioUnitPropertyID = 16
public let kAudioUnitProperty_AudioChannelLayout: AudioUnitPropertyID = 19
public let kAudioUnitProperty_TailTime: AudioUnitPropertyID = 20
public let kAudioUnitProperty_BypassEffect: AudioUnitPropertyID = 21
public let kAudioUnitProperty_LastRenderError: AudioUnitPropertyID = 22
public let kAudioUnitProperty_SetRenderCallback: AudioUnitPropertyID = 23
public let kAudioUnitProperty_FactoryPresets: AudioUnitPropertyID = 24
public let kAudioUnitProperty_ContextName: AudioUnitPropertyID = 25
public let kAudioUnitProperty_RenderQuality: AudioUnitPropertyID = 26
public let kAudioUnitProperty_HostCallbacks: AudioUnitPropertyID = 27
public let kAudioUnitProperty_InPlaceProcessing: AudioUnitPropertyID = 29
public let kAudioUnitProperty_ElementName: AudioUnitPropertyID = 30
public let kAudioUnitProperty_SupportedChannelLayoutTags: AudioUnitPropertyID = 32
public let kAudioUnitProperty_ParameterStringFromValue: AudioUnitPropertyID = 33
public let kAudioUnitProperty_ParameterIDName: AudioUnitPropertyID = 34
public let kAudioUnitProperty_ParameterClumpName: AudioUnitPropertyID = 35
public let kAudioUnitProperty_PresentPreset: AudioUnitPropertyID = 36
public let kAudioUnitProperty_OfflineRender: AudioUnitPropertyID = 37
public let kAudioUnitProperty_ParameterValueFromString: AudioUnitPropertyID = 38
public let kAudioUnitProperty_PresentationLatency: AudioUnitPropertyID = 40
public let kAudioUnitProperty_DependentParameters: AudioUnitPropertyID = 45
public let kAudioUnitProperty_InputSamplesInOutput: AudioUnitPropertyID = 49
public let kAudioUnitProperty_ClassInfoFromDocument: AudioUnitPropertyID = 50
public let kAudioUnitProperty_ShouldAllocateBuffer: AudioUnitPropertyID = 51
public let kAudioUnitProperty_FrequencyResponse: AudioUnitPropertyID = 52
public let kAudioUnitProperty_ParameterHistoryInfo: AudioUnitPropertyID = 53
public let kAudioUnitProperty_NickName: AudioUnitPropertyID = 54
public let kAudioUnitProperty_RequestViewController: AudioUnitPropertyID = 56
public let kAudioUnitProperty_ParametersForOverview: AudioUnitPropertyID = 57
public let kAudioUnitProperty_SupportsMPE: AudioUnitPropertyID = 58
public let kAudioUnitProperty_LastRenderSampleTime: AudioUnitPropertyID = 61
public let kAudioUnitProperty_LoadedOutOfProcess: AudioUnitPropertyID = 62
public let kAudioUnitProperty_MIDIOutputEventListCallback: AudioUnitPropertyID = 63
public let kAudioUnitProperty_AudioUnitMIDIProtocol: AudioUnitPropertyID = 64
public let kAudioUnitProperty_HostMIDIProtocol: AudioUnitPropertyID = 65
public let kAudioUnitProperty_MIDIOutputBufferSizeHint: AudioUnitPropertyID = 66
public let kAudioUnitProperty_MIDIOutputCallbackInfo: AudioUnitPropertyID = 47
public let kAudioUnitProperty_MIDIOutputCallback: AudioUnitPropertyID = 48
public let kAudioUnitProperty_RemoteControlEventListener: AudioUnitPropertyID = 100
public let kAudioUnitProperty_IsInterAppConnected: AudioUnitPropertyID = 101
public let kAudioUnitProperty_PeerURL: AudioUnitPropertyID = 102
public let kAudioUnitProperty_ReverbRoomType: AudioUnitPropertyID = 10
public let kAudioUnitProperty_UsesInternalReverb: AudioUnitPropertyID = 1004
public let kAudioUnitProperty_SpatializationAlgorithm: AudioUnitPropertyID = 3000
public let kAudioUnitProperty_SpatialMixerRenderingFlags: AudioUnitPropertyID = 3003
public let kAudioUnitProperty_3DMixerRenderingFlags: AudioUnitPropertyID = 3003
public let kAudioUnitProperty_DopplerShift: AudioUnitPropertyID = 3002
public let kAudioUnitProperty_3DMixerDistanceAtten: AudioUnitPropertyID = 3004
public let kAudioUnitProperty_SpatialMixerSourceMode: AudioUnitPropertyID = 3005
public let kAudioUnitProperty_MatrixLevels: AudioUnitPropertyID = 3006
public let kAudioUnitProperty_MeteringMode: AudioUnitPropertyID = 3007
public let kAudioUnitProperty_MatrixDimensions: AudioUnitPropertyID = 3009
public let kAudioUnitProperty_SpatialMixerDistanceParams: AudioUnitPropertyID = 3010
public let kAudioUnitProperty_3DMixerDistanceParams: AudioUnitPropertyID = 3010
public let kAudioUnitProperty_MeterClipping: AudioUnitPropertyID = 3011
public let kAudioUnitProperty_SpatialMixerAttenuationCurve: AudioUnitPropertyID = 3013
public let kAudioUnitProperty_3DMixerAttenuationCurve: AudioUnitPropertyID = 3013
public let kAudioUnitProperty_SampleRateConverterComplexity: AudioUnitPropertyID = 3014
public let kAudioUnitProperty_InputAnchorTimeStamp: AudioUnitPropertyID = 3016
public let kAudioUnitProperty_ReverbPreset: AudioUnitPropertyID = 3017
public let kAudioUnitProperty_SpatialMixerOutputType: AudioUnitPropertyID = 3100
public let kAudioUnitProperty_SpatialMixerPointSourceInHeadMode: AudioUnitPropertyID = 3103
public let kAudioUnitProperty_SpatialMixerEnableHeadTracking: AudioUnitPropertyID = 3111
public let kAudioUnitProperty_SpatialMixerPersonalizedHRTFMode: AudioUnitPropertyID = 3113
public let kAudioUnitProperty_SpatialMixerAnyInputIsUsingPersonalizedHRTF: AudioUnitPropertyID = 3116
public let kAudioUnitProperty_ScheduleAudioSlice: AudioUnitPropertyID = 3300
public let kAudioUnitProperty_ScheduleStartTimeStamp: AudioUnitPropertyID = 3301
public let kAudioUnitProperty_CurrentPlayTime: AudioUnitPropertyID = 3302
public let kAudioUnitProperty_ScheduledFileIDs: AudioUnitPropertyID = 3310
public let kAudioUnitProperty_ScheduledFileRegion: AudioUnitPropertyID = 3311
public let kAudioUnitProperty_ScheduledFilePrime: AudioUnitPropertyID = 3312
public let kAudioUnitProperty_ScheduledFileBufferSizeFrames: AudioUnitPropertyID = 3313
public let kAudioUnitProperty_ScheduledFileNumberBuffers: AudioUnitPropertyID = 3314
public let kAudioUnitProperty_DeferredRendererPullSize: AudioUnitPropertyID = 3320
public let kAudioUnitProperty_DeferredRendererExtraLatency: AudioUnitPropertyID = 3321
public let kAudioUnitProperty_DeferredRendererWaitFrames: AudioUnitPropertyID = 3322

public let kAudioOutputUnitProperty_CurrentDevice: AudioUnitPropertyID = 2000
public let kAudioOutputUnitProperty_IsRunning: AudioUnitPropertyID = 2001
public let kAudioOutputUnitProperty_ChannelMap: AudioUnitPropertyID = 2002
public let kAudioOutputUnitProperty_EnableIO: AudioUnitPropertyID = 2003
public let kAudioOutputUnitProperty_StartTime: AudioUnitPropertyID = 2004
public let kAudioOutputUnitProperty_SetInputCallback: AudioUnitPropertyID = 2005
public let kAudioOutputUnitProperty_HasIO: AudioUnitPropertyID = 2006
public let kAudioOutputUnitProperty_StartTimestampsAtZero: AudioUnitPropertyID = 2007
public let kAudioOutputUnitProperty_MIDICallbacks: AudioUnitPropertyID = 2010
public let kAudioOutputUnitProperty_HostReceivesRemoteControlEvents: AudioUnitPropertyID = 2011
public let kAudioOutputUnitProperty_RemoteControlToHost: AudioUnitPropertyID = 2012
public let kAudioOutputUnitProperty_HostTransportState: AudioUnitPropertyID = 2013
public let kAudioOutputUnitProperty_NodeComponentDescription: AudioUnitPropertyID = 2014

public let kAudioUnitRange: Int = 0x0000
public let kAudioUnitInitializeSelect: Int = 0x0001
public let kAudioUnitUninitializeSelect: Int = 0x0002
public let kAudioUnitGetPropertyInfoSelect: Int = 0x0003
public let kAudioUnitGetPropertySelect: Int = 0x0004
public let kAudioUnitSetPropertySelect: Int = 0x0005
public let kAudioUnitGetParameterSelect: Int = 0x0006
public let kAudioUnitSetParameterSelect: Int = 0x0007
public let kAudioUnitResetSelect: Int = 0x0009
public let kAudioUnitAddPropertyListenerSelect: Int = 0x000A
public let kAudioUnitRemovePropertyListenerSelect: Int = 0x000B
public let kAudioUnitRenderSelect: Int = 0x000E
public let kAudioUnitAddRenderNotifySelect: Int = 0x000F
public let kAudioUnitRemoveRenderNotifySelect: Int = 0x0010
public let kAudioUnitScheduleParametersSelect: Int = 0x0011
public let kAudioUnitRemovePropertyListenerWithUserDataSelect: Int = 0x0012
public let kAudioUnitComplexRenderSelect: Int = 0x0013
public let kAudioUnitProcessSelect: Int = 0x0014
public let kAudioUnitProcessMultipleSelect: Int = 0x0015

public let kAudioOutputUnitRange: Int = 0x0200
public let kAudioOutputUnitStartSelect: Int = 0x0201
public let kAudioOutputUnitStopSelect: Int = 0x0202

public let kAudioUnitSampleRateConverterComplexity_Linear: UInt32 = atFourCC("line")
public let kAudioUnitSampleRateConverterComplexity_Normal: UInt32 = atFourCC("norm")
public let kAudioUnitSampleRateConverterComplexity_Mastering: UInt32 = atFourCC("bats")

public struct AudioUnitRenderActionFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let unitRenderAction_PreRender = AudioUnitRenderActionFlags(rawValue: 1 << 2)
    public static let unitRenderAction_PostRender = AudioUnitRenderActionFlags(rawValue: 1 << 3)
    public static let unitRenderAction_OutputIsSilence = AudioUnitRenderActionFlags(rawValue: 1 << 4)
    public static let offlineUnitRenderAction_Preflight = AudioUnitRenderActionFlags(rawValue: 1 << 5)
    public static let offlineUnitRenderAction_Render = AudioUnitRenderActionFlags(rawValue: 1 << 6)
    public static let offlineUnitRenderAction_Complete = AudioUnitRenderActionFlags(rawValue: 1 << 7)
    public static let unitRenderAction_PostRenderError = AudioUnitRenderActionFlags(rawValue: 1 << 8)
    public static let unitRenderAction_DoNotCheckRenderArgs = AudioUnitRenderActionFlags(rawValue: 1 << 9)
}

public enum AudioUnitParameterUnit: UInt32, Sendable, Hashable {
    case generic = 0
    case indexed = 1
    case boolean = 2
    case percent = 3
    case seconds = 4
    case sampleFrames = 5
    case phase = 6
    case rate = 7
    case hertz = 8
    case cents = 9
    case relativeSemiTones = 10
    case midiNoteNumber = 11
    case midiController = 12
    case decibels = 13
    case linearGain = 14
    case degrees = 15
    case equalPowerCrossfade = 16
    case mixerFaderCurve1 = 17
    case pan = 18
    case meters = 19
    case absoluteCents = 20
    case octaves = 21
    case BPM = 22
    case beats = 23
    case milliseconds = 24
    case ratio = 25
    case customUnit = 26
    case midi2Controller = 27
}

public struct AudioUnitParameterOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let flag_CFNameRelease = AudioUnitParameterOptions(rawValue: 1 << 4)
    public static let flag_OmitFromPresets = AudioUnitParameterOptions(rawValue: 1 << 13) // if present
    public static let flag_PlotHistory = AudioUnitParameterOptions(rawValue: 1 << 14)
    public static let flag_MeterReadOnly = AudioUnitParameterOptions(rawValue: 1 << 15)
    public static let flag_DisplayMask = AudioUnitParameterOptions(rawValue: 7 << 16)
    public static let flag_DisplaySquareRoot = AudioUnitParameterOptions(rawValue: 1 << 16)
    public static let flag_DisplaySquared = AudioUnitParameterOptions(rawValue: 2 << 16)
    public static let flag_DisplayCubed = AudioUnitParameterOptions(rawValue: 3 << 16)
    public static let flag_DisplayCubeRoot = AudioUnitParameterOptions(rawValue: 4 << 16)
    public static let flag_DisplayExponential = AudioUnitParameterOptions(rawValue: 5 << 16)
    public static let flag_DisplayLogarithmic = AudioUnitParameterOptions(rawValue: 6 << 16)
    public static let flag_HasClump = AudioUnitParameterOptions(rawValue: 1 << 20)
    public static let flag_HasCFNameString = AudioUnitParameterOptions(rawValue: 1 << 21)
    public static let flag_IsHighResolution = AudioUnitParameterOptions(rawValue: 1 << 22)
    public static let flag_NonRealTime = AudioUnitParameterOptions(rawValue: 1 << 23)
    public static let flag_CanRamp = AudioUnitParameterOptions(rawValue: 1 << 24)
    public static let flag_ExpertMode = AudioUnitParameterOptions(rawValue: 1 << 25)
    public static let flag_HasName = AudioUnitParameterOptions(rawValue: 1 << 26)
    public static let flag_IsGlobalMeta = AudioUnitParameterOptions(rawValue: 1 << 10)
    public static let flag_IsElementMeta = AudioUnitParameterOptions(rawValue: 1 << 11)
    public static let flag_ValuesHaveStrings = AudioUnitParameterOptions(rawValue: 1 << 16)
    public static let flag_IsReadable = AudioUnitParameterOptions(rawValue: 1 << 30)
    public static let flag_IsWritable = AudioUnitParameterOptions(rawValue: 1 << 31)
}

public enum AudioUnitEventType: UInt32, Sendable, Hashable {
    case parameterValueChange = 0
    case beginParameterChangeGesture = 1
    case endParameterChangeGesture = 2
    case propertyChange = 3
}

public enum AudioUnitRemoteControlEvent: UInt32, Sendable, Hashable {
    case togglePlayPause = 1
    case toggleRecord = 2
    case rewind = 3
}
