# CryptoKit SDK depth — `agent/fw-cryptokit`

Worktree `fw-cryptokit`. Isolated guest in `full/cryptokit/`. No UI chrome.

Linux sealed host gate (`swift:6.2-noble` + python3): `FRAMEWORK_FANOUT_DELIVERABLE_OK` / `CRYPTOKIT_AGENT_RUNTIME_OK` / `FRAMEWORK_FANOUT_HOST_OK`. Darwin `tests/test_cryptokit_host.sh`: `CRYPTOKIT_HOST_OK` including Ed25519 sign/verify. Catalyst openrender **124/124**. Linux `swift:6.2-noble` `openrender` release link OK (266 s). The worktree's `validate_seed.py` still pins generator `e44f6bde`; origin/main `c0b85df0` accepts that digest via `generator-lineage.json`. The operator merge onto current main supplies that lineage; this branch does not edit `full/framework-fanout/`.

## Before / after

| gate | before | after |
|---|---|---|
| Coverage implemented | 429 | **1181** |
| Coverage declared | 347 | **39** (SecureEnclave only) |
| Coverage deferred | 488 | **44** (Foundation SortComparator / formatted Sequence overlays) |
| Coverage unavailable | 23 | 23 (12 SecureEnclave `LAContext`/`SecAccessControl` inits + 11 Combine `publisher`) |
| Nondeferred | 776 | **1220** (floor 644) |
| RFC vectors | hashes/HMAC/HKDF/AES-GCM/ChaChaPoly; curves fail-closed | those plus X25519, Ed25519, AES-KW unwrap, P-256/P-384/P-521, HPKE base |

## What was measured

Published RFCs, not a score search:

| primitive | vector | result |
|---|---|---|
| X25519 | RFC 7748 §6.1 Alice/Bob | public `8520f009…9b4e6a`, shared `4a5d9d5ba4ce2de1…1e161742` |
| Ed25519 | RFC 8032 §7.1 empty message | public `d75a9801…07511a`, sig `e5564300…` / `5fb88215…` |
| AES-KW | RFC 3394 §4.1 | wrap `1FA68B0A8112B447AEF34BD8FB5A7B829D3E862371D2CFE5`; unwrap recovers the key |
| P-256 | RFC 6979 A.2.5 | public `60fed4ba…` \|\| `7903fe10…d4462299`; sign/verify round-trip; PEM/SPKI/x963/compressed recover the same point |
| HPKE | RFC 9180 base | X25519-HKDF-SHA256 + ChaChaPoly and P-256-HKDF-SHA256 + AES-GCM-256 open(seal(m)) == m |

Compact representation: x iff y is even. The RFC 6979 A.2.5 point has odd y → `compactRepresentation == nil` (recorded as an oracle question vs Darwin).

## Fail-closed (honest)

- `SecureEnclave.isAvailable == false`; generate/sign throw `underlyingCoreCryptoError(error: -1)`.
- ML-KEM / ML-DSA / X-Wing generate, encapsulate, decapsulate, sign fail closed.
- Combine `Sequence.publisher` unavailable on Linux.

## Files

`CryptoKitMath.swift` (field 2^255-19 + NIST Jacobian), `CryptoKitEncoding.swift` (SPKI/PKCS#8/PEM), rewritten `CryptoKitCurves.swift` / `CryptoKitHPKE.swift`, AES inverse + RFC 3394 unwrap in `CryptoKitAEAD.swift`.
