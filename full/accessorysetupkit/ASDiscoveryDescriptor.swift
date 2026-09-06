import Foundation

/// Filter describing which accessories the picker should show. Linux never
/// talks to Bluetooth or Wi-Fi Aware; blob/mask and name matching are local
/// arithmetic available through `@_spi(OpenUIKitHost)`.
open class ASDiscoveryDescriptor: NSObject {
    /// BLE proximity filter. Raw values match pinned
    /// `ASDiscoveryDescriptorRange` (`Default = 0`, `Immediate = 10`).
    public enum Range: Int, Equatable, Hashable, Sendable {
        case `default` = 0
        case immediate = 10
    }

    /// Wi-Fi Aware NAN role. Raw values match pinned
    /// `ASDiscoveryDescriptorWiFiAwareServiceRole`
    /// (`Subscriber = 10`, `Publisher = 20`).
    public enum WiFiAwareServiceRole: Int, Equatable, Hashable, Sendable {
        case subscriber = 10
        case publisher = 20
    }

    public override init() {
        super.init()
    }

    open var supportedOptions: ASAccessory.SupportOptions = []
    open var bluetoothCompanyIdentifier = ASBluetoothCompanyIdentifier(0)
    open var bluetoothManufacturerDataBlob: Data?
    open var bluetoothManufacturerDataMask: Data?
    open var bluetoothNameSubstringCompareOptions: NSString.CompareOptions = []
    open var bluetoothNameSubstring: String?
    open var bluetoothRange: Range = .default
    open var bluetoothServiceDataBlob: Data?
    open var bluetoothServiceDataMask: Data?
    open var bluetoothServiceUUID: CBUUID?
    open var ssid: String?
    open var ssidPrefix: String?
    open var wifiAwareServiceName: String?
    open var wifiAwareServiceRole: WiFiAwareServiceRole = .subscriber
    open var wifiAwareModelNameMatch: ASPropertyCompareString?
    open var wifiAwareVendorNameMatch: ASPropertyCompareString?

    /// Masked manufacturer-data compare used by BLE filters: each payload
    /// byte is AND-ed with the mask before equality with the blob.
    @_spi(OpenUIKitHost)
    public func hostMatchesBluetoothManufacturerData(_ payload: Data) -> Bool {
        Self.hostMatchesMaskedBlob(
            payload: payload,
            blob: bluetoothManufacturerDataBlob,
            mask: bluetoothManufacturerDataMask
        )
    }

    /// Masked service-data compare, same arithmetic as manufacturer data.
    @_spi(OpenUIKitHost)
    public func hostMatchesBluetoothServiceData(_ payload: Data) -> Bool {
        Self.hostMatchesMaskedBlob(
            payload: payload,
            blob: bluetoothServiceDataBlob,
            mask: bluetoothServiceDataMask
        )
    }

    /// Substring match using `bluetoothNameSubstringCompareOptions`.
    @_spi(OpenUIKitHost)
    public func hostMatchesBluetoothName(_ name: String) -> Bool {
        guard let substring = bluetoothNameSubstring else { return true }
        let range = (name as NSString).range(
            of: substring,
            options: bluetoothNameSubstringCompareOptions
        )
        return range.location != NSNotFound
    }

    /// Exact SSID match, otherwise prefix match, otherwise unconstrained.
    @_spi(OpenUIKitHost)
    public func hostMatchesSSID(_ candidate: String) -> Bool {
        if let ssid {
            return candidate == ssid
        }
        if let ssidPrefix {
            return candidate.hasPrefix(ssidPrefix)
        }
        return true
    }

    private static func hostMatchesMaskedBlob(
        payload: Data,
        blob: Data?,
        mask: Data?
    ) -> Bool {
        guard let blob, let mask else {
            return blob == nil && mask == nil
        }
        guard payload.count == blob.count, blob.count == mask.count else {
            return false
        }
        for index in blob.indices {
            if (payload[index] & mask[index]) != (blob[index] & mask[index]) {
                return false
            }
        }
        return true
    }
}

/// String plus `NSString.CompareOptions` used by Wi-Fi Aware name filters.
open class ASPropertyCompareString: NSObject {
    private let storedString: String
    private let storedCompareOptions: NSString.CompareOptions

    @available(*, unavailable, message: "Use init(string:compareOptions:)")
    public override init() {
        fatalError("ASPropertyCompareString.init is unsupported")
    }

    public init(string: String, compareOptions: NSString.CompareOptions = []) {
        storedString = string
        storedCompareOptions = compareOptions
        super.init()
    }

    open var string: String { storedString }
    open var compareOptions: NSString.CompareOptions { storedCompareOptions }

    /// Contains-match using the stored compare options. Apple's exact
    /// equality-vs-substring rule is unobserved (oracle); this is the
    /// `NSString.range(of:options:)` interpretation.
    @_spi(OpenUIKitHost)
    public func hostMatches(_ candidate: String) -> Bool {
        let range = (candidate as NSString).range(
            of: storedString,
            options: storedCompareOptions
        )
        return range.location != NSNotFound
    }
}
