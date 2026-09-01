import Foundation

/// A request that adds and sets up a device into an ecosystem.
///
/// Linux has no Apple Matter commissioning UI, Home picker, or setup-payload
/// entitlement. `isSupported` is therefore `false`, and `perform()` always
/// throws `MatterSupportError`. Value types still construct, compare, hash,
/// and round-trip through a local `Codable` representation.
@available(iOS 16.1, macOS 14.0, *)
public struct MatterAddDeviceRequest: Hashable, @unchecked Sendable {
    /// A configuration object representing the topology of the initiating ecosystem.
    public var topology: Topology

    /// Optional Matter setup payload. Stored only; never interpreted.
    public var setupPayload: MTRSetupPayload?

    /// A predicate that filters what devices appear in the picker.
    public var showDeviceCriteria: DeviceCriteria

    /// Whether the Apple flow would request accessory network scans.
    public var shouldScanNetworks: Bool

    /// Linux cannot present Apple's add-device UI or talk to a Matter fabric.
    public static var isSupported: Bool { false }

    /// Create the request. `shouldScanNetworks` defaults to `true`, matching
    /// the iOS 16.4 designated initializer.
    public init(
        topology: Topology,
        setupPayload: MTRSetupPayload? = nil,
        showing deviceCriteria: DeviceCriteria = .allDevices
    ) {
        self.init(
            topology: topology,
            setupPayload: setupPayload,
            showing: deviceCriteria,
            shouldScanNetworks: true
        )
    }

    /// Create the request with an optional network scan flag.
    public init(
        topology: Topology,
        setupPayload: MTRSetupPayload? = nil,
        showing deviceCriteria: DeviceCriteria = .allDevices,
        shouldScanNetworks: Bool = true
    ) {
        self.topology = topology
        self.setupPayload = setupPayload
        self.showDeviceCriteria = deviceCriteria
        self.shouldScanNetworks = shouldScanNetworks
    }

    /// Launch the user interface to set up a Matter device in the ecosystem.
    /// Always fails closed on Linux.
    public func perform() async throws {
        throw _matterSupportUnsupported("MatterAddDeviceRequest.perform")
    }

    public static func == (a: MatterAddDeviceRequest, b: MatterAddDeviceRequest) -> Bool {
        a.topology == b.topology
            && a.showDeviceCriteria == b.showDeviceCriteria
            && a.shouldScanNetworks == b.shouldScanNetworks
            && a.setupPayload === b.setupPayload
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topology)
        hasher.combine(showDeviceCriteria)
        hasher.combine(shouldScanNetworks)
        hasher.combine(setupPayload.map { ObjectIdentifier($0) })
    }
}

@available(iOS 16.1, macOS 14.0, *)
extension MatterAddDeviceRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case topology
        case showDeviceCriteria
        case shouldScanNetworks
    }

    /// Local round-trip encoding. `setupPayload` is omitted because Apple's
    /// encoding of `MTRSetupPayload` is not in the pinned corpus.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topology = try container.decode(Topology.self, forKey: .topology)
        showDeviceCriteria = try container.decode(DeviceCriteria.self, forKey: .showDeviceCriteria)
        shouldScanNetworks = try container.decode(Bool.self, forKey: .shouldScanNetworks)
        setupPayload = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topology, forKey: .topology)
        try container.encode(showDeviceCriteria, forKey: .showDeviceCriteria)
        try container.encode(shouldScanNetworks, forKey: .shouldScanNetworks)
    }
}

extension MatterAddDeviceRequest {
    /// The representation of a home that appears in the picker during device setup.
    public struct Home: Hashable, Codable, Sendable {
        /// The name of the home that appears in the picker.
        public var displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }
    }

    /// The representation of a room that appears in the picker during device setup.
    public struct Room: Hashable, Codable, Sendable {
        /// The name of the room that appears in the picker.
        public var displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }
    }

    /// Information describing the properties of the ecosystem.
    public struct Topology: Hashable, Codable, Sendable {
        /// The name of your ecosystem.
        public var ecosystemName: String

        /// An array of available homes to add the new device into.
        public var homes: [Home]

        public init(ecosystemName: String, homes: [Home]) {
            self.ecosystemName = ecosystemName
            self.homes = homes
        }
    }

    /// A predicate to match against possible devices that may appear in the picker.
    public enum DeviceCriteria: Hashable, Codable, Sendable {
        /// All devices match without any filtering.
        case allDevices
        /// A device matches if it matches any one of the nested criteria.
        indirect case any([DeviceCriteria])
        /// A device matches if it matches all of the nested criteria.
        indirect case all([DeviceCriteria])
        /// A device matches if it does not match the nested criteria.
        indirect case not(DeviceCriteria)
        /// A device matches if it has the given commissioning identifier.
        case commissioningID(UUID)
        /// A device matches if it has the given vendor identifier.
        case vendorID(Int)
        /// A device matches if it has the given product identifier.
        case productID(Int)
        /// A device matches if it has the given serial number.
        case serialNumber(String)
        /// A device matches if it is already paired to the given fabric node.
        case fabricNode(rootPublicKey: Data, nodeID: UInt64)
    }
}
