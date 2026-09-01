public enum SFSpeechRecognitionTaskHint: Int, Hashable, Sendable {
    case unspecified = 0
    case dictation = 1
    case search = 2
    case confirmation = 3
}

public enum SFSpeechRecognitionTaskState: Int, Hashable, Sendable {
    case starting = 0
    case running = 1
    case finishing = 2
    case canceling = 3
    case completed = 4
}

public enum SFSpeechRecognizerAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3
}

public protocol SFSpeechRecognizerDelegate: NSObjectProtocol {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
}

extension SFSpeechRecognizerDelegate {
    public func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        _ = (speechRecognizer, available)
    }
}

public protocol SFSpeechRecognitionTaskDelegate: NSObjectProtocol {
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask)
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    )
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    )
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishSuccessfully successfully: Bool
    )
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask)
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask)
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didProcessAudioDuration duration: TimeInterval
    )
}

extension SFSpeechRecognitionTaskDelegate {
    public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        _ = task
    }

    public func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    ) {
        _ = (task, transcription)
    }

    public func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        _ = (task, recognitionResult)
    }

    public func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishSuccessfully successfully: Bool
    ) {
        _ = (task, successfully)
    }

    public func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        _ = task
    }

    public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        _ = task
    }

    public func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didProcessAudioDuration duration: TimeInterval
    ) {
        _ = (task, duration)
    }
}

open class SFAcousticFeature: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let acousticFeatureValuePerFrame: [Double]
    public let frameDuration: TimeInterval

    public init(
        acousticFeatureValuePerFrame: [Double] = [],
        frameDuration: TimeInterval = 0
    ) {
        self.acousticFeatureValuePerFrame = acousticFeatureValuePerFrame
        self.frameDuration = frameDuration
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        acousticFeatureValuePerFrame = coder.decodeObject(forKey: "values") as? [Double] ?? []
        frameDuration = coder.decodeDouble(forKey: "frameDuration")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(acousticFeatureValuePerFrame, forKey: "values")
        coder.encode(frameDuration, forKey: "frameDuration")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFAcousticFeature(
            acousticFeatureValuePerFrame: acousticFeatureValuePerFrame,
            frameDuration: frameDuration
        )
    }
}

open class SFVoiceAnalytics: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let jitter: SFAcousticFeature
    public let pitch: SFAcousticFeature
    public let shimmer: SFAcousticFeature
    public let voicing: SFAcousticFeature

    public init(
        jitter: SFAcousticFeature = SFAcousticFeature(),
        pitch: SFAcousticFeature = SFAcousticFeature(),
        shimmer: SFAcousticFeature = SFAcousticFeature(),
        voicing: SFAcousticFeature = SFAcousticFeature()
    ) {
        self.jitter = jitter
        self.pitch = pitch
        self.shimmer = shimmer
        self.voicing = voicing
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        jitter = coder.decodeObject(of: SFAcousticFeature.self, forKey: "jitter") ?? SFAcousticFeature()
        pitch = coder.decodeObject(of: SFAcousticFeature.self, forKey: "pitch") ?? SFAcousticFeature()
        shimmer = coder.decodeObject(of: SFAcousticFeature.self, forKey: "shimmer") ?? SFAcousticFeature()
        voicing = coder.decodeObject(of: SFAcousticFeature.self, forKey: "voicing") ?? SFAcousticFeature()
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(jitter, forKey: "jitter")
        coder.encode(pitch, forKey: "pitch")
        coder.encode(shimmer, forKey: "shimmer")
        coder.encode(voicing, forKey: "voicing")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFVoiceAnalytics(jitter: jitter, pitch: pitch, shimmer: shimmer, voicing: voicing)
    }
}

open class SFTranscriptionSegment: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let substring: String
    public let substringRange: NSRange
    public let timestamp: TimeInterval
    public let duration: TimeInterval
    public let confidence: Float
    public let alternativeSubstrings: [String]
    public let voiceAnalytics: SFVoiceAnalytics?

    public init(
        substring: String = "",
        substringRange: NSRange = NSRange(location: 0, length: 0),
        timestamp: TimeInterval = 0,
        duration: TimeInterval = 0,
        confidence: Float = 0,
        alternativeSubstrings: [String] = [],
        voiceAnalytics: SFVoiceAnalytics? = nil
    ) {
        self.substring = substring
        self.substringRange = substringRange
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
        self.alternativeSubstrings = alternativeSubstrings
        self.voiceAnalytics = voiceAnalytics
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        substring = coder.decodeObject(of: NSString.self, forKey: "substring") as String? ?? ""
        substringRange = coder.decodeObject(of: NSValue.self, forKey: "range")?.rangeValue
            ?? NSRange(location: 0, length: 0)
        timestamp = coder.decodeDouble(forKey: "timestamp")
        duration = coder.decodeDouble(forKey: "duration")
        confidence = coder.decodeFloat(forKey: "confidence")
        alternativeSubstrings = coder.decodeObject(forKey: "alternatives") as? [String] ?? []
        voiceAnalytics = coder.decodeObject(of: SFVoiceAnalytics.self, forKey: "voiceAnalytics")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(substring, forKey: "substring")
        coder.encode(NSValue(range: substringRange), forKey: "range")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(duration, forKey: "duration")
        coder.encode(confidence, forKey: "confidence")
        coder.encode(alternativeSubstrings, forKey: "alternatives")
        coder.encode(voiceAnalytics, forKey: "voiceAnalytics")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFTranscriptionSegment(
            substring: substring,
            substringRange: substringRange,
            timestamp: timestamp,
            duration: duration,
            confidence: confidence,
            alternativeSubstrings: alternativeSubstrings,
            voiceAnalytics: voiceAnalytics
        )
    }
}

open class SFTranscription: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let formattedString: String
    public let segments: [SFTranscriptionSegment]
    public let speakingRate: Double
    public let averagePauseDuration: TimeInterval

    public init(
        formattedString: String = "",
        segments: [SFTranscriptionSegment] = [],
        speakingRate: Double = 0,
        averagePauseDuration: TimeInterval = 0
    ) {
        self.formattedString = formattedString
        self.segments = segments
        self.speakingRate = speakingRate
        self.averagePauseDuration = averagePauseDuration
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        formattedString = coder.decodeObject(of: NSString.self, forKey: "formatted") as String? ?? ""
        segments = coder.decodeObject(of: [NSArray.self, SFTranscriptionSegment.self], forKey: "segments")
            as? [SFTranscriptionSegment] ?? []
        speakingRate = coder.decodeDouble(forKey: "speakingRate")
        averagePauseDuration = coder.decodeDouble(forKey: "averagePauseDuration")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(formattedString, forKey: "formatted")
        coder.encode(segments, forKey: "segments")
        coder.encode(speakingRate, forKey: "speakingRate")
        coder.encode(averagePauseDuration, forKey: "averagePauseDuration")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFTranscription(
            formattedString: formattedString,
            segments: segments,
            speakingRate: speakingRate,
            averagePauseDuration: averagePauseDuration
        )
    }
}

open class SFSpeechRecognitionMetadata: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let speakingRate: Double
    public let averagePauseDuration: TimeInterval
    public let speechStartTimestamp: TimeInterval
    public let speechDuration: TimeInterval
    public let voiceAnalytics: SFVoiceAnalytics?

    public init(
        speakingRate: Double = 0,
        averagePauseDuration: TimeInterval = 0,
        speechStartTimestamp: TimeInterval = 0,
        speechDuration: TimeInterval = 0,
        voiceAnalytics: SFVoiceAnalytics? = nil
    ) {
        self.speakingRate = speakingRate
        self.averagePauseDuration = averagePauseDuration
        self.speechStartTimestamp = speechStartTimestamp
        self.speechDuration = speechDuration
        self.voiceAnalytics = voiceAnalytics
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        speakingRate = coder.decodeDouble(forKey: "speakingRate")
        averagePauseDuration = coder.decodeDouble(forKey: "averagePauseDuration")
        speechStartTimestamp = coder.decodeDouble(forKey: "speechStart")
        speechDuration = coder.decodeDouble(forKey: "speechDuration")
        voiceAnalytics = coder.decodeObject(of: SFVoiceAnalytics.self, forKey: "voiceAnalytics")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(speakingRate, forKey: "speakingRate")
        coder.encode(averagePauseDuration, forKey: "averagePauseDuration")
        coder.encode(speechStartTimestamp, forKey: "speechStart")
        coder.encode(speechDuration, forKey: "speechDuration")
        coder.encode(voiceAnalytics, forKey: "voiceAnalytics")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFSpeechRecognitionMetadata(
            speakingRate: speakingRate,
            averagePauseDuration: averagePauseDuration,
            speechStartTimestamp: speechStartTimestamp,
            speechDuration: speechDuration,
            voiceAnalytics: voiceAnalytics
        )
    }
}

open class SFSpeechRecognitionResult: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public let bestTranscription: SFTranscription
    public let transcriptions: [SFTranscription]
    public let isFinal: Bool
    public let speechRecognitionMetadata: SFSpeechRecognitionMetadata?

    public init(
        bestTranscription: SFTranscription = SFTranscription(),
        transcriptions: [SFTranscription]? = nil,
        isFinal: Bool = true,
        speechRecognitionMetadata: SFSpeechRecognitionMetadata? = nil
    ) {
        self.bestTranscription = bestTranscription
        self.transcriptions = transcriptions ?? [bestTranscription]
        self.isFinal = isFinal
        self.speechRecognitionMetadata = speechRecognitionMetadata
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        bestTranscription = coder.decodeObject(of: SFTranscription.self, forKey: "best")
            ?? SFTranscription()
        transcriptions = coder.decodeObject(of: [NSArray.self, SFTranscription.self], forKey: "transcriptions")
            as? [SFTranscription] ?? []
        isFinal = coder.decodeBool(forKey: "final")
        speechRecognitionMetadata = coder.decodeObject(
            of: SFSpeechRecognitionMetadata.self,
            forKey: "metadata"
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(bestTranscription, forKey: "best")
        coder.encode(transcriptions, forKey: "transcriptions")
        coder.encode(isFinal, forKey: "final")
        coder.encode(speechRecognitionMetadata, forKey: "metadata")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SFSpeechRecognitionResult(
            bestTranscription: bestTranscription,
            transcriptions: transcriptions,
            isFinal: isFinal,
            speechRecognitionMetadata: speechRecognitionMetadata
        )
    }
}

open class SFSpeechRecognitionRequest: NSObject {
    public var taskHint: SFSpeechRecognitionTaskHint = .unspecified
    public var shouldReportPartialResults = true
    public var contextualStrings: [String] = []
    public var interactionIdentifier: String?
    public var requiresOnDeviceRecognition = false
    public var addsPunctuation = false
    public var customizedLanguageModel: SFSpeechLanguageModel.Configuration?

    public override init() {
        super.init()
    }
}

open class SFSpeechURLRecognitionRequest: SFSpeechRecognitionRequest {
    public let url: URL

    public init(url URL: URL) {
        self.url = URL
        super.init()
    }

    public convenience init(URL: URL) {
        self.init(url: URL)
    }
}

open class SFSpeechAudioBufferRecognitionRequest: SFSpeechRecognitionRequest {
    private let lock = NSLock()
    private var ended = false
    private(set) var appendedBufferCount = 0

    public var nativeAudioFormat: AVAudioFormat {
        SpeechPortable.defaultAudioFormat()
    }

    public func append(_ audioPCMBuffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard !ended else { return }
        appendedBufferCount += 1
        _ = audioPCMBuffer
    }

    public func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard !ended else { return }
        appendedBufferCount += 1
        _ = sampleBuffer
    }

    public func endAudio() {
        lock.lock()
        ended = true
        lock.unlock()
    }
}

open class SFSpeechRecognitionTask: NSObject {
    private let lock = NSLock()
    private var _state: SFSpeechRecognitionTaskState = .starting
    private var _cancelled = false
    private var _finishing = false
    private var _error: (any Error)?

    public var state: SFSpeechRecognitionTaskState {
        lock.lock(); defer { lock.unlock() }
        return _state
    }

    public var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return _cancelled
    }

    public var isFinishing: Bool {
        lock.lock(); defer { lock.unlock() }
        return _finishing
    }

    public var error: (any Error)? {
        lock.lock(); defer { lock.unlock() }
        return _error
    }

    func failClosed(_ error: SFSpeechError) {
        lock.lock()
        _error = error
        _state = .completed
        lock.unlock()
    }

    public func cancel() {
        lock.lock()
        _cancelled = true
        _state = .completed
        if _error == nil {
            _error = SpeechPortable.failClosedError(
                .internalServiceError,
                reason: "Speech recognition was cancelled and is unavailable on this host"
            )
        }
        lock.unlock()
    }

    public func finish() {
        lock.lock()
        _finishing = true
        _state = .completed
        if _error == nil {
            _error = SpeechPortable.failClosedError(
                .noModel,
                reason: "Speech recognition has no on-device or remote model on this host"
            )
        }
        lock.unlock()
    }
}

open class SFSpeechRecognizer {
    private static let statusLock = NSLock()
    private static var _authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .denied

    public let locale: Locale
    public var defaultTaskHint: SFSpeechRecognitionTaskHint = .unspecified
    public weak var delegate: (any SFSpeechRecognizerDelegate)?
    public var queue = OperationQueue()
    public var supportsOnDeviceRecognition = false

    public var isAvailable: Bool { false }

    public convenience init?() {
        self.init(locale: Locale.current)
    }

    public init?(locale: Locale) {
        self.locale = locale
    }

    public class func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        statusLock.lock(); defer { statusLock.unlock() }
        return _authorizationStatus
    }

    public class func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        statusLock.lock()
        _authorizationStatus = .denied
        let status = _authorizationStatus
        statusLock.unlock()
        handler(status)
    }

    public class func supportedLocales() -> Set<Locale> {
        []
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, (any Error)?) -> Void
    ) -> SFSpeechRecognitionTask {
        _ = request
        let task = SFSpeechRecognitionTask()
        let error = SpeechPortable.failClosedError(
            .noModel,
            reason: "SFSpeechRecognizer has no speech service on this host"
        )
        task.failClosed(error)
        resultHandler(nil, error)
        return task
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        delegate: any SFSpeechRecognitionTaskDelegate
    ) -> SFSpeechRecognitionTask {
        _ = request
        let task = SFSpeechRecognitionTask()
        let error = SpeechPortable.failClosedError(
            .noModel,
            reason: "SFSpeechRecognizer has no speech service on this host"
        )
        task.failClosed(error)
        delegate.speechRecognitionTask(task, didFinishSuccessfully: false)
        return task
    }
}
