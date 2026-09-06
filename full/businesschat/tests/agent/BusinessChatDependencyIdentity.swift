import BusinessChat
import Foundation
import UIKit
@_spi(OpenUIKitHost) import BusinessChat

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Foundation/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation and UIKit (and their dylibs).
// 2. Build BusinessChat with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports BusinessChat and every
//    declared dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `BUSINESSCHAT_DEPENDENCY_IDENTITY_OK` and that
//    `libBusinessChat.dylib` was loaded.

private func assertNotBusinessChatType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("BusinessChat."))
}

func assertFoundationIdentity() {
    let identifier = "urn:biz:identity-probe"
    let body = "identity-body"
    let data = Data(body.utf8)
    precondition(type(of: data) == Data.self)
    assertNotBusinessChatType(data)
    precondition(!String(reflecting: type(of: identifier)).hasPrefix("BusinessChat."))

    BusinessChatHostControl.reset()
    BCChatAction.openTranscript(
        businessIdentifier: identifier,
        intentParameters: [.body: body, .intent: "identity-intent"]
    )
    let recorded = BusinessChatHostControl.lastOpenTranscript()
    precondition(recorded?.businessIdentifier == identifier)
    precondition(recorded?.intentParameters[.body] == body)
    precondition(BusinessChatHostControl.didOpenTranscript() == false)

    let coder: NSCoder = NSKeyedArchiver(requiringSecureCoding: false)
    assertNotBusinessChatType(coder)
    let decoded = BCChatButton(coder: coder)
    precondition(decoded == nil)
}

#if canImport(UIKit)
func assertUIKitIdentity() {
    // The public census has no UIKit-owned parameter types. UIControl is
    // the Darwin superclass of BCChatButton; this isolated module does not
    // publish a UIControl lookalike. Importing UIKit here proves the
    // dependency is named for the EC2 client.
    let button = BCChatButton(style: .dark)
    let asObject: NSObject = button
    precondition(asObject === button)
    precondition(BusinessChatHostControl.style(of: button) == .dark)
    _ = UIControl.self
}
#endif

func businessChatDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(UIKit)
    assertUIKitIdentity()
    #endif
    print("BUSINESSCHAT_DEPENDENCY_IDENTITY_OK")
}
