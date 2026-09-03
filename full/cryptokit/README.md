# CryptoKit

Linux starting point for Apple's public `CryptoKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

Host-compiled sources import **Foundation only**.

## What is real

Portable Swift implementations that match public test vectors:

- SHA-256 / SHA-384 / SHA-512, SHA3-256 / SHA3-384 / SHA3-512
- Insecure MD5 and SHA-1
- HMAC and HKDF (RFC 4231 / RFC 5869 cases in agent tests)
- AES-GCM (NIST empty-plaintext tag plus open/seal round-trips)
- ChaCha20-Poly1305 (RFC 8439 section 2.8.2 ciphertext and tag)
- AES Key Wrap (RFC 3394 wrap). Unwrap is fail-closed: AES decrypt is not
  available in this guest, so `AES.KeyWrap.unwrap` throws `.unwrapFailure`.
- `SymmetricKey` / `SymmetricKeySize`
- Digest and MAC `Sequence` iteration plus constant-time `==`

`libCryptoKit.dylib` compiles with `-warnings-as-errors`.

## Fail-closed boundaries

Linux has no Secure Enclave, no Apple CoreCrypto ECC/Ed25519/X25519 provider,
and no HPKE or post-quantum primitive here. Those APIs compile and then throw
`CryptoKitError.underlyingCoreCryptoError` (or a documented size/PEM ASN.1
error) instead of inventing signatures, shared secrets, or encapsulated keys.

- `SecureEnclave.isAvailable == false`
- Curve25519 / P256 / P384 / P521 signing and key agreement do not succeed
- HPKE `Sender` / `Recipient` inits do not perform DHKEM
- ML-KEM / ML-DSA / X-Wing generate, encapsulate, decapsulate, and sign fail closed
- PEM / DER / x9.63 / compact encodings return empty placeholders or throw
  `CryptoKitASN1Error` / `CryptoKitError.incorrectParameterSize`

Secure Enclave initializers that take `LAContext` or `SecAccessControl` are
**unavailable**: those types are not declared dependencies, and no public
lookalike is introduced.

`Sequence.publisher` (Combine) is **unavailable** on Linux.

## Deferred

Swift.Sequence overlays (`map`, `filter`, `sorted`, and similar) and Foundation
`Error.localizedDescription` / `SortComparator` helpers are inherited from the
toolchain and are not restated in guest sources. Native ECC, HPKE, and
post-quantum behavior stays deferred until a provider plus an Apple-runtime
oracle exist.

## Tests

- `tests/agent/CryptoKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/CryptoKitTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/CryptoKitDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/test_cryptokit_host.sh` — existing hashing / nonce / Ed25519 fail-closed host probe
