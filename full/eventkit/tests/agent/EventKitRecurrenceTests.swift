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
