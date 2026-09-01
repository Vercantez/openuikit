import EventKit
import Foundation

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
        exerciseTypesAndErrors()
        exerciseObjectModel()
        exerciseRecurrenceCoding()
        exercisePredicates()
        await exerciseFailClosedStore()
        await exerciseVirtualConference()
        await MainActor.run {
            exerciseTypedNotification()
        }
        print("EVENTKIT_AGENT_RUNTIME_OK")
    }

    private static func exerciseTypesAndErrors() {
        precondition(EKAuthorizationStatus.authorized == .fullAccess)
        precondition(EKAuthorizationStatus.authorized.rawValue == 3)
        precondition(EKAuthorizationStatus(rawValue: 2) == .denied)
        precondition(EKWeekday.EKMonday == .monday)
        precondition(EKWeekday.sunday.rawValue == 1)
        precondition(EKWeekday.saturday.rawValue == 7)
        precondition(EKReminderPriority.high.rawValue == 1)
        precondition(EKReminderPriority.medium.rawValue == 5)
        precondition(EKReminderPriority.low.rawValue == 9)
        precondition(EKEventAvailability.notSupported.rawValue == -1)
        precondition(EKEntityType.event.rawValue == 0)
        precondition(EKEntityMask.event.rawValue == 1)
        precondition(EKEntityMask.reminder.rawValue == 2)

        var mask: EKEntityMask = [.event]
        precondition(mask.contains(.event))
        precondition(!mask.contains(.reminder))
        mask.insert(.reminder)
        precondition(mask.contains(.reminder))
        precondition(mask.union(.event) == [.event, .reminder])
        precondition(mask.intersection(.event) == .event)
        _ = mask.symmetricDifference(.reminder)
        mask.formUnion(.event)
        mask.formIntersection([.event, .reminder])
        mask.formSymmetricDifference(.event)
        precondition(!mask.isEmpty)
        precondition(mask.isDisjoint(with: []))
        precondition(EKEntityMask().isEmpty)
        precondition(EKEntityMask([.event, .reminder]).isSuperset(of: .event))
        precondition(EKEntityMask.event.isSubset(of: [.event, .reminder]))
        precondition(EKEntityMask.event.isStrictSubset(of: [.event, .reminder]))
        precondition(EKEntityMask([.event, .reminder]).isStrictSuperset(of: .event))
        var subtracted = EKEntityMask([.event, .reminder])
        subtracted.subtract(.event)
        precondition(subtracted == .reminder)
        precondition(EKEntityMask([.event, .reminder]).subtracting(.reminder) == .event)
        _ = EKCalendarEventAvailabilityMask(arrayLiteral: .busy, .free)
        precondition(EKCalendarEventAvailabilityMask.busy != .free)

        let hashed: Set<EKAuthorizationStatus> = [.denied, .restricted, .fullAccess]
        precondition(hashed.contains(.denied))
        precondition(EKAlarmProximity.none.hashValue == EKAlarmProximity.none.hashValue)
        var hasher = Hasher()
        EKSpan.thisEvent.hash(into: &hasher)
        _ = hasher.finalize()

        precondition(EKErrorDomain == "EKErrorDomain")
        precondition(EKError.last.rawValue == 37)
        precondition(EKError.eventNotMutable.rawValue == 0)
        precondition(EKError.osNotSupported.rawValue == 29)
        precondition(EKError.eventStoreNotAuthorized.rawValue == 28)
        precondition(EKError.noCalendar.rawValue == 36)

        let empty = EKError(.osNotSupported)
        precondition(empty.userInfo.isEmpty)
        precondition(empty.errorUserInfo.isEmpty)
        precondition(empty.hashValue == EKError(.osNotSupported).hashValue)
        precondition(empty == EKError(.osNotSupported))
        precondition(empty != EKError(.eventStoreNotAuthorized))
        let tagged = EKError(.osNotSupported, userInfo: ["sentinel": "value"])
        precondition(tagged.userInfo["sentinel"] as? String == "value")
        precondition(tagged != empty)
        precondition(tagged.hashValue == empty.hashValue)
        precondition(!empty.localizedDescription.isEmpty)
        precondition(EKError.Code.osNotSupported ~= empty)

        let codes: [EKError.Code] = [
            .eventNotMutable, .noStartDate, .noEndDate, .datesInverted,
            .internalFailure, .calendarReadOnly, .durationGreaterThanRecurrence,
            .alarmGreaterThanRecurrence, .startDateTooFarInFuture,
            .startDateCollidesWithOtherOccurrence, .objectBelongsToDifferentStore,
            .invitesCannotBeMoved, .invalidSpan, .calendarHasNoSource,
            .calendarSourceCannotBeModified, .calendarIsImmutable,
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
        precondition(Set(codes.map(\.rawValue)).count == codes.count)
        precondition(EKError.Code(rawValue: 4) == .internalFailure)
        _ = [EKAlarmType.display, .audio, .procedure, .email]
        _ = [EKCalendarType.local, .calDAV, .exchange, .subscription, .birthday]
        _ = [EKSourceType.local, .exchange, .calDAV, .mobileMe, .subscribed, .birthdays]
        _ = [EKParticipantRole.unknown, .required, .optional, .chair, .nonParticipant]
        _ = [
            EKParticipantStatus.unknown, .pending, .accepted, .declined, .tentative,
            .delegated, .completed, .inProcess,
        ]
        _ = [EKParticipantType.unknown, .person, .room, .resource, .group]
        _ = [
            EKParticipantScheduleStatus.none, .pending, .sent, .delivered,
            .recipientNotRecognized, .noPrivileges, .deliveryFailed, .cannotDeliver,
            .recipientNotAllowed,
        ]
        _ = [EKEventStatus.none, .confirmed, .tentative, .canceled]
        _ = [EKRecurrenceFrequency.daily, .weekly, .monthly, .yearly]
    }

    private static func exerciseObjectModel() {
        let store = EKEventStore()
        precondition(!store.eventStoreIdentifier.isEmpty)
        precondition(store.sources.isEmpty)
        precondition(store.delegateSources.isEmpty)
        precondition(store.defaultCalendarForNewEvents == nil)
        precondition(store.defaultCalendarForNewReminders() == nil)

        let event = EKEvent(eventStore: store)
        precondition(event.isNew)
        event.title = "Planning"
        event.notes = "Bring notes"
        event.location = "Library"
        event.url = URL(string: "https://example.invalid/event")
        event.timeZone = TimeZone(secondsFromGMT: 0)
        event.startDate = Date(timeIntervalSince1970: 1_700_000_000)
        event.endDate = Date(timeIntervalSince1970: 1_700_003_600)
        event.isAllDay = false
        event.availability = .busy
        precondition(event.hasChanges)
        precondition(event.hasNotes)
        precondition(event.eventIdentifier != nil)
        precondition(!event.calendarItemIdentifier.isEmpty)
        precondition(event.status == .none)
        precondition(event.birthdayPersonID == -1)
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

        let reminder = EKReminder(eventStore: store)
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
        precondition(source.calendars(for: .event).isEmpty)
        calendar.source = source

        let participant = EKParticipant()
        precondition(participant.participantStatus == .unknown)
        precondition(!participant.isCurrentUser)
        precondition(participant.abRecord(with: NSObject()) == nil)
        precondition(!participant.contactPredicate.evaluate(with: participant))
        _ = participant.copy()

        event.reset()
        _ = EKObject().hasChanges
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
        weekly.recurrenceEnd = endByDate

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

        let item = EKCalendarItem()
        item.addRecurrenceRule(weekly)
        precondition(item.hasRecurrenceRules)
        item.removeRecurrenceRule(weekly)
        precondition(!item.hasRecurrenceRules)

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

        let reminderCalendar = EKCalendar(for: .reminder, eventStore: store)
        let incomplete = EKReminder(eventStore: store)
        incomplete.calendar = reminderCalendar
        incomplete.dueDateComponents = DateComponents(
            calendar: Calendar.current,
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

        let allReminders = store.predicateForReminders(in: nil)
        precondition(allReminders.evaluate(with: incomplete))
    }

    private static func exerciseFailClosedStore() async {
        let store = EKEventStore()
        precondition(EKEventStore.authorizationStatus(for: .event) == .denied)
        precondition(EKEventStore.authorizationStatus(for: .reminder) == .denied)

        do {
            _ = try await store.requestAccess(to: .event)
            fatalError("requestAccess must fail closed")
        } catch {
            requireEKError(error, code: .osNotSupported)
        }

        let fullEvents = await withCheckedContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                continuation.resume(returning: (granted, error))
            }
        }
        precondition(fullEvents.0 == false)
        requireEKError(fullEvents.1, code: .osNotSupported)

        let fullReminders = await withCheckedContinuation { continuation in
            store.requestFullAccessToReminders { granted, error in
                continuation.resume(returning: (granted, error))
            }
        }
        precondition(fullReminders.0 == false)
        requireEKError(fullReminders.1, code: .osNotSupported)

        let writeOnly = await withCheckedContinuation { continuation in
            store.requestWriteOnlyAccessToEvents { granted, error in
                continuation.resume(returning: (granted, error))
            }
        }
        precondition(writeOnly.0 == false)
        requireEKError(writeOnly.1, code: .osNotSupported)

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

        let fetchDone = await withCheckedContinuation { continuation in
            let token = store.fetchReminders(matching: store.predicateForReminders(in: nil)) { reminders in
                continuation.resume(returning: reminders)
            }
            store.cancelFetchRequest(token)
        }
        precondition(fetchDone == nil)

        store.refreshSourcesIfNecessary()
        store.reset()
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
        let roomResult = await withCheckedContinuation { continuation in
            provider.fetchAvailableRoomTypes { rooms, error in
                continuation.resume(returning: (rooms, error))
            }
        }
        precondition(roomResult.0 == nil)
        requireEKError(roomResult.1, code: .osNotSupported)

        do {
            _ = try await provider.fetchVirtualConference(identifier: room.identifier)
            fatalError("fetchVirtualConference must fail closed")
        } catch {
            requireEKError(error, code: .osNotSupported)
        }
    }

    @MainActor
    private static func exerciseTypedNotification() {
        precondition(Notification.Name.EKEventStoreChanged.rawValue == "EKEventStoreChangedNotification")
        precondition(EKEventStore.EventStoreChanged.name == .EKEventStoreChanged)
        let message = EKEventStore.EventStoreChanged()
        let notification = EKEventStore.EventStoreChanged.makeNotification(message)
        precondition(EKEventStore.EventStoreChanged.makeMessage(notification) != nil)
        let unrelated = Notification(name: Notification.Name("other"))
        precondition(EKEventStore.EventStoreChanged.makeMessage(unrelated) == nil)
    }
}

await EventKitRuntime.main()
