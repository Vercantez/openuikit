import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioPlayerFailClosed() {
    do {
        _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/no/such/avfaudio-player.wav"))
        preconditionFailure("missing URL")
    } catch {}
    do {
        _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
        preconditionFailure("directory URL")
    } catch {}
    do { _ = try AVAudioPlayer(data: Data()); preconditionFailure("empty data") } catch {}
    do { _ = try AVAudioPlayer(data: Data([0, 1, 2, 3, 4, 5, 6, 7])); preconditionFailure("garbage") } catch {}
    let wave = avfaudioTestWAVE()
    do {
        let fromData = try AVAudioPlayer(data: wave)
        precondition(fromData.format.sampleRate == 44100)
        precondition(fromData.format.channelCount == 2)
        precondition(abs(fromData.duration - (8.0 / 44100.0)) < 0.000_000_1)
        precondition(fromData.prepareToPlay() == false)
        precondition(fromData.play() == false)
        precondition(!fromData.isPlaying)
        fromData.volume = 0.5
        precondition(fromData.volume == 0.5)
        fromData.pan = 0.1
        fromData.rate = 1
        fromData.enableRate = true
        fromData.numberOfLoops = 0
        fromData.isMeteringEnabled = false
        fromData.currentTime = 0
        _ = fromData.data
        _ = fromData.settings
        _ = fromData.numberOfChannels
        _ = fromData.deviceCurrentTime
        _ = fromData.channelAssignments
        fromData.pause()
        fromData.stop()
        fromData.updateMeters()
        _ = fromData.averagePower(forChannel: 0)
        _ = fromData.peakPower(forChannel: 0)
        fromData.setVolume(0.2, fadeDuration: 0)
        _ = fromData.play(atTime: 0)
        let hinted = try AVAudioPlayer(data: wave, fileTypeHint: "public.wav")
        precondition(hinted.duration == fromData.duration)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(
            "avfaudio-valid-\(UUID().uuidString).wav"
        )
        defer { try? FileManager.default.removeItem(at: tmp) }
        try wave.write(to: tmp)
        let fromURL = try AVAudioPlayer(contentsOf: tmp)
        precondition(fromURL.url == tmp)
        _ = try AVAudioPlayer(contentsOf: tmp, fileTypeHint: "public.wav")
        _ = try AVAudioPlayer(contentsOfURL: tmp)
        _ = try AVAudioPlayer(contentsOfURL: tmp, fileTypeHint: "public.wav")
    } catch {
        preconditionFailure("player fixtures: \(error)")
    }
}

