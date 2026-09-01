@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Dispatch)
import Dispatch
#endif
import Glibc

/// Portable Linux starting point for Apple's public `NetworkExtension` module.
///
/// Configuration objects, enumerations, and error types are real in-memory
/// values. Preference loading, VPN/hotspot/filter/relay activation, packet I/O,
/// and Apple entitlement-gated services fail closed. This module never
/// fabricates a connected tunnel, a joined hotspot, or a successful content
/// filter decision.

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

public let NEVPNConnectionStartOptionUsername = "Username"
public let NEVPNConnectionStartOptionPassword = "Password"
public let kNEHotspotHelperOptionDisplayName = "DisplayName"

public let NEFilterProviderRemediationMapRemediationButtonTexts =
    "RemediationButtonTexts"
public let NEFilterProviderRemediationMapRemediationURLs = "RemediationURLs"

/// Maximum peek window documented by Apple's `NEFilterFlow` header discussion.
public var NEFilterFlowBytesMax: UInt64 { 512 * 1024 }

public var NEFilterProviderRemediationURLFlowURL: String { "FLOW_URL" }
public var NEFilterProviderRemediationURLFlowURLHostname: String {
    "FLOW_URL_HOSTNAME"
}
public var NEFilterProviderRemediationURLOrganization: String { "ORGANIZATION" }
public var NEFilterProviderRemediationURLUsername: String { "USERNAME" }

extension NSNotification.Name {
    public static let NEVPNStatusDidChange = NSNotification.Name(
        "NEVPNStatusDidChangeNotification"
    )
    public static let NEVPNConfigurationChange = NSNotification.Name(
        "NEVPNConfigurationChangeNotification"
    )
    public static let NEFilterConfigurationDidChange = NSNotification.Name(
        "NEFilterConfigurationDidChangeNotification"
    )
    public static let NEDNSProxyConfigurationDidChange = NSNotification.Name(
        "NEDNSProxyConfigurationDidChangeNotification"
    )
    public static let NEDNSSettingsConfigurationDidChange = NSNotification.Name(
        "NEDNSSettingsConfigurationDidChangeNotification"
    )
    public static let NERelayConfigurationDidChange = NSNotification.Name(
        "NERelayConfigurationDidChangeNotification"
    )
    public static let NEURLFilterStatusDidChange = NSNotification.Name(
        "NEURLFilterStatusDidChangeNotification"
    )
    public static let NEURLFilterConfigurationDidChange = NSNotification.Name(
        "NEURLFilterConfigurationDidChangeNotification"
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

    static func complete(_ handler: ((any Error)?) -> Void, _ error: any Error) {
        handler(error)
    }

    static func completeOptional(
        _ handler: (((any Error)?) -> Void)?,
        _ error: any Error
    ) {
        handler?(error)
    }
}
