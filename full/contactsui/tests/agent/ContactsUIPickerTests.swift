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

private func makePhoneProperty(for contact: CNContact) -> CNContactProperty {
    CNContactProperty(
        contact: contact,
        key: CNContactPhoneNumbersKey,
        value: contact.phoneNumbers[0].value.stringValue as NSString,
        identifier: contact.phoneNumbers[0].identifier,
        label: contact.phoneNumbers[0].label
    )
}

@MainActor
func testPickerConstruction() {
    let picker = CNContactPickerViewController()
    precondition(type(of: picker) === CNContactPickerViewController.self)
    precondition(picker.delegate == nil)
    let probe = PickerProbe()
    picker.delegate = probe
    ContactsUIHostControl.reportPickerDidShow(picker)
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(probe.cancelled)
    precondition(probe.selectedContact == nil)
}

@MainActor
func testPickerDelegateProperty() {
    let picker = CNContactPickerViewController()
    let probe = PickerProbe()
    picker.delegate = probe
    let existential: any CNContactPickerDelegate = probe
    precondition(picker.delegate === probe)
    _ = existential
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    let ada = makeAda()
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    precondition(!probe.cancelled)
}

@MainActor
func testPickerDisplayedPropertyKeys() {
    let picker = CNContactPickerViewController()
    picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]
    precondition(picker.displayedPropertyKeys == [CNContactGivenNameKey, CNContactPhoneNumbersKey])
    picker.displayedPropertyKeys = [CNContactEmailAddressesKey]
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfProperty = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    let phone = makePhoneProperty(for: ada)
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, property: phone))
    precondition(probe.selectedProperty == nil)
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    precondition(ContactsUIHostControl.reportPickerSelection(picker, property: phone))
    precondition(probe.selectedProperty?.key == CNContactPhoneNumbersKey)
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
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    precondition(ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: ada))
    let bob = CNMutableContact()
    bob.givenName = "Bob"
    precondition(!ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: bob))
    let probe = PickerProbe()
    picker.delegate = probe
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: bob))
    precondition(probe.selectedContact == nil)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    let begins = ContactsUIHostControl.predicate(format: "familyName BEGINSWITH[cd] %@", argument: "love")
    picker.predicateForEnablingContact = begins
    precondition(ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: ada))
}

@MainActor
func testPickerPredicateForSelectionOfContact() {
    let picker = CNContactPickerViewController()
    picker.predicateForSelectionOfContact = NSPredicate(value: false)
    precondition(picker.predicateForSelectionOfContact == NSPredicate(value: false))
    let ada = makeAda()
    picker.predicateForEnablingContact = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact == nil)
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
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
    let property = makePhoneProperty(for: ada)
    precondition(ContactsUIHostControl.evaluate(picker.predicateForSelectionOfProperty, property: property))
    let probe = PickerProbe()
    picker.delegate = probe
    let email = CNContactProperty(
        contact: ada,
        key: CNContactEmailAddressesKey,
        value: "ada@example.com" as NSString,
        identifier: ada.emailAddresses[0].identifier,
        label: CNLabelWork
    )
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, property: email))
    precondition(probe.selectedProperty == nil)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, property: property))
    precondition(probe.selectedProperty?.key == CNContactPhoneNumbersKey)
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
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.pickerIsVisible(picker))
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    precondition(probe.selectedContact?.familyName == "Lovelace")
    precondition(!probe.cancelled)
    precondition(probe.selectedContacts.isEmpty)
    precondition(!ContactsUIHostControl.pickerIsVisible(picker))
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
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contacts: [ada, bob]))
    precondition(probe.selectedContacts.count == 1)
    precondition(probe.selectedContacts[0].givenName == "Ada")
    precondition(probe.selectedContact == nil)
    precondition(!probe.cancelled)
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
    let property = makePhoneProperty(for: ada)
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, property: property))
    precondition(probe.selectedProperty?.key == CNContactPhoneNumbersKey)
    precondition(probe.selectedProperty?.identifier == ada.phoneNumbers[0].identifier)
    precondition(probe.selectedContact == nil)
    precondition(!probe.cancelled)
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
    let property = makePhoneProperty(for: ada)
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.reportPickerSelection(picker, properties: [property]))
    precondition(probe.selectedProperties.count == 1)
    precondition(probe.selectedProperties[0].key == CNContactPhoneNumbersKey)
    precondition(probe.selectedContact == nil)
    precondition(!probe.cancelled)
}

@MainActor
func testPickerDidCancel() {
    let picker = CNContactPickerViewController()
    let probe = PickerProbe()
    picker.delegate = probe
    precondition(!probe.cancelled)
    ContactsUIHostControl.reportPickerDidShow(picker)
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(probe.cancelled)
    precondition(probe.selectedContact == nil)
    precondition(probe.selectedContacts.isEmpty)
    precondition(probe.selectedProperty == nil)
    precondition(probe.selectedProperties.isEmpty)
    precondition(!ContactsUIHostControl.pickerIsVisible(picker))
}

private final class PickerNotificationProbe: NSObject {
    var shown = 0
    var hidden = 0
    weak var lastObject: AnyObject?

    @objc func didShow(_ notification: Notification) {
        lastObject = notification.object as AnyObject?
        shown += 1
    }

    @objc func didHide(_ notification: Notification) {
        lastObject = notification.object as AnyObject?
        hidden += 1
    }
}

@MainActor
func testPickerDidShowHideNotifications() {
    let picker = CNContactPickerViewController()
    let notes = PickerNotificationProbe()
    NotificationCenter.default.addObserver(
        notes,
        selector: #selector(PickerNotificationProbe.didShow(_:)),
        name: .CNContactPickerViewControllerPickerDidShow,
        object: picker
    )
    NotificationCenter.default.addObserver(
        notes,
        selector: #selector(PickerNotificationProbe.didHide(_:)),
        name: .CNContactPickerViewControllerPickerDidHide,
        object: picker
    )
    defer { NotificationCenter.default.removeObserver(notes) }
    precondition(CNContactPickerViewControllerPickerDidShowNotification.rawValue
        == "CNContactPickerViewControllerPickerDidShowNotification")
    precondition(CNContactPickerViewControllerPickerDidHideNotification.rawValue
        == "CNContactPickerViewControllerPickerDidHideNotification")
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(notes.shown == 1)
    precondition(notes.hidden == 0)
    precondition(notes.lastObject === picker)
    let probe = PickerProbe()
    picker.delegate = probe
    ContactsUIHostControl.reportPickerCancel(picker)
    precondition(notes.shown == 1)
    precondition(notes.hidden == 1)
    precondition(probe.cancelled)
}
