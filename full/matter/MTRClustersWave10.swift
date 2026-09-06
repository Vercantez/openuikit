import Foundation
import Dispatch

// Wave-10 fail-closed cluster I/O and in-memory MTRCluster* cache.
// Completion-handler spellings of ObjC selectors (including those whose
// canonical surface row is the Swift async overlay) run synchronously
// and return MTRError.invalidState. There is no Matter radio.

open class MTRBaseClusterAccessControl: MTRGenericBaseCluster {
    open class func readAttributeACL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeARL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
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
    open class func readAttributeAccessControlEntriesPerFabric(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAccessControlEntriesPerFabric(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAcl(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
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
    open class func readAttributeCommissioningARL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeExtension(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeExtension(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeSubjectsPerAccessControlEntry(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSubjectsPerAccessControlEntry(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTargetsPerAccessControlEntry(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTargetsPerAccessControlEntry(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeACL(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeARL(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
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
    open func readAttributeAccessControlEntriesPerFabric(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAccessControlEntriesPerFabric(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcl(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
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
    open func readAttributeCommissioningARL(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExtension(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExtension(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
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
    open func readAttributeSubjectsPerAccessControlEntry(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSubjectsPerAccessControlEntry(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTargetsPerAccessControlEntry(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetsPerAccessControlEntry(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func reviewFabricRestrictions(with params: MTRAccessControlClusterReviewFabricRestrictionsParams, completion: @escaping (MTRAccessControlClusterReviewFabricRestrictionsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeACL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeARL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
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
    open func subscribeAttributeAccessControlEntriesPerFabric(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAccessControlEntriesPerFabric(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcl(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
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
    open func subscribeAttributeCommissioningARL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExtension(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExtension(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeSubjectsPerAccessControlEntry(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSubjectsPerAccessControlEntry(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetsPerAccessControlEntry(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetsPerAccessControlEntry(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeACL(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeACL(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeAcl(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeAcl(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeExtension(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeExtension(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeExtension(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeExtension(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterAccessControl: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeACL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ACL", params: params)
    }
    open func readAttributeARL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ARL", params: params)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAccessControlEntriesPerFabric(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AccessControlEntriesPerFabric", params: params)
    }
    open func readAttributeAcl(with params: MTRReadParams?) -> [String : Any]
    {
        _ = (params)
        return mtrHostRead("Acl", params: params) ?? [:]
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
    open func readAttributeCommissioningARL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CommissioningARL", params: params)
    }
    open func readAttributeExtension(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Extension", params: params)
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
    open func readAttributeSubjectsPerAccessControlEntry(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SubjectsPerAccessControlEntry", params: params)
    }
    open func readAttributeTargetsPerAccessControlEntry(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TargetsPerAccessControlEntry", params: params)
    }
    open func reviewFabricRestrictions(with params: MTRAccessControlClusterReviewFabricRestrictionsParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRAccessControlClusterReviewFabricRestrictionsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeACL(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ACL", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeACL(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ACL", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeAcl(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("Acl", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeAcl(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("Acl", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeExtension(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("Extension", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeExtension(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("Extension", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterActions: MTRGenericBaseCluster {
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
    open class func readAttributeActionList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActionList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeEndpointLists(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeEndpointLists(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeSetupURL(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSetupURL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func disableActionWithDuration(with params: MTRActionsClusterDisableActionWithDurationParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func disableActionWithDuration(with params: MTRActionsClusterDisableActionWithDurationParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func disableAction(with params: MTRActionsClusterDisableActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func disableAction(with params: MTRActionsClusterDisableActionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func enableActionWithDuration(with params: MTRActionsClusterEnableActionWithDurationParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func enableActionWithDuration(with params: MTRActionsClusterEnableActionWithDurationParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func enableAction(with params: MTRActionsClusterEnableActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func enableAction(with params: MTRActionsClusterEnableActionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func instantAction(with params: MTRActionsClusterInstantActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func instantAction(with params: MTRActionsClusterInstantActionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func instantActionWithTransition(with params: MTRActionsClusterInstantActionWithTransitionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func instantActionWithTransition(with params: MTRActionsClusterInstantActionWithTransitionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func pauseActionWithDuration(with params: MTRActionsClusterPauseActionWithDurationParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func pauseActionWithDuration(with params: MTRActionsClusterPauseActionWithDurationParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func pauseAction(with params: MTRActionsClusterPauseActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func pauseAction(with params: MTRActionsClusterPauseActionParams, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func readAttributeActionList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActionList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeEndpointLists(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEndpointLists(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeSetupURL(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSetupURL(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resumeAction(with params: MTRActionsClusterResumeActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func resumeAction(with params: MTRActionsClusterResumeActionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func startActionWithDuration(with params: MTRActionsClusterStartActionWithDurationParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func startActionWithDuration(with params: MTRActionsClusterStartActionWithDurationParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func startAction(with params: MTRActionsClusterStartActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func startAction(with params: MTRActionsClusterStartActionParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func stopAction(with params: MTRActionsClusterStopActionParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func stopAction(with params: MTRActionsClusterStopActionParams, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeActionList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActionList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeEndpointLists(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEndpointLists(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeSetupURL(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetupURL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterActions: MTRGenericCluster {
    open func disableActionWithDuration(with params: MTRActionsClusterDisableActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func disableActionWithDuration(with params: MTRActionsClusterDisableActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func disableAction(with params: MTRActionsClusterDisableActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func disableAction(with params: MTRActionsClusterDisableActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func enableActionWithDuration(with params: MTRActionsClusterEnableActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func enableActionWithDuration(with params: MTRActionsClusterEnableActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func enableAction(with params: MTRActionsClusterEnableActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func enableAction(with params: MTRActionsClusterEnableActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func instantAction(with params: MTRActionsClusterInstantActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func instantAction(with params: MTRActionsClusterInstantActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func instantActionWithTransition(with params: MTRActionsClusterInstantActionWithTransitionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func instantActionWithTransition(with params: MTRActionsClusterInstantActionWithTransitionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func pauseActionWithDuration(with params: MTRActionsClusterPauseActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func pauseActionWithDuration(with params: MTRActionsClusterPauseActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func pauseAction(with params: MTRActionsClusterPauseActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func pauseAction(with params: MTRActionsClusterPauseActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActionList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActionList", params: params)
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
    open func readAttributeEndpointLists(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EndpointLists", params: params)
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
    open func readAttributeSetupURL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SetupURL", params: params)
    }
    open func resumeAction(with params: MTRActionsClusterResumeActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resumeAction(with params: MTRActionsClusterResumeActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func startActionWithDuration(with params: MTRActionsClusterStartActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func startActionWithDuration(with params: MTRActionsClusterStartActionWithDurationParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func startAction(with params: MTRActionsClusterStartActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func startAction(with params: MTRActionsClusterStartActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func stopAction(with params: MTRActionsClusterStopActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stopAction(with params: MTRActionsClusterStopActionParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterApplicationBasic: MTRGenericBaseCluster {
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
    open class func readAttributeAllowedVendorList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAllowedVendorList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApplicationName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeApplicationName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApplicationVersion(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeApplicationVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApplication(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRApplicationBasicClusterApplicationBasicApplication?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeApplication(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRApplicationBasicClusterApplicationStruct?, (any Error)?) -> Void)
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
    open class func readAttributeProductID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeStatus(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeStatus(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeAllowedVendorList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAllowedVendorList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApplicationName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApplicationName(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApplicationVersion(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApplicationVersion(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApplication(completion: @escaping (MTRApplicationBasicClusterApplicationStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApplication(completionHandler: @escaping (MTRApplicationBasicClusterApplicationBasicApplication?, (any Error)?) -> Void)
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
    open func readAttributeProductID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductID(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorID(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorName(completionHandler: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeAllowedVendorList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAllowedVendorList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplicationName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplicationName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplicationVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplicationVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplication(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRApplicationBasicClusterApplicationBasicApplication?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApplication(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRApplicationBasicClusterApplicationStruct?, (any Error)?) -> Void)
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
    open func subscribeAttributeProductID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterApplicationBasic: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAllowedVendorList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AllowedVendorList", params: params)
    }
    open func readAttributeApplicationName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApplicationName", params: params)
    }
    open func readAttributeApplicationVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApplicationVersion", params: params)
    }
    open func readAttributeApplication(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Application", params: params)
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
    open func readAttributeProductID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductID", params: params)
    }
    open func readAttributeStatus(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Status", params: params)
    }
    open func readAttributeVendorID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorID", params: params)
    }
    open func readAttributeVendorName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorName", params: params)
    }
}

open class MTRBaseClusterBasicInformation: MTRGenericBaseCluster {
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
    open class func readAttributeCapabilityMinima(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRBasicInformationClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDataModelRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeHardwareVersionString(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHardwareVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLocalConfigDisabled(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeLocation(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeManufacturingDate(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxPathsPerInvoke(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNodeLabel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePartNumber(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductAppearance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductLabel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductURL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReachable(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSerialNumber(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSoftwareVersionString(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSoftwareVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSpecificationVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUniqueID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCapabilityMinima(completion: @escaping (MTRBasicInformationClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDataModelRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeHardwareVersionString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHardwareVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocalConfigDisabled(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocation(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeManufacturingDate(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxPathsPerInvoke(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNodeLabel(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePartNumber(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductAppearance(completion: @escaping (MTRBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductLabel(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductURL(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReachable(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSerialNumber(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSoftwareVersionString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSoftwareVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSpecificationVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUniqueID(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorName(completion: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeCapabilityMinima(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRBasicInformationClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDataModelRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeHardwareVersionString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHardwareVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalConfigDisabled(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeManufacturingDate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPathsPerInvoke(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNodeLabel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartNumber(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductAppearance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductLabel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductURL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReachable(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSerialNumber(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersionString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSpecificationVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUniqueID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeLocalConfigDisabled(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLocalConfigDisabled(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLocation(withValue value: String, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeLocation(withValue value: String, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeNodeLabel(withValue value: String, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeNodeLabel(withValue value: String, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterBasicInformation: MTRGenericCluster {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCapabilityMinima(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CapabilityMinima", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeDataModelRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DataModelRevision", params: params)
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
    open func readAttributeHardwareVersionString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HardwareVersionString", params: params)
    }
    open func readAttributeHardwareVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HardwareVersion", params: params)
    }
    open func readAttributeLocalConfigDisabled(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LocalConfigDisabled", params: params)
    }
    open func readAttributeLocation(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Location", params: params)
    }
    open func readAttributeManufacturingDate(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ManufacturingDate", params: params)
    }
    open func readAttributeMaxPathsPerInvoke(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxPathsPerInvoke", params: params)
    }
    open func readAttributeNodeLabel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NodeLabel", params: params)
    }
    open func readAttributePartNumber(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PartNumber", params: params)
    }
    open func readAttributeProductAppearance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductAppearance", params: params)
    }
    open func readAttributeProductID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductID", params: params)
    }
    open func readAttributeProductLabel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductLabel", params: params)
    }
    open func readAttributeProductName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductName", params: params)
    }
    open func readAttributeProductURL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductURL", params: params)
    }
    open func readAttributeReachable(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Reachable", params: params)
    }
    open func readAttributeSerialNumber(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SerialNumber", params: params)
    }
    open func readAttributeSoftwareVersionString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SoftwareVersionString", params: params)
    }
    open func readAttributeSoftwareVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SoftwareVersion", params: params)
    }
    open func readAttributeSpecificationVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SpecificationVersion", params: params)
    }
    open func readAttributeUniqueID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UniqueID", params: params)
    }
    open func readAttributeVendorID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorID", params: params)
    }
    open func readAttributeVendorName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorName", params: params)
    }
    open func writeAttributeLocalConfigDisabled(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("LocalConfigDisabled", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLocalConfigDisabled(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("LocalConfigDisabled", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLocation(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("Location", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLocation(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("Location", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNodeLabel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("NodeLabel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNodeLabel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("NodeLabel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterBridgedDeviceBasicInformation: MTRGenericBaseCluster {
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
    open class func readAttributeHardwareVersionString(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHardwareVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeManufacturingDate(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNodeLabel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePartNumber(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductAppearance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductLabel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeProductURL(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReachable(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSerialNumber(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSoftwareVersionString(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSoftwareVersion(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUniqueID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVendorName(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func keepActive(with params: MTRBridgedDeviceBasicInformationClusterKeepActiveParams, completion: @escaping ((any Error)?) -> Void)
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
    open func readAttributeHardwareVersionString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHardwareVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeManufacturingDate(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNodeLabel(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePartNumber(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductAppearance(completion: @escaping (MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductLabel(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeProductURL(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReachable(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSerialNumber(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSoftwareVersionString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSoftwareVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUniqueID(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorName(completion: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeHardwareVersionString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHardwareVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeManufacturingDate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNodeLabel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartNumber(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductAppearance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductLabel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductURL(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReachable(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSerialNumber(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersionString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUniqueID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeNodeLabel(withValue value: String, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeNodeLabel(withValue value: String, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterBridgedDeviceBasicInformation: MTRGenericCluster {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func keepActive(with params: MTRBridgedDeviceBasicInformationClusterKeepActiveParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
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
    open func readAttributeHardwareVersionString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HardwareVersionString", params: params)
    }
    open func readAttributeHardwareVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HardwareVersion", params: params)
    }
    open func readAttributeManufacturingDate(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ManufacturingDate", params: params)
    }
    open func readAttributeNodeLabel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NodeLabel", params: params)
    }
    open func readAttributePartNumber(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PartNumber", params: params)
    }
    open func readAttributeProductAppearance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductAppearance", params: params)
    }
    open func readAttributeProductID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductID", params: params)
    }
    open func readAttributeProductLabel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductLabel", params: params)
    }
    open func readAttributeProductName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductName", params: params)
    }
    open func readAttributeProductURL(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ProductURL", params: params)
    }
    open func readAttributeReachable(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Reachable", params: params)
    }
    open func readAttributeSerialNumber(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SerialNumber", params: params)
    }
    open func readAttributeSoftwareVersionString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SoftwareVersionString", params: params)
    }
    open func readAttributeSoftwareVersion(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SoftwareVersion", params: params)
    }
    open func readAttributeUniqueID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UniqueID", params: params)
    }
    open func readAttributeVendorID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorID", params: params)
    }
    open func readAttributeVendorName(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorName", params: params)
    }
    open func writeAttributeNodeLabel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("NodeLabel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNodeLabel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("NodeLabel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterElectricalPowerMeasurement: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAccuracy(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActivePower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApparentCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApparentPower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeFrequency(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGeneratedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHarmonicCurrents(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeHarmonicPhases(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNeutralCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNumberOfMeasurementTypes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePowerFactor(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePowerMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRMSCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRMSPower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRMSVoltage(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRanges(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReactiveCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeReactivePower(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeVoltage(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAccuracy(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApparentCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApparentPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHarmonicCurrents(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHarmonicPhases(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNeutralCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfMeasurementTypes(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerFactor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRMSCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRMSPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRMSVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRanges(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactiveCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAccuracy(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHarmonicCurrents(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHarmonicPhases(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNeutralCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfMeasurementTypes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRMSCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRMSPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRMSVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRanges(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactiveCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterElectricalPowerMeasurement: MTRGenericCluster {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeActiveCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveCurrent", params: params)
    }
    open func readAttributeActivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePower", params: params)
    }
    open func readAttributeApparentCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApparentCurrent", params: params)
    }
    open func readAttributeApparentPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApparentPower", params: params)
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
    open func readAttributeFrequency(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Frequency", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeHarmonicCurrents(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HarmonicCurrents", params: params)
    }
    open func readAttributeHarmonicPhases(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HarmonicPhases", params: params)
    }
    open func readAttributeNeutralCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NeutralCurrent", params: params)
    }
    open func readAttributeNumberOfMeasurementTypes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NumberOfMeasurementTypes", params: params)
    }
    open func readAttributePowerFactor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerFactor", params: params)
    }
    open func readAttributePowerMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerMode", params: params)
    }
    open func readAttributeRMSCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RMSCurrent", params: params)
    }
    open func readAttributeRMSPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RMSPower", params: params)
    }
    open func readAttributeRMSVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RMSVoltage", params: params)
    }
    open func readAttributeRanges(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Ranges", params: params)
    }
    open func readAttributeReactiveCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactiveCurrent", params: params)
    }
    open func readAttributeReactivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactivePower", params: params)
    }
    open func readAttributeVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Voltage", params: params)
    }
}

open class MTRBaseClusterEnergyEVSE: MTRGenericBaseCluster {
    open class func readAttributeAcceptedCommandList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeApproximateEVEfficiency(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAttributeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeChargingEnabledUntil(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCircuitCapacity(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFaultState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeMaximumChargeCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinimumChargeCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNextChargeRequiredEnergy(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNextChargeStartTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNextChargeTargetSoC(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeNextChargeTargetTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRandomizationDelayWindow(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSessionDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSessionEnergyCharged(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSessionID(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupplyState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUserMaximumChargeCurrent(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func clearTargets(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func clearTargets(with params: MTREnergyEVSEClusterClearTargetsParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func disable(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func disable(with params: MTREnergyEVSEClusterDisableParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func enableCharging(with params: MTREnergyEVSEClusterEnableChargingParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getTargetsWithCompletion(_ completion: @escaping (MTREnergyEVSEClusterGetTargetsResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getTargetsWith(_ params: MTREnergyEVSEClusterGetTargetsParams?, completion: @escaping (MTREnergyEVSEClusterGetTargetsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApproximateEVEfficiency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChargingEnabledUntil(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCircuitCapacity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFaultState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeMaximumChargeCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinimumChargeCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNextChargeRequiredEnergy(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNextChargeStartTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNextChargeTargetSoC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNextChargeTargetTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRandomizationDelayWindow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSessionDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSessionEnergyCharged(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSessionID(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupplyState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUserMaximumChargeCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func setTargetsWith(_ params: MTREnergyEVSEClusterSetTargetsParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func startDiagnostics(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func startDiagnostics(with params: MTREnergyEVSEClusterStartDiagnosticsParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApproximateEVEfficiency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChargingEnabledUntil(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCircuitCapacity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFaultState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeMaximumChargeCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinimumChargeCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNextChargeRequiredEnergy(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNextChargeStartTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNextChargeTargetSoC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNextChargeTargetTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRandomizationDelayWindow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSessionDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSessionEnergyCharged(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSessionID(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupplyState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUserMaximumChargeCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeApproximateEVEfficiency(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeApproximateEVEfficiency(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeRandomizationDelayWindow(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeRandomizationDelayWindow(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeUserMaximumChargeCurrent(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeUserMaximumChargeCurrent(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterEnergyEVSE: MTRGenericCluster {
    open func clearTargets(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func clearTargets(with params: MTREnergyEVSEClusterClearTargetsParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func disable(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func disable(with params: MTREnergyEVSEClusterDisableParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func enableCharging(with params: MTREnergyEVSEClusterEnableChargingParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getTargetsWithExpectedValues(_ expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTREnergyEVSEClusterGetTargetsResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getTargetsWith(_ params: MTREnergyEVSEClusterGetTargetsParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTREnergyEVSEClusterGetTargetsResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeApproximateEVEfficiency(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApproximateEVEfficiency", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeChargingEnabledUntil(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ChargingEnabledUntil", params: params)
    }
    open func readAttributeCircuitCapacity(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CircuitCapacity", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeFaultState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FaultState", params: params)
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
    open func readAttributeMaximumChargeCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaximumChargeCurrent", params: params)
    }
    open func readAttributeMinimumChargeCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinimumChargeCurrent", params: params)
    }
    open func readAttributeNextChargeRequiredEnergy(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NextChargeRequiredEnergy", params: params)
    }
    open func readAttributeNextChargeStartTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NextChargeStartTime", params: params)
    }
    open func readAttributeNextChargeTargetSoC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NextChargeTargetSoC", params: params)
    }
    open func readAttributeNextChargeTargetTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NextChargeTargetTime", params: params)
    }
    open func readAttributeRandomizationDelayWindow(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RandomizationDelayWindow", params: params)
    }
    open func readAttributeSessionDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SessionDuration", params: params)
    }
    open func readAttributeSessionEnergyCharged(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SessionEnergyCharged", params: params)
    }
    open func readAttributeSessionID(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SessionID", params: params)
    }
    open func readAttributeState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("State", params: params)
    }
    open func readAttributeSupplyState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupplyState", params: params)
    }
    open func readAttributeUserMaximumChargeCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UserMaximumChargeCurrent", params: params)
    }
    open func setTargetsWith(_ params: MTREnergyEVSEClusterSetTargetsParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func startDiagnostics(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func startDiagnostics(with params: MTREnergyEVSEClusterStartDiagnosticsParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeApproximateEVEfficiency(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ApproximateEVEfficiency", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeApproximateEVEfficiency(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ApproximateEVEfficiency", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRandomizationDelayWindow(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("RandomizationDelayWindow", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRandomizationDelayWindow(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("RandomizationDelayWindow", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeUserMaximumChargeCurrent(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("UserMaximumChargeCurrent", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeUserMaximumChargeCurrent(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("UserMaximumChargeCurrent", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterEthernetNetworkDiagnostics: MTRGenericBaseCluster {
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
    open class func readAttributeCarrierDetect(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCarrierDetect(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeCollisionCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCollisionCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeFullDuplex(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFullDuplex(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeOverrunCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeOverrunCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePHYRate(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePHYRate(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePacketRxCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePacketRxCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributePacketTxCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePacketTxCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTimeSinceReset(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTimeSinceReset(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTxErrCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTxErrCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCarrierDetect(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCarrierDetect(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeCollisionCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCollisionCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeFullDuplex(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFullDuplex(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeOverrunCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOverrunCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePHYRate(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePHYRate(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePacketRxCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePacketRxCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePacketTxCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePacketTxCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTimeSinceReset(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTimeSinceReset(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxErrCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxErrCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetCounts(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCounts(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetCounts(with params: MTREthernetNetworkDiagnosticsClusterResetCountsParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func resetCounts(with params: MTREthernetNetworkDiagnosticsClusterResetCountsParams?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeCarrierDetect(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCarrierDetect(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeCollisionCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCollisionCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeFullDuplex(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFullDuplex(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeOverrunCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOverrunCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePHYRate(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePHYRate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePacketRxCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePacketRxCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePacketTxCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePacketTxCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTimeSinceReset(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTimeSinceReset(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterEthernetNetworkDiagnostics: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCarrierDetect(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CarrierDetect", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCollisionCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CollisionCount", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeFullDuplex(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FullDuplex", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeOverrunCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OverrunCount", params: params)
    }
    open func readAttributePHYRate(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PHYRate", params: params)
    }
    open func readAttributePacketRxCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PacketRxCount", params: params)
    }
    open func readAttributePacketTxCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PacketTxCount", params: params)
    }
    open func readAttributeTimeSinceReset(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TimeSinceReset", params: params)
    }
    open func readAttributeTxErrCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TxErrCount", params: params)
    }
    open func resetCounts(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetCounts(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetCounts(with params: MTREthernetNetworkDiagnosticsClusterResetCountsParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetCounts(with params: MTREthernetNetworkDiagnosticsClusterResetCountsParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterGeneralCommissioning: MTRGenericBaseCluster {
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
    open class func readAttributeBasicCommissioningInfo(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeBasicCommissioningInfo(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBreadcrumb(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeBreadcrumb(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeLocationCapability(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLocationCapability(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRegulatoryConfig(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeRegulatoryConfig(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportsConcurrentConnection(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSupportsConcurrentConnection(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func armFailSafe(with params: MTRGeneralCommissioningClusterArmFailSafeParams, completion: @escaping (MTRGeneralCommissioningClusterArmFailSafeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func armFailSafe(with params: MTRGeneralCommissioningClusterArmFailSafeParams, completionHandler: @escaping (MTRGeneralCommissioningClusterArmFailSafeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func commissioningComplete(completion: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func commissioningComplete(completionHandler: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func commissioningComplete(with params: MTRGeneralCommissioningClusterCommissioningCompleteParams?, completion: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func commissioningComplete(with params: MTRGeneralCommissioningClusterCommissioningCompleteParams?, completionHandler: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeBasicCommissioningInfo(completion: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBasicCommissioningInfo(completionHandler: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBreadcrumb(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBreadcrumb(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeLocationCapability(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocationCapability(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRegulatoryConfig(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRegulatoryConfig(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportsConcurrentConnection(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportsConcurrentConnection(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func setRegulatoryConfigWith(_ params: MTRGeneralCommissioningClusterSetRegulatoryConfigParams, completion: @escaping (MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func setRegulatoryConfigWith(_ params: MTRGeneralCommissioningClusterSetRegulatoryConfigParams, completionHandler: @escaping (MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams?, (any Error)?) -> Void)
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
    open func subscribeAttributeBasicCommissioningInfo(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBasicCommissioningInfo(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRGeneralCommissioningClusterBasicCommissioningInfo?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBreadcrumb(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBreadcrumb(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeLocationCapability(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocationCapability(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRegulatoryConfig(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRegulatoryConfig(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportsConcurrentConnection(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportsConcurrentConnection(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeBreadcrumb(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeBreadcrumb(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeBreadcrumb(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeBreadcrumb(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterGeneralCommissioning: MTRGenericCluster {
    open func armFailSafe(with params: MTRGeneralCommissioningClusterArmFailSafeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralCommissioningClusterArmFailSafeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func armFailSafe(with params: MTRGeneralCommissioningClusterArmFailSafeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGeneralCommissioningClusterArmFailSafeResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func commissioningComplete(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func commissioningComplete(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func commissioningComplete(with params: MTRGeneralCommissioningClusterCommissioningCompleteParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func commissioningComplete(with params: MTRGeneralCommissioningClusterCommissioningCompleteParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGeneralCommissioningClusterCommissioningCompleteResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeBasicCommissioningInfo(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BasicCommissioningInfo", params: params)
    }
    open func readAttributeBreadcrumb(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Breadcrumb", params: params)
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
    open func readAttributeLocationCapability(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LocationCapability", params: params)
    }
    open func readAttributeRegulatoryConfig(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RegulatoryConfig", params: params)
    }
    open func readAttributeSupportsConcurrentConnection(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportsConcurrentConnection", params: params)
    }
    open func setRegulatoryConfigWith(_ params: MTRGeneralCommissioningClusterSetRegulatoryConfigParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func setRegulatoryConfigWith(_ params: MTRGeneralCommissioningClusterSetRegulatoryConfigParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeBreadcrumb(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("Breadcrumb", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBreadcrumb(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("Breadcrumb", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterGeneralDiagnostics: MTRGenericBaseCluster {
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
    open class func readAttributeActiveHardwareFaults(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActiveHardwareFaults(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveNetworkFaults(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActiveNetworkFaults(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeActiveRadioFaults(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActiveRadioFaults(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeBootReason(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeBootReasons(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
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
    open class func readAttributeNetworkInterfaces(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeNetworkInterfaces(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRebootCount(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeRebootCount(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTestEventTriggersEnabled(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTestEventTriggersEnabled(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTotalOperationalHours(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTotalOperationalHours(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeUpTime(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUpTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func payloadTestRequest(with params: MTRGeneralDiagnosticsClusterPayloadTestRequestParams, completion: @escaping (MTRGeneralDiagnosticsClusterPayloadTestResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
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
    open func readAttributeActiveHardwareFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveHardwareFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveNetworkFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveNetworkFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveRadioFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveRadioFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeBootReason(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBootReasons(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeNetworkInterfaces(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNetworkInterfaces(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRebootCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRebootCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTestEventTriggersEnabled(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTestEventTriggersEnabled(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTotalOperationalHours(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTotalOperationalHours(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUpTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUpTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeActiveHardwareFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveHardwareFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveNetworkFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveNetworkFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveRadioFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveRadioFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeBootReason(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBootReasons(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
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
    open func subscribeAttributeNetworkInterfaces(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNetworkInterfaces(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRebootCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRebootCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTestEventTriggersEnabled(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTestEventTriggersEnabled(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalOperationalHours(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalOperationalHours(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUpTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func testEventTrigger(with params: MTRGeneralDiagnosticsClusterTestEventTriggerParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func testEventTrigger(with params: MTRGeneralDiagnosticsClusterTestEventTriggerParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func timeSnapshot(completion: @escaping (MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func timeSnapshot(with params: MTRGeneralDiagnosticsClusterTimeSnapshotParams?, completion: @escaping (MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterGeneralDiagnostics: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func payloadTestRequest(with params: MTRGeneralDiagnosticsClusterPayloadTestRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralDiagnosticsClusterPayloadTestResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveHardwareFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveHardwareFaults", params: params)
    }
    open func readAttributeActiveNetworkFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveNetworkFaults", params: params)
    }
    open func readAttributeActiveRadioFaults(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveRadioFaults", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBootReason(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BootReason", params: params)
    }
    open func readAttributeBootReasons(with params: MTRReadParams?) -> [String : Any]
    {
        _ = (params)
        return mtrHostRead("BootReasons", params: params) ?? [:]
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
    open func readAttributeNetworkInterfaces(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NetworkInterfaces", params: params)
    }
    open func readAttributeRebootCount(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RebootCount", params: params)
    }
    open func readAttributeTestEventTriggersEnabled(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TestEventTriggersEnabled", params: params)
    }
    open func readAttributeTotalOperationalHours(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TotalOperationalHours", params: params)
    }
    open func readAttributeUpTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("UpTime", params: params)
    }
    open func testEventTrigger(with params: MTRGeneralDiagnosticsClusterTestEventTriggerParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func testEventTrigger(with params: MTRGeneralDiagnosticsClusterTestEventTriggerParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func timeSnapshot(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func timeSnapshot(with params: MTRGeneralDiagnosticsClusterTimeSnapshotParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterModeSelect: MTRGenericBaseCluster {
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
    open class func readAttributeCurrentMode(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDescription(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeDescription(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (String?, (any Error)?) -> Void)
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
    open class func readAttributeOnMode(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeOnMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeStandardNamespace(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeStandardNamespace(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeStartUpMode(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeStartUpMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedModes(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSupportedModes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func changeToMode(with params: MTRModeSelectClusterChangeToModeParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func changeToMode(with params: MTRModeSelectClusterChangeToModeParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCurrentMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDescription(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDescription(completionHandler: @escaping (String?, (any Error)?) -> Void)
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
    open func readAttributeOnMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOnMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStandardNamespace(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStandardNamespace(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStartUpMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStartUpMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportedModes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedModes(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeCurrentMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDescription(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDescription(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeOnMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStandardNamespace(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStandardNamespace(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeOnMode(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeOnMode(withValue value: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeOnMode(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeOnMode(withValue value: NSNumber?, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeStartUpMode(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeStartUpMode(withValue value: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeStartUpMode(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeStartUpMode(withValue value: NSNumber?, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterModeSelect: MTRGenericCluster {
    open func changeToMode(with params: MTRModeSelectClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func changeToMode(with params: MTRModeSelectClusterChangeToModeParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeDescription(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Description", params: params)
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
    open func readAttributeOnMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OnMode", params: params)
    }
    open func readAttributeStandardNamespace(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("StandardNamespace", params: params)
    }
    open func readAttributeStartUpMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("StartUpMode", params: params)
    }
    open func readAttributeSupportedModes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedModes", params: params)
    }
    open func writeAttributeOnMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("OnMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeOnMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("OnMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeStartUpMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("StartUpMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeStartUpMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("StartUpMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterOperationalCredentials: MTRGenericBaseCluster {
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
    open class func readAttributeCommissionedFabrics(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCommissionedFabrics(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentFabricIndex(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentFabricIndex(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeFabrics(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeFabrics(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeNOCs(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeNOCs(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedFabrics(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSupportedFabrics(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTrustedRootCertificates(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTrustedRootCertificates(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func csrRequest(with params: MTROperationalCredentialsClusterCSRRequestParams, completion: @escaping (MTROperationalCredentialsClusterCSRResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func csrRequest(with params: MTROperationalCredentialsClusterCSRRequestParams, completionHandler: @escaping (MTROperationalCredentialsClusterCSRResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func addNOC(with params: MTROperationalCredentialsClusterAddNOCParams, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func addNOC(with params: MTROperationalCredentialsClusterAddNOCParams, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func addTrustedRootCertificate(with params: MTROperationalCredentialsClusterAddTrustedRootCertificateParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func addTrustedRootCertificate(with params: MTROperationalCredentialsClusterAddTrustedRootCertificateParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func attestationRequest(with params: MTROperationalCredentialsClusterAttestationRequestParams, completion: @escaping (MTROperationalCredentialsClusterAttestationResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func attestationRequest(with params: MTROperationalCredentialsClusterAttestationRequestParams, completionHandler: @escaping (MTROperationalCredentialsClusterAttestationResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func certificateChainRequest(with params: MTROperationalCredentialsClusterCertificateChainRequestParams, completion: @escaping (MTROperationalCredentialsClusterCertificateChainResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func certificateChainRequest(with params: MTROperationalCredentialsClusterCertificateChainRequestParams, completionHandler: @escaping (MTROperationalCredentialsClusterCertificateChainResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCommissionedFabrics(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCommissionedFabrics(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentFabricIndex(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentFabricIndex(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFabrics(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFabrics(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
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
    open func readAttributeNOCs(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNOCs(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportedFabrics(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedFabrics(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTrustedRootCertificates(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTrustedRootCertificates(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func removeFabric(with params: MTROperationalCredentialsClusterRemoveFabricParams, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func removeFabric(with params: MTROperationalCredentialsClusterRemoveFabricParams, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
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
    open func subscribeAttributeCommissionedFabrics(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCommissionedFabrics(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentFabricIndex(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentFabricIndex(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFabrics(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFabrics(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeNOCs(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNOCs(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedFabrics(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedFabrics(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTrustedRootCertificates(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTrustedRootCertificates(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func updateFabricLabel(with params: MTROperationalCredentialsClusterUpdateFabricLabelParams, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func updateFabricLabel(with params: MTROperationalCredentialsClusterUpdateFabricLabelParams, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func updateNOC(with params: MTROperationalCredentialsClusterUpdateNOCParams, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func updateNOC(with params: MTROperationalCredentialsClusterUpdateNOCParams, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterOperationalCredentials: MTRGenericCluster {
    open func csrRequest(with params: MTROperationalCredentialsClusterCSRRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterCSRResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func csrRequest(with params: MTROperationalCredentialsClusterCSRRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterCSRResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func addNOC(with params: MTROperationalCredentialsClusterAddNOCParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func addNOC(with params: MTROperationalCredentialsClusterAddNOCParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func addTrustedRootCertificate(with params: MTROperationalCredentialsClusterAddTrustedRootCertificateParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func addTrustedRootCertificate(with params: MTROperationalCredentialsClusterAddTrustedRootCertificateParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func attestationRequest(with params: MTROperationalCredentialsClusterAttestationRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterAttestationResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func attestationRequest(with params: MTROperationalCredentialsClusterAttestationRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterAttestationResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func certificateChainRequest(with params: MTROperationalCredentialsClusterCertificateChainRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterCertificateChainResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func certificateChainRequest(with params: MTROperationalCredentialsClusterCertificateChainRequestParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterCertificateChainResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCommissionedFabrics(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CommissionedFabrics", params: params)
    }
    open func readAttributeCurrentFabricIndex(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentFabricIndex", params: params)
    }
    open func readAttributeFabrics(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Fabrics", params: params)
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
    open func readAttributeNOCs(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NOCs", params: params)
    }
    open func readAttributeSupportedFabrics(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedFabrics", params: params)
    }
    open func readAttributeTrustedRootCertificates(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TrustedRootCertificates", params: params)
    }
    open func removeFabric(with params: MTROperationalCredentialsClusterRemoveFabricParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func removeFabric(with params: MTROperationalCredentialsClusterRemoveFabricParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func updateFabricLabel(with params: MTROperationalCredentialsClusterUpdateFabricLabelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func updateFabricLabel(with params: MTROperationalCredentialsClusterUpdateFabricLabelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func updateNOC(with params: MTROperationalCredentialsClusterUpdateNOCParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func updateNOC(with params: MTROperationalCredentialsClusterUpdateNOCParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTROperationalCredentialsClusterNOCResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterPressureMeasurement: MTRGenericBaseCluster {
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
    open class func readAttributeMaxMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxScaledValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxScaledValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinScaledValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMinScaledValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeScale(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeScale(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeScaledTolerance(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeScaledTolerance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeScaledValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeScaledValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTolerance(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTolerance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxScaledValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxScaledValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinScaledValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinScaledValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeScale(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeScale(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeScaledTolerance(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeScaledTolerance(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeScaledValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeScaledValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTolerance(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTolerance(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeMaxMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxScaledValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxScaledValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinScaledValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinScaledValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScale(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScale(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScaledTolerance(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScaledTolerance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScaledValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScaledValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterPressureMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeMaxMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxMeasuredValue", params: params)
    }
    open func readAttributeMaxScaledValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxScaledValue", params: params)
    }
    open func readAttributeMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredValue", params: params)
    }
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributeMinScaledValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinScaledValue", params: params)
    }
    open func readAttributeScale(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Scale", params: params)
    }
    open func readAttributeScaledTolerance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ScaledTolerance", params: params)
    }
    open func readAttributeScaledValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ScaledValue", params: params)
    }
    open func readAttributeTolerance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Tolerance", params: params)
    }
}

open class MTRBaseClusterGroupKeyManagement: MTRGenericBaseCluster {
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
    open class func readAttributeGroupKeyMap(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGroupKeyMap(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeGroupTable(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeGroupTable(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxGroupKeysPerFabric(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxGroupKeysPerFabric(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxGroupsPerFabric(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxGroupsPerFabric(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func keySetReadAllIndices(completion: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func keySetReadAllIndices(with params: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams?, completion: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func keySetReadAllIndices(with params: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams?, completionHandler: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetRead(with params: MTRGroupKeyManagementClusterKeySetReadParams, completion: @escaping (MTRGroupKeyManagementClusterKeySetReadResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func keySetRead(with params: MTRGroupKeyManagementClusterKeySetReadParams, completionHandler: @escaping (MTRGroupKeyManagementClusterKeySetReadResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetRemove(with params: MTRGroupKeyManagementClusterKeySetRemoveParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func keySetRemove(with params: MTRGroupKeyManagementClusterKeySetRemoveParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetWrite(with params: MTRGroupKeyManagementClusterKeySetWriteParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func keySetWrite(with params: MTRGroupKeyManagementClusterKeySetWriteParams, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func readAttributeGroupKeyMap(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGroupKeyMap(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGroupTable(with params: MTRReadParams?, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGroupTable(with params: MTRReadParams?, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxGroupKeysPerFabric(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxGroupKeysPerFabric(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxGroupsPerFabric(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxGroupsPerFabric(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeGroupKeyMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGroupKeyMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGroupTable(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGroupTable(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxGroupKeysPerFabric(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxGroupKeysPerFabric(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxGroupsPerFabric(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxGroupsPerFabric(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeGroupKeyMap(withValue value: [Any], completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeGroupKeyMap(withValue value: [Any], completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeGroupKeyMap(withValue value: [Any], params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeGroupKeyMap(withValue value: [Any], params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterGroupKeyManagement: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func keySetReadAllIndices(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func keySetReadAllIndices(with params: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func keySetReadAllIndices(with params: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetRead(with params: MTRGroupKeyManagementClusterKeySetReadParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRGroupKeyManagementClusterKeySetReadResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func keySetRead(with params: MTRGroupKeyManagementClusterKeySetReadParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRGroupKeyManagementClusterKeySetReadResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetRemove(with params: MTRGroupKeyManagementClusterKeySetRemoveParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func keySetRemove(with params: MTRGroupKeyManagementClusterKeySetRemoveParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func keySetWrite(with params: MTRGroupKeyManagementClusterKeySetWriteParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func keySetWrite(with params: MTRGroupKeyManagementClusterKeySetWriteParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func readAttributeGroupKeyMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GroupKeyMap", params: params)
    }
    open func readAttributeGroupTable(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GroupTable", params: params)
    }
    open func readAttributeMaxGroupKeysPerFabric(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxGroupKeysPerFabric", params: params)
    }
    open func readAttributeMaxGroupsPerFabric(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MaxGroupsPerFabric", params: params)
    }
    open func writeAttributeGroupKeyMap(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("GroupKeyMap", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeGroupKeyMap(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("GroupKeyMap", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterIlluminanceMeasurement: MTRGenericBaseCluster {
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
    open class func readAttributeLightSensorType(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLightSensorType(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMaxMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTolerance(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTolerance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeLightSensorType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLightSensorType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTolerance(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTolerance(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeLightSensorType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLightSensorType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterIlluminanceMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeLightSensorType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LightSensorType", params: params)
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
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributeTolerance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Tolerance", params: params)
    }
}

open class MTRBaseClusterDescriptor: MTRGenericBaseCluster {
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
    open class func readAttributeClientList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClientList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeDeviceList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeDeviceTypeList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributePartsList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePartsList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeServerList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeServerList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeClientList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClientList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeDeviceList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDeviceTypeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
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
    open func readAttributePartsList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePartsList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeServerList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeServerList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeClientList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClientList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeDeviceList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDeviceTypeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributePartsList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartsList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeServerList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeServerList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterDescriptor: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeClientList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClientList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeDeviceList(with params: MTRReadParams?) -> [String : Any]
    {
        _ = (params)
        return mtrHostRead("DeviceList", params: params) ?? [:]
    }
    open func readAttributeDeviceTypeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DeviceTypeList", params: params)
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
    open func readAttributePartsList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PartsList", params: params)
    }
    open func readAttributeServerList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ServerList", params: params)
    }
}

open class MTRBaseClusterFlowMeasurement: MTRGenericBaseCluster {
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
    open class func readAttributeMaxMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMaxMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeMinMeasuredValue(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeMinMeasuredValue(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTolerance(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTolerance(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeMaxMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinMeasuredValue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinMeasuredValue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTolerance(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTolerance(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeMaxMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinMeasuredValue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTolerance(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterFlowMeasurement: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeMinMeasuredValue(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MinMeasuredValue", params: params)
    }
    open func readAttributeTolerance(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Tolerance", params: params)
    }
}

open class MTRBaseClusterMediaInput: MTRGenericBaseCluster {
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
    open class func readAttributeCurrentInput(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentInput(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeInputList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeInputList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func hideStatus(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func hideStatus(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func hideStatus(with params: MTRMediaInputClusterHideInputStatusParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func hideStatus(with params: MTRMediaInputClusterHideInputStatusParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCurrentInput(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentInput(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeInputList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInputList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func renameInput(with params: MTRMediaInputClusterRenameInputParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func renameInput(with params: MTRMediaInputClusterRenameInputParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func select(with params: MTRMediaInputClusterSelectInputParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func select(with params: MTRMediaInputClusterSelectInputParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func showStatus(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func showStatus(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func showStatus(with params: MTRMediaInputClusterShowInputStatusParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func showStatus(with params: MTRMediaInputClusterShowInputStatusParams?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeCurrentInput(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentInput(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeInputList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInputList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterMediaInput: MTRGenericCluster {
    open func hideStatus(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func hideStatus(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func hideStatus(with params: MTRMediaInputClusterHideInputStatusParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func hideStatus(with params: MTRMediaInputClusterHideInputStatusParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCurrentInput(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentInput", params: params)
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
    open func readAttributeInputList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InputList", params: params)
    }
    open func renameInput(with params: MTRMediaInputClusterRenameInputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func renameInput(with params: MTRMediaInputClusterRenameInputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func select(with params: MTRMediaInputClusterSelectInputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func select(with params: MTRMediaInputClusterSelectInputParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func showStatus(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func showStatus(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func showStatus(with params: MTRMediaInputClusterShowInputStatusParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func showStatus(with params: MTRMediaInputClusterShowInputStatusParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterAdministratorCommissioning: MTRGenericBaseCluster {
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
    open class func readAttributeAdminFabricIndex(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAdminFabricIndex(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeAdminVendorId(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeAdminVendorId(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeWindowStatus(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeWindowStatus(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func openBasicCommissioningWindow(with params: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func openBasicCommissioningWindow(with params: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func openWindow(with params: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func openWindow(with params: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func readAttributeAdminFabricIndex(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAdminFabricIndex(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAdminVendorId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAdminVendorId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeWindowStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWindowStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func revokeCommissioning(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func revokeCommissioning(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func revokeCommissioning(with params: MTRAdministratorCommissioningClusterRevokeCommissioningParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func revokeCommissioning(with params: MTRAdministratorCommissioningClusterRevokeCommissioningParams?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeAdminFabricIndex(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAdminFabricIndex(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAdminVendorId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAdminVendorId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeWindowStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWindowStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterAdministratorCommissioning: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func openBasicCommissioningWindow(with params: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func openBasicCommissioningWindow(with params: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func openWindow(with params: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func openWindow(with params: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAdminFabricIndex(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AdminFabricIndex", params: params)
    }
    open func readAttributeAdminVendorId(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AdminVendorId", params: params)
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
    open func readAttributeWindowStatus(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WindowStatus", params: params)
    }
    open func revokeCommissioning(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func revokeCommissioning(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func revokeCommissioning(with params: MTRAdministratorCommissioningClusterRevokeCommissioningParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func revokeCommissioning(with params: MTRAdministratorCommissioningClusterRevokeCommissioningParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterSoftwareDiagnostics: MTRGenericBaseCluster {
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
    open class func readAttributeCurrentHeapFree(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentHeapFree(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentHeapHighWatermark(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentHeapHighWatermark(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentHeapUsed(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentHeapUsed(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeThreadMetrics(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeThreadMetrics(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCurrentHeapFree(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentHeapFree(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentHeapHighWatermark(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentHeapHighWatermark(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentHeapUsed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentHeapUsed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeThreadMetrics(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThreadMetrics(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetWatermarks(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetWatermarks(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetWatermarks(with params: MTRSoftwareDiagnosticsClusterResetWatermarksParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func resetWatermarks(with params: MTRSoftwareDiagnosticsClusterResetWatermarksParams?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeCurrentHeapFree(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHeapFree(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHeapHighWatermark(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHeapHighWatermark(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHeapUsed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHeapUsed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeThreadMetrics(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThreadMetrics(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterSoftwareDiagnostics: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeCurrentHeapFree(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentHeapFree", params: params)
    }
    open func readAttributeCurrentHeapHighWatermark(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentHeapHighWatermark", params: params)
    }
    open func readAttributeCurrentHeapUsed(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentHeapUsed", params: params)
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
    open func readAttributeThreadMetrics(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ThreadMetrics", params: params)
    }
    open func resetWatermarks(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetWatermarks(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetWatermarks(with params: MTRSoftwareDiagnosticsClusterResetWatermarksParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func resetWatermarks(with params: MTRSoftwareDiagnosticsClusterResetWatermarksParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterThermostatUserInterfaceConfiguration: MTRGenericBaseCluster {
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
    open class func readAttributeKeypadLockout(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeKeypadLockout(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeScheduleProgrammingVisibility(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeScheduleProgrammingVisibility(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTemperatureDisplayMode(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeTemperatureDisplayMode(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeKeypadLockout(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeKeypadLockout(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeScheduleProgrammingVisibility(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeScheduleProgrammingVisibility(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTemperatureDisplayMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTemperatureDisplayMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeKeypadLockout(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeKeypadLockout(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScheduleProgrammingVisibility(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScheduleProgrammingVisibility(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureDisplayMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureDisplayMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeKeypadLockout(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeKeypadLockout(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeKeypadLockout(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeKeypadLockout(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeTemperatureDisplayMode(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeTemperatureDisplayMode(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeTemperatureDisplayMode(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeTemperatureDisplayMode(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterThermostatUserInterfaceConfiguration: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeKeypadLockout(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("KeypadLockout", params: params)
    }
    open func readAttributeScheduleProgrammingVisibility(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ScheduleProgrammingVisibility", params: params)
    }
    open func readAttributeTemperatureDisplayMode(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TemperatureDisplayMode", params: params)
    }
    open func writeAttributeKeypadLockout(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("KeypadLockout", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeKeypadLockout(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("KeypadLockout", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ScheduleProgrammingVisibility", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeScheduleProgrammingVisibility(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ScheduleProgrammingVisibility", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeTemperatureDisplayMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("TemperatureDisplayMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeTemperatureDisplayMode(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("TemperatureDisplayMode", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterChannel: MTRGenericBaseCluster {
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
    open class func readAttributeChannelList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeChannelList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeCurrentChannel(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRChannelClusterChannelInfo?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentChannel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRChannelClusterChannelInfoStruct?, (any Error)?) -> Void)
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
    open class func readAttributeLineup(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRChannelClusterLineupInfo?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLineup(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRChannelClusterLineupInfoStruct?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func cancelRecordProgram(with params: MTRChannelClusterCancelRecordProgramParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func changeByNumber(with params: MTRChannelClusterChangeChannelByNumberParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func changeByNumber(with params: MTRChannelClusterChangeChannelByNumberParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func change(with params: MTRChannelClusterChangeChannelParams, completion: @escaping (MTRChannelClusterChangeChannelResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func change(with params: MTRChannelClusterChangeChannelParams, completionHandler: @escaping (MTRChannelClusterChangeChannelResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProgramGuide(completion: @escaping (MTRChannelClusterProgramGuideResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getProgramGuide(with params: MTRChannelClusterGetProgramGuideParams?, completion: @escaping (MTRChannelClusterProgramGuideResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeChannelList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChannelList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeCurrentChannel(completion: @escaping (MTRChannelClusterChannelInfoStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentChannel(completionHandler: @escaping (MTRChannelClusterChannelInfo?, (any Error)?) -> Void)
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
    open func readAttributeLineup(completion: @escaping (MTRChannelClusterLineupInfoStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLineup(completionHandler: @escaping (MTRChannelClusterLineupInfo?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func recordProgram(with params: MTRChannelClusterRecordProgramParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRChannelClusterSkipChannelParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRChannelClusterSkipChannelParams, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeChannelList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChannelList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeCurrentChannel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRChannelClusterChannelInfo?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentChannel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRChannelClusterChannelInfoStruct?, (any Error)?) -> Void)
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
    open func subscribeAttributeLineup(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRChannelClusterLineupInfo?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLineup(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRChannelClusterLineupInfoStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterChannel: MTRGenericCluster {
    open func cancelRecordProgram(with params: MTRChannelClusterCancelRecordProgramParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func changeByNumber(with params: MTRChannelClusterChangeChannelByNumberParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func changeByNumber(with params: MTRChannelClusterChangeChannelByNumberParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func change(with params: MTRChannelClusterChangeChannelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRChannelClusterChangeChannelResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func change(with params: MTRChannelClusterChangeChannelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRChannelClusterChangeChannelResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProgramGuide(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRChannelClusterProgramGuideResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getProgramGuide(with params: MTRChannelClusterGetProgramGuideParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRChannelClusterProgramGuideResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeChannelList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ChannelList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentChannel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentChannel", params: params)
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
    open func readAttributeLineup(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Lineup", params: params)
    }
    open func recordProgram(with params: MTRChannelClusterRecordProgramParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRChannelClusterSkipChannelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func skip(with params: MTRChannelClusterSkipChannelParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterSmokeCOAlarm: MTRGenericBaseCluster {
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
    open class func readAttributeBatteryAlert(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCOState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeContaminationState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDeviceMuted(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeEndOfServiceAlert(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeExpiryDate(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeExpressedState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeHardwareFaultAlert(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeInterconnectCOAlarm(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeInterconnectSmoke(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSmokeSensitivityLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSmokeState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTestInProgress(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeBatteryAlert(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCOState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeContaminationState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDeviceMuted(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEndOfServiceAlert(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExpiryDate(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExpressedState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeHardwareFaultAlert(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInterconnectCOAlarm(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInterconnectSmoke(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSmokeSensitivityLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSmokeState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTestInProgress(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func selfTestRequest(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func selfTestRequest(with params: MTRSmokeCOAlarmClusterSelfTestRequestParams?, completion: @escaping ((any Error)?) -> Void)
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
    open func subscribeAttributeBatteryAlert(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCOState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeContaminationState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDeviceMuted(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEndOfServiceAlert(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExpiryDate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExpressedState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeHardwareFaultAlert(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInterconnectCOAlarm(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInterconnectSmoke(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSmokeSensitivityLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSmokeState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTestInProgress(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeSmokeSensitivityLevel(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSmokeSensitivityLevel(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterSmokeCOAlarm: MTRGenericCluster {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeBatteryAlert(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("BatteryAlert", params: params)
    }
    open func readAttributeCOState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("COState", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeContaminationState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ContaminationState", params: params)
    }
    open func readAttributeDeviceMuted(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DeviceMuted", params: params)
    }
    open func readAttributeEndOfServiceAlert(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EndOfServiceAlert", params: params)
    }
    open func readAttributeExpiryDate(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ExpiryDate", params: params)
    }
    open func readAttributeExpressedState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ExpressedState", params: params)
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
    open func readAttributeHardwareFaultAlert(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HardwareFaultAlert", params: params)
    }
    open func readAttributeInterconnectCOAlarm(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InterconnectCOAlarm", params: params)
    }
    open func readAttributeInterconnectSmoke(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InterconnectSmoke", params: params)
    }
    open func readAttributeSmokeSensitivityLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SmokeSensitivityLevel", params: params)
    }
    open func readAttributeSmokeState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SmokeState", params: params)
    }
    open func readAttributeTestInProgress(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TestInProgress", params: params)
    }
    open func selfTestRequest(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func selfTestRequest(with params: MTRSmokeCOAlarmClusterSelfTestRequestParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeSmokeSensitivityLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("SmokeSensitivityLevel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeSmokeSensitivityLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("SmokeSensitivityLevel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterTimeFormatLocalization: MTRGenericBaseCluster {
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
    open class func readAttributeActiveCalendarType(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeActiveCalendarType(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeHourFormat(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeHourFormat(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeSupportedCalendarTypes(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSupportedCalendarTypes(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
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
    open func readAttributeActiveCalendarType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveCalendarType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeHourFormat(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHourFormat(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportedCalendarTypes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedCalendarTypes(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeActiveCalendarType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCalendarType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeHourFormat(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHourFormat(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedCalendarTypes(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedCalendarTypes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeActiveCalendarType(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeActiveCalendarType(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeActiveCalendarType(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeActiveCalendarType(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeHourFormat(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeHourFormat(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeHourFormat(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeHourFormat(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterTimeFormatLocalization: MTRGenericCluster {
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveCalendarType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveCalendarType", params: params)
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
    open func readAttributeHourFormat(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HourFormat", params: params)
    }
    open func readAttributeSupportedCalendarTypes(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("SupportedCalendarTypes", params: params)
    }
    open func writeAttributeActiveCalendarType(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("ActiveCalendarType", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeActiveCalendarType(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("ActiveCalendarType", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeHourFormat(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("HourFormat", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeHourFormat(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("HourFormat", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterApplicationLauncher: MTRGenericBaseCluster {
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
    open class func readAttributeCatalogList(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCatalogList(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping ([Any]?, (any Error)?) -> Void)
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
    open class func readAttributeCurrentApp(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRApplicationLauncherClusterApplicationEP?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeCurrentApp(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (MTRApplicationLauncherClusterApplicationEPStruct?, (any Error)?) -> Void)
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
    open func hideApp(completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func hideApp(with params: MTRApplicationLauncherClusterHideAppParams?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func hideApp(with params: MTRApplicationLauncherClusterHideAppParams?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func launchApp(completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func launchApp(with params: MTRApplicationLauncherClusterLaunchAppParams?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func launchApp(with params: MTRApplicationLauncherClusterLaunchAppParams?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
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
    open func readAttributeCatalogList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCatalogList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func readAttributeCurrentApp(completion: @escaping (MTRApplicationLauncherClusterApplicationEPStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentApp(completionHandler: @escaping (MTRApplicationLauncherClusterApplicationEP?, (any Error)?) -> Void)
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
    open func stopApp(completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func stopApp(with params: MTRApplicationLauncherClusterStopAppParams?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func stopApp(with params: MTRApplicationLauncherClusterStopAppParams?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
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
    open func subscribeAttributeCatalogList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCatalogList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
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
    open func subscribeAttributeCurrentApp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRApplicationLauncherClusterApplicationEP?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentApp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRApplicationLauncherClusterApplicationEPStruct?, (any Error)?) -> Void)
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
    open func writeAttributeCurrentApp(withValue value: MTRApplicationLauncherClusterApplicationEPStruct?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeCurrentApp(withValue value: MTRApplicationLauncherClusterApplicationEP?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeCurrentApp(withValue value: MTRApplicationLauncherClusterApplicationEPStruct?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeCurrentApp(withValue value: MTRApplicationLauncherClusterApplicationEP?, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterApplicationLauncher: MTRGenericCluster {
    open func hideApp(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func hideApp(with params: MTRApplicationLauncherClusterHideAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func hideApp(with params: MTRApplicationLauncherClusterHideAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func launchApp(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func launchApp(with params: MTRApplicationLauncherClusterLaunchAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func launchApp(with params: MTRApplicationLauncherClusterLaunchAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
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
    open func readAttributeCatalogList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CatalogList", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentApp(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentApp", params: params)
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
    open func stopApp(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stopApp(with params: MTRApplicationLauncherClusterStopAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func stopApp(with params: MTRApplicationLauncherClusterStopAppParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping (MTRApplicationLauncherClusterLauncherResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeCurrentApp(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("CurrentApp", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeCurrentApp(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("CurrentApp", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterValveConfigurationAndControl: MTRGenericBaseCluster {
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
    open class func readAttributeAutoCloseTime(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeClusterRevision(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeCurrentState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDefaultOpenDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeDefaultOpenLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeLevelStep(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeOpenDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeRemainingDuration(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTargetLevel(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeTargetState(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open class func readAttributeValveFault(withClusterStateCache clusterStateCacheContainer: MTRClusterStateCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (clusterStateCacheContainer, endpoint, queue, completion)
        mtrInvokeFailClosed(completion)
    }
    open func close(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func close(with params: MTRValveConfigurationAndControlClusterCloseParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func open(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func open(with params: MTRValveConfigurationAndControlClusterOpenParams?, completion: @escaping ((any Error)?) -> Void)
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
    open func readAttributeAutoCloseTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultOpenDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultOpenLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeLevelStep(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOpenDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRemainingDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeValveFault(completion: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeAutoCloseTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultOpenDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultOpenLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeLevelStep(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOpenDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemainingDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeValveFault(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeDefaultOpenDuration(withValue value: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeDefaultOpenDuration(withValue value: NSNumber?, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeDefaultOpenLevel(withValue value: NSNumber, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completion)
        mtrFailClosed(completion)
    }
    open func writeAttributeDefaultOpenLevel(withValue value: NSNumber, params: MTRWriteParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterValveConfigurationAndControl: MTRGenericCluster {
    open func close(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func close(with params: MTRValveConfigurationAndControlClusterCloseParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func open(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func open(with params: MTRValveConfigurationAndControlClusterOpenParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
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
    open func readAttributeAutoCloseTime(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AutoCloseTime", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentLevel", params: params)
    }
    open func readAttributeCurrentState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentState", params: params)
    }
    open func readAttributeDefaultOpenDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DefaultOpenDuration", params: params)
    }
    open func readAttributeDefaultOpenLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DefaultOpenLevel", params: params)
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
    open func readAttributeLevelStep(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LevelStep", params: params)
    }
    open func readAttributeOpenDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OpenDuration", params: params)
    }
    open func readAttributeRemainingDuration(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RemainingDuration", params: params)
    }
    open func readAttributeTargetLevel(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TargetLevel", params: params)
    }
    open func readAttributeTargetState(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TargetState", params: params)
    }
    open func readAttributeValveFault(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ValveFault", params: params)
    }
    open func writeAttributeDefaultOpenDuration(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("DefaultOpenDuration", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeDefaultOpenDuration(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("DefaultOpenDuration", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeDefaultOpenLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        mtrHostWrite("DefaultOpenLevel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeDefaultOpenLevel(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        mtrHostWrite("DefaultOpenLevel", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterBasic: MTRBaseClusterBasicInformation {
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
    open class func readAttributeCapabilityMinima(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (MTRBasicClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeClusterRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeDataModelRevision(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open class func readAttributeHardwareVersionString(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeHardwareVersion(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLocalConfigDisabled(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeLocation(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeManufacturingDate(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeNodeLabel(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePartNumber(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductLabel(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductURL(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeReachable(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSerialNumber(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSoftwareVersionString(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSoftwareVersion(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUniqueID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func mfgSpecificPing(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func mfgSpecificPing(with params: MTRBasicClusterMfgSpecificPingParams?, completionHandler: @escaping ((any Error)?) -> Void)
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
    open func readAttributeCapabilityMinima(completionHandler: @escaping (MTRBasicClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDataModelRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func readAttributeHardwareVersionString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeHardwareVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLocalConfigDisabled(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLocation(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeManufacturingDate(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNodeLabel(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePartNumber(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductID(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductLabel(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductName(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductURL(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReachable(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSerialNumber(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSoftwareVersionString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSoftwareVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUniqueID(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorID(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorName(completionHandler: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeCapabilityMinima(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRBasicClusterCapabilityMinimaStruct?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDataModelRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
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
    open func subscribeAttributeHardwareVersionString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHardwareVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalConfigDisabled(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeManufacturingDate(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNodeLabel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartNumber(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductLabel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductURL(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReachable(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSerialNumber(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersionString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUniqueID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeLocalConfigDisabled(withValue value: NSNumber, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeLocalConfigDisabled(withValue value: NSNumber, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeLocation(withValue value: String, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeLocation(withValue value: String, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeNodeLabel(withValue value: String, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeNodeLabel(withValue value: String, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterBasic: MTRClusterBasicInformation {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func mfgSpecificPing(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func mfgSpecificPing(with params: MTRBasicClusterMfgSpecificPingParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterBridgedDeviceBasic: MTRBaseClusterBridgedDeviceBasicInformation {
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
    open class func readAttributeHardwareVersionString(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeHardwareVersion(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeManufacturingDate(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeNodeLabel(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributePartNumber(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductLabel(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeProductURL(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeReachable(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSerialNumber(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSoftwareVersionString(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeSoftwareVersion(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeUniqueID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorID(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    open class func readAttributeVendorName(withAttributeCache attributeCacheContainer: MTRAttributeCacheContainer, endpoint: NSNumber, queue: dispatch_queue_t, completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (attributeCacheContainer, endpoint, queue, completionHandler)
        mtrInvokeFailClosed(completionHandler)
    }
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
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
    open func readAttributeHardwareVersionString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeHardwareVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeManufacturingDate(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNodeLabel(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePartNumber(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductLabel(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductName(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeProductURL(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReachable(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSerialNumber(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSoftwareVersionString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSoftwareVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUniqueID(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorID(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorName(completionHandler: @escaping (String?, (any Error)?) -> Void)
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
    open func subscribeAttributeHardwareVersionString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHardwareVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeManufacturingDate(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNodeLabel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartNumber(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductLabel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeProductURL(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReachable(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSerialNumber(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersionString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoftwareVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUniqueID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorID(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func writeAttributeNodeLabel(withValue value: String, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func writeAttributeNodeLabel(withValue value: String, params: MTRWriteParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (value, params, completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRClusterBridgedDeviceBasic: MTRClusterBridgedDeviceBasicInformation {
    public convenience init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
}

