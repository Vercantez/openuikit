import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Portable grouped-table section drawn by `CNContactViewController` on Linux.
/// Pixel-identical iOS 26.1 CNContactViewController chrome was not measured:
/// `uikit/scripts/conformance_flow.sh` is present but has no ContactsUI fixture
/// app and this host cannot run the iOS simulator capture side.
public struct ContactsUIContactSection: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case message
        case name
        case phone
        case email
        case address
    }

    public var kind: Kind
    public var title: String?
    public var rows: [ContactsUIContactRow]
}

public struct ContactsUIContactRow: Equatable, Sendable {
    public var label: String
    public var value: String
    public var propertyKey: String
    public var identifier: String?
    public var highlighted: Bool
}

/// Contact editor / viewer. Darwin subclasses `UIViewController`. Isolated
/// Linux subclasses the UIKit lookalike `UITableViewController` (.grouped) and
/// builds a documented section model (name header, phone / email / address
/// rows with labels). It does not load an Apple address book.
@MainActor
public class CNContactViewController: UITableViewController {
    public weak var delegate: (any CNContactViewControllerDelegate)?
    public var displayedPropertyKeys: [Any]?
    public var alternateName: String?
    public var message: String?
    public var allowsEditing: Bool = true
    public var allowsActions: Bool = true
    public var shouldShowLinkedContacts: Bool = false
    public var contactStore: CNContactStore?
    public var parentGroup: CNGroup?
    public var parentContainer: CNContainer?
    public private(set) var contact: CNContact

    var linuxHighlightedPropertyKey: String?
    var linuxHighlightedPropertyIdentifier: String?
    var linuxCompletedWithoutSaving: Bool = false
    var linuxSections: [ContactsUIContactSection] = []

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
        super.init(style: .grouped)
        self.allowsEditing = allowsEditing
        self.title = "Contact"
        _ = linuxRebuildSections()
    }

    @MainActor
    public func highlightProperty(withKey key: String, identifier: String?) {
        linuxHighlightedPropertyKey = key
        linuxHighlightedPropertyIdentifier = identifier
        _ = linuxRebuildSections()
    }

    @discardableResult
    func linuxRebuildSections() -> [ContactsUIContactSection] {
        var sections: [ContactsUIContactSection] = []
        let keys = displayedKeySet()

        if let message, !message.isEmpty {
            sections.append(
                ContactsUIContactSection(
                    kind: .message,
                    title: nil,
                    rows: [
                        ContactsUIContactRow(
                            label: "",
                            value: message,
                            propertyKey: "message",
                            identifier: nil,
                            highlighted: false
                        )
                    ]
                )
            )
        }

        let displayName = resolvedDisplayName()
        sections.append(
            ContactsUIContactSection(
                kind: .name,
                title: nil,
                rows: [
                    ContactsUIContactRow(
                        label: "name",
                        value: displayName,
                        propertyKey: CNContactGivenNameKey,
                        identifier: contact.identifier,
                        highlighted: linuxHighlightedPropertyKey == CNContactGivenNameKey
                    )
                ]
            )
        )

        if keys.contains(CNContactPhoneNumbersKey) {
            let rows = contact.phoneNumbers.map { labeled in
                ContactsUIContactRow(
                    label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: labeled.label ?? ""),
                    value: labeled.value.stringValue,
                    propertyKey: CNContactPhoneNumbersKey,
                    identifier: labeled.identifier,
                    highlighted: isHighlighted(
                        key: CNContactPhoneNumbersKey,
                        identifier: labeled.identifier
                    )
                )
            }
            if !rows.isEmpty || allowsEditing {
                sections.append(
                    ContactsUIContactSection(kind: .phone, title: "Phone", rows: rows)
                )
            }
        }

        if keys.contains(CNContactEmailAddressesKey) {
            let rows = contact.emailAddresses.map { labeled in
                ContactsUIContactRow(
                    label: CNLabeledValue<NSString>.localizedString(forLabel: labeled.label ?? ""),
                    value: labeled.value as String,
                    propertyKey: CNContactEmailAddressesKey,
                    identifier: labeled.identifier,
                    highlighted: isHighlighted(
                        key: CNContactEmailAddressesKey,
                        identifier: labeled.identifier
                    )
                )
            }
            if !rows.isEmpty || allowsEditing {
                sections.append(
                    ContactsUIContactSection(kind: .email, title: "Email", rows: rows)
                )
            }
        }

        if keys.contains(CNContactPostalAddressesKey) {
            let rows = contact.postalAddresses.map { labeled in
                ContactsUIContactRow(
                    label: CNLabeledValue<CNPostalAddress>.localizedString(forLabel: labeled.label ?? ""),
                    value: formattedAddress(labeled.value),
                    propertyKey: CNContactPostalAddressesKey,
                    identifier: labeled.identifier,
                    highlighted: isHighlighted(
                        key: CNContactPostalAddressesKey,
                        identifier: labeled.identifier
                    )
                )
            }
            if !rows.isEmpty || allowsEditing {
                sections.append(
                    ContactsUIContactSection(kind: .address, title: "Address", rows: rows)
                )
            }
        }

        linuxSections = sections
        return sections
    }

    private func displayedKeySet() -> Set<String> {
        guard let displayedPropertyKeys, !displayedPropertyKeys.isEmpty else {
            return [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey,
                CNContactPostalAddressesKey,
            ]
        }
        return Set(displayedPropertyKeys.compactMap { $0 as? String })
    }

    private func resolvedDisplayName() -> String {
        if let alternateName, !alternateName.isEmpty {
            return alternateName
        }
        let joined = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !joined.isEmpty {
            return joined
        }
        if !contact.organizationName.isEmpty {
            return contact.organizationName
        }
        return "No Name"
    }

    private func isHighlighted(key: String, identifier: String) -> Bool {
        guard linuxHighlightedPropertyKey == key else { return false }
        if let wanted = linuxHighlightedPropertyIdentifier {
            return wanted == identifier
        }
        return true
    }

    private func formattedAddress(_ address: CNPostalAddress) -> String {
        [address.street, address.city, address.state, address.postalCode, address.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

@MainActor
public protocol CNContactViewControllerDelegate: NSObjectProtocol {
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
}
