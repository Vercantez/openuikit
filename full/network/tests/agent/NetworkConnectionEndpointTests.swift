import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testConnectionLocalRemoteEndpointsFromLoopback() {
    let params = NWParameters.tcp
    params.allowLocalEndpointReuse = true
    let listener = try! NWListener(using: params, on: .any)
    listener.start(queue: DispatchQueue(label: "network.endpoints.listener"))
    expect(listener.state == .ready, "listener ready")
    let client = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: params
    )
    client.start(queue: DispatchQueue(label: "network.endpoints.client"))
    expect(client.state == .ready, "client ready")
    expect(client.currentPath != nil, "currentPath")
    expect(client.localEndpoint != nil, "localEndpoint")
    expect(client.remoteEndpoint != nil, "remoteEndpoint")
    if case .hostPort(let host, let port) = client.remoteEndpoint {
        if case .ipv4(let address) = host {
            expect(address.isLoopback, "remote is loopback")
        } else {
            preconditionFailure("remote host")
        }
        expect(port == listener.port, "remote port is listener")
    } else {
        preconditionFailure("remote endpoint shape")
    }
    if case .hostPort(let host, _) = client.localEndpoint {
        if case .ipv4(let address) = host {
            expect(address.isLoopback, "local is loopback")
        }
    }
    expect(client.currentPath?.localEndpoint != nil, "path localEndpoint")
    expect(client.currentPath?.remoteEndpoint != nil, "path remoteEndpoint")
    client.cancel()
    listener.cancel()
}

func testUDPConnectionEndpointsFromLoopback() {
    let params = NWParameters.udp
    params.allowLocalEndpointReuse = true
    let listener = try! NWListener(using: params, on: .any)
    listener.start(queue: DispatchQueue(label: "network.udp.endpoints.listener"))
    expect(listener.state == .ready, "udp listener ready")
    let client = NWConnection(
        host: .ipv4(.loopback),
        port: listener.port!,
        using: params
    )
    client.start(queue: DispatchQueue(label: "network.udp.endpoints.client"))
    expect(client.state == .ready, "udp client ready")
    expect(client.localEndpoint != nil, "udp localEndpoint")
    expect(client.remoteEndpoint != nil, "udp remoteEndpoint")
    client.cancel()
    listener.cancel()
}
