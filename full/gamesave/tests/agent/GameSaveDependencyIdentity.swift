import GameSave
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest iCloud / UIKit success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and UIKit if status-display APIs are wired).
// 2. Build GameSave with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports GameSave and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `GAMESAVE_DEPENDENCY_IDENTITY_OK` and that
//    `libGameSave.dylib` was loaded.

private func assertNotGameSaveType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("GameSave."))
}

func assertFoundationIdentity() {
    let directory = GameSaveSyncedDirectory.openDirectory(containerIdentifier: "identity")
    switch directory.state {
    case .local(let url):
        assertNotGameSaveType(url)
        precondition(url.isFileURL)
        _ = url.path
    default:
        preconditionFailure("expected local fail-closed directory state")
    }
    let domain = GameSaveErrorDomain
    precondition(domain == "GameSaveErrorDomain")
    let error = NSError(domain: domain, code: 1)
    assertNotGameSaveType(error.domain)
    precondition(error.domain == GameSaveErrorDomain)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
    _ = Foundation.URL.self
}

func gameSaveDependencyIdentityMain() {
    assertFoundationIdentity()
    print("GAMESAVE_DEPENDENCY_IDENTITY_OK")
}
