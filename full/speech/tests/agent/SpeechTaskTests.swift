@_spi(OpenUIKitHost) import Speech
import Foundation

func testSpeechRecognitionTaskUnauthorized() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    let finished = DispatchSemaphore(value: 0)
    let state = SpeechLockedState()
    let task = recognizer.recognitionTask(with: request) { result, error in
        state.noteCallback(.denied, onMain: Thread.isMainThread)
        precondition(result == nil)
        speechRequireAssistantUnauthorized(error)
        finished.signal()
    }
    state.markReturned()
    precondition(state.snapshot().count == 0, "result handler ran inline")
    speechWait(finished, "unauthorized handler did not run")
    precondition(state.snapshot().count == 1)
    precondition(state.snapshot().sawReturned)
    speechRequireAssistantUnauthorized(task.error)
    precondition(task.state == .completed)
}

func testSpeechRecognitionTaskMissingAssets() {
    speechAuthorizeForTests()
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    let assets = DispatchSemaphore(value: 0)
    let task = recognizer.recognitionTask(with: request) { result, error in
        precondition(result == nil)
        speechRequireLSR(error, code: SpeechHostControl.lsrAssetsNotInstalled)
        assets.signal()
    }
    speechWait(assets, "assets-missing handler did not run")
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
    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/tmp/speech.wav"))
    let delegate = SpeechRecordingDelegate()
    recognizer.queue.isSuspended = true
    let task = recognizer.recognitionTask(with: request, delegate: delegate)
    task.cancel()
    precondition(task.isCancelled)
    precondition(task.state == .completed || task.state == .canceling)
    recognizer.queue.isSuspended = false
    speechWait(delegate.finished, "delegate did not finish")
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
    speechWait(delegate.finished, "scripted delegate did not finish")
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
    let done = DispatchSemaphore(value: 0)
    var finals = 0
    _ = recognizer.recognitionTask(with: request) { result, error in
        precondition(error == nil)
        if result?.isFinal == true {
            finals += 1
            precondition(result?.bestTranscription.formattedString == "handler")
            done.signal()
        }
    }
    speechWait(done, "scripted handler did not finish")
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
    speechWait(delegate.finished, "buffer task did not finish")
    precondition(task.isFinishing)
    precondition(task.state == .completed)
    precondition(delegate.snapshot().result?.bestTranscription.formattedString == "buffer")
}
