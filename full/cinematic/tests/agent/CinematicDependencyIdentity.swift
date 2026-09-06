import Foundation
import Cinematic

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Cinematic with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that imports Cinematic and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `CINEMATIC_DEPENDENCY_IDENTITY_OK` and that `libCinematic.dylib`
//    was loaded.

private func assertNotCinematicType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Cinematic."))
}

/// Pass genuine Foundation values through public Cinematic APIs.
func cinematicDependencyIdentityProbe() {
    let domain = CNCinematicErrorDomain
    precondition(type(of: domain) == String.self)
    assertNotCinematicType(domain)

    let userInfo: [String: Any] = ["stamp": Date(timeIntervalSince1970: 1_700_000_000)]
    assertNotCinematicType(userInfo)
    let wrapped = CNCinematicError(.unsupported, userInfo: userInfo)
    precondition(wrapped.userInfo["stamp"] as? Date == Date(timeIntervalSince1970: 1_700_000_000))
    precondition(wrapped.errorUserInfo["stamp"] as? Date == Date(timeIntervalSince1970: 1_700_000_000))

    var observed: Bool?
    CNAssetSpatialAudioInfo.checkIfContainsSpatialAudio(asset: AVAsset()) { value in
        observed = value
    }
    precondition(observed == false)
    let nsError = CNCinematicError(.unsupported) as NSError
    precondition(nsError.domain == CNCinematicErrorDomain)
    precondition(nsError.code == CNCinematicError.Code.unsupported.rawValue)
}

#if CINEMATIC_IDENTITY_MAIN
cinematicDependencyIdentityProbe()
print("CINEMATIC_DEPENDENCY_IDENTITY_OK")
#endif
