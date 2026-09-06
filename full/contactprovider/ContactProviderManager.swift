import Foundation

/// An interface for the app to control its extension.
///
/// Linux vends a process-local handle so `domain` and `isEnabled` are
/// observable. There is no Contact Provider extension host, `contactsd`, or
/// Settings prompt. `isEnabled` is always `false`. Every method that would
/// talk to Apple services throws ``ContactProviderError/featureNotAvailable``.
///
/// Apple's documentation says `init` throws `featureNotAvailable` on an
/// unsupported platform. Linux still constructs the local handle so callers
/// can inspect domain state; the throw is reserved for unknown identifiers
/// (`domainNotRegistered`) and for every IPC operation. See
/// `oracle-questions.tsv`.
public final class ContactProviderManager: @unchecked Sendable {
    private let storedDomain: any ContactProviderDomain

    /// Creates a provider manager.
    ///
    /// - Parameter domainIdentifier: A string to identify a domain of contacts
    ///   to provide. Defaults to ``DefaultContactProviderDomain/identifier``.
    /// - Throws: ``ContactProviderError/domainNotRegistered`` when the
    ///   identifier is not the default domain. Linux has no extension catalog
    ///   that could register additional domains.
    public init(domainIdentifier: String = DefaultContactProviderDomain.identifier) throws {
        guard domainIdentifier == DefaultContactProviderDomain.identifier else {
            throw ContactProviderError.domainNotRegistered
        }
        self.storedDomain = DefaultContactProviderDomain()
    }

    /// The domain that this instance manages.
    ///
    /// This value defaults to ``DefaultContactProviderDomain``.
    public var domain: any ContactProviderDomain { storedDomain }

    /// A Boolean value that indicates whether the person using the app enabled
    /// the extension domain.
    ///
    /// Linux has no Settings pane or enablement daemon, so this is always
    /// `false`.
    public var isEnabled: Bool { false }

    /// Requests the person using the app to enable the extension domain.
    ///
    /// Linux has no enablement UI. Always throws
    /// ``ContactProviderError/featureNotAvailable``.
    public func enable() async throws {
        throw ContactProviderError.featureNotAvailable
    }

    /// Disables the extension domain.
    ///
    /// Linux has no previously-provided contacts to delete. Always throws
    /// ``ContactProviderError/featureNotAvailable``.
    public func disable() async throws {
        throw ContactProviderError.featureNotAvailable
    }

    /// Requests that the extension enumerate its contacts for the domain.
    ///
    /// Linux has no extension process to signal. Always throws
    /// ``ContactProviderError/featureNotAvailable``.
    public func signalEnumerator(
        for collection: ContactItem.Identifier = .rootContainer
    ) async throws {
        _ = collection
        throw ContactProviderError.featureNotAvailable
    }

    /// Requests that the extension terminate.
    ///
    /// Linux has no loaded extension. Always throws
    /// ``ContactProviderError/featureNotAvailable``.
    public func invalidate() async throws {
        throw ContactProviderError.featureNotAvailable
    }

    /// Resets the extension domain.
    ///
    /// Linux has no Contacts database cache to drop. Always throws
    /// ``ContactProviderError/featureNotAvailable``.
    public func reset() async throws {
        throw ContactProviderError.featureNotAvailable
    }
}
