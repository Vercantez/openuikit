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

        let posted = EventKitPostedCounter()
        let token = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: nil
        ) { _ in
            posted.increment()
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
        precondition(posted.current == 1)
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
    let roomResult = eventKitWait {
        (finish: @escaping (([EKVirtualConferenceRoomTypeDescriptor]?, (any Error)?)) -> Void) in
        provider.fetchAvailableRoomTypes { rooms, error in
            finish((rooms, error))
        }
    }
    precondition(roomResult.0 == nil)
    eventKitRequireEKError(roomResult.1, code: .osNotSupported)
    let asyncError = eventKitWait { (finish: @escaping ((any Error)?) -> Void) in
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                do {
                    _ = try await provider.fetchVirtualConference(identifier: "standup")
                    finish(nil)
                } catch {
                    finish(error)
                }
            }
        }
    }
    eventKitRequireEKError(asyncError, code: .osNotSupported)
}
