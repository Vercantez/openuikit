@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Network)
import Network
#endif

/// Linux starting point for Apple's public `DeviceDiscoveryUI` module.
///
/// Isolated host compilation has Foundation only. UIKit / SwiftUI / Network
/// APIs use the lookalikes in `DeviceDiscoveryUILookalikes.swift` until those
/// modules are on the link line. Linux has no device-discovery daemon, Wi-Fi
/// Aware, Bonjour browser, pairing sheet, or entitlement-gated advertiser:
/// every path that would present Apple UI, browse peers, or return a selected
/// `NWEndpoint` stays fail-closed.
///
/// Darwin types: https://developer.apple.com/documentation/devicediscoveryui

/// Linux host-test control. Hidden from ordinary `import DeviceDiscoveryUI`
/// clients and not part of Apple's public DeviceDiscoveryUI surface.
@_spi(OpenUIKitHost)
public enum DeviceDiscoveryUIHostControl {
    public static func isDefault(_ access: DDDevicePairingAccess) -> Bool {
        access.linuxKind == .default
    }

    public static func isPermanent(_ access: DDDevicePairingAccess) -> Bool {
        access.linuxKind == .permanent
    }

    public static func pairingAccess(
        of controller: DDDevicePairingViewController
    ) -> DDDevicePairingAccess {
        controller.linuxAccess
    }

    public static func viewDidLoadCount(
        of controller: DDDevicePairingViewController
    ) -> Int {
        controller.linuxViewDidLoadCount
    }

    public static func advertisingAttempted(
        of controller: DDDevicePairingViewController
    ) -> Bool {
        controller.linuxAdvertisingAttempted
    }

    public static func pairingViewAccess<Label, Fallback>(
        _ view: DevicePairingView<Label, Fallback>
    ) -> DDDevicePairingAccess {
        view.linuxAccess
    }

    public static func pairingViewLabel<Label, Fallback>(
        _ view: DevicePairingView<Label, Fallback>
    ) -> Label {
        view.linuxLabel
    }

    public static func pairingViewFallback<Label, Fallback>(
        _ view: DevicePairingView<Label, Fallback>
    ) -> Fallback {
        view.linuxFallback
    }

    public static func pickerAccess<Label, Fallback>(
        _ view: DevicePicker<Label, Fallback>
    ) -> DDDevicePairingAccess {
        view.linuxAccess
    }

    public static func pickerLabel<Label, Fallback>(
        _ view: DevicePicker<Label, Fallback>
    ) -> Label {
        view.linuxLabel
    }

    public static func pickerFallback<Label, Fallback>(
        _ view: DevicePicker<Label, Fallback>
    ) -> Fallback {
        view.linuxFallback
    }

    public static func pickerHasParametersClosure<Label, Fallback>(
        _ view: DevicePicker<Label, Fallback>
    ) -> Bool {
        view.linuxHasParametersClosure
    }

    public static func pickerOnSelectCount<Label, Fallback>(
        _ view: DevicePicker<Label, Fallback>
    ) -> Int {
        view.linuxOnSelectCount
    }

    /// Invokes the stored `onSelect` without claiming a device was chosen.
    /// Darwin calls `onSelect` after the user picks an endpoint; Linux never
    /// does that from public APIs.
    public static func invokeStoredOnSelect<Label, Fallback, Endpoint>(
        _ view: DevicePicker<Label, Fallback>,
        endpoint: Endpoint
    ) {
        view.linuxInvokeStoredOnSelect(endpoint)
    }
}

/// Fail-closed error for hardware, daemon, entitlement, or Apple-service
/// paths. Linux never invents a discovered device or pairing grant.
public enum DeviceDiscoveryUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}
