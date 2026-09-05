import Foundation

/// Deprecated AudioSession constants. The C AudioSession API is not hosted
/// on Linux; functions remain undeclared so callers cannot fabricate I/O.

public typealias AudioSessionPropertyID = UInt32
public typealias AudioSessionInterruptionType = UInt32
public typealias AudioSessionInterruptionListener = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Void
public typealias AudioSessionPropertyListener = @convention(c) (
    UnsafeMutableRawPointer?,
    AudioSessionPropertyID,
    UInt32,
    UnsafeRawPointer?
) -> Void

public let kAudioSessionNoError: Int32 = 0
public let kAudioSessionNotInitialized: Int32 = atSignedFourCC("!ses")
public let kAudioSessionAlreadyInitialized: Int32 = atSignedFourCC("init")
public let kAudioSessionInitializationError: Int32 = atSignedFourCC("ini?")
public let kAudioSessionUnsupportedPropertyError: Int32 = atSignedFourCC("pty?")
public let kAudioSessionBadPropertySizeError: Int32 = atSignedFourCC("!siz")
public let kAudioSessionNotActiveError: Int32 = atSignedFourCC("!act")
public let kAudioSessionNoCategorySet: Int32 = atSignedFourCC("?cat")
public let kAudioSessionIncompatibleCategory: Int32 = atSignedFourCC("!cat")
public let kAudioSessionUnspecifiedError: Int32 = atSignedFourCC("what")

public let kAudioSessionBeginInterruption: UInt32 = 1
public let kAudioSessionEndInterruption: UInt32 = 0
public let kAudioSessionInterruptionType_ShouldResume: AudioSessionInterruptionType = 1
public let kAudioSessionInterruptionType_ShouldNotResume: AudioSessionInterruptionType = 0

public let kAudioSessionCategory_AmbientSound: UInt32 = atFourCC("ambi")
public let kAudioSessionCategory_SoloAmbientSound: UInt32 = atFourCC("solo")
public let kAudioSessionCategory_MediaPlayback: UInt32 = atFourCC("medi")
public let kAudioSessionCategory_RecordAudio: UInt32 = atFourCC("reca")
public let kAudioSessionCategory_PlayAndRecord: UInt32 = atFourCC("plar")
public let kAudioSessionCategory_AudioProcessing: UInt32 = atFourCC("proc")
public let kAudioSessionCategory_LiveAudio: UInt32 = atFourCC("live")
public let kAudioSessionCategory_UserInterfaceSoundEffects: UInt32 = atFourCC("uise")

public let kAudioSessionMode_Default: UInt32 = atFourCC("dflt")
public let kAudioSessionMode_VoiceChat: UInt32 = atFourCC("vcct")
public let kAudioSessionMode_VideoRecording: UInt32 = atFourCC("vrcd")
public let kAudioSessionMode_Measurement: UInt32 = atFourCC("msmt")
public let kAudioSessionMode_GameChat: UInt32 = atFourCC("gmct")

public let kAudioSessionOverrideAudioRoute_None: UInt32 = 0
public let kAudioSessionOverrideAudioRoute_Speaker: UInt32 = atFourCC("spkr")
public let kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation: UInt32 = 1

public let kAudioSessionProperty_AudioCategory: AudioSessionPropertyID = atFourCC("acat")
public let kAudioSessionProperty_AudioRoute: AudioSessionPropertyID = atFourCC("rout")
public let kAudioSessionProperty_AudioInputAvailable: AudioSessionPropertyID = atFourCC("aiav")
public let kAudioSessionProperty_AudioRouteChange: AudioSessionPropertyID = atFourCC("roch")
public let kAudioSessionProperty_AudioRouteDescription: AudioSessionPropertyID = atFourCC("rdes")
public let kAudioSessionProperty_InterruptionType: AudioSessionPropertyID = atFourCC("type")
public let kAudioSessionProperty_OverrideAudioRoute: AudioSessionPropertyID = atFourCC("ovrd")
public let kAudioSessionProperty_OtherAudioIsPlaying: AudioSessionPropertyID = atFourCC("othr")
public let kAudioSessionProperty_OtherMixableAudioShouldDuck: AudioSessionPropertyID = atFourCC("duck")
public let kAudioSessionProperty_CurrentHardwareSampleRate: AudioSessionPropertyID = atFourCC("chsr")
public let kAudioSessionProperty_CurrentHardwareIOBufferDuration: AudioSessionPropertyID = atFourCC("chib")
public let kAudioSessionProperty_CurrentHardwareOutputVolume: AudioSessionPropertyID = atFourCC("chov")
public let kAudioSessionProperty_CurrentHardwareInputNumberChannels: AudioSessionPropertyID = atFourCC("chic")
public let kAudioSessionProperty_CurrentHardwareOutputNumberChannels: AudioSessionPropertyID = atFourCC("choc")
public let kAudioSessionProperty_CurrentHardwareInputLatency: AudioSessionPropertyID = atFourCC("chil")
public let kAudioSessionProperty_CurrentHardwareOutputLatency: AudioSessionPropertyID = atFourCC("chol")
public let kAudioSessionProperty_PreferredHardwareSampleRate: AudioSessionPropertyID = atFourCC("phsr")
public let kAudioSessionProperty_PreferredHardwareIOBufferDuration: AudioSessionPropertyID = atFourCC("phib")
public let kAudioSessionProperty_Mode: AudioSessionPropertyID = atFourCC("mode")
public let kAudioSessionProperty_InputGainAvailable: AudioSessionPropertyID = atFourCC("igav")
public let kAudioSessionProperty_InputGainScalar: AudioSessionPropertyID = atFourCC("igsc")
public let kAudioSessionProperty_InputSource: AudioSessionPropertyID = atFourCC("isrc")
public let kAudioSessionProperty_InputSources: AudioSessionPropertyID = atFourCC("isrc")
public let kAudioSessionProperty_OutputDestination: AudioSessionPropertyID = atFourCC("odst")
public let kAudioSessionProperty_OutputDestinations: AudioSessionPropertyID = atFourCC("odst")
public let kAudioSessionProperty_OverrideCategoryMixWithOthers: AudioSessionPropertyID = atFourCC("cmix")
public let kAudioSessionProperty_OverrideCategoryDefaultToSpeaker: AudioSessionPropertyID = atFourCC("cspk")
public let kAudioSessionProperty_OverrideCategoryEnableBluetoothInput: AudioSessionPropertyID = atFourCC("cblt")
public let kAudioSessionProperty_ServerDied: AudioSessionPropertyID = atFourCC("died")

public let kAudioSessionRouteChangeReason_Unknown: UInt32 = 0
public let kAudioSessionRouteChangeReason_NewDeviceAvailable: UInt32 = 1
public let kAudioSessionRouteChangeReason_OldDeviceUnavailable: UInt32 = 2
public let kAudioSessionRouteChangeReason_CategoryChange: UInt32 = 3
public let kAudioSessionRouteChangeReason_Override: UInt32 = 4
public let kAudioSessionRouteChangeReason_WakeFromSleep: UInt32 = 6
public let kAudioSessionRouteChangeReason_NoSuitableRouteForCategory: UInt32 = 7
public let kAudioSessionRouteChangeReason_RouteConfigurationChange: UInt32 = 8

public let kAudioSession_AudioRouteChangeKey_Reason = "OutputAudioRouteChangeKey_Reason"
public let kAudioSession_AudioRouteChangeKey_OldRoute = "OutputAudioRouteChangeKey_LastRoute"
