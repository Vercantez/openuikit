import Foundation
import Dispatch
import Matter

func testBaseFanControlClassCacheFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterFanControl.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeAirflowDirection(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFanModeSequence(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFanModeSequence(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFanMode(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFanMode(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributePercentCurrent(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributePercentCurrent(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributePercentSetting(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributePercentSetting(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeRockSetting(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeRockSetting(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeRockSupport(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeRockSupport(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedCurrent(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedCurrent(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedMax(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedMax(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedSetting(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeSpeedSetting(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeWindSetting(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeWindSetting(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeWindSupport(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterFanControl.readAttributeWindSupport(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseFanControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterFanControl(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRBaseClusterFanControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
}

func testBaseFanControlReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterFanControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterFanControl init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAirflowDirection(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFanModeSequence(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFanModeSequence(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFanMode(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFanMode(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePercentCurrent(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePercentCurrent(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePercentSetting(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributePercentSetting(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeRockSetting(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeRockSetting(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeRockSupport(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeRockSupport(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedCurrent(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedCurrent(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedMax(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedMax(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedSetting(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSpeedSetting(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeWindSetting(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeWindSetting(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeWindSupport(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeWindSupport(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseFanControlCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterFanControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterFanControl init")
        return
    }
    cluster.step(with: MTRFanControlClusterStepParams(), completion: { err in mtrExpectInvalidState(err) })
}

func testBaseFanControlSubscribeFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterFanControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterFanControl init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAirflowDirection(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFanModeSequence(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFanModeSequence(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFanMode(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFanMode(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePercentCurrent(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePercentCurrent(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePercentSetting(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributePercentSetting(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeRockSetting(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeRockSetting(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeRockSupport(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeRockSupport(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedCurrent(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedCurrent(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedMax(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedMax(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedSetting(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSpeedSetting(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeWindSetting(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeWindSetting(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeWindSupport(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeWindSupport(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseFanControlWriteFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterFanControl(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterFanControl init")
        return
    }
    cluster.writeAttributeAirflowDirection(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeAirflowDirection(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanModeSequence(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanModeSequence(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanModeSequence(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanModeSequence(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanMode(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanMode(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanMode(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeFanMode(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePercentSetting(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePercentSetting(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePercentSetting(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributePercentSetting(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeRockSetting(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeRockSetting(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeRockSetting(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeRockSetting(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeSpeedSetting(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeSpeedSetting(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeSpeedSetting(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeSpeedSetting(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeWindSetting(withValue: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeWindSetting(withValue: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeWindSetting(withValue: n(1), params: MTRWriteParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.writeAttributeWindSetting(withValue: n(1), params: MTRWriteParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}
