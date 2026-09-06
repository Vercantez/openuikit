import Foundation
import TouchController

func testAddThrottleCopiesDescriptorAndClampsBaseValue() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 300, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let descriptor = TCThrottleDescriptor()
    descriptor.orientation = .horizontal
    descriptor.snapsToBaseValue = false
    descriptor.baseValue = 1.5
    descriptor.indicatorSize = CGSize(width: 6, height: 12)
    descriptor.throttleSize = CGSize(width: 80, height: 16)
    descriptor.size = CGSize(width: 80, height: 16)
    let throttle = canvas.addThrottle(descriptor: descriptor)
    precondition(throttle.orientation == .horizontal)
    precondition(throttle.snapsToBaseValue == false)
    precondition(throttle.baseValue == 1)
    throttle.baseValue = -0.2
    precondition(throttle.baseValue == 0)
    throttle.baseValue = 0.25
    precondition(throttle.baseValue == 0.25)
    precondition(throttle.indicatorSize.width == 6)
    precondition(throttle.throttleSize.height == 16)
    precondition(canvas.throttles.count == 1)
}

func testThrottleBackgroundAndIndicatorContents() {
    let canvasDescriptor = TCTouchControllerDescriptor()
    canvasDescriptor.size = CGSize(width: 200, height: 200)
    let canvas = TCTouchController(descriptor: canvasDescriptor)
    let background = TCControlContents.throttleBackgroundContents(
        size: CGSize(width: 20, height: 80),
        controller: canvas
    )
    let indicator = TCControlContents.throttleIndicatorContents(
        size: CGSize(width: 12, height: 12),
        controller: canvas
    )
    let descriptor = TCThrottleDescriptor()
    descriptor.backgroundContents = background
    descriptor.indicatorContents = indicator
    descriptor.size = CGSize(width: 20, height: 80)
    let throttle = canvas.addThrottle(descriptor: descriptor)
    precondition(throttle.backgroundContents === background)
    precondition(throttle.indicatorContents === indicator)
}
