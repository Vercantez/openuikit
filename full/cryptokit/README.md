# CryptoKit

Linux starting point for Apple's public `CryptoKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

Host-compiled sources import **Foundation only**.

## What is real

Portable Swift implementations that match published test vectors:

- SHA-256 / SHA-384 / SHA-512, SHA3-256 / SHA3-384 / SHA3-512
- Insecure MD5 and SHA-1
- HMAC and HKDF (RFC 4231 / RFC 5869)
- AES-GCM (NIST empty-plaintext tag plus open/seal round-trips)
- ChaCha20-Poly1305 (RFC 8439 section 2.8.2)
- AES Key Wrap and unwrap (RFC 3394 §4.1:
  wrap `1FA68B0A8112B447AEF34BD8FB5A7B829D3E862371D2CFE5`)
- `SymmetricKey` / `SymmetricKeySize`
- Digest and MAC `Sequence` iteration plus constant-time `==`
- X25519 key agreement (RFC 7748 §6.1 shared secret
  `4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742`)
- Ed25519 sign/verify (RFC 8032 §7.1 empty-message signature)
- P-256 / P-384 / P-521 ECDSA and ECDH, plus raw / x9.63 / compressed /
  compact / SPKI / PKCS#8 / PEM encodings (RFC 6979 A.2.5 P-256 public point)
- `SharedSecret.hkdfDerivedSymmetricKey` / `x963DerivedSymmetricKey`
- HPKE base mode for X25519-ChaChaPoly and P-256-AES-GCM (RFC 9180)

`libCryptoKit.dylib` compiles with `-warnings-as-errors`.

Coverage after this round: **1181 implemented / 39 declared / 44 deferred /
23 unavailable** of 1287 IDs. Implemented ≥ 900. Nondeferred except
SecureEnclave (declared + LAContext unavailable) and Combine `Sequence.publisher`
(unavailable on Linux). 44 Foundation `SortComparator`/`formatted` Sequence
overlays stay deferred: Darwin comparator defaults are unobserved.

## Fail-closed boundaries

- `SecureEnclave.isAvailable == false`; hardware-backed P-256 / ML-KEM / ML-DSA
  generate and sign throw `CryptoKitError.underlyingCoreCryptoError`. Inits that
  take `LAContext` or `SecAccessControl` are **unavailable**.
- ML-KEM / ML-DSA / X-Wing generate, encapsulate, decapsulate, and sign fail
  closed (no Kyber/Dilithium provider).
- `Sequence.publisher` (Combine) is **unavailable** on Linux.

## Deferred

Swift.Sequence + Foundation `SortComparator` / `FormatStyle` overlays on digest
and nonce types, and `Error.localizedDescription` wording on Darwin, remain
unrestated. Native post-quantum behavior stays fail-closed until a provider plus
an Apple-runtime oracle exist. Insecure.RSA is not in this SDK snapshot.

## Tests

- `tests/agent/CryptoKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/CryptoKitTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/CryptoKitDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/test_cryptokit_host.sh` — hashing / nonce / Ed25519 RFC 8032 host probe
