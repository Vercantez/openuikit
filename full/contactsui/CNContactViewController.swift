import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Contact editor / viewer. Darwin subclasses `UIViewController`. Isolated Linux
/// stores display flags and never loads an address book. `CNContact`-typed
/// members compile only when Contacts is imported.
@MainActor
public class CNContactViewController: NSObject {
    public weak var delegate: (any CNContactViewControllerDelegate)?
    public var displayedPropertyKeys: [Any]?
    public var alternateName: String?
    public var message: String?
    public var allowsEditing: Bool = true
    public var allowsActions: Bool = true
    public var shouldShowLinkedContacts: Bool = false

    var linuxHighlightedPropertyKey: String?
    var linuxHighlightedPropertyIdentifier: String?
    var linuxCompletedWithoutSaving: Bool = false

    #if canImport(Contacts)
    public private(set) var contact: CNContact
    public var contactStore: CNContactStore?
    public var parentGroup: CNGroup?
    public var parentContainer: CNContainer?

    @MainActor
    public class func descriptorForRequiredKeys() -> any CNKeyDescriptor {
        CNContact.descriptorForAllComparatorKeys()
    }

    @MainActor
    public convenience init(for contact: CNContact) {
        self.init(storedContact: contact, allowsEditing: true)
    }

    @MainActor
    public convenience init(forContact contact: CNContact) {
        self.init(storedContact: contact, allowsEditing: true)
    }

    @MainActor
    public convenience init(forUnknownContact contact: CNContact) {
        self.init(storedContact: contact, allowsEditing: false)
    }

    @MainActor
    public convenience init(forNewContact contact: CNContact?) {
        self.init(storedContact: contact, allowsEditing: true)
    }

    private init(storedContact: CNContact?, allowsEditing: Bool) {
        self.contact = storedContact ?? CNMutableContact()
        super.init()
        self.allowsEditing = allowsEditing
    }
    #else
    public override init() {
        super.init()
    }
    #endif

    @MainActor
    public func highlightProperty(withKey key: String, identifier: String?) {
        linuxHighlightedPropertyKey = key
        linuxHighlightedPropertyIdentifier = identifier
    }
}

@MainActor
public protocol CNContactViewControllerDelegate: NSObjectProtocol {
    #if canImport(Contacts)
    func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    )
    func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool
    #endif
}

extension CNContactViewControllerDelegate {
    #if canImport(Contacts)
    public func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    ) {
        _ = viewController
        _ = contact
    }

    public func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool {
        _ = property
        return false
    }
    #endif
}
