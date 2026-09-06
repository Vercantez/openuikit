import Foundation

// MARK: - Isolation stand-ins
//
// The isolated host gate compiles ContactProvider with Foundation only.
// `CNMutableContact` is Contacts-owned. `AppExtension` and
// `AppExtensionConfiguration` are ExtensionFoundation-owned. These stand-ins
// exist so ContactProvider-owned signatures type-check. They are not Linux
// ports of those modules and must be deleted when the real modules are on
// the link line.

#if canImport(Contacts)
import Contacts
#else
/// Contacts-owned mutable contact. Isolation stand-in only.
///
/// Linux stores the identifier and a few writable name fields so
/// `ContactItem.contact` can be constructed and hashed. This is not
/// `Contacts.CNMutableContact` and does not talk to a contact store.
open class CNMutableContact: NSObject, @unchecked Sendable {
    public var identifier: String
    public var givenName: String
    public var familyName: String
    public var organizationName: String

    public override init() {
        self.identifier = UUID().uuidString
        self.givenName = ""
        self.familyName = ""
        self.organizationName = ""
        super.init()
    }
}
#endif

#if canImport(ExtensionFoundation)
import ExtensionFoundation
#else
/// ExtensionFoundation-owned configuration protocol. Isolation stand-in only.
public protocol AppExtensionConfiguration {}

/// ExtensionFoundation-owned extension protocol. Isolation stand-in only.
public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}
#endif

/// Linux configuration marker returned by
/// `ContactProviderExtension.configuration`. Darwin vends an
/// `ExtensionFoundation.AppExtensionConfiguration`; Linux has no extension
/// host, so this type is inert.
public struct ContactProviderExtensionConfiguration: AppExtensionConfiguration, Sendable {
    public init() {}
}
