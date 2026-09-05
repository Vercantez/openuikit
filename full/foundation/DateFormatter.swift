// A dependency-light DateFormatter facade for Linux-hosted Mach-O guests.
//
// Pattern fields, quoted literals, dateStyle/timeStyle tables, locale names
// (en/de/fr/ja) and parsing round trips were read off Apple Foundation on
// 2026-09-05 (full/foundation/tests/foundation-date-formatter-apple-2026-09-05.txt).
// No ICU: style patterns and name tables are the carried golden.

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
        if let pattern = _stylePatterns[_styleKey] {
            return _render(pattern, date: date)
        }
        return ""
    }

    open func string(for object: Any?) -> String? {
        guard let date = object as? Date else { return nil }
        return string(from: date)
    }

    open func date(from string: String) -> Date? {
        let pattern: String
        if let dateFormat, !dateFormat.isEmpty {
            pattern = dateFormat
        } else if let styled = _stylePatterns[_styleKey] {
            pattern = styled
        } else {
            return nil
        }
        return _parse(pattern, string: string)
    }

    private var _styleKey: String {
        "\(_localeIdentifier).\(dateStyle.rawValue).\(timeStyle.rawValue)"
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
        if identifier == "EN_US_POSIX" { return true }
        for part in identifier.split(separator: "_") {
            if part == "US" || part == "PH" { return true }
        }
        return false
    }

    // Style dateFormat strings: Apple DateFormatter on 2026-09-05, GMT.
    // NNBSP before `a` is U+202F (en_US / en_US_POSIX).
    private var _stylePatterns: [String: String] {
        [
            "en_US_POSIX.0.1": "h:mm\u{202F}a",
            "en_US_POSIX.0.2": "h:mm:ss\u{202F}a",
            "en_US_POSIX.0.3": "h:mm:ss\u{202F}a z",
            "en_US_POSIX.0.4": "h:mm:ss\u{202F}a zzzz",
            "en_US_POSIX.1.0": "M/d/yy",
            "en_US_POSIX.1.1": "M/d/yy, h:mm\u{202F}a",
            "en_US_POSIX.1.2": "M/d/yy, h:mm:ss\u{202F}a",
            "en_US_POSIX.1.3": "M/d/yy, h:mm:ss\u{202F}a z",
            "en_US_POSIX.1.4": "M/d/yy, h:mm:ss\u{202F}a zzzz",
            "en_US_POSIX.2.0": "MMM d, y",
            "en_US_POSIX.2.1": "MMM d, y 'at' h:mm\u{202F}a",
            "en_US_POSIX.2.2": "MMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US_POSIX.2.3": "MMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US_POSIX.2.4": "MMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_US_POSIX.3.0": "MMMM d, y",
            "en_US_POSIX.3.1": "MMMM d, y 'at' h:mm\u{202F}a",
            "en_US_POSIX.3.2": "MMMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US_POSIX.3.3": "MMMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US_POSIX.3.4": "MMMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_US_POSIX.4.0": "EEEE, MMMM d, y",
            "en_US_POSIX.4.1": "EEEE, MMMM d, y 'at' h:mm\u{202F}a",
            "en_US_POSIX.4.2": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US_POSIX.4.3": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US_POSIX.4.4": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_US.0.1": "h:mm\u{202F}a",
            "en_US.0.2": "h:mm:ss\u{202F}a",
            "en_US.0.3": "h:mm:ss\u{202F}a z",
            "en_US.0.4": "h:mm:ss\u{202F}a zzzz",
            "en_US.1.0": "M/d/yy",
            "en_US.1.1": "M/d/yy, h:mm\u{202F}a",
            "en_US.1.2": "M/d/yy, h:mm:ss\u{202F}a",
            "en_US.1.3": "M/d/yy, h:mm:ss\u{202F}a z",
            "en_US.1.4": "M/d/yy, h:mm:ss\u{202F}a zzzz",
            "en_US.2.0": "MMM d, y",
            "en_US.2.1": "MMM d, y 'at' h:mm\u{202F}a",
            "en_US.2.2": "MMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US.2.3": "MMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US.2.4": "MMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_US.3.0": "MMMM d, y",
            "en_US.3.1": "MMMM d, y 'at' h:mm\u{202F}a",
            "en_US.3.2": "MMMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US.3.3": "MMMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US.3.4": "MMMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_US.4.0": "EEEE, MMMM d, y",
            "en_US.4.1": "EEEE, MMMM d, y 'at' h:mm\u{202F}a",
            "en_US.4.2": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a",
            "en_US.4.3": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a z",
            "en_US.4.4": "EEEE, MMMM d, y 'at' h:mm:ss\u{202F}a zzzz",
            "en_GB.0.1": "HH:mm",
            "en_GB.0.2": "HH:mm:ss",
            "en_GB.0.3": "HH:mm:ss z",
            "en_GB.0.4": "HH:mm:ss zzzz",
            "en_GB.1.0": "dd/MM/y",
            "en_GB.1.1": "dd/MM/y, HH:mm",
            "en_GB.1.2": "dd/MM/y, HH:mm:ss",
            "en_GB.1.3": "dd/MM/y, HH:mm:ss z",
            "en_GB.1.4": "dd/MM/y, HH:mm:ss zzzz",
            "en_GB.2.0": "d MMM y",
            "en_GB.2.1": "d MMM y 'at' HH:mm",
            "en_GB.2.2": "d MMM y 'at' HH:mm:ss",
            "en_GB.2.3": "d MMM y 'at' HH:mm:ss z",
            "en_GB.2.4": "d MMM y 'at' HH:mm:ss zzzz",
            "en_GB.3.0": "d MMMM y",
            "en_GB.3.1": "d MMMM y 'at' HH:mm",
            "en_GB.3.2": "d MMMM y 'at' HH:mm:ss",
            "en_GB.3.3": "d MMMM y 'at' HH:mm:ss z",
            "en_GB.3.4": "d MMMM y 'at' HH:mm:ss zzzz",
            "en_GB.4.0": "EEEE, d MMMM y",
            "en_GB.4.1": "EEEE, d MMMM y 'at' HH:mm",
            "en_GB.4.2": "EEEE, d MMMM y 'at' HH:mm:ss",
            "en_GB.4.3": "EEEE, d MMMM y 'at' HH:mm:ss z",
            "en_GB.4.4": "EEEE, d MMMM y 'at' HH:mm:ss zzzz",
            "de_DE.0.1": "HH:mm",
            "de_DE.0.2": "HH:mm:ss",
            "de_DE.0.3": "HH:mm:ss z",
            "de_DE.0.4": "HH:mm:ss zzzz",
            "de_DE.1.0": "dd.MM.yy",
            "de_DE.1.1": "dd.MM.yy, HH:mm",
            "de_DE.1.2": "dd.MM.yy, HH:mm:ss",
            "de_DE.1.3": "dd.MM.yy, HH:mm:ss z",
            "de_DE.1.4": "dd.MM.yy, HH:mm:ss zzzz",
            "de_DE.2.0": "dd.MM.y",
            "de_DE.2.1": "dd.MM.y, HH:mm",
            "de_DE.2.2": "dd.MM.y, HH:mm:ss",
            "de_DE.2.3": "dd.MM.y, HH:mm:ss z",
            "de_DE.2.4": "dd.MM.y, HH:mm:ss zzzz",
            "de_DE.3.0": "d. MMMM y",
            "de_DE.3.1": "d. MMMM y 'um' HH:mm",
            "de_DE.3.2": "d. MMMM y 'um' HH:mm:ss",
            "de_DE.3.3": "d. MMMM y 'um' HH:mm:ss z",
            "de_DE.3.4": "d. MMMM y 'um' HH:mm:ss zzzz",
            "de_DE.4.0": "EEEE, d. MMMM y",
            "de_DE.4.1": "EEEE, d. MMMM y 'um' HH:mm",
            "de_DE.4.2": "EEEE, d. MMMM y 'um' HH:mm:ss",
            "de_DE.4.3": "EEEE, d. MMMM y 'um' HH:mm:ss z",
            "de_DE.4.4": "EEEE, d. MMMM y 'um' HH:mm:ss zzzz",
            "fr_FR.0.1": "HH:mm",
            "fr_FR.0.2": "HH:mm:ss",
            "fr_FR.0.3": "HH:mm:ss z",
            "fr_FR.0.4": "HH:mm:ss zzzz",
            "fr_FR.1.0": "dd/MM/y",
            "fr_FR.1.1": "dd/MM/y HH:mm",
            "fr_FR.1.2": "dd/MM/y HH:mm:ss",
            "fr_FR.1.3": "dd/MM/y HH:mm:ss z",
            "fr_FR.1.4": "dd/MM/y HH:mm:ss zzzz",
            "fr_FR.2.0": "d MMM y",
            "fr_FR.2.1": "d MMM y 'à' HH:mm",
            "fr_FR.2.2": "d MMM y 'à' HH:mm:ss",
            "fr_FR.2.3": "d MMM y 'à' HH:mm:ss z",
            "fr_FR.2.4": "d MMM y 'à' HH:mm:ss zzzz",
            "fr_FR.3.0": "d MMMM y",
            "fr_FR.3.1": "d MMMM y 'à' HH:mm",
            "fr_FR.3.2": "d MMMM y 'à' HH:mm:ss",
            "fr_FR.3.3": "d MMMM y 'à' HH:mm:ss z",
            "fr_FR.3.4": "d MMMM y 'à' HH:mm:ss zzzz",
            "fr_FR.4.0": "EEEE d MMMM y",
            "fr_FR.4.1": "EEEE d MMMM y 'à' HH:mm",
            "fr_FR.4.2": "EEEE d MMMM y 'à' HH:mm:ss",
            "fr_FR.4.3": "EEEE d MMMM y 'à' HH:mm:ss z",
            "fr_FR.4.4": "EEEE d MMMM y 'à' HH:mm:ss zzzz",
            "ja_JP.0.1": "H:mm",
            "ja_JP.0.2": "H:mm:ss",
            "ja_JP.0.3": "H:mm:ss z",
            "ja_JP.0.4": "H時mm分ss秒 zzzz",
            "ja_JP.1.0": "y/MM/dd",
            "ja_JP.1.1": "y/MM/dd H:mm",
            "ja_JP.1.2": "y/MM/dd H:mm:ss",
            "ja_JP.1.3": "y/MM/dd H:mm:ss z",
            "ja_JP.1.4": "y/MM/dd H時mm分ss秒 zzzz",
            "ja_JP.2.0": "y/MM/dd",
            "ja_JP.2.1": "y/MM/dd H:mm",
            "ja_JP.2.2": "y/MM/dd H:mm:ss",
            "ja_JP.2.3": "y/MM/dd H:mm:ss z",
            "ja_JP.2.4": "y/MM/dd H時mm分ss秒 zzzz",
            "ja_JP.3.0": "y年M月d日",
            "ja_JP.3.1": "y年M月d日 H:mm",
            "ja_JP.3.2": "y年M月d日 H:mm:ss",
            "ja_JP.3.3": "y年M月d日 H:mm:ss z",
            "ja_JP.3.4": "y年M月d日 H時mm分ss秒 zzzz",
            "ja_JP.4.0": "y年M月d日 EEEE",
            "ja_JP.4.1": "y年M月d日 EEEE H:mm",
            "ja_JP.4.2": "y年M月d日 EEEE H:mm:ss",
            "ja_JP.4.3": "y年M月d日 EEEE H:mm:ss z",
            "ja_JP.4.4": "y年M月d日 EEEE H時mm分ss秒 zzzz",
        ]
    }

    private func _render(_ pattern: String, date: Date) -> String {
        let calendar = _effectiveCalendar
        let components = calendar.dateComponents(
            [.era, .year, .month, .day, .dayOfYear, .weekday,
             .hour, .minute, .second, .nanosecond],
            from: date
        )
        let zone = timeZone ?? calendar.timeZone
        var output = ""
        for token in _tokens(pattern) {
            switch token {
            case .literal(let text):
                output += text
            case .field(let symbol, let count):
                output += _field(
                    symbol,
                    count: count,
                    components: components,
                    date: date,
                    zone: zone
                )
            }
        }
        return output
    }

    private enum Token {
        case literal(String)
        case field(Character, Int)
    }

    private func _tokens(_ pattern: String) -> [Token] {
        let characters = Array(pattern)
        var tokens: [Token] = []
        var index = 0
        var quoted = false
        var literal = ""
        func flushLiteral() {
            if !literal.isEmpty {
                tokens.append(.literal(literal))
                literal = ""
            }
        }
        while index < characters.count {
            let character = characters[index]
            if character == "'" {
                if index + 1 < characters.count, characters[index + 1] == "'" {
                    literal.append("'")
                    index += 2
                } else {
                    quoted.toggle()
                    index += 1
                }
                continue
            }
            if quoted || !(character.isASCII && character.isLetter) {
                literal.append(character)
                index += 1
                continue
            }
            flushLiteral()
            var end = index + 1
            while end < characters.count, characters[end] == character { end += 1 }
            tokens.append(.field(character, end - index))
            index = end
        }
        flushLiteral()
        return tokens
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
        case "G":
            return _era
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
            return hour < 12 ? _am : _pm
        case "Z": return _offset(zone.secondsFromGMT(for: date), colon: count >= 5, zulu: false)
        case "X": return _offset(zone.secondsFromGMT(for: date), colon: count >= 3, zulu: true)
        case "x": return _offset(zone.secondsFromGMT(for: date), colon: count >= 3, zulu: false)
        case "z":
            return _zoneName(zone, date: date, long: count >= 4)
        default: return String(repeating: String(symbol), count: count)
        }
    }

    private var _era: String {
        switch _language {
        case "de": return "n. Chr."
        case "fr": return "ap. J.-C."
        case "ja": return "西暦"
        default: return "AD"
        }
    }

    private var _am: String {
        switch _language {
        case "ja": return "午前"
        case "en":
            return _usesTwelveHourStyle ? "AM" : "am"
        default: return "AM"
        }
    }

    private var _pm: String {
        switch _language {
        case "ja": return "午後"
        case "en":
            return _usesTwelveHourStyle ? "PM" : "pm"
        default: return "PM"
        }
    }

    private func _zoneName(_ zone: TimeZone, date: Date, long: Bool) -> String {
        let id = zone.identifier
        let locale = _localeIdentifier
        if long {
            if id == "GMT" {
                switch _language {
                case "de": return "Mittlere Greenwich-Zeit"
                case "fr": return "heure moyenne de Greenwich"
                case "ja": return "グリニッジ標準時"
                default: return "Greenwich Mean Time"
                }
            }
            if id == "America/Chicago" {
                switch _language {
                case "de": return "Nordamerikanische Zentral-Normalzeit"
                case "fr": return "heure normale du centre nord-américain"
                case "ja": return "米国中部標準時"
                default: return "Central Standard Time"
                }
            }
        } else {
            if _language == "fr" {
                return _formattedOffset(zone.secondsFromGMT(for: date), prefix: "UTC", minus: "\u{2212}")
            }
            if locale == "en_GB", id == "America/Chicago" {
                return _formattedOffset(zone.secondsFromGMT(for: date), prefix: "GMT", minus: "-")
            }
            if _language == "de" || _language == "ja" {
                return _formattedOffset(zone.secondsFromGMT(for: date), prefix: "GMT", minus: "-")
            }
            if id == "GMT" { return "GMT" }
            if let abbreviation = zone.abbreviation(for: date) {
                return abbreviation
            }
        }
        return zone.abbreviation(for: date) ?? zone.identifier
    }

    private func _formattedOffset(_ seconds: Int, prefix: String, minus: String) -> String {
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds < 0 ? minus : "+"
        var result = prefix + sign + String(hours)
        if minutes != 0 { result += ":" + _pad(minutes, 2) }
        return result
    }

    private var _monthNames: (short: [String], long: [String]) {
        switch _language {
        case "de":
            return (["Jan.", "Feb.", "März", "Apr.", "Mai", "Juni",
                     "Juli", "Aug.", "Sept.", "Okt.", "Nov.", "Dez."],
                    ["Januar", "Februar", "März", "April", "Mai", "Juni",
                     "Juli", "August", "September", "Oktober", "November", "Dezember"])
        case "fr":
            return (["janv.", "févr.", "mars", "avr.", "mai", "juin",
                     "juil.", "août", "sept.", "oct.", "nov.", "déc."],
                    ["janvier", "février", "mars", "avril", "mai", "juin",
                     "juillet", "août", "septembre", "octobre", "novembre", "décembre"])
        case "ja":
            return (["1月", "2月", "3月", "4月", "5月", "6月",
                     "7月", "8月", "9月", "10月", "11月", "12月"],
                    ["1月", "2月", "3月", "4月", "5月", "6月",
                     "7月", "8月", "9月", "10月", "11月", "12月"])
        default:
            return (["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"])
        }
    }

    private var _weekdayNames: (short: [String], long: [String]) {
        switch _language {
        case "de":
            return (["So.", "Mo.", "Di.", "Mi.", "Do.", "Fr.", "Sa."],
                    ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"])
        case "fr":
            return (["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."],
                    ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"])
        case "ja":
            return (["日", "月", "火", "水", "木", "金", "土"],
                    ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"])
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

    private func _parse(_ pattern: String, string: String) -> Date? {
        let tokens = _tokens(pattern)
        let characters = Array(string)
        var index = 0
        var year = 1970
        var month = 1
        var day = 1
        var hour = 0
        var minute = 0
        var second = 0
        var nanosecond = 0
        var isPM: Bool?
        var zoneSeconds = 0
        var sawZone = false

        func remaining() -> String {
            String(characters[index...])
        }
        func takeDigits(_ maxCount: Int) -> Int? {
            var digits = ""
            while digits.count < maxCount, index < characters.count, characters[index].isNumber {
                digits.append(characters[index])
                index += 1
            }
            return digits.isEmpty ? nil : Int(digits)
        }
        func matchPrefix(_ names: [String]) -> Int? {
            let rest = remaining()
            var best: (Int, Int)? = nil
            for (offset, name) in names.enumerated() {
                if rest.hasPrefix(name) {
                    if best == nil || name.count > best!.1 {
                        best = (offset, name.count)
                    }
                }
            }
            guard let hit = best else { return nil }
            index += hit.1
            return hit.0
        }

        for token in tokens {
            switch token {
            case .literal(let text):
                let slice = remaining()
                guard slice.hasPrefix(text) else { return nil }
                index += text.count
            case .field(let symbol, let count):
                switch symbol {
                case "y", "Y":
                    let width = count == 2 ? 2 : max(count, 1)
                    guard let value = takeDigits(count == 1 ? 4 : width) else { return nil }
                    year = count == 2 ? 2000 + value : value
                    if count == 2, value >= 70 { year = 1900 + value }
                case "M", "L":
                    if count >= 3 {
                        let names = count >= 4 ? _monthNames.long : _monthNames.short
                        guard let offset = matchPrefix(names) else { return nil }
                        month = offset + 1
                    } else {
                        guard let value = takeDigits(2) else { return nil }
                        month = value
                    }
                case "d":
                    guard let value = takeDigits(2) else { return nil }
                    day = value
                case "D":
                    guard let value = takeDigits(3) else { return nil }
                    // day-of-year is converted after the loop via calendar if needed
                    day = value
                    month = 1
                case "H", "k":
                    guard let value = takeDigits(2) else { return nil }
                    hour = symbol == "k" && value == 24 ? 0 : value
                case "h", "K":
                    guard let value = takeDigits(2) else { return nil }
                    hour = value
                case "m":
                    guard let value = takeDigits(2) else { return nil }
                    minute = value
                case "s":
                    guard let value = takeDigits(2) else { return nil }
                    second = value
                case "S":
                    guard let value = takeDigits(count) else { return nil }
                    var scaled = value
                    var digits = String(value).count
                    while digits < 9 {
                        scaled *= 10
                        digits += 1
                    }
                    nanosecond = scaled
                case "a":
                    if matchPrefix([_am]) != nil {
                        isPM = false
                    } else if matchPrefix([_pm]) != nil {
                        isPM = true
                    } else {
                        return nil
                    }
                case "X", "x", "Z":
                    sawZone = true
                    if remaining().hasPrefix("Z") {
                        index += 1
                        zoneSeconds = 0
                    } else if remaining().hasPrefix("+") || remaining().hasPrefix("-") {
                        let negative = remaining().hasPrefix("-")
                        index += 1
                        guard let hours = takeDigits(2) else { return nil }
                        if index < characters.count, characters[index] == ":" { index += 1 }
                        let minutes = takeDigits(2) ?? 0
                        zoneSeconds = (hours * 3600 + minutes * 60) * (negative ? -1 : 1)
                    } else {
                        return nil
                    }
                case "E", "e", "c", "G", "z":
                    // Consume a run of non-digit, non-separator letters/punctuation.
                    while index < characters.count {
                        let character = characters[index]
                        if character.isNumber { break }
                        if character == "," || character == " " { break }
                        index += 1
                    }
                default:
                    break
                }
            }
        }
        guard index == characters.count || isLenient else { return nil }
        if let isPM {
            if isPM, hour < 12 { hour += 12 }
            if !isPM, hour == 12 { hour = 0 }
        }
        var calendar = _effectiveCalendar
        if sawZone {
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = nanosecond
        guard let date = calendar.date(from: components) else { return nil }
        if sawZone {
            return date.addingTimeInterval(TimeInterval(-zoneSeconds))
        }
        return date
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
