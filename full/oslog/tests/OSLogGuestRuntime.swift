import OSLog

@main
private struct OSLogGuestRuntime {
    static func main() {
        precondition(OSLogPortable.backend == .standardError)
        precondition(!OSLogPortable.supportsUnifiedLogging)
        precondition(OSLogPortable.supportsSignposts)

        let log = OSLog(
            subsystem: "OpenUIKit.OSLogGuestRuntime",
            category: "Standalone"
        )
        let identifier = OSSignpostID(log: log)
        precondition(identifier != .invalid && identifier != .exclusive)
        Logger(log).info("standalone OSLog diagnostic")
        os_signpost(
            .event,
            log: log,
            name: "StandaloneBoundary",
            signpostID: identifier,
            "%{public}s",
            "visible"
        )
        print(
            "OSLOG_GUEST_MACHO_OK backend=standard-error " +
            "signposts=visible reexport=os"
        )
    }
}
