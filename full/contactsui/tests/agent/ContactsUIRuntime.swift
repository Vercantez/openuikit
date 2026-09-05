@_spi(OpenUIKitHost) import ContactsUI
import Foundation

private final class PickerProbe: NSObject, CNContactPickerDelegate {
    var cancelled = false
    var selectedContact: CNContact?
    var selectedContacts: [CNContact] = []
    var selectedProperty: CNContactProperty?
    var selectedProperties: [CNContactProperty] = []

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        _ = picker
        cancelled = true
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        _ = picker
        selectedContact = contact
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        _ = picker
        selectedContacts = contacts
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contactProperty: CNContactProperty
    ) {
        _ = picker
        selectedProperty = contactProperty
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelectContactProperties contactProperties: [CNContactProperty]
    ) {
        _ = picker
        selectedProperties = contactProperties
    }
}

private final class DefaultPickerDelegate: NSObject, CNContactPickerDelegate {}

private final class EditorProbe: NSObject, CNContactViewControllerDelegate {
    var completed: CNContact??
    var defaultActionProperty: CNContactProperty?
    var allowDefault = false

    func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    ) {
        _ = viewController
        completed = contact
    }

    func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool {
        defaultActionProperty = property
        return allowDefault
    }
}

private func makeAda() -> CNMutableContact {
    let contact = CNMutableContact()
    contact.givenName = "Ada"
    contact.familyName = "Lovelace"
    contact.phoneNumbers = [
        CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+15555550100"))
    ]
    contact.emailAddresses = [
        CNLabeledValue(label: CNLabelWork, value: "ada@example.com" as NSString)
    ]
    let postal = CNPostalAddress()
    postal.street = "1 Analytical Engine"
    postal.city = "London"
    postal.country = "UK"
    contact.postalAddresses = [
        CNLabeledValue(label: CNLabelHome, value: postal)
    ]
    return contact
}

@MainActor
private func assertCaption() {
    let cases: [ContactAccessButton.Caption] = [.defaultText, .email, .phone]
    precondition(Set(cases).count == 3)
    precondition(ContactAccessButton.Caption.defaultText.rawValue == "defaultText")
    precondition(ContactAccessButton.Caption(rawValue: "email") == .email)
    precondition(ContactAccessButton.Caption(rawValue: "not-a-caption") == nil)
    var hasher = Hasher()
    ContactAccessButton.Caption.phone.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ContactAccessButton.Caption.email.hashValue
    precondition(ContactAccessButton.Caption.email != .phone)
}

@MainActor
private func assertStyle() {
    let automatic = ContactAccessButton.Style.automatic
    precondition(automatic.imageTrailingEdgePadding == nil)
    precondition(automatic.imageWidth == nil)
    precondition(automatic.imageColor == nil)
    let custom = ContactAccessButton.Style(
        imageTrailingEdgePadding: 8,
        imageWidth: 30,
        imageColor: .accentColor
    )
    precondition(custom.imageTrailingEdgePadding == 8)
    precondition(custom.imageWidth == 30)
    precondition(custom.imageColor == .accentColor)
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
    precondition(received == nil)

    let captioned = button.contactAccessButtonCaption(.email)
    precondition(captioned.linuxCaption == .email)
    let styled = captioned.contactAccessButtonStyle(ContactAccessButton.Style(imageWidth: 30))
    precondition(styled.linuxStyle.imageWidth == 30)

    var presented = true
    var pickerGranted: [String]?
    let presentedBinding = Binding(
        get: { presented },
        set: { presented = $0 }
    )
    let gated = styled.contactAccessPicker(isPresented: presentedBinding) { ids in
        pickerGranted = ids
    }
    precondition(presented == false)
    precondition(pickerGranted == [])

    let exercised = gated.linuxExerciseIdentityModifiers()
    let tags = ContactsUIHostControl.linuxModifierTags(exercised)
    precondition(tags.contains("contactAccessButtonCaption(_:)"))
    precondition(tags.contains("contactAccessButtonStyle(_:)"))
    precondition(tags.contains("contactAccessPicker(isPresented:completionHandler:)"))
    precondition(tags.contains("linuxExerciseIdentityModifiers()"))

    let granted = ContactsUIHostControl.invokeAccessApproval(exercised)
    precondition(granted.isEmpty)
    precondition(received == [])

    _ = exercised.body
}

@MainActor
private func assertPicker() {
    let ada = makeAda()
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]
    precondition(picker.displayedPropertyKeys == [CNContactGivenNameKey, CNContactPhoneNumbersKey])

    let enabled = NSPredicate(value: true)
    picker.predicateForEnablingContact = enabled
    picker.predicateForSelectionOfContact = NSPredicate(value: false)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    precondition(picker.predicateForEnablingContact == enabled)

    let probe = PickerProbe()
    picker.delegate = probe
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(probe.cancelled)

    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")

    picker.predicateForEnablingContact = ContactsUIHostControl.predicate(
        format: "givenName == %@",
        argument: "Ada"
    )
    precondition(ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: ada))
    let bob = CNMutableContact()
    bob.givenName = "Bob"
    precondition(!ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: bob))
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: bob))

    picker.predicateForEnablingContact = ContactsUIHostControl.predicate(
        format: "emailAddresses.@count > 0"
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contacts: [ada, bob]))
    precondition(probe.selectedContacts.count == 1)
    precondition(probe.selectedContacts[0].givenName == "Ada")

    let property = CNContactProperty(
        contact: ada,
        key: CNContactPhoneNumbersKey,
        value: ada.phoneNumbers[0].value.stringValue as NSString,
        identifier: ada.phoneNumbers[0].identifier,
        label: ada.phoneNumbers[0].label
    )
    picker.predicateForSelectionOfProperty = ContactsUIHostControl.predicate(
        format: "key == %@",
        argument: CNContactPhoneNumbersKey
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, property: property))
    precondition(probe.selectedProperty?.key == CNContactPhoneNumbersKey)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, properties: [property]))
    precondition(probe.selectedProperties.count == 1)

    let unused = DefaultPickerDelegate()
    picker.delegate = unused
    ContactsUIHostControl.reportPickerCancel(picker)
}

@MainActor
private func assertEditor() {
    let ada = makeAda()
    let editor = CNContactViewController(for: ada)
    editor.allowsActions = false
    editor.allowsEditing = true
    editor.shouldShowLinkedContacts = true
    editor.alternateName = "Ada L."
    editor.message = "Mathematician"
    editor.displayedPropertyKeys = [
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey,
        CNContactPostalAddressesKey,
    ]
    editor.contactStore = CNContactStore()
    editor.parentGroup = CNGroup()
    editor.parentContainer = CNContainer()
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.allowsActions == false)
    precondition(editor.shouldShowLinkedContacts == true)
    _ = CNContactViewController.descriptorForRequiredKeys()

    editor.highlightProperty(withKey: CNContactEmailAddressesKey, identifier: ada.emailAddresses[0].identifier)
    precondition(
        ContactsUIHostControl.highlightedPropertyKey(editor) == CNContactEmailAddressesKey
    )

    let sections = ContactsUIHostControl.linuxContactSections(editor)
    let kinds = sections.map(\.kind)
    precondition(kinds.contains(.message))
    precondition(kinds.contains(.name))
    precondition(kinds.contains(.phone))
    precondition(kinds.contains(.email))
    precondition(kinds.contains(.address))
    let nameRow = sections.first { $0.kind == .name }?.rows.first
    precondition(nameRow?.value == "Ada L.")
    let phoneRow = sections.first { $0.kind == .phone }?.rows.first
    precondition(phoneRow?.value == "+15555550100")
    let emailRow = sections.first { $0.kind == .email }?.rows.first
    precondition(emailRow?.highlighted == true)
    let addressRow = sections.first { $0.kind == .address }?.rows.first
    precondition(addressRow?.value.contains("London") == true)

    let unknown = CNContactViewController(forUnknownContact: ada)
    precondition(unknown.allowsEditing == false)
    let fresh = CNContactViewController(forNewContact: nil)
    precondition(fresh.allowsEditing == true)
    _ = CNContactViewController(forContact: ada)

    let probe = EditorProbe()
    probe.allowDefault = true
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))

    let property = CNContactProperty(
        contact: ada,
        key: CNContactEmailAddressesKey,
        value: "ada@example.com" as NSString,
        identifier: ada.emailAddresses[0].identifier,
        label: CNLabelWork
    )
    precondition(ContactsUIHostControl.shouldPerformDefaultAction(editor, for: property))
    precondition(probe.defaultActionProperty?.key == CNContactEmailAddressesKey)

    let icon = UIApplicationShortcutIcon(contact: ada)
    precondition(ContactsUIHostControl.shortcutContactIdentifier(icon) == ada.identifier)
    _ = ada.id
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
