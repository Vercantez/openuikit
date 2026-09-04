import CommonCrypto
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build CommonCrypto with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s CommonCrypto and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` values flow through public CommonCrypto APIs
//    without a framework-local Data stand-in.

private func assertNotCommonCryptoType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CommonCrypto."))
}

func commoncryptoDependencyIdentityMain() {
    let payload = Data("abc".utf8)
    assertNotCommonCryptoType(payload)
    precondition(type(of: payload) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("CommonCrypto."))

    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    payload.withUnsafeBytes { raw in
        _ = CC_SHA256(raw.baseAddress, CC_LONG(payload.count), &digest)
    }
    precondition(digest.count == 32)
    let digestData = Data(digest)
    assertNotCommonCryptoType(digestData)

    var random = Data(count: 16)
    random.withUnsafeMutableBytes { raw in
        _ = CCRandomGenerateBytes(raw.baseAddress, raw.count)
    }
    assertNotCommonCryptoType(random)
}

commoncryptoDependencyIdentityMain()
