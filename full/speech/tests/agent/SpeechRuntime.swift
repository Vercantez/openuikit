@_spi(OpenUIKitHost) import Speech
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var status: SFSpeechRecognizerAuthorizationStatus?
    private var onMain = false

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(_ status: SFSpeechRecognizerAuthorizationStatus, onMain: Bool) {
        lock.lock()
        sawReturned = returned
        count += 1
        self.status = status
        self.onMain = onMain
        lock.unlock()
    }

    func snapshot() -> (
        sawReturned: Bool,
        count: Int,
        status: SFSpeechRecognizerAuthorizationStatus?,
        onMain: Bool
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, status, onMain)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class RecordingDelegate: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
    let finished = DispatchSemaphore(value: 0)
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
        finished.signal()
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

private final class AvailabilityDelegate: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    let changed = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var available: Bool?

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        lock.lock()
        self.available = available
        lock.unlock()
        changed.signal()
    }

    func snapshot() -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        return available
    }
}

private func requireAssistantUnauthorized(_ error: (any Error)?) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kAFAssistantErrorDomain)
    precondition(nsError?.code == SpeechHostControl.assistantRequestNotAuthorized)
}

private func requireLSR(_ error: (any Error)?, code: Int) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kLSRErrorDomain)
    precondition(nsError?.code == code)
}

func speechRuntimeMain() async {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.resetScriptedRecognizers()
    assertEnums()
    assertErrorSurface()
    await assertAuthorization()
    assertRecognizer()
    await assertFailClosedTask()
    await assertScriptedRecognition()
    await assertBufferTask()
    await assertAnalyzerAndModules()
    await assertCustomLanguageModel()
    assertAttributes()
    await assertSynthesizedSurface()
    print("SPEECH_AGENT_RUNTIME_OK")
}

Task {
    await speechRuntimeMain()
    exit(0)
}
RunLoop.main.run()

private func assertEnums() {
    precondition(SFSpeechRecognizerAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(SFSpeechRecognizerAuthorizationStatus.denied.rawValue == 1)
    precondition(SFSpeechRecognizerAuthorizationStatus.restricted.rawValue == 2)
    precondition(SFSpeechRecognizerAuthorizationStatus.authorized.rawValue == 3)
    precondition(SFSpeechRecognizerAuthorizationStatus(rawValue: 1) == .denied)
    precondition(SFSpeechRecognitionTaskHint.unspecified.rawValue == 0)
    precondition(SFSpeechRecognitionTaskHint.dictation != .search)
    precondition(SFSpeechRecognitionTaskHint.confirmation.rawValue == 3)
    precondition(SFSpeechRecognitionTaskState.starting.rawValue == 0)
    precondition(SFSpeechRecognitionTaskState.running.rawValue == 1)
    precondition(SFSpeechRecognitionTaskState.finishing.rawValue == 2)
    precondition(SFSpeechRecognitionTaskState.canceling.rawValue == 3)
    precondition(SFSpeechRecognitionTaskState.completed.rawValue == 4)
    precondition(SFSpeechError.Code.internalServiceError.rawValue == 1)
    precondition(SFSpeechError.Code.audioReadFailed.rawValue == 2)
    precondition(SFSpeechError.Code.undefinedTemplateClassName.rawValue == 7)
    precondition(SFSpeechError.Code.malformedSupplementalModel.rawValue == 8)
    precondition(SFSpeechError.Code.timeout.rawValue == 12)
    precondition(SFSpeechError.Code.missingParameter.rawValue == 13)
    precondition(SFSpeechError.audioReadFailed == .audioReadFailed)
    precondition(SFSpeechError.Code.audioReadFailed != .timeout)
    precondition(AssetInventory.Status.unsupported < .installed)
    precondition(SpeechDetector.SensitivityLevel.low.rawValue == 0)
    precondition(SpeechDetector.SensitivityLevel.allCases.count == 3)
    precondition(SpeechTranscriber.ReportingOption.allCases.contains(.volatileResults))
    precondition(DictationTranscriber.TranscriptionOption.allCases.contains(.punctuation))
    precondition(SpeechAnalyzer.Options.ModelRetention.allCases.contains(.whileInUse))
    _ = SFSpeechError.Code.malformedSupplementalModel.hashValue
    _ = SFSpeechRecognitionTaskHint.dictation.hashValue
    _ = SFSpeechRecognitionTaskState.running.hashValue
    _ = SFSpeechRecognizerAuthorizationStatus.authorized.hashValue
    _ = SpeechDetector.SensitivityLevel.high.hashValue
    var hasher = Hasher()
    SFSpeechError.Code.missingParameter.hash(into: &hasher)
    SFSpeechRecognitionTaskHint.search.hash(into: &hasher)
    SFSpeechRecognitionTaskState.finishing.hash(into: &hasher)
    SFSpeechRecognizerAuthorizationStatus.restricted.hash(into: &hasher)
    SpeechDetector.SensitivityLevel.medium.hash(into: &hasher)
    AnalysisContext.UserDataTag("topic").hash(into: &hasher)
    AnalysisContext.ContextualStringsTag.general.hash(into: &hasher)
    precondition(AnalysisContext.UserDataTag("topic") != AnalysisContext.UserDataTag("other"))
    precondition(AnalysisContext.ContextualStringsTag.general != AnalysisContext.ContextualStringsTag("other"))
}

private func assertErrorSurface() {
    let error = SFSpeechError(.internalServiceError)
    precondition(error.errorCode == SFSpeechError.Code.internalServiceError.rawValue)
    precondition(SFSpeechError.errorDomain == SFSpeechErrorDomain)
    precondition(error == SFSpeechError(.internalServiceError, userInfo: ["x": 1]))
    precondition(error.localizedDescription.isEmpty == false)
    precondition((error as NSError).domain == SFSpeechErrorDomain)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String != nil)
    let code: SFSpeechError.Code = .timeout
    switch code {
    case .timeout:
        break
    default:
        fatalError("timeout mismatch")
    }
    precondition(SFSpeechError.Code.undefinedTemplateClassName != .missingParameter)
}

private func assertAuthorization() async {
    SpeechHostControl.resetAuthorizationStatusForTests()
    precondition(SFSpeechRecognizer.authorizationStatus() == .notDetermined)

    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        state.noteCallback(status, onMain: Thread.isMainThread)
        finished.signal()
    }
    state.markReturned()
    let mid = state.snapshot()
    precondition(mid.count == 0, "authorization callback ran inline")
    waitEvent(finished, "authorization callback did not run")
    let end = state.snapshot()
    precondition(end.count == 1)
    precondition(end.sawReturned)
    precondition(end.status == .denied)
    precondition(end.onMain)
    precondition(SFSpeechRecognizer.authorizationStatus() == .denied)

    let second = DispatchSemaphore(value: 0)
    var secondStatus: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        secondStatus = status
        second.signal()
    }
    waitEvent(second, "second authorization did not run")
    precondition(secondStatus == .denied)

    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    let granted = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        precondition(status == .authorized)
        granted.signal()
    }
    waitEvent(granted, "authorized decision did not run")
    precondition(SFSpeechRecognizer.authorizationStatus() == .authorized)

    let locales = SFSpeechRecognizer.supportedLocales()
    precondition(locales.isEmpty == false)
    precondition(locales.contains(Locale(identifier: "en-US")))
    precondition(locales.contains(Locale(identifier: "ja-JP")))
    precondition(locales.contains(Locale(identifier: "zh-CN")))
}

private func assertRecognizer() {
    SpeechHostControl.resetScriptedRecognizers()
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
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "zz-ZZ")) == nil)
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "fr_FR")) != nil)

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
    precondition(urlRequest.shouldReportPartialResults == false)
    precondition(urlRequest.requiresOnDeviceRecognition)
    precondition(urlRequest.taskHint == .search)

    let bufferRequest = SFSpeechAudioBufferRecognitionRequest()
    precondition(bufferRequest.nativeAudioFormat.sampleRate == 16_000)
    precondition(bufferRequest.nativeAudioFormat.channelCount == 1)
    bufferRequest.append(SpeechHostPCMBuffer(frameLength: 1600))
    bufferRequest.appendAudioSampleBuffer(SpeechHostSampleBuffer(data: Data([0, 1])))
    precondition(bufferRequest.appendedBufferCount == 2)
    bufferRequest.endAudio()
    precondition(bufferRequest.didEndAudio)

    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5, 0.25])
    precondition(feature.frameDuration == 0.01)
    precondition(feature.acousticFeatureValuePerFrame == [0.5, 0.25])
    let copiedFeature = feature.copy() as! SFAcousticFeature
    precondition(copiedFeature.isEqual(feature))
    precondition(copiedFeature !== feature)
    precondition(SFAcousticFeature(coder: NSCoder()) == nil)

    let analytics = SFVoiceAnalytics(
        jitter: feature,
        pitch: feature,
        shimmer: feature,
        voicing: feature
    )
    precondition(analytics.jitter.isEqual(feature))
    precondition(analytics.pitch.isEqual(feature))
    precondition(analytics.shimmer.isEqual(feature))
    precondition(analytics.voicing.isEqual(feature))
    precondition((analytics.copy() as! SFVoiceAnalytics).isEqual(analytics))
    precondition(SFVoiceAnalytics(coder: NSCoder()) == nil)

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
    precondition(SFSpeechLanguageModel.Configuration(coder: NSCoder()) == nil)
}

private func assertFailClosedTask() async {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    let finished = DispatchSemaphore(value: 0)
    let state = LockedState()
    _ = recognizer.recognitionTask(with: request) { result, error in
        state.noteCallback(.denied, onMain: Thread.isMainThread)
        precondition(result == nil)
        requireAssistantUnauthorized(error)
        finished.signal()
    }
    state.markReturned()
    precondition(state.snapshot().count == 0, "result handler ran inline")
    waitEvent(finished, "unauthorized handler did not run")
    precondition(state.snapshot().count == 1)
    precondition(state.snapshot().sawReturned)

    SpeechHostControl.installAuthorizationDecision(.authorized)
    let authDone = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { _ in authDone.signal() }
    waitEvent(authDone, "auth for fail-closed assets")

    let assets = DispatchSemaphore(value: 0)
    let assetTask = recognizer.recognitionTask(with: request) { result, error in
        precondition(result == nil)
        requireLSR(error, code: SpeechHostControl.lsrAssetsNotInstalled)
        assets.signal()
    }
    waitEvent(assets, "assets-missing handler did not run")
    precondition(assetTask.state == .completed)

    let delegate = RecordingDelegate()
    recognizer.queue.isSuspended = true
    let cancelTask = recognizer.recognitionTask(with: request, delegate: delegate)
    cancelTask.cancel()
    precondition(cancelTask.isCancelled)
    precondition(cancelTask.state == .completed || cancelTask.state == .canceling)
    recognizer.queue.isSuspended = false
    waitEvent(delegate.finished, "delegate did not finish")
    precondition(cancelTask.isCancelled)
    precondition(cancelTask.state == .completed)
    let snap = delegate.snapshot()
    precondition(snap.success == false)
    precondition(snap.cancelled)
    requireLSR(cancelTask.error, code: SpeechHostControl.lsrRequestCanceled)
}

private func assertScriptedRecognition() async {
    SpeechHostControl.resetScriptedRecognizers()
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    let auth = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        precondition(status == .authorized)
        auth.signal()
    }
    waitEvent(auth, "scripted auth")

    let partial = SpeechScriptedResult(
        formattedString: "hel",
        segments: [
            SpeechScriptedSegment(
                substring: "hel",
                timestamp: 0,
                duration: 0.2,
                confidence: 0.4
            )
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
    SpeechHostControl.registerScriptedRecognizer(
        locale: Locale(identifier: "en-US"),
        results: [partial, final],
        supportsOnDeviceRecognition: true
    )

    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    precondition(recognizer.isAvailable)
    precondition(recognizer.supportsOnDeviceRecognition)

    let availability = AvailabilityDelegate()
    let notify = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))!
    notify.delegate = availability
    SpeechHostControl.registerScriptedRecognizer(
        locale: Locale(identifier: "fr-FR"),
        results: [SpeechScriptedResult(formattedString: "bonjour", isFinal: true)],
        supportsOnDeviceRecognition: false
    )
    waitEvent(availability.changed, "availability did not change")
    precondition(availability.snapshot() == true)
    precondition(notify.isAvailable)

    let delegate = RecordingDelegate()
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    request.shouldReportPartialResults = true
    request.addsPunctuation = true
    request.contextualStrings = ["OpenUIKit"]
    request.taskHint = .dictation
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    waitEvent(delegate.finished, "scripted delegate did not finish")
    precondition(task.state == .completed)
    precondition(task.isCancelled == false)
    let snap = delegate.snapshot()
    precondition(snap.success == true)
    precondition(snap.detected)
    precondition(snap.hypothesized >= 1)
    precondition(snap.finishedAudio)
    precondition(snap.result?.isFinal == true)
    precondition(snap.result?.bestTranscription.formattedString == "hello world")
    precondition(snap.result?.bestTranscription.segments.count == 2)
    precondition(snap.result?.bestTranscription.segments[0].substring == "hello")
    precondition(snap.result?.bestTranscription.segments[0].confidence == 0.95)
    precondition(snap.result?.bestTranscription.segments[0].alternativeSubstrings == ["halo"])
    precondition(snap.result?.transcriptions.count == 2)
    precondition(snap.result?.speechRecognitionMetadata?.speechDuration == 0.7)
    precondition(snap.result?.speechRecognitionMetadata?.speakingRate == 110)

    let handlerDone = DispatchSemaphore(value: 0)
    var finals = 0
    _ = recognizer.recognitionTask(with: request) { result, error in
        precondition(error == nil)
        if result?.isFinal == true {
            finals += 1
            handlerDone.signal()
        }
    }
    waitEvent(handlerDone, "scripted handler did not finish")
    precondition(finals == 1)
}

private func assertBufferTask() async {
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    SpeechHostControl.registerScriptedRecognizer(
        locale: Locale(identifier: "en-US"),
        results: [SpeechScriptedResult(formattedString: "buffer", isFinal: true, speechDuration: 0.3)]
    )
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = false
    let delegate = RecordingDelegate()
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    precondition(task.state == .starting || task.state == .running)
    request.append(SpeechHostPCMBuffer(frameLength: 320))
    request.endAudio()
    waitEvent(delegate.finished, "buffer task did not finish")
    precondition(task.isFinishing)
    precondition(task.state == .completed)
    precondition(delegate.snapshot().result?.bestTranscription.formattedString == "buffer")
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
    _ = DictationTranscriber.ContentHint.customizedLanguage(
        modelConfiguration: SFSpeechLanguageModel.Configuration(
            languageModel: URL(fileURLWithPath: "/tmp/lm.bin")
        )
    )
    _ = SpeechTranscriber.Preset.progressiveTranscription
    _ = SpeechTranscriber.Preset.transcriptionWithAlternatives
    _ = SpeechTranscriber.Preset.timeIndexedProgressiveTranscription
    _ = SpeechTranscriber.Preset.timeIndexedTranscriptionWithAlternatives
    _ = DictationTranscriber.Preset.shortDictation
    _ = DictationTranscriber.Preset.longDictation
    _ = DictationTranscriber.Preset.progressiveShortDictation
    _ = DictationTranscriber.Preset.progressiveLongDictation
    _ = DictationTranscriber.Preset.timeIndexedLongDictation

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
    try? await analyzer.setModules([dictation])
    do {
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        fatalError("analyzer should fail closed")
    } catch {
        let speechError = error as? SFSpeechError
        precondition(speechError?.code == .noModel)
    }
    await analyzer.cancelAndFinishNow()
    await analyzer.hostCheckIsolation()
    let moduleCount = await analyzer.modules.count
    precondition(moduleCount == 1)

    let status = await AssetInventory.status(forModules: [transcriber])
    precondition(status == .unsupported)
    precondition(AssetInventory.maximumReservedLocales == 0)
    let reserved = await AssetInventory.reservedLocales
    precondition(reserved.isEmpty)
    do {
        _ = try await AssetInventory.reserve(locale: Locale(identifier: "en-US"))
        fatalError("reserve should fail closed")
    } catch {
        let speechError = error as? SFSpeechError
        precondition(speechError?.code == .cannotAllocateUnsupportedLocale)
    }
    let released = await AssetInventory.release(reservedLocale: Locale(identifier: "en-US"))
    precondition(released == false)
    let request = try? await AssetInventory.assetInstallationRequest(supporting: [transcriber])
    precondition(request == nil)
    let install = AssetInstallationRequest()
    precondition(install.progress.totalUnitCount == 1)
    do {
        try await install.downloadAndInstall()
        fatalError("download should fail closed")
    } catch {
        let speechError = error as? SFSpeechError
        precondition(speechError?.code == .internalServiceError)
    }
    await SpeechModels.endRetention()

    let hostResult = SpeechTranscriber.Result(text: AttributedString("x"), isFinal: true)
    precondition(hostResult.description == "x")
    precondition(hostResult.isFinal)
    let detected = SpeechDetector.Result(speechDetected: false)
    precondition(detected.description == "silence")
}

private func assertCustomLanguageModel() async {
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
    precondition(data.snapshotPronunciations()[0].description.contains("ui"))
    precondition(data.snapshotPhraseCounts()[0].description.contains("OpenUIKit"))

    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    data.insert(phraseCountGenerator: generator)
    do {
        let contains = try await generator.contains { $0.phrase == "open {App}" }
        precondition(contains)
        let first = try await generator.first { $0.count == 2 }
        precondition(first?.count == 2)
        let all = try await generator.allSatisfy { $0.count > 0 }
        precondition(all)
        let reduced = try await generator.reduce(0) { $0 + $1.count }
        precondition(reduced == 2)
        var mapped: [String] = []
        for try await phrase in generator.map({ $0.phrase }) {
            mapped.append(phrase)
        }
        precondition(mapped == ["open {App}"])
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
        let compact = generator.compactMap { $0.count > 0 ? $0.phrase : nil }
        var compactValues: [String] = []
        for try await item in compact {
            compactValues.append(item)
        }
        precondition(compactValues == ["open {App}"])
        _ = try generator.prefix(while: { $0.count > 0 })
        _ = generator.drop(while: { $0.count == 0 })
        _ = try await generator.min(by: { $0.count < $1.count })
        _ = try await generator.max(by: { $0.count < $1.count })
        _ = generator.flatMap { _ in
            SpeechEmptyResults<SFCustomLanguageModelData.PhraseCount>()
        }
        var generatorIterator = generator.makeAsyncIterator()
        _ = try await generatorIterator.next(isolation: nil)
    } catch {
        fatalError("phrase generator sequence failed: \(error)")
    }
    precondition(generator != SFCustomLanguageModelData.TemplatePhraseCountGenerator())
    let template = SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("x", count: 1)
    precondition(template != SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("y", count: 1))
    let pronunciation = SFCustomLanguageModelData.CustomPronunciation(grapheme: "a", phonemes: ["ah"])
    precondition(pronunciation != SFCustomLanguageModelData.CustomPronunciation(grapheme: "b", phonemes: ["b"]))

    let config = SFSpeechLanguageModel.Configuration(
        languageModel: URL(fileURLWithPath: "/tmp/lm.bin"),
        vocabulary: URL(fileURLWithPath: "/tmp/vocab.txt"),
        weight: NSNumber(value: 1.5)
    )
    precondition(config.languageModel.path.hasSuffix("lm.bin"))
    precondition(config.vocabulary?.path.hasSuffix("vocab.txt") == true)
    precondition(config.weight?.doubleValue == 1.5)

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
    do {
        try await data.export(to: URL(fileURLWithPath: "/tmp/out.bin"))
        fatalError("export should fail closed")
    } catch {
        precondition((error as? SFSpeechError)?.code == .internalServiceError)
    }
}

private func assertAttributes() {
    let key = AttributeScopes.SpeechAttributes.ConfidenceAttribute.self
    precondition(key.name.isEmpty == false)
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.9
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.9)
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.invalidationConditions
    _ = String(describing: AttributeScopes.SpeechAttributes.ConfidenceAttribute.self)

    var timed = AttributedString("hello")
    let range = SpeechHostTimeRange(start: 0, duration: 0.4)
    timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = range
    precondition(timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] == range)
    let found = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 0.1, duration: 0.1))
    precondition(found != nil)
    let missed = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 9, duration: 1))
    precondition(missed == nil)
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.name
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.invalidationConditions
    let encoded = try? JSONEncoder().encode(range)
    precondition(encoded != nil)
    let decoded = try? JSONDecoder().decode(SpeechHostTimeRange.self, from: encoded!)
    precondition(decoded == range)
}

private func assertSynthesizedSurface() async {
    let scope = AttributeScopes.SpeechAttributes()
    _ = scope.transcriptionConfidence
    _ = scope.audioTimeRange
    _ = SFSpeechError.Code.audioDisordered
    _ = SFSpeechError.Code.moduleOutputFailed
    _ = SFSpeechError.Code.insufficientResources
    _ = SFSpeechError.Code.unexpectedAudioFormat
    _ = SFSpeechError.Code.assetLocaleNotAllocated
    _ = SFSpeechError.Code.incompatibleAudioFormats
    _ = SFSpeechError.Code.tooManyAssetLocalesAllocated
    _ = SFSpeechError.Code.cannotAllocateUnsupportedLocale
    _ = SFSpeechError.Code.noModel
    let empty = SpeechEmptyResults<Int>()
    var iterator = empty.makeAsyncIterator()
    let next = try? await iterator.next()
    precondition(next == nil)
}
