import Foundation

// MARK: - Isolation stand-ins
//
// The isolated Linux gate compiles ContactProvider with Foundation only.
// `CNMutableContact` is Contacts-owned. `AppExtension` and
// `AppExtensionConfiguration` are ExtensionFoundation-owned. These stand-ins
// exist so ContactProvider-owned signatures type-check. They are not Linux
// ports of those modules.
//
// The real modules bind only on device SDK builds (`os(iOS)` with the
// module importable). `canImport` alone is insufficient: macOS can see
// Contacts and ExtensionFoundation, but the macOS ExtensionFoundation
// `AppExtension` carries `@MainActor init()` / `@MainActor configuration`
// requirements (and a 26.0-gated `accept(connection:)` configuration
// protocol) that the portable Linux surface does not vouch for, so the
// macOS host gate type-checks against these stand-ins. This mirrors the
// `os(iOS) || os(Linux)` gating precedent in NetworkExtension. The clean
// Linux EC2 build never sees the real modules and always uses stand-ins.

#if (os(iOS) || os(Linux)) && canImport(Contacts)
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

#if (os(iOS) || os(Linux)) && canImport(ExtensionFoundation)
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
