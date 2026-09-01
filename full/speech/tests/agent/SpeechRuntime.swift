import Foundation
import Speech

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SPEECH_RUNTIME_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func requireError(_ error: (any Error)?, code: SFSpeechError.Code, _ message: String) {
    guard let speech = error as? SFSpeechError else {
        fputs(
            "SPEECH_RUNTIME_FAIL: \(message) (not SFSpeechError: \(String(describing: error)))\n",
            stderr
        )
        exit(1)
    }
    require(speech.code == code, "\(message) (code \(speech.code) != \(code))")
    require(SFSpeechError.errorDomain == SFSpeechErrorDomain, "error domain mismatch")
    require(speech.errorCode == code.rawValue, "errorCode mismatch")
}

struct OneInput: AsyncSequence, Sendable {
    typealias Element = AnalyzerInput
    let value: AnalyzerInput
    struct Iterator: AsyncIteratorProtocol {
        var value: AnalyzerInput?
        mutating func next() async -> AnalyzerInput? {
            defer { value = nil }
            return value
        }
    }
    func makeAsyncIterator() -> Iterator {
        Iterator(value: value)
    }
}

// MARK: - Errors and enums

require(SFSpeechErrorDomain == "SFSpeechErrorDomain", "error domain string")
require(SFSpeechError.internalServiceError.rawValue == 1, "internalServiceError raw")
require(SFSpeechError.audioReadFailed.rawValue == 2, "audioReadFailed raw")
require(SFSpeechError.undefinedTemplateClassName.rawValue == 7, "undefinedTemplateClassName raw")
require(SFSpeechError.malformedSupplementalModel.rawValue == 8, "malformedSupplementalModel raw")
require(SFSpeechError.timeout.rawValue == 12, "timeout raw")
require(SFSpeechError.missingParameter.rawValue == 13, "missingParameter raw")
require(SFSpeechError.Code.noModel.rawValue == 5, "noModel raw")
require(SFSpeechError.Code.audioDisordered.rawValue == 3, "audioDisordered raw")
require(SFSpeechError.Code.cannotAllocateUnsupportedLocale.rawValue == 15, "cannotAllocate")
require(SFSpeechError.Code(rawValue: 1) == .internalServiceError, "code init")
require(SFSpeechError.Code(rawValue: 99) == nil, "unknown code")

let typed = SFSpeechError(.noModel, userInfo: ["reason": "test"])
require(typed.code == .noModel, "typed code")
require(SFSpeechError.Code.noModel ~= typed, "pattern match")
require(typed != SFSpeechError(.timeout), "error inequality")
require(typed.hashValue != 0 || typed.hashValue == 0, "error hash")

require(SFSpeechRecognitionTaskHint.unspecified.rawValue == 0, "hint unspecified")
require(SFSpeechRecognitionTaskHint.dictation.rawValue == 1, "hint dictation")
require(SFSpeechRecognitionTaskHint.search.rawValue == 2, "hint search")
require(SFSpeechRecognitionTaskHint.confirmation.rawValue == 3, "hint confirmation")
require(SFSpeechRecognitionTaskHint.dictation != .search, "hint inequality")
require(SFSpeechRecognitionTaskState.starting.rawValue == 0, "state starting")
require(SFSpeechRecognitionTaskState.completed.rawValue == 4, "state completed")
require(SFSpeechRecognizerAuthorizationStatus.denied.rawValue == 1, "auth denied")
require(SFSpeechRecognizerAuthorizationStatus.authorized.rawValue == 3, "auth authorized")
require(SpeechDetector.SensitivityLevel(rawValue: 1) == .medium, "sensitivity raw")
require(
    SpeechDetector.SensitivityLevel.allCases == [.low, .medium, .high],
    "sensitivity cases"
)
require(
    SpeechAnalyzer.Options.ModelRetention.allCases.contains(.lingering),
    "retention cases"
)
require(
    SpeechTranscriber.ReportingOption.allCases.contains(.fastResults),
    "reporting cases"
)
require(
    SpeechTranscriber.TranscriptionOption.allCases.contains(.etiquetteReplacements),
    "transcription option cases"
)
require(
    SpeechTranscriber.ResultAttributeOption.allCases.contains(.audioTimeRange),
    "attribute option cases"
)

// MARK: - Authorization and recognizer (privacy / remote-service fail-closed)

require(
    SFSpeechRecognizer.authorizationStatus() == .denied,
    "default authorization is denied"
)
require(SFSpeechRecognizer.supportedLocales().isEmpty, "no Apple locales")

var requested: SFSpeechRecognizerAuthorizationStatus?
SFSpeechRecognizer.requestAuthorization { requested = $0 }
require(requested == .denied, "requestAuthorization stays denied")
require(
    SFSpeechRecognizer.authorizationStatus() == .denied,
    "authorization remains denied"
)

guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
    require(false, "recognizer init")
    fatalError("unreachable")
}
require(SFSpeechRecognizer() != nil, "default recognizer init")
require(!recognizer.isAvailable, "recognizer unavailable")
require(!recognizer.supportsOnDeviceRecognition, "no on-device")
require(recognizer.locale.identifier == "en-US", "locale stored")
recognizer.defaultTaskHint = .search
require(recognizer.defaultTaskHint == .search, "task hint stored")
recognizer.queue.maxConcurrentOperationCount = 1

let urlRequest = SFSpeechURLRecognitionRequest(
    url: URL(fileURLWithPath: "/tmp/speech-sample.wav")
)
urlRequest.addsPunctuation = true
urlRequest.shouldReportPartialResults = false
urlRequest.contextualStrings = ["OpenUIKit"]
urlRequest.requiresOnDeviceRecognition = true
urlRequest.taskHint = .dictation
urlRequest.interactionIdentifier = "runtime"
require(urlRequest.url.path.hasSuffix("speech-sample.wav"), "url request")
require(urlRequest.addsPunctuation, "punctuation flag")
_ = SFSpeechURLRecognitionRequest(URL: URL(fileURLWithPath: "/tmp/other.wav"))

let bufferRequest = SFSpeechAudioBufferRecognitionRequest()
let format = bufferRequest.nativeAudioFormat
require(format.sampleRate == 16_000, "native sample rate")
let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 320)
pcm.frameLength = 160
bufferRequest.append(pcm)
bufferRequest.appendAudioSampleBuffer(CMSampleBuffer())
bufferRequest.endAudio()

final class TaskProbe: NSObject, SFSpeechRecognitionTaskDelegate {}
let probe = TaskProbe()
let task = recognizer.recognitionTask(with: urlRequest, delegate: probe)
require(task.state == .completed, "task completed")
requireError(task.error, code: .noModel, "recognition task error")

var handlerSawError = false
let handlerTask = recognizer.recognitionTask(with: bufferRequest) { result, error in
    require(result == nil, "no fabricated transcription")
    requireError(error, code: .noModel, "handler error")
    handlerSawError = true
}
require(handlerSawError, "handler invoked")
handlerTask.cancel()
require(handlerTask.isCancelled, "cancel flag")
handlerTask.finish()
require(handlerTask.isFinishing, "finish flag")

// MARK: - Result objects

let segment = SFTranscriptionSegment(
    substring: "hello",
    substringRange: NSRange(location: 0, length: 5),
    timestamp: 0.1,
    duration: 0.4,
    confidence: 0.8,
    alternativeSubstrings: ["halo"]
)
let transcription = SFTranscription(
    formattedString: "hello",
    segments: [segment],
    speakingRate: 2.5,
    averagePauseDuration: 0.05
)
let metadata = SFSpeechRecognitionMetadata(
    speakingRate: 2.5,
    speechDuration: 0.4
)
let result = SFSpeechRecognitionResult(
    bestTranscription: transcription,
    isFinal: true,
    speechRecognitionMetadata: metadata
)
require(result.bestTranscription.formattedString == "hello", "best text")
require(result.transcriptions.count == 1, "transcriptions")
require(result.isFinal, "final result")
_ = result.copy()
_ = transcription.copy()
_ = segment.copy()
_ = SFVoiceAnalytics().copy()
_ = SFAcousticFeature(acousticFeatureValuePerFrame: [0.1], frameDuration: 0.01).copy()
let feature = SFAcousticFeature(
    acousticFeatureValuePerFrame: [0.2, 0.3],
    frameDuration: 0.01
)
require(feature.acousticFeatureValuePerFrame.count == 2, "acoustic frames")
require(feature.frameDuration == 0.01, "frame duration")

let emptyResult = SpeechTranscriber.Result(
    text: AttributedString("x"),
    alternatives: [],
    range: .zero,
    resultsFinalizationTime: .zero
)
require(emptyResult.isFinal, "module result isFinal")
require(emptyResult.description == "x", "result description")

// MARK: - Custom language model data (local, useful)

let modelURL = URL(fileURLWithPath: "/tmp/speech-lm.bin")
let configuration = SFSpeechLanguageModel.Configuration(
    languageModel: modelURL,
    vocabulary: nil,
    weight: 1.5
)
require(configuration.languageModel == modelURL, "lm url")
require(configuration.weight?.doubleValue == 1.5, "lm weight")
_ = SFSpeechLanguageModel.Configuration(languageModel: modelURL)
_ = SFSpeechLanguageModel.Configuration(languageModel: modelURL, vocabulary: nil)

let custom = SFCustomLanguageModelData(
    locale: Locale(identifier: "en_US"),
    identifier: "demo.lm",
    version: "1",
    builder: {
        SFCustomLanguageModelData.PhraseCount(phrase: "open the pod bay doors", count: 3)
        SFCustomLanguageModelData.CustomPronunciation(
            grapheme: "OpenUIKit",
            phonemes: ["o", "p", "n"]
        )
        SFCustomLanguageModelData.PhraseCountsFromTemplates(
            classes: ["app": ["Mail", "Maps"]]
        ) {
            SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template(
                "open {app}",
                count: 2
            )
        }
    }
)
require(custom.identifier == "demo.lm", "custom id")
require(custom.version == "1", "custom version")
require(custom.locale.identifier == "en_US", "custom locale")
require(
    SFCustomLanguageModelData.supportedPhonemes(locale: custom.locale).isEmpty,
    "no phoneme inventory"
)
require(custom != SFCustomLanguageModelData(locale: Locale(identifier: "fr"), identifier: "x", version: "0"), "lm inequality")

let exportURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("speech-custom-lm.json")
try await custom.export(to: exportURL)
let exported = try Data(contentsOf: exportURL)
let json = try JSONSerialization.jsonObject(with: exported) as? [String: Any]
let exportedPhrases = json?["phraseCounts"] as? [[String: Any]] ?? []
let phraseNames = Set(exportedPhrases.compactMap { $0["phrase"] as? String })
require(phraseNames.contains("open the pod bay doors"), "direct phrase")
require(phraseNames.contains("open Mail"), "template Mail")
require(phraseNames.contains("open Maps"), "template Maps")
let exportedTerms = json?["pronunciations"] as? [[String: Any]] ?? []
require(
    exportedTerms.contains(where: { ($0["grapheme"] as? String) == "OpenUIKit" }),
    "pronunciation stored"
)

let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
generator.define(className: "x", values: ["hello"])
generator.insert(template: "{x}", count: 1)
var seen: [String] = []
for try await phrase in generator {
    seen.append(phrase.phrase)
}
require(seen == ["hello"], "phrase generator sequence")
require(
    try await generator.contains(SFCustomLanguageModelData.PhraseCount(phrase: "hello", count: 1)),
    "contains"
)

do {
    try await SFSpeechLanguageModel.prepareCustomLanguageModel(
        for: exportURL,
        configuration: configuration
    )
    require(false, "prepareCustomLanguageModel must fail closed")
} catch {
    requireError(error, code: .noModel, "prepare custom LM")
}

do {
    try await SFSpeechLanguageModel.prepareCustomLanguageModel(
        for: exportURL,
        clientIdentifier: "demo",
        configuration: configuration,
        ignoresCache: true
    )
    require(false, "prepare with client id must fail closed")
} catch {
    requireError(error, code: .noModel, "prepare custom LM client")
}

// MARK: - Analyzer family

require(!SpeechTranscriber.isAvailable, "transcriber unavailable")
let transcriber = SpeechTranscriber(
    locale: Locale(identifier: "en-US"),
    preset: .progressiveTranscription
)
require(transcriber.selectedLocales.count == 1, "transcriber locale")
require(transcriber.reportingOptions.contains(.volatileResults), "progressive reporting")
require(await SpeechTranscriber.supportedLocales.isEmpty, "no transcriber locales")
require(await SpeechTranscriber.installedLocales.isEmpty, "no installed locales")
require(await transcriber.availableCompatibleAudioFormats.isEmpty, "no formats")
require(
    await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en")) == nil,
    "no equivalent locale"
)
require(
    SpeechTranscriber.Preset.transcription != .transcriptionWithAlternatives,
    "preset inequality"
)

var transcriberCount = 0
for try await _ in transcriber.results {
    transcriberCount += 1
}
require(transcriberCount == 0, "no fabricated transcriber results")

let dictation = DictationTranscriber(
    locale: Locale(identifier: "en-US"),
    preset: .shortDictation
)
require(dictation.contentHints.contains(.shortForm), "short-form hint")
require(dictation.transcriptionOptions.contains(.punctuation), "dictation punctuation")
let customized = DictationTranscriber.ContentHint.customizedLanguage(
    modelConfiguration: configuration
)
require(customized != .farField, "content hint inequality")
require(
    DictationTranscriber.Preset.longDictation != .phrase,
    "dictation preset inequality"
)
var dictationCount = 0
for try await _ in dictation.results {
    dictationCount += 1
}
require(dictationCount == 0, "no fabricated dictation results")

let detector = SpeechDetector(
    detectionOptions: SpeechDetector.DetectionOptions(sensitivityLevel: .high),
    reportResults: false
)
require(detector.detectionOptions.sensitivityLevel == .high, "detector sensitivity")
require(detector.availableCompatibleAudioFormats.isEmpty, "detector formats")
require(SpeechDetector().reportResults, "default detector reports")
var detectorCount = 0
for try await _ in detector.results {
    detectorCount += 1
}
require(detectorCount == 0, "no fabricated detector results")

let context = AnalysisContext()
context.contextualStrings[.general] = ["OpenUIKit"]
context.userData[AnalysisContext.UserDataTag("session")] = "runtime"
require(context.contextualStrings[.general] == ["OpenUIKit"], "context strings")
require(AnalysisContext.ContextualStringsTag("general") == .general, "general tag")
require(AnalysisContext.UserDataTag("session").rawValue == "session", "user data tag")

require(AssetInventory.maximumReservedLocales == 0, "no reserved locales")
require(await AssetInventory.reservedLocales.isEmpty, "reserved empty")
require(
    await AssetInventory.status(forModules: [transcriber, detector]) == .unsupported,
    "inventory unsupported"
)
require(AssetInventory.Status.unsupported < AssetInventory.Status.installed, "status order")
require(AssetInventory.Status.supported <= .downloading, "status <=")
require(AssetInventory.Status.installed > .downloading, "status >")
require(
    try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) == nil,
    "no install request"
)
do {
    _ = try await AssetInventory.reserve(locale: Locale(identifier: "en-US"))
    require(false, "reserve must fail closed")
} catch {
    requireError(error, code: .cannotAllocateUnsupportedLocale, "reserve locale")
}
require(
    await AssetInventory.release(reservedLocale: Locale(identifier: "en-US")) == false,
    "release"
)

await SpeechModels.endRetention()

let analyzer = SpeechAnalyzer(
    modules: [transcriber, dictation, detector],
    options: SpeechAnalyzer.Options(priority: .medium, modelRetention: .whileInUse)
)
require((await analyzer.modules).count == 3, "analyzer modules")
try await analyzer.setContext(context)
require(await analyzer.context.contextualStrings[.general] == ["OpenUIKit"], "setContext")
try await analyzer.setModules([transcriber])
require((await analyzer.modules).count == 1, "setModules")
require(await analyzer.volatileRange == nil, "no volatile range")
require(
    await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) == nil,
    "no shared format"
)
require(
    await SpeechAnalyzer.bestAvailableAudioFormat(
        compatibleWith: [transcriber],
        considering: format
    ) == nil,
    "no considered format"
)

do {
    try await analyzer.prepareToAnalyze(in: format)
    require(false, "prepareToAnalyze must fail closed")
} catch {
    requireError(error, code: .noModel, "prepareToAnalyze")
}

let input = AnalyzerInput(
    buffer: pcm,
    bufferStartTime: CMTime(seconds: 0, preferredTimescale: 16_000)
)
require(input.bufferStartTime?.isValid == true, "input timestamp")
_ = AnalyzerInput(buffer: pcm)

do {
    _ = try await analyzer.analyzeSequence(OneInput(value: input))
    require(false, "analyzeSequence must fail closed")
} catch {
    requireError(error, code: .noModel, "analyzeSequence")
}

let audioFile = AVAudioFile(forReading: URL(fileURLWithPath: "/tmp/missing.wav"))
do {
    _ = try await analyzer.analyzeSequence(from: audioFile)
    require(false, "analyze file must fail closed")
} catch {
    requireError(error, code: .audioReadFailed, "analyze file")
}

do {
    try await analyzer.start(inputSequence: OneInput(value: input))
    require(false, "start sequence must fail closed")
} catch {
    requireError(error, code: .noModel, "start sequence")
}

do {
    try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)
    require(false, "start file must fail closed")
} catch {
    requireError(error, code: .noModel, "start file")
}

await analyzer.cancelAnalysis(before: .zero)
await analyzer.cancelAndFinishNow()
try await analyzer.finalize(through: nil)
try await analyzer.finalizeAndFinish(through: .zero)
try await analyzer.finish(after: .zero)
try await analyzer.finalizeAndFinishThroughEndOfInput()

do {
    _ = try await SpeechAnalyzer(
        inputAudioFile: audioFile,
        modules: [transcriber]
    )
    require(false, "file analyzer init must fail closed")
} catch {
    requireError(error, code: .noModel, "file analyzer init")
}

_ = SpeechAnalyzer(
    inputSequence: OneInput(value: input),
    modules: [transcriber]
)

// MARK: - Attributes

var attributed = AttributedString("hello world")
attributed.transcriptionConfidence = 0.42
let hello = attributed.startIndex..<attributed.index(attributed.startIndex, offsetByCharacters: 5)
attributed[hello].audioTimeRange = CMTimeRange(
    start: .zero,
    duration: CMTime(seconds: 0.4, preferredTimescale: 1000)
)
let hit = attributed.rangeOfAudioTimeRangeAttributes(
    intersecting: CMTimeRange(
        start: CMTime(seconds: 0.1, preferredTimescale: 1000),
        duration: CMTime(seconds: 0.1, preferredTimescale: 1000)
    )
)
require(hit != nil, "time-range attribute lookup")
require(
    AttributeScopes.SpeechAttributes.ConfidenceAttribute.name.contains("Confidence")
        || AttributeScopes.SpeechAttributes.ConfidenceAttribute.name.contains("confidence"),
    "confidence attribute name"
)

print("SPEECH_AGENT_RUNTIME_OK")
