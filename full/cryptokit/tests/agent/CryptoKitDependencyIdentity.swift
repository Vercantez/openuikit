import CryptoKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build CryptoKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s CryptoKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` values round-trip through public CryptoKit APIs
//    without a framework-local Data stand-in.

private func assertNotCryptoKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CryptoKit."))
}

func cryptokitDependencyIdentityMain() {
    let payload = Data("CryptoKit-Foundation".utf8)
    assertNotCryptoKitType(payload)
    precondition(type(of: payload) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("CryptoKit."))

    let digest = SHA256.hash(data: payload)
    let digestBytes = digest.withUnsafeBytes { Data($0) }
    precondition(digestBytes.count == 32)
    assertNotCryptoKitType(digestBytes)

    let key = SymmetricKey(data: Data(count: 32))
    let sealed = try! AES.GCM.seal(payload, using: key)
    let opened = try! AES.GCM.open(sealed, using: key)
    precondition(opened == payload)
    assertNotCryptoKitType(opened)

    let hmac = HMAC<SHA256>.authenticationCode(for: payload, using: key)
    precondition(
        HMAC<SHA256>.isValidAuthenticationCode(hmac, authenticating: payload, using: key)
    )
}

cryptokitDependencyIdentityMain()
