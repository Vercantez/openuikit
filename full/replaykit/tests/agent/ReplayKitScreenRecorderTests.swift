import Foundation
import ReplayKit

private final class RKRecorderAvailabilityProbe: NSObject, RPScreenRecorderDelegate {
    var changes = 0

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
        changes += 1
    }
}

func testRPScreenRecorderSharedState() {
    let first = RPScreenRecorder.shared()
    let second = RPScreenRecorder.shared()
    precondition(first === second)
    precondition(!first.isAvailable)
    precondition(!first.isRecording)
    precondition(!first.isCameraEnabled)
    precondition(!first.isMicrophoneEnabled)
    precondition(first.cameraPosition == .front)

    first.isCameraEnabled = true
    first.isMicrophoneEnabled = true
    first.cameraPosition = .back
    precondition(first.isCameraEnabled)
    precondition(first.isMicrophoneEnabled)
    precondition(first.cameraPosition == .back)
    precondition(!first.isAvailable)
    precondition(!first.isRecording)

    first.isCameraEnabled = false
    first.isMicrophoneEnabled = false
    first.cameraPosition = .front
    precondition(!first.isCameraEnabled)
    precondition(!first.isMicrophoneEnabled)
    precondition(first.cameraPosition == .front)

    let probe = RKRecorderAvailabilityProbe()
    first.delegate = probe
    precondition(first.delegate === probe)
    precondition(probe.changes == 0)
    first.delegate = nil
    precondition(first.delegate == nil)
}

func testRPScreenRecorderFailClosedActions() {
    let recorder = RPScreenRecorder.shared()
    precondition(!recorder.isAvailable)
    precondition(!recorder.isRecording)

    recorder.startRecording(handler: { _ in })
    precondition(!recorder.isRecording)

    recorder.startRecording(withMicrophoneEnabled: true, handler: { _ in })
    precondition(recorder.isMicrophoneEnabled)
    precondition(!recorder.isRecording)
    recorder.isMicrophoneEnabled = false

    recorder.startRecording(withMicrophoneEnabled: false, handler: nil)
    precondition(!recorder.isMicrophoneEnabled)
    precondition(!recorder.isRecording)

    recorder.startClipBuffering(completionHandler: { _ in })
    recorder.startClipBuffering(completionHandler: nil)
    recorder.stopClipBuffering(completionHandler: { _ in })
    recorder.stopClipBuffering(completionHandler: nil)
    recorder.stopCapture(handler: { _ in })
    recorder.stopCapture(handler: nil)
    precondition(!recorder.isRecording)

    recorder.discardRecording(handler: {})
    precondition(!recorder.isRecording)

    recorder.stopRecording(
        withOutput: URL(fileURLWithPath: "/tmp/replaykit-out.mp4"),
        completionHandler: { _ in }
    )
    precondition(!recorder.isRecording)

    recorder.exportClip(
        to: URL(fileURLWithPath: "/tmp/replaykit-clip.mp4"),
        duration: 5,
        completionHandler: { _ in }
    )
    precondition(!recorder.isRecording)
    precondition(!recorder.isAvailable)
}

func testRPScreenRecorderDelegate() {
    let recorder = RPScreenRecorder.shared()
    let probe = RKRecorderAvailabilityProbe()
    let existential: any RPScreenRecorderDelegate = probe
    existential.screenRecorderDidChangeAvailability(recorder)
    precondition(probe.changes == 1)
    probe.screenRecorderDidChangeAvailability(recorder)
    precondition(probe.changes == 2)
}
