@_spi(OpenUIKitHost) import EventKit
import CoreFoundation
import Dispatch
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(MapKit)
import MapKit
#endif

enum EventKitTestRoot {
    nonisolated(unsafe) static var directory: URL?
}

func eventKitWithIsolatedStore(_ body: () -> Void) {
    let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("eventkit-test-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    EventKitTestRoot.directory = tmp
    EKEventStore.useIsolatedStoreDirectory(tmp)
    EKEventStore.resetIsolatedStore()
    EKEventStore.denyAccessRequests = false
    defer {
        EKEventStore.denyAccessRequests = false
        EventKitTestRoot.directory = nil
        try? FileManager.default.removeItem(at: tmp)
    }
    body()
}

func eventKitFreshStore() {
    EKEventStore.denyAccessRequests = false
    if let directory = EventKitTestRoot.directory {
        try? FileManager.default.removeItem(
            at: directory.appendingPathComponent("store.json")
        )
        try? FileManager.default.removeItem(
            at: directory.appendingPathComponent("store.json.tmp")
        )
    }
    EKEventStore.resetIsolatedStore()
}

func eventKitRequireEKError(_ error: (any Error)?, code: EKError.Code) {
    guard let error = error as? EKError else {
        fatalError("expected typed EKError, got \(String(describing: error))")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(EKError.errorDomain == EKErrorDomain)
}

func eventKitRequireThrown(_ code: EKError.Code, work: () throws -> Void) {
    do {
        try work()
        fatalError("expected EKError.\(code) to be thrown")
    } catch {
        eventKitRequireEKError(error, code: code)
        precondition(code ~= error)
    }
}

func eventKitGMTCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

func eventKitGMTDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
    eventKitGMTCalendar().date(
        from: DateComponents(year: year, month: month, day: day, hour: hour)
    )!
}

func eventKitWait<T>(_ work: (@escaping (T) -> Void) -> Void) -> T {
    let lock = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var value: T?
    var returned = false
    var reentrant = false
    work { result in
        reentrant = !returned
        value = result
        lock.signal()
    }
    returned = true
    lock.wait()
    precondition(!reentrant, "EventKit completion must not run reentrantly on the caller")
    guard let value else { fatalError("completion did not fire") }
    return value
}

func eventKitRequestAccessHandler(
    _ work: (@escaping EKEventStoreRequestAccessCompletionHandler) -> Void
) -> (Bool, (any Error)?) {
    eventKitWait { (finish: @escaping ((Bool, (any Error)?)) -> Void) in
        work { granted, error in
            finish((granted, error))
        }
    }
}

func eventKitFetchReminders(
    _ store: EKEventStore,
    matching predicate: NSPredicate,
    cancel: Bool = false
) -> [EKReminder]? {
    eventKitWait { (finish: @escaping ([EKReminder]?) -> Void) in
        let token = store.fetchReminders(matching: predicate) { reminders in
            finish(reminders)
        }
        if cancel {
            store.cancelFetchRequest(token)
        }
    }
}

final class EventKitPostedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
    var current: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

func eventKitRequestAccess(_ store: EKEventStore, to type: EKEntityType) -> Bool {
    eventKitWait { (finish: @escaping (Bool) -> Void) in
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                do {
                    finish(try await store.requestAccess(to: type))
                } catch {
                    finish(false)
                }
            }
        }
    }
}

func eventKitGrantFullAccess(_ store: EKEventStore) {
    let events = eventKitRequestAccessHandler { completion in
        store.requestFullAccessToEvents(completion: completion)
    }
    precondition(events.0 == true)
    precondition(events.1 == nil)
    let reminders = eventKitRequestAccessHandler { completion in
        store.requestFullAccessToReminders(completion: completion)
    }
    precondition(reminders.0 == true)
    precondition(reminders.1 == nil)
    precondition(EKEventStore.authorizationStatus(for: .event) == .fullAccess)
    precondition(EKEventStore.authorizationStatus(for: .reminder) == .fullAccess)
}

func testEKErrorCodesAndDomain() {
    precondition(EKErrorDomain == "EKErrorDomain")
    precondition(EKError.errorDomain == EKErrorDomain)
    let codes: [EKError.Code] = [
        .eventNotMutable, .noStartDate, .noEndDate, .datesInverted, .internalFailure,
        .calendarReadOnly, .durationGreaterThanRecurrence, .alarmGreaterThanRecurrence,
        .startDateTooFarInFuture, .startDateCollidesWithOtherOccurrence,
        .objectBelongsToDifferentStore, .invitesCannotBeMoved, .invalidSpan,
        .calendarHasNoSource, .calendarSourceCannotBeModified, .calendarIsImmutable,
        .sourceDoesNotAllowCalendarAddDelete, .recurringReminderRequiresDueDate,
        .structuredLocationsNotSupported, .reminderLocationsNotSupported,
        .alarmProximityNotSupported, .calendarDoesNotAllowEvents,
        .calendarDoesNotAllowReminders, .sourceDoesNotAllowEvents,
        .sourceDoesNotAllowReminders, .priorityIsInvalid, .invalidEntityType,
        .procedureAlarmsNotMutable, .eventStoreNotAuthorized, .osNotSupported,
        .invalidInviteReplyCalendar, .notificationsCollectionFlagNotSet,
        .sourceMismatch, .notificationCollectionMismatch,
        .notificationSavedWithoutCollection, .reminderAlarmContainsEmailOrUrl,
        .noCalendar, .last,
    ]
    precondition(codes.count == 38)
    precondition(EKError.eventNotMutable.rawValue == 0)
    precondition(EKError.noStartDate.rawValue == 1)
    precondition(EKError.noEndDate.rawValue == 2)
    precondition(EKError.datesInverted.rawValue == 3)
    precondition(EKError.internalFailure.rawValue == 4)
    precondition(EKError.calendarReadOnly.rawValue == 5)
    precondition(EKError.durationGreaterThanRecurrence.rawValue == 6)
    precondition(EKError.alarmGreaterThanRecurrence.rawValue == 7)
    precondition(EKError.startDateTooFarInFuture.rawValue == 8)
    precondition(EKError.startDateCollidesWithOtherOccurrence.rawValue == 9)
    precondition(EKError.objectBelongsToDifferentStore.rawValue == 10)
    precondition(EKError.invitesCannotBeMoved.rawValue == 11)
    precondition(EKError.invalidSpan.rawValue == 12)
    precondition(EKError.calendarHasNoSource.rawValue == 13)
    precondition(EKError.calendarSourceCannotBeModified.rawValue == 14)
    precondition(EKError.calendarIsImmutable.rawValue == 15)
    precondition(EKError.sourceDoesNotAllowCalendarAddDelete.rawValue == 16)
    precondition(EKError.recurringReminderRequiresDueDate.rawValue == 17)
    precondition(EKError.structuredLocationsNotSupported.rawValue == 18)
    precondition(EKError.reminderLocationsNotSupported.rawValue == 19)
    precondition(EKError.alarmProximityNotSupported.rawValue == 20)
    precondition(EKError.calendarDoesNotAllowEvents.rawValue == 21)
    precondition(EKError.calendarDoesNotAllowReminders.rawValue == 22)
    precondition(EKError.sourceDoesNotAllowEvents.rawValue == 23)
    precondition(EKError.sourceDoesNotAllowReminders.rawValue == 24)
    precondition(EKError.priorityIsInvalid.rawValue == 25)
    precondition(EKError.invalidEntityType.rawValue == 26)
    precondition(EKError.procedureAlarmsNotMutable.rawValue == 27)
    precondition(EKError.eventStoreNotAuthorized.rawValue == 28)
    precondition(EKError.osNotSupported.rawValue == 29)
    precondition(EKError.invalidInviteReplyCalendar.rawValue == 30)
    precondition(EKError.notificationsCollectionFlagNotSet.rawValue == 31)
    precondition(EKError.sourceMismatch.rawValue == 32)
    precondition(EKError.notificationCollectionMismatch.rawValue == 33)
    precondition(EKError.notificationSavedWithoutCollection.rawValue == 34)
    precondition(EKError.reminderAlarmContainsEmailOrUrl.rawValue == 35)
    precondition(EKError.noCalendar.rawValue == 36)
    precondition(EKError.last.rawValue == 37)
    precondition(EKError.Code(rawValue: 4) == .internalFailure)
    precondition(EKError.noCalendar == .noCalendar)
    for (index, code) in codes.enumerated() {
        precondition(code.rawValue == index)
        let error = EKError(code)
        precondition(error.code == code)
        precondition(error.errorCode == index)
        precondition(error.userInfo.isEmpty)
        precondition(error.errorUserInfo.isEmpty)
        precondition(!error.localizedDescription.isEmpty)
        precondition(EKError(code) == error)
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
    }
    let tagged = EKError(.osNotSupported, userInfo: ["sentinel": "value"])
    let empty = EKError(.osNotSupported)
    precondition(tagged != empty)
    precondition(tagged.hashValue == empty.hashValue)
    precondition(EKError.Code.osNotSupported ~= empty)
    precondition(!(EKError.Code.noCalendar ~= empty))
}


func testEKErrorThrownOnValidation() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        eventKitGrantFullAccess(store)
        let calendar = store.defaultCalendarForNewEvents!

        let missingStart = EKEvent(eventStore: store)
        missingStart.calendar = calendar
        missingStart.endDate = eventKitGMTDate(2026, 4, 1)
        eventKitRequireThrown(.noStartDate) {
            try store.save(missingStart, span: .thisEvent)
        }

        let missingEnd = EKEvent(eventStore: store)
        missingEnd.calendar = calendar
        missingEnd.startDate = eventKitGMTDate(2026, 4, 1)
        eventKitRequireThrown(.noEndDate) {
            try store.save(missingEnd, span: .thisEvent)
        }

        let inverted = EKEvent(eventStore: store)
        inverted.calendar = calendar
        inverted.startDate = eventKitGMTDate(2026, 4, 2)
        inverted.endDate = eventKitGMTDate(2026, 4, 1)
        eventKitRequireThrown(.datesInverted) {
            try store.save(inverted, span: .thisEvent)
        }

        let noCalendar = EKEvent(eventStore: store)
        noCalendar.calendar = nil
        noCalendar.startDate = eventKitGMTDate(2026, 4, 1)
        noCalendar.endDate = eventKitGMTDate(2026, 4, 1, hour: 10)
        eventKitRequireThrown(.noCalendar) {
            try store.save(noCalendar, span: .thisEvent)
        }

        let reminderCalendar: EKCalendar
        if let existing = store.defaultCalendarForNewReminders() {
            reminderCalendar = existing
        } else {
            let created = EKCalendar(for: .reminder, eventStore: store)
            created.title = "Reminders"
            created.source = store.sources.first
            try! store.saveCalendar(created, commit: true)
            reminderCalendar = created
        }
        let wrongKind = EKEvent(eventStore: store)
        wrongKind.calendar = reminderCalendar
        wrongKind.startDate = eventKitGMTDate(2026, 4, 1)
        wrongKind.endDate = eventKitGMTDate(2026, 4, 1, hour: 10)
        eventKitRequireThrown(.calendarDoesNotAllowEvents) {
            try store.save(wrongKind, span: .thisEvent)
        }

        let eventOnly = EKCalendar(for: .event, eventStore: store)
        eventOnly.title = "Events only"
        eventOnly.source = store.sources.first
        try! store.saveCalendar(eventOnly, commit: true)
        let reminder = EKReminder(eventStore: store)
        reminder.title = "Wrong calendar"
        reminder.calendar = eventOnly
        eventKitRequireThrown(.calendarDoesNotAllowReminders) {
            try store.save(reminder, commit: true)
        }

        let recurring = EKReminder(eventStore: store)
        recurring.title = "Needs due date"
        recurring.calendar = reminderCalendar
        recurring.addRecurrenceRule(
            EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
        )
        eventKitRequireThrown(.recurringReminderRequiresDueDate) {
            try store.save(recurring, commit: true)
        }

        let priority = EKReminder(eventStore: store)
        priority.title = "Bad priority"
        priority.calendar = reminderCalendar
        priority.priority = 99
        eventKitRequireThrown(.priorityIsInvalid) {
            try store.save(priority, commit: true)
        }

        let orphan = EKCalendar(for: .event, eventStore: store)
        orphan.title = "No source"
        eventKitRequireThrown(.calendarHasNoSource) {
            try store.saveCalendar(orphan, commit: true)
        }

        let other = EKEventStore(sources: [EKSource()])
        let foreign = EKEvent(eventStore: other)
        foreign.calendar = calendar
        foreign.startDate = eventKitGMTDate(2026, 4, 1)
        foreign.endDate = eventKitGMTDate(2026, 4, 1, hour: 10)
        eventKitRequireThrown(.objectBelongsToDifferentStore) {
            try store.save(foreign, span: .thisEvent)
        }
    }
}
