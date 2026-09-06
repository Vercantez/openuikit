import Foundation
import Dispatch

open class MTRCluster: NSObject {
    public var device: MTRBaseDevice?
    public var endpoint: NSNumber = 0
    public var queue: dispatch_queue_t?

    public func mtrFailClosed(_ completion: @escaping ((any Error)?) -> Void) {
        completion(MTRFailClosed())
    }

    public func mtrFailClosed<T>(_ completion: @escaping (T?, (any Error)?) -> Void) {
        completion(nil, MTRFailClosed())
    }

    public func mtrSubscribeFailClosed<T>(
        _ reportHandler: @escaping (T?, (any Error)?) -> Void
    ) {
        reportHandler(nil, MTRFailClosed())
    }

    public func mtrHostRead(_ attribute: String, params: MTRReadParams?) -> [String: Any]? {
        _ = params
        return (device as? MTRDevice)?.mtrCachedAttribute(
            endpoint: endpoint,
            cluster: String(describing: type(of: self)),
            attribute: attribute
        )
    }

    public func mtrHostWrite(
        _ attribute: String,
        value: Any,
        expectedValueInterval: NSNumber?,
        params: MTRWriteParams?
    ) {
        _ = (expectedValueInterval, params)
        (device as? MTRDevice)?.mtrStoreExpected(
            endpoint: endpoint,
            cluster: String(describing: type(of: self)),
            attribute: attribute,
            value: value
        )
    }
}

open class MTRGenericBaseCluster: MTRCluster {}
open class MTRGenericCluster: MTRCluster {}

open class MTRBaseDevice: NSObject {
    public var sessionTransportType: MTRTransportType { .undefined }

    public func openCommissioningWindow(
        withSetupPasscode setupPasscode: NSNumber,
        discriminator: NSNumber,
        duration: NSNumber
    ) throws -> MTRSetupPayload {
        _ = (setupPasscode, discriminator, duration)
        throw MTRFailClosed()
    }

    public func readAttribute(
        withEndpointID endpoint: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        params: MTRReadParams?
    ) throws -> [Any] {
        _ = (endpoint, clusterID, attributeID, params)
        throw MTRFailClosed(.invalidState)
    }

    public func invokeCommand(
        withEndpointID endpoint: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: [String: Any]?,
        timedInvokeTimeout: NSNumber?
    ) throws -> [Any] {
        _ = (endpoint, clusterID, commandID, commandFields, timedInvokeTimeout)
        throw MTRFailClosed(.invalidState)
    }

    public convenience init(nodeID: NSNumber, controller: MTRDeviceController) {
        self.init()
        _ = (nodeID, controller)
    }

    public func deregisterReportHandlers(withClientQueue queue: dispatch_queue_t, completion: @escaping () -> Void) {
        _ = queue
        completion()
    }

    public func deregisterReportHandlers(with queue: dispatch_queue_t, completion: @escaping () -> Void) {
        deregisterReportHandlers(withClientQueue: queue, completion: completion)
    }

    public func downloadLog(
        of type: MTRDiagnosticLogType,
        timeout: TimeInterval,
        queue: dispatch_queue_t,
        completion: @escaping (URL?, (any Error)?) -> Void
    ) {
        _ = (type, timeout, queue)
        mtrInvokeFailClosed(completion)
    }

    public func invokeCommand(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: Any,
        timedInvokeTimeout timeoutMs: NSNumber?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, commandID, commandFields, timeoutMs, queue)
        mtrInvokeFailClosed(completion)
    }

    public func invokeCommand(
        withEndpointId endpointId: NSNumber,
        clusterId: NSNumber,
        commandId: NSNumber,
        commandFields: Any,
        timedInvokeTimeout timeoutMs: NSNumber?,
        clientQueue: dispatch_queue_t,
        completionHandler: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        invokeCommand(
            withEndpointID: endpointId,
            clusterID: clusterId,
            commandID: commandId,
            commandFields: commandFields,
            timedInvokeTimeout: timeoutMs,
            queue: clientQueue,
            completion: completionHandler
        )
    }

    public func openCommissioningWindow(
        withDiscriminator discriminator: NSNumber,
        duration: NSNumber,
        queue: dispatch_queue_t,
        completion: @escaping (MTRSetupPayload?, (any Error)?) -> Void
    ) {
        _ = (discriminator, duration, queue)
        mtrInvokeFailClosed(completion)
    }

    public func openCommissioningWindow(
        withSetupPasscode setupPasscode: NSNumber,
        discriminator: NSNumber,
        duration: NSNumber,
        queue: dispatch_queue_t,
        completion: @escaping (MTRSetupPayload?, (any Error)?) -> Void
    ) {
        _ = (setupPasscode, discriminator, duration, queue)
        mtrInvokeFailClosed(completion)
    }

    public func readAttributePaths(
        _ attributePaths: [MTRAttributeRequestPath]?,
        eventPaths: [MTREventRequestPath]?,
        params: MTRReadParams?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (attributePaths, eventPaths, params, queue)
        mtrInvokeFailClosed(completion)
    }

    public func readAttribute(
        withEndpointId endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        params: MTRReadParams?,
        clientQueue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        readAttributes(
            withEndpointID: endpointId,
            clusterID: clusterId,
            attributeID: attributeId,
            params: params,
            queue: clientQueue,
            completion: completion
        )
    }

    public func readAttributes(
        withEndpointID endpointID: NSNumber?,
        clusterID: NSNumber?,
        attributeID: NSNumber?,
        params: MTRReadParams?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, attributeID, params, queue)
        mtrInvokeFailClosed(completion)
    }

    public func readEvents(
        withEndpointID endpointID: NSNumber?,
        clusterID: NSNumber?,
        eventID: NSNumber?,
        params: MTRReadParams?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, eventID, params, queue)
        mtrInvokeFailClosed(completion)
    }

    public func subscribeAttribute(
        withEndpointId endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: MTRSubscribeParams?,
        clientQueue: dispatch_queue_t,
        reportHandler: @escaping MTRDeviceResponseHandler,
        subscriptionEstablished subscriptionEstablishedHandler: (() -> Void)? = nil
    ) {
        _ = (endpointId, clusterId, attributeId, minInterval, maxInterval, params, clientQueue, subscriptionEstablishedHandler)
        reportHandler(nil, MTRFailClosed())
    }

    public func subscribe(
        toAttributePaths attributePaths: [MTRAttributeRequestPath]?,
        eventPaths: [MTREventRequestPath]?,
        params: MTRSubscribeParams?,
        queue: dispatch_queue_t,
        reportHandler: @escaping MTRDeviceResponseHandler,
        subscriptionEstablished: MTRSubscriptionEstablishedHandler?,
        resubscriptionScheduled: MTRDeviceResubscriptionScheduledHandler? = nil
    ) {
        _ = (attributePaths, eventPaths, params, queue, subscriptionEstablished, resubscriptionScheduled)
        reportHandler(nil, MTRFailClosed())
    }

    public func subscribeToAttributes(
        withEndpointID endpointID: NSNumber?,
        clusterID: NSNumber?,
        attributeID: NSNumber?,
        params: MTRSubscribeParams?,
        queue: dispatch_queue_t,
        reportHandler: @escaping MTRDeviceResponseHandler,
        subscriptionEstablished: MTRSubscriptionEstablishedHandler? = nil
    ) {
        _ = (endpointID, clusterID, attributeID, params, queue, subscriptionEstablished)
        reportHandler(nil, MTRFailClosed())
    }

    public func subscribeToEvents(
        withEndpointID endpointID: NSNumber?,
        clusterID: NSNumber?,
        eventID: NSNumber?,
        params: MTRSubscribeParams?,
        queue: dispatch_queue_t,
        reportHandler: @escaping MTRDeviceResponseHandler,
        subscriptionEstablished: MTRSubscriptionEstablishedHandler? = nil
    ) {
        _ = (endpointID, clusterID, eventID, params, queue, subscriptionEstablished)
        reportHandler(nil, MTRFailClosed())
    }

    public func subscribe(
        with queue: dispatch_queue_t,
        minInterval: UInt16,
        maxInterval: UInt16,
        params: MTRSubscribeParams?,
        cacheContainer attributeCacheContainer: MTRAttributeCacheContainer?,
        attributeReportHandler: MTRDeviceReportHandler?,
        eventReportHandler: MTRDeviceReportHandler?,
        errorHandler: @escaping MTRDeviceErrorHandler,
        subscriptionEstablished subscriptionEstablishedHandler: (() -> Void)?,
        resubscriptionScheduled resubscriptionScheduledHandler: MTRDeviceResubscriptionScheduledHandler? = nil
    ) {
        _ = (
            queue, minInterval, maxInterval, params, attributeCacheContainer,
            attributeReportHandler, eventReportHandler, subscriptionEstablishedHandler,
            resubscriptionScheduledHandler
        )
        errorHandler(MTRFailClosed())
    }

    public func subscribe(
        with queue: dispatch_queue_t,
        params: MTRSubscribeParams,
        clusterStateCacheContainer: MTRClusterStateCacheContainer?,
        attributeReportHandler: MTRDeviceReportHandler?,
        eventReportHandler: MTRDeviceReportHandler?,
        errorHandler: @escaping MTRDeviceErrorHandler,
        subscriptionEstablished: MTRSubscriptionEstablishedHandler?,
        resubscriptionScheduled: MTRDeviceResubscriptionScheduledHandler? = nil
    ) {
        _ = (
            queue, params, clusterStateCacheContainer, attributeReportHandler,
            eventReportHandler, subscriptionEstablished, resubscriptionScheduled
        )
        errorHandler(MTRFailClosed())
    }

    public func writeAttribute(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        value: Any,
        timedWriteTimeout timeoutMs: NSNumber?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, attributeID, value, timeoutMs, queue)
        mtrInvokeFailClosed(completion)
    }

    public func writeAttribute(
        withEndpointId endpointId: NSNumber,
        clusterId: NSNumber,
        attributeId: NSNumber,
        value: Any,
        timedWriteTimeout timeoutMs: NSNumber?,
        clientQueue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        writeAttribute(
            withEndpointID: endpointId,
            clusterID: clusterId,
            attributeID: attributeId,
            value: value,
            timedWriteTimeout: timeoutMs,
            queue: clientQueue,
            completion: completion
        )
    }
}

open class MTRDevice: MTRBaseDevice {
    public var nodeID: NSNumber = 0
    public private(set) var state: MTRDeviceState = .unknown
    public var estimatedStartTime: Date?
    public var estimatedStartDate: Date? {
        get { estimatedStartTime }
        set { estimatedStartTime = newValue }
    }
    public var estimatedSubscriptionLatency: NSNumber?
    public var deviceController: MTRDeviceController?
    public var deviceCachePrimed: Bool { !attributeCache.isEmpty }
    public var vendorID: NSNumber?
    public var productID: NSNumber?
    public var networkCommissioningFeatures: MTRNetworkCommissioningFeature = []

    private var attributeCache: [String: [String: Any]] = [:]
    private var delegates: [MTRDeviceDelegateBox] = []
    private var delegateDispatchLog: [String] = []

    public override init() {
        super.init()
    }

    public init(nodeID: NSNumber, controller: MTRDeviceController) {
        super.init()
        self.nodeID = nodeID
        self.deviceController = controller
    }

    public convenience init(nodeID: UInt64, deviceController: MTRDeviceController) {
        self.init(nodeID: NSNumber(value: nodeID), controller: deviceController)
    }

    public class func device(withNodeID nodeID: NSNumber, controller: MTRDeviceController) -> MTRDevice {
        MTRDevice(nodeID: nodeID, controller: controller)
    }

    public func setDelegate(_ delegate: any MTRDeviceDelegate, queue: dispatch_queue_t) {
        _ = queue
        delegates = [MTRDeviceDelegateBox(delegate)]
        mtrDispatchState(state)
    }

    public func add(_ delegate: any MTRDeviceDelegate, queue: dispatch_queue_t) {
        _ = queue
        delegates.append(MTRDeviceDelegateBox(delegate))
        delegate.device(self, stateChanged: state)
    }

    public func add(
        _ delegate: any MTRDeviceDelegate,
        queue: dispatch_queue_t,
        interestedPathsForAttributes: [Any]?,
        interestedPathsForEvents: [Any]?
    ) {
        _ = (interestedPathsForAttributes, interestedPathsForEvents)
        add(delegate, queue: queue)
    }

    public func remove(_ delegate: any MTRDeviceDelegate) {
        let marker = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.identifier == marker }
    }

    public func readAttribute(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        params: MTRReadParams?
    ) -> [String: Any]? {
        _ = params
        return attributeCache[mtrCacheKey(endpoint: endpointID, cluster: clusterID, attribute: attributeID)]
    }

    public func readAttributePaths(_ attributePaths: [MTRAttributeRequestPath]) -> [[String: Any]] {
        attributePaths.compactMap { path in
            guard let endpoint = path.endpoint, let cluster = path.cluster, let attribute = path.attribute else {
                return nil
            }
            guard let value = readAttribute(
                withEndpointID: endpoint, clusterID: cluster, attributeID: attribute, params: nil
            ) else {
                return nil
            }
            let attrPath = MTRAttributePath(endpointID: endpoint, clusterID: cluster, attributeID: attribute)
            return MTRMakeAttributeResponse(path: attrPath, data: value)
        }
    }

    public func writeAttribute(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        value: Any,
        expectedValueInterval: NSNumber
    ) {
        mtrStoreExpected(
            endpoint: endpointID,
            cluster: clusterID,
            attribute: attributeID,
            value: value
        )
        _ = expectedValueInterval
    }

    public func writeAttribute(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        value: Any,
        expectedValueInterval: NSNumber,
        timedWriteTimeout timeout: NSNumber?
    ) {
        _ = timeout
        writeAttribute(
            withEndpointID: endpointID,
            clusterID: clusterID,
            attributeID: attributeID,
            value: value,
            expectedValueInterval: expectedValueInterval
        )
    }

    public func invokeCommand(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: [String: Any]?,
        expectedValues: [[String: Any]]?,
        expectedValueInterval: NSNumber?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, commandID, commandFields, expectedValues, expectedValueInterval, queue)
        mtrInvokeFailClosed(completion)
    }

    public func invokeCommand(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: Any,
        expectedValues: [[String: Any]]?,
        expectedValueInterval: NSNumber?,
        timedInvokeTimeout timeout: NSNumber?,
        clientQueue queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (endpointID, clusterID, commandID, commandFields, expectedValues, expectedValueInterval, timeout, queue)
        mtrInvokeFailClosed(completion)
    }

    public func invokeCommand(
        withEndpointID endpointID: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: Any,
        expectedValues: [[String: Any]]?,
        expectedValueInterval: NSNumber?,
        timedInvokeTimeout timeout: NSNumber?,
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        invokeCommand(
            withEndpointID: endpointID,
            clusterID: clusterID,
            commandID: commandID,
            commandFields: commandFields,
            expectedValues: expectedValues,
            expectedValueInterval: expectedValueInterval,
            timedInvokeTimeout: timeout,
            clientQueue: queue,
            completion: completion
        )
    }

    public func invokeCommands(
        _ commands: [[MTRCommandWithRequiredResponse]],
        queue: dispatch_queue_t,
        completion: @escaping ([[String: Any]]?, (any Error)?) -> Void
    ) {
        _ = (commands, queue)
        mtrInvokeFailClosed(completion)
    }

    public func wait(
        forAttributeValues values: [MTRAttributePath: [String: Any]],
        timeout: TimeInterval,
        queue: dispatch_queue_t,
        completion: @escaping ((any Error)?) -> Void
    ) -> MTRAttributeValueWaiter {
        _ = (values, timeout, queue)
        mtrInvokeFailClosed(completion)
        return MTRAttributeValueWaiter()
    }

    public func descriptorClusters() -> [MTRAttributePath: [String: Any]] { [:] }

    func mtrCachedAttribute(endpoint: NSNumber, cluster: String, attribute: String) -> [String: Any]? {
        attributeCache[mtrNamedKey(endpoint: endpoint, cluster: cluster, attribute: attribute)]
    }

    func mtrStoreExpected(endpoint: NSNumber, cluster: String, attribute: String, value: Any) {
        let encoded = mtrEncodeDataValue(value)
        attributeCache[mtrNamedKey(endpoint: endpoint, cluster: cluster, attribute: attribute)] = encoded
        mtrDispatchAttribute(endpoint: endpoint, clusterName: cluster, attribute: attribute, data: encoded)
    }

    func mtrStoreExpected(endpoint: NSNumber, cluster: NSNumber, attribute: NSNumber, value: Any) {
        let encoded = mtrEncodeDataValue(value)
        attributeCache[mtrCacheKey(endpoint: endpoint, cluster: cluster, attribute: attribute)] = encoded
        let path = MTRAttributePath(endpointID: endpoint, clusterID: cluster, attributeID: attribute)
        mtrDispatchAttributeReport(MTRMakeAttributeResponse(path: path, data: encoded))
    }

    public func mtrHostSetState(_ newState: MTRDeviceState) {
        state = newState
        if newState == .reachable, estimatedStartTime == nil {
            estimatedStartTime = Date()
        }
        mtrDispatchState(newState)
    }

    public func mtrHostDelegateLog() -> [String] { delegateDispatchLog }

    private func mtrDispatchState(_ newState: MTRDeviceState) {
        delegateDispatchLog.append("state:\(newState.rawValue)")
        for box in delegates {
            box.delegate?.device(self, stateChanged: newState)
        }
    }

    private func mtrDispatchAttribute(
        endpoint: NSNumber,
        clusterName: String,
        attribute: String,
        data: [String: Any]
    ) {
        _ = (endpoint, clusterName, attribute)
        let path = MTRAttributePath(endpointID: endpoint, clusterID: 0, attributeID: 0)
        mtrDispatchAttributeReport(MTRMakeAttributeResponse(path: path, data: data))
    }

    private func mtrDispatchAttributeReport(_ report: [String: Any]) {
        delegateDispatchLog.append("attribute")
        for box in delegates {
            box.delegate?.device(self, receivedAttributeReport: [report])
        }
    }

    private func mtrEncodeDataValue(_ value: Any) -> [String: Any] {
        if let dict = value as? [String: Any], dict[MTRTypeKey] is String {
            return dict
        }
        if let number = value as? NSNumber {
            return MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: number)
        }
        if let data = value as? Data {
            return MTRMakeDataValue(type: MTROctetStringValueType, value: data)
        }
        if let text = value as? String {
            return MTRMakeDataValue(type: MTRUTF8StringValueType, value: text)
        }
        if let flag = value as? Bool {
            return MTRMakeDataValue(type: MTRBooleanValueType, value: flag)
        }
        return MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: value)
    }

    private func mtrCacheKey(endpoint: NSNumber, cluster: NSNumber, attribute: NSNumber) -> String {
        "\(endpoint.uint64Value).\(cluster.uint64Value).\(attribute.uint64Value)"
    }

    private func mtrNamedKey(endpoint: NSNumber, cluster: String, attribute: String) -> String {
        "\(endpoint.uint64Value).\(cluster).\(attribute)"
    }
}

private final class MTRDeviceDelegateBox {
    weak var delegate: (any MTRDeviceDelegate)?
    let identifier: ObjectIdentifier

    init(_ delegate: any MTRDeviceDelegate) {
        self.delegate = delegate
        self.identifier = ObjectIdentifier(delegate as AnyObject)
    }
}

open class MTRDeviceController: NSObject {
    public private(set) var isRunning: Bool = false
    public var running: Bool { isRunning }
    public var uniqueIdentifier: UUID = UUID()
    public var controllerNodeID: NSNumber?
    public var compressedFabricID: NSNumber?

    public func setupCommissioningSession(with payload: MTRSetupPayload, newNodeID: NSNumber) throws {
        _ = (payload, newNodeID)
        throw MTRFailClosed(.invalidState)
    }

    public func setupCommissioningSession(
        withDiscoveredDevice discoveredDevice: MTRCommissionableBrowserResult,
        payload: MTRSetupPayload,
        newNodeID: NSNumber
    ) throws {
        _ = (discoveredDevice, payload, newNodeID)
        throw MTRFailClosed(.invalidState)
    }

    public func commissionNode(withID nodeID: NSNumber, commissioningParams: MTRCommissioningParameters) throws {
        _ = (nodeID, commissioningParams)
        throw MTRFailClosed()
    }

    public func cancelCommissioning(forNodeID nodeID: NSNumber) throws {
        _ = nodeID
        throw MTRFailClosed(.cancelled)
    }

    public func shutdown() {
        isRunning = false
        controllerNodeID = nil
    }

    public func preWarmCommissioningSession() {}

    public func devices() -> [MTRDevice] { [] }

    public func getDeviceBeingCommissioned(_ deviceId: NSNumber) throws -> MTRBaseDevice {
        _ = deviceId
        throw MTRFailClosed(.notFound)
    }
}

open class MTRDeviceControllerAbstractParameters: NSObject {
    public var startSuspended: Bool = false
}

open class MTRDeviceControllerParameters: MTRDeviceControllerAbstractParameters {
    public var uniqueIdentifier: UUID = UUID()
    public var shouldAdvertiseOperational: Bool = false
    public var concurrentSubscriptionEstablishmentsAllowedOnThread: Int = 0
    public var productAttestationAuthorityCertificates: [Data]?
    public var certificationDeclarationCertificates: [Data]?
    public var storageBehaviorConfiguration: MTRDeviceStorageBehaviorConfiguration?

    public func setOTAProviderDelegate(
        _ otaProviderDelegate: any MTROTAProviderDelegate,
        queue: dispatch_queue_t
    ) {
        _ = (otaProviderDelegate, queue)
    }

    public func setOperationalCertificateIssuer(
        _ operationalCertificateIssuer: any MTROperationalCertificateIssuer,
        queue: dispatch_queue_t
    ) {
        _ = (operationalCertificateIssuer, queue)
    }
}

open class MTRDeviceControllerStartupParams: NSObject {
    public let ipk: Data
    public let fabricID: NSNumber
    public var fabricId: UInt64 { fabricID.uint64Value }
    public var nocSigner: (any MTRKeypair)?
    public var operationalKeypair: (any MTRKeypair)?
    public var operationalCertificate: Data?
    public var intermediateCertificate: Data?
    public var rootCertificate: Data?
    public var nodeID: NSNumber?
    public var nodeId: NSNumber? {
        get { nodeID }
        set { nodeID = newValue }
    }
    public var vendorID: NSNumber?
    public var vendorId: NSNumber? {
        get { vendorID }
        set { vendorID = newValue }
    }
    public var caseAuthenticatedTags: Set<NSNumber>?
    public var operationalCertificateIssuer: (any MTROperationalCertificateIssuer)?
    public var operationalCertificateIssuerQueue: dispatch_queue_t?

    public init(ipk: Data, fabricID: NSNumber, nocSigner: any MTRKeypair) {
        self.ipk = ipk
        self.fabricID = fabricID
        self.nocSigner = nocSigner
        super.init()
    }

    public convenience init(IPK ipk: Data, fabricID: NSNumber, nocSigner: any MTRKeypair) {
        self.init(ipk: ipk, fabricID: fabricID, nocSigner: nocSigner)
    }

    public convenience init(signing nocSigner: any MTRKeypair, fabricId: UInt64, ipk: Data) {
        self.init(ipk: ipk, fabricID: NSNumber(value: fabricId), nocSigner: nocSigner)
    }

    public init(
        ipk: Data,
        operationalKeypair: any MTRKeypair,
        operationalCertificate: Data,
        intermediateCertificate: Data?,
        rootCertificate: Data
    ) {
        self.ipk = ipk
        self.fabricID = 0
        self.operationalKeypair = operationalKeypair
        self.operationalCertificate = operationalCertificate
        self.intermediateCertificate = intermediateCertificate
        self.rootCertificate = rootCertificate
        super.init()
    }

    public convenience init(
        IPK ipk: Data,
        operationalKeypair: any MTRKeypair,
        operationalCertificate: Data,
        intermediateCertificate: Data?,
        rootCertificate: Data
    ) {
        self.init(
            ipk: ipk,
            operationalKeypair: operationalKeypair,
            operationalCertificate: operationalCertificate,
            intermediateCertificate: intermediateCertificate,
            rootCertificate: rootCertificate
        )
    }

    public convenience init(
        operationalKeypair: any MTRKeypair,
        operationalCertificate: Data,
        intermediateCertificate: Data?,
        rootCertificate: Data,
        ipk: Data
    ) {
        self.init(
            ipk: ipk,
            operationalKeypair: operationalKeypair,
            operationalCertificate: operationalCertificate,
            intermediateCertificate: intermediateCertificate,
            rootCertificate: rootCertificate
        )
    }

    public func mtrValidate() throws {
        if ipk.count != 16 {
            throw MTRMakeError(.invalidArgument, reason: "Matter IPK must be 16 bytes")
        }
        if nocSigner == nil && operationalCertificate == nil {
            throw MTRMakeError(.invalidArgument, reason: "nocSigner or operational certificate is required")
        }
        if operationalCertificate == nil, fabricID.uint64Value == 0 {
            throw MTRMakeError(.invalidIntegerValue, reason: "fabricID 0 is invalid")
        }
    }
}

open class MTRDeviceControllerExternalCertificateParameters: MTRDeviceControllerParameters {}

open class MTRXPCDeviceControllerParameters: MTRDeviceControllerAbstractParameters {}

open class MTRDeviceControllerFactoryParams: NSObject {
    public var storage: (any MTRStorage)?
    public var otaProviderDelegate: (any MTROTAProviderDelegate)?
    public var productAttestationAuthorityCertificates: [Data]?
    public var certificationDeclarationCertificates: [Data]?
    public var port: NSNumber?
    public var shouldStartServer: Bool = false

    public override init() {
        super.init()
    }

    public init(storage: any MTRStorage) {
        self.storage = storage
        super.init()
    }
}

open class MTRControllerFactoryParams: MTRDeviceControllerFactoryParams {
    public var cdCerts: [Data]? {
        get { certificationDeclarationCertificates }
        set { certificationDeclarationCertificates = newValue }
    }
    public var paaCerts: [Data]? {
        get { productAttestationAuthorityCertificates }
        set { productAttestationAuthorityCertificates = newValue }
    }
    public var startServer: Bool {
        get { shouldStartServer }
        set { shouldStartServer = newValue }
    }
    public var storageDelegate: any MTRPersistentStorageDelegate {
        (storage as? MTRPersistentStorageDelegate) ?? MTRHostEmptyStorage.shared
    }
}

private final class MTRHostEmptyStorage: NSObject, MTRPersistentStorageDelegate {
    static let shared = MTRHostEmptyStorage()
    func storageData(forKey key: String) -> Data? { nil }
    func setStorageData(_ value: Data, forKey key: String) -> Bool {
        _ = (value, key)
        return false
    }
    func removeStorageData(forKey key: String) -> Bool {
        _ = key
        return false
    }
}

open class MTRDeviceControllerFactory: NSObject {
    public private(set) var isRunning: Bool = false
    public var running: Bool { isRunning }
    public var knownFabrics: [MTRFabricInfo]? { nil }

    public class func sharedInstance() -> MTRDeviceControllerFactory {
        MTRDeviceControllerFactory.shared
    }

    public static let shared = MTRDeviceControllerFactory()

    public func start(_ startupParams: MTRDeviceControllerFactoryParams) throws {
        _ = startupParams
        throw MTRFailClosed()
    }

    public func stop() {
        isRunning = false
    }

    public func preWarmCommissioningSession() {}

    public func createController(onExistingFabric startupParams: MTRDeviceControllerParameters) throws -> MTRDeviceController {
        _ = startupParams
        throw MTRFailClosed()
    }

    public func createController(onNewFabric startupParams: MTRDeviceControllerParameters) throws -> MTRDeviceController {
        _ = startupParams
        throw MTRFailClosed()
    }

    public func createController(onExistingFabric startupParams: MTRDeviceControllerStartupParams) throws -> MTRDeviceController {
        try startupParams.mtrValidate()
        throw MTRFailClosed()
    }

    public func createController(onNewFabric startupParams: MTRDeviceControllerStartupParams) throws -> MTRDeviceController {
        try startupParams.mtrValidate()
        throw MTRFailClosed()
    }
}

open class MTRControllerFactory: MTRDeviceControllerFactory {
    public static let sharedFactory = MTRControllerFactory()

    public func shutdown() {
        stop()
    }

    public func startup(_ startupParams: MTRControllerFactoryParams) -> Bool {
        do {
            try start(startupParams)
            return true
        } catch {
            return false
        }
    }

    public func startController(onExistingFabric startupParams: MTRDeviceControllerStartupParams) -> MTRDeviceController? {
        try? createController(onExistingFabric: startupParams)
    }

    public func startController(onNewFabric startupParams: MTRDeviceControllerStartupParams) -> MTRDeviceController? {
        try? createController(onNewFabric: startupParams)
    }
}

open class MTRCertificates: NSObject {
    public class func isCertificate(_ certificate1: Data, equalTo certificate2: Data) -> Bool {
        certificate1 == certificate2
    }

    public class func keypair(_ keypair: any MTRKeypair, matchesCertificate certificate: Data) -> Bool {
        _ = (keypair, certificate)
        return false
    }

    public class func convertMatterCertificate(_ matterCertificate: Data) -> Data? {
        _ = matterCertificate
        return nil
    }

    public class func convertX509Certificate(_ x509Certificate: Data) -> Data? {
        _ = x509Certificate
        return nil
    }

    public class func createCertificateSigningRequest(_ keypair: any MTRKeypair) throws -> Data {
        _ = keypair
        throw MTRFailClosed(.invalidState)
    }

    public class func generateCertificateSigningRequest(_ keypair: any MTRKeypair) throws -> Data {
        try createCertificateSigningRequest(keypair)
    }

    public class func createRootCertificate(
        _ keypair: any MTRKeypair,
        issuerID: NSNumber?,
        fabricID: NSNumber?
    ) throws -> Data {
        _ = (keypair, issuerID, fabricID)
        throw MTRFailClosed(.invalidState)
    }

    public class func generateRootCertificate(
        _ keypair: any MTRKeypair,
        issuerId: NSNumber?,
        fabricId: NSNumber?
    ) throws -> Data {
        try createRootCertificate(keypair, issuerID: issuerId, fabricID: fabricId)
    }

    public class func publicKey(fromCSR csr: Data) throws -> Data {
        _ = csr
        throw MTRFailClosed(.tlvDecodeFailed)
    }
}

open class MTRAttributeCacheContainer: NSObject {}
open class MTRClusterStateCacheContainer: NSObject {}

open class MTRAsyncCallbackQueueWorkItem: NSObject {
    public var readyHandler: MTRAsyncCallbackReadyHandler?
    public var cancelHandler: () -> Void = {}
    public var enqueued = false
    public var ended = false
    public var retryCount = 0

    public override init() {
        super.init()
    }

    public init(queue: dispatch_queue_t) {
        _ = queue
        super.init()
    }

    public func endWork() { ended = true }
    public func retryWork() { retryCount += 1 }
}

open class MTRAsyncCallbackWorkQueue: NSObject {
    private var items: [MTRAsyncCallbackQueueWorkItem] = []

    public override init() {
        super.init()
    }

    public init(context: Any?, queue: dispatch_queue_t) {
        _ = (context, queue)
        super.init()
    }

    public func enqueue(_ item: MTRAsyncCallbackQueueWorkItem) {
        item.enqueued = true
        items.append(item)
        item.readyHandler?(item, item.retryCount)
    }

    public func invalidate() {
        items.removeAll()
    }
}

open class MTRServerAttribute: NSObject {
    public var attributeID: NSNumber = 0
    public var value: Any?
}

open class MTRServerCluster: NSObject {
    public var clusterID: NSNumber = 0
    public var attributes: [MTRServerAttribute] = []
}

open class MTRServerEndpoint: NSObject {
    public var endpointID: NSNumber = 0
    public var clusters: [MTRServerCluster] = []
    public var deviceTypes: [MTRDeviceTypeRevision] = []
}
