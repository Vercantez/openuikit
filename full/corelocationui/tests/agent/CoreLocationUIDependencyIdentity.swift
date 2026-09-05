import CoreLocationUI
import CoreLocation
import Foundation
import UIKit
@_spi(OpenUIKitHost) import CoreLocationUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest CoreLocation/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest CoreLocation, Foundation, UIKit (and their dylibs).
// 2. Build CoreLocationUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports CoreLocationUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `CORELOCATIONUI_DEPENDENCY_IDENTITY_OK` and that
//    `libCoreLocationUI.dylib` was loaded.

private func assertNotCoreLocationUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CoreLocationUI."))
}

func assertFoundationIdentity() {
    let frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    assertNotCoreLocationUIType(frame)
    let button = CLLocationButton(frame: frame)
    button.fontSize = CGFloat(17)
    button.cornerRadius = CGFloat(25)
    precondition(button.fontSize == 17)
    precondition(button.cornerRadius == 25)
    precondition(button.frame.width == 44)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

func assertUIKitIdentity() {
    let button = CLLocationButton(frame: .zero)
    precondition(button is UIControl)
    precondition(type(of: button).superclass() == UIControl.self || button is UIView)
    button.sendActions(for: .touchUpInside)
}

func assertCoreLocationIdentity() {
    // CoreLocationUI does not take CLLocation values. Importing CoreLocation
    // and constructing a coordinate next to a button proves the modules share
    // a process; the button still cannot fabricate a location.
    let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    assertNotCoreLocationUIType(coordinate)
    let button = CLLocationButton()
    let result = CoreLocationUIHostControl.requestOneTimeAuthorization(button)
    switch result {
    case .success:
        preconditionFailure("Linux must not invent a location grant")
    case .failure(let error):
        precondition(error == .linuxHost(operation: "CLLocationButton.oneTimeAuthorization"))
    }
    _ = coordinate.latitude
}

func coreLocationUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    assertCoreLocationIdentity()
    print("CORELOCATIONUI_DEPENDENCY_IDENTITY_OK")
}
