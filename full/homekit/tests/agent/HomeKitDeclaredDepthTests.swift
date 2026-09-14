import Foundation
import HomeKit

private func declaredDepthRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit declared-depth test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func declaredDepthCode(_ error: (any Error)?) -> Int? {
    (error as NSError?)?.code
}

private final class DeclaredDepthBrowserDelegate: NSObject, HMAccessoryBrowserDelegate {
    var found: [HMAccessory] = []
    var removed: [HMAccessory] = []
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        _ = browser
        found.append(accessory)
    }
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        _ = browser
        removed.append(accessory)
    }
}

private final class DeclaredDepthSnapshotDelegate: NSObject, HMCameraSnapshotControlDelegate {
    var takes: [(HMCameraSnapshotControl, HMCameraSnapshot?, (any Error)?)] = []
    var refreshes = 0
    func cameraSnapshotControl(
        _ cameraSnapshotControl: HMCameraSnapshotControl,
        didTake snapshot: HMCameraSnapshot?,
        error: (any Error)?
    ) {
        takes.append((cameraSnapshotControl, snapshot, error))
    }
    func cameraSnapshotControlDidUpdateMostRecentSnapshot(_ cameraSnapshotControl: HMCameraSnapshotControl) {
        _ = cameraSnapshotControl
        refreshes += 1
    }
}

private final class DeclaredDepthStreamDelegate: NSObject, HMCameraStreamControlDelegate {
    var starts = 0
    var stops: [(HMCameraStreamControl, (any Error)?)] = []
    func cameraStreamControlDidStartStream(_ cameraStreamControl: HMCameraStreamControl) {
        _ = cameraStreamControl
        starts += 1
    }
    func cameraStreamControl(
        _ cameraStreamControl: HMCameraStreamControl,
        didStopStreamWithError error: (any Error)?
    ) {
        stops.append((cameraStreamControl, error))
    }
}

private final class DeclaredDepthNetworkDelegate: NSObject, HMNetworkConfigurationProfileDelegate {
    var updates: [HMNetworkConfigurationProfile] = []
    func profileDidUpdateNetworkAccessMode(_ profile: HMNetworkConfigurationProfile) {
        updates.append(profile)
    }
}

private final class DeclaredDepthHomeManagerDelegate: NSObject, HMHomeManagerDelegate {
    var didUpdateHomes = 0
    var didUpdatePrimary = 0
    var added: [HMHome] = []
    var removed: [HMHome] = []
    var requests: [HMAddAccessoryRequest] = []
    var statuses: [HMHomeManagerAuthorizationStatus] = []
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        _ = manager
        didUpdateHomes += 1
    }
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        _ = manager
        didUpdatePrimary += 1
    }
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        _ = manager
        added.append(home)
    }
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        _ = manager
        removed.append(home)
    }
    func homeManager(_ manager: HMHomeManager, didReceiveAddAccessoryRequest request: HMAddAccessoryRequest) {
        _ = manager
        requests.append(request)
    }
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        _ = manager
        statuses.append(status)
    }
}

private final class DeclaredDepthMediaOrderDelegate: NSObject, HMMediaSourceDisplayOrderProfile.Delegate,
    @unchecked Sendable
{
    var updates = 0
    func mediaSourceDisplayOrderProfileDidUpdateOrder(_ profile: HMMediaSourceDisplayOrderProfile) {
        _ = profile
        updates += 1
    }
}

func testDeclaredAccessControlAndUser() {
    let access = HMAccessControl()
    declaredDepthRequire(access !== HMAccessControl(), "access control instances distinct")
    let user = HMUser()
    declaredDepthRequire(!user.uniqueIdentifier.uuidString.isEmpty, "user identifier")
    let named = HMUser.host_make(name: "Guest")
    declaredDepthRequire(named.name == "Guest", "user name")
    declaredDepthRequire(named.uniqueIdentifier != user.uniqueIdentifier, "user identifiers unique")
}

func testDeclaredBrowserDelegate() {
    let browser = HMAccessoryBrowser()
    declaredDepthRequire(browser.delegate == nil, "browser delegate starts nil")
    let stub = DeclaredDepthBrowserDelegate()
    let conforming: any HMAccessoryBrowserDelegate = stub
    browser.delegate = conforming
    declaredDepthRequire(browser.delegate === stub, "browser delegate stored")
    let accessory = HMAccessory.host_make(name: "Declared Lamp")
    browser.delegate?.accessoryBrowser(browser, didFindNewAccessory: accessory)
    browser.delegate?.accessoryBrowser(browser, didRemoveNewAccessory: accessory)
    declaredDepthRequire(stub.found.count == 1 && stub.found.first === accessory, "find dispatched")
    declaredDepthRequire(stub.removed.count == 1 && stub.removed.first === accessory, "remove dispatched")
}

func testDeclaredSetupManagerAndPayload() {
    let manager = HMAccessorySetupManager()
    var setupResult: HMAccessorySetupResult?
    var setupError: (any Error)?
    manager.performAccessorySetup(using: HMAccessorySetupRequest()) { result, error in
        setupResult = result
        setupError = error
    }
    declaredDepthRequire(setupResult == nil, "setup returns no result")
    declaredDepthRequire(
        declaredDepthCode(setupError) == HMError.Code.missingEntitlement.rawValue,
        "setup missing entitlement"
    )
    let token = HMAccessoryOwnershipToken(data: Data([0xA5]))!
    let url = URL(string: "homekit://declared-depth")!
    let payload = HMAccessorySetupPayload(url: url, ownershipToken: token)!
    declaredDepthRequire(payload.url == url, "payload url")
    let legacy = HMAccessorySetupPayload(URL: url, ownershipToken: token)!
    declaredDepthRequire(legacy.url == url, "legacy payload url")
    let result = HMAccessorySetupResult()
    declaredDepthRequire(!result.homeUniqueIdentifier.uuidString.isEmpty, "result home identifier")
    declaredDepthRequire(result.accessoryUniqueIdentifiers.isEmpty, "result accessories empty")
}

func testDeclaredCameraControls() {
    let control = HMCameraControl()
    let fresh = HMCameraControl.init()
    declaredDepthRequire(control !== fresh, "camera control instances distinct")
    let profile = HMCameraProfile()
    declaredDepthRequire(profile.streamControl == nil, "stream control absent")
    declaredDepthRequire(profile.snapshotControl == nil, "snapshot control absent")
    declaredDepthRequire(profile.speakerControl == nil, "speaker control absent")
    declaredDepthRequire(profile.microphoneControl == nil, "microphone control absent")
    let wired = HMCameraProfile.host_make(
        streamControl: HMCameraStreamControl(),
        snapshotControl: HMCameraSnapshotControl()
    )
    declaredDepthRequire(wired.streamControl != nil, "stream control wired")
    declaredDepthRequire(wired.snapshotControl != nil, "snapshot control wired")
    let source = HMCameraSource()
    declaredDepthRequire(source.aspectRatio == 0, "aspect ratio unknown default")
    source.host_setAspectRatio(16.0 / 9.0)
    declaredDepthRequire(abs(source.aspectRatio - 16.0 / 9.0) < 1e-9, "aspect ratio stored")
    let stream = HMCameraStream()
    declaredDepthRequire(stream.aspectRatio == 0, "stream inherits aspect ratio")
    stream.setAudioStreamSetting(.incomingAudioAllowed)
    declaredDepthRequire(stream.audioStreamSetting == .incomingAudioAllowed, "audio setting stored")
    stream.setAudioStreamSetting(.muted)
    declaredDepthRequire(stream.audioStreamSetting == .muted, "audio setting restored")
    var audioError: (any Error)?
    stream.updateAudioStreamSetting(.muted) { audioError = $0 }
    declaredDepthRequire(
        declaredDepthCode(audioError) == HMError.Code.operationNotSupported.rawValue,
        "audio update fail closed"
    )
}

func testDeclaredThresholdAndWriteAction() {
    let characteristic = HMCharacteristic.host_make(
        type: HMCharacteristicTypeBrightness,
        properties: [HMCharacteristicPropertyReadable],
        metadata: nil,
        value: NSNumber(value: 50)
    )
    let range = HMNumberRange(minValue: NSNumber(value: 0), maxValue: NSNumber(value: 100))
    let event = HMCharacteristicThresholdRangeEvent(characteristic: characteristic, thresholdRange: range)
    declaredDepthRequire(event.characteristic === characteristic, "threshold characteristic")
    declaredDepthRequire(event.thresholdRange.contains(NSNumber(value: 50)), "threshold range")
    let mutable = HMMutableCharacteristicThresholdRangeEvent(characteristic: characteristic, thresholdRange: range)
    let replacement = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [],
        metadata: nil,
        value: nil
    )
    mutable.characteristic = replacement
    declaredDepthRequire(mutable.characteristic === replacement, "mutable threshold characteristic")
    let action = HMCharacteristicWriteAction<NSNumber>(
        characteristic: characteristic,
        targetValue: NSNumber(value: 75)
    )
    declaredDepthRequire(action.characteristic === characteristic, "write action characteristic")
    declaredDepthRequire(action.targetValue.intValue == 75, "write action target")
    var updateError: (any Error)?
    action.updateTargetValue(NSNumber(value: 80)) { updateError = $0 }
    declaredDepthRequire(updateError == nil, "target update succeeds")
    declaredDepthRequire(action.targetValue.intValue == 80, "target update stored")
}

func testDeclaredHomeManagerFailClosed() {
    let manager = HMHomeManager()
    declaredDepthRequire(manager.delegate == nil, "manager delegate starts nil")
    declaredDepthRequire(manager.homes.isEmpty, "manager homes empty")
    let stub = DeclaredDepthHomeManagerDelegate()
    let conforming: any HMHomeManagerDelegate = stub
    manager.delegate = conforming
    declaredDepthRequire(manager.delegate === stub, "manager delegate stored")
    var addResult: HMHome?
    var addError: (any Error)?
    manager.addHome(named: "Declared Home") { home, error in
        addResult = home
        addError = error
    }
    declaredDepthRequire(addResult == nil, "add home returns nothing")
    declaredDepthRequire(
        declaredDepthCode(addError) == HMError.Code.homeAccessNotAuthorized.rawValue,
        "add home not authorized"
    )
    var removeError: (any Error)?
    manager.removeHome(HMHome.host_make(name: "Declared Home")) { removeError = $0 }
    declaredDepthRequire(
        declaredDepthCode(removeError) == HMError.Code.homeAccessNotAuthorized.rawValue,
        "remove home not authorized"
    )
    var primaryError: (any Error)?
    manager.updatePrimaryHome(HMHome.host_make(name: "Declared Home")) { primaryError = $0 }
    declaredDepthRequire(
        declaredDepthCode(primaryError) == HMError.Code.homeAccessNotAuthorized.rawValue,
        "primary home not authorized"
    )
    var vendorResult: HMAccessory?
    var vendorError: (any Error)?
    manager.findVendorAccessory(hapPublicKey: Data([0x01])) { accessory, error in
        vendorResult = accessory
        vendorError = error
    }
    declaredDepthRequire(vendorResult == nil, "vendor lookup returns nothing")
    declaredDepthRequire(
        declaredDepthCode(vendorError) == HMError.Code.accessoryDiscoveryFailed.rawValue,
        "vendor lookup fails closed"
    )
}

func testDeclaredEventsAndTimerTrigger() {
    let location = HMLocationEvent()
    let mutableLocation = HMMutableLocationEvent()
    declaredDepthRequire(location !== mutableLocation, "location event instances distinct")
    declaredDepthRequire(location.uniqueIdentifier != mutableLocation.uniqueIdentifier, "location identifiers")
    let time = HMTimeEvent()
    declaredDepthRequire(!time.uniqueIdentifier.uuidString.isEmpty, "time event identifier")
    var fire = DateComponents()
    fire.hour = 7
    fire.minute = 30
    let trigger = HMTimerTrigger(name: "Declared Timer", fireDate: Date(timeIntervalSince1970: 4_000_000), recurrence: fire)
    declaredDepthRequire(trigger.recurrence?.hour == 7, "timer recurrence")
    declaredDepthRequire(trigger.recurrenceCalendar == nil, "recurrence calendar absent")
    var fireError: (any Error)?
    trigger.updateFireDate(Date(timeIntervalSince1970: 5_000_000)) { fireError = $0 }
    declaredDepthRequire(fireError != nil, "fire date update fail closed")
    var recurrenceError: (any Error)?
    trigger.updateRecurrence(nil) { recurrenceError = $0 }
    declaredDepthRequire(recurrenceError != nil, "recurrence update fail closed")
    var zoneError: (any Error)?
    trigger.updateTimeZone(TimeZone(identifier: "America/Los_Angeles")) { zoneError = $0 }
    declaredDepthRequire(zoneError != nil, "time zone update fail closed")
    let significant = HMMutableSignificantTimeEvent(significantEvent: .sunrise, offset: nil)
    declaredDepthRequire(significant.offset == nil, "offset starts nil")
    var offset = DateComponents()
    offset.minute = 15
    significant.offset = offset
    declaredDepthRequire(significant.offset?.minute == 15, "offset stored")
}

func testDeclaredCameraDelegates() {
    let snapshotDelegate: any HMCameraSnapshotControlDelegate = DeclaredDepthSnapshotDelegate()
    let snapshotControl = HMCameraSnapshotControl()
    snapshotDelegate.cameraSnapshotControl(snapshotControl, didTake: nil, error: nil)
    snapshotDelegate.cameraSnapshotControlDidUpdateMostRecentSnapshot(snapshotControl)
    let streamDelegate: any HMCameraStreamControlDelegate = DeclaredDepthStreamDelegate()
    let streamControl = HMCameraStreamControl()
    streamDelegate.cameraStreamControlDidStartStream(streamControl)
    streamDelegate.cameraStreamControl(streamControl, didStopStreamWithError: nil)
    let networkDelegate: any HMNetworkConfigurationProfileDelegate = DeclaredDepthNetworkDelegate()
    let networkProfile = HMNetworkConfigurationProfile()
    networkDelegate.profileDidUpdateNetworkAccessMode(networkProfile)
    let homeDelegate: any HMHomeManagerDelegate = DeclaredDepthHomeManagerDelegate()
    let manager = HMHomeManager()
    let home = HMHome.host_make(name: "Delegate Home")
    homeDelegate.homeManagerDidUpdateHomes(manager)
    homeDelegate.homeManagerDidUpdatePrimaryHome(manager)
    homeDelegate.homeManager(manager, didAdd: home)
    homeDelegate.homeManager(manager, didRemove: home)
    homeDelegate.homeManager(manager, didReceiveAddAccessoryRequest: HMAddAccessoryRequest())
    homeDelegate.homeManager(manager, didUpdate: [.determined, .restricted])
    declaredDepthRequire(true, "delegate dispatch returns")
}

func testDeclaredMediaOrderProfile() {
    let profile = HMMediaSourceDisplayOrderProfile()
    declaredDepthRequire(profile.order.isEmpty, "order starts empty")
    declaredDepthRequire(profile.canModifyOrder == false, "order not modifiable")
    declaredDepthRequire(profile.delegate == nil, "order delegate starts nil")
    let stub = DeclaredDepthMediaOrderDelegate()
    let conforming: any HMMediaSourceDisplayOrderProfile.Delegate = stub
    profile.delegate = conforming
    declaredDepthRequire(profile.delegate === stub, "order delegate stored")
    profile.delegate?.mediaSourceDisplayOrderProfileDidUpdateOrder(profile)
    declaredDepthRequire(stub.updates == 1, "order delegate dispatched")
    var blockError: (any Error)?
    let block: HMErrorBlock = { blockError = $0 }
    block(nil)
    declaredDepthRequire(blockError == nil, "error block invoked")
    let trigger = HMTimerTrigger(name: "Block Timer", fireDate: Date(), recurrence: nil)
    trigger.updateTimeZone(nil, completionHandler: block)
    declaredDepthRequire(blockError != nil, "error block carries failure")
}

func testDeclaredErrorWitnesses() {
    let reachable = HMError.Code(rawValue: 4)
    declaredDepthRequire(reachable == .accessoryNotReachable, "raw value init")
    declaredDepthRequire(HMError.Code(rawValue: 9_999_999) == nil, "unknown raw value nil")
    declaredDepthRequire(HMError.Code.accessDenied != .alreadyExists, "codes differ")
    declaredDepthRequire(!(HMError.Code.accessDenied != HMError.Code.accessDenied), "same code equal")
    let code = HMError.Code.accessoryNotReachable
    declaredDepthRequire(code.hashValue == HMError.Code.accessoryNotReachable.hashValue, "hash stable")
    var first = Hasher()
    code.hash(into: &first)
    var second = Hasher()
    HMError.Code.accessoryNotReachable.hash(into: &second)
    declaredDepthRequire(first.finalize() == second.finalize(), "hash into matches")
    declaredDepthRequire(Set([code, .accessoryNotReachable]).count == 1, "hash set dedupes")
    let described = (HMError(.accessDenied) as any Error).localizedDescription
    declaredDepthRequire(!described.isEmpty, "localized description")
}
