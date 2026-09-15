import Foundation
import Matter

private final class Wave10ClientRecorder: NSObject, MTRDeviceControllerClientProtocol {
    var nodeIDs: [UInt64] = []
    var errorCount = 0
    func handleReport(withController controller: Any?, nodeId: UInt64, values: Any?, error: (any Error)?) {
        _ = (controller, values)
        nodeIDs.append(nodeId)
        if error != nil {
            errorCount += 1
        }
    }
}

func testWave10ControllerClientReport() {
    let stub = Wave10ClientRecorder()
    let client: any MTRDeviceControllerClientProtocol = stub
    client.handleReport(withController: nil, nodeId: 42, values: ["k": "v"], error: nil)
    mtrRequire(stub.nodeIDs == [42], "handleReport records node")
    mtrRequire(stub.errorCount == 0, "nil error stays nil")
}

private final class Wave10ServerRecorder: NSObject, MTRDeviceControllerServerProtocol {
    var downloads: [(NSNumber, MTRDiagnosticLogType)] = []
    var anyControllerCount = 0
    var fabricIDs: [UInt64] = []
    var invoked: [(UInt64, NSNumber, NSNumber, NSNumber)] = []
    var cacheReads: [UInt64] = []
    var reads: [UInt64] = []
    var stopped: [UInt64] = []
    var attributeSubscriptions: [UInt64] = []
    var subscriptions: [(UInt64, Bool)] = []
    var writes: [(UInt64, NSNumber)] = []
    func downloadLog(
        withController controller: Any?,
        nodeId: NSNumber,
        type: MTRDiagnosticLogType,
        timeout: TimeInterval,
        completion: @escaping (String?, (any Error)?) -> Void
    ) {
        _ = (controller, timeout, completion)
        downloads.append((nodeId, type))
    }
    func getAnyDeviceController(completion: @escaping (Any?, (any Error)?) -> Void) {
        _ = completion
        anyControllerCount += 1
    }
    func getDeviceController(withFabricId fabricId: UInt64, completion: @escaping (Any?, (any Error)?) -> Void) {
        _ = completion
        fabricIDs.append(fabricId)
    }
    func invokeCommand(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        commandId: NSNumber,
        fields: Any,
        timedInvokeTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, fields, timeoutMs, completion)
        invoked.append((nodeId, endpointId, clusterId, commandId))
    }
    func readAttributeCache(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, endpointId, clusterId, attributeId, completion)
        cacheReads.append(nodeId)
    }
    func readAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        params: [String: Any]?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, endpointId, clusterId, attributeId, params, completion)
        reads.append(nodeId)
    }
    func stopReports(withController controller: Any?, nodeId: UInt64, completion: @escaping () -> Void) {
        _ = (controller, completion)
        stopped.append(nodeId)
    }
    func subscribeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        establishedHandler: @escaping () -> Void
    ) {
        _ = (controller, endpointId, clusterId, attributeId, minInterval, maxInterval, params, establishedHandler)
        attributeSubscriptions.append(nodeId)
    }
    func subscribe(
        withController controller: Any?,
        nodeId: UInt64,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        shouldCache: Bool,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (controller, minInterval, maxInterval, params, completion)
        subscriptions.append((nodeId, shouldCache))
    }
    func writeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        attributeId: NSNumber,
        value: Any,
        timedWriteTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, clusterId, attributeId, value, timeoutMs, completion)
        writes.append((nodeId, endpointId))
    }
}

func testWave10ControllerServerReadCallbacks() {
    let stub = Wave10ServerRecorder()
    let server: any MTRDeviceControllerServerProtocol = stub
    server.downloadLog(withController: nil, nodeId: NSNumber(value: 1), type: .crash, timeout: 5) { _, _ in }
    server.getAnyDeviceController { _, _ in }
    server.getDeviceController(withFabricId: 77) { _, _ in }
    server.readAttributeCache(withController: nil, nodeId: 2, endpointId: nil, clusterId: nil, attributeId: nil) { _, _ in }
    server.readAttribute(
        withController: nil,
        nodeId: 3,
        endpointId: nil,
        clusterId: nil,
        attributeId: nil,
        params: nil
    ) { _, _ in }
    mtrRequire(stub.downloads.count == 1 && stub.downloads[0].1 == .crash, "downloadLog records type")
    mtrRequire(stub.anyControllerCount == 1, "getAnyDeviceController dispatches")
    mtrRequire(stub.fabricIDs == [77], "getDeviceController records fabric")
    mtrRequire(stub.cacheReads == [2], "readAttributeCache records node")
    mtrRequire(stub.reads == [3], "readAttribute records node")
}

func testWave10ControllerServerWriteCallbacks() {
    let stub = Wave10ServerRecorder()
    let server: any MTRDeviceControllerServerProtocol = stub
    server.invokeCommand(
        withController: nil,
        nodeId: 4,
        endpointId: NSNumber(value: 1),
        clusterId: NSNumber(value: 6),
        commandId: NSNumber(value: 2),
        fields: [:],
        timedInvokeTimeout: nil
    ) { _, _ in }
    server.writeAttribute(
        withController: nil,
        nodeId: 5,
        endpointId: NSNumber(value: 1),
        clusterId: NSNumber(value: 6),
        attributeId: NSNumber(value: 0),
        value: true,
        timedWriteTimeout: nil
    ) { _, _ in }
    server.stopReports(withController: nil, nodeId: 6) {}
    server.subscribeAttribute(
        withController: nil,
        nodeId: 7,
        endpointId: nil,
        clusterId: nil,
        attributeId: nil,
        minInterval: NSNumber(value: 1),
        maxInterval: NSNumber(value: 10),
        params: nil,
        establishedHandler: {}
    )
    server.subscribe(
        withController: nil,
        nodeId: 8,
        minInterval: NSNumber(value: 1),
        maxInterval: NSNumber(value: 10),
        params: nil,
        shouldCache: true
    ) { _ in }
    mtrRequire(stub.invoked.count == 1 && stub.invoked[0].0 == 4, "invokeCommand records node")
    mtrRequire(stub.writes.count == 1 && stub.writes[0].0 == 5, "writeAttribute records node")
    mtrRequire(stub.stopped == [6], "stopReports records node")
    mtrRequire(stub.attributeSubscriptions == [7], "subscribeAttribute records node")
    mtrRequire(stub.subscriptions.count == 1 && stub.subscriptions[0] == (8, true), "subscribe records cache flag")
}

private final class Wave10NOCRecorder: NSObject, MTRNOCChainIssuer {
    var csrCount = 0
    func onNOCChainGenerationNeeded(
        _ csrInfo: CSRInfo,
        attestationInfo: AttestationInfo,
        onNOCChainGenerationComplete: @escaping MTRNOCChainGenerationCompleteHandler
    ) {
        _ = (csrInfo, attestationInfo, onNOCChainGenerationComplete)
        csrCount += 1
    }
}

private final class Wave10OperationalRecorder: NSObject, MTROperationalCertificateIssuer {
    var skipValidation = false
    var issuedCount = 0
    var shouldSkipAttestationCertificateValidation: Bool { skipValidation }
    func issueOperationalCertificate(
        forRequest csrInfo: MTROperationalCSRInfo,
        attestationInfo: MTRDeviceAttestationInfo,
        controller: MTRDeviceController,
        completion: @escaping (MTROperationalCertificateChain?, (any Error)?) -> Void
    ) {
        _ = (csrInfo, attestationInfo, controller, completion)
        issuedCount += 1
    }
}

func testWave10NOCAndOperationalIssuerCallbacks() {
    let noc = Wave10NOCRecorder()
    let nocIssuer: any MTRNOCChainIssuer = noc
    let csr = CSRInfo(nonce: Data([0x01]), elements: Data([0x02]), elementsSignature: Data([0x03]), csr: Data([0x04]))
    let attestation = AttestationInfo(
        challenge: Data(),
        nonce: Data(),
        elements: Data(),
        elementsSignature: Data(),
        dac: Data(),
        pai: Data(),
        certificationDeclaration: Data(),
        firmwareInfo: nil
    )
    nocIssuer.onNOCChainGenerationNeeded(csr, attestationInfo: attestation) { _, _, _, _, _ in }
    mtrRequire(noc.csrCount == 1, "NOC chain request dispatches")
    let issuer = Wave10OperationalRecorder()
    let operational: any MTROperationalCertificateIssuer = issuer
    mtrRequire(operational.shouldSkipAttestationCertificateValidation == false, "validation flag defaults false")
    issuer.skipValidation = true
    mtrRequire(operational.shouldSkipAttestationCertificateValidation == true, "validation flag round-trips")
    operational.issueOperationalCertificate(
        forRequest: MTROperationalCSRInfo(csr: Data([0x05]), csrNonce: Data(), csrElementsTLV: Data(), attestationSignature: Data()),
        attestationInfo: MTRDeviceAttestationInfo(),
        controller: MTRDeviceController()
    ) { _, _ in }
    mtrRequire(issuer.issuedCount == 1, "operational certificate request dispatches")
}

private final class Wave10OTARecorder: NSObject, MTROTAProviderDelegate {
    var applyCount = 0
    var legacyApplyCount = 0
    var queryCount = 0
    var legacyQueryCount = 0
    var notifyCount = 0
    var legacyNotifyCount = 0
    var bdxQueryCount = 0
    var legacyBDXQueryCount = 0
    var bdxBeginCount = 0
    var legacyBDXBeginCount = 0
    var bdxEndCount = 0
    var bdxEndMetricsCount = 0
    func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
        applyCount += 1
    }
    func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
        legacyApplyCount += 1
    }
    func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completion: @escaping (Data?, Bool) -> Void
    ) {
        _ = (nodeID, controller, blockSize, blockIndex, bytesToSkip, completion)
        bdxQueryCount += 1
    }
    func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completionHandler: @escaping (Data?, Bool) -> Void
    ) {
        _ = (nodeID, controller, blockSize, blockIndex, bytesToSkip, completionHandler)
        legacyBDXQueryCount += 1
    }
    func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, fileDesignator, offset, completion)
        bdxBeginCount += 1
    }
    func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, fileDesignator, offset, completionHandler)
        legacyBDXBeginCount += 1
    }
    func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        error: (any Error)?
    ) {
        _ = (nodeID, controller, error)
        bdxEndCount += 1
    }
    func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        metrics: MTRMetrics,
        error: (any Error)?
    ) {
        _ = (nodeID, controller, metrics, error)
        bdxEndMetricsCount += 1
    }
    func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
        notifyCount += 1
    }
    func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
        legacyNotifyCount += 1
    }
    func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterQueryImageParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
        queryCount += 1
    }
    func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterQueryImageParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
        legacyQueryCount += 1
    }
}

func testWave10OTAQueryCallbacks() {
    let stub = Wave10OTARecorder()
    let ota: any MTROTAProviderDelegate = stub
    let controller = MTRDeviceController()
    let node = NSNumber(value: 21)
    ota.handleApplyUpdateRequest(forNodeID: node, controller: controller, params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams(), completion: { _, _ in })
    ota.handleApplyUpdateRequest(forNodeID: node, controller: controller, params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams(), completionHandler: { _, _ in })
    ota.handleQueryImage(forNodeID: node, controller: controller, params: MTROTASoftwareUpdateProviderClusterQueryImageParams(), completion: { _, _ in })
    ota.handleQueryImage(forNodeID: node, controller: controller, params: MTROtaSoftwareUpdateProviderClusterQueryImageParams(), completionHandler: { _, _ in })
    ota.handleNotifyUpdateApplied(forNodeID: node, controller: controller, params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams(), completion: { _ in })
    ota.handleNotifyUpdateApplied(forNodeID: node, controller: controller, params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams(), completionHandler: { _ in })
    mtrRequire(stub.applyCount == 1, "apply update dispatches")
    mtrRequire(stub.legacyApplyCount == 1, "legacy apply update dispatches")
    mtrRequire(stub.queryCount == 1, "query image dispatches")
    mtrRequire(stub.legacyQueryCount == 1, "legacy query image dispatches")
    mtrRequire(stub.notifyCount == 1, "notify applied dispatches")
    mtrRequire(stub.legacyNotifyCount == 1, "legacy notify applied dispatches")
}

func testWave10OTABDXCallbacks() {
    let stub = Wave10OTARecorder()
    let ota: any MTROTAProviderDelegate = stub
    let controller = MTRDeviceController()
    let node = NSNumber(value: 22)
    ota.handleBDXQuery(forNodeID: node, controller: controller, blockSize: NSNumber(value: 128), blockIndex: NSNumber(value: 0), bytesToSkip: NSNumber(value: 0), completion: { _, _ in })
    ota.handleBDXQuery(forNodeID: node, controller: controller, blockSize: NSNumber(value: 128), blockIndex: NSNumber(value: 0), bytesToSkip: NSNumber(value: 0), completionHandler: { _, _ in })
    ota.handleBDXTransferSessionBegin(forNodeID: node, controller: controller, fileDesignator: "img", offset: NSNumber(value: 0), completion: { _ in })
    ota.handleBDXTransferSessionBegin(forNodeID: node, controller: controller, fileDesignator: "img", offset: NSNumber(value: 0), completionHandler: { _ in })
    ota.handleBDXTransferSessionEnd(forNodeID: node, controller: controller, error: nil)
    ota.handleBDXTransferSessionEnd(forNodeID: node, controller: controller, metrics: MTRMetrics(), error: nil)
    mtrRequire(stub.bdxQueryCount == 1, "BDX query dispatches")
    mtrRequire(stub.legacyBDXQueryCount == 1, "legacy BDX query dispatches")
    mtrRequire(stub.bdxBeginCount == 1, "BDX begin dispatches")
    mtrRequire(stub.legacyBDXBeginCount == 1, "legacy BDX begin dispatches")
    mtrRequire(stub.bdxEndCount == 1, "BDX end dispatches")
    mtrRequire(stub.bdxEndMetricsCount == 1, "BDX end with metrics dispatches")
}
