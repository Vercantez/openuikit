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

func testEnumRawValuesAndAliases() {
    precondition(EKAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(EKAuthorizationStatus.restricted.rawValue == 1)
    precondition(EKAuthorizationStatus.denied.rawValue == 2)
    precondition(EKAuthorizationStatus.fullAccess.rawValue == 3)
    precondition(EKAuthorizationStatus.writeOnly.rawValue == 4)
    precondition(EKAuthorizationStatus.authorized == .fullAccess)
    precondition(EKAuthorizationStatus.authorized.rawValue == 3)
    precondition(EKAuthorizationStatus(rawValue: 2) == .denied)
    precondition(EKAuthorizationStatus(rawValue: 99) == nil)

    precondition(EKWeekday.sunday.rawValue == 1)
    precondition(EKWeekday.monday.rawValue == 2)
    precondition(EKWeekday.tuesday.rawValue == 3)
    precondition(EKWeekday.wednesday.rawValue == 4)
    precondition(EKWeekday.thursday.rawValue == 5)
    precondition(EKWeekday.friday.rawValue == 6)
    precondition(EKWeekday.saturday.rawValue == 7)
    precondition(EKWeekday.EKSunday == .sunday)
    precondition(EKWeekday.EKMonday == .monday)
    precondition(EKWeekday.EKTuesday == .tuesday)
    precondition(EKWeekday.EKWednesday == .wednesday)
    precondition(EKWeekday.EKThursday == .thursday)
    precondition(EKWeekday.EKFriday == .friday)
    precondition(EKWeekday.EKSaturday == .saturday)
    precondition(EKWeekday(rawValue: 1) == .sunday)

    precondition(EKReminderPriority.none.rawValue == 0)
    precondition(EKReminderPriority.high.rawValue == 1)
    precondition(EKReminderPriority.medium.rawValue == 5)
    precondition(EKReminderPriority.low.rawValue == 9)
    precondition(EKReminderPriority(rawValue: 5) == .medium)

    precondition(EKEventAvailability.notSupported.rawValue == -1)
    precondition(EKEventAvailability.busy.rawValue == 0)
    precondition(EKEventAvailability.free.rawValue == 1)
    precondition(EKEventAvailability.tentative.rawValue == 2)
    precondition(EKEventAvailability.unavailable.rawValue == 3)
    precondition(EKEventAvailability(rawValue: 0) == .busy)

    precondition(EKEntityType.event.rawValue == 0)
    precondition(EKEntityType.reminder.rawValue == 1)
    precondition(EKEntityType(rawValue: 1) == .reminder)
    precondition(EKSpan.thisEvent.rawValue == 0)
    precondition(EKSpan.futureEvents.rawValue == 1)
    precondition(EKSpan(rawValue: 0) == .thisEvent)
    precondition(EKAlarmProximity.none.rawValue == 0)
    precondition(EKAlarmProximity.enter.rawValue == 1)
    precondition(EKAlarmProximity.leave.rawValue == 2)
    precondition(EKAlarmProximity(rawValue: 2) == .leave)
    precondition(EKAlarmType.display.rawValue == 0)
    precondition(EKAlarmType.audio.rawValue == 1)
    precondition(EKAlarmType.procedure.rawValue == 2)
    precondition(EKAlarmType.email.rawValue == 3)
    precondition(EKAlarmType(rawValue: 1) == .audio)
    precondition(EKCalendarType.local.rawValue == 0)
    precondition(EKCalendarType.calDAV.rawValue == 1)
    precondition(EKCalendarType.exchange.rawValue == 2)
    precondition(EKCalendarType.subscription.rawValue == 3)
    precondition(EKCalendarType.birthday.rawValue == 4)
    precondition(EKCalendarType(rawValue: 0) == .local)
    precondition(EKSourceType.local.rawValue == 0)
    precondition(EKSourceType.exchange.rawValue == 1)
    precondition(EKSourceType.calDAV.rawValue == 2)
    precondition(EKSourceType.mobileMe.rawValue == 3)
    precondition(EKSourceType.subscribed.rawValue == 4)
    precondition(EKSourceType.birthdays.rawValue == 5)
    precondition(EKSourceType(rawValue: 0) == .local)
    precondition(EKRecurrenceFrequency.daily.rawValue == 0)
    precondition(EKRecurrenceFrequency.weekly.rawValue == 1)
    precondition(EKRecurrenceFrequency.monthly.rawValue == 2)
    precondition(EKRecurrenceFrequency.yearly.rawValue == 3)
    precondition(EKRecurrenceFrequency(rawValue: 2) == .monthly)
    precondition(EKEventStatus.none.rawValue == 0)
    precondition(EKEventStatus.confirmed.rawValue == 1)
    precondition(EKEventStatus.tentative.rawValue == 2)
    precondition(EKEventStatus.canceled.rawValue == 3)
    precondition(EKEventStatus(rawValue: 1) == .confirmed)
    precondition(EKParticipantRole.unknown.rawValue == 0)
    precondition(EKParticipantRole.required.rawValue == 1)
    precondition(EKParticipantRole.optional.rawValue == 2)
    precondition(EKParticipantRole.chair.rawValue == 3)
    precondition(EKParticipantRole.nonParticipant.rawValue == 4)
    precondition(EKParticipantRole(rawValue: 3) == .chair)
    precondition(EKParticipantStatus.unknown.rawValue == 0)
    precondition(EKParticipantStatus.pending.rawValue == 1)
    precondition(EKParticipantStatus.accepted.rawValue == 2)
    precondition(EKParticipantStatus.declined.rawValue == 3)
    precondition(EKParticipantStatus.tentative.rawValue == 4)
    precondition(EKParticipantStatus.delegated.rawValue == 5)
    precondition(EKParticipantStatus.completed.rawValue == 6)
    precondition(EKParticipantStatus.inProcess.rawValue == 7)
    precondition(EKParticipantStatus(rawValue: 2) == .accepted)
    precondition(EKParticipantType.unknown.rawValue == 0)
    precondition(EKParticipantType.person.rawValue == 1)
    precondition(EKParticipantType.room.rawValue == 2)
    precondition(EKParticipantType.resource.rawValue == 3)
    precondition(EKParticipantType.group.rawValue == 4)
    precondition(EKParticipantType(rawValue: 1) == .person)
    precondition(EKParticipantScheduleStatus.none.rawValue == 0)
    precondition(EKParticipantScheduleStatus.pending.rawValue == 1)
    precondition(EKParticipantScheduleStatus.sent.rawValue == 2)
    precondition(EKParticipantScheduleStatus.delivered.rawValue == 3)
    precondition(EKParticipantScheduleStatus.recipientNotRecognized.rawValue == 4)
    precondition(EKParticipantScheduleStatus.noPrivileges.rawValue == 5)
    precondition(EKParticipantScheduleStatus.deliveryFailed.rawValue == 6)
    precondition(EKParticipantScheduleStatus.cannotDeliver.rawValue == 7)
    precondition(EKParticipantScheduleStatus.recipientNotAllowed.rawValue == 8)
    precondition(EKParticipantScheduleStatus(rawValue: 1) == .pending)
}


func testEnumHashableAndInequality() {
    precondition(EKAlarmProximity.none != .enter)
    precondition(EKAlarmType.display != .audio)
    precondition(EKAuthorizationStatus.denied != .restricted)
    precondition(EKCalendarType.local != .calDAV)
    precondition(EKEntityType.event != .reminder)
    precondition(EKEventAvailability.busy != .free)
    precondition(EKEventStatus.none != .confirmed)
    precondition(EKParticipantRole.unknown != .required)
    precondition(EKParticipantScheduleStatus.pending != .sent)
    precondition(EKParticipantStatus.accepted != .declined)
    precondition(EKParticipantType.person != .room)
    precondition(EKRecurrenceFrequency.daily != .weekly)
    precondition(EKReminderPriority.high != .low)
    precondition(EKSourceType.local != .calDAV)
    precondition(EKSpan.thisEvent != .futureEvents)
    precondition(EKWeekday.monday != .friday)
    precondition(EKCalendarEventAvailabilityMask.busy != .free)
    precondition(EKEntityMask.event != .reminder)
    precondition(EKError(.osNotSupported) != EKError(.noCalendar))

    let hashed: Set<EKAuthorizationStatus> = [.denied, .restricted, .fullAccess]
    precondition(hashed.contains(.denied))
    _ = EKAlarmProximity.none.hashValue
    _ = EKAlarmType.display.hashValue
    _ = EKAuthorizationStatus.denied.hashValue
    _ = EKCalendarType.local.hashValue
    _ = EKEntityType.event.hashValue
    _ = EKError.Code.osNotSupported.hashValue
    _ = EKEventAvailability.busy.hashValue
    _ = EKEventStatus.none.hashValue
    _ = EKParticipantRole.unknown.hashValue
    _ = EKParticipantScheduleStatus.pending.hashValue
    _ = EKParticipantStatus.accepted.hashValue
    _ = EKParticipantType.person.hashValue
    _ = EKRecurrenceFrequency.daily.hashValue
    _ = EKReminderPriority.high.hashValue
    _ = EKSourceType.local.hashValue
    _ = EKSpan.thisEvent.hashValue
    _ = EKWeekday.monday.hashValue
    var hasher = Hasher()
    EKAlarmProximity.none.hash(into: &hasher)
    EKAlarmType.display.hash(into: &hasher)
    EKAuthorizationStatus.denied.hash(into: &hasher)
    EKCalendarType.local.hash(into: &hasher)
    EKEntityType.event.hash(into: &hasher)
    EKError.Code.noCalendar.hash(into: &hasher)
    EKEventAvailability.busy.hash(into: &hasher)
    EKEventStatus.none.hash(into: &hasher)
    EKParticipantRole.unknown.hash(into: &hasher)
    EKParticipantScheduleStatus.pending.hash(into: &hasher)
    EKParticipantStatus.accepted.hash(into: &hasher)
    EKParticipantType.person.hash(into: &hasher)
    EKRecurrenceFrequency.daily.hash(into: &hasher)
    EKReminderPriority.medium.hash(into: &hasher)
    EKSourceType.local.hash(into: &hasher)
    EKSpan.futureEvents.hash(into: &hasher)
    EKWeekday.sunday.hash(into: &hasher)
    _ = hasher.finalize()
}


func testOptionSetAlgebra() {
    var mask: EKEntityMask = [.event]
    precondition(mask.contains(.event))
    precondition(!mask.contains(.reminder))
    _ = mask.insert(.reminder)
    precondition(mask.contains(.reminder))
    precondition(mask.union(.event) == [.event, .reminder])
    precondition(mask.intersection(.event) == .event)
    precondition(mask.subtracting(.reminder) == .event)
    precondition(EKEntityMask().isEmpty)
    precondition(EKEntityMask.event.isSubset(of: [.event, .reminder]))
    _ = mask.remove(.event)
    _ = mask.update(with: .reminder)
    mask.formUnion(.event)
    mask.formIntersection([.event, .reminder])
    mask.formSymmetricDifference(.reminder)
    mask.subtract(.event)
    precondition(EKEntityMask.event.isDisjoint(with: .reminder))
    precondition(EKEntityMask([.event, .reminder]).isSuperset(of: .event))
    precondition(EKEntityMask.event.isStrictSubset(of: [.event, .reminder]))
    precondition(EKEntityMask([.event, .reminder]).isStrictSuperset(of: .event))
    _ = EKEntityMask([EKEntityMask.event])
    _ = EKEntityMask.event.symmetricDifference(.reminder)
    _ = EKEntityMask(rawValue: 1)
    _ = EKEntityMask()

    _ = EKCalendarEventAvailabilityMask(arrayLiteral: .busy, .free)
    var avail: EKCalendarEventAvailabilityMask = [.busy]
    precondition(avail.contains(.busy))
    precondition(!avail.contains(.tentative))
    _ = avail.insert(.free)
    _ = avail.remove(.busy)
    _ = avail.update(with: .tentative)
    avail.formUnion(.unavailable)
    avail.formIntersection([.tentative, .unavailable])
    avail.formSymmetricDifference(.tentative)
    avail.subtract(.unavailable)
    precondition(EKCalendarEventAvailabilityMask.busy.isDisjoint(with: .free))
    precondition(EKCalendarEventAvailabilityMask([.busy, .free]).isSuperset(of: .busy))
    precondition(EKCalendarEventAvailabilityMask.busy.isSubset(of: [.busy, .free]))
    precondition(EKCalendarEventAvailabilityMask.busy.isStrictSubset(of: [.busy, .free]))
    precondition(EKCalendarEventAvailabilityMask([.busy, .free]).isStrictSuperset(of: .busy))
    precondition(EKCalendarEventAvailabilityMask().isEmpty)
    precondition(EKCalendarEventAvailabilityMask.busy.subtracting(.busy).isEmpty)
    precondition(EKCalendarEventAvailabilityMask.busy.union(.free).contains(.free))
    precondition(EKCalendarEventAvailabilityMask([.busy, .free]).intersection(.busy) == .busy)
    precondition(
        EKCalendarEventAvailabilityMask.busy.symmetricDifference(.free) == [.busy, .free]
    )
    _ = EKCalendarEventAvailabilityMask([EKCalendarEventAvailabilityMask.busy])
    _ = EKCalendarEventAvailabilityMask()
    _ = EKCalendarEventAvailabilityMask(rawValue: 1)
    precondition(EKCalendarEventAvailabilityMask.tentative.rawValue == 1 << 2)
    precondition(EKCalendarEventAvailabilityMask.unavailable.rawValue == 1 << 3)
}


func testPublicTypealiases() {
    let cfBook: CFTypeRef = NSObject()
    let book: ABAddressBook = cfBook
    let record: ABRecord? = nil
    _ = (book, record)
    let identifier: EKVirtualConferenceRoomTypeIdentifier = "standup"
    precondition(identifier == "standup")
    let store = EKEventStore()
    let handler: EKEventStoreRequestAccessCompletionHandler = { _, _ in }
    _ = handler
    let search: EKEventSearchCallback = { _, stop in
        stop.pointee = true
    }
    _ = search
    _ = store.eventStoreIdentifier
}
