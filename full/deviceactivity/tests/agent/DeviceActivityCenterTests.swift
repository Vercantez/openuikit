import DeviceActivity
import Foundation

func testDeviceActivityCenterUnauthorized() {
    deviceActivityReset()
    deviceActivityRequire(!DeviceActivityAuthorization.isAuthorized, "fail-closed")
    let center = DeviceActivityCenter()
    let parts = deviceActivityTodayInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    do {
        try center.startMonitoring(DeviceActivityName("blocked"), during: schedule)
        fatalError("expected unauthorized")
    } catch let error as DeviceActivityCenter.MonitoringError {
        deviceActivityRequire(error == .unauthorized, "unauthorized")
    } catch {
        fatalError("unexpected \(error)")
    }
    deviceActivityRequire(center.activities.isEmpty, "no activities recorded")
}

func testDeviceActivityCenterStartStopAndQuery() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let name = DeviceActivityName("daily")
    let parts = deviceActivityTodayInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    let eventName = DeviceActivityEvent.Name("hour")
    let event = DeviceActivityEvent(
        threshold: DateComponents(hour: 1),
        includesPastActivity: true
    )
    try! center.startMonitoring(name, during: schedule, events: [eventName: event])
    deviceActivityRequire(center.activities.contains(name), "recorded")
    deviceActivityRequire(center.schedule(for: name) == schedule, "schedule(for:)")
    deviceActivityRequire(center.events(for: name)[eventName] == event, "events(for:)")
    let missing = DeviceActivityName("absent")
    deviceActivityRequire(center.schedule(for: missing) == nil, "missing schedule")
    deviceActivityRequire(center.events(for: missing).isEmpty, "missing events")
    let later = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: true
    )
    try! center.startMonitoring(name, during: later)
    deviceActivityRequire(center.activities.count == 1, "overwrite does not duplicate")
    deviceActivityRequire(center.schedule(for: name)?.repeats == true, "overwrite schedule")
    center.stopMonitoring([name])
    deviceActivityRequire(!center.activities.contains(name), "stopped")
}

func testDeviceActivityCenterStopMonitoringEmptyStopsAll() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let parts = deviceActivityTodayInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    try! center.startMonitoring(DeviceActivityName("a"), during: schedule)
    try! center.startMonitoring(DeviceActivityName("b"), during: schedule)
    deviceActivityRequire(center.activities.count == 2, "two activities")
    center.stopMonitoring()
    deviceActivityRequire(center.activities.isEmpty, "empty stop clears all")
}

func testDeviceActivityCenterOverwriteSameName() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let name = DeviceActivityName("same")
    let parts = deviceActivityTodayInterval()
    let first = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    try! center.startMonitoring(name, during: first)
    let later = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: true
    )
    try! center.startMonitoring(name, during: later)
    deviceActivityRequire(center.activities.count == 1, "overwrite does not duplicate")
    deviceActivityRequire(center.schedule(for: name)?.repeats == true, "overwrite schedule")
}

func testDeviceActivityCenterIntervalTooShort() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let parts = deviceActivityShortInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    do {
        try center.startMonitoring(DeviceActivityName("short"), during: schedule)
        fatalError("expected intervalTooShort")
    } catch let error as DeviceActivityCenter.MonitoringError {
        deviceActivityRequire(error == .intervalTooShort, "short")
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testDeviceActivityCenterIntervalTooLong() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let parts = deviceActivityLongInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    do {
        try center.startMonitoring(DeviceActivityName("long"), during: schedule)
        fatalError("expected intervalTooLong")
    } catch let error as DeviceActivityCenter.MonitoringError {
        deviceActivityRequire(error == .intervalTooLong, "long")
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testDeviceActivityCenterInvalidDateComponents() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    var start = DateComponents()
    start.year = 2020
    start.month = 1
    start.day = 1
    start.hour = 9
    var end = DateComponents()
    end.year = 2020
    end.month = 1
    end.day = 1
    end.hour = 10
    let schedule = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: false
    )
    do {
        try center.startMonitoring(DeviceActivityName("past"), during: schedule)
        fatalError("expected invalidDateComponents")
    } catch let error as DeviceActivityCenter.MonitoringError {
        deviceActivityRequire(error == .invalidDateComponents, "invalid")
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testDeviceActivityCenterExcessiveActivities() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    let center = DeviceActivityCenter()
    let parts = deviceActivityTodayInterval()
    let schedule = DeviceActivitySchedule(
        intervalStart: parts.start,
        intervalEnd: parts.end,
        repeats: false
    )
    for index in 0..<20 {
        try! center.startMonitoring(DeviceActivityName("slot-\(index)"), during: schedule)
    }
    deviceActivityRequire(center.activities.count == 20, "cap filled")
    do {
        try center.startMonitoring(DeviceActivityName("overflow"), during: schedule)
        fatalError("expected excessiveActivities")
    } catch let error as DeviceActivityCenter.MonitoringError {
        deviceActivityRequire(error == .excessiveActivities, "excessive")
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testDeviceActivityCenterEquatable() {
    deviceActivityRequire(DeviceActivityCenter() == DeviceActivityCenter(), "empty equal")
}
