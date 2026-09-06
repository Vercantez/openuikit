import Foundation
import RoomPlan

final class RoomPlanViewDelegateStub: NSObject, RoomCaptureViewDelegate {
    var presented: (CapturedRoom, (any Error)?)?
    var shouldPresentValue = true

    func encode(with coder: NSCoder) {
        _ = coder
    }

    required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    override init() {
        super.init()
    }

    func captureView(didPresent processedResult: CapturedRoom, error: (any Error)?) {
        presented = (processedResult, error)
    }

    func captureView(
        shouldPresent roomDataForProcessing: CapturedRoomData,
        error: (any Error)?
    ) -> Bool {
        _ = roomDataForProcessing
        _ = error
        return shouldPresentValue
    }
}

func testRoomCaptureViewInitFrame() {
    let view = RoomCaptureView(frame: CGRect(x: 1, y: 2, width: 320, height: 480))
    precondition(view.frame.width == 320)
    precondition(view.frame.height == 480)
    precondition(view.captureSession != nil)
    precondition(view.isModelEnabled == false)
}

func testRoomCaptureViewInitFrameARSession() {
    let arSession = ARSession()
    let view = RoomCaptureView(frame: .zero, arSession: arSession)
    precondition(view.captureSession.arSession === arSession)
}

func testRoomCaptureViewCoderFailClosed() {
    let coder = NSKeyedArchiver(requiringSecureCoding: false)
    let view = RoomCaptureView(coder: coder)
    precondition(view == nil)
}

func testRoomCaptureViewEncode() {
    let view = RoomCaptureView(frame: .zero)
    let coder = NSKeyedArchiver(requiringSecureCoding: false)
    view.encode(with: coder)
}

func testRoomCaptureViewLayoutSubviews() {
    let view = RoomCaptureView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    view.layoutSubviews()
}

func testRoomCaptureViewTraitCollectionDidChange() {
    let view = RoomCaptureView(frame: .zero)
    view.traitCollectionDidChange(nil)
    view.traitCollectionDidChange(NSObject())
}

func testRoomCaptureViewSubviewsEmpty() {
    let view = RoomCaptureView(frame: .zero)
    precondition(view.subviews.isEmpty)
}

func testRoomCaptureViewIsModelEnabled() {
    let view = RoomCaptureView(frame: .zero)
    view.isModelEnabled = true
    precondition(view.isModelEnabled)
    view.isModelEnabled = false
    precondition(!view.isModelEnabled)
}

func testRoomCaptureViewCaptureSession() {
    let view = RoomCaptureView(frame: .zero)
    let replacement = RoomCaptureSession()
    view.captureSession = replacement
    precondition(view.captureSession === replacement)
}

func testRoomCaptureViewDelegate() {
    let view = RoomCaptureView(frame: .zero)
    let stub = RoomPlanViewDelegateStub()
    view.delegate = stub
    precondition(view.delegate === stub)
    view.delegate = nil
    precondition(view.delegate == nil)
}
