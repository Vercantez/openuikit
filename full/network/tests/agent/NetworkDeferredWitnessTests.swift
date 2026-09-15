import Foundation
import Network

/// Focused synchronous witnesses for deferred Network-graph rows whose
/// declarations already exist in this Linux starting point:
/// `Hashable.hashValue` witnesses, typed-overlay associated-type aliases,
/// protocol-hierarchy conformance, handler typealiases, channel ID /
/// TLV `sendIdempotent`, coder witnesses, `NWTXTRecord.SubSequence`,
/// and `Bonjour.Endpoint.ID`. No Apple service, TLS/QUIC handshake,
/// mDNS, or async behavior is exercised here.

func testNetworkHashValueWitnesses() {
    func checkConsistent<H: Hashable>(_ value: H, _ message: String) {
        precondition(value.hashValue == value.hashValue, message)
        var hasher = Hasher()
        hasher.combine(value)
        _ = hasher.finalize()
    }
    checkConsistent(NWInterface.RadioType.WiFi.ac, "wifi hashValue")
    checkConsistent(
        NWInterface.RadioType.Cellular.NewRadio5GVariant.sub6GHz,
        "5g variant hashValue"
    )
    checkConsistent(
        NWConnection.EstablishmentReport.Resolution.DNSProtocol.tls,
        "dns protocol hashValue"
    )
    checkConsistent(
        NWConnection.EstablishmentReport.Resolution.Source.cache,
        "resolution source hashValue"
    )
    checkConsistent(NWParameters.Attribution.user, "attribution hashValue")
    checkConsistent(NWParameters.ServiceClass.signaling, "service class hashValue")
    checkConsistent(
        NWParameters.ExpiredDNSBehavior.prohibit,
        "expired dns hashValue"
    )
    checkConsistent(
        NWParameters.MultipathServiceType.aggregate,
        "multipath hashValue"
    )
    checkConsistent(NWProtocolIP.ECN.ce, "ecn hashValue")
    checkConsistent(
        NWProtocolIP.Options.AddressPreference.stable,
        "address preference hashValue"
    )
    checkConsistent(NWProtocolIP.Options.Version.v6, "ip version hashValue")
    checkConsistent(
        NWProtocolFramer.StartResult.willMarkReady,
        "start result hashValue"
    )
    precondition(
        NWParameters.ServiceClass.bestEffort.hashValue
            == NWParameters.ServiceClass.bestEffort.hashValue,
        "service class stable"
    )
}

func testTypedProtocolAssociatedTypes() {
    let tcpBelow: TCP.BelowProtocol = IP()
    precondition(
        tcpBelow.parameters.defaultProtocolStack.internetProtocol
            is NWProtocolIP.Options,
        "tcp below is ip"
    )
    let tcpStorage: TCP.ProtocolStorage = DefaultProtocolStorage()
    _ = tcpStorage
    let udpBelow: UDP.BelowProtocol = IP()
    _ = udpBelow.parameters
    let udpStorage: UDP.ProtocolStorage = DefaultProtocolStorage()
    _ = udpStorage
    let udpContent: UDP.ContentType = Data([1, 2])
    precondition(udpContent.count == 2, "udp content")
    let udpLegacy: UDP.LegacyMessage = (content: Data([3]), metadata: nil)
    precondition(udpLegacy.content == Data([3]), "udp legacy")
    let tlsBelow: TLS.BelowProtocol = TCP()
    _ = tlsBelow.parameters
    let tlsStorage: TLS.ProtocolStorage = DefaultProtocolStorage()
    _ = tlsStorage
    let ipBelow: IP.BelowProtocol = ()
    _ = ipBelow
    let ipStorage: IP.ProtocolStorage = DefaultProtocolStorage()
    _ = ipStorage
    let quicBelow: QUIC.BelowProtocol = UDP()
    _ = quicBelow.parameters
    let streamBelow: QUICStream.BelowProtocol = ()
    _ = streamBelow
    let streamStorage: QUICStream.ProtocolStorage = DefaultProtocolStorage()
    _ = streamStorage
    let datagramBelow: QUICDatagram.BelowProtocol = ()
    _ = datagramBelow
    let datagramStorage: QUICDatagram.ProtocolStorage = DefaultProtocolStorage()
    _ = datagramStorage
    let datagramContent: QUICDatagram.ContentType = Data([4])
    precondition(datagramContent == Data([4]), "quic datagram content")
    let datagramLegacy: QUICDatagram.LegacyMessage = (
        content: Data([5]), metadata: nil
    )
    precondition(datagramLegacy.content == Data([5]), "quic datagram legacy")
    let wsBelow: WebSocket.BelowProtocol = TCP()
    _ = wsBelow
    let wsStorage: WebSocket.ProtocolStorage = DefaultProtocolStorage()
    _ = wsStorage
    let wsContent: WebSocket.ContentType = Data([6])
    precondition(wsContent == Data([6]), "websocket content")
    let wsLegacy: WebSocket.LegacyMessage = (
        type: .binary, content: Data([7]), metadata: nil, isFinal: true
    )
    precondition(wsLegacy.type == .binary && wsLegacy.isFinal, "websocket legacy")
    let coderContent: Coder<String, String, NetworkJSONCoder>.ContentType = "hi"
    precondition(coderContent == "hi", "coder content")
    let coderBelow: Coder<String, String, NetworkJSONCoder>.BelowProtocol = TCP()
    _ = coderBelow
    let coderStorage: Coder<String, String, NetworkJSONCoder>.ProtocolStorage =
        DefaultProtocolStorage()
    _ = coderStorage
    let coderLegacy: Coder<String, String, NetworkJSONCoder>.LegacyMessage = (
        content: "hi", metadata: nil, isFinal: true
    )
    precondition(coderLegacy.content == "hi", "coder legacy")
    let framerContent: Framer<LengthPrefixedHostFramer>.ContentType = Data([8])
    precondition(framerContent == Data([8]), "framer content")
    let framerBelow: Framer<LengthPrefixedHostFramer>.BelowProtocol = TCP()
    _ = framerBelow
    let framerStorage: Framer<LengthPrefixedHostFramer>.ProtocolStorage =
        DefaultProtocolStorage()
    _ = framerStorage
    let framerLegacy: Framer<LengthPrefixedHostFramer>.LegacyMessage? = nil
    _ = framerLegacy
}

func testTypedProtocolHierarchy() {
    let oneToOne: any OneToOneProtocol = TCP()
    _ = oneToOne.parameters
    let stream: any StreamProtocol = TCP()
    precondition(
        stream.parameters.defaultProtocolStack.transportProtocol
            is NWProtocolTCP.Options,
        "stream parameters"
    )
    let message: any MessageProtocol = UDP()
    _ = message.parameters
    let datagram: any DatagramProtocol = UDP()
    _ = datagram.parameters
    let multiplex: any MultiplexProtocol = QUIC(alpn: [])
    _ = multiplex.parameters
    let connectable: any Connectable = NWEndpoint.unix(path: "/tmp/x")
    _ = connectable
}

func testNetworkChannelIDAndTLVSend() {
    let inner = NWConnection(host: "127.0.0.1", port: 1, using: .udp)
    let channel = NetworkChannel<TLV>(inner: inner)
    let identifier: NetworkChannel<TLV>.ID = channel.id
    precondition(!identifier.isEmpty, "channel id")
    channel.sendIdempotent(Data([9]), type: 3, lastMessage: true, metadata: { })
    channel.sendIdempotent(Data([10]), type: 4)
    inner.cancel()
}

func testNetworkListenerBrowserHandlerAliases() {
    let listenerHandler: NetworkListener<TCP>.StateUpdateHandler = { _, _ in }
    _ = listenerHandler
    let registrationHandler: NetworkListener<TCP>.ServiceRegistrationUpdateHandler = {
        _, _ in
    }
    _ = registrationHandler
    let browserHandler: NetworkBrowser<Bonjour>.StateUpdateHandler = { _, _ in }
    _ = browserHandler
}

func testNetworkFixedWidthIntegerOverlay() {
    func overlayBigEndian<T: NetworkFixedWidthInteger>(_ value: T) -> T {
        value.bigEndian
    }
    precondition(overlayBigEndian(UInt8(1)) == UInt8(1), "overlay bigEndian")
    func takesOverlayInteger<T: NetworkFixedWidthInteger>(_ type: T.Type) -> Int {
        T.bitWidth
    }
    precondition(takesOverlayInteger(UInt8.self) == 8, "overlay integer")
}

func testNetworkCoderWitnesses() {
    let jsonDecoder: NetworkJSONCoder.Decoder = JSONDecoder()
    let jsonEncoder: NetworkJSONCoder.Encoder = JSONEncoder()
    let plistDecoder: NetworkPropertyListCoder.Decoder = PropertyListDecoder()
    let plistEncoder: NetworkPropertyListCoder.Encoder = PropertyListEncoder()
    _ = plistDecoder
    _ = plistEncoder
    let coder = NetworkJSONCoder()
    guard let encoded = try? coder.makeEncoder().encode("hello") else {
        preconditionFailure("json encode")
    }
    guard
        let decoded = try? coder.makeDecoder().decode(String.self, from: encoded),
        decoded == "hello"
    else {
        preconditionFailure("json decode")
    }
    let existentialEncoder: any NetworkEncoder = jsonEncoder
    guard let existentialData = try? existentialEncoder.encode("hi") else {
        preconditionFailure("existential encode")
    }
    let existentialDecoder: any NetworkDecoder = jsonDecoder
    guard
        let back = try? existentialDecoder.decode(String.self, from: existentialData),
        back == "hi"
    else {
        preconditionFailure("existential decode")
    }
}

func testNWTXTRecordSubSequenceAndBonjourID() {
    let record = NWTXTRecord(["a": "1", "b": "hello"])
    let head: NWTXTRecord.SubSequence = record.prefix(1)
    precondition(head.count == 1, "txt subsequence")
    precondition(head[head.startIndex].key == "a", "txt subsequence key")
    let bonjourID: Bonjour.Endpoint.ID = "example._http._tcp.local"
    precondition(!bonjourID.isEmpty, "bonjour id")
}

/// `NWBrowser.Result.Change.Flags` is a real `OptionSet` in this starting
/// point. This batch exercises every stdlib `Equatable` / `Hashable` /
/// `SetAlgebra` / `OptionSet` witness the Network graph attributes to it.
/// All synchronous and in-process; no browse daemon runs here.
func testBrowserFlagsSetAlgebraWitnesses() {
    typealias Flags = NWBrowser.Result.Change.Flags
    let added: Flags = [.interfaceAdded, .metadataChanged]
    let removed: Flags = [.interfaceRemoved]
    precondition((added != removed) && !(added != added), "flags !=")
    precondition(added.hashValue == added.hashValue, "flags hashValue")
    var hasher = Hasher()
    added.hash(into: &hasher)
    _ = hasher.finalize()
    let empty = Flags()
    precondition(empty.isEmpty, "flags empty init")
    let literal: Flags = [.identical, .interfaceAdded]
    precondition(literal.contains(.identical), "array literal contains")
    let fromSequence = Flags([.identical, .metadataChanged])
    precondition(fromSequence.contains(.metadataChanged), "sequence init")
    precondition(added.isDisjoint(with: removed), "isDisjoint")
    precondition(added.isSuperset(of: [.interfaceAdded]), "isSuperset")
    precondition(added.isSubset(of: [.interfaceAdded, .metadataChanged, .identical]), "isSubset")
    precondition(added.isStrictSubset(of: [.interfaceAdded, .metadataChanged, .identical]), "strict subset")
    let superset: Flags = [.interfaceAdded, .metadataChanged, .identical]
    precondition(superset.isStrictSuperset(of: added), "strict superset")
    precondition((added.subtracting(.interfaceAdded) == [.metadataChanged]), "subtracting")
    precondition(
        added.intersection(.interfaceAdded) == [.interfaceAdded],
        "intersection"
    )
    precondition(
        added.symmetricDifference(removed).contains(.interfaceRemoved),
        "symmetricDifference"
    )
    precondition(added.union(removed).contains(.interfaceAdded), "union")
    var mutable = added
    let inserted = mutable.insert(.interfaceRemoved)
    precondition(inserted.inserted && mutable.contains(.interfaceRemoved), "insert")
    let taken = mutable.remove(.interfaceRemoved)
    precondition(taken == .interfaceRemoved && !mutable.contains(.interfaceRemoved), "remove")
    let previous = mutable.update(with: .identical)
    precondition(previous == nil && mutable.contains(.identical), "update")
    mutable.formIntersection(.interfaceAdded)
    precondition(mutable == [.interfaceAdded], "formIntersection")
    mutable.formSymmetricDifference([.interfaceAdded, .identical])
    precondition(mutable == [.identical], "formSymmetricDifference")
    mutable.formUnion(.metadataChanged)
    precondition(mutable.contains(.metadataChanged), "formUnion")
    var subtracted = added
    subtracted.subtract(.interfaceAdded)
    precondition(subtracted == [.metadataChanged], "subtract")
    let raw = Flags(rawValue: 0b1010)
    precondition(raw.rawValue == 0b1010, "rawValue init")
}

/// `NWEndpoint.Host` declares all three string-literal initializers locally.
/// Calling each one directly exercises the stdlib default witnesses the
/// graph attributes to `Host`.
func testNWEndpointHostLiteralWitnesses() {
    let fromString: NWEndpoint.Host = "example.com"
    let fromGrapheme = NWEndpoint.Host(extendedGraphemeClusterLiteral: "example.com")
    let fromScalar = NWEndpoint.Host(unicodeScalarLiteral: "example.com")
    precondition(fromString == fromGrapheme && fromGrapheme == fromScalar, "host literals agree")
}

/// Generic-context references to the `MessageProtocol` and `BrowserProvider`
/// associated types. Conformance itself is compiled in; these lines name the
/// exact associated-type identifiers from the graph.
func testTypedMessageAndBrowserAssociatedTypes() {
    func contentTypes<M: MessageProtocol>(_ type: M.Type) -> (M.ContentType.Type, M.LegacyMessage.Type) {
        (M.ContentType.self, M.LegacyMessage.self)
    }
    let (udpContent, udpLegacy) = contentTypes(UDP.self)
    _ = (udpContent, udpLegacy)
    func browserEndpoint<B: BrowserProvider>(_ type: B.Type) -> B.Endpoint.Type {
        B.Endpoint.self
    }
    let endpointType = browserEndpoint(Bonjour.self)
    precondition("\(endpointType)".contains("Endpoint"), "browser endpoint")
}

/// Both `certificateValidator` builders are synchronous local stores: they
/// take an (async-typed) closure value and return the protocol value without
/// performing any TLS handshake. Passing a non-async closure value is a
/// synchronous call; the closure never runs on Linux.
func testTLSCertificateValidatorBuilders() {
    let tls = TLS().certificateValidator { _, _ in true }
    _ = tls.parameters
    let quic = QUIC(alpn: []).tls.certificateValidator { _, _ in true }
    _ = quic.parameters
}

/// Group membership without a daemon: a multiplex group always reports the
/// single endpoint it wraps, reachable through the `NWGroupDescriptor`
/// requirement as well.
func testGroupDescriptorMembers() {
    let endpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: 443)
    let group = NWMultiplexGroup(with: endpoint)
    precondition(group.members == [endpoint], "multiplex members")
    let descriptor: any NWGroupDescriptor = group
    precondition(descriptor.members == [endpoint], "descriptor members")
}

/// WebSocket handler setters store the queue and handler locally. Linux
/// performs no handshake, so the handlers never fire; retention is the
/// whole behavior under test.
func testWebSocketHandlerSetters() {
    let options = NWProtocolWebSocket.Options()
    let queue = DispatchQueue(label: "websocket-probe")
    options.setClientRequestHandler(queue) { _, _ in
        NWProtocolWebSocket.Response(status: .accept)
    }
    precondition(options.clientRequestHandler != nil, "request handler stored")
    let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
    metadata.setPongHandler(queue) { _ in }
    precondition(metadata.pongHandler != nil, "pong handler stored")
}

/// `NWProtocolDefinition` equality is identifier-based; inequality is the
/// stdlib `Equatable.!=` default witness the graph attributes to it.
func testProtocolDefinitionInequality() {
    precondition(NWProtocolTCP.definition != NWProtocolUDP.definition, "definitions differ")
    precondition(!(NWProtocolTCP.definition != NWProtocolTCP.definition), "definitions equal")
}
