@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testConstantsAndNotifications() {

// Payloads are C-identifier placeholders, not Apple-oracle strings.
// Tests only prove the symbols exist and are usable as keys.
_ = NEVPNErrorDomain
_ = NEVPNConnectionErrorDomain
_ = NETunnelProviderErrorDomain
_ = NEAppProxyErrorDomain
_ = NEAppPushErrorDomain
_ = NEDNSProxyErrorDomain
_ = NEDNSSettingsErrorDomain
_ = NEFilterErrorDomain
_ = NEHotspotConfigurationErrorDomain
_ = NERelayErrorDomain
_ = NERelayClientErrorDomain
_ = NEVPNConnectionStartOptionUsername
_ = NEVPNConnectionStartOptionPassword
_ = kNEHotspotHelperOptionDisplayName
_ = NEFilterFlowBytesMax
_ = NEFilterProviderRemediationMapRemediationURLs
_ = NEFilterProviderRemediationMapRemediationButtonTexts
_ = NEFilterProviderRemediationURLFlowURL
_ = NEFilterProviderRemediationURLFlowURLHostname
_ = NEFilterProviderRemediationURLOrganization
_ = NEFilterProviderRemediationURLUsername
_ = NSNotification.Name.NEVPNStatusDidChange
_ = NSNotification.Name.NEVPNConfigurationChange
_ = NSNotification.Name.NEFilterConfigurationDidChange
_ = NSNotification.Name.NEDNSProxyConfigurationDidChange
_ = NSNotification.Name.NEDNSSettingsConfigurationDidChange
_ = NSNotification.Name.NERelayConfigurationDidChange
_ = NSNotification.Name.NEURLFilterStatusDidChange
_ = NSNotification.Name.NEURLFilterConfigurationDidChange

precondition(NEVPNStatus.disconnected.rawValue == 1)
precondition(NEVPNStatus.connected.rawValue == 3)
precondition(NEOnDemandRuleAction.connect.rawValue == 1)
precondition(NEDNSProtocol.HTTPS.rawValue == 3)
precondition(NEFilterAction.drop.rawValue == 2)
precondition(NEProviderStopReason.userInitiated.rawValue == 1)
precondition(NEVPNError.configurationInvalid.rawValue == 1)
precondition(NEAppProxyFlowError.notConnected.rawValue == 1)
precondition(NETunnelProviderError.networkSettingsFailed.rawValue == 3)
precondition(NEAppPushManagerError.inactiveSession.rawValue == 4)
}
