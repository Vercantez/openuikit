import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Contact picker. Darwin subclasses `UIViewController`. Isolated Linux uses
/// the UIKit lookalike and never presents an address book. Selection callbacks
/// are delivered only through documented host SPI after predicate evaluation.
@MainActor
public class CNContactPickerViewController: UIViewController {
    public weak var delegate: (any CNContactPickerDelegate)?
    public var displayedPropertyKeys: [String]?
    @NSCopying public var predicateForEnablingContact: NSPredicate?
    @NSCopying public var predicateForSelectionOfContact: NSPredicate?
    @NSCopying public var predicateForSelectionOfProperty: NSPredicate?

    public override init() {
        super.init()
        self.title = "Contacts"
    }

    func hostSelect(contact: CNContact) -> Bool {
        guard ContactsUIPredicateEvaluation.evaluate(predicateForEnablingContact, contact: contact) else {
            return false
        }
        guard ContactsUIPredicateEvaluation.evaluate(predicateForSelectionOfContact, contact: contact) else {
            return false
        }
        delegate?.contactPicker(self, didSelect: contact)
        return true
    }

    func hostSelect(contacts: [CNContact]) -> Bool {
        var accepted: [CNContact] = []
        for contact in contacts {
            guard ContactsUIPredicateEvaluation.evaluate(predicateForEnablingContact, contact: contact) else {
                continue
            }
            guard ContactsUIPredicateEvaluation.evaluate(predicateForSelectionOfContact, contact: contact) else {
                continue
            }
            accepted.append(contact)
        }
        guard !accepted.isEmpty else { return false }
        delegate?.contactPicker(self, didSelect: accepted)
        return true
    }

    func hostSelect(property: CNContactProperty) -> Bool {
        guard ContactsUIPredicateEvaluation.evaluate(
            predicateForEnablingContact,
            contact: property.contact
        ) else {
            return false
        }
        if let keys = displayedPropertyKeys, !keys.contains(property.key) {
            return false
        }
        guard ContactsUIPredicateEvaluation.evaluate(
            predicateForSelectionOfProperty,
            property: property
        ) else {
            return false
        }
        delegate?.contactPicker(self, didSelect: property)
        return true
    }

    func hostSelect(properties: [CNContactProperty]) -> Bool {
        var accepted: [CNContactProperty] = []
        for property in properties {
            guard ContactsUIPredicateEvaluation.evaluate(
                predicateForEnablingContact,
                contact: property.contact
            ) else {
                continue
            }
            if let keys = displayedPropertyKeys, !keys.contains(property.key) {
                continue
            }
            guard ContactsUIPredicateEvaluation.evaluate(
                predicateForSelectionOfProperty,
                property: property
            ) else {
                continue
            }
            accepted.append(property)
        }
        guard !accepted.isEmpty else { return false }
        delegate?.contactPicker(self, didSelectContactProperties: accepted)
        return true
    }
}

@MainActor
public protocol CNContactPickerDelegate: NSObjectProtocol {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController)
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
}

extension CNContactPickerDelegate {
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        _ = picker
    }

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contact: CNContact
    ) {
        _ = picker
        _ = contact
    }

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelectContactProperties contactProperties: [CNContactProperty]
    ) {
        _ = picker
        _ = contactProperties
    }

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contactProperty: CNContactProperty
    ) {
        _ = picker
        _ = contactProperty
    }

    public func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contacts: [CNContact]
    ) {
        _ = picker
        _ = contacts
    }
}
