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

Coverage after this round: **1221 implemented / 21 declared / 0 deferred / 22
not-applicable / 23 unavailable** of 1287 IDs. Wave 8 recount: before
1221/21/0, after 1221/21/0 (gain 0 — all 21 leftover declared rows are
SecureEnclave PrivateKey instance members whose only Apple initializers
require LAContext/SecAccessControl, so no instance is obtainable in-process;
they stay declared fail-closed rather than inventing a synthetic initializer). Wave 9 recount: before
1221/21/0, after 1221/21/0 (gain 0 — re-examined all 21 declared rows: 12 are
non-throwing `publicKey`/`dataRepresentation` getters that cannot fail closed
without changing Apple's signature, and 9 are throwing instance methods with no
obtainable instance; both stay declared per the hardware fail-closed rule). Wave 10 recount: before
1221/21/0, after 1221/21/0 (gain 0 — re-verified all 21 declared anchors compile
in CryptoKitSecureEnclave.swift and all 23 implemented tests pass in a manual
marker-only runner; no SecureEnclave PrivateKey instance is obtainable in-process
without inventing a non-Apple initializer, so the 12 non-throwing getters and 9
throwing instance methods stay declared). Wave 11 recount: before
1221/21/0, after 1221/21/0 (gain 0 — re-verified all 21 declared anchors still compile
in CryptoKitSecureEnclave.swift, libCryptoKit.dylib still builds with
-warnings-as-errors, and all 23 cited agent tests pass in a manual @main runner;
converting the 12 non-throwing getters would require changing Apple's signatures
and converting the 9 throwing methods would require inventing a synthetic
succeeding initializer for hardware-backed keys, both of which would fabricate
SecureEnclave success and violate the fail-closed rule; the 12 LAContext/SecAccessControl
inits plus 11 Combine publishers stay unavailable and the 22 Foundation
compare/formatted witnesses stay not-applicable). Wave 12 recount: before
1221/21/0, after 1221/21/0 (gain 0 — re-verified all 8 guest sources still build
libCryptoKit.dylib with -warnings-as-errors and all 23 cited agent tests pass in a
manual marker-only runner emitting only CRYPTOKIT_AGENT_RUNTIME_OK; the 21 declared
rows remain unconvertible in-process because the 6 SecureEnclave PrivateKey structs
expose no public initializer (memberwise init is internal and tests link externally),
Apple's only initializers require LAContext/SecAccessControl (unavailable), and the
sole factories (ML-KEM generate) correctly throw fail-closed, so no instance exists
on which to call the 12 getters or 9 throwing methods; deferred is 0). Wave 13 recount: before
1221/21/0, after 1221/21/0 (gain 0 — async-shaped leftover is 0: the symbol graph and
API digester contain no async/await/AsyncSequence symbols, the sealed @main async runner
still passes all 23 cited agent tests emitting only CRYPTOKIT_AGENT_RUNTIME_OK, the
dylib still builds with -warnings-as-errors, and the 21 declared SecureEnclave instance
members remain uncallable in-process for the same no-obtainable-instance reason; the
Overlay OVERRIDE does not apply (no SwiftUI View modifiers in CryptoKit coverage). Wave 14 recount: before
1221/21/0, after 1221/21/0 (gain 0 — re-verified all 8 guest sources still build
libCryptoKit.dylib with -warnings-as-errors and all 23 cited agent tests pass in a
manual @main runner emitting only CRYPTOKIT_AGENT_RUNTIME_OK; the 21 declared
SecureEnclave instance members (12 non-throwing publicKey/dataRepresentation getters
that cannot fail closed without changing Apple's signatures, plus 9 throwing
signature/sharedSecretFromKeyAgreement/decapsulate methods with no obtainable instance
since the 6 PrivateKey structs expose no public initializer and Apple's only inits
require LAContext/SecAccessControl) stay declared fail-closed; the Overlay OVERRIDE
does not apply — no SwiftUI View modifiers exist in CryptoKit coverage). Implemented ≥ 900. Nondeferred except
SecureEnclave (declared + LAContext unavailable) and Combine `Sequence.publisher`
(unavailable on Linux). Foundation `Sequence.compare` / `formatted` overlays are
not-applicable: their generic constraints (`Element: SortComparator`,
`Element == String`) are unsatisfiable for `UInt8`-element digest/nonce types.
`sorted(using:)` single- and array-comparator overloads are implemented with a
`UInt8` test comparator.

## Fail-closed boundaries

- `SecureEnclave.isAvailable == false`; hardware-backed P-256 / ML-KEM / ML-DSA
  generate and sign throw `CryptoKitError.underlyingCoreCryptoError`. The
  SecureEnclave namespace surface (P256 / ML-KEM / ML-DSA enums, private-key
  types, `PublicKey` aliases, ML-KEM `generate`) is covered by in-process
  fail-closed tests. Instance members (`publicKey`, `dataRepresentation`,
  `signature`, `sharedSecretFromKeyAgreement`, `decapsulate`) stay declared:
  Apple's only initializers require `LAContext`/`SecAccessControl`, so no
  instance is obtainable on Linux. Inits that
  take `LAContext` or `SecAccessControl` are **unavailable**.
- ML-KEM / ML-DSA / X-Wing generate, encapsulate, decapsulate, and sign fail
  closed (no Kyber/Dilithium provider).
- `Sequence.publisher` (Combine) is **unavailable** on Linux.

## Deferred

Swift.Sequence + Foundation `SortComparator` single/array `sorted(using:)` overlays
on digest, MAC, and nonce types are implemented via `testDigestSortedUsingComparator` /
`testAuthCodeNonceSortedUsingComparator`. `Sequence.compare` / `formatted` are
not-applicable (constraints uncallable for `UInt8` elements). `Error.localizedDescription`
wording on Darwin remains unrestated. Native post-quantum behavior stays fail-closed until a provider plus
an Apple-runtime oracle exist. Insecure.RSA is not in this SDK snapshot.

## Tests

- `tests/agent/CryptoKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/CryptoKitTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/CryptoKitDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/test_cryptokit_host.sh` — hashing / nonce / Ed25519 RFC 8032 host probe
