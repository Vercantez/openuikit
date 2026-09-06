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
    fputs("CONTACTSUI_AGENT_RUNTIME_OK\n", stdout)
    fflush(stdout)
}

Task { @MainActor in
    contactsUIRuntimeMain()
    exit(0)
}

dispatchMain()
