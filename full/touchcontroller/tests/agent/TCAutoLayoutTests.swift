import Foundation
import TouchController

func testAutomaticallyLayoutKnownLabels() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 400, height: 300)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    canvas.automaticallyLayoutControls(for: [
        .buttonA, .buttonB, .leftThumbstick, .directionPad, .buttonLeftShoulder
    ])
    precondition(canvas.buttons.count == 3)
    precondition(canvas.thumbsticks.count == 1)
    precondition(canvas.directionPads.count == 1)
    precondition(canvas.thumbsticks[0].label === TCControlLabel.leftThumbstick)
    precondition(canvas.directionPads[0].label === TCControlLabel.directionPad)
    let names = Set(canvas.buttons.map(\.label.name))
    precondition(names.contains("Button A"))
    precondition(names.contains("Button B"))
    precondition(names.contains("Left Shoulder"))
}

func testAutomaticallyLayoutIsIdempotentForSameLabels() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 400, height: 300)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    canvas.automaticallyLayoutControls(for: [.buttonA, .directionPad])
    canvas.automaticallyLayoutControls(for: [.buttonA, .directionPad])
    precondition(canvas.buttons.count == 1)
    precondition(canvas.directionPads.count == 1)
}

func testAutomaticallyLayoutRightThumbstickAnchor() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 400, height: 300)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    canvas.automaticallyLayoutControls(for: [.rightThumbstick])
    precondition(canvas.thumbsticks[0].anchor == .bottomRight)
    precondition(canvas.thumbsticks[0].size.width == 96)
}
