import Foundation

public typealias GCExtendedGamepadValueChangedHandler = (GCExtendedGamepad, GCControllerElement) -> Void
public typealias GCGamepadValueChangedHandler = (GCGamepad, GCControllerElement) -> Void
public typealias GCMicroGamepadValueChangedHandler = (GCMicroGamepad, GCControllerElement) -> Void
public typealias GCMotionValueChangedHandler = (GCMotion) -> Void

open class GCPhysicalInputProfile: NSObject {
    public weak var device: (any GCDevice)?
    open var hasRemappedElements = false
    open var lastEventTimestamp: TimeInterval = 0
    open var valueDidChangeHandler: ((GCPhysicalInputProfile, GCControllerElement) -> Void)?

    var namedElements: [String: GCControllerElement] = [:]

    public required override init() {
        super.init()
    }

    open var elements: [String: GCControllerElement] { namedElements }
    open var axes: [String: GCControllerAxisInput] {
        Dictionary(uniqueKeysWithValues: namedElements.compactMap { key, value in
            (value as? GCControllerAxisInput).map { (key, $0) }
        })
    }
    open var buttons: [String: GCControllerButtonInput] {
        Dictionary(uniqueKeysWithValues: namedElements.compactMap { key, value in
            (value as? GCControllerButtonInput).map { (key, $0) }
        })
    }
    open var dpads: [String: GCControllerDirectionPad] {
        Dictionary(uniqueKeysWithValues: namedElements.compactMap { key, value in
            (value as? GCControllerDirectionPad).map { (key, $0) }
        })
    }
    open var touchpads: [String: GCControllerTouchpad] {
        Dictionary(uniqueKeysWithValues: namedElements.compactMap { key, value in
            (value as? GCControllerTouchpad).map { (key, $0) }
        })
    }

    open var allElements: Set<GCControllerElement> { Set(namedElements.values) }
    open var allAxes: Set<GCControllerAxisInput> { Set(axes.values) }
    open var allButtons: Set<GCControllerButtonInput> { Set(buttons.values) }
    open var allDpads: Set<GCControllerDirectionPad> { Set(dpads.values) }
    open var allTouchpads: Set<GCControllerTouchpad> { Set(touchpads.values) }

    public subscript(key: String) -> GCControllerElement? { namedElements[key] }

    func register(_ element: GCControllerElement, name: String, aliases extra: [String] = []) {
        namedElements[name] = element
        element.aliases = Set([name] + extra)
        element.localizedName = name
        element.unmappedLocalizedName = name
        element.owningProfile = self
    }

    open func capture() -> Self {
        let copy = type(of: self).init()
        copy.setStateFromPhysicalInput(self)
        copy.lastEventTimestamp = lastEventTimestamp
        copy.hasRemappedElements = hasRemappedElements
        copy.device = device
        return copy
    }

    open func mappedElementAlias(forPhysicalInputName inputName: String) -> String {
        inputName
    }

    open func mappedPhysicalInputNames(forElementAlias elementAlias: String) -> Set<String> {
        [elementAlias]
    }

    open func setStateFromPhysicalInput(_ physicalInput: GCPhysicalInputProfile) {
        for (name, source) in physicalInput.namedElements {
            guard let destination = namedElements[name] else { continue }
            _gcCopyElement(source, onto: destination)
        }
    }
}

open class GCGamepad: GCPhysicalInputProfile {
    public weak var controller: GCController?
    open var buttonA = GCControllerButtonInput()
    open var buttonB = GCControllerButtonInput()
    open var buttonX = GCControllerButtonInput()
    open var buttonY = GCControllerButtonInput()
    open var dpad = GCControllerDirectionPad()
    open var leftShoulder = GCControllerButtonInput()
    open var rightShoulder = GCControllerButtonInput()
    open var valueChangedHandler: GCGamepadValueChangedHandler?

    public required init() {
        super.init()
        register(buttonA, name: GCInputButtonA)
        register(buttonB, name: GCInputButtonB)
        register(buttonX, name: GCInputButtonX)
        register(buttonY, name: GCInputButtonY)
        register(dpad, name: GCInputDirectionPad)
        register(leftShoulder, name: GCInputLeftShoulder)
        register(rightShoulder, name: GCInputRightShoulder)
        buttonA.isAnalog = true
        buttonB.isAnalog = true
        buttonX.isAnalog = true
        buttonY.isAnalog = true
        leftShoulder.isAnalog = true
        rightShoulder.isAnalog = true
        valueDidChangeHandler = { [weak self] _, element in
            guard let self else { return }
            self.valueChangedHandler?(self, element)
        }
    }

    open func saveSnapshot() -> GCGamepadSnapshot {
        var data = _gcGamepadSnapshot(self)
        return GCGamepadSnapshot(snapshotData: NSDataFromGCGamepadSnapShotDataV100(&data) ?? Data())
    }
}

open class GCExtendedGamepad: GCPhysicalInputProfile {
    public weak var controller: GCController?
    open var buttonA = GCControllerButtonInput()
    open var buttonB = GCControllerButtonInput()
    open var buttonX = GCControllerButtonInput()
    open var buttonY = GCControllerButtonInput()
    open var buttonMenu = GCControllerButtonInput()
    open var buttonOptions: GCControllerButtonInput? = GCControllerButtonInput()
    open var buttonHome: GCControllerButtonInput? = GCControllerButtonInput()
    open var dpad = GCControllerDirectionPad()
    open var leftShoulder = GCControllerButtonInput()
    open var rightShoulder = GCControllerButtonInput()
    open var leftTrigger = GCControllerButtonInput()
    open var rightTrigger = GCControllerButtonInput()
    open var leftThumbstick = GCControllerDirectionPad()
    open var rightThumbstick = GCControllerDirectionPad()
    open var leftThumbstickButton: GCControllerButtonInput? = GCControllerButtonInput()
    open var rightThumbstickButton: GCControllerButtonInput? = GCControllerButtonInput()
    open var valueChangedHandler: GCExtendedGamepadValueChangedHandler?

    public required init() {
        super.init()
        register(buttonA, name: GCInputButtonA)
        register(buttonB, name: GCInputButtonB)
        register(buttonX, name: GCInputButtonX)
        register(buttonY, name: GCInputButtonY)
        register(buttonMenu, name: GCInputButtonMenu)
        if let buttonOptions { register(buttonOptions, name: GCInputButtonOptions) }
        if let buttonHome { register(buttonHome, name: GCInputButtonHome) }
        register(dpad, name: GCInputDirectionPad)
        register(leftShoulder, name: GCInputLeftShoulder)
        register(rightShoulder, name: GCInputRightShoulder)
        register(leftTrigger, name: GCInputLeftTrigger)
        register(rightTrigger, name: GCInputRightTrigger)
        register(leftThumbstick, name: GCInputLeftThumbstick)
        register(rightThumbstick, name: GCInputRightThumbstick)
        if let leftThumbstickButton { register(leftThumbstickButton, name: GCInputLeftThumbstickButton) }
        if let rightThumbstickButton { register(rightThumbstickButton, name: GCInputRightThumbstickButton) }
        buttonA.isAnalog = true
        buttonB.isAnalog = true
        buttonX.isAnalog = true
        buttonY.isAnalog = true
        buttonMenu.isAnalog = false
        buttonOptions?.isAnalog = false
        buttonHome?.isAnalog = false
        leftShoulder.isAnalog = true
        rightShoulder.isAnalog = true
        leftTrigger.isAnalog = true
        rightTrigger.isAnalog = true
        leftThumbstickButton?.isAnalog = false
        rightThumbstickButton?.isAnalog = false
        valueDidChangeHandler = { [weak self] _, element in
            guard let self else { return }
            self.valueChangedHandler?(self, element)
        }
    }

    open func saveSnapshot() -> GCExtendedGamepadSnapshot {
        var data = _gcExtendedSnapshot(self)
        return GCExtendedGamepadSnapshot(snapshotData: NSDataFromGCExtendedGamepadSnapshotData(&data) ?? Data())
    }

    open func setStateFrom(_ extendedGamepad: GCExtendedGamepad) {
        setStateFromPhysicalInput(extendedGamepad)
    }
}

open class GCMicroGamepad: GCPhysicalInputProfile {
    public weak var controller: GCController?
    open var allowsRotation = false
    open var reportsAbsoluteDpadValues = false
    open var buttonA = GCControllerButtonInput()
    open var buttonX = GCControllerButtonInput()
    open var buttonMenu = GCControllerButtonInput()
    open var dpad = GCControllerDirectionPad()
    open var valueChangedHandler: GCMicroGamepadValueChangedHandler?

    public required init() {
        super.init()
        register(buttonA, name: GCInputMicroGamepadButtonA, aliases: [GCInputButtonA])
        register(buttonX, name: GCInputMicroGamepadButtonX, aliases: [GCInputButtonX])
        register(buttonMenu, name: GCInputMicroGamepadButtonMenu, aliases: [GCInputButtonMenu])
        register(dpad, name: GCInputMicroGamepadDpad, aliases: [GCInputDirectionPad])
        buttonA.isAnalog = true
        buttonX.isAnalog = true
        buttonMenu.isAnalog = false
        valueDidChangeHandler = { [weak self] _, element in
            guard let self else { return }
            self.valueChangedHandler?(self, element)
        }
    }

    open func saveSnapshot() -> GCMicroGamepadSnapshot {
        var data = _gcMicroSnapshot(self)
        return GCMicroGamepadSnapshot(snapshotData: NSDataFromGCMicroGamepadSnapshotData(&data) ?? Data())
    }

    open func setStateFrom(_ microGamepad: GCMicroGamepad) {
        setStateFromPhysicalInput(microGamepad)
    }
}

open class GCDirectionalGamepad: GCMicroGamepad {}

open class GCDualShockGamepad: GCExtendedGamepad {
    open var touchpadButton: GCControllerButtonInput! = GCControllerButtonInput()
    open var touchpadPrimary: GCControllerDirectionPad! = GCControllerDirectionPad()
    open var touchpadSecondary: GCControllerDirectionPad! = GCControllerDirectionPad()

    public required init() {
        super.init()
        if let touchpadButton { register(touchpadButton, name: GCInputDualShockTouchpadButton) }
        if let touchpadPrimary { register(touchpadPrimary, name: GCInputDualShockTouchpadOne) }
        if let touchpadSecondary { register(touchpadSecondary, name: GCInputDualShockTouchpadTwo) }
    }
}

open class GCDualSenseGamepad: GCExtendedGamepad {
    open var touchpadButton = GCControllerButtonInput()
    open var touchpadPrimary = GCControllerDirectionPad()
    open var touchpadSecondary = GCControllerDirectionPad()

    /// DualSense adaptive triggers occupy the extended-gamepad trigger slots.
    open var leftAdaptiveTrigger: GCDualSenseAdaptiveTrigger {
        leftTrigger as! GCDualSenseAdaptiveTrigger
    }
    open var rightAdaptiveTrigger: GCDualSenseAdaptiveTrigger {
        rightTrigger as! GCDualSenseAdaptiveTrigger
    }

    public required init() {
        super.init()
        leftTrigger = GCDualSenseAdaptiveTrigger()
        rightTrigger = GCDualSenseAdaptiveTrigger()
        register(leftTrigger, name: GCInputLeftTrigger)
        register(rightTrigger, name: GCInputRightTrigger)
        register(touchpadButton, name: GCInputDualShockTouchpadButton)
        register(touchpadPrimary, name: GCInputDualShockTouchpadOne)
        register(touchpadSecondary, name: GCInputDualShockTouchpadTwo)
    }
}

open class GCXboxGamepad: GCExtendedGamepad {
    open var buttonShare: GCControllerButtonInput? = GCControllerButtonInput()
    open var paddleButton1: GCControllerButtonInput? = GCControllerButtonInput()
    open var paddleButton2: GCControllerButtonInput? = GCControllerButtonInput()
    open var paddleButton3: GCControllerButtonInput? = GCControllerButtonInput()
    open var paddleButton4: GCControllerButtonInput? = GCControllerButtonInput()

    public required init() {
        super.init()
        if let buttonShare { register(buttonShare, name: GCInputButtonShare) }
        if let paddleButton1 { register(paddleButton1, name: GCInputXboxPaddleOne) }
        if let paddleButton2 { register(paddleButton2, name: GCInputXboxPaddleTwo) }
        if let paddleButton3 { register(paddleButton3, name: GCInputXboxPaddleThree) }
        if let paddleButton4 { register(paddleButton4, name: GCInputXboxPaddleFour) }
    }
}

open class GCMotion: NSObject {
    public weak var controller: GCController?
    open var acceleration = GCAcceleration()
    open var attitude = GCQuaternion()
    open var gravity = GCAcceleration()
    open var rotationRate = GCRotationRate()
    open var userAcceleration = GCAcceleration()
    open var hasAttitude = false
    open var hasAttitudeAndRotationRate = false
    open var hasGravityAndUserAcceleration = false
    open var hasRotationRate = false
    open var sensorsActive = false
    open var sensorsRequireManualActivation = true
    open var valueChangedHandler: GCMotionValueChangedHandler?

    /// Software-only setter used by snapshots. Does not claim IMU hardware.
    open func setAcceleration(_ acceleration: GCAcceleration) {
        self.acceleration = acceleration
        valueChangedHandler?(self)
    }

    open func setAttitude(_ attitude: GCQuaternion) {
        self.attitude = attitude
        valueChangedHandler?(self)
    }

    open func setGravity(_ gravity: GCAcceleration) {
        self.gravity = gravity
        valueChangedHandler?(self)
    }

    open func setRotationRate(_ rotationRate: GCRotationRate) {
        self.rotationRate = rotationRate
        valueChangedHandler?(self)
    }

    open func setUserAcceleration(_ userAcceleration: GCAcceleration) {
        self.userAcceleration = userAcceleration
        valueChangedHandler?(self)
    }

    open func setStateFrom(_ motion: GCMotion) {
        acceleration = motion.acceleration
        attitude = motion.attitude
        gravity = motion.gravity
        rotationRate = motion.rotationRate
        userAcceleration = motion.userAcceleration
        hasAttitude = motion.hasAttitude
        hasAttitudeAndRotationRate = motion.hasAttitudeAndRotationRate
        hasGravityAndUserAcceleration = motion.hasGravityAndUserAcceleration
        hasRotationRate = motion.hasRotationRate
        valueChangedHandler?(self)
    }
}

func _gcCopyElement(_ source: GCControllerElement, onto destination: GCControllerElement) {
    switch (source, destination) {
    case let (src as GCControllerButtonInput, dst as GCControllerButtonInput):
        dst.setValue(src.value)
    case let (src as GCControllerAxisInput, dst as GCControllerAxisInput):
        dst.setValue(src.value)
    case let (src as GCControllerDirectionPad, dst as GCControllerDirectionPad):
        dst.setValueForXAxis(src.xAxis.value, yAxis: src.yAxis.value)
    case let (src as GCControllerTouchpad, dst as GCControllerTouchpad):
        dst.setValueForXAxis(
            src.touchSurface.xAxis.value,
            yAxis: src.touchSurface.yAxis.value,
            touchDown: src.touchState != .up,
            buttonValue: src.button.value
        )
    default:
        break
    }
}

func _gcGamepadSnapshot(_ gamepad: GCGamepad) -> GCGamepadSnapShotDataV100 {
    GCGamepadSnapShotDataV100(
        version: 0x100,
        size: 36,
        dpadX: gamepad.dpad.xAxis.value,
        dpadY: gamepad.dpad.yAxis.value,
        buttonA: gamepad.buttonA.value,
        buttonB: gamepad.buttonB.value,
        buttonX: gamepad.buttonX.value,
        buttonY: gamepad.buttonY.value,
        leftShoulder: gamepad.leftShoulder.value,
        rightShoulder: gamepad.rightShoulder.value
    )
}

func _gcExtendedSnapshot(_ gamepad: GCExtendedGamepad) -> GCExtendedGamepadSnapshotData {
    GCExtendedGamepadSnapshotData(
        version: UInt16(GCCurrentExtendedGamepadSnapshotDataVersion.rawValue),
        size: 80,
        dpadX: gamepad.dpad.xAxis.value,
        dpadY: gamepad.dpad.yAxis.value,
        buttonA: gamepad.buttonA.value,
        buttonB: gamepad.buttonB.value,
        buttonX: gamepad.buttonX.value,
        buttonY: gamepad.buttonY.value,
        leftShoulder: gamepad.leftShoulder.value,
        rightShoulder: gamepad.rightShoulder.value,
        leftThumbstickX: gamepad.leftThumbstick.xAxis.value,
        leftThumbstickY: gamepad.leftThumbstick.yAxis.value,
        rightThumbstickX: gamepad.rightThumbstick.xAxis.value,
        rightThumbstickY: gamepad.rightThumbstick.yAxis.value,
        leftTrigger: gamepad.leftTrigger.value,
        rightTrigger: gamepad.rightTrigger.value,
        supportsClickableThumbsticks: ObjCBool(true),
        leftThumbstickButton: ObjCBool(gamepad.leftThumbstickButton?.isPressed ?? false),
        rightThumbstickButton: ObjCBool(gamepad.rightThumbstickButton?.isPressed ?? false)
    )
}

func _gcMicroSnapshot(_ gamepad: GCMicroGamepad) -> GCMicroGamepadSnapshotData {
    GCMicroGamepadSnapshotData(
        version: UInt16(GCCurrentMicroGamepadSnapshotDataVersion.rawValue),
        size: 20,
        dpadX: gamepad.dpad.xAxis.value,
        dpadY: gamepad.dpad.yAxis.value,
        buttonA: gamepad.buttonA.value,
        buttonX: gamepad.buttonX.value
    )
}
