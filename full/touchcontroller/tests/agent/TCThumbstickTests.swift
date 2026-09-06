import Foundation
import TouchController

func testAddThumbstickCopiesDescriptor() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 300, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCThumbstickDescriptor()
    descriptor.label = .rightThumbstick
    descriptor.hidesWhenNotPressed = true
    descriptor.stickSize = CGSize(width: 20, height: 20)
    descriptor.size = CGSize(width: 80, height: 80)
    descriptor.colliderShape = .circle
    descriptor.anchor = .bottomRight
    descriptor.anchorCoordinateSystem = .absolute
    let stick = canvas.addThumbstick(descriptor: descriptor)
    precondition(stick.label === TCControlLabel.rightThumbstick)
    precondition(stick.hidesWhenNotPressed)
    precondition(stick.stickSize.width == 20)
    precondition(stick.size.height == 80)
    precondition(stick.colliderShape == .circle)
    precondition(canvas.thumbsticks.count == 1)
}

func testThumbstickPressViaCircleCollider() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCThumbstickDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 40, height: 40)
    descriptor.colliderShape = .circle
    let stick = canvas.addThumbstick(descriptor: descriptor)
    let center = CGPoint(x: 20, y: 20)
    precondition(canvas.handleTouchBegan(at: center, index: 2))
    precondition(stick.isPressed)
    precondition(canvas.handleTouchMoved(at: CGPoint(x: 22, y: 18), index: 2))
    precondition(canvas.handleTouchEnded(at: center, index: 2))
    precondition(stick.isPressed == false)
}
