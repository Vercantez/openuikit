import Foundation
import RoomPlan

final class RoomPlanEndRecorder: RoomCaptureSessionDelegate {
    var ended: (CapturedRoomData, (any Error)?)?
    var started = false

    func captureSession(
        _ session: RoomCaptureSession,
        didStartWith configuration: RoomCaptureSession.Configuration
    ) {
        started = true
        _ = session
        _ = configuration
    }

    func captureSession(
        _ session: RoomCaptureSession,
        didEndWith data: CapturedRoomData,
        error: (any Error)?
    ) {
        ended = (data, error)
        _ = session
    }
}

func testRoomCaptureSessionIsSupported() {
    precondition(RoomCaptureSession.isSupported == false)
}

func testRoomCaptureSessionInit() {
    let session = RoomCaptureSession()
    precondition(session.delegate == nil)
    _ = session.arSession
}

func testRoomCaptureSessionRunDeviceNotSupported() {
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.run(configuration: RoomCaptureSession.Configuration())
    precondition(recorder.started == false)
    guard let ended = recorder.ended else {
        preconditionFailure("didEndWith must fire")
    }
    guard let error = ended.1 as? RoomCaptureSession.CaptureError else {
        preconditionFailure("expected CaptureError")
    }
    precondition(error == .deviceNotSupported)
}

func testRoomCaptureSessionRunAfterReplacingARSession() {
    let session = RoomCaptureSession()
    session.arSession = ARSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.run(configuration: RoomCaptureSession.Configuration())
    guard let error = recorder.ended?.1 as? RoomCaptureSession.CaptureError else {
        preconditionFailure("expected CaptureError")
    }
    precondition(error == .invalidARConfiguration)
}

func testRoomCaptureSessionStopIsNoOp() {
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.stop()
    precondition(recorder.ended == nil)
}

func testRoomCaptureSessionStopPauseARSession() {
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.stop(pauseARSession: false)
    session.stop(pauseARSession: true)
    precondition(recorder.ended == nil)
}

func testRoomCaptureSessionConfigurationDefault() {
    let configuration = RoomCaptureSession.Configuration()
    precondition(configuration.isCoachingEnabled == true)
}

func testRoomCaptureSessionConfigurationCoaching() {
    var configuration = RoomCaptureSession.Configuration()
    configuration.isCoachingEnabled = false
    precondition(configuration.isCoachingEnabled == false)
    configuration.isCoachingEnabled = true
    precondition(configuration.isCoachingEnabled == true)
}

func testRoomCaptureSessionDelegateAssignment() {
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    precondition(session.delegate === recorder)
    session.delegate = nil
    precondition(session.delegate == nil)
}

func testRoomCaptureSessionInitWithARSession() {
    let arSession = ARSession()
    let session = RoomCaptureSession(arSession: arSession)
    precondition(session.arSession === arSession)
    let without = RoomCaptureSession(arSession: nil)
    _ = without.arSession
}
