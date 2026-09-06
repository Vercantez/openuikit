import Foundation
import TouchController

func testControlLabelPresets() {
    precondition(TCControlLabel.buttonA.name == "Button A")
    precondition(TCControlLabel.buttonA.role == .button)
    precondition(TCControlLabel.buttonB.name == "Button B")
    precondition(TCControlLabel.buttonB.role == .button)
    precondition(TCControlLabel.buttonX.name == "Button X")
    precondition(TCControlLabel.buttonY.name == "Button Y")
    precondition(TCControlLabel.buttonMenu.name == "Button Menu")
    precondition(TCControlLabel.buttonOptions.name == "Button Options")
    precondition(TCControlLabel.buttonLeftShoulder.name == "Left Shoulder")
    precondition(TCControlLabel.buttonLeftTrigger.name == "Left Trigger")
    precondition(TCControlLabel.buttonRightShoulder.name == "Right Shoulder")
    precondition(TCControlLabel.buttonRightTrigger.name == "Right Trigger")
    precondition(TCControlLabel.leftThumbstick.name == "Left Thumbstick")
    precondition(TCControlLabel.leftThumbstick.role == .button)
    precondition(TCControlLabel.leftThumbstickButton.name == "Left Thumbstick Button")
    precondition(TCControlLabel.rightThumbstick.name == "Right Thumbstick")
    precondition(TCControlLabel.rightThumbstickButton.name == "Right Thumbstick Button")
    precondition(TCControlLabel.directionPad.name == "Direction Pad")
    precondition(TCControlLabel.directionPad.role == .directionPad)
    precondition(TCControlLabel.buttonA === TCControlLabel.buttonA)
}

func testControlLabelCustomInit() {
    let label = TCControlLabel(name: "Custom Pad", role: .directionPad)
    precondition(label.name == "Custom Pad")
    precondition(label.role == .directionPad)
    precondition(label !== TCControlLabel.directionPad)
}
