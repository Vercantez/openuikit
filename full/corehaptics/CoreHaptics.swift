import Foundation

public let CHHapticTimeImmediate: TimeInterval = 0

public struct CHHapticError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    public enum Code: Int, Sendable {
        case engineNotRunning = -4805
        case operationNotPermitted = -4806
        case notSupported = -4815
    }

    public let code: Code
    public init(_ code: Code) { self.code = code }
    public var description: String { "Haptic service is unavailable (\(code.rawValue))" }
}

public protocol CHHapticDeviceCapability {
    var supportsHaptics: Bool { get }
    var supportsAudio: Bool { get }
}

private struct PortableHapticCapability: CHHapticDeviceCapability {
    let supportsHaptics = false
    let supportsAudio = false
}

public struct CHHapticEventParameter: Equatable, Sendable {
    public enum ParameterID: String, Sendable {
        case hapticIntensity = "HapticIntensity"
        case hapticSharpness = "HapticSharpness"
        case attackTime = "AttackTime"
        case decayTime = "DecayTime"
        case releaseTime = "ReleaseTime"
        case sustained = "Sustained"
        case audioVolume = "AudioVolume"
        case audioPan = "AudioPan"
        case audioPitch = "AudioPitch"
        case audioBrightness = "AudioBrightness"
    }

    public let parameterID: ParameterID
    public let value: Float

    public init(parameterID: ParameterID, value: Float) {
        self.parameterID = parameterID
        self.value = value
    }
}

public struct CHHapticDynamicParameter: Equatable, Sendable {
    public enum ID: String, Sendable {
        case hapticIntensityControl = "HapticIntensityControl"
        case hapticSharpnessControl = "HapticSharpnessControl"
        case audioVolumeControl = "AudioVolumeControl"
        case audioPanControl = "AudioPanControl"
        case audioBrightnessControl = "AudioBrightnessControl"
        case audioPitchControl = "AudioPitchControl"
    }

    public let parameterID: ID
    public let value: Float
    public let relativeTime: TimeInterval

    public init(parameterID: ID, value: Float, relativeTime: TimeInterval) {
        self.parameterID = parameterID
        self.value = value
        self.relativeTime = relativeTime
    }
}

public struct CHHapticEvent: Equatable, Sendable {
    public enum EventType: String, Sendable {
        case hapticTransient = "HapticTransient"
        case hapticContinuous = "HapticContinuous"
        case audioContinuous = "AudioContinuous"
        case audioCustom = "AudioCustom"
    }

    public let type: EventType
    public let eventParameters: [CHHapticEventParameter]
    public let relativeTime: TimeInterval
    public let duration: TimeInterval

    public init(
        eventType: EventType,
        parameters: [CHHapticEventParameter],
        relativeTime: TimeInterval
    ) {
        type = eventType
        eventParameters = parameters
        self.relativeTime = relativeTime
        duration = 0
    }

    public init(
        eventType: EventType,
        parameters: [CHHapticEventParameter],
        relativeTime: TimeInterval,
        duration: TimeInterval
    ) {
        type = eventType
        eventParameters = parameters
        self.relativeTime = relativeTime
        self.duration = max(0, duration)
    }
}

public final class CHHapticPattern {
    public let events: [CHHapticEvent]
    public let parameters: [CHHapticDynamicParameter]
    public let duration: TimeInterval

    public init(
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter]
    ) throws {
        guard events.allSatisfy({ $0.relativeTime >= 0 && $0.duration >= 0 }) else {
            throw CHHapticError(.operationNotPermitted)
        }
        self.events = events
        self.parameters = parameters
        duration = events.map { $0.relativeTime + $0.duration }.max() ?? 0
    }
}

public protocol CHHapticPatternPlayer: AnyObject {
    func start(atTime time: TimeInterval) throws
    func stop(atTime time: TimeInterval) throws
    func sendParameters(
        _ parameters: [CHHapticDynamicParameter],
        atTime time: TimeInterval
    ) throws
}

public final class CHHapticPortablePatternPlayer: CHHapticPatternPlayer {
    public let pattern: CHHapticPattern
    public private(set) var startAttempts = 0
    public private(set) var isPlaying = false

    public init(pattern: CHHapticPattern) { self.pattern = pattern }

    public func start(atTime time: TimeInterval) throws {
        startAttempts += 1
        isPlaying = false
        throw CHHapticError(.notSupported)
    }

    public func stop(atTime time: TimeInterval) throws {
        isPlaying = false
    }

    public func sendParameters(
        _ parameters: [CHHapticDynamicParameter],
        atTime time: TimeInterval
    ) throws {
        throw CHHapticError(.notSupported)
    }
}

public final class CHHapticEngine {
    public enum StoppedReason: Int, Sendable {
        case audioSessionInterrupt = 1
        case applicationSuspended = 2
        case idleTimeout = 3
        case notifyWhenFinished = 4
        case engineDestroyed = 5
        case gameControllerDisconnect = 6
        case systemError = -1
    }

    public var stoppedHandler: ((StoppedReason) -> Void)?
    public var resetHandler: (() -> Void)?
    public var playsHapticsOnly = false
    public var isAutoShutdownEnabled = true
    public private(set) var isRunning = false
    public private(set) var startAttempts = 0
    public var currentTime: TimeInterval { 0 }

    public init() throws {}

    public static func capabilitiesForHardware() -> CHHapticDeviceCapability {
        PortableHapticCapability()
    }

    public func start() throws {
        startAttempts += 1
        isRunning = false
        throw CHHapticError(.notSupported)
    }

    public func start(completionHandler: @escaping (Error?) -> Void) {
        startAttempts += 1
        isRunning = false
        completionHandler(CHHapticError(.notSupported))
    }

    public func stop(completionHandler: @escaping (Error?) -> Void) {
        isRunning = false
        completionHandler(nil)
    }

    public func makePlayer(
        with pattern: CHHapticPattern
    ) throws -> CHHapticPatternPlayer {
        CHHapticPortablePatternPlayer(pattern: pattern)
    }
}
