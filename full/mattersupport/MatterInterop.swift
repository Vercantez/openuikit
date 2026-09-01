import Foundation

/// Linux stand-in for Matter's `MTRSetupPayload` until a Matter module exists.
///
/// MatterSupport only stores an optional payload on `MatterAddDeviceRequest`.
/// Providing a non-nil instance does not parse QR/manual codes, does not
/// satisfy `com.apple.developer.matter.allow-setup-payload`, and does not
/// make `perform()` succeed.
open class MTRSetupPayload: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

/// Linux stand-in for Matter's `MTRNetworkCommissioningWiFiSecurity` NS_OPTIONS.
/// Raw values follow the public Matter iOS 16.4 enumeration; named cases are
/// included so `WiFiScanResult` can be constructed usefully. This is not a
/// claim that Linux can join those networks.
public struct MTRNetworkCommissioningWiFiSecurity: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let unencrypted = MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 0)
    public static let WEP = MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 1)
    public static let WPAPersonal = MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 2)
    public static let WPA2Personal = MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 3)
    public static let WPA3Personal = MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 4)
}

/// Linux stand-in for Matter's `MTRNetworkCommissioningWiFiBand` NS_OPTIONS.
/// Raw values follow the public Matter Swift names (`band2G4`, `band5G`, …).
public struct MTRNetworkCommissioningWiFiBand: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let band2G4 = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 0)
    public static let band3G65 = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 1)
    public static let band5G = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 2)
    public static let band6G = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 3)
    public static let band60G = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 4)
    public static let band1G = MTRNetworkCommissioningWiFiBand(rawValue: 1 << 5)
}
