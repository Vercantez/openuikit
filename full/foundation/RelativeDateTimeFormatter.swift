// Locale-aware relative date/time formatting for Linux-hosted Mach-O guests.
//
// This is a dependency-light implementation over FoundationEssentials'
// Calendar, Locale, Date, and DateComponents identities.  It implements the
// complete value-formatting surface used by the first-party formatter rather
// than teaching individual applications how to render ages.

import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("RelativeDateTimeFormatter requires the ObjectiveC NSObject substrate")
#endif

@_silgen_name("openui_relative_time_v1_format")
private func _openUIRelativeTimeFormat(
    _ abiVersion: UInt32,
    _ localeBytes: UnsafePointer<UInt8>?,
    _ localeCount: UInt64,
    _ unitsStyle: Int32,
    _ dateTimeStyle: Int32,
    _ unit: Int32,
    _ value: Double,
    _ outputBytes: UnsafeMutablePointer<UInt8>?,
    _ outputCapacity: UInt64,
    _ outputCount: UnsafeMutablePointer<UInt64>?
) -> Int32

open class RelativeDateTimeFormatter: NSObject, @unchecked Sendable {
    public enum DateTimeStyle: Int, Sendable {
        case numeric = 0
        case named = 1
    }

    public enum UnitsStyle: Int, Sendable {
        case full = 0
        case spellOut = 1
        case short = 2
        case abbreviated = 3
    }

    open var dateTimeStyle: DateTimeStyle = .numeric
    open var unitsStyle: UnitsStyle = .full
    open var calendar: Calendar = .autoupdatingCurrent
    open var locale: Locale = .current

    public override init() {
        super.init()
    }

    open func localizedString(from dateComponents: DateComponents) -> String {
        let candidates: [(Calendar.Component, Int?)] = [
            (.year, dateComponents.year),
            (.month, dateComponents.month),
            (.weekOfMonth, dateComponents.weekOfMonth),
            (.day, dateComponents.day),
            (.hour, dateComponents.hour),
            (.minute, dateComponents.minute),
            (.second, dateComponents.second),
        ]
        // Apple's API formats one component, preferring the least granular
        // (largest calendar) component that was actually supplied.
        for (component, value) in candidates {
            if let value {
                return _format(Double(value), component: component)
            }
        }
        return _format(0, component: .second)
    }

    open func localizedString(fromTimeInterval timeInterval: TimeInterval) -> String {
        _formatInterval(timeInterval)
    }

    open func localizedString(for date: Date, relativeTo referenceDate: Date) -> String {
        let interval = date.timeIntervalSince(referenceDate)
        let magnitude = abs(interval)

        // Calendar-aware day/month/year boundaries matter more than a fixed
        // seconds conversion once the interval is at least a day.
        if magnitude >= 86_400 {
            let ordered: [Calendar.Component] = [.year, .month, .weekOfMonth, .day]
            let components = calendar.dateComponents(
                Set(ordered),
                from: referenceDate,
                to: date
            )
            for component in ordered {
                let value: Int?
                switch component {
                case .year: value = components.year
                case .month: value = components.month
                case .weekOfMonth: value = components.weekOfMonth
                case .day: value = components.day
                default: value = nil
                }
                if let value, value != 0 {
                    return _format(Double(value), component: component)
                }
            }
        }
        return _formatInterval(interval)
    }

    open func string(for object: Any?) -> String? {
        guard let date = object as? Date else { return nil }
        return localizedString(for: date, relativeTo: Date())
    }

    private func _formatInterval(_ interval: TimeInterval) -> String {
        let magnitude = abs(interval)
        let component: Calendar.Component
        let divisor: Double
        switch magnitude {
        case 0..<60:
            component = .second; divisor = 1
        case 60..<3_600:
            component = .minute; divisor = 60
        case 3_600..<86_400:
            component = .hour; divisor = 3_600
        case 86_400..<604_800:
            component = .day; divisor = 86_400
        case 604_800..<2_629_746:
            component = .weekOfMonth; divisor = 604_800
        case 2_629_746..<31_556_952:
            component = .month; divisor = 2_629_746
        default:
            component = .year; divisor = 31_556_952
        }
        return _format((interval / divisor).rounded(), component: component)
    }

    private func _format(_ rawValue: Double, component: Calendar.Component) -> String {
        let value = Int(rawValue.rounded())
        let unit: Int32
        switch component {
        case .year: unit = 0
        case .month: unit = 1
        case .weekOfMonth, .weekOfYear: unit = 2
        case .day: unit = 3
        case .hour: unit = 4
        case .minute: unit = 5
        default: unit = 6
        }
        if let result = _hostFormat(
            localeIdentifier: locale.identifier,
            unit: unit,
            value: Double(value)
        ) {
            return result
        }
        // A malformed locale identifier should not make a nonthrowing
        // first-party formatter crash an application. Retry through the same
        // real ICU service with a known locale before using the bounded ASCII
        // emergency path.
        if let result = _hostFormat(
            localeIdentifier: "en_US_POSIX",
            unit: unit,
            value: Double(value)
        ) {
            return result
        }
        return _emergencyEnglish(value, component: component)
    }

    private func _hostFormat(
        localeIdentifier: String,
        unit: Int32,
        value: Double
    ) -> String? {
        let localeBytes = Array(localeIdentifier.utf8)
        var output = [UInt8](repeating: 0, count: 4_096)
        var outputCount: UInt64 = 0
        let error = localeBytes.withUnsafeBufferPointer { localeBuffer in
            output.withUnsafeMutableBufferPointer { outputBuffer in
                _openUIRelativeTimeFormat(
                    1,
                    localeBuffer.baseAddress,
                    UInt64(localeBuffer.count),
                    Int32(unitsStyle.rawValue),
                    Int32(dateTimeStyle.rawValue),
                    unit,
                    value,
                    outputBuffer.baseAddress,
                    UInt64(outputBuffer.count),
                    &outputCount
                )
            }
        }
        guard error == 0, outputCount <= UInt64(output.count) else { return nil }
        return String(decoding: output.prefix(Int(outputCount)), as: UTF8.self)
    }

    private func _emergencyEnglish(
        _ value: Int,
        component: Calendar.Component
    ) -> String {
        let magnitude = abs(value)
        let stem: String
        switch component {
        case .year: stem = "year"
        case .month: stem = "month"
        case .weekOfMonth, .weekOfYear: stem = "week"
        case .day: stem = "day"
        case .hour: stem = "hour"
        case .minute: stem = "minute"
        default: stem = "second"
        }
        let phrase = "\(magnitude) \(stem)\(magnitude == 1 ? "" : "s")"
        return value < 0 ? phrase + " ago" : "in " + phrase
    }
}
