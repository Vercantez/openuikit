import Foundation
import Dispatch
import Matter

func testBaseOnOffClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterOnOff.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeGlobalSceneControl(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeGlobalSceneControl(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOffWaitTime(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOffWaitTime(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOnOff(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOnOff(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOnTime(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeOnTime(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeStartUp(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterOnOff.readAttributeStartUp(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOnOffInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterOnOff(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterOnOff(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseOnOffCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterOnOff(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOnOff init")
        return
    }
    cluster.off(completion: { err in mtrExpectInvalidState(err) })
    cluster.off(completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.offWithEffect(with: MTROnOffClusterOffWithEffectParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.offWithEffect(with: MTROnOffClusterOffWithEffectParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.off(with: MTROnOffClusterOffParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.off(with: MTROnOffClusterOffParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.on(completion: { err in mtrExpectInvalidState(err) })
    cluster.on(completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.on(with: MTROnOffClusterOnParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.on(with: MTROnOffClusterOnParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(with: MTROnOffClusterOnWithRecallGlobalSceneParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(with: MTROnOffClusterOnWithRecallGlobalSceneParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithTimedOff(with: MTROnOffClusterOnWithTimedOffParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithTimedOff(with: MTROnOffClusterOnWithTimedOffParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.toggle(completion: { err in mtrExpectInvalidState(err) })
    cluster.toggle(completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.toggle(with: MTROnOffClusterToggleParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.toggle(with: MTROnOffClusterToggleParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testBaseOnOffReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterOnOff(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOnOff init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGlobalSceneControl(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGlobalSceneControl(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOffWaitTime(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOffWaitTime(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOnOff(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOnOff(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOnTime(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeOnTime(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeStartUp(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeStartUp(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOnOffSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterOnOff(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOnOff init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGlobalSceneControl(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGlobalSceneControl(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOffWaitTime(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOffWaitTime(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOnOff(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOnOff(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOnTime(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeOnTime(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeStartUp(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeStartUp(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseOnOffWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterOnOff(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterOnOff init")
        return
    }
    cluster.writeAttributeOffWaitTime(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOffWaitTime(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOffWaitTime(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOffWaitTime(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOnTime(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOnTime(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOnTime(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeOnTime(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeStartUp(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeStartUp(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeStartUp(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeStartUp(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}
