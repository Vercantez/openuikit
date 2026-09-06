import Foundation
import TouchController

func testSwitchToggleOnTouchEndedInside() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: descriptor)
    let switchDescriptor = TCSwitchDescriptor()
    switchDescriptor.anchor = .topLeft
    switchDescriptor.anchorCoordinateSystem = .absolute
    switchDescriptor.size = CGSize(width: 50, height: 50)
    switchDescriptor.colliderShape = .rect
    let control = canvas.addSwitch(descriptor: switchDescriptor)
    precondition(control.isSwitchedOn == false)
    let point = CGPoint(x: 10, y: 10)
    precondition(canvas.handleTouchBegan(at: point, index: 0))
    precondition(control.isPressed)
    precondition(control.isSwitchedOn == false)
    precondition(canvas.handleTouchEnded(at: point, index: 0))
    precondition(control.isSwitchedOn)
    precondition(control.isPressed == false)
    precondition(canvas.handleTouchBegan(at: point, index: 0))
    precondition(canvas.handleTouchEnded(at: point, index: 0))
    precondition(control.isSwitchedOn == false)
}

func testSwitchDoesNotToggleWhenReleasedOutside() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: descriptor)
    let switchDescriptor = TCSwitchDescriptor()
    switchDescriptor.anchor = .topLeft
    switchDescriptor.anchorCoordinateSystem = .absolute
    switchDescriptor.size = CGSize(width: 50, height: 50)
    switchDescriptor.colliderShape = .rect
    let control = canvas.addSwitch(descriptor: switchDescriptor)
    precondition(canvas.handleTouchBegan(at: CGPoint(x: 10, y: 10), index: 3))
    precondition(canvas.handleTouchEnded(at: CGPoint(x: 180, y: 180), index: 3))
    precondition(control.isSwitchedOn == false)
}

func testSwitchContentsAndCollection() {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: descriptor)
    let switchDescriptor = TCSwitchDescriptor()
    switchDescriptor.contents = TCControlContents.buttonContents(
        forSystemImageNamed: "circle",
        size: CGSize(width: 16, height: 16),
        shape: .circle,
        controller: canvas
    )
    switchDescriptor.switchedOnContents = TCControlContents.switchedOnContents(
        forSystemImageNamed: "circle.fill",
        size: CGSize(width: 16, height: 16),
        shape: .circle,
        controller: canvas
    )
    let control = canvas.addSwitch(descriptor: switchDescriptor)
    precondition(control.contents != nil)
    precondition(control.switchedOnContents != nil)
    precondition(canvas.switches.count == 1)
    precondition(canvas.switches[0] === control)
}
