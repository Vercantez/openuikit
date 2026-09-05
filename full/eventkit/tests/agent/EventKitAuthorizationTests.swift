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
        try? FileManager.default.removeItem(at: directory)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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
    var value: T?
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

func eventKitRequestAccess(_ store: EKEventStore, to type: EKEntityType) -> Bool {
    let lock = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var granted = false
    nonisolated(unsafe) var failed = false
    Task.detached {
        do {
            granted = try await store.requestAccess(to: type)
        } catch {
            failed = true
        }
        lock.signal()
    }
    lock.wait()
    precondition(!failed, "requestAccess must not throw on deny-or-grant")
    return granted
}

func eventKitGrantFullAccess(_ store: EKEventStore) {
    let events = eventKitWait { completion in
        store.requestFullAccessToEvents(completion: completion)
    }
    precondition(events.0 == true)
    precondition(events.1 == nil)
    let reminders = eventKitWait { completion in
        store.requestFullAccessToReminders(completion: completion)
    }
    precondition(reminders.0 == true)
    precondition(reminders.1 == nil)
}

func testAuthorizationStartsNotDetermined() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        precondition(EKEventStore.authorizationStatus(for: .event) == .notDetermined)
        precondition(EKEventStore.authorizationStatus(for: .reminder) == .notDetermined)
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.save(EKEvent(eventStore: store), span: .thisEvent)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.save(EKEvent(eventStore: store), span: .futureEvents, commit: false)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.remove(EKEvent(eventStore: store), span: .thisEvent)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.remove(EKEvent(eventStore: store), span: .thisEvent, commit: false)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.save(EKReminder(eventStore: store), commit: true)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.remove(EKReminder(eventStore: store), commit: true)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.saveCalendar(EKCalendar(for: .event, eventStore: store), commit: true)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.removeCalendar(EKCalendar(for: .event, eventStore: store), commit: true)
        }
        eventKitRequireThrown(.eventStoreNotAuthorized) {
            try store.commit()
        }
        let predicate = store.predicateForEvents(
            withStart: Date.distantPast,
            end: Date.distantFuture,
            calendars: nil
        )
        precondition(store.events(matching: predicate).isEmpty)
        store.enumerateEvents(matching: predicate) { _, stop in
            stop.pointee = true
            fatalError("unauthorized store must not enumerate events")
        }
        precondition(store.event(withIdentifier: "missing") == nil)
        precondition(store.calendarItem(withIdentifier: "missing") == nil)
        precondition(store.calendarItems(withExternalIdentifier: "missing").isEmpty)
        precondition(store.calendar(withIdentifier: "missing") == nil)
        precondition(store.calendars(for: .event).isEmpty)
        precondition(store.source(withIdentifier: "missing") == nil)
        store.refreshSourcesIfNecessary()
        store.reset()
    }
}


func testAuthorizationDeniedFailsClosed() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        EKEventStore.denyAccessRequests = true
        let granted = eventKitRequestAccess(store, to: .event)
        precondition(granted == false)
        precondition(EKEventStore.authorizationStatus(for: .event) == .denied)

        let fullEvents = eventKitWait { completion in
            store.requestFullAccessToEvents(completion: completion)
        }
        precondition(fullEvents.0 == false)
        precondition(fullEvents.1 == nil)

        let fullReminders = eventKitWait { completion in
            store.requestFullAccessToReminders(completion: completion)
        }
        precondition(fullReminders.0 == false)
        precondition(fullReminders.1 == nil)

        let writeOnly = eventKitWait { completion in
            store.requestWriteOnlyAccessToEvents(completion: completion)
        }
        precondition(writeOnly.0 == false)
        precondition(writeOnly.1 == nil)
        EKEventStore.denyAccessRequests = false
    }
}


func testAuthorizationFullAccessAndWriteOnly() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        let fullEvents = eventKitWait { completion in
            store.requestFullAccessToEvents(completion: completion)
        }
        precondition(fullEvents.0 == true)
        precondition(fullEvents.1 == nil)
        precondition(EKEventStore.authorizationStatus(for: .event) == .fullAccess)
        precondition(EKEventStore.authorizationStatus(for: .event) == .authorized)

        let reminderGrant = eventKitRequestAccess(store, to: .reminder)
        precondition(reminderGrant)
        precondition(EKEventStore.authorizationStatus(for: .reminder) == .fullAccess)
    }

    eventKitFreshStore()
    if true {
        let writeStore = EKEventStore()
        let writeOnly = eventKitWait { completion in
            writeStore.requestWriteOnlyAccessToEvents(completion: completion)
        }
        precondition(writeOnly.0 == true)
        precondition(writeOnly.1 == nil)
        precondition(EKEventStore.authorizationStatus(for: .event) == .writeOnly)
        let writeEvent = EKEvent(eventStore: writeStore)
        writeEvent.title = "Write only"
        writeEvent.startDate = eventKitGMTDate(2026, 6, 1)
        writeEvent.endDate = eventKitGMTDate(2026, 6, 1, hour: 10)
        writeEvent.calendar = writeStore.defaultCalendarForNewEvents
        try! writeStore.save(writeEvent, span: .thisEvent)
        let writePred = writeStore.predicateForEvents(
            withStart: eventKitGMTDate(2026, 6, 1),
            end: eventKitGMTDate(2026, 6, 2),
            calendars: nil
        )
        precondition(writeStore.events(matching: writePred).isEmpty)
    }
}
