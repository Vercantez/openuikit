# Security (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Security` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and the pinned `dotnet/macios` bindings as a
secondary numeric cross-check. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

- The in-process portable keychain (`SecItemAdd` / `CopyMatching` / `Update` /
  `Delete`) from the pre-wave-5 lane is unchanged: generic-password CRUD,
  duplicate detection, match-limit listing, and persistent-ref bytes.
- `SecRandomCopyBytes` fills buffers from `SystemRandomNumberGenerator`.
- `SecCopyErrorMessageString` returns the existing English strings for the
  statuses the original lane handled, plus a generic fallback.
- OSStatus numeric identities come from the pinned macios `SecStatusCode` /
  `SslStatus` bindings, which themselves cite `SecBase.h` / `SecureTransport.h`.
  Apple-derived graph IDs win the census; binding values fill the numbers.
- `SSLCipherSuite` / `tls_ciphersuite_t` raw values are IANA TLS cipher suite
  identities as published in Apple's SecureTransport overlay.
- `SSLProtocol`, `tls_protocol_version_t`, `SecPadding`,
  `SecAccessControlCreateFlags`, `SecKeyOperationType`, and
  `SecTrustResultType` use documented raw values from those same headers via
  macios.
- Known SecItem four-character keys keep the payloads already shipped in
  `Security.swift`. Additional documented four-character keys are listed in
  `SecurityItemKeys.swift`.

## Fail-closed boundaries

Linux has no Apple keychain daemon, Secure Enclave, certificate trust store,
TLS stack owned by Security.framework, or shared web-credential agent.

- Certificate, key, PKCS#12, trust-evaluation, access-control, and shared
  web-credential APIs return `errSecUnimplemented`, `nil`, or `false`.
  `SecTrustEvaluate` additionally writes `.invalid`.
- Code-signing helpers already on the lane (`SecStaticCodeCreateWithPath` and
  friends) remain `errSecNotAvailable`; they are extra relative to the iOS
  public graph and are not coverage rows.
- `sec_protocol_*` APIs that only need Foundation types exist as inert
  option/metadata objects. They never negotiate TLS.

## Deferred

- Every function or typealias whose graph signature mentions `dispatch_queue_t`
  or `dispatch_data_t` is deferred: Dispatch is not a declared isolated-host
  dependency, and a module-local lookalike is forbidden.
- `kSec*` CFString constants without a documented four-character payload are
  declared with the C name as a process-local identity. That is source
  compatible, not an Apple-oracle string.
- The pre-wave-5 `errSecInvalidValue` alias (`== errSecParam`) is preserved
  even though macios records `InvalidValue = -67694`. An oracle question asks
  which identity iOS 26.1 actually exports.

Coverage counts for this deliverable: implemented 996,
declared 275, deferred 18,
unavailable 0.
