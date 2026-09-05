@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testErrorBridging() {
    let vpn = NEVPNError(.configurationInvalid)
    precondition(vpn.code == .configurationInvalid)
    precondition(vpn.errorCode == 1)
    precondition(NEVPNError.errorDomain == NEVPNErrorDomain)
    _ = vpn.errorUserInfo
    _ = vpn.localizedDescription
    precondition(NEVPNError(.configurationInvalid) != NEVPNError(.connectionFailed))
    touchHashable(vpn)
    touchHashable(NEVPNError.configurationReadWriteFailed)
    _ = NEVPNError.configurationInvalid
    _ = NEVPNError.connectionFailed

    let proxy = NEAppProxyFlowError(.notConnected)
    precondition(proxy.code == .notConnected)
    precondition(NEAppProxyFlowError.errorDomain == NEAppProxyErrorDomain)
    _ = proxy.errorUserInfo
    _ = proxy.localizedDescription
    _ = NEAppProxyFlowError.aborted
    touchHashable(proxy)

    let push = NEAppPushManagerError(.inactiveSession)
    precondition(push.code == .inactiveSession)
    precondition(NEAppPushManagerError.errorDomain == NEAppPushErrorDomain)
    _ = push.errorUserInfo
    _ = NEAppPushManagerError.configurationInvalid

    let tunnel = NETunnelProviderError(.networkSettingsFailed)
    precondition(tunnel.code == .networkSettingsFailed)
    precondition(NETunnelProviderError.errorDomain == NETunnelProviderErrorDomain)
    _ = tunnel.errorUserInfo
    _ = NETunnelProviderError.networkSettingsCanceled

    let filter = NEFilterManagerError.configurationInvalid
    precondition(filter.rawValue == 1)
    _ = filter.localizedDescription
    let dns = NEDNSProxyManagerError.configurationDisabled
    _ = dns.localizedDescription
    let settings = NEDNSSettingsManagerError.configurationStale
    _ = settings.localizedDescription
    let relay = NERelayManagerError.configurationInvalid
    _ = relay.localizedDescription
    let hotspot = NEHotspotConfigurationError.internal
    _ = hotspot.localizedDescription
    let url = NEURLFilterManager.Error.configurationInvalid
    _ = url.helpAnchor
    _ = url.failureReason
    _ = url.errorDescription
    _ = url.recoverySuggestion
    _ = url.localizedDescription
    _ = NEHotspotManager.Error.internalError.localizedDescription
}
