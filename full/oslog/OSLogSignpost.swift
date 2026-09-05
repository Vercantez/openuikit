// OSSignpostID / OSSignposter / os_signpost. Records `OSLogEntrySignpost`
// into the in-process ring.
//
// Probe 2 on OpenUIKit-2x-fw-oslog / iOS 26.1 SE, 2026-09-05: Apple's
// `OSLogStore` returned 0 `OSLogEntrySignpost` / `eventType == signpostEvent`
// rows for `OSSignposter.beginInterval` / `emitEvent` / `endInterval` within
// 0.4 s. The port still records them so `getEntries` can return signpost
// subclasses the public surface names.
//
// Signpost ID constants (same probe): exclusive=0xEEEEB0B5B2B2EEEE,
// invalid=UInt64.max, null=0. `makeSignpostID()` first value was 1.
// Sibling `uikit/Sources/os` swaps invalid/null — do not edit that file.

import Foundation

public struct OSSignpostType: Equatable, RawRepresentable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let event = OSSignpostType(rawValue: 0)
    public static let begin = OSSignpostType(rawValue: 1)
    public static let end = OSSignpostType(rawValue: 2)
}

public struct OSSignpostID: Equatable, Hashable, Sendable {
    public let rawValue: UInt64

    /// Probe 2026-09-05: 17216892719917625070 == 0xEEEEB0B5B2B2EEEE.
    public static let exclusive = OSSignpostID(rawValue: 0xEEEEB0B5B2B2EEEE)
    /// Probe 2026-09-05: `OSSignpostID.invalid.rawValue == UInt64.max`.
    public static let invalid = OSSignpostID(rawValue: UInt64.max)
    /// Probe 2026-09-05: `OSSignpostID.null.rawValue == 0`.
    public static let null = OSSignpostID(rawValue: 0)

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public init(log: OSLog) {
        _ = log
        self.rawValue = OSSignpostID.next()
    }

    public init(log: OSLog, object: AnyObject) {
        _ = log
        self.rawValue = OSSignpostID.id(for: object)
    }

    private static let lock = NSLock()
    private static var sequence: UInt64 = 1
    private static var objects: [ObjectIdentifier: UInt64] = [:]

    static func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        var value = sequence
        sequence += 1
        if value == exclusive.rawValue || value == invalid.rawValue || value == null.rawValue {
            value = sequence
            sequence += 1
        }
        return value
    }

    static func id(for object: AnyObject) -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(object)
        if let existing = objects[key] { return existing }
        var value = sequence
        sequence += 1
        if value == exclusive.rawValue || value == invalid.rawValue || value == null.rawValue {
            value = sequence
            sequence += 1
        }
        objects[key] = value
        return value
    }
}

public class OSSignpostIntervalState: NSObject {
    let name: String
    let id: OSSignpostID
    let subsystem: String
    let category: String

    init(name: String, id: OSSignpostID, subsystem: String, category: String) {
        self.name = name
        self.id = id
        self.subsystem = subsystem
        self.category = category
        super.init()
    }
}

public struct OSSignposter: Sendable {
    public let subsystem: String
    public let category: String

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public init(logHandle: OSLog) {
        self.subsystem = logHandle.subsystem
        self.category = logHandle.category
    }

    public func makeSignpostID() -> OSSignpostID {
        OSSignpostID(rawValue: OSSignpostID.next())
    }

    public func beginInterval(
        _ name: StaticString,
        id: OSSignpostID = .exclusive
    ) -> OSSignpostIntervalState {
        beginInterval(name, id: id, OSLogMessage(stringLiteral: ""))
    }

    public func beginInterval(
        _ name: StaticString,
        id: OSSignpostID = .exclusive,
        _ message: OSLogMessage
    ) -> OSSignpostIntervalState {
        let text = staticStringText(name)
        record(name: text, type: .intervalBegin, id: id, message: message)
        return OSSignpostIntervalState(
            name: text,
            id: id,
            subsystem: subsystem,
            category: category
        )
    }

    public func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        _ = name
        record(
            name: state.name,
            type: .intervalEnd,
            id: state.id,
            message: OSLogMessage(stringLiteral: "")
        )
    }

    public func emitEvent(_ name: StaticString, id: OSSignpostID = .exclusive) {
        emitEvent(name, id: id, OSLogMessage(stringLiteral: ""))
    }

    public func emitEvent(
        _ name: StaticString,
        id: OSSignpostID = .exclusive,
        _ message: OSLogMessage
    ) {
        record(name: staticStringText(name), type: .event, id: id, message: message)
    }

    private func record(
        name: String,
        type: OSLogEntrySignpost.SignpostType,
        id: OSSignpostID,
        message: OSLogMessage
    ) {
        let composed = message.composedMessage.isEmpty ? name : message.composedMessage
        let format = message.formatString.isEmpty ? name : message.formatString
        OSLogRecord.signpost(
            subsystem: subsystem,
            category: category,
            name: name,
            type: type,
            identifier: id.rawValue,
            composedMessage: composed,
            formatString: format,
            components: message.components
        )
    }
}

public func os_signpost_enabled(_ log: OSLog) -> Bool {
    log != .disabled
}

public func os_signpost(
    _ type: OSSignpostType,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive
) {
    os_signpost(type, dso: dso, log: log, name: name, signpostID: signpostID, "%s", "")
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
    _ = dso
    if log == .disabled { return }
    let built = OSLogCFormat.apply(format: staticStringText(format), args: arguments)
    let mapped: OSLogEntrySignpost.SignpostType
    switch type {
    case .begin: mapped = .intervalBegin
    case .end: mapped = .intervalEnd
    default: mapped = .event
    }
    OSLogRecord.signpost(
        subsystem: log.subsystem,
        category: log.category,
        name: staticStringText(name),
        type: mapped,
        identifier: signpostID.rawValue,
        composedMessage: built.composed,
        formatString: built.format,
        components: built.components
    )
}
