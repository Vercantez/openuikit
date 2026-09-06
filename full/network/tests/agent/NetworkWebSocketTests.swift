import Foundation
import Network

private func wsExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testWebSocketOpcodeRawValues() {
    wsExpect(NWProtocolWebSocket.Opcode.cont.rawValue == 0, "cont")
    wsExpect(NWProtocolWebSocket.Opcode.text.rawValue == 1, "text")
    wsExpect(NWProtocolWebSocket.Opcode.binary.rawValue == 2, "binary")
    wsExpect(NWProtocolWebSocket.Opcode.close.rawValue == 8, "close")
    wsExpect(NWProtocolWebSocket.Opcode.ping.rawValue == 9, "ping")
    wsExpect(NWProtocolWebSocket.Opcode.pong.rawValue == 10, "pong")
    wsExpect(NWProtocolWebSocket.Opcode(rawValue: 1) == .text, "init text")
    wsExpect(NWProtocolWebSocket.Opcode(rawValue: 15) == nil, "reserved rejected")
    wsExpect(NWProtocolWebSocket.Opcode.text != .binary, "distinct")
    _ = NWProtocolWebSocket.Opcode.text.hashValue
}

func testWebSocketRFC6455UnmaskedHello() {
    // RFC 6455 §5.7: unmasked text "Hello"
    let expected = Data([0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f])
    let frame = NWProtocolWebSocket.Frame(
        opcode: .text,
        payload: Data("Hello".utf8)
    )
    wsExpect(frame.encode() == expected, "unmasked hello encode")
    let decoded = NWProtocolWebSocket.Frame.decode(expected)
    wsExpect(decoded?.fin == true, "fin")
    wsExpect(decoded?.opcode == .text, "opcode")
    wsExpect(decoded?.masked == false, "unmasked")
    wsExpect(decoded?.payload == Data("Hello".utf8), "payload")
}

func testWebSocketRFC6455MaskedHello() {
    // RFC 6455 §5.7: masked text "Hello" with key 0x37fa213d
    let expected = Data([
        0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58
    ])
    let frame = NWProtocolWebSocket.Frame(
        opcode: .text,
        payload: Data("Hello".utf8),
        masked: true,
        maskingKey: 0x37fa213d
    )
    wsExpect(frame.encode() == expected, "masked hello encode")
    let decoded = NWProtocolWebSocket.Frame.decode(expected)
    wsExpect(decoded?.masked == true, "masked")
    wsExpect(decoded?.maskingKey == 0x37fa213d, "key")
    wsExpect(decoded?.payload == Data("Hello".utf8), "unmasked payload")
}

func testWebSocketRFC6455Fragmentation() {
    // RFC 6455 §5.7: fragmented "Hello" as "Hel" + "lo"
    let first = Data([0x01, 0x03, 0x48, 0x65, 0x6c])
    let second = Data([0x80, 0x02, 0x6c, 0x6f])
    let encodedFirst = NWProtocolWebSocket.Frame(
        fin: false,
        opcode: .text,
        payload: Data("Hel".utf8)
    ).encode()
    let encodedSecond = NWProtocolWebSocket.Frame(
        fin: true,
        opcode: .cont,
        payload: Data("lo".utf8)
    ).encode()
    wsExpect(encodedFirst == first, "first fragment")
    wsExpect(encodedSecond == second, "second fragment")
    let decodedFirst = NWProtocolWebSocket.Frame.decode(first)
    let decodedSecond = NWProtocolWebSocket.Frame.decode(second)
    wsExpect(decodedFirst?.fin == false, "not fin")
    wsExpect(decodedFirst?.opcode == .text, "text start")
    wsExpect(decodedSecond?.fin == true, "fin")
    wsExpect(decodedSecond?.opcode == .cont, "continuation")
    var combined = Data()
    combined.append(decodedFirst!.payload)
    combined.append(decodedSecond!.payload)
    wsExpect(combined == Data("Hello".utf8), "reassembled")
}

func testWebSocketRFC6455PingPongAndClose() {
    let ping = Data([0x89, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f])
    wsExpect(
        NWProtocolWebSocket.Frame(opcode: .ping, payload: Data("Hello".utf8)).encode() == ping,
        "unmasked ping"
    )
    let pong = Data([
        0x8a, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58
    ])
    let encodedPong = NWProtocolWebSocket.Frame(
        opcode: .pong,
        payload: Data("Hello".utf8),
        masked: true,
        maskingKey: 0x37fa213d
    ).encode()
    wsExpect(encodedPong == pong, "masked pong")
    var closePayload = Data()
    closePayload.append(contentsOf: [
        UInt8(NWProtocolWebSocket.CloseCode.Defined.normalClosure.rawValue >> 8),
        UInt8(NWProtocolWebSocket.CloseCode.Defined.normalClosure.rawValue & 0xff)
    ])
    let close = NWProtocolWebSocket.Frame(opcode: .close, payload: closePayload)
    let decodedClose = NWProtocolWebSocket.Frame.decode(close.encode())
    wsExpect(decodedClose?.opcode == .close, "close opcode")
    wsExpect(decodedClose?.payload.count == 2, "close payload")
}

func testWebSocketExtendedPayloadLengths() {
    let body256 = Data(repeating: 0x61, count: 256)
    let encoded = NWProtocolWebSocket.Frame(opcode: .binary, payload: body256).encode()
    wsExpect(encoded[0] == 0x82, "binary fin")
    wsExpect(encoded[1] == 126, "16-bit length")
    wsExpect(encoded[2] == 0x01 && encoded[3] == 0x00, "256")
    wsExpect(NWProtocolWebSocket.Frame.decode(encoded)?.payload.count == 256, "round trip 256")
    let body64k = Data(repeating: 0x62, count: 65536)
    let encoded64 = NWProtocolWebSocket.Frame(opcode: .binary, payload: body64k).encode()
    wsExpect(encoded64[1] == 127, "64-bit length")
    wsExpect(Array(encoded64[2..<10]) == [0, 0, 0, 0, 0, 1, 0, 0], "65536 header")
    wsExpect(NWProtocolWebSocket.Frame.decode(encoded64)?.payload.count == 65536, "round trip 64k")
}

func testWebSocketCloseCodesAndOptions() {
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.normalClosure.rawValue == 1000, "1000")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.goingAway.rawValue == 1001, "1001")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.protocolError.rawValue == 1002, "1002")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.unsupportedData.rawValue == 1003, "1003")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.noStatusReceived.rawValue == 1005, "1005")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.abnormalClosure.rawValue == 1006, "1006")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.invalidFramePayloadData.rawValue == 1007, "1007")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.policyViolation.rawValue == 1008, "1008")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.messageTooBig.rawValue == 1009, "1009")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.mandatoryExtension.rawValue == 1010, "1010")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.internalServerError.rawValue == 1011, "1011")
    wsExpect(NWProtocolWebSocket.CloseCode.Defined.tlsHandshake.rawValue == 1015, "1015")
    let protocolCode = NWProtocolWebSocket.CloseCode.protocolCode(.goingAway)
    wsExpect(protocolCode.rawValue == 1001, "protocol raw")
    wsExpect(NWProtocolWebSocket.CloseCode.applicationCode(3000).rawValue == 3000, "app")
    wsExpect(NWProtocolWebSocket.CloseCode.privateCode(4000).rawValue == 4000, "private")
    let thrown = try? NWProtocolWebSocket.CloseCode(rawValue: 1000)
    wsExpect(thrown?.rawValue == 1000, "throwing init")
    do {
        _ = try NWProtocolWebSocket.CloseCode(rawValue: 2000)
        preconditionFailure("invalid close code must throw")
    } catch {
        wsExpect(error is NWError, "posix EINVAL")
    }
    let options = NWProtocolWebSocket.Options(.version13)
    wsExpect(options.version == .version13, "version13")
    wsExpect(NWProtocolWebSocket.Version.v13 == .version13, "v13 alias")
    wsExpect(NWProtocolWebSocket.Version.version13 == .version13, "eq")
    _ = NWProtocolWebSocket.Version.version13.hashValue
    var versionHasher = Hasher()
    NWProtocolWebSocket.Version.version13.hash(into: &versionHasher)
    options.autoReplyPing = true
    options.skipHandshake = true
    options.maximumMessageSize = 4096
    wsExpect(options.autoReplyPing, "auto ping")
    wsExpect(options.skipHandshake, "skip")
    wsExpect(options.maximumMessageSize == 4096, "max size")
    options.setAdditionalHeaders([("X-A", "1")])
    wsExpect(options.additionalHeaders.count == 1, "headers")
    options.setSubprotocols(["chat"])
    wsExpect(options.subprotocols == ["chat"], "subprotocols")
    let meta = NWProtocolWebSocket.Metadata(opcode: .text)
    wsExpect(meta.opcode == .text, "metadata opcode")
    meta.closeCode = .protocolCode(.goingAway)
    wsExpect(meta.closeCode == .protocolCode(.goingAway), "close stored")
    meta.selectedSubprotocol = "chat"
    wsExpect(meta.selectedSubprotocol == "chat", "selected")
    meta.additionalServerHeaders = [("X-B", "2")]
    wsExpect(meta.additionalServerHeaders?.count == 1, "server headers")
    let accept = NWProtocolWebSocket.Response(
        status: .accept,
        subprotocol: "chat",
        additionalHeaders: nil
    )
    wsExpect(accept.status == .accept, "accept")
    wsExpect(accept.subprotocol == "chat", "subprotocol")
    let response = NWProtocolWebSocket.Response(
        status: .reject,
        subprotocol: nil,
        additionalHeaders: [("X-C", "3")]
    )
    wsExpect(response.status == .reject, "reject")
    wsExpect(response.additionalHeaders?.count == 1, "response headers")
    wsExpect(NWProtocolWebSocket.Response.Status.accept != .reject, "status distinct")
    _ = NWProtocolWebSocket.Response.Status.reject.hashValue
    var statusHasher = Hasher()
    NWProtocolWebSocket.Response.Status.accept.hash(into: &statusHasher)
    wsExpect(NWProtocolWebSocket.definition.identifier == "ws", "definition")
    _ = NWProtocolWebSocket.CloseCode.Defined.RawValue.self
    wsExpect(NWProtocolWebSocket.CloseCode.Defined(rawValue: 1000) == .normalClosure, "raw init")
}
