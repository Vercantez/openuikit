#if os(Linux)
import Glibc
#elseif os(Windows)
import ucrt
#else
import Darwin
#endif

@_spi(OpenUIKitHost) import ContactsUI
import Foundation

// MARK: - ContactsUICaptionTests.swift
/// Table-driven Caption enum: cases, raw values, failable init, Hashable.
@MainActor
func testCaptionCases() {
    let table: [(ContactAccessButton.Caption, String)] = [
        (.defaultText, "defaultText"),
        (.email, "email"),
        (.phone, "phone"),
    ]
    precondition(Set(table.map(\.0)).count == 3)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(ContactAccessButton.Caption(rawValue: raw) == value)
    }
    precondition(ContactAccessButton.Caption(rawValue: "not-a-caption") == nil)
    precondition(ContactAccessButton.Caption.email != .phone)
    precondition(ContactAccessButton.Caption.defaultText != .email)
    var hasher = Hasher()
    ContactAccessButton.Caption.phone.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ContactAccessButton.Caption.email.hashValue
    typealias Raw = ContactAccessButton.Caption.RawValue
    precondition((table[0].1 as Raw) == "defaultText")
}

// MARK: - ContactsUIStyleTests.swift
@MainActor
func testStyleAutomatic() {
    let automatic = ContactAccessButton.Style.automatic
    precondition(automatic.imageTrailingEdgePadding == nil)
    precondition(automatic.imageWidth == nil)
    precondition(automatic.imageColor == nil)
    let other = ContactAccessButton.Style()
    precondition(automatic == other)
}

@MainActor
func testStyleInitializer() {
    let custom = ContactAccessButton.Style(
        imageTrailingEdgePadding: 8,
        imageWidth: 30,
        imageColor: .accentColor
    )
    precondition(custom.imageTrailingEdgePadding == 8)
    precondition(custom.imageWidth == 30)
    precondition(custom.imageColor == .accentColor)
    precondition(custom != ContactAccessButton.Style.automatic)
}

// MARK: - ContactsUIAccessButtonTests.swift
@MainActor
func testAccessButtonInit() {
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
    let granted = ContactsUIHostControl.invokeAccessApproval(button)
    precondition(granted.isEmpty)
    precondition(received == [])
    let model = ContactsUIHostControl.accessPickerModel(button)
    precondition(model.queryString == "Anne")
    precondition(model.ignoredEmails == ["skip@example.com"])
    precondition(model.ignoredPhoneNumbers == ["+15555550100"])
    precondition(model.failClosedApprovedIdentifiers().isEmpty)
}

@MainActor
func testAccessButtonBody() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.body
    let _: ContactAccessButton.Body = button.body
}

@MainActor
func testContactAccessButtonCaption() {
    let button = ContactAccessButton(queryString: "Ada")
    let captioned = button.contactAccessButtonCaption(.email)
    precondition(captioned.linuxCaption == .email)
    let tags = ContactsUIHostControl.linuxModifierTags(captioned)
    precondition(tags.contains("contactAccessButtonCaption(_:)"))
}

@MainActor
func testContactAccessButtonStyle() {
    let button = ContactAccessButton(queryString: "Ada")
    let styled = button.contactAccessButtonStyle(ContactAccessButton.Style(imageWidth: 30))
    precondition(styled.linuxStyle.imageWidth == 30)
    let tags = ContactsUIHostControl.linuxModifierTags(styled)
    precondition(tags.contains("contactAccessButtonStyle(_:)"))
}

@MainActor
func testContactAccessPickerFailClosed() {
    var presented = true
    var granted: [String]?
    let binding = Binding(
        get: { presented },
        set: { presented = $0 }
    )
    let button = ContactAccessButton(queryString: "Ada")
    let gated = button.contactAccessPicker(isPresented: binding) { ids in
        granted = ids
    }
    precondition(presented == false)
    precondition(granted == [])
    let tags = ContactsUIHostControl.linuxModifierTags(gated)
    precondition(tags.contains("contactAccessPicker(isPresented:completionHandler:)"))
    let model = ContactsUIHostControl.accessPickerModel(button)
    precondition(model.queryString == "Ada")
    precondition(model.failClosedApprovedIdentifiers() == [])
}

@MainActor
func testViewContactAccessPicker() {
    var presented = true
    var granted: [String]?
    let binding = Binding(
        get: { presented },
        set: { presented = $0 }
    )
    var view: some View = EmptyView()
    view = view.contactAccessPicker(
        isPresented: binding,
        completionHandler: { ids in granted = ids }
    )
    _ = view
    precondition(presented == false)
    precondition(granted == [])
}

@MainActor
func testViewContactAccessButtonStyle() {
    var view: some View = EmptyView()
    view = view.contactAccessButtonStyle(ContactAccessButton.Style.automatic)
    _ = view
}

@MainActor
func testViewContactAccessButtonCaption() {
    var view: some View = EmptyView()
    view = view.contactAccessButtonCaption(.phone)
    _ = view
}

// MARK: - ContactsUIPickerTests.swift
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
    let compound = ContactsUIHostControl.predicate(
        format: "givenName == %@ AND emailAddresses.@count > 0",
        argument: "Ada"
    )
    picker.predicateForEnablingContact = compound
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    probe.selectedContact = nil
    precondition(ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: ada))
    precondition(!ContactsUIHostControl.evaluate(picker.predicateForEnablingContact, contact: bob))
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    probe.selectedContact = nil
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: bob))
    precondition(probe.selectedContact == nil)
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
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.pickerIsVisible(picker))
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    precondition(!ContactsUIHostControl.pickerIsVisible(picker))
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

@MainActor
func testPickerPredicateAndOrCompound() {
    let picker = CNContactPickerViewController()
    let ada = makeAda()
    let grace = CNMutableContact()
    grace.givenName = "Grace"
    grace.familyName = "Hopper"
    grace.emailAddresses = [
        CNLabeledValue(label: CNLabelWork, value: "grace@example.com" as NSString)
    ]
    let nameless = CNMutableContact()
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfContact = ContactsUIHostControl.and(
        ContactsUIHostControl.predicate(format: "givenName == %@", argument: "Ada"),
        ContactsUIHostControl.predicate(format: "emailAddresses.@count > 0")
    )
    let probe = PickerProbe()
    picker.delegate = probe
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    probe.selectedContact = nil
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: nameless))
    precondition(probe.selectedContact == nil)
    picker.predicateForSelectionOfContact = ContactsUIHostControl.or(
        ContactsUIHostControl.predicate(format: "givenName == %@", argument: "Ada"),
        ContactsUIHostControl.predicate(format: "givenName == %@", argument: "Grace")
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: grace))
    precondition(probe.selectedContact?.givenName == "Grace")
    probe.selectedContact = nil
    picker.predicateForSelectionOfContact = ContactsUIHostControl.predicate(
        format: "givenName == %@ OR givenName == %@",
        arguments: ["Ada", "Grace"]
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    probe.selectedContact = nil
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: nameless))
    precondition(probe.selectedContact == nil)
}

@MainActor
func testPickerPredicateCollectionContains() {
    let picker = CNContactPickerViewController()
    picker.predicateForEnablingContact = NSPredicate(value: true)
    picker.predicateForSelectionOfContact = ContactsUIHostControl.predicate(
        format: "emailAddresses CONTAINS[cd] %@",
        argument: "ADA@EXAMPLE.COM"
    )
    let probe = PickerProbe()
    picker.delegate = probe
    let ada = makeAda()
    let grace = CNMutableContact()
    grace.givenName = "Grace"
    grace.emailAddresses = [
        CNLabeledValue(label: CNLabelWork, value: "grace@example.com" as NSString)
    ]
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    probe.selectedContact = nil
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: grace))
    precondition(probe.selectedContact == nil)
    picker.predicateForSelectionOfContact = ContactsUIHostControl.predicate(
        format: "phoneNumbers == %@",
        argument: "+15555550100"
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.givenName == "Ada")
    probe.selectedContact = nil
    picker.predicateForSelectionOfContact = ContactsUIHostControl.predicate(
        format: "familyName ENDSWITH[cd] %@",
        argument: "lace"
    )
    precondition(ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact?.familyName == "Lovelace")
}

@MainActor
func testPickerFailingPredicateDoesNotHide() {
    let picker = CNContactPickerViewController()
    picker.predicateForEnablingContact = NSPredicate(value: false)
    picker.predicateForSelectionOfContact = NSPredicate(value: true)
    let probe = PickerProbe()
    picker.delegate = probe
    ContactsUIHostControl.reportPickerDidShow(picker)
    precondition(ContactsUIHostControl.pickerIsVisible(picker))
    let ada = makeAda()
    precondition(!ContactsUIHostControl.reportPickerSelection(picker, contact: ada))
    precondition(probe.selectedContact == nil)
    precondition(!probe.cancelled)
    precondition(ContactsUIHostControl.pickerIsVisible(picker))
}

private final class PickerNotificationProbe: @unchecked Sendable {
    var shown = 0
    var hidden = 0
    weak var lastObject: AnyObject?
}

@MainActor
func testPickerDidShowHideNotifications() {
    let picker = CNContactPickerViewController()
    let notes = PickerNotificationProbe()
    let showObserver = NotificationCenter.default.addObserver(
        forName: .CNContactPickerViewControllerPickerDidShow,
        object: picker,
        queue: nil
    ) { notification in
        notes.lastObject = notification.object as AnyObject?
        notes.shown += 1
    }
    let hideObserver = NotificationCenter.default.addObserver(
        forName: .CNContactPickerViewControllerPickerDidHide,
        object: picker,
        queue: nil
    ) { notification in
        notes.lastObject = notification.object as AnyObject?
        notes.hidden += 1
    }
    defer {
        NotificationCenter.default.removeObserver(showObserver)
        NotificationCenter.default.removeObserver(hideObserver)
    }
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

// MARK: - ContactsUIViewControllerTests.swift
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

private func makeEditorAda() -> CNMutableContact {
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
private func assertFailClosedCompletion(_ editor: CNContactViewController) {
    let probe = EditorProbe()
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerClass() {
    let editor = CNContactViewController(for: makeEditorAda())
    precondition(type(of: editor) === CNContactViewController.self)
    let asController: UIViewController = editor
    precondition(asController === editor)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerInitFor() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.allowsEditing == true)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerInitForContact() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(forContact: ada)
    precondition(editor.contact.familyName == "Lovelace")
    precondition(editor.allowsEditing == true)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerInitForNewContact() {
    let fresh = CNContactViewController(forNewContact: nil)
    precondition(fresh.allowsEditing == true)
    assertFailClosedCompletion(fresh)
    let ada = makeEditorAda()
    let seeded = CNContactViewController(forNewContact: ada)
    precondition(seeded.contact.givenName == "Ada")
    assertFailClosedCompletion(seeded)
}

@MainActor
func testViewControllerInitForUnknownContact() {
    let editor = CNContactViewController(forUnknownContact: makeEditorAda())
    precondition(editor.allowsEditing == false)
    precondition(editor.contact.givenName == "Ada")
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerDescriptorForRequiredKeys() {
    let descriptor = CNContactViewController.descriptorForRequiredKeys()
    _ = descriptor
    let editor = CNContactViewController(for: makeEditorAda())
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerHighlightProperty() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    editor.highlightProperty(
        withKey: CNContactEmailAddressesKey,
        identifier: ada.emailAddresses[0].identifier
    )
    precondition(
        ContactsUIHostControl.highlightedPropertyKey(editor) == CNContactEmailAddressesKey
    )
    precondition(
        ContactsUIHostControl.highlightedPropertyIdentifier(editor)
            == ada.emailAddresses[0].identifier
    )
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerAllowsActions() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    editor.allowsActions = false
    precondition(editor.allowsActions == false)
    let probe = EditorProbe()
    probe.allowDefault = true
    editor.delegate = probe
    let property = CNContactProperty(
        contact: ada,
        key: CNContactPhoneNumbersKey,
        value: ada.phoneNumbers[0].value.stringValue as NSString,
        identifier: ada.phoneNumbers[0].identifier,
        label: ada.phoneNumbers[0].label
    )
    precondition(!ContactsUIHostControl.shouldPerformDefaultAction(editor, for: property))
    precondition(probe.defaultActionProperty == nil)
    editor.allowsActions = true
    precondition(editor.allowsActions == true)
    precondition(ContactsUIHostControl.shouldPerformDefaultAction(editor, for: property))
    precondition(probe.defaultActionProperty?.key == CNContactPhoneNumbersKey)
    ContactsUIHostControl.reportViewControllerDidCancel(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerAllowsEditing() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.allowsEditing = false
    precondition(editor.allowsEditing == false)
    let unknown = CNContactViewController(forUnknownContact: CNMutableContact())
    precondition(unknown.allowsEditing == false)
    let unknownSections = ContactsUIHostControl.linuxContactSections(unknown)
    precondition(!unknownSections.contains { $0.kind == .phone })
    let fresh = CNContactViewController(forNewContact: nil)
    precondition(fresh.allowsEditing == true)
    let freshSections = ContactsUIHostControl.linuxContactSections(fresh)
    precondition(freshSections.contains { $0.kind == .phone })
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerAlternateName() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.alternateName = "Ada L."
    precondition(editor.alternateName == "Ada L.")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    let nameRow = sections.first { $0.kind == .name }?.rows.first
    precondition(nameRow?.value == "Ada L.")
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerContact() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.contact.identifier == ada.identifier)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerContactStore() {
    let editor = CNContactViewController(for: makeEditorAda())
    let store = CNContactStore()
    editor.contactStore = store
    precondition(editor.contactStore === store)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerDelegateProperty() {
    let editor = CNContactViewController(for: makeEditorAda())
    let probe = EditorProbe()
    editor.delegate = probe
    precondition(editor.delegate === probe)
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerDisplayedPropertyKeys() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.displayedPropertyKeys = [
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey,
        CNContactPostalAddressesKey,
    ]
    precondition((editor.displayedPropertyKeys as? [String])?.contains(CNContactPhoneNumbersKey) == true)
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    let kinds = Set(sections.map(\.kind))
    precondition(kinds.contains(.phone))
    precondition(kinds.contains(.email))
    precondition(kinds.contains(.address))
    editor.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    let filtered = ContactsUIHostControl.linuxContactSections(editor)
    let filteredKinds = Set(filtered.map(\.kind))
    precondition(filteredKinds.contains(.phone))
    precondition(!filteredKinds.contains(.email))
    precondition(!filteredKinds.contains(.address))
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerMessage() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.message = "Mathematician"
    precondition(editor.message == "Mathematician")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    precondition(sections.contains { $0.kind == .message })
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerParentContainer() {
    let editor = CNContactViewController(for: makeEditorAda())
    let container = CNContainer()
    editor.parentContainer = container
    precondition(editor.parentContainer === container)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerParentGroup() {
    let editor = CNContactViewController(for: makeEditorAda())
    let group = CNGroup()
    editor.parentGroup = group
    precondition(editor.parentGroup === group)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerShouldShowLinkedContacts() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.shouldShowLinkedContacts = true
    editor.contactStore = CNContactStore()
    precondition(editor.shouldShowLinkedContacts == true)
    precondition(ContactsUIHostControl.linkedContactCount(editor) == 0)
    editor.shouldShowLinkedContacts = false
    precondition(editor.shouldShowLinkedContacts == false)
    precondition(ContactsUIHostControl.linkedContactCount(editor) == 0)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerDelegateProtocol() {
    let editor = CNContactViewController(for: makeEditorAda())
    let probe = EditorProbe()
    editor.delegate = probe
    let existential: any CNContactViewControllerDelegate = probe
    _ = existential
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerDidCompleteWith() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    let probe = EditorProbe()
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
    ContactsUIHostControl.reportViewControllerCompletion(editor, contact: ada)
    precondition(probe.completed??.givenName == "Ada")
    precondition(probe.completed??.identifier == ada.identifier)
    ContactsUIHostControl.reportViewControllerDidCancel(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerShouldPerformDefaultAction() {
    let ada = makeEditorAda()
    let editor = CNContactViewController(for: ada)
    let probe = EditorProbe()
    probe.allowDefault = true
    editor.delegate = probe
    let property = CNContactProperty(
        contact: ada,
        key: CNContactEmailAddressesKey,
        value: "ada@example.com" as NSString,
        identifier: ada.emailAddresses[0].identifier,
        label: CNLabelWork
    )
    precondition(ContactsUIHostControl.shouldPerformDefaultAction(editor, for: property))
    precondition(probe.defaultActionProperty?.key == CNContactEmailAddressesKey)
}

// MARK: - ContactsUIOverlayTests.swift
@MainActor
func testMutableContactId() {
    let contact = CNMutableContact()
    let identifier = contact.id
    precondition(identifier == contact.id)
    _ = contact.identifier
}

@MainActor
func testShortcutIconInitContact() {
    let contact = CNMutableContact()
    contact.givenName = "Ada"
    let icon = UIApplicationShortcutIcon(contact: contact)
    precondition(ContactsUIHostControl.shortcutContactIdentifier(icon) == contact.identifier)
}

// MARK: - ContactsUIViewModifierTests.swift
@MainActor
private func assertModifierTag(_ button: ContactAccessButton, contains needle: String) {
    let tags = ContactsUIHostControl.linuxModifierTags(button)
    precondition(tags.contains { $0.contains(needle) }, "missing \(needle) in \(tags)")
}

@MainActor
func testModifierBrightness() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.brightness(0.25)
    assertModifierTag(modified, contains: "brightness(0.25)")
}

@MainActor
func testModifierMonospaced() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.monospaced(true)
    assertModifierTag(modified, contains: "monospaced(true)")
}

@MainActor
func testModifierSaturation() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.saturation(0.4)
    assertModifierTag(modified, contains: "saturation(0.4)")
}

@MainActor
func testModifierUnredacted() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.unredacted()
    assertModifierTag(modified, contains: "unredacted()")
}

@MainActor
func testModifierColorInvert() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.colorInvert()
    assertModifierTag(modified, contains: "colorInvert()")
}

@MainActor
func testModifierLineSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineSpacing(2)
    assertModifierTag(modified, contains: "lineSpacing(2.0)")
}

@MainActor
func testModifierScaledToFit() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scaledToFit()
    assertModifierTag(modified, contains: "scaledToFit()")
}

@MainActor
func testModifierSubmitScope() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.submitScope(true)
    assertModifierTag(modified, contains: "submitScope(true)")
}

@MainActor
func testModifierFindDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.findDisabled(true)
    assertModifierTag(modified, contains: "findDisabled(true)")
}

@MainActor
func testModifierLabelsHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelsHidden()
    assertModifierTag(modified, contains: "labelsHidden()")
}

@MainActor
func testModifierMoveDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.moveDisabled(true)
    assertModifierTag(modified, contains: "moveDisabled(true)")
}

@MainActor
func testModifierScaledToFill() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scaledToFill()
    assertModifierTag(modified, contains: "scaledToFill()")
}

@MainActor
func testModifierGeometryGroup() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.geometryGroup()
    assertModifierTag(modified, contains: "geometryGroup()")
}

@MainActor
func testModifierBaselineOffset() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.baselineOffset(1)
    assertModifierTag(modified, contains: "baselineOffset(1.0)")
}

@MainActor
func testModifierDeleteDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.deleteDisabled(true)
    assertModifierTag(modified, contains: "deleteDisabled(true)")
}

@MainActor
func testModifierLayoutPriority() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.layoutPriority(1.5)
    assertModifierTag(modified, contains: "layoutPriority(1.5)")
}

@MainActor
func testModifierListRowSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listRowSpacing(4)
    assertModifierTag(modified, contains: "listRowSpacing(4.0)")
}

@MainActor
func testModifierScrollDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.scrollDisabled(true)
    assertModifierTag(modified, contains: "scrollDisabled(true)")
}

@MainActor
func testModifierGridCellColumns() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.gridCellColumns(2)
    assertModifierTag(modified, contains: "gridCellColumns(2)")
}

@MainActor
func testModifierMonospacedDigit() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.monospacedDigit()
    assertModifierTag(modified, contains: "monospacedDigit()")
}

@MainActor
func testModifierReplaceDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.replaceDisabled(true)
    assertModifierTag(modified, contains: "replaceDisabled(true)")
}

@MainActor
func testModifierSafeAreaPaddingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(4)
    assertModifierTag(modified, contains: "safeAreaPadding(length:4.0)")
}

@MainActor
func testModifierSafeAreaPaddingInsets() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
    assertModifierTag(modified, contains: "safeAreaPadding(insets:1.0,2.0,3.0,4.0)")
}

@MainActor
func testModifierSafeAreaPaddingEdges() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.safeAreaPadding(.all, 6)
    assertModifierTag(modified, contains: "safeAreaPadding(edges:15,6.0)")
}

@MainActor
func testModifierStatusBarHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.statusBarHidden(true)
    assertModifierTag(modified, contains: "statusBarHidden(true)")
}

@MainActor
func testModifierAllowsHitTesting() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.allowsHitTesting(false)
    assertModifierTag(modified, contains: "allowsHitTesting(false)")
}

@MainActor
func testModifierAllowsTightening() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.allowsTightening(true)
    assertModifierTag(modified, contains: "allowsTightening(true)")
}

@MainActor
func testModifierCompositingGroup() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.compositingGroup()
    assertModifierTag(modified, contains: "compositingGroup()")
}

@MainActor
func testModifierLuminanceToAlpha() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.luminanceToAlpha()
    assertModifierTag(modified, contains: "luminanceToAlpha()")
}

@MainActor
func testModifierPrivacySensitive() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.privacySensitive(true)
    assertModifierTag(modified, contains: "privacySensitive(true)")
}

@MainActor
func testModifierDefaultAppStorage() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.defaultAppStorage(UserDefaults.standard)
    assertModifierTag(modified, contains: "defaultAppStorage")
}

@MainActor
func testModifierSelectionDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.selectionDisabled(true)
    assertModifierTag(modified, contains: "selectionDisabled(true)")
}

@MainActor
func testModifierListSectionSpacingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listSectionSpacing(8)
    assertModifierTag(modified, contains: "listSectionSpacing(length:8.0)")
}

@MainActor
func testModifierListSectionSpacingToken() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.listSectionSpacing(.default)
    assertModifierTag(modified, contains: "listSectionSpacing(token:default)")
}

@MainActor
func testModifierMinimumScaleFactor() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.minimumScaleFactor(0.8)
    assertModifierTag(modified, contains: "minimumScaleFactor(0.8)")
}

@MainActor
func testModifierNavigationDocumentPreviewBoth() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<String, Int>())
    assertModifierTag(modified, contains: "navigationDocument(preview:String,Int)")
}

@MainActor
func testModifierNavigationDocumentPreviewIcon() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<String, Never>())
    assertModifierTag(modified, contains: "navigationDocument(preview:String,Never)")
}

@MainActor
func testModifierNavigationDocumentPreviewNeverNever() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<Never, Never>())
    assertModifierTag(modified, contains: "navigationDocument(preview:Never,Never)")
}

@MainActor
func testModifierNavigationDocumentPreviewLabel() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("doc", preview: SharePreview<Never, String>())
    assertModifierTag(modified, contains: "navigationDocument(preview:Never,String)")
}

@MainActor
func testModifierNavigationDocumentURL() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument(URL(string: "https://example.com")!)
    assertModifierTag(modified, contains: "navigationDocument(url:https://example.com)")
}

@MainActor
func testModifierNavigationDocumentTransferable() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationDocument("payload")
    assertModifierTag(modified, contains: "navigationDocument(transferable:payload)")
}

@MainActor
func testModifierNavigationBarHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.navigationBarHidden(true)
    assertModifierTag(modified, contains: "navigationBarHidden(true)")
}

@MainActor
func testModifierDisableAutocorrection() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.disableAutocorrection(true)
    assertModifierTag(modified, contains: "disableAutocorrection(true)")
}

@MainActor
func testModifierLabelReservedIconWidth() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelReservedIconWidth(12)
    assertModifierTag(modified, contains: "labelReservedIconWidth(12.0)")
}

@MainActor
func testModifierLabelIconToTitleSpacing() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.labelIconToTitleSpacing(4)
    assertModifierTag(modified, contains: "labelIconToTitleSpacing(4.0)")
}

@MainActor
func testModifierBold() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.bold(true)
    assertModifierTag(modified, contains: "bold(true)")
}

@MainActor
func testModifierBadgeLocalizedStringResource() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(LocalizedStringResource("res"))
    assertModifierTag(modified, contains: "badge(resource:res)")
}

@MainActor
func testModifierBadgeLocalizedStringKey() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(LocalizedStringKey("key"))
    assertModifierTag(modified, contains: "badge(key:key)")
}

@MainActor
func testModifierBadgeText() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(Text("hi"))
    assertModifierTag(modified, contains: "badge(text:hi)")
}

@MainActor
func testModifierBadgeInt() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge(3)
    assertModifierTag(modified, contains: "badge(count:3)")
}

@MainActor
func testModifierBadgeStringProtocol() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.badge("label" as String?)
    assertModifierTag(modified, contains: "badge(string:label)")
}

@MainActor
func testModifierFrameWidthHeight() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame(width: 100, height: 40, alignment: .center)
    assertModifierTag(modified, contains: "frame(width:100.0,height:40.0)")
}

@MainActor
func testModifierFrameMinIdealMax() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame(minWidth: 10, idealWidth: 20, maxWidth: 30, minHeight: 40, idealHeight: 50, maxHeight: 60, alignment: .center)
    assertModifierTag(modified, contains: "frame(minIdealMax:10.0,20.0,30.0,40.0,50.0,60.0)")
}

@MainActor
func testModifierFrameEmpty() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.frame()
    assertModifierTag(modified, contains: "frame()")
}

@MainActor
func testModifierHidden() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.hidden()
    assertModifierTag(modified, contains: "hidden()")
}

@MainActor
func testModifierItalic() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.italic(true)
    assertModifierTag(modified, contains: "italic(true)")
}

@MainActor
func testModifierOffsetXY() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.offset(x: 1, y: 2)
    assertModifierTag(modified, contains: "offset(x:1.0,y:2.0)")
}

@MainActor
func testModifierOffsetSize() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.offset(CGSize(width: 3, height: 4))
    assertModifierTag(modified, contains: "offset(size:3.0x4.0)")
}

@MainActor
func testModifierZIndex() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.zIndex(2.5)
    assertModifierTag(modified, contains: "zIndex(2.5)")
}

@MainActor
func testModifierClipped() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.clipped(antialiased: true)
    assertModifierTag(modified, contains: "clipped(antialiased:true)")
}

@MainActor
func testModifierKerning() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.kerning(0.2)
    assertModifierTag(modified, contains: "kerning(0.2)")
}

@MainActor
func testModifierOpacity() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.opacity(0.5)
    assertModifierTag(modified, contains: "opacity(0.5)")
}

@MainActor
func testModifierPaddingLength() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(8)
    assertModifierTag(modified, contains: "padding(length:8.0)")
}

@MainActor
func testModifierPaddingInsets() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
    assertModifierTag(modified, contains: "padding(insets:1.0,1.0,1.0,1.0)")
}

@MainActor
func testModifierPaddingEdges() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.padding(.all, 8)
    assertModifierTag(modified, contains: "padding(edges:15,8.0)")
}

@MainActor
func testModifierContrast() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.contrast(1.1)
    assertModifierTag(modified, contains: "contrast(1.1)")
}

@MainActor
func testModifierDisabled() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.disabled(true)
    assertModifierTag(modified, contains: "disabled(true)")
}

@MainActor
func testModifierTracking() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.tracking(0.1)
    assertModifierTag(modified, contains: "tracking(0.1)")
}

@MainActor
func testModifierFixedSizeHV() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.fixedSize(horizontal: true, vertical: false)
    assertModifierTag(modified, contains: "fixedSize(horizontal:true,vertical:false)")
}

@MainActor
func testModifierFixedSize() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.fixedSize()
    assertModifierTag(modified, contains: "fixedSize()")
}

@MainActor
func testModifierFocusableInteractions() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.focusable(true, interactions: .automatic)
    assertModifierTag(modified, contains: "focusable(interactions:automatic)")
}

@MainActor
func testModifierFocusable() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.focusable(true)
    assertModifierTag(modified, contains: "focusable(true)")
}

@MainActor
func testModifierGrayscale() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.grayscale(0.2)
    assertModifierTag(modified, contains: "grayscale(0.2)")
}

@MainActor
func testModifierLineLimitReservesSpace() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2, reservesSpace: true)
    assertModifierTag(modified, contains: "lineLimit(2,reservesSpace:true)")
}

@MainActor
func testModifierLineLimitClosedRange() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(1...3)
    assertModifierTag(modified, contains: "lineLimit(closed:1...3)")
}

@MainActor
func testModifierLineLimitOptionalInt() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2 as Int?)
    assertModifierTag(modified, contains: "lineLimit(optional:2)")
}

@MainActor
func testModifierLineLimitPartialFrom() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(2...)
    assertModifierTag(modified, contains: "lineLimit(from:2)")
}

@MainActor
func testModifierLineLimitPartialThrough() {
    let button = ContactAccessButton(queryString: "Ada")
    let modified = button.lineLimit(...4)
    assertModifierTag(modified, contains: "lineLimit(through:4)")
}

// MARK: - ContactsUIViewOverlayTests.swift
@MainActor
func testViewOverlayBatch01() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accentColor(nil)
    _ = EmptyView().accentColor(nil)
    _ = button.accessibilityAction(nil, nil)
    _ = EmptyView().accessibilityAction(nil, nil)
    _ = button.accessibilityAction(action: nil, label: nil)
    _ = EmptyView().accessibilityAction(action: nil, label: nil)
    _ = button.accessibilityAction(named: nil, nil)
    _ = EmptyView().accessibilityAction(named: nil, nil)
    _ = button.accessibilityChartDescriptor(nil)
    _ = EmptyView().accessibilityChartDescriptor(nil)
    _ = button.accessibilityCustomContent(nil, nil, importance: nil)
    _ = EmptyView().accessibilityCustomContent(nil, nil, importance: nil)
    _ = button.actionSheet(isPresented: nil, content: nil)
    _ = EmptyView().actionSheet(isPresented: nil, content: nil)
    _ = button.actionSheet(item: nil, content: nil)
    _ = EmptyView().actionSheet(item: nil, content: nil)
    _ = button.badgeProminence(nil)
    _ = EmptyView().badgeProminence(nil)
    _ = button.buttonBorderShape(nil)
    _ = EmptyView().buttonBorderShape(nil)
    _ = button.buttonRepeatBehavior(nil)
    _ = EmptyView().buttonRepeatBehavior(nil)
    _ = button.defaultScrollAnchor(nil)
    _ = EmptyView().defaultScrollAnchor(nil)
    _ = button.defaultScrollAnchor(nil, for: nil)
    _ = EmptyView().defaultScrollAnchor(nil, for: nil)
    _ = button.distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    _ = EmptyView().distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    _ = button.fileExporterFilenameLabel(nil)
    _ = EmptyView().fileExporterFilenameLabel(nil)
    _ = button.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)
    _ = EmptyView().fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)
    _ = button.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
    _ = EmptyView().fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
    _ = button.gridColumnAlignment(nil)
    _ = EmptyView().gridColumnAlignment(nil)
    _ = button.mask(nil)
    _ = EmptyView().mask(nil)
    _ = button.mask(alignment: nil, nil)
    _ = EmptyView().mask(alignment: nil, nil)
    _ = button.menuStyle(nil)
    _ = EmptyView().menuStyle(nil)
    _ = button.onGeometryChange(for: nil, of: nil, action: nil)
    _ = EmptyView().onGeometryChange(for: nil, of: nil, action: nil)
    _ = button.onPreferenceChange(nil, perform: nil)
    _ = EmptyView().onPreferenceChange(nil, perform: nil)
    _ = button.onSubmit(of: nil, nil)
    _ = EmptyView().onSubmit(of: nil, nil)
    _ = button.onTapGesture(count: nil, coordinateSpace: nil, perform: nil)
    _ = EmptyView().onTapGesture(count: nil, coordinateSpace: nil, perform: nil)
    _ = button.onTapGesture(count: nil, perform: nil)
    _ = EmptyView().onTapGesture(count: nil, perform: nil)
    _ = button.presentationBackground(nil)
    _ = EmptyView().presentationBackground(nil)
    _ = button.presentationBackground(alignment: nil, content: nil)
    _ = EmptyView().presentationBackground(alignment: nil, content: nil)
    _ = button.progressViewStyle(nil)
    _ = EmptyView().progressViewStyle(nil)
    _ = button.scrollEdgeEffectHidden(nil, for: nil)
    _ = EmptyView().scrollEdgeEffectHidden(nil, for: nil)
    _ = button.scrollEdgeEffectStyle(nil, for: nil)
    _ = EmptyView().scrollEdgeEffectStyle(nil, for: nil)
    _ = button.scrollTargetBehavior(nil)
    _ = EmptyView().scrollTargetBehavior(nil)
    _ = button.searchFocused(nil)
    _ = EmptyView().searchFocused(nil)
    _ = button.searchFocused(nil, equals: nil)
    _ = EmptyView().searchFocused(nil, equals: nil)
    _ = button.sensoryFeedback(nil, trigger: nil)
    _ = EmptyView().sensoryFeedback(nil, trigger: nil)
    _ = button.sensoryFeedback(nil, trigger: nil, condition: nil)
    _ = EmptyView().sensoryFeedback(nil, trigger: nil, condition: nil)
    _ = button.sensoryFeedback(trigger: nil, nil)
    _ = EmptyView().sensoryFeedback(trigger: nil, nil)
    _ = button.simultaneousGesture(nil, including: nil)
    _ = EmptyView().simultaneousGesture(nil, including: nil)
    _ = button.simultaneousGesture(nil, isEnabled: nil)
    _ = EmptyView().simultaneousGesture(nil, isEnabled: nil)
    _ = button.simultaneousGesture(nil, name: nil, isEnabled: nil)
    _ = EmptyView().simultaneousGesture(nil, name: nil, isEnabled: nil)
    _ = button.speechAlwaysIncludesPunctuation(nil)
    _ = EmptyView().speechAlwaysIncludesPunctuation(nil)
    _ = button.speechSpellsOutCharacters(nil)
    _ = EmptyView().speechSpellsOutCharacters(nil)
    _ = button.submitLabel(nil)
    _ = EmptyView().submitLabel(nil)
    _ = button.symbolColorRenderingMode(nil)
    _ = EmptyView().symbolColorRenderingMode(nil)
    _ = button.symbolVariant(nil)
    _ = EmptyView().symbolVariant(nil)
    _ = button.tabViewCustomization(nil)
    _ = EmptyView().tabViewCustomization(nil)
    _ = button.tag(nil, includeOptional: nil)
    _ = EmptyView().tag(nil, includeOptional: nil)
    _ = button.textRenderer(nil)
    _ = EmptyView().textRenderer(nil)
    _ = button.toolbarTitleDisplayMode(nil)
    _ = EmptyView().toolbarTitleDisplayMode(nil)
}

@MainActor
func testViewOverlayBatch02() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibility(activationPoint: nil)
    _ = EmptyView().accessibility(activationPoint: nil)
    _ = button.accessibility(addTraits: nil)
    _ = EmptyView().accessibility(addTraits: nil)
    _ = button.accessibility(hidden: nil)
    _ = EmptyView().accessibility(hidden: nil)
    _ = button.accessibility(hint: nil)
    _ = EmptyView().accessibility(hint: nil)
    _ = button.accessibility(identifier: nil)
    _ = EmptyView().accessibility(identifier: nil)
    _ = button.accessibility(inputLabels: nil)
    _ = EmptyView().accessibility(inputLabels: nil)
    _ = button.accessibility(label: nil)
    _ = EmptyView().accessibility(label: nil)
    _ = button.accessibility(removeTraits: nil)
    _ = EmptyView().accessibility(removeTraits: nil)
    _ = button.accessibility(selectionIdentifier: nil)
    _ = EmptyView().accessibility(selectionIdentifier: nil)
    _ = button.accessibility(sortPriority: nil)
    _ = EmptyView().accessibility(sortPriority: nil)
    _ = button.accessibility(value: nil)
    _ = EmptyView().accessibility(value: nil)
    _ = button.accessibilityHeading(nil)
    _ = EmptyView().accessibilityHeading(nil)
    _ = button.accessibilityRespondsToUserInteraction(nil)
    _ = EmptyView().accessibilityRespondsToUserInteraction(nil)
    _ = button.accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
    _ = EmptyView().accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
    _ = button.accessibilityScrollStatus(nil, isEnabled: nil)
    _ = EmptyView().accessibilityScrollStatus(nil, isEnabled: nil)
    _ = button.anchorPreference(key: nil, value: nil, transform: nil)
    _ = EmptyView().anchorPreference(key: nil, value: nil, transform: nil)
    _ = button.backgroundStyle(nil)
    _ = EmptyView().backgroundStyle(nil)
    _ = button.containerBackground(nil, for: nil)
    _ = EmptyView().containerBackground(nil, for: nil)
    _ = button.containerBackground(for: nil, alignment: nil, content: nil)
    _ = EmptyView().containerBackground(for: nil, alignment: nil, content: nil)
    _ = button.contextMenu(nil)
    _ = EmptyView().contextMenu(nil)
    _ = button.contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    _ = EmptyView().contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    _ = button.contextMenu(menuItems: nil)
    _ = EmptyView().contextMenu(menuItems: nil)
    _ = button.contextMenu(menuItems: nil, preview: nil)
    _ = EmptyView().contextMenu(menuItems: nil, preview: nil)
    _ = button.defaultAdaptableTabBarPlacement(nil)
    _ = EmptyView().defaultAdaptableTabBarPlacement(nil)
    _ = button.gridCellUnsizedAxes(nil)
    _ = EmptyView().gridCellUnsizedAxes(nil)
    _ = button.highPriorityGesture(nil, including: nil)
    _ = EmptyView().highPriorityGesture(nil, including: nil)
    _ = button.highPriorityGesture(nil, isEnabled: nil)
    _ = EmptyView().highPriorityGesture(nil, isEnabled: nil)
    _ = button.highPriorityGesture(nil, name: nil, isEnabled: nil)
    _ = EmptyView().highPriorityGesture(nil, name: nil, isEnabled: nil)
    _ = button.indexViewStyle(nil)
    _ = EmptyView().indexViewStyle(nil)
    _ = button.keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)
    _ = EmptyView().keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)
    _ = button.keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
    _ = EmptyView().keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
    _ = button.listItemTint(nil)
    _ = EmptyView().listItemTint(nil)
    _ = button.listSectionMargins(nil, nil)
    _ = EmptyView().listSectionMargins(nil, nil)
    _ = button.matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)
    _ = EmptyView().matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)
    _ = button.menuOrder(nil)
    _ = EmptyView().menuOrder(nil)
    _ = button.navigationBarTitle(nil)
    _ = EmptyView().navigationBarTitle(nil)
    _ = button.navigationBarTitle(nil, displayMode: nil)
    _ = EmptyView().navigationBarTitle(nil, displayMode: nil)
    _ = button.navigationSplitViewStyle(nil)
    _ = EmptyView().navigationSplitViewStyle(nil)
    _ = button.onAppear(perform: nil)
    _ = EmptyView().onAppear(perform: nil)
    _ = button.overlayPreferenceValue(nil, nil)
    _ = EmptyView().overlayPreferenceValue(nil, nil)
    _ = button.overlayPreferenceValue(nil, alignment: nil, nil)
    _ = EmptyView().overlayPreferenceValue(nil, alignment: nil, nil)
    _ = button.paletteSelectionEffect(nil)
    _ = EmptyView().paletteSelectionEffect(nil)
    _ = button.presentationCornerRadius(nil)
    _ = EmptyView().presentationCornerRadius(nil)
    _ = button.refreshable(action: nil)
    _ = EmptyView().refreshable(action: nil)
    _ = button.safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)
    _ = EmptyView().safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)
    _ = button.scrollBounceBehavior(nil, axes: nil)
    _ = EmptyView().scrollBounceBehavior(nil, axes: nil)
    _ = button.speechAnnouncementsQueued(nil)
    _ = EmptyView().speechAnnouncementsQueued(nil)
    _ = button.strikethrough(nil, pattern: nil, color: nil)
    _ = EmptyView().strikethrough(nil, pattern: nil, color: nil)
    _ = button.swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)
    _ = EmptyView().swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)
    _ = button.symbolVariableValueMode(nil)
    _ = EmptyView().symbolVariableValueMode(nil)
    _ = button.tableStyle(nil)
    _ = EmptyView().tableStyle(nil)
    _ = button.textInputFormattingControlVisibility(nil, for: nil)
    _ = EmptyView().textInputFormattingControlVisibility(nil, for: nil)
    _ = button.toolbarBackgroundVisibility(nil, for: nil)
    _ = EmptyView().toolbarBackgroundVisibility(nil, for: nil)
    _ = button.transaction(nil)
    _ = EmptyView().transaction(nil)
    _ = button.transaction(nil, body: nil)
    _ = EmptyView().transaction(nil, body: nil)
    _ = button.transaction(value: nil, nil)
    _ = EmptyView().transaction(value: nil, nil)
    _ = button.transition(nil)
    _ = EmptyView().transition(nil)
    _ = button.writingDirection(strategy: nil)
    _ = EmptyView().writingDirection(strategy: nil)
}

@MainActor
func testViewOverlayBatch03() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityActions(nil)
    _ = EmptyView().accessibilityActions(nil)
    _ = button.accessibilityActions(category: nil, nil)
    _ = EmptyView().accessibilityActions(category: nil, nil)
    _ = button.accessibilityChildren(children: nil)
    _ = EmptyView().accessibilityChildren(children: nil)
    _ = button.accessibilityDragPoint(nil, description: nil)
    _ = EmptyView().accessibilityDragPoint(nil, description: nil)
    _ = button.accessibilityDragPoint(nil, description: nil, isEnabled: nil)
    _ = EmptyView().accessibilityDragPoint(nil, description: nil, isEnabled: nil)
    _ = button.accessibilityHint(nil)
    _ = EmptyView().accessibilityHint(nil)
    _ = button.accessibilityHint(nil, isEnabled: nil)
    _ = EmptyView().accessibilityHint(nil, isEnabled: nil)
    _ = button.accessibilitySortPriority(nil)
    _ = EmptyView().accessibilitySortPriority(nil)
    _ = button.accessibilityZoomAction(nil)
    _ = EmptyView().accessibilityZoomAction(nil)
    _ = button.backgroundPreferenceValue(nil, nil)
    _ = EmptyView().backgroundPreferenceValue(nil, nil)
    _ = button.backgroundPreferenceValue(nil, alignment: nil, nil)
    _ = EmptyView().backgroundPreferenceValue(nil, alignment: nil, nil)
    _ = button.border(nil, width: nil)
    _ = EmptyView().border(nil, width: nil)
    _ = button.clipShape(nil, style: nil)
    _ = EmptyView().clipShape(nil, style: nil)
    _ = button.cornerRadius(nil, antialiased: nil)
    _ = EmptyView().cornerRadius(nil, antialiased: nil)
    _ = button.dialogSuppressionToggle(nil, isSuppressed: nil)
    _ = EmptyView().dialogSuppressionToggle(nil, isSuppressed: nil)
    _ = button.dialogSuppressionToggle(isSuppressed: nil)
    _ = EmptyView().dialogSuppressionToggle(isSuppressed: nil)
    _ = button.environment(nil)
    _ = EmptyView().environment(nil)
    _ = button.environment(nil, nil)
    _ = EmptyView().environment(nil, nil)
    _ = button.fileDialogBrowserOptions(nil)
    _ = EmptyView().fileDialogBrowserOptions(nil)
    _ = button.fileMover(isPresented: nil, file: nil, onCompletion: nil)
    _ = EmptyView().fileMover(isPresented: nil, file: nil, onCompletion: nil)
    _ = button.fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileMover(isPresented: nil, files: nil, onCompletion: nil)
    _ = EmptyView().fileMover(isPresented: nil, files: nil, onCompletion: nil)
    _ = button.fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
    _ = button.gaugeStyle(nil)
    _ = EmptyView().gaugeStyle(nil)
    _ = button.glassEffectID(nil, in: nil)
    _ = EmptyView().glassEffectID(nil, in: nil)
    _ = button.hueRotation(nil)
    _ = EmptyView().hueRotation(nil)
    _ = button.interactiveDismissDisabled(nil)
    _ = EmptyView().interactiveDismissDisabled(nil)
    _ = button.invalidatableContent(nil)
    _ = EmptyView().invalidatableContent(nil)
    _ = button.listRowBackground(nil)
    _ = EmptyView().listRowBackground(nil)
    _ = button.listRowSeparator(nil, edges: nil)
    _ = EmptyView().listRowSeparator(nil, edges: nil)
    _ = button.navigationBarTitleDisplayMode(nil)
    _ = EmptyView().navigationBarTitleDisplayMode(nil)
    _ = button.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)
    _ = EmptyView().onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)
    _ = button.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    _ = EmptyView().onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    _ = button.onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    _ = EmptyView().onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    _ = button.onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
    _ = EmptyView().onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
    _ = button.onPencilSqueeze(perform: nil)
    _ = EmptyView().onPencilSqueeze(perform: nil)
    _ = button.popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    _ = EmptyView().popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    _ = button.popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    _ = EmptyView().popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    _ = button.presentationBackgroundInteraction(nil)
    _ = EmptyView().presentationBackgroundInteraction(nil)
    _ = button.previewContext(nil)
    _ = EmptyView().previewContext(nil)
    _ = button.scrollInputBehavior(nil, for: nil)
    _ = EmptyView().scrollInputBehavior(nil, for: nil)
    _ = button.scrollPosition(nil, anchor: nil)
    _ = EmptyView().scrollPosition(nil, anchor: nil)
    _ = button.scrollPosition(id: nil, anchor: nil)
    _ = EmptyView().scrollPosition(id: nil, anchor: nil)
    _ = button.scrollTargetLayout(isEnabled: nil)
    _ = EmptyView().scrollTargetLayout(isEnabled: nil)
    _ = button.sectionIndexLabel(nil)
    _ = EmptyView().sectionIndexLabel(nil)
    _ = button.symbolEffect(nil, options: nil, isActive: nil)
    _ = EmptyView().symbolEffect(nil, options: nil, isActive: nil)
    _ = button.symbolEffect(nil, options: nil, value: nil)
    _ = EmptyView().symbolEffect(nil, options: nil, value: nil)
    _ = button.tabViewSearchActivation(nil)
    _ = EmptyView().tabViewSearchActivation(nil)
    _ = button.task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)
    _ = EmptyView().task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)
    _ = button.task(id: nil, priority: nil, nil)
    _ = EmptyView().task(id: nil, priority: nil, nil)
    _ = button.task(priority: nil, nil)
    _ = EmptyView().task(priority: nil, nil)
    _ = button.textSelectionAffinity(nil)
    _ = EmptyView().textSelectionAffinity(nil)
    _ = button.underline(nil, pattern: nil, color: nil)
    _ = EmptyView().underline(nil, pattern: nil, color: nil)
}

@MainActor
func testViewOverlayBatch04() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityActivationPoint(nil)
    _ = EmptyView().accessibilityActivationPoint(nil)
    _ = button.accessibilityActivationPoint(nil, isEnabled: nil)
    _ = EmptyView().accessibilityActivationPoint(nil, isEnabled: nil)
    _ = button.accessibilityAdjustableAction(nil)
    _ = EmptyView().accessibilityAdjustableAction(nil)
    _ = button.accessibilityDropPoint(nil, description: nil)
    _ = EmptyView().accessibilityDropPoint(nil, description: nil)
    _ = button.accessibilityDropPoint(nil, description: nil, isEnabled: nil)
    _ = EmptyView().accessibilityDropPoint(nil, description: nil, isEnabled: nil)
    _ = button.accessibilityLabel(nil)
    _ = EmptyView().accessibilityLabel(nil)
    _ = button.accessibilityLabel(nil, isEnabled: nil)
    _ = EmptyView().accessibilityLabel(nil, isEnabled: nil)
    _ = button.accessibilityLabel(content: nil)
    _ = EmptyView().accessibilityLabel(content: nil)
    _ = button.accessibilityLabeledPair(role: nil, id: nil, in: nil)
    _ = EmptyView().accessibilityLabeledPair(role: nil, id: nil, in: nil)
    _ = button.accessibilityRemoveTraits(nil)
    _ = EmptyView().accessibilityRemoveTraits(nil)
    _ = button.buttonStyle(nil)
    _ = EmptyView().buttonStyle(nil)
    _ = button.colorMultiply(nil)
    _ = EmptyView().colorMultiply(nil)
    _ = button.colorScheme(nil)
    _ = EmptyView().colorScheme(nil)
    _ = button.containerRelativeFrame(nil, alignment: nil)
    _ = EmptyView().containerRelativeFrame(nil, alignment: nil)
    _ = button.containerRelativeFrame(nil, alignment: nil, nil)
    _ = EmptyView().containerRelativeFrame(nil, alignment: nil, nil)
    _ = button.containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
    _ = EmptyView().containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
    _ = button.containerShape(nil)
    _ = EmptyView().containerShape(nil)
    _ = button.containerValue(nil, nil)
    _ = EmptyView().containerValue(nil, nil)
    _ = button.contentMargins(nil, nil, for: nil)
    _ = EmptyView().contentMargins(nil, nil, for: nil)
    _ = button.contentMargins(nil, for: nil)
    _ = EmptyView().contentMargins(nil, for: nil)
    _ = button.controlGroupStyle(nil)
    _ = EmptyView().controlGroupStyle(nil)
    _ = button.disclosureGroupStyle(nil)
    _ = EmptyView().disclosureGroupStyle(nil)
    _ = button.documentBrowserContextMenu(nil)
    _ = EmptyView().documentBrowserContextMenu(nil)
    _ = button.font(nil)
    _ = EmptyView().font(nil)
    _ = button.fontDesign(nil)
    _ = EmptyView().fontDesign(nil)
    _ = button.foregroundColor(nil)
    _ = EmptyView().foregroundColor(nil)
    _ = button.headerProminence(nil)
    _ = EmptyView().headerProminence(nil)
    _ = button.hoverEffectDisabled(nil)
    _ = EmptyView().hoverEffectDisabled(nil)
    _ = button.matchedTransitionSource(id: nil, in: nil)
    _ = EmptyView().matchedTransitionSource(id: nil, in: nil)
    _ = button.matchedTransitionSource(id: nil, in: nil, configuration: nil)
    _ = EmptyView().matchedTransitionSource(id: nil, in: nil, configuration: nil)
    _ = button.onDrag(nil)
    _ = EmptyView().onDrag(nil)
    _ = button.onDrag(nil, preview: nil)
    _ = EmptyView().onDrag(nil, preview: nil)
    _ = button.presentationDetents(nil)
    _ = EmptyView().presentationDetents(nil)
    _ = button.presentationDetents(nil, selection: nil)
    _ = EmptyView().presentationDetents(nil, selection: nil)
    _ = button.previewDisplayName(nil)
    _ = EmptyView().previewDisplayName(nil)
    _ = button.scenePadding(nil)
    _ = EmptyView().scenePadding(nil)
    _ = button.scenePadding(nil, edges: nil)
    _ = EmptyView().scenePadding(nil, edges: nil)
    _ = button.searchCompletion(nil)
    _ = EmptyView().searchCompletion(nil)
    _ = button.sliderThumbVisibility(nil)
    _ = EmptyView().sliderThumbVisibility(nil)
    _ = button.statusBar(hidden: nil)
    _ = EmptyView().statusBar(hidden: nil)
    _ = button.tabViewSidebarHeader(content: nil)
    _ = EmptyView().tabViewSidebarHeader(content: nil)
    _ = button.textCase(nil)
    _ = EmptyView().textCase(nil)
    _ = button.toolbar(nil, for: nil)
    _ = EmptyView().toolbar(nil, for: nil)
    _ = button.toolbar(content: nil)
    _ = EmptyView().toolbar(content: nil)
    _ = button.toolbar(id: nil, content: nil)
    _ = EmptyView().toolbar(id: nil, content: nil)
    _ = button.toolbar(removing: nil)
    _ = EmptyView().toolbar(removing: nil)
    _ = button.toolbarForegroundStyle(nil, for: nil)
    _ = EmptyView().toolbarForegroundStyle(nil, for: nil)
    _ = button.toolbarRole(nil)
    _ = EmptyView().toolbarRole(nil)
    _ = button.transformEnvironment(nil, transform: nil)
    _ = EmptyView().transformEnvironment(nil, transform: nil)
    _ = button.writingToolsAffordanceVisibility(nil)
    _ = EmptyView().writingToolsAffordanceVisibility(nil)
}

@MainActor
func testViewOverlayBatch05() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityAddTraits(nil)
    _ = EmptyView().accessibilityAddTraits(nil)
    _ = button.accessibilityFocused(nil)
    _ = EmptyView().accessibilityFocused(nil)
    _ = button.accessibilityFocused(nil, equals: nil)
    _ = EmptyView().accessibilityFocused(nil, equals: nil)
    _ = button.allowsWindowActivationEvents()
    _ = EmptyView().allowsWindowActivationEvents()
    _ = button.allowsWindowActivationEvents(nil)
    _ = EmptyView().allowsWindowActivationEvents(nil)
    _ = button.containerCornerOffset(nil, sizeToFit: nil)
    _ = EmptyView().containerCornerOffset(nil, sizeToFit: nil)
    _ = button.coordinateSpace(nil)
    _ = EmptyView().coordinateSpace(nil)
    _ = button.coordinateSpace(name: nil)
    _ = EmptyView().coordinateSpace(name: nil)
    _ = button.defaultFocus(nil, nil, priority: nil)
    _ = EmptyView().defaultFocus(nil, nil, priority: nil)
    _ = button.fileDialogCustomizationID(nil)
    _ = EmptyView().fileDialogCustomizationID(nil)
    _ = button.fontWidth(nil)
    _ = EmptyView().fontWidth(nil)
    _ = button.groupBoxStyle(nil)
    _ = EmptyView().groupBoxStyle(nil)
    _ = button.id(nil)
    _ = EmptyView().id(nil)
    _ = button.imageScale(nil)
    _ = EmptyView().imageScale(nil)
    _ = button.layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    _ = EmptyView().layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    _ = button.layoutDirectionBehavior(nil)
    _ = EmptyView().layoutDirectionBehavior(nil)
    _ = button.listRowSeparatorTint(nil, edges: nil)
    _ = EmptyView().listRowSeparatorTint(nil, edges: nil)
    _ = button.listSectionIndexVisibility(nil)
    _ = EmptyView().listSectionIndexVisibility(nil)
    _ = button.listSectionSeparatorTint(nil, edges: nil)
    _ = EmptyView().listSectionSeparatorTint(nil, edges: nil)
    _ = button.onContinuousHover(coordinateSpace: nil, perform: nil)
    _ = EmptyView().onContinuousHover(coordinateSpace: nil, perform: nil)
    _ = button.position(nil)
    _ = EmptyView().position(nil)
    _ = button.position(x: nil, y: nil)
    _ = EmptyView().position(x: nil, y: nil)
    _ = button.projectionEffect(nil)
    _ = EmptyView().projectionEffect(nil)
    _ = button.rotationEffect(nil, anchor: nil)
    _ = EmptyView().rotationEffect(nil, anchor: nil)
    _ = button.searchPresentationToolbarBehavior(nil)
    _ = EmptyView().searchPresentationToolbarBehavior(nil)
    _ = button.searchSelection(nil)
    _ = EmptyView().searchSelection(nil)
    _ = button.searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    _ = EmptyView().searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    _ = button.searchable(text: nil, placement: nil, prompt: nil)
    _ = EmptyView().searchable(text: nil, placement: nil, prompt: nil)
    _ = button.searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    _ = EmptyView().searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    _ = button.searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = EmptyView().searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = button.shadow(color: nil, radius: nil, x: nil, y: nil)
    _ = EmptyView().shadow(color: nil, radius: nil, x: nil, y: nil)
    _ = button.speechAdjustedPitch(nil)
    _ = EmptyView().speechAdjustedPitch(nil)
    _ = button.tabViewSidebarBottomBar(content: nil)
    _ = EmptyView().tabViewSidebarBottomBar(content: nil)
    _ = button.tableColumnHeaders(nil)
    _ = EmptyView().tableColumnHeaders(nil)
    _ = button.toolbarBackground(nil, for: nil)
    _ = EmptyView().toolbarBackground(nil, for: nil)
    _ = button.userActivity(nil, element: nil, nil)
    _ = EmptyView().userActivity(nil, element: nil, nil)
    _ = button.userActivity(nil, isActive: nil, nil)
    _ = EmptyView().userActivity(nil, isActive: nil, nil)
}

@MainActor
func testViewOverlayBatch06() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityDefaultFocus(nil, nil)
    _ = EmptyView().accessibilityDefaultFocus(nil, nil)
    _ = button.accessibilityDirectTouch(nil, options: nil)
    _ = EmptyView().accessibilityDirectTouch(nil, options: nil)
    _ = button.accessibilityIdentifier(nil)
    _ = EmptyView().accessibilityIdentifier(nil)
    _ = button.accessibilityIdentifier(nil, isEnabled: nil)
    _ = EmptyView().accessibilityIdentifier(nil, isEnabled: nil)
    _ = button.accessibilityIgnoresInvertColors(nil)
    _ = EmptyView().accessibilityIgnoresInvertColors(nil)
    _ = button.accessibilityTextContentType(nil)
    _ = EmptyView().accessibilityTextContentType(nil)
    _ = button.alignmentGuide(nil, computeValue: nil)
    _ = EmptyView().alignmentGuide(nil, computeValue: nil)
    _ = button.aspectRatio(nil, contentMode: nil)
    _ = EmptyView().aspectRatio(nil, contentMode: nil)
    _ = button.blur(radius: nil, opaque: nil)
    _ = EmptyView().blur(radius: nil, opaque: nil)
    _ = button.colorEffect(nil, isEnabled: nil)
    _ = EmptyView().colorEffect(nil, isEnabled: nil)
    _ = button.contentTransition(nil)
    _ = EmptyView().contentTransition(nil)
    _ = button.datePickerStyle(nil)
    _ = EmptyView().datePickerStyle(nil)
    _ = button.defersSystemGestures(on: nil)
    _ = EmptyView().defersSystemGestures(on: nil)
    _ = button.dialogIcon(nil)
    _ = EmptyView().dialogIcon(nil)
    _ = button.fileDialogConfirmationLabel(nil)
    _ = EmptyView().fileDialogConfirmationLabel(nil)
    _ = button.fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)
    _ = EmptyView().fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)
    _ = button.fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    _ = EmptyView().fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    _ = button.fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = EmptyView().fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = button.focusedValue(nil)
    _ = EmptyView().focusedValue(nil)
    _ = button.focusedValue(nil, nil)
    _ = EmptyView().focusedValue(nil, nil)
    _ = button.glassEffectUnion(id: nil, namespace: nil)
    _ = EmptyView().glassEffectUnion(id: nil, namespace: nil)
    _ = button.handGestureShortcut(nil, isEnabled: nil)
    _ = EmptyView().handGestureShortcut(nil, isEnabled: nil)
    _ = button.navigationDestination(for: nil, destination: nil)
    _ = EmptyView().navigationDestination(for: nil, destination: nil)
    _ = button.navigationDestination(isPresented: nil, destination: nil)
    _ = EmptyView().navigationDestination(isPresented: nil, destination: nil)
    _ = button.navigationDestination(item: nil, destination: nil)
    _ = EmptyView().navigationDestination(item: nil, destination: nil)
    _ = button.navigationTitle(nil)
    _ = EmptyView().navigationTitle(nil)
    _ = button.onDrop(of: nil, delegate: nil)
    _ = EmptyView().onDrop(of: nil, delegate: nil)
    _ = button.onDrop(of: nil, isTargeted: nil, perform: nil)
    _ = EmptyView().onDrop(of: nil, isTargeted: nil, perform: nil)
    _ = button.onReceive(nil, perform: nil)
    _ = EmptyView().onReceive(nil, perform: nil)
    _ = button.onScrollPhaseChange(nil)
    _ = EmptyView().onScrollPhaseChange(nil)
    _ = button.presentationSizing(nil)
    _ = EmptyView().presentationSizing(nil)
    _ = button.redacted(reason: nil)
    _ = EmptyView().redacted(reason: nil)
    _ = button.renameAction(nil)
    _ = EmptyView().renameAction(nil)
    _ = button.scrollTransition(nil, axis: nil, transition: nil)
    _ = EmptyView().scrollTransition(nil, axis: nil, transition: nil)
    _ = button.scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
    _ = EmptyView().scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
    _ = button.searchToolbarBehavior(nil)
    _ = EmptyView().searchToolbarBehavior(nil)
    _ = button.sheet(isPresented: nil, onDismiss: nil, content: nil)
    _ = EmptyView().sheet(isPresented: nil, onDismiss: nil, content: nil)
    _ = button.sheet(item: nil, onDismiss: nil, content: nil)
    _ = EmptyView().sheet(item: nil, onDismiss: nil, content: nil)
    _ = button.symbolEffectsRemoved(nil)
    _ = EmptyView().symbolEffectsRemoved(nil)
    _ = button.tabBarMinimizeBehavior(nil)
    _ = EmptyView().tabBarMinimizeBehavior(nil)
    _ = button.tabViewSidebarFooter(content: nil)
    _ = EmptyView().tabViewSidebarFooter(content: nil)
    _ = button.textSelection(nil)
    _ = EmptyView().textSelection(nil)
    _ = button.toggleStyle(nil)
    _ = EmptyView().toggleStyle(nil)
    _ = button.transformAnchorPreference(key: nil, value: nil, transform: nil)
    _ = EmptyView().transformAnchorPreference(key: nil, value: nil, transform: nil)
    _ = button.visualEffect(nil)
    _ = EmptyView().visualEffect(nil)
}

@MainActor
func testViewOverlayBatch07() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityElement(children: nil)
    _ = EmptyView().accessibilityElement(children: nil)
    _ = button.accessibilityHidden(nil)
    _ = EmptyView().accessibilityHidden(nil)
    _ = button.accessibilityHidden(nil, isEnabled: nil)
    _ = EmptyView().accessibilityHidden(nil, isEnabled: nil)
    _ = button.accessibilityInputLabels(nil)
    _ = EmptyView().accessibilityInputLabels(nil)
    _ = button.accessibilityInputLabels(nil, isEnabled: nil)
    _ = EmptyView().accessibilityInputLabels(nil, isEnabled: nil)
    _ = button.accessibilityShowsLargeContentViewer()
    _ = EmptyView().accessibilityShowsLargeContentViewer()
    _ = button.accessibilityShowsLargeContentViewer(nil)
    _ = EmptyView().accessibilityShowsLargeContentViewer(nil)
    _ = button.autocapitalization(nil)
    _ = EmptyView().autocapitalization(nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)
    _ = EmptyView().confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    _ = EmptyView().confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    _ = EmptyView().confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
    _ = EmptyView().confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
    _ = button.contentShape(nil, nil, eoFill: nil)
    _ = EmptyView().contentShape(nil, nil, eoFill: nil)
    _ = button.contentShape(nil, eoFill: nil)
    _ = EmptyView().contentShape(nil, eoFill: nil)
    _ = button.flipsForRightToLeftLayoutDirection(nil)
    _ = EmptyView().flipsForRightToLeftLayoutDirection(nil)
    _ = button.focusEffectDisabled(nil)
    _ = EmptyView().focusEffectDisabled(nil)
    _ = button.fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)
    _ = EmptyView().fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)
    _ = button.fullScreenCover(item: nil, onDismiss: nil, content: nil)
    _ = EmptyView().fullScreenCover(item: nil, onDismiss: nil, content: nil)
    _ = button.handlesExternalEvents(preferring: nil, allowing: nil)
    _ = EmptyView().handlesExternalEvents(preferring: nil, allowing: nil)
    _ = button.keyboardType(nil)
    _ = EmptyView().keyboardType(nil)
    _ = button.listStyle(nil)
    _ = EmptyView().listStyle(nil)
    _ = button.modifier(nil)
    _ = EmptyView().modifier(nil)
    _ = button.multilineTextAlignment(nil)
    _ = EmptyView().multilineTextAlignment(nil)
    _ = button.multilineTextAlignment(strategy: nil)
    _ = EmptyView().multilineTextAlignment(strategy: nil)
    _ = button.navigationBarItems(leading: nil)
    _ = EmptyView().navigationBarItems(leading: nil)
    _ = button.navigationBarItems(leading: nil, trailing: nil)
    _ = EmptyView().navigationBarItems(leading: nil, trailing: nil)
    _ = button.navigationBarItems(trailing: nil)
    _ = EmptyView().navigationBarItems(trailing: nil)
    _ = button.navigationSplitViewColumnWidth(nil)
    _ = EmptyView().navigationSplitViewColumnWidth(nil)
    _ = button.navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
    _ = EmptyView().navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
    _ = button.navigationViewStyle(nil)
    _ = EmptyView().navigationViewStyle(nil)
    _ = button.onScrollGeometryChange(for: nil, of: nil, action: nil)
    _ = EmptyView().onScrollGeometryChange(for: nil, of: nil, action: nil)
    _ = button.persistentSystemOverlays(nil)
    _ = EmptyView().persistentSystemOverlays(nil)
    _ = button.phaseAnimator(nil, content: nil, animation: nil)
    _ = EmptyView().phaseAnimator(nil, content: nil, animation: nil)
    _ = button.phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
    _ = EmptyView().phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
    _ = button.pickerStyle(nil)
    _ = EmptyView().pickerStyle(nil)
    _ = button.preference(key: nil, value: nil)
    _ = EmptyView().preference(key: nil, value: nil)
    _ = button.preferredColorScheme(nil)
    _ = EmptyView().preferredColorScheme(nil)
    _ = button.presentationContentInteraction(nil)
    _ = EmptyView().presentationContentInteraction(nil)
    _ = button.presentationDragIndicator(nil)
    _ = EmptyView().presentationDragIndicator(nil)
    _ = button.previewLayout(nil)
    _ = EmptyView().previewLayout(nil)
    _ = button.scaleEffect(nil, anchor: nil)
    _ = EmptyView().scaleEffect(nil, anchor: nil)
    _ = button.scaleEffect(x: nil, y: nil, anchor: nil)
    _ = EmptyView().scaleEffect(x: nil, y: nil, anchor: nil)
    _ = button.searchDictationBehavior(nil)
    _ = EmptyView().searchDictationBehavior(nil)
    _ = button.tabViewStyle(nil)
    _ = EmptyView().tabViewStyle(nil)
    _ = button.textInputAutocapitalization(nil)
    _ = EmptyView().textInputAutocapitalization(nil)
    _ = button.toolbarTitleMenu(content: nil)
    _ = EmptyView().toolbarTitleMenu(content: nil)
    _ = button.transformEffect(nil)
    _ = EmptyView().transformEffect(nil)
    _ = button.truncationMode(nil)
    _ = EmptyView().truncationMode(nil)
    _ = button.typeSelectEquivalent(nil)
    _ = EmptyView().typeSelectEquivalent(nil)
}

@MainActor
func testViewOverlayBatch08() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityLinkedGroup(id: nil, in: nil)
    _ = EmptyView().accessibilityLinkedGroup(id: nil, in: nil)
    _ = button.accessibilityRotorEntry(id: nil, in: nil)
    _ = EmptyView().accessibilityRotorEntry(id: nil, in: nil)
    _ = button.accessibilityScrollAction(nil)
    _ = EmptyView().accessibilityScrollAction(nil)
    _ = button.accessibilityValue(nil)
    _ = EmptyView().accessibilityValue(nil)
    _ = button.accessibilityValue(nil, isEnabled: nil)
    _ = EmptyView().accessibilityValue(nil, isEnabled: nil)
    _ = button.attributedTextFormattingDefinition(nil)
    _ = EmptyView().attributedTextFormattingDefinition(nil)
    _ = button.background(nil, in: nil, fillStyle: nil)
    _ = EmptyView().background(nil, in: nil, fillStyle: nil)
    _ = button.background(nil, alignment: nil)
    _ = EmptyView().background(nil, alignment: nil)
    _ = button.background(nil, ignoresSafeAreaEdges: nil)
    _ = EmptyView().background(nil, ignoresSafeAreaEdges: nil)
    _ = button.background(in: nil, fillStyle: nil)
    _ = EmptyView().background(in: nil, fillStyle: nil)
    _ = button.background(alignment: nil, content: nil)
    _ = EmptyView().background(alignment: nil, content: nil)
    _ = button.background(ignoresSafeAreaEdges: nil)
    _ = EmptyView().background(ignoresSafeAreaEdges: nil)
    _ = button.backgroundExtensionEffect()
    _ = EmptyView().backgroundExtensionEffect()
    _ = button.backgroundExtensionEffect(isEnabled: nil)
    _ = EmptyView().backgroundExtensionEffect(isEnabled: nil)
    _ = button.blendMode(nil)
    _ = EmptyView().blendMode(nil)
    _ = button.buttonSizing(nil)
    _ = EmptyView().buttonSizing(nil)
    _ = button.contentToolbar(for: nil, content: nil)
    _ = EmptyView().contentToolbar(for: nil, content: nil)
    _ = button.controlSize(nil)
    _ = EmptyView().controlSize(nil)
    _ = button.environmentObject(nil)
    _ = EmptyView().environmentObject(nil)
    _ = button.fileDialogDefaultDirectory(nil)
    _ = EmptyView().fileDialogDefaultDirectory(nil)
    _ = button.fileDialogURLEnabled(nil)
    _ = EmptyView().fileDialogURLEnabled(nil)
    _ = button.findNavigator(isPresented: nil)
    _ = EmptyView().findNavigator(isPresented: nil)
    _ = button.focused(nil)
    _ = EmptyView().focused(nil)
    _ = button.focused(nil, equals: nil)
    _ = EmptyView().focused(nil, equals: nil)
    _ = button.fontWeight(nil)
    _ = EmptyView().fontWeight(nil)
    _ = button.glassEffect(nil, in: nil)
    _ = EmptyView().glassEffect(nil, in: nil)
    _ = button.gridCellAnchor(nil)
    _ = EmptyView().gridCellAnchor(nil)
    _ = button.ignoresSafeArea(nil, edges: nil)
    _ = EmptyView().ignoresSafeArea(nil, edges: nil)
    _ = button.labeledContentStyle(nil)
    _ = EmptyView().labeledContentStyle(nil)
    _ = button.labelsVisibility(nil)
    _ = EmptyView().labelsVisibility(nil)
    _ = button.navigationBarBackButtonHidden(nil)
    _ = EmptyView().navigationBarBackButtonHidden(nil)
    _ = button.navigationLinkIndicatorVisibility(nil)
    _ = EmptyView().navigationLinkIndicatorVisibility(nil)
    _ = button.navigationSubtitle(nil)
    _ = EmptyView().navigationSubtitle(nil)
    _ = button.onKeyPress(nil, action: nil)
    _ = EmptyView().onKeyPress(nil, action: nil)
    _ = button.onKeyPress(nil, phases: nil, action: nil)
    _ = EmptyView().onKeyPress(nil, phases: nil, action: nil)
    _ = button.onKeyPress(characters: nil, phases: nil, action: nil)
    _ = EmptyView().onKeyPress(characters: nil, phases: nil, action: nil)
    _ = button.onKeyPress(keys: nil, phases: nil, action: nil)
    _ = EmptyView().onKeyPress(keys: nil, phases: nil, action: nil)
    _ = button.onKeyPress(phases: nil, action: nil)
    _ = EmptyView().onKeyPress(phases: nil, action: nil)
    _ = button.overlay(nil, in: nil, fillStyle: nil)
    _ = EmptyView().overlay(nil, in: nil, fillStyle: nil)
    _ = button.overlay(nil, alignment: nil)
    _ = EmptyView().overlay(nil, alignment: nil)
    _ = button.overlay(nil, ignoresSafeAreaEdges: nil)
    _ = EmptyView().overlay(nil, ignoresSafeAreaEdges: nil)
    _ = button.overlay(alignment: nil, content: nil)
    _ = EmptyView().overlay(alignment: nil, content: nil)
    _ = button.scrollClipDisabled(nil)
    _ = EmptyView().scrollClipDisabled(nil)
    _ = button.searchScopes(nil, activation: nil, nil)
    _ = EmptyView().searchScopes(nil, activation: nil, nil)
    _ = button.searchScopes(nil, scopes: nil)
    _ = EmptyView().searchScopes(nil, scopes: nil)
    _ = button.searchSuggestions(nil)
    _ = EmptyView().searchSuggestions(nil)
    _ = button.searchSuggestions(nil, for: nil)
    _ = EmptyView().searchSuggestions(nil, for: nil)
    _ = button.springLoadingBehavior(nil)
    _ = EmptyView().springLoadingBehavior(nil)
    _ = button.tabViewBottomAccessory(content: nil)
    _ = EmptyView().tabViewBottomAccessory(content: nil)
    _ = button.textScale(nil, isEnabled: nil)
    _ = EmptyView().textScale(nil, isEnabled: nil)
    _ = button.tint(nil)
    _ = EmptyView().tint(nil)
    _ = button.typesettingLanguage(nil, isEnabled: nil)
    _ = EmptyView().typesettingLanguage(nil, isEnabled: nil)
    _ = button.writingToolsBehavior(nil)
    _ = EmptyView().writingToolsBehavior(nil)
}

@MainActor
func testViewOverlayBatch09() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.accessibilityRepresentation(representation: nil)
    _ = EmptyView().accessibilityRepresentation(representation: nil)
    _ = button.accessibilityRotor(nil, entries: nil)
    _ = EmptyView().accessibilityRotor(nil, entries: nil)
    _ = button.accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    _ = EmptyView().accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    _ = button.accessibilityRotor(nil, entries: nil, entryLabel: nil)
    _ = EmptyView().accessibilityRotor(nil, entries: nil, entryLabel: nil)
    _ = button.accessibilityRotor(nil, textRanges: nil)
    _ = EmptyView().accessibilityRotor(nil, textRanges: nil)
    _ = button.assistiveAccessNavigationIcon(nil)
    _ = EmptyView().assistiveAccessNavigationIcon(nil)
    _ = button.assistiveAccessNavigationIcon(systemImage: nil)
    _ = EmptyView().assistiveAccessNavigationIcon(systemImage: nil)
    _ = button.autocorrectionDisabled(nil)
    _ = EmptyView().autocorrectionDisabled(nil)
    _ = button.defaultHoverEffect(nil)
    _ = EmptyView().defaultHoverEffect(nil)
    _ = button.draggable(nil)
    _ = EmptyView().draggable(nil)
    _ = button.draggable(nil, preview: nil)
    _ = EmptyView().draggable(nil, preview: nil)
    _ = button.drawingGroup(opaque: nil, colorMode: nil)
    _ = EmptyView().drawingGroup(opaque: nil, colorMode: nil)
    _ = button.dropDestination(for: nil, action: nil, isTargeted: nil)
    _ = EmptyView().dropDestination(for: nil, action: nil, isTargeted: nil)
    _ = button.dropDestination(for: nil, isEnabled: nil, action: nil)
    _ = EmptyView().dropDestination(for: nil, isEnabled: nil, action: nil)
    _ = button.edgesIgnoringSafeArea(nil)
    _ = EmptyView().edgesIgnoringSafeArea(nil)
    _ = button.focusedObject(nil)
    _ = EmptyView().focusedObject(nil)
    _ = button.foregroundStyle(nil)
    _ = EmptyView().foregroundStyle(nil)
    _ = button.foregroundStyle(nil, nil)
    _ = EmptyView().foregroundStyle(nil, nil)
    _ = button.foregroundStyle(nil, nil, nil)
    _ = EmptyView().foregroundStyle(nil, nil, nil)
    _ = button.formStyle(nil)
    _ = EmptyView().formStyle(nil)
    _ = button.help(nil)
    _ = EmptyView().help(nil)
    _ = button.hoverEffect(nil)
    _ = EmptyView().hoverEffect(nil)
    _ = button.hoverEffect(nil, isEnabled: nil)
    _ = EmptyView().hoverEffect(nil, isEnabled: nil)
    _ = button.inspectorColumnWidth(nil)
    _ = EmptyView().inspectorColumnWidth(nil)
    _ = button.inspectorColumnWidth(min: nil, ideal: nil, max: nil)
    _ = EmptyView().inspectorColumnWidth(min: nil, ideal: nil, max: nil)
    _ = button.interactionActivityTrackingTag(nil)
    _ = EmptyView().interactionActivityTrackingTag(nil)
    _ = button.keyboardShortcut(nil)
    _ = EmptyView().keyboardShortcut(nil)
    _ = button.keyboardShortcut(nil, modifiers: nil)
    _ = EmptyView().keyboardShortcut(nil, modifiers: nil)
    _ = button.keyboardShortcut(nil, modifiers: nil, localization: nil)
    _ = EmptyView().keyboardShortcut(nil, modifiers: nil, localization: nil)
    _ = button.labelStyle(nil)
    _ = EmptyView().labelStyle(nil)
    _ = button.layoutValue(key: nil, value: nil)
    _ = EmptyView().layoutValue(key: nil, value: nil)
    _ = button.listSectionSeparator(nil, edges: nil)
    _ = EmptyView().listSectionSeparator(nil, edges: nil)
    _ = button.materialActiveAppearance(nil)
    _ = EmptyView().materialActiveAppearance(nil)
    _ = button.menuActionDismissBehavior(nil)
    _ = EmptyView().menuActionDismissBehavior(nil)
    _ = button.menuIndicator(nil)
    _ = EmptyView().menuIndicator(nil)
    _ = button.onChange(of: nil, initial: nil, nil)
    _ = EmptyView().onChange(of: nil, initial: nil, nil)
    _ = button.onChange(of: nil, perform: nil)
    _ = EmptyView().onChange(of: nil, perform: nil)
    _ = button.onHover(perform: nil)
    _ = EmptyView().onHover(perform: nil)
    _ = button.onPencilDoubleTap(perform: nil)
    _ = EmptyView().onPencilDoubleTap(perform: nil)
    _ = button.rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)
    _ = EmptyView().rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)
    _ = button.scrollContentBackground(nil)
    _ = EmptyView().scrollContentBackground(nil)
    _ = button.sectionActions(content: nil)
    _ = EmptyView().sectionActions(content: nil)
    _ = button.symbolRenderingMode(nil)
    _ = EmptyView().symbolRenderingMode(nil)
    _ = button.textContentType(nil)
    _ = EmptyView().textContentType(nil)
    _ = button.toolbarColorScheme(nil, for: nil)
    _ = EmptyView().toolbarColorScheme(nil, for: nil)
    _ = button.windowToolbarFullScreenVisibility(nil)
    _ = EmptyView().windowToolbarFullScreenVisibility(nil)
}

@MainActor
func testViewOverlayBatch10() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.alert(nil, isPresented: nil, actions: nil)
    _ = EmptyView().alert(nil, isPresented: nil, actions: nil)
    _ = button.alert(nil, isPresented: nil, actions: nil, message: nil)
    _ = EmptyView().alert(nil, isPresented: nil, actions: nil, message: nil)
    _ = button.alert(nil, isPresented: nil, presenting: nil, actions: nil)
    _ = EmptyView().alert(nil, isPresented: nil, presenting: nil, actions: nil)
    _ = button.alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    _ = EmptyView().alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    _ = button.alert(isPresented: nil, content: nil)
    _ = EmptyView().alert(isPresented: nil, content: nil)
    _ = button.alert(isPresented: nil, error: nil, actions: nil)
    _ = EmptyView().alert(isPresented: nil, error: nil, actions: nil)
    _ = button.alert(isPresented: nil, error: nil, actions: nil, message: nil)
    _ = EmptyView().alert(isPresented: nil, error: nil, actions: nil, message: nil)
    _ = button.alert(item: nil, content: nil)
    _ = EmptyView().alert(item: nil, content: nil)
    _ = button.allowedDynamicRange(nil)
    _ = EmptyView().allowedDynamicRange(nil)
    _ = button.animation(nil)
    _ = EmptyView().animation(nil)
    _ = button.animation(nil, body: nil)
    _ = EmptyView().animation(nil, body: nil)
    _ = button.animation(nil, value: nil)
    _ = EmptyView().animation(nil, value: nil)
    _ = button.dynamicTypeSize(nil)
    _ = EmptyView().dynamicTypeSize(nil)
    _ = button.fileDialogImportsUnresolvedAliases(nil)
    _ = EmptyView().fileDialogImportsUnresolvedAliases(nil)
    _ = button.fileDialogMessage(nil)
    _ = EmptyView().fileDialogMessage(nil)
    _ = button.focusedSceneObject(nil)
    _ = EmptyView().focusedSceneObject(nil)
    _ = button.focusedSceneValue(nil)
    _ = EmptyView().focusedSceneValue(nil)
    _ = button.focusedSceneValue(nil, nil)
    _ = EmptyView().focusedSceneValue(nil, nil)
    _ = button.gesture(nil)
    _ = EmptyView().gesture(nil)
    _ = button.gesture(nil, including: nil)
    _ = EmptyView().gesture(nil, including: nil)
    _ = button.gesture(nil, isEnabled: nil)
    _ = EmptyView().gesture(nil, isEnabled: nil)
    _ = button.gesture(nil, name: nil, isEnabled: nil)
    _ = EmptyView().gesture(nil, name: nil, isEnabled: nil)
    _ = button.glassEffectTransition(nil)
    _ = EmptyView().glassEffectTransition(nil)
    _ = button.inspector(isPresented: nil, content: nil)
    _ = EmptyView().inspector(isPresented: nil, content: nil)
    _ = button.itemProvider(nil)
    _ = EmptyView().itemProvider(nil)
    _ = button.lineHeight(nil)
    _ = EmptyView().lineHeight(nil)
    _ = button.listRowInsets(nil)
    _ = EmptyView().listRowInsets(nil)
    _ = button.listRowInsets(nil, nil)
    _ = EmptyView().listRowInsets(nil, nil)
    _ = button.navigationTransition(nil)
    _ = EmptyView().navigationTransition(nil)
    _ = button.onContinueUserActivity(nil, perform: nil)
    _ = EmptyView().onContinueUserActivity(nil, perform: nil)
    _ = button.onDisappear(perform: nil)
    _ = EmptyView().onDisappear(perform: nil)
    _ = button.onInteractiveResizeChange(nil)
    _ = EmptyView().onInteractiveResizeChange(nil)
    _ = button.onOpenURL(perform: nil)
    _ = EmptyView().onOpenURL(perform: nil)
    _ = button.onOpenURL(prefersInApp: nil)
    _ = EmptyView().onOpenURL(prefersInApp: nil)
    _ = button.onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)
    _ = EmptyView().onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)
    _ = button.onScrollVisibilityChange(threshold: nil, nil)
    _ = EmptyView().onScrollVisibilityChange(threshold: nil, nil)
    _ = button.presentationCompactAdaptation(nil)
    _ = EmptyView().presentationCompactAdaptation(nil)
    _ = button.presentationCompactAdaptation(horizontal: nil, vertical: nil)
    _ = EmptyView().presentationCompactAdaptation(horizontal: nil, vertical: nil)
    _ = button.previewDevice(nil)
    _ = EmptyView().previewDevice(nil)
    _ = button.previewInterfaceOrientation(nil)
    _ = EmptyView().previewInterfaceOrientation(nil)
    _ = button.safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)
    _ = EmptyView().safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)
    _ = button.scrollDismissesKeyboard(nil)
    _ = EmptyView().scrollDismissesKeyboard(nil)
    _ = button.scrollIndicators(nil, axes: nil)
    _ = EmptyView().scrollIndicators(nil, axes: nil)
    _ = button.scrollIndicatorsFlash(onAppear: nil)
    _ = EmptyView().scrollIndicatorsFlash(onAppear: nil)
    _ = button.scrollIndicatorsFlash(trigger: nil)
    _ = EmptyView().scrollIndicatorsFlash(trigger: nil)
    _ = button.tabItem(nil)
    _ = EmptyView().tabItem(nil)
    _ = button.textEditorStyle(nil)
    _ = EmptyView().textEditorStyle(nil)
    _ = button.textFieldStyle(nil)
    _ = EmptyView().textFieldStyle(nil)
    _ = button.toolbarVisibility(nil, for: nil)
    _ = EmptyView().toolbarVisibility(nil, for: nil)
    _ = button.transformPreference(nil, nil)
    _ = EmptyView().transformPreference(nil, nil)
}

@MainActor
func contactsUIRuntimeMain() {
    testCaptionCases()
    testStyleAutomatic()
    testStyleInitializer()
    testAccessButtonInit()
    testAccessButtonBody()
    testContactAccessButtonCaption()
    testContactAccessButtonStyle()
    testContactAccessPickerFailClosed()
    testViewContactAccessPicker()
    testViewContactAccessButtonStyle()
    testViewContactAccessButtonCaption()
    testPickerConstruction()
    testPickerDelegateProperty()
    testPickerDisplayedPropertyKeys()
    testPickerPredicateForEnablingContact()
    testPickerPredicateForSelectionOfContact()
    testPickerPredicateForSelectionOfProperty()
    testPickerDelegateProtocol()
    testPickerDidSelectContact()
    testPickerDidSelectContacts()
    testPickerDidSelectContactProperty()
    testPickerDidSelectContactProperties()
    testPickerDidCancel()
    testPickerPredicateAndOrCompound()
    testPickerPredicateCollectionContains()
    testPickerFailingPredicateDoesNotHide()
    testPickerDidShowHideNotifications()
    testViewControllerClass()
    testViewControllerInitFor()
    testViewControllerInitForContact()
    testViewControllerInitForNewContact()
    testViewControllerInitForUnknownContact()
    testViewControllerDescriptorForRequiredKeys()
    testViewControllerHighlightProperty()
    testViewControllerAllowsActions()
    testViewControllerAllowsEditing()
    testViewControllerAlternateName()
    testViewControllerContact()
    testViewControllerContactStore()
    testViewControllerDelegateProperty()
    testViewControllerDisplayedPropertyKeys()
    testViewControllerMessage()
    testViewControllerParentContainer()
    testViewControllerParentGroup()
    testViewControllerShouldShowLinkedContacts()
    testViewControllerDelegateProtocol()
    testViewControllerDidCompleteWith()
    testViewControllerShouldPerformDefaultAction()
    testMutableContactId()
    testShortcutIconInitContact()
    testModifierBrightness()
    testModifierMonospaced()
    testModifierSaturation()
    testModifierUnredacted()
    testModifierColorInvert()
    testModifierLineSpacing()
    testModifierScaledToFit()
    testModifierSubmitScope()
    testModifierFindDisabled()
    testModifierLabelsHidden()
    testModifierMoveDisabled()
    testModifierScaledToFill()
    testModifierGeometryGroup()
    testModifierBaselineOffset()
    testModifierDeleteDisabled()
    testModifierLayoutPriority()
    testModifierListRowSpacing()
    testModifierScrollDisabled()
    testModifierGridCellColumns()
    testModifierMonospacedDigit()
    testModifierReplaceDisabled()
    testModifierSafeAreaPaddingLength()
    testModifierSafeAreaPaddingInsets()
    testModifierSafeAreaPaddingEdges()
    testModifierStatusBarHidden()
    testModifierAllowsHitTesting()
    testModifierAllowsTightening()
    testModifierCompositingGroup()
    testModifierLuminanceToAlpha()
    testModifierPrivacySensitive()
    testModifierDefaultAppStorage()
    testModifierSelectionDisabled()
    testModifierListSectionSpacingLength()
    testModifierListSectionSpacingToken()
    testModifierMinimumScaleFactor()
    testModifierNavigationDocumentPreviewBoth()
    testModifierNavigationDocumentPreviewIcon()
    testModifierNavigationDocumentPreviewNeverNever()
    testModifierNavigationDocumentPreviewLabel()
    testModifierNavigationDocumentURL()
    testModifierNavigationDocumentTransferable()
    testModifierNavigationBarHidden()
    testModifierDisableAutocorrection()
    testModifierLabelReservedIconWidth()
    testModifierLabelIconToTitleSpacing()
    testModifierBold()
    testModifierBadgeLocalizedStringResource()
    testModifierBadgeLocalizedStringKey()
    testModifierBadgeText()
    testModifierBadgeInt()
    testModifierBadgeStringProtocol()
    testModifierFrameWidthHeight()
    testModifierFrameMinIdealMax()
    testModifierFrameEmpty()
    testModifierHidden()
    testModifierItalic()
    testModifierOffsetXY()
    testModifierOffsetSize()
    testModifierZIndex()
    testModifierClipped()
    testModifierKerning()
    testModifierOpacity()
    testModifierPaddingLength()
    testModifierPaddingInsets()
    testModifierPaddingEdges()
    testModifierContrast()
    testModifierDisabled()
    testModifierTracking()
    testModifierFixedSizeHV()
    testModifierFixedSize()
    testModifierFocusableInteractions()
    testModifierFocusable()
    testModifierGrayscale()
    testModifierLineLimitReservesSpace()
    testModifierLineLimitClosedRange()
    testModifierLineLimitOptionalInt()
    testModifierLineLimitPartialFrom()
    testModifierLineLimitPartialThrough()
    testViewOverlayBatch01()
    testViewOverlayBatch02()
    testViewOverlayBatch03()
    testViewOverlayBatch04()
    testViewOverlayBatch05()
    testViewOverlayBatch06()
    testViewOverlayBatch07()
    testViewOverlayBatch08()
    testViewOverlayBatch09()
    testViewOverlayBatch10()
    fputs("CONTACTSUI_AGENT_RUNTIME_OK\n", stdout)
    fflush(stdout)
}

Task { @MainActor in
    contactsUIRuntimeMain()
    exit(0)
}

dispatchMain()
