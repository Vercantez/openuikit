import Foundation
import AVKit

func testCaptureEventClassConstructs() {
    let event = AVCaptureEvent()
    _ = event
    precondition(event.phase == .ended)
}

func testCaptureEventPlaySoundFailsClosed() {
    let event = AVCaptureEvent()
    precondition(event.play(.cameraShutter) == false)
    precondition(event.play(.beginVideoRecording) == false)
    precondition(event.play(.endVideoRecording) == false)
}

func testCaptureEventPhase() {
    let ended = AVCaptureEvent()
    precondition(ended.phase == .ended)
    let began = AVCaptureEvent(openUIKitHostPhase: .began, shouldPlaySound: false)
    precondition(began.phase == .began)
    let cancelled = AVCaptureEvent(openUIKitHostPhase: .cancelled, shouldPlaySound: false)
    precondition(cancelled.phase == .cancelled)
}

func testCaptureEventShouldPlaySound() {
    let silent = AVCaptureEvent()
    precondition(silent.shouldPlaySound == false)
    let sounding = AVCaptureEvent(openUIKitHostPhase: .ended, shouldPlaySound: true)
    precondition(sounding.shouldPlaySound == true)
}

func testCaptureEventInteractionClassConstructs() {
    avkitOnMain {
        let interaction = AVCaptureEventInteraction { _ in }
        _ = interaction
        precondition(interaction.isEnabled == true)
    }
}

func testCaptureEventInteractionDefaultCaptureSoundDisabled() {
    avkitOnMain {
        let previous = AVCaptureEventInteraction.defaultCaptureSoundDisabled
        AVCaptureEventInteraction.defaultCaptureSoundDisabled = true
        precondition(AVCaptureEventInteraction.defaultCaptureSoundDisabled == true)
        AVCaptureEventInteraction.defaultCaptureSoundDisabled = false
        precondition(AVCaptureEventInteraction.defaultCaptureSoundDisabled == false)
        AVCaptureEventInteraction.defaultCaptureSoundDisabled = previous
    }
}

func testCaptureEventInteractionInitHandler() {
    avkitOnMain {
        var count = 0
        let interaction = AVCaptureEventInteraction { _ in count += 1 }
        let event = AVCaptureEvent(openUIKitHostPhase: .ended, shouldPlaySound: false)
        interaction.openUIKitHostDeliver(event)
        precondition(count == 1)
    }
}

func testCaptureEventInteractionInitEventHandler() {
    avkitOnMain {
        var count = 0
        let interaction = AVCaptureEventInteraction(eventHandler: { _ in count += 1 })
        interaction.openUIKitHostDeliver(AVCaptureEvent())
        precondition(count == 1)
    }
}

func testCaptureEventInteractionInitPrimarySecondary() {
    avkitOnMain {
        var primary = 0
        var secondary = 0
        let interaction = AVCaptureEventInteraction(
            primary: { _ in primary += 1 },
            secondary: { _ in secondary += 1 }
        )
        interaction.openUIKitHostDeliver(AVCaptureEvent())
        interaction.openUIKitHostDeliver(AVCaptureEvent(), secondary: true)
        precondition(primary == 1)
        precondition(secondary == 1)
    }
}

func testCaptureEventInteractionInitPrimaryEventHandlerSecondaryEventHandler() {
    avkitOnMain {
        var primary = 0
        var secondary = 0
        let interaction = AVCaptureEventInteraction(
            primaryEventHandler: { _ in primary += 1 },
            secondaryEventHandler: { _ in secondary += 1 }
        )
        interaction.openUIKitHostDeliver(AVCaptureEvent())
        interaction.openUIKitHostDeliver(AVCaptureEvent(), secondary: true)
        precondition(primary == 1)
        precondition(secondary == 1)
    }
}

func testCaptureEventInteractionIsEnabled() {
    avkitOnMain {
        let interaction = AVCaptureEventInteraction { _ in }
        precondition(interaction.isEnabled == true)
        interaction.isEnabled = false
        precondition(interaction.isEnabled == false)
    }
}

func testCaptureEventSoundClassConstructs() {
    let sound = AVCaptureEventSound()
    _ = sound
}

func testCaptureEventSoundBeginVideoRecording() {
    let sound = AVCaptureEventSound.beginVideoRecording
    _ = sound
    precondition(AVCaptureEvent().play(sound) == false)
}

func testCaptureEventSoundCameraShutter() {
    let sound = AVCaptureEventSound.cameraShutter
    _ = sound
    precondition(AVCaptureEvent().play(sound) == false)
}

func testCaptureEventSoundEndVideoRecording() {
    let sound = AVCaptureEventSound.endVideoRecording
    _ = sound
    precondition(AVCaptureEvent().play(sound) == false)
}

func testCaptureEventSoundInitURLThrows() {
    do {
        _ = try AVCaptureEventSound(url: URL(fileURLWithPath: "/tmp/shutter.caf"))
        preconditionFailure("custom capture sound must fail closed")
    } catch let error as AVKitError {
        precondition(error.code == .unknown)
    } catch {
        let nsError = error as NSError
        precondition(nsError.domain == AVKitErrorDomain)
        precondition(nsError.code == AVKitError.Code.unknown.rawValue)
    }
}

func testCaptureEventSoundInitURLLabelThrows() {
    do {
        _ = try AVCaptureEventSound(URL: URL(fileURLWithPath: "/tmp/shutter.caf"))
        preconditionFailure("custom capture sound must fail closed")
    } catch let error as AVKitError {
        precondition(error.code == .unknown)
    } catch {
        let nsError = error as NSError
        precondition(nsError.domain == AVKitErrorDomain)
        precondition(nsError.code == AVKitError.Code.unknown.rawValue)
    }
}
