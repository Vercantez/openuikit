import Foundation
import DockKit

func testObservationInit() {
    let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let yaw = Measurement(value: -15, unit: UnitAngle.degrees)
    let observation = DockAccessory.Observation(
        identifier: 42,
        type: .humanFace,
        rect: rect,
        faceYawAngle: yaw
    )
    precondition(observation.identifier == 42)
    precondition(observation.type == .humanFace)
    precondition(observation.rect.origin.x == 0.1)
    precondition(observation.rect.origin.y == 0.2)
    precondition(observation.rect.size.width == 0.3)
    precondition(observation.rect.size.height == 0.4)
    precondition(observation.faceYawAngle?.value == -15)
}

func testObservationDefaultFaceYawAngle() {
    let observation = DockAccessory.Observation(
        identifier: 1,
        type: .object,
        rect: .zero
    )
    precondition(observation.faceYawAngle == nil)
    precondition(observation.type == .object)
    precondition(observation.identifier == 1)
}
