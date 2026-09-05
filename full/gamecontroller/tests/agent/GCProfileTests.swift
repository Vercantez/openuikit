import Foundation
import Dispatch
import GameController

func testPhysicalInputProfileDictionaries() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let pad = snapshot.extendedGamepad!
    precondition(pad.elements[GCInputButtonA] === pad.buttonA)
    precondition(pad.buttons[GCInputButtonA] === pad.buttonA)
    precondition(pad.dpads[GCInputLeftThumbstick] != nil)
    _ = pad.axes
    _ = pad.touchpads
    _ = pad.allElements
    _ = pad.allButtons
    _ = pad.allDpads
    _ = pad.allAxes
    _ = pad.allTouchpads
    _ = pad.hasRemappedElements
    _ = pad.device
    precondition(pad[GCInputButtonA] === pad.buttonA)
    _ = pad.mappedElementAlias(forPhysicalInputName: GCInputButtonA)
    _ = pad.mappedPhysicalInputNames(forElementAlias: GCInputButtonA)

    pad.buttonA.setValue(1)
    precondition(pad.lastEventTimestamp > 0)
    pad.valueDidChangeHandler = { _, _ in }

    let profileCopy = pad.capture()
    precondition(profileCopy.buttonA.isPressed)
    profileCopy.setStateFromPhysicalInput(pad)
    GCSimulatedInput.reset()
}
