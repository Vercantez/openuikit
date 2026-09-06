@_exported import Foundation

/// Isolated Linux starting point for Apple's DeviceActivity module.
///
/// Value types, schedule arithmetic, and a process-local monitoring registry
/// are real. Screen Time daemons, FamilyControls entitlements, ManagedSettings
/// tokens, and SwiftUI report UI stay fail-closed. See `README.md`.
enum DeviceActivityModuleMarker {
    static let name = "DeviceActivity"
}

// MARK: - Names

/// The unique name of a device-activity monitoring session.
public struct DeviceActivityName: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = String

    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Schedule

/// A calendar-based schedule for when to monitor a device's activity.
///
/// `nextInterval` follows the public matching rule: `Calendar.current` when
/// neither component carries a calendar, and
/// `Calendar.MatchingPolicy.nextTimePreservingSmallerComponents`.
public struct DeviceActivitySchedule: Equatable, Sendable {
    public let intervalStart: DateComponents
    public let intervalEnd: DateComponents
    public let repeats: Bool
    public let warningTime: DateComponents?

    public init(
        intervalStart: DateComponents,
        intervalEnd: DateComponents,
        repeats: Bool,
        warningTime: DateComponents? = nil
    ) {
        self.intervalStart = intervalStart
        self.intervalEnd = intervalEnd
        self.repeats = repeats
        self.warningTime = warningTime
    }

    /// The current interval if one is ongoing, otherwise the next future
    /// interval. `nil` when the components match no current or future dates.
    public var nextInterval: DateInterval? {
        DeviceActivityScheduleArithmetic.nextInterval(
            start: intervalStart,
            end: intervalEnd,
            repeats: repeats,
            now: Date()
        )
    }
}

enum DeviceActivityScheduleArithmetic {
    static let minimumMonitoringDuration: TimeInterval = 15 * 60
    static let maximumMonitoringDuration: TimeInterval = 7 * 24 * 60 * 60
    static let maximumActivities = 20

    static func calendar(
        start: DateComponents,
        end: DateComponents
    ) -> Calendar {
        start.calendar ?? end.calendar ?? Calendar.current
    }

    static func nextInterval(
        start: DateComponents,
        end: DateComponents,
        repeats: Bool,
        now: Date
    ) -> DateInterval? {
        let calendar = calendar(start: start, end: end)
        guard let startDate = matchDate(
            calendar: calendar,
            matching: start,
            around: now,
            repeats: repeats
        ) else {
            return nil
        }
        guard let endDate = matchedEndDate(
            calendar: calendar,
            startDate: startDate,
            end: end,
            repeats: repeats
        ), endDate > startDate else {
            return nil
        }
        let interval = DateInterval(start: startDate, end: endDate)
        if now >= startDate && now < endDate {
            return interval
        }
        if startDate > now {
            return interval
        }
        if !repeats {
            return nil
        }
        guard let nextStart = calendar.nextDate(
            after: startDate,
            matching: start,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        ) else {
            return nil
        }
        guard let nextEnd = matchedEndDate(
            calendar: calendar,
            startDate: nextStart,
            end: end,
            repeats: repeats
        ), nextEnd > nextStart else {
            return nil
        }
        return DateInterval(start: nextStart, end: nextEnd)
    }

    static func matchDate(
        calendar: Calendar,
        matching components: DateComponents,
        around now: Date,
        repeats: Bool
    ) -> Date? {
        if !repeats, let exact = calendar.date(from: components) {
            return exact
        }
        if let backward = calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .backward
        ) {
            return backward
        }
        return calendar.nextDate(
            after: now.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        )
    }

    static func matchedEndDate(
        calendar: Calendar,
        startDate: Date,
        end: DateComponents,
        repeats: Bool
    ) -> Date? {
        if !repeats, let exact = calendar.date(from: end), exact > startDate {
            return exact
        }
        if let sameDay = calendar.nextDate(
            after: startDate.addingTimeInterval(-1),
            matching: end,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        ), sameDay > startDate {
            return sameDay
        }
        return calendar.nextDate(
            after: startDate,
            matching: end,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        )
    }
}

// MARK: - Event

/// An event that represents application, category, or website activity.
///
/// Isolated Linux construction cannot take ManagedSettings tokens. Empty
/// token sets make `includesAllActivity` `true`, matching the public rule.
public struct DeviceActivityEvent: Equatable, Sendable {
    public struct Name: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = String
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let threshold: DateComponents
    public let includesPastActivity: Bool
    let applicationTokenCount: Int
    let categoryTokenCount: Int
    let webDomainTokenCount: Int

    /// Linux isolated constructor. Token-typed Apple inits require
    /// ManagedSettings and stay deferred.
    public init(
        threshold: DateComponents,
        includesPastActivity: Bool = false
    ) {
        self.threshold = threshold
        self.includesPastActivity = includesPastActivity
        self.applicationTokenCount = 0
        self.categoryTokenCount = 0
        self.webDomainTokenCount = 0
    }

    /// `true` when applications, categories, and webDomains are all empty.
    public var includesAllActivity: Bool {
        applicationTokenCount == 0
            && categoryTokenCount == 0
            && webDomainTokenCount == 0
    }
}

// MARK: - Filter

/// A filter that selects which device-activity records a report should include.
public struct DeviceActivityFilter: Equatable, Hashable, Sendable {
    public enum SegmentInterval: Hashable, Sendable {
        case hourly(
            during: DateInterval = DateInterval(
                start: Calendar.current.startOfDay(for: Date()),
                end: Date()
            )
        )
        case daily(during: DateInterval)
        case weekly(during: DateInterval)
    }

    public struct Users: Hashable, Sendable {
        enum Kind: Hashable, Sendable {
            case all
            case children
        }

        let kind: Kind

        public static let all = Users(kind: .all)
        public static let children = Users(kind: .children)
    }

    public struct Devices: Hashable, Sendable {
        enum Kind: Hashable, Sendable {
            case all
            case models(Set<DeviceActivityData.Device.Model>)
        }

        let kind: Kind

        private init(kind: Kind) {
            self.kind = kind
        }

        public static let all = Devices(kind: .all)

        public init(_ models: Set<DeviceActivityData.Device.Model>) {
            self.kind = .models(models)
        }
    }

    public var segmentInterval: SegmentInterval
    public let users: Users?
    public let devices: Devices?

    public init(
        segment segmentInterval: SegmentInterval = .hourly(),
        devices: Devices? = nil
    ) {
        self.segmentInterval = segmentInterval
        self.users = nil
        self.devices = devices
    }

    public init(
        segment segmentInterval: SegmentInterval = .hourly(),
        users: Users,
        devices: Devices
    ) {
        self.segmentInterval = segmentInterval
        self.users = users
        self.devices = devices
    }
}

// MARK: - Authorization

/// Process-local authorization bits. Linux has no FamilyControls / Screen Time
/// service, so `isAuthorized` is `false` unless `isOverridden` is set.
public protocol DeviceActivityAuthorizing {
    static var isAuthorized: Bool { get }
    static func isAuthorized(_ bundleIdentifier: String) -> Bool
}

/// Fail-closed authorization surface for DeviceActivity.
open class DeviceActivityAuthorization: NSObject, DeviceActivityAuthorizing {
    public override init() {
        super.init()
    }

    public static var isAuthorized: Bool {
        DeviceActivityHostState.isOverridden
    }

    public static func isAuthorized(_ bundleIdentifier: String) -> Bool {
        _ = bundleIdentifier
        return DeviceActivityHostState.isOverridden
    }

    public static var authorizedClientIdentifiers: [String] {
        []
    }

    public static var isOverridden: Bool {
        get { DeviceActivityHostState.isOverridden }
        set { DeviceActivityHostState.isOverridden = newValue }
    }

    public static var sharingEnabled: Bool { false }
}

// MARK: - Monitor extension principal class

/// App-extension principal class for interval and threshold callbacks.
///
/// Linux never hosts a DeviceActivityMonitor extension, so these methods are
/// inert no-ops unless a test subclass records calls.
open class DeviceActivityMonitor: NSObject {
    public override init() {
        super.init()
    }

    open func intervalDidEnd(for activity: DeviceActivityName) {
        _ = activity
    }

    open func intervalDidStart(for activity: DeviceActivityName) {
        _ = activity
    }

    open func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        _ = (event, activity)
    }

    open func intervalWillEndWarning(for activity: DeviceActivityName) {
        _ = activity
    }

    open func intervalWillStartWarning(for activity: DeviceActivityName) {
        _ = activity
    }

    open func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        _ = (event, activity)
    }
}
