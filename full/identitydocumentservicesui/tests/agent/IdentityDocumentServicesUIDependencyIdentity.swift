import IdentityDocumentServicesUI
import Foundation
import IdentityDocumentServices
import UIKit
@_spi(OpenUIKitHost) import IdentityDocumentServicesUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest IdentityDocumentServices
// / UIKit success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest IdentityDocumentServices, Foundation, UIKit (and their dylibs).
// 2. Build IdentityDocumentServicesUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports IdentityDocumentServicesUI and every
//    dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `IDENTITYDOCUMENTSERVICESUI_DEPENDENCY_IDENTITY_OK` and that
//    `libIdentityDocumentServicesUI.dylib` was loaded.

private func assertNotIdentityDocumentServicesUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("IdentityDocumentServicesUI."))
}

func assertFoundationIdentity() {
    _ = Foundation.Date.self
    _ = Foundation.Data.self
    let origin = URL(string: "https://rp.example")!
    assertNotIdentityDocumentServicesUIType(origin)
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext(
        requestingWebsiteOrigin: origin
    )
    precondition(context.requestingWebsiteOrigin == origin)
}

#if canImport(IdentityDocumentServices)
func assertIdentityDocumentServicesIdentity() {
    let request = IdentityDocumentServices.ISO18013MobileDocumentRequest(
        presentmentRequests: [],
        requestAuthentications: []
    )
    assertNotIdentityDocumentServicesUIType(request)
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext(request: request)
    precondition(context.request.presentmentRequests.isEmpty)
    let raw = IdentityDocumentServices.IdentityDocumentWebPresentmentRawRequest(
        requestType: .iso18013MobileDocument,
        requestData: Data()
    )
    assertNotIdentityDocumentServicesUIType(raw)
}
#endif

#if canImport(UIKit)
func assertUIKitIdentity() {
    let window = IdentityDocumentPresentationAnchor()
    precondition(window is UIKit.UIWindow)
    precondition(IdentityDocumentPresentationAnchor.self == UIKit.UIWindow.self)
    assertNotIdentityDocumentServicesUIType(window)
}
#endif

func identityDocumentServicesUIDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(IdentityDocumentServices)
    assertIdentityDocumentServicesIdentity()
    #endif
    #if canImport(UIKit)
    assertUIKitIdentity()
    #endif
    print("IDENTITYDOCUMENTSERVICESUI_DEPENDENCY_IDENTITY_OK")
}
