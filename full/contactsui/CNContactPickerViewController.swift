#if canImport(Contacts) && canImport(UIKit)
import Contacts
import UIKit

@MainActor
public protocol CNContactPickerDelegate: AnyObject {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact)
    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelectContactProperties contactProperties: [CNContactProperty]
    )
    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contactProperty: CNContactProperty
    )
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact])
    func contactPickerDidCancel(_ picker: CNContactPickerViewController)
}

extension CNContactPickerDelegate {
    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contact: CNContact
    ) {}

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelectContactProperties contactProperties: [CNContactProperty]
    ) {}

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contactProperty: CNContactProperty
    ) {}

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contacts: [CNContact]
    ) {}

    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
}

/// Host-driven contact picker using real UIKit and Contacts types.
/// It stores displayed keys and predicates. It never enumerates a system
/// address book; selection is an SPI host action.
@MainActor
open class CNContactPickerViewController: UIViewController {
    public weak var delegate: (any CNContactPickerDelegate)?
    public var displayedPropertyKeys: [String]?
    public var predicateForEnablingContact: NSPredicate?
    public var predicateForSelectionOfContact: NSPredicate?
    public var predicateForSelectionOfProperty: NSPredicate?

    @_spi(OpenUIKitHost)
    public private(set) var isPresented = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }

    @_spi(OpenUIKitHost)
    public func isContactEnabled(_ contact: CNContact) -> Bool {
        predicateForEnablingContact?.evaluate(with: contact) ?? true
    }

    @_spi(OpenUIKitHost)
    public func isContactSelectable(_ contact: CNContact) -> Bool {
        guard isContactEnabled(contact) else { return false }
        return predicateForSelectionOfContact?.evaluate(with: contact) ?? true
    }

    @_spi(OpenUIKitHost)
    public func isPropertySelectable(_ property: CNContactProperty) -> Bool {
        guard isContactSelectable(property.contact) else { return false }
        return predicateForSelectionOfProperty?.evaluate(with: property) ?? true
    }

    @_spi(OpenUIKitHost)
    open func presentPicker() {
        isPresented = true
    }

    @_spi(OpenUIKitHost)
    @discardableResult
    open func reportCancel() -> Bool {
        isPresented = false
        delegate?.contactPickerDidCancel(self)
        return true
    }

    @_spi(OpenUIKitHost)
    @discardableResult
    open func reportSelection(contact: CNContact) -> ContactsUIPortableError? {
        guard isContactEnabled(contact) else {
            return ContactsUIPortableError(.contactDisabledByPredicate)
        }
        guard isContactSelectable(contact) else {
            return ContactsUIPortableError(.contactNotSelectableByPredicate)
        }
        isPresented = false
        delegate?.contactPicker(self, didSelect: contact)
        return nil
    }

    @_spi(OpenUIKitHost)
    @discardableResult
    open func reportSelection(contacts: [CNContact]) -> ContactsUIPortableError? {
        for contact in contacts {
            guard isContactEnabled(contact) else {
                return ContactsUIPortableError(.contactDisabledByPredicate)
            }
            guard isContactSelectable(contact) else {
                return ContactsUIPortableError(.contactNotSelectableByPredicate)
            }
        }
        isPresented = false
        delegate?.contactPicker(self, didSelect: contacts)
        return nil
    }

    @_spi(OpenUIKitHost)
    @discardableResult
    open func reportSelection(contactProperty: CNContactProperty) -> ContactsUIPortableError? {
        guard isPropertySelectable(contactProperty) else {
            return ContactsUIPortableError(.propertyNotSelectableByPredicate)
        }
        isPresented = false
        delegate?.contactPicker(self, didSelect: contactProperty)
        return nil
    }

    @_spi(OpenUIKitHost)
    @discardableResult
    open func reportSelection(
        contactProperties: [CNContactProperty]
    ) -> ContactsUIPortableError? {
        for property in contactProperties {
            guard isPropertySelectable(property) else {
                return ContactsUIPortableError(.propertyNotSelectableByPredicate)
            }
        }
        isPresented = false
        delegate?.contactPicker(self, didSelectContactProperties: contactProperties)
        return nil
    }
}
#endif
