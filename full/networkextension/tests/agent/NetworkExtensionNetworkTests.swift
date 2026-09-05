@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
