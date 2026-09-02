import Foundation
import AVFAudio

/// Compile probe for roadmap corpus call sites. Not a claim of Apple runtime parity.
final class SignalSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {}

func proveSignalSpeechSynthesizer() {
    let synthesizer = AVSpeechSynthesizer()
    let utterance = AVSpeechUtterance(string: "signal corpus")
    let delegate = SignalSpeechDelegate()
    synthesizer.delegate = delegate
    synthesizer.speak(utterance)
}

func proveTelegramAudioSession() {
    let session = AVAudioSession.sharedInstance()
    _ = session.outputVolume
}

func proveNextcloudRecordPermission() {
    _ = AVAudioApplication.shared.recordPermission
    AVAudioApplication.requestRecordPermission { _ in }
}

proveSignalSpeechSynthesizer()
proveTelegramAudioSession()
proveNextcloudRecordPermission()
print("AVFAUDIO_CORPUS_COMPILE_OK")
