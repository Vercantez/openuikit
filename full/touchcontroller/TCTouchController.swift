import Foundation

#if canImport(Metal)
import Metal
#endif
#if canImport(GameController)
import GameController
#endif

/// On-screen touch controller. Software add/remove, layout, hit-testing, and
/// touch routing are real. `connect()` does not publish a `GCController`.
public final class TCTouchController: NSObject {
    public class var isSupported: Bool { TouchControllerLinuxSupport.isSupported }

    public var size: CGSize
    public var drawableSize: CGSize
    public private(set) var isConnected: Bool = false

    private var storedControls: [TCControlBase] = []
    private var activeTouches: [Int: TCControlBase] = [:]

    public init(descriptor: TCTouchControllerDescriptor) {
        size = descriptor.size
        drawableSize = descriptor.drawableSize
        super.init()
    }

#if canImport(Metal)
    public var device: any MTLDevice {
        descriptorDevice
    }

    private var descriptorDevice: any MTLDevice

    public func render(using encoder: any MTLRenderCommandEncoder) {
        _ = encoder
    }
#endif

#if canImport(GameController)
    public var controller: GCController {
        fatalError("TouchController.connect() is fail-closed on Linux; no GCController is published")
    }
#endif

    public var controls: [any TCControl] { storedControls }

    public var buttons: [TCButton] {
        storedControls.compactMap { $0 as? TCButton }
    }

    public var switches: [TCSwitch] {
        storedControls.compactMap { $0 as? TCSwitch }
    }

    public var thumbsticks: [TCThumbstick] {
        storedControls.compactMap { $0 as? TCThumbstick }
    }

    public var directionPads: [TCDirectionPad] {
        storedControls.compactMap { $0 as? TCDirectionPad }
    }

    public var throttles: [TCThrottle] {
        storedControls.compactMap { $0 as? TCThrottle }
    }

    public var touchpads: [TCTouchpad] {
        storedControls.compactMap { $0 as? TCTouchpad }
    }

    public func addButton(descriptor: TCButtonDescriptor) -> TCButton {
        let control = TCButton(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func addSwitch(descriptor: TCSwitchDescriptor) -> TCSwitch {
        let control = TCSwitch(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func addThumbstick(descriptor: TCThumbstickDescriptor) -> TCThumbstick {
        let control = TCThumbstick(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func addDirectionPad(descriptor: TCDirectionPadDescriptor) -> TCDirectionPad {
        let control = TCDirectionPad(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func addThrottle(descriptor: TCThrottleDescriptor) -> TCThrottle {
        let control = TCThrottle(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func addTouchpad(descriptor: TCTouchpadDescriptor) -> TCTouchpad {
        let control = TCTouchpad(descriptor: descriptor, canvas: self)
        storedControls.append(control)
        return control
    }

    public func removeAllControls() {
        storedControls.removeAll()
        activeTouches.removeAll()
    }

    public func removeControl(_ control: any TCControl) {
        storedControls.removeAll { candidate in
            guard let object = control as AnyObject? else { return false }
            return candidate === object
        }
        activeTouches = activeTouches.filter { _, value in
            guard let object = control as AnyObject? else { return true }
            return value !== object
        }
    }

    public func control(at point: CGPoint) -> (any TCControl)? {
        hitControl(at: point, requiringEnabled: false)
    }

    public func handleTouchBegan(at point: CGPoint, index: Int) -> Bool {
        guard let control = hitControl(at: point, requiringEnabled: true) else {
            return false
        }
        control.handleTouchBegan(at: point)
        if control.isPressed {
            activeTouches[index] = control
            return true
        }
        return false
    }

    public func handleTouchMoved(at point: CGPoint, index: Int) -> Bool {
        guard let control = activeTouches[index] else { return false }
        control.handleTouchMoved(at: point)
        return true
    }

    public func handleTouchEnded(at point: CGPoint, index: Int) -> Bool {
        guard let control = activeTouches.removeValue(forKey: index) else {
            return false
        }
        control.handleTouchEnded(at: point)
        return true
    }

    /// Linux automatic layout: known Game Controller labels are placed at
    /// conventional virtual-controller anchors. Apple's exact packing is
    /// unobserved.
    public func automaticallyLayoutControls(for labels: [TCControlLabel]) {
        for label in labels {
            if storedControls.contains(where: { $0.label.name == label.name && $0.label.role == label.role }) {
                continue
            }
            switch label.role {
            case .directionPad:
                let descriptor = TCDirectionPadDescriptor()
                descriptor.compositeLabel = label
                descriptor.size = CGSize(width: 96, height: 96)
                descriptor.anchor = .bottomLeft
                descriptor.anchorCoordinateSystem = .absolute
                descriptor.offset = CGPoint(x: 24, y: -24)
                _ = addDirectionPad(descriptor: descriptor)
            case .button:
                if label.name.contains("Thumbstick") && !label.name.contains("Button") {
                    let descriptor = TCThumbstickDescriptor()
                    descriptor.label = label
                    descriptor.size = CGSize(width: 96, height: 96)
                    descriptor.stickSize = CGSize(width: 48, height: 48)
                    if label.name.hasPrefix("Right") {
                        descriptor.anchor = .bottomRight
                    } else {
                        descriptor.anchor = .bottomLeft
                    }
                    descriptor.anchorCoordinateSystem = .absolute
                    descriptor.offset = CGPoint(x: label.name.hasPrefix("Right") ? -24 : 24, y: -24)
                    _ = addThumbstick(descriptor: descriptor)
                } else {
                    let descriptor = TCButtonDescriptor()
                    descriptor.label = label
                    descriptor.size = CGSize(width: 56, height: 56)
                    descriptor.anchor = Self.buttonAnchor(for: label)
                    descriptor.anchorCoordinateSystem = .absolute
                    descriptor.offset = Self.buttonOffset(for: label)
                    _ = addButton(descriptor: descriptor)
                }
            }
        }
    }

    public func connect() {
        isConnected = false
    }

    public func disconnect() {
        isConnected = false
        for control in storedControls {
            if control.isPressed {
                control.handleTouchEnded(at: control.position)
            }
        }
        activeTouches.removeAll()
    }

    private func hitControl(at point: CGPoint, requiringEnabled: Bool) -> TCControlBase? {
        let hits = storedControls.enumerated().filter { item in
            item.element.contains(point) && (!requiringEnabled || item.element.isEnabled)
        }
        return hits.max { lhs, rhs in
            if lhs.element.zIndex != rhs.element.zIndex {
                return lhs.element.zIndex < rhs.element.zIndex
            }
            return lhs.offset < rhs.offset
        }?.element
    }

    private static func buttonAnchor(for label: TCControlLabel) -> TCControlLayoutAnchor {
        switch label.name {
        case "Left Shoulder", "Left Trigger":
            return .topLeft
        case "Right Shoulder", "Right Trigger":
            return .topRight
        case "Button Menu":
            return .topCenter
        case "Button Options":
            return .topCenter
        default:
            return .bottomRight
        }
    }

    private static func buttonOffset(for label: TCControlLabel) -> CGPoint {
        switch label.name {
        case "Button A":
            return CGPoint(x: -80, y: -40)
        case "Button B":
            return CGPoint(x: -24, y: -96)
        case "Button X":
            return CGPoint(x: -136, y: -96)
        case "Button Y":
            return CGPoint(x: -80, y: -152)
        case "Left Shoulder", "Left Trigger":
            return CGPoint(x: 24, y: 24)
        case "Right Shoulder", "Right Trigger":
            return CGPoint(x: -24, y: 24)
        case "Button Menu":
            return CGPoint(x: -40, y: 16)
        case "Button Options":
            return CGPoint(x: 40, y: 16)
        default:
            return CGPoint(x: -24, y: -24)
        }
    }
}
