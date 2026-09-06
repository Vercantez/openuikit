import Foundation
import SafetyKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build SafetyKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that imports SafetyKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `SAFETYKIT_DEPENDENCY_IDENTITY_OK` and that `libSafetyKit.dylib`
//    was loaded.

private func assertNotSafetyKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SafetyKit."))
}

/// Pass genuine Foundation values through public SafetyKit APIs.
func safetyKitDependencyIdentityProbe() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotSafetyKitType(stamp)
    precondition(type(of: stamp) == Date.self)

    let event = SACrashDetectionEvent.host_makeEvent(
        date: stamp,
        response: .disabled,
        location: nil
    )
    precondition(event.date == stamp)
    precondition(event.date.timeIntervalSince1970 == 1_700_000_000)

    let userInfo: [String: Any] = ["stamp": stamp]
    assertNotSafetyKitType(userInfo)
    let wrapped = SAError(.invalidArgument, userInfo: userInfo)
    precondition(wrapped.userInfo["stamp"] as? Date == stamp)
    precondition(wrapped.errorUserInfo["stamp"] as? Date == stamp)

    let domain = SAErrorDomain
    precondition(type(of: domain) == String.self)
    assertNotSafetyKitType(domain)

    var status: SAAuthorizationStatus?
    var error: (any Error)?
    SACrashDetectionManager().requestAuthorization { receivedStatus, receivedError in
        status = receivedStatus
        error = receivedError
    }
    precondition(status == .notDetermined)
    let nsError = error as NSError?
    precondition(nsError?.domain == SAErrorDomain)
    precondition(nsError?.code == SAError.Code.notAllowed.rawValue)
}

#if SAFETYKIT_IDENTITY_MAIN
safetyKitDependencyIdentityProbe()
print("SAFETYKIT_DEPENDENCY_IDENTITY_OK")
#endif
