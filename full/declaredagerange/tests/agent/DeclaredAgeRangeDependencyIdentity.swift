import DeclaredAgeRange
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest DeclaredAgeRange
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build DeclaredAgeRange with that module on `-I` / `-L`.
// 3. Link this file as a client that imports DeclaredAgeRange and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `DECLAREDAGERANGE_DEPENDENCY_IDENTITY_OK` and that
//    `libDeclaredAgeRange.dylib` was loaded.

private func assertNotDeclaredAgeRangeType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("DeclaredAgeRange."))
}

func assertFoundationIdentity() {
    let controls = AgeRangeService.ParentalControls.communicationLimits
    let description: String = controls.description
    assertNotDeclaredAgeRangeType(description)
    precondition(description == "1")

    let error: AgeRangeService.Error = .notAvailable
    let localized: String = error.localizedDescription
    assertNotDeclaredAgeRangeType(localized)
    precondition(!localized.isEmpty)

    let nsError = error as NSError
    assertNotDeclaredAgeRangeType(nsError)
    precondition(nsError.localizedDescription == localized)

    let data = Data([0x41, 0x52])
    assertNotDeclaredAgeRangeType(data)
    precondition(data.count == 2)
    _ = Foundation.String.self
}

func declaredAgeRangeDependencyIdentityMain() {
    assertFoundationIdentity()
    print("DECLAREDAGERANGE_DEPENDENCY_IDENTITY_OK")
}
