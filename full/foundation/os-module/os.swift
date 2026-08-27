//===----------------------------------------------------------------------===//
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
// So the surface actually demanded by the 197-file build is THREE things:
// `os_unfair_lock` and its lock/unlock (LockedState.Primitive), and
// `Logger(subsystem:category:).error(_:)` with `\(x, privacy: .public)`
// interpolation (Calendar_Gregorian, URL).  That is all.  Nothing here is
// speculative surface.
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
        let bytes = Array(line.utf8)
        bytes.withUnsafeBufferPointer { buf in
            var off = 0
            while off < buf.count {
                let n = Darwin.write(2, buf.baseAddress! + off, buf.count - off)
                if n <= 0 { break }
                off += n
            }
        }
    }
}
