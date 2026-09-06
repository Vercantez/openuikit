import Foundation
import Dispatch
import Matter

func testBaseActionsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRBaseClusterActions(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRBaseClusterActions(device: baseDevice, endpoint: 1, queue: DispatchQueue.global())
}

func testBaseActionsClassCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    MTRBaseClusterActions.readAttributeAcceptedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeAcceptedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeActionList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeActionList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeAttributeList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeAttributeList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeClusterRevision(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeClusterRevision(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeEndpointLists(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeEndpointLists(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeFeatureMap(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeFeatureMap(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeGeneratedCommandList(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeGeneratedCommandList(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeSetupURL(withAttributeCache: MTRAttributeCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completionHandler: { _, err in mtrExpectInvalidState(err) })
    MTRBaseClusterActions.readAttributeSetupURL(withClusterStateCache: MTRClusterStateCacheContainer(), endpoint: n(1), queue: DispatchQueue.global(), completion: { _, err in mtrExpectInvalidState(err) })
}

func testBaseActionsCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterActions(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterActions init")
        return
    }
    cluster.disableActionWithDuration(with: MTRActionsClusterDisableActionWithDurationParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.disableActionWithDuration(with: MTRActionsClusterDisableActionWithDurationParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.disableAction(with: MTRActionsClusterDisableActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.disableAction(with: MTRActionsClusterDisableActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.enableActionWithDuration(with: MTRActionsClusterEnableActionWithDurationParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.enableActionWithDuration(with: MTRActionsClusterEnableActionWithDurationParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.enableAction(with: MTRActionsClusterEnableActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.enableAction(with: MTRActionsClusterEnableActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.instantAction(with: MTRActionsClusterInstantActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.instantAction(with: MTRActionsClusterInstantActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.instantActionWithTransition(with: MTRActionsClusterInstantActionWithTransitionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.instantActionWithTransition(with: MTRActionsClusterInstantActionWithTransitionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.pauseActionWithDuration(with: MTRActionsClusterPauseActionWithDurationParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.pauseActionWithDuration(with: MTRActionsClusterPauseActionWithDurationParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.pauseAction(with: MTRActionsClusterPauseActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.pauseAction(with: MTRActionsClusterPauseActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.resumeAction(with: MTRActionsClusterResumeActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.resumeAction(with: MTRActionsClusterResumeActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.startActionWithDuration(with: MTRActionsClusterStartActionWithDurationParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.startActionWithDuration(with: MTRActionsClusterStartActionWithDurationParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.startAction(with: MTRActionsClusterStartActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.startAction(with: MTRActionsClusterStartActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stopAction(with: MTRActionsClusterStopActionParams(), completion: { err in mtrExpectInvalidState(err) })
    cluster.stopAction(with: MTRActionsClusterStopActionParams(), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testBaseActionsRead() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterActions(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterActions init")
        return
    }
    cluster.readAttributeAcceptedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAcceptedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeActionList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeActionList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeAttributeList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeClusterRevision(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeEndpointLists(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeEndpointLists(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeFeatureMap(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeGeneratedCommandList(completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSetupURL(completion: { _, err in mtrExpectInvalidState(err) })
    cluster.readAttributeSetupURL(completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testBaseActionsSubscribe() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRBaseClusterActions(device: baseDevice, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRBaseClusterActions init")
        return
    }
    cluster.subscribeAttributeAcceptedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAcceptedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeActionList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeActionList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeAttributeList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeClusterRevision(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeEndpointLists(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeEndpointLists(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeFeatureMap(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeGeneratedCommandList(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSetupURL(withMinInterval: n(1), maxInterval: n(1), params: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.subscribeAttributeSetupURL(with: MTRSubscribeParams.new(), subscriptionEstablished: nil as MTRSubscriptionEstablishedHandler?, reportHandler: { _, err in mtrExpectInvalidState(err) })
}
