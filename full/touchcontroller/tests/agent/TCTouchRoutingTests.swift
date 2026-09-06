import Foundation
import TouchController

func testTouchRoutingUnknownIndexReturnsFalse() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    precondition(canvas.handleTouchMoved(at: .zero, index: 9) == false)
    precondition(canvas.handleTouchEnded(at: .zero, index: 9) == false)
}

func testTouchRoutingMissReturnsFalse() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 10, height: 10)
    descriptor.colliderShape = .rect
    _ = canvas.addButton(descriptor: descriptor)
    precondition(canvas.handleTouchBegan(at: CGPoint(x: 50, y: 50), index: 0) == false)
}

func testDirectProtocolTouchHandlers() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 20, height: 20)
    descriptor.colliderShape = .rect
    let button: any TCControl = canvas.addButton(descriptor: descriptor)
    button.handleTouchBegan(at: CGPoint(x: 5, y: 5))
    precondition(button.isPressed)
    button.handleTouchMoved(at: CGPoint(x: 6, y: 6))
    button.handleTouchEnded(at: CGPoint(x: 5, y: 5))
    precondition(button.isPressed == false)
}

func testRemoveControlAndRemoveAll() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let first = TCButtonDescriptor()
    first.size = CGSize(width: 10, height: 10)
    first.anchorCoordinateSystem = .absolute
    first.anchor = .topLeft
    first.colliderShape = .rect
    let a = canvas.addButton(descriptor: first)
    let second = TCButtonDescriptor()
    second.size = CGSize(width: 10, height: 10)
    second.anchorCoordinateSystem = .absolute
    second.anchor = .topLeft
    second.offset = CGPoint(x: 50, y: 0)
    second.colliderShape = .rect
    let b = canvas.addButton(descriptor: second)
    precondition(canvas.controls.count == 2)
    canvas.removeControl(a)
    precondition(canvas.controls.count == 1)
    precondition(canvas.buttons[0] === b)
    canvas.removeAllControls()
    precondition(canvas.controls.isEmpty)
    precondition(canvas.buttons.isEmpty)
}
