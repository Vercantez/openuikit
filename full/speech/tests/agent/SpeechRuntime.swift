@_spi(OpenUIKitHost) import Speech
import Foundation

struct SpeechNeverResults<Element: Sendable>: Sendable, AsyncSequence {
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    struct AsyncIterator: AsyncIteratorProtocol {
        mutating func next() async -> Element? { nil }
    }
}

func speechRunAsync(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task.detached {
        await body()
        semaphore.signal()
    }
    precondition(
        semaphore.wait(timeout: .now() + 10) == .success,
        "async speech probe timed out"
    )
}

func speechRequireAssistantUnauthorized(_ error: (any Error)?) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kAFAssistantErrorDomain)
    precondition(nsError?.code == SpeechHostControl.assistantRequestNotAuthorized)
}

func speechRequireLSR(_ error: (any Error)?, code: Int) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kLSRErrorDomain)
    precondition(nsError?.code == code)
}

func speechHash<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    value.hash(into: &hasher)
    return hasher.finalize()
}

final class SpeechRecordingDelegate: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var success: Bool?
    private var cancelled = false
    private var detected = false
    private var hypothesized = 0
    private var finishedRecognition: SFSpeechRecognitionResult?
    private var finishedAudio = false
    private var processedDuration: TimeInterval = 0

    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        detected = true
        lock.unlock()
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    ) {
        lock.lock()
        hypothesized += 1
        _ = transcription
        lock.unlock()
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        lock.lock()
        finishedRecognition = recognitionResult
        lock.unlock()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didProcessAudioDuration duration: TimeInterval) {
        lock.lock()
        processedDuration = duration
        lock.unlock()
    }

    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        finishedAudio = true
        lock.unlock()
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        lock.lock()
        success = successfully
        lock.unlock()
    }

    func snapshot() -> (
        success: Bool?,
        cancelled: Bool,
        detected: Bool,
        hypothesized: Int,
        result: SFSpeechRecognitionResult?,
        finishedAudio: Bool,
        duration: TimeInterval
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (success, cancelled, detected, hypothesized, finishedRecognition, finishedAudio, processedDuration)
    }
}

final class SpeechAvailabilityDelegate: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var available: Bool?

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        lock.lock()
        self.available = available
        lock.unlock()
    }

    func snapshot() -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        return available
    }
}

func speechAuthorizeForTests() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    var seen: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        seen = status
    }
    precondition(seen == .authorized)
    precondition(SFSpeechRecognizer.authorizationStatus() == .authorized)
}

func speechRegisterEnglishScript(
    results: [SpeechScriptedResult],
    supportsOnDeviceRecognition: Bool = true
) {
    SpeechHostControl.registerScriptedRecognizer(
        locale: Locale(identifier: "en-US"),
        results: results,
        supportsOnDeviceRecognition: supportsOnDeviceRecognition
    )
}

// MARK: - SpeechErrorTests.swift
func testSFSpeechErrorCodes() {
    let table: [(SFSpeechError.Code, Int)] = [
        (.internalServiceError, 1),
        (.audioReadFailed, 2),
        (.undefinedTemplateClassName, 7),
        (.malformedSupplementalModel, 8),
        (.timeout, 12),
        (.missingParameter, 13),
        (.audioDisordered, 1001),
        (.moduleOutputFailed, 1002),
        (.insufficientResources, 1003),
        (.unexpectedAudioFormat, 1004),
        (.assetLocaleNotAllocated, 1005),
        (.incompatibleAudioFormats, 1006),
        (.tooManyAssetLocalesAllocated, 1007),
        (.cannotAllocateUnsupportedLocale, 1008),
        (.noModel, 1009),
    ]
    for (code, raw) in table {
        precondition(code.rawValue == raw)
        precondition(SFSpeechError.Code(rawValue: raw) == code)
        _ = speechHash(code)
        _ = code.hashValue
    }
    precondition(SFSpeechError.Code(rawValue: 1) != .timeout)
    precondition(SFSpeechError.audioReadFailed == .audioReadFailed)
    precondition(SFSpeechError.internalServiceError == .internalServiceError)
    precondition(SFSpeechError.malformedSupplementalModel == .malformedSupplementalModel)
    precondition(SFSpeechError.missingParameter == .missingParameter)
    precondition(SFSpeechError.timeout == .timeout)
    precondition(SFSpeechError.undefinedTemplateClassName == .undefinedTemplateClassName)
    precondition(SFSpeechErrorDomain == "SFSpeechErrorDomain")
    precondition(SFSpeechError.errorDomain == SFSpeechErrorDomain)

    let error = SFSpeechError(.internalServiceError, userInfo: ["x": 1])
    precondition(error.code == .internalServiceError)
    precondition(error.errorCode == 1)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String != nil)
    precondition(error.userInfo[NSLocalizedDescriptionKey] as? String != nil)
    precondition(error.localizedDescription.isEmpty == false)
    precondition((error as NSError).domain == SFSpeechErrorDomain)
    precondition(error == SFSpeechError(.internalServiceError))
    precondition(error != SFSpeechError(.timeout))
    _ = speechHash(error)
    _ = error.hashValue

    let code: SFSpeechError.Code = .timeout
    switch code {
    case .timeout:
        break
    default:
        fatalError("timeout mismatch")
    }
}

// MARK: - SpeechEnumTests.swift
func testSpeechClassicEnums() {
    precondition(SFSpeechRecognitionTaskHint.unspecified.rawValue == 0)
    precondition(SFSpeechRecognitionTaskHint.dictation.rawValue == 1)
    precondition(SFSpeechRecognitionTaskHint.search.rawValue == 2)
    precondition(SFSpeechRecognitionTaskHint.confirmation.rawValue == 3)
    precondition(SFSpeechRecognitionTaskHint(rawValue: 1) == .dictation)
    precondition(SFSpeechRecognitionTaskHint.dictation != .search)
    _ = speechHash(SFSpeechRecognitionTaskHint.dictation)
    _ = SFSpeechRecognitionTaskHint.search.hashValue

    precondition(SFSpeechRecognitionTaskState.starting.rawValue == 0)
    precondition(SFSpeechRecognitionTaskState.running.rawValue == 1)
    precondition(SFSpeechRecognitionTaskState.finishing.rawValue == 2)
    precondition(SFSpeechRecognitionTaskState.canceling.rawValue == 3)
    precondition(SFSpeechRecognitionTaskState.completed.rawValue == 4)
    precondition(SFSpeechRecognitionTaskState(rawValue: 2) == .finishing)
    precondition(SFSpeechRecognitionTaskState.running != .completed)
    _ = speechHash(SFSpeechRecognitionTaskState.running)
    _ = SFSpeechRecognitionTaskState.finishing.hashValue

    precondition(SFSpeechRecognizerAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied.rawValue == 1)
    precondition(SFSpeechRecognizerAuthorizationStatus.restricted.rawValue == 2)
    precondition(SFSpeechRecognizerAuthorizationStatus.authorized.rawValue == 3)
    precondition(SFSpeechRecognizerAuthorizationStatus(rawValue: 3) == .authorized)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied != .authorized)
    _ = speechHash(SFSpeechRecognizerAuthorizationStatus.authorized)
    _ = SFSpeechRecognizerAuthorizationStatus.restricted.hashValue
}

func testSpeechTranscriberEnums() {
    let reporting: [SpeechTranscriber.ReportingOption] = [
        .fastResults, .volatileResults, .alternativeTranscriptions,
    ]
    precondition(SpeechTranscriber.ReportingOption.allCases.count == 3)
    for option in reporting {
        precondition(SpeechTranscriber.ReportingOption.allCases.contains(option))
        _ = speechHash(option)
        _ = option.hashValue
    }
    precondition(SpeechTranscriber.ReportingOption.fastResults != .volatileResults)
    _ = SpeechTranscriber.ReportingOption.AllCases.self

    precondition(SpeechTranscriber.TranscriptionOption.allCases.contains(.etiquetteReplacements))
    precondition(SpeechTranscriber.TranscriptionOption.etiquetteReplacements == .etiquetteReplacements)
    _ = speechHash(SpeechTranscriber.TranscriptionOption.etiquetteReplacements)
    _ = SpeechTranscriber.TranscriptionOption.etiquetteReplacements.hashValue
    _ = SpeechTranscriber.TranscriptionOption.AllCases.self

    precondition(SpeechTranscriber.ResultAttributeOption.allCases.contains(.audioTimeRange))
    precondition(SpeechTranscriber.ResultAttributeOption.allCases.contains(.transcriptionConfidence))
    precondition(SpeechTranscriber.ResultAttributeOption.audioTimeRange != .transcriptionConfidence)
    _ = speechHash(SpeechTranscriber.ResultAttributeOption.audioTimeRange)
    _ = SpeechTranscriber.ResultAttributeOption.transcriptionConfidence.hashValue
    _ = SpeechTranscriber.ResultAttributeOption.AllCases.self
}

func testDictationTranscriberEnums() {
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.volatileResults))
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.frequentFinalization))
    precondition(DictationTranscriber.ReportingOption.allCases.contains(.alternativeTranscriptions))
    precondition(DictationTranscriber.ReportingOption.volatileResults != .frequentFinalization)
    _ = speechHash(DictationTranscriber.ReportingOption.volatileResults)
    _ = DictationTranscriber.ReportingOption.frequentFinalization.hashValue
    _ = DictationTranscriber.ReportingOption.AllCases.self

    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.punctuation))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.etiquetteReplacements))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.emoji))
    precondition(DictationTranscriber.TranscriptionOption.punctuation != .emoji)
    _ = speechHash(DictationTranscriber.TranscriptionOption.punctuation)
    _ = DictationTranscriber.TranscriptionOption.emoji.hashValue
    _ = DictationTranscriber.TranscriptionOption.AllCases.self

    precondition(DictationTranscriber.ResultAttributeOption.allCases.contains(.audioTimeRange))
    precondition(DictationTranscriber.ResultAttributeOption.allCases.contains(.transcriptionConfidence))
    precondition(DictationTranscriber.ResultAttributeOption.audioTimeRange != .transcriptionConfidence)
    _ = speechHash(DictationTranscriber.ResultAttributeOption.audioTimeRange)
    _ = DictationTranscriber.ResultAttributeOption.transcriptionConfidence.hashValue
    _ = DictationTranscriber.ResultAttributeOption.AllCases.self
}

func testSpeechDetectorSensitivityEnum() {
    precondition(SpeechDetector.SensitivityLevel.low.rawValue == 0)
    precondition(SpeechDetector.SensitivityLevel.medium.rawValue == 1)
    precondition(SpeechDetector.SensitivityLevel.high.rawValue == 2)
    precondition(SpeechDetector.SensitivityLevel(rawValue: 1) == .medium)
    precondition(SpeechDetector.SensitivityLevel.allCases.count == 3)
    precondition(SpeechDetector.SensitivityLevel.low != .high)
    _ = speechHash(SpeechDetector.SensitivityLevel.high)
    _ = SpeechDetector.SensitivityLevel.medium.hashValue
    _ = SpeechDetector.SensitivityLevel.AllCases.self
    _ = SpeechDetector.SensitivityLevel.RawValue.self
}

func testSpeechAnalyzerModelRetentionEnum() {
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.whileInUse))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.processLifetime))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.lingering))
    precondition(SpeechAnalyzer.Options.ModelRetention.whileInUse != .lingering)
    _ = speechHash(SpeechAnalyzer.Options.ModelRetention.processLifetime)
    _ = SpeechAnalyzer.Options.ModelRetention.lingering.hashValue
    _ = SpeechAnalyzer.Options.ModelRetention.AllCases.self
}

func testAssetInventoryStatusEnum() {
    precondition(AssetInventory.Status.unsupported < .supported)
    precondition(AssetInventory.Status.supported < .downloading)
    precondition(AssetInventory.Status.downloading < .installed)
    precondition(AssetInventory.Status.unsupported != .installed)
    precondition(AssetInventory.Status.installed == .installed)
    precondition(AssetInventory.Status.installed > .unsupported)
    precondition(AssetInventory.Status.installed >= .downloading)
    precondition(AssetInventory.Status.unsupported <= .supported)
    let closed = AssetInventory.Status.unsupported ... .installed
    precondition(closed.contains(.supported))
    let half = AssetInventory.Status.unsupported ..< .installed
    precondition(half.contains(.downloading))
    precondition(half.contains(.installed) == false)
    let from = AssetInventory.Status.supported...
    precondition(from.contains(.installed))
    let through = ...AssetInventory.Status.supported
    precondition(through.contains(.unsupported))
    let upTo = ..<AssetInventory.Status.installed
    precondition(upTo.contains(.downloading))
    _ = speechHash(AssetInventory.Status.installed)
    _ = AssetInventory.Status.supported.hashValue
}

// MARK: - SpeechRecognizerTests.swift
func testSupportedLocales() {
    let locales = SFSpeechRecognizer.supportedLocales()
    precondition(locales.isEmpty == false)
    precondition(locales.contains(Locale(identifier: "en-US")))
    precondition(locales.contains(Locale(identifier: "ja-JP")))
    precondition(locales.contains(Locale(identifier: "zh-CN")))
}

func testSpeechRecognizerInit() {
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    precondition(recognizer != nil)
    let unwrapped = recognizer!
    let asObject: NSObject = unwrapped
    precondition(asObject === unwrapped)
    precondition(unwrapped.locale.identifier == "en-US")
    precondition(unwrapped.supportsOnDeviceRecognition == false)
    unwrapped.defaultTaskHint = .dictation
    precondition(unwrapped.defaultTaskHint == .dictation)
    unwrapped.supportsOnDeviceRecognition = true
    precondition(unwrapped.supportsOnDeviceRecognition)
    unwrapped.queue.isSuspended = false
    precondition(unwrapped.queue.isSuspended == false)
    let defaultRecognizer = SFSpeechRecognizer()
    precondition(defaultRecognizer.locale.identifier.isEmpty == false)
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "zz-ZZ")) == nil)
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "fr_FR")) != nil)
}

func testSpeechRecognizerAuthorization() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    precondition(SFSpeechRecognizer.authorizationStatus() == .notDetermined)

    var first: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        first = status
    }
    precondition(first == .denied)
    precondition(SFSpeechRecognizer.authorizationStatus() == .denied)

    var second: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        second = status
    }
    precondition(second == .denied)

    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    var granted: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        granted = status
    }
    precondition(granted == .authorized)
    precondition(SFSpeechRecognizer.authorizationStatus() == .authorized)
}

func testSpeechRecognizerAvailability() {
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    precondition(recognizer.isAvailable == false)
    let availability = SpeechAvailabilityDelegate()
    recognizer.delegate = availability
    speechRegisterEnglishScript(
        results: [SpeechScriptedResult(formattedString: "hello", isFinal: true)]
    )
    precondition(availability.snapshot() == true)
    precondition(recognizer.isAvailable)
    precondition(recognizer.delegate === availability)
}

// MARK: - SpeechRequestTests.swift
func testSpeechRecognitionRequestProperties() {
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    request.addsPunctuation = true
    request.contextualStrings = ["OpenUIKit"]
    request.shouldReportPartialResults = false
    request.requiresOnDeviceRecognition = true
    request.taskHint = .search
    request.interactionIdentifier = "probe"
    let modelURL = URL(fileURLWithPath: "/tmp/model.bin")
    request.customizedLanguageModel = SFSpeechLanguageModel.Configuration(languageModel: modelURL)
    precondition(request.customizedLanguageModel?.languageModel == modelURL)
    precondition(request.addsPunctuation)
    precondition(request.contextualStrings == ["OpenUIKit"])
    precondition(request.shouldReportPartialResults == false)
    precondition(request.requiresOnDeviceRecognition)
    precondition(request.taskHint == .search)
    precondition(request.interactionIdentifier == "probe")
}

func testSpeechURLRecognitionRequest() {
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    precondition(request.url.path == "/tmp/speech.wav")
    let labeled = SFSpeechURLRecognitionRequest(URL: URL(fileURLWithPath: "/tmp/b.wav"))
    precondition(labeled.url.path == "/tmp/b.wav")
}

func testSpeechAudioBufferRequest() {
    let request = SFSpeechAudioBufferRecognitionRequest()
    precondition(request.nativeAudioFormat.sampleRate == 16_000)
    precondition(request.nativeAudioFormat.channelCount == 1)
    request.append(SpeechHostPCMBuffer(frameLength: 1600))
    request.appendAudioSampleBuffer(SpeechHostSampleBuffer(data: Data([0, 1])))
    precondition(request.appendedBufferCount == 2)
    request.endAudio()
    precondition(request.didEndAudio)
}

// MARK: - SpeechTaskTests.swift
func testSpeechRecognitionTaskUnauthorized() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    var sawHandler = false
    let task = recognizer.recognitionTask(with: request) { result, error in
        sawHandler = true
        precondition(result == nil)
        speechRequireAssistantUnauthorized(error)
    }
    precondition(sawHandler)
    speechRequireAssistantUnauthorized(task.error)
    precondition(task.state == .completed)
}

func testSpeechRecognitionTaskMissingAssets() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    var sawHandler = false
    let task = recognizer.recognitionTask(with: request) { result, error in
        sawHandler = true
        precondition(result == nil)
        speechRequireLSR(error, code: SpeechHostControl.lsrAssetsNotInstalled)
    }
    precondition(sawHandler)
    precondition(task.state == .completed)
    speechRequireLSR(task.error, code: SpeechHostControl.lsrAssetsNotInstalled)
}

func testSpeechRecognitionTaskCancel() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    speechRegisterEnglishScript(
        results: [SpeechScriptedResult(formattedString: "hello", isFinal: true)]
    )
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechAudioBufferRecognitionRequest()
    let delegate = SpeechRecordingDelegate()
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    precondition(task.state == .starting || task.state == .running)
    task.cancel()
    precondition(task.isCancelled)
    precondition(task.state == .completed)
    let snap = delegate.snapshot()
    precondition(snap.success == false)
    precondition(snap.cancelled)
    speechRequireLSR(task.error, code: SpeechHostControl.lsrRequestCanceled)
}

func testSpeechRecognitionTaskScriptedDelegate() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let partial = SpeechScriptedResult(
        formattedString: "hel",
        segments: [
            SpeechScriptedSegment(substring: "hel", timestamp: 0, duration: 0.2, confidence: 0.4)
        ],
        isFinal: false,
        speechDuration: 0.2
    )
    let final = SpeechScriptedResult(
        formattedString: "hello world",
        segments: [
            SpeechScriptedSegment(
                substring: "hello",
                timestamp: 0,
                duration: 0.3,
                confidence: 0.95,
                alternativeSubstrings: ["halo"]
            ),
            SpeechScriptedSegment(
                substring: "world",
                timestamp: 0.3,
                duration: 0.4,
                confidence: 0.91
            )
        ],
        alternativeFormattedStrings: ["hello word"],
        isFinal: true,
        speakingRate: 110,
        averagePauseDuration: 0.08,
        speechDuration: 0.7,
        speechStartTimestamp: 0.02
    )
    speechRegisterEnglishScript(results: [partial, final])
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let delegate = SpeechRecordingDelegate()
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    request.shouldReportPartialResults = true
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    precondition(task.state == .completed)
    precondition(task.isCancelled == false)
    let snap = delegate.snapshot()
    precondition(snap.success == true)
    precondition(snap.detected)
    precondition(snap.hypothesized >= 1)
    precondition(snap.finishedAudio)
    precondition(snap.duration >= 0)
    precondition(snap.result?.isFinal == true)
    precondition(snap.result?.bestTranscription.formattedString == "hello world")
    precondition(snap.result?.bestTranscription.segments.count == 2)
}

func testSpeechRecognitionTaskHandler() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    speechRegisterEnglishScript(
        results: [SpeechScriptedResult(formattedString: "handler", isFinal: true)]
    )
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    var finals = 0
    _ = recognizer.recognitionTask(with: request) { result, error in
        precondition(error == nil)
        if result?.isFinal == true {
            finals += 1
            precondition(result?.bestTranscription.formattedString == "handler")
        }
    }
    precondition(finals == 1)
}

func testSpeechRecognitionTaskFinish() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    speechRegisterEnglishScript(
        results: [SpeechScriptedResult(formattedString: "buffer", isFinal: true, speechDuration: 0.3)]
    )
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = false
    let delegate = SpeechRecordingDelegate()
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    precondition(task.state == .starting || task.state == .running)
    request.append(SpeechHostPCMBuffer(frameLength: 320))
    request.endAudio()
    task.finish()
    precondition(task.isFinishing)
    precondition(task.state == .completed)
    precondition(delegate.snapshot().result?.bestTranscription.formattedString == "buffer")
}

// MARK: - SpeechTranscriptionTests.swift
func testSFAcousticFeature() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5, 0.25])
    precondition(feature.frameDuration == 0.01)
    precondition(feature.acousticFeatureValuePerFrame == [0.5, 0.25])
    let copied = feature.copy() as! SFAcousticFeature
    precondition(copied.isEqual(feature))
    precondition(copied !== feature)
    precondition(SFAcousticFeature(coder: NSCoder()) == nil)
}

func testSFVoiceAnalytics() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    precondition(analytics.jitter.isEqual(feature))
    precondition(analytics.pitch.isEqual(feature))
    precondition(analytics.shimmer.isEqual(feature))
    precondition(analytics.voicing.isEqual(feature))
    precondition((analytics.copy() as! SFVoiceAnalytics).isEqual(analytics))
    precondition(SFVoiceAnalytics(coder: NSCoder()) == nil)
}

func testSFTranscriptionSegment() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    let segment = SFTranscriptionSegment(
        substring: "hello",
        substringRange: NSRange(location: 0, length: 5),
        timestamp: 0.1,
        duration: 0.4,
        confidence: 0.92,
        alternativeSubstrings: ["helloo"],
        voiceAnalytics: analytics
    )
    precondition(segment.substring == "hello")
    precondition(segment.substringRange.location == 0)
    precondition(segment.timestamp == 0.1)
    precondition(segment.duration == 0.4)
    precondition(segment.confidence == 0.92)
    precondition(segment.alternativeSubstrings == ["helloo"])
    precondition(segment.voiceAnalytics != nil)
    precondition(SFTranscriptionSegment(coder: NSCoder()) == nil)
}

func testSFTranscription() {
    let segment = SFTranscriptionSegment(
        substring: "hello",
        substringRange: NSRange(location: 0, length: 5),
        timestamp: 0.1,
        duration: 0.4,
        confidence: 0.92,
        alternativeSubstrings: [],
        voiceAnalytics: nil
    )
    let transcription = SFTranscription(
        formattedString: "hello",
        segments: [segment],
        speakingRate: 120,
        averagePauseDuration: 0.05
    )
    precondition(transcription.formattedString == "hello")
    precondition(transcription.segments.count == 1)
    precondition(transcription.speakingRate == 120)
    precondition(transcription.averagePauseDuration == 0.05)
    precondition(SFTranscription(coder: NSCoder()) == nil)
}

func testSFSpeechRecognitionMetadata() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    let metadata = SFSpeechRecognitionMetadata(
        averagePauseDuration: 0.05,
        speakingRate: 120,
        speechDuration: 0.5,
        speechStartTimestamp: 0.1,
        voiceAnalytics: analytics
    )
    precondition(metadata.averagePauseDuration == 0.05)
    precondition(metadata.speakingRate == 120)
    precondition(metadata.speechDuration == 0.5)
    precondition(metadata.speechStartTimestamp == 0.1)
    precondition(metadata.voiceAnalytics != nil)
    precondition(SFSpeechRecognitionMetadata(coder: NSCoder()) == nil)
}

func testSFSpeechRecognitionResult() {
    let transcription = SFTranscription(formattedString: "hello")
    let metadata = SFSpeechRecognitionMetadata(
        averagePauseDuration: 0.05,
        speakingRate: 120,
        speechDuration: 0.5,
        speechStartTimestamp: 0.1,
        voiceAnalytics: nil
    )
    let result = SFSpeechRecognitionResult(
        bestTranscription: transcription,
        transcriptions: [transcription, SFTranscription(formattedString: "halo")],
        isFinal: true,
        speechRecognitionMetadata: metadata
    )
    precondition(result.isFinal)
    precondition(result.bestTranscription.formattedString == "hello")
    precondition(result.transcriptions.count == 2)
    precondition(result.speechRecognitionMetadata?.speechDuration == 0.5)
    precondition(SFSpeechRecognitionResult(coder: NSCoder()) == nil)
}

// MARK: - SpeechLanguageModelTests.swift
func testSFSpeechLanguageModelConfiguration() {
    let modelURL = URL(fileURLWithPath: "/tmp/lm.bin")
    let vocabURL = URL(fileURLWithPath: "/tmp/vocab.txt")
    let short = SFSpeechLanguageModel.Configuration(languageModel: modelURL)
    precondition(short.languageModel == modelURL)
    precondition(short.vocabulary == nil)
    precondition(short.weight == nil)
    let withVocab = SFSpeechLanguageModel.Configuration(languageModel: modelURL, vocabulary: vocabURL)
    precondition(withVocab.vocabulary == vocabURL)
    let config = SFSpeechLanguageModel.Configuration(
        languageModel: modelURL,
        vocabulary: vocabURL,
        weight: NSNumber(value: 1.5)
    )
    precondition(config.languageModel.path.hasSuffix("lm.bin"))
    precondition(config.vocabulary?.path.hasSuffix("vocab.txt") == true)
    precondition(config.weight?.doubleValue == 1.5)
    precondition(SFSpeechLanguageModel.Configuration(coder: NSCoder()) == nil)
}

func testPrepareCustomLanguageModel() {
    let config = SFSpeechLanguageModel.Configuration(
        languageModel: URL(fileURLWithPath: "/tmp/lm.bin")
    )
    speechRunAsync {
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                clientIdentifier: "client",
                configuration: config
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                clientIdentifier: "client",
                configuration: config,
                ignoresCache: true
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                configuration: config
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
        do {
            try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                for: URL(fileURLWithPath: "/tmp/asset"),
                configuration: config,
                ignoresCache: true
            )
            fatalError("prepare should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}

// MARK: - SpeechAnalyzerTests.swift
func testAnalysisContext() {
    let context = AnalysisContext()
    let topic = AnalysisContext.UserDataTag("topic")
    let rawTag = AnalysisContext.UserDataTag(rawValue: "other")
    precondition(topic.rawValue == "topic")
    precondition(rawTag.rawValue == "other")
    precondition(topic != rawTag)
    _ = speechHash(topic)
    _ = topic.hashValue
    _ = AnalysisContext.UserDataTag.RawValue.self

    let general = AnalysisContext.ContextualStringsTag.general
    let other = AnalysisContext.ContextualStringsTag("other")
    let rawStrings = AnalysisContext.ContextualStringsTag(rawValue: "custom")
    precondition(general.rawValue == "general")
    precondition(other.rawValue == "other")
    precondition(rawStrings.rawValue == "custom")
    precondition(general != other)
    _ = speechHash(general)
    _ = general.hashValue
    _ = AnalysisContext.ContextualStringsTag.RawValue.self

    context.contextualStrings[.general] = ["OpenUIKit"]
    context.userData[topic] = "speech"
    precondition(context.contextualStrings[.general] == ["OpenUIKit"])
    precondition(context.userData[topic] as? String == "speech")
}

func testSpeechAnalyzerLifecycle() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    let options = SpeechAnalyzer.Options(priority: .medium, modelRetention: .whileInUse)
    precondition(options.priority == .medium)
    precondition(options.modelRetention == .whileInUse)
    let other = SpeechAnalyzer.Options(priority: .high, modelRetention: .lingering)
    precondition(options != other)
    precondition(options == SpeechAnalyzer.Options(priority: .medium, modelRetention: .whileInUse))
    _ = speechHash(options)

    let context = AnalysisContext()
    context.contextualStrings[.general] = ["OpenUIKit"]
    speechRunAsync {
        let analyzer = SpeechAnalyzer(modules: [transcriber], options: options)
        try? await analyzer.setContext(context)
        let stored = await analyzer.context
        precondition(stored.contextualStrings[.general] == ["OpenUIKit"])
        try? await analyzer.setModules([dictation])
        do {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
            fatalError("analyzer should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .noModel)
        }
        await analyzer.cancelAndFinishNow()
        let moduleCount = await analyzer.modules.count
        precondition(moduleCount == 1)
    }
}

func testSpeechAnalyzerIsolation() {
    speechRunAsync {
        let analyzer = SpeechAnalyzer(modules: [])
        await analyzer.hostCheckIsolation()
        _ = analyzer.unownedExecutor
    }
}

func testAssetInventory() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    speechRunAsync {
        let status = await AssetInventory.status(forModules: [transcriber])
        precondition(status == .unsupported)
        precondition(AssetInventory.maximumReservedLocales == 0)
        let reserved = await AssetInventory.reservedLocales
        precondition(reserved.isEmpty)
        do {
            _ = try await AssetInventory.reserve(locale: Locale(identifier: "en-US"))
            fatalError("reserve should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .cannotAllocateUnsupportedLocale)
        }
        let released = await AssetInventory.release(reservedLocale: Locale(identifier: "en-US"))
        precondition(released == false)
        let request = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber])
        precondition(request == nil)
    }
}

func testAssetInstallationRequest() {
    let install = AssetInstallationRequest()
    precondition(install.progress.totalUnitCount == 1)
    speechRunAsync {
        do {
            try await install.downloadAndInstall()
            fatalError("download should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}

func testSpeechModels() {
    speechRunAsync {
        await SpeechModels.endRetention()
    }
}

func testSpeechModuleProtocols() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    let detector = SpeechDetector()
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    precondition(transcriber.selectedLocales.count == 1)
    precondition(dictation.selectedLocales.count == 1)
    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.isFinal)
    precondition(SpeechDetector.Result(speechDetected: true).isFinal)
    precondition(DictationTranscriber.Result(text: AttributedString("d"), isFinal: true).isFinal)
    _ = SpeechTranscriber.Result.self
    _ = SpeechTranscriber.Results.self
    _ = SpeechDetector.Results.self
    _ = DictationTranscriber.Results.self
    speechRunAsync {
        let supported = await SpeechTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let equivalent = await SpeechTranscriber.supportedLocale(
            equivalentTo: Locale(identifier: "en-US")
        )
        precondition(equivalent == nil)
        var iterator = transcriber.results.makeAsyncIterator()
        let next = try? await iterator.next()
        precondition(next == nil)
        var detectorIterator = detector.results.makeAsyncIterator()
        _ = try? await detectorIterator.next()
        var dictationIterator = dictation.results.makeAsyncIterator()
        _ = try? await dictationIterator.next()
    }
}

// MARK: - SpeechTranscriberTests.swift
func testSpeechTranscriberPresets() {
    let custom = SpeechTranscriber.Preset(
        transcriptionOptions: [.etiquetteReplacements],
        reportingOptions: [.volatileResults],
        attributeOptions: [.audioTimeRange]
    )
    precondition(custom.transcriptionOptions.contains(.etiquetteReplacements))
    precondition(custom.reportingOptions.contains(.volatileResults))
    precondition(custom.attributeOptions.contains(.audioTimeRange))
    precondition(SpeechTranscriber.Preset.transcription != .progressiveTranscription)
    precondition(SpeechTranscriber.Preset.transcription == .transcription)
    _ = SpeechTranscriber.Preset.progressiveTranscription
    _ = SpeechTranscriber.Preset.transcriptionWithAlternatives
    _ = SpeechTranscriber.Preset.timeIndexedProgressiveTranscription
    _ = SpeechTranscriber.Preset.timeIndexedTranscriptionWithAlternatives
    _ = speechHash(custom)
    _ = custom.hashValue
}

func testSpeechTranscriberRuntime() {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    precondition(SpeechTranscriber.isAvailable == false)
    precondition(transcriber.selectedLocales.count == 1)
    let explicit = SpeechTranscriber(
        locale: Locale(identifier: "en-US"),
        transcriptionOptions: [.etiquetteReplacements],
        reportingOptions: [.fastResults],
        attributeOptions: [.transcriptionConfidence]
    )
    precondition(explicit.preset.transcriptionOptions.contains(.etiquetteReplacements))
    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.description == "x")
    precondition(hostResult.isFinal)
    precondition(hostResult.text.characters.elementsEqual("x"))
    precondition(hostResult.alternatives.isEmpty)
    precondition(hostResult != SpeechTranscriber.Result(text: AttributedString("y"), isFinal: false))
    _ = speechHash(hostResult)
    _ = hostResult.hashValue
    _ = SpeechTranscriber.Results.self
    speechRunAsync {
        let supported = await SpeechTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let installed = await SpeechTranscriber.installedLocales
        precondition(installed.isEmpty)
        let equivalent = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US"))
        precondition(equivalent == nil)
        var iterator = transcriber.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testDictationTranscriberPresets() {
    let custom = DictationTranscriber.Preset(
        contentHints: [.shortForm, .farField, .atypicalSpeech],
        transcriptionOptions: [.punctuation],
        reportingOptions: [.volatileResults],
        attributeOptions: [.audioTimeRange]
    )
    precondition(custom.contentHints.contains(.shortForm))
    precondition(custom.transcriptionOptions.contains(.punctuation))
    precondition(custom.reportingOptions.contains(.volatileResults))
    precondition(custom.attributeOptions.contains(.audioTimeRange))
    precondition(DictationTranscriber.Preset.phrase != .shortDictation)
    _ = DictationTranscriber.Preset.shortDictation
    _ = DictationTranscriber.Preset.longDictation
    _ = DictationTranscriber.Preset.progressiveShortDictation
    _ = DictationTranscriber.Preset.progressiveLongDictation
    _ = DictationTranscriber.Preset.timeIndexedLongDictation
    _ = speechHash(custom)
    _ = custom.hashValue
    precondition(DictationTranscriber.ContentHint.farField != .shortForm)
    precondition(DictationTranscriber.ContentHint.atypicalSpeech != .farField)
    _ = speechHash(DictationTranscriber.ContentHint.shortForm)
    _ = DictationTranscriber.ContentHint.farField.hashValue
    _ = DictationTranscriber.ContentHint.customizedLanguage(
        modelConfiguration: SFSpeechLanguageModel.Configuration(
            languageModel: URL(fileURLWithPath: "/tmp/lm.bin")
        )
    )
}

func testDictationTranscriberRuntime() {
    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    precondition(dictation.preset == .phrase)
    precondition(dictation.selectedLocales.count == 1)
    let explicit = DictationTranscriber(
        locale: Locale(identifier: "en-US"),
        contentHints: [.farField],
        transcriptionOptions: [.emoji],
        reportingOptions: [.frequentFinalization],
        attributeOptions: [.transcriptionConfidence]
    )
    precondition(explicit.preset.contentHints.contains(.farField))
    let result = DictationTranscriber.Result(text: AttributedString("dictation"), isFinal: true)
    precondition(result.description == "dictation")
    precondition(result.isFinal)
    precondition(result.alternatives.isEmpty)
    precondition(result != DictationTranscriber.Result(text: AttributedString("other"), isFinal: false))
    _ = speechHash(result)
    _ = result.hashValue
    _ = DictationTranscriber.Results.self
    speechRunAsync {
        let supported = await DictationTranscriber.supportedLocales
        precondition(supported.isEmpty)
        let installed = await DictationTranscriber.installedLocales
        precondition(installed.isEmpty)
        let equivalent = await DictationTranscriber.supportedLocale(
            equivalentTo: Locale(identifier: "en-US")
        )
        precondition(equivalent == nil)
        var iterator = dictation.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testSpeechDetectorRuntime() {
    let detector = SpeechDetector()
    precondition(detector.detectionOptions.sensitivityLevel == .medium)
    let options = SpeechDetector.DetectionOptions(sensitivityLevel: .high)
    precondition(options.sensitivityLevel == .high)
    precondition(options != SpeechDetector.DetectionOptions(sensitivityLevel: .low))
    _ = speechHash(options)
    _ = options.hashValue
    let detector2 = SpeechDetector(detectionOptions: options, reportResults: true)
    precondition(detector2.reportResults)
    precondition(detector2.detectionOptions == options)
    let detected = SpeechDetector.Result(speechDetected: false)
    precondition(detected.description == "silence")
    precondition(detected.speechDetected == false)
    precondition(detected.isFinal)
    _ = SpeechDetector.Results.self
    speechRunAsync {
        var iterator = detector.results.makeAsyncIterator()
        let first = try? await iterator.next()
        precondition(first == nil)
    }
}

func testSpeechDetectorOptionsHashable() {
    let low = SpeechDetector.DetectionOptions(sensitivityLevel: .low)
    let high = SpeechDetector.DetectionOptions(sensitivityLevel: .high)
    precondition(low != high)
    precondition(low == SpeechDetector.DetectionOptions(sensitivityLevel: .low))
    _ = speechHash(low)
    _ = low.hashValue
}

// MARK: - SpeechCustomLanguageModelTests.swift
func testCustomLanguageModelData() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    precondition(data.identifier == "probe")
    precondition(data.version == "1")
    precondition(data.locale.identifier == "en-US")
    let other = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    precondition(data == other)
    precondition(data != SFCustomLanguageModelData(locale: Locale(identifier: "fr-FR"), identifier: "x", version: "1"))
    _ = speechHash(data)
    _ = data.hashValue
    let encoded = try! JSONEncoder().encode(data)
    let decoded = try! JSONDecoder().decode(SFCustomLanguageModelData.self, from: encoded)
    precondition(decoded.identifier == "probe")
}

func testCustomLanguageModelInsert() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    let phrase = SFCustomLanguageModelData.PhraseCount(phrase: "OpenUIKit", count: 3)
    precondition(phrase.phrase == "OpenUIKit")
    precondition(phrase.count == 3)
    precondition(phrase.description.contains("OpenUIKit"))
    precondition(phrase != SFCustomLanguageModelData.PhraseCount(phrase: "other", count: 1))
    _ = speechHash(phrase)
    _ = phrase.hashValue
    data.insert(phraseCount: phrase)
    phrase.insert(data: data)
    let pronunciation = SFCustomLanguageModelData.CustomPronunciation(grapheme: "ui", phonemes: ["y", "u"])
    precondition(pronunciation.grapheme == "ui")
    precondition(pronunciation.phonemes == ["y", "u"])
    precondition(pronunciation.description.contains("ui"))
    precondition(pronunciation != SFCustomLanguageModelData.CustomPronunciation(grapheme: "b", phonemes: ["b"]))
    _ = speechHash(pronunciation)
    _ = pronunciation.hashValue
    data.insert(term: pronunciation)
    pronunciation.insert(data: data)
    precondition(data.snapshotPhraseCounts().contains(where: { $0.phrase == "OpenUIKit" && $0.count == 3 }))
    precondition(data.snapshotPronunciations().contains(where: { $0.grapheme == "ui" }))
    precondition(SFCustomLanguageModelData.supportedPhonemes(locale: Locale(identifier: "en-US")).isEmpty)
    let encodedPhrase = try! JSONEncoder().encode(phrase)
    let decodedPhrase = try! JSONDecoder().decode(SFCustomLanguageModelData.PhraseCount.self, from: encodedPhrase)
    precondition(decodedPhrase.count == 3)
    let encodedPron = try! JSONEncoder().encode(pronunciation)
    let decodedPron = try! JSONDecoder().decode(SFCustomLanguageModelData.CustomPronunciation.self, from: encodedPron)
    precondition(decodedPron.grapheme == "ui")
}

func testCustomLanguageModelBuilder() {
    let optionalPhrase: String? = "optional"
    let flag = true
    let items = ["a", "b"]
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "builder",
        version: "1",
        builder: {
            SFCustomLanguageModelData.PhraseCount(phrase: "OpenUIKit", count: 3)
            SFCustomLanguageModelData.CustomPronunciation(grapheme: "ui", phonemes: ["y", "u"])
            if let phrase = optionalPhrase {
                SFCustomLanguageModelData.PhraseCount(phrase: phrase, count: 1)
            }
            if flag {
                SFCustomLanguageModelData.PhraseCount(phrase: "yes", count: 1)
            } else {
                SFCustomLanguageModelData.PhraseCount(phrase: "no", count: 1)
            }
            for item in items {
                SFCustomLanguageModelData.PhraseCount(phrase: item, count: 1)
            }
            SFCustomLanguageModelData.PhraseCountsFromTemplates(
                classes: ["App": ["Mail"]]
            ) {
                SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("open {App}", count: 2)
                if flag {
                    SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("launch {App}", count: 1)
                } else {
                    SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("close {App}", count: 1)
                }
            }
        }
    )
    precondition(data.snapshotPhraseCounts().contains(where: { $0.phrase == "OpenUIKit" }))
    let compound = SFCustomLanguageModelData.CompoundTemplate([
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("x", count: 1)
    ])
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    compound.insert(generator: generator)
}

func testPhraseCountGenerator() {
    let generator = SFCustomLanguageModelData.PhraseCountGenerator()
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "gen",
        version: "1"
    )
    let encoded = try! JSONEncoder().encode(generator)
    let decoded = try! JSONDecoder().decode(SFCustomLanguageModelData.PhraseCountGenerator.self, from: encoded)
    precondition(generator == decoded)
    _ = speechHash(generator)
    _ = generator.hashValue
    generator.insert(data: data)
    data.insert(phraseCountGenerator: generator)
    _ = SFCustomLanguageModelData.PhraseCountGenerator.Element.self
    _ = SFCustomLanguageModelData.PhraseCountGenerator.AsyncIterator.self
    let nestedIterator = generator.makeAsyncIterator()
    _ = type(of: nestedIterator)
}

func testPhraseCountGeneratorSequence() {
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    speechRunAsync {
        do {
            let containsWhere = try await generator.contains { $0.phrase == "open {App}" }
            precondition(containsWhere)
            let containsValue = try await generator.contains(
                SFCustomLanguageModelData.PhraseCount(phrase: "open {App}", count: 2)
            )
            precondition(containsValue)
            let first = try await generator.first { $0.count == 2 }
            precondition(first?.count == 2)
            let all = try await generator.allSatisfy { $0.count > 0 }
            precondition(all)
            let reduced = try await generator.reduce(0) { $0 + $1.count }
            precondition(reduced == 2)
            _ = try await generator.reduce(into: 0) { partial, item in
                partial += item.count
            }
            var mapped: [String] = []
            for try await phrase in generator.map({ $0.phrase }) {
                mapped.append(phrase)
            }
            precondition(mapped == ["open {App}"])
            func throwingIdentity(_ value: String) throws -> String { value }
            var throwingMapped: [String] = []
            for try await phrase in generator.map({ try throwingIdentity($0.phrase) }) {
                throwingMapped.append(phrase)
            }
            precondition(throwingMapped == ["open {App}"])
            var filtered: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.filter({ $0.count == 2 }) {
                filtered.append(item)
            }
            precondition(filtered.count == 1)
            var prefixed: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.prefix(1) {
                prefixed.append(item)
            }
            precondition(prefixed.count == 1)
            var dropped: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.dropFirst(0) {
                dropped.append(item)
            }
            precondition(dropped.count == 1)
            var compactValues: [String] = []
            for try await item in generator.compactMap({ $0.count > 0 ? $0.phrase : nil }) {
                compactValues.append(item)
            }
            precondition(compactValues == ["open {App}"])
            var throwingCompact: [String] = []
            for try await item in generator.compactMap({ try throwingIdentity($0.phrase) as String? }) {
                throwingCompact.append(item)
            }
            precondition(throwingCompact == ["open {App}"])
            _ = try generator.prefix(while: { $0.count > 0 })
            _ = generator.drop(while: { $0.count == 0 })
            _ = try await generator.min(by: { $0.count < $1.count })
            _ = try await generator.max(by: { $0.count < $1.count })
            var emptyFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in
                SpeechEmptyResults<SFCustomLanguageModelData.PhraseCount>()
            }) {
                emptyFlat.append(item)
            }
            precondition(emptyFlat.isEmpty)
            var streamFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in
                SpeechNeverResults<SFCustomLanguageModelData.PhraseCount>()
            }) {
                streamFlat.append(item)
            }
            precondition(streamFlat.isEmpty)
            func throwingEmpty() throws -> SpeechEmptyResults<SFCustomLanguageModelData.PhraseCount> {
                SpeechEmptyResults()
            }
            var throwingFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in try throwingEmpty() }) {
                throwingFlat.append(item)
            }
            precondition(throwingFlat.isEmpty)
            let iterator = generator.makeAsyncIterator()
            _ = try await iterator.next()
            var isolatedIterator = generator.makeAsyncIterator()
            _ = try await isolatedIterator.next(isolation: nil)
        } catch {
            fatalError("phrase generator sequence failed: \(error)")
        }
    }
}

func testTemplatePhraseCountGenerator() {
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    precondition(generator != SFCustomLanguageModelData.TemplatePhraseCountGenerator())
    _ = speechHash(generator)
    let template = SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("x", count: 1)
    precondition(template.body == "x")
    precondition(template.count == 1)
    precondition(template != SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("y", count: 1))
    _ = speechHash(template)
    _ = template.hashValue
    template.insert(generator: generator)
    let encoded = try! JSONEncoder().encode(template)
    let decoded = try! JSONDecoder().decode(
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template.self,
        from: encoded
    )
    precondition(decoded.count == 1)
    let encodedGen = try! JSONEncoder().encode(generator)
    _ = try! JSONDecoder().decode(SFCustomLanguageModelData.TemplatePhraseCountGenerator.self, from: encodedGen)
    let iterator = SFCustomLanguageModelData.TemplatePhraseCountGenerator.Iterator(
        templates: [template],
        templateClasses: ["App": ["Mail"]]
    )
    _ = type(of: iterator)
    speechRunAsync {
        let next = try? await iterator.next()
        precondition(next?.phrase == "x")
        let asyncIterator = generator.makeAsyncIterator()
        _ = try? await asyncIterator.next()
    }
}

func testCustomLanguageModelExport() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    speechRunAsync {
        do {
            try await data.export(to: URL(fileURLWithPath: "/tmp/out.bin"))
            fatalError("export should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}

// MARK: - SpeechAttributesTests.swift
private struct SpeechAttributeBox: Encodable {
    let encodeValue: (any Encoder) throws -> Void
    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

func testSpeechAttributesScope() {
    let scope = AttributeScopes.SpeechAttributes()
    _ = scope.transcriptionConfidence
    _ = scope.audioTimeRange
}

func testSpeechConfidenceAttribute() {
    let key = AttributeScopes.SpeechAttributes.ConfidenceAttribute.self
    precondition(key.name.isEmpty == false)
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.9
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.9)
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.invalidationConditions
    _ = String(describing: AttributeScopes.SpeechAttributes.ConfidenceAttribute.self)
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.Value.self
    let encoded = try! JSONEncoder().encode(
        SpeechAttributeBox(encodeValue: { encoder in
            try AttributeScopes.SpeechAttributes.ConfidenceAttribute.encode(0.9, to: encoder)
        })
    )
    struct ConfidenceProbe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try AttributeScopes.SpeechAttributes.ConfidenceAttribute.decode(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(ConfidenceProbe.self, from: encoded)
}

func testSpeechTimeRangeAttribute() {
    var timed = AttributedString("hello")
    let range = SpeechHostTimeRange(start: 0, duration: 0.4)
    timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = range
    precondition(timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] == range)
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.name
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.invalidationConditions
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.Value.self
    let encoded = try! JSONEncoder().encode(range)
    let decoded = try! JSONDecoder().decode(SpeechHostTimeRange.self, from: encoded)
    precondition(decoded == range)
    let boxed = try! JSONEncoder().encode(
        SpeechAttributeBox(encodeValue: { encoder in
            try AttributeScopes.SpeechAttributes.TimeRangeAttribute.encode(range, to: encoder)
        })
    )
    struct TimeRangeProbe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try AttributeScopes.SpeechAttributes.TimeRangeAttribute.decode(from: decoder)
        }
    }
    let roundTrip = try? JSONDecoder().decode(TimeRangeProbe.self, from: boxed)
    _ = roundTrip
}

func testRangeOfAudioTimeRangeAttributes() {
    var timed = AttributedString("hello")
    let range = SpeechHostTimeRange(start: 0, duration: 0.4)
    timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = range
    let found = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 0.1, duration: 0.1))
    precondition(found != nil)
    let missed = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 9, duration: 1))
    precondition(missed == nil)
}

func testAttributeDynamicLookup() {
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.8
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.8)
    attributed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = SpeechHostTimeRange(
        start: 0,
        duration: 0.2
    )
    precondition(attributed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self]?.start == 0)
    let keyPath = \AttributeScopes.SpeechAttributes.transcriptionConfidence
    precondition(type(of: keyPath) == KeyPath<AttributeScopes.SpeechAttributes, AttributeScopes.SpeechAttributes.ConfidenceAttribute>.self)
}

func speechRuntimeMain() {
    testSFSpeechErrorCodes()
    testSpeechClassicEnums()
    testSpeechTranscriberEnums()
    testDictationTranscriberEnums()
    testSpeechDetectorSensitivityEnum()
    testSpeechAnalyzerModelRetentionEnum()
    testAssetInventoryStatusEnum()
    testSupportedLocales()
    testSpeechRecognizerInit()
    testSpeechRecognizerAuthorization()
    testSpeechRecognizerAvailability()
    testSpeechRecognitionRequestProperties()
    testSpeechURLRecognitionRequest()
    testSpeechAudioBufferRequest()
    testSpeechRecognitionTaskUnauthorized()
    testSpeechRecognitionTaskMissingAssets()
    testSpeechRecognitionTaskCancel()
    testSpeechRecognitionTaskScriptedDelegate()
    testSpeechRecognitionTaskHandler()
    testSpeechRecognitionTaskFinish()
    testSFAcousticFeature()
    testSFVoiceAnalytics()
    testSFTranscriptionSegment()
    testSFTranscription()
    testSFSpeechRecognitionMetadata()
    testSFSpeechRecognitionResult()
    testSFSpeechLanguageModelConfiguration()
    testPrepareCustomLanguageModel()
    testAnalysisContext()
    testSpeechAnalyzerLifecycle()
    testSpeechAnalyzerIsolation()
    testAssetInventory()
    testAssetInstallationRequest()
    testSpeechModels()
    testSpeechModuleProtocols()
    testSpeechTranscriberPresets()
    testSpeechTranscriberRuntime()
    testDictationTranscriberPresets()
    testDictationTranscriberRuntime()
    testSpeechDetectorRuntime()
    testSpeechDetectorOptionsHashable()
    testCustomLanguageModelData()
    testCustomLanguageModelInsert()
    testCustomLanguageModelBuilder()
    testPhraseCountGenerator()
    testPhraseCountGeneratorSequence()
    testTemplatePhraseCountGenerator()
    testCustomLanguageModelExport()
    testSpeechAttributesScope()
    testSpeechConfidenceAttribute()
    testSpeechTimeRangeAttribute()
    testRangeOfAudioTimeRangeAttributes()
    testAttributeDynamicLookup()
    print("SPEECH_AGENT_RUNTIME_OK")
}

speechRuntimeMain()

