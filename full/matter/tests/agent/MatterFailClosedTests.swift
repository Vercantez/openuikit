import Foundation
import Dispatch
import Matter

func testControllerCommissioningFailClosed() {
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
}

func testBaseDeviceInitAndTransport() {
    let controller = MTRDeviceController()
    let base = MTRBaseDevice(nodeID: n(1), controller: controller)
    mtrRequire(base.sessionTransportType == .undefined, "transport")
    let device = MTRDevice(nodeID: n(1), controller: controller)
    mtrRequire(device.nodeID.intValue == 1, "node")
    mtrRequire(device.state == .unknown, "state")
    let viaUInt = MTRDevice(nodeID: UInt64(2), deviceController: controller)
    mtrRequire(viaUInt.nodeID.uint64Value == 2, "uint64 init")
    let viaClass = MTRDevice.device(withNodeID: n(1), controller: controller)
    mtrRequire(viaClass.nodeID.intValue == 1, "class factory")
    mtrRequire(device.deviceController != nil, "controller stored")
    mtrRequire(device.estimatedSubscriptionLatency == nil, "no latency")
    mtrRequire(device.vendorID == nil, "no vendor")
    mtrRequire(device.productID == nil, "no product")
    mtrRequire(device.networkCommissioningFeatures.isEmpty, "no features")
    mtrRequire(device.descriptorClusters().isEmpty, "no descriptor")
    _ = MTRBaseDevice.self
    _ = MTRDevice.self
    _ = MTRCluster()
    _ = MTRGenericBaseCluster()
    _ = MTRGenericCluster()
    let classes = MTRDeviceControllerStorageClasses()
    mtrRequire(classes.contains(ObjectIdentifier(MTRSetupPayload.self)), "storage classes")
}

func testBaseDeviceReadWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    do {
        _ = try (device as MTRBaseDevice).readAttribute(withEndpointID: n(1), clusterID: n(6), attributeID: n(0), params: nil)
        mtrRequire(false, "read should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "read")
    } catch {
        mtrRequire(false, "wrong error")
    }
    device.readAttributes(withEndpointID: n(1), clusterID: n(6), attributeID: n(0), params: nil, queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.readAttribute(withEndpointId: n(1), clusterId: n(6), attributeId: n(0), params: nil, clientQueue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.readEvents(withEndpointID: n(1), clusterID: n(0x28), eventID: n(0), params: nil, queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.readAttributePaths(
        [MTRAttributeRequestPath(endpointID: n(1), clusterID: n(6), attributeID: n(0))],
        eventPaths: [MTREventRequestPath(endpointID: n(1), clusterID: n(0x28), eventID: n(0))],
        params: nil,
        queue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    _ = device.readAttributePaths([MTRAttributeRequestPath(endpointID: n(1), clusterID: n(6), attributeID: n(0))])
    device.writeAttribute(
        withEndpointID: n(1), clusterID: n(6), attributeID: n(0), value: n(1),
        timedWriteTimeout: n(100), queue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.writeAttribute(
        withEndpointId: n(1), clusterId: n(6), attributeId: n(0), value: n(1),
        timedWriteTimeout: n(100), clientQueue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.writeAttribute(
        withEndpointID: n(1), clusterID: n(6), attributeID: n(0), value: n(1),
        expectedValueInterval: n(1), timedWriteTimeout: n(100)
    )
}

func testBaseDeviceSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    device.subscribeAttribute(
        withEndpointId: n(1), clusterId: n(6), attributeId: n(0),
        minInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(),
        clientQueue: DispatchQueue.global(),
        reportHandler: { _, err in mtrExpectInvalidState(err) },
        subscriptionEstablished: nil
    )
    device.subscribe(
        toAttributePaths: [MTRAttributeRequestPath(endpointID: n(1), clusterID: n(6), attributeID: n(0))],
        eventPaths: nil, params: MTRSubscribeParams.new(), queue: DispatchQueue.global(),
        reportHandler: { _, err in mtrExpectInvalidState(err) },
        subscriptionEstablished: nil, resubscriptionScheduled: nil
    )
    device.subscribeToAttributes(
        withEndpointID: n(1), clusterID: n(6), attributeID: n(0),
        params: MTRSubscribeParams.new(), queue: DispatchQueue.global(),
        reportHandler: { _, err in mtrExpectInvalidState(err) },
        subscriptionEstablished: nil
    )
    device.subscribeToEvents(
        withEndpointID: n(1), clusterID: n(0x28), eventID: n(0),
        params: MTRSubscribeParams.new(), queue: DispatchQueue.global(),
        reportHandler: { _, err in mtrExpectInvalidState(err) },
        subscriptionEstablished: nil
    )
    device.subscribe(
        with: DispatchQueue.global(), minInterval: 1, maxInterval: 1,
        params: MTRSubscribeParams.new(), cacheContainer: MTRAttributeCacheContainer(),
        attributeReportHandler: nil, eventReportHandler: nil,
        errorHandler: { _ in }, subscriptionEstablished: nil, resubscriptionScheduled: nil
    )
    device.subscribe(
        with: DispatchQueue.global(), params: MTRSubscribeParams.new(),
        clusterStateCacheContainer: MTRClusterStateCacheContainer(),
        attributeReportHandler: nil, eventReportHandler: nil,
        errorHandler: { _ in }, subscriptionEstablished: nil, resubscriptionScheduled: nil
    )
    device.deregisterReportHandlers(withClientQueue: DispatchQueue.global(), completion: {})
    device.deregisterReportHandlers(with: DispatchQueue.global(), completion: {})
}

func testBaseDeviceCommandAndCommissionWindowFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    do {
        _ = try device.invokeCommand(withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: nil, timedInvokeTimeout: nil)
        mtrRequire(false, "invoke should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "invoke")
    } catch {
        mtrRequire(false, "wrong error")
    }
    device.invokeCommand(
        withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: n(1) as Any,
        timedInvokeTimeout: nil, queue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.invokeCommand(
        withEndpointId: n(1), clusterId: n(6), commandId: n(1), commandFields: n(1) as Any,
        timedInvokeTimeout: nil, clientQueue: DispatchQueue.global(),
        completionHandler: { _, err in mtrExpectInvalidState(err) }
    )
    device.invokeCommand(
        withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: nil,
        expectedValues: [], expectedValueInterval: n(1), queue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.invokeCommand(
        withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: n(1) as Any,
        expectedValues: [], expectedValueInterval: n(1), timedInvokeTimeout: nil,
        clientQueue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.invokeCommand(
        withEndpointID: n(1), clusterID: n(6), commandID: n(1), commandFields: n(1) as Any,
        expectedValues: [], expectedValueInterval: n(1), timedInvokeTimeout: nil,
        queue: DispatchQueue.global(),
        completion: { _, err in mtrExpectInvalidState(err) }
    )
    device.invokeCommands([[MTRCommandWithRequiredResponse()]], queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.openCommissioningWindow(withDiscriminator: n(3840), duration: n(60), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.openCommissioningWindow(withSetupPasscode: n(20202021), discriminator: n(3840), duration: n(60), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    device.downloadLog(of: .endUserSupport, timeout: 1, queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    let waiter = device.wait(forAttributeValues: [:], timeout: 1, queue: DispatchQueue.global(), completion: { err in mtrExpectInvalidState(err) })
    _ = waiter
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
        _ = try MTRCertificates.generateRootCertificate(key, issuerId: nil, fabricId: n(1))
        mtrRequire(false, "gen root")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, "genroot")
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

func testCertificateInfoTLV() {
    let bytes = Data([0x15, 0x24, 0x00])
    let info = MTRCertificateInfo(tlvBytes: bytes)
    mtrRequire(info != nil, "tlv init")
    mtrRequire(info?.notAfter == nil, "notAfter unread")
    mtrRequire(info?.notBefore == nil, "notBefore unread")
    mtrRequire(info?.subject == nil, "subject unread")
    mtrRequire(info?.publicKeyData == nil, "publicKey unread")
    let alias = MTRCertificateInfo(TLVBytes: bytes)
    mtrRequire(alias != nil, "TLV alias")
    _ = MTRCertificateInfo.self
}

func testFactoryFailClosed() {
    let factory = MTRDeviceControllerFactory.sharedInstance()
    mtrRequire(!factory.running, "not running")
    mtrRequire(!factory.isRunning, "isRunning")
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

func testControllerFactoryAliases() {
    final class DummyKey: NSObject, MTRKeypair {
        func signMessageECDSA_RAW(_ message: Data) -> Data { message }
        func signMessageECDSA_DER(_ message: Data) -> Data { message }
    }
    let factory = MTRControllerFactory.sharedFactory
    mtrRequire(!factory.isRunning, "alias running")
    let params = MTRControllerFactoryParams()
    params.cdCerts = [Data([1])]
    params.paaCerts = [Data([2])]
    params.startServer = false
    mtrRequire(params.cdCerts?.count == 1, "cd")
    mtrRequire(params.paaCerts?.count == 1, "paa")
    mtrRequire(!params.startServer, "server")
    _ = params.storageDelegate
    mtrRequire(!factory.startup(params), "startup false")
    let ipk = Data(repeating: 0xAB, count: 16)
    let key = DummyKey()
    let startup = MTRDeviceControllerStartupParams(ipk: ipk, fabricID: n(1), nocSigner: key)
    mtrRequire(factory.startController(onExistingFabric: startup) == nil, "start existing nil")
    mtrRequire(factory.startController(onNewFabric: startup) == nil, "start new nil")
    factory.shutdown()
    _ = MTRControllerFactoryParams.self
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
    let fromData = MTROTAHeader(data: Data([1, 2, 3]))
    fromData.imageDigest = Data([9])
    fromData.imageDigestType = .sha256
    fromData.maxApplicableVersion = n(2)
    fromData.minApplicableVersion = n(1)
    fromData.payloadSize = n(10)
    fromData.productID = n(1)
    fromData.releaseNotesURL = "https://example.invalid"
    fromData.softwareVersion = n(3)
    fromData.softwareVersionString = "3.0"
    fromData.vendorID = n(0xFFF1)
    mtrRequire(fromData.imageDigest.count == 1, "digest")
    mtrRequire(fromData.softwareVersionString == "3.0", "ver str")
}
