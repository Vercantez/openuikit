import Foundation
@_spi(OpenUIKitHost) import CoreLocationUI

func testLocationButtonInit() {
    let zero = CLLocationButton()
    precondition(zero.frame == .zero)
    precondition(zero.icon == CLLocationButtonIcon.none)
    precondition(zero.label == .currentLocation)
    precondition(zero.fontSize == 0)
    precondition(zero.cornerRadius == 0)
    precondition(CLLocationButton.supportsSecureCoding)

    let framed = CLLocationButton(frame: CGRect(x: 1, y: 2, width: 44, height: 44))
    precondition(framed.frame.origin.x == 1)
    precondition(framed.frame.origin.y == 2)
    precondition(framed.frame.width == 44)
    precondition(framed.frame.height == 44)

    switch CoreLocationUIHostControl.requestOneTimeAuthorization(framed) {
    case .success:
        preconditionFailure("Linux must not invent a location grant")
    case .failure(let error):
        precondition(error == .linuxHost(operation: "CLLocationButton.oneTimeAuthorization"))
    }
    precondition(CoreLocationUIHostControl.authorizationAttempts(of: framed) == 1)
    framed.sendActions(for: .touchUpInside)
    precondition(CoreLocationUIHostControl.authorizationAttempts(of: framed) == 2)

    framed.icon = .arrowFilled
    framed.label = .shareCurrentLocation
    framed.fontSize = 18
    framed.cornerRadius = 25
    let data = try! NSKeyedArchiver.archivedData(withRootObject: framed, requiringSecureCoding: true)
    let restored = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocationButton.self, from: data)
    precondition(restored != nil)
    precondition(restored?.icon == .arrowFilled)
    precondition(restored?.label == .shareCurrentLocation)
    precondition(restored?.fontSize == 18)
    precondition(restored?.cornerRadius == 25)
}

func testLocationButtonCornerRadius() {
    let button = CLLocationButton()
    precondition(button.cornerRadius == 0)
    button.cornerRadius = 25
    precondition(button.cornerRadius == 25)
    button.cornerRadius = 0
    precondition(button.cornerRadius == 0)
}

func testLocationButtonFontSize() {
    let button = CLLocationButton()
    precondition(button.fontSize == 0)
    button.fontSize = 17
    precondition(button.fontSize == 17)
    button.fontSize = 12.5
    precondition(button.fontSize == 12.5)
}

func testLocationButtonIcon() {
    let button = CLLocationButton()
    precondition(button.icon == CLLocationButtonIcon.none)
    button.icon = .arrowFilled
    precondition(button.icon == .arrowFilled)
    button.icon = .arrowOutline
    precondition(button.icon == .arrowOutline)
    button.icon = CLLocationButtonIcon.none
    precondition(button.icon == CLLocationButtonIcon.none)
}

func testLocationButtonLabel() {
    let button = CLLocationButton()
    precondition(button.label == .currentLocation)
    button.label = CLLocationButtonLabel.none
    precondition(button.label == CLLocationButtonLabel.none)
    button.label = .sendCurrentLocation
    precondition(button.label == .sendCurrentLocation)
    button.label = .sendMyCurrentLocation
    precondition(button.label == .sendMyCurrentLocation)
    button.label = .shareCurrentLocation
    precondition(button.label == .shareCurrentLocation)
    button.label = .shareMyCurrentLocation
    precondition(button.label == .shareMyCurrentLocation)
    button.label = .currentLocation
    precondition(button.label == .currentLocation)
}
