import Foundation
import RoomPlan

final class RoomPlanMinimalSessionDelegate: RoomCaptureSessionDelegate {}

final class RoomPlanMinimalViewDelegate: NSObject, RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        _ = coder
    }

    required init?(coder: NSCoder) {
        _ = coder
        super.init()
    }

    override init() {
        super.init()
    }
}

func testSessionDelegateDefaults() {
    let delegate = RoomPlanMinimalSessionDelegate()
    let session = RoomCaptureSession()
    let room = CapturedRoom()
    delegate.captureSession(session, didUpdate: room)
    delegate.captureSession(session, didAdd: room)
    delegate.captureSession(session, didChange: room)
    delegate.captureSession(session, didRemove: room)
    delegate.captureSession(session, didProvide: .normal)
    delegate.captureSession(session, didStartWith: RoomCaptureSession.Configuration())
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.run(configuration: RoomCaptureSession.Configuration())
    if let ended = recorder.ended {
        delegate.captureSession(session, didEndWith: ended.0, error: ended.1)
    }
}

func testViewDelegateDefaults() {
    let delegate = RoomPlanMinimalViewDelegate()
    let room = CapturedRoom()
    delegate.captureView(didPresent: room, error: nil)
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.run(configuration: RoomCaptureSession.Configuration())
    let data = recorder.ended!.0
    let should = delegate.captureView(shouldPresent: data, error: nil)
    precondition(should == true)
}

func testViewDelegateShouldPresentDefault() {
    let delegate = RoomPlanMinimalViewDelegate()
    let session = RoomCaptureSession()
    let recorder = RoomPlanEndRecorder()
    session.delegate = recorder
    session.run(configuration: RoomCaptureSession.Configuration())
    let should = delegate.captureView(
        shouldPresent: recorder.ended!.0,
        error: RoomCaptureSession.CaptureError.deviceNotSupported
    )
    precondition(should)
}

func testViewDelegateNSCoding() {
    let stub = RoomPlanViewDelegateStub()
    let coder = NSKeyedArchiver(requiringSecureCoding: false)
    stub.encode(with: coder)
    let restored = RoomPlanViewDelegateStub(coder: coder)
    precondition(restored == nil)
}
