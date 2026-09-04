// Harness, not app source: the `ByteCountFormatter` the vendored
// SizeFormatter.swift resolves to when OpenUIKit is the host.
//
// Why it exists: the Linux-hosted arm64-apple-macos GUEST route compiles the
// real-app harness against the port's own Foundation, which has no
// `ByteCountFormatter` (both authorities' build_full failed on it from
// 4a5bbe00 to 9a7319c2). A type declared in this module shadows the imported
// one, so the vendored file keeps its exact upstream text and, on Apple's
// or corelibs' Foundation, simply uses this port instead.
//
// The logic is the monorepo's reviewed portable implementation
// (full/foundation/ByteCountFormatter.swift, "follows the observable Darwin
// contract"), minus its NSObject base and `string(for:)`, so it compiles on
// every route. The real-UIKit oracle (scripts/realapp_probe_sim.sh) does
// NOT compile this file — it lists its sources explicitly — so the goldens
// still come from Apple's formatter. Only the placeholder (0 bytes) reaches
// the screen today: iOS 26.1 renders it "0 bytes" (the golden's label), and
// the monorepo logic said "0 KB" there — the storage screen fell from
// 99.408 to 99.353 until the zero rule below was read off the golden.

public final class ByteCountFormatter {
    public struct Units: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let useBytes = Units(rawValue: 1 << 0)
        public static let useKB = Units(rawValue: 1 << 1)
        public static let useMB = Units(rawValue: 1 << 2)
        public static let useGB = Units(rawValue: 1 << 3)
        public static let useTB = Units(rawValue: 1 << 4)
        public static let usePB = Units(rawValue: 1 << 5)
        public static let useEB = Units(rawValue: 1 << 6)
        public static let useZB = Units(rawValue: 1 << 7)
        public static let useYBOrHigher = Units(rawValue: 0x0FF << 8)
        public static let useAll = Units(rawValue: 0x0FFFF)
    }

    public enum CountStyle: Int, Sendable {
        case file = 0, memory, decimal, binary
    }

    public var allowedUnits: Units = []
    public var countStyle: CountStyle = .file
    public var allowsNonnumericFormatting = true
    public var includesActualByteCount = false
    public var includesCount = true
    public var includesUnit = true
    public var isAdaptive = true
    public var zeroPadsFractionDigits = false

    public init() {}

    public static func string(fromByteCount byteCount: Int64, countStyle: CountStyle) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = countStyle
        return formatter.string(fromByteCount: byteCount)
    }

    public func string(fromByteCount byteCount: Int64) -> String {
        let base = _base
        let unit = _selectedUnit(for: byteCount, base: base)
        let divisor = _power(base, exponent: unit)
        let magnitude = byteCount < 0 ? -Double(byteCount) : Double(byteCount)
        let signedCount = byteCount < 0 ? -(magnitude / divisor) : magnitude / divisor
        let count = _formattedCount(signedCount, unit: unit)
        let unitName = _unitName(unit, byteCount: byteCount)
        var result = ""
        if includesCount {
            result = (allowsNonnumericFormatting && byteCount == 0) ? "Zero" : count
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
            // Measured: Darwin says "Zero KB" for 0 with nonnumeric formatting
            // (full/foundation/tests/foundation-byte-count-apple-2026-08-31.txt,
            // static.*.0) but "0 bytes" with it off and every unit allowed —
            // the Pocket Casts storage screen's placeholder on iOS 26.1
            // (/tmp/golden_realapp_ios/realapp_storage_light.layout.json,
            // "0 bytes"). "0 KB" (forced-kb.0) is the allowed-units floor.
            preferred = allowsNonnumericFormatting ? 1 : 0
        } else {
            while preferred < 8 {
                let scaled = magnitude / _power(base, exponent: preferred)
                let digits = _fractionDigitCount(magnitude: scaled, unit: preferred)
                let factor = _power(10, exponent: digits)
                let rounded = (scaled * factor).rounded(.toNearestOrAwayFromZero) / factor
                guard rounded >= base else { break }
                preferred += 1
            }
        }
        if allowed.contains(preferred) { return preferred }
        if let lower = allowed.last(where: { $0 < preferred }) { return lower }
        return allowed.first ?? preferred
    }

    private var _allowedUnitIndices: [Int] {
        if allowedUnits.isEmpty || allowedUnits == .useAll { return Array(0...8) }
        var result: [Int] = []
        for index in 0...7 where allowedUnits.rawValue & (1 << UInt(index)) != 0 {
            result.append(index)
        }
        if allowedUnits.rawValue & Units.useYBOrHigher.rawValue != 0 { result.append(8) }
        return result
    }

    private func _formattedCount(_ value: Double, unit: Int) -> String {
        let magnitude = value < 0 ? -value : value
        let digits = _fractionDigitCount(magnitude: magnitude, unit: unit)
        let factor = _power(10, exponent: digits)
        let rounded = (value * factor).rounded(.toNearestOrAwayFromZero)
        let negative = rounded < 0
        let absoluteScaled = negative ? -rounded : rounded
        let scaledInteger: UInt64 = absoluteScaled >= Double(UInt64.max) ? UInt64.max : UInt64(absoluteScaled)
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
        if isAdaptive { return unit <= 1 ? 0 : (magnitude < 10 ? 1 : 0) }
        if magnitude < 10 { return 2 }
        if magnitude < 100 { return 1 }
        return 0
    }

    private func _unitName(_ unit: Int, byteCount: Int64) -> String {
        if unit == 0 { return byteCount == 1 || byteCount == -1 ? "byte" : "bytes" }
        return ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"][unit]
    }

    private func _power(_ base: Double, exponent: Int) -> Double {
        var result = 1.0
        if exponent > 0 { for _ in 0..<exponent { result *= base } }
        return result
    }

    private func _integerPowerOfTen(_ exponent: Int) -> UInt64 {
        var result: UInt64 = 1
        if exponent > 0 { for _ in 0..<exponent { result *= 10 } }
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
            if index > 0 && (digits.count - index).isMultiple(of: 3) { output.append(",") }
            output.append(character)
        }
        return output
    }
}
