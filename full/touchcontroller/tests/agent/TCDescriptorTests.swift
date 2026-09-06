import Foundation
import TouchController

func testButtonDescriptorDefaultsAndMutation() {
    let descriptor = TCButtonDescriptor()
    precondition(descriptor.label === TCControlLabel.buttonA)
    precondition(descriptor.contents == nil)
    precondition(descriptor.anchor == .center)
    precondition(descriptor.anchorCoordinateSystem == .relative)
    precondition(descriptor.offset == .zero)
    precondition(descriptor.zIndex == 0)
    precondition(descriptor.size == .zero)
    precondition(descriptor.colliderShape == .circle)
    precondition(descriptor.highlightDuration == 0)
    descriptor.label = .buttonB
    descriptor.anchor = .topLeft
    descriptor.anchorCoordinateSystem = .absolute
    descriptor.offset = CGPoint(x: 3, y: 4)
    descriptor.zIndex = 7
    descriptor.size = CGSize(width: 32, height: 48)
    descriptor.colliderShape = .rect
    descriptor.highlightDuration = 0.25
    precondition(descriptor.label === TCControlLabel.buttonB)
    precondition(descriptor.anchor == .topLeft)
    precondition(descriptor.anchorCoordinateSystem == .absolute)
    precondition(descriptor.offset.x == 3)
    precondition(descriptor.zIndex == 7)
    precondition(descriptor.size.width == 32)
    precondition(descriptor.colliderShape == .rect)
    precondition(descriptor.highlightDuration == 0.25)
}

func testSwitchDescriptorDefaultsAndMutation() {
    let descriptor = TCSwitchDescriptor()
    precondition(descriptor.switchedOnContents == nil)
    descriptor.colliderShape = .leftSide
    descriptor.size = CGSize(width: 20, height: 20)
    precondition(descriptor.colliderShape == .leftSide)
    precondition(descriptor.size.height == 20)
}

func testThumbstickDescriptorDefaultsAndMutation() {
    let descriptor = TCThumbstickDescriptor()
    precondition(descriptor.label === TCControlLabel.leftThumbstick)
    precondition(descriptor.hidesWhenNotPressed == false)
    precondition(descriptor.anchor == .bottomLeft)
    descriptor.hidesWhenNotPressed = true
    descriptor.stickSize = CGSize(width: 12, height: 12)
    descriptor.label = .rightThumbstick
    precondition(descriptor.hidesWhenNotPressed)
    precondition(descriptor.stickSize.width == 12)
    precondition(descriptor.label === TCControlLabel.rightThumbstick)
}

func testDirectionPadDescriptorDefaultsAndMutation() {
    let descriptor = TCDirectionPadDescriptor()
    precondition(descriptor.compositeLabel === TCControlLabel.directionPad)
    precondition(descriptor.isDigital)
    precondition(descriptor.inputIsMutuallyExclusive)
    precondition(descriptor.isRadial == false)
    descriptor.isRadial = true
    descriptor.isDigital = false
    descriptor.inputIsMutuallyExclusive = false
    descriptor.upLabel = .buttonY
    descriptor.downLabel = .buttonA
    descriptor.leftLabel = .buttonX
    descriptor.rightLabel = .buttonB
    descriptor.upContents = TCControlContents(images: [])
    descriptor.downContents = TCControlContents(images: [])
    descriptor.leftContents = TCControlContents(images: [])
    descriptor.rightContents = TCControlContents(images: [])
    descriptor.highlightDuration = 0.4
    descriptor.zIndex = 3
    descriptor.size = CGSize(width: 70, height: 70)
    descriptor.offset = CGPoint(x: 1, y: 2)
    descriptor.colliderShape = .circle
    descriptor.anchor = .center
    descriptor.anchorCoordinateSystem = .absolute
    precondition(descriptor.isRadial)
    precondition(descriptor.isDigital == false)
    precondition(descriptor.upLabel === TCControlLabel.buttonY)
    precondition(descriptor.upContents != nil)
    precondition(descriptor.highlightDuration == 0.4)
    precondition(descriptor.zIndex == 3)
    precondition(descriptor.colliderShape == .circle)
}

func testThrottleDescriptorDefaultsAndMutation() {
    let descriptor = TCThrottleDescriptor()
    precondition(descriptor.orientation == .vertical)
    precondition(descriptor.snapsToBaseValue)
    precondition(descriptor.baseValue == 0)
    descriptor.orientation = .horizontal
    descriptor.baseValue = 0.4
    descriptor.snapsToBaseValue = false
    descriptor.indicatorSize = CGSize(width: 8, height: 16)
    descriptor.throttleSize = CGSize(width: 12, height: 64)
    precondition(descriptor.orientation == .horizontal)
    precondition(descriptor.baseValue == 0.4)
    precondition(descriptor.snapsToBaseValue == false)
    precondition(descriptor.indicatorSize.height == 16)
}

func testTouchpadDescriptorDefaultsAndMutation() {
    let descriptor = TCTouchpadDescriptor()
    precondition(descriptor.reportsRelativeValues == false)
    descriptor.reportsRelativeValues = true
    descriptor.colliderShape = .rightSide
    precondition(descriptor.reportsRelativeValues)
    precondition(descriptor.colliderShape == .rightSide)
}

func testTouchControllerDescriptorSizeAndSampleCount() {
    let descriptor = TCTouchControllerDescriptor()
    precondition(descriptor.size == .zero)
    precondition(descriptor.drawableSize == .zero)
    precondition(descriptor.sampleCount == 1)
    descriptor.size = CGSize(width: 400, height: 240)
    descriptor.drawableSize = CGSize(width: 800, height: 480)
    descriptor.sampleCount = 4
    precondition(descriptor.size.width == 400)
    precondition(descriptor.drawableSize.height == 480)
    precondition(descriptor.sampleCount == 4)
}
