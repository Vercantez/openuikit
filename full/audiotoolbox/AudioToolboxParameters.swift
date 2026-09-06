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

public let kHALOutputParam_Volume: AudioUnitParameterID = 14

public let kTimePitchParam_Rate: AudioUnitParameterID = 0
public let kTimePitchParam_Pitch: AudioUnitParameterID = 1
public let kTimePitchParam_EffectBlend: AudioUnitParameterID = 2

public let kNewTimePitchParam_Rate: AudioUnitParameterID = 0
public let kNewTimePitchParam_Pitch: AudioUnitParameterID = 1
public let kNewTimePitchParam_Overlap: AudioUnitParameterID = 4
public let kNewTimePitchParam_EnablePeakLocking: AudioUnitParameterID = 6

public let kVarispeedParam_PlaybackRate: AudioUnitParameterID = 0
public let kVarispeedParam_PlaybackCents: AudioUnitParameterID = 1

public let kAUGroupParameterID_Volume: AudioUnitParameterID = 7
public let kAUGroupParameterID_Pan: AudioUnitParameterID = 10
public let kAUGroupParameterID_Volume_LSB: AudioUnitParameterID = 39
public let kAUGroupParameterID_Sustain: AudioUnitParameterID = 64
public let kAUGroupParameterID_Sostenuto: AudioUnitParameterID = 66
public let kAUGroupParameterID_AllSoundOff: AudioUnitParameterID = 120
public let kAUGroupParameterID_ResetAllControllers: AudioUnitParameterID = 121
public let kAUGroupParameterID_AllNotesOff: AudioUnitParameterID = 123

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
