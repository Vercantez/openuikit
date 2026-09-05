@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
