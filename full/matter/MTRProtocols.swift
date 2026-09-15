import Foundation

public protocol MTRStorage: NSObjectProtocol {
    func storageData(forKey key: String) -> Data?
    func setStorageData(_ value: Data, forKey key: String) -> Bool
    func removeStorageData(forKey key: String) -> Bool
}

public protocol MTRPersistentStorageDelegate: MTRStorage {}

// Apple declares the members below as `@objc optional` requirements.
// Portable Swift has no `@objc optional`, so each requirement is declared
// here and given a host-inert default in MTRProtocolRequirementsWave10.swift.
// Signatures match the Xcode 26.1 symbol graph Swift spellings exactly.
public protocol MTRKeypair: NSObjectProtocol {
    func signMessageECDSA_RAW(_ message: Data) -> Data
    func signMessageECDSA_DER(_ message: Data) -> Data
}

public protocol MTRDeviceControllerStorageDelegate: NSObjectProtocol {
    func controller(
        _ controller: MTRDeviceController,
        removeValueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool
    func controller(
        _ controller: MTRDeviceController,
        storeValue value: any NSSecureCoding,
        forKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool
    func controller(
        _ controller: MTRDeviceController,
        storeValues values: [String: any NSSecureCoding],
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool
    func controller(
        _ controller: MTRDeviceController,
        valueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> (any NSSecureCoding)?
    func values(
        for controller: MTRDeviceController,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> [String: any NSSecureCoding]?
}

public protocol MTRDeviceControllerDelegate: NSObjectProtocol {
    func controller(
        _ controller: MTRDeviceController,
        commissioneeHasReceivedNetworkCredentials nodeID: NSNumber
    )
    func controller(_ controller: MTRDeviceController, commissioningComplete error: (any Error)?)
    func controller(
        _ controller: MTRDeviceController,
        commissioningComplete error: (any Error)?,
        nodeID: NSNumber?
    )
    func controller(
        _ controller: MTRDeviceController,
        commissioningComplete error: (any Error)?,
        nodeID: NSNumber?,
        metrics: MTRMetrics
    )
    func controller(
        _ controller: MTRDeviceController,
        commissioningSessionEstablishmentDone error: (any Error)?
    )
    func controller(_ controller: MTRDeviceController, read info: MTRCommissioneeInfo)
    func controller(_ controller: MTRDeviceController, readCommissioningInfo info: MTRProductIdentity)
    func controller(_ controller: MTRDeviceController, statusUpdate status: MTRCommissioningStatus)
    func controller(_ controller: MTRDeviceController, suspendedChangedTo suspended: Bool)
    func devicesChanged(for controller: MTRDeviceController)
}

public protocol MTRDevicePairingDelegate: NSObjectProtocol {
    func onCommissioningComplete(_ error: (any Error)?)
    func onPairingComplete(_ error: (any Error)?)
    func onPairingDeleted(_ error: (any Error)?)
    func onStatusUpdate(_ status: MTRPairingStatus)
}

public protocol MTRCommissionableBrowserDelegate: NSObjectProtocol {
    func controller(
        _ controller: MTRDeviceController,
        didFindCommissionableDevice device: MTRCommissionableBrowserResult
    )
    func controller(
        _ controller: MTRDeviceController,
        didRemoveCommissionableDevice device: MTRCommissionableBrowserResult
    )
}

public protocol MTRXPCServerProtocol_MTRDevice: NSObjectProtocol {}

public protocol MTRXPCServerProtocol_MTRDeviceController: NSObjectProtocol {}

public protocol MTRXPCServerProtocol: MTRXPCServerProtocol_MTRDevice, MTRXPCServerProtocol_MTRDeviceController {}

public protocol MTRNOCChainIssuer: NSObjectProtocol {
    func onNOCChainGenerationNeeded(
        _ csrInfo: CSRInfo,
        attestationInfo: AttestationInfo,
        onNOCChainGenerationComplete: @escaping MTRNOCChainGenerationCompleteHandler
    )
}

public protocol MTROperationalCertificateIssuer: NSObjectProtocol {
    var shouldSkipAttestationCertificateValidation: Bool { get }
    func issueOperationalCertificate(
        forRequest csrInfo: MTROperationalCSRInfo,
        attestationInfo: MTRDeviceAttestationInfo,
        controller: MTRDeviceController,
        completion: @escaping (MTROperationalCertificateChain?, (any Error)?) -> Void
    )
}

public protocol MTRDeviceDelegate: NSObjectProtocol {
    func device(_ device: MTRDevice, stateChanged state: MTRDeviceState)
    func device(_ device: MTRDevice, receivedAttributeReport attributeReport: [[String: Any]])
    func device(_ device: MTRDevice, receivedEventReport eventReport: [[String: Any]])
    func deviceBecameActive(_ device: MTRDevice)
    func deviceCachePrimed(_ device: MTRDevice)
    func deviceConfigurationChanged(_ device: MTRDevice)
}

extension MTRDeviceDelegate {
    public func deviceBecameActive(_ device: MTRDevice) { _ = device }
    public func deviceCachePrimed(_ device: MTRDevice) { _ = device }
    public func deviceConfigurationChanged(_ device: MTRDevice) { _ = device }
}

public protocol MTRXPCClientProtocol_MTRDevice: NSObjectProtocol {}

public protocol MTRXPCClientProtocol_MTRDeviceController: NSObjectProtocol {}

public protocol MTRXPCClientProtocol: MTRXPCClientProtocol_MTRDevice, MTRXPCClientProtocol_MTRDeviceController {}

public protocol MTRDeviceAttestationDelegate: NSObjectProtocol {
    func deviceAttestation(
        _ controller: MTRDeviceController,
        completedForDevice device: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    )
    func deviceAttestation(
        _ controller: MTRDeviceController,
        failedForDevice device: UnsafeMutableRawPointer,
        error: any Error
    )
    func deviceAttestationCompleted(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    )
    func deviceAttestationFailed(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        error: any Error
    )
}

public protocol MTROTAProviderDelegate: NSObjectProtocol {
    func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    )
    func handleApplyUpdateRequest(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterApplyUpdateResponseParams?, (any Error)?) -> Void
    )
    func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completion: @escaping (Data?, Bool) -> Void
    )
    func handleBDXQuery(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        blockSize: NSNumber,
        blockIndex: NSNumber,
        bytesToSkip: NSNumber,
        completionHandler: @escaping (Data?, Bool) -> Void
    )
    func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completion: @escaping ((any Error)?) -> Void
    )
    func handleBDXTransferSessionBegin(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        fileDesignator: String,
        offset: NSNumber,
        completionHandler: @escaping ((any Error)?) -> Void
    )
    func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        error: (any Error)?
    )
    func handleBDXTransferSessionEnd(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        metrics: MTRMetrics,
        error: (any Error)?
    )
    func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completion: @escaping ((any Error)?) -> Void
    )
    func handleNotifyUpdateApplied(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams,
        completionHandler: @escaping ((any Error)?) -> Void
    )
    func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROTASoftwareUpdateProviderClusterQueryImageParams,
        completion: @escaping (MTROTASoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    )
    func handleQueryImage(
        forNodeID nodeID: NSNumber,
        controller: MTRDeviceController,
        params: MTROtaSoftwareUpdateProviderClusterQueryImageParams,
        completionHandler: @escaping (MTROtaSoftwareUpdateProviderClusterQueryImageResponseParams?, (any Error)?) -> Void
    )
}

public protocol MTRDeviceControllerClientProtocol: NSObjectProtocol {
    func handleReport(
        withController controller: Any?,
        nodeId: UInt64,
        values: Any?,
        error: (any Error)?
    )
}

public protocol MTRDeviceControllerServerProtocol: NSObjectProtocol {
    func downloadLog(
        withController controller: Any?,
        nodeId: NSNumber,
        type: MTRDiagnosticLogType,
        timeout: TimeInterval,
        completion: @escaping (String?, (any Error)?) -> Void
    )
    func getAnyDeviceController(completion: @escaping (Any?, (any Error)?) -> Void)
    func getDeviceController(
        withFabricId fabricId: UInt64,
        completion: @escaping (Any?, (any Error)?) -> Void
    )
    func invokeCommand(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        commandId: NSNumber,
        fields: Any,
        timedInvokeTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    )
    func readAttributeCache(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    )
    func readAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        params: [String: Any]?,
        completion: @escaping (Any?, (any Error)?) -> Void
    )
    func stopReports(
        withController controller: Any?,
        nodeId: UInt64,
        completion: @escaping () -> Void
    )
    func subscribeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber?,
        clusterId: NSNumber?,
        attributeId: NSNumber?,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        establishedHandler: @escaping () -> Void
    )
    func subscribe(
        withController controller: Any?,
        nodeId: UInt64,
        minInterval: NSNumber,
        maxInterval: NSNumber,
        params: [String: Any]?,
        shouldCache: Bool,
        completion: @escaping ((any Error)?) -> Void
    )
    func writeAttribute(
        withController controller: Any?,
        nodeId: UInt64,
        endpointId: NSNumber,
        clusterId: NSNumber,
        attributeId: NSNumber,
        value: Any,
        timedWriteTimeout timeoutMs: NSNumber?,
        completion: @escaping (Any?, (any Error)?) -> Void
    )
}
