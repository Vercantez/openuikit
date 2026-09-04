import Foundation
import OSLog

// Standalone host probe. The sealed schema-v2 gate compiles
// tests/agent/*Tests.swift and LoadSmoke.swift; this file is a manual
// runtime contract check for the empty current-process store.

precondition(OSLogPortable.backend == .standardError)
precondition(!OSLogPortable.supportsUnifiedLogging)
precondition(OSLogEntryLog.Level.debug.rawValue == 1)
precondition(OSLogStore.Scope.currentProcessIdentifier.rawValue == 1)

let store = try! OSLogStore(scope: .currentProcessIdentifier)
precondition(Array(try! store.getEntries()).isEmpty)

do {
    _ = try OSLogStore(url: URL(fileURLWithPath: "/tmp/missing.logarchive"))
    preconditionFailure("log archive open must fail closed")
} catch let error as OSLogPortable.StoreError {
    precondition(error == .logArchiveUnavailable)
}

print("OSLOG_AGENT_RUNTIME_OK")
