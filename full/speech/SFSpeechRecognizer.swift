import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

// MARK: - Acoustic / transcription objects

public class SFAcousticFeature: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public private(set) var frameDuration: TimeInterval
    public private(set) var acousticFeatureValuePerFrame: [Double]

    @_spi(OpenUIKitHost)
    public init(frameDuration: TimeInterval, acousticFeatureValuePerFrame: [Double]) {
        self.frameDuration = frameDuration
        self.acousticFeatureValuePerFrame = acousticFeatureValuePerFrame
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFAcousticFeature(
            frameDuration: frameDuration,
            acousticFeatureValuePerFrame: acousticFeatureValuePerFrame
        )
    }
}

public class SFVoiceAnalytics: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    @NSCopying public private(set) var jitter: SFAcousticFeature
    @NSCopying public private(set) var pitch: SFAcousticFeature
    @NSCopying public private(set) var shimmer: SFAcousticFeature
    @NSCopying public private(set) var voicing: SFAcousticFeature

    @_spi(OpenUIKitHost)
    public init(
        jitter: SFAcousticFeature,
        pitch: SFAcousticFeature,
        shimmer: SFAcousticFeature,
        voicing: SFAcousticFeature
    ) {
        self.jitter = jitter
        self.pitch = pitch
        self.shimmer = shimmer
        self.voicing = voicing
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFVoiceAnalytics(jitter: jitter, pitch: pitch, shimmer: shimmer, voicing: voicing)
    }
}

public class SFTranscriptionSegment: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public private(set) var alternativeSubstrings: [String]
    public private(set) var confidence: Float
    public private(set) var duration: TimeInterval
    public private(set) var substring: String
    public private(set) var substringRange: NSRange
    public private(set) var timestamp: TimeInterval
    public private(set) var voiceAnalytics: SFVoiceAnalytics?

    @_spi(OpenUIKitHost)
    public init(
        substring: String,
        substringRange: NSRange,
        timestamp: TimeInterval,
        duration: TimeInterval,
        confidence: Float,
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

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFTranscriptionSegment(
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

public class SFTranscription: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public private(set) var averagePauseDuration: TimeInterval
    public private(set) var formattedString: String
    public private(set) var segments: [SFTranscriptionSegment]
    public private(set) var speakingRate: Double

    @_spi(OpenUIKitHost)
    public init(
        formattedString: String,
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

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFTranscription(
            formattedString: formattedString,
            segments: segments,
            speakingRate: speakingRate,
            averagePauseDuration: averagePauseDuration
        )
    }
}

public class SFSpeechRecognitionMetadata: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public private(set) var averagePauseDuration: TimeInterval
    public private(set) var speakingRate: Double
    public private(set) var speechDuration: TimeInterval
    public private(set) var speechStartTimestamp: TimeInterval
    public private(set) var voiceAnalytics: SFVoiceAnalytics?

    @_spi(OpenUIKitHost)
    public init(
        averagePauseDuration: TimeInterval = 0,
        speakingRate: Double = 0,
        speechDuration: TimeInterval = 0,
        speechStartTimestamp: TimeInterval = 0,
        voiceAnalytics: SFVoiceAnalytics? = nil
    ) {
        self.averagePauseDuration = averagePauseDuration
        self.speakingRate = speakingRate
        self.speechDuration = speechDuration
        self.speechStartTimestamp = speechStartTimestamp
        self.voiceAnalytics = voiceAnalytics
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFSpeechRecognitionMetadata(
            averagePauseDuration: averagePauseDuration,
            speakingRate: speakingRate,
            speechDuration: speechDuration,
            speechStartTimestamp: speechStartTimestamp,
            voiceAnalytics: voiceAnalytics
        )
    }
}

public class SFSpeechRecognitionResult: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    @NSCopying public private(set) var bestTranscription: SFTranscription
    public private(set) var isFinal: Bool
    public private(set) var speechRecognitionMetadata: SFSpeechRecognitionMetadata?
    public private(set) var transcriptions: [SFTranscription]

    @_spi(OpenUIKitHost)
    public init(
        bestTranscription: SFTranscription,
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

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        SFSpeechRecognitionResult(
            bestTranscription: bestTranscription,
            transcriptions: transcriptions,
            isFinal: isFinal,
            speechRecognitionMetadata: speechRecognitionMetadata
        )
    }
}

// MARK: - Language model configuration

public class SFSpeechLanguageModel: NSObject {
    public class Configuration: NSObject, NSCopying, NSSecureCoding {
        public static var supportsSecureCoding: Bool { false }

        public private(set) var languageModel: URL
        public private(set) var vocabulary: URL?
        public private(set) var weight: NSNumber?

        public convenience init(languageModel: URL) {
            self.init(languageModel: languageModel, vocabulary: nil, weight: nil)
        }

        public convenience init(languageModel: URL, vocabulary: URL?) {
            self.init(languageModel: languageModel, vocabulary: vocabulary, weight: nil)
        }

        public init(languageModel: URL, vocabulary: URL?, weight: NSNumber?) {
            self.languageModel = languageModel
            self.vocabulary = vocabulary
            self.weight = weight
            super.init()
        }

        public required init?(coder: NSCoder) {
            return nil
        }

        public func encode(with coder: NSCoder) {}

        public func copy(with zone: NSZone? = nil) -> Any {
            Configuration(
                languageModel: languageModel,
                vocabulary: vocabulary,
                weight: weight
            )
        }
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        clientIdentifier: String,
        configuration: Configuration
    ) async throws {
        try await prepareCustomLanguageModel(
            for: asset,
            clientIdentifier: clientIdentifier,
            configuration: configuration,
            ignoresCache: false
        )
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        clientIdentifier: String,
        configuration: Configuration,
        ignoresCache: Bool
    ) async throws {
        _ = (asset, clientIdentifier, configuration, ignoresCache)
        throw speechFailClosedError(.internalServiceError)
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        configuration: Configuration
    ) async throws {
        try await prepareCustomLanguageModel(
            for: asset,
            configuration: configuration,
            ignoresCache: false
        )
    }

    public class func prepareCustomLanguageModel(
        for asset: URL,
        configuration: Configuration,
        ignoresCache: Bool
    ) async throws {
        try await prepareCustomLanguageModel(
            for: asset,
            clientIdentifier: "",
            configuration: configuration,
            ignoresCache: ignoresCache
        )
    }
}

// MARK: - Requests

open class SFSpeechRecognitionRequest: NSObject {
    public var addsPunctuation = false
    public var contextualStrings: [String] = []
    @NSCopying public var customizedLanguageModel: SFSpeechLanguageModel.Configuration?
    public var interactionIdentifier: String?
    public var requiresOnDeviceRecognition = false
    public var shouldReportPartialResults = true
    public var taskHint = SFSpeechRecognitionTaskHint.unspecified
}

public class SFSpeechURLRecognitionRequest: SFSpeechRecognitionRequest {
    public private(set) var url: URL

    public init(url URL: URL) {
        self.url = URL
        super.init()
    }

    public convenience init(URL: URL) {
        self.init(url: URL)
    }
}

public class SFSpeechAudioBufferRecognitionRequest: SFSpeechRecognitionRequest {
    public private(set) var didEndAudio = false
    public private(set) var appendedBufferCount = 0

    public func endAudio() {
        didEndAudio = true
    }

#if canImport(AVFoundation)
    public var nativeAudioFormat: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
    }

    public func append(_ audioPCMBuffer: AVAudioPCMBuffer) {
        _ = audioPCMBuffer
        appendedBufferCount += 1
    }
#endif

#if canImport(CoreMedia)
    public func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        _ = sampleBuffer
        appendedBufferCount += 1
    }
#endif
}

// MARK: - Task + delegates

public protocol SFSpeechRecognitionTaskDelegate: NSObjectProtocol {
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask)
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    )
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool)
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    )
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didProcessAudioDuration duration: TimeInterval)
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask)
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask)
}

public extension SFSpeechRecognitionTaskDelegate {
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {}
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {}
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {}
    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    ) {}
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didProcessAudioDuration duration: TimeInterval) {}
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {}
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {}
}

public protocol SFSpeechRecognizerDelegate: NSObjectProtocol {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
}

public extension SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {}
}

public class SFSpeechRecognitionTask: NSObject {
    public private(set) var isCancelled = false
    public private(set) var isFinishing = false
    public private(set) var state = SFSpeechRecognitionTaskState.starting
    public private(set) var error: (any Error)?

    private let lock = NSLock()
    private let deliveryQueue: OperationQueue
    private var resultHandler: ((SFSpeechRecognitionResult?, (any Error)?) -> Void)?
    private weak var taskDelegate: (any SFSpeechRecognitionTaskDelegate)?
    private var finished = false

    fileprivate init(
        queue: OperationQueue,
        resultHandler: ((SFSpeechRecognitionResult?, (any Error)?) -> Void)?,
        delegate: (any SFSpeechRecognitionTaskDelegate)?
    ) {
        self.deliveryQueue = queue
        self.resultHandler = resultHandler
        self.taskDelegate = delegate
        super.init()
    }

    public func cancel() {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        isCancelled = true
        isFinishing = true
        state = .canceling
        lock.unlock()
        failClosed(cancelled: true)
    }

    public func finish() {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        isFinishing = true
        if state == .starting || state == .running {
            state = .finishing
        }
        lock.unlock()
        failClosed(cancelled: false)
    }

    fileprivate func startFailClosed() {
        lock.lock()
        state = .running
        lock.unlock()
        speechDeliverAsync { [self] in
            self.failClosed(cancelled: false)
        }
    }

    private func failClosed(cancelled: Bool) {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        let error = speechFailClosedError(.internalServiceError)
        self.error = error
        state = cancelled ? .completed : .completed
        isFinishing = true
        let handler = resultHandler
        resultHandler = nil
        let delegate = taskDelegate
        taskDelegate = nil
        let queue = deliveryQueue
        lock.unlock()

        speechDeliverOnQueue(queue) {
            handler?(nil, error)
            if cancelled {
                delegate?.speechRecognitionTaskWasCancelled(self)
            }
            delegate?.speechRecognitionTask(self, didFinishSuccessfully: false)
        }
    }
}

// MARK: - Recognizer

public class SFSpeechRecognizer: NSObject {
    public private(set) var locale: Locale
    public var defaultTaskHint = SFSpeechRecognitionTaskHint.unspecified
    public weak var delegate: (any SFSpeechRecognizerDelegate)?
    private let queueBackend = DispatchQueue(
        label: "Speech.SFSpeechRecognizer.dispatch",
        qos: .utility
    )
    public var queue: OperationQueue
    public var supportsOnDeviceRecognition = false
    public var isAvailable: Bool { false }
    private var activeTasks: [SFSpeechRecognitionTask] = []

    public class func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        speechCurrentAuthorizationStatus()
    }

    public class func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        speechStoreAuthorizationStatus(.denied)
        let status = speechCurrentAuthorizationStatus()
        speechDeliverAuthorization {
            handler(status)
        }
    }

    public class func supportedLocales() -> Set<Locale> {
        []
    }

    public override init() {
        self.locale = Locale.current
        let queue = OperationQueue()
        queue.name = "Speech.SFSpeechRecognizer"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.queue = queue
        super.init()
        queue.underlyingQueue = queueBackend
    }

    public init?(locale: Locale) {
        self.locale = locale
        let queue = OperationQueue()
        queue.name = "Speech.SFSpeechRecognizer"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.queue = queue
        super.init()
        queue.underlyingQueue = queueBackend
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        delegate: any SFSpeechRecognitionTaskDelegate
    ) -> SFSpeechRecognitionTask {
        _ = request
        let task = SFSpeechRecognitionTask(queue: queue, resultHandler: nil, delegate: delegate)
        activeTasks.append(task)
        task.startFailClosed()
        return task
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, (any Error)?) -> Void
    ) -> SFSpeechRecognitionTask {
        _ = request
        let task = SFSpeechRecognitionTask(
            queue: queue,
            resultHandler: resultHandler,
            delegate: nil
        )
        activeTasks.append(task)
        task.startFailClosed()
        return task
    }
}
