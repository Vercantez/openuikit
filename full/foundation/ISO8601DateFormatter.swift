// Portable ISO8601DateFormatter for Linux-hosted Mach-O guests.
//
// Format-option bits, separators, fractional seconds and offsets were read
// off Apple Foundation on macOS 26.1 / 2026-09-05
// (full/foundation/tests/foundation-iso8601-date-formatter-apple-2026-09-05.txt).
// No ICU: the grammar is numeric.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif

open class ISO8601DateFormatter {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // Raw values: Apple ISO8601DateFormatter.Options on 2026-09-05.
        public static let withYear = Options(rawValue: 1)
        public static let withMonth = Options(rawValue: 2)
        public static let withWeekOfYear = Options(rawValue: 4)
        public static let withDay = Options(rawValue: 16)
        public static let withTime = Options(rawValue: 32)
        public static let withTimeZone = Options(rawValue: 64)
        public static let withSpaceBetweenDateAndTime = Options(rawValue: 128)
        public static let withDashSeparatorInDate = Options(rawValue: 256)
        public static let withColonSeparatorInTime = Options(rawValue: 512)
        public static let withColonSeparatorInTimeZone = Options(rawValue: 1024)
        public static let withFractionalSeconds = Options(rawValue: 2048)
        public static let withFullDate = Options(rawValue: 275)
        public static let withFullTime = Options(rawValue: 1632)
        public static let withInternetDateTime = Options(rawValue: 1907)
    }

    open var timeZone: TimeZone! = TimeZone(secondsFromGMT: 0)
    open var formatOptions: Options = .withInternetDateTime

    public init() {}

    open func string(from date: Date) -> String {
        Self.string(from: date, timeZone: timeZone ?? TimeZone(secondsFromGMT: 0)!, formatOptions: formatOptions)
    }

    open func date(from string: String) -> Date? {
        _parse(string, options: formatOptions)
    }

    open class func string(
        from date: Date,
        timeZone: TimeZone,
        formatOptions: Options
    ) -> String {
        if formatOptions.isEmpty { return "" }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond,
             .weekOfYear, .yearForWeekOfYear],
            from: date
        )
        let dash = formatOptions.contains(.withDashSeparatorInDate)
        let colonTime = formatOptions.contains(.withColonSeparatorInTime)
        let colonZone = formatOptions.contains(.withColonSeparatorInTimeZone)
        var output = ""

        let hasDate = formatOptions.contains(.withYear)
            || formatOptions.contains(.withMonth)
            || formatOptions.contains(.withDay)
            || formatOptions.contains(.withWeekOfYear)
        let hasTime = formatOptions.contains(.withTime)

        if formatOptions.contains(.withWeekOfYear) {
            let year = components.yearForWeekOfYear ?? components.year ?? 0
            let week = components.weekOfYear ?? 0
            output += _pad(year, 4)
            if dash { output += "-" }
            output += "W" + _pad(week, 2)
        } else if hasDate {
            if formatOptions.contains(.withYear) {
                output += _pad(components.year ?? 0, 4)
            }
            if formatOptions.contains(.withMonth) {
                if dash && formatOptions.contains(.withYear) { output += "-" }
                output += _pad(components.month ?? 0, 2)
            }
            if formatOptions.contains(.withDay) {
                if dash && (formatOptions.contains(.withYear) || formatOptions.contains(.withMonth)) {
                    output += "-"
                }
                output += _pad(components.day ?? 0, 2)
            }
        }

        if hasTime {
            if hasDate {
                output += formatOptions.contains(.withSpaceBetweenDateAndTime) ? " " : "T"
            }
            output += _pad(components.hour ?? 0, 2)
            if colonTime { output += ":" }
            output += _pad(components.minute ?? 0, 2)
            if colonTime { output += ":" }
            output += _pad(components.second ?? 0, 2)
            if formatOptions.contains(.withFractionalSeconds) {
                let nanos = components.nanosecond ?? 0
                let millis = nanos / 1_000_000
                output += "." + _pad(millis, 3)
            }
        }

        if formatOptions.contains(.withTimeZone) {
            let seconds = timeZone.secondsFromGMT(for: date)
            if seconds == 0 {
                output += "Z"
            } else {
                let sign = seconds < 0 ? "-" : "+"
                let magnitude = abs(seconds)
                let hours = magnitude / 3600
                let minutes = (magnitude % 3600) / 60
                output += sign + _pad(hours, 2)
                if colonZone { output += ":" }
                output += _pad(minutes, 2)
            }
        }
        return output
    }

    private func _parse(_ string: String, options: Options) -> Date? {
        if options.contains(.withInternetDateTime) || options.contains(.withFullDate) {
            return _parseISO(string, requireTime: options.contains(.withTime) || options.contains(.withFullTime) || options.contains(.withInternetDateTime))
        }
        return _parseISO(string, requireTime: options.contains(.withTime))
    }

    private func _parseISO(_ string: String, requireTime: Bool) -> Date? {
        let characters = Array(string)
        var index = 0
        func take(_ count: Int) -> String? {
            guard index + count <= characters.count else { return nil }
            let slice = String(characters[index..<(index + count)])
            index += count
            return slice
        }
        func peek() -> Character? {
            index < characters.count ? characters[index] : nil
        }
        func eat(_ expected: Character) -> Bool {
            guard peek() == expected else { return false }
            index += 1
            return true
        }

        guard let yearText = take(4), let year = Int(yearText) else { return nil }
        var month = 1
        var day = 1
        var hour = 0
        var minute = 0
        var second = 0
        var nanosecond = 0
        var zoneSeconds = 0

        if eat("-") {
            guard let monthText = take(2), let parsedMonth = Int(monthText) else { return nil }
            month = parsedMonth
            guard eat("-") else { return nil }
            guard let dayText = take(2), let parsedDay = Int(dayText) else { return nil }
            day = parsedDay
        } else if peek()?.isNumber == true {
            guard let monthText = take(2), let parsedMonth = Int(monthText) else { return nil }
            month = parsedMonth
            guard let dayText = take(2), let parsedDay = Int(dayText) else { return nil }
            day = parsedDay
        }

        if peek() == "T" || peek() == " " {
            index += 1
            guard let hourText = take(2), let parsedHour = Int(hourText) else { return nil }
            hour = parsedHour
            if eat(":") {
                guard let minuteText = take(2), let parsedMinute = Int(minuteText) else { return nil }
                minute = parsedMinute
                if eat(":") {
                    guard let secondText = take(2), let parsedSecond = Int(secondText) else { return nil }
                    second = parsedSecond
                }
            } else {
                guard let minuteText = take(2), let parsedMinute = Int(minuteText) else { return nil }
                minute = parsedMinute
                if peek()?.isNumber == true {
                    guard let secondText = take(2), let parsedSecond = Int(secondText) else { return nil }
                    second = parsedSecond
                }
            }
            if eat(".") {
                var fraction = ""
                while peek()?.isNumber == true, fraction.count < 9 {
                    fraction.append(characters[index])
                    index += 1
                }
                guard !fraction.isEmpty, let value = Int(fraction) else { return nil }
                var scaled = value
                var digits = fraction.count
                while digits < 9 {
                    scaled *= 10
                    digits += 1
                }
                nanosecond = scaled
            }
            if eat("Z") {
                zoneSeconds = 0
            } else if peek() == "+" || peek() == "-" {
                let negative = peek() == "-"
                index += 1
                guard let zoneHourText = take(2), let zoneHour = Int(zoneHourText) else { return nil }
                if eat(":") {
                    guard let zoneMinuteText = take(2), let zoneMinute = Int(zoneMinuteText) else { return nil }
                    zoneSeconds = (zoneHour * 3600 + zoneMinute * 60) * (negative ? -1 : 1)
                } else if peek()?.isNumber == true {
                    guard let zoneMinuteText = take(2), let zoneMinute = Int(zoneMinuteText) else { return nil }
                    zoneSeconds = (zoneHour * 3600 + zoneMinute * 60) * (negative ? -1 : 1)
                } else {
                    zoneSeconds = zoneHour * 3600 * (negative ? -1 : 1)
                }
            }
        } else if requireTime {
            return nil
        }

        guard index == characters.count else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = nanosecond
        guard let utc = calendar.date(from: components) else { return nil }
        return utc.addingTimeInterval(TimeInterval(-zoneSeconds))
    }
}

private func _pad(_ value: Int, _ width: Int) -> String {
    let digits = String(value)
    guard digits.count < width else { return digits }
    return String(repeating: "0", count: width - digits.count) + digits
}
