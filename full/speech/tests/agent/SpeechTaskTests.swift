@_spi(OpenUIKitHost) import Speech
import Foundation

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
