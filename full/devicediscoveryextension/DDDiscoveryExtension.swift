import Foundation

/// Configuration protocol for a device-discovery app extension. Inherits the
/// isolated-host `AppExtensionConfiguration` (real ExtensionFoundation when
/// that module is on the link line).
public protocol DDDiscoveryExtensionConfigurationProtocol: AppExtensionConfiguration {}

/// Device-discovery app-extension protocol. `startDiscovery` / `stopDiscovery`
/// are required. `didReceiveEvent` has a no-op default. The default
/// `configuration` wraps `self` in `DDDiscoveryExtensionConfiguration`.
///
/// Linux implementors must not invent nearby devices: scan, Bluetooth, DIAL,
/// and Wi-Fi Aware require Apple daemons and entitlements that are absent.
public protocol DDDiscoveryExtension: AppExtension {
    func startDiscovery(session: DDDiscoverySession)
    func stopDiscovery(session: DDDiscoverySession)
    func didReceiveEvent(_ event: DDDeviceEvent)
}

extension DDDiscoveryExtension {
    public func didReceiveEvent(_ event: DDDeviceEvent) {
        _ = event
    }

    public var configuration: DDDiscoveryExtensionConfiguration<Self> {
        DDDiscoveryExtensionConfiguration(discoveryExtension: self)
    }
}

/// Wraps a `DDDiscoveryExtension` for the extension-host configuration
/// handshake. Darwin annotates the type `@MainActor @preconcurrency`; Linux
/// drops MainActor because the sealed runner has no run loop. `accept` is
/// fail-closed (`false`): there is no NSXPC extension host on this platform.
public final class DDDiscoveryExtensionConfiguration<T: DDDiscoveryExtension>:
    DDDiscoveryExtensionConfigurationProtocol
{
    public let discoveryExtension: T

    public init(discoveryExtension: T) {
        self.discoveryExtension = discoveryExtension
    }

    public func accept(connection inCnx: NSXPCConnection) -> Bool {
        _ = inCnx
        return false
    }
}
