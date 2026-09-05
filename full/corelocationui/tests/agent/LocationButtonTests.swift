import Foundation
@_spi(OpenUIKitHost) import CoreLocationUI

func testSwiftLocationButtonConstruct() {
    var invoked = false
    let button = LocationButton {
        invoked = true
    }
    precondition(type(of: button) == LocationButton.self)
    precondition(CoreLocationUIHostControl.title(of: button) == .currentLocation)
    precondition(!invoked)
}

func testSwiftLocationButtonBody() {
    let button = LocationButton(.shareCurrentLocation, action: {})
    let empty: LocationButton.Body = EmptyView()
    let body: LocationButton.Body = button.body
    _ = empty
    _ = body
}

func testSwiftLocationButtonTitle() {
    let titles: [LocationButton.Title] = [
        .currentLocation,
        .sendCurrentLocation,
        .sendMyCurrentLocation,
        .shareCurrentLocation,
        .shareMyCurrentLocation,
    ]
    precondition(Set(titles).count == 5)
    precondition(LocationButton.Title.currentLocation.label == .currentLocation)
    precondition(LocationButton.Title.sendCurrentLocation != .shareCurrentLocation)
}

func testTitleCurrentLocation() {
    precondition(LocationButton.Title.currentLocation == .currentLocation)
    precondition(LocationButton.Title.currentLocation.label == .currentLocation)
    precondition(LocationButton.Title.currentLocation != .sendCurrentLocation)
}

func testTitleSendCurrentLocation() {
    precondition(LocationButton.Title.sendCurrentLocation == .sendCurrentLocation)
    precondition(LocationButton.Title.sendCurrentLocation.label == .sendCurrentLocation)
    precondition(LocationButton.Title.sendCurrentLocation != .currentLocation)
}

func testTitleSendMyCurrentLocation() {
    precondition(LocationButton.Title.sendMyCurrentLocation == .sendMyCurrentLocation)
    precondition(LocationButton.Title.sendMyCurrentLocation.label == .sendMyCurrentLocation)
    precondition(LocationButton.Title.sendMyCurrentLocation != .sendCurrentLocation)
}

func testTitleShareCurrentLocation() {
    precondition(LocationButton.Title.shareCurrentLocation == .shareCurrentLocation)
    precondition(LocationButton.Title.shareCurrentLocation.label == .shareCurrentLocation)
    precondition(LocationButton.Title.shareCurrentLocation != .shareMyCurrentLocation)
}

func testTitleShareMyCurrentLocation() {
    precondition(LocationButton.Title.shareMyCurrentLocation == .shareMyCurrentLocation)
    precondition(LocationButton.Title.shareMyCurrentLocation.label == .shareMyCurrentLocation)
    precondition(LocationButton.Title.shareMyCurrentLocation != .currentLocation)
}

func testSwiftLocationButtonInit() {
    var invoked = 0
    let explicit = LocationButton(.sendMyCurrentLocation) {
        invoked += 1
    }
    precondition(CoreLocationUIHostControl.title(of: explicit) == .sendMyCurrentLocation)

    let defaulted = LocationButton(action: {})
    precondition(CoreLocationUIHostControl.title(of: defaulted) == .currentLocation)

    let nilTitle = LocationButton(nil, action: {})
    precondition(CoreLocationUIHostControl.title(of: nilTitle) == nil)

    switch CoreLocationUIHostControl.activate(explicit) {
    case .success:
        preconditionFailure("Linux must not invent a location grant")
    case .failure(let error):
        precondition(error == .linuxHost(operation: "LocationButton.oneTimeAuthorization"))
    }
    precondition(CoreLocationUIHostControl.activationAttempts(of: explicit) == 1)
    precondition(invoked == 0)

    CoreLocationUIHostControl.invokeStoredAction(explicit)
    precondition(invoked == 1)
}
