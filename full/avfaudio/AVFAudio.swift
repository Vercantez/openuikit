import Foundation
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(CoreMIDI)
import CoreMIDI
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

// MARK: - AVFAudio-owned typealiases

public typealias AVAudioChannelCount = UInt32
public typealias AVAudioFrameCount = UInt32
public typealias AVAudioFramePosition = Int64
public typealias AVAudioPacketCount = UInt32
public typealias AVAudioNodeBus = Int
public typealias AVAudio3DVector = AVAudio3DPoint
public typealias AVMusicTimeStamp = Double
public typealias AVBeatRange = AVAudioBeatRange

public typealias AVAudioNodeCompletionHandler = () -> Void
public typealias AVAudioNodeTapBlock = (AVAudioPCMBuffer, AVAudioTime) -> Void
public typealias AVAudioPlayerNodeCompletionHandler = (AVAudioPlayerNodeCompletionCallbackType) -> Void
public typealias AVAudioConverterInputBlock = (
    AVAudioPacketCount,
    UnsafeMutablePointer<AVAudioConverterInputStatus>
) -> AVAudioBuffer?
public typealias AVAudioSequencerUserCallback = (AVMusicTrack, Data, AVMusicTimeStamp) -> Void
public typealias AVMIDIPlayerCompletionHandler = () -> Void
public typealias AVMusicEventEnumerationBlock = (
    AVMusicEvent,
    UnsafeMutablePointer<AVMusicTimeStamp>,
    UnsafeMutablePointer<ObjCBool>
) -> Void

#if canImport(CoreAudioTypes) || canImport(AudioToolbox)
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
public typealias AUMIDIOutputEventBlock = (
    Int64,
    UInt8,
    Int,
    UnsafePointer<UInt8>
) -> OSStatus
#endif

#if canImport(CoreMIDI)
public typealias AUMIDIEventListBlock = (UnsafePointer<MIDIEventList>) -> OSStatus
#endif

// MARK: - Compile-only key symbols (values are not claimed as Apple CFString/FourCC ABI)

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

public let AVSpeechUtteranceMinimumSpeechRate: Float = 0
public let AVSpeechUtteranceMaximumSpeechRate: Float = 1
public let AVSpeechUtteranceDefaultSpeechRate: Float = 0.5
public let AVSpeechSynthesisVoiceIdentifierAlex = "AVSpeechSynthesisVoiceIdentifierAlex"
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
public let AVSampleRateConverterAlgorithm_Mastering = "AVSampleRateConverterAlgorithm_Mastering"
public let AVSampleRateConverterAlgorithm_MinimumPhase = "AVSampleRateConverterAlgorithm_MinimumPhase"
public let AVSampleRateConverterAlgorithm_Normal = "AVSampleRateConverterAlgorithm_Normal"

public let AVAudioUnitTypeOutput = "AVAudioUnitTypeOutput"
public let AVAudioUnitTypeMusicDevice = "AVAudioUnitTypeMusicDevice"
public let AVAudioUnitTypeMusicEffect = "AVAudioUnitTypeMusicEffect"
public let AVAudioUnitTypeFormatConverter = "AVAudioUnitTypeFormatConverter"
public let AVAudioUnitTypeEffect = "AVAudioUnitTypeEffect"
public let AVAudioUnitTypeMixer = "AVAudioUnitTypeMixer"
public let AVAudioUnitTypePanner = "AVAudioUnitTypePanner"
public let AVAudioUnitTypeGenerator = "AVAudioUnitTypeGenerator"
public let AVAudioUnitTypeOfflineEffect = "AVAudioUnitTypeOfflineEffect"
public let AVAudioUnitTypeMIDIProcessor = "AVAudioUnitTypeMIDIProcessor"
public let AVAudioUnitManufacturerNameApple = "AVAudioUnitManufacturerNameApple"

public var AVMusicTimeStampEndOfTrack: Double { Double(Int64.max) }

public struct AVAudioBeatRange: Equatable, Sendable {
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
    AVAudioBeatRange(start: startBeat, length: lengthInBeats)
}

func avfaudioLock<T>(_ lock: NSLock, _ body: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return body()
}

func avfaudioLock<T>(_ lock: NSLock, _ body: () throws -> T) throws -> T {
    lock.lock()
    defer { lock.unlock() }
    return try body()
}

func avfaudioHostUnavailableError(
    _ message: String = "No AVFAudio host audio service is available."
) -> NSError {
    NSError(
        domain: "AVFAudio.host",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}

enum AVFAudioCallbackDelivery {
    static let reentrancyKey = DispatchSpecificKey<UInt8>()
    static let queue: DispatchQueue = {
        let queue = DispatchQueue(label: "AVFAudio.callback")
        queue.setSpecific(key: reentrancyKey, value: 0)
        return queue
    }()

    final class Once: @unchecked Sendable {
        private let lock = NSLock()
        private var done = false
        func claim() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if done { return false }
            done = true
            return true
        }
    }

    static func deliverExactlyOnce(_ body: @escaping () -> Void) {
        let once = Once()
        queue.async {
            guard once.claim() else { return }
            let depth = queue.getSpecific(key: reentrancyKey) ?? 0
            guard depth == 0 else { return }
            queue.setSpecific(key: reentrancyKey, value: 1)
            defer { queue.setSpecific(key: reentrancyKey, value: 0) }
            body()
        }
    }
}

@_spi(OpenUIKitHost)
public enum AVFAudioHostAvailability {
    public static var audioOutputAvailable: Bool { false }
    public static var audioInputAvailable: Bool { false }
    public static var appleSpeechVoicesAvailable: Bool { false }
    public static var callbackQueue: DispatchQueue { AVFAudioCallbackDelivery.queue }
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

public extension NSNotification.Name {
    static let AVAudioEngineConfigurationChange = NSNotification.Name(
        "AVAudioEngineConfigurationChangeNotification"
    )
    static let AVAudioUnitComponentTagsDidChange = NSNotification.Name(
        "AVAudioUnitComponentTagsDidChangeNotification"
    )
}
