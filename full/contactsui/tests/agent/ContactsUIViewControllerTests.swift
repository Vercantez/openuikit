@_spi(OpenUIKitHost) import ContactsUI
import Foundation

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
private func assertFailClosedCompletion(_ editor: CNContactViewController) {
    let probe = EditorProbe()
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerClass() {
    let editor = CNContactViewController(for: makeAda())
    precondition(type(of: editor) === CNContactViewController.self)
    let asController: UIViewController = editor
    precondition(asController === editor)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerInitFor() {
    let ada = makeAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.allowsEditing == true)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerInitForContact() {
    let ada = makeAda()
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
    let ada = makeAda()
    let seeded = CNContactViewController(forNewContact: ada)
    precondition(seeded.contact.givenName == "Ada")
    assertFailClosedCompletion(seeded)
}

@MainActor
func testViewControllerInitForUnknownContact() {
    let editor = CNContactViewController(forUnknownContact: makeAda())
    precondition(editor.allowsEditing == false)
    precondition(editor.contact.givenName == "Ada")
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerDescriptorForRequiredKeys() {
    let descriptor = CNContactViewController.descriptorForRequiredKeys()
    _ = descriptor
    let editor = CNContactViewController(for: makeAda())
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerHighlightProperty() {
    let ada = makeAda()
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
    let ada = makeAda()
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
    let editor = CNContactViewController(for: makeAda())
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
    let editor = CNContactViewController(for: makeAda())
    editor.alternateName = "Ada L."
    precondition(editor.alternateName == "Ada L.")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    let nameRow = sections.first { $0.kind == .name }?.rows.first
    precondition(nameRow?.value == "Ada L.")
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerContact() {
    let ada = makeAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.contact.identifier == ada.identifier)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerContactStore() {
    let editor = CNContactViewController(for: makeAda())
    let store = CNContactStore()
    editor.contactStore = store
    precondition(editor.contactStore === store)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerDelegateProperty() {
    let editor = CNContactViewController(for: makeAda())
    let probe = EditorProbe()
    editor.delegate = probe
    precondition(editor.delegate === probe)
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerDisplayedPropertyKeys() {
    let editor = CNContactViewController(for: makeAda())
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
    let editor = CNContactViewController(for: makeAda())
    editor.message = "Mathematician"
    precondition(editor.message == "Mathematician")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    precondition(sections.contains { $0.kind == .message })
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerParentContainer() {
    let editor = CNContactViewController(for: makeAda())
    let container = CNContainer()
    editor.parentContainer = container
    precondition(editor.parentContainer === container)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerParentGroup() {
    let editor = CNContactViewController(for: makeAda())
    let group = CNGroup()
    editor.parentGroup = group
    precondition(editor.parentGroup === group)
    assertFailClosedCompletion(editor)
}

@MainActor
func testViewControllerShouldShowLinkedContacts() {
    let editor = CNContactViewController(for: makeAda())
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
    let editor = CNContactViewController(for: makeAda())
    let probe = EditorProbe()
    editor.delegate = probe
    let existential: any CNContactViewControllerDelegate = probe
    _ = existential
    ContactsUIHostControl.reportViewControllerCompletion(editor)
    precondition(probe.completed == .some(nil))
}

@MainActor
func testViewControllerDidCompleteWith() {
    let ada = makeAda()
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
    let ada = makeAda()
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
