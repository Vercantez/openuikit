import DeviceCheck
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build DeviceCheck with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that imports DeviceCheck and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `DEVICECHECK_DEPENDENCY_IDENTITY_OK` and that `libDeviceCheck.dylib`
//    was loaded.

private func assertNotDeviceCheckType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("DeviceCheck."))
}

/// Pass genuine Foundation values through public DeviceCheck APIs.
func deviceCheckDependencyIdentityProbe() {
    let hash = Data(repeating: 0x11, count: 32)
    assertNotDeviceCheckType(hash)
    precondition(type(of: hash) == Data.self)

    let domain = DCErrorDomain
    precondition(type(of: domain) == String.self)
    assertNotDeviceCheckType(domain)

    var tokenSeen: Data? = Data()
    var tokenError: (any Error)?
    DCDevice.current.generateToken { token, error in
        tokenSeen = token
        tokenError = error
    }
    precondition(tokenSeen == nil)
    let tokenNSError = tokenError as NSError?
    precondition(tokenNSError != nil)
    precondition(tokenNSError?.domain == DCErrorDomain)
    precondition(tokenNSError?.code == DCError.Code.featureUnsupported.rawValue)
    if let nsError = tokenNSError {
        assertNotDeviceCheckType(nsError.domain)
    }

    var attestation: Data? = Data()
    DCAppAttestService.shared.attestKey(
        "identity-key",
        clientDataHash: hash
    ) { data, error in
        attestation = data
        let nsError = error as NSError?
        precondition(nsError?.domain == DCError.errorDomain)
        precondition(nsError?.code == DCError.Code.featureUnsupported.rawValue)
    }
    precondition(attestation == nil)

    let userInfo: [String: Any] = ["hash": hash]
    assertNotDeviceCheckType(userInfo)
    let wrapped = DCError(.invalidInput, userInfo: userInfo)
    precondition(wrapped.userInfo["hash"] as? Data == hash)
    precondition(wrapped.errorUserInfo["hash"] as? Data == hash)
}

#if DEVICECHECK_IDENTITY_MAIN
deviceCheckDependencyIdentityProbe()
print("DEVICECHECK_DEPENDENCY_IDENTITY_OK")
#endif
