#if os(Linux)
import Glibc
#endif
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
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    if unit.isRemoteIO {
        return kAudioUnitErr_FailedInitialization
    }
    unit.initialized = true
    return 0
}

@_cdecl("AudioUnitUninitialize")
public func AudioUnitUninitialize(_ inUnit: AudioUnit?) -> Int32 {
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    unit.initialized = false
    return 0
}

@_cdecl("AudioOutputUnitStart")
public func AudioOutputUnitStart(_ ci: AudioUnit?) -> Int32 {
    guard let unit = ATRegistry.shared.lookup(ci, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_FailedInitialization
    }
    if unit.isRemoteIO {
        return kAudioUnitErr_FailedInitialization
    }
    if !unit.initialized {
        return kAudioUnitErr_Uninitialized
    }
    return 0
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
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    if !unit.initialized {
        return kAudioUnitErr_Uninitialized
    }
    return 0
}

public func AudioUnitGetProperty(
    _ inUnit: AudioUnit?,
    _ inID: AudioUnitPropertyID,
    _ inScope: AudioUnitScope,
    _ inElement: AudioUnitElement,
    _ outData: UnsafeMutableRawPointer?,
    _ ioDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inElement
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    switch inID {
    case kAudioUnitProperty_StreamFormat:
        if let ioDataSize, ioDataSize.pointee < UInt32(atASBDSize) {
            return kAudioUnitErr_InvalidPropertyValue
        }
        ioDataSize?.pointee = UInt32(atASBDSize)
        let format = inScope == kAudioUnitScope_Input ? unit.inputFormat : unit.outputFormat
        if let outData { atStoreASBD(format, to: outData) }
        return 0
    case kAudioUnitProperty_ElementCount:
        ioDataSize?.pointee = 4
        let count = inScope == kAudioUnitScope_Input ? unit.inputCount : unit.outputCount
        outData?.storeBytes(of: count, as: UInt32.self)
        return 0
    case kAudioUnitProperty_SampleRate:
        ioDataSize?.pointee = 8
        outData?.storeBytes(of: unit.outputFormat.mSampleRate, as: Float64.self)
        return 0
    case kAudioUnitProperty_MaximumFramesPerSlice:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: unit.maximumFrames, as: UInt32.self)
        return 0
    case kAudioUnitProperty_LastRenderError:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: unit.lastRenderError, as: Int32.self)
        return 0
    default:
        return kAudioUnitErr_InvalidProperty
    }
}

public func AudioUnitSetProperty(
    _ inUnit: AudioUnit?,
    _ inID: AudioUnitPropertyID,
    _ inScope: AudioUnitScope,
    _ inElement: AudioUnitElement,
    _ inData: UnsafeRawPointer?,
    _ inDataSize: UInt32
) -> Int32 {
    _ = inElement
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    if unit.initialized && inID == kAudioUnitProperty_StreamFormat {
        return kAudioUnitErr_Initialized
    }
    switch inID {
    case kAudioUnitProperty_StreamFormat:
        guard let inData, inDataSize >= UInt32(atASBDSize), var format = atLoadASBD(inData) else {
            return kAudioUnitErr_FormatNotSupported
        }
        if format.mFormatID != atFormatLinearPCM {
            return kAudioUnitErr_FormatNotSupported
        }
        atFillPCMASBD(&format)
        if inScope == kAudioUnitScope_Input {
            unit.inputFormat = format
        } else {
            unit.outputFormat = format
        }
        return 0
    case kAudioUnitProperty_ElementCount:
        guard let inData, inDataSize >= 4 else { return kAudioUnitErr_InvalidPropertyValue }
        let count = inData.loadUnaligned(as: UInt32.self)
        if inScope == kAudioUnitScope_Input {
            unit.inputCount = max(1, count)
        } else {
            unit.outputCount = max(1, count)
        }
        return 0
    case kAudioUnitProperty_MaximumFramesPerSlice:
        guard let inData, inDataSize >= 4 else { return kAudioUnitErr_InvalidPropertyValue }
        unit.maximumFrames = inData.loadUnaligned(as: UInt32.self)
        return 0
    default:
        return kAudioUnitErr_InvalidProperty
    }
}

public func AudioUnitGetParameter(
    _ inUnit: AudioUnit?,
    _ inID: AudioUnitParameterID,
    _ inScope: AudioUnitScope,
    _ inElement: AudioUnitElement,
    _ outValue: UnsafeMutablePointer<AudioUnitParameterValue>?
) -> Int32 {
    _ = inScope
    _ = inElement
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    outValue?.pointee = unit.parameters[inID] ?? 0
    return 0
}

public func AudioUnitSetParameter(
    _ inUnit: AudioUnit?,
    _ inID: AudioUnitParameterID,
    _ inScope: AudioUnitScope,
    _ inElement: AudioUnitElement,
    _ inValue: AudioUnitParameterValue,
    _ inBufferOffsetInFrames: UInt32
) -> Int32 {
    _ = inScope
    _ = inElement
    _ = inBufferOffsetInFrames
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    unit.parameters[inID] = inValue
    return 0
}

public func AudioUnitRender(
    _ inUnit: AudioUnit?,
    _ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    _ inTimeStamp: UnsafeRawPointer?,
    _ inOutputBusNumber: UInt32,
    _ inNumberFrames: UInt32,
    _ ioData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inTimeStamp
    _ = inOutputBusNumber
    guard let unit = ATRegistry.shared.lookup(inUnit, as: ATAudioUnitObject.self) else {
        return kAudioUnitErr_InvalidElement
    }
    if unit.isRemoteIO {
        unit.lastRenderError = kAudioUnitErr_FailedInitialization
        return kAudioUnitErr_FailedInitialization
    }
    if !unit.initialized {
        unit.lastRenderError = kAudioUnitErr_Uninitialized
        return kAudioUnitErr_Uninitialized
    }
    if inNumberFrames > unit.maximumFrames {
        unit.lastRenderError = kAudioUnitErr_TooManyFramesToProcess
        return kAudioUnitErr_TooManyFramesToProcess
    }
    guard let list = atLoadBufferList(ioData), let first = list.buffers.first, let dest = first.data else {
        unit.lastRenderError = kAudioUnitErr_InvalidParameter
        return kAudioUnitErr_InvalidParameter
    }
    let bytes = Int(inNumberFrames) * Int(max(unit.outputFormat.mBytesPerFrame, 1))
    let count = min(bytes, Int(first.dataByteSize))
    memset(dest, 0, count)
    if unit.isMixer {
        // Offline mixer with no connected inputs renders silence (sum of empty buses).
        _ = atMixPCM(inputs: [], dest: unit.outputFormat, output: dest, outputByteCapacity: count)
    }
    ioActionFlags?.pointee.insert(.unitRenderAction_OutputIsSilence)
    unit.lastRenderError = 0
    return 0
}
