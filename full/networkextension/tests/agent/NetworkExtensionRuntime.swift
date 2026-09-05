@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


func requireVPNError(_ error: Error?, code: NEVPNError.Code) {
    guard let error = error as? NEVPNError else {
        fatalError("expected NEVPNError, got \(String(describing: error))")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(NEVPNError.errorDomain == NEVPNErrorDomain)
}

final class LockedState<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    @discardableResult
    func withLock<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}

func drainHostQueue() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        NetworkExtensionHostCallback.schedule {
            continuation.resume()
        }
    }
}

func neDrain() {
    let _: Int = neCallback { handler in
        NetworkExtensionHostCallback.schedule {
            handler(0)
        }
    }
}

func neWait(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + 20) != .success {
        fatalError("timed out waiting for NetworkExtension host callback")
    }
}

func awaitHostCallback<T>(
    _ body: (@escaping (T) -> Void) -> Void
) async -> T {
    await withCheckedContinuation { continuation in
        let state = LockedState((returned: false, count: 0, captured: false, value: Optional<T>.none))
        NetworkExtensionHostCallback.holdDelivery()
        body { value in
            precondition(
                NetworkExtensionHostCallback.isCurrentQueue,
                "completion was not delivered on NetworkExtensionHostCallback.queue"
            )
            let shouldResume = state.withLock { snapshot -> Bool in
                precondition(snapshot.returned, "callback before API return was recorded")
                snapshot.count += 1
                precondition(snapshot.count == 1, "callback delivered more than once")
                if snapshot.captured {
                    return false
                }
                snapshot.captured = true
                snapshot.value = value
                return true
            }
            if shouldResume {
                continuation.resume(returning: value)
            }
        }
        let countBeforeRelease = state.withLock { snapshot -> Int in
            snapshot.returned = true
            return snapshot.count
        }
        precondition(countBeforeRelease == 0, "callback ran before releaseDelivery")
        NetworkExtensionHostCallback.releaseDelivery()
    }
}

func neCallback<T>(_ body: (@escaping (T) -> Void) -> Void) -> T {
    let state = LockedState((returned: false, count: 0, captured: false, value: Optional<T>.none))
    let semaphore = DispatchSemaphore(value: 0)
    NetworkExtensionHostCallback.holdDelivery()
    body { value in
        precondition(
            NetworkExtensionHostCallback.isCurrentQueue,
            "completion was not delivered on NetworkExtensionHostCallback.queue"
        )
        let shouldResume = state.withLock { snapshot -> Bool in
            precondition(snapshot.returned, "callback before API return was recorded")
            snapshot.count += 1
            precondition(snapshot.count == 1, "callback delivered more than once")
            if snapshot.captured {
                return false
            }
            snapshot.captured = true
            snapshot.value = value
            return true
        }
        if shouldResume {
            semaphore.signal()
        }
    }
    let countBeforeRelease = state.withLock { snapshot -> Int in
        snapshot.returned = true
        return snapshot.count
    }
    precondition(countBeforeRelease == 0, "callback ran before releaseDelivery")
    NetworkExtensionHostCallback.releaseDelivery()
    precondition(semaphore.wait(timeout: .now() + 10) == .success)
    return state.withLock { snapshot in
        guard let value = snapshot.value else {
            fatalError("host callback did not capture a value")
        }
        return value
    }
}

func requireCopy<T: NSObject & NSCopying>(
    _ value: T,
    as type: T.Type = T.self,
    _ check: (T, T) -> Void
) {
    guard let copied = value.copy(with: nil) as? T else {
        fatalError("copy(with:) did not return \(type)")
    }
    precondition(copied !== value)
    precondition(Swift.type(of: copied) == Swift.type(of: value))
    check(value, copied)
}

func roundTripSecure<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(
            withRootObject: value,
            requiringSecureCoding: true
        )
    } catch {
        fatalError("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data)
        else {
            fatalError("expected restored \(T.self)")
        }
        return restored
    } catch {
        fatalError("unarchive failed: \(error)")
    }
}

func touchHashable<T: Hashable>(_ value: T) {
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
    _ = value.hashValue
    precondition(value == value)
    _ = value != value
}

final class PushCallDelegate: NSObject, NEAppPushDelegate {
    private let lock = NSLock()
    private var _calls = 0
    private var _lastInfo: [AnyHashable: Any] = [:]

    var calls: Int {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    func appPushManager(
        _ manager: NEAppPushManager,
        didReceiveIncomingCallWithUserInfo userInfo: [AnyHashable: Any]
    ) {
        _ = manager
        precondition(NetworkExtensionHostCallback.isCurrentQueue)
        lock.lock()
        _calls += 1
        _lastInfo = userInfo
        lock.unlock()
    }
}

func networkExtensionResetStore() {
    let storeRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("ne-vpn-\(UUID().uuidString)", isDirectory: true)
    NetworkExtensionHostPreferences.resetForHostTesting(rootDirectory: storeRoot)
}

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

func testVPNProtocolAndOnDemand() {

let ike = NEVPNProtocolIKEv2()
ike.serverAddress = "vpn.example.invalid"
ike.username = "user"
ike.remoteIdentifier = "remote.example.invalid"
ike.localIdentifier = "local.example.invalid"
ike.authenticationMethod = .certificate
ike.useExtendedAuthentication = true
ike.enablePFS = true
ike.deadPeerDetectionRate = .medium
ike.certificateType = .ECDSA256
ike.minimumTLSVersion = .version1_2
ike.maximumTLSVersion = .version1_2
ike.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
ike.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA256
ike.ikeSecurityAssociationParameters.diffieHellmanGroup = .group14
ike.ikeSecurityAssociationParameters.lifetimeMinutes = 60
ike.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmChaCha20Poly1305
ike.ppkConfiguration = NEVPNIKEv2PPKConfiguration(
    identifier: "ppk",
    keychainReference: Data([0x01])
)
precondition(ike.serverAddress == "vpn.example.invalid")
precondition(ike.ikeSecurityAssociationParameters.diffieHellmanGroup == .group14)
precondition(ike.ppkConfiguration?.identifier == "ppk")
precondition(ike.ppkConfiguration?.isMandatory == true)

let ipsec = NEVPNProtocolIPSec()
ipsec.serverAddress = "ipsec.example.invalid"
ipsec.authenticationMethod = .sharedSecret
ipsec.sharedSecretReference = Data([0x02])
precondition(ipsec.authenticationMethod == .sharedSecret)

let providerProtocol = NETunnelProviderProtocol()
providerProtocol.providerBundleIdentifier = "example.packet-tunnel"
providerProtocol.providerConfiguration = ["server": "127.0.0.1"]
providerProtocol.disconnectOnSleep = true
providerProtocol.includeAllNetworks = false
providerProtocol.excludeLocalNetworks = true
precondition(providerProtocol.providerBundleIdentifier == "example.packet-tunnel")

let manager = NEVPNManager.shared()
precondition(manager === NEVPNManager.shared())
manager.localizedDescription = "Linux test VPN"
manager.isEnabled = true
manager.isOnDemandEnabled = true
manager.protocolConfiguration = ike
manager.protocol = ike
precondition(manager.protocolConfiguration === ike)
precondition(manager.connection.manager === manager)
precondition(manager.connection.status == .invalid)
precondition(manager.connection.connectedDate == nil)

let connectRule = NEOnDemandRuleConnect()
connectRule.interfaceTypeMatch = .wiFi
connectRule.ssidMatch = ["Example"]
connectRule.probeURL = URL(string: "https://captive.example.invalid")
precondition(connectRule.action == .connect)
let disconnectRule = NEOnDemandRuleDisconnect()
precondition(disconnectRule.action == .disconnect)
let ignoreRule = NEOnDemandRuleIgnore()
precondition(ignoreRule.action == .ignore)
let evaluate = NEOnDemandRuleEvaluateConnection()
evaluate.connectionRules = [
    NEEvaluateConnectionRule(matchDomains: ["example.invalid"], andAction: .connectIfNeeded)
]
precondition(evaluate.action == .evaluateConnection)
precondition(evaluate.connectionRules?.first?.action == .connectIfNeeded)
manager.onDemandRules = [connectRule, disconnectRule, ignoreRule, evaluate]

do {
    try manager.connection.startVPNTunnel()
    fatalError("startVPNTunnel must fail closed when nothing is saved")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}
do {
    try manager.connection.startVPNTunnel(options: [
        NEVPNConnectionStartOptionUsername: "user" as NSString
    ])
    fatalError("startVPNTunnel(options:) must fail closed when nothing is saved")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}
manager.connection.stopVPNTunnel()

let tunnelManager = NETunnelProviderManager()
tunnelManager.protocolConfiguration = providerProtocol
precondition(tunnelManager.routingMethod == .destinationIP)
precondition(tunnelManager.copyAppRules() == nil)
precondition(tunnelManager.connection is NETunnelProviderSession)
do {
    try (tunnelManager.connection as! NETunnelProviderSession).startTunnel(options: nil)
    fatalError("startTunnel must fail closed")
} catch {
    requireVPNError(error, code: .connectionFailed)
}
do {
    try (tunnelManager.connection as! NETunnelProviderSession)
        .sendProviderMessage(Data([0x03]))
    fatalError("sendProviderMessage must fail closed")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}

let appRule = NEAppRule(signingIdentifier: "example.app")
appRule.matchPath = "/usr/bin/false"
precondition(appRule.matchSigningIdentifier == "example.app")
}

func testVPNPreferenceStoreAndStatusMachine() {

let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("ne-vpn-store-\(UUID().uuidString)", isDirectory: true)
NetworkExtensionHostPreferences.resetForHostTesting(rootDirectory: root)

let manager = NEVPNManager.shared()
precondition(manager.connection.status == .invalid)
do {
    try manager.connection.startVPNTunnel()
    fatalError("unsaved start must throw configurationInvalid")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}

let loadedEmpty = neCallback { handler in
    manager.loadFromPreferences(completionHandler: handler)
}
precondition(loadedEmpty == nil)
precondition(manager.connection.status == .invalid)

let ike = NEVPNProtocolIKEv2()
ike.serverAddress = "vpn.example.invalid"
ike.username = "user"
ike.remoteIdentifier = "remote.example.invalid"
ike.localIdentifier = "local.example.invalid"
ike.authenticationMethod = .certificate
ike.includeAllNetworks = true
ike.excludeLocalNetworks = false
ike.sliceUUID = "slice"
ike.disconnectOnSleep = true
manager.protocolConfiguration = ike
manager.localizedDescription = "Simulated Linux VPN"
manager.isEnabled = true
manager.isOnDemandEnabled = true
let connect = NEOnDemandRuleConnect()
connect.interfaceTypeMatch = .wiFi
connect.ssidMatch = ["Cafe"]
connect.dnsSearchDomainMatch = ["lan"]
connect.dnsServerAddressMatch = ["1.1.1.1"]
connect.probeURL = URL(string: "https://captive.example.invalid")
manager.onDemandRules = [connect]

let seen = LockedState<[NEVPNStatus]>([])
let observer = NotificationCenter.default.addObserver(
    forName: .NEVPNStatusDidChange,
    object: manager.connection,
    queue: nil
) { notification in
    precondition(notification.object as? NEVPNConnection === manager.connection)
    seen.withLock { $0.append(manager.connection.status) }
}

let saved = neCallback { handler in
    manager.saveToPreferences(completionHandler: handler)
}
precondition(saved == nil)
precondition(manager.connection.status == .disconnected)

try! manager.connection.startVPNTunnel()
precondition(manager.connection.status == .connected)
precondition(manager.connection.connectedDate != nil)

manager.connection.stopVPNTunnel()
precondition(manager.connection.status == .disconnected)
precondition(manager.connection.connectedDate == nil)

neDrain()
NotificationCenter.default.removeObserver(observer)
let observed = seen.withLock { $0 }
precondition(observed.contains(.connecting))
precondition(observed.contains(.connected))
precondition(observed.contains(.disconnecting))
precondition(observed.contains(.disconnected))

manager.isEnabled = false
let savedDisabled = neCallback { handler in
    manager.saveToPreferences(completionHandler: handler)
}
precondition(savedDisabled == nil)
do {
    try manager.connection.startVPNTunnel()
    fatalError("disabled configuration must throw configurationDisabled")
} catch {
    requireVPNError(error, code: .configurationDisabled)
}

manager.isEnabled = true
let savedEnabled = neCallback { handler in
    manager.saveToPreferences(completionHandler: handler)
}
precondition(savedEnabled == nil)

NetworkExtensionHostPreferences.reloadPersistedStateForHostTesting()
let reloaded = neCallback { handler in
    NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
}
precondition(reloaded == nil)
precondition(NEVPNManager.shared().localizedDescription == "Simulated Linux VPN")
precondition(NEVPNManager.shared().protocolConfiguration?.serverAddress == "vpn.example.invalid")
precondition(NEVPNManager.shared().connection.status == .disconnected)
precondition(NEVPNManager.shared().onDemandRules?.first?.ssidMatch == ["Cafe"])

let tunnel = NETunnelProviderManager()
let tunnelLoad = neCallback { handler in
    tunnel.loadFromPreferences(completionHandler: handler)
}
precondition(tunnelLoad == nil)
let providerProtocol = NETunnelProviderProtocol()
providerProtocol.serverAddress = "packet.example.invalid"
providerProtocol.providerBundleIdentifier = "example.packet-tunnel"
providerProtocol.providerConfiguration = ["mode": "test"]
tunnel.protocolConfiguration = providerProtocol
tunnel.localizedDescription = "Packet tunnel"
tunnel.isEnabled = true
tunnel.replaceAppRulesForHostTesting([
    NEAppRule(signingIdentifier: "example.app")
])
let tunnelSave = neCallback { handler in
    tunnel.saveToPreferences(completionHandler: handler)
}
precondition(tunnelSave == nil)
let copiedRules = tunnel.copyAppRules()
precondition(copiedRules?.first?.matchSigningIdentifier == "example.app")
precondition(copiedRules?.first !== tunnel.copyAppRules()?.first)

let session = tunnel.connection as! NETunnelProviderSession
do {
    try session.startTunnel(options: ["debug": true])
    fatalError("extension-hosted startTunnel must fail closed")
} catch {
    requireVPNError(error, code: .connectionFailed)
}
do {
    try session.sendProviderMessage(Data([0x01]), responseHandler: { _ in })
    fatalError("sendProviderMessage must fail closed")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}
session.stopTunnel()

let allTunnels = neCallback { handler in
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
        handler((managers, error))
    }
}
precondition(allTunnels.1 == nil)
precondition(allTunnels.0?.count == 1)
precondition(allTunnels.0?.first?.protocolConfiguration?.serverAddress == "packet.example.invalid")
precondition(
    (allTunnels.0?.first?.protocolConfiguration as? NETunnelProviderProtocol)?
        .providerBundleIdentifier == "example.packet-tunnel"
)

let removed = neCallback { handler in
    NEVPNManager.shared().removeFromPreferences(completionHandler: handler)
}
precondition(removed == nil)
precondition(NEVPNManager.shared().connection.status == .invalid)
do {
    try NEVPNManager.shared().connection.startVPNTunnel()
    fatalError("removed configuration must fail closed")
} catch {
    requireVPNError(error, code: .configurationInvalid)
}
}

func testIKEv2ExtendedProperties() {
let proxySettings = NEProxySettings()
let ike = NEVPNProtocolIKEv2()
ike.disconnectOnSleep = true
ike.enforceRoutes = true
ike.excludeAPNs = false
ike.excludeCellularServices = false
ike.excludeDeviceCommunication = false
ike.excludeLocalNetworks = false
ike.identityData = Data([0x01])
ike.identityDataPassword = "pw"
ike.identityReference = Data([0x02])
ike.includeAllNetworks = true
ike.passwordReference = Data([0x03])
ike.proxySettings = proxySettings
ike.sliceUUID = "slice"
ike.allowPostQuantumKeyExchangeFallback = true
ike.disableMOBIKE = true
ike.disableRedirect = true
ike.enableFallback = true
ike.enableRevocationCheck = true
ike.mtu = 1280
ike.serverCertificateCommonName = "cn"
ike.serverCertificateIssuerCommonName = "issuer"
ike.strictRevocationCheck = true
ike.useConfigurationAttributeInternalIPSubnet = true
}

func testNSCopying() {

let appRule = NEAppRule(signingIdentifier: "example.app")
appRule.matchPath = "/usr/bin/false"
requireCopy(appRule) { original, copied in
    precondition(copied.matchSigningIdentifier == original.matchSigningIdentifier)
    precondition(copied.matchPath == original.matchPath)
}

let dns = NEDNSSettings(servers: ["1.1.1.1"])
dns.matchDomains = ["example.invalid"]
requireCopy(dns) { original, copied in
    precondition(copied.servers == original.servers)
    precondition(copied.matchDomains == original.matchDomains)
    precondition(copied.dnsProtocol == .cleartext)
}
let doh = NEDNSOverHTTPSSettings(servers: ["1.1.1.1"])
doh.serverURL = URL(string: "https://dns.example.invalid/dns-query")
requireCopy(doh) { original, copied in
    precondition(copied.serverURL == original.serverURL)
    precondition(copied.dnsProtocol == .HTTPS)
}
let dot = NEDNSOverTLSSettings(servers: ["1.1.1.1"])
dot.serverName = "dns.example.invalid"
requireCopy(dot) { original, copied in
    precondition(copied.serverName == original.serverName)
    precondition(copied.dnsProtocol == .TLS)
}

let proxyProtocol = NEDNSProxyProviderProtocol()
proxyProtocol.providerBundleIdentifier = "example.dns-proxy"
requireCopy(proxyProtocol) { original, copied in
    precondition(copied.providerBundleIdentifier == original.providerBundleIdentifier)
}

let evaluateRule = NEEvaluateConnectionRule(
    matchDomains: ["example.invalid"],
    andAction: .connectIfNeeded
)
evaluateRule.probeURL = URL(string: "https://probe.example.invalid")
requireCopy(evaluateRule) { original, copied in
    precondition(copied.matchDomains == original.matchDomains)
    precondition(copied.action == original.action)
    precondition(copied.probeURL == original.probeURL)
}

let allow = NEFilterNewFlowVerdict.allow()
allow.shouldReport = true
requireCopy(allow) { original, copied in
    precondition(copied.shouldReport == original.shouldReport)
}
requireCopy(NEFilterDataVerdict(passBytes: 16, peekBytes: 32)) { _, copied in
    _ = copied
}
requireCopy(NEFilterControlVerdict.drop(withUpdateRules: false)) { _, copied in
    _ = copied
}
requireCopy(NEFilterRemediationVerdict.drop()) { _, copied in
    _ = copied
}
requireCopy(NEFilterVerdict()) { original, copied in
    precondition(copied.shouldReport == original.shouldReport)
}

let flow = NEFilterFlow()
requireCopy(flow) { original, copied in
    precondition(copied.identifier == original.identifier)
    precondition(copied.direction == .any)
}
requireCopy(NEFilterBrowserFlow()) { original, copied in
    precondition(copied.identifier == original.identifier)
}
requireCopy(NEFilterSocketFlow()) { original, copied in
    precondition(copied.identifier == original.identifier)
}

let report = NEFilterReport()
requireCopy(report) { original, copied in
    precondition(copied.action == original.action)
    precondition(copied.event == original.event)
}

let filterConfig = NEFilterProviderConfiguration()
filterConfig.filterSockets = true
filterConfig.organization = "Example"
requireCopy(filterConfig) { original, copied in
    precondition(copied.filterSockets == original.filterSockets)
    precondition(copied.organization == original.organization)
}

let metadata = NEFlowMetaData(
    sourceAppSigningIdentifier: "example.app",
    sourceAppUniqueIdentifier: Data([0x01])
)
requireCopy(metadata) { original, copied in
    precondition(copied.sourceAppSigningIdentifier == original.sourceAppSigningIdentifier)
    precondition(copied.sourceAppUniqueIdentifier == original.sourceAppUniqueIdentifier)
}

let hotspot = NEHotspotConfiguration(ssid: "Cafe")
hotspot.joinOnce = true
requireCopy(hotspot) { original, copied in
    precondition(copied.ssid == original.ssid)
    precondition(copied.joinOnce == original.joinOnce)
}
let eap = NEHotspotEAPSettings()
eap.username = "user"
eap.preferredTLSVersion = .version1_2
requireCopy(eap) { original, copied in
    precondition(copied.username == original.username)
    precondition(copied.preferredTLSVersion == original.preferredTLSVersion)
}
let hs20 = NEHotspotHS20Settings(domainName: "example.invalid", roamingEnabled: true)
hs20.naiRealmNames = ["realm"]
requireCopy(hs20) { original, copied in
    precondition(copied.domainName == original.domainName)
    precondition(copied.isRoamingEnabled == original.isRoamingEnabled)
    precondition(copied.naiRealmNames == original.naiRealmNames)
}

let v4Route = NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.255.255.0")
v4Route.gatewayAddress = "10.0.0.1"
requireCopy(v4Route) { original, copied in
    precondition(copied.destinationAddress == original.destinationAddress)
    precondition(copied.gatewayAddress == original.gatewayAddress)
}
let v6Route = NEIPv6Route(destinationAddress: "fd00::", networkPrefixLength: 64)
requireCopy(v6Route) { original, copied in
    precondition(copied.destinationAddress == original.destinationAddress)
}
let v4 = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
v4.includedRoutes = [v4Route]
requireCopy(v4) { original, copied in
    precondition(copied.addresses == original.addresses)
    precondition(copied.includedRoutes?.first?.destinationAddress == "10.0.0.0")
    precondition(copied.includedRoutes?.first !== original.includedRoutes?.first)
}
let v6 = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
requireCopy(v6) { original, copied in
    precondition(copied.addresses == original.addresses)
}

let connect = NEOnDemandRuleConnect()
connect.interfaceTypeMatch = .wiFi
connect.ssidMatch = ["Example"]
requireCopy(connect) { original, copied in
    precondition(copied.action == .connect)
    precondition(copied.interfaceTypeMatch == original.interfaceTypeMatch)
    precondition(copied.ssidMatch == original.ssidMatch)
}
requireCopy(NEOnDemandRuleDisconnect()) { _, copied in
    precondition(copied.action == .disconnect)
}
requireCopy(NEOnDemandRuleIgnore()) { _, copied in
    precondition(copied.action == .ignore)
}
let evaluate = NEOnDemandRuleEvaluateConnection()
evaluate.connectionRules = [evaluateRule]
requireCopy(evaluate) { original, copied in
    precondition(copied.action == .evaluateConnection)
    precondition(copied.connectionRules?.first?.action == .connectIfNeeded)
    precondition(copied.connectionRules?.first !== original.connectionRules?.first)
}

let packet = NEPacket(data: Data([0x45]), protocolFamily: NetworkExtensionPOSIX.inetFamily)
requireCopy(packet) { original, copied in
    precondition(copied.data == original.data)
    precondition(copied.protocolFamily == original.protocolFamily)
}

let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "203.0.113.1")
settings.mtu = 1280
settings.ipv4Settings = v4
requireCopy(settings) { original, copied in
    precondition(copied.tunnelRemoteAddress == original.tunnelRemoteAddress)
    precondition(copied.mtu?.intValue == 1280)
    precondition(copied.ipv4Settings?.addresses == original.ipv4Settings?.addresses)
    precondition(copied.ipv4Settings !== original.ipv4Settings)
}

let lte = NEPrivateLTENetwork()
lte.mobileCountryCode = "310"
lte.mobileNetworkCode = "260"
requireCopy(lte) { original, copied in
    precondition(copied.mobileCountryCode == original.mobileCountryCode)
    precondition(copied.mobileNetworkCode == original.mobileNetworkCode)
}

let proxyServer = NEProxyServer(address: "127.0.0.1", port: 8080)
proxyServer.authenticationRequired = true
requireCopy(proxyServer) { original, copied in
    precondition(copied.address == original.address)
    precondition(copied.port == original.port)
    precondition(copied.authenticationRequired == original.authenticationRequired)
}
let proxy = NEProxySettings()
proxy.httpsEnabled = true
proxy.httpsServer = proxyServer
requireCopy(proxy) { original, copied in
    precondition(copied.httpsEnabled == original.httpsEnabled)
    precondition(copied.httpsServer?.port == original.httpsServer?.port)
    precondition(copied.httpsServer !== original.httpsServer)
}

let relay = NERelay()
relay.http3RelayURL = URL(string: "https://relay.example.invalid")
requireCopy(relay) { original, copied in
    precondition(copied.http3RelayURL == original.http3RelayURL)
}

let tunnelProtocol = NETunnelProviderProtocol()
tunnelProtocol.providerBundleIdentifier = "example.packet-tunnel"
tunnelProtocol.serverAddress = "vpn.example.invalid"
requireCopy(tunnelProtocol) { original, copied in
    precondition(copied.providerBundleIdentifier == original.providerBundleIdentifier)
    precondition(copied.serverAddress == original.serverAddress)
}

let ipsec = NEVPNProtocolIPSec()
ipsec.authenticationMethod = .sharedSecret
ipsec.serverAddress = "ipsec.example.invalid"
requireCopy(ipsec) { original, copied in
    precondition(copied.authenticationMethod == original.authenticationMethod)
    precondition(copied.serverAddress == original.serverAddress)
}

let ike = NEVPNProtocolIKEv2()
ike.serverAddress = "vpn.example.invalid"
ike.enablePFS = true
ike.ikeSecurityAssociationParameters.diffieHellmanGroup = .group14
ike.ppkConfiguration = NEVPNIKEv2PPKConfiguration(
    identifier: "ppk",
    keychainReference: Data([0x01])
)
ike.ppkConfiguration?.isMandatory = false
requireCopy(ike) { original, copied in
    precondition(copied.serverAddress == original.serverAddress)
    precondition(copied.enablePFS == original.enablePFS)
    precondition(copied.ikeSecurityAssociationParameters.diffieHellmanGroup == .group14)
    precondition(copied.ikeSecurityAssociationParameters !== original.ikeSecurityAssociationParameters)
    precondition(copied.ppkConfiguration?.identifier == "ppk")
    precondition(copied.ppkConfiguration?.isMandatory == false)
    precondition(copied.ppkConfiguration !== original.ppkConfiguration)
}

let ppk = NEVPNIKEv2PPKConfiguration(identifier: "ppk", keychainReference: Data([0x02]))
requireCopy(ppk) { original, copied in
    precondition(copied.identifier == original.identifier)
    precondition(copied.keychainReference == original.keychainReference)
}

let sa = NEVPNIKEv2SecurityAssociationParameters()
sa.lifetimeMinutes = 60
requireCopy(sa) { original, copied in
    precondition(copied.lifetimeMinutes == original.lifetimeMinutes)
}

let host = NWHostEndpoint(hostname: "example.invalid", port: "443")
requireCopy(host) { original, copied in
    precondition(copied.hostname == original.hostname)
    precondition(copied.port == original.port)
}
let bonjour = NWBonjourServiceEndpoint(name: "printer", type: "_ipp._tcp", domain: "local.")
requireCopy(bonjour) { original, copied in
    precondition(copied.name == original.name)
    precondition(copied.type == original.type)
    precondition(copied.domain == original.domain)
}
requireCopy(NWEndpoint()) { _, copied in
    _ = copied
}
}

func testNSSecureCoding() {

let ike = NEVPNProtocolIKEv2()
ike.serverAddress = "vpn.example.invalid"
ike.username = "user"
ike.authenticationMethod = .sharedSecret
ike.enablePFS = true
ike.mtu = 1400
ike.certificateType = .ed25519
ike.deadPeerDetectionRate = .low
ike.minimumTLSVersion = .version1_2
ike.maximumTLSVersion = .version1_2
ike.allowPostQuantumKeyExchangeFallback = true
ike.disableMOBIKE = true
ike.disableRedirect = true
ike.enableFallback = true
ike.enableRevocationCheck = true
ike.strictRevocationCheck = true
ike.useConfigurationAttributeInternalIPSubnet = true
ike.serverCertificateCommonName = "vpn"
ike.serverCertificateIssuerCommonName = "issuer"
ike.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES128GCM
ike.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA384
ike.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
ike.ikeSecurityAssociationParameters.postQuantumKeyExchangeMethods = [.method36]
ike.ppkConfiguration = NEVPNIKEv2PPKConfiguration(
    identifier: "ppk",
    keychainReference: Data([0x09])
)
let restoredIKE = roundTripSecure(ike)
precondition(restoredIKE.serverAddress == "vpn.example.invalid")
precondition(restoredIKE.enablePFS)
precondition(restoredIKE.mtu == 1400)
precondition(restoredIKE.certificateType == .ed25519)
precondition(
    restoredIKE.ikeSecurityAssociationParameters.diffieHellmanGroup == .group20
)
precondition(
    restoredIKE.ikeSecurityAssociationParameters.postQuantumKeyExchangeMethods == [.method36]
)
precondition(restoredIKE.ppkConfiguration?.identifier == "ppk")

let ipsec = NEVPNProtocolIPSec()
ipsec.serverAddress = "ipsec.example.invalid"
ipsec.authenticationMethod = .sharedSecret
ipsec.sharedSecretReference = Data([0x11])
ipsec.localIdentifier = "local"
ipsec.remoteIdentifier = "remote"
ipsec.useExtendedAuthentication = true
let restoredIPSec = roundTripSecure(ipsec)
precondition(restoredIPSec.authenticationMethod == .sharedSecret)
precondition(restoredIPSec.sharedSecretReference == Data([0x11]))

let tunnel = NETunnelProviderProtocol()
tunnel.serverAddress = "packet.example.invalid"
tunnel.providerBundleIdentifier = "example.packet-tunnel"
tunnel.providerConfiguration = ["k": "v"]
let restoredTunnel = roundTripSecure(tunnel)
precondition(restoredTunnel.providerBundleIdentifier == "example.packet-tunnel")
precondition(restoredTunnel.providerConfiguration?["k"] as? String == "v")

let connect = NEOnDemandRuleConnect()
connect.interfaceTypeMatch = .cellular
connect.ssidMatch = ["Office"]
connect.dnsSearchDomainMatch = ["corp"]
connect.probeURL = URL(string: "https://probe.example.invalid")
let restoredConnect = roundTripSecure(connect)
precondition(restoredConnect.action == .connect)
precondition(restoredConnect.interfaceTypeMatch == .cellular)
precondition(restoredConnect.ssidMatch == ["Office"])

let evaluate = NEOnDemandRuleEvaluateConnection()
evaluate.connectionRules = [
    NEEvaluateConnectionRule(matchDomains: ["example.invalid"], andAction: .neverConnect)
]
evaluate.connectionRules?.first?.useDNSServers = ["1.1.1.1"]
let restoredEvaluate = roundTripSecure(evaluate)
precondition(restoredEvaluate.connectionRules?.first?.action == .neverConnect)
precondition(restoredEvaluate.connectionRules?.first?.useDNSServers == ["1.1.1.1"])

let v4 = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
v4.includedRoutes = [NEIPv4Route.default()]
let restoredV4 = roundTripSecure(v4)
precondition(restoredV4.addresses == ["10.0.0.2"])
precondition(restoredV4.includedRoutes?.first?.destinationAddress == "0.0.0.0")

let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "203.0.113.1")
settings.ipv4Settings = v4
settings.mtu = 1280
let restoredSettings = roundTripSecure(settings)
precondition(restoredSettings.tunnelRemoteAddress == "203.0.113.1")
precondition(restoredSettings.mtu?.intValue == 1280)
}

func testFailClosedManagers() {
    neWait {
        NetworkExtensionHostPreferences.resetForHostTesting(
            rootDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ne-vpn-managers-\(UUID().uuidString)", isDirectory: true)
        )
        let vpnLoad = await awaitHostCallback { handler in
            NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
        }
        precondition(vpnLoad == nil)
        precondition(NEVPNManager.shared().connection.status == .invalid)

        let allTunnels = await awaitHostCallback { handler in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allTunnels.0?.isEmpty == true)
        precondition(allTunnels.1 == nil)

        let filterLoad = await awaitHostCallback { handler in
            NEFilterManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let filterError = filterLoad as? NSError else {
            fatalError("expected NSError from filter load")
        }
        precondition(filterError.domain == NEFilterErrorDomain)
        precondition(filterError.code == NEFilterManagerError.configurationInvalid.rawValue)
        NEFilterManager.shared().isEnabled = false
        NEFilterManager.shared().providerConfiguration = NEFilterProviderConfiguration()
        NEFilterManager.shared().providerConfiguration?.filterSockets = true

        let dnsLoad = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let dnsError = dnsLoad as? NSError else {
            fatalError("expected NSError from DNS settings load")
        }
        precondition(dnsError.domain == NEDNSSettingsErrorDomain)
        precondition(NEDNSSettingsManager.shared().isEnabled == false)

        let proxyLoad = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let proxyError = proxyLoad as? NSError else {
            fatalError("expected NSError from DNS proxy load")
        }
        precondition(proxyError.domain == NEDNSProxyErrorDomain)

        let pushLoad = await awaitHostCallback { handler in
            NEAppPushManager().loadFromPreferences(completionHandler: handler)
        }
        guard let pushError = pushLoad as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError")
        }
        precondition(pushError.code == .configurationNotLoaded)
        precondition(NEAppPushManagerError.errorDomain == NEAppPushErrorDomain)

        let allPush = await awaitHostCallback { handler in
            NEAppPushManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allPush.0 == nil)

        let relayLoad = await awaitHostCallback { handler in
            NERelayManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let relayError = relayLoad as? NSError else {
            fatalError("expected NSError from relay load")
        }
        precondition(relayError.domain == NERelayErrorDomain)
        let relay = NERelay()
        relay.http3RelayURL = URL(string: "https://relay.example.invalid")
        NERelayManager.shared().relays = [relay]
        NERelayManager.shared().isEnabled = false

        do {
            try await NEHotspotConfigurationManager.shared.apply(
                NEHotspotConfiguration(ssid: "Example")
            )
            fatalError("hotspot apply must fail closed")
        } catch let error as NEHotspotConfigurationError {
            precondition(error == .internal)
        } catch {
            fatalError("unexpected hotspot error \(error)")
        }
        let ssids = await NEHotspotConfigurationManager.shared.configuredSSIDs()
        precondition(ssids.isEmpty)

        let currentNetwork = await awaitHostCallback { handler in
            NEHotspotNetwork.fetchCurrent(completionHandler: handler)
        }
        precondition(currentNetwork == nil)

        do {
            try await NEHotspotManager.shared.loadFromPreferences()
            fatalError("NEHotspotManager load must fail closed")
        } catch NEHotspotManager.Error.configurationNotLoaded {
            ()
        } catch {
            fatalError("unexpected hotspot manager error \(error)")
        }

        do {
            try await NEURLFilterManager.shared.loadFromPreferences()
            fatalError("URL filter load must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationNotLoaded)
            precondition(error.rawValue == 8)
        } catch {
            fatalError("unexpected URL filter error \(error)")
        }
        let urlFilterStatus = await NEURLFilterManager.shared.status
        precondition(urlFilterStatus == .invalid)
        precondition(NEURLFilterManager.shared.shouldFailClosed)
    }
}

func testFailClosedCompletions() {
    neWait {
        NetworkExtensionHostPreferences.resetForHostTesting(
            rootDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ne-vpn-failclosed-\(UUID().uuidString)", isDirectory: true)
        )
        let vpnSaveStale = await awaitHostCallback { handler in
            NEVPNManager.shared().saveToPreferences(completionHandler: handler)
        }
        requireVPNError(vpnSaveStale, code: .configurationStale)
        let loaded = await awaitHostCallback { handler in
            NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
        }
        precondition(loaded == nil)
        let vpnSaveInvalid = await awaitHostCallback { handler in
            NEVPNManager.shared().saveToPreferences(completionHandler: handler)
        }
        requireVPNError(vpnSaveInvalid, code: .configurationInvalid)
        let vpnRemove = await awaitHostCallback { handler in
            NEVPNManager.shared().removeFromPreferences(completionHandler: handler)
        }
        precondition(vpnRemove == nil)

        let filterSave = await awaitHostCallback { handler in
            NEFilterManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let filterSaveError = filterSave as? NSError else {
            fatalError("expected NSError from filter save")
        }
        precondition(filterSaveError.domain == NEFilterErrorDomain)
        precondition(
            filterSaveError.code == NEFilterManagerError.configurationPermissionDenied.rawValue
        )
        let filterRemove = await awaitHostCallback { handler in
            NEFilterManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let filterRemoveError = filterRemove as? NSError else {
            fatalError("expected NSError from filter remove")
        }
        precondition(
            filterRemoveError.code == NEFilterManagerError.configurationCannotBeRemoved.rawValue
        )

        let dnsSave = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let dnsSaveError = dnsSave as? NSError else {
            fatalError("expected NSError from DNS save")
        }
        precondition(dnsSaveError.domain == NEDNSSettingsErrorDomain)
        let dnsRemove = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let dnsRemoveError = dnsRemove as? NSError else {
            fatalError("expected NSError from DNS remove")
        }
        precondition(
            dnsRemoveError.code == NEDNSSettingsManagerError.configurationCannotBeRemoved.rawValue
        )

        let proxySave = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let proxySaveError = proxySave as? NSError else {
            fatalError("expected NSError from DNS proxy save")
        }
        precondition(proxySaveError.domain == NEDNSProxyErrorDomain)
        let proxyRemove = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let proxyRemoveError = proxyRemove as? NSError else {
            fatalError("expected NSError from DNS proxy remove")
        }
        precondition(
            proxyRemoveError.code == NEDNSProxyManagerError.configurationCannotBeRemoved.rawValue
        )

        let pushSave = await awaitHostCallback { handler in
            NEAppPushManager().saveToPreferences(completionHandler: handler)
        }
        guard let pushSaveError = pushSave as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError from push save")
        }
        precondition(pushSaveError.code == .configurationInvalid)
        let pushRemove = await awaitHostCallback { handler in
            NEAppPushManager().removeFromPreferences(completionHandler: handler)
        }
        guard let pushRemoveError = pushRemove as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError from push remove")
        }
        precondition(pushRemoveError.code == .configurationInvalid)

        let relaySave = await awaitHostCallback { handler in
            NERelayManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let relaySaveError = relaySave as? NSError else {
            fatalError("expected NSError from relay save")
        }
        precondition(relaySaveError.domain == NERelayErrorDomain)
        let relayRemove = await awaitHostCallback { handler in
            NERelayManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let relayRemoveError = relayRemove as? NSError else {
            fatalError("expected NSError from relay remove")
        }
        precondition(
            relayRemoveError.code == NERelayManagerError.configurationCannotBeRemoved.rawValue
        )
        let allRelays = await awaitHostCallback { handler in
            NERelayManager.loadAllManagersFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allRelays.0.isEmpty)
        let lastRelayErrors = await awaitHostCallback { handler in
            NERelayManager.shared().getLastClientErrors(1, completionHandler: handler)
        }
        precondition(lastRelayErrors == nil)

        let filterStart = await awaitHostCallback { handler in
            NEFilterProvider().startFilter(completionHandler: handler)
        }
        guard let filterStartError = filterStart as? NSError else {
            fatalError("expected NSError from filter start")
        }
        precondition(filterStartError.domain == NEFilterErrorDomain)

        let proxyOpen = await awaitHostCallback { handler in
            NEAppProxyTCPFlow().open(withLocalFlowEndpoint: nil, completionHandler: handler)
        }
        guard let proxyOpenError = proxyOpen as? NEAppProxyFlowError else {
            fatalError("expected NEAppProxyFlowError from proxy open")
        }
        precondition(proxyOpenError.code == .notConnected)

        let datagrams = await awaitHostCallback { handler in
            NEPacketTunnelFlow().readPackets { packets, protocols in
                handler((packets, protocols))
            }
        }
        precondition(datagrams.0.isEmpty)
        precondition(datagrams.1.isEmpty)

        do {
            try await NEAppProxyTCPFlow().open(withLocalEndpoint: nil)
            fatalError("app proxy open must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy open error \(error)")
        }
        do {
            try await NEAppProxyTCPFlow().open(withLocalFlowEndpoint: nil)
            fatalError("app proxy open flow endpoint must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy open flow error \(error)")
        }

        let tcpRead = await awaitHostCallback { handler in
            NEAppProxyTCPFlow().readData { data, error in
                handler((data, error))
            }
        }
        precondition(tcpRead.0 == nil)
        do {
            try await NEAppProxyTCPFlow().write(Data([0x01]))
            fatalError("app proxy write must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy write error \(error)")
        }

        let udpFlow = NEAppProxyUDPFlow()
        let datagramRead = await udpFlow.readDatagrams()
        precondition(datagramRead.0 == nil)
        do {
            try await udpFlow.writeDatagrams([(Data([0x01]), NWHostEndpoint(hostname: "h", port: "1"))])
            fatalError("udp writeDatagrams must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected udp write error \(error)")
        }
        do {
            try await udpFlow.writeDatagrams(
                [Data([0x01])],
                sentBy: [NWHostEndpoint(hostname: "h", port: "1")]
            )
            fatalError("udp writeDatagrams sentBy must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected udp write sentBy error \(error)")
        }
        let udpWrite = await awaitHostCallback { handler in
            udpFlow.writeDatagrams(
                [(Data([0x02]), NWHostEndpoint(hostname: "h", port: "1"))],
                completionHandler: handler
            )
        }
        precondition(udpWrite != nil)

        await NEAppProxyProvider().stopProxy(with: .userInitiated)
        do {
            try await NEDNSProxyProvider().startProxy(options: nil)
            fatalError("dns proxy start must fail closed")
        } catch {
            ()
        }
        await NEDNSProxyProvider().stopProxy(with: .providerDisabled)
        await NEFilterProvider().stopFilter(with: .userInitiated)
        let controlVerdict = await NEFilterControlProvider().handleNewFlow(NEFilterFlow())
        _ = controlVerdict
        let remediateVerdict = await NEFilterControlProvider().handleRemediation(for: NEFilterFlow())
        _ = remediateVerdict
        _ = await NETunnelProvider().handleAppMessage(Data([0x00]))

        do {
            try await NEHotspotManager.shared.saveToPreferences()
            fatalError("hotspot manager save must fail closed")
        } catch NEHotspotManager.Error.configurationInvalid {
            ()
        } catch {
            fatalError("unexpected hotspot save error \(error)")
        }
        do {
            try await NEHotspotManager.shared.removeFromPreferences()
            fatalError("hotspot manager remove must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.resetPIRCache()
            fatalError("reset PIR cache must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationInvalid)
        } catch {
            fatalError("unexpected reset PIR error \(error)")
        }
        do {
            try await NEURLFilterManager.shared.saveToPreferences()
            fatalError("url filter save must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.refreshPIRParameters()
            fatalError("refresh PIR must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.removeFromPreferences()
            fatalError("url filter remove must fail closed")
        } catch {
            ()
        }
        _ = NEURLFilterManager.shared.handleConfigChange()
        _ = NEURLFilterManager.shared.handleStatusChange()
        _ = await NEURLFilterManager.shared.lastDisconnectError

        let multi = await awaitHostCallback { handler in
            NWUDPSession(endpoint: NWHostEndpoint(hostname: "h", port: "1"))
                .writeMultipleDatagrams([Data([0x01])], completionHandler: handler)
        }
        precondition(multi != nil)

        let allProxyManagers = await awaitHostCallback { handler in
            NEAppProxyProviderManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        _ = allProxyManagers
    }
}

func testPacketTunnelNetworkSettings() {

let v4 = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
v4.includedRoutes = [NEIPv4Route.default()]
v4.excludedRoutes = [
    NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.255.255.0")
]
precondition(v4.addresses == ["10.0.0.2"])
precondition(v4.includedRoutes?.first?.destinationAddress == "0.0.0.0")

let v6 = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
v6.includedRoutes = [NEIPv6Route.default()]
precondition(v6.networkPrefixLengths.first?.intValue == 64)
precondition(v6.includedRoutes?.first?.destinationAddress == "::")

let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
dns.matchDomains = ["example.invalid"]
dns.searchDomains = ["lan"]
precondition(dns.dnsProtocol == .cleartext)
let doh = NEDNSOverHTTPSSettings(servers: ["1.1.1.1"])
doh.serverURL = URL(string: "https://dns.example.invalid/dns-query")
precondition(doh.dnsProtocol == .HTTPS)
let dot = NEDNSOverTLSSettings(servers: ["1.1.1.1"])
dot.serverName = "dns.example.invalid"
precondition(dot.dnsProtocol == .TLS)

let proxy = NEProxySettings()
proxy.httpsEnabled = true
proxy.httpsServer = NEProxyServer(address: "127.0.0.1", port: 8080)
proxy.httpsServer?.authenticationRequired = false
precondition(proxy.httpsServer?.port == 8080)

let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "203.0.113.1")
settings.ipv4Settings = v4
settings.ipv6Settings = v6
settings.dnsSettings = dns
settings.proxySettings = proxy
settings.mtu = 1280
settings.tunnelOverheadBytes = 28
precondition(settings.tunnelRemoteAddress == "203.0.113.1")
precondition(settings.mtu?.intValue == 1280)
}

func testLegacyNetworkAndPackets() {
    neWait {
        let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
        precondition(endpoint.hostname == "example.invalid")
        precondition(endpoint.port == "443")
        let bonjour = NWBonjourServiceEndpoint(name: "printer", type: "_ipp._tcp", domain: "local.")
        precondition(bonjour.type == "_ipp._tcp")
        let path = NWPath(status: .unsatisfied)
        precondition(path.status == .unsatisfied)
        precondition(path.isEqual(to: NWPath(status: .unsatisfied)))

        let tcp = NWTCPConnection(endpoint: endpoint)
        precondition(tcp.state == .disconnected)
        precondition(tcp.isViable == false)
        let tcpError = await awaitHostCallback { handler in
            tcp.write(Data([0x00]), completionHandler: handler)
        }
        precondition(tcpError != nil)
        tcp.cancel()
        precondition(tcp.state == .cancelled)

        let udp = NWUDPSession(endpoint: endpoint)
        precondition(udp.state == .failed)
        let udpRead = await awaitHostCallback { handler in
            udp.setReadHandler({ data, error in
                handler((data, error))
            }, maxDatagrams: 1)
        }
        precondition(udpRead.0 == nil)
        precondition(udpRead.1 != nil)

        let packet = NEPacket(data: Data([0x45]), protocolFamily: NetworkExtensionPOSIX.inetFamily)
        precondition(packet.data.count == 1)
        let flow = NEPacketTunnelFlow()
        precondition(flow.writePacketObjects([packet]) == false)
        precondition(flow.writePackets([packet.data], withProtocols: [NSNumber(value: 2)]) == false)
        let objects = await awaitHostCallback { handler in
            flow.readPacketObjects(completionHandler: handler)
        }
        precondition(objects.isEmpty)

        let provider = NEPacketTunnelProvider()
        do {
            try await provider.startTunnel(options: nil)
            fatalError("packet tunnel start must fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        do {
            let invalidV4 = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "203.0.113.1")
            invalidV4.ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.1"], subnetMasks: [])
            try await provider.setTunnelNetworkSettings(invalidV4)
            fatalError("mismatched IPv4 settings must be invalid")
        } catch let error as NETunnelProviderError {
            precondition(error.code == .networkSettingsInvalid)
        } catch {
            fatalError("unexpected tunnel settings error \(error)")
        }
        do {
            try await provider.setTunnelNetworkSettings(
                NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "203.0.113.1")
            )
            fatalError("setTunnelNetworkSettings must fail closed")
        } catch let error as NETunnelProviderError {
            precondition(error.code == .networkSettingsFailed)
            precondition(NETunnelProviderError.errorDomain == NETunnelProviderErrorDomain)
        } catch {
            fatalError("unexpected tunnel settings error \(error)")
        }
        await provider.stopTunnel(with: .userInitiated)
        _ = provider.createTCPConnectionThroughTunnel(
            to: endpoint,
            enableTLS: true,
            tlsParameters: NWTLSParameters(),
            delegate: nil
        )
        let displayed = await awaitHostCallback { handler in
            provider.displayMessage("unsupported", completionHandler: handler)
        }
        precondition(displayed == false)

        let appProxy = NEAppProxyProvider()
        do {
            try await appProxy.startProxy(options: nil)
            fatalError("app proxy start must fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        precondition(appProxy.handleNewFlow(NEAppProxyTCPFlow()) == false)

        let pushProvider = NEAppPushProvider()
        let startError = await awaitHostCallback { handler in
            pushProvider.start(completionHandler: handler)
        }
        guard let typed = startError as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError from app push start")
        }
        precondition(typed.code == .inactiveSession)
        pushProvider.reportIncomingCall(userInfo: ["key": "value"])
        await pushProvider.stop(with: .providerDisabled)
    }
}

func testAppProxyAndPushSurface() {
let flow = NEAppProxyTCPFlow()
precondition(flow.isBound == false)
_ = flow.metaData
_ = flow.remoteHostname
_ = flow.remoteEndpoint
_ = flow.remoteFlowEndpoint
flow.closeReadWithError(nil)
flow.closeWriteWithError(nil)
let udp = NEAppProxyUDPFlow()
_ = udp.localEndpoint
_ = udp.localFlowEndpoint

let proxy = NEAppProxyProvider()
proxy.cancelProxyWithError(nil)
_ = proxy.handleNewUDPFlow(udp, initialRemoteEndpoint: NWHostEndpoint(hostname: "h", port: "1"))
let dnsProxy = NEDNSProxyProvider()
_ = dnsProxy.systemDNSSettings
dnsProxy.cancelProxyWithError(nil)
_ = dnsProxy.handleNewFlow(flow)
_ = dnsProxy.handleNewUDPFlow(udp, initialRemoteEndpoint: NWHostEndpoint(hostname: "h", port: "1"))

let push = NEAppPushManager()
push.isEnabled = true
push.localizedDescription = "push"
push.matchEthernet = true
push.providerConfiguration = ["a": "b"]
let pushProvider = NEAppPushProvider()
_ = pushProvider.providerConfiguration
pushProvider.handleTimerEvent()
pushProvider.reportPushToTalkMessage(userInfo: ["k": "v"])
pushProvider.start()
pushProvider.unmatchEthernet()

let appRule = NEAppRule(signingIdentifier: "id")
appRule.matchDomains = ["example.invalid"]
}

func testDNSSettingsStores() {
let doh = NEDNSOverHTTPSSettings(servers: ["1.1.1.1"])
doh.identityReference = Data([0x01])
let dot = NEDNSOverTLSSettings(servers: ["1.1.1.1"])
dot.identityReference = Data([0x02])
let dns = NEDNSSettings(servers: ["1.1.1.1"])
dns.allowFailover = true
dns.domainName = "example.invalid"
dns.matchDomainsNoSearch = true

NEDNSProxyManager.shared().isEnabled = false
NEDNSProxyManager.shared().localizedDescription = "dns"
NEDNSProxyManager.shared().providerProtocol = NEDNSProxyProviderProtocol()
NEDNSProxyManager.shared().providerProtocol?.providerConfiguration = ["x": "y"]
NEDNSSettingsManager.shared().dnsSettings = dns
NEDNSSettingsManager.shared().localizedDescription = "dns settings"
NEDNSSettingsManager.shared().onDemandRules = [NEOnDemandRuleIgnore()]
}

func testProviderAndRouteSurface() {
let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
let packet = NEPacket(data: Data([0x45]), protocolFamily: NetworkExtensionPOSIX.inetFamily)
_ = packet.metadata
let tunnelProvider = NEPacketTunnelProvider()
_ = tunnelProvider.packetFlow
tunnelProvider.cancelTunnelWithError(nil)
_ = tunnelProvider.createUDPSessionThroughTunnel(to: endpoint, from: nil)
let provider = NEProvider()
_ = provider.defaultPath
_ = provider.createUDPSession(to: endpoint, from: nil)
provider.wake()
let path = NWPath(status: .satisfied, isExpensive: true, isConstrained: true)
_ = path.isExpensive
_ = path.isConstrained

let proxyServer = NEProxyServer(address: "127.0.0.1", port: 8080)
proxyServer.username = "u"
proxyServer.password = "p"
let proxySettings = NEProxySettings()
proxySettings.httpEnabled = true
proxySettings.httpServer = proxyServer
proxySettings.autoProxyConfigurationEnabled = true
proxySettings.exceptionList = ["localhost"]
proxySettings.excludeSimpleHostnames = true
proxySettings.matchDomains = ["example.invalid"]
proxySettings.proxyAutoConfigurationJavaScript = "function FindProxy() { return 'DIRECT'; }"
proxySettings.proxyAutoConfigurationURL = URL(string: "https://wpad.example.invalid")
_ = NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.255.255.0").destinationSubnetMask
_ = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"]).subnetMasks
let v6Route = NEIPv6Route(destinationAddress: "fd00::", networkPrefixLength: 64)
v6Route.gatewayAddress = "fd00::1"
_ = v6Route.destinationNetworkPrefixLength
let v6 = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
v6.excludedRoutes = [v6Route]
_ = v6.addresses

let lte = NEPrivateLTENetwork()
lte.trackingAreaCode = "1"
let tunnelCfg = NETunnelProvider()
_ = tunnelCfg.appRules
_ = tunnelCfg.protocolConfiguration
tunnelCfg.reasserting = true
_ = tunnelCfg.routingMethod
}

func testFilterVerdicts() {

let allow = NEFilterNewFlowVerdict.allow()
allow.shouldReport = true
precondition(allow.shouldReport)
_ = NEFilterNewFlowVerdict.drop()
_ = NEFilterNewFlowVerdict.needRules()
_ = NEFilterNewFlowVerdict.filterDataVerdict(
    withFilterInbound: true,
    peekInboundBytes: 64,
    filterOutbound: true,
    peekOutboundBytes: 64
)
_ = NEFilterDataVerdict.allow()
_ = NEFilterDataVerdict.drop()
_ = NEFilterDataVerdict(passBytes: 16, peekBytes: 32)
_ = NEFilterControlVerdict.drop(withUpdateRules: false)
_ = NEFilterRemediationVerdict.drop()

let flow = NEFilterFlow()
precondition(flow.direction == .any)
let provider = NEFilterDataProvider()
precondition(provider.handleNewFlow(flow) !== allow)
let dataVerdict = provider.handleInboundData(
    from: flow,
    readBytesStartOffset: 0,
    readBytes: Data([0x00])
)
_ = dataVerdict
provider.handleRulesChanged()

let report = NEFilterReport()
precondition(report.action == .invalid)
precondition(report.event == .newFlow)
provider.handle(report)
}

func testFilterProviderSurface() {
let browser = NEFilterBrowserFlow()
_ = browser.parentURL
_ = browser.request
_ = browser.response
let socket = NEFilterSocketFlow()
_ = socket.localEndpoint
_ = socket.remoteEndpoint
_ = socket.remoteHostname
_ = socket.socketFamily
_ = socket.socketProtocol
_ = socket.socketType
_ = socket.localFlowEndpoint
_ = socket.remoteFlowEndpoint
let filterFlow = NEFilterFlow()
_ = filterFlow.url
_ = filterFlow.sourceAppIdentifier
_ = filterFlow.sourceAppUniqueIdentifier
_ = filterFlow.sourceAppVersion
let report = NEFilterReport()
_ = report.bytesInboundCount
_ = report.bytesOutboundCount
_ = report.flow
NEFilterManager.shared().localizedDescription = "filter"
let filterConfig = NEFilterProviderConfiguration()
filterConfig.filterBrowsers = true
filterConfig.identityReference = Data([0x03])
filterConfig.passwordReference = Data([0x04])
filterConfig.serverAddress = "filter.example.invalid"
filterConfig.username = "filter"
filterConfig.vendorConfiguration = ["v": "1"]
let filterProvider = NEFilterProvider()
_ = filterProvider.filterConfiguration
let dataProvider = NEFilterDataProvider()
_ = dataProvider.handleInboundDataComplete(for: filterFlow)
_ = dataProvider.handleOutboundDataComplete(for: filterFlow)
_ = dataProvider.handleOutboundData(from: filterFlow, readBytesStartOffset: 0, readBytes: Data())
_ = dataProvider.handleRemediation(for: filterFlow)
let control = NEFilterControlProvider()
control.urlAppendStringMap = ["a": "b"]
control.remediationMap = ["r": ["k": "v" as NSString]]
control.notifyRulesChanged()
_ = NEFilterControlVerdict.allow(withUpdateRules: true)
_ = NEFilterControlVerdict.updateRules()
_ = NEFilterDataVerdict.allow()
_ = NEFilterDataVerdict.drop()
_ = NEFilterDataVerdict.needRules()
_ = NEFilterDataVerdict.remediateVerdict(
    withRemediationURLMapKey: "u",
    remediationButtonTextMapKey: "b"
)
_ = NEFilterNewFlowVerdict.urlAppendStringVerdict(withMapKey: "m")
_ = NEFilterNewFlowVerdict.drop()
_ = NEFilterNewFlowVerdict.filterDataVerdict(
    withFilterInbound: false,
    peekInboundBytes: 1,
    filterOutbound: false,
    peekOutboundBytes: 1
)
_ = NEFilterNewFlowVerdict.needRules()
_ = NEFilterNewFlowVerdict.remediateVerdict(
    withRemediationURLMapKey: "u",
    remediationButtonTextMapKey: "b"
)
_ = NEFilterRemediationVerdict.allow()
_ = NEFilterRemediationVerdict.needRules()
}

func testHotspotConfiguration() {

let openNet = NEHotspotConfiguration(ssid: "Cafe")
precondition(openNet.ssid == "Cafe")
let wpa = NEHotspotConfiguration(SSID: "Cafe", passphrase: "password12", isWEP: false)
precondition(wpa.ssid == "Cafe")
let prefix = NEHotspotConfiguration(ssidPrefix: "Cafe")
precondition(prefix.ssidPrefix == "Cafe")
let eap = NEHotspotEAPSettings()
eap.username = "user"
eap.password = "secret"
eap.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPTLS.rawValue)]
eap.preferredTLSVersion = .version1_2
eap.ttlsInnerAuthenticationType = .eapttlsInnerAuthenticationMSCHAPv2
precondition(eap.setTrustedServerCertificates([]) == false)
let eapConfig = NEHotspotConfiguration(ssid: "Enterprise", eapSettings: eap)
precondition(eapConfig.ssid == "Enterprise")
let hs20 = NEHotspotHS20Settings(domainName: "example.invalid", roamingEnabled: false)
let passpoint = NEHotspotConfiguration(hs20Settings: hs20, eapSettings: eap)
precondition(passpoint.ssidPrefix == "")
precondition(NEHotspotHelper.register(options: nil, queue: .main, handler: { _ in }) == false)
precondition(NEHotspotHelper.supportedNetworkInterfaces() == nil)
let command = NEHotspotHelperCommand()
let response = command.createResponse(.failure)
response.deliver()
let network = NEHotspotNetwork(ssid: "Cafe", bssid: "00:00:00:00:00:00")
network.setConfidence(.low)
precondition(network.securityType == .unknown)
precondition(NEHotspotHelper.logoff(network) == false)

let lte = NEPrivateLTENetwork()
lte.mobileCountryCode = "310"
lte.mobileNetworkCode = "260"
let push = NEAppPushManager()
push.matchPrivateLTENetworks = [lte]
push.matchSSIDs = ["Cafe"]
push.providerBundleIdentifier = "example.push"
precondition(push.isActive == false)
}

func testHotspotExtendedSurface() {
let hotspot = NEHotspotConfiguration(SSID: "Cafe")
hotspot.hidden = true
hotspot.lifeTimeInDays = 7
_ = NEHotspotConfiguration(ssid: "Cafe", passphrase: "password12", isWEP: false)
_ = NEHotspotConfiguration(SSIDPrefix: "Pre")
_ = NEHotspotConfiguration(ssidPrefix: "Pre", passphrase: "password12", isWEP: false)
_ = NEHotspotConfiguration(SSIDPrefix: "Pre", passphrase: "password12", isWEP: true)
let eap = NEHotspotEAPSettings()
eap.outerIdentity = "outer"
eap.isTLSClientCertificateRequired = true
eap.trustedServerNames = ["radius.example.invalid"]
_ = NEHotspotConfiguration(SSID: "Ent", eapSettings: eap)
let hs20 = NEHotspotHS20Settings(domainName: "example.invalid", roamingEnabled: true)
hs20.mccAndMNCs = ["310260"]
hs20.roamingConsortiumOIs = ["001"]
_ = NEHotspotConfiguration(HS20Settings: hs20, eapSettings: eap)
NEHotspotConfigurationManager.shared.removeConfiguration(forHS20DomainName: "example.invalid")
NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: "Cafe")
let command = NEHotspotHelperCommand()
_ = command.commandType
_ = command.network
_ = command.networkList
let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
_ = command.createTCPConnection(endpoint)
_ = command.createUDPSession(endpoint)
let response = command.createResponse(.uiRequired)
let network = NEHotspotNetwork(ssid: "Cafe", bssid: "00:00:00:00:00:00")
_ = network.ssid
_ = network.bssid
_ = network.didAutoJoin
_ = network.isChosenHelper
_ = network.didJustJoin
_ = network.isSecure
_ = network.signalStrength
network.setPassword("secret")
response.setNetwork(network)
response.setNetworkList([network])
}

func testLegacyConnectionProperties() {
let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
let tls = NWTLSParameters()
tls.sslCipherSuites = [1]
tls.tlsSessionID = Data([0x04])
tls.maximumSSLProtocolVersion = 1
tls.minimumSSLProtocolVersion = 1
let tcp = NWTCPConnection(endpoint: endpoint)
_ = tcp.connectedPath
_ = tcp.error
_ = tcp.hasBetterPath
_ = tcp.localAddress
_ = tcp.remoteAddress
_ = tcp.txtRecord
tcp.writeClose()
_ = NWTCPConnection(upgradeFor: tcp)
_ = NWTCPConnection(upgradeForConnection: tcp)
let udpSession = NWUDPSession(endpoint: endpoint)
_ = udpSession.currentPath
_ = udpSession.endpoint
_ = udpSession.hasBetterPath
_ = udpSession.maximumDatagramLength
_ = udpSession.resolvedEndpoint
_ = udpSession.isViable
udpSession.tryNextResolvedEndpoint()
_ = NWUDPSession(upgradeFor: udpSession)
_ = NWUDPSession(upgradeForSession: udpSession)
}

func testURLFilterBoundary() {
    neWait {
        let verdict = await NEURLFilter.verdict(for: URL(string: "https://example.invalid")!)
        precondition(verdict == .unknown)
        let prefilter = NEURLFilterPrefilter(
            data: .smallFilter(Data([0x00])),
            tag: "t1",
            bitCount: 8,
            hashCount: 1,
            murmurSeed: 0
        )
        precondition(prefilter.tag == "t1")
        switch prefilter.data {
        case .smallFilter(let data):
            precondition(data.count == 1)
        case .temporaryFilepath:
            fatalError("expected smallFilter")
        }
        do {
            try NEURLFilterManager.shared.setConfiguration(
                pirServerURL: URL(string: "https://pir.example.invalid")!,
                pirPrivacyPassIssuerURL: nil,
                pirAuthenticationToken: "token",
                controlProviderBundleIdentifier: "example.urlfilter"
            )
            fatalError("URL filter configuration must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationInvalid)
            precondition(error.rawValue == 2)
        } catch {
            fatalError("unexpected URL filter configuration error \(error)")
        }
    }
}

@MainActor
func testMainActorConfigurations() {
    _ = NEAppExtensionConfiguration()
    _ = NEURLFilterControlProviderConfiguration()
    _ = NEHotspotEvaluationProviderConfiguration()
    _ = NEHotspotAuthenticationProviderConfiguration()
}

func testURLFilterAndHotspotManagerSurface() {
let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "443")
let command = NEHotspotHelperCommand()
let udp = NEAppProxyUDPFlow()
let tcp = NWTCPConnection(endpoint: endpoint)
let request = NSMutableURLRequest(url: URL(string: "https://example.invalid")!)
request.bind(to: command)

let hotspotManager = NEHotspotManager.shared
hotspotManager.safariDomains = ["example.invalid"]
hotspotManager.evaluatedSSIDs = ["Cafe"]
hotspotManager.evaluationProviderBundleIdentifier = "eval"
hotspotManager.authenticationProviderBundleIdentifier = "auth"
hotspotManager.isEnabled = false
_ = NEHotspotManager.Error.internalError.localizedDescription

_ = NEURLFilterManager.shared.pirServerURL
_ = NEURLFilterManager.shared.appBundleIdentifier
_ = NEURLFilterManager.shared.pirAuthenticationToken
NEURLFilterManager.shared.prefilterFetchInterval = 60
_ = NEURLFilterManager.shared.pirPrivacyPassIssuerURL
_ = NEURLFilterManager.shared.controlProviderBundleIdentifier
NEURLFilterManager.shared.isEnabled = false
let err = NEURLFilterManager.Error.configurationInvalid
_ = err.helpAnchor
_ = err.failureReason
_ = err.errorDescription
_ = err.recoverySuggestion
_ = err.localizedDescription
_ = NEURLFilterManager.Status.invalid.rawValue
let prefilter = NEURLFilterPrefilter(
    data: .temporaryFilepath(URL(fileURLWithPath: "/tmp/prefilter")),
    tag: "t2",
    bitCount: 4,
    hashCount: 2,
    murmurSeed: 7
)
_ = prefilter.murmurSeed
_ = prefilter.bitCount
_ = prefilter.hashCount

_ = NEAppProxyProviderManager()

final class UDPHandler: NEAppProxyUDPFlowHandling {
    func handleNewUDPFlow(
        _ flow: NEAppProxyUDPFlow,
        initialRemoteFlowEndpoint remoteEndpoint: NWEndpoint
    ) -> Bool {
        _ = (flow, remoteEndpoint)
        return false
    }
}
_ = UDPHandler().handleNewUDPFlow(udp, initialRemoteFlowEndpoint: endpoint)

final class AuthDelegate: NSObject, NWTCPConnectionAuthenticationDelegate {}
let auth = AuthDelegate()
_ = auth.shouldEvaluateTrust(for: tcp)
_ = auth.shouldProvideIdentity(for: tcp)

let handler: NEHotspotHelperHandler = { _ in }
_ = handler
}

func testReturnBeforeCallbackAndQueueIdentity() {

let error = neCallback { handler in
    NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
}
precondition(error == nil)

let disconnect = neCallback { handler in
    NEVPNManager.shared().connection.fetchLastDisconnectError(completionHandler: handler)
}
precondition(disconnect == nil)
}

func testExactlyOnceDelivery() {

let count = LockedState(0)
let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "443"))
NetworkExtensionHostCallback.holdDelivery()
tcp.readLength(1) { _, _ in
    precondition(NetworkExtensionHostCallback.isCurrentQueue)
    count.withLock { $0 += 1 }
}
tcp.cancel()
let beforeRelease = count.withLock { $0 }
precondition(beforeRelease == 0, "callback ran before releaseDelivery")
NetworkExtensionHostCallback.releaseDelivery()
neDrain()
precondition(count.withLock { $0 } == 1)
neDrain()
precondition(count.withLock { $0 } == 1)
precondition(tcp.state == .cancelled)
}

func testCancellation() {

let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "1"))
tcp.cancel()
precondition(tcp.state == .cancelled)
let result = neCallback { handler in
    tcp.readMinimumLength(1, maximumLength: 8) { data, error in
        handler((data, error))
    }
}
precondition(result.0 == nil)
guard let error = result.1 as? NEAppProxyFlowError else {
    fatalError("expected NEAppProxyFlowError after cancel")
}
precondition(error.code == NEAppProxyFlowError.Code.aborted)

let udp = NWUDPSession(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "1"))
udp.cancel()
precondition(udp.state == .cancelled)
let datagram = neCallback { handler in
    udp.writeDatagram(Data([0x01]), completionHandler: handler)
}
precondition(datagram != nil)
}

func testDelegateReplacement() {

let manager = NEAppPushManager()
let first = PushCallDelegate()
let second = PushCallDelegate()
manager.delegate = first
manager.deliverIncomingCallForHostTesting(userInfo: ["token": "a"])
manager.delegate = second
neDrain()
precondition(first.calls == 0)
precondition(second.calls == 1)
}

func testWeakOwnership() {

let manager = NEAppPushManager()
weak var weakDelegate: PushCallDelegate?
do {
    let delegate = PushCallDelegate()
    manager.delegate = delegate
    weakDelegate = delegate
    precondition(weakDelegate != nil)
}
precondition(weakDelegate == nil)

weak var weakManager: NEAppPushManager?
do {
    let owned = NEAppPushManager()
    weakManager = owned
    owned.deliverIncomingCallForHostTesting()
}
neDrain()
precondition(weakManager == nil)
}

func testConcurrentSafety() {
    neWait {
        let groupCount = 8
        let results = await withTaskGroup(of: (any Error)?.self, returning: [(any Error)?].self) { group in
            for _ in 0..<groupCount {
                group.addTask {
                    await awaitHostCallback { handler in
                        NEVPNManager().loadFromPreferences(completionHandler: handler)
                    }
                }
            }
            var collected: [(any Error)?] = []
            for await error in group {
                collected.append(error)
            }
            return collected
        }
        precondition(results.count == groupCount)
        for error in results {
            precondition(error == nil)
        }

        let filterSaves = await withTaskGroup(of: (any Error)?.self, returning: [(any Error)?].self) { group in
            for _ in 0..<4 {
                group.addTask {
                    await awaitHostCallback { handler in
                        NEFilterManager.shared().saveToPreferences(completionHandler: handler)
                    }
                }
            }
            var collected: [(any Error)?] = []
            for await error in group {
                collected.append(error)
            }
            return collected
        }
        precondition(filterSaves.count == 4)
    }
}

func testOverrideDispatch() {
    neWait {
        class HostTunnel: NEPacketTunnelProvider {
            var started = false

            override func startTunnel(options: [String: NSObject]? = nil) async throws {
                started = true
                try await super.startTunnel(options: options)
            }
        }

        let concrete = HostTunnel()
        let existential: NEProvider = concrete
        let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "80")
        let connection = existential.createTCPConnection(
            to: endpoint,
            enableTLS: false,
            tlsParameters: nil,
            delegate: nil
        )
        precondition(connection.endpoint === endpoint)
        do {
            try await concrete.startTunnel(options: nil)
            fatalError("overridden startTunnel must still fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        precondition(concrete.started)

        let slept: Void = await awaitHostCallback { handler in
            existential.sleep {
                handler(())
            }
        }
        _ = slept
    }
}

networkExtensionResetStore()
testEnumRawValues()
testAuditedRawValues()
testErrorHashableSurface()
testConstantsAndNotifications()
testErrorBridging()
testVPNProtocolAndOnDemand()
testVPNPreferenceStoreAndStatusMachine()
testIKEv2ExtendedProperties()
testNSCopying()
testNSSecureCoding()
testFailClosedManagers()
testFailClosedCompletions()
testPacketTunnelNetworkSettings()
testLegacyNetworkAndPackets()
testAppProxyAndPushSurface()
testDNSSettingsStores()
testProviderAndRouteSurface()
testFilterVerdicts()
testFilterProviderSurface()
testHotspotConfiguration()
testHotspotExtendedSurface()
testLegacyConnectionProperties()
testURLFilterBoundary()
await MainActor.run {
    testMainActorConfigurations()
}
testURLFilterAndHotspotManagerSurface()
testReturnBeforeCallbackAndQueueIdentity()
testExactlyOnceDelivery()
testCancellation()
testDelegateReplacement()
testWeakOwnership()
testConcurrentSafety()
testOverrideDispatch()
print("NETWORKEXTENSION_AGENT_RUNTIME_OK")
