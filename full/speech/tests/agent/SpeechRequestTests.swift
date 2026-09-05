@_spi(OpenUIKitHost) import Speech
import Foundation

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
