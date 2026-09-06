import Foundation
import TouchController

private func makeCanvas() -> TCTouchController {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 400, height: 300)
    return TCTouchController(descriptor: descriptor)
}

func testAddButtonCopiesDescriptorAndLayout() {
    let canvas = makeCanvas()
    let descriptor = TCButtonDescriptor()
    descriptor.label = .buttonX
    descriptor.anchor = .topRight
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.offset = CGPoint(x: -8, y: 8)
    descriptor.size = CGSize(width: 40, height: 40)
    descriptor.colliderShape = .rect
    descriptor.highlightDuration = 0.3
    descriptor.zIndex = 2
    let contents = TCControlContents.buttonContents(
        forSystemImageNamed: "xmark",
        size: CGSize(width: 24, height: 24),
        shape: .rect,
        controller: canvas
    )
    descriptor.contents = contents
    let button = canvas.addButton(descriptor: descriptor)
    precondition(button.label === TCControlLabel.buttonX)
    precondition(button.anchor == .topRight)
    precondition(button.anchorCoordinateSystem == .absolute)
    precondition(button.offset.x == -8)
    precondition(button.size.width == 40)
    precondition(button.colliderShape == .rect)
    precondition(button.highlightDuration == 0.3)
    precondition(button.zIndex == 2)
    precondition(button.contents === contents)
    precondition(button.isEnabled)
    precondition(button.isPressed == false)
    precondition(canvas.buttons.count == 1)
    precondition(canvas.buttons[0] === button)
}

func testButtonTouchPressAndRelease() {
    let canvas = makeCanvas()
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 40, height: 40)
    descriptor.colliderShape = .rect
    let button = canvas.addButton(descriptor: descriptor)
    let inside = CGPoint(x: 10, y: 10)
    precondition(canvas.handleTouchBegan(at: inside, index: 1))
    precondition(button.isPressed)
    precondition(canvas.handleTouchEnded(at: inside, index: 1))
    precondition(button.isPressed == false)
}

func testDisabledButtonIgnoresTouch() {
    let canvas = makeCanvas()
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 40, height: 40)
    descriptor.colliderShape = .rect
    let button = canvas.addButton(descriptor: descriptor)
    button.isEnabled = false
    precondition(canvas.handleTouchBegan(at: CGPoint(x: 5, y: 5), index: 0) == false)
    precondition(button.isPressed == false)
}
