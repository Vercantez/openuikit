import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVFAudioHostAvailability() {
    precondition(!AVFAudioHostAvailability.audioOutputAvailable)
    precondition(!AVFAudioHostAvailability.audioInputAvailable)
    precondition(!AVFAudioHostAvailability.appleSpeechVoicesAvailable)
    _ = AVFAudioHostAvailability.callbackQueue
}
