import Foundation
import Dispatch
import GameController

func testDeviceElementAliases() {
    GCSimulatedInput.reset()
    let queue = DispatchQueue(label: "gc.devicealias.handler")

    let axis = GCDeviceAxisInput()
    axis.valueChangedHandler = { _, _ in }
    axis.setValue(0.5)
    precondition(axis.value == 0.5)
    precondition(axis.isAnalog)
    precondition(GCDeviceAxisInput.self == GCControllerAxisInput.self)

    let button = GCDeviceButtonInput()
    button.isAnalog = true
    button.valueChangedHandler = { _, _, _ in }
    button.setValue(0.75)
    precondition(button.isPressed)
    precondition(button.value == 0.75)
    precondition(GCDeviceButtonInput.self == GCControllerButtonInput.self)

    let dpad = GCDeviceDirectionPad()
    dpad.valueChangedHandler = { _, _, _ in }
    dpad.setValueForXAxis(0.5, yAxis: 0.25)
    precondition(dpad.xAxis.value == 0.5)
    precondition(dpad.yAxis.value == 0.25)
    precondition(dpad.up.isPressed)
    precondition(GCDeviceDirectionPad.self == GCControllerDirectionPad.self)

    let element = GCDeviceElement()
    element.localizedName = "Trigger"
    element.sfSymbolsName = "gamecontroller.fill"
    precondition(element.localizedName == "Trigger")
    precondition(element.sfSymbolsName == "gamecontroller.fill")
    precondition(!element.isAnalog)
    precondition(GCDeviceElement.self == GCControllerElement.self)

    let touchpad = GCDeviceTouchpad()
    touchpad.setValueForXAxis(0.1, yAxis: 0.2, touchDown: true, buttonValue: 1.0)
    precondition(touchpad.touchState == .down)
    precondition(touchpad.button.isPressed)
    precondition(GCDeviceTouchpad.self == GCControllerTouchpad.self)

    let snapshot = GCController.withExtendedGamepad()
    snapshot.handlerQueue = queue
    let aliasedAxis: GCDeviceAxisInput = snapshot.extendedGamepad!.leftThumbstick.xAxis
    aliasedAxis.setValue(-0.25)
    precondition(aliasedAxis.value == -0.25)
    let aliasedButton: GCDeviceButtonInput = snapshot.extendedGamepad!.buttonA
    aliasedButton.setValue(1.0)
    precondition(aliasedButton.isPressed)
    GCSimulatedInput.reset()
}
