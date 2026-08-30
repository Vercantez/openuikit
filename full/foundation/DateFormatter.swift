// A dependency-light DateFormatter facade for Linux-hosted Mach-O guests.
//
// This is a project-owned implementation of the public Unicode date-pattern
// contract. It intentionally builds on FoundationEssentials' production
// Calendar, Locale, TimeZone and Date values rather than introducing parallel
// identities. The supported pattern symbols are the common Gregorian subset
// listed in FOUNDATION_GUEST_SERVICES.md; unsupported letters are preserved
// literally so a missing feature is visible instead of silently disappearing.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif

open class DateFormatter {
    public enum Style: UInt, Sendable {
        case none = 0
        case short = 1
        case medium = 2
        case long = 3
        case full = 4
    }

    open var locale: Locale! = .current
    open var calendar: Calendar! = .current
    open var timeZone: TimeZone?
    open var dateFormat: String!
    open var dateStyle: Style = .none
    open var timeStyle: Style = .none
    open var isLenient = false

    public init() {}

    open func string(from date: Date) -> String {
        if let dateFormat, !dateFormat.isEmpty {
            return _render(dateFormat, date: date)
        }

        let datePart = _styleDatePattern(dateStyle).map { _render($0, date: date) }
        let timePart = _styleTimePattern(timeStyle).map { _render($0, date: date) }
        switch (datePart, timePart) {
        case let (date?, time?):
            if _language == "fr" {
                return date + (dateStyle == .short ? " " : " à ") + time
            }
            if dateStyle == .short { return date + ", " + time }
            return date + " at " + time
        case let (date?, nil): return date
        case let (nil, time?): return time
        case (nil, nil): return ""
        }
    }

    open func string(for object: Any?) -> String? {
        guard let date = object as? Date else { return nil }
        return string(from: date)
    }

    private var _effectiveCalendar: Calendar {
        var value = calendar ?? .current
        value.locale = locale ?? .current
        if let timeZone { value.timeZone = timeZone }
        return value
    }

    private var _localeIdentifier: String {
        String((locale ?? .current).identifier.map { $0 == "-" ? "_" : $0 })
    }

    private var _language: String {
        String(_localeIdentifier.split(separator: "_").first ?? "en")
    }

    private var _usesTwelveHourStyle: Bool {
        let identifier = _localeIdentifier.uppercased()
        return identifier.contains("_US") || identifier.contains("_PH") ||
            identifier == "EN_US_POSIX"
    }

    private func _styleDatePattern(_ style: Style) -> String? {
        guard style != .none else { return nil }
        if _language == "fr" {
            switch style {
            case .short: return "dd/MM/yyyy"
            case .medium: return "d MMM yyyy"
            case .long: return "d MMMM yyyy"
            case .full: return "EEEE d MMMM yyyy"
            case .none: return nil
            }
        }
        if _usesTwelveHourStyle {
            switch style {
            case .short: return "M/d/yy"
            case .medium: return "MMM d, yyyy"
            case .long: return "MMMM d, yyyy"
            case .full: return "EEEE, MMMM d, yyyy"
            case .none: return nil
            }
        }
        switch style {
        case .short: return "dd/MM/yyyy"
        case .medium: return "d MMM yyyy"
        case .long: return "d MMMM yyyy"
        case .full: return "EEEE, d MMMM yyyy"
        case .none: return nil
        }
    }

    private func _styleTimePattern(_ style: Style) -> String? {
        guard style != .none else { return nil }
        let clock = _usesTwelveHourStyle ? "h:mm" : "HH:mm"
        let seconds = _usesTwelveHourStyle ? "h:mm:ss" : "HH:mm:ss"
        let marker = _usesTwelveHourStyle ? "\u{202F}a" : ""
        switch style {
        case .short: return clock + marker
        case .medium: return seconds + marker
        case .long: return seconds + marker + " z"
        case .full: return seconds + marker + " zzzz"
        case .none: return nil
        }
    }

    private func _render(_ pattern: String, date: Date) -> String {
        let calendar = _effectiveCalendar
        let components = calendar.dateComponents(
            [.era, .year, .month, .day, .dayOfYear, .weekday,
             .hour, .minute, .second, .nanosecond],
            from: date
        )
        let zone = timeZone ?? calendar.timeZone
        let characters = Array(pattern)
        var output = ""
        var index = 0
        var quoted = false

        while index < characters.count {
            let character = characters[index]
            if character == "'" {
                if index + 1 < characters.count, characters[index + 1] == "'" {
                    output.append("'")
                    index += 2
                } else {
                    quoted.toggle()
                    index += 1
                }
                continue
            }
            guard !quoted, character.isASCII, character.isLetter else {
                output.append(character)
                index += 1
                continue
            }

            var end = index + 1
            while end < characters.count, characters[end] == character { end += 1 }
            let count = end - index
            output += _field(
                character,
                count: count,
                components: components,
                date: date,
                zone: zone
            )
            index = end
        }
        return output
    }

    private func _field(
        _ symbol: Character,
        count: Int,
        components: DateComponents,
        date: Date,
        zone: TimeZone
    ) -> String {
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let weekday = components.weekday ?? 1

        switch symbol {
        case "G": return (components.era ?? 1) == 0 ? "BC" : "AD"
        case "y", "Y":
            return count == 2 ? _pad(abs(year) % 100, 2) : _pad(abs(year), count)
        case "M", "L":
            if count == 1 { return String(month) }
            if count == 2 { return _pad(month, 2) }
            if count == 3 { return _monthNames.short[safe: month - 1] ?? String(month) }
            if count == 4 { return _monthNames.long[safe: month - 1] ?? String(month) }
            return String((_monthNames.long[safe: month - 1] ?? String(month)).prefix(1))
        case "d": return count == 1 ? String(day) : _pad(day, count)
        case "D":
            let value = components.dayOfYear ?? day
            return count == 1 ? String(value) : _pad(value, count)
        case "E":
            if count == 5 {
                return String((_weekdayNames.long[safe: weekday - 1] ?? String(weekday)).prefix(1))
            }
            if count >= 4 { return _weekdayNames.long[safe: weekday - 1] ?? String(weekday) }
            return _weekdayNames.short[safe: weekday - 1] ?? String(weekday)
        case "e", "c":
            if count <= 2 { return count == 2 ? _pad(weekday, 2) : String(weekday) }
            return _field("E", count: count, components: components, date: date, zone: zone)
        case "H": return count == 1 ? String(hour) : _pad(hour, count)
        case "k":
            let value = hour == 0 ? 24 : hour
            return count == 1 ? String(value) : _pad(value, count)
        case "K":
            let value = hour % 12
            return count == 1 ? String(value) : _pad(value, count)
        case "h":
            let value = hour % 12 == 0 ? 12 : hour % 12
            return count == 1 ? String(value) : _pad(value, count)
        case "m": return count == 1 ? String(minute) : _pad(minute, count)
        case "s": return count == 1 ? String(second) : _pad(second, count)
        case "S":
            let nanos = _pad(components.nanosecond ?? 0, 9)
            if count <= 9 { return String(nanos.prefix(count)) }
            return nanos + String(repeating: "0", count: count - 9)
        case "a":
            if _language == "en", !_usesTwelveHourStyle { return hour < 12 ? "am" : "pm" }
            return hour < 12 ? "AM" : "PM"
        case "Z": return _offset(zone.secondsFromGMT(for: date), colon: count >= 5, zulu: false)
        case "X": return _offset(zone.secondsFromGMT(for: date), colon: count >= 3, zulu: true)
        case "x": return _offset(zone.secondsFromGMT(for: date), colon: count >= 3, zulu: false)
        case "z":
            if _language == "fr", count < 4 {
                let seconds = zone.secondsFromGMT(for: date)
                let hours = abs(seconds) / 3600
                let minutes = (abs(seconds) % 3600) / 60
                let sign = seconds < 0 ? "−" : "+"
                return "UTC" + sign + String(hours) +
                    (minutes == 0 ? "" : ":" + _pad(minutes, 2))
            }
            if count >= 4, zone.identifier == "GMT" { return "Greenwich Mean Time" }
            return zone.abbreviation(for: date) ?? zone.identifier
        default: return String(repeating: String(symbol), count: count)
        }
    }

    private var _monthNames: (short: [String], long: [String]) {
        switch _language {
        case "fr":
            return (["janv.", "févr.", "mars", "avr.", "mai", "juin",
                     "juil.", "août", "sept.", "oct.", "nov.", "déc."],
                    ["janvier", "février", "mars", "avril", "mai", "juin",
                     "juillet", "août", "septembre", "octobre", "novembre", "décembre"])
        default:
            return (["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"])
        }
    }

    private var _weekdayNames: (short: [String], long: [String]) {
        switch _language {
        case "fr":
            return (["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."],
                    ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"])
        default:
            return (["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
                    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"])
        }
    }

    private func _pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        guard digits.count < width else { return digits }
        return String(repeating: "0", count: width - digits.count) + digits
    }

    private func _offset(_ seconds: Int, colon: Bool, zulu: Bool) -> String {
        if seconds == 0, zulu { return "Z" }
        let magnitude = abs(seconds)
        let hours = magnitude / 3600
        let minutes = (magnitude % 3600) / 60
        return (seconds < 0 ? "-" : "+") + _pad(hours, 2) +
            (colon ? ":" : "") + _pad(minutes, 2)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
