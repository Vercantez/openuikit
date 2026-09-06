import Foundation

/// Process-local monitoring registry shared by every `DeviceActivityCenter`.
/// Linux has no Screen Time daemon; this records schedules and events only.
enum DeviceActivityHostState {
    private static let lock = NSLock()
    private static var overridden = false
    private static var records: [DeviceActivityName: Record] = [:]

    struct Record: Equatable {
        var schedule: DeviceActivitySchedule
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    }

    static var isOverridden: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return overridden
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            overridden = newValue
        }
    }

    static var activities: [DeviceActivityName] {
        lock.lock()
        defer { lock.unlock() }
        return Array(records.keys)
    }

    static func record(for activity: DeviceActivityName) -> Record? {
        lock.lock()
        defer { lock.unlock() }
        return records[activity]
    }

    static func store(
        _ activity: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) {
        lock.lock()
        defer { lock.unlock() }
        records[activity] = Record(schedule: schedule, events: events)
    }

    static func remove(_ names: [DeviceActivityName]) {
        lock.lock()
        defer { lock.unlock() }
        if names.isEmpty {
            records.removeAll()
            return
        }
        for name in names {
            records.removeValue(forKey: name)
        }
    }

    static var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return records.count
    }

    static func contains(_ activity: DeviceActivityName) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return records[activity] != nil
    }

    static func resetForTests() {
        lock.lock()
        defer { lock.unlock() }
        overridden = false
        records.removeAll()
    }
}

/// Isolated-host reset for process-local DeviceActivity state.
public enum DeviceActivityIsolatedHost {
    public static func reset() {
        DeviceActivityHostState.resetForTests()
    }
}

/// Starts and stops process-local device-activity monitoring.
///
/// Documented Apple limits enforced here:
/// - at most twenty concurrent activities
/// - interval duration at least fifteen minutes
/// - interval duration at most one week
///
/// Without FamilyControls authorization, `startMonitoring` throws
/// `.unauthorized` unless `DeviceActivityAuthorization.isOverridden` is true.
/// Even then, no extension callbacks fire.
public struct DeviceActivityCenter: Equatable {
    public init() {}

    public var activities: [DeviceActivityName] {
        DeviceActivityHostState.activities
    }

    public func schedule(for activity: DeviceActivityName) -> DeviceActivitySchedule? {
        DeviceActivityHostState.record(for: activity)?.schedule
    }

    public func events(
        for activity: DeviceActivityName
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        DeviceActivityHostState.record(for: activity)?.events ?? [:]
    }

    public func stopMonitoring(_ activities: [DeviceActivityName] = []) {
        DeviceActivityHostState.remove(activities)
    }

    public func startMonitoring(
        _ activity: DeviceActivityName,
        during schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    ) throws {
        if !DeviceActivityAuthorization.isAuthorized,
           !DeviceActivityAuthorization.isOverridden
        {
            throw MonitoringError.unauthorized
        }
        guard let interval = DeviceActivityScheduleArithmetic.nextInterval(
            start: schedule.intervalStart,
            end: schedule.intervalEnd,
            repeats: schedule.repeats,
            now: Date()
        ) else {
            throw MonitoringError.invalidDateComponents
        }
        let duration = interval.duration
        if duration < DeviceActivityScheduleArithmetic.minimumMonitoringDuration {
            throw MonitoringError.intervalTooShort
        }
        if duration > DeviceActivityScheduleArithmetic.maximumMonitoringDuration {
            throw MonitoringError.intervalTooLong
        }
        if !DeviceActivityHostState.contains(activity),
           DeviceActivityHostState.count >= DeviceActivityScheduleArithmetic.maximumActivities
        {
            throw MonitoringError.excessiveActivities
        }
        DeviceActivityHostState.store(activity, schedule: schedule, events: events)
    }

    /// Errors thrown by `startMonitoring`.
    public enum MonitoringError: Error, Equatable, Hashable, LocalizedError {
        case excessiveActivities
        case intervalTooLong
        case intervalTooShort
        case invalidDateComponents
        case unauthorized

        public var errorDescription: String? {
            switch self {
            case .excessiveActivities:
                return "The calling process is monitoring too many activities."
            case .intervalTooLong:
                return "The activity’s schedule has an interval that is too long."
            case .intervalTooShort:
                return "The activity’s schedule has an interval that is too short."
            case .invalidDateComponents:
                return "The schedule’s date range is invalid."
            case .unauthorized:
                return "The calling process isn’t authorized to monitor device activity."
            }
        }

        public var recoverySuggestion: String? {
            switch self {
            case .excessiveActivities:
                return "Stop monitoring an existing activity before starting another. The documented maximum is twenty."
            case .intervalTooLong:
                return "Shorten the schedule so the interval is at most one week."
            case .intervalTooShort:
                return "Lengthen the schedule so the interval is at least fifteen minutes."
            case .invalidDateComponents:
                return "Provide date components that match a current or future interval."
            case .unauthorized:
                return "Request FamilyControls authorization before monitoring device activity."
            }
        }
    }
}
