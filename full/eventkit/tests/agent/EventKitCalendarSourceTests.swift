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

func testLocalSourceAndDefaultCalendars() {
    eventKitFreshStore()
    if true {
        let empty = EKEventStore()
        precondition(!empty.eventStoreIdentifier.isEmpty)
        precondition(empty.sources.isEmpty)
        precondition(empty.delegateSources.isEmpty)
        precondition(empty.defaultCalendarForNewEvents == nil)
        precondition(empty.defaultCalendarForNewReminders() == nil)

        eventKitGrantFullAccess(empty)
        precondition(empty.defaultCalendarForNewEvents != nil)
        precondition(empty.defaultCalendarForNewReminders() != nil)
        precondition(empty.sources.contains { $0.sourceType == .local && $0.title == "On This Device" })
        let eventCalendars = empty.calendars(for: .event)
        let reminderCalendars = empty.calendars(for: .reminder)
        precondition(!eventCalendars.isEmpty)
        precondition(!reminderCalendars.isEmpty)
        precondition(eventCalendars[0].allowedEntityTypes.contains(.event))
        precondition(reminderCalendars[0].allowedEntityTypes.contains(.reminder))
        let identifier = eventCalendars[0].calendarIdentifier
        precondition(empty.calendar(withIdentifier: identifier)?.title == eventCalendars[0].title)
        precondition(empty.source(withIdentifier: empty.sources[0].sourceIdentifier) === empty.sources[0])
        #if canImport(CoreGraphics)
        let components = empty.defaultCalendarForNewEvents!.cgColor.components
        precondition(components != nil)
        precondition(abs(Double(components![1]) - 0.478) < 0.001)
        #endif
    }
}


func testSaveAndRemoveCalendar() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        eventKitGrantFullAccess(store)
        let extra = EKCalendar(for: .event, eventStore: store)
        extra.title = "Work"
        extra.source = store.sources.first
        precondition(extra.type == .local)
        precondition(extra.allowsContentModifications)
        precondition(!extra.isImmutable)
        precondition(!extra.isSubscribed)
        precondition(extra.supportedEventAvailabilities.contains(.busy))
        try! store.saveCalendar(extra, commit: true)
        precondition(store.calendar(withIdentifier: extra.calendarIdentifier)?.title == "Work")
        try! store.removeCalendar(extra, commit: true)
        precondition(store.calendar(withIdentifier: extra.calendarIdentifier) == nil)

        let alias = EKCalendar(forEntityType: .reminder, eventStore: store)
        precondition(alias.allowedEntityTypes.contains(.reminder))
        alias.title = "Tasks"
        alias.source = store.sources.first
        try! store.saveCalendar(alias, commit: false)
        try! store.commit()
        precondition(store.calendar(withIdentifier: alias.calendarIdentifier)?.title == "Tasks")
    }
}


func testHostedSourcesAndDelegateSources() {
    eventKitFreshStore()
    if true {
        let source = EKSource()
        precondition(!source.sourceIdentifier.isEmpty)
        precondition(source.sourceType == .local)
        precondition(!source.isDelegate)
        precondition(source.calendars(for: .event).isEmpty)
        _ = source.title
        let sourced = EKEventStore(sources: [source])
        precondition(sourced.sources.count == 1)
        precondition(sourced.source(withIdentifier: sourced.sources[0].sourceIdentifier) === sourced.sources[0])
        precondition(sourced.delegateSources.isEmpty)
        sourced.refreshSourcesIfNecessary()
        sourced.reset()
    }
}
