import Foundation

/// The object that handles configuration and commissioning of a device into an
/// ecosystem.
///
/// Apps subclass this type and override the open methods. Linux has no Apple
/// extension host, Matter attestation service, Wi-Fi/Thread credential store,
/// or commissioning UI. Default implementations therefore fail closed for
/// attestation, network selection, and commissioning. `rooms(in:)` returns an
/// empty list and `configureDevice(named:in:)` is inert, matching the
/// documented empty-topology behavior rather than fabricating homes or rooms.
@available(iOS 16.1, macOS 14.0, *)
open class MatterAddDeviceExtensionRequestHandler: NSObject {
    public override init() {
        super.init()
    }

    /// Performs additional verification after Apple's built-in attestation.
    /// Linux has no Apple attestation pipeline, so the default fails closed.
    open func validateDeviceCredential(
        _ deviceCredential: DeviceCredential
    ) async throws {
        _ = deviceCredential
        throw _matterSupportUnsupported("validateDeviceCredential")
    }

    /// Selects a Wi-Fi network for the accessory. Linux has no system Wi-Fi
    /// association path, so the default fails closed instead of returning
    /// `defaultSystemNetwork`.
    open func selectWiFiNetwork(
        from wifiScanResults: [WiFiScanResult]
    ) async throws -> WiFiNetworkAssociation {
        _ = wifiScanResults
        throw _matterSupportUnsupported("selectWiFiNetwork")
    }

    /// Selects a Thread network for the accessory. Linux has no ThreadNetwork
    /// credential store, so the default fails closed.
    open func selectThreadNetwork(
        from threadScanResults: [ThreadScanResult]
    ) async throws -> ThreadNetworkAssociation {
        _ = threadScanResults
        throw _matterSupportUnsupported("selectThreadNetwork")
    }

    /// Commissions the device with the onboarding payload. Always fails closed
    /// in the base class; subclasses must supply a real fabric.
    open func commissionDevice(
        in home: MatterAddDeviceRequest.Home?,
        onboardingPayload: String,
        commissioningID: UUID
    ) async throws {
        _ = (home, onboardingPayload, commissioningID)
        throw _matterSupportUnsupported("commissionDevice")
    }

    /// Rooms for the Select Room card. Empty means no picker and a nil room.
    open func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room] {
        _ = home
        return []
    }

    /// Applies the selected name and room. Inert by default.
    open func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async {
        _ = (name, room)
    }
}

extension MatterAddDeviceExtensionRequestHandler {
    /// Device credentials presented during commissioning.
    public struct DeviceCredential: Hashable, Codable, Sendable {
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
            self.productAttestationIntermediateCertificate = productAttestationIntermediateCertificate
        }
    }

    /// A result of a Wi-Fi-scan operation performed on the device.
    public struct WiFiScanResult: Hashable, Codable, Sendable {
        public var ssid: Data
        public var rssi: Int8
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
    }

    /// A result of a Thread-scan operation performed on the device.
    public struct ThreadScanResult: Hashable, Codable, Sendable {
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

    /// Description of an association to a Wi-Fi network.
    public struct WiFiNetworkAssociation: Hashable, Sendable {
        private enum Kind: Hashable, Sendable {
            case defaultSystem
            case network(ssid: Data, credentials: Data)
        }

        private let kind: Kind

        /// Sentinel for the current Wi-Fi network of the iOS device.
        /// Holding this value does not associate Linux to any network.
        public static var defaultSystemNetwork: WiFiNetworkAssociation {
            WiFiNetworkAssociation(kind: .defaultSystem)
        }

        /// Records SSID and passphrase bytes for a specific network.
        public static func network(ssid: Data, credentials: Data) -> WiFiNetworkAssociation {
            WiFiNetworkAssociation(kind: .network(ssid: ssid, credentials: credentials))
        }

        public static func == (
            a: WiFiNetworkAssociation,
            b: WiFiNetworkAssociation
        ) -> Bool {
            a.kind == b.kind
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(kind)
        }
    }

    /// Description of an association to a Thread network.
    public struct ThreadNetworkAssociation: Hashable, Sendable {
        private enum Kind: Hashable, Sendable {
            case defaultSystem
            case network(extendedPANID: UInt64)
        }

        private let kind: Kind

        /// Sentinel for the system's preferred Thread network.
        /// Holding this value does not join a Thread mesh on Linux.
        public static var defaultSystemNetwork: ThreadNetworkAssociation {
            ThreadNetworkAssociation(kind: .defaultSystem)
        }

        /// Records an extended PAN identifier. Credentials are not fetched.
        public static func network(extendedPANID: UInt64) -> ThreadNetworkAssociation {
            ThreadNetworkAssociation(kind: .network(extendedPANID: extendedPANID))
        }

        public static func == (
            a: ThreadNetworkAssociation,
            b: ThreadNetworkAssociation
        ) -> Bool {
            a.kind == b.kind
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(kind)
        }
    }
}

@available(iOS 16.1, macOS 14.0, *)
extension MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case ssid
        case credentials
    }

    private enum KindTag: String, Codable {
        case defaultSystemNetwork
        case network
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch kind {
        case .defaultSystem:
            try container.encode(KindTag.defaultSystemNetwork, forKey: .kind)
        case .network(let ssid, let credentials):
            try container.encode(KindTag.network, forKey: .kind)
            try container.encode(ssid, forKey: .ssid)
            try container.encode(credentials, forKey: .credentials)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(KindTag.self, forKey: .kind) {
        case .defaultSystemNetwork:
            self = .defaultSystemNetwork
        case .network:
            self = .network(
                ssid: try container.decode(Data.self, forKey: .ssid),
                credentials: try container.decode(Data.self, forKey: .credentials)
            )
        }
    }
}

@available(iOS 16.1, macOS 14.0, *)
extension MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case extendedPANID
    }

    private enum KindTag: String, Codable {
        case defaultSystemNetwork
        case network
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch kind {
        case .defaultSystem:
            try container.encode(KindTag.defaultSystemNetwork, forKey: .kind)
        case .network(let extendedPANID):
            try container.encode(KindTag.network, forKey: .kind)
            try container.encode(extendedPANID, forKey: .extendedPANID)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(KindTag.self, forKey: .kind) {
        case .defaultSystemNetwork:
            self = .defaultSystemNetwork
        case .network:
            self = .network(
                extendedPANID: try container.decode(UInt64.self, forKey: .extendedPANID)
            )
        }
    }
}
