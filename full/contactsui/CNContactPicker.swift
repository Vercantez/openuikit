import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Contact picker. Darwin subclasses `UIViewController`. Isolated Linux uses
/// `NSObject` and never presents an address book. Selection callbacks that
/// require `CNContact` stay gated; cancel is deliverable through host SPI.
@MainActor
public class CNContactPickerViewController: NSObject {
    public weak var delegate: (any CNContactPickerDelegate)?
    public var displayedPropertyKeys: [String]?
    @NSCopying public var predicateForEnablingContact: NSPredicate?
    @NSCopying public var predicateForSelectionOfContact: NSPredicate?
    @NSCopying public var predicateForSelectionOfProperty: NSPredicate?

    public override init() {
        super.init()
    }
}

@MainActor
public protocol CNContactPickerDelegate: NSObjectProtocol {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController)

    #if canImport(Contacts)
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
    #endif
}

extension CNContactPickerDelegate {
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        _ = picker
    }

    #if canImport(Contacts)
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
    #endif
}
