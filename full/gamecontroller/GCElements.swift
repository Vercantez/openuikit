import Foundation

public typealias GCControllerAxisValueChangedHandler = (GCControllerAxisInput, Float) -> Void
public typealias GCControllerButtonTouchedChangedHandler = (GCControllerButtonInput, Float, Bool, Bool) -> Void
public typealias GCControllerButtonValueChangedHandler = (GCControllerButtonInput, Float, Bool) -> Void
public typealias GCControllerDirectionPadValueChangedHandler = (GCControllerDirectionPad, Float, Float) -> Void
public typealias GCControllerTouchpadHandler = (GCControllerTouchpad, Float, Float, Float, Bool) -> Void

public typealias GCDeviceAxisInput = GCControllerAxisInput
public typealias GCDeviceButtonInput = GCControllerButtonInput
public typealias GCDeviceDirectionPad = GCControllerDirectionPad
public typealias GCDeviceElement = GCControllerElement
public typealias GCDeviceTouchpad = GCControllerTouchpad

open class GCControllerElement: NSObject {
    public enum SystemGestureState: Int, Sendable, Hashable {
        case enabled = 0
        case alwaysReceive = 1
        case disabled = 2
    }

    open var aliases: Set<String> = []
    open var isAnalog = false
    open var isBoundToSystemGesture = false
    public weak var collection: GCControllerElement?
    open var localizedName: String?
    open var preferredSystemGestureState: SystemGestureState = .enabled
    open var sfSymbolsName: String?
    open var unmappedLocalizedName: String?
    open var unmappedSfSymbolsName: String?
    weak var owningProfile: GCPhysicalInputProfile?

    public override init() {
        super.init()
    }
}

open class GCControllerAxisInput: GCControllerElement {
    open private(set) var value: Float = 0
    open var valueChangedHandler: GCControllerAxisValueChangedHandler?

    public override init() {
        super.init()
        isAnalog = true
    }

    open func setValue(_ value: Float) {
        let clamped = _gcClampUnit(value)
        self.value = clamped
        valueChangedHandler?(self, clamped)
        _gcNotifyProfile(self)
    }
}

open class GCControllerButtonInput: GCControllerElement {
    open private(set) var value: Float = 0
    open var isPressed: Bool { value > 0 }
    open var isTouched: Bool = false
    open var pressedChangedHandler: GCControllerButtonValueChangedHandler?
    open var touchedChangedHandler: GCControllerButtonTouchedChangedHandler?
    open var valueChangedHandler: GCControllerButtonValueChangedHandler?

    open func setValue(_ value: Float) {
        let clamped = _gcClamp01(value)
        let wasPressed = isPressed
        self.value = clamped
        if !isTouched && clamped > 0 {
            isTouched = true
            touchedChangedHandler?(self, clamped, isPressed, true)
        } else if isTouched && clamped == 0 {
            isTouched = false
            touchedChangedHandler?(self, clamped, isPressed, false)
        }
        valueChangedHandler?(self, clamped, isPressed)
        if wasPressed != isPressed {
            pressedChangedHandler?(self, clamped, isPressed)
        }
        _gcNotifyProfile(self)
    }
}

open class GCControllerDirectionPad: GCControllerElement {
    open var xAxis = GCControllerAxisInput()
    open var yAxis = GCControllerAxisInput()
    open var up = GCControllerButtonInput()
    open var down = GCControllerButtonInput()
    open var left = GCControllerButtonInput()
    open var right = GCControllerButtonInput()
    open var valueChangedHandler: GCControllerDirectionPadValueChangedHandler?

    public override init() {
        super.init()
        isAnalog = true
        for child in [xAxis, yAxis, up, down, left, right] as [GCControllerElement] {
            child.collection = self
        }
    }

    open func setValueForXAxis(_ xAxisValue: Float, yAxis yAxisValue: Float) {
        xAxis.setValue(xAxisValue)
        yAxis.setValue(yAxisValue)
        right.setValue(max(0, xAxis.value))
        left.setValue(max(0, -xAxis.value))
        up.setValue(max(0, yAxis.value))
        down.setValue(max(0, -yAxis.value))
        valueChangedHandler?(self, xAxis.value, yAxis.value)
        _gcNotifyProfile(self)
    }
}

open class GCControllerTouchpad: GCControllerElement {
    public enum TouchState: Int, Sendable, Hashable {
        case up = 0
        case down = 1
        case moving = 2
    }

    open var button = GCControllerButtonInput()
    open var reportsAbsoluteTouchSurfaceValues = false
    open var touchDown: GCControllerTouchpadHandler?
    open var touchMoved: GCControllerTouchpadHandler?
    open var touchUp: GCControllerTouchpadHandler?
    open private(set) var touchState: TouchState = .up
    open var touchSurface = GCControllerDirectionPad()

    public override init() {
        super.init()
        button.collection = self
        touchSurface.collection = self
    }

    open func setValueForXAxis(
        _ xAxis: Float,
        yAxis: Float,
        touchDown touchIsDown: Bool,
        buttonValue: Float
    ) {
        let previous = touchState
        touchSurface.setValueForXAxis(xAxis, yAxis: yAxis)
        button.setValue(buttonValue)
        if touchIsDown {
            touchState = previous == .up ? .down : .moving
        } else {
            touchState = .up
        }
        let handler: GCControllerTouchpadHandler?
        switch touchState {
        case .down: handler = touchDown
        case .moving: handler = touchMoved
        case .up: handler = touchUp
        }
        handler?(self, touchSurface.xAxis.value, touchSurface.yAxis.value, button.value, touchIsDown)
        _gcNotifyProfile(self)
    }
}

open class GCDeviceCursor: GCControllerDirectionPad {}

open class GCDualSenseAdaptiveTrigger: GCControllerButtonInput {
    public enum Mode: Int, Sendable, Hashable {
        case off = 0
        case feedback = 1
        case weapon = 2
        case vibration = 3
        case slopeFeedback = 4
    }

    public enum Status: Int, Sendable, Hashable {
        case unknown = 0
        case feedbackNoLoad = 1
        case feedbackLoadApplied = 2
        case weaponReady = 3
        case weaponFiring = 4
        case weaponFired = 5
        case vibrationNotVibrating = 6
        case vibrationIsVibrating = 7
        case slopeFeedbackReady = 8
        case slopeFeedbackApplyingLoad = 9
        case slopeFeedbackFinished = 10
    }

    public struct PositionalAmplitudes {
        public var values: (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float)
        public init(values: (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float)) {
            self.values = values
        }
        public init() {
            self.values = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        }
    }

    public struct PositionalResistiveStrengths {
        public var values: (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float)
        public init(values: (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float)) {
            self.values = values
        }
        public init() {
            self.values = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        }
    }

    open class var discretePositionCount: Int { 10 }
    open private(set) var armPosition: Float = 0
    open private(set) var mode: Mode = .off
    open private(set) var status: Status = .unknown

    public override init() {
        super.init()
    }

    /// Records the requested software mode. No DualSense hardware is present,
    /// so `status` stays `.unknown` and the trigger does not claim a physical effect.
    open func setModeOff() {
        mode = .off
        status = .unknown
    }

    open func setModeFeedbackWithStartPosition(_ startPosition: Float, resistiveStrength: Float) {
        _ = (startPosition, resistiveStrength)
        mode = .feedback
        status = .unknown
    }

    open func setModeFeedback(resistiveStrengths positionalResistiveStrengths: PositionalResistiveStrengths) {
        _ = positionalResistiveStrengths
        mode = .feedback
        status = .unknown
    }

    open func setModeSlopeFeedback(
        startPosition: Float,
        endPosition: Float,
        startStrength: Float,
        endStrength: Float
    ) {
        _ = (startPosition, endPosition, startStrength, endStrength)
        mode = .slopeFeedback
        status = .unknown
    }

    open func setModeVibrationWithStartPosition(_ startPosition: Float, amplitude: Float, frequency: Float) {
        _ = (startPosition, amplitude, frequency)
        mode = .vibration
        status = .unknown
    }

    open func setModeVibration(amplitudes positionalAmplitudes: PositionalAmplitudes, frequency: Float) {
        _ = (positionalAmplitudes, frequency)
        mode = .vibration
        status = .unknown
    }

    open func setModeWeaponWithStartPosition(
        _ startPosition: Float,
        endPosition: Float,
        resistiveStrength: Float
    ) {
        _ = (startPosition, endPosition, resistiveStrength)
        mode = .weapon
        status = .unknown
    }
}

func _gcNotifyProfile(_ element: GCControllerElement) {
    var cursor: GCControllerElement? = element
    while let current = cursor {
        if let profile = current.owningProfile {
            profile.valueDidChangeHandler?(profile, element)
            return
        }
        cursor = current.collection
    }
    element.owningProfile?.valueDidChangeHandler?(element.owningProfile!, element)
}
