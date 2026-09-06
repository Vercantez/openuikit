#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atW5Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW5PCMBlob(
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

#if canImport(CoreFoundation)
private func atW5FileURL(_ path: String) -> CFURL {
    path.withCString { cstr in
        CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
            path.utf8.count,
            false
        )!
    }
}
#endif

private var atW5ListenerHits = 0
private func atW5PropertyListener(
    _ userData: UnsafeMutableRawPointer?,
    _ unit: AudioUnit?,
    _ id: AudioUnitPropertyID,
    _ scope: AudioUnitScope,
    _ element: AudioUnitElement
) {
    _ = userData
    _ = unit
    _ = scope
    _ = element
    if id == kAudioUnitProperty_MaximumFramesPerSlice {
        atW5ListenerHits += 1
    }
}

func testWave5RemainingAUParameterIDs() {
    atW5Expect(kAUSamplerParam_Gain == 900, "samp gain")
    atW5Expect(kAUSamplerParam_CoarseTuning == 901, "coarse")
    atW5Expect(kAUSamplerParam_FineTuning == 902, "fine")
    atW5Expect(kAUSamplerParam_Pan == 903, "samp pan")
    atW5Expect(kBandpassParam_CenterFrequency == 0 && kBandpassParam_Bandwidth == 1, "bandpass")
    atW5Expect(kHipassParam_CutoffFrequency == 0 && kHipassParam_Resonance == 1, "hipass")
    atW5Expect(kLowPassParam_CutoffFrequency == 0 && kLowPassParam_Resonance == 1, "lowpass")
    atW5Expect(kHighShelfParam_CutOffFrequency == 0 && kHighShelfParam_Gain == 1, "highshelf")
    atW5Expect(kAULowShelfParam_CutoffFrequency == 0 && kAULowShelfParam_Gain == 1, "lowshelf")
    atW5Expect(kParametricEQParam_CenterFreq == 0 && kParametricEQParam_Q == 1, "peq")
    atW5Expect(kParametricEQParam_Gain == 2, "peq gain")
    atW5Expect(kLimiterParam_AttackTime == 0 && kLimiterParam_DecayTime == 1, "lim")
    atW5Expect(kLimiterParam_PreGain == 2, "lim gain")
    atW5Expect(kDynamicsProcessorParam_Threshold == 0, "dyn 0")
    atW5Expect(kDynamicsProcessorParam_HeadRoom == 1, "dyn 1")
    atW5Expect(kDynamicsProcessorParam_ExpansionRatio == 2, "dyn 2")
    atW5Expect(kDynamicsProcessorParam_ExpansionThreshold == 3, "dyn 3")
    atW5Expect(kDynamicsProcessorParam_AttackTime == 4, "dyn 4")
    atW5Expect(kDynamicsProcessorParam_ReleaseTime == 5, "dyn 5")
    atW5Expect(kDynamicsProcessorParam_OverallGain == 6, "dyn 6")
    atW5Expect(kDynamicsProcessorParam_CompressionAmount == 1000, "dyn 1000")
    atW5Expect(kDynamicsProcessorParam_InputAmplitude == 2000, "dyn 2000")
    atW5Expect(kDynamicsProcessorParam_OutputAmplitude == 3000, "dyn 3000")
    atW5Expect(kDelayParam_WetDryMix == 0 && kDelayParam_DelayTime == 1, "delay")
    atW5Expect(kDelayParam_Feedback == 2 && kDelayParam_LopassCutoff == 3, "delay 2")
    atW5Expect(kReverb2Param_DryWetMix == 0 && kReverb2Param_Gain == 1, "rvb2")
    atW5Expect(kReverb2Param_MinDelayTime == 2 && kReverb2Param_MaxDelayTime == 3, "rvb2 delay")
    atW5Expect(kReverb2Param_DecayTimeAt0Hz == 4 && kReverb2Param_DecayTimeAtNyquist == 5, "rvb2 decay")
    atW5Expect(kReverb2Param_RandomizeReflections == 6, "rvb2 rand")
    atW5Expect(kRandomParam_BoundA == 0 && kRandomParam_BoundB == 1 && kRandomParam_Curve == 2, "rand")
    atW5Expect(kRoundTripAACParam_Format == 0, "raac")
    atW5Expect(kRoundTripAACParam_EncodingStrategy == 1 && kRoundTripAACParam_RateOrQuality == 2, "raac 2")
    atW5Expect(kReverbParam_FilterFrequency == 14, "rev f")
    atW5Expect(kReverbParam_FilterBandwidth == 15 && kReverbParam_FilterGain == 16, "rev bg")
    atW5Expect(kReverbParam_FilterType == 17 && kReverbParam_FilterEnable == 18, "rev te")
    atW5Expect(kAUAudioMixParameter_Style == 0 && kAUAudioMixParameter_RemixAmount == 1, "mix p")
    atW5Expect(k3DMixerParam_PreAveragePower == 1000, "3d pre avg")
    atW5Expect(k3DMixerParam_PrePeakHoldLevel == 2000, "3d pre peak")
    atW5Expect(k3DMixerParam_PostAveragePower == 3000, "3d post avg")
    atW5Expect(k3DMixerParam_PostPeakHoldLevel == 4000, "3d post peak")
    atW5Expect(kSampleDelayParam_DelayFrames == 0, "sdly")
}

func testWave5RemainingPropertyAndPolicyIDs() {
    atW5Expect(kAUAudioMixProperty_SpatialAudioMixMetadata == 5000, "mix meta")
    atW5Expect(kAUAudioMixProperty_EnableSpatialization == 5001, "mix spat")
    atW5Expect(kAUVoiceIOProperty_BypassVoiceProcessing == 2100, "vpio bypass")
    atW5Expect(kAUVoiceIOProperty_VoiceProcessingEnableAGC == 2101, "vpio agc")
    atW5Expect(kAUVoiceIOProperty_MuteOutput == 2104, "vpio mute")
    atW5Expect(kAUVoiceIOProperty_MutedSpeechActivityEventListener == 2106, "vpio speech")
    atW5Expect(kAUSamplerProperty_LoadPresetFromBank == 4100, "bank")
    atW5Expect(kAUSamplerProperty_BankAndPreset == 4100, "alias bank")
    atW5Expect(kAUSamplerProperty_LoadAudioFiles == 4101, "files")
    atW5Expect(kAUSamplerProperty_LoadInstrument == 4102, "inst")
    atW5Expect(kAUMIDISynthProperty_EnablePreload == 4119, "preload")
    atW5Expect(kInstrumentType_DLSPreset == 1 && kInstrumentType_SF2Preset == 1, "dls")
    atW5Expect(kInstrumentType_AUPreset == 2 && kInstrumentType_Audiofile == 3, "types")
    atW5Expect(kInstrumentType_EXS24 == 4, "exs")
    atW5Expect(kAUSampler_DefaultPercussionBankMSB == 0x78, "perc")
    atW5Expect(kAUSampler_DefaultMelodicBankMSB == 0x79, "mel")
    atW5Expect(kAUSampler_DefaultBankLSB == 0, "lsb")
    atW5Expect(kRenderQuality_Min == 0 && kRenderQuality_Low == 0x20, "rq low")
    atW5Expect(kRenderQuality_Medium == 0x40 && kRenderQuality_High == 0x60, "rq mid")
    atW5Expect(kRenderQuality_Max == 0x7F, "rq max")
    atW5Expect(kAudioQueueHardwareCodecPolicy_Default == 0, "hw 0")
    atW5Expect(kAudioQueueHardwareCodecPolicy_UseSoftwareOnly == 1, "hw 1")
    atW5Expect(kAudioQueueHardwareCodecPolicy_UseHardwareOnly == 2, "hw 2")
    atW5Expect(kAudioQueueHardwareCodecPolicy_PreferSoftware == 3, "hw 3")
    atW5Expect(kAudioQueueHardwareCodecPolicy_PreferHardware == 4, "hw 4")
    atW5Expect(kConverterPrimeMethod_Pre == 0 && kConverterPrimeMethod_Normal == 1, "prime")
    atW5Expect(kConverterPrimeMethod_None == 2, "prime none")
    atW5Expect(kHintBasic == 0 && kHintAdvanced == 1 && kHintHidden == 2, "hint")
    atW5Expect(kAUParameterListener_AnyParameter == 0xFFFF_FFFF, "any param")
    atW5Expect(kNumberOfResponseFrequencies == 1024, "nfreq")
    atW5Expect(kAudioDecoderComponentType == 0x6164_6563, "adec")
    atW5Expect(kAudioEncoderComponentType == 0x6165_6E63, "aenc")
    atW5Expect(kMusicTimeStamp_EndOfTrack == Double.greatestFiniteMagnitude, "eot")
}

func testWave5StringKeysAndMarkerBytes() {
    atW5Expect(kAUPresetVersionKey == "version", "ver")
    atW5Expect(kAUPresetTypeKey == "type" && kAUPresetSubtypeKey == "subtype", "type")
    atW5Expect(kAUPresetManufacturerKey == "manufacturer", "mfr")
    atW5Expect(kAUPresetDataKey == "data" && kAUPresetNameKey == "name", "data")
    atW5Expect(kAUPresetRenderQualityKey == "render-quality", "rq")
    atW5Expect(kAUPresetCPULoadKey == "cpu-load", "cpu")
    atW5Expect(kAUPresetElementNameKey == "element-name", "el")
    atW5Expect(kAUPresetExternalFileRefs == "file-references", "refs")
    atW5Expect(kAUPresetPartKey == "part", "part")
    atW5Expect(kAudioUnitConfigurationInfo_HasCustomView == "HasCustomView", "cv")
    atW5Expect(kAudioUnitConfigurationInfo_ChannelConfigurations == "ChannelConfigurations", "cc")
    atW5Expect(kAudioUnitConfigurationInfo_InitialInputs == "InitialInputs", "in")
    atW5Expect(kAudioUnitConfigurationInfo_InitialOutputs == "InitialOutputs", "out")
    atW5Expect(kAudioUnitConfigurationInfo_IconURL == "IconURL", "icon")
    atW5Expect(kAudioUnitConfigurationInfo_BusCountWritable == "BusCountWritable", "bus")
    atW5Expect(
        kAudioUnitConfigurationInfo_SupportedChannelLayoutTags == "SupportedChannelLayoutTags",
        "tags"
    )
    atW5Expect(kAudioUnitConfigurationInfo_MIDIProtocol == "MIDIProtocol", "midi")
    atW5Expect(kAudioUnitConfigurationInfo_MigrateFromPlugin == "MigrateFromPlugin", "mig")
    atW5Expect(kAudioSettings_TopLevelKey == "name" && kAudioSettings_Version == "version", "set top")
    atW5Expect(kAudioSettings_Parameters == "parameters" && kAudioSettings_SettingKey == "key", "set p")
    atW5Expect(kAudioSettings_SettingName == "name" && kAudioSettings_ValueType == "value type", "set n")
    atW5Expect(kAudioSettings_AvailableValues == "available values", "avail")
    atW5Expect(kAudioSettings_LimitedValues == "limited values", "lim")
    atW5Expect(kAudioSettings_CurrentValue == "current value", "cur")
    atW5Expect(kAudioSettings_Hint == "hint" && kAudioSettings_Unit == "unit", "hint unit")
    atW5Expect(kAudioSettings_Summary == "summary", "sum")
    atW5Expect(kAudioSession_AudioRouteChangeKey_OldRoute == "OldRoute", "old")
    atW5Expect(kAudioSession_AudioRouteChangeKey_Reason == "Reason", "reason")
    atW5Expect(NumAudioFileMarkersToNumBytes(0) >= 8, "0 markers header")
    let two = NumAudioFileMarkersToNumBytes(2)
    atW5Expect(NumBytesToNumAudioFileMarkers(two) == 2, "round trip markers")
    atW5Expect(NumBytesToNumAudioFileMarkers(0) == 0, "undersize")
}

func testWave5OverlayStructLayouts() {
    var channels = AUChannelInfo(inChannels: 2, outChannels: 2)
    atW5Expect(channels.inChannels == 2 && channels.outChannels == 2, "ch")
    channels = AUChannelInfo()
    atW5Expect(channels.inChannels == 0, "ch empty")
    atW5Expect(MemoryLayout<AUChannelInfo>.size == 4, "ch size")
    var dep = AUDependentParameter(mScope: 1, mParameterID: 7)
    atW5Expect(dep.mScope == 1 && dep.mParameterID == 7, "dep")
    dep = AUDependentParameter()
    atW5Expect(dep.mParameterID == 0, "dep empty")
    var unitParam = AudioUnitParameter(mAudioUnit: nil, mParameterID: 3, mScope: 1, mElement: 2)
    atW5Expect(unitParam.mParameterID == 3 && unitParam.mElement == 2, "aup")
    unitParam = AudioUnitParameter()
    atW5Expect(unitParam.mAudioUnit == nil, "aup empty")
    var preset = AUPreset(presetNumber: 4, presetName: nil)
    atW5Expect(preset.presetNumber == 4, "preset")
    preset = AUPreset()
    atW5Expect(preset.presetNumber == 0, "preset empty")
    var pe = ParameterEvent(parameterID: 1, scope: 0, element: 0, value: 0.5)
    atW5Expect(pe.value == 0.5, "pe")
    pe = ParameterEvent()
    atW5Expect(pe.parameterID == 0, "pe empty")
    var raw = MIDIRawData(length: 1, data: 0x90)
    atW5Expect(raw.length == 1 && raw.data == 0x90, "raw")
    raw = MIDIRawData()
    atW5Expect(raw.length == 0, "raw empty")
    var meta = MIDIMetaEvent(
        metaEventType: 0x51,
        unused1: 0,
        unused2: 0,
        unused3: 0,
        dataLength: 1,
        data: 0x60
    )
    atW5Expect(meta.metaEventType == 0x51 && meta.data == 0x60, "meta")
    meta = MIDIMetaEvent()
    atW5Expect(meta.dataLength == 0, "meta empty")
    var autoEvent = AUParameterAutomationEvent(
        hostTime: 8,
        address: 2,
        value: 0.25,
        eventType: .touch
    )
    atW5Expect(autoEvent.eventType == .touch && autoEvent.address == 2, "auto")
    atW5Expect(autoEvent.reserved == 0, "auto reserved")
    autoEvent = AUParameterAutomationEvent()
    atW5Expect(autoEvent.hostTime == 0, "auto empty")
    var recorded = AURecordedParameterEvent(hostTime: 1, address: 9, value: 0.1)
    atW5Expect(recorded.address == 9, "rec")
    recorded = AURecordedParameterEvent()
    atW5Expect(recorded.value == 0, "rec empty")
    var smpte = AudioFile_SMPTE_Time(mHours: 1, mMinutes: 2, mSeconds: 3, mFrames: 4, mSubFrameSampleOffset: 5)
    atW5Expect(smpte.mHours == 1 && smpte.mFrames == 4, "smpte")
    smpte = AudioFile_SMPTE_Time()
    atW5Expect(smpte.mMinutes == 0, "smpte empty")
    atW5Expect(MemoryLayout<AudioFile_SMPTE_Time>.size == 8, "smpte size")
    var marker = AudioFileMarker(
        mFramePosition: 12,
        mName: nil,
        mMarkerID: 3,
        mSMPTETime: smpte,
        mType: 0,
        mReserved: 0,
        mChannel: 1
    )
    atW5Expect(marker.mFramePosition == 12 && marker.mChannel == 1, "marker")
    marker = AudioFileMarker()
    atW5Expect(marker.mMarkerID == 0, "marker empty")
    var list = AudioFileMarkerList(mSMPTE_TimeType: 1, mNumberMarkers: 1, mMarkers: marker)
    atW5Expect(list.mNumberMarkers == 1, "list")
    list = AudioFileMarkerList()
    atW5Expect(list.mSMPTE_TimeType == 0, "list empty")
    var inst = AUSamplerInstrumentData(
        fileURL: nil,
        instrumentType: kInstrumentType_AUPreset,
        bankMSB: kAUSampler_DefaultMelodicBankMSB,
        bankLSB: kAUSampler_DefaultBankLSB,
        presetID: 12
    )
    atW5Expect(inst.presetID == 12 && inst.instrumentType == 2, "inst")
    inst = AUSamplerInstrumentData()
    atW5Expect(inst.bankMSB == kAUSampler_DefaultMelodicBankMSB, "inst empty")
    var bank = AUSamplerBankPresetData(
        bankURL: nil,
        bankMSB: kAUSampler_DefaultPercussionBankMSB,
        bankLSB: 0,
        presetID: 1,
        reserved: 0
    )
    atW5Expect(bank.bankMSB == 0x78, "bank")
    bank = AUSamplerBankPresetData()
    atW5Expect(bank.reserved == 0, "bank empty")
}

func testWave5AUParameterTree() {
    let parameter = AUParameterTree.createParameter(
        withIdentifier: "gain",
        name: "Gain",
        address: 7,
        min: 0,
        max: 2,
        unit: .linearGain,
        unitName: "gain",
        flags: .flag_CanRamp,
        valueStrings: ["low", "high"],
        dependentParameters: [1]
    )
    atW5Expect(parameter.identifier == "gain" && parameter.displayName == "Gain", "id")
    atW5Expect(parameter.address == 7 && parameter.maxValue == 2, "addr")
    atW5Expect(parameter.unit == .linearGain && parameter.unitName == "gain", "unit")
    atW5Expect(parameter.flags.contains(.flag_CanRamp), "flags")
    atW5Expect(parameter.valueStrings?.count == 2, "strings")
    atW5Expect(parameter.dependentParameters?.first?.intValue == 1, "dep")
    atW5Expect(parameter.displayName(withLength: 2) == "Ga", "trunc")
    atW5Expect(parameter.keyPath == "gain", "path")
    parameter.setValue(1.5, originator: nil)
    atW5Expect(parameter.value == 1.5, "set")
    parameter.setValue(9, originator: nil, atHostTime: 1)
    atW5Expect(parameter.value == 2, "clamp")
    parameter.setValue(0.25, originator: nil, atHostTime: 2, eventType: .touch)
    atW5Expect(parameter.value == 0.25, "event")
    var encoded: AUValue = 0.5
    atW5Expect(parameter.string(fromValue: &encoded).contains("0.5"), "string")
    atW5Expect(parameter.value(from: "1.25") == 1.25, "from string")
    let token = parameter.token(byAddingParameterObserver: { _, _ in })
    let autoToken = parameter.token(byAddingParameterAutomationObserver: { _, _ in })
    let recToken = parameter.token(byAddingParameterRecordingObserver: { _, _ in })
    atW5Expect(token != autoToken && recToken != token, "tokens")
    parameter.removeParameterObserver(token)
    parameter.removeParameterObserver(autoToken)
    parameter.removeParameterObserver(recToken)
    _ = parameter.implementorValueProvider(parameter)
    parameter.implementorValueObserver(parameter, 0)
    let group = AUParameterTree.createGroup(withIdentifier: "g", name: "Group", children: [parameter])
    atW5Expect(group.children.count == 1 && group.allParameters.count == 1, "group")
    let template = AUParameterTree.createGroupTemplate([parameter])
    let copied = AUParameterTree.createGroup(fromTemplate: template, identifier: "c", name: "Copy", addressOffset: 10)
    atW5Expect(copied.identifier == "c" && copied.children.count == 1, "template")
    let tree = AUParameterTree.createTree(withChildren: [group])
    atW5Expect(tree.parameter(withAddress: 7) === parameter, "lookup addr")
    atW5Expect(tree.parameter(withID: 7, scope: 0, element: 0) === parameter, "lookup id")
}

func testWave5MusicSequenceReverseAndMeta() {
    var sequence: MusicSequence?
    atW5Expect(NewMusicSequence(&sequence) == 0, "seq")
    var track: MusicTrack?
    atW5Expect(MusicSequenceNewTrack(sequence, &track) == 0, "track")
    var note = MIDINoteMessage(channel: 0, note: 60, velocity: 80, releaseVelocity: 0, duration: 0.5)
    atW5Expect(MusicTrackNewMIDINoteEvent(track, 0, &note) == 0, "n0")
    note.note = 64
    atW5Expect(MusicTrackNewMIDINoteEvent(track, 4, &note) == 0, "n4")
    var meta = MIDIMetaEvent(metaEventType: 0x51, unused1: 0, unused2: 0, unused3: 0, dataLength: 1, data: 0x40)
    atW5Expect(MusicTrackNewMetaEvent(track, 1, &meta) == 0, "meta")
    var raw = MIDIRawData(length: 1, data: 0x90)
    atW5Expect(MusicTrackNewMIDIRawDataEvent(track, 2, &raw) == 0, "raw")
    var param = ParameterEvent(parameterID: kMultiChannelMixerParam_Volume, scope: 0, element: 0, value: 0.5)
    atW5Expect(MusicTrackNewParameterEvent(track, 3, &param) == 0, "param")
    atW5Expect(MusicSequenceReverse(sequence) == 0, "reverse")
    var iterator: MusicEventIterator?
    atW5Expect(NewMusicEventIterator(track, &iterator) == 0, "iter")
    var time: MusicTimeStamp = -1
    var type: MusicEventType = 0
    var data: UnsafeRawPointer?
    var size: UInt32 = 0
    atW5Expect(MusicEventIteratorGetEventInfo(iterator, &time, &type, &data, &size) == 0, "first")
    atW5Expect(abs(time - 0) < 0.0001, "reversed 4->0")
    atW5Expect(type == kMusicEventType_MIDINoteMessage, "still note")
    var newNote = MIDINoteMessage(channel: 1, note: 70, velocity: 40, releaseVelocity: 0, duration: 0.25)
    atW5Expect(MusicEventIteratorSetEventInfo(iterator, kMusicEventType_MIDINoteMessage, &newNote) == 0, "set info")
    atW5Expect(MusicEventIteratorGetEventInfo(iterator, &time, &type, &data, &size) == 0, "reread")
    let loaded = data!.assumingMemoryBound(to: MIDINoteMessage.self).pointee
    atW5Expect(loaded.note == 70 && loaded.channel == 1, "updated payload")
    atW5Expect(DisposeMusicEventIterator(iterator) == 0, "disp iter")
    atW5Expect(DisposeMusicSequence(sequence) == 0, "disp seq")
}

func testWave5AudioUnitProcessAndListeners() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var mixer: AudioComponentInstance?
    atW5Expect(AudioComponentInstanceNew(component, &mixer) == 0, "mixer")
    atW5ListenerHits = 0
    atW5Expect(
        AudioUnitAddPropertyListener(mixer, kAudioUnitProperty_MaximumFramesPerSlice, atW5PropertyListener, nil) == 0,
        "add listener"
    )
    var frames: UInt32 = 64
    atW5Expect(
        AudioUnitSetProperty(
            mixer,
            kAudioUnitProperty_MaximumFramesPerSlice,
            kAudioUnitScope_Global,
            0,
            &frames,
            4
        ) == 0,
        "set frames"
    )
    atW5Expect(atW5ListenerHits == 1, "listener fired")
    atW5Expect(
        AudioUnitRemovePropertyListenerWithUserData(
            mixer,
            kAudioUnitProperty_MaximumFramesPerSlice,
            atW5PropertyListener,
            nil
        ) == 0,
        "remove"
    )
    frames = 32
    atW5Expect(
        AudioUnitSetProperty(
            mixer,
            kAudioUnitProperty_MaximumFramesPerSlice,
            kAudioUnitScope_Global,
            0,
            &frames,
            4
        ) == 0,
        "set again"
    )
    atW5Expect(atW5ListenerHits == 1, "removed")
    let format = atW5PCMBlob(bits: 32, flags: 9)
    atW5Expect(
        format.withUnsafeBytes { raw in
            AudioUnitSetProperty(
                mixer,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Output,
                0,
                raw.baseAddress,
                40
            )
        } == 0,
        "format"
    )
    atW5Expect(AudioUnitInitialize(mixer) == 0, "init")
    var storage = [Float](repeating: 1, count: 8)
    var abl = [UInt8](repeating: 0, count: 24)
    let status: Int32 = storage.withUnsafeMutableBytes { samples in
        abl.withUnsafeMutableBytes { raw in
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt(bitPattern: samples.baseAddress!), toByteOffset: 16, as: UInt.self)
            raw.baseAddress!.storeBytes(of: UInt32(32), toByteOffset: 12, as: UInt32.self)
            var flags = AudioUnitRenderActionFlags()
            var stamp = [UInt8](repeating: 0, count: 64)
            return stamp.withUnsafeMutableBytes { ts in
                AudioUnitProcess(mixer, &flags, ts.baseAddress, 8, raw.baseAddress)
            }
        }
    }
    atW5Expect(status == 0, "process")
    atW5Expect(storage.allSatisfy { $0 == 0 }, "silence")
    var output = abl
    atW5Expect(
        output.withUnsafeMutableBytes { raw in
            var ptr: UnsafeMutableRawPointer? = raw.baseAddress
            return withUnsafePointer(to: &ptr) { pointer in
                AudioUnitProcessMultiple(mixer, nil, nil, 8, 0, nil, 1, pointer)
            }
        } == 0,
        "process multiple"
    )
    _ = AudioComponentInstanceDispose(mixer)
}

func testWave5AudioFileUserDataAndFailClosed() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-w5-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atW5PCMBlob()
    var file: AudioFileID?
    atW5Expect(
        format.withUnsafeBytes { raw in
            AudioFileCreateWithURL(atW5FileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
        } == 0,
        "create"
    )
    var payload: [UInt8] = [1, 2, 3, 4]
    atW5Expect(
        payload.withUnsafeBytes { raw in
            AudioFileSetUserData(file, 0x616E_6E6F, 0, 4, raw.baseAddress)
        } == 0,
        "set"
    )
    var count: UInt32 = 0
    atW5Expect(AudioFileCountUserData(file, 0x616E_6E6F, &count) == 0 && count == 1, "count")
    var size: UInt32 = 0
    atW5Expect(AudioFileGetUserDataSize(file, 0x616E_6E6F, 0, &size) == 0 && size == 4, "size")
    var size64: UInt64 = 0
    atW5Expect(AudioFileGetUserDataSize64(file, 0x616E_6E6F, 0, &size64) == 0 && size64 == 4, "size64")
    var out = [UInt8](repeating: 0, count: 4)
    size = 4
    atW5Expect(
        out.withUnsafeMutableBytes { raw in
            AudioFileGetUserData(file, 0x616E_6E6F, 0, &size, raw.baseAddress)
        } == 0 && out == payload,
        "get"
    )
    var slice = [UInt8](repeating: 0, count: 2)
    size = 2
    atW5Expect(
        slice.withUnsafeMutableBytes { raw in
            AudioFileGetUserDataAtOffset(file, 0x616E_6E6F, 0, 2, &size, raw.baseAddress)
        } == 0 && slice == [3, 4],
        "offset"
    )
    atW5Expect(AudioFileRemoveUserData(file, 0x616E_6E6F, 0) == 0, "remove")
    atW5Expect(AudioFileCountUserData(file, 0x616E_6E6F, &count) == 0 && count == 0, "empty")
    atW5Expect(AudioFileClose(file) == 0, "close")
    atW5Expect(AudioOutputUnitPublish(nil, nil, 0, nil) == kAudioComponentErr_NotPermitted, "publish")
    atW5Expect(AudioComponentCopyIcon(nil, nil) == kAudioComponentErr_NotPermitted, "icon")
    atW5Expect(AudioOutputUnitGetHostIcon(nil, 32) == nil, "host icon")
#endif
    atW5Expect(AudioQueueDeviceGetCurrentTime(nil, nil) == kAudioQueueErr_InvalidDevice, "aq now")
    atW5Expect(AudioQueueDeviceTranslateTime(nil, nil, nil) == kAudioQueueErr_InvalidDevice, "aq xlat")
    atW5Expect(AudioQueueDeviceGetNearestStartTime(nil, nil, 0) == kAudioQueueErr_InvalidDevice, "aq near")
    atW5Expect(MusicDeviceMIDIEventList(nil, 0, nil) == kAudioUnitErr_InvalidElement, "midi list")
    var converter: AudioConverterRef?
    let src = atW5PCMBlob()
    let dst = atW5PCMBlob()
    atW5Expect(
        src.withUnsafeBytes { a in
            dst.withUnsafeBytes { b in
                AudioConverterNew(a.baseAddress, b.baseAddress, &converter)
            }
        } == 0,
        "converter"
    )
    atW5Expect(AudioConverterPrepare(converter) == 0, "prepare")
    atW5Expect(AudioConverterDispose(converter) == 0, "dispose conv")
}
