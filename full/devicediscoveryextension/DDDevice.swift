import Foundation

/// Local capability bits advertised on a `DDDevice`. Raw bit assignments follow
/// the pinned `dotnet/macios` `DDDeviceSupports` flags (`BluetoothPairingLE =
/// 1 << 1`, `BluetoothTransportBridging = 1 << 2`, `BluetoothHid = 1 << 3`).
/// There is no bit-0 member in the public census.
public struct DDDeviceSupports: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let bluetoothPairingLE = DDDeviceSupports(rawValue: 1 << 1)
    public static let bluetoothTransportBridging = DDDeviceSupports(rawValue: 1 << 2)
    public static let bluetoothHID = DDDeviceSupports(rawValue: 1 << 3)
}

/// Process-local discovered-device record. Setting networking fields stores
/// them on this object and does not browse, pair, or advertise.
public class DDDevice: NSObject {
    public enum Category: Int, Sendable, Hashable {
        case hifiSpeaker = 0
        case hifiSpeakerMultiple = 1
        case tvWithMediaBox = 2
        case tv = 3
        case laptopComputer = 4
        case desktopComputer = 5
        case accessorySetup = 6
    }

    public enum MediaPlaybackState: Int, Sendable, Hashable {
        case noContent = 0
        case paused = 1
        case playing = 2
    }

    public enum `Protocol`: Int, Sendable, Hashable {
        case invalid = 0
        case dial = 1
    }

    public enum WiFiAwareServiceRole: Int, Sendable, Hashable {
        case subscriber = 10
        case publisher = 20
    }

    public var displayName: String
    public var category: Category
    public var protocolType: UTType
    public var identifier: String

    /// Defaults to `.invalid`. Coupling to `protocolType` is unobserved.
    public var `protocol`: Protocol

    /// Defaults to `.invalid`. Darwin activation is not started from `init`.
    public var state: DDDeviceState

    public var bluetoothIdentifier: UUID?
    public var displayImageName: String?
    public var ssid: String?
    public var mediaContentTitle: String?
    public var mediaContentSubtitle: String?
    public var wifiAwareServiceName: String?
    public var wifiAwareModelName: String?
    public var wifiAwareVendorName: String?

    /// Defaults to `.noContent`.
    public var mediaPlaybackState: MediaPlaybackState

    /// Defaults to `[]`.
    public var deviceSupports: DDDeviceSupports

    /// Defaults to `false`.
    public var supportsGrouping: Bool

    /// Darwin's post-init URL is unobserved. Linux uses a file-URL root as a
    /// non-nil placeholder; it is not a discovered device location.
    public var url: URL

    /// Defaults to `.subscriber` (the smaller documented raw value). Darwin's
    /// default is an oracle question.
    public var wifiAwareServiceRole: WiFiAwareServiceRole

    /// Stored locally. Assignment does not open a Network path.
    public var networkEndpoint: NWEndpoint?

    /// Stored locally. Assignment does not publish a TXT record.
    public var txtRecord: NWTXTRecord?

    @available(*, unavailable)
    public override init() {
        fatalError("DDDevice requires init(displayName:category:protocolType:identifier:)")
    }

    public init(
        displayName: String,
        category: Category,
        protocolType: UTType,
        identifier: String
    ) {
        self.displayName = displayName
        self.category = category
        self.protocolType = protocolType
        self.identifier = identifier
        self.`protocol` = .invalid
        self.state = .invalid
        self.mediaPlaybackState = .noContent
        self.deviceSupports = []
        self.supportsGrouping = false
        self.url = URL(fileURLWithPath: "/")
        self.wifiAwareServiceRole = .subscriber
        super.init()
    }
}

/// Top-level device-state enumeration (not nested in `DDDevice`). Raw values
/// follow pinned macios (`Invalid = 0`, `Activating = 10`, `Activated = 20`,
/// `Authorized = 25`, `Invalidating = 30`).
public enum DDDeviceState: Int, Sendable, Hashable {
    case invalid = 0
    case activating = 10
    case activated = 20
    case authorized = 25
    case invalidating = 30
}

/// Linux mapping of `DDDeviceCategoryToString`. Darwin's exact strings are
/// unobserved; this returns the ObjC enumerator spelling from the pinned USR.
public func DDDeviceCategoryToString(_ inValue: DDDevice.Category) -> String {
    switch inValue {
    case .hifiSpeaker: return "DDDeviceCategoryHiFiSpeaker"
    case .hifiSpeakerMultiple: return "DDDeviceCategoryHiFiSpeakerMultiple"
    case .tvWithMediaBox: return "DDDeviceCategoryTVWithMediaBox"
    case .tv: return "DDDeviceCategoryTV"
    case .laptopComputer: return "DDDeviceCategoryLaptopComputer"
    case .desktopComputer: return "DDDeviceCategoryDesktopComputer"
    case .accessorySetup: return "DDDeviceCategoryAccessorySetup"
    }
}

public func DDDeviceMediaPlaybackStateToString(_ inValue: DDDevice.MediaPlaybackState) -> String {
    switch inValue {
    case .noContent: return "DDDeviceMediaPlaybackStateNoContent"
    case .paused: return "DDDeviceMediaPlaybackStatePaused"
    case .playing: return "DDDeviceMediaPlaybackStatePlaying"
    }
}

public func DDDeviceProtocolToString(_ inValue: DDDevice.`Protocol`) -> String {
    switch inValue {
    case .invalid: return "DDDeviceProtocolInvalid"
    case .dial: return "DDDeviceProtocolDIAL"
    }
}

/// Clients outside this module cannot write `DDDevice.Protocol` because Swift
/// reserves `.Protocol` for protocol metatypes. This alias is the same nested
/// type (`c:@E@DDDeviceProtocol`).
public typealias DDDeviceProtocol = DDDevice.`Protocol`

public func DDDeviceStateToString(_ inValue: DDDeviceState) -> String {
    switch inValue {
    case .invalid: return "DDDeviceStateInvalid"
    case .activating: return "DDDeviceStateActivating"
    case .activated: return "DDDeviceStateActivated"
    case .authorized: return "DDDeviceStateAuthorized"
    case .invalidating: return "DDDeviceStateInvalidating"
    }
}
