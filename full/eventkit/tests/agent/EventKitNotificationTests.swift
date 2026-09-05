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

func testEventStoreChangedPostedOnCommit() {
    eventKitFreshStore()
    if true {
        let store = EKEventStore()
        eventKitGrantFullAccess(store)
        precondition(
            Notification.Name.EKEventStoreChanged.rawValue == "EKEventStoreChangedNotification"
        )
        let typed = EKEventStore.EventStoreChanged()
        precondition(EKEventStore.EventStoreChanged.name == .EKEventStoreChanged)
        precondition(
            EKEventStore.EventStoreChanged.makeMessage(
                Notification(name: .EKEventStoreChanged)
            ) != nil
        )
        precondition(
            EKEventStore.EventStoreChanged.makeMessage(
                Notification(name: Notification.Name("other"))
            ) == nil
        )
        let note = EKEventStore.EventStoreChanged.makeNotification(typed)
        precondition(note.name == .EKEventStoreChanged)
        let _: EKEventStore.EventStoreChanged.Subject.Type = EKEventStore.self

        var posted = 0
        let token = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: nil
        ) { _ in
            posted += 1
        }
        let event = EKEvent(eventStore: store)
        event.title = "Standup"
        event.notes = "Weekly"
        event.location = "Library"
        event.startDate = eventKitGMTDate(2026, 3, 2)
        event.endDate = eventKitGMTDate(2026, 3, 2, hour: 10)
        event.calendar = store.defaultCalendarForNewEvents
        event.availability = .busy
        event.addAlarm(EKAlarm(relativeOffset: -300))
        try! store.save(event, span: .thisEvent)
        precondition(posted == 1)
        NotificationCenter.default.removeObserver(token)
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let identifier: NotificationCenter.BaseMessageIdentifier<EKEventStore.EventStoreChanged> =
            .changed
        _ = identifier
        #endif
    }
}


func testVirtualConferenceProviderFailClosed() {
    let provider = EKVirtualConferenceProvider()
    let roomResult = eventKitWait { completion in
        provider.fetchAvailableRoomTypes(completionHandler: completion)
    }
    precondition(roomResult.0 == nil)
    eventKitRequireEKError(roomResult.1, code: .osNotSupported)
    let lock = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var asyncError: (any Error)?
    Task.detached {
        do {
            _ = try await provider.fetchVirtualConference(identifier: "standup")
            asyncError = nil
        } catch {
            asyncError = error
        }
        lock.signal()
    }
    lock.wait()
    eventKitRequireEKError(asyncError, code: .osNotSupported)
}
