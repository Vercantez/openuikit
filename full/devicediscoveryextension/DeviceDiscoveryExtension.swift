@_exported import Foundation

// Linux starting point for Apple's public DeviceDiscoveryExtension surface,
// reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graph and
// cross-checked against the api-digester plus pinned dotnet-macios bindings.
//
// Discovery, pairing, Wi-Fi Aware, Bluetooth HID, DIAL, NSXPC extension-host
// delivery, and entitlement prompts are fail-closed: Linux has no
// DeviceDiscovery daemon, accessory-setup UI, or Apple networking entitlements.
// Value types, error codes, option-set algebra, local device records, and the
// session event log are implemented and tested here.

/// Completion used by Darwin DeviceDiscovery C helpers. The optional error is
/// nil on a Darwin success path; Linux call sites that need a result should
/// pass a non-nil `DDError` (`unsupported` / `missingEntitlement`).
public typealias DDErrorHandler = ((any Error)?) -> Void

/// Darwin out-parameter sugar `AutoreleasingUnsafeMutablePointer<NSError?>`.
/// That type does not exist on Linux Swift; the portable alias is an
/// `UnsafeMutablePointer<NSError?>`.
public typealias DDErrorOutType = UnsafeMutablePointer<NSError?>

/// Handler invoked with a `DDDeviceEvent`. Darwin delivery queue and
/// exactly-once guarantees are unobserved; Linux callers are invoked
/// synchronously by the site that holds the handler.
public typealias DDEventHandler = (DDDeviceEvent) -> Void

/// Process-local identity of Apple's `DDDeviceProtocolString` newtype.
/// Raw string bytes are the C export names until an Apple-oracle observation
/// of the loaded Darwin constants lands.
public struct DDDeviceProtocolString: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let invalid = DDDeviceProtocolString(rawValue: "DDDeviceProtocolStringInvalid")
    public static let dial = DDDeviceProtocolString(rawValue: "DDDeviceProtocolStringDIAL")
}
