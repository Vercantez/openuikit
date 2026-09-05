// Portable NumberFormatter for Linux-hosted Mach-O guests.
//
// Decimal / percent / currency / ordinal output, grouping, fraction digits
// and rounding modes were read off Apple Foundation on 2026-09-05
// (full/foundation/tests/foundation-number-formatter-apple-2026-09-05.txt)
// for en_US_POSIX, en_US, en_GB, de_DE, fr_FR and ja_JP. No ICU: locale
// symbols are the carried tables that golden proves.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif

open class NumberFormatter {
    public enum Style: UInt, Sendable {
        case none = 0
        case decimal = 1
        case currency = 2
        case percent = 3
        case scientific = 4
        case spellOut = 5
        case ordinal = 6
        case currencyISOCode = 8
        case currencyPlural = 9
        case currencyAccounting = 10
    }

    public enum RoundingMode: UInt, Sendable {
        case ceiling = 0
        case floor = 1
        case down = 2
        case up = 3
        case halfEven = 4
        case halfDown = 5
        case halfUp = 6
    }

    open var numberStyle: Style = .none
    open var locale: Locale! = .current
    open var minimumFractionDigits = 0
    open var maximumFractionDigits = 0
    open var usesGroupingSeparator = true
    open var roundingMode: RoundingMode = .halfEven
    open var groupingSize = 3

    public init() {}

    open func string(from number: NSNumber) -> String? {
        _string(number.doubleValue)
    }

    open func string(from number: Int) -> String? {
        _string(Double(number))
    }

    open func string(from number: Double) -> String? {
        _string(number)
    }

    open func number(from string: String) -> NSNumber? {
        let table = _localeTable
        var body = string
        var percent = false
        if body.hasSuffix(table.percentSuffix) {
            percent = true
            body.removeLast(table.percentSuffix.count)
        }
        var filtered = ""
        for character in body {
            if character == "-" || character == "\u{2212}" {
                filtered.append("-")
                continue
            }
            if character >= "0" && character <= "9" {
                filtered.append(character)
                continue
            }
            if String(character) == table.decimal {
                filtered.append(".")
                continue
            }
        }
        guard let value = Double(filtered) else { return nil }
        return NSNumber(value: percent ? value / 100 : value)
    }

    private struct LocaleTable {
        var decimal: String
        var grouping: String
        var groupDecimal: Bool
        var groupOrdinal: Bool
        var percentSuffix: String
        var currencySymbol: String
        var currencyPrefix: Bool
        var currencySpace: String
        var currencyFractions: Int
        var ordinal: OrdinalKind
    }

    private enum OrdinalKind { case english, german, french, japanese }

    private var _localeTable: LocaleTable {
        switch _localeIdentifier {
        case "en_GB":
            return LocaleTable(
                decimal: ".", grouping: ",", groupDecimal: true, groupOrdinal: true,
                percentSuffix: "%", currencySymbol: "£", currencyPrefix: true,
                currencySpace: "", currencyFractions: 2, ordinal: .english
            )
        case "de_DE":
            return LocaleTable(
                decimal: ",", grouping: ".", groupDecimal: true, groupOrdinal: true,
                percentSuffix: "\u{00A0}%", currencySymbol: "€", currencyPrefix: false,
                currencySpace: "\u{00A0}", currencyFractions: 2, ordinal: .german
            )
        case "fr_FR":
            return LocaleTable(
                decimal: ",", grouping: "\u{202F}", groupDecimal: true, groupOrdinal: true,
                percentSuffix: "\u{00A0}%", currencySymbol: "€", currencyPrefix: false,
                currencySpace: "\u{00A0}", currencyFractions: 2, ordinal: .french
            )
        case "ja_JP":
            return LocaleTable(
                decimal: ".", grouping: ",", groupDecimal: true, groupOrdinal: true,
                percentSuffix: "%", currencySymbol: "¥", currencyPrefix: true,
                currencySpace: "", currencyFractions: 0, ordinal: .japanese
            )
        case "en_US_POSIX":
            return LocaleTable(
                decimal: ".", grouping: ",", groupDecimal: false, groupOrdinal: true,
                percentSuffix: "%", currencySymbol: "$", currencyPrefix: true,
                currencySpace: "\u{00A0}", currencyFractions: 2, ordinal: .english
            )
        default:
            return LocaleTable(
                decimal: ".", grouping: ",", groupDecimal: true, groupOrdinal: true,
                percentSuffix: "%", currencySymbol: "$", currencyPrefix: true,
                currencySpace: "", currencyFractions: 2, ordinal: .english
            )
        }
    }

    private var _localeIdentifier: String {
        String((locale ?? .current).identifier.map { $0 == "-" ? "_" : $0 })
    }

    private func _string(_ value: Double) -> String {
        let table = _localeTable
        switch numberStyle {
        case .percent:
            return _format(
                value * 100,
                table: table,
                minFrac: 0,
                maxFrac: _neededFractions(value * 100),
                grouping: table.groupDecimal
            ) + table.percentSuffix
        case .currency:
            return _currency(value, table: table)
        case .ordinal:
            return _ordinal(value, table: table)
        default:
            let explicit = minimumFractionDigits > 0 || maximumFractionDigits > 0
            return _format(
                value,
                table: table,
                minFrac: explicit ? minimumFractionDigits : 0,
                maxFrac: explicit ? maximumFractionDigits : _neededFractions(value),
                grouping: table.groupDecimal
            )
        }
    }

    private func _neededFractions(_ value: Double) -> Int {
        let magnitude = abs(value)
        if magnitude == magnitude.rounded(.towardZero) { return 0 }
        return 6
    }

    private func _currency(_ value: Double, table: LocaleTable) -> String {
        let formatted = _format(
            abs(value),
            table: table,
            minFrac: table.currencyFractions,
            maxFrac: table.currencyFractions,
            grouping: table.groupDecimal
        )
        let body: String
        if table.currencyPrefix {
            body = table.currencySymbol + table.currencySpace + formatted
        } else {
            body = formatted + table.currencySpace + table.currencySymbol
        }
        return value < 0 ? "-" + body : body
    }

    private func _ordinal(_ value: Double, table: LocaleTable) -> String {
        let negative = value < 0
        let integer = abs(Int(value.rounded(.towardZero)))
        let grouped = _grouped(String(integer), separator: table.grouping, enabled: table.groupOrdinal)
        let stem: String
        switch table.ordinal {
        case .english:
            let mod100 = integer % 100
            let mod10 = integer % 10
            if mod100 >= 11 && mod100 <= 13 {
                stem = grouped + "th"
            } else if mod10 == 1 {
                stem = grouped + "st"
            } else if mod10 == 2 {
                stem = grouped + "nd"
            } else if mod10 == 3 {
                stem = grouped + "rd"
            } else {
                stem = grouped + "th"
            }
        case .german:
            stem = grouped + "."
        case .french:
            stem = grouped + (integer == 1 ? "er" : "e")
        case .japanese:
            return "第" + (negative ? "\u{2212}" : "") + grouped
        }
        return negative ? "\u{2212}" + stem : stem
    }

    private func _format(
        _ value: Double,
        table: LocaleTable,
        minFrac: Int,
        maxFrac: Int,
        grouping: Bool
    ) -> String {
        let rounded = _round(value, digits: maxFrac, mode: roundingMode)
        let negative = rounded < 0
        let magnitude = abs(rounded)
        let factor = _power10(maxFrac)
        let scaled = (magnitude * Double(factor)).rounded(.toNearestOrAwayFromZero)
        var scaledInt = UInt64(scaled)
        if maxFrac == 0 {
            scaledInt = UInt64(magnitude.rounded(.toNearestOrAwayFromZero))
        }
        let divisor = UInt64(max(factor, 1))
        let whole = maxFrac == 0 ? scaledInt : scaledInt / divisor
        let fraction = maxFrac == 0 ? 0 : scaledInt % divisor
        var fractionText = ""
        if maxFrac > 0 {
            fractionText = String(fraction)
            if fractionText.count < maxFrac {
                fractionText = String(repeating: "0", count: maxFrac - fractionText.count) + fractionText
            }
            while fractionText.count > minFrac, fractionText.last == "0" {
                fractionText.removeLast()
            }
        } else if minFrac > 0 {
            fractionText = String(repeating: "0", count: minFrac)
        }
        var result = _grouped(String(whole), separator: table.grouping, enabled: usesGroupingSeparator && grouping)
        if !fractionText.isEmpty {
            result += table.decimal + fractionText
        }
        if negative { result = "-" + result }
        return result
    }

    private func _round(_ value: Double, digits: Int, mode: RoundingMode) -> Double {
        let factor = Double(_power10(digits))
        let scaled = value * factor
        let rounded: Double
        switch mode {
        case .ceiling: rounded = scaled.rounded(.up)
        case .floor: rounded = scaled.rounded(.down)
        case .down: rounded = scaled.rounded(.towardZero)
        case .up: rounded = scaled.rounded(.awayFromZero)
        case .halfEven: rounded = scaled.rounded(.toNearestOrEven)
        case .halfUp: rounded = scaled.rounded(.toNearestOrAwayFromZero)
        case .halfDown:
            let sign: Double = scaled < 0 ? -1 : 1
            let mag = abs(scaled)
            let ip = mag.rounded(.towardZero)
            let frac = mag - ip
            if frac < 0.5 {
                rounded = sign * ip
            } else if frac > 0.5 {
                rounded = sign * (ip + 1)
            } else {
                rounded = sign * ip
            }
        }
        return rounded / factor
    }

    private func _grouped(_ digits: String, separator: String, enabled: Bool) -> String {
        guard enabled, groupingSize > 0 else { return digits }
        var output = ""
        for (index, character) in digits.enumerated() {
            if index > 0 && (digits.count - index).isMultiple(of: groupingSize) {
                output += separator
            }
            output.append(character)
        }
        return output
    }

    private func _power10(_ exponent: Int) -> Int {
        var result = 1
        if exponent > 0 {
            for _ in 0..<exponent { result *= 10 }
        }
        return result
    }
}
