@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
