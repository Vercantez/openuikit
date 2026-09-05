import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

// MARK: - Acoustic / transcription objects (value semantics)

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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFAcousticFeature else { return false }
        return frameDuration == other.frameDuration
            && acousticFeatureValuePerFrame == other.acousticFeatureValuePerFrame
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(frameDuration)
        hasher.combine(acousticFeatureValuePerFrame)
        return hasher.finalize()
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFVoiceAnalytics else { return false }
        return jitter.isEqual(other.jitter)
            && pitch.isEqual(other.pitch)
            && shimmer.isEqual(other.shimmer)
            && voicing.isEqual(other.voicing)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(jitter.hash)
        hasher.combine(pitch.hash)
        hasher.combine(shimmer.hash)
        hasher.combine(voicing.hash)
        return hasher.finalize()
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFTranscriptionSegment else { return false }
        return substring == other.substring
            && NSEqualRanges(substringRange, other.substringRange)
            && timestamp == other.timestamp
            && duration == other.duration
            && confidence == other.confidence
            && alternativeSubstrings == other.alternativeSubstrings
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(substring)
        hasher.combine(timestamp)
        hasher.combine(duration)
        hasher.combine(confidence)
        return hasher.finalize()
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFTranscription else { return false }
        return formattedString == other.formattedString
            && speakingRate == other.speakingRate
            && averagePauseDuration == other.averagePauseDuration
            && segments.elementsEqual(other.segments, by: { $0.isEqual($1) })
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(formattedString)
        hasher.combine(speakingRate)
        hasher.combine(averagePauseDuration)
        return hasher.finalize()
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFSpeechRecognitionMetadata else { return false }
        return averagePauseDuration == other.averagePauseDuration
            && speakingRate == other.speakingRate
            && speechDuration == other.speechDuration
            && speechStartTimestamp == other.speechStartTimestamp
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(averagePauseDuration)
        hasher.combine(speakingRate)
        hasher.combine(speechDuration)
        hasher.combine(speechStartTimestamp)
        return hasher.finalize()
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SFSpeechRecognitionResult else { return false }
        return isFinal == other.isFinal && bestTranscription.isEqual(other.bestTranscription)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(isFinal)
        hasher.combine(bestTranscription.hash)
        return hasher.finalize()
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

    /// iOS 17 custom language-model compile. Linux has no speech engine;
    /// every overload fail-closes with `SFSpeechError.internalServiceError`.
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
    public private(set) var appendedSampleBufferCount = 0
    fileprivate weak var attachedTask: SFSpeechRecognitionTask?

    public var nativeAudioFormat: SpeechNativeAudioFormat {
        #if canImport(AVFoundation)
        AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        #else
        .speechNative
        #endif
    }

    public func append(_ audioPCMBuffer: SpeechPCMBuffer) {
        #if canImport(AVFoundation)
        _ = audioPCMBuffer
        #else
        _ = audioPCMBuffer.frameLength
        #endif
        appendedBufferCount += 1
    }

    public func appendAudioSampleBuffer(_ sampleBuffer: SpeechSampleBuffer) {
        #if canImport(CoreMedia)
        _ = sampleBuffer
        #else
        _ = sampleBuffer.sampleRate
        #endif
        appendedSampleBufferCount += 1
        appendedBufferCount += 1
    }

    /// Citation: [endAudio()](https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest/endaudio())
    /// — call when there is no more audio to append. Sticky on this host.
    public func endAudio() {
        didEndAudio = true
        attachedTask?.hostAudioInputEnded()
    }
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
    /// Starts in `.starting` (recognition has not yet begun).
    public private(set) var state = SFSpeechRecognitionTaskState.starting
    public private(set) var error: (any Error)?

    private let lock = NSLock()
    private let deliveryQueue: OperationQueue
    private var resultHandler: ((SFSpeechRecognitionResult?, (any Error)?) -> Void)?
    private weak var taskDelegate: (any SFSpeechRecognitionTaskDelegate)?
    private var finished = false
    private let request: SFSpeechRecognitionRequest
    private let script: SpeechScriptedRecognizer?
    private let isURLRequest: Bool

    fileprivate init(
        request: SFSpeechRecognitionRequest,
        queue: OperationQueue,
        resultHandler: ((SFSpeechRecognitionResult?, (any Error)?) -> Void)?,
        delegate: (any SFSpeechRecognitionTaskDelegate)?,
        script: SpeechScriptedRecognizer?
    ) {
        self.request = request
        self.deliveryQueue = queue
        self.resultHandler = resultHandler
        self.taskDelegate = delegate
        self.script = script
        self.isURLRequest = request is SFSpeechURLRecognitionRequest
        super.init()
        if let buffer = request as? SFSpeechAudioBufferRecognitionRequest {
            buffer.attachedTask = self
        }
    }

    /// Citation: [cancel()](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/cancel())
    /// — cancels the current speech recognition task. Header: canceling means
    /// no more recognition results will arrive.
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
        complete(
            result: nil,
            error: speechLSRError(
                SpeechHostControl.lsrRequestCanceled,
                description: "Request was canceled."
            ),
            cancelled: true
        )
    }

    /// Citation: [finish()](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/finish())
    /// — stops accepting new audio and finishes processing already-accepted
    /// audio. "For audio buffer–based recognition, recognition does not finish
    /// until this method is called." "has no effect on URL-based recognition
    /// requests, which effectively buffer the entire file immediately."
    public func finish() {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        if isURLRequest {
            lock.unlock()
            return
        }
        isFinishing = true
        if state == .starting || state == .running {
            state = .finishing
        }
        lock.unlock()
        hostAudioInputEnded()
    }

    fileprivate func start() {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        state = .running
        lock.unlock()

        let authorization = speechCurrentAuthorizationStatus()
        if authorization != .authorized {
            complete(
                result: nil,
                error: speechAssistantError(
                    SpeechHostControl.assistantRequestNotAuthorized,
                    description: "Request is not authorized."
                ),
                cancelled: false
            )
            return
        }

        if request.requiresOnDeviceRecognition && script?.supportsOnDeviceRecognition != true {
            complete(
                result: nil,
                error: speechLSRError(
                    SpeechHostControl.lsrAssetsNotInstalled,
                    description: "Assets are not installed."
                ),
                cancelled: false
            )
            return
        }

        guard let script else {
            if isURLRequest {
                complete(
                    result: nil,
                    error: speechLSRError(
                        SpeechHostControl.lsrAssetsNotInstalled,
                        description: "Assets are not installed."
                    ),
                    cancelled: false
                )
            }
            return
        }

        if isURLRequest {
            deliverScriptedResults(script)
        }
    }

    fileprivate func hostAudioInputEnded() {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        if state == .running {
            state = .finishing
        }
        isFinishing = true
        let hasScript = script != nil
        lock.unlock()

        if let script, hasScript {
            deliverScriptedResults(script)
        } else if !hasScript {
            complete(
                result: nil,
                error: speechLSRError(
                    SpeechHostControl.lsrAssetsNotInstalled,
                    description: "Assets are not installed."
                ),
                cancelled: false
            )
        }
    }

    private func deliverScriptedResults(_ script: SpeechScriptedRecognizer) {
        let once: Bool = {
            lock.lock()
            defer { lock.unlock() }
            if finished { return false }
            return true
        }()
        guard once else { return }

        speechDeliverOnQueue(deliveryQueue) { [self] in
            lock.lock()
            if finished {
                lock.unlock()
                return
            }
            lock.unlock()

            // running: "Speech recognition (potentially including audio recording) is in progress."
            taskDelegate?.speechRecognitionDidDetectSpeech(self)

            let partials = script.results.filter { !$0.isFinal }
            let finals = script.results.filter(\.isFinal)
            if request.shouldReportPartialResults {
                for partial in partials {
                    let transcription = makeTranscription(partial)
                    taskDelegate?.speechRecognitionTask(self, didHypothesizeTranscription: transcription)
                    resultHandler?(makeResult(partial, transcription: transcription), nil)
                }
            }

            let duration = (finals + partials).map(\.speechDuration).max() ?? 0
            taskDelegate?.speechRecognitionTask(self, didProcessAudioDuration: duration)
            taskDelegate?.speechRecognitionTaskFinishedReadingAudio(self)

            lock.lock()
            if !finished {
                // finishing: "No more audio is being recorded, but more recognition results may arrive."
                state = .finishing
                isFinishing = true
            }
            lock.unlock()

            let finalScript = finals.last ?? SpeechScriptedResult(
                formattedString: script.results.last?.formattedString ?? "",
                segments: script.results.last?.segments ?? [],
                isFinal: true
            )
            let transcription = makeTranscription(finalScript)
            let result = makeResult(finalScript, transcription: transcription)
            taskDelegate?.speechRecognitionTask(self, didFinishRecognition: result)
            complete(result: result, error: nil, cancelled: false)
        }
    }

    private func makeTranscription(_ script: SpeechScriptedResult) -> SFTranscription {
        var location = 0
        let segments = script.segments.map { segment -> SFTranscriptionSegment in
            let range = NSRange(location: location, length: (segment.substring as NSString).length)
            location = range.location + range.length
            return SFTranscriptionSegment(
                substring: segment.substring,
                substringRange: range,
                timestamp: segment.timestamp,
                duration: segment.duration,
                confidence: segment.confidence,
                alternativeSubstrings: segment.alternativeSubstrings
            )
        }
        return SFTranscription(
            formattedString: script.formattedString,
            segments: segments,
            speakingRate: script.speakingRate,
            averagePauseDuration: script.averagePauseDuration
        )
    }

    private func makeResult(
        _ script: SpeechScriptedResult,
        transcription: SFTranscription
    ) -> SFSpeechRecognitionResult {
        var transcriptions = [transcription]
        for alternative in script.alternativeFormattedStrings {
            transcriptions.append(SFTranscription(formattedString: alternative))
        }
        let metadata = SFSpeechRecognitionMetadata(
            averagePauseDuration: script.averagePauseDuration,
            speakingRate: script.speakingRate,
            speechDuration: script.speechDuration,
            speechStartTimestamp: script.speechStartTimestamp,
            voiceAnalytics: nil
        )
        return SFSpeechRecognitionResult(
            bestTranscription: transcription,
            transcriptions: transcriptions,
            isFinal: script.isFinal,
            speechRecognitionMetadata: script.isFinal ? metadata : nil
        )
    }

    private func complete(result: SFSpeechRecognitionResult?, error: (any Error)?, cancelled: Bool) {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        self.error = error
        if cancelled {
            state = .completed
            isCancelled = true
        } else {
            state = .completed
        }
        isFinishing = true
        let handler = resultHandler
        resultHandler = nil
        let delegate = taskDelegate
        taskDelegate = nil
        let queue = deliveryQueue
        lock.unlock()

        speechDeliverOnQueue(queue) {
            handler?(result, error)
            if cancelled {
                delegate?.speechRecognitionTaskWasCancelled(self)
            }
            delegate?.speechRecognitionTask(self, didFinishSuccessfully: error == nil && !cancelled)
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
    /// Citation: [isAvailable](https://developer.apple.com/documentation/speech/sfspeechrecognizer/isavailable)
    /// and [supportedLocales()](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportedlocales()):
    /// support does not mean currently available. This host stays `false` unless
    /// `SpeechHostControl.registerScriptedRecognizer` installs a script for the locale.
    public var isAvailable: Bool {
        SpeechScriptStore.shared.script(for: locale) != nil
    }

    private var activeTasks: [SFSpeechRecognitionTask] = []

    public class func authorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        speechCurrentAuthorizationStatus()
    }

    /// Citation: [requestAuthorization(_:)](https://developer.apple.com/documentation/speech/sfspeechrecognizer/requestauthorization(_:))
    /// and [Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition).
    /// Darwin presents a TCC prompt on the first call and remembers the answer.
    /// Linux has no prompt: `.notDetermined` fail-closes to `.denied` unless a
    /// host decision is installed. The handler runs on the calling thread
    /// (this isolated host has no run loop). Darwin main-queue identity is an
    /// oracle item.
    public class func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        if speechCurrentAuthorizationStatus() == .notDetermined {
            let decided = speechTakeAuthorizationDecision() ?? .denied
            speechStoreAuthorizationStatus(decided)
        }
        let status = speechCurrentAuthorizationStatus()
        speechDeliverOnMain {
            handler(status)
        }
    }

    public class func supportedLocales() -> Set<Locale> {
        SpeechDocumentedLocales.locales
    }

    /// Graph overlay is `convenience init?()`. Linux `NSObject.init()` is
    /// non-failable, so this override always succeeds with the documented
    /// host default locale (`Locale.current` when supported, else `en-US`).
    public override init() {
        self.locale = SpeechDocumentedLocales.hostDefaultLocale()
        let queue = OperationQueue()
        queue.name = "Speech.SFSpeechRecognizer"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.queue = queue
        super.init()
        queue.underlyingQueue = queueBackend
        SpeechScriptStore.shared.track(self)
        if let script = SpeechScriptStore.shared.script(for: locale) {
            supportsOnDeviceRecognition = script.supportsOnDeviceRecognition
        }
    }

    /// Citation: [init(locale:)](https://developer.apple.com/documentation/speech/sfspeechrecognizer/init(locale:))
    /// — returns `nil` if the locale is not supported. Darwin may fall back to
    /// the keyboard dictation language; that fallback is unobserved here.
    public init?(locale: Locale) {
        guard let matched = SpeechDocumentedLocales.matchingSupportedLocale(locale) else {
            return nil
        }
        self.locale = matched
        let queue = OperationQueue()
        queue.name = "Speech.SFSpeechRecognizer"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.queue = queue
        super.init()
        queue.underlyingQueue = queueBackend
        SpeechScriptStore.shared.track(self)
        if let script = SpeechScriptStore.shared.script(for: matched) {
            supportsOnDeviceRecognition = script.supportsOnDeviceRecognition
        }
    }

    func hostAvailabilityDidChange(_ available: Bool) {
        let recognizer = self
        speechDeliverOnQueue(queue) {
            recognizer.delegate?.speechRecognizer(recognizer, availabilityDidChange: available)
        }
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        delegate: any SFSpeechRecognitionTaskDelegate
    ) -> SFSpeechRecognitionTask {
        makeTask(request: request, resultHandler: nil, delegate: delegate)
    }

    public func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, (any Error)?) -> Void
    ) -> SFSpeechRecognitionTask {
        makeTask(request: request, resultHandler: resultHandler, delegate: nil)
    }

    private func makeTask(
        request: SFSpeechRecognitionRequest,
        resultHandler: ((SFSpeechRecognitionResult?, (any Error)?) -> Void)?,
        delegate: (any SFSpeechRecognitionTaskDelegate)?
    ) -> SFSpeechRecognitionTask {
        if request.taskHint == .unspecified {
            request.taskHint = defaultTaskHint
        }
        let task = SFSpeechRecognitionTask(
            request: request,
            queue: queue,
            resultHandler: resultHandler,
            delegate: delegate,
            script: SpeechScriptStore.shared.script(for: locale)
        )
        activeTasks.append(task)
        speechDeliverOnQueue(queue) {
            task.start()
        }
        return task
    }
}
