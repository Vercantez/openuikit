import Foundation
import Dispatch
import Matter

func testBaseBinaryInputBasicClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterBinaryInputBasic.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeActiveText(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeActiveText(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeApplicationType(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeApplicationType(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeDescription(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeDescription(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeInactiveText(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeInactiveText(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeOutOfService(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeOutOfService(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributePolarity(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributePolarity(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributePresentValue(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributePresentValue(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeReliability(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeReliability(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeStatusFlags(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBinaryInputBasic.readAttributeStatusFlags(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBinaryInputBasicInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterBinaryInputBasic(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterBinaryInputBasic(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseBinaryInputBasicReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBinaryInputBasic(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBinaryInputBasic init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeActiveText(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeActiveText(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeApplicationType(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeApplicationType(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeDescription(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeDescription(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeInactiveText(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeInactiveText(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOutOfService(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOutOfService(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePolarity(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePolarity(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePresentValue(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePresentValue(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeReliability(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeReliability(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeStatusFlags(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeStatusFlags(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBinaryInputBasicSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBinaryInputBasic(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBinaryInputBasic init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeActiveText(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeActiveText(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeApplicationType(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeApplicationType(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeDescription(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeDescription(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeInactiveText(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeInactiveText(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOutOfService(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOutOfService(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePolarity(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePolarity(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePresentValue(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePresentValue(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeReliability(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeReliability(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeStatusFlags(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeStatusFlags(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBinaryInputBasicWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBinaryInputBasic(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBinaryInputBasic init")
        return
    }
    cluster.writeAttributeActiveText(withValue: "x", completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeActiveText(withValue: "x", completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeActiveText(withValue: "x", params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeActiveText(withValue: "x", params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeDescription(withValue: "x", completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeDescription(withValue: "x", completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeDescription(withValue: "x", params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeDescription(withValue: "x", params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInactiveText(withValue: "x", completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInactiveText(withValue: "x", completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInactiveText(withValue: "x", params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeInactiveText(withValue: "x", params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOutOfService(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOutOfService(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOutOfService(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOutOfService(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePresentValue(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePresentValue(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePresentValue(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePresentValue(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeReliability(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeReliability(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeReliability(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeReliability(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}
