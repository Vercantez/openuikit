import Foundation
import AVFAudio

enum RuntimeFailure: Error {
    case message(String)
}

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw RuntimeFailure.message(message) }
}

func run() throws {
    let format = try requireFormat(
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 2,
            interleaved: false
        )
    )
    try require(format.sampleRate == 44100, "sample rate")
    try require(format.channelCount == 2, "channel count")
    try require(format.commonFormat == .pcmFormatFloat32, "common format")
    try require(format.isInterleaved == false, "interleaved")
    try require(format.isStandard, "standard format")
    try require(format.settings[AVSampleRateKey] as? Double == 44100, "settings sample rate")

    let standard = try requireFormat(
        AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
    )
    try require(standard.channelCount == 1, "mono channels")

    guard let fromSettings = AVAudioFormat(settings: [
        AVSampleRateKey: 22050,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsNonInterleaved: true,
        AVLinearPCMBitDepthKey: 32,
    ]) else {
        throw RuntimeFailure.message("settings format")
    }
    try require(fromSettings.sampleRate == 22050, "settings-derived rate")

    let asbd = format.streamDescription.pointee
    try require(asbd.mFormatID == kAudioFormatLinearPCM, "linear PCM asbd")
    guard let fromASBD = AVAudioFormat(streamDescription: format.streamDescription) else {
        throw RuntimeFailure.message("asbd format")
    }
    try require(fromASBD.sampleRate == format.sampleRate, "asbd round-trip")

    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512) else {
        throw RuntimeFailure.message("pcm buffer")
    }
    buffer.frameLength = 256
    try require(buffer.frameCapacity == 512, "frame capacity")
    try require(buffer.stride == 1, "non-interleaved stride")
    guard let planes = buffer.floatChannelData else {
        throw RuntimeFailure.message("float planes")
    }
    planes[0][0] = 0.5
    planes[1][0] = -0.25
    try require(planes[0][0] == 0.5, "channel 0 write")
    try require(planes[1][0] == -0.25, "channel 1 write")

    let host = AVAudioTime.hostTime(forSeconds: 1.5)
    let seconds = AVAudioTime.seconds(forHostTime: host)
    try require(abs(seconds - 1.5) < 0.000_001, "host time conversion")
    let sampleTime = AVAudioTime(sampleTime: 44100, atRate: 44100)
    try require(sampleTime.isSampleTimeValid, "sample time valid")
    try require(!sampleTime.isHostTimeValid, "host time invalid")
    let both = AVAudioTime(hostTime: host, sampleTime: 0, atRate: 44100)
    try require(both.extrapolateTime(fromAnchor: sampleTime) != nil, "extrapolate")

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
    try require(session.category == .playback, "session category")
    try require(session.mode == .moviePlayback, "session mode")
    try require(session.categoryOptions.contains(.mixWithOthers), "session options")
    try session.setActive(true)
    try require(session._isActive, "session active")
    try require(session.recordPermission == .denied, "record permission fail-closed")
    try require(!session.isInputAvailable, "no input hardware")
    try require(!session.isMicrophoneInjectionAvailable, "no mic injection")
    try session.setPreferredSampleRate(48000)
    try require(session.sampleRate == 48000, "preferred sample rate stored")
    try session.setOutputMuted(true)
    try require(session.isOutputMuted, "output muted flag")
    session.requestRecordPermission { granted in
        _ = granted
    }
    try require(AVAudioSession.Category.playAndRecord.rawValue.contains("PlayAndRecord"), "category raw")
    try require(AVAudioSession.Port.builtInSpeaker.rawValue == "Speaker", "port raw")

    var permission = true
    AVAudioApplication.requestRecordPermission { permission = $0 }
    try require(permission == false, "application record permission denied")
    try require(
        AVAudioApplication.shared.microphoneInjectionPermission == .serviceDisabled,
        "injection disabled"
    )
    try AVAudioApplication.shared.setInputMuted(true)
    try require(AVAudioApplication.shared.isInputMuted, "input muted")

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    try require(engine.attachedNodes.contains(player), "player attached")
    try require(
        engine.inputConnectionPoint(for: engine.mainMixerNode, inputBus: 0)?.node === player
            || engine.outputConnectionPoints(for: player, outputBus: 0).contains(where: {
                $0.node === engine.mainMixerNode
            }),
        "graph connection"
    )
    try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
    try require(engine.isInManualRenderingMode, "manual rendering")
    player.volume = 1
    engine.mainMixerNode.outputVolume = 1
    awaitSchedule(player, buffer: buffer)
    player.play()
    try require(player.isPlaying, "player node playing")

    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        throw RuntimeFailure.message("render buffer")
    }
    let status = try engine.renderOffline(256, to: rendered)
    try require(status == .success, "offline render status")
    try require(rendered.frameLength == 256, "rendered frames")
    guard let outPlanes = rendered.floatChannelData else {
        throw RuntimeFailure.message("rendered planes")
    }
    try require(outPlanes[0][0] == 0.5, "mixed channel 0")
    try require(outPlanes[1][0] == -0.25, "mixed channel 1")
    engine.stop()
    try require(!engine.isRunning, "engine stopped")

    let converter = try requireConverter(AVAudioConverter(from: format, to: format))
    guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("converter dest")
    }
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("converter src")
    }
    source.frameLength = 4
    source.floatChannelData?[0][0] = 0.25
    try converter.convert(to: converted, from: source)
    try require(converted.frameLength == 4, "converted frames")
    try require(converted.floatChannelData?[0][0] == 0.25, "converted sample")

    let point = AVAudioMake3DPoint(1, 2, 3)
    try require(point.x == 1 && point.y == 2 && point.z == 3, "3d point")
    let orientation = AVAudioMake3DAngularOrientation(0.1, 0.2, 0.3)
    try require(orientation.pitch == 0.2, "3d orientation")
    let vector = AVAudioMake3DVectorOrientation(
        AVAudioMake3DVector(0, 0, 1),
        AVAudioMake3DVector(0, 1, 0)
    )
    try require(vector.up.y == 1, "vector up")

    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("avfaudio-probe.bin")
    try Data([0, 1, 2, 3]).write(to: tmp)
    let filePlayer = try AVAudioPlayer(contentsOf: tmp)
    try require(filePlayer.prepareToPlay(), "player prepare")
    try require(filePlayer.play() == false, "player hardware fail-closed")
    try require(!filePlayer.isPlaying, "player not playing")
    filePlayer.volume = 0.5
    try require(filePlayer.volume == 0.5, "player volume stored")

    let recorder = try AVAudioRecorder(url: tmp.appendingPathExtension("rec"), format: format)
    try require(recorder.prepareToRecord(), "recorder prepare")
    try require(recorder.record() == false, "recorder hardware fail-closed")
    try require(!recorder.isRecording, "recorder not recording")

    let utterance = AVSpeechUtterance(string: "hello openuikit")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    try require(utterance.speechString == "hello openuikit", "utterance text")
    let synth = AVSpeechSynthesizer()
    synth.speak(utterance)
    try require(synth._queuedUtterances.count == 1, "utterance queued")
    try require(!synth.isSpeaking, "speech is not claimed as spoken")
    try require(
        AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .unsupported,
        "personal voice unavailable"
    )
    try require(AVSpeechSynthesisVoice.speechVoices().isEmpty, "no apple voices")
    try require(AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri") == nil, "voice lookup nil")

    let sequencer = AVAudioSequencer()
    let track = sequencer.createAndAppendTrack()
    track.addEvent(AVMIDINoteEvent(channel: 0, key: 60, velocity: 100, duration: 1), at: 0)
    try require(sequencer.tracks.count == 1, "sequencer track")
    try sequencer.start()
    try require(sequencer.isPlaying, "sequencer software playing flag")
    sequencer.stop()

    let delay = AVAudioUnitDelay()
    delay.delayTime = 0.2
    try require(delay.delayTime == 0.2, "delay param")
    let eq = AVAudioUnitEQ(numberOfBands: 3)
    try require(eq.bands.count == 3, "eq bands")

    try require(AVAudioQuality.max.rawValue == 0x7F, "quality max")
    try require(AVAudioCommonFormat.pcmFormatInt16 != .pcmFormatFloat32, "format inequality")
    try require(
        AVAudioPlayerNodeBufferOptions.loops.contains(.loops),
        "buffer option set"
    )
    try require(AVFormatIDKey == "AVFormatIDKey", "format key")
    try require(AVAUDIOENGINE_HAVE_AUAUDIOUNIT == 0, "no AUAudioUnit feature")
    try require(!AVFAudioPortable.hardwareOutputAvailable, "portable hardware flag")

    try require(
        AVAudioSession.RouteSharingPolicy.longForm == .longFormAudio,
        "longForm alias"
    )

    print("AVFAUDIO_AGENT_RUNTIME_OK")
}

func requireFormat(_ format: AVAudioFormat?) throws -> AVAudioFormat {
    guard let format else { throw RuntimeFailure.message("nil format") }
    return format
}

func requireConverter(_ converter: AVAudioConverter?) throws -> AVAudioConverter {
    guard let converter else { throw RuntimeFailure.message("nil converter") }
    return converter
}

func awaitSchedule(_ player: AVAudioPlayerNode, buffer: AVAudioPCMBuffer) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await player.scheduleBuffer(buffer)
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 2)
}

do {
    try run()
} catch {
    fputs("AVFAUDIO_AGENT_RUNTIME_FAIL: \(error)\n", stderr)
    exit(1)
}
