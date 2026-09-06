import Foundation
import TouchController

func testControlProtocolExistentialLayoutWitnesses() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 120, height: 80)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .centerLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 10, height: 10)
    descriptor.offset = CGPoint(x: 4, y: 0)
    let button = canvas.addButton(descriptor: descriptor)
    let layout: any TCControlLayout = button
    precondition(layout.anchor == .centerLeft)
    precondition(layout.anchorCoordinateSystem == .absolute)
    precondition(layout.size.width == 10)
    layout.zIndex = 9
    layout.offset = CGPoint(x: 6, y: 1)
    layout.size = CGSize(width: 12, height: 12)
    layout.anchor = .center
    layout.anchorCoordinateSystem = .relative
    precondition(button.zIndex == 9)
    precondition(button.offset.x == 6)
    precondition(button.size.height == 12)
    precondition(button.anchor == .center)
    _ = layout.position
    let control: any TCControl = button
    precondition(control.label === TCControlLabel.buttonA)
    precondition(control.colliderShape == .circle)
    control.isEnabled = false
    precondition(button.isEnabled == false)
    control.highlightDuration = 0.5
    precondition(button.highlightDuration == 0.5)
}

func testProductCategoryAndSupportFlags() {
    precondition(TCGameControllerProductCategoryTouchController == "Touch Controller")
    precondition(TCTouchController.isSupported == false)
    precondition(TouchControllerLinuxSupport.isSupported == false)
}

func testConnectDisconnectFailClosed() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: descriptor)
    precondition(canvas.isConnected == false)
    canvas.connect()
    precondition(canvas.isConnected == false)
    canvas.disconnect()
    precondition(canvas.isConnected == false)
}

func testControllerStoresSizeAndDrawableSize() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 320, height: 180)
    descriptor.drawableSize = CGSize(width: 640, height: 360)
    let canvas = TCTouchController(descriptor: descriptor)
    precondition(canvas.size.width == 320)
    precondition(canvas.drawableSize.height == 360)
    canvas.size = CGSize(width: 100, height: 50)
    canvas.drawableSize = CGSize(width: 200, height: 100)
    precondition(canvas.size.height == 50)
    precondition(canvas.drawableSize.width == 200)
}

func testControllerTypedCollections() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: descriptor)
    _ = canvas.addButton(descriptor: TCButtonDescriptor())
    _ = canvas.addSwitch(descriptor: TCSwitchDescriptor())
    _ = canvas.addThumbstick(descriptor: TCThumbstickDescriptor())
    _ = canvas.addDirectionPad(descriptor: TCDirectionPadDescriptor())
    _ = canvas.addThrottle(descriptor: TCThrottleDescriptor())
    _ = canvas.addTouchpad(descriptor: TCTouchpadDescriptor())
    precondition(canvas.controls.count == 6)
    precondition(canvas.buttons.count == 1)
    precondition(canvas.switches.count == 1)
    precondition(canvas.thumbsticks.count == 1)
    precondition(canvas.directionPads.count == 1)
    precondition(canvas.throttles.count == 1)
    precondition(canvas.touchpads.count == 1)
}
