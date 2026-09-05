import Foundation
import Dispatch
import GameController

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
