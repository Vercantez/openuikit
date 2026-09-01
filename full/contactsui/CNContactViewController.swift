#if canImport(Contacts) && canImport(UIKit)
import Contacts
import UIKit

@MainActor
public protocol CNContactViewControllerDelegate: AnyObject {
    func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    )
    func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool
}

extension CNContactViewControllerDelegate {
    public func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    ) {}

    public func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool {
        true
    }
}

/// Host-driven contact card / editor using real UIKit and Contacts types.
/// Completing is an SPI host action; nothing is written to an Apple system store.
@MainActor
open class CNContactViewController: UIViewController {
    public private(set) var contact: CNContact
    public weak var delegate: (any CNContactViewControllerDelegate)?
    public var contactStore: CNContactStore?
    public var displayedPropertyKeys: [Any]?
    public var allowsActions = true
    public var allowsEditing = true
    public var shouldShowLinkedContacts = false
    public var alternateName: String?
    public var message: String?
    public var parentGroup: CNGroup?
    public var parentContainer: CNContainer?

    public private(set) var highlightedPropertyKey: String?
    public private(set) var highlightedPropertyIdentifier: String?

    public static func descriptorForRequiredKeys() -> any CNKeyDescriptor {
        CNContact.descriptorForAllComparatorKeys()
    }

    init(contact: CNContact) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }

    public convenience init(for contact: CNContact) {
        self.init(contact: contact)
        allowsEditing = true
        allowsActions = true
    }

    public convenience init(forContact contact: CNContact) {
        self.init(for: contact)
    }

    public convenience init(forNewContact contact: CNContact?) {
        self.init(contact: contact ?? CNMutableContact())
        allowsEditing = true
        allowsActions = false
    }

    public convenience init(forUnknownContact contact: CNContact) {
        self.init(contact: contact)
        allowsEditing = false
        allowsActions = true
    }

    public func highlightProperty(withKey key: String, identifier: String?) {
        highlightedPropertyKey = key
        highlightedPropertyIdentifier = identifier
    }

    /// Host action corresponding to Done / Create. Passing `nil` matches a
    /// cancelled new-contact flow. Does not persist to a system store.
    @_spi(OpenUIKitHost)
    open func reportCompletion(contact: CNContact?) {
        if let contact {
            self.contact = contact
        }
        delegate?.contactViewController(self, didCompleteWith: contact)
    }

    @_spi(OpenUIKitHost)
    open func shouldPerformDefaultAction(for property: CNContactProperty) -> Bool {
        delegate?.contactViewController(self, shouldPerformDefaultActionFor: property) ?? true
    }
}
#endif
