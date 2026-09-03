@_spi(OpenUIKitHost) import Speech
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var status: SFSpeechRecognizerAuthorizationStatus?

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(_ status: SFSpeechRecognizerAuthorizationStatus) {
        lock.lock()
        sawReturned = returned
        count += 1
        self.status = status
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int, status: SFSpeechRecognizerAuthorizationStatus?) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, status)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class QueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        SpeechHostControl.enqueueAuthorizationProbe {
            self.occupied.signal()
            _ = self.hold.wait(timeout: .now() + eventTimeout)
        }
        waitEvent(occupied, "queue blocker did not occupy")
    }

    func release() {
        hold.signal()
    }
}

private final class TaskDelegate: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
    let finished = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var success: Bool?
    private var cancelled = false

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        lock.lock()
        success = successfully
        lock.unlock()
        finished.signal()
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func snapshot() -> (success: Bool?, cancelled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (success, cancelled)
    }
}

private func requireFailClosed(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed SFSpeechError")
    }
    let speechError = error as? SFSpeechError
    let nsError = error as NSError
    precondition(nsError.domain == SFSpeechErrorDomain)
    if let speechError {
        precondition(speechError.code == .internalServiceError || speechError.code == .noModel
            || speechError.code == .cannotAllocateUnsupportedLocale)
    }
}

func speechRuntimeMain() async {
    SpeechHostControl.resetAuthorizationStatusForTests()
    assertEnums()
    assertErrorSurface()
    await assertAuthorization()
    assertRecognizer()
    await assertRecognitionTask()
    await assertAnalyzerAndModules()
    assertCustomLanguageModel()
    assertAttributes()
    print("SPEECH_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await speechRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()

private func assertEnums() {
    precondition(SFSpeechRecognizerAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied.rawValue == 1)
    precondition(SFSpeechRecognizerAuthorizationStatus.restricted.rawValue == 2)
    precondition(SFSpeechRecognizerAuthorizationStatus.authorized.rawValue == 3)
    precondition(SFSpeechRecognizerAuthorizationStatus(rawValue: 1) == .denied)
    precondition(SFSpeechRecognitionTaskHint.unspecified.rawValue == 0)
    precondition(SFSpeechRecognitionTaskHint.dictation != .search)
    precondition(SFSpeechRecognitionTaskState.starting.rawValue == 0)
    precondition(SFSpeechRecognitionTaskState.completed.rawValue == 4)
    precondition(SFSpeechError.Code.audioReadFailed != .timeout)
    precondition(SFSpeechError.audioReadFailed == .audioReadFailed)
    precondition(AssetInventory.Status.unsupported < .installed)
    precondition(SpeechDetector.SensitivityLevel.low.rawValue == 0)
    precondition(SpeechDetector.SensitivityLevel.allCases.count == 3)
    precondition(SpeechTranscriber.ReportingOption.allCases.contains(.volatileResults))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.punctuation))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.whileInUse))
}

private func assertErrorSurface() {
    let error = SFSpeechError(.internalServiceError)
    precondition(error.errorCode == SFSpeechError.Code.internalServiceError.rawValue)
    precondition(SFSpeechError.errorDomain == SFSpeechErrorDomain)
    precondition(error == SFSpeechError(.internalServiceError, userInfo: ["x": 1]))
    precondition(error.localizedDescription.isEmpty == false)
    precondition((error as NSError).domain == SFSpeechErrorDomain)
}

private func assertAuthorization() async {
    SpeechHostControl.resetAuthorizationStatusForTests()
    precondition(SFSpeechRecognizer.authorizationStatus() == .notDetermined)

    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let blocker = QueueBlocker()
    blocker.occupy()
    SFSpeechRecognizer.requestAuthorization { status in
        state.noteCallback(status)
        finished.signal()
    }
    state.markReturned()
    let mid = state.snapshot()
    precondition(mid.count == 0, "authorization callback ran inline")
    blocker.release()
    waitEvent(finished, "authorization callback did not run")
    let end = state.snapshot()
    precondition(end.count == 1)
    precondition(end.sawReturned)
    precondition(end.status == .denied)
    precondition(SFSpeechRecognizer.authorizationStatus() == .denied)
    precondition(SFSpeechRecognizer.supportedLocales().isEmpty)
}

private func assertRecognizer() {
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    precondition(recognizer != nil)
    let unwrapped = recognizer!
    let asObject: NSObject = unwrapped
    precondition(asObject === unwrapped)
    precondition(unwrapped.locale.identifier == "en-US")
    precondition(unwrapped.isAvailable == false)
    precondition(unwrapped.supportsOnDeviceRecognition == false)
    unwrapped.defaultTaskHint = .dictation
    precondition(unwrapped.defaultTaskHint == .dictation)
    unwrapped.supportsOnDeviceRecognition = true
    precondition(unwrapped.supportsOnDeviceRecognition)
    let defaultRecognizer = SFSpeechRecognizer()
    precondition(defaultRecognizer.locale.identifier.isEmpty == false)

    let urlRequest = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    precondition(urlRequest.url.path == "/tmp/speech.wav")
    let urlRequest2 = SFSpeechURLRecognitionRequest(URL: URL(fileURLWithPath: "/tmp/b.wav"))
    precondition(urlRequest2.url.path == "/tmp/b.wav")
    urlRequest.addsPunctuation = true
    urlRequest.contextualStrings = ["OpenUIKit"]
    urlRequest.shouldReportPartialResults = false
    urlRequest.requiresOnDeviceRecognition = true
    urlRequest.taskHint = .search
    urlRequest.interactionIdentifier = "probe"
    let modelURL = URL(fileURLWithPath: "/tmp/model.bin")
    urlRequest.customizedLanguageModel = SFSpeechLanguageModel.Configuration(languageModel: modelURL)
    precondition(urlRequest.customizedLanguageModel?.languageModel == modelURL)
    precondition(urlRequest.addsPunctuation)
    precondition(urlRequest.contextualStrings == ["OpenUIKit"])

    let bufferRequest = SFSpeechAudioBufferRecognitionRequest()
    bufferRequest.endAudio()
    precondition(bufferRequest.didEndAudio)

    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    precondition(feature.frameDuration == 0.01)
    precondition(SFAcousticFeature(coder: NSCoder()) == nil)
    let transcription = SFTranscription(formattedString: "hello")
    precondition(transcription.formattedString == "hello")
    precondition(transcription.segments.isEmpty)
    let result = SFSpeechRecognitionResult(bestTranscription: transcription, isFinal: true)
    precondition(result.isFinal)
    precondition(result.bestTranscription.formattedString == "hello")
}

private func assertRecognitionTask() async {
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    let finished = DispatchSemaphore(value: 0)
    let state = LockedState()
    _ = recognizer.recognitionTask(with: request) { result, error in
        state.noteCallback(.denied)
        precondition(result == nil)
        requireFailClosed(error)
        finished.signal()
    }
    state.markReturned()
    precondition(state.snapshot().count == 0, "result handler ran inline")
    waitEvent(finished, "result handler did not run")
    precondition(state.snapshot().count == 1)
    precondition(state.snapshot().sawReturned)

    let delegate = TaskDelegate()
    let cancelRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))!
    let cancelBlocker = QueueBlocker()
    cancelBlocker.occupy()
    let task = cancelRecognizer.recognitionTask(with: request, delegate: delegate)
    task.cancel()
    precondition(task.isCancelled)
    cancelBlocker.release()
    waitEvent(delegate.finished, "delegate did not finish")
    precondition(task.isCancelled)
    precondition(task.state == .completed)
    let snap = delegate.snapshot()
    precondition(snap.success == false)
}

private func assertAnalyzerAndModules() async {
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
    precondition(SpeechTranscriber.isAvailable == false)
    precondition(transcriber.selectedLocales.count == 1)
    let supported = await SpeechTranscriber.supportedLocales
    precondition(supported.isEmpty)
    let equivalent = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US"))
    precondition(equivalent == nil)
    var transcriberIterator = transcriber.results.makeAsyncIterator()
    let first = try? await transcriberIterator.next()
    precondition(first == nil)

    let dictation = DictationTranscriber(locale: Locale(identifier: "en-US"), preset: .phrase)
    precondition(dictation.preset == .phrase)
    precondition(DictationTranscriber.ContentHint.farField != .shortForm)

    let detector = SpeechDetector()
    precondition(detector.detectionOptions.sensitivityLevel == .medium)
    let options = SpeechDetector.DetectionOptions(sensitivityLevel: .high)
    let detector2 = SpeechDetector(detectionOptions: options, reportResults: true)
    precondition(detector2.reportResults)
    precondition(detector2.detectionOptions == options)

    let context = AnalysisContext()
    context.contextualStrings[.general] = ["OpenUIKit"]
    context.userData[AnalysisContext.UserDataTag("topic")] = "speech"
    precondition(context.contextualStrings[.general] == ["OpenUIKit"])

    let analyzer = SpeechAnalyzer(modules: [transcriber], options: SpeechAnalyzer.Options(
        priority: .medium,
        modelRetention: .whileInUse
    ))
    try? await analyzer.setContext(context)
    let stored = await analyzer.context
    precondition(stored.contextualStrings[.general] == ["OpenUIKit"])
    do {
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        fatalError("analyzer should fail closed")
    } catch {
        requireFailClosed(error)
    }
    await analyzer.cancelAndFinishNow()

    let status = await AssetInventory.status(forModules: [transcriber])
    precondition(status == .unsupported)
    precondition(AssetInventory.maximumReservedLocales == 0)
    do {
        _ = try await AssetInventory.reserve(locale: Locale(identifier: "en-US"))
        fatalError("reserve should fail closed")
    } catch {
        requireFailClosed(error)
    }
    let released = await AssetInventory.release(reservedLocale: Locale(identifier: "en-US"))
    precondition(released == false)
    let request = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber])
    precondition(request == nil)
    await SpeechModels.endRetention()

    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.description == "x")
    precondition(hostResult.isFinal)
}

private func assertCustomLanguageModel() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1",
        builder: {
            SFCustomLanguageModelData.PhraseCount(phrase: "OpenUIKit", count: 3)
            SFCustomLanguageModelData.CustomPronunciation(grapheme: "ui", phonemes: ["y", "u"])
        }
    )
    precondition(data.identifier == "probe")
    precondition(data.version == "1")
    precondition(data.snapshotPhraseCounts().contains(where: { $0.phrase == "OpenUIKit" && $0.count == 3 }))
    precondition(data.snapshotPronunciations().contains(where: { $0.grapheme == "ui" }))
    precondition(SFCustomLanguageModelData.supportedPhonemes(locale: Locale(identifier: "en-US")).isEmpty)

    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    data.insert(phraseCountGenerator: generator)

    let config = SFSpeechLanguageModel.Configuration(
        languageModel: URL(fileURLWithPath: "/tmp/lm.bin"),
        vocabulary: URL(fileURLWithPath: "/tmp/vocab.txt"),
        weight: NSNumber(value: 1.5)
    )
    precondition(config.languageModel.path.hasSuffix("lm.bin"))
    precondition(config.vocabulary?.path.hasSuffix("vocab.txt") == true)
    precondition(config.weight?.doubleValue == 1.5)
}

private func assertAttributes() {
    let key = AttributeScopes.SpeechAttributes.ConfidenceAttribute.self
    precondition(key.name.isEmpty == false)
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.9
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.9)
}
