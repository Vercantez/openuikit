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
