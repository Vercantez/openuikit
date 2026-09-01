@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Dispatch)
import Dispatch
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(Network)
import Network
#endif
#if canImport(Security)
import Security
#endif
#if canImport(ExtensionFoundation)
import ExtensionFoundation
#endif
// AccessorySetupKit is not imported here. `ASAccessory` APIs live in
// NetworkExtensionHotspot.swift and compile only under a usable combination:
// `(os(iOS) || os(Linux)) && canImport(AccessorySetupKit) && canImport(UIKit)`.
// `canImport(AccessorySetupKit)` alone is insufficient: macOS can see the
// module, but `ASPickerDisplayItem` requires `UIKit/UIKit.h`.

/// Portable Linux starting point for Apple's public `NetworkExtension` module.
///
/// Configuration objects, enumerations, and error types are real in-memory
/// values. Preference loading, VPN/hotspot/filter/relay activation, packet I/O,
/// and Apple entitlement-gated services fail closed. This module never
/// fabricates a connected tunnel, a joined hotspot, or a successful content
/// filter decision.
///
/// Asynchronous completions are delivered exactly once on
/// `NetworkExtensionHostCallback.queue` after the calling function returns.
/// That scheduler is a Linux host control, not Apple callback semantics.

// Placeholder string payloads use C identifier spelling. They are not
// oracle-verified iPhoneOS 26.1 values; coverage for these symbols is
// `declared` until a runtime probe records the Apple strings.
public let NEAppProxyErrorDomain = "NEAppProxyErrorDomain"
public let NEAppPushErrorDomain = "NEAppPushErrorDomain"
public let NEDNSProxyErrorDomain = "NEDNSProxyErrorDomain"
public let NEDNSSettingsErrorDomain = "NEDNSSettingsErrorDomain"
public let NEFilterErrorDomain = "NEFilterErrorDomain"
public let NEHotspotConfigurationErrorDomain = "NEHotspotConfigurationErrorDomain"
public let NERelayClientErrorDomain = "NERelayClientErrorDomain"
public let NERelayErrorDomain = "NERelayErrorDomain"
public let NETunnelProviderErrorDomain = "NETunnelProviderErrorDomain"
public let NEVPNConnectionErrorDomain = "NEVPNConnectionErrorDomain"
public let NEVPNErrorDomain = "NEVPNErrorDomain"

public let NEVPNConnectionStartOptionUsername = "NEVPNConnectionStartOptionUsername"
public let NEVPNConnectionStartOptionPassword = "NEVPNConnectionStartOptionPassword"
public let kNEHotspotHelperOptionDisplayName = "kNEHotspotHelperOptionDisplayName"

public let NEFilterProviderRemediationMapRemediationButtonTexts =
    "NEFilterProviderRemediationMapRemediationButtonTexts"
public let NEFilterProviderRemediationMapRemediationURLs =
    "NEFilterProviderRemediationMapRemediationURLs"

/// Unverified placeholder. The pinned graph does not record the exported value.
public var NEFilterFlowBytesMax: UInt64 { 0 }

public var NEFilterProviderRemediationURLFlowURL: String {
    "NEFilterProviderRemediationURLFlowURL"
}
public var NEFilterProviderRemediationURLFlowURLHostname: String {
    "NEFilterProviderRemediationURLFlowURLHostname"
}
public var NEFilterProviderRemediationURLOrganization: String {
    "NEFilterProviderRemediationURLOrganization"
}
public var NEFilterProviderRemediationURLUsername: String {
    "NEFilterProviderRemediationURLUsername"
}

extension NSNotification.Name {
    // Placeholder raw values use the Swift overlay names. They are not
    // oracle-verified Darwin notification strings.
    public static let NEVPNStatusDidChange = NSNotification.Name(
        "NEVPNStatusDidChange"
    )
    public static let NEVPNConfigurationChange = NSNotification.Name(
        "NEVPNConfigurationChange"
    )
    public static let NEFilterConfigurationDidChange = NSNotification.Name(
        "NEFilterConfigurationDidChange"
    )
    public static let NEDNSProxyConfigurationDidChange = NSNotification.Name(
        "NEDNSProxyConfigurationDidChange"
    )
    public static let NEDNSSettingsConfigurationDidChange = NSNotification.Name(
        "NEDNSSettingsConfigurationDidChange"
    )
    public static let NERelayConfigurationDidChange = NSNotification.Name(
        "NERelayConfigurationDidChange"
    )
    public static let NEURLFilterStatusDidChange = NSNotification.Name(
        "NEURLFilterStatusDidChange"
    )
    public static let NEURLFilterConfigurationDidChange = NSNotification.Name(
        "NEURLFilterConfigurationDidChange"
    )
}

extension NSMutableURLRequest {
    /// Hotspot helper binding is entitlement-gated and has no Linux host.
    /// The request is left unchanged.
    public func bind(to command: NEHotspotHelperCommand) {
        _ = command
    }
}

enum _NEHostBoundary {
    static let description =
        "NetworkExtension host services are unavailable on this platform"

    static func vpnError(
        _ code: NEVPNError.Code = .configurationInvalid
    ) -> NEVPNError {
        NEVPNError(
            code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    static func tunnelError(
        _ code: NETunnelProviderError.Code = .networkSettingsFailed
    ) -> NETunnelProviderError {
        NETunnelProviderError(
            code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    static func appPushError(
        _ code: NEAppPushManagerError.Code = .configurationInvalid
    ) -> NEAppPushManagerError {
        NEAppPushManagerError(
            code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    static func appProxyError(
        _ code: NEAppProxyFlowError.Code = .notConnected
    ) -> NEAppProxyFlowError {
        NEAppProxyFlowError(
            code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    static func nsError(domain: String, code: Int) -> NSError {
        NSError(
            domain: domain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    static func complete(
        _ handler: @escaping ((any Error)?) -> Void,
        _ error: any Error
    ) {
        _NEOnceDelivery(handler).schedule(error as (any Error)?)
    }

    static func completeOptional(
        _ handler: (((any Error)?) -> Void)?,
        _ error: any Error
    ) {
        guard let handler else { return }
        complete(handler, error)
    }

    static func completeNilError(_ handler: @escaping ((any Error)?) -> Void) {
        _NEOnceDelivery(handler).schedule(nil)
    }
}

@_spi(OpenUIKitHost)
public enum NetworkExtensionPOSIX {
    public static var inetFamily: sa_family_t {
        sa_family_t(AF_INET)
    }
}
