import Foundation

/// A weekday plus an optional week-of-month index used by recurrence rules.
open class EKRecurrenceDayOfWeek: NSObject, NSCopying, NSSecureCoding {
    public let dayOfTheWeek: EKWeekday
    public let weekNumber: Int

    public static var supportsSecureCoding: Bool { true }

    public init(dayOfTheWeek: EKWeekday, weekNumber: Int) {
        self.dayOfTheWeek = dayOfTheWeek
        // RFC 5545 BYDAY ordinals are -53...53 (0 = every matching weekday).
        self.weekNumber = Self.clampedWeekNumber(weekNumber)
        super.init()
    }

    static func clampedWeekNumber(_ value: Int) -> Int {
        min(53, max(-53, value))
    }

    public convenience init(_ dayOfTheWeek: EKWeekday) {
        self.init(dayOfTheWeek: dayOfTheWeek, weekNumber: 0)
    }

    public convenience init(_ dayOfTheWeek: EKWeekday, weekNumber: Int) {
        self.init(dayOfTheWeek: dayOfTheWeek, weekNumber: weekNumber)
    }

    public required init?(coder: NSCoder) {
        let rawDay = coder.decodeInteger(forKey: "dayOfTheWeek")
        guard let day = EKWeekday(rawValue: rawDay) else { return nil }
        dayOfTheWeek = day
        weekNumber = coder.decodeInteger(forKey: "weekNumber")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(dayOfTheWeek.rawValue, forKey: "dayOfTheWeek")
        coder.encode(weekNumber, forKey: "weekNumber")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        EKRecurrenceDayOfWeek(dayOfTheWeek: dayOfTheWeek, weekNumber: weekNumber)
    }
}

/// Recurrence termination: either an end date or an occurrence count.
open class EKRecurrenceEnd: NSObject, NSCopying, NSSecureCoding {
    public let endDate: Date?
    public let occurrenceCount: Int

    public static var supportsSecureCoding: Bool { true }

    private init(storedEndDate: Date?, storedOccurrenceCount: Int) {
        endDate = storedEndDate
        occurrenceCount = storedOccurrenceCount
        super.init()
    }

    public convenience init(end endDate: Date) {
        self.init(storedEndDate: endDate, storedOccurrenceCount: 0)
    }

    public convenience init(endDate: Date) {
        self.init(end: endDate)
    }

    public convenience init(occurrenceCount: Int) {
        self.init(storedEndDate: nil, storedOccurrenceCount: max(0, occurrenceCount))
    }

    public required init?(coder: NSCoder) {
        if coder.containsValue(forKey: "endDate") {
            endDate = coder.decodeObject(of: NSDate.self, forKey: "endDate") as Date?
        } else {
            endDate = nil
        }
        occurrenceCount = coder.decodeInteger(forKey: "occurrenceCount")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        if let endDate {
            coder.encode(endDate as NSDate, forKey: "endDate")
        }
        coder.encode(occurrenceCount, forKey: "occurrenceCount")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        EKRecurrenceEnd(storedEndDate: endDate, storedOccurrenceCount: occurrenceCount)
    }
}

/// An RFC 5545-style recurrence rule attached to a calendar item.
open class EKRecurrenceRule: EKObject, NSCopying {
    public private(set) var frequency: EKRecurrenceFrequency
    public private(set) var interval: Int
    public private(set) var daysOfTheWeek: [EKRecurrenceDayOfWeek]?
    public private(set) var daysOfTheMonth: [NSNumber]?
    public private(set) var monthsOfTheYear: [NSNumber]?
    public private(set) var weeksOfTheYear: [NSNumber]?
    public private(set) var daysOfTheYear: [NSNumber]?
    public private(set) var setPositions: [NSNumber]?
    public var recurrenceEnd: EKRecurrenceEnd? {
        get { _recurrenceEnd }
        set {
            _recurrenceEnd = newValue.flatMap { $0.copy() as? EKRecurrenceEnd }
            markChanged()
        }
    }
    public var calendarIdentifier: String { "gregorian" }
    public var firstDayOfTheWeek: Int { _firstDayOfTheWeek }

    private var _recurrenceEnd: EKRecurrenceEnd?
    private var _committedRecurrenceEnd: EKRecurrenceEnd?
    private var _firstDayOfTheWeek: Int = 0

    public init(
        recurrenceWith type: EKRecurrenceFrequency,
        interval: Int,
        end: EKRecurrenceEnd?
    ) {
        frequency = type
        self.interval = max(1, interval)
        _recurrenceEnd = end.flatMap { $0.copy() as? EKRecurrenceEnd }
        super.init()
        finishInitialization()
    }

    public init(
        recurrenceWithFrequency type: EKRecurrenceFrequency,
        interval: Int,
        end: EKRecurrenceEnd?
    ) {
        frequency = type
        self.interval = max(1, interval)
        _recurrenceEnd = end.flatMap { $0.copy() as? EKRecurrenceEnd }
        super.init()
        finishInitialization()
    }

    public init(
        recurrenceWith type: EKRecurrenceFrequency,
        interval: Int,
        daysOfTheWeek days: [EKRecurrenceDayOfWeek]?,
        daysOfTheMonth monthDays: [NSNumber]?,
        monthsOfTheYear months: [NSNumber]?,
        weeksOfTheYear: [NSNumber]?,
        daysOfTheYear: [NSNumber]?,
        setPositions: [NSNumber]?,
        end: EKRecurrenceEnd?
    ) {
        frequency = type
        self.interval = max(1, interval)
        daysOfTheWeek = days
        daysOfTheMonth = monthDays
        monthsOfTheYear = months
        self.weeksOfTheYear = weeksOfTheYear
        self.daysOfTheYear = daysOfTheYear
        self.setPositions = setPositions
        _recurrenceEnd = end.flatMap { $0.copy() as? EKRecurrenceEnd }
        super.init()
        finishInitialization()
    }

    public init(
        recurrenceWithFrequency type: EKRecurrenceFrequency,
        interval: Int,
        daysOfTheWeek days: [EKRecurrenceDayOfWeek]?,
        daysOfTheMonth monthDays: [NSNumber]?,
        monthsOfTheYear months: [NSNumber]?,
        weeksOfTheYear: [NSNumber]?,
        daysOfTheYear: [NSNumber]?,
        setPositions: [NSNumber]?,
        end: EKRecurrenceEnd?
    ) {
        frequency = type
        self.interval = max(1, interval)
        daysOfTheWeek = days
        daysOfTheMonth = monthDays
        monthsOfTheYear = months
        self.weeksOfTheYear = weeksOfTheYear
        self.daysOfTheYear = daysOfTheYear
        self.setPositions = setPositions
        _recurrenceEnd = end.flatMap { $0.copy() as? EKRecurrenceEnd }
        super.init()
        finishInitialization()
    }

    override func captureCommittedState() {
        _committedRecurrenceEnd = _recurrenceEnd.flatMap { $0.copy() as? EKRecurrenceEnd }
    }

    override func restoreCommittedState() {
        _recurrenceEnd = _committedRecurrenceEnd.flatMap { $0.copy() as? EKRecurrenceEnd }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: daysOfTheMonth,
            monthsOfTheYear: monthsOfTheYear,
            weeksOfTheYear: weeksOfTheYear,
            daysOfTheYear: daysOfTheYear,
            setPositions: setPositions,
            end: recurrenceEnd
        )
        copy._firstDayOfTheWeek = _firstDayOfTheWeek
        return copy
    }

    func applyFirstDayOfTheWeek(_ value: Int) {
        _firstDayOfTheWeek = value
    }

    func persistRecord() -> EKRecurrenceRecord {
        EKRecurrenceRecord(
            frequency: frequency.rawValue,
            interval: interval,
            daysOfTheWeek: (daysOfTheWeek ?? []).map { [$0.dayOfTheWeek.rawValue, $0.weekNumber] },
            daysOfTheMonth: (daysOfTheMonth ?? []).map(\.intValue),
            monthsOfTheYear: (monthsOfTheYear ?? []).map(\.intValue),
            weeksOfTheYear: (weeksOfTheYear ?? []).map(\.intValue),
            daysOfTheYear: (daysOfTheYear ?? []).map(\.intValue),
            setPositions: (setPositions ?? []).map(\.intValue),
            endDate: recurrenceEnd?.endDate?.timeIntervalSince1970,
            occurrenceCount: recurrenceEnd?.occurrenceCount ?? 0,
            firstDayOfTheWeek: firstDayOfTheWeek
        )
    }

    static func fromRecord(_ record: EKRecurrenceRecord) -> EKRecurrenceRule {
        let days: [EKRecurrenceDayOfWeek]? = record.daysOfTheWeek.isEmpty ? nil : record.daysOfTheWeek.compactMap { pair in
            guard pair.count >= 2, let weekday = EKWeekday(rawValue: pair[0]) else { return nil }
            return EKRecurrenceDayOfWeek(dayOfTheWeek: weekday, weekNumber: pair[1])
        }
        let end: EKRecurrenceEnd?
        if let endDate = record.endDate {
            end = EKRecurrenceEnd(end: Date(timeIntervalSince1970: endDate))
        } else if record.occurrenceCount > 0 {
            end = EKRecurrenceEnd(occurrenceCount: record.occurrenceCount)
        } else {
            end = nil
        }
        let rule = EKRecurrenceRule(
            recurrenceWith: EKRecurrenceFrequency(rawValue: record.frequency) ?? .daily,
            interval: record.interval,
            daysOfTheWeek: days,
            daysOfTheMonth: record.daysOfTheMonth.isEmpty ? nil : record.daysOfTheMonth.map { NSNumber(value: $0) },
            monthsOfTheYear: record.monthsOfTheYear.isEmpty ? nil : record.monthsOfTheYear.map { NSNumber(value: $0) },
            weeksOfTheYear: record.weeksOfTheYear.isEmpty ? nil : record.weeksOfTheYear.map { NSNumber(value: $0) },
            daysOfTheYear: record.daysOfTheYear.isEmpty ? nil : record.daysOfTheYear.map { NSNumber(value: $0) },
            setPositions: record.setPositions.isEmpty ? nil : record.setPositions.map { NSNumber(value: $0) },
            end: end
        )
        rule.applyFirstDayOfTheWeek(record.firstDayOfTheWeek)
        return rule
    }
}
