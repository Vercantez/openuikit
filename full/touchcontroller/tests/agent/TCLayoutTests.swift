import Foundation
import TouchController

private func makeCanvas(width: CGFloat = 200, height: CGFloat = 100) -> TCTouchController {
    let descriptor = TCTouchControllerDescriptor()
    descriptor.size = CGSize(width: width, height: height)
    descriptor.drawableSize = descriptor.size
    return TCTouchController(descriptor: descriptor)
}

func testLayoutPositionAbsoluteCenter() {
    let canvas = makeCanvas()
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .center
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.offset = .zero
    descriptor.size = CGSize(width: 20, height: 10)
    let button = canvas.addButton(descriptor: descriptor)
    precondition(button.position.x == 90)
    precondition(button.position.y == 45)
}

func testLayoutPositionAbsoluteCorners() {
    let canvas = makeCanvas(width: 100, height: 80)
    let topLeft = TCButtonDescriptor()
    topLeft.anchor = .topLeft
    topLeft.anchorCoordinateSystem = .absolute
    topLeft.size = CGSize(width: 10, height: 10)
    let topLeftButton = canvas.addButton(descriptor: topLeft)
    precondition(topLeftButton.position == .zero)

    let bottomRight = TCButtonDescriptor()
    bottomRight.anchor = .bottomRight
    bottomRight.anchorCoordinateSystem = .absolute
    bottomRight.size = CGSize(width: 10, height: 10)
    let bottomRightButton = canvas.addButton(descriptor: bottomRight)
    precondition(bottomRightButton.position.x == 90)
    precondition(bottomRightButton.position.y == 70)
}

func testLayoutPositionRelativeOffset() {
    let canvas = makeCanvas(width: 100, height: 100)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .relative
    descriptor.offset = CGPoint(x: 0.1, y: 0.2)
    descriptor.size = CGSize(width: 10, height: 10)
    let button = canvas.addButton(descriptor: descriptor)
    precondition(button.position.x == 10)
    precondition(button.position.y == 20)
}

func testLayoutPositionTracksCanvasSize() {
    let canvas = makeCanvas(width: 100, height: 100)
    let descriptor = TCButtonDescriptor()
    descriptor.anchor = .center
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.size = CGSize(width: 10, height: 10)
    let button = canvas.addButton(descriptor: descriptor)
    precondition(button.position.x == 45)
    canvas.size = CGSize(width: 200, height: 100)
    precondition(button.position.x == 95)
}
