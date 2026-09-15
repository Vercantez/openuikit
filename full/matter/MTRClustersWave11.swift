import Foundation
import Dispatch

// Wave-11 generated Matter Base/Device cluster fail-closed I/O.

open class MTRBaseClusterAccountLogin: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func getSetupPIN(with params: MTRAccountLoginClusterGetSetupPINParams, completion: @escaping (MTRAccountLoginClusterGetSetupPINResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getSetupPIN(with params: MTRAccountLoginClusterGetSetupPINParams, completionHandler: @escaping (MTRAccountLoginClusterGetSetupPINResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func login(with params: MTRAccountLoginClusterLoginParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func login(with params: MTRAccountLoginClusterLoginParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func logout(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func logout(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func logout(with params: MTRAccountLoginClusterLogoutParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func logout(with params: MTRAccountLoginClusterLogoutParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterActivatedCarbonFilterMonitoring: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeChangeIndication(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCondition(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDegradationDirection(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeInPlaceIndicator(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLastChangedTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReplacementProductList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChangeIndication(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCondition(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDegradationDirection(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInPlaceIndicator(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLastChangedTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReplacementProductList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(with params: MTRActivatedCarbonFilterMonitoringClusterResetConditionParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChangeIndication(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCondition(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDegradationDirection(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInPlaceIndicator(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLastChangedTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReplacementProductList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeLastChangedTime(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLastChangedTime(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterAirQuality: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAirQuality(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAirQuality(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAirQuality(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterAudioOutput: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentOutput(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentOutput(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOutputList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeOutputList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentOutput(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentOutput(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOutputList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOutputList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func renameOutput(with params: MTRAudioOutputClusterRenameOutputParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func renameOutput(with params: MTRAudioOutputClusterRenameOutputParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func select(with params: MTRAudioOutputClusterSelectOutputParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func select(with params: MTRAudioOutputClusterSelectOutputParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentOutput(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentOutput(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOutputList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOutputList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterBinding: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBinding(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeBinding(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBinding(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBinding(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBinding(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBinding(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeBinding(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeBinding(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeBinding(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeBinding(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterBooleanState: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeStateValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeStateValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStateValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStateValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStateValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStateValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterBooleanStateConfiguration: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAlarmsActive(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAlarmsEnabled(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAlarmsSupported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAlarmsSuppressed(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentSensitivityLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDefaultSensitivityLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSensorFault(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedSensitivityLevels(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func enableDisableAlarm(with params: MTRBooleanStateConfigurationClusterEnableDisableAlarmParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAlarmsActive(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAlarmsEnabled(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAlarmsSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAlarmsSuppressed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentSensitivityLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultSensitivityLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSensorFault(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedSensitivityLevels(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAlarmsActive(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAlarmsEnabled(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAlarmsSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAlarmsSuppressed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentSensitivityLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultSensitivityLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSensorFault(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedSensitivityLevels(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func suppressAlarm(with params: MTRBooleanStateConfigurationClusterSuppressAlarmParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeCurrentSensitivityLevel(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeCurrentSensitivityLevel(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterCarbonDioxideConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterCarbonMonoxideConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterCommissionerControl: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedDeviceCategories(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func commissionNode(with params: MTRCommissionerControlClusterCommissionNodeParams, completion: @escaping (MTRCommissionerControlClusterReverseOpenCommissioningWindowParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedDeviceCategories(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func requestCommissioningApproval(with params: MTRCommissionerControlClusterRequestCommissioningApprovalParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedDeviceCategories(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterContentAppObserver: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func contentAppMessage(with params: MTRContentAppObserverClusterContentAppMessageParams, completion: @escaping (MTRContentAppObserverClusterContentAppMessageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterDeviceEnergyManagementMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRDeviceEnergyManagementModeClusterChangeToModeParams, completion: @escaping (MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterDiagnosticLogs: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func retrieveLogsRequest(with params: MTRDiagnosticLogsClusterRetrieveLogsRequestParams, completion: @escaping (MTRDiagnosticLogsClusterRetrieveLogsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func retrieveLogsRequest(with params: MTRDiagnosticLogsClusterRetrieveLogsRequestParams, completionHandler: @escaping (MTRDiagnosticLogsClusterRetrieveLogsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterDishwasherAlarm: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLatch(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMask(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func modifyEnabledAlarms(with params: MTRDishwasherAlarmClusterModifyEnabledAlarmsParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLatch(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMask(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func reset(with params: MTRDishwasherAlarmClusterResetParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLatch(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMask(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterDishwasherMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRDishwasherModeClusterChangeToModeParams, completion: @escaping (MTRDishwasherModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterElectricalEnergyMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAccuracy(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCumulativeEnergyExported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCumulativeEnergyImported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCumulativeEnergyReset(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeriodicEnergyExported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeriodicEnergyImported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAccuracy(completion: @escaping (MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCumulativeEnergyExported(completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCumulativeEnergyImported(completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCumulativeEnergyReset(completion: @escaping (MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeriodicEnergyExported(completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeriodicEnergyImported(completion: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAccuracy(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCumulativeEnergyExported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCumulativeEnergyImported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCumulativeEnergyReset(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeriodicEnergyExported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeriodicEnergyImported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterEnergyEVSEMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTREnergyEVSEModeClusterChangeToModeParams, completion: @escaping (MTREnergyEVSEModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterFixedLabel: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLabelList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLabelList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLabelList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLabelList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLabelList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLabelList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterFormaldehydeConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterHEPAFilterMonitoring: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeChangeIndication(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCondition(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDegradationDirection(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeInPlaceIndicator(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLastChangedTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReplacementProductList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChangeIndication(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCondition(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDegradationDirection(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInPlaceIndicator(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLastChangedTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReplacementProductList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(with params: MTRHEPAFilterMonitoringClusterResetConditionParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChangeIndication(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCondition(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDegradationDirection(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInPlaceIndicator(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLastChangedTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReplacementProductList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeLastChangedTime(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLastChangedTime(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterICDManagement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveModeDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveModeThreshold(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClientsSupportedPerFabric(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeICDCounter(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeIdleModeDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaximumCheckInBackOff(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperatingMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRegisteredClients(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUserActiveModeTriggerHint(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUserActiveModeTriggerInstruction(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveModeDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveModeThreshold(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClientsSupportedPerFabric(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeICDCounter(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeIdleModeDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaximumCheckInBackOff(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperatingMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRegisteredClients(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUserActiveModeTriggerHint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUserActiveModeTriggerInstruction(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func registerClient(with params: MTRICDManagementClusterRegisterClientParams, completion: @escaping (MTRICDManagementClusterRegisterClientResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func stayActiveRequest(with params: MTRICDManagementClusterStayActiveRequestParams, completion: @escaping (MTRICDManagementClusterStayActiveResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveModeDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveModeThreshold(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClientsSupportedPerFabric(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeICDCounter(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeIdleModeDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaximumCheckInBackOff(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperatingMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRegisteredClients(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUserActiveModeTriggerHint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUserActiveModeTriggerInstruction(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func unregisterClient(with params: MTRICDManagementClusterUnregisterClientParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterKeypadInput: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func sendKey(with params: MTRKeypadInputClusterSendKeyParams, completion: @escaping (MTRKeypadInputClusterSendKeyResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func sendKey(with params: MTRKeypadInputClusterSendKeyParams, completionHandler: @escaping (MTRKeypadInputClusterSendKeyResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterLaundryDryerControls: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSelectedDrynessLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedDrynessLevels(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSelectedDrynessLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedDrynessLevels(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSelectedDrynessLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedDrynessLevels(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeSelectedDrynessLevel(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSelectedDrynessLevel(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterLaundryWasherControls: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNumberOfRinses(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSpinSpeedCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSpinSpeeds(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedRinses(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfRinses(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSpinSpeedCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSpinSpeeds(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedRinses(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfRinses(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSpinSpeedCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSpinSpeeds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedRinses(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeNumberOfRinses(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeNumberOfRinses(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSpinSpeedCurrent(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSpinSpeedCurrent(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterLaundryWasherMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRLaundryWasherModeClusterChangeToModeParams, completion: @escaping (MTRLaundryWasherModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterLocalizationConfiguration: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveLocale(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActiveLocale(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedLocales(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSupportedLocales(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveLocale(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveLocale(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportedLocales(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedLocales(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveLocale(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveLocale(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedLocales(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedLocales(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeActiveLocale(withValue value: String, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeActiveLocale(withValue value: String, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeActiveLocale(withValue value: String, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeActiveLocale(withValue value: String, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterLowPower: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func sleep(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func sleep(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func sleep(with params: MTRLowPowerClusterSleepParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func sleep(with params: MTRLowPowerClusterSleepParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterMessages: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveMessageIDs(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMessages(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func cancelRequest(with params: MTRMessagesClusterCancelMessagesRequestParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func presentRequest(with params: MTRMessagesClusterPresentMessagesRequestParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveMessageIDs(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMessages(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveMessageIDs(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMessages(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterMicrowaveOvenControl: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCookTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxCookTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxPower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinPower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePowerSetting(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePowerStep(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeWattRating(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func addMoreTime(with params: MTRMicrowaveOvenControlClusterAddMoreTimeParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCookTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxCookTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerSetting(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerStep(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWattRating(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setCookingParametersWithCompletion(_ completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setCookingParametersWith(_ params: MTRMicrowaveOvenControlClusterSetCookingParametersParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCookTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxCookTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerSetting(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerStep(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWattRating(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterMicrowaveOvenMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterNitrogenDioxideConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterOTASoftwareUpdateProvider: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func applyUpdateRequest(with params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams, completion: @escaping (MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func notifyUpdateApplied(with params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func queryImage(with params: MTROTASoftwareUpdateProviderClusterQueryImageParams, completion: @escaping (MTROTASoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterOTASoftwareUpdateRequestor: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDefaultOTAProviders(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUpdatePossible(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUpdateStateProgress(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUpdateState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func announceOTAProvider(with params: MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultOTAProviders(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUpdatePossible(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUpdateStateProgress(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUpdateState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultOTAProviders(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdatePossible(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdateStateProgress(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdateState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeDefaultOTAProviders(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeDefaultOTAProviders(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterOnOffSwitchConfiguration: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSwitchActions(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSwitchActions(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSwitchType(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSwitchType(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSwitchActions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSwitchActions(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSwitchType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSwitchType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSwitchActions(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSwitchActions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSwitchType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSwitchType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeSwitchActions(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSwitchActions(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeSwitchActions(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSwitchActions(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterOperationalState: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCountdownTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentPhase(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalError(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTROperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalStateList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePhaseList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func pause(completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func pause(with params: MTROperationalStateClusterPauseParams?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCountdownTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPhase(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalError(completion: @escaping (MTROperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalStateList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhaseList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resume(completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resume(with params: MTROperationalStateClusterResumeParams?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func start(completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func start(with params: MTROperationalStateClusterStartParams?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func stop(completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func stop(with params: MTROperationalStateClusterStopParams?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCountdownTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPhase(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalError(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTROperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalStateList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhaseList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterOvenCavityOperationalState: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCountdownTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentPhase(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalError(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTROvenCavityOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalStateList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePhaseList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCountdownTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPhase(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalError(completion: @escaping (MTROvenCavityOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalStateList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhaseList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func start(completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func start(with params: MTROvenCavityOperationalStateClusterStartParams?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func stop(completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func stop(with params: MTROvenCavityOperationalStateClusterStopParams?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCountdownTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPhase(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalError(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTROvenCavityOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalStateList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhaseList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterOvenMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTROvenModeClusterChangeToModeParams, completion: @escaping (MTROvenModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterOzoneConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterPM10ConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterPM1ConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterPM25ConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterPowerSourceConfiguration: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSources(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSources(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSources(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSources(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSources(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSources(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterPowerTopology: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveEndpoints(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAvailableEndpoints(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveEndpoints(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAvailableEndpoints(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveEndpoints(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAvailableEndpoints(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRVCCleanMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRRVCCleanModeClusterChangeToModeParams, completion: @escaping (MTRRVCCleanModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRVCOperationalState: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCountdownTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentPhase(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalError(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRRVCOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalStateList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOperationalState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePhaseList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func goHome(completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func goHome(with params: MTRRVCOperationalStateClusterGoHomeParams?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func pause(completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func pause(with params: MTRRVCOperationalStateClusterPauseParams?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCountdownTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPhase(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalError(completion: @escaping (MTRRVCOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalStateList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhaseList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resume(completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resume(with params: MTRRVCOperationalStateClusterResumeParams?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCountdownTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPhase(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalError(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRRVCOperationalStateClusterErrorStateStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalStateList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhaseList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRVCRunMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRRVCRunModeClusterChangeToModeParams, completion: @escaping (MTRRVCRunModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRadonConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRefrigeratorAlarm: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMask(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupported(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMask(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMask(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterRefrigeratorAndTemperatureControlledCabinetMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams, completion: @escaping (MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterServiceArea: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentArea(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeEstimatedEndTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProgress(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSelectedAreas(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedAreas(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedMaps(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentArea(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEstimatedEndTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProgress(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSelectedAreas(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedAreas(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedMaps(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func selectAreas(with params: MTRServiceAreaClusterSelectAreasParams, completion: @escaping (MTRServiceAreaClusterSelectAreasResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRServiceAreaClusterSkipAreaParams, completion: @escaping (MTRServiceAreaClusterSkipAreaResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentArea(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEstimatedEndTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProgress(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSelectedAreas(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedAreas(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedMaps(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterTargetNavigator: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentTarget(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentTarget(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTargetList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTargetList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func navigateTarget(with params: MTRTargetNavigatorClusterNavigateTargetParams, completion: @escaping (MTRTargetNavigatorClusterNavigateTargetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func navigateTarget(with params: MTRTargetNavigatorClusterNavigateTargetParams, completionHandler: @escaping (MTRTargetNavigatorClusterNavigateTargetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentTarget(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentTarget(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTargetList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentTarget(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentTarget(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterTemperatureControl: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxTemperature(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinTemperature(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSelectedTemperatureLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeStep(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedTemperatureLevels(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTemperatureSetpoint(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxTemperature(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinTemperature(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSelectedTemperatureLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStep(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedTemperatureLevels(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTemperatureSetpoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setTemperatureWithCompletion(_ completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setTemperatureWith(_ params: MTRTemperatureControlClusterSetTemperatureParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxTemperature(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinTemperature(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSelectedTemperatureLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStep(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedTemperatureLevels(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureSetpoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterThreadBorderRouterManagement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveDatasetTimestamp(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBorderAgentID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBorderRouterName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeInterfaceEnabled(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePendingDatasetTimestamp(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeThreadVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func getActiveDatasetRequest(completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getActiveDatasetRequest(with params: MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getPendingDatasetRequest(completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getPendingDatasetRequest(with params: MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveDatasetTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBorderAgentID(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBorderRouterName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInterfaceEnabled(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePendingDatasetTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThreadVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setActiveDatasetRequestWith(_ params: MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func setPendingDatasetRequestWith(_ params: MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveDatasetTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBorderAgentID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBorderRouterName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInterfaceEnabled(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePendingDatasetTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThreadVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterThreadNetworkDirectory: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePreferredExtendedPanID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeThreadNetworkTableSize(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeThreadNetworks(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func addNetwork(with params: MTRThreadNetworkDirectoryClusterAddNetworkParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getOperationalDataset(with params: MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams, completion: @escaping (MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePreferredExtendedPanID(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThreadNetworkTableSize(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThreadNetworks(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func removeNetwork(with params: MTRThreadNetworkDirectoryClusterRemoveNetworkParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePreferredExtendedPanID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThreadNetworkTableSize(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThreadNetworks(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributePreferredExtendedPanID(withValue value: Data?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributePreferredExtendedPanID(withValue value: Data?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterTotalVolatileOrganicCompoundsConcentrationMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAverageMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLevelValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementMedium(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasurementUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValueWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePeakMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUncertainty(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLevelValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementMedium(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValueWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePeakMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUncertainty(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLevelValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementMedium(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValueWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePeakMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUncertainty(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterUnitLocalization: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTemperatureUnit(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTemperatureUnit(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTemperatureUnit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTemperatureUnit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureUnit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureUnit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeTemperatureUnit(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeTemperatureUnit(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeTemperatureUnit(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeTemperatureUnit(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterUserLabel: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLabelList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLabelList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLabelList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLabelList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLabelList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLabelList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeLabelList(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLabelList(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeLabelList(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLabelList(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterWakeOnLAN: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLinkLocalAddress(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMACAddress(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLinkLocalAddress(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMACAddress(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLinkLocalAddress(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMACAddress(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterWaterHeaterManagement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBoostState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeEstimatedHeatRequired(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHeatDemand(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHeaterTypes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTankPercentage(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTankVolume(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func boost(with params: MTRWaterHeaterManagementClusterBoostParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func cancelBoost(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func cancelBoost(with params: MTRWaterHeaterManagementClusterCancelBoostParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBoostState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEstimatedHeatRequired(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHeatDemand(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHeaterTypes(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTankPercentage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTankVolume(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBoostState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEstimatedHeatRequired(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHeatDemand(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHeaterTypes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTankPercentage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTankVolume(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterWaterHeaterMode: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRWaterHeaterModeClusterChangeToModeParams, completion: @escaping (MTRWaterHeaterModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterWiFiNetworkManagement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFeatureMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePassphraseSurrogate(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSSID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func networkPassphraseRequest(completion: @escaping (MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func networkPassphraseRequest(with params: MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams?, completion: @escaping (MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePassphraseSurrogate(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSSID(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePassphraseSurrogate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSSID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterAccountLogin: MTRGenericCluster {
    open func getSetupPIN(with params: MTRAccountLoginClusterGetSetupPINParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRAccountLoginClusterGetSetupPINResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getSetupPIN(with params: MTRAccountLoginClusterGetSetupPINParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRAccountLoginClusterGetSetupPINResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func login(with params: MTRAccountLoginClusterLoginParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func login(with params: MTRAccountLoginClusterLoginParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func logout(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func logout(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func logout(with params: MTRAccountLoginClusterLogoutParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func logout(with params: MTRAccountLoginClusterLogoutParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
}

open class MTRClusterActivatedCarbonFilterMonitoring: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeChangeIndication(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ChangeIndication", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCondition(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Condition", params: params)
    }
    open func readAttributeDegradationDirection(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DegradationDirection", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeInPlaceIndicator(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InPlaceIndicator", params: params)
    }
    open func readAttributeLastChangedTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LastChangedTime", params: params)
    }
    open func readAttributeReplacementProductList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReplacementProductList", params: params)
    }
    open func resetCondition(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(with params: MTRActivatedCarbonFilterMonitoringClusterResetConditionParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLastChangedTime(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LastChangedTime", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLastChangedTime(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LastChangedTime", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterAirQuality: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAirQuality(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AirQuality", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
}

open class MTRClusterAudioOutput: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentOutput(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentOutput", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOutputList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OutputList", params: params)
    }
    open func renameOutput(with params: MTRAudioOutputClusterRenameOutputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func renameOutput(with params: MTRAudioOutputClusterRenameOutputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func select(with params: MTRAudioOutputClusterSelectOutputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func select(with params: MTRAudioOutputClusterSelectOutputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterBallastConfiguration: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBallastFactorAdjustment(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BallastFactorAdjustment", params: params)
    }
    open func readAttributeBallastStatus(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BallastStatus", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeIntrinsicBalanceFactor(with params: MTRReadParams?) -> [String : Any]
    {
        _ = (params)
        return mtrHostRead("IntrinsicBalanceFactor", params: params) ?? [:]
    }
    open func readAttributeIntrinsicBallastFactor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("IntrinsicBallastFactor", params: params)
    }
    open func readAttributeLampAlarmMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampAlarmMode", params: params)
    }
    open func readAttributeLampBurnHoursTripPoint(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampBurnHoursTripPoint", params: params)
    }
    open func readAttributeLampBurnHours(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampBurnHours", params: params)
    }
    open func readAttributeLampManufacturer(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampManufacturer", params: params)
    }
    open func readAttributeLampQuantity(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampQuantity", params: params)
    }
    open func readAttributeLampRatedHours(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampRatedHours", params: params)
    }
    open func readAttributeLampType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LampType", params: params)
    }
    open func readAttributeMaxLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxLevel", params: params)
    }
    open func readAttributeMinLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinLevel", params: params)
    }
    open func readAttributePhysicalMaxLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhysicalMaxLevel", params: params)
    }
    open func readAttributePhysicalMinLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhysicalMinLevel", params: params)
    }
    open func writeAttributeBallastFactorAdjustment(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("BallastFactorAdjustment", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBallastFactorAdjustment(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("BallastFactorAdjustment", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeIntrinsicBalanceFactor(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("IntrinsicBalanceFactor", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeIntrinsicBalanceFactor(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("IntrinsicBalanceFactor", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeIntrinsicBallastFactor(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("IntrinsicBallastFactor", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeIntrinsicBallastFactor(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("IntrinsicBallastFactor", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampAlarmMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampAlarmMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampAlarmMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampAlarmMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampBurnHoursTripPoint(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampBurnHoursTripPoint", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampBurnHoursTripPoint(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampBurnHoursTripPoint", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampBurnHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampBurnHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampBurnHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampBurnHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampManufacturer(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampManufacturer", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampManufacturer(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampManufacturer", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampRatedHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampRatedHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampRatedHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampRatedHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLampType(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LampType", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLampType(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LampType", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeMaxLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("MaxLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeMaxLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("MaxLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeMinLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("MinLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeMinLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("MinLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterBinding: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBinding(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Binding", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func writeAttributeBinding(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("Binding", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBinding(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("Binding", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterBooleanState: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeStateValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("StateValue", params: params)
    }
}

open class MTRClusterBooleanStateConfiguration: MTRGenericCluster {
    open func enableDisableAlarm(with params: MTRBooleanStateConfigurationClusterEnableDisableAlarmParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAlarmsActive(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AlarmsActive", params: params)
    }
    open func readAttributeAlarmsEnabled(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AlarmsEnabled", params: params)
    }
    open func readAttributeAlarmsSupported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AlarmsSupported", params: params)
    }
    open func readAttributeAlarmsSuppressed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AlarmsSuppressed", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentSensitivityLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentSensitivityLevel", params: params)
    }
    open func readAttributeDefaultSensitivityLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DefaultSensitivityLevel", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSensorFault(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SensorFault", params: params)
    }
    open func readAttributeSupportedSensitivityLevels(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedSensitivityLevels", params: params)
    }
    open func suppressAlarm(with params: MTRBooleanStateConfigurationClusterSuppressAlarmParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeCurrentSensitivityLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("CurrentSensitivityLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeCurrentSensitivityLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("CurrentSensitivityLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterCarbonDioxideConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterCarbonMonoxideConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterCommissionerControl: MTRGenericCluster {
    open func commissionNode(with params: MTRCommissionerControlClusterCommissionNodeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRCommissionerControlClusterReverseOpenCommissioningWindowParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedDeviceCategories(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedDeviceCategories", params: params)
    }
    open func requestCommissioningApproval(with params: MTRCommissionerControlClusterRequestCommissioningApprovalParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterContentAppObserver: MTRGenericCluster {
    open func contentAppMessage(with params: MTRContentAppObserverClusterContentAppMessageParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRContentAppObserverClusterContentAppMessageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
}

open class MTRClusterDeviceEnergyManagementMode: MTRGenericCluster {
    open func changeToMode(with params: MTRDeviceEnergyManagementModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterDiagnosticLogs: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func retrieveLogsRequest(with params: MTRDiagnosticLogsClusterRetrieveLogsRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRDiagnosticLogsClusterRetrieveLogsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func retrieveLogsRequest(with params: MTRDiagnosticLogsClusterRetrieveLogsRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRDiagnosticLogsClusterRetrieveLogsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterDishwasherAlarm: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func modifyEnabledAlarms(with params: MTRDishwasherAlarmClusterModifyEnabledAlarmsParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLatch(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Latch", params: params)
    }
    open func readAttributeMask(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Mask", params: params)
    }
    open func readAttributeState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("State", params: params)
    }
    open func readAttributeSupported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Supported", params: params)
    }
    open func reset(with params: MTRDishwasherAlarmClusterResetParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterDishwasherMode: MTRGenericCluster {
    open func changeToMode(with params: MTRDishwasherModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRDishwasherModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterElectricalEnergyMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAccuracy(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Accuracy", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCumulativeEnergyExported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CumulativeEnergyExported", params: params)
    }
    open func readAttributeCumulativeEnergyImported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CumulativeEnergyImported", params: params)
    }
    open func readAttributeCumulativeEnergyReset(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CumulativeEnergyReset", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributePeriodicEnergyExported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeriodicEnergyExported", params: params)
    }
    open func readAttributePeriodicEnergyImported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeriodicEnergyImported", params: params)
    }
}

open class MTRClusterEnergyEVSEMode: MTRGenericCluster {
    open func changeToMode(with params: MTREnergyEVSEModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTREnergyEVSEModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterFixedLabel: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLabelList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LabelList", params: params)
    }
}

open class MTRClusterFormaldehydeConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterHEPAFilterMonitoring: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeChangeIndication(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ChangeIndication", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCondition(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Condition", params: params)
    }
    open func readAttributeDegradationDirection(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DegradationDirection", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeInPlaceIndicator(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InPlaceIndicator", params: params)
    }
    open func readAttributeLastChangedTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LastChangedTime", params: params)
    }
    open func readAttributeReplacementProductList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReplacementProductList", params: params)
    }
    open func resetCondition(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetCondition(with params: MTRHEPAFilterMonitoringClusterResetConditionParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLastChangedTime(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LastChangedTime", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLastChangedTime(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LastChangedTime", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterICDManagement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveModeDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveModeDuration", params: params)
    }
    open func readAttributeActiveModeThreshold(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveModeThreshold", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClientsSupportedPerFabric(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClientsSupportedPerFabric", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeICDCounter(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ICDCounter", params: params)
    }
    open func readAttributeIdleModeDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("IdleModeDuration", params: params)
    }
    open func readAttributeMaximumCheckInBackOff(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaximumCheckInBackOff", params: params)
    }
    open func readAttributeOperatingMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperatingMode", params: params)
    }
    open func readAttributeRegisteredClients(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RegisteredClients", params: params)
    }
    open func readAttributeUserActiveModeTriggerHint(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UserActiveModeTriggerHint", params: params)
    }
    open func readAttributeUserActiveModeTriggerInstruction(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UserActiveModeTriggerInstruction", params: params)
    }
    open func registerClient(with params: MTRICDManagementClusterRegisterClientParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRICDManagementClusterRegisterClientResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stayActiveRequest(with params: MTRICDManagementClusterStayActiveRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRICDManagementClusterStayActiveResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func unregisterClient(with params: MTRICDManagementClusterUnregisterClientParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterKeypadInput: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func sendKey(with params: MTRKeypadInputClusterSendKeyParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRKeypadInputClusterSendKeyResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func sendKey(with params: MTRKeypadInputClusterSendKeyParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRKeypadInputClusterSendKeyResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterLaundryDryerControls: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSelectedDrynessLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SelectedDrynessLevel", params: params)
    }
    open func readAttributeSupportedDrynessLevels(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedDrynessLevels", params: params)
    }
    open func writeAttributeSelectedDrynessLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("SelectedDrynessLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeSelectedDrynessLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("SelectedDrynessLevel", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterLaundryWasherControls: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeNumberOfRinses(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NumberOfRinses", params: params)
    }
    open func readAttributeSpinSpeedCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SpinSpeedCurrent", params: params)
    }
    open func readAttributeSpinSpeeds(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SpinSpeeds", params: params)
    }
    open func readAttributeSupportedRinses(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedRinses", params: params)
    }
    open func writeAttributeNumberOfRinses(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("NumberOfRinses", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNumberOfRinses(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("NumberOfRinses", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeSpinSpeedCurrent(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("SpinSpeedCurrent", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeSpinSpeedCurrent(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("SpinSpeedCurrent", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterLaundryWasherMode: MTRGenericCluster {
    open func changeToMode(with params: MTRLaundryWasherModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRLaundryWasherModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterLocalizationConfiguration: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveLocale(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveLocale", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedLocales(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedLocales", params: params)
    }
    open func writeAttributeActiveLocale(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ActiveLocale", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeActiveLocale(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ActiveLocale", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterLowPower: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func sleep(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func sleep(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func sleep(with params: MTRLowPowerClusterSleepParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func sleep(with params: MTRLowPowerClusterSleepParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterMessages: MTRGenericCluster {
    open func cancelRequest(with params: MTRMessagesClusterCancelMessagesRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func presentRequest(with params: MTRMessagesClusterPresentMessagesRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveMessageIDs(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveMessageIDs", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeMessages(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Messages", params: params)
    }
}

open class MTRClusterMicrowaveOvenControl: MTRGenericCluster {
    open func addMoreTime(with params: MTRMicrowaveOvenControlClusterAddMoreTimeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCookTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CookTime", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeMaxCookTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxCookTime", params: params)
    }
    open func readAttributeMaxPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxPower", params: params)
    }
    open func readAttributeMinPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinPower", params: params)
    }
    open func readAttributePowerSetting(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerSetting", params: params)
    }
    open func readAttributePowerStep(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerStep", params: params)
    }
    open func readAttributeWattRating(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WattRating", params: params)
    }
    open func setCookingParametersWithExpectedValues(_ expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func setCookingParametersWith(_ params: MTRMicrowaveOvenControlClusterSetCookingParametersParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterMicrowaveOvenMode: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterNitrogenDioxideConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterOTASoftwareUpdateProvider: MTRGenericCluster {
    open func applyUpdateRequest(with params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func notifyUpdateApplied(with params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func queryImage(with params: MTROTASoftwareUpdateProviderClusterQueryImageParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROTASoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
}

open class MTRClusterOTASoftwareUpdateRequestor: MTRGenericCluster {
    open func announceOTAProvider(with params: MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeDefaultOTAProviders(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DefaultOTAProviders", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeUpdatePossible(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UpdatePossible", params: params)
    }
    open func readAttributeUpdateStateProgress(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UpdateStateProgress", params: params)
    }
    open func readAttributeUpdateState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UpdateState", params: params)
    }
    open func writeAttributeDefaultOTAProviders(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("DefaultOTAProviders", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeDefaultOTAProviders(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("DefaultOTAProviders", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterOnOffSwitchConfiguration: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSwitchActions(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SwitchActions", params: params)
    }
    open func readAttributeSwitchType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SwitchType", params: params)
    }
    open func writeAttributeSwitchActions(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("SwitchActions", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeSwitchActions(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("SwitchActions", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterOperationalState: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func pause(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func pause(with params: MTROperationalStateClusterPauseParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCountdownTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CountdownTime", params: params)
    }
    open func readAttributeCurrentPhase(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentPhase", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOperationalError(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalError", params: params)
    }
    open func readAttributeOperationalStateList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalStateList", params: params)
    }
    open func readAttributeOperationalState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalState", params: params)
    }
    open func readAttributePhaseList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhaseList", params: params)
    }
    open func resume(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resume(with params: MTROperationalStateClusterResumeParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func start(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func start(with params: MTROperationalStateClusterStartParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stop(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stop(with params: MTROperationalStateClusterStopParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterOvenCavityOperationalState: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCountdownTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CountdownTime", params: params)
    }
    open func readAttributeCurrentPhase(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentPhase", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOperationalError(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalError", params: params)
    }
    open func readAttributeOperationalStateList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalStateList", params: params)
    }
    open func readAttributeOperationalState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalState", params: params)
    }
    open func readAttributePhaseList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhaseList", params: params)
    }
    open func start(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func start(with params: MTROvenCavityOperationalStateClusterStartParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stop(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stop(with params: MTROvenCavityOperationalStateClusterStopParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROvenCavityOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterOvenMode: MTRGenericCluster {
    open func changeToMode(with params: MTROvenModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROvenModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterOzoneConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterPM10ConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterPM1ConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterPM25ConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterPowerSource: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveBatChargeFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveBatChargeFaults", params: params)
    }
    open func readAttributeActiveBatFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveBatFaults", params: params)
    }
    open func readAttributeActiveWiredFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveWiredFaults", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBatANSIDesignation(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatANSIDesignation", params: params)
    }
    open func readAttributeBatApprovedChemistry(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatApprovedChemistry", params: params)
    }
    open func readAttributeBatCapacity(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatCapacity", params: params)
    }
    open func readAttributeBatChargeLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatChargeLevel", params: params)
    }
    open func readAttributeBatChargeState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatChargeState", params: params)
    }
    open func readAttributeBatChargingCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatChargingCurrent", params: params)
    }
    open func readAttributeBatCommonDesignation(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatCommonDesignation", params: params)
    }
    open func readAttributeBatFunctionalWhileCharging(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatFunctionalWhileCharging", params: params)
    }
    open func readAttributeBatIECDesignation(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatIECDesignation", params: params)
    }
    open func readAttributeBatPercentRemaining(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatPercentRemaining", params: params)
    }
    open func readAttributeBatPresent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatPresent", params: params)
    }
    open func readAttributeBatQuantity(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatQuantity", params: params)
    }
    open func readAttributeBatReplaceability(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatReplaceability", params: params)
    }
    open func readAttributeBatReplacementDescription(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatReplacementDescription", params: params)
    }
    open func readAttributeBatReplacementNeeded(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatReplacementNeeded", params: params)
    }
    open func readAttributeBatTimeRemaining(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatTimeRemaining", params: params)
    }
    open func readAttributeBatTimeToFullCharge(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatTimeToFullCharge", params: params)
    }
    open func readAttributeBatVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatVoltage", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeDescription(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Description", params: params)
    }
    open func readAttributeEndpointList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EndpointList", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOrder(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Order", params: params)
    }
    open func readAttributeStatus(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Status", params: params)
    }
    open func readAttributeWiredAssessedCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredAssessedCurrent", params: params)
    }
    open func readAttributeWiredAssessedInputFrequency(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredAssessedInputFrequency", params: params)
    }
    open func readAttributeWiredAssessedInputVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredAssessedInputVoltage", params: params)
    }
    open func readAttributeWiredCurrentType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredCurrentType", params: params)
    }
    open func readAttributeWiredMaximumCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredMaximumCurrent", params: params)
    }
    open func readAttributeWiredNominalVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredNominalVoltage", params: params)
    }
    open func readAttributeWiredPresent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WiredPresent", params: params)
    }
}

open class MTRClusterPowerSourceConfiguration: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSources(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Sources", params: params)
    }
}

open class MTRClusterPowerTopology: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveEndpoints(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveEndpoints", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAvailableEndpoints(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AvailableEndpoints", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
}

open class MTRClusterPumpConfigurationAndControl: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeCapacity(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Capacity", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeControlMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ControlMode", params: params)
    }
    open func readAttributeEffectiveControlMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EffectiveControlMode", params: params)
    }
    open func readAttributeEffectiveOperationMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EffectiveOperationMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLifetimeEnergyConsumed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LifetimeEnergyConsumed", params: params)
    }
    open func readAttributeLifetimeRunningHours(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LifetimeRunningHours", params: params)
    }
    open func readAttributeMaxCompPressure(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxCompPressure", params: params)
    }
    open func readAttributeMaxConstFlow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxConstFlow", params: params)
    }
    open func readAttributeMaxConstPressure(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxConstPressure", params: params)
    }
    open func readAttributeMaxConstSpeed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxConstSpeed", params: params)
    }
    open func readAttributeMaxConstTemp(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxConstTemp", params: params)
    }
    open func readAttributeMaxFlow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxFlow", params: params)
    }
    open func readAttributeMaxPressure(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxPressure", params: params)
    }
    open func readAttributeMaxSpeed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxSpeed", params: params)
    }
    open func readAttributeMinCompPressure(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinCompPressure", params: params)
    }
    open func readAttributeMinConstFlow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinConstFlow", params: params)
    }
    open func readAttributeMinConstPressure(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinConstPressure", params: params)
    }
    open func readAttributeMinConstSpeed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinConstSpeed", params: params)
    }
    open func readAttributeMinConstTemp(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinConstTemp", params: params)
    }
    open func readAttributeOperationMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationMode", params: params)
    }
    open func readAttributePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Power", params: params)
    }
    open func readAttributePumpStatus(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PumpStatus", params: params)
    }
    open func readAttributeSpeed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Speed", params: params)
    }
    open func writeAttributeControlMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ControlMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeControlMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ControlMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLifetimeEnergyConsumed(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LifetimeEnergyConsumed", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLifetimeEnergyConsumed(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LifetimeEnergyConsumed", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLifetimeRunningHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LifetimeRunningHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLifetimeRunningHours(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LifetimeRunningHours", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeOperationMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("OperationMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeOperationMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("OperationMode", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterRVCCleanMode: MTRGenericCluster {
    open func changeToMode(with params: MTRRVCCleanModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCCleanModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterRVCOperationalState: MTRGenericCluster {
    open func goHome(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func goHome(with params: MTRRVCOperationalStateClusterGoHomeParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func pause(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func pause(with params: MTRRVCOperationalStateClusterPauseParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCountdownTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CountdownTime", params: params)
    }
    open func readAttributeCurrentPhase(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentPhase", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOperationalError(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalError", params: params)
    }
    open func readAttributeOperationalStateList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalStateList", params: params)
    }
    open func readAttributeOperationalState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OperationalState", params: params)
    }
    open func readAttributePhaseList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhaseList", params: params)
    }
    open func resume(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resume(with params: MTRRVCOperationalStateClusterResumeParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCOperationalStateClusterOperationalCommandResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterRVCRunMode: MTRGenericCluster {
    open func changeToMode(with params: MTRRVCRunModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRVCRunModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterRadonConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterRefrigeratorAlarm: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeMask(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Mask", params: params)
    }
    open func readAttributeState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("State", params: params)
    }
    open func readAttributeSupported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Supported", params: params)
    }
}

open class MTRClusterRefrigeratorAndTemperatureControlledCabinetMode: MTRGenericCluster {
    open func changeToMode(with params: MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterServiceArea: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentArea(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentArea", params: params)
    }
    open func readAttributeEstimatedEndTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EstimatedEndTime", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeProgress(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Progress", params: params)
    }
    open func readAttributeSelectedAreas(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SelectedAreas", params: params)
    }
    open func readAttributeSupportedAreas(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedAreas", params: params)
    }
    open func readAttributeSupportedMaps(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedMaps", params: params)
    }
    open func selectAreas(with params: MTRServiceAreaClusterSelectAreasParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRServiceAreaClusterSelectAreasResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRServiceAreaClusterSkipAreaParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRServiceAreaClusterSkipAreaResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterTargetNavigator: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func navigateTarget(with params: MTRTargetNavigatorClusterNavigateTargetParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRTargetNavigatorClusterNavigateTargetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func navigateTarget(with params: MTRTargetNavigatorClusterNavigateTargetParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTargetNavigatorClusterNavigateTargetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentTarget(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentTarget", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeTargetList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TargetList", params: params)
    }
}

open class MTRClusterTemperatureControl: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeMaxTemperature(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxTemperature", params: params)
    }
    open func readAttributeMinTemperature(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinTemperature", params: params)
    }
    open func readAttributeSelectedTemperatureLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SelectedTemperatureLevel", params: params)
    }
    open func readAttributeStep(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Step", params: params)
    }
    open func readAttributeSupportedTemperatureLevels(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedTemperatureLevels", params: params)
    }
    open func readAttributeTemperatureSetpoint(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TemperatureSetpoint", params: params)
    }
    open func setTemperatureWithExpectedValues(_ expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func setTemperatureWith(_ params: MTRTemperatureControlClusterSetTemperatureParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterThreadBorderRouterManagement: MTRGenericCluster {
    open func getActiveDatasetRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getActiveDatasetRequest(with params: MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getPendingDatasetRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getPendingDatasetRequest(with params: MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRThreadBorderRouterManagementClusterDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveDatasetTimestamp(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveDatasetTimestamp", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBorderAgentID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BorderAgentID", params: params)
    }
    open func readAttributeBorderRouterName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BorderRouterName", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeInterfaceEnabled(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InterfaceEnabled", params: params)
    }
    open func readAttributePendingDatasetTimestamp(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PendingDatasetTimestamp", params: params)
    }
    open func readAttributeThreadVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ThreadVersion", params: params)
    }
    open func setActiveDatasetRequestWith(_ params: MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func setPendingDatasetRequestWith(_ params: MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterThreadNetworkDirectory: MTRGenericCluster {
    open func addNetwork(with params: MTRThreadNetworkDirectoryClusterAddNetworkParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getOperationalDataset(with params: MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributePreferredExtendedPanID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PreferredExtendedPanID", params: params)
    }
    open func readAttributeThreadNetworkTableSize(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ThreadNetworkTableSize", params: params)
    }
    open func readAttributeThreadNetworks(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ThreadNetworks", params: params)
    }
    open func removeNetwork(with params: MTRThreadNetworkDirectoryClusterRemoveNetworkParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributePreferredExtendedPanID(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("PreferredExtendedPanID", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributePreferredExtendedPanID(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("PreferredExtendedPanID", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterTotalVolatileOrganicCompoundsConcentrationMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValueWindow", params: params)
    }
    open func readAttributeAverageMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageMeasuredValue", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLevelValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelValue", params: params)
    }
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMeasurementMedium(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementMedium", params: params)
    }
    open func readAttributeMeasurementUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementUnit", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributePeakMeasuredValueWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValueWindow", params: params)
    }
    open func readAttributePeakMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PeakMeasuredValue", params: params)
    }
    open func readAttributeUncertainty(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Uncertainty", params: params)
    }
}

open class MTRClusterUnitLocalization: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeTemperatureUnit(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TemperatureUnit", params: params)
    }
    open func writeAttributeTemperatureUnit(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("TemperatureUnit", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeTemperatureUnit(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("TemperatureUnit", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterUserLabel: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLabelList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LabelList", params: params)
    }
    open func writeAttributeLabelList(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LabelList", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLabelList(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LabelList", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRClusterWakeOnLAN: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeLinkLocalAddress(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LinkLocalAddress", params: params)
    }
    open func readAttributeMACAddress(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MACAddress", params: params)
    }
}

open class MTRClusterWaterHeaterManagement: MTRGenericCluster {
    open func boost(with params: MTRWaterHeaterManagementClusterBoostParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func cancelBoost(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func cancelBoost(with params: MTRWaterHeaterManagementClusterCancelBoostParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBoostState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BoostState", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeEstimatedHeatRequired(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EstimatedHeatRequired", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeHeatDemand(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HeatDemand", params: params)
    }
    open func readAttributeHeaterTypes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HeaterTypes", params: params)
    }
    open func readAttributeTankPercentage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TankPercentage", params: params)
    }
    open func readAttributeTankVolume(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TankVolume", params: params)
    }
}

open class MTRClusterWaterHeaterMode: MTRGenericCluster {
    open func changeToMode(with params: MTRWaterHeaterModeClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRWaterHeaterModeClusterChangeToModeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentMode", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
}

open class MTRClusterWiFiNetworkManagement: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func networkPassphraseRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func networkPassphraseRequest(with params: MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributePassphraseSurrogate(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PassphraseSurrogate", params: params)
    }
    open func readAttributeSSID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SSID", params: params)
    }
}

open class MTRBaseClusterOtaSoftwareUpdateProvider: MTRBaseClusterOTASoftwareUpdateProvider {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open func applyUpdateRequest(with params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams, completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func notifyUpdateApplied(with params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func queryImage(with params: MTROtaSoftwareUpdateProviderClusterQueryImageParams, completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    public override init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRBaseClusterOtaSoftwareUpdateRequestor: MTRBaseClusterOTASoftwareUpdateRequestor {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeDefaultOtaProviders(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUpdatePossible(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUpdateStateProgress(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUpdateState(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open func announceOtaProvider(with params: MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDefaultOtaProviders(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUpdatePossible(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUpdateStateProgress(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUpdateState(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultOtaProviders(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdatePossible(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdateStateProgress(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpdateState(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeDefaultOtaProviders(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeDefaultOtaProviders(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public override init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRBaseClusterWakeOnLan: MTRBaseClusterWakeOnLAN {
    open class func readAttributeAcceptedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAttributeList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFeatureMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGeneratedCommandList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMACAddress(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMACAddress(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMACAddress(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    public override init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRClusterOtaSoftwareUpdateProvider: MTRClusterOTASoftwareUpdateProvider {
    open func applyUpdateRequest(with params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func notifyUpdateApplied(with params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func queryImage(with params: MTROtaSoftwareUpdateProviderClusterQueryImageParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public override init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRClusterOtaSoftwareUpdateRequestor: MTRClusterOTASoftwareUpdateRequestor {
    open func announceOtaProvider(with params: MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func readAttributeDefaultOtaProviders(with params: MTRReadParams?) -> [String : Any]
    {
        _ = (params)
        return mtrHostRead("DefaultOtaProviders", params: params) ?? [:]
    }
    open func writeAttributeDefaultOtaProviders(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("DefaultOtaProviders", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeDefaultOtaProviders(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("DefaultOtaProviders", value: expectedValueIntervalMs, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    public override init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRClusterWakeOnLan: MTRClusterWakeOnLAN {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public override init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}

open class MTRClusterTestCluster: MTRClusterUnitTesting {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func simpleStructEchoRequest(with params: MTRTestClusterClusterSimpleStructEchoRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterSimpleStructResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testAddArguments(with params: MTRTestClusterClusterTestAddArgumentsParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestAddArgumentsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testComplexNullableOptionalRequest(with params: MTRTestClusterClusterTestComplexNullableOptionalRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestComplexNullableOptionalResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testEmitTestEventRequest(with params: MTRTestClusterClusterTestEmitTestEventRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestEmitTestEventResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testEmitTestFabricScopedEventRequest(with params: MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testEnumsRequest(with params: MTRTestClusterClusterTestEnumsRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestEnumsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testListInt8UArgumentRequest(with params: MTRTestClusterClusterTestListInt8UArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testListInt8UReverseRequest(with params: MTRTestClusterClusterTestListInt8UReverseRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestListInt8UReverseResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testListNestedStructListArgumentRequest(with params: MTRTestClusterClusterTestListNestedStructListArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testListStructArgumentRequest(with params: MTRTestClusterClusterTestListStructArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNestedStructArgumentRequest(with params: MTRTestClusterClusterTestNestedStructArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNestedStructListArgumentRequest(with params: MTRTestClusterClusterTestNestedStructListArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNotHandled(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNotHandled(with params: MTRTestClusterClusterTestNotHandledParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNullableOptionalRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestNullableOptionalResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNullableOptionalRequest(with params: MTRTestClusterClusterTestNullableOptionalRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestNullableOptionalResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSimpleArgumentRequest(with params: MTRTestClusterClusterTestSimpleArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestSimpleArgumentResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSimpleOptionalArgumentRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSimpleOptionalArgumentRequest(with params: MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSpecific(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestSpecificResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSpecific(with params: MTRTestClusterClusterTestSpecificParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestSpecificResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testStructArgumentRequest(with params: MTRTestClusterClusterTestStructArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterBooleanResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testStructArrayArgumentRequest(with params: MTRTestClusterClusterTestStructArrayArgumentRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRTestClusterClusterTestStructArrayArgumentResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testUnknownCommand(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testUnknownCommand(with params: MTRTestClusterClusterTestUnknownCommandParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func test(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func test(with params: MTRTestClusterClusterTestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func timedInvokeRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func timedInvokeRequest(with params: MTRTestClusterClusterTimedInvokeRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public override init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init(device: device, endpointID: endpointID, queue: queue)
    }
}
