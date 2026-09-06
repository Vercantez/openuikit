import Foundation
import Network

private func transportExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testQUICConnectionFailsClosed() {
    let parameters = NWParameters.quic(alpn: ["h3"])
    transportExpect(
        parameters.defaultProtocolStack.transportProtocol is NWProtocolQUIC.Options,
        "quic transport"
    )
    let options = parameters.defaultProtocolStack.transportProtocol as! NWProtocolQUIC.Options
    transportExpect(options.alpn == ["h3"], "alpn stored")
    transportExpect(options.securityProtocolOptions.encodedData.isEmpty, "tls options data")
    transportExpect(options.isDatagram == false, "stream default")
    options.isDatagram = true
    options.maxDatagramFrameSize = 1200
    transportExpect(options.isDatagram, "datagram flag")
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: .https),
        using: parameters
    )
    var viability: Bool?
    var better: Bool?
    connection.viabilityUpdateHandler = { viability = $0 }
    connection.betterPathUpdateHandler = { better = $0 }
    connection.start(queue: DispatchQueue(label: "network.quic"))
    if case .failed(let error) = connection.state {
        transportExpect(error == .posix(.EOPNOTSUPP), "quic fail-closed")
    } else {
        preconditionFailure("quic must fail closed")
    }
    transportExpect(viability == false, "not viable")
    transportExpect(better == false, "no better path")
    let datagram = NWParameters.quicDatagram(alpn: ["h3"])
    let datagramConnection = NWConnection(
        host: .ipv4(.loopback),
        port: .https,
        using: datagram
    )
    datagramConnection.start(queue: DispatchQueue(label: "network.quic.dgram"))
    if case .failed = datagramConnection.state {
        // expected
    } else {
        preconditionFailure("quic datagram fail-closed")
    }
}

func testQUICOptionsDataModel() {
    let options = NWProtocolQUIC.Options(alpn: ["h3", "h3-32"])
    transportExpect(options.idleTimeout == 0, "idle default")
    transportExpect(options.maxUDPPayloadSize == 0, "payload default")
    transportExpect(options.initialMaxData == 0, "max data default")
    transportExpect(options.direction == .bidirectional, "bidi default")
    options.direction = .unidirectional
    options.idleTimeout = 30
    options.initialMaxStreamsBidirectional = 4
    options.initialMaxStreamsUnidirectional = 2
    transportExpect(options.initialMaxStreamsBidirectional == 4, "bidi streams")
    let error: NWProtocolQUIC.ApplicationError = 7
    transportExpect(error.code == 7, "integer literal")
    transportExpect(error.reason == nil, "reason nil")
    let withReason = NWProtocolQUIC.ApplicationError(code: 9, reason: "stop")
    transportExpect(withReason.reason == "stop", "reason")
    transportExpect(withReason.message == "stop", "message alias")
    let meta = NWProtocolQUIC.Metadata()
    meta.keepAlive = .on
    transportExpect(meta.keepAliveBehavior == .on, "keepalive on")
    meta.keepAliveBehavior = .off
    transportExpect(meta.keepAlive == .off, "off")
    meta.keepAlive = .seconds(15)
    if case .seconds(let value) = meta.keepAlive {
        transportExpect(value == 15, "seconds")
    } else {
        preconditionFailure("seconds")
    }
    meta.streamIdentifier = 3
    transportExpect(meta.streamID == 3, "stream id")
    meta.negotiatedALPN = "h3"
    transportExpect(meta.negotiatedALPN == "h3", "alpn")
    meta.remoteIdleTimeout = 0
    transportExpect(meta.remoteIdleTimeout == 0, "remote idle")
    meta.usableDatagramFrameSize = 0
    transportExpect(meta.usableDatagramFrameSize == 0, "datagram frame")
    meta.streamApplicationErrorCode = nil
    transportExpect(meta.streamApplicationErrorCode == nil, "stream app error")
    meta.localMaxStreamsBidirectional = 1
    meta.localMaxStreamsUnidirectional = 1
    meta.remoteMaxStreamsBidirectional = 1
    meta.remoteMaxStreamsUnidirectional = 1
    transportExpect(meta.localMaxStreamsBidirectional == 1, "local bidi")
    transportExpect(meta.remoteMaxStreamsUnidirectional == 1, "remote uni")
    meta.applicationError = withReason
    transportExpect(meta.applicationError?.code == 9, "metadata error")
    options.initialMaxData = 1024
    options.maxUDPPayloadSize = 1200
    options.initialMaxStreamDataBidirectionalLocal = 1
    options.initialMaxStreamDataBidirectionalRemote = 1
    options.initialMaxStreamDataUnidirectional = 1
    _ = NWProtocolQUIC.Options()
    _ = meta.securityProtocolMetadata.encodedData
    _ = NWProtocolQUIC.Options.Direction.bidirectional.hashValue
    transportExpect(NWProtocolQUIC.Options.Direction.bidirectional != .unidirectional, "distinct")
    transportExpect(NWProtocolQUIC.definition.identifier == "quic", "definition")
}

func testTLSOptionsStoreSecurityProtocolData() {
    let options = NWProtocolTLS.Options()
    options.securityProtocolOptions.encodedData = Data([0x16, 0x03, 0x03])
    transportExpect(
        options.securityProtocolOptions.encodedData == Data([0x16, 0x03, 0x03]),
        "stored handshake bytes"
    )
    let again = options.securityProtocolOptions
    transportExpect(again === options.securityProtocolOptions, "same object")
    let metadata = NWProtocolTLS.Metadata()
    transportExpect(metadata.securityProtocolMetadata.encodedData.isEmpty, "empty metadata")
    let copied = nw_tls_copy_sec_protocol_options(nw_tls_create_options())
    transportExpect(copied.encodedData.isEmpty, "C copy is a stand-in")
    _ = nw_tls_copy_sec_protocol_metadata(nw_ip_create_metadata())
    _ = nw_quic_copy_sec_protocol_options(nw_quic_create_options())
    _ = nw_quic_copy_sec_protocol_metadata(nw_ip_create_metadata())
}

func testTLSHandshakeFailsWithErrSSLProtocol() {
    let parameters = NWParameters.tls
    transportExpect(parameters.tlsOptions != nil, "tls preset")
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: .https),
        using: parameters
    )
    var states: [NWConnection.State] = []
    connection.stateUpdateHandler = { states.append($0) }
    connection.start(queue: DispatchQueue(label: "network.tls.depth"))
    transportExpect(states.contains(.preparing), "preparing")
    if case .failed(let error) = connection.state {
        if case .tls(let status) = error {
            transportExpect(status == -9800, "errSSLProtocol")
        } else {
            preconditionFailure("tls domain")
        }
    } else {
        preconditionFailure("handshake fail-closed")
    }
    let dtls = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: 4433),
        using: .dtls
    )
    dtls.start(queue: DispatchQueue(label: "network.dtls"))
    if case .failed(let error) = dtls.state {
        if case .tls(let status) = error {
            transportExpect(status == -9800, "dtls errSSLProtocol")
        } else {
            preconditionFailure("dtls tls domain")
        }
    } else {
        preconditionFailure("dtls fail-closed")
    }
}

func testListenerServiceAdvertisementFailsClosed() {
    let service = NWListener.Service(name: "printer", type: "_ipp._tcp", domain: "local.")
    let listener = try! NWListener(service: service, using: .tcp)
    var failed: NWError?
    listener.stateUpdateHandler = { state in
        if case .failed(let error) = state { failed = error }
    }
    listener.start(queue: DispatchQueue(label: "network.listener.bonjour"))
    transportExpect(failed == .posix(.EOPNOTSUPP), "no mDNS")
    if case .failed(let error) = listener.state {
        transportExpect(error == .posix(.EOPNOTSUPP), "state failed")
    } else {
        preconditionFailure("service start fail-closed")
    }
    listener.cancel()
    let app = try! NWListener(applicationService: "app")
    app.start(queue: DispatchQueue(label: "network.listener.app"))
    if case .failed(let error) = app.state {
        transportExpect(error == .posix(.EOPNOTSUPP), "app service")
    } else {
        preconditionFailure("application service fail-closed")
    }
    app.cancel()
}

func testBrowserDescriptorsFailClosedWithPOSIXError() {
    let descriptors: [NWBrowser.Descriptor] = [
        .bonjour(type: "_http._tcp", domain: "local."),
        .bonjourWithTXTRecord(type: "_ssh._tcp", domain: nil),
        .applicationService(name: "app")
    ]
    for descriptor in descriptors {
        let browser = NWBrowser(for: descriptor, using: .tcp)
        transportExpect(browser.state == .setup, "starts in setup")
        transportExpect(browser.descriptor == descriptor, "descriptor stored")
        transportExpect(browser.parameters.tcpOptions != nil, "tcp params")
        var error: NWError?
        browser.stateUpdateHandler = { state in
            if case .failed(let value) = state { error = value }
            if case .waiting = state { transportExpect(false, "no waiting success") }
            if case .ready = state { transportExpect(false, "no ready bonjour") }
        }
        var changes = 0
        browser.browseResultsChangedHandler = { results, _ in
            transportExpect(results.isEmpty, "no peers")
            changes += 1
        }
        let queue = DispatchQueue(label: "network.browser.depth")
        browser.start(queue: queue)
        transportExpect(error == .posix(.EOPNOTSUPP), "\(descriptor) fail-closed")
        transportExpect(browser.browseResults.isEmpty, "no peers")
        transportExpect(browser.queue === queue, "queue stored")
        transportExpect(browser.debugDescription.isEmpty == false, "debug")
        transportExpect(changes == 1, "empty change callback")
        browser.cancel()
        transportExpect(browser.state == .cancelled, "cancelled")
        transportExpect(browser.state == browser.state, "state eq")
    }
    let txt = NWTXTRecord(["path": "/"])
    let result = NWBrowser.Result(
        endpoint: .hostPort(host: .ipv4(.loopback), port: .http),
        interfaces: [NWInterface(name: "lo", type: .loopback)],
        metadata: .bonjour(txt)
    )
    transportExpect(result.endpoint == .hostPort(host: .ipv4(.loopback), port: .http), "endpoint")
    transportExpect(result.interfaces.first?.name == "lo", "interfaces")
    if case .bonjour(let record) = result.metadata {
        transportExpect(record["path"] == "/", "txt metadata")
    } else {
        preconditionFailure("bonjour metadata")
    }
    transportExpect(result.metadata == .bonjour(txt), "metadata eq")
    transportExpect(result.metadata.debugDescription.isEmpty == false, "metadata debug")
    transportExpect(NWBrowser.Result.Metadata.none != .bonjour(txt), "none vs bonjour")
    transportExpect(result == result, "result eq")
    _ = result.hashValue
    var hasher = Hasher()
    result.hash(into: &hasher)
    let added = NWBrowser.Result.Change(between: nil, result)
    if case .added = added { } else { preconditionFailure("added") }
    let removed = NWBrowser.Result.Change(between: result, nil)
    if case .removed = removed { } else { preconditionFailure("removed") }
    let changed = NWBrowser.Result.Change(between: result, result)
    if case .changed(_, _, let flags) = changed {
        transportExpect(flags.rawValue == 0, "no fabricated interface change")
    } else {
        preconditionFailure("changed")
    }
    let identical = NWBrowser.Result.Change.identical
    transportExpect(identical == identical, "identical eq")
    _ = identical.hashValue
    var changeHasher = Hasher()
    identical.hash(into: &changeHasher)
    _ = NWBrowser.Result.Change.Flags.interfaceAdded
    _ = NWBrowser.Result.Change.Flags.interfaceRemoved
    _ = NWBrowser.Result.Change.Flags.metadataChanged
    _ = NWBrowser.Result.Change.Flags.identical
    let raw = NWBrowser.Result.Change.Flags(rawValue: 1)
    transportExpect(raw.rawValue == 1, "flags raw")
    _ = NWBrowser.Result.Change.Flags.RawValue.self
    _ = NWBrowser.Result.Change.Flags.Element.self
    _ = NWBrowser.Result.Change.Flags.ArrayLiteralElement.self
}

func testConnectionViabilityBetterPathAndContext() {
    let params = NWParameters.tcp
    params.allowLocalEndpointReuse = true
    let listener = try! NWListener(using: params, on: .any)
    listener.start(queue: DispatchQueue(label: "network.viability.listener"))
    transportExpect(listener.state == .ready, "listener ready")
    transportExpect((listener.port?.rawValue ?? 0) != 0, "ephemeral")
    let client = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: params
    )
    var viability: Bool?
    var better: Bool?
    var path: NWPath?
    client.viabilityUpdateHandler = { viability = $0 }
    client.betterPathUpdateHandler = { better = $0 }
    client.pathUpdateHandler = { path = $0 }
    client.start(queue: DispatchQueue(label: "network.viability.client"))
    transportExpect(client.state == .ready, "client ready")
    transportExpect(viability == true, "viable")
    transportExpect(better == false, "no better path on Linux")
    transportExpect(path != nil, "path snapshot")
    transportExpect(client.currentPath != nil, "currentPath")
    let context = NWConnection.ContentContext(identifier: "probe", isFinal: false)
    client.send(
        content: Data([1]),
        contentContext: context,
        isComplete: true,
        completion: .idempotent
    )
    client.cancel()
    listener.cancel()
}

func testProtocolOptionDocumentedDefaults() {
    let tcp = NWProtocolTCP.Options()
    transportExpect(tcp.noDelay == false, "nodelay default")
    transportExpect(tcp.enableKeepalive == false, "keepalive default")
    transportExpect(tcp.connectionTimeout == 0, "timeout default")
    transportExpect(tcp.keepaliveIdle == 0, "idle default")
    transportExpect(tcp.keepaliveCount == 0, "count default")
    transportExpect(tcp.keepaliveInterval == 0, "interval default")
    transportExpect(tcp.enableFastOpen == false, "fast open default")
    transportExpect(tcp.disableECN == false, "ecn default")
    transportExpect(tcp.noOptions == false, "noOptions default")
    transportExpect(tcp.maximumSegmentSize == 0, "mss default")
    let udp = NWProtocolUDP.Options()
    transportExpect(udp.preferNoChecksum == false, "udp checksum default")
    let ip = NWProtocolIP.Options()
    transportExpect(ip.version == .any, "ip any")
    transportExpect(ip.hopLimit == 0, "hop default")
    transportExpect(ip.useMinimumMTU == false, "mtu default")
    transportExpect(ip.disableFragmentation == false, "frag default")
    transportExpect(ip.localAddressPreference == .default, "addr pref")
    let tcpParams = NWParameters.tcp
    transportExpect(tcpParams.serviceClass == .bestEffort, "best effort")
    transportExpect(tcpParams.attribution == .developer, "developer")
    transportExpect(tcpParams.expiredDNSBehavior == .systemDefault, "dns default")
    transportExpect(tcpParams.multipathServiceType == .disabled, "multipath off")
    transportExpect(tcpParams.allowLocalEndpointReuse == false, "reuse off")
}

func testPathMonitorRestartAndFilterUpdates() {
    let cellular = NWPathMonitor(requiredInterfaceType: .cellular)
    var seen: [NWPath] = []
    cellular.pathUpdateHandler = { seen.append($0) }
    cellular.start(queue: DispatchQueue(label: "network.path.cellular"))
    transportExpect(seen.count == 1, "one update")
    transportExpect(seen[0].usesInterfaceType(.cellular) == false, "no cellular")
    transportExpect(
        seen[0].status == .unsatisfied || seen[0].availableInterfaces.isEmpty
            || !seen[0].availableInterfaces.contains { $0.type == .cellular },
        "cellular filter"
    )
    cellular.cancel()
    let wifi = NWPathMonitor(requiredInterfaceType: .wifi)
    wifi.start(queue: DispatchQueue(label: "network.path.wifi"))
    _ = wifi.currentPath.usesInterfaceType(.wifi)
    _ = wifi.currentPath.supportsIPv4
    _ = wifi.currentPath.supportsIPv6
    wifi.cancel()
    let loopbackOnly = NWPathMonitor(requiredInterfaceType: .loopback)
    loopbackOnly.start(queue: DispatchQueue(label: "network.path.loop"))
    transportExpect(loopbackOnly.currentPath.usesInterfaceType(.loopback), "loopback present")
    loopbackOnly.cancel()
}
