// Portable DateComponentsFormatter for Linux-hosted Mach-O guests.
//
// unitsStyle × allowedUnits × zeroFormattingBehavior and the en/de/fr/ja
// unit names were read off Apple Foundation on 2026-09-05
// (full/foundation/tests/foundation-date-components-formatter-apple-2026-09-05.txt).
// No ICU: unit strings are carried tables.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif

public struct NSCalendar {
    public struct Unit: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // Raw values: Apple NSCalendar.Unit on 2026-09-05.
        public static let era = Unit(rawValue: 2)
        public static let year = Unit(rawValue: 4)
        public static let month = Unit(rawValue: 8)
        public static let day = Unit(rawValue: 16)
        public static let hour = Unit(rawValue: 32)
        public static let minute = Unit(rawValue: 64)
        public static let second = Unit(rawValue: 128)
        public static let weekday = Unit(rawValue: 512)
        public static let weekdayOrdinal = Unit(rawValue: 1024)
        public static let quarter = Unit(rawValue: 2048)
        public static let weekOfMonth = Unit(rawValue: 4096)
        public static let weekOfYear = Unit(rawValue: 8192)
        public static let yearForWeekOfYear = Unit(rawValue: 16384)
        public static let nanosecond = Unit(rawValue: 32768)
        public static let calendar = Unit(rawValue: 1_048_576)
        public static let timeZone = Unit(rawValue: 2_097_152)
    }
}

open class DateComponentsFormatter {
    public enum UnitsStyle: Int, Sendable {
        case positional = 0
        case abbreviated = 1
        case short = 2
        case full = 3
        case spellOut = 4
        case brief = 5
    }

    public struct ZeroFormattingBehavior: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // Raw values: Apple DateComponentsFormatter.ZeroFormattingBehavior on 2026-09-05.
        public static let `default` = ZeroFormattingBehavior(rawValue: 1)
        public static let dropLeading = ZeroFormattingBehavior(rawValue: 2)
        public static let dropMiddle = ZeroFormattingBehavior(rawValue: 4)
        public static let dropTrailing = ZeroFormattingBehavior(rawValue: 8)
        public static let dropAll = ZeroFormattingBehavior(rawValue: 14)
        public static let pad = ZeroFormattingBehavior(rawValue: 65536)
    }

    open var unitsStyle: UnitsStyle = .positional
    open var allowedUnits: NSCalendar.Unit = []
    open var zeroFormattingBehavior: ZeroFormattingBehavior = .default
    open var calendar: Calendar?

    public init() {}

    open func string(from components: DateComponents) -> String? {
        let units = _orderedUnits
        var values: [(UnitKind, Int)] = []
        for unit in units {
            values.append((unit, _component(components, unit)))
        }
        return _render(values)
    }

    open func string(from ti: TimeInterval) -> String? {
        var remaining = Int(ti.rounded())
        if remaining < 0 { remaining = -remaining }
        var values: [(UnitKind, Int)] = []
        for unit in _orderedUnits {
            let size = unit.seconds
            if size == 0 { continue }
            let count = remaining / size
            remaining -= count * size
            values.append((unit, count))
        }
        return _render(values)
    }

    open func string(from startDate: Date, to endDate: Date) -> String? {
        string(from: endDate.timeIntervalSince(startDate))
    }

    private enum UnitKind: Int {
        case year, month, week, day, hour, minute, second

        var seconds: Int {
            switch self {
            case .year: return 31_556_952
            case .month: return 2_629_746
            case .week: return 604_800
            case .day: return 86_400
            case .hour: return 3_600
            case .minute: return 60
            case .second: return 1
            }
        }
    }

    private var _orderedUnits: [UnitKind] {
        let allowed = allowedUnits
        var result: [UnitKind] = []
        if allowed.contains(.year) { result.append(.year) }
        if allowed.contains(.month) { result.append(.month) }
        if allowed.contains(.weekOfYear) || allowed.contains(.weekOfMonth) { result.append(.week) }
        if allowed.contains(.day) { result.append(.day) }
        if allowed.contains(.hour) { result.append(.hour) }
        if allowed.contains(.minute) { result.append(.minute) }
        if allowed.contains(.second) { result.append(.second) }
        if result.isEmpty {
            result = [.hour, .minute, .second]
        }
        return result
    }

    private func _component(_ components: DateComponents, _ unit: UnitKind) -> Int {
        switch unit {
        case .year: return components.year ?? 0
        case .month: return components.month ?? 0
        case .week: return components.weekOfYear ?? components.weekOfMonth ?? 0
        case .day: return components.day ?? 0
        case .hour: return components.hour ?? 0
        case .minute: return components.minute ?? 0
        case .second: return components.second ?? 0
        }
    }

    private func _render(_ values: [(UnitKind, Int)]) -> String {
        let shown = _filter(values)
        guard !shown.isEmpty else { return "" }
        if unitsStyle == .positional {
            return _positional(shown)
        }
        return _labeled(shown)
    }

    private func _filter(_ values: [(UnitKind, Int)]) -> [(UnitKind, Int)] {
        let behavior = zeroFormattingBehavior
        if behavior.contains(.pad) && !behavior.contains(.dropAll) && behavior != .default {
            return values
        }
        if behavior.isEmpty {
            return values
        }
        if behavior.contains(.dropAll) || behavior == .default && unitsStyle != .positional {
            let nonzero = values.filter { $0.1 != 0 }
            return nonzero.isEmpty ? [values.last!] : nonzero
        }
        var result = values
        let dropLead = behavior.contains(.dropLeading)
            || behavior == .default
            || behavior.contains(.dropMiddle)
        let dropTrail = behavior.contains(.dropTrailing)
        if dropLead {
            while result.count > 1, result.first?.1 == 0 {
                result.removeFirst()
            }
        }
        if dropTrail {
            while result.count > 1, result.last?.1 == 0 {
                result.removeLast()
            }
        }
        if behavior.contains(.dropMiddle) {
            var filtered: [(UnitKind, Int)] = []
            for (index, item) in result.enumerated() {
                if item.1 != 0 || index == 0 || index == result.count - 1 {
                    filtered.append(item)
                }
            }
            result = filtered
        }
        return result
    }

    private func _positional(_ values: [(UnitKind, Int)]) -> String {
        let pad = zeroFormattingBehavior.contains(.pad)
        var parts: [String] = []
        for (index, item) in values.enumerated() {
            if pad || index > 0 {
                parts.append(_pad(item.1, 2))
            } else {
                parts.append(String(item.1))
            }
        }
        return parts.joined(separator: ":")
    }

    private func _labeled(_ values: [(UnitKind, Int)]) -> String {
        let language = _language
        var parts: [String] = []
        for item in values {
            parts.append(_label(item.1, unit: item.0, language: language))
        }
        if unitsStyle == .full {
            if language == "ja" {
                return parts.joined(separator: " ")
            }
            if language == "de" || language == "fr" {
                if parts.count == 1 { return parts[0] }
                let conjunction = language == "de" ? " und " : " et "
                return parts.dropLast().joined(separator: ", ") + conjunction + parts.last!
            }
            return parts.joined(separator: ", ")
        }
        if unitsStyle == .short {
            return parts.joined(separator: ", ")
        }
        if language == "ja" {
            return unitsStyle == .abbreviated ? parts.joined() : parts.joined(separator: " ")
        }
        return parts.joined(separator: " ")
    }

    private var _language: String {
        let identifier = String((calendar?.locale ?? .current).identifier.map { $0 == "-" ? "_" : $0 })
        if let first = identifier.split(separator: "_").first {
            return String(first)
        }
        return "en"
    }

    private func _label(_ value: Int, unit: UnitKind, language: String) -> String {
        let plural = abs(value) != 1
        switch (language, unitsStyle) {
        case ("de", .full):
            let name: String
            switch unit {
            case .day: name = plural ? "Tage" : "Tag"
            case .hour: name = plural ? "Stunden" : "Stunde"
            case .minute: name = plural ? "Minuten" : "Minute"
            case .second: name = plural ? "Sekunden" : "Sekunde"
            case .week: name = plural ? "Wochen" : "Woche"
            case .month: name = plural ? "Monate" : "Monat"
            case .year: name = plural ? "Jahre" : "Jahr"
            }
            return "\(value) \(name)"
        case ("fr", .full):
            let name: String
            let nbsp = unit == .minute ? " " : "\u{00A0}"
            switch unit {
            case .day: name = plural ? "jours" : "jour"
            case .hour: name = plural ? "heures" : "heure"
            case .minute: name = plural ? "minutes" : "minute"
            case .second: name = plural ? "secondes" : "seconde"
            case .week: name = plural ? "semaines" : "semaine"
            case .month: name = plural ? "mois" : "mois"
            case .year: name = plural ? "ans" : "an"
            }
            return "\(value)\(nbsp)\(name)"
        case ("ja", .full), ("ja", .abbreviated), ("ja", .short), ("ja", .brief):
            let name: String
            switch unit {
            case .day: name = "日"
            case .hour: name = "時間"
            case .minute: name = "分"
            case .second: name = "秒"
            case .week: name = "週間"
            case .month: name = "か月"
            case .year: name = "年"
            }
            return "\(value)\(name)"
        case (_, .abbreviated):
            if language == "de" || language == "fr" {
                switch unit {
                case .hour: return "\(value)h"
                case .minute: return "\(value)min"
                case .second: return "\(value)s"
                case .day: return "\(value)d"
                case .week: return "\(value)w"
                case .month: return "\(value)m"
                case .year: return "\(value)y"
                }
            }
            switch unit {
            case .day: return "\(value)d"
            case .hour: return "\(value)h"
            case .minute: return "\(value)m"
            case .second: return "\(value)s"
            case .week: return "\(value)w"
            case .month: return "\(value)mo"
            case .year: return "\(value)y"
            }
        case (_, .short):
            switch unit {
            case .day: return "\(value) day"
            case .hour: return "\(value) hr"
            case .minute: return "\(value) min"
            case .second: return "\(value) sec"
            case .week: return "\(value) wk"
            case .month: return "\(value) mth"
            case .year: return "\(value) yr"
            }
        case (_, .brief):
            switch unit {
            case .day: return "\(value)day"
            case .hour: return "\(value)hr"
            case .minute: return "\(value)min"
            case .second: return "\(value)sec"
            case .week: return "\(value)wk"
            case .month: return "\(value)mth"
            case .year: return "\(value)yr"
            }
        default:
            let name: String
            switch unit {
            case .day: name = plural ? "days" : "day"
            case .hour: name = plural ? "hours" : "hour"
            case .minute: name = plural ? "minutes" : "minute"
            case .second: name = plural ? "seconds" : "second"
            case .week: name = plural ? "weeks" : "week"
            case .month: name = plural ? "months" : "month"
            case .year: name = plural ? "years" : "year"
            }
            return "\(value) \(name)"
        }
    }

    private func _pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        guard digits.count < width else { return digits }
        return String(repeating: "0", count: width - digits.count) + digits
    }
}
