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
func testViewControllerClass() {
    let editor = CNContactViewController(for: makeAda())
    precondition(type(of: editor) === CNContactViewController.self)
    let asController: UIViewController = editor
    precondition(asController === editor)
}

@MainActor
func testViewControllerInitFor() {
    let ada = makeAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.allowsEditing == true)
}

@MainActor
func testViewControllerInitForContact() {
    let ada = makeAda()
    let editor = CNContactViewController(forContact: ada)
    precondition(editor.contact.familyName == "Lovelace")
    precondition(editor.allowsEditing == true)
}

@MainActor
func testViewControllerInitForNewContact() {
    let fresh = CNContactViewController(forNewContact: nil)
    precondition(fresh.allowsEditing == true)
    let ada = makeAda()
    let seeded = CNContactViewController(forNewContact: ada)
    precondition(seeded.contact.givenName == "Ada")
}

@MainActor
func testViewControllerInitForUnknownContact() {
    let editor = CNContactViewController(forUnknownContact: makeAda())
    precondition(editor.allowsEditing == false)
    precondition(editor.contact.givenName == "Ada")
}

@MainActor
func testViewControllerDescriptorForRequiredKeys() {
    let descriptor = CNContactViewController.descriptorForRequiredKeys()
    _ = descriptor
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
}

@MainActor
func testViewControllerAllowsActions() {
    let editor = CNContactViewController(for: makeAda())
    editor.allowsActions = false
    precondition(editor.allowsActions == false)
    editor.allowsActions = true
    precondition(editor.allowsActions == true)
}

@MainActor
func testViewControllerAllowsEditing() {
    let editor = CNContactViewController(for: makeAda())
    editor.allowsEditing = false
    precondition(editor.allowsEditing == false)
}

@MainActor
func testViewControllerAlternateName() {
    let editor = CNContactViewController(for: makeAda())
    editor.alternateName = "Ada L."
    precondition(editor.alternateName == "Ada L.")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    let nameRow = sections.first { $0.kind == .name }?.rows.first
    precondition(nameRow?.value == "Ada L.")
}

@MainActor
func testViewControllerContact() {
    let ada = makeAda()
    let editor = CNContactViewController(for: ada)
    precondition(editor.contact.givenName == "Ada")
    precondition(editor.contact.identifier == ada.identifier)
}

@MainActor
func testViewControllerContactStore() {
    let editor = CNContactViewController(for: makeAda())
    let store = CNContactStore()
    editor.contactStore = store
    precondition(editor.contactStore === store)
}

@MainActor
func testViewControllerDelegateProperty() {
    let editor = CNContactViewController(for: makeAda())
    let probe = EditorProbe()
    editor.delegate = probe
    precondition(editor.delegate === probe)
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
}

@MainActor
func testViewControllerMessage() {
    let editor = CNContactViewController(for: makeAda())
    editor.message = "Mathematician"
    precondition(editor.message == "Mathematician")
    let sections = ContactsUIHostControl.linuxContactSections(editor)
    precondition(sections.contains { $0.kind == .message })
}

@MainActor
func testViewControllerParentContainer() {
    let editor = CNContactViewController(for: makeAda())
    let container = CNContainer()
    editor.parentContainer = container
    precondition(editor.parentContainer === container)
}

@MainActor
func testViewControllerParentGroup() {
    let editor = CNContactViewController(for: makeAda())
    let group = CNGroup()
    editor.parentGroup = group
    precondition(editor.parentGroup === group)
}

@MainActor
func testViewControllerShouldShowLinkedContacts() {
    let editor = CNContactViewController(for: makeAda())
    editor.shouldShowLinkedContacts = true
    precondition(editor.shouldShowLinkedContacts == true)
    editor.shouldShowLinkedContacts = false
    precondition(editor.shouldShowLinkedContacts == false)
}

@MainActor
func testViewControllerDelegateProtocol() {
    let editor = CNContactViewController(for: makeAda())
    let probe = EditorProbe()
    editor.delegate = probe
    let existential: any CNContactViewControllerDelegate = probe
    _ = existential
}

@MainActor
func testViewControllerDidCompleteWith() {
    let editor = CNContactViewController(for: makeAda())
    let probe = EditorProbe()
    editor.delegate = probe
    ContactsUIHostControl.reportViewControllerCompletion(editor)
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
