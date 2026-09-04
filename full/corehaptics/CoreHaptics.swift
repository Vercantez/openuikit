import Foundation

// MARK: - Constants

/// Documented AHAP / Core Haptics immediate-time sentinel. Apple's public
/// overlay spells this as a `TimeInterval` getter equal to `0`.
public var CHHapticTimeImmediate: TimeInterval { 0 }

/// Linux fallback spelling of the exported `CoreHapticsErrorDomain` symbol.
/// The Apple binary payload is unobserved; see `oracle-questions.tsv`.
public let CoreHapticsErrorDomain = "CoreHapticsErrorDomain"

/// Linux fallback spellings of the exported audio-resource option keys.
/// The Apple `NSString` payloads are unobserved.
public let CHHapticAudioResourceKeyLoopEnabled = "CHHapticAudioResourceKeyLoopEnabled"
public let CHHapticAudioResourceKeyUseVolumeEnvelope =
    "CHHapticAudioResourceKeyUseVolumeEnvelope"

public typealias CHHapticAudioResourceID = Int
public typealias CHHapticAudioResourceKey = NSString
public typealias CHHapticAdvancedPatternPlayerCompletionHandler = ((any Error)?) -> Void

// MARK: - Errors

/// Bridged Core Haptics error.
///
/// Raw values come from the pinned `dotnet/macios` `CHHapticErrorCode` enum
/// (`EngineNotRunning = -4805` … `MemoryError = -4899`). Foundation's
/// protocol-default `hash(into:)` / `hashValue` witnesses trap on this
/// toolchain, so those Hashable members are provided here.
@frozen
public struct CHHapticError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = CHHapticError

        case engineNotRunning = -4805
        case operationNotPermitted = -4806
        case engineStartTimeout = -4808
        case notSupported = -4809
        case serverInitFailed = -4810
        case serverInterrupted = -4811
        case invalidPatternPlayer = -4812
        case invalidPatternData = -4813
        case invalidPatternDictionary = -4814
        case invalidAudioSession = -4815
        case invalidEngineParameter = -4816
        case invalidParameterType = -4820
        case invalidEventType = -4821
        case invalidEventTime = -4822
        case invalidEventDuration = -4823
        case invalidAudioResource = -4824
        case resourceNotAvailable = -4825
        case badEventEntry = -4830
        case badParameterEntry = -4831
        case invalidTime = -4840
        case fileNotFound = -4851
        case insufficientPower = -4897
        case unknownError = -4898
        case memoryError = -4899
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { CoreHapticsErrorDomain }

    public static var engineNotRunning: Code { .engineNotRunning }
    public static var operationNotPermitted: Code { .operationNotPermitted }
    public static var engineStartTimeout: Code { .engineStartTimeout }
    public static var notSupported: Code { .notSupported }
    public static var serverInitFailed: Code { .serverInitFailed }
    public static var serverInterrupted: Code { .serverInterrupted }
    public static var invalidPatternPlayer: Code { .invalidPatternPlayer }
    public static var invalidPatternData: Code { .invalidPatternData }
    public static var invalidPatternDictionary: Code { .invalidPatternDictionary }
    public static var invalidAudioSession: Code { .invalidAudioSession }
    public static var invalidEngineParameter: Code { .invalidEngineParameter }
    public static var invalidParameterType: Code { .invalidParameterType }
    public static var invalidEventType: Code { .invalidEventType }
    public static var invalidEventTime: Code { .invalidEventTime }
    public static var invalidEventDuration: Code { .invalidEventDuration }
    public static var invalidAudioResource: Code { .invalidAudioResource }
    public static var resourceNotAvailable: Code { .resourceNotAvailable }
    public static var badEventEntry: Code { .badEventEntry }
    public static var badParameterEntry: Code { .badParameterEntry }
    public static var invalidTime: Code { .invalidTime }
    public static var fileNotFound: Code { .fileNotFound }
    public static var insufficientPower: Code { .insufficientPower }
    public static var unknownError: Code { .unknownError }
    public static var memoryError: Code { .memoryError }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

// MARK: - Event / parameter / pattern identity newtypes

/// Raw string payloads match Apple's public AHAP schema (`HapticIntensity`,
/// `HapticTransient`, `Version`, …) and the original lane's spellings.
extension CHHapticEvent {
    public struct ParameterID: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let hapticIntensity = ParameterID(rawValue: "HapticIntensity")
        public static let hapticSharpness = ParameterID(rawValue: "HapticSharpness")
        public static let attackTime = ParameterID(rawValue: "AttackTime")
        public static let decayTime = ParameterID(rawValue: "DecayTime")
        public static let releaseTime = ParameterID(rawValue: "ReleaseTime")
        public static let sustained = ParameterID(rawValue: "Sustained")
        public static let audioVolume = ParameterID(rawValue: "AudioVolume")
        public static let audioPitch = ParameterID(rawValue: "AudioPitch")
        public static let audioPan = ParameterID(rawValue: "AudioPan")
        public static let audioBrightness = ParameterID(rawValue: "AudioBrightness")
    }

    public struct EventType: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let hapticTransient = EventType(rawValue: "HapticTransient")
        public static let hapticContinuous = EventType(rawValue: "HapticContinuous")
        public static let audioContinuous = EventType(rawValue: "AudioContinuous")
        public static let audioCustom = EventType(rawValue: "AudioCustom")
    }
}

extension CHHapticDynamicParameter {
    public struct ID: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let hapticIntensityControl = ID(rawValue: "HapticIntensityControl")
        public static let hapticSharpnessControl = ID(rawValue: "HapticSharpnessControl")
        public static let hapticAttackTimeControl = ID(rawValue: "HapticAttackTimeControl")
        public static let hapticDecayTimeControl = ID(rawValue: "HapticDecayTimeControl")
        public static let hapticReleaseTimeControl = ID(rawValue: "HapticReleaseTimeControl")
        public static let audioVolumeControl = ID(rawValue: "AudioVolumeControl")
        public static let audioPanControl = ID(rawValue: "AudioPanControl")
        public static let audioBrightnessControl = ID(rawValue: "AudioBrightnessControl")
        public static let audioPitchControl = ID(rawValue: "AudioPitchControl")
        public static let audioAttackTimeControl = ID(rawValue: "AudioAttackTimeControl")
        public static let audioDecayTimeControl = ID(rawValue: "AudioDecayTimeControl")
        public static let audioReleaseTimeControl = ID(rawValue: "AudioReleaseTimeControl")
    }
}

extension CHHapticPattern {
    public struct Key: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let version = Key(rawValue: "Version")
        public static let pattern = Key(rawValue: "Pattern")
        public static let event = Key(rawValue: "Event")
        public static let eventType = Key(rawValue: "EventType")
        public static let time = Key(rawValue: "Time")
        public static let eventDuration = Key(rawValue: "EventDuration")
        public static let eventWaveformPath = Key(rawValue: "EventWaveformPath")
        public static let eventParameters = Key(rawValue: "EventParameters")
        public static let parameter = Key(rawValue: "Parameter")
        public static let parameterID = Key(rawValue: "ParameterID")
        public static let parameterValue = Key(rawValue: "ParameterValue")
        public static let parameterCurve = Key(rawValue: "ParameterCurve")
        public static let parameterCurveControlPoints = Key(rawValue: "ParameterCurveControlPoints")
        public static let eventWaveformUseVolumeEnvelope = Key(rawValue: "EventWaveformUseVolumeEnvelope")
        public static let eventWaveformLoopEnabled = Key(rawValue: "EventWaveformLoopEnabled")
    }
}

// MARK: - Value objects

public final class CHHapticEventParameter: NSObject {
    public let parameterID: CHHapticEvent.ParameterID
    public var value: Float

    public init(parameterID: CHHapticEvent.ParameterID, value: Float) {
        self.parameterID = parameterID
        self.value = value
        super.init()
    }
}

public final class CHHapticDynamicParameter: NSObject {
    public let parameterID: ID
    public var value: Float
    public var relativeTime: TimeInterval

    public init(parameterID: ID, value: Float, relativeTime time: TimeInterval) {
        self.parameterID = parameterID
        self.value = value
        self.relativeTime = time
        super.init()
    }
}

public final class CHHapticEvent: NSObject {
    public let type: EventType
    public let eventParameters: [CHHapticEventParameter]
    public var relativeTime: TimeInterval
    public var duration: TimeInterval
    public let audioResourceID: CHHapticAudioResourceID?

    public init(
        eventType type: EventType,
        parameters eventParams: [CHHapticEventParameter],
        relativeTime time: TimeInterval
    ) {
        self.type = type
        eventParameters = eventParams
        relativeTime = time
        duration = 0
        audioResourceID = nil
        super.init()
    }

    public init(
        eventType type: EventType,
        parameters eventParams: [CHHapticEventParameter],
        relativeTime time: TimeInterval,
        duration: TimeInterval
    ) {
        self.type = type
        eventParameters = eventParams
        relativeTime = time
        self.duration = duration
        audioResourceID = nil
        super.init()
    }

    public init(
        audioResourceID resID: CHHapticAudioResourceID,
        parameters eventParams: [CHHapticEventParameter],
        relativeTime time: TimeInterval
    ) {
        type = .audioCustom
        eventParameters = eventParams
        relativeTime = time
        duration = 0
        audioResourceID = resID
        super.init()
    }

    public init(
        audioResourceID resID: CHHapticAudioResourceID,
        parameters eventParams: [CHHapticEventParameter],
        relativeTime time: TimeInterval,
        duration: TimeInterval
    ) {
        type = .audioCustom
        eventParameters = eventParams
        relativeTime = time
        self.duration = duration
        audioResourceID = resID
        super.init()
    }
}

public final class CHHapticParameterCurve: NSObject {
    public final class ControlPoint: NSObject {
        public var relativeTime: TimeInterval
        public var value: Float

        public init(relativeTime time: TimeInterval, value: Float) {
            relativeTime = time
            self.value = value
            super.init()
        }
    }

    public let parameterID: CHHapticDynamicParameter.ID
    public let controlPoints: [ControlPoint]
    public var relativeTime: TimeInterval

    public init(
        parameterID: CHHapticDynamicParameter.ID,
        controlPoints: [ControlPoint],
        relativeTime: TimeInterval
    ) {
        self.parameterID = parameterID
        self.controlPoints = controlPoints
        self.relativeTime = relativeTime
        super.init()
    }
}

// MARK: - Pattern

public final class CHHapticPattern: NSObject {
    public let events: [CHHapticEvent]
    public let parameters: [CHHapticDynamicParameter]
    public let parameterCurves: [CHHapticParameterCurve]
    public let duration: TimeInterval

    public init(
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter]
    ) throws {
        try CHHapticPattern.validate(events: events, parameters: parameters, curves: [])
        self.events = events
        self.parameters = parameters
        parameterCurves = []
        duration = CHHapticPattern.computeDuration(
            events: events, parameters: parameters, curves: []
        )
        super.init()
    }

    public init(
        events: [CHHapticEvent],
        parameterCurves: [CHHapticParameterCurve]
    ) throws {
        try CHHapticPattern.validate(
            events: events, parameters: [], curves: parameterCurves
        )
        self.events = events
        parameters = []
        self.parameterCurves = parameterCurves
        duration = CHHapticPattern.computeDuration(
            events: events, parameters: [], curves: parameterCurves
        )
        super.init()
    }

    public init(dictionary patternDict: [Key: Any]) throws {
        let parsed = try CHHapticPattern.parse(dictionary: patternDict)
        events = parsed.events
        parameters = parsed.parameters
        parameterCurves = parsed.curves
        duration = CHHapticPattern.computeDuration(
            events: parsed.events,
            parameters: parsed.parameters,
            curves: parsed.curves
        )
        super.init()
    }

    public init(contentsOf ahapURL: URL) throws {
        let data: Data
        do {
            data = try Data(contentsOf: ahapURL)
        } catch {
            throw CHHapticError(.fileNotFound)
        }
        let parsed = try CHHapticPattern.parse(data: data)
        events = parsed.events
        parameters = parsed.parameters
        parameterCurves = parsed.curves
        duration = CHHapticPattern.computeDuration(
            events: parsed.events,
            parameters: parsed.parameters,
            curves: parsed.curves
        )
        super.init()
    }

    public convenience init(contentsOfURL ahapURL: URL) throws {
        try self.init(contentsOf: ahapURL)
    }

    public func exportDictionary() throws -> [Key: Any] {
        var patternItems: [[Key: Any]] = []
        for event in events {
            var body: [Key: Any] = [
                .eventType: event.type.rawValue,
                .time: event.relativeTime,
            ]
            if event.duration != 0 {
                body[.eventDuration] = event.duration
            }
            if !event.eventParameters.isEmpty {
                body[.eventParameters] = event.eventParameters.map { parameter in
                    [
                        Key.parameterID: parameter.parameterID.rawValue,
                        Key.parameterValue: parameter.value,
                    ] as [Key: Any]
                }
            }
            patternItems.append([.event: body])
        }
        for parameter in parameters {
            let body: [Key: Any] = [
                .parameterID: parameter.parameterID.rawValue,
                .parameterValue: parameter.value,
                .time: parameter.relativeTime,
            ]
            patternItems.append([.parameter: body])
        }
        for curve in parameterCurves {
            let points: [[Key: Any]] = curve.controlPoints.map { point in
                [
                    .time: point.relativeTime,
                    .parameterValue: point.value,
                ]
            }
            let body: [Key: Any] = [
                .parameterID: curve.parameterID.rawValue,
                .time: curve.relativeTime,
                .parameterCurveControlPoints: points,
            ]
            patternItems.append([.parameterCurve: body])
        }
        return [
            .version: 1.0,
            .pattern: patternItems,
        ]
    }

    private static func computeDuration(
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter],
        curves: [CHHapticParameterCurve]
    ) -> TimeInterval {
        let eventEnd = events.map { $0.relativeTime + max(0, $0.duration) }.max() ?? 0
        let parameterEnd = parameters.map(\.relativeTime).max() ?? 0
        let curveEnd = curves.map { curve in
            curve.relativeTime + (curve.controlPoints.map(\.relativeTime).max() ?? 0)
        }.max() ?? 0
        return max(eventEnd, parameterEnd, curveEnd)
    }

    private static func validate(
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter],
        curves: [CHHapticParameterCurve]
    ) throws {
        for event in events {
            if event.relativeTime < 0 { throw CHHapticError(.invalidEventTime) }
            if event.duration < 0 { throw CHHapticError(.invalidEventDuration) }
        }
        for parameter in parameters where parameter.relativeTime < 0 {
            throw CHHapticError(.invalidTime)
        }
        for curve in curves {
            if curve.relativeTime < 0 { throw CHHapticError(.invalidTime) }
            for point in curve.controlPoints where point.relativeTime < 0 {
                throw CHHapticError(.invalidTime)
            }
        }
    }

    private static func parse(data: Data) throws -> (
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter],
        curves: [CHHapticParameterCurve]
    ) {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CHHapticError(.invalidPatternData)
        }
        guard let dictionary = object as? [String: Any] else {
            throw CHHapticError(.invalidPatternDictionary)
        }
        var keyed: [Key: Any] = [:]
        for (raw, value) in dictionary {
            keyed[Key(rawValue: raw)] = value
        }
        return try parse(dictionary: keyed)
    }

    private static func parse(dictionary: [Key: Any]) throws -> (
        events: [CHHapticEvent],
        parameters: [CHHapticDynamicParameter],
        curves: [CHHapticParameterCurve]
    ) {
        guard let items = dictionary[.pattern] as? [Any] else {
            throw CHHapticError(.invalidPatternDictionary)
        }
        var events: [CHHapticEvent] = []
        var parameters: [CHHapticDynamicParameter] = []
        var curves: [CHHapticParameterCurve] = []
        for item in items {
            let row = try keyedDictionary(item)
            if let eventBody = row[.event] {
                events.append(try parseEvent(eventBody))
            } else if let parameterBody = row[.parameter] {
                parameters.append(try parseDynamicParameter(parameterBody))
            } else if let curveBody = row[.parameterCurve] {
                curves.append(try parseCurve(curveBody))
            } else {
                throw CHHapticError(.invalidPatternDictionary)
            }
        }
        try validate(events: events, parameters: parameters, curves: curves)
        return (events, parameters, curves)
    }

    private static func keyedDictionary(_ value: Any) throws -> [Key: Any] {
        if let typed = value as? [Key: Any] {
            return typed
        }
        if let strings = value as? [String: Any] {
            var keyed: [Key: Any] = [:]
            for (raw, nested) in strings {
                keyed[Key(rawValue: raw)] = nested
            }
            return keyed
        }
        throw CHHapticError(.invalidPatternDictionary)
    }

    private static func parseEvent(_ value: Any) throws -> CHHapticEvent {
        let body = try keyedDictionary(value)
        guard let typeRaw = stringValue(body[.eventType]) else {
            throw CHHapticError(.invalidEventType)
        }
        let time = timeValue(body[.time]) ?? 0
        let duration = timeValue(body[.eventDuration]) ?? 0
        var parameters: [CHHapticEventParameter] = []
        if let rawParameters = body[.eventParameters] as? [Any] {
            for entry in rawParameters {
                let parameterBody = try keyedDictionary(entry)
                guard let idRaw = stringValue(parameterBody[.parameterID]) else {
                    throw CHHapticError(.badParameterEntry)
                }
                guard let value = floatValue(parameterBody[.parameterValue]) else {
                    throw CHHapticError(.badParameterEntry)
                }
                parameters.append(
                    CHHapticEventParameter(
                        parameterID: CHHapticEvent.ParameterID(rawValue: idRaw),
                        value: value
                    )
                )
            }
        }
        return CHHapticEvent(
            eventType: CHHapticEvent.EventType(rawValue: typeRaw),
            parameters: parameters,
            relativeTime: time,
            duration: duration
        )
    }

    private static func parseDynamicParameter(_ value: Any) throws -> CHHapticDynamicParameter {
        let body = try keyedDictionary(value)
        guard let idRaw = stringValue(body[.parameterID]) else {
            throw CHHapticError(.badParameterEntry)
        }
        guard let parameterValue = floatValue(body[.parameterValue]) else {
            throw CHHapticError(.badParameterEntry)
        }
        return CHHapticDynamicParameter(
            parameterID: CHHapticDynamicParameter.ID(rawValue: idRaw),
            value: parameterValue,
            relativeTime: timeValue(body[.time]) ?? 0
        )
    }

    private static func parseCurve(_ value: Any) throws -> CHHapticParameterCurve {
        let body = try keyedDictionary(value)
        guard let idRaw = stringValue(body[.parameterID]) else {
            throw CHHapticError(.badParameterEntry)
        }
        var points: [CHHapticParameterCurve.ControlPoint] = []
        if let rawPoints = body[.parameterCurveControlPoints] as? [Any] {
            for entry in rawPoints {
                let pointBody = try keyedDictionary(entry)
                guard let pointValue = floatValue(pointBody[.parameterValue]) else {
                    throw CHHapticError(.badParameterEntry)
                }
                points.append(
                    CHHapticParameterCurve.ControlPoint(
                        relativeTime: timeValue(pointBody[.time]) ?? 0,
                        value: pointValue
                    )
                )
            }
        }
        return CHHapticParameterCurve(
            parameterID: CHHapticDynamicParameter.ID(rawValue: idRaw),
            controlPoints: points,
            relativeTime: timeValue(body[.time]) ?? 0
        )
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let value = value as? String { return value }
        if let value = value as? NSString { return value as String }
        return nil
    }

    private static func timeValue(_ value: Any?) -> TimeInterval? {
        if let value = value as? TimeInterval { return value }
        if let value = value as? Double { return value }
        if let value = value as? Float { return TimeInterval(value) }
        if let value = value as? Int { return TimeInterval(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    private static func floatValue(_ value: Any?) -> Float? {
        if let value = value as? Float { return value }
        if let value = value as? Double { return Float(value) }
        if let value = value as? Int { return Float(value) }
        if let value = value as? NSNumber { return value.floatValue }
        return nil
    }
}

// MARK: - Protocols

public protocol CHHapticParameterAttributes: NSObjectProtocol {
    var minValue: Float { get }
    var maxValue: Float { get }
    var defaultValue: Float { get }
}

public protocol CHHapticDeviceCapability {
    var supportsHaptics: Bool { get }
    var supportsAudio: Bool { get }
    func attributes(forDynamicParameter inParameter: CHHapticDynamicParameter.ID) throws
        -> any CHHapticParameterAttributes
    func attributes(
        forEventParameter inParameter: CHHapticEvent.ParameterID,
        eventType type: CHHapticEvent.EventType
    ) throws -> any CHHapticParameterAttributes
}

public protocol CHHapticPatternPlayer: NSObjectProtocol {
    var isMuted: Bool { get set }
    func start(atTime time: TimeInterval) throws
    func stop(atTime time: TimeInterval) throws
    func sendParameters(_ parameters: [CHHapticDynamicParameter], atTime time: TimeInterval) throws
    func scheduleParameterCurve(_ parameterCurve: CHHapticParameterCurve, atTime time: TimeInterval) throws
    func cancel() throws
}

public protocol CHHapticAdvancedPatternPlayer: CHHapticPatternPlayer {
    var loopEnabled: Bool { get set }
    var loopEnd: TimeInterval { get set }
    var playbackRate: Float { get set }
    var completionHandler: CHHapticAdvancedPatternPlayerCompletionHandler { get set }
    func pause(atTime time: TimeInterval) throws
    func resume(atTime time: TimeInterval) throws
    func seek(toOffset offsetTime: TimeInterval) throws
}

private final class PortableHapticCapability: CHHapticDeviceCapability {
    let supportsHaptics = false
    let supportsAudio = false

    func attributes(forDynamicParameter inParameter: CHHapticDynamicParameter.ID) throws
        -> any CHHapticParameterAttributes
    {
        _ = inParameter
        throw CHHapticError(.notSupported)
    }

    func attributes(
        forEventParameter inParameter: CHHapticEvent.ParameterID,
        eventType type: CHHapticEvent.EventType
    ) throws -> any CHHapticParameterAttributes {
        _ = inParameter
        _ = type
        throw CHHapticError(.notSupported)
    }
}

/// Process-local player retained from the original lane. Start/send/seek stay
/// fail-closed: Linux has no haptic renderer.
public final class CHHapticPortablePatternPlayer: NSObject, CHHapticAdvancedPatternPlayer {
    public let pattern: CHHapticPattern
    public private(set) var startAttempts = 0
    public private(set) var isPlaying = false
    public var isMuted = false
    public var loopEnabled = false
    public var loopEnd: TimeInterval = 0
    public var playbackRate: Float = 1
    public var completionHandler: CHHapticAdvancedPatternPlayerCompletionHandler = { _ in }

    public init(pattern: CHHapticPattern) {
        self.pattern = pattern
        super.init()
    }

    public func start(atTime time: TimeInterval) throws {
        _ = time
        startAttempts += 1
        isPlaying = false
        throw CHHapticError(.notSupported)
    }

    public func stop(atTime time: TimeInterval) throws {
        _ = time
        isPlaying = false
    }

    public func sendParameters(
        _ parameters: [CHHapticDynamicParameter],
        atTime time: TimeInterval
    ) throws {
        _ = parameters
        _ = time
        throw CHHapticError(.notSupported)
    }

    public func scheduleParameterCurve(
        _ parameterCurve: CHHapticParameterCurve,
        atTime time: TimeInterval
    ) throws {
        _ = parameterCurve
        _ = time
        throw CHHapticError(.notSupported)
    }

    public func cancel() throws {
        isPlaying = false
    }

    public func pause(atTime time: TimeInterval) throws {
        _ = time
        throw CHHapticError(.notSupported)
    }

    public func resume(atTime time: TimeInterval) throws {
        _ = time
        throw CHHapticError(.notSupported)
    }

    public func seek(toOffset offsetTime: TimeInterval) throws {
        _ = offsetTime
        throw CHHapticError(.notSupported)
    }
}

// MARK: - Engine

public final class CHHapticEngine {
    public enum FinishedAction: Int, Sendable {
        case stopEngine = 1
        case leaveEngineRunning = 2
    }

    public enum StoppedReason: Int, Sendable {
        case audioSessionInterrupt = 1
        case applicationSuspended = 2
        case idleTimeout = 3
        case notifyWhenFinished = 4
        case engineDestroyed = 5
        case gameControllerDisconnect = 6
        case systemError = -1
    }

    public typealias CompletionHandler = ((any Error)?) -> Void
    public typealias FinishedHandler = ((any Error)?) -> FinishedAction
    public typealias ResetHandler = () -> Void
    public typealias StoppedHandler = (StoppedReason) -> Void

    public var stoppedHandler: StoppedHandler = { _ in }
    public var resetHandler: ResetHandler = {}
    public var playsHapticsOnly = false
    public var playsAudioOnly = false
    public var isMutedForAudio = false
    public var isMutedForHaptics = false
    public var isAutoShutdownEnabled = false
    public private(set) var isRunning = false
    public private(set) var startAttempts = 0
    public var currentTime: TimeInterval { 0 }

    public init() throws {}

    /// Clang-importer synthesized spelling of `initAndReturnError:`.
    public convenience init(andReturnError: ()) throws {
        try self.init()
    }

    public static func capabilitiesForHardware() -> any CHHapticDeviceCapability {
        PortableHapticCapability()
    }

    public func start() throws {
        startAttempts += 1
        isRunning = false
        throw CHHapticError(.notSupported)
    }

    public func start(completionHandler: (((any Error)?) -> Void)? = nil) {
        startAttempts += 1
        isRunning = false
        completionHandler?(CHHapticError(.notSupported))
    }

    public func stop(completionHandler: (((any Error)?) -> Void)? = nil) {
        isRunning = false
        completionHandler?(nil)
    }

    public func notifyWhenPlayersFinished(finishedHandler: @escaping FinishedHandler) {
        _ = finishedHandler(CHHapticError(.notSupported))
    }

    public func makePlayer(with pattern: CHHapticPattern) throws -> any CHHapticPatternPlayer {
        CHHapticPortablePatternPlayer(pattern: pattern)
    }

    public func makeAdvancedPlayer(with pattern: CHHapticPattern) throws
        -> any CHHapticAdvancedPatternPlayer
    {
        CHHapticPortablePatternPlayer(pattern: pattern)
    }

    public func registerAudioResource(
        _ resourceURL: URL,
        options: [AnyHashable: Any] = [:]
    ) throws -> CHHapticAudioResourceID {
        _ = resourceURL
        _ = options
        throw CHHapticError(.notSupported)
    }

    public func unregisterAudioResource(_ resourceID: CHHapticAudioResourceID) throws {
        _ = resourceID
        throw CHHapticError(.notSupported)
    }

    public func playPattern(from data: Data) throws {
        _ = try CHHapticPattern(dictionary: try CHHapticPattern.jsonDictionary(from: data))
        throw CHHapticError(.notSupported)
    }

    public func playPattern(from fileURL: URL) throws {
        _ = try CHHapticPattern(contentsOf: fileURL)
        throw CHHapticError(.notSupported)
    }
}

extension CHHapticPattern {
    fileprivate static func jsonDictionary(from data: Data) throws -> [Key: Any] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CHHapticError(.invalidPatternData)
        }
        guard let dictionary = object as? [String: Any] else {
            throw CHHapticError(.invalidPatternDictionary)
        }
        var keyed: [Key: Any] = [:]
        for (raw, value) in dictionary {
            keyed[Key(rawValue: raw)] = value
        }
        return keyed
    }
}
