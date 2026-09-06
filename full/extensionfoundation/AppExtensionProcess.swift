import Foundation

/// A type the host app creates to launch and manage an app extension.
///
/// Linux never launches an appex. The public throwing initializer always
/// fails closed. `makeXPCConnection()` / `makeXPCSession()` throw. `invalidate()`
/// is a process-local no-op on an unlaunched handle.
public struct AppExtensionProcess {
    /// A structure that holds the identity of an app extension and process-related details.
    public struct Configuration {
        /// The identifying information for the app extension you want to launch.
        public var appExtensionIdentity: AppExtensionIdentity
        /// The closure to run if the app extension’s process exits unexpectedly.
        public var onInterruption: () -> Void

        public init(
            appExtensionIdentity: AppExtensionIdentity,
            onInterruption: @escaping () -> Void = {}
        ) {
            self.appExtensionIdentity = appExtensionIdentity
            self.onInterruption = onInterruption
        }
    }

    private final class Storage: @unchecked Sendable {
        let configuration: Configuration
        var invalidated: Bool

        init(configuration: Configuration) {
            self.configuration = configuration
            self.invalidated = false
        }
    }

    private let storage: Storage

    /// Finds or creates an extension process. Linux always throws.
    public init(configuration: Configuration) throws {
        self.storage = Storage(configuration: configuration)
        throw ExtensionFoundationHostError.processUnavailable
    }

    /// Asynchronous process construction. Linux always throws.
    public init(configuration: Configuration) async throws {
        self.storage = Storage(configuration: configuration)
        throw ExtensionFoundationHostError.processUnavailable
    }

    @_spi(OpenUIKitHost)
    public init(hostUnlaunched configuration: Configuration) {
        self.storage = Storage(configuration: configuration)
    }

    /// Connect using Foundation XPC. Linux always throws.
    public func makeXPCConnection() throws -> NSXPCConnection {
        throw ExtensionFoundationHostError.xpcUnavailable
    }

    /// Connect using an XPC session. Linux always throws.
    public func makeXPCSession() throws -> XPCSession {
        throw ExtensionFoundationHostError.xpcUnavailable
    }

    /// Invalidates a host connection. On an unlaunched Linux handle this is a
    /// no-op and never claims an Apple process exited.
    public func invalidate() {
        storage.invalidated = true
    }

    @_spi(OpenUIKitHost)
    public var host_isInvalidated: Bool { storage.invalidated }

    @_spi(OpenUIKitHost)
    public var host_configuration: Configuration { storage.configuration }
}
