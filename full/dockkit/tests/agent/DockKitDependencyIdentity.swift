import Foundation
import DockKit

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public DockKit APIs.
func dockKitDependencyIdentityProbe() {
    let uuid = UUID()
    let identifier = DockAccessory.Identifier(
        name: "stand",
        uuid: uuid,
        category: .trackingStand
    )
    precondition(identifier.uuid == uuid)

    let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let yaw = Measurement(value: 12.5, unit: UnitAngle.degrees)
    let observation = DockAccessory.Observation(
        identifier: 7,
        type: .humanFace,
        rect: rect,
        faceYawAngle: yaw
    )
    precondition(observation.rect.width == rect.width)
    precondition(observation.faceYawAngle?.value == 12.5)
    precondition(observation.faceYawAngle?.unit == UnitAngle.degrees)

    let accessory = DockAccessory(identifier: identifier)
    do {
        _ = try accessory.setLimits(
            DockAccessory.Limits(yaw: nil, pitch: nil, roll: nil)
        )
        preconditionFailure("setLimits must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
        let ns = error as NSError
        precondition(!ns.localizedDescription.isEmpty)
    } catch {
        preconditionFailure("expected DockKitError")
    }

    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let state = DockAccessory.TrackingState(trackedSubjects: [], time: date)
    precondition(state.time == date)
}
