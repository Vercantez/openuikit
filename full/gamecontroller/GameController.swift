import Foundation
import Dispatch

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreServices)
import CoreServices
#endif

/// Linux starting implementation of Apple's public `GameController` module.
///
/// Software snapshot controllers (`GCController.withExtendedGamepad()` /
/// `withMicroGamepad()`) are real in-memory devices with analog and button
/// elements. Physical HID, wireless discovery, haptics engines, DualSense
/// trigger motors, virtual-controller injection, and UIKit/SwiftUI event
/// routing are fail-closed: this host has no Apple GameController service.
/// UIKit types are imported and used when the real module is present; they are
/// omitted (not replaced with `NSObject` or a local stand-in) otherwise.

public enum GCControllerPlayerIndex: Int, Sendable, Hashable {
    case indexUnset = -1
    case index1 = 0
    case index2 = 1
    case index3 = 2
    case index4 = 3
}

public enum GCDevicePhysicalInputElementChange: Int, Sendable, Hashable {
    case unknownChange = -1
    case noChange = 0
    case changed = 1
}

public enum GCExtendedGamepadSnapshotDataVersion: Int, Sendable, Hashable {
    case version1 = 1
    case version2 = 2
}

public enum GCMicroGamepadSnapshotDataVersion: Int, Sendable, Hashable {
    case version1 = 1
}

public struct GCPhysicalInputSourceDirection: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let up = GCPhysicalInputSourceDirection(rawValue: 1 << 0)
    public static let down = GCPhysicalInputSourceDirection(rawValue: 1 << 1)
    public static let left = GCPhysicalInputSourceDirection(rawValue: 1 << 2)
    public static let right = GCPhysicalInputSourceDirection(rawValue: 1 << 3)
}

public struct GCUIEventTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let gamepad = GCUIEventTypes(rawValue: 1 << 0)
}

public struct GCHapticsLocality: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let all = GCHapticsLocality(rawValue: "All")
    public static let `default` = GCHapticsLocality(rawValue: "Default")
    public static let handles = GCHapticsLocality(rawValue: "Handles")
    public static let leftHandle = GCHapticsLocality(rawValue: "LeftHandle")
    public static let rightHandle = GCHapticsLocality(rawValue: "RightHandle")
    public static let triggers = GCHapticsLocality(rawValue: "Triggers")
    public static let leftTrigger = GCHapticsLocality(rawValue: "LeftTrigger")
    public static let rightTrigger = GCHapticsLocality(rawValue: "RightTrigger")
}

public struct GCPoint2: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    public init() {
        self.init(x: 0, y: 0)
    }
}

public let GCPoint2Zero = GCPoint2()

public func GCPoint2Make(_ x: Float, _ y: Float) -> GCPoint2 {
    GCPoint2(x: x, y: y)
}

public func GCPoint2Equal(_ point1: GCPoint2, _ point2: GCPoint2) -> Bool {
    point1 == point2
}

public func NSStringFromGCPoint2(_ point: GCPoint2) -> String {
    "{\(point.x), \(point.y)}"
}

public struct GCQuaternion: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double
    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    public init() {
        self.init(x: 0, y: 0, z: 0, w: 1)
    }
}

public struct GCAcceleration: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public struct GCEulerAngles: Equatable, Sendable {
    public var pitch: Double
    public var yaw: Double
    public var roll: Double
    public init(pitch: Double, yaw: Double, roll: Double) {
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
    }
    public init() {
        self.init(pitch: 0, yaw: 0, roll: 0)
    }
}

public struct GCRotationRate: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    public init() {
        self.init(x: 0, y: 0, z: 0)
    }
}

public let GCCurrentExtendedGamepadSnapshotDataVersion = GCExtendedGamepadSnapshotDataVersion.version2
public let GCCurrentMicroGamepadSnapshotDataVersion = GCMicroGamepadSnapshotDataVersion.version1
public let GCHapticDurationInfinite: Float = -1

public let GCProductCategoryArcadeStick = "Arcade Stick"
public let GCProductCategoryCoalescedRemote = "Coalesced Remote"
public let GCProductCategoryControlCenterRemote = "Control Center Remote"
public let GCProductCategoryDualSense = "DualSense"
public let GCProductCategoryDualShock4 = "DualShock4"
public let GCProductCategoryHID = "HID"
public let GCProductCategoryKeyboard = "Keyboard"
public let GCProductCategoryMFi = "MFi"
public let GCProductCategoryMouse = "Mouse"
public let GCProductCategorySiriRemote1stGen = "Siri Remote 1st Gen"
public let GCProductCategorySiriRemote2ndGen = "Siri Remote 2nd Gen"
public let GCProductCategorySpatialController = "Spatial Controller"
public let GCProductCategoryUniversalElectronicsRemote = "Universal Electronics Remote"
public let GCProductCategoryXboxOne = "Xbox One"

public var kIOHIDGCSyntheticDeviceKey: String { "GCSyntheticDevice" }

public var GCInputButtonA: String { "Button A" }
public var GCInputButtonB: String { "Button B" }
public var GCInputButtonX: String { "Button X" }
public var GCInputButtonY: String { "Button Y" }
public var GCInputButtonHome: String { "Button Home" }
public var GCInputButtonMenu: String { "Button Menu" }
public var GCInputButtonShare: String { "Button Share" }
public var GCInputButtonOptions: String { "Button Options" }
public var GCInputLeftTrigger: String { "Left Trigger" }
public var GCInputRightTrigger: String { "Right Trigger" }
public var GCInputLeftShoulder: String { "Left Shoulder" }
public var GCInputRightShoulder: String { "Right Shoulder" }
public var GCInputDirectionPad: String { "Direction Pad" }
public var GCInputLeftThumbstick: String { "Left Thumbstick" }
public var GCInputRightThumbstick: String { "Right Thumbstick" }
public var GCInputLeftThumbstickButton: String { "Left Thumbstick Button" }
public var GCInputRightThumbstickButton: String { "Right Thumbstick Button" }
public var GCInputXboxPaddleOne: String { "Paddle 1" }
public var GCInputXboxPaddleTwo: String { "Paddle 2" }
public var GCInputXboxPaddleThree: String { "Paddle 3" }
public var GCInputXboxPaddleFour: String { "Paddle 4" }
public var GCInputDualShockTouchpadOne: String { "Touchpad 1" }
public var GCInputDualShockTouchpadTwo: String { "Touchpad 2" }
public var GCInputDualShockTouchpadButton: String { "Touchpad Button" }

public let GCInputDirectionalCardinalDpad = "Cardinal D-pad"
public let GCInputDirectionalCenterButton = "Center Button"
public let GCInputDirectionalDpad = "Directional D-pad"
public let GCInputDirectionalTouchSurfaceButton = "Touch Surface Button"
public let GCInputMicroGamepadButtonA = "Button A"
public let GCInputMicroGamepadButtonMenu = "Button Menu"
public let GCInputMicroGamepadButtonX = "Button X"
public let GCInputMicroGamepadDpad = "Direction Pad"

extension NSNotification.Name {
    public static let GCControllerDidBecomeCurrent = NSNotification.Name("GCControllerDidBecomeCurrentNotification")
    public static let GCControllerDidConnect = NSNotification.Name("GCControllerDidConnectNotification")
    public static let GCControllerDidDisconnect = NSNotification.Name("GCControllerDidDisconnectNotification")
    public static let GCControllerDidStopBeingCurrent = NSNotification.Name("GCControllerDidStopBeingCurrentNotification")
    public static let GCControllerUserCustomizationsDidChange = NSNotification.Name("GCControllerUserCustomizationsDidChangeNotification")
    public static let GCKeyboardDidConnect = NSNotification.Name("GCKeyboardDidConnectNotification")
    public static let GCKeyboardDidDisconnect = NSNotification.Name("GCKeyboardDidDisconnectNotification")
    public static let GCMouseDidBecomeCurrent = NSNotification.Name("GCMouseDidBecomeCurrentNotification")
    public static let GCMouseDidConnect = NSNotification.Name("GCMouseDidConnectNotification")
    public static let GCMouseDidDisconnect = NSNotification.Name("GCMouseDidDisconnectNotification")
    public static let GCMouseDidStopBeingCurrent = NSNotification.Name("GCMouseDidStopBeingCurrentNotification")
}

public protocol GCDevice: NSObjectProtocol {
    var handlerQueue: DispatchQueue { get set }
    var physicalInputProfile: GCPhysicalInputProfile { get }
    var productCategory: String { get }
    var vendorName: String? { get }
}

open class GCGameControllerActivationContext: NSObject {
    open var previousApplicationBundleID: String? { nil }
}

#if canImport(UIKit)
@MainActor
public protocol GCGameControllerSceneDelegate: NSObjectProtocol {
    func scene(
        _ scene: UIKit.UIScene,
        didActivateGameControllerWith context: GCGameControllerActivationContext
    )
}
#endif

open class GCColor: NSObject, NSSecureCoding {
    open var red: Float
    open var green: Float
    open var blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        red = coder.decodeFloat(forKey: "red")
        green = coder.decodeFloat(forKey: "green")
        blue = coder.decodeFloat(forKey: "blue")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(red, forKey: "red")
        coder.encode(green, forKey: "green")
        coder.encode(blue, forKey: "blue")
    }
}

open class GCDeviceBattery: NSObject {
    public enum State: Int, Sendable, Hashable {
        case unknown = 0
        case discharging = 1
        case charging = 2
        case full = 3
    }

    open var batteryLevel: Float
    open var batteryState: State

    init(level: Float, state: State) {
        self.batteryLevel = level
        self.batteryState = state
        super.init()
    }
}

open class GCDeviceLight: NSObject {
    open var color: GCColor
    init(color: GCColor) {
        self.color = color
        super.init()
    }
}

open class GCDeviceHaptics: NSObject {
    open var supportedLocalities: Set<GCHapticsLocality> { [] }
}

public struct GameControllerEventHandlingOptions: Equatable, Sendable {
    public var receivesEventsInView: Bool
    public init() { self.receivesEventsInView = false }
    public static func receivesEventsInView(_ receivesEventsInView: Bool) -> GameControllerEventHandlingOptions {
        var options = GameControllerEventHandlingOptions()
        options.receivesEventsInView = receivesEventsInView
        return options
    }
}

#if canImport(UIKit)
@MainActor
open class GCEventViewController: UIKit.UIViewController {
    open var controllerUserInteractionEnabled = false
}

@MainActor
open class GCEventInteraction: NSObject, UIKit.UIInteraction {
    public override init() {
        super.init()
    }

    open var handledEventTypes = GCUIEventTypes.gamepad
    open var receivesEventsInView = false
    public private(set) weak var view: UIKit.UIView?

    public func willMove(to view: UIKit.UIView?) {
        _ = view
    }

    public func didMove(to view: UIKit.UIView?) {
        self.view = view
    }
}
#endif

struct _GCUncheckedAction: @unchecked Sendable {
    let run: () -> Void
}

func _gcAsync(_ queue: DispatchQueue, _ body: @escaping () -> Void) {
    let action = _GCUncheckedAction(run: body)
    queue.async { action.run() }
}

let _gcServiceQueue = DispatchQueue(label: "GameController.service")

final class _GCOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: (() -> Void)?

    func store(_ handler: (() -> Void)?) {
        lock.lock()
        pending = handler
        lock.unlock()
    }

    func fireOnce() {
        lock.lock()
        let handler = pending
        pending = nil
        lock.unlock()
        handler?()
    }
}

let _gcDiscoveryOnce = _GCOnce()

final class _GCOnceError: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: (((any Error)?) -> Void)?

    init(_ handler: (((any Error)?) -> Void)?) {
        pending = handler
    }

    func fireOnce(_ error: (any Error)?) {
        lock.lock()
        let handler = pending
        pending = nil
        lock.unlock()
        handler?(error)
    }
}

func _gcHandlerQueue(for element: GCControllerElement) -> DispatchQueue {
    var cursor: GCControllerElement? = element
    while let current = cursor {
        if let device = current.owningProfile?.device {
            return device.handlerQueue
        }
        cursor = current.collection
    }
    return element.owningProfile?.device?.handlerQueue ?? .main
}

func _gcClampUnit(_ value: Float) -> Float {
    min(1, max(-1, value))
}

func _gcClamp01(_ value: Float) -> Float {
    min(1, max(0, value))
}

func _gcLinuxUnsupported(_ reason: String) -> NSError {
    NSError(
        domain: "GameController",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: reason]
    )
}

#if canImport(CoreServices)
@inline(never)
func _gcTouchCoreServices() {
    _ = kUTTypeData
}
#endif

extension NSValue {
    public convenience init(GCPoint2 point: GCPoint2) {
        var copy = point
        self.init(bytes: &copy, objCType: "{GCPoint2=ff}")
    }

    public var gcPoint2Value: GCPoint2 {
        var point = GCPoint2()
        getValue(&point)
        return point
    }
}
