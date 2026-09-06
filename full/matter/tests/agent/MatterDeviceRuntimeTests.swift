import Foundation
import Dispatch
import Matter

final class MTRHostDeviceDelegate: NSObject, MTRDeviceDelegate {
    var order: [String] = []
    func device(_ device: MTRDevice, stateChanged state: MTRDeviceState) {
        order.append("state:\(state.rawValue)")
    }
    func device(_ device: MTRDevice, receivedAttributeReport attributeReport: [[String : Any]]) {
        order.append("attribute:\(attributeReport.count)")
    }
    func device(_ device: MTRDevice, receivedEventReport eventReport: [[String : Any]]) {
        order.append("event:\(eventReport.count)")
    }
}

func testStartupParamsValidation() {
    final class DummyKey: NSObject, MTRKeypair {
        func signMessageECDSA_RAW(_ message: Data) -> Data { message }
        func signMessageECDSA_DER(_ message: Data) -> Data { message }
    }
    let key = DummyKey()
    let short = MTRDeviceControllerStartupParams(ipk: Data([1, 2]), fabricID: n(1), nocSigner: key)
    mtrRequire(short.fabricID.intValue == 1, "fabric")
    mtrRequire(short.fabricId == 1, "fabricId")
    mtrRequire(short.ipk.count == 2, "short ipk stored")
    let factory = MTRDeviceControllerFactory.sharedInstance()
    do {
        _ = try factory.createController(onNewFabric: short)
        mtrRequire(false, "short ipk should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidArgument, "ipk length")
    } catch {
        mtrRequire(false, "wrong error")
    }
    let ipk = Data(repeating: 0xAB, count: 16)
    let ok = MTRDeviceControllerStartupParams(IPK: ipk, fabricID: n(1), nocSigner: key)
    ok.nodeID = n(7)
    ok.vendorID = n(0xFFF1)
    mtrRequire(ok.nodeId?.intValue == 7, "node alias")
    mtrRequire(ok.vendorId?.uintValue == 0xFFF1, "vendor alias")
    do {
        _ = try factory.createController(onExistingFabric: ok)
        mtrRequire(false, "valid params still fail-closed")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "no radio")
    } catch {
        mtrRequire(false, "wrong error")
    }
    let viaSigning = MTRDeviceControllerStartupParams(signing: key, fabricId: 2, ipk: ipk)
    mtrRequire(viaSigning.fabricId == 2, "signing fabric")
    let cert = Data([0x30, 0x00])
    let root = Data([0x30, 0x01])
    let viaOp = MTRDeviceControllerStartupParams(
        ipk: ipk, operationalKeypair: key, operationalCertificate: cert,
        intermediateCertificate: nil, rootCertificate: root
    )
    mtrRequire(viaOp.operationalCertificate == cert, "op cert")
    mtrRequire(viaOp.rootCertificate == root, "root cert")
    let viaIPK = MTRDeviceControllerStartupParams(
        IPK: ipk, operationalKeypair: key, operationalCertificate: cert,
        intermediateCertificate: nil, rootCertificate: root
    )
    mtrRequire(viaIPK.rootCertificate == root, "IPK op")
    let viaTail = MTRDeviceControllerStartupParams(
        operationalKeypair: key, operationalCertificate: cert,
        intermediateCertificate: nil, rootCertificate: root, ipk: ipk
    )
    mtrRequire(viaTail.ipk.count == 16, "tail ipk")
    viaOp.caseAuthenticatedTags = [n(1)]
    viaOp.rootCertificate = root
    viaOp.operationalCertificateIssuerQueue = DispatchQueue.global()
    mtrRequire(viaOp.caseAuthenticatedTags?.count == 1, "cats")
    mtrRequire(viaOp.nocSigner == nil, "op path has no nocSigner")
    let params = MTRDeviceControllerParameters()
    params.startSuspended = true
    params.shouldAdvertiseOperational = true
    params.storageBehaviorConfiguration = MTRDeviceStorageBehaviorConfiguration()
    mtrRequire(params.startSuspended, "suspended")
    factory.preWarmCommissioningSession()
    mtrRequire(factory.knownFabrics == nil, "no fabrics")
    mtrRequire(!factory.isRunning, "isRunning")
}

func testDeviceDelegateDispatchOrder() {
    let controller = MTRDeviceController()
    mtrRequire(!controller.isRunning, "controller down")
    controller.controllerNodeID = n(99)
    mtrRequire(controller.controllerNodeID?.intValue == 99, "node id stored")
    controller.shutdown()
    mtrRequire(!controller.isRunning, "shutdown")
    mtrRequire(controller.controllerNodeID == nil, "cleared")
    let device = MTRDevice(nodeID: n(4), controller: controller)
    mtrRequire(device.state == .unknown, "start unknown")
    mtrRequire(device.estimatedStartDate == nil, "no start")
    let delegate = MTRHostDeviceDelegate()
    device.setDelegate(delegate, queue: DispatchQueue.global())
    mtrRequire(delegate.order.first == "state:0", "state first")
    device.writeAttribute(
        withEndpointID: n(1), clusterID: n(6), attributeID: n(0),
        value: MTRMakeDataValue(type: MTRBooleanValueType, value: true),
        expectedValueInterval: n(1000)
    )
    mtrRequire(delegate.order.contains { $0.hasPrefix("attribute:") }, "attr after")
    let idxState = delegate.order.firstIndex(where: { $0.hasPrefix("state:") })!
    let idxAttr = delegate.order.firstIndex(where: { $0.hasPrefix("attribute:") })!
    mtrRequire(idxState < idxAttr, "state before attribute")
    let cached: [String: Any]? = device.readAttribute(
        withEndpointID: n(1), clusterID: n(6), attributeID: n(0), params: nil
    )
    mtrRequire(cached?[MTRTypeKey] as? String == MTRBooleanValueType, "cached type")
    device.mtrHostSetState(.reachable)
    mtrRequire(device.state == .reachable, "reachable host inject")
    mtrRequire(device.estimatedStartTime != nil, "start date")
    let event = MTREventPath(endpointID: n(1), clusterID: n(0x28), eventID: n(0))
    let decoded = try? MTREventReport(responseValue: MTRMakeEventResponse(
        path: event, data: MTRMakeDataValue(type: MTRBooleanValueType, value: true)
    ))
    mtrRequire(decoded?.path.event.uintValue == 0, "event decode")
    device.add(delegate, queue: DispatchQueue.global())
    device.remove(delegate)
}
