import CoreTelephony
import Dispatch
import Foundation

private func waitOnce(_ semaphore: DispatchSemaphore, seconds: Double = 2) {
    precondition(semaphore.wait(timeout: .now() + seconds) == .success)
}

private func waitQuiet(_ semaphore: DispatchSemaphore, seconds: Double = 0.25) {
    precondition(semaphore.wait(timeout: .now() + seconds) == .timedOut)
}

private final class NetworkDelegateProbe: NSObject, CTTelephonyNetworkInfoDelegate {
    var seen: String?
    func dataServiceIdentifierDidChange(_ identifier: String) {
        seen = identifier
    }
}

private final class SubscriberDelegateProbe: NSObject, CTSubscriberDelegate {
    var refreshed: CTSubscriber?
    func subscriberTokenRefreshed(_ subscriber: CTSubscriber) {
        refreshed = subscriber
    }
}

enum CoreTelephonyRuntime {
    static func main() async {
        exerciseErrorAndEnums()
        exerciseCallCenter()
        exerciseNetworkInfoAndDelegates()
        exerciseSubscriber()
        await exerciseCellularDataNotifier()
        await exerciseCellularPlan()
        print("CORETELEPHONY_AGENT_RUNTIME_OK")
    }

    static func exerciseErrorAndEnums() {
        precondition(kCTErrorDomainNoError == 0)
        precondition(kCTErrorDomainPOSIX == 1)
        precondition(kCTErrorDomainMach == 2)

        let zero = CTError()
        precondition(zero.domain == Int32(kCTErrorDomainNoError))
        precondition(zero.error == 0)
        var err = CTError(domain: Int32(kCTErrorDomainPOSIX), error: 2)
        precondition(err.domain == Int32(kCTErrorDomainPOSIX))
        precondition(err.error == 2)
        err.domain = Int32(kCTErrorDomainMach)
        err.error = 9
        precondition(err.domain == Int32(kCTErrorDomainMach))
        precondition(err.error == 9)

        precondition(CTCellularDataRestrictedState(rawValue: 0) == .restrictedStateUnknown)
        precondition(CTCellularDataRestrictedState(rawValue: 1) == .restricted)
        precondition(CTCellularDataRestrictedState(rawValue: 2) == .notRestricted)
        precondition(CTCellularDataRestrictedState(rawValue: 99) == nil)
        precondition(CTCellularDataRestrictedState.restricted != .notRestricted)
        _ = CTCellularDataRestrictedState.restricted.hashValue
        var hasher = Hasher()
        CTCellularDataRestrictedState.notRestricted.hash(into: &hasher)
        _ = hasher.finalize()

        precondition(CTCellularPlanCapability(rawValue: 0) == .dataOnly)
        precondition(CTCellularPlanCapability(rawValue: 1) == .dataAndVoice)
        precondition(CTCellularPlanCapability(rawValue: 8) == nil)
        precondition(CTCellularPlanCapability.dataOnly != .dataAndVoice)
        let capabilityHash = CTCellularPlanCapability.dataOnly.hashValue
        precondition(capabilityHash != CTCellularPlanCapability.dataAndVoice.hashValue)
        var capabilityHasher = Hasher()
        CTCellularPlanCapability.dataAndVoice.hash(into: &capabilityHasher)
        _ = capabilityHasher.finalize()

        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 0) == .unknown)
        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 1) == .fail)
        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 2) == .success)
        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 3) == .cancel)
        precondition(CTCellularPlanProvisioningAddPlanResult(rawValue: 4) == nil)
        precondition(
            CTCellularPlanProvisioningAddPlanResult.fail
                != CTCellularPlanProvisioningAddPlanResult.success
        )
        let resultHash = CTCellularPlanProvisioningAddPlanResult.fail.hashValue
        precondition(resultHash != CTCellularPlanProvisioningAddPlanResult.success.hashValue)
        var resultHasher = Hasher()
        CTCellularPlanProvisioningAddPlanResult.cancel.hash(into: &resultHasher)
        _ = resultHasher.finalize()

        precondition(CTCallStateConnected == "connected")
        precondition(CTCallStateDialing == "dialing")
        precondition(CTRadioAccessTechnologyLTE == "CTRadioAccessTechnologyLTE")
        precondition(CTSubscriberTokenRefreshed == "CTSubscriberTokenRefreshed")
        precondition(
            NSNotification.Name.CTRadioAccessTechnologyDidChange.rawValue
                == "CTRadioAccessTechnologyDidChangeNotification"
        )
        precondition(
            NSNotification.Name.CTServiceRadioAccessTechnologyDidChange.rawValue
                == "CTServiceRadioAccessTechnologyDidChangeNotification"
        )
        let _: CellularDataRestrictionDidUpdateNotifier = { _ in }
    }

    static func exerciseCallCenter() {
        let call = CTCall()
        precondition(call.callID.isEmpty)
        precondition(call.callState.isEmpty)

        let center = CTCallCenter()
        precondition(center.currentCalls == nil)
        var fired = false
        center.callEventHandler = { _ in fired = true }
        precondition(center.callEventHandler != nil)
        precondition(!fired)
        center.callEventHandler = nil
        precondition(center.callEventHandler == nil)
    }

    static func exerciseNetworkInfoAndDelegates() {
        let carrier = CTCarrier()
        precondition(carrier.carrierName == nil)
        precondition(carrier.mobileCountryCode == nil)
        precondition(carrier.mobileNetworkCode == nil)
        precondition(carrier.isoCountryCode == nil)
        precondition(carrier.allowsVOIP == false)

        let info = CTTelephonyNetworkInfo()
        precondition(info.dataServiceIdentifier == nil)
        precondition(info.subscriberCellularProvider == nil)
        precondition(info.serviceSubscriberCellularProviders == nil)
        precondition(info.currentRadioAccessTechnology == nil)
        precondition(info.serviceCurrentRadioAccessTechnology == nil)

        var providerFired = false
        var serviceFired = false
        info.subscriberCellularProviderDidUpdateNotifier = { _ in providerFired = true }
        info.serviceSubscriberCellularProvidersDidUpdateNotifier = { _ in serviceFired = true }
        precondition(!providerFired)
        precondition(!serviceFired)

        let override = NetworkDelegateProbe()
        info.delegate = override
        precondition(info.delegate === override)
        let existential: any CTTelephonyNetworkInfoDelegate = override
        existential.dataServiceIdentifierDidChange("probe-id")
        precondition(override.seen == "probe-id")
        info.delegate = nil
        precondition(info.delegate == nil)
    }

    static func exerciseSubscriber() {
        let subscriber = CTSubscriber()
        precondition(subscriber.carrierToken == nil)
        precondition(subscriber.identifier.isEmpty)
        precondition(subscriber.isSIMInserted == false)
        let probe = SubscriberDelegateProbe()
        subscriber.delegate = probe
        precondition(subscriber.delegate === probe)
        precondition(subscriber.refreshCarrierToken() == false)
        precondition(probe.refreshed == nil)
        let existential: any CTSubscriberDelegate = probe
        existential.subscriberTokenRefreshed(subscriber)
        precondition(probe.refreshed === subscriber)

        precondition(CTSubscriberInfo.subscribers().isEmpty)
        let deprecated = CTSubscriberInfo.subscriber()
        precondition(deprecated.isSIMInserted == false)
    }

    static func exerciseCellularDataNotifier() async {
        let data = CTCellularData()
        precondition(data.restrictedState == .restrictedStateUnknown)

        let first = DispatchSemaphore(value: 0)
        var hits = 0
        var seen: CTCellularDataRestrictedState?
        var inline = false
        data.cellularDataRestrictionDidUpdateNotifier = { state in
            hits += 1
            seen = state
            inline = true
            first.signal()
        }
        precondition(!inline)
        waitOnce(first)
        precondition(hits == 1)
        precondition(seen == .restrictedStateUnknown)
        waitQuiet(first)

        var secondHits = 0
        data.cellularDataRestrictionDidUpdateNotifier = { _ in
            secondHits += 1
        }
        waitQuiet(DispatchSemaphore(value: 0), seconds: 0.25)
        precondition(secondHits == 0)
        precondition(hits == 1)

        data.cellularDataRestrictionDidUpdateNotifier = nil
        let again = DispatchSemaphore(value: 0)
        var thirdHits = 0
        data.cellularDataRestrictionDidUpdateNotifier = { _ in
            thirdHits += 1
            again.signal()
        }
        waitOnce(again)
        precondition(thirdHits == 1)
    }

    static func exerciseCellularPlan() async {
        let properties = CTCellularPlanProperties()
        properties.associatedIccid = "890000"
        properties.simCapability = .dataAndVoice
        properties.supportedRegionCodes = [Locale.Region("US")]
        precondition(properties.associatedIccid == "890000")
        precondition(properties.simCapability == .dataAndVoice)
        precondition(properties.supportedRegionCodes == [Locale.Region("US")])
        let dummyArchive: Data = {
            let archiver = NSKeyedArchiver(requiringSecureCoding: true)
            archiver.encode("coretelephony-linux", forKey: "probe")
            return archiver.encodedData
        }()
        let emptyPropertiesArchive = try! NSKeyedUnarchiver(forReadingFrom: dummyArchive)
        precondition(CTCellularPlanProperties(coder: emptyPropertiesArchive) == nil)
        let emptyRequestArchive = try! NSKeyedUnarchiver(forReadingFrom: dummyArchive)
        precondition(CTCellularPlanProvisioningRequest(coder: emptyRequestArchive) == nil)

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
        waitOnce(addSemaphore)
        precondition(addResult == .fail)

        let asyncFail = await provisioning.addPlan(with: request)
        precondition(asyncFail == .fail)
        let asyncFailWithProperties = await provisioning.addPlan(
            request: request,
            properties: properties
        )
        precondition(asyncFailWithProperties == .fail)

        let updateSemaphore = DispatchSemaphore(value: 0)
        var updateError: (any Error)?
        var updateInline = false
        provisioning.update(properties) { error in
            updateInline = true
            updateError = error
            updateSemaphore.signal()
        }
        precondition(!updateInline)
        waitOnce(updateSemaphore)
        precondition(updateError != nil)
        do {
            try await provisioning.update(properties)
            fatalError("update must fail closed")
        } catch {
            precondition((error as NSError).domain == NSPOSIXErrorDomain)
        }

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
        waitOnce(tokenSemaphore)
        precondition(token == nil)
        precondition(tokenError != nil)
        do {
            _ = try await CTCellularPlanStatus.checkValidity(ofToken: "token")
            fatalError("checkValidity must fail closed")
        } catch {
            precondition((error as NSError).domain == NSPOSIXErrorDomain)
        }
    }
}

let coreTelephonyRuntimeDone = DispatchSemaphore(value: 0)
Task {
    await CoreTelephonyRuntime.main()
    coreTelephonyRuntimeDone.signal()
}
coreTelephonyRuntimeDone.wait()
