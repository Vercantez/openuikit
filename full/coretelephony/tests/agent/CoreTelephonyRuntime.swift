import CoreTelephony
import Foundation

private final class RecordingSubscriberDelegate: NSObject, CTSubscriberDelegate {
    var refreshed: CTSubscriber?

    func subscriberTokenRefreshed(_ subscriber: CTSubscriber) {
        refreshed = subscriber
    }
}

private final class RecordingNetworkDelegate: NSObject, CTTelephonyNetworkInfoDelegate {
    var changedIdentifier: String?

    func dataServiceIdentifierDidChange(_ identifier: String) {
        changedIdentifier = identifier
    }
}

enum CoreTelephonyRuntime {
    static func main() async {
        exerciseConstants()
        exerciseErrorSurface()
        exerciseEnums()
        exerciseCallAndCarrier()
        await exerciseCellularData()
        exerciseSubscriber()
        exerciseNetworkInfo()
        await exerciseCellularPlan()
        try! exercisePlanCoding()

        print("CORETELEPHONY_AGENT_RUNTIME_OK")
    }

    private static func exerciseConstants() {
        let radio = [
            CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMA1x,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
            CTRadioAccessTechnologyeHRPD,
            CTRadioAccessTechnologyLTE,
            CTRadioAccessTechnologyNRNSA,
            CTRadioAccessTechnologyNR,
        ]
        precondition(Set(radio).count == radio.count)
        precondition(radio.allSatisfy { !$0.isEmpty })
        precondition(!CTCallStateDialing.isEmpty)
        precondition(!CTCallStateIncoming.isEmpty)
        precondition(!CTCallStateConnected.isEmpty)
        precondition(!CTCallStateDisconnected.isEmpty)
        precondition(!CTSubscriberTokenRefreshed.isEmpty)
        precondition(!NSNotification.Name.CTRadioAccessTechnologyDidChange.rawValue.isEmpty)
        precondition(!NSNotification.Name.CTServiceRadioAccessTechnologyDidChange.rawValue.isEmpty)
    }

    private static func exerciseErrorSurface() {
        precondition(kCTErrorDomainNoError == 0)
        precondition(kCTErrorDomainPOSIX == 1)
        precondition(kCTErrorDomainMach == 2)

        let zero = CTError()
        precondition(zero.domain == 0)
        precondition(zero.error == 0)

        var error = CTError(domain: Int32(kCTErrorDomainPOSIX), error: 2)
        precondition(error.domain == 1)
        precondition(error.error == 2)
        error.domain = Int32(kCTErrorDomainMach)
        error.error = 5
        precondition(error.domain == 2)
        precondition(error.error == 5)
    }

    private static func exerciseEnums() {
        precondition(CTCellularDataRestrictedState.restrictedStateUnknown.rawValue == 0)
        precondition(CTCellularDataRestrictedState.restricted.rawValue == 1)
        precondition(CTCellularDataRestrictedState.notRestricted.rawValue == 2)
        precondition(CTCellularDataRestrictedState(rawValue: 1) == .restricted)
        precondition(CTCellularDataRestrictedState(rawValue: 99) == nil)
        precondition(CTCellularDataRestrictedState.restricted != .notRestricted)
        precondition(
            CTCellularDataRestrictedState.restricted.hashValue
                != CTCellularDataRestrictedState.notRestricted.hashValue
        )
        var hasher = Hasher()
        CTCellularDataRestrictedState.restricted.hash(into: &hasher)

        precondition(CTCellularPlanCapability.dataOnly.rawValue == 0)
        precondition(CTCellularPlanCapability.dataAndVoice.rawValue == 1)
        precondition(CTCellularPlanCapability(rawValue: 1) == .dataAndVoice)
        precondition(CTCellularPlanCapability.dataOnly != .dataAndVoice)
        precondition(
            CTCellularPlanCapability.dataOnly.hashValue
                != CTCellularPlanCapability.dataAndVoice.hashValue
        )
        hasher = Hasher()
        CTCellularPlanCapability.dataAndVoice.hash(into: &hasher)

        precondition(CTCellularPlanProvisioningAddPlanResult.unknown.rawValue == 0)
        precondition(CTCellularPlanProvisioningAddPlanResult.fail.rawValue == 1)
        precondition(CTCellularPlanProvisioningAddPlanResult.success.rawValue == 2)
        precondition(CTCellularPlanProvisioningAddPlanResult.cancel.rawValue == 3)
        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 2) == .success)
        precondition(CTCellularPlanProvisioningAddPlanResult.fail != .success)
        precondition(
            CTCellularPlanProvisioningAddPlanResult.fail.hashValue
                != CTCellularPlanProvisioningAddPlanResult.success.hashValue
        )
        hasher = Hasher()
        CTCellularPlanProvisioningAddPlanResult.cancel.hash(into: &hasher)
    }

    private static func exerciseCallAndCarrier() {
        let call = CTCall()
        precondition(call.callState == CTCallStateDisconnected)
        precondition(call.callID.isEmpty)

        let center = CTCallCenter()
        precondition(center.currentCalls == nil)
        var handlerFired = false
        center.callEventHandler = { _ in handlerFired = true }
        precondition(center.callEventHandler != nil)
        precondition(handlerFired == false)

        let carrier = CTCarrier()
        precondition(carrier.carrierName == nil)
        precondition(carrier.mobileCountryCode == nil)
        precondition(carrier.mobileNetworkCode == nil)
        precondition(carrier.isoCountryCode == nil)
        precondition(carrier.allowsVOIP == false)
    }

    private static func exerciseCellularData() async {
        let data = CTCellularData()
        precondition(data.restrictedState == .restrictedStateUnknown)

        data.cellularDataRestrictionDidUpdateNotifier = nil
        precondition(data.cellularDataRestrictionDidUpdateNotifier == nil)

        let firstState = await withCheckedContinuation {
            (continuation: CheckedContinuation<CTCellularDataRestrictedState, Never>) in
            data.cellularDataRestrictionDidUpdateNotifier = { state in
                continuation.resume(returning: state)
            }
        }
        precondition(firstState == .restrictedStateUnknown)
        precondition(data.cellularDataRestrictionDidUpdateNotifier != nil)

        var laterCount = 0
        data.cellularDataRestrictionDidUpdateNotifier = { _ in
            laterCount += 1
        }
        try! await Task.sleep(nanoseconds: 80_000_000)
        precondition(laterCount == 0)

        data.cellularDataRestrictionDidUpdateNotifier = nil
        data.cellularDataRestrictionDidUpdateNotifier = { _ in
            laterCount += 1
        }
        try! await Task.sleep(nanoseconds: 80_000_000)
        precondition(laterCount == 0)
    }

    private static func exerciseSubscriber() {
        let subscriber = CTSubscriber()
        precondition(subscriber.carrierToken == nil)
        precondition(subscriber.refreshCarrierToken() == false)
        precondition(subscriber.identifier.isEmpty)
        precondition(subscriber.isSIMInserted == false)

        let delegate = RecordingSubscriberDelegate()
        subscriber.delegate = delegate
        precondition(subscriber.delegate === delegate)
        delegate.subscriberTokenRefreshed(subscriber)
        precondition(delegate.refreshed === subscriber)

        precondition(CTSubscriberInfo.subscribers().isEmpty)
        let legacy = CTSubscriberInfo.subscriber()
        precondition(legacy.isSIMInserted == false)
        precondition(legacy.carrierToken == nil)
    }

    private static func exerciseNetworkInfo() {
        let info = CTTelephonyNetworkInfo()
        precondition(info.currentRadioAccessTechnology == nil)
        precondition(info.serviceCurrentRadioAccessTechnology == nil)
        precondition(info.subscriberCellularProvider == nil)
        precondition(info.serviceSubscriberCellularProviders == nil)
        precondition(info.dataServiceIdentifier == nil)

        let delegate = RecordingNetworkDelegate()
        info.delegate = delegate
        precondition(info.delegate === delegate)
        delegate.dataServiceIdentifierDidChange("data-service")
        precondition(delegate.changedIdentifier == "data-service")

        var serviceNotifierFired = false
        var providerNotifierFired = false
        info.serviceSubscriberCellularProvidersDidUpdateNotifier = { _ in
            serviceNotifierFired = true
        }
        info.subscriberCellularProviderDidUpdateNotifier = { _ in
            providerNotifierFired = true
        }
        precondition(info.serviceSubscriberCellularProvidersDidUpdateNotifier != nil)
        precondition(info.subscriberCellularProviderDidUpdateNotifier != nil)
        precondition(serviceNotifierFired == false)
        precondition(providerNotifierFired == false)
    }

    private static func exerciseCellularPlan() async {
        let request = CTCellularPlanProvisioningRequest()
        precondition(request.address.isEmpty)
        request.address = "https://example.invalid/esim"
        request.matchingID = "match"
        request.oid = "oid"
        request.confirmationCode = "code"
        request.iccid = "8900"
        request.eid = "eid"
        precondition(request.address.hasPrefix("https://"))
        precondition(request.matchingID == "match")
        precondition(request.oid == "oid")
        precondition(request.confirmationCode == "code")
        precondition(request.iccid == "8900")
        precondition(request.eid == "eid")

        let properties = CTCellularPlanProperties()
        precondition(properties.associatedIccid == nil)
        precondition(properties.simCapability == .dataOnly)
        precondition(properties.supportedRegionCodes.isEmpty)
        properties.associatedIccid = "8900"
        properties.simCapability = .dataAndVoice
        properties.supportedRegionCodes = [Locale.Region("US"), Locale.Region("GB")]
        precondition(properties.supportedRegionCodes.map(\.identifier) == ["US", "GB"])

        let provisioning = CTCellularPlanProvisioning()
        precondition(provisioning.supportsCellularPlan() == false)
        precondition(provisioning.supportsEmbeddedSIM == false)

        let callbackResult = await withCheckedContinuation { continuation in
            provisioning.addPlan(with: request) { result in
                continuation.resume(returning: result)
            }
        }
        precondition(callbackResult == .fail)

        let asyncResult = await provisioning.addPlan(with: request)
        precondition(asyncResult == .fail)

        let callbackResult2 = await withCheckedContinuation { continuation in
            provisioning.addPlan(request: request, properties: properties) { result in
                continuation.resume(returning: result)
            }
        }
        precondition(callbackResult2 == .fail)

        let asyncResult2 = await provisioning.addPlan(request: request, properties: properties)
        precondition(asyncResult2 == .fail)

        let updateError = await withCheckedContinuation { continuation in
            provisioning.update(properties) { error in
                continuation.resume(returning: error)
            }
        }
        precondition(updateError != nil)

        do {
            try await provisioning.update(properties)
            fatalError("update must fail closed")
        } catch {
            precondition(!String(describing: error).isEmpty)
        }

        let tokenResult = await withCheckedContinuation { continuation in
            CTCellularPlanStatus.getTokenWithCompletion { token, error in
                continuation.resume(returning: (token, error))
            }
        }
        precondition(tokenResult.0 == nil)
        precondition(tokenResult.1 != nil)

        do {
            _ = try await CTCellularPlanStatus.token()
            fatalError("token() must fail closed")
        } catch {
            precondition(!String(describing: error).isEmpty)
        }

        let validity = await withCheckedContinuation { continuation in
            CTCellularPlanStatus.checkValidity(ofToken: "not-a-token") { isValid, error in
                continuation.resume(returning: (isValid, error))
            }
        }
        precondition(validity.0 == false)
        precondition(validity.1 != nil)

        do {
            _ = try await CTCellularPlanStatus.checkValidity(ofToken: "not-a-token")
            fatalError("checkValidity must fail closed")
        } catch {
            precondition(!String(describing: error).isEmpty)
        }
    }

    private static func exercisePlanCoding() throws {
        let properties = CTCellularPlanProperties()
        properties.associatedIccid = "8900123"
        properties.simCapability = .dataAndVoice
        properties.supportedRegionCodes = [Locale.Region("JP")]
        let propertyData = try NSKeyedArchiver.archivedData(
            withRootObject: properties,
            requiringSecureCoding: true
        )
        let decodedProperties = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: CTCellularPlanProperties.self,
            from: propertyData
        )
        precondition(decodedProperties?.associatedIccid == "8900123")
        precondition(decodedProperties?.simCapability == .dataAndVoice)
        precondition(decodedProperties?.supportedRegionCodes.map(\.identifier) == ["JP"])

        let request = CTCellularPlanProvisioningRequest()
        request.address = "sm-dp+"
        request.matchingID = "m"
        request.oid = "o"
        request.confirmationCode = "c"
        request.iccid = "i"
        request.eid = "e"
        let requestData = try NSKeyedArchiver.archivedData(
            withRootObject: request,
            requiringSecureCoding: true
        )
        let decodedRequest = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: CTCellularPlanProvisioningRequest.self,
            from: requestData
        )
        precondition(decodedRequest?.address == "sm-dp+")
        precondition(decodedRequest?.matchingID == "m")
        precondition(decodedRequest?.oid == "o")
        precondition(decodedRequest?.confirmationCode == "c")
        precondition(decodedRequest?.iccid == "i")
        precondition(decodedRequest?.eid == "e")
    }
}

await CoreTelephonyRuntime.main()
