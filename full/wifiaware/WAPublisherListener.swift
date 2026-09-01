import Foundation

#if canImport(Network)
import Network
#endif

/// Configures a Network listener to publish a Wi-Fi Aware service.
///
/// Building a listener configuration is local and deterministic. Actually
/// publishing requires Apple's `ListenerProvider` / `NetworkListener` path,
/// which Linux Network does not provide. ``wifiAware(_:active:)`` therefore
/// returns a value; it does not start a radio or advertise a service.
public struct WAPublisherListener: Sendable {
    public struct Action: Sendable {
        let service: WAPublishableService
        let devices: Devices
        let datapath: DatapathParameters?

        public static func connecting(
            to myPublishingService: WAPublishableService,
            from pairedDevices: Devices,
            datapath wifiAware: DatapathParameters? = nil
        ) -> Action {
            Action(service: myPublishingService, devices: pairedDevices, datapath: wifiAware)
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

    public struct DatapathParameters: Sendable {
        public static let defaults = DatapathParameters(performanceMode: .bulk)
        public static let realtime = DatapathParameters(performanceMode: .realtime)

        let performanceMode: WAPerformanceMode
    }

    let action: Action
    let requestedDuration: Duration?

    public static func wifiAware(
        _ action: Action,
        active requestedDuration: Duration? = nil
    ) -> WAPublisherListener {
        WAPublisherListener(action: action, requestedDuration: requestedDuration)
    }

    /// Application-declared publishable services are the only service kind this
    /// starting point can name. Accessory-only publishers are an oracle question.
    public var isApplicationService: Bool { true }

#if canImport(Network)
    public var service: NWListener.Service {
        get {
            // Linux Network has no NWListener.Service. This branch exists so a
            // later Network module that grows the nested type can compile the
            // Apple signature; the isolated gate does not compile this path.
            fatalError("NWListener.Service is not available on this Network starting point")
        }
    }

    public func configureParameters(_ parameters: NWParameters) {
        parameters.wifiAware = action.datapath.map {
            WAParameters(performanceMode: $0.performanceMode)
        } ?? .defaults
        parameters.includePeerToPeer = true
    }
#endif
}
