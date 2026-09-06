import Foundation

public let kAudioQueueProperty_IsRunning: AudioQueuePropertyID = atFourCC("aqrn")
public let kAudioQueueDeviceProperty_SampleRate: AudioQueuePropertyID = atFourCC("aqsr")
public let kAudioQueueDeviceProperty_NumberChannels: AudioQueuePropertyID = atFourCC("aqdc")
public let kAudioQueueProperty_CurrentDevice: AudioQueuePropertyID = atFourCC("aqcd")
public let kAudioQueueProperty_MagicCookie: AudioQueuePropertyID = atFourCC("aqmc")
public let kAudioQueueProperty_MaximumOutputPacketSize: AudioQueuePropertyID = atFourCC("xops")
public let kAudioQueueProperty_StreamDescription: AudioQueuePropertyID = atFourCC("aqft")
public let kAudioQueueProperty_ChannelLayout: AudioQueuePropertyID = atFourCC("aqcl")
public let kAudioQueueProperty_EnableLevelMetering: AudioQueuePropertyID = atFourCC("aqme")
public let kAudioQueueProperty_CurrentLevelMeter: AudioQueuePropertyID = atFourCC("aqmv")
public let kAudioQueueProperty_CurrentLevelMeterDB: AudioQueuePropertyID = atFourCC("aqmd")
public let kAudioQueueProperty_DecodeBufferSizeFrames: AudioQueuePropertyID = atFourCC("dcbf")
public let kAudioQueueProperty_ConverterError: AudioQueuePropertyID = atFourCC("qcve")
public let kAudioQueueProperty_EnableTimePitch: AudioQueuePropertyID = atFourCC("q_tp")
public let kAudioQueueProperty_TimePitchAlgorithm: AudioQueuePropertyID = atFourCC("qtpa")
public let kAudioQueueProperty_TimePitchBypass: AudioQueuePropertyID = atFourCC("qtpb")
public let kAudioQueueProperty_HardwareCodecPolicy: AudioQueuePropertyID = atFourCC("aqcp")
public let kAudioQueueProperty_ChannelAssignments: AudioQueuePropertyID = atFourCC("aqca")

public let kAudioQueueTimePitchAlgorithm_Spectral: UInt32 = atFourCC("spec")
public let kAudioQueueTimePitchAlgorithm_TimeDomain: UInt32 = atFourCC("tido")
public let kAudioQueueTimePitchAlgorithm_LowQualityZeroLatency: UInt32 = atFourCC("lqzl")
public let kAudioQueueTimePitchAlgorithm_Varispeed: UInt32 = atFourCC("vspd")

public typealias AudioQueueInputCallback = (
    UnsafeMutableRawPointer?,
    AudioQueueRef,
    AudioQueueBufferRef,
    UnsafeRawPointer?,
    UInt32,
    UnsafeRawPointer?
) -> Void

extension AudioQueueProcessingTapFlags {
    public static let preEffects = AudioQueueProcessingTapFlags(rawValue: 1 << 0)
    public static let postEffects = AudioQueueProcessingTapFlags(rawValue: 1 << 1)
    public static let siphon = AudioQueueProcessingTapFlags(rawValue: 1 << 2)
    public static let startOfStream = AudioQueueProcessingTapFlags(rawValue: 1 << 8)
    public static let endOfStream = AudioQueueProcessingTapFlags(rawValue: 1 << 9)
}
