#if canImport(UIKit) && canImport(Contacts)
import Contacts
import UIKit

extension UIApplicationShortcutIcon {
    /// ContactsUI overlay on UIKit's shortcut icon. This host cannot produce an
    /// Apple Home Screen glyph from a contact.
    public convenience init(contact: CNContact) {
        _ = contact.identifier
        self.init()
    }
}
#endif
