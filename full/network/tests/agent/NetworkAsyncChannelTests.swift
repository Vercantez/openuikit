import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func loopbackDiscardEndpoint() -> NWEndpoint {
    .hostPort(host: .ipv4(.loopback), port: 9)
}

private func expectENOTCONN(_ error: Error, _ context: String) {
    if let nwError = error as? NWError {
        expect(nwError == .posix(.ENOTCONN), "\(context): expected ENOTCONN, got \(nwError)")
    } else {
        expect(false, "\(context): expected NWError, got \(error)")
    }
}

func testAsyncStreamChannelSendData() async {
    let channel = NetworkChannel<TCP>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: .tcp)
    )
    do {
        try await channel.send(Data([1, 2, 3]))
        try await channel.send(Data([4]), endOfStream: true)
    } catch {
        expect(false, "stream data send must not throw: \(error)")
    }
    expect(channel.state == .setup, "unstarted stream channel stays in setup")
}

func testAsyncStreamChannelSendInteger() async {
    let channel = NetworkChannel<TCP>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: .tcp)
    )
    do {
        try await channel.send(UInt8(42))
    } catch {
        expect(false, "stream integer send must not throw: \(error)")
    }
}

func testAsyncStreamChannelReceivesFailClosed() async {
    let channel = NetworkChannel<TCP>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: .tcp)
    )
    do {
        _ = try await channel.receive(as: UInt8.self)
        expect(false, "stream typed receive must throw")
    } catch {
        expectENOTCONN(error, "stream typed receive")
    }
    do {
        _ = try await channel.receive(atLeast: 1, atMost: 64)
        expect(false, "stream bounded receive must throw")
    } catch {
        expectENOTCONN(error, "stream bounded receive")
    }
    do {
        _ = try await channel.receive(exactly: 4)
        expect(false, "stream exact receive must throw")
    } catch {
        expectENOTCONN(error, "stream exact receive")
    }
}

func testAsyncDatagramChannelSendReceive() async {
    let channel = NetworkChannel<UDP>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: .udp)
    )
    do {
        try await channel.send(Data([9, 9]))
    } catch {
        expect(false, "datagram send must not throw: \(error)")
    }
    do {
        _ = try await channel.receive()
        expect(false, "datagram receive must throw")
    } catch {
        expectENOTCONN(error, "datagram receive")
    }
}

func testAsyncTLVChannelSendReceive() async {
    let channel = NetworkChannel<TLV>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: TLV { TCP() }.parameters)
    )
    do {
        try await channel.send(Data([1]), type: 7, lastMessage: true)
    } catch {
        expect(false, "TLV send must not throw: \(error)")
    }
    do {
        _ = try await channel.receive()
        expect(false, "TLV receive must throw")
    } catch {
        expectENOTCONN(error, "TLV receive")
    }
}

func testAsyncWebSocketChannelPingPong() async {
    let connection = NetworkConnection(to: loopbackDiscardEndpoint(), using: { WebSocket { TCP() } })
    do {
        try await connection.channel.ping(Data([1, 2]))
        try await connection.channel.pong(Data([3]))
    } catch {
        expect(false, "websocket ping/pong must not throw: \(error)")
    }
}

func testAsyncWebSocketChannelSendClose() async {
    let connection = NetworkConnection(to: loopbackDiscardEndpoint(), using: { WebSocket { TCP() } })
    do {
        try await connection.channel.send("hello")
        try await connection.channel.send(Data([0x82]))
        try await connection.channel.close()
    } catch {
        expect(false, "websocket send/close must not throw: \(error)")
    }
}

func testAsyncWebSocketChannelReceiveFailsClosed() async {
    let connection = NetworkConnection(to: loopbackDiscardEndpoint(), using: { WebSocket { TCP() } })
    do {
        _ = try await connection.channel.receive()
        expect(false, "websocket receive must throw")
    } catch {
        expectENOTCONN(error, "websocket receive")
    }
}

func testAsyncFramerChannelSendReceive() async {
    let framer = Framer<LengthPrefixedHostFramer> { TCP() }
    let channel = NetworkChannel<Framer<LengthPrefixedHostFramer>>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: framer.parameters)
    )
    let message = NWProtocolFramer.Message(definition: LengthPrefixedHostFramer.definition)
    do {
        try await channel.send(Data([1, 2]), lastMessage: true, metadata: message)
    } catch {
        expect(false, "framer send must not throw: \(error)")
    }
    do {
        _ = try await channel.receive()
        expect(false, "framer receive must throw")
    } catch {
        expectENOTCONN(error, "framer receive")
    }
}

func testAsyncCoderChannelSendReceive() async {
    let coder = Coder(sending: String.self, receiving: String.self, using: NetworkJSONCoder()) { TCP() }
    let channel = NetworkChannel<Coder<String, String, NetworkJSONCoder>>(
        inner: NWConnection(to: loopbackDiscardEndpoint(), using: coder.parameters)
    )
    do {
        try await channel.send("hello")
    } catch {
        expect(false, "coder send must not throw: \(error)")
    }
    do {
        _ = try await channel.receive()
        expect(false, "coder receive must throw")
    } catch {
        expectENOTCONN(error, "coder receive")
    }
}

func testAsyncPathMonitorIteratorNext() async {
    var iterator = NWPathMonitor().makeAsyncIterator()
    let first = await iterator.next()
    expect(first != nil, "path iterator yields the current path first")
    let second = await iterator.next()
    expect(second == nil, "path iterator ends after one path")
}
