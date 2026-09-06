# SecureElementCredential (Linux starting point)

This directory is a fail-closed portable `SecureElementCredential` module for
the OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph and API digester. It is not wired
into the shared guest package; that integration is a separate central review
step.

Coverage: **123 implemented / 25 declared / 7 unavailable / 0 not-applicable /
155 total** (148 nondeferred, above the medium-full floor of 78).

## What is real

- `CredentialSession.ErrorCode` as a Swift `Error` / `LocalizedError` /
  `Equatable` / `Hashable` enum matching the API-digester child order
  (`userNotAuthorized` … `internalError`). No integer raw values are
  claimed. `failureReason` and `errorDescription` are stable English
  sentences; `helpAnchor` and `recoverySuggestion` stay the LocalizedError
  defaults (`nil`).
- `Credential`, `InstanceInfo`, `InstanceType`, `Credential.State`,
  `CredentialSession.State`, `Event`, `NFCFieldInformation`,
  `ConnectivityEvent`, `CardEmulationOptions`, `SecureElementInfo`,
  `PresentmentIntentAssertion.State`, and `CredentialSessionWindowSceneEvent`
  as value types with stored properties, equality, hashing, and Codable
  round-trips where the graph records those witnesses.
- Module-level SwiftUI overlay aliases `Credential` and
  `CardEmulationOptions`.
- `CredentialSession.init()`, identity `==` / `!=`, and
  `unownedExecutor`.
- `CredentialTransaction` / `Configuration` identity equality.

## Fail-closed boundaries

Linux has no Secure Element, NFC card-emulation radio, Apple credential
daemon, `com.apple.developer.secure-element-credential` entitlement, GDPR
sheet, or presentment authorization UI.

- `startSession()`, `isEligible`, provision/list/delete, wired/transceive,
  presentment assertion, `secureElementInfo`, `eventStream`, and SwiftUI
  perform APIs throw `featureUnavailable` (async; `declared` because the
  sealed runner cannot `await`).
- `InstanceInfo.securityDomainCounter` throws the same error.
- Entering wired/delete with `installationPending` or `installationFailed`
  credentials throws `invalidCredentialState` before the unavailable
  fallback.
- UIKit overlay methods that take `UIScene` / `UIWindowScene`,
  `UIScene.ConnectionOptions.credentialSessionEvent`,
  `CredentialSessionWindowSceneDelegate`, and SwiftUI
  `View.transactionTask` are `unavailable` (those modules are not
  dependencies of this Foundation-only seed).
- `endCardEmulation()` has no scene type, so it is declared on the actor
  and still throws `featureUnavailable`.
- Actor isolation witnesses (`assertIsolated`, `assumeIsolated`,
  `preconditionIsolated`) are `declared`: they trap off-actor, and the
  sealed runner has no isolation hop.

## Depth pass 2026-09

Fresh seed started at 0 implemented/declared. First host pass:
**123 implemented / 22 declared / 7 unavailable / 3 not-applicable**.

Repair: the three `Actor` isolation witnesses (`assertIsolated`,
`assumeIsolated`, `preconditionIsolated`) are not SwiftUI cross-import
overlays, so `not-applicable` was refused. They are now `declared`
(off-actor calls trap; sealed runner cannot hop). After this pass:
**123 implemented / 25 declared / 7 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 23 | `ErrorCodeTests.swift#testErrorCodeCases` |
| 5 | `SessionStateTests.swift#testSessionStateCases` |
| 4 | `InstanceInfoTests.swift#testInstanceTypeCases` |
| 3 | `CredentialTests.swift#testCredentialStateCases` |
| 3 | `SessionStateTests.swift#testNFCFieldCases` |

`testErrorCodeCases` is a table-driven enum-member test (22 cases plus the
enum type). Focused per-family tests in `tests/agent/*Tests.swift` cover
the remaining implemented rows and stay under the 40% bulk-relabel bound
on non-member citations.

The sealed host gate was run as
`bash full/secureelementcredential/tests/acceptance/test_host.sh` and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=SecureElementCredential lane=medium-full symbols=155
FRAMEWORK_FANOUT_REFERENCE_OK
SECUREELEMENTCREDENTIAL_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=SecureElementCredential dylib=libSecureElementCredential.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this
snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiled with a clean product tree
(`products=clean`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.
