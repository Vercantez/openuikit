import Foundation
import TouchController

func testAddDirectionPadCopiesDescriptor() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 300, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCDirectionPadDescriptor()
    descriptor.isDigital = false
    descriptor.isRadial = true
    descriptor.inputIsMutuallyExclusive = false
    descriptor.size = CGSize(width: 64, height: 64)
    descriptor.anchor = .bottomLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.upLabel = .buttonY
    descriptor.downLabel = .buttonA
    descriptor.leftLabel = .buttonX
    descriptor.rightLabel = .buttonB
    descriptor.upContents = TCControlContents(images: [])
    descriptor.downContents = TCControlContents(images: [])
    descriptor.leftContents = TCControlContents(images: [])
    descriptor.rightContents = TCControlContents(images: [])
    descriptor.highlightDuration = 0.15
    descriptor.colliderShape = .rect
    let pad = canvas.addDirectionPad(descriptor: descriptor)
    precondition(pad.isDigital == false)
    precondition(pad.isRadial)
    precondition(pad.inputIsMutuallyExclusive == false)
    precondition(pad.upLabel === TCControlLabel.buttonY)
    precondition(pad.downLabel === TCControlLabel.buttonA)
    precondition(pad.leftLabel === TCControlLabel.buttonX)
    precondition(pad.rightLabel === TCControlLabel.buttonB)
    precondition(pad.label === TCControlLabel.directionPad)
    precondition(pad.colliderShape == .rect)
    precondition(pad.highlightDuration == 0.15)
    precondition(pad.compositeLabel === TCControlLabel.directionPad)
    precondition(pad.upContents != nil)
    precondition(pad.downContents != nil)
    precondition(pad.leftContents != nil)
    precondition(pad.rightContents != nil)
    precondition(canvas.directionPads.count == 1)
}

func testDirectionPadContentsAssignment() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let up = TCControlContents.directionPadContents(
        label: .directionPad,
        size: CGSize(width: 16, height: 16),
        style: .pentagon,
        direction: .up,
        controller: canvas
    )
    let descriptor = TCDirectionPadDescriptor()
    descriptor.upContents = up
    descriptor.size = CGSize(width: 64, height: 64)
    let pad = canvas.addDirectionPad(descriptor: descriptor)
    precondition(pad.upContents === up)
    pad.downContents = TCControlContents.directionPadContents(
        label: .directionPad,
        size: CGSize(width: 16, height: 16),
        style: .circle,
        direction: .down,
        controller: canvas
    )
    precondition(pad.downContents != nil)
}
