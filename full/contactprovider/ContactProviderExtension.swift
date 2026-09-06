import Foundation

/// The extension `@main` class implements this protocol.
///
/// Darwin inherits `ExtensionFoundation.AppExtension`. Isolated Linux
/// compilation uses the isolation stand-in. `configuration` is the shared
/// inert marker; there is no extension process to configure.
public protocol ContactProviderExtension: ContactItemEnumerating, AppExtension
where Configuration == ContactProviderExtensionConfiguration {
    /// Configures the extension instance for a domain.
    ///
    /// The system configures the extension for a domain before any enumeration
    /// begins. Linux stores nothing; conforming types may record the domain
    /// themselves.
    func configure(for domain: any ContactProviderDomain)

    /// Invalidates the extension.
    ///
    /// The system calls this method before terminating the extension. Linux
    /// has no extension process. The sealed runner cannot `await` this method.
    func invalidate() async throws
}

extension ContactProviderExtension {
    /// A shared implementation for your app extension configuration.
    ///
    /// Your extension should use this shared
    /// `ContactProviderExtension.configuration` implementation rather than
    /// providing its own. Linux returns an inert marker; it does not talk to
    /// `appex`.
    public var configuration: ContactProviderExtensionConfiguration {
        ContactProviderExtensionConfiguration()
    }
}
