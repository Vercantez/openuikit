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

func testEventAndCalendarItemValueSemantics() {
    let store = EKEventStore()
    let event = EKEvent(eventStore: store)
    let asItem: EKCalendarItem = event
    let asObject: EKObject = event
    _ = (asItem, asObject)
    precondition(event.isNew)
    precondition(!event.hasChanges)
    precondition(event.attendees == nil)
    precondition(!event.hasAttendees)
    precondition(event.creationDate != nil)
    precondition(event.lastModifiedDate != nil)
    precondition(event.recurrenceRules == nil)
    event.title = "Planning"
    event.notes = "Bring notes"
    event.location = "Library"
    event.url = URL(string: "https://example.invalid/event")
    event.timeZone = TimeZone(secondsFromGMT: 0)
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    event.startDate = start
    event.endDate = Date(timeIntervalSince1970: 1_700_003_600)
    precondition(event.occurrenceDate == start)
    event.isAllDay = false
    event.availability = .busy
    precondition(event.hasChanges)
    precondition(event.hasNotes)
    precondition(event.eventIdentifier != nil)
    precondition(!event.calendarItemIdentifier.isEmpty)
    precondition(event.calendarItemExternalIdentifier != nil)
    precondition(event.status == .none)
    precondition(event.birthdayPersonID == -1)
    precondition(event.birthdayContactIdentifier == nil)
    precondition(event.organizer == nil)
    precondition(!event.isDetached)
    precondition(!event.refresh())
    let other = EKEvent(eventStore: store)
    other.startDate = Date(timeIntervalSince1970: 1_700_010_000)
    precondition(event.compareStartDate(with: other) == .orderedAscending)
    event.rollback()
    precondition(!event.hasChanges)
    precondition(event.title == nil)
    precondition(event.occurrenceDate == nil)
    event.reset()
    precondition(!event.hasChanges)
}


func testReminderAlarmAndLocationValueSemantics() {
    let store = EKEventStore()
    let reminder = EKReminder(eventStore: store)
    precondition(!reminder.hasChanges)
    reminder.title = "Ship EventKit"
    reminder.priority = Int(EKReminderPriority.high.rawValue)
    reminder.dueDateComponents = DateComponents(year: 2026, month: 9, day: 2)
    reminder.startDateComponents = DateComponents(year: 2026, month: 9, day: 1)
    precondition(!reminder.isCompleted)
    reminder.isCompleted = true
    precondition(reminder.isCompleted)
    precondition(reminder.completionDate != nil)
    reminder.isCompleted = false
    precondition(reminder.completionDate == nil)

    let alarm = EKAlarm(relativeOffset: -900)
    precondition(alarm.relativeOffset == -900)
    precondition(alarm.absoluteDate == nil)
    alarm.absoluteDate = Date(timeIntervalSince1970: 1_699_999_000)
    precondition(alarm.absoluteDate != nil)
    precondition(alarm.relativeOffset == 0)
    alarm.relativeOffset = -60
    precondition(alarm.absoluteDate == nil)
    alarm.proximity = .none
    let namedLocation = EKStructuredLocation(title: "Library")
    namedLocation.radius = 50
    alarm.structuredLocation = namedLocation
    let event = EKEvent(eventStore: store)
    event.addAlarm(alarm)
    precondition(event.hasAlarms)
    event.removeAlarm(alarm)
    precondition(!event.hasAlarms)
    event.alarms = [alarm]
    precondition(event.hasAlarms)
    let locationCopy = namedLocation.copy() as? EKStructuredLocation
    precondition(locationCopy?.title == "Library")
    event.structuredLocation = namedLocation
    precondition(event.location == "Library")
    _ = EKAlarm(absoluteDate: Date(timeIntervalSince1970: 1_700_000_000))
    #if canImport(CoreLocation)
    namedLocation.geoLocation = CLLocation(latitude: 37.3349, longitude: -122.009)
    precondition(abs((namedLocation.geoLocation?.coordinate.latitude ?? 0) - 37.3349) < 0.0001)
    #endif
    #if canImport(MapKit) && canImport(CoreLocation)
    let mapItem = MKMapItem(
        location: CLLocation(latitude: 37.3349, longitude: -122.009),
        address: nil
    )
    mapItem.name = "Apple Park"
    let fromMap = EKStructuredLocation(mapItem: mapItem)
    precondition(fromMap.title == "Apple Park")
    #endif
}


func testParticipantAndVirtualConferenceDescriptors() {
    let participant = EKParticipant()
    precondition(participant.participantStatus == .unknown)
    precondition(participant.participantRole == .unknown)
    precondition(participant.participantType == .unknown)
    precondition(participant.name == nil)
    precondition(participant.url.scheme == "mailto")
    precondition(!participant.isCurrentUser)
    let cfBook: CFTypeRef = NSObject()
    let book: ABAddressBook = cfBook
    precondition(participant.abRecord(with: book) == nil)
    precondition(!participant.contactPredicate.evaluate(with: participant))
    _ = participant.copy()

    let url = URL(string: "https://example.invalid/meet")!
    let urlDescriptor = EKVirtualConferenceURLDescriptor(title: "Join", url: url)
    let urlAlias = EKVirtualConferenceURLDescriptor(title: "Join", URL: url)
    precondition(urlDescriptor.url == urlAlias.url)
    precondition(urlDescriptor.title == "Join")
    let room = EKVirtualConferenceRoomTypeDescriptor(title: "Standup", identifier: "standup")
    precondition(room.identifier == "standup")
    precondition(room.title == "Standup")
    let descriptor = EKVirtualConferenceDescriptor(
        title: "Standup",
        urlDescriptors: [urlDescriptor],
        conferenceDetails: "PIN 1234"
    )
    let alias = EKVirtualConferenceDescriptor(
        title: "Standup",
        URLDescriptors: [urlAlias],
        conferenceDetails: nil
    )
    precondition(descriptor.urlDescriptors.count == 1)
    precondition(descriptor.conferenceDetails == "PIN 1234")
    precondition(alias.title == "Standup")
}
