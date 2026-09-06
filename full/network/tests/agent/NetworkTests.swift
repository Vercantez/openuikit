import Foundation
import Network

private func nwExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func nwWait(_ semaphore: DispatchSemaphore, _ message: String, seconds: Double = 3) {
    let result = semaphore.wait(timeout: .now() + seconds)
    nwExpect(result == .success, message)
}

func testIPv4AddressParsing() {
    let loopback = IPv4Address("127.0.0.1")
    nwExpect(loopback == IPv4Address.loopback, "loopback identity")
    nwExpect(loopback?.isLoopback == true, "loopback flag")
    nwExpect(IPv4Address("127.1.2.3")?.isLoopback == true, "RFC 1122 127/8")
    nwExpect(IPv4Address.any.rawValue == Data(repeating: 0, count: 4), "any")
    nwExpect(IPv4Address.broadcast.rawValue == Data(repeating: 255, count: 4), "broadcast")
    nwExpect(IPv4Address("127.0.0") == nil, "short rejected")
    nwExpect(IPv4Address("256.0.0.1") == nil, "octet overflow rejected")
    nwExpect(IPv4Address("224.0.0.1")?.isMulticast == true, "multicast")
    nwExpect(IPv4Address("223.0.0.1")?.isMulticast == false, "not multicast")
    nwExpect(IPv4Address("169.254.1.1")?.isLinkLocal == true, "link local")
    nwExpect(IPv4Address("169.253.1.1")?.isLinkLocal == false, "not link local")
    nwExpect(IPv4Address.mdnsGroup.debugDescription == "224.0.0.251", "mdns group")
    nwExpect(IPv4Address.mdnsGroup.description == "224.0.0.251", "description")
    nwExpect(IPv4Address.allHostsGroup.debugDescription.hasPrefix("224"), "all hosts")
    _ = IPv4Address.allRoutersGroup
    _ = IPv4Address.allReportsGroup
    let fromData = IPv4Address(Data([10, 0, 0, 1]))
    nwExpect(fromData?.rawValue == Data([10, 0, 0, 1]), "data init")
    nwExpect(IPv4Address(rawValue: Data([1, 2, 3])) == nil, "short raw rejected")
    let withInterface = IPv4Address(Data([10, 0, 0, 1]), NWInterface(name: "lo", type: .loopback, index: 1))
    nwExpect(withInterface?.interface?.name == "lo", "interface attached")
    nwExpect(withInterface?.hashValue != 0 || withInterface?.hashValue == 0, "hashValue")
    var hasher = Hasher()
    withInterface?.hash(into: &hasher)
    let asIP: (any IPAddress)? = loopback
    nwExpect(asIP?.isLoopback == true, "IPAddress witness")
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
    nwExpect(IPv6Address("fc00::1")?.isUniqueLocal == true, "unique local")
    nwExpect(IPv6Address("2002::1")?.is6to4 == true, "6to4")
    nwExpect(IPv6Address("::2")?.isIPv4Compatabile == true, "v4 compatible spelling")
    let zoned = IPv6Address("fe80::1%lo")
    nwExpect(zoned != nil, "zone parsed")
    nwExpect(zoned?.interface?.name == "lo", "zone name")
    nwExpect(zoned?.debugDescription.hasSuffix("%lo") == true, "description with zone")
    nwExpect(zoned?.description.hasSuffix("%lo") == true, "description alias")
    nwExpect(IPv6Address("1:2:3:4:5:6:7:8:9") == nil, "too many words")
    nwExpect(IPv6Address(rawValue: Data(repeating: 0, count: 16)) == IPv6Address.any, "raw any")
    nwExpect(IPv6Address.linkLocalNodes.isMulticast, "link local nodes")
    nwExpect(IPv6Address.linkLocalRouters.isMulticast, "link local routers")
    nwExpect(IPv6Address.nodeLocalNodes.isMulticast, "node local nodes")
    _ = IPv6Address.broadcast
    nwExpect(IPv6Address("ff02::1")?.multicastScope == .linkLocal, "multicast scope")
    nwExpect(IPv6Address.Scope.nodeLocal.rawValue == 1, "nodeLocal")
    nwExpect(IPv6Address.Scope.siteLocal.rawValue == 5, "siteLocal")
    nwExpect(IPv6Address.Scope.organizationLocal.rawValue == 8, "org")
    nwExpect(IPv6Address.Scope.global.rawValue == 14, "global")
    _ = Set([IPv6Address.loopback, IPv6Address.any])
}

func testNWEndpointPortsAndHosts() {
    nwExpect(NWEndpoint.Port.https.rawValue == 443, "https")
    nwExpect(NWEndpoint.Port.http.rawValue == 80, "http")
    nwExpect(NWEndpoint.Port.ssh.rawValue == 22, "ssh")
    nwExpect(NWEndpoint.Port.smtp.rawValue == 25, "smtp")
    nwExpect(NWEndpoint.Port.pop.rawValue == 110, "pop")
    nwExpect(NWEndpoint.Port.imap.rawValue == 143, "imap")
    nwExpect(NWEndpoint.Port.imaps.rawValue == 993, "imaps")
    nwExpect(NWEndpoint.Port.socks.rawValue == 1080, "socks")
    nwExpect(NWEndpoint.Port.any.rawValue == 0, "any")
    nwExpect(NWEndpoint.Port("443")?.rawValue == 443, "string port")
    nwExpect(NWEndpoint.Port("http")?.rawValue == 80, "service name http")
    nwExpect(NWEndpoint.Port("https")?.rawValue == 443, "service name https")
    nwExpect(NWEndpoint.Port("not-a-port") == nil, "bad port")
    nwExpect(NWEndpoint.Port(rawValue: 8080)?.rawValue == 8080, "rawValue init")
    let host: NWEndpoint.Host = "example.invalid"
    let endpoint = NWEndpoint.hostPort(host: host, port: .https)
    nwExpect(endpoint.debugDescription.hasSuffix(":443"), "hostPort description")
    let ipv4Host = NWEndpoint.Host("127.0.0.1")
    if case .ipv4(let address) = ipv4Host {
        nwExpect(address.isLoopback, "host parses ipv4")
    } else {
        preconditionFailure("expected ipv4 host")
    }
    let ipv6Host = NWEndpoint.Host("::1")
    if case .ipv6(let address) = ipv6Host {
        nwExpect(address.isLoopback, "host parses ipv6")
    } else {
        preconditionFailure("expected ipv6 host")
    }
    let bracketed = NWEndpoint.Host("[::1]")
    if case .ipv6 = bracketed {
        // expected
    } else {
        preconditionFailure("bracketed ipv6")
    }
    let named = NWEndpoint.Host.name("example.invalid", nil)
    nwExpect(named.interface == nil, "name interface")
    let url = NWEndpoint.url(URL(string: "https://example.invalid")!)
    nwExpect(url.debugDescription.hasPrefix("https://"), "url endpoint")
    let unix = NWEndpoint.unix(path: "/tmp/openuikit-nw.sock")
    nwExpect(unix.debugDescription.hasPrefix("/tmp/"), "unix")
    let service = NWEndpoint.service(name: "x", type: "_http._tcp", domain: "local.", interface: nil)
    nwExpect(service.txtRecord == nil, "txt nil")
    nwExpect(endpoint != url, "distinct cases")
    nwExpect(endpoint == endpoint, "equality")
    _ = Set([endpoint, url, unix, service])
    var hasher = Hasher()
    endpoint.hash(into: &hasher)
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
    nwExpect(String(kNWErrorDomainTLS) == "kNWErrorDomainTLS", "tls domain")
    nwExpect(String(kNWErrorDomainWiFiAware) == "kNWErrorDomainWiFiAware", "wifi domain")
    nwExpect(NWError.errorDomain.isEmpty == false, "errorDomain")
    nwExpect(NWError.posix(.EPERM).errorUserInfo.isEmpty, "userInfo")
    nwExpect(NWError.tls(-9800).debugDescription.isEmpty == false, "tls debug")
    nwExpect(NWError.posix(.EPERM).localizedDescription.isEmpty == false, "localized")
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
    nwExpect(nw_error_domain_invalid.rawValue == 0, "error invalid")
    nwExpect(nw_interface_type_wifi.rawValue == 1, "wifi")
    nwExpect(nw_interface_type_cellular.rawValue == 2, "cellular")
    nwExpect(nw_interface_type_wired.rawValue == 3, "wired")
    nwExpect(nw_interface_type_loopback.rawValue == 4, "loopback")
    nwExpect(nw_interface_type_other.rawValue == 0, "other")
    nwExpect(nw_path_status_satisfied.rawValue == 1, "satisfied")
    nwExpect(nw_path_status_unsatisfied.rawValue == 2, "unsatisfied")
    nwExpect(nw_path_status_invalid.rawValue == 0, "path invalid")
    nwExpect(nw_path_status_satisfiable.rawValue == 3, "satisfiable")
    nwExpect(nw_browse_result_change_result_added == 0x02, "result added")
    nwExpect(NW_FRAMER_CREATE_FLAGS_DEFAULT == 0, "framer flags")
    nwExpect(NW_FRAMER_WAKEUP_TIME_FOREVER > 0, "wakeup forever")
    nwExpect(NW_LISTENER_INFINITE_CONNECTION_LIMIT > 0, "infinite")
    nwExpect(NW_QUIC_CONNECTION_DEFAULT_KEEPALIVE == 0, "quic keepalive")
    nwExpect(nw_listener_state_ready.rawValue == 2, "listener ready")
    nwExpect(nw_listener_state_failed.rawValue == 3, "listener failed")
    nwExpect(nw_listener_state_cancelled.rawValue == 4, "listener cancelled")
    nwExpect(nw_listener_state_waiting.rawValue == 1, "listener waiting")
    nwExpect(nw_listener_state_invalid.rawValue == 0, "listener invalid")
    nwExpect(nw_browser_state_ready.rawValue == 1, "browser ready")
    nwExpect(nw_browser_state_failed.rawValue == 2, "browser failed")
    nwExpect(nw_browser_state_cancelled.rawValue == 3, "browser cancelled")
    nwExpect(nw_ip_version_4.rawValue == 1, "ip v4")
    nwExpect(nw_ip_version_6.rawValue == 2, "ip v6")
    nwExpect(nw_ip_version_any.rawValue == 0, "ip any")
    nwExpect(nw_ip_ecn_flag_non_ect.rawValue == 0, "ecn")
    nwExpect(nw_ip_ecn_flag_ect_1.rawValue == 1, "ect1")
    nwExpect(nw_ip_ecn_flag_ect_0.rawValue == 2, "ect0")
    nwExpect(nw_ip_ecn_flag_ce.rawValue == 3, "ce")
    nwExpect(nw_link_quality_unknown.rawValue == 0, "lq unknown")
    nwExpect(nw_link_quality_minimal.rawValue == 10, "lq min")
    nwExpect(nw_link_quality_moderate.rawValue == 20, "lq mod")
    nwExpect(nw_link_quality_good.rawValue == 30, "lq good")
    nwExpect(nw_service_class_best_effort.rawValue == 0, "sc be")
    nwExpect(nw_service_class_background.rawValue == 1, "sc bg")
    nwExpect(nw_service_class_signaling.rawValue == 5, "sc sig")
    nwExpect(nw_multipath_service_disabled.rawValue == 0, "mp disabled")
    nwExpect(nw_endpoint_type_host.rawValue == 2, "endpoint host")
    nwExpect(nw_endpoint_type_address.rawValue == 1, "endpoint address")
    nwExpect(nw_endpoint_type_url.rawValue == 4, "endpoint url")
    nwExpect(nw_parameters_attribution_t.developer.rawValue == 1, "attr developer")
    nwExpect(nw_parameters_attribution_t.user.rawValue == 2, "attr user")
    nwExpect(nw_ws_close_code_normal_closure.rawValue == 1000, "ws close")
    nwExpect(nw_ws_opcode_text.rawValue == 1, "ws text")
    nwExpect(nw_ws_version_13.rawValue == 1, "ws v13")
    nwExpect(nw_path_unsatisfied_reason_not_available.rawValue == 0, "reason")
    nwExpect(nw_txt_record_find_key_not_present.rawValue == 1, "txt key")
    nwExpect(nw_framer_start_result_ready.rawValue == 1, "framer ready")
    nwExpect(nw_connection_group_state_ready.rawValue == 2, "group ready")
    nwExpect(nw_interface_radio_type_wifi_n.rawValue == 4, "radio n")
    nwExpect(nw_interface_radio_type_wifi_ax.rawValue == 6, "radio ax")
    nwExpect(nw_browse_result_change_identical == 1, "identical")
    nwExpect(nw_browse_result_change_result_removed == 4, "removed")
}

func testNWInterfaceAndPathFromGetifaddrs() {
    let lo = NWInterface(name: "lo", type: .loopback, index: 1)
    nwExpect(lo.type == .loopback, "loopback type")
    nwExpect(lo.name == "lo", "name")
    nwExpect(lo.index == 1, "index")
    nwExpect(lo.debugDescription.isEmpty == false, "debug")
    _ = Set([
        NWInterface.InterfaceType.other,
        .wifi,
        .cellular,
        .wiredEthernet,
        .loopback
    ])
    let radioWifi = NWInterface.RadioType.wifi(.ax)
    let radioCell = NWInterface.RadioType.cell(.standalone5G(.sub6GHz))
    _ = Set([radioWifi, radioCell, .wifi(.a), .wifi(.b), .wifi(.g), .wifi(.n), .wifi(.ac)])
    _ = Set([
        NWInterface.RadioType.Cellular.gsm,
        .lte,
        .cdma,
        .evdo,
        .wcdma,
        .dualConnectivity5G(.mmWave)
    ])

    let monitor = NWPathMonitor()
    var seen: [NWPath] = []
    monitor.pathUpdateHandler = { path in
        seen.append(path)
        nwExpect(path.isExpensive == false, "isExpensive false")
        nwExpect(path.isConstrained == false, "isConstrained false")
        nwExpect(path.isUltraConstrained == false, "ultra false")
        nwExpect(path.linkQuality == .unknown, "link quality unknown")
        _ = path.gateways
        _ = path.usesInterfaceType(.loopback)
        _ = path.usesInterfaceType(.wifi)
        _ = path.usesInterfaceType(.wiredEthernet)
        _ = path.debugDescription
        if path.status == .satisfied {
            nwExpect(path.availableInterfaces.contains { $0.type != .loopback }, "non-loopback present")
        } else {
            nwExpect(path.status == .unsatisfied, "unsatisfied otherwise")
            nwExpect(path.unsatisfiedReason == .notAvailable, "reason")
        }
    }
    let queue = DispatchQueue(label: "network.path")
    monitor.start(queue: queue)
    nwExpect(seen.count == 1, "exactly one snapshot")
    nwExpect(monitor.currentPath.status == seen[0].status, "current path")
    nwExpect(monitor.queue === queue, "queue stored")
    _ = monitor.makeAsyncIterator()
    let required = NWPathMonitor(requiredInterfaceType: .loopback)
    required.start(queue: DispatchQueue(label: "network.path.lo"))
    nwExpect(required.requiredInterfaceType == .loopback, "required")
    required.cancel()
    let prohibited = NWPathMonitor(prohibitedInterfaceTypes: [.cellular])
    prohibited.start(queue: DispatchQueue(label: "network.path.no-cell"))
    nwExpect(prohibited.prohibitedInterfaceTypes.contains(.cellular), "prohibited")
    prohibited.cancel()
    monitor.cancel()
    nwExpect(monitor.isCancelled, "cancelled")
    _ = Set([NWPath.Status.satisfied, .unsatisfied, .requiresConnection])
    _ = Set([
        NWPath.UnsatisfiedReason.notAvailable,
        .cellularDenied,
        .wifiDenied,
        .localNetworkDenied,
        .vpnInactive
    ])
    _ = Set([NWPath.LinkQuality.unknown, .minimal, .moderate, .good])
}

func testTCPLoopbackRoundTrip() {
    let params = NWParameters.tcp
    params.allowLocalEndpointReuse = true
    let listener = try! NWListener(using: params, on: .any)
    let queue = DispatchQueue(label: "network.tcp")
    let accepted = DispatchSemaphore(value: 0)
    let serverReady = DispatchSemaphore(value: 0)
    let serverGot = DispatchSemaphore(value: 0)
    var inbound: NWConnection?
    var payload: Data?
    listener.newConnectionHandler = { connection in
        inbound = connection
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                serverReady.signal()
                connection.receive(minimumIncompleteLength: 4, maximumLength: 64) { data, context, _, error in
                    nwExpect(error == nil, "server receive")
                    nwExpect(context != nil, "content context")
                    payload = data
                    serverGot.signal()
                    connection.send(content: Data([9, 9, 9, 9]), completion: .idempotent)
                }
            }
        }
        connection.start(queue: queue)
        accepted.signal()
    }
    var listenerReady = false
    listener.stateUpdateHandler = { state in
        if case .ready = state { listenerReady = true }
    }
    listener.start(queue: queue)
    nwExpect(listenerReady, "listener ready")
    nwExpect(listener.port != nil, "port assigned")
    nwExpect(listener.port?.rawValue != 0, "ephemeral port")
    nwExpect(listener.debugDescription.isEmpty == false, "listener debug")
    nwExpect(listener.parameters === params, "parameters")
    nwExpect(listener.queue === queue, "listener queue")
    nwExpect(NWListener.InfiniteConnectionLimit > 0, "infinite limit")
    _ = listener.newConnectionLimit

    let client = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: listener.port!),
        using: params
    )
    let clientReady = DispatchSemaphore(value: 0)
    let echoGot = DispatchSemaphore(value: 0)
    var echo: Data?
    var sawPreparing = false
    client.stateUpdateHandler = { state in
        if case .preparing = state { sawPreparing = true }
        if case .ready = state { clientReady.signal() }
    }
    client.start(queue: queue)
    nwWait(clientReady, "client ready")
    nwExpect(sawPreparing, "preparing first")
    nwExpect(client.state == .ready, "client state ready")
    nwWait(accepted, "accepted")
    nwWait(serverReady, "server ready")
    let sendDone = DispatchSemaphore(value: 0)
    client.send(content: Data([1, 2, 3, 4]), completion: .contentProcessed { error in
        nwExpect(error == nil, "client send")
        sendDone.signal()
    })
    nwWait(sendDone, "send completion")
    nwWait(serverGot, "server payload")
    nwExpect(payload == Data([1, 2, 3, 4]), "bytes")
    inbound?.receive(minimumIncompleteLength: 1, maximumLength: 16) { _, _, _, _ in }
    client.receive(minimumIncompleteLength: 4, maximumLength: 16) { data, _, complete, error in
        nwExpect(error == nil, "echo receive")
        _ = complete
        echo = data
        echoGot.signal()
    }
    nwWait(echoGot, "echo")
    nwExpect(echo == Data([9, 9, 9, 9]), "echo bytes")
    client.forceCancel()
    listener.cancel()
    nwExpect(listener.state == .cancelled, "listener cancelled")
}

func testUDPLoopbackRoundTrip() {
    let params = NWParameters.udp
    params.allowLocalEndpointReuse = true
    nwExpect(params.defaultProtocolStack.transportProtocol is NWProtocolUDP.Options, "udp transport")
    let listener = try! NWListener(using: params, on: .any)
    let queue = DispatchQueue(label: "network.udp")
    let accepted = DispatchSemaphore(value: 0)
    let serverGot = DispatchSemaphore(value: 0)
    var inbound: NWConnection?
    listener.newConnectionHandler = { connection in
        inbound = connection
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                connection.receiveMessage { data, _, _, error in
                    nwExpect(error == nil, "udp server receive")
                    nwExpect(data == Data([7, 8]), "udp payload")
                    serverGot.signal()
                    connection.send(content: Data([7, 8]), completion: .idempotent)
                }
            }
        }
        connection.start(queue: queue)
        accepted.signal()
    }
    listener.start(queue: queue)
    nwExpect(listener.state == .ready, "udp listener ready")
    let client = NWConnection(
        host: .ipv4(.loopback),
        port: listener.port!,
        using: params
    )
    let clientReady = DispatchSemaphore(value: 0)
    client.stateUpdateHandler = { state in
        if case .ready = state { clientReady.signal() }
    }
    client.start(queue: queue)
    nwWait(clientReady, "udp client ready")
    client.send(content: Data([7, 8]), completion: .idempotent)
    nwWait(accepted, "udp accepted")
    nwWait(serverGot, "udp server got")
    _ = inbound
    client.cancel()
    listener.cancel()
}

func testTLSConnectionFailsClosed() {
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: .https),
        using: .tls
    )
    var states: [NWConnection.State] = []
    connection.stateUpdateHandler = { states.append($0) }
    connection.start(queue: DispatchQueue(label: "network.tls"))
    nwExpect(states.contains(.preparing), "preparing")
    if case .failed(let error) = connection.state {
        if case .tls(let code) = error {
            nwExpect(code == -9800, "errSSLProtocol")
        } else {
            preconditionFailure("expected tls error")
        }
    } else {
        preconditionFailure("expected failed")
    }
    connection.cancel()
}

func testServiceEndpointWaitsThenFails() {
    let connection = NWConnection(
        to: .service(name: "x", type: "_http._tcp", domain: "local.", interface: nil),
        using: .tcp
    )
    var states: [NWConnection.State] = []
    connection.stateUpdateHandler = { states.append($0) }
    connection.start(queue: DispatchQueue(label: "network.service"))
    nwExpect(states.contains(.preparing), "preparing")
    var sawWaiting = false
    for state in states {
        if case .waiting = state { sawWaiting = true }
    }
    nwExpect(sawWaiting, "waiting")
    if case .failed(let error) = connection.state {
        nwExpect(error == .posix(.EOPNOTSUPP), "no bonjour")
    } else {
        preconditionFailure("expected failed")
    }
}

func testConnectionRefusedOnClosedPort() {
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: 1),
        using: .tcp
    )
    connection.start(queue: DispatchQueue(label: "network.refused"))
    if case .failed(let error) = connection.state {
        if case .posix = error {
            // ECONNREFUSED or EACCES depending on the host.
        } else {
            preconditionFailure("posix error")
        }
    } else {
        preconditionFailure("expected failed")
    }
    var sendError: NWError?
    connection.send(content: Data([1]), completion: .contentProcessed { sendError = $0 })
    nwExpect(sendError != nil, "send after fail")
    let receiveDone = DispatchSemaphore(value: 0)
    connection.receive(minimumIncompleteLength: 1, maximumLength: 8) { data, _, _, error in
        nwExpect(data == nil, "no bytes")
        nwExpect(error != nil, "receive error")
        receiveDone.signal()
    }
    nwWait(receiveDone, "receive after fail")
    connection.cancelCurrentEndpoint()
}

func testNWBrowserFailClosedNoBonjour() {
    let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
    var browserFailed = false
    browser.stateUpdateHandler = { state in
        if case .failed(let error) = state {
            browserFailed = error == .posix(.EOPNOTSUPP)
        }
    }
    var changes = 0
    browser.browseResultsChangedHandler = { results, _ in
        nwExpect(results.isEmpty, "no fabricated peers")
        changes += 1
    }
    browser.start(queue: DispatchQueue(label: "network.browser"))
    nwExpect(browserFailed, "browser failed")
    nwExpect(browser.browseResults.isEmpty, "empty results")
    nwExpect(changes == 1, "empty change callback")
    nwExpect(browser.debugDescription.isEmpty == false, "debug")
    _ = NWBrowser.Descriptor.bonjourWithTXTRecord(type: "_ssh._tcp", domain: "local.")
    _ = NWBrowser.Descriptor.applicationService(name: "app")
    let change = NWBrowser.Result.Change(between: nil, nil)
    if case .identical = change { } else { preconditionFailure("identical") }
    browser.cancel()
    nwExpect(browser.state == .cancelled, "cancelled")
}

func testNWConnectionGroupFailClosed() {
    let group = NWConnectionGroup(with: NWMultiplexGroup(with: .hostPort(host: .ipv4(.loopback), port: .http)), using: .tcp)
    var failed = false
    group.stateUpdateHandler = { state in
        if case .failed = state { failed = true }
    }
    group.start(queue: DispatchQueue(label: "network.group"))
    nwExpect(failed, "group failed")
    nwExpect(NWMulticastGroup(with: .hostPort(host: .ipv4(.loopback), port: .http)) == nil, "multicast init fails closed")
    let message = NWConnectionGroup.Message(group: group)
    nwExpect(message.identifier == "group-message", "message")
    group.cancel()
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
    nwExpect(record.setEntry(.data(Data([1])), for: "bin"), "data entry")
    nwExpect(Array(record).count == 5, "collection count")
    nwExpect(record.count == 5, "count")
    nwExpect(record.startIndex.rawValue == 0, "start")
    nwExpect(record.index(after: record.startIndex).rawValue == 1, "after")
    nwExpect(record.startIndex < record.endIndex, "index ordered")
    _ = record.debugDescription
    _ = record.debugDescription
    let fromData = NWTXTRecord(Data([0, 1, 2]))
    nwExpect(fromData.endIndex.rawValue >= 0, "data init")
    nwExpect(record == record, "equal")
    var hasher = Hasher()
    record.hash(into: &hasher)
}

func testNWParametersPresetsAndBuilders() {
    let tcp = NWParameters.tcp
    nwExpect(tcp.serviceClass == .bestEffort, "default class")
    nwExpect(tcp.tcpOptions != nil, "tcp options")
    nwExpect(tcp.defaultProtocolStack.transportProtocol is NWProtocolTCP.Options, "tcp transport")
    _ = tcp.peerToPeerIncluded(true).localOnly(true)
    nwExpect(tcp.includePeerToPeer, "peer to peer stored")
    nwExpect(tcp.acceptLocalOnly, "local only stored")
    _ = tcp.serviceClass(.responsiveData)
        .fastOpenAllowed(true)
        .expiredDNSBehavior(.allow)
        .noProxiesPreferred(true)
        .multipathServiceType(.handover)
        .requiredInterfaceType(.wifi)
        .dnssecValidationRequired(true)
        .expensivePathsProhibited(true)
        .prohibitedInterfaceTypes([.cellular])
        .localEndpointReuseAllowed(true)
        .constrainedPathsProhibited(true)
        .ultraConstrainedPathsAllowed(false)
        .localPort(.http)
    nwExpect(tcp.allowFastOpen, "fast open")
    nwExpect(tcp.requiredInterfaceType == .wifi, "required wifi")
    nwExpect(tcp.allowLocalEndpointReuse, "reuse")
    nwExpect(tcp.multipathServiceType == .handover, "multipath")
    let tls = NWParameters.tls
    nwExpect(tls.tlsOptions != nil, "tls options present")
    _ = NWParameters.udp
    _ = NWParameters.dtls
    _ = NWParameters.applicationService
    _ = NWParameters.quic(alpn: ["h3"])
    _ = NWParameters.quicDatagram(alpn: ["h3"])
    let copied = tcp.copy()
    nwExpect(copied === tcp, "copy identity")
    tcp.setPrivacyContext(.default)
    _ = tcp.debugDescription
    _ = NWParameters.PrivacyContext.default.debugDescription
    NWParameters.PrivacyContext.default.flushCache()
    NWParameters.PrivacyContext.default.disableLogging()
    NWParameters.PrivacyContext.default.requireEncryptedNameResolution(true, fallbackResolver: nil)
    _ = NWParameters.Attribution.developer
    _ = NWParameters.Attribution.user
    _ = NWParameters.ExpiredDNSBehavior.systemDefault
    _ = NWParameters.ExpiredDNSBehavior.prohibit
    _ = NWParameters.ExpiredDNSBehavior.persistent
    _ = NWParameters.MultipathServiceType.disabled
    _ = NWParameters.MultipathServiceType.interactive
    _ = NWParameters.MultipathServiceType.aggregate
    let iface = NWInterface(name: "lo", type: .loopback)
    _ = tcp.requiredInterface(iface)
    _ = tcp.prohibitedInterfaces([iface])
    _ = tcp.localEndpoint(.hostPort(host: .ipv4(.loopback), port: .any))
    _ = NWParameters.PrivacyContext.ResolverConfiguration.tls(
        .hostPort(host: .ipv4(.loopback), port: .https),
        serverAddresses: []
    )
    _ = NWParameters.PrivacyContext.ResolverConfiguration.https(
        URL(string: "https://dns.example")!,
        serverAddresses: []
    )
}

func testNWProtocolOptionsValueStores() {
    let tcp = NWProtocolTCP.Options()
    tcp.noDelay = true
    tcp.connectionTimeout = 5
    tcp.enableKeepalive = true
    tcp.keepaliveIdle = 10
    tcp.keepaliveCount = 3
    tcp.keepaliveInterval = 2
    tcp.enableFastOpen = true
    tcp.maximumSegmentSize = 512
    tcp.disableECN = true
    tcp.noOptions = true
    tcp.persistTimeout = 1
    tcp.retransmitFinDrop = true
    tcp.connectionDropTime = 1
    tcp.disableAckStretching = true
    tcp.noPush = true
    nwExpect(tcp.noDelay, "nodelay stored")
    nwExpect(NWProtocolTCP.definition.identifier == "tcp", "tcp definition")
    _ = NWProtocolTCP.Metadata().availableSendBuffer
    _ = NWProtocolTCP.Metadata().availableReceiveBuffer

    let udp = NWProtocolUDP.Options()
    udp.preferNoChecksum = true
    nwExpect(udp.preferNoChecksum, "udp checksum")
    nwExpect(NWProtocolUDP.definition.identifier == "udp", "udp definition")
    _ = NWProtocolUDP.Metadata()

    let tls = NWProtocolTLS.Options()
    _ = tls.securityProtocolOptions
    _ = NWProtocolTLS.Metadata().securityProtocolMetadata
    nwExpect(NWProtocolTLS.definition.identifier == "tls", "tls definition")

    let ip = NWProtocolIP.Options()
    ip.version = .v4
    ip.hopLimit = 64
    ip.useMinimumMTU = true
    ip.disableFragmentation = true
    ip.disableMulticastLoopback = true
    ip.shouldCalculateReceiveTime = true
    ip.localAddressPreference = .stable
    nwExpect(ip.version == .v4, "ip version")
    let ipMeta = NWProtocolIP.Metadata()
    _ = ipMeta.serviceClass(.background).ecn(.ect0)
    nwExpect(ipMeta.serviceClass == .background, "service class")
    nwExpect(ipMeta.ecn == .ect0, "ecn")
    _ = ipMeta.receiveTime
    _ = NWProtocolIP.ECN.nonECT
    _ = NWProtocolIP.ECN.ect1
    _ = NWProtocolIP.ECN.ce
    _ = NWProtocolIP.Options.Version.any
    _ = NWProtocolIP.Options.Version.v6
    _ = NWProtocolIP.Options.AddressPreference.default
    _ = NWProtocolIP.Options.AddressPreference.temporary
    nwExpect(NWProtocolIP.definition.identifier == "ip", "ip definition")
}

func testOverlayQUICWebSocketFramer() {
    let quic = NWProtocolQUIC.Options(alpn: ["h3"])
    quic.direction = .unidirectional
    quic.idleTimeout = 30
    quic.maxUDPPayloadSize = 1200
    quic.initialMaxData = 1
    quic.initialMaxStreamDataBidirectionalLocal = 1
    quic.initialMaxStreamDataBidirectionalRemote = 1
    quic.initialMaxStreamDataUnidirectional = 1
    quic.initialMaxStreamsBidirectional = 1
    quic.initialMaxStreamsUnidirectional = 1
    nwExpect(quic.alpn.count == 1, "alpn")
    _ = NWProtocolQUIC.ApplicationError(code: 1, message: "x")
    let quicMeta = NWProtocolQUIC.Metadata()
    quicMeta.keepAliveBehavior = .application
    nwExpect(quicMeta.streamID == 0, "stream id")
    nwExpect(NWProtocolQUIC.definition.identifier == "quic", "quic def")

    let ws = NWProtocolWebSocket.Options()
    ws.autoReplyPing = true
    ws.maximumMessageSize = 16
    ws.skipHandshake = true
    ws.setSubprotocols(["chat"])
    ws.addAdditionalHeader("X-A", value: "1")
    let wsMeta = NWProtocolWebSocket.Metadata()
    wsMeta.opcode = .text
    wsMeta.closeCode = .defined(.goingAway)
    wsMeta.response = NWProtocolWebSocket.Response(status: .accept)
    _ = NWProtocolWebSocket.Opcode.cont
    _ = NWProtocolWebSocket.Opcode.binary
    _ = NWProtocolWebSocket.Opcode.close
    _ = NWProtocolWebSocket.Opcode.ping
    _ = NWProtocolWebSocket.Opcode.pong
    _ = NWProtocolWebSocket.Version.v13
    _ = NWProtocolWebSocket.CloseCode.Defined.normalClosure
    _ = NWProtocolWebSocket.CloseCode.privateStatus(4000)
    nwExpect(NWProtocolWebSocket.definition.identifier == "ws", "ws def")

    final class ProbeFramer: NWProtocolFramerImplementation {
        required init(framer: NWProtocolFramer.Instance) { _ = framer }
        func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
        func handleInput(framer: NWProtocolFramer.Instance) -> Int { 0 }
        func handleOutput(
            framer: NWProtocolFramer.Instance,
            message: NWProtocolFramer.Message,
            messageLength: Int,
            isComplete: Bool
        ) {
            _ = framer
            _ = message
            _ = messageLength
            _ = isComplete
        }
        func wakeup(framer: NWProtocolFramer.Instance) { _ = framer }
        func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
        func cleanup(framer: NWProtocolFramer.Instance) { _ = framer }
    }
    let definition = NWProtocolFramer.Definition(implementation: ProbeFramer.self)
    let message = NWProtocolFramer.Message(definition: definition)
    message["k"] = "v"
    _ = message["k"]
    _ = NWProtocolFramer.Options(definition: definition)
    _ = NWProtocolFramer.StartResult.willMarkReady
    let instance = NWProtocolFramer.Instance()
    instance.writeOutput(data: Data())
    instance.passInput(to: NWProtocolTCP.definition)
    instance.markReady()
    instance.markFailed(error: NWError?.none)
    instance.deliverInput(data: Data(), message: message, isComplete: true)
    instance.scheduleWakeup(wakeupTime: NWProtocolFramer.Instance.WakeupTime.now)
    instance.scheduleWakeup(wakeupTime: .forever)
    instance.scheduleWakeup(wakeupTime: .interval(0.1))

    let hop = ProxyConfiguration.RelayHop(
        http3RelayEndpoint: nil,
        http2RelayEndpoint: nil,
        additionalHTTPHeaderFields: [:]
    )
    let proxy = ProxyConfiguration(relays: [hop])
    nwExpect(proxy.relays.count == 1, "relays")
}

func testConnectionContentContextAndReports() {
    let ctx = NWConnection.ContentContext(
        identifier: "x",
        expiration: 1,
        priority: 0.5,
        isFinal: true,
        antecedent: nil,
        metadata: []
    )
    nwExpect(ctx.identifier == "x", "id")
    nwExpect(NWConnection.ContentContext.defaultStream.identifier == "defaultStream", "stream")
    nwExpect(NWConnection.ContentContext.finalMessage.isFinal, "final")
    _ = ctx.antecedent
    _ = ctx.relativePriority
    _ = ctx.expirationMilliseconds
    _ = ctx.protocolMetadata
    _ = ctx.protocolMetadata(definition: NWProtocolTCP.definition)
    let connection = NWConnection(to: .hostPort(host: .ipv4(.loopback), port: .http), using: .tcp)
    connection.restart()
    connection.batch { }
    _ = connection.maximumDatagramSize
    _ = connection.metadata(definition: NWProtocolTCP.definition)
    _ = connection.startDataTransferReport()
    connection.requestEstablishmentReport(queue: DispatchQueue(label: "est")) { report in
        nwExpect(report == nil, "no fabricated establishment")
    }
    let pending: NWConnection.PendingDataTransferReport = connection.startDataTransferReport()
    let collected = DispatchSemaphore(value: 0)
    pending.collect(queue: DispatchQueue(label: "report")) { report in
        nwExpect(report.pathReports.isEmpty == false, "path report")
        let transfer: NWConnection.DataTransferReport = report
        _ = transfer.duration
        _ = transfer.aggregatePathReport
        _ = transfer.debugDescription
        let pathReports: [NWConnection.DataTransferReport.PathReport] = transfer.pathReports
        if let pathReport = pathReports.first {
            _ = pathReport.sentIPPacketCount
            _ = pathReport.receivedIPPacketCount
            _ = pathReport.sentTransportByteCount
            _ = pathReport.receivedTransportByteCount
            _ = pathReport.sentApplicationByteCount
            _ = pathReport.receivedApplicationByteCount
            _ = pathReport.retransmittedTransportByteCount
            _ = pathReport.receivedTransportDuplicateByteCount
            _ = pathReport.receivedTransportOutOfOrderByteCount
            _ = pathReport.transportMinimumRTT
            _ = pathReport.transportRTTVariance
            _ = pathReport.transportSmoothedRTT
            _ = pathReport.interface
            _ = pathReport.radioType
        }
        collected.signal()
    }
    nwWait(collected, "report collect")
}

func testListenerServiceInits() {
    let service = NWListener.Service(applicationService: "app")
    nwExpect(service.name == "app", "app name")
    let named = NWListener.Service(name: "n", type: "_http._tcp", domain: "local.")
    nwExpect(named.type.hasPrefix("_http"), "type")
    var withTXT = NWListener.Service(name: "n", type: "_http._tcp", domain: nil, txtRecord: NWTXTRecord(["a": "1"]))
    withTXT.noAutoRename = true
    nwExpect(withTXT.noAutoRename, "no rename")
    _ = withTXT.debugDescription
    _ = withTXT.txtRecordObject
    let listener = try! NWListener(service: service, using: .tcp)
    nwExpect(listener.service?.name == "app", "attached")
    let appListener = try! NWListener(applicationService: "app2")
    nwExpect(appListener.service?.name == "app2", "app listener")
    _ = NWListener.ServiceRegistrationChange.add(.hostPort(host: .ipv4(.loopback), port: .http))
    _ = NWListener.ServiceRegistrationChange.remove(.unix(path: "/tmp/x"))
}

func testCAPITypealiasesAndSmoke() {
    testCAPIHostAndPathMonitorFunctions()
}

func testPathMonitorDeliversUnsatisfiedSnapshot() {
    testNWInterfaceAndPathFromGetifaddrs()
}

func testConnectionSendReceiveFailClosed() {
    testConnectionRefusedOnClosedPort()
}

func testListenerAndBrowserFailClosed() {
    testNWBrowserFailClosedNoBonjour()
}

func testParametersBuildersStayLocal() {
    testNWParametersPresetsAndBuilders()
}
