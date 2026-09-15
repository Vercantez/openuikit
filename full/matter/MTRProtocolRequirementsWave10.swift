import Foundation

// Host-inert defaults for the `@objc optional` delegate/storage/XPC protocol
// requirements declared in MTRProtocols.swift. There is no Matter fabric,
// commissioning daemon, or XPC controller service on Linux, so nothing ever
// invokes these callbacks; the defaults accept-and-ignore so host code
// compiles, mirroring Apple's optional semantics as closely as portable
// Swift allows. Record-and-assert behavior lives in the tests, which
// override every requirement with a recording stub.

extension MTRDeviceControllerStorageDelegate {
    public func controller(
        _ controller: MTRDeviceController,
        removeValueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, key, securityLevel, sharingType)
        return false
    }

    public func controller(
        _ controller: MTRDeviceController,
        storeValue value: any NSSecureCoding,
        forKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, value, key, securityLevel, sharingType)
        return false
    }

    public func controller(
        _ controller: MTRDeviceController,
        storeValues values: [String: any NSSecureCoding],
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, values, securityLevel, sharingType)
        return false
    }

    public func controller(
        _ controller: MTRDeviceController,
        valueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> (any NSSecureCoding)? {
        _ = (controller, key, securityLevel, sharingType)
        return nil
    }

    public func values(
        for controller: MTRDeviceController,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> [String: any NSSecureCoding]? {
        _ = (controller, securityLevel, sharingType)
        return nil
    }
}

extension MTRDeviceControllerDelegate {
    public func controller(
        _ controller: MTRDeviceController,
        commissioneeHasReceivedNetworkCredentials nodeID: NSNumber
    ) {
        _ = (controller, nodeID)
    }

    public func controller(_ controller: MTRDeviceController, commissioningComplete error: (any Error)?) {
        _ = (controller, error)
    }

    public func controller(
        _ controller: MTRDeviceController,
        commissioningComplete error: (any Error)?,
        nodeID: NSNumber?
    ) {
        _ = (controller, error, nodeID)
    }

    public func controller(
        _ controller: MTRDeviceController,
        commissioningComplete error: (any Error)?,
        nodeID: NSNumber?,
        metrics: MTRMetrics
    ) {
        _ = (controller, error, nodeID, metrics)
    }

    public func controller(
        _ controller: MTRDeviceController,
        commissioningSessionEstablishmentDone error: (any Error)?
    ) {
        _ = (controller, error)
    }

    public func controller(_ controller: MTRDeviceController, read info: MTRCommissioneeInfo) {
        _ = (controller, info)
    }

    public func controller(_ controller: MTRDeviceController, readCommissioningInfo info: MTRProductIdentity) {
        _ = (controller, info)
    }

    public func controller(_ controller: MTRDeviceController, statusUpdate status: MTRCommissioningStatus) {
        _ = (controller, status)
    }

    public func controller(_ controller: MTRDeviceController, suspendedChangedTo suspended: Bool) {
        _ = (controller, suspended)
    }

    public func devicesChanged(for controller: MTRDeviceController) {
        _ = controller
    }
}

extension MTRDevicePairingDelegate {
    public func onCommissioningComplete(_ error: (any Error)?) { _ = error }
    public func onPairingComplete(_ error: (any Error)?) { _ = error }
    public func onPairingDeleted(_ error: (any Error)?) { _ = error }
    public func onStatusUpdate(_ status: MTRPairingStatus) { _ = status }
}

extension MTRCommissionableBrowserDelegate {
    public func controller(
        _ controller: MTRDeviceController,
        didFindCommissionableDevice device: MTRCommissionableBrowserResult
    ) {
        _ = (controller, device)
    }

    public func controller(
        _ controller: MTRDeviceController,
        didRemoveCommissionableDevice device: MTRCommissionableBrowserResult
    ) {
        _ = (controller, device)
    }
}

extension MTRDeviceAttestationDelegate {
    public func deviceAttestation(
        _ controller: MTRDeviceController,
        completedForDevice device: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    ) {
        _ = (controller, device, attestationDeviceInfo, error)
    }

    public func deviceAttestation(
        _ controller: MTRDeviceController,
        failedForDevice device: UnsafeMutableRawPointer,
        error: any Error
    ) {
        _ = (controller, device, error)
    }

    public func deviceAttestationCompleted(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    ) {
        _ = (controller, opaqueDeviceHandle, attestationDeviceInfo, error)
    }

    public func deviceAttestationFailed(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        error: any Error
    ) {
        _ = (controller, opaqueDeviceHandle, error)
    }
}

extension MTRNOCChainIssuer {
    public func onNOCChainGenerationNeeded(
        _ csrInfo: CSRInfo,
        attestationInfo: AttestationInfo,
        onNOCChainGenerationComplete: @escaping MTRNOCChainGenerationCompleteHandler
    ) {
        _ = (csrInfo, attestationInfo, onNOCChainGenerationComplete)
    }
}

extension MTROperationalCertificateIssuer {
    public var shouldSkipAttestationCertificateValidation: Bool { false }

    public func issueOperationalCertificate(
        forRequest csrInfo: MTROperationalCSRInfo,
        attestationInfo: MTRDeviceAttestationInfo,
        controller: MTRDeviceController,
        completion: @escaping (MTROperationalCertificateChain?, (any Error)?) -> Void
    ) {
        _ = (csrInfo, attestationInfo, controller, completion)
    }
}

extension MTROTAProviderDelegate {
    public func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
    }

    public func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
    }

    public func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completion: @escaping (Data?, Bool) -> Void
    ) {
        _ = (nodeID, controller, blockSize, blockIndex, bytesToSkip, completion)
    }

    public func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completionHandler: @escaping (Data?, Bool) -> Void
    ) {
        _ = (nodeID, controller, blockSize, blockIndex, bytesToSkip, completionHandler)
    }

    public func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, fileDesignator, offset, completion)
    }

    public func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, fileDesignator, offset, completionHandler)
    }

    public func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        error: (any Error)?
    ) {
        _ = (nodeID, controller, error)
    }

    public func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        metrics: MTRMetrics,
        error: (any Error)?
    ) {
        _ = (nodeID, controller, metrics, error)
    }

    public func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
    }

    public func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
    }

    public func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterQueryImageParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completion)
    }

    public func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterQueryImageParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    ) {
        _ = (nodeID, controller, params, completionHandler)
    }
}

extension MTRDeviceControllerClientProtocol {
    public func handleReport(
        withController controller: Any?,
        nodeId: UInt64,
        values: Any?,
        error: (any Error)?
    ) {
        _ = (controller, nodeId, values, error)
    }
}

extension MTRDeviceControllerServerProtocol {
    public func downloadLog(
        withController controller: Any?,
        nodeId: NSNumber,
        type: MTRDiagnosticLogType,
        timeout: TimeInterval,
        completion: @escaping (String?, (any Error)?) -> Void
    ) {
        _ = (controller, nodeId, type, timeout, completion)
    }

    public func getAnyDeviceController(completion: @escaping (Any?, (any Error)?) -> Void) {
        _ = completion
    }

    public func getDeviceController(
        withFabricId fabricId: UInt64,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (fabricId, completion)
    }

    public func invokeCommand(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        commandId: NSNumber,
        fields: Any,
        timedInvokeTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, nodeId, endpointId, clusterId, commandId, fields, timeoutMs, completion)
    }

    public func readAttributeCache(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, nodeId, endpointId, clusterId, attributeId, completion)
    }

    public func readAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        params: [String: Any]?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, nodeId, endpointId, clusterId, attributeId, params, completion)
    }

    public func stopReports(
        withController controller: Any?,
        nodeId: UInt64,
        completion: @escaping () -> Void
    ) {
        _ = (controller, nodeId, completion)
    }

    public func subscribeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        establishedHandler: @escaping () -> Void
    ) {
        _ = (controller, nodeId, endpointId, clusterId, attributeId, minInterval, maxInterval, params, establishedHandler)
    }

    public func subscribe(
        withController controller: Any?,
        nodeId: UInt64,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        shouldCache: Bool,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (controller, nodeId, minInterval, maxInterval, params, shouldCache, completion)
    }

    public func writeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        attributeId: NSNumber,
        value: Any,
        timedWriteTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    ) {
        _ = (controller, nodeId, endpointId, clusterId, attributeId, value, timeoutMs, completion)
    }
}
