import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testTypedTCPLoopbackSendIdempotent() {
    let listener = try! NetworkListener(using: { TCP().localEndpointReuseAllowed(true) })
    var inbound: NetworkConnection<TCP>?
    listener.newConnectionHandler = { connection in
        inbound = connection
        _ = connection.start()
    }
    var listenerReady = false
    _ = listener.onStateUpdate { _, state in
        if case .ready = state { listenerReady = true }
    }
    _ = listener.start()
    expect(listenerReady || listener.state == .ready, "listener ready")
    expect(listener.port != nil && listener.port?.rawValue != 0, "ephemeral port")
    expect(listener.debugDescription.isEmpty == false, "listener debug")
    expect(listener.newConnectionLimit > 0, "limit")
    _ = listener.newConnectionLimit(8)
    expect(listener.newConnectionLimit == 8, "limit set")
    expect(listener.service == nil, "no bonjour")
    _ = listener.onServiceRegistrationUpdate { _, _ in }

    let client = NetworkConnection(
        to: .hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: { TCP().localEndpointReuseAllowed(true) }
    )
    var clientReady = false
    _ = client.onStateUpdate { _, state in
        if case .ready = state { clientReady = true }
    }
    _ = client.onPathUpdate { _, _ in }
        .onViabilityUpdate { _, _ in }
        .onBetterPathUpdate { _, _ in }
    _ = client.start()
    expect(clientReady || client.state == .ready, "client ready")
    expect(client.currentPath != nil, "path")
    expect(client.localEndpoint != nil, "local")
    expect(client.remoteEndpoint != nil, "remote")
    expect(client.debugDescription.isEmpty == false, "conn debug")
    expect(client.channel.maximumDatagramSize > 0, "datagram size")
    expect(client.channel.id.isEmpty == false, "channel id")
    expect(client.channel.metadata(definition: NWProtocolTCP.definition) == nil, "no metadata")
    client.channel.sendIdempotent(Data([1, 2, 3, 4]), endOfStream: false)
    client.channel.sendIdempotent(UInt8(7), endOfStream: false)
    client.channel.sendIdempotent(Data([9]), endOfStream: true, metadata: { })
    client.channel.sendIdempotent("hi")
    let connectable: any Connectable = NWEndpoint.hostPort(host: .ipv4(.loopback), port: listener.port!)
    let viaConnectable = NetworkConnection(to: connectable, using: { TCP().localEndpointReuseAllowed(true) })
    viaConnectable.cancel()
    let extraListener = try! NetworkListener(using: NWParametersBuilder(auto: { TCP().localEndpointReuseAllowed(true) }))
    extraListener.cancel()
    expect(client.channel.hashValue == client.channel.hashValue, "hash stable")
    expect(client.channel == client.channel, "identity eq")
    _ = inbound
    client.tryNextEndpoint()
    listener.cancel()
    client.cancel()
}

func testTypedUDPListenerBindsLoopbackPort() {
    let listener = try! NetworkListener(using: { UDP().localEndpointReuseAllowed(true) })
    _ = listener.start()
    expect(listener.state == .ready, "udp listener ready")
    expect(listener.port != nil, "udp port")
    let client = NetworkConnection(
        to: NWEndpoint.hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: { UDP() }
    )
    let viaBuilder = NetworkConnection(
        to: NWEndpoint.hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: NWParametersBuilder(auto: { UDP() })
    )
    viaBuilder.cancel()
    let connectable: any Connectable = NWEndpoint.hostPort(host: .ipv4(.loopback), port: listener.port!)
    NetworkConnection(to: connectable, using: { UDP() }).cancel()
    NetworkConnection(to: connectable, using: NWParametersBuilder(auto: { UDP() })).cancel()
    _ = client.start()
    expect(client.state == .ready, "udp client ready")
    client.channel.sendIdempotent(Data([7, 8]))
    client.cancel()
    listener.cancel()
}

func testTypedListenerBonjourProviderFailsClosed() {
    do {
        _ = try NetworkListener(
            for: BonjourListenerProvider(name: "svc", type: "_ssh._tcp", domain: "local."),
            using: { TCP() }
        )
        preconditionFailure("bonjour listener must throw")
    } catch {
        expect((error as? NWError) == .posix(.EOPNOTSUPP), "EOPNOTSUPP")
    }
    let provider = BonjourListenerProvider.bonjour(name: "a", type: "_http._tcp", domain: nil, txtRecord: NWTXTRecord(["k": "v"]))
    expect(provider.service.type == "_http._tcp", "service type")
    expect(provider.service.txtRecordObject != nil, "txt")
}

func testNetworkBrowserFailClosedWithoutMDNS() {
    let browser = NetworkBrowser(for: Bonjour.bonjour("_ssh._tcp", domain: "local.", includeTxtRecord: true), using: .tcp)
    expect(browser.state == .setup, "setup")
    var sawFailed = false
    _ = browser.onStateUpdate { _, state in
        if case .failed(let error) = state {
            expect(error == .posix(.EOPNOTSUPP), "browser error")
            sawFailed = true
        }
    }
    _ = browser.start()
    expect(sawFailed, "failed callback")
    expect(browser.debugDescription.isEmpty == false, "debug")
    if case .failed = NetworkBrowser<Bonjour>.State.failed(.posix(.EOPNOTSUPP)) {
        // enum cases
    }
    _ = NetworkBrowser<Bonjour>.State.setup
    _ = NetworkBrowser<Bonjour>.State.ready
    _ = NetworkBrowser<Bonjour>.State.cancelled
    _ = NetworkBrowser<Bonjour>.State.waiting(.posix(.EAGAIN))
    let result: NetworkBrowser<Bonjour>.RunResult<Int> = .finish(1)
    if case .finish(let value) = result {
        expect(value == 1, "finish")
    }
    if case .continue = NetworkBrowser<Bonjour>.RunResult<Int>.continue {
        // continue case
    }
    let endpoint = Bonjour.Endpoint(
        name: "n",
        type: "_ssh._tcp",
        domain: "local.",
        result: NWBrowser.Result(
            endpoint: .service(name: "n", type: "_ssh._tcp", domain: "local.", interface: nil),
            interfaces: [],
            metadata: .none
        ),
        txtRecord: NWTXTRecord()
    )
    expect(endpoint.description.contains("_ssh._tcp"), "description")
    expect(endpoint.id.contains("n"), "id")
    expect(endpoint.nwEndpoint == endpoint.result.endpoint, "nwEndpoint")
}

func testNWParametersProviderFluentBuildersOnTCP() {
    let interface = NWInterface(name: "lo", type: .loopback, index: 1)
    let tcp = TCP()
        .serviceClass(.responsiveData)
        .localEndpoint(.hostPort(host: .ipv4(.loopback), port: .http))
        .fastOpenAllowed(true)
        .requiredInterface(interface)
        .expiredDNSBehavior(.allow)
        .noProxiesPreferred(true)
        .peerToPeerIncluded(true)
        .multipathServiceType(.handover)
        .prohibitedInterfaces([interface])
        .requiredInterfaceType(.loopback)
        .dnssecValidationRequired(true)
        .expensivePathsProhibited(true)
        .prohibitedInterfaceTypes([.cellular])
        .localEndpointReuseAllowed(true)
        .constrainedPathsProhibited(true)
        .ultraConstrainedPathsAllowed(true)
        .localOnly(true)
        .localPort(.https)
    expect(tcp.parameters.serviceClass == .responsiveData, "class")
    expect(tcp.parameters.allowFastOpen, "fastopen")
    expect(tcp.parameters.preferNoProxies, "noproxy")
    expect(tcp.parameters.includePeerToPeer, "p2p")
    expect(tcp.parameters.multipathServiceType == .handover, "mp")
    expect(tcp.parameters.requiredInterfaceType == .loopback, "lo type")
    expect(tcp.parameters.requiresDNSSECValidation, "dnssec")
    expect(tcp.parameters.prohibitExpensivePaths, "expensive")
    expect(tcp.parameters.allowLocalEndpointReuse, "reuse")
    expect(tcp.parameters.prohibitConstrainedPaths, "constrained")
    expect(tcp.parameters.allowUltraConstrainedPaths, "ultra")
    expect(tcp.parameters.acceptLocalOnly, "localOnly")
    expect(tcp.parameters.parameters === tcp.parameters, "parameters identity")
    let built = NWParametersBuilder<TCP>.parameters { TCP() }
        .serviceClass(.responsiveData)
        .localEndpoint(.hostPort(host: .ipv4(.loopback), port: .http))
        .fastOpenAllowed(true)
        .requiredInterface(interface)
        .expiredDNSBehavior(.allow)
        .noProxiesPreferred(true)
        .peerToPeerIncluded(true)
        .multipathServiceType(.handover)
        .prohibitedInterfaces([interface])
        .requiredInterfaceType(.loopback)
        .dnssecValidationRequired(true)
        .expensivePathsProhibited(true)
        .prohibitedInterfaceTypes([.cellular])
        .localEndpointReuseAllowed(true)
        .constrainedPathsProhibited(true)
        .ultraConstrainedPathsAllowed(true)
        .localOnly(true)
        .localPort(.https)
    expect(built.parameters.tcpOptions != nil, "builder tcp")
    expect(built.parameters.serviceClass == .responsiveData, "builder class")
    let withInitial = NWParametersBuilder<TCP>.parameters(initialParameters: .tcp) { TCP() }
    expect(withInitial.parameters.tcpOptions != nil, "initial")
    _ = NWParametersBuilder<TCP>(auto: { TCP() })
    _ = ProtocolStackBuilder<TCP>.buildBlock(TCP())
    _ = ProtocolMetadataBuilder.buildBlock()
    _ = DefaultProtocolStorage()
}

func testUnexpectedEndpointAndTXTDecoder() {
    let endpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .ssh)
    let unexpected = UnexpectedEndpointType(endpoint: endpoint)
    expect(unexpected.endpoint == endpoint, "endpoint")
    expect(unexpected.debugDescription.contains("22"), "debug")
    expect(unexpected.localizedDescription.isEmpty == false, "localized")
    let decoder = TXTRecordDecoder()
    let record = NWTXTRecord(["path": "/", "ok": "true"])
    let decoded = try! decoder.decode([String: String].self, from: record)
    expect(decoded["path"] == "/", "txt json")
}

func testMulticastGroupInitFailsClosed() {
    do {
        _ = try NWMulticastGroup(
            for: [.hostPort(host: .ipv4(IPv4Address("224.0.0.1")!), port: 5353)],
            from: nil,
            disableUnicast: true
        )
        preconditionFailure("multicast must throw")
    } catch {
        expect((error as? NWError) == .posix(.EOPNOTSUPP), "multicast fail-closed")
    }
    _ = NWMultiplexGroup(to: .hostPort(host: .ipv4(.loopback), port: .http))
}

func testTypedListenerStateCases() {
    let setup = NetworkListener<TCP>.State.setup
    let ready = NetworkListener<TCP>.State.ready
    let cancelled = NetworkListener<TCP>.State.cancelled
    let waiting = NetworkListener<TCP>.State.waiting(.posix(.EAGAIN))
    let failed = NetworkListener<TCP>.State.failed(.posix(.EOPNOTSUPP))
    expect(setup != ready, "distinct")
    expect(cancelled != failed, "cancelled")
    if case .waiting = waiting, case .failed = failed {
        // exercised
    }
    let add = NetworkListener<TCP>.ServiceRegistrationChange.add(.hostPort(host: .ipv4(.loopback), port: .http))
    let remove = NetworkListener<TCP>.ServiceRegistrationChange.remove(.hostPort(host: .ipv4(.loopback), port: .http))
    if case .add = add, case .remove = remove {
        // exercised
    }
    let channelSetup = NetworkChannel<TCP>.State.setup
    let channelReady = NetworkChannel<TCP>.State.ready
    let channelPreparing = NetworkChannel<TCP>.State.preparing
    let channelCancelled = NetworkChannel<TCP>.State.cancelled
    let channelWaiting = NetworkChannel<TCP>.State.waiting(.posix(.EAGAIN))
    let channelFailed = NetworkChannel<TCP>.State.failed(.posix(.ECONNREFUSED))
    expect(channelSetup != channelReady, "channel distinct")
    expect(channelPreparing != channelCancelled, "preparing")
    if case .waiting = channelWaiting, case .failed = channelFailed {
        // exercised
    }
}
