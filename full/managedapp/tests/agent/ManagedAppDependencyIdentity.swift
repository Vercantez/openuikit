import Foundation
import ManagedApp

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest success. This file is
// not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build ManagedApp with that module on `-I` / `-L`.
// 3. Link this file as a client that imports ManagedApp and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `MANAGEDAPP_DEPENDENCY_IDENTITY_OK` and that
//    `libManagedApp.dylib` was loaded.

func managedAppDependencyIdentityMain() {
    let payload = Data("mdm-config".utf8)
    let encoder = JSONEncoder()
    let code = ManagedAppConfigurationDecodingErrorCode(
        rawValue: ManagedAppConfigurationDecodingErrorCode.keyNotFound
    )!
    let encoded = try! encoder.encode(code)
    precondition(!encoded.isEmpty)
    precondition(payload.count == 10)

    let error: any Error = ManagedAppError.invalidIdentifier
    precondition(!error.localizedDescription.isEmpty)

    let decoded = try! JSONDecoder().decode(
        ManagedAppConfigurationDecodingErrorCode.self,
        from: encoded
    )
    precondition(decoded.rawValue == ManagedAppConfigurationDecodingErrorCode.keyNotFound)

    print("MANAGEDAPP_DEPENDENCY_IDENTITY_OK")
}
