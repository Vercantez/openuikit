import Foundation
import RelevanceKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build RelevanceKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that imports RelevanceKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `RELEVANCEKIT_DEPENDENCY_IDENTITY_OK` and that `libRelevanceKit.dylib`
//    was loaded.

private func assertNotRelevanceKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("RelevanceKit."))
}

/// Pass genuine Foundation values through public RelevanceKit APIs.
func relevanceKitDependencyIdentityProbe() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotRelevanceKitType(stamp)
    precondition(type(of: stamp) == Date.self)

    let exact = RelevantContext.date(stamp)
    _ = exact

    let interval = DateInterval(start: stamp, duration: 3_600)
    assertNotRelevanceKitType(interval)
    precondition(type(of: interval) == DateInterval.self)
    let datedInterval = RelevantContext.date(interval: interval, kind: .scheduled)
    _ = datedInterval

    let range: ClosedRange<Date> = stamp...stamp.addingTimeInterval(120)
    assertNotRelevanceKitType(range.lowerBound)
    let datedRange = RelevantContext.date(range: range, kind: .informational)
    _ = datedRange

    let fromTo = RelevantContext.date(from: stamp, to: stamp.addingTimeInterval(60))
    _ = fromTo
}

#if RELEVANCEKIT_IDENTITY_MAIN
relevanceKitDependencyIdentityProbe()
print("RELEVANCEKIT_DEPENDENCY_IDENTITY_OK")
#endif
