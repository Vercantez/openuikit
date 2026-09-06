import Foundation
import LightweightCodeRequirements

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build LightweightCodeRequirements with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that `import`s LightweightCodeRequirements and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` values flow through public LightweightCodeRequirements
//    APIs without a framework-local Data stand-in.

private func assertNotLightweightCodeRequirementsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("LightweightCodeRequirements."))
}

func lightweightCodeRequirementsDependencyIdentityMain() {
    let digest = Data([0x4c, 0x57, 0x43, 0x52])
    assertNotLightweightCodeRequirementsType(digest)
    precondition(type(of: digest) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("LightweightCodeRequirements."))

    let hash = CodeDirectoryHash(digest)
    precondition(hash.values == [digest])
    assertNotLightweightCodeRequirementsType(hash.values[0])

    let info = InfoPlistHash.in([digest, Data("plist".utf8)])
    precondition(info.values.count == 2)
    precondition(type(of: info.values[0]) == Data.self)

    let encoded = try! JSONEncoder().encode(hash)
    precondition(!encoded.isEmpty)
    assertNotLightweightCodeRequirementsType(encoded)
}

lightweightCodeRequirementsDependencyIdentityMain()
