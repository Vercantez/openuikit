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
    return contact
}

@MainActor
func testPickerConstruction() {
    let picker = CNContactPickerViewController()
    precondition(type(of: picker) === CNContactPickerViewController.self)
    precondition(picker.delegate == nil)
}

@MainActor
func testPickerDelegateProperty() {
    let picker = CNContactPickerViewController()
    let probe = PickerProbe()
    picker.delegate = probe
    let existential: any CNContactPickerDelegate = probe
    precondition(picker.delegate === probe)
    _ = existential
}

@MainActor
func testPickerDisplayedPropertyKeys() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]
    precondition(picker.displayedPropertyKeys == [CNContactGivenNameKey, CNContactPhoneNumbersKey])
    picker.displayedPropertyKeys = nil
    precondition(picker.displayedPropertyKeys == nil)
}

@MainActor
func testPickerPredicateForEnablingContact() {
    let picker = CNContactPickerViewController()
    let enabled = NSPredicate(value: true)
    picker.predicateForEnablingContact = enabled
    precondition(picker.predicateForEnablingContact == enabled)
    let ada = makeAda()
    let named = ContactsUIHostControl.predicate(format: "givenName == %@", argument: "Ada")
    picker.predicateForEnablingContact = named
    precondition(ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: ada))
    let bob = CNMutableContact()
    bob.givenName = "Bob"
    precondition(!ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: bob))
}

@MainActor
func testPickerPredicateForSelectionOfContact() {
    let picker = CNContactPickerViewController()
    picker.predicateForSelectionOfContact = NSPredicate(value: false)
    precondition(picker.predicateForSelectionOfContact == NSPredicate(value: false))
    let ada = makeAda()
    picker.predicateForEnablingContact = NSPredicate(value: true)
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
}

@MainActor
func testPickerPredicateForSelectionOfProperty() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfProperty = ContactsUIHostControl.predicate(
        format: "key == %@",
        argument: CNContactPhoneNumbersKey
    )
    let ada = makeAda()
    let property = CNContactProperty(
        contact: ada,
        key: CNContactPhoneNumbersKey,
        value: ada.phoneNumbers[0].value.stringValue as NSString,
        identifier: ada.phoneNumbers[0].identifier,
        label: ada.phoneNumbers[0].label
    )
    precondition(ContactsUIHostControl.evaluate(picker.predicateForSelectionOfProperty, property: property))
}

@MainActor
func testPickerDelegateProtocol() {
    let unused = DefaultPickerDelegate()
    let picker = CNContactPickerViewController()
    picker.delegate = unused
    ContactsUIHostControl.reportPickerCancel(picker)
    let existential: any CNContactPickerDelegate = unused
    _ = existential
}

@MainActor
func testPickerDidSelectContact() {
    let picker = CNContactPickerViewController()
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
}

@MainActor
func testPickerDidSelectContacts() {
    let picker = CNContactPickerViewController()
    picker.predicateForEnablingContact = ContactsUIHostControl.predicate(
        format: "emailAddresses.@count > 0"
    )
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    let bob = CNMutableContact()
    bob.givenName = "Bob"
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contacts: [ada, bob]))
    precondition(probe.selectedContacts.count == 1)
    precondition(probe.selectedContacts[0].givenName == "Ada")
}

@MainActor
func testPickerDidSelectContactProperty() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    let property = CNContactProperty(
        contact: ada,
        key: CNContactPhoneNumbersKey,
        value: ada.phoneNumbers[0].value.stringValue as NSString,
        identifier: ada.phoneNumbers[0].identifier,
        label: ada.phoneNumbers[0].label
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, property: property))
    precondition(probe.selectedProperty?.key == CNContactPhoneNumbersKey)
}

@MainActor
func testPickerDidSelectContactProperties() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    let property = CNContactProperty(
        contact: ada,
        key: CNContactPhoneNumbersKey,
        value: ada.phoneNumbers[0].value.stringValue as NSString,
        identifier: ada.phoneNumbers[0].identifier,
        label: ada.phoneNumbers[0].label
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, properties: [property]))
    precondition(probe.selectedProperties.count == 1)
}

@MainActor
func testPickerDidCancel() {
    let picker = CNContactPickerViewController()
    let probe = PickerProbe()
    picker.delegate = probe
    precondition(!probe.cancelled)
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(probe.cancelled)
}
