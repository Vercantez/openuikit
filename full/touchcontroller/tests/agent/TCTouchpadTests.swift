import Foundation
import TouchController

func testAddTouchpadCopiesDescriptor() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 300, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCTouchpadDescriptor()
    descriptor.reportsRelativeValues = true
    descriptor.size = CGSize(width: 120, height: 80)
    descriptor.colliderShape = .rect
    descriptor.anchor = .center
    let pad = canvas.addTouchpad(descriptor: descriptor)
    precondition(pad.reportsRelativeValues)
    precondition(pad.size.width == 120)
    precondition(pad.colliderShape == .rect)
    pad.reportsRelativeValues = false
    precondition(pad.reportsRelativeValues == false)
    precondition(canvas.touchpads.count == 1)
}

func testTouchpadContentsAssignment() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let contents = TCControlContents(images: [])
    let descriptor = TCTouchpadDescriptor()
    descriptor.contents = contents
    descriptor.size = CGSize(width: 40, height: 40)
    let pad = canvas.addTouchpad(descriptor: descriptor)
    precondition(pad.contents === contents)
}
