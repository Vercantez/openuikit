import Foundation
import Dispatch
import Matter

func testBaseBarrierControlClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterBarrierControl.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCapabilities(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCapabilities(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCloseEvents(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCloseEvents(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierClosePeriod(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierClosePeriod(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCommandCloseEvents(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCommandCloseEvents(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCommandOpenEvents(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierCommandOpenEvents(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierMovingState(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierMovingState(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierOpenEvents(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierOpenEvents(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierOpenPeriod(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierOpenPeriod(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierPosition(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierPosition(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierSafetyStatus(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeBarrierSafetyStatus(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterBarrierControl.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBarrierControlCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBarrierControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBarrierControl init")
        return
    }
    cluster.barrierControlGoToPercent(with: MTRBarrierControlClusterBarrierControlGoToPercentParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlGoToPercent(with: MTRBarrierControlClusterBarrierControlGoToPercentParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(with: MTRBarrierControlClusterBarrierControlStopParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(with: MTRBarrierControlClusterBarrierControlStopParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testBaseBarrierControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterBarrierControl(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterBarrierControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseBarrierControlReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBarrierControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBarrierControl init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCapabilities(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCapabilities(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCloseEvents(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCloseEvents(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierClosePeriod(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierClosePeriod(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCommandCloseEvents(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCommandCloseEvents(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCommandOpenEvents(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierCommandOpenEvents(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierMovingState(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierMovingState(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierOpenEvents(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierOpenEvents(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierOpenPeriod(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierOpenPeriod(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierPosition(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierPosition(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierSafetyStatus(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeBarrierSafetyStatus(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBarrierControlSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBarrierControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBarrierControl init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCapabilities(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCapabilities(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCloseEvents(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCloseEvents(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierClosePeriod(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierClosePeriod(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCommandCloseEvents(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCommandCloseEvents(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCommandOpenEvents(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierCommandOpenEvents(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierMovingState(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierMovingState(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierOpenEvents(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierOpenEvents(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierOpenPeriod(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierOpenPeriod(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierPosition(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierPosition(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierSafetyStatus(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeBarrierSafetyStatus(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseBarrierControlWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterBarrierControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterBarrierControl init")
        return
    }
    cluster.writeAttributeBarrierCloseEvents(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCloseEvents(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCloseEvents(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCloseEvents(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierClosePeriod(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierClosePeriod(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierClosePeriod(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierClosePeriod(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenEvents(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenEvents(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenEvents(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenEvents(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenPeriod(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenPeriod(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenPeriod(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeBarrierOpenPeriod(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}
