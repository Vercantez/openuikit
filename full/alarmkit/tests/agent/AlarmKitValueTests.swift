import Foundation
import AlarmKit

func testAlarmIDTypealias() {
    let id: Alarm.ID = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
    alarmKitExpectEqual(
        id,
        UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        "Alarm.ID is UUID"
    )
}

func testAlarmDecodeEncode() {
    let payload: [String: Any] = [
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "state": "scheduled",
        "schedule": [
            "relative": [
                "time": ["hour": 6, "minute": 45],
                "repeats": ["weekly": ["mon", "wed"]],
            ]
        ],
        "countdownDuration": ["preAlert": 10, "postAlert": 20],
    ]
    let data: Data
    let alarm: Alarm
    do {
        data = try JSONSerialization.data(withJSONObject: payload)
        alarm = try JSONDecoder().decode(Alarm.self, from: data)
    } catch {
        fatalError("ALARMKIT_TEST_FAIL decode Alarm: \(error)")
    }
    alarmKitExpectEqual(
        alarm.id,
        UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        "alarm id"
    )
    alarmKitExpectEqual(alarm.state, .scheduled, "alarm state")
    alarmKitExpectEqual(alarm.countdownDuration?.preAlert, 10, "alarm preAlert")
    alarmKitExpectEqual(alarm.countdownDuration?.postAlert, 20, "alarm postAlert")
    if case .relative(let relative) = alarm.schedule {
        alarmKitExpectEqual(relative.time.hour, 6, "decoded hour")
        alarmKitExpectEqual(relative.time.minute, 45, "decoded minute")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected relative schedule on alarm")
    }
    let encoded = alarmKitRoundTrip(alarm)
    alarmKitExpectEqual(encoded.id, alarm.id, "round-trip id")
    alarmKitExpectEqual(encoded.state, alarm.state, "round-trip state")
    alarmKitExpectEqual(
        encoded.countdownDuration?.preAlert,
        alarm.countdownDuration?.preAlert,
        "round-trip countdown"
    )
}
