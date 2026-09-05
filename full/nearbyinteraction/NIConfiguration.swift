import Foundation

/// Abstract Nearby Interaction session configuration. Concrete subclasses
/// store peer tokens, accessory blobs, or DL-TDoA network identifiers.
/// Constructing a bare `NIConfiguration` is not part of the public Apple
/// surface; Linux keeps an internal designated initializer for subclasses.
public class NIConfiguration: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NIConfiguration()
    }
}

public class NIDiscoveryToken: NSObject, NSCopying, NSSecureCoding {
    internal let identifier: UUID

    public var deviceCapabilities: any NIDeviceCapability {
        NIHostDeviceCapability.unsupported
    }

    public static var supportsSecureCoding: Bool { true }

    internal init(identifier: UUID) {
        self.identifier = identifier
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostToken(identifier: UUID = UUID()) -> NIDiscoveryToken {
        NIDiscoveryToken(identifier: identifier)
    }

    public required init?(coder: NSCoder) {
        guard let uuidString = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let uuid = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.identifier = uuid
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier.uuidString as NSString, forKey: "identifier")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NIDiscoveryToken(identifier: identifier)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NIDiscoveryToken else { return false }
        return identifier == other.identifier
    }

    public override var hash: Int {
        identifier.hashValue
    }
}

public class NINearbyPeerConfiguration: NIConfiguration {
    public let peerDiscoveryToken: NIDiscoveryToken
    public var isCameraAssistanceEnabled: Bool = false
    public var isExtendedDistanceMeasurementEnabled: Bool = false

    public init(peerToken: NIDiscoveryToken) {
        self.peerDiscoveryToken = (peerToken.copy() as? NIDiscoveryToken) ?? peerToken
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let token = coder.decodeObject(of: NIDiscoveryToken.self, forKey: "peerDiscoveryToken") else {
            return nil
        }
        self.peerDiscoveryToken = token
        super.init(coder: coder)
        isCameraAssistanceEnabled = coder.decodeBool(forKey: "cameraAssistanceEnabled")
        isExtendedDistanceMeasurementEnabled = coder.decodeBool(forKey: "extendedDistanceMeasurementEnabled")
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(peerDiscoveryToken, forKey: "peerDiscoveryToken")
        coder.encode(isCameraAssistanceEnabled, forKey: "cameraAssistanceEnabled")
        coder.encode(isExtendedDistanceMeasurementEnabled, forKey: "extendedDistanceMeasurementEnabled")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = NINearbyPeerConfiguration(peerToken: peerDiscoveryToken)
        copy.isCameraAssistanceEnabled = isCameraAssistanceEnabled
        copy.isExtendedDistanceMeasurementEnabled = isExtendedDistanceMeasurementEnabled
        return copy
    }
}

public class NINearbyAccessoryConfiguration: NIConfiguration {
    public let accessoryDiscoveryToken: NIDiscoveryToken
    public var isCameraAssistanceEnabled: Bool = false
    public let bluetoothPeerIdentifier: UUID?

    /// Accessory shareable-configuration blobs are Apple/firmware defined.
    /// Linux cannot parse them and refuses with `invalidConfiguration`.
    public init(data: Data) throws {
        _ = data
        throw NIError(.invalidConfiguration)
    }

    /// Same fail-closed path: the accessory payload is unobserved.
    public init(accessoryData: Data, bluetoothPeerIdentifier identifier: UUID) throws {
        _ = accessoryData
        _ = identifier
        throw NIError(.invalidConfiguration)
    }

    internal init(token: NIDiscoveryToken, bluetoothPeerIdentifier: UUID?) {
        self.accessoryDiscoveryToken = (token.copy() as? NIDiscoveryToken) ?? token
        self.bluetoothPeerIdentifier = bluetoothPeerIdentifier
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostConfiguration(
        token: NIDiscoveryToken,
        bluetoothPeerIdentifier: UUID? = nil
    ) -> NINearbyAccessoryConfiguration {
        NINearbyAccessoryConfiguration(token: token, bluetoothPeerIdentifier: bluetoothPeerIdentifier)
    }

    public required init?(coder: NSCoder) {
        guard let token = coder.decodeObject(of: NIDiscoveryToken.self, forKey: "accessoryDiscoveryToken") else {
            return nil
        }
        self.accessoryDiscoveryToken = token
        if let uuidString = coder.decodeObject(of: NSString.self, forKey: "bluetoothPeerIdentifier") as String? {
            self.bluetoothPeerIdentifier = UUID(uuidString: uuidString)
        } else {
            self.bluetoothPeerIdentifier = nil
        }
        super.init(coder: coder)
        isCameraAssistanceEnabled = coder.decodeBool(forKey: "cameraAssistanceEnabled")
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(accessoryDiscoveryToken, forKey: "accessoryDiscoveryToken")
        if let bluetoothPeerIdentifier {
            coder.encode(bluetoothPeerIdentifier.uuidString as NSString, forKey: "bluetoothPeerIdentifier")
        }
        coder.encode(isCameraAssistanceEnabled, forKey: "cameraAssistanceEnabled")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = NINearbyAccessoryConfiguration(
            token: accessoryDiscoveryToken,
            bluetoothPeerIdentifier: bluetoothPeerIdentifier
        )
        copy.isCameraAssistanceEnabled = isCameraAssistanceEnabled
        return copy
    }
}

public class NIDLTDOAConfiguration: NIConfiguration {
    public var networkIdentifier: Int

    public init(networkIdentifier: Int) {
        self.networkIdentifier = networkIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.networkIdentifier = coder.decodeInteger(forKey: "networkIdentifier")
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(networkIdentifier, forKey: "networkIdentifier")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        NIDLTDOAConfiguration(networkIdentifier: networkIdentifier)
    }
}
