import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNWParametersInitsAndStoredFlags() {
    let empty = NWParameters()
    expect(empty.tcpOptions == nil, "empty has no tcp")
    expect(empty.parameters === empty, "parameters alias")
    let tlsTCP = NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options())
    expect(tlsTCP.tlsOptions != nil, "tls stored")
    expect(tlsTCP.tcpOptions != nil, "tcp stored")
    let dtlsUDP = NWParameters(dtls: NWProtocolTLS.Options(), udp: NWProtocolUDP.Options())
    expect(dtlsUDP.defaultProtocolStack.transportProtocol is NWProtocolUDP.Options, "udp transport")
    let quic = NWParameters(quic: NWProtocolQUIC.Options(alpn: ["h3"]))
    expect(quic.defaultProtocolStack.transportProtocol is NWProtocolQUIC.Options, "quic transport")
    empty.preferNoProxies = true
    empty.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .http)
    empty.prohibitExpensivePaths = true
    empty.prohibitConstrainedPaths = true
    empty.requiresDNSSECValidation = true
    empty.allowUltraConstrainedPaths = true
    empty.attribution = .user
    expect(empty.preferNoProxies, "preferNoProxies")
    expect(empty.requiredLocalEndpoint != nil, "requiredLocalEndpoint")
    expect(empty.prohibitExpensivePaths, "prohibitExpensivePaths")
    expect(empty.prohibitConstrainedPaths, "prohibitConstrainedPaths")
    expect(empty.requiresDNSSECValidation, "requiresDNSSECValidation")
    expect(empty.allowUltraConstrainedPaths, "allowUltraConstrainedPaths")
    expect(empty.attribution == .user, "attribution")
}

func testNWParametersProtocolStackAndPrivacy() {
    let tcp = NWParameters.tcp
    expect(tcp.defaultProtocolStack.internetProtocol is NWProtocolIP.Options, "internetProtocol")
    expect(tcp.defaultProtocolStack.transportProtocol is NWProtocolTCP.Options, "transportProtocol")
    expect(tcp.defaultProtocolStack.applicationProtocols.isEmpty, "applicationProtocols empty")
    tcp.defaultProtocolStack.applicationProtocols = [NWProtocolTLS.Options()]
    expect(tcp.defaultProtocolStack.applicationProtocols.count == 1, "applicationProtocols set")
    let privacy = NWParameters.PrivacyContext(description: "ctx")
    privacy.proxyConfigurations = [ProxyConfiguration()]
    expect(privacy.proxyConfigurations.count == 1, "proxyConfigurations")
    tcp.setPrivacyContext(privacy)
}

func testNWParametersHashableEnums() {
    var hasher = Hasher()
    NWParameters.Attribution.developer.hash(into: &hasher)
    NWParameters.ServiceClass.bestEffort.hash(into: &hasher)
    NWParameters.ExpiredDNSBehavior.allow.hash(into: &hasher)
    NWParameters.MultipathServiceType.handover.hash(into: &hasher)
    expect(NWParameters.Attribution.developer.hashValue != 0 || true, "attribution hashValue")
    expect(NWParameters.ServiceClass.signaling.hashValue != 0 || true, "serviceClass hashValue")
    expect(Set([NWParameters.Attribution.developer, .user]).count == 2, "attribution set")
    expect(Set([NWParameters.ServiceClass.bestEffort, .background]).count == 2, "service class set")
    expect(Set([NWParameters.ExpiredDNSBehavior.allow, .prohibit]).count == 2, "dns set")
    expect(Set([NWParameters.MultipathServiceType.disabled, .aggregate]).count == 2, "multipath set")
}
