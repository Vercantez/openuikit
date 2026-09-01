import Foundation

extension Notification.Name {
    /// Posted on Apple platforms when the Calendar or Reminders database changes.
    /// This Linux starting point never posts it: there is no host store to observe.
    public static let EKEventStoreChanged = Notification.Name("EKEventStoreChangedNotification")
}

/// Process-local EventKit store.
///
/// Linux has no Calendar/Reminders privacy prompt and no Apple calendar
/// database. Authorization is fail-closed (`denied`). Save/remove/commit throw
/// `EKError.eventStoreNotAuthorized`. Fetch APIs return empty results. In-memory
/// object construction (events, reminders, alarms, recurrence) still works so
/// callers can assemble values without claiming a successful host write.
open class EKEventStore: NSObject {
    public let eventStoreIdentifier: String
    public private(set) var sources: [EKSource]
    public var delegateSources: [EKSource] { sources.filter(\.isDelegate) }
    public var defaultCalendarForNewEvents: EKCalendar? { nil }

    public override init() {
        eventStoreIdentifier = UUID().uuidString
        sources = []
        super.init()
    }

    public init(sources: [EKSource]) {
        eventStoreIdentifier = UUID().uuidString
        self.sources = sources
        super.init()
        for source in sources {
            source.bind(to: self)
        }
    }

    open class func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus {
        _ = entityType
        return .denied
    }

    open func requestAccess(to entityType: EKEntityType) async throws -> Bool {
        _ = entityType
        throw EKMakeError(.osNotSupported)
    }

    open func requestFullAccessToEvents(
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        completion(false, EKMakeError(.osNotSupported))
    }

    open func requestFullAccessToReminders(
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        completion(false, EKMakeError(.osNotSupported))
    }

    open func requestWriteOnlyAccessToEvents(
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        completion(false, EKMakeError(.osNotSupported))
    }

    open func defaultCalendarForNewReminders() -> EKCalendar? {
        nil
    }

    open func calendars(for entityType: EKEntityType) -> [EKCalendar] {
        _ = entityType
        return []
    }

    open func calendar(withIdentifier identifier: String) -> EKCalendar? {
        _ = identifier
        return nil
    }

    open func source(withIdentifier identifier: String) -> EKSource? {
        sources.first { $0.sourceIdentifier == identifier }
    }

    open func calendarItem(withIdentifier identifier: String) -> EKCalendarItem? {
        _ = identifier
        return nil
    }

    open func calendarItems(withExternalIdentifier externalIdentifier: String) -> [EKCalendarItem] {
        _ = externalIdentifier
        return []
    }

    open func event(withIdentifier identifier: String) -> EKEvent? {
        _ = identifier
        return nil
    }

    open func events(matching predicate: NSPredicate) -> [EKEvent] {
        _ = predicate
        return []
    }

    open func enumerateEvents(
        matching predicate: NSPredicate,
        using block: @escaping EKEventSearchCallback
    ) {
        _ = (predicate, block)
    }

    open func fetchReminders(
        matching predicate: NSPredicate,
        completion: @escaping ([EKReminder]?) -> Void
    ) -> Any {
        _ = predicate
        completion(nil)
        return NSObject()
    }

    open func cancelFetchRequest(_ fetchIdentifier: Any) {
        _ = fetchIdentifier
    }

    open func predicateForEvents(
        withStart startDate: Date,
        end endDate: Date,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarIDs = Set((calendars ?? []).map(\.calendarIdentifier))
        return NSPredicate { object, _ in
            guard let event = object as? EKEvent else { return false }
            guard let eventStart = event.startDate, let eventEnd = event.endDate else {
                return false
            }
            if eventEnd <= startDate || eventStart >= endDate {
                return false
            }
            if !calendarIDs.isEmpty {
                guard let calendar = event.calendar,
                      calendarIDs.contains(calendar.calendarIdentifier)
                else {
                    return false
                }
            }
            return true
        }
    }

    open func predicateForReminders(in calendars: [EKCalendar]?) -> NSPredicate {
        let calendarIDs = Set((calendars ?? []).map(\.calendarIdentifier))
        return NSPredicate { object, _ in
            guard let reminder = object as? EKReminder else { return false }
            if calendarIDs.isEmpty { return true }
            guard let calendar = reminder.calendar,
                  calendarIDs.contains(calendar.calendarIdentifier)
            else {
                return false
            }
            return true
        }
    }

    open func predicateForIncompleteReminders(
        withDueDateStarting startDate: Date?,
        ending endDate: Date?,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarIDs = Set((calendars ?? []).map(\.calendarIdentifier))
        return NSPredicate { object, _ in
            guard let reminder = object as? EKReminder, !reminder.isCompleted else {
                return false
            }
            if !Self.dueDate(reminder.dueDateComponents, starts: startDate, ends: endDate) {
                return false
            }
            if calendarIDs.isEmpty { return true }
            guard let calendar = reminder.calendar,
                  calendarIDs.contains(calendar.calendarIdentifier)
            else {
                return false
            }
            return true
        }
    }

    open func predicateForCompletedReminders(
        withCompletionDateStarting startDate: Date?,
        ending endDate: Date?,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarIDs = Set((calendars ?? []).map(\.calendarIdentifier))
        return NSPredicate { object, _ in
            guard let reminder = object as? EKReminder, reminder.isCompleted else {
                return false
            }
            if let completion = reminder.completionDate {
                if let startDate, completion < startDate { return false }
                if let endDate, completion > endDate { return false }
            } else if startDate != nil || endDate != nil {
                return false
            }
            if calendarIDs.isEmpty { return true }
            guard let calendar = reminder.calendar,
                  calendarIDs.contains(calendar.calendarIdentifier)
            else {
                return false
            }
            return true
        }
    }

    open func saveCalendar(_ calendar: EKCalendar, commit: Bool) throws {
        _ = (calendar, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func removeCalendar(_ calendar: EKCalendar, commit: Bool) throws {
        _ = (calendar, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func save(_ event: EKEvent, span: EKSpan) throws {
        try save(event, span: span, commit: true)
    }

    open func save(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
        _ = (event, span, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func remove(_ event: EKEvent, span: EKSpan) throws {
        try remove(event, span: span, commit: true)
    }

    open func remove(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
        _ = (event, span, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func save(_ reminder: EKReminder, commit: Bool) throws {
        _ = (reminder, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func remove(_ reminder: EKReminder, commit: Bool) throws {
        _ = (reminder, commit)
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func commit() throws {
        throw EKMakeError(.eventStoreNotAuthorized)
    }

    open func refreshSourcesIfNecessary() {}

    open func reset() {}

    private static func dueDate(
        _ components: DateComponents?,
        starts startDate: Date?,
        ends endDate: Date?
    ) -> Bool {
        if startDate == nil && endDate == nil {
            return true
        }
        guard let components,
              let due = Calendar.current.date(from: components)
        else {
            return false
        }
        if let startDate, due < startDate { return false }
        if let endDate, due > endDate { return false }
        return true
    }
}

extension EKEventStore {
    /// Typed notification payload. Linux Foundation does not provide
    /// `NotificationCenter.MainActorMessage`, so this type is a standalone
    /// value with the same public members.
    public struct EventStoreChanged: Sendable {
        public typealias Subject = EKEventStore

        public static var name: Notification.Name { .EKEventStoreChanged }

        public init() {}

        @MainActor
        public static func makeMessage(
            _ notification: Notification
        ) -> EKEventStore.EventStoreChanged? {
            guard notification.name == name else { return nil }
            return EventStoreChanged()
        }

        @MainActor
        public static func makeNotification(
            _ message: EKEventStore.EventStoreChanged
        ) -> Notification {
            _ = message
            return Notification(name: name)
        }
    }
}
