// os_signpost no-ops. Measured scratch/ladder-corpus 2026-09-05:
//   * os_signpost(.begin/.end, log:name:signpostID:format, args…)
//     DuckDuckGo Core/Instruments.swift:46–63 (import os.signpost;
//     OSLog + OSSignpostID(log:) + format "Event: %@ info: %@")
//   * OSSignposter / OSSignpostID — Telegram StorageUsageScreen,
//     NetNewsWire ArticlesTable (not required by the brief's named
//     surface; the function + ID + type cover the os_signpost call).

public struct OSSignpostType: Equatable, RawRepresentable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let event = OSSignpostType(rawValue: 0)
    public static let begin = OSSignpostType(rawValue: 1)
    public static let end = OSSignpostType(rawValue: 2)
}

public struct OSSignpostID: Equatable, Hashable, Sendable {
    public let rawValue: UInt64

    public static let exclusive = OSSignpostID(rawValue: 0xEEEEB0B5B2B2EEEE)
    public static let invalid = OSSignpostID(rawValue: 0)
    public static let null = OSSignpostID(rawValue: UInt64.max)

    public init(log: OSLog) {
        _ = log
        self.rawValue = 1
    }

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public func os_signpost(
    _ type: OSSignpostType,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive
) {
    _ = (type, dso, log, name, signpostID)
}

public func os_signpost(
    _ type: OSSignpostType,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive,
    _ format: StaticString,
    _ arguments: CVarArg...
) {
    _ = (type, dso, log, name, signpostID, format, arguments)
}
