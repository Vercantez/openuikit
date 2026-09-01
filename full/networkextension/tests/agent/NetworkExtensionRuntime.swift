import Foundation
import Glibc
import NetworkExtension

private func requireVPNError(_ error: Error?, code: NEVPNError.Code) {
    guard let error = error as? NEVPNError else {
        fatalError("expected NEVPNError, got \(String(describing: error))")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(NEVPNError.errorDomain == NEVPNErrorDomain)
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
        print("NETWORKEXTENSION_AGENT_RUNTIME_OK")
    }

    static func exerciseConstantsAndNotifications() {
        precondition(NEVPNErrorDomain == "NEVPNErrorDomain")
        precondition(NEVPNConnectionErrorDomain == "NEVPNConnectionErrorDomain")
        precondition(NETunnelProviderErrorDomain == "NETunnelProviderErrorDomain")
        precondition(NEAppProxyErrorDomain == "NEAppProxyErrorDomain")
        precondition(NEAppPushErrorDomain == "NEAppPushErrorDomain")
        precondition(NEDNSProxyErrorDomain == "NEDNSProxyErrorDomain")
        precondition(NEDNSSettingsErrorDomain == "NEDNSSettingsErrorDomain")
        precondition(NEFilterErrorDomain == "NEFilterErrorDomain")
        precondition(NEHotspotConfigurationErrorDomain == "NEHotspotConfigurationErrorDomain")
        precondition(NERelayErrorDomain == "NERelayErrorDomain")
        precondition(NERelayClientErrorDomain == "NERelayClientErrorDomain")
        precondition(NEVPNConnectionStartOptionUsername == "Username")
        precondition(NEVPNConnectionStartOptionPassword == "Password")
        precondition(kNEHotspotHelperOptionDisplayName == "DisplayName")
        precondition(NEFilterFlowBytesMax == 512 * 1024)
        precondition(NEFilterProviderRemediationMapRemediationURLs == "RemediationURLs")
        precondition(NEFilterProviderRemediationMapRemediationButtonTexts == "RemediationButtonTexts")
        precondition(NEFilterProviderRemediationURLFlowURL == "FLOW_URL")
        precondition(NEFilterProviderRemediationURLFlowURLHostname == "FLOW_URL_HOSTNAME")
        precondition(NEFilterProviderRemediationURLOrganization == "ORGANIZATION")
        precondition(NEFilterProviderRemediationURLUsername == "USERNAME")

        precondition(NSNotification.Name.NEVPNStatusDidChange.rawValue == "NEVPNStatusDidChangeNotification")
        precondition(NSNotification.Name.NEVPNConfigurationChange.rawValue == "NEVPNConfigurationChangeNotification")
        precondition(NSNotification.Name.NEFilterConfigurationDidChange.rawValue == "NEFilterConfigurationDidChangeNotification")
        precondition(NSNotification.Name.NEDNSProxyConfigurationDidChange.rawValue == "NEDNSProxyConfigurationDidChangeNotification")
        precondition(NSNotification.Name.NEDNSSettingsConfigurationDidChange.rawValue == "NEDNSSettingsConfigurationDidChangeNotification")
        precondition(NSNotification.Name.NERelayConfigurationDidChange.rawValue == "NERelayConfigurationDidChangeNotification")
        precondition(NSNotification.Name.NEURLFilterStatusDidChange.rawValue == "NEURLFilterStatusDidChangeNotification")
        precondition(NSNotification.Name.NEURLFilterConfigurationDidChange.rawValue == "NEURLFilterConfigurationDidChangeNotification")

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
        let vpnLoad = await withCheckedContinuation { continuation in
            NEVPNManager.shared().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
        }
        requireVPNError(vpnLoad, code: .configurationReadWriteFailed)

        let allTunnels = await withCheckedContinuation { continuation in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                continuation.resume(returning: (managers, error))
            }
        }
        precondition(allTunnels.0 == nil)
        requireVPNError(allTunnels.1, code: .configurationReadWriteFailed)

        let filterLoad = await withCheckedContinuation { continuation in
            NEFilterManager.shared().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
        }
        guard let filterError = filterLoad as? NSError else {
            fatalError("expected NSError from filter load")
        }
        precondition(filterError.domain == NEFilterErrorDomain)
        precondition(filterError.code == NEFilterManagerError.configurationInvalid.rawValue)
        NEFilterManager.shared().isEnabled = false
        NEFilterManager.shared().providerConfiguration = NEFilterProviderConfiguration()
        NEFilterManager.shared().providerConfiguration?.filterSockets = true

        let dnsLoad = await withCheckedContinuation { continuation in
            NEDNSSettingsManager.shared().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
        }
        guard let dnsError = dnsLoad as? NSError else {
            fatalError("expected NSError from DNS settings load")
        }
        precondition(dnsError.domain == NEDNSSettingsErrorDomain)
        precondition(NEDNSSettingsManager.shared().isEnabled == false)

        let proxyLoad = await withCheckedContinuation { continuation in
            NEDNSProxyManager.shared().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
        }
        guard let proxyError = proxyLoad as? NSError else {
            fatalError("expected NSError from DNS proxy load")
        }
        precondition(proxyError.domain == NEDNSProxyErrorDomain)

        let pushLoad = await withCheckedContinuation { continuation in
            NEAppPushManager().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
        }
        guard let pushError = pushLoad as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError")
        }
        precondition(pushError.code == .configurationNotLoaded)
        precondition(NEAppPushManagerError.errorDomain == NEAppPushErrorDomain)

        let allPush = await withCheckedContinuation { continuation in
            NEAppPushManager.loadAllFromPreferences { managers, error in
                continuation.resume(returning: (managers, error))
            }
        }
        precondition(allPush.0 == nil)

        let relayLoad = await withCheckedContinuation { continuation in
            NERelayManager.shared().loadFromPreferences { error in
                continuation.resume(returning: error)
            }
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
        NEHotspotNetwork.fetchCurrent { network in
            precondition(network == nil)
        }

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
        let tcpError = await withCheckedContinuation { continuation in
            tcp.write(Data([0x00])) { error in
                continuation.resume(returning: error)
            }
        }
        precondition(tcpError != nil)
        tcp.cancel()

        let udp = NWUDPSession(endpoint: endpoint)
        precondition(udp.state == .failed)
        udp.setReadHandler({ _, _ in }, maxDatagrams: 1)

        let packet = NEPacket(data: Data([0x45]), protocolFamily: sa_family_t(AF_INET))
        precondition(packet.data.count == 1)
        let flow = NEPacketTunnelFlow()
        precondition(flow.writePacketObjects([packet]) == false)
        precondition(flow.writePackets([packet.data], withProtocols: [NSNumber(value: AF_INET)]) == false)
        let objects = await withCheckedContinuation { continuation in
            flow.readPacketObjects { packets in
                continuation.resume(returning: packets)
            }
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
        provider.displayMessage("unsupported") { displayed in
            precondition(displayed == false)
        }

        let appProxy = NEAppProxyProvider()
        do {
            try await appProxy.startProxy(options: nil)
            fatalError("app proxy start must fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        precondition(appProxy.handleNewFlow(NEAppProxyTCPFlow()) == false)

        let pushProvider = NEAppPushProvider()
        let startError = await withCheckedContinuation { continuation in
            pushProvider.start { error in
                continuation.resume(returning: error)
            }
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
}

await NetworkExtensionRuntime.main()
