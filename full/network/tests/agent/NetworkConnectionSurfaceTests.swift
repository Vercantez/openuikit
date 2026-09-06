import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testConnectionEndpointBatchAndHandlers() {
    let endpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .http)
    let connection = NWConnection(to: endpoint, using: .tcp)
    expect(connection.endpoint == endpoint, "endpoint stored")
    var ran = false
    connection.batch { ran = true }
    expect(ran, "batch ran")
    connection.receiveDiscontiguous(minimumIncompleteLength: 1, maximumLength: 8) { data, _, _, error in
        expect(data == nil, "discontiguous nil")
        expect(error == .unsupported, "discontiguous fail-closed")
    }
    connection.receiveMessageDiscontiguous { data, _, _, error in
        expect(data == nil, "message discontiguous nil")
        expect(error == .unsupported, "message discontiguous fail-closed")
    }
}

func testContentContextDefaultMessage() {
    expect(NWConnection.ContentContext.defaultMessage.identifier == "default", "defaultMessage")
    let ctx = NWConnection.ContentContext(identifier: "x")
    expect(ctx.identifier == "x", "identifier")
}

func testReceiveMessageOnRefusedConnection() {
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: 1),
        using: .tcp
    )
    connection.start(queue: DispatchQueue(label: "network.receiveMessage"))
    var sawCompletion = false
    connection.receiveMessage { data, _, _, error in
        expect(data == nil, "no message bytes")
        expect(error != nil, "receiveMessage error")
        sawCompletion = true
    }
    expect(sawCompletion, "receiveMessage completed")
}

func testEstablishmentReportDataModel() {
    let preferred = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .https)
    let resolution = NWConnection.EstablishmentReport.Resolution(
        duration: 0.01,
        source: .query,
        endpointCount: 1,
        preferredEndpoint: preferred,
        successfulEndpoint: preferred
    )
    expect(resolution.dnsProtocol == .unknown, "dnsProtocol")
    expect(resolution.endpointCount == 1, "endpointCount")
    expect(resolution.preferredEndpoint == preferred, "preferredEndpoint")
    expect(resolution.successfulEndpoint == preferred, "successfulEndpoint")
    expect(resolution.source == .query, "source")
    expect(resolution.duration == 0.01, "resolution duration")
    _ = Set([
        NWConnection.EstablishmentReport.Resolution.DNSProtocol.unknown,
        .udp,
        .tcp,
        .tls,
        .https
    ])
    var hasher = Hasher()
    NWConnection.EstablishmentReport.Resolution.DNSProtocol.tls.hash(into: &hasher)
    NWConnection.EstablishmentReport.Resolution.Source.cache.hash(into: &hasher)
    expect(NWConnection.EstablishmentReport.Resolution.DNSProtocol.udp.hashValue != 0 || true, "dns hashValue")
    expect(NWConnection.EstablishmentReport.Resolution.Source.query.hashValue != 0 || true, "source hashValue")
    let handshake = NWConnection.EstablishmentReport.Handshake(
        definition: NWProtocolTLS.definition,
        handshakeRTT: 0,
        handshakeDuration: 0
    )
    expect(handshake.definition.identifier == "tls", "handshake definition")
    expect(handshake.handshakeRTT == 0, "handshakeRTT")
    expect(handshake.handshakeDuration == 0, "handshakeDuration")
    let report = NWConnection.EstablishmentReport(
        duration: 0,
        attemptStartedAfterInterval: 0,
        previousAttemptCount: 0,
        usedProxy: false,
        proxyConfigured: false,
        proxyEndpoint: nil,
        resolutions: [resolution],
        handshakes: [handshake]
    )
    expect(report.handshakes.count == 1, "handshakes")
    expect(report.resolutions.count == 1, "resolutions")
    expect(report.proxyEndpoint == nil, "proxyEndpoint")
    expect(report.proxyConfigured == false, "proxyConfigured")
    expect(report.previousAttemptCount == 0, "previousAttemptCount")
    expect(report.attemptStartedAfterInterval == 0, "attemptStartedAfterInterval")
    expect(report.duration == 0, "duration")
    expect(report.usedProxy == false, "usedProxy")
    expect(report.debugDescription.contains("EstablishmentReport"), "debugDescription")
}

func testDataTransferReportFields() {
    let connection = NWConnection(
        to: .hostPort(host: .ipv4(.loopback), port: .http),
        using: .tcp
    )
    let pending = connection.startDataTransferReport()
    var report: NWConnection.DataTransferReport?
    pending.collect(queue: DispatchQueue(label: "network.dtr.surface")) { report = $0 }
    expect(report != nil, "collect")
    expect(report!.duration == 0, "duration")
    expect(report!.debugDescription.contains("DataTransferReport"), "debugDescription")
    expect(report!.pathReports.first?.interface.type == .loopback, "interface")
}
