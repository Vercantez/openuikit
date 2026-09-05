@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
