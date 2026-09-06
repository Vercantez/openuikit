import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testTCPProtocolStackOptionsAndDefaults() {
    let tcp = TCP()
        .noDelay(true)
        .noOptions(false)
        .noPush(true)
        .persistTimeout(30)
        .fastOpenAllowed(true)
        .connectionTimeout(7)
        .retransmitFinDrop(true)
        .maximumSegmentSize(1400)
        .ecnDisabled(true)
        .ackStretchingDisabled(true)
        .retransmitConnectionDropTime(9)
        .keepalive(idleTimeInSeconds: 10, count: 3, intervalInSeconds: 2)
    expect(tcp.parameters.tcpOptions?.noDelay == true, "noDelay")
    expect(tcp.parameters.tcpOptions?.noPush == true, "noPush")
    expect(tcp.parameters.tcpOptions?.persistTimeout == 30, "persist")
    expect(tcp.parameters.tcpOptions?.enableFastOpen == true, "fastOpen")
    expect(tcp.parameters.tcpOptions?.connectionTimeout == 7, "timeout")
    expect(tcp.parameters.tcpOptions?.retransmitFinDrop == true, "finDrop")
    expect(tcp.parameters.tcpOptions?.maximumSegmentSize == 1400, "mss")
    expect(tcp.parameters.tcpOptions?.disableECN == true, "ecn")
    expect(tcp.parameters.tcpOptions?.disableAckStretching == true, "ack")
    expect(tcp.parameters.tcpOptions?.connectionDropTime == 9, "drop")
    expect(tcp.parameters.tcpOptions?.enableKeepalive == true, "keepalive")
    expect(tcp.parameters.tcpOptions?.keepaliveIdle == 10, "idle")
    expect(tcp.parameters.tcpOptions?.keepaliveCount == 3, "count")
    expect(tcp.parameters.tcpOptions?.keepaliveInterval == 2, "interval")
    let stacked = TCP { IP().version(.v4).hopLimit(64) }
    expect(
        (stacked.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.version == .v4,
        "ip version"
    )
    let metadata = TCP.Metadata(endOfStream: true, other: [])
    expect(metadata.endOfStream, "eos")
    expect(metadata.other.isEmpty, "other")
    _ = DefaultProtocolStorage()
}

func testUDPAndIPProtocolStackOptions() {
    let ip = IP()
        .version(.v6)
        .hopLimit(8)
        .localAddressPreference(.temporary)
        .minimumMTU(true)
        .fragmentationDisabled(true)
        .receiveTimeCalculated(true)
        .multicastLoopbackDisabled(true)
    let options = ip.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options
    expect(options?.version == .v6, "v6")
    expect(options?.hopLimit == 8, "hop")
    expect(options?.localAddressPreference == .temporary, "pref")
    expect(options?.useMinimumMTU == true, "mtu")
    expect(options?.disableFragmentation == true, "df")
    expect(options?.shouldCalculateReceiveTime == true, "rxtime")
    expect(options?.disableMulticastLoopback == true, "mcast")
    let udp = UDP { IP() }.noChecksumPreferred(true)
    expect(
        (udp.parameters.defaultProtocolStack.transportProtocol as? NWProtocolUDP.Options)?.preferNoChecksum == true,
        "nochecksum"
    )
    expect(UDP.Metadata(other: []).other.isEmpty, "udp metadata")
    expect(IP.Metadata(other: []).other.isEmpty, "ip metadata")
}

func testTLSProtocolStackStoresOptionsAndFailsClosed() {
    let tls = TLS()
        .applicationProtocols(["h2"])
        .peerAuthentication(.required)
        .version(min: tls_protocol_version_t(rawValue: 0x0303), max: nil)
        .cipherSuites([tls_ciphersuite_t(rawValue: 0x1301)])
        .cipherSuiteGroups([tls_ciphersuite_group_t(rawValue: 1)])
        .ticketsEnabled(false)
        .earlyDataEnabled(true)
        .localIdentity(sec_identity())
    expect(tls.applicationProtocolsValue == ["h2"], "alpn")
    expect(tls.peerAuthenticationValue == .required, "auth")
    expect(tls.ticketsEnabledValue == false, "tickets")
    expect(tls.earlyDataEnabledValue == true, "early")
    expect(tls.cipherSuiteValues.count == 1, "suites")
    expect(tls.minVersion?.rawValue == 0x0303, "min ver")
    expect(TLS.PeerAuthentication.none != .optional, "peer cases")
    _ = TLS.PeerAuthentication.required.hashValue
    var hasher = Hasher()
    TLS.PeerAuthentication.none.hash(into: &hasher)
    let stacked = TLS { TCP() }
    let connection = NetworkConnection(to: .hostPort(host: .ipv4(.loopback), port: .https), using: { stacked })
    _ = connection.start()
    if case .failed(let error) = connection.state {
        if case .tls(let status) = error {
            expect(status == -9800, "errSSLProtocol")
        } else {
            preconditionFailure("tls domain")
        }
    } else {
        preconditionFailure("tls fail-closed")
    }
    expect(TLS.Metadata(endOfStream: false).endOfStream == false, "tls metadata")
}

func testQUICProtocolStackDataModelAndFailClosedStart() {
    var quic = QUIC(alpn: ["h3"])
        .idleTimeout(30)
        .initialMaxData(1024)
        .maxUDPPayloadSize(1200)
        .maxDatagramFrameSize(1100)
        .initialMaxBidirectionalStreams(4)
        .initialMaxUnidirectionalStreams(2)
        .initialMaxStreamDataUnidirectional(8)
        .initialMaxStreamDataBidirectionalLocal(9)
        .initialMaxStreamDataBidirectionalRemote(10)
    quic = QUIC(alpn: ["h3"]) { UDP() }
    let options = quic.parameters.defaultProtocolStack.transportProtocol as? NWProtocolQUIC.Options
    expect(options?.alpn == ["h3"], "alpn")
    _ = quic.tls.cipherSuites([])
    _ = quic.tls.ciphersuiteGroups([])
    _ = quic.tls.peerAuthentication(.none)
    _ = quic.tls.localIdentity(sec_identity())
    _ = quic.tls.certificateValidator { _, _ in true }
    let connection = NetworkConnection(to: .hostPort(host: .ipv4(.loopback), port: .https), using: { QUIC(alpn: ["h3"]) })
    _ = connection.onStateUpdate { _, _ in }
        .onPathUpdate { _, _ in }
        .onViabilityUpdate { _, _ in }
        .onBetterPathUpdate { _, _ in }
        .start()
    if case .failed(let error) = connection.state {
        expect(error == .posix(.EOPNOTSUPP), "quic fail-closed")
    } else {
        preconditionFailure("quic must fail closed")
    }
    connection.applicationError = NWProtocolQUIC.ApplicationError(code: 7)
    expect(connection.applicationError.code == 7, "app error")
    expect(connection.negotiatedALPN == nil, "no alpn")
    expect(connection.remoteIdleTimeout == 0, "idle")
    expect(connection.usableDatagramFrameSize == 0, "frame")
    expect(connection.remoteMaxStreamsBidirectional == 0, "bidi")
    expect(connection.remoteMaxStreamsUnidirectional == 0, "uni")
    connection.keepalive = .on
    expect(connection.keepalive == .on, "keepalive")
    _ = connection.securityProtocolMetadata.encodedData
    _ = connection.datagrams.parent
    do {
        _ = try connection.openStream(directionality: .bidirectional)
        preconditionFailure("openStream must throw")
    } catch {
        expect((error as? NWError) == .posix(.EOPNOTSUPP), "openStream fail-closed")
    }
    _ = QUIC.ProtocolStorage()
    expect(QUICStream.Directionality.bidirectional != .unidirectional, "dir")
    expect(QUICStream.Initiator.client != .server, "initiator")
    _ = QUICStream.Directionality.bidirectional.hashValue
    _ = QUICStream.Initiator.server.hashValue
    var hasher = Hasher()
    QUICStream.Directionality.unidirectional.hash(into: &hasher)
    QUICStream.Initiator.client.hash(into: &hasher)
    let streamMeta = QUICStream.Metadata(endOfStream: true, other: [])
    expect(streamMeta.endOfStream, "stream eos")
    expect(QUICDatagram.Metadata(other: []).other.isEmpty, "datagram meta")
    _ = QUICStream()
    _ = QUICDatagram()
    let stream = QUIC.Stream<QUICStream>(parent: connection)
    expect(stream.streamID == 0, "stream id")
    expect(stream.directionality == .bidirectional, "stream dir")
    expect(stream.initiator == .client, "stream initiator")
    expect(stream.streamApplicationErrorCode == 0, "stream app error")
    expect(stream.parent === connection, "stream parent")
    let multiplex = NetworkConnection(
        to: .hostPort(host: .ipv4(.loopback), port: .https),
        using: NWParametersBuilder(auto: { QUIC(alpn: ["h3"]) })
    )
    _ = multiplex.start()
    multiplex.cancel()
    let connectable: any Connectable = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .https)
    let viaConnectable = NetworkConnection(to: connectable, using: { QUIC(alpn: ["h3"]) })
    viaConnectable.cancel()
    _ = NetworkConnection(
        to: connectable,
        using: NWParametersBuilder(auto: { QUIC(alpn: ["h3"]) })
    )
}

func testWebSocketFramerAndCoderProtocolStacks() {
    let ws = WebSocket { TCP() }
        .autoReplyPing(true)
        .skipHandshake(true)
        .maximumMessageSize(4096)
        .subprotocols(["chat"])
        .additionalHeaders([("X-Test", "1")])
    expect(
        (ws.parameters.defaultProtocolStack.applicationProtocols.first as? NWProtocolWebSocket.Options)?.autoReplyPing == true,
        "auto ping"
    )
    expect(
        (ws.parameters.defaultProtocolStack.applicationProtocols.first as? NWProtocolWebSocket.Options)?.skipHandshake == true,
        "skip"
    )
    expect(
        (ws.parameters.defaultProtocolStack.applicationProtocols.first as? NWProtocolWebSocket.Options)?.maximumMessageSize == 4096,
        "max"
    )
    let wsMeta = WebSocket.Metadata(opcode: .text, closeCode: .protocolCode(.normalClosure), isComplete: true)
    expect(wsMeta.opcode == .text, "opcode")
    expect(wsMeta.closeCode?.rawValue == 1000, "close")
    expect(wsMeta.isComplete, "complete")
    expect(wsMeta.lastMessage == false, "ws last")
    expect(wsMeta.other.isEmpty, "ws other")
    let framer = Framer<LengthPrefixedHostFramer>(using: LengthPrefixedHostFramer.self) { TCP() }
    expect(framer.options.definition.identifier.isEmpty == false, "framer def")
    let message = NWProtocolFramer.Message(definition: LengthPrefixedHostFramer.definition)
    let framerMeta = Framer<LengthPrefixedHostFramer>.Metadata(
        framer: message,
        isComplete: true,
        lastMessage: false,
        other: []
    )
    expect(framerMeta.isComplete, "framer complete")
    expect(framerMeta.lastMessage == false, "last")
    expect(framerMeta.framer === message, "message")
    _ = Framer<LengthPrefixedHostFramer> { TCP() }
    let coder = Coder(sending: String.self, receiving: String.self, using: NetworkJSONCoder()) { TCP() }
    let jsonPayload = try! coder.coder.makeEncoder().encode(["ok": true])
    expect(jsonPayload.isEmpty == false, "json encoder")
    let decoded = Coder(String.self, using: NetworkJSONCoder.json) { TCP() }
    _ = decoded.parameters
    _ = Coder(receiving: String.self, sending: String.self, using: NetworkJSONCoder()) { TCP() }
    _ = Coder(sending: String.self, receiving: String.self, using: NetworkJSONCoder()) { UDP() }
    _ = Coder(receiving: String.self, sending: String.self, using: NetworkJSONCoder()) { UDP() }
    _ = Coder(String.self, using: NetworkJSONCoder.json) { UDP() }
    _ = Framer<LengthPrefixedHostFramer>(using: LengthPrefixedHostFramer.self) { UDP() }
    _ = Framer<LengthPrefixedHostFramer> { UDP() }
    _ = WebSocket { UDP() }
    let plist = NetworkPropertyListCoder()
    let plistPayload = try! plist.makeEncoder().encode(["ok": true])
    let plistRoundTrip = try! plist.makeDecoder().decode([String: Bool].self, from: plistPayload)
    expect(plistRoundTrip["ok"] == true, "plist round trip")
    expect((try! NetworkJSONCoder.json.makeDecoder().decode([String: Bool].self, from: jsonPayload))["ok"] == true, "static json")
    expect(try! NetworkPropertyListCoder.propertyList.makeEncoder().encode(["ok": true]).isEmpty == false, "static plist")
    let payload = try! NetworkJSONCoder().makeEncoder().encode(["ok": true])
    let roundTrip = try! NetworkJSONCoder().makeDecoder().decode([String: Bool].self, from: payload)
    expect(roundTrip["ok"] == true, "json round trip")
    let coderMeta = Coder<String, String, NetworkJSONCoder>.Metadata(isComplete: false, lastMessage: true)
    expect(coderMeta.isComplete == false, "coder complete")
    expect(coderMeta.lastMessage, "coder last")
    let wsConnection = NetworkConnection(
        to: .hostPort(host: .ipv4(.loopback), port: 9),
        using: { WebSocket { TCP() } }
    )
    wsConnection.channel.sendIdempotent("hi")
    wsConnection.channel.sendIdempotent(Data([0x81]))
    let tlvChannel = NetworkChannel<TCP>(inner: NWConnection(to: .hostPort(host: .ipv4(.loopback), port: 9), using: .tcp))
    tlvChannel.sendIdempotent(Data([1]), type: 1, lastMessage: false)
    _ = TLS().certificateValidator { _, _ in true }
}
