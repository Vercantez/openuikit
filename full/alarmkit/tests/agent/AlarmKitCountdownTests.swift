import Foundation
import AlarmKit

func testCountdownDurationInitAndProperties() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    alarmKitExpectEqual(duration.preAlert, 15, "preAlert")
    alarmKitExpectEqual(duration.postAlert, 30, "postAlert")
    let empty = Alarm.CountdownDuration(preAlert: nil, postAlert: nil)
    alarmKitExpect(empty.preAlert == nil, "nil preAlert")
    alarmKitExpect(empty.postAlert == nil, "nil postAlert")
}

func testCountdownDurationEquatable() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    let copy = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    alarmKitExpect(duration == copy, "CountdownDuration ==")
    alarmKitExpect(!(duration != copy), "CountdownDuration !=")
    alarmKitExpect(
        duration != Alarm.CountdownDuration(preAlert: nil, postAlert: nil),
        "nil duration differs"
    )
}

func testCountdownDurationCodable() {
    let duration = Alarm.CountdownDuration(preAlert: 15, postAlert: 30)
    let decoded = alarmKitRoundTrip(duration)
    alarmKitExpectEqual(decoded.preAlert, 15, "decoded preAlert")
    alarmKitExpectEqual(decoded.postAlert, 30, "decoded postAlert")
    let empty = alarmKitRoundTrip(Alarm.CountdownDuration(preAlert: nil, postAlert: nil))
    alarmKitExpect(empty.preAlert == nil, "decoded nil preAlert")
}
