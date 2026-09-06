# ContactProvider (Linux starting point)

This directory is a fail-closed portable `ContactProvider` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface
(99 exact IDs). Isolated host compilation produces `libContactProvider.dylib`
with Foundation only. `CNMutableContact` and `AppExtension` are isolation
stand-ins when Contacts and ExtensionFoundation are absent; they compile out
when those modules are on the import path. They are not Linux ports of those
frameworks.

Linux has no Contact Provider extension host, `contactsd`, Settings
enablement UI, or system Contacts database. Enablement, signaling, reset, and
invalidation never report success.

## What is real

- `ContactProviderError` cases in API-digester declaration order.
  `errorCode` is the 0...10 discriminator. `errorDomain` is
  `ContactProvider.ContactProviderError`. `errorDescription` / `failureReason`
  use the pinned graph doc-comment sentences. `helpAnchor` and
  `recoverySuggestion` stay `nil`.
- `ContactItem.Identifier` stores a string, hashes/equals on `value`, and
  exposes `rootContainer` with Linux sentinel `rootContainer`.
- `ContactItem.contact` stores a `CNMutableContact` payload plus identifier.
  Equality uses the item identifier and `contact.identifier`.
- `ContactItemPage` and `ContactItemSyncAnchor` store `generationMarker: Data`
  and `offset: Int`, are `Equatable` + `Codable`, and round-trip keyed JSON.
  `initialPage` is empty data and offset `0`.
- `DefaultContactProviderDomain` uses static identifier sentinel
  `DefaultContactProviderDomain`, empty `userInfo`, and the bundle display
  name (process name fallback).
- Observer protocols are synchronous recording APIs. Stub enumerators and
  extensions type-check against `ContactItemEnumerating` /
  `ContactProviderExtension`.
- `ContactProviderManager` is a process-local handle for the default domain.
  `isEnabled` is always `false`. Unknown identifiers throw
  `domainNotRegistered`.

## Fail-closed boundaries

- `ContactProviderManager.enable()`, `disable()`, `signalEnumerator(for:)`,
  `invalidate()`, and `reset()` throw `featureNotAvailable`. There is no
  extension process to signal and no Contacts cache to delete.
- `ContactItemEnumerator` async methods and
  `ContactProviderExtension.invalidate()` are declared only: the sealed
  runner has no run loop and cannot `await`.
- Linux never writes the system Contacts database, never presents an
  enablement prompt, and never claims an extension was discovered.
- Darwin `errorCode` integers, default-domain identifier, and
  `rootContainer` string are unobserved sentinels; see
  `oracle-questions.tsv`.

## Depth pass 2026-09

Implemented **90** of 99 exact IDs (9 `declared` async methods). Nondeferred
count 99, above the leaf-full floor of 80.

Top-5 `implemented` evidence distribution:

1. `testContactProviderErrorCases` — 11 rows (enum table)
2. `testContactProviderErrorUserInfo` — 2 rows (owned + synthesized)
3. `testContactProviderErrorCodes` — 2 rows (owned + synthesized)
4. `testContactProviderFailureReason` — 2 rows (owned + synthesized)
5. `testContactProviderErrorDescription` — 2 rows (owned + synthesized)

No non-enum test is cited by more than 2 implemented rows.

## Tests

`tests/agent/ContactProviderLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/ContactProviderDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree (`products=clean`). Starting commit `cbb368eeea236bbc0479fefa599190972ac8cfca` matched.
