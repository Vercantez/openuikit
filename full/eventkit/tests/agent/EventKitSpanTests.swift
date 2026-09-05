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

func testSpanThisEventDetachesOccurrence() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        eventKitGrantFullAccess(store)
        let series = EKEvent(eventStore: store)
        series.title = "Daily standup"
        series.calendar = store.defaultCalendarForNewEvents
        series.startDate = eventKitGMTDate(2026, 5, 1)
        series.endDate = eventKitGMTDate(2026, 5, 1, hour: 10)
        series.addRecurrenceRule(
            EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: EKRecurrenceEnd(occurrenceCount: 5)
            )
        )
        try! store.save(series, span: .thisEvent)
        let seriesPred = store.predicateForEvents(
            withStart: eventKitGMTDate(2026, 5, 1),
            end: eventKitGMTDate(2026, 5, 10),
            calendars: nil
        )
        let occurrences = store.events(matching: seriesPred)
        precondition(occurrences.count == 5)
        let third = occurrences[2]
        precondition(!third.isDetached)
        try! store.remove(third, span: .thisEvent)
        let afterRemove = store.events(matching: seriesPred)
        precondition(afterRemove.count == 4)

        let remaining = store.events(matching: seriesPred)
        let second = remaining[1]
        second.title = "Only this day"
        try! store.save(second, span: .thisEvent, commit: true)
        let afterDetach = store.events(matching: seriesPred)
        precondition(afterDetach.contains { $0.title == "Only this day" && $0.isDetached })
        precondition(afterDetach.contains { $0.title == "Daily standup" })
    }
}


func testSpanFutureEventsSplitsSeries() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        eventKitGrantFullAccess(store)
        let series = EKEvent(eventStore: store)
        series.title = "Original series"
        series.calendar = store.defaultCalendarForNewEvents
        series.startDate = eventKitGMTDate(2026, 7, 1)
        series.endDate = eventKitGMTDate(2026, 7, 1, hour: 10)
        series.addRecurrenceRule(
            EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: EKRecurrenceEnd(occurrenceCount: 6)
            )
        )
        try! store.save(series, span: .thisEvent)
        let window = store.predicateForEvents(
            withStart: eventKitGMTDate(2026, 7, 1),
            end: eventKitGMTDate(2026, 7, 10),
            calendars: nil
        )
        let occurrences = store.events(matching: window)
        precondition(occurrences.count == 6)
        let fourth = occurrences[3]
        fourth.title = "Future title"
        try! store.save(fourth, span: .futureEvents)
        let split = store.events(matching: window)
        let original = split.filter { $0.title == "Original series" }
        let future = split.filter { $0.title == "Future title" }
        precondition(original.count == 3)
        precondition(future.count == 3)

        let dropFrom = store.events(matching: window).last!
        try! store.remove(dropFrom, span: .futureEvents, commit: true)
        let remaining = store.events(matching: window)
        precondition(remaining.count < 6)
    }
}
