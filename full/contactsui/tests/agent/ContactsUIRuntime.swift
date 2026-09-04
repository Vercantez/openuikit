@_spi(OpenUIKitHost) import ContactsUI
import Foundation

private final class CancelDelegate: NSObject, CNContactPickerDelegate {
    var cancelled = false

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        _ = picker
        cancelled = true
    }
}

private final class DefaultPickerDelegate: NSObject, CNContactPickerDelegate {}

private final class EditorDelegate: NSObject, CNContactViewControllerDelegate {}

@MainActor
private func assertCaption() {
    let cases: [ContactAccessButton.Caption] = [.defaultText, .email, .phone]
    precondition(Set(cases).count == 3)
    precondition(ContactAccessButton.Caption.defaultText != .email)
    precondition(ContactAccessButton.Caption.email != .phone)
    precondition(ContactAccessButton.Caption.phone != .defaultText)
    precondition(ContactAccessButton.Caption.defaultText.rawValue == "defaultText")
    precondition(ContactAccessButton.Caption.email.rawValue == "email")
    precondition(ContactAccessButton.Caption.phone.rawValue == "phone")
    precondition(ContactAccessButton.Caption(rawValue: "defaultText") == .defaultText)
    precondition(ContactAccessButton.Caption(rawValue: "not-a-caption") == nil)

    var hasher = Hasher()
    ContactAccessButton.Caption.email.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ContactAccessButton.Caption.phone.hashValue
}

@MainActor
private func assertStyle() {
    let automatic = ContactAccessButton.Style.automatic
    precondition(automatic.imageTrailingEdgePadding == nil)
    precondition(automatic.imageWidth == nil)
    let custom = ContactAccessButton.Style(
        imageTrailingEdgePadding: 8,
        imageWidth: 30
    )
    precondition(custom.imageTrailingEdgePadding == 8)
    precondition(custom.imageWidth == 30)
    precondition(custom != automatic)
}

@MainActor
private func assertAccessButton() {
    var received: [String]?
    let button = ContactAccessButton(
        queryString: "Anne",
        ignoredEmails: ["skip@example.com"],
        ignoredPhoneNumbers: ["+15555550100"]
    ) { identifiers in
        received = identifiers
    }
    precondition(button.queryString == "Anne")
    precondition(button.ignoredEmails == ["skip@example.com"])
    precondition(button.ignoredPhoneNumbers == ["+15555550100"])
    precondition(received == nil)

    let captioned = button.contactAccessButtonCaption(.email)
    precondition(captioned.linuxCaption == .email)
    let styled = captioned.contactAccessButtonStyle(
        ContactAccessButton.Style(imageWidth: 30)
    )
    precondition(styled.linuxStyle.imageWidth == 30)

    let chained = styled.hidden().padding(4).disabled(true).opacity(0.5)
    let tags = ContactsUIHostControl.linuxModifierTags(chained)
    precondition(tags.contains("hidden()"))
    precondition(tags.contains("padding(_:)"))
    precondition(tags.contains("disabled(_:)"))
    precondition(tags.contains("opacity(_:)"))
    precondition(tags.contains("contactAccessButtonCaption(_:)"))
    precondition(tags.contains("contactAccessButtonStyle(_:)"))

    let granted = ContactsUIHostControl.invokeAccessApproval(chained)
    precondition(granted.isEmpty)
    precondition(received == [])
}

@MainActor
private func assertPicker() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = ["givenName", "familyName"]
    precondition(picker.displayedPropertyKeys == ["givenName", "familyName"])
    let enabled = NSPredicate(value: true)
    picker.predicateForEnablingContact = enabled
    picker.predicateForSelectionOfContact = NSPredicate(value: false)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    precondition(picker.predicateForEnablingContact == enabled)

    let cancel = CancelDelegate()
    picker.delegate = cancel
    let existential: any CNContactPickerDelegate = cancel
    precondition(!cancel.cancelled)
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(cancel.cancelled)
    _ = existential

    let unused = DefaultPickerDelegate()
    picker.delegate = unused
    ContactsUIHostControl.reportPickerCancel(picker)
}

@MainActor
private func assertEditor() {
    let editor = CNContactViewController()
    editor.allowsActions = false
    editor.allowsEditing = false
    editor.shouldShowLinkedContacts = true
    editor.alternateName = "Alt"
    editor.message = "Msg"
    editor.displayedPropertyKeys = ["phoneNumbers"]
    precondition(editor.allowsActions == false)
    precondition(editor.allowsEditing == false)
    precondition(editor.shouldShowLinkedContacts == true)
    precondition(editor.alternateName == "Alt")
    precondition(editor.message == "Msg")

    editor.highlightProperty(withKey: "emailAddresses", identifier: "work")
    precondition(
        ContactsUIHostControl.highlightedPropertyKey(editor) == "emailAddresses"
    )
    precondition(
        ContactsUIHostControl.highlightedPropertyIdentifier(editor) == "work"
    )

    let delegate = EditorDelegate()
    editor.delegate = delegate
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    _ = delegate
}

@MainActor
func contactsUIRuntimeMain() {
    assertCaption()
    assertStyle()
    assertAccessButton()
    assertPicker()
    assertEditor()
    print("CONTACTSUI_AGENT_RUNTIME_OK")
}

Task { @MainActor in
    contactsUIRuntimeMain()
    exit(0)
}
dispatchMain()
