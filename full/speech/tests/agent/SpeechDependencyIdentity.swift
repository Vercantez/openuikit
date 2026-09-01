import Foundation
import Speech
import AVFoundation
import CoreMedia

func identityFail(_ message: String) -> Never {
    fputs("SPEECH_DEPENDENCY_IDENTITY_FAIL: \(message)\n", stderr)
    exit(1)
}

func identityRequire(_ condition: Bool, _ message: String) {
    if !condition {
        identityFail(message)
    }
}

func identityIsNSObject(_ value: Any) -> Bool {
    value is NSObject
}

let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)
identityRequire(format.sampleRate == 16_000, "AVAudioFormat sample rate")
identityRequire(format.channelCount == 1, "AVAudioFormat channels")

guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 64) else {
    identityFail("AVAudioPCMBuffer init")
}
buffer.frameLength = 32

let sampleBuffer = CMSampleBuffer()
let time = CMTime(seconds: 0.5, preferredTimescale: 16_000)
identityRequire(time.isNumeric, "CMTime is numeric")
let range = CMTimeRange(start: .zero, duration: time)
identityRequire(range.isValid, "CMTimeRange is valid")

let request = SFSpeechAudioBufferRecognitionRequest()
request.append(buffer)
request.appendAudioSampleBuffer(sampleBuffer)
request.endAudio()
identityRequire(request.nativeAudioFormat.sampleRate == format.sampleRate, "native format")

let input = AnalyzerInput(buffer: buffer, bufferStartTime: time)
identityRequire(input.bufferStartTime?.isNumeric == true, "AnalyzerInput CMTime")
_ = AnalyzerInput(buffer: buffer)

var attributed = AttributedString("identity")
attributed.audioTimeRange = range
let hit = attributed.rangeOfAudioTimeRangeAttributes(intersecting: range)
identityRequire(hit != nil, "CMTimeRange through Speech attributes")

guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
    identityFail("SFSpeechRecognizer init")
}
identityRequire(identityIsNSObject(recognizer), "SFSpeechRecognizer inherits NSObject")
identityRequire(!recognizer.isAvailable, "recognizer stays unavailable")

let audioURL = URL(fileURLWithPath: "/tmp/speech-identity-missing.wav")
do {
    let audioFile = try AVAudioFile(forReading: audioURL)
    _ = audioFile.url
} catch {
    _ = error
}

print("SPEECH_DEPENDENCY_IDENTITY_OK")
