import Foundation
import AlarmKit

func testScheduleRelativeTime() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    alarmKitExpectEqual(time.hour, 7, "hour")
    alarmKitExpectEqual(time.minute, 30, "minute")
    alarmKitExpect(time == Alarm.Schedule.Relative.Time(hour: 7, minute: 30), "Time ==")
    alarmKitExpect(time != Alarm.Schedule.Relative.Time(hour: 8, minute: 0), "Time !=")
    _ = time.hashValue
    var hasher = Hasher()
    time.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRelativeTimeCodable() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    let decoded = alarmKitRoundTrip(time)
    alarmKitExpectEqual(decoded.hour, 7, "decoded time hour")
    alarmKitExpectEqual(decoded.minute, 30, "decoded time minute")
}

func testScheduleRecurrenceCases() {
    alarmKitExpect(Alarm.Schedule.Relative.Recurrence.never == .never, "never ==")
    alarmKitExpect(
        Alarm.Schedule.Relative.Recurrence.never != .weekly([.monday]),
        "never !="
    )
    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    alarmKitExpect(weekly == .weekly([.monday, .friday]), "weekly ==")
    _ = Alarm.Schedule.Relative.Recurrence.never.hashValue
    var hasher = Hasher()
    weekly.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRecurrenceCodable() {
    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    alarmKitExpectEqual(alarmKitRoundTrip(weekly), weekly, "decoded weekly")
    alarmKitExpectEqual(
        alarmKitRoundTrip(Alarm.Schedule.Relative.Recurrence.never),
        .never,
        "decoded never"
    )
}

func testScheduleRelativeInit() {
    let time = Alarm.Schedule.Relative.Time(hour: 7, minute: 30)
    let never = Alarm.Schedule.Relative(time: time)
    alarmKitExpectEqual(never.time.hour, 7, "relative hour")
    alarmKitExpect(never.repeats == .never, "default repeats")
    let weekly = Alarm.Schedule.Relative(
        time: time,
        repeats: .weekly([.monday, .friday])
    )
    alarmKitExpect(weekly.repeats == .weekly([.monday, .friday]), "weekly repeats")
    alarmKitExpect(weekly != never, "relative !=")
    alarmKitExpect(weekly == weekly, "relative ==")
    _ = weekly.hashValue
    var hasher = Hasher()
    never.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleRelativeCodable() {
    let relative = Alarm.Schedule.Relative(
        time: Alarm.Schedule.Relative.Time(hour: 6, minute: 45),
        repeats: .weekly([.monday, .wednesday])
    )
    let decoded = alarmKitRoundTrip(relative)
    alarmKitExpectEqual(decoded.time.hour, 6, "decoded relative hour")
    alarmKitExpectEqual(decoded.time.minute, 45, "decoded relative minute")
    alarmKitExpect(decoded.repeats == .weekly([.monday, .wednesday]), "decoded repeats")
}

func testScheduleFixedAndRelativeCases() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let fixed = Alarm.Schedule.fixed(date)
    let relative = Alarm.Schedule.relative(
        Alarm.Schedule.Relative(time: Alarm.Schedule.Relative.Time(hour: 7, minute: 30))
    )
    alarmKitExpect(fixed != relative, "schedule !=")
    alarmKitExpect(fixed == Alarm.Schedule.fixed(date), "fixed ==")
    _ = fixed.hashValue
    var hasher = Hasher()
    relative.hash(into: &hasher)
    _ = hasher.finalize()
}

func testScheduleCodable() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let fixed = Alarm.Schedule.fixed(date)
    let decodedFixed = alarmKitRoundTrip(fixed)
    if case .fixed(let decodedDate) = decodedFixed {
        alarmKitExpectEqual(
            decodedDate.timeIntervalSince1970,
            date.timeIntervalSince1970,
            "fixed date"
        )
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected fixed schedule")
    }

    let weekly = Alarm.Schedule.Relative.Recurrence.weekly([.monday, .friday])
    let relativeSchedule = Alarm.Schedule.relative(
        Alarm.Schedule.Relative(
            time: Alarm.Schedule.Relative.Time(hour: 7, minute: 30),
            repeats: weekly
        )
    )
    let decodedRelative = alarmKitRoundTrip(relativeSchedule)
    if case .relative(let decoded) = decodedRelative {
        alarmKitExpectEqual(decoded.time.hour, 7, "decoded relative hour")
        alarmKitExpectEqual(decoded.time.minute, 30, "decoded relative minute")
        alarmKitExpect(decoded.repeats == weekly, "decoded weekly")
    } else {
        fatalError("ALARMKIT_TEST_FAIL: expected relative schedule")
    }
}
