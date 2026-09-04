import Foundation
import Network

private func nwExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testIPv4AddressParsing() {
    let loopback = IPv4Address("127.0.0.1")
    nwExpect(loopback == IPv4Address.loopback, "loopback identity")
    nwExpect(loopback?.isLoopback == true, "loopback flag")
    nwExpect(IPv4Address.any.rawValue == Data(repeating: 0, count: 4), "any")
    nwExpect(IPv4Address.broadcast.rawValue == Data(repeating: 255, count: 4), "broadcast")
    nwExpect(IPv4Address("127.0.0") == nil, "short rejected")
    nwExpect(IPv4Address("256.0.0.1") == nil, "octet overflow rejected")
    nwExpect(IPv4Address("224.0.0.1")?.isMulticast == true, "multicast")
    nwExpect(IPv4Address.mdnsGroup.debugDescription == "224.0.0.251", "mdns group")
    let fromData = IPv4Address(Data([10, 0, 0, 1]))
    nwExpect(fromData?.rawValue == Data([10, 0, 0, 1]), "data init")
    nwExpect(IPv4Address(rawValue: Data([1, 2, 3])) == nil, "short raw rejected")
}

func testIPv6AddressParsing() {
    let loopback = IPv6Address("::1")
    nwExpect(loopback == IPv6Address.loopback, "ipv6 loopback")
    nwExpect(loopback?.isLoopback == true, "isLoopback")
    nwExpect(IPv6Address.any.isAny, "isAny")
    nwExpect(IPv6Address("::") == IPv6Address.any, "compressed any")
    nwExpect(IPv6Address("::ffff:127.0.0.1")?.isIPv4Mapped == true, "v4 mapped")
    nwExpect(IPv6Address("::ffff:127.0.0.1")?.asIPv4 == IPv4Address.loopback, "asIPv4")
    nwExpect(IPv6Address("fe80::1")?.isLinkLocal == true, "link local")
    nwExpect(IPv6Address("ff02::1")?.isMulticast == true, "multicast")
    nwExpect(IPv6Address("::1%lo0") == nil, "zone rejected")
    nwExpect(IPv6Address("1:2:3:4:5:6:7:8:9") == nil, "too many words")
    nwExpect(IPv6Address(rawValue: Data(repeating: 0, count: 16)) == IPv6Address.any, "raw any")
}

func testNWEndpointPortsAndHosts() {
    nwExpect(NWEndpoint.Port.https.rawValue == 443, "https")
    nwExpect(NWEndpoint.Port.http.rawValue == 80, "http")
    nwExpect(NWEndpoint.Port.ssh.rawValue == 22, "ssh")
    nwExpect(NWEndpoint.Port.any.rawValue == 0, "any")
    nwExpect(NWEndpoint.Port("443")?.rawValue == 443, "string port")
    nwExpect(NWEndpoint.Port("not-a-port") == nil, "bad port")
    let host: NWEndpoint.Host = "example.invalid"
    let endpoint = NWEndpoint.hostPort(host: host, port: .https)
    nwExpect(endpoint.debugDescription.contains("443"), "hostPort description")
    let url = NWEndpoint.url(URL(string: "https://example.invalid")!)
    nwExpect(url.debugDescription.contains("example.invalid"), "url endpoint")
}

func testNWErrorFailClosedCases() {
    let error = NWError.unsupported
    if case .posix(let code) = error {
        nwExpect(code == .EOPNOTSUPP, "unsupported maps to EOPNOTSUPP")
    } else {
        preconditionFailure("unsupported is posix")
    }
    nwExpect(NWError.posix(.EPERM).errorCode == 1, "EPERM code")
    nwExpect(NWError.dns(0) != NWError.tls(0), "distinct domains")
    nwExpect(NWError.wifiAware(1).errorCode == 1, "wifiAware")
    nwExpect(kNWErrorDomainPOSIX.length > 0, "posix domain constant")
    nwExpect(String(kNWErrorDomainDNS) == "kNWErrorDomainDNS", "dns domain name")
}

func testCEnumRawValuesFromMacios() {
    nwExpect(nw_connection_state_invalid.rawValue == 0, "invalid")
    nwExpect(nw_connection_state_waiting.rawValue == 1, "waiting")
    nwExpect(nw_connection_state_preparing.rawValue == 2, "preparing")
    nwExpect(nw_connection_state_ready.rawValue == 3, "ready")
    nwExpect(nw_connection_state_failed.rawValue == 4, "failed")
    nwExpect(nw_connection_state_cancelled.rawValue == 5, "cancelled")
    nwExpect(nw_error_domain_posix.rawValue == 1, "posix")
    nwExpect(nw_error_domain_dns.rawValue == 2, "dns")
    nwExpect(nw_error_domain_tls.rawValue == 3, "tls")
    nwExpect(nw_error_domain_wifi_aware.rawValue == 4, "wifi aware")
    nwExpect(nw_interface_type_wifi.rawValue == 1, "wifi")
    nwExpect(nw_path_status_satisfied.rawValue == 1, "satisfied")
    nwExpect(nw_browse_result_change_result_added == 0x02, "result added")
    nwExpect(NW_FRAMER_CREATE_FLAGS_DEFAULT == 0, "framer flags")
}

func testPathMonitorDeliversUnsatisfiedSnapshot() {
    let monitor = NWPathMonitor()
    var seen: [NWPath.Status] = []
    monitor.pathUpdateHandler = { path in
        seen.append(path.status)
        nwExpect(path.availableInterfaces.isEmpty, "no fabricated interfaces")
        nwExpect(path.unsatisfiedReason == .notAvailable, "reason")
    }
    monitor.start(queue: DispatchQueue(label: "network.path"))
    nwExpect(seen == [.unsatisfied], "exactly one unsatisfied snapshot")
    nwExpect(monitor.currentPath.status == .unsatisfied, "current path")
    monitor.cancel()
    nwExpect(monitor.isCancelled, "cancelled")
}

func testConnectionSendReceiveFailClosed() {
    let connection = NWConnection(
        to: .hostPort(host: "127.0.0.1", port: .http),
        using: .tcp
    )
    var states: [NWConnection.State] = []
    connection.stateUpdateHandler = { states.append($0) }
    var viability = true
    connection.viabilityUpdateHandler = { viability = $0 }
    connection.start(queue: DispatchQueue(label: "network.conn"))
    nwExpect(states.contains(.preparing), "preparing first")
    if case .failed(let error) = connection.state {
        nwExpect(error == .unsupported, "failed unsupported")
    } else {
        preconditionFailure("expected failed")
    }
    nwExpect(viability == false, "not viable")

    var sendError: NWError?
    connection.send(content: Data([1]), completion: .contentProcessed { sendError = $0 })
    nwExpect(sendError == .unsupported, "send fail-closed")

    var receiveError: NWError?
    connection.receive(minimumIncompleteLength: 1, maximumLength: 16) { data, _, complete, error in
        nwExpect(data == nil, "no fabricated bytes")
        nwExpect(complete == false, "not complete")
        receiveError = error
    }
    nwExpect(receiveError == .unsupported, "receive fail-closed")
    connection.cancel()
    nwExpect(connection.state == .cancelled, "cancelled")
}

func testListenerAndBrowserFailClosed() {
    let listener = try! NWListener(using: .tcp, on: .any)
    var listenerFailed = false
    listener.stateUpdateHandler = { state in
        if case .failed = state { listenerFailed = true }
    }
    listener.start(queue: DispatchQueue(label: "network.listener"))
    nwExpect(listenerFailed, "listener failed")

    let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
    var browserFailed = false
    browser.stateUpdateHandler = { state in
        if case .failed = state { browserFailed = true }
    }
    var changes = 0
    browser.browseResultsChangedHandler = { _, _ in changes += 1 }
    browser.start(queue: DispatchQueue(label: "network.browser"))
    nwExpect(browserFailed, "browser failed")
    nwExpect(browser.browseResults.isEmpty, "no fabricated peers")
    nwExpect(changes == 1, "empty change callback")
}

func testTXTRecordDictionaryRoundTrip() {
    var record = NWTXTRecord(["a": "1", "b": "2"])
    nwExpect(record["a"] == "1", "get a")
    nwExpect(record["b"] == "2", "get b")
    record["c"] = "3"
    nwExpect(record.getEntry(for: "c") != nil, "set c")
    nwExpect(record.setEntry(.empty, for: "empty"), "empty entry")
    if case .empty = record.getEntry(for: "empty")! {
        // expected
    } else {
        preconditionFailure("empty entry")
    }
    nwExpect(Array(record).count == 4, "collection count")
}

func testParametersBuildersStayLocal() {
    let tcp = NWParameters.tcp
    nwExpect(tcp.serviceClass == .bestEffort, "default class")
    _ = tcp.peerToPeerIncluded(true).localOnly(true)
    nwExpect(tcp.includePeerToPeer, "peer to peer stored")
    nwExpect(tcp.acceptLocalOnly, "local only stored")
    let tls = NWParameters.tls
    nwExpect(tls.tlsOptions != nil, "tls options present")
    _ = NWParameters.udp
    _ = NWProtocolTCP.Options()
    _ = NWProtocolUDP.Options()
    _ = NWProtocolIP.Options()
    nwExpect(NWProtocolTCP.definition.identifier == "tcp", "tcp definition")
}
