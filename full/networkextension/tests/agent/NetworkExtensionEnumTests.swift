@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testEnumRawValues() {
    let pairs: [(Int, Int)] = [
        (NEVPNStatus.invalid.rawValue, 0),
        (NEVPNStatus.disconnected.rawValue, 1),
        (NEVPNStatus.connecting.rawValue, 2),
        (NEVPNStatus.connected.rawValue, 3),
        (NEVPNStatus.reasserting.rawValue, 4),
        (NEVPNStatus.disconnecting.rawValue, 5),
        (NEProviderStopReason.none.rawValue, 0),
        (NEProviderStopReason.userInitiated.rawValue, 1),
        (NEProviderStopReason.providerFailed.rawValue, 2),
        (NEProviderStopReason.noNetworkAvailable.rawValue, 3),
        (NEProviderStopReason.unrecoverableNetworkChange.rawValue, 4),
        (NEProviderStopReason.providerDisabled.rawValue, 5),
        (NEProviderStopReason.authenticationCanceled.rawValue, 6),
        (NEProviderStopReason.configurationFailed.rawValue, 7),
        (NEProviderStopReason.idleTimeout.rawValue, 8),
        (NEProviderStopReason.configurationDisabled.rawValue, 9),
        (NEProviderStopReason.configurationRemoved.rawValue, 10),
        (NEProviderStopReason.superceded.rawValue, 11),
        (NEProviderStopReason.userLogout.rawValue, 12),
        (NEProviderStopReason.userSwitch.rawValue, 13),
        (NEProviderStopReason.connectionFailed.rawValue, 14),
        (NEProviderStopReason.sleep.rawValue, 15),
        (NEProviderStopReason.appUpdate.rawValue, 16),
        (NEProviderStopReason.internalError.rawValue, 17),
        (NEOnDemandRuleAction.connect.rawValue, 1),
        (NEOnDemandRuleAction.disconnect.rawValue, 2),
        (NEOnDemandRuleAction.evaluateConnection.rawValue, 3),
        (NEOnDemandRuleAction.ignore.rawValue, 4),
        (NEOnDemandRuleInterfaceType.any.rawValue, 0),
        (NEOnDemandRuleInterfaceType.wiFi.rawValue, 2),
        (NEOnDemandRuleInterfaceType.cellular.rawValue, 3),
        (NEEvaluateConnectionRuleAction.connectIfNeeded.rawValue, 1),
        (NEEvaluateConnectionRuleAction.neverConnect.rawValue, 2),
        (NEFilterAction.invalid.rawValue, 0),
        (NEFilterAction.allow.rawValue, 1),
        (NEFilterAction.drop.rawValue, 2),
        (NEFilterAction.remediate.rawValue, 3),
        (NEFilterAction.filterData.rawValue, 4),
        (NETrafficDirection.any.rawValue, 0),
        (NETrafficDirection.inbound.rawValue, 1),
        (NETrafficDirection.outbound.rawValue, 2),
        (NETunnelProviderRoutingMethod.destinationIP.rawValue, 1),
        (NETunnelProviderRoutingMethod.sourceApplication.rawValue, 2),
        (NEDNSProtocol.cleartext.rawValue, 1),
        (NEDNSProtocol.TLS.rawValue, 2),
        (NEDNSProtocol.HTTPS.rawValue, 3),
        (NEVPNIKEAuthenticationMethod.none.rawValue, 0),
        (NEVPNIKEAuthenticationMethod.certificate.rawValue, 1),
        (NEVPNIKEAuthenticationMethod.sharedSecret.rawValue, 2),
        (NEVPNIKEv2CertificateType.RSA.rawValue, 1),
        (NEVPNIKEv2CertificateType.ECDSA256.rawValue, 2),
        (NEVPNIKEv2CertificateType.ECDSA384.rawValue, 3),
        (NEVPNIKEv2CertificateType.ECDSA521.rawValue, 4),
        (NEVPNIKEv2CertificateType.ed25519.rawValue, 5),
        (NEVPNIKEv2CertificateType.RSAPSS.rawValue, 6),
        (NEVPNIKEv2DeadPeerDetectionRate.none.rawValue, 0),
        (NEVPNIKEv2DeadPeerDetectionRate.low.rawValue, 1),
        (NEVPNIKEv2DeadPeerDetectionRate.medium.rawValue, 2),
        (NEVPNIKEv2DeadPeerDetectionRate.high.rawValue, 3),
        (NEVPNIKEv2DiffieHellmanGroup.groupInvalid.rawValue, 0),
        (NEVPNIKEv2DiffieHellmanGroup.group14.rawValue, 14),
        (NEVPNIKEv2DiffieHellmanGroup.group15.rawValue, 15),
        (NEVPNIKEv2DiffieHellmanGroup.group16.rawValue, 16),
        (NEVPNIKEv2DiffieHellmanGroup.group17.rawValue, 17),
        (NEVPNIKEv2DiffieHellmanGroup.group18.rawValue, 18),
        (NEVPNIKEv2DiffieHellmanGroup.group19.rawValue, 19),
        (NEVPNIKEv2DiffieHellmanGroup.group20.rawValue, 20),
        (NEVPNIKEv2DiffieHellmanGroup.group21.rawValue, 21),
        (NEVPNIKEv2DiffieHellmanGroup.group31.rawValue, 31),
        (NEVPNIKEv2DiffieHellmanGroup.group32.rawValue, 32),
        (NEVPNIKEv2EncryptionAlgorithm.algorithmAES128.rawValue, 3),
        (NEVPNIKEv2EncryptionAlgorithm.algorithmAES256.rawValue, 4),
        (NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM.rawValue, 5),
        (NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM.rawValue, 6),
        (NEVPNIKEv2EncryptionAlgorithm.algorithmChaCha20Poly1305.rawValue, 7),
        (NEVPNIKEv2IntegrityAlgorithm.SHA256.rawValue, 3),
        (NEVPNIKEv2IntegrityAlgorithm.SHA384.rawValue, 4),
        (NEVPNIKEv2IntegrityAlgorithm.SHA512.rawValue, 5),
        (NEVPNIKEv2PostQuantumKeyExchangeMethod.methodNone.rawValue, 0),
        (NEVPNIKEv2PostQuantumKeyExchangeMethod.method36.rawValue, 36),
        (NEVPNIKEv2PostQuantumKeyExchangeMethod.method37.rawValue, 37),
        (NEVPNIKEv2TLSVersion.versionDefault.rawValue, 0),
        (NEVPNIKEv2TLSVersion.version1_0.rawValue, 1),
        (NEVPNIKEv2TLSVersion.version1_1.rawValue, 2),
        (NEVPNIKEv2TLSVersion.version1_2.rawValue, 3),
        (NWPathStatus.invalid.rawValue, 0),
        (NWPathStatus.satisfied.rawValue, 1),
        (NWPathStatus.unsatisfied.rawValue, 2),
        (NWPathStatus.satisfiable.rawValue, 3),
        (NWTCPConnectionState.invalid.rawValue, 0),
        (NWTCPConnectionState.connecting.rawValue, 1),
        (NWTCPConnectionState.waiting.rawValue, 2),
        (NWTCPConnectionState.connected.rawValue, 3),
        (NWTCPConnectionState.disconnected.rawValue, 4),
        (NWTCPConnectionState.cancelled.rawValue, 5),
        (NWUDPSessionState.invalid.rawValue, 0),
        (NWUDPSessionState.waiting.rawValue, 1),
        (NWUDPSessionState.preparing.rawValue, 2),
        (NWUDPSessionState.ready.rawValue, 3),
        (NWUDPSessionState.failed.rawValue, 4),
        (NWUDPSessionState.cancelled.rawValue, 5),
        (NEFilterManagerError.configurationInvalid.rawValue, 1),
        (NEFilterManagerError.configurationDisabled.rawValue, 2),
        (NEFilterManagerError.configurationStale.rawValue, 3),
        (NEFilterManagerError.configurationCannotBeRemoved.rawValue, 4),
        (NEFilterManagerError.configurationPermissionDenied.rawValue, 5),
        (NEFilterManagerError.configurationInternalError.rawValue, 6),
        (NEDNSProxyManagerError.configurationInvalid.rawValue, 1),
        (NEDNSProxyManagerError.configurationDisabled.rawValue, 2),
        (NEDNSProxyManagerError.configurationStale.rawValue, 3),
        (NEDNSProxyManagerError.configurationCannotBeRemoved.rawValue, 4),
        (NEDNSSettingsManagerError.configurationInvalid.rawValue, 1),
        (NEDNSSettingsManagerError.configurationDisabled.rawValue, 2),
        (NEDNSSettingsManagerError.configurationStale.rawValue, 3),
        (NEDNSSettingsManagerError.configurationCannotBeRemoved.rawValue, 4),
        (NERelayManagerError.configurationInvalid.rawValue, 1),
        (NERelayManagerError.configurationDisabled.rawValue, 2),
        (NERelayManagerError.configurationStale.rawValue, 3),
        (NERelayManagerError.configurationCannotBeRemoved.rawValue, 4),
        (NERelayManagerClientError.none.rawValue, 0),
        (NERelayManagerClientError.dnsFailed.rawValue, 1),
        (NERelayManagerClientError.serverUnreachable.rawValue, 2),
        (NERelayManagerClientError.serverDisconnected.rawValue, 3),
        (NERelayManagerClientError.certificateInvalid.rawValue, 4),
        (NERelayManagerClientError.certificateExpired.rawValue, 5),
        (NERelayManagerClientError.certificateMissing.rawValue, 6),
        (NERelayManagerClientError.serverCertificateInvalid.rawValue, 7),
        (NERelayManagerClientError.serverCertificateExpired.rawValue, 8),
        (NERelayManagerClientError.other.rawValue, 9),
        (NEVPNConnectionError.overslept.rawValue, 1),
        (NEVPNConnectionError.noNetworkAvailable.rawValue, 2),
        (NEVPNConnectionError.unrecoverableNetworkChange.rawValue, 3),
        (NEVPNConnectionError.configurationFailed.rawValue, 4),
        (NEVPNConnectionError.serverAddressResolutionFailed.rawValue, 5),
        (NEVPNConnectionError.serverNotResponding.rawValue, 6),
        (NEVPNConnectionError.serverDead.rawValue, 7),
        (NEVPNConnectionError.authenticationFailed.rawValue, 8),
        (NEVPNConnectionError.clientCertificateInvalid.rawValue, 9),
        (NEVPNConnectionError.clientCertificateNotYetValid.rawValue, 10),
        (NEVPNConnectionError.clientCertificateExpired.rawValue, 11),
        (NEVPNConnectionError.pluginFailed.rawValue, 12),
        (NEVPNConnectionError.configurationNotFound.rawValue, 13),
        (NEVPNConnectionError.pluginDisabled.rawValue, 14),
        (NEVPNConnectionError.negotiationFailed.rawValue, 15),
        (NEVPNConnectionError.serverDisconnected.rawValue, 16),
        (NEVPNConnectionError.serverCertificateInvalid.rawValue, 17),
        (NEVPNConnectionError.serverCertificateNotYetValid.rawValue, 18),
        (NEVPNConnectionError.serverCertificateExpired.rawValue, 19),
        (NEHotspotConfigurationError.unknown.rawValue, 0),
        (NEHotspotConfigurationError.invalid.rawValue, 1),
        (NEHotspotConfigurationError.invalidSSID.rawValue, 2),
        (NEHotspotConfigurationError.invalidWPAPassphrase.rawValue, 3),
        (NEHotspotConfigurationError.invalidWEPPassphrase.rawValue, 4),
        (NEHotspotConfigurationError.invalidEAPSettings.rawValue, 5),
        (NEHotspotConfigurationError.invalidHS20Settings.rawValue, 6),
        (NEHotspotConfigurationError.invalidHS20DomainName.rawValue, 7),
        (NEHotspotConfigurationError.userDenied.rawValue, 8),
        (NEHotspotConfigurationError.internal.rawValue, 9),
        (NEHotspotConfigurationError.pending.rawValue, 10),
        (NEHotspotConfigurationError.systemConfiguration.rawValue, 11),
        (NEHotspotConfigurationError.alreadyAssociated.rawValue, 12),
        (NEHotspotConfigurationError.applicationIsNotInForeground.rawValue, 13),
        (NEHotspotConfigurationError.invalidSSIDPrefix.rawValue, 14),
        (NEHotspotConfigurationError.userUnauthorized.rawValue, 15),
        (NEHotspotConfigurationError.joinOnceNotSupported.rawValue, 16),
        (NEHotspotConfigurationError.systemDenied.rawValue, 17),
        (NEHotspotHelperCommandType.none.rawValue, 0),
        (NEHotspotHelperCommandType.filterScanList.rawValue, 1),
        (NEHotspotHelperCommandType.evaluate.rawValue, 2),
        (NEHotspotHelperCommandType.authenticate.rawValue, 3),
        (NEHotspotHelperCommandType.presentUI.rawValue, 4),
        (NEHotspotHelperCommandType.maintain.rawValue, 5),
        (NEHotspotHelperCommandType.logoff.rawValue, 6),
        (NEHotspotHelperConfidence.none.rawValue, 0),
        (NEHotspotHelperConfidence.low.rawValue, 1),
        (NEHotspotHelperConfidence.high.rawValue, 2),
        (NEHotspotHelperResult.success.rawValue, 0),
        (NEHotspotHelperResult.failure.rawValue, 1),
        (NEHotspotHelperResult.uiRequired.rawValue, 2),
        (NEHotspotHelperResult.commandNotRecognized.rawValue, 3),
        (NEHotspotHelperResult.authenticationRequired.rawValue, 4),
        (NEHotspotHelperResult.unsupportedNetwork.rawValue, 5),
        (NEHotspotHelperResult.temporaryFailure.rawValue, 6),
        (NEHotspotNetworkSecurityType.unknown.rawValue, 0),
        (NEHotspotNetworkSecurityType.open.rawValue, 1),
        (NEHotspotNetworkSecurityType.WEP.rawValue, 2),
        (NEHotspotNetworkSecurityType.personal.rawValue, 3),
        (NEHotspotNetworkSecurityType.enterprise.rawValue, 4),
        (NEFilterReport.Event.newFlow.rawValue, 1),
        (NEFilterReport.Event.dataDecision.rawValue, 2),
        (NEFilterReport.Event.flowClosed.rawValue, 3),
        (NEHotspotEAPSettings.TLSVersion.version1_0.rawValue, 0),
        (NEHotspotEAPSettings.TLSVersion.version1_1.rawValue, 1),
        (NEHotspotEAPSettings.TLSVersion.version1_2.rawValue, 2),
        (NEHotspotEAPSettings.EAPType.EAPTLS.rawValue, 13),
        (NEHotspotEAPSettings.EAPType.EAPTTLS.rawValue, 21),
        (NEHotspotEAPSettings.EAPType.EAPPEAP.rawValue, 25),
        (NEHotspotEAPSettings.EAPType.EAPFAST.rawValue, 43),
        (NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationPAP.rawValue, 0),
        (NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationCHAP.rawValue, 1),
        (NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationMSCHAP.rawValue, 2),
        (NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationMSCHAPv2.rawValue, 3),
        (NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationEAP.rawValue, 4),
        (NEURLFilter.Verdict.unknown.rawValue, 1),
        (NEURLFilter.Verdict.allow.rawValue, 2),
        (NEURLFilter.Verdict.deny.rawValue, 3),
        (NEURLFilterManager.Status.invalid.rawValue, 0),
        (NEURLFilterManager.Status.stopped.rawValue, 1),
        (NEURLFilterManager.Status.starting.rawValue, 2),
        (NEURLFilterManager.Status.running.rawValue, 3),
        (NEURLFilterManager.Status.stopping.rawValue, 4),
        (NEURLFilterManager.Error.configurationUnchanged.rawValue, 1),
        (NEURLFilterManager.Error.configurationInvalid.rawValue, 2),
        (NEURLFilterManager.Error.configurationDisabled.rawValue, 3),
        (NEURLFilterManager.Error.configurationStale.rawValue, 4),
        (NEURLFilterManager.Error.configurationCannotBeRemoved.rawValue, 5),
        (NEURLFilterManager.Error.configurationPermissionDenied.rawValue, 6),
        (NEURLFilterManager.Error.configurationInternalError.rawValue, 7),
        (NEURLFilterManager.Error.configurationNotLoaded.rawValue, 8),
        (NEURLFilterManager.Error.serverSetupIncomplete.rawValue, 9),
        (NEURLFilterManager.Error.internalError.rawValue, 10),
        (NEURLFilterManager.Error.extensionCancelled.rawValue, 11),
        (NEURLFilterManager.Error.extensionNotFound.rawValue, 12),
        (NEURLFilterManager.Error.extensionFailedToLoad.rawValue, 13),
        (NEURLFilterManager.Error.unknown.rawValue, 14),
        (NEVPNError.Code.configurationInvalid.rawValue, 1),
        (NEVPNError.Code.configurationDisabled.rawValue, 2),
        (NEVPNError.Code.connectionFailed.rawValue, 3),
        (NEVPNError.Code.configurationStale.rawValue, 4),
        (NEVPNError.Code.configurationReadWriteFailed.rawValue, 5),
        (NEVPNError.Code.configurationUnknown.rawValue, 6),
        (NEAppProxyFlowError.Code.notConnected.rawValue, 1),
        (NEAppProxyFlowError.Code.peerReset.rawValue, 2),
        (NEAppProxyFlowError.Code.hostUnreachable.rawValue, 3),
        (NEAppProxyFlowError.Code.invalidArgument.rawValue, 4),
        (NEAppProxyFlowError.Code.aborted.rawValue, 5),
        (NEAppProxyFlowError.Code.refused.rawValue, 6),
        (NEAppProxyFlowError.Code.timedOut.rawValue, 7),
        (NEAppProxyFlowError.Code.internal.rawValue, 8),
        (NEAppProxyFlowError.Code.datagramTooLarge.rawValue, 9),
        (NEAppProxyFlowError.Code.readAlreadyPending.rawValue, 10),
        (NEAppPushManagerError.Code.configurationInvalid.rawValue, 1),
        (NEAppPushManagerError.Code.configurationNotLoaded.rawValue, 2),
        (NEAppPushManagerError.Code.internalError.rawValue, 3),
        (NEAppPushManagerError.Code.inactiveSession.rawValue, 4),
        (NETunnelProviderError.Code.networkSettingsInvalid.rawValue, 1),
        (NETunnelProviderError.Code.networkSettingsCanceled.rawValue, 2),
        (NETunnelProviderError.Code.networkSettingsFailed.rawValue, 3),
    ]
    for (observed, expected) in pairs {
        precondition(observed == expected)
        touchHashable(observed)
    }
    touchHashable(NEVPNStatus.connected)
    touchHashable(NEProviderStopReason.userInitiated)
    touchHashable(NEOnDemandRuleAction.connect)
    touchHashable(NEFilterAction.drop)
    touchHashable(NEVPNConnectionError.pluginFailed)
    touchHashable(NEHotspotConfigurationError.internal)
    touchHashable(NEURLFilter.Verdict.deny)
    touchHashable(NEURLFilterManager.Error.unknown)
    touchHashable(NEURLFilterManager.Status.running)
    touchHashable(NEFilterReport.Event.newFlow)
    touchHashable(NEHotspotEAPSettings.EAPType.EAPTLS)
    touchHashable(NEHotspotManager.Error.configurationInvalid)
    _ = NEVPNStatus(rawValue: 0)
    _ = NEProviderStopReason(rawValue: 1)
    _ = NEDNSProtocol(rawValue: 3)
    _ = NEURLFilter.Verdict(rawValue: 1)
    _ = NEURLFilterManager.Error(rawValue: 14)
    _ = NEURLFilterManager.Status(rawValue: 0)
    _ = NEAppProxyFlowError.Code(rawValue: 1)
    _ = NEVPNError.Code(rawValue: 1)
    _ = NETunnelProviderError.Code(rawValue: 3)
    _ = NEHotspotEAPSettings.TLSVersion(rawValue: 2)
    _ = NEHotspotEAPSettings.TTLSInnerAuthenticationType(rawValue: 3)
    _ = NEFilterReport.Event(rawValue: 1)
    precondition(NEVPNStatus.disconnected != NEVPNStatus.connected)
    precondition(NEURLFilter.Verdict(rawValue: 0) == nil)
    _ = NEVPNStatus.RawValue.self
    _ = NEURLFilterManager.Error.RawValue.self
    _ = NEURLFilterManager.Status.RawValue.self
}

func testAuditedRawValues() {

precondition(NEURLFilter.Verdict.unknown.rawValue == 1)
precondition(NEURLFilter.Verdict.allow.rawValue == 2)
precondition(NEURLFilter.Verdict.deny.rawValue == 3)
precondition(NEURLFilter.Verdict(rawValue: 0) == nil)
precondition(NEURLFilter.Verdict(rawValue: 1) == .unknown)
precondition(NEURLFilter.Verdict(rawValue: 2) == .allow)
precondition(NEURLFilter.Verdict(rawValue: 3) == .deny)

precondition(NEURLFilterManager.Status.invalid.rawValue == 0)
precondition(NEURLFilterManager.Status.stopped.rawValue == 1)
precondition(NEURLFilterManager.Status.starting.rawValue == 2)
precondition(NEURLFilterManager.Status.running.rawValue == 3)
precondition(NEURLFilterManager.Status.stopping.rawValue == 4)

precondition(NEURLFilterManager.Error.configurationUnchanged.rawValue == 1)
precondition(NEURLFilterManager.Error.configurationInvalid.rawValue == 2)
precondition(NEURLFilterManager.Error.configurationDisabled.rawValue == 3)
precondition(NEURLFilterManager.Error.configurationStale.rawValue == 4)
precondition(NEURLFilterManager.Error.configurationCannotBeRemoved.rawValue == 5)
precondition(NEURLFilterManager.Error.configurationPermissionDenied.rawValue == 6)
precondition(NEURLFilterManager.Error.configurationInternalError.rawValue == 7)
precondition(NEURLFilterManager.Error.configurationNotLoaded.rawValue == 8)
precondition(NEURLFilterManager.Error.serverSetupIncomplete.rawValue == 9)
precondition(NEURLFilterManager.Error.internalError.rawValue == 10)
precondition(NEURLFilterManager.Error.extensionCancelled.rawValue == 11)
precondition(NEURLFilterManager.Error.extensionNotFound.rawValue == 12)
precondition(NEURLFilterManager.Error.extensionFailedToLoad.rawValue == 13)
precondition(NEURLFilterManager.Error.unknown.rawValue == 14)
precondition(NEURLFilterManager.Error(rawValue: 0) == nil)

precondition(NEVPNConnectionError.overslept.rawValue == 1)
precondition(NEVPNConnectionError.noNetworkAvailable.rawValue == 2)
precondition(NEVPNConnectionError.unrecoverableNetworkChange.rawValue == 3)
precondition(NEVPNConnectionError.configurationFailed.rawValue == 4)
precondition(NEVPNConnectionError.serverAddressResolutionFailed.rawValue == 5)
precondition(NEVPNConnectionError.serverNotResponding.rawValue == 6)
precondition(NEVPNConnectionError.serverDead.rawValue == 7)
precondition(NEVPNConnectionError.authenticationFailed.rawValue == 8)
precondition(NEVPNConnectionError.clientCertificateInvalid.rawValue == 9)
precondition(NEVPNConnectionError.clientCertificateNotYetValid.rawValue == 10)
precondition(NEVPNConnectionError.clientCertificateExpired.rawValue == 11)
precondition(NEVPNConnectionError.pluginFailed.rawValue == 12)
precondition(NEVPNConnectionError.configurationNotFound.rawValue == 13)
precondition(NEVPNConnectionError.pluginDisabled.rawValue == 14)
precondition(NEVPNConnectionError.negotiationFailed.rawValue == 15)
precondition(NEVPNConnectionError.serverDisconnected.rawValue == 16)
precondition(NEVPNConnectionError.serverCertificateInvalid.rawValue == 17)
precondition(NEVPNConnectionError.serverCertificateNotYetValid.rawValue == 18)
precondition(NEVPNConnectionError.serverCertificateExpired.rawValue == 19)
precondition(NEVPNConnectionError(rawValue: 0) == nil)
precondition(NEVPNConnectionError(rawValue: 12) == .pluginFailed)
precondition(NEVPNConnectionError(rawValue: 9) == .clientCertificateInvalid)
}

func testErrorHashableSurface() {
touchHashable(NEAppProxyFlowError.Code.datagramTooLarge)
touchHashable(NEAppProxyFlowError.Code.hostUnreachable)
touchHashable(NEAppProxyFlowError.Code.internal)
touchHashable(NEAppProxyFlowError.Code.invalidArgument)
touchHashable(NEAppProxyFlowError.Code.peerReset)
touchHashable(NEAppProxyFlowError.Code.readAlreadyPending)
touchHashable(NEAppProxyFlowError.Code.refused)
touchHashable(NEAppProxyFlowError.Code.timedOut)
touchHashable(NEAppPushManagerError.Code.internalError)
touchHashable(NEDNSProxyManagerError.configurationDisabled)
touchHashable(NEDNSProxyManagerError.configurationInvalid)
touchHashable(NEDNSProxyManagerError.configurationStale)
touchHashable(NEDNSSettingsManagerError.configurationDisabled)
touchHashable(NEDNSSettingsManagerError.configurationInvalid)
touchHashable(NEDNSSettingsManagerError.configurationStale)
touchHashable(NEEvaluateConnectionRuleAction.neverConnect)
touchHashable(NEFilterAction.allow)
touchHashable(NEFilterAction.filterData)
touchHashable(NEFilterAction.remediate)
touchHashable(NEFilterManagerError.configurationDisabled)
touchHashable(NEFilterManagerError.configurationInternalError)
touchHashable(NEFilterManagerError.configurationStale)
touchHashable(NEFilterReport.Event.dataDecision)
touchHashable(NEFilterReport.Event.flowClosed)
touchHashable(NEHotspotEAPSettings.EAPType.EAPFAST)
touchHashable(NEHotspotEAPSettings.EAPType.EAPPEAP)
touchHashable(NEHotspotEAPSettings.EAPType.EAPTTLS)
for code in [
    NEHotspotConfigurationError.alreadyAssociated,
    .applicationIsNotInForeground,
    .invalid,
    .invalidEAPSettings,
    .invalidHS20DomainName,
    .invalidHS20Settings,
    .invalidSSID,
    .invalidSSIDPrefix,
    .invalidWEPPassphrase,
    .invalidWPAPassphrase,
    .joinOnceNotSupported,
    .pending,
    .systemConfiguration,
    .systemDenied,
    .unknown,
    .userDenied,
    .userUnauthorized,
] as [NEHotspotConfigurationError] {
    touchHashable(code)
    _ = NEHotspotConfigurationError(rawValue: code.rawValue)
}
touchHashable(NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationCHAP)
touchHashable(NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationEAP)
touchHashable(NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationMSCHAP)
touchHashable(NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationPAP)
for command in [
    NEHotspotHelperCommandType.authenticate,
    .evaluate,
    .filterScanList,
    .logoff,
    .maintain,
    .none,
    .presentUI,
] as [NEHotspotHelperCommandType] {
    touchHashable(command)
    _ = NEHotspotHelperCommandType(rawValue: command.rawValue)
}
touchHashable(NEHotspotHelperConfidence.high)
touchHashable(NEHotspotHelperConfidence.none)
for result in [
    NEHotspotHelperResult.authenticationRequired,
    .commandNotRecognized,
    .success,
    .temporaryFailure,
    .uiRequired,
    .unsupportedNetwork,
] as [NEHotspotHelperResult] {
    touchHashable(result)
    _ = NEHotspotHelperResult(rawValue: result.rawValue)
}
touchHashable(NEHotspotNetworkSecurityType.enterprise)
touchHashable(NEHotspotNetworkSecurityType.open)
touchHashable(NEHotspotNetworkSecurityType.personal)
touchHashable(NEHotspotNetworkSecurityType.WEP)
touchHashable(NEOnDemandRuleInterfaceType.any)
touchHashable(NEOnDemandRuleInterfaceType.cellular)
for reason in NEProviderStopReason.none.rawValue...NEProviderStopReason.internalError.rawValue {
    if let value = NEProviderStopReason(rawValue: reason) {
        touchHashable(value)
    }
}
for code in 0...9 {
    if let value = NERelayManagerClientError(rawValue: code) {
        touchHashable(value)
    }
}
touchHashable(NERelayManagerError.configurationDisabled)
touchHashable(NERelayManagerError.configurationInvalid)
touchHashable(NERelayManagerError.configurationStale)
touchHashable(NETrafficDirection.inbound)
touchHashable(NETrafficDirection.outbound)
touchHashable(NETunnelProviderError.networkSettingsCanceled)
touchHashable(NETunnelProviderError.networkSettingsInvalid)
touchHashable(NETunnelProviderRoutingMethod.sourceApplication)
touchHashable(NEVPNError.configurationDisabled)
touchHashable(NEVPNError.configurationStale)
touchHashable(NEVPNError.configurationUnknown)
touchHashable(NEVPNIKEAuthenticationMethod.none)
for cert in [
    NEVPNIKEv2CertificateType.ECDSA384,
    .ECDSA521,
    .ed25519,
    .RSA,
    .RSAPSS,
] as [NEVPNIKEv2CertificateType] {
    touchHashable(cert)
}
touchHashable(NEVPNIKEv2DeadPeerDetectionRate.high)
touchHashable(NEVPNIKEv2DeadPeerDetectionRate.low)
touchHashable(NEVPNIKEv2DeadPeerDetectionRate.none)
for group in [
    0, 14, 15, 16, 17, 18, 19, 20, 21, 31, 32,
] {
    if let value = NEVPNIKEv2DiffieHellmanGroup(rawValue: group) {
        touchHashable(value)
    }
}
touchHashable(NEVPNIKEv2EncryptionAlgorithm.algorithmAES128)
touchHashable(NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM)
touchHashable(NEVPNIKEv2EncryptionAlgorithm.algorithmAES256)
touchHashable(NEVPNIKEv2IntegrityAlgorithm.SHA384)
touchHashable(NEVPNIKEv2IntegrityAlgorithm.SHA512)
touchHashable(NEVPNIKEv2PostQuantumKeyExchangeMethod.method36)
touchHashable(NEVPNIKEv2PostQuantumKeyExchangeMethod.method37)
touchHashable(NEVPNIKEv2PostQuantumKeyExchangeMethod.methodNone)
touchHashable(NEVPNIKEv2TLSVersion.version1_0)
touchHashable(NEVPNIKEv2TLSVersion.version1_1)
touchHashable(NEVPNIKEv2TLSVersion.versionDefault)
touchHashable(NEVPNStatus.connecting)
touchHashable(NEVPNStatus.disconnecting)
touchHashable(NEVPNStatus.reasserting)
touchHashable(NWPathStatus.invalid)
touchHashable(NWPathStatus.satisfiable)
touchHashable(NWPathStatus.satisfied)
touchHashable(NWTCPConnectionState.connected)
touchHashable(NWTCPConnectionState.connecting)
touchHashable(NWTCPConnectionState.invalid)
touchHashable(NWTCPConnectionState.waiting)
touchHashable(NWUDPSessionState.invalid)
touchHashable(NWUDPSessionState.preparing)
touchHashable(NWUDPSessionState.ready)
touchHashable(NWUDPSessionState.waiting)
touchHashable(NEHotspotManager.Error.internalError)
touchHashable(NEHotspotManager.Error.configurationInvalid)

_ = NEAppProxyFlowError(.hostUnreachable).errorUserInfo
_ = NEAppProxyFlowError.hostUnreachable
_ = NEAppProxyFlowError.invalidArgument
_ = NEAppProxyFlowError.datagramTooLarge
_ = NEAppProxyFlowError.readAlreadyPending
_ = NEAppProxyFlowError.refused
_ = NEAppProxyFlowError.internal
_ = NEAppProxyFlowError.timedOut
_ = NEAppProxyFlowError.peerReset
_ = NEAppProxyFlowError(.internal).localizedDescription
_ = NEAppPushManagerError.internalError
_ = NEAppPushManagerError(.internalError).localizedDescription
_ = NETunnelProviderError.networkSettingsInvalid
_ = NETunnelProviderError.networkSettingsCanceled
_ = NETunnelProviderError(.networkSettingsInvalid).localizedDescription
_ = NEVPNError.configurationStale
_ = NEVPNError.configurationUnknown
_ = NEVPNError.configurationDisabled
_ = NEVPNError(.configurationUnknown).localizedDescription
precondition(NEVPNError(.configurationInvalid) != NEVPNError(.connectionFailed))
_ = NEVPNError.Code(rawValue: 1)
_ = NEVPNStatus(rawValue: 0)
_ = NWPathStatus(rawValue: 1)
_ = NEDNSProtocol(rawValue: 1)
_ = NEFilterAction(rawValue: 1)
_ = NWUDPSessionState(rawValue: 1)
_ = NETrafficDirection(rawValue: 1)
_ = NEAppProxyFlowError.Code(rawValue: 1)
_ = NEFilterReport.Event(rawValue: 1)
_ = NERelayManagerError(rawValue: 1)
_ = NEFilterManagerError(rawValue: 1)
_ = NEOnDemandRuleAction(rawValue: 1)
_ = NEProviderStopReason(rawValue: 1)
_ = NEVPNIKEv2TLSVersion(rawValue: 0)
_ = NWTCPConnectionState(rawValue: 1)
_ = NEAppPushManagerError.Code(rawValue: 1)
_ = NETunnelProviderError.Code(rawValue: 1)
_ = NEDNSProxyManagerError(rawValue: 1)
_ = NEDNSSettingsManagerError(rawValue: 1)
_ = NEHotspotHelperConfidence(rawValue: 1)
_ = NERelayManagerClientError(rawValue: 1)
_ = NEVPNIKEv2CertificateType(rawValue: 1)
_ = NEHotspotHelperCommandType(rawValue: 1)
_ = NEHotspotNetworkSecurityType(rawValue: 1)
_ = NEVPNIKEAuthenticationMethod(rawValue: 1)
_ = NEVPNIKEv2DiffieHellmanGroup(rawValue: 14)
_ = NEVPNIKEv2IntegrityAlgorithm(rawValue: 3)
_ = NEHotspotEAPSettings.EAPType(rawValue: 13)
_ = NETunnelProviderRoutingMethod(rawValue: 1)
_ = NEVPNIKEv2EncryptionAlgorithm(rawValue: 3)
_ = NEEvaluateConnectionRuleAction(rawValue: 1)
_ = NEVPNIKEv2DeadPeerDetectionRate(rawValue: 1)
_ = NEHotspotEAPSettings.TLSVersion(rawValue: 2)
_ = NEVPNIKEv2PostQuantumKeyExchangeMethod(rawValue: 0)
_ = NEHotspotEAPSettings.TTLSInnerAuthenticationType(rawValue: 0)
_ = NEURLFilterManager.Status(rawValue: 0)
_ = NEURLFilterManager.Error.RawValue.self
_ = NEURLFilterManager.Status.RawValue.self
}
