import MediaSetup
import Foundation
import UIKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Foundation/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation and UIKit modules and dylibs.
// 2. Build MediaSetup with those modules on `-I` / `-L` (so `canImport(UIKit)`
//    is true and `MSPresentationAnchor` is `UIWindow`).
// 3. Link this file as a client that imports MediaSetup, Foundation, and UIKit.
// 4. Pass genuine Foundation.URL and UIKit.UIWindow values through public
//    MediaSetup APIs.
// 5. Confirm `start()` still fails closed.
// 6. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 7. Confirm `MEDIASETUP_DEPENDENCY_IDENTITY_OK` and that
//    `libMediaSetup.dylib` was loaded.

private func assertNotMediaSetupType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("MediaSetup."))
}

private final class IdentityPresentationContext: NSObject, MSAuthenticationPresentationContext {
    let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    func presentationAnchor() -> MSPresentationAnchor? {
        window
    }
}

func assertFoundationIdentity() {
    let url = URL(string: "https://identity.example/token")!
    assertNotMediaSetupType(url)
    precondition(type(of: url) == URL.self)

    let account = MSServiceAccount(serviceName: "IdentityService", accountName: "identity-user")
    account.authorizationTokenURL = url
    account.configurationURL = URL(string: "https://identity.example/config")!
    account.clientID = "identity-client"
    account.clientSecret = "identity-secret"
    account.authorizationScope = "identity-scope"
    precondition(account.authorizationTokenURL == url)
    precondition(account.configurationURL?.host == "identity.example")
    _ = Foundation.Data.self
    _ = Foundation.Date.self
}

func assertUIKitIdentity() {
    let window = UIWindow(frame: .zero)
    assertNotMediaSetupType(window)
    precondition(window is UIWindow)

    let account = MSServiceAccount(serviceName: "IdentityService", accountName: "identity-user")
    let session = MSSetupSession(serviceAccount: account)
    let context = IdentityPresentationContext(window: window)
    session.presentationContext = context
    precondition(session.presentationContext === context)
    let anchor = context.presentationAnchor()
    precondition(anchor === window)
}

func mediaSetupDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()

    let account = MSServiceAccount(serviceName: "IdentityService", accountName: "identity-user")
    let session = MSSetupSession(serviceAccount: account)
    do {
        try session.start()
        preconditionFailure("Linux must not invent a Media Setup success")
    } catch let error as NSError {
        assertNotMediaSetupType(error)
        precondition(error.domain == "MediaSetup.linux.unavailable")
        precondition(error.code == 1)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }

    print("MEDIASETUP_DEPENDENCY_IDENTITY_OK")
}
