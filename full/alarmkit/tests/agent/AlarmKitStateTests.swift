import Foundation
import AlarmKit

func testAlarmStateCases() {
    let cases: [Alarm.State] = [.scheduled, .countdown, .paused, .alerting]
    alarmKitExpectEqual(cases.count, 4, "four Alarm.State cases")
    alarmKitExpectEqual(Alarm.State.scheduled, .scheduled, "scheduled identity")
    alarmKitExpect(Alarm.State.countdown != .paused, "countdown is not paused")
    alarmKitExpect(Alarm.State.alerting != .scheduled, "alerting is not scheduled")
}

func testAlarmStateEquatableHashable() {
    alarmKitExpect(Alarm.State.scheduled == .scheduled, "state ==")
    alarmKitExpect(Alarm.State.scheduled != .alerting, "state !=")
    _ = Alarm.State.paused.hashValue
    var hasher = Hasher()
    Alarm.State.countdown.hash(into: &hasher)
    _ = hasher.finalize()
    alarmKitExpectEqual(
        Alarm.State.scheduled.hashValue,
        Alarm.State.scheduled.hashValue,
        "equal states hash equal"
    )
}

func testAlarmStateCodable() {
    for state in [Alarm.State.scheduled, .countdown, .paused, .alerting] {
        alarmKitExpectEqual(alarmKitRoundTrip(state), state, "state round-trip \(state)")
    }
}
