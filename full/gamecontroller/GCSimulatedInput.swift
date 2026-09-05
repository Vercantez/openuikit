import Foundation
import Dispatch

/// Linux simulated HID source. This host has no `/dev/input` joystick nodes,
/// so controllers, keyboards, and mice are published only through this
/// in-process registry. Attach/detach posts the documented `GC*DidConnect` /
/// `DidDisconnect` notifications. Battery, light, and haptics stay nil
/// (fail-closed): the simulated source is not a physical accessory.
public enum GCSimulatedInput {
    private static let lock = NSLock()
    private static var connected: [ObjectIdentifier: GCController] = [:]
    private static var ordered: [GCController] = []
    private static var currentControllerStorage: GCController?
    private static var coalescedKeyboardStorage: GCKeyboard?
    private static var miceByID: [ObjectIdentifier: GCMouse] = [:]
    private static var orderedMice: [GCMouse] = []
    private static var currentMouseStorage: GCMouse?

    public static var linuxEvdevAvailable: Bool {
        FileManager.default.fileExists(atPath: "/dev/input")
    }

    public static func reset() {
        lock.lock()
        connected.removeAll()
        ordered.removeAll()
        currentControllerStorage = nil
        coalescedKeyboardStorage = nil
        miceByID.removeAll()
        orderedMice.removeAll()
        currentMouseStorage = nil
        lock.unlock()
    }

    public static func connectedControllers() -> [GCController] {
        lock.lock()
        let copy = ordered
        lock.unlock()
        return copy
    }

    public static var currentController: GCController? {
        lock.lock()
        let value = currentControllerStorage
        lock.unlock()
        return value
    }

    public static var coalescedKeyboard: GCKeyboard? {
        lock.lock()
        let value = coalescedKeyboardStorage
        lock.unlock()
        return value
    }

    public static func connectedMice() -> [GCMouse] {
        lock.lock()
        let copy = orderedMice
        lock.unlock()
        return copy
    }

    public static var currentMouse: GCMouse? {
        lock.lock()
        let value = currentMouseStorage
        lock.unlock()
        return value
    }

    /// Publishes a non-snapshot controller and posts connect / become-current.
    public static func attach(_ controller: GCController) {
        controller.isSnapshot = false
        controller.input.bind(from: controller.physicalInputProfile)
        lock.lock()
        let id = ObjectIdentifier(controller)
        if connected[id] == nil {
            connected[id] = controller
            ordered.append(controller)
        }
        let previous = currentControllerStorage
        currentControllerStorage = controller
        lock.unlock()
        NotificationCenter.default.post(
            name: .GCControllerDidConnect,
            object: controller
        )
        if previous !== controller {
            if let previous {
                NotificationCenter.default.post(
                    name: .GCControllerDidStopBeingCurrent,
                    object: previous
                )
            }
            NotificationCenter.default.post(
                name: .GCControllerDidBecomeCurrent,
                object: controller
            )
        }
    }

    public static func detach(_ controller: GCController) {
        lock.lock()
        let id = ObjectIdentifier(controller)
        connected.removeValue(forKey: id)
        ordered.removeAll { $0 === controller }
        let wasCurrent = currentControllerStorage === controller
        if wasCurrent {
            currentControllerStorage = ordered.last
        }
        let next = currentControllerStorage
        lock.unlock()
        if wasCurrent {
            NotificationCenter.default.post(
                name: .GCControllerDidStopBeingCurrent,
                object: controller
            )
        }
        NotificationCenter.default.post(
            name: .GCControllerDidDisconnect,
            object: controller
        )
        if wasCurrent, let next {
            NotificationCenter.default.post(
                name: .GCControllerDidBecomeCurrent,
                object: next
            )
        }
    }

    public static func attachKeyboard(_ keyboard: GCKeyboard) {
        lock.lock()
        let previous = coalescedKeyboardStorage
        coalescedKeyboardStorage = keyboard
        lock.unlock()
        if previous !== keyboard {
            if let previous {
                NotificationCenter.default.post(
                    name: .GCKeyboardDidDisconnect,
                    object: previous
                )
            }
            NotificationCenter.default.post(
                name: .GCKeyboardDidConnect,
                object: keyboard
            )
        }
    }

    public static func detachKeyboard(_ keyboard: GCKeyboard) {
        lock.lock()
        let wasCoalesced = coalescedKeyboardStorage === keyboard
        if wasCoalesced {
            coalescedKeyboardStorage = nil
        }
        lock.unlock()
        if wasCoalesced {
            NotificationCenter.default.post(
                name: .GCKeyboardDidDisconnect,
                object: keyboard
            )
        }
    }

    public static func attachMouse(_ mouse: GCMouse) {
        lock.lock()
        let id = ObjectIdentifier(mouse)
        if miceByID[id] == nil {
            miceByID[id] = mouse
            orderedMice.append(mouse)
        }
        let previous = currentMouseStorage
        currentMouseStorage = mouse
        lock.unlock()
        NotificationCenter.default.post(name: .GCMouseDidConnect, object: mouse)
        if previous !== mouse {
            if let previous {
                NotificationCenter.default.post(
                    name: .GCMouseDidStopBeingCurrent,
                    object: previous
                )
            }
            NotificationCenter.default.post(
                name: .GCMouseDidBecomeCurrent,
                object: mouse
            )
        }
    }

    public static func detachMouse(_ mouse: GCMouse) {
        lock.lock()
        let id = ObjectIdentifier(mouse)
        miceByID.removeValue(forKey: id)
        orderedMice.removeAll { $0 === mouse }
        let wasCurrent = currentMouseStorage === mouse
        if wasCurrent {
            currentMouseStorage = orderedMice.last
        }
        let next = currentMouseStorage
        lock.unlock()
        if wasCurrent {
            NotificationCenter.default.post(
                name: .GCMouseDidStopBeingCurrent,
                object: mouse
            )
        }
        NotificationCenter.default.post(name: .GCMouseDidDisconnect, object: mouse)
        if wasCurrent, let next {
            NotificationCenter.default.post(name: .GCMouseDidBecomeCurrent, object: next)
        }
    }

    public static func makeExtendedGamepad(
        vendorName: String = "Simulated Extended Gamepad"
    ) -> GCController {
        let controller = GCController(profile: GCExtendedGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryHID)
        return controller
    }

    public static func makeMicroGamepad(
        vendorName: String = "Simulated Micro Gamepad"
    ) -> GCController {
        let controller = GCController(profile: GCMicroGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryMFi)
        return controller
    }

    public static func makeDualSense(
        vendorName: String = "Simulated DualSense"
    ) -> GCController {
        let controller = GCController(profile: GCDualSenseGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryDualSense)
        return controller
    }

    public static func makeDualShock(
        vendorName: String = "Simulated DualShock"
    ) -> GCController {
        let controller = GCController(profile: GCDualShockGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryDualShock4)
        return controller
    }

    public static func makeXbox(
        vendorName: String = "Simulated Xbox"
    ) -> GCController {
        let controller = GCController(profile: GCXboxGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryXboxOne)
        return controller
    }

    public static func makeDirectionalGamepad(
        vendorName: String = "Simulated Directional Gamepad"
    ) -> GCController {
        let controller = GCController(profile: GCDirectionalGamepad())
        configureLive(controller, vendorName: vendorName, category: GCProductCategoryMFi)
        return controller
    }

    public static func makeKeyboard(
        vendorName: String = "Simulated Keyboard"
    ) -> GCKeyboard {
        let keyboard = GCKeyboard()
        keyboard.simulatedVendorName = vendorName
        return keyboard
    }

    public static func makeMouse(vendorName: String = "Simulated Mouse") -> GCMouse {
        let mouse = GCMouse()
        mouse.simulatedVendorName = vendorName
        return mouse
    }

    public static func applyMotion(
        _ controller: GCController,
        attitude: GCQuaternion,
        rotationRate: GCRotationRate,
        gravity: GCAcceleration,
        userAcceleration: GCAcceleration,
        acceleration: GCAcceleration? = nil
    ) {
        guard let motion = controller.motion else { return }
        motion.sensorsRequireManualActivation = false
        motion.sensorsActive = true
        motion.hasAttitude = true
        motion.hasRotationRate = true
        motion.hasGravityAndUserAcceleration = true
        motion.hasAttitudeAndRotationRate = true
        motion.attitude = attitude
        motion.rotationRate = rotationRate
        motion.gravity = gravity
        motion.userAcceleration = userAcceleration
        motion.acceleration = acceleration ?? GCAcceleration(
            x: gravity.x + userAcceleration.x,
            y: gravity.y + userAcceleration.y,
            z: gravity.z + userAcceleration.z
        )
        motion.valueChangedHandler?(motion)
    }

    public static func pressKey(_ keyboard: GCKeyboard, _ code: GCKeyCode, pressed: Bool) {
        guard let input = keyboard.keyboardInput else { return }
        guard let button = input.button(forKeyCode: code) else { return }
        button.setValue(pressed ? 1 : 0)
        let handler = input.keyChangedHandler
        _gcAsync(keyboard.handlerQueue) {
            handler?(input, button, code, pressed)
        }
    }

    public static func moveMouse(_ mouse: GCMouse, deltaX: Float, deltaY: Float) {
        guard let input = mouse.mouseInput else { return }
        let handler = input.mouseMovedHandler
        _gcAsync(mouse.handlerQueue) {
            handler?(input, deltaX, deltaY)
        }
    }

    private static func configureLive(
        _ controller: GCController,
        vendorName: String,
        category: String
    ) {
        controller.isSnapshot = false
        controller.isAttachedToDevice = false
        controller.vendorName = vendorName
        controller.productCategory = category
        controller.battery = nil
        controller.light = nil
        controller.haptics = nil
        if let motion = controller.motion {
            motion.sensorsRequireManualActivation = false
            motion.sensorsActive = true
            motion.hasAttitude = true
            motion.hasRotationRate = true
            motion.hasGravityAndUserAcceleration = true
            motion.hasAttitudeAndRotationRate = true
        }
        controller.input.bind(from: controller.physicalInputProfile)
    }
}
