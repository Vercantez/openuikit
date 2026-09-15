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

## Wave6 recount 2026-09-15

Before **90** implemented / 9 declared / 0 deferred; after **90**
implemented / 9 declared / 0 deferred (gain +0). The 9 leftover rows are
all `async` (`ContactItemEnumerator` content/changes/invalidate,
`ContactProviderManager` enable/disable/signalEnumerator/invalidate/reset,
`ContactProviderExtension.invalidate`): the coverage contract forbids
`await` (and semaphore/RunLoop waits) in cited tests, so no synchronous
`test*()` can call those identifiers and they stay honestly `declared`.
This slug has no SwiftUI View overlays, so the overlay override does not
apply. Host-compat fix only: `ContactProviderLookalikes.swift` now gates
the real Contacts/ExtensionFoundation imports on
`(os(iOS) || os(Linux)) && canImport(...)` (NetworkExtension precedent) so
the macOS Apple-SDK host type-checks against the isolation stand-ins;
`ContactItem.swift` and `ContactProviderExtension.swift` carry the same
gated imports for device-SDK builds. Linux semantics are unchanged. The
sealed `tests/acceptance/test_host.sh` runner is Linux-only (`import
Glibc`); on this Mac the product dylib plus all 73 cited `test*()`
functions were compiled with the host `swiftc` and executed to the exact
`CONTACTPROVIDER_AGENT_RUNTIME_OK` marker instead.

Top-5 `implemented` evidence distribution:

1. `testContactProviderErrorCases` — 11 rows (enum table)
2. `testContactProviderErrorUserInfo` — 2 rows (owned + synthesized)
3. `testContactProviderErrorCodes` — 2 rows (owned + synthesized)
4. `testContactProviderFailureReason` — 2 rows (owned + synthesized)
5. `testContactProviderErrorDescription` — 2 rows (owned + synthesized)

No non-enum test is cited by more than 2 implemented rows.

## Wave10 recount 2026-09-15

Before **90** implemented / 9 declared / 0 deferred / 0 not-applicable; after **90** implemented / 9 declared / 0 deferred / 0 not-applicable (gain +0). Re-examined all 9 leftover `declared` rows: every one is `async` (`ContactItemEnumerator.enumerateContent/enumerateChanges/invalidate`, `ContactProviderManager.enable/disable/signalEnumerator/invalidate/reset`, `ContactProviderExtension.invalidate`). The coverage contract requires each `implemented` row to cite a top-level synchronous no-argument `func test*()` that actually calls the identifier with no `await`/semaphore/RunLoop waits, so no sync test can invoke these async entry points and they stay honestly `declared`. No SwiftUI View-overlay rows exist in this 99-ID surface, so the overlay override does not apply. No product, test, manifest, or coverage changes needed.

## Wave11 recount 2026-09-15

Before **90** implemented / 9 declared / 0 deferred / 0 not-applicable; after **90** implemented / 9 declared / 0 deferred / 0 not-applicable (gain +0). Re-examined all 9 leftover `declared` rows: every one is `async` (`ContactItemEnumerator.enumerateContent/enumerateChanges/invalidate`, `ContactProviderManager.enable/disable/signalEnumerator/invalidate/reset`, `ContactProviderExtension.invalidate`). The coverage contract requires each `implemented` row to cite a top-level synchronous no-argument `func test*()` that actually calls the identifier with no `await`/semaphore/RunLoop waits, so no sync test can invoke these async entry points (calling an `async` function from a sync context without `await` is a compile error) and they stay honestly `declared`. Retargeting them as sync would misrepresent the Apple async surface pinned in the digester/graph. No SwiftUI View-overlay rows exist in this 99-ID surface, so the overlay override does not apply. Product compiles warning-free under host `swiftc` (exit 0); no product, test, manifest, or coverage changes needed.

## Tests

`tests/agent/ContactProviderLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/ContactProviderDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree. This run ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ContactProvider lane=leaf-full symbols=99
FRAMEWORK_FANOUT_REFERENCE_OK
CONTACTPROVIDER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ContactProvider dylib=libContactProvider.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token is
the host-inventory stamp; the sealed framework gate compiles with a clean
product tree (`products=clean`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

## Wave12 recount 2026-09-15

Before **90** implemented / 9 declared / 0 deferred / 0 not-applicable; after **90** implemented / 9 declared / 0 deferred / 0 not-applicable (gain +0). Re-examined all 9 leftover `declared` rows: every one is `async` (`ContactItemEnumerator.enumerateContent/enumerateChanges/invalidate`, `ContactProviderManager.enable/disable/signalEnumerator/invalidate/reset`, `ContactProviderExtension.invalidate`). The coverage contract requires each `implemented` row to cite a top-level synchronous no-argument `func test*()` that actually calls the identifier with no `await`/semaphore/RunLoop/`DispatchQueue.main` waits, so no sync test can invoke these async entry points (calling an `async` function from sync context without `await` is a compile error) and they stay honestly `declared`. Retargeting them as sync would misrepresent the Apple async surface. No SwiftUI View-overlay rows exist in this 99-ID surface, so the overlay override does not apply. Product type-checks warning-free under host `swiftc` (exit 0); no product, test, manifest, or coverage changes needed.
