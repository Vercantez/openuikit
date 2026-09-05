import Foundation
import Dispatch
import GameController

func testGamepadProfileFamilies() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let pad = snapshot.extendedGamepad!
    _ = pad.controller
    _ = pad.buttonA
    _ = pad.buttonB
    _ = pad.buttonX
    _ = pad.buttonY
    _ = pad.buttonHome
    _ = pad.buttonMenu
    _ = pad.buttonOptions
    _ = pad.leftShoulder
    _ = pad.rightShoulder
    _ = pad.leftTrigger
    _ = pad.rightTrigger
    _ = pad.leftThumbstick
    _ = pad.rightThumbstick
    _ = pad.leftThumbstickButton
    _ = pad.rightThumbstickButton
    _ = pad.dpad
    pad.valueChangedHandler = { _, _ in }
    _ = pad.saveSnapshot()
    pad.setStateFrom(pad)

    if let gamepad = snapshot.gamepad {
        _ = gamepad.saveSnapshot()
        _ = gamepad.buttonA
        _ = gamepad.buttonB
        _ = gamepad.buttonX
        _ = gamepad.buttonY
        _ = gamepad.dpad
        _ = gamepad.leftShoulder
        _ = gamepad.rightShoulder
        _ = gamepad.controller
        gamepad.valueChangedHandler = { _, _ in }
    }

    let micro = GCController.withMicroGamepad()
    precondition(micro.microGamepad != nil)
    micro.microGamepad?.buttonA.setValue(1)
    precondition(micro.microGamepad?.buttonA.isPressed == true)
    micro.microGamepad?.allowsRotation = true
    micro.microGamepad?.reportsAbsoluteDpadValues = true
    precondition(micro.microGamepad?.allowsRotation == true)
    _ = micro.microGamepad?.buttonX
    _ = micro.microGamepad?.buttonMenu
    _ = micro.microGamepad?.dpad
    _ = micro.microGamepad?.controller
    micro.microGamepad?.valueChangedHandler = { _, _ in }
    _ = micro.microGamepad?.saveSnapshot()
    if let otherMicro = GCController.withMicroGamepad().microGamepad, let liveMicro = micro.microGamepad {
        liveMicro.setStateFrom(otherMicro)
    }

    let directional = GCSimulatedInput.makeDirectionalGamepad()
    precondition(directional.microGamepad is GCDirectionalGamepad)
    _ = GCDirectionalGamepad.self
    _ = GCGamepad.self
    _ = GCExtendedGamepad.self
    _ = GCMicroGamepad.self
    GCSimulatedInput.reset()
}
