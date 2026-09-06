import Foundation
import Dispatch
import Matter

func testBaseOperationalCredentialsClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    MTRBaseClusterOperationalCredentials.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeCommissionedFabrics(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeCommissionedFabrics(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeCurrentFabricIndex(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeCurrentFabricIndex(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeFabrics(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeFabrics(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeNOCs(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeNOCs(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeSupportedFabrics(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeSupportedFabrics(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeTrustedRootCertificates(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOperationalCredentials.readAttributeTrustedRootCertificates(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOperationalCredentialsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRBaseClusterOperationalCredentials(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOperationalCredentials init")
        return
    }
    cluster.csrRequest(with: MTROperationalCredentialsClusterCSRRequestParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.csrRequest(with: MTROperationalCredentialsClusterCSRRequestParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addNOC(with: MTROperationalCredentialsClusterAddNOCParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addNOC(with: MTROperationalCredentialsClusterAddNOCParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addTrustedRootCertificate(with: MTROperationalCredentialsClusterAddTrustedRootCertificateParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.addTrustedRootCertificate(with: MTROperationalCredentialsClusterAddTrustedRootCertificateParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.attestationRequest(with: MTROperationalCredentialsClusterAttestationRequestParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.attestationRequest(with: MTROperationalCredentialsClusterAttestationRequestParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.certificateChainRequest(with: MTROperationalCredentialsClusterCertificateChainRequestParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.certificateChainRequest(with: MTROperationalCredentialsClusterCertificateChainRequestParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.removeFabric(with: MTROperationalCredentialsClusterRemoveFabricParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeFabric(with: MTROperationalCredentialsClusterRemoveFabricParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.updateFabricLabel(with: MTROperationalCredentialsClusterUpdateFabricLabelParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.updateFabricLabel(with: MTROperationalCredentialsClusterUpdateFabricLabelParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.updateNOC(with: MTROperationalCredentialsClusterUpdateNOCParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.updateNOC(with: MTROperationalCredentialsClusterUpdateNOCParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOperationalCredentialsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRBaseClusterOperationalCredentials(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterOperationalCredentials(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseOperationalCredentialsReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRBaseClusterOperationalCredentials(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOperationalCredentials init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeCommissionedFabrics(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeCommissionedFabrics(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeCurrentFabricIndex(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeCurrentFabricIndex(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFabrics(with: MTRReadParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFabrics(with: MTRReadParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeNOCs(with: MTRReadParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeNOCs(with: MTRReadParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSupportedFabrics(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSupportedFabrics(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeTrustedRootCertificates(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeTrustedRootCertificates(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOperationalCredentialsSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRBaseClusterOperationalCredentials(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOperationalCredentials init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeCommissionedFabrics(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeCommissionedFabrics(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeCurrentFabricIndex(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeCurrentFabricIndex(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFabrics(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFabrics(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeNOCs(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeNOCs(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSupportedFabrics(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSupportedFabrics(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeTrustedRootCertificates(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeTrustedRootCertificates(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

