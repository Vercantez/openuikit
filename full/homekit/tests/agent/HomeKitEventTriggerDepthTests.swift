import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testEventTriggerConstructionAndMutations() {
    let event = HMDurationEvent(duration: 5)
    let end = HMCalendarEvent(fireDateComponents: DateComponents(hour: 9))
    var rec = DateComponents()
    rec.hour = 1
    let predicate = NSPredicate { _, _ in true }
    let trigger = HMEventTrigger(
        name: "Arrive",
        events: [event],
        end: [end],
        recurrences: [rec],
        predicate: predicate
    )
    hmRequire(trigger.name == "Arrive", "name")
    hmRequire(trigger.events.count == 1, "events")
    hmRequire(trigger.endEvents.count == 1, "end")
    hmRequire(trigger.recurrences?.count == 1, "recurrence")
    hmRequire(trigger.predicate === predicate, "pred")
    hmRequire(trigger.executeOnce == false, "once")
    hmRequire(trigger.triggerActivationState == .disabledNoHomeHub, "no hub")
    hmRequire(trigger.isEnabled == false, "disabled")
    hmRequire(trigger.actionSets.isEmpty, "no sets")
    hmRequire(trigger.lastFireDate == nil, "no fire")
    hmRequire(trigger.uniqueIdentifier.uuidString.isEmpty == false, "uuid")

    let labeled = HMEventTrigger(
        name: "Leave",
        events: [event],
        endEvents: nil,
        recurrences: nil,
        predicate: nil
    )
    hmRequire(labeled.endEvents.isEmpty, "nil end")
    let short = HMEventTrigger(name: "Short", events: [], predicate: nil)
    hmRequire(short.events.isEmpty, "empty events")

    var error: (any Error)?
    let extra = HMPresenceEvent(presenceEventType: .everyExit, presenceUserType: .homeUsers)
    trigger.addEvent(extra) { error = $0 }
    hmRequire(error == nil && trigger.events.count == 2, "add event")
    trigger.removeEvent(extra) { error = $0 }
    hmRequire(error == nil && trigger.events.count == 1, "remove event")
    trigger.updateEvents([extra]) { error = $0 }
    hmRequire(error == nil && trigger.events.first === extra, "update events")
    trigger.updateEndEvents([]) { error = $0 }
    hmRequire(trigger.endEvents.isEmpty, "clear end")
    trigger.updatePredicate(nil) { error = $0 }
    hmRequire(trigger.predicate == nil, "clear pred")
    trigger.updateRecurrences(nil) { error = $0 }
    hmRequire(trigger.recurrences == nil, "clear rec")
    trigger.updateExecuteOnce(true) { error = $0 }
    hmRequire(trigger.executeOnce, "once")

    let home = HMHome.host_make(name: "T")
    home.addTrigger(trigger) { error = $0 }
    hmRequire(error == nil, "add to home")
    trigger.enable(true) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.noHomeHub.rawValue, "enable no hub")
    let set = HMActionSet.host_make(name: "A")
    trigger.addActionSet(set) { error = $0 }
    hmRequire(error == nil && trigger.actionSets.count == 1, "set")
    home.host_setHomeHubState(.connected)
    trigger.enable(true) { error = $0 }
    hmRequire(error == nil && trigger.isEnabled, "enabled")
    hmRequire(trigger.triggerActivationState == .enabled, "activation")
    trigger.enable(false) { error = $0 }
    hmRequire(trigger.isEnabled == false, "disabled again")
    trigger.host_markFired(at: Date(timeIntervalSince1970: 10))
    hmRequire(trigger.lastFireDate?.timeIntervalSince1970 == 10, "fired")
}

func testEventTriggerSignificantAndPresencePredicates() {
    var comps = DateComponents()
    comps.hour = 6
    comps.minute = 0
    let after = HMEventTrigger.predicateForEvaluatingTrigger(occurringAfter: comps)
    hmRequire(after.evaluate(with: HMLocalClock.date(hour: 7, minute: 0)) == true, "after 7")
    hmRequire(after.evaluate(with: HMLocalClock.date(hour: 5, minute: 0)) == false, "after 5")
    let before = HMEventTrigger.predicateForEvaluatingTrigger(occurringBefore: comps)
    hmRequire(before.evaluate(with: HMLocalClock.date(hour: 5, minute: 0)) == true, "before 5")
    hmRequire(before.evaluate(with: HMLocalClock.date(hour: 7, minute: 0)) == false, "before 7")
    let on = HMEventTrigger.predicateForEvaluatingTrigger(occurringOn: comps)
    hmRequire(on.evaluate(with: HMLocalClock.date(hour: 6, minute: 0)) == true, "on")
    hmRequire(on.evaluate(with: HMLocalClock.date(hour: 6, minute: 1)) == false, "not on")
    var later = DateComponents()
    later.hour = 8
    later.minute = 0
    let between = HMEventTrigger.predicateForEvaluatingTriggerOccurringBetweenDate(
        with: comps,
        secondDateWith: later
    )
    hmRequire(between.evaluate(with: HMLocalClock.date(hour: 7, minute: 0)) == true, "between")
    hmRequire(between.evaluate(with: HMLocalClock.date(hour: 9, minute: 0)) == false, "outside")

    var overnightStart = DateComponents()
    overnightStart.hour = 22
    var overnightEnd = DateComponents()
    overnightEnd.hour = 2
    let wrap = HMEventTrigger.predicateForEvaluatingTriggerOccurringBetweenDate(
        with: overnightStart,
        secondDateWith: overnightEnd
    )
    hmRequire(wrap.evaluate(with: HMLocalClock.date(hour: 23, minute: 0)) == true, "wrap night")
    hmRequire(wrap.evaluate(with: HMLocalClock.date(hour: 1, minute: 0)) == true, "wrap morning")
    hmRequire(wrap.evaluate(with: HMLocalClock.date(hour: 12, minute: 0)) == false, "wrap noon")

    let afterSig = HMEventTrigger.predicateForEvaluatingTrigger(
        occurringAfter: HMSignificantEvent.sunrise.rawValue,
        applyingOffset: nil
    )
    hmRequire(afterSig.evaluate(with: nil) == true, "sunrise string")
    let badSig = HMEventTrigger.predicateForEvaluatingTrigger(
        occurringAfter: "not-an-event",
        applyingOffset: nil
    )
    hmRequire(badSig.evaluate(with: nil) == false, "unknown event")
    let beforeSig = HMEventTrigger.predicateForEvaluatingTrigger(
        occurringBefore: HMSignificantEvent.sunset.rawValue,
        applyingOffset: DateComponents(minute: 10)
    )
    hmRequire(beforeSig.evaluate(with: nil) == true, "sunset string")

    let sunrise = HMSignificantTimeEvent(significantEvent: .sunrise, offset: nil)
    let sunset = HMSignificantTimeEvent(significantEvent: .sunset, offset: nil)
    hmRequire(
        HMEventTrigger.predicateForEvaluatingTriggerOccurring(afterSignificantEvent: sunrise)
            .evaluate(with: nil) == true,
        "after sig object"
    )
    hmRequire(
        HMEventTrigger.predicateForEvaluatingTriggerOccurring(beforeSignificantEvent: sunset)
            .evaluate(with: nil) == true,
        "before sig object"
    )
    hmRequire(
        HMEventTrigger.predicate(
            forEvaluatingTriggerOccurringBetweenSignificantEvent: sunrise,
            secondSignificantEvent: sunset
        ).evaluate(with: nil) == true,
        "between sig"
    )

    let presence = HMPresenceEvent(presenceEventType: .everyEntry, presenceUserType: .currentUser)
    let pred = HMEventTrigger.predicateForEvaluatingTrigger(withPresence: presence)
    hmRequire(pred.evaluate(with: presence) == true, "same presence")
    let other = HMPresenceEvent(presenceEventType: .everyExit, presenceUserType: .currentUser)
    hmRequire(pred.evaluate(with: other) == false, "different type")
    hmRequire(pred.evaluate(with: NSNumber(value: HMPresenceEventType.everyEntry.rawValue)) == true, "number")
}

func testTriggerBaseClass() {
    let trigger = HMTrigger()
    hmRequire(trigger.name == "", "empty name")
    hmRequire(trigger.isEnabled == false, "off")
    hmRequire(trigger.actionSets.isEmpty, "sets")
    hmRequire(trigger.lastFireDate == nil, "fire")
    hmRequire(trigger.uniqueIdentifier.uuidString.isEmpty == false, "uuid")
    var error: (any Error)?
    trigger.updateName("Timer") { error = $0 }
    hmRequire(error == nil && trigger.name == "Timer", "rename")
    trigger.updateName("") { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.stringShorterThanMinimum.rawValue, "empty")
}
