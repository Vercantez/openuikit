import Foundation

#if canImport(Network)
import Network
#endif

/// Configures a Network browser to subscribe to a Wi-Fi Aware service.
///
/// Like ``WAPublisherListener``, constructing a browser configuration does not
/// discover peers or open a datapath. Guest Network has no `NWBrowser`, so
/// `makeDescriptor()` and `makeEndpoint(from:)` stay deferred.
public struct WASubscriberBrowser: Sendable {
    public typealias Endpoint = WAEndpoint

    public struct Action: Sendable {
        let devices: Devices
        let service: WASubscribableService

        public static func connecting(
            to pairedDevices: Devices,
            from mySubscribingService: WASubscribableService
        ) -> Action {
            Action(devices: pairedDevices, service: mySubscribingService)
        }
    }

    public struct Devices: Sendable {
        enum Selection: Sendable {
            case allPaired
            case userSpecified
            case selected([WAPairedDevice])
            case matching(Predicate<WAPairedDevice>)
        }

        let selection: Selection

        public static let allPairedDevices = Devices(selection: .allPaired)
        public static let userSpecifiedDevices = Devices(selection: .userSpecified)

        public static func selected(_ pairedDevices: some Sequence<WAPairedDevice>) -> Devices {
            Devices(selection: .selected(Array(pairedDevices)))
        }

        public static func selected(_ pairedDevices: WAPairedDevice.Devices) -> Devices {
            Devices(selection: .selected(Array(pairedDevices.values)))
        }

        public static func matching(_ pairedDevicesFilter: Predicate<WAPairedDevice>) -> Devices {
            Devices(selection: .matching(pairedDevicesFilter))
        }
    }

    let action: Action
    let requestedDuration: Duration?

    public static func wifiAware(
        _ action: Action,
        active requestedDuration: Duration? = nil
    ) -> WASubscriberBrowser {
        WASubscriberBrowser(action: action, requestedDuration: requestedDuration)
    }

#if canImport(Network)
    public func configureParameters(_ parameters: NWParameters?) -> NWParameters {
        let resolved = parameters ?? .tcp
        resolved.wifiAware = .defaults
        resolved.includePeerToPeer = true
        return resolved
    }
#endif
}
