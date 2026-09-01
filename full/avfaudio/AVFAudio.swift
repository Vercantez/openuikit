import Foundation

// MARK: - Portable C ABI stand-ins
//
// The host gate compiles AVFAudio without linking CoreAudio / AudioToolbox /
// CoreMIDI / CoreMedia. These types exist so public signatures type-check.
// They are not a claim of Apple layout, calling convention, or device behavior.

public typealias OSStatus = Int32
public typealias FourCharCode = UInt32
public typealias AudioChannelCount = UInt32
public typealias AudioChannelLayoutTag = UInt32
public typealias AudioChannelLabel = UInt32
public typealias AudioFormatID = UInt32
public typealias AudioFormatFlags = UInt32
public typealias AudioUnit = OpaquePointer
public typealias AudioComponent = OpaquePointer
public typealias MusicSequence = OpaquePointer
public typealias CMAudioFormatDescription = OpaquePointer
public typealias MIDIProtocolID = UInt32
public typealias NSErrorPointer = UnsafeMutablePointer<NSError?>?

public let noErr: OSStatus = 0
public let kAudioFormatLinearPCM: AudioFormatID = 0x6C70636D
public let kAudioFormatFlagIsFloat: AudioFormatFlags = 1 << 0
public let kAudioFormatFlagIsBigEndian: AudioFormatFlags = 1 << 1
public let kAudioFormatFlagIsSignedInteger: AudioFormatFlags = 1 << 2
public let kAudioFormatFlagIsPacked: AudioFormatFlags = 1 << 3
public let kAudioFormatFlagIsNonInterleaved: AudioFormatFlags = 1 << 5
public let kAudioChannelLayoutTag_Mono: AudioChannelLayoutTag = 100 << 16 | 1
public let kAudioChannelLayoutTag_Stereo: AudioChannelLayoutTag = 101 << 16 | 2

public typealias AVAudioChannelCount = UInt32
public typealias AVAudioFrameCount = UInt32
public typealias AVAudioFramePosition = Int64
public typealias AVAudioPacketCount = UInt32
public typealias AVAudioNodeBus = Int
public typealias AVAudio3DVector = AVAudio3DPoint
public typealias AVMusicTimeStamp = Double
public typealias AVBeatRange = _AVBeatRange

public typealias AVAudioNodeCompletionHandler = () -> Void
public typealias AVAudioNodeTapBlock = (AVAudioPCMBuffer, AVAudioTime) -> Void
public typealias AVAudioPlayerNodeCompletionHandler = (AVAudioPlayerNodeCompletionCallbackType) -> Void
public typealias AVAudioConverterInputBlock = (
    AVAudioPacketCount,
    UnsafeMutablePointer<AVAudioConverterInputStatus>
) -> AVAudioBuffer?
public typealias AVAudioIONodeInputBlock = (AVAudioFrameCount) -> UnsafePointer<AudioBufferList>?
public typealias AVAudioEngineManualRenderingBlock = (
    AVAudioFrameCount,
    UnsafeMutablePointer<AudioBufferList>,
    UnsafeMutablePointer<OSStatus>?
) -> AVAudioEngineManualRenderingStatus
public typealias AVAudioSinkNodeReceiverBlock = (
    UnsafePointer<AudioTimeStamp>,
    AVAudioFrameCount,
    UnsafePointer<AudioBufferList>
) -> OSStatus
public typealias AVAudioSourceNodeRenderBlock = (
    UnsafeMutablePointer<ObjCBool>,
    UnsafePointer<AudioTimeStamp>,
    AVAudioFrameCount,
    UnsafeMutablePointer<AudioBufferList>
) -> OSStatus
public typealias AVAudioSequencerUserCallback = (AVMusicTrack, Data, AVMusicTimeStamp) -> Void
public typealias AVMIDIPlayerCompletionHandler = () -> Void
public typealias AVMusicEventEnumerationBlock = (
    AVMusicEvent,
    UnsafeMutablePointer<AVMusicTimeStamp>,
    UnsafeMutablePointer<ObjCBool>
) -> Void
public typealias AUMIDIOutputEventBlock = (
    Int64,
    UInt8,
    Int,
    UnsafePointer<UInt8>
) -> OSStatus
public typealias AUMIDIEventListBlock = (
    UnsafePointer<MIDIEventList>
) -> OSStatus

public let AVAUDIOENGINE_HAVE_AUAUDIOUNIT: Int32 = 0
public let AVAUDIOENGINE_HAVE_MUSICPLAYER: Int32 = 0
public let AVAUDIOFORMAT_HAVE_CMFORMATDESCRIPTION: Int32 = 0
public let AVAUDIOIONODE_HAVE_AUDIOUNIT: Int32 = 0
public let AVAUDIONODE_HAVE_AUAUDIOUNIT: Int32 = 0
public let AVAUDIOUNITCOMPONENT_HAVE_AUDIOCOMPONENT: Int32 = 0
public let AVAUDIOUNIT_HAVE_AUDIOUNIT: Int32 = 0

public let AVAudioBitRateStrategy_Constant = "AVAudioBitRateStrategy_Constant"
public let AVAudioBitRateStrategy_LongTermAverage = "AVAudioBitRateStrategy_LongTermAverage"
public let AVAudioBitRateStrategy_Variable = "AVAudioBitRateStrategy_Variable"
public let AVAudioBitRateStrategy_VariableConstrained = "AVAudioBitRateStrategy_VariableConstrained"
public let AVAudioFileTypeKey = "AVAudioFileTypeKey"

public let AVAudioSessionInterruptionOptionKey = "AVAudioSessionInterruptionOptionKey"
public let AVAudioSessionInterruptionReasonKey = "AVAudioSessionInterruptionReasonKey"
public let AVAudioSessionInterruptionTypeKey = "AVAudioSessionInterruptionTypeKey"
public let AVAudioSessionInterruptionWasSuspendedKey = "AVAudioSessionInterruptionWasSuspendedKey"
public let AVAudioSessionMicrophoneInjectionIsAvailableKey =
    "AVAudioSessionMicrophoneInjectionIsAvailableKey"
public let AVAudioSessionRenderingModeNewRenderingModeKey =
    "AVAudioSessionRenderingModeNewRenderingModeKey"
public let AVAudioSessionRouteChangePreviousRouteKey = "AVAudioSessionRouteChangePreviousRouteKey"
public let AVAudioSessionRouteChangeReasonKey = "AVAudioSessionRouteChangeReasonKey"
public let AVAudioSessionSilenceSecondaryAudioHintTypeKey =
    "AVAudioSessionSilenceSecondaryAudioHintTypeKey"
public let AVAudioSessionSpatialAudioEnabledKey = "AVAudioSessionSpatialAudioEnabledKey"

public let AVSpeechUtteranceMinimumSpeechRate: Float = 0.0
public let AVSpeechUtteranceMaximumSpeechRate: Float = 1.0
public let AVSpeechUtteranceDefaultSpeechRate: Float = 0.5
public let AVSpeechSynthesisVoiceIdentifierAlex = "com.apple.speech.synthesis.voice.Alex"
public let AVSpeechSynthesisIPANotationAttribute = "AVSpeechSynthesisIPANotationAttribute"

public let AVFormatIDKey = "AVFormatIDKey"
public let AVSampleRateKey = "AVSampleRateKey"
public let AVNumberOfChannelsKey = "AVNumberOfChannelsKey"
public let AVLinearPCMBitDepthKey = "AVLinearPCMBitDepthKey"
public let AVLinearPCMIsBigEndianKey = "AVLinearPCMIsBigEndianKey"
public let AVLinearPCMIsFloatKey = "AVLinearPCMIsFloatKey"
public let AVLinearPCMIsNonInterleaved = "AVLinearPCMIsNonInterleaved"
public let AVChannelLayoutKey = "AVChannelLayoutKey"
public let AVEncoderAudioQualityKey = "AVEncoderAudioQualityKey"
public let AVEncoderAudioQualityForVBRKey = "AVEncoderAudioQualityForVBRKey"
public let AVEncoderBitRateKey = "AVEncoderBitRateKey"
public let AVEncoderBitRatePerChannelKey = "AVEncoderBitRatePerChannelKey"
public let AVEncoderBitRateStrategyKey = "AVEncoderBitRateStrategyKey"
public let AVEncoderBitDepthHintKey = "AVEncoderBitDepthHintKey"
public let AVEncoderASPFrequencyKey = "AVEncoderASPFrequencyKey"
public let AVEncoderContentSourceKey = "AVEncoderContentSourceKey"
public let AVEncoderDynamicRangeControlConfigurationKey =
    "AVEncoderDynamicRangeControlConfigurationKey"
public let AVSampleRateConverterAlgorithmKey = "AVSampleRateConverterAlgorithmKey"
public let AVSampleRateConverterAudioQualityKey = "AVSampleRateConverterAudioQualityKey"
public let AVSampleRateConverterAlgorithm_Mastering = "Mastering"
public let AVSampleRateConverterAlgorithm_MinimumPhase = "MinimumPhase"
public let AVSampleRateConverterAlgorithm_Normal = "Normal"

public let AVAudioUnitTypeOutput = "auou"
public let AVAudioUnitTypeMusicDevice = "aumu"
public let AVAudioUnitTypeMusicEffect = "aumf"
public let AVAudioUnitTypeFormatConverter = "aufc"
public let AVAudioUnitTypeEffect = "aufx"
public let AVAudioUnitTypeMixer = "aumx"
public let AVAudioUnitTypePanner = "aupn"
public let AVAudioUnitTypeGenerator = "augn"
public let AVAudioUnitTypeOfflineEffect = "auol"
public let AVAudioUnitTypeMIDIProcessor = "aumi"
public let AVAudioUnitManufacturerNameApple = "Apple"

public var AVMusicTimeStampEndOfTrack: Double { Double.greatestFiniteMagnitude }

public struct AudioStreamBasicDescription: Equatable, Sendable {
    public var mSampleRate: Double
    public var mFormatID: AudioFormatID
    public var mFormatFlags: AudioFormatFlags
    public var mBytesPerPacket: UInt32
    public var mFramesPerPacket: UInt32
    public var mBytesPerFrame: UInt32
    public var mChannelsPerFrame: UInt32
    public var mBitsPerChannel: UInt32
    public var mReserved: UInt32

    public init(
        mSampleRate: Double = 0,
        mFormatID: AudioFormatID = 0,
        mFormatFlags: AudioFormatFlags = 0,
        mBytesPerPacket: UInt32 = 0,
        mFramesPerPacket: UInt32 = 0,
        mBytesPerFrame: UInt32 = 0,
        mChannelsPerFrame: UInt32 = 0,
        mBitsPerChannel: UInt32 = 0,
        mReserved: UInt32 = 0
    ) {
        self.mSampleRate = mSampleRate
        self.mFormatID = mFormatID
        self.mFormatFlags = mFormatFlags
        self.mBytesPerPacket = mBytesPerPacket
        self.mFramesPerPacket = mFramesPerPacket
        self.mBytesPerFrame = mBytesPerFrame
        self.mChannelsPerFrame = mChannelsPerFrame
        self.mBitsPerChannel = mBitsPerChannel
        self.mReserved = mReserved
    }
}

public struct AudioBuffer {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?

    public init(
        mNumberChannels: UInt32 = 0,
        mDataByteSize: UInt32 = 0,
        mData: UnsafeMutableRawPointer? = nil
    ) {
        self.mNumberChannels = mNumberChannels
        self.mDataByteSize = mDataByteSize
        self.mData = mData
    }
}

public struct AudioBufferList {
    public var mNumberBuffers: UInt32
    public var mBuffers: AudioBuffer
    public init(mNumberBuffers: UInt32 = 0, mBuffers: AudioBuffer = AudioBuffer()) {
        self.mNumberBuffers = mNumberBuffers
        self.mBuffers = mBuffers
    }
}

public struct AudioChannelLayout: Equatable, Sendable {
    public var mChannelLayoutTag: AudioChannelLayoutTag
    public var mChannelBitmap: UInt32
    public var mNumberChannelDescriptions: UInt32
    public init(
        mChannelLayoutTag: AudioChannelLayoutTag = 0,
        mChannelBitmap: UInt32 = 0,
        mNumberChannelDescriptions: UInt32 = 0
    ) {
        self.mChannelLayoutTag = mChannelLayoutTag
        self.mChannelBitmap = mChannelBitmap
        self.mNumberChannelDescriptions = mNumberChannelDescriptions
    }
}

public struct AudioTimeStamp: Equatable, Sendable {
    public var mSampleTime: Double
    public var mHostTime: UInt64
    public var mRateScalar: Double
    public var mWordClockTime: UInt64
    public var mFlags: UInt32
    public var mReserved: UInt32
    public init(
        mSampleTime: Double = 0,
        mHostTime: UInt64 = 0,
        mRateScalar: Double = 1,
        mWordClockTime: UInt64 = 0,
        mFlags: UInt32 = 0,
        mReserved: UInt32 = 0
    ) {
        self.mSampleTime = mSampleTime
        self.mHostTime = mHostTime
        self.mRateScalar = mRateScalar
        self.mWordClockTime = mWordClockTime
        self.mFlags = mFlags
        self.mReserved = mReserved
    }
}

public struct AudioStreamPacketDescription: Equatable, Sendable {
    public var mStartOffset: Int64
    public var mVariableFramesInPacket: UInt32
    public var mDataByteSize: UInt32
    public init(
        mStartOffset: Int64 = 0,
        mVariableFramesInPacket: UInt32 = 0,
        mDataByteSize: UInt32 = 0
    ) {
        self.mStartOffset = mStartOffset
        self.mVariableFramesInPacket = mVariableFramesInPacket
        self.mDataByteSize = mDataByteSize
    }
}

public struct AudioStreamPacketDependencyDescription: Equatable, Sendable {
    public var mFlags: UInt32
    public var mNumberIndependentPackets: UInt32
    public init(mFlags: UInt32 = 0, mNumberIndependentPackets: UInt32 = 0) {
        self.mFlags = mFlags
        self.mNumberIndependentPackets = mNumberIndependentPackets
    }
}

public struct AudioComponentDescription: Equatable, Sendable {
    public var componentType: FourCharCode
    public var componentSubType: FourCharCode
    public var componentManufacturer: FourCharCode
    public var componentFlags: UInt32
    public var componentFlagsMask: UInt32
    public init(
        componentType: FourCharCode = 0,
        componentSubType: FourCharCode = 0,
        componentManufacturer: FourCharCode = 0,
        componentFlags: UInt32 = 0,
        componentFlagsMask: UInt32 = 0
    ) {
        self.componentType = componentType
        self.componentSubType = componentSubType
        self.componentManufacturer = componentManufacturer
        self.componentFlags = componentFlags
        self.componentFlagsMask = componentFlagsMask
    }
}

public struct AudioComponentInstantiationOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct MIDIEventList {
    public var protocolID: MIDIProtocolID
    public var numPackets: UInt32
    public init(protocolID: MIDIProtocolID = 0, numPackets: UInt32 = 0) {
        self.protocolID = protocolID
        self.numPackets = numPackets
    }
}

public struct _AVBeatRange: Equatable, Sendable {
    public var start: AVMusicTimeStamp
    public var length: AVMusicTimeStamp
    public init(start: AVMusicTimeStamp = 0, length: AVMusicTimeStamp = 0) {
        self.start = start
        self.length = length
    }
}

public func AVMakeBeatRange(
    _ startBeat: AVMusicTimeStamp,
    _ lengthInBeats: AVMusicTimeStamp
) -> AVBeatRange {
    AVBeatRange(start: startBeat, length: lengthInBeats)
}

/// Fail-closed error used when Linux cannot provide Apple hardware, codec, or
/// entitlement behavior. Never presented as a successful Apple service result.
public struct AVAudioError: Error, Equatable, CustomStringConvertible, Sendable {
    public enum Code: Int, Sendable {
        case notSupported = -11800
        case hardwareNotAvailable = -11801
        case permissionDenied = -11802
        case codecUnavailable = -11803
        case fileFormatUnsupported = -11804
        case engineCannotStart = -11805
        case operationCancelled = -11806
    }

    public let code: Code
    public let message: String
    public var description: String { "AVAudioError(\(code.rawValue)): \(message)" }

    public init(_ code: Code, _ message: String) {
        self.code = code
        self.message = message
    }

    public static let hardwareNotAvailable = AVAudioError(
        .hardwareNotAvailable,
        "No Apple audio hardware, session daemon, or codec runtime is available on this Linux host."
    )
    public static let notSupported = AVAudioError(
        .notSupported,
        "This AVFAudio operation is not supported on the Linux starting point."
    )
    public static let codecUnavailable = AVAudioError(
        .codecUnavailable,
        "No Apple audio codec is installed; compressed encode/decode is fail-closed."
    )
    public static let permissionDenied = AVAudioError(
        .permissionDenied,
        "Microphone, personal-voice, and injection entitlements are unavailable."
    )
}

func avfaudioLock<T>(_ lock: NSLock, _ body: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return body()
}

func avaudioNSError(_ error: AVAudioError) -> NSError {
    NSError(
        domain: "AVFAudio",
        code: error.code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: error.message]
    )
}

public enum AVFAudioPortable {
    public static let linuxStartingPoint = true
    public static let hardwareOutputAvailable = false
    public static let hardwareInputAvailable = false
    public static let appleSpeechVoicesAvailable = false
}

public func AVAudioMake3DPoint(_ x: Float, _ y: Float, _ z: Float) -> AVAudio3DPoint {
    AVAudio3DPoint(x: x, y: y, z: z)
}

public func AVAudioMake3DVector(_ x: Float, _ y: Float, _ z: Float) -> AVAudio3DVector {
    AVAudio3DPoint(x: x, y: y, z: z)
}

public func AVAudioMake3DAngularOrientation(
    _ yaw: Float,
    _ pitch: Float,
    _ roll: Float
) -> AVAudio3DAngularOrientation {
    AVAudio3DAngularOrientation(yaw: yaw, pitch: pitch, roll: roll)
}

public func AVAudioMake3DVectorOrientation(
    _ forward: AVAudio3DVector,
    _ up: AVAudio3DVector
) -> AVAudio3DVectorOrientation {
    AVAudio3DVectorOrientation(forward: forward, up: up)
}

public struct AVAudio3DPoint: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public init() {
        self.x = 0
        self.y = 0
        self.z = 0
    }
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct AVAudio3DAngularOrientation: Equatable, Hashable, Sendable {
    public var yaw: Float
    public var pitch: Float
    public var roll: Float
    public init() {
        self.yaw = 0
        self.pitch = 0
        self.roll = 0
    }
    public init(yaw: Float, pitch: Float, roll: Float) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
    }
}

public struct AVAudio3DVectorOrientation: Equatable, Hashable, Sendable {
    public var forward: AVAudio3DVector
    public var up: AVAudio3DVector
    public init() {
        self.forward = AVAudio3DPoint()
        self.up = AVAudio3DPoint(x: 0, y: 1, z: 0)
    }
    public init(forward: AVAudio3DVector, up: AVAudio3DVector) {
        self.forward = forward
        self.up = up
    }
}

open class AUAudioUnit: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public extension NSNotification.Name {
    static let AVAudioEngineConfigurationChange = NSNotification.Name(
        "AVAudioEngineConfigurationChangeNotification"
    )
    static let AVAudioUnitComponentTagsDidChange = NSNotification.Name(
        "AVAudioUnitComponentTagsDidChangeNotification"
    )
}
