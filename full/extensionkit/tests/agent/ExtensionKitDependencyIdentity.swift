import ExtensionKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Foundation / UIKit /
// SwiftUI / ExtensionFoundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and UIKit / SwiftUI / ExtensionFoundation when
//    those lanes exist).
// 2. Build ExtensionKit with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports ExtensionKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `EXTENSIONKIT_DEPENDENCY_IDENTITY_OK` and that
//    `libExtensionKit.dylib` was loaded.
//
// Isolated host compilation has Foundation only. Assertions that need UIKit
// or Foundation XPC are compiled only when those modules exist.

private func assertNotExtensionKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ExtensionKit."))
}

private func assertFoundationIdentity() {
    let identifier = UUID()
    let bundle = "com.example.identity"
    assertNotExtensionKitType(identifier)
    assertNotExtensionKitType(bundle)

    let identity = AppExtensionIdentity(bundleIdentifier: bundle)
    let configuration = EXHostViewController.Configuration(
        appExtension: identity,
        sceneID: identifier.uuidString
    )
    precondition(configuration.sceneID == identifier.uuidString)
    precondition(configuration.appExtension.bundleIdentifier == bundle)
    precondition(type(of: identifier) == UUID.self)
    precondition(type(of: bundle) == String.self)
}

func extensionKitDependencyIdentityMain() {
    assertFoundationIdentity()
    print("EXTENSIONKIT_DEPENDENCY_IDENTITY_OK")
}
