import Foundation
import LocalAuthentication
import LocalAuthenticationEmbeddedUI
import UIKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest LocalAuthentication /
// UIKit success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest LocalAuthentication, Foundation, UIKit (and their dylibs).
// 2. Build LocalAuthenticationEmbeddedUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports LocalAuthenticationEmbeddedUI and
//    every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `LOCALAUTHENTICATIONEMBEDDEDUI_DEPENDENCY_IDENTITY_OK` and that
//    `libLocalAuthenticationEmbeddedUI.dylib` was loaded.

private func assertNotLocalAuthenticationEmbeddedUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("LocalAuthenticationEmbeddedUI."))
}

func assertFoundationIdentity() {
    let reason = "dependency-identity"
    precondition(reason.utf8.count > 0)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

func assertUIKitIdentity() {
    let window = UIWindow()
    assertNotLocalAuthenticationEmbeddedUIType(window)
    let context: LAPresentationContext = window
    precondition(type(of: context) == UIWindow.self)
    precondition(LAPresentationContext.self == UIWindow.self)
}

func assertLocalAuthenticationIdentity() {
    let right = LARight()
    assertNotLocalAuthenticationEmbeddedUIType(right)
    precondition(right.state == .unknown)
    let window = UIWindow()
    var captured: (any Error)?
    var calls = 0
    right.authorize(localizedReason: "identity", in: window) { error in
        calls += 1
        captured = error
    }
    precondition(calls == 1)
    let nsError = captured as NSError?
    precondition(nsError?.domain == "com.apple.LocalAuthentication")
    precondition(nsError?.code == -1004)
    precondition(right.state != .authorized)
}

func localAuthenticationEmbeddedUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    assertLocalAuthenticationIdentity()
    print("LOCALAUTHENTICATIONEMBEDDEDUI_DEPENDENCY_IDENTITY_OK")
}
