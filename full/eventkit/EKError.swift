import Foundation

/// Apple's public EventKit error domain string, taken from `EKError.h`.
public let EKErrorDomain = "EKErrorDomain"

/// Portable counterpart of EventKit's bridged `NS_ERROR_ENUM(EKErrorDomain)`.
///
/// Numeric codes follow the public Xcode 26.1 `EKErrorCode` enumeration order
/// (`eventNotMutable = 0` through `last`). Stored `userInfo` is preserved
/// exactly; this overlay does not insert a default localized-description entry.
public struct EKError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case eventNotMutable = 0
        case noStartDate = 1
        case noEndDate = 2
        case datesInverted = 3
        case internalFailure = 4
        case calendarReadOnly = 5
        case durationGreaterThanRecurrence = 6
        case alarmGreaterThanRecurrence = 7
        case startDateTooFarInFuture = 8
        case startDateCollidesWithOtherOccurrence = 9
        case objectBelongsToDifferentStore = 10
        case invitesCannotBeMoved = 11
        case invalidSpan = 12
        case calendarHasNoSource = 13
        case calendarSourceCannotBeModified = 14
        case calendarIsImmutable = 15
        case sourceDoesNotAllowCalendarAddDelete = 16
        case recurringReminderRequiresDueDate = 17
        case structuredLocationsNotSupported = 18
        case reminderLocationsNotSupported = 19
        case alarmProximityNotSupported = 20
        case calendarDoesNotAllowEvents = 21
        case calendarDoesNotAllowReminders = 22
        case sourceDoesNotAllowEvents = 23
        case sourceDoesNotAllowReminders = 24
        case priorityIsInvalid = 25
        case invalidEntityType = 26
        case procedureAlarmsNotMutable = 27
        case eventStoreNotAuthorized = 28
        case osNotSupported = 29
        case invalidInviteReplyCalendar = 30
        case notificationsCollectionFlagNotSet = 31
        case sourceMismatch = 32
        case notificationCollectionMismatch = 33
        case notificationSavedWithoutCollection = 34
        case reminderAlarmContainsEmailOrUrl = 35
        case noCalendar = 36
        case last = 37
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { EKErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let eventNotMutable = Code.eventNotMutable
    public static let noStartDate = Code.noStartDate
    public static let noEndDate = Code.noEndDate
    public static let datesInverted = Code.datesInverted
    public static let internalFailure = Code.internalFailure
    public static let calendarReadOnly = Code.calendarReadOnly
    public static let durationGreaterThanRecurrence = Code.durationGreaterThanRecurrence
    public static let alarmGreaterThanRecurrence = Code.alarmGreaterThanRecurrence
    public static let startDateTooFarInFuture = Code.startDateTooFarInFuture
    public static let startDateCollidesWithOtherOccurrence = Code.startDateCollidesWithOtherOccurrence
    public static let objectBelongsToDifferentStore = Code.objectBelongsToDifferentStore
    public static let invitesCannotBeMoved = Code.invitesCannotBeMoved
    public static let invalidSpan = Code.invalidSpan
    public static let calendarHasNoSource = Code.calendarHasNoSource
    public static let calendarSourceCannotBeModified = Code.calendarSourceCannotBeModified
    public static let calendarIsImmutable = Code.calendarIsImmutable
    public static let sourceDoesNotAllowCalendarAddDelete = Code.sourceDoesNotAllowCalendarAddDelete
    public static let recurringReminderRequiresDueDate = Code.recurringReminderRequiresDueDate
    public static let structuredLocationsNotSupported = Code.structuredLocationsNotSupported
    public static let reminderLocationsNotSupported = Code.reminderLocationsNotSupported
    public static let alarmProximityNotSupported = Code.alarmProximityNotSupported
    public static let calendarDoesNotAllowEvents = Code.calendarDoesNotAllowEvents
    public static let calendarDoesNotAllowReminders = Code.calendarDoesNotAllowReminders
    public static let sourceDoesNotAllowEvents = Code.sourceDoesNotAllowEvents
    public static let sourceDoesNotAllowReminders = Code.sourceDoesNotAllowReminders
    public static let priorityIsInvalid = Code.priorityIsInvalid
    public static let invalidEntityType = Code.invalidEntityType
    public static let procedureAlarmsNotMutable = Code.procedureAlarmsNotMutable
    public static let eventStoreNotAuthorized = Code.eventStoreNotAuthorized
    public static let osNotSupported = Code.osNotSupported
    public static let invalidInviteReplyCalendar = Code.invalidInviteReplyCalendar
    public static let notificationsCollectionFlagNotSet = Code.notificationsCollectionFlagNotSet
    public static let sourceMismatch = Code.sourceMismatch
    public static let notificationCollectionMismatch = Code.notificationCollectionMismatch
    public static let notificationSavedWithoutCollection = Code.notificationSavedWithoutCollection
    public static let reminderAlarmContainsEmailOrUrl = Code.reminderAlarmContainsEmailOrUrl
    public static let noCalendar = Code.noCalendar
    public static let last = Code.last

    public static func == (lhs: EKError, rhs: EKError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension EKError.Code {
    public static func ~= (match: EKError.Code, error: any Error) -> Bool {
        (error as? EKError)?.code == match
    }
}

func EKMakeError(_ code: EKError.Code, userInfo: [String: Any] = [:]) -> EKError {
    EKError(code, userInfo: userInfo)
}
