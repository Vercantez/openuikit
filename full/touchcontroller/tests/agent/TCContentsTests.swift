import Foundation
import TouchController

func testControlContentsInitImagesAndFactories() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let empty = TCControlContents(images: [])
    precondition(empty.images.isEmpty)

    let button = TCControlContents.buttonContents(
        forSystemImageNamed: "a.circle",
        size: CGSize(width: 24, height: 18),
        shape: .circle,
        controller: canvas
    )
    precondition(button.images.count == 1)
    precondition(button.images[0].size.width == 24)
    precondition(button.images[0].size.height == 18)
    precondition(button.images[0].offset == .zero)

    let switched = TCControlContents.switchedOnContents(
        forSystemImageNamed: "a.circle.fill",
        size: CGSize(width: 10, height: 10),
        shape: .rect,
        controller: canvas
    )
    precondition(switched.images[0].size.width == 10)

    let stick = TCControlContents.thumbstickStickContents(
        size: CGSize(width: 14, height: 14),
        controller: canvas
    )
    precondition(stick.images[0].size.width == 14)
    let background = TCControlContents.thumbstickStickBackgroundContents(
        size: CGSize(width: 40, height: 40),
        controller: canvas
    )
    precondition(background.images[0].size.height == 40)

    let copied = TCControlContents(images: button.images)
    precondition(copied.images.count == 1)
    copied.images[0].offset = CGPoint(x: 2, y: 3)
    precondition(copied.images[0].offset.x == 2)
}

func testControlImageSizeAndOffsetMutation() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 100, height: 100)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let contents = TCControlContents.throttleIndicatorContents(
        size: CGSize(width: 8, height: 9),
        controller: canvas
    )
    let image = contents.images[0]
    image.size = CGSize(width: 11, height: 12)
    image.offset = CGPoint(x: -1, y: 4)
    precondition(image.size.width == 11)
    precondition(image.size.height == 12)
    precondition(image.offset.y == 4)
}
