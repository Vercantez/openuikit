import Foundation
import TouchController

func testEnumRawValuesAndHashable() {
    precondition(TCColliderShape.circle.rawValue == 0)
    precondition(TCColliderShape.rect.rawValue == 1)
    precondition(TCColliderShape.leftSide.rawValue == 2)
    precondition(TCColliderShape.rightSide.rawValue == 3)
    precondition(TCColliderShape(rawValue: 0) == .circle)
    precondition(TCColliderShape(rawValue: 99) == nil)
    precondition(TCColliderShape.circle != .rect)
    _ = TCColliderShape.circle.hashValue
    var colliderHasher = Hasher()
    TCColliderShape.circle.hash(into: &colliderHasher)
    _ = colliderHasher.finalize()

    precondition(TCControlContents.ButtonShape.circle.rawValue == 0)
    precondition(TCControlContents.ButtonShape.rect.rawValue == 1)
    precondition(TCControlContents.ButtonShape(rawValue: 1) == .rect)
    precondition(TCControlContents.ButtonShape(rawValue: -1) == nil)
    precondition(TCControlContents.ButtonShape.circle != .rect)
    _ = TCControlContents.ButtonShape.rect.hashValue
    var buttonShapeHasher = Hasher()
    TCControlContents.ButtonShape.rect.hash(into: &buttonShapeHasher)
    _ = buttonShapeHasher.finalize()

    precondition(TCControlContents.DpadDirection.up.rawValue == 0)
    precondition(TCControlContents.DpadDirection.down.rawValue == 1)
    precondition(TCControlContents.DpadDirection.left.rawValue == 2)
    precondition(TCControlContents.DpadDirection.right.rawValue == 3)
    precondition(TCControlContents.DpadDirection(rawValue: 2) == .left)
    precondition(TCControlContents.DpadDirection(rawValue: 8) == nil)
    precondition(TCControlContents.DpadDirection.up != .down)
    _ = TCControlContents.DpadDirection.left.hashValue
    var dpadDirectionHasher = Hasher()
    TCControlContents.DpadDirection.left.hash(into: &dpadDirectionHasher)
    _ = dpadDirectionHasher.finalize()

    precondition(TCControlContents.DpadElementStyle.circle.rawValue == 0)
    precondition(TCControlContents.DpadElementStyle.pentagon.rawValue == 1)
    precondition(TCControlContents.DpadElementStyle(rawValue: 0) == .circle)
    precondition(TCControlContents.DpadElementStyle(rawValue: 4) == nil)
    precondition(TCControlContents.DpadElementStyle.circle != .pentagon)
    _ = TCControlContents.DpadElementStyle.pentagon.hashValue
    var dpadStyleHasher = Hasher()
    TCControlContents.DpadElementStyle.pentagon.hash(into: &dpadStyleHasher)
    _ = dpadStyleHasher.finalize()

    precondition(TCControlLabel.Role.button.rawValue == 0)
    precondition(TCControlLabel.Role.directionPad.rawValue == 1)
    precondition(TCControlLabel.Role(rawValue: 1) == .directionPad)
    precondition(TCControlLabel.Role(rawValue: 3) == nil)
    precondition(TCControlLabel.Role.button != .directionPad)
    _ = TCControlLabel.Role.button.hashValue
    var roleHasher = Hasher()
    TCControlLabel.Role.button.hash(into: &roleHasher)
    _ = roleHasher.finalize()

    precondition(TCControlLayoutAnchor.topLeft.rawValue == 0)
    precondition(TCControlLayoutAnchor.topCenter.rawValue == 1)
    precondition(TCControlLayoutAnchor.topRight.rawValue == 2)
    precondition(TCControlLayoutAnchor.centerLeft.rawValue == 3)
    precondition(TCControlLayoutAnchor.center.rawValue == 4)
    precondition(TCControlLayoutAnchor.centerRight.rawValue == 5)
    precondition(TCControlLayoutAnchor.bottomLeft.rawValue == 6)
    precondition(TCControlLayoutAnchor.bottomCenter.rawValue == 7)
    precondition(TCControlLayoutAnchor.bottomRight.rawValue == 8)
    precondition(TCControlLayoutAnchor(rawValue: 4) == .center)
    precondition(TCControlLayoutAnchor(rawValue: 20) == nil)
    precondition(TCControlLayoutAnchor.topLeft != .bottomRight)
    _ = TCControlLayoutAnchor.center.hashValue
    var anchorHasher = Hasher()
    TCControlLayoutAnchor.center.hash(into: &anchorHasher)
    _ = anchorHasher.finalize()

    precondition(TCControlLayoutAnchorCoordinateSystem.relative.rawValue == 0)
    precondition(TCControlLayoutAnchorCoordinateSystem.absolute.rawValue == 1)
    precondition(TCControlLayoutAnchorCoordinateSystem(rawValue: 0) == .relative)
    precondition(TCControlLayoutAnchorCoordinateSystem(rawValue: 5) == nil)
    precondition(TCControlLayoutAnchorCoordinateSystem.relative != .absolute)
    _ = TCControlLayoutAnchorCoordinateSystem.absolute.hashValue
    var systemHasher = Hasher()
    TCControlLayoutAnchorCoordinateSystem.absolute.hash(into: &systemHasher)
    _ = systemHasher.finalize()

    precondition(TCThrottle.Orientation.vertical.rawValue == 0)
    precondition(TCThrottle.Orientation.horizontal.rawValue == 1)
    precondition(TCThrottle.Orientation(rawValue: 1) == .horizontal)
    precondition(TCThrottle.Orientation(rawValue: 9) == nil)
    precondition(TCThrottle.Orientation.vertical != .horizontal)
    _ = TCThrottle.Orientation.vertical.hashValue
    var throttleHasher = Hasher()
    TCThrottle.Orientation.vertical.hash(into: &throttleHasher)
    _ = throttleHasher.finalize()
}
