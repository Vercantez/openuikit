import DeviceActivity
import Foundation

func testDeviceActivityScheduleStoresComponents() {
    let start = DateComponents(hour: 9, minute: 0)
    let end = DateComponents(hour: 17, minute: 0)
    let warning = DateComponents(minute: 5)
    let schedule = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: true,
        warningTime: warning
    )
    deviceActivityRequire(schedule.intervalStart.hour == 9, "start")
    deviceActivityRequire(schedule.intervalEnd.hour == 17, "end")
    deviceActivityRequire(schedule.repeats, "repeats")
    deviceActivityRequire(schedule.warningTime?.minute == 5, "warning")
    let other = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: true,
        warningTime: warning
    )
    deviceActivityRequire(schedule == other, "equal schedules")
    let nonRepeating = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: false
    )
    deviceActivityRequire(schedule != nonRepeating, "repeats inequality")
    deviceActivityRequire(nonRepeating.warningTime == nil, "default warning nil")
}

func testDeviceActivityScheduleNextIntervalCurrent() {
    let parts = deviceActivityTodayInterval(hours: 1)
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    let interval = schedule.nextInterval
    deviceActivityRequire(interval != nil, "current interval exists")
    if let interval {
        deviceActivityRequire(interval.duration >= 14 * 60, "duration")
        deviceActivityRequire(interval.start <= Date(), "started")
        deviceActivityRequire(interval.end > Date(), "not ended")
    }

    var pastStart = DateComponents()
    pastStart.calendar = Calendar.current
    pastStart.year = 2020
    pastStart.month = 1
    pastStart.day = 1
    pastStart.hour = 9
    var pastEnd = DateComponents()
    pastEnd.calendar = Calendar.current
    pastEnd.year = 2020
    pastEnd.month = 1
    pastEnd.day = 1
    pastEnd.hour = 10
    let past = DeviceActivitySchedule(
        intervalStart: pastStart,
        intervalEnd: pastEnd,
        repeats: false
    )
    deviceActivityRequire(past.nextInterval == nil, "past non-repeating is nil")
}

func testDeviceActivityScheduleNextIntervalPastNonRepeatingIsNil() {
    let calendar = Calendar.current
    var start = DateComponents()
    start.calendar = calendar
    start.year = 2020
    start.month = 1
    start.day = 1
    start.hour = 9
    var end = DateComponents()
    end.calendar = calendar
    end.year = 2020
    end.month = 1
    end.day = 1
    end.hour = 10
    let schedule = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: false
    )
    deviceActivityRequire(schedule.nextInterval == nil, "past non-repeating is nil")
}
