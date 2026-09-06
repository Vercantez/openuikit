import Foundation
import TouchController

func testHitTestingRectCollider() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 40, height: 20)
    descriptor.colliderShape = .rect
    let button = canvas.addButton(descriptor: descriptor)
    let hit = canvas.control(at: CGPoint(x: 39, y: 19))
    precondition(hit as AnyObject === button)
    precondition(canvas.control(at: CGPoint(x: 41, y: 10)) == nil)
}

func testHitTestingCircleCollider() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 40, height: 40)
    descriptor.colliderShape = .circle
    _ = canvas.addButton(descriptor: descriptor)
    precondition(canvas.control(at: CGPoint(x: 20, y: 20)) != nil)
    precondition(canvas.control(at: CGPoint(x: 1, y: 1)) == nil)
}

func testHitTestingLeftAndRightSideColliders() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let left = TCButtonDescriptor()
    left.anchor = .topLeft
    left.anchorCoordinateSystem = .absolute
    left.size = CGSize(width: 40, height: 40)
    left.colliderShape = .leftSide
    left.zIndex = 1
    let leftButton = canvas.addButton(descriptor: left)
    precondition(canvas.control(at: CGPoint(x: 5, y: 20)) as AnyObject === leftButton)
    precondition(canvas.control(at: CGPoint(x: 30, y: 20)) == nil)

    canvas.removeAllControls()
    let right = TCButtonDescriptor()
    right.anchor = .topLeft
    right.anchorCoordinateSystem = .absolute
    right.size = CGSize(width: 40, height: 40)
    right.colliderShape = .rightSide
    let rightButton = canvas.addButton(descriptor: right)
    precondition(canvas.control(at: CGPoint(x: 30, y: 20)) as AnyObject === rightButton)
    precondition(canvas.control(at: CGPoint(x: 5, y: 20)) == nil)
}

func testHitTestingZIndexPriority() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let low = TCButtonDescriptor()
    low.anchor = .topLeft
    low.anchorCoordinateSystem = .absolute
    low.size = CGSize(width: 40, height: 40)
    low.colliderShape = .rect
    low.zIndex = 1
    low.label = .buttonA
    let lowButton = canvas.addButton(descriptor: low)
    let high = TCButtonDescriptor()
    high.anchor = .topLeft
    high.anchorCoordinateSystem = .absolute
    high.size = CGSize(width: 40, height: 40)
    high.colliderShape = .rect
    high.zIndex = 5
    high.label = .buttonB
    let highButton = canvas.addButton(descriptor: high)
    let hit = canvas.control(at: CGPoint(x: 10, y: 10))
    precondition(hit as AnyObject === highButton)
    precondition(hit as AnyObject !== lowButton)
}
