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

func requireThrows(_ message: String, _ operation: () throws -> Void) throws {
    var didThrow = false
    do {
        try operation()
    } catch {
        didThrow = true
    }
    try require(didThrow, message)
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
    try require(
        (format.settings[AVFormatIDKey] as? NSNumber)?.uint32Value == 1_819_304_813,
        "settings format id"
    )
    try require(format.settings[AVLinearPCMIsBigEndianKey] as? Bool == false, "settings endian")
    try require(format.settings[AVLinearPCMIsNonInterleaved] as? Bool == true, "settings non-interleaved")
    try require(format.settings[AVLinearPCMBitDepthKey] as? Int == 32, "settings bit depth")

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
    guard let copied = buffer.copy() as? AVAudioPCMBuffer else {
        throw RuntimeFailure.message("pcm NSCopying dynamic type")
    }
    try require(copied !== buffer, "pcm copy must be independent")
    try require(
        copied.frameCapacity
            == buffer.frameCapacity * AVAudioFrameCount(MemoryLayout<Float>.stride),
        "pcm copy capacity follows first AudioBuffer byte capacity"
    )
    try require(copied.frameLength == buffer.frameLength, "pcm copy frame length")
    try require(copied.floatChannelData?[0][0] == 0.5, "pcm copy sample")
    planes[0][0] = 0.75
    try require(copied.floatChannelData?[0][0] == 0.5, "pcm copy storage independence")
    guard let mutableCopied = buffer.mutableCopy() as? AVAudioPCMBuffer else {
        throw RuntimeFailure.message("pcm NSMutableCopying dynamic type")
    }
    try require(mutableCopied !== buffer, "pcm mutable copy must be independent")
    try require(
        mutableCopied.frameCapacity == copied.frameCapacity,
        "pcm mutable copy capacity"
    )
    try require(mutableCopied.floatChannelData?[0][0] == 0.75, "pcm mutable copy sample")

    let compressed = AVAudioCompressedBuffer(
        format: format,
        packetCapacity: 3,
        maximumPacketSize: 8
    )
    guard let compressedCopy = compressed.copy() as? AVAudioBuffer else {
        throw RuntimeFailure.message("compressed NSCopying base type")
    }
    guard let compressedMutableCopy = compressed.mutableCopy() as? AVAudioBuffer else {
        throw RuntimeFailure.message("compressed NSMutableCopying base type")
    }
    try require(
        !(compressedCopy is AVAudioCompressedBuffer),
        "compressed copy must use AVAudioBuffer dynamic type"
    )
    try require(
        !(compressedMutableCopy is AVAudioCompressedBuffer),
        "compressed mutable copy must use AVAudioBuffer dynamic type"
    )
    try require(compressedCopy !== compressed, "compressed copy must be independent")
    try require(
        compressedMutableCopy !== compressed,
        "compressed mutable copy must be independent"
    )
    try require(compressedCopy.format === compressed.format, "compressed copy format identity")
    try require(
        compressedMutableCopy.format === compressed.format,
        "compressed mutable copy format identity"
    )

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
    interleavedBuffer.frameLength = 2
    interleavedBuffer.floatChannelData?[0][0] = 0.125
    interleavedBuffer.floatChannelData?[1][0] = -0.5
    interleavedBuffer.floatChannelData?[0][interleavedBuffer.stride] = 0.25
    try require(
        interleavedBuffer.floatChannelData?[0][0] == 0.125,
        "interleaved ch0 is not aliased to ch1"
    )
    try require(
        interleavedBuffer.floatChannelData?[1][0] == -0.5,
        "interleaved ch1 offset by one sample"
    )
    try require(
        interleavedBuffer.floatChannelData?[0][interleavedBuffer.stride] == 0.25,
        "interleaved frame stride"
    )
    guard let interleavedCopy = interleavedBuffer.copy() as? AVAudioPCMBuffer else {
        throw RuntimeFailure.message("interleaved pcm copy")
    }
    try require(
        interleavedCopy.frameCapacity
            == interleavedBuffer.frameCapacity
                * AVAudioFrameCount(MemoryLayout<Float>.stride)
                * AVAudioFrameCount(interleavedBuffer.stride),
        "interleaved copy capacity follows first AudioBuffer byte capacity"
    )

    let int16Format = try requireFormat(
        AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 44_100,
            channels: 2,
            interleaved: false
        )
    )
    guard
        let int16Buffer = AVAudioPCMBuffer(pcmFormat: int16Format, frameCapacity: 3),
        let int16Copy = int16Buffer.copy() as? AVAudioPCMBuffer
    else {
        throw RuntimeFailure.message("int16 pcm copy")
    }
    try require(int16Copy.frameCapacity == 6, "int16 copy byte capacity")
    try require(int16Buffer.int16ChannelData != nil, "int16 channel data")
    int16Buffer.frameLength = 1
    int16Buffer.int16ChannelData?[0][0] = 1024
    int16Buffer.int16ChannelData?[1][0] = -2048

    let int32Format = try requireFormat(
        AVAudioFormat(
            commonFormat: .pcmFormatInt32,
            sampleRate: 48_000,
            channels: 1,
            interleaved: true
        )
    )
    guard let int32Buffer = AVAudioPCMBuffer(pcmFormat: int32Format, frameCapacity: 4) else {
        throw RuntimeFailure.message("int32 pcm")
    }
    try require(int32Buffer.stride == 1, "int32 interleaved stride")
    try require(int32Buffer.int32ChannelData != nil, "int32 channel data")
    int32Buffer.frameLength = 1
    int32Buffer.int32ChannelData?[0][0] = 100_000

    let host = AVAudioTime.hostTime(forSeconds: 1.5)
    let seconds = AVAudioTime.seconds(forHostTime: host)
    try require(abs(seconds - 1.5) < 0.000_001, "host time conversion")
    try require(AVAudioTime.hostTime(forSeconds: -1.5) == 0, "negative hostTime clamped")
    try require(AVAudioTime.hostTime(forSeconds: .nan) == 0, "non-finite hostTime clamped")
    let sampleTime = AVAudioTime(sampleTime: 44100, atRate: 44100)
    try require(sampleTime.isSampleTimeValid, "sample time valid")
    try require(!sampleTime.isHostTimeValid, "host time invalid")
    let both = AVAudioTime(hostTime: host, sampleTime: 0, atRate: 44100)
    try require(both.extrapolateTime(fromAnchor: sampleTime) != nil, "extrapolate")
    try proveExtrapolateTime()
    try proveAudioTimeStampFlagRoundTrip()

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
    try require(session.category == .playback, "session category")
    try require(session.mode == .moviePlayback, "session mode")
    try require(session.categoryOptions.contains(.mixWithOthers), "session options")
    try requireThrows("setActive must fail closed without a host service") {
        try session.setActive(true)
    }
    try require(session.sampleRate == 0, "no fabricated hardware sample rate")
    try require(session.outputVolume == 0, "telegram outputVolume fail-closed")
    try require(
        AVAudioApplication.shared.recordPermission == .denied,
        "nextcloud recordPermission fail-closed"
    )
    try require(session.outputNumberOfChannels == 0, "no fabricated output channels")
    try require(session.currentRoute.outputs.isEmpty, "no fabricated route")
    try require(session.recordPermission == .denied, "record permission fail-closed")
    try require(!session.isInputAvailable, "no input hardware")
    try require(!session.isMicrophoneInjectionAvailable, "no mic injection")
    try requireThrows("setPreferredSampleRate must fail closed") {
        try session.setPreferredSampleRate(48000)
    }
    try require(session.sampleRate == 0, "preferred rate did not become hardware rate")
    try requireThrows("overrideOutputAudioPort must fail closed") {
        try session.overrideOutputAudioPort(.speaker)
    }

    var permissionCalls = 0
    var permissionGranted = true
    var permissionInline = false
    var nestedDuringOuter = false
    var outerFinished = false
    let permissionSem = DispatchSemaphore(value: 0)
    let nestedSem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
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
    }
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
    AVFAudioHostAvailability.callbackQueue.sync {
        AVAudioApplication.requestRecordPermission { granted in
            dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
            appCount += 1
            appPermission = granted
            appSem.signal()
        }
        appInline = appCount != 0
    }
    try require(!appInline, "application permission must not run inline")
    try require(appSem.wait(timeout: .now() + 2) == .success, "application permission timeout")
    try require(appCount == 1, "application permission exactly once")
    try require(appPermission == false, "application record permission denied")
    try require(
        AVAudioApplication.shared.microphoneInjectionPermission == .serviceDisabled,
        "injection disabled"
    )
    try requireThrows("setInputMuted must fail closed") {
        try AVAudioApplication.shared.setInputMuted(true)
    }
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
    try proveEngineConnectReplacement(format: format)
    try require(!engine.isRunning, "engine is not running")
    try requireThrows("engine.start must fail closed without a device or manual rendering") {
        try engine.start()
    }
    try require(!engine.isRunning, "start must not set running")
    try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
    try require(engine.isInManualRenderingMode, "manual rendering enabled")
    try require(engine.manualRenderingMode == .offline, "manual mode offline")
    try require(engine.manualRenderingMaximumFrameCount == 512, "manual max frames")
    try require(engine.manualRenderingFormat.sampleRate == format.sampleRate, "manual format")
    try requireThrows("enableManualRenderingMode twice throws initialized") {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
    }
    try engine.start()
    try require(engine.isRunning, "manual start sets running")
    player.scheduleBuffer(buffer, completionHandler: {})
    player.volume = 1
    player.pan = 0
    player.play()
    try require(player.isPlaying, "player node local transport")
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        throw RuntimeFailure.message("render buffer")
    }
    let status = try engine.renderOffline(256, to: rendered)
    try require(status == .success, "offline render success")
    try require(rendered.frameLength == 256, "rendered frames")
    try require(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.75) < 0.000_1, "mixed channel 0")
    try require(abs((rendered.floatChannelData?[1][0] ?? 0) + 0.25) < 0.000_1, "mixed channel 1")
    try require(engine.manualRenderingSampleTime == 256, "manual sample time advanced")
    engine.stop()
    try require(!engine.isRunning, "engine stopped")
    engine.disableManualRenderingMode()
    try require(!engine.isInManualRenderingMode, "manual rendering disabled")
    try proveManualRenderingMix(format: format)
    try proveManualRenderingErrors(format: format)

    let converter = try requireConverter(AVAudioConverter(from: format, to: format))
    guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("converter dest")
    }
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("converter src")
    }
    source.frameLength = 4
    source.floatChannelData?[0][0] = 0.25
    source.floatChannelData?[1][0] = -0.5
    try converter.convert(to: converted, from: source)
    try require(converted.frameLength == 4, "pcm convert frames")
    try require(abs((converted.floatChannelData?[0][0] ?? 0) - 0.25) < 0.000_1, "pcm convert ch0")
    try proveConverterFamilies()
    try proveAudioFileContainers(format: format)

    let point = AVAudioMake3DPoint(1, 2, 3)
    try require(point.x == 1 && point.y == 2 && point.z == 3, "3d point")
    let orientation = AVAudioMake3DAngularOrientation(0.1, 0.2, 0.3)
    try require(orientation.pitch == 0.2, "3d orientation")
    let vector = AVAudioMake3DVectorOrientation(
        AVAudioMake3DVector(0, 0, 1),
        AVAudioMake3DVector(0, 1, 0)
    )
    try require(vector.up.y == 1, "vector up")

    try provePlayerFixtures()
    try proveCorpusCompileSurfaces()
    try proveGraphSendable()
    try proveDepthCatalog()
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(
        "avfaudio-probe-\(UUID().uuidString).bin"
    )
    let recordingURL = tmp.appendingPathExtension("rec")
    defer {
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: recordingURL)
    }
    try avfaudioTestLinearPCMWAVE().write(to: tmp)
    let recorder = try AVAudioRecorder(url: recordingURL, format: format)
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
    AVFAudioHostAvailability.callbackQueue.sync {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
            dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
            voiceCount += 1
            voiceStatus = status
            voiceSem.signal()
        }
        voiceInline = voiceCount != 0
    }
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
    try requireThrows("sequencer.start must fail closed") {
        try sequencer.start()
    }
    try require(!sequencer.isPlaying, "sequencer must not claim playback")
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

func proveManualRenderingMix(format: AVAudioFormat) throws {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let eq = AVAudioUnitEQ(numberOfBands: 2)
    eq.globalGain = 0
    engine.attach(player)
    engine.attach(eq)
    engine.connect(player, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    engine.mainMixerNode.outputVolume = 0.5
    player.volume = 1
    player.pan = -1
    try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 64)
    try engine.start()
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("mix source")
    }
    source.frameLength = 8
    source.floatChannelData?[0][0] = 1
    source.floatChannelData?[1][0] = 1
    player.scheduleBuffer(source, completionHandler: {})
    player.play()
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        throw RuntimeFailure.message("mix dest")
    }
    let status = try engine.renderOffline(8, to: rendered)
    try require(status == .success, "mix render")
    try require(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.5) < 0.000_1, "pan left + mixer gain")
    try require(abs(rendered.floatChannelData?[1][0] ?? 1) < 0.000_1, "pan left silences right")
    engine.stop()
    engine.disableManualRenderingMode()
}

func proveManualRenderingErrors(format: AVAudioFormat) throws {
    let engine = AVAudioEngine()
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16) else {
        throw RuntimeFailure.message("error buffer")
    }
    try requireThrows("render without manual mode") {
        _ = try engine.renderOffline(8, to: buffer)
    }
    try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 16)
    try requireThrows("render without start") {
        _ = try engine.renderOffline(8, to: buffer)
    }
    engine.prepare()
    try engine.start()
    engine.pause()
    try require(!engine.isRunning, "paused engine is not running")
    try engine.start()
    _ = try engine.renderOffline(4, to: buffer)
    engine.reset()
    try require(engine.manualRenderingSampleTime == 0, "reset sample time")
}

func proveConverterFamilies() throws {
    let floatFormat = try requireFormat(
        AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
    )
    let intFormat = try requireFormat(
        AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 2, interleaved: false)
    )
    let mono = try requireFormat(
        AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: false)
    )
    let converter = try requireConverter(AVAudioConverter(from: floatFormat, to: intFormat))
    converter.bitRate = 128_000
    converter.bitRateStrategy = AVAudioBitRateStrategy_Constant
    converter.sampleRateConverterQuality = AVAudioQuality.medium.rawValue
    converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Normal
    converter.channelMap = [0, 1]
    converter.dither = true
    converter.downmix = false
    converter.primeMethod = .none
    converter.primeInfo = AVAudioConverterPrimeInfo(leadingFrames: 0, trailingFrames: 0)
    converter.contentSource = .unspecified
    converter.dynamicRangeControlConfiguration = .none
    converter.audioSyncPacketFrequency = 0
    converter.magicCookie = Data()
    try require(converter.inputFormat === floatFormat, "converter input")
    try require(converter.outputFormat === intFormat, "converter output")
    try require(converter.applicableEncodeBitRates == nil, "no encode table")
    try require(converter.maximumOutputPacketSize == 0, "pcm packet size")
    guard
        let src = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: 4),
        let dst = AVAudioPCMBuffer(pcmFormat: intFormat, frameCapacity: 4)
    else {
        throw RuntimeFailure.message("int convert buffers")
    }
    src.frameLength = 4
    src.floatChannelData?[0][0] = 0.5
    try converter.convert(to: dst, from: src)
    try require(dst.frameLength == 4, "int convert frames")
    try require((dst.int16ChannelData?[0][0] ?? 0) > 14000, "float to int16")
    converter.reset()

    let rateConverter = try requireConverter(AVAudioConverter(from: floatFormat, to: mono))
    rateConverter.downmix = true
    guard
        let rateSrc = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: 8),
        let rateDst = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: 8)
    else {
        throw RuntimeFailure.message("rate convert buffers")
    }
    rateSrc.frameLength = 8
    for frame in 0..<8 {
        rateSrc.floatChannelData?[0][frame] = 0.4
        rateSrc.floatChannelData?[1][frame] = 0.4
    }
    try rateConverter.convert(to: rateDst, from: rateSrc)
    try require(rateDst.frameLength == 4, "linear resample half rate")
    try require(abs((rateDst.floatChannelData?[0][0] ?? 0) - 0.4) < 0.05, "resampled value")

    var blockError: NSError?
    let status = converter.convert(to: dst, error: &blockError) { _, inputStatus in
        inputStatus.pointee = .haveData
        return src
    }
    try require(status == .haveData || status == .error, "block convert returned")
}

func proveAudioFileContainers(format: AVAudioFormat) throws {
    let directory = FileManager.default.temporaryDirectory
    let wavURL = directory.appendingPathComponent("avfaudio-depth-\(UUID().uuidString).wav")
    let cafURL = directory.appendingPathComponent("avfaudio-depth-\(UUID().uuidString).caf")
    let aiffURL = directory.appendingPathComponent("avfaudio-depth-\(UUID().uuidString).aiff")
    defer {
        try? FileManager.default.removeItem(at: wavURL)
        try? FileManager.default.removeItem(at: cafURL)
        try? FileManager.default.removeItem(at: aiffURL)
    }

    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16) else {
        throw RuntimeFailure.message("file source")
    }
    source.frameLength = 16
    source.floatChannelData?[0][0] = 0.25
    source.floatChannelData?[1][1] = -0.5

    let writer = try AVAudioFile(forWriting: wavURL, settings: format.settings)
    try require(writer.fileFormat.sampleRate == 44100, "wav write format")
    try writer.write(from: source)
    try require(writer.length == 16, "wav write length")
    try require(writer.framePosition == 16, "wav write position")
    writer.close()
    try require(!writer.isOpen, "wav closed")

    let reader = try AVAudioFile(forReading: wavURL)
    try require(reader.length == 16, "wav read length")
    try require(reader.url == wavURL, "wav url")
    try require(reader.processingFormat.isStandard, "wav processing standard")
    guard let wavBuffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: 16) else {
        throw RuntimeFailure.message("wav buffer")
    }
    try reader.read(into: wavBuffer)
    try require(wavBuffer.frameLength == 16, "wav frames read")
    try require(abs((wavBuffer.floatChannelData?[0][0] ?? 0) - 0.25) < 0.01, "wav sample")
    reader.framePosition = 0
    try reader.read(into: wavBuffer, frameCount: 4)
    try require(wavBuffer.frameLength == 4, "wav partial read")

    let processingWriter = try AVAudioFile(
        forWriting: cafURL,
        settings: format.settings,
        commonFormat: .pcmFormatFloat32,
        interleaved: false
    )
    try processingWriter.write(from: source)
    processingWriter.close()
    let cafReader = try AVAudioFile(
        forReading: cafURL,
        commonFormat: .pcmFormatFloat32,
        interleaved: false
    )
    try require(cafReader.length == 16, "caf length")
    guard let cafBuffer = AVAudioPCMBuffer(pcmFormat: cafReader.processingFormat, frameCapacity: 16) else {
        throw RuntimeFailure.message("caf buffer")
    }
    try cafReader.read(into: cafBuffer)
    try require(abs((cafBuffer.floatChannelData?[0][0] ?? 0) - 0.25) < 0.01, "caf sample")

    try avfaudioTestAIFF().write(to: aiffURL)
    let aiff = try AVAudioFile(forReading: aiffURL)
    try require(aiff.fileFormat.channelCount == 1, "aiff channels")
    try require(aiff.length == 4, "aiff frames")
    guard let aiffBuffer = AVAudioPCMBuffer(pcmFormat: aiff.processingFormat, frameCapacity: 8) else {
        throw RuntimeFailure.message("aiff buffer")
    }
    try aiff.read(into: aiffBuffer)
    try require(aiffBuffer.frameLength == 4, "aiff read")

    try requireThrows("missing audio file") {
        _ = try AVAudioFile(forReading: URL(fileURLWithPath: "/no/such/avfaudio-file.wav"))
    }

    let layout = AVAudioChannelLayout(layoutTag: 0x650002)
    try require(layout?.channelCount == 2, "layout tag channels")
    try require(layout?.layoutTag == 0x650002, "layout tag stored")
    let layoutFormat = AVAudioFormat(
        standardFormatWithSampleRate: 48000,
        channelLayout: layout!
    )
    try require(layoutFormat.channelCount == 2, "layout format channels")
    try require(layoutFormat.channelLayout?.layoutTag == 0x650002, "layout format tag")
    try require(
        (layoutFormat.settings[AVChannelLayoutKey] as? NSNumber)?.uint32Value == 0x650002,
        "settings channel layout"
    )
    let commonLayout = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 44100,
        interleaved: true,
        channelLayout: layout!
    )
    try require(commonLayout.isInterleaved, "layout interleaved")
    try require(layout!.isEqual(layout), "layout equal")
}

func proveDepthCatalog() throws {
    try proveDepthConstants()
    try proveDepthEnums()
    try proveDepthSessionSurface()
    try proveDepthGraphSurface()
    try proveDepthSpeechAndMIDI()
    try proveDepthApplicationAnd3D()
}

func proveDepthConstants() throws {
    try require(AVAudioBitRateStrategy_Constant.contains("Constant"), "bitrate constant")
    try require(AVAudioBitRateStrategy_LongTermAverage.contains("LongTerm"), "bitrate lta")
    try require(AVAudioBitRateStrategy_Variable.contains("Variable"), "bitrate var")
    try require(AVAudioBitRateStrategy_VariableConstrained.contains("Constrained"), "bitrate vbr")
    try require(AVAudioFileTypeKey == "AVAudioFileTypeKey", "file type key")
    _ = AVAudioSessionInterruptionOptionKey
    _ = AVAudioSessionInterruptionReasonKey
    _ = AVAudioSessionInterruptionTypeKey
    _ = AVAudioSessionInterruptionWasSuspendedKey
    _ = AVAudioSessionMicrophoneInjectionIsAvailableKey
    _ = AVAudioSessionRenderingModeNewRenderingModeKey
    _ = AVAudioSessionRouteChangePreviousRouteKey
    _ = AVAudioSessionRouteChangeReasonKey
    _ = AVAudioSessionSilenceSecondaryAudioHintTypeKey
    _ = AVAudioSessionSpatialAudioEnabledKey
    try require(AVSpeechUtteranceMinimumSpeechRate == 0, "min speech rate")
    try require(AVSpeechUtteranceMaximumSpeechRate == 1, "max speech rate")
    try require(AVSpeechUtteranceDefaultSpeechRate == 0.5, "default speech rate")
    _ = AVSpeechSynthesisVoiceIdentifierAlex
    _ = AVSpeechSynthesisIPANotationAttribute
    _ = AVFormatIDKey
    _ = AVSampleRateKey
    _ = AVNumberOfChannelsKey
    _ = AVLinearPCMBitDepthKey
    _ = AVLinearPCMIsBigEndianKey
    _ = AVLinearPCMIsFloatKey
    _ = AVLinearPCMIsNonInterleaved
    _ = AVChannelLayoutKey
    _ = AVEncoderAudioQualityKey
    _ = AVEncoderAudioQualityForVBRKey
    _ = AVEncoderBitRateKey
    _ = AVEncoderBitRatePerChannelKey
    _ = AVEncoderBitRateStrategyKey
    _ = AVEncoderBitDepthHintKey
    _ = AVEncoderASPFrequencyKey
    _ = AVEncoderContentSourceKey
    _ = AVEncoderDynamicRangeControlConfigurationKey
    _ = AVSampleRateConverterAlgorithmKey
    _ = AVSampleRateConverterAudioQualityKey
    _ = AVSampleRateConverterAlgorithm_Mastering
    _ = AVSampleRateConverterAlgorithm_MinimumPhase
    _ = AVSampleRateConverterAlgorithm_Normal
    _ = AVAudioUnitTypeOutput
    _ = AVAudioUnitTypeMusicDevice
    _ = AVAudioUnitTypeMusicEffect
    _ = AVAudioUnitTypeFormatConverter
    _ = AVAudioUnitTypeEffect
    _ = AVAudioUnitTypeMixer
    _ = AVAudioUnitTypePanner
    _ = AVAudioUnitTypeGenerator
    _ = AVAudioUnitTypeOfflineEffect
    _ = AVAudioUnitTypeMIDIProcessor
    _ = AVAudioUnitManufacturerNameApple
    try require(AVMusicTimeStampEndOfTrack == Double(Int64.max), "end of track")
    let range = AVMakeBeatRange(1, 4)
    try require(range.start == 1 && range.length == 4, "beat range")
    let emptyRange = AVAudioBeatRange()
    try require(emptyRange.length == 0, "empty beat range")
    try require(
        Notification.Name.AVAudioEngineConfigurationChange.rawValue
            == "AVAudioEngineConfigurationChangeNotification",
        "engine configuration name"
    )
    try require(
        Notification.Name.AVAudioUnitComponentTagsDidChange.rawValue
            == "AVAudioUnitComponentTagsDidChangeNotification",
        "unit tags name"
    )
}

func proveDepthEnums() throws {
    let formats: [AVAudioCommonFormat] = [
        .otherFormat, .pcmFormatFloat32, .pcmFormatFloat64, .pcmFormatInt16, .pcmFormatInt32,
    ]
    try require(formats.count == 5, "common formats")
    try require(AVAudioCommonFormat(rawValue: 1) == .pcmFormatFloat32, "common format raw")
    try require(AVAudio3DMixingPointSourceInHeadMode.mono != .bypass, "in-head")
    try require(AVAudio3DMixingRenderingAlgorithm.HRTF != .auto, "render algo")
    _ = AVAudio3DMixingRenderingAlgorithm.equalPowerPanning
    _ = AVAudio3DMixingRenderingAlgorithm.sphericalHead
    _ = AVAudio3DMixingRenderingAlgorithm.soundField
    _ = AVAudio3DMixingRenderingAlgorithm.stereoPassThrough
    _ = AVAudio3DMixingRenderingAlgorithm.HRTFHQ
    _ = AVAudio3DMixingSourceMode.spatializeIfMono
    _ = AVAudio3DMixingSourceMode.bypass
    _ = AVAudio3DMixingSourceMode.pointSource
    _ = AVAudio3DMixingSourceMode.ambienceBed
    _ = AVAudioContentSource.unspecified
    _ = AVAudioContentSource.passthrough
    _ = AVAudioContentSource.music_Spatial
    _ = AVAudioConverterInputStatus.haveData
    _ = AVAudioConverterInputStatus.noDataNow
    _ = AVAudioConverterInputStatus.endOfStream
    _ = AVAudioConverterOutputStatus.haveData
    _ = AVAudioConverterOutputStatus.inputRanDry
    _ = AVAudioConverterOutputStatus.endOfStream
    _ = AVAudioConverterOutputStatus.error
    _ = AVAudioConverterPrimeMethod.pre
    _ = AVAudioConverterPrimeMethod.normal
    _ = AVAudioConverterPrimeMethod.none
    _ = AVAudioDynamicRangeControlConfiguration.music
    _ = AVAudioEngineManualRenderingError.invalidMode
    _ = AVAudioEngineManualRenderingError.initialized
    _ = AVAudioEngineManualRenderingError.notRunning
    _ = AVAudioEngineManualRenderingMode.offline
    _ = AVAudioEngineManualRenderingMode.realtime
    _ = AVAudioEngineManualRenderingStatus.error
    _ = AVAudioEngineManualRenderingStatus.success
    _ = AVAudioEngineManualRenderingStatus.insufficientDataFromInputNode
    _ = AVAudioEngineManualRenderingStatus.cannotDoInCurrentContext
    _ = AVAudioEnvironmentDistanceAttenuationModel.exponential
    _ = AVAudioEnvironmentOutputType.headphones
    _ = AVAudioPlayerNodeCompletionCallbackType.dataConsumed
    _ = AVAudioQuality.min
    _ = AVAudioQuality.low
    _ = AVAudioQuality.high
    _ = AVAudioQuality.max
    _ = AVAudioUnitDistortionPreset.drumsBitBrush
    _ = AVAudioUnitDistortionPreset.speechWaves
    _ = AVAudioUnitEQFilterType.parametric
    _ = AVAudioUnitEQFilterType.resonantHighShelf
    _ = AVAudioUnitReverbPreset.smallRoom
    _ = AVAudioUnitReverbPreset.cathedral
    _ = AVAudioVoiceProcessingSpeechActivityEvent.started
    _ = AVMusicTrackLoopCount.forever
    _ = AVSpeechBoundary.immediate
    _ = AVSpeechBoundary.word
    _ = AVSpeechSynthesisVoiceGender.female
    _ = AVSpeechSynthesisVoiceQuality.premium
    try require(
        AVAudioPlayerNodeBufferOptions.loops.contains(.loops)
            && AVAudioPlayerNodeBufferOptions.interrupts.contains(.interrupts)
            && AVAudioPlayerNodeBufferOptions.interruptsAtLoop.contains(.interruptsAtLoop),
        "buffer options"
    )
    try require(AVAudioSessionActivationOptions().rawValue == 0, "activation options")
    try require(
        AVMusicSequenceLoadOptions.smf_ChannelsToTracks.rawValue != 0,
        "sequence load options"
    )
    var duck = AVAudioVoiceProcessingOtherAudioDuckingConfiguration(
        enableAdvancedDucking: true,
        duckingLevel: .max
    )
    duck.enableAdvancedDucking = false
    try require(duck.duckingLevel == .max, "ducking")
}

func proveDepthSessionSurface() throws {
    let session = AVAudioSession.sharedInstance()
    _ = AVAudioSession.Category.ambient
    _ = AVAudioSession.Category.soloAmbient
    _ = AVAudioSession.Category.record
    _ = AVAudioSession.Category.multiRoute
    _ = AVAudioSession.Category.audioProcessing
    _ = AVAudioSession.Mode.default
    _ = AVAudioSession.Mode.voiceChat
    _ = AVAudioSession.Mode.videoChat
    _ = AVAudioSession.Mode.gameChat
    _ = AVAudioSession.Mode.videoRecording
    _ = AVAudioSession.Mode.measurement
    _ = AVAudioSession.Mode.spokenAudio
    _ = AVAudioSession.Mode.voicePrompt
    _ = AVAudioSession.Mode.shortFormVideo
    _ = AVAudioSession.Port.lineIn
    _ = AVAudioSession.Port.builtInMic
    _ = AVAudioSession.Port.headphones
    _ = AVAudioSession.Port.bluetoothA2DP
    _ = AVAudioSession.Port.airPlay
    _ = AVAudioSession.Location.upper
    _ = AVAudioSession.Location.orientationTop
    _ = AVAudioSession.Orientation.front
    _ = AVAudioSession.PolarPattern.cardioid
    _ = AVAudioSession.CategoryOptions.duckOthers
    _ = AVAudioSession.CategoryOptions.allowBluetooth
    _ = AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation
    _ = AVAudioSession.InterruptionOptions.shouldResume
    _ = AVAudioSession.IOType.aggregated
    _ = AVAudioSession.InterruptionType.began
    _ = AVAudioSession.InterruptionReason.routeDisconnected
    _ = AVAudioSession.RouteChangeReason.newDeviceAvailable
    _ = AVAudioSession.PromptStyle.short
    _ = AVAudioSession.StereoOrientation.landscapeLeft
    _ = AVAudioSession.RenderingMode.dolbyAtmos
    _ = AVAudioSession.MicrophoneInjectionMode.spokenAudio
    _ = AVAudioSession.interruptionNotification
    _ = AVAudioSession.routeChangeNotification
    _ = AVAudioSession.mediaServicesWereLostNotification
    _ = AVAudioSession.mediaServicesWereResetNotification
    _ = AVAudioSession.silenceSecondaryAudioHintNotification
    _ = AVAudioSession.spatialPlaybackCapabilitiesChangedNotification
    _ = AVAudioSession.availableInputsChangeNotification
    _ = AVAudioSession.renderingModeChangeNotification
    _ = AVAudioSession.renderingCapabilitiesChangeNotification
    _ = AVAudioSession.microphoneInjectionCapabilitiesChangeNotification
    _ = AVAudioSession.outputMuteStateChangeNotification
    _ = AVAudioSession.userIntentToUnmuteOutputNotification
    _ = AVAudioSession.muteStateKey
    try session.setCategory(.playback)
    try session.setCategory(.playback, options: [.mixWithOthers])
    try session.setMode(.moviePlayback)
    try require(!session.availableCategories.isEmpty, "available categories")
    try require(!session.availableModes.isEmpty, "available modes")
    try require(session.promptStyle == .none, "prompt style")
    try require(session.renderingMode == .notApplicable, "rendering mode")
    try require(session.inputLatency == 0 && session.outputLatency == 0, "latency")
    try require(session.maximumInputNumberOfChannels == 0, "max in")
    try require(session.preferredOutputNumberOfChannels == 2, "pref out stored default")
    try requireThrows("aggregated io") { try session.setAggregatedIOPreference(.aggregated) }
    let port = AVAudioSessionPortDescription(
        portType: .builtInSpeaker,
        portName: "Speaker",
        uid: "spk"
    )
    try require(port.portType == .builtInSpeaker, "port type")
    try requireThrows("preferred data source") { try port.setPreferredDataSource(nil) }
    let channel = AVAudioSessionChannelDescription(
        channelName: "Left",
        channelNumber: 1,
        owningPortUID: "spk",
        channelLabel: 1
    )
    try require(channel.channelNumber == 1, "channel number")
    let source = AVAudioSessionDataSourceDescription(
        dataSourceID: 1,
        dataSourceName: "Mic",
        location: .upper,
        orientation: .front
    )
    try source.setPreferredPolarPattern(.cardioid)
    try require(source.preferredPolarPattern == .cardioid, "polar")
    _ = AVAudioSessionCapability()
    _ = AVAudioSessionPortExtensionBluetoothMicrophone().highQualityRecording.isSupported
}

func proveDepthGraphSurface() throws {
    let engine = AVAudioEngine()
    let mixer = AVAudioMixerNode()
    let player = AVAudioPlayerNode()
    let delay = AVAudioUnitDelay()
    let distortion = AVAudioUnitDistortion()
    let reverb = AVAudioUnitReverb()
    let pitch = AVAudioUnitTimePitch()
    let vari = AVAudioUnitVarispeed()
    let sampler = AVAudioUnitSampler()
    let env = AVAudioEnvironmentNode()
    engine.attach(mixer)
    engine.attach(player)
    engine.attach(delay)
    engine.attach(distortion)
    engine.attach(reverb)
    engine.attach(pitch)
    engine.attach(vari)
    engine.attach(sampler)
    engine.attach(env)
    try require(player.numberOfInputs == 1, "player inputs")
    try require(engine.inputNode.numberOfInputs == 0, "input node inputs")
    try require(engine.outputNode.numberOfOutputs == 0, "output node outputs")
    _ = player.latency
    _ = player.outputPresentationLatency
    _ = player.name(forInputBus: 0)
    _ = player.name(forOutputBus: 0)
    player.installTap(onBus: 0, bufferSize: 256, format: nil) { _, _ in }
    player.removeTap(onBus: 0)
    player.prepare(withFrameCount: 128)
    _ = player.nodeTime(forPlayerTime: AVAudioTime(hostTime: 1))
    _ = player.playerTime(forNodeTime: AVAudioTime(sampleTime: 0, atRate: 44100))
    delay.feedback = 20
    delay.lowPassCutoff = 8000
    delay.wetDryMix = 40
    distortion.preGain = -3
    distortion.wetDryMix = 25
    distortion.loadFactoryPreset(.drumsLoFi)
    reverb.wetDryMix = 30
    reverb.loadFactoryPreset(.mediumHall)
    pitch.rate = 1.1
    pitch.pitch = 50
    pitch.overlap = 4
    vari.rate = 0.9
    sampler.masterGain = -3
    sampler.globalTuning = 10
    sampler.stereoPan = 0.1
    sampler.startNote(60, withVelocity: 100, onChannel: 0)
    sampler.stopNote(60, onChannel: 0)
    sampler.sendController(1, withValue: 64, onChannel: 0)
    sampler.sendPitchBend(8192, onChannel: 0)
    sampler.sendPressure(10, onChannel: 0)
    sampler.sendPressure(forKey: 60, withValue: 20, onChannel: 0)
    sampler.sendProgramChange(0, onChannel: 0)
    sampler.sendProgramChange(0, bankMSB: 0, bankLSB: 0, onChannel: 0)
    sampler.sendMIDIEvent(0x90, data1: 60)
    sampler.sendMIDIEvent(0x90, data1: 60, data2: 100)
    sampler.sendMIDISysExEvent(Data([0xf0, 0xf7]))
    try requireThrows("sampler bank") {
        try sampler.loadSoundBankInstrument(
            at: URL(fileURLWithPath: "/tmp/missing.sf2"),
            program: 0,
            bankMSB: 0x79,
            bankLSB: 0
        )
    }
    try requireThrows("sampler instrument") {
        try sampler.loadInstrument(at: URL(fileURLWithPath: "/tmp/missing.aupreset"))
    }
    try requireThrows("sampler files") {
        try sampler.loadAudioFiles(at: [URL(fileURLWithPath: "/tmp/missing.wav")])
    }
    env.outputVolume = 0.8
    env.outputType = .headphones
    env.listenerPosition = AVAudioMake3DPoint(0, 0, 0)
    env.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
    env.listenerVectorOrientation = AVAudioMake3DVectorOrientation(
        AVAudioMake3DVector(0, 0, 1),
        AVAudioMake3DVector(0, 1, 0)
    )
    env.distanceAttenuationParameters.rolloffFactor = 2
    env.reverbParameters.enable = true
    env.reverbParameters.loadFactoryReverbPreset(.plate)
    try require(env.applicableRenderingAlgorithms.isEmpty, "no hardware algorithms")
    engine.disconnectNodeOutput(player)
    engine.disconnectNodeOutput(player, bus: 0)
    engine.disconnectNodeInput(mixer, bus: 0)
    engine.disconnectMIDI(player, from: mixer)
    engine.disconnectMIDI(player, from: [mixer])
    engine.disconnectMIDIInput(mixer)
    engine.disconnectMIDIOutput(player)
    engine.isAutoShutdownEnabled = true
    try require(engine.isAutoShutdownEnabled, "autoshutdown stored")
    engine.detach(env)
    let points = [AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 1)]
    engine.connect(player, to: points, fromBus: 0, format: nil)
    try require(
        engine.inputConnectionPoint(for: engine.mainMixerNode, inputBus: 1)?.node === player,
        "connection points connect"
    )
    let dest = AVAudioMixingDestination(
        connectionPoint: AVAudioConnectionPoint(node: mixer, bus: 0)
    )
    try require(dest.connectionPoint.bus == 0, "mixing dest")
    _ = player.destination(forMixer: mixer, bus: 0)
    let component = AVAudioUnitComponent(name: "test", typeName: AVAudioUnitTypeEffect)
    try require(component.isSandboxSafe, "component sandbox")
    try require(AVAudioUnitComponentManager.shared().tagNames.isEmpty, "no components")
    try require(
        AVAudioUnitComponentManager.shared().components(matching: NSPredicate(value: true)).isEmpty,
        "predicate components"
    )
    _ = AVAudioUnitComponentManager.registrationsChangedNotification
}

func proveDepthSpeechAndMIDI() throws {
    let utterance = AVSpeechUtterance(attributedString: NSAttributedString(string: "depth"))
    utterance.pitchMultiplier = 1.1
    utterance.volume = 0.8
    utterance.preUtteranceDelay = 0.01
    utterance.postUtteranceDelay = 0.02
    utterance.prefersAssistiveTechnologySettings = true
    try require(utterance.attributedSpeechString.string == "depth", "attributed utterance")
    try require(AVSpeechUtterance(ssmlRepresentation: "") == nil, "empty ssml")
    let ssml = AVSpeechUtterance(SSMLRepresentation: "<speak>hi</speak>")
    try require(ssml?.speechString.contains("hi") == true, "ssml")
    let marker = AVSpeechSynthesisMarker(
        wordRange: NSRange(location: 0, length: 1),
        atByteSampleOffset: 0
    )
    _ = AVSpeechSynthesisMarker(
        sentenceRange: NSRange(location: 0, length: 1),
        atByteSampleOffset: 0
    )
    _ = AVSpeechSynthesisMarker(
        paragraphRange: NSRange(location: 0, length: 1),
        atByteSampleOffset: 0
    )
    _ = AVSpeechSynthesisMarker(phonemeString: "AH", atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(bookmarkName: "b", atByteSampleOffset: 0)
    try require(marker.mark == .word, "marker word")
    let synth = AVSpeechSynthesizer()
    synth.usesApplicationAudioSession = false
    synth.mixToTelephonyUplink = false
    try require(!synth.isPaused, "not paused")
    try require(!synth.pauseSpeaking(at: .immediate), "pause fail-closed")
    try require(!synth.continueSpeaking(), "continue fail-closed")
    _ = synth.stopSpeaking(at: .word)
    synth.write(utterance) { _ in }
    synth.write(utterance, toBufferCallback: { _ in }, toMarkerCallback: { _ in })
    _ = AVSpeechSynthesizer.availableVoicesDidChangeNotification
    try require(AVSpeechSynthesisVoice.currentLanguageCode().isEmpty == false, "language code")
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
    try require(request.voice.identifier == "id", "provider request")

    let sequencer = AVAudioSequencer()
    let track = sequencer.createAndAppendTrack()
    track.isLoopingEnabled = true
    track.isMuted = false
    track.numberOfLoops = AVMusicTrackLoopCount.forever.rawValue
    track.loopRange = AVMakeBeatRange(0, 4)
    track.addEvent(AVMIDINoteEvent(channel: 0, key: 64, velocity: 80, duration: 0.5), at: 1)
    track.addEvent(AVMIDIControlChangeEvent(channel: 0, messageType: .volume, value: 100), at: 0)
    track.addEvent(AVMIDIPitchBendEvent(channel: 0, value: 0), at: 0)
    track.addEvent(AVMIDIProgramChangeEvent(channel: 0, programNumber: 1), at: 0)
    track.addEvent(AVMIDIChannelPressureEvent(channel: 0, pressure: 1), at: 0)
    track.addEvent(AVMIDIPolyPressureEvent(channel: 0, key: 60, pressure: 1), at: 0)
    track.addEvent(AVMIDIMetaEvent(type: .tempo, data: Data([1, 2, 3])), at: 0)
    track.addEvent(AVMIDISysexEvent(data: Data([0xf0, 0xf7])), at: 0)
    track.addEvent(AVMusicUserEvent(data: Data([1])), at: 0)
    track.addEvent(AVParameterEvent(parameterID: 1, scope: 0, element: 0, value: 0.5), at: 0)
    track.addEvent(AVExtendedTempoEvent(tempo: 120), at: 0)
    track.addEvent(
        AVExtendedNoteOnEvent(midiNote: 60, velocity: 100, instrumentID: 0, groupID: 0, duration: 1),
        at: 0
    )
    try require(AVExtendedNoteOnEvent.defaultInstrument != 0, "default instrument")
    track.addEvent(AVAUPresetEvent(scope: 0, element: 0, dictionary: [:]), at: 0)
    track.enumerateEvents(in: AVMakeBeatRange(0, 16)) { _, _, stop in
        stop.pointee = true
    }
    track.moveEvents(in: AVMakeBeatRange(0, 1), by: 0.5)
    let other = sequencer.createAndAppendTrack()
    other.copyEvents(in: AVMakeBeatRange(0, 16), from: track, insertAt: 0)
    other.copyAndMergeEvents(in: AVMakeBeatRange(0, 16), from: track, mergeAt: 0)
    track.clearEvents(in: AVMakeBeatRange(0, 16))
    try require(sequencer.removeTrack(other), "remove track")
    sequencer.reverseEvents()
    sequencer.setUserCallback(nil)
    _ = sequencer.beats(forSeconds: 1)
    _ = sequencer.seconds(forBeats: 1)
    _ = AVAudioSequencer.InfoDictionaryKey.album
    _ = AVAudioSequencer.InfoDictionaryKey.title
    try requireThrows("midi player") {
        _ = try AVMIDIPlayer(contentsOf: URL(fileURLWithPath: "/tmp/missing.mid"), soundBankURL: nil)
    }
}

func proveDepthApplicationAnd3D() throws {
    _ = AVAudioApplication.inputMuteStateChangeNotification
    _ = AVAudioApplication.muteStateKey
    _ = AVAudioApplication.MicrophoneInjectionPermission.undetermined
    _ = AVAudioApplication.recordPermission.undetermined
    try require(AVAudioApplication.shared.isInputMuted, "app muted")
    let cookie = Data([1, 2, 3])
    let format = try requireFormat(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
    format.magicCookie = cookie
    try require(format.magicCookie == cookie, "magic cookie")
    let compressed = AVAudioCompressedBuffer(format: format, packetCapacity: 2)
    compressed.packetCount = 1
    compressed.byteLength = 4
    try require(compressed.byteCapacity > 0, "compressed capacity")
    try require(compressed.maximumPacketSize == 0, "compressed max packet")
    _ = AVAudioCompressedBuffer(format: format, packetCapacity: 1, maximumPacketSize: 16)
    let time = AVAudioTime(hostTime: 10, sampleTime: 100, atRate: 44100)
    try require(time.hostTime == 10 && time.sampleTime == 100, "time both")
    try require(AVAudioTime.seconds(forHostTime: AVAudioTime.hostTime(forSeconds: 2)) == 2, "2s")
}

func avfaudioTestAIFF() -> Data {
    var data = Data()
    func appendASCII(_ text: String) { data.append(contentsOf: text.utf8) }
    func appendU16(_ value: UInt16) {
        var big = value.bigEndian
        withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
    }
    func appendU32(_ value: UInt32) {
        var big = value.bigEndian
        withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
    }
    appendASCII("FORM")
    appendU32(4 + 8 + 18 + 8 + 8 + 8)
    appendASCII("AIFF")
    appendASCII("COMM")
    appendU32(18)
    appendU16(1)
    appendU32(4)
    appendU16(16)
    data.append(contentsOf: [0x40, 0x0e, 0xac, 0x44, 0, 0, 0, 0, 0, 0])
    appendASCII("SSND")
    appendU32(16)
    appendU32(0)
    appendU32(0)
    data.append(contentsOf: [0, 0, 0x10, 0, 0x20, 0, 0x30, 0])
    return data
}

func requireFormat(_ format: AVAudioFormat?) throws -> AVAudioFormat {
    guard let format else { throw RuntimeFailure.message("nil format") }
    return format
}

func requireConverter(_ converter: AVAudioConverter?) throws -> AVAudioConverter {
    guard let converter else { throw RuntimeFailure.message("nil converter") }
    return converter
}

func avfaudioTestLinearPCMWAVE(
    frames: Int = 8,
    sampleRate: UInt32 = 44100,
    channels: UInt16 = 2
) -> Data {
    let blockAlign = channels * 2
    let dataBytes = UInt32(frames) * UInt32(blockAlign)
    let byteRate = sampleRate * UInt32(blockAlign)
    var data = Data()
    func appendASCII(_ text: String) {
        data.append(contentsOf: text.utf8)
    }
    func appendU16(_ value: UInt16) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    func appendU32(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    appendASCII("RIFF")
    appendU32(36 + dataBytes)
    appendASCII("WAVE")
    appendASCII("fmt ")
    appendU32(16)
    appendU16(1)
    appendU16(channels)
    appendU32(sampleRate)
    appendU32(byteRate)
    appendU16(blockAlign)
    appendU16(16)
    appendASCII("data")
    appendU32(dataBytes)
    data.append(contentsOf: Array(repeating: 0, count: Int(dataBytes)))
    return data
}

func provePlayerFixtures() throws {
    try requireThrows("missing URL must throw") {
        _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/no/such/avfaudio-player.wav"))
    }

    let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    try requireThrows("unreadable directory URL must throw") {
        _ = try AVAudioPlayer(contentsOf: directory)
    }

    try requireThrows("empty data must throw") {
        _ = try AVAudioPlayer(data: Data())
    }

    try requireThrows("garbage data must throw") {
        _ = try AVAudioPlayer(data: Data([0, 1, 2, 3, 4, 5, 6, 7]))
    }

    let wave = avfaudioTestLinearPCMWAVE()
    let fromData = try AVAudioPlayer(data: wave)
    try require(fromData.format.sampleRate == 44100, "wave sample rate")
    try require(fromData.format.channelCount == 2, "wave channels")
    try require(abs(fromData.duration - (8.0 / 44100.0)) < 0.000_000_1, "wave duration")
    try require(fromData.prepareToPlay() == false, "player prepare fail-closed")
    try require(fromData.play() == false, "player hardware fail-closed")
    try require(!fromData.isPlaying, "player not playing")
    fromData.volume = 0.5
    try require(fromData.volume == 0.5, "player volume stored")

    let hinted = try AVAudioPlayer(data: wave, fileTypeHint: "public.wav")
    try require(hinted.duration == fromData.duration, "hinted wave duration")

    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(
        "avfaudio-valid-\(UUID().uuidString).wav"
    )
    defer { try? FileManager.default.removeItem(at: tmp) }
    try wave.write(to: tmp)
    let fromURL = try AVAudioPlayer(contentsOf: tmp)
    try require(fromURL.url == tmp, "wave url retained")
    try require(fromURL.play() == false, "url player hardware fail-closed")
    let hintedURL = try AVAudioPlayer(contentsOf: tmp, fileTypeHint: "public.wav")
    try require(hintedURL.format.channelCount == 2, "hinted url channels")
}

func proveEngineConnectReplacement(format: AVAudioFormat) throws {
    let engine = AVAudioEngine()
    let sourceA = AVAudioPlayerNode()
    let sourceB = AVAudioPlayerNode()
    let destination = AVAudioMixerNode()
    let unrelated = AVAudioMixerNode()
    engine.attach(sourceA)
    engine.attach(sourceB)
    engine.attach(destination)
    engine.attach(unrelated)

    engine.connect(sourceA, to: destination, fromBus: 0, toBus: 0, format: format)
    engine.connect(sourceB, to: destination, fromBus: 0, toBus: 0, format: format)
    try require(
        engine.inputConnectionPoint(for: destination, inputBus: 0)?.node === sourceB,
        "competing source replaced destination bus"
    )
    try require(
        engine.outputConnectionPoints(for: sourceA, outputBus: 0).isEmpty,
        "replaced source lost destination bus 0"
    )
    try require(
        engine.outputConnectionPoints(for: sourceB, outputBus: 0).contains(where: {
            $0.node === destination && $0.bus == 0
        }),
        "winner remains on destination bus 0"
    )

    engine.connect(sourceA, to: unrelated, fromBus: 0, toBus: 0, format: format)
    try require(
        engine.inputConnectionPoint(for: destination, inputBus: 0)?.node === sourceB,
        "unrelated same-numbered bus must not steal destination input"
    )
    try require(
        engine.inputConnectionPoint(for: unrelated, inputBus: 0)?.node === sourceA,
        "unrelated destination bus 0 stored"
    )

    engine.connect(sourceA, to: destination, fromBus: 0, toBus: 1, format: format)
    try require(
        engine.inputConnectionPoint(for: destination, inputBus: 0)?.node === sourceB,
        "bus 1 connect must not replace bus 0"
    )
    try require(
        engine.inputConnectionPoint(for: destination, inputBus: 1)?.node === sourceA,
        "destination bus 1 stored independently"
    )
}

func proveExtrapolateTime() throws {
    let rate: Double = 44100
    let after = AVAudioTime(hostTime: 1_000_000_000, sampleTime: 88200, atRate: rate)
    let anchor = AVAudioTime(hostTime: 1_000_000_000, sampleTime: 44100, atRate: rate)
    let afterResult = after.extrapolateTime(fromAnchor: anchor)
    try require(afterResult?.isHostTimeValid == true, "after-anchor host valid")
    try require(afterResult?.hostTime == 2_000_000_000, "after-anchor host ticks")
    try require(afterResult?.sampleTime == 88200, "after-anchor sample")

    let before = AVAudioTime(hostTime: 9, sampleTime: 0, atRate: rate)
    let beforeResult = before.extrapolateTime(fromAnchor: anchor)
    try require(beforeResult?.isHostTimeValid == true, "before-anchor host valid")
    try require(beforeResult?.hostTime == 0, "before-anchor host ticks")
    try require(beforeResult?.sampleTime == 0, "before-anchor sample")

    let same = AVAudioTime(hostTime: 5, sampleTime: 44100, atRate: rate)
    let sameResult = same.extrapolateTime(fromAnchor: anchor)
    try require(sameResult?.hostTime == 1_000_000_000, "equal-delta host unchanged")

    let overflowAnchor = AVAudioTime(hostTime: UInt64.max - 5, sampleTime: 0, atRate: 1)
    let overflowSample = AVAudioTime(hostTime: 0, sampleTime: 1, atRate: 1)
    try require(
        overflowSample.extrapolateTime(fromAnchor: overflowAnchor) == nil,
        "overflow returns nil"
    )

    let underflowAnchor = AVAudioTime(hostTime: 5, sampleTime: 1, atRate: 1)
    let underflowSample = AVAudioTime(hostTime: 0, sampleTime: 0, atRate: 1)
    try require(
        underflowSample.extrapolateTime(fromAnchor: underflowAnchor) == nil,
        "underflow returns nil"
    )
}

final class SignalSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {}

func proveCorpusCompileSurfaces() throws {
    let utterance = AVSpeechUtterance(string: "signal corpus")
    let synthesizer = AVSpeechSynthesizer()
    let delegate = SignalSpeechDelegate()
    synthesizer.delegate = delegate
    synthesizer.speak(utterance)
    try require(!synthesizer.isSpeaking, "signal speak fail-closed")
    try require(utterance.speechString == "signal corpus", "signal utterance")

    let session = AVAudioSession.sharedInstance()
    _ = session.outputVolume
    try require(session.outputVolume == 0, "telegram outputVolume")

    try require(
        AVAudioApplication.shared.recordPermission == .denied,
        "nextcloud application permission"
    )
}

func proveGraphSendable() throws {
    let format = try requireFormat(
        AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    )
    let send: @Sendable () -> Double = { format.sampleRate }
    try require(send() == 44100, "graph Sendable AVAudioFormat")
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
