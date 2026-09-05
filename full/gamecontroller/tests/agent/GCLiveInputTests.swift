import Foundation
import Dispatch
import GameController

func testLiveInputAndPhysicalElementProtocols() {
    final class Box: @unchecked Sendable {
        var available = 0
        var streamCount = 0
    }
    let box = Box()
    GCSimulatedInput.reset()
    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    let handlerQueue = DispatchQueue(label: "gc.live.handler")
    simulated.handlerQueue = handlerQueue

    let live = simulated.input
    live.inputStateQueueDepth = 8
    live.queue = handlerQueue
    _ = live.unmapped
    _ = live.device
    _ = live.lastEventLatency
    _ = live.lastEventTimestamp
    _ = live.switches
    _ = live.elements
    _ = live.axes
    _ = live.dpads
    _ = live.buttons
    _ = live[GCInputButtonA]
    live.elementValueDidChangeHandler = { _, _ in }
    live.inputStateAvailableHandler = { _ in box.available += 1 }

    let device: any GCDevice = simulated
    _ = device.handlerQueue
    _ = device.physicalInputProfile
    _ = device.productCategory
    _ = device.vendorName

    if let button = live.buttons[GCButtonElementName.a] {
        _ = button.aliases
        _ = button.localizedName
        _ = button.sfSymbolsName
        _ = button.forceInput
        _ = button.pressedInput.value
        _ = button.pressedInput.isPressed
        _ = button.pressedInput.isAnalog
        _ = button.pressedInput.canWrap
        _ = button.pressedInput.lastValueTimestamp
        _ = button.pressedInput.lastValueLatency
        _ = button.pressedInput.sources
        _ = button.pressedInput.lastPressedStateTimestamp
        _ = button.pressedInput.lastPressedStateLatency
        button.pressedInput.valueDidChangeHandler = { _, _, _ in }
        button.pressedInput.pressedDidChangeHandler = { _, _, _ in }
        if let touched = button.touchedInput {
            _ = touched.isTouched
            _ = touched.sources
            _ = touched.lastTouchedStateTimestamp
            _ = touched.lastTouchedStateLatency
            touched.touchedDidChangeHandler = { _, _, _ in }
        }
    }

    if let dpad = live.dpads[GCDirectionPadElementName.leftThumbstick] {
        _ = dpad.up
        _ = dpad.down
        _ = dpad.left
        _ = dpad.right
        _ = dpad.xAxis.value
        _ = dpad.xAxis.isAnalog
        _ = dpad.xAxis.canWrap
        _ = dpad.xAxis.lastValueTimestamp
        _ = dpad.xAxis.lastValueLatency
        _ = dpad.xAxis.sources
        dpad.xAxis.valueDidChangeHandler = { _, _, _ in }
        _ = dpad.yAxis
        _ = dpad.xyAxes.value
        _ = dpad.xyAxes.isAnalog
        _ = dpad.xyAxes.canWrap
        _ = dpad.xyAxes.lastValueTimestamp
        _ = dpad.xyAxes.lastValueLatency
        _ = dpad.xyAxes.sources
        dpad.xyAxes.valueDidChangeHandler = { _, _, _ in }
    }

    let axisIndex = live.axes.startIndex
    if axisIndex != live.axes.endIndex {
        let axis = live.axes[axisIndex]
        _ = axis.absoluteInput?.value
        _ = axis.relativeInput.delta
        _ = axis.relativeInput.isAnalog
        _ = axis.relativeInput.lastDeltaTimestamp
        _ = axis.relativeInput.lastDeltaLatency
        _ = axis.relativeInput.sources
        axis.relativeInput.deltaDidChangeHandler = { _, _, _ in }
    }

    simulated.extendedGamepad?.buttonB.setValue(0.75)
    precondition(simulated.extendedGamepad?.buttonB.isPressed == true)
    let queued = live.nextInputState()
    precondition(queued != nil)
    _ = queued?.lastEventTimestamp
    _ = queued?.lastEventLatency
    _ = queued?.device
    _ = queued?.axes
    _ = queued?.dpads
    _ = queued?.buttons
    _ = queued?.elements
    _ = queued?.switches
    if let element = live.buttons[GCButtonElementName.a] {
        _ = live.change(for: element)
        if let queuedState = queued {
            _ = queuedState.change(for: element)
        }
    }
    _ = live.changedElements()
    _ = queued?.changedElements()
    let captured = live.capture()
    _ = captured.lastEventTimestamp
    _ = captured.buttons
    _ = captured.axes
    _ = captured.dpads
    _ = captured.elements
    _ = captured.switches
    _ = captured[GCInputButtonA]

    let empty = GCControllerInputState()
    _ = empty.axes
    _ = empty.dpads
    _ = empty.buttons
    _ = empty.elements
    _ = empty.switches

    let physical: any GCDevicePhysicalInput = live
    _ = physical.inputStateQueueDepth
    _ = physical.queue
    _ = physical.capture()
    _ = physical.nextInputState()

    let streamGate = DispatchSemaphore(value: 0)
    Task {
        for await _ in live.inputStates {
            box.streamCount += 1
            streamGate.signal()
            break
        }
    }
    Thread.sleep(forTimeInterval: 0.05)
    simulated.extendedGamepad?.buttonY.setValue(1)
    precondition(streamGate.wait(timeout: .now() + 2) == .success)
    precondition(box.streamCount == 1)

    _ = (any GCAxis2DInput).self
    _ = (any GCAxisElement).self
    _ = (any GCAxisInput).self
    _ = (any GCButtonElement).self
    _ = (any GCDevice).self
    _ = (any GCDevicePhysicalInput).self
    _ = (any GCDevicePhysicalInputState).self
    _ = (any GCDevicePhysicalInputStateDiff).self
    _ = (any GCDirectionPadElement).self
    _ = (any GCLinearInput).self
    _ = (any GCPhysicalInputElement).self
    _ = (any GCPressedStateInput).self
    _ = (any GCRelativeInput).self
    _ = (any GCTouchedStateInput).self
    _ = GCControllerLiveInput.self
    _ = GCControllerInputState.self

    GCSimulatedInput.detach(simulated)
    GCSimulatedInput.reset()
}
