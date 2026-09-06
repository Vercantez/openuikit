import Foundation

/// Named Game Controller element that a touch control binds to.
/// Preset `name` strings match the sibling `GameController` `GCInput*`
/// constants (`"Button A"`, `"Left Thumbstick"`, …).
public final class TCControlLabel: NSObject {
    public enum Role: Int, Sendable, Hashable {
        case button = 0
        case directionPad = 1
    }

    public let name: String
    public let role: Role

    public init(name: String, role: Role) {
        self.name = name
        self.role = role
        super.init()
    }

    private static let presetButtonA = TCControlLabel(name: "Button A", role: .button)
    private static let presetButtonB = TCControlLabel(name: "Button B", role: .button)
    private static let presetButtonX = TCControlLabel(name: "Button X", role: .button)
    private static let presetButtonY = TCControlLabel(name: "Button Y", role: .button)
    private static let presetButtonMenu = TCControlLabel(name: "Button Menu", role: .button)
    private static let presetButtonOptions = TCControlLabel(name: "Button Options", role: .button)
    private static let presetButtonLeftShoulder = TCControlLabel(name: "Left Shoulder", role: .button)
    private static let presetButtonLeftTrigger = TCControlLabel(name: "Left Trigger", role: .button)
    private static let presetButtonRightShoulder = TCControlLabel(name: "Right Shoulder", role: .button)
    private static let presetButtonRightTrigger = TCControlLabel(name: "Right Trigger", role: .button)
    private static let presetLeftThumbstick = TCControlLabel(name: "Left Thumbstick", role: .button)
    private static let presetLeftThumbstickButton = TCControlLabel(name: "Left Thumbstick Button", role: .button)
    private static let presetRightThumbstick = TCControlLabel(name: "Right Thumbstick", role: .button)
    private static let presetRightThumbstickButton = TCControlLabel(name: "Right Thumbstick Button", role: .button)
    private static let presetDirectionPad = TCControlLabel(name: "Direction Pad", role: .directionPad)

    public class var buttonA: TCControlLabel { presetButtonA }
    public class var buttonB: TCControlLabel { presetButtonB }
    public class var buttonX: TCControlLabel { presetButtonX }
    public class var buttonY: TCControlLabel { presetButtonY }
    public class var buttonMenu: TCControlLabel { presetButtonMenu }
    public class var buttonOptions: TCControlLabel { presetButtonOptions }
    public class var buttonLeftShoulder: TCControlLabel { presetButtonLeftShoulder }
    public class var buttonLeftTrigger: TCControlLabel { presetButtonLeftTrigger }
    public class var buttonRightShoulder: TCControlLabel { presetButtonRightShoulder }
    public class var buttonRightTrigger: TCControlLabel { presetButtonRightTrigger }
    public class var leftThumbstick: TCControlLabel { presetLeftThumbstick }
    public class var leftThumbstickButton: TCControlLabel { presetLeftThumbstickButton }
    public class var rightThumbstick: TCControlLabel { presetRightThumbstick }
    public class var rightThumbstickButton: TCControlLabel { presetRightThumbstickButton }
    public class var directionPad: TCControlLabel { presetDirectionPad }
}
