import Foundation
import TouchController

func testProtocolHighlightDurationOnAllControls() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let button = canvas.addButton(descriptor: TCButtonDescriptor())
    let sw = canvas.addSwitch(descriptor: TCSwitchDescriptor())
    let stick = canvas.addThumbstick(descriptor: TCThumbstickDescriptor())
    let pad = canvas.addDirectionPad(descriptor: TCDirectionPadDescriptor())
    let throttle = canvas.addThrottle(descriptor: TCThrottleDescriptor())
    let touchpad = canvas.addTouchpad(descriptor: TCTouchpadDescriptor())
    button.highlightDuration = 0.1
    sw.highlightDuration = 0.2
    stick.highlightDuration = 0.3
    pad.highlightDuration = 0.4
    throttle.highlightDuration = 0.5
    touchpad.highlightDuration = 0.6
    precondition(button.highlightDuration == 0.1)
    precondition(sw.highlightDuration == 0.2)
    precondition(stick.highlightDuration == 0.3)
    precondition(pad.highlightDuration == 0.4)
    precondition(throttle.highlightDuration == 0.5)
    precondition(touchpad.highlightDuration == 0.6)
}
