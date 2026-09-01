import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

    let interleaved = try requireFormat(
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 2,
            interleaved: true
        )
    )
    guard let interleavedBuffer = AVAudioPCMBuffer(pcmFormat: interleaved, frameCapacity: 8) else {
        throw RuntimeFailure.message("interleaved pcm")
    }
    try require(interleavedBuffer.stride == 2, "interleaved stride")

    let host = AVAudioTime.hostTime(forSeconds: 1.5)
    let seconds = AVAudioTime.seconds(forHostTime: host)
    try require(abs(seconds - 1.5) < 0.000_001, "host time conversion")
    let sampleTime = AVAudioTime(sampleTime: 44100, atRate: 44100)
    try require(sampleTime.isSampleTimeValid, "sample time valid")
    try require(!sampleTime.isHostTimeValid, "host time invalid")
    let both = AVAudioTime(hostTime: host, sampleTime: 0, atRate: 44100)
    try require(both.extrapolateTime(fromAnchor: sampleTime) != nil, "extrapolate")
    try proveAudioTimeStampFlagRoundTrip()

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
    try require(session.category == .playback, "session category")
    try require(session.mode == .moviePlayback, "session mode")
    try require(session.categoryOptions.contains(.mixWithOthers), "session options")
    do {
        try session.setActive(true)
        throw RuntimeFailure.message("setActive must fail closed without a host service")
    } catch {
        try require(true, "setActive threw")
    }
    try require(session.sampleRate == 0, "no fabricated hardware sample rate")
    try require(session.outputNumberOfChannels == 0, "no fabricated output channels")
    try require(session.currentRoute.outputs.isEmpty, "no fabricated route")
    try require(session.recordPermission == .denied, "record permission fail-closed")
    try require(!session.isInputAvailable, "no input hardware")
    try require(!session.isMicrophoneInjectionAvailable, "no mic injection")
    do {
        try session.setPreferredSampleRate(48000)
        throw RuntimeFailure.message("setPreferredSampleRate must fail closed")
    } catch {}
    try require(session.sampleRate == 0, "preferred rate did not become hardware rate")
    do {
        try session.overrideOutputAudioPort(.speaker)
        throw RuntimeFailure.message("overrideOutputAudioPort must fail closed")
    } catch {}

    var permissionCalls = 0
    var permissionGranted = true
    var permissionInline = false
    var nestedDuringOuter = false
    var outerFinished = false
    let permissionSem = DispatchSemaphore(value: 0)
    let nestedSem = DispatchSemaphore(value: 0)
    session.requestRecordPermission { granted in
        dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
        permissionCalls += 1
        permissionGranted = granted
        session.requestRecordPermission { _ in
            if !outerFinished { nestedDuringOuter = true }
            nestedSem.signal()
        }
        outerFinished = true
        permissionSem.signal()
    }
    permissionInline = permissionCalls != 0
    try require(!permissionInline, "record permission callback must not run inline")
    try require(permissionSem.wait(timeout: .now() + 2) == .success, "permission callback timeout")
    try require(permissionCalls == 1, "record permission exactly once")
    try require(permissionGranted == false, "record permission denied")
    try require(nestedSem.wait(timeout: .now() + 2) == .success, "nested permission timeout")
    try require(!nestedDuringOuter, "permission callback must not reenter")

    var appPermission = true
    var appInline = false
    var appCount = 0
    let appSem = DispatchSemaphore(value: 0)
    AVAudioApplication.requestRecordPermission { granted in
        dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
        appCount += 1
        appPermission = granted
        appSem.signal()
    }
    appInline = appCount != 0
    try require(!appInline, "application permission must not run inline")
    try require(appSem.wait(timeout: .now() + 2) == .success, "application permission timeout")
    try require(appCount == 1, "application permission exactly once")
    try require(appPermission == false, "application record permission denied")
    try require(
        AVAudioApplication.shared.microphoneInjectionPermission == .serviceDisabled,
        "injection disabled"
    )
    do {
        try AVAudioApplication.shared.setInputMuted(true)
        throw RuntimeFailure.message("setInputMuted must fail closed")
    } catch {}
    try require(AVAudioApplication.shared.isInputMuted, "input remains fail-closed muted")

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    try require(engine.attachedNodes.contains(player), "player attached")
    try require(
        engine.outputConnectionPoints(for: player, outputBus: 0).contains(where: {
            $0.node === engine.mainMixerNode
        }),
        "graph connection"
    )
    try require(!engine.isRunning, "engine is not running")
    do {
        try engine.start()
        throw RuntimeFailure.message("engine.start must fail closed without a device")
    } catch {
        try require(!engine.isRunning, "start must not set running")
    }
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
        throw RuntimeFailure.message("enableManualRenderingMode must fail closed")
    } catch {
        try require(!engine.isInManualRenderingMode, "manual rendering must stay disabled")
    }
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        throw RuntimeFailure.message("render buffer")
    }
    do {
        _ = try engine.renderOffline(256, to: rendered)
        throw RuntimeFailure.message("renderOffline must fail closed")
    } catch {
        try require(rendered.frameLength == 0, "failed render must not claim frames")
    }
    player.play()
    try require(player.isPlaying, "player node local transport")
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
    do {
        try converter.convert(to: converted, from: source)
        throw RuntimeFailure.message("converter must fail closed without a codec host")
    } catch {}

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
    try require(filePlayer.prepareToPlay() == false, "player prepare fail-closed")
    try require(filePlayer.play() == false, "player hardware fail-closed")
    try require(!filePlayer.isPlaying, "player not playing")
    filePlayer.volume = 0.5
    try require(filePlayer.volume == 0.5, "player volume stored")

    let recorder = try AVAudioRecorder(url: tmp.appendingPathExtension("rec"), format: format)
    try require(recorder.prepareToRecord() == false, "recorder prepare fail-closed")
    try require(recorder.record() == false, "recorder hardware fail-closed")
    try require(!recorder.isRecording, "recorder not recording")

    let utterance = AVSpeechUtterance(string: "hello openuikit")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    try require(utterance.speechString == "hello openuikit", "utterance text")
    let synth = AVSpeechSynthesizer()
    synth.speak(utterance)
    try require(!synth.isSpeaking, "speech is not claimed as spoken")
    try require(
        AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .unsupported,
        "personal voice unavailable"
    )
    var voiceStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus?
    var voiceInline = false
    var voiceCount = 0
    let voiceSem = DispatchSemaphore(value: 0)
    AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
        dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
        voiceCount += 1
        voiceStatus = status
        voiceSem.signal()
    }
    voiceInline = voiceCount != 0
    try require(!voiceInline, "personal voice callback must not run inline")
    try require(voiceSem.wait(timeout: .now() + 2) == .success, "personal voice timeout")
    try require(voiceCount == 1, "personal voice exactly once")
    try require(voiceStatus == .unsupported, "personal voice unsupported")
    try require(AVSpeechSynthesisVoice.speechVoices().isEmpty, "no apple voices")
    try require(AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri") == nil, "voice lookup nil")

    let sequencer = AVAudioSequencer()
    let track = sequencer.createAndAppendTrack()
    track.addEvent(AVMIDINoteEvent(channel: 0, key: 60, velocity: 100, duration: 1), at: 0)
    try require(sequencer.tracks.count == 1, "sequencer track")
    do {
        try sequencer.start()
        throw RuntimeFailure.message("sequencer.start must fail closed")
    } catch {
        try require(!sequencer.isPlaying, "sequencer must not claim playback")
    }
    sequencer.stop()

    let delay = AVAudioUnitDelay()
    delay.delayTime = 0.2
    try require(delay.delayTime == 0.2, "delay param")
    let eq = AVAudioUnitEQ(numberOfBands: 3)
    try require(eq.bands.count == 3, "eq bands")

    try require(AVAudioCommonFormat.pcmFormatInt16 != .pcmFormatFloat32, "format inequality")
    try require(
        AVAudioPlayerNodeBufferOptions.loops.contains(.loops),
        "buffer option set"
    )
    try require(
        AVAudioSession.RouteSharingPolicy.longForm == .longFormAudio,
        "longForm alias"
    )
    try require(session.category == .playAndRecord || session.category == .playback, "category still stored")
    try require(AVAudioSession.Category.playAndRecord != .playback, "category inequality")
    try require(!AVFAudioHostAvailability.audioOutputAvailable, "no host output")
    try require(!AVFAudioHostAvailability.audioInputAvailable, "no host input")

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

func proveAudioTimeStampFlagRoundTrip() throws {
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    func stamp(
        hostTime: UInt64,
        sampleTime: Double,
        flags: AudioTimeStampFlags
    ) -> AudioTimeStamp {
        var value = AudioTimeStamp()
        value.mHostTime = hostTime
        value.mSampleTime = sampleTime
        value.mFlags = flags
        return value
    }

    func roundTrip(
        _ flags: AudioTimeStampFlags,
        expectHost: Bool,
        expectSample: Bool,
        label: String
    ) throws {
        var value = stamp(hostTime: 99, sampleTime: 44100, flags: flags)
        try require(
            value.mFlags.contains(.hostTimeValid) == expectHost,
            "\(label) host flag"
        )
        try require(
            value.mFlags.contains(.sampleTimeValid) == expectSample,
            "\(label) sample flag"
        )
        let decoded = AVAudioTime(audioTimeStamp: &value, sampleRate: 44100)
        try require(decoded.isHostTimeValid == expectHost, "\(label) host validity")
        try require(decoded.isSampleTimeValid == expectSample, "\(label) sample validity")
        var encoded = decoded.audioTimeStamp
        try require(
            encoded.mFlags.contains(.hostTimeValid) == expectHost,
            "\(label) encoded host flag"
        )
        try require(
            encoded.mFlags.contains(.sampleTimeValid) == expectSample,
            "\(label) encoded sample flag"
        )
        let again = AVAudioTime(audioTimeStamp: &encoded, sampleRate: 44100)
        try require(again.isHostTimeValid == expectHost, "\(label) second host validity")
        try require(again.isSampleTimeValid == expectSample, "\(label) second sample validity")
        if !expectHost {
            try require(encoded.mHostTime == 0, "\(label) encoded host time cleared")
        }
        if !expectSample {
            try require(encoded.mSampleTime == 0, "\(label) encoded sample time cleared")
        }
    }

    // Leftover mHostTime=99 / mSampleTime=44100 must not imply validity.
    try roundTrip([], expectHost: false, expectSample: false, label: "none")
    try roundTrip([.hostTimeValid], expectHost: true, expectSample: false, label: "host-only")
    try roundTrip([.sampleTimeValid], expectHost: false, expectSample: true, label: "sample-only")
    try roundTrip(
        [.hostTimeValid, .sampleTimeValid],
        expectHost: true,
        expectSample: true,
        label: "both"
    )
    try roundTrip(
        [.rateScalarValid],
        expectHost: false,
        expectSample: false,
        label: "nonzero-rate-scalar-only"
    )

    let hostOnly = AVAudioTime(hostTime: 42)
    var hostStamp = hostOnly.audioTimeStamp
    try require(hostStamp.mFlags.contains(.hostTimeValid), "AVAudioTime host-only flag")
    try require(!hostStamp.mFlags.contains(.sampleTimeValid), "AVAudioTime host-only excludes sample")
    let hostDecoded = AVAudioTime(audioTimeStamp: &hostStamp, sampleRate: 48000)
    try require(hostDecoded.isHostTimeValid && !hostDecoded.isSampleTimeValid, "host-only round-trip")

    let sampleOnly = AVAudioTime(sampleTime: 128, atRate: 44100)
    var sampleStamp = sampleOnly.audioTimeStamp
    try require(sampleStamp.mFlags.contains(.sampleTimeValid), "AVAudioTime sample-only flag")
    try require(!sampleStamp.mFlags.contains(.hostTimeValid), "AVAudioTime sample-only excludes host")
    let sampleDecoded = AVAudioTime(audioTimeStamp: &sampleStamp, sampleRate: 44100)
    try require(
        sampleDecoded.isSampleTimeValid && !sampleDecoded.isHostTimeValid,
        "sample-only round-trip"
    )

    let bothValid = AVAudioTime(hostTime: 7, sampleTime: 256, atRate: 48000)
    var bothStamp = bothValid.audioTimeStamp
    try require(
        bothStamp.mFlags.contains(.hostTimeValid) && bothStamp.mFlags.contains(.sampleTimeValid),
        "AVAudioTime both flags"
    )
    let bothDecoded = AVAudioTime(audioTimeStamp: &bothStamp, sampleRate: 48000)
    try require(
        bothDecoded.isHostTimeValid && bothDecoded.isSampleTimeValid,
        "both flags round-trip"
    )
    print("AVFAUDIO_AUDIO_TIMESTAMP_FLAGS_OK")
    #endif
}

do {
    try run()
} catch {
    fputs("AVFAUDIO_AGENT_RUNTIME_FAIL: \(error)\n", stderr)
    exit(1)
}
