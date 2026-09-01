// Linux starting point for Apple's public ContactsUI module.
//
// Controllers preserve caller-supplied contact identity, predicates, and
// delegate wiring. Presentation is host-driven: a Linux shell can render its
// own picker or editor and call the report* methods. This module never reads a
// system address book, never grants Limited Contacts Access identifiers, and
// never claims that Apple's CNContactPicker or CNContactViewController UI ran.

@_exported import Foundation

#if canImport(Contacts)
@_exported import Contacts
#endif

#if canImport(UIKit)
@_exported import UIKit
public typealias ContactsUIPresenter = UIViewController
#else
public typealias ContactsUIPresenter = NSObject
#endif

public enum ContactsUIPortable {
    public enum PresentationCapability: Int, Sendable {
        case unavailable = 0
        case hostDriven = 1
    }

    /// Linux has no Apple contact picker sheet. Hosts drive selection.
    public static let contactPickerCapability = PresentationCapability.hostDriven

    /// Linux has no Apple contact card / editor sheet. Hosts drive editing.
    public static let contactViewCapability = PresentationCapability.hostDriven

    /// Apple's Limited Contacts Access button/picker is not available here.
    public static let limitedAccessUIAvailable = false

    /// This module does not bind a system CNContactStore.
    public static let systemContactStoreAvailable = false
}

public struct ContactsUIPortableError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
        case contactDisabledByPredicate = 1
        case contactNotSelectableByPredicate = 2
        case propertyNotSelectableByPredicate = 3
        case limitedAccessUIUnavailable = 4
        case systemContactStoreUnavailable = 5
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .contactDisabledByPredicate:
            description = "The contact is disabled by predicateForEnablingContact"
        case .contactNotSelectableByPredicate:
            description = "The contact is rejected by predicateForSelectionOfContact"
        case .propertyNotSelectableByPredicate:
            description = "The property is rejected by predicateForSelectionOfProperty"
        case .limitedAccessUIUnavailable:
            description = "Apple Limited Contacts Access UI is unavailable on this host"
        case .systemContactStoreUnavailable:
            description = "No Apple system contact store is available on this host"
        }
    }
}
