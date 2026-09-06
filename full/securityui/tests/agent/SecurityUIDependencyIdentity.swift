import Foundation
import SecurityUI
import UIKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest UIKit/Security success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation, UIKit (and Security, if present) dylibs.
// 2. Build SecurityUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports SecurityUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `SECURITYUI_DEPENDENCY_IDENTITY_OK` and that `libSecurityUI.dylib`
//    was loaded.

private func assertNotSecurityUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SecurityUI."))
}

func assertFoundationIdentity() {
    let url = URL(string: "https://example.invalid/help")!
    assertNotSecurityUIType(url)
    let title = "Certificate"
    let message = "Inspect this certificate."
    assertNotSecurityUIType(title)
    assertNotSecurityUIType(message)
    _ = Foundation.Data.self
    _ = Foundation.Date.self
}

func assertUIKitIdentity() {
    let presenter = UIViewController()
    assertNotSecurityUIType(presenter)
    precondition(presenter is UIViewController)
}

func securityUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    print("SECURITYUI_DEPENDENCY_IDENTITY_OK")
}
