import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if !canImport(UIKit)
/// Contacts-backed shortcut icon token. Without UIKit this is a value holder
/// for the contact identifier, not a Home Screen icon renderer.
open class UIApplicationShortcutIcon: NSObject {
    public let contactIdentifier: String

    public init(contact: CNContact) {
        contactIdentifier = contact.identifier
        super.init()
    }
}
#endif
