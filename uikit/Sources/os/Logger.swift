// Logger + privacy interpolation for the 20-app ladder corpus.
//
// Measured scratch/ladder-corpus 2026-09-05, 13 apps `import os`:
//   * Logger(subsystem:category:) — NetNewsWire, DuckDuckGo, Hackers
//     PostRepository+Parsing, WordPress Tracks, MastodonSDK
//   * Logger() — Pocket Casts FileLog/TracksAdapter, nextcloud NCShareCells
//   * methods: .log (787) .info (499) .debug (336) .error (206)
//     .warning (51) .notice (6) .fault (2); also .log(level: .error, …)
//     (WordPress CustomPostSettingsViewModel)
//   * interpolation privacy: .public (451) .private (3)
//     e.g. NetNewsWire Account.swift
//     `\(error.localizedDescription, privacy: .public)`
// Messages are accepted and ignored.

public struct OSLogPrivacy: Equatable, Sendable {
    public static let `public` = OSLogPrivacy()
    public static let `private` = OSLogPrivacy()
    public static let sensitive = OSLogPrivacy()
    public static let auto = OSLogPrivacy()
    public init() {}
}

public struct OSLogInterpolation: StringInterpolationProtocol {
    public init(literalCapacity: Int, interpolationCount: Int) {
        _ = (literalCapacity, interpolationCount)
    }

    public mutating func appendLiteral(_ literal: String) {
        _ = literal
    }

    public mutating func appendInterpolation<T>(_ value: T) {
        _ = value
    }

    public mutating func appendInterpolation<T>(_ value: T, privacy: OSLogPrivacy) {
        _ = (value, privacy)
    }

    public mutating func appendInterpolation(_ value: Error, privacy: OSLogPrivacy) {
        _ = (value, privacy)
    }

    // Formatted numbers (iPhoneSimulator26.1.sdk os.swiftinterface): the value
    // is an autoclosure, as in Apple's declaration; messages are discarded here
    // so it is never evaluated. NetNewsWire FMDatabase+Extras.swift:43
    // `\(duration, format: .fixed(precision: 4), privacy: .public)`.
    // `format:` carries no default here (Apple's does): with a default these
    // would compete with the generic privacy-only overload above.
    public mutating func appendInterpolation(
        _ number: @autoclosure @escaping () -> Double, format: OSLogFloatFormatting,
        align: OSLogStringAlignment = .none, privacy: OSLogPrivacy = .auto
    ) {
        _ = (number, format, align, privacy)
    }

    public mutating func appendInterpolation(
        _ number: @autoclosure @escaping () -> Float, format: OSLogFloatFormatting,
        align: OSLogStringAlignment = .none, privacy: OSLogPrivacy = .auto
    ) {
        _ = (number, format, align, privacy)
    }

    public mutating func appendInterpolation<T: FixedWidthInteger>(
        _ number: @autoclosure @escaping () -> T, format: OSLogIntegerFormatting,
        align: OSLogStringAlignment = .none, privacy: OSLogPrivacy = .auto
    ) {
        _ = (number, format, align, privacy)
    }
}

/// Apple's float format specifier (`%f` / `%e` / `%g` / `%a` family).
public struct OSLogFloatFormatting {
    public enum Notation: Sendable { case hex, fixed, exponential, hybrid }
    public let notation: Notation
    public let precision: (() -> Int)?
    public let explicitPositiveSign: Bool
    public let uppercase: Bool

    init(_ notation: Notation, precision: (() -> Int)?, explicitPositiveSign: Bool, uppercase: Bool) {
        self.notation = notation
        self.precision = precision
        self.explicitPositiveSign = explicitPositiveSign
        self.uppercase = uppercase
    }

    public static var fixed: OSLogFloatFormatting { .fixed() }
    public static func fixed(precision: @autoclosure @escaping () -> Int, explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.fixed, precision: precision, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static func fixed(explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.fixed, precision: nil, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static var hex: OSLogFloatFormatting { .hex() }
    public static func hex(explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.hex, precision: nil, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static var exponential: OSLogFloatFormatting { .exponential() }
    public static func exponential(precision: @autoclosure @escaping () -> Int, explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.exponential, precision: precision, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static func exponential(explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.exponential, precision: nil, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static var hybrid: OSLogFloatFormatting { .hybrid() }
    public static func hybrid(precision: @autoclosure @escaping () -> Int, explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.hybrid, precision: precision, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
    public static func hybrid(explicitPositiveSign: Bool = false, uppercase: Bool = false) -> OSLogFloatFormatting {
        .init(.hybrid, precision: nil, explicitPositiveSign: explicitPositiveSign, uppercase: uppercase)
    }
}

/// Apple's integer format specifier (`%d` / `%x` / `%o` family).
public struct OSLogIntegerFormatting {
    public let radix: Int
    public let explicitPositiveSign: Bool
    public let includePrefix: Bool
    public let uppercase: Bool
    public let minDigits: (() -> Int)?

    init(radix: Int, explicitPositiveSign: Bool, includePrefix: Bool, uppercase: Bool, minDigits: (() -> Int)?) {
        self.radix = radix
        self.explicitPositiveSign = explicitPositiveSign
        self.includePrefix = includePrefix
        self.uppercase = uppercase
        self.minDigits = minDigits
    }

    public static func decimal(explicitPositiveSign: Bool = false, minDigits: @autoclosure @escaping () -> Int) -> OSLogIntegerFormatting {
        .init(radix: 10, explicitPositiveSign: explicitPositiveSign, includePrefix: false, uppercase: false, minDigits: minDigits)
    }
    public static func decimal(explicitPositiveSign: Bool = false) -> OSLogIntegerFormatting {
        .init(radix: 10, explicitPositiveSign: explicitPositiveSign, includePrefix: false, uppercase: false, minDigits: nil)
    }
    public static var decimal: OSLogIntegerFormatting { .decimal() }
    public static func hex(explicitPositiveSign: Bool = false, includePrefix: Bool = false, uppercase: Bool = false, minDigits: @autoclosure @escaping () -> Int) -> OSLogIntegerFormatting {
        .init(radix: 16, explicitPositiveSign: explicitPositiveSign, includePrefix: includePrefix, uppercase: uppercase, minDigits: minDigits)
    }
    public static func hex(explicitPositiveSign: Bool = false, includePrefix: Bool = false, uppercase: Bool = false) -> OSLogIntegerFormatting {
        .init(radix: 16, explicitPositiveSign: explicitPositiveSign, includePrefix: includePrefix, uppercase: uppercase, minDigits: nil)
    }
    public static var hex: OSLogIntegerFormatting { .hex() }
    public static func octal(explicitPositiveSign: Bool = false, includePrefix: Bool = false, uppercase: Bool = false, minDigits: @autoclosure @escaping () -> Int) -> OSLogIntegerFormatting {
        .init(radix: 8, explicitPositiveSign: explicitPositiveSign, includePrefix: includePrefix, uppercase: uppercase, minDigits: minDigits)
    }
    public static func octal(explicitPositiveSign: Bool = false, includePrefix: Bool = false, uppercase: Bool = false) -> OSLogIntegerFormatting {
        .init(radix: 8, explicitPositiveSign: explicitPositiveSign, includePrefix: includePrefix, uppercase: uppercase, minDigits: nil)
    }
    public static var octal: OSLogIntegerFormatting { .octal() }
}

/// Apple's column alignment for an interpolated value.
public struct OSLogStringAlignment {
    public enum Anchor: Sendable { case start, end }
    public let minimumColumnWidth: (() -> Int)?
    public let anchor: Anchor

    init(minimumColumnWidth: (() -> Int)?, anchor: Anchor) {
        self.minimumColumnWidth = minimumColumnWidth
        self.anchor = anchor
    }

    public static var none: OSLogStringAlignment { .init(minimumColumnWidth: nil, anchor: .end) }
    public static func right(columns: @autoclosure @escaping () -> Int) -> OSLogStringAlignment {
        .init(minimumColumnWidth: columns, anchor: .end)
    }
    public static func left(columns: @autoclosure @escaping () -> Int) -> OSLogStringAlignment {
        .init(minimumColumnWidth: columns, anchor: .start)
    }
}

public struct OSLogMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        _ = value
    }

    public init(stringInterpolation: OSLogInterpolation) {
        _ = stringInterpolation
    }
}

public struct Logger: Sendable {
    public let subsystem: String
    public let category: String

    // Pocket Casts FileLog.swift:28, TracksAdapter.swift:245, AnalyticsHelper.swift:442;
    // nextcloud NCShareCells.swift:252.
    public init() {
        self.subsystem = ""
        self.category = ""
    }

    // Hackers Data PostRepository+Parsing.swift:14 (subsystem + category);
    // NetNewsWire Account.swift:94; DuckDuckGo Logger+Multiple.swift.
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func log(_ message: OSLogMessage) { _ = message }
    public func log(level: OSLogType, _ message: OSLogMessage) { _ = (level, message) }
    public func trace(_ message: OSLogMessage) { _ = message }
    public func debug(_ message: OSLogMessage) { _ = message }
    public func info(_ message: OSLogMessage) { _ = message }
    public func notice(_ message: OSLogMessage) { _ = message }
    public func warning(_ message: OSLogMessage) { _ = message }
    public func error(_ message: OSLogMessage) { _ = message }
    public func fault(_ message: OSLogMessage) { _ = message }
    public func critical(_ message: OSLogMessage) { _ = message }
}
