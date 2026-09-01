import Foundation

#if canImport(UIKit)
import UIKit
#endif

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

/// Host-driven contact picker. It stores displayed keys and predicates, then
/// forwards explicit host selections. It never enumerates a system address book.
@MainActor
open class CNContactPickerViewController: ContactsUIPresenter {
    public weak var delegate: (any CNContactPickerDelegate)?
    public var displayedPropertyKeys: [String]?
    public var predicateForEnablingContact: NSPredicate?
    public var predicateForSelectionOfContact: NSPredicate?
    public var predicateForSelectionOfProperty: NSPredicate?

    public private(set) var isPresented = false

#if canImport(UIKit)
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }
#else
    public override init() {
        super.init()
    }
#endif

    public func isContactEnabled(_ contact: CNContact) -> Bool {
        predicateForEnablingContact?.evaluate(with: contact) ?? true
    }

    public func isContactSelectable(_ contact: CNContact) -> Bool {
        guard isContactEnabled(contact) else { return false }
        return predicateForSelectionOfContact?.evaluate(with: contact) ?? true
    }

    public func isPropertySelectable(_ property: CNContactProperty) -> Bool {
        guard isContactSelectable(property.contact) else { return false }
        return predicateForSelectionOfProperty?.evaluate(with: property) ?? true
    }

    /// Host action corresponding to showing the picker UI.
    open func presentPicker() {
        isPresented = true
    }

    /// Host action corresponding to the Cancel control.
    @discardableResult
    open func reportCancel() -> Bool {
        isPresented = false
        delegate?.contactPickerDidCancel(self)
        return true
    }

    /// Host action corresponding to selecting a single contact.
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

    /// Host action corresponding to selecting multiple contacts.
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

    /// Host action corresponding to selecting one labeled property.
    @discardableResult
    open func reportSelection(contactProperty: CNContactProperty) -> ContactsUIPortableError? {
        guard isPropertySelectable(contactProperty) else {
            return ContactsUIPortableError(.propertyNotSelectableByPredicate)
        }
        isPresented = false
        delegate?.contactPicker(self, didSelect: contactProperty)
        return nil
    }

    /// Host action corresponding to selecting several labeled properties.
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
