import Foundation
import Dispatch
import Matter

func testBaseNetworkCommissioningClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterNetworkCommissioning.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeConnectMaxTimeSeconds(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeConnectMaxTimeSeconds(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeInterfaceEnabled(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeInterfaceEnabled(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastConnectErrorValue(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastConnectErrorValue(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastNetworkID(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastNetworkID(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastNetworkingStatus(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeLastNetworkingStatus(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeMaxNetworks(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeMaxNetworks(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeNetworks(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeNetworks(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeScanMaxTimeSeconds(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeScanMaxTimeSeconds(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeSupportedThreadFeatures(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeSupportedWiFiBands(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterNetworkCommissioning.readAttributeThreadVersion(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseNetworkCommissioningCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterNetworkCommissioning init")
        return
    }
    cluster.addOrUpdateThreadNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateThreadNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateWiFiNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateWiFiNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.connectNetwork(with: MTRNetworkCommissioningClusterConnectNetworkParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.connectNetwork(with: MTRNetworkCommissioningClusterConnectNetworkParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.removeNetwork(with: MTRNetworkCommissioningClusterRemoveNetworkParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeNetwork(with: MTRNetworkCommissioningClusterRemoveNetworkParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.reorderNetwork(with: MTRNetworkCommissioningClusterReorderNetworkParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.reorderNetwork(with: MTRNetworkCommissioningClusterReorderNetworkParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(with: MTRNetworkCommissioningClusterScanNetworksParams(), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(with: MTRNetworkCommissioningClusterScanNetworksParams(), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseNetworkCommissioningInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseNetworkCommissioningReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterNetworkCommissioning init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeConnectMaxTimeSeconds(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeConnectMaxTimeSeconds(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeInterfaceEnabled(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeInterfaceEnabled(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastConnectErrorValue(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastConnectErrorValue(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastNetworkID(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastNetworkID(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastNetworkingStatus(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeLastNetworkingStatus(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeMaxNetworks(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeMaxNetworks(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeNetworks(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeNetworks(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeScanMaxTimeSeconds(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeScanMaxTimeSeconds(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSupportedThreadFeatures(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSupportedWiFiBands(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeThreadVersion(completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseNetworkCommissioningSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterNetworkCommissioning init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeConnectMaxTimeSeconds(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeConnectMaxTimeSeconds(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeInterfaceEnabled(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeInterfaceEnabled(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastConnectErrorValue(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastConnectErrorValue(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastNetworkID(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastNetworkID(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastNetworkingStatus(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeLastNetworkingStatus(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeMaxNetworks(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeMaxNetworks(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeNetworks(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeNetworks(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeScanMaxTimeSeconds(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeScanMaxTimeSeconds(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSupportedThreadFeatures(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSupportedWiFiBands(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeThreadVersion(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseNetworkCommissioningWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterNetworkCommissioning(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterNetworkCommissioning init")
        return
    }
    cluster.writeAttributeInterfaceEnabled(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInterfaceEnabled(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInterfaceEnabled(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInterfaceEnabled(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}
