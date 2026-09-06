# IdentityDocumentServices (Linux starting point)

This directory is a fail-closed portable `IdentityDocumentServices` module
for the OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS
public surface (106 exact IDs). Isolated host compilation produces
`libIdentityDocumentServices.dylib` with Foundation only.

Linux has no identity-document entitlement, Secure Element, Apple
presentment daemon, or ISO 18013-5 CBOR validator. Web presentment
validation and provider registration never report success.

## What is real

- ISO 18013-5 request trees (`ElementInfo`, `DocumentRequest`,
  `DocumentRequestSet`, `PresentmentRequest`, `RequestAuthentication`,
  `ISO18013MobileDocumentRequest`) store caller fields and round-trip.
- `ISO18013MobileDocumentResponse` stores caller `Data`.
- `IdentityDocumentWebPresentmentRawRequest` stores `RequestType` and
  payload bytes. `RequestType` is the documented
  `iso18013MobileDocument` case with `Equatable` / `Hashable`.
- `IdentityDocumentPresentmentError.Code` raw values follow the pinned
  API-digester child order: `unknown = 0`, `invalidRequest = 1`,
  `requestInProgress = 2`, `cancelled = 3`, `notEntitled = 4`.
- Presentment `~=` matches `IdentityDocumentPresentmentError` by `code`.
- `MobileDocumentRegistration` stores type, authority key identifiers,
  document identifier, and invalidation date. Omitting the identifier
  uses `UUID().uuidString`.
- `IdentityDocumentProviderRegistrationStore.Status` and
  `RegistrationError` cases match the documented enum children
  (`authorized` / `notDetermined` / `notAuthorized` / `notSupported`
  and `unknown` / `invalidRequest` / `notAuthorized` / `notSupported`).

## Fail-closed boundaries

- `IdentityDocumentWebPresentmentRawRequestValidator` rejects empty
  request data and non-https origins as `invalidRequest`. Any other
  payload throws `notEntitled`. It never returns a parsed ISO 18013-5
  request.
- `IdentityDocumentProviderRegistrationStore.status` is always
  `.notSupported`. `addRegistration`, `removeRegistration`, and
  `registrations` throw `.notSupported`. Those async members are
  declared, not awaited by the isolated runner.
- `RequestAuthentication.authenticationCertificateChain` uses a
  module-local `SecCertificate` stand-in because Security is not a
  declared dependency. There is no trust evaluation.
- Constructing `ISO18013MobileDocumentResponse` is not a successful
  presentment.

## Depth pass 2026-09

Implemented **99** of 106 exact IDs (4 `declared` async store members,
3 `not-applicable` synthesized Actor isolation witnesses). Nondeferred
count 103, above the medium-full floor of 53.

Top-5 `implemented` evidence distribution:

1. `testPresentmentErrorCodeRawValues` — 9 rows (enum table)
2. `testMobileDocumentRegistrationStoresFields` — 6 rows
3. `testPresentmentErrorStaticCodeAliases` — 5 rows (Code static lets)
4. `testRegistrationErrorCases` — 5 rows (enum table)
5. `testRegistrationStoreStatusCases` — 5 rows (enum table)

No non-enum test is cited by more than 6 implemented rows (40% of the
remaining 78 non-table rows would be 31).

## Tests

`tests/agent/IdentityDocumentServicesLoadSmoke.swift` is the schema-v2
load marker. `tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/IdentityDocumentServicesDependencyIdentity.swift` is
prepared for a future clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep
generated products out of the tree.

## Gates and markers

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=IdentityDocumentServices lane=medium-full symbols=106
FRAMEWORK_FANOUT_REFERENCE_OK
IDENTITYDOCUMENTSERVICES_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=IdentityDocumentServices dylib=libIdentityDocumentServices.dylib
```

Environment: `swiftc` reports Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did
not emit `CURSOR_SWIFT_ENVIRONMENT_OK` because
`scratch/ladder-corpus/focus-ios` is absent on this VM. The sealed gate
compiles with a clean product tree (`products=clean`). Active Cursor
Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

`origin/agent/fw-identitydocumentservices` is published from this
Cursor-created work branch.
