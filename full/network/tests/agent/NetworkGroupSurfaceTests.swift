import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testConnectionGroupDescriptorAndSend() {
    let group = NWConnectionGroup(
        with: NWMultiplexGroup(with: .unix(path: "/tmp/openuikit-group.sock")),
        using: .udp
    )
    expect(group.descriptor is NWMultiplexGroup, "descriptor")
    expect(group.parameters.tcpOptions == nil, "parameters")
    expect(group.debugDescription.contains("NWConnectionGroup"), "debugDescription")
    var handlerRan = false
    group.newConnectionHandler = { _ in handlerRan = true }
    group.newConnectionHandler?(
        NWConnection(to: .unix(path: "/tmp/x"), using: .udp)
    )
    expect(handlerRan, "newConnectionHandler")
    var sendError: NWError?
    let message = NWConnectionGroup.Message.default
    expect(message.localEndpoint == nil, "localEndpoint")
    expect(message.remoteEndpoint == nil, "remoteEndpoint")
    expect(message.path == nil, "path")
    expect(message.metadata(definition: NWProtocolUDP.definition) == nil, "message metadata")
    group.send(content: Data([1]), to: nil, message: message) { sendError = $0 }
    expect(sendError == .unsupported, "send fail-closed")
    expect(group.metadata(definition: NWProtocolUDP.definition) == nil, "group metadata")
}

func testProxyConfigurationDebugDescription() {
    let hop = ProxyConfiguration.RelayHop()
    expect(hop.debugDescription.contains("RelayHop"), "hop debugDescription")
    let proxy = ProxyConfiguration(relays: [hop])
    expect(proxy.debugDescription.contains("ProxyConfiguration"), "proxy debugDescription")
}
