import CoreTelephony
import Dispatch
import Foundation

private func ctWaitOnce(_ semaphore: DispatchSemaphore, seconds: Double = 2) {
    precondition(semaphore.wait(timeout: .now() + seconds) == .success)
}

private final class CTBox<T>: @unchecked Sendable {
    var value: T?
}

private func ctEmptyCoder() -> NSKeyedUnarchiver {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    archiver.encode("coretelephony-linux", forKey: "probe")
    do {
        return try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
    } catch {
        preconditionFailure("unarchiver setup failed: \(error)")
    }
}

func testPlanCapabilityEnum() {
    precondition(CTCellularPlanCapability(rawValue: 0) == .dataOnly)
    precondition(CTCellularPlanCapability(rawValue: 1) == .dataAndVoice)
    precondition(CTCellularPlanCapability(rawValue: 8) == nil)
    precondition(CTCellularPlanCapability.dataOnly != .dataAndVoice)
    precondition(
        CTCellularPlanCapability.dataOnly.hashValue
            != CTCellularPlanCapability.dataAndVoice.hashValue
    )
    var hasher = Hasher()
    CTCellularPlanCapability.dataAndVoice.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddPlanResultEnum() {
    precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 0) == .unknown)
    precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 1) == .fail)
    precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 2) == .success)
    precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 3) == .cancel)
    precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 4) == nil)
    precondition(
        CTCellularPlanProvisioningAddPlanResult.fail
            != CTCellularPlanProvisioningAddPlanResult.success
    )
    precondition(
        CTCellularPlanProvisioningAddPlanResult.fail.hashValue
            != CTCellularPlanProvisioningAddPlanResult.success.hashValue
    )
    var hasher = Hasher()
    CTCellularPlanProvisioningAddPlanResult.cancel.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPlanPropertiesStorage() {
    let properties = CTCellularPlanProperties()
    properties.associatedIccid = "890000"
    properties.simCapability = .dataAndVoice
    properties.supportedRegionCodes = [Locale.Region("US")]
    precondition(properties.associatedIccid == "890000")
    precondition(properties.simCapability == .dataAndVoice)
    precondition(properties.supportedRegionCodes == [Locale.Region("US")])
}

func testPlanPropertiesInitCoder() {
    precondition(CTCellularPlanProperties(coder: ctEmptyCoder()) == nil)
}

func testPlanRequestStorage() {
    let request = CTCellularPlanProvisioningRequest()
    precondition(request.address.isEmpty)
    request.address = "https://example.test/esim"
    request.matchingID = "match"
    request.oid = "oid"
    request.confirmationCode = "code"
    request.iccid = "iccid"
    request.eid = "eid"
    precondition(request.address == "https://example.test/esim")
    precondition(request.matchingID == "match")
    precondition(request.oid == "oid")
    precondition(request.confirmationCode == "code")
    precondition(request.iccid == "iccid")
    precondition(request.eid == "eid")
}

func testPlanRequestInitCoder() {
    precondition(CTCellularPlanProvisioningRequest(coder: ctEmptyCoder()) == nil)
}

func testPlanProvisioningFailClosed() {
    let request = CTCellularPlanProvisioningRequest()
    request.address = "https://example.test/esim"
    let properties = CTCellularPlanProperties()
    let provisioning = CTCellularPlanProvisioning()
    precondition(provisioning.supportsCellularPlan() == false)
    precondition(provisioning.supportsEmbeddedSIM == false)

    let addSemaphore = DispatchSemaphore(value: 0)
    var addInline = false
    var addResult: CTCellularPlanProvisioningAddPlanResult?
    provisioning.addPlan(with: request) { result in
        addInline = true
        addResult = result
        addSemaphore.signal()
    }
    precondition(!addInline)
    ctWaitOnce(addSemaphore)
    precondition(addResult == .fail)

    let asyncBox = CTBox<CTCellularPlanProvisioningAddPlanResult>()
    let asyncSemaphore = DispatchSemaphore(value: 0)
    Task {
        asyncBox.value = await provisioning.addPlan(with: request)
        asyncSemaphore.signal()
    }
    ctWaitOnce(asyncSemaphore)
    precondition(asyncBox.value == .fail)

    let propsBox = CTBox<CTCellularPlanProvisioningAddPlanResult>()
    let propsSemaphore = DispatchSemaphore(value: 0)
    Task {
        propsBox.value = await provisioning.addPlan(request: request, properties: properties)
        propsSemaphore.signal()
    }
    ctWaitOnce(propsSemaphore)
    precondition(propsBox.value == .fail)

    let updateSemaphore = DispatchSemaphore(value: 0)
    var updateError: (any Error)?
    var updateInline = false
    provisioning.update(properties) { error in
        updateInline = true
        updateError = error
        updateSemaphore.signal()
    }
    precondition(!updateInline)
    ctWaitOnce(updateSemaphore)
    precondition(updateError != nil)
    precondition((updateError as NSError?)?.domain == NSPOSIXErrorDomain)

    let throwBox = CTBox<Bool>()
    let throwSemaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            try await provisioning.update(properties)
            throwBox.value = false
        } catch {
            throwBox.value = (error as NSError).domain == NSPOSIXErrorDomain
        }
        throwSemaphore.signal()
    }
    ctWaitOnce(throwSemaphore)
    precondition(throwBox.value == true)
}

func testPlanStatusFailClosed() {
    let tokenSemaphore = DispatchSemaphore(value: 0)
    var token: String? = "sentinel"
    var tokenError: (any Error)?
    var tokenInline = false
    CTCellularPlanStatus.getTokenWithCompletion { value, error in
        tokenInline = true
        token = value
        tokenError = error
        tokenSemaphore.signal()
    }
    precondition(!tokenInline)
    ctWaitOnce(tokenSemaphore)
    precondition(token == nil)
    precondition(tokenError != nil)
    precondition((tokenError as NSError?)?.domain == NSPOSIXErrorDomain)

    let validityBox = CTBox<Bool>()
    let validitySemaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            _ = try await CTCellularPlanStatus.checkValidity(ofToken: "token")
            validityBox.value = false
        } catch {
            validityBox.value = (error as NSError).domain == NSPOSIXErrorDomain
        }
        validitySemaphore.signal()
    }
    ctWaitOnce(validitySemaphore)
    precondition(validityBox.value == true)
}
