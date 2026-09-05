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
    let editor = CNContactViewController(for: makeEditorAda())
    editor.allowsActions = false
    precondition(editor.allowsActions == false)
    editor.allowsActions = true
    precondition(editor.allowsActions == true)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerAllowsEditing() {
    let editor = CNContactViewController(for: makeEditorAda())
    editor.allowsEditing = false
    precondition(editor.allowsEditing == false)
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
    precondition(editor.shouldShowLinkedContacts == true)
    editor.shouldShowLinkedContacts = false
    precondition(editor.shouldShowLinkedContacts == false)
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
    let editor = CNContactViewController(for: makeEditorAda())
    let probe = EditorProbe()
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
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
    fputs("CONTACTSUI_AGENT_RUNTIME_OK\n", stdout)
    fflush(stdout)
}

Task { @MainActor in
    contactsUIRuntimeMain()
    exit(0)
}

dispatchMain()
