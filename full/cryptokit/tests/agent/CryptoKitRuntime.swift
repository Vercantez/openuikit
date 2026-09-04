import CryptoKit
import Foundation

// Optional schema-v1-style runtime probe. The sealed schema-v2 host gate compiles
// tests/agent/*Tests.swift plus CryptoKitLoadSmoke.swift and emits the marker
// from generated runner stdout; this file is not part of that isolated compile.

func cryptokitAgentRuntimeProbe() {
    precondition(SecureEnclave.isAvailable == false)
    precondition(SHA256Digest.byteCount == 32)
    _ = SHA256.hash(data: Data())
}
