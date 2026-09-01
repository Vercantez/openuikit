// Portable Foundation byte-count formatting for Linux-hosted Mach-O guests.
//
// The implementation follows the observable Darwin contract: file/decimal
// styles use powers of 1000, memory/binary styles use powers of 1024, default
// unit selection is adaptive, explicit unit masks constrain selection, and
// count/unit/actual-byte presentation flags compose without hidden host state.

import ObjectiveC

open class ByteCountFormatter: ObjectiveC.NSObject, @unchecked Sendable {
    public struct Units: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let useBytes = Units(rawValue: 1 << 0)
        public static let useKB = Units(rawValue: 1 << 1)
        public static let useMB = Units(rawValue: 1 << 2)
        public static let useGB = Units(rawValue: 1 << 3)
        public static let useTB = Units(rawValue: 1 << 4)
        public static let usePB = Units(rawValue: 1 << 5)
        public static let useEB = Units(rawValue: 1 << 6)
        public static let useZB = Units(rawValue: 1 << 7)
        public static let useYBOrHigher = Units(rawValue: 0xff << 8)
        public static let useAll = Units(rawValue: 0xffff)

        @available(*, unavailable, message: "use [] to construct an empty option set")
        public static var useDefault: Units { [] }
    }

    public enum CountStyle: UInt, Sendable {
        case file = 0
        case memory = 1
        case decimal = 2
        case binary = 3
    }

    open var allowedUnits: Units = []
    open var countStyle: CountStyle = .file
    open var allowsNonnumericFormatting = true
    open var includesActualByteCount = false
    open var includesCount = true
    open var includesUnit = true
    open var isAdaptive = true
    open var zeroPadsFractionDigits = false

    public override init() {
        super.init()
    }

    open class func string(
        fromByteCount byteCount: Int64,
        countStyle: CountStyle
    ) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = countStyle
        return formatter.string(fromByteCount: byteCount)
    }

    open func string(fromByteCount byteCount: Int64) -> String {
        let base = _base
        let unit = _selectedUnit(for: byteCount, base: base)
        let divisor = _power(base, exponent: unit)
        let magnitude = byteCount < 0 ? -Double(byteCount) : Double(byteCount)
        let signedCount = byteCount < 0 ? -(magnitude / divisor) : magnitude / divisor
        let count = _formattedCount(signedCount, unit: unit)
        let unitName = _unitName(unit, byteCount: byteCount)

        var result = ""
        if includesCount {
            if allowsNonnumericFormatting && byteCount == 0 {
                result = "Zero"
            } else {
                result = count
            }
        }
        if includesUnit {
            if !result.isEmpty { result += " " }
            result += unitName
        }
        if includesActualByteCount && includesCount && includesUnit {
            result += " (\(_groupedInteger(byteCount)) bytes)"
        }
        return result
    }

    open func string(for object: Any?) -> String? {
        switch object {
        case let value as NSNumber:
            return string(fromByteCount: value.int64Value)
        case let value as Int64:
            return string(fromByteCount: value)
        case let value as Int:
            return string(fromByteCount: Int64(value))
        case let value as Int32:
            return string(fromByteCount: Int64(value))
        case let value as UInt64:
            return string(fromByteCount: Int64(clamping: value))
        case let value as UInt:
            return string(fromByteCount: Int64(clamping: value))
        default:
            return nil
        }
    }

    private var _base: Double {
        switch countStyle {
        case .file, .decimal: return 1_000
        case .memory, .binary: return 1_024
        }
    }

    private func _selectedUnit(for byteCount: Int64, base: Double) -> Int {
        let allowed = _allowedUnitIndices
        let magnitude = byteCount < 0 ? -Double(byteCount) : Double(byteCount)
        var preferred = 0
        if magnitude == 0 {
            preferred = 1
        } else {
            while preferred < 8 {
                let scaled = magnitude / _power(base, exponent: preferred)
                let digits = _fractionDigitCount(magnitude: scaled, unit: preferred)
                let factor = _power(10, exponent: digits)
                let rounded = (scaled * factor)
                    .rounded(.toNearestOrAwayFromZero) / factor
                guard rounded >= base else { break }
                preferred += 1
            }
        }

        if allowed.contains(preferred) { return preferred }
        if let lower = allowed.last(where: { $0 < preferred }) { return lower }
        return allowed.first ?? preferred
    }

    private var _allowedUnitIndices: [Int] {
        if allowedUnits.isEmpty || allowedUnits == .useAll {
            return Array(0...8)
        }
        var result: [Int] = []
        for index in 0...7 where allowedUnits.rawValue & (1 << UInt(index)) != 0 {
            result.append(index)
        }
        if allowedUnits.rawValue & Units.useYBOrHigher.rawValue != 0 {
            result.append(8)
        }
        return result
    }

    private func _formattedCount(_ value: Double, unit: Int) -> String {
        let magnitude = value < 0 ? -value : value
        let digits = _fractionDigitCount(magnitude: magnitude, unit: unit)

        let factor = _power(10, exponent: digits)
        let rounded = (value * factor).rounded(.toNearestOrAwayFromZero)
        let negative = rounded < 0
        let absoluteScaled = negative ? -rounded : rounded
        let scaledInteger: UInt64
        if absoluteScaled >= Double(UInt64.max) {
            scaledInteger = UInt64.max
        } else {
            scaledInteger = UInt64(absoluteScaled)
        }
        let divisor = _integerPowerOfTen(digits)
        let whole = scaledInteger / divisor
        let fraction = scaledInteger % divisor
        var result = (negative ? "-" : "") + _groupedUnsigned(whole)
        if digits > 0 && (zeroPadsFractionDigits || fraction != 0) {
            var fractionText = String(fraction)
            if fractionText.count < digits {
                fractionText = String(repeating: "0", count: digits - fractionText.count) + fractionText
            }
            if !zeroPadsFractionDigits {
                while fractionText.last == "0" { fractionText.removeLast() }
            }
            if !fractionText.isEmpty { result += "." + fractionText }
        }
        return result
    }

    private func _fractionDigitCount(magnitude: Double, unit: Int) -> Int {
        if isAdaptive {
            return unit <= 1 ? 0 : (magnitude < 10 ? 1 : 0)
        } else if magnitude < 10 {
            return 2
        } else if magnitude < 100 {
            return 1
        } else {
            return 0
        }
    }

    private func _unitName(_ unit: Int, byteCount: Int64) -> String {
        if unit == 0 { return byteCount == 1 || byteCount == -1 ? "byte" : "bytes" }
        return ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"][unit]
    }

    private func _power(_ base: Double, exponent: Int) -> Double {
        var result = 1.0
        if exponent > 0 {
            for _ in 0..<exponent { result *= base }
        }
        return result
    }

    private func _integerPowerOfTen(_ exponent: Int) -> UInt64 {
        var result: UInt64 = 1
        if exponent > 0 {
            for _ in 0..<exponent { result *= 10 }
        }
        return result
    }

    private func _groupedInteger(_ value: Int64) -> String {
        if value < 0 {
            let magnitude = UInt64(bitPattern: -(value + 1)) + 1
            return "-" + _groupedUnsigned(magnitude)
        }
        return _groupedUnsigned(UInt64(value))
    }

    private func _groupedUnsigned(_ value: UInt64) -> String {
        let digits = String(value)
        var output = ""
        for (index, character) in digits.enumerated() {
            if index > 0 && (digits.count - index).isMultiple(of: 3) {
                output.append(",")
            }
            output.append(character)
        }
        return output
    }
}
