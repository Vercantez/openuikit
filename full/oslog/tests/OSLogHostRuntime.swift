import OSLog
import os

private final class SignpostObject {}

@main
private struct OSLogHostRuntime {
    static func main() {
        precondition(OSLogPortable.backend == .standardError)
        precondition(!OSLogPortable.supportsUnifiedLogging)
        precondition(OSLogPortable.supportsSignposts)
        precondition(OSLogPortable.signpostIdentityScope == "process-local")

        // `OSLog` re-exports the very same Logger declaration from `os`.
        let logger: os.Logger = Logger.text
        logger.info("emoji logger identity=shared")

        let log = OSLog(subsystem: "PortableOSLog", category: "HostGate")
        let generated = OSSignpostID(log: log)
        let next = OSSignpostID(log: log)
        precondition(generated != .invalid && generated != .exclusive)
        precondition(next != generated)

        let object = SignpostObject()
        let objectID = OSSignpostID(log: log, object: object)
        precondition(objectID == OSSignpostID(log: log, object: object))
        precondition(os_signpost_enabled(log))
        precondition(!os_signpost_enabled(.disabled))

        os_signpost(.begin, log: log, name: "host-work", signpostID: generated)
        os_signpost(
            .event,
            log: log,
            name: "host-value",
            signpostID: objectID,
            "%{public}s",
            "visible"
        )
        os_signpost(.end, log: log, name: "host-work", signpostID: generated)
        os_signpost(.event, log: .disabled, name: "must-not-appear")

        print(
            "OSLOG_HOST_RUNTIME_OK backend=standard-error " +
            "signposts=visible identity=shared scope=process-local"
        )
    }
}
