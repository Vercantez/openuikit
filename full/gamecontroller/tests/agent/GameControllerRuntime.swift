import Foundation
import Dispatch
import GameController

GCSimulatedInput.reset()
precondition(!GCSimulatedInput.linuxEvdevAvailable)
precondition(GCController.controllers().isEmpty)
precondition(GCController.current == nil)
precondition(GCKeyboard.coalesced == nil)
precondition(GCMouse.current == nil)
precondition(GCMouse.mice().isEmpty)

func _gcOnMain(_ body: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(body)
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated(body)
        }
    }
}

func _gcWalkConstants() {
    _ = GCControllerPlayerIndex.self
    _ = GCControllerPlayerIndex.index1
    _ = GCControllerPlayerIndex.index2
    _ = GCControllerPlayerIndex.index3
    _ = GCControllerPlayerIndex.index4
    _ = GCControllerPlayerIndex.indexUnset
    _ = GCDeviceBattery.State.self
    _ = GCDeviceBattery.State.charging
    _ = GCDeviceBattery.State.discharging
    _ = GCDeviceBattery.State.full
    _ = GCDeviceBattery.State.unknown
    _ = GCDevicePhysicalInputElementChange.self
    _ = GCDevicePhysicalInputElementChange.changed
    _ = GCDevicePhysicalInputElementChange.noChange
    _ = GCDevicePhysicalInputElementChange.unknownChange
    _ = GCDualSenseAdaptiveTrigger.Mode.self
    _ = GCDualSenseAdaptiveTrigger.Mode.feedback
    _ = GCDualSenseAdaptiveTrigger.Mode.off
    _ = GCDualSenseAdaptiveTrigger.Mode.slopeFeedback
    _ = GCDualSenseAdaptiveTrigger.Mode.vibration
    _ = GCDualSenseAdaptiveTrigger.Mode.weapon
    _ = GCDualSenseAdaptiveTrigger.Status.self
    _ = GCDualSenseAdaptiveTrigger.Status.feedbackLoadApplied
    _ = GCDualSenseAdaptiveTrigger.Status.feedbackNoLoad
    _ = GCDualSenseAdaptiveTrigger.Status.slopeFeedbackApplyingLoad
    _ = GCDualSenseAdaptiveTrigger.Status.slopeFeedbackFinished
    _ = GCDualSenseAdaptiveTrigger.Status.slopeFeedbackReady
    _ = GCDualSenseAdaptiveTrigger.Status.unknown
    _ = GCDualSenseAdaptiveTrigger.Status.vibrationIsVibrating
    _ = GCDualSenseAdaptiveTrigger.Status.vibrationNotVibrating
    _ = GCDualSenseAdaptiveTrigger.Status.weaponFired
    _ = GCDualSenseAdaptiveTrigger.Status.weaponFiring
    _ = GCDualSenseAdaptiveTrigger.Status.weaponReady
    _ = GCExtendedGamepadSnapshotDataVersion.self
    _ = GCExtendedGamepadSnapshotDataVersion.version1
    _ = GCExtendedGamepadSnapshotDataVersion.version2
    _ = GCMicroGamepadSnapshotDataVersion.self
    _ = GCMicroGamepadSnapshotDataVersion.version1
    _ = GCPhysicalInputSourceDirection.self
    _ = GCPhysicalInputSourceDirection.down
    _ = GCPhysicalInputSourceDirection.left
    _ = GCPhysicalInputSourceDirection.right
    _ = GCPhysicalInputSourceDirection.up
    _ = GCControllerElement.SystemGestureState.self
    _ = GCControllerElement.SystemGestureState.alwaysReceive
    _ = GCControllerElement.SystemGestureState.disabled
    _ = GCControllerElement.SystemGestureState.enabled
    _ = GCControllerTouchpad.TouchState.self
    _ = GCControllerTouchpad.TouchState.down
    _ = GCControllerTouchpad.TouchState.moving
    _ = GCControllerTouchpad.TouchState.up
    _ = GCUIEventTypes.self
    _ = GCUIEventTypes.gamepad
    _ = GCDualSenseAdaptiveTrigger.discretePositionCount
    _ = NSNotification.Name.GCControllerDidBecomeCurrent
    _ = NSNotification.Name.GCControllerDidConnect
    _ = NSNotification.Name.GCControllerDidDisconnect
    _ = NSNotification.Name.GCControllerDidStopBeingCurrent
    _ = NSNotification.Name.GCControllerUserCustomizationsDidChange
    _ = GCCurrentExtendedGamepadSnapshotDataVersion
    _ = GCCurrentMicroGamepadSnapshotDataVersion
    _ = GCDeviceAxisInput.self
    _ = GCDeviceButtonInput.self
    _ = GCDeviceDirectionPad.self
    _ = GCDeviceElement.self
    _ = GCDeviceTouchpad.self
    _ = GCHapticDurationInfinite
    _ = GCHapticsLocality.all
    _ = GCHapticsLocality.`default`
    _ = GCHapticsLocality.handles
    _ = GCHapticsLocality.leftHandle
    _ = GCHapticsLocality.leftTrigger
    _ = GCHapticsLocality.rightHandle
    _ = GCHapticsLocality.rightTrigger
    _ = GCHapticsLocality.triggers
    _ = GCInputDirectionalCardinalDpad
    _ = GCInputDirectionalCenterButton
    _ = GCInputDirectionalDpad
    _ = GCInputDirectionalTouchSurfaceButton
    _ = GCInputMicroGamepadButtonA
    _ = GCInputMicroGamepadButtonMenu
    _ = GCInputMicroGamepadButtonX
    _ = GCInputMicroGamepadDpad
    _ = GCKeyA
    _ = GCKeyApplication
    _ = GCKeyB
    _ = GCKeyBackslash
    _ = GCKeyC
    _ = GCKeyCapsLock
    _ = GCKeyCloseBracket
    _ = GCKeyCode.application
    _ = GCKeyCode.backslash
    _ = GCKeyCode.capsLock
    _ = GCKeyCode.closeBracket
    _ = GCKeyCode.comma
    _ = GCKeyCode.deleteForward
    _ = GCKeyCode.deleteOrBackspace
    _ = GCKeyCode.downArrow
    _ = GCKeyCode.eight
    _ = GCKeyCode.end
    _ = GCKeyCode.equalSign
    _ = GCKeyCode.escape
    _ = GCKeyCode.F1
    _ = GCKeyCode.F10
    _ = GCKeyCode.F11
    _ = GCKeyCode.F12
    _ = GCKeyCode.F13
    _ = GCKeyCode.F14
    _ = GCKeyCode.F15
    _ = GCKeyCode.F16
    _ = GCKeyCode.F17
    _ = GCKeyCode.F18
    _ = GCKeyCode.F19
    _ = GCKeyCode.F2
    _ = GCKeyCode.F20
    _ = GCKeyCode.F3
    _ = GCKeyCode.F4
    _ = GCKeyCode.F5
    _ = GCKeyCode.F6
    _ = GCKeyCode.F7
    _ = GCKeyCode.F8
    _ = GCKeyCode.F9
    _ = GCKeyCode.five
    _ = GCKeyCode.four
    _ = GCKeyCode.graveAccentAndTilde
    _ = GCKeyCode.home
    _ = GCKeyCode.hyphen
    _ = GCKeyCode.insert
    _ = GCKeyCode.international1
    _ = GCKeyCode.international2
    _ = GCKeyCode.international3
    _ = GCKeyCode.international4
    _ = GCKeyCode.international5
    _ = GCKeyCode.international6
    _ = GCKeyCode.international7
    _ = GCKeyCode.international8
    _ = GCKeyCode.international9
    _ = GCKeyCode.keyA
    _ = GCKeyCode.keyB
    _ = GCKeyCode.keyC
    _ = GCKeyCode.keyD
    _ = GCKeyCode.keyE
    _ = GCKeyCode.keyF
    _ = GCKeyCode.keyG
    _ = GCKeyCode.keyH
    _ = GCKeyCode.keyI
    _ = GCKeyCode.keyJ
    _ = GCKeyCode.keyK
    _ = GCKeyCode.keyL
    _ = GCKeyCode.keyM
    _ = GCKeyCode.keyN
    _ = GCKeyCode.keyO
    _ = GCKeyCode.keyP
    _ = GCKeyCode.keyQ
    _ = GCKeyCode.keyR
    _ = GCKeyCode.keyS
    _ = GCKeyCode.keyT
    _ = GCKeyCode.keyU
    _ = GCKeyCode.keyV
    _ = GCKeyCode.keyW
    _ = GCKeyCode.keyX
    _ = GCKeyCode.keyY
    _ = GCKeyCode.keyZ
    _ = GCKeyCode.keypad0
    _ = GCKeyCode.keypad1
    _ = GCKeyCode.keypad2
    _ = GCKeyCode.keypad3
    _ = GCKeyCode.keypad4
    _ = GCKeyCode.keypad5
    _ = GCKeyCode.keypad6
    _ = GCKeyCode.keypad7
    _ = GCKeyCode.keypad8
    _ = GCKeyCode.keypad9
    _ = GCKeyCode.keypadAsterisk
    _ = GCKeyCode.keypadEnter
    _ = GCKeyCode.keypadEqualSign
    _ = GCKeyCode.keypadHyphen
    _ = GCKeyCode.keypadNumLock
    _ = GCKeyCode.keypadPeriod
    _ = GCKeyCode.keypadPlus
    _ = GCKeyCode.keypadSlash
    _ = GCKeyCode.LANG1
    _ = GCKeyCode.LANG2
    _ = GCKeyCode.LANG3
    _ = GCKeyCode.LANG4
    _ = GCKeyCode.LANG5
    _ = GCKeyCode.LANG6
    _ = GCKeyCode.LANG7
    _ = GCKeyCode.LANG8
    _ = GCKeyCode.LANG9
    _ = GCKeyCode.leftAlt
    _ = GCKeyCode.leftArrow
    _ = GCKeyCode.leftControl
    _ = GCKeyCode.leftGUI
    _ = GCKeyCode.leftShift
    _ = GCKeyCode.nine
    _ = GCKeyCode.nonUSBackslash
    _ = GCKeyCode.nonUSPound
    _ = GCKeyCode.one
    _ = GCKeyCode.openBracket
    _ = GCKeyCode.pageDown
    _ = GCKeyCode.pageUp
    _ = GCKeyCode.pause
    _ = GCKeyCode.period
    _ = GCKeyCode.power
    _ = GCKeyCode.printScreen
    _ = GCKeyCode.quote
    _ = GCKeyCode.returnOrEnter
    _ = GCKeyCode.rightAlt
    _ = GCKeyCode.rightArrow
    _ = GCKeyCode.rightControl
    _ = GCKeyCode.rightGUI
    _ = GCKeyCode.rightShift
    _ = GCKeyCode.scrollLock
    _ = GCKeyCode.semicolon
    _ = GCKeyCode.seven
    _ = GCKeyCode.six
    _ = GCKeyCode.slash
    _ = GCKeyCode.spacebar
    _ = GCKeyCode.tab
    _ = GCKeyCode.three
    _ = GCKeyCode.two
    _ = GCKeyCode.upArrow
    _ = GCKeyCode.zero
    _ = GCKeyComma
    _ = GCKeyD
    _ = GCKeyDeleteForward
    _ = GCKeyDeleteOrBackspace
    _ = GCKeyDownArrow
    _ = GCKeyE
    _ = GCKeyEight
    _ = GCKeyEnd
    _ = GCKeyEqualSign
    _ = GCKeyEscape
    _ = GCKeyF
    _ = GCKeyF1
    _ = GCKeyF10
    _ = GCKeyF11
    _ = GCKeyF12
    _ = GCKeyF13
    _ = GCKeyF14
    _ = GCKeyF15
    _ = GCKeyF16
    _ = GCKeyF17
    _ = GCKeyF18
    _ = GCKeyF19
    _ = GCKeyF2
    _ = GCKeyF20
    _ = GCKeyF3
    _ = GCKeyF4
    _ = GCKeyF5
    _ = GCKeyF6
    _ = GCKeyF7
    _ = GCKeyF8
    _ = GCKeyF9
    _ = GCKeyFive
    _ = GCKeyFour
    _ = GCKeyG
    _ = GCKeyGraveAccentAndTilde
    _ = GCKeyH
    _ = GCKeyHome
    _ = GCKeyHyphen
    _ = GCKeyI
    _ = GCKeyInsert
    _ = GCKeyInternational1
    _ = GCKeyInternational2
    _ = GCKeyInternational3
    _ = GCKeyInternational4
    _ = GCKeyInternational5
    _ = GCKeyInternational6
    _ = GCKeyInternational7
    _ = GCKeyInternational8
    _ = GCKeyInternational9
    _ = GCKeyJ
    _ = GCKeyK
    _ = GCKeyKeypad0
    _ = GCKeyKeypad1
    _ = GCKeyKeypad2
    _ = GCKeyKeypad3
    _ = GCKeyKeypad4
    _ = GCKeyKeypad5
    _ = GCKeyKeypad6
    _ = GCKeyKeypad7
    _ = GCKeyKeypad8
    _ = GCKeyKeypad9
    _ = GCKeyKeypadAsterisk
    _ = GCKeyKeypadEnter
    _ = GCKeyKeypadEqualSign
    _ = GCKeyKeypadHyphen
    _ = GCKeyKeypadNumLock
    _ = GCKeyKeypadPeriod
    _ = GCKeyKeypadPlus
    _ = GCKeyKeypadSlash
    _ = GCKeyL
    _ = GCKeyLANG1
    _ = GCKeyLANG2
    _ = GCKeyLANG3
    _ = GCKeyLANG4
    _ = GCKeyLANG5
    _ = GCKeyLANG6
    _ = GCKeyLANG7
    _ = GCKeyLANG8
    _ = GCKeyLANG9
    _ = GCKeyLeftAlt
    _ = GCKeyLeftArrow
    _ = GCKeyLeftControl
    _ = GCKeyLeftGUI
    _ = GCKeyLeftShift
    _ = GCKeyM
    _ = GCKeyN
    _ = GCKeyNine
    _ = GCKeyNonUSBackslash
    _ = GCKeyNonUSPound
    _ = GCKeyO
    _ = GCKeyOne
    _ = GCKeyOpenBracket
    _ = GCKeyP
    _ = GCKeyPageDown
    _ = GCKeyPageUp
    _ = GCKeyPause
    _ = GCKeyPeriod
    _ = GCKeyPower
    _ = GCKeyPrintScreen
    _ = GCKeyQ
    _ = GCKeyQuote
    _ = GCKeyR
    _ = GCKeyReturnOrEnter
    _ = GCKeyRightAlt
    _ = GCKeyRightArrow
    _ = GCKeyRightControl
    _ = GCKeyRightGUI
    _ = GCKeyRightShift
    _ = GCKeyS
    _ = GCKeyScrollLock
    _ = GCKeySemicolon
    _ = GCKeySeven
    _ = GCKeySix
    _ = GCKeySlash
    _ = GCKeySpacebar
    _ = GCKeyT
    _ = GCKeyTab
    _ = GCKeyThree
    _ = GCKeyTwo
    _ = GCKeyU
    _ = GCKeyUpArrow
    _ = GCKeyV
    _ = GCKeyW
    _ = GCKeyX
    _ = GCKeyY
    _ = GCKeyZ
    _ = GCKeyZero
    _ = NSNotification.Name.GCKeyboardDidConnect
    _ = NSNotification.Name.GCKeyboardDidDisconnect
    _ = NSNotification.Name.GCMouseDidBecomeCurrent
    _ = NSNotification.Name.GCMouseDidConnect
    _ = NSNotification.Name.GCMouseDidDisconnect
    _ = NSNotification.Name.GCMouseDidStopBeingCurrent
    _ = GCPoint2Zero
    _ = GCProductCategoryArcadeStick
    _ = GCProductCategoryCoalescedRemote
    _ = GCProductCategoryControlCenterRemote
    _ = GCProductCategoryDualSense
    _ = GCProductCategoryDualShock4
    _ = GCProductCategoryHID
    _ = GCProductCategoryKeyboard
    _ = GCProductCategoryMFi
    _ = GCProductCategoryMouse
    _ = GCProductCategorySiriRemote1stGen
    _ = GCProductCategorySiriRemote2ndGen
    _ = GCProductCategorySpatialController
    _ = GCProductCategoryUniversalElectronicsRemote
    _ = GCProductCategoryXboxOne
    _ = GCPoint2.self
    _ = GCQuaternion.self
    _ = GCAcceleration.self
    _ = GCDualSenseAdaptiveTrigger.PositionalAmplitudes.self
    _ = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths.self
    _ = GCEulerAngles.self
    _ = GCExtendedGamepadSnapShotDataV100.self
    _ = GCExtendedGamepadSnapshotData.self
    _ = GCGamepadSnapShotDataV100.self
    _ = GCMicroGamepadSnapShotDataV100.self
    _ = GCMicroGamepadSnapshotData.self
    _ = GCRotationRate.self
    _ = GCControllerAxisValueChangedHandler.self
    _ = GCControllerButtonTouchedChangedHandler.self
    _ = GCControllerButtonValueChangedHandler.self
    _ = GCControllerDirectionPadValueChangedHandler.self
    _ = GCControllerTouchpadHandler.self
    _ = GCExtendedGamepadValueChangedHandler.self
    _ = GCGamepadValueChangedHandler.self
    _ = GCHapticsLocality.self
    _ = GCKeyCode.self
    _ = GCKeyboardValueChangedHandler.self
    _ = GCMicroGamepadValueChangedHandler.self
    _ = GCMotionValueChangedHandler.self
    _ = GCMouseMoved.self
    _ = kIOHIDGCSyntheticDeviceKey
    _ = GCColor.self
    _ = GCController.self
    _ = GCController.current
    _ = GCController.shouldMonitorBackgroundEvents
    _ = GCControllerAxisInput.self
    _ = GCControllerButtonInput.self
    _ = GCControllerDirectionPad.self
    _ = GCControllerElement.self
    _ = GCControllerInputState.self
    _ = GCControllerLiveInput.self
    _ = GCControllerTouchpad.self
    _ = GCDeviceBattery.self
    _ = GCDeviceCursor.self
    _ = GCDeviceHaptics.self
    _ = GCDeviceLight.self
    _ = GCDirectionalGamepad.self
    _ = GCDualSenseAdaptiveTrigger.self
    _ = GCDualSenseGamepad.self
    _ = GCDualShockGamepad.self
    _ = GCExtendedGamepad.self
    _ = GCExtendedGamepadSnapshot.self
    _ = GCGameControllerActivationContext.self
    _ = GCGamepad.self
    _ = GCGamepadSnapshot.self
    _ = GCKeyboard.self
    _ = GCKeyboard.coalesced
    _ = GCKeyboardInput.self
    _ = GCMicroGamepad.self
    _ = GCMicroGamepadSnapshot.self
    _ = GCMotion.self
    _ = GCMouse.self
    _ = GCMouse.current
    _ = GCMouseInput.self
    _ = GCPhysicalInputProfile.self
    _ = GCVirtualController.self
    _ = GCVirtualController.Configuration.self
    _ = GCVirtualController.ElementConfiguration.self
    _ = GCXboxGamepad.self
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
    _ = (any GCPhysicalInputSource).self
    _ = (any GCPressedStateInput).self
    _ = (any GCRelativeInput).self
    _ = (any GCSwitchElement).self
    _ = (any GCSwitchPositionInput).self
    _ = (any GCTouchedStateInput).self
    _ = GCInputButtonA
    _ = GCInputButtonB
    _ = GCInputButtonX
    _ = GCInputButtonY
    _ = GCAxisElementName.self
    _ = (any GCAxisElement).self
    _ = GCAxisElementName.RawValue.self
    _ = GCInputButtonHome
    _ = GCInputButtonMenu
    _ = GCInputButtonShare
    _ = GCInputLeftTrigger
    _ = GCButtonElementName.self
    _ = (any GCButtonElement).self
    _ = GCButtonElementName.leftBumper
    _ = GCButtonElementName.leftTrigger
    _ = GCButtonElementName.rightBumper
    _ = GCButtonElementName.leftShoulder
    _ = GCButtonElementName.rightTrigger
    _ = GCButtonElementName.rightShoulder
    _ = GCButtonElementName.thumbstickButton
    _ = GCButtonElementName.a
    _ = GCButtonElementName.b
    _ = GCButtonElementName.x
    _ = GCButtonElementName.y
    _ = GCButtonElementName.leftThumbstickButton
    _ = GCButtonElementName.rightThumbstickButton
    _ = GCButtonElementName.grip
    _ = GCButtonElementName.home
    _ = GCButtonElementName.menu
    _ = GCButtonElementName.share
    _ = GCButtonElementName.options
    _ = GCButtonElementName.trigger
    _ = GCButtonElementName.RawValue.self
    _ = GCInputDirectionPad
    _ = GCInputLeftShoulder
    _ = GCInputRightTrigger
    _ = GCSwitchElementName.self
    _ = (any GCSwitchElement).self
    _ = GCSwitchElementName.RawValue.self
    _ = GCInputButtonOptions
    _ = GCInputRightShoulder
    _ = GCInputXboxPaddleOne
    _ = GCInputXboxPaddleTwo
    _ = GCInputLeftThumbstick
    _ = GCInputXboxPaddleFour
    _ = GCInputRightThumbstick
    _ = GCInputXboxPaddleThree
    _ = GCDirectionPadElementName.self
    _ = (any GCDirectionPadElement).self
    _ = GCDirectionPadElementName.directionPad
    _ = GCDirectionPadElementName.thumbstick
    _ = GCDirectionPadElementName.leftThumbstick
    _ = GCDirectionPadElementName.rightThumbstick
    _ = GCDirectionPadElementName.RawValue.self
    _ = GCPhysicalInputElementName.self
    _ = (any GCPhysicalInputElement).self
    _ = GCPhysicalInputElementName.RawValue.self
    _ = GCInputDualShockTouchpadOne
    _ = GCInputDualShockTouchpadTwo
    _ = GCInputLeftThumbstickButton
    _ = GCInputRightThumbstickButton
    _ = GCInputDualShockTouchpadButton
    _ = (any GCPhysicalInputElementTypedName).self
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.self
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.Index.self
    _ = GameControllerEventHandlingOptions.self
    _ = GCKeyboard.DidConnectMessage.self
    _ = GCKeyboard.DidConnectMessage.name
    _ = GCKeyboard.DidConnectMessage.Subject.self
    _ = GCKeyboard.DidDisconnectMessage.self
    _ = GCKeyboard.DidDisconnectMessage.name
    _ = GCKeyboard.DidDisconnectMessage.Subject.self
    _ = GCController.DidConnectMessage.self
    _ = GCController.DidConnectMessage.name
    _ = GCController.DidConnectMessage.Subject.self
    _ = GCController.DidDisconnectMessage.self
    _ = GCController.DidDisconnectMessage.name
    _ = GCController.DidDisconnectMessage.Subject.self
    _ = GCController.DidBecomeCurrentMessage.self
    _ = GCController.DidBecomeCurrentMessage.name
    _ = GCController.DidBecomeCurrentMessage.Subject.self
    _ = GCController.DidStopBeingCurrentMessage.self
    _ = GCController.DidStopBeingCurrentMessage.name
    _ = GCController.DidStopBeingCurrentMessage.Subject.self
    _ = GCKeyboard.DidConnectMessage.name
    _ = GCKeyboard.DidDisconnectMessage.name
    _ = GCController.DidConnectMessage.name
    _ = GCController.DidDisconnectMessage.name
    _ = GCController.DidBecomeCurrentMessage.name
    _ = GCController.DidStopBeingCurrentMessage.name
    _ = GCMouse.DidConnectMessage.name
    _ = GCMouse.DidDisconnectMessage.name
    _ = GCMouse.DidBecomeCurrentMessage.name
    _ = GCMouse.DidStopBeingCurrentMessage.name
    _ = GCMouse.DidConnectMessage.self
    _ = GCMouse.DidConnectMessage.name
    _ = GCMouse.DidConnectMessage.Subject.self
    _ = GCMouse.DidDisconnectMessage.self
    _ = GCMouse.DidDisconnectMessage.name
    _ = GCMouse.DidDisconnectMessage.Subject.self
    _ = GCMouse.DidBecomeCurrentMessage.self
    _ = GCMouse.DidBecomeCurrentMessage.name
    _ = GCMouse.DidBecomeCurrentMessage.Subject.self
    _ = GCMouse.DidStopBeingCurrentMessage.self
    _ = GCMouse.DidStopBeingCurrentMessage.name
    _ = GCMouse.DidStopBeingCurrentMessage.Subject.self

}

_gcWalkConstants()

let discoveryGate = DispatchSemaphore(value: 0)
var discoveryCount = 0
GCController.startWirelessControllerDiscovery {
    discoveryCount += 1
    discoveryGate.signal()
}
precondition(discoveryCount == 0)
precondition(discoveryGate.wait(timeout: .now() + 2) == .success)
precondition(discoveryCount == 1)
GCController.stopWirelessControllerDiscovery()

let snapshot = GCController.withExtendedGamepad()
precondition(snapshot.isSnapshot)
precondition(!snapshot.isAttachedToDevice)
precondition(snapshot.extendedGamepad != nil)
precondition(snapshot.gamepad != nil)
precondition(snapshot.motion != nil)
precondition(snapshot.motion?.hasAttitude == false)
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

let handlerQueue = DispatchQueue(label: "gc.handler.test")
let handlerKey = DispatchSpecificKey<UInt8>()
handlerQueue.setSpecific(key: handlerKey, value: 7)
snapshot.handlerQueue = handlerQueue
precondition(snapshot.handlerQueue === handlerQueue)

let pad = snapshot.extendedGamepad!
precondition(pad.buttonA.value == 0)
precondition(!pad.buttonA.isPressed)
precondition(pad.buttonA.isAnalog)
precondition(pad.elements[GCInputButtonA] === pad.buttonA)
precondition(pad.buttons[GCInputButtonA] === pad.buttonA)
precondition(pad.dpads[GCInputLeftThumbstick] != nil)
_ = pad.axes
_ = pad.allElements
_ = pad.allButtons
_ = pad.allDpads
_ = pad.allAxes
_ = pad.allTouchpads
_ = pad.hasRemappedElements
_ = pad.mappedElementAlias(forPhysicalInputName: GCInputButtonA)
_ = pad.mappedPhysicalInputNames(forElementAlias: GCInputButtonA)
precondition(pad[GCInputButtonA] === pad.buttonA)

let handlerGate = DispatchSemaphore(value: 0)
var handlerQueueHonored = false
var handlerFireCount = 0
var pressedFireCount = 0
var touchedFireCount = 0
pad.buttonA.valueChangedHandler = { _, _, _ in
    handlerFireCount += 1
    handlerQueueHonored = DispatchQueue.getSpecific(key: handlerKey) == 7
    handlerGate.signal()
}
pad.buttonA.pressedChangedHandler = { _, _, _ in
    pressedFireCount += 1
}
pad.buttonA.touchedChangedHandler = { _, _, _, _ in
    touchedFireCount += 1
}
pad.buttonA.setValue(1)
precondition(pad.buttonA.isPressed)
precondition(pad.buttonA.value == 1)
precondition(pad.buttonA.isTouched)
precondition(handlerFireCount == 0)
precondition(handlerGate.wait(timeout: .now() + 2) == .success)
precondition(handlerFireCount == 1)
precondition(handlerQueueHonored)
precondition(pad.lastEventTimestamp > 0)

pad.leftThumbstick.setValueForXAxis(0.5, yAxis: -0.25)
precondition(abs(pad.leftThumbstick.xAxis.value - 0.5) < 0.0001)
precondition(abs(pad.leftThumbstick.yAxis.value + 0.25) < 0.0001)
precondition(pad.leftThumbstick.right.isPressed)
precondition(!pad.leftThumbstick.left.isPressed)
precondition(pad.leftThumbstick.down.isPressed)
precondition(!pad.leftThumbstick.up.isPressed)
precondition(!pad.leftThumbstick.up.isAnalog)
precondition(pad.leftThumbstick.xAxis.isAnalog)

let captured = snapshot.capture()
precondition(captured.isSnapshot)
precondition(captured.extendedGamepad?.buttonA.isPressed == true)
let profileCopy = pad.capture()
precondition(profileCopy.buttonA.isPressed)
profileCopy.setStateFrom(pad)

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

var encoded = GCExtendedGamepadSnapshotData()
encoded.buttonX = 0.75
encoded.leftTrigger = 0.4
let roundTrip = NSDataFromGCExtendedGamepadSnapshotData(&encoded)
var restored = GCExtendedGamepadSnapshotData()
precondition(GCExtendedGamepadSnapshotDataFromNSData(&restored, roundTrip))
precondition(abs(restored.buttonX - 0.75) < 0.0001)
precondition(abs(restored.leftTrigger - 0.4) < 0.0001)

var v100 = GCExtendedGamepadSnapShotDataV100()
v100.buttonA = 0.5
v100.dpadX = 0.1
v100.dpadY = -0.2
v100.buttonB = 0.3
v100.buttonX = 0.4
v100.buttonY = 0.5
v100.leftShoulder = 0.6
v100.rightShoulder = 0.7
v100.leftThumbstickX = 0.8
v100.leftThumbstickY = -0.8
v100.rightThumbstickX = 0.2
v100.rightThumbstickY = -0.2
v100.leftTrigger = 0.9
v100.rightTrigger = 0.1
let v100Data = NSDataFromGCExtendedGamepadSnapShotDataV100(&v100)
var v100Restored = GCExtendedGamepadSnapShotDataV100()
precondition(GCExtendedGamepadSnapShotDataV100FromNSData(&v100Restored, v100Data))
precondition(abs(v100Restored.buttonA - 0.5) < 0.0001)

var classic = GCGamepadSnapShotDataV100()
classic.buttonA = 1
classic.buttonB = 0.2
classic.buttonX = 0.3
classic.buttonY = 0.4
classic.dpadX = 0.5
classic.dpadY = -0.5
classic.leftShoulder = 0.6
classic.rightShoulder = 0.7
let classicData = NSDataFromGCGamepadSnapShotDataV100(&classic)
var classicRestored = GCGamepadSnapShotDataV100()
precondition(GCGamepadSnapShotDataV100FromNSData(&classicRestored, classicData))
precondition(classicRestored.buttonA == 1)
_ = pad.controller
if let gamepad = snapshot.gamepad {
    _ = gamepad.saveSnapshot()
    _ = gamepad.buttonA
    _ = gamepad.buttonB
    _ = gamepad.buttonX
    _ = gamepad.buttonY
    _ = gamepad.dpad
    _ = gamepad.leftShoulder
    _ = gamepad.rightShoulder
    gamepad.valueChangedHandler = { _, _ in }
}

let extendedFromData = GCExtendedGamepadSnapshot(snapshotData: snapshotBlob)
precondition(extendedFromData.buttonA.isPressed)
_ = GCExtendedGamepadSnapshot(controller: snapshot, snapshotData: snapshotBlob)
_ = GCGamepadSnapshot(snapshotData: classicData ?? Data())
_ = GCGamepadSnapshot(controller: snapshot, snapshotData: classicData ?? Data())

let micro = GCController.withMicroGamepad()
precondition(micro.microGamepad != nil)
micro.microGamepad?.buttonA.setValue(1)
precondition(micro.microGamepad?.buttonA.isPressed == true)
micro.microGamepad?.allowsRotation = true
micro.microGamepad?.reportsAbsoluteDpadValues = true
precondition(micro.microGamepad?.allowsRotation == true)
var microDataStruct = GCMicroGamepadSnapshotData()
microDataStruct.buttonA = 1
microDataStruct.buttonX = 0.5
microDataStruct.dpadX = 0.25
microDataStruct.dpadY = -0.25
let microBlob = NSDataFromGCMicroGamepadSnapshotData(&microDataStruct)
var microRestored = GCMicroGamepadSnapshotData()
precondition(GCMicroGamepadSnapshotDataFromNSData(&microRestored, microBlob))
var microV100 = GCMicroGamepadSnapShotDataV100()
microV100.buttonA = 1
microV100.buttonX = 0.2
microV100.dpadX = 0.3
microV100.dpadY = 0.4
let microV100Blob = NSDataFromGCMicroGamepadSnapShotDataV100(&microV100)
var microV100Restored = GCMicroGamepadSnapShotDataV100()
precondition(GCMicroGamepadSnapShotDataV100FromNSData(&microV100Restored, microV100Blob))
_ = micro.microGamepad?.saveSnapshot()
if let otherMicro = GCController.withMicroGamepad().microGamepad, let liveMicro = micro.microGamepad {
    liveMicro.setStateFrom(otherMicro)
}
_ = GCMicroGamepadSnapshot(snapshotData: microBlob ?? Data())
_ = GCMicroGamepadSnapshot(controller: micro, snapshotData: microBlob ?? Data())

let point = GCPoint2Make(1.5, -2)
precondition(GCPoint2Equal(point, GCPoint2(x: 1.5, y: -2)))
precondition(!GCPoint2Equal(point, GCPoint2Zero))
_ = NSStringFromGCPoint2(point)
let boxed = NSValue(GCPoint2: point)
precondition(GCPoint2Equal(boxed.gcPoint2Value, point))

precondition(GCKeyCode.keyA.rawValue == 0x04)
precondition(GCKeyCode.escape.rawValue == 0x29)

let names = GCButtonElementName.a
precondition(names.rawValue == GCInputButtonA)
_ = GCButtonElementName.arcadeButton(row: 1, column: 2)
_ = GCButtonElementName.backLeftButton(position: 1)
_ = GCButtonElementName.backRightButton(position: 2)
_ = GCButtonElementName(rawValue: "Custom")
_ = GCAxisElementName(rawValue: "Axis")
_ = GCSwitchElementName(rawValue: "Switch")
_ = GCPhysicalInputElementName(rawValue: "Element")
_ = GCButtonElementName.leftBumper
_ = GCButtonElementName.leftTrigger
_ = GCButtonElementName.rightBumper
_ = GCButtonElementName.leftShoulder
_ = GCButtonElementName.rightTrigger
_ = GCButtonElementName.rightShoulder
_ = GCButtonElementName.thumbstickButton
_ = GCButtonElementName.b
_ = GCButtonElementName.x
_ = GCButtonElementName.y
_ = GCButtonElementName.leftThumbstickButton
_ = GCButtonElementName.rightThumbstickButton
_ = GCButtonElementName.grip
_ = GCButtonElementName.home
_ = GCButtonElementName.menu
_ = GCButtonElementName.share
_ = GCButtonElementName.options
_ = GCButtonElementName.trigger

let collection = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
precondition(collection.isEmpty)
precondition(collection[GCButtonElementName.a] == nil)
precondition(collection[GCAxisElementName(rawValue: "x")] == nil)
precondition(collection[GCSwitchElementName(rawValue: "s")] == nil)
precondition(collection[GCPhysicalInputElementName(rawValue: "p")] == nil)
precondition(collection[GCDirectionPadElementName.directionPad] == nil)
precondition(collection.startIndex == collection.endIndex)
let idx = collection.startIndex
precondition(idx == collection.endIndex)
precondition(!(idx < collection.endIndex) || true)
precondition(idx <= collection.endIndex)
_ = idx..<collection.endIndex
_ = ..<collection.endIndex
precondition(GCButtonElementName.a != GCButtonElementName.b)
precondition(GCAxisElementName(rawValue: "a") != GCAxisElementName(rawValue: "b"))
precondition(GCSwitchElementName(rawValue: "a") != GCSwitchElementName(rawValue: "b"))
precondition(GCDirectionPadElementName.leftThumbstick != .rightThumbstick)
precondition(GCPhysicalInputElementName(rawValue: "a") != GCPhysicalInputElementName(rawValue: "b"))
precondition(GCControllerPlayerIndex.index1 != .index2)
precondition(GCDeviceBattery.State.charging != .full)
precondition(GCDevicePhysicalInputElementChange.changed != .noChange)
precondition(GCDualSenseAdaptiveTrigger.Mode.off != .feedback)
precondition(GCDualSenseAdaptiveTrigger.Status.unknown != .weaponReady)
precondition(GCExtendedGamepadSnapshotDataVersion.version1 != .version2)
precondition(GCMicroGamepadSnapshotDataVersion(rawValue: 99) == nil)
precondition(GCPhysicalInputSourceDirection.up != .down)
precondition(GCControllerElement.SystemGestureState.enabled != .disabled)
precondition(GCControllerTouchpad.TouchState.up != .down)
precondition(GCUIEventTypes.gamepad != GCUIEventTypes())
precondition(GCHapticsLocality.all != .handles)
precondition(GCKeyCode.keyA != .keyB)

var hashed = Set<GCKeyCode>()
hashed.insert(.keyA)
hashed.insert(.escape)
_ = hashed.hashValue
_ = Set([GCHapticsLocality.all, .default, .handles, .leftHandle, .rightHandle, .triggers, .leftTrigger, .rightTrigger])
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
_ = Set([GCExtendedGamepadSnapshotDataVersion.version1, .version2])
_ = Set([GCMicroGamepadSnapshotDataVersion.version1])
_ = Set([GCControllerElement.SystemGestureState.enabled, .alwaysReceive, .disabled])
_ = Set([GCControllerTouchpad.TouchState.up, .down, .moving])
_ = Set([GCButtonElementName.a, .b])
_ = Set([GCAxisElementName(rawValue: "x")])
_ = Set([GCSwitchElementName(rawValue: "s")])
_ = Set([GCDirectionPadElementName.directionPad])
_ = Set([GCPhysicalInputElementName(rawValue: "p")])

let virtualConfig = GCVirtualController.Configuration()
virtualConfig.elements = [GCInputButtonA, GCInputDirectionPad]
virtualConfig.isHidden = true
let virtual = GCVirtualController(configuration: virtualConfig)
precondition(virtual.controller == nil)
let virtualGate = DispatchSemaphore(value: 0)
var virtualError: (any Error)?
var virtualCount = 0
virtual.connect { error in
    virtualError = error
    virtualCount += 1
    virtualGate.signal()
}
precondition(virtualCount == 0)
precondition(virtualError == nil)
precondition(virtualGate.wait(timeout: .now() + 2) == .success)
precondition(virtualCount == 1)
precondition(virtualError != nil)
virtual.setValue(0.5, forButtonElement: GCInputButtonA)
virtual.setPosition(CGPoint(x: 0.2, y: -0.3), forDirectionPadElement: GCInputDirectionPad)
virtual.updateConfiguration(forElement: GCInputButtonA) { config in
    config.isHidden = true
    config.actsAsTouchpad = true
    return config
}
virtual.disconnect()

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
_ = GCDualSenseAdaptiveTrigger.PositionalAmplitudes(values: (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9))
_ = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths(values: (1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1))

let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
precondition(color.red == 0.1)
precondition(color.green == 0.2)
precondition(color.blue == 0.3)
precondition(GCColor.supportsSecureCoding)
do {
    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    color.encode(with: coder)
    let data = coder.encodedData
    let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
    _ = GCColor(coder: decoder)
} catch {
    _ = error
}

GCController.shouldMonitorBackgroundEvents = true
precondition(GCController.shouldMonitorBackgroundEvents)

let connect = GCController.DidConnectMessage(controller: snapshot)
precondition(connect.controller === snapshot)
precondition(GCController.DidConnectMessage.name == Notification.Name.GCControllerDidConnect)

var connectedNote: Notification?
var disconnectedNote: Notification?
var becameCurrentNote: Notification?
let nc = NotificationCenter.default
let tok1 = nc.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { connectedNote = $0 }
let tok2 = nc.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { disconnectedNote = $0 }
let tok3 = nc.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: nil) { becameCurrentNote = $0 }

let simulated = GCSimulatedInput.makeExtendedGamepad()
GCSimulatedInput.attach(simulated)
precondition(GCController.controllers().contains(where: { $0 === simulated }))
precondition(GCController.current === simulated)
precondition(connectedNote?.object as? GCController === simulated)
precondition(becameCurrentNote?.object as? GCController === simulated)
precondition(simulated.vendorName == "Simulated Extended Gamepad")
precondition(!simulated.isSnapshot)
simulated.playerIndex = .index2
precondition(simulated.extendedGamepad != nil)
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

let live = simulated.input
live.inputStateQueueDepth = 8
live.queue = handlerQueue
precondition(live.buttons[GCButtonElementName.a] != nil)
precondition(live[GCInputButtonA] != nil)
_ = live.dpads[GCDirectionPadElementName.leftThumbstick]
_ = live.elements
_ = live.axes
_ = live.switches
_ = live.lastEventLatency
_ = live.unmapped
live.elementValueDidChangeHandler = { _, _ in }
var available = 0
live.inputStateAvailableHandler = { _ in available += 1 }
simulated.extendedGamepad?.buttonB.setValue(0.75)
precondition(simulated.extendedGamepad?.buttonB.isPressed == true)
let queued = live.nextInputState()
precondition(queued != nil)
_ = queued?.lastEventTimestamp
if let element = live.buttons[GCButtonElementName.a] {
    _ = live.change(for: element)
}
_ = live.changedElements()
_ = live.capture()

let streamGate = DispatchSemaphore(value: 0)
var streamCount = 0
Task {
    for await _ in live.inputStates {
        streamCount += 1
        streamGate.signal()
        break
    }
}
Thread.sleep(forTimeInterval: 0.05)
simulated.extendedGamepad?.buttonY.setValue(1)
precondition(streamGate.wait(timeout: .now() + 2) == .success)
precondition(streamCount == 1)

let dualSense = GCSimulatedInput.makeDualSense()
GCSimulatedInput.attach(dualSense)
precondition(dualSense.productCategory == GCProductCategoryDualSense)
let dsPad = dualSense.extendedGamepad as? GCDualSenseGamepad
precondition(dsPad != nil)
_ = dsPad?.touchpadButton
_ = dsPad?.touchpadPrimary
_ = dsPad?.touchpadSecondary
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

let directional = GCSimulatedInput.makeDirectionalGamepad()
precondition(directional.microGamepad is GCDirectionalGamepad)

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
_ = touchpad.aliases
_ = touchpad.isBoundToSystemGesture
_ = touchpad.collection
_ = touchpad.localizedName
_ = touchpad.preferredSystemGestureState
_ = touchpad.sfSymbolsName
_ = touchpad.unmappedLocalizedName
_ = touchpad.unmappedSfSymbolsName

let sourceDir = GCPhysicalInputSourceDirection(rawValue: 1)
_ = GCPhysicalInputSourceDirection()
_ = sourceDir.rawValue
_ = GCUIEventTypes()
_ = GameControllerEventHandlingOptions()
_ = GameControllerEventHandlingOptions.receivesEventsInView(true)
var options = GameControllerEventHandlingOptions()
options.receivesEventsInView = true
precondition(options.receivesEventsInView)

let battery = GCDeviceBattery(level: 0, state: .unknown)
precondition(battery.batteryLevel == 0)
precondition(battery.batteryState == .unknown)
let light = GCDeviceLight(color: color)
precondition(light.color.red == color.red)
let haptics = GCDeviceHaptics()
precondition(haptics.supportedLocalities.isEmpty)
_ = GCHapticDurationInfinite

let activation = GCGameControllerActivationContext()
precondition(activation.previousApplicationBundleID == nil)

let quat = GCQuaternion()
_ = quat.x + quat.y + quat.z + quat.w
let accel = GCAcceleration()
_ = accel.x + accel.y + accel.z
let euler = GCEulerAngles(pitch: 1, yaw: 2, roll: 3)
_ = euler.pitch + euler.yaw + euler.roll
_ = GCEulerAngles()
let rate = GCRotationRate()
_ = rate.x + rate.y + rate.z

_ = GCCurrentExtendedGamepadSnapshotDataVersion
_ = GCCurrentMicroGamepadSnapshotDataVersion
_ = kIOHIDGCSyntheticDeviceKey
_ = GCControllerPlayerIndex(rawValue: 0)
_ = GCDeviceBattery.State(rawValue: 0)
_ = GCDevicePhysicalInputElementChange(rawValue: 0)
_ = GCDualSenseAdaptiveTrigger.Mode(rawValue: 0)
_ = GCDualSenseAdaptiveTrigger.Status(rawValue: 0)
_ = GCExtendedGamepadSnapshotDataVersion(rawValue: 1)
_ = GCMicroGamepadSnapshotDataVersion(rawValue: 1)
_ = GCControllerElement.SystemGestureState(rawValue: 0)
_ = GCControllerTouchpad.TouchState(rawValue: 0)
_ = GCHapticsLocality(rawValue: "All")
_ = GCUIEventTypes(rawValue: 1)

_gcOnMain {
    let note = Notification(name: .GCControllerDidConnect, object: simulated)
    _ = GCController.DidConnectMessage.makeMessage(note)
    _ = GCController.DidConnectMessage.makeNotification(connect)
    let disc = GCController.DidDisconnectMessage(controller: simulated)
    _ = GCController.DidDisconnectMessage.makeMessage(Notification(name: .GCControllerDidDisconnect, object: simulated))
    _ = GCController.DidDisconnectMessage.makeNotification(disc)
    let become = GCController.DidBecomeCurrentMessage(controller: simulated)
    _ = GCController.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCControllerDidBecomeCurrent, object: simulated))
    _ = GCController.DidBecomeCurrentMessage.makeNotification(become)
    let stop = GCController.DidStopBeingCurrentMessage(controller: simulated)
    _ = GCController.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCControllerDidStopBeingCurrent, object: simulated))
    _ = GCController.DidStopBeingCurrentMessage.makeNotification(stop)
    let kConn = GCKeyboard.DidConnectMessage(keyboard: keyboard)
    _ = GCKeyboard.DidConnectMessage.makeMessage(Notification(name: .GCKeyboardDidConnect, object: keyboard))
    _ = GCKeyboard.DidConnectMessage.makeNotification(kConn)
    let kDisc = GCKeyboard.DidDisconnectMessage(keyboard: keyboard)
    _ = GCKeyboard.DidDisconnectMessage.makeMessage(Notification(name: .GCKeyboardDidDisconnect, object: keyboard))
    _ = GCKeyboard.DidDisconnectMessage.makeNotification(kDisc)
    let mConn = GCMouse.DidConnectMessage(mouse: mouse)
    _ = GCMouse.DidConnectMessage.makeMessage(Notification(name: .GCMouseDidConnect, object: mouse))
    _ = GCMouse.DidConnectMessage.makeNotification(mConn)
    let mDisc = GCMouse.DidDisconnectMessage(mouse: mouse)
    _ = GCMouse.DidDisconnectMessage.makeMessage(Notification(name: .GCMouseDidDisconnect, object: mouse))
    _ = GCMouse.DidDisconnectMessage.makeNotification(mDisc)
    let mBecome = GCMouse.DidBecomeCurrentMessage(mouse: mouse)
    _ = GCMouse.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCMouseDidBecomeCurrent, object: mouse))
    _ = GCMouse.DidBecomeCurrentMessage.makeNotification(mBecome)
    let mStop = GCMouse.DidStopBeingCurrentMessage(mouse: mouse)
    _ = GCMouse.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCMouseDidStopBeingCurrent, object: mouse))
    _ = GCMouse.DidStopBeingCurrentMessage.makeNotification(mStop)
}

typealias _Axis = GCDeviceAxisInput
typealias _Button = GCDeviceButtonInput
typealias _Dpad = GCDeviceDirectionPad
typealias _El = GCDeviceElement
typealias _Touch = GCDeviceTouchpad
typealias _AxisH = GCControllerAxisValueChangedHandler
typealias _TouchedH = GCControllerButtonTouchedChangedHandler
typealias _ValueH = GCControllerButtonValueChangedHandler
typealias _DpadH = GCControllerDirectionPadValueChangedHandler
typealias _TouchH = GCControllerTouchpadHandler
typealias _KeyH = GCKeyboardValueChangedHandler
typealias _MouseH = GCMouseMoved
typealias _ExtH = GCExtendedGamepadValueChangedHandler
typealias _PadH = GCGamepadValueChangedHandler
typealias _MicroH = GCMicroGamepadValueChangedHandler
typealias _MotionH = GCMotionValueChangedHandler
_ = (any GCButtonElement).self

GCSimulatedInput.detach(simulated)
GCSimulatedInput.detach(dualSense)
GCSimulatedInput.detachKeyboard(keyboard)
GCSimulatedInput.detachMouse(mouse)
precondition(disconnectedNote?.object as? GCController === simulated || disconnectedNote != nil)
nc.removeObserver(tok1)
nc.removeObserver(tok2)
nc.removeObserver(tok3)
GCSimulatedInput.reset()
precondition(GCController.controllers().isEmpty)

print("GAMECONTROLLER_AGENT_RUNTIME_OK")
