import Foundation
import Dispatch
import GameController

func testSimulatedMotion() {
    GCSimulatedInput.reset()
    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    GCSimulatedInput.applyMotion(
        simulated,
        attitude: GCQuaternion(x: 0, y: 0, z: 0, w: 1),
        rotationRate: GCRotationRate(x: 0.1, y: 0.2, z: 0.3),
        gravity: GCAcceleration(x: 0, y: -1, z: 0),
        userAcceleration: GCAcceleration(x: 0.01, y: 0, z: 0)
    )
    precondition(simulated.motion?.hasAttitude == true)
    precondition(simulated.motion?.hasRotationRate == true)
    precondition(simulated.motion?.hasGravityAndUserAcceleration == true)
    precondition(simulated.motion?.hasAttitudeAndRotationRate == true)
    precondition(abs((simulated.motion?.gravity.y ?? 0) + 1) < 0.0001)
    simulated.motion?.setAcceleration(GCAcceleration(x: 1, y: 2, z: 3))
    simulated.motion?.setAttitude(GCQuaternion(x: 0, y: 0, z: 0, w: 1))
    simulated.motion?.setGravity(GCAcceleration(x: 0, y: -1, z: 0))
    simulated.motion?.setRotationRate(GCRotationRate(x: 0, y: 0, z: 0))
    simulated.motion?.setUserAcceleration(GCAcceleration())
    _ = simulated.motion?.controller
    if let motionCopy = simulated.motion {
        let other = GCMotion()
        other.setStateFrom(motionCopy)
        _ = other.sensorsActive
        _ = other.sensorsRequireManualActivation
        _ = other.acceleration.x
        _ = other.attitude.w
        _ = other.gravity.y
        _ = other.rotationRate.z
        _ = other.userAcceleration.x
        other.valueChangedHandler = { _ in }
    }

    let quat = GCQuaternion()
    _ = quat.x + quat.y + quat.z + quat.w
    _ = GCQuaternion(x: 0, y: 0, z: 0, w: 1)
    let accel = GCAcceleration()
    _ = accel.x + accel.y + accel.z
    _ = GCAcceleration(x: 1, y: 2, z: 3)
    let euler = GCEulerAngles(pitch: 1, yaw: 2, roll: 3)
    _ = euler.pitch + euler.yaw + euler.roll
    _ = GCEulerAngles()
    let rate = GCRotationRate()
    _ = rate.x + rate.y + rate.z
    _ = GCRotationRate(x: 0.1, y: 0.2, z: 0.3)
    GCSimulatedInput.detach(simulated)
    GCSimulatedInput.reset()
}
