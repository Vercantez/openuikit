//===----------------------------------------------------------------------===//
//
// ### THIS IS OURS.  IT IS NOT APPLE'S `os` OVERLAY. ###
//
// Written in this repository, named `os` only because upstream's source
// imports that name, and it implements the measured logging, signpost, and
// locking declarations below out of a module that has dozens.  **Its silence
// about everything else -- `os_activity`, `OSLogPrivacy`'s mask and format
// options, the whole `os_workgroup` family -- is a SCOPE STATEMENT, not an
// implementation choice.**  If something fails to compile against this module,
// the conclusion is almost always "that part of `os` was never provided here",
// not "the overlay is broken".  Add what you need, and extend the measured
// list below when you do, so the next reader still knows what is covered.
//
// `os` -- the smallest module that makes upstream's Darwin branch mean here
// what it means on Darwin.  Provided, not faked: every declaration below is
// backed by something that exists at runtime, and the one thing that does not
// exist (the unified log) is replaced by a visible fallback rather than a
// no-op.
//
// WHY THIS EXISTS, measured rather than assumed.  Route (A) (full/sdk-gaps
// RULING) makes `canImport(Darwin)` TRUE, and in swift-foundation 6.2.2's
// FoundationEssentials that turns 14 `internal import os` sites live.  Sorted
// by the conditional that guards them:
//
//   #if canImport(Darwin)   Calendar/Calendar.swift, String/String+Path.swift
//                           -- 2 files, NO os-less fallback branch.  They
//                           reference nothing from os at all: upstream uses
//                           `import os` here purely as the Darwin spelling of
//                           "pull in the C library".
//   #if canImport(os)       LockedState.swift, Calendar/Calendar_Gregorian.swift,
//                           URL/URL.swift (+ two files this port excludes).
//                           These have real fallback branches.
//   #if FOUNDATION_FRAMEWORK  the other 7 -- never compiled here.
//
// So the original 197-file FoundationEssentials build demanded THREE things:
// `os_unfair_lock` and its lock/unlock (LockedState.Primitive), and
// `Logger(subsystem:category:).error(_:)` with `\(x, privacy: .public)`
// interpolation (Calendar_Gregorian, URL).  That is all.  Nothing here is
// speculative surface. The app-facing layer now additionally provides the
// real allocated unfair lock below because unchanged first-party application
// packages use it for mutable Sendable state.  The signpost layer is the exact
// surface used by pinned Nuke's untouched Internal/Log.swift: event/begin/end,
// generated and object-derived IDs, and format arguments.  Those boundaries
// are written visibly to fd 2 instead of pretending a unified-log backend is
// present.
//
// WHY NOT APPLE'S `os` OVERLAY.  Tried and measured first.  Apple's
// os.swiftmodule does `@_exported import os.log` / `os.signpost` /
// `os.workgroup`, so it needs the Clang module `os`, which machorun's SDK does
// not declare and is six headers short of (os/log.h, os/atomic.h,
// os/trace_base.h, os/activity.h, os/signpost.h, os/trace.h, plus three
// `_modules/_os_*.h` shims).  Staging all nine from Xcode still fails: the
// `os_workgroup` submodule does not compile against our headers
// ("unexpected type name 'OS_object': expected identifier", 11x "unknown type
// name 'os_workgroup_t'").  And even if it built, `libswiftos.dylib` does not
// exist for this target and libSystem exports ZERO `_os_log*` symbols -- it
// exports the whole `os_unfair_lock` family and nothing else beginning `os_`.
// Compiling against an overlay whose dylib we cannot load is the unbacked
// promise this project keeps closing, so it is not done here.
//
// WHY THE LOGGER WRITES TO fd 2.  There is no unified log to write to, and a
// logging call that silently discards is indistinguishable from one that
// works -- Foundation reaches these lines only on overflow and
// non-advancing-enumeration paths, which are exactly the diagnostics worth
// not losing.  write(2) rather than print/FileHandle: no Foundation, no
// buffering, and it still says something if the process is about to die.
//===----------------------------------------------------------------------===//

@_exported import Darwin

// os_unfair_lock, os_unfair_lock_lock, os_unfair_lock_unlock and the rest of
// the family come from `Darwin.os.lock` (usr/include/os/lock.h, which machorun
// DOES stage) and are re-exported by the line above.  libSystem.B.tbd exports
// _os_unfair_lock_lock/_unlock/_trylock/_assert_owner and the recursive
// variants, so this is a real implementation, not a declaration.

/// A heap-allocated unfair lock whose copies share both lock identity and
/// protected state, matching Apple's value-semantic wrapper.  The underlying
/// primitive is the real libSystem unfair lock already used by NSLock.
public struct OSAllocatedUnfairLock<State>: @unchecked Sendable {
    private let storage: ManagedBuffer<State, os_unfair_lock>

    public init(uncheckedState initialState: State) {
        storage = .create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements { lock in
                lock.initialize(to: os_unfair_lock())
            }
            return initialState
        }
    }

    public func withLockUnchecked<Result>(
        _ body: (inout State) throws -> Result
    ) rethrows -> Result {
        try storage.withUnsafeMutablePointers { state, lock in
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return try body(&state.pointee)
        }
    }

    public func withLock<Result: Sendable>(
        _ body: @Sendable (inout State) throws -> Result
    ) rethrows -> Result {
        try withLockUnchecked(body)
    }

    public func withLockIfAvailableUnchecked<Result>(
        _ body: (inout State) throws -> Result
    ) rethrows -> Result? {
        try storage.withUnsafeMutablePointers { state, lock in
            guard os_unfair_lock_trylock(lock) else { return nil }
            defer { os_unfair_lock_unlock(lock) }
            return try body(&state.pointee)
        }
    }

    public func withLockIfAvailable<Result: Sendable>(
        _ body: @Sendable (inout State) throws -> Result
    ) rethrows -> Result? {
        try withLockIfAvailableUnchecked(body)
    }

    public enum Ownership: Sendable, Hashable {
        case owner
        case notOwner
    }

    public func precondition(_ condition: Ownership) {
        storage.withUnsafeMutablePointerToElements { lock in
            switch condition {
            case .owner: os_unfair_lock_assert_owner(lock)
            case .notOwner: os_unfair_lock_assert_not_owner(lock)
            }
        }
    }
}

public extension OSAllocatedUnfairLock where State: Sendable {
    init(initialState: State) {
        self.init(uncheckedState: initialState)
    }
}

public extension OSAllocatedUnfairLock where State == () {
    init() {
        self.init(uncheckedState: ())
    }

    func withLockUnchecked<Result>(_ body: () throws -> Result) rethrows -> Result {
        try withLockUnchecked { _ in try body() }
    }

    func withLock<Result: Sendable>(
        _ body: @Sendable () throws -> Result
    ) rethrows -> Result {
        try withLock { _ in try body() }
    }

    func withLockIfAvailableUnchecked<Result>(
        _ body: () throws -> Result
    ) rethrows -> Result? {
        try withLockIfAvailableUnchecked { _ in try body() }
    }

    func withLockIfAvailable<Result: Sendable>(
        _ body: @Sendable () throws -> Result
    ) rethrows -> Result? {
        try withLockIfAvailable { _ in try body() }
    }

    @available(*, noasync, message: "Use withLock for scoped locking")
    func lock() {
        storage.withUnsafeMutablePointerToElements { os_unfair_lock_lock($0) }
    }

    @available(*, noasync, message: "Use withLock for scoped locking")
    func unlock() {
        storage.withUnsafeMutablePointerToElements { os_unfair_lock_unlock($0) }
    }

    @available(*, noasync, message: "Use withLockIfAvailable for scoped locking")
    func lockIfAvailable() -> Bool {
        storage.withUnsafeMutablePointerToElements { os_unfair_lock_trylock($0) }
    }
}

public struct OSLogPrivacy: Sendable, Equatable {
    let rawValue: UInt8
    public static let auto = OSLogPrivacy(rawValue: 0)
    public static let `public` = OSLogPrivacy(rawValue: 1)
    public static let `private` = OSLogPrivacy(rawValue: 2)
    public static let sensitive = OSLogPrivacy(rawValue: 3)
}

public struct OSLogType: Sendable, Equatable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let `default` = OSLogType(rawValue: 0x00)
    public static let info = OSLogType(rawValue: 0x01)
    public static let debug = OSLogType(rawValue: 0x02)
    public static let error = OSLogType(rawValue: 0x10)
    public static let fault = OSLogType(rawValue: 0x11)

    var label: StaticString {
        switch rawValue {
        case 0x01: return "info"
        case 0x02: return "debug"
        case 0x10: return "error"
        case 0x11: return "fault"
        default:   return "default"
        }
    }
}

/// The message type behind `logger.error("...")`.  Apple's is a compile-time
/// constant-evaluated format-string builder; ours simply renders eagerly,
/// which is correct output and slower, and nothing here is on a hot path.
public struct OSLogMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public let text: String
    public init(stringLiteral value: String) { text = value }
    public init(stringInterpolation: Interpolation) { text = stringInterpolation.out }

    public struct Interpolation: StringInterpolationProtocol {
        var out: String
        public init(literalCapacity: Int, interpolationCount: Int) {
            out = ""
            out.reserveCapacity(literalCapacity + interpolationCount * 8)
        }
        public mutating func appendLiteral(_ literal: String) { out += literal }
        // ONE generic overload with a defaulted `privacy:` covers both `\(x)`
        // and `\(x, privacy: .public)`.  Two overloads would be ambiguous at
        // every unlabelled site.
        public mutating func appendInterpolation<T>(_ value: T,
                                                   privacy: OSLogPrivacy = .auto) {
            out += String(describing: value)
        }
    }
}

public struct OSLog: @unchecked Sendable {
    public let subsystem: String
    public let category: String
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
    public static let `default` = OSLog(subsystem: "", category: "")
    public static let disabled = OSLog(subsystem: "", category: "__disabled")
}

/// The three interval states consumed by the public signpost API.
public struct OSSignpostType: RawRepresentable, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let event = OSSignpostType(rawValue: 0)
    public static let begin = OSSignpostType(rawValue: 1)
    public static let end = OSSignpostType(rawValue: 2)

    fileprivate var label: StaticString {
        switch rawValue {
        case Self.begin.rawValue: return "signpost-begin"
        case Self.end.rawValue: return "signpost-end"
        default: return "signpost-event"
        }
    }
}

private let _nextSignpostID = OSAllocatedUnfairLock(initialState: UInt64(1))

/// A process-local signpost identity. Generated IDs are monotonically unique
/// for the lifetime of this process; object IDs remain stable for the lifetime
/// of the referenced object. Neither property is claimed across processes.
public struct OSSignpostID: RawRepresentable, Sendable, Hashable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }

    public static let invalid = OSSignpostID(rawValue: 0)
    public static let exclusive = OSSignpostID(rawValue: UInt64.max)

    public init(log: OSLog) {
        self.rawValue = _nextSignpostID.withLock { next in
            let value = next
            next &+= 1
            if next == Self.invalid.rawValue || next == Self.exclusive.rawValue {
                next = 1
            }
            return value
        }
    }

    public init(log: OSLog, object: AnyObject) {
        var value = UInt64(UInt(bitPattern: ObjectIdentifier(object)))
        // Reserve Apple's two sentinel values while preserving stable identity.
        if value == Self.invalid.rawValue || value == Self.exclusive.rawValue {
            value ^= 0x9e3779b97f4a7c15
        }
        self.rawValue = value
    }
}

/// There is no native unified-log filter on this platform. Every non-disabled
/// signpost has a real, visible stderr diagnostic sink.
public func os_signpost_enabled(_ log: OSLog) -> Bool {
    log.category != "__disabled"
}

public func os_signpost(
    _ type: OSSignpostType,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive
) {
    _emitSignpost(type, log: log, name: name, signpostID: signpostID, format: nil, arguments: [])
}

public func os_signpost(
    _ type: OSSignpostType,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive,
    _ format: StaticString,
    _ arguments: CVarArg...
) {
    _emitSignpost(
        type,
        log: log,
        name: name,
        signpostID: signpostID,
        format: format,
        arguments: arguments.map { String(describing: $0) }
    )
}

/// The exact single-message form used by Nuke. SwiftCore's portable Darwin
/// target does not vend the host SDK's retroactive `String: CVarArg`
/// conformance, so keeping this overload generic preserves the source-level
/// API without inventing unsafe C vararg storage.
public func os_signpost<Message>(
    _ type: OSSignpostType,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID = .exclusive,
    _ format: StaticString,
    _ argument: Message
) {
    _emitSignpost(
        type,
        log: log,
        name: name,
        signpostID: signpostID,
        format: format,
        arguments: [String(describing: argument)]
    )
}

private func _emitSignpost(
    _ type: OSSignpostType,
    log: OSLog,
    name: StaticString,
    signpostID: OSSignpostID,
    format: StaticString?,
    arguments: [String]
) {
    guard os_signpost_enabled(log) else { return }
    var line = "[" + String(describing: type.label) + "] "
    if !log.subsystem.isEmpty {
        line += log.subsystem + ":" + log.category + " "
    }
    line += String(describing: name)
    line += " id=" + String(signpostID.rawValue)
    if let format {
        line += " format=" + String(describing: format)
        if !arguments.isEmpty {
            line += " args=["
            line += arguments.joined(separator: ", ")
            line += "]"
        }
    }
    _writeDiagnostic(line + "\n")
}

private func _writeDiagnostic(_ line: String) {
    let bytes = Array(line.utf8)
    bytes.withUnsafeBufferPointer { buf in
        guard let baseAddress = buf.baseAddress else { return }
        var offset = 0
        while offset < buf.count {
            let written = Darwin.write(2, baseAddress + offset, buf.count - offset)
            if written <= 0 { break }
            offset += written
        }
    }
}

public struct Logger: Sendable {
    let subsystem: String
    let category: String
    public init() { self.init(subsystem: "", category: "") }
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
    public init(_ log: OSLog) { self.init(subsystem: log.subsystem, category: log.category) }

    public func log(level: OSLogType, _ message: OSLogMessage) { emit(level, message) }
    public func log(_ message: OSLogMessage) { emit(.default, message) }
    public func trace(_ message: OSLogMessage) { emit(.debug, message) }
    public func debug(_ message: OSLogMessage) { emit(.debug, message) }
    public func info(_ message: OSLogMessage) { emit(.info, message) }
    public func notice(_ message: OSLogMessage) { emit(.default, message) }
    public func warning(_ message: OSLogMessage) { emit(.error, message) }
    public func error(_ message: OSLogMessage) { emit(.error, message) }
    public func critical(_ message: OSLogMessage) { emit(.fault, message) }
    public func fault(_ message: OSLogMessage) { emit(.fault, message) }

    private func emit(_ level: OSLogType, _ message: OSLogMessage) {
        if category == "__disabled" { return }
        var line = "["
        line += String(describing: level.label)
        line += "] "
        if !subsystem.isEmpty { line += subsystem + ":" + category + " " }
        line += message.text
        line += "\n"
        _writeDiagnostic(line)
    }
}
