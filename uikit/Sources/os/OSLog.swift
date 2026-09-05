// OSLog / os_log compatibility for the 20-app ladder corpus.
//
// Measured scratch/ladder-corpus 2026-09-05:
//   * 13/20 apps `import os` (202 files); 94 files `import os.log`
//   * OSLog(subsystem:category:) — Focus NimbusWrapper, firefox
//     MozillaRustComponents Logger, DuckDuckGo Instruments
//   * os_log("%@", log:type:message) and os_log("%{private}@", …)
//     (Focus NimbusWrapper:60–68, type .debug/.info/.fault/.error)
//   * os_log(format, args…) without an OSLog (DuckDuckGo Autofill)
//   * os_log("… \(error)") OSLogMessage form (DuckDuckGo Autofill:200)
// Calls are accepted and ignored.

public struct OSLog: Equatable, @unchecked Sendable {
    public let subsystem: String
    public let category: String

    public static let `default` = OSLog(subsystem: "com.apple.runtime-issues", category: "os")
    public static let disabled = OSLog(subsystem: "", category: "")

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
}

public struct OSLogType: Equatable, RawRepresentable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    // Apple's overlay values (os/log.h).
    public static let `default` = OSLogType(rawValue: 0x00)
    public static let info = OSLogType(rawValue: 0x01)
    public static let debug = OSLogType(rawValue: 0x02)
    public static let error = OSLogType(rawValue: 0x10)
    public static let fault = OSLogType(rawValue: 0x11)
}

public func os_log(
    _ message: StaticString,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog = .default,
    type: OSLogType = .default,
    _ args: CVarArg...
) {
    _ = (message, dso, log, type, args)
}

public func os_log(
    _ type: OSLogType,
    dso: UnsafeRawPointer = #dsohandle,
    log: OSLog = .default,
    _ message: OSLogMessage
) {
    _ = (type, dso, log, message)
}

public func os_log(_ message: OSLogMessage) {
    _ = message
}
