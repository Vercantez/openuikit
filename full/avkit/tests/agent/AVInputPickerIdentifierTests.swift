import Foundation
import AVKit

private final class InputPickerMethodProbe: NSObject, AVInputPickerInteraction.Delegate {
    var events: [String] = []

    func inputPickerInteractionWillBeginPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("willPresent")
    }

    func inputPickerInteractionDidEndPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("didPresent")
    }

    func inputPickerInteractionWillBeginDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("willDismiss")
    }

    func inputPickerInteractionDidEndDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
        events.append("didDismiss")
    }
}

func testInputPickerInteractionClassConstructs() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        _ = picker
        precondition(picker.isPresented == false)
    }
}

func testInputPickerInteractionDismissKeepsClosed() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        picker.dismiss()
        precondition(picker.isPresented == false)
    }
}

func testInputPickerInteractionInit() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        precondition(picker.isPresented == false)
        _ = picker.audioSession
    }
}

func testInputPickerInteractionInitAudioSession() {
    avkitOnMain {
        let session = AVAudioSession()
        let picker = AVInputPickerInteraction(audioSession: session)
        precondition(picker.audioSession === session)
        let fallback = AVInputPickerInteraction(audioSession: nil)
        _ = fallback.audioSession
    }
}

func testInputPickerInteractionPresentKeepsClosed() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        picker.present()
        precondition(picker.isPresented == false)
    }
}

func testInputPickerInteractionAudioSession() {
    avkitOnMain {
        let session = AVAudioSession()
        let picker = AVInputPickerInteraction()
        picker.audioSession = session
        precondition(picker.audioSession === session)
    }
}

func testInputPickerInteractionDelegateStorage() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        precondition(picker.delegate === probe)
        picker.delegate = nil
        precondition(picker.delegate == nil)
    }
}

func testInputPickerInteractionIsPresented() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        precondition(picker.isPresented == false)
        picker.present()
        precondition(picker.isPresented == false)
        picker.dismiss()
        precondition(picker.isPresented == false)
    }
}

func testInputPickerInteractionDelegateProtocolConformance() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        let typed: (any AVInputPickerInteraction.Delegate)? = picker.delegate
        precondition(typed === probe)
    }
}

func testInputPickerInteractionDidEndDismissing() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        picker.present()
        picker.dismiss()
        precondition(probe.events.contains("didDismiss"))
    }
}

func testInputPickerInteractionDidEndPresenting() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        picker.present()
        precondition(probe.events.contains("didPresent"))
    }
}

func testInputPickerInteractionWillBeginDismissing() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        picker.present()
        picker.dismiss()
        precondition(probe.events.contains("willDismiss"))
    }
}

func testInputPickerInteractionWillBeginPresenting() {
    avkitOnMain {
        let picker = AVInputPickerInteraction()
        let probe = InputPickerMethodProbe()
        picker.delegate = probe
        picker.present()
        precondition(probe.events.first == "willPresent")
    }
}
