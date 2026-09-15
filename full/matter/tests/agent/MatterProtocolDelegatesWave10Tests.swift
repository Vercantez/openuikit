import Foundation
import Matter

private final class Wave10PairingRecorder: NSObject, MTRDevicePairingDelegate {
    var commissioningErrors: [(any Error)?] = []
    var pairingErrors: [(any Error)?] = []
    var deletedErrors: [(any Error)?] = []
    var statuses: [MTRPairingStatus] = []
    func onCommissioningComplete(_ error: (any Error)?) { commissioningErrors.append(error) }
    func onPairingComplete(_ error: (any Error)?) { pairingErrors.append(error) }
    func onPairingDeleted(_ error: (any Error)?) { deletedErrors.append(error) }
    func onStatusUpdate(_ status: MTRPairingStatus) { statuses.append(status) }
}

func testWave10PairingDelegateCallbacks() {
    let stub = Wave10PairingRecorder()
    let delegate: any MTRDevicePairingDelegate = stub
    delegate.onCommissioningComplete(nil)
    delegate.onPairingComplete(nil)
    delegate.onPairingDeleted(nil)
    delegate.onStatusUpdate(.success)
    mtrRequire(stub.commissioningErrors.count == 1, "onCommissioningComplete dispatches")
    mtrRequire(stub.pairingErrors.count == 1, "onPairingComplete dispatches")
    mtrRequire(stub.deletedErrors.count == 1, "onPairingDeleted dispatches")
    mtrRequire(stub.statuses == [.success], "onStatusUpdate records status")
}

private final class Wave10ControllerDelegateRecorder: NSObject, MTRDeviceControllerDelegate {
    var networkCredentialNodes: [NSNumber] = []
    var completeErrors: [(any Error)?] = []
    var completeNodeIDs: [NSNumber?] = []
    var completeMetrics: [MTRMetrics] = []
    var sessionErrors: [(any Error)?] = []
    var commissioneeInfos: [MTRCommissioneeInfo] = []
    var commissioningInfos: [MTRProductIdentity] = []
    var statuses: [MTRCommissioningStatus] = []
    var suspended: [Bool] = []
    var devicesChangedCount = 0
    func controller(_ controller: MTRDeviceController, commissioneeHasReceivedNetworkCredentials nodeID: NSNumber) {
        _ = controller
        networkCredentialNodes.append(nodeID)
    }
    func controller(_ controller: MTRDeviceController, commissioningComplete error: (any Error)?) {
        _ = controller
        completeErrors.append(error)
    }
    func controller(_ controller: MTRDeviceController, commissioningComplete error: (any Error)?, nodeID: NSNumber?) {
        _ = (controller, error)
        completeNodeIDs.append(nodeID)
    }
    func controller(
        _ controller: MTRDeviceController,
        commissioningComplete error: (any Error)?,
        nodeID: NSNumber?,
        metrics: MTRMetrics
    ) {
        _ = (controller, error, nodeID)
        completeMetrics.append(metrics)
    }
    func controller(_ controller: MTRDeviceController, commissioningSessionEstablishmentDone error: (any Error)?) {
        _ = controller
        sessionErrors.append(error)
    }
    func controller(_ controller: MTRDeviceController, read info: MTRCommissioneeInfo) {
        _ = controller
        commissioneeInfos.append(info)
    }
    func controller(_ controller: MTRDeviceController, readCommissioningInfo info: MTRProductIdentity) {
        _ = controller
        commissioningInfos.append(info)
    }
    func controller(_ controller: MTRDeviceController, statusUpdate status: MTRCommissioningStatus) {
        _ = controller
        statuses.append(status)
    }
    func controller(_ controller: MTRDeviceController, suspendedChangedTo suspended: Bool) {
        _ = controller
        self.suspended.append(suspended)
    }
    func devicesChanged(for controller: MTRDeviceController) {
        _ = controller
        devicesChangedCount += 1
    }
}

func testWave10ControllerCommissioningCallbacks() {
    let stub = Wave10ControllerDelegateRecorder()
    let delegate: any MTRDeviceControllerDelegate = stub
    let controller = MTRDeviceController()
    delegate.controller(controller, commissioneeHasReceivedNetworkCredentials: NSNumber(value: 11))
    delegate.controller(controller, commissioningComplete: nil)
    delegate.controller(controller, commissioningComplete: nil, nodeID: NSNumber(value: 12))
    delegate.controller(controller, commissioningComplete: nil, nodeID: NSNumber(value: 13), metrics: MTRMetrics())
    delegate.controller(controller, commissioningSessionEstablishmentDone: nil)
    delegate.controller(controller, statusUpdate: .success)
    mtrRequire(stub.networkCredentialNodes == [NSNumber(value: 11)], "network credentials node recorded")
    mtrRequire(stub.completeErrors.count == 1, "commissioningComplete dispatches")
    mtrRequire(stub.completeNodeIDs.count == 1 && stub.completeNodeIDs[0] == NSNumber(value: 12), "commissioning nodeID recorded")
    mtrRequire(stub.completeMetrics.count == 1, "commissioning metrics recorded")
    mtrRequire(stub.sessionErrors.count == 1, "session establishment dispatches")
    mtrRequire(stub.statuses == [.success], "status update recorded")
}

func testWave10ControllerInfoCallbacks() {
    let stub = Wave10ControllerDelegateRecorder()
    let delegate: any MTRDeviceControllerDelegate = stub
    let controller = MTRDeviceController()
    delegate.controller(controller, read: MTRCommissioneeInfo())
    delegate.controller(controller, readCommissioningInfo: MTRProductIdentity(vendorID: 1, productID: 2))
    delegate.controller(controller, suspendedChangedTo: true)
    delegate.devicesChanged(for: controller)
    mtrRequire(stub.commissioneeInfos.count == 1, "read commissionee info dispatches")
    mtrRequire(stub.commissioningInfos.count == 1, "read commissioning info dispatches")
    mtrRequire(stub.suspended == [true], "suspended change recorded")
    mtrRequire(stub.devicesChangedCount == 1, "devices changed dispatches")
}

private final class Wave10BrowserRecorder: NSObject, MTRCommissionableBrowserDelegate {
    var found: [MTRCommissionableBrowserResult] = []
    var removed: [MTRCommissionableBrowserResult] = []
    func controller(_ controller: MTRDeviceController, didFindCommissionableDevice device: MTRCommissionableBrowserResult) {
        _ = controller
        found.append(device)
    }
    func controller(_ controller: MTRDeviceController, didRemoveCommissionableDevice device: MTRCommissionableBrowserResult) {
        _ = controller
        removed.append(device)
    }
}

private final class Wave10AttestationRecorder: NSObject, MTRDeviceAttestationDelegate {
    var completedCount = 0
    var failedCount = 0
    var legacyCompletedCount = 0
    var legacyFailedCount = 0
    func deviceAttestation(
        _ controller: MTRDeviceController,
        completedForDevice device: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    ) {
        _ = (controller, device, attestationDeviceInfo, error)
        completedCount += 1
    }
    func deviceAttestation(
        _ controller: MTRDeviceController,
        failedForDevice device: UnsafeMutableRawPointer,
        error: any Error
    ) {
        _ = (controller, device, error)
        failedCount += 1
    }
    func deviceAttestationCompleted(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        attestationDeviceInfo: MTRDeviceAttestationDeviceInfo,
        error: (any Error)?
    ) {
        _ = (controller, opaqueDeviceHandle, attestationDeviceInfo, error)
        legacyCompletedCount += 1
    }
    func deviceAttestationFailed(
        for controller: MTRDeviceController,
        opaqueDeviceHandle: UnsafeMutableRawPointer,
        error: any Error
    ) {
        _ = (controller, opaqueDeviceHandle, error)
        legacyFailedCount += 1
    }
}

func testWave10BrowserAttestationCallbacks() {
    let browser = Wave10BrowserRecorder()
    let browserDelegate: any MTRCommissionableBrowserDelegate = browser
    let controller = MTRDeviceController()
    browserDelegate.controller(controller, didFindCommissionableDevice: MTRCommissionableBrowserResult())
    browserDelegate.controller(controller, didRemoveCommissionableDevice: MTRCommissionableBrowserResult())
    mtrRequire(browser.found.count == 1, "didFind dispatches")
    mtrRequire(browser.removed.count == 1, "didRemove dispatches")
    let attestation = Wave10AttestationRecorder()
    let attestationDelegate: any MTRDeviceAttestationDelegate = attestation
    let handle = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { handle.deallocate() }
    let info = MTRDeviceAttestationDeviceInfo()
    attestationDelegate.deviceAttestation(controller, completedForDevice: handle, attestationDeviceInfo: info, error: nil)
    attestationDelegate.deviceAttestationCompleted(for: controller, opaqueDeviceHandle: handle, attestationDeviceInfo: info, error: nil)
    mtrRequire(attestation.completedCount == 1, "attestation completed dispatches")
    mtrRequire(attestation.legacyCompletedCount == 1, "legacy attestation completed dispatches")
}

func testWave10AttestationFailureCallbacks() {
    let attestation = Wave10AttestationRecorder()
    let attestationDelegate: any MTRDeviceAttestationDelegate = attestation
    let controller = MTRDeviceController()
    let handle = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { handle.deallocate() }
    struct Wave10ProbeError: Error {}
    attestationDelegate.deviceAttestation(controller, failedForDevice: handle, error: Wave10ProbeError())
    attestationDelegate.deviceAttestationFailed(for: controller, opaqueDeviceHandle: handle, error: Wave10ProbeError())
    mtrRequire(attestation.failedCount == 1, "attestation failed dispatches")
    mtrRequire(attestation.legacyFailedCount == 1, "legacy attestation failed dispatches")
}

final class Wave10SecureBox: NSObject, NSSecureCoding {
    let tag: Int
    init(tag: Int) {
        self.tag = tag
        super.init()
    }
    static var supportsSecureCoding: Bool { true }
    func encode(with coder: NSCoder) { coder.encode(tag, forKey: "tag") }
    required init?(coder: NSCoder) {
        tag = coder.decodeInteger(forKey: "tag")
        super.init()
    }
}

private final class Wave10StorageRecorder: NSObject, MTRDeviceControllerStorageDelegate {
    var box: [String: any NSSecureCoding] = [:]
    func controller(
        _ controller: MTRDeviceController,
        removeValueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, securityLevel, sharingType)
        return box.removeValue(forKey: key) != nil
    }
    func controller(
        _ controller: MTRDeviceController,
        storeValue value: any NSSecureCoding,
        forKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, securityLevel, sharingType)
        box[key] = value
        return true
    }
    func controller(
        _ controller: MTRDeviceController,
        storeValues values: [String: any NSSecureCoding],
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> Bool {
        _ = (controller, securityLevel, sharingType)
        for (key, value) in values {
            box[key] = value
        }
        return true
    }
    func controller(
        _ controller: MTRDeviceController,
        valueForKey key: String,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> (any NSSecureCoding)? {
        _ = (controller, securityLevel, sharingType)
        return box[key]
    }
    func values(
        for controller: MTRDeviceController,
        securityLevel: MTRStorageSecurityLevel,
        sharingType: MTRStorageSharingType
    ) -> [String: any NSSecureCoding]? {
        _ = (controller, securityLevel, sharingType)
        return box
    }
}

func testWave10ControllerStorageDelegateCallbacks() {
    let stub = Wave10StorageRecorder()
    let delegate: any MTRDeviceControllerStorageDelegate = stub
    let controller = MTRDeviceController()
    let stored = Wave10SecureBox(tag: 7)
    mtrRequire(
        delegate.controller(controller, storeValue: stored, forKey: "k", securityLevel: .secure, sharingType: .notShared),
        "storeValue sticks"
    )
    let fetched = delegate.controller(controller, valueForKey: "k", securityLevel: .secure, sharingType: .notShared)
    mtrRequire((fetched as? Wave10SecureBox)?.tag == 7, "valueForKey round-trips")
    mtrRequire(
        delegate.controller(
            controller,
            storeValues: ["j": Wave10SecureBox(tag: 9)],
            securityLevel: .secure,
            sharingType: .notShared
        ),
        "storeValues sticks"
    )
    let snapshot = delegate.values(for: controller, securityLevel: .secure, sharingType: .notShared)
    mtrRequire(snapshot?.count == 2, "values snapshot covers both keys")
    mtrRequire(
        delegate.controller(controller, removeValueForKey: "k", securityLevel: .secure, sharingType: .notShared),
        "removeValueForKey reports removal"
    )
    mtrRequire(
        delegate.controller(controller, valueForKey: "k", securityLevel: .secure, sharingType: .notShared) == nil,
        "removed key reads nil"
    )
}

private final class Wave10KeypairEcho: NSObject, MTRKeypair {
    func signMessageECDSA_RAW(_ message: Data) -> Data { message }
    func signMessageECDSA_DER(_ message: Data) -> Data { message }
}

func testWave10KeypairSignWitnesses() {
    let stub = Wave10KeypairEcho()
    let keypair: any MTRKeypair = stub
    mtrRequire(keypair.signMessageECDSA_RAW(Data([0x01])) == Data([0x01]), "RAW witness echoes")
    mtrRequire(keypair.signMessageECDSA_DER(Data([0x02])) == Data([0x02]), "DER witness echoes")
}
