import Foundation

/// Geographic alarm proximity. Raw values match public `EKAlarm.h`.
public enum EKAlarmProximity: Int, Sendable {
    case none = 0
    case enter = 1
    case leave = 2
}

/// Alarm action kinds recorded on an `EKAlarm`. Raw values match public `EKAlarm.h`.
public enum EKAlarmType: Int, Sendable {
    case display = 0
    case audio = 1
    case procedure = 2
    case email = 3
}

/// Calendar and Reminders privacy status. `authorized` is the historical alias of
/// `fullAccess` (raw value 3), matching the public `EKAuthorizationStatus` overlay.
public enum EKAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case fullAccess = 3
    case writeOnly = 4

    public static var authorized: EKAuthorizationStatus { .fullAccess }
}

/// Bit mask of event availability values a calendar can store.
public struct EKCalendarEventAvailabilityMask: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let busy = EKCalendarEventAvailabilityMask(rawValue: 1 << 0)
    public static let free = EKCalendarEventAvailabilityMask(rawValue: 1 << 1)
    public static let tentative = EKCalendarEventAvailabilityMask(rawValue: 1 << 2)
    public static let unavailable = EKCalendarEventAvailabilityMask(rawValue: 1 << 3)
}

/// Calendar backing store. Raw values match public `EKCalendarType`.
public enum EKCalendarType: Int, Sendable {
    case local = 0
    case calDAV = 1
    case exchange = 2
    case subscription = 3
    case birthday = 4
}

/// Entity kinds an `EKEventStore` can authorize and query.
public enum EKEntityType: UInt, Sendable {
    case event = 0
    case reminder = 1
}

/// Bit mask of `EKEntityType` values.
public struct EKEntityMask: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let event = EKEntityMask(rawValue: 1 << EKEntityType.event.rawValue)
    public static let reminder = EKEntityMask(rawValue: 1 << EKEntityType.reminder.rawValue)
}

/// Free/busy status stored on an event. `-1` is the public "not supported" sentinel.
public enum EKEventAvailability: Int, Sendable {
    case notSupported = -1
    case busy = 0
    case free = 1
    case tentative = 2
    case unavailable = 3
}

/// Published event confirmation state.
public enum EKEventStatus: Int, Sendable {
    case none = 0
    case confirmed = 1
    case tentative = 2
    case canceled = 3
}

/// Attendee role on an event.
public enum EKParticipantRole: Int, Sendable {
    case unknown = 0
    case required = 1
    case optional = 2
    case chair = 3
    case nonParticipant = 4
}

/// Delivery state of a scheduling message.
public enum EKParticipantScheduleStatus: Int, Sendable {
    case none = 0
    case pending = 1
    case sent = 2
    case delivered = 3
    case recipientNotRecognized = 4
    case noPrivileges = 5
    case deliveryFailed = 6
    case cannotDeliver = 7
    case recipientNotAllowed = 8
}

/// RSVP/process state of an attendee.
public enum EKParticipantStatus: Int, Sendable {
    case unknown = 0
    case pending = 1
    case accepted = 2
    case declined = 3
    case tentative = 4
    case delegated = 5
    case completed = 6
    case inProcess = 7
}

/// Kind of calendar participant.
public enum EKParticipantType: Int, Sendable {
    case unknown = 0
    case person = 1
    case room = 2
    case resource = 3
    case group = 4
}

/// Recurrence cadence.
public enum EKRecurrenceFrequency: Int, Sendable {
    case daily = 0
    case weekly = 1
    case monthly = 2
    case yearly = 3
}

/// RFC 5545 priority bands used by reminders (`none`/`high`/`medium`/`low`).
public enum EKReminderPriority: UInt, Sendable {
    case none = 0
    case high = 1
    case medium = 5
    case low = 9
}

/// Account/source backing a calendar.
public enum EKSourceType: Int, Sendable {
    case local = 0
    case exchange = 1
    case calDAV = 2
    case mobileMe = 3
    case subscribed = 4
    case birthdays = 5
}

/// Span of a save/remove that affects a recurring event.
public enum EKSpan: Int, Sendable {
    case thisEvent = 0
    case futureEvents = 1
}

/// ICS/RFC 5545 weekday. Cases are 1-based Sunday…Saturday; `EKSunday` and
/// friends are the historical NS_ENUM aliases.
@frozen public enum EKWeekday: Int, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public static var EKSunday: EKWeekday { .sunday }
    public static var EKMonday: EKWeekday { .monday }
    public static var EKTuesday: EKWeekday { .tuesday }
    public static var EKWednesday: EKWeekday { .wednesday }
    public static var EKThursday: EKWeekday { .thursday }
    public static var EKFriday: EKWeekday { .friday }
    public static var EKSaturday: EKWeekday { .saturday }
}
