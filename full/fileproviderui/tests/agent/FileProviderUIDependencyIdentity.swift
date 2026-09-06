import FileProviderUI
import FileProvider
import Foundation
import UIKit
@_spi(OpenUIKitHost) import FileProviderUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest FileProvider/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest FileProvider, Foundation, UIKit (and their dylibs).
// 2. Build FileProviderUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports FileProviderUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `FILEPROVIDERUI_DEPENDENCY_IDENTITY_OK` and that
//    `libFileProviderUI.dylib` was loaded.

private func assertNotFileProviderUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("FileProviderUI."))
}

func assertFoundationIdentity() {
    let error = FPUIExtensionErrorCode.userCancelled as NSError
    assertNotFileProviderUIType(error.domain)
    precondition(error.domain == FPUIErrorDomain)
    precondition(error.code == 0)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

#if canImport(FileProvider)
func assertFileProviderIdentity() {
    let domain = FileProvider.NSFileProviderDomainIdentifier("identity-domain")
    assertNotFileProviderUIType(domain)
    let context = FPUIActionExtensionContext()
    context.hostSetDomainIdentifier(domain)
    precondition(context.domainIdentifier == domain)

    let item = FileProvider.NSFileProviderItemIdentifier("identity-item")
    assertNotFileProviderUIType(item)
    let controller = FPUIActionExtensionViewController()
    controller.prepare(forAction: "identity-action", itemIdentifiers: [item])
    precondition(controller.hostPreparedItemIdentifiers == [item])
}
#endif

#if canImport(UIKit)
func assertUIKitIdentity() {
    let controller = FPUIActionExtensionViewController()
    precondition(controller is UIViewController)
    precondition(
        type(of: controller).superclass() == UIViewController.self
            || controller is UIViewController
    )
}
#endif

func fileProviderUIDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(FileProvider)
    assertFileProviderIdentity()
    #endif
    #if canImport(UIKit)
    assertUIKitIdentity()
    #endif
    print("FILEPROVIDERUI_DEPENDENCY_IDENTITY_OK")
}
