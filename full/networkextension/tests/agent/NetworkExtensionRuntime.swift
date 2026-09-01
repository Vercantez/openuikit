@_spi(OpenUIKitHost) import NetworkExtension
import Foundation

private func requireVPNError(_ error: Error?, code: NEVPNError.Code) {
    guard let error = error as? NEVPNError else {
        fatalError("expected NEVPNError, got \(String(describing: error))")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(NEVPNError.errorDomain == NEVPNErrorDomain)
}

private func drainHostQueue() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        NetworkExtensionHostCallback.schedule {
            continuation.resume()
        }
    }
}

/// Wait for an asynchronous NetworkExtension completion. The probed API must
/// return before the handler runs, and the handler must run on
/// `NetworkExtensionHostCallback.queue`. That queue is a Linux host control,
/// not Apple `nesessionmanager` identity.
private func awaitHostCallback<T>(
    _ body: (@escaping (T) -> Void) -> Void
) async -> T {
    await withCheckedContinuation { continuation in
        var returned = false
        body { value in
            precondition(returned, "asynchronous completion ran inline")
            precondition(
                NetworkExtensionHostCallback.isCurrentQueue,
                "completion was not delivered on NetworkExtensionHostCallback.queue"
            )
            continuation.resume(returning: value)
        }
        returned = true
    }
}

private final class PushCallDelegate: NSObject, NEAppPushDelegate {
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

struct NetworkExtensionRuntime {
    static func main() async {
        exerciseConstantsAndNotifications()
        exerciseVPNConfiguration()
        await exerciseFailClosedManagers()
        exerciseRoutesAndSettings()
        exerciseFilterVerdicts()
        exerciseHotspotObjects()
        await exerciseLegacyNetworkAndPackets()
        await exerciseURLFilterBoundary()
        await exerciseHostCallbackContracts()
        print("NETWORKEXTENSION_AGENT_RUNTIME_OK")
    }

    static func exerciseConstantsAndNotifications() {
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

    static func exerciseVPNConfiguration() {
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
            fatalError("startVPNTunnel must fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        do {
            try manager.connection.startVPNTunnel(options: [
                NEVPNConnectionStartOptionUsername: "user" as NSString
            ])
            fatalError("startVPNTunnel(options:) must fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
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

    static func exerciseFailClosedManagers() async {
        let vpnLoad = await awaitHostCallback { handler in
            NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
        }
        requireVPNError(vpnLoad, code: .configurationReadWriteFailed)

        let allTunnels = await awaitHostCallback { handler in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allTunnels.0 == nil)
        requireVPNError(allTunnels.1, code: .configurationReadWriteFailed)

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
        } catch NEURLFilterManager.Error.configurationNotLoaded {
            ()
        } catch {
            fatalError("unexpected URL filter error \(error)")
        }
        let urlFilterStatus = await NEURLFilterManager.shared.status
        precondition(urlFilterStatus == .invalid)
        precondition(NEURLFilterManager.shared.shouldFailClosed)
    }

    static func exerciseRoutesAndSettings() {
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

    static func exerciseFilterVerdicts() {
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

    static func exerciseHotspotObjects() {
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

    static func exerciseLegacyNetworkAndPackets() async {
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

    static func exerciseURLFilterBoundary() async {
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
        } catch NEURLFilterManager.Error.configurationInvalid {
            ()
        } catch {
            fatalError("unexpected URL filter configuration error \(error)")
        }
    }

    static func exerciseHostCallbackContracts() async {
        await exerciseReturnBeforeCallbackAndQueueIdentity()
        await exerciseExactlyOnceDelivery()
        await exerciseCancellation()
        await exerciseDelegateReplacement()
        await exerciseWeakOwnership()
        await exerciseConcurrentSafety()
        await exerciseOverrideDispatch()
    }

    static func exerciseReturnBeforeCallbackAndQueueIdentity() async {
        var returned = false
        let error = await withCheckedContinuation { continuation in
            NEVPNManager.shared().loadFromPreferences { value in
                precondition(returned)
                precondition(NetworkExtensionHostCallback.isCurrentQueue)
                continuation.resume(returning: value)
            }
            returned = true
        }
        requireVPNError(error, code: .configurationReadWriteFailed)

        let disconnect = await awaitHostCallback { handler in
            NEVPNManager.shared().connection.fetchLastDisconnectError(completionHandler: handler)
        }
        requireVPNError(disconnect, code: .connectionFailed)
    }

    static func exerciseExactlyOnceDelivery() async {
        final class OnceCount: @unchecked Sendable {
            var value = 0
        }
        let count = OnceCount()
        let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "443"))
        tcp.readLength(1) { _, _ in
            precondition(NetworkExtensionHostCallback.isCurrentQueue)
            count.value += 1
        }
        tcp.cancel()
        await drainHostQueue()
        await drainHostQueue()
        precondition(count.value == 1)
        precondition(tcp.state == .cancelled)
    }

    static func exerciseCancellation() async {
        let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "1"))
        tcp.cancel()
        precondition(tcp.state == .cancelled)
        let result = await awaitHostCallback { handler in
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
        let datagram = await awaitHostCallback { handler in
            udp.writeDatagram(Data([0x01]), completionHandler: handler)
        }
        precondition(datagram != nil)
    }

    static func exerciseDelegateReplacement() async {
        let manager = NEAppPushManager()
        let first = PushCallDelegate()
        let second = PushCallDelegate()
        manager.delegate = first
        manager.deliverIncomingCallForHostTesting(userInfo: ["token": "a"])
        manager.delegate = second
        await drainHostQueue()
        precondition(first.calls == 0)
        precondition(second.calls == 1)
    }

    static func exerciseWeakOwnership() async {
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
        await drainHostQueue()
        precondition(weakManager == nil)
    }

    static func exerciseConcurrentSafety() async {
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
            requireVPNError(error, code: .configurationReadWriteFailed)
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

    static func exerciseOverrideDispatch() async {
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

await NetworkExtensionRuntime.main()
