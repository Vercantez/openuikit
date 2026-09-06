import Foundation

/// Option-set and enum overlays whose payloads are corroborated by the pinned
/// dotnet-macios bindings (`src/AudioUnit/AUEnums.cs`, `src/AudioToolbox/Enums.cs`,
/// `src/AudioToolbox/AudioFile.cs`) and the compact public surface names.

public struct AU3DMixerRenderingFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let k3DMixerRenderingFlags_InterAuralDelay = AU3DMixerRenderingFlags(rawValue: 1 << 0)
    public static let k3DMixerRenderingFlags_DopplerShift = AU3DMixerRenderingFlags(rawValue: 1 << 1)
    public static let k3DMixerRenderingFlags_DistanceAttenuation = AU3DMixerRenderingFlags(rawValue: 1 << 2)
    public static let k3DMixerRenderingFlags_DistanceFilter = AU3DMixerRenderingFlags(rawValue: 1 << 3)
    public static let k3DMixerRenderingFlags_DistanceDiffusion = AU3DMixerRenderingFlags(rawValue: 1 << 4)
    public static let k3DMixerRenderingFlags_LinearDistanceAttenuation = AU3DMixerRenderingFlags(rawValue: 1 << 5)
    public static let k3DMixerRenderingFlags_ConstantReverbBlend = AU3DMixerRenderingFlags(rawValue: 1 << 6)
}

public struct AUSpatialMixerRenderingFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let spatialMixerRenderingFlags_InterAuralDelay = AUSpatialMixerRenderingFlags(rawValue: 1 << 0)
    public static let spatialMixerRenderingFlags_DistanceAttenuation = AUSpatialMixerRenderingFlags(rawValue: 1 << 2)
}

public struct AUHostTransportStateFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let changed = AUHostTransportStateFlags(rawValue: 1)
    public static let moving = AUHostTransportStateFlags(rawValue: 2)
    public static let recording = AUHostTransportStateFlags(rawValue: 4)
    public static let cycling = AUHostTransportStateFlags(rawValue: 8)
}

public struct AUScheduledAudioSliceFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let scheduledAudioSliceFlag_Complete = AUScheduledAudioSliceFlags(rawValue: 0x01)
    public static let scheduledAudioSliceFlag_BeganToRender = AUScheduledAudioSliceFlags(rawValue: 0x02)
    public static let scheduledAudioSliceFlag_BeganToRenderLate = AUScheduledAudioSliceFlags(rawValue: 0x04)
    public static let scheduledAudioSliceFlag_Loop = AUScheduledAudioSliceFlags(rawValue: 0x08)
    public static let scheduledAudioSliceFlag_Interrupt = AUScheduledAudioSliceFlags(rawValue: 0x10)
    public static let scheduledAudioSliceFlag_InterruptAtLoop = AUScheduledAudioSliceFlags(rawValue: 0x20)
}

public struct AudioBytePacketTranslationFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let bytePacketTranslationFlag_IsEstimate = AudioBytePacketTranslationFlags(rawValue: 1)
}

public struct AudioSettingsFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let expertParameter = AudioSettingsFlags(rawValue: 1 << 0)
    public static let invisibleParameter = AudioSettingsFlags(rawValue: 1 << 1)
    public static let metaParameter = AudioSettingsFlags(rawValue: 1 << 2)
    public static let userInterfaceParameter = AudioSettingsFlags(rawValue: 1 << 3)
}

public enum AU3DMixerAttenuationCurve: UInt32, Sendable, Hashable {
    case k3DMixerAttenuationCurve_Power = 0
    case k3DMixerAttenuationCurve_Exponential = 1
    case k3DMixerAttenuationCurve_Inverse = 2
    case k3DMixerAttenuationCurve_Linear = 3
}

public enum AUSpatialMixerAttenuationCurve: UInt32, Sendable, Hashable {
    case spatialMixerAttenuationCurve_Power = 0
    case spatialMixerAttenuationCurve_Exponential = 1
    case spatialMixerAttenuationCurve_Inverse = 2
    case spatialMixerAttenuationCurve_Linear = 3
}

public enum AUSpatialMixerOutputType: UInt32, Sendable, Hashable {
    case spatialMixerOutputType_Headphones = 1
    case spatialMixerOutputType_BuiltInSpeakers = 2
    case spatialMixerOutputType_ExternalSpeakers = 3
}

public enum AUSpatialMixerPointSourceInHeadMode: UInt32, Sendable, Hashable {
    case spatialMixerPointSourceInHeadMode_Mono = 0
    case spatialMixerPointSourceInHeadMode_Bypass = 1
}

public enum AUSpatialMixerSourceMode: UInt32, Sendable, Hashable {
    case spatialMixerSourceMode_SpatializeIfMono = 0
    case spatialMixerSourceMode_Bypass = 1
    case spatialMixerSourceMode_PointSource = 2
    case spatialMixerSourceMode_AmbienceBed = 3
}

public enum AUSpatialMixerPersonalizedHRTFMode: UInt32, Sendable, Hashable {
    case off = 0
    case on = 1
    case `auto` = 2
}

public enum AUSpatializationAlgorithm: UInt32, Sendable, Hashable {
    case spatializationAlgorithm_EqualPowerPanning = 0
    case spatializationAlgorithm_SphericalHead = 1
    case spatializationAlgorithm_HRTF = 2
    case spatializationAlgorithm_SoundField = 3
    case spatializationAlgorithm_VectorBasedPanning = 4
    case spatializationAlgorithm_StereoPassThrough = 5
    case spatializationAlgorithm_HRTFHQ = 6
    case spatializationAlgorithm_UseOutputType = 7
}

public enum AUReverbRoomType: UInt32, Sendable, Hashable {
    case reverbRoomType_SmallRoom = 0
    case reverbRoomType_MediumRoom = 1
    case reverbRoomType_LargeRoom = 2
    case reverbRoomType_MediumHall = 3
    case reverbRoomType_LargeHall = 4
    case reverbRoomType_Plate = 5
    case reverbRoomType_MediumChamber = 6
    case reverbRoomType_LargeChamber = 7
    case reverbRoomType_Cathedral = 8
    case reverbRoomType_LargeRoom2 = 9
    case reverbRoomType_MediumHall2 = 10
    case reverbRoomType_MediumHall3 = 11
    case reverbRoomType_LargeHall2 = 12
}

public enum AUAudioMixRenderingStyle: UInt32, Sendable, Hashable {
    case audioMixRenderingStyle_Cinematic = 0
    case audioMixRenderingStyle_Studio = 1
    case audioMixRenderingStyle_InFrame = 2
    case audioMixRenderingStyle_CinematicBackgroundStem = 3
    case audioMixRenderingStyle_CinematicForegroundStem = 4
    case audioMixRenderingStyle_StudioForegroundStem = 5
    case audioMixRenderingStyle_InFrameForegroundStem = 6
    case audioMixRenderingStyle_Standard = 7
    case audioMixRenderingStyle_StudioBackgroundStem = 8
    case audioMixRenderingStyle_InFrameBackgroundStem = 9
}

public enum AUVoiceIOOtherAudioDuckingLevel: UInt32, Sendable, Hashable {
    case `default` = 0
    case min = 10
    case mid = 20
    case max = 30
}

public enum AUVoiceIOSpeechActivityEvent: UInt32, Sendable, Hashable {
    case hasStarted = 0
    case hasEnded = 1
}

public enum AudioBalanceFadeType: UInt32, Sendable, Hashable {
    case maxUnityGain = 0
    case equalPower = 1
}

public enum AudioPanningMode: UInt32, Sendable, Hashable {
    case panningMode_SoundField = 3
    case panningMode_VectorBasedPanning = 4
}

public let kAudioFileLoopDirection_NoLooping: UInt32 = 0
public let kAudioFileLoopDirection_Forward: UInt32 = 1
public let kAudioFileLoopDirection_ForwardAndBackward: UInt32 = 2
public let kAudioFileLoopDirection_Backward: UInt32 = 3

public let kAudioFileMarkerType_Generic: UInt32 = 0

public let kAudioUnitClumpID_System: UInt32 = 0
public let kAudioUnitParameterName_Full: Int = -1
