import DeviceActivity
import Foundation

func deviceActivityRequire(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

func deviceActivityReset() {
    DeviceActivityIsolatedHost.reset()
}

func deviceActivityTodayInterval(hours: Int = 1) -> (start: DateComponents, end: DateComponents) {
    let calendar = Calendar.current
    let now = Date()
    let startDate = calendar.date(byAdding: .minute, value: -5, to: now) ?? now
    let endDate = calendar.date(byAdding: .minute, value: 15 * hours, to: startDate) ?? now
    var start = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: startDate
    )
    var end = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: endDate
    )
    start.calendar = calendar
    end.calendar = calendar
    return (start, end)
}

func deviceActivityLongInterval() -> (start: DateComponents, end: DateComponents) {
    let calendar = Calendar.current
    let now = Date()
    let startDate = calendar.date(byAdding: .minute, value: -5, to: now) ?? now
    let endDate = calendar.date(byAdding: .day, value: 8, to: startDate) ?? now
    var start = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: startDate
    )
    var end = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: endDate
    )
    start.calendar = calendar
    end.calendar = calendar
    return (start, end)
}

func deviceActivityShortInterval() -> (start: DateComponents, end: DateComponents) {
    let calendar = Calendar.current
    let now = Date()
    let startDate = calendar.date(byAdding: .minute, value: -1, to: now) ?? now
    let endDate = calendar.date(byAdding: .minute, value: 2, to: startDate) ?? now
    var start = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: startDate
    )
    var end = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: endDate
    )
    start.calendar = calendar
    end.calendar = calendar
    return (start, end)
}

func testDeviceActivityNameRawValue() {
    let name = DeviceActivityName("daily-limit")
    deviceActivityRequire(name.rawValue == "daily-limit", "init(_)")
    let fromRaw = DeviceActivityName(rawValue: "daily-limit")
    deviceActivityRequire(fromRaw.rawValue == "daily-limit", "init(rawValue:)")
    deviceActivityRequire(name == fromRaw, "equal names")
    deviceActivityRequire(name != DeviceActivityName("other"), "unequal names")
    var hasher = Hasher()
    name.hash(into: &hasher)
    deviceActivityRequire(name.hashValue == fromRaw.hashValue, "hashValue")
}

func testDeviceActivityEventNameRawValue() {
    let name = DeviceActivityEvent.Name("threshold")
    deviceActivityRequire(name.rawValue == "threshold", "init(_)")
    let fromRaw = DeviceActivityEvent.Name(rawValue: "threshold")
    deviceActivityRequire(fromRaw == name, "event name equal")
    deviceActivityRequire(name != DeviceActivityEvent.Name("other"), "unequal")
    var hasher = Hasher()
    name.hash(into: &hasher)
    deviceActivityRequire(name.hashValue == fromRaw.hashValue, "hashValue")
}

func testDeviceActivityEventIncludesAllActivity() {
    let threshold = DateComponents(hour: 1)
    let event = DeviceActivityEvent(threshold: threshold, includesPastActivity: false)
    deviceActivityRequire(event.threshold.hour == 1, "threshold")
    deviceActivityRequire(event.includesPastActivity == false, "past default")
    deviceActivityRequire(event.includesAllActivity, "empty tokens => all activity")
    let past = DeviceActivityEvent(threshold: threshold, includesPastActivity: true)
    deviceActivityRequire(past.includesPastActivity, "includesPastActivity")
    deviceActivityRequire(event != past, "past flag inequality")
    deviceActivityRequire(event == DeviceActivityEvent(threshold: threshold), "equal events")
}
