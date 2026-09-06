import Assignables
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Assignables success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build Assignables with that module on `-I` / `-L`.
// 3. Link this file as a client that imports Assignables and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `ASSIGNABLES_DEPENDENCY_IDENTITY_OK` and that
//    `libAssignables.dylib` was loaded.

private func assertNotAssignablesType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Assignables."))
}

func assertFoundationIdentity() {
    let data = Data([0x41, 0x53])
    assertNotAssignablesType(data)
    precondition(data.count == 2)

    let identity = StringUserIdentity(value: "foundation-probe")
    let encoder = JSONEncoder()
    let encoded = try! encoder.encode(identity)
    assertNotAssignablesType(encoded)
    let decoded = try! JSONDecoder().decode(StringUserIdentity.self, from: encoded)
    precondition(decoded == identity)

    var document = try! AssignableDocument(id: "identity", partData: [:])
    document.authors = [AnyUserIdentity(identity)]
    let url = URL(fileURLWithPath: "/tmp/assignables-identity")
    _ = url
    _ = Foundation.Date.self
    _ = Foundation.UUID.self
    _ = CGRect(x: 0, y: 0, width: 1, height: 1)
}

func assignablesDependencyIdentityMain() {
    assertFoundationIdentity()
    print("ASSIGNABLES_DEPENDENCY_IDENTITY_OK")
}
