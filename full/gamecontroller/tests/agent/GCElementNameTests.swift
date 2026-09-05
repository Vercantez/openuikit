import Foundation
import Dispatch
import GameController

func testElementNameConstants() {
    _ = GCButtonElementName.self
    _ = GCAxisElementName.self
    _ = GCSwitchElementName.self
    _ = GCDirectionPadElementName.self
    _ = GCPhysicalInputElementName.self
    precondition(GCButtonElementName.a.rawValue == GCInputButtonA)
    precondition(GCButtonElementName.b.rawValue == GCInputButtonB)
    precondition(GCButtonElementName.x.rawValue == GCInputButtonX)
    precondition(GCButtonElementName.y.rawValue == GCInputButtonY)
    precondition(GCButtonElementName.leftBumper.rawValue == "Left Bumper")
    precondition(GCButtonElementName.leftTrigger.rawValue == GCInputLeftTrigger)
    precondition(GCButtonElementName.rightBumper.rawValue == "Right Bumper")
    precondition(GCButtonElementName.leftShoulder.rawValue == GCInputLeftShoulder)
    precondition(GCButtonElementName.rightTrigger.rawValue == GCInputRightTrigger)
    precondition(GCButtonElementName.rightShoulder.rawValue == GCInputRightShoulder)
    precondition(GCButtonElementName.thumbstickButton.rawValue == "Thumbstick Button")
    precondition(GCButtonElementName.leftThumbstickButton.rawValue == GCInputLeftThumbstickButton)
    precondition(GCButtonElementName.rightThumbstickButton.rawValue == GCInputRightThumbstickButton)
    precondition(GCButtonElementName.grip.rawValue == "Grip")
    precondition(GCButtonElementName.home.rawValue == GCInputButtonHome)
    precondition(GCButtonElementName.menu.rawValue == GCInputButtonMenu)
    precondition(GCButtonElementName.share.rawValue == GCInputButtonShare)
    precondition(GCButtonElementName.options.rawValue == GCInputButtonOptions)
    precondition(GCButtonElementName.trigger.rawValue == "Trigger")
    precondition(GCButtonElementName.arcadeButton(row: 1, column: 2).rawValue == "Arcade Button 1,2")
    precondition(GCButtonElementName.backLeftButton(position: 1).rawValue == "Back Left Button 1")
    precondition(GCButtonElementName.backRightButton(position: 2).rawValue == "Back Right Button 2")
    precondition(GCDirectionPadElementName.directionPad.rawValue == GCInputDirectionPad)
    precondition(GCDirectionPadElementName.thumbstick.rawValue == "Thumbstick")
    precondition(GCDirectionPadElementName.leftThumbstick.rawValue == GCInputLeftThumbstick)
    precondition(GCDirectionPadElementName.rightThumbstick.rawValue == GCInputRightThumbstick)
    _ = GCButtonElementName(rawValue: "Custom")
    _ = GCAxisElementName(rawValue: "Axis")
    _ = GCSwitchElementName(rawValue: "Switch")
    _ = GCPhysicalInputElementName(rawValue: "Element")
    _ = GCDirectionPadElementName(rawValue: "Pad")
    precondition(GCButtonElementName.a != GCButtonElementName.b)
    precondition(GCAxisElementName(rawValue: "a") != GCAxisElementName(rawValue: "b"))
    precondition(GCSwitchElementName(rawValue: "a") != GCSwitchElementName(rawValue: "b"))
    precondition(GCDirectionPadElementName.leftThumbstick != .rightThumbstick)
    precondition(GCPhysicalInputElementName(rawValue: "a") != GCPhysicalInputElementName(rawValue: "b"))
    var hasher = Hasher()
    GCButtonElementName.a.hash(into: &hasher)
    GCAxisElementName(rawValue: "x").hash(into: &hasher)
    GCSwitchElementName(rawValue: "s").hash(into: &hasher)
    GCDirectionPadElementName.directionPad.hash(into: &hasher)
    GCPhysicalInputElementName(rawValue: "p").hash(into: &hasher)
    _ = hasher.finalize()
    _ = Set([GCButtonElementName.a, .b])
    _ = Set([GCAxisElementName(rawValue: "x")])
    _ = Set([GCSwitchElementName(rawValue: "s")])
    _ = Set([GCDirectionPadElementName.directionPad])
    _ = Set([GCPhysicalInputElementName(rawValue: "p")])
}
