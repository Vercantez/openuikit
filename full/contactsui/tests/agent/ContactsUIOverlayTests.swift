@_spi(OpenUIKitHost) import ContactsUI
import Foundation

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
