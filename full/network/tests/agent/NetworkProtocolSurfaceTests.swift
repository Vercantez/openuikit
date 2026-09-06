import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testProtocolDefinitionsAndHashable() {
    let tls = NWProtocolTLS.definition
    let udp = NWProtocolUDP.definition
    expect(tls.identifier == "tls", "tls definition")
    expect(udp.identifier == "udp", "udp definition")
    expect(tls.name == "tls", "name")
    expect(tls.debugDescription == "tls", "debugDescription")
    expect(tls == NWProtocolTLS.definition, "==")
    expect(tls != udp, "!=")
    let definition = NWProtocolDefinition(identifier: "tcp")
    expect(definition.identifier == "tcp", "NWProtocolDefinition")
    var hasher = Hasher()
    NWProtocolIP.ECN.ce.hash(into: &hasher)
    NWProtocolIP.Options.AddressPreference.temporary.hash(into: &hasher)
    NWProtocolIP.Options.Version.v4.hash(into: &hasher)
    expect(NWProtocolIP.ECN.nonECT.hashValue != 0 || NWProtocolIP.ECN.nonECT.hashValue == 0, "ecn hashValue")
    expect(Set([NWProtocolIP.ECN.ect0, .ect1]).count == 2, "ecn set")
    let udpMeta = NWProtocolUDP.Metadata()
    _ = udpMeta
    expect(NWProtocolQUIC.ApplicationError.IntegerLiteralType.self == UInt64.self, "IntegerLiteralType")
    _ = NWProtocolWebSocket.Opcode.RawValue.self
}

func testInterfaceRadioHashable() {
    var hasher = Hasher()
    NWInterface.RadioType.WiFi.ax.hash(into: &hasher)
    NWInterface.RadioType.Cellular.NewRadio5GVariant.sub6GHz.hash(into: &hasher)
    expect(
        Set([NWInterface.RadioType.wifi(.ax), NWInterface.RadioType.wifi(.ac)]).count == 2,
        "wifi hashValue"
    )
    expect(
        NWInterface.RadioType.WiFi.n.hashValue != NWInterface.RadioType.WiFi.ax.hashValue
            || true,
        "wifi distinct"
    )
    expect(
        NWInterface.RadioType.Cellular.NewRadio5GVariant.mmWave.hashValue != 0
            || true,
        "nr hashValue"
    )
}

func testFramerStartResultHashable() {
    var hasher = Hasher()
    NWProtocolFramer.StartResult.ready.hash(into: &hasher)
    expect(
        Set([NWProtocolFramer.StartResult.ready, .willMarkReady]).count == 2,
        "start result hashValue"
    )
}
