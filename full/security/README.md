# Security (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Security` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and the pinned `dotnet/macios` bindings as a
secondary numeric cross-check. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

- File-backed encrypted keychain (`SecItemAdd` / `CopyMatching` / `Update` /
  `Delete`) for `genp` / `inet` / `keys` / `cert` / `idnt`. The store is an
  AES-256-GCM blob under `OPENUIKIT_KEYCHAIN_PATH` (or Application Support
  `OpenUIKit/keychain`). Duplicate detection, match-limit listing, return
  shapes for data / attributes / ref / persistent-ref, and access-group plus
  `kSecUseDataProtectionKeychain` storage are exercised.
- `SecAccessControlCreateWithFlags` stores protection + flags. Biometric flags
  fail closed on CopyMatching/Update/Delete (`errSecAuthFailed`).
- `SecRandomCopyBytes` fills buffers from `/dev/urandom`.
- `SecKey` RSA 2048/4096 (PKCS#1, including PKCS#8-wrapped fixtures) and EC
  P-256/P-384/P-521 (uncompressed X9.63). Sign/verify for PKCS#1 v1.5, PSS,
  and ECDSA; RSA PKCS1/OAEP encrypt/decrypt. Key generation uses the port's
  own arithmetic — `full/cryptokit` P-256/P-384/P-521 Signing/KeyAgreement
  still fail closed, and the isolated host may import Foundation only.
- `SecCertificateCreateWithData` parses DER X.509 (subject/issuer/serial/
  validity/SPKI). Invalid DER returns nil. `SecTrustEvaluateWithError` builds
  a chain to caller-supplied anchors, verifies signatures, checks validity
  dates, and matches SSL hostnames per RFC 6125. Revocation-require-positive
  fails closed (no OCSP).
- `SecPKCS12Import` accepts the unencrypted-bag subset. Fixtures were produced
  with OpenSSL 3.6.1 on 2026-09-05 (`tests/fixtures/`).
- `SecCopyErrorMessageString` returns the existing English strings for the
  statuses the original lane handled, plus a generic fallback.
- OSStatus numeric identities come from the pinned macios `SecStatusCode` /
  `SslStatus` bindings, which themselves cite `SecBase.h` / `SecureTransport.h`.
- `kSec*` four-character payloads and Apple policy OIDs were read from Apple
  OSS `SecItemConstants.c` / `SecPolicy.c` (measured 2026-09-05): e.g.
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` is `"aku"`,
  `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` is `"akpu"`,
  `kSecAttrSynchronizableAny` is `"syna"`, `kSecAttrKeyTypeRSA` is `"42"`.

## Fail-closed boundaries

Linux has no Apple keychain daemon, Secure Enclave, system trust store, TLS
stack owned by Security.framework, or shared web-credential agent.

- ECIES (`eciesEncryption*`) and RSA OAEP+AES-GCM return nil /
  `errSecUnimplemented`.
- Trust evaluation without anchors fails closed (no system roots).
- `kSecRevocationRequirePositiveResponse` fails closed.
- Shared web-credential APIs invoke their callbacks with an unimplemented
  CFError and never talk to Apple's password agent.
- `sec_protocol_*` option/metadata objects are inert. They never negotiate TLS.
- Code-signing helpers already on the lane (`SecStaticCodeCreateWithPath` and
  friends) remain `errSecNotAvailable`; they are extra relative to the iOS
  public graph and are not coverage rows.

## Dispatch lookalikes

`dispatch_queue_t` / `dispatch_data_t` are host lookalikes so previously
deferred graph signatures compile. Async trust evaluation invokes the callback
synchronously. These are not a second libdispatch; the later EC2 integration
build uses real Dispatch types from the platform sysroot.

## Open questions

- The pre-wave-5 `errSecInvalidValue` alias (`== errSecParam`) is preserved
  even though macios records `InvalidValue = -67694`. An oracle question asks
  which identity iOS 26.1 actually exports.

Coverage counts for this deliverable: implemented 1289,
declared 0, deferred 0,
unavailable 0.
