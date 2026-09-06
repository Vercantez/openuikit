import ThreadNetwork
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest ThreadNetwork success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build ThreadNetwork with that module on `-I` / `-L`.
// 3. Link this file as a client that imports ThreadNetwork and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `THREADNETWORK_DEPENDENCY_IDENTITY_OK` and that
//    `libThreadNetwork.dylib` was loaded.

private func assertNotThreadNetworkType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("ThreadNetwork."))
}

func assertFoundationIdentity() {
    let dataset = Data([0x00, 0x03, 0x00, 0x00, 0x12])
    assertNotThreadNetworkType(dataset)
    precondition(dataset.count == 5)

    let created = Date(timeIntervalSince1970: 0)
    assertNotThreadNetworkType(created)

    let client = THClient()
    var preferred = true
    client.checkPreferredNetwork(forActiveOperationalDataset: dataset) { available in
        preferred = available
    }
    precondition(preferred == false)

    client.retrieveAllCredentials { credentials, error in
        precondition(credentials == nil)
        precondition(error != nil)
    }

    _ = Foundation.Data.self
    _ = Foundation.Date.self
    _ = Foundation.UUID.self
}

func threadNetworkDependencyIdentityMain() {
    assertFoundationIdentity()
    print("THREADNETWORK_DEPENDENCY_IDENTITY_OK")
}
