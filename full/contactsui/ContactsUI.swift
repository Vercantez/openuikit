// Linux starting point for Apple's public ContactsUI module.
//
// Controllers and the Limited Access button are compiled only when their
// first-party dependencies are importable. This isolated host has Foundation
// alone, so those declarations are gated. Host-only presentation controls are
// SPI. The module never reads a system address book and never grants Apple
// Limited Contacts Access identifiers.

@_exported import Foundation

#if canImport(Contacts)
@_exported import Contacts
#endif

#if canImport(UIKit)
@_exported import UIKit
#endif

@_spi(OpenUIKitHost)
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

@_spi(OpenUIKitHost)
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
