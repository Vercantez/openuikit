import Foundation

public let kMultiChannelMixerParam_Volume: AudioUnitParameterID = 0
public let kMultiChannelMixerParam_Enable: AudioUnitParameterID = 1
public let kMultiChannelMixerParam_Pan: AudioUnitParameterID = 2
public let kMultiChannelMixerParam_PreAveragePower: AudioUnitParameterID = 1000
public let kMultiChannelMixerParam_PrePeakHoldLevel: AudioUnitParameterID = 2000
public let kMultiChannelMixerParam_PostAveragePower: AudioUnitParameterID = 3000
public let kMultiChannelMixerParam_PostPeakHoldLevel: AudioUnitParameterID = 4000

public let kMatrixMixerParam_Volume: AudioUnitParameterID = 0
public let kMatrixMixerParam_Enable: AudioUnitParameterID = 1
public let kMatrixMixerParam_PreAveragePower: AudioUnitParameterID = 1000
public let kMatrixMixerParam_PrePeakHoldLevel: AudioUnitParameterID = 2000
public let kMatrixMixerParam_PostAveragePower: AudioUnitParameterID = 3000
public let kMatrixMixerParam_PostPeakHoldLevel: AudioUnitParameterID = 4000
public let kMatrixMixerParam_PreAveragePowerLinear: AudioUnitParameterID = 5000
public let kMatrixMixerParam_PrePeakHoldLevelLinear: AudioUnitParameterID = 6000
public let kMatrixMixerParam_PostAveragePowerLinear: AudioUnitParameterID = 7000
public let kMatrixMixerParam_PostPeakHoldLevelLinear: AudioUnitParameterID = 8000

public let k3DMixerParam_Azimuth: AudioUnitParameterID = 0
public let k3DMixerParam_Elevation: AudioUnitParameterID = 1
public let k3DMixerParam_Distance: AudioUnitParameterID = 2
public let k3DMixerParam_Gain: AudioUnitParameterID = 3
public let k3DMixerParam_PlaybackRate: AudioUnitParameterID = 4
public let k3DMixerParam_Enable: AudioUnitParameterID = 5
public let k3DMixerParam_MinGain: AudioUnitParameterID = 6
public let k3DMixerParam_MaxGain: AudioUnitParameterID = 7
public let k3DMixerParam_ReverbBlend: AudioUnitParameterID = 8
public let k3DMixerParam_GlobalReverbGain: AudioUnitParameterID = 9
public let k3DMixerParam_OcclusionAttenuation: AudioUnitParameterID = 10
public let k3DMixerParam_ObstructionAttenuation: AudioUnitParameterID = 11
/// 10.8+ header aliases of the Enable / gain / reverb / occlusion IDs above.
public let k3DMixerParam_BusEnable: AudioUnitParameterID = k3DMixerParam_Enable
public let k3DMixerParam_MinGainInDecibels: AudioUnitParameterID = k3DMixerParam_MinGain
public let k3DMixerParam_MaxGainInDecibels: AudioUnitParameterID = k3DMixerParam_MaxGain
public let k3DMixerParam_DryWetReverbBlend: AudioUnitParameterID = k3DMixerParam_ReverbBlend
public let k3DMixerParam_GlobalReverbGainInDecibels: AudioUnitParameterID = k3DMixerParam_GlobalReverbGain
public let k3DMixerParam_OcclusionAttenuationInDecibels: AudioUnitParameterID = k3DMixerParam_OcclusionAttenuation
public let k3DMixerParam_ObstructionAttenuationInDecibels: AudioUnitParameterID = k3DMixerParam_ObstructionAttenuation
public let k3DMixerParam_PreAveragePower: AudioUnitParameterID = 1000
public let k3DMixerParam_PrePeakHoldLevel: AudioUnitParameterID = 2000
public let k3DMixerParam_PostAveragePower: AudioUnitParameterID = 3000
public let k3DMixerParam_PostPeakHoldLevel: AudioUnitParameterID = 4000

public let kHALOutputParam_Volume: AudioUnitParameterID = 14

public let kTimePitchParam_Rate: AudioUnitParameterID = 0
public let kTimePitchParam_Pitch: AudioUnitParameterID = 1
public let kTimePitchParam_EffectBlend: AudioUnitParameterID = 2

public let kNewTimePitchParam_Rate: AudioUnitParameterID = 0
public let kNewTimePitchParam_Pitch: AudioUnitParameterID = 1
public let kNewTimePitchParam_Overlap: AudioUnitParameterID = 4
public let kNewTimePitchParam_Smoothness: AudioUnitParameterID = kNewTimePitchParam_Overlap
public let kNewTimePitchParam_EnablePeakLocking: AudioUnitParameterID = 6
public let kNewTimePitchParam_EnableSpectralCoherence: AudioUnitParameterID = kNewTimePitchParam_EnablePeakLocking
public let kNewTimePitchParam_EnableTransientPreservation: AudioUnitParameterID = 7

public let kVarispeedParam_PlaybackRate: AudioUnitParameterID = 0
public let kVarispeedParam_PlaybackCents: AudioUnitParameterID = 1

public let kAUGroupParameterID_ModWheel: AudioUnitParameterID = 1
public let kAUGroupParameterID_Foot: AudioUnitParameterID = 4
public let kAUGroupParameterID_DataEntry: AudioUnitParameterID = 6
public let kAUGroupParameterID_Volume: AudioUnitParameterID = 7
public let kAUGroupParameterID_Pan: AudioUnitParameterID = 10
public let kAUGroupParameterID_Expression: AudioUnitParameterID = 11
public let kAUGroupParameterID_ModWheel_LSB: AudioUnitParameterID = 33
public let kAUGroupParameterID_Foot_LSB: AudioUnitParameterID = 36
public let kAUGroupParameterID_DataEntry_LSB: AudioUnitParameterID = 38
public let kAUGroupParameterID_Volume_LSB: AudioUnitParameterID = 39
public let kAUGroupParameterID_Pan_LSB: AudioUnitParameterID = 42
public let kAUGroupParameterID_Expression_LSB: AudioUnitParameterID = 43
public let kAUGroupParameterID_Sustain: AudioUnitParameterID = 64
public let kAUGroupParameterID_Sostenuto: AudioUnitParameterID = 66
public let kAUGroupParameterID_AllSoundOff: AudioUnitParameterID = 120
public let kAUGroupParameterID_ResetAllControllers: AudioUnitParameterID = 121
public let kAUGroupParameterID_AllNotesOff: AudioUnitParameterID = 123
public let kAUGroupParameterID_PitchBend: AudioUnitParameterID = 0xE0
public let kAUGroupParameterID_KeyPressure: AudioUnitParameterID = 0xA0
public let kAUGroupParameterID_ChannelPressure: AudioUnitParameterID = 0xD0
public let kAUGroupParameterID_KeyPressure_FirstKey: AudioUnitParameterID = 256
public let kAUGroupParameterID_KeyPressure_LastKey: AudioUnitParameterID = 383

public let kDistortionParam_Delay: AudioUnitParameterID = 0
public let kDistortionParam_Decay: AudioUnitParameterID = 1
public let kDistortionParam_DelayMix: AudioUnitParameterID = 2
public let kDistortionParam_Decimation: AudioUnitParameterID = 3
public let kDistortionParam_Rounding: AudioUnitParameterID = 4
public let kDistortionParam_DecimationMix: AudioUnitParameterID = 5
public let kDistortionParam_LinearTerm: AudioUnitParameterID = 6
public let kDistortionParam_SquaredTerm: AudioUnitParameterID = 7
public let kDistortionParam_CubicTerm: AudioUnitParameterID = 8
public let kDistortionParam_PolynomialMix: AudioUnitParameterID = 9
public let kDistortionParam_RingModFreq1: AudioUnitParameterID = 10
public let kDistortionParam_RingModFreq2: AudioUnitParameterID = 11
public let kDistortionParam_RingModBalance: AudioUnitParameterID = 12
public let kDistortionParam_RingModMix: AudioUnitParameterID = 13
public let kDistortionParam_SoftClipGain: AudioUnitParameterID = 14
public let kDistortionParam_FinalMix: AudioUnitParameterID = 15

public let kAUNBandEQParam_GlobalGain: AudioUnitParameterID = 0
public let kAUNBandEQParam_BypassBand: AudioUnitParameterID = 1000
public let kAUNBandEQParam_FilterType: AudioUnitParameterID = 2000
public let kAUNBandEQParam_Frequency: AudioUnitParameterID = 3000
public let kAUNBandEQParam_Gain: AudioUnitParameterID = 4000
public let kAUNBandEQParam_Bandwidth: AudioUnitParameterID = 5000

public let kAUNBandEQFilterType_Parametric: Int = 0
public let kAUNBandEQFilterType_2ndOrderButterworthLowPass: Int = 1
public let kAUNBandEQFilterType_2ndOrderButterworthHighPass: Int = 2
public let kAUNBandEQFilterType_ResonantLowPass: Int = 3
public let kAUNBandEQFilterType_ResonantHighPass: Int = 4
public let kAUNBandEQFilterType_BandPass: Int = 5
public let kAUNBandEQFilterType_BandStop: Int = 6
public let kAUNBandEQFilterType_LowShelf: Int = 7
public let kAUNBandEQFilterType_HighShelf: Int = 8
public let kAUNBandEQFilterType_ResonantLowShelf: Int = 9
public let kAUNBandEQFilterType_ResonantHighShelf: Int = 10
public let kNumAUNBandEQFilterTypes: Int = 11

public let kAUNBandEQProperty_NumberOfBands: AudioUnitPropertyID = 2200
public let kAUNBandEQProperty_MaxNumberOfBands: AudioUnitPropertyID = 2201
public let kAUNBandEQProperty_BiquadCoefficients: AudioUnitPropertyID = 2203

public let kSpatialMixerParam_Azimuth: AudioUnitParameterID = 0
public let kSpatialMixerParam_Elevation: AudioUnitParameterID = 1
public let kSpatialMixerParam_Distance: AudioUnitParameterID = 2
public let kSpatialMixerParam_Gain: AudioUnitParameterID = 3
public let kSpatialMixerParam_PlaybackRate: AudioUnitParameterID = 4
public let kSpatialMixerParam_Enable: AudioUnitParameterID = 5
public let kSpatialMixerParam_MinGain: AudioUnitParameterID = 6
public let kSpatialMixerParam_MaxGain: AudioUnitParameterID = 7
public let kSpatialMixerParam_ReverbBlend: AudioUnitParameterID = 8
public let kSpatialMixerParam_GlobalReverbGain: AudioUnitParameterID = 9
public let kSpatialMixerParam_OcclusionAttenuation: AudioUnitParameterID = 10
public let kSpatialMixerParam_ObstructionAttenuation: AudioUnitParameterID = 11
public let kSpatialMixerParam_HeadYaw: AudioUnitParameterID = 12
public let kSpatialMixerParam_HeadPitch: AudioUnitParameterID = 13
public let kSpatialMixerParam_HeadRoll: AudioUnitParameterID = 14

public let kMusicDeviceProperty_InstrumentCount: AudioUnitPropertyID = 1000
public let kMusicDeviceProperty_InstrumentName: AudioUnitPropertyID = 1001
public let kMusicDeviceProperty_InstrumentNumber: AudioUnitPropertyID = 1004
public let kMusicDeviceProperty_BankName: AudioUnitPropertyID = 1007
public let kMusicDeviceProperty_SoundBankURL: AudioUnitPropertyID = 1100

public let kMusicDeviceRange: Int = 0x0100
public let kMusicDeviceMIDIEventSelect: Int = 0x0101
public let kMusicDeviceSysExSelect: Int = 0x0102
public let kMusicDevicePrepareInstrumentSelect: Int = 0x0103
public let kMusicDeviceReleaseInstrumentSelect: Int = 0x0104
public let kMusicDeviceStartNoteSelect: Int = 0x0105
public let kMusicDeviceStopNoteSelect: Int = 0x0106
public let kMusicDeviceMIDIEventListSelect: Int = 0x0107

public let kMusicNoteEvent_UseGroupInstrument: UInt32 = 0xFFFF_FFFF
public let kMusicNoteEvent_Unused: UInt32 = 0x00FF_FFFF

public let kAudioQueueParam_Volume: AudioQueueParameterID = 1
public let kAudioQueueParam_PlayRate: AudioQueueParameterID = 2
public let kAudioQueueParam_Pitch: AudioQueueParameterID = 3
public let kAudioQueueParam_VolumeRampTime: AudioQueueParameterID = 4
public let kAudioQueueParam_Pan: AudioQueueParameterID = 13

public let kSequenceTrackProperty_LoopInfo: UInt32 = 0
public let kSequenceTrackProperty_OffsetTime: UInt32 = 1
public let kSequenceTrackProperty_MuteStatus: UInt32 = 2
public let kSequenceTrackProperty_SoloStatus: UInt32 = 3
public let kSequenceTrackProperty_AutomatedParameters: UInt32 = 4
public let kSequenceTrackProperty_TrackLength: UInt32 = 5
public let kSequenceTrackProperty_TimeResolution: UInt32 = 6

public let kAudioToolboxErr_InvalidSequenceType: Int32 = -10846
public let kAudioToolboxErr_TrackIndexError: Int32 = -10859
public let kAudioToolboxErr_TrackNotFound: Int32 = -10858
public let kAudioToolboxErr_EndOfTrack: Int32 = -10857
public let kAudioToolboxErr_StartOfTrack: Int32 = -10856
public let kAudioToolboxErr_IllegalTrackDestination: Int32 = -10855
public let kAudioToolboxErr_NoSequence: Int32 = -10854
public let kAudioToolboxErr_InvalidEventType: Int32 = -10853
public let kAudioToolboxErr_InvalidPlayerState: Int32 = -10852
public let kAudioToolboxErr_CannotDoInCurrentContext: Int32 = -10863
public let kAudioToolboxError_NoTrackDestination: Int32 = -66720

public let kAudioFileGlobalInfo_ReadableTypes: AudioFilePropertyID = atFourCC("afrf")
public let kAudioFileGlobalInfo_WritableTypes: AudioFilePropertyID = atFourCC("afwf")
public let kAudioFileGlobalInfo_FileTypeName: AudioFilePropertyID = atFourCC("ftnm")
public let kAudioFileGlobalInfo_AvailableFormatIDs: AudioFilePropertyID = atFourCC("fmid")
public let kAudioFileGlobalInfo_AvailableStreamDescriptionsForFormat: AudioFilePropertyID = atFourCC("sdid")
public let kAudioFileGlobalInfo_AllExtensions: AudioFilePropertyID = atFourCC("alxt")
public let kAudioFileGlobalInfo_AllHFSTypeCodes: AudioFilePropertyID = atFourCC("ahfs")
public let kAudioFileGlobalInfo_AllUTIs: AudioFilePropertyID = atFourCC("auti")
public let kAudioFileGlobalInfo_AllMIMETypes: AudioFilePropertyID = atFourCC("amim")
public let kAudioFileGlobalInfo_ExtensionsForType: AudioFilePropertyID = atFourCC("fext")
public let kAudioFileGlobalInfo_HFSTypeCodesForType: AudioFilePropertyID = atFourCC("fhfs")
public let kAudioFileGlobalInfo_UTIsForType: AudioFilePropertyID = atFourCC("futi")
public let kAudioFileGlobalInfo_MIMETypesForType: AudioFilePropertyID = atFourCC("fmim")
public let kAudioFileGlobalInfo_TypesForMIMEType: AudioFilePropertyID = atFourCC("tmim")
public let kAudioFileGlobalInfo_TypesForUTI: AudioFilePropertyID = atFourCC("tuti")
public let kAudioFileGlobalInfo_TypesForHFSTypeCode: AudioFilePropertyID = atFourCC("thfs")
public let kAudioFileGlobalInfo_TypesForExtension: AudioFilePropertyID = atFourCC("text")

public let kAUSamplerParam_Gain: AudioUnitParameterID = 900
public let kAUSamplerParam_CoarseTuning: AudioUnitParameterID = 901
public let kAUSamplerParam_FineTuning: AudioUnitParameterID = 902
public let kAUSamplerParam_Pan: AudioUnitParameterID = 903

public let kBandpassParam_CenterFrequency: AudioUnitParameterID = 0
public let kBandpassParam_Bandwidth: AudioUnitParameterID = 1

public let kHipassParam_CutoffFrequency: AudioUnitParameterID = 0
public let kHipassParam_Resonance: AudioUnitParameterID = 1

public let kLowPassParam_CutoffFrequency: AudioUnitParameterID = 0
public let kLowPassParam_Resonance: AudioUnitParameterID = 1

public let kHighShelfParam_CutOffFrequency: AudioUnitParameterID = 0
public let kHighShelfParam_Gain: AudioUnitParameterID = 1

public let kAULowShelfParam_CutoffFrequency: AudioUnitParameterID = 0
public let kAULowShelfParam_Gain: AudioUnitParameterID = 1

public let kParametricEQParam_CenterFreq: AudioUnitParameterID = 0
public let kParametricEQParam_Q: AudioUnitParameterID = 1
public let kParametricEQParam_Gain: AudioUnitParameterID = 2

public let kLimiterParam_AttackTime: AudioUnitParameterID = 0
public let kLimiterParam_DecayTime: AudioUnitParameterID = 1
public let kLimiterParam_PreGain: AudioUnitParameterID = 2

public let kDynamicsProcessorParam_Threshold: AudioUnitParameterID = 0
public let kDynamicsProcessorParam_HeadRoom: AudioUnitParameterID = 1
public let kDynamicsProcessorParam_ExpansionRatio: AudioUnitParameterID = 2
public let kDynamicsProcessorParam_ExpansionThreshold: AudioUnitParameterID = 3
public let kDynamicsProcessorParam_AttackTime: AudioUnitParameterID = 4
public let kDynamicsProcessorParam_ReleaseTime: AudioUnitParameterID = 5
public let kDynamicsProcessorParam_OverallGain: AudioUnitParameterID = 6
public let kDynamicsProcessorParam_CompressionAmount: AudioUnitParameterID = 1000
public let kDynamicsProcessorParam_InputAmplitude: AudioUnitParameterID = 2000
public let kDynamicsProcessorParam_OutputAmplitude: AudioUnitParameterID = 3000

public let kDelayParam_WetDryMix: AudioUnitParameterID = 0
public let kDelayParam_DelayTime: AudioUnitParameterID = 1
public let kDelayParam_Feedback: AudioUnitParameterID = 2
public let kDelayParam_LopassCutoff: AudioUnitParameterID = 3

public let kReverb2Param_DryWetMix: AudioUnitParameterID = 0
public let kReverb2Param_Gain: AudioUnitParameterID = 1
public let kReverb2Param_MinDelayTime: AudioUnitParameterID = 2
public let kReverb2Param_MaxDelayTime: AudioUnitParameterID = 3
public let kReverb2Param_DecayTimeAt0Hz: AudioUnitParameterID = 4
public let kReverb2Param_DecayTimeAtNyquist: AudioUnitParameterID = 5
public let kReverb2Param_RandomizeReflections: AudioUnitParameterID = 6

public let kRandomParam_BoundA: AudioUnitParameterID = 0
public let kRandomParam_BoundB: AudioUnitParameterID = 1
public let kRandomParam_Curve: AudioUnitParameterID = 2

public let kRoundTripAACParam_Format: AudioUnitParameterID = 0
public let kRoundTripAACParam_EncodingStrategy: AudioUnitParameterID = 1
public let kRoundTripAACParam_RateOrQuality: AudioUnitParameterID = 2

public let kReverbParam_FilterFrequency: AudioUnitParameterID = 14
public let kReverbParam_FilterBandwidth: AudioUnitParameterID = 15
public let kReverbParam_FilterGain: AudioUnitParameterID = 16
public let kReverbParam_FilterType: AudioUnitParameterID = 17
public let kReverbParam_FilterEnable: AudioUnitParameterID = 18

public let kAUAudioMixParameter_Style: AudioUnitParameterID = 0
public let kAUAudioMixParameter_RemixAmount: AudioUnitParameterID = 1

public let kAUAudioMixProperty_SpatialAudioMixMetadata: AudioUnitPropertyID = 5000
public let kAUAudioMixProperty_EnableSpatialization: AudioUnitPropertyID = 5001

public let kAUVoiceIOProperty_BypassVoiceProcessing: AudioUnitPropertyID = 2100
public let kAUVoiceIOProperty_VoiceProcessingEnableAGC: AudioUnitPropertyID = 2101
public let kAUVoiceIOProperty_MuteOutput: AudioUnitPropertyID = 2104
public let kAUVoiceIOProperty_MutedSpeechActivityEventListener: AudioUnitPropertyID = 2106

public let kAUSamplerProperty_LoadPresetFromBank: AudioUnitPropertyID = 4100
public let kAUSamplerProperty_BankAndPreset: AudioUnitPropertyID = kAUSamplerProperty_LoadPresetFromBank
public let kAUSamplerProperty_LoadAudioFiles: AudioUnitPropertyID = 4101
public let kAUSamplerProperty_LoadInstrument: AudioUnitPropertyID = 4102
public let kAUMIDISynthProperty_EnablePreload: AudioUnitPropertyID = 4119

public let kInstrumentType_DLSPreset: UInt8 = 1
public let kInstrumentType_SF2Preset: UInt8 = kInstrumentType_DLSPreset
public let kInstrumentType_AUPreset: UInt8 = 2
public let kInstrumentType_Audiofile: UInt8 = 3
public let kInstrumentType_EXS24: UInt8 = 4

public let kAUSampler_DefaultPercussionBankMSB: UInt8 = 0x78
public let kAUSampler_DefaultMelodicBankMSB: UInt8 = 0x79
public let kAUSampler_DefaultBankLSB: UInt8 = 0x00

public let kRenderQuality_Min: Int = 0x00
public let kRenderQuality_Low: Int = 0x20
public let kRenderQuality_Medium: Int = 0x40
public let kRenderQuality_High: Int = 0x60
public let kRenderQuality_Max: Int = 0x7F

public let kAudioQueueHardwareCodecPolicy_Default: UInt32 = 0
public let kAudioQueueHardwareCodecPolicy_UseSoftwareOnly: UInt32 = 1
public let kAudioQueueHardwareCodecPolicy_UseHardwareOnly: UInt32 = 2
public let kAudioQueueHardwareCodecPolicy_PreferSoftware: UInt32 = 3
public let kAudioQueueHardwareCodecPolicy_PreferHardware: UInt32 = 4

public let kConverterPrimeMethod_Pre: UInt32 = 0
public let kConverterPrimeMethod_Normal: UInt32 = 1
public let kConverterPrimeMethod_None: UInt32 = 2

public let kHintBasic: UInt32 = 0
public let kHintAdvanced: UInt32 = 1
public let kHintHidden: UInt32 = 2

public let kAUParameterListener_AnyParameter: AudioUnitParameterID = 0xFFFF_FFFF
public let kNumberOfResponseFrequencies: UInt32 = 1024

public let kAudioDecoderComponentType: UInt32 = atFourCC("adec")
public let kAudioEncoderComponentType: UInt32 = atFourCC("aenc")

public let kMusicTimeStamp_EndOfTrack: MusicTimeStamp = Double.greatestFiniteMagnitude

public let kSampleDelayParam_DelayFrames: AudioUnitParameterID = 0

public let kDynamicRangeCompressionProfile_None: UInt32 = 0
public let kDynamicRangeCompressionProfile_LateNight: UInt32 = 1
public let kDynamicRangeCompressionProfile_NoisyEnvironment: UInt32 = 2
public let kDynamicRangeCompressionProfile_LimitedPlaybackRange: UInt32 = 3
public let kDynamicRangeCompressionProfile_GeneralCompression: UInt32 = 6

public let kDynamicRangeControlMode_None: UInt32 = 0
public let kDynamicRangeControlMode_Light: UInt32 = 1
public let kDynamicRangeControlMode_Heavy: UInt32 = 2

public let kProgramTargetLevel_None: UInt32 = 0
public let kProgramTargetLevel_Minus31dB: UInt32 = 1
public let kProgramTargetLevel_Minus23dB: UInt32 = 2
public let kProgramTargetLevel_Minus20dB: UInt32 = 3

public let kAUSoundIsolationParam_WetDryMixPercent: AudioUnitParameterID = 0
public let kAUSoundIsolationParam_SoundToIsolate: AudioUnitParameterID = 1
public let kAUSoundIsolationSoundType_HighQualityVoice: Int = 0
public let kAUSoundIsolationSoundType_Voice: Int = 1
