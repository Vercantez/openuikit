import Foundation
import Dispatch
import GameController

func testHandlerTypealiases() {
    GCSimulatedInput.reset()
    let queue = DispatchQueue(label: "gc.handlertype.handler")
    let snapshot = GCController.withExtendedGamepad()
    snapshot.handlerQueue = queue
    let pad = snapshot.extendedGamepad!

    let axisHandler: GCControllerAxisValueChangedHandler = { _, _ in }
    pad.leftThumbstick.xAxis.valueChangedHandler = axisHandler
    pad.leftThumbstick.xAxis.setValue(0.25)
    precondition(pad.leftThumbstick.xAxis.value == 0.25)
    precondition(pad.leftThumbstick.xAxis.valueChangedHandler != nil)

    let buttonHandler: GCControllerButtonValueChangedHandler = { _, _, _ in }
    pad.buttonA.valueChangedHandler = buttonHandler
    pad.buttonA.setValue(1.0)
    precondition(pad.buttonA.isPressed)
    precondition(pad.buttonA.valueChangedHandler != nil)

    let touchedHandler: GCControllerButtonTouchedChangedHandler = { _, _, _, _ in }
    pad.buttonA.touchedChangedHandler = touchedHandler
    precondition(pad.buttonA.touchedChangedHandler != nil)

    let dpadHandler: GCControllerDirectionPadValueChangedHandler = { _, _, _ in }
    pad.dpad.valueChangedHandler = dpadHandler
    pad.dpad.setValueForXAxis(0.0, yAxis: 1.0)
    precondition(pad.dpad.up.isPressed)
    precondition(pad.dpad.valueChangedHandler != nil)

    let touchpad = GCControllerTouchpad()
    let touchHandler: GCControllerTouchpadHandler = { _, _, _, _, _ in }
    touchpad.touchDown = touchHandler
    touchpad.touchMoved = touchHandler
    touchpad.touchUp = touchHandler
    touchpad.setValueForXAxis(0.0, yAxis: 0.0, touchDown: true, buttonValue: 0.0)
    precondition(touchpad.touchState == .down)
    precondition(touchpad.touchDown != nil)

    let extendedHandler: GCExtendedGamepadValueChangedHandler = { _, _ in }
    pad.valueChangedHandler = extendedHandler
    precondition(pad.valueChangedHandler != nil)

    let classic = GCGamepad()
    let gamepadHandler: GCGamepadValueChangedHandler = { _, _ in }
    classic.valueChangedHandler = gamepadHandler
    classic.buttonB.setValue(0.5)
    precondition(classic.buttonB.value == 0.5)
    precondition(classic.valueChangedHandler != nil)

    let micro = GCMicroGamepad()
    let microHandler: GCMicroGamepadValueChangedHandler = { _, _ in }
    micro.valueChangedHandler = microHandler
    precondition(micro.valueChangedHandler != nil)

    let motion = GCMotion()
    var motionFires = 0
    let motionHandler: GCMotionValueChangedHandler = { _ in motionFires += 1 }
    motion.valueChangedHandler = motionHandler
    motion.setAcceleration(GCAcceleration(x: 0, y: 0, z: -1))
    precondition(motionFires == 1)
    precondition(motion.acceleration.z == -1)

    let keyboardInput = GCKeyboardInput()
    let keyboardHandler: GCKeyboardValueChangedHandler = { _, _, _, _ in }
    keyboardInput.keyChangedHandler = keyboardHandler
    precondition(keyboardInput.keyChangedHandler != nil)

    let mouseInput = GCMouseInput()
    let mouseHandler: GCMouseMoved = { _, _, _ in }
    mouseInput.mouseMovedHandler = mouseHandler
    precondition(mouseInput.mouseMovedHandler != nil)
    GCSimulatedInput.reset()
}
