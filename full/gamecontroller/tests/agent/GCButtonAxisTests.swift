import Foundation
import Dispatch
import GameController

func testButtonAxisDpadHandlers() {
    final class Box: @unchecked Sendable {
        var handlerQueueHonored = false
        var handlerFireCount = 0
        var pressedFireCount = 0
        var touchedFireCount = 0
    }
    let box = Box()
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let handlerQueue = DispatchQueue(label: "gc.button.handler")
    let handlerKey = DispatchSpecificKey<UInt8>()
    handlerQueue.setSpecific(key: handlerKey, value: 7)
    snapshot.handlerQueue = handlerQueue
    let pad = snapshot.extendedGamepad!

    precondition(pad.buttonA.value == 0)
    precondition(!pad.buttonA.isPressed)
    precondition(pad.buttonA.isAnalog)

    let handlerGate = DispatchSemaphore(value: 0)
    pad.buttonA.valueChangedHandler = { _, _, _ in
        box.handlerFireCount += 1
        box.handlerQueueHonored = DispatchQueue.getSpecific(key: handlerKey) == 7
        handlerGate.signal()
    }
    pad.buttonA.pressedChangedHandler = { _, _, _ in
        box.pressedFireCount += 1
    }
    pad.buttonA.touchedChangedHandler = { _, _, _, _ in
        box.touchedFireCount += 1
    }
    pad.buttonA.setValue(1)
    precondition(pad.buttonA.isPressed)
    precondition(pad.buttonA.value == 1)
    precondition(pad.buttonA.isTouched)
    precondition(handlerGate.wait(timeout: .now() + 2) == .success)
    precondition(box.handlerFireCount == 1)
    precondition(box.handlerQueueHonored)

    pad.leftThumbstick.setValueForXAxis(0.5, yAxis: -0.25)
    precondition(abs(pad.leftThumbstick.xAxis.value - 0.5) < 0.0001)
    precondition(abs(pad.leftThumbstick.yAxis.value + 0.25) < 0.0001)
    precondition(pad.leftThumbstick.right.isPressed)
    precondition(!pad.leftThumbstick.left.isPressed)
    precondition(pad.leftThumbstick.down.isPressed)
    precondition(!pad.leftThumbstick.up.isPressed)
    precondition(!pad.leftThumbstick.up.isAnalog)
    precondition(pad.leftThumbstick.xAxis.isAnalog)
    pad.leftThumbstick.valueChangedHandler = { _, _, _ in }
    pad.leftThumbstick.xAxis.valueChangedHandler = { _, _ in }
    pad.leftThumbstick.xAxis.setValue(0.1)

    _ = pad.buttonA.collection
    _ = pad.buttonA.isBoundToSystemGesture
    _ = pad.buttonA.preferredSystemGestureState
    _ = pad.buttonA.sfSymbolsName
    _ = pad.buttonA.localizedName
    _ = pad.buttonA.unmappedLocalizedName
    _ = pad.buttonA.unmappedSfSymbolsName
    _ = pad.buttonA.aliases
    _ = GCControllerElement.self
    _ = GCControllerButtonInput.self
    _ = GCControllerAxisInput.self
    _ = GCControllerDirectionPad.self
    GCSimulatedInput.reset()
}
