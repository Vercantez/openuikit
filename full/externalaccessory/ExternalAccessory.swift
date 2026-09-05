@_exported import Foundation
@preconcurrency import Dispatch

// Linux starting point for Apple's ExternalAccessory. MFi accessory
// transport, the External Accessory daemon, Bluetooth picker UI, and
// Wireless Accessory Configuration are fail-closed: Linux has no those
// services. Value types, error codes, notification names, option-set
// algebra, and the manager/browser state machines are implemented here.

// MARK: - UIKit / Dispatch overlays (not declared dependencies)

/// UIKit is not a declared dependency of this seed. Configuration UI is
/// fail-closed; the parameter is accepted as `NSObject` so the selector
/// type-checks.
public typealias UIViewController = NSObject

/// Darwin `dispatch_queue_t` overlay used by `EAWiFiUnconfiguredAccessoryBrowser`.
public typealias dispatch_queue_t = DispatchQueue

// MARK: - Notification names and user-info keys

extension NSNotification.Name {
    /// Process-local identity of Apple's `EAAccessoryDidConnectNotification`.
    public static let EAAccessoryDidConnect = NSNotification.Name(
        "EAAccessoryDidConnectNotification"
    )

    /// Process-local identity of Apple's `EAAccessoryDidDisconnectNotification`.
    public static let EAAccessoryDidDisconnect = NSNotification.Name(
        "EAAccessoryDidDisconnectNotification"
    )
}

/// User-info key for the accessory object on connect/disconnect notifications.
public let EAAccessoryKey = "EAAccessoryKey"

/// User-info key for the accessory selected in the Bluetooth picker.
public let EAAccessorySelectedKey = "EAAccessorySelectedKey"

/// `NSError` domain for `EABluetoothAccessoryPickerError`.
public let EABluetoothAccessoryPickerErrorDomain = "EABluetoothAccessoryPickerErrorDomain"

/// Sentinel connection identifier. Apple's header assigns `0`.
public var EAConnectionIDNone: Int { 0 }

/// Completion handler for the ObjC Bluetooth accessory picker.
public typealias EABluetoothAccessoryPickerCompletion = ((any Error)?) -> Void

// MARK: - Wi-Fi unconfigured accessory browser state

/// Browser state. Sequential `NSInteger` values matching the API-digester
/// child order and the pinned dotnet-macios `Native` enum.
public enum EAWiFiUnconfiguredAccessoryBrowserState: Int, Equatable, Hashable, Sendable {
    case wiFiUnavailable = 0
    case stopped = 1
    case searching = 2
    case configuring = 3
}

/// Configuration outcome. Sequential `NSInteger` values matching the
/// API-digester child order and the pinned dotnet-macios `Native` enum.
public enum EAWiFiUnconfiguredAccessoryConfigurationStatus: Int, Equatable, Hashable, Sendable {
    case success = 0
    case userCancelledConfiguration = 1
    case failed = 2
}

// MARK: - Wi-Fi unconfigured accessory properties

/// Feature bits advertised by an MFI Wireless Accessory Configuration
/// accessory. Bit positions match `EAWiFiUnconfiguredAccessoryPropertySupports*`
/// (`1 << 0`, `1 << 1`, `1 << 2`) from the pinned macios bindings.
public struct EAWiFiUnconfiguredAccessoryProperties: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let propertySupportsAirPlay = EAWiFiUnconfiguredAccessoryProperties(
        rawValue: 1 << 0
    )
    public static let propertySupportsAirPrint = EAWiFiUnconfiguredAccessoryProperties(
        rawValue: 1 << 1
    )
    public static let propertySupportsHomeKit = EAWiFiUnconfiguredAccessoryProperties(
        rawValue: 1 << 2
    )
}
