import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioApplicationFailClosed() {
    precondition(AVAudioApplication.shared.recordPermission == .denied)
    precondition(AVAudioApplication.shared.microphoneInjectionPermission == .serviceDisabled)
    precondition(AVAudioApplication.shared.isInputMuted)
    do {
        try AVAudioApplication.shared.setInputMuted(true)
        preconditionFailure("setInputMuted")
    } catch {}
    _ = AVAudioApplication.inputMuteStateChangeNotification
    _ = AVAudioApplication.muteStateKey
    var count = 0
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVAudioApplication.requestRecordPermission { _ in
            count += 1
            sem.signal()
        }
    }
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(count == 1)
}

