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
