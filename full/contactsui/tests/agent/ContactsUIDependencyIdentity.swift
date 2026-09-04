@_spi(OpenUIKitHost) import ContactsUI
import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Contacts/UIKit/SwiftUI
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Contacts, Foundation, UIKit, SwiftUI (and their dylibs).
// 2. Build ContactsUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports ContactsUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `CONTACTSUI_DEPENDENCY_IDENTITY_OK` and that `libContactsUI.dylib`
//    was loaded.
//
// Assertions below that need Contacts/UIKit/SwiftUI are compiled only when
// those modules exist. This file must still type-check on the isolated host.

private func assertNotContactsUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ContactsUI."))
}

@MainActor
private func assertFoundationIdentity() {
    let predicate = NSPredicate(value: true)
    assertNotContactsUIType(predicate)
    let picker = CNContactPickerViewController()
    picker.predicateForEnablingContact = predicate
    precondition(picker.predicateForEnablingContact != nil)

    let button = ContactAccessButton(queryString: "Ada")
    let granted = ContactsUIHostControl.invokeAccessApproval(button)
    precondition(granted.isEmpty)
}

#if canImport(Contacts) && canImport(UIKit)
@MainActor
private func assertContactsUIKitIdentity() {
    let contact = CNMutableContact()
    assertNotContactsUIType(contact)
    let editor = CNContactViewController(for: contact)
    precondition(type(of: editor).superclass() == UIViewController.self || editor is UIViewController)
    let picker = CNContactPickerViewController()
    precondition(picker is UIViewController)
    _ = CNContactViewController.descriptorForRequiredKeys()
}
#endif

#if canImport(SwiftUI)
@MainActor
private func assertSwiftUIIdentity() {
    let button = ContactAccessButton(queryString: "Ada")
    let _: any View = button
}
#endif

@MainActor
func contactsUIDependencyIdentityMain() {
    assertFoundationIdentity()
    #if canImport(Contacts) && canImport(UIKit)
    assertContactsUIKitIdentity()
    #endif
    #if canImport(SwiftUI)
    assertSwiftUIIdentity()
    #endif
    print("CONTACTSUI_DEPENDENCY_IDENTITY_OK")
}

Task { @MainActor in
    contactsUIDependencyIdentityMain()
    exit(0)
}
dispatchMain()
