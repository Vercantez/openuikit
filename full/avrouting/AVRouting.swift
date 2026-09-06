@_exported import Foundation

/// Linux starting point for Apple's public `AVRouting` module.
///
/// Reconstructed from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph
/// (38 exact public identifiers). Isolated host-gate success is not
/// AirPlay / Bluetooth route discovery, not a route-picker UI, and not
/// playback arbitration against a Darwin media daemon.
///
/// Value types, `NSNotification.Name` identity, `AVCustomRoutingPartialIP`
/// storage, process-local active-route bookkeeping, and notification-name
/// constants are real. Hardware endpoints, authorized-route vending,
/// delegate callbacks from a routing controller, and external-playback
/// arbitration stay fail-closed and inert.
///
/// UniformTypeIdentifiers and Network are not declared dependencies of
/// this seed. Isolated-host overlays for `UTType` and `nw_endpoint_t`
/// compile out when those modules are importable. They are not public
/// substitutes for those modules.

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#else
/// Isolated-host stand-in for `UniformTypeIdentifiers.UTType`. Identifier
/// strings are caller-supplied. Not a UTI database. Compiled out when the
/// real module is on the link line.
public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}
#endif

#if canImport(Network)
import Network
#else
/// Isolated-host overlay for Darwin `nw_endpoint_t` (`OS_nw_endpoint`).
/// Network.framework is not a declared dependency. Compiled out when
/// `Network` is importable. Linux `AVCustomDeviceRoute.networkEndpoint`
/// is always `nil`.
public protocol OS_nw_endpoint: NSObjectProtocol, Sendable {}
public typealias nw_endpoint_t = any OS_nw_endpoint
#endif

// MARK: - AVCustomRoutingEventReason

/// Reason a custom-routing event was delivered.
///
/// Pinned `dotnet/macios` `src/avrouting.cs` records this as a Native
/// `long` with `Activate = 0`, then `Deactivate`, then `Reactivate`.
/// That sequential assignment matches the Apple graph child order.
public enum AVCustomRoutingEventReason: Int, Sendable, Equatable, Hashable {
    case activate = 0
    case deactivate = 1
    case reactivate = 2
}
