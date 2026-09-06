#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atW6Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW6PCMBlob(
    rate: Float64 = 44100,
    channels: UInt32 = 1,
    bits: UInt32 = 16,
    flags: UInt32 = 12
) -> [UInt8] {
    var blob = [UInt8](repeating: 0, count: 40)
    let bytesPerSample = bits / 8
    blob.withUnsafeMutableBytes { raw in
        let p = raw.baseAddress!
        p.storeBytes(of: rate, toByteOffset: 0, as: Float64.self)
        p.storeBytes(of: UInt32(0x6C70_636D), toByteOffset: 8, as: UInt32.self)
        p.storeBytes(of: flags, toByteOffset: 12, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 16, as: UInt32.self)
        p.storeBytes(of: UInt32(1), toByteOffset: 20, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 24, as: UInt32.self)
        p.storeBytes(of: channels, toByteOffset: 28, as: UInt32.self)
        p.storeBytes(of: bits, toByteOffset: 32, as: UInt32.self)
    }
    return blob
}

private func atW6MixerDescription() -> AudioComponentDescription {
    AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
}

func testWave6ConstantAliases() {
    atW6Expect(k3DMixerParam_BusEnable == k3DMixerParam_Enable, "bus enable alias")
    atW6Expect(k3DMixerParam_DryWetReverbBlend == k3DMixerParam_ReverbBlend, "dry wet alias")
    atW6Expect(
        k3DMixerParam_GlobalReverbGainInDecibels == k3DMixerParam_GlobalReverbGain,
        "global reverb alias"
    )
    atW6Expect(k3DMixerParam_MaxGainInDecibels == k3DMixerParam_MaxGain, "max gain alias")
    atW6Expect(k3DMixerParam_MinGainInDecibels == k3DMixerParam_MinGain, "min gain alias")
    atW6Expect(
        k3DMixerParam_ObstructionAttenuationInDecibels == k3DMixerParam_ObstructionAttenuation,
        "obstruction alias"
    )
    atW6Expect(
        k3DMixerParam_OcclusionAttenuationInDecibels == k3DMixerParam_OcclusionAttenuation,
        "occlusion alias"
    )
    atW6Expect(kDynamicRangeCompressionProfile_None == 0, "drc none")
    atW6Expect(kDynamicRangeCompressionProfile_LateNight == 1, "drc late")
    atW6Expect(kDynamicRangeCompressionProfile_NoisyEnvironment == 2, "drc noisy")
    atW6Expect(kDynamicRangeCompressionProfile_LimitedPlaybackRange == 3, "drc limited")
    atW6Expect(kDynamicRangeCompressionProfile_GeneralCompression == 6, "drc general iso")
    atW6Expect(kDynamicRangeControlMode_None == 0, "mode none")
    atW6Expect(kDynamicRangeControlMode_Light == 1, "mode light")
    atW6Expect(kDynamicRangeControlMode_Heavy == 2, "mode heavy")
    atW6Expect(kProgramTargetLevel_None == 0, "ptl none")
    atW6Expect(kProgramTargetLevel_Minus31dB == 1, "ptl 31")
    atW6Expect(kProgramTargetLevel_Minus23dB == 2, "ptl 23")
    atW6Expect(kProgramTargetLevel_Minus20dB == 3, "ptl 20")
    atW6Expect(kNewTimePitchParam_Smoothness == kNewTimePitchParam_Overlap, "ntp smoothness")
    atW6Expect(
        kNewTimePitchParam_EnableSpectralCoherence == kNewTimePitchParam_EnablePeakLocking,
        "ntp coherence"
    )
    atW6Expect(kNewTimePitchParam_EnableTransientPreservation == 7, "ntp transient")
    atW6Expect(kAUSoundIsolationParam_WetDryMixPercent == 0, "iso wet")
    atW6Expect(kAUSoundIsolationParam_SoundToIsolate == 1, "iso sound")
    atW6Expect(kAUSoundIsolationSoundType_HighQualityVoice == 0, "iso hq")
    atW6Expect(kAUSoundIsolationSoundType_Voice == 1, "iso voice")
}

func testAudioUnitParameterInfoOverlay() {
    var info = AudioUnitParameterInfo()
    atW6Expect(info.unit == .generic && info.minValue == 0 && info.maxValue == 1, "empty")
    atW6Expect(info.clumpID == 0 && info.flags.isEmpty, "empty flags")
    atW6Expect(info.name.0 == 0 && info.name.51 == 0, "52-byte name")
    atW6Expect(info.unitName == nil && info.cfNameString == nil, "no cf")
    var filledName = info.name
    filledName.0 = 71
    filledName.1 = 97
    filledName.2 = 105
    filledName.3 = 110
    info = AudioUnitParameterInfo(
        name: filledName,
        unitName: nil,
        clumpID: 7,
        cfNameString: nil,
        unit: .linearGain,
        minValue: 0,
        maxValue: 2,
        defaultValue: 1,
        flags: .flag_CanRamp
    )
    atW6Expect(info.name.0 == 71 && info.name.3 == 110, "gain letters")
    atW6Expect(info.clumpID == 7 && info.defaultValue == 1, "clump default")
    atW6Expect(info.unit == .linearGain && info.flags.contains(.flag_CanRamp), "unit flags")
    atW6Expect(MemoryLayout<AudioUnitParameterInfo>.size >= 52 + 8 + 4 + 8 + 4 + 12, "layout floor")
}

func testScheduledAudioSliceOverlay() {
    var completions = 0
    let proc: ScheduledAudioSliceCompletionProc = { _, _ in
        completions += 1
    }
    var user: UInt8 = 9
    var slice = ScheduledAudioSlice()
    atW6Expect(slice.mNumberFrames == 0 && slice.mBufferList == nil, "empty")
    atW6Expect(slice.mFlags.isEmpty && slice.mReserved == 0 && slice.mReserved2 == nil, "reserved")
    slice = ScheduledAudioSlice(
        mTimeStamp: (1, 2, 3, 4, 5, 6, 7, 8),
        mCompletionProc: proc,
        mCompletionProcUserData: &user,
        mFlags: .scheduledAudioSliceFlag_Loop,
        mReserved: 11,
        mReserved2: nil,
        mNumberFrames: 64,
        mBufferList: &user
    )
    atW6Expect(slice.mTimeStamp.0 == 1 && slice.mTimeStamp.7 == 8, "stamp overlay")
    atW6Expect(slice.mNumberFrames == 64, "frames")
    atW6Expect(slice.mFlags.contains(.scheduledAudioSliceFlag_Loop), "loop")
    atW6Expect(slice.mReserved == 11, "reserved")
    atW6Expect(slice.mCompletionProcUserData == UnsafeMutableRawPointer(&user), "user")
    var mutable = slice
    withUnsafeMutablePointer(to: &mutable) { pointer in
        slice.mCompletionProc?(slice.mCompletionProcUserData, pointer)
    }
    atW6Expect(completions == 1, "completion fired")
}

func testAUMIDIEventOverlay() {
    var event = AUMIDIEvent()
    atW6Expect(event.eventType == .MIDI && event.length == 0 && event.cable == 0, "empty")
    atW6Expect(event.data.0 == 0 && event.next == nil && event.reserved == 0, "empty data")
    event = AUMIDIEvent(
        next: nil,
        eventSampleTime: AUEventSampleTimeImmediate,
        eventType: .MIDI,
        reserved: 1,
        length: 3,
        cable: 2,
        data: (0x90, 60, 100)
    )
    atW6Expect(event.eventSampleTime == -1, "immediate")
    atW6Expect(event.length == 3 && event.cable == 2, "len cable")
    atW6Expect(event.data.0 == 0x90 && event.data.1 == 60 && event.data.2 == 100, "note on")
    atW6Expect(event.reserved == 1 && event.eventType == .MIDI, "type")
}

func testAUParameterEventOverlay() {
    var event = AUParameterEvent()
    atW6Expect(event.value == 0 && event.parameterAddress == 0, "empty")
    atW6Expect(event.reserved.0 == 0 && event.rampDurationSampleFrames == 0, "reserved")
    event = AUParameterEvent(
        next: nil,
        eventSampleTime: 48,
        eventType: .parameterRamp,
        reserved: (1, 2, 3),
        rampDurationSampleFrames: 128,
        parameterAddress: 7,
        value: 0.25
    )
    atW6Expect(event.eventSampleTime == 48 && event.eventType == .parameterRamp, "time type")
    atW6Expect(event.reserved.1 == 2 && event.rampDurationSampleFrames == 128, "ramp")
    atW6Expect(event.parameterAddress == 7 && event.value == 0.25, "addr value")
}

func testScheduledAudioFileRegionOverlay() {
    var completions = 0
    let proc: ScheduledAudioFileRegionCompletionProc = { _, _, status in
        completions += status == 0 ? 1 : 0
    }
    var region = ScheduledAudioFileRegion()
    atW6Expect(region.mLoopCount == 0 && region.mStartFrame == 0 && region.mFramesToPlay == 0, "empty")
    atW6Expect(region.mAudioFile == nil && region.mCompletionProc == nil, "empty ptrs")
    region = ScheduledAudioFileRegion(
        mTimeStamp: (9, 0, 0, 0, 0, 0, 0, 0),
        mCompletionProc: proc,
        mCompletionProcUserData: nil,
        mAudioFile: OpaquePointer(bitPattern: 5),
        mLoopCount: 2,
        mStartFrame: 16,
        mFramesToPlay: 32
    )
    atW6Expect(region.mTimeStamp.0 == 9, "stamp")
    atW6Expect(region.mLoopCount == 2 && region.mStartFrame == 16 && region.mFramesToPlay == 32, "play")
    atW6Expect(region.mAudioFile == OpaquePointer(bitPattern: 5), "file")
    var mutable = region
    withUnsafeMutablePointer(to: &mutable) { pointer in
        region.mCompletionProc?(nil, pointer, 0)
    }
    atW6Expect(completions == 1, "file region completion")
}

func testAudioFileRegionAndNext() {
    let name = "verse" as CFString
    var first = AudioFileRegion(
        mRegionID: 1,
        mName: Unmanaged.passUnretained(name),
        mFlags: .loopEnable,
        mNumberMarkers: 1,
        mMarkers: AudioFileMarker(
            mFramePosition: 8,
            mName: nil,
            mMarkerID: 4,
            mSMPTETime: AudioFile_SMPTE_Time(),
            mType: 0,
            mReserved: 0,
            mChannel: 1
        )
    )
    atW6Expect(first.mRegionID == 1 && first.mFlags.contains(.loopEnable), "flags")
    atW6Expect(first.mNumberMarkers == 1 && first.mMarkers.mFramePosition == 8, "marker")
    atW6Expect(first.mName?.takeUnretainedValue() as String == "verse", "name")
    var list = AudioFileRegionList(mSMPTE_TimeType: 1, mNumberRegions: 2, mRegions: first)
    atW6Expect(list.mSMPTE_TimeType == 1 && list.mNumberRegions == 2, "list")
    list = AudioFileRegionList()
    atW6Expect(list.mNumberRegions == 0, "empty list")
    first = AudioFileRegion()
    atW6Expect(first.mRegionID == 0 && first.mName == nil, "empty region")

    var storage = [
        AudioFileRegion(
            mRegionID: 10,
            mName: Unmanaged.passUnretained(name),
            mFlags: .playForward,
            mNumberMarkers: 1,
            mMarkers: AudioFileMarker()
        ),
        AudioFileRegion(
            mRegionID: 11,
            mName: Unmanaged.passUnretained(name),
            mFlags: .playBackward,
            mNumberMarkers: 1,
            mMarkers: AudioFileMarker()
        )
    ]
    let next = storage.withUnsafeMutableBufferPointer { buffer in
        NextAudioFileRegion(buffer.baseAddress!)
    }
    atW6Expect(next.pointee.mRegionID == 11, "next region id")
    atW6Expect(next.pointee.mFlags.contains(.playBackward), "next flags")
}

func testAudioPanningInfoOverlay() {
    var info = AudioPanningInfo()
    atW6Expect(info.mPanningMode == .panningMode_SoundField, "mode")
    atW6Expect(info.mGainScale == 1 && info.mOutputChannelMap == nil, "gain map")
    var dummy: UInt32 = 0
    info = AudioPanningInfo(
        mPanningMode: .panningMode_VectorBasedPanning,
        mCoordinateFlags: 3,
        mCoordinates: (1.5, -0.5, 0.25),
        mGainScale: 0.8,
        mOutputChannelMap: UnsafeRawPointer(&dummy)
    )
    atW6Expect(info.mPanningMode == .panningMode_VectorBasedPanning, "vector")
    atW6Expect(info.mCoordinateFlags == 3, "flags")
    atW6Expect(info.mCoordinates.0 == 1.5 && info.mCoordinates.2 == 0.25, "xyz")
    atW6Expect(info.mGainScale == 0.8 && info.mOutputChannelMap != nil, "scale map")
}

func testAudioUnitParameterEventSchedule() {
    var event = AudioUnitParameterEvent()
    atW6Expect(event.eventType == .parameterEvent_Immediate && event.parameter == 0, "empty")
    event = AudioUnitParameterEvent(
        scope: kAudioUnitScope_Input,
        element: 1,
        parameter: kMultiChannelMixerParam_Volume,
        eventType: .parameterEvent_Immediate,
        eventValues: AudioUnitParameterEventValues(value: 0.25)
    )
    atW6Expect(event.scope == kAudioUnitScope_Input && event.element == 1, "scope el")
    atW6Expect(event.parameter == kMultiChannelMixerParam_Volume, "param")
    atW6Expect(event.eventValues.value == 0.25, "immediate value")

    var desc = atW6MixerDescription()
    let component = AudioComponentFindNext(nil, &desc)
    var unit: AudioComponentInstance?
    atW6Expect(AudioComponentInstanceNew(component, &unit) == 0, "new mixer")
    atW6Expect(AudioUnitInitialize(unit) == 0, "init")
    atW6Expect(
        withUnsafePointer(to: &event) { pointer in
            AudioUnitScheduleParameters(unit, pointer, 1)
        } == 0,
        "schedule"
    )
    var value: AudioUnitParameterValue = 0
    atW6Expect(
        AudioUnitGetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, &value) == 0,
        "get"
    )
    atW6Expect(value == 0.25, "scheduled volume")
    var ramp = AudioUnitParameterEvent(
        scope: kAudioUnitScope_Input,
        element: 1,
        parameter: kMultiChannelMixerParam_Volume,
        eventType: .parameterEvent_Ramped,
        eventValues: AudioUnitParameterEventValues(
            value: 0,
            startBufferOffset: 0,
            durationInFrames: 64,
            startValue: 0.25,
            endValue: 0.5
        )
    )
    atW6Expect(ramp.eventValues.endValue == 0.5 && ramp.eventValues.durationInFrames == 64, "ramp fields")
    atW6Expect(
        withUnsafePointer(to: &ramp) { pointer in
            AudioUnitScheduleParameters(unit, pointer, 1)
        } == 0,
        "ramp schedule"
    )
    atW6Expect(
        AudioUnitGetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, &value) == 0
            && value == 0.5,
        "ramp applied as end"
    )
    atW6Expect(AudioUnitScheduleParameters(nil, nil, 1) == kAudioUnitErr_InvalidElement, "nil unit")
    _ = AudioComponentInstanceDispose(unit)
}

func testHostCallbackInfoOverlay() {
    var info = HostCallbackInfo()
    atW6Expect(info.hostUserData == nil && info.beatAndTempoProc == nil, "empty")
    var beats: Float64 = 0
    var tempo: Float64 = 0
    let beat: HostCallback_GetBeatAndTempo = { _, outBeat, outTempo in
        outBeat?.pointee = 4
        outTempo?.pointee = 120
        return 0
    }
    let location: HostCallback_GetMusicalTimeLocation = { _, _, _, _, _ in 0 }
    let transport: HostCallback_GetTransportState = { _, moving, _, _, _, _, _ in
        moving?.pointee = 1
        return 0
    }
    let transport2: HostCallback_GetTransportState2 = { _, _, _, _, _, _, _, _ in 0 }
    var token: UInt8 = 1
    info = HostCallbackInfo(
        hostUserData: &token,
        beatAndTempoProc: beat,
        musicalTimeLocationProc: location,
        transportStateProc: transport,
        transportStateProc2: transport2
    )
    atW6Expect(info.hostUserData == UnsafeMutableRawPointer(&token), "user")
    atW6Expect(info.beatAndTempoProc?(nil, &beats, &tempo) == 0 && beats == 4 && tempo == 120, "beat")
    var moving: UInt8 = 0
    atW6Expect(info.transportStateProc?(nil, &moving, nil, nil, nil, nil, nil) == 0 && moving == 1, "moving")
    atW6Expect(info.musicalTimeLocationProc?(nil, nil, nil, nil, nil) == 0, "location")
    atW6Expect(info.transportStateProc2?(nil, nil, nil, nil, nil, nil, nil, nil) == 0, "t2")
}

func testAUAudioUnitV2BridgeAndStatus() {
    let status: AUAudioUnitStatus = 0
    atW6Expect(status == 0, "status alias")
    atW6Expect(AUAudioUnitPreset(coder: NSCoder()) == nil, "preset coder fail-closed")
    var mixer = atW6MixerDescription()
    var before = AudioComponentFindNext(nil, &mixer)
    var countBefore = 0
    while before != nil {
        countBefore += 1
        before = AudioComponentFindNext(before, &mixer)
    }
    AUAudioUnit.registerSubclass(
        AUAudioUnit.self,
        as: mixer,
        name: "LinuxMixer",
        version: 1
    )
    var after = AudioComponentFindNext(nil, &mixer)
    var countAfter = 0
    while after != nil {
        countAfter += 1
        after = AudioComponentFindNext(after, &mixer)
    }
    atW6Expect(countAfter == countBefore, "register does not publish plugins")
    do {
        let bridged = try AUAudioUnitV2Bridge(componentDescription: mixer)
        atW6Expect(bridged.audioUnitName == "MultiChannelMixer", "bridge name")
        atW6Expect(Int(bitPattern: bridged.audioUnit) > 1, "v2 instance")
        atW6Expect(AudioUnitInitialize(bridged.audioUnit) == 0, "v2 init")
        let preset = AUAudioUnitPreset()
        do {
            _ = try bridged.presetState(for: preset)
            fatalError("preset state must fail closed")
        } catch {
            atW6Expect(true, "preset fail-closed")
        }
    } catch {
        fatalError("software v2 bridge must instantiate")
    }
    var remote = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_RemoteIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    do {
        _ = try AUAudioUnitV2Bridge(componentDescription: remote)
        fatalError("remote io bridge must fail closed")
    } catch {
        atW6Expect(true, "remote fail-closed")
    }
    _ = remote
}

func testAudioConverterPrimeInfoOverlay() {
    var info = AudioConverterPrimeInfo()
    atW6Expect(info.leadingFrames == 0 && info.trailingFrames == 0, "empty")
    info = AudioConverterPrimeInfo(leadingFrames: 2, trailingFrames: 3)
    atW6Expect(info.leadingFrames == 2 && info.trailingFrames == 3, "prime")
    atW6Expect(MemoryLayout<AudioConverterPrimeInfo>.size == 8, "8 bytes")
}

func testAudioFilePacketTableInfoOverlay() {
    var info = AudioFilePacketTableInfo()
    atW6Expect(info.mNumberValidFrames == 0 && info.mPrimingFrames == 0, "empty")
    info = AudioFilePacketTableInfo(mNumberValidFrames: 100, mPrimingFrames: 2, mRemainderFrames: 1)
    atW6Expect(info.mNumberValidFrames == 100 && info.mPrimingFrames == 2 && info.mRemainderFrames == 1, "pti")
}

func testAudioFileTypeAndFormatIDOverlay() {
    var pair = AudioFileTypeAndFormatID()
    atW6Expect(pair.mFileType == 0 && pair.mFormatID == 0, "empty")
    pair = AudioFileTypeAndFormatID(mFileType: kAudioFileWAVEType, mFormatID: 0x6C70_636D)
    atW6Expect(pair.mFileType == kAudioFileWAVEType && pair.mFormatID == 0x6C70_636D, "wave pcm")
}

func testAudioQueueBufferStructInit() {
    var bytes: UInt8 = 7
    let buffer = AudioQueueBuffer(
        mAudioDataBytesCapacity: 4,
        mAudioData: &bytes,
        mAudioDataByteSize: 2,
        mUserData: nil,
        mPacketDescriptionCapacity: 0,
        mPacketDescriptions: nil,
        mPacketDescriptionCount: 0
    )
    atW6Expect(buffer.mAudioDataBytesCapacity == 4, "cap")
    atW6Expect(buffer.mAudioDataByteSize == 2, "size")
    atW6Expect(buffer.mAudioData.load(as: UInt8.self) == 7, "payload")
    atW6Expect(buffer.mUserData == nil && buffer.mPacketDescriptionCount == 0, "user pk")
    atW6Expect(buffer.mPacketDescriptionCapacity == 0 && buffer.mPacketDescriptions == nil, "pk desc")
}

func testAudioComponentPlugInInterfaceOverlay() {
    var opened = 0
    var closed = 0
    var looked = 0
    var interface = AudioComponentPlugInInterface()
    atW6Expect(interface.Open == nil && interface.reserved == nil, "empty")
    interface = AudioComponentPlugInInterface(
        Open: { _, _ in
            opened += 1
            return 0
        },
        Close: { _ in
            closed += 1
            return 0
        },
        Lookup: { selector in
            looked += Int(selector)
            return nil
        },
        reserved: nil
    )
    var dummy: UInt8 = 0
    atW6Expect(interface.Open?(UnsafeMutableRawPointer(&dummy), OpaquePointer(bitPattern: 2)!) == 0, "open")
    atW6Expect(interface.Close?(UnsafeMutableRawPointer(&dummy)) == 0, "close")
    atW6Expect(interface.Lookup?(3) == nil && looked == 3, "lookup")
    atW6Expect(opened == 1 && closed == 1, "counts")
    let factory: AudioComponentFactoryFunction = { _ in nil }
    var description = atW6MixerDescription()
    atW6Expect(factory(&description) == nil, "factory nil")
}

func testCABarBeatTimeReservedAndMemberwise() {
    var time = CABarBeatTime()
    atW6Expect(time.subbeat == 0 && time.reserved == 0, "empty")
    time = CABarBeatTime(bar: 2, beat: 3, subbeat: 4, subbeatDivisor: 480, reserved: 9)
    atW6Expect(time.bar == 2 && time.beat == 3, "bar beat")
    atW6Expect(time.subbeat == 4 && time.subbeatDivisor == 480 && time.reserved == 9, "sub reserved")
}

func testMusicDeviceTypealiases() {
    let component: MusicDeviceComponent = OpaquePointer(bitPattern: 3)
    let group: MusicDeviceGroupID = 2
    let instrument: MusicDeviceInstrumentID = 11
    atW6Expect(component == OpaquePointer(bitPattern: 3), "component")
    atW6Expect(group == 2 && instrument == 11, "ids")
    let midi: MusicDeviceMIDIEventProc = { _, _, _, _, _ in kAudioUnitErr_CannotDoInCurrentContext }
    var raw: UInt8 = 0
    atW6Expect(
        midi(UnsafeMutableRawPointer(&raw), 0x90, 60, 100, 0) == kAudioUnitErr_CannotDoInCurrentContext,
        "midi proc"
    )
    let sysEx: MusicDeviceSysExProc = { _, _, _ in kAudioUnitErr_CannotDoInCurrentContext }
    atW6Expect(sysEx(UnsafeMutableRawPointer(&raw), &raw, 1) == kAudioUnitErr_CannotDoInCurrentContext, "sysex")
    let stop: MusicDeviceStopNoteProc = { _, _, _, _ in kAudioUnitErr_CannotDoInCurrentContext }
    atW6Expect(stop(UnsafeMutableRawPointer(&raw), 1, 1, 0) == kAudioUnitErr_CannotDoInCurrentContext, "stop")
    var noteID: NoteInstanceID = 0
    var params = MusicDeviceNoteParams()
    let start: MusicDeviceStartNoteProc = { _, _, _, outID, _, _ in
        outID.pointee = 9
        return kAudioUnitErr_CannotDoInCurrentContext
    }
    atW6Expect(
        start(UnsafeMutableRawPointer(&raw), instrument, group, &noteID, 0, &params)
            == kAudioUnitErr_CannotDoInCurrentContext
            && noteID == 9,
        "start"
    )
    let sched: AudioUnitScheduleParametersProc = { _, _, count in Int32(count) }
    var scheduled = AudioUnitParameterEvent()
    atW6Expect(sched(UnsafeMutableRawPointer(&raw), &scheduled, 3) == 3, "sched proc")
}

func testTranslationOverlays() {
    var bytes = AudioBytePacketTranslation()
    atW6Expect(bytes.mByte == 0 && bytes.mFlags.isEmpty, "empty byte")
    bytes = AudioBytePacketTranslation(
        mByte: 12,
        mPacket: 3,
        mByteOffsetInPacket: 4,
        mFlags: .bytePacketTranslationFlag_IsEstimate
    )
    atW6Expect(bytes.mByte == 12 && bytes.mPacket == 3, "byte packet")
    atW6Expect(bytes.mByteOffsetInPacket == 4 && bytes.mFlags.contains(.bytePacketTranslationFlag_IsEstimate), "off")
    var frames = AudioFramePacketTranslation()
    atW6Expect(frames.mFrame == 0, "empty frame")
    frames = AudioFramePacketTranslation(mFrame: 8, mPacket: 1, mFrameOffsetInPacket: 2)
    atW6Expect(frames.mFrame == 8 && frames.mPacket == 1 && frames.mFrameOffsetInPacket == 2, "frame")
    var independent = AudioIndependentPacketTranslation()
    independent = AudioIndependentPacketTranslation(mPacket: 5, mIndependentlyDecodablePacket: 4)
    atW6Expect(independent.mPacket == 5 && independent.mIndependentlyDecodablePacket == 4, "ind")
    var range = AudioPacketRangeByteCountTranslation()
    range = AudioPacketRangeByteCountTranslation(mPacket: 1, mPacketCount: 8, mByteCountUpperBound: 256)
    atW6Expect(range.mPacketCount == 8 && range.mByteCountUpperBound == 256, "range")
    var roll = AudioPacketRollDistanceTranslation()
    roll = AudioPacketRollDistanceTranslation(mPacket: 2, mRollDistance: -1)
    atW6Expect(roll.mPacket == 2 && roll.mRollDistance == -1, "roll")
    var dep = AudioPacketDependencyInfoTranslation()
    dep = AudioPacketDependencyInfoTranslation(
        mPacket: 9,
        mIsIndependentlyDecodable: 1,
        mNumberPrerollPackets: 2
    )
    atW6Expect(dep.mIsIndependentlyDecodable == 1 && dep.mNumberPrerollPackets == 2, "dep")
}

func testAudioQueueLevelMeterAndChannelAssignment() {
    var meter = AudioQueueLevelMeterState()
    atW6Expect(meter.mAveragePower == 0 && meter.mPeakPower == 0, "empty meter")
    meter = AudioQueueLevelMeterState(mAveragePower: -12, mPeakPower: -3)
    atW6Expect(meter.mAveragePower == -12 && meter.mPeakPower == -3, "meter")
    var assignment = AudioQueueChannelAssignment()
    atW6Expect(assignment.mChannelNumber == 0 && assignment.mDeviceUID == nil, "empty assign")
    let uid = "BuiltInSpeaker" as CFString
    assignment = AudioQueueChannelAssignment(
        mDeviceUID: Unmanaged.passUnretained(uid),
        mChannelNumber: 1
    )
    atW6Expect(assignment.mChannelNumber == 1, "ch")
    atW6Expect(assignment.mDeviceUID?.takeUnretainedValue() as String == "BuiltInSpeaker", "uid")
    var parameter = AudioQueueParameterEvent()
    atW6Expect(parameter.mID == 0 && parameter.mValue == 0, "empty aq param")
    parameter = AudioQueueParameterEvent(mID: kAudioQueueParam_Volume, mValue: 0.5)
    atW6Expect(parameter.mID == kAudioQueueParam_Volume && parameter.mValue == 0.5, "vol event")
}

func testAudioUnitNodeConnectionOverlay() {
    var connection = AudioUnitNodeConnection()
    atW6Expect(connection.sourceNode == 0 && connection.destInputNumber == 0, "empty")
    connection = AudioUnitNodeConnection(
        sourceNode: 1,
        sourceOutputNumber: 0,
        destNode: 2,
        destInputNumber: 3
    )
    atW6Expect(connection.sourceNode == 1 && connection.sourceOutputNumber == 0, "src")
    atW6Expect(connection.destNode == 2 && connection.destInputNumber == 3, "dst")
    let alias: AUNodeConnection = connection
    atW6Expect(alias.destNode == 2, "alias")
}

func testAudioQueueEnqueueWithParametersAndOfflineRender() {
    let format = atW6PCMBlob()
    var queue: AudioQueueRef?
    atW6Expect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, nil, nil, nil, nil, 0, &queue)
        } == 0,
        "new output"
    )
    var source: AudioQueueBufferRef?
    var dest: AudioQueueBufferRef?
    atW6Expect(AudioQueueAllocateBuffer(queue, 8, &source) == 0, "src")
    atW6Expect(AudioQueueAllocateBuffer(queue, 8, &dest) == 0, "dst")
    let samples: [Int16] = [1, 2, 3, 4]
    for (index, sample) in samples.enumerated() {
        source!.pointee.mAudioData.storeBytes(of: sample, toByteOffset: index * 2, as: Int16.self)
    }
    source!.pointee.mAudioDataByteSize = 8
    var parameter = AudioQueueParameterEvent(mID: kAudioQueueParam_Volume, mValue: 0.75)
    atW6Expect(
        withUnsafePointer(to: &parameter) { pointer in
            AudioQueueEnqueueBufferWithParameters(
                queue,
                source,
                0,
                nil,
                1,
                0,
                1,
                pointer,
                nil,
                nil
            )
        } == 0,
        "enqueue params"
    )
    var volume: AudioQueueParameterValue = 0
    atW6Expect(AudioQueueGetParameter(queue, kAudioQueueParam_Volume, &volume) == 0 && volume == 0.75, "vol")
    atW6Expect(AudioQueueOfflineRender(queue, nil, dest, 3) == 0, "offline")
    atW6Expect(dest!.pointee.mAudioDataByteSize == 6, "3 frames")
    var rendered = [Int16](repeating: 0, count: 3)
    for index in 0..<3 {
        rendered[index] = dest!.pointee.mAudioData.load(fromByteOffset: index * 2, as: Int16.self)
    }
    atW6Expect(rendered == [2, 3, 4], "trim start one frame")
    atW6Expect(AudioQueueOfflineRender(queue, nil, dest, 2) == 0, "silence when empty")
    let silence0 = dest!.pointee.mAudioData.load(fromByteOffset: 0, as: Int16.self)
    let silence1 = dest!.pointee.mAudioData.load(fromByteOffset: 2, as: Int16.self)
    atW6Expect(silence0 == 0 && silence1 == 0, "zeros")
    atW6Expect(AudioQueueDispose(queue, true) == 0, "dispose")
}

func testAURenderEventHeaderAndUnion() {
    var header = AURenderEventHeader()
    atW6Expect(header.next == nil && header.eventType == .parameter && header.reserved == 0, "empty header")
    header = AURenderEventHeader(
        next: nil,
        eventSampleTime: 12,
        eventType: .midiSysEx,
        reserved: 3
    )
    atW6Expect(header.eventSampleTime == 12 && header.eventType == .midiSysEx && header.reserved == 3, "header")
    var midi = AUMIDIEvent(
        next: nil,
        eventSampleTime: 4,
        eventType: .MIDI,
        reserved: 0,
        length: 3,
        cable: 0,
        data: (0x80, 60, 0)
    )
    var render = AURenderEvent(MIDI: midi)
    atW6Expect(render.MIDI.data.0 == 0x80 && render.head.eventType == .MIDI, "midi union")
    var parameter = AUParameterEvent(
        next: nil,
        eventSampleTime: 8,
        eventType: .parameter,
        reserved: (0, 0, 0),
        rampDurationSampleFrames: 0,
        parameterAddress: 1,
        value: 0.5
    )
    render = AURenderEvent(parameter: parameter)
    atW6Expect(render.parameter.value == 0.5 && render.head.eventSampleTime == 8, "param union")
    render = AURenderEvent()
    atW6Expect(render.head.eventType == .parameter && render.MIDI.length == 0, "empty union")
    _ = midi
}

func testExtendedNoteOnEventOverlay() {
    var event = ExtendedNoteOnEvent()
    atW6Expect(event.instrumentID == 0 && event.duration == 0, "empty")
    event = ExtendedNoteOnEvent(
        instrumentID: 12,
        groupID: 3,
        duration: 0.5,
        extendedParams: MusicDeviceNoteParams(argCount: 2, mPitch: 64, mVelocity: 90, mControls: 0)
    )
    atW6Expect(event.instrumentID == 12 && event.groupID == 3, "ids")
    atW6Expect(event.duration == 0.5 && event.extendedParams.mPitch == 64, "params")
}

func testParameterNameAndStringConversionOverlays() {
    var name = AudioUnitParameterNameInfo()
    atW6Expect(name.inID == 0 && name.outName == nil, "empty name")
    let label = "Gain" as CFString
    name = AudioUnitParameterNameInfo(
        inID: kMultiChannelMixerParam_Volume,
        inDesiredLength: 4,
        outName: Unmanaged.passUnretained(label)
    )
    atW6Expect(name.inID == kMultiChannelMixerParam_Volume && name.inDesiredLength == 4, "id len")
    atW6Expect(name.outName?.takeUnretainedValue() as String == "Gain", "out name")
    let alias: AudioUnitParameterIDName = name
    atW6Expect(alias.inDesiredLength == 4, "alias")
    var value: AudioUnitParameterValue = 0.5
    var fromValue = AudioUnitParameterStringFromValue()
    atW6Expect(fromValue.inParamID == 0 && fromValue.outString == nil, "empty sfv")
    fromValue = AudioUnitParameterStringFromValue(inParamID: 1, inValue: &value, outString: nil)
    atW6Expect(fromValue.inParamID == 1 && fromValue.inValue?.pointee == 0.5, "sfv")
    var fromString = AudioUnitParameterValueFromString()
    atW6Expect(fromString.outValue == 0, "empty vfs")
    fromString = AudioUnitParameterValueFromString(
        inParamID: 1,
        inString: Unmanaged.passUnretained(label),
        outValue: 0.25
    )
    atW6Expect(fromString.outValue == 0.25 && fromString.inString != nil, "vfs")
    var history = AudioUnitParameterHistoryInfo()
    history = AudioUnitParameterHistoryInfo(updatesPerSecond: 30, historyDurationInSeconds: 2)
    atW6Expect(history.updatesPerSecond == 30 && history.historyDurationInSeconds == 2, "hist")
    var bin = AudioUnitFrequencyResponseBin()
    bin = AudioUnitFrequencyResponseBin(mFrequency: 1000, mMagnitude: -3)
    atW6Expect(bin.mFrequency == 1000 && bin.mMagnitude == -3, "bin")
}

func testAUInputSamplesInOutputCallbackStructOverlay() {
    var hits = 0
    let callback: AUInputSamplesInOutputCallback = { _, _, inputSample, outputSample in
        if inputSample == 1 && outputSample == 2 {
            hits += 1
        }
    }
    var info = AUInputSamplesInOutputCallbackStruct()
    atW6Expect(info.userData == nil && info.inputToOutputCallback == nil, "empty")
    var token: UInt8 = 0
    info = AUInputSamplesInOutputCallbackStruct(inputToOutputCallback: callback, userData: &token)
    atW6Expect(info.userData == UnsafeMutableRawPointer(&token), "user")
    info.inputToOutputCallback?(info.userData, nil, 1, 2)
    atW6Expect(hits == 1, "callback")
}

func testAudioOutputUnitStartAtTimeAndMIDICallbacks() {
    var params = AudioOutputUnitStartAtTimeParams()
    atW6Expect(params.mFlags == 0 && params.mTimestamp.0 == 0, "empty")
    params = AudioOutputUnitStartAtTimeParams(mTimestamp: (4, 0, 0, 0, 0, 0, 0, 0), mFlags: 1)
    atW6Expect(params.mTimestamp.0 == 4 && params.mFlags == 1, "start at")
    var midiHits = 0
    var sysExHits = 0
    var callbacks = AudioOutputUnitMIDICallbacks()
    atW6Expect(callbacks.userData == nil && callbacks.MIDIEventProc == nil, "empty midi")
    callbacks = AudioOutputUnitMIDICallbacks(
        userData: nil,
        MIDIEventProc: { _, status, data1, _, _ in
            if status == 0x90 && data1 == 60 { midiHits += 1 }
        },
        MIDISysExProc: { _, _, length in
            if length == 3 { sysExHits += 1 }
        }
    )
    callbacks.MIDIEventProc?(nil, 0x90, 60, 100, 0)
    var sysex: [UInt8] = [0xF0, 0x00, 0xF7]
    sysex.withUnsafeBufferPointer { buffer in
        callbacks.MIDISysExProc?(nil, buffer.baseAddress!, 3)
    }
    atW6Expect(midiHits == 1 && sysExHits == 1, "midi callbacks")
    var duck = AUVoiceIOOtherAudioDuckingConfiguration()
    atW6Expect(duck.mEnableAdvancedDucking == 0 && duck.mDuckingLevel == .default, "empty duck")
    duck = AUVoiceIOOtherAudioDuckingConfiguration(mEnableAdvancedDucking: 1, mDuckingLevel: .max)
    atW6Expect(duck.mEnableAdvancedDucking == 1 && duck.mDuckingLevel == .max, "duck")
}

func testExtAudioFilePacketTableInfoOverrideAlias() {
    let overrideValue: ExtAudioFilePacketTableInfoOverride = kExtAudioFilePacketTableInfoOverride_UseFileValue
    atW6Expect(overrideValue == -1, "use file")
}
