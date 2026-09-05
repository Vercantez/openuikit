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

func testEventPredicatesAndFetches() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        let calendar = EKCalendar(for: .event, eventStore: store)
        let inside = EKEvent(eventStore: store)
        inside.calendar = calendar
        inside.startDate = Date(timeIntervalSince1970: 1_000)
        inside.endDate = Date(timeIntervalSince1970: 2_000)
        let outside = EKEvent(eventStore: store)
        outside.startDate = Date(timeIntervalSince1970: 9_000)
        outside.endDate = Date(timeIntervalSince1970: 10_000)

        let predicate = store.predicateForEvents(
            withStart: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 3_000),
            calendars: [calendar]
        )
        precondition(predicate.evaluate(with: inside))
        precondition(!predicate.evaluate(with: outside))
        let none = store.predicateForEvents(
            withStart: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 3_000),
            calendars: []
        )
        precondition(!none.evaluate(with: inside))
        let allCalendars = store.predicateForEvents(
            withStart: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 3_000),
            calendars: nil
        )
        precondition(allCalendars.evaluate(with: inside))

        eventKitGrantFullAccess(store)
        let event = EKEvent(eventStore: store)
        event.title = "Standup"
        event.startDate = eventKitGMTDate(2026, 3, 2)
        event.endDate = eventKitGMTDate(2026, 3, 2, hour: 10)
        event.calendar = store.defaultCalendarForNewEvents
        try! store.save(event, span: .thisEvent)
        let fetched = store.event(withIdentifier: event.eventIdentifier)
        precondition(fetched?.title == "Standup")
        precondition(store.calendarItem(withIdentifier: event.calendarItemIdentifier) != nil)
        let savedPred = store.predicateForEvents(
            withStart: eventKitGMTDate(2026, 3, 1),
            end: eventKitGMTDate(2026, 3, 4),
            calendars: nil
        )
        precondition(store.events(matching: savedPred).count == 1)
        var enumerated = 0
        store.enumerateEvents(matching: savedPred) { match, stop in
            enumerated += 1
            precondition(match.title == "Standup")
            stop.pointee = true
        }
        precondition(enumerated == 1)
        let store2 = EKEventStore()
        precondition(store2.event(withIdentifier: event.eventIdentifier)?.title == "Standup")
        precondition(store2.event(withIdentifier: event.eventIdentifier)?.refresh() == true)
        precondition(!store.calendarItems(withExternalIdentifier: event.calendarItemExternalIdentifier).isEmpty)
    }
}


func testReminderPredicatesAndFetches() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        let reminderCalendar = EKCalendar(for: .reminder, eventStore: store)
        let incomplete = EKReminder(eventStore: store)
        incomplete.calendar = reminderCalendar
        incomplete.dueDateComponents = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 9,
            day: 2
        )
        let completed = EKReminder(eventStore: store)
        completed.calendar = reminderCalendar
        completed.isCompleted = true

        let incompletePredicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [reminderCalendar]
        )
        precondition(incompletePredicate.evaluate(with: incomplete))
        precondition(!incompletePredicate.evaluate(with: completed))
        let completedPredicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        precondition(completedPredicate.evaluate(with: completed))
        precondition(!completedPredicate.evaluate(with: incomplete))
        precondition(!store.predicateForReminders(in: []).evaluate(with: incomplete))
        precondition(store.predicateForReminders(in: nil).evaluate(with: incomplete))

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dueOnSecond = EKReminder(eventStore: store)
        dueOnSecond.dueDateComponents = DateComponents(
            calendar: utcCalendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 9,
            day: 2,
            hour: 0
        )
        let windowStart = utcCalendar.date(
            from: DateComponents(year: 2026, month: 9, day: 1, hour: 23)
        )!
        let windowEnd = utcCalendar.date(
            from: DateComponents(year: 2026, month: 9, day: 2, hour: 1)
        )!
        let dueWindow = store.predicateForIncompleteReminders(
            withDueDateStarting: windowStart,
            ending: windowEnd,
            calendars: nil
        )
        precondition(dueWindow.evaluate(with: dueOnSecond))

        let unauthorized = eventKitFetchReminders(
            store,
            matching: store.predicateForReminders(in: nil),
            cancel: true
        )
        precondition(unauthorized == nil)

        eventKitGrantFullAccess(store)
        let reminder = EKReminder(eventStore: store)
        reminder.title = "Ship EventKit"
        reminder.calendar = store.defaultCalendarForNewReminders()
        reminder.priority = Int(EKReminderPriority.high.rawValue)
        reminder.dueDateComponents = DateComponents(
            calendar: eventKitGMTCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 3,
            day: 3
        )
        try! store.save(reminder, commit: true)
        let fetchedReminders = eventKitFetchReminders(
            store,
            matching: store.predicateForReminders(in: nil)
        )
        precondition(fetchedReminders?.contains { $0.title == "Ship EventKit" } == true)
        try! store.remove(reminder, commit: true)
        let afterRemove = eventKitFetchReminders(
            store,
            matching: store.predicateForReminders(in: nil)
        )
        precondition(afterRemove?.contains { $0.title == "Ship EventKit" } != true)
    }
}
