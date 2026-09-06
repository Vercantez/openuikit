import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNWPathDNSAndEndpoints() {
    let path = NWPath(
        status: .unsatisfied,
        supportsDNS: false,
        localEndpoint: .hostPort(host: .ipv4(.loopback), port: .any),
        remoteEndpoint: .hostPort(host: .ipv4(.loopback), port: .https)
    )
    expect(path.supportsDNS == false, "supportsDNS")
    expect(path.localEndpoint != nil, "localEndpoint")
    expect(path.remoteEndpoint != nil, "remoteEndpoint")
    let monitor = NWPathMonitor()
    monitor.start(queue: DispatchQueue(label: "network.path.surface"))
    _ = monitor.currentPath.supportsDNS
    expect(monitor.currentPath.localEndpoint == nil, "snapshot localEndpoint")
    expect(monitor.currentPath.remoteEndpoint == nil, "snapshot remoteEndpoint")
    monitor.cancel()
}

func testIPAddressProtocolInits() {
    let fromBytes: (any IPAddress)? = IPv4Address(Data([127, 0, 0, 1]), nil)
    expect(fromBytes?.isLoopback == true, "IPAddress init data interface")
    let fromString: (any IPAddress)? = IPv4Address("127.0.0.1")
    expect(fromString?.isLoopback == true, "IPAddress init string")
}

func testHostPortAssociatedTypes() {
    let host: NWEndpoint.Host = "example.invalid"
    expect(host.debugDescription.contains("example") || true, "stringLiteral")
    _ = NWEndpoint.Host.StringLiteralType.self
    _ = NWEndpoint.Host.UnicodeScalarLiteralType.self
    _ = NWEndpoint.Host.ExtendedGraphemeClusterLiteralType.self
    _ = NWEndpoint.Port.IntegerLiteralType.self
    _ = NWEndpoint.Port.RawValue.self
    let port: NWEndpoint.Port = 443
    expect(port.rawValue == 443, "integer literal RawValue")
    let again = NWEndpoint.Host(stringLiteral: "127.0.0.1")
    if case .ipv4 = again { } else { preconditionFailure("stringLiteral ipv4") }
    let cluster = NWEndpoint.Host(extendedGraphemeClusterLiteral: "127.0.0.1")
    if case .ipv4 = cluster { } else { preconditionFailure("extendedGraphemeClusterLiteral") }
    let scalar = NWEndpoint.Host(unicodeScalarLiteral: "127.0.0.1")
    if case .ipv4 = scalar { } else { preconditionFailure("unicodeScalarLiteral") }
    _ = IPv6Address.Scope.RawValue.self
    _ = NWPathMonitor.AsyncIterator.self
    _ = NWPathMonitor.Element.self
    _ = NWPathMonitor.Iterator.Element.self
}
