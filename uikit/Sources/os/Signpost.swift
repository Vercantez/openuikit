// os_signpost / OSSignposter no-ops. Measured scratch/ladder-corpus 2026-09-05:
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
    // MEASURED Tools/oracle2/signposterprobe: invalid = ~0, null = 0.
    public static let invalid = OSSignpostID(rawValue: UInt64.max)
    public static let null = OSSignpostID(rawValue: 0)

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

// OSSignposter (NetNewsWire ArticlesTable.swift:28/767/771/777). Declarations
// follow iPhoneSimulator26.1.sdk os.swiftinterface; MEASURED values in
// Tools/oracle2/signposterprobe/transcript-macos.txt: isEnabled is true for
// any log but OSLog.disabled, makeSignpostID returns distinct valid IDs,
// withIntervalSignpost returns its task's value. Nothing is recorded.

extension OSLog {
    public struct Category: Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let pointsOfInterest = Category(rawValue: "PointsOfInterest")
        public static let dynamicTracing = Category(rawValue: "DynamicTracing")
        public static let dynamicStackTracing = Category(rawValue: "DynamicStackTracing")
    }

    public init(subsystem: String, category: Category) {
        self.init(subsystem: subsystem, category: category.rawValue)
    }
}

public typealias SignpostMetadata = OSLogMessage

// On Darwin the port's `os` module loads next to Apple's libswiftos, whose
// OSSignpostIntervalState has the same mangled name (_TtC2os23…); a second
// class under that runtime name makes objc warn "implemented in both … may
// cause spurious casting failures". Give ours a distinct runtime name.
#if canImport(ObjectiveC)
@_objcRuntimeName(_TtC2os32OpenUIKitOSSignpostIntervalState)
#endif
public final class OSSignpostIntervalState: @unchecked Sendable {
    public let signpostID: OSSignpostID
    init(id: OSSignpostID) { self.signpostID = id }
}

public struct OSSignposter: @unchecked Sendable {
    private let log: OSLog
    private static let counter = OSAllocatedUnfairLock(initialState: UInt64(0))

    public init(subsystem: String, category: String) { log = OSLog(subsystem: subsystem, category: category) }
    public init(subsystem: String, category: OSLog.Category) { log = OSLog(subsystem: subsystem, category: category) }
    public init() { log = .default }
    public init(logHandle: OSLog) { log = logHandle }
    public init(logger: Logger) { log = OSLog(subsystem: logger.subsystem, category: logger.category) }

    public var isEnabled: Bool { log != .disabled }

    public func emitEvent(_ name: StaticString, id: OSSignpostID = .exclusive, _ message: SignpostMetadata) {
        _ = (name, id, message)
    }
    public func emitEvent(_ name: StaticString, id: OSSignpostID = .exclusive) { _ = (name, id) }

    public func beginInterval(_ name: StaticString, id: OSSignpostID = .exclusive, _ message: SignpostMetadata) -> OSSignpostIntervalState {
        _ = (name, message)
        return OSSignpostIntervalState(id: id)
    }
    public func beginInterval(_ name: StaticString, id: OSSignpostID = .exclusive) -> OSSignpostIntervalState {
        _ = name
        return OSSignpostIntervalState(id: id)
    }
    public func beginAnimationInterval(_ name: StaticString, id: OSSignpostID = .exclusive) -> OSSignpostIntervalState {
        beginInterval(name, id: id)
    }
    public func beginAnimationInterval(_ name: StaticString, id: OSSignpostID = .exclusive, _ message: SignpostMetadata) -> OSSignpostIntervalState {
        beginInterval(name, id: id, message)
    }

    public func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState, _ message: SignpostMetadata) {
        _ = (name, state, message)
    }
    public func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) { _ = (name, state) }

    public func withIntervalSignpost<T>(_ name: StaticString, id: OSSignpostID = .exclusive, _ message: SignpostMetadata, around task: () throws -> T) rethrows -> T {
        _ = (name, id, message)
        return try task()
    }
    public func withIntervalSignpost<T>(_ name: StaticString, id: OSSignpostID = .exclusive, around task: () throws -> T) rethrows -> T {
        _ = (name, id)
        return try task()
    }

    public func makeSignpostID() -> OSSignpostID {
        // Distinct and never one of the three sentinels.
        OSSignpostID(rawValue: Self.counter.withLock { $0 += 1; return $0 })
    }
    public func makeSignpostID(from object: AnyObject) -> OSSignpostID {
        OSSignpostID(rawValue: UInt64(UInt(bitPattern: ObjectIdentifier(object).hashValue)))
    }
}
