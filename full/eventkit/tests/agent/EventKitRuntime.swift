@_spi(OpenUIKitHost) import EventKit
import CoreFoundation
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

enum EventKitRuntime {
    private static func requireEKError(
        _ error: (any Error)?,
        code: EKError.Code
    ) {
        guard let error = error as? EKError else {
            fatalError("expected typed EKError")
        }
        precondition(error.code == code)
        precondition(error.errorCode == code.rawValue)
        precondition(EKError.errorDomain == EKErrorDomain)
    }

    private static func requireThrown(_ code: EKError.Code, work: () throws -> Void) {
        do {
            try work()
            fatalError("expected EKError to be thrown")
        } catch {
            requireEKError(error, code: code)
            precondition(code ~= error)
        }
    }

    static func main() async {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("eventkit-runtime-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        EKEventStore.useIsolatedStoreDirectory(tmp)
        EKEventStore.resetIsolatedStore()
        EKEventStore.denyAccessRequests = false
        defer { try? FileManager.default.removeItem(at: tmp) }

        exerciseTypesAndErrors()
        exerciseRemainingSurface()
        exerciseObjectModel()
        exerciseRecurrenceCoding()
        exerciseRecurrenceExpansion()
        exercisePredicates()
        await exerciseUnauthorizedStore()
        await exerciseDeniedStore()
        await exerciseAuthorizedStore()
        await exerciseVirtualConference()
        exerciseNotificationName()
        print("EVENTKIT_AGENT_RUNTIME_OK")
    }

    private static func exerciseTypesAndErrors() {
        precondition(EKAuthorizationStatus.notDetermined.rawValue == 0)
        precondition(EKAuthorizationStatus.restricted.rawValue == 1)
        precondition(EKAuthorizationStatus.denied.rawValue == 2)
        precondition(EKAuthorizationStatus.fullAccess.rawValue == 3)
        precondition(EKAuthorizationStatus.writeOnly.rawValue == 4)
        precondition(EKAuthorizationStatus.authorized == .fullAccess)
        precondition(EKAuthorizationStatus.authorized.rawValue == 3)
        precondition(EKAuthorizationStatus(rawValue: 2) == .denied)

        precondition(EKWeekday.sunday.rawValue == 1)
        precondition(EKWeekday.monday.rawValue == 2)
        precondition(EKWeekday.saturday.rawValue == 7)
        precondition(EKWeekday.EKMonday == .monday)
        precondition(EKWeekday.EKSunday == .sunday)

        precondition(EKReminderPriority.none.rawValue == 0)
        precondition(EKReminderPriority.high.rawValue == 1)
        precondition(EKReminderPriority.medium.rawValue == 5)
        precondition(EKReminderPriority.low.rawValue == 9)

        precondition(EKEventAvailability.notSupported.rawValue == -1)
        precondition(EKEventAvailability.busy.rawValue == 0)
        precondition(EKEntityType.event.rawValue == 0)
        precondition(EKEntityType.reminder.rawValue == 1)
        precondition(EKEntityMask.event.rawValue == 1)
        precondition(EKEntityMask.reminder.rawValue == 2)
        precondition(EKSpan.thisEvent.rawValue == 0)
        precondition(EKSpan.futureEvents.rawValue == 1)
        precondition(EKAlarmProximity.none.rawValue == 0)
        precondition(EKAlarmProximity.enter.rawValue == 1)
        precondition(EKAlarmType.display.rawValue == 0)
        precondition(EKCalendarType.local.rawValue == 0)
        precondition(EKSourceType.local.rawValue == 0)
        precondition(EKRecurrenceFrequency.daily.rawValue == 0)
        precondition(EKEventStatus.none.rawValue == 0)
        precondition(EKParticipantRole.unknown.rawValue == 0)
        precondition(EKParticipantStatus.accepted.rawValue == 2)
        precondition(EKParticipantType.person.rawValue == 1)
        precondition(EKParticipantScheduleStatus.pending.rawValue == 1)

        var mask: EKEntityMask = [.event]
        precondition(mask.contains(.event))
        precondition(!mask.contains(.reminder))
        mask.insert(.reminder)
        precondition(mask.contains(.reminder))
        precondition(mask.union(.event) == [.event, .reminder])
        precondition(mask.intersection(.event) == .event)
        precondition(mask.subtracting(.reminder) == .event)
        precondition(EKEntityMask().isEmpty)
        precondition(EKEntityMask.event.isSubset(of: [.event, .reminder]))
        _ = EKCalendarEventAvailabilityMask(arrayLiteral: .busy, .free)
        precondition(EKCalendarEventAvailabilityMask.busy != .free)

        let hashed: Set<EKAuthorizationStatus> = [.denied, .restricted, .fullAccess]
        precondition(hashed.contains(.denied))

        precondition(EKErrorDomain == "EKErrorDomain")
        precondition(EKError.last.rawValue == 37)
        precondition(EKError.eventNotMutable.rawValue == 0)
        precondition(EKError.osNotSupported.rawValue == 29)
        precondition(EKError.eventStoreNotAuthorized.rawValue == 28)
        precondition(EKError.noCalendar == .noCalendar)
        precondition(EKError.noStartDate.rawValue == 1)

        let empty = EKError(.osNotSupported)
        precondition(empty.userInfo.isEmpty)
        precondition(empty.errorUserInfo.isEmpty)
        precondition(empty == EKError(.osNotSupported))
        precondition(empty != EKError(.eventStoreNotAuthorized))
        let tagged = EKError(.osNotSupported, userInfo: ["sentinel": "value"])
        precondition(tagged != empty)
        precondition(tagged.hashValue == empty.hashValue)
        precondition(EKError.Code.osNotSupported ~= empty)
        precondition(EKError.Code(rawValue: 4) == .internalFailure)
        precondition(!empty.localizedDescription.isEmpty)
    }

    private static func exerciseObjectModel() {
        let store = EKEventStore()
        precondition(!store.eventStoreIdentifier.isEmpty)
        precondition(store.sources.isEmpty)
        precondition(store.delegateSources.isEmpty)
        precondition(store.defaultCalendarForNewEvents == nil)
        precondition(store.defaultCalendarForNewReminders() == nil)

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
        precondition(event.status == .none)
        precondition(event.birthdayPersonID == -1)
        precondition(event.birthdayContactIdentifier == nil)
        precondition(event.organizer == nil)
        precondition(!event.isDetached)
        precondition(!event.refresh())

        let other = EKEvent(eventStore: store)
        other.startDate = Date(timeIntervalSince1970: 1_700_010_000)
        precondition(event.compareStartDate(with: other) == .orderedAscending)

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

        event.rollback()
        precondition(!event.hasChanges)
        precondition(event.title == nil)
        precondition(event.occurrenceDate == nil)

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

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Work"
        precondition(calendar.allowedEntityTypes.contains(.event))
        precondition(!calendar.allowedEntityTypes.contains(.reminder))
        precondition(calendar.type == .local)
        precondition(calendar.allowsContentModifications)
        precondition(!calendar.isImmutable)
        precondition(!calendar.isSubscribed)
        let aliasCalendar = EKCalendar(forEntityType: .reminder, eventStore: store)
        precondition(aliasCalendar.allowedEntityTypes.contains(.reminder))

        let source = EKSource()
        precondition(!source.sourceIdentifier.isEmpty)
        precondition(source.sourceType == .local)
        precondition(!source.isDelegate)
        precondition(source.calendars(for: .event).isEmpty)
        calendar.source = source

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

        event.reset()
        precondition(!event.hasChanges)
    }

    private static func exerciseRecurrenceCoding() {
        let monday = EKRecurrenceDayOfWeek(.monday)
        precondition(monday.dayOfTheWeek == .monday)
        precondition(monday.weekNumber == 0)
        let secondFriday = EKRecurrenceDayOfWeek(.friday, weekNumber: 2)
        let designated = EKRecurrenceDayOfWeek(dayOfTheWeek: .sunday, weekNumber: -1)
        precondition(designated.weekNumber == -1)

        let endByDate = EKRecurrenceEnd(end: Date(timeIntervalSince1970: 1_800_000_000))
        let endByDateAlias = EKRecurrenceEnd(endDate: Date(timeIntervalSince1970: 1_800_000_000))
        precondition(endByDate.endDate != nil)
        precondition(endByDateAlias.occurrenceCount == 0)
        let endByCount = EKRecurrenceEnd(occurrenceCount: 8)
        precondition(endByCount.occurrenceCount == 8)
        precondition(endByCount.endDate == nil)

        let weekly = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: endByCount
        )
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
            let decodedDay = unarchiver.decodeObject(
                of: EKRecurrenceDayOfWeek.self,
                forKey: "day"
            )
            let decodedEnd = unarchiver.decodeObject(
                of: EKRecurrenceEnd.self,
                forKey: "end"
            )
            precondition(decodedDay?.dayOfTheWeek == .monday)
            precondition(decodedEnd?.occurrenceCount == 8)
        } catch {
            fatalError("secure coding round-trip failed: \(error)")
        }
    }

    private static func exercisePredicates() {
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

        let emptyReminderCalendars = store.predicateForReminders(in: [])
        precondition(!emptyReminderCalendars.evaluate(with: incomplete))
        let allReminders = store.predicateForReminders(in: nil)
        precondition(allReminders.evaluate(with: incomplete))

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
    }

    private static func exerciseUnauthorizedStore() async {
        let store = EKEventStore()
        precondition(EKEventStore.authorizationStatus(for: .event) == .notDetermined)
        precondition(EKEventStore.authorizationStatus(for: .reminder) == .notDetermined)

        let event = EKEvent(eventStore: store)
        event.title = "Must not persist"
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(60)
        requireThrown(.eventStoreNotAuthorized) {
            try store.save(event, span: .thisEvent)
        }
        requireThrown(.eventStoreNotAuthorized) {
            try store.save(event, span: .futureEvents, commit: false)
        }
        requireThrown(.eventStoreNotAuthorized) {
            try store.remove(event, span: .thisEvent)
        }
        requireThrown(.eventStoreNotAuthorized) {
            try store.remove(event, span: .thisEvent, commit: false)
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = "Must not persist"
        requireThrown(.eventStoreNotAuthorized) {
            try store.save(reminder, commit: true)
        }
        requireThrown(.eventStoreNotAuthorized) {
            try store.remove(reminder, commit: true)
        }

        let calendar = EKCalendar(for: .event, eventStore: store)
        requireThrown(.eventStoreNotAuthorized) {
            try store.saveCalendar(calendar, commit: true)
        }
        requireThrown(.eventStoreNotAuthorized) {
            try store.removeCalendar(calendar, commit: true)
        }
        requireThrown(.eventStoreNotAuthorized) {
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
            fatalError("host store must not enumerate events")
        }
        precondition(store.event(withIdentifier: "missing") == nil)
        precondition(store.calendarItem(withIdentifier: "missing") == nil)
        precondition(store.calendarItems(withExternalIdentifier: "missing").isEmpty)
        precondition(store.calendar(withIdentifier: "missing") == nil)
        precondition(store.calendars(for: .event).isEmpty)
        precondition(store.source(withIdentifier: "missing") == nil)

        let sourced = EKEventStore(sources: [EKSource()])
        precondition(sourced.sources.count == 1)
        precondition(sourced.source(withIdentifier: sourced.sources[0].sourceIdentifier) === sourced.sources[0])
        precondition(sourced.delegateSources.isEmpty)

        var fetchReturned = false
        var fetchReentrant = false
        let fetchDone = await withCheckedContinuation { continuation in
            let token = store.fetchReminders(matching: store.predicateForReminders(in: nil)) { reminders in
                fetchReentrant = !fetchReturned
                continuation.resume(returning: reminders)
            }
            store.cancelFetchRequest(token)
            fetchReturned = true
        }
        precondition(fetchReturned)
        precondition(!fetchReentrant)
        precondition(fetchDone == nil)

        store.refreshSourcesIfNecessary()
        store.reset()
    }

    private static func freshIsolatedStore() -> EKEventStore {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("eventkit-case-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        EKEventStore.useIsolatedStoreDirectory(tmp)
        EKEventStore.resetIsolatedStore()
        EKEventStore.denyAccessRequests = false
        return EKEventStore()
    }

    private static func exerciseDeniedStore() async {
        let store = freshIsolatedStore()
        EKEventStore.denyAccessRequests = true
        var accessReturned = false
        do {
            let granted = try await store.requestAccess(to: .event)
            accessReturned = true
            precondition(granted == false)
        } catch {
            fatalError("denied requestAccess must not throw: \(error)")
        }
        precondition(accessReturned)
        precondition(EKEventStore.authorizationStatus(for: .event) == .denied)

        var fullEventsReturned = false
        var fullEventsReentrant = false
        let fullEvents = await withCheckedContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                fullEventsReentrant = !fullEventsReturned
                continuation.resume(returning: (granted, error))
            }
            fullEventsReturned = true
        }
        precondition(fullEventsReturned)
        precondition(!fullEventsReentrant)
        precondition(fullEvents.0 == false)
        precondition(fullEvents.1 == nil)

        var remindersReturned = false
        var remindersReentrant = false
        let fullReminders = await withCheckedContinuation { continuation in
            store.requestFullAccessToReminders { granted, error in
                remindersReentrant = !remindersReturned
                continuation.resume(returning: (granted, error))
            }
            remindersReturned = true
        }
        precondition(!remindersReentrant)
        precondition(fullReminders.0 == false)
        precondition(fullReminders.1 == nil)

        var writeReturned = false
        var writeReentrant = false
        let writeOnly = await withCheckedContinuation { continuation in
            store.requestWriteOnlyAccessToEvents { granted, error in
                writeReentrant = !writeReturned
                continuation.resume(returning: (granted, error))
            }
            writeReturned = true
        }
        precondition(!writeReentrant)
        precondition(writeOnly.0 == false)
        precondition(writeOnly.1 == nil)
        EKEventStore.denyAccessRequests = false
    }

    private static func exerciseRemainingSurface() {
        precondition(EKAlarmProximity.leave.rawValue == 2)
        precondition(EKAlarmType.audio.rawValue == 1)
        precondition(EKAlarmType.email.rawValue == 3)
        precondition(EKAlarmType.procedure.rawValue == 2)
        precondition(EKCalendarType.birthday.rawValue == 4)
        precondition(EKCalendarType.calDAV.rawValue == 1)
        precondition(EKCalendarType.exchange.rawValue == 2)
        precondition(EKCalendarType.subscription.rawValue == 3)
        precondition(EKEventAvailability.free.rawValue == 1)
        precondition(EKEventAvailability.tentative.rawValue == 2)
        precondition(EKEventAvailability.unavailable.rawValue == 3)
        precondition(EKEventStatus.canceled.rawValue == 3)
        precondition(EKEventStatus.confirmed.rawValue == 1)
        precondition(EKEventStatus.tentative.rawValue == 2)
        precondition(EKParticipantRole.chair.rawValue == 3)
        precondition(EKParticipantRole.nonParticipant.rawValue == 4)
        precondition(EKParticipantRole.optional.rawValue == 2)
        precondition(EKParticipantRole.required.rawValue == 1)
        precondition(EKParticipantScheduleStatus.cannotDeliver.rawValue == 7)
        precondition(EKParticipantScheduleStatus.delivered.rawValue == 3)
        precondition(EKParticipantScheduleStatus.deliveryFailed.rawValue == 6)
        precondition(EKParticipantScheduleStatus.noPrivileges.rawValue == 5)
        precondition(EKParticipantScheduleStatus.none.rawValue == 0)
        precondition(EKParticipantScheduleStatus.recipientNotAllowed.rawValue == 8)
        precondition(EKParticipantScheduleStatus.recipientNotRecognized.rawValue == 4)
        precondition(EKParticipantScheduleStatus.sent.rawValue == 2)
        precondition(EKParticipantStatus.completed.rawValue == 6)
        precondition(EKParticipantStatus.declined.rawValue == 3)
        precondition(EKParticipantStatus.delegated.rawValue == 5)
        precondition(EKParticipantStatus.inProcess.rawValue == 7)
        precondition(EKParticipantStatus.pending.rawValue == 1)
        precondition(EKParticipantStatus.tentative.rawValue == 4)
        precondition(EKParticipantStatus.unknown.rawValue == 0)
        precondition(EKParticipantType.group.rawValue == 4)
        precondition(EKParticipantType.resource.rawValue == 3)
        precondition(EKParticipantType.room.rawValue == 2)
        precondition(EKParticipantType.unknown.rawValue == 0)
        precondition(EKSourceType.birthdays.rawValue == 5)
        precondition(EKSourceType.calDAV.rawValue == 2)
        precondition(EKSourceType.exchange.rawValue == 1)
        precondition(EKSourceType.mobileMe.rawValue == 3)
        precondition(EKSourceType.subscribed.rawValue == 4)
        precondition(EKWeekday.EKFriday == .friday)
        precondition(EKWeekday.EKSaturday == .saturday)
        precondition(EKWeekday.EKThursday == .thursday)
        precondition(EKWeekday.EKTuesday == .tuesday)
        precondition(EKWeekday.EKWednesday == .wednesday)
        precondition(EKWeekday.friday.rawValue == 6)
        precondition(EKWeekday.thursday.rawValue == 5)
        precondition(EKWeekday.tuesday.rawValue == 3)
        precondition(EKWeekday.wednesday.rawValue == 4)

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
        precondition(EKError.datesInverted.rawValue == 3)
        precondition(EKError.noEndDate.rawValue == 2)
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
        precondition(EKError.invalidInviteReplyCalendar.rawValue == 30)
        precondition(EKError.notificationsCollectionFlagNotSet.rawValue == 31)
        precondition(EKError.sourceMismatch.rawValue == 32)
        precondition(EKError.notificationCollectionMismatch.rawValue == 33)
        precondition(EKError.notificationSavedWithoutCollection.rawValue == 34)
        precondition(EKError.reminderAlarmContainsEmailOrUrl.rawValue == 35)
        for code in codes {
            precondition(EKError(code).code == code)
            precondition(code != .last || code.rawValue == 37)
        }

        precondition(EKAlarmProximity.none != .enter)
        precondition(EKAlarmType.display != .audio)
        precondition(EKAuthorizationStatus.denied != .restricted)
        precondition(EKCalendarType.local != .calDAV)
        precondition(EKEntityType.event != .reminder)
        precondition(EKError(.osNotSupported) != EKError(.noCalendar))
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

        var entities: EKEntityMask = [.event]
        _ = entities.remove(.event)
        _ = entities.update(with: .reminder)
        entities.formUnion(.event)
        entities.formIntersection([.event, .reminder])
        entities.formSymmetricDifference(.reminder)
        entities.subtract(.event)
        precondition(EKEntityMask.event.isDisjoint(with: .reminder))
        precondition(EKEntityMask([.event, .reminder]).isSuperset(of: .event))
        precondition(EKEntityMask.event.isStrictSubset(of: [.event, .reminder]))
        precondition(EKEntityMask([.event, .reminder]).isStrictSuperset(of: .event))
        _ = EKEntityMask([EKEntityMask.event])
        _ = EKEntityMask.event.symmetricDifference(.reminder)
    }

    private static func gmtCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func gmtDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        gmtCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private static func exerciseRecurrenceExpansion() {
        let calendar = gmtCalendar()
        func starts(_ rule: EKRecurrenceRule, from start: Date, days: Int) -> [Date] {
            EKRecurrenceExpansion.occurrenceStarts(
                rule: rule,
                seriesStart: start,
                rangeStart: start,
                rangeEnd: calendar.date(byAdding: .day, value: days, to: start)!,
                calendar: calendar
            )
        }

        let jan1 = gmtDate(2026, 1, 1)
        let daily = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 1,
            end: EKRecurrenceEnd(occurrenceCount: 3)
        )
        let dailyDates = starts(daily, from: jan1, days: 10)
        precondition(dailyDates.count == 3)
        precondition(dailyDates[0] == jan1)
        precondition(dailyDates[1] == gmtDate(2026, 1, 2))
        precondition(dailyDates[2] == gmtDate(2026, 1, 3))

        let daily2 = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 2,
            end: EKRecurrenceEnd(occurrenceCount: 3)
        )
        let everyOther = starts(daily2, from: jan1, days: 10)
        precondition(everyOther.map { calendar.component(.day, from: $0) } == [1, 3, 5])

        let monday = gmtDate(2026, 1, 5)
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
        let fifteenths = starts(monthly, from: gmtDate(2026, 1, 15), days: 80)
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
        let lastFridays = starts(lastFriday, from: gmtDate(2026, 1, 30), days: 90)
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
        let years = starts(yearly, from: jan1, days: 800)
        precondition(years.map { calendar.component(.year, from: $0) } == [2026, 2027, 2028])

        let clamped = EKRecurrenceDayOfWeek(dayOfTheWeek: .monday, weekNumber: 100)
        precondition(clamped.weekNumber == 53)
        let negativeCount = EKRecurrenceEnd(occurrenceCount: -4)
        precondition(negativeCount.occurrenceCount == 0)
    }

    private static func exerciseAuthorizedStore() async {
        let store = freshIsolatedStore()
        var grantedEvents = false
        let fullEvents = await withCheckedContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                continuation.resume(returning: (granted, error))
            }
            grantedEvents = true
        }
        precondition(grantedEvents)
        precondition(fullEvents.0 == true)
        precondition(fullEvents.1 == nil)
        precondition(EKEventStore.authorizationStatus(for: .event) == .fullAccess)

        let reminderGrant = try! await store.requestAccess(to: .reminder)
        precondition(reminderGrant)
        precondition(EKEventStore.authorizationStatus(for: .reminder) == .fullAccess)

        precondition(store.defaultCalendarForNewEvents != nil)
        precondition(store.defaultCalendarForNewReminders() != nil)
        precondition(store.sources.contains { $0.sourceType == .local && $0.title == "On This Device" })
        #if canImport(CoreGraphics)
        let components = store.defaultCalendarForNewEvents!.cgColor.components
        precondition(components != nil)
        precondition(abs(Double(components![1]) - 0.478) < 0.001)
        #endif

        #if canImport(CoreLocation)
        let named = EKStructuredLocation(title: "HQ")
        named.geoLocation = CLLocation(latitude: 37.3349, longitude: -122.009)
        precondition(abs((named.geoLocation?.coordinate.latitude ?? 0) - 37.3349) < 0.0001)
        #endif
        #if canImport(MapKit) && canImport(CoreLocation)
        let mapItem = MKMapItem(
            location: CLLocation(latitude: 37.3349, longitude: -122.009),
            address: nil
        )
        mapItem.name = "Apple Park"
        let fromMap = EKStructuredLocation(mapItem: mapItem)
        precondition(fromMap.title == "Apple Park")
        precondition(abs((fromMap.geoLocation?.coordinate.latitude ?? 0) - 37.3349) < 0.0001)
        #endif

        let event = EKEvent(eventStore: store)
        event.title = "Standup"
        event.notes = "Weekly"
        event.location = "Library"
        event.startDate = gmtDate(2026, 3, 2)
        event.endDate = gmtDate(2026, 3, 2, hour: 10)
        event.calendar = store.defaultCalendarForNewEvents
        event.availability = .busy
        event.addAlarm(EKAlarm(relativeOffset: -300))

        var posted = 0
        let token = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: nil
        ) { _ in
            posted += 1
        }
        try! store.save(event, span: .thisEvent)
        precondition(posted == 1)
        NotificationCenter.default.removeObserver(token)

        let fetched = store.event(withIdentifier: event.eventIdentifier)
        precondition(fetched?.title == "Standup")
        precondition(store.calendarItem(withIdentifier: event.calendarItemIdentifier) != nil)
        let predicate = store.predicateForEvents(
            withStart: gmtDate(2026, 3, 1),
            end: gmtDate(2026, 3, 4),
            calendars: nil
        )
        precondition(store.events(matching: predicate).count == 1)

        let store2 = EKEventStore()
        precondition(store2.event(withIdentifier: event.eventIdentifier)?.title == "Standup")
        precondition(store2.event(withIdentifier: event.eventIdentifier)?.refresh() == true)

        let reminder = EKReminder(eventStore: store)
        reminder.title = "Ship EventKit"
        reminder.calendar = store.defaultCalendarForNewReminders()
        reminder.priority = Int(EKReminderPriority.high.rawValue)
        reminder.dueDateComponents = DateComponents(
            calendar: gmtCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 3,
            day: 3
        )
        try! store.save(reminder, commit: true)
        let reminderPred = store.predicateForReminders(in: nil)
        let fetchedReminders = await withCheckedContinuation { continuation in
            _ = store.fetchReminders(matching: reminderPred) { reminders in
                continuation.resume(returning: reminders)
            }
        }
        precondition(fetchedReminders?.contains { $0.title == "Ship EventKit" } == true)

        reminder.priority = 99
        requireThrown(.priorityIsInvalid) {
            try store.save(reminder, commit: true)
        }
        reminder.priority = 1

        let inverted = EKEvent(eventStore: store)
        inverted.calendar = store.defaultCalendarForNewEvents
        inverted.startDate = gmtDate(2026, 4, 2)
        inverted.endDate = gmtDate(2026, 4, 1)
        requireThrown(.datesInverted) {
            try store.save(inverted, span: .thisEvent)
        }

        let series = EKEvent(eventStore: store)
        series.title = "Daily standup"
        series.calendar = store.defaultCalendarForNewEvents
        series.startDate = gmtDate(2026, 5, 1)
        series.endDate = gmtDate(2026, 5, 1, hour: 10)
        series.addRecurrenceRule(
            EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: EKRecurrenceEnd(occurrenceCount: 5)
            )
        )
        try! store.save(series, span: .thisEvent)
        let seriesPred = store.predicateForEvents(
            withStart: gmtDate(2026, 5, 1),
            end: gmtDate(2026, 5, 10),
            calendars: nil
        )
        let occurrences = store.events(matching: seriesPred)
        precondition(occurrences.count == 5)

        let third = occurrences[2]
        try! store.remove(third, span: .thisEvent)
        let afterRemove = store.events(matching: seriesPred)
        precondition(afterRemove.count == 4)

        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let typed = EKEventStore.EventStoreChanged()
        precondition(EKEventStore.EventStoreChanged.name == .EKEventStoreChanged)
        await MainActor.run {
            precondition(
                EKEventStore.EventStoreChanged.makeMessage(
                    Notification(name: .EKEventStoreChanged)
                ) != nil
            )
            let note = EKEventStore.EventStoreChanged.makeNotification(typed)
            precondition(note.name == .EKEventStoreChanged)
        }
        let identifier: NotificationCenter.BaseMessageIdentifier<EKEventStore.EventStoreChanged> =
            .changed
        _ = identifier
        #endif

        let extra = EKCalendar(for: .event, eventStore: store)
        extra.title = "Work"
        extra.source = store.sources.first
        try! store.saveCalendar(extra, commit: true)
        precondition(store.calendar(withIdentifier: extra.calendarIdentifier)?.title == "Work")
        try! store.removeCalendar(extra, commit: true)
        precondition(store.calendar(withIdentifier: extra.calendarIdentifier) == nil)

        let writeStore = freshIsolatedStore()
        var writeReturned = false
        let writeOnly = await withCheckedContinuation { continuation in
            writeStore.requestWriteOnlyAccessToEvents { granted, error in
                continuation.resume(returning: (granted, error))
            }
            writeReturned = true
        }
        precondition(writeReturned)
        precondition(writeOnly.0 == true)
        precondition(EKEventStore.authorizationStatus(for: .event) == .writeOnly)
        let writeEvent = EKEvent(eventStore: writeStore)
        writeEvent.title = "Write only"
        writeEvent.startDate = gmtDate(2026, 6, 1)
        writeEvent.endDate = gmtDate(2026, 6, 1, hour: 10)
        writeEvent.calendar = writeStore.defaultCalendarForNewEvents
        try! writeStore.save(writeEvent, span: .thisEvent)
        let writePred = writeStore.predicateForEvents(
            withStart: gmtDate(2026, 6, 1),
            end: gmtDate(2026, 6, 2),
            calendars: nil
        )
        precondition(writeStore.events(matching: writePred).isEmpty)
    }

    private static func exerciseVirtualConference() async {
        let url = URL(string: "https://example.invalid/meet")!
        let urlDescriptor = EKVirtualConferenceURLDescriptor(title: "Join", url: url)
        let urlAlias = EKVirtualConferenceURLDescriptor(title: "Join", URL: url)
        precondition(urlDescriptor.url == urlAlias.url)

        let room = EKVirtualConferenceRoomTypeDescriptor(
            title: "Standup",
            identifier: "standup"
        )
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
        precondition(alias.title == "Standup")
        precondition(room.identifier == "standup")

        let provider = EKVirtualConferenceProvider()
        var roomsReturned = false
        var roomsReentrant = false
        let roomResult = await withCheckedContinuation { continuation in
            provider.fetchAvailableRoomTypes { rooms, error in
                roomsReentrant = !roomsReturned
                continuation.resume(returning: (rooms, error))
            }
            roomsReturned = true
        }
        precondition(!roomsReentrant)
        precondition(roomResult.0 == nil)
        requireEKError(roomResult.1, code: .osNotSupported)

        do {
            _ = try await provider.fetchVirtualConference(identifier: room.identifier)
            fatalError("fetchVirtualConference must fail closed")
        } catch {
            requireEKError(error, code: .osNotSupported)
        }
    }

    private static func exerciseNotificationName() {
        precondition(
            Notification.Name.EKEventStoreChanged.rawValue == "EKEventStoreChangedNotification"
        )
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        precondition(EKEventStore.EventStoreChanged.name.rawValue == "EKEventStoreChangedNotification")
        #endif
    }
}

await EventKitRuntime.main()
