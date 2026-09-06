import Foundation

/// In-process discovery session. `report(_:)` appends events for host
/// observation and does not deliver them to an Apple DeviceDiscovery daemon,
/// extension host, or networked peer.
public class DDDiscoverySession: NSObject {
    private var events: [DDDeviceEvent] = []

    public override init() {
        super.init()
    }

    public func report(_ inEvent: DDDeviceEvent) {
        events.append(inEvent)
    }

    /// Host-only view of events retained by `report(_:)`. Not an Apple API.
    @_spi(OpenUIKitHost)
    public var reportedEvents: [DDDeviceEvent] {
        events
    }
}
