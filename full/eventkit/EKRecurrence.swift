import Foundation

/// A weekday plus an optional week-of-month index used by recurrence rules.
open class EKRecurrenceDayOfWeek: NSObject, NSCopying, NSSecureCoding {
    public let dayOfTheWeek: EKWeekday
    public let weekNumber: Int

    public static var supportsSecureCoding: Bool { true }

    public init(dayOfTheWeek: EKWeekday, weekNumber: Int) {
        self.dayOfTheWeek = dayOfTheWeek
        self.weekNumber = weekNumber
        super.init()
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
        self.init(storedEndDate: nil, storedOccurrenceCount: occurrenceCount)
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
}
