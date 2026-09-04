import Foundation
import OSLog

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build OSLog with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports OSLog and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `OSLOG_DEPENDENCY_IDENTITY_OK` and that `libOSLog.dylib` was loaded.

private func assertNotOSLogType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("OSLog."))
}

/// Pass genuine Foundation values through public OSLog APIs.
func osLogDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/identity.logarchive")
    assertNotOSLogType(url)
    precondition(type(of: url) == URL.self)
    do {
        _ = try OSLogStore(url: url)
        preconditionFailure("archive URL must not open a fabricated store")
    } catch let error as OSLogPortable.StoreError {
        precondition(error == .logArchiveUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }

    let date = Date(timeIntervalSince1970: 42)
    assertNotOSLogType(date)
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let position = store.position(date: date)
    precondition(String(describing: type(of: position)) == "OSLogPosition")
    let interval: TimeInterval = 8
    assertNotOSLogType(interval)
    _ = store.position(timeIntervalSinceEnd: interval)

    let predicate = NSPredicate(value: false)
    assertNotOSLogType(predicate)
    let entries = try! store.getEntries(
        with: .reverse,
        at: position,
        matching: predicate
    )
    precondition(Array(entries).isEmpty)

    let payload = Data([0x6F, 0x73])
    assertNotOSLogType(payload)
    switch OSLogMessageComponent.Argument.data(payload) {
    case .data(let value):
        precondition(value == payload)
    default:
        preconditionFailure("Data argument identity")
    }

    let number = NSNumber(value: Int64(11))
    assertNotOSLogType(number)
    _ = number.int64Value
}

#if OSLOG_IDENTITY_MAIN
osLogDependencyIdentityProbe()
print("OSLOG_DEPENDENCY_IDENTITY_OK")
#endif
