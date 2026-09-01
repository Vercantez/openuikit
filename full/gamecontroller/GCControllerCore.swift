import Foundation
import Dispatch

open class GCController: NSObject, GCDevice {
    open var handlerQueue: DispatchQueue = .main
    open var productCategory: String = GCProductCategoryHID
    open var vendorName: String?
    open var playerIndex: GCControllerPlayerIndex = .indexUnset
    open var isAttachedToDevice = false
    open var isSnapshot = false
    open var battery: GCDeviceBattery?
    open var haptics: GCDeviceHaptics?
    open var light: GCDeviceLight?
    open var motion: GCMotion?
    open var controllerPausedHandler: ((GCController) -> Void)?
    open var physicalInputProfile: GCPhysicalInputProfile
    open var input: GCControllerLiveInput
    open var gamepad: GCGamepad?
    open var extendedGamepad: GCExtendedGamepad?
    open var microGamepad: GCMicroGamepad?

    public static var current: GCController? { nil }
    public static var shouldMonitorBackgroundEvents = false

    init(profile: GCPhysicalInputProfile) {
        self.physicalInputProfile = profile
        self.input = GCControllerLiveInput()
        super.init()
        profile.device = self
        input.device = self
        if let extended = profile as? GCExtendedGamepad {
            extended.controller = self
            extendedGamepad = extended
            let classic = GCGamepad()
            classic.controller = self
            classic.device = self
            gamepad = classic
        } else if let classic = profile as? GCGamepad {
            classic.controller = self
            gamepad = classic
        }
        if let micro = profile as? GCMicroGamepad {
            micro.controller = self
            microGamepad = micro
        }
        motion = GCMotion()
        motion?.controller = self
        motion?.sensorsRequireManualActivation = true
        motion?.hasAttitude = false
        motion?.hasRotationRate = false
        motion?.hasGravityAndUserAcceleration = false
        motion?.hasAttitudeAndRotationRate = false
    }

    open class func controllers() -> [GCController] { [] }

    open class func withExtendedGamepad() -> GCController {
        let controller = GCController(profile: GCExtendedGamepad())
        controller.isSnapshot = true
        controller.isAttachedToDevice = false
        controller.vendorName = nil
        controller.productCategory = GCProductCategoryHID
        return controller
    }

    open class func withMicroGamepad() -> GCController {
        let controller = GCController(profile: GCMicroGamepad())
        controller.isSnapshot = true
        controller.isAttachedToDevice = false
        controller.vendorName = nil
        controller.productCategory = GCProductCategoryHID
        return controller
    }

    /// Linux has no GameController wireless discovery service.
    open class func startWirelessControllerDiscovery(completionHandler: (() -> Void)? = nil) {
        completionHandler?()
    }

    open class func stopWirelessControllerDiscovery() {}

    open func capture() -> GCController {
        if let extended = extendedGamepad {
            let copy = GCController.withExtendedGamepad()
            copy.playerIndex = playerIndex
            copy.extendedGamepad?.setStateFrom(extended)
            return copy
        }
        if let micro = microGamepad {
            let copy = GCController.withMicroGamepad()
            copy.playerIndex = playerIndex
            copy.microGamepad?.setStateFrom(micro)
            return copy
        }
        return GCController.withExtendedGamepad()
    }
}

extension GCController {
    public struct DidConnectMessage {
        public typealias Subject = GCController
        public var controller: GCController
        public static var name: Notification.Name { .GCControllerDidConnect }
        public init(controller: GCController) { self.controller = controller }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCController).map { Self(controller: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.controller)
        }
    }

    public struct DidDisconnectMessage {
        public typealias Subject = GCController
        public var controller: GCController
        public static var name: Notification.Name { .GCControllerDidDisconnect }
        public init(controller: GCController) { self.controller = controller }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCController).map { Self(controller: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.controller)
        }
    }

    public struct DidBecomeCurrentMessage {
        public typealias Subject = GCController
        public var controller: GCController
        public static var name: Notification.Name { .GCControllerDidBecomeCurrent }
        public init(controller: GCController) { self.controller = controller }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCController).map { Self(controller: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.controller)
        }
    }

    public struct DidStopBeingCurrentMessage {
        public typealias Subject = GCController
        public var controller: GCController
        public static var name: Notification.Name { .GCControllerDidStopBeingCurrent }
        public init(controller: GCController) { self.controller = controller }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCController).map { Self(controller: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.controller)
        }
    }
}

public typealias GCKeyboardValueChangedHandler = (GCKeyboardInput, GCControllerButtonInput, GCKeyCode, Bool) -> Void
public typealias GCMouseMoved = (GCMouseInput, Float, Float) -> Void

open class GCKeyboardInput: GCPhysicalInputProfile {
    open var isAnyKeyPressed: Bool {
        buttons.values.contains { $0.isPressed }
    }
    open var keyChangedHandler: GCKeyboardValueChangedHandler?
    private var keyButtons: [Int: GCControllerButtonInput] = [:]

    open func button(forKeyCode code: GCKeyCode) -> GCControllerButtonInput? {
        if let existing = keyButtons[code.rawValue] { return existing }
        let button = GCControllerButtonInput()
        button.localizedName = "Key \(code.rawValue)"
        keyButtons[code.rawValue] = button
        register(button, name: "Key \(code.rawValue)")
        return button
    }
}

open class GCKeyboard: NSObject, GCDevice {
    open var handlerQueue: DispatchQueue = .main
    open var productCategory: String { GCProductCategoryKeyboard }
    open var vendorName: String? { nil }
    open var physicalInputProfile: GCPhysicalInputProfile { keyboardInput ?? GCPhysicalInputProfile() }
    open var keyboardInput: GCKeyboardInput? = GCKeyboardInput()
    public static var coalesced: GCKeyboard? { nil }
}

extension GCKeyboard {
    public struct DidConnectMessage {
        public typealias Subject = GCKeyboard
        public var keyboard: GCKeyboard
        public static var name: Notification.Name { .GCKeyboardDidConnect }
        public init(keyboard: GCKeyboard) { self.keyboard = keyboard }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCKeyboard).map { Self(keyboard: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.keyboard)
        }
    }

    public struct DidDisconnectMessage {
        public typealias Subject = GCKeyboard
        public var keyboard: GCKeyboard
        public static var name: Notification.Name { .GCKeyboardDidDisconnect }
        public init(keyboard: GCKeyboard) { self.keyboard = keyboard }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCKeyboard).map { Self(keyboard: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.keyboard)
        }
    }
}

open class GCMouseInput: GCPhysicalInputProfile {
    open var leftButton = GCControllerButtonInput()
    open var middleButton: GCControllerButtonInput? = GCControllerButtonInput()
    open var rightButton: GCControllerButtonInput? = GCControllerButtonInput()
    open var auxiliaryButtons: [GCControllerButtonInput]? = []
    open var mouseMovedHandler: GCMouseMoved?
    open var scroll = GCDeviceCursor()

    override init() {
        super.init()
        register(leftButton, name: "Left Button")
        if let middleButton { register(middleButton, name: "Middle Button") }
        if let rightButton { register(rightButton, name: "Right Button") }
        register(scroll, name: "Scroll")
    }
}

open class GCMouse: NSObject, GCDevice {
    open var handlerQueue: DispatchQueue = .main
    open var productCategory: String { GCProductCategoryMouse }
    open var vendorName: String? { nil }
    open var physicalInputProfile: GCPhysicalInputProfile { mouseInput ?? GCPhysicalInputProfile() }
    open var mouseInput: GCMouseInput? = GCMouseInput()
    public static var current: GCMouse? { nil }
    open class func mice() -> [GCMouse] { [] }
}

extension GCMouse {
    public struct DidConnectMessage {
        public typealias Subject = GCMouse
        public var mouse: GCMouse
        public static var name: Notification.Name { .GCMouseDidConnect }
        public init(mouse: GCMouse) { self.mouse = mouse }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCMouse).map { Self(mouse: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.mouse)
        }
    }

    public struct DidDisconnectMessage {
        public typealias Subject = GCMouse
        public var mouse: GCMouse
        public static var name: Notification.Name { .GCMouseDidDisconnect }
        public init(mouse: GCMouse) { self.mouse = mouse }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCMouse).map { Self(mouse: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.mouse)
        }
    }

    public struct DidBecomeCurrentMessage {
        public typealias Subject = GCMouse
        public var mouse: GCMouse
        public static var name: Notification.Name { .GCMouseDidBecomeCurrent }
        public init(mouse: GCMouse) { self.mouse = mouse }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCMouse).map { Self(mouse: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.mouse)
        }
    }

    public struct DidStopBeingCurrentMessage {
        public typealias Subject = GCMouse
        public var mouse: GCMouse
        public static var name: Notification.Name { .GCMouseDidStopBeingCurrent }
        public init(mouse: GCMouse) { self.mouse = mouse }
        @MainActor public static func makeMessage(_ notification: Notification) -> Self? {
            (notification.object as? GCMouse).map { Self(mouse: $0) }
        }
        @MainActor public static func makeNotification(_ message: Self) -> Notification {
            Notification(name: name, object: message.mouse)
        }
    }
}

open class GCVirtualController: NSObject {
    open class Configuration: NSObject {
        open var elements: Set<String> = []
        open var isHidden = false
    }

    open class ElementConfiguration: NSObject {
        open var actsAsTouchpad = false
        open var isHidden = false
    }

    open var controller: GCController? { nil }
    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }

    open func connect(replyHandler reply: (((any Error)?) -> Void)? = nil) {
        reply?(
            _gcLinuxUnsupported(
                "GCVirtualController cannot inject HID devices on this host"
            )
        )
    }

    open func disconnect() {}

    open func setPosition(_ position: CGPoint, forDirectionPadElement element: String) {
        _ = (position, element)
    }

    open func setValue(_ value: CGFloat, forButtonElement element: String) {
        _ = (value, element)
    }

    open func updateConfiguration(
        forElement element: String,
        configuration config: (ElementConfiguration) -> ElementConfiguration
    ) {
        _ = config(ElementConfiguration())
        _ = element
    }
}
