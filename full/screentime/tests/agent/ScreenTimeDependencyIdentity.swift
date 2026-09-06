import ScreenTime
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest ScreenTime success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build ScreenTime with that module on `-I` / `-L`.
// 3. Link this file as a client that imports ScreenTime and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `SCREENTIME_DEPENDENCY_IDENTITY_OK` and that
//    `libScreenTime.dylib` was loaded.

private func assertNotScreenTimeType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ScreenTime."))
}

func assertFoundationIdentity() {
    let data = Data([0x53, 0x54])
    assertNotScreenTimeType(data)
    precondition(data.count == 2)

    let start = Date(timeIntervalSince1970: 0)
    let interval = DateInterval(start: start, duration: 60)
    assertNotScreenTimeType(interval)
    precondition(interval.duration == 60)

    let url = URL(string: "https://example.invalid/path")!
    assertNotScreenTimeType(url)

    let history = STWebHistory(profileIdentifier: STWebHistory.ProfileIdentifier("p1"))
    history.deleteHistory(during: interval)
    history.deleteHistory(for: url)

    _ = Foundation.Date.self
    _ = Foundation.UUID.self
}

func screenTimeDependencyIdentityMain() {
    assertFoundationIdentity()
    print("SCREENTIME_DEPENDENCY_IDENTITY_OK")
}
