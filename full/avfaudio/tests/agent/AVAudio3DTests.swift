import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudio3DHelpers() {
    let point = AVAudioMake3DPoint(1, 2, 3)
    precondition(point.x == 1 && point.y == 2 && point.z == 3)
    let orientation = AVAudioMake3DAngularOrientation(0.1, 0.2, 0.3)
    precondition(orientation.pitch == 0.2)
    let vector = AVAudioMake3DVectorOrientation(
        AVAudioMake3DVector(0, 0, 1),
        AVAudioMake3DVector(0, 1, 0)
    )
    precondition(vector.up.y == 1)
    let env = AVAudioEnvironmentNode()
    env.outputVolume = 0.8
    env.outputType = .headphones
    env.listenerPosition = AVAudioMake3DPoint(0, 0, 0)
    env.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
    env.listenerVectorOrientation = vector
    env.distanceAttenuationParameters.rolloffFactor = 2
    env.reverbParameters.enable = true
    env.reverbParameters.loadFactoryReverbPreset(.plate)
    precondition(env.applicableRenderingAlgorithms.isEmpty)
}

