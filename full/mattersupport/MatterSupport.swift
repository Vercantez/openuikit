@_exported import Foundation

#if canImport(Matter)
import Matter
#endif

/// Linux starting point for Apple's public `MatterSupport` module.
///
/// Linux has no Apple Home / Matter commissioning UI, no MatterSupport
/// app extension host, and (in the isolated host configuration) no Matter
/// module. Public APIs that would present system UI or talk to an ecosystem
/// backend fail closed. Types that require `MTRSetupPayload`,
/// `MTRNetworkCommissioningWiFiSecurity`, or `MTRNetworkCommissioningWiFiBand`
/// are compiled only when `canImport(Matter)`; they are never replaced with
/// same-named substitutes.

// MARK: - Fail-closed NSError

/// Linux-local domain. Darwin's error identity for `perform()` and un-overridden
/// extension hooks is unobserved.
let matterSupportUnavailableDomain = "MatterSupport.linux.unavailable"

let matterSupportUnavailableCode = 1

func matterSupportUnavailableError(operation: String) -> NSError {
    NSError(
        domain: matterSupportUnavailableDomain,
        code: matterSupportUnavailableCode,
        userInfo: [
            NSLocalizedDescriptionKey:
                "Linux has no Matter commissioning UI or extension host (\(operation))"
        ]
    )
}

// MARK: - DeviceCriteria coding (Linux-local keys; Darwin layout unobserved)

private enum DeviceCriteriaCodingKey: String, CodingKey {
    case kind
    case string
    case int
    case uuid
    case data
    case uint64
    case children
    case child
}

private enum DeviceCriteriaKind: String {
    case allDevices
    case fabricNode
    case serialNumber
    case commissioningID
    case vendorID
    case productID
    case all
    case any
    case not
}

// MARK: - MatterAddDeviceRequest

public struct MatterAddDeviceRequest: Hashable, Sendable {
    public var topology: Topology
    public var showDeviceCriteria: DeviceCriteria
    public var shouldScanNetworks: Bool

#if canImport(Matter)
    public var setupPayload: MTRSetupPayload?

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
#else
    /// Host-only construction. The canonical inits take `MTRSetupPayload?` and
    /// are omitted while Matter cannot be imported.
    @_spi(OpenUIKitHost)
    public init(
        topology: Topology,
        showing deviceCriteria: DeviceCriteria = .allDevices,
        shouldScanNetworks: Bool = true
    ) {
        self.topology = topology
        self.showDeviceCriteria = deviceCriteria
        self.shouldScanNetworks = shouldScanNetworks
    }
#endif

    /// Linux has no Apple Matter commissioning UI.
    public static var isSupported: Bool { false }

    /// Always throws. Does not invent a successful commissioning sheet.
    public func perform() async throws {
        throw matterSupportUnavailableError(operation: "perform")
    }
}

extension MatterAddDeviceRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case topology
        case showDeviceCriteria
        case shouldScanNetworks
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topology = try container.decode(Topology.self, forKey: .topology)
        showDeviceCriteria = try container.decode(
            DeviceCriteria.self,
            forKey: .showDeviceCriteria
        )
        shouldScanNetworks = try container.decode(Bool.self, forKey: .shouldScanNetworks)
#if canImport(Matter)
        setupPayload = nil
#endif
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topology, forKey: .topology)
        try container.encode(showDeviceCriteria, forKey: .showDeviceCriteria)
        try container.encode(shouldScanNetworks, forKey: .shouldScanNetworks)
    }
}

extension MatterAddDeviceRequest {
    public struct Home: Hashable, Sendable, Codable {
        public var displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }
    }

    public struct Room: Hashable, Sendable, Codable {
        public var displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }
    }

    public struct Topology: Hashable, Sendable, Codable {
        public var ecosystemName: String
        public var homes: [Home]

        public init(ecosystemName: String, homes: [Home]) {
            self.ecosystemName = ecosystemName
            self.homes = homes
        }
    }

    public enum DeviceCriteria: Hashable, Sendable {
        case allDevices
        case fabricNode(rootPublicKey: Data, nodeID: UInt64)
        case serialNumber(String)
        case commissioningID(UUID)
        case vendorID(Int)
        case productID(Int)
        indirect case all([MatterAddDeviceRequest.DeviceCriteria])
        indirect case any([MatterAddDeviceRequest.DeviceCriteria])
        indirect case not(MatterAddDeviceRequest.DeviceCriteria)
    }
}

extension MatterAddDeviceRequest.DeviceCriteria: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DeviceCriteriaCodingKey.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch DeviceCriteriaKind(rawValue: kind) {
        case .allDevices:
            self = .allDevices
        case .fabricNode:
            self = .fabricNode(
                rootPublicKey: try container.decode(Data.self, forKey: .data),
                nodeID: try container.decode(UInt64.self, forKey: .uint64)
            )
        case .serialNumber:
            self = .serialNumber(try container.decode(String.self, forKey: .string))
        case .commissioningID:
            self = .commissioningID(try container.decode(UUID.self, forKey: .uuid))
        case .vendorID:
            self = .vendorID(try container.decode(Int.self, forKey: .int))
        case .productID:
            self = .productID(try container.decode(Int.self, forKey: .int))
        case .all:
            self = .all(
                try container.decode(
                    [MatterAddDeviceRequest.DeviceCriteria].self,
                    forKey: .children
                )
            )
        case .any:
            self = .any(
                try container.decode(
                    [MatterAddDeviceRequest.DeviceCriteria].self,
                    forKey: .children
                )
            )
        case .not:
            self = .not(
                try container.decode(
                    MatterAddDeviceRequest.DeviceCriteria.self,
                    forKey: .child
                )
            )
        case nil:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "unknown DeviceCriteria kind \(kind)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DeviceCriteriaCodingKey.self)
        switch self {
        case .allDevices:
            try container.encode(DeviceCriteriaKind.allDevices.rawValue, forKey: .kind)
        case .fabricNode(let rootPublicKey, let nodeID):
            try container.encode(DeviceCriteriaKind.fabricNode.rawValue, forKey: .kind)
            try container.encode(rootPublicKey, forKey: .data)
            try container.encode(nodeID, forKey: .uint64)
        case .serialNumber(let value):
            try container.encode(DeviceCriteriaKind.serialNumber.rawValue, forKey: .kind)
            try container.encode(value, forKey: .string)
        case .commissioningID(let value):
            try container.encode(DeviceCriteriaKind.commissioningID.rawValue, forKey: .kind)
            try container.encode(value, forKey: .uuid)
        case .vendorID(let value):
            try container.encode(DeviceCriteriaKind.vendorID.rawValue, forKey: .kind)
            try container.encode(value, forKey: .int)
        case .productID(let value):
            try container.encode(DeviceCriteriaKind.productID.rawValue, forKey: .kind)
            try container.encode(value, forKey: .int)
        case .all(let children):
            try container.encode(DeviceCriteriaKind.all.rawValue, forKey: .kind)
            try container.encode(children, forKey: .children)
        case .any(let children):
            try container.encode(DeviceCriteriaKind.any.rawValue, forKey: .kind)
            try container.encode(children, forKey: .children)
        case .not(let child):
            try container.encode(DeviceCriteriaKind.not.rawValue, forKey: .kind)
            try container.encode(child, forKey: .child)
        }
    }
}

// MARK: - Extension request handler

/// Base class for a MatterSupport extension principal. Linux has no extension
/// host: un-overridden hooks fail closed. Subclass and override; do not treat
/// a successful return from the base class as Apple-service success.
open class MatterAddDeviceExtensionRequestHandler: NSObject {
    public override init() {
        super.init()
    }

    /// Performs verification and attestation checks. The base class always
    /// throws; Linux has no PAA roots or attestation service.
    open func validateDeviceCredential(
        _ deviceCredential: DeviceCredential
    ) async throws {
        _ = deviceCredential
        throw matterSupportUnavailableError(operation: "validateDeviceCredential")
    }

    /// Commissions the device with the onboarding payload. The base class
    /// always throws; Linux has no Matter fabric commissioner.
    open func commissionDevice(
        in home: MatterAddDeviceRequest.Home?,
        onboardingPayload: String,
        commissioningID: UUID
    ) async throws {
        _ = home
        _ = onboardingPayload
        _ = commissioningID
        throw matterSupportUnavailableError(operation: "commissionDevice")
    }

    /// Pushes the user-chosen name/room into the ecosystem backend. The base
    /// class is a no-op: there is no backend to update.
    open func configureDevice(
        named name: String,
        in room: MatterAddDeviceRequest.Room?
    ) async {
        _ = name
        _ = room
    }

    /// Rooms to offer in the commissioning UI. The base class returns `[]`.
    open func rooms(
        in home: MatterAddDeviceRequest.Home?
    ) async -> [MatterAddDeviceRequest.Room] {
        _ = home
        return []
    }

    /// Selects a Wi-Fi network for the accessory. The base class always throws.
    open func selectWiFiNetwork(
        from wifiScanResults: [WiFiScanResult]
    ) async throws -> WiFiNetworkAssociation {
        _ = wifiScanResults
        throw matterSupportUnavailableError(operation: "selectWiFiNetwork")
    }

    /// Selects a Thread network for the accessory. The base class always throws.
    open func selectThreadNetwork(
        from threadScanResults: [ThreadScanResult]
    ) async throws -> ThreadNetworkAssociation {
        _ = threadScanResults
        throw matterSupportUnavailableError(operation: "selectThreadNetwork")
    }
}

extension MatterAddDeviceExtensionRequestHandler {
    public struct DeviceCredential: Hashable, Sendable, Codable {
        public var certificationDeclaration: Data
        public var deviceAttestationCertificate: Data
        public var productAttestationIntermediateCertificate: Data

        public init(
            certificationDeclaration: Data,
            deviceAttestationCertificate: Data,
            productAttestationIntermediateCertificate: Data
        ) {
            self.certificationDeclaration = certificationDeclaration
            self.deviceAttestationCertificate = deviceAttestationCertificate
            self.productAttestationIntermediateCertificate =
                productAttestationIntermediateCertificate
        }
    }

    public struct WiFiScanResult: Hashable, Sendable {
        public var ssid: Data
        public var rssi: Int8

#if canImport(Matter)
        public var security: MTRNetworkCommissioningWiFiSecurity
        public var band: MTRNetworkCommissioningWiFiBand

        public init(
            ssid: Data,
            rssi: Int8,
            security: MTRNetworkCommissioningWiFiSecurity,
            band: MTRNetworkCommissioningWiFiBand
        ) {
            self.ssid = ssid
            self.rssi = rssi
            self.security = security
            self.band = band
        }
#else
        @_spi(OpenUIKitHost)
        public init(ssid: Data, rssi: Int8) {
            self.ssid = ssid
            self.rssi = rssi
        }
#endif
    }

    public struct ThreadScanResult: Hashable, Sendable, Codable {
        public var networkName: String
        public var panID: UInt16
        public var extendedPANID: UInt64
        public var channel: UInt16
        public var extendedAddress: Data
        public var rssi: Int8
        public var version: UInt8
        public var linkQualityIndicator: UInt8

        public init(
            networkName: String,
            panID: UInt16,
            extendedPANID: UInt64,
            channel: UInt16,
            extendedAddress: Data,
            rssi: Int8,
            version: UInt8,
            linkQualityIndicator: UInt8
        ) {
            self.networkName = networkName
            self.panID = panID
            self.extendedPANID = extendedPANID
            self.channel = channel
            self.extendedAddress = extendedAddress
            self.rssi = rssi
            self.version = version
            self.linkQualityIndicator = linkQualityIndicator
        }
    }

    public struct WiFiNetworkAssociation: Hashable, Sendable {
        fileprivate enum Representation: Hashable, Sendable {
            case defaultSystemNetwork
            case ssidCredentials(ssid: Data, credentials: Data)
        }

        fileprivate var representation: Representation

        fileprivate init(representation: Representation) {
            self.representation = representation
        }

        public static var defaultSystemNetwork: WiFiNetworkAssociation {
            WiFiNetworkAssociation(representation: .defaultSystemNetwork)
        }

        public static func network(ssid: Data, credentials: Data) -> WiFiNetworkAssociation {
            WiFiNetworkAssociation(
                representation: .ssidCredentials(ssid: ssid, credentials: credentials)
            )
        }
    }

    public struct ThreadNetworkAssociation: Hashable, Sendable {
        fileprivate enum Representation: Hashable, Sendable {
            case defaultSystemNetwork
            case extendedPANID(UInt64)
        }

        fileprivate var representation: Representation

        fileprivate init(representation: Representation) {
            self.representation = representation
        }

        public static var defaultSystemNetwork: ThreadNetworkAssociation {
            ThreadNetworkAssociation(representation: .defaultSystemNetwork)
        }

        public static func network(extendedPANID: UInt64) -> ThreadNetworkAssociation {
            ThreadNetworkAssociation(representation: .extendedPANID(extendedPANID))
        }
    }
}

extension MatterAddDeviceExtensionRequestHandler.WiFiScanResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case ssid
        case rssi
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ssid = try container.decode(Data.self, forKey: .ssid)
        rssi = try container.decode(Int8.self, forKey: .rssi)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ssid, forKey: .ssid)
        try container.encode(rssi, forKey: .rssi)
    }
}

extension MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case ssid
        case credentials
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "defaultSystemNetwork":
            self.init(representation: .defaultSystemNetwork)
        case "ssidCredentials":
            self.init(
                representation: .ssidCredentials(
                    ssid: try container.decode(Data.self, forKey: .ssid),
                    credentials: try container.decode(Data.self, forKey: .credentials)
                )
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "unknown WiFiNetworkAssociation kind \(kind)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch representation {
        case .defaultSystemNetwork:
            try container.encode("defaultSystemNetwork", forKey: .kind)
        case .ssidCredentials(let ssid, let credentials):
            try container.encode("ssidCredentials", forKey: .kind)
            try container.encode(ssid, forKey: .ssid)
            try container.encode(credentials, forKey: .credentials)
        }
    }
}

extension MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case extendedPANID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "defaultSystemNetwork":
            self.init(representation: .defaultSystemNetwork)
        case "extendedPANID":
            self.init(
                representation: .extendedPANID(
                    try container.decode(UInt64.self, forKey: .extendedPANID)
                )
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "unknown ThreadNetworkAssociation kind \(kind)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch representation {
        case .defaultSystemNetwork:
            try container.encode("defaultSystemNetwork", forKey: .kind)
        case .extendedPANID(let value):
            try container.encode("extendedPANID", forKey: .kind)
            try container.encode(value, forKey: .extendedPANID)
        }
    }
}
