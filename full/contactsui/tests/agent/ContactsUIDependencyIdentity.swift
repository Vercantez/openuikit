import Contacts
@_spi(OpenUIKitHost) import ContactsUI
import Foundation
import SwiftUI
import UIKit

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

@MainActor
private final class PickerIdentityProbe: CNContactPickerDelegate {
    var selected: [CNContact] = []
    var cancelled = false

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contact: CNContact
    ) {
        selected.append(contact)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        cancelled = true
    }
}

@MainActor
private final class EditorIdentityProbe: CNContactViewControllerDelegate {
    var completed: CNContact?
    var allowDefaultAction = true

    func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    ) {
        completed = contact
    }

    func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool {
        _ = property.key
        return allowDefaultAction
    }
}

@MainActor
private func runContactsUIDependencyIdentity() {
    let contact = CNMutableContact()
    contact.givenName = "Ada"
    contact.familyName = "Lovelace"
    _ = contact.id

    let picker = CNContactPickerViewController()
    precondition(picker is UIViewController)
    precondition(CNContactPickerViewController.self is UIViewController.Type)

    let pickerDelegate: any CNContactPickerDelegate = PickerIdentityProbe()
    picker.delegate = pickerDelegate
    picker.displayedPropertyKeys = ["givenName", "familyName"]
    picker.presentPicker()
    precondition(picker.reportSelection(contact: contact) == nil)
    let pickerProbe = pickerDelegate as! PickerIdentityProbe
    precondition(pickerProbe.selected.count == 1)
    precondition(pickerProbe.selected[0].givenName == "Ada")

    picker.presentPicker()
    precondition(picker.reportCancel())
    precondition(pickerProbe.cancelled)

    let editor = CNContactViewController(for: contact)
    precondition(editor is UIViewController)
    precondition(CNContactViewController.self is UIViewController.Type)
    let unknown = CNContactViewController(forUnknownContact: contact)
    let created = CNContactViewController(forNewContact: nil)
    precondition(!unknown.allowsEditing)
    precondition(created.allowsEditing)
    editor.highlightProperty(withKey: "givenName", identifier: nil)
    precondition(editor.highlightedPropertyKey == "givenName")

    let editorDelegate: any CNContactViewControllerDelegate = EditorIdentityProbe()
    editor.delegate = editorDelegate
    editor.reportCompletion(contact: contact)
    let editorProbe = editorDelegate as! EditorIdentityProbe
    precondition(editorProbe.completed?.givenName == "Ada")

    let keys = CNContactViewController.descriptorForRequiredKeys()
    _ = keys

    let icon = UIApplicationShortcutIcon(contact: contact)
    precondition(icon is UIApplicationShortcutIcon)
    let iconName = String(reflecting: type(of: icon))
    precondition(!iconName.hasPrefix("ContactsUI."))
    precondition(iconName.contains("UIApplicationShortcutIcon"))

    var granted: [String] = ["sentinel"]
    let button = ContactAccessButton(
        queryString: "Ada",
        ignoredEmails: ["skip@example.com"],
        ignoredPhoneNumbers: ["555"],
        approvalCallback: { granted = $0 }
    )
    let buttonView: any View = button
    _ = buttonView
    let styled: any View = button.contactAccessButtonStyle(.automatic)
    _ = styled
    let captioned: any View = button.contactAccessButtonCaption(.email)
    _ = captioned
    button.reportApproval()
    precondition(granted.isEmpty)

    #if os(Linux)
    let loaded = dlopen("libContactsUI.dylib", RTLD_NOW)
    precondition(loaded != nil, "libContactsUI.dylib must be loadable")
    #endif
}

MainActor.assumeIsolated {
    runContactsUIDependencyIdentity()
}
print("CONTACTSUI_DEPENDENCY_IDENTITY_OK")
