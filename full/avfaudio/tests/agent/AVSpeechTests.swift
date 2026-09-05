import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVSpeechFailClosed() {
    let utterance = AVSpeechUtterance(string: "hello openuikit")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    utterance.pitchMultiplier = 1.1
    utterance.volume = 0.8
    utterance.preUtteranceDelay = 0.01
    utterance.postUtteranceDelay = 0.02
    utterance.prefersAssistiveTechnologySettings = true
    precondition(utterance.speechString == "hello openuikit")
    let attributed = AVSpeechUtterance(attributedString: NSAttributedString(string: "depth"))
    precondition(attributed.attributedSpeechString.string == "depth")
    precondition(AVSpeechUtterance(ssmlRepresentation: "") == nil)
    let ssml = AVSpeechUtterance(SSMLRepresentation: "<speak>hi</speak>")
    precondition(ssml?.speechString.contains("hi") == true)
    let synth = AVSpeechSynthesizer()
    synth.speak(utterance)
    precondition(!synth.isSpeaking)
    precondition(!synth.isPaused)
    precondition(!synth.pauseSpeaking(at: .immediate))
    precondition(!synth.continueSpeaking())
    _ = synth.stopSpeaking(at: .word)
    synth.usesApplicationAudioSession = false
    synth.mixToTelephonyUplink = false
    synth.write(utterance) { _ in }
    synth.write(utterance, toBufferCallback: { _ in }, toMarkerCallback: { _ in })
    precondition(AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .unsupported)
    precondition(AVSpeechSynthesisVoice.speechVoices().isEmpty)
    precondition(AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri") == nil)
    _ = AVSpeechSynthesisVoice(language: "en")
    _ = AVSpeechSynthesizer.availableVoicesDidChangeNotification
    precondition(!AVSpeechSynthesisVoice.currentLanguageCode().isEmpty)
    let marker = AVSpeechSynthesisMarker(wordRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    precondition(marker.mark == .word)
    _ = AVSpeechSynthesisMarker(sentenceRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(paragraphRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(phonemeString: "AH", atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(bookmarkName: "b", atByteSampleOffset: 0)
    let provider = AVSpeechSynthesisProviderVoice(
        name: "x",
        identifier: "id",
        primaryLanguages: ["en"],
        supportedLanguages: ["en"]
    )
    provider.age = 30
    provider.gender = .male
    AVSpeechSynthesisProviderVoice.updateSpeechVoices()
    let request = AVSpeechSynthesisProviderRequest(
        ssmlRepresentation: "<speak>a</speak>",
        voice: provider
    )
    precondition(request.voice.identifier == "id")
    var voiceCount = 0
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { _ in
            voiceCount += 1
            sem.signal()
        }
    }
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(voiceCount == 1)
}

