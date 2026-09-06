import Foundation
import DockKit

func testMotionStateProperties() {
    let positions = Vector3D(x: 0.1, y: 0.2, z: 0.3)
    let velocities = Vector3D(x: 1, y: 0, z: -1)
    let state = DockAccessory.MotionState(
        angularPositions: positions,
        angularVelocities: velocities,
        error: nil,
        timestamp: 12.5
    )
    precondition(state.angularPositions == positions)
    precondition(state.angularVelocities == velocities)
    precondition(state.error == nil)
    precondition(state.timestamp == 12.5)
}

func testMotionStateWithError() {
    let state = DockAccessory.MotionState(
        angularPositions: Vector3D(),
        angularVelocities: Vector3D(),
        error: DockKitError.notConnected,
        timestamp: 0
    )
    precondition((state.error as? DockKitError) == .notConnected)
}
