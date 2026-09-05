@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
