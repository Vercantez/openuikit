import Foundation

#if canImport(UIKit)
import UIKit
#endif

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

/// Host-driven contact card / editor. It preserves the supplied contact and
/// display options. Completing or cancelling is a host action; nothing is
/// written to an Apple system store.
@MainActor
open class CNContactViewController: ContactsUIPresenter {
    public enum Mode: Int, Equatable, Sendable {
        case existing = 0
        case unknown = 1
        case new = 2
    }

    public private(set) var contact: CNContact
    public private(set) var mode: Mode
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
        CNContactKeyDescriptor(keys: [
            "identifier",
            "givenName",
            "familyName",
            "organizationName",
            "phoneNumbers",
            "emailAddresses",
            "imageData",
            "thumbnailImageData",
        ])
    }

#if canImport(UIKit)
    public init(mode: Mode, contact: CNContact) {
        self.mode = mode
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
        applyModeDefaults()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }
#else
    public init(mode: Mode, contact: CNContact) {
        self.mode = mode
        self.contact = contact
        super.init()
        applyModeDefaults()
    }
#endif

    public convenience init(for contact: CNContact) {
        self.init(mode: .existing, contact: contact)
    }

    public convenience init(forContact contact: CNContact) {
        self.init(for: contact)
    }

    public convenience init(forNewContact contact: CNContact?) {
        self.init(mode: .new, contact: contact ?? CNMutableContact())
        allowsEditing = true
        allowsActions = false
    }

    public convenience init(forUnknownContact contact: CNContact) {
        self.init(mode: .unknown, contact: contact)
        allowsEditing = false
        allowsActions = true
    }

    public func highlightProperty(withKey key: String, identifier: String?) {
        highlightedPropertyKey = key
        highlightedPropertyIdentifier = identifier
    }

    /// Host action corresponding to Done / Create. Passing `nil` matches a
    /// cancelled new-contact flow.
    open func reportCompletion(contact: CNContact?) {
        if let contact {
            self.contact = contact
        }
        delegate?.contactViewController(self, didCompleteWith: contact)
    }

    /// Asks the delegate whether a property should run its default action
    /// (message, call, and similar). Default is `true` when no delegate is set.
    open func shouldPerformDefaultAction(for property: CNContactProperty) -> Bool {
        delegate?.contactViewController(self, shouldPerformDefaultActionFor: property) ?? true
    }

    private func applyModeDefaults() {
        switch mode {
        case .existing:
            allowsEditing = true
            allowsActions = true
        case .unknown:
            allowsEditing = false
            allowsActions = true
        case .new:
            allowsEditing = true
            allowsActions = false
        }
    }
}
