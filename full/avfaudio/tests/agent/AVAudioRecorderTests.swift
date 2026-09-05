import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioRecorderFailClosed() {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "avfaudio-rec-\(UUID().uuidString).caf"
    )
    defer { try? FileManager.default.removeItem(at: url) }
    do {
        let recorder = try AVAudioRecorder(url: url, format: format)
        precondition(recorder.prepareToRecord() == false)
        precondition(recorder.record() == false)
        precondition(!recorder.isRecording)
        _ = recorder.record(atTime: 0)
        _ = recorder.record(forDuration: 0.1)
        _ = recorder.record(atTime: 0, forDuration: 0.1)
        recorder.pause()
        recorder.stop()
        _ = recorder.deleteRecording()
        recorder.updateMeters()
        _ = recorder.averagePower(forChannel: 0)
        _ = recorder.peakPower(forChannel: 0)
        _ = recorder.url
        _ = recorder.format
        _ = recorder.settings
        _ = recorder.currentTime
        _ = recorder.deviceCurrentTime
        _ = recorder.channelAssignments
        recorder.isMeteringEnabled = false
        _ = try AVAudioRecorder(URL: url, format: format)
        _ = try AVAudioRecorder(url: url, settings: format.settings)
        _ = try AVAudioRecorder(URL: url, settings: format.settings)
    } catch {
        preconditionFailure("recorder: \(error)")
    }
}

