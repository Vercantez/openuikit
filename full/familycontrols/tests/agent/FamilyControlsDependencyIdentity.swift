import FamilyControls
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest FamilyControls
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build FamilyControls with that module on `-I` / `-L`.
// 3. Link this file as a client that imports FamilyControls and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `FAMILYCONTROLS_DEPENDENCY_IDENTITY_OK` and that
//    `libFamilyControls.dylib` was loaded.

private func assertNotFamilyControlsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("FamilyControls."))
}

func assertFoundationIdentity() {
    let data = Data([0x46, 0x43])
    assertNotFamilyControlsType(data)
    precondition(data.count == 2)

    var selection = FamilyActivitySelection()
    let encoder = JSONEncoder()
    let encoded = try! encoder.encode(selection)
    assertNotFamilyControlsType(encoded)
    let decoded = try! JSONDecoder().decode(FamilyActivitySelection.self, from: encoded)
    precondition(decoded == selection)
    _ = Foundation.Date.self
    _ = Foundation.UUID.self
    selection.applicationTokens.insert(ApplicationToken())
    precondition(selection.applicationTokens.count == 1)
}

func familyControlsDependencyIdentityMain() {
    assertFoundationIdentity()
    print("FAMILYCONTROLS_DEPENDENCY_IDENTITY_OK")
}
