import Foundation
import Network

enum NetworkRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw NetworkRuntimeFailure.message(message)
    }
}

func runNetworkRuntime() throws {
    try expect(IPv4Address("127.0.0.1") == IPv4Address.loopback, "ipv4 loopback")
    try expect(IPv4Address("256.0.0.1") == nil, "ipv4 reject")
    try expect(IPv6Address("::1") == IPv6Address.loopback, "ipv6 loopback")
    try expect(IPv6Address("::1").isLoopback, "ipv6 isLoopback")
    try expect(NWEndpoint.Port.https.rawValue == 443, "https port")
    try expect(nw_connection_state_ready.rawValue == 3, "connection ready")
    try expect(nw_error_domain_posix.rawValue == 1, "posix domain")
    var txt = NWTXTRecord(["path": "/"])
    try expect(txt["path"] == "/", "txt get")
    _ = txt.setEntry(.string("1"), for: "ver")
    try expect(txt.getEntry(for: "ver") != nil, "txt set")

    let monitor = NWPathMonitor()
    var sawUnsatisfied = false
    monitor.pathUpdateHandler = { path in
        sawUnsatisfied = path.status == .unsatisfied
    }
    monitor.start(queue: DispatchQueue(label: "network.runtime"))
    try expect(sawUnsatisfied, "path monitor fail-closed")
    monitor.cancel()

    let connection = NWConnection(
        host: "localhost",
        port: .http,
        using: .tcp
    )
    var failed = false
    connection.stateUpdateHandler = { state in
        if case .failed = state { failed = true }
    }
    connection.start(queue: DispatchQueue(label: "network.runtime.conn"))
    try expect(failed, "connection fail-closed")
}

#if NETWORK_RUNTIME_MAIN
do {
    try runNetworkRuntime()
    print("NETWORK_AGENT_RUNTIME_OK")
} catch {
    fatalError("NETWORK_AGENT_RUNTIME_FAIL \(error)")
}
#endif
