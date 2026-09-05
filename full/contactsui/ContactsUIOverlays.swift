import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif

// Overlay members that require Contacts and UIKit.

#if canImport(UIKit) && canImport(Contacts)
extension UIApplicationShortcutIcon {
    /// Darwin overlay `init(contact:)`. The OpenUIKit type cannot store a
    /// contact-specific image (its `init(storage:)` is private), so Linux uses
    /// the generic `.contact` icon type and does not claim Apple shortcut art.
    public convenience init(contact: CNContact) {
        _ = contact
        self.init(type: .contact)
    }
}
#endif
