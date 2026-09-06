import Foundation
import SystemExtensions

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build SystemExtensions with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports SystemExtensions and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `SYSTEMEXTENSIONS_DEPENDENCY_IDENTITY_OK` and that
//    `libSystemExtensions.dylib` was loaded.

private func assertNotSystemExtensionsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SystemExtensions."))
}

/// Pass genuine Foundation values through public SystemExtensions APIs.
func systemExtensionsDependencyIdentityProbe() {
    let bundleID = "com.example.openuikit.identity"
    assertNotSystemExtensionsType(bundleID)
    precondition(type(of: bundleID) == String.self)

    do {
        _ = try OSSystemExtensionsWorkspace.shared.systemExtensions(
            forApplicationWithBundleID: bundleID
        )
        preconditionFailure("workspace query must fail closed")
    } catch let error as OSSystemExtensionError {
        let nsError = error as NSError
        precondition(nsError.domain == OSSystemExtensionErrorDomain)
        precondition(nsError.code == OSSystemExtensionError.Code.unknown.rawValue)
        assertNotSystemExtensionsType(nsError.domain)
    } catch {
        preconditionFailure("expected OSSystemExtensionError")
    }

    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotSystemExtensionsType(stamp)
    let hash = Data(repeating: 0x53, count: 8)
    assertNotSystemExtensionsType(hash)
    let userInfo: [String: Any] = ["stamp": stamp, "hash": hash]
    assertNotSystemExtensionsType(userInfo)
    let wrapped = OSSystemExtensionError(.validationFailed, userInfo: userInfo)
    precondition(wrapped.userInfo["stamp"] as? Date == stamp)
    precondition(wrapped.errorUserInfo["hash"] as? Data == hash)

    let domain = OSSystemExtensionErrorDomain
    precondition(type(of: domain) == String.self)
    assertNotSystemExtensionsType(domain)

    _ = Foundation.NSError.self
    _ = Foundation.UUID.self
}

func systemExtensionsDependencyIdentityMain() {
    systemExtensionsDependencyIdentityProbe()
    print("SYSTEMEXTENSIONS_DEPENDENCY_IDENTITY_OK")
}

#if SYSTEMEXTENSIONS_IDENTITY_MAIN
systemExtensionsDependencyIdentityMain()
#endif
