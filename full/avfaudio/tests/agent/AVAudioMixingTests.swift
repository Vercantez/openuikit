import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioMixingPanGain() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
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
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 64)
        try engine.start()
    } catch {
        preconditionFailure("mix engine: \(error)")
    }
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        preconditionFailure("mix source")
    }
    source.frameLength = 8
    source.floatChannelData?[0][0] = 1
    source.floatChannelData?[1][0] = 1
    player.scheduleBuffer(source, completionHandler: {})
    player.play()
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        preconditionFailure("mix dest")
    }
    do {
        let status = try engine.renderOffline(8, to: rendered)
        precondition(status == .success)
    } catch {
        preconditionFailure("mix render: \(error)")
    }
    precondition(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.5) < 0.000_1)
    precondition(abs(rendered.floatChannelData?[1][0] ?? 1) < 0.000_1)
    engine.stop()
    engine.disableManualRenderingMode()
    let dest = AVAudioMixingDestination(
        connectionPoint: AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 0)
    )
    precondition(dest.connectionPoint.bus == 0)
    _ = player.destination(forMixer: engine.mainMixerNode, bus: 0)
}

