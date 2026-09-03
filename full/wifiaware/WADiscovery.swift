import Foundation

/// Endpoint of a Wi-Fi Aware connection. System-produced on Apple; Linux
/// instances exist only through host SPI (not public construction).
public struct WAEndpoint: Sendable, Hashable, CustomStringConvertible {
    public let device: WAPairedDevice

    public var publishedService: WAPublishableService? {
        _publishedService
    }

    public var subscribedService: WASubscribableService? {
        _subscribedService
    }

    public var description: String {
        "WAEndpoint(device: \(device.description))"
    }

    private let _publishedService: WAPublishableService?
    private let _subscribedService: WASubscribableService?

    @_spi(OpenUIKitHost)
    public init(
        device: WAPairedDevice,
        publishedService: WAPublishableService? = nil,
        subscribedService: WASubscribableService? = nil
    ) {
        self.device = device
        _publishedService = publishedService
        _subscribedService = subscribedService
    }
}

/// Current Wi-Fi Aware path. System-produced on Apple.
public struct WAPath: Sendable {
    public let endpoint: WAEndpoint
    public let performance: WAPerformanceReport
    public let durationActive: Duration

    @_spi(OpenUIKitHost)
    public init(
        endpoint: WAEndpoint,
        performance: WAPerformanceReport,
        durationActive: Duration
    ) {
        self.endpoint = endpoint
        self.performance = performance
        self.durationActive = durationActive
    }
}

/// Current performance state of a datapath.
public struct WAPerformanceReport: Sendable, Codable {
    public let timestamp: Date
    public let localTimestamp: ContinuousClock.Instant
    public let throughputCeiling: Double?
    public let throughputCapacity: Double?
    public let transmitLatency: [WAAccessCategory: TransmitLatencyMetrics]
    public let signalStrength: Double?

    public var throughputCapacityRatio: Double? {
        guard let throughputCapacity, let throughputCeiling, throughputCeiling != 0 else {
            return nil
        }
        return throughputCapacity / throughputCeiling
    }

    @_spi(OpenUIKitHost)
    public init(
        timestamp: Date,
        localTimestamp: ContinuousClock.Instant,
        throughputCeiling: Double?,
        throughputCapacity: Double?,
        transmitLatency: [WAAccessCategory: TransmitLatencyMetrics],
        signalStrength: Double?
    ) {
        self.timestamp = timestamp
        self.localTimestamp = localTimestamp
        self.throughputCeiling = throughputCeiling
        self.throughputCapacity = throughputCapacity
        self.transmitLatency = transmitLatency
        self.signalStrength = signalStrength
    }

    public struct TransmitLatencyMetrics: Sendable, Codable {
        public let accessCategory: WAAccessCategory
        public let average: Duration?

        @_spi(OpenUIKitHost)
        public init(accessCategory: WAAccessCategory, average: Duration?) {
            self.accessCategory = accessCategory
            self.average = average
        }
    }
}

/// Configures a network listener to publish a service over Wi-Fi Aware.
///
/// `ListenerProvider` / `NWListener` members are omitted: this isolated
/// compile has no `Network` module. Construction of the listener itself is
/// host SPI; `Action` and `Devices` are public.
public struct WAPublisherListener: Sendable {
    let action: Action

    /// Linux never publishes. Always `false`.
    public var isApplicationService: Bool { false }

    @_spi(OpenUIKitHost)
    public init(hostAction: Action) {
        action = hostAction
    }

    public struct Action: Sendable {
        let service: WAPublishableService
        let devices: Devices
        let datapath: DatapathParameters?

        public static func connecting(
            to myPublishingService: WAPublishableService,
            from pairedDevices: Devices,
            datapath wifiAware: DatapathParameters? = nil
        ) -> Action {
            Action(
                service: myPublishingService,
                devices: pairedDevices,
                datapath: wifiAware
            )
        }

        @_spi(OpenUIKitHost)
        public var hostService: WAPublishableService { service }

        @_spi(OpenUIKitHost)
        public var hostDevices: Devices { devices }

        @_spi(OpenUIKitHost)
        public var hostDatapath: DatapathParameters? { datapath }
    }

    public struct Devices: Sendable {
        enum Selection: Sendable {
            case allPaired
            case userSpecified
            case selected(WAPairedDevice.Devices)
            case matching(Predicate<WAPairedDevice>)
        }

        let selection: Selection

        public static let allPairedDevices = Devices(selection: .allPaired)
        public static let userSpecifiedDevices = Devices(selection: .userSpecified)

        public static func selected(
            _ pairedDevices: some Sequence<WAPairedDevice>
        ) -> Devices {
            var snapshot: WAPairedDevice.Devices = [:]
            for device in pairedDevices {
                snapshot[device.id] = device
            }
            return Devices(selection: .selected(snapshot))
        }

        public static func selected(_ pairedDevices: WAPairedDevice.Devices) -> Devices {
            Devices(selection: .selected(pairedDevices))
        }

        public static func matching(
            _ pairedDevicesFilter: Predicate<WAPairedDevice>
        ) -> Devices {
            Devices(selection: .matching(pairedDevicesFilter))
        }

        @_spi(OpenUIKitHost)
        public var hostKind: String {
            switch selection {
            case .allPaired: return "allPaired"
            case .userSpecified: return "userSpecified"
            case .selected: return "selected"
            case .matching: return "matching"
            }
        }

        @_spi(OpenUIKitHost)
        public var hostSelectedCount: Int {
            if case .selected(let snapshot) = selection {
                return snapshot.count
            }
            return 0
        }
    }

    public struct DatapathParameters: Sendable {
        let performanceMode: WAPerformanceMode

        public static let defaults = DatapathParameters(performanceMode: .bulk)
        public static let realtime = DatapathParameters(performanceMode: .realtime)

        @_spi(OpenUIKitHost)
        public var hostPerformanceMode: WAPerformanceMode { performanceMode }
    }
}

/// Configures a network browser to subscribe to a Wi-Fi Aware service.
///
/// `BrowserProvider` / `NWBrowser` members are omitted: this isolated compile
/// has no `Network` module.
public struct WASubscriberBrowser: Sendable {
    public typealias Endpoint = WAEndpoint

    let action: Action

    @_spi(OpenUIKitHost)
    public init(hostAction: Action) {
        action = hostAction
    }

    public struct Action: Sendable {
        let devices: Devices
        let service: WASubscribableService

        public static func connecting(
            to pairedDevices: Devices,
            from mySubscribingService: WASubscribableService
        ) -> Action {
            Action(devices: pairedDevices, service: mySubscribingService)
        }

        @_spi(OpenUIKitHost)
        public var hostService: WASubscribableService { service }

        @_spi(OpenUIKitHost)
        public var hostDevices: Devices { devices }
    }

    public struct Devices: Sendable {
        enum Selection: Sendable {
            case allPaired
            case userSpecified
            case selected(WAPairedDevice.Devices)
            case matching(Predicate<WAPairedDevice>)
        }

        let selection: Selection

        public static let allPairedDevices = Devices(selection: .allPaired)
        public static let userSpecifiedDevices = Devices(selection: .userSpecified)

        public static func selected(
            _ pairedDevices: some Sequence<WAPairedDevice>
        ) -> Devices {
            var snapshot: WAPairedDevice.Devices = [:]
            for device in pairedDevices {
                snapshot[device.id] = device
            }
            return Devices(selection: .selected(snapshot))
        }

        public static func selected(_ pairedDevices: WAPairedDevice.Devices) -> Devices {
            Devices(selection: .selected(pairedDevices))
        }

        public static func matching(
            _ pairedDevicesFilter: Predicate<WAPairedDevice>
        ) -> Devices {
            Devices(selection: .matching(pairedDevicesFilter))
        }

        @_spi(OpenUIKitHost)
        public var hostKind: String {
            switch selection {
            case .allPaired: return "allPaired"
            case .userSpecified: return "userSpecified"
            case .selected: return "selected"
            case .matching: return "matching"
            }
        }

        @_spi(OpenUIKitHost)
        public var hostSelectedCount: Int {
            if case .selected(let snapshot) = selection {
                return snapshot.count
            }
            return 0
        }
    }
}
