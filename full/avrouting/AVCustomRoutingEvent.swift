import Foundation

/// An activation, deactivation, or reactivation request for a custom route.
///
/// Darwin vends events from `AVCustomRoutingController` to its delegate.
/// Linux has no routing daemon, so the controller never delivers events.
/// The Linux-only initializer exists so host tests can construct values
/// and exercise `reason` / `route` storage.
///
/// Apple graph: `open class AVCustomRoutingEvent: NSObject`, Sendable,
/// iOS 16+. Properties are get-only. No public designated initializer.
open class AVCustomRoutingEvent: NSObject, @unchecked Sendable {
    public let reason: AVCustomRoutingEventReason
    public let route: AVCustomDeviceRoute

    /// Linux-only construction. Darwin events are created by the routing
    /// controller, not by this initializer.
    public init(reason: AVCustomRoutingEventReason, route: AVCustomDeviceRoute) {
        self.reason = reason
        self.route = route
        super.init()
    }
}
