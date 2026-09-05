import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testNumberRange() {
    let both = HMNumberRange(minValue: 1, maxValue: 10)
    hmRequire(both.minValue?.intValue == 1, "min")
    hmRequire(both.maxValue?.intValue == 10, "max")
    hmRequire(both.contains(NSNumber(value: 5)), "contains 5")
    hmRequire(!both.contains(NSNumber(value: 11)), "rejects 11")
    let minOnly = HMNumberRange(minValue: 3)
    hmRequire(minOnly.maxValue == nil, "max nil")
    hmRequire(minOnly.contains(NSNumber(value: 3)), "min inclusive")
    hmRequire(!minOnly.contains(NSNumber(value: 2)), "below min")
    let maxOnly = HMNumberRange(maxValue: 8)
    hmRequire(maxOnly.minValue == nil, "min nil")
    hmRequire(maxOnly.contains(NSNumber(value: 8)), "max inclusive")
    hmRequire(!maxOnly.contains(NSNumber(value: 9)), "above max")
}

func testDurationAndCalendarEvents() {
    let duration = HMDurationEvent(duration: 12.5)
    hmRequire(duration.duration == 12.5, "duration")
    _ = duration.uniqueIdentifier
    let mutable = HMMutableDurationEvent(duration: 1)
    mutable.duration = 4
    hmRequire(mutable.duration == 4, "mutable duration")
    var comps = DateComponents()
    comps.hour = 7
    comps.minute = 30
    let calendar = HMCalendarEvent(fireDateComponents: comps)
    hmRequire(calendar.fireDateComponents.hour == 7, "hour")
    let calendarFire = HMCalendarEvent(fire: comps)
    hmRequire(calendarFire.fireDateComponents.minute == 30, "fire label")
    let mutCal = HMMutableCalendarEvent(fireDateComponents: comps)
    var next = DateComponents()
    next.hour = 8
    mutCal.fireDateComponents = next
    hmRequire(mutCal.fireDateComponents.hour == 8, "mutable hour")
}

func testPresenceAndSignificantTime() {
    let presence = HMPresenceEvent(presenceEventType: .everyEntry, presenceUserType: .currentUser)
    hmRequire(presence.presenceEventType == .everyEntry, "type")
    hmRequire(presence.presenceUserType == .currentUser, "user")
    let mut = HMMutablePresenceEvent(presenceEventType: .everyExit, presenceUserType: .homeUsers)
    mut.presenceEventType = .lastExit
    mut.presenceUserType = .customUsers
    hmRequire(mut.presenceEventType == .lastExit, "mut type")
    hmRequire(mut.presenceUserType == .customUsers, "mut user")
    hmRequire(HMSignificantEvent.sunrise.rawValue == "HMSignificantEventSunrise", "sunrise")
    hmRequire(HMSignificantEvent.sunset.rawValue == "HMSignificantEventSunset", "sunset")
    hmRequire(HMSignificantEvent("HMSignificantEventSunrise") == .sunrise, "init(_)")
    var offset = DateComponents()
    offset.minute = 15
    let sig = HMSignificantTimeEvent(significantEvent: .sunrise, offset: offset)
    hmRequire(sig.significantEvent == .sunrise, "sig event")
    hmRequire(sig.offset?.minute == 15, "offset")
    let mutSig = HMMutableSignificantTimeEvent(significantEvent: .sunset, offset: offset)
    mutSig.significantEvent = .sunrise
    hmRequire(mutSig.significantEvent == .sunrise, "mut sig")
}

func testTimerTrigger() {
    let fire = Date(timeIntervalSince1970: 1_700_000_000)
    let trigger = HMTimerTrigger(name: "Morning", fireDate: fire, recurrence: nil)
    hmRequire(trigger.name == "Morning", "name")
    hmRequire(trigger.fireDate == fire, "fire")
    hmRequire(trigger.isEnabled == false, "disabled")
    hmRequire(trigger.actionSets.isEmpty, "no sets")
    let tz = TimeZone(secondsFromGMT: 3600)
    let full = HMTimerTrigger(
        name: "Eve",
        fireDate: fire,
        timeZone: tz,
        recurrence: nil,
        recurrenceCalendar: Calendar(identifier: .gregorian)
    )
    hmRequire(full.timeZone?.secondsFromGMT() == 3600, "tz")
    hmRequire(full.recurrenceCalendar?.identifier == .gregorian, "calendar")
}

func testHomeManagerFailClosed() {
    let manager = HMHomeManager()
    hmRequire(manager.homes.isEmpty, "no Apple homes")
    hmRequire(manager.primaryHome == nil, "no primary")
    hmRequire(manager.authorizationStatus.contains(.determined), "determined")
    hmRequire(manager.authorizationStatus.contains(.restricted), "restricted")
    hmRequire(!manager.authorizationStatus.contains(.authorized), "not authorized")
    var captured: (any Error)?
    // identify-style completions run before return.
    let accessory = HMAccessory.host_make(name: "Lamp")
    accessory.identify { error in captured = error }
    hmRequire(captured != nil, "identify error")
    let ns = captured! as NSError
    hmRequire(ns.domain == HMErrorDomain, "domain")
    hmRequire(ns.code == HMError.Code.accessoryNotReachable.rawValue, "not reachable")
}

func testAccessoryBrowserIdle() {
    let browser = HMAccessoryBrowser()
    hmRequire(browser.discoveredAccessories.isEmpty, "empty")
    browser.startSearchingForNewAccessories()
    hmRequire(browser.discoveredAccessories.isEmpty, "still empty")
    browser.stopSearchingForNewAccessories()
    hmRequire(browser.discoveredAccessories.isEmpty, "stopped empty")
}

func testCameraStreamFailClosed() {
    let control = HMCameraStreamControl.host_make()
    hmRequire(control.streamState == .notStreaming, "idle")
    hmRequire(control.cameraStream == nil, "no stream")
    control.startStream()
    hmRequire(control.streamState == .notStreaming, "did not invent streaming")
    control.stopStream()
    hmRequire(control.streamState == .notStreaming, "stop idle")
    let snapshot = HMCameraSnapshotControl.host_make()
    hmRequire(snapshot.mostRecentSnapshot == nil, "no snapshot")
    snapshot.takeSnapshot()
    hmRequire(snapshot.mostRecentSnapshot == nil, "did not invent snapshot")
}

func testCharacteristicMetadataAndWrite() {
    let meta = HMCharacteristicMetadata.host_make(
        format: HMCharacteristicMetadataFormatUInt8,
        units: HMCharacteristicMetadataUnitsPercentage,
        minimumValue: 0,
        maximumValue: 100,
        stepValue: 1
    )
    hmRequire(meta.format == "uint8", "format")
    hmRequire(meta.units == "percentage", "units")
    hmRequire(meta.contains(NSNumber(value: 50)), "50 ok")
    hmRequire(!meta.contains(NSNumber(value: 101)), "101 rejected")
    let characteristic = HMCharacteristic.host_make(
        type: HMCharacteristicTypeBrightness,
        properties: [HMCharacteristicPropertyReadable, HMCharacteristicPropertyWritable],
        metadata: meta,
        value: NSNumber(value: 10)
    )
    hmRequire(characteristic.characteristicType == HMCharacteristicTypeBrightness, "type")
    hmRequire(characteristic.isNotificationEnabled == false, "notify off")
    var writeError: (any Error)?
    characteristic.host_writeLocal(NSNumber(value: 40)) { error in writeError = error }
    hmRequire(writeError == nil, "local write ok")
    hmRequire((characteristic.value as? NSNumber)?.intValue == 40, "stored")
    characteristic.host_writeLocal(NSNumber(value: 200)) { error in writeError = error }
    hmRequire((writeError as NSError?)?.code == HMError.Code.valueHigherThanMaximum.rawValue, "max")
    characteristic.host_writeLocal("nope") { error in writeError = error }
    hmRequire((writeError as NSError?)?.code == HMError.Code.invalidValueType.rawValue, "type")
    var unreachable: (any Error)?
    characteristic.readValue { error in unreachable = error }
    hmRequire((unreachable as NSError?)?.code == HMError.Code.accessoryNotReachable.rawValue, "read fail-closed")
}

func testHomeGraphQueries() {
    let home = HMHome.host_make(name: "Cottage")
    hmRequire(home.name == "Cottage", "name")
    hmRequire(home.homeHubState == .notAvailable, "no hub")
    hmRequire(home.isPrimary == false, "not primary")
    let room = home.roomForEntireHome()
    hmRequire(room.name == "Cottage", "whole-home room")
    let light = HMService.host_make(name: "Ceiling", serviceType: HMServiceTypeLightbulb)
    let fan = HMService.host_make(name: "Fan", serviceType: HMServiceTypeFan)
    home.host_setServices([light, fan])
    let lights = home.servicesWithTypes([HMServiceTypeLightbulb])
    hmRequire(lights?.count == 1, "one light")
    hmRequire(lights?.first?.name == "Ceiling", "name")
    hmRequire(home.servicesWithTypes([HMServiceTypeThermostat])?.isEmpty == true, "no thermo")
    hmRequire(home.builtinActionSet(ofType: HMActionSetTypeWakeUp) == nil, "no builtin")
}

func testEventTriggerPredicates() {
    var comps = DateComponents()
    comps.hour = 6
    let after = HMEventTrigger.predicateForEvaluatingTrigger(occurringAfter: comps)
    hmRequire(after.evaluate(with: nil) == true, "after")
    let before = HMEventTrigger.predicateForEvaluatingTrigger(occurringBefore: comps)
    hmRequire(before.evaluate(with: nil) == true, "before")
    let on = HMEventTrigger.predicateForEvaluatingTrigger(occurringOn: comps)
    hmRequire(on.evaluate(with: nil) == true, "on")
    let between = HMEventTrigger.predicateForEvaluatingTriggerOccurringBetweenDate(
        with: comps,
        secondDateWith: comps
    )
    hmRequire(between.evaluate(with: nil) == true, "between")
    let presence = HMPresenceEvent(presenceEventType: .atHome, presenceUserType: .currentUser)
    let pred = HMEventTrigger.predicateForEvaluatingTrigger(withPresence: presence)
    hmRequire(pred.evaluate(with: nil) == true, "presence")
    hmRequire(HMEvent.isSupported(for: HMHome.host_make(name: "X")) == false, "events unsupported")
}

func testSetupPayloadAndOwnership() {
    hmRequire(HMAccessoryOwnershipToken(data: Data()) == nil, "empty token")
    let token = HMAccessoryOwnershipToken(data: Data([0x01, 0x02]))
    hmRequire(token != nil, "token")
    hmRequire(HMAccessorySetupPayload(url: nil) == nil, "nil url")
    let url = URL(string: "homekit://setup")!
    let payload = HMAccessorySetupPayload(url: url)
    hmRequire(payload != nil, "payload")
    let labeled = HMAccessorySetupPayload(URL: url)
    hmRequire(labeled != nil, "URL label")
    let withToken = HMAccessorySetupPayload(url: url, ownershipToken: token)
    hmRequire(withToken != nil, "with token")
    let labeledToken = HMAccessorySetupPayload(URL: url, ownershipToken: token)
    hmRequire(labeledToken != nil, "URL token")
    let request = HMAccessorySetupRequest()
    request.suggestedAccessoryName = "Lock"
    hmRequire(request.suggestedAccessoryName == "Lock", "suggested")
    let manager = HMAccessorySetupManager()
    var setupError: (any Error)?
    // The async API is declared; the host completion path is fail-closed.
    manager.host_performSetup(request) { _, error in setupError = error }
    hmRequire((setupError as NSError?)?.code == HMError.Code.missingEntitlement.rawValue, "setup")
}

func testActionWriteAndThreshold() {
    let characteristic = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [HMCharacteristicPropertyWritable],
        metadata: nil,
        value: false
    )
    let action = HMCharacteristicWriteAction<NSNumber>(
        characteristic: characteristic,
        targetValue: NSNumber(value: true)
    )
    hmRequire(action.targetValue.boolValue == true, "target")
    hmRequire(action.uniqueIdentifier.uuidString.isEmpty == false, "uuid")
    let range = HMNumberRange(minValue: 10, maxValue: 20)
    let event = HMCharacteristicThresholdRangeEvent(characteristic: characteristic, thresholdRange: range)
    hmRequire(event.thresholdRange.minValue?.intValue == 10, "thr min")
    let mut = HMMutableCharacteristicThresholdRangeEvent(
        characteristic: characteristic,
        thresholdRange: range
    )
    mut.thresholdRange = HMNumberRange(minValue: 1, maxValue: 2)
    hmRequire(mut.thresholdRange.maxValue?.intValue == 2, "mut max")
}

func testCelsiusFahrenheitConversion() {
    let c = HMCharacteristicMetadata.host_celsiusToFahrenheit(0)
    hmRequire(abs(c - 32) < 0.0001, "0C=32F")
    let f = HMCharacteristicMetadata.host_fahrenheitToCelsius(212)
    hmRequire(abs(f - 100) < 0.0001, "212F=100C")
    hmRequire(HMCharacteristicMetadata.host_isKnownFormat("bool"), "bool known")
    hmRequire(!HMCharacteristicMetadata.host_isKnownFormat("nope"), "unknown format")
}

func testFoundationIdentityThroughHomeKit() {
    let uuid = UUID()
    let user = HMUser.host_make(name: "Ada", uniqueIdentifier: uuid)
    hmRequire(user.uniqueIdentifier == uuid, "UUID round-trip")
    hmRequire(user.name == "Ada", "name")
    let data = Data([0x0A])
    let token = HMAccessoryOwnershipToken(data: data)
    hmRequire(token != nil, "Data token")
    let error = HMError(.invalidParameter, userInfo: ["n": NSNumber(value: 3)])
    hmRequire((error.userInfo["n"] as? NSNumber)?.intValue == 3, "NSNumber")
}
