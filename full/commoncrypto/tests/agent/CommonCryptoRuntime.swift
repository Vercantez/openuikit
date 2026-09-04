import CommonCrypto

// Optional schema-v1-style runtime probe. The sealed schema-v2 host gate compiles
// tests/agent/*Tests.swift plus CommonCryptoLoadSmoke.swift and emits the marker
// from generated runner stdout; this file is not part of that isolated compile.

func commoncryptoAgentRuntimeProbe() {
    precondition(CC_SHA256_DIGEST_LENGTH == 32)
    precondition(kCCSuccess == 0)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = CC_SHA256(nil, 0, &digest)
}
