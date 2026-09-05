import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioEngineManualRendering() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    precondition(engine.attachedNodes.contains(player))
    precondition(
        engine.outputConnectionPoints(for: player, outputBus: 0).contains(where: {
            $0.node === engine.mainMixerNode
        })
    )
    precondition(!engine.isRunning)
    do {
        try engine.start()
        preconditionFailure("hardware start must throw")
    } catch {}
    precondition(!engine.isRunning)
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
    } catch {
        preconditionFailure("enable manual: \(error)")
    }
    precondition(engine.isInManualRenderingMode)
    precondition(engine.manualRenderingMode == .offline)
    precondition(engine.manualRenderingMaximumFrameCount == 512)
    precondition(engine.manualRenderingFormat.sampleRate == format.sampleRate)
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
        preconditionFailure("second enable must throw")
    } catch {}
    do { try engine.start() } catch { preconditionFailure("manual start: \(error)") }
    precondition(engine.isRunning)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        preconditionFailure("schedule buffer")
    }
    buffer.frameLength = 256
    buffer.floatChannelData?[0][0] = 0.75
    buffer.floatChannelData?[1][0] = -0.25
    player.scheduleBuffer(buffer, completionHandler: {})
    player.volume = 1
    player.pan = 0
    player.play()
    precondition(player.isPlaying)
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        preconditionFailure("render buffer")
    }
    do {
        let status = try engine.renderOffline(256, to: rendered)
        precondition(status == .success)
    } catch {
        preconditionFailure("render: \(error)")
    }
    precondition(rendered.frameLength == 256)
    precondition(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.75) < 0.000_1)
    precondition(abs((rendered.floatChannelData?[1][0] ?? 0) + 0.25) < 0.000_1)
    precondition(engine.manualRenderingSampleTime == 256)
    engine.pause()
    engine.stop()
    precondition(!engine.isRunning)
    engine.disableManualRenderingMode()
    precondition(!engine.isInManualRenderingMode)
    engine.prepare()
    engine.reset()
    _ = engine.inputNode
    _ = engine.outputNode
    engine.isAutoShutdownEnabled = true
    precondition(engine.isAutoShutdownEnabled)
}

func testAVAudioEngineGraphConnections() {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
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
    precondition(engine.inputConnectionPoint(for: destination, inputBus: 0)?.node === sourceB)
    precondition(engine.outputConnectionPoints(for: sourceA, outputBus: 0).isEmpty)
    engine.connect(sourceA, to: unrelated, fromBus: 0, toBus: 0, format: format)
    engine.connect(sourceA, to: destination, fromBus: 0, toBus: 1, format: format)
    precondition(engine.inputConnectionPoint(for: destination, inputBus: 1)?.node === sourceA)
    engine.disconnectNodeOutput(sourceA)
    engine.disconnectNodeOutput(sourceB, bus: 0)
    engine.disconnectNodeInput(destination, bus: 0)
    engine.disconnectNodeInput(unrelated)
    engine.disconnectMIDI(sourceA, from: destination)
    engine.disconnectMIDI(sourceA, from: [destination])
    engine.disconnectMIDIInput(destination)
    engine.disconnectMIDIOutput(sourceA)
    engine.detach(unrelated)
    let points = [AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 1)]
    engine.connect(sourceA, to: points, fromBus: 0, format: nil)
    _ = destination.nextAvailableInputBus
    destination.outputVolume = 0.5
    sourceA.prepare(withFrameCount: 128)
    _ = sourceA.nodeTime(forPlayerTime: AVAudioTime(hostTime: 1))
    _ = sourceA.playerTime(forNodeTime: AVAudioTime(sampleTime: 0, atRate: 44100))
    sourceA.installTap(onBus: 0, bufferSize: 256, format: nil) { _, _ in }
    sourceA.removeTap(onBus: 0)
    _ = sourceA.numberOfInputs
    _ = sourceA.numberOfOutputs
    _ = sourceA.latency
    _ = sourceA.outputPresentationLatency
    _ = sourceA.name(forInputBus: 0)
    _ = sourceA.name(forOutputBus: 0)
    _ = sourceA.inputFormat(forBus: 0)
    _ = sourceA.outputFormat(forBus: 0)
    _ = sourceA.engine
    sourceA.reset()
}

