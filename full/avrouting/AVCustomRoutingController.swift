import Foundation

/// Delegate for custom-route activation events and picker actions.
///
/// Apple graph: `NSObjectProtocol & Sendable`. `handle` is required
/// (`requirementOf`); `eventDidTimeOut` and `didSelect` are optional.
/// The compact surface selected the async Swift spelling of `handle`;
/// the raw graph also records the ObjC completion-handler form under
/// the same precise identifier. Linux requires the completion-handler
/// form so tests can invoke it synchronously. The async spelling is a
/// defaulted overlay that calls the completion-handler. The controller
/// itself never invokes the delegate: there is no routing daemon.
public protocol AVCustomRoutingControllerDelegate: NSObjectProtocol, Sendable {
    func customRoutingController(
        _ controller: AVCustomRoutingController,
        handle event: AVCustomRoutingEvent,
        completionHandler: @escaping (Bool) -> Void
    )

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        eventDidTimeOut event: AVCustomRoutingEvent
    )

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        didSelect customActionItem: AVCustomRoutingActionItem
    )
}

public extension AVCustomRoutingControllerDelegate {
    func customRoutingController(
        _ controller: AVCustomRoutingController,
        handle event: AVCustomRoutingEvent
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            self.customRoutingController(controller, handle: event) { success in
                continuation.resume(returning: success)
            }
        }
    }

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        eventDidTimeOut event: AVCustomRoutingEvent
    ) {}

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        didSelect customActionItem: AVCustomRoutingActionItem
    ) {}
}

/// Custom-route authorization and activation controller.
///
/// `knownRouteIPs` and `customActionItems` are process-local storage.
/// `authorizedRoutes` is always empty: Linux has no entitlement prompt
/// and no route-authorization daemon. `setActive(_:for:)` / `isRouteActive`
/// keep a process-local active set by object identity; that bookkeeping
/// does not route audio or talk to AirPlay.
///
/// The controller never posts `authorizedRoutesDidChange` and never
/// calls the delegate.
///
/// Apple graph: `open class AVCustomRoutingController: NSObject`, iOS 16+.
open class AVCustomRoutingController: NSObject {
    /// Posted on Darwin when authorized custom routes change.
    /// Linux never posts this name.
    public static let authorizedRoutesDidChange = NSNotification.Name(
        "AVCustomRoutingControllerAuthorizedRoutesDidChangeNotification"
    )

    public weak var delegate: (any AVCustomRoutingControllerDelegate)?

    /// Always empty on Linux. The routing daemon that vends authorized
    /// routes is not present.
    public var authorizedRoutes: [AVCustomDeviceRoute] {
        []
    }

    public var knownRouteIPs: [AVCustomRoutingPartialIP] = []

    public var customActionItems: [AVCustomRoutingActionItem] = []

    private var activeRouteIDs: Set<ObjectIdentifier> = []

    public override init() {
        super.init()
    }

    /// Revokes any process-local active flag for `route`. Does not
    /// contact an authorization service and does not change
    /// `authorizedRoutes` (already empty).
    public func invalidateAuthorization(for route: AVCustomDeviceRoute) {
        activeRouteIDs.remove(ObjectIdentifier(route))
    }

    /// Process-local active flag. Does not route media.
    public func setActive(_ active: Bool, for route: AVCustomDeviceRoute) {
        let identity = ObjectIdentifier(route)
        if active {
            activeRouteIDs.insert(identity)
        } else {
            activeRouteIDs.remove(identity)
        }
    }

    /// Returns whether `setActive(true, for:)` was recorded for this
    /// route identity. Always `false` after `invalidateAuthorization(for:)`
    /// and for routes that were never activated.
    public func isRouteActive(_ route: AVCustomDeviceRoute) -> Bool {
        activeRouteIDs.contains(ObjectIdentifier(route))
    }
}
