import Foundation

/// Context a Live Caller ID lookup extension uses to talk to its PIR
/// service. This is a local value type: constructing it does not contact
/// Apple or a carrier.
public struct LiveCallerIDLookupExtensionContext: Hashable, Codable, Sendable {
    public let serviceURL: URL
    public let tokenIssuerURL: URL
    public let userTierToken: Data

    public init(serviceURL: URL, tokenIssuerURL: URL, userTierToken: Data) {
        self.serviceURL = serviceURL
        self.tokenIssuerURL = tokenIssuerURL
        self.userTierToken = userTierToken
    }
}

/// Configuration marker for a Live Caller ID lookup extension.
///
/// Darwin inherits `ExtensionFoundation.AppExtensionConfiguration`. That module
/// is not a declared dependency of this port, so the protocol is a local
/// marker only.
public protocol LiveCallerIDLookupExtensionConfiguration {}

/// Live Caller ID lookup extension protocol.
///
/// Darwin inherits `ExtensionFoundation.AppExtension`. Isolated Linux
/// compilation does not import ExtensionFoundation, so this protocol only
/// requires the documented `context` property.
public protocol LiveCallerIDLookupProtocol {
    var context: LiveCallerIDLookupExtensionContext { get }
}

extension LiveCallerIDLookupProtocol {
    /// Opaque Darwin configuration. Linux has no App Extension runtime, so
    /// this returns an inert marker value.
    public var configuration: some LiveCallerIDLookupExtensionConfiguration {
        LiveCallerIDLookupLinuxConfiguration()
    }
}

struct LiveCallerIDLookupLinuxConfiguration: LiveCallerIDLookupExtensionConfiguration {}

/// Process-local Live Caller ID manager. Linux never enables an extension,
/// never opens Settings, and never refreshes PIR parameters.
open class LiveCallerIDLookupManager {
    public static let shared = LiveCallerIDLookupManager()

    private init() {}

    /// Always `.disabled`: there is no Live Caller ID daemon on Linux.
    public func status(forExtensionWithIdentifier identifier: String) -> CallLookupExtensionStatus {
        _ = identifier
        return .disabled
    }

    public func openSettings() async throws {
        throw IdentityLookupLinux.filterError(.system)
    }

    public func reset(forExtensionWithIdentifier identifier: String) async throws {
        _ = identifier
        throw IdentityLookupLinux.filterError(.system)
    }

    public func refreshPIRParameters(forExtensionWithIdentifier identifier: String) async throws {
        _ = identifier
        throw IdentityLookupLinux.filterError(.system)
    }

    public func refreshExtensionContext(forExtensionWithIdentifier identifier: String) async throws {
        _ = identifier
        throw IdentityLookupLinux.filterError(.system)
    }
}

/// Core Data / Foundation typealiases that Apple's overlay exposes for the
/// Live Lookup store. `NSSet` is Foundation-owned. `NSManagedObject` is
/// CoreData-owned and is not redeclared here.
public typealias LiveLookupStoreFoundationFrameworkSet = NSSet
public typealias LiveLookupDBExtensionCoreDataPropertiesSet = NSSet
public typealias IdentityInfoCoreDataPropertiesSet = NSSet
public typealias BlockingInfoCoreDataPropertiesSet = NSSet
