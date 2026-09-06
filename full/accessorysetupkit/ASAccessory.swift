import Foundation

/// Session event kind. Raw values match the pinned dotnet-macios
/// `[Native] ASAccessoryEventType` (`Unknown = 0` … `PickerSetupRename = 90`).
public enum ASAccessoryEventType: Int, Equatable, Hashable, Sendable {
    case unknown = 0
    case activated = 10
    case invalidated = 11
    case migrationComplete = 20
    case accessoryAdded = 30
    case accessoryRemoved = 31
    case accessoryChanged = 32
    case accessoryDiscovered = 33
    case pickerDidPresent = 40
    case pickerDidDismiss = 50
    case pickerSetupBridging = 60
    case pickerSetupFailed = 70
    case pickerSetupPairing = 80
    case pickerSetupRename = 90
}

/// Previously authorized accessory record. Linux never vends a live accessory
/// from discovery; host tests construct records through
/// `@_spi(OpenUIKitHost)`.
open class ASAccessory: NSObject {
    public typealias WiFiAwarePairedDeviceID = UInt64

    /// Authorization state. Raw values match pinned dotnet-macios
    /// `Unauthorized = 0`, `AwaitingAuthorization = 10`, `Authorized = 20`.
    public enum AccessoryState: Int, Equatable, Hashable, Sendable {
        case unauthorized = 0
        case awaitingAuthorization = 10
        case authorized = 20
    }

    /// SSID rename bits. `ssid` is `1 << 0` from pinned `ASAccessoryRenameOptions`.
    public struct RenameOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let ssid = RenameOptions(rawValue: 1 << 0)
    }

    /// Transport support bits. Positions match pinned
    /// `ASAccessorySupportOptions` (`1 << 1`, `1 << 2`, `1 << 3`).
    public struct SupportOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let bluetoothPairingLE = SupportOptions(rawValue: 1 << 1)
        public static let bluetoothTransportBridging = SupportOptions(rawValue: 1 << 2)
        public static let bluetoothHID = SupportOptions(rawValue: 1 << 3)
    }

    private let storedState: AccessoryState
    private let storedBluetoothIdentifier: UUID?
    private let storedDisplayName: String
    private let storedSSID: String?
    private let storedDescriptor: ASDiscoveryDescriptor
    private let storedBluetoothTransportBridgingIdentifier: Data?
    private let storedWifiAwarePairedDeviceID: WiFiAwarePairedDeviceID

    @available(*, unavailable, message: "Use session events or @_spi(OpenUIKitHost) construction")
    public override init() {
        fatalError("ASAccessory.init is unsupported")
    }

    @_spi(OpenUIKitHost)
    public init(
        hostDisplayName: String = "",
        hostState: AccessoryState = .unauthorized,
        hostBluetoothIdentifier: UUID? = nil,
        hostSSID: String? = nil,
        hostDescriptor: ASDiscoveryDescriptor = ASDiscoveryDescriptor(),
        hostBluetoothTransportBridgingIdentifier: Data? = nil,
        hostWifiAwarePairedDeviceID: WiFiAwarePairedDeviceID = 0
    ) {
        storedDisplayName = hostDisplayName
        storedState = hostState
        storedBluetoothIdentifier = hostBluetoothIdentifier
        storedSSID = hostSSID
        storedDescriptor = hostDescriptor
        storedBluetoothTransportBridgingIdentifier = hostBluetoothTransportBridgingIdentifier
        storedWifiAwarePairedDeviceID = hostWifiAwarePairedDeviceID
        super.init()
    }

    open var state: AccessoryState { storedState }
    open var bluetoothIdentifier: UUID? { storedBluetoothIdentifier }
    open var displayName: String { storedDisplayName }
    open var ssid: String? { storedSSID }
    open var descriptor: ASDiscoveryDescriptor { storedDescriptor }
    open var bluetoothTransportBridgingIdentifier: Data? {
        storedBluetoothTransportBridgingIdentifier
    }
    open var wifiAwarePairedDeviceID: WiFiAwarePairedDeviceID {
        storedWifiAwarePairedDeviceID
    }
}

/// Event delivered to `ASAccessorySession` handlers. Linux constructs these
/// for local activate/invalidate transitions; hardware events are never
/// invented.
open class ASAccessoryEvent: NSObject {
    private let storedEventType: ASAccessoryEventType
    private let storedAccessory: ASAccessory?
    private let storedError: (any Error)?

    @available(*, unavailable, message: "Events are produced by ASAccessorySession")
    public override init() {
        fatalError("ASAccessoryEvent.init is unsupported")
    }

    @_spi(OpenUIKitHost)
    public init(
        hostEventType: ASAccessoryEventType,
        hostAccessory: ASAccessory? = nil,
        hostError: (any Error)? = nil
    ) {
        storedEventType = hostEventType
        storedAccessory = hostAccessory
        storedError = hostError
        super.init()
    }

    open var eventType: ASAccessoryEventType { storedEventType }
    open var accessory: ASAccessory? { storedAccessory }
    open var error: (any Error)? { storedError }
}

/// Discovered-but-not-yet-authorized accessory. Linux never invents BLE
/// advertisements; host tests supply RSSI and advertisement payloads.
open class ASDiscoveredAccessory: ASAccessory {
    private let storedBluetoothAdvertisementData: [AnyHashable: Any]?
    private let storedBluetoothRSSI: Int?

    @_spi(OpenUIKitHost)
    public init(
        hostDisplayName: String = "",
        hostDescriptor: ASDiscoveryDescriptor = ASDiscoveryDescriptor(),
        hostBluetoothAdvertisementData: [AnyHashable: Any]? = nil,
        hostBluetoothRSSI: Int? = nil
    ) {
        storedBluetoothAdvertisementData = hostBluetoothAdvertisementData
        storedBluetoothRSSI = hostBluetoothRSSI
        super.init(
            hostDisplayName: hostDisplayName,
            hostState: .unauthorized,
            hostDescriptor: hostDescriptor
        )
    }

    open var bluetoothAdvertisementData: [AnyHashable: Any]? {
        storedBluetoothAdvertisementData
    }

    open var bluetoothRSSI: Int? { storedBluetoothRSSI }
}
