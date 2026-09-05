import Foundation
import Dispatch
import GameController

func testSnapshotRoundTrip() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let pad = snapshot.extendedGamepad!
    pad.buttonA.setValue(1)
    let snapshotBlob = pad.saveSnapshot().snapshotData
    precondition(!snapshotBlob.isEmpty)
    var decoded = GCExtendedGamepadSnapshotData()
    precondition(GCExtendedGamepadSnapshotDataFromNSData(&decoded, snapshotBlob))
    precondition(decoded.buttonA == 1)
    _ = decoded.version
    _ = decoded.size
    _ = decoded.dpadX
    _ = decoded.dpadY
    _ = decoded.buttonB
    _ = decoded.buttonX
    _ = decoded.buttonY
    _ = decoded.leftShoulder
    _ = decoded.rightShoulder
    _ = decoded.leftThumbstickX
    _ = decoded.leftThumbstickY
    _ = decoded.rightThumbstickX
    _ = decoded.rightThumbstickY
    _ = decoded.leftTrigger
    _ = decoded.rightTrigger
    _ = decoded.supportsClickableThumbsticks
    _ = decoded.leftThumbstickButton
    _ = decoded.rightThumbstickButton

    var encoded = GCExtendedGamepadSnapshotData(
        version: 2,
        size: 80,
        dpadX: 0, dpadY: 0,
        buttonA: 0, buttonB: 0, buttonX: 0.75, buttonY: 0,
        leftShoulder: 0, rightShoulder: 0,
        leftThumbstickX: 0, leftThumbstickY: 0,
        rightThumbstickX: 0, rightThumbstickY: 0,
        leftTrigger: 0.4, rightTrigger: 0,
        supportsClickableThumbsticks: false,
        leftThumbstickButton: false,
        rightThumbstickButton: false
    )
    let roundTrip = NSDataFromGCExtendedGamepadSnapshotData(&encoded)
    var restored = GCExtendedGamepadSnapshotData()
    precondition(GCExtendedGamepadSnapshotDataFromNSData(&restored, roundTrip))
    precondition(abs(restored.buttonX - 0.75) < 0.0001)
    precondition(abs(restored.leftTrigger - 0.4) < 0.0001)

    var v100 = GCExtendedGamepadSnapShotDataV100(
        version: 0x100,
        size: 60,
        dpadX: 0.1, dpadY: -0.2,
        buttonA: 0.5, buttonB: 0.3, buttonX: 0.4, buttonY: 0.5,
        leftShoulder: 0.6, rightShoulder: 0.7,
        leftThumbstickX: 0.8, leftThumbstickY: -0.8,
        rightThumbstickX: 0.2, rightThumbstickY: -0.2,
        leftTrigger: 0.9, rightTrigger: 0.1
    )
    let v100Data = NSDataFromGCExtendedGamepadSnapShotDataV100(&v100)
    var v100Restored = GCExtendedGamepadSnapShotDataV100()
    precondition(GCExtendedGamepadSnapShotDataV100FromNSData(&v100Restored, v100Data))
    precondition(abs(v100Restored.buttonA - 0.5) < 0.0001)
    _ = v100Restored.version
    _ = v100Restored.size
    _ = v100Restored.dpadX
    _ = v100Restored.dpadY
    _ = v100Restored.buttonB
    _ = v100Restored.buttonX
    _ = v100Restored.buttonY
    _ = v100Restored.leftShoulder
    _ = v100Restored.rightShoulder
    _ = v100Restored.leftThumbstickX
    _ = v100Restored.leftThumbstickY
    _ = v100Restored.rightThumbstickX
    _ = v100Restored.rightThumbstickY
    _ = v100Restored.leftTrigger
    _ = v100Restored.rightTrigger

    var classic = GCGamepadSnapShotDataV100(
        version: 0x100,
        size: 36,
        dpadX: 0.5, dpadY: -0.5,
        buttonA: 1, buttonB: 0.2, buttonX: 0.3, buttonY: 0.4,
        leftShoulder: 0.6, rightShoulder: 0.7
    )
    let classicData = NSDataFromGCGamepadSnapShotDataV100(&classic)
    var classicRestored = GCGamepadSnapShotDataV100()
    precondition(GCGamepadSnapShotDataV100FromNSData(&classicRestored, classicData))
    precondition(classicRestored.buttonA == 1)
    _ = classicRestored.version
    _ = classicRestored.size
    _ = classicRestored.dpadX
    _ = classicRestored.dpadY
    _ = classicRestored.buttonB
    _ = classicRestored.buttonX
    _ = classicRestored.buttonY
    _ = classicRestored.leftShoulder
    _ = classicRestored.rightShoulder

    let extendedFromData = GCExtendedGamepadSnapshot(snapshotData: snapshotBlob)
    precondition(extendedFromData.buttonA.isPressed)
    _ = extendedFromData.snapshotData
    _ = GCExtendedGamepadSnapshot(controller: snapshot, snapshotData: snapshotBlob)
    let gamepadSnap = GCGamepadSnapshot(snapshotData: classicData ?? Data())
    _ = gamepadSnap.snapshotData
    _ = GCGamepadSnapshot(controller: snapshot, snapshotData: classicData ?? Data())

    var microDataStruct = GCMicroGamepadSnapshotData(
        version: 1,
        size: 24,
        dpadX: 0.25, dpadY: -0.25,
        buttonA: 1, buttonX: 0.5
    )
    _ = microDataStruct.version
    _ = microDataStruct.size
    _ = microDataStruct.dpadX
    _ = microDataStruct.dpadY
    _ = microDataStruct.buttonA
    _ = microDataStruct.buttonX
    let microBlob = NSDataFromGCMicroGamepadSnapshotData(&microDataStruct)
    var microRestored = GCMicroGamepadSnapshotData()
    precondition(GCMicroGamepadSnapshotDataFromNSData(&microRestored, microBlob))
    var microV100 = GCMicroGamepadSnapShotDataV100(
        version: 0x100,
        size: 20,
        dpadX: 0.3, dpadY: 0.4,
        buttonA: 1, buttonX: 0.2
    )
    _ = microV100.version
    _ = microV100.size
    _ = microV100.dpadX
    _ = microV100.dpadY
    _ = microV100.buttonA
    _ = microV100.buttonX
    let microV100Blob = NSDataFromGCMicroGamepadSnapShotDataV100(&microV100)
    var microV100Restored = GCMicroGamepadSnapShotDataV100()
    precondition(GCMicroGamepadSnapShotDataV100FromNSData(&microV100Restored, microV100Blob))
    let micro = GCController.withMicroGamepad()
    let microSnap = GCMicroGamepadSnapshot(snapshotData: microBlob ?? Data())
    _ = microSnap.snapshotData
    _ = GCMicroGamepadSnapshot(controller: micro, snapshotData: microBlob ?? Data())
    _ = GCExtendedGamepadSnapshot.self
    _ = GCGamepadSnapshot.self
    _ = GCMicroGamepadSnapshot.self
    GCSimulatedInput.reset()
}
