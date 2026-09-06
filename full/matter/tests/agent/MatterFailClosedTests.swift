import Foundation
import Matter

func testControllerFailClosed() {
    let controller = MTRDeviceController()
    mtrRequire(!controller.running, "not running")
    mtrRequire(controller.devices().isEmpty, "no devices")
    let payload = MTRSetupPayload(setupPasscode: n(20202021), discriminator: n(3840))
    do {
        try controller.setupCommissioningSession(with: payload, newNodeID: n(1))
        mtrRequire(false, "session should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "session code")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        try controller.commissionNode(withID: n(1), commissioningParams: MTRCommissioningParameters())
        mtrRequire(false, "commission should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "commission code")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        try controller.cancelCommissioning(forNodeID: n(1))
        mtrRequire(false, "cancel should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .cancelled, "cancel code")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try controller.getDeviceBeingCommissioned(n(1))
        mtrRequire(false, "get should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .notFound, "not found")
    } catch {
        mtrRequire(false, "wrong error")
    }
    controller.shutdown()
    let device = MTRDevice.device(withNodeID: n(1), controller: controller)
    mtrRequire(device.nodeID.intValue == 1, "node")
    mtrRequire(device.state == .unknown, "state")
    mtrRequire(device.sessionTransportType == .undefined, "transport")
    do {
        _ = try (device as MTRBaseDevice).readAttribute(withEndpointID: n(1), clusterID: n(6), attributeID: n(0), params: nil)
        mtrRequire(false, "read should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "read")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try device.invokeCommand(withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: nil, timedInvokeTimeout: nil)
        mtrRequire(false, "invoke should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "invoke")
    } catch {
        mtrRequire(false, "wrong error")
    }
    let classes = MTRDeviceControllerStorageClasses()
    mtrRequire(classes.contains(ObjectIdentifier(MTRSetupPayload.self)), "storage classes")
    _ = MTRCluster()
    _ = MTRGenericBaseCluster()
    _ = MTRGenericCluster()
}

func testCertificateFailClosed() {
    let a = Data([1, 2, 3])
    let b = Data([1, 2, 3])
    mtrRequire(MTRCertificates.isCertificate(a, equalTo: b), "eq")
    mtrRequire(!MTRCertificates.isCertificate(a, equalTo: Data([9])), "neq")
    mtrRequire(MTRCertificates.convertMatterCertificate(a) == nil, "matter")
    mtrRequire(MTRCertificates.convertX509Certificate(a) == nil, "x509")
    final class DummyKey: NSObject, MTRKeypair {
        func signMessageECDSA_RAW(_ message: Data) -> Data { message }
        func signMessageECDSA_DER(_ message: Data) -> Data { message }
    }
    let key = DummyKey()
    mtrRequire(!MTRCertificates.keypair(key, matchesCertificate: a), "match")
    do {
        _ = try MTRCertificates.createCertificateSigningRequest(key)
        mtrRequire(false, "csr should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "csr")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try MTRCertificates.createRootCertificate(key, issuerID: nil, fabricID: n(1))
        mtrRequire(false, "root should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "root")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try MTRCertificates.publicKey(fromCSR: a)
        mtrRequire(false, "pubkey should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .tlvDecodeFailed, "pub")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try MTRCertificates.generateCertificateSigningRequest(key)
        mtrRequire(false, "gen csr")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "gencsr")
    } catch {
        mtrRequire(false, "wrong error")
    }
    let info = CSRInfo(nonce: a, elements: a, elementsSignature: a, csr: a)
    mtrRequire(info.csr == a, "csrinfo")
    let att = AttestationInfo(
        challenge: a, nonce: a, elements: a, elementsSignature: a,
        dac: a, pai: a, certificationDeclaration: a, firmwareInfo: nil
    )
    mtrRequire(att.dac == a, "att")
}

func testFactoryFailClosed() {
    let factory = MTRDeviceControllerFactory.sharedInstance()
    mtrRequire(!factory.running, "not running")
    do {
        try factory.start(MTRDeviceControllerFactoryParams())
        mtrRequire(false, "start should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "start")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try factory.createController(onNewFabric: MTRDeviceControllerParameters())
        mtrRequire(false, "new fabric")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "new")
    } catch {
        mtrRequire(false, "wrong error")
    }
    do {
        _ = try factory.createController(onExistingFabric: MTRDeviceControllerParameters())
        mtrRequire(false, "existing fabric")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "existing")
    } catch {
        mtrRequire(false, "wrong error")
    }
    factory.stop()
    _ = MTRControllerFactory.sharedFactory
    _ = MTRDeviceControllerExternalCertificateParameters()
    _ = MTRXPCDeviceControllerParameters()
}

func testOTAHeaderFailClosed() {
    do {
        _ = try MTROTAHeaderParser.header(fromData: Data([0, 1, 2]))
        mtrRequire(false, "ota should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .unknownSchema, "ota")
    } catch {
        mtrRequire(false, "wrong error")
    }
    let header = MTROTAHeader()
    mtrRequire(header.vendorID == nil, "empty")
}
