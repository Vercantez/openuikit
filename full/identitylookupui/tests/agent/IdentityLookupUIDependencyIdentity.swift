import IdentityLookupUI
import Foundation
import IdentityLookup
import UIKit
@_spi(OpenUIKitHost) import IdentityLookupUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest IdentityLookup/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest IdentityLookup, Foundation, UIKit (and their dylibs).
// 2. Build IdentityLookupUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports IdentityLookupUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `IDENTITYLOOKUPUI_DEPENDENCY_IDENTITY_OK` and that
//    `libIdentityLookupUI.dylib` was loaded.

private func assertNotIdentityLookupUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("IdentityLookupUI."))
}

func assertFoundationIdentity() {
    _ = Foundation.Date.self
    _ = Foundation.Data.self
    let context = ILClassificationUIExtensionContext()
    precondition(context is NSObject)
    assertNotIdentityLookupUIType(context.isReadyForClassificationResponse)
}

#if canImport(IdentityLookup)
func assertIdentityLookupIdentity() {
    let request = IdentityLookup.ILClassificationRequest()
    assertNotIdentityLookupUIType(request)
    let controller = ILClassificationUIExtensionViewController()
    controller.prepare(for: request)
    precondition(controller.hostPreparedRequest === request)
    let response = controller.classificationResponse(for: request)
    assertNotIdentityLookupUIType(response)
    precondition(response.action == IdentityLookup.ILClassificationAction.none)
}
#endif

#if canImport(UIKit)
func assertUIKitIdentity() {
    let controller = ILClassificationUIExtensionViewController()
    precondition(controller is UIViewController)
    precondition(
        type(of: controller).superclass() == UIViewController.self
            || controller is UIViewController
    )
}
#endif

func identityLookupUIDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(IdentityLookup)
    assertIdentityLookupIdentity()
    #endif
    #if canImport(UIKit)
    assertUIKitIdentity()
    #endif
    print("IDENTITYLOOKUPUI_DEPENDENCY_IDENTITY_OK")
}
