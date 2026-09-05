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

// MARK: - EventKitTypeTests.swift

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

// MARK: - EventKitErrorTests.swift

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

// MARK: - EventKitAuthorizationTests.swift

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

        let fullEvents = eventKitRequestAccessHandler { completion in
            store.requestFullAccessToEvents(completion: completion)
        }
        precondition(fullEvents.0 == false)
        precondition(fullEvents.1 == nil)

        let fullReminders = eventKitRequestAccessHandler { completion in
            store.requestFullAccessToReminders(completion: completion)
        }
        precondition(fullReminders.0 == false)
        precondition(fullReminders.1 == nil)

        let writeOnly = eventKitRequestAccessHandler { completion in
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
        let fullEvents = eventKitRequestAccessHandler { completion in
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
        let writeOnly = eventKitRequestAccessHandler { completion in
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

// MARK: - EventKitCalendarSourceTests.swift

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

// MARK: - EventKitSpanTests.swift

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

// MARK: - EventKitRecurrenceTests.swift

func testRecurrenceDailyExamples() {
    let calendar = eventKitGMTCalendar()
    func starts(_ rule: EKRecurrenceRule, from start: Date, days: Int) -> [Date] {
        EKRecurrenceExpansion.occurrenceStarts(
            rule: rule,
            seriesStart: start,
            rangeStart: start,
            rangeEnd: calendar.date(byAdding: .day, value: days, to: start)!,
            calendar: calendar
        )
    }
    let jan1 = eventKitGMTDate(2026, 1, 1)
    let daily = EKRecurrenceRule(
        recurrenceWith: .daily,
        interval: 1,
        end: EKRecurrenceEnd(occurrenceCount: 3)
    )
    let dailyDates = starts(daily, from: jan1, days: 10)
    precondition(dailyDates.count == 3)
    precondition(dailyDates[0] == jan1)
    precondition(dailyDates[1] == eventKitGMTDate(2026, 1, 2))
    precondition(dailyDates[2] == eventKitGMTDate(2026, 1, 3))

    let daily2 = EKRecurrenceRule(
        recurrenceWith: .daily,
        interval: 2,
        end: EKRecurrenceEnd(occurrenceCount: 3)
    )
    let everyOther = starts(daily2, from: jan1, days: 10)
    precondition(everyOther.map { calendar.component(.day, from: $0) } == [1, 3, 5])
}

func testRecurrenceWeeklyExamples() {
    let calendar = eventKitGMTCalendar()
    func starts(_ rule: EKRecurrenceRule, from start: Date, days: Int) -> [Date] {
        EKRecurrenceExpansion.occurrenceStarts(
            rule: rule,
            seriesStart: start,
            rangeStart: start,
            rangeEnd: calendar.date(byAdding: .day, value: days, to: start)!,
            calendar: calendar
        )
    }
    let monday = eventKitGMTDate(2026, 1, 5)
    precondition(calendar.component(.weekday, from: monday) == EKWeekday.monday.rawValue)
    let weeklyMon = EKRecurrenceRule(
        recurrenceWith: .weekly,
        interval: 1,
        daysOfTheWeek: [EKRecurrenceDayOfWeek(.monday)],
        daysOfTheMonth: nil,
        monthsOfTheYear: nil,
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: EKRecurrenceEnd(occurrenceCount: 4)
    )
    let mondays = starts(weeklyMon, from: monday, days: 40)
    precondition(mondays.map { calendar.component(.day, from: $0) } == [5, 12, 19, 26])

    let mwf = EKRecurrenceRule(
        recurrenceWith: .weekly,
        interval: 1,
        daysOfTheWeek: [
            EKRecurrenceDayOfWeek(.monday),
            EKRecurrenceDayOfWeek(.wednesday),
            EKRecurrenceDayOfWeek(.friday),
        ],
        daysOfTheMonth: nil,
        monthsOfTheYear: nil,
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: EKRecurrenceEnd(occurrenceCount: 6)
    )
    let mwfDates = starts(mwf, from: monday, days: 20)
    precondition(mwfDates.map { calendar.component(.day, from: $0) } == [5, 7, 9, 12, 14, 16])
}

func testRecurrenceMonthlyAndYearlyExamples() {
    let calendar = eventKitGMTCalendar()
    func starts(_ rule: EKRecurrenceRule, from start: Date, days: Int) -> [Date] {
        EKRecurrenceExpansion.occurrenceStarts(
            rule: rule,
            seriesStart: start,
            rangeStart: start,
            rangeEnd: calendar.date(byAdding: .day, value: days, to: start)!,
            calendar: calendar
        )
    }
    let monthly = EKRecurrenceRule(
        recurrenceWith: .monthly,
        interval: 1,
        daysOfTheWeek: nil,
        daysOfTheMonth: [NSNumber(value: 15)],
        monthsOfTheYear: nil,
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: EKRecurrenceEnd(occurrenceCount: 3)
    )
    let fifteenths = starts(monthly, from: eventKitGMTDate(2026, 1, 15), days: 80)
    precondition(fifteenths.count == 3)
    precondition(calendar.component(.month, from: fifteenths[1]) == 2)
    precondition(calendar.component(.day, from: fifteenths[1]) == 15)
    precondition(calendar.component(.month, from: fifteenths[2]) == 3)

    let lastFriday = EKRecurrenceRule(
        recurrenceWith: .monthly,
        interval: 1,
        daysOfTheWeek: [EKRecurrenceDayOfWeek(.friday, weekNumber: -1)],
        daysOfTheMonth: nil,
        monthsOfTheYear: nil,
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: EKRecurrenceEnd(occurrenceCount: 3)
    )
    let lastFridays = starts(lastFriday, from: eventKitGMTDate(2026, 1, 30), days: 90)
    precondition(lastFridays.count == 3)
    precondition(calendar.component(.day, from: lastFridays[1]) == 27)
    precondition(calendar.component(.month, from: lastFridays[1]) == 2)
    precondition(calendar.component(.day, from: lastFridays[2]) == 27)
    precondition(calendar.component(.month, from: lastFridays[2]) == 3)

    let yearly = EKRecurrenceRule(
        recurrenceWith: .yearly,
        interval: 1,
        daysOfTheWeek: nil,
        daysOfTheMonth: [NSNumber(value: 1)],
        monthsOfTheYear: [NSNumber(value: 1)],
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: EKRecurrenceEnd(occurrenceCount: 3)
    )
    let years = starts(yearly, from: eventKitGMTDate(2026, 1, 1), days: 800)
    precondition(years.map { calendar.component(.year, from: $0) } == [2026, 2027, 2028])
}

func testRecurrenceRuleValueSemanticsAndCoding() {
    let monday = EKRecurrenceDayOfWeek(.monday)
    precondition(monday.dayOfTheWeek == .monday)
    precondition(monday.weekNumber == 0)
    let secondFriday = EKRecurrenceDayOfWeek(.friday, weekNumber: 2)
    precondition(secondFriday.weekNumber == 2)
    let designated = EKRecurrenceDayOfWeek(dayOfTheWeek: .sunday, weekNumber: -1)
    precondition(designated.weekNumber == -1)
    let clamped = EKRecurrenceDayOfWeek(dayOfTheWeek: .monday, weekNumber: 100)
    precondition(clamped.weekNumber == 53)

    let endByDate = EKRecurrenceEnd(end: Date(timeIntervalSince1970: 1_800_000_000))
    let endByDateAlias = EKRecurrenceEnd(endDate: Date(timeIntervalSince1970: 1_800_000_000))
    precondition(endByDate.endDate != nil)
    precondition(endByDateAlias.occurrenceCount == 0)
    let endByCount = EKRecurrenceEnd(occurrenceCount: 8)
    precondition(endByCount.occurrenceCount == 8)
    precondition(endByCount.endDate == nil)
    let negativeCount = EKRecurrenceEnd(occurrenceCount: -4)
    precondition(negativeCount.occurrenceCount == 0)

    let weekly = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: endByCount)
    precondition(weekly.frequency == .weekly)
    precondition(weekly.interval == 1)
    precondition(weekly.calendarIdentifier == "gregorian")
    precondition(weekly.firstDayOfTheWeek == 0)
    weekly.recurrenceEnd = endByDate
    precondition(weekly.hasChanges)
    weekly.rollback()
    precondition(!weekly.hasChanges)
    precondition(weekly.recurrenceEnd?.occurrenceCount == 8)

    let monthly = EKRecurrenceRule(
        recurrenceWithFrequency: .monthly,
        interval: 2,
        daysOfTheWeek: [monday, secondFriday],
        daysOfTheMonth: [NSNumber(value: 1)],
        monthsOfTheYear: [NSNumber(value: 9)],
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: [NSNumber(value: 1)],
        end: endByDate
    )
    precondition(monthly.daysOfTheWeek?.count == 2)
    precondition(monthly.daysOfTheMonth?.first?.intValue == 1)
    precondition(monthly.monthsOfTheYear?.first?.intValue == 9)
    precondition(monthly.weeksOfTheYear == nil)
    precondition(monthly.daysOfTheYear == nil)
    precondition(monthly.setPositions?.first?.intValue == 1)
    _ = EKRecurrenceRule(
        recurrenceWith: .yearly,
        interval: 1,
        daysOfTheWeek: nil,
        daysOfTheMonth: nil,
        monthsOfTheYear: [NSNumber(value: 1)],
        weeksOfTheYear: nil,
        daysOfTheYear: [NSNumber(value: 1)],
        setPositions: nil,
        end: nil
    )
    _ = EKRecurrenceRule(recurrenceWithFrequency: .daily, interval: 1, end: nil)
    let ruleCopy = weekly.copy() as? EKRecurrenceRule
    precondition(ruleCopy?.frequency == .weekly)

    let store = EKEventStore()
    let item = EKEvent(eventStore: store)
    item.addRecurrenceRule(weekly)
    precondition(item.hasRecurrenceRules)
    precondition(item.recurrenceRules?.count == 1)
    item.removeRecurrenceRule(weekly)
    precondition(!item.hasRecurrenceRules)
    precondition(item.recurrenceRules == nil)

    do {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(monday, forKey: "day")
        archiver.encode(endByCount, forKey: "end")
        archiver.finishEncoding()
        let data = archiver.encodedData
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        let decodedDay = unarchiver.decodeObject(of: EKRecurrenceDayOfWeek.self, forKey: "day")
        let decodedEnd = unarchiver.decodeObject(of: EKRecurrenceEnd.self, forKey: "end")
        precondition(decodedDay?.dayOfTheWeek == .monday)
        precondition(decodedEnd?.occurrenceCount == 8)
        precondition(EKRecurrenceDayOfWeek.supportsSecureCoding)
        precondition(EKRecurrenceEnd.supportsSecureCoding)
    } catch {
        fatalError("secure coding round-trip failed: \(error)")
    }
}

// MARK: - EventKitPredicateTests.swift

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

// MARK: - EventKitValueSemanticsTests.swift

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

// MARK: - EventKitNotificationTests.swift

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


enum EventKitRuntime {
    static func main() {
        eventKitWithIsolatedStore {
            testEnumRawValuesAndAliases()
            testEnumHashableAndInequality()
            testOptionSetAlgebra()
            testPublicTypealiases()
            testEKErrorCodesAndDomain()
            testEKErrorThrownOnValidation()
            testAuthorizationStartsNotDetermined()
            testAuthorizationDeniedFailsClosed()
            testAuthorizationFullAccessAndWriteOnly()
            testLocalSourceAndDefaultCalendars()
            testSaveAndRemoveCalendar()
            testHostedSourcesAndDelegateSources()
            testSpanThisEventDetachesOccurrence()
            testSpanFutureEventsSplitsSeries()
            testRecurrenceDailyExamples()
            testRecurrenceWeeklyExamples()
            testRecurrenceMonthlyAndYearlyExamples()
            testRecurrenceRuleValueSemanticsAndCoding()
            testEventPredicatesAndFetches()
            testReminderPredicatesAndFetches()
            testEventAndCalendarItemValueSemantics()
            testReminderAlarmAndLocationValueSemantics()
            testParticipantAndVirtualConferenceDescriptors()
            testEventStoreChangedPostedOnCommit()
            testVirtualConferenceProviderFailClosed()
        }
        print("EVENTKIT_AGENT_RUNTIME_OK")
    }
}

EventKitRuntime.main()
