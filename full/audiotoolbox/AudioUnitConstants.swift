import Foundation

public let kAudioUnitManufacturer_Apple: UInt32 = atFourCC("appl")

public let kAudioUnitType_Output: UInt32 = atFourCC("auou")
public let kAudioUnitType_MusicDevice: UInt32 = atFourCC("aumu")
public let kAudioUnitType_MusicEffect: UInt32 = atFourCC("aumf")
public let kAudioUnitType_FormatConverter: UInt32 = atFourCC("aufc")
public let kAudioUnitType_Effect: UInt32 = atFourCC("aufx")
public let kAudioUnitType_Mixer: UInt32 = atFourCC("aumx")
public let kAudioUnitType_Panner: UInt32 = atFourCC("aupn")
public let kAudioUnitType_Generator: UInt32 = atFourCC("augn")
public let kAudioUnitType_OfflineEffect: UInt32 = atFourCC("auol")
public let kAudioUnitType_MIDIProcessor: UInt32 = atFourCC("aumi")
public let kAudioUnitType_SpeechSynthesizer: UInt32 = atFourCC("ausp")
public let kAudioUnitType_RemoteEffect: UInt32 = atFourCC("aurx")
public let kAudioUnitType_RemoteGenerator: UInt32 = atFourCC("aurg")
public let kAudioUnitType_RemoteInstrument: UInt32 = atFourCC("auri")
public let kAudioUnitType_RemoteMusicEffect: UInt32 = atFourCC("aurm")

public let kAudioUnitSubType_GenericOutput: UInt32 = atFourCC("genr")
public let kAudioUnitSubType_RemoteIO: UInt32 = atFourCC("rioc")
public let kAudioUnitSubType_VoiceProcessingIO: UInt32 = atFourCC("vpio")
public let kAudioUnitSubType_Sampler: UInt32 = atFourCC("samp")
public let kAudioUnitSubType_MIDISynth: UInt32 = atFourCC("msyn")
public let kAudioUnitSubType_AUConverter: UInt32 = atFourCC("conv")
public let kAudioUnitSubType_Varispeed: UInt32 = atFourCC("vari")
public let kAudioUnitSubType_DeferredRenderer: UInt32 = atFourCC("defr")
public let kAudioUnitSubType_Splitter: UInt32 = atFourCC("splt")
public let kAudioUnitSubType_Merger: UInt32 = atFourCC("merg")
public let kAudioUnitSubType_NewTimePitch: UInt32 = atFourCC("nutp")
public let kAudioUnitSubType_AUiPodTimeOther: UInt32 = atFourCC("ipto")
public let kAudioUnitSubType_RoundTripAAC: UInt32 = atFourCC("raac")
public let kAudioUnitSubType_MultiSplitter: UInt32 = atFourCC("mspl")
public let kAudioUnitSubType_TimePitch: UInt32 = atFourCC("tmpt")
public let kAudioUnitSubType_AUiPodTime: UInt32 = atFourCC("iptm")
public let kAudioUnitSubType_PeakLimiter: UInt32 = atFourCC("lmtr")
public let kAudioUnitSubType_DynamicsProcessor: UInt32 = atFourCC("dcmp")
public let kAudioUnitSubType_LowPassFilter: UInt32 = atFourCC("lpas")
public let kAudioUnitSubType_HighPassFilter: UInt32 = atFourCC("hpas")
public let kAudioUnitSubType_HighShelfFilter: UInt32 = atFourCC("hshf")
public let kAudioUnitSubType_LowShelfFilter: UInt32 = atFourCC("lshf")
public let kAudioUnitSubType_ParametricEQ: UInt32 = atFourCC("pmeq")
public let kAudioUnitSubType_Delay: UInt32 = atFourCC("dely")
public let kAudioUnitSubType_SampleDelay: UInt32 = atFourCC("sdly")
public let kAudioUnitSubType_Distortion: UInt32 = atFourCC("dist")
public let kAudioUnitSubType_BandPassFilter: UInt32 = atFourCC("bpas")
public let kAudioUnitSubType_NBandEQ: UInt32 = atFourCC("nbeq")
public let kAudioUnitSubType_Reverb2: UInt32 = atFourCC("rvb2")
public let kAudioUnitSubType_AUiPodEQ: UInt32 = atFourCC("ipeq")
public let kAudioUnitSubType_AUSoundIsolation: UInt32 = atFourCC("asis")
public let kAudioUnitSubType_MultiChannelMixer: UInt32 = atFourCC("mcmx")
public let kAudioUnitSubType_MatrixMixer: UInt32 = atFourCC("mxmx")
public let kAudioUnitSubType_SpatialMixer: UInt32 = atFourCC("3dem")
public let kAudioUnitSubType_AU3DMixerEmbedded: UInt32 = atFourCC("3dem")
public let kAudioUnitSubType_ScheduledSoundPlayer: UInt32 = atFourCC("sspl")
public let kAudioUnitSubType_AudioFilePlayer: UInt32 = atFourCC("afpl")
public let kAudioUnitSubType_AUAudioMix: UInt32 = atFourCC("amix")

public enum AUAudioUnitBusType: UInt32, Sendable, Hashable {
    case input = 1
    case output = 2
}

public enum AURenderEventType: UInt8, Sendable, Hashable {
    case parameter = 1
    case parameterRamp = 2
    case MIDI = 8
    case midiSysEx = 9
    case midiEventList = 10
}

public enum AUParameterEventType: UInt32, Sendable, Hashable {
    case parameterEvent_Immediate = 1
    case parameterEvent_Ramped = 2
}

public enum AUParameterAutomationEventType: UInt32, Sendable, Hashable {
    case value = 0
    case touch = 1
    case release = 2
}

@_cdecl("AudioUnitInitialize")
public func AudioUnitInitialize(_ inUnit: AudioUnit?) -> Int32 {
    guard ATRegistry.shared.lookup(inUnit) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_FailedInitialization
}

@_cdecl("AudioUnitUninitialize")
public func AudioUnitUninitialize(_ inUnit: AudioUnit?) -> Int32 {
    guard ATRegistry.shared.lookup(inUnit) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return 0
}

@_cdecl("AudioOutputUnitStart")
public func AudioOutputUnitStart(_ ci: AudioUnit?) -> Int32 {
    _ = ci
    return kAudioUnitErr_FailedInitialization
}

@_cdecl("AudioOutputUnitStop")
public func AudioOutputUnitStop(_ ci: AudioUnit?) -> Int32 {
    _ = ci
    return 0
}

@_cdecl("AudioUnitReset")
public func AudioUnitReset(
    _ inUnit: AudioUnit?,
    _ inScope: AudioUnitScope,
    _ inElement: AudioUnitElement
) -> Int32 {
    _ = inScope
    _ = inElement
    guard ATRegistry.shared.lookup(inUnit) != nil else {
        return kAudioUnitErr_InvalidElement
    }
    return kAudioUnitErr_Uninitialized
}
