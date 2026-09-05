import Foundation
import Dispatch
import GameController

// --- GCButtonAxisTests.swift ---
func testButtonAxisDpadHandlers() {
    final class Box: @unchecked Sendable {
        var handlerQueueHonored = false
        var handlerFireCount = 0
        var pressedFireCount = 0
        var touchedFireCount = 0
    }
    let box = Box()
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let handlerQueue = DispatchQueue(label: "gc.button.handler")
    let handlerKey = DispatchSpecificKey<UInt8>()
    handlerQueue.setSpecific(key: handlerKey, value: 7)
    snapshot.handlerQueue = handlerQueue
    let pad = snapshot.extendedGamepad!

    precondition(pad.buttonA.value == 0)
    precondition(!pad.buttonA.isPressed)
    precondition(pad.buttonA.isAnalog)

    let handlerGate = DispatchSemaphore(value: 0)
    pad.buttonA.valueChangedHandler = { _, _, _ in
        box.handlerFireCount += 1
        box.handlerQueueHonored = DispatchQueue.getSpecific(key: handlerKey) == 7
        handlerGate.signal()
    }
    pad.buttonA.pressedChangedHandler = { _, _, _ in
        box.pressedFireCount += 1
    }
    pad.buttonA.touchedChangedHandler = { _, _, _, _ in
        box.touchedFireCount += 1
    }
    pad.buttonA.setValue(1)
    precondition(pad.buttonA.isPressed)
    precondition(pad.buttonA.value == 1)
    precondition(pad.buttonA.isTouched)
    precondition(handlerGate.wait(timeout: .now() + 2) == .success)
    precondition(box.handlerFireCount == 1)
    precondition(box.handlerQueueHonored)

    pad.leftThumbstick.setValueForXAxis(0.5, yAxis: -0.25)
    precondition(abs(pad.leftThumbstick.xAxis.value - 0.5) < 0.0001)
    precondition(abs(pad.leftThumbstick.yAxis.value + 0.25) < 0.0001)
    precondition(pad.leftThumbstick.right.isPressed)
    precondition(!pad.leftThumbstick.left.isPressed)
    precondition(pad.leftThumbstick.down.isPressed)
    precondition(!pad.leftThumbstick.up.isPressed)
    precondition(!pad.leftThumbstick.up.isAnalog)
    precondition(pad.leftThumbstick.xAxis.isAnalog)
    pad.leftThumbstick.valueChangedHandler = { _, _, _ in }
    pad.leftThumbstick.xAxis.valueChangedHandler = { _, _ in }
    pad.leftThumbstick.xAxis.setValue(0.1)

    _ = pad.buttonA.collection
    _ = pad.buttonA.isBoundToSystemGesture
    _ = pad.buttonA.preferredSystemGestureState
    _ = pad.buttonA.sfSymbolsName
    _ = pad.buttonA.localizedName
    _ = pad.buttonA.unmappedLocalizedName
    _ = pad.buttonA.unmappedSfSymbolsName
    _ = pad.buttonA.aliases
    _ = GCControllerElement.self
    _ = GCControllerButtonInput.self
    _ = GCControllerAxisInput.self
    _ = GCControllerDirectionPad.self
    GCSimulatedInput.reset()
}


// --- GCCollectionTests.swift ---
func testPhysicalInputElementCollection() {
    GCSimulatedInput.reset()
    let empty = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
    precondition(empty.startIndex == empty.endIndex)
    let emptyIdx = empty.startIndex
    precondition(emptyIdx == empty.endIndex)
    precondition(emptyIdx <= empty.endIndex)
    _ = emptyIdx..<empty.endIndex
    _ = ..<empty.endIndex
    precondition(empty[GCButtonElementName.a] == nil)
    precondition(empty[GCAxisElementName(rawValue: "x")] == nil)
    precondition(empty[GCSwitchElementName(rawValue: "s")] == nil)
    precondition(empty[GCPhysicalInputElementName(rawValue: "p")] == nil)
    precondition(empty[GCDirectionPadElementName.directionPad] == nil)
    precondition(empty[GCInputButtonA] == nil)

    let simulated = GCSimulatedInput.makeExtendedGamepad()
    let buttons = simulated.input.buttons
    let start = buttons.startIndex
    precondition(start < buttons.endIndex)
    _ = buttons[start]
    _ = buttons.index(after: start)
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.self
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.Index.self
    GCSimulatedInput.reset()
}


// --- GCColorTests.swift ---
func testGCColorComponents() {
    let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
    precondition(color.red == 0.1)
    precondition(color.green == 0.2)
    precondition(color.blue == 0.3)
    do {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        color.encode(with: coder)
        let data = coder.encodedData
        let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
        _ = GCColor(coder: decoder)
    } catch {
        _ = error
    }
    _ = GCColor.self
}


// --- GCControllerTests.swift ---
func testControllerRegistryAndNotifications() {
    final class Box: @unchecked Sendable {
        var discoveryCount = 0
        var connected: Notification?
        var disconnected: Notification?
        var becameCurrent: Notification?
    }
    let box = Box()
    GCSimulatedInput.reset()
    precondition(!GCSimulatedInput.linuxEvdevAvailable)
    precondition(GCController.controllers().isEmpty)
    precondition(GCController.current == nil)

    let discoveryGate = DispatchSemaphore(value: 0)
    GCController.startWirelessControllerDiscovery {
        box.discoveryCount += 1
        discoveryGate.signal()
    }
    precondition(box.discoveryCount == 0)
    precondition(discoveryGate.wait(timeout: .now() + 2) == .success)
    precondition(box.discoveryCount == 1)
    GCController.stopWirelessControllerDiscovery()

    let snapshot = GCController.withExtendedGamepad()
    precondition(snapshot.isSnapshot)
    precondition(!snapshot.isAttachedToDevice)
    precondition(snapshot.extendedGamepad != nil)
    precondition(snapshot.gamepad != nil)
    precondition(snapshot.motion != nil)
    precondition(snapshot.haptics == nil)
    precondition(snapshot.battery == nil)
    precondition(snapshot.light == nil)
    precondition(snapshot.productCategory == GCProductCategoryHID)
    precondition(snapshot.vendorName == nil)
    precondition(snapshot.playerIndex == .indexUnset)
    precondition(GCController.controllers().isEmpty)

    snapshot.playerIndex = .index1
    precondition(snapshot.playerIndex == .index1)
    snapshot.controllerPausedHandler = { _ in }
    _ = snapshot.physicalInputProfile
    _ = snapshot.input

    let handlerQueue = DispatchQueue(label: "gc.controller.handler")
    snapshot.handlerQueue = handlerQueue
    precondition(snapshot.handlerQueue === handlerQueue)

    GCController.shouldMonitorBackgroundEvents = true
    precondition(GCController.shouldMonitorBackgroundEvents)

    let nc = NotificationCenter.default
    let tok1 = nc.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { box.connected = $0 }
    let tok2 = nc.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { box.disconnected = $0 }
    let tok3 = nc.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: nil) { box.becameCurrent = $0 }

    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    precondition(GCController.controllers().contains(where: { $0 === simulated }))
    precondition(GCController.current === simulated)
    precondition(box.connected?.object as? GCController === simulated)
    precondition(box.becameCurrent?.object as? GCController === simulated)
    precondition(!simulated.isSnapshot)
    let captured = simulated.capture()
    precondition(captured.isSnapshot)

    GCSimulatedInput.detach(simulated)
    precondition(box.disconnected?.object as? GCController === simulated || box.disconnected != nil)
    nc.removeObserver(tok1)
    nc.removeObserver(tok2)
    nc.removeObserver(tok3)
    GCSimulatedInput.reset()
    precondition(GCController.controllers().isEmpty)
    _ = GCController.self
}


// --- GCDeviceAccessoryTests.swift ---
func testBatteryLightHapticsTypes() {
    let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
    let battery = GCDeviceBattery(level: 0, state: .unknown)
    precondition(battery.batteryLevel == 0)
    precondition(battery.batteryState == .unknown)
    let light = GCDeviceLight(color: color)
    precondition(light.color.red == color.red)
    let haptics = GCDeviceHaptics()
    precondition(haptics.supportedLocalities.isEmpty)
    let activation = GCGameControllerActivationContext()
    precondition(activation.previousApplicationBundleID == nil)
    _ = GCDeviceBattery.self
    _ = GCDeviceLight.self
    _ = GCDeviceHaptics.self
    _ = GCGameControllerActivationContext.self
}


// --- GCDualSenseTests.swift ---
func testDualSenseXboxDualShockAndTouchpad() {
    GCSimulatedInput.reset()
    let dual = GCDualSenseAdaptiveTrigger()
    dual.setModeFeedbackWithStartPosition(0.2, resistiveStrength: 0.8)
    precondition(dual.mode == .feedback)
    precondition(dual.status == .unknown)
    _ = dual.armPosition
    _ = GCDualSenseAdaptiveTrigger.discretePositionCount
    dual.setModeFeedback(resistiveStrengths: GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths())
    dual.setModeSlopeFeedback(startPosition: 0.1, endPosition: 0.9, startStrength: 0.2, endStrength: 0.8)
    dual.setModeVibrationWithStartPosition(0.1, amplitude: 0.5, frequency: 10)
    dual.setModeVibration(amplitudes: GCDualSenseAdaptiveTrigger.PositionalAmplitudes(), frequency: 12)
    dual.setModeWeaponWithStartPosition(0.1, endPosition: 0.7, resistiveStrength: 0.4)
    dual.setModeOff()
    precondition(dual.mode == .off)
    let amplitudes = GCDualSenseAdaptiveTrigger.PositionalAmplitudes(values: (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9))
    _ = amplitudes.values
    let strengths = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths(values: (1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1))
    _ = strengths.values
    _ = GCDualSenseAdaptiveTrigger.PositionalAmplitudes()
    _ = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths()

    let dualSense = GCSimulatedInput.makeDualSense()
    GCSimulatedInput.attach(dualSense)
    precondition(dualSense.productCategory == GCProductCategoryDualSense)
    let dsPad = dualSense.extendedGamepad as? GCDualSenseGamepad
    precondition(dsPad != nil)
    _ = dsPad?.touchpadButton
    _ = dsPad?.touchpadPrimary
    _ = dsPad?.touchpadSecondary
    _ = dsPad?.leftTrigger
    _ = dsPad?.rightTrigger
    dsPad?.leftAdaptiveTrigger.setModeFeedbackWithStartPosition(0.2, resistiveStrength: 0.5)
    precondition(dsPad?.leftAdaptiveTrigger.mode == .feedback)
    _ = dsPad?.rightAdaptiveTrigger
    _ = dsPad?.saveSnapshot()

    let dualShock = GCSimulatedInput.makeDualShock()
    let ds4 = dualShock.extendedGamepad as? GCDualShockGamepad
    precondition(ds4?.touchpadButton != nil)
    _ = ds4?.touchpadPrimary
    _ = ds4?.touchpadSecondary
    _ = ds4?.saveSnapshot()

    let xbox = GCSimulatedInput.makeXbox()
    let xb = xbox.extendedGamepad as? GCXboxGamepad
    _ = xb?.buttonShare
    _ = xb?.paddleButton1
    _ = xb?.paddleButton2
    _ = xb?.paddleButton3
    _ = xb?.paddleButton4
    _ = xb?.saveSnapshot()
    precondition(xbox.productCategory == GCProductCategoryXboxOne)

    let touchpad = GCControllerTouchpad()
    touchpad.reportsAbsoluteTouchSurfaceValues = true
    touchpad.touchDown = { _, _, _, _, _ in }
    touchpad.touchMoved = { _, _, _, _, _ in }
    touchpad.touchUp = { _, _, _, _, _ in }
    touchpad.setValueForXAxis(0.4, yAxis: 0.5, touchDown: true, buttonValue: 0.6)
    precondition(touchpad.touchState == .down)
    touchpad.setValueForXAxis(0.7, yAxis: 0.1, touchDown: true, buttonValue: 0.2)
    precondition(touchpad.touchState == .moving)
    touchpad.setValueForXAxis(0, yAxis: 0, touchDown: false, buttonValue: 0)
    precondition(touchpad.touchState == .up)
    _ = touchpad.button
    _ = touchpad.touchSurface
    GCSimulatedInput.detach(dualSense)
    GCSimulatedInput.reset()
}


// --- GCElementNameTests.swift ---
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


// --- GCEnumTests.swift ---
func testEnumAndOptionSetMembers() {
    _ = GCControllerPlayerIndex.self
    _ = GCDeviceBattery.State.self
    _ = GCDevicePhysicalInputElementChange.self
    _ = GCDualSenseAdaptiveTrigger.Mode.self
    _ = GCDualSenseAdaptiveTrigger.Status.self
    _ = GCExtendedGamepadSnapshotDataVersion.self
    _ = GCMicroGamepadSnapshotDataVersion.self
    _ = GCControllerElement.SystemGestureState.self
    _ = GCControllerTouchpad.TouchState.self
    _ = GCPhysicalInputSourceDirection.self
    _ = GCUIEventTypes.self
    precondition(GCControllerPlayerIndex.indexUnset.rawValue == -1)
    precondition(GCControllerPlayerIndex.index1.rawValue == 0)
    precondition(GCControllerPlayerIndex.index2.rawValue == 1)
    precondition(GCControllerPlayerIndex.index3.rawValue == 2)
    precondition(GCControllerPlayerIndex.index4.rawValue == 3)
    precondition(GCDeviceBattery.State.unknown.rawValue == 0)
    precondition(GCDeviceBattery.State.discharging.rawValue == 1)
    precondition(GCDeviceBattery.State.charging.rawValue == 2)
    precondition(GCDeviceBattery.State.full.rawValue == 3)
    precondition(GCDevicePhysicalInputElementChange.unknownChange.rawValue == -1)
    precondition(GCDevicePhysicalInputElementChange.noChange.rawValue == 0)
    precondition(GCDevicePhysicalInputElementChange.changed.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Mode.off.rawValue == 0)
    precondition(GCDualSenseAdaptiveTrigger.Mode.feedback.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Mode.weapon.rawValue == 2)
    precondition(GCDualSenseAdaptiveTrigger.Mode.vibration.rawValue == 3)
    precondition(GCDualSenseAdaptiveTrigger.Mode.slopeFeedback.rawValue == 4)
    precondition(GCDualSenseAdaptiveTrigger.Status.unknown.rawValue == 0)
    precondition(GCDualSenseAdaptiveTrigger.Status.feedbackNoLoad.rawValue == 1)
    precondition(GCDualSenseAdaptiveTrigger.Status.feedbackLoadApplied.rawValue == 2)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponReady.rawValue == 3)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponFiring.rawValue == 4)
    precondition(GCDualSenseAdaptiveTrigger.Status.weaponFired.rawValue == 5)
    precondition(GCDualSenseAdaptiveTrigger.Status.vibrationNotVibrating.rawValue == 6)
    precondition(GCDualSenseAdaptiveTrigger.Status.vibrationIsVibrating.rawValue == 7)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackReady.rawValue == 8)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackApplyingLoad.rawValue == 9)
    precondition(GCDualSenseAdaptiveTrigger.Status.slopeFeedbackFinished.rawValue == 10)
    precondition(GCExtendedGamepadSnapshotDataVersion.version1.rawValue == 1)
    precondition(GCExtendedGamepadSnapshotDataVersion.version2.rawValue == 2)
    precondition(GCMicroGamepadSnapshotDataVersion.version1.rawValue == 1)
    precondition(GCControllerElement.SystemGestureState.enabled.rawValue == 0)
    precondition(GCControllerElement.SystemGestureState.alwaysReceive.rawValue == 1)
    precondition(GCControllerElement.SystemGestureState.disabled.rawValue == 2)
    precondition(GCControllerTouchpad.TouchState.up.rawValue == 0)
    precondition(GCControllerTouchpad.TouchState.down.rawValue == 1)
    precondition(GCControllerTouchpad.TouchState.moving.rawValue == 2)
    precondition(GCPhysicalInputSourceDirection.up.rawValue == 1 << 0)
    precondition(GCPhysicalInputSourceDirection.down.rawValue == 1 << 1)
    precondition(GCPhysicalInputSourceDirection.left.rawValue == 1 << 2)
    precondition(GCPhysicalInputSourceDirection.right.rawValue == 1 << 3)
    precondition(GCUIEventTypes.gamepad.rawValue == 1 << 0)
    precondition(GCControllerPlayerIndex.index1 != .index2)
    precondition(GCDeviceBattery.State.charging != .full)
    precondition(GCDevicePhysicalInputElementChange.changed != .noChange)
    precondition(GCDualSenseAdaptiveTrigger.Mode.off != .feedback)
    precondition(GCDualSenseAdaptiveTrigger.Status.unknown != .weaponReady)
    precondition(GCExtendedGamepadSnapshotDataVersion.version1 != .version2)
    precondition(GCMicroGamepadSnapshotDataVersion(rawValue: 99) == nil)
    precondition(GCControllerElement.SystemGestureState.enabled != .disabled)
    precondition(GCControllerTouchpad.TouchState.up != .down)
    precondition(GCPhysicalInputSourceDirection.up != .down)
    precondition(GCUIEventTypes.gamepad != GCUIEventTypes())
    _ = GCPhysicalInputSourceDirection()
    _ = GCPhysicalInputSourceDirection(rawValue: 1)
    _ = GCUIEventTypes()
    _ = GCUIEventTypes(rawValue: 1)
    _ = GCControllerPlayerIndex(rawValue: 0)
    _ = GCDeviceBattery.State(rawValue: 0)
    _ = GCDevicePhysicalInputElementChange(rawValue: 0)
    _ = GCDualSenseAdaptiveTrigger.Mode(rawValue: 0)
    _ = GCDualSenseAdaptiveTrigger.Status(rawValue: 0)
    _ = GCExtendedGamepadSnapshotDataVersion(rawValue: 1)
    _ = GCMicroGamepadSnapshotDataVersion(rawValue: 1)
    _ = GCControllerElement.SystemGestureState(rawValue: 0)
    _ = GCControllerTouchpad.TouchState(rawValue: 0)
    var hasher = Hasher()
    GCControllerPlayerIndex.indexUnset.hash(into: &hasher)
    GCControllerPlayerIndex.index1.hash(into: &hasher)
    GCControllerPlayerIndex.index2.hash(into: &hasher)
    GCControllerPlayerIndex.index3.hash(into: &hasher)
    GCControllerPlayerIndex.index4.hash(into: &hasher)
    GCDeviceBattery.State.charging.hash(into: &hasher)
    GCDevicePhysicalInputElementChange.changed.hash(into: &hasher)
    GCDualSenseAdaptiveTrigger.Mode.off.hash(into: &hasher)
    GCDualSenseAdaptiveTrigger.Status.unknown.hash(into: &hasher)
    GCExtendedGamepadSnapshotDataVersion.version1.hash(into: &hasher)
    GCMicroGamepadSnapshotDataVersion.version1.hash(into: &hasher)
    GCControllerElement.SystemGestureState.enabled.hash(into: &hasher)
    GCControllerTouchpad.TouchState.up.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Set([GCControllerPlayerIndex.index1, .index2, .index3, .index4, .indexUnset])
    _ = Set([GCDeviceBattery.State.unknown, .charging, .discharging, .full])
    _ = Set([GCDevicePhysicalInputElementChange.changed, .noChange, .unknownChange])
    _ = Set([GCDualSenseAdaptiveTrigger.Mode.off, .feedback, .weapon, .vibration, .slopeFeedback])
    _ = Set([
        GCDualSenseAdaptiveTrigger.Status.unknown,
        .feedbackNoLoad, .feedbackLoadApplied,
        .weaponReady, .weaponFiring, .weaponFired,
        .vibrationNotVibrating, .vibrationIsVibrating,
        .slopeFeedbackReady, .slopeFeedbackApplyingLoad, .slopeFeedbackFinished
    ])
}


// --- GCEventOptionsTests.swift ---
func testEventHandlingOptions() {
    _ = GameControllerEventHandlingOptions()
    _ = GameControllerEventHandlingOptions.receivesEventsInView(true)
    var options = GameControllerEventHandlingOptions()
    options.receivesEventsInView = true
    precondition(options.receivesEventsInView)
    _ = GameControllerEventHandlingOptions.self
}


// --- GCGamepadFamilyTests.swift ---
func testGamepadProfileFamilies() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let pad = snapshot.extendedGamepad!
    _ = pad.controller
    _ = pad.buttonA
    _ = pad.buttonB
    _ = pad.buttonX
    _ = pad.buttonY
    _ = pad.buttonHome
    _ = pad.buttonMenu
    _ = pad.buttonOptions
    _ = pad.leftShoulder
    _ = pad.rightShoulder
    _ = pad.leftTrigger
    _ = pad.rightTrigger
    _ = pad.leftThumbstick
    _ = pad.rightThumbstick
    _ = pad.leftThumbstickButton
    _ = pad.rightThumbstickButton
    _ = pad.dpad
    pad.valueChangedHandler = { _, _ in }
    _ = pad.saveSnapshot()
    pad.setStateFrom(pad)

    if let gamepad = snapshot.gamepad {
        _ = gamepad.saveSnapshot()
        _ = gamepad.buttonA
        _ = gamepad.buttonB
        _ = gamepad.buttonX
        _ = gamepad.buttonY
        _ = gamepad.dpad
        _ = gamepad.leftShoulder
        _ = gamepad.rightShoulder
        _ = gamepad.controller
        gamepad.valueChangedHandler = { _, _ in }
    }

    let micro = GCController.withMicroGamepad()
    precondition(micro.microGamepad != nil)
    micro.microGamepad?.buttonA.setValue(1)
    precondition(micro.microGamepad?.buttonA.isPressed == true)
    micro.microGamepad?.allowsRotation = true
    micro.microGamepad?.reportsAbsoluteDpadValues = true
    precondition(micro.microGamepad?.allowsRotation == true)
    _ = micro.microGamepad?.buttonX
    _ = micro.microGamepad?.buttonMenu
    _ = micro.microGamepad?.dpad
    _ = micro.microGamepad?.controller
    micro.microGamepad?.valueChangedHandler = { _, _ in }
    _ = micro.microGamepad?.saveSnapshot()
    if let otherMicro = GCController.withMicroGamepad().microGamepad, let liveMicro = micro.microGamepad {
        liveMicro.setStateFrom(otherMicro)
    }

    let directional = GCSimulatedInput.makeDirectionalGamepad()
    precondition(directional.microGamepad is GCDirectionalGamepad)
    _ = GCDirectionalGamepad.self
    _ = GCGamepad.self
    _ = GCExtendedGamepad.self
    _ = GCMicroGamepad.self
    GCSimulatedInput.reset()
}


// --- GCGeometryTests.swift ---
func testGeometryAndNSValue() {
    let point = GCPoint2Make(1.5, -2)
    precondition(GCPoint2Equal(point, GCPoint2(x: 1.5, y: -2)))
    precondition(!GCPoint2Equal(point, GCPoint2Zero))
    _ = point.x
    _ = point.y
    _ = GCPoint2()
    _ = NSStringFromGCPoint2(point)
    let boxed = NSValue(GCPoint2: point)
    precondition(GCPoint2Equal(boxed.gcPoint2Value, point))
    _ = GCPoint2.self
}


// --- GCInputNameTests.swift ---
func testDeviceInputNameConstants() {
    precondition(GCProductCategoryArcadeStick == "Arcade Stick")
    precondition(GCProductCategoryCoalescedRemote == "Coalesced Remote")
    precondition(GCProductCategoryControlCenterRemote == "Control Center Remote")
    precondition(GCProductCategoryDualSense == "DualSense")
    precondition(GCProductCategoryDualShock4 == "DualShock4")
    precondition(GCProductCategoryHID == "HID")
    precondition(GCProductCategoryKeyboard == "Keyboard")
    precondition(GCProductCategoryMFi == "MFi")
    precondition(GCProductCategoryMouse == "Mouse")
    precondition(GCProductCategorySiriRemote1stGen == "Siri Remote 1st Gen")
    precondition(GCProductCategorySiriRemote2ndGen == "Siri Remote 2nd Gen")
    precondition(GCProductCategorySpatialController == "Spatial Controller")
    precondition(GCProductCategoryUniversalElectronicsRemote == "Universal Electronics Remote")
    precondition(GCProductCategoryXboxOne == "Xbox One")
    precondition(GCInputDirectionalCardinalDpad == "Cardinal D-pad")
    precondition(GCInputDirectionalCenterButton == "Center Button")
    precondition(GCInputDirectionalDpad == "Directional D-pad")
    precondition(GCInputDirectionalTouchSurfaceButton == "Touch Surface Button")
    precondition(GCInputMicroGamepadButtonA == "Button A")
    precondition(GCInputMicroGamepadButtonMenu == "Button Menu")
    precondition(GCInputMicroGamepadButtonX == "Button X")
    precondition(GCInputMicroGamepadDpad == "Direction Pad")
    precondition(GCInputButtonA == "Button A")
    precondition(GCInputButtonB == "Button B")
    precondition(GCInputButtonX == "Button X")
    precondition(GCInputButtonY == "Button Y")
    precondition(GCInputButtonHome == "Button Home")
    precondition(GCInputButtonMenu == "Button Menu")
    precondition(GCInputButtonShare == "Button Share")
    precondition(GCInputButtonOptions == "Button Options")
    precondition(GCInputLeftTrigger == "Left Trigger")
    precondition(GCInputRightTrigger == "Right Trigger")
    precondition(GCInputLeftShoulder == "Left Shoulder")
    precondition(GCInputRightShoulder == "Right Shoulder")
    precondition(GCInputDirectionPad == "Direction Pad")
    precondition(GCInputLeftThumbstick == "Left Thumbstick")
    precondition(GCInputRightThumbstick == "Right Thumbstick")
    precondition(GCInputLeftThumbstickButton == "Left Thumbstick Button")
    precondition(GCInputRightThumbstickButton == "Right Thumbstick Button")
    precondition(GCInputXboxPaddleOne == "Paddle 1")
    precondition(GCInputXboxPaddleTwo == "Paddle 2")
    precondition(GCInputXboxPaddleThree == "Paddle 3")
    precondition(GCInputXboxPaddleFour == "Paddle 4")
    precondition(GCInputDualShockTouchpadOne == "Touchpad 1")
    precondition(GCInputDualShockTouchpadTwo == "Touchpad 2")
    precondition(GCInputDualShockTouchpadButton == "Touchpad Button")
    precondition(kIOHIDGCSyntheticDeviceKey == "GCSyntheticDevice")
    precondition(GCCurrentExtendedGamepadSnapshotDataVersion == .version2)
    precondition(GCCurrentMicroGamepadSnapshotDataVersion == .version1)
    precondition(GCHapticDurationInfinite == -1)
    precondition(GCHapticsLocality.all.rawValue == "All")
    precondition(GCHapticsLocality.`default`.rawValue == "Default")
    precondition(GCHapticsLocality.handles.rawValue == "Handles")
    precondition(GCHapticsLocality.leftHandle.rawValue == "LeftHandle")
    precondition(GCHapticsLocality.rightHandle.rawValue == "RightHandle")
    precondition(GCHapticsLocality.triggers.rawValue == "Triggers")
    precondition(GCHapticsLocality.leftTrigger.rawValue == "LeftTrigger")
    precondition(GCHapticsLocality.rightTrigger.rawValue == "RightTrigger")
    precondition(GCHapticsLocality.all != .handles)
    _ = GCHapticsLocality(rawValue: "All")
    _ = GCHapticsLocality.self
    var hasher = Hasher()
    GCHapticsLocality.all.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Set([GCHapticsLocality.all, .default, .handles, .leftHandle, .rightHandle, .triggers, .leftTrigger, .rightTrigger])
}


// --- GCKeyCodeTests.swift ---
func testHIDKeyCodeValues() {
    _ = GCKeyCode.self
    precondition(GCKeyCode.application.rawValue == 101)
    precondition(GCKeyCode.backslash.rawValue == 49)
    precondition(GCKeyCode.capsLock.rawValue == 57)
    precondition(GCKeyCode.closeBracket.rawValue == 48)
    precondition(GCKeyCode.comma.rawValue == 54)
    precondition(GCKeyCode.deleteForward.rawValue == 76)
    precondition(GCKeyCode.deleteOrBackspace.rawValue == 42)
    precondition(GCKeyCode.downArrow.rawValue == 81)
    precondition(GCKeyCode.eight.rawValue == 37)
    precondition(GCKeyCode.end.rawValue == 77)
    precondition(GCKeyCode.equalSign.rawValue == 46)
    precondition(GCKeyCode.escape.rawValue == 41)
    precondition(GCKeyCode.F1.rawValue == 58)
    precondition(GCKeyCode.F10.rawValue == 67)
    precondition(GCKeyCode.F11.rawValue == 68)
    precondition(GCKeyCode.F12.rawValue == 69)
    precondition(GCKeyCode.F13.rawValue == 104)
    precondition(GCKeyCode.F14.rawValue == 105)
    precondition(GCKeyCode.F15.rawValue == 106)
    precondition(GCKeyCode.F16.rawValue == 107)
    precondition(GCKeyCode.F17.rawValue == 108)
    precondition(GCKeyCode.F18.rawValue == 109)
    precondition(GCKeyCode.F19.rawValue == 110)
    precondition(GCKeyCode.F2.rawValue == 59)
    precondition(GCKeyCode.F20.rawValue == 111)
    precondition(GCKeyCode.F3.rawValue == 60)
    precondition(GCKeyCode.F4.rawValue == 61)
    precondition(GCKeyCode.F5.rawValue == 62)
    precondition(GCKeyCode.F6.rawValue == 63)
    precondition(GCKeyCode.F7.rawValue == 64)
    precondition(GCKeyCode.F8.rawValue == 65)
    precondition(GCKeyCode.F9.rawValue == 66)
    precondition(GCKeyCode.five.rawValue == 34)
    precondition(GCKeyCode.four.rawValue == 33)
    precondition(GCKeyCode.graveAccentAndTilde.rawValue == 53)
    precondition(GCKeyCode.home.rawValue == 74)
    precondition(GCKeyCode.hyphen.rawValue == 45)
    precondition(GCKeyCode.insert.rawValue == 73)
    precondition(GCKeyCode.international1.rawValue == 135)
    precondition(GCKeyCode.international2.rawValue == 136)
    precondition(GCKeyCode.international3.rawValue == 137)
    precondition(GCKeyCode.international4.rawValue == 138)
    precondition(GCKeyCode.international5.rawValue == 139)
    precondition(GCKeyCode.international6.rawValue == 140)
    precondition(GCKeyCode.international7.rawValue == 141)
    precondition(GCKeyCode.international8.rawValue == 142)
    precondition(GCKeyCode.international9.rawValue == 143)
    precondition(GCKeyCode.keyA.rawValue == 4)
    precondition(GCKeyCode.keyB.rawValue == 5)
    precondition(GCKeyCode.keyC.rawValue == 6)
    precondition(GCKeyCode.keyD.rawValue == 7)
    precondition(GCKeyCode.keyE.rawValue == 8)
    precondition(GCKeyCode.keyF.rawValue == 9)
    precondition(GCKeyCode.keyG.rawValue == 10)
    precondition(GCKeyCode.keyH.rawValue == 11)
    precondition(GCKeyCode.keyI.rawValue == 12)
    precondition(GCKeyCode.keyJ.rawValue == 13)
    precondition(GCKeyCode.keyK.rawValue == 14)
    precondition(GCKeyCode.keyL.rawValue == 15)
    precondition(GCKeyCode.keyM.rawValue == 16)
    precondition(GCKeyCode.keyN.rawValue == 17)
    precondition(GCKeyCode.keyO.rawValue == 18)
    precondition(GCKeyCode.keyP.rawValue == 19)
    precondition(GCKeyCode.keyQ.rawValue == 20)
    precondition(GCKeyCode.keyR.rawValue == 21)
    precondition(GCKeyCode.keyS.rawValue == 22)
    precondition(GCKeyCode.keyT.rawValue == 23)
    precondition(GCKeyCode.keyU.rawValue == 24)
    precondition(GCKeyCode.keyV.rawValue == 25)
    precondition(GCKeyCode.keyW.rawValue == 26)
    precondition(GCKeyCode.keyX.rawValue == 27)
    precondition(GCKeyCode.keyY.rawValue == 28)
    precondition(GCKeyCode.keyZ.rawValue == 29)
    precondition(GCKeyCode.keypad0.rawValue == 98)
    precondition(GCKeyCode.keypad1.rawValue == 89)
    precondition(GCKeyCode.keypad2.rawValue == 90)
    precondition(GCKeyCode.keypad3.rawValue == 91)
    precondition(GCKeyCode.keypad4.rawValue == 92)
    precondition(GCKeyCode.keypad5.rawValue == 93)
    precondition(GCKeyCode.keypad6.rawValue == 94)
    precondition(GCKeyCode.keypad7.rawValue == 95)
    precondition(GCKeyCode.keypad8.rawValue == 96)
    precondition(GCKeyCode.keypad9.rawValue == 97)
    precondition(GCKeyCode.keypadAsterisk.rawValue == 85)
    precondition(GCKeyCode.keypadEnter.rawValue == 88)
    precondition(GCKeyCode.keypadEqualSign.rawValue == 103)
    precondition(GCKeyCode.keypadHyphen.rawValue == 86)
    precondition(GCKeyCode.keypadNumLock.rawValue == 83)
    precondition(GCKeyCode.keypadPeriod.rawValue == 99)
    precondition(GCKeyCode.keypadPlus.rawValue == 87)
    precondition(GCKeyCode.keypadSlash.rawValue == 84)
    precondition(GCKeyCode.LANG1.rawValue == 144)
    precondition(GCKeyCode.LANG2.rawValue == 145)
    precondition(GCKeyCode.LANG3.rawValue == 146)
    precondition(GCKeyCode.LANG4.rawValue == 147)
    precondition(GCKeyCode.LANG5.rawValue == 148)
    precondition(GCKeyCode.LANG6.rawValue == 149)
    precondition(GCKeyCode.LANG7.rawValue == 150)
    precondition(GCKeyCode.LANG8.rawValue == 151)
    precondition(GCKeyCode.LANG9.rawValue == 152)
    precondition(GCKeyCode.leftAlt.rawValue == 226)
    precondition(GCKeyCode.leftArrow.rawValue == 80)
    precondition(GCKeyCode.leftControl.rawValue == 224)
    precondition(GCKeyCode.leftGUI.rawValue == 227)
    precondition(GCKeyCode.leftShift.rawValue == 225)
    precondition(GCKeyCode.nine.rawValue == 38)
    precondition(GCKeyCode.nonUSBackslash.rawValue == 100)
    precondition(GCKeyCode.nonUSPound.rawValue == 50)
    precondition(GCKeyCode.one.rawValue == 30)
    precondition(GCKeyCode.openBracket.rawValue == 47)
    precondition(GCKeyCode.pageDown.rawValue == 78)
    precondition(GCKeyCode.pageUp.rawValue == 75)
    precondition(GCKeyCode.pause.rawValue == 72)
    precondition(GCKeyCode.period.rawValue == 55)
    precondition(GCKeyCode.power.rawValue == 102)
    precondition(GCKeyCode.printScreen.rawValue == 70)
    precondition(GCKeyCode.quote.rawValue == 52)
    precondition(GCKeyCode.returnOrEnter.rawValue == 40)
    precondition(GCKeyCode.rightAlt.rawValue == 230)
    precondition(GCKeyCode.rightArrow.rawValue == 79)
    precondition(GCKeyCode.rightControl.rawValue == 228)
    precondition(GCKeyCode.rightGUI.rawValue == 231)
    precondition(GCKeyCode.rightShift.rawValue == 229)
    precondition(GCKeyCode.scrollLock.rawValue == 71)
    precondition(GCKeyCode.semicolon.rawValue == 51)
    precondition(GCKeyCode.seven.rawValue == 36)
    precondition(GCKeyCode.six.rawValue == 35)
    precondition(GCKeyCode.slash.rawValue == 56)
    precondition(GCKeyCode.spacebar.rawValue == 44)
    precondition(GCKeyCode.tab.rawValue == 43)
    precondition(GCKeyCode.three.rawValue == 32)
    precondition(GCKeyCode.two.rawValue == 31)
    precondition(GCKeyCode.upArrow.rawValue == 82)
    precondition(GCKeyCode.zero.rawValue == 39)
    precondition(GCKeyCode.keyA != .keyB)
    precondition(GCKeyCode.keyA.rawValue == 0x04)
    precondition(GCKeyCode.escape.rawValue == 0x29)
    _ = GCKeyCode(rawValue: 4)
    var hasher = Hasher()
    GCKeyCode.keyA.hash(into: &hasher)
    _ = hasher.finalize()
    var hashed = Set<GCKeyCode>()
    hashed.insert(.keyA)
    hashed.insert(.escape)
    precondition(hashed.count == 2)
}


// --- GCKeyNameTests.swift ---
func testHIDKeyNameStrings() {
    precondition(GCKeyA == "A")
    precondition(GCKeyApplication == "Application")
    precondition(GCKeyB == "B")
    precondition(GCKeyBackslash == "Backslash")
    precondition(GCKeyC == "C")
    precondition(GCKeyCapsLock == "CapsLock")
    precondition(GCKeyCloseBracket == "CloseBracket")
    precondition(GCKeyComma == "Comma")
    precondition(GCKeyD == "D")
    precondition(GCKeyDeleteForward == "DeleteForward")
    precondition(GCKeyDeleteOrBackspace == "DeleteOrBackspace")
    precondition(GCKeyDownArrow == "DownArrow")
    precondition(GCKeyE == "E")
    precondition(GCKeyEight == "Eight")
    precondition(GCKeyEnd == "End")
    precondition(GCKeyEqualSign == "EqualSign")
    precondition(GCKeyEscape == "Escape")
    precondition(GCKeyF == "F")
    precondition(GCKeyF1 == "F1")
    precondition(GCKeyF10 == "F10")
    precondition(GCKeyF11 == "F11")
    precondition(GCKeyF12 == "F12")
    precondition(GCKeyF13 == "F13")
    precondition(GCKeyF14 == "F14")
    precondition(GCKeyF15 == "F15")
    precondition(GCKeyF16 == "F16")
    precondition(GCKeyF17 == "F17")
    precondition(GCKeyF18 == "F18")
    precondition(GCKeyF19 == "F19")
    precondition(GCKeyF2 == "F2")
    precondition(GCKeyF20 == "F20")
    precondition(GCKeyF3 == "F3")
    precondition(GCKeyF4 == "F4")
    precondition(GCKeyF5 == "F5")
    precondition(GCKeyF6 == "F6")
    precondition(GCKeyF7 == "F7")
    precondition(GCKeyF8 == "F8")
    precondition(GCKeyF9 == "F9")
    precondition(GCKeyFive == "Five")
    precondition(GCKeyFour == "Four")
    precondition(GCKeyG == "G")
    precondition(GCKeyGraveAccentAndTilde == "GraveAccentAndTilde")
    precondition(GCKeyH == "H")
    precondition(GCKeyHome == "Home")
    precondition(GCKeyHyphen == "Hyphen")
    precondition(GCKeyI == "I")
    precondition(GCKeyInsert == "Insert")
    precondition(GCKeyInternational1 == "International1")
    precondition(GCKeyInternational2 == "International2")
    precondition(GCKeyInternational3 == "International3")
    precondition(GCKeyInternational4 == "International4")
    precondition(GCKeyInternational5 == "International5")
    precondition(GCKeyInternational6 == "International6")
    precondition(GCKeyInternational7 == "International7")
    precondition(GCKeyInternational8 == "International8")
    precondition(GCKeyInternational9 == "International9")
    precondition(GCKeyJ == "J")
    precondition(GCKeyK == "K")
    precondition(GCKeyKeypad0 == "Keypad0")
    precondition(GCKeyKeypad1 == "Keypad1")
    precondition(GCKeyKeypad2 == "Keypad2")
    precondition(GCKeyKeypad3 == "Keypad3")
    precondition(GCKeyKeypad4 == "Keypad4")
    precondition(GCKeyKeypad5 == "Keypad5")
    precondition(GCKeyKeypad6 == "Keypad6")
    precondition(GCKeyKeypad7 == "Keypad7")
    precondition(GCKeyKeypad8 == "Keypad8")
    precondition(GCKeyKeypad9 == "Keypad9")
    precondition(GCKeyKeypadAsterisk == "KeypadAsterisk")
    precondition(GCKeyKeypadEnter == "KeypadEnter")
    precondition(GCKeyKeypadEqualSign == "KeypadEqualSign")
    precondition(GCKeyKeypadHyphen == "KeypadHyphen")
    precondition(GCKeyKeypadNumLock == "KeypadNumLock")
    precondition(GCKeyKeypadPeriod == "KeypadPeriod")
    precondition(GCKeyKeypadPlus == "KeypadPlus")
    precondition(GCKeyKeypadSlash == "KeypadSlash")
    precondition(GCKeyL == "L")
    precondition(GCKeyLANG1 == "LANG1")
    precondition(GCKeyLANG2 == "LANG2")
    precondition(GCKeyLANG3 == "LANG3")
    precondition(GCKeyLANG4 == "LANG4")
    precondition(GCKeyLANG5 == "LANG5")
    precondition(GCKeyLANG6 == "LANG6")
    precondition(GCKeyLANG7 == "LANG7")
    precondition(GCKeyLANG8 == "LANG8")
    precondition(GCKeyLANG9 == "LANG9")
    precondition(GCKeyLeftAlt == "LeftAlt")
    precondition(GCKeyLeftArrow == "LeftArrow")
    precondition(GCKeyLeftControl == "LeftControl")
    precondition(GCKeyLeftGUI == "LeftGUI")
    precondition(GCKeyLeftShift == "LeftShift")
    precondition(GCKeyM == "M")
    precondition(GCKeyN == "N")
    precondition(GCKeyNine == "Nine")
    precondition(GCKeyNonUSBackslash == "NonUSBackslash")
    precondition(GCKeyNonUSPound == "NonUSPound")
    precondition(GCKeyO == "O")
    precondition(GCKeyOne == "One")
    precondition(GCKeyOpenBracket == "OpenBracket")
    precondition(GCKeyP == "P")
    precondition(GCKeyPageDown == "PageDown")
    precondition(GCKeyPageUp == "PageUp")
    precondition(GCKeyPause == "Pause")
    precondition(GCKeyPeriod == "Period")
    precondition(GCKeyPower == "Power")
    precondition(GCKeyPrintScreen == "PrintScreen")
    precondition(GCKeyQ == "Q")
    precondition(GCKeyQuote == "Quote")
    precondition(GCKeyR == "R")
    precondition(GCKeyReturnOrEnter == "ReturnOrEnter")
    precondition(GCKeyRightAlt == "RightAlt")
    precondition(GCKeyRightArrow == "RightArrow")
    precondition(GCKeyRightControl == "RightControl")
    precondition(GCKeyRightGUI == "RightGUI")
    precondition(GCKeyRightShift == "RightShift")
    precondition(GCKeyS == "S")
    precondition(GCKeyScrollLock == "ScrollLock")
    precondition(GCKeySemicolon == "Semicolon")
    precondition(GCKeySeven == "Seven")
    precondition(GCKeySix == "Six")
    precondition(GCKeySlash == "Slash")
    precondition(GCKeySpacebar == "Spacebar")
    precondition(GCKeyT == "T")
    precondition(GCKeyTab == "Tab")
    precondition(GCKeyThree == "Three")
    precondition(GCKeyTwo == "Two")
    precondition(GCKeyU == "U")
    precondition(GCKeyUpArrow == "UpArrow")
    precondition(GCKeyV == "V")
    precondition(GCKeyW == "W")
    precondition(GCKeyX == "X")
    precondition(GCKeyY == "Y")
    precondition(GCKeyZ == "Z")
    precondition(GCKeyZero == "Zero")
}


// --- GCKeyboardMouseTests.swift ---
func testCoalescedKeyboardAndMouse() {
    GCSimulatedInput.reset()
    precondition(GCKeyboard.coalesced == nil)
    precondition(GCMouse.current == nil)
    precondition(GCMouse.mice().isEmpty)

    let keyboard = GCSimulatedInput.makeKeyboard()
    GCSimulatedInput.attachKeyboard(keyboard)
    precondition(GCKeyboard.coalesced === keyboard)
    precondition(keyboard.productCategory == GCProductCategoryKeyboard)
    precondition(keyboard.vendorName == "Simulated Keyboard")
    _ = keyboard.physicalInputProfile
    let keyInput = keyboard.keyboardInput!
    _ = keyInput.button(forKeyCode: .keyA)
    GCSimulatedInput.pressKey(keyboard, .keyA, pressed: true)
    precondition(keyInput.isAnyKeyPressed)
    keyInput.keyChangedHandler = { _, _, _, _ in }
    GCSimulatedInput.pressKey(keyboard, .keyA, pressed: false)
    _ = GCKeyboard.self
    _ = GCKeyboardInput.self

    let mouse = GCSimulatedInput.makeMouse()
    GCSimulatedInput.attachMouse(mouse)
    precondition(GCMouse.current === mouse)
    precondition(GCMouse.mice().contains(where: { $0 === mouse }))
    let mouseInput = mouse.mouseInput!
    _ = mouseInput.leftButton
    _ = mouseInput.middleButton
    _ = mouseInput.rightButton
    _ = mouseInput.auxiliaryButtons
    _ = mouseInput.scroll
    mouseInput.mouseMovedHandler = { _, _, _ in }
    GCSimulatedInput.moveMouse(mouse, deltaX: 3, deltaY: -4)
    mouseInput.leftButton.setValue(1)
    precondition(mouseInput.leftButton.isPressed)
    let cursor = GCDeviceCursor()
    cursor.setValueForXAxis(0.1, yAxis: 0.2)
    _ = GCMouse.self
    _ = GCMouseInput.self
    _ = GCDeviceCursor.self

    GCSimulatedInput.detachKeyboard(keyboard)
    GCSimulatedInput.detachMouse(mouse)
    GCSimulatedInput.reset()
}


// --- GCLiveInputTests.swift ---
func testLiveInputAndPhysicalElementProtocols() {
    final class Box: @unchecked Sendable {
        var available = 0
        var streamCount = 0
    }
    let box = Box()
    GCSimulatedInput.reset()
    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    let handlerQueue = DispatchQueue(label: "gc.live.handler")
    simulated.handlerQueue = handlerQueue

    let live = simulated.input
    live.inputStateQueueDepth = 8
    live.queue = handlerQueue
    _ = live.unmapped
    _ = live.device
    _ = live.lastEventLatency
    _ = live.lastEventTimestamp
    _ = live.switches
    _ = live.elements
    _ = live.axes
    _ = live.dpads
    _ = live.buttons
    _ = live[GCInputButtonA]
    live.elementValueDidChangeHandler = { _, _ in }
    live.inputStateAvailableHandler = { _ in box.available += 1 }

    let device: any GCDevice = simulated
    _ = device.handlerQueue
    _ = device.physicalInputProfile
    _ = device.productCategory
    _ = device.vendorName

    if let button = live.buttons[GCButtonElementName.a] {
        _ = button.aliases
        _ = button.localizedName
        _ = button.sfSymbolsName
        _ = button.forceInput
        _ = button.pressedInput.value
        _ = button.pressedInput.isPressed
        _ = button.pressedInput.isAnalog
        _ = button.pressedInput.canWrap
        _ = button.pressedInput.lastValueTimestamp
        _ = button.pressedInput.lastValueLatency
        _ = button.pressedInput.sources
        _ = button.pressedInput.lastPressedStateTimestamp
        _ = button.pressedInput.lastPressedStateLatency
        button.pressedInput.valueDidChangeHandler = { _, _, _ in }
        button.pressedInput.pressedDidChangeHandler = { _, _, _ in }
        if let touched = button.touchedInput {
            _ = touched.isTouched
            _ = touched.sources
            _ = touched.lastTouchedStateTimestamp
            _ = touched.lastTouchedStateLatency
            touched.touchedDidChangeHandler = { _, _, _ in }
        }
    }

    if let dpad = live.dpads[GCDirectionPadElementName.leftThumbstick] {
        _ = dpad.up
        _ = dpad.down
        _ = dpad.left
        _ = dpad.right
        _ = dpad.xAxis.value
        _ = dpad.xAxis.isAnalog
        _ = dpad.xAxis.canWrap
        _ = dpad.xAxis.lastValueTimestamp
        _ = dpad.xAxis.lastValueLatency
        _ = dpad.xAxis.sources
        dpad.xAxis.valueDidChangeHandler = { _, _, _ in }
        _ = dpad.yAxis
        _ = dpad.xyAxes.value
        _ = dpad.xyAxes.isAnalog
        _ = dpad.xyAxes.canWrap
        _ = dpad.xyAxes.lastValueTimestamp
        _ = dpad.xyAxes.lastValueLatency
        _ = dpad.xyAxes.sources
        dpad.xyAxes.valueDidChangeHandler = { _, _, _ in }
    }

    let axisIndex = live.axes.startIndex
    if axisIndex != live.axes.endIndex {
        let axis = live.axes[axisIndex]
        _ = axis.absoluteInput?.value
        _ = axis.relativeInput.delta
        _ = axis.relativeInput.isAnalog
        _ = axis.relativeInput.lastDeltaTimestamp
        _ = axis.relativeInput.lastDeltaLatency
        _ = axis.relativeInput.sources
        axis.relativeInput.deltaDidChangeHandler = { _, _, _ in }
    }

    simulated.extendedGamepad?.buttonB.setValue(0.75)
    precondition(simulated.extendedGamepad?.buttonB.isPressed == true)
    let queued = live.nextInputState()
    precondition(queued != nil)
    _ = queued?.lastEventTimestamp
    _ = queued?.lastEventLatency
    _ = queued?.device
    _ = queued?.axes
    _ = queued?.dpads
    _ = queued?.buttons
    _ = queued?.elements
    _ = queued?.switches
    if let element = live.buttons[GCButtonElementName.a] {
        _ = live.change(for: element)
        if let queuedState = queued {
            _ = queuedState.change(for: element)
        }
    }
    _ = live.changedElements()
    _ = queued?.changedElements()
    let captured = live.capture()
    _ = captured.lastEventTimestamp
    _ = captured.buttons
    _ = captured.axes
    _ = captured.dpads
    _ = captured.elements
    _ = captured.switches
    _ = captured[GCInputButtonA]

    let empty = GCControllerInputState()
    _ = empty.axes
    _ = empty.dpads
    _ = empty.buttons
    _ = empty.elements
    _ = empty.switches

    let physical: any GCDevicePhysicalInput = live
    _ = physical.inputStateQueueDepth
    _ = physical.queue
    _ = physical.capture()
    _ = physical.nextInputState()

    let streamGate = DispatchSemaphore(value: 0)
    Task {
        for await _ in live.inputStates {
            box.streamCount += 1
            streamGate.signal()
            break
        }
    }
    Thread.sleep(forTimeInterval: 0.05)
    simulated.extendedGamepad?.buttonY.setValue(1)
    precondition(streamGate.wait(timeout: .now() + 2) == .success)
    precondition(box.streamCount == 1)

    _ = (any GCAxis2DInput).self
    _ = (any GCAxisElement).self
    _ = (any GCAxisInput).self
    _ = (any GCButtonElement).self
    _ = (any GCDevice).self
    _ = (any GCDevicePhysicalInput).self
    _ = (any GCDevicePhysicalInputState).self
    _ = (any GCDevicePhysicalInputStateDiff).self
    _ = (any GCDirectionPadElement).self
    _ = (any GCLinearInput).self
    _ = (any GCPhysicalInputElement).self
    _ = (any GCPressedStateInput).self
    _ = (any GCRelativeInput).self
    _ = (any GCTouchedStateInput).self
    _ = GCControllerLiveInput.self
    _ = GCControllerInputState.self

    GCSimulatedInput.detach(simulated)
    GCSimulatedInput.reset()
}


// --- GCMotionTests.swift ---
func testSimulatedMotion() {
    GCSimulatedInput.reset()
    let simulated = GCSimulatedInput.makeExtendedGamepad()
    GCSimulatedInput.attach(simulated)
    GCSimulatedInput.applyMotion(
        simulated,
        attitude: GCQuaternion(x: 0, y: 0, z: 0, w: 1),
        rotationRate: GCRotationRate(x: 0.1, y: 0.2, z: 0.3),
        gravity: GCAcceleration(x: 0, y: -1, z: 0),
        userAcceleration: GCAcceleration(x: 0.01, y: 0, z: 0)
    )
    precondition(simulated.motion?.hasAttitude == true)
    precondition(simulated.motion?.hasRotationRate == true)
    precondition(simulated.motion?.hasGravityAndUserAcceleration == true)
    precondition(simulated.motion?.hasAttitudeAndRotationRate == true)
    precondition(abs((simulated.motion?.gravity.y ?? 0) + 1) < 0.0001)
    simulated.motion?.setAcceleration(GCAcceleration(x: 1, y: 2, z: 3))
    simulated.motion?.setAttitude(GCQuaternion(x: 0, y: 0, z: 0, w: 1))
    simulated.motion?.setGravity(GCAcceleration(x: 0, y: -1, z: 0))
    simulated.motion?.setRotationRate(GCRotationRate(x: 0, y: 0, z: 0))
    simulated.motion?.setUserAcceleration(GCAcceleration())
    _ = simulated.motion?.controller
    if let motionCopy = simulated.motion {
        let other = GCMotion()
        other.setStateFrom(motionCopy)
        _ = other.sensorsActive
        _ = other.sensorsRequireManualActivation
        _ = other.acceleration.x
        _ = other.attitude.w
        _ = other.gravity.y
        _ = other.rotationRate.z
        _ = other.userAcceleration.x
        other.valueChangedHandler = { _ in }
    }

    let quat = GCQuaternion()
    _ = quat.x + quat.y + quat.z + quat.w
    _ = GCQuaternion(x: 0, y: 0, z: 0, w: 1)
    let accel = GCAcceleration()
    _ = accel.x + accel.y + accel.z
    _ = GCAcceleration(x: 1, y: 2, z: 3)
    let euler = GCEulerAngles(pitch: 1, yaw: 2, roll: 3)
    _ = euler.pitch + euler.yaw + euler.roll
    _ = GCEulerAngles()
    let rate = GCRotationRate()
    _ = rate.x + rate.y + rate.z
    _ = GCRotationRate(x: 0.1, y: 0.2, z: 0.3)
    GCSimulatedInput.detach(simulated)
    GCSimulatedInput.reset()
}


// --- GCNotificationMessageTests.swift ---
func testTypedNotificationMessages() {
    func onMain(_ body: @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated(body)
            }
        }
    }

    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let connect = GCController.DidConnectMessage(controller: snapshot)
    precondition(connect.controller === snapshot)
    precondition(GCController.DidConnectMessage.name == Notification.Name.GCControllerDidConnect)

    let keyboard = GCSimulatedInput.makeKeyboard()
    let mouse = GCSimulatedInput.makeMouse()

    onMain {
        let note = Notification(name: .GCControllerDidConnect, object: snapshot)
        _ = GCController.DidConnectMessage.makeMessage(note)
        _ = GCController.DidConnectMessage.makeNotification(connect)
        let disc = GCController.DidDisconnectMessage(controller: snapshot)
        _ = disc.controller
        _ = GCController.DidDisconnectMessage.name
        _ = GCController.DidDisconnectMessage.makeMessage(Notification(name: .GCControllerDidDisconnect, object: snapshot))
        _ = GCController.DidDisconnectMessage.makeNotification(disc)
        let become = GCController.DidBecomeCurrentMessage(controller: snapshot)
        _ = become.controller
        _ = GCController.DidBecomeCurrentMessage.name
        _ = GCController.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCControllerDidBecomeCurrent, object: snapshot))
        _ = GCController.DidBecomeCurrentMessage.makeNotification(become)
        let stop = GCController.DidStopBeingCurrentMessage(controller: snapshot)
        _ = stop.controller
        _ = GCController.DidStopBeingCurrentMessage.name
        _ = GCController.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCControllerDidStopBeingCurrent, object: snapshot))
        _ = GCController.DidStopBeingCurrentMessage.makeNotification(stop)

        let kConn = GCKeyboard.DidConnectMessage(keyboard: keyboard)
        _ = kConn.keyboard
        _ = GCKeyboard.DidConnectMessage.name
        _ = GCKeyboard.DidConnectMessage.makeMessage(Notification(name: .GCKeyboardDidConnect, object: keyboard))
        _ = GCKeyboard.DidConnectMessage.makeNotification(kConn)
        let kDisc = GCKeyboard.DidDisconnectMessage(keyboard: keyboard)
        _ = kDisc.keyboard
        _ = GCKeyboard.DidDisconnectMessage.name
        _ = GCKeyboard.DidDisconnectMessage.makeMessage(Notification(name: .GCKeyboardDidDisconnect, object: keyboard))
        _ = GCKeyboard.DidDisconnectMessage.makeNotification(kDisc)

        let mConn = GCMouse.DidConnectMessage(mouse: mouse)
        _ = mConn.mouse
        _ = GCMouse.DidConnectMessage.name
        _ = GCMouse.DidConnectMessage.makeMessage(Notification(name: .GCMouseDidConnect, object: mouse))
        _ = GCMouse.DidConnectMessage.makeNotification(mConn)
        let mDisc = GCMouse.DidDisconnectMessage(mouse: mouse)
        _ = mDisc.mouse
        _ = GCMouse.DidDisconnectMessage.name
        _ = GCMouse.DidDisconnectMessage.makeMessage(Notification(name: .GCMouseDidDisconnect, object: mouse))
        _ = GCMouse.DidDisconnectMessage.makeNotification(mDisc)
        let mBecome = GCMouse.DidBecomeCurrentMessage(mouse: mouse)
        _ = mBecome.mouse
        _ = GCMouse.DidBecomeCurrentMessage.name
        _ = GCMouse.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCMouseDidBecomeCurrent, object: mouse))
        _ = GCMouse.DidBecomeCurrentMessage.makeNotification(mBecome)
        let mStop = GCMouse.DidStopBeingCurrentMessage(mouse: mouse)
        _ = mStop.mouse
        _ = GCMouse.DidStopBeingCurrentMessage.name
        _ = GCMouse.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCMouseDidStopBeingCurrent, object: mouse))
        _ = GCMouse.DidStopBeingCurrentMessage.makeNotification(mStop)
    }
    GCSimulatedInput.reset()
}


// --- GCNotificationNameTests.swift ---
func testNotificationNameConstants() {
    precondition(NSNotification.Name.GCControllerDidBecomeCurrent.rawValue == "GCControllerDidBecomeCurrentNotification")
    precondition(NSNotification.Name.GCControllerDidConnect.rawValue == "GCControllerDidConnectNotification")
    precondition(NSNotification.Name.GCControllerDidDisconnect.rawValue == "GCControllerDidDisconnectNotification")
    precondition(NSNotification.Name.GCControllerDidStopBeingCurrent.rawValue == "GCControllerDidStopBeingCurrentNotification")
    precondition(NSNotification.Name.GCControllerUserCustomizationsDidChange.rawValue == "GCControllerUserCustomizationsDidChangeNotification")
    precondition(NSNotification.Name.GCKeyboardDidConnect.rawValue == "GCKeyboardDidConnectNotification")
    precondition(NSNotification.Name.GCKeyboardDidDisconnect.rawValue == "GCKeyboardDidDisconnectNotification")
    precondition(NSNotification.Name.GCMouseDidBecomeCurrent.rawValue == "GCMouseDidBecomeCurrentNotification")
    precondition(NSNotification.Name.GCMouseDidConnect.rawValue == "GCMouseDidConnectNotification")
    precondition(NSNotification.Name.GCMouseDidDisconnect.rawValue == "GCMouseDidDisconnectNotification")
    precondition(NSNotification.Name.GCMouseDidStopBeingCurrent.rawValue == "GCMouseDidStopBeingCurrentNotification")
}


// --- GCProfileTests.swift ---
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


// --- GCSnapshotTests.swift ---
func testSnapshotRoundTrip() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let pad = snapshot.extendedGamepad!
    pad.buttonA.setValue(1)
    let snapshotBlob = pad.saveSnapshot().snapshotData
    precondition(!snapshotBlob.isEmpty)
    var decoded = GCExtendedGamepadSnapshotData()
    precondition(GCExtendedGamepadSnapshotDataFromNSData(&decoded, snapshotBlob))
    precondition(decoded.buttonA == 1)
    _ = decoded.version
    _ = decoded.size
    _ = decoded.dpadX
    _ = decoded.dpadY
    _ = decoded.buttonB
    _ = decoded.buttonX
    _ = decoded.buttonY
    _ = decoded.leftShoulder
    _ = decoded.rightShoulder
    _ = decoded.leftThumbstickX
    _ = decoded.leftThumbstickY
    _ = decoded.rightThumbstickX
    _ = decoded.rightThumbstickY
    _ = decoded.leftTrigger
    _ = decoded.rightTrigger
    _ = decoded.supportsClickableThumbsticks
    _ = decoded.leftThumbstickButton
    _ = decoded.rightThumbstickButton

    var encoded = GCExtendedGamepadSnapshotData(
        version: 2,
        size: 80,
        dpadX: 0, dpadY: 0,
        buttonA: 0, buttonB: 0, buttonX: 0.75, buttonY: 0,
        leftShoulder: 0, rightShoulder: 0,
        leftThumbstickX: 0, leftThumbstickY: 0,
        rightThumbstickX: 0, rightThumbstickY: 0,
        leftTrigger: 0.4, rightTrigger: 0,
        supportsClickableThumbsticks: false,
        leftThumbstickButton: false,
        rightThumbstickButton: false
    )
    let roundTrip = NSDataFromGCExtendedGamepadSnapshotData(&encoded)
    var restored = GCExtendedGamepadSnapshotData()
    precondition(GCExtendedGamepadSnapshotDataFromNSData(&restored, roundTrip))
    precondition(abs(restored.buttonX - 0.75) < 0.0001)
    precondition(abs(restored.leftTrigger - 0.4) < 0.0001)

    var v100 = GCExtendedGamepadSnapShotDataV100(
        version: 0x100,
        size: 60,
        dpadX: 0.1, dpadY: -0.2,
        buttonA: 0.5, buttonB: 0.3, buttonX: 0.4, buttonY: 0.5,
        leftShoulder: 0.6, rightShoulder: 0.7,
        leftThumbstickX: 0.8, leftThumbstickY: -0.8,
        rightThumbstickX: 0.2, rightThumbstickY: -0.2,
        leftTrigger: 0.9, rightTrigger: 0.1
    )
    let v100Data = NSDataFromGCExtendedGamepadSnapShotDataV100(&v100)
    var v100Restored = GCExtendedGamepadSnapShotDataV100()
    precondition(GCExtendedGamepadSnapShotDataV100FromNSData(&v100Restored, v100Data))
    precondition(abs(v100Restored.buttonA - 0.5) < 0.0001)
    _ = v100Restored.version
    _ = v100Restored.size
    _ = v100Restored.dpadX
    _ = v100Restored.dpadY
    _ = v100Restored.buttonB
    _ = v100Restored.buttonX
    _ = v100Restored.buttonY
    _ = v100Restored.leftShoulder
    _ = v100Restored.rightShoulder
    _ = v100Restored.leftThumbstickX
    _ = v100Restored.leftThumbstickY
    _ = v100Restored.rightThumbstickX
    _ = v100Restored.rightThumbstickY
    _ = v100Restored.leftTrigger
    _ = v100Restored.rightTrigger

    var classic = GCGamepadSnapShotDataV100(
        version: 0x100,
        size: 36,
        dpadX: 0.5, dpadY: -0.5,
        buttonA: 1, buttonB: 0.2, buttonX: 0.3, buttonY: 0.4,
        leftShoulder: 0.6, rightShoulder: 0.7
    )
    let classicData = NSDataFromGCGamepadSnapShotDataV100(&classic)
    var classicRestored = GCGamepadSnapShotDataV100()
    precondition(GCGamepadSnapShotDataV100FromNSData(&classicRestored, classicData))
    precondition(classicRestored.buttonA == 1)
    _ = classicRestored.version
    _ = classicRestored.size
    _ = classicRestored.dpadX
    _ = classicRestored.dpadY
    _ = classicRestored.buttonB
    _ = classicRestored.buttonX
    _ = classicRestored.buttonY
    _ = classicRestored.leftShoulder
    _ = classicRestored.rightShoulder

    let extendedFromData = GCExtendedGamepadSnapshot(snapshotData: snapshotBlob)
    precondition(extendedFromData.buttonA.isPressed)
    _ = extendedFromData.snapshotData
    _ = GCExtendedGamepadSnapshot(controller: snapshot, snapshotData: snapshotBlob)
    let gamepadSnap = GCGamepadSnapshot(snapshotData: classicData ?? Data())
    _ = gamepadSnap.snapshotData
    _ = GCGamepadSnapshot(controller: snapshot, snapshotData: classicData ?? Data())

    var microDataStruct = GCMicroGamepadSnapshotData(
        version: 1,
        size: 24,
        dpadX: 0.25, dpadY: -0.25,
        buttonA: 1, buttonX: 0.5
    )
    _ = microDataStruct.version
    _ = microDataStruct.size
    _ = microDataStruct.dpadX
    _ = microDataStruct.dpadY
    _ = microDataStruct.buttonA
    _ = microDataStruct.buttonX
    let microBlob = NSDataFromGCMicroGamepadSnapshotData(&microDataStruct)
    var microRestored = GCMicroGamepadSnapshotData()
    precondition(GCMicroGamepadSnapshotDataFromNSData(&microRestored, microBlob))
    var microV100 = GCMicroGamepadSnapShotDataV100(
        version: 0x100,
        size: 20,
        dpadX: 0.3, dpadY: 0.4,
        buttonA: 1, buttonX: 0.2
    )
    _ = microV100.version
    _ = microV100.size
    _ = microV100.dpadX
    _ = microV100.dpadY
    _ = microV100.buttonA
    _ = microV100.buttonX
    let microV100Blob = NSDataFromGCMicroGamepadSnapShotDataV100(&microV100)
    var microV100Restored = GCMicroGamepadSnapShotDataV100()
    precondition(GCMicroGamepadSnapShotDataV100FromNSData(&microV100Restored, microV100Blob))
    let micro = GCController.withMicroGamepad()
    let microSnap = GCMicroGamepadSnapshot(snapshotData: microBlob ?? Data())
    _ = microSnap.snapshotData
    _ = GCMicroGamepadSnapshot(controller: micro, snapshotData: microBlob ?? Data())
    _ = GCExtendedGamepadSnapshot.self
    _ = GCGamepadSnapshot.self
    _ = GCMicroGamepadSnapshot.self
    GCSimulatedInput.reset()
}


// --- GCVirtualControllerTests.swift ---
func testVirtualControllerFailClosed() {
    final class Box: @unchecked Sendable {
        var error: (any Error)?
        var count = 0
    }
    let box = Box()
    let virtualConfig = GCVirtualController.Configuration()
    virtualConfig.elements = [GCInputButtonA, GCInputDirectionPad]
    virtualConfig.isHidden = true
    let virtual = GCVirtualController(configuration: virtualConfig)
    precondition(virtual.controller == nil)
    let virtualGate = DispatchSemaphore(value: 0)
    virtual.connect { error in
        box.error = error
        box.count += 1
        virtualGate.signal()
    }
    precondition(box.count == 0)
    precondition(box.error == nil)
    precondition(virtualGate.wait(timeout: .now() + 2) == .success)
    precondition(box.count == 1)
    precondition(box.error != nil)
    virtual.setValue(0.5, forButtonElement: GCInputButtonA)
    virtual.setPosition(CGPoint(x: 0.2, y: -0.3), forDirectionPadElement: GCInputDirectionPad)
    virtual.updateConfiguration(forElement: GCInputButtonA) { config in
        config.isHidden = true
        config.actsAsTouchpad = true
        return config
    }
    virtual.disconnect()
    _ = GCVirtualController.self
    _ = GCVirtualController.Configuration.self
    _ = GCVirtualController.ElementConfiguration.self
}


testButtonAxisDpadHandlers()
testPhysicalInputElementCollection()
testGCColorComponents()
testControllerRegistryAndNotifications()
testBatteryLightHapticsTypes()
testDualSenseXboxDualShockAndTouchpad()
testElementNameConstants()
testEnumAndOptionSetMembers()
testEventHandlingOptions()
testGamepadProfileFamilies()
testGeometryAndNSValue()
testDeviceInputNameConstants()
testHIDKeyCodeValues()
testHIDKeyNameStrings()
testCoalescedKeyboardAndMouse()
testLiveInputAndPhysicalElementProtocols()
testSimulatedMotion()
testTypedNotificationMessages()
testNotificationNameConstants()
testPhysicalInputProfileDictionaries()
testSnapshotRoundTrip()
testVirtualControllerFailClosed()

print("GAMECONTROLLER_AGENT_RUNTIME_OK")
