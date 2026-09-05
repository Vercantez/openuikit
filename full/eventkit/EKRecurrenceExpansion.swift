import Foundation

/// Expands `EKRecurrenceRule` over Foundation `Calendar`.
///
/// DTSTART (`seriesStart`) is always the first occurrence. Later dates follow
/// RFC 5545 `FREQ`/`INTERVAL`/`BYDAY`/`BYMONTHDAY`/`BYMONTH`/`BYYEARDAY`/
/// `BYWEEKNO`/`BYSETPOS`/`UNTIL`/`COUNT`. `recurrenceEnd.endDate` is inclusive.
///
/// Documented samples (Gregorian, `TimeZone(secondsFromGMT: 0)`, start 09:00):
/// - daily interval 1 COUNT 3 from 2026-01-01 → 1, 2, 3 Jan
/// - daily interval 2 COUNT 3 from 2026-01-01 → 1, 3, 5 Jan
/// - weekly Monday COUNT 4 from 2026-01-05 (Monday) → 5, 12, 19, 26 Jan
/// - weekly MO,WE,FR COUNT 6 from 2026-01-05 → 5, 7, 9, 12, 14, 16 Jan
/// - monthly BYMONTHDAY=15 COUNT 3 from 2026-01-15 → 15 Jan, 15 Feb, 15 Mar
/// - monthly BYDAY=-1FR COUNT 3 from 2026-01-30 → 30 Jan, 27 Feb, 27 Mar
/// - yearly BYMONTH=1 BYMONTHDAY=1 COUNT 3 from 2026-01-01 → 2026, 2027, 2028
@_spi(OpenUIKitHost)
public enum EKRecurrenceExpansion {
    static let occurrenceCap = 50_000

    public static func occurrenceStarts(
        rule: EKRecurrenceRule,
        seriesStart: Date,
        rangeStart: Date,
        rangeEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        let until = rule.recurrenceEnd?.endDate ?? Date.distantFuture
        let maxCount: Int = {
            let count = rule.recurrenceEnd?.occurrenceCount ?? 0
            return count > 0 ? count : occurrenceCap
        }()

        var matches: [Date] = []
        matches.append(seriesStart)

        switch rule.frequency {
        case .daily:
            appendDaily(
                rule: rule,
                seriesStart: seriesStart,
                until: until,
                maxCount: maxCount,
                calendar: calendar,
                into: &matches
            )
        case .weekly:
            appendWeekly(
                rule: rule,
                seriesStart: seriesStart,
                until: until,
                maxCount: maxCount,
                calendar: calendar,
                into: &matches
            )
        case .monthly:
            appendMonthly(
                rule: rule,
                seriesStart: seriesStart,
                until: until,
                maxCount: maxCount,
                calendar: calendar,
                into: &matches
            )
        case .yearly:
            appendYearly(
                rule: rule,
                seriesStart: seriesStart,
                until: until,
                maxCount: maxCount,
                calendar: calendar,
                into: &matches
            )
        }

        var seen = Set<TimeInterval>()
        var unique: [Date] = []
        for date in matches {
            let key = date.timeIntervalSince1970
            if seen.contains(key) { continue }
            seen.insert(key)
            unique.append(date)
        }
        unique.sort()
        if unique.count > maxCount {
            unique = Array(unique.prefix(maxCount))
        }
        return unique.filter { date in
            date <= until && date < rangeEnd && date >= min(seriesStart, rangeStart)
                && !(date < rangeStart)
        }
    }

    private static func appendDaily(
        rule: EKRecurrenceRule,
        seriesStart: Date,
        until: Date,
        maxCount: Int,
        calendar: Calendar,
        into matches: inout [Date]
    ) {
        var cursor = seriesStart
        var count = 1
        while count < maxCount {
            guard let next = calendar.date(byAdding: .day, value: rule.interval, to: cursor) else {
                break
            }
            if next > until { break }
            matches.append(next)
            cursor = next
            count += 1
        }
    }

    private static func appendWeekly(
        rule: EKRecurrenceRule,
        seriesStart: Date,
        until: Date,
        maxCount: Int,
        calendar: Calendar,
        into matches: inout [Date]
    ) {
        let weekdays = weekdaySet(rule, seriesStart: seriesStart, calendar: calendar)
        var weekStart = startOfWeek(containing: seriesStart, calendar: calendar, rule: rule)
        var count = 1
        var weekIndex = 0
        while count < maxCount {
            if weekIndex > 0, weekIndex % rule.interval != 0 {
                guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                    break
                }
                weekStart = nextWeek
                weekIndex += 1
                if weekStart > until { break }
                continue
            }
            var weekDates: [Date] = []
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                    continue
                }
                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: day))
                if let weekday, weekdays.contains(weekday) {
                    weekDates.append(stamp(day, from: seriesStart, calendar: calendar))
                }
            }
            weekDates = applySetPositions(weekDates, rule.setPositions)
            for date in weekDates where date > seriesStart {
                if date > until { return }
                matches.append(date)
                count += 1
                if count >= maxCount { return }
            }
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                break
            }
            weekStart = nextWeek
            weekIndex += 1
            if weekStart > until { break }
        }
    }

    private static func appendMonthly(
        rule: EKRecurrenceRule,
        seriesStart: Date,
        until: Date,
        maxCount: Int,
        calendar: Calendar,
        into matches: inout [Date]
    ) {
        let anchor = monthAnchor(seriesStart, calendar: calendar)
        var count = 1
        for monthIndex in 0..<2_400 {
            guard let cursor = calendar.date(
                byAdding: .month,
                value: rule.interval * monthIndex,
                to: anchor
            ) else {
                break
            }
            if cursor > until { break }
            let candidates = monthCandidates(
                rule: rule,
                in: cursor,
                seriesStart: seriesStart,
                calendar: calendar
            ).filter { $0 > seriesStart && $0 <= until }
            for date in candidates {
                matches.append(date)
                count += 1
                if count >= maxCount { return }
            }
        }
    }

    private static func appendYearly(
        rule: EKRecurrenceRule,
        seriesStart: Date,
        until: Date,
        maxCount: Int,
        calendar: Calendar,
        into matches: inout [Date]
    ) {
        let anchor = yearAnchor(seriesStart, calendar: calendar)
        var count = 1
        for yearIndex in 0..<400 {
            guard let cursor = calendar.date(
                byAdding: .year,
                value: rule.interval * yearIndex,
                to: anchor
            ) else {
                break
            }
            let candidates = yearCandidates(
                rule: rule,
                in: cursor,
                seriesStart: seriesStart,
                calendar: calendar
            ).filter { $0 > seriesStart && $0 <= until }
            if cursor > until && candidates.isEmpty { break }
            for date in candidates {
                matches.append(date)
                count += 1
                if count >= maxCount { return }
            }
        }
    }

    private static func monthAnchor(_ date: Date, calendar: Calendar) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: date)
        comps.day = 1
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }

    private static func yearAnchor(_ date: Date, calendar: Calendar) -> Date {
        var comps = calendar.dateComponents([.year], from: date)
        comps.month = 1
        comps.day = 1
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }

    private static func monthCandidates(
        rule: EKRecurrenceRule,
        in monthDate: Date,
        seriesStart: Date,
        calendar: Calendar
    ) -> [Date] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthDate) else {
            return []
        }
        var dates: [Date] = []
        if let monthDays = rule.daysOfTheMonth, !monthDays.isEmpty {
            for number in monthDays {
                let raw = number.intValue
                let day: Int
                if raw > 0 {
                    day = raw
                } else {
                    day = dayRange.count + raw + 1
                }
                if dayRange.contains(day) {
                    dates.append(stamp(day: day, of: monthDate, from: seriesStart, calendar: calendar))
                }
            }
        } else if let days = rule.daysOfTheWeek, !days.isEmpty {
            dates = weekdays(
                days,
                inMonthOf: monthDate,
                seriesStart: seriesStart,
                calendar: calendar
            )
        } else {
            let startDay = calendar.component(.day, from: seriesStart)
            let day = min(startDay, dayRange.count)
            dates.append(stamp(day: day, of: monthDate, from: seriesStart, calendar: calendar))
        }
        if let months = rule.monthsOfTheYear, !months.isEmpty {
            let month = calendar.component(.month, from: monthDate)
            dates = dates.filter { _ in months.contains { $0.intValue == month } }
        }
        dates.sort()
        return applySetPositions(dates, rule.setPositions)
    }

    private static func yearCandidates(
        rule: EKRecurrenceRule,
        in yearDate: Date,
        seriesStart: Date,
        calendar: Calendar
    ) -> [Date] {
        var dates: [Date] = []
        if let yearDays = rule.daysOfTheYear, !yearDays.isEmpty {
            guard let dayRange = calendar.range(of: .day, in: .year, for: yearDate) else {
                return []
            }
            for number in yearDays {
                let raw = number.intValue
                let day: Int
                if raw > 0 {
                    day = raw
                } else {
                    day = dayRange.count + raw + 1
                }
                if dayRange.contains(day) {
                    var comps = calendar.dateComponents([.year], from: yearDate)
                    comps.day = day
                    if let date = calendar.date(from: comps) {
                        dates.append(stamp(date, from: seriesStart, calendar: calendar))
                    }
                }
            }
        } else if let weeks = rule.weeksOfTheYear, !weeks.isEmpty {
            for number in weeks {
                var comps = calendar.dateComponents([.year], from: yearDate)
                comps.weekOfYear = number.intValue
                comps.weekday = calendar.component(.weekday, from: seriesStart)
                if let date = calendar.date(from: comps) {
                    dates.append(stamp(date, from: seriesStart, calendar: calendar))
                }
            }
        } else if let days = rule.daysOfTheWeek, !days.isEmpty, rule.monthsOfTheYear != nil {
            let months = (rule.monthsOfTheYear ?? []).map(\.intValue)
            for month in months {
                var comps = calendar.dateComponents([.year], from: yearDate)
                comps.month = month
                comps.day = 1
                if let monthDate = calendar.date(from: comps) {
                    dates.append(contentsOf: weekdays(
                        days,
                        inMonthOf: monthDate,
                        seriesStart: seriesStart,
                        calendar: calendar
                    ))
                }
            }
        } else if let monthDays = rule.daysOfTheMonth, !monthDays.isEmpty {
            let months = (rule.monthsOfTheYear ?? [NSNumber(value: calendar.component(.month, from: seriesStart))])
                .map(\.intValue)
            for month in months {
                var comps = calendar.dateComponents([.year], from: yearDate)
                comps.month = month
                comps.day = 1
                if let monthDate = calendar.date(from: comps) {
                    dates.append(contentsOf: monthCandidates(
                        rule: rule,
                        in: monthDate,
                        seriesStart: seriesStart,
                        calendar: calendar
                    ))
                }
            }
            dates.sort()
            return applySetPositions(dates, rule.setPositions)
        } else if let months = rule.monthsOfTheYear, !months.isEmpty {
            let day = calendar.component(.day, from: seriesStart)
            for month in months.map(\.intValue) {
                var comps = calendar.dateComponents([.year], from: yearDate)
                comps.month = month
                comps.day = 1
                if let monthDate = calendar.date(from: comps),
                   let range = calendar.range(of: .day, in: .month, for: monthDate)
                {
                    dates.append(stamp(
                        day: min(day, range.count),
                        of: monthDate,
                        from: seriesStart,
                        calendar: calendar
                    ))
                }
            }
        } else {
            var comps = calendar.dateComponents([.month, .day], from: seriesStart)
            comps.year = calendar.component(.year, from: yearDate)
            if let date = calendar.date(from: comps) {
                dates.append(stamp(date, from: seriesStart, calendar: calendar))
            }
        }
        if let months = rule.monthsOfTheYear, !months.isEmpty, rule.daysOfTheMonth == nil {
            let allowed = Set(months.map(\.intValue))
            dates = dates.filter { allowed.contains(calendar.component(.month, from: $0)) }
        }
        dates.sort()
        return applySetPositions(dates, rule.setPositions)
    }

    private static func weekdays(
        _ days: [EKRecurrenceDayOfWeek],
        inMonthOf monthDate: Date,
        seriesStart: Date,
        calendar: Calendar
    ) -> [Date] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthDate) else {
            return []
        }
        var grouped: [EKWeekday: [Date]] = [:]
        for day in dayRange {
            let stamped = stamp(day: day, of: monthDate, from: seriesStart, calendar: calendar)
            guard let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: stamped)) else {
                continue
            }
            grouped[weekday, default: []].append(stamped)
        }
        var result: [Date] = []
        for day in days {
            let list = grouped[day.dayOfTheWeek] ?? []
            if day.weekNumber == 0 {
                result.append(contentsOf: list)
            } else if day.weekNumber > 0, day.weekNumber <= list.count {
                result.append(list[day.weekNumber - 1])
            } else if day.weekNumber < 0 {
                let index = list.count + day.weekNumber
                if index >= 0 && index < list.count {
                    result.append(list[index])
                }
            }
        }
        result.sort()
        return result
    }

    private static func weekdaySet(
        _ rule: EKRecurrenceRule,
        seriesStart: Date,
        calendar: Calendar
    ) -> Set<EKWeekday> {
        if let days = rule.daysOfTheWeek, !days.isEmpty {
            return Set(days.map(\.dayOfTheWeek))
        }
        if let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: seriesStart)) {
            return [weekday]
        }
        return []
    }

    private static func startOfWeek(
        containing date: Date,
        calendar: Calendar,
        rule: EKRecurrenceRule
    ) -> Date {
        var cal = calendar
        if rule.firstDayOfTheWeek >= 1 && rule.firstDayOfTheWeek <= 7 {
            cal.firstWeekday = rule.firstDayOfTheWeek
        }
        let weekday = cal.component(.weekday, from: date)
        let delta = (weekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -delta, to: startOfDay(date, calendar: cal)) ?? date
    }

    private static func startOfDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    private static func stamp(
        _ day: Date,
        from seriesStart: Date,
        calendar: Calendar
    ) -> Date {
        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        let time = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: seriesStart)
        comps.hour = time.hour
        comps.minute = time.minute
        comps.second = time.second
        comps.nanosecond = time.nanosecond
        return calendar.date(from: comps) ?? day
    }

    private static func stamp(
        day: Int,
        of monthDate: Date,
        from seriesStart: Date,
        calendar: Calendar
    ) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: monthDate)
        comps.day = day
        let time = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: seriesStart)
        comps.hour = time.hour
        comps.minute = time.minute
        comps.second = time.second
        comps.nanosecond = time.nanosecond
        return calendar.date(from: comps) ?? monthDate
    }

    private static func applySetPositions(_ dates: [Date], _ positions: [NSNumber]?) -> [Date] {
        guard let positions, !positions.isEmpty else { return dates }
        var picked: [Date] = []
        for number in positions {
            let raw = number.intValue
            if raw > 0, raw <= dates.count {
                picked.append(dates[raw - 1])
            } else if raw < 0 {
                let index = dates.count + raw
                if index >= 0 && index < dates.count {
                    picked.append(dates[index])
                }
            }
        }
        picked.sort()
        return picked
    }
}
