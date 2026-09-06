#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atW4Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW4ProbeOptionSet<T: OptionSet>(_ a: T, _ b: T) where T.Element == T {
    atW4Expect(a != b, "distinct members")
    var set = T()
    atW4Expect(set.isEmpty, "empty init")
    set.insert(a)
    atW4Expect(set.contains(a), "insert contains")
    atW4Expect(!set.contains(b), "insert misses other")
    let inserted = set.insert(b)
    atW4Expect(inserted.inserted, "insert new")
    atW4Expect(set.contains(b), "contains after insert")
    let again = set.insert(b)
    atW4Expect(!again.inserted, "insert duplicate")
    _ = set.update(with: a)
    let removed = set.remove(b)
    atW4Expect(removed != nil, "remove")
    set.formUnion(b)
    atW4Expect(set.contains(a) && set.contains(b), "formUnion")
    set.formIntersection(a)
    atW4Expect(set.contains(a) && !set.contains(b), "formIntersection")
    set.formSymmetricDifference(a.union(b))
    atW4Expect(set.contains(b) && !set.contains(a), "formSymmetricDifference")
    var copy = a.union(b)
    copy.subtract(a)
    atW4Expect(!copy.contains(a) && copy.contains(b), "subtract")
    let combined = a.union(b)
    atW4Expect(a.isSubset(of: combined), "isSubset")
    atW4Expect(combined.isSuperset(of: a), "isSuperset")
    atW4Expect(a.isDisjoint(with: b), "isDisjoint")
    atW4Expect(a.isStrictSubset(of: combined), "isStrictSubset")
    atW4Expect(combined.isStrictSuperset(of: a), "isStrictSuperset")
    atW4Expect(combined.contains(a) && combined.contains(b), "union")
    atW4Expect(a.intersection(combined).contains(a), "intersection")
    atW4Expect(a.symmetricDifference(b).contains(a) && a.symmetricDifference(b).contains(b), "symmetricDifference")
    atW4Expect(!a.subtracting(a).contains(a), "subtracting")
    let fromSequence = T([a, b] as [T])
    atW4Expect(fromSequence.contains(a) && fromSequence.contains(b), "sequence init")
    _ = T(rawValue: a.rawValue)
}

private func atW4ProbeEnum<T: Hashable & RawRepresentable>(_ a: T, _ b: T) {
    atW4Expect(a != b, "inequality")
    atW4Expect(a == a, "equality")
    _ = a.hashValue
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
    _ = T(rawValue: a.rawValue)
}

func testOptionSetAlgebraAudioFileFamily() {
    atW4ProbeOptionSet(AudioFileFlags.eraseFile, AudioFileFlags.dontPageAlignAudioData)
    atW4ProbeOptionSet(AudioFileRegionFlags.loopEnable, AudioFileRegionFlags.playForward)
    atW4ProbeOptionSet(AudioFileStreamParseFlags.discontinuity, AudioFileStreamParseFlags(rawValue: 2))
    atW4ProbeOptionSet(
        AudioFileStreamPropertyFlags.propertyIsCached,
        AudioFileStreamPropertyFlags.cacheProperty
    )
    atW4ProbeOptionSet(
        AudioFileStreamSeekFlags.offsetIsEstimated,
        AudioFileStreamSeekFlags(rawValue: 2)
    )
    atW4ProbeOptionSet(CAFFormatFlags.linearPCMFormatFlagIsFloat, CAFFormatFlags.linearPCMFormatFlagIsLittleEndian)
    atW4ProbeOptionSet(CAFRegionFlags.loopEnable, CAFRegionFlags.playForward)
}

func testOptionSetAlgebraAudioUnitAndQueue() {
    atW4ProbeOptionSet(
        AudioUnitRenderActionFlags.unitRenderAction_PreRender,
        AudioUnitRenderActionFlags.unitRenderAction_PostRender
    )
    atW4ProbeOptionSet(
        AudioUnitParameterOptions.flag_CanRamp,
        AudioUnitParameterOptions.flag_ExpertMode
    )
    atW4ProbeOptionSet(
        AudioQueueProcessingTapFlags.preEffects,
        AudioQueueProcessingTapFlags.postEffects
    )
    atW4ProbeOptionSet(
        AudioComponentFlags.unsearchable,
        AudioComponentFlags.sandboxSafe
    )
    atW4ProbeOptionSet(
        AudioComponentInstantiationOptions.loadOutOfProcess,
        AudioComponentInstantiationOptions.loadedRemotely
    )
    atW4ProbeOptionSet(
        AudioConverterOptions.unbuffered,
        AudioConverterOptions(rawValue: 2)
    )
    atW4ProbeOptionSet(
        MusicSequenceFileFlags.eraseFile,
        MusicSequenceFileFlags(rawValue: 2)
    )
    atW4ProbeOptionSet(
        MusicSequenceLoadFlags.smf_ChannelsToTracks,
        MusicSequenceLoadFlags(rawValue: 1 << 1)
    )
    atW4Expect(MusicSequenceLoadFlags.smf_PreserveTracks.rawValue == 0, "preserve tracks")
    atW4Expect(MusicSequenceLoadFlags.channelsToTracks == .smf_ChannelsToTracks, "alias")
}

func testOptionSetAlgebraNewMixerFlags() {
    atW4ProbeOptionSet(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_InterAuralDelay,
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_DopplerShift
    )
    atW4Expect(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_DistanceAttenuation.rawValue == 1 << 2,
        "3d distance"
    )
    atW4Expect(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_DistanceFilter.rawValue == 1 << 3,
        "filter"
    )
    atW4Expect(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_DistanceDiffusion.rawValue == 1 << 4,
        "diffusion"
    )
    atW4Expect(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_LinearDistanceAttenuation.rawValue == 1 << 5,
        "linear dist"
    )
    atW4Expect(
        AU3DMixerRenderingFlags.k3DMixerRenderingFlags_ConstantReverbBlend.rawValue == 1 << 6,
        "reverb blend"
    )
    atW4ProbeOptionSet(
        AUSpatialMixerRenderingFlags.spatialMixerRenderingFlags_InterAuralDelay,
        AUSpatialMixerRenderingFlags.spatialMixerRenderingFlags_DistanceAttenuation
    )
    atW4ProbeOptionSet(AUHostTransportStateFlags.changed, AUHostTransportStateFlags.moving)
    atW4Expect(AUHostTransportStateFlags.recording.rawValue == 4, "recording")
    atW4Expect(AUHostTransportStateFlags.cycling.rawValue == 8, "cycling")
    atW4ProbeOptionSet(
        AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_Complete,
        AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_BeganToRender
    )
    atW4Expect(AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_BeganToRenderLate.rawValue == 4, "late")
    atW4Expect(AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_Loop.rawValue == 8, "loop")
    atW4Expect(AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_Interrupt.rawValue == 16, "interrupt")
    atW4Expect(AUScheduledAudioSliceFlags.scheduledAudioSliceFlag_InterruptAtLoop.rawValue == 32, "loop interrupt")
    atW4ProbeOptionSet(
        AudioBytePacketTranslationFlags.bytePacketTranslationFlag_IsEstimate,
        AudioBytePacketTranslationFlags(rawValue: 2)
    )
    atW4ProbeOptionSet(AudioSettingsFlags.expertParameter, AudioSettingsFlags.invisibleParameter)
    atW4Expect(AudioSettingsFlags.metaParameter.rawValue == 1 << 2, "meta")
    atW4Expect(AudioSettingsFlags.userInterfaceParameter.rawValue == 1 << 3, "ui")
}

func testEnumHashableInequalityCatalog() {
    atW4ProbeEnum(AUAudioUnitBusType.input, AUAudioUnitBusType.output)
    atW4Expect(AUAudioUnitBusType(rawValue: 1) == .input, "bus raw")
    atW4ProbeEnum(AUParameterAutomationEventType.value, AUParameterAutomationEventType.touch)
    atW4Expect(AUParameterAutomationEventType.release.rawValue == 2, "release")
    atW4ProbeEnum(AUParameterEventType.parameterEvent_Immediate, AUParameterEventType.parameterEvent_Ramped)
    atW4ProbeEnum(AURenderEventType.parameter, AURenderEventType.parameterRamp)
    atW4Expect(AURenderEventType.MIDI.rawValue == 8, "midi")
    atW4Expect(AURenderEventType.midiSysEx.rawValue == 9, "sysex")
    atW4Expect(AURenderEventType.midiEventList.rawValue == 10, "list")
    atW4ProbeEnum(
        AU3DMixerAttenuationCurve.k3DMixerAttenuationCurve_Power,
        AU3DMixerAttenuationCurve.k3DMixerAttenuationCurve_Exponential
    )
    atW4Expect(AU3DMixerAttenuationCurve.k3DMixerAttenuationCurve_Inverse.rawValue == 2, "inv")
    atW4Expect(AU3DMixerAttenuationCurve.k3DMixerAttenuationCurve_Linear.rawValue == 3, "lin")
    atW4ProbeEnum(
        AUSpatialMixerAttenuationCurve.spatialMixerAttenuationCurve_Power,
        AUSpatialMixerAttenuationCurve.spatialMixerAttenuationCurve_Exponential
    )
    atW4Expect(AUSpatialMixerAttenuationCurve.spatialMixerAttenuationCurve_Inverse.rawValue == 2, "sinv")
    atW4Expect(AUSpatialMixerAttenuationCurve.spatialMixerAttenuationCurve_Linear.rawValue == 3, "slin")
    atW4ProbeEnum(
        AUAudioMixRenderingStyle.audioMixRenderingStyle_Cinematic,
        AUAudioMixRenderingStyle.audioMixRenderingStyle_Studio
    )
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_InFrame.rawValue == 2, "inframe")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_CinematicBackgroundStem.rawValue == 3, "cbg")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_CinematicForegroundStem.rawValue == 4, "cfg")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_StudioForegroundStem.rawValue == 5, "sfg")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_InFrameForegroundStem.rawValue == 6, "ifg")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_Standard.rawValue == 7, "std")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_StudioBackgroundStem.rawValue == 8, "sbg")
    atW4Expect(AUAudioMixRenderingStyle.audioMixRenderingStyle_InFrameBackgroundStem.rawValue == 9, "ibg")
    atW4ProbeEnum(AUReverbRoomType.reverbRoomType_SmallRoom, AUReverbRoomType.reverbRoomType_MediumRoom)
    atW4Expect(AUReverbRoomType.reverbRoomType_LargeRoom.rawValue == 2, "large room")
    atW4Expect(AUReverbRoomType.reverbRoomType_MediumHall.rawValue == 3, "med hall")
    atW4Expect(AUReverbRoomType.reverbRoomType_LargeHall.rawValue == 4, "large hall")
    atW4Expect(AUReverbRoomType.reverbRoomType_Plate.rawValue == 5, "plate")
    atW4Expect(AUReverbRoomType.reverbRoomType_MediumChamber.rawValue == 6, "med chamber")
    atW4Expect(AUReverbRoomType.reverbRoomType_LargeChamber.rawValue == 7, "large chamber")
    atW4Expect(AUReverbRoomType.reverbRoomType_Cathedral.rawValue == 8, "cathedral")
    atW4Expect(AUReverbRoomType.reverbRoomType_LargeRoom2.rawValue == 9, "large room2")
    atW4Expect(AUReverbRoomType.reverbRoomType_MediumHall2.rawValue == 10, "med hall2")
    atW4Expect(AUReverbRoomType.reverbRoomType_MediumHall3.rawValue == 11, "med hall3")
    atW4Expect(AUReverbRoomType.reverbRoomType_LargeHall2.rawValue == 12, "large hall2")
    atW4ProbeEnum(
        AUSpatialMixerOutputType.spatialMixerOutputType_Headphones,
        AUSpatialMixerOutputType.spatialMixerOutputType_BuiltInSpeakers
    )
    atW4Expect(AUSpatialMixerOutputType.spatialMixerOutputType_ExternalSpeakers.rawValue == 3, "ext")
    atW4ProbeEnum(
        AUSpatialMixerPersonalizedHRTFMode.off,
        AUSpatialMixerPersonalizedHRTFMode.on
    )
    atW4Expect(AUSpatialMixerPersonalizedHRTFMode.auto.rawValue == 2, "auto")
    atW4ProbeEnum(
        AUSpatialMixerPointSourceInHeadMode.spatialMixerPointSourceInHeadMode_Mono,
        AUSpatialMixerPointSourceInHeadMode.spatialMixerPointSourceInHeadMode_Bypass
    )
    atW4ProbeEnum(
        AUSpatialMixerSourceMode.spatialMixerSourceMode_SpatializeIfMono,
        AUSpatialMixerSourceMode.spatialMixerSourceMode_Bypass
    )
    atW4Expect(AUSpatialMixerSourceMode.spatialMixerSourceMode_PointSource.rawValue == 2, "point")
    atW4Expect(AUSpatialMixerSourceMode.spatialMixerSourceMode_AmbienceBed.rawValue == 3, "bed")
    atW4ProbeEnum(
        AUSpatializationAlgorithm.spatializationAlgorithm_EqualPowerPanning,
        AUSpatializationAlgorithm.spatializationAlgorithm_SphericalHead
    )
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_HRTF.rawValue == 2, "hrtf")
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_SoundField.rawValue == 3, "field")
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_VectorBasedPanning.rawValue == 4, "vector")
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_StereoPassThrough.rawValue == 5, "passthru")
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_HRTFHQ.rawValue == 6, "hq")
    atW4Expect(AUSpatializationAlgorithm.spatializationAlgorithm_UseOutputType.rawValue == 7, "out type")
    atW4ProbeEnum(AUVoiceIOOtherAudioDuckingLevel.default, AUVoiceIOOtherAudioDuckingLevel.min)
    atW4Expect(AUVoiceIOOtherAudioDuckingLevel.mid.rawValue == 20, "mid")
    atW4Expect(AUVoiceIOOtherAudioDuckingLevel.max.rawValue == 30, "max duck")
    atW4ProbeEnum(AUVoiceIOSpeechActivityEvent.hasStarted, AUVoiceIOSpeechActivityEvent.hasEnded)
    atW4ProbeEnum(AudioBalanceFadeType.maxUnityGain, AudioBalanceFadeType.equalPower)
    atW4Expect(AudioBalanceFadeType(rawValue: 1) == .equalPower, "fade raw")
    atW4ProbeEnum(AudioPanningMode.panningMode_SoundField, AudioPanningMode.panningMode_VectorBasedPanning)
    atW4Expect(AudioPanningMode(rawValue: 3) == .panningMode_SoundField, "pan raw")
    atW4ProbeEnum(AudioComponentValidationResult.unknown, AudioComponentValidationResult.passed)
    atW4ProbeEnum(AudioFilePermissions.readPermission, AudioFilePermissions.writePermission)
    atW4ProbeEnum(AudioUnitEventType.parameterValueChange, AudioUnitEventType.propertyChange)
    atW4ProbeEnum(AudioUnitParameterUnit.generic, AudioUnitParameterUnit.hertz)
    atW4ProbeEnum(AudioUnitRemoteControlEvent.togglePlayPause, AudioUnitRemoteControlEvent.rewind)
    atW4ProbeEnum(MusicSequenceFileTypeID.anyType, MusicSequenceFileTypeID.midiType)
    atW4ProbeEnum(MusicSequenceType.beats, MusicSequenceType.seconds)
}

func testRemainingParameterAndSelectorIDs() {
    atW4Expect(kDistortionParam_Delay == 0, "delay")
    atW4Expect(kDistortionParam_Decay == 1, "decay")
    atW4Expect(kDistortionParam_DelayMix == 2, "delay mix")
    atW4Expect(kDistortionParam_Decimation == 3, "decim")
    atW4Expect(kDistortionParam_Rounding == 4, "round")
    atW4Expect(kDistortionParam_DecimationMix == 5, "decim mix")
    atW4Expect(kDistortionParam_LinearTerm == 6, "lin")
    atW4Expect(kDistortionParam_SquaredTerm == 7, "sq")
    atW4Expect(kDistortionParam_CubicTerm == 8, "cubic")
    atW4Expect(kDistortionParam_PolynomialMix == 9, "poly")
    atW4Expect(kDistortionParam_RingModFreq1 == 10, "rm1")
    atW4Expect(kDistortionParam_RingModFreq2 == 11, "rm2")
    atW4Expect(kDistortionParam_RingModBalance == 12, "rm bal")
    atW4Expect(kDistortionParam_RingModMix == 13, "rm mix")
    atW4Expect(kDistortionParam_SoftClipGain == 14, "clip")
    atW4Expect(kDistortionParam_FinalMix == 15, "final")
    atW4Expect(kAUNBandEQParam_GlobalGain == 0, "eq gain")
    atW4Expect(kAUNBandEQParam_BypassBand == 1000, "bypass")
    atW4Expect(kAUNBandEQParam_FilterType == 2000, "filter")
    atW4Expect(kAUNBandEQParam_Frequency == 3000, "freq")
    atW4Expect(kAUNBandEQParam_Gain == 4000, "band gain")
    atW4Expect(kAUNBandEQParam_Bandwidth == 5000, "bw")
    atW4Expect(kAUNBandEQFilterType_Parametric == 0, "parametric")
    atW4Expect(kAUNBandEQFilterType_2ndOrderButterworthLowPass == 1, "lp")
    atW4Expect(kAUNBandEQFilterType_2ndOrderButterworthHighPass == 2, "hp")
    atW4Expect(kAUNBandEQFilterType_ResonantLowPass == 3, "rlp")
    atW4Expect(kAUNBandEQFilterType_ResonantHighPass == 4, "rhp")
    atW4Expect(kAUNBandEQFilterType_BandPass == 5, "bp")
    atW4Expect(kAUNBandEQFilterType_BandStop == 6, "bs")
    atW4Expect(kAUNBandEQFilterType_LowShelf == 7, "ls")
    atW4Expect(kAUNBandEQFilterType_HighShelf == 8, "hs")
    atW4Expect(kAUNBandEQFilterType_ResonantLowShelf == 9, "rls")
    atW4Expect(kAUNBandEQFilterType_ResonantHighShelf == 10, "rhs")
    atW4Expect(kNumAUNBandEQFilterTypes == 11, "count")
    atW4Expect(kAUNBandEQProperty_NumberOfBands == 2200, "nbands")
    atW4Expect(kAUNBandEQProperty_MaxNumberOfBands == 2201, "max bands")
    atW4Expect(kAUNBandEQProperty_BiquadCoefficients == 2203, "biquad")
    atW4Expect(kSpatialMixerParam_Azimuth == 0, "az")
    atW4Expect(kSpatialMixerParam_Elevation == 1, "el")
    atW4Expect(kSpatialMixerParam_Distance == 2, "dist")
    atW4Expect(kSpatialMixerParam_Gain == 3, "gain")
    atW4Expect(kSpatialMixerParam_PlaybackRate == 4, "rate")
    atW4Expect(kSpatialMixerParam_Enable == 5, "en")
    atW4Expect(kSpatialMixerParam_MinGain == 6, "min")
    atW4Expect(kSpatialMixerParam_MaxGain == 7, "max")
    atW4Expect(kSpatialMixerParam_ReverbBlend == 8, "rev")
    atW4Expect(kSpatialMixerParam_GlobalReverbGain == 9, "grg")
    atW4Expect(kSpatialMixerParam_OcclusionAttenuation == 10, "occ")
    atW4Expect(kSpatialMixerParam_ObstructionAttenuation == 11, "obs")
    atW4Expect(kSpatialMixerParam_HeadYaw == 12, "yaw")
    atW4Expect(kSpatialMixerParam_HeadPitch == 13, "pitch")
    atW4Expect(kSpatialMixerParam_HeadRoll == 14, "roll")
    atW4Expect(kAUGroupParameterID_ModWheel == 1, "mod")
    atW4Expect(kAUGroupParameterID_Foot == 4, "foot")
    atW4Expect(kAUGroupParameterID_DataEntry == 6, "data")
    atW4Expect(kAUGroupParameterID_Expression == 11, "expr")
    atW4Expect(kAUGroupParameterID_ModWheel_LSB == 33, "mod lsb")
    atW4Expect(kAUGroupParameterID_Foot_LSB == 36, "foot lsb")
    atW4Expect(kAUGroupParameterID_DataEntry_LSB == 38, "data lsb")
    atW4Expect(kAUGroupParameterID_Pan_LSB == 42, "pan lsb")
    atW4Expect(kAUGroupParameterID_Expression_LSB == 43, "expr lsb")
    atW4Expect(kAUGroupParameterID_PitchBend == 0xE0, "pb")
    atW4Expect(kAUGroupParameterID_KeyPressure == 0xA0, "kp")
    atW4Expect(kAUGroupParameterID_ChannelPressure == 0xD0, "cp")
    atW4Expect(kAUGroupParameterID_KeyPressure_FirstKey == 256, "kp first")
    atW4Expect(kAUGroupParameterID_KeyPressure_LastKey == 383, "kp last")
    atW4Expect(kAudioOutputUnitProperty_CurrentDevice == 2000, "cur dev")
    atW4Expect(kAudioOutputUnitProperty_IsRunning == 2001, "running")
    atW4Expect(kAudioOutputUnitProperty_ChannelMap == 2002, "chmap")
    atW4Expect(kAudioOutputUnitProperty_EnableIO == 2003, "io")
    atW4Expect(kAudioOutputUnitProperty_StartTime == 2004, "start")
    atW4Expect(kAudioOutputUnitProperty_SetInputCallback == 2005, "incb")
    atW4Expect(kAudioOutputUnitProperty_HasIO == 2006, "hasio")
    atW4Expect(kAudioOutputUnitProperty_StartTimestampsAtZero == 2007, "ts0")
    atW4Expect(kAudioOutputUnitProperty_MIDICallbacks == 2010, "midi cb")
    atW4Expect(kAudioOutputUnitProperty_HostReceivesRemoteControlEvents == 2011, "host rc")
    atW4Expect(kAudioOutputUnitProperty_RemoteControlToHost == 2012, "rc host")
    atW4Expect(kAudioOutputUnitProperty_HostTransportState == 2013, "transport")
    atW4Expect(kAudioOutputUnitProperty_NodeComponentDescription == 2014, "node desc")
    atW4Expect(kAudioUnitRange == 0, "range")
    atW4Expect(kAudioUnitInitializeSelect == 1, "init sel")
    atW4Expect(kAudioUnitUninitializeSelect == 2, "uninit")
    atW4Expect(kAudioUnitGetPropertyInfoSelect == 3, "gpi")
    atW4Expect(kAudioUnitGetPropertySelect == 4, "gp")
    atW4Expect(kAudioUnitSetPropertySelect == 5, "sp")
    atW4Expect(kAudioUnitGetParameterSelect == 6, "gpar")
    atW4Expect(kAudioUnitSetParameterSelect == 7, "spar")
    atW4Expect(kAudioUnitResetSelect == 9, "reset")
    atW4Expect(kAudioUnitAddPropertyListenerSelect == 0xA, "add lis")
    atW4Expect(kAudioUnitRemovePropertyListenerSelect == 0xB, "rm lis")
    atW4Expect(kAudioUnitRenderSelect == 0xE, "render")
    atW4Expect(kAudioUnitAddRenderNotifySelect == 0xF, "add rn")
    atW4Expect(kAudioUnitRemoveRenderNotifySelect == 0x10, "rm rn")
    atW4Expect(kAudioUnitScheduleParametersSelect == 0x11, "sched")
    atW4Expect(kAudioUnitRemovePropertyListenerWithUserDataSelect == 0x12, "rm ud")
    atW4Expect(kAudioUnitComplexRenderSelect == 0x13, "complex")
    atW4Expect(kAudioUnitProcessSelect == 0x14, "process")
    atW4Expect(kAudioUnitProcessMultipleSelect == 0x15, "multi")
    atW4Expect(kAudioOutputUnitRange == 0x200, "ou range")
    atW4Expect(kAudioOutputUnitStartSelect == 0x201, "ou start")
    atW4Expect(kAudioOutputUnitStopSelect == 0x202, "ou stop")
    atW4Expect(kAudioUnitSampleRateConverterComplexity_Linear == kAudioConverterSampleRateConverterComplexity_Linear, "line")
    atW4Expect(kAudioUnitSampleRateConverterComplexity_Normal == kAudioConverterSampleRateConverterComplexity_Normal, "norm")
    atW4Expect(kAudioUnitSampleRateConverterComplexity_Mastering == kAudioConverterSampleRateConverterComplexity_Mastering, "bats")
    atW4Expect(kAudioUnitClumpID_System == 0, "clump")
    atW4Expect(kAudioUnitParameterName_Full == -1, "full name")
    atW4Expect(kAudioFileLoopDirection_NoLooping == 0, "noloop")
    atW4Expect(kAudioFileLoopDirection_Forward == 1, "fwd")
    atW4Expect(kAudioFileLoopDirection_ForwardAndBackward == 2, "fwdbwd")
    atW4Expect(kAudioFileLoopDirection_Backward == 3, "bwd")
    atW4Expect(kAudioFileMarkerType_Generic == 0, "generic marker")
    atW4Expect(kAudioFileInvalidPacketDependencyError == atW4FourCC("dep?"), "dep?")
}

private func atW4FourCC(_ s: StaticString) -> Int32 {
    var value: UInt32 = 0
    s.withUTF8Buffer { buffer in
        value = (UInt32(buffer[0]) << 24) | (UInt32(buffer[1]) << 16) | (UInt32(buffer[2]) << 8) | UInt32(buffer[3])
    }
    return Int32(bitPattern: value)
}

private func atW4UIntFourCC(_ s: StaticString) -> UInt32 {
    var value: UInt32 = 0
    s.withUTF8Buffer { buffer in
        value = (UInt32(buffer[0]) << 24) | (UInt32(buffer[1]) << 16) | (UInt32(buffer[2]) << 8) | UInt32(buffer[3])
    }
    return value
}

func testAudioFileInfoDictionaryKeys() {
    atW4Expect(kAFInfoDictionary_Album == "album", "album")
    atW4Expect(kAFInfoDictionary_ApproximateDurationInSeconds == "approximate duration in seconds", "dur")
    atW4Expect(kAFInfoDictionary_Artist == "artist", "artist")
    atW4Expect(kAFInfoDictionary_ChannelLayout == "channel layout", "layout")
    atW4Expect(kAFInfoDictionary_Comments == "comments", "comments")
    atW4Expect(kAFInfoDictionary_Composer == "composer", "composer")
    atW4Expect(kAFInfoDictionary_Copyright == "copyright", "copyright")
    atW4Expect(kAFInfoDictionary_EncodingApplication == "encoding application", "enc")
    atW4Expect(kAFInfoDictionary_Genre == "genre", "genre")
    atW4Expect(kAFInfoDictionary_ISRC == "ISRC", "isrc")
    atW4Expect(kAFInfoDictionary_KeySignature == "key signature", "key")
    atW4Expect(kAFInfoDictionary_Lyricist == "lyricist", "lyricist")
    atW4Expect(kAFInfoDictionary_NominalBitRate == "nominal bit rate", "bitrate")
    atW4Expect(kAFInfoDictionary_RecordedDate == "recorded date", "date")
    atW4Expect(kAFInfoDictionary_SourceBitDepth == "source bit depth", "bitdepth")
    atW4Expect(kAFInfoDictionary_SourceEncoder == "source encoder", "encoder")
    atW4Expect(kAFInfoDictionary_SubTitle == "subtitle", "sub")
    atW4Expect(kAFInfoDictionary_Tempo == "tempo", "tempo")
    atW4Expect(kAFInfoDictionary_TimeSignature == "time signature", "timesig")
    atW4Expect(kAFInfoDictionary_Title == "title", "title")
    atW4Expect(kAFInfoDictionary_TrackNumber == "track number", "track")
    atW4Expect(kAFInfoDictionary_Year == "year", "year")
}

func testRemainingAudioCodecAndStreamProperties() {
    atW4Expect(kAudioCodecPropertySupportedInputFormats == atW4UIntFourCC("ifm#"), "ifm")
    atW4Expect(kAudioCodecPropertySupportedOutputFormats == atW4UIntFourCC("ofm#"), "ofm")
    atW4Expect(kAudioCodecPropertyAvailableInputSampleRates == atW4UIntFourCC("aisr"), "aisr")
    atW4Expect(kAudioCodecPropertyAvailableOutputSampleRates == atW4UIntFourCC("aosr"), "aosr")
    atW4Expect(kAudioCodecPropertyAvailableBitRateRange == atW4UIntFourCC("abrt"), "abrt")
    atW4Expect(kAudioCodecPropertyMinimumNumberInputPackets == atW4UIntFourCC("mnip"), "mnip")
    atW4Expect(kAudioCodecPropertyMinimumNumberOutputPackets == atW4UIntFourCC("mnop"), "mnop")
    atW4Expect(kAudioCodecPropertyAvailableNumberChannels == atW4UIntFourCC("cmnc"), "cmnc")
    atW4Expect(kAudioCodecPropertyDoesSampleRateConversion == atW4UIntFourCC("lmrc"), "lmrc")
    atW4Expect(kAudioCodecDoesSampleRateConversion == kAudioCodecPropertyDoesSampleRateConversion, "alias src")
    atW4Expect(kAudioCodecPropertyAvailableInputChannelLayoutTags == atW4UIntFourCC("ailt"), "ailt")
    atW4Expect(kAudioCodecPropertyAvailableOutputChannelLayoutTags == atW4UIntFourCC("aolt"), "aolt")
    atW4Expect(kAudioCodecPropertyFormatInfo == atW4UIntFourCC("acfi"), "acfi")
    atW4Expect(kAudioCodecPropertyRequiresPacketDescription == atW4UIntFourCC("pakd"), "pakd")
    atW4Expect(kAudioCodecPropertyInputChannelLayout == atW4UIntFourCC("icl "), "icl")
    atW4Expect(kAudioCodecPropertyOutputChannelLayout == atW4UIntFourCC("ocl "), "ocl")
    atW4Expect(kAudioCodecPropertyInputFormatsForOutputFormat == atW4UIntFourCC("if4o"), "if4o")
    atW4Expect(kAudioCodecPropertyOutputFormatsForInputFormat == atW4UIntFourCC("of4i"), "of4i")
    atW4Expect(kAudioCodecInputFormatsForOutputFormat == kAudioCodecPropertyInputFormatsForOutputFormat, "alias if")
    atW4Expect(kAudioCodecOutputFormatsForInputFormat == kAudioCodecPropertyOutputFormatsForInputFormat, "alias of")
    atW4Expect(kAudioCodecPropertyAvailableBitRates == atW4UIntFourCC("brt#"), "brt")
    atW4Expect(kAudioCodecPropertyAvailableInputChannelLayouts == atW4UIntFourCC("icl#"), "icl#")
    atW4Expect(kAudioCodecPropertyAvailableOutputChannelLayouts == atW4UIntFourCC("ocl#"), "ocl#")
    atW4Expect(kAudioCodecPropertyZeroFramesPadded == kAudioCodecPropertyPaddedZeros, "pad0")
    atW4Expect(kAudioCodecPropertyMinimumDelayMode == atW4UIntFourCC("mdel"), "mdel")
    atW4Expect(kAudioCodecBitRateFormat == atW4UIntFourCC("cbrf"), "cbrf")
    atW4Expect(kAudioCodecExtendFrequencies == atW4UIntFourCC("acef"), "acef")
    atW4Expect(kAudioCodecOutputPrecedence == atW4UIntFourCC("oppr"), "oppr")
    atW4Expect(kAudioCodecUseRecommendedSampleRate == atW4UIntFourCC("ursr"), "ursr")
    atW4Expect(kAudioFileStreamProperty_BitRate == atW4UIntFourCC("brat"), "brat")
    atW4Expect(kAudioFileStreamProperty_ByteToPacket == atW4UIntFourCC("bypk"), "bypk")
    atW4Expect(kAudioFileStreamProperty_DataOffset == atW4UIntFourCC("doff"), "doff")
    atW4Expect(kAudioFileStreamProperty_FormatList == atW4UIntFourCC("flst"), "flst")
    atW4Expect(kAudioFileStreamProperty_FrameToPacket == atW4UIntFourCC("frpk"), "frpk")
    atW4Expect(kAudioFileStreamProperty_InfoDictionary == atW4UIntFourCC("info"), "info")
    atW4Expect(kAudioFileStreamProperty_MagicCookieData == atW4UIntFourCC("mgic"), "mgic")
    atW4Expect(kAudioFileStreamProperty_MaximumPacketSize == atW4UIntFourCC("psze"), "psze")
    atW4Expect(kAudioFileStreamProperty_NextIndependentPacket == atW4UIntFourCC("nind"), "nind")
    atW4Expect(kAudioFileStreamProperty_PacketTableInfo == atW4UIntFourCC("pnfo"), "pnfo")
    atW4Expect(kAudioFileStreamProperty_PacketToByte == atW4UIntFourCC("pkby"), "pkby")
    atW4Expect(kAudioFileStreamProperty_PacketToDependencyInfo == atW4UIntFourCC("pdep"), "pdep")
    atW4Expect(kAudioFileStreamProperty_PacketToFrame == atW4UIntFourCC("pkfr"), "pkfr")
    atW4Expect(kAudioFileStreamProperty_PacketToRollDistance == atW4UIntFourCC("prll"), "prll")
    atW4Expect(kAudioFileStreamProperty_PreviousIndependentPacket == atW4UIntFourCC("pind"), "pind")
    atW4Expect(kAudioFileStreamProperty_RestrictsRandomAccess == atW4UIntFourCC("rran"), "rran")
}

func testAUAudioUnitSoftwareProperties() {
    let mixer = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    do {
        let unit = try AUAudioUnit(componentDescription: mixer)
        atW4Expect(unit.canProcessInPlace, "inplace")
        atW4Expect(!unit.inputEnabled, "no hw in")
        atW4Expect(unit.outputEnabled, "out enabled")
        unit.renderQuality = 64
        atW4Expect(unit.renderQuality == 64, "quality")
        unit.shouldBypassEffect = true
        atW4Expect(unit.shouldBypassEffect, "bypass")
        unit.contextName = "mix"
        atW4Expect(unit.contextName == "mix", "context")
        unit.channelMap = [0, 1]
        atW4Expect(unit.channelMap?.count == 2, "map")
        atW4Expect(unit.factoryPresets == nil, "no factory")
        atW4Expect(unit.userPresets.isEmpty, "no user")
        atW4Expect(unit.allParameterValues, "kvo trigger")
        atW4Expect(!unit.musicDeviceOrEffect, "not music")
        atW4Expect(!unit.providesUserInterface, "no ui")
        atW4Expect(!unit.supportsMPE, "no mpe")
        atW4Expect(!unit.supportsUserPresets, "no user presets")
        atW4Expect(unit.channelCapabilities == nil, "no caps")
        atW4Expect(unit.MIDIOutputNames.isEmpty, "no midi names")
        atW4Expect(unit.virtualMIDICableCount == 0, "no cables")
        atW4Expect(unit.migrateFromPlugin.isEmpty, "no migrate")
        unit.MIDIOutputBufferSizeHint = 512
        atW4Expect(unit.MIDIOutputBufferSizeHint == 512, "hint")
        unit.setRenderResourcesAllocated(true)
        atW4Expect(unit.renderResourcesAllocated, "allocated setter")
        unit.setRenderResourcesAllocated(false)
        atW4Expect(!unit.renderResourcesAllocated, "cleared")
        let overview = unit.parametersForOverview(withCount: 4)
        atW4Expect(overview.isEmpty, "empty overview")
        let token = unit.tokenByAddingRenderObserver { _ in }
        atW4Expect(token != 0, "token")
        unit.removeRenderObserver(token)
        let preset = AUAudioUnitPreset()
        preset.number = 1
        preset.name = "user"
        unit.currentPreset = preset
        atW4Expect(unit.currentPreset?.number == 1, "preset")
        do {
            try unit.saveUserPreset(preset)
            fatalError("save must fail closed")
        } catch {
            atW4Expect(true, "save fail-closed")
        }
        do {
            try unit.deleteUserPreset(preset)
            fatalError("delete must fail closed")
        } catch {
            atW4Expect(true, "delete fail-closed")
        }
        atW4Expect(unit.inputBusses.busType == .input, "in type")
        atW4Expect(unit.outputBusses.busType == .output, "out type")
        atW4Expect(unit.inputBusses.ownerAudioUnit === unit, "in owner")
        atW4Expect(unit.outputBusses.ownerAudioUnit === unit, "out owner")
        let bus = unit.inputBusses[0]
        atW4Expect(bus.index == 0, "index")
        atW4Expect(bus.shouldAllocateBuffer, "alloc buffer")
        atW4Expect(bus.maximumChannelCount == 2, "max ch")
        atW4Expect(bus.ownerAudioUnit === unit, "bus owner")
        atW4Expect(bus.supportedChannelCounts?.contains(2) == true, "counts")
        atW4Expect(bus.supportedChannelLayoutTags == nil, "no tags")
        atW4Expect(bus.contextPresentationLatency == 0, "latency")
        bus.name = "in0"
        atW4Expect(bus.name == "in0", "bus name")
        atW4Expect(unit.componentName == "MultiChannelMixer", "component name")
        _ = unit.component
        unit.fullState = ["k": "v"]
        atW4Expect(unit.fullState?["k"] as? String == "v", "state")
        unit.fullStateForDocument = ["d": 1]
        atW4Expect(unit.fullStateForDocument?["d"] as? Int == 1, "doc state")
        let owned = AUAudioUnitBusArray(audioUnit: unit, busType: .input)
        atW4Expect(owned.busType == .input, "owned type")
        atW4Expect(owned.ownerAudioUnit === unit, "owned owner")
        let extra = AUAudioUnitBus(busType: .output)
        extra.name = "out"
        let wrapped = AUAudioUnitBusArray(audioUnit: unit, busType: .output, busses: [extra])
        atW4Expect(wrapped.count == 1, "wrapped count")
        atW4Expect(wrapped[0].name == "out", "wrapped bus")
        atW4Expect(wrapped[0].index == 0, "wrapped index")
    } catch {
        fatalError("software mixer v3 must instantiate")
    }
}
